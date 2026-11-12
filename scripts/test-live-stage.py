#!/usr/bin/env python3

import importlib.util
import json
import os
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("live_stage", os.path.join(HERE, "live-stage.py"))
ls = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ls)

TABLE = """3 /usr/lib/modules/**
1 /usr/lib/libsingularity.so* abi:2
2 /usr/bin/labwc
0 /usr/share/glib-2.0/schemas/*.gschema.xml keys:2
1 /usr/bin/singularity-desktop
0 /usr/share/**
"""

ANCHOR = ["/usr/lib/atomloops/live", "d", "0o755", "", None]
failures = 0


def check(ok, what):
    global failures
    print(("ok   " if ok else "FAIL ") + what)
    if not ok:
        failures += 1


def lists(old, new, anchor=True):
    o = {e[0]: e for e in old + ([ANCHOR] if anchor else [])}
    n = {e[0]: e for e in new + ([ANCHOR] if anchor else [])}
    return o, n


def f(path, digest, extra=None):
    return [path, "f", "0o644", digest, extra]


with tempfile.TemporaryDirectory() as tmp:
    table = os.path.join(tmp, "stages")
    with open(table, "w") as t:
        t.write(TABLE)
    rules = ls.load_table(table)

    stage, _ = ls.decide(rules, *lists([f("/usr/share/a", "1")], [f("/usr/share/a", "2")]))
    check(stage == 0, "data only is silent")
    stage, _ = ls.decide(rules, *lists([f("/usr/bin/singularity-desktop", "1")], [f("/usr/bin/singularity-desktop", "2")]))
    check(stage == 1, "the shell needs a reload")
    stage, _ = ls.decide(rules, *lists([f("/usr/bin/labwc", "1")], [f("/usr/bin/labwc", "2"), f("/usr/share/a", "1")]))
    check(stage == 2, "the compositor needs a new session")
    stage, reasons = ls.decide(rules, *lists([], [f("/usr/bin/unknown", "1")]))
    check(stage == 3 and reasons[0][2] == "not covered by the stage table", "an uncovered file needs a reboot")
    stage, _ = ls.decide(rules, *lists([f("/usr/lib/modules/7.2/a.ko", "1")], []))
    check(stage == 3, "a removed module needs a reboot")
    stage, _ = ls.decide(rules, *lists([f("/usr/share/a", "1")], [f("/usr/share/a", "2")], anchor=False))
    check(stage == 3, "a release without the live anchor needs a reboot")

    lib = "/usr/lib/libsingularity.so.0"
    stage, _ = ls.decide(rules, *lists([f(lib, "1", ["a", "b"])], [f(lib, "2", ["a", "b", "c"])]))
    check(stage == 1, "added symbols keep the reload")
    stage, reasons = ls.decide(rules, *lists([f(lib, "1", ["a", "b"])], [f(lib, "2", ["a"])]))
    check(stage == 2 and "1 symbols removed (b)" in reasons[0][2], "a removed symbol needs a new session")
    stage, _ = ls.decide(rules, *lists([f(lib, "1", ["a"])], []))
    check(stage == 2, "a removed library needs a new session")

    schema = "/usr/share/glib-2.0/schemas/dev.sinty.x.gschema.xml"
    stage, _ = ls.decide(rules, *lists([f(schema, "1", ["s/a"])], [f(schema, "2", ["s/a", "s/b"])]))
    check(stage == 0, "a new settings key is silent")
    stage, _ = ls.decide(rules, *lists([f(schema, "1", ["s/a", "s/b"])], [f(schema, "2", ["s/a"])]))
    check(stage == 2, "a removed settings key needs a new session")

    root = os.path.join(tmp, "root")
    os.makedirs(os.path.join(root, "usr/share/glib-2.0/schemas"))
    os.makedirs(os.path.join(root, "usr/lib/atomloops/live"))
    with open(os.path.join(root, "usr/share/glib-2.0/schemas/dev.sinty.x.gschema.xml"), "w") as s:
        s.write('<schemalist><schema id="dev.sinty.x"><key name="one" type="b"/><key name="two" type="b"/></schema></schemalist>')
    os.symlink("share", os.path.join(root, "usr/link"))
    listed = {e[0]: e for e in ls.list_root(root, rules)}
    check(listed["/usr/share/glib-2.0/schemas/dev.sinty.x.gschema.xml"][4] == ["dev.sinty.x/one", "dev.sinty.x/two"], "schema keys are listed")
    check(listed["/usr/link"][1:4] == ["l", "0o777", "share"], "symlinks are listed by target")
    check(listed["/usr/lib/atomloops/live"][1] == "d", "the live anchor is listed")

    elf = "/usr/lib/libc.so.6"
    if os.path.exists("/usr/lib/x86_64-linux-gnu/libc.so.6"):
        elf = "/usr/lib/x86_64-linux-gnu/libc.so.6"
    if os.path.exists(elf):
        with open(os.path.realpath(elf), "rb") as e:
            symbols = ls.dynamic_symbols(e.read())
        check(symbols is not None and "malloc" in symbols and len(symbols) > 500, "exported symbols are read from a real library")

    out = subprocess.run([sys.executable, os.path.join(HERE, "live-stage.py"), "decide", "--table", table,
                          "--old", os.devnull, "--new", os.devnull, "--min-stage", "2"], capture_output=True, text=True)
    check(json.loads(out.stdout)["stage"] == 3, "the command line refuses without the anchor")

sys.exit(1 if failures else 0)
