#!/usr/bin/env python3
"""
Rob 的「hierarchical-tap 子集双例化」UT 生成脚本 —— 产出 verif/ut/Rob/tb_tap.sv。

方法学(见 docs/backend/Rob.md §12「golden 双例化等价的可行性结论」):
  golden Rob.sv(3234 端口, 其中 ~2040 是 diffCommits/trace/perf/debug —— 可读核
  有意不实现)。全端口双例化≈重写 golden 主体, 不做。正确等价形态 = 层次 tap 子集:

    u_g : golden Rob, 喂全平铺随机激励(891 个 input)。
    u_i : xs_Rob_core, 输入 = 「同一激励的抽象翻译」+「层次探针抽 u_g 的子模块输出」:
            _exceptionGen_io_state_*  -> eg_*
            _deqPtrGenModule_io_out_* -> deq_ptr_vec / deq_ptr_next0
            _enqPtrGenModule_io_out_* -> enq_ptr_vec
            _snapshots_snapshotGen_*  -> snap_ptr0 (按 snptSelect)
            _rab_io_* / _vtypeBuffer_io_* -> rab_*/vtype_*
          enq 派生字段直接 tap u_g 已算好的内部 wire(消除 §12 的「需复现 enq 派生」风险):
            enqNeedWriteRFSeq_i  -> enq_need_write_rf
            allow_interrupts(_i) -> enq_allow_interrupt
            io_enq_req_i_bits_fuType[16] -> enq_write_std (isStore)
            io_enq_req_i_bits_numWB / robIdx / hasException / flushPipe / 静态字段 -> enq_*/enq_info

  逐拍比对「控制输出子集」+「内部控制状态探针」(!$isunknown(golden) 跳 don't-care):
    输出: io_commits_isCommit/commitValid_* / io_flushOut_* / io_exception_* /
          io_enq_canAccept(ForDispatch) / io_enq_isEmpty / io_robDeqPtr_* /
          io_headNotReady / io_cpu_halt / io_wfi_wfiReq
    探针(两侧层次引用同名内部 reg/wire):
          state / blockCommit / lastCycleFlush / hasWFI / deqHasFlushed / intrBitSetReg

  +define+SYNTHESIS 关断 golden XSError 断言。
"""
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl/Rob.sv"
HDR = "// 自动生成: scripts/gen_rob_tap.py —— 勿手改 (hierarchical-tap 子集双例化)\n"

RENAME_WIDTH = 6
COMMIT_WIDTH = 8
NUM_EXU_WB = 27
NUM_WB = 25            # io_writebackNums 端口数 0..24
PTR_W = 8
ROB_SIZE = 160

