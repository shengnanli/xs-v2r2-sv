// =============================================================================
// PFEvent.sv —— 24 个 mhpmevent CSR 的影子副本组（NewCSR 旁边的性能事件选择寄存器堆）
//
// 在哪一层：NewCSR 旁边（backend/fu/NewCSR/PFEvent.scala `class PFEvent`）。每个 hpm 计数器
//   mhpmcounter3..26 有一个事件选择 CSR mhpmevent3..26；PFEvent 监听 CSR 写总线 distribute_csr.w，
//   在 CSR 外面**再存一份**，把内容直接送给各单元的性能计数选择逻辑（HPerfMonitor 的 io_hpm_event），
//   免得从 NewCSR 深处拉长线。本配置 perfCntNum = 24（golden 端口 io_hpmevent_0..23）。
// 机制（照 Scala 逐句）：第 n 个副本是一个 perfEventsModule（CSRModule("perfEvents", MhpmeventBundle)），
//   写使能 = w.valid && w.addr == mhpmevent3 + n（0x323 + n），写数据直接接总线；读数据就是输出。
//   字段语义 / WARL（OPTYPE 只收合法值）/ 异步复位都在 perfEventsModule 里，见 rtl/backend/perfEventsModule.sv。
// 子模块：perfEventsModule ×24（本仓重写件，已签核）。golden 对照：G1-canonical/golden-rtl/PFEvent.sv（288 行）。
// =============================================================================
module PFEvent (
  input  logic        clock,
  input  logic        reset,
  input  logic        io_distribute_csr_w_valid,
  input  logic [11:0] io_distribute_csr_w_bits_addr,
  input  logic [63:0] io_distribute_csr_w_bits_data,
  output logic [63:0] io_hpmevent_0,
  output logic [63:0] io_hpmevent_1,
  output logic [63:0] io_hpmevent_2,
  output logic [63:0] io_hpmevent_3,
  output logic [63:0] io_hpmevent_4,
  output logic [63:0] io_hpmevent_5,
  output logic [63:0] io_hpmevent_6,
  output logic [63:0] io_hpmevent_7,
  output logic [63:0] io_hpmevent_8,
  output logic [63:0] io_hpmevent_9,
  output logic [63:0] io_hpmevent_10,
  output logic [63:0] io_hpmevent_11,
  output logic [63:0] io_hpmevent_12,
  output logic [63:0] io_hpmevent_13,
  output logic [63:0] io_hpmevent_14,
  output logic [63:0] io_hpmevent_15,
  output logic [63:0] io_hpmevent_16,
  output logic [63:0] io_hpmevent_17,
  output logic [63:0] io_hpmevent_18,
  output logic [63:0] io_hpmevent_19,
  output logic [63:0] io_hpmevent_20,
  output logic [63:0] io_hpmevent_21,
  output logic [63:0] io_hpmevent_22,
  output logic [63:0] io_hpmevent_23
);

  localparam int          NUM_EVENTS     = 24;       // perfCntNum
  localparam logic [11:0] CSR_MHPMEVENT3 = 12'h323;  // 第 0 个副本对应的 CSR 地址

  logic [63:0] hpmevent [NUM_EVENTS];

  // 第 n 个副本：地址命中 mhpmevent(3+n) 的写才写它
  for (genvar n = 0; n < NUM_EVENTS; n++) begin : g_evt
    perfEventsModule perfEvents (
      .clock   (clock),
      .reset   (reset),
      .w_wen   (io_distribute_csr_w_valid && io_distribute_csr_w_bits_addr == CSR_MHPMEVENT3 + 12'(n)),
      .w_wdata (io_distribute_csr_w_bits_data),
      .rdata   (hpmevent[n])
    );
  end

  // 展平成 golden 的逐个输出端口
  assign io_hpmevent_0 = hpmevent[0];
  assign io_hpmevent_1 = hpmevent[1];
  assign io_hpmevent_2 = hpmevent[2];
  assign io_hpmevent_3 = hpmevent[3];
  assign io_hpmevent_4 = hpmevent[4];
  assign io_hpmevent_5 = hpmevent[5];
  assign io_hpmevent_6 = hpmevent[6];
  assign io_hpmevent_7 = hpmevent[7];
  assign io_hpmevent_8 = hpmevent[8];
  assign io_hpmevent_9 = hpmevent[9];
  assign io_hpmevent_10 = hpmevent[10];
  assign io_hpmevent_11 = hpmevent[11];
  assign io_hpmevent_12 = hpmevent[12];
  assign io_hpmevent_13 = hpmevent[13];
  assign io_hpmevent_14 = hpmevent[14];
  assign io_hpmevent_15 = hpmevent[15];
  assign io_hpmevent_16 = hpmevent[16];
  assign io_hpmevent_17 = hpmevent[17];
  assign io_hpmevent_18 = hpmevent[18];
  assign io_hpmevent_19 = hpmevent[19];
  assign io_hpmevent_20 = hpmevent[20];
  assign io_hpmevent_21 = hpmevent[21];
  assign io_hpmevent_22 = hpmevent[22];
  assign io_hpmevent_23 = hpmevent[23];

endmodule
