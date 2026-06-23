#!/usr/bin/env python3
"""
CtrlBlock 双例化 UT 生成器（仿 DataPath UT）。

产出 verif/ut/CtrlBlock/{tb.sv, variants_xs.sv, Makefile}：
  - tb.sv         : 输入端口为 logic 寄存器（negedge 随机驱动），输出端口分 g_/i_ 两套 wire。
                    u_g = golden CtrlBlock；u_i = CtrlBlock_xs（可读核 wrapper）。
                    每拍 #4 后逐输出端口比对，!$isunknown(golden) 跳 don't-care。
  - variants_xs.sv: CtrlBlock_xs（golden 同名扁平端口）-> 例化 xs_CtrlBlock_core u_core。
  - Makefile      : 仿 DataPath，子模块全 golden 黑盒（-y GOLDEN_RTL 自动解析叶子）。

不抽逻辑、不套壳；仅生成验证脚手架。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"
BK = XSSV / "rtl/backend"
UT = XSSV / "verif/ut/CtrlBlock"
GSV = (GOLDEN / "CtrlBlock.sv").read_text()
HDR = "// 自动生成：scripts/gen_ctrlblock_ut.py —— 勿手改\n"

# CtrlBlock 16 个子模块类型（UT 两侧共用 golden 黑盒；DelayN_15/17 等带后缀）。
SUB_TYPES = [
    "DecodeStage", "DelayN_15", "DelayN_17", "FusionDecoder", "GPAMem",
    "MemCtrl", "NewDispatch", "PipeGroupConnect", "PipelineConnectPipe",
    "RedirectGenerator", "Rename", "RenameTableWrapper", "Rob",
    "SnapshotGenerator_14", "SyncDataModuleTemplate_BackendPC_64entry", "Trace",
]


def top_ports():
    m = re.search(r"^module CtrlBlock\((.*?)\n\);", GSV, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1,
                        pm.group(3)))
    return res


def wdecl(w):
    return "" if w == 1 else f"[{w - 1}:0] "


def gen_variants(ports):
    """CtrlBlock_xs：golden 同名扁平端口 wrapper，例化可读核 xs_CtrlBlock_core。"""
    L = [HDR, "module CtrlBlock_xs(", "  input  clock,", "  input  reset,"]
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"  {d}  {wdecl(w)}{n}{comma}")
    L.append(");")
    L.append("  xs_CtrlBlock_core u_core (")
    L.append("    .clock(clock),")
    L.append("    .reset(reset),")
    for i, (d, w, n) in enumerate(pl):
        comma = "," if i < len(pl) - 1 else ""
        L.append(f"    .{n}({n}){comma}")
    L.append("  );")
    L.append("endmodule")
    (UT / "variants_xs.sv").write_text("\n".join(L) + "\n")


def gen_tb(ports):
    pl = [p for p in ports if p[2] not in ("clock", "reset")]
    ins = [p for p in pl if p[0] == "input"]
    outs = [p for p in pl if p[0] == "output"]

    L = [HDR, "`timescale 1ns/1ps", "module tb;",
         "  int unsigned NCYCLES = 200000;",
         "  bit clk = 0, rst;",
         "  int errors = 0, checks = 0;",
         "  always #5 clk = ~clk;",
         ""]

    # 输入：driven 寄存器
    for d, w, n in ins:
        L.append(f"  logic {wdecl(w)}{n};")
    # 输出：g_/i_ 两套 wire
    for d, w, n in outs:
        L.append(f"  wire {wdecl(w)}g_{n};")
        L.append(f"  wire {wdecl(w)}i_{n};")
    L.append("")

    # 例化 u_g（golden）
    def conn(prefix_out):
        items = [".clock(clk)", ".reset(rst)"]
        for d, w, n in pl:
            if d == "input":
                items.append(f".{n}({n})")
            else:
                items.append(f".{n}({prefix_out}{n})")
        return ", ".join(items)

    L.append(f"  CtrlBlock    u_g ({conn('g_')});")
    L.append(f"  CtrlBlock_xs u_i ({conn('i_')});")
    L.append("")

    # 每个输出端口首次分叉只报一次（不被 80 行截断），带分叉拍号；便于诊断对齐路数。
    L.append(f"  bit reported [0:{len(outs) - 1}];")
    L.append("  int distinct_div = 0;")
    L.append("")

    # 随机驱动：negedge clk
    L.append("  always @(negedge clk) begin")
    L.append("    if (rst) begin")
    for d, w, n in ins:
        if n.endswith("_valid") or n.endswith("_ready"):
            L.append(f"      {n} <= 1'b0;")
    L.append("    end else begin")
    for d, w, n in ins:
        if w == 1:
            L.append(f"      {n} <= $urandom_range(0,1);")
        elif w <= 32:
            L.append(f"      {n} <= {w}'($urandom);")
        elif w <= 64:
            L.append(f"      {n} <= {{$urandom(), $urandom()}};")
        else:
            chunks = (w + 31) // 32
            cat = ", ".join(["$urandom()"] * chunks)
            L.append(f"      {n} <= {{{cat}}};")
    L.append("    end")
    L.append("  end")
    L.append("")

    # 比对：negedge clk, #4 后
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4; checks++;")
    for k, (d, w, n) in enumerate(outs):
        L.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        L.append(f"      if(!reported[{k}]) begin reported[{k}]=1; distinct_div++;")
        L.append(f"        $display(\"[DIV %0t] {n} g=%h i=%h\", "
                 f"$time, g_{n}, i_{n}); end end")
    L.append("  end")
    L.append("")

    # ---- 层次探针(+PROBE 时启用)：定位重定向/快照/rename 链第一个分叉点 ----
    # golden 内部名 vs 可读核内部名(u_i.u_core.<sig>)，逐拍比对，首次分叉报一次。
    probes = [
        # (golden u_g 内部信号, 核 u_i.u_core 内部信号, 标签)
        ("u_g.s1_robFlushRedirect_valid_last_REG", "u_i.u_core.s1_robFlushValid", "s1_robFlushValid"),
        ("u_g.s2_s4_pendingRedirectValid", "u_i.u_core.s2_s4_pendingRedirectValid", "s2s4_pending"),
        ("u_g._redirectGen_io_stage2Redirect_valid", "u_i.u_core._redirectGen_io_stage2Redirect_valid", "redirGen_s2_valid"),
        ("u_g.useSnpt", "u_i.u_core.useSnpt", "useSnpt"),
        ("u_g.snptSelect", "u_i.u_core.snptSelect", "snptSelect"),
        ("u_g._rename_io_out_0_valid", "u_i.u_core._rename_io_out_0_valid", "rename_out0_valid"),
        ("u_g._rename_io_out_0_bits_pdest", "u_i.u_core._rename_io_out_0_bits_pdest", "rename_out0_pdest"),
        ("u_g._rename_io_out_0_bits_fuType", "u_i.u_core._rename_io_out_0_bits_fuType", "rename_out0_fuType"),
        ("u_g._renamePipeDispatch_io_out_0_valid", "u_i.u_core._renamePipeDispatch_io_out_0_valid", "rpd_out0_valid"),
        ("u_g._renamePipeDispatch_io_out_0_bits_pdest", "u_i.u_core._renamePipeDispatch_io_out_0_bits_pdest", "rpd_out0_pdest"),
        ("u_g._rename_io_in_0_ready", "u_i.u_core._rename_io_in_0_ready", "rename_in0_ready"),
        ("u_g.decodeBufValid_0", "u_i.u_core.decodeBufValid[0]", "decodeBufValid0"),
        ("u_g.x15", "u_i.u_core.decodeRedirect", "x15_vs_decodeRedirect"),
        ("u_g.io_redirect_valid_0", "u_i.u_core.s1_s3_redirect_valid", "io_redir_v0_vs_s1s3"),
        ("u_g.decodeBufAcceptNum", "u_i.u_core.decodeBufAcceptNum", "bufAcceptNum"),
        ("u_g.decodeFromFrontendAcceptNum", "u_i.u_core.decodeFromFrontendAcceptNum", "feAcceptNum"),
        ("u_g._decode_io_in_0_ready", "u_i.u_core._decode_io_in_ready[0]", "decode_in0_ready"),
        ("u_g._decodePipeRenameModule_io_in_ready", "u_i.u_core._decodePipeRenameModule_io_in_ready", "dprm0_in_ready"),
        ("u_g._decode_io_out_0_valid", "u_i.u_core._decode_io_out_0_valid", "decode_out0_valid"),
        ("u_g._decode_io_fusion_0_T", "u_i.u_core.decodeFusionAdv[0]", "fusionAdv0"),
        ("u_g._decode_io_in_0_bits_T_foldpc", "u_i.u_core.decodeInFoldpc[0]", "decodeInFoldpc0"),
        ("u_g.decodeBufBits_0_instr", "u_i.u_core.decodeBufBits[0].instr", "decodeBufBits0_instr"),
        ("u_g._rename_io_out_0_bits_fuType", "u_i.u_core._rename_io_out_0_bits_fuType", "rename_out0_fuType2"),
        ("u_g._renamePipeDispatch_io_in_0_ready", "u_i.u_core._renamePipeDispatch_io_in_0_ready", "rpd_in0_ready"),
        ("u_g.decodeBufBits_1_instr", "u_i.u_core.decodeBufBits[1].instr", "decodeBufBits1_instr"),
        ("u_g.decodeBufBits_2_instr", "u_i.u_core.decodeBufBits[2].instr", "decodeBufBits2_instr"),
        ("u_g.decodeBufBits_3_instr", "u_i.u_core.decodeBufBits[3].instr", "decodeBufBits3_instr"),
        ("u_g.decodeBufBits_4_instr", "u_i.u_core.decodeBufBits[4].instr", "decodeBufBits4_instr"),
        ("u_g.decodeBufBits_5_instr", "u_i.u_core.decodeBufBits[5].instr", "decodeBufBits5_instr"),
        ("u_g.decodeBufValid_1", "u_i.u_core.decodeBufValid[1]", "decodeBufValid1"),
        ("u_g.decodeBufValid_5", "u_i.u_core.decodeBufValid[5]", "decodeBufValid5"),
        ("u_g._decode_io_in_5_ready", "u_i.u_core._decode_io_in_ready[5]", "decode_in5_ready"),
        ("u_g.decode.complexNum", "u_i.u_core.decode.complexNum", "decode_complexNum"),
        ("u_g.decode.readyCounter", "u_i.u_core.decode.readyCounter", "decode_readyCounter"),
        ("u_g.decode.isComplexVec_0", "u_i.u_core.decode.isComplexVec_0", "isComplexVec0"),
        ("u_g.decode.io_in_0_valid", "u_i.u_core.decode.io_in_0_valid", "decode_io_in0_valid"),
        ("u_g.decode.io_in_5_valid", "u_i.u_core.decode.io_in_5_valid", "decode_io_in5_valid"),
        ("u_g.decode.io_in_0_bits_instr", "u_i.u_core.decode.io_in_0_bits_instr", "decode_io_in0_instr"),
        ("u_g.decode.io_in_5_bits_instr", "u_i.u_core.decode.io_in_5_bits_instr", "decode_io_in5_instr"),
        ("u_g.decode.io_out_0_ready", "u_i.u_core.decode.io_out_0_ready", "decode_io_out0_ready"),
        ("u_g.redirectGen_io_oldestExuRedirect_valid_last_REG", "u_i.u_core.oldestExuRedirectValid", "oldestExuRedirValid"),
        ("u_g.loadReplay_valid_last_REG", "u_i.u_core.loadReplayValidR", "loadReplayValid"),
        ("u_g.redirectGen_io_instrAddrTransType_REG_bare", "u_i.u_core.instrTransBareR", "instrTransBare"),
        ("u_g.redirectGen_io_oldestExuRedirectIsCSR_r", "u_i.u_core.oldestExuRedirectIsCSR", "oldestExuIsCSR"),
        ("u_g.exuRedirects_0_valid", "u_i.u_core.exuRedirValid[0]", "exuRedirV0"),
        ("u_g.exuRedirects_1_valid", "u_i.u_core.exuRedirValid[1]", "exuRedirV1"),
        ("u_g.exuRedirects_2_valid", "u_i.u_core.exuRedirValid[2]", "exuRedirV2"),
        ("u_g.exuRedirects_3_valid", "u_i.u_core.exuRedirValid[3]", "exuRedirV3"),
        ("u_g._oldestExuRedirect_T_636", "u_i.u_core.exuOldestValid", "exuOldestValid_comb"),
        ("u_g.s2_s4_redirect_next_bits_r_robIdx_value", "u_i.u_core.s2_s4_redirect_robValue", "s2s4_robval"),
        ("u_g.s2_s4_redirect_next_valid_last_REG", "u_i.u_core.s2_s4_redirect_valid", "s2s4_validchk"),
        ("u_g._redirectGen_io_stage2Redirect_bits_robIdx_value", "u_i.u_core._redirectGen_io_stage2Redirect_bits_robIdx_value", "redirGen_s2_robval"),
    ]
    L.append("`ifdef PROBE")
    L.append(f"  bit prep [0:{len(probes) - 1}];")
    L.append("  always @(negedge clk) if (!rst) begin")
    L.append("    #4;")
    for k, (gp, ip, tag) in enumerate(probes):
        L.append(f"    if (!$isunknown({gp}) && {gp} !== {ip} && !prep[{k}]) begin "
                 f"prep[{k}]=1; $display(\"[PROBE %0t] {tag} g=%h i=%h\", $time, {gp}, {ip}); end")
    L.append("  end")
    L.append("`endif")
    L.append("")
    L.append("`ifdef DUMP")
    L.append("  always @(negedge clk) if (!rst) begin #4;")
    L.append("    if (u_g._oldestExuRedirect_T_636 !== u_i.u_core.exuOldestValid) ")
    L.append("      $display(\"[EDUMP %0t] T636 g=%b coreOV i=%b | gV=%b%b%b%b iV=%b%b%b%b | iOH=%b | grob0=%h%h grob1=%h%h grob2=%h%h grob3=%h%h\", $time, u_g._oldestExuRedirect_T_636, u_i.u_core.exuOldestValid, u_g.exuRedirects_3_valid,u_g.exuRedirects_2_valid,u_g.exuRedirects_1_valid,u_g.exuRedirects_0_valid, u_i.u_core.exuRedirValid[3],u_i.u_core.exuRedirValid[2],u_i.u_core.exuRedirValid[1],u_i.u_core.exuRedirValid[0], u_i.u_core.exuOldestOH, u_g.io_fromWB_wbData_1_bits_redirect_bits_robIdx_flag,u_g.io_fromWB_wbData_1_bits_redirect_bits_robIdx_value, u_g.io_fromWB_wbData_3_bits_redirect_bits_robIdx_flag,u_g.io_fromWB_wbData_3_bits_redirect_bits_robIdx_value, u_g.io_fromWB_wbData_5_bits_redirect_bits_robIdx_flag,u_g.io_fromWB_wbData_5_bits_redirect_bits_robIdx_value, u_g.io_fromWB_wbData_7_bits_redirect_bits_robIdx_flag,u_g.io_fromWB_wbData_7_bits_redirect_bits_robIdx_value);")
    L.append("  end")
    L.append("`endif")
    L.append("")

    # 收尾
    L.append("  initial begin")
    L.append("    if (!$value$plusargs(\"NCYCLES=%d\", NCYCLES)) NCYCLES = 200000;")
    L.append("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
    L.append("    repeat (NCYCLES) @(posedge clk);")
    L.append("    $display(\"distinct_diverging_ports=%0d / %0d\", distinct_div, "
             f"{len(outs)});")
    L.append("    $display(\"checks=%0d errors=%0d\", checks, errors);")
    L.append("    if (errors == 0 && checks > 1000) $display(\"TEST PASSED\"); "
             "else $display(\"TEST FAILED\");")
    L.append("    $finish;")
    L.append("  end")
    L.append("endmodule")
    (UT / "tb.sv").write_text("\n".join(L) + "\n")
    return len(ins), len(outs)


def gen_makefile():
    subs = " \\\n           ".join(f"$(GOLDEN_RTL)/{t}.sv" for t in SUB_TYPES)
    ref_deps = " ".join(f"{t}.sv" for t in SUB_TYPES)
    txt = f"""# 自动生成：scripts/gen_ctrlblock_ut.py —— 勿手改