# golden 的 io_writeback 端口实际索引(只有这些口存在)
WB_PORT_IDX = [1, 3, 5, 7, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
# needFlush 路径用到的 (writeback端口, writebackNeedFlush索引) 配对(golden _needFlushWriteBack_T_24)
NEEDFLUSH_MAP = [(7, 0), (13, 1), (14, 2), (18, 6), (19, 7),
                 (20, 8), (21, 9), (22, 10), (23, 11), (24, 12)]
# fflags 累加用到的 exu 端口(golden fflagsRes, wflags 口, 实际有 wflags/fflags 端口): 5,8..17
FFLAGS_PORTS = [5, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
# vxsat 用到的 exu 端口(golden robEntries_0_vxsat): 13,15
VXSAT_PORTS = [13, 15]
# std 写回 exu 端口(golden robEntries_0_stdWritebacked): 25,26
STD_PORTS = [25, 26]
# branch-taken(cfiUpdate.taken) exu 端口(golden itype Taken): 1,3,5
BRANCH_PORTS = [1, 3, 5]


def parse_golden_ports():
    """返回 [(dir, width_str, name)], width_str 为 '' (1bit) 或 '[H:L]'。"""
    ports = []
    started = False
    for ln in GOLDEN.read_text().splitlines():
        if ln.startswith("module Rob("):
            started = True
            continue
        if not started:
            continue
        if ln.startswith(");"):
            break
        s = ln.strip().rstrip(",")
        if not (s.startswith("input") or s.startswith("output")):
            continue
        toks = s.split()
        d = toks[0]
        if toks[1].startswith("["):
            width = toks[1]
            name = toks[2]
        else:
            width = ""
            name = toks[1]
        ports.append((d, width, name))
    return ports


def width_bits(width_str):
    if not width_str:
        return 1
    inner = width_str.strip("[]")
    hi, lo = inner.split(":")
    return int(hi) - int(lo) + 1


# ---------------------------------------------------------------------------
# 输入激励分组: 给 golden 的 891 个 input 一个合理的随机/常量驱动策略。
# 关键控制 input(redirect/csr/wfi/snpt) 单独点名; enq_req_* / exuWriteback_* /
# writeback_* / writebackNums_* / writebackNeedFlush_* 批量随机; 其余 debug/常量
# 输入给 0 或恒定(对 ROB 控制核无影响, 它们只喂 debug/perf/difftest 路径)。
# ---------------------------------------------------------------------------

# 这些 input 由专门 stim 驱动(点名), 不进通用随机/置零池。
NAMED_DRIVEN = {"clock", "reset"}


def build_tb():
    ports = parse_golden_ports()
    in_ports = [p for p in ports if p[0] == "input"]
    out_ports = [p for p in ports if p[0] == "output"]
    out_names = {p[2] for p in out_ports}

    L = [HDR, "`timescale 1ns/1ps",
         "import rob_pkg::*;",
         "module tb;",
         "  int NCYCLES = 200000;  // 可经 +NCYCLES=<n> 覆盖(快速迭代)",
         "  bit clk = 0; logic rst;",
         "  int errors = 0, checks = 0;",
         "  int warmup = 40;   // 复位+流水填充, 比对从该拍后开始",
         "  always #5 clk = ~clk;",
         "  logic clock, reset; assign clock = clk; assign reset = rst;",
         ""]

    # ---- 为 golden 的每个 input 声明一个 tb reg(named/批量), output 声明 wire ----
    L.append("  // ---- golden 输入驱动寄存器 ----")
    for d, w, n in in_ports:
        if n in ("clock", "reset"):
            continue
        L.append(f"  logic {w+' ' if w else ''}{n};")
    L.append("")
    L.append("  // ---- golden 输出线(只 hang, 比对用层次引用 u_g.<port>) ----")
    # outputs 不需要显式 wire(实例化时悬空即可)

    # ---- 实例化 u_g(golden) ----
    L.append("")
    L.append("  // ===================================================================")
    L.append("  // u_g: golden Rob —— 全平铺激励")
    L.append("  // ===================================================================")
    L.append("  Rob u_g (")
    conns = []
    for d, w, n in ports:
        if n == "clock":
            conns.append("    .clock (clock)")
        elif n == "reset":
            conns.append("    .reset (reset)")
        elif d == "input":
            conns.append(f"    .{n} ({n})")
        else:
            conns.append(f"    .{n} ()")  # 输出悬空
    L.append(",\n".join(conns))
    L.append("  );")
    L.append("")

    # ---- u_i: xs_Rob_core, 输入全部 tap 自 u_g ----
    L += build_core_inst()

    # ---- 激励 ----
    L += build_stim(in_ports, out_names)

    # ---- 比对 ----
    L += build_compare(out_names)

    # ---- epilog ----
    L += [
        "  initial begin",
        "    void'($value$plusargs(\"NCYCLES=%d\", NCYCLES));",
        "    rst = 1; repeat (8) @(posedge clk); rst = 0;",
        "    repeat (NCYCLES) @(posedge clk);",
        '    $display("checks=%0d errors=%0d", checks, errors);',
        '    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");',
        "    $finish;",
        "  end",
        "endmodule"]
    return "\n".join(L)


def build_core_inst():
    """u_i 的输入信号声明 + 从 u_g tap 的赋值 + 例化。"""
    L = ["  // ===================================================================",
         "  // u_i: xs_Rob_core —— 输入 = 同激励翻译 + u_g 层次探针",
         "  // ===================================================================",
         "  // ---- 黑盒子模块输出探针(从 u_g 内部 wire 取) ----",
         "  logic                    eg_valid, eg_robidx_flag;",
         "  logic [PTR_W-1:0]        eg_robidx_value;",
         "  logic eg_is_exception, eg_flush_pipe, eg_replay_inst, eg_is_vls, eg_is_enq_excp, eg_is_vset;",
         "  rob_ptr_t deq_ptr_vec [COMMIT_WIDTH]; rob_ptr_t deq_ptr_next0;",
         "  rob_ptr_t enq_ptr_vec [RENAME_WIDTH]; rob_ptr_t snap_ptr0;",
         "  logic rab_can_enq, rab_status_commit_end, rab_status_walk_end, vtype_status_walk_end;",
         "",
         "  // exceptionGen 状态探针 -> eg_*",
         "  assign eg_valid        = u_g._exceptionGen_io_state_valid;",
         "  assign eg_robidx_flag  = u_g._exceptionGen_io_state_bits_robIdx_flag;",
         "  assign eg_robidx_value = u_g._exceptionGen_io_state_bits_robIdx_value;",
         "  // eg_is_exception = (|exceptionVec[23:0]) | singleStep | (trigger==4'h1)  (Rob.scala 577)",
         "  assign eg_is_exception = (|{",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_23, u_g._exceptionGen_io_state_bits_exceptionVec_22,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_21, u_g._exceptionGen_io_state_bits_exceptionVec_20,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_19, u_g._exceptionGen_io_state_bits_exceptionVec_18,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_17, u_g._exceptionGen_io_state_bits_exceptionVec_16,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_15, u_g._exceptionGen_io_state_bits_exceptionVec_14,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_13, u_g._exceptionGen_io_state_bits_exceptionVec_12,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_11, u_g._exceptionGen_io_state_bits_exceptionVec_10,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_9,  u_g._exceptionGen_io_state_bits_exceptionVec_8,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_7,  u_g._exceptionGen_io_state_bits_exceptionVec_6,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_5,  u_g._exceptionGen_io_state_bits_exceptionVec_4,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_3,  u_g._exceptionGen_io_state_bits_exceptionVec_2,",
         "      u_g._exceptionGen_io_state_bits_exceptionVec_1,  u_g._exceptionGen_io_state_bits_exceptionVec_0})",
         "    | u_g._exceptionGen_io_state_bits_singleStep | (u_g._exceptionGen_io_state_bits_trigger == 4'h1);",
         "  assign eg_flush_pipe   = u_g._exceptionGen_io_state_bits_flushPipe;",
         "  assign eg_replay_inst  = u_g._exceptionGen_io_state_bits_replayInst;",
         "  assign eg_is_vls       = u_g._exceptionGen_io_state_bits_isVecLoad; // 占位, vls 由 entry 决定",
         "  assign eg_is_enq_excp  = u_g._exceptionGen_io_state_bits_isEnqExcp;",
         "  assign eg_is_vset      = u_g._exceptionGen_io_state_bits_isVset;",
         "",
         "  // deqPtr / enqPtr / next / snap 探针",
         "  always_comb begin"]
    # deqPtr: slot0 flag = _deqPtrGenModule_io_out_0_flag; slot1..7 flag 经 io_commits_robIdx_N_flag 输出口暴露; value 全在内部 wire。
    L.append("    deq_ptr_vec[0] = '{flag: u_g._deqPtrGenModule_io_out_0_flag, value: u_g._deqPtrGenModule_io_out_0_value};")
    for i in range(1, COMMIT_WIDTH):
        L.append(f"    deq_ptr_vec[{i}] = '{{flag: u_g.io_commits_robIdx_{i}_flag, value: u_g._deqPtrGenModule_io_out_{i}_value}};")
    L.append("    deq_ptr_next0 = '{flag: u_g._deqPtrGenModule_io_next_out_0_flag, value: u_g._deqPtrGenModule_io_next_out_0_value};")
    # enqPtr: slot0 flag = _enqPtrGenModule_io_out_0_flag; slot1..5 golden 只用其 value(分配只读 value),flag 取 slot0(同绕回区)。
    L.append("    enq_ptr_vec[0] = '{flag: u_g._enqPtrGenModule_io_out_0_flag, value: u_g._enqPtrGenModule_io_out_0_value};")
    for i in range(1, RENAME_WIDTH):
        L.append(f"    enq_ptr_vec[{i}] = '{{flag: u_g._enqPtrGenModule_io_out_0_flag, value: u_g._enqPtrGenModule_io_out_{i}_value}};")
    # snap_ptr0 = 按 snptSelect 选中的快照(golden _GEN_2634[snptSelect])
    L.append("    unique case (io_snpt_snptSelect)")
    for i in range(4):
        L.append(f"      2'd{i}: snap_ptr0 = '{{flag: u_g._snapshots_snapshotGen_io_snapshots_{i}_0_flag, value: u_g._snapshots_snapshotGen_io_snapshots_{i}_0_value}};")
    L.append("      default: snap_ptr0 = '0;")
    L.append("    endcase")
    L.append("  end")
    L.append("  assign rab_can_enq           = u_g._rab_io_canEnq;")
    L.append("  assign rab_status_commit_end = u_g._rab_io_status_commitEnd;")
    L.append("  assign rab_status_walk_end   = u_g._rab_io_status_walkEnd;")
    L.append("  assign vtype_status_walk_end = u_g._vtypeBuffer_io_status_walkEnd;")
    L.append("")

    # ---- enq 抽象翻译(直接 tap u_g 已算好的派生 wire / req 端口) ----
    L += build_enq_tap()
    # ---- writeback 翻译 ----
    L += build_wb_tap()
    # ---- csr/wfi/misc(同 tb reg) ----
    L += [
        "  // ---- redirect / csr / wfi / misc ----",
        "  // 这些核输入与 golden input 同名(io_redirect_*/io_csr_*/io_wfi_*/io_snpt_useSnpt/",
        "  // io_fromVecExcpMod_busy/io_trace_blockCommit): 由顶部 golden 驱动 reg 直接经 .* 绑定,",
        "  // 不再重复声明/赋值(同一根网络, 既喂 u_g 也喂 u_i, 保证同激励)。",
        "  // io_misPredWb 是核独有端口(golden 内部聚合), 单独构造:",
        "  logic io_misPredWb;",
        "  // misPredWb: golden redirectWBs 聚合 = OR(io_writeback_{1,3,5,7} cfiUpdate.isMisPred & redirect.valid & valid)",
        "  assign io_misPredWb =",
        "      (u_g.io_writeback_1_bits_redirect_bits_cfiUpdate_isMisPred & u_g.io_writeback_1_bits_redirect_valid & u_g.io_writeback_1_valid)",
        "    | (u_g.io_writeback_3_bits_redirect_bits_cfiUpdate_isMisPred & u_g.io_writeback_3_bits_redirect_valid & u_g.io_writeback_3_valid)",
        "    | (u_g.io_writeback_5_bits_redirect_bits_cfiUpdate_isMisPred & u_g.io_writeback_5_bits_redirect_valid & u_g.io_writeback_5_valid)",
        "    | (u_g.io_writeback_7_bits_redirect_bits_cfiUpdate_isMisPred & u_g.io_writeback_7_bits_redirect_valid & u_g.io_writeback_7_valid);",
        "",
        "  // ---- u_i 输出 ----",
        "  rob_state_e o_state;",
        "  logic o_commits_isCommit, o_commits_isWalk;",
        "  logic [COMMIT_WIDTH-1:0] o_commits_commitValid, o_commits_walkValid;",
        "  rob_commit_entry_t o_commit_info [COMMIT_WIDTH]; rob_ptr_t o_commits_robIdx [COMMIT_WIDTH];",
        "  logic [COMMIT_WIDTH-1:0] o_deq_commit_v, o_deq_commit_w, o_hasCommitted;",
        "  logic o_intrBitSetReg, o_hasNoSpecExec, o_allowOnlyOneCommit, o_blockCommit, o_allCommitted;",
        "  logic o_allowEnqueue, o_hasBlockBackward; logic [RENAME_WIDTH-1:0] o_enq_for_ptr;",
        "  logic o_eg_flush; logic [UOP_CNT_W:0] o_rab_commitSize, o_rab_walkSize; logic o_rab_walkEnd;",
        "  logic o_flushOut_valid, o_flushOut_robIdx_flag; logic [PTR_W-1:0] o_flushOut_robIdx_value;",
        "  logic o_flushOut_level, o_flushOut_isRVC; logic [FTQ_PTR_W-1:0] o_flushOut_ftqIdx_value;",
        "  logic o_flushOut_ftqIdx_flag; logic [FTQ_OFFSET_W-1:0] o_flushOut_ftqOffset;",
        "  logic o_exception_valid, o_intrEnable;",
        "  logic o_enq_canAccept, o_enq_canAcceptForDispatch, o_robFull, o_headNotReady;",
        "  logic o_cpu_halt, o_wfiReq; logic [PTR_W:0] o_numValidEntries;",
        "",
        "  xs_Rob_core u_i (.*);",
        ""]
    return L


def build_enq_tap():
    L = ["  // ---- enq 抽象翻译: 直接 tap u_g 派生 wire/req 端口 ----",
         "  logic [RENAME_WIDTH-1:0] enq_valid, enq_first_uop, enq_need_write_rf, enq_write_std;",
         "  logic [RENAME_WIDTH-1:0] enq_block_backward, enq_wait_forward, enq_is_wfi;",
         "  logic [RENAME_WIDTH-1:0] enq_has_exception, enq_trigger_dmode, enq_allow_interrupt;",
         "  logic [UOP_CNT_W-1:0] enq_num_wb [RENAME_WIDTH];",
         "  logic [PTR_W-1:0] enq_robidx_value [RENAME_WIDTH];",
         "  rob_entry_t enq_info [RENAME_WIDTH];",
         "  always_comb begin"]
    ai = {0: "u_g.allow_interrupts", 1: "u_g.allow_interrupts_1", 2: "u_g.allow_interrupts_2",
          3: "u_g.allow_interrupts_3", 4: "u_g.allow_interrupts_4", 5: "u_g.allow_interrupts_5"}
    for i in range(RENAME_WIDTH):
        g = f"u_g.io_enq_req_{i}"
        L += [
            f"    enq_valid[{i}]         = {g}_valid;",
            f"    enq_first_uop[{i}]     = {g}_bits_firstUop;",
            f"    enq_need_write_rf[{i}] = u_g.enqNeedWriteRFSeq_{i};",
            f"    enq_write_std[{i}]     = {g}_bits_fuType[16];",
            f"    enq_block_backward[{i}]= {g}_bits_blockBackward;",
            f"    enq_wait_forward[{i}]  = {g}_bits_waitForward;",
            f"    enq_is_wfi[{i}]        = ({g}_bits_fuType == 35'h2) & ({g}_bits_fuOpType == 9'h22);",
            f"    enq_has_exception[{i}] = {g}_bits_hasException;",
            f"    enq_trigger_dmode[{i}] = {g}_bits_trigger == 4'h1;",
            f"    enq_allow_interrupt[{i}]= {ai[i]};",
            f"    enq_num_wb[{i}]        = {g}_bits_numWB;",
            f"    enq_robidx_value[{i}]  = {g}_bits_robIdx_value;",
            f"    enq_info[{i}]          = '0;",
            f"    enq_info[{i}].rf_wen        = {g}_bits_rfWen;",
            f"    enq_info[{i}].fp_wen        = {g}_bits_dirtyFs;",
            f"    enq_info[{i}].wflags        = {g}_bits_wfflags;",
            f"    enq_info[{i}].dirty_vs      = {g}_bits_dirtyVs;",
            f"    enq_info[{i}].commit_type   = {g}_bits_commitType;",
            f"    enq_info[{i}].is_rvc        = {g}_bits_preDecodeInfo_isRVC;",
            f"    enq_info[{i}].is_vset       = {g}_bits_isVset;",
            f"    enq_info[{i}].instr_size    = {g}_bits_instrSize;",
            f"    enq_info[{i}].ftq_idx_value = {g}_bits_ftqPtr_value;",
            f"    enq_info[{i}].ftq_idx_flag  = {g}_bits_ftqPtr_flag;",
            f"    enq_info[{i}].ftq_offset    = {g}_bits_ftqOffset;",
            f"    enq_info[{i}].itype         = {g}_bits_traceBlockInPipe_itype;",
            f"    enq_info[{i}].iretire       = {g}_bits_traceBlockInPipe_iretire;",
            f"    enq_info[{i}].ilastsize     = {g}_bits_traceBlockInPipe_ilastsize;",
            f"    enq_info[{i}].need_flush    = {g}_bits_hasException | {g}_bits_flushPipe;",
            f"    enq_info[{i}].vls           = {g}_bits_vlsInstr;",
        ]
    L.append("  end")
    L.append("")
    return L


def build_wb_tap():
    L = ["  // ---- writeback 翻译: exuWriteback(uopNum 递减 / std / fflags / vxsat / branch) ----",
         "  logic [NUM_EXU_WB-1:0] wb_valid; logic [PTR_W-1:0] wb_robidx [NUM_EXU_WB];",
         "  logic [4:0] wb_num [NUM_EXU_WB]; logic [NUM_EXU_WB-1:0] wb_is_std;",
         "  logic [NUM_EXU_WB-1:0] wb_fflags_valid; logic [4:0] wb_fflags [NUM_EXU_WB];",
         "  logic [NUM_EXU_WB-1:0] wb_vxsat_valid, wb_vxsat, wb_branch_taken;",
         "  logic [NUM_WB-1:0] excp_wb_valid; logic [PTR_W-1:0] excp_wb_robidx [NUM_WB];",
         "  logic [NUM_WB-1:0] excp_wb_need_flush;",
         "  always_comb begin"]
    for p in range(NUM_EXU_WB):
        g = f"u_g.io_exuWriteback_{p}"
        L.append(f"    wb_valid[{p}]  = {g}_valid;")
        L.append(f"    wb_robidx[{p}] = {g}_bits_robIdx_value;")
        # uopNum: io_writebackNums 仅 0..24
        if p < NUM_WB:
            L.append(f"    wb_num[{p}]    = u_g.io_writebackNums_{p}_bits;")
        else:
            L.append(f"    wb_num[{p}]    = 5'h0;")
        std_val = "1'b1" if p in STD_PORTS else "1'b0"
        L.append(f"    wb_is_std[{p}] = {std_val};")
        # fflags
        if p in FFLAGS_PORTS:
            L.append(f"    wb_fflags_valid[{p}] = {g}_bits_wflags;")
            L.append(f"    wb_fflags[{p}]       = {g}_bits_fflags;")
        else:
            L.append(f"    wb_fflags_valid[{p}] = 1'b0;")
            L.append(f"    wb_fflags[{p}]       = 5'h0;")
        # vxsat
        if p in VXSAT_PORTS:
            L.append(f"    wb_vxsat_valid[{p}] = {g}_bits_vxsat;")
            L.append(f"    wb_vxsat[{p}]       = {g}_bits_vxsat;")
        else:
            L.append(f"    wb_vxsat_valid[{p}] = 1'b0;")
            L.append(f"    wb_vxsat[{p}]       = 1'b0;")
        # branch taken
        if p in BRANCH_PORTS:
            L.append(f"    wb_branch_taken[{p}] = {g}_bits_redirect_bits_cfiUpdate_taken;")
        else:
            L.append(f"    wb_branch_taken[{p}] = 1'b0;")
    # excp_wb: golden needFlush 路径用 io_writeback_{port} + io_writebackNeedFlush_{idx}
    L.append("    // excp_wb: 默认全 0, 仅 golden needFlush 路径映射的端口有效")
    L.append("    for (int k=0;k<NUM_WB;k++) begin excp_wb_valid[k]=1'b0; excp_wb_robidx[k]=8'h0; excp_wb_need_flush[k]=1'b0; end")
    for (wbp, nf) in NEEDFLUSH_MAP:
        L.append(f"    excp_wb_valid[{nf}]      = u_g.io_writeback_{wbp}_valid;")
        L.append(f"    excp_wb_robidx[{nf}]     = u_g.io_writeback_{wbp}_bits_robIdx_value;")
        L.append(f"    excp_wb_need_flush[{nf}] = u_g.io_writebackNeedFlush_{nf};")
    L.append("  end")
    L.append("")
    return L


def build_stim(in_ports, out_names):
    """随机驱动 golden 的 input 端口。点名关键控制口; enq/wb 批量; 其余置 0。"""
    named = {
        "io_redirect_valid", "io_redirect_bits_robIdx_flag", "io_redirect_bits_robIdx_value",
        "io_redirect_bits_level", "io_csr_intrBitSet", "io_csr_wfiEvent",
        "io_csr_criticalErrorState", "io_snpt_useSnpt", "io_snpt_snptSelect",
        "io_wfi_enable", "io_wfi_safeFromMem", "io_wfi_safeFromFrontend",
        "io_fromVecExcpMod_busy", "io_trace_blockCommit",
    }
    in_names = {p[2] for p in in_ports}
    # enq / wb 端口名集合(批量随机)
    enq_re = lambda n: n.startswith("io_enq_req_")
    exuwb_re = lambda n: n.startswith("io_exuWriteback_")
    wbnums_re = lambda n: n.startswith("io_writebackNums_")
    wbnf_re = lambda n: n.startswith("io_writebackNeedFlush_")
    wb_re = lambda n: n.startswith("io_writeback_")

    # 其余 input(非 named/enq/wb) -> 复位段置 0, 不再驱动(它们喂 debug/perf, 对控制核无影响)
    L = ["  // ===================================================================",
         "  // 随机激励(negedge 更新, 喂 golden 的 input)",
         "  // ===================================================================",
         "  // 入队 robIdx 用 enqPtr 跟随(tap u_g enqPtr 当前值)",
         "  function automatic logic [4:0] rnum(); return 5'($urandom_range(0,2)); endfunction",
         "  always @(negedge clk) begin",
         "    if (rst) begin"]
    # 复位: 所有非 clock/reset input <= 0
    for d, w, n in in_ports:
        if n in ("clock", "reset"):
            continue
        L.append(f"      {n} <= '0;")
    L.append("      io_wfi_enable <= 1'b1; io_wfi_safeFromMem <= 1'b1; io_wfi_safeFromFrontend <= 1'b1;")
    L.append("    end else begin")
    # named control
    L += [
        "      io_redirect_valid <= ($urandom_range(0,99) < 2);",
        "      io_redirect_bits_robIdx_flag <= u_g._deqPtrGenModule_io_out_0_flag;",
        "      io_redirect_bits_robIdx_value <= u_g._deqPtrGenModule_io_out_0_value + 8'($urandom_range(0,16));",
        "      io_redirect_bits_level <= $urandom_range(0,1);",
        "      io_csr_intrBitSet <= ($urandom_range(0,99)<3);",
        "      io_csr_wfiEvent <= ($urandom_range(0,99)<3);",
        "      io_csr_criticalErrorState <= 1'b0;",
        "      io_snpt_useSnpt <= ($urandom_range(0,99)<30);",
        "      io_snpt_snptSelect <= $urandom_range(0,3);",
        "      io_wfi_enable <= 1'b1; io_wfi_safeFromMem <= 1'b1; io_wfi_safeFromFrontend <= 1'b1;",
        "      io_fromVecExcpMod_busy <= ($urandom_range(0,99)<2);",
        "      io_trace_blockCommit <= ($urandom_range(0,99)<2);",
    ]
    # enq req per port: drive valid/firstUop/needWriteRf-fields/numWB/robIdx + minimal
    L.append("      // ---- enqueue: 6 口随机, robIdx 跟随 enqPtrVec ----")
    L.append("      for (int i=0;i<6;i++) begin")
    # use array-style? ports are flattened. Generate per-port block.
    L.append("      end")
    for i in range(RENAME_WIDTH):
        g = f"io_enq_req_{i}"
        L += [
            f"      {g}_valid <= ($urandom_range(0,99)<65);",
            f"      {g}_bits_firstUop <= 1'b1;",
            f"      {g}_bits_lastUop <= 1'b1;",
            f"      {g}_bits_robIdx_flag <= u_g._enqPtrGenModule_io_out_0_flag;",
            f"      {g}_bits_robIdx_value <= u_g._enqPtrGenModule_io_out_{i}_value;",
            f"      {g}_bits_numWB <= 7'($urandom_range(1,4));",
            f"      {g}_bits_rfWen <= ($urandom_range(0,99)<55);",
            f"      {g}_bits_fpWen <= ($urandom_range(0,99)<10);",
            f"      {g}_bits_vecWen <= ($urandom_range(0,99)<10);",
            f"      {g}_bits_v0Wen <= ($urandom_range(0,99)<5);",
            f"      {g}_bits_vlWen <= ($urandom_range(0,99)<5);",
            f"      {g}_bits_dirtyFs <= ($urandom_range(0,99)<10);",
            f"      {g}_bits_dirtyVs <= ($urandom_range(0,99)<5);",
            f"      {g}_bits_wfflags <= ($urandom_range(0,99)<8);",
            f"      {g}_bits_blockBackward <= ($urandom_range(0,99)<3);",
            f"      {g}_bits_waitForward <= ($urandom_range(0,99)<3);",
            f"      {g}_bits_hasException <= ($urandom_range(0,99)<5);",
            f"      {g}_bits_flushPipe <= ($urandom_range(0,99)<3);",
            f"      {g}_bits_isVset <= ($urandom_range(0,99)<3);",
            f"      {g}_bits_vlsInstr <= ($urandom_range(0,99)<5);",
            f"      {g}_bits_commitType <= $urandom_range(0,5);",
            f"      {g}_bits_fuType <= 35'(1 << $urandom_range(0,20));",
            f"      {g}_bits_fuOpType <= $urandom_range(0,16);",
            f"      {g}_bits_trigger <= ($urandom_range(0,99)<3) ? 4'h1 : 4'h0;",
            f"      {g}_bits_preDecodeInfo_isRVC <= $urandom_range(0,1);",
            f"      {g}_bits_instrSize <= $urandom_range(1,2);",
            f"      {g}_bits_ftqPtr_flag <= $urandom_range(0,1);",
            f"      {g}_bits_ftqPtr_value <= $urandom_range(0,63);",
            f"      {g}_bits_ftqOffset <= $urandom_range(0,15);",
            f"      {g}_bits_traceBlockInPipe_itype <= $urandom_range(0,6);",
            f"      {g}_bits_traceBlockInPipe_iretire <= $urandom_range(0,2);",
            f"      {g}_bits_traceBlockInPipe_ilastsize <= $urandom_range(0,1);",
            f"      {g}_bits_singleStep <= ($urandom_range(0,99)<2);",
        ]
    # exuWriteback per port
    L.append("      // ---- exu writeback ----")
    for p in range(NUM_EXU_WB):
        g = f"io_exuWriteback_{p}"
        L += [
            f"      {g}_valid <= ($urandom_range(0,99)<35);",
            f"      {g}_bits_robIdx_value <= $urandom_range(0,{ROB_SIZE-1});",
        ]
        if p < NUM_WB:
            L.append(f"      io_writebackNums_{p}_bits <= rnum();")
        if p in FFLAGS_PORTS:
            L.append(f"      {g}_bits_wflags <= ($urandom_range(0,99)<20);")
            L.append(f"      {g}_bits_fflags <= $urandom_range(0,31);")
        if p in VXSAT_PORTS:
            L.append(f"      {g}_bits_vxsat <= ($urandom_range(0,99)<10);")
        if p in BRANCH_PORTS:
            L.append(f"      {g}_bits_redirect_bits_cfiUpdate_taken <= ($urandom_range(0,99)<20);")
            L.append(f"      {g}_bits_redirect_valid <= ($urandom_range(0,99)<10);")
    # writeback ports —— 按端口实际拥有的字段分别驱动:
    #   有 valid 的口: {1,3,5,7,13,14,18..24}; 有 robIdx 的口: {7,13,14,15,16,17,18..24}
    WB_HAS_VALID = [1, 3, 5, 7, 13, 14, 18, 19, 20, 21, 22, 23, 24]
    WB_HAS_ROBIDX = [7, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]
    L.append("      // ---- writeback(needFlush + misPred 路径) ----")
    for wbp in sorted(set(WB_HAS_VALID) | set(WB_HAS_ROBIDX)):
        if wbp in WB_HAS_VALID:
            L.append(f"      io_writeback_{wbp}_valid <= ($urandom_range(0,99)<20);")
        if wbp in WB_HAS_ROBIDX:
            L.append(f"      io_writeback_{wbp}_bits_robIdx_value <= $urandom_range(0,{ROB_SIZE-1});")
    for (wbp, nf) in NEEDFLUSH_MAP:
        L.append(f"      io_writebackNeedFlush_{nf} <= ($urandom_range(0,99)<30);")
    # misPred 路径: io_writeback_{1,3,5,7} 的 redirect/isMisPred
    L.append("      // ---- misPred 路径(io_writeback_{1,3,5,7}) ----")
    for wbp in (1, 3, 5, 7):
        L.append(f"      io_writeback_{wbp}_bits_redirect_valid <= ($urandom_range(0,99)<10);")
        L.append(f"      io_writeback_{wbp}_bits_redirect_bits_cfiUpdate_isMisPred <= ($urandom_range(0,99)<40);")
    L.append("    end")
    L.append("  end")
    L.append("")
    return L


def build_compare(out_names):
    """逐拍比对控制输出子集 + 内部状态探针。"""
    # 比较列表: (golden 层次引用, u_i 信号, 名字)
    cmp_out = [
        ("u_g.io_commits_isCommit", "o_commits_isCommit", "commits_isCommit"),
        ("u_g.io_flushOut_valid", "o_flushOut_valid", "flushOut_valid"),
        ("u_g.io_exception_valid", "o_exception_valid", "exception_valid"),
        ("u_g.io_enq_canAccept", "o_enq_canAccept", "enq_canAccept"),
        ("u_g.io_enq_canAcceptForDispatch", "o_enq_canAcceptForDispatch", "enq_canAcceptForDispatch"),
        ("u_g.io_headNotReady", "o_headNotReady", "headNotReady"),
        ("u_g.io_cpu_halt", "o_cpu_halt", "cpu_halt"),
        ("u_g.io_wfi_wfiReq", "o_wfiReq", "wfiReq"),
        ("u_g.io_robDeqPtr_flag", "o_commits_robIdx[0].flag", "robDeqPtr_flag"),
        ("u_g.io_robDeqPtr_value", "o_commits_robIdx[0].value", "robDeqPtr_value"),
        ("u_g.io_flushOut_bits_robIdx_flag", "o_flushOut_robIdx_flag", "flushOut_robIdx_flag"),
        ("u_g.io_flushOut_bits_robIdx_value", "o_flushOut_robIdx_value", "flushOut_robIdx_value"),
        ("u_g.io_flushOut_bits_level", "o_flushOut_level", "flushOut_level"),
        # io_exception_bits_isInterrupt = RegNext(intrEnable) (golden 寄存输出), 故比对 tb 寄存的 intrEnable
        ("u_g.io_exception_bits_isInterrupt", "intrEnable_q", "exception_isInterrupt"),
    ]
    cmp_probe = [
        ("u_g.state", "{1'(o_state)}", "state"),
        ("u_g.blockCommit", "o_blockCommit", "blockCommit"),
        ("u_g.lastCycleFlush", "u_i.lastCycleFlush", "lastCycleFlush"),
        ("u_g.hasWFI", "o_wfiReq", "hasWFI"),
        ("u_g.deqHasFlushed", "u_i.deqHasFlushed", "deqHasFlushed"),
        ("u_g.intrBitSetReg", "o_intrBitSetReg", "intrBitSetReg"),
        ("u_g.walkPtrTrue_value", "u_i.walkPtrTrue.value", "walkPtrTrue_value"),
        ("u_g.walkPtrTrue_flag", "u_i.walkPtrTrue.flag", "walkPtrTrue_flag"),
        ("u_g.lastWalkPtr_value", "u_i.lastWalkPtr.value", "lastWalkPtr_value"),
        ("u_g.lastWalkPtr_flag", "u_i.lastWalkPtr.flag", "lastWalkPtr_flag"),
        ("u_g.walkFinished", "u_i.walkFinished", "walkFinished"),
        ("u_g.deqHasException", "u_i.deqHasException", "deqHasException"),
        ("u_g.deqHasReplayInst", "u_i.deqHasReplayInst", "deqHasReplayInst"),
        ("u_g.intrEnable", "u_i.intrEnable", "intrEnable"),
        ("u_g.isFlushPipe", "u_i.isFlushPipe", "isFlushPipe"),
    ]

    L = ["  // ===================================================================",
         "  // 逐拍比对(posedge 后稳定): !$isunknown(golden) 跳 don't-care",
         "  // ===================================================================",
         "  int unsigned cyc = 0;",
         "  always @(posedge clk) if (!rst) cyc <= cyc + 1;",
         "  // golden io_exception_bits_isInterrupt 是 exceptionHappen 条件锁存(非每拍更新);",
         "  // tb 用同条件(u_i.exceptionHappen)锁存 impl intrEnable 对齐。",
         "  logic intrEnable_q;",
         "  always @(posedge clk) if (rst) intrEnable_q <= 1'b0;",
         "    else if (u_i.exceptionHappen) intrEnable_q <= o_intrEnable;",
         "  task automatic chk(input string nm, input logic [63:0] g, input logic [63:0] i);",
         "    if (!$isunknown(g) && (g !== i)) begin",
         "      errors++;",
         "      if (errors <= 60) $display(\"[cyc %0d] MISMATCH %s golden=%0h impl=%0h\", cyc, nm, g, i);",
         "    end",
         "  endtask",
         "  always @(negedge clk) if (!rst && cyc > warmup) begin",
         "    checks++;"]
    for g, i, nm in cmp_out:
        L.append(f"    chk(\"{nm}\", {g}, {i});")
    # commitValid_0..7
    for k in range(COMMIT_WIDTH):
        L.append(f"    chk(\"commitValid_{k}\", u_g.io_commits_commitValid_{k}, o_commits_commitValid[{k}]);")
    for g, i, nm in cmp_probe:
        L.append(f"    chk(\"{nm}\", {g}, {i});")
    L.append("  end")
    L.append("")
    return L


def main():
    ut = XSSV / "verif/ut/Rob"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "tb_tap.sv").write_text(build_tb())
    print("generated tap dual-instantiation UT ->", ut / "tb_tap.sv")


if __name__ == "__main__":
    main()
