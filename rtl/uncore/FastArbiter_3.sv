// =============================================================================
// FastArbiter_3.sv —— FastArbiter 家族薄 wrapper：L2 MSHRCtl 16 个 MSHR 发往 CHI TXREQ（Acquire/读写请求）的仲裁
//
// 本变体规模：N=16 路，载荷打平 W=96 位（14 个字段，其中 5 个常量字段）。
//   例化者：MSHRCtl.sv（实例 txreq_arb）。
//   常量字段：每个请求方给这些字段喂的都是同一个常量，firtool 于是删掉了它们
//   的输入端口、把输出折成 `K & |chosenOH`。本文件把常量喂进每一路，核里的
//   Mux1H 自然得出同一结果：
//     qos                      = 4'hE   —— MSHR.scala:367 oa.qos := Fill(QOS_WIDTH, 1) - 1
//     size                     = 3'h6   —— MSHR.scala:394 oa.size := log2Ceil(blockBytes)（64B 行）
//     memAttr_cacheable        = 1'h1   —— MSHR.scala:416 MemAttr(cacheable = true)
//     memAttr_ewa              = 1'h1   —— MSHR.scala:419 MemAttr(ewa = true)
//     snpAttr                  = 1'h1   —— MSHR.scala:421 oa.snpAttr := true.B
//
// 本文件只做"字段打包 → 核 → 拆包"的端口对位；仲裁逻辑（轮转 + 挂起记忆）
// 在 rtl/common/xs_FastArbiter_core.sv，全家族共一份。
// 本文件由 scripts/gen_fastarbiter_l2.py 生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/FastArbiter_3.sv
// =============================================================================
package fastarbiter_3_pkg;
  // 载荷字段表：顺序 = golden io_out_bits_* 的端口顺序，靠前者占高位。
  typedef struct packed {
    logic [3:0]  qos;               // 常量 4'hE
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [6:0]  opcode;
    logic [2:0]  size;              // 常量 3'h6
    logic [47:0] addr;
    logic        likelyshared;
    logic        allowRetry;
    logic [3:0]  pCrdType;
    logic        memAttr_allocate;
    logic        memAttr_cacheable; // 常量 1'h1
    logic        memAttr_ewa;       // 常量 1'h1
    logic        snpAttr;           // 常量 1'h1
    logic        expCompAck;
  } payload_t;
endpackage

