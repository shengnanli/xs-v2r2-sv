// =============================================================================
// xs_l1metaarray_pkg —— L1 DCache 异步元数据阵列（Coh / Flag）的共享类型与参数
//
// 对应 Chisel: xiangshan.cache.AsynchronousMetaArray.scala
//   class L1CohMetaArray   —— 一致性状态(coherence)元数据阵列
//   class L1FlagMetaArray  —— 标志位(flag, 如 error/prefetch valid)元数据阵列
//   bundle Meta / MetaReadReq / CohMetaWriteReq / FlagMetaWriteReq
//
// 角色：DCache 每个 way 都要为每个 set 记录“这条 cacheline 现在处于什么一致性状态”
//   （Nothing/Branch/Trunk/Dirty，TileLink ClientMetadata，2 bit）以及若干 1-bit 标志。
//   这些元数据用**寄存器堆**实现（不是 SRAM），因此叫“异步”阵列：读不打拍取数，
//   组合给出当拍数据；写则经过 S0->S1 两拍流水后落寄存器堆。
//
// 为什么读侧要做 bypass：写有 2 拍延迟（S0 收请求，S1 才真正写进 meta_array）。
//   若一条读请求的 idx 恰好命中“正在 S0 或 S1 在途的写”，直接读寄存器堆会拿到旧值。
//   故对每个 (读口, way) 做在途写转发(bypass)，保证读到最新值。
//
// 组织：meta_array[nSets][nWays]，本配置 nSets=256(idxBits=8)、nWays=4。
//   - Coh entry = 2-bit coh_state（ClientMetadata.state）
//   - Flag entry = 1-bit flag
//   读口数/写口数由参数化覆盖（见各 class 的 readPorts/writePorts）。
//
// way 选择：写请求带 one-hot 的 way_en，对每个 way 独立判定是否写；读则一次返回
//   全部 nWays 份数据(resp[way])，由上层（DCache 命中比较）再做 tag 命中选 way。
//   本阵列本身**不做 tag 命中**，只按 idx 索引返回该 set 全部 way 的元数据。
// =============================================================================
package xs_l1metaarray_pkg;

  // ---------------- 物理参数（KunmingHu V2R2，DCacheParameters）----------------
  localparam int N_SETS   = 256;          // nSets
  localparam int IDX_BITS = 8;            // log2(nSets)
  localparam int N_WAYS   = 4;            // nWays
  localparam int COH_BITS = 2;            // ClientMetadata.state 宽（Nothing/Branch/Trunk/Dirty）

  // ClientMetadata 状态编码（TileLink ClientStates，仅用于阅读理解，逻辑上当 2-bit 透传）
  typedef enum logic [COH_BITS-1:0] {
    COH_NOTHING = 2'd0,                   // 无副本
    COH_BRANCH  = 2'd1,                   // 只读共享
    COH_TRUNK   = 2'd2,                   // 独占(可写未脏)
    COH_DIRTY   = 2'd3                    // 独占且已脏
  } coh_state_e;

  // 一致性元数据条目（与 Chisel class Meta 对应：只有一个 coh 字段）
  typedef struct packed {
    logic [COH_BITS-1:0] coh_state;
  } meta_coh_t;

endpackage

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

// 自动生成：xs-v2r2-sv/scripts/gen_l1metaarray.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护
// L1 元数据阵列 golden 同名 / xs 变体扁平包装：扁平端口 <-> 可读核数组端口。

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module L1CohMetaArray import xs_l1metaarray_pkg::*; (
  input clock,
  input reset,
  input io_read_0_valid,
  input [7:0] io_read_0_bits_idx,
  input io_read_1_valid,
  input [7:0] io_read_1_bits_idx,
  input io_read_2_valid,
  input [7:0] io_read_2_bits_idx,
  input io_read_3_valid,
  input [7:0] io_read_3_bits_idx,
  output [1:0] io_resp_0_0_coh_state,
  output [1:0] io_resp_0_1_coh_state,
  output [1:0] io_resp_0_2_coh_state,
  output [1:0] io_resp_0_3_coh_state,
  output [1:0] io_resp_1_0_coh_state,
  output [1:0] io_resp_1_1_coh_state,
  output [1:0] io_resp_1_2_coh_state,
  output [1:0] io_resp_1_3_coh_state,
  output [1:0] io_resp_2_0_coh_state,
  output [1:0] io_resp_2_1_coh_state,
  output [1:0] io_resp_2_2_coh_state,
  output [1:0] io_resp_2_3_coh_state,
  output [1:0] io_resp_3_0_coh_state,
  output [1:0] io_resp_3_1_coh_state,
  output [1:0] io_resp_3_2_coh_state,
  output [1:0] io_resp_3_3_coh_state,
  input io_write_0_valid,
  input [7:0] io_write_0_bits_idx,
  input [3:0] io_write_0_bits_way_en,
  input [1:0] io_write_0_bits_meta_coh_state
);
  logic                rvalid [4];
  logic [7:0] ridx   [4];
  logic                wvalid [1];
  logic [7:0] widx   [1];
  logic [3:0]   wen    [1];
  meta_coh_t           resp   [4][4];
  meta_coh_t           wdata  [1];
  always_comb begin
    rvalid[0] = io_read_0_valid;
    ridx[0]   = io_read_0_bits_idx;
    rvalid[1] = io_read_1_valid;
    ridx[1]   = io_read_1_bits_idx;
    rvalid[2] = io_read_2_valid;
    ridx[2]   = io_read_2_bits_idx;
    rvalid[3] = io_read_3_valid;
    ridx[3]   = io_read_3_bits_idx;
    wvalid[0] = io_write_0_valid;
    widx[0]   = io_write_0_bits_idx;
    wen[0]    = io_write_0_bits_way_en;
    wdata[0].coh_state = io_write_0_bits_meta_coh_state;
  end
  xs_L1CohMetaArray_core #(.READ_PORTS(4), .WRITE_PORTS(1)) u_core (
    .clock(clock), .reset(reset),
    .io_read_valid(rvalid), .io_read_idx(ridx), .io_resp(resp),
    .io_write_valid(wvalid), .io_write_idx(widx),
    .io_write_way_en(wen), .io_write_meta(wdata)
  );
  assign io_resp_0_0_coh_state = resp[0][0].coh_state;
  assign io_resp_0_1_coh_state = resp[0][1].coh_state;
  assign io_resp_0_2_coh_state = resp[0][2].coh_state;
  assign io_resp_0_3_coh_state = resp[0][3].coh_state;
  assign io_resp_1_0_coh_state = resp[1][0].coh_state;
  assign io_resp_1_1_coh_state = resp[1][1].coh_state;
  assign io_resp_1_2_coh_state = resp[1][2].coh_state;
  assign io_resp_1_3_coh_state = resp[1][3].coh_state;
  assign io_resp_2_0_coh_state = resp[2][0].coh_state;
  assign io_resp_2_1_coh_state = resp[2][1].coh_state;
  assign io_resp_2_2_coh_state = resp[2][2].coh_state;
  assign io_resp_2_3_coh_state = resp[2][3].coh_state;
  assign io_resp_3_0_coh_state = resp[3][0].coh_state;
  assign io_resp_3_1_coh_state = resp[3][1].coh_state;
  assign io_resp_3_2_coh_state = resp[3][2].coh_state;
  assign io_resp_3_3_coh_state = resp[3][3].coh_state;
endmodule
