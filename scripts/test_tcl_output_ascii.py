#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""FM Tcl 输出字符闸 —— `puts` / `error` 打出去的字里不许有 U+0080..U+00FF。

## 为什么要这道闸（2026-09-20 实测，TlbStorageWrapper_2/_3 lane 自抓）

`fm_verdict.py` 用 `open(log).read()` 读 fm.log，默认 utf-8 严格解码。
verif/ut/TlbStorageWrapper/fm_pins.tcl 里有一行

    puts "TLBSW_PINS: ... = 11 位 × $_nports 端口 ..."

fm_shell 把它写进 fm.log 时：**CJK 变成 `?`（无害），而 `×`(U+00D7) 原样落成
单字节 0xd7** —— 那是一个不合法的 UTF-8 起始字节。于是：

    UnicodeDecodeError: 'utf-8' codec can't decode byte 0xd7 in position 64147

`fm_verdict.py` 当场崩，`$v` 变成空串，`make fm-<target>` 以 rc=2 结束。
★后果是一个"既像成功又像失败"的中间态★：evidence 目录照样生成，receipt 里
native_verdict=SUCCEEDED / passing=8266 一应俱全，只有 `verdict` 字段是空的、
MAKE_RC=2 躺在角落。上一轮就是这么把一份**没出 verdict** 的证据当成签核报上去的。

## 判据为什么只卡 U+0080..U+00FF，而不是"全 ASCII"

两条路径的编码行为**不一样**，实测区分过（同一份 fm.log）：

  1. fm_shell **回显入口 Tcl**（含注释）时保留 UTF-8：
     日志里 `#   FM_TOP  顶层模块名…` 是 b'\\xe9\\xa1\\xb6\\xe5\\xb1\\x82…'，合法 UTF-8。
     ⇒ 注释里写中文是安全的，不必禁。
  2. 脚本自己 `puts` 出去的字走另一条通道：CJK 被替换成 `?`，
     而 Latin-1 区（U+0080..U+00FF）的字符**原样落成单字节** ⇒ 非法 UTF-8。

所以致命的恰好是 `× § · ° ± ×` 这类"看起来很 ASCII"的排版符号。
判据锁这一段，既抓得住真病因，又不会把仓里 8 个文件里合法的中文 puts 全判红
（实测：全仓 23 个钉点文件，按本判据只有一个文件命中，就是那个真出过事的）。

用法: python3 scripts/test_tcl_output_ascii.py [--selftest]
退出码 0 = 全部干净
"""
import glob
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATTERNS = ["verif/ut/*/fm_pins*.tcl", "scripts/fm_eq.tcl", "scripts/*.tcl"]


def scan_text(text):
    """返回 [(行号, [坏字符...])] —— 只看会产生输出的语句行（及其续行）。"""
    out = []
    cont = False
    for i, line in enumerate(text.split("\n"), 1):
        if line.lstrip().startswith("#"):
            cont = False
            continue
        is_out = re.search(r"\b(puts|error)\b", line) is not None
        if is_out or cont:
            bad = sorted({c for c in line if 0x80 <= ord(c) <= 0xFF})
            if bad:
                out.append((i, bad))
            # 反斜杠续行的下一行仍属同一条语句
            cont = line.rstrip().endswith("\\")
        else:
            cont = False
    return out


def scan_files():
    files = []
    for p in PATTERNS:
        files += glob.glob(os.path.join(REPO, p))
    files = sorted(set(files))
    rc = 0
    print("=== FM Tcl 输出字符闸（puts/error 里不许有 U+0080..U+00FF）===")
    print("  扫描 %d 个 tcl" % len(files))
    for f in files:
        with open(f, encoding="utf-8") as fh:
            hits = scan_text(fh.read())
        if hits:
            rc = 1
            rel = os.path.relpath(f, REPO)
            for ln, bad in hits:
                print("  FAIL  %s:%d  输出里含 %s" % (rel, ln, " ".join(bad)))
                print("        这些字符会原样落成单字节进 fm.log，"
                      "让 fm_verdict.py 的 utf-8 解码当场崩（verdict 变空 / MAKE_RC=2）")
    if rc == 0:
        print("  ok    所有输出语句都只用 ASCII")
    return rc


def selftest():
    """★双向负测★：会抓真病因，也不许对合法写法误报。"""
    fails = 0
    cases = [
        # (说明, 文本, 期望命中数)
        ("真病因：puts 里的 × (U+00D7)",
         'puts "PINS: 11 bit × 2 port"\n', 1),
        ("真病因：error 里的 §",
         'error "PIN_ERROR: see § 2.6"\n', 1),
        ("真病因：反斜杠续行的第二行才带 ×",
         'error "PIN_ERROR: a \\\n   b × c"\n', 1),
        ("不误报：puts 里的中文（fm_shell 会换成 ?，不破坏 utf-8）",
         'puts "TLBSW_PINS: 钉了 22 对死位"\n', 0),
        ("不误报：注释里的 ×（入口回显保留 utf-8，安全）",
         '# 11 位 × 2 端口\nputs "PINS ok"\n', 0),
        ("不误报：纯 ASCII",
         'puts "PINS: 11 bits x 2 ports"\n', 0),
        ("不误报：非输出语句里的 ×（不进日志）",
         'set label "11 × 2"\n', 0),
    ]
    print("=== 自测（双向）===")
    for desc, text, want in cases:
        got = len(scan_text(text))
        ok = got == want
        print("  %-4s %s  命中 %d（期望 %d）" % ("[ok]" if ok else "[FAIL]", desc, got, want))
        if not ok:
            fails += 1
    print("  自测%s" % ("全过" if fails == 0 else "失败 %d 项" % fails))
    return fails


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(1 if selftest() else 0)
    sys.exit(scan_files())
