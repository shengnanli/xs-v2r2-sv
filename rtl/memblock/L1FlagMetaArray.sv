// =============================================================================
// xs_L1FlagMetaArray_core —— L1 DCache 标志位元数据阵列（可读重写）
//
// 对应 Chisel: xiangshan.cache.AsynchronousMetaArray.scala  class L1FlagMetaArray
//
// 在 DCache 中的位置：与 L1CohMetaArray 同构，但每条 cacheline 只存 1-bit 标志
//   （香山用它记录如 error / prefetch-valid 等布尔属性）。按 idx 读出某 set 全部
//   nWays 个 way 的 flag，写口按 way_en 更新某 way 的 flag。
//
// 寄存器堆而非 SRAM：meta_array 是 nSets×nWays 个 1-bit 寄存器。
//
// 读写时序（与 Coh 同样 1 拍读延迟、写 2 拍流水 + 读旁路），唯一差异在非旁路路径：
//   L1FlagMetaArray **未走 bypassRead 数据锁存分支**，而是 RegEnable(idx)，于下一拍
//   用“锁存后的 idx”组合读 meta_array[idx_r][way]。因 meta_array 在 S1 才更新，
//   读出的恰是更新后的值，与 Coh 锁存数据的写法功能等价，但寄存的是 idx 而非数据，
//   需逐字保持以与 golden 等价。
//
// 参数化覆盖两个 golden 变体：
//   L1FlagMetaArray   : READ_PORTS=4 WRITE_PORTS=1
//   L1FlagMetaArray_1 : READ_PORTS=5 WRITE_PORTS=4
// =============================================================================
module xs_L1FlagMetaArray_core import xs_l1metaarray_pkg::*; #(
  parameter int READ_PORTS  = 4,
  parameter int WRITE_PORTS = 1,
  // WDATA_CONST_MASK[wp]=1 表示写口 wp 的 flag 是编译期常量（父模块 tie-off），
  //   其常量值为 WDATA_CONST_VAL[wp]。与 golden(firtool 常量传播)一致：对这些写口
  //   **不生成 s1_way_wdata 寄存器**，直接用常量参与 meta_array 合并与旁路，避免出现
  //   golden 侧不存在的 impl-only 常量寄存器。默认全 0 = 全部为真实数据（sibling 变体）。
  parameter logic [WRITE_PORTS-1:0] WDATA_CONST_MASK = '0,
  parameter logic [WRITE_PORTS-1:0] WDATA_CONST_VAL  = '0
)(
  input  logic                      clock,
  input  logic                      reset,

  // 读口：每口给 idx，下一拍返回该 set 全部 nWays 个 way 的 flag
  input  logic                      io_read_valid [READ_PORTS],
  input  logic [IDX_BITS-1:0]       io_read_idx   [READ_PORTS],
  output logic                      io_resp       [READ_PORTS][N_WAYS],

  // 写口：way_en 为 one-hot way 选择，写入 flag
  input  logic                      io_write_valid  [WRITE_PORTS],
  input  logic [IDX_BITS-1:0]       io_write_idx    [WRITE_PORTS],
  input  logic [N_WAYS-1:0]         io_write_way_en [WRITE_PORTS],
  input  logic                      io_write_flag   [WRITE_PORTS]
);

  // =========================================================================
  // 架构状态：寄存器堆（nSets × nWays 个 1-bit flag），复位清 0
  // =========================================================================
  logic meta_array [N_SETS][N_WAYS];

  // =========================================================================
  // 写路径：S0 按 way 拆请求 → S1 打一拍 → 落寄存器堆
  // =========================================================================
  logic                s0_way_wen   [N_WAYS][WRITE_PORTS];
  logic [IDX_BITS-1:0] s0_way_waddr [N_WAYS][WRITE_PORTS];
  logic                s0_way_wdata [N_WAYS][WRITE_PORTS];
  logic                s1_way_wen   [N_WAYS][WRITE_PORTS];
  logic [IDX_BITS-1:0] s1_way_waddr [N_WAYS][WRITE_PORTS];
  // s1_way_wdata_eff: S1 在途写数据。真实数据口=打一拍寄存值；常量口=常量（无寄存器）。
  logic                s1_way_wdata_eff [N_WAYS][WRITE_PORTS];

  always_comb begin
    for (int wp = 0; wp < WRITE_PORTS; wp++) begin
      for (int w = 0; w < N_WAYS; w++) begin
        s0_way_wen  [w][wp] = io_write_valid[wp] & io_write_way_en[wp][w];
        s0_way_waddr[w][wp] = io_write_idx[wp];
        s0_way_wdata[w][wp] = io_write_flag[wp];
      end
    end
  end

  // S1 wen/waddr 恒打一拍（所有写口，含常量口——golden 对常量口保留 wen/waddr 寄存器）。
  // wdata 仅对真实数据口生成寄存器；常量口直接取常量（golden firtool 常量传播后无 wdata 寄存器）。
  always_ff @(posedge clock) begin
    for (int wp = 0; wp < WRITE_PORTS; wp++) begin
      for (int w = 0; w < N_WAYS; w++) begin
        s1_way_wen[w][wp] <= s0_way_wen[w][wp];
        if (s0_way_wen[w][wp])
          s1_way_waddr[w][wp] <= s0_way_waddr[w][wp];
      end
    end
  end

  genvar gwp, gwy;
  generate
    for (gwp = 0; gwp < WRITE_PORTS; gwp++) begin : g_wport
      if (WDATA_CONST_MASK[gwp]) begin : g_const_wdata
        // 常量写口：无 s1 wdata 寄存器，直接常量（与 golden 一致）
        for (gwy = 0; gwy < N_WAYS; gwy++) begin : g_const_way
          assign s1_way_wdata_eff[gwy][gwp] = WDATA_CONST_VAL[gwp];
        end
      end else begin : g_real_wdata
        // 真实数据写口：保留 s1 wdata 寄存器（sibling / 写口3）
        logic s1_wdata_r [N_WAYS];
        always_ff @(posedge clock) begin
          for (int w = 0; w < N_WAYS; w++)
            if (s0_way_wen[w][gwp])
              s1_wdata_r[w] <= s0_way_wdata[w][gwp];
        end
        for (gwy = 0; gwy < N_WAYS; gwy++) begin : g_real_way
          assign s1_way_wdata_eff[gwy][gwp] = s1_wdata_r[gwy];
        end
      end
    end
  endgenerate

  // 寄存器堆落盘：异步复位清 0，与 golden 的 async-reset 一致（FM 比对 DFF 复位引脚）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < N_SETS; s++)
        for (int w = 0; w < N_WAYS; w++)
          meta_array[s][w] <= 1'b0;
    end else begin
      for (int wp = 0; wp < WRITE_PORTS; wp++)
        for (int w = 0; w < N_WAYS; w++)
          if (s1_way_wen[w][wp])
            meta_array[s1_way_waddr[w][wp]][w] <= s1_way_wdata_eff[w][wp];
    end
  end

  // =========================================================================
  // 读路径：旁路选择 + 转发数据(同 Coh)；非旁路路径锁存 idx 再组合读寄存器堆
  // =========================================================================
  function automatic logic bypass_hit(
      input logic rd_idx_match_s0 [WRITE_PORTS],
      input logic rd_idx_match_s1 [WRITE_PORTS]
  );
    logic hit;
    hit = 1'b0;
    for (int wp = 0; wp < WRITE_PORTS; wp++)
      if (rd_idx_match_s1[wp] || rd_idx_match_s0[wp]) hit = 1'b1;
    return hit;
  endfunction

  genvar gp, gw;
  generate
    for (gp = 0; gp < READ_PORTS; gp++) begin : g_rport
      for (gw = 0; gw < N_WAYS; gw++) begin : g_way

        logic rd_bypass_sel;
        logic rd_bypass_data;
        always_comb begin
          logic m_s0 [WRITE_PORTS];
          logic m_s1 [WRITE_PORTS];
          rd_bypass_data = 1'b0;             // 与 Chisel DontCare 对齐
          for (int wp = 0; wp < WRITE_PORTS; wp++) begin
            m_s1[wp] = s1_way_wen[gw][wp] & (s1_way_waddr[gw][wp] == io_read_idx[gp]);
            m_s0[wp] = s0_way_wen[gw][wp] & (s0_way_waddr[gw][wp] == io_read_idx[gp]);
            if (m_s1[wp]) rd_bypass_data = s1_way_wdata_eff[gw][wp];
            if (m_s0[wp]) rd_bypass_data = s0_way_wdata[gw][wp];
          end
          rd_bypass_sel = bypass_hit(m_s0, m_s1);
        end

        // 非旁路路径：锁存 idx（read.valid 使能），下一拍用锁存 idx 组合读寄存器堆
        logic                sel_r;
        logic                bypass_data_r;
        logic [IDX_BITS-1:0] idx_r;
        always_ff @(posedge clock) begin
          if (io_read_valid[gp]) sel_r        <= rd_bypass_sel;
          if (rd_bypass_sel)     bypass_data_r <= rd_bypass_data;
          if (io_read_valid[gp]) idx_r        <= io_read_idx[gp];
        end

        assign io_resp[gp][gw] = sel_r ? bypass_data_r : meta_array[idx_r][gw];
      end
    end
  endgenerate

endmodule
