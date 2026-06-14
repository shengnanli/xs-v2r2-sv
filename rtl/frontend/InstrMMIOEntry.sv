// =============================================================================
// xs_InstrMMIOEntry —— MMIO 取指 miss 处理单元（单条 MMIO 请求的 FSM）
//
// 对应 Chisel: xiangshan.frontend.icache.InstrMMIOEntry（KunminghuV2：nMMIOs=1，
// 故 id 恒 0、flush 被绑 0 DCE、resp.ready 恒 1 DCE）
//
// 4 态 FSM：
//   s_invalid    : 接受 io_req，锁存地址 → s_refill_req
//   s_refill_req : 向 L2 发 TileLink Get（地址按 mmioBusBytes=8 对齐）；wfiReq 时暂不发；
//                  acquire 握手成功 → s_refill_resp
//   s_refill_resp: 收 grant（恒 ready），锁存 64-bit 数据/corrupt → s_send_resp
//   s_send_resp  : 输出 resp（恒 valid，下游恒 ready，1 拍）→ s_invalid
// wfiSafe = 非 s_refill_resp（无在途 L2 响应即可安全进入 wfi）。
// 取指数据按 pc[2:1] 从 64-bit 总线数据里选 32 位（maxInstrLen=32）。
// =============================================================================
module xs_InstrMMIOEntry (
  input  logic        clock,
  input  logic        reset,
  output logic        io_req_ready,
  input  logic        io_req_valid,
  input  logic [47:0] io_req_bits_addr,
  output logic        io_resp_valid,
  output logic [31:0] io_resp_bits_data,
  output logic        io_resp_bits_corrupt,
  input  logic        io_mmio_acquire_ready,
  output logic        io_mmio_acquire_valid,
  output logic [47:0] io_mmio_acquire_bits_address,
  input  logic        io_mmio_grant_valid,
  input  logic [63:0] io_mmio_grant_bits_data,
  input  logic        io_mmio_grant_bits_corrupt,
  input  logic        io_wfi_wfiReq,
  output logic        io_wfi_wfiSafe
);
  localparam logic [1:0] S_INVALID = 2'd0, S_REFILL_REQ = 2'd1,
                         S_REFILL_RESP = 2'd2, S_SEND_RESP = 2'd3;

  logic [1:0]  state;
  logic [47:0] req_addr;
  logic [63:0] respDataReg;
  logic        respCorruptReg;

  // 取指数据选择：mmioBusBytes=8，按 pc[2:1] 取 32 位
  logic [31:0] respData;
  always_comb begin
    unique case (req_addr[2:1])
      2'b00:   respData = respDataReg[31:0];
      2'b01:   respData = respDataReg[47:16];
      2'b10:   respData = respDataReg[63:32];
      default: respData = {16'b0, respDataReg[63:48]};
    endcase
  end

  assign io_req_ready                 = (state == S_INVALID);
  assign io_mmio_acquire_valid        = (state == S_REFILL_REQ) && !io_wfi_wfiReq;
  assign io_mmio_acquire_bits_address = {req_addr[47:3], 3'b0};  // 按 8B 对齐
  assign io_resp_valid                = (state == S_SEND_RESP);
  assign io_resp_bits_data            = respData;
  assign io_resp_bits_corrupt         = respCorruptReg;
  assign io_wfi_wfiSafe               = (state != S_REFILL_RESP);

  wire req_fire   = (state == S_INVALID) && io_req_valid;
  wire grant_fire = (state == S_REFILL_RESP) && io_mmio_grant_valid;   // grant.ready 恒 1

  // req_addr：无复位（与 golden 一致）
  always_ff @(posedge clock)
    if (req_fire) req_addr <= io_req_bits_addr;

  // 响应数据/corrupt：复位清零（golden RegInit）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      respDataReg    <= 64'b0;
      respCorruptReg <= 1'b0;
    end else if (grant_fire) begin
      respDataReg    <= io_mmio_grant_bits_data;
      respCorruptReg <= io_mmio_grant_bits_corrupt;
    end
  end

  // 状态机
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      state <= S_INVALID;
    else case (state)
      S_INVALID:     if (io_req_valid) state <= S_REFILL_REQ;
      S_REFILL_REQ:  if (io_mmio_acquire_valid && io_mmio_acquire_ready) state <= S_REFILL_RESP;
      S_REFILL_RESP: if (io_mmio_grant_valid) state <= S_SEND_RESP;
      S_SEND_RESP:   state <= S_INVALID;            // resp.ready 恒 1 → 1 拍
      default:       state <= S_INVALID;
    endcase
  end

endmodule
