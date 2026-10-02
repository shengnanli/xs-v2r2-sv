#!/usr/bin/env python3
"""gen_pmpchecker.py —— PMPChecker 家族三个薄 wrapper 的生成器。

生成对象（纯机械：golden 端口表 + 把 32 项扁平端口装成数组接到共用核）：
  rtl/backend/PMPChecker.sv      sameCycle=true（L2TLB 的页表访存口，cmd 恒为读）
  rtl/backend/PMPChecker_2.sv    结果打一拍（Frontend 取指口，cmd 恒为取指）
  rtl/backend/PMPChecker_12.sv   leaveHitMux=true（MemBlock 访存口，cmd 由端口给）
  verif/ut/PMPChecker/fm_pins_pre.tcl   PMPChecker_12 的 FM「匹配前」钉点（见 gen_pins）
手写逻辑全部在 rtl/backend/xs_PMPChecker_core.sv，本脚本不碰。

端口表逐字取自 G1 golden 同名模块（顺序/名字/位宽全同）。fail-closed 核对：
  (1) golden 的每个端口恰好命中一条映射规则（表项字段 / env / req / resp / clock / reset），
      命中不了即报错；
  (2) 表项字段在 32 项上必须齐（某字段要么 32 项都有、要么都没有）；
  (3) golden 没有的表项字段 / cmd 由 wrapper 接常量：字段接 0，cmd 接本变体的固定访问类型
      （firtool 就是因为父模块把 cmd 接成常量才把这些端口消掉的）；
  (4) RESP_USED 由 golden 实际存在的 resp 端口推出。
--check：生成结果与磁盘逐字节比较，有漂移 rc=1。
"""
import argparse
import os
import re
import sys

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.normpath(os.path.join(HERE, "..", "rtl", "backend"))

NUM = 32
PMP_FIELDS = ["l", "a", "x", "w", "r"]
PMA_FIELDS = ["c", "atomic", "a", "x", "w", "r"]
RESP = ["ld", "st", "instr", "mmio", "atomic"]   # RESP_USED 的 bit 0..4

# 变体表：核参数 + 固定 cmd（None = 由端口给）+ 文件头说明
VARIANTS = {
    "PMPChecker": dict(
        same_cycle=1, hit_mux=0, cmd="3'b000",
        brief="页表遍历器访存口的 PMP/PMA 检查（纯组合，当拍出结果）",
        notes=[
            "Scala：L2TLB.scala `new PMPChecker(lgMaxSize = 3, sameCycle = true)`。",
            "访问类型恒为读（TlbCmd.read），所以 golden 没有 cmd 口，表项的 x/w 位也被消掉；",
            "输出只剩 ld / mmio / atomic。无寄存器，clock/reset 都没有。",
        ]),
    "PMPChecker_2": dict(
        same_cycle=0, hit_mux=0, cmd="3'b010",
        brief="取指口的 PMP/PMA 检查（组合算完，结果打一拍）",
        notes=[
            "Scala：Frontend.scala `new PMPChecker(3)`（sameCycle / leaveHitMux 都是缺省 false）。",
            "访问类型恒为取指（TlbCmd.exec），所以 golden 没有 cmd 口，表项只留 x 位；",
            "父模块只接了 instr / mmio，另外三个结果寄存器被 firtool 删掉（RESP_USED）。",
            "结果寄存器由 io_req_valid 使能、不复位，所以没有 reset 口。",
        ]),
    "PMPChecker_12": dict(
        same_cycle=0, hit_mux=1, cmd=None,
        brief="访存口（DTLB 之后）的 PMP/PMA 检查（命中位先打一拍，下一拍选项出结果）",
        notes=[
            "Scala：MemBlock.scala `new PMPChecker(4, leaveHitMux = true)`。",
            "五种结果全用；cmd 由端口给并跟着命中位打一拍。命中位带异步复位，其余寄存器不复位。",
        ]),
}

PORT = re.compile(r"\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?([A-Za-z_]\w*)\s*,?\s*$")


def port_table(module):
    """golden 顶层端口表：[(dir, width, name, 原文行)]，顺序即 golden 顺序。"""
    lines = open(os.path.join(GOLDEN_DIR, module + ".sv")).read().split("\n")
    start = next(i for i, l in enumerate(lines) if l.startswith("module %s(" % module))
    end = start
    while not lines[end].startswith(");"):
        end += 1
    out = []
    for l in lines[start + 1:end]:
        m = PORT.match(l)
        if not m:
            raise SystemExit("gen_pmpchecker: 端口行解析失败: %r" % l)
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        out.append((m.group(1), w, m.group(4), l.rstrip(",").rstrip()))
    return out


