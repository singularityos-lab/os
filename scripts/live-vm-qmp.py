#!/usr/bin/env python3
import json
import socket
import sys
import time

WIDTH, HEIGHT = 1280, 800
SPECIAL = {" ": "spc", "\n": "ret", ".": "dot", "-": "minus", "/": "slash"}


class Qmp:
    def __init__(self, path):
        self.sock = socket.socket(socket.AF_UNIX)
        self.sock.connect(path)
        self.f = self.sock.makefile("rw")
        json.loads(self.f.readline())
        self.call("qmp_capabilities")

    def call(self, name, **args):
        self.f.write(json.dumps({"execute": name, "arguments": args}) + "\n")
        self.f.flush()
        while True:
            reply = json.loads(self.f.readline())
            if "return" in reply:
                return reply["return"]
            if "error" in reply:
                raise RuntimeError(f"{name}: {reply['error']}")

    def move(self, x, y):
        self.call("input-send-event", events=[
            {"type": "abs", "data": {"axis": "x", "value": x * 32767 // WIDTH}},
            {"type": "abs", "data": {"axis": "y", "value": y * 32767 // HEIGHT}},
        ])

    def click(self, x, y):
        self.move(x, y)
        time.sleep(0.1)
        for down in (True, False):
            self.call("input-send-event", events=[{"type": "btn", "data": {"down": down, "button": "left"}}])
            time.sleep(0.08)

    def key(self, *names):
        self.call("send-key", keys=[{"type": "qcode", "data": n} for n in names], **{"hold-time": 60})

    def type(self, text):
        for ch in text:
            self.key(SPECIAL.get(ch, ch))
            time.sleep(0.05)


def main():
    qmp = Qmp(sys.argv[1])
    op, args = sys.argv[2], sys.argv[3:]
    if op == "shot":
        qmp.call("screendump", filename=args[0], format="png")
    elif op == "click":
        qmp.click(int(args[0]), int(args[1]))
    elif op == "move":
        qmp.move(int(args[0]), int(args[1]))
    elif op == "key":
        qmp.key(*args[0].split("-"))
    elif op == "type":
        qmp.type(args[0])
    elif op == "quit":
        qmp.call("quit")
    else:
        sys.exit(f"live-vm-qmp: unknown operation {op}")


if __name__ == "__main__":
    main()
