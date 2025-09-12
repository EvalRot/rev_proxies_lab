#!/usr/bin/env python3
import argparse
import socket
import sys


def send_raw(host: str, port: int, data: bytes, timeout: float = 5.0) -> bytes:
    with socket.create_connection((host, port), timeout=timeout) as s:
        s.sendall(data)
        s.shutdown(socket.SHUT_WR)
        chunks = []
        while True:
            buf = s.recv(4096)
            if not buf:
                break
            chunks.append(buf)
        return b"".join(chunks)


def main():
    p = argparse.ArgumentParser(description="Send raw TCP/HTTP payload and print the response")
    p.add_argument("host")
    p.add_argument("port", type=int)
    p.add_argument("--file", "-f", help="Path to file with raw request. If omitted, read stdin.")
    args = p.parse_args()
    payload = None
    if args.file:
        with open(args.file, "rb") as fh:
            payload = fh.read()
    else:
        payload = sys.stdin.buffer.read()
    resp = send_raw(args.host, args.port, payload)
    sys.stdout.buffer.write(resp)


if __name__ == "__main__":
    main()

