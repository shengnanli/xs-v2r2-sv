// =============================================================================
// tb —— VSetRiWvf 双例化 UT（由 scripts/gen_exeunits_ut.py 生成，勿手改）
//   golden VSetRiWvf vs 重写 VSetRiWvf_xs；每拍比较全部 27 个输出口（!==）。
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
  logic io_in_bits_ctrl_vlWen;
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
  wire  g_io_out_bits_ctrl_vlWen, i_io_out_bits_ctrl_vlWen;
  wire  [63:0] g_io_out_bits_res_data, i_io_out_bits_res_data;
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
  wire  g_io_vtype_valid, i_io_vtype_valid;
  wire  g_io_vtype_bits_illegal, i_io_vtype_bits_illegal;
  wire  g_io_vtype_bits_vma, i_io_vtype_bits_vma;
  wire  g_io_vtype_bits_vta, i_io_vtype_bits_vta;
  wire  [1:0] g_io_vtype_bits_vsew, i_io_vtype_bits_vsew;
  wire  [2:0] g_io_vtype_bits_vlmul, i_io_vtype_bits_vlmul;
  wire  g_io_vlIsZero, i_io_vlIsZero;
  wire  g_io_vlIsVlmax, i_io_vlIsVlmax;

  // 覆盖计数
  longint c_vl0 = 0, c_vlmax = 0, c_vtype_wr = 0, c_illegal = 0, c_legal = 0, c_avl_mid = 0;
  logic [8:0] vset_pool [8] = '{9'h0A0, 9'h0A1, 9'h060, 9'h061, 9'h020, 9'h062, 9'h0A2, 9'h072};

  VSetRiWvf u_g (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_vlWen(io_in_bits_ctrl_vlWen),
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
    .io_out_bits_ctrl_vlWen(g_io_out_bits_ctrl_vlWen),
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
    .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx),
    .io_vtype_valid(g_io_vtype_valid),
    .io_vtype_bits_illegal(g_io_vtype_bits_illegal),
    .io_vtype_bits_vma(g_io_vtype_bits_vma),
    .io_vtype_bits_vta(g_io_vtype_bits_vta),
    .io_vtype_bits_vsew(g_io_vtype_bits_vsew),
    .io_vtype_bits_vlmul(g_io_vtype_bits_vlmul),
    .io_vlIsZero(g_io_vlIsZero),
    .io_vlIsVlmax(g_io_vlIsVlmax)
  );
  VSetRiWvf_xs u_i (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_vlWen(io_in_bits_ctrl_vlWen),
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
    .io_out_bits_ctrl_vlWen(i_io_out_bits_ctrl_vlWen),
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
    .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx),
    .io_vtype_valid(i_io_vtype_valid),
    .io_vtype_bits_illegal(i_io_vtype_bits_illegal),
    .io_vtype_bits_vma(i_io_vtype_bits_vma),
    .io_vtype_bits_vta(i_io_vtype_bits_vta),
    .io_vtype_bits_vsew(i_io_vtype_bits_vsew),
    .io_vtype_bits_vlmul(i_io_vtype_bits_vlmul),
    .io_vlIsZero(i_io_vlIsZero),
    .io_vlIsVlmax(i_io_vlIsVlmax)
  );

  // 每拍激励：先全随机，再按目标语义覆盖
  task automatic drive();
    io_in_valid = 1'($urandom);
    io_in_bits_ctrl_fuOpType = 9'($urandom);
    io_in_bits_ctrl_robIdx_flag = 1'($urandom);
    io_in_bits_ctrl_robIdx_value = 8'($urandom);
    io_in_bits_ctrl_pdest = 8'($urandom);
    io_in_bits_ctrl_vlWen = 1'($urandom);
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

    // fuOpType：85% 取本 FU 真会收到的 vset uop 编码（含两个不归它管的 keep 码），15% 全随机
    if ($urandom_range(0, 99) < 85) io_in_bits_ctrl_fuOpType = vset_pool[$urandom_range(0, 7)];
    // src1 低 11 位是 vtype 立即数 / VtypeStruct：70% 给合法 vsew(0..3) 与 vlmul(!=4)、reserved=0
    if ($urandom_range(0, 99) < 70) begin
      io_in_bits_data_src_1[5:3] = 3'($urandom_range(0, 3));
      io_in_bits_data_src_1[2:0] = 3'($urandom_range(0, 7));
      if (io_in_bits_data_src_1[2:0] == 3'b100) io_in_bits_data_src_1[2:0] = 3'b000;
      io_in_bits_data_src_1[63:8] = {41'h0, 5'($urandom), 10'h0};   // 只留 uimm5 [14:10]
      if ($urandom_range(0, 9) == 0) io_in_bits_data_src_1[63] = 1'b1; // vill
    end
    // AVL（src0）：60% 落在 0..40（覆盖 vl<VLMAX / =VLMAX / >VLMAX 三种）
    if ($urandom_range(0, 99) < 60) io_in_bits_data_src_0 = 64'($urandom_range(0, 40));

  endtask

  task automatic compare();
    checks++; if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_in_ready g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    checks++; if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_valid g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    checks++; if (g_io_out_bits_ctrl_robIdx_flag !== i_io_out_bits_ctrl_robIdx_flag) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_robIdx_flag g=%h i=%h", cyc, g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag); end
    checks++; if (g_io_out_bits_ctrl_robIdx_value !== i_io_out_bits_ctrl_robIdx_value) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_robIdx_value g=%h i=%h", cyc, g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value); end
    checks++; if (g_io_out_bits_ctrl_pdest !== i_io_out_bits_ctrl_pdest) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_pdest g=%h i=%h", cyc, g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest); end
    checks++; if (g_io_out_bits_ctrl_vlWen !== i_io_out_bits_ctrl_vlWen) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_out_bits_ctrl_vlWen g=%h i=%h", cyc, g_io_out_bits_ctrl_vlWen, i_io_out_bits_ctrl_vlWen); end
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
    checks++; if (g_io_vtype_valid !== i_io_vtype_valid) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vtype_valid g=%h i=%h", cyc, g_io_vtype_valid, i_io_vtype_valid); end
    checks++; if (g_io_vtype_bits_illegal !== i_io_vtype_bits_illegal) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vtype_bits_illegal g=%h i=%h", cyc, g_io_vtype_bits_illegal, i_io_vtype_bits_illegal); end
    checks++; if (g_io_vtype_bits_vma !== i_io_vtype_bits_vma) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vtype_bits_vma g=%h i=%h", cyc, g_io_vtype_bits_vma, i_io_vtype_bits_vma); end
    checks++; if (g_io_vtype_bits_vta !== i_io_vtype_bits_vta) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vtype_bits_vta g=%h i=%h", cyc, g_io_vtype_bits_vta, i_io_vtype_bits_vta); end
    checks++; if (g_io_vtype_bits_vsew !== i_io_vtype_bits_vsew) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vtype_bits_vsew g=%h i=%h", cyc, g_io_vtype_bits_vsew, i_io_vtype_bits_vsew); end
    checks++; if (g_io_vtype_bits_vlmul !== i_io_vtype_bits_vlmul) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vtype_bits_vlmul g=%h i=%h", cyc, g_io_vtype_bits_vlmul, i_io_vtype_bits_vlmul); end
    checks++; if (g_io_vlIsZero !== i_io_vlIsZero) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vlIsZero g=%h i=%h", cyc, g_io_vlIsZero, i_io_vlIsZero); end
    checks++; if (g_io_vlIsVlmax !== i_io_vlIsVlmax) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_vlIsVlmax g=%h i=%h", cyc, g_io_vlIsVlmax, i_io_vlIsVlmax); end
  endtask

  task automatic sample_cov();

    if (io_in_valid) begin
      if (g_io_vlIsZero) c_vl0++;
      if (g_io_vlIsVlmax) c_vlmax++;
      if (g_io_vtype_valid) c_vtype_wr++;
      if (g_io_vtype_bits_illegal) c_illegal++; else c_legal++;
      if (!g_io_vlIsZero && !g_io_vlIsVlmax) c_avl_mid++;
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
    $display("cov vl0=%0d vlmax=%0d vtype_wr=%0d illegal=%0d legal=%0d avl_mid=%0d", c_vl0, c_vlmax, c_vtype_wr, c_illegal, c_legal, c_avl_mid);
    ok = (errors == 0) && (checks > 1000);
    if (!(c_vl0 > 1000)) begin ok = 0; $display("cov LOW: c_vl0 > 1000"); end
    if (!(c_vlmax > 1000)) begin ok = 0; $display("cov LOW: c_vlmax > 1000"); end
    if (!(c_vtype_wr > 1000)) begin ok = 0; $display("cov LOW: c_vtype_wr > 1000"); end
    if (!(c_illegal > 1000)) begin ok = 0; $display("cov LOW: c_illegal > 1000"); end
    if (!(c_legal > 1000)) begin ok = 0; $display("cov LOW: c_legal > 1000"); end
    if (!(c_avl_mid > 1000)) begin ok = 0; $display("cov LOW: c_avl_mid > 1000"); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
