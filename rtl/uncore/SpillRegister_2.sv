// SpillRegister_2.sv —— NCB 下游 W 通道的两级 skid buffer（256 位 data）
//
// payload 289 位（data[256] + strb[32] + last[1]），父模块 NCBDownstreamW / NCBDownstreamW_1。
// 拼字布局（首字段在最高位）：data[288:33]  strb[32:1]  last[0]
// 控制 + 存储在共享核 rtl/uncore/xs_SpillRegister_core.sv（语义见该文件头，SpillRegister / SpillRegister_2 / SpillRegister_6 三变体同用）；
// 本文件只做字段拼字/拆字与端口同名转发，两个 valid 异步复位、两级 payload 寄存器照 golden 不复位。
// golden 192 行；端口表与连线由 scripts/gen_busbuffer_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(SpillRegister_2) —— scripts/gen_busbuffer_leaves5.py
module SpillRegister_2 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [255:0] io_in_bits_data,
  input  logic [31:0] io_in_bits_strb,
  input  logic io_in_bits_last,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [255:0] io_out_bits_data,
  output logic [31:0] io_out_bits_strb,
  output logic io_out_bits_last
);

  logic [288:0] in_payload, out_payload;

  // 入侧拼字（首字段在最高位，字段顺序照 golden 端口序）
  assign in_payload = {
    io_in_bits_data,
    io_in_bits_strb,
    io_in_bits_last
  };

  xs_SpillRegister_core #(.W(289)) u_core (
    .clock       (clock),
    .reset       (reset),
    .in_ready   (io_in_ready),
    .in_valid   (io_in_valid),
    .in_payload (in_payload),
    .out_ready   (io_out_ready),
    .out_valid   (io_out_valid),
    .out_payload (out_payload)
  );

  assign io_out_bits_data = out_payload[288:33];
  assign io_out_bits_strb = out_payload[32:1];
  assign io_out_bits_last = out_payload[0];

endmodule
// END GENERATED(SpillRegister_2)
