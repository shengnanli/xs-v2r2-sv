// SpillRegister_6.sv —— NCB 下游 AW/AR 通道的两级 skid buffer（5 位 id，带 cache）
//
// payload 75 位（id[5] + addr[49] + len[8] + size[3] + burst[2] + cache[4] + qos[4]），父模块 NCBDownstreamAW_1 / NCBDownstreamAR_1。
// 拼字布局（首字段在最高位）：id[74:70]  addr[69:21]  len[20:13]  size[12:10]  burst[9:8]  cache[7:4]  qos[3:0]
// 控制 + 存储在共享核 rtl/uncore/xs_SpillRegister_core.sv（语义见该文件头，SpillRegister / SpillRegister_2 / SpillRegister_6 三变体同用）；
// 本文件只做字段拼字/拆字与端口同名转发，两个 valid 异步复位、两级 payload 寄存器照 golden 不复位。
// golden 210 行；端口表与连线由 scripts/gen_busbuffer_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(SpillRegister_6) —— scripts/gen_busbuffer_leaves5.py
module SpillRegister_6 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [4:0] io_in_bits_id,
  input  logic [48:0] io_in_bits_addr,
  input  logic [7:0] io_in_bits_len,
  input  logic [2:0] io_in_bits_size,
  input  logic [1:0] io_in_bits_burst,
  input  logic [3:0] io_in_bits_cache,
  input  logic [3:0] io_in_bits_qos,
  input  logic io_out_ready,
  output logic io_out_valid,
  output logic [4:0] io_out_bits_id,
  output logic [48:0] io_out_bits_addr,
  output logic [7:0] io_out_bits_len,
  output logic [2:0] io_out_bits_size,
  output logic [1:0] io_out_bits_burst,
  output logic [3:0] io_out_bits_cache,
  output logic [3:0] io_out_bits_qos
);

  logic [74:0] in_payload, out_payload;

  // 入侧拼字（首字段在最高位，字段顺序照 golden 端口序）
  assign in_payload = {
    io_in_bits_id,
    io_in_bits_addr,
    io_in_bits_len,
    io_in_bits_size,
    io_in_bits_burst,
    io_in_bits_cache,
    io_in_bits_qos
  };

  xs_SpillRegister_core #(.W(75)) u_core (
    .clock       (clock),
    .reset       (reset),
    .in_ready   (io_in_ready),
    .in_valid   (io_in_valid),
    .in_payload (in_payload),
    .out_ready   (io_out_ready),
    .out_valid   (io_out_valid),
    .out_payload (out_payload)
  );

  assign io_out_bits_id = out_payload[74:70];
  assign io_out_bits_addr = out_payload[69:21];
  assign io_out_bits_len = out_payload[20:13];
  assign io_out_bits_size = out_payload[12:10];
  assign io_out_bits_burst = out_payload[9:8];
  assign io_out_bits_cache = out_payload[7:4];
  assign io_out_bits_qos = out_payload[3:0];

endmodule
// END GENERATED(SpillRegister_6)
