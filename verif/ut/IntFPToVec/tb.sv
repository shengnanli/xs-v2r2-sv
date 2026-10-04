// =============================================================================
// tb —— IntFPToVec 双例化 UT（由 scripts/gen_exeunits_ut.py 生成，勿手改）
//   golden IntFPToVec vs 重写 IntFPToVec_xs；每拍比较全部 21 个输出口（!==）。
//   激励 / 覆盖 / 判据见生成器 TARGETS 里本目标一节。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARM = 2;
  localparam int RESET_ODDS = 20000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic io_in_bits_ctrl_robIdx_flag;
  logic [7:0] io_in_bits_ctrl_robIdx_value;
  logic [7:0] io_in_bits_ctrl_pdest;
  logic io_in_bits_ctrl_fpWen;
  logic io_in_bits_ctrl_vecWen;
  logic io_in_bits_ctrl_v0Wen;
  logic io_in_bits_validPipe_0;
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
  wire  g_io_in_ready, i_io_in_ready;
  wire  g_io_out_valid, i_io_out_valid;
  wire  g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag;
  wire  [7:0] g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value;
  wire  [7:0] g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest;
  wire  g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen;
  wire  g_io_out_bits_ctrl_vecWen, i_io_out_bits_ctrl_vecWen;
  wire  g_io_out_bits_ctrl_v0Wen, i_io_out_bits_ctrl_v0Wen;
  wire  [127:0] g_io_out_bits_res_data, i_io_out_bits_res_data;
  wire  g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove;
  wire  [63:0] g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id;
  wire  [63:0] g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime;
  wire  [63:0] g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime;
  wire  [55:0] g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum;
  wire  [7:0] g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx;

  longint c_fli_h = 0, c_fli_s = 0, c_fli_d = 0, c_dup_nan = 0, c_dup_ok = 0, c_fmv = 0, c_imm = 0, c_plain = 0;

  IntFPToVec u_g (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_fpWen(io_in_bits_ctrl_fpWen),
    .io_in_bits_ctrl_vecWen(io_in_bits_ctrl_vecWen),
    .io_in_bits_ctrl_v0Wen(io_in_bits_ctrl_v0Wen),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
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
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen(g_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_vecWen(g_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen(g_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data(g_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove(g_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(g_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(g_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(g_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(g_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx)
  );
  IntFPToVec_xs u_i (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_fpWen(io_in_bits_ctrl_fpWen),
    .io_in_bits_ctrl_vecWen(io_in_bits_ctrl_vecWen),
    .io_in_bits_ctrl_v0Wen(io_in_bits_ctrl_v0Wen),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
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
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen(i_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_vecWen(i_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen(i_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data(i_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_eliminatedMove(i_io_out_bits_perfDebugInfo_eliminatedMove),
    .io_out_bits_perfDebugInfo_renameTime(i_io_out_bits_perfDebugInfo_renameTime),
    .io_out_bits_perfDebugInfo_dispatchTime(i_io_out_bits_perfDebugInfo_dispatchTime),
    .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime),
    .io_out_bits_perfDebugInfo_writebackTime(i_io_out_bits_perfDebugInfo_writebackTime),
    .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_io_out_bits_perfDebugInfo_runahead_checkpoint_id),
    .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_io_out_bits_perfDebugInfo_tlbFirstReqTime),
    .io_out_bits_perfDebugInfo_tlbRespTime(i_io_out_bits_perfDebugInfo_tlbRespTime),
    .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum),
    .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx)
  );

  // 每拍激励：先全随机，再按目标语义覆盖
  task automatic drive();
    io_in_valid = 1'($urandom);
    io_in_bits_ctrl_fuOpType = 9'($urandom);
    io_in_bits_ctrl_robIdx_flag = 1'($urandom);
    io_in_bits_ctrl_robIdx_value = 8'($urandom);
    io_in_bits_ctrl_pdest = 8'($urandom);
    io_in_bits_ctrl_fpWen = 1'($urandom);
    io_in_bits_ctrl_vecWen = 1'($urandom);
    io_in_bits_ctrl_v0Wen = 1'($urandom);
    io_in_bits_validPipe_0 = 1'($urandom);
    io_in_bits_data_src_1 = 64'({$urandom(), $urandom()});
    io_in_bits_data_src_0 = 64'({$urandom(), $urandom()});
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

    // opType：40% fli（[7]=1，[6:5] 取 h/s/d 三种合法码 + 偶尔非法 11），60% 非 fli（[7:5]=0，
    //   [4:2] 走 IF2VectorType 的 6 个码，[1:0]=vsew 全取）；另 10% 全随机已由默认随机覆盖
    if ($urandom_range(0, 9) != 0) begin
      if ($urandom_range(0, 99) < 40) begin
        io_in_bits_ctrl_fuOpType[8:5] = {2'b01, 2'($urandom_range(0, 3))};
        if (io_in_bits_ctrl_fuOpType[6:5] == 2'b11 && $urandom_range(0, 3) != 0)
          io_in_bits_ctrl_fuOpType[6:5] = 2'b00;
      end else begin
        io_in_bits_ctrl_fuOpType[8:5] = 4'b0000;
        io_in_bits_ctrl_fuOpType[4:2] = 3'($urandom_range(0, 5)) + ((io_in_bits_ctrl_fuOpType[4] ? 3'd1 : 3'd0));
      end
    end
    // 浮点源：50% 给某一宽度的合法 NaN-box（高位全 1），其余随机（触发规范 NaN 替换）
    case ($urandom_range(0, 5))
      0: io_in_bits_data_src_0[63:8]  = '1;
      1: io_in_bits_data_src_0[63:16] = '1;
      2: io_in_bits_data_src_0[63:32] = '1;
      default: ;
    endcase

  endtask

  task automatic compare();
    checks++; if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_in_ready g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    checks++; if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_valid g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    checks++; if (g_io_out_bits_ctrl_robIdx_flag !== i_io_out_bits_ctrl_robIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_robIdx_flag g=%h i=%h", cyc, g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag); end
    checks++; if (g_io_out_bits_ctrl_robIdx_value !== i_io_out_bits_ctrl_robIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_robIdx_value g=%h i=%h", cyc, g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value); end
    checks++; if (g_io_out_bits_ctrl_pdest !== i_io_out_bits_ctrl_pdest) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_pdest g=%h i=%h", cyc, g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest); end
    checks++; if (g_io_out_bits_ctrl_fpWen !== i_io_out_bits_ctrl_fpWen) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_fpWen g=%h i=%h", cyc, g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen); end
    checks++; if (g_io_out_bits_ctrl_vecWen !== i_io_out_bits_ctrl_vecWen) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_vecWen g=%h i=%h", cyc, g_io_out_bits_ctrl_vecWen, i_io_out_bits_ctrl_vecWen); end
    checks++; if (g_io_out_bits_ctrl_v0Wen !== i_io_out_bits_ctrl_v0Wen) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_v0Wen g=%h i=%h", cyc, g_io_out_bits_ctrl_v0Wen, i_io_out_bits_ctrl_v0Wen); end
    checks++; if (g_io_out_bits_res_data !== i_io_out_bits_res_data) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_res_data g=%h i=%h", cyc, g_io_out_bits_res_data, i_io_out_bits_res_data); end
    checks++; if (g_io_out_bits_perfDebugInfo_eliminatedMove !== i_io_out_bits_perfDebugInfo_eliminatedMove) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_eliminatedMove g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_eliminatedMove, i_io_out_bits_perfDebugInfo_eliminatedMove); end
    checks++; if (g_io_out_bits_perfDebugInfo_renameTime !== i_io_out_bits_perfDebugInfo_renameTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_renameTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_renameTime, i_io_out_bits_perfDebugInfo_renameTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_dispatchTime !== i_io_out_bits_perfDebugInfo_dispatchTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_dispatchTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_dispatchTime, i_io_out_bits_perfDebugInfo_dispatchTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_enqRsTime !== i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_enqRsTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_selectTime !== i_io_out_bits_perfDebugInfo_selectTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_selectTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_issueTime !== i_io_out_bits_perfDebugInfo_issueTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_issueTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_writebackTime !== i_io_out_bits_perfDebugInfo_writebackTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_writebackTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_writebackTime, i_io_out_bits_perfDebugInfo_writebackTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_runahead_checkpoint_id !== i_io_out_bits_perfDebugInfo_runahead_checkpoint_id) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_runahead_checkpoint_id g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_runahead_checkpoint_id, i_io_out_bits_perfDebugInfo_runahead_checkpoint_id); end
    checks++; if (g_io_out_bits_perfDebugInfo_tlbFirstReqTime !== i_io_out_bits_perfDebugInfo_tlbFirstReqTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_tlbFirstReqTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_tlbFirstReqTime, i_io_out_bits_perfDebugInfo_tlbFirstReqTime); end
    checks++; if (g_io_out_bits_perfDebugInfo_tlbRespTime !== i_io_out_bits_perfDebugInfo_tlbRespTime) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_perfDebugInfo_tlbRespTime g=%h i=%h", cyc, g_io_out_bits_perfDebugInfo_tlbRespTime, i_io_out_bits_perfDebugInfo_tlbRespTime); end
    checks++; if (g_io_out_bits_debug_seqNum_seqNum !== i_io_out_bits_debug_seqNum_seqNum) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_seqNum g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_seqNum, i_io_out_bits_debug_seqNum_seqNum); end
    checks++; if (g_io_out_bits_debug_seqNum_uopIdx !== i_io_out_bits_debug_seqNum_uopIdx) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_debug_seqNum_uopIdx g=%h i=%h", cyc, g_io_out_bits_debug_seqNum_uopIdx, i_io_out_bits_debug_seqNum_uopIdx); end
  endtask

  task automatic sample_cov();

    begin
      logic [8:0] op;
      bit fli;
      op = io_in_bits_ctrl_fuOpType;
      fli = op[7] && op[6:5] != 2'b11;
      if (op[7] && op[6:5] == 2'b10) c_fli_h++;
      if (op[7] && op[6:5] == 2'b00) c_fli_s++;
      if (op[7] && op[6:5] == 2'b01) c_fli_d++;
      if (!fli && op[4] && op[2]) begin
        if (g_io_out_bits_res_data[7:0] == 8'h78 || g_io_out_bits_res_data[15:0] == 16'h7E00
            || g_io_out_bits_res_data[31:0] == 32'h7FC00000) c_dup_nan++; else c_dup_ok++;
      end
      if (!fli && !op[4] && op[2]) c_fmv++;
      if (!fli && op[3]) c_imm++;
      if (!fli && !op[4] && !op[2]) c_plain++;
    end

  endtask

  initial begin
    bit ok;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
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
    $display("cov fli h/s/d=%0d/%0d/%0d dup_nan=%0d dup_ok=%0d fmv=%0d imm=%0d plain=%0d", c_fli_h, c_fli_s, c_fli_d, c_dup_nan, c_dup_ok, c_fmv, c_imm, c_plain);
    ok = (errors == 0) && (checks > 1000);
    if (!(c_fli_h > 1000)) begin ok = 0; $display("cov LOW: c_fli_h > 1000"); end
    if (!(c_fli_s > 1000)) begin ok = 0; $display("cov LOW: c_fli_s > 1000"); end
    if (!(c_fli_d > 1000)) begin ok = 0; $display("cov LOW: c_fli_d > 1000"); end
    if (!(c_dup_nan > 1000)) begin ok = 0; $display("cov LOW: c_dup_nan > 1000"); end
    if (!(c_dup_ok > 1000)) begin ok = 0; $display("cov LOW: c_dup_ok > 1000"); end
    if (!(c_fmv > 1000)) begin ok = 0; $display("cov LOW: c_fmv > 1000"); end
    if (!(c_imm > 1000)) begin ok = 0; $display("cov LOW: c_imm > 1000"); end
    if (!(c_plain > 1000)) begin ok = 0; $display("cov LOW: c_plain > 1000"); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
