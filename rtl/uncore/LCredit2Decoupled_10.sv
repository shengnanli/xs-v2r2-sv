// =============================================================================
//  LCredit2Decoupled_10 —— CHI 链路层 接收侧 握手转换 可读重写核 (xs_LCredit2Decoupled_10_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/LinkLayer.scala (class LCredit2Decoupled)
//  与 LCredit2Decoupled 同型 (信用记账 + LCrdReturn 过滤 + blocking 队列), lcreditNum=4,
//  仅净荷/队列不同: 本变体 = DAT(422b) (队列 Queue4_CHIDAT, 黑盒)。控制注释见 LCredit2Decoupled.sv。
//  不变式: lcreditInflight + lcreditPool === 4。LinkStates: RUN=2。
// =============================================================================
module xs_LCredit2Decoupled_10_core(
  input          clock,
  input          reset,
  input          io_in_flitv,
  input  [421:0] io_in_flit,
  output         io_in_lcrdv,
  input          io_out_ready,
  output         io_out_valid,
  output [3:0]   io_out_bits_qos,
  output [10:0]  io_out_bits_tgtID,
  output [10:0]  io_out_bits_srcID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_homeNID,
  output [3:0]   io_out_bits_opcode,
  output [1:0]   io_out_bits_respErr,
  output [2:0]   io_out_bits_resp,
  output [3:0]   io_out_bits_dataSource,
  output [2:0]   io_out_bits_cBusy,
  output [11:0]  io_out_bits_dbID,
  output [1:0]   io_out_bits_ccID,
  output [1:0]   io_out_bits_dataID,
  output [1:0]   io_out_bits_tagOp,
  output [7:0]   io_out_bits_tag,
  output [1:0]   io_out_bits_tu,
  output         io_out_bits_traceTag,
  output [3:0]   io_out_bits_rsvdc,
  output [31:0]  io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0]  io_out_bits_dataCheck,
  output [3:0]   io_out_bits_poison,
  input  [1:0]   io_state_state,
  output         io_reclaimLCredit
);

  reg  [2:0] lcreditInflight;
  reg  [2:0] lcreditPool;
  reg        in_lcrdv_q;

  wire [2:0] queue_count;
  wire       queue_enq_ready;
  wire       queue_deq_valid;
  wire [3:0] queue_deq_opcode;

  wire accept     = (|lcreditInflight) & io_in_flitv;
  wire lcreditOut = (lcreditPool > queue_count) & (io_state_state == 2'h2); // RUN

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      lcreditInflight <= 3'h0;
      lcreditPool     <= 3'h4;   // lcreditNum = 4
      in_lcrdv_q      <= 1'h0;
    end
    else begin
      if (lcreditOut) begin
        if (~accept) begin
          lcreditInflight <= lcreditInflight + 3'h1;
          lcreditPool     <= lcreditPool - 3'h1;
        end
      end
      else if (accept) begin
        lcreditInflight <= lcreditInflight - 3'h1;
        lcreditPool     <= lcreditPool + 3'h1;
      end
      in_lcrdv_q <= lcreditOut;
    end
  end

  assign io_in_lcrdv       = in_lcrdv_q;
  assign io_reclaimLCredit = lcreditInflight == 3'h0;

  // LCrdReturn (opcode==0) 空 flit: 吞掉不输出
  wire isLCrdReturn = queue_deq_valid & (queue_deq_opcode == 4'h0);
  assign io_out_valid       = ~isLCrdReturn & queue_deq_valid;
  assign io_out_bits_opcode = queue_deq_opcode;

  Queue4_CHIDAT queue (
    .clock                  (clock),
    .reset                  (reset),
    .io_enq_ready           (queue_enq_ready),
    .io_enq_valid           (accept),
    .io_enq_bits_qos        (io_in_flit[3:0]),
    .io_enq_bits_tgtID      (io_in_flit[14:4]),
    .io_enq_bits_srcID      (io_in_flit[25:15]),
    .io_enq_bits_txnID      (io_in_flit[37:26]),
    .io_enq_bits_homeNID    (io_in_flit[48:38]),
    .io_enq_bits_opcode     (io_in_flit[52:49]),
    .io_enq_bits_respErr    (io_in_flit[54:53]),
    .io_enq_bits_resp       (io_in_flit[57:55]),
    .io_enq_bits_dataSource (io_in_flit[61:58]),
    .io_enq_bits_cBusy      (io_in_flit[64:62]),
    .io_enq_bits_dbID       (io_in_flit[76:65]),
    .io_enq_bits_ccID       (io_in_flit[78:77]),
    .io_enq_bits_dataID     (io_in_flit[80:79]),
    .io_enq_bits_tagOp      (io_in_flit[82:81]),
    .io_enq_bits_tag        (io_in_flit[90:83]),
    .io_enq_bits_tu         (io_in_flit[92:91]),
    .io_enq_bits_traceTag   (io_in_flit[93]),
    .io_enq_bits_rsvdc      (io_in_flit[97:94]),
    .io_enq_bits_be         (io_in_flit[129:98]),
    .io_enq_bits_data       (io_in_flit[385:130]),
    .io_enq_bits_dataCheck  (io_in_flit[417:386]),
    .io_enq_bits_poison     (io_in_flit[421:418]),
    .io_deq_ready           (isLCrdReturn | io_out_ready),
    .io_deq_valid           (queue_deq_valid),
    .io_deq_bits_qos        (io_out_bits_qos),
    .io_deq_bits_tgtID      (io_out_bits_tgtID),
    .io_deq_bits_srcID      (io_out_bits_srcID),
    .io_deq_bits_txnID      (io_out_bits_txnID),
    .io_deq_bits_homeNID    (io_out_bits_homeNID),
    .io_deq_bits_opcode     (queue_deq_opcode),
    .io_deq_bits_respErr    (io_out_bits_respErr),
    .io_deq_bits_resp       (io_out_bits_resp),
    .io_deq_bits_dataSource (io_out_bits_dataSource),
    .io_deq_bits_cBusy      (io_out_bits_cBusy),
    .io_deq_bits_dbID       (io_out_bits_dbID),
    .io_deq_bits_ccID       (io_out_bits_ccID),
    .io_deq_bits_dataID     (io_out_bits_dataID),
    .io_deq_bits_tagOp      (io_out_bits_tagOp),
    .io_deq_bits_tag        (io_out_bits_tag),
    .io_deq_bits_tu         (io_out_bits_tu),
    .io_deq_bits_traceTag   (io_out_bits_traceTag),
    .io_deq_bits_rsvdc      (io_out_bits_rsvdc),
    .io_deq_bits_be         (io_out_bits_be),
    .io_deq_bits_data       (io_out_bits_data),
    .io_deq_bits_dataCheck  (io_out_bits_dataCheck),
    .io_deq_bits_poison     (io_out_bits_poison),
    .io_count               (queue_count)
  );

endmodule
