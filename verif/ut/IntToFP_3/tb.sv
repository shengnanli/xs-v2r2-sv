// =============================================================================
// tb —— IntToFP_3 UT: golden IntToFP_3 (u_g) vs 可读核 IntToFP_3_xs (u_i) 逐拍比对。
// IntToFP_3 = 整数->浮点转换单元 3 级流水外壳。两 DUT 同延迟, 每拍同激励 => 每拍
// 逐输出比对。激励覆盖: typeTagOut(H/S/D 三 tag)/wflags/typ(符号/长度)/rm(舍入模式,
// 含 rm==3'b111 走 io_frm) + 各类边界整数值 + validPipe/ctrlPipe 随机门控。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst = 1;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // ---- DUT 输入 ----
  logic        io_in_valid;
  logic [1:0]  io_in_bits_ctrl_fpu_typeTagOut;
  logic        io_in_bits_ctrl_fpu_wflags;
  logic [1:0]  io_in_bits_ctrl_fpu_typ;
  logic [2:0]  io_in_bits_ctrl_fpu_rm;
  logic        io_in_bits_ctrlPipe_2_robIdx_flag;
  logic [7:0]  io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0]  io_in_bits_ctrlPipe_2_pdest;
  logic        io_in_bits_ctrlPipe_2_fpWen;
  logic        io_in_bits_ctrlPipe_2_fpu_wflags;
  logic        io_in_bits_validPipe_0;
  logic        io_in_bits_validPipe_1;
  logic        io_in_bits_validPipe_2;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic [2:0]  io_frm;

  // ---- golden 输出 ----
  logic        g_out_valid, g_ctrl_robIdx_flag, g_ctrl_fpWen, g_ctrl_fpu_wflags;
  logic [7:0]  g_ctrl_robIdx_value, g_ctrl_pdest;
  logic [63:0] g_res_data;
  logic [4:0]  g_res_fflags;
  logic [63:0] g_perf_enqRsTime, g_perf_selectTime, g_perf_issueTime;
  // ---- impl 输出 ----
  logic        i_out_valid, i_ctrl_robIdx_flag, i_ctrl_fpWen, i_ctrl_fpu_wflags;
  logic [7:0]  i_ctrl_robIdx_value, i_ctrl_pdest;
  logic [63:0] i_res_data;
  logic [4:0]  i_res_fflags;
  logic [63:0] i_perf_enqRsTime, i_perf_selectTime, i_perf_issueTime;

  IntToFP_3 u_g (
    .clock(clk), .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fpu_typeTagOut(io_in_bits_ctrl_fpu_typeTagOut),
    .io_in_bits_ctrl_fpu_wflags(io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_fpu_typ(io_in_bits_ctrl_fpu_typ),
    .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_fpWen(io_in_bits_ctrlPipe_2_fpWen),
    .io_in_bits_ctrlPipe_2_fpu_wflags(io_in_bits_ctrlPipe_2_fpu_wflags),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(g_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(g_ctrl_pdest),
    .io_out_bits_ctrl_fpWen(g_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags(g_ctrl_fpu_wflags),
    .io_out_bits_res_data(g_res_data),
    .io_out_bits_res_fflags(g_res_fflags),
    .io_out_bits_perfDebugInfo_enqRsTime(g_perf_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_perf_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_perf_issueTime),
    .io_frm(io_frm)
  );

  IntToFP_3_xs u_i (
    .clock(clk), .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fpu_typeTagOut(io_in_bits_ctrl_fpu_typeTagOut),
    .io_in_bits_ctrl_fpu_wflags(io_in_bits_ctrl_fpu_wflags),
    .io_in_bits_ctrl_fpu_typ(io_in_bits_ctrl_fpu_typ),
    .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_fpWen(io_in_bits_ctrlPipe_2_fpWen),
    .io_in_bits_ctrlPipe_2_fpu_wflags(io_in_bits_ctrlPipe_2_fpu_wflags),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(i_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(i_ctrl_pdest),
    .io_out_bits_ctrl_fpWen(i_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags(i_ctrl_fpu_wflags),
    .io_out_bits_res_data(i_res_data),
    .io_out_bits_res_fflags(i_res_fflags),
    .io_out_bits_perfDebugInfo_enqRsTime(i_perf_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_perf_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_perf_issueTime),
    .io_frm(io_frm)
  );

  // 64bit 随机整数(混合边界值)
  function automatic logic [63:0] rand64();
    int unsigned sel = $urandom_range(0, 9);
    case (sel)
      0: return 64'h0;
      1: return '1;
      2: return 64'h8000_0000_0000_0000;
      3: return 64'h0000_0000_8000_0000;
      4: return {32'h0, $urandom};
      5: return $urandom_range(0, 63);
      default: return {$urandom, $urandom};
    endcase
  endfunction

  task automatic drive_inputs();
    io_in_valid                        = $urandom;
    io_in_bits_ctrl_fpu_typeTagOut     = $urandom_range(0, 2);      // H(2)/S(0)/D(1) tag
    io_in_bits_ctrl_fpu_wflags         = $urandom;
    io_in_bits_ctrl_fpu_typ            = $urandom_range(0, 3);      // 符号/长度
    io_in_bits_ctrl_fpu_rm             = ($urandom_range(0,4)==0) ? 3'b111 : $urandom_range(0,7);
    io_in_bits_ctrlPipe_2_robIdx_flag  = $urandom;
    io_in_bits_ctrlPipe_2_robIdx_value = $urandom;
    io_in_bits_ctrlPipe_2_pdest        = $urandom;
    io_in_bits_ctrlPipe_2_fpWen        = $urandom;
    io_in_bits_ctrlPipe_2_fpu_wflags   = $urandom;
    io_in_bits_validPipe_0             = $urandom;
    io_in_bits_validPipe_1             = $urandom;
    io_in_bits_validPipe_2             = $urandom;
    io_in_bits_data_src_0              = rand64();
    io_in_bits_perfDebugInfo_enqRsTime  = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_selectTime = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_issueTime  = {$urandom,$urandom};
    io_frm                             = $urandom_range(0,7);
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h", $time, nm, g, i); end \
    checks++;

  task automatic check_outputs();
    `CK(g_out_valid,        i_out_valid,        "out_valid")
    `CK(g_ctrl_robIdx_flag, i_ctrl_robIdx_flag, "robIdx_flag")
    `CK(g_ctrl_robIdx_value,i_ctrl_robIdx_value,"robIdx_value")
    `CK(g_ctrl_pdest,       i_ctrl_pdest,       "pdest")
    `CK(g_ctrl_fpWen,       i_ctrl_fpWen,       "fpWen")
    `CK(g_ctrl_fpu_wflags,  i_ctrl_fpu_wflags,  "fpu_wflags")
    `CK(g_res_data,         i_res_data,         "res_data")
    `CK(g_res_fflags,       i_res_fflags,       "res_fflags")
    `CK(g_perf_enqRsTime,   i_perf_enqRsTime,   "enqRsTime")
    `CK(g_perf_selectTime,  i_perf_selectTime,  "selectTime")
    `CK(g_perf_issueTime,   i_perf_issueTime,   "issueTime")
  endtask

  initial begin
    io_in_valid = 0; io_in_bits_validPipe_0 = 0; io_in_bits_validPipe_1 = 0;
    io_in_bits_validPipe_2 = 0;
    io_in_bits_ctrl_fpu_typeTagOut = 0; io_in_bits_ctrl_fpu_wflags = 0;
    io_in_bits_ctrl_fpu_typ = 0; io_in_bits_ctrl_fpu_rm = 0;
    io_in_bits_ctrlPipe_2_robIdx_flag = 0; io_in_bits_ctrlPipe_2_robIdx_value = 0;
    io_in_bits_ctrlPipe_2_pdest = 0; io_in_bits_ctrlPipe_2_fpWen = 0;
    io_in_bits_ctrlPipe_2_fpu_wflags = 0; io_in_bits_data_src_0 = 0;
    io_in_bits_perfDebugInfo_enqRsTime = 0; io_in_bits_perfDebugInfo_selectTime = 0;
    io_in_bits_perfDebugInfo_issueTime = 0; io_frm = 0;
    repeat (4) @(posedge clk);
    #1 rst = 0;
    drive_inputs();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check_outputs();   // 稳定后比对
      drive_inputs();       // 下一拍激励
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
