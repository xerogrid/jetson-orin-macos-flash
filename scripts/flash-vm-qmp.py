#!/usr/bin/env python3
"""Send one explicit QMP command to the dedicated flashing VM."""
import json
import pathlib
import socket
import sys

sock_path = pathlib.Path(__file__).resolve().parent.parent / '.local/jetson-vm/qmp.sock'
command = json.loads(sys.argv[1])
with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
    sock.settimeout(10)
    sock.connect(str(sock_path))
    stream = sock.makefile('rwb', buffering=0)
    json.loads(stream.readline())
    for item in ({'execute': 'qmp_capabilities'}, command):
        stream.write(json.dumps(item).encode() + b'\n')
        while True:
            response = json.loads(stream.readline())
            if 'return' in response or 'error' in response:
                break
    print(json.dumps(response, indent=2))
    if 'error' in response:
        sys.exit(1)
