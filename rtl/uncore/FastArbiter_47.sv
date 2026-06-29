// =============================================================================
//  FastArbiter_47 —— CHI TXREQ 4 路 round-robin 仲裁器 (可读核 xs_FastArbiter_47_core)
// -----------------------------------------------------------------------------
//  SNXbar 上行: 4 个 RN 主口的 TXREQ (CHI 请求通道) 经本仲裁器轮转选一路发往 SN。
//  payload = CHI REQ flit 子集 (tgtID/srcID/txnID/opcode/size/addr/order/memAttr...)。
//  仲裁算法见 fastarbiter_pkg (pendingMask/rrGrantMask 轮转 + chosenOH one-hot 选择);
//  本核只负责把 payload 打包成 struct, 用胜者 one-hot OR 归约多路选择到 io_out。
//  无 io_in_ready 端口 (SNXbar 用 io_chosen 自行回送), 下游背压只看 io_out_ready。
// =============================================================================
module xs_FastArbiter_47_core
  import fastarbiter_pkg::*;
(
  input         clock,
  input         reset,
  input         io_in_0_valid,
  input  [10:0] io_in_0_bits_tgtID,
  input  [10:0] io_in_0_bits_srcID,
  input  [11:0] io_in_0_bits_txnID,
  input  [6:0]  io_in_0_bits_opcode,
  input  [2:0]  io_in_0_bits_size,
  input  [47:0] io_in_0_bits_addr,
  input         io_in_0_bits_allowRetry,
  input  [1:0]  io_in_0_bits_order,
  input  [3:0]  io_in_0_bits_pCrdType,
  input         io_in_0_bits_memAttr_allocate,
  input         io_in_0_bits_memAttr_cacheable,
  input         io_in_0_bits_memAttr_device,
  input         io_in_0_bits_memAttr_ewa,
  input         io_in_0_bits_snpAttr,
  input         io_in_0_bits_expCompAck,
  input         io_in_1_valid,
  input  [10:0] io_in_1_bits_tgtID,
  input  [10:0] io_in_1_bits_srcID,
  input  [11:0] io_in_1_bits_txnID,
  input  [6:0]  io_in_1_bits_opcode,
  input  [2:0]  io_in_1_bits_size,
  input  [47:0] io_in_1_bits_addr,
  input         io_in_1_bits_allowRetry,
  input  [1:0]  io_in_1_bits_order,
  input  [3:0]  io_in_1_bits_pCrdType,
  input         io_in_1_bits_memAttr_allocate,
  input         io_in_1_bits_memAttr_cacheable,
  input         io_in_1_bits_memAttr_device,
  input         io_in_1_bits_memAttr_ewa,
  input         io_in_1_bits_snpAttr,
  input         io_in_1_bits_expCompAck,
  input         io_in_2_valid,
  input  [10:0] io_in_2_bits_tgtID,
  input  [10:0] io_in_2_bits_srcID,
  input  [11:0] io_in_2_bits_txnID,
  input  [6:0]  io_in_2_bits_opcode,
  input  [2:0]  io_in_2_bits_size,
  input  [47:0] io_in_2_bits_addr,
  input         io_in_2_bits_allowRetry,
  input  [1:0]  io_in_2_bits_order,
  input  [3:0]  io_in_2_bits_pCrdType,
  input         io_in_2_bits_memAttr_allocate,
  input         io_in_2_bits_memAttr_cacheable,
  input         io_in_2_bits_memAttr_device,
  input         io_in_2_bits_memAttr_ewa,
  input         io_in_2_bits_snpAttr,
  input         io_in_2_bits_expCompAck,
  input         io_in_3_valid,
  input  [10:0] io_in_3_bits_tgtID,
  input  [10:0] io_in_3_bits_srcID,
  input  [11:0] io_in_3_bits_txnID,
  input  [6:0]  io_in_3_bits_opcode,
  input  [2:0]  io_in_3_bits_size,
  input  [47:0] io_in_3_bits_addr,
  input         io_in_3_bits_allowRetry,
  input  [1:0]  io_in_3_bits_order,
  input  [3:0]  io_in_3_bits_pCrdType,
  input         io_in_3_bits_memAttr_allocate,
  input         io_in_3_bits_memAttr_cacheable,
  input         io_in_3_bits_memAttr_device,
  input         io_in_3_bits_memAttr_ewa,
  input         io_in_3_bits_snpAttr,
  input         io_in_3_bits_expCompAck,
  input         io_out_ready,
  output        io_out_valid,
  output [10:0] io_out_bits_tgtID,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [6:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_size,
  output [47:0] io_out_bits_addr,
  output        io_out_bits_allowRetry,
  output [1:0]  io_out_bits_order,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_memAttr_allocate,
  output        io_out_bits_memAttr_cacheable,
  output        io_out_bits_memAttr_device,
  output        io_out_bits_memAttr_ewa,
  output        io_out_bits_snpAttr,
  output        io_out_bits_expCompAck,
  output [IDXW-1:0] io_chosen
);

  // ---- CHI REQ flit payload (打包成 packed struct, 便于 one-hot OR 多路选择) ----
  typedef struct packed {
    logic [10:0] tgtID;
    logic [10:0] srcID;
    logic [11:0] txnID;
    logic [6:0]  opcode;
    logic [2:0]  size;
    logic [47:0] addr;
    logic        allowRetry;
    logic [1:0]  order;
    logic [3:0]  pCrdType;
    logic        memAttr_allocate;
    logic        memAttr_cacheable;
    logic        memAttr_device;
    logic        memAttr_ewa;
    logic        snpAttr;
    logic        expCompAck;
  } req_t;

  req_t            pin [NUM];
  logic [NUM-1:0]  valids;

  assign valids = {io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};

  assign pin[0] = '{tgtID:io_in_0_bits_tgtID, srcID:io_in_0_bits_srcID, txnID:io_in_0_bits_txnID,
                    opcode:io_in_0_bits_opcode, size:io_in_0_bits_size, addr:io_in_0_bits_addr,
                    allowRetry:io_in_0_bits_allowRetry, order:io_in_0_bits_order,
                    pCrdType:io_in_0_bits_pCrdType, memAttr_allocate:io_in_0_bits_memAttr_allocate,
                    memAttr_cacheable:io_in_0_bits_memAttr_cacheable,
                    memAttr_device:io_in_0_bits_memAttr_device, memAttr_ewa:io_in_0_bits_memAttr_ewa,
                    snpAttr:io_in_0_bits_snpAttr, expCompAck:io_in_0_bits_expCompAck};
  assign pin[1] = '{tgtID:io_in_1_bits_tgtID, srcID:io_in_1_bits_srcID, txnID:io_in_1_bits_txnID,
                    opcode:io_in_1_bits_opcode, size:io_in_1_bits_size, addr:io_in_1_bits_addr,
                    allowRetry:io_in_1_bits_allowRetry, order:io_in_1_bits_order,
                    pCrdType:io_in_1_bits_pCrdType, memAttr_allocate:io_in_1_bits_memAttr_allocate,
                    memAttr_cacheable:io_in_1_bits_memAttr_cacheable,
                    memAttr_device:io_in_1_bits_memAttr_device, memAttr_ewa:io_in_1_bits_memAttr_ewa,
                    snpAttr:io_in_1_bits_snpAttr, expCompAck:io_in_1_bits_expCompAck};
  assign pin[2] = '{tgtID:io_in_2_bits_tgtID, srcID:io_in_2_bits_srcID, txnID:io_in_2_bits_txnID,
                    opcode:io_in_2_bits_opcode, size:io_in_2_bits_size, addr:io_in_2_bits_addr,
                    allowRetry:io_in_2_bits_allowRetry, order:io_in_2_bits_order,
                    pCrdType:io_in_2_bits_pCrdType, memAttr_allocate:io_in_2_bits_memAttr_allocate,
                    memAttr_cacheable:io_in_2_bits_memAttr_cacheable,
                    memAttr_device:io_in_2_bits_memAttr_device, memAttr_ewa:io_in_2_bits_memAttr_ewa,
                    snpAttr:io_in_2_bits_snpAttr, expCompAck:io_in_2_bits_expCompAck};
  assign pin[3] = '{tgtID:io_in_3_bits_tgtID, srcID:io_in_3_bits_srcID, txnID:io_in_3_bits_txnID,
                    opcode:io_in_3_bits_opcode, size:io_in_3_bits_size, addr:io_in_3_bits_addr,
                    allowRetry:io_in_3_bits_allowRetry, order:io_in_3_bits_order,
                    pCrdType:io_in_3_bits_pCrdType, memAttr_allocate:io_in_3_bits_memAttr_allocate,
                    memAttr_cacheable:io_in_3_bits_memAttr_cacheable,
                    memAttr_device:io_in_3_bits_memAttr_device, memAttr_ewa:io_in_3_bits_memAttr_ewa,
                    snpAttr:io_in_3_bits_snpAttr, expCompAck:io_in_3_bits_expCompAck};

  // ---- round-robin 状态 + 组合选胜 ----
  reg   [NUM-1:0] pendingMask;
  reg   [NUM-1:0] rrGrantMask;
  logic [NUM-1:0] chosenOH;

  assign chosenOH = rr_choose(valids, pendingMask, rrGrantMask);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pendingMask <= '0;
      rrGrantMask <= '0;
    end else if (io_out_ready & (|valids)) begin
      pendingMask <= valids & ~chosenOH;     // 没被选中的 valid 转入欠服务
      rrGrantMask <= gt_mask(chosenOH);      // 优先区推进到本次胜者之后
    end
  end

  // ---- 胜者 payload 多路选择 (one-hot OR 归约, chosenOH 至多一位置位) ----
  req_t psel;
  always_comb begin
    psel = '0;
    for (int i = 0; i < NUM; i++)
      if (chosenOH[i]) psel |= pin[i];
  end

  assign io_out_valid                 = |valids;
  assign io_out_bits_tgtID            = psel.tgtID;
  assign io_out_bits_srcID            = psel.srcID;
  assign io_out_bits_txnID            = psel.txnID;
  assign io_out_bits_opcode           = psel.opcode;
  assign io_out_bits_size             = psel.size;
  assign io_out_bits_addr             = psel.addr;
  assign io_out_bits_allowRetry       = psel.allowRetry;
  assign io_out_bits_order            = psel.order;
  assign io_out_bits_pCrdType         = psel.pCrdType;
  assign io_out_bits_memAttr_allocate = psel.memAttr_allocate;
  assign io_out_bits_memAttr_cacheable= psel.memAttr_cacheable;
  assign io_out_bits_memAttr_device   = psel.memAttr_device;
  assign io_out_bits_memAttr_ewa      = psel.memAttr_ewa;
  assign io_out_bits_snpAttr          = psel.snpAttr;
  assign io_out_bits_expCompAck       = psel.expCompAck;
  assign io_chosen                    = encode_oh(chosenOH);

endmodule
