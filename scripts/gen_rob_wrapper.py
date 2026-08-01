#!/usr/bin/env python3
"""
gen_rob_wrapper.py —— 生成 rtl/backend/Rob_wrapper.sv (FM impl 侧顶层 `Rob`)。

FM assembly 装配壳(与 golden Rob.sv 同名同 2343-output 端口):
  1) 6 golden 逻辑叶子(两侧 elaborate 白盒): rab/vtypeBuffer/snapshots_snapshotGen/
     exceptionGen/deqPtrGenModule/enqPtrGenModule —— **原样**从 golden 抽取实例块,
     只把 66 body-glue net 重连到 xs_Rob_core 输出 / flat-port 组合译码(非空耦合);
     其输出净 _<leaf>_io_* 驱动 2081 leaf-passthrough 顶层输出 + 喂回 u_core;
  2) difftest 叶子链(两侧 elaborate)+ _ext 内存 —— 无 top-output, DPI sink = 黑盒;
  3) xs_Rob_core u_core —— 输入 = 叶子输出净 + flat-port 译码(**复用已验证的
     tb_tap.sv u_i 驱动块**, 把 u_g. 前缀去掉即成 wrapper 本地叶子净); 输出 =
     A_CORE(70)+C_DEEP(100), 驱动 262 body 输出中的 170;
  4) rob_lsq_deep_outputs —— lsq(5)/gpaddr(2)/toDecode(1)/error(1) 9 口;
  5) B_SHALLOW(92) —— wrapper 侧 RegNext(both-side 叶子输出) 复刻。

u_core 输入驱动来源 = tb_tap.sv 行[UI_START..UI_END] 的 u_i 驱动块(已 seed1/7/42
errors=0 验证), 转换: `u_g.` -> 本地净(叶子输出); `u_i` -> `u_core`。
"""
import re, sys, json
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = Path("/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv")
if not GOLDEN.exists():
    GOLDEN = XSSV / "golden/chisel-rtl/Rob.sv"


def read_golden():
    return GOLDEN.read_text().splitlines()


def extract_port_header(lines):
    out, started = [], False
    for ln in lines:
        if ln.startswith("module Rob("):
            started = True
        if started:
            out.append(ln)
            if ln.strip() == ");":
                break
    return out


def find_instances(lines):
    inst_re = re.compile(r"^  ([A-Z][A-Za-z0-9_]+|[a-z_][A-Za-z0-9_]*_ext) +([A-Za-z_][A-Za-z0-9_]*) +\($")
    insts = []
    i, n = 0, len(lines)
    while i < n:
        m = inst_re.match(lines[i])
        if m:
            j = i + 1
            while j < n and lines[j].strip() != ");":
                j += 1
            insts.append((m.group(1), m.group(2), i, j))
            i = j + 1
        else:
            i += 1
    return insts


def subst_expr(e):
    """Map a golden leaf-input glue expr to the wrapper net (u_core o_* or local decode)."""
    e = e.strip()
    if e in ("{1'h0, state}", "{1'h0,state}"):
        return "{1'h0, o_state}"
    if e == "state & walkFinished":
        return "o_rab_walkEnd"
    if e == "allowEnqueue & _rab_io_canEnq & ~io_fromVecExcpMod_busy":
        return "o_allowEnqueue & _rab_io_canEnq & ~io_fromVecExcpMod_busy"
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", e):
        if e == "io_flushOut_valid_0":   # exceptionGen.io_flush = flushOut.valid
            return "o_flushOut_valid"
        m = re.match(r"^robDeqGroup_(\d+)_commit_([vw])$", e)
        if m:
            return f"o_deq_commit_{m.group(2)}[{m.group(1)}]"
        m = re.match(r"^hasCommitted_(\d+)$", e)
        if m:
            return f"o_hasCommitted[{m.group(1)}]"
        m = re.match(r"^canEnqueueEG_(\d+)$", e)
        if m:
            return f"canEnqueueEG_{m.group(1)}"
        m = re.match(r"^_dispatchNum_T(?:_(\d+))?$", e)
        if m:
            return f"o_enq_for_ptr[{m.group(1) or '0'}]"
        gmap = {
            "hasBlockBackward": "o_hasBlockBackward",
            "hasWaitForward": "o_hasNoSpecExec",
            "intrBitSetReg": "o_intrBitSetReg",
            "allowOnlyOneCommit": "o_allowOnlyOneCommit",
            "blockCommit": "o_blockCommit",
            "rawInfo_0_interrupt_safe": "o_commit_info_0_interrupt_safe",
            "snptEnq": "snptEnq",
            "rab_io_fromRob_vecLoadExcp_valid_REG": "rab_vecLoadExcp_valid_REG",
        }
        return gmap.get(e)
    return None


