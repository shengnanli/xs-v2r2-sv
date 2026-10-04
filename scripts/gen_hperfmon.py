#!/usr/bin/env python3
"""gen_hperfmon.py —— HPerfMonitor / HPerfMonitor_1 / HPerfMonitor_2 的机械派生区生成器。

三个变体都是 utility.HPerfMonitor：N 个 HPerfCounter* 实例 + 每路两拍打拍。手写区（文件头、打拍寄存器）
不碰；本脚本只重写 rtl/common/<变体>.sv 里三个 GENERATED 区：
  ports    —— golden 端口表逐行照抄（端口名 / 方向 / 位宽，一行一个）；
  counters —— N 个计数器例化：实例名、模块名、连线全部从 golden 例化原样读出，
              逐个校验 fail-closed：
                * 每个实例的 io_hpm_event 必须接 io_hpm_event_<n>（n = 实例序号）；
                * io_perf_0_value 必须接 _<实例名>_io_perf_0_value（golden 的内部线），本脚本改接 counter_value[n]；
                * 其余每个端口必须"同名对接"（.io_events_sets_k_value(io_events_sets_k_value)），
                  且该名字确实是本模块的输入端口；
                * 子模块端口表（golden <child>.sv）与连线集合必须完全相等（一个不多一个不少）；
  outputs    —— io_perf_<n>_value = perf_qq[n]，n 取 golden 输出端口表，必须恰好 0..N-1 连续。
golden 寄存器表额外核对：恰好 2N 个 6 位 reg，名为 io_perf_<n>_value_REG / _REG_1（对应手写区的 perf_q / perf_qq）。

用法：
  python3 scripts/gen_hperfmon.py          # 重写三个文件的 GENERATED 区
  python3 scripts/gen_hperfmon.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
GOLDEN = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

VARIANTS = {            # 变体 -> (计数器模块, 计数器个数)
    "HPerfMonitor":   ("HPerfCounter", 8),
    "HPerfMonitor_2": ("HPerfCounter_13", 8),
    "HPerfMonitor_1": ("HPerfCounter_8", 5),
}

PORT = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')
INST = re.compile(r'^\s+(\w+)\s+(\w+)\s+\($')
CONN = re.compile(r'^\s+\.(\w+)\s+\(([\w]+)\),?$')


def die(msg):
    sys.exit(f"gen_hperfmon: {msg}")


def module_text(name):
    txt = open(os.path.join(GOLDEN, name + ".sv")).read()
    key = f"\nmodule {name}("
    if key not in txt:
        die(f"golden {name}.sv 里找不到 module {name}(")
    body = txt[txt.index(key) + 1:]
    return body[:body.index("\nendmodule")]


def ports(name):
    body = module_text(name)
    head = body[:body.index("\n);")]
    out = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            die(f"{name}: 端口行解析失败 {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4)))
    return out


def instances(name):
    """[(模块, 实例名, [(端口, 信号)])]，只认本文件里的子模块例化。"""
    lines = module_text(name).splitlines()
    res, cur = [], None
    for ln in lines:
        m = INST.match(ln)
        if m and cur is None and not ln.lstrip().startswith(("module", "input", "output")):
            cur = (m.group(1), m.group(2), [])
            continue
        if cur is not None:
            if ln.strip() == ");":
                res.append(cur)
                cur = None
                continue
            c = CONN.match(ln)
            if not c:
                die(f"{name}/{cur[1]}: 连线行解析失败 {ln!r}")
            cur[2].append((c.group(1), c.group(2)))
    if cur is not None:
        die(f"{name}: 例化 {cur[1]} 未闭合")
    return res


def render(variant):
    child, n = VARIANTS[variant]
    vp = ports(variant)
    inputs = {nm for d, _, nm in vp if d == "input"}
    outs = [nm for d, _, nm in vp if d == "output"]
    if outs != [f"io_perf_{i}_value" for i in range(n)]:
        die(f"{variant}: 输出端口表不是 io_perf_0..{n-1}_value: {outs}")
    # golden 寄存器表核对
    regs = re.findall(r'^\s+reg\s+\[5:0\]\s+(\w+);', module_text(variant), re.M)
    want = [f"io_perf_{i}_value_REG{s}" for i in range(n) for s in ("", "_1")]
    if sorted(regs) != sorted(want):
        die(f"{variant}: golden 寄存器表与 2N 个打拍寄存器不符: {regs}")
    child_ports = {nm for _, _, nm in ports(child)} - {"clock"} | {"clock"}
    insts = instances(variant)
    if len(insts) != n:
        die(f"{variant}: 期望 {n} 个例化，golden 有 {len(insts)}")
    ports_txt = []
    for i, (d, w, nm) in enumerate(vp):
        rng = f"[{w-1}:0]" if w > 1 else ""
        sep = "," if i < len(vp) - 1 else ""
        ports_txt.append(f"  {d:<6} logic {rng:<6} {nm}{sep}")
    cnt_txt = []
    for idx, (mod, inst, conns) in enumerate(insts):
        exp_inst = "perfEvents_hpc" if idx == 0 else f"perfEvents_hpc_{idx}"
        if mod != child or inst != exp_inst:
            die(f"{variant}: 第 {idx} 个例化是 {mod} {inst}，期望 {child} {exp_inst}")
        names = [p for p, _ in conns]
        if set(names) != child_ports or len(names) != len(child_ports):
            die(f"{variant}/{inst}: 连线集合与 {child} 端口表不等")
        cnt_txt.append(f"  {child} {inst} (")
        body = []
        for p, s in conns:
            if p == "io_hpm_event":
                if s != f"io_hpm_event_{idx}":
                    die(f"{variant}/{inst}: io_hpm_event 接 {s}，期望 io_hpm_event_{idx}")
                sig = s
            elif p == "io_perf_0_value":
                if s != f"_{inst}_io_perf_0_value":
                    die(f"{variant}/{inst}: io_perf_0_value 接 {s}")
                sig = f"counter_value[{idx}]"
            else:
                if p != s or s not in inputs:
                    die(f"{variant}/{inst}: .{p}({s}) 不是同名对接本模块输入")
                sig = s
            body.append(f"    .{p} ({sig})")
        width = max(len(p) for p, _ in conns)
        body = [f"    .{p:<{width}} ({b.split('(', 1)[1]}" for (p, _), b in zip(conns, body)]
        cnt_txt.append(",\n".join(body))
        cnt_txt.append("  );")
    out_txt = [f"  assign io_perf_{i}_value = perf_qq[{i}];" for i in range(n)]
    return {"ports": "\n".join(ports_txt), "counters": "\n".join(cnt_txt), "outputs": "\n".join(out_txt)}


def splice(text, tag, content, path):
    pat = re.compile(r"(// BEGIN GENERATED\(" + tag + r"\)\n)(.*?)(^[ \t]*// END GENERATED)", re.S | re.M)
    if len(pat.findall(text)) != 1:
        die(f"{path}: GENERATED({tag}) 区不是恰好一个")
    return pat.sub(lambda m: m.group(1) + content + "\n" + m.group(3), text)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    a = ap.parse_args()
    rc = 0
    for v in VARIANTS:
        path = os.path.join(REPO, "rtl", "common", v + ".sv")
        old = open(path).read()
        new = old
        for tag, content in render(v).items():
            new = splice(new, tag, content, path)
        if a.check:
            if new != old:
                print(f"[gencheck] {path} 与生成结果不一致（请跑 scripts/gen_hperfmon.py 刷新）")
                rc = 1
            else:
                print(f"[gencheck] {path} OK")
        elif new != old:
            open(path, "w").write(new)
            print(f"wrote {path}")
        else:
            print(f"unchanged {path}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