MODULE = CtrlBlock

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包（核通过 `include 引入端口/glue/inst svh）。
RTL_SRCS = $(RTL_DIR)/backend/ctrlblock_pkg.sv \\
           $(RTL_DIR)/backend/CtrlBlock.sv

TB_SRCS = variants_xs.sv tb.sv

# 16 个子模块类型作 golden 黑盒；UT 双例化两侧共用同一份 golden 定义。
SUB_DEPS = {subs}

GOLDEN_SRCS = $(GOLDEN_RTL)/CtrlBlock.sv $(SUB_DEPS)

# FM：impl 侧（wrapper->可读核）与 ref 侧在相同层次黑盒化子模块。
WRAPPER_SRCS = variants_xs.sv $(SUB_DEPS)
FM_VARIANTS = CtrlBlock
FM_REF_DEPS_CtrlBlock = {ref_deps}

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest；UT 关掉并关随机化，处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/backend
# 寄存器初值复位为 0（编译开 initreg，运行期 +vcs+initreg+0 经 SIM_ARGS 注入）。
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# 子模块更深 golden 叶子用 -y 库目录按文件名自动解析（.sv 与 difftest 探针 .v）。
VCS += -y $(GOLDEN_RTL) +libext+.sv+.v
VCS += -assert disable
"""
    (UT / "Makefile").write_text(txt)


def main():
    UT.mkdir(parents=True, exist_ok=True)
    ports = top_ports()
    gen_variants(ports)
    ni, no = gen_tb(ports)
    gen_makefile()
    print(f"CtrlBlock UT generated: {ni} inputs driven, {no} outputs compared")


if __name__ == "__main__":
    main()
