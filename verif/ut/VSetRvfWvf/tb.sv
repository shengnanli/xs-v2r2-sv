// VSetRvfWvf UT：golden 与重写 VSetRvfWvf_xs 双例化随机比对（G1 端口）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 20000;
  bit clk = 0; int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic io_in_bits_ctrl_robIdx_flag;
  logic [7:0] io_in_bits_ctrl_robIdx_value;
  logic [7:0] io_in_bits_ctrl_pdest;
  logic io_in_bits_ctrl_rfWen;
  logic io_in_bits_ctrl_vlWen;
  logic [7:0] io_in_bits_data_src_4;
  logic [127:0] io_in_bits_data_src_1;
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
  wire g_io_out_bits_ctrl_vlWen, i_io_out_bits_ctrl_vlWen;
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
  wire g_io_vtype_valid, i_io_vtype_valid;
  wire g_io_vtype_bits_illegal, i_io_vtype_bits_illegal;
  wire g_io_vtype_bits_vma, i_io_vtype_bits_vma;
  wire g_io_vtype_bits_vta, i_io_vtype_bits_vta;
  wire [1:0] g_io_vtype_bits_vsew, i_io_vtype_bits_vsew;
  wire [2:0] g_io_vtype_bits_vlmul, i_io_vtype_bits_vlmul;
  wire g_io_vlIsZero, i_io_vlIsZero;
  wire g_io_vlIsVlmax, i_io_vlIsVlmax;

  VSetRvfWvf u_g (.io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag), .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value), .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest), .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen), .io_in_bits_ctrl_vlWen(io_in_bits_ctrl_vlWen), .io_in_bits_data_src_4(io_in_bits_data_src_4), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove), .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime), .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime), .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id), .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime), .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime), .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum), .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx), .io_out_ready(io_out_ready), .io_in_ready(g_io_in_ready), .io_out_valid(g_io_out_valid), .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(g_io_out_bits_ctrl_rfWen), .io_out_bits_ctrl_vlWen(g_io_out_bits_ctrl_vlWen), .io_out_bits_res_data(g_io_out_bits_res_data), .io_out_bits_perfDebugInfo_eliminatedMove(g_io_out_bits_perfDebugInfo_eliminatedMove), .io_out_bits_perfDebugInfo_renameTime(g_io_out_bits_perfDebugInfo_renameTime), .io_out_bits_perfDebugInfo_dispatchTime(g_io_out_bits_perfDebugInfo_dispatchTime), .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime), .io_out_bits_perfDebugInfo_writebackTime(g_io_out_bits_perfDebugInfo_writebackTime), .io_out_bits_perfDebugInfo_runahead_checkpoint_id(g_io_out_bits_perfDebugInfo_runahead_checkpoint_id), .io_out_bits_perfDebugInfo_tlbFirstReqTime(g_io_out_bits_perfDebugInfo_tlbFirstReqTime), .io_out_bits_perfDebugInfo_tlbRespTime(g_io_out_bits_perfDebugInfo_tlbRespTime), .io_out_bits_debug_seqNum_seqNum(g_io_out_bits_debug_seqNum_seqNum), .io_out_bits_debug_seqNum_uopIdx(g_io_out_bits_debug_seqNum_uopIdx), .io_vtype_valid(g_io_vtype_valid), .io_vtype_bits_illegal(g_io_vtype_bits_illegal), .io_vtype_bits_vma(g_io_vtype_bits_vma), .io_vtype_bits_vta(g_io_vtype_bits_vta), .io_vtype_bits_vsew(g_io_vtype_bits_vsew), .io_vtype_bits_vlmul(g_io_vtype_bits_vlmul), .io_vlIsZero(g_io_vlIsZero), .io_vlIsVlmax(g_io_vlIsVlmax));
  VSetRvfWvf_xs u_i (.io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag), .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value), .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest), .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen), .io_in_bits_ctrl_vlWen(io_in_bits_ctrl_vlWen), .io_in_bits_data_src_4(io_in_bits_data_src_4), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_perfDebugInfo_eliminatedMove(io_in_bits_perfDebugInfo_eliminatedMove), .io_in_bits_perfDebugInfo_renameTime(io_in_bits_perfDebugInfo_renameTime), .io_in_bits_perfDebugInfo_dispatchTime(io_in_bits_perfDebugInfo_dispatchTime), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_in_bits_perfDebugInfo_writebackTime(io_in_bits_perfDebugInfo_writebackTime), .io_in_bits_perfDebugInfo_runahead_checkpoint_id(io_in_bits_perfDebugInfo_runahead_checkpoint_id), .io_in_bits_perfDebugInfo_tlbFirstReqTime(io_in_bits_perfDebugInfo_tlbFirstReqTime), .io_in_bits_perfDebugInfo_tlbRespTime(io_in_bits_perfDebugInfo_tlbRespTime), .io_in_bits_debug_seqNum_seqNum(io_in_bits_debug_seqNum_seqNum), .io_in_bits_debug_seqNum_uopIdx(io_in_bits_debug_seqNum_uopIdx), .io_out_ready(io_out_ready), .io_in_ready(i_io_in_ready), .io_out_valid(i_io_out_valid), .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(i_io_out_bits_ctrl_rfWen), .io_out_bits_ctrl_vlWen(i_io_out_bits_ctrl_vlWen), .io_out_bits_res_data(i_io_out_bits_res_data), .io_out_bits_perfDebugInfo_eliminatedMove(i_io_out_bits_perfDebugInfo_eliminatedMove), .io_out_bits_perfDebugInfo_renameTime(i_io_out_bits_perfDebugInfo_renameTime), .io_out_bits_perfDebugInfo_dispatchTime(i_io_out_bits_perfDebugInfo_dispatchTime), .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime), .io_out_bits_perfDebugInfo_writebackTime(i_io_out_bits_perfDebugInfo_writebackTime), .io_out_bits_perfDebugInfo_runahead_checkpoint_id(i_io_out_bits_perfDebugInfo_runahead_checkpoint_id), .io_out_bits_perfDebugInfo_tlbFirstReqTime(i_io_out_bits_perfDebugInfo_tlbFirstReqTime), .io_out_bits_perfDebugInfo_tlbRespTime(i_io_out_bits_perfDebugInfo_tlbRespTime), .io_out_bits_debug_seqNum_seqNum(i_io_out_bits_debug_seqNum_seqNum), .io_out_bits_debug_seqNum_uopIdx(i_io_out_bits_debug_seqNum_uopIdx), .io_vtype_valid(i_io_vtype_valid), .io_vtype_bits_illegal(i_io_vtype_bits_illegal), .io_vtype_bits_vma(i_io_vtype_bits_vma), .io_vtype_bits_vta(i_io_vtype_bits_vta), .io_vtype_bits_vsew(i_io_vtype_bits_vsew), .io_vtype_bits_vlmul(i_io_vtype_bits_vlmul), .io_vlIsZero(i_io_vlIsZero), .io_vlIsVlmax(i_io_vlIsVlmax));

  always @(negedge clk) begin
    io_in_valid <= 1'($urandom);
    io_in_bits_ctrl_fuOpType <= 9'($urandom);
    io_in_bits_ctrl_robIdx_flag <= 1'($urandom);
    io_in_bits_ctrl_robIdx_value <= 8'($urandom);
    io_in_bits_ctrl_pdest <= 8'($urandom);
    io_in_bits_ctrl_rfWen <= 1'($urandom);
    io_in_bits_ctrl_vlWen <= 1'($urandom);
    io_in_bits_data_src_4 <= 8'($urandom);
    io_in_bits_data_src_1 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
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
    io_out_ready <= 1'($urandom);
  end
  always @(negedge clk) begin
    #4; checks++;
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
    if (g_io_out_bits_ctrl_vlWen !== i_io_out_bits_ctrl_vlWen) begin errors++;
      $display("[%0t] io_out_bits_ctrl_vlWen mismatch: g=%h i=%h", $time, g_io_out_bits_ctrl_vlWen, i_io_out_bits_ctrl_vlWen); end
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
    if (g_io_vtype_valid !== i_io_vtype_valid) begin errors++;
      $display("[%0t] io_vtype_valid mismatch: g=%h i=%h", $time, g_io_vtype_valid, i_io_vtype_valid); end
    if (g_io_vtype_bits_illegal !== i_io_vtype_bits_illegal) begin errors++;
      $display("[%0t] io_vtype_bits_illegal mismatch: g=%h i=%h", $time, g_io_vtype_bits_illegal, i_io_vtype_bits_illegal); end
    if (g_io_vtype_bits_vma !== i_io_vtype_bits_vma) begin errors++;
      $display("[%0t] io_vtype_bits_vma mismatch: g=%h i=%h", $time, g_io_vtype_bits_vma, i_io_vtype_bits_vma); end
    if (g_io_vtype_bits_vta !== i_io_vtype_bits_vta) begin errors++;
      $display("[%0t] io_vtype_bits_vta mismatch: g=%h i=%h", $time, g_io_vtype_bits_vta, i_io_vtype_bits_vta); end
    if (g_io_vtype_bits_vsew !== i_io_vtype_bits_vsew) begin errors++;
      $display("[%0t] io_vtype_bits_vsew mismatch: g=%h i=%h", $time, g_io_vtype_bits_vsew, i_io_vtype_bits_vsew); end
    if (g_io_vtype_bits_vlmul !== i_io_vtype_bits_vlmul) begin errors++;
      $display("[%0t] io_vtype_bits_vlmul mismatch: g=%h i=%h", $time, g_io_vtype_bits_vlmul, i_io_vtype_bits_vlmul); end
    if (g_io_vlIsZero !== i_io_vlIsZero) begin errors++;
      $display("[%0t] io_vlIsZero mismatch: g=%h i=%h", $time, g_io_vlIsZero, i_io_vlIsZero); end
    if (g_io_vlIsVlmax !== i_io_vlIsVlmax) begin errors++;
      $display("[%0t] io_vlIsVlmax mismatch: g=%h i=%h", $time, g_io_vlIsVlmax, i_io_vlIsVlmax); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 20000;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
