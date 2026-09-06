"""Offline tests only: never contact QEMU, USB, SSH, or a physical disk."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('setup_vm', ROOT / 'scripts/setup-flash-vm.py')
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)


class PackageTests(unittest.TestCase):
    def test_fresh_setup_with_mocked_external_tools(self):
        # Exercise artifact generation in a disposable directory, not the live VM.
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            vm = root / '.local/jetson-vm'
            downloads = vm / 'downloads'
            downloads.mkdir(parents=True)
            (root / 'config').mkdir()
            entries = []
            for name in ('base.img', 'bsp.tbz2', 'rootfs.tbz2'):
                file = downloads / name
                file.write_bytes(b'fixture')
                entries.append(dict(filename=name, url='https://example.invalid/' + name, sha256=setup.sha256(file)))
            (root / 'config/downloads.json').write_text(json.dumps(entries))

            def fake_run(argv, **kwargs):
                if argv[0] == 'bzip2':
                    kwargs['stdout'].write(b'expanded fixture')
                elif argv[0] == 'ssh-keygen':
                    key = Path(argv[-1])
                    key.write_text('fixture private key')
                    key.with_suffix('.pub').write_text('ssh-ed25519 fixture public key')
                elif argv[0] == 'hdiutil':
                    Path(argv[argv.index('-o') + 1]).write_bytes(b'seed fixture')
                elif argv[0] == 'qemu-img':
                    Path(argv[-2]).write_bytes(b'overlay fixture')
                else:
                    self.fail('Unexpected external command: ' + argv[0])

            old_umask = os.umask(0o077)
            try:
                with patch.object(setup, 'ROOT', root), patch.object(setup, 'VM', vm), \
                        patch.object(setup.platform, 'system', return_value='Darwin'), \
                        patch.object(setup.platform, 'machine', return_value='arm64'), \
                        patch.object(setup.shutil, 'which', side_effect=lambda name: name), \
                        patch.object(setup.subprocess, 'run', side_effect=fake_run), \
                        patch('sys.argv', ['setup', '--target-user', 'jetson']):
                    setup.main()
            finally:
                os.umask(old_umask)
            self.assertEqual((vm / 'target-user').read_text(), 'jetson\n')
            for name in ('xavier-password', 'id_ed25519', 'xavier_ed25519'):
                self.assertEqual((vm / name).stat().st_mode & 0o777, 0o600)
            self.assertTrue((vm / 'ubuntu.qcow2').is_file())
            self.assertTrue((vm / 'seed.iso').is_file())

    def test_manifest(self):
        entries = json.loads((ROOT / 'config/downloads.json').read_text())
        self.assertEqual(len(entries), 3)
        for item in entries:
            self.assertRegex(item['sha256'], r'^[0-9a-f]{64}$')
            self.assertTrue(item['url'].startswith('https://'))
            self.assertEqual(Path(item['filename']).name, item['filename'])

    def test_cloud_init_key_only(self):
        config = setup.cloud_config('ssh-ed25519 TEST public-key\n')
        self.assertTrue(config.startswith('#cloud-config\n'))
        data = json.loads(config.split('\n', 1)[1])
        self.assertFalse(data['ssh_pwauth'])
        self.assertTrue(data['disable_root'])
        self.assertEqual(data['users'][0]['ssh_authorized_keys'], ['ssh-ed25519 TEST public-key'])

    def test_existing_vm_refused_before_subprocess(self):
        with tempfile.TemporaryDirectory() as tmp:
            vm = Path(tmp)
            (vm / 'ubuntu.qcow2').write_text('do not replace')
            with patch.object(setup, 'VM', vm), patch.object(setup.platform, 'system', return_value='Darwin'), \
                    patch.object(setup.platform, 'machine', return_value='arm64'), \
                    patch('sys.argv', ['setup']), patch.object(setup.subprocess, 'run') as run:
                with self.assertRaises(SystemExit):
                    setup.main()
                run.assert_not_called()
            self.assertEqual((vm / 'ubuntu.qcow2').read_text(), 'do not replace')

    def profile(self, **overrides):
        values = dict(BOARDID='3668', BOARDSKU='0000', FAB='300', BOARDREV='E.0',
                      EXPECTED_NVME_SERIAL='TEST123', EXT_NUM_SECTORS='7814037168', APP_SIZE_GIB='32')
        values.update(overrides)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'target.env'
            path.write_text(''.join(f'{k}={v}\n' for k, v in values.items()))
            return subprocess.run(['bash', '-eu', '-c',
                'source "$1"; echo accepted', 'test', str(ROOT / 'scripts/load-target-profile.sh')],
                env={'PATH': '/usr/bin:/bin', 'TARGET_PROFILE': str(path)}, capture_output=True).returncode

    def test_measured_profile_accepted(self):
        self.assertEqual(self.profile(), 0)

    def test_other_module_rejected(self):
        self.assertNotEqual(self.profile(BOARDSKU='0001'), 0)

    def test_placeholder_rejected(self):
        self.assertNotEqual(self.profile(FAB='REPLACE_FROM_DEVICE_TREE'), 0)

    def test_small_disk_rejected(self):
        self.assertNotEqual(self.profile(EXT_NUM_SECTORS='1000000'), 0)

    def test_invalid_sector_count_rejected(self):
        for value in ('0', '-1', '7814x', '07814037168'):
            self.assertNotEqual(self.profile(EXT_NUM_SECTORS=value), 0)

    def test_oversized_app_rejected(self):
        self.assertNotEqual(self.profile(APP_SIZE_GIB='128'), 0)

    def test_daemonize_refused_before_qemu(self):
        result = subprocess.run(['bash', str(ROOT / 'scripts/start-flash-vm.sh'), '-daemonize'], capture_output=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn(b'without -daemonize', result.stderr)

    def test_all_shell_scripts_parse(self):
        for script in (ROOT / 'scripts').glob('*.sh'):
            subprocess.run(['bash', '-n', str(script)], check=True)


if __name__ == '__main__':
    unittest.main()
