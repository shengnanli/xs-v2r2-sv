// MulUnit UT —— golden MulUnit 与派生 MulUnit_xs 双例化，逐拍比对全部输出。
//
// 本 tb 的三件事（G1 这一轮的重点在第 3 条）：
//   1. 端口表按 G1 golden 重新生成（含 G0 没有的 io_in_ready / io_out_ready /
//      perfDebugInfo 7 个新字段 / debug_seqNum）；
//   2. opcode 激励覆盖各子块：mul/mulh/mulhsu/mulhu/mulw/mulw7 全表轮询；
//      另掺 1/8 的全随机 9bit（打非法编码，验四选一/LookupTree 的 default 语义）；
//   3. ★反压场景★：io_out_ready 周期性拉低 3~8 拍，把 rdyVec 链压住，验证
//      valid/payload 的保持行为。tb 末尾要求 stall 覆盖数达标才判 PASS，
//      并逐拍比对 golden 的 rdyVec_1 与重写核的 rdy_s1（内部反压链是否一致）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 100000;
  bit clk = 0;
  int errors = 0, checks = 0;
  int n_stall_s0 = 0, n_stall_s1 = 0, n_stall_hold = 0;
  int op_cov[64];
  always #5 clk = ~clk;

  logic clock, reset;
  assign clock = clk;

  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic io_in_bits_ctrlPipe_2_robIdx_flag;
  logic [7:0] io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0] io_in_bits_ctrlPipe_2_pdest;
  logic io_in_bits_ctrlPipe_2_rfWen;
  logic io_in_bits_validPipe_0;
  logic io_in_bits_validPipe_1;
  logic io_in_bits_validPipe_2;
  logic [63:0] io_in_bits_data_src_1;
  logic [63:0] io_in_bits_data_src_0;
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

  wire g_io_in_ready, i_io_in_ready;
  wire g_io_out_valid, i_io_out_valid;
  wire g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value;
  wire [7:0] g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest;
  wire g_io_out_bits_ctrl_rfWen, i_io_out_bits_ctrl_rfWen;
  wire [63:0] g_io_out_bits_res_data, i_io_out_bits_res_data;
  wire g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove;
  wire [63:0] g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire [63:0] g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime;
  wire [55:0] g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  wire [7:0] g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;

  MulUnit u_g (
    .clock (clock), .reset (reset),
    .io_in_valid (io_in_valid),
    .io_in_bits_ctrl_fuOpType (io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag (io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value (io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest (io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen (io_in_bits_ctrlPipe_2_rfWen),
    .io_in_bits_validPipe_0 (io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1 (io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2 (io_in_bits_validPipe_2),
    .io_in_bits_data_src_1 (io_in_bits_data_src_1),
    .io_in_bits_data_src_0 (io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove (io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime (io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime (io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime (io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime (io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime (io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime (io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum (io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx (io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready (io_out_ready),
    .io_in_ready (g_io_in_ready),
    .io_out_valid (g_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (g_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (g_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (g_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (g_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data (g_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove (g_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime (g_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime (g_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime (g_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (g_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (g_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime (g_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (g_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime (g_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime (g_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum (g_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx (g_io_out_bits_debug_seqNum_uopIdx)
  );
  MulUnit_xs u_i (
    .clock (clock), .reset (reset),
    .io_in_valid (io_in_valid),
    .io_in_bits_ctrl_fuOpType (io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag (io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value (io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest (io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen (io_in_bits_ctrlPipe_2_rfWen),
    .io_in_bits_validPipe_0 (io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1 (io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2 (io_in_bits_validPipe_2),
    .io_in_bits_data_src_1 (io_in_bits_data_src_1),
    .io_in_bits_data_src_0 (io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_eliminatedMove (io_in_bits_perfDebugInfo_eliminatedMove),
    .io_in_bits_perfDebugInfo_renameTime (io_in_bits_perfDebugInfo_renameTime),
    .io_in_bits_perfDebugInfo_dispatchTime (io_in_bits_perfDebugInfo_dispatchTime),
    .io_in_bits_perfDebugInfo_enqRsTime (io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (io_in_bits_perfDebugInfo_issueTime),
    .io_in_bits_perfDebugInfo_writebackTime (io_in_bits_perfDebugInfo_writebackTime),
    .io_in_bits_perfDebugInfo_runahead_checkpoint_id (io_in_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_in_bits_perfDebugInfo_tlbFirstReqTime (io_in_bits_perfDebugInfo_tlbFirstReqTime),
    .io_in_bits_perfDebugInfo_tlbRespTime (io_in_bits_perfDebugInfo_tlbRespTime),
    .io_in_bits_debug_seqNum_seqNum (io_in_bits_debug_seqNum_seqNum),
    .io_in_bits_debug_seqNum_uopIdx (io_in_bits_debug_seqNum_uopIdx),
    .io_out_ready (io_out_ready),
    .io_in_ready (i_io_in_ready),
    .io_out_valid (i_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (i_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (i_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (i_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (i_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data (i_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove (i_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime (i_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime (i_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime (i_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (i_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (i_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime (i_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id (i_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime (i_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime (i_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum (i_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx (i_io_out_bits_debug_seqNum_uopIdx)
  );

  // ---- 合法 opcode 表（7/8 的激励从这里取，1/8 全随机）----
  localparam int NOPS = 6;
  logic [8:0] op_tab[NOPS];
  initial begin
    op_tab[0] = 9'h000;  // mul
    op_tab[1] = 9'h001;  // mulh
    op_tab[2] = 9'h002;  // mulhsu
    op_tab[3] = 9'h003;  // mulhu
    op_tab[4] = 9'h004;  // mulw
    op_tab[5] = 9'h00c;  // mulw7
  end

  // ---- 复位：前 4 拍拉高（valid 链是本模块唯一带复位的寄存器）----
  initial begin
    reset = 1'b1;
    repeat (4) @(posedge clk);
    @(negedge clk) reset = 1'b0;
  end

  // ---- 激励 ----
  int stall_cnt = 0;
  always @(negedge clk) begin
    if (reset) begin
      io_in_valid <= 1'b0;
      io_out_ready <= 1'b1;
      io_in_bits_validPipe_0 <= 1'b0;
      io_in_bits_validPipe_1 <= 1'b0;
      io_in_bits_validPipe_2 <= 1'b0;
      io_in_bits_ctrl_fuOpType <= 9'h0;
    end else begin
      // valid 偏高（3/4），让流水填满，反压才有东西可压
      io_in_valid <= (($urandom % 4) != 0);
      // 上游预打拍的 validPipe：偏高（7/8），同时覆盖 regEnable 的与项
      io_in_bits_validPipe_0 <= (($urandom % 8) != 0);
      io_in_bits_validPipe_1 <= (($urandom % 8) != 0);
      io_in_bits_validPipe_2 <= (($urandom % 8) != 0);
      // opcode：7/8 取合法表，1/8 全随机 9bit
      if (($urandom % 8) != 0)
        io_in_bits_ctrl_fuOpType <= op_tab[$urandom % NOPS];
      else
        io_in_bits_ctrl_fuOpType <= 9'($urandom);
      // ★反压★：1/8 概率起一段 3~8 拍的 ready 拉低，其余拍随机
      if (stall_cnt > 0) begin
        io_out_ready <= 1'b0;
        stall_cnt = stall_cnt - 1;
      end else if (($urandom % 8) == 0) begin
        io_out_ready <= 1'b0;
        stall_cnt = 3 + ($urandom % 6);
      end else begin
        io_out_ready <= 1'($urandom);
      end
    end
    io_in_bits_ctrlPipe_2_robIdx_flag <= 1'($urandom);
    io_in_bits_ctrlPipe_2_robIdx_value <= 8'($urandom);
    io_in_bits_ctrlPipe_2_pdest <= 8'($urandom);
    io_in_bits_ctrlPipe_2_rfWen <= 1'($urandom);
    io_in_bits_data_src_1 <= 64'({$urandom(), $urandom()});
    io_in_bits_data_src_0 <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_eliminatedMove <= 1'($urandom);
    io_in_bits_perfDebugInfo_renameTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_dispatchTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_writebackTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_runahead_checkpoint_id <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbFirstReqTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_tlbRespTime <= 64'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_seqNum <= 56'({$urandom(), $urandom()});
    io_in_bits_debug_seqNum_uopIdx <= 8'($urandom);
  end

  // ---- 逐拍比对 + 反压/opcode 覆盖统计 ----
  logic [63:0] prev_res;
  logic        prev_rdy1;
  bit          sampled = 0;
  always @(negedge clk) begin
    #4;
    if (!reset) begin
      checks++;
      // 反压覆盖：golden 内部 rdyVec 链（wire，层次引用可见）
      if (u_g.rdyVec_1 === 1'b0) n_stall_s1++;
      if (u_g.rdyVec_0 === 1'b0) n_stall_s0++;
      // 内部反压链一致性：golden rdyVec_1 vs 重写核 rdy_s1
      if (u_g.rdyVec_1 !== u_i.u_core.rdy_s1) begin errors++;
        $display("[%0t] rdyVec_1 vs rdy_s1 mismatch: g=%b i=%b", $time,
                 u_g.rdyVec_1, u_i.u_core.rdy_s1); end
      // opcode 覆盖：只统计真正 fire 的拍（in_valid & in_ready）
      if (io_in_valid && g_io_in_ready)
        op_cov[io_in_bits_ctrl_fuOpType[5:0]]++;
      if (g_io_in_ready !== i_io_in_ready) begin errors++;
        $display("[%0t] io_in_ready mismatch: g=%h i=%h", $time, g_io_in_ready, i_io_in_ready); end
      if (g_io_out_valid !== i_io_out_valid) begin errors++;
        $display("[%0t] io_out_valid mismatch: g=%h i=%h", $time, g_io_out_valid, i_io_out_valid); end
      if (g_io_out_bits_ctrl_robIdx_flag !== i_io_out_bits_ctrl_robIdx_flag) begin errors++;
        $display("[%0t] io_out_bits_ctrl_robIdx_flag mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag); end
      if (g_io_out_bits_ctrl_robIdx_value !== i_io_out_bits_ctrl_robIdx_value) begin errors++;
        $display("[%0t] io_out_bits_ctrl_robIdx_value mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value); end
      if (g_io_out_bits_ctrl_pdest !== i_io_out_bits_ctrl_pdest) begin errors++;
        $display("[%0t] io_out_bits_ctrl_pdest mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest); end
      if (g_io_out_bits_ctrl_rfWen !== i_io_out_bits_ctrl_rfWen) begin errors++;
        $display("[%0t] io_out_bits_ctrl_rfWen mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_rfWen, i_io_out_bits_ctrl_rfWen); end
      if (g_io_out_bits_res_data !== i_io_out_bits_res_data) begin errors++;
        $display("[%0t] io_out_bits_res_data mismatch: g=%h i=%h", $time, g_io_out_bits_res_data, i_io_out_bits_res_data); end
      if (g_io_out_bits_perfDebugInfo_eliminatedMove !== i_io_out_bits_perfDebugInfo_eliminatedMove) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_eliminatedMove mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove); end
      if (g_io_out_bits_perfDebugInfo_renameTime !== i_io_out_bits_perfDebugInfo_renameTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_renameTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime); end
      if (g_io_out_bits_perfDebugInfo_dispatchTime !== i_io_out_bits_perfDebugInfo_dispatchTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_dispatchTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime); end
      if (g_io_out_bits_perfDebugInfo_enqRsTime !== i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_enqRsTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime); end
      if (g_io_out_bits_perfDebugInfo_selectTime !== i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_selectTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime); end
      if (g_io_out_bits_perfDebugInfo_issueTime !== i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_issueTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime); end
      if (g_io_out_bits_perfDebugInfo_writebackTime !== i_io_out_bits_perfDebugInfo_writebackTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_writebackTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime); end
      if (g_io_out_bits_perfDebugInfo_runahead_checkpoint_id !== i_io_out_bits_perfDebugInfo_runahead_checkpoint_id) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_runahead_checkpoint_id mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id); end
      if (g_io_out_bits_perfDebugInfo_tlbFirstReqTime !== i_io_out_bits_perfDebugInfo_tlbFirstReqTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_tlbFirstReqTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime); end
      if (g_io_out_bits_perfDebugInfo_tlbRespTime !== i_io_out_bits_perfDebugInfo_tlbRespTime) begin errors++;
        $display("[%0t] io_out_bits_perfDebugInfo_tlbRespTime mismatch: g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime); end
      if (g_io_out_bits_debug_seqNum_seqNum !== i_io_out_bits_debug_seqNum_seqNum) begin errors++;
        $display("[%0t] io_out_bits_debug_seqNum_seqNum mismatch: g=%h i=%h", $time, g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum); end
      if (g_io_out_bits_debug_seqNum_uopIdx !== i_io_out_bits_debug_seqNum_uopIdx) begin errors++;
        $display("[%0t] io_out_bits_debug_seqNum_uopIdx mismatch: g=%h i=%h", $time, g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx); end
      // ★反压保持检查★：上一拍 rdy_s1=0 ⇒ 第 2 级使能必为 0 ⇒ 这一拍
      // 输出数据必须原封不动（Bku 是输出寄存器保持，MulUnit 是阵列末级
      // 寄存器 + ctrl_s2 一起保持）。打到几次记进 hold_ok。
      if (sampled && (prev_rdy1 === 1'b0)) begin
        if (g_io_out_bits_res_data !== prev_res) begin errors++;
          $display("[%0t] stall 期间 res_data 被刷新: prev=%h now=%h", $time,
                   prev_res, g_io_out_bits_res_data); end
        else n_stall_hold++;
      end
      prev_rdy1 = u_g.rdyVec_1;
      prev_res  = g_io_out_bits_res_data;
      sampled   = 1'b1;
    end
  end

  int ncov;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 100000;
    repeat (NCYCLES + 8) @(posedge clk);
    ncov = 0;
    for (int k = 0; k < 64; k++) if (op_cov[k] > 0) ncov++;
    $display("checks=%0d errors=%0d", checks, errors);
    $display("coverage: distinct_fuOpType[5:0]=%0d  stall_s1=%0d stall_s0=%0d hold_ok=%0d",
             ncov, n_stall_s1, n_stall_s0, n_stall_hold);
    $display("  op_cov[mul]=%0d", op_cov[6'h00]);
    $display("  op_cov[mulh]=%0d", op_cov[6'h01]);
    $display("  op_cov[mulhsu]=%0d", op_cov[6'h02]);
    $display("  op_cov[mulhu]=%0d", op_cov[6'h03]);
    $display("  op_cov[mulw]=%0d", op_cov[6'h04]);
    $display("  op_cov[mulw7]=%0d", op_cov[6'h0c]);
    if (errors != 0) $display("TEST FAILED: %0d mismatches", errors);
    else if (checks <= 1000) $display("TEST FAILED: too few checks");
    else if (n_stall_s1 < 100 || n_stall_s0 < 100)
      $display("TEST FAILED: 反压场景没打到（stall_s1=%0d stall_s0=%0d）",
               n_stall_s1, n_stall_s0);
    else begin
      if (op_cov[6'h00] == 0 || op_cov[6'h01] == 0 || op_cov[6'h02] == 0 || op_cov[6'h03] == 0 || op_cov[6'h04] == 0 || op_cov[6'h0c] == 0)
        $display("TEST FAILED: 子块 opcode 覆盖不全");
      else $display("TEST PASSED");
    end
    $finish;
  end
endmodule