ENTRY = re.compile(r"io_check_env_(pmp|pma)_(\d+)_(?:cfg_(\w+)|(addr|mask))$")
WIDTH = {"a": 2, "addr": 46, "mask": 48}
SCALAR = {
    "clock": ("input", 1), "reset": ("input", 1),
    "io_check_env_mode": ("input", 2), "io_check_env_debug": ("input", 1),
    "io_req_valid": ("input", 1), "io_req_bits_addr": ("input", 48), "io_req_bits_cmd": ("input", 3),
}


def classify(module):
    """返回 (ports, have)：have[('pmp','x')] = True 表示该字段 32 项齐全。"""
    ports = port_table(module)
    seen = {}
    scalars = set()
    resps = set()
    for d, w, n, _ in ports:
        m = ENTRY.match(n)
        if m:
            kind, idx, field = m.group(1), int(m.group(2)), m.group(3) or m.group(4)
            allowed = (PMP_FIELDS if kind == "pmp" else PMA_FIELDS) + ["addr", "mask"]
            if field not in allowed or idx >= NUM or d != "input" or w != WIDTH.get(field, 1):
                raise SystemExit("gen_pmpchecker: %s 端口 %s 不符合表项字段形状" % (module, n))
            seen.setdefault((kind, field), set()).add(idx)
        elif n in SCALAR:
            if (d, w) != SCALAR[n]:
                raise SystemExit("gen_pmpchecker: %s 端口 %s 方向/位宽不符" % (module, n))
            scalars.add(n)
        elif n.startswith("io_resp_") and n[len("io_resp_"):] in RESP:
            if d != "output" or w != 1:
                raise SystemExit("gen_pmpchecker: %s 端口 %s 方向/位宽不符" % (module, n))
            resps.add(n[len("io_resp_"):])
        else:
            raise SystemExit("gen_pmpchecker: %s 端口 %s 没有命中任何映射规则" % (module, n))
    for key, idxs in seen.items():
        if idxs != set(range(NUM)):
            raise SystemExit("gen_pmpchecker: %s 字段 %s_%s 不是 %d 项齐全" % (module, key[0], key[1], NUM))
    for must in [("pmp", "a"), ("pmp", "addr"), ("pmp", "mask"), ("pma", "a"), ("pma", "addr"), ("pma", "mask"),
                 ("pmp", "l")]:
        if must not in seen:
            raise SystemExit("gen_pmpchecker: %s 缺必需字段 %s_%s" % (module, must[0], must[1]))
    for must in ["io_check_env_mode", "io_check_env_debug", "io_req_bits_addr"]:
        if must not in scalars:
            raise SystemExit("gen_pmpchecker: %s 缺端口 %s" % (module, must))
    return ports, set(seen), scalars, resps


