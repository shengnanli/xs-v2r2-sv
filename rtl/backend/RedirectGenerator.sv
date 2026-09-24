// =============================================================================
// RedirectGenerator.sv —— 后端重定向仲裁与两级流水（exu 误预测 / load 回放 / Rob 冲刷）
// -----------------------------------------------------------------------------
// 设计源: XiangShan src/main/scala/xiangshan/backend/ctrlblock/RedirectGenerator.scala
// golden 对照: G1-canonical/golden-rtl/RedirectGenerator.sv（1,134 行）
// 层次位置: SimTop…backend.inner.ctrlBlock.redirectGen
//
// ★ 它是什么 ★
// 每拍最多两个重定向源：来自执行单元的最老分支误预测/异常重定向（oldestExuRedirect，
// 已在上游按 robIdx 选过最老）与访存违例的 load 回放重定向（loadReplay）。本模块：
//   s0  按 robIdx 环形序选出更老的一个（selectOldestRedirect → one-hot）；
//       被上一次冲刷「覆盖」的重定向（robIdx 在 flushAfter 之后，或 Rob 正在冲刷）作废；
//       对非 CSR 来源的 exu 重定向，按当前地址翻译模式给目标地址算取指访问/页/客体页错误；
//   s1  锁存选中的重定向（RegEnable）和预译码信息，输出 stage2Redirect（Rob 冲刷时压掉 valid）
//       与 one-hot（stage2oldestOH）；
//   s2  若 s1 是 load 回放且 flushItself(level)，向 MemCtrl 发 memPredUpdate：
//       waddr/ldpc = XORFold(load pc)、stpc = XORFold(store pc)（store pc 由上层 pcMem
//       按 s1 的 stFtqIdx/stFtqOffset 读回，golden 里那两个读地址输出端口被裁掉，只剩 data 输入）。
// flushAfter：记住最近一次冲刷（Rob 冲刷优先于本地选出的重定向）的 robIdx/level，
// 之后 3 拍内（flushAfterCounter=111 逐拍右移）robIdx 在它之后的重定向都作废。
//
// ★ golden 事实 ★
//   - loadReplay 没有 cfiUpdate 的预测器字段、没有 interrupt/fullTarget 等，被选中时
//     这些字段为 0；debugIsMemVio 对 load 恒 1、对 exu 恒 0（golden 直接寄存 one-hot[1]）。
//   - 非 CSR 的 exu 重定向：fullTarget 高 14 位取自输入 fullTarget[63:50]，低 50 位换成
//     cfiUpdate.target；IAF/IPF/IGPF 在此重算（CSR 来源沿用输入的三位）。
//   - s1 的 bits/预译码/memPred 地址寄存器、flushAfterCounter 无复位；
//     flushAfter、s1 valid、one-hot、memPredUpdate.valid 异步复位 0。
//   - memPredUpdate.wdata 恒 1 被折叠掉，io_hartId 无消费者被裁掉。
// =============================================================================

package redirectgen_pkg;
  localparam int unsigned ROB_IDX_W  = 8;
  localparam int unsigned FTQ_IDX_W  = 6;
  localparam int unsigned FTQ_OFF_W  = 4;
  localparam int unsigned VADDR_W    = 50;
  localparam int unsigned XLEN       = 64;
  localparam int unsigned PADDR_W    = 48;
  localparam int unsigned MEMPRED_PC_W = 10;

  typedef struct packed {
    logic                 flag;
    logic [ROB_IDX_W-1:0] value;
  } rob_ptr_t;

  // 预译码信息（随 exu 重定向一起锁存）
  typedef struct packed {
    logic       valid;
    logic       isRVC;
    logic [1:0] brType;
    logic       isCall;
    logic       isRet;
  } predecode_t;

  // 地址翻译模式（决定取指目标地址的错误检查）
  typedef struct packed {
    logic bare, sv39, sv39x4, sv48, sv48x4;
  } addr_trans_t;

  // BEGIN GENERATED(redirect_struct) —— 由 scripts/gen_redirectgen.py 按字段表产出
  // 分支/预测器更新信息（Chisel CfiUpdateInfo；golden 端口序）
  typedef struct packed {
    logic [49:0] pc;
    logic [3:0] ssp;
    logic [2:0] sctr;
    logic TOSW_flag;
    logic [4:0] TOSW_value;
    logic TOSR_flag;
    logic [4:0] TOSR_value;
    logic NOS_flag;
    logic [4:0] NOS_value;
    logic [49:0] topAddr;
    logic [10:0] folded_hist_17;
    logic [10:0] folded_hist_16;
    logic [6:0] folded_hist_15;
    logic [7:0] folded_hist_14;
    logic [8:0] folded_hist_13;
    logic [3:0] folded_hist_12;
    logic [7:0] folded_hist_11;
    logic [8:0] folded_hist_10;
    logic [6:0] folded_hist_9;
    logic [7:0] folded_hist_8;
    logic [6:0] folded_hist_7;
    logic [8:0] folded_hist_6;
    logic [6:0] folded_hist_5;
    logic [7:0] folded_hist_4;
    logic [7:0] folded_hist_3;
    logic [7:0] folded_hist_2;
    logic [10:0] folded_hist_1;
    logic [7:0] folded_hist_0;
    logic afhob_5_0;
    logic afhob_5_1;
    logic afhob_5_2;
    logic afhob_5_3;
    logic afhob_4_0;
    logic afhob_4_1;
    logic afhob_4_2;
    logic afhob_4_3;
    logic afhob_3_0;
    logic afhob_3_1;
    logic afhob_3_2;
    logic afhob_3_3;
    logic afhob_2_0;
    logic afhob_2_1;
    logic afhob_2_2;
    logic afhob_2_3;
    logic afhob_1_0;
    logic afhob_1_1;
    logic afhob_1_2;
    logic afhob_1_3;
    logic afhob_0_0;
    logic afhob_0_1;
    logic afhob_0_2;
    logic afhob_0_3;
    logic [2:0] lastBrNumOH;
    logic [3:0] ghr;
    logic histPtr_flag;
    logic [7:0] histPtr_value;
    logic [9:0] specCnt_0;
    logic [9:0] specCnt_1;
    logic br_hit;
    logic jr_hit;
    logic sc_hit;
    logic predTaken;
    logic [49:0] target;
    logic taken;
    logic isMisPred;
    logic [1:0] shift;
    logic addIntoHist;
    logic backendIGPF;
    logic backendIPF;
    logic backendIAF;
  } cfi_update_t;

  // 重定向（Chisel Redirect；exu 与 load 两源的字段并集，共 561 位）
  typedef struct packed {
    logic isRVC;
    rob_ptr_t robIdx;
    logic ftqIdx_flag;
    logic [5:0] ftqIdx_value;
    logic [3:0] ftqOffset;
    logic level;
    logic interrupt;
    cfi_update_t cfiUpdate;
    logic [63:0] fullTarget;
    logic satpFlush;
    logic isVlsException;
    logic stFtqIdx_flag;
    logic [5:0] stFtqIdx_value;
    logic [3:0] stFtqOffset;
    logic [63:0] debug_runahead_checkpoint_id;
    logic debugIsCtrl;
    logic debugIsMemVio;
  } redirect_t;
  // END GENERATED

  // 环形指针序：a 在 b 之后（utility.CircularQueuePtr 的 >）
  function automatic logic rob_is_after(input rob_ptr_t a, input rob_ptr_t b);
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

  // XORFold(pc[VAddrBits-1:1], MemPredPCWidth)：49 位按 10 位一段异或折叠
  function automatic logic [MEMPRED_PC_W-1:0] fold_pc(input logic [VADDR_W-1:0] pc);
    logic [VADDR_W-2:0] v;
    logic [MEMPRED_PC_W-1:0] r;
    v = pc[VADDR_W-1:1];
    r = '0;
    for (int i = 0; i < (VADDR_W - 1 + MEMPRED_PC_W - 1) / MEMPRED_PC_W; i++)
      r ^= MEMPRED_PC_W'(v >> (i * MEMPRED_PC_W));
    return r;
  endfunction
