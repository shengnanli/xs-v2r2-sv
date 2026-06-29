// =============================================================================
//  LCredit2Decoupled_1 —— CHI 链路层 接收侧 握手转换 (非阻塞) 可读重写核
//                          (xs_LCredit2Decoupled_1_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/LinkLayer.scala (class LCredit2Decoupled, blocking=false)
//  接收对端 CHI 链路层 flit, 解包成内部 DecoupledIO。本变体: RSP 通道 (payload 73b),
//  lcreditNum=15, blocking=false ⇒ 无缓冲队列, 直接解包输出 (假定下游恒 ready)。
//
//  ===== L-Credit 授信 (5 位池, 不变式 inflight+pool === 15) =====
//    accept     = lcreditInflight!=0 & in.flitv
//    lcreditOut = lcreditPool!=0 & state==RUN     (非阻塞: 只看池非空, 不看队列占用)
//    in.lcrdv   = RegNext(lcreditOut)
//    更新: lcreditOut&~accept ⇒ inflight+1/pool-1 ; ~lcreditOut&accept ⇒ inflight-1/pool+1
//    reclaimLCredit = lcreditInflight==0
//
//  ===== LCrdReturn 过滤 =====
//    isLCrdReturn = (opcode==0) ; out.valid = accept & ~isLCrdReturn
//    out.bits 直接由 in.flit 各位段解包 (无队列缓冲)。
// =============================================================================
module xs_LCredit2Decoupled_1_core (
  input         clock,
  input         reset,
  // ---- io.in (Flipped ChannelIO, CHI 链路层 flit) ----
  input         io_in_flitv,
  input  [72:0] io_in_flit,
  output        io_in_lcrdv,
  // ---- io.out (DecoupledIO CHIRSP) ----
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output [10:0] io_out_bits_srcID,
  output [11:0] io_out_bits_txnID,
  output [4:0]  io_out_bits_opcode,
  output [1:0]  io_out_bits_respErr,
  output [2:0]  io_out_bits_resp,
  output [2:0]  io_out_bits_fwdState,
  output [2:0]  io_out_bits_cBusy,
  output [11:0] io_out_bits_dbID,
  output [3:0]  io_out_bits_pCrdType,
  output [1:0]  io_out_bits_tagOp,
  output        io_out_bits_traceTag,
  // ---- io.state / reclaim ----
  input  [1:0]  io_state_state,
  output        io_reclaimLCredit
);

  reg  [4:0] lcreditInflight;
  reg  [4:0] lcreditPool;
  reg        in_lcrdv_q;

  wire accept     = (|lcreditInflight) & io_in_flitv;
  wire lcreditOut = (|lcreditPool) & (io_state_state == 2'h2); // RUN

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      lcreditInflight <= 5'h0;
      lcreditPool     <= 5'hF;   // lcreditNum = 15
      in_lcrdv_q      <= 1'h0;
    end
    else begin
      if (lcreditOut) begin
        if (~accept) begin
          lcreditInflight <= lcreditInflight + 5'h1;
          lcreditPool     <= lcreditPool - 5'h1;
        end
      end
      else if (accept) begin
        lcreditInflight <= lcreditInflight - 5'h1;
        lcreditPool     <= lcreditPool + 5'h1;
      end
      in_lcrdv_q <= lcreditOut;
    end
  end

  assign io_in_lcrdv       = in_lcrdv_q;
  assign io_reclaimLCredit = lcreditInflight == 5'h0;

  // ---- 直接解包 (无队列); opcode==0 即 LCrdReturn, 不向下游输出 ----
  wire isLCrdReturn = (io_in_flit[42:38] == 5'h0);
  assign io_out_valid        = accept & ~isLCrdReturn;
  assign io_out_bits_qos     = io_in_flit[3:0];
  assign io_out_bits_tgtID   = io_in_flit[14:4];
  assign io_out_bits_srcID   = io_in_flit[25:15];
  assign io_out_bits_txnID   = io_in_flit[37:26];
  assign io_out_bits_opcode  = io_in_flit[42:38];
  assign io_out_bits_respErr = io_in_flit[44:43];
  assign io_out_bits_resp    = io_in_flit[47:45];
  assign io_out_bits_fwdState = io_in_flit[50:48];
  assign io_out_bits_cBusy   = io_in_flit[53:51];
  assign io_out_bits_dbID    = io_in_flit[65:54];
  assign io_out_bits_pCrdType = io_in_flit[69:66];
  assign io_out_bits_tagOp   = io_in_flit[71:70];
  assign io_out_bits_traceTag = io_in_flit[72];

endmodule
