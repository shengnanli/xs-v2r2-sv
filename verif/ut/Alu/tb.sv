// =============================================================================
// tb —— Alu UT:golden Alu (u_g) vs 可读核 Alu_xs (u_i) 逐拍逐输出比对。
// ALU 为纯组合单周期:每拍随机驱动 src0/src1/fuOpType,下一拍沿比较所有输出。
// 激励策略:多数拍从全部合法 fuOpType 表里取(保证每类运算/变体覆盖),
//   少数拍取完全随机 func(覆盖未定义码,golden 输出非 X 时仍须等价);
//   操作数混合全随机与边界值(0/全1/符号边界/小移位量)。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  // 合法 ALU fuOpType(与 alu_pkg/ALUOpType 一致),用于定向覆盖。
  localparam int NOP = 74;
  logic [8:0] OPS [NOP] = '{
    9'h00,9'h01,9'h02,9'h03,9'h04,9'h05,9'h06,9'h07,9'h09,9'h0b, // shift
    9'h10,9'h11,9'h12,9'h13,9'h14,9'h15,9'h16,9'h17,9'h18,9'h19,9'h1a,9'h1c,9'h1d, // word
    9'h20,9'h21,9'h22,9'h23,9'h24,9'h25,9'h26,9'h27,9'h28,9'h29,9'h2a,9'h2b,9'h2c,9'h2d,9'h2f, // add
    9'h30,9'h31,9'h32,9'h34,9'h35,9'h36,9'h37, // compare
    9'h74,9'h76, // zicond
    9'h40,9'h41,9'h42,9'h43,9'h44,9'h45,9'h46,9'h48,9'h49,9'h4a,9'h4b, // misc 100x
    9'h50,9'h51,9'h52,9'h53,9'h58,9'h59,9'h5a,9'h5b, // misc 101x rev/pack/orh48/szewl/byte2
    9'h60,9'h61,9'h62,9'h63,9'h64,9'h65,9'h66,9'h67  // misc 110x lsb/zexth
  };

  // DUT 输入
  logic        io_in_valid;
  logic [8:0]  io_in_bits_ctrl_fuOpType;
  logic        io_in_bits_ctrlPipe_0_robIdx_flag;
  logic [7:0]  io_in_bits_ctrlPipe_0_robIdx_value;
  logic [7:0]  io_in_bits_ctrlPipe_0_pdest;
  logic        io_in_bits_ctrlPipe_0_rfWen;
  logic [63:0] io_in_bits_data_src_1;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;

  // golden 输出
  logic        g_io_out_valid, g_io_out_bits_ctrl_robIdx_flag, g_io_out_bits_ctrl_rfWen;
  logic [7:0]  g_io_out_bits_ctrl_robIdx_value, g_io_out_bits_ctrl_pdest;
  logic [63:0] g_io_out_bits_res_data;
  logic [63:0] g_io_out_bits_perfDebugInfo_enqRsTime, g_io_out_bits_perfDebugInfo_selectTime, g_io_out_bits_perfDebugInfo_issueTime;
  // impl 输出
  logic        i_io_out_valid, i_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_rfWen;
  logic [7:0]  i_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_pdest;
  logic [63:0] i_io_out_bits_res_data;
  logic [63:0] i_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_issueTime;

  Alu u_g (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrlPipe_0_robIdx_flag(io_in_bits_ctrlPipe_0_robIdx_flag),
    .io_in_bits_ctrlPipe_0_robIdx_value(io_in_bits_ctrlPipe_0_robIdx_value),
    .io_in_bits_ctrlPipe_0_pdest(io_in_bits_ctrlPipe_0_pdest),
    .io_in_bits_ctrlPipe_0_rfWen(io_in_bits_ctrlPipe_0_rfWen),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen(g_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data(g_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime)
  );

  Alu_xs u_i (
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrlPipe_0_robIdx_flag(io_in_bits_ctrlPipe_0_robIdx_flag),
    .io_in_bits_ctrlPipe_0_robIdx_value(io_in_bits_ctrlPipe_0_robIdx_value),
    .io_in_bits_ctrlPipe_0_pdest(io_in_bits_ctrlPipe_0_pdest),
    .io_in_bits_ctrlPipe_0_rfWen(io_in_bits_ctrlPipe_0_rfWen),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen(i_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data(i_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime)
  );

  // 64bit 随机数(混合边界值)
  function automatic logic [63:0] rand64();
    int unsigned sel = $urandom_range(0, 9);
    case (sel)
      0: return 64'h0;
      1: return '1;
      2: return 64'h8000_0000_0000_0000;
      3: return 64'h0000_0000_8000_0000;
      4: return {32'h0, $urandom};                 // 仅低 32 位
      5: return $urandom_range(0, 63);             // 小值(移位量友好)
      default: return {$urandom, $urandom};        // 全随机
    endcase
  endfunction

  task automatic drive_inputs();
    int unsigned pick = $urandom_range(0, 99);
    if (pick < 90)
      io_in_bits_ctrl_fuOpType = OPS[$urandom_range(0, NOP-1)]; // 定向覆盖
    else
      io_in_bits_ctrl_fuOpType = {2'b00, $urandom_range(0, 127)}; // 随机 func
    io_in_valid                        = $urandom;
    io_in_bits_ctrlPipe_0_robIdx_flag  = $urandom;
    io_in_bits_ctrlPipe_0_robIdx_value = $urandom;
    io_in_bits_ctrlPipe_0_pdest        = $urandom;
    io_in_bits_ctrlPipe_0_rfWen        = $urandom;
    io_in_bits_data_src_0              = rand64();
    io_in_bits_data_src_1              = rand64();
    io_in_bits_perfDebugInfo_enqRsTime  = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_selectTime = {$urandom,$urandom};
    io_in_bits_perfDebugInfo_issueTime  = {$urandom,$urandom};
  endtask

  `define CK(g,i,nm) \
    if (!$isunknown(g) && (g) !== (i)) begin errors++; \
      if (errors<=60) $display("[%0t] %s g=%h i=%h (func=%h s0=%h s1=%h)", $time, nm, g, i, \
        io_in_bits_ctrl_fuOpType, io_in_bits_data_src_0, io_in_bits_data_src_1); end \
    checks++;

  task automatic check_outputs();
    `CK(g_io_out_bits_res_data,                i_io_out_bits_res_data,                "res_data")
    `CK(g_io_out_valid,                        i_io_out_valid,                        "out_valid")
    `CK(g_io_out_bits_ctrl_robIdx_flag,        i_io_out_bits_ctrl_robIdx_flag,        "robIdx_flag")
    `CK(g_io_out_bits_ctrl_robIdx_value,       i_io_out_bits_ctrl_robIdx_value,       "robIdx_value")
    `CK(g_io_out_bits_ctrl_pdest,              i_io_out_bits_ctrl_pdest,              "pdest")
    `CK(g_io_out_bits_ctrl_rfWen,              i_io_out_bits_ctrl_rfWen,              "rfWen")
    `CK(g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime, "enqRsTime")
    `CK(g_io_out_bits_perfDebugInfo_selectTime,i_io_out_bits_perfDebugInfo_selectTime,"selectTime")
    `CK(g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime, "issueTime")
  endtask

  initial begin
    drive_inputs();
    repeat (NCYCLES) begin
      @(posedge clk);
      #1 check_outputs();   // 组合稳定后比对
      drive_inputs();       // 准备下一拍激励
    end
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
