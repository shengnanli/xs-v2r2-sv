// =============================================================================
// PipelineRegModule —— 带 valid/ready 握手的「一拍流水寄存器」
//                      （PipelineRegModule 家族共用核 + 本变体 wrapper）
//
// 出处：xiangshan/mem/MemCommon.scala 的 AddPipelineReg.PipelineRegModule。
// LoadQueueUncache 用它在四个出口各垫一拍（Chisel: AddPipelineReg(left, right, false.B)）：
//   PipelineRegModule    （本文件）uncache 总线请求 io.uncache.req（10 个字段）
//   PipelineRegModule_1  MMIO load 写回 io.mmioOut(2)            （182 个字段）
//   PipelineRegModule_2  NC load 写回 io.ncOut(0/1/2)（三个实例）（187 个字段）
// 家族成员只差 payload 的字段表，控制逻辑逐字相同（gen_pipelinereg.py 每次生成时
// 对 golden 逐条核对，见其 check_body()）。
//
// 机制（就是一个深度为 1 的 skid-less 缓冲）：
//   · valid 寄存器（异步复位为 0）：本拍 in 成交则置 1；否则 out 成交则清 0。
//   · payload 寄存器（不复位）：只在 in 成交那一拍写入，其余时间保持。
//   · in.ready = 缓冲空 或 下游本拍收走（~valid | out.ready）——
//     所以满且下游不收时反压上游，满且下游收走时同一拍可以接新数据（吞吐 1/拍）。
//   · Chisel 里还有一个 isFlush 输入；三处调用都传 false.B，firtool 已把它消掉，
//     golden 端口表里没有它，这里也没有。
//
// 结构：payload 在核里是一根 W 位向量（bits_q）。wrapper 按 golden 端口表的字段
// 顺序把 io_in_bits_* 拼成这根向量（第一个字段在最高位），出口再按同样的偏移拆开。
// golden 是按字段展平的寄存器 io_out_bits_r_<字段>；两侧名字对不上，FM 靠
// verif/ut/PipelineRegModule/fm_pins_pre.tcl（gen_pipelinereg.py 生成）逐位钉。
// =============================================================================

module xs_PipelineRegModule_core #(
  parameter int W = 1        // payload 总位宽（各变体由 wrapper 给出）
) (
  input  logic         clock,
  input  logic         reset,
  output logic         in_ready,
  input  logic         in_valid,
  input  logic [W-1:0] in_bits,
  input  logic         out_ready,
  output logic         out_valid,
  output logic [W-1:0] out_bits
);

  logic         valid_q;   // 缓冲里有一笔数据（golden: pipeline_reg_valid）
  logic [W-1:0] bits_q;    // 那笔数据的 payload（golden: io_out_bits_r_*）

  // 上游能写：缓冲空，或者下游本拍把旧数据收走。
  assign in_ready = ~valid_q | out_ready;

  wire in_fire  = in_valid & in_ready;
  wire out_fire = out_ready & valid_q;

  // valid：入优先于出（Chisel 两个 when 的先后，后写的 in.fire 覆盖 out.fire）。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      valid_q <= 1'b0;
    else if (in_fire)
      valid_q <= 1'b1;
    else if (out_fire)
      valid_q <= 1'b0;
  end

  // payload：RegEnable(io.in.bits, io.in.fire)，不复位。
  always_ff @(posedge clock) begin
    if (in_fire)
      bits_q <= in_bits;
  end

  assign out_valid = valid_q;
  assign out_bits  = bits_q;

endmodule

// BEGIN GENERATED(pipereg-wrapper)
module PipelineRegModule(
  input         clock,
  input         reset,
  output        io_in_ready,
  input         io_in_valid,
  input         io_in_bits_robIdx_flag,
  input  [7:0]  io_in_bits_robIdx_value,
  input  [4:0]  io_in_bits_cmd,
  input  [47:0] io_in_bits_addr,
  input  [49:0] io_in_bits_vaddr,
  input  [63:0] io_in_bits_data,
  input  [7:0]  io_in_bits_mask,
  input  [6:0]  io_in_bits_id,
  input         io_in_bits_nc,
  input         io_in_bits_memBackTypeMM,
  input         io_out_ready,
  output        io_out_valid,
  output        io_out_bits_robIdx_flag,
  output [7:0]  io_out_bits_robIdx_value,
  output [4:0]  io_out_bits_cmd,
  output [47:0] io_out_bits_addr,
  output [49:0] io_out_bits_vaddr,
  output [63:0] io_out_bits_data,
  output [7:0]  io_out_bits_mask,
  output [6:0]  io_out_bits_id,
  output        io_out_bits_nc,
  output        io_out_bits_memBackTypeMM
);
  // payload = 10 个字段拼成 193 位（字段顺序同 golden 端口表，第一个在最高位）
  localparam int W = 193;
  logic [W-1:0] in_bits;
  logic [W-1:0] out_bits;

  assign in_bits = {
    io_in_bits_robIdx_flag,
    io_in_bits_robIdx_value,
    io_in_bits_cmd,
    io_in_bits_addr,
    io_in_bits_vaddr,
    io_in_bits_data,
    io_in_bits_mask,
    io_in_bits_id,
    io_in_bits_nc,
    io_in_bits_memBackTypeMM
  };

  xs_PipelineRegModule_core #(.W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_ready  (io_in_ready),
    .in_valid  (io_in_valid),
    .in_bits   (in_bits),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_bits)
  );

  assign io_out_bits_robIdx_flag = out_bits[192];
  assign io_out_bits_robIdx_value = out_bits[191:184];
  assign io_out_bits_cmd = out_bits[183:179];
  assign io_out_bits_addr = out_bits[178:131];
  assign io_out_bits_vaddr = out_bits[130:81];
  assign io_out_bits_data = out_bits[80:17];
  assign io_out_bits_mask = out_bits[16:9];
  assign io_out_bits_id = out_bits[8:2];
  assign io_out_bits_nc = out_bits[1];
  assign io_out_bits_memBackTypeMM = out_bits[0];
endmodule
// END GENERATED
