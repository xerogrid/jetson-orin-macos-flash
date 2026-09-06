#!/usr/bin/env python3
"""Create a fresh flashing VM; never opens a physical disk or flashes a Jetson."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import secrets
import shlex
import shutil
import subprocess
import uuid

ROOT = Path(__file__).resolve().parent.parent
VM = ROOT / '.local/jetson-vm'


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(4 * 1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def cloud_config(public_key):
    return '#cloud-config\n' + json.dumps({
        'hostname': 'jetson-flash-host', 'manage_etc_hosts': True,
        'users': [{'name': 'flash', 'groups': ['adm', 'sudo'],
                   'shell': '/bin/bash', 'sudo': 'ALL=(ALL) NOPASSWD:ALL',
                   'lock_passwd': True, 'ssh_authorized_keys': [public_key.strip()]}],
        'ssh_pwauth': False, 'disable_root': True,
        'package_update': False, 'package_upgrade': False,
    }, indent=2) + '\n'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--verify-downloads', action='store_true', help='Read-only checksum check')
    parser.add_argument('--target-user', default='jetson')
    parser.add_argument('--hostname', default='xavier-nx')
    parser.add_argument('--timezone', default='UTC')
    args = parser.parse_args()
    if not re.fullmatch(r'[a-z][a-z0-9_-]{0,30}', args.target_user) or args.target_user == 'root':
        parser.error('Use a non-root Linux username')
    if not re.fullmatch(r'[a-z0-9][a-z0-9-]{0,62}', args.hostname):
        parser.error('Invalid hostname')
    if not re.fullmatch(r'[A-Za-z0-9_+/-]+', args.timezone) or '..' in args.timezone:
        parser.error('Invalid timezone')
    manifest = json.loads((ROOT / 'config/downloads.json').read_text())
    if args.verify_downloads:
        for item in manifest:
            path = VM / 'downloads' / item['filename']
            if not path.is_file() or sha256(path) != item['sha256']:
                raise SystemExit('Missing or mismatched download: ' + item['filename'])
            print('Verified ' + item['filename'])
        return
    if platform.system() != 'Darwin' or platform.machine() != 'arm64':
        parser.error('Run initialization on an Apple Silicon Mac')
    # Refuse partial/existing installations rather than replacing disks or keys.
    for name in ('ubuntu.qcow2', 'seed.iso', 'id_ed25519', 'xavier_ed25519', 'xavier-password'):
        if (VM / name).exists():
            parser.error('Existing VM/credentials found; will not overwrite: ' + name)
    required = ('qemu-img', 'ssh-keygen', 'hdiutil', 'curl', 'bzip2')
    programs = {name: shutil.which(name) for name in required}
    if not all(programs.values()):
        parser.error('Missing host tools; install Homebrew qemu and ensure its bin directory is on PATH')
    os.umask(0o077)
    downloads = VM / 'downloads'
    downloads.mkdir(parents=True, exist_ok=True)
    for item in manifest:
        path = downloads / item['filename']
        if not path.exists():
            partial = path.with_name(path.name + '.partial')
            subprocess.run([programs['curl'], '--fail', '--location', '--retry', '3',
                            '--output', str(partial), item['url']], check=True)
            if sha256(partial) != item['sha256']:
                raise SystemExit('Checksum mismatch; refusing download: ' + path.name)
            partial.rename(path)
        if sha256(path) != item['sha256']:
            raise SystemExit('Checksum mismatch; refusing cached download: ' + path.name)
        print('Verified ' + path.name, flush=True)
        if path.suffix == '.tbz2':
            output = path.with_suffix('.tar')
            # Rebuild derived archives from verified inputs, including cached downloads.
            partial = output.with_suffix('.tar.partial')
            with partial.open('wb') as stream:
                subprocess.run([programs['bzip2'], '-dc', str(path)], stdout=stream, check=True)
            partial.replace(output)
    for name in ('id_ed25519', 'xavier_ed25519'):
        subprocess.run([programs['ssh-keygen'], '-q', '-t', 'ed25519', '-N', '',
                        '-C', name + '-jetson-bringup', '-f', str(VM / name)], check=True)
    (VM / 'xavier-password').write_text(secrets.token_urlsafe(24) + '\n')
    (VM / 'target-user').write_text(args.target_user + '\n')
    login = {'TARGET_USER': args.target_user, 'TARGET_HOSTNAME': args.hostname,
             'TARGET_TIMEZONE': args.timezone}
    (VM / 'target-login.env').write_text(''.join(k + '=' + shlex.quote(v) + '\n' for k, v in login.items()))
    seed = VM / 'seed'
    seed.mkdir(exist_ok=True)
    (seed / 'user-data').write_text(cloud_config((VM / 'id_ed25519.pub').read_text()))
    (seed / 'meta-data').write_text('instance-id: jetson-flash-' + str(uuid.uuid4()) + '\nlocal-hostname: jetson-flash-host\n')
    subprocess.run([programs['hdiutil'], 'makehybrid', '-iso', '-joliet',
                    '-default-volume-name', 'cidata', '-o', str(VM / 'seed.iso'), str(seed)], check=True)
    subprocess.run([programs['qemu-img'], 'create', '-f', 'qcow2', '-F', 'qcow2',
                    '-b', str(downloads / manifest[0]['filename']), str(VM / 'ubuntu.qcow2'), '160G'], check=True)
    print('VM prepared. Follow docs/apple-silicon-runbook.md; no flash has run.')


if __name__ == '__main__':
    main()