def gen(module):
    v = VARIANTS[module]
    ports, have, scalars, resps = classify(module)
    if (v["cmd"] is None) != ("io_req_bits_cmd" in scalars):
        raise SystemExit("gen_pmpchecker: %s 的 cmd 端口有无与变体表不一致" % module)
    registered = not v["same_cycle"]
    if registered != ("clock" in scalars):
        raise SystemExit("gen_pmpchecker: %s 的 clock 端口有无与变体表不一致" % module)
    if bool(v["hit_mux"]) != ("reset" in scalars):
        raise SystemExit("gen_pmpchecker: %s 的 reset 端口有无与变体表不一致" % module)
    resp_used = sum(1 << k for k, r in enumerate(RESP) if r in resps)

    o = []
    o.append("// =============================================================================")
    o.append("// %s —— %s" % (module, v["brief"]))
    o.append("//")
    o.append("// 薄 wrapper：逻辑全部在共用核 xs_PMPChecker_core（同目录 xs_PMPChecker_core.sv，机制讲在那里）。")
    for n in v["notes"]:
        o.append("// " + n)
    o.append("// 本层只做端口展平：golden 的 32 项扁平 io_check_env_{pmp,pma}_<i>_* <-> 核的数组端口；")
    o.append("// golden 没有的字段接 0、固定的访问类型接常量。")
    o.append("// 端口表逐字抄自 G1 golden 同名模块。自动生成：scripts/gen_pmpchecker.py —— 勿手改")
    o.append("// =============================================================================")
    o.append("")
    o.append("module %s(" % module)
    for i, (_, _, _, raw) in enumerate(ports):
        o.append(raw + ("," if i != len(ports) - 1 else ""))
    o.append(");")
    o.append("")
    o.append("  localparam int unsigned NUM_ENTRY = %d;" % NUM)
    o.append("")
    decl = []
    for kind, fields in (("pmp", PMP_FIELDS), ("pma", PMA_FIELDS)):
        for f in fields + ["addr", "mask"]:
            w = WIDTH.get(f, 1)
            rng = "[%d:0] " % (w - 1) if w > 1 else ""
            decl.append((kind, f, "  logic [NUM_ENTRY-1:0]%s %s_%s;" % (rng.rstrip() and rng.rstrip() or "", kind, f)))
    for _, _, line in decl:
        o.append(line.replace("]  ", "] ").replace("] [", "]["))
    o.append("")
    for kind, fields in (("pmp", PMP_FIELDS), ("pma", PMA_FIELDS)):
        for f in fields + ["addr", "mask"]:
            if (kind, f) in have:
                suffix = f if f in ("addr", "mask") else "cfg_" + f
                o.append("  assign %s_%s = {" % (kind, f))
                for i in range(NUM - 1, -1, -1):
                    o.append("    io_check_env_%s_%d_%s%s" % (kind, i, suffix, "," if i else ""))
                o.append("  };")
            else:
                o.append("  assign %s_%s = '0;  // golden 无此字段端口（本变体的访问类型用不到）" % (kind, f))
    o.append("")
    o.append("  xs_PMPChecker_core #(")
    o.append("    .NUM_ENTRY     (NUM_ENTRY),")
    o.append("    .SAME_CYCLE    (1'b%d)," % v["same_cycle"])
    o.append("    .LEAVE_HIT_MUX (1'b%d)," % v["hit_mux"])
    o.append("    .RESP_USED     (5'b%s)" % format(resp_used, "05b"))
    o.append("  ) u_core (")
    conn = []
    conn.append(("clock", "clock" if "clock" in scalars else "1'b0"))
    conn.append(("reset", "reset" if "reset" in scalars else "1'b0"))
    conn.append(("env_mode", "io_check_env_mode"))
    conn.append(("env_debug", "io_check_env_debug"))
    for kind, fields in (("pmp", PMP_FIELDS), ("pma", PMA_FIELDS)):
        for f in fields + ["addr", "mask"]:
            conn.append(("%s_%s" % (kind, f), "%s_%s" % (kind, f)))
    conn.append(("req_valid", "io_req_valid" if "io_req_valid" in scalars else "1'b1"))
    conn.append(("req_addr", "io_req_bits_addr"))
    conn.append(("req_cmd", "io_req_bits_cmd" if v["cmd"] is None else v["cmd"]))
    for r in RESP:
        conn.append(("resp_" + r, "io_resp_" + r if r in resps else ""))
    for i, (p, s) in enumerate(conn):
        o.append("    .%-11s (%s)%s" % (p, s, "," if i != len(conn) - 1 else ""))
    o.append("  );")
    o.append("")
    o.append("endmodule")
    return "\n".join(o) + "\n"


# ---------------------------------------------------------------------------
# PMPChecker_12 的 FM「匹配前」钉点
#   golden 的寄存器是 firtool 展平名（res_pmp_r / res_pmp_r_<i> / res_pmp_r_33_<i>_cfg_x ...），
#   重写核是按字段的数组（g_hitmux.pmp_match_q[i] / pmp_x_q[i] ...）。不钉时 FM 的名字匹配会把
#   golden 的 res_pmp_r_33_<i>_cfg_r 与别的寄存器错配（2026-10-02 非正式试跑：62(62) unmatched、
#   failing 至少 20，截断）。钉点只消名差：每个 golden 寄存器恰好命中一条规则、映射是单射，
#   否则生成失败；运行时逐条数 set_user_match 返回值，拒一条或总数不等于字面整数即 error。
#   另两个变体（PMPChecker 无寄存器、PMPChecker_2 只有 2 个）不需要钉，文件按 $top 分支。
# ---------------------------------------------------------------------------
PIN_TOP = "PMPChecker_12"
PIN_RULES = [
    (re.compile(r"res_(pmp|pma)_r$"), lambda m: "%s_match_q_reg[0]" % m.group(1)),
    (re.compile(r"res_(pmp|pma)_r_(\d+)$"), lambda m: "%s_match_q_reg[%s]" % (m.group(1), m.group(2))),
    (re.compile(r"res_(pmp|pma)_r_33_(\d+)_cfg_(\w+)$"),
     lambda m: "%s_%s_q_reg[%s]" % (m.group(1), m.group(3), m.group(2))),
    (re.compile(r"cmd$"), lambda m: "cmd_q_reg"),
]
REG_DECL = re.compile(r"^  reg\s+(?:\[(\d+):(\d+)\]\s*)?(\w+);\s*$")


