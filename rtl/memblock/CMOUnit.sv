// =============================================================================
// CMOUnit —— DCache 的 CMO（cache block 管理指令）发送单元
//
// 位置：MissQueue 内部，与 16 个 MissEntry 并列。LSQ 送来一条 cbo.clean / cbo.flush /
//   cbo.inval（CMOReq），本单元把它变成 TileLink A 通道上的一条 CBOClean/CBOFlush/CBOInval
//   消息发给 L2，等 L2 在 D 通道回 CBOAck，再把结果（denied / corrupt）回给 LSQ。
//   A 请求在 MissQueue 的 acquire 仲裁里优先级最高（第 0 路）；D 通道上 opcode==CBOAck 的
//   回应由 MissQueue 转给本单元。
//
// 机制：一次只处理一条的四状态机（Scala: MissQueue.scala class CMOUnit）
//   IDLE --req.fire--> SREQ --A.fire--> WRESP --D.fire--> LSQ_RESP --resp.fire--> IDLE
//   · 请求在 req.fire 拍锁存（不复位的数据寄存器，只在 fire 拍写）；
//   · denied/corrupt 在接新请求时清零、在收 D 拍取 D 的值；
//   · no_pending = "没有已发出未回的 A 请求"，给 WFI 握手用：wfiSafe = RegNext(no_pending && wfiReq)；
//     wfiReq 期间本单元不发 A（A.valid 被 wfiReq 压住）。
//
// golden 与 Scala 的差别（firtool DCE / 常量折叠，照 golden 端口表写）：
//   · A 通道只剩 opcode/address 两个载荷端口：source=nMissEntries+1、size=6 等常量在父级折掉；
//   · resp_to_lsq 只剩 denied/corrupt：address/nderr 两个输出父级没人读，端口被删，
//     nderr 寄存器也随之整个消失；但 **req_address 寄存器仍是 64 位**，只有 [47:0] 被 A 通道读，
//     [63:48] 是 golden 自己的死位 —— 这里照留 64 位（Scala CMOReq.address 就是 64 位），
//     两侧对称，FM 用 vmucp 实比。
// =============================================================================

