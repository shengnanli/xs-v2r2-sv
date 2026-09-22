// BitmapCache.sv —— 页位图缓存（Bitmap Cache）：把 Bitmap 走表器从内存读回的 64 位
// "页检查失败位图"（每位对应一个 4KB 页的 check-failed 标志）缓存起来，
// 让后续同一 ppn 段的 bitmap 检查不必再访存。
//
// 本文件含：xs_BitmapCache_core（可读重写核）+ BitmapCache（golden 同名 wrapper，67 端口透传）。
// 对应 Chisel: xiangshan.cache.mmu.BitmapCache（BitmapCheck.scala 第 407 行起）；
// 对照 golden = G1-canonical/golden-rtl/BitmapCache.sv（940 行，单变体）。
//
// 【它在 L2TLB 里的位置】
//   Bitmap 走表器每做一次检查先来本缓存查：命中就直接拿到该 8 页扇区的 8 个 cf 位；
//   未命中才去内存读 64 位位图，读回后经 io.refill 写进本缓存。
//   请求携带 order（Bitmap 里的条目序号）原样带回，供 Bitmap 对号入座。
//
// 【几何（golden 实测）】32 组 × 4 路，SplittedSRAM(waySplit=2, dataSplit=2 → 4 个 SRAMTemplate_124)
//   表项 = {tag[24:0], data[63:0]}（SRAM 位宽 90，多出的 1 位是 bcReservedBits）
//   请求 tag 是 36 位 ppn：tag[35:11] 比对用 tag，tag[10:6] 组号，tag[5:3] 选 64 位里的哪个字节
//   （一个字节 = 8 个相邻页 = 一个 tlbcontiguous 扇区），tag[2:0] 不用。
//   有效位 bcv 是 128 位 flop（32 组 × 4 路），mbmc.BCLEAR 一次清空；SRAM 内容不清。
//
// 【三级流水（golden 实测，PipelineConnect 链）】
//   stageReq(组合) ─▶ stageDelay(valid, data_*) ─▶ stageResp(valid_1, data_1_*)
//       发 SRAM 读        SRAM 数据回来、算命中      装配 io.resp
//   ready 反压：stageResp_ready = ~valid_1 | io_resp_ready
//              stageReq_ready  = stageResp_ready & ~io_refill_valid   ← refill 占 SRAM 写口时不收新请求
//   SRAM 读数据用 DataHoldBypass 保持（data_resp_r_*），流水停住时数据不丢。
//   ★命中向量 hitVec 在 stageDelay→stageResp 那一拍算并打进寄存器★：
//     hitVec[w] = (读回 tag[w] == data_tag[35:11]) & vVec_delay[w]
//   其中 vVec_delay 是 stageReq 那拍锁住的本组 4 个有效位（不是回填后的新值）。
//
// 【替换：树形 PLRU（每组 3 位 state_vec）+ replaceWrapper】
//   有空路先填空路（PriorityEncoder(~valid)），满了才问 PLRU。两个写者：
//   refill 那一拍（victim 路）优先，其次是 stageResp 命中那一拍（hitWay）。
//
// 【复位域（golden 实测）】
//   异步复位：state_vec×32、bcv、stageDelay_valid_1cycle、stageResp_valid_1cycle、valid、valid_1。
//   不复位：两级流水载荷 data_*/data_1_*、DataHoldBypass 的 data_resp_r_*、vVec_delay、
//           ramDatas_*（★只存 data 不存 tag——tag 在 stageResp 没人读，firtool 已裁掉★）、hitVec_*。
//
// 【子模块（两侧同源读 golden，不黑盒——同 PtwCache 的取法）】
//   SplittedSRAM bitmapcache —— 32×4 的 SRAM（→ SRAMTemplate_124 ×4 → sram_array_…_bitmap → array_9 → array_9_ext）
//   MbistBitmapCache mbistBC —— MBIST 分发级（utility.mbist.MbistPipeline 单态化；本仓 rtl/dft 尚无它的薄文件）
//   ClockGate                —— SRAM 时钟门控，E = 读请求 | (~flush & refill) | mbist 请求
//   golden 的 array_9_ext 地址 5 位 / 深度 32，2^5 == 32，Formality 不会报 ELAB-147 越界。
//
// 【X 传播写法】命中向量、命中路选择都写成三目而不是 if：SRAM 没写过的行读出 X，
//   `if (x)` 按假走、三目吐 X，两侧要在同一拍以同样方式传播（vVec 门控保证真正命中时不含 X）。
module xs_BitmapCache_core
  import xs_mmu_common_pkg::*;
