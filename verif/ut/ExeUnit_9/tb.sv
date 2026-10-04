// =============================================================================
// tb —— ExeUnit_9 双例化 UT（由 scripts/gen_exeunits_ut.py 生成，勿手改）
//   golden ExeUnit_9 vs 重写 ExeUnit_9_xs；每拍比较全部 22 个输出口（!==）。
//   激励 / 覆盖 / 判据见生成器 TARGETS 里本目标一节。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARM = 13;
  localparam int RESET_ODDS = 20000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic io_flush_valid;
  logic io_flush_bits_robIdx_flag;
  logic [7:0] io_flush_bits_robIdx_value;
  logic io_flush_bits_level;
  logic io_in_valid;
  logic [34:0] io_in_bits_fuType;
  logic [8:0] io_in_bits_fuOpType;
  logic [63:0] io_in_bits_src_0;
  logic [63:0] io_in_bits_src_1;
  logic io_in_bits_robIdx_flag;
  logic [7:0] io_in_bits_robIdx_value;
  logic [7:0] io_in_bits_pdest;
  logic io_in_bits_fpWen;
  logic io_in_bits_fpu_wflags;
  logic [1:0] io_in_bits_fpu_fmt;
  logic [2:0] io_in_bits_fpu_rm;
  logic io_in_bits_perfDebugInfo_eliminatedMove;
  logic [63:0] io_in_bits_perfDebugInfo_renameTime;
  logic [63:0] io_in_bits_perfDebugInfo_dispatchTime;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic [63:0] io_in_bits_perfDebugInfo_writebackTime;
  logic [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id;
  logic [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime;
  logic [63:0] io_in_bits_perfDebugInfo_tlbRespTime;
  logic [55:0] io_in_bits_debug_seqNum_seqNum;
  logic [7:0] io_in_bits_debug_seqNum_uopIdx;
  logic io_out_ready;
  logic [2:0] io_frm;
  logic cg_bore_cgen;
  wire  g_io_in_ready, i_io_in_ready;
  wire  g_io_out_valid, i_io_out_valid;
  wire  [63:0] g_io_out_bits_data_0, i_io_out_bits_data_0;
  wire  [63:0] g_io_out_bits_data_1, i_io_out_bits_data_1;
  wire  [7:0] g_io_out_bits_pdest, i_io_out_bits_pdest;
  wire  g_io_out_bits_robIdx_flag, i_io_out_bits_robIdx_flag;
  wire  [7:0] g_io_out_bits_robIdx_value, i_io_out_bits_robIdx_value;
  wire  g_io_out_bits_fpWen, i_io_out_bits_fpWen;
  wire  [4:0] g_io_out_bits_fflags, i_io_out_bits_fflags;
  wire  g_io_out_bits_wflags, i_io_out_bits_wflags;
  wire  g_io_out_bits_debugInfo_eliminatedMove, i_io_out_bits_debugInfo_eliminatedMove;
  wire  [63:0] g_io_out_bits_debugInfo_renameTime, i_io_out_bits_debugInfo_renameTime;
  wire  [63:0] g_io_out_bits_debugInfo_dispatchTime, i_io_out_bits_debugInfo_dispatchTime;
  wire  [63:0] g_io_out_bits_debugInfo_enqRsTime, i_io_out_bits_debugInfo_enqRsTime;
  wire  [63:0] g_io_out_bits_debugInfo_selectTime, i_io_out_bits_debugInfo_selectTime;
  wire  [63:0] g_io_out_bits_debugInfo_issueTime, i_io_out_bits_debugInfo_issueTime;
  wire  [63:0] g_io_out_bits_debugInfo_writebackTime, i_io_out_bits_debugInfo_writebackTime;
  wire  [63:0] g_io_out_bits_debugInfo_runahead_checkpoint_id, i_io_out_bits_debugInfo_runahead_checkpoint_id;
  wire  [63:0] g_io_out_bits_debugInfo_tlbFirstReqTime, i_io_out_bits_debugInfo_tlbFirstReqTime;
  wire  [63:0] g_io_out_bits_debugInfo_tlbRespTime, i_io_out_bits_debugInfo_tlbRespTime;
  wire  [55:0] g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;
  localparam int NFU = 1;
  logic [34:0] fu_code [NFU] = '{35'h4000};
  longint c_in [NFU];
  longint c_out [NFU];
  longint c_stall = 0, c_flush = 0, c_nofu = 0, c_cg_on = 0, c_cg_off = 0, c_busy = 0;

  ExeUnit_9 u_g (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_fpWen(io_in_bits_fpWen),
    .io_in_bits_fpu_wflags(io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_frm(io_frm),
    .cg_bore_cgen(cg_bore_cgen),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_data_0(g_io_out_bits_data_0),
    .io_out_bits_data_1(g_io_out_bits_data_1),
    .io_out_bits_pdest(g_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(g_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_io_out_bits_robIdx_value),
    .io_out_bits_fpWen(g_io_out_bits_fpWen),
    .io_out_bits_fflags(g_io_out_bits_fflags),
    .io_out_bits_wflags(g_io_out_bits_wflags),
    .io_out_bits_debugInfo_eliminatedMove(g_io_out_bits_debugInfo_eliminatedMove),
    .io_out_bits_debugInfo_renameTime(g_io_out_bits_debugInfo_renameTime),
    .io_out_bits_debugInfo_dispatchTime(g_io_out_bits_debugInfo_dispatchTime),
    .io_out_bits_debugInfo_enqRsTime(g_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(g_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(g_io_out_bits_debugInfo_issueTime),
    .io_out_bits_debugInfo_writebackTime(g_io_out_bits_debugInfo_writebackTime),
    .io_out_bits_debugInfo_runahead_checkpoint_id(g_io_out_bits_debugInfo_runahead_checkpoint_id),
    .io_out_bits_debugInfo_tlbFirstReqTime(g_io_out_bits_debugInfo_tlbFirstReqTime),
    .io_out_bits_debugInfo_tlbRespTime(g_io_out_bits_debugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx)
  );
  ExeUnit_9_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_fpWen(io_in_bits_fpWen),
    .io_in_bits_fpu_wflags(io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready(io_out_ready),
    .io_frm(io_frm),
    .cg_bore_cgen(cg_bore_cgen),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_data_0(i_io_out_bits_data_0),
    .io_out_bits_data_1(i_io_out_bits_data_1),
    .io_out_bits_pdest(i_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(i_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_io_out_bits_robIdx_value),
    .io_out_bits_fpWen(i_io_out_bits_fpWen),
    .io_out_bits_fflags(i_io_out_bits_fflags),
    .io_out_bits_wflags(i_io_out_bits_wflags),
    .io_out_bits_debugInfo_eliminatedMove(i_io_out_bits_debugInfo_eliminatedMove),
    .io_out_bits_debugInfo_renameTime(i_io_out_bits_debugInfo_renameTime),
    .io_out_bits_debugInfo_dispatchTime(i_io_out_bits_debugInfo_dispatchTime),
    .io_out_bits_debugInfo_enqRsTime(i_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(i_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(i_io_out_bits_debugInfo_issueTime),
    .io_out_bits_debugInfo_writebackTime(i_io_out_bits_debugInfo_writebackTime),
    .io_out_bits_debugInfo_runahead_checkpoint_id(i_io_out_bits_debugInfo_runahead_checkpoint_id),
    .io_out_bits_debugInfo_tlbFirstReqTime(i_io_out_bits_debugInfo_tlbFirstReqTime),
    .io_out_bits_debugInfo_tlbRespTime(i_io_out_bits_debugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx)
  );

  // 每拍激励：先全随机，再按目标语义覆盖
  task automatic drive();
    io_flush_valid = 1'($urandom);
    io_flush_bits_robIdx_flag = 1'($urandom);
    io_flush_bits_robIdx_value = 8'($urandom);
    io_flush_bits_level = 1'($urandom);
    io_in_valid = 1'($urandom);
    io_in_bits_fuType = 35'({$urandom(), $urandom()});
    io_in_bits_fuOpType = 9'($urandom);
    io_in_bits_src_0 = 64'({$urandom(), $urandom()});
    io_in_bits_src_1 = 64'({$urandom(), $urandom()});
    io_in_bits_robIdx_flag = 1'($urandom);
    io_in_bits_robIdx_value = 8'($urandom);
    io_in_bits_pdest = 8'($urandom);
    io_in_bits_fpWen = 1'($urandom);
    io_in_bits_fpu_wflags = 1'($urandom);
    io_in_bits_fpu_fmt = 2'($urandom);
    io_in_bits_fpu_rm = 3'($urandom);
    io_in_bits_perfDebugInfo_eliminatedMove = 1'($urandom);
    io_in_bits_perfDebugInfo_renameTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_dispatchTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_enqRsTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_selectTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_issueTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_writebackTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_runahead_checkpoint_id = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbFirstReqTime = 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbRespTime = 64'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_seqNum = 56'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_uopIdx = 8'($urandom);
    io_out_ready = 1'($urandom);
    io_frm = 3'($urandom);
    cg_bore_cgen = 1'($urandom);
    // fuType：85% 取本外壳某个 FU 的编码（与 Dispatcher 的 acceptVec 一致），其余全随机
    //   （多数不命中任何 FU：Dispatcher 不派发，指令被吞 —— 这条路两侧也必须一致）
    if ($urandom_range(0, 99) < 85) io_in_bits_fuType = fu_code[$urandom_range(0, NFU - 1)];
    io_in_valid  = ($urandom_range(0, 9) < 6);
    io_out_ready = ($urandom_range(0, 9) != 0);           // 10% 反压
    io_in_bits_robIdx_value = 8'($urandom_range(0, 15));  // 窄范围：冲刷比较两种结果都常见
    io_flush_valid = ($urandom_range(0, 9) == 0);
    io_flush_bits_robIdx_value = 8'($urandom_range(0, 15));
    cg_bore_cgen = ($urandom_range(0, 19) == 0);   // DFT 强开时钟，偶发
    // 暖机：复位撤销后轮流给每个 FU 发有效指令、不反压不冲刷，把各级不复位的寄存器写成确定值
    if (cyc < WARM) begin
      io_in_valid = 1; io_out_ready = 1;
      io_in_bits_fuType = fu_code[cyc % NFU];
      io_flush_valid = 0;
    end

  endtask

  task automatic compare();
    checks++; if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_in_ready g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    checks++; if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_valid g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    checks++; if (g_io_out_bits_data_0 !== i_io_out_bits_data_0) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_data_0 g=%h i=%h", cyc, g_io_out_bits_data_0, i_io_out_bits_data_0); end
    checks++; if (g_io_out_bits_data_1 !== i_io_out_bits_data_1) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_data_1 g=%h i=%h", cyc, g_io_out_bits_data_1, i_io_out_bits_data_1); end
    checks++; if (g_io_out_bits_pdest !== i_io_out_bits_pdest) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_pdest g=%h i=%h", cyc, g_io_out_bits_pdest, i_io_out_bits_pdest); end
    checks++; if (g_io_out_bits_robIdx_flag !== i_io_out_bits_robIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_robIdx_flag g=%h i=%h", cyc, g_io_out_bits_robIdx_flag, i_io_out_bits_robIdx_flag); end
    checks++; if (g_io_out_bits_robIdx_value !== i_io_out_bits_robIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_robIdx_value g=%h i=%h", cyc, g_io_out_bits_robIdx_value, i_io_out_bits_robIdx_value); end
    checks++; if (g_io_out_bits_fpWen !== i_io_out_bits_fpWen) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_fpWen g=%h i=%h", cyc, g_io_out_bits_fpWen, i_io_out_bits_fpWen); end
    checks++; if (g_io_out_bits_fflags !== i_io_out_bits_fflags) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_fflags g=%h i=%h", cyc, g_io_out_bits_fflags, i_io_out_bits_fflags); end
    checks++; if (g_io_out_bits_wflags !== i_io_out_bits_wflags) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_wflags g=%h i=%h", cyc, g_io_out_bits_wflags, i_io_out_bits_wflags); end
    checks++; if (g_io_out_bits_debugInfo_eliminatedMove !== i_io_out_bits_debugInfo_eliminatedMove) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_eliminatedMove g=%h i=%h", cyc, g_io_out_bits_debugInfo_eliminatedMove, i_io_out_bits_debugInfo_eliminatedMove); end
    checks++; if (g_io_out_bits_debugInfo_renameTime !== i_io_out_bits_debugInfo_renameTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_renameTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_renameTime, i_io_out_bits_debugInfo_renameTime); end
    checks++; if (g_io_out_bits_debugInfo_dispatchTime !== i_io_out_bits_debugInfo_dispatchTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_dispatchTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_dispatchTime, i_io_out_bits_debugInfo_dispatchTime); end
    checks++; if (g_io_out_bits_debugInfo_enqRsTime !== i_io_out_bits_debugInfo_enqRsTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_enqRsTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_enqRsTime, i_io_out_bits_debugInfo_enqRsTime); end
    checks++; if (g_io_out_bits_debugInfo_selectTime !== i_io_out_bits_debugInfo_selectTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_selectTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_selectTime, i_io_out_bits_debugInfo_selectTime); end
    checks++; if (g_io_out_bits_debugInfo_issueTime !== i_io_out_bits_debugInfo_issueTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_issueTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_issueTime, i_io_out_bits_debugInfo_issueTime); end
    checks++; if (g_io_out_bits_debugInfo_writebackTime !== i_io_out_bits_debugInfo_writebackTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_writebackTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_writebackTime, i_io_out_bits_debugInfo_writebackTime); end
    checks++; if (g_io_out_bits_debugInfo_runahead_checkpoint_id !== i_io_out_bits_debugInfo_runahead_checkpoint_id) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_runahead_checkpoint_id g=%h i=%h", cyc, g_io_out_bits_debugInfo_runahead_checkpoint_id, i_io_out_bits_debugInfo_runahead_checkpoint_id); end
    checks++; if (g_io_out_bits_debugInfo_tlbFirstReqTime !== i_io_out_bits_debugInfo_tlbFirstReqTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_tlbFirstReqTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_tlbFirstReqTime, i_io_out_bits_debugInfo_tlbFirstReqTime); end
    checks++; if (g_io_out_bits_debugInfo_tlbRespTime !== i_io_out_bits_debugInfo_tlbRespTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debugInfo_tlbRespTime g=%h i=%h", cyc, g_io_out_bits_debugInfo_tlbRespTime, i_io_out_bits_debugInfo_tlbRespTime); end
    checks++; if (g_io_out_bits_debug_seqNum_seqNum !== i_io_out_bits_debug_seqNum_seqNum) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_seqNum g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum); end
    checks++; if (g_io_out_bits_debug_seqNum_uopIdx !== i_io_out_bits_debug_seqNum_uopIdx) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_uopIdx g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx); end
  endtask

  task automatic sample_cov();
    if (u_g._in1ToN_io_out_0_valid && u_g._Fdiv_io_in_ready) c_in[0]++;
    if (u_g._Fdiv_io_out_valid) c_out[0]++;
    if (io_in_valid && !(io_in_bits_fuType inside {35'h4000})) c_nofu++;
    if (g_io_out_valid && !io_out_ready) c_stall++;
    if (io_flush_valid && io_in_valid) c_flush++;
    if (u_g.ClockGate.E) c_cg_on++; else c_cg_off++;
    if (u_g.busy) c_busy++;

  endtask

  initial begin
    bit ok;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    foreach (c_in[k]) begin c_in[k] = 0; c_out[k] = 0; end
    reset = 1;
    drive();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      reset = (cyc < 5) || ($urandom_range(0, RESET_ODDS - 1) == 0);
      drive();
      #4;
      if (cyc >= WARM) compare();
      if (!reset) sample_cov();
    end
    $display("cov in=%p out=%p stall=%0d flush=%0d nofu=%0d cg_on=%0d cg_off=%0d busy=%0d", c_in, c_out, c_stall, c_flush, c_nofu, c_cg_on, c_cg_off, c_busy);
    ok = (errors == 0) && (checks > 1000);
    if (!(c_in[0] > 1000)) begin ok = 0; $display("cov LOW: c_in[0] > 1000"); end
    if (!(c_out[0] > 1000)) begin ok = 0; $display("cov LOW: c_out[0] > 1000"); end
    if (!(c_stall > 1000)) begin ok = 0; $display("cov LOW: c_stall > 1000"); end
    if (!(c_nofu > 1000)) begin ok = 0; $display("cov LOW: c_nofu > 1000"); end
    if (!(c_flush > 1000)) begin ok = 0; $display("cov LOW: c_flush > 1000"); end
    if (!(c_cg_on > 1000)) begin ok = 0; $display("cov LOW: c_cg_on > 1000"); end
    if (!(c_cg_off > 1000)) begin ok = 0; $display("cov LOW: c_cg_off > 1000"); end
    if (!(c_busy > 1000)) begin ok = 0; $display("cov LOW: c_busy > 1000"); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