def subst_glue(block):
    out = []
    i, n = 0, len(block)
    while i < n:
        ln = block[i]
        m = re.match(r"(\s*)\.io_fromRob_walkSize\b", ln)
        if m:
            j = i
            while j < n and not block[j].rstrip().endswith("),"):
                j += 1
            out.append(f"{m.group(1)}.io_fromRob_walkSize (o_rab_walkSize),")
            i = j + 1
            continue
        m = re.match(r"(\s*)\.io_fromRob_commitSize\b", ln)
        if m:
            j = i
            while j < n and not block[j].rstrip().endswith("),"):
                j += 1
            out.append(f"{m.group(1)}.io_fromRob_commitSize (o_rab_commitSize),")
            i = j + 1
            continue
        # enqPtr .io_allowEnqueue spans 2 lines: allowEnqueue(reg) -> o_allowEnqueue
        m = re.match(r"(\s*)\.io_allowEnqueue\b", ln)
        if m and "(" not in ln:
            j = i
            while j < n and not block[j].rstrip().endswith("),"):
                j += 1
            out.append(f"{m.group(1)}.io_allowEnqueue (o_allowEnqueue & _rab_io_canEnq & ~io_fromVecExcpMod_busy),")
            i = j + 1
            continue
        cm = re.match(r"(\s*\.[A-Za-z0-9_]+\s*)\((.*?)\)(,?)\s*$", ln)
        if cm:
            new = subst_expr(cm.group(2))
            if new is not None:
                out.append(f"{cm.group(1)}({new}){cm.group(3)}")
                i += 1
                continue
        out.append(ln)
        i += 1
    return out


def main():
    lines = read_golden()
    header = extract_port_header(lines)
    insts = find_instances(lines)

    parts = []
    W = parts.append
    for ln in header:
        W(ln)
    W("")
    W("  import rob_pkg::*;")
    W("")
    # hand-written prelude: leaf-output net decls, glue defs, u_core-o alias nets,
    # u_core input wiring (from tb_tap), u_core instance, B_SHALLOW RegNext.
    prelude = XSSV / "scripts/rob_wrapper_prelude.svh"
    W(prelude.read_text() if prelude.exists() else "  // PRELUDE MISSING")
    W("")
    # leaf instances (glue-substituted)
    for mod, nm, s, e in insts:
        W(f"  // ---- {mod} {nm} ----")
        parts.extend(subst_glue(lines[s:e + 1]))
        W("")
    # 262 body output assigns + 2081 leaf-passthrough handled by named leaf-port
    # connections above (io_TOP already appears as the .port net in golden blocks).
    epilogue = XSSV / "scripts/rob_wrapper_epilogue.svh"
    W(epilogue.read_text() if epilogue.exists() else "  // EPILOGUE MISSING")
    W("endmodule")

    dst = XSSV / "rtl/backend/Rob_wrapper.sv"
    dst.write_text("\n".join(parts) + "\n")
    print("wrote", dst, "lines:", len(parts), file=sys.stderr)


if __name__ == "__main__":
    main()
