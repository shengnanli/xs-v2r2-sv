`timescale 1ns/1ps
// =============================================================================
// Fence UT —— golden Fence 与可读实现 Fence_xs 双例化，逐拍比对全部输出。
//
// 激励：随机驱动入口握手 + 随机 fuOpType（加权偏向 6 个合法编码，也注入非法码
// 测健壮性）+ 随机 src0/src1/imm + 随机 sbIsEmpty + 随机 out_ready。
// 两个 DUT 接同一组输入，每个 negedge 比对所有输出端口（golden 为 X 时跳过该拍）。
// =============================================================================
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  bit rst;
  int errors = 0;
  int checks  = 0;

  always #5 clk = ~clk;

  // ---- 共享输入 ----
  logic        io_in_valid;
  logic [8:0]  io_in_bits_ctrl_fuOpType;
  logic        io_in_bits_ctrl_robIdx_flag;
  logic [7:0]  io_in_bits_ctrl_robIdx_value;
  logic [7:0]  io_in_bits_ctrl_pdest;
  logic        io_in_bits_ctrl_flushPipe;
  logic [63:0] io_in_bits_data_src_1;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_data_imm;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic        io_out_ready;
  logic        io_fenceio_sbuffer_sbIsEmpty;

  // ---- golden 输出 ----
  wire        g_in_ready, g_out_valid;
  wire        g_robIdx_flag;  wire [7:0] g_robIdx_value, g_pdest;
  wire        g_flushPipe;    wire [63:0] g_res_data;
  wire [63:0] g_perf_enq, g_perf_sel, g_perf_iss;
  wire        g_sf_valid, g_sf_rs1, g_sf_rs2, g_sf_flushPipe, g_sf_hv, g_sf_hg;
  wire [49:0] g_sf_addr;  wire [15:0] g_sf_id;
  wire        g_fencei, g_flushSb;

  // ---- impl 输出 ----
  wire        i_in_ready, i_out_valid;
  wire        i_robIdx_flag;  wire [7:0] i_robIdx_value, i_pdest;
  wire        i_flushPipe;    wire [63:0] i_res_data;
  wire [63:0] i_perf_enq, i_perf_sel, i_perf_iss;
  wire        i_sf_valid, i_sf_rs1, i_sf_rs2, i_sf_flushPipe, i_sf_hv, i_sf_hg;
  wire [49:0] i_sf_addr;  wire [15:0] i_sf_id;
  wire        i_fencei, i_flushSb;

  Fence u_g (
    .clock(clk), .reset(rst),
    .io_in_ready(g_in_ready), .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_flushPipe(io_in_bits_ctrl_flushPipe),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_ready(io_out_ready), .io_out_valid(g_out_valid),
    .io_out_bits_ctrl_robIdx_flag(g_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(g_robIdx_value),
    .io_out_bits_ctrl_pdest(g_pdest),
    .io_out_bits_ctrl_flushPipe(g_flushPipe),
    .io_out_bits_res_data(g_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime(g_perf_enq),
    .io_out_bits_perfDebugInfo_selectTime(g_perf_sel),
    .io_out_bits_perfDebugInfo_issueTime(g_perf_iss),
    .io_fenceio_sfence_valid(g_sf_valid),
    .io_fenceio_sfence_bits_rs1(g_sf_rs1),
    .io_fenceio_sfence_bits_rs2(g_sf_rs2),
    .io_fenceio_sfence_bits_addr(g_sf_addr),
    .io_fenceio_sfence_bits_id(g_sf_id),
    .io_fenceio_sfence_bits_flushPipe(g_sf_flushPipe),
    .io_fenceio_sfence_bits_hv(g_sf_hv),
    .io_fenceio_sfence_bits_hg(g_sf_hg),
    .io_fenceio_fencei(g_fencei),
    .io_fenceio_sbuffer_flushSb(g_flushSb),
    .io_fenceio_sbuffer_sbIsEmpty(io_fenceio_sbuffer_sbIsEmpty)
  );

  Fence_xs u_i (
    .clock(clk), .reset(rst),
    .io_in_ready(i_in_ready), .io_in_valid(io_in_valid),
    .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType),
    .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value),
    .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest),
    .io_in_bits_ctrl_flushPipe(io_in_bits_ctrl_flushPipe),
    .io_in_bits_data_src_1(io_in_bits_data_src_1),
    .io_in_bits_data_src_0(io_in_bits_data_src_0),
    .io_in_bits_data_imm(io_in_bits_data_imm),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_ready(io_out_ready), .io_out_valid(i_out_valid),
    .io_out_bits_ctrl_robIdx_flag(i_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value(i_robIdx_value),
    .io_out_bits_ctrl_pdest(i_pdest),
    .io_out_bits_ctrl_flushPipe(i_flushPipe),
    .io_out_bits_res_data(i_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime(i_perf_enq),
    .io_out_bits_perfDebugInfo_selectTime(i_perf_sel),
    .io_out_bits_perfDebugInfo_issueTime(i_perf_iss),
    .io_fenceio_sfence_valid(i_sf_valid),
    .io_fenceio_sfence_bits_rs1(i_sf_rs1),
    .io_fenceio_sfence_bits_rs2(i_sf_rs2),
    .io_fenceio_sfence_bits_addr(i_sf_addr),
    .io_fenceio_sfence_bits_id(i_sf_id),
    .io_fenceio_sfence_bits_flushPipe(i_sf_flushPipe),
    .io_fenceio_sfence_bits_hv(i_sf_hv),
    .io_fenceio_sfence_bits_hg(i_sf_hg),
    .io_fenceio_fencei(i_fencei),
    .io_fenceio_sbuffer_flushSb(i_flushSb),
    .io_fenceio_sbuffer_sbIsEmpty(io_fenceio_sbuffer_sbIsEmpty)
  );

  // 逐拍比对一个标量输出（golden 为 X 跳过——不应出现，但保险）
  task automatic chk(input string name, input logic [63:0] g, input logic [63:0] i);
    if (!$isunknown(g)) begin
      checks++;
      if (i !== g) begin
        errors++;
        if (errors < 30)
          $display("[ERR] t=%0t %s golden=%h impl=%h", $time, name, g, i);
      end
    end
  endtask

  // 加权随机选择 fuOpType：偏向 6 个合法编码，少量非法码测健壮
  function automatic logic [8:0] rand_op();
    int unsigned r = $urandom_range(0, 99);
    case (1'b1)
      (r < 16): return 9'h00; // nofence
      (r < 32): return 9'h10; // fence
      (r < 48): return 9'h11; // sfence
      (r < 64): return 9'h12; // fencei
      (r < 75): return 9'h13; // hfence_v
      (r < 86): return 9'h14; // hfence_g
      default : return 9'($urandom_range(0, 511)); // 非法/任意编码
    endcase
  endfunction

  initial begin
    void'($value$plusargs("NCYCLES=%d", NCYCLES));
    io_in_valid                  = 0;
    io_in_bits_ctrl_fuOpType     = 0;
    io_in_bits_ctrl_robIdx_flag  = 0;
    io_in_bits_ctrl_robIdx_value = 0;
    io_in_bits_ctrl_pdest        = 0;
    io_in_bits_ctrl_flushPipe    = 0;
    io_in_bits_data_src_1        = 0;
    io_in_bits_data_src_0        = 0;
    io_in_bits_data_imm          = 0;
    io_in_bits_perfDebugInfo_enqRsTime   = 0;
    io_in_bits_perfDebugInfo_selectTime  = 0;
    io_in_bits_perfDebugInfo_issueTime   = 0;
    io_out_ready                 = 1;
    io_fenceio_sbuffer_sbIsEmpty = 0;

    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    repeat (NCYCLES) begin
      @(posedge clk);
      // 在时钟沿后更新激励，下个 negedge 采样比对
      #1;
      io_in_valid                  = ($urandom_range(0, 99) < 55);
      io_in_bits_ctrl_fuOpType     = rand_op();
      io_in_bits_ctrl_robIdx_flag  = $urandom;
      io_in_bits_ctrl_robIdx_value = $urandom;
      io_in_bits_ctrl_pdest        = $urandom;
      io_in_bits_ctrl_flushPipe    = $urandom;
      io_in_bits_data_src_1        = {$urandom, $urandom};
      io_in_bits_data_src_0        = {$urandom, $urandom};
      io_in_bits_data_imm          = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_enqRsTime  = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_selectTime = {$urandom, $urandom};
      io_in_bits_perfDebugInfo_issueTime  = {$urandom, $urandom};
      io_out_ready                 = ($urandom_range(0, 99) < 90);
      // sbIsEmpty 偏向常拉高，保证状态机能推进，又时常拉低制造等待
      io_fenceio_sbuffer_sbIsEmpty = ($urandom_range(0, 99) < 70);

      @(negedge clk);
      chk("in_ready",   {63'b0, g_in_ready},   {63'b0, i_in_ready});
      chk("out_valid",  {63'b0, g_out_valid},  {63'b0, i_out_valid});
      chk("robIdx_flag",{63'b0, g_robIdx_flag},{63'b0, i_robIdx_flag});
      chk("robIdx_val", {56'b0, g_robIdx_value},{56'b0, i_robIdx_value});
      chk("pdest",      {56'b0, g_pdest},      {56'b0, i_pdest});
      chk("flushPipe",  {63'b0, g_flushPipe},  {63'b0, i_flushPipe});
      chk("res_data",   g_res_data,            i_res_data);
      chk("perf_enq",   g_perf_enq,            i_perf_enq);
      chk("perf_sel",   g_perf_sel,            i_perf_sel);
      chk("perf_iss",   g_perf_iss,            i_perf_iss);
      chk("sf_valid",   {63'b0, g_sf_valid},   {63'b0, i_sf_valid});
      chk("sf_rs1",     {63'b0, g_sf_rs1},     {63'b0, i_sf_rs1});
      chk("sf_rs2",     {63'b0, g_sf_rs2},     {63'b0, i_sf_rs2});
      chk("sf_addr",    {14'b0, g_sf_addr},    {14'b0, i_sf_addr});
      chk("sf_id",      {48'b0, g_sf_id},      {48'b0, i_sf_id});
      chk("sf_flushPipe",{63'b0, g_sf_flushPipe},{63'b0, i_sf_flushPipe});
      chk("sf_hv",      {63'b0, g_sf_hv},      {63'b0, i_sf_hv});
      chk("sf_hg",      {63'b0, g_sf_hg},      {63'b0, i_sf_hg});
      chk("fencei",     {63'b0, g_fencei},     {63'b0, i_fencei});
      chk("flushSb",    {63'b0, g_flushSb},    {63'b0, i_flushSb});
    end

    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end else begin
      $display("TEST FAILED");
      $fatal(1);
    end
  end
endmodule
