#!/usr/bin/env python3
# =============================================================================
# gen_compressunit.py —— 生成 CompressUnit 的 golden 同端口 wrapper(及 UT 改名变体)。
# CompressUnit 端口是 6 条 lane × {valid, exceptionVec[24], trigger[4],
# canRobCompress, lastUop, commitType[3]} 输入 + 4 组 6 路输出,共 198 端口,
# 手写易错,故机械生成。本脚本只产 **端口适配层**(扁平端口 <-> 可读核 struct/数组),
# 不含任何算法逻辑(算法在 rtl/backend/CompressUnit.sv)。
#
# 用法: python3 gen_compressunit.py > ../rtl/backend/CompressUnit_wrapper.sv
#        python3 gen_compressunit.py --xs > ../verif/ut/CompressUnit/variants_xs.sv
# =============================================================================
import sys

W = 6      # RenameWidth
EXC = 24   # exceptionVec bits

def ports():
    lines = []
    for i in range(W):
        lines.append(f"  input         io_in_{i}_valid,")
        for j in range(EXC):
            lines.append(f"  input         io_in_{i}_bits_exceptionVec_{j},")
        lines.append(f"  input  [3:0]  io_in_{i}_bits_trigger,")
        lines.append(f"  input         io_in_{i}_bits_canRobCompress,")
        lines.append(f"  input         io_in_{i}_bits_lastUop,")
        lines.append(f"  input  [2:0]  io_in_{i}_bits_commitType,")
    outs = []
    for i in range(W):
        outs.append(f"  output        io_out_needRobFlags_{i}{{c}}")
    for i in range(W):
        outs.append(f"  output [2:0]  io_out_instrSizes_{i}{{c}}")
    for i in range(W):
        outs.append(f"  output [5:0]  io_out_masks_{i}{{c}}")
    for i in range(W):
        outs.append(f"  output        io_out_canCompressVec_{i}{{c}}")
    # last output no trailing comma
    for k in range(len(outs)):
        outs[k] = outs[k].format(c="," if k < len(outs)-1 else "")
    return "\n".join(lines + outs)

def body():
    b = []
    b.append("  compress_in_t [RENAME_WIDTH-1:0] in_w;")
    b.append("  logic [RENAME_WIDTH-1:0]             ccv, nrf;")
    b.append("  logic [RENAME_WIDTH-1:0][SIZE_W-1:0] sizes;")
    b.append("  logic [RENAME_WIDTH-1:0][MASK_W-1:0] masks_w;")
    b.append("")
    for i in range(W):
        exc = "{" + ", ".join(f"io_in_{i}_bits_exceptionVec_{j}" for j in range(EXC-1, -1, -1)) + "}"
        b.append(f"  assign in_w[{i}] = '{{")
        b.append(f"    valid:          io_in_{i}_valid,")
        b.append(f"    exceptionVec:   {exc},")
        b.append(f"    trigger:        io_in_{i}_bits_trigger,")
        b.append(f"    canRobCompress: io_in_{i}_bits_canRobCompress,")
        b.append(f"    lastUop:        io_in_{i}_bits_lastUop,")
        b.append(f"    commitType:     io_in_{i}_bits_commitType")
        b.append(f"  }};")
    b.append("")
    b.append("  xs_CompressUnit_core u_core (")
    b.append("    .in               (in_w),")
    b.append("    .can_compress_vec (ccv),")
    b.append("    .need_rob_flags   (nrf),")
    b.append("    .instr_sizes      (sizes),")
    b.append("    .masks            (masks_w)")
    b.append("  );")
    b.append("")
    for i in range(W):
        b.append(f"  assign io_out_needRobFlags_{i}    = nrf[{i}];")
    for i in range(W):
        b.append(f"  assign io_out_instrSizes_{i}      = sizes[{i}];")
    for i in range(W):
        b.append(f"  assign io_out_masks_{i}           = masks_w[{i}];")
    for i in range(W):
        b.append(f"  assign io_out_canCompressVec_{i}  = ccv[{i}];")
    return "\n".join(b)