module FastArbiter_3 import fastarbiter_3_pkg::*; (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [10:0] io_in_0_bits_tgtID,
  input  [11:0] io_in_0_bits_txnID,
  input  [6:0]  io_in_0_bits_opcode,
  input  [47:0] io_in_0_bits_addr,
  input         io_in_0_bits_likelyshared,
  input         io_in_0_bits_allowRetry,
  input  [3:0]  io_in_0_bits_pCrdType,
  input         io_in_0_bits_memAttr_allocate,
  input         io_in_0_bits_expCompAck,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [10:0] io_in_1_bits_tgtID,
  input  [11:0] io_in_1_bits_txnID,
  input  [6:0]  io_in_1_bits_opcode,
  input  [47:0] io_in_1_bits_addr,
  input         io_in_1_bits_likelyshared,
  input         io_in_1_bits_allowRetry,
  input  [3:0]  io_in_1_bits_pCrdType,
  input         io_in_1_bits_memAttr_allocate,
  input         io_in_1_bits_expCompAck,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [10:0] io_in_2_bits_tgtID,
  input  [11:0] io_in_2_bits_txnID,
  input  [6:0]  io_in_2_bits_opcode,
  input  [47:0] io_in_2_bits_addr,
  input         io_in_2_bits_likelyshared,
  input         io_in_2_bits_allowRetry,
  input  [3:0]  io_in_2_bits_pCrdType,
  input         io_in_2_bits_memAttr_allocate,
  input         io_in_2_bits_expCompAck,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [10:0] io_in_3_bits_tgtID,
  input  [11:0] io_in_3_bits_txnID,
  input  [6:0]  io_in_3_bits_opcode,
  input  [47:0] io_in_3_bits_addr,
  input         io_in_3_bits_likelyshared,
  input         io_in_3_bits_allowRetry,
  input  [3:0]  io_in_3_bits_pCrdType,
  input         io_in_3_bits_memAttr_allocate,
  input         io_in_3_bits_expCompAck,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [10:0] io_in_4_bits_tgtID,
  input  [11:0] io_in_4_bits_txnID,
  input  [6:0]  io_in_4_bits_opcode,
  input  [47:0] io_in_4_bits_addr,
  input         io_in_4_bits_likelyshared,
  input         io_in_4_bits_allowRetry,
  input  [3:0]  io_in_4_bits_pCrdType,
  input         io_in_4_bits_memAttr_allocate,
  input         io_in_4_bits_expCompAck,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input  [10:0] io_in_5_bits_tgtID,
  input  [11:0] io_in_5_bits_txnID,
  input  [6:0]  io_in_5_bits_opcode,
  input  [47:0] io_in_5_bits_addr,
  input         io_in_5_bits_likelyshared,
  input         io_in_5_bits_allowRetry,
  input  [3:0]  io_in_5_bits_pCrdType,
  input         io_in_5_bits_memAttr_allocate,
  input         io_in_5_bits_expCompAck,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input  [10:0] io_in_6_bits_tgtID,
  input  [11:0] io_in_6_bits_txnID,
  input  [6:0]  io_in_6_bits_opcode,
  input  [47:0] io_in_6_bits_addr,
  input         io_in_6_bits_likelyshared,
  input         io_in_6_bits_allowRetry,
  input  [3:0]  io_in_6_bits_pCrdType,
  input         io_in_6_bits_memAttr_allocate,
  input         io_in_6_bits_expCompAck,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input  [10:0] io_in_7_bits_tgtID,
  input  [11:0] io_in_7_bits_txnID,
  input  [6:0]  io_in_7_bits_opcode,
  input  [47:0] io_in_7_bits_addr,
  input         io_in_7_bits_likelyshared,
  input         io_in_7_bits_allowRetry,
  input  [3:0]  io_in_7_bits_pCrdType,
  input         io_in_7_bits_memAttr_allocate,
  input         io_in_7_bits_expCompAck,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input  [10:0] io_in_8_bits_tgtID,
  input  [11:0] io_in_8_bits_txnID,
  input  [6:0]  io_in_8_bits_opcode,
  input  [47:0] io_in_8_bits_addr,
  input         io_in_8_bits_likelyshared,
  input         io_in_8_bits_allowRetry,
  input  [3:0]  io_in_8_bits_pCrdType,
  input         io_in_8_bits_memAttr_allocate,
  input         io_in_8_bits_expCompAck,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input  [10:0] io_in_9_bits_tgtID,
  input  [11:0] io_in_9_bits_txnID,
  input  [6:0]  io_in_9_bits_opcode,
  input  [47:0] io_in_9_bits_addr,
  input         io_in_9_bits_likelyshared,
  input         io_in_9_bits_allowRetry,
  input  [3:0]  io_in_9_bits_pCrdType,
  input         io_in_9_bits_memAttr_allocate,
  input         io_in_9_bits_expCompAck,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input  [10:0] io_in_10_bits_tgtID,
  input  [11:0] io_in_10_bits_txnID,
  input  [6:0]  io_in_10_bits_opcode,
  input  [47:0] io_in_10_bits_addr,
  input         io_in_10_bits_likelyshared,
  input         io_in_10_bits_allowRetry,
  input  [3:0]  io_in_10_bits_pCrdType,
  input         io_in_10_bits_memAttr_allocate,
  input         io_in_10_bits_expCompAck,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input  [10:0] io_in_11_bits_tgtID,
  input  [11:0] io_in_11_bits_txnID,
  input  [6:0]  io_in_11_bits_opcode,
  input  [47:0] io_in_11_bits_addr,
  input         io_in_11_bits_likelyshared,
  input         io_in_11_bits_allowRetry,
  input  [3:0]  io_in_11_bits_pCrdType,
  input         io_in_11_bits_memAttr_allocate,
  input         io_in_11_bits_expCompAck,
  output        io_in_12_ready,
  input         io_in_12_valid,
  input  [10:0] io_in_12_bits_tgtID,
  input  [11:0] io_in_12_bits_txnID,
  input  [6:0]  io_in_12_bits_opcode,
  input  [47:0] io_in_12_bits_addr,
  input         io_in_12_bits_likelyshared,
  input         io_in_12_bits_allowRetry,
  input  [3:0]  io_in_12_bits_pCrdType,
  input         io_in_12_bits_memAttr_allocate,
  input         io_in_12_bits_expCompAck,
  output        io_in_13_ready,
  input         io_in_13_valid,
  input  [10:0] io_in_13_bits_tgtID,
  input  [11:0] io_in_13_bits_txnID,
  input  [6:0]  io_in_13_bits_opcode,
  input  [47:0] io_in_13_bits_addr,
  input         io_in_13_bits_likelyshared,
  input         io_in_13_bits_allowRetry,
  input  [3:0]  io_in_13_bits_pCrdType,
  input         io_in_13_bits_memAttr_allocate,
  input         io_in_13_bits_expCompAck,
  output        io_in_14_ready,
  input         io_in_14_valid,
  input  [10:0] io_in_14_bits_tgtID,
  input  [11:0] io_in_14_bits_txnID,
  input  [6:0]  io_in_14_bits_opcode,
  input  [47:0] io_in_14_bits_addr,
  input         io_in_14_bits_likelyshared,
  input         io_in_14_bits_allowRetry,
  input  [3:0]  io_in_14_bits_pCrdType,
  input         io_in_14_bits_memAttr_allocate,
  input         io_in_14_bits_expCompAck,
  output        io_in_15_ready,
  input         io_in_15_valid,
  input  [10:0] io_in_15_bits_tgtID,
  input  [11:0] io_in_15_bits_txnID,
  input  [6:0]  io_in_15_bits_opcode,
  input  [47:0] io_in_15_bits_addr,
  input         io_in_15_bits_likelyshared,
  input         io_in_15_bits_allowRetry,
  input  [3:0]  io_in_15_bits_pCrdType,
  input         io_in_15_bits_memAttr_allocate,
  input         io_in_15_bits_expCompAck,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [11:0] io_out_bits_txnID,
  output [6:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_size,
  output [47:0] io_out_bits_addr,
  output        io_out_bits_likelyshared,
  output        io_out_bits_allowRetry,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_memAttr_allocate,
  output        io_out_bits_memAttr_cacheable,
  output        io_out_bits_memAttr_ewa,
  output        io_out_bits_snpAttr,
  output        io_out_bits_expCompAck
);
  localparam int N = 16;
  localparam int W = $bits(payload_t);

  // ---- 打包：第 i 路的全部字段按字段表拼成一个 payload_t（常量字段每路都喂同一个值）
  payload_t [N-1:0] in_payload;
  assign in_payload[0] = '{
    qos: 4'hE,
    tgtID: io_in_0_bits_tgtID,
    txnID: io_in_0_bits_txnID,
    opcode: io_in_0_bits_opcode,
    size: 3'h6,
    addr: io_in_0_bits_addr,
    likelyshared: io_in_0_bits_likelyshared,
    allowRetry: io_in_0_bits_allowRetry,
    pCrdType: io_in_0_bits_pCrdType,
    memAttr_allocate: io_in_0_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_0_bits_expCompAck
  };
  assign in_payload[1] = '{
    qos: 4'hE,
    tgtID: io_in_1_bits_tgtID,
    txnID: io_in_1_bits_txnID,
    opcode: io_in_1_bits_opcode,
    size: 3'h6,
    addr: io_in_1_bits_addr,
    likelyshared: io_in_1_bits_likelyshared,
    allowRetry: io_in_1_bits_allowRetry,
    pCrdType: io_in_1_bits_pCrdType,
    memAttr_allocate: io_in_1_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_1_bits_expCompAck
  };
  assign in_payload[2] = '{
    qos: 4'hE,
    tgtID: io_in_2_bits_tgtID,
    txnID: io_in_2_bits_txnID,
    opcode: io_in_2_bits_opcode,
    size: 3'h6,
    addr: io_in_2_bits_addr,
    likelyshared: io_in_2_bits_likelyshared,
    allowRetry: io_in_2_bits_allowRetry,
    pCrdType: io_in_2_bits_pCrdType,
    memAttr_allocate: io_in_2_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_2_bits_expCompAck
  };
  assign in_payload[3] = '{
    qos: 4'hE,
    tgtID: io_in_3_bits_tgtID,
    txnID: io_in_3_bits_txnID,
    opcode: io_in_3_bits_opcode,
    size: 3'h6,
    addr: io_in_3_bits_addr,
    likelyshared: io_in_3_bits_likelyshared,
    allowRetry: io_in_3_bits_allowRetry,
    pCrdType: io_in_3_bits_pCrdType,
    memAttr_allocate: io_in_3_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_3_bits_expCompAck
  };
  assign in_payload[4] = '{
    qos: 4'hE,
    tgtID: io_in_4_bits_tgtID,
    txnID: io_in_4_bits_txnID,
    opcode: io_in_4_bits_opcode,
    size: 3'h6,
    addr: io_in_4_bits_addr,
    likelyshared: io_in_4_bits_likelyshared,
    allowRetry: io_in_4_bits_allowRetry,
    pCrdType: io_in_4_bits_pCrdType,
    memAttr_allocate: io_in_4_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_4_bits_expCompAck
  };
  assign in_payload[5] = '{
    qos: 4'hE,
    tgtID: io_in_5_bits_tgtID,
    txnID: io_in_5_bits_txnID,
    opcode: io_in_5_bits_opcode,
    size: 3'h6,
    addr: io_in_5_bits_addr,
    likelyshared: io_in_5_bits_likelyshared,
    allowRetry: io_in_5_bits_allowRetry,
    pCrdType: io_in_5_bits_pCrdType,
    memAttr_allocate: io_in_5_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_5_bits_expCompAck
  };
  assign in_payload[6] = '{
    qos: 4'hE,
    tgtID: io_in_6_bits_tgtID,
    txnID: io_in_6_bits_txnID,
    opcode: io_in_6_bits_opcode,
    size: 3'h6,
    addr: io_in_6_bits_addr,
    likelyshared: io_in_6_bits_likelyshared,
    allowRetry: io_in_6_bits_allowRetry,
    pCrdType: io_in_6_bits_pCrdType,
    memAttr_allocate: io_in_6_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_6_bits_expCompAck
  };
  assign in_payload[7] = '{
    qos: 4'hE,
    tgtID: io_in_7_bits_tgtID,
    txnID: io_in_7_bits_txnID,
    opcode: io_in_7_bits_opcode,
    size: 3'h6,
    addr: io_in_7_bits_addr,
    likelyshared: io_in_7_bits_likelyshared,
    allowRetry: io_in_7_bits_allowRetry,
    pCrdType: io_in_7_bits_pCrdType,
    memAttr_allocate: io_in_7_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_7_bits_expCompAck
  };
  assign in_payload[8] = '{
    qos: 4'hE,
    tgtID: io_in_8_bits_tgtID,
    txnID: io_in_8_bits_txnID,
    opcode: io_in_8_bits_opcode,
    size: 3'h6,
    addr: io_in_8_bits_addr,
    likelyshared: io_in_8_bits_likelyshared,
    allowRetry: io_in_8_bits_allowRetry,
    pCrdType: io_in_8_bits_pCrdType,
    memAttr_allocate: io_in_8_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_8_bits_expCompAck
  };
  assign in_payload[9] = '{
    qos: 4'hE,
    tgtID: io_in_9_bits_tgtID,
    txnID: io_in_9_bits_txnID,
    opcode: io_in_9_bits_opcode,
    size: 3'h6,
    addr: io_in_9_bits_addr,
    likelyshared: io_in_9_bits_likelyshared,
    allowRetry: io_in_9_bits_allowRetry,
    pCrdType: io_in_9_bits_pCrdType,
    memAttr_allocate: io_in_9_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_9_bits_expCompAck
  };
  assign in_payload[10] = '{
    qos: 4'hE,
    tgtID: io_in_10_bits_tgtID,
    txnID: io_in_10_bits_txnID,
    opcode: io_in_10_bits_opcode,
    size: 3'h6,
    addr: io_in_10_bits_addr,
    likelyshared: io_in_10_bits_likelyshared,
    allowRetry: io_in_10_bits_allowRetry,
    pCrdType: io_in_10_bits_pCrdType,
    memAttr_allocate: io_in_10_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_10_bits_expCompAck
  };
  assign in_payload[11] = '{
    qos: 4'hE,
    tgtID: io_in_11_bits_tgtID,
    txnID: io_in_11_bits_txnID,
    opcode: io_in_11_bits_opcode,
    size: 3'h6,
    addr: io_in_11_bits_addr,
    likelyshared: io_in_11_bits_likelyshared,
    allowRetry: io_in_11_bits_allowRetry,
    pCrdType: io_in_11_bits_pCrdType,
    memAttr_allocate: io_in_11_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_11_bits_expCompAck
  };
  assign in_payload[12] = '{
    qos: 4'hE,
    tgtID: io_in_12_bits_tgtID,
    txnID: io_in_12_bits_txnID,
    opcode: io_in_12_bits_opcode,
    size: 3'h6,
    addr: io_in_12_bits_addr,
    likelyshared: io_in_12_bits_likelyshared,
    allowRetry: io_in_12_bits_allowRetry,
    pCrdType: io_in_12_bits_pCrdType,
    memAttr_allocate: io_in_12_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_12_bits_expCompAck
  };
  assign in_payload[13] = '{
    qos: 4'hE,
    tgtID: io_in_13_bits_tgtID,
    txnID: io_in_13_bits_txnID,
    opcode: io_in_13_bits_opcode,
    size: 3'h6,
    addr: io_in_13_bits_addr,
    likelyshared: io_in_13_bits_likelyshared,
    allowRetry: io_in_13_bits_allowRetry,
    pCrdType: io_in_13_bits_pCrdType,
    memAttr_allocate: io_in_13_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_13_bits_expCompAck
  };
  assign in_payload[14] = '{
    qos: 4'hE,
    tgtID: io_in_14_bits_tgtID,
    txnID: io_in_14_bits_txnID,
    opcode: io_in_14_bits_opcode,
    size: 3'h6,
    addr: io_in_14_bits_addr,
    likelyshared: io_in_14_bits_likelyshared,
    allowRetry: io_in_14_bits_allowRetry,
    pCrdType: io_in_14_bits_pCrdType,
    memAttr_allocate: io_in_14_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_14_bits_expCompAck
  };
  assign in_payload[15] = '{
    qos: 4'hE,
    tgtID: io_in_15_bits_tgtID,
    txnID: io_in_15_bits_txnID,
    opcode: io_in_15_bits_opcode,
    size: 3'h6,
    addr: io_in_15_bits_addr,
    likelyshared: io_in_15_bits_likelyshared,
    allowRetry: io_in_15_bits_allowRetry,
    pCrdType: io_in_15_bits_pCrdType,
    memAttr_allocate: io_in_15_bits_memAttr_allocate,
    memAttr_cacheable: 1'h1,
    memAttr_ewa: 1'h1,
    snpAttr: 1'h1,
    expCompAck: io_in_15_bits_expCompAck
  };

  // ---- 核例化：仲裁逻辑全在 xs_FastArbiter_core
  payload_t out_payload;
  xs_FastArbiter_core #(.N(N), .W(W)) u_core (
    .clock     (clock),
    .reset     (reset),
    .in_valid  ({io_in_15_valid, io_in_14_valid, io_in_13_valid, io_in_12_valid,
                 io_in_11_valid, io_in_10_valid, io_in_9_valid, io_in_8_valid,
                 io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                 io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid}),
    .in_bits   (in_payload),
    .in_ready  ({io_in_15_ready, io_in_14_ready, io_in_13_ready, io_in_12_ready,
                 io_in_11_ready, io_in_10_ready, io_in_9_ready, io_in_8_ready,
                 io_in_7_ready, io_in_6_ready, io_in_5_ready, io_in_4_ready,
                 io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready}),
    .out_ready (io_out_ready),
    .out_valid (io_out_valid),
    .out_bits  (out_payload)
  );

  // ---- 拆包：与打包共用同一张字段表
  assign io_out_bits_qos = out_payload.qos;
  assign io_out_bits_tgtID = out_payload.tgtID;
  assign io_out_bits_txnID = out_payload.txnID;
  assign io_out_bits_opcode = out_payload.opcode;
  assign io_out_bits_size = out_payload.size;
  assign io_out_bits_addr = out_payload.addr;
  assign io_out_bits_likelyshared = out_payload.likelyshared;
  assign io_out_bits_allowRetry = out_payload.allowRetry;
  assign io_out_bits_pCrdType = out_payload.pCrdType;
  assign io_out_bits_memAttr_allocate = out_payload.memAttr_allocate;
  assign io_out_bits_memAttr_cacheable = out_payload.memAttr_cacheable;
  assign io_out_bits_memAttr_ewa = out_payload.memAttr_ewa;
  assign io_out_bits_snpAttr = out_payload.snpAttr;
  assign io_out_bits_expCompAck = out_payload.expCompAck;
endmodule
