#!/usr/bin/env python3
"""生成 NewIFU 的双例化 UT testbench（tb.sv）。

golden NewIFU（连同 golden 的 PreDecode / PredChecker / FrontendTrigger / RVCExpander / F3Predecoder）
vs 重写 NewIFU_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍逐位比较全部输出。

NewIFU 是带握手的流水线，纯随机输入走不通（ICache 响应的 vaddr 要等于 f2 的 startAddr 才算数），
所以激励是「受约束随机」，约束里引用 golden 实例的内部状态（两侧吃到的输入永远相同，重写侧一旦
跑偏输出就对不上，不影响判据）：
  * FTQ 请求：startAddr 随机（偶地址）；不预测跳时 nextStartAddr = startAddr + 2k（k=1..16），
    预测跳时目标一半就近一半全随机；ftqIdx 缓慢递增。
  * ICache 响应：多数拍 vaddr / doubleline 对上 golden 的 f2 请求（1/16 的拍故意对不上）；
    512 位数据按半字拼，半字从「jal / jalr / branch / c.j / c.jr / c.jalr / c.beqz / 普通 RVC /
    全随机」里抽，保证各种 brType、RVC/RVI 交错、跨块半条指令都大量出现；mode%4==0 为控制流
    指令密集档（几乎每块都有漏跳），mode%4==3 为「直线」档（无控制流指令、整块取满，专走
    last half 及其撤销），其余为稀疏档。
  * MMIO：pmp_mmio / pbmt 按 mode 分档（mode%4==1 为 MMIO 密集档）；InstrUncache / ITLB / PMP /
    ROB 提交的握手全随机，ROB 提交的 ftqIdx 多数拍对上 golden 的 f3 块。
  * 冲刷：后端重定向（ftqIdx 取 f3 块附近 ±2，一半 ftqOffset=0）、BPU s2/s3 覆盖、IBuffer 反压，
    密度按 mode 分档。
  * 触发器：偶尔更新，tdata2 取 f3 块起始地址附近。
不复位寄存器（各级 RegEnable 数据、f3_mmio_data、wb 级）在 +random 档两侧初值不同：arm 条件 =
f2_fire / wb_enable / MMIO 数据被写或被清 各至少发生过一次之后才开始比。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

G = "ni_u_gold."

DECLS = """
int unsigned ni_ftq = 0;
logic [49:0] ni_start;
logic [6:0]  ni_f3idx;
int unsigned ni_cfi_div = 16;   // 半字抽样的分母：16 = 控制流指令密集，256 = 稀疏
function automatic logic [15:0] ni_hw();
  int unsigned r;
  logic [15:0] x;
  r = $urandom_range(0, ni_cfi_div - 1);
  x = 16'($urandom);
  case (r)
    0:       return {x[15:7], 7'h6F};                 // jal（RVI 低半）
    1:       return {1'b0, 3'b000, x[11:7], 7'h67};   // jalr（RVI 低半）
    2:       return {x[15:7], 7'h63};                 // branch（RVI 低半）
    3:       return {3'b101, x[12:2], 2'b01};         // c.j
    4:       return {4'b1000, x[11:7], 5'b0, 2'b10};  // c.jr（rs1=1/5 时是 ret）
    5:       return {4'b1001, x[11:7], 5'b0, 2'b10};  // c.jalr / c.ebreak
    6:       return {3'b110, x[12:2], 2'b01};         // c.beqz
    7, 8, 9, 10: return {x[15:2], x[1] ? 2'b01 : (x[0] ? 2'b00 : 2'b10)};  // 普通 RVC
    default: return (ni_cfi_div > 16 && x[15]) ? {x[15:2], x[1] ? 2'b01 : (x[0] ? 2'b00 : 2'b10)} : x;
  endcase
endfunction
"""

L = []
A = L.append
# ---- FTQ 请求 ----
A("ni_cfi_div = (@mode % 4 == 0) ? 16 : (@mode % 4 == 3) ? 1000000 : 256;")
A("ni_ftq = ni_ftq + $urandom_range(0, 1);")
A("ni_start = 50'({$urandom, $urandom});")
A("if ($urandom_range(0, 31) != 0) ni_start[0] = 1'b0;")
A("@io_ftqInter_fromFtq_req_bits_startAddr = ni_start;")
A("@io_ftqInter_fromFtq_req_bits_nextlineStart = {ni_start[49:6] + 44'd1, 6'b0};")
A("if (@io_ftqInter_fromFtq_req_bits_ftqOffset_valid) begin")
A("  if ($urandom_range(0, 1)) @io_ftqInter_fromFtq_req_bits_nextStartAddr = ni_start + 50'($urandom_range(0, 4096)) - 50'd2048;")
A("end else if ($urandom_range(0, 15) != 0)")
A("  @io_ftqInter_fromFtq_req_bits_nextStartAddr = ni_start + 50'(2 * $urandom_range(1, 16));")
# 「直线」档（mode%4==3）：块里没有控制流指令、整块取满 32 字节；1/4 的块预测在位置 15 跳
# （那里其实不是控制流指令 → 第 2 拍判 notCFI 误预测），配合 IBuffer 反压走 last half 的撤销路径
A("if (@mode % 4 == 3) begin")
A("  @io_ftqInter_fromFtq_req_bits_ftqOffset_valid = ($urandom_range(0, 3) == 0);")
A("  @io_ftqInter_fromFtq_req_bits_ftqOffset_bits = 4'd15;")
A("  @io_ftqInter_fromFtq_req_bits_nextStartAddr = ni_start + 50'd32;")
A("end")
A("{@io_ftqInter_fromFtq_req_bits_ftqIdx_flag, @io_ftqInter_fromFtq_req_bits_ftqIdx_value} = 7'(ni_ftq);")
A("@io_ftqInter_fromFtq_req_valid = (@mode % 8 == 7) ? ($urandom_range(0, 3) == 0) : ($urandom_range(0, 7) != 0);")
A("@io_icacheInter_icacheReady = ($urandom_range(0, 7) != 0);")
# ---- ICache 响应 ----
A("@io_icacheInter_resp_valid = (@mode % 8 == 6) ? ($urandom_range(0, 7) == 0) : ($urandom_range(0, 3) != 0);")
A("if ($urandom_range(0, 15) != 0) begin")
A("  @io_icacheInter_resp_bits_vaddr_0 = %sf2_ftq_req_startAddr;" % G)
A("  @io_icacheInter_resp_bits_vaddr_1 = %sf2_ftq_req_nextlineStart;" % G)
A("  @io_icacheInter_resp_bits_doubleline = %sf2_doubleLine;" % G)
A("end")
A("for (int h = 0; h < 32; h++) @io_icacheInter_resp_bits_data[h*16 +: 16] = ni_hw();")
A("@io_icacheInter_resp_bits_exception_0 = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'd0;")
A("@io_icacheInter_resp_bits_exception_1 = ($urandom_range(0, 7) == 0) ? 2'($urandom) : 2'd0;")
A("@io_icacheInter_resp_bits_pmp_mmio_0 = (@mode % 4 == 1) ? 1'($urandom) : ($urandom_range(0, 31) == 0);")
A("@io_icacheInter_resp_bits_pmp_mmio_1 = ($urandom_range(0, 15) == 0) ? ~@io_icacheInter_resp_bits_pmp_mmio_0 : @io_icacheInter_resp_bits_pmp_mmio_0;")
A("@io_icacheInter_resp_bits_itlb_pbmt_0 = ($urandom_range(0, (@mode % 4 == 1) ? 3 : 31) == 0) ? 2'($urandom) : 2'd0;")
A("if ($urandom_range(0, 15) != 0) @io_icacheInter_resp_bits_itlb_pbmt_1 = @io_icacheInter_resp_bits_itlb_pbmt_0;")
# ---- IBuffer 反压 ----
A("@io_toIbuffer_ready = (@mode % 8 == 5) ? ($urandom_range(0, 3) == 0) : (@mode % 4 == 3) ? 1'($urandom) : ($urandom_range(0, 7) != 0);")
# ---- 冲刷 ----
A("ni_f3idx = {%sf3_ftq_req_ftqIdx_flag, %sf3_ftq_req_ftqIdx_value};" % (G, G))
A("@io_ftqInter_fromFtq_redirect_valid = ($urandom_range(0, (@mode % 2) ? 31 : 255) == 0);")
A("{@io_ftqInter_fromFtq_redirect_bits_ftqIdx_flag, @io_ftqInter_fromFtq_redirect_bits_ftqIdx_value} = ni_f3idx + 7'($urandom_range(0, 4)) - 7'd2;")
A("if ($urandom_range(0, 1)) @io_ftqInter_fromFtq_redirect_bits_ftqOffset = 4'd0;")
A("@io_ftqInter_fromFtq_topdown_redirect_valid = @io_ftqInter_fromFtq_redirect_valid | ($urandom_range(0, 63) == 0);")
A("@io_ftqInter_fromFtq_flushFromBpu_s2_valid = ($urandom_range(0, 15) == 0);")
A("@io_ftqInter_fromFtq_flushFromBpu_s3_valid = ($urandom_range(0, 31) == 0);")
A("{@io_ftqInter_fromFtq_flushFromBpu_s2_bits_flag, @io_ftqInter_fromFtq_flushFromBpu_s2_bits_value} = 7'(ni_ftq) + 7'($urandom_range(0, 2)) - 7'd1;")
A("{@io_ftqInter_fromFtq_flushFromBpu_s3_bits_flag, @io_ftqInter_fromFtq_flushFromBpu_s3_bits_value} = 7'(ni_ftq) + 7'($urandom_range(0, 2)) - 7'd1;")
# ---- MMIO 相关握手 ----
A("@io_uncacheInter_fromUncache_valid = ($urandom_range(0, 2) == 0);")
A("@io_uncacheInter_fromUncache_bits_data = {ni_hw(), ni_hw()};")
A("@io_uncacheInter_fromUncache_bits_corrupt = ($urandom_range(0, 15) == 0);")
A("@io_iTLBInter_resp_bits_excp_0_pf_instr = ($urandom_range(0, 23) == 0);")
A("@io_iTLBInter_resp_bits_excp_0_gpf_instr = ($urandom_range(0, 23) == 0);")
A("@io_iTLBInter_resp_bits_excp_0_af_instr = ($urandom_range(0, 23) == 0);")
A("if ($urandom_range(0, 15) != 0) @io_iTLBInter_resp_bits_pbmt_0 = %sf3_itlb_pbmt;" % G)
A("@io_pmp_resp_instr = ($urandom_range(0, 15) == 0);")
A("if ($urandom_range(0, 15) != 0) @io_pmp_resp_mmio = %sf3_pmp_mmio;" % G)
for c in range(8):
    A("@io_rob_commits_%d_valid = ($urandom_range(0, 3) == 0);" % c)
    A("if ($urandom_range(0, 3) != 0) {@io_rob_commits_%d_bits_ftqIdx_flag, @io_rob_commits_%d_bits_ftqIdx_value} = ni_f3idx;" % (c, c))
    A("if ($urandom_range(0, 3) != 0) @io_rob_commits_%d_bits_ftqOffset = 4'd0;" % c)
# ---- 触发器 ----
A("@io_frontendTrigger_tUpdate_valid = ($urandom_range(0, 63) == 0);")
A("@io_frontendTrigger_tUpdate_bits_tdata_tdata2 = {14'($urandom), %sf3_ftq_req_startAddr + 50'($urandom_range(0, 32))};" % G)
A("@io_frontendTrigger_tUpdate_bits_tdata_select = ($urandom_range(0, 7) == 0);")
A("@io_frontendTrigger_tUpdate_bits_tdata_chain = ($urandom_range(0, 3) == 0);")
A("@io_frontendTrigger_tUpdate_bits_tdata_action = 4'($urandom_range(0, 1));")
A("@io_frontendTrigger_debugMode = ($urandom_range(0, 15) == 0);")
for k in range(4):
    A("if ($urandom_range(0, 7) != 0) @io_frontendTrigger_tEnableVec_%d = 1'b1;" % k)
STIM = "\n".join(L)

MMIO_STATES = ["waitLastCmt", "sendReq", "waitResp", "sendTLB", "tlbResp", "sendPMP", "pmpResp",
               "resendReq", "waitResendResp", "waitCommit", "commited"]
COV = [
    ("f0_fire", G + "f0_fire"),
    ("f0_bpu_flush", G + "f0_fire && %sf0_flush_from_bpu_probe" % G),
    ("f1_stall", G + "f1_valid && !%sf1_fire" % G),
    ("f2_fire", G + "f2_fire"),
    ("f2_wait_icache", G + "f2_valid && !%sicacheRespAllValid" % G),
    ("f2_resp_latched", G + "f2_icache_all_resp_reg"),
    ("f2_doubleline", G + "f2_fire && %sf2_doubleLine" % G),
    ("f3_fire", G + "f3_fire"),
    ("ibuf_backpressure", "@io_toIbuffer_valid && !@io_toIbuffer_ready"),
    ("backend_redirect", "@io_ftqInter_fromFtq_redirect_valid && %sf3_valid" % G),
    ("wb_valid", G + "wb_valid"),
    ("wb_redirect", G + "wb_redirect_probe"),
    ("wb_not_flush_f3", G + "wb_redirect_probe && %sf3_wb_not_flush" % G),
    ("wb_half_flush", G + "wb_valid && %swb_false_lastHalf" % G),
    ("lastHalf", G + "f3_lastHalf_valid && %sf3_fire" % G),
    ("lastHalf_disable", G + "f3_lastHalf_disable"),
    ("chk_jal", G + "checkJalFault_probe"),
    ("chk_jalr", G + "checkJalrFault_probe"),
    ("chk_ret", G + "checkRetFault_probe"),
    ("chk_target", G + "checkTargetFault_probe"),
    ("chk_notcfi", G + "checkNotCFIFault_probe"),
    ("chk_invalid", G + "checkInvalidTaken_probe"),
    ("exc_first_line", "@io_toIbuffer_valid && @io_toIbuffer_bits_exceptionType_0 != 2'd0"),
    ("exc_cross_page", "@io_toIbuffer_valid && (@io_toIbuffer_bits_crossPageIPFFix_3 || @io_toIbuffer_bits_crossPageIPFFix_9 || @io_toIbuffer_bits_crossPageIPFFix_15)"),
    ("gpaddr_wen", "@io_toBackend_gpaddrMem_wen"),
    ("illegal", "@io_toIbuffer_valid && @io_toIbuffer_bits_illegalInstr_2"),
    ("triggered", "@io_toIbuffer_valid && @io_toIbuffer_bits_triggered_4 != 4'hF"),
    ("mmio_req", G + "f3_req_is_mmio"),
    ("mmio_nc_direct", G + "f3_req_is_mmio && %smmio_state == 4'h0 && %sf3_itlb_pbmt == 2'h1" % (G, G)),
    ("mmio_need_resend", G + "mmio_state == 4'h3 && @io_uncacheInter_fromUncache_valid && %sneedResend" % G),
    ("mmio_exception", G + "f3_req_is_mmio && %smmio_exception != 2'h0 && @io_toIbuffer_valid" % G),
    ("mmio_to_ibuffer", G + "f3_req_is_mmio && @io_toIbuffer_valid && @io_toIbuffer_ready"),
    ("mmio_redirect", G + "mmio_redirect"),
    ("mmio_pdWb", "@io_ftqInter_toFtq_pdWb_valid && !%swb_valid" % G),
    ("mmio_abort", G + "f3_req_is_mmio && %s_GEN_29" % G),
    ("mmio_need_not_flush", G + "f3_need_not_flush"),
    ("mmio_commit_read", "@io_mmioCommitRead_valid"),
    ("uncache_flush", "@io_uncacheInter_toUncache_bits_flush"),
] + [("mmio_%s" % n, G + "mmio_state == 4'd%d" % (k + 1)) for k, n in enumerate(MMIO_STATES)]

# 恒 0 的输出位：perf 计数值只有 0/1（高 5 位恒 0）
EXEMPT = ["io_perf_%d_value[%d]" % (e, b) for e in range(13) for b in range(1, 6)]

ARM = [
    G + "f2_fire",
    G + "wb_enable",
    G + "_GEN_29 || (%smmio_state == 4'h3 && @io_uncacheInter_fromUncache_valid)" % G,
]

PAIRS = [
    Pair("NewIFU", "ni_", clocked=True, stim=STIM, cov=COV, decls=DECLS, exempt=EXEMPT, arm=ARM,
         arm_delay=4, mode_period=1000, reset_period=50000, cov_min=20),
]

HEADER = """自动生成：verif/ut/NewIFU/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
NewIFU 双例化逐拍比对：golden NewIFU vs 重写 NewIFU_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
