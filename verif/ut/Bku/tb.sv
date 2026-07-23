// =============================================================================
// Bku UT testbench —— golden Bku vs impl Bku_xs 逐拍比对
//
// 策略：
//   · 覆盖全部 32 个合法 fuOpType（BKUOpType），并夹杂随机 src0/src1。
//   · validPipe_0/1/2 与 io_in_valid 随机置位，制造各种打拍使能组合，覆盖
//     valid 链与 perf 透传分叉（不只是“一直 valid”）。
//   · 每拍比对所有输出端口；golden 含 X（未初始化打拍）时按铁律跳过该位
//     （!$isunknown(golden)）。
//   · seed 通过 +ntb_random_seed 注入；run 200000 拍 errors=0 视为通过。
// =============================================================================
`timescale 1ns/1ps
module tb;
  localparam int NVEC = 200000;
  int errors = 0, checks = 0;

  // 全部 36 个合法 opType（与 BKUOpType 一致）
  localparam int NOPS = 36;
  logic [8:0] ops [0:NOPS-1] = '{
    9'h00, 9'h01, 9'h02,             // clmul/h/r
    9'h04, 9'h05,                    // xperm.n/.b
    9'h08, 9'h09, 9'h0a, 9'h0b, 9'h0c, 9'h0d, // clz/clzw/ctz/ctzw/cpop/cpopw
    9'h20, 9'h21, 9'h22, 9'h23, 9'h24, 9'h25, 9'h26, // aes64*
    9'h28, 9'h29, 9'h2a, 9'h2b, 9'h2c, 9'h2d, 9'h2e, 9'h2f, // sm4ed/ks
    9'h30, 9'h31, 9'h32, 9'h33, 9'h34, 9'h35, 9'h36, 9'h37, // sha
    9'h38, 9'h39                     // sm3p0/p1
  };

  // DUT 输入
  logic        clock = 0, reset;
  logic        io_in_valid;
  logic [8:0]  io_in_bits_ctrl_fuOpType;
  logic        io_in_bits_ctrlPipe_2_robIdx_flag;
  logic [7:0]  io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0]  io_in_bits_ctrlPipe_2_pdest;
  logic        io_in_bits_ctrlPipe_2_rfWen;
  logic        io_in_bits_validPipe_0, io_in_bits_validPipe_1, io_in_bits_validPipe_2;
  logic [63:0] io_in_bits_data_src_1, io_in_bits_data_src_0;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;

  // golden 输出
  wire        g_out_valid, g_robIdx_flag, g_rfWen;
  wire [7:0]  g_robIdx_value, g_pdest;
  wire [63:0] g_res_data, g_enq, g_sel, g_iss;
  // impl 输出
  wire        i_out_valid, i_robIdx_flag, i_rfWen;
  wire [7:0]  i_robIdx_value, i_pdest;
  wire [63:0] i_res_data, i_enq, i_sel, i_iss;

  // golden Bku 有 io_out_ready 输入端口(impl 侧 out.ready 恒 tie-high, 不引出)。
  // tb 不驱动它则悬空为 X → golden 内 rdyVec_1=~validVecThisFu_2|io_out_ready 在
  // validVecThisFu_2=1 时变 X, 令 golden 输出/perf 寄存器间歇冻结, 与 impl(恒 ready)
  // 产生大量伪失配。按真实设计(Bku.out.ready 恒 1)把 golden io_out_ready 钉为 1。
  // (io_in_ready 是 golden 输出, impl 未引出, 悬空即可, 不参与比对。)
  Bku g_dut (
    .clock(clock), .reset(reset),
    .io_out_ready(1'b1),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen(io_in_bits_ctrlPipe_2_rfWen),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(g_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_robIdx_value),
    .io_out_bits_ctrl_pdest(g_pdest),
    .io_out_bits_ctrl_rfWen(g_rfWen),
    .io_out_bits_res_data(g_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime(g_enq),
    .io_out_bits_perfDebugInfo_selectTime(g_sel),
    .io_out_bits_perfDebugInfo_issueTime(g_iss)
  );

  Bku_xs i_dut (
    .clock(clock), .reset(reset),
    .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest),
    .io_in_bits_ctrlPipe_2_rfWen(io_in_bits_ctrlPipe_2_rfWen),
    .io_in_bits_validPipe_0(io_in_bits_validPipe_0),
    .io_in_bits_validPipe_1(io_in_bits_validPipe_1),
    .io_in_bits_validPipe_2(io_in_bits_validPipe_2),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(i_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_robIdx_value),
    .io_out_bits_ctrl_pdest(i_pdest),
    .io_out_bits_ctrl_rfWen(i_rfWen),
    .io_out_bits_res_data(i_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime(i_enq),
    .io_out_bits_perfDebugInfo_selectTime(i_sel),
    .io_out_bits_perfDebugInfo_issueTime(i_iss)
  );

  always #5 clock = ~clock;

  // 单端口比对（golden 含 X 跳过）
  task automatic cmp(input string nm, input logic [63:0] g, input logic [63:0] i);
    if (!$isunknown(g)) begin
      checks++;
      if (g !== i) begin
        errors++;
        if (errors <= 30)
          $display("MISMATCH %s @%0t: golden=%h impl=%h", nm, $time, g, i);
      end
    end
  endtask

  task automatic drive_rand();
    io_in_valid                        = $random;
    io_in_bits_validPipe_0             = $random;
    io_in_bits_validPipe_1             = $random;
    io_in_bits_validPipe_2             = $random;
    io_in_bits_ctrl_fuOpType           = ops[$urandom_range(0, NOPS-1)];
    io_in_bits_data_src_0              = {$random, $random};
    io_in_bits_data_src_1             = {$random, $random};
    io_in_bits_ctrlPipe_2_robIdx_flag  = $random;
    io_in_bits_ctrlPipe_2_robIdx_value = $random;
    io_in_bits_ctrlPipe_2_pdest        = $random;
    io_in_bits_ctrlPipe_2_rfWen        = $random;
    io_in_bits_perfDebugInfo_enqRsTime  = {$random, $random};
    io_in_bits_perfDebugInfo_selectTime = {$random, $random};
    io_in_bits_perfDebugInfo_issueTime  = {$random, $random};
  endtask

  initial begin
    // 复位
    reset = 1;
    io_in_valid = 0;
    io_in_bits_validPipe_0 = 0; io_in_bits_validPipe_1 = 0; io_in_bits_validPipe_2 = 0;
    io_in_bits_ctrl_fuOpType = 0;
    io_in_bits_data_src_0 = 0; io_in_bits_data_src_1 = 0;
    io_in_bits_ctrlPipe_2_robIdx_flag = 0; io_in_bits_ctrlPipe_2_robIdx_value = 0;
    io_in_bits_ctrlPipe_2_pdest = 0; io_in_bits_ctrlPipe_2_rfWen = 0;
    io_in_bits_perfDebugInfo_enqRsTime = 0;
    io_in_bits_perfDebugInfo_selectTime = 0;
    io_in_bits_perfDebugInfo_issueTime = 0;
    repeat (4) @(negedge clock);
    reset = 0;

    for (int v = 0; v < NVEC; v++) begin
      @(negedge clock);
      drive_rand();
      #1; // 让组合输出（含跨层次 assign）充分传播后再采样
      // 比对（流水已稳定后；前几拍输出为 X 自动被 cmp 跳过）
      cmp("out_valid",   {63'b0, g_out_valid},   {63'b0, i_out_valid});
      cmp("res_data",    g_res_data,             i_res_data);
      cmp("robIdx_flag", {63'b0, g_robIdx_flag}, {63'b0, i_robIdx_flag});
      cmp("robIdx_val",  {56'b0, g_robIdx_value},{56'b0, i_robIdx_value});
      cmp("pdest",       {56'b0, g_pdest},       {56'b0, i_pdest});
      cmp("rfWen",       {63'b0, g_rfWen},       {63'b0, i_rfWen});
      cmp("perf_enq",    g_enq,                  i_enq);
      cmp("perf_sel",    g_sel,                  i_sel);
      cmp("perf_iss",    g_iss,                  i_iss);
    end

    $display("=== Bku UT: checks=%0d errors=%0d ===", checks, errors);
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end
endmodule
