// =============================================================================
// xs_SMSPrefetcher_core —— SMS(空间-记忆流) 数据预取器顶层装配 glue（可读重写）
//
// 对应 Chisel: src/main/scala/xiangshan/mem/prefetch/SMSPrefetcher.scala
//   class SMSPrefetcher
//
// SMS = Spatial Memory Streaming 预取。它例化 5 个子模块：
//   - train_filter    (SMSTrainFilter)        : 训练输入过滤（3 端口 load → 单训练流）
//   - active_gen_table(ActiveGenerationTable)  : 活跃生成表（AGT，跟踪访问区域）
//   - stride          (StridePF)               : stride 检测辅助
//   - pht             (PatternHistoryTable)    : 模式历史表（PHT，SRAM 存历史模式）
//   - pf_filter       (PrefetchFilter)         : 预取请求过滤 + TLB/PMP + 发射
//   子模块均为纯逻辑；pht 内含 SRAMTemplate_134 → 厂商 SRAM 宏
//   sram_array_1p32x148m74s1h0l1b_pftch_pht（唯一黑盒，两侧对称）。
//
// 本核 = 顶层 glue（子模块在外层 wrapper 里例化 golden）：
//   1. train_vld_s0_last_REG：RegNext(train_filter.valid)（异步复位），门控 AGT s0 lookup；
//   2. train_*_s0 寄存 bank：train_filter 发训练时，算 s0 特征并锁存（供 AGT/Stride s0）：
//        - region_tag  = {vaddr[20:16]^[25:21]^[30:26], vaddr[15:10]}（区域 tag 折叠哈希）
//        - region_p1/m1_tag：region_addr±1 的同款折叠哈希 + allow_cross（进位/借位判定）
//        - pht_tag     = pc[19:7]
//        - pht_index   = {pc[1]^pc[6], pc[5:2]}
//        - region_offset = vaddr[9:6], region_paddr = paddr[47:10], region_vaddr = vaddr[49:10]
//   3. _probe_0 = pht.pf_gen_req_valid & io_pht_en（PHT 生成的预取请求经 pht_en 门控喂 filter）；
//   4. 输出：io_l2_req_valid = pf_l2_valid & io_enable & (|addr[47:31]) & addr<0x80000000000。
// =============================================================================
module xs_SMSPrefetcher_core (
  input  logic        clock,
  input  logic        reset,

  input  logic        io_enable,
  input  logic        io_pht_en,

  // ---- train_filter 训练请求（→ 核算 s0 特征）----
  input  logic        i_train_valid,
  input  logic [49:0] i_train_vaddr,
  input  logic [47:0] i_train_paddr,
  input  logic [49:0] i_train_pc,

  // ---- 核 → AGT / Stride 的 s0 lookup ----
  output logic        o_s0_lookup_valid,           // = train_vld_s0_last_REG
  output logic [10:0] o_region_tag_s0,
  output logic [10:0] o_region_p1_tag_s0,
  output logic [10:0] o_region_m1_tag_s0,
  output logic [3:0]  o_region_offset_s0,
  output logic [4:0]  o_pht_index_s0,
  output logic [12:0] o_pht_tag_s0,
  output logic        o_allow_cross_region_p1_s0,
  output logic        o_allow_cross_region_m1_s0,
  output logic [37:0] o_region_paddr_s0,
  output logic [39:0] o_region_vaddr_s0,
  output logic [9:0]  o_stride_s0_pc,               // train_s0_pc[9:0]（StridePF 用）

  // ---- pht → pf_filter 的 gen_req valid（经 pht_en 门控）----
  input  logic        i_pht_gen_req_valid,
  output logic        o_pf_gen_req_valid,           // = _probe_0

  // ---- pf_filter 的 L2 预取输出（→ 顶层门控）----
  input  logic        i_pf_l2_addr_valid,
  input  logic [47:0] i_pf_l2_addr_bits,
  output logic        io_l2_req_valid,
  output logic [47:0] io_l2_req_bits_addr
);

  // ---------------- s0 lastREG + 特征寄存 bank ----------------
  logic        train_vld_s0_last_REG;
  logic [49:0] train_s0_pc;
  logic [10:0] train_region_tag_s0;
  logic [10:0] train_region_p1_tag_s0;
  logic [10:0] train_region_m1_tag_s0;
  logic        train_allow_cross_region_p1_s0;
  logic        train_allow_cross_region_m1_s0;
  logic [12:0] train_pht_tag_s0;
  logic [4:0]  train_pht_index_s0;
  logic [3:0]  train_region_offset_s0;
  logic [37:0] train_region_paddr_s0;
  logic [39:0] train_region_vaddr_s0;

  // region_addr = vaddr[30:10]（21 位区域号），±1 用 22 位算进位/借位
  wire [21:0] region_addr    = {1'b0, i_train_vaddr[30:10]};
  wire [21:0] region_addr_p1 = region_addr + 22'h1;
  wire [21:0] region_addr_m1 = region_addr - 22'h1;

  // ---------------- 时序：s0 lastREG（异步复位）----------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) train_vld_s0_last_REG <= 1'b0;
    else       train_vld_s0_last_REG <= i_train_valid;
  end

  // ---------------- 时序：s0 特征寄存 bank（无复位，train_valid 使能）----------------
  always_ff @(posedge clock) begin
    if (i_train_valid) begin
      train_s0_pc <= i_train_pc;
      // region_tag = 折叠哈希高段 ^ 拼低 6 位
      train_region_tag_s0 <= {i_train_vaddr[20:16] ^ i_train_vaddr[25:21] ^ i_train_vaddr[30:26],
                              i_train_vaddr[15:10]};
      train_region_p1_tag_s0 <= {region_addr_p1[10:6] ^ region_addr_p1[15:11] ^ region_addr_p1[20:16],
                                 region_addr_p1[5:0]};
      train_region_m1_tag_s0 <= {region_addr_m1[10:6] ^ region_addr_m1[15:11] ^ region_addr_m1[20:16],
                                 region_addr_m1[5:0]};
      train_allow_cross_region_p1_s0 <= ~region_addr_p1[21];  // 无进位溢出才允许跨区
      train_allow_cross_region_m1_s0 <= ~region_addr_m1[21];  // 无借位下溢才允许跨区
      train_pht_tag_s0    <= i_train_pc[19:7];
      train_pht_index_s0  <= {i_train_pc[1] ^ i_train_pc[6], i_train_pc[5:2]};
      train_region_offset_s0 <= i_train_vaddr[9:6];
      train_region_paddr_s0  <= i_train_paddr[47:10];
      train_region_vaddr_s0  <= i_train_vaddr[49:10];
    end
  end

  // ---------------- 输出：s0 特征 ----------------
  assign o_s0_lookup_valid          = train_vld_s0_last_REG;
  assign o_region_tag_s0            = train_region_tag_s0;
  assign o_region_p1_tag_s0         = train_region_p1_tag_s0;
  assign o_region_m1_tag_s0         = train_region_m1_tag_s0;
  assign o_region_offset_s0         = train_region_offset_s0;
  assign o_pht_index_s0             = train_pht_index_s0;
  assign o_pht_tag_s0               = train_pht_tag_s0;
  assign o_allow_cross_region_p1_s0 = train_allow_cross_region_p1_s0;
  assign o_allow_cross_region_m1_s0 = train_allow_cross_region_m1_s0;
  assign o_region_paddr_s0          = train_region_paddr_s0;
  assign o_region_vaddr_s0          = train_region_vaddr_s0;
  assign o_stride_s0_pc             = train_s0_pc[9:0];

  // ---------------- pht gen_req 经 pht_en 门控喂 filter ----------------
  assign o_pf_gen_req_valid = i_pht_gen_req_valid & io_pht_en;

  // ---------------- 顶层 L2 预取输出门控 ----------------
  assign io_l2_req_valid = i_pf_l2_addr_valid & io_enable
                         & (|i_pf_l2_addr_bits[47:31])
                         & (i_pf_l2_addr_bits < 48'h80000000000);
  assign io_l2_req_bits_addr = i_pf_l2_addr_bits;

endmodule
