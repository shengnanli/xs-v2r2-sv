// =============================================================================
// xs_PTWRepeaterNB_core —— TLB 与 L2TLB 之间的单项请求/应答中继（PTWRepeaterNB 的核）
//
// 位置：src/main/scala/xiangshan/cache/mmu/Repeater.scala 的 class PTWRepeaterNB
//   （Width = 1、passReady = false）。它插在一个 L1 TLB 的 PTW 口与 L2TLB 之间，
//   把请求与应答各打一拍寄存，用来切断两端之间的长走线。"NB"（non-blocking）指的是
//   请求与应答两条通路各自独立，收着应答时仍可继续发请求。
//
// 机制（两条对称的单项通路，各一个"在手"标志 BoolStopWatch）：
//   请求：tlb_req.fire（= 没在手 && tlb 有请求）时锁存 req、sent 置 1；
//         ptw_req.valid = sent；ptw_req.fire 或 flush 时 sent 清 0（stop 优先于 start）。
//         tlb_req.ready = !sent（passReady=false：不穿透下游 ready）。
//   应答：ptw_resp.fire（= 没在手 && ptw 有应答）时锁存 resp、recv 置 1；
//         tlb_resp.valid = recv；tlb_resp.fire 或 flush 时 recv 清 0。
//         ptw_resp.ready = !recv。
//   flush = (sfence.valid | satp/vsatp/hgatp.changed | priv.virt_changed) 经 DelayN(1)
//           打一拍（子模块 DelayN_1，两侧白盒）。
//
// 怪癖：锁存的 req / resp 不复位；flush 只清标志、不清载荷；fire 当拍又 flush 时
//   标志仍清 0（golden：sent <= ~(stop) & (start | sent)）。
//
// 载荷在核里是两根打包向量（REQ_W / RESP_W 位），字段的拆分与拼接由薄文件做，
// 核不关心字段含义。
// =============================================================================
module xs_PTWRepeaterNB_core #(
  parameter int unsigned REQ_W  = 40,      // vpn 38 + s2xlate 2
  parameter int unsigned RESP_W = 1        // 由薄文件给：PtwRespS2 全部字段
)(
  input  logic              clock,
  input  logic              reset,
  input  logic              flush_src,      // sfence / satp 等改变（打一拍后生效）
  // ---- TLB 侧 ----
  output logic              tlb_req_ready,
  input  logic              tlb_req_valid,
  input  logic [REQ_W-1:0]  tlb_req_bits,
  input  logic              tlb_resp_ready,
  output logic              tlb_resp_valid,
  output logic [RESP_W-1:0] tlb_resp_bits,
  // ---- L2TLB（PTW）侧 ----
  input  logic              ptw_req_ready,
  output logic              ptw_req_valid,
  output logic [REQ_W-1:0]  ptw_req_bits,
  output logic              ptw_resp_ready,
  input  logic              ptw_resp_valid,
  input  logic [RESP_W-1:0] ptw_resp_bits
);

  // flush 打一拍（golden 实例名 delay）
  logic flush;
  DelayN_1 delay (
    .clock (clock),
    .io_in (flush_src),
    .io_out(flush)
  );

  // ---- 请求通路 ----
  logic             sent;     // 有一笔请求在手、还没被 PTW 收走
  logic [REQ_W-1:0] req;      // 锁存的请求（不复位）

  wire tlb_req_fire = tlb_req_ready & tlb_req_valid;
  wire ptw_req_fire = ptw_req_ready & ptw_req_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                       sent <= 1'b0;
    else if (ptw_req_fire | flush)   sent <= 1'b0;      // stop 优先
    else if (tlb_req_fire)           sent <= 1'b1;
  end
  always_ff @(posedge clock) begin
    if (tlb_req_fire) req <= tlb_req_bits;
  end

  assign tlb_req_ready = ~sent;
  assign ptw_req_valid = sent;
  assign ptw_req_bits  = req;

  // ---- 应答通路 ----
  logic              recv;    // 有一笔应答在手、还没被 TLB 收走
  logic [RESP_W-1:0] resp;    // 锁存的应答（不复位）

  wire ptw_resp_fire = ptw_resp_ready & ptw_resp_valid;
  wire tlb_resp_fire = tlb_resp_ready & tlb_resp_valid;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)                       recv <= 1'b0;
    else if (tlb_resp_fire | flush)  recv <= 1'b0;
    else if (ptw_resp_fire)          recv <= 1'b1;
  end
  always_ff @(posedge clock) begin
    if (ptw_resp_fire) resp <= ptw_resp_bits;
  end

  assign ptw_resp_ready = ~recv;
  assign tlb_resp_valid = recv;
  assign tlb_resp_bits  = resp;

endmodule
