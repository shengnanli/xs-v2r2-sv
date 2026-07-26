// =============================================================================
//  RRArbiterInit_18 —— 5 路 round-robin 仲裁器可读核 (xs_RRArbiterInit_18_core)
// -----------------------------------------------------------------------------
//  TL2CHICoupledL2 直接子: CHI TXREQ 通道 5 路 RRArbiter (Chisel utility.RRArbiter,
//  lastGrant 轮转)。前 4 路 (0..3) 是对称的 CHI REQ flit; 第 5 路 (io_in_4) 额外携带
//  size(3)/tgtID(11) 两个字段 (input-4 专属, 见 golden _GEN_9/_GEN_3)。
//
//  ---- Chisel RRArbiter 算法 (同 RRArbiterInit_11, 5 路) ----
//    lastGrant 寄存器 (复位 0, 记上次胜者下标)。
//    grantMask[i] = (lastGrant < i)  —— i 排在 lastGrant 之后才进 masked 轮。
//                   (golden: i=1 用 ==0; i=2 用 <2; i=3 用 <3; i=4 用 ~lastGrant[2]=<4)
//    masked 轮候选 validMask[i] = valid[i] & grantMask[i], i=1..4 (下标 0 不进 masked 轮)。
//    choice = 最低命中的 masked 候选下标; 若无, 退化 base 轮 = valids 里最低下标 (默认 4)。
//    io_out_valid = valid[choice]。胜者更新: io_out_ready & io_out_valid 时 lastGrant<=choice。
//    ready(i) = "轮转优先序里排在 i 前面的都没请求" & io_out_ready (Chisel Arbiter 语义,
//               不门控 i 自身 valid); 各路表达式逐位照搬 golden 的 _ctrl_T 前缀链。
//  payload: 共有字段 = input[choice]; input-4 专属 size/tgtID = (choice==4)?input4:常量。
//  io_chosen = choice。与 golden RRArbiterInit_18 逐位等价。
// =============================================================================
module xs_RRArbiterInit_18_core (
  input         clock,
  input         reset,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_qos,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_returnNID,
  input         io_in_0_bits_stashNIDValid,
  input  [11:0] io_in_0_bits_returnTxnID,
  input  [6:0]  io_in_0_bits_opcode,
  input  [47:0] io_in_0_bits_addr,
  input         io_in_0_bits_ns,
  input         io_in_0_bits_likelyshared,
  input         io_in_0_bits_allowRetry,
  input  [1:0]  io_in_0_bits_order,
  input  [3:0]  io_in_0_bits_pCrdType,
  input         io_in_0_bits_memAttr_allocate,
  input         io_in_0_bits_memAttr_cacheable,
  input         io_in_0_bits_memAttr_device,
  input         io_in_0_bits_memAttr_ewa,
  input         io_in_0_bits_snpAttr,
  input  [7:0]  io_in_0_bits_lpIDWithPadding,
  input         io_in_0_bits_snoopMe,
  input         io_in_0_bits_expCompAck,
  input  [1:0]  io_in_0_bits_tagOp,
  input         io_in_0_bits_traceTag,
  input         io_in_0_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_0_bits_mpam_partID,
  input         io_in_0_bits_mpam_mpamNS,
  input  [3:0]  io_in_0_bits_rsvdc,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [3:0]  io_in_1_bits_qos,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_returnNID,
  input         io_in_1_bits_stashNIDValid,
  input  [11:0] io_in_1_bits_returnTxnID,
  input  [6:0]  io_in_1_bits_opcode,
  input  [47:0] io_in_1_bits_addr,
  input         io_in_1_bits_ns,
  input         io_in_1_bits_likelyshared,
  input         io_in_1_bits_allowRetry,
  input  [1:0]  io_in_1_bits_order,
  input  [3:0]  io_in_1_bits_pCrdType,
  input         io_in_1_bits_memAttr_allocate,
  input         io_in_1_bits_memAttr_cacheable,
  input         io_in_1_bits_memAttr_device,
  input         io_in_1_bits_memAttr_ewa,
  input         io_in_1_bits_snpAttr,
  input  [7:0]  io_in_1_bits_lpIDWithPadding,
  input         io_in_1_bits_snoopMe,
  input         io_in_1_bits_expCompAck,
  input  [1:0]  io_in_1_bits_tagOp,
  input         io_in_1_bits_traceTag,
  input         io_in_1_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_1_bits_mpam_partID,
  input         io_in_1_bits_mpam_mpamNS,
  input  [3:0]  io_in_1_bits_rsvdc,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input  [3:0]  io_in_2_bits_qos,
  input  [11:0] io_in_2_bits_txnID,
  input  [10:0] io_in_2_bits_returnNID,
  input         io_in_2_bits_stashNIDValid,
  input  [11:0] io_in_2_bits_returnTxnID,
  input  [6:0]  io_in_2_bits_opcode,
  input  [47:0] io_in_2_bits_addr,
  input         io_in_2_bits_ns,
  input         io_in_2_bits_likelyshared,
  input         io_in_2_bits_allowRetry,
  input  [1:0]  io_in_2_bits_order,
  input  [3:0]  io_in_2_bits_pCrdType,
  input         io_in_2_bits_memAttr_allocate,
  input         io_in_2_bits_memAttr_cacheable,
  input         io_in_2_bits_memAttr_device,
  input         io_in_2_bits_memAttr_ewa,
  input         io_in_2_bits_snpAttr,
  input  [7:0]  io_in_2_bits_lpIDWithPadding,
  input         io_in_2_bits_snoopMe,
  input         io_in_2_bits_expCompAck,
  input  [1:0]  io_in_2_bits_tagOp,
  input         io_in_2_bits_traceTag,
  input         io_in_2_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_2_bits_mpam_partID,
  input         io_in_2_bits_mpam_mpamNS,
  input  [3:0]  io_in_2_bits_rsvdc,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input  [3:0]  io_in_3_bits_qos,
  input  [11:0] io_in_3_bits_txnID,
  input  [10:0] io_in_3_bits_returnNID,
  input         io_in_3_bits_stashNIDValid,
  input  [11:0] io_in_3_bits_returnTxnID,
  input  [6:0]  io_in_3_bits_opcode,
  input  [47:0] io_in_3_bits_addr,
  input         io_in_3_bits_ns,
  input         io_in_3_bits_likelyshared,
  input         io_in_3_bits_allowRetry,
  input  [1:0]  io_in_3_bits_order,
  input  [3:0]  io_in_3_bits_pCrdType,
  input         io_in_3_bits_memAttr_allocate,
  input         io_in_3_bits_memAttr_cacheable,
  input         io_in_3_bits_memAttr_device,
  input         io_in_3_bits_memAttr_ewa,
  input         io_in_3_bits_snpAttr,
  input  [7:0]  io_in_3_bits_lpIDWithPadding,
  input         io_in_3_bits_snoopMe,
  input         io_in_3_bits_expCompAck,
  input  [1:0]  io_in_3_bits_tagOp,
  input         io_in_3_bits_traceTag,
  input         io_in_3_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_3_bits_mpam_partID,
  input         io_in_3_bits_mpam_mpamNS,
  input  [3:0]  io_in_3_bits_rsvdc,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input  [3:0]  io_in_4_bits_qos,
  input  [10:0] io_in_4_bits_tgtID,
  input  [11:0] io_in_4_bits_txnID,
  input  [10:0] io_in_4_bits_returnNID,
  input         io_in_4_bits_stashNIDValid,
  input  [11:0] io_in_4_bits_returnTxnID,
  input  [6:0]  io_in_4_bits_opcode,
  input  [2:0]  io_in_4_bits_size,
  input  [47:0] io_in_4_bits_addr,
  input         io_in_4_bits_ns,
  input         io_in_4_bits_likelyshared,
  input         io_in_4_bits_allowRetry,
  input  [1:0]  io_in_4_bits_order,
  input  [3:0]  io_in_4_bits_pCrdType,
  input         io_in_4_bits_memAttr_allocate,
  input         io_in_4_bits_memAttr_cacheable,
  input         io_in_4_bits_memAttr_device,
  input         io_in_4_bits_memAttr_ewa,
  input         io_in_4_bits_snpAttr,
  input  [7:0]  io_in_4_bits_lpIDWithPadding,
  input         io_in_4_bits_snoopMe,
  input         io_in_4_bits_expCompAck,
  input  [1:0]  io_in_4_bits_tagOp,
  input         io_in_4_bits_traceTag,
  input         io_in_4_bits_mpam_perfMonGroup,
  input  [8:0]  io_in_4_bits_mpam_partID,
  input         io_in_4_bits_mpam_mpamNS,
  input  [3:0]  io_in_4_bits_rsvdc,
  input         io_out_ready,
  output        io_out_valid,
  output logic [3:0]  io_out_bits_qos,
  output [10:0] io_out_bits_tgtID,
  output logic [11:0] io_out_bits_txnID,
  output logic [10:0] io_out_bits_returnNID,
  output logic        io_out_bits_stashNIDValid,
  output logic [11:0] io_out_bits_returnTxnID,
  output logic [6:0]  io_out_bits_opcode,
  output [2:0]  io_out_bits_size,
  output logic [47:0] io_out_bits_addr,
  output logic        io_out_bits_ns,
  output logic        io_out_bits_likelyshared,
  output logic        io_out_bits_allowRetry,
  output logic [1:0]  io_out_bits_order,
  output logic [3:0]  io_out_bits_pCrdType,
  output logic        io_out_bits_memAttr_allocate,
  output logic        io_out_bits_memAttr_cacheable,
  output logic        io_out_bits_memAttr_device,
  output logic        io_out_bits_memAttr_ewa,
  output logic        io_out_bits_snpAttr,
  output logic [7:0]  io_out_bits_lpIDWithPadding,
  output logic        io_out_bits_snoopMe,
  output logic        io_out_bits_expCompAck,
  output logic [1:0]  io_out_bits_tagOp,
  output logic        io_out_bits_traceTag,
  output logic        io_out_bits_mpam_perfMonGroup,
  output logic [8:0]  io_out_bits_mpam_partID,
  output logic        io_out_bits_mpam_mpamNS,
  output logic [3:0]  io_out_bits_rsvdc,
  output [2:0]  io_chosen
);

  localparam int unsigned NUM = 5;

  // ---- lastGrant 寄存器 + grantMask ----
  reg  [2:0] lastGrant;

  // grantMask[i] = (lastGrant < i): golden 逐位形式 (i=1: ==0; i=2: <2; i=3: <3; i=4: ~[2])
  wire gm1 = (lastGrant == 3'h0);
  wire gm2 = (lastGrant <  3'h2);
  wire gm3 = (lastGrant <  3'h3);
  wire gm4 = ~lastGrant[2];             // = (lastGrant < 4)

  // masked 轮候选 (下标 0 不进 masked 轮)
  wire vm1 = io_in_1_valid & gm1;
  wire vm2 = io_in_2_valid & gm2;
  wire vm3 = io_in_3_valid & gm3;
  wire vm4 = io_in_4_valid & gm4;

  // base 轮: valids 里最低下标 (默认 4, 与 golden _GEN_30 一致)
  wire [2:0] baseChoice =
    io_in_0_valid ? 3'h0 :
    io_in_1_valid ? 3'h1 :
    io_in_2_valid ? 3'h2 :
    io_in_3_valid ? 3'h3 : 3'h4;

  // choice = 最低命中 masked 候选; 否则退化 base 轮
  wire [2:0] choice =
    vm1 ? 3'h1 :
    vm2 ? 3'h2 :
    vm3 ? 3'h3 :
    vm4 ? 3'h4 : baseChoice;

  // io_out_valid = valid[choice] (choice 0..4; >4 不可达退化 valid0)
  logic out_valid;
  always_comb begin
    unique case (choice)
      3'h0:    out_valid = io_in_0_valid;
      3'h1:    out_valid = io_in_1_valid;
      3'h2:    out_valid = io_in_2_valid;
      3'h3:    out_valid = io_in_3_valid;
      3'h4:    out_valid = io_in_4_valid;
      default: out_valid = io_in_0_valid;
    endcase
  end

  always @(posedge clock or posedge reset) begin
    if (reset)
      lastGrant <= 3'h0;
    else if (io_out_ready & out_valid)
      lastGrant <= choice;
  end

  // ---- ready 前缀链 (逐位照搬 golden _ctrl_T) ----
  wire t1 = vm1 | vm2;                 // _ctrl_T_1
  wire t2 = t1  | vm3;                 // _ctrl_T_2
  wire t3 = t2  | vm4;                 // _ctrl_T_3 = 有任一 masked 候选
  wire t4 = t3  | io_in_0_valid;       // _ctrl_T_4
  wire t5 = t4  | io_in_1_valid;       // _ctrl_T_5
  wire t6 = t5  | io_in_2_valid;       // _ctrl_T_6

  assign io_in_0_ready = ~t3 & io_out_ready;
  assign io_in_1_ready = (gm1 | ~t4) & io_out_ready;
  assign io_in_2_ready = (~vm1 & gm2 | ~t5) & io_out_ready;
  assign io_in_3_ready = (~t1  & gm3 | ~t6) & io_out_ready;
  assign io_in_4_ready = (~t2  & gm4 | ~(t6 | io_in_3_valid)) & io_out_ready;

  assign io_out_valid = out_valid;
  assign io_chosen    = choice;

  // ---- payload: 共有字段 = input[choice] (choice 0..4, 默认 0 = golden 高位不可达项) ----
  //  为可读, 用 always_comb case 逐字段选择 (等价于 golden 的 _GEN_N[io_chosen_choice])。
  always_comb begin
    // 默认取 input0 (对应 golden 8 深表里 index 0/5/6/7 的 io_in_0 项)
    io_out_bits_qos            = io_in_0_bits_qos;
    io_out_bits_txnID          = io_in_0_bits_txnID;
    io_out_bits_returnNID      = io_in_0_bits_returnNID;
    io_out_bits_stashNIDValid  = io_in_0_bits_stashNIDValid;
    io_out_bits_returnTxnID    = io_in_0_bits_returnTxnID;
    io_out_bits_opcode         = io_in_0_bits_opcode;
    io_out_bits_addr           = io_in_0_bits_addr;
    io_out_bits_ns             = io_in_0_bits_ns;
    io_out_bits_likelyshared   = io_in_0_bits_likelyshared;
    io_out_bits_allowRetry     = io_in_0_bits_allowRetry;
    io_out_bits_order          = io_in_0_bits_order;
    io_out_bits_pCrdType       = io_in_0_bits_pCrdType;
    io_out_bits_memAttr_allocate  = io_in_0_bits_memAttr_allocate;
    io_out_bits_memAttr_cacheable = io_in_0_bits_memAttr_cacheable;
    io_out_bits_memAttr_device    = io_in_0_bits_memAttr_device;
    io_out_bits_memAttr_ewa       = io_in_0_bits_memAttr_ewa;
    io_out_bits_snpAttr        = io_in_0_bits_snpAttr;
    io_out_bits_lpIDWithPadding= io_in_0_bits_lpIDWithPadding;
    io_out_bits_snoopMe        = io_in_0_bits_snoopMe;
    io_out_bits_expCompAck     = io_in_0_bits_expCompAck;
    io_out_bits_tagOp          = io_in_0_bits_tagOp;
    io_out_bits_traceTag       = io_in_0_bits_traceTag;
    io_out_bits_mpam_perfMonGroup = io_in_0_bits_mpam_perfMonGroup;
    io_out_bits_mpam_partID    = io_in_0_bits_mpam_partID;
    io_out_bits_mpam_mpamNS    = io_in_0_bits_mpam_mpamNS;
    io_out_bits_rsvdc          = io_in_0_bits_rsvdc;
    case (choice)
      3'h1: begin
        io_out_bits_qos            = io_in_1_bits_qos;
        io_out_bits_txnID          = io_in_1_bits_txnID;
        io_out_bits_returnNID      = io_in_1_bits_returnNID;
        io_out_bits_stashNIDValid  = io_in_1_bits_stashNIDValid;
        io_out_bits_returnTxnID    = io_in_1_bits_returnTxnID;
        io_out_bits_opcode         = io_in_1_bits_opcode;
        io_out_bits_addr           = io_in_1_bits_addr;
        io_out_bits_ns             = io_in_1_bits_ns;
        io_out_bits_likelyshared   = io_in_1_bits_likelyshared;
        io_out_bits_allowRetry     = io_in_1_bits_allowRetry;
        io_out_bits_order          = io_in_1_bits_order;
        io_out_bits_pCrdType       = io_in_1_bits_pCrdType;
        io_out_bits_memAttr_allocate  = io_in_1_bits_memAttr_allocate;
        io_out_bits_memAttr_cacheable = io_in_1_bits_memAttr_cacheable;
        io_out_bits_memAttr_device    = io_in_1_bits_memAttr_device;
        io_out_bits_memAttr_ewa       = io_in_1_bits_memAttr_ewa;
        io_out_bits_snpAttr        = io_in_1_bits_snpAttr;
        io_out_bits_lpIDWithPadding= io_in_1_bits_lpIDWithPadding;
        io_out_bits_snoopMe        = io_in_1_bits_snoopMe;
        io_out_bits_expCompAck     = io_in_1_bits_expCompAck;
        io_out_bits_tagOp          = io_in_1_bits_tagOp;
        io_out_bits_traceTag       = io_in_1_bits_traceTag;
        io_out_bits_mpam_perfMonGroup = io_in_1_bits_mpam_perfMonGroup;
        io_out_bits_mpam_partID    = io_in_1_bits_mpam_partID;
        io_out_bits_mpam_mpamNS    = io_in_1_bits_mpam_mpamNS;
        io_out_bits_rsvdc          = io_in_1_bits_rsvdc;
      end
      3'h2: begin
        io_out_bits_qos            = io_in_2_bits_qos;
        io_out_bits_txnID          = io_in_2_bits_txnID;
        io_out_bits_returnNID      = io_in_2_bits_returnNID;
        io_out_bits_stashNIDValid  = io_in_2_bits_stashNIDValid;
        io_out_bits_returnTxnID    = io_in_2_bits_returnTxnID;
        io_out_bits_opcode         = io_in_2_bits_opcode;
        io_out_bits_addr           = io_in_2_bits_addr;
        io_out_bits_ns             = io_in_2_bits_ns;
        io_out_bits_likelyshared   = io_in_2_bits_likelyshared;
        io_out_bits_allowRetry     = io_in_2_bits_allowRetry;
        io_out_bits_order          = io_in_2_bits_order;
        io_out_bits_pCrdType       = io_in_2_bits_pCrdType;
        io_out_bits_memAttr_allocate  = io_in_2_bits_memAttr_allocate;
        io_out_bits_memAttr_cacheable = io_in_2_bits_memAttr_cacheable;
        io_out_bits_memAttr_device    = io_in_2_bits_memAttr_device;
        io_out_bits_memAttr_ewa       = io_in_2_bits_memAttr_ewa;
        io_out_bits_snpAttr        = io_in_2_bits_snpAttr;
        io_out_bits_lpIDWithPadding= io_in_2_bits_lpIDWithPadding;
        io_out_bits_snoopMe        = io_in_2_bits_snoopMe;
        io_out_bits_expCompAck     = io_in_2_bits_expCompAck;
        io_out_bits_tagOp          = io_in_2_bits_tagOp;
        io_out_bits_traceTag       = io_in_2_bits_traceTag;
        io_out_bits_mpam_perfMonGroup = io_in_2_bits_mpam_perfMonGroup;
        io_out_bits_mpam_partID    = io_in_2_bits_mpam_partID;
        io_out_bits_mpam_mpamNS    = io_in_2_bits_mpam_mpamNS;
        io_out_bits_rsvdc          = io_in_2_bits_rsvdc;
      end
      3'h3: begin
        io_out_bits_qos            = io_in_3_bits_qos;
        io_out_bits_txnID          = io_in_3_bits_txnID;
        io_out_bits_returnNID      = io_in_3_bits_returnNID;
        io_out_bits_stashNIDValid  = io_in_3_bits_stashNIDValid;
        io_out_bits_returnTxnID    = io_in_3_bits_returnTxnID;
        io_out_bits_opcode         = io_in_3_bits_opcode;
        io_out_bits_addr           = io_in_3_bits_addr;
        io_out_bits_ns             = io_in_3_bits_ns;
        io_out_bits_likelyshared   = io_in_3_bits_likelyshared;
        io_out_bits_allowRetry     = io_in_3_bits_allowRetry;
        io_out_bits_order          = io_in_3_bits_order;
        io_out_bits_pCrdType       = io_in_3_bits_pCrdType;
        io_out_bits_memAttr_allocate  = io_in_3_bits_memAttr_allocate;
        io_out_bits_memAttr_cacheable = io_in_3_bits_memAttr_cacheable;
        io_out_bits_memAttr_device    = io_in_3_bits_memAttr_device;
        io_out_bits_memAttr_ewa       = io_in_3_bits_memAttr_ewa;
        io_out_bits_snpAttr        = io_in_3_bits_snpAttr;
        io_out_bits_lpIDWithPadding= io_in_3_bits_lpIDWithPadding;
        io_out_bits_snoopMe        = io_in_3_bits_snoopMe;
        io_out_bits_expCompAck     = io_in_3_bits_expCompAck;
        io_out_bits_tagOp          = io_in_3_bits_tagOp;
        io_out_bits_traceTag       = io_in_3_bits_traceTag;
        io_out_bits_mpam_perfMonGroup = io_in_3_bits_mpam_perfMonGroup;
        io_out_bits_mpam_partID    = io_in_3_bits_mpam_partID;
        io_out_bits_mpam_mpamNS    = io_in_3_bits_mpam_mpamNS;
        io_out_bits_rsvdc          = io_in_3_bits_rsvdc;
      end
      3'h4: begin
        io_out_bits_qos            = io_in_4_bits_qos;
        io_out_bits_txnID          = io_in_4_bits_txnID;
        io_out_bits_returnNID      = io_in_4_bits_returnNID;
        io_out_bits_stashNIDValid  = io_in_4_bits_stashNIDValid;
        io_out_bits_returnTxnID    = io_in_4_bits_returnTxnID;
        io_out_bits_opcode         = io_in_4_bits_opcode;
        io_out_bits_addr           = io_in_4_bits_addr;
        io_out_bits_ns             = io_in_4_bits_ns;
        io_out_bits_likelyshared   = io_in_4_bits_likelyshared;
        io_out_bits_allowRetry     = io_in_4_bits_allowRetry;
        io_out_bits_order          = io_in_4_bits_order;
        io_out_bits_pCrdType       = io_in_4_bits_pCrdType;
        io_out_bits_memAttr_allocate  = io_in_4_bits_memAttr_allocate;
        io_out_bits_memAttr_cacheable = io_in_4_bits_memAttr_cacheable;
        io_out_bits_memAttr_device    = io_in_4_bits_memAttr_device;
        io_out_bits_memAttr_ewa       = io_in_4_bits_memAttr_ewa;
        io_out_bits_snpAttr        = io_in_4_bits_snpAttr;
        io_out_bits_lpIDWithPadding= io_in_4_bits_lpIDWithPadding;
        io_out_bits_snoopMe        = io_in_4_bits_snoopMe;
        io_out_bits_expCompAck     = io_in_4_bits_expCompAck;
        io_out_bits_tagOp          = io_in_4_bits_tagOp;
        io_out_bits_traceTag       = io_in_4_bits_traceTag;
        io_out_bits_mpam_perfMonGroup = io_in_4_bits_mpam_perfMonGroup;
        io_out_bits_mpam_partID    = io_in_4_bits_mpam_partID;
        io_out_bits_mpam_mpamNS    = io_in_4_bits_mpam_mpamNS;
        io_out_bits_rsvdc          = io_in_4_bits_rsvdc;
      end
      default: ; // choice 0/5/6/7 用默认 input0 值
    endcase
  end

  // ---- input-4 专属字段 size/tgtID ----
  //  golden _GEN_9 = index 0..3 = 3'h6, index 4 = io_in_4_bits_size, index 5..7 = 3'h6。
  //  golden _GEN_3 = index 0..3 = 11'h0, index 4 = io_in_4_bits_tgtID, index 5..7 = 11'h0。
  assign io_out_bits_size  = (choice == 3'h4) ? io_in_4_bits_size  : 3'h6;
  assign io_out_bits_tgtID = (choice == 3'h4) ? io_in_4_bits_tgtID : 11'h0;

endmodule
