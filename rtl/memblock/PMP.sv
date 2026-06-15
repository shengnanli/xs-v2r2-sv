// =============================================================================
// xs_PMP_core —— PMP/PMA 配置寄存器组 + CSR 写逻辑（可读重写）
//
// 对应 Chisel: xiangshan.backend.fu.PMP（trait PMPMethod + PMAMethod，
//   经 MaskedRegMap.generate 生成 CSR 读写映射）。
//
// 角色：保存 16 条 PMP 条目（物理内存保护）与 16 条 PMA 条目（物理内存属性）的
//   架构状态，响应来自 CSR 分发总线 (distribute_csr) 的写，把最新条目快照输出给
//   各处 PMPChecker（ITLB/DTLB/PTW 等）。本模块只“存与写”，匹配检查在 PMPChecker。
//
// 条目编码（cfg 8 bit）：[7]l [6]c [5]atomic [4:3]a [2]x [1]w [0]r（见 pmp_pkg）。
//   8 个 cfg 打包进 1 个 64 位 CSR：cfg CSR 只有 2 个（条目0-7 / 8-15）。
//
// CSR 地址（见 CSRConst.scala / rocket CSRs）：
//   PMP : pmpcfg0=0x3A0  pmpcfg2=0x3A2   pmpaddr0..15=0x3B0..0x3BF
//   PMA : pmacfg0=0x7C0  pmacfg2=0x7C2   pmaaddr0..15=0x7C8..0x7D7
//
// 写时序：与 golden 一致，CSR 写打一拍生效——
//   wdata 在 w.valid 当拍寄存；每个 CSR 的写使能 wen 也寄存一拍；下一拍按 wen 用
//   寄存的 wdata 更新对应寄存器。（MaskedRegMap 的实现产物）
//
// 写语义（PMPReadWriteMethod）：
//   - 写 cfg：逐字节，若该字节旧 l=1（locked）则保持旧值不可改；否则写入新值，但
//       w := w & r（W 不能无 R），且 A 经 CoarserGrain 规整（去 NA4）。
//       写 cfg 且新模式为 NAPOT 时，顺带按“现有 addr”刷新该条目的匹配 mask。
//   - 写 addr：locked' = cfg[i].l || (cfg[i+1].l && cfg[i+1].tor)（自身锁，或下一条
//       TOR 且锁——TOR 用本条 addr 作下界，故被下条锁连带保护）；非锁定才写入，并按
//       新 addr 刷新 mask。最后一条无“下一条”，只看自身锁。
//
// 输出 io_pmp_*/io_pma_* 直接给出寄存器当前值（addr 为内部存储值，匹配在 checker）。
//
// 本模块为单层叶子（无子模块例化），全部条目用数组 + for 表达，便于阅读与 FM 比对。
// =============================================================================
module xs_PMP_core import xs_pmp_pkg::*; (
  input  logic                     clock,
  input  logic                     reset,
  input  logic                     io_distribute_csr_w_valid,
  input  logic [11:0]              io_distribute_csr_w_bits_addr,
  input  logic [63:0]              io_distribute_csr_w_bits_data,
  output pmp_entry_t [NUM_PMP-1:0] io_pmp,
  output pmp_entry_t [NUM_PMA-1:0] io_pma
);

  // ---- CSR 地址常量 ----
  localparam logic [11:0] PMPCFG0 = 12'h3A0, PMPCFG2 = 12'h3A2;
  localparam logic [11:0] PMPADDR0 = 12'h3B0;                 // pmpaddr0..15 连续
  localparam logic [11:0] PMACFG0 = 12'h7C0, PMACFG2 = 12'h7C2;
  localparam logic [11:0] PMAADDR0 = 12'h7C8;                 // pmaaddr0..15 连续

  // ---- PMA 复位默认值（来自 Chisel pma_init，描述香山 SoC 地址空间属性）----
  // cfgMerged[0]=条目0-7, cfgMerged[1]=条目8-15。地址/掩码见下。这些是平台固定属性，
  // 软件一般不再改（多数条目 NAPOT/TOR 描述 DDR/MMIO/外设可否缓存与原子）。
  localparam logic [63:0] PMA_CFG0_INIT = 64'h0B0B0B0F0B000000;
  localparam logic [63:0] PMA_CFG1_INIT = 64'h186F0B080B0B0B0F;

  // 寄存器组：两个 bank（[0]=PMP，[1]=PMA），各 2 个 cfgMerged + 16 addr + 16 mask
  // 用数组承载，输出时再拆成 io 结构。
  logic [63:0]                pmp_cfg_merged [2];   // PMP 条目 0-7 / 8-15 的 cfg
  logic [PMP_ADDR_REG_W-1:0]  pmpMapping_addr  [NUM_PMP];
  logic [PMP_ADDR_BITS-1:0]   pmpMapping_mask  [NUM_PMP];
  logic [63:0]                pma_cfg_merged [2];
  logic [PMP_ADDR_REG_W-1:0]  pmaMapping_addr  [NUM_PMA];
  logic [PMP_ADDR_BITS-1:0]   pmaMapping_mask  [NUM_PMA];

  // 写流水寄存：wdata 与各 CSR 的写使能（打一拍）
  logic [63:0] wdata_reg;
  logic        wen_pmpcfg [2];
  logic        wen_pmacfg [2];
  logic        wen_pmpaddr [NUM_PMP];
  logic        wen_pmaaddr [NUM_PMA];

  wire wval = io_distribute_csr_w_valid;
  wire [11:0] waddr = io_distribute_csr_w_bits_addr;

  // 单条目下一拍 {addr, mask} 的打包宽度（高位 addr，低位 mask）
  localparam int ADDR_MASK_W = PMP_ADDR_REG_W + PMP_ADDR_BITS;  // 46 + 48 = 94

  // mask 更新优先序（1=cfg 写优先，0=addr 写优先）。两个写使能物理互斥，优先序不影响
  // 功能，仅为与 golden(firtool 调度)逐条目对齐以利 Formality 签名比对。
  localparam logic [NUM_PMP-1:0] PMP_CFG_FIRST =
    16'b1100_0100_1111_1111;  // 条目15..0：见 golden 各 mask_i 首个 if 分支
  localparam logic [NUM_PMA-1:0] PMA_CFG_FIRST =
    16'b1111_1111_1100_1111;  // 条目15..0

  // =========================================================================
  // cfg 写函数：给定旧的 64 位 cfgMerged 与待写 wdata，返回新 64 位 cfgMerged。
  // 逐字节：旧 locked 则保持；否则取 wdata，w&=r，a 规整（CoarserGrain 去 NA4）。
  // c/atomic(保留位 6/5) 直接随 wdata 写入（PMP 中无意义但照样存）。
  // =========================================================================
  function automatic logic [63:0] xs_write_cfg(input logic [63:0] oldv, input logic [63:0] wd);
    logic [63:0] nv;
    for (int i = 0; i < CFG_PER_CSR; i++) begin
      automatic int b = i*8;
      automatic logic old_l = oldv[b+7];
      automatic logic [1:0] new_a = xs_coarsen_a(wd[b+4 -: 2]);
      if (old_l) begin
        nv[b +: 8] = oldv[b +: 8];                 // 锁定，保持旧值
      end else begin
        nv[b+7]      = wd[b+7];                     // l
        nv[b+6]      = wd[b+6];                     // c
        nv[b+5]      = wd[b+5];                     // atomic
        nv[b+4 -: 2] = new_a;                       // a (规整)
        nv[b+2]      = wd[b+2];                     // x
        nv[b+1]      = wd[b+1] & wd[b+0];           // w := w & r
        nv[b+0]      = wd[b+0];                     // r
      end
    end
    return nv;
  endfunction

  // 取第 i 条目（同 bank 内）的 locked / tor，用于 addr 锁定判断
  function automatic logic xs_cfg_locked(input logic [63:0] merged, input int idx_in_csr);
    return merged[idx_in_csr*8 + 7];
  endfunction
  function automatic logic xs_cfg_tor(input logic [63:0] merged, input int idx_in_csr);
    return (merged[idx_in_csr*8 + 4 -: 2] == A_TOR);
  endfunction

  // =========================================================================
  // 单条目 addr/mask 的下一拍值（纯函数：只读形参，不碰非局部信号）。返回 {addr,mask}。
  //   1) 若“写 cfg 且未锁 且新模式 NAPOT”→ 用现有 addr 重算 mask（write_cfg_vec）。
  //   2) 否则若“写本条 addr 且未锁”→ 写入新 addr，并按新 addr 重算 mask（write_addr）。
  //   3) 否则保持原值。
  // 未锁定 locked' = cfg.l | (next_cfg.l & next_cfg.tor)；最后一条 next_cfg 传 0。
  //   self_cfg / next_cfg 为本条/下一条的 8 位 cfg 字节。
  // =========================================================================
  function automatic logic [ADDR_MASK_W-1:0] xs_next_entry(
      input logic [7:0]                 self_cfg,    // 本条目现有 cfg 字节
      input logic [7:0]                 next_cfg,    // 下一条目现有 cfg 字节（末条传 0）
      input logic [7:0]                 wd_cfg_byte, // 写 cfg 时本条目对应的 wdata 字节
      input logic [PMP_ADDR_REG_W-1:0]  wd_addr,     // 写 addr 时的 wdata 低 46 位
      input logic [PMP_ADDR_REG_W-1:0]  addr,        // 现有 addr
      input logic [PMP_ADDR_BITS-1:0]   mask,        // 现有 mask
      input logic                       wen_cfg,     // 写本条所属 cfg CSR
      input logic                       wen_addr,    // 写本条 addr CSR
      input logic                       cfg_first);  // mask 更新优先序（对齐 golden）
    automatic logic self_l   = self_cfg[7];
    automatic logic next_l   = next_cfg[7];
    automatic logic next_tor = (next_cfg[4:3] == A_TOR);
    automatic logic addr_locked = self_l | (next_l & next_tor);
    automatic logic [1:0] cur_a = xs_coarsen_a(wd_cfg_byte[4:3]); // 写 cfg 后本条新 a
    automatic logic a0 = self_cfg[3];                              // 现有 cfg 的 a[0]
    automatic logic [PMP_ADDR_REG_W-1:0] nx_addr = addr;
    automatic logic [PMP_ADDR_BITS-1:0]  nx_mask = mask;
    automatic logic cfg_napot = wen_cfg & ~self_l & cur_a[1];   // 写 cfg 把本条设成 NAPOT 未锁
    // addr：仅由“写本条 addr 且未锁”更新。
    if (wen_addr & ~addr_locked) nx_addr = wd_addr;
    // mask 更新两路：
    //   addr 写：进入 wen_addr 分支，未锁则用新 addr 重算（a0=现有 cfg a[0]），锁则保持。
    //   cfg 写→NAPOT 未锁：用现有 addr 重算（a0=新 a[0]）。
    // wen_cfg 与 wen_addr 物理互斥（不同 CSR 地址）；firtool 对不同条目用了不同书写顺序，
    // cfg_first 据 golden 对齐：进入“先”那一路的 wen 分支后即不再看另一路（与 golden 同构）。
    if (cfg_first) begin
      if (cfg_napot)              nx_mask = xs_match_mask(addr, cur_a[0]);
      else if (wen_addr & ~addr_locked) nx_mask = xs_match_mask(wd_addr, a0);
    end else begin
      if (wen_addr) begin
        if (~addr_locked)         nx_mask = xs_match_mask(wd_addr, a0);  // 锁则保持
      end else if (cfg_napot)     nx_mask = xs_match_mask(addr, cur_a[0]);
    end
    return {nx_addr, nx_mask};
  endfunction

  // =========================================================================
  // 复位：PMP 全 0；PMA 按平台默认值。
  // =========================================================================
  // PMA 默认地址/掩码（来自 golden 复位值），用 localparam 数组表达。
  localparam logic [PMP_ADDR_REG_W-1:0] PMA_ADDR_INIT [NUM_PMA] = '{
    46'h0,           46'h0,           46'h0,           46'h4000000,
    46'h8000000,     46'hC004000,     46'hC014000,     46'hE008000,
    46'hE008400,     46'hE008800,     46'hE400000,     46'hE400800,
    46'hE800000,     46'h20000000,    46'h20000000000, 46'h1FFFFFFFFFFF };
  localparam logic [PMP_ADDR_BITS-1:0] PMA_MASK_INIT [NUM_PMA] = '{
    48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF,
    48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFF, 48'hFFFFFFFFFFFF };

  // =========================================================================
  // 时序块：写流水 + 条目寄存器更新
  // =========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      pmp_cfg_merged[0] <= 64'h0;
      pmp_cfg_merged[1] <= 64'h0;
      pma_cfg_merged[0] <= PMA_CFG0_INIT;
      pma_cfg_merged[1] <= PMA_CFG1_INIT;
      for (int i = 0; i < 2; i++)       begin wen_pmpcfg[i]  <= 1'b0; wen_pmacfg[i]  <= 1'b0; end
      for (int i = 0; i < NUM_PMP; i++) begin wen_pmpaddr[i] <= 1'b0; end
      for (int i = 0; i < NUM_PMA; i++) begin wen_pmaaddr[i] <= 1'b0; end
    end else begin
      // ---- 写使能打一拍 ----
      wen_pmpcfg[0] <= wval & (waddr == PMPCFG0);
      wen_pmpcfg[1] <= wval & (waddr == PMPCFG2);
      wen_pmacfg[0] <= wval & (waddr == PMACFG0);
      wen_pmacfg[1] <= wval & (waddr == PMACFG2);
      for (int i = 0; i < NUM_PMP; i++)
        wen_pmpaddr[i] <= wval & (waddr == (PMPADDR0 + i[11:0]));
      for (int i = 0; i < NUM_PMA; i++)
        wen_pmaaddr[i] <= wval & (waddr == (PMAADDR0 + i[11:0]));

      // ---- cfg 寄存器更新 ----
      if (wen_pmpcfg[0]) pmp_cfg_merged[0] <= xs_write_cfg(pmp_cfg_merged[0], wdata_reg);
      if (wen_pmpcfg[1]) pmp_cfg_merged[1] <= xs_write_cfg(pmp_cfg_merged[1], wdata_reg);
      if (wen_pmacfg[0]) pma_cfg_merged[0] <= xs_write_cfg(pma_cfg_merged[0], wdata_reg);
      if (wen_pmacfg[1]) pma_cfg_merged[1] <= xs_write_cfg(pma_cfg_merged[1], wdata_reg);

    end
  end

  // =========================================================================
  // addr / mask 寄存器：每条目一个 always_ff（genvar 展开，所有位选都是常量索引，
  // 避免变量位选/数组变量下标导致的综合/FM 歧义）。每条目调纯函数 xs_next_entry。
  //   下一条目 cfg 字节：用 localparam 算好每条目的“下一条 byte 偏移”，末条传 0。
  // =========================================================================
  genvar gi;
  generate
    for (gi = 0; gi < NUM_PMP; gi++) begin : g_pmp_entry
      localparam int CSR  = gi / CFG_PER_CSR;       // 本条所属 cfg CSR
      localparam int SUB  = gi % CFG_PER_CSR;       // 本条在 CSR 内字节序号
      localparam int NCSR = (gi == NUM_PMP-1) ? 0 : (gi+1) / CFG_PER_CSR;
      localparam int NSUB = (gi == NUM_PMP-1) ? 0 : (gi+1) % CFG_PER_CSR;
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          pmpMapping_addr[gi] <= '0;
          pmpMapping_mask[gi] <= '0;
        end else begin
          automatic logic [ADDR_MASK_W-1:0] nx = xs_next_entry(
            pmp_cfg_merged[CSR][SUB*8 +: 8],
            (gi == NUM_PMP-1) ? 8'h0 : pmp_cfg_merged[NCSR][NSUB*8 +: 8],
            wdata_reg[SUB*8 +: 8], wdata_reg[PMP_ADDR_REG_W-1:0],
            pmpMapping_addr[gi], pmpMapping_mask[gi],
            wen_pmpcfg[CSR], wen_pmpaddr[gi], PMP_CFG_FIRST[gi]);
          pmpMapping_addr[gi] <= nx[PMP_ADDR_BITS +: PMP_ADDR_REG_W];
          pmpMapping_mask[gi] <= nx[0 +: PMP_ADDR_BITS];
        end
      end
    end
    for (gi = 0; gi < NUM_PMA; gi++) begin : g_pma_entry
      localparam int CSR  = gi / CFG_PER_CSR;
      localparam int SUB  = gi % CFG_PER_CSR;
      localparam int NCSR = (gi == NUM_PMA-1) ? 0 : (gi+1) / CFG_PER_CSR;
      localparam int NSUB = (gi == NUM_PMA-1) ? 0 : (gi+1) % CFG_PER_CSR;
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          pmaMapping_addr[gi] <= PMA_ADDR_INIT[gi];
          pmaMapping_mask[gi] <= PMA_MASK_INIT[gi];
        end else begin
          automatic logic [ADDR_MASK_W-1:0] nx = xs_next_entry(
            pma_cfg_merged[CSR][SUB*8 +: 8],
            (gi == NUM_PMA-1) ? 8'h0 : pma_cfg_merged[NCSR][NSUB*8 +: 8],
            wdata_reg[SUB*8 +: 8], wdata_reg[PMP_ADDR_REG_W-1:0],
            pmaMapping_addr[gi], pmaMapping_mask[gi],
            wen_pmacfg[CSR], wen_pmaaddr[gi], PMA_CFG_FIRST[gi]);
          pmaMapping_addr[gi] <= nx[PMP_ADDR_BITS +: PMP_ADDR_REG_W];
          pmaMapping_mask[gi] <= nx[0 +: PMP_ADDR_BITS];
        end
      end
    end
  endgenerate

  // wdata 单独在 posedge clock（无复位）寄存，仅 valid 时更新（同 golden）
  always_ff @(posedge clock) begin
    if (io_distribute_csr_w_valid)
      wdata_reg <= io_distribute_csr_w_bits_data;
  end

  // =========================================================================
  // 输出：把寄存器组拆成条目结构
  // =========================================================================
  always_comb begin
    for (int i = 0; i < NUM_PMP; i++) begin
      automatic int csr = i / CFG_PER_CSR;
      io_pmp[i].cfg  = xs_cfg_from_byte(pmp_cfg_merged[csr], i % CFG_PER_CSR);
      io_pmp[i].addr = pmpMapping_addr[i];
      io_pmp[i].mask = pmpMapping_mask[i];
    end
    for (int i = 0; i < NUM_PMA; i++) begin
      automatic int csr = i / CFG_PER_CSR;
      io_pma[i].cfg  = xs_cfg_from_byte(pma_cfg_merged[csr], i % CFG_PER_CSR);
      io_pma[i].addr = pmaMapping_addr[i];
      io_pma[i].mask = pmaMapping_mask[i];
    end
  end

endmodule
