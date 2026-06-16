// =============================================================================
// xs_L1CohMetaArray_core —— L1 DCache 一致性状态元数据阵列（可读重写）
//
// 对应 Chisel: xiangshan.cache.AsynchronousMetaArray.scala  class L1CohMetaArray
//
// 在 DCache 中的位置：每条 cacheline 需要记录 TileLink 一致性状态(ClientMetadata)，
//   LoadPipe/MainPipe/ProbeQueue 在访问某 set 时，按 idx 读出该 set 全部 nWays 个
//   way 的 coh_state，配合 tag 命中判断这条线当前是否可读/可写、是否需要 probe/降级。
//   写口由 refill/probe/store 命中等更新某 way 的一致性状态。
//
// 寄存器堆而非 SRAM（“异步阵列”）：meta_array 是 nSets×nWays 个 2-bit 寄存器。
//
// 读写时序（1 拍读延迟，写 2 拍流水 + 读旁路）：
//   写：S0 收请求(way_en 逐 way 拆) → S1（打一拍）真正写入 meta_array。
//   读：S0 收 idx；为对抗 S0/S1 在途写造成的旧值，对每个 (读口,way) 做在途写转发：
//        若该 way 的 S1 在途写 或 S0 在途写命中本读 idx，则下一拍输出转发数据；
//        否则输出 S0 锁存(RegEnable on read.valid)的寄存器堆读值。
//   注意(与 L1Flag 的差异)：本模块 bypassRead=true，**非旁路路径锁存的是“数据”**
//     （S0 读出 meta_array[idx][way] 后打一拍），而非锁存 idx 再于 S1 组合读。
//     二者功能等价（meta_array 在 S1 才更新），但寄存语义不同，需逐字保持。
//
// 结构：meta entry 用 struct；nWays×readPorts 用 genvar/for 并行；在途写转发用
//   function 计算。行数远小于 golden(展平 7638 行)。
// =============================================================================
module xs_L1CohMetaArray_core import xs_l1metaarray_pkg::*; #(
  parameter int READ_PORTS  = 4,
  parameter int WRITE_PORTS = 1
)(
  input  logic                      clock,
  input  logic                      reset,

  // 读口：每口给 idx，下一拍返回该 set 全部 nWays 个 way 的一致性状态
  input  logic                      io_read_valid [READ_PORTS],
  input  logic [IDX_BITS-1:0]       io_read_idx   [READ_PORTS],
  output meta_coh_t                 io_resp       [READ_PORTS][N_WAYS],

  // 写口：way_en 为 one-hot way 选择，写入 coh_state
  input  logic                      io_write_valid  [WRITE_PORTS],
  input  logic [IDX_BITS-1:0]       io_write_idx    [WRITE_PORTS],
  input  logic [N_WAYS-1:0]         io_write_way_en [WRITE_PORTS],
  input  meta_coh_t                 io_write_meta   [WRITE_PORTS]
);

  // =========================================================================
  // 架构状态：寄存器堆（nSets × nWays 个 coh entry），复位清 0(=COH_NOTHING)
  // =========================================================================
  meta_coh_t meta_array [N_SETS][N_WAYS];

  // =========================================================================
  // 写路径：S0 按 way 拆请求 → S1 打一拍 → 落寄存器堆
  // 索引顺序 [way][wport] 与 Chisel 一致：way_en 逐 way 拆到各写口。
  // =========================================================================
  logic                s0_way_wen   [N_WAYS][WRITE_PORTS];
  logic [IDX_BITS-1:0] s0_way_waddr [N_WAYS][WRITE_PORTS];
  meta_coh_t           s0_way_wdata [N_WAYS][WRITE_PORTS];
  logic                s1_way_wen   [N_WAYS][WRITE_PORTS];
  logic [IDX_BITS-1:0] s1_way_waddr [N_WAYS][WRITE_PORTS];
  meta_coh_t           s1_way_wdata [N_WAYS][WRITE_PORTS];

  // S0 组合：把每个写口的请求按 way_en 拆到各 way
  always_comb begin
    for (int wp = 0; wp < WRITE_PORTS; wp++) begin
      for (int w = 0; w < N_WAYS; w++) begin
        s0_way_wen  [w][wp] = io_write_valid[wp] & io_write_way_en[wp][w];
        s0_way_waddr[w][wp] = io_write_idx[wp];
        s0_way_wdata[w][wp] = io_write_meta[wp];
      end
    end
  end

  // S1 在途写寄存（无复位，与 golden 一致：上电 X，UT 用 $isunknown 跳过）
  // wen 用 RegNext；waddr/wdata 用 RegEnable(s0_wen) 省功耗
  always_ff @(posedge clock) begin
    for (int wp = 0; wp < WRITE_PORTS; wp++) begin
      for (int w = 0; w < N_WAYS; w++) begin
        s1_way_wen[w][wp] <= s0_way_wen[w][wp];
        if (s0_way_wen[w][wp]) begin
          s1_way_waddr[w][wp] <= s0_way_waddr[w][wp];
          s1_way_wdata[w][wp] <= s0_way_wdata[w][wp];
        end
      end
    end
  end

  // 寄存器堆落盘：异步复位清 0（COH_NOTHING），与 golden 的 async-reset 一致——
  // 这关系到 DFF 复位引脚连接，FM 据此比对，必须保持异步复位语义。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < N_SETS; s++)
        for (int w = 0; w < N_WAYS; w++)
          meta_array[s][w] <= '0;
    end else begin
      for (int wp = 0; wp < WRITE_PORTS; wp++)
        for (int w = 0; w < N_WAYS; w++)
          if (s1_way_wen[w][wp])
            meta_array[s1_way_waddr[w][wp]][w] <= s1_way_wdata[w][wp];
    end
  end

  // =========================================================================
  // 读路径：每 (读口,way) 计算在途写转发选择 + 转发数据，下一拍 mux
  // =========================================================================

  // 纯函数：扫描某 way 全部写口的 S0/S1 在途写，判断是否需对给定读 idx 旁路
  function automatic logic bypass_hit(
      input logic                rd_idx_match_s0 [WRITE_PORTS],
      input logic                rd_idx_match_s1 [WRITE_PORTS]
  );
    logic hit;
    hit = 1'b0;
    for (int wp = 0; wp < WRITE_PORTS; wp++)
      // S1 与 S0 同时命中时，Chisel 后写(S0)覆盖：见下方 bypass_data 选择
      if (rd_idx_match_s1[wp] || rd_idx_match_s0[wp]) hit = 1'b1;
    return hit;
  endfunction

  genvar gp, gw;
  generate
    for (gp = 0; gp < READ_PORTS; gp++) begin : g_rport
      for (gw = 0; gw < N_WAYS; gw++) begin : g_way

        // 本拍(S0)在途写命中本读 idx 的标志与转发数据（组合）
        logic      rd_bypass_sel;
        meta_coh_t rd_bypass_data;
        always_comb begin
          logic m_s0 [WRITE_PORTS];
          logic m_s1 [WRITE_PORTS];
          rd_bypass_data = '0;               // 与 Chisel DontCare 对齐(无命中时不被选)
          for (int wp = 0; wp < WRITE_PORTS; wp++) begin
            m_s1[wp] = s1_way_wen[gw][wp] & (s1_way_waddr[gw][wp] == io_read_idx[gp]);
            m_s0[wp] = s0_way_wen[gw][wp] & (s0_way_waddr[gw][wp] == io_read_idx[gp]);
            // 选择顺序复刻 Chisel when 链：先 S1 后 S0，后者优先（最新写）
            if (m_s1[wp]) rd_bypass_data = s1_way_wdata[gw][wp];
            if (m_s0[wp]) rd_bypass_data = s0_way_wdata[gw][wp];
          end
          rd_bypass_sel = bypass_hit(m_s0, m_s1);
        end

        // S0->S1 锁存：选择位(read.valid 使能)、转发数据(命中使能)、寄存器堆读值(read.valid 使能)
        logic      sel_r;
        meta_coh_t bypass_data_r;
        meta_coh_t array_data_r;            // 锁存“数据”——bypassRead=true 路径
        always_ff @(posedge clock) begin
          if (io_read_valid[gp])  sel_r        <= rd_bypass_sel;
          if (rd_bypass_sel)      bypass_data_r <= rd_bypass_data;
          if (io_read_valid[gp])  array_data_r  <= meta_array[io_read_idx[gp]][gw];
        end

        assign io_resp[gp][gw] = sel_r ? bypass_data_r : array_data_r;
      end
    end
  endgenerate

endmodule