(
  // BEGIN GENERATED(core_ports) —— 由 gen_mmu5.py 从 golden 端口表逐根抄出
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BCLEAR,
  input  logic         io_csr_priv_virt_changed,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [7:0]   io_req_bits_order,
  input  logic [35:0]  io_req_bits_tag,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic         io_resp_bits_hit,
  output logic         io_resp_bits_cfs_0,
  output logic         io_resp_bits_cfs_1,
  output logic         io_resp_bits_cfs_2,
  output logic         io_resp_bits_cfs_3,
  output logic         io_resp_bits_cfs_4,
  output logic         io_resp_bits_cfs_5,
  output logic         io_resp_bits_cfs_6,
  output logic         io_resp_bits_cfs_7,
  output logic [7:0]   io_resp_bits_order,
  input  logic         io_refill_valid,
  input  logic [35:0]  io_refill_bits_tag,
  input  logic [63:0]  io_refill_bits_data,
  input  logic [5:0]   boreChildrenBd_bore_array,
  input  logic         boreChildrenBd_bore_all,
  input  logic         boreChildrenBd_bore_req,
  output logic         boreChildrenBd_bore_ack,
  input  logic         boreChildrenBd_bore_writeen,
  input  logic [1:0]   boreChildrenBd_bore_be,
  input  logic [5:0]   boreChildrenBd_bore_addr,
  input  logic [89:0]  boreChildrenBd_bore_indata,
  input  logic         boreChildrenBd_bore_readen,
  input  logic [5:0]   boreChildrenBd_bore_addr_rd,
  output logic [89:0]  boreChildrenBd_bore_outdata,
  input  logic         sigFromSrams_bore_ram_hold,
  input  logic         sigFromSrams_bore_ram_bypass,
  input  logic         sigFromSrams_bore_ram_bp_clken,
  input  logic         sigFromSrams_bore_ram_aux_clk,
  input  logic         sigFromSrams_bore_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_ram_mcp_hold,
  input  logic         sigFromSrams_bore_cgen,
  input  logic         sigFromSrams_bore_1_ram_hold,
  input  logic         sigFromSrams_bore_1_ram_bypass,
  input  logic         sigFromSrams_bore_1_ram_bp_clken,
  input  logic         sigFromSrams_bore_1_ram_aux_clk,
  input  logic         sigFromSrams_bore_1_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_1_ram_mcp_hold,
  input  logic         sigFromSrams_bore_1_cgen,
  input  logic         sigFromSrams_bore_2_ram_hold,
  input  logic         sigFromSrams_bore_2_ram_bypass,
  input  logic         sigFromSrams_bore_2_ram_bp_clken,
  input  logic         sigFromSrams_bore_2_ram_aux_clk,
  input  logic         sigFromSrams_bore_2_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_2_ram_mcp_hold,
  input  logic         sigFromSrams_bore_2_cgen,
  input  logic         sigFromSrams_bore_3_ram_hold,
  input  logic         sigFromSrams_bore_3_ram_bypass,
  input  logic         sigFromSrams_bore_3_ram_bp_clken,
  input  logic         sigFromSrams_bore_3_ram_aux_clk,
  input  logic         sigFromSrams_bore_3_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_3_ram_mcp_hold,
  input  logic         sigFromSrams_bore_3_cgen,
  input  logic         cg_bore_cgen
  // END GENERATED(core_ports)
);

  // ===========================================================================
  // §1 几何与全局控制
  // ===========================================================================
  localparam int BC_SETS  = 32;
  localparam int BC_WAYS  = 4;
  localparam int BC_SET_W = 5;     // tag[10:6]
  localparam int BC_TAG_W = 25;    // tag[35:11]

  logic flush;
  assign flush = io_sfence_valid | io_csr_satp_changed | io_csr_vsatp_changed
               | io_csr_hgatp_changed | io_csr_priv_virt_changed;

  // ===========================================================================
  // §2 寄存器声明
  // ===========================================================================
  // ---- 异步复位域 ----
  logic [2:0]            state_vec [BC_SETS];   // 每组一棵 4 路树形 PLRU
  logic [BC_SETS*BC_WAYS-1:0] bcv;              // 有效位：bcv[set*4 + way]
  logic                  stageDelay_valid_1cycle; // OneCycleValid(stageReq.fire)：SRAM 数据"刚回来"的那一拍
  logic                  stageResp_valid_1cycle;  // OneCycleValid(stageResp.fire)：命中更新 PLRU 用
  logic                  valid;                   // stageDelay 有效
  logic                  valid_1;                 // stageResp 有效
  // ---- 不复位域 ----
  logic [7:0]            data_order,  data_1_order;
  logic [35:0]           data_tag,    data_1_tag;
  logic [BC_TAG_W-1:0]   data_resp_r_tag  [BC_WAYS];  // DataHoldBypass 保持寄存器
  logic [63:0]           data_resp_r_data [BC_WAYS];
  logic [BC_WAYS-1:0]    vVec_delay;                  // stageReq 那拍锁住的本组有效位
  logic [63:0]           ramDatas_data [BC_WAYS];     // stageResp 级的 4 路位图数据
  logic [BC_WAYS-1:0]    hitVec;

  // ===========================================================================
  // §3 流水握手
  // ===========================================================================
  logic stageResp_ready, stageReq_ready;
  logic req_fire;     // stageReq.fire（golden _vVec_delay_T / leftFire）
  logic delay_fire;   // stageDelay.fire（golden leftFire_1）
  logic resp_fire;    // stageResp.fire（golden _GEN_5）
  assign stageResp_ready = ~valid_1 | io_resp_ready;
  assign stageReq_ready  = stageResp_ready & ~io_refill_valid;
  assign req_fire        = stageReq_ready & io_req_valid;
  assign delay_fire      = valid & stageResp_ready;
  assign resp_fire       = io_resp_ready & valid_1;

  // ===========================================================================
  // §4 SRAM 读回 + DataHoldBypass + 命中判定（stageDelay 级）
  // ===========================================================================
  logic [BC_TAG_W-1:0] sram_rtag  [BC_WAYS];
  logic [63:0]         sram_rdata [BC_WAYS];
  logic [BC_TAG_W-1:0] data_resp_tag  [BC_WAYS];   // DataHoldBypass(bitmapcache.io.r.resp.data, stageDelay_valid_1cycle)
  logic [63:0]         data_resp_data [BC_WAYS];
  logic [BC_WAYS-1:0]  hitVec_delay;
  always_comb begin
    for (int w = 0; w < BC_WAYS; w++) begin
      data_resp_tag[w]  = stageDelay_valid_1cycle ? sram_rtag[w]  : data_resp_r_tag[w];
      data_resp_data[w] = stageDelay_valid_1cycle ? sram_rdata[w] : data_resp_r_data[w];
      hitVec_delay[w]   = (data_resp_tag[w] == data_tag[35:11]) & vVec_delay[w];
    end
  end

  // ===========================================================================
  // §5 命中侧（stageResp 级）：hit / hitWay / 命中路的位图 / 8 个 cf 位
  // ===========================================================================
  logic        hit;
  logic        hit_in_low_ways;    // 路 0 或路 1 命中（golden _hitWay_T，ParallelPriorityMux 的树根）
  logic [1:0]  hitWay;
  logic [63:0] hitWayEntry_data;
  logic [7:0]  cfs;
  assign hit_in_low_ways  = hitVec[0] | hitVec[1];
  assign hit              = hit_in_low_ways | hitVec[2] | hitVec[3];
  assign hitWay           = hit_in_low_ways ? {1'b0, ~hitVec[0]} : {1'b1, ~hitVec[2]};
  assign hitWayEntry_data = hit_in_low_ways ? (hitVec[0] ? ramDatas_data[0] : ramDatas_data[1])
                                            : (hitVec[2] ? ramDatas_data[2] : ramDatas_data[3]);
  // 64 位位图按字节分 8 个扇区，tag[5:3] 选扇区；扇区内 8 位 = 8 个相邻页的 cf
  assign cfs = hitWayEntry_data[data_1_tag[5:3]*8 +: 8];

  // ===========================================================================
  // §6 替换：PLRU（4 路 3 位）+ replaceWrapper
  // ===========================================================================
  function automatic logic [1:0] plru4_way(input logic [2:0] s);
    return {s[2], s[2] ? s[1] : s[0]};
  endfunction

  function automatic logic [2:0] plru4_access(input logic [2:0] s, input logic [1:0] way);
    return {~way[1],
            way[1] ? ~way[0] : s[1],
            way[1] ? s[0]    : ~way[0]};
  endfunction

  logic [BC_SET_W-1:0] refill_set, resp_set;
  logic [BC_WAYS-1:0]  refill_set_valid;   // 回填组的 4 个有效位
  logic [1:0]          bc_victimWay;       // replaceWrapper：有空路先填空路，满了问 PLRU
  assign refill_set       = io_refill_bits_tag[10:6];
  assign resp_set         = data_1_tag[10:6];
  assign refill_set_valid = bcv[refill_set*BC_WAYS +: BC_WAYS];
  assign bc_victimWay = (&refill_set_valid)   ? plru4_way(state_vec[refill_set])
                      : ~refill_set_valid[0]  ? 2'd0
                      : ~refill_set_valid[1]  ? 2'd1
                      : ~refill_set_valid[2]  ? 2'd2 : 2'd3;

  logic hit_touch;   // stageResp 命中那一拍更新 PLRU
  assign hit_touch = hit & stageResp_valid_1cycle;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < BC_SETS; s++) state_vec[s] <= 3'h0;
      bcv                     <= '0;
      stageDelay_valid_1cycle <= 1'b0;
      stageResp_valid_1cycle  <= 1'b0;
      valid                   <= 1'b0;
      valid_1                 <= 1'b0;
    end else begin
      for (int s = 0; s < BC_SETS; s++) begin
        if (io_refill_valid & (refill_set == BC_SET_W'(s)))
          state_vec[s] <= plru4_access(state_vec[s], bc_victimWay);
        else if (hit_touch & (resp_set == BC_SET_W'(s)))
          state_vec[s] <= plru4_access(state_vec[s], hitWay);
      end
      // 有效位：BCLEAR 整体清空优先；refill 置位 {组, victim 路}
      if (io_csr_mbmc_BCLEAR)
        bcv <= '0;
      else if (io_refill_valid)
        bcv <= bcv | ((BC_SETS*BC_WAYS)'(1) << {refill_set, bc_victimWay});
      stageDelay_valid_1cycle <= ~flush & req_fire;
      stageResp_valid_1cycle  <= ~flush & stageResp_ready & valid_1;
      valid                   <= ~flush & (req_fire   | (~stageResp_ready & valid));
      valid_1                 <= ~flush & (delay_fire | (~stageResp_ready & valid_1));
    end
  end

  // ===========================================================================
  // §7 流水载荷（不复位域）
  // ===========================================================================
  always_ff @(posedge clock) begin
    if (req_fire) begin
      data_order <= io_req_bits_order;
      data_tag   <= io_req_bits_tag;
      vVec_delay <= bcv[io_req_bits_tag[10:6]*BC_WAYS +: BC_WAYS];
    end
    if (delay_fire) begin
      data_1_order <= data_order;
      data_1_tag   <= data_tag;
      for (int w = 0; w < BC_WAYS; w++) begin
        ramDatas_data[w] <= data_resp_data[w];
        hitVec[w]        <= hitVec_delay[w];
      end
    end
    if (stageDelay_valid_1cycle) begin
      for (int w = 0; w < BC_WAYS; w++) begin
        data_resp_r_tag[w]  <= sram_rtag[w];
        data_resp_r_data[w] <= sram_rdata[w];
      end
    end
  end

  // ===========================================================================
  // §8 SRAM / MBIST / 时钟门控（golden 同源子模块）
  // ===========================================================================
  logic sram_clock;
  logic [BC_WAYS-1:0] refill_waymask;
  assign refill_waymask = BC_WAYS'(1) << bc_victimWay;

  ClockGate ClockGate (
    .TE (cg_bore_cgen),
    .E  (req_fire | (~flush & io_refill_valid) | boreChildrenBd_bore_req),
    .CK (clock),
    .Q  (sram_clock)
  );

  // MBIST 分发级 <-> SRAM 的 4 条 bore 总线
  logic [5:0]  childBd_addr [4], childBd_addr_rd [4], childBd_array [4];
  logic [89:0] childBd_wdata [4], childBd_rdata [4];
  logic [1:0]  childBd_wmask [4];
  logic        childBd_re [4], childBd_we [4], childBd_ack [4], childBd_selectedOH [4];

  SplittedSRAM bitmapcache (
    .clock                            (sram_clock),
    .reset                            (reset),
    .io_r_req_valid                   (req_fire),
    .io_r_req_bits_setIdx             (io_req_bits_tag[10:6]),
    .io_r_resp_data_0_tag             (sram_rtag[0]),
    .io_r_resp_data_0_data            (sram_rdata[0]),
    .io_r_resp_data_1_tag             (sram_rtag[1]),
    .io_r_resp_data_1_data            (sram_rdata[1]),
    .io_r_resp_data_2_tag             (sram_rtag[2]),
    .io_r_resp_data_2_data            (sram_rdata[2]),
    .io_r_resp_data_3_tag             (sram_rtag[3]),
    .io_r_resp_data_3_data            (sram_rdata[3]),
    .io_w_req_valid                   (io_refill_valid),
    .io_w_req_bits_setIdx             (refill_set),
    .io_w_req_bits_data_0_tag         (io_refill_bits_tag[35:11]),
    .io_w_req_bits_data_0_data        (io_refill_bits_data),
    .io_w_req_bits_data_1_tag         (io_refill_bits_tag[35:11]),
    .io_w_req_bits_data_1_data        (io_refill_bits_data),
    .io_w_req_bits_data_2_tag         (io_refill_bits_tag[35:11]),
    .io_w_req_bits_data_2_data        (io_refill_bits_data),
    .io_w_req_bits_data_3_tag         (io_refill_bits_tag[35:11]),
    .io_w_req_bits_data_3_data        (io_refill_bits_data),
    .io_w_req_bits_waymask            (refill_waymask),
    .boreChildrenBd_bore_addr         (childBd_addr[0]),
    .boreChildrenBd_bore_addr_rd      (childBd_addr_rd[0]),
    .boreChildrenBd_bore_wdata        (childBd_wdata[0]),
    .boreChildrenBd_bore_wmask        (childBd_wmask[0]),
    .boreChildrenBd_bore_re           (childBd_re[0]),
    .boreChildrenBd_bore_we           (childBd_we[0]),
    .boreChildrenBd_bore_rdata        (childBd_rdata[0]),
    .boreChildrenBd_bore_ack          (childBd_ack[0]),
    .boreChildrenBd_bore_selectedOH   (childBd_selectedOH[0]),
    .boreChildrenBd_bore_array        (childBd_array[0]),
    .boreChildrenBd_bore_1_addr       (childBd_addr[1]),
    .boreChildrenBd_bore_1_addr_rd    (childBd_addr_rd[1]),
    .boreChildrenBd_bore_1_wdata      (childBd_wdata[1]),
    .boreChildrenBd_bore_1_wmask      (childBd_wmask[1]),
    .boreChildrenBd_bore_1_re         (childBd_re[1]),
    .boreChildrenBd_bore_1_we         (childBd_we[1]),
    .boreChildrenBd_bore_1_rdata      (childBd_rdata[1]),
    .boreChildrenBd_bore_1_ack        (childBd_ack[1]),
    .boreChildrenBd_bore_1_selectedOH (childBd_selectedOH[1]),
    .boreChildrenBd_bore_1_array      (childBd_array[1]),
    .boreChildrenBd_bore_2_addr       (childBd_addr[2]),
    .boreChildrenBd_bore_2_addr_rd    (childBd_addr_rd[2]),
    .boreChildrenBd_bore_2_wdata      (childBd_wdata[2]),
    .boreChildrenBd_bore_2_wmask      (childBd_wmask[2]),
    .boreChildrenBd_bore_2_re         (childBd_re[2]),
    .boreChildrenBd_bore_2_we         (childBd_we[2]),
    .boreChildrenBd_bore_2_rdata      (childBd_rdata[2]),
    .boreChildrenBd_bore_2_ack        (childBd_ack[2]),
    .boreChildrenBd_bore_2_selectedOH (childBd_selectedOH[2]),
    .boreChildrenBd_bore_2_array      (childBd_array[2]),
    .boreChildrenBd_bore_3_addr       (childBd_addr[3]),
    .boreChildrenBd_bore_3_addr_rd    (childBd_addr_rd[3]),
    .boreChildrenBd_bore_3_wdata      (childBd_wdata[3]),
    .boreChildrenBd_bore_3_wmask      (childBd_wmask[3]),
    .boreChildrenBd_bore_3_re         (childBd_re[3]),
    .boreChildrenBd_bore_3_we         (childBd_we[3]),
    .boreChildrenBd_bore_3_rdata      (childBd_rdata[3]),
    .boreChildrenBd_bore_3_ack        (childBd_ack[3]),
    .boreChildrenBd_bore_3_selectedOH (childBd_selectedOH[3]),
    .boreChildrenBd_bore_3_array      (childBd_array[3]),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_3_cgen)
  );

  MbistBitmapCache mbistBC (
    .clock               (clock),
    .reset               (reset),
    .mbist_array         (boreChildrenBd_bore_array),
    .mbist_all           (boreChildrenBd_bore_all),
    .mbist_req           (boreChildrenBd_bore_req),
    .mbist_ack           (boreChildrenBd_bore_ack),
    .mbist_writeen       (boreChildrenBd_bore_writeen),
    .mbist_be            (boreChildrenBd_bore_be),
    .mbist_addr          (boreChildrenBd_bore_addr),
    .mbist_indata        (boreChildrenBd_bore_indata),
    .mbist_readen        (boreChildrenBd_bore_readen),
    .mbist_addr_rd       (boreChildrenBd_bore_addr_rd),
    .mbist_outdata       (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr       (childBd_addr[0]),
    .toSRAM_0_addr_rd    (childBd_addr_rd[0]),
    .toSRAM_0_wdata      (childBd_wdata[0]),
    .toSRAM_0_wmask      (childBd_wmask[0]),
    .toSRAM_0_re         (childBd_re[0]),
    .toSRAM_0_we         (childBd_we[0]),
    .toSRAM_0_rdata      (childBd_rdata[0]),
    .toSRAM_0_ack        (childBd_ack[0]),
    .toSRAM_0_selectedOH (childBd_selectedOH[0]),
    .toSRAM_0_array      (childBd_array[0]),
    .toSRAM_1_addr       (childBd_addr[1]),
    .toSRAM_1_addr_rd    (childBd_addr_rd[1]),
    .toSRAM_1_wdata      (childBd_wdata[1]),
    .toSRAM_1_wmask      (childBd_wmask[1]),
    .toSRAM_1_re         (childBd_re[1]),
    .toSRAM_1_we         (childBd_we[1]),
    .toSRAM_1_rdata      (childBd_rdata[1]),
    .toSRAM_1_ack        (childBd_ack[1]),
    .toSRAM_1_selectedOH (childBd_selectedOH[1]),
    .toSRAM_1_array      (childBd_array[1]),
    .toSRAM_2_addr       (childBd_addr[2]),
    .toSRAM_2_addr_rd    (childBd_addr_rd[2]),
    .toSRAM_2_wdata      (childBd_wdata[2]),
    .toSRAM_2_wmask      (childBd_wmask[2]),
    .toSRAM_2_re         (childBd_re[2]),
    .toSRAM_2_we         (childBd_we[2]),
    .toSRAM_2_rdata      (childBd_rdata[2]),
    .toSRAM_2_ack        (childBd_ack[2]),
    .toSRAM_2_selectedOH (childBd_selectedOH[2]),
    .toSRAM_2_array      (childBd_array[2]),
    .toSRAM_3_addr       (childBd_addr[3]),
    .toSRAM_3_addr_rd    (childBd_addr_rd[3]),
    .toSRAM_3_wdata      (childBd_wdata[3]),
    .toSRAM_3_wmask      (childBd_wmask[3]),
    .toSRAM_3_re         (childBd_re[3]),
    .toSRAM_3_we         (childBd_we[3]),
    .toSRAM_3_rdata      (childBd_rdata[3]),
    .toSRAM_3_ack        (childBd_ack[3]),
    .toSRAM_3_selectedOH (childBd_selectedOH[3]),
    .toSRAM_3_array      (childBd_array[3])
  );

  // ===========================================================================
  // §9 输出
  // ===========================================================================
  assign io_req_ready       = stageReq_ready;
  assign io_resp_valid      = valid_1;
  assign io_resp_bits_hit   = hit;
  assign io_resp_bits_cfs_0 = cfs[0];
  assign io_resp_bits_cfs_1 = cfs[1];
  assign io_resp_bits_cfs_2 = cfs[2];
  assign io_resp_bits_cfs_3 = cfs[3];
  assign io_resp_bits_cfs_4 = cfs[4];
  assign io_resp_bits_cfs_5 = cfs[5];
  assign io_resp_bits_cfs_6 = cfs[6];
  assign io_resp_bits_cfs_7 = cfs[7];
  assign io_resp_bits_order = data_1_order;

endmodule

// BEGIN GENERATED(wrapper) —— 由 gen_mmu5.py 生成：BitmapCache 的 golden 同名 wrapper，
// 端口与 G1 golden 逐位同名，纯透传到 xs_BitmapCache_core（无任何逻辑）。
module BitmapCache(
  input  logic         clock,
  input  logic         reset,
  input  logic         io_sfence_valid,
  input  logic         io_csr_satp_changed,
  input  logic         io_csr_vsatp_changed,
  input  logic         io_csr_hgatp_changed,
  input  logic         io_csr_mbmc_BCLEAR,
  input  logic         io_csr_priv_virt_changed,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [7:0]   io_req_bits_order,
  input  logic [35:0]  io_req_bits_tag,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic         io_resp_bits_hit,
  output logic         io_resp_bits_cfs_0,
  output logic         io_resp_bits_cfs_1,
  output logic         io_resp_bits_cfs_2,
  output logic         io_resp_bits_cfs_3,
  output logic         io_resp_bits_cfs_4,
  output logic         io_resp_bits_cfs_5,
  output logic         io_resp_bits_cfs_6,
  output logic         io_resp_bits_cfs_7,
  output logic [7:0]   io_resp_bits_order,
  input  logic         io_refill_valid,
  input  logic [35:0]  io_refill_bits_tag,
  input  logic [63:0]  io_refill_bits_data,
  input  logic [5:0]   boreChildrenBd_bore_array,
  input  logic         boreChildrenBd_bore_all,
  input  logic         boreChildrenBd_bore_req,
  output logic         boreChildrenBd_bore_ack,
  input  logic         boreChildrenBd_bore_writeen,
  input  logic [1:0]   boreChildrenBd_bore_be,
  input  logic [5:0]   boreChildrenBd_bore_addr,
  input  logic [89:0]  boreChildrenBd_bore_indata,
  input  logic         boreChildrenBd_bore_readen,
  input  logic [5:0]   boreChildrenBd_bore_addr_rd,
  output logic [89:0]  boreChildrenBd_bore_outdata,
  input  logic         sigFromSrams_bore_ram_hold,
  input  logic         sigFromSrams_bore_ram_bypass,
  input  logic         sigFromSrams_bore_ram_bp_clken,
  input  logic         sigFromSrams_bore_ram_aux_clk,
  input  logic         sigFromSrams_bore_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_ram_mcp_hold,
  input  logic         sigFromSrams_bore_cgen,
  input  logic         sigFromSrams_bore_1_ram_hold,
  input  logic         sigFromSrams_bore_1_ram_bypass,
  input  logic         sigFromSrams_bore_1_ram_bp_clken,
  input  logic         sigFromSrams_bore_1_ram_aux_clk,
  input  logic         sigFromSrams_bore_1_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_1_ram_mcp_hold,
  input  logic         sigFromSrams_bore_1_cgen,
  input  logic         sigFromSrams_bore_2_ram_hold,
  input  logic         sigFromSrams_bore_2_ram_bypass,
  input  logic         sigFromSrams_bore_2_ram_bp_clken,
  input  logic         sigFromSrams_bore_2_ram_aux_clk,
  input  logic         sigFromSrams_bore_2_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_2_ram_mcp_hold,
  input  logic         sigFromSrams_bore_2_cgen,
  input  logic         sigFromSrams_bore_3_ram_hold,
  input  logic         sigFromSrams_bore_3_ram_bypass,
  input  logic         sigFromSrams_bore_3_ram_bp_clken,
  input  logic         sigFromSrams_bore_3_ram_aux_clk,
  input  logic         sigFromSrams_bore_3_ram_aux_ckbp,
  input  logic         sigFromSrams_bore_3_ram_mcp_hold,
  input  logic         sigFromSrams_bore_3_cgen,
  input  logic         cg_bore_cgen
);
  xs_BitmapCache_core u_core (
    .clock                            (clock),
    .reset                            (reset),
    .io_sfence_valid                  (io_sfence_valid),
    .io_csr_satp_changed              (io_csr_satp_changed),
    .io_csr_vsatp_changed             (io_csr_vsatp_changed),
    .io_csr_hgatp_changed             (io_csr_hgatp_changed),
    .io_csr_mbmc_BCLEAR               (io_csr_mbmc_BCLEAR),
    .io_csr_priv_virt_changed         (io_csr_priv_virt_changed),
    .io_req_ready                     (io_req_ready),
    .io_req_valid                     (io_req_valid),
    .io_req_bits_order                (io_req_bits_order),
    .io_req_bits_tag                  (io_req_bits_tag),
    .io_resp_ready                    (io_resp_ready),
    .io_resp_valid                    (io_resp_valid),
    .io_resp_bits_hit                 (io_resp_bits_hit),
    .io_resp_bits_cfs_0               (io_resp_bits_cfs_0),
    .io_resp_bits_cfs_1               (io_resp_bits_cfs_1),
    .io_resp_bits_cfs_2               (io_resp_bits_cfs_2),
    .io_resp_bits_cfs_3               (io_resp_bits_cfs_3),
    .io_resp_bits_cfs_4               (io_resp_bits_cfs_4),
    .io_resp_bits_cfs_5               (io_resp_bits_cfs_5),
    .io_resp_bits_cfs_6               (io_resp_bits_cfs_6),
    .io_resp_bits_cfs_7               (io_resp_bits_cfs_7),
    .io_resp_bits_order               (io_resp_bits_order),
    .io_refill_valid                  (io_refill_valid),
    .io_refill_bits_tag               (io_refill_bits_tag),
    .io_refill_bits_data              (io_refill_bits_data),
    .boreChildrenBd_bore_array        (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all          (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req          (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack          (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen      (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be           (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr         (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata       (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen       (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd      (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata      (boreChildrenBd_bore_outdata),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_3_cgen),
    .cg_bore_cgen                     (cg_bore_cgen)
  );
endmodule
// END GENERATED(wrapper)