module xs_CMOUnit_core (
  input  logic        clock,
  input  logic        reset,          // 异步复位（高有效）
  // LSQ -> 本单元：CMO 请求
  output logic        req_ready,
  input  logic        req_valid,
  input  logic [2:0]  req_opcode,     // 0 clean / 1 flush / 2 inval（3 zero 不会送到这里）
  input  logic [63:0] req_address,
  // 本单元 -> L2：A 通道
  input  logic        chanA_ready,
  output logic        chanA_valid,
  output logic [3:0]  chanA_opcode,   // TileLink CBOClean=12 / CBOFlush=13 / CBOInval=14
  output logic [47:0] chanA_address,
  // L2 -> 本单元：D 通道 CBOAck
  output logic        chanD_ready,
  input  logic        chanD_valid,
  input  logic        chanD_denied,
  input  logic        chanD_corrupt,
  // 本单元 -> LSQ：完成回应
  input  logic        resp_ready,
  output logic        resp_valid,
  output logic        resp_denied,
  output logic        resp_corrupt,
  // WFI 握手
  input  logic        wfi_req,
  output logic        wfi_safe
);

  // TileLink A 通道 CBO 消息的 opcode（rocket-chip TLMessages，昆明湖 V2 自定义）
  localparam logic [3:0] TL_CBO_CLEAN = 4'd12;
  localparam logic [3:0] TL_CBO_FLUSH = 4'd13;
  localparam logic [3:0] TL_CBO_INVAL = 4'd14;

  typedef enum logic [1:0] {
    S_IDLE     = 2'd0,   // 空闲，可以接新请求
    S_SREQ     = 2'd1,   // 请求已锁存，等 A 通道发出去
    S_WRESP    = 2'd2,   // A 已发，等 L2 的 CBOAck
    S_LSQ_RESP = 2'd3    // 收到 CBOAck，等 LSQ 收走回应
  } cmo_state_e;

  cmo_state_e  state;
  logic [2:0]  req_opcode_q;     // 锁存的请求（不复位）
  logic [63:0] req_address_q;
  logic        denied_q;
  logic        corrupt_q;
  logic        no_pending_q;     // 复位为 1：没有在途的 A 请求
  logic        wfi_safe_q;

  // ---- 握手 ----
  wire req_fire   = req_ready & req_valid;
  wire chanA_fire = chanA_ready & chanA_valid;
  wire chanD_fire = chanD_ready & chanD_valid;
  wire resp_fire  = resp_ready & resp_valid;

  assign req_ready   = state == S_IDLE;
  assign chanA_valid = state == S_SREQ & ~wfi_req;
  assign chanD_ready = state == S_WRESP;
  assign resp_valid  = state == S_LSQ_RESP;

  // ---- 状态机与状态位 ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state        <= S_IDLE;
      denied_q     <= 1'b0;
      corrupt_q    <= 1'b0;
      no_pending_q <= 1'b1;
    end else begin
      case (state)
        S_IDLE: if (req_fire) begin
          state     <= S_SREQ;
          denied_q  <= 1'b0;          // 新请求：清掉上一条的结果
          corrupt_q <= 1'b0;
        end
        S_SREQ: if (chanA_fire) begin
          state        <= S_WRESP;
          no_pending_q <= 1'b0;       // A 发出去了，开始"在途"
        end
        S_WRESP: if (chanD_fire) begin
          state        <= S_LSQ_RESP;
          denied_q     <= chanD_denied;
          corrupt_q    <= chanD_corrupt;
          no_pending_q <= 1'b1;
        end
        S_LSQ_RESP: if (resp_fire) begin
          state <= S_IDLE;
        end
        default: ;
      endcase
    end
  end

  // 请求数据：只在接收拍写，不复位
  always_ff @(posedge clock) begin
    if (req_fire) begin
      req_opcode_q  <= req_opcode;
      req_address_q <= req_address;
    end
  end

  // WFI：一拍延迟（GatedValidRegNext，复位 0）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) wfi_safe_q <= 1'b0;
    else       wfi_safe_q <= no_pending_q & wfi_req;
  end
  assign wfi_safe = wfi_safe_q;

  // ---- 输出载荷 ----
  // MuxLookup(opcode, CBOClean)(0->Clean, 1->Flush, 2->Inval)：未列出的编码落到 Clean
  always_comb begin
    case (req_opcode_q)
      3'd1:    chanA_opcode = TL_CBO_FLUSH;
      3'd2:    chanA_opcode = TL_CBO_INVAL;
      default: chanA_opcode = TL_CBO_CLEAN;
    endcase
  end
  assign chanA_address = req_address_q[47:0];   // 物理地址 48 位；[63:48] 无人读
  assign resp_denied   = denied_q;
  assign resp_corrupt  = corrupt_q;

endmodule

// golden 同名 wrapper：端口逐位同名，只做改名
module CMOUnit(
  input         clock,
  input         reset,
  output        io_req_ready,
  input         io_req_valid,
  input  [2:0]  io_req_bits_opcode,
  input  [63:0] io_req_bits_address,
  input         io_req_chanA_ready,
  output        io_req_chanA_valid,
  output [3:0]  io_req_chanA_bits_opcode,
  output [47:0] io_req_chanA_bits_address,
  output        io_resp_chanD_ready,
  input         io_resp_chanD_valid,
  input         io_resp_chanD_bits_denied,
  input         io_resp_chanD_bits_corrupt,
  input         io_resp_to_lsq_ready,
  output        io_resp_to_lsq_valid,
  output        io_resp_to_lsq_bits_denied,
  output        io_resp_to_lsq_bits_corrupt,
  input         io_wfi_wfiReq,
  output        io_wfi_wfiSafe
);

  xs_CMOUnit_core u_core (
    .clock         (clock),
    .reset         (reset),
    .req_ready     (io_req_ready),
    .req_valid     (io_req_valid),
    .req_opcode    (io_req_bits_opcode),
    .req_address   (io_req_bits_address),
    .chanA_ready   (io_req_chanA_ready),
    .chanA_valid   (io_req_chanA_valid),
    .chanA_opcode  (io_req_chanA_bits_opcode),
    .chanA_address (io_req_chanA_bits_address),
    .chanD_ready   (io_resp_chanD_ready),
    .chanD_valid   (io_resp_chanD_valid),
    .chanD_denied  (io_resp_chanD_bits_denied),
    .chanD_corrupt (io_resp_chanD_bits_corrupt),
    .resp_ready    (io_resp_to_lsq_ready),
    .resp_valid    (io_resp_to_lsq_valid),
    .resp_denied   (io_resp_to_lsq_bits_denied),
    .resp_corrupt  (io_resp_to_lsq_bits_corrupt),
    .wfi_req       (io_wfi_wfiReq),
    .wfi_safe      (io_wfi_wfiSafe)
  );

endmodule
