#!/usr/bin/env python3
"""bench_verdict.py —— 把 golden / impl 两侧同一负载的 sim.log 做机械对照。

判据（codex 0160 的三条验收）：
  1. 正常终止        : 出现 `HIT GOOD TRAP` 且没有 `HIT BAD TRAP` / `EXCEEDED MAX CYCLE`
  2. 架构输出完全相同: 归一化后的日志正文（= 负载的 UART 输出 + TRAP + instrCnt/cycleCnt）
                       两侧逐字节相同
  3. difftest 失配 0 : 没有 `different at pc` / `Mismatch` / `DIFFTEST FAILED` / `ABORT`

归一化只删掉与被测设计无关的仿真器噪声（VCS 版本/路径/编译时间戳/墙钟/仿真时间），
其中 **仿真时间刻意剔除**：impl 侧 rtl/uncore/SubDirectory{,_1}.sv 带 `timescale 1ns/1ps`
（golden 无任何 timescale），导致 `$finish at simulation time` 的单位是 ps 而非 ns。
这是编译期时间精度差异，不是架构差异（cycleCnt 两侧相同可证），交由 collateral 泳道处理。

用法: bench_verdict.py <golden/sim.log> <impl/sim.log> [标签]
"""
import re, sys, pathlib

ANSI = re.compile(r"\x1b\[[0-9;]*m")
DROP = [
    r"^Chronologic VCS", r"^Contains Synopsys", r"^Compiler version",
    r"^ram image:", r"^diff-test ref so:", r"^simv compiled at",
    r"^The image is ", r"^The reference model is ",
    r"^\$finish called from file", r"^\$finish at simulation time",
    r"^ *V C S +S i m u l a t i o n +R e p o r t", r"^Time: ", r"^CPU Time:",
    r"^[A-Z][a-z]{2} [A-Z][a-z]{2} +\d+ \d+:\d+:\d+ \d{4}$",
    r"^\s*$",
]
DROP_RE = re.compile("|".join(DROP))
MISMATCH = re.compile(r"different at pc|Mismatch|DIFFTEST FAILED|ABORT at pc|HIT BAD TRAP", re.I)


def norm(p):
    txt = ANSI.sub("", pathlib.Path(p).read_text(errors="replace"))
    return [l.rstrip() for l in txt.splitlines() if not DROP_RE.match(l.rstrip())]


def facts(lines):
    j = "\n".join(lines)
    g = lambda pat: (re.search(pat, j).group(0) if re.search(pat, j) else None)
    return {
        "trap": g(r"HIT (GOOD|BAD) TRAP at pc = 0x[0-9a-f]+"),
        "counts": g(r"instrCnt = [\d,]+, cycleCnt = [\d,]+, IPC = [\d.]+"),
        "done": g(r"DIFFTEST WORKLOAD DONE at cycle\s+\d+"),
        "maxcycle": g(r"EXCEEDED MAX CYCLE:\s+\d+"),
        "difftest_on": "Difftest enabled" in j,
        "mismatches": len(MISMATCH.findall(j)),
    }


def main():
    gp, ip = sys.argv[1], sys.argv[2]
    tag = sys.argv[3] if len(sys.argv) > 3 else pathlib.Path(gp).parent.name
    gl, il = norm(gp), norm(ip)
    gf, iff = facts(gl), facts(il)
    print(f"===== {tag} =====")
    for k in gf:
        mark = "==" if gf[k] == iff[k] else "!!"
        print(f"  {k:14s} {mark} golden={gf[k]!r}  impl={iff[k]!r}")
    same = gl == il
    print(f"  {'normalized-log':14s} {'==' if same else '!!'} "
          f"{'IDENTICAL' if same else 'DIFFERENT'} ({len(gl)} vs {len(il)} lines)")
    if not same:
        import difflib
        d = list(difflib.unified_diff(gl, il, "golden", "impl", lineterm="", n=2))
        print("  --- first 60 diff lines ---")
        for l in d[:60]:
            print("   " + l)
    ok = (same and gf["difftest_on"] and gf["mismatches"] == 0 and iff["mismatches"] == 0
          and gf["trap"] and gf["trap"].startswith("HIT GOOD") and not gf["maxcycle"])
    print(f"  VERDICT: {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
