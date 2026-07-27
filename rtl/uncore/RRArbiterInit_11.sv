// =============================================================================
//  xs_RRArbiterInit_11_core —— 8 输入 round-robin 仲裁器可读核 (Chisel RRArbiter)。
//  见 RRArbiterInit_11_wrapper.sv 头注释描述算法与逐位等价关系。
// =============================================================================
// ---- 可读 round-robin 核 ----
module xs_RRArbiterInit_11_core (
  input         clock,
  input         reset,
  output        io_in_0_ready, input io_in_0_valid,
  input  [11:0] io_in_0_bits_txnID, input [6:0] io_in_0_bits_opcode, input [2:0] io_in_0_bits_size,
  input  [47:0] io_in_0_bits_addr, input io_in_0_bits_allowRetry, input [1:0] io_in_0_bits_order,
  input  [3:0]  io_in_0_bits_pCrdType, input io_in_0_bits_memAttr_device, input io_in_0_bits_memAttr_ewa,
  output        io_in_1_ready, input io_in_1_valid,
  input  [11:0] io_in_1_bits_txnID, input [6:0] io_in_1_bits_opcode, input [2:0] io_in_1_bits_size,
  input  [47:0] io_in_1_bits_addr, input io_in_1_bits_allowRetry, input [1:0] io_in_1_bits_order,
  input  [3:0]  io_in_1_bits_pCrdType, input io_in_1_bits_memAttr_device, input io_in_1_bits_memAttr_ewa,
  output        io_in_2_ready, input io_in_2_valid,
  input  [11:0] io_in_2_bits_txnID, input [6:0] io_in_2_bits_opcode, input [2:0] io_in_2_bits_size,
  input  [47:0] io_in_2_bits_addr, input io_in_2_bits_allowRetry, input [1:0] io_in_2_bits_order,
  input  [3:0]  io_in_2_bits_pCrdType, input io_in_2_bits_memAttr_device, input io_in_2_bits_memAttr_ewa,
  output        io_in_3_ready, input io_in_3_valid,
  input  [11:0] io_in_3_bits_txnID, input [6:0] io_in_3_bits_opcode, input [2:0] io_in_3_bits_size,
  input  [47:0] io_in_3_bits_addr, input io_in_3_bits_allowRetry, input [1:0] io_in_3_bits_order,
  input  [3:0]  io_in_3_bits_pCrdType, input io_in_3_bits_memAttr_device, input io_in_3_bits_memAttr_ewa,
  output        io_in_4_ready, input io_in_4_valid,
  input  [11:0] io_in_4_bits_txnID, input [6:0] io_in_4_bits_opcode, input [2:0] io_in_4_bits_size,
  input  [47:0] io_in_4_bits_addr, input io_in_4_bits_allowRetry, input [1:0] io_in_4_bits_order,
  input  [3:0]  io_in_4_bits_pCrdType, input io_in_4_bits_memAttr_device, input io_in_4_bits_memAttr_ewa,
  output        io_in_5_ready, input io_in_5_valid,
  input  [11:0] io_in_5_bits_txnID, input [6:0] io_in_5_bits_opcode, input [2:0] io_in_5_bits_size,
  input  [47:0] io_in_5_bits_addr, input io_in_5_bits_allowRetry, input [1:0] io_in_5_bits_order,
  input  [3:0]  io_in_5_bits_pCrdType, input io_in_5_bits_memAttr_device, input io_in_5_bits_memAttr_ewa,
  output        io_in_6_ready, input io_in_6_valid,
  input  [11:0] io_in_6_bits_txnID, input [6:0] io_in_6_bits_opcode, input [2:0] io_in_6_bits_size,
  input  [47:0] io_in_6_bits_addr, input io_in_6_bits_allowRetry, input [1:0] io_in_6_bits_order,
  input  [3:0]  io_in_6_bits_pCrdType, input io_in_6_bits_memAttr_device, input io_in_6_bits_memAttr_ewa,
  output        io_in_7_ready, input io_in_7_valid,
  input  [11:0] io_in_7_bits_txnID, input [6:0] io_in_7_bits_opcode, input [2:0] io_in_7_bits_size,
  input  [47:0] io_in_7_bits_addr, input io_in_7_bits_allowRetry, input [1:0] io_in_7_bits_order,
  input  [3:0]  io_in_7_bits_pCrdType, input io_in_7_bits_memAttr_device, input io_in_7_bits_memAttr_ewa,
  input         io_out_ready,
  output        io_out_valid,
  output [11:0] io_out_bits_txnID,
  output [6:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_size,
  output [47:0] io_out_bits_addr,
  output        io_out_bits_allowRetry,
  output [1:0]  io_out_bits_order,
  output [3:0]  io_out_bits_pCrdType,
  output        io_out_bits_memAttr_device,
  output        io_out_bits_memAttr_ewa
);
  localparam int unsigned NUM = 8;

  // payload 打包 (与端口宽度一致): txnID(12)|opcode(7)|size(3)|addr(48)|allowRetry(1)|order(2)|pCrdType(4)|device(1)|ewa(1) = 79 位
  localparam int unsigned W = 79;
  logic [7:0]     valids;
  logic [W-1:0]   pin [NUM];
  assign valids = {io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                   io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign pin[0] = {io_in_0_bits_txnID, io_in_0_bits_opcode, io_in_0_bits_size, io_in_0_bits_addr,
                   io_in_0_bits_allowRetry, io_in_0_bits_order, io_in_0_bits_pCrdType,
                   io_in_0_bits_memAttr_device, io_in_0_bits_memAttr_ewa};
  assign pin[1] = {io_in_1_bits_txnID, io_in_1_bits_opcode, io_in_1_bits_size, io_in_1_bits_addr,
                   io_in_1_bits_allowRetry, io_in_1_bits_order, io_in_1_bits_pCrdType,
                   io_in_1_bits_memAttr_device, io_in_1_bits_memAttr_ewa};
  assign pin[2] = {io_in_2_bits_txnID, io_in_2_bits_opcode, io_in_2_bits_size, io_in_2_bits_addr,
                   io_in_2_bits_allowRetry, io_in_2_bits_order, io_in_2_bits_pCrdType,
                   io_in_2_bits_memAttr_device, io_in_2_bits_memAttr_ewa};
  assign pin[3] = {io_in_3_bits_txnID, io_in_3_bits_opcode, io_in_3_bits_size, io_in_3_bits_addr,
                   io_in_3_bits_allowRetry, io_in_3_bits_order, io_in_3_bits_pCrdType,
                   io_in_3_bits_memAttr_device, io_in_3_bits_memAttr_ewa};
  assign pin[4] = {io_in_4_bits_txnID, io_in_4_bits_opcode, io_in_4_bits_size, io_in_4_bits_addr,
                   io_in_4_bits_allowRetry, io_in_4_bits_order, io_in_4_bits_pCrdType,
                   io_in_4_bits_memAttr_device, io_in_4_bits_memAttr_ewa};
  assign pin[5] = {io_in_5_bits_txnID, io_in_5_bits_opcode, io_in_5_bits_size, io_in_5_bits_addr,
                   io_in_5_bits_allowRetry, io_in_5_bits_order, io_in_5_bits_pCrdType,
                   io_in_5_bits_memAttr_device, io_in_5_bits_memAttr_ewa};
  assign pin[6] = {io_in_6_bits_txnID, io_in_6_bits_opcode, io_in_6_bits_size, io_in_6_bits_addr,
                   io_in_6_bits_allowRetry, io_in_6_bits_order, io_in_6_bits_pCrdType,
                   io_in_6_bits_memAttr_device, io_in_6_bits_memAttr_ewa};
  assign pin[7] = {io_in_7_bits_txnID, io_in_7_bits_opcode, io_in_7_bits_size, io_in_7_bits_addr,
                   io_in_7_bits_allowRetry, io_in_7_bits_order, io_in_7_bits_pCrdType,
                   io_in_7_bits_memAttr_device, io_in_7_bits_memAttr_ewa};

  reg [2:0] lastGrant;

  // grantMask[i] = (lastGrant < i); index 0 无 mask 项 (从 1 起做 masked 轮)。
  logic [7:0] grantMask;
  always_comb
    for (int i = 0; i < NUM; i++)
      grantMask[i] = (3'(i) > lastGrant);

  // masked 轮候选: validMask[i] = valids[i] & grantMask[i] (i=1..7)。
  logic [7:0] validMask;
  always_comb begin
    validMask = '0;
    for (int i = 1; i < NUM; i++)
      validMask[i] = valids[i] & grantMask[i];
  end

  // masked 轮里取最低下标 (下标最小者优先, RRArbiter 语义)。
  logic       maskedHit;
  logic [2:0] maskedIdx;
  always_comb begin
    maskedHit = 1'b0;
    maskedIdx = 3'h0;
    for (int i = NUM - 1; i >= 1; i--)
      if (validMask[i]) begin maskedHit = 1'b1; maskedIdx = 3'(i); end
  end

  // 退化 base 轮: 全 valids 里取最低下标 (全 0 时为 7, 与 golden {2'h3,~io_in_6_valid} 一致)。
  logic [2:0] baseIdx;
  always_comb begin
    baseIdx = {2'h3, ~io_in_6_valid};  // = io_in_6_valid?6:7
    for (int i = NUM - 2; i >= 0; i--)
      if (valids[i]) baseIdx = 3'(i);
  end

  logic [2:0] chosen;
  assign chosen = maskedHit ? maskedIdx : baseIdx;

  wire out_valid = valids[chosen];

  always @(posedge clock or posedge reset) begin
    if (reset)
      lastGrant <= 3'h0;
    else if (io_out_ready & out_valid)
      lastGrant <= chosen;
  end

  // ---- ready = grant(i) & out_ready ----
  // Chisel Arbiter 语义: grant(i) = "轮转优先序里排在 i 前面的输入都没请求"。ready 不
  // 门控 i 自身 valid (未请求也可 ready = "若请求会被 grant")。golden 用两段前缀-OR:
  //   前缀段 A: masked 轮候选 validMask_1..7 的累积 OR (_A6 = 是否有 masked 候选)
  //   前缀段 B: 从 _A6 起再依次 OR 进 io_in_0..5_valid (base 轮低下标累积)
  // 各路 grant 表达式逐位照搬 golden。
  wire vm1 = io_in_1_valid & grantMask[1];
  wire vm2 = io_in_2_valid & grantMask[2];
  wire vm3 = io_in_3_valid & grantMask[3];
  wire vm4 = io_in_4_valid & grantMask[4];
  wire vm5 = io_in_5_valid & grantMask[5];
  wire vm6 = io_in_6_valid & grantMask[6];
  wire vm7 = io_in_7_valid & grantMask[7];
  wire a1 = vm1 | vm2;
  wire a2 = a1  | vm3;
  wire a3 = a2  | vm4;
  wire a4 = a3  | vm5;
  wire a5 = a4  | vm6;
  wire a6 = a5  | vm7;                 // 有任一 masked 候选
  wire b7  = a6  | io_in_0_valid;
  wire b8  = b7  | io_in_1_valid;
  wire b9  = b8  | io_in_2_valid;
  wire b10 = b9  | io_in_3_valid;
  wire b11 = b10 | io_in_4_valid;
  wire b12 = b11 | io_in_5_valid;
  assign io_in_0_ready = ~a6 & io_out_ready;
  assign io_in_1_ready = (grantMask[1] | ~b7 ) & io_out_ready;
  assign io_in_2_ready = (~vm1 & grantMask[2] | ~b8 ) & io_out_ready;
  assign io_in_3_ready = (~a1  & grantMask[3] | ~b9 ) & io_out_ready;
  assign io_in_4_ready = (~a2  & grantMask[4] | ~b10) & io_out_ready;
  assign io_in_5_ready = (~a3  & grantMask[5] | ~b11) & io_out_ready;
  assign io_in_6_ready = (~a4  & grantMask[6] | ~b12) & io_out_ready;
  assign io_in_7_ready = (~a5  & grantMask[7] | ~(b12 | io_in_6_valid)) & io_out_ready;

  logic [W-1:0] pout;
  assign pout = pin[chosen];

  assign io_out_valid            = out_valid;
  assign io_out_bits_txnID       = pout[78:67];
  assign io_out_bits_opcode      = pout[66:60];
  assign io_out_bits_size        = pout[59:57];
  assign io_out_bits_addr        = pout[56:9];
  assign io_out_bits_allowRetry  = pout[8];
  assign io_out_bits_order       = pout[7:6];
  assign io_out_bits_pCrdType    = pout[5:2];
  assign io_out_bits_memAttr_device = pout[1];
  assign io_out_bits_memAttr_ewa    = pout[0];
endmodule
