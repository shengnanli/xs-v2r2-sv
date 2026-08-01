#!/usr/bin/env python3
# =====================================================================
# gen_rob_arr160_tb.py — 生成 Rob core 的 ROB_SIZE=160 边界定向 UT。
# ---------------------------------------------------------------------
# 目的(codex 0098 A): 验证 rob_entries[160] + index_in_range() guard:
#   - 合法下标(158/159): 读向量 mux 读出正确 entry 数据(功能 bit-exact)。
#   - 越界下标(160/255): guard → 'x, 输出为 X(不 clamp/wrap/取 entry-0)。
# 直接驱动 deq_ptr_vec[0]/deqPtr(核输入, 来自 golden 黑盒 deqPtr wrapper)到
# 边界值, 观察被 guard 的输出端口。生成完整显式端口表(不用 .* 以绕过
# tb/core 端口漂移)。tb body = scripts/rob_arr160_tb_body.svh(直驱+比对逻辑)。
#
# 用法: python3 scripts/gen_rob_arr160_tb.py
#   → 写 verif/ut/Rob/tb_arr160.sv (自包含, 可直接 make arr160-run)
# =====================================================================
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CORE = os.path.join(REPO, "rtl", "backend", "Rob.sv")
BODY = os.path.join(HERE, "rob_arr160_tb_body.svh")
OUT  = os.path.join(REPO, "verif", "ut", "Rob", "tb_arr160.sv")

def parse_ports(src):
    m = re.search(r'module\s+xs_Rob_core.*?\(\s*(.*?)\n\);', src, re.S)
    body = m.group(1)
    ports = []
    for line in body.splitlines():
        line = re.sub(r'//.*$', '', line).strip().rstrip(',').strip()
        if not line:
            continue
        mm = re.match(
            r'(input|output)\s+'
            r'(logic|rob_ptr_t|rob_entry_t|rob_commit_entry_t|rob_state_e)?\s*'
            r'((?:\[[^\]]*\]\s*)*)?\s*'
            r'([A-Za-z_][A-Za-z0-9_]*)\s*'
            r'((?:\[[^\]]*\]\s*)*)?$', line)
        if not mm:
            raise SystemExit(f"port parse fail: {line!r}")
        d, typ, packed, name, unpacked = mm.groups()
        ports.append((d, typ or 'logic', (packed or '').strip(),
                      name, (unpacked or '').strip()))
    return ports

def decl(typ, packed, name, unpacked):
    p = (packed + ' ') if packed else ''
    u = (' ' + unpacked) if unpacked else ''
    return f"  {typ} {p}{name}{u};"

def main():
    ports = parse_ports(open(CORE).read())
    lines = []
    lines.append("// 自动生成: scripts/gen_rob_arr160_tb.py —— 边界定向 UT, 勿手改")
    lines.append("`timescale 1ns/1ps")
    lines.append("import rob_pkg::*;")
    lines.append("module tb;")
    lines.append("  bit clk = 0; logic clock, reset; assign clock = clk;")
    lines.append("  int errors = 0, checks = 0;")
    lines.append("  always #5 clk = ~clk;")
    lines.append("")
    for d, typ, packed, name, unpacked in ports:
        if name in ('clock', 'reset'):
            continue
        lines.append(decl(typ, packed, name, unpacked))
    lines.append("")
    conns = [f".{name}({name})" for d, typ, packed, name, unpacked in ports]
    lines.append("  xs_Rob_core u_core (")
    lines.append("    " + ",\n    ".join(conns))
    lines.append("  );")
    lines.append("")
    lines.append(open(BODY).read())
    lines.append("endmodule")
    open(OUT, "w").write("\n".join(lines))
    print(f"wrote {OUT} ({len(ports)} ports)")

if __name__ == "__main__":
    main()