def emit(name, header):
    print(header)
    print("import compressunit_pkg::*;")
    print()
    print(f"module {name} (")
    print(ports())
    print(");")
    print()
    print(body())
    print()
    print("endmodule")

if __name__ == "__main__" and "--bridge" not in sys.argv:
    if "--xs" in sys.argv:
        hdr = ("// CompressUnit_xs —— UT 用可读核包装(golden 同端口,改名避免与 golden 冲突)。\n"
               "// 由 scripts/gen_compressunit.py --xs 生成。仅端口适配,无算法逻辑。")
        emit("CompressUnit_xs", hdr)
    else:
        hdr = ("// =============================================================================\n"
               "// CompressUnit (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/CompressUnit.sv\n"
               "// 完全一致。机械生成的端口适配层:扁平端口 <-> 可读核 xs_CompressUnit_core 的\n"
               "// struct/数组端口。算法逻辑在 rtl/backend/CompressUnit.sv。\n"
               "// 由 scripts/gen_compressunit.py 生成。\n"
               "// =============================================================================")
        emit("CompressUnit", hdr)


# -----------------------------------------------------------------------------
# 额外:生成 UT 用的 cu_bridge 模块,把 tb 的数组信号连到 golden CompressUnit(u_g)
# 与可读核 CompressUnit_xs(u_i) 的 198 个扁平端口,并把两者输出引出为数组。
# 用法: python3 gen_compressunit.py --bridge > ../verif/ut/CompressUnit/cu_bridge.sv
# -----------------------------------------------------------------------------
def gen_bridge():
    L = []
    L.append("// cu_bridge —— UT 数组信号 <-> 两个 DUT 扁平端口的桥接(机械生成)。")
    L.append("// 由 scripts/gen_compressunit.py --bridge 生成。")
    L.append("module cu_bridge #(parameter int W=6, parameter int EXC=24) (")
    L.append("  input  logic            v   [W],")
    L.append("  input  logic [EXC-1:0]  exc [W],")
    L.append("  input  logic [3:0]      trg [W],")
    L.append("  input  logic            crc [W],")
    L.append("  input  logic            lu  [W],")
    L.append("  input  logic [2:0]      ct  [W],")
    L.append("  output logic            g_nrf [W], i_nrf [W],")
    L.append("  output logic [2:0]      g_sz  [W], i_sz  [W],")
    L.append("  output logic [5:0]      g_mk  [W], i_mk  [W],")
    L.append("  output logic            g_ccv [W], i_ccv [W]")
    L.append(");")
    def inst(modname, pfx):
        s = [f"  {modname} u (".replace(" u ", f" u_{pfx} ")]
        for i in range(W):
            s.append(f"    .io_in_{i}_valid(v[{i}]),")
            for j in range(EXC):
                s.append(f"    .io_in_{i}_bits_exceptionVec_{j}(exc[{i}][{j}]),")
            s.append(f"    .io_in_{i}_bits_trigger(trg[{i}]),")
            s.append(f"    .io_in_{i}_bits_canRobCompress(crc[{i}]),")
            s.append(f"    .io_in_{i}_bits_lastUop(lu[{i}]),")
            s.append(f"    .io_in_{i}_bits_commitType(ct[{i}]),")
        outconn = []
        for i in range(W):
            outconn.append(f"    .io_out_needRobFlags_{i}({pfx}_nrf[{i}])")
        for i in range(W):
            outconn.append(f"    .io_out_instrSizes_{i}({pfx}_sz[{i}])")
        for i in range(W):
            outconn.append(f"    .io_out_masks_{i}({pfx}_mk[{i}])")
        for i in range(W):
            outconn.append(f"    .io_out_canCompressVec_{i}({pfx}_ccv[{i}])")
        s.append("\n".join(o + "," for o in outconn[:-1]) + "\n    " + outconn[-1].strip())
        s.append("  );")
        return "\n".join(s)
    L.append(inst("CompressUnit", "g"))
    L.append(inst("CompressUnit_xs", "i"))
    L.append("endmodule")
    return "\n".join(L)

if "--bridge" in sys.argv:
    print(gen_bridge())