endpackage

module xs_RedirectGenerator_core
  import redirectgen_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  // s0 输入
  input  logic        exu_valid,
  input  redirect_t   exu_bits,          // 来自执行单元的最老重定向（含全部预测器字段）
  input  logic        exu_isCSR,
  input  addr_trans_t instrAddrTransType,
  input  predecode_t  exu_predecode,
  input  logic        load_valid,
  input  redirect_t   load_bits,         // load 回放重定向（只有少数字段有意义，其余调用方给 0）
  input  logic        robFlush_valid,
  input  rob_ptr_t    robFlush_robIdx,
  input  logic        robFlush_level,
  input  logic [VADDR_W-1:0] memPredPcRead_data,   // 上层 pcMem 按 s1 的 stFtq* 读回的 store pc
  // 输出
  output logic        stage2_valid,
  output redirect_t   stage2_bits,
  output predecode_t  stage2_pd,
  output logic [1:0]  stage2_oldestOH,
  output logic        memPredUpdate_valid,
  output logic [MEMPRED_PC_W-1:0] memPredUpdate_waddr,
  output logic [MEMPRED_PC_W-1:0] memPredUpdate_ldpc,
  output logic [MEMPRED_PC_W-1:0] memPredUpdate_stpc
);

  // ---------------------------------------------------------------------------
  // s0.a  exu 重定向的目标地址修饰与取指错误检查（非 CSR 来源才重算）
  // ---------------------------------------------------------------------------
  redirect_t exu_fixed;
  logic [XLEN-1:0] full_target;
  always_comb begin
    exu_fixed   = exu_bits;
    full_target = {exu_bits.fullTarget[XLEN-1:VADDR_W], exu_bits.cfiUpdate.target};
    exu_fixed.fullTarget = full_target;
    if (!exu_isCSR) begin
      exu_fixed.cfiUpdate.backendIAF  = instrAddrTransType.bare & (|full_target[XLEN-1:PADDR_W]);
      exu_fixed.cfiUpdate.backendIPF  =
          instrAddrTransType.sv39 & (full_target[XLEN-1:39] != {(XLEN-39){full_target[38]}})
        | instrAddrTransType.sv48 & (full_target[XLEN-1:48] != {(XLEN-48){full_target[47]}});
      exu_fixed.cfiUpdate.backendIGPF =
          instrAddrTransType.sv39x4 & (|full_target[XLEN-1:41])
        | instrAddrTransType.sv48x4 & (|full_target[XLEN-1:50]);
    end
  end

  // ---------------------------------------------------------------------------
  // s0.b  选最老：两个源按 robIdx 比较（Redirect.selectOldestRedirect 的 2 项特例）
  //   sel_exu  = exu.valid  & (!load.valid | !(exu 在 load 之后))
  //   sel_load = load.valid & (!exu.valid  |   exu 在 load 之后 )
  // ---------------------------------------------------------------------------
  wire exu_after_load = rob_is_after(exu_bits.robIdx, load_bits.robIdx);
  wire sel_exu  = exu_valid  & (~load_valid | ~exu_after_load);
  wire sel_load = load_valid & (~exu_valid  |  exu_after_load);

  // 被最近一次冲刷覆盖的重定向作废（robIdx.needFlush(flushAfter) 或 Rob 正在冲刷）
  logic     flushAfter_valid;
  rob_ptr_t flushAfter_robIdx;
  logic     flushAfter_level;
  logic [2:0] flushAfterCounter;   // 无复位

  // 函数只看参数（Formality FMR_VLOG-091：函数体读模块级信号会让 set_top 失败）
  function automatic logic need_flush(input rob_ptr_t idx, input logic fa_valid,
                                      input rob_ptr_t fa_robIdx, input logic fa_level,
                                      input logic rob_flushing);
    return fa_valid & (fa_level & (idx == fa_robIdx) | rob_is_after(idx, fa_robIdx))
         | rob_flushing;
  endfunction
  wire exu_flushed  = need_flush(exu_bits.robIdx,  flushAfter_valid, flushAfter_robIdx, flushAfter_level, robFlush_valid);
  wire load_flushed = need_flush(load_bits.robIdx, flushAfter_valid, flushAfter_robIdx, flushAfter_level, robFlush_valid);

  wire oldestValid = (sel_exu & ~exu_flushed) | (sel_load & ~load_flushed);

  // Mux1H：选中者的字段按位或（未选中者贡献 0）
  redirect_t oldest_bits;
  assign oldest_bits = (sel_exu ? exu_fixed : '0) | (sel_load ? load_bits : '0);

  // ---------------------------------------------------------------------------
  // flushAfter：Rob 冲刷优先于本地选出的重定向；有效期由 3 位计数器右移控制
  // ---------------------------------------------------------------------------
  wire robFlushOrExuFlushValid = oldestValid | robFlush_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      flushAfter_valid  <= 1'b0;
      flushAfter_robIdx <= '0;
      flushAfter_level  <= 1'b0;
    end else begin
      flushAfter_valid <= robFlushOrExuFlushValid | (flushAfterCounter[0] & flushAfter_valid);
      if (robFlushOrExuFlushValid) begin
        flushAfter_robIdx <= robFlush_valid ? robFlush_robIdx : oldest_bits.robIdx;
        flushAfter_level  <= robFlush_valid ? robFlush_level  : oldest_bits.level;
      end
    end
  end

  always_ff @(posedge clock) begin
    if (robFlushOrExuFlushValid)      flushAfterCounter <= 3'b111;
    else if (flushAfterCounter[0])    flushAfterCounter <= {1'b0, flushAfterCounter[2:1]};
  end

  // ---------------------------------------------------------------------------
  // s1：锁存选中的重定向
  // ---------------------------------------------------------------------------
  logic       s1_valid;        // 复位 0
  logic [1:0] s1_onehot;       // {sel_load, sel_exu}，复位 0
  redirect_t  s1_bits;         // 无复位
  predecode_t s1_pd;           // 无复位

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid  <= 1'b0;
      s1_onehot <= 2'b00;
    end else begin
      s1_valid  <= oldestValid;
      s1_onehot <= {sel_load, sel_exu};
    end
  end

  always_ff @(posedge clock) begin
    if (oldestValid) begin
      s1_bits <= oldest_bits;
      s1_bits.debugIsMemVio <= sel_load;   // exu 来源恒 0、load 来源恒 1
      s1_pd   <= exu_predecode;
    end
  end

  assign stage2_valid    = s1_valid & ~robFlush_valid;
  assign stage2_bits     = s1_bits;
  assign stage2_pd       = s1_pd;
  assign stage2_oldestOH = s1_onehot;

  // ---------------------------------------------------------------------------
  // s2：load 回放触发访存相关性预测器更新
  // ---------------------------------------------------------------------------
  wire s1_isReplay      = s1_onehot[1];
  wire s1_replay_fire   = s1_isReplay & s1_valid;
  logic [MEMPRED_PC_W-1:0] memPred_waddr_q, memPred_ldpc_q, memPred_stpc_q;   // 无复位

  always_ff @(posedge clock or posedge reset) begin
    if (reset) memPredUpdate_valid <= 1'b0;
    else       memPredUpdate_valid <= s1_replay_fire & s1_bits.level;   // flushItself
  end

  always_ff @(posedge clock) begin
    if (s1_replay_fire) begin
      memPred_waddr_q <= fold_pc(s1_bits.cfiUpdate.pc);
      memPred_ldpc_q  <= fold_pc(s1_bits.cfiUpdate.pc);
      memPred_stpc_q  <= fold_pc(memPredPcRead_data);
    end
  end
  assign memPredUpdate_waddr = memPred_waddr_q;
  assign memPredUpdate_ldpc  = memPred_ldpc_q;
  assign memPredUpdate_stpc  = memPred_stpc_q;

endmodule : xs_RedirectGenerator_core

// BEGIN GENERATED(redirectgen_wrapper) —— 由 scripts/gen_redirectgen.py 从 golden 端口表产出
module RedirectGenerator(
  input  clock,
  input  reset,
  input  io_oldestExuRedirect_valid,
  input  io_oldestExuRedirect_bits_isRVC,
  input  io_oldestExuRedirect_bits_robIdx_flag,
  input  [7:0] io_oldestExuRedirect_bits_robIdx_value,
  input  io_oldestExuRedirect_bits_ftqIdx_flag,
  input  [5:0] io_oldestExuRedirect_bits_ftqIdx_value,
  input  [3:0] io_oldestExuRedirect_bits_ftqOffset,
  input  io_oldestExuRedirect_bits_level,
  input  io_oldestExuRedirect_bits_interrupt,
  input  [49:0] io_oldestExuRedirect_bits_cfiUpdate_pc,
  input  [3:0] io_oldestExuRedirect_bits_cfiUpdate_ssp,
  input  [2:0] io_oldestExuRedirect_bits_cfiUpdate_sctr,
  input  io_oldestExuRedirect_bits_cfiUpdate_TOSW_flag,
  input  [4:0] io_oldestExuRedirect_bits_cfiUpdate_TOSW_value,
  input  io_oldestExuRedirect_bits_cfiUpdate_TOSR_flag,
  input  [4:0] io_oldestExuRedirect_bits_cfiUpdate_TOSR_value,
  input  io_oldestExuRedirect_bits_cfiUpdate_NOS_flag,
  input  [4:0] io_oldestExuRedirect_bits_cfiUpdate_NOS_value,
  input  [49:0] io_oldestExuRedirect_bits_cfiUpdate_topAddr,
  input  [10:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  input  [10:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  input  [6:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  input  [8:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  input  [3:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  input  [8:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  input  [6:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  input  [6:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  input  [8:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  input  [6:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  input  [10:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  input  io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  input  [2:0] io_oldestExuRedirect_bits_cfiUpdate_lastBrNumOH,
  input  [3:0] io_oldestExuRedirect_bits_cfiUpdate_ghr,
  input  io_oldestExuRedirect_bits_cfiUpdate_histPtr_flag,
  input  [7:0] io_oldestExuRedirect_bits_cfiUpdate_histPtr_value,
  input  [9:0] io_oldestExuRedirect_bits_cfiUpdate_specCnt_0,
  input  [9:0] io_oldestExuRedirect_bits_cfiUpdate_specCnt_1,
  input  io_oldestExuRedirect_bits_cfiUpdate_br_hit,
  input  io_oldestExuRedirect_bits_cfiUpdate_jr_hit,
  input  io_oldestExuRedirect_bits_cfiUpdate_sc_hit,
  input  io_oldestExuRedirect_bits_cfiUpdate_predTaken,
  input  [49:0] io_oldestExuRedirect_bits_cfiUpdate_target,
  input  io_oldestExuRedirect_bits_cfiUpdate_taken,
  input  io_oldestExuRedirect_bits_cfiUpdate_isMisPred,
  input  [1:0] io_oldestExuRedirect_bits_cfiUpdate_shift,
  input  io_oldestExuRedirect_bits_cfiUpdate_addIntoHist,
  input  io_oldestExuRedirect_bits_cfiUpdate_backendIGPF,
  input  io_oldestExuRedirect_bits_cfiUpdate_backendIPF,
  input  io_oldestExuRedirect_bits_cfiUpdate_backendIAF,
  input  [63:0] io_oldestExuRedirect_bits_fullTarget,
  input  io_oldestExuRedirect_bits_satpFlush,
  input  io_oldestExuRedirect_bits_isVlsException,
  input  io_oldestExuRedirect_bits_stFtqIdx_flag,
  input  [5:0] io_oldestExuRedirect_bits_stFtqIdx_value,
  input  [3:0] io_oldestExuRedirect_bits_stFtqOffset,
  input  [63:0] io_oldestExuRedirect_bits_debug_runahead_checkpoint_id,
  input  io_oldestExuRedirect_bits_debugIsCtrl,
  input  io_oldestExuRedirectIsCSR,
  input  io_instrAddrTransType_bare,
  input  io_instrAddrTransType_sv39,
  input  io_instrAddrTransType_sv39x4,
  input  io_instrAddrTransType_sv48,
  input  io_instrAddrTransType_sv48x4,
  input  io_oldestExuOutPredecode_valid,
  input  io_oldestExuOutPredecode_isRVC,
  input  [1:0] io_oldestExuOutPredecode_brType,
  input  io_oldestExuOutPredecode_isCall,
  input  io_oldestExuOutPredecode_isRet,
  input  io_loadReplay_valid,
  input  io_loadReplay_bits_isRVC,
  input  io_loadReplay_bits_robIdx_flag,
  input  [7:0] io_loadReplay_bits_robIdx_value,
  input  io_loadReplay_bits_ftqIdx_flag,
  input  [5:0] io_loadReplay_bits_ftqIdx_value,
  input  [3:0] io_loadReplay_bits_ftqOffset,
  input  io_loadReplay_bits_level,
  input  [49:0] io_loadReplay_bits_cfiUpdate_pc,
  input  [49:0] io_loadReplay_bits_cfiUpdate_target,
  input  io_loadReplay_bits_stFtqIdx_flag,
  input  [5:0] io_loadReplay_bits_stFtqIdx_value,
  input  [3:0] io_loadReplay_bits_stFtqOffset,
  input  [63:0] io_loadReplay_bits_debug_runahead_checkpoint_id,
  input  io_robFlush_valid,
  input  io_robFlush_bits_robIdx_flag,
  input  [7:0] io_robFlush_bits_robIdx_value,
  input  io_robFlush_bits_level,
  output io_stage2Redirect_valid,
  output io_stage2Redirect_bits_isRVC,
  output io_stage2Redirect_bits_robIdx_flag,
  output [7:0] io_stage2Redirect_bits_robIdx_value,
  output io_stage2Redirect_bits_ftqIdx_flag,
  output [5:0] io_stage2Redirect_bits_ftqIdx_value,
  output [3:0] io_stage2Redirect_bits_ftqOffset,
  output io_stage2Redirect_bits_level,
  output io_stage2Redirect_bits_interrupt,
  output [49:0] io_stage2Redirect_bits_cfiUpdate_pc,
  output io_stage2Redirect_bits_cfiUpdate_pd_valid,
  output io_stage2Redirect_bits_cfiUpdate_pd_isRVC,
  output [1:0] io_stage2Redirect_bits_cfiUpdate_pd_brType,
  output io_stage2Redirect_bits_cfiUpdate_pd_isCall,
  output io_stage2Redirect_bits_cfiUpdate_pd_isRet,
  output [3:0] io_stage2Redirect_bits_cfiUpdate_ssp,
  output [2:0] io_stage2Redirect_bits_cfiUpdate_sctr,
  output io_stage2Redirect_bits_cfiUpdate_TOSW_flag,
  output [4:0] io_stage2Redirect_bits_cfiUpdate_TOSW_value,
  output io_stage2Redirect_bits_cfiUpdate_TOSR_flag,
  output [4:0] io_stage2Redirect_bits_cfiUpdate_TOSR_value,
  output io_stage2Redirect_bits_cfiUpdate_NOS_flag,
  output [4:0] io_stage2Redirect_bits_cfiUpdate_NOS_value,
  output [49:0] io_stage2Redirect_bits_cfiUpdate_topAddr,
  output [10:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist,
  output [10:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist,
  output [6:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist,
  output [8:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist,
  output [3:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist,
  output [8:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist,
  output [6:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist,
  output [6:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist,
  output [8:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist,
  output [6:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist,
  output [10:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_0,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_1,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_2,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_3,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_0,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_1,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_2,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_3,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_0,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_1,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_2,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_3,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_0,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_1,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_2,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_3,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_0,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_1,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_2,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_3,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_0,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_1,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_2,
  output io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_3,
  output [2:0] io_stage2Redirect_bits_cfiUpdate_lastBrNumOH,
  output [3:0] io_stage2Redirect_bits_cfiUpdate_ghr,
  output io_stage2Redirect_bits_cfiUpdate_histPtr_flag,
  output [7:0] io_stage2Redirect_bits_cfiUpdate_histPtr_value,
  output [9:0] io_stage2Redirect_bits_cfiUpdate_specCnt_0,
  output [9:0] io_stage2Redirect_bits_cfiUpdate_specCnt_1,
  output io_stage2Redirect_bits_cfiUpdate_br_hit,
  output io_stage2Redirect_bits_cfiUpdate_jr_hit,
  output io_stage2Redirect_bits_cfiUpdate_sc_hit,
  output io_stage2Redirect_bits_cfiUpdate_predTaken,
  output [49:0] io_stage2Redirect_bits_cfiUpdate_target,
  output io_stage2Redirect_bits_cfiUpdate_taken,
  output io_stage2Redirect_bits_cfiUpdate_isMisPred,
  output [1:0] io_stage2Redirect_bits_cfiUpdate_shift,
  output io_stage2Redirect_bits_cfiUpdate_addIntoHist,
  output io_stage2Redirect_bits_cfiUpdate_backendIGPF,
  output io_stage2Redirect_bits_cfiUpdate_backendIPF,
  output io_stage2Redirect_bits_cfiUpdate_backendIAF,
  output [63:0] io_stage2Redirect_bits_fullTarget,
  output io_stage2Redirect_bits_satpFlush,
  output io_stage2Redirect_bits_isVlsException,
  output io_stage2Redirect_bits_stFtqIdx_flag,
  output [5:0] io_stage2Redirect_bits_stFtqIdx_value,
  output [3:0] io_stage2Redirect_bits_stFtqOffset,
  output [63:0] io_stage2Redirect_bits_debug_runahead_checkpoint_id,
  output io_stage2Redirect_bits_debugIsCtrl,
  output io_stage2Redirect_bits_debugIsMemVio,
  output io_memPredUpdate_valid,
  output [9:0] io_memPredUpdate_waddr,
  output [9:0] io_memPredUpdate_ldpc,
  output [9:0] io_memPredUpdate_stpc,
  input  [49:0] io_memPredPcRead_data,
  output [1:0] io_stage2oldestOH
);
  import redirectgen_pkg::*;
  redirect_t exu_bits, load_bits, stage2_bits;
  predecode_t stage2_pd;
  always_comb begin
    exu_bits = '0;
    exu_bits.isRVC = io_oldestExuRedirect_bits_isRVC;
    exu_bits.robIdx.flag = io_oldestExuRedirect_bits_robIdx_flag;
    exu_bits.robIdx.value = io_oldestExuRedirect_bits_robIdx_value;
    exu_bits.ftqIdx_flag = io_oldestExuRedirect_bits_ftqIdx_flag;
    exu_bits.ftqIdx_value = io_oldestExuRedirect_bits_ftqIdx_value;
    exu_bits.ftqOffset = io_oldestExuRedirect_bits_ftqOffset;
    exu_bits.level = io_oldestExuRedirect_bits_level;
    exu_bits.interrupt = io_oldestExuRedirect_bits_interrupt;
    exu_bits.cfiUpdate.pc = io_oldestExuRedirect_bits_cfiUpdate_pc;
    exu_bits.cfiUpdate.ssp = io_oldestExuRedirect_bits_cfiUpdate_ssp;
    exu_bits.cfiUpdate.sctr = io_oldestExuRedirect_bits_cfiUpdate_sctr;
    exu_bits.cfiUpdate.TOSW_flag = io_oldestExuRedirect_bits_cfiUpdate_TOSW_flag;
    exu_bits.cfiUpdate.TOSW_value = io_oldestExuRedirect_bits_cfiUpdate_TOSW_value;
    exu_bits.cfiUpdate.TOSR_flag = io_oldestExuRedirect_bits_cfiUpdate_TOSR_flag;
    exu_bits.cfiUpdate.TOSR_value = io_oldestExuRedirect_bits_cfiUpdate_TOSR_value;
    exu_bits.cfiUpdate.NOS_flag = io_oldestExuRedirect_bits_cfiUpdate_NOS_flag;
    exu_bits.cfiUpdate.NOS_value = io_oldestExuRedirect_bits_cfiUpdate_NOS_value;
    exu_bits.cfiUpdate.topAddr = io_oldestExuRedirect_bits_cfiUpdate_topAddr;
    exu_bits.cfiUpdate.folded_hist_17 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist;
    exu_bits.cfiUpdate.folded_hist_16 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist;
    exu_bits.cfiUpdate.folded_hist_15 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist;
    exu_bits.cfiUpdate.folded_hist_14 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist;
    exu_bits.cfiUpdate.folded_hist_13 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist;
    exu_bits.cfiUpdate.folded_hist_12 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist;
    exu_bits.cfiUpdate.folded_hist_11 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist;
    exu_bits.cfiUpdate.folded_hist_10 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist;
    exu_bits.cfiUpdate.folded_hist_9 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist;
    exu_bits.cfiUpdate.folded_hist_8 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist;
    exu_bits.cfiUpdate.folded_hist_7 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist;
    exu_bits.cfiUpdate.folded_hist_6 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist;
    exu_bits.cfiUpdate.folded_hist_5 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist;
    exu_bits.cfiUpdate.folded_hist_4 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist;
    exu_bits.cfiUpdate.folded_hist_3 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist;
    exu_bits.cfiUpdate.folded_hist_2 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist;
    exu_bits.cfiUpdate.folded_hist_1 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist;
    exu_bits.cfiUpdate.folded_hist_0 = io_oldestExuRedirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist;
    exu_bits.cfiUpdate.afhob_5_0 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_0;
    exu_bits.cfiUpdate.afhob_5_1 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_1;
    exu_bits.cfiUpdate.afhob_5_2 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_2;
    exu_bits.cfiUpdate.afhob_5_3 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_5_bits_3;
    exu_bits.cfiUpdate.afhob_4_0 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_0;
    exu_bits.cfiUpdate.afhob_4_1 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_1;
    exu_bits.cfiUpdate.afhob_4_2 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_2;
    exu_bits.cfiUpdate.afhob_4_3 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_4_bits_3;
    exu_bits.cfiUpdate.afhob_3_0 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_0;
    exu_bits.cfiUpdate.afhob_3_1 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_1;
    exu_bits.cfiUpdate.afhob_3_2 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_2;
    exu_bits.cfiUpdate.afhob_3_3 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_3_bits_3;
    exu_bits.cfiUpdate.afhob_2_0 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_0;
    exu_bits.cfiUpdate.afhob_2_1 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_1;
    exu_bits.cfiUpdate.afhob_2_2 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_2;
    exu_bits.cfiUpdate.afhob_2_3 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_2_bits_3;
    exu_bits.cfiUpdate.afhob_1_0 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_0;
    exu_bits.cfiUpdate.afhob_1_1 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_1;
    exu_bits.cfiUpdate.afhob_1_2 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_2;
    exu_bits.cfiUpdate.afhob_1_3 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_1_bits_3;
    exu_bits.cfiUpdate.afhob_0_0 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_0;
    exu_bits.cfiUpdate.afhob_0_1 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_1;
    exu_bits.cfiUpdate.afhob_0_2 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_2;
    exu_bits.cfiUpdate.afhob_0_3 = io_oldestExuRedirect_bits_cfiUpdate_afhob_afhob_0_bits_3;
    exu_bits.cfiUpdate.lastBrNumOH = io_oldestExuRedirect_bits_cfiUpdate_lastBrNumOH;
    exu_bits.cfiUpdate.ghr = io_oldestExuRedirect_bits_cfiUpdate_ghr;
    exu_bits.cfiUpdate.histPtr_flag = io_oldestExuRedirect_bits_cfiUpdate_histPtr_flag;
    exu_bits.cfiUpdate.histPtr_value = io_oldestExuRedirect_bits_cfiUpdate_histPtr_value;
    exu_bits.cfiUpdate.specCnt_0 = io_oldestExuRedirect_bits_cfiUpdate_specCnt_0;
    exu_bits.cfiUpdate.specCnt_1 = io_oldestExuRedirect_bits_cfiUpdate_specCnt_1;
    exu_bits.cfiUpdate.br_hit = io_oldestExuRedirect_bits_cfiUpdate_br_hit;
    exu_bits.cfiUpdate.jr_hit = io_oldestExuRedirect_bits_cfiUpdate_jr_hit;
    exu_bits.cfiUpdate.sc_hit = io_oldestExuRedirect_bits_cfiUpdate_sc_hit;
    exu_bits.cfiUpdate.predTaken = io_oldestExuRedirect_bits_cfiUpdate_predTaken;
    exu_bits.cfiUpdate.target = io_oldestExuRedirect_bits_cfiUpdate_target;
    exu_bits.cfiUpdate.taken = io_oldestExuRedirect_bits_cfiUpdate_taken;
    exu_bits.cfiUpdate.isMisPred = io_oldestExuRedirect_bits_cfiUpdate_isMisPred;
    exu_bits.cfiUpdate.shift = io_oldestExuRedirect_bits_cfiUpdate_shift;
    exu_bits.cfiUpdate.addIntoHist = io_oldestExuRedirect_bits_cfiUpdate_addIntoHist;
    exu_bits.cfiUpdate.backendIGPF = io_oldestExuRedirect_bits_cfiUpdate_backendIGPF;
    exu_bits.cfiUpdate.backendIPF = io_oldestExuRedirect_bits_cfiUpdate_backendIPF;
    exu_bits.cfiUpdate.backendIAF = io_oldestExuRedirect_bits_cfiUpdate_backendIAF;
    exu_bits.fullTarget = io_oldestExuRedirect_bits_fullTarget;
    exu_bits.satpFlush = io_oldestExuRedirect_bits_satpFlush;
    exu_bits.isVlsException = io_oldestExuRedirect_bits_isVlsException;
    exu_bits.stFtqIdx_flag = io_oldestExuRedirect_bits_stFtqIdx_flag;
    exu_bits.stFtqIdx_value = io_oldestExuRedirect_bits_stFtqIdx_value;
    exu_bits.stFtqOffset = io_oldestExuRedirect_bits_stFtqOffset;
    exu_bits.debug_runahead_checkpoint_id = io_oldestExuRedirect_bits_debug_runahead_checkpoint_id;
    exu_bits.debugIsCtrl = io_oldestExuRedirect_bits_debugIsCtrl;
  end
  always_comb begin
    load_bits = '0;
    load_bits.isRVC = io_loadReplay_bits_isRVC;
    load_bits.robIdx.flag = io_loadReplay_bits_robIdx_flag;
    load_bits.robIdx.value = io_loadReplay_bits_robIdx_value;
    load_bits.ftqIdx_flag = io_loadReplay_bits_ftqIdx_flag;
    load_bits.ftqIdx_value = io_loadReplay_bits_ftqIdx_value;
    load_bits.ftqOffset = io_loadReplay_bits_ftqOffset;
    load_bits.level = io_loadReplay_bits_level;
    load_bits.cfiUpdate.pc = io_loadReplay_bits_cfiUpdate_pc;
    load_bits.cfiUpdate.target = io_loadReplay_bits_cfiUpdate_target;
    load_bits.stFtqIdx_flag = io_loadReplay_bits_stFtqIdx_flag;
    load_bits.stFtqIdx_value = io_loadReplay_bits_stFtqIdx_value;
    load_bits.stFtqOffset = io_loadReplay_bits_stFtqOffset;
    load_bits.debug_runahead_checkpoint_id = io_loadReplay_bits_debug_runahead_checkpoint_id;
    load_bits.debugIsMemVio = 1'b1;   // load 回放来源恒 1（golden 寄存 one-hot[1]）
  end
  assign io_stage2Redirect_bits_isRVC = stage2_bits.isRVC;
  assign io_stage2Redirect_bits_robIdx_flag = stage2_bits.robIdx.flag;
  assign io_stage2Redirect_bits_robIdx_value = stage2_bits.robIdx.value;
  assign io_stage2Redirect_bits_ftqIdx_flag = stage2_bits.ftqIdx_flag;
  assign io_stage2Redirect_bits_ftqIdx_value = stage2_bits.ftqIdx_value;
  assign io_stage2Redirect_bits_ftqOffset = stage2_bits.ftqOffset;
  assign io_stage2Redirect_bits_level = stage2_bits.level;
  assign io_stage2Redirect_bits_interrupt = stage2_bits.interrupt;
  assign io_stage2Redirect_bits_cfiUpdate_pc = stage2_bits.cfiUpdate.pc;
  assign io_stage2Redirect_bits_cfiUpdate_ssp = stage2_bits.cfiUpdate.ssp;
  assign io_stage2Redirect_bits_cfiUpdate_sctr = stage2_bits.cfiUpdate.sctr;
  assign io_stage2Redirect_bits_cfiUpdate_TOSW_flag = stage2_bits.cfiUpdate.TOSW_flag;
  assign io_stage2Redirect_bits_cfiUpdate_TOSW_value = stage2_bits.cfiUpdate.TOSW_value;
  assign io_stage2Redirect_bits_cfiUpdate_TOSR_flag = stage2_bits.cfiUpdate.TOSR_flag;
  assign io_stage2Redirect_bits_cfiUpdate_TOSR_value = stage2_bits.cfiUpdate.TOSR_value;
  assign io_stage2Redirect_bits_cfiUpdate_NOS_flag = stage2_bits.cfiUpdate.NOS_flag;
  assign io_stage2Redirect_bits_cfiUpdate_NOS_value = stage2_bits.cfiUpdate.NOS_value;
  assign io_stage2Redirect_bits_cfiUpdate_topAddr = stage2_bits.cfiUpdate.topAddr;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_17_folded_hist = stage2_bits.cfiUpdate.folded_hist_17;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_16_folded_hist = stage2_bits.cfiUpdate.folded_hist_16;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_15_folded_hist = stage2_bits.cfiUpdate.folded_hist_15;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_14_folded_hist = stage2_bits.cfiUpdate.folded_hist_14;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_13_folded_hist = stage2_bits.cfiUpdate.folded_hist_13;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_12_folded_hist = stage2_bits.cfiUpdate.folded_hist_12;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_11_folded_hist = stage2_bits.cfiUpdate.folded_hist_11;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_10_folded_hist = stage2_bits.cfiUpdate.folded_hist_10;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_9_folded_hist = stage2_bits.cfiUpdate.folded_hist_9;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_8_folded_hist = stage2_bits.cfiUpdate.folded_hist_8;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_7_folded_hist = stage2_bits.cfiUpdate.folded_hist_7;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_6_folded_hist = stage2_bits.cfiUpdate.folded_hist_6;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_5_folded_hist = stage2_bits.cfiUpdate.folded_hist_5;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_4_folded_hist = stage2_bits.cfiUpdate.folded_hist_4;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_3_folded_hist = stage2_bits.cfiUpdate.folded_hist_3;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_2_folded_hist = stage2_bits.cfiUpdate.folded_hist_2;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_1_folded_hist = stage2_bits.cfiUpdate.folded_hist_1;
  assign io_stage2Redirect_bits_cfiUpdate_folded_hist_hist_0_folded_hist = stage2_bits.cfiUpdate.folded_hist_0;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_0 = stage2_bits.cfiUpdate.afhob_5_0;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_1 = stage2_bits.cfiUpdate.afhob_5_1;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_2 = stage2_bits.cfiUpdate.afhob_5_2;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_5_bits_3 = stage2_bits.cfiUpdate.afhob_5_3;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_0 = stage2_bits.cfiUpdate.afhob_4_0;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_1 = stage2_bits.cfiUpdate.afhob_4_1;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_2 = stage2_bits.cfiUpdate.afhob_4_2;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_4_bits_3 = stage2_bits.cfiUpdate.afhob_4_3;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_0 = stage2_bits.cfiUpdate.afhob_3_0;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_1 = stage2_bits.cfiUpdate.afhob_3_1;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_2 = stage2_bits.cfiUpdate.afhob_3_2;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_3_bits_3 = stage2_bits.cfiUpdate.afhob_3_3;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_0 = stage2_bits.cfiUpdate.afhob_2_0;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_1 = stage2_bits.cfiUpdate.afhob_2_1;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_2 = stage2_bits.cfiUpdate.afhob_2_2;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_2_bits_3 = stage2_bits.cfiUpdate.afhob_2_3;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_0 = stage2_bits.cfiUpdate.afhob_1_0;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_1 = stage2_bits.cfiUpdate.afhob_1_1;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_2 = stage2_bits.cfiUpdate.afhob_1_2;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_1_bits_3 = stage2_bits.cfiUpdate.afhob_1_3;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_0 = stage2_bits.cfiUpdate.afhob_0_0;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_1 = stage2_bits.cfiUpdate.afhob_0_1;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_2 = stage2_bits.cfiUpdate.afhob_0_2;
  assign io_stage2Redirect_bits_cfiUpdate_afhob_afhob_0_bits_3 = stage2_bits.cfiUpdate.afhob_0_3;
  assign io_stage2Redirect_bits_cfiUpdate_lastBrNumOH = stage2_bits.cfiUpdate.lastBrNumOH;
  assign io_stage2Redirect_bits_cfiUpdate_ghr = stage2_bits.cfiUpdate.ghr;
  assign io_stage2Redirect_bits_cfiUpdate_histPtr_flag = stage2_bits.cfiUpdate.histPtr_flag;
  assign io_stage2Redirect_bits_cfiUpdate_histPtr_value = stage2_bits.cfiUpdate.histPtr_value;
  assign io_stage2Redirect_bits_cfiUpdate_specCnt_0 = stage2_bits.cfiUpdate.specCnt_0;
  assign io_stage2Redirect_bits_cfiUpdate_specCnt_1 = stage2_bits.cfiUpdate.specCnt_1;
  assign io_stage2Redirect_bits_cfiUpdate_br_hit = stage2_bits.cfiUpdate.br_hit;
  assign io_stage2Redirect_bits_cfiUpdate_jr_hit = stage2_bits.cfiUpdate.jr_hit;
  assign io_stage2Redirect_bits_cfiUpdate_sc_hit = stage2_bits.cfiUpdate.sc_hit;
  assign io_stage2Redirect_bits_cfiUpdate_predTaken = stage2_bits.cfiUpdate.predTaken;
  assign io_stage2Redirect_bits_cfiUpdate_target = stage2_bits.cfiUpdate.target;
  assign io_stage2Redirect_bits_cfiUpdate_taken = stage2_bits.cfiUpdate.taken;
  assign io_stage2Redirect_bits_cfiUpdate_isMisPred = stage2_bits.cfiUpdate.isMisPred;
  assign io_stage2Redirect_bits_cfiUpdate_shift = stage2_bits.cfiUpdate.shift;
  assign io_stage2Redirect_bits_cfiUpdate_addIntoHist = stage2_bits.cfiUpdate.addIntoHist;
  assign io_stage2Redirect_bits_cfiUpdate_backendIGPF = stage2_bits.cfiUpdate.backendIGPF;
  assign io_stage2Redirect_bits_cfiUpdate_backendIPF = stage2_bits.cfiUpdate.backendIPF;
  assign io_stage2Redirect_bits_cfiUpdate_backendIAF = stage2_bits.cfiUpdate.backendIAF;
  assign io_stage2Redirect_bits_fullTarget = stage2_bits.fullTarget;
  assign io_stage2Redirect_bits_satpFlush = stage2_bits.satpFlush;
  assign io_stage2Redirect_bits_isVlsException = stage2_bits.isVlsException;
  assign io_stage2Redirect_bits_stFtqIdx_flag = stage2_bits.stFtqIdx_flag;
  assign io_stage2Redirect_bits_stFtqIdx_value = stage2_bits.stFtqIdx_value;
  assign io_stage2Redirect_bits_stFtqOffset = stage2_bits.stFtqOffset;
  assign io_stage2Redirect_bits_debug_runahead_checkpoint_id = stage2_bits.debug_runahead_checkpoint_id;
  assign io_stage2Redirect_bits_debugIsCtrl = stage2_bits.debugIsCtrl;
  assign io_stage2Redirect_bits_debugIsMemVio = stage2_bits.debugIsMemVio;
  assign io_stage2Redirect_bits_cfiUpdate_pd_valid = stage2_pd.valid;
  assign io_stage2Redirect_bits_cfiUpdate_pd_isRVC = stage2_pd.isRVC;
  assign io_stage2Redirect_bits_cfiUpdate_pd_brType = stage2_pd.brType;
  assign io_stage2Redirect_bits_cfiUpdate_pd_isCall = stage2_pd.isCall;
  assign io_stage2Redirect_bits_cfiUpdate_pd_isRet = stage2_pd.isRet;

  xs_RedirectGenerator_core u_core (
    .clock              (clock),
    .reset              (reset),
    .exu_valid          (io_oldestExuRedirect_valid),
    .exu_bits           (exu_bits),
    .exu_isCSR          (io_oldestExuRedirectIsCSR),
    .instrAddrTransType ('{bare: io_instrAddrTransType_bare, sv39: io_instrAddrTransType_sv39,
                           sv39x4: io_instrAddrTransType_sv39x4, sv48: io_instrAddrTransType_sv48,
                           sv48x4: io_instrAddrTransType_sv48x4}),
    .exu_predecode      ('{valid: io_oldestExuOutPredecode_valid, isRVC: io_oldestExuOutPredecode_isRVC,
                           brType: io_oldestExuOutPredecode_brType, isCall: io_oldestExuOutPredecode_isCall,
                           isRet: io_oldestExuOutPredecode_isRet}),
    .load_valid         (io_loadReplay_valid),
    .load_bits          (load_bits),
    .robFlush_valid     (io_robFlush_valid),
    .robFlush_robIdx    ('{flag: io_robFlush_bits_robIdx_flag, value: io_robFlush_bits_robIdx_value}),
    .robFlush_level     (io_robFlush_bits_level),
    .memPredPcRead_data (io_memPredPcRead_data),
    .stage2_valid       (io_stage2Redirect_valid),
    .stage2_bits        (stage2_bits),
    .stage2_pd          (stage2_pd),
    .stage2_oldestOH    (io_stage2oldestOH),
    .memPredUpdate_valid(io_memPredUpdate_valid),
    .memPredUpdate_waddr(io_memPredUpdate_waddr),
    .memPredUpdate_ldpc (io_memPredUpdate_ldpc),
    .memPredUpdate_stpc (io_memPredUpdate_stpc)
  );
endmodule
// END GENERATED
