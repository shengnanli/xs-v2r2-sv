// SpillRegister.sv —— NCB 下游 AW/AR 通道的两级 skid buffer（6 位 id）
//
// payload 72 位（id[6] + addr[49] + len[8] + size[3] + burst[2] + qos[4]），父模块 NCBDownstreamAW / NCBDownstreamAR。
// 拼字布局（首字段在最高位）：id[71:66]  addr[65:17]  len[16:9]  size[8:6]  burst[5:4]  qos[3:0]
// 控制 + 存储在共享核 rtl/uncore/xs_SpillRegister_core.sv（语义见该文件头，SpillRegister / SpillRegister_2 / SpillRegister_6 三变体同用）；
// 本文件只做字段拼字/拆字与端口同名转发，两个 valid 异步复位、两级 payload 寄存器照 golden 不复位。
// golden 201 行；端口表与连线由 scripts/gen_busbuffer_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(SpillRegister) —— scripts/gen_busbuffer_leaves5.py
module SpillRegister (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [5:0] io_in_bits_id,
  input  logic [48:0] io_in_bits_addr,
  input  logic [7:0] io_in_bits_len,
  input  logic [2:0] io_in_bits_size,
  input  logic [1:0] io_in_bits_burst,
  input  logic [3:0] io_in_bits_qos,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [5:0] io_out_bits_id,
  output logic [48:0] io_out_bits_addr,
  output logic [7:0] io_out_bits_len,
  output logic [2:0] io_out_bits_size,
  output logic [1:0] io_out_bits_burst,
  output logic [3:0] io_out_bits_qos
);

  logic [71:0] in_payload, out_payload;

  // 入侧拼字（首字段在最高位，字段顺序照 golden 端口序）
  assign in_payload = {
    io_in_bits_id,
    io_in_bits_addr,
    io_in_bits_len,
    io_in_bits_size,
    io_in_bits_burst,
    io_in_bits_qos
  };

  xs_SpillRegister_core #(.W(72)) u_core (
    .clock       (clock),
    .reset       (reset),
    .in_ready   (io_in_ready),
    .in_valid   (io_in_valid),
    .in_payload (in_payload),
    .out_ready   (io_out_ready),
    .out_valid   (io_out_valid),
    .out_payload (out_payload)
  );

  assign io_out_bits_id = out_payload[71:66];
  assign io_out_bits_addr = out_payload[65:17];
  assign io_out_bits_len = out_payload[16:9];
  assign io_out_bits_size = out_payload[8:6];
  assign io_out_bits_burst = out_payload[5:4];
  assign io_out_bits_qos = out_payload[3:0];

endmodule
// END GENERATED(SpillRegister)