def golden_regs(module):
    out = []
    for l in open(os.path.join(GOLDEN_DIR, module + ".sv")).read().split("\n"):
        m = REG_DECL.match(l)
        if m:
            out.append((m.group(3), int(m.group(1)) - int(m.group(2)) + 1 if m.group(1) else 1))
    return out


def gen_pins():
    regs = golden_regs(PIN_TOP)
    pairs = []
    seen = set()
    for name, w in regs:
        hits = [fn(r.match(name)) for r, fn in PIN_RULES if r.match(name)]
        if len(hits) != 1:
            raise SystemExit("gen_pmpchecker: golden 寄存器 %s 命中 %d 条钉点规则（要求恰好 1 条）" % (name, len(hits)))
        tgt = hits[0]
        if w == 1:
            bits = [(name + "_reg", tgt)]
        else:
            bits = [("%s_reg[%d]" % (name, b), "%s[%d]" % (tgt, b)) for b in range(w)]
        for g, i in bits:
            if i in seen:
                raise SystemExit("gen_pmpchecker: 两个 golden 寄存器位映射到同一个重写寄存器位 %s（不是双射）" % i)
            seen.add(i)
            pairs.append((g, i))
    total = len(pairs)
    esc = lambda x: x.replace("[", "\\[").replace("]", "\\]")
    o = []
    o.append("# PMPChecker 家族 FM「匹配前」钉点 -- 自动生成：scripts/gen_pmpchecker.py（勿手改）")
    o.append("#")
    o.append("# 只对 PMPChecker_12 生效：消 golden 展平寄存器名与重写核按字段数组名之间的命名鸿沟。")
    o.append("# set_user_match 只是声明两点对应，比较照比：不约束 ref、不改 appvar、不加黑盒。")
    o.append("# fail-closed：set_user_match 从不抛异常（返回 0 = 没配上），所以逐条数返回值；")
    o.append("# 拒一条或总数不等于字面整数（= golden 寄存器位数）就 error。进 fm.log 的输出一律 ASCII。")
    o.append("if {$top eq \"%s\"} {" % PIN_TOP)
    o.append("  set ::PMPCHK_PIN_EXPECT %d" % total)
    o.append("  set ::PMPCHK_PIN_OK 0")
    o.append("  set ::PMPCHK_PIN_BAD 0")
    o.append("  proc pmpchk_pin {g i} {")
    o.append("    if {[set_user_match \"r:/WORK/%s/$g\" \"i:/WORK/%s/u_core/g_hitmux.$i\"]} {" % (PIN_TOP, PIN_TOP))
    o.append("      incr ::PMPCHK_PIN_OK")
    o.append("    } else {")
    o.append("      incr ::PMPCHK_PIN_BAD")
    o.append("      if {$::PMPCHK_PIN_BAD <= 10} { puts \"PMPCHK_PIN_FAIL: $g <-> $i\" }")
    o.append("    }")
    o.append("  }")
    o.append("  puts \"PMPCHK_PIN_BEGIN %s expect=$::PMPCHK_PIN_EXPECT\"" % PIN_TOP)
    for g, i in pairs:
        o.append("  pmpchk_pin {%s} {%s}" % (g, i))
    o.append("  puts \"PMPCHK_PIN_END %s ok=$::PMPCHK_PIN_OK bad=$::PMPCHK_PIN_BAD\"" % PIN_TOP)
    o.append("  if {$::PMPCHK_PIN_BAD != 0} { error \"PMPCHK_PIN_MISS=$::PMPCHK_PIN_BAD\" }")
    o.append("  if {$::PMPCHK_PIN_OK != %d} { error \"PMPCHK_PIN_COUNT=$::PMPCHK_PIN_OK expect=%d\" }" % (total, total))
    o.append("}")
    return "\n".join(o) + "\n"


PINS_PATH = os.path.normpath(os.path.join(HERE, "..", "verif", "ut", "PMPChecker", "fm_pins_pre.tcl"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只比对不写，有漂移 rc=1")
    args = ap.parse_args()
    rc = 0
    outs = [(os.path.join(RTL, module + ".sv"), gen(module)) for module in VARIANTS]
    outs.append((PINS_PATH, gen_pins()))
    for path, txt in outs:
        old = open(path).read() if os.path.exists(path) else None
        if args.check:
            if old != txt:
                print("[gen_pmpchecker] DRIFT %s" % path)
                rc = 1
            else:
                print("[gen_pmpchecker] OK %s" % path)
        elif old != txt:
            open(path, "w").write(txt)
            print("wrote %s" % path)
        else:
            print("unchanged %s" % path)
    return rc


if __name__ == "__main__":
    sys.exit(main())
