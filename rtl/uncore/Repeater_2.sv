// Repeater_2.sv —— TLWidthWidget_1 的 A 通道 repeat 缓冲（8 位 mask + 64 位 data）
//
// payload 130 位（opcode[4] + size[2] + source[15] + address[30] + user_amba_prot_bufferable[1] + user_amba_prot_modifiable[1] + user_amba_prot_readalloc[1] + user_amba_prot_writealloc[1] + user_amba_prot_privileged[1] + user_amba_prot_secure[1] + user_amba_prot_fetch[1] + mask[8] + data[64]），父模块 TLWidthWidget_1。
// 拼字布局（首字段在最高位）：opcode[129:126]  size[125:124]  source[123:109]  address[108:79]  user_amba_prot_bufferable[78]  user_amba_prot_modifiable[77]  user_amba_prot_readalloc[76]  user_amba_prot_writealloc[75]  user_amba_prot_privileged[74]  user_amba_prot_secure[73]  user_amba_prot_fetch[72]  mask[71:64]  data[63:0]
// 控制 + 存储在共享核 rtl/uncore/xs_Repeater_core.sv（语义见该文件头，Repeater_1 / Repeater_2 两变体同用）；
// 本变体无 io_full 端口（golden 就没引出），核的 full 输出悬空；full 异步复位、saved payload 寄存器照 golden 不复位。
// golden 221 行；端口表与连线由 scripts/gen_busbuffer_leaves5.py 从 golden 机械生成并逐字段校验。


// BEGIN GENERATED(Repeater_2) —— scripts/gen_busbuffer_leaves5.py
module Repeater_2 (
  input  logic clock,
  input  logic reset,
  input  logic io_repeat,
  output logic io_enq_ready,
  input  logic io_enq_valid,
  input  logic [3:0] io_enq_bits_opcode,
  input  logic [1:0] io_enq_bits_size,
  input  logic [14:0] io_enq_bits_source,
  input  logic [29:0] io_enq_bits_address,
  input  logic io_enq_bits_user_amba_prot_bufferable,
  input  logic io_enq_bits_user_amba_prot_modifiable,
  input  logic io_enq_bits_user_amba_prot_readalloc,
  input  logic io_enq_bits_user_amba_prot_writealloc,
  input  logic io_enq_bits_user_amba_prot_privileged,
  input  logic io_enq_bits_user_amba_prot_secure,
  input  logic io_enq_bits_user_amba_prot_fetch,
  input  logic [7:0] io_enq_bits_mask,
  input  logic [63:0] io_enq_bits_data,
  input  logic io_deq_ready,
  output logic io_deq_valid,
  output logic [3:0] io_deq_bits_opcode,
  output logic [1:0] io_deq_bits_size,
  output logic [14:0] io_deq_bits_source,
  output logic [29:0] io_deq_bits_address,
  output logic io_deq_bits_user_amba_prot_bufferable,
  output logic io_deq_bits_user_amba_prot_modifiable,
  output logic io_deq_bits_user_amba_prot_readalloc,
  output logic io_deq_bits_user_amba_prot_writealloc,
  output logic io_deq_bits_user_amba_prot_privileged,
  output logic io_deq_bits_user_amba_prot_secure,
  output logic io_deq_bits_user_amba_prot_fetch,
  output logic [7:0] io_deq_bits_mask,
  output logic [63:0] io_deq_bits_data
);

  logic [129:0] in_payload, out_payload;

  // 入侧拼字（首字段在最高位，字段顺序照 golden 端口序）
  assign in_payload = {
    io_enq_bits_opcode,
    io_enq_bits_size,
    io_enq_bits_source,
    io_enq_bits_address,
    io_enq_bits_user_amba_prot_bufferable,
    io_enq_bits_user_amba_prot_modifiable,
    io_enq_bits_user_amba_prot_readalloc,
    io_enq_bits_user_amba_prot_writealloc,
    io_enq_bits_user_amba_prot_privileged,
    io_enq_bits_user_amba_prot_secure,
    io_enq_bits_user_amba_prot_fetch,
    io_enq_bits_mask,
    io_enq_bits_data
  };

  xs_Repeater_core #(.W(130)) u_core (
    .clock       (clock),
    .reset       (reset),
    .repeat_req  (io_repeat),
    .full        (),
    .enq_ready   (io_enq_ready),
    .enq_valid   (io_enq_valid),
    .enq_payload (in_payload),
    .deq_ready   (io_deq_ready),
    .deq_valid   (io_deq_valid),
    .deq_payload (out_payload)
  );

  assign io_deq_bits_opcode = out_payload[129:126];
  assign io_deq_bits_size = out_payload[125:124];
  assign io_deq_bits_source = out_payload[123:109];
  assign io_deq_bits_address = out_payload[108:79];
  assign io_deq_bits_user_amba_prot_bufferable = out_payload[78];
  assign io_deq_bits_user_amba_prot_modifiable = out_payload[77];
  assign io_deq_bits_user_amba_prot_readalloc = out_payload[76];
  assign io_deq_bits_user_amba_prot_writealloc = out_payload[75];
  assign io_deq_bits_user_amba_prot_privileged = out_payload[74];
  assign io_deq_bits_user_amba_prot_secure = out_payload[73];
  assign io_deq_bits_user_amba_prot_fetch = out_payload[72];
  assign io_deq_bits_mask = out_payload[71:64];
  assign io_deq_bits_data = out_payload[63:0];

endmodule
// END GENERATED(Repeater_2)
