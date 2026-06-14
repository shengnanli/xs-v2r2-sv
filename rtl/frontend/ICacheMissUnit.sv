// =============================================================================
// ICacheMissUnit —— ICache Miss 处理单元（顶层结构 + grant 数据通路）
//
// 香山 V2R2 ICacheMissUnit 的手工可读重写（核：xs_ICacheMissUnit_core）。
//
// 结构（参见 Scala ICacheMissUnit.scala 顶部 ASCII 图）：
//   fetch_req    --> fetchDemux    --> 4 个 fetch  MSHR  --\
//   prefetch_req --> prefetchDemux --> 10 个 prefetch MSHR -> prefetchArb --\
//                                                                            +-> acquireArb --> mem_acquire
//   - fetch  MSHR 优先级高于 prefetch；fetch 间低 index 优先。
//   - prefetch MSHR 由 priorityFIFO 记录入队顺序，按序发射（prefetchArb 选择）。
//   - 各 MSHR 的 lookUps 用于去重：命中则 req 不再入队（fetchHit/prefetchHit）。
//
// 子模块沿用 golden（DeMultiplexer / DeMultiplexer_1 / MuxBundle /
// Arbiter5_MSHRAcquire / ICacheMSHR* / FIFOReg），本模块只重写顶层连线与
// TileLink D 通道（grant）的 cacheline 收集 + SRAM 写 + fetch 响应数据通路。
//
// 端口与寄存器名沿用 golden，便于 Formality 按名 / 展平规则配对。
// =============================================================================
module xs_ICacheMissUnit_core (
  input          clock,
  input          reset,
  input          io_fencei,
  input          io_flush,
  input          io_wfi_wfiReq,
  output         io_wfi_wfiSafe,
  output         io_fetch_req_ready,
  input          io_fetch_req_valid,
  input  [41:0]  io_fetch_req_bits_blkPaddr,
  input  [7:0]   io_fetch_req_bits_vSetIdx,
  output         io_fetch_resp_valid,
  output [41:0]  io_fetch_resp_bits_blkPaddr,
  output [7:0]   io_fetch_resp_bits_vSetIdx,
  output [3:0]   io_fetch_resp_bits_waymask,
  output [511:0] io_fetch_resp_bits_data,
  output         io_fetch_resp_bits_corrupt,
  output         io_prefetch_req_ready,
  input          io_prefetch_req_valid,
  input  [41:0]  io_prefetch_req_bits_blkPaddr,
  input  [7:0]   io_prefetch_req_bits_vSetIdx,
  output         io_meta_write_valid,
  output [7:0]   io_meta_write_bits_virIdx,
  output [35:0]  io_meta_write_bits_phyTag,
  output [3:0]   io_meta_write_bits_waymask,
  output         io_meta_write_bits_bankIdx,
  output         io_data_write_valid,
  output [7:0]   io_data_write_bits_virIdx,
  output [511:0] io_data_write_bits_data,
  output [3:0]   io_data_write_bits_waymask,
  output         io_victim_vSetIdx_valid,
  output [7:0]   io_victim_vSetIdx_bits,
  input  [1:0]   io_victim_way,
  input          io_mem_acquire_ready,
  output         io_mem_acquire_valid,
  output [3:0]   io_mem_acquire_bits_source,
  output [47:0]  io_mem_acquire_bits_address,
  input          io_mem_grant_valid,
  input  [3:0]   io_mem_grant_bits_opcode,
  input  [2:0]   io_mem_grant_bits_size,
  input  [3:0]   io_mem_grant_bits_source,
  input  [255:0] io_mem_grant_bits_data,
  input          io_mem_grant_bits_corrupt
);

  // 共 14 个 MSHR：0..3 为 fetch，4..13 为 prefetch。
  localparam int N_FETCH    = 4;
  localparam int N_PREFETCH = 10;

  // ---------------------------------------------------------------------------
  // 子模块互连线网
  // ---------------------------------------------------------------------------
  // fetchDemux：1 路 fetch req 分发到 4 个 fetch MSHR
  wire        fetchDemux_in_ready;
  wire        fetchDemux_out_valid    [N_FETCH];
  wire [41:0] fetchDemux_out_blkPaddr [N_FETCH];
  wire [7:0]  fetchDemux_out_vSetIdx  [N_FETCH];

  // prefetchDemux：1 路 prefetch req 分发到 10 个 prefetch MSHR
  wire        prefetchDemux_in_ready;
  wire        prefetchDemux_out_valid    [N_PREFETCH];
  wire [41:0] prefetchDemux_out_blkPaddr [N_PREFETCH];
  wire [7:0]  prefetchDemux_out_vSetIdx  [N_PREFETCH];
  wire [3:0]  prefetchDemux_chosen;

  // fetch MSHR 输出
  wire        fetchMSHR_wfiSafe   [N_FETCH];
  wire        fetchMSHR_req_ready [N_FETCH];
  wire        fetchMSHR_acq_valid [N_FETCH];
  wire [47:0] fetchMSHR_acq_addr  [N_FETCH];
  wire [7:0]  fetchMSHR_acq_vSet  [N_FETCH];
  wire        fetchMSHR_lk0_hit   [N_FETCH];
  wire        fetchMSHR_lk1_hit   [N_FETCH];
  wire        fetchMSHR_resp_valid    [N_FETCH];
  wire [41:0] fetchMSHR_resp_blkPaddr [N_FETCH];
  wire [7:0]  fetchMSHR_resp_vSetIdx  [N_FETCH];
  wire [1:0]  fetchMSHR_resp_way      [N_FETCH];

  // prefetch MSHR 输出
  wire        prefetchMSHR_wfiSafe   [N_PREFETCH];
  wire        prefetchMSHR_req_ready [N_PREFETCH];
  wire        prefetchMSHR_acq_valid [N_PREFETCH];
  wire [47:0] prefetchMSHR_acq_addr  [N_PREFETCH];
  wire [7:0]  prefetchMSHR_acq_vSet  [N_PREFETCH];
  wire        prefetchMSHR_lk0_hit   [N_PREFETCH];
  wire        prefetchMSHR_lk1_hit   [N_PREFETCH];
  wire        prefetchMSHR_resp_valid    [N_PREFETCH];
  wire [41:0] prefetchMSHR_resp_blkPaddr [N_PREFETCH];
  wire [7:0]  prefetchMSHR_resp_vSetIdx  [N_PREFETCH];
  wire [1:0]  prefetchMSHR_resp_way      [N_PREFETCH];

  // prefetch 仲裁器 / acquire 仲裁器 / FIFO
  wire        prefetchArb_in_ready [N_PREFETCH];
  wire        prefetchArb_out_valid;
  wire [3:0]  prefetchArb_out_source;
  wire [47:0] prefetchArb_out_address;
  wire [7:0]  prefetchArb_out_vSetIdx;

  wire        acquireArb_in_ready [N_FETCH];  // in_0..3 给 fetch MSHR
  wire        acquireArb_in4_ready;            // in_4 给 prefetchArb.out
  wire        acquireArb_out_valid;

  wire        priorityFIFO_enq_ready;
  wire        priorityFIFO_deq_valid;
  wire [3:0]  priorityFIFO_deq_bits;

  // ---------------------------------------------------------------------------
  // 去重命中：任一 MSHR 的 lookUp 命中即视为重复请求，不再入队
  // lookUps_0 比对 fetch_req，lookUps_1 比对 prefetch_req
  // ---------------------------------------------------------------------------
  wire fetchHit =
    fetchMSHR_lk0_hit[0]    | fetchMSHR_lk0_hit[1]    | fetchMSHR_lk0_hit[2]    | fetchMSHR_lk0_hit[3]    |
    prefetchMSHR_lk0_hit[0] | prefetchMSHR_lk0_hit[1] | prefetchMSHR_lk0_hit[2] | prefetchMSHR_lk0_hit[3] |
    prefetchMSHR_lk0_hit[4] | prefetchMSHR_lk0_hit[5] | prefetchMSHR_lk0_hit[6] | prefetchMSHR_lk0_hit[7] |
    prefetchMSHR_lk0_hit[8] | prefetchMSHR_lk0_hit[9];

  // prefetch 还需与同拍 fetch_req 比对（fetch 优先，prefetch 命中 fetch 则视作重复）
  wire prefetchHitFetchReq =
    (io_prefetch_req_bits_blkPaddr == io_fetch_req_bits_blkPaddr) &
    (io_prefetch_req_bits_vSetIdx  == io_fetch_req_bits_vSetIdx)  & io_fetch_req_valid;

  wire prefetchHit =
    fetchMSHR_lk1_hit[0]    | fetchMSHR_lk1_hit[1]    | fetchMSHR_lk1_hit[2]    | fetchMSHR_lk1_hit[3]    |
    prefetchMSHR_lk1_hit[0] | prefetchMSHR_lk1_hit[1] | prefetchMSHR_lk1_hit[2] | prefetchMSHR_lk1_hit[3] |
    prefetchMSHR_lk1_hit[4] | prefetchMSHR_lk1_hit[5] | prefetchMSHR_lk1_hit[6] | prefetchMSHR_lk1_hit[7] |
    prefetchMSHR_lk1_hit[8] | prefetchMSHR_lk1_hit[9] | prefetchHitFetchReq;

  // demux 入口 valid：命中去重时压低
  wire fetchDemux_in_valid    = io_fetch_req_valid    & ~fetchHit;
  wire prefetchDemux_in_valid = io_prefetch_req_valid & ~prefetchHit;

  // ---------------------------------------------------------------------------
  // TileLink D 通道（grant）：收集 cacheline（refillCycles=2，每拍 256bit）
  // ---------------------------------------------------------------------------
  reg          readBeatCnt;       // 1 bit：当前 beat 序号（0/1）
  reg  [255:0] respDataReg_0;     // beat0 数据
  reg  [255:0] respDataReg_1;     // beat1 数据

  // grant.fire && hasData：opcode[0]=1 表示 AccessAckData/GrantData 等带数据响应
  wire grant_hasData = io_mem_grant_valid & io_mem_grant_bits_opcode[0];
  // 最后一拍：第 1 个 beat（readBeatCnt==1）且带数据
  wire last_fire     = grant_hasData & readBeatCnt;

  // refill_done 计数器（来自 edge.addr_inc，用于断言 refill 完成与 last_fire 对齐）
  // beats1 = hasData ? (是否多 beat) : 0；size>=6(64B) 时 decode[5]=1 → 单 beat
  wire [12:0] beats1_decode    = 13'h3F << io_mem_grant_bits_size;
  wire        refill_done_beats1 = io_mem_grant_bits_opcode[0] & ~beats1_decode[5];
  reg         refill_done_r_counter;

  // ---------------------------------------------------------------------------
  // grant 收集寄存器（异步复位，与 golden 一致）
  // ---------------------------------------------------------------------------
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      readBeatCnt           <= 1'h0;
      respDataReg_0         <= 256'h0;
      respDataReg_1         <= 256'h0;
      refill_done_r_counter <= 1'h0;
    end else begin
      // wait_last = readBeatCnt==1 → 回 0，否则 +1（1bit：~cnt & (cnt-1)==Mux）
      if (grant_hasData)
        readBeatCnt <= ~readBeatCnt & 1'(readBeatCnt - 1'h1);
      if (grant_hasData & ~readBeatCnt)
        respDataReg_0 <= io_mem_grant_bits_data;
      if (grant_hasData & readBeatCnt)
        respDataReg_1 <= io_mem_grant_bits_data;
      // refill_done 计数器：每个 grant.fire 递减，归 0 时载入 beats1
      if (io_mem_grant_valid) begin
        if (refill_done_r_counter)
          refill_done_r_counter <= 1'(refill_done_r_counter - 1'h1);
        else
          refill_done_r_counter <= refill_done_beats1;
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 响应流水：last_fire 后一拍向 mainPipe/SRAM 输出
  // ---------------------------------------------------------------------------
  reg        last_fire_r;
  reg [3:0]  id_r;
  always @(posedge clock) begin
    last_fire_r <= last_fire;
    id_r        <= io_mem_grant_bits_source;
  end

  // corrupt：本次响应任一 beat corrupt 则整条 corrupt，last_fire_r 送出后清除
  reg corrupt_r;
  always @(posedge clock or posedge reset) begin
    if (reset)
      corrupt_r <= 1'h0;
    else
      corrupt_r <= (grant_hasData & io_mem_grant_bits_corrupt) | (~last_fire_r & corrupt_r);
  end

  // 选中 MSHR 的响应信息（提前一拍在 last_fire 时锁存，改善时序）
  reg [41:0] mshr_resp_blkPaddr;
  reg [7:0]  mshr_resp_vSetIdx;
  reg [1:0]  mshr_resp_way;

  // 按 grant.source 选择对应 MSHR 的 resp.bits（16 选 1）。
  // 用满 16 项的 packed 数组、4bit 索引选择，避免越界（与 golden _GEN 布局一致）：
  //   idx 0..3   -> fetchMSHR 0..3
  //   idx 4..13  -> prefetchMSHR 0..9
  //   idx 14,15  -> 复用 fetchMSHR_0（firtool 把 14 项 Vec 补到 16 项的填充）
  wire [15:0][41:0] sel_blkPaddr_v = {
    fetchMSHR_resp_blkPaddr[0], fetchMSHR_resp_blkPaddr[0],
    prefetchMSHR_resp_blkPaddr[9], prefetchMSHR_resp_blkPaddr[8],
    prefetchMSHR_resp_blkPaddr[7], prefetchMSHR_resp_blkPaddr[6],
    prefetchMSHR_resp_blkPaddr[5], prefetchMSHR_resp_blkPaddr[4],
    prefetchMSHR_resp_blkPaddr[3], prefetchMSHR_resp_blkPaddr[2],
    prefetchMSHR_resp_blkPaddr[1], prefetchMSHR_resp_blkPaddr[0],
    fetchMSHR_resp_blkPaddr[3], fetchMSHR_resp_blkPaddr[2],
    fetchMSHR_resp_blkPaddr[1], fetchMSHR_resp_blkPaddr[0]
  };
  wire [15:0][7:0] sel_vSetIdx_v = {
    fetchMSHR_resp_vSetIdx[0], fetchMSHR_resp_vSetIdx[0],
    prefetchMSHR_resp_vSetIdx[9], prefetchMSHR_resp_vSetIdx[8],
    prefetchMSHR_resp_vSetIdx[7], prefetchMSHR_resp_vSetIdx[6],
    prefetchMSHR_resp_vSetIdx[5], prefetchMSHR_resp_vSetIdx[4],
    prefetchMSHR_resp_vSetIdx[3], prefetchMSHR_resp_vSetIdx[2],
    prefetchMSHR_resp_vSetIdx[1], prefetchMSHR_resp_vSetIdx[0],
    fetchMSHR_resp_vSetIdx[3], fetchMSHR_resp_vSetIdx[2],
    fetchMSHR_resp_vSetIdx[1], fetchMSHR_resp_vSetIdx[0]
  };
  wire [15:0][1:0] sel_way_v = {
    fetchMSHR_resp_way[0], fetchMSHR_resp_way[0],
    prefetchMSHR_resp_way[9], prefetchMSHR_resp_way[8],
    prefetchMSHR_resp_way[7], prefetchMSHR_resp_way[6],
    prefetchMSHR_resp_way[5], prefetchMSHR_resp_way[4],
    prefetchMSHR_resp_way[3], prefetchMSHR_resp_way[2],
    prefetchMSHR_resp_way[1], prefetchMSHR_resp_way[0],
    fetchMSHR_resp_way[3], fetchMSHR_resp_way[2],
    fetchMSHR_resp_way[1], fetchMSHR_resp_way[0]
  };
  wire [41:0] sel_blkPaddr = sel_blkPaddr_v[io_mem_grant_bits_source];
  wire [7:0]  sel_vSetIdx  = sel_vSetIdx_v[io_mem_grant_bits_source];
  wire [1:0]  sel_way      = sel_way_v[io_mem_grant_bits_source];

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      mshr_resp_blkPaddr <= 42'h0;
      mshr_resp_vSetIdx  <= 8'h0;
      mshr_resp_way      <= 2'h0;
    end else if (last_fire) begin
      mshr_resp_blkPaddr <= sel_blkPaddr;
      mshr_resp_vSetIdx  <= sel_vSetIdx;
      mshr_resp_way      <= sel_way;
    end
  end

  // 选中 MSHR 的 resp.valid（不锁存，flush/fencei 可随时清除）。按 id_r 选 16:1。
  wire [15:0] sel_valid_v = {
    fetchMSHR_resp_valid[0], fetchMSHR_resp_valid[0],
    prefetchMSHR_resp_valid[9], prefetchMSHR_resp_valid[8],
    prefetchMSHR_resp_valid[7], prefetchMSHR_resp_valid[6],
    prefetchMSHR_resp_valid[5], prefetchMSHR_resp_valid[4],
    prefetchMSHR_resp_valid[3], prefetchMSHR_resp_valid[2],
    prefetchMSHR_resp_valid[1], prefetchMSHR_resp_valid[0],
    fetchMSHR_resp_valid[3], fetchMSHR_resp_valid[2],
    fetchMSHR_resp_valid[1], fetchMSHR_resp_valid[0]
  };
  wire mshr_valid = sel_valid_v[id_r];

  wire [3:0] waymask = 4'h1 << mshr_resp_way;

  // 响应/写 SRAM 控制
  wire fetch_resp_valid = mshr_valid & last_fire_r;
  // flush/fencei 时仍向 mainPipe 送响应（时序考虑），但不可写 SRAM
  wire write_sram_valid = fetch_resp_valid & ~corrupt_r & ~io_flush & ~io_fencei;

  wire [511:0] resp_data = {respDataReg_1, respDataReg_0};

  // ===========================================================================
  // 子模块例化（沿用 golden RTL 子模块）
  // ===========================================================================
  DeMultiplexer fetchDemux (
    .io_in_ready            (fetchDemux_in_ready),
    .io_in_valid            (fetchDemux_in_valid),
    .io_in_bits_blkPaddr    (io_fetch_req_bits_blkPaddr),
    .io_in_bits_vSetIdx     (io_fetch_req_bits_vSetIdx),
    .io_out_0_ready         (fetchMSHR_req_ready[0]),
    .io_out_0_valid         (fetchDemux_out_valid[0]),
    .io_out_0_bits_blkPaddr (fetchDemux_out_blkPaddr[0]),
    .io_out_0_bits_vSetIdx  (fetchDemux_out_vSetIdx[0]),
    .io_out_1_ready         (fetchMSHR_req_ready[1]),
    .io_out_1_valid         (fetchDemux_out_valid[1]),
    .io_out_1_bits_blkPaddr (fetchDemux_out_blkPaddr[1]),
    .io_out_1_bits_vSetIdx  (fetchDemux_out_vSetIdx[1]),
    .io_out_2_ready         (fetchMSHR_req_ready[2]),
    .io_out_2_valid         (fetchDemux_out_valid[2]),
    .io_out_2_bits_blkPaddr (fetchDemux_out_blkPaddr[2]),
    .io_out_2_bits_vSetIdx  (fetchDemux_out_vSetIdx[2]),
    .io_out_3_ready         (fetchMSHR_req_ready[3]),
    .io_out_3_valid         (fetchDemux_out_valid[3]),
    .io_out_3_bits_blkPaddr (fetchDemux_out_blkPaddr[3]),
    .io_out_3_bits_vSetIdx  (fetchDemux_out_vSetIdx[3])
  );

  DeMultiplexer_1 prefetchDemux (
    .io_in_ready            (prefetchDemux_in_ready),
    .io_in_valid            (prefetchDemux_in_valid),
    .io_in_bits_blkPaddr    (io_prefetch_req_bits_blkPaddr),
    .io_in_bits_vSetIdx     (io_prefetch_req_bits_vSetIdx),
    .io_out_0_ready         (prefetchMSHR_req_ready[0]),
    .io_out_0_valid         (prefetchDemux_out_valid[0]),
    .io_out_0_bits_blkPaddr (prefetchDemux_out_blkPaddr[0]),
    .io_out_0_bits_vSetIdx  (prefetchDemux_out_vSetIdx[0]),
    .io_out_1_ready         (prefetchMSHR_req_ready[1]),
    .io_out_1_valid         (prefetchDemux_out_valid[1]),
    .io_out_1_bits_blkPaddr (prefetchDemux_out_blkPaddr[1]),
    .io_out_1_bits_vSetIdx  (prefetchDemux_out_vSetIdx[1]),
    .io_out_2_ready         (prefetchMSHR_req_ready[2]),
    .io_out_2_valid         (prefetchDemux_out_valid[2]),
    .io_out_2_bits_blkPaddr (prefetchDemux_out_blkPaddr[2]),
    .io_out_2_bits_vSetIdx  (prefetchDemux_out_vSetIdx[2]),
    .io_out_3_ready         (prefetchMSHR_req_ready[3]),
    .io_out_3_valid         (prefetchDemux_out_valid[3]),
    .io_out_3_bits_blkPaddr (prefetchDemux_out_blkPaddr[3]),
    .io_out_3_bits_vSetIdx  (prefetchDemux_out_vSetIdx[3]),
    .io_out_4_ready         (prefetchMSHR_req_ready[4]),
    .io_out_4_valid         (prefetchDemux_out_valid[4]),
    .io_out_4_bits_blkPaddr (prefetchDemux_out_blkPaddr[4]),
    .io_out_4_bits_vSetIdx  (prefetchDemux_out_vSetIdx[4]),
    .io_out_5_ready         (prefetchMSHR_req_ready[5]),
    .io_out_5_valid         (prefetchDemux_out_valid[5]),
    .io_out_5_bits_blkPaddr (prefetchDemux_out_blkPaddr[5]),
    .io_out_5_bits_vSetIdx  (prefetchDemux_out_vSetIdx[5]),
    .io_out_6_ready         (prefetchMSHR_req_ready[6]),
    .io_out_6_valid         (prefetchDemux_out_valid[6]),
    .io_out_6_bits_blkPaddr (prefetchDemux_out_blkPaddr[6]),
    .io_out_6_bits_vSetIdx  (prefetchDemux_out_vSetIdx[6]),
    .io_out_7_ready         (prefetchMSHR_req_ready[7]),
    .io_out_7_valid         (prefetchDemux_out_valid[7]),
    .io_out_7_bits_blkPaddr (prefetchDemux_out_blkPaddr[7]),
    .io_out_7_bits_vSetIdx  (prefetchDemux_out_vSetIdx[7]),
    .io_out_8_ready         (prefetchMSHR_req_ready[8]),
    .io_out_8_valid         (prefetchDemux_out_valid[8]),
    .io_out_8_bits_blkPaddr (prefetchDemux_out_blkPaddr[8]),
    .io_out_8_bits_vSetIdx  (prefetchDemux_out_vSetIdx[8]),
    .io_out_9_ready         (prefetchMSHR_req_ready[9]),
    .io_out_9_valid         (prefetchDemux_out_valid[9]),
    .io_out_9_bits_blkPaddr (prefetchDemux_out_blkPaddr[9]),
    .io_out_9_bits_vSetIdx  (prefetchDemux_out_vSetIdx[9]),
    .io_chosen              (prefetchDemux_chosen)
  );

  MuxBundle prefetchArb (
    .io_sel                       (priorityFIFO_deq_bits),
    .io_in_0_ready                (prefetchArb_in_ready[0]),
    .io_in_0_valid                (prefetchMSHR_acq_valid[0]),
    .io_in_0_bits_acquire_address (prefetchMSHR_acq_addr[0]),
    .io_in_0_bits_vSetIdx         (prefetchMSHR_acq_vSet[0]),
    .io_in_1_ready                (prefetchArb_in_ready[1]),
    .io_in_1_valid                (prefetchMSHR_acq_valid[1]),
    .io_in_1_bits_acquire_address (prefetchMSHR_acq_addr[1]),
    .io_in_1_bits_vSetIdx         (prefetchMSHR_acq_vSet[1]),
    .io_in_2_ready                (prefetchArb_in_ready[2]),
    .io_in_2_valid                (prefetchMSHR_acq_valid[2]),
    .io_in_2_bits_acquire_address (prefetchMSHR_acq_addr[2]),
    .io_in_2_bits_vSetIdx         (prefetchMSHR_acq_vSet[2]),
    .io_in_3_ready                (prefetchArb_in_ready[3]),
    .io_in_3_valid                (prefetchMSHR_acq_valid[3]),
    .io_in_3_bits_acquire_address (prefetchMSHR_acq_addr[3]),
    .io_in_3_bits_vSetIdx         (prefetchMSHR_acq_vSet[3]),
    .io_in_4_ready                (prefetchArb_in_ready[4]),
    .io_in_4_valid                (prefetchMSHR_acq_valid[4]),
    .io_in_4_bits_acquire_address (prefetchMSHR_acq_addr[4]),
    .io_in_4_bits_vSetIdx         (prefetchMSHR_acq_vSet[4]),
    .io_in_5_ready                (prefetchArb_in_ready[5]),
    .io_in_5_valid                (prefetchMSHR_acq_valid[5]),
    .io_in_5_bits_acquire_address (prefetchMSHR_acq_addr[5]),
    .io_in_5_bits_vSetIdx         (prefetchMSHR_acq_vSet[5]),
    .io_in_6_ready                (prefetchArb_in_ready[6]),
    .io_in_6_valid                (prefetchMSHR_acq_valid[6]),
    .io_in_6_bits_acquire_address (prefetchMSHR_acq_addr[6]),
    .io_in_6_bits_vSetIdx         (prefetchMSHR_acq_vSet[6]),
    .io_in_7_ready                (prefetchArb_in_ready[7]),
    .io_in_7_valid                (prefetchMSHR_acq_valid[7]),
    .io_in_7_bits_acquire_address (prefetchMSHR_acq_addr[7]),
    .io_in_7_bits_vSetIdx         (prefetchMSHR_acq_vSet[7]),
    .io_in_8_ready                (prefetchArb_in_ready[8]),
    .io_in_8_valid                (prefetchMSHR_acq_valid[8]),
    .io_in_8_bits_acquire_address (prefetchMSHR_acq_addr[8]),
    .io_in_8_bits_vSetIdx         (prefetchMSHR_acq_vSet[8]),
    .io_in_9_ready                (prefetchArb_in_ready[9]),
    .io_in_9_valid                (prefetchMSHR_acq_valid[9]),
    .io_in_9_bits_acquire_address (prefetchMSHR_acq_addr[9]),
    .io_in_9_bits_vSetIdx         (prefetchMSHR_acq_vSet[9]),
    .io_out_ready                 (acquireArb_in4_ready),
    .io_out_valid                 (prefetchArb_out_valid),
    .io_out_bits_acquire_source   (prefetchArb_out_source),
    .io_out_bits_acquire_address  (prefetchArb_out_address),
    .io_out_bits_vSetIdx          (prefetchArb_out_vSetIdx)
  );

  Arbiter5_MSHRAcquire acquireArb (
    .io_in_0_ready                (acquireArb_in_ready[0]),
    .io_in_0_valid                (fetchMSHR_acq_valid[0]),
    .io_in_0_bits_acquire_address (fetchMSHR_acq_addr[0]),
    .io_in_0_bits_vSetIdx         (fetchMSHR_acq_vSet[0]),
    .io_in_1_ready                (acquireArb_in_ready[1]),
    .io_in_1_valid                (fetchMSHR_acq_valid[1]),
    .io_in_1_bits_acquire_address (fetchMSHR_acq_addr[1]),
    .io_in_1_bits_vSetIdx         (fetchMSHR_acq_vSet[1]),
    .io_in_2_ready                (acquireArb_in_ready[2]),
    .io_in_2_valid                (fetchMSHR_acq_valid[2]),
    .io_in_2_bits_acquire_address (fetchMSHR_acq_addr[2]),
    .io_in_2_bits_vSetIdx         (fetchMSHR_acq_vSet[2]),
    .io_in_3_ready                (acquireArb_in_ready[3]),
    .io_in_3_valid                (fetchMSHR_acq_valid[3]),
    .io_in_3_bits_acquire_address (fetchMSHR_acq_addr[3]),
    .io_in_3_bits_vSetIdx         (fetchMSHR_acq_vSet[3]),
    .io_in_4_ready                (acquireArb_in4_ready),
    .io_in_4_valid                (prefetchArb_out_valid),
    .io_in_4_bits_acquire_source  (prefetchArb_out_source),
    .io_in_4_bits_acquire_address (prefetchArb_out_address),
    .io_in_4_bits_vSetIdx         (prefetchArb_out_vSetIdx),
    .io_out_ready                 (io_mem_acquire_ready),
    .io_out_valid                 (acquireArb_out_valid),
    .io_out_bits_acquire_source   (io_mem_acquire_bits_source),
    .io_out_bits_acquire_address  (io_mem_acquire_bits_address),
    .io_out_bits_vSetIdx          (io_victim_vSetIdx_bits)
  );

  // ---- fetch MSHRs（ID 0..3，无 io_flush 端口）----
  ICacheMSHR fetchMSHRs_0 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(fetchMSHR_wfiSafe[0]),
    .io_invalid(last_fire_r & (id_r == 4'h0)),
    .io_req_ready(fetchMSHR_req_ready[0]), .io_req_valid(fetchDemux_out_valid[0]),
    .io_req_bits_blkPaddr(fetchDemux_out_blkPaddr[0]), .io_req_bits_vSetIdx(fetchDemux_out_vSetIdx[0]),
    .io_acquire_ready(acquireArb_in_ready[0]), .io_acquire_valid(fetchMSHR_acq_valid[0]),
    .io_acquire_bits_acquire_address(fetchMSHR_acq_addr[0]), .io_acquire_bits_vSetIdx(fetchMSHR_acq_vSet[0]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(fetchMSHR_lk0_hit[0]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(fetchMSHR_lk1_hit[0]),
    .io_resp_valid(fetchMSHR_resp_valid[0]), .io_resp_bits_blkPaddr(fetchMSHR_resp_blkPaddr[0]),
    .io_resp_bits_vSetIdx(fetchMSHR_resp_vSetIdx[0]), .io_resp_bits_way(fetchMSHR_resp_way[0]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_1 fetchMSHRs_1 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(fetchMSHR_wfiSafe[1]),
    .io_invalid(last_fire_r & (id_r == 4'h1)),
    .io_req_ready(fetchMSHR_req_ready[1]), .io_req_valid(fetchDemux_out_valid[1]),
    .io_req_bits_blkPaddr(fetchDemux_out_blkPaddr[1]), .io_req_bits_vSetIdx(fetchDemux_out_vSetIdx[1]),
    .io_acquire_ready(acquireArb_in_ready[1]), .io_acquire_valid(fetchMSHR_acq_valid[1]),
    .io_acquire_bits_acquire_address(fetchMSHR_acq_addr[1]), .io_acquire_bits_vSetIdx(fetchMSHR_acq_vSet[1]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(fetchMSHR_lk0_hit[1]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(fetchMSHR_lk1_hit[1]),
    .io_resp_valid(fetchMSHR_resp_valid[1]), .io_resp_bits_blkPaddr(fetchMSHR_resp_blkPaddr[1]),
    .io_resp_bits_vSetIdx(fetchMSHR_resp_vSetIdx[1]), .io_resp_bits_way(fetchMSHR_resp_way[1]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_2 fetchMSHRs_2 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(fetchMSHR_wfiSafe[2]),
    .io_invalid(last_fire_r & (id_r == 4'h2)),
    .io_req_ready(fetchMSHR_req_ready[2]), .io_req_valid(fetchDemux_out_valid[2]),
    .io_req_bits_blkPaddr(fetchDemux_out_blkPaddr[2]), .io_req_bits_vSetIdx(fetchDemux_out_vSetIdx[2]),
    .io_acquire_ready(acquireArb_in_ready[2]), .io_acquire_valid(fetchMSHR_acq_valid[2]),
    .io_acquire_bits_acquire_address(fetchMSHR_acq_addr[2]), .io_acquire_bits_vSetIdx(fetchMSHR_acq_vSet[2]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(fetchMSHR_lk0_hit[2]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(fetchMSHR_lk1_hit[2]),
    .io_resp_valid(fetchMSHR_resp_valid[2]), .io_resp_bits_blkPaddr(fetchMSHR_resp_blkPaddr[2]),
    .io_resp_bits_vSetIdx(fetchMSHR_resp_vSetIdx[2]), .io_resp_bits_way(fetchMSHR_resp_way[2]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_3 fetchMSHRs_3 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(fetchMSHR_wfiSafe[3]),
    .io_invalid(last_fire_r & (id_r == 4'h3)),
    .io_req_ready(fetchMSHR_req_ready[3]), .io_req_valid(fetchDemux_out_valid[3]),
    .io_req_bits_blkPaddr(fetchDemux_out_blkPaddr[3]), .io_req_bits_vSetIdx(fetchDemux_out_vSetIdx[3]),
    .io_acquire_ready(acquireArb_in_ready[3]), .io_acquire_valid(fetchMSHR_acq_valid[3]),
    .io_acquire_bits_acquire_address(fetchMSHR_acq_addr[3]), .io_acquire_bits_vSetIdx(fetchMSHR_acq_vSet[3]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(fetchMSHR_lk0_hit[3]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(fetchMSHR_lk1_hit[3]),
    .io_resp_valid(fetchMSHR_resp_valid[3]), .io_resp_bits_blkPaddr(fetchMSHR_resp_blkPaddr[3]),
    .io_resp_bits_vSetIdx(fetchMSHR_resp_vSetIdx[3]), .io_resp_bits_way(fetchMSHR_resp_way[3]),
    .io_victimWay(io_victim_way)
  );

  // ---- prefetch MSHRs（ID 4..13，带 io_flush 端口）----
  ICacheMSHR_4 prefetchMSHRs_0 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[0]),
    .io_invalid(last_fire_r & (id_r == 4'h4)),
    .io_req_ready(prefetchMSHR_req_ready[0]), .io_req_valid(prefetchDemux_out_valid[0]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[0]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[0]),
    .io_acquire_ready(prefetchArb_in_ready[0]), .io_acquire_valid(prefetchMSHR_acq_valid[0]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[0]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[0]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[0]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[0]),
    .io_resp_valid(prefetchMSHR_resp_valid[0]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[0]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[0]), .io_resp_bits_way(prefetchMSHR_resp_way[0]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_5 prefetchMSHRs_1 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[1]),
    .io_invalid(last_fire_r & (id_r == 4'h5)),
    .io_req_ready(prefetchMSHR_req_ready[1]), .io_req_valid(prefetchDemux_out_valid[1]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[1]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[1]),
    .io_acquire_ready(prefetchArb_in_ready[1]), .io_acquire_valid(prefetchMSHR_acq_valid[1]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[1]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[1]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[1]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[1]),
    .io_resp_valid(prefetchMSHR_resp_valid[1]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[1]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[1]), .io_resp_bits_way(prefetchMSHR_resp_way[1]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_6 prefetchMSHRs_2 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[2]),
    .io_invalid(last_fire_r & (id_r == 4'h6)),
    .io_req_ready(prefetchMSHR_req_ready[2]), .io_req_valid(prefetchDemux_out_valid[2]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[2]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[2]),
    .io_acquire_ready(prefetchArb_in_ready[2]), .io_acquire_valid(prefetchMSHR_acq_valid[2]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[2]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[2]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[2]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[2]),
    .io_resp_valid(prefetchMSHR_resp_valid[2]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[2]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[2]), .io_resp_bits_way(prefetchMSHR_resp_way[2]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_7 prefetchMSHRs_3 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[3]),
    .io_invalid(last_fire_r & (id_r == 4'h7)),
    .io_req_ready(prefetchMSHR_req_ready[3]), .io_req_valid(prefetchDemux_out_valid[3]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[3]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[3]),
    .io_acquire_ready(prefetchArb_in_ready[3]), .io_acquire_valid(prefetchMSHR_acq_valid[3]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[3]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[3]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[3]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[3]),
    .io_resp_valid(prefetchMSHR_resp_valid[3]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[3]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[3]), .io_resp_bits_way(prefetchMSHR_resp_way[3]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_8 prefetchMSHRs_4 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[4]),
    .io_invalid(last_fire_r & (id_r == 4'h8)),
    .io_req_ready(prefetchMSHR_req_ready[4]), .io_req_valid(prefetchDemux_out_valid[4]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[4]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[4]),
    .io_acquire_ready(prefetchArb_in_ready[4]), .io_acquire_valid(prefetchMSHR_acq_valid[4]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[4]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[4]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[4]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[4]),
    .io_resp_valid(prefetchMSHR_resp_valid[4]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[4]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[4]), .io_resp_bits_way(prefetchMSHR_resp_way[4]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_9 prefetchMSHRs_5 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[5]),
    .io_invalid(last_fire_r & (id_r == 4'h9)),
    .io_req_ready(prefetchMSHR_req_ready[5]), .io_req_valid(prefetchDemux_out_valid[5]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[5]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[5]),
    .io_acquire_ready(prefetchArb_in_ready[5]), .io_acquire_valid(prefetchMSHR_acq_valid[5]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[5]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[5]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[5]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[5]),
    .io_resp_valid(prefetchMSHR_resp_valid[5]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[5]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[5]), .io_resp_bits_way(prefetchMSHR_resp_way[5]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_10 prefetchMSHRs_6 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[6]),
    .io_invalid(last_fire_r & (id_r == 4'hA)),
    .io_req_ready(prefetchMSHR_req_ready[6]), .io_req_valid(prefetchDemux_out_valid[6]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[6]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[6]),
    .io_acquire_ready(prefetchArb_in_ready[6]), .io_acquire_valid(prefetchMSHR_acq_valid[6]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[6]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[6]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[6]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[6]),
    .io_resp_valid(prefetchMSHR_resp_valid[6]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[6]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[6]), .io_resp_bits_way(prefetchMSHR_resp_way[6]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_11 prefetchMSHRs_7 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[7]),
    .io_invalid(last_fire_r & (id_r == 4'hB)),
    .io_req_ready(prefetchMSHR_req_ready[7]), .io_req_valid(prefetchDemux_out_valid[7]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[7]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[7]),
    .io_acquire_ready(prefetchArb_in_ready[7]), .io_acquire_valid(prefetchMSHR_acq_valid[7]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[7]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[7]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[7]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[7]),
    .io_resp_valid(prefetchMSHR_resp_valid[7]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[7]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[7]), .io_resp_bits_way(prefetchMSHR_resp_way[7]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_12 prefetchMSHRs_8 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[8]),
    .io_invalid(last_fire_r & (id_r == 4'hC)),
    .io_req_ready(prefetchMSHR_req_ready[8]), .io_req_valid(prefetchDemux_out_valid[8]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[8]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[8]),
    .io_acquire_ready(prefetchArb_in_ready[8]), .io_acquire_valid(prefetchMSHR_acq_valid[8]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[8]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[8]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[8]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[8]),
    .io_resp_valid(prefetchMSHR_resp_valid[8]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[8]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[8]), .io_resp_bits_way(prefetchMSHR_resp_way[8]),
    .io_victimWay(io_victim_way)
  );
  ICacheMSHR_13 prefetchMSHRs_9 (
    .clock(clock), .reset(reset), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(prefetchMSHR_wfiSafe[9]),
    .io_invalid(last_fire_r & (id_r == 4'hD)),
    .io_req_ready(prefetchMSHR_req_ready[9]), .io_req_valid(prefetchDemux_out_valid[9]),
    .io_req_bits_blkPaddr(prefetchDemux_out_blkPaddr[9]), .io_req_bits_vSetIdx(prefetchDemux_out_vSetIdx[9]),
    .io_acquire_ready(prefetchArb_in_ready[9]), .io_acquire_valid(prefetchMSHR_acq_valid[9]),
    .io_acquire_bits_acquire_address(prefetchMSHR_acq_addr[9]), .io_acquire_bits_vSetIdx(prefetchMSHR_acq_vSet[9]),
    .io_lookUps_0_info_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_lookUps_0_info_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_lookUps_0_hit(prefetchMSHR_lk0_hit[9]),
    .io_lookUps_1_info_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_lookUps_1_info_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_lookUps_1_hit(prefetchMSHR_lk1_hit[9]),
    .io_resp_valid(prefetchMSHR_resp_valid[9]), .io_resp_bits_blkPaddr(prefetchMSHR_resp_blkPaddr[9]),
    .io_resp_bits_vSetIdx(prefetchMSHR_resp_vSetIdx[9]), .io_resp_bits_way(prefetchMSHR_resp_way[9]),
    .io_victimWay(io_victim_way)
  );

  // prefetch 入队顺序 FIFO：enq 与 prefetchDemux.in 同拍 fire，deq 与 prefetchArb.out 同拍 fire
  FIFOReg priorityFIFO (
    .clock        (clock),
    .reset        (reset),
    .io_enq_ready (priorityFIFO_enq_ready),
    .io_enq_valid (prefetchDemux_in_ready & prefetchDemux_in_valid),
    .io_enq_bits  (prefetchDemux_chosen),
    .io_deq_ready (acquireArb_in4_ready & prefetchArb_out_valid),
    .io_deq_valid (priorityFIFO_deq_valid),
    .io_deq_bits  (priorityFIFO_deq_bits),
    .io_flush     (io_flush | io_fencei)
  );

  // ===========================================================================
  // 顶层输出
  // ===========================================================================
  assign io_wfi_wfiSafe =
    fetchMSHR_wfiSafe[0]    & fetchMSHR_wfiSafe[1]    & fetchMSHR_wfiSafe[2]    & fetchMSHR_wfiSafe[3]    &
    prefetchMSHR_wfiSafe[0] & prefetchMSHR_wfiSafe[1] & prefetchMSHR_wfiSafe[2] & prefetchMSHR_wfiSafe[3] &
    prefetchMSHR_wfiSafe[4] & prefetchMSHR_wfiSafe[5] & prefetchMSHR_wfiSafe[6] & prefetchMSHR_wfiSafe[7] &
    prefetchMSHR_wfiSafe[8] & prefetchMSHR_wfiSafe[9];

  assign io_fetch_req_ready    = fetchDemux_in_ready    | fetchHit;
  assign io_prefetch_req_ready = prefetchDemux_in_ready | prefetchHit;

  // fetch 响应
  assign io_fetch_resp_valid        = fetch_resp_valid;
  assign io_fetch_resp_bits_blkPaddr = mshr_resp_blkPaddr;
  assign io_fetch_resp_bits_vSetIdx  = mshr_resp_vSetIdx;
  assign io_fetch_resp_bits_waymask  = waymask;
  assign io_fetch_resp_bits_data     = resp_data;
  assign io_fetch_resp_bits_corrupt  = corrupt_r;

  // 写 SRAM（meta + data）
  assign io_meta_write_valid        = write_sram_valid;
  assign io_meta_write_bits_virIdx  = mshr_resp_vSetIdx;
  assign io_meta_write_bits_phyTag  = mshr_resp_blkPaddr[41:6];
  assign io_meta_write_bits_waymask = waymask;
  assign io_meta_write_bits_bankIdx = mshr_resp_vSetIdx[0];
  assign io_data_write_valid        = write_sram_valid;
  assign io_data_write_bits_virIdx  = mshr_resp_vSetIdx;
  assign io_data_write_bits_data    = resp_data;
  assign io_data_write_bits_waymask = waymask;

  // 替换器索取 victim way：acquire fire 时
  assign io_victim_vSetIdx_valid = io_mem_acquire_ready & acquireArb_out_valid;
  assign io_mem_acquire_valid    = acquireArb_out_valid;

endmodule
