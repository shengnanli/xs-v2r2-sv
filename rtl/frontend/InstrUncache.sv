// =============================================================================
//  InstrUncache —— 前端 MMIO 取指通路的顶层（IFU ↔ TileLink 之间的那一小块）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/frontend/icache/InstrUncache.scala
//      （class InstrUncache / InstrUncacheImp，LazyModule + TLClientNode）
//
//  ## 它在什么位置
//      IFU(f3, mmio_state 状态机)
//          │ io_req  : {addr, memBackTypeMM, memPageTypeNC, flush}
//          │ io_resp : {data[31:0], corrupt}
//          ▼
//      ┌───────────────── InstrUncache（本文件）─────────────────┐
//      │  entries_0 : InstrMMIOEntry  ← 4 态状态机，逻辑都在那边  │
//      │  resp_arb  : Arbiter1_InsUncacheResp ← 单入仲裁（直通）  │
//      └──────────────── auto_client_out (TileLink A/D) ─────────┘
//          │ A: Get(address, user.MemBackTypeMM, user.MemPageTypeNC)
//          │ D: AccessAckData(source, data[63:0], corrupt)
//          ▼  L2（CoupledL2）→ 总线 → 设备
//  取指地址若落在 uncacheable / MMIO 区域，就不能走 ICache（不能缓存、不能预取、
//  不能投机），改由本通路一次一笔 TileLink Get 去总线上把指令读回来。
//  为什么必须这样、状态机怎么走、页属性 user 位是干什么的，都写在
//  rtl/frontend/InstrMMIOEntry.sv 的文件头里——那边才是逻辑本体。
//
//  ## 本层只有三件事，其中两件被 nMMIOs=1 化简没了
//    1. 分配：Chisel 用 PriorityEncoder 在若干个空闲 entry 里挑一个（entry_alloc_idx）。
//       KunminghuV2 的 cacheParams.nMMIOs = 1 —— 只有一个 entry，挑无可挑，
//       req 直连 entries_0，req.ready 就是 entries_0 的 ready。
//    2. 响应汇聚：Chisel 用 Arbiter(nMMIOs) 把各 entry 的 resp 汇成一路；
//       单入 Arbiter 退化成三条直通线（见 Arbiter1_InsUncacheResp.sv）。
//       同理 TLArbiter.lowestFromSeq 汇聚 A 通道也退化成直连。
//       wfiSafe 是所有 entry 的与，单 entry 就是它自己。
//    3. D 通道按 source 分发（**本层唯一剩下的真逻辑**）：TileLink 用 source id 标识
//       是哪一笔请求的回包，Chisel 写的是 when(mmio_grant.bits.source === i.U)。
//       i=0，于是化简成 io_mmio_grant_valid = ~d_source & d_valid：source 不是 0 的
//       D 报文不是给本 entry 的，valid 不能送进去。
//       另外 Chisel 里 mmio_grant.ready 被无条件钉成 true.B（注释写明是为了防 X 传播），
//       所以 entry 上根本没有 grant_ready 端口，D 通道对本模块是"必收"的。
//
//  ## 结构：本文件不含 xs_*_core
//  golden 这一层本身就只是装配壳（两个例化 + 一个与门），拆出一个"可读核"只会多一层
//  转手，反而看不清。逻辑核在 InstrMMIOEntry.sv，本文件与 golden 结构一一对应。
//
//  ## G0 → G1 这一轮改了什么
//  只加端口、不改逻辑：req 侧多了 memBackTypeMM / memPageTypeNC / flush 三个输入，
//  A 通道多了 user_memPageType_NC / user_memBackType_MM 两个输出，五根线全部直穿到
//  entries_0，本层不做任何处理。（golden 的 diff 看着有 40 多行，是因为 entry 例化的
//  端口名变长、firtool 把整段端口映射重新对齐了；真改动就是这 5 根线。）
// =============================================================================
module InstrUncache(
  input  logic        clock,
  input  logic        reset,

  // TileLink 客户端出口：A 通道发 Get，D 通道收 AccessAckData
  input  logic        auto_client_out_a_ready,
  output logic        auto_client_out_a_valid,
  output logic [47:0] auto_client_out_a_bits_address,
  output logic        auto_client_out_a_bits_user_memPageType_NC,
  output logic        auto_client_out_a_bits_user_memBackType_MM,
  input  logic        auto_client_out_d_valid,
  input  logic        auto_client_out_d_bits_source,
  input  logic [63:0] auto_client_out_d_bits_data,
  input  logic        auto_client_out_d_bits_corrupt,

  // IFU 侧
  output logic        io_req_ready,
  input  logic        io_req_valid,
  input  logic [47:0] io_req_bits_addr,
  input  logic        io_req_bits_memBackTypeMM,
  input  logic        io_req_bits_memPageTypeNC,
  input  logic        io_req_bits_flush,
  output logic        io_resp_valid,
  output logic [31:0] io_resp_bits_data,
  output logic        io_resp_bits_corrupt,

  // WFI 握手：所有 entry 都没有在途总线读时才可进 wfi（单 entry → 就是它自己）
  input  logic        io_wfi_wfiReq,
  output logic        io_wfi_wfiSafe
);

  // entries_0 的响应先进仲裁器再出去（单入 → 直通，见 Arbiter1_InsUncacheResp.sv）
  logic        entry0_resp_valid;
  logic [31:0] entry0_resp_data;
  logic        entry0_resp_corrupt;

  // D 通道按 source 分发：本模块只有 entry 0，source 必须是 0 才是给它的回包。
  logic        entry0_grant_valid;
  assign entry0_grant_valid = ~auto_client_out_d_bits_source & auto_client_out_d_valid;

  InstrMMIOEntry entries_0 (
    .clock                                    (clock),
    .reset                                    (reset),
    .io_req_ready                             (io_req_ready),
    .io_req_valid                             (io_req_valid),
    .io_req_bits_addr                         (io_req_bits_addr),
    .io_req_bits_memBackTypeMM                (io_req_bits_memBackTypeMM),
    .io_req_bits_memPageTypeNC                (io_req_bits_memPageTypeNC),
    .io_req_bits_flush                        (io_req_bits_flush),
    .io_resp_valid                            (entry0_resp_valid),
    .io_resp_bits_data                        (entry0_resp_data),
    .io_resp_bits_corrupt                     (entry0_resp_corrupt),
    .io_mmio_acquire_ready                    (auto_client_out_a_ready),
    .io_mmio_acquire_valid                    (auto_client_out_a_valid),
    .io_mmio_acquire_bits_address             (auto_client_out_a_bits_address),
    .io_mmio_acquire_bits_user_memPageType_NC (auto_client_out_a_bits_user_memPageType_NC),
    .io_mmio_acquire_bits_user_memBackType_MM (auto_client_out_a_bits_user_memBackType_MM),
    .io_mmio_grant_valid                      (entry0_grant_valid),
    .io_mmio_grant_bits_data                  (auto_client_out_d_bits_data),
    .io_mmio_grant_bits_corrupt               (auto_client_out_d_bits_corrupt),
    .io_wfi_wfiReq                            (io_wfi_wfiReq),
    .io_wfi_wfiSafe                           (io_wfi_wfiSafe)
  );

  Arbiter1_InsUncacheResp resp_arb (
    .io_in_0_valid        (entry0_resp_valid),
    .io_in_0_bits_data    (entry0_resp_data),
    .io_in_0_bits_corrupt (entry0_resp_corrupt),
    .io_out_valid         (io_resp_valid),
    .io_out_bits_data     (io_resp_bits_data),
    .io_out_bits_corrupt  (io_resp_bits_corrupt)
  );

endmodule
