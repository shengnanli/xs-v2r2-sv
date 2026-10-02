// =============================================================================
//  PMP.sv —— 分布式 PMP / PMA 表的"本地副本"（CSR 写入口 + 32 项 PMP + 32 项 PMA）
// -----------------------------------------------------------------------------
//  位置：L2TLB 里的 pmp（Chisel: backend/fu/PMP.scala class PMP）。CSR 单元每次写 pmpcfg* / pmpaddr* /
//        pmacfg* / pmaaddr* 时，都把这次写（地址 + 数据）广播到 io_distribute_csr；各个需要做物理地址
//        权限检查的地方（这里是 L2TLB 的页表遍历器）各自维护一份同样的表，供 PMPChecker 比对。
//  输出：每项的 cfg（l/a/x/w/r，PMA 另有 c/atomic、没有 l）、addr（pmpaddr 寄存器值，46 位）、
//        mask（NAPOT 匹配用的预计算掩码，48 位）。表本身不提供读口（这一副本只写不读）。
//
//  核心机制（与 CSR 单元里那份完全同一套 MaskedRegMap 写规则）：
//    · 写入打一拍：wen_reg = RegNext(写有效 && 地址命中)，wdata_reg = RegEnable(写数据)，下一拍才真正写表
//      （"减少扇出"，MaskedRegMap.generate 的注释原话）。每个 CSR 地址一个 wen_reg，共 72 个。
//    · pmpcfg 写（一个 64 位 CSR 管 8 项）：逐项看，**已锁（l=1）的项不变**；没锁的项写入新值，
//      其中 w 只有在 r 也为 1 时才能置（W=1,R=0 是保留组合），a 因粒度 4KB（PlatformGrain=12 > 2）
//      把 NA4 并成 NAPOT：a = {a[1], |a}。若新 a 是 NAPOT，顺便用本项现有 addr 重算 mask。
//    · pmpaddr 写：本项锁住、或**下一项**是锁住的 TOR（它把本项当下界）时不变；否则写入，并按本项
//      现有 cfg 重算 mask。最后一项没有"下一项"。
//    · mask = match_mask(a[0], addr)：把 {addr, a[0]} 低 10 位强制为 1（4KB 粒度），取"最低的 0 及其以下"
//      为 1 的掩码，再补 2 位 —— 即 NAPOT 区域内可变的地址位。
//  复位值：PMP 全 0；PMA 是平台的地址映射表（见 pmp_pkg 的 PMA_INIT_*），由 SoC 配置决定。
//
//  文件结构（单文件规范）：pmp_pkg → xs_PMP_core（可读核）→ PMP（golden 同名 wrapper）。
//  子模块：无。
//  设计源：src/main/scala/xiangshan/backend/fu/PMP.scala（PMPMethod.pmp_gen_mapping、PMPReadWriteMethodBare）、
//          PMA.scala（pma_init）、utility RegMap.scala（MaskedRegMap.generate）
// =============================================================================

// =============================================================================
//  pmp_pkg —— 常量、cfg 结构、复位值表、纯函数
// =============================================================================
package pmp_pkg;

  localparam int NUM       = 32;          // NumPMPReal = NumPMAReal = 32
  localparam int CFG_CSRS  = NUM / 8;     // 一个 64 位 cfg CSR 管 8 项
  localparam int ADDR_W    = 46;          // PMPAddrBits(48) - PMPOffBits(2)
  localparam int MASK_W    = 48;          // PMPAddrBits

  // CSR 地址（PMXLEN=64 时 cfg CSR 只有偶数号：pmpcfg0/2/4/6）
  localparam logic [11:0] PMPCFG_BASE  = 12'h3A0;
  localparam logic [11:0] PMPADDR_BASE = 12'h3B0;
  localparam logic [11:0] PMACFG_BASE  = 12'h7C0;
  localparam logic [11:0] PMAADDR_BASE = 12'h7C8;

  // 一项的配置字节（PMPConfig）：l | c | atomic | a(2) | x | w | r
  //   PMP 里 c/atomic 是保留位；PMA 里 c = 可缓存，atomic = 支持原子操作。
  typedef struct packed {
    logic       l;
    logic       c;
    logic       atomic;
    logic [1:0] a;        // 0 OFF / 1 TOR / 2 NA4 / 3 NAPOT
    logic       x;
    logic       w;
    logic       r;
  } pm_cfg_t;

  localparam logic [1:0] A_TOR = 2'd1;

  // ---- PMA 复位值（平台地址映射；由 SoC 的 PMAConfigs 生成，0 号项在最后一个 cfg 字节）----
  //   addr 是 pmpaddr 格式（物理地址 >> 2）；mask 由 addr 与 a 预计算。只列非零项，其余项复位为 0。
  localparam logic [63:0] PMA_INIT_CFG [CFG_CSRS] = '{
      64'h0,
      64'h0,
      64'h0B0B0B0F0B000000,
      64'h186F0B080B0B0B0F };
  localparam logic [ADDR_W-1:0] PMA_INIT_ADDR [NUM] = '{
      46'h0, 46'h0, 46'h0, 46'h0, 46'h0, 46'h0, 46'h0, 46'h0,
      46'h0, 46'h0, 46'h0, 46'h0, 46'h0, 46'h0, 46'h0, 46'h0,
      46'h0, 46'h0, 46'h0,
      46'h4000000,           // 19: 0x0010000000
      46'h8000000,           // 20: 0x0020000000
      46'hC004000,           // 21: 0x0030010000
      46'hC014000,           // 22: 0x0030050000
      46'hE008000,           // 23: 0x0038020000
      46'hE008400,           // 24: 0x0038021000
      46'hE008800,           // 25: 0x0038022000
      46'hE400000,           // 26: 0x0039000000
      46'hE400800,           // 27: 0x0039002000
      46'hE800000,           // 28: 0x003A000000
      46'h20000000,          // 29: 0x0080000000
      46'h20000000000,       // 30: 0x0800000000000
      46'h1FFFFFFFFFFF };    // 31: 全地址空间上界
  // mask 复位：除最后一项（覆盖全部地址）外都是 4KB 粒度的 0xFFF
  function automatic logic [MASK_W-1:0] pma_init_mask(input int i);
    return (i == NUM - 1) ? 48'hFFFFFFFFFFFF : 48'hFFF;
  endfunction

  // match_mask(cfg, paddr)：NAPOT 匹配掩码。{paddr, a[0]} 的低 10 位先强制为 1（4KB 粒度），
  //   x & ~(x+1) 取出"最低的 0 以下全为 1"，再左移补上 2 位 PMPOffBits。结果截到 48 位，
  //   所以只有 paddr[44:0] 参与。
  function automatic logic [MASK_W-1:0] match_mask(input logic a0, input logic [44:0] paddr);
    logic [45:0] c;
    c = {paddr, a0} | 46'h3FF;
    return {c & ~(46'(c + 1'b1)), 2'b11};
  endfunction

  // 写一个 cfg 字节（write_cfg_vec 的单项）：锁住的不变；否则 w 需要 r、NA4 并入 NAPOT
  function automatic pm_cfg_t write_cfg(input pm_cfg_t old, input pm_cfg_t wr);
    pm_cfg_t n;
    if (old.l) return old;
    n   = wr;
    n.w = wr.w & wr.r;
    n.a = {wr.a[1], |wr.a};
    return n;
  endfunction

endpackage

// =============================================================================
//  xs_PMP_core —— 可读核
// -----------------------------------------------------------------------------
//  分节：§1 写入打拍  §2 两张表（状态数组第一维 0 = PMP、1 = PMA，结构完全相同，
//        只差 CSR 基地址与复位值）  §3 输出
// =============================================================================
module xs_PMP_core
  import pmp_pkg::*;
(
  input  logic              clock,
  input  logic              reset,
  input  logic              csr_w_valid,
  input  logic [11:0]       csr_w_addr,
  input  logic [63:0]       csr_w_data,
  output pm_cfg_t [NUM-1:0]           pmp_cfg,
  output logic    [NUM-1:0][ADDR_W-1:0] pmp_addr,
  output logic    [NUM-1:0][MASK_W-1:0] pmp_mask,
  output pm_cfg_t [NUM-1:0]           pma_cfg,
  output logic    [NUM-1:0][ADDR_W-1:0] pma_addr,
  output logic    [NUM-1:0][MASK_W-1:0] pma_mask
);

  // ===========================================================================
  // §1 写入打拍：数据存一份（不复位），每张表的每个 CSR 地址各一个"上一拍写我"的标志（复位为 0）
  // ===========================================================================
  logic [63:0] wdata_reg;
  always_ff @(posedge clock) begin
    if (csr_w_valid) wdata_reg <= csr_w_data;
  end

  // ===========================================================================
  // §2 两张表
  // ===========================================================================
  //  第一维 t：0 = PMP 表（pmpcfg*/pmpaddr*），1 = PMA 表（pmacfg*/pmaaddr*）
  logic [63:0]       cfg_merged [2][CFG_CSRS];   // 每个 cfg CSR 管 8 项
  logic [ADDR_W-1:0] addr       [2][NUM];
  logic [MASK_W-1:0] mask       [2][NUM];
  logic              cfg_wen    [2][CFG_CSRS];   // 上一拍写了第 k 个 cfg CSR
  logic              addr_wen   [2][NUM];        // 上一拍写了第 i 个 addr CSR
  pm_cfg_t           cfg        [2][NUM];        // cfg_merged 按字节拆开

  for (genvar t = 0; t < 2; t++) begin : mapping
    localparam logic [11:0] CFG_BASE  = (t == 0) ? PMPCFG_BASE  : PMACFG_BASE;
    localparam logic [11:0] ADDR_BASE = (t == 0) ? PMPADDR_BASE : PMAADDR_BASE;

    for (genvar i = 0; i < NUM; i++) begin : g_cfg_view
      assign cfg[t][i] = pm_cfg_t'(cfg_merged[t][i / 8][8 * (i % 8) +: 8]);
    end

    // ---- 写使能打拍 ----
    for (genvar k = 0; k < CFG_CSRS; k++) begin : g_cfg_wen
      always_ff @(posedge clock or posedge reset) begin
        if (reset) cfg_wen[t][k] <= 1'b0;
        else       cfg_wen[t][k] <= csr_w_valid & (csr_w_addr == 12'(CFG_BASE + 2 * k));
      end
    end
    for (genvar i = 0; i < NUM; i++) begin : g_addr_wen
      always_ff @(posedge clock or posedge reset) begin
        if (reset) addr_wen[t][i] <= 1'b0;
        else       addr_wen[t][i] <= csr_w_valid & (csr_w_addr == 12'(ADDR_BASE + i));
      end
    end

    // ---- cfg 写：8 项逐项按 write_cfg 更新 ----
    for (genvar k = 0; k < CFG_CSRS; k++) begin : g_cfg_csr
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          cfg_merged[t][k] <= (t == 0) ? 64'h0 : PMA_INIT_CFG[k];
        end else if (cfg_wen[t][k]) begin
          for (int j = 0; j < 8; j++)
            cfg_merged[t][k][8 * j +: 8] <= write_cfg(cfg[t][8 * k + j], pm_cfg_t'(wdata_reg[8 * j +: 8]));
        end
      end
    end

    // ---- addr 写 + mask 维护 ----
    for (genvar i = 0; i < NUM; i++) begin : g_entry
      // 本项锁住，或下一项是锁住的 TOR（本项是它的下界）时，addr 不可写；最后一项没有"下一项"
      wire next_locks_me = (i == NUM - 1) ? 1'b0
                         : (cfg[t][(i + 1) % NUM].l & (cfg[t][(i + 1) % NUM].a == A_TOR));
      wire addr_locked   = cfg[t][i].l | next_locks_me;
      // 本项所在 cfg CSR 被写、本项没锁、写入后是 NAPOT：按现有 addr 重算 mask
      pm_cfg_t new_cfg;
      assign new_cfg = write_cfg(cfg[t][i], pm_cfg_t'(wdata_reg[8 * (i % 8) +: 8]));
      wire cfg_napot_write = cfg_wen[t][i / 8] & ~cfg[t][i].l & new_cfg.a[1];

      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          addr[t][i] <= (t == 0) ? '0 : PMA_INIT_ADDR[i];
          mask[t][i] <= (t == 0) ? '0 : pma_init_mask(i);
        end else begin
          if (cfg_napot_write)
            mask[t][i] <= match_mask(new_cfg.a[0], addr[t][i][44:0]);
          if (addr_wen[t][i] & ~addr_locked) begin
            addr[t][i] <= wdata_reg[ADDR_W-1:0];
            mask[t][i] <= match_mask(cfg[t][i].a[0], wdata_reg[44:0]);
          end
        end
      end
    end
  end

  // ===========================================================================
  // §3 输出
  // ===========================================================================
  for (genvar i = 0; i < NUM; i++) begin : g_out
    assign pmp_cfg[i]  = cfg[0][i];
    assign pmp_addr[i] = addr[0][i];
    assign pmp_mask[i] = mask[0][i];
    assign pma_cfg[i]  = cfg[1][i];
    assign pma_addr[i] = addr[1][i];
    assign pma_mask[i] = mask[1][i];
  end

endmodule

// =============================================================================
//  PMP —— golden 同名 wrapper：端口逐位同名同序，只做展平
// =============================================================================
module PMP
  import pmp_pkg::*;
(
  // BEGIN GENERATED(pmp_ports) —— scripts/gen_mmuleaf.py
  input         clock,
  input         reset,
  input         io_distribute_csr_w_valid,
  input  [11:0] io_distribute_csr_w_bits_addr,
  input  [63:0] io_distribute_csr_w_bits_data,
  output        io_pmp_0_cfg_l,
  output [1:0]  io_pmp_0_cfg_a,
  output        io_pmp_0_cfg_x,
  output        io_pmp_0_cfg_w,
  output        io_pmp_0_cfg_r,
  output [45:0] io_pmp_0_addr,
  output [47:0] io_pmp_0_mask,
  output        io_pmp_1_cfg_l,
  output [1:0]  io_pmp_1_cfg_a,
  output        io_pmp_1_cfg_x,
  output        io_pmp_1_cfg_w,
  output        io_pmp_1_cfg_r,
  output [45:0] io_pmp_1_addr,
  output [47:0] io_pmp_1_mask,
  output        io_pmp_2_cfg_l,
  output [1:0]  io_pmp_2_cfg_a,
  output        io_pmp_2_cfg_x,
  output        io_pmp_2_cfg_w,
  output        io_pmp_2_cfg_r,
  output [45:0] io_pmp_2_addr,
  output [47:0] io_pmp_2_mask,
  output        io_pmp_3_cfg_l,
  output [1:0]  io_pmp_3_cfg_a,
  output        io_pmp_3_cfg_x,
  output        io_pmp_3_cfg_w,
  output        io_pmp_3_cfg_r,
  output [45:0] io_pmp_3_addr,
  output [47:0] io_pmp_3_mask,
  output        io_pmp_4_cfg_l,
  output [1:0]  io_pmp_4_cfg_a,
  output        io_pmp_4_cfg_x,
  output        io_pmp_4_cfg_w,
  output        io_pmp_4_cfg_r,
  output [45:0] io_pmp_4_addr,
  output [47:0] io_pmp_4_mask,
  output        io_pmp_5_cfg_l,
  output [1:0]  io_pmp_5_cfg_a,
  output        io_pmp_5_cfg_x,
  output        io_pmp_5_cfg_w,
  output        io_pmp_5_cfg_r,
  output [45:0] io_pmp_5_addr,
  output [47:0] io_pmp_5_mask,
  output        io_pmp_6_cfg_l,
  output [1:0]  io_pmp_6_cfg_a,
  output        io_pmp_6_cfg_x,
  output        io_pmp_6_cfg_w,
  output        io_pmp_6_cfg_r,
  output [45:0] io_pmp_6_addr,
  output [47:0] io_pmp_6_mask,
  output        io_pmp_7_cfg_l,
  output [1:0]  io_pmp_7_cfg_a,
  output        io_pmp_7_cfg_x,
  output        io_pmp_7_cfg_w,
  output        io_pmp_7_cfg_r,
  output [45:0] io_pmp_7_addr,
  output [47:0] io_pmp_7_mask,
  output        io_pmp_8_cfg_l,
  output [1:0]  io_pmp_8_cfg_a,
  output        io_pmp_8_cfg_x,
  output        io_pmp_8_cfg_w,
  output        io_pmp_8_cfg_r,
  output [45:0] io_pmp_8_addr,
  output [47:0] io_pmp_8_mask,
  output        io_pmp_9_cfg_l,
  output [1:0]  io_pmp_9_cfg_a,
  output        io_pmp_9_cfg_x,
  output        io_pmp_9_cfg_w,
  output        io_pmp_9_cfg_r,
  output [45:0] io_pmp_9_addr,
  output [47:0] io_pmp_9_mask,
  output        io_pmp_10_cfg_l,
  output [1:0]  io_pmp_10_cfg_a,
  output        io_pmp_10_cfg_x,
  output        io_pmp_10_cfg_w,
  output        io_pmp_10_cfg_r,
  output [45:0] io_pmp_10_addr,
  output [47:0] io_pmp_10_mask,
  output        io_pmp_11_cfg_l,
  output [1:0]  io_pmp_11_cfg_a,
  output        io_pmp_11_cfg_x,
  output        io_pmp_11_cfg_w,
  output        io_pmp_11_cfg_r,
  output [45:0] io_pmp_11_addr,
  output [47:0] io_pmp_11_mask,
  output        io_pmp_12_cfg_l,
  output [1:0]  io_pmp_12_cfg_a,
  output        io_pmp_12_cfg_x,
  output        io_pmp_12_cfg_w,
  output        io_pmp_12_cfg_r,
  output [45:0] io_pmp_12_addr,
  output [47:0] io_pmp_12_mask,
  output        io_pmp_13_cfg_l,
  output [1:0]  io_pmp_13_cfg_a,
  output        io_pmp_13_cfg_x,
  output        io_pmp_13_cfg_w,
  output        io_pmp_13_cfg_r,
  output [45:0] io_pmp_13_addr,
  output [47:0] io_pmp_13_mask,
  output        io_pmp_14_cfg_l,
  output [1:0]  io_pmp_14_cfg_a,
  output        io_pmp_14_cfg_x,
  output        io_pmp_14_cfg_w,
  output        io_pmp_14_cfg_r,
  output [45:0] io_pmp_14_addr,
  output [47:0] io_pmp_14_mask,
  output        io_pmp_15_cfg_l,
  output [1:0]  io_pmp_15_cfg_a,
  output        io_pmp_15_cfg_x,
  output        io_pmp_15_cfg_w,
  output        io_pmp_15_cfg_r,
  output [45:0] io_pmp_15_addr,
  output [47:0] io_pmp_15_mask,
  output        io_pmp_16_cfg_l,
  output [1:0]  io_pmp_16_cfg_a,
  output        io_pmp_16_cfg_x,
  output        io_pmp_16_cfg_w,
  output        io_pmp_16_cfg_r,
  output [45:0] io_pmp_16_addr,
  output [47:0] io_pmp_16_mask,
  output        io_pmp_17_cfg_l,
  output [1:0]  io_pmp_17_cfg_a,
  output        io_pmp_17_cfg_x,
  output        io_pmp_17_cfg_w,
  output        io_pmp_17_cfg_r,
  output [45:0] io_pmp_17_addr,
  output [47:0] io_pmp_17_mask,
  output        io_pmp_18_cfg_l,
  output [1:0]  io_pmp_18_cfg_a,
  output        io_pmp_18_cfg_x,
  output        io_pmp_18_cfg_w,
  output        io_pmp_18_cfg_r,
  output [45:0] io_pmp_18_addr,
  output [47:0] io_pmp_18_mask,
  output        io_pmp_19_cfg_l,
  output [1:0]  io_pmp_19_cfg_a,
  output        io_pmp_19_cfg_x,
  output        io_pmp_19_cfg_w,
  output        io_pmp_19_cfg_r,
  output [45:0] io_pmp_19_addr,
  output [47:0] io_pmp_19_mask,
  output        io_pmp_20_cfg_l,
  output [1:0]  io_pmp_20_cfg_a,
  output        io_pmp_20_cfg_x,
  output        io_pmp_20_cfg_w,
  output        io_pmp_20_cfg_r,
  output [45:0] io_pmp_20_addr,
  output [47:0] io_pmp_20_mask,
  output        io_pmp_21_cfg_l,
  output [1:0]  io_pmp_21_cfg_a,
  output        io_pmp_21_cfg_x,
  output        io_pmp_21_cfg_w,
  output        io_pmp_21_cfg_r,
  output [45:0] io_pmp_21_addr,
  output [47:0] io_pmp_21_mask,
  output        io_pmp_22_cfg_l,
  output [1:0]  io_pmp_22_cfg_a,
  output        io_pmp_22_cfg_x,
  output        io_pmp_22_cfg_w,
  output        io_pmp_22_cfg_r,
  output [45:0] io_pmp_22_addr,
  output [47:0] io_pmp_22_mask,
  output        io_pmp_23_cfg_l,
  output [1:0]  io_pmp_23_cfg_a,
  output        io_pmp_23_cfg_x,
  output        io_pmp_23_cfg_w,
  output        io_pmp_23_cfg_r,
  output [45:0] io_pmp_23_addr,
  output [47:0] io_pmp_23_mask,
  output        io_pmp_24_cfg_l,
  output [1:0]  io_pmp_24_cfg_a,
  output        io_pmp_24_cfg_x,
  output        io_pmp_24_cfg_w,
  output        io_pmp_24_cfg_r,
  output [45:0] io_pmp_24_addr,
  output [47:0] io_pmp_24_mask,
  output        io_pmp_25_cfg_l,
  output [1:0]  io_pmp_25_cfg_a,
  output        io_pmp_25_cfg_x,
  output        io_pmp_25_cfg_w,
  output        io_pmp_25_cfg_r,
  output [45:0] io_pmp_25_addr,
  output [47:0] io_pmp_25_mask,
  output        io_pmp_26_cfg_l,
  output [1:0]  io_pmp_26_cfg_a,
  output        io_pmp_26_cfg_x,
  output        io_pmp_26_cfg_w,
  output        io_pmp_26_cfg_r,
  output [45:0] io_pmp_26_addr,
  output [47:0] io_pmp_26_mask,
  output        io_pmp_27_cfg_l,
  output [1:0]  io_pmp_27_cfg_a,
  output        io_pmp_27_cfg_x,
  output        io_pmp_27_cfg_w,
  output        io_pmp_27_cfg_r,
  output [45:0] io_pmp_27_addr,
  output [47:0] io_pmp_27_mask,
  output        io_pmp_28_cfg_l,
  output [1:0]  io_pmp_28_cfg_a,
  output        io_pmp_28_cfg_x,
  output        io_pmp_28_cfg_w,
  output        io_pmp_28_cfg_r,
  output [45:0] io_pmp_28_addr,
  output [47:0] io_pmp_28_mask,
  output        io_pmp_29_cfg_l,
  output [1:0]  io_pmp_29_cfg_a,
  output        io_pmp_29_cfg_x,
  output        io_pmp_29_cfg_w,
  output        io_pmp_29_cfg_r,
  output [45:0] io_pmp_29_addr,
  output [47:0] io_pmp_29_mask,
  output        io_pmp_30_cfg_l,
  output [1:0]  io_pmp_30_cfg_a,
  output        io_pmp_30_cfg_x,
  output        io_pmp_30_cfg_w,
  output        io_pmp_30_cfg_r,
  output [45:0] io_pmp_30_addr,
  output [47:0] io_pmp_30_mask,
  output        io_pmp_31_cfg_l,
  output [1:0]  io_pmp_31_cfg_a,
  output        io_pmp_31_cfg_x,
  output        io_pmp_31_cfg_w,
  output        io_pmp_31_cfg_r,
  output [45:0] io_pmp_31_addr,
  output [47:0] io_pmp_31_mask,
  output        io_pma_0_cfg_c,
  output        io_pma_0_cfg_atomic,
  output [1:0]  io_pma_0_cfg_a,
  output        io_pma_0_cfg_x,
  output        io_pma_0_cfg_w,
  output        io_pma_0_cfg_r,
  output [45:0] io_pma_0_addr,
  output [47:0] io_pma_0_mask,
  output        io_pma_1_cfg_c,
  output        io_pma_1_cfg_atomic,
  output [1:0]  io_pma_1_cfg_a,
  output        io_pma_1_cfg_x,
  output        io_pma_1_cfg_w,
  output        io_pma_1_cfg_r,
  output [45:0] io_pma_1_addr,
  output [47:0] io_pma_1_mask,
  output        io_pma_2_cfg_c,
  output        io_pma_2_cfg_atomic,
  output [1:0]  io_pma_2_cfg_a,
  output        io_pma_2_cfg_x,
  output        io_pma_2_cfg_w,
  output        io_pma_2_cfg_r,
  output [45:0] io_pma_2_addr,
  output [47:0] io_pma_2_mask,
  output        io_pma_3_cfg_c,
  output        io_pma_3_cfg_atomic,
  output [1:0]  io_pma_3_cfg_a,
  output        io_pma_3_cfg_x,
  output        io_pma_3_cfg_w,
  output        io_pma_3_cfg_r,
  output [45:0] io_pma_3_addr,
  output [47:0] io_pma_3_mask,
  output        io_pma_4_cfg_c,
  output        io_pma_4_cfg_atomic,
  output [1:0]  io_pma_4_cfg_a,
  output        io_pma_4_cfg_x,
  output        io_pma_4_cfg_w,
  output        io_pma_4_cfg_r,
  output [45:0] io_pma_4_addr,
  output [47:0] io_pma_4_mask,
  output        io_pma_5_cfg_c,
  output        io_pma_5_cfg_atomic,
  output [1:0]  io_pma_5_cfg_a,
  output        io_pma_5_cfg_x,
  output        io_pma_5_cfg_w,
  output        io_pma_5_cfg_r,
  output [45:0] io_pma_5_addr,
  output [47:0] io_pma_5_mask,
  output        io_pma_6_cfg_c,
  output        io_pma_6_cfg_atomic,
  output [1:0]  io_pma_6_cfg_a,
  output        io_pma_6_cfg_x,
  output        io_pma_6_cfg_w,
  output        io_pma_6_cfg_r,
  output [45:0] io_pma_6_addr,
  output [47:0] io_pma_6_mask,
  output        io_pma_7_cfg_c,
  output        io_pma_7_cfg_atomic,
  output [1:0]  io_pma_7_cfg_a,
  output        io_pma_7_cfg_x,
  output        io_pma_7_cfg_w,
  output        io_pma_7_cfg_r,
  output [45:0] io_pma_7_addr,
  output [47:0] io_pma_7_mask,
  output        io_pma_8_cfg_c,
  output        io_pma_8_cfg_atomic,
  output [1:0]  io_pma_8_cfg_a,
  output        io_pma_8_cfg_x,
  output        io_pma_8_cfg_w,
  output        io_pma_8_cfg_r,
  output [45:0] io_pma_8_addr,
  output [47:0] io_pma_8_mask,
  output        io_pma_9_cfg_c,
  output        io_pma_9_cfg_atomic,
  output [1:0]  io_pma_9_cfg_a,
  output        io_pma_9_cfg_x,
  output        io_pma_9_cfg_w,
  output        io_pma_9_cfg_r,
  output [45:0] io_pma_9_addr,
  output [47:0] io_pma_9_mask,
  output        io_pma_10_cfg_c,
  output        io_pma_10_cfg_atomic,
  output [1:0]  io_pma_10_cfg_a,
  output        io_pma_10_cfg_x,
  output        io_pma_10_cfg_w,
  output        io_pma_10_cfg_r,
  output [45:0] io_pma_10_addr,
  output [47:0] io_pma_10_mask,
  output        io_pma_11_cfg_c,
  output        io_pma_11_cfg_atomic,
  output [1:0]  io_pma_11_cfg_a,
  output        io_pma_11_cfg_x,
  output        io_pma_11_cfg_w,
  output        io_pma_11_cfg_r,
  output [45:0] io_pma_11_addr,
  output [47:0] io_pma_11_mask,
  output        io_pma_12_cfg_c,
  output        io_pma_12_cfg_atomic,
  output [1:0]  io_pma_12_cfg_a,
  output        io_pma_12_cfg_x,
  output        io_pma_12_cfg_w,
  output        io_pma_12_cfg_r,
  output [45:0] io_pma_12_addr,
  output [47:0] io_pma_12_mask,
  output        io_pma_13_cfg_c,
  output        io_pma_13_cfg_atomic,
  output [1:0]  io_pma_13_cfg_a,
  output        io_pma_13_cfg_x,
  output        io_pma_13_cfg_w,
  output        io_pma_13_cfg_r,
  output [45:0] io_pma_13_addr,
  output [47:0] io_pma_13_mask,
  output        io_pma_14_cfg_c,
  output        io_pma_14_cfg_atomic,
  output [1:0]  io_pma_14_cfg_a,
  output        io_pma_14_cfg_x,
  output        io_pma_14_cfg_w,
  output        io_pma_14_cfg_r,
  output [45:0] io_pma_14_addr,
  output [47:0] io_pma_14_mask,
  output        io_pma_15_cfg_c,
  output        io_pma_15_cfg_atomic,
  output [1:0]  io_pma_15_cfg_a,
  output        io_pma_15_cfg_x,
  output        io_pma_15_cfg_w,
  output        io_pma_15_cfg_r,
  output [45:0] io_pma_15_addr,
  output [47:0] io_pma_15_mask,
  output        io_pma_16_cfg_c,
  output        io_pma_16_cfg_atomic,
  output [1:0]  io_pma_16_cfg_a,
  output        io_pma_16_cfg_x,
  output        io_pma_16_cfg_w,
  output        io_pma_16_cfg_r,
  output [45:0] io_pma_16_addr,
  output [47:0] io_pma_16_mask,
  output        io_pma_17_cfg_c,
  output        io_pma_17_cfg_atomic,
  output [1:0]  io_pma_17_cfg_a,
  output        io_pma_17_cfg_x,
  output        io_pma_17_cfg_w,
  output        io_pma_17_cfg_r,
  output [45:0] io_pma_17_addr,
  output [47:0] io_pma_17_mask,
  output        io_pma_18_cfg_c,
  output        io_pma_18_cfg_atomic,
  output [1:0]  io_pma_18_cfg_a,
  output        io_pma_18_cfg_x,
  output        io_pma_18_cfg_w,
  output        io_pma_18_cfg_r,
  output [45:0] io_pma_18_addr,
  output [47:0] io_pma_18_mask,
  output        io_pma_19_cfg_c,
  output        io_pma_19_cfg_atomic,
  output [1:0]  io_pma_19_cfg_a,
  output        io_pma_19_cfg_x,
  output        io_pma_19_cfg_w,
  output        io_pma_19_cfg_r,
  output [45:0] io_pma_19_addr,
  output [47:0] io_pma_19_mask,
  output        io_pma_20_cfg_c,
  output        io_pma_20_cfg_atomic,
  output [1:0]  io_pma_20_cfg_a,
  output        io_pma_20_cfg_x,
  output        io_pma_20_cfg_w,
  output        io_pma_20_cfg_r,
  output [45:0] io_pma_20_addr,
  output [47:0] io_pma_20_mask,
  output        io_pma_21_cfg_c,
  output        io_pma_21_cfg_atomic,
  output [1:0]  io_pma_21_cfg_a,
  output        io_pma_21_cfg_x,
  output        io_pma_21_cfg_w,
  output        io_pma_21_cfg_r,
  output [45:0] io_pma_21_addr,
  output [47:0] io_pma_21_mask,
  output        io_pma_22_cfg_c,
  output        io_pma_22_cfg_atomic,
  output [1:0]  io_pma_22_cfg_a,
  output        io_pma_22_cfg_x,
  output        io_pma_22_cfg_w,
  output        io_pma_22_cfg_r,
  output [45:0] io_pma_22_addr,
  output [47:0] io_pma_22_mask,
  output        io_pma_23_cfg_c,
  output        io_pma_23_cfg_atomic,
  output [1:0]  io_pma_23_cfg_a,
  output        io_pma_23_cfg_x,
  output        io_pma_23_cfg_w,
  output        io_pma_23_cfg_r,
  output [45:0] io_pma_23_addr,
  output [47:0] io_pma_23_mask,
  output        io_pma_24_cfg_c,
  output        io_pma_24_cfg_atomic,
  output [1:0]  io_pma_24_cfg_a,
  output        io_pma_24_cfg_x,
  output        io_pma_24_cfg_w,
  output        io_pma_24_cfg_r,
  output [45:0] io_pma_24_addr,
  output [47:0] io_pma_24_mask,
  output        io_pma_25_cfg_c,
  output        io_pma_25_cfg_atomic,
  output [1:0]  io_pma_25_cfg_a,
  output        io_pma_25_cfg_x,
  output        io_pma_25_cfg_w,
  output        io_pma_25_cfg_r,
  output [45:0] io_pma_25_addr,
  output [47:0] io_pma_25_mask,
  output        io_pma_26_cfg_c,
  output        io_pma_26_cfg_atomic,
  output [1:0]  io_pma_26_cfg_a,
  output        io_pma_26_cfg_x,
  output        io_pma_26_cfg_w,
  output        io_pma_26_cfg_r,
  output [45:0] io_pma_26_addr,
  output [47:0] io_pma_26_mask,
  output        io_pma_27_cfg_c,
  output        io_pma_27_cfg_atomic,
  output [1:0]  io_pma_27_cfg_a,
  output        io_pma_27_cfg_x,
  output        io_pma_27_cfg_w,
  output        io_pma_27_cfg_r,
  output [45:0] io_pma_27_addr,
  output [47:0] io_pma_27_mask,
  output        io_pma_28_cfg_c,
  output        io_pma_28_cfg_atomic,
  output [1:0]  io_pma_28_cfg_a,
  output        io_pma_28_cfg_x,
  output        io_pma_28_cfg_w,
  output        io_pma_28_cfg_r,
  output [45:0] io_pma_28_addr,
  output [47:0] io_pma_28_mask,
  output        io_pma_29_cfg_c,
  output        io_pma_29_cfg_atomic,
  output [1:0]  io_pma_29_cfg_a,
  output        io_pma_29_cfg_x,
  output        io_pma_29_cfg_w,
  output        io_pma_29_cfg_r,
  output [45:0] io_pma_29_addr,
  output [47:0] io_pma_29_mask,
  output        io_pma_30_cfg_c,
  output        io_pma_30_cfg_atomic,
  output [1:0]  io_pma_30_cfg_a,
  output        io_pma_30_cfg_x,
  output        io_pma_30_cfg_w,
  output        io_pma_30_cfg_r,
  output [45:0] io_pma_30_addr,
  output [47:0] io_pma_30_mask,
  output        io_pma_31_cfg_c,
  output        io_pma_31_cfg_atomic,
  output [1:0]  io_pma_31_cfg_a,
  output        io_pma_31_cfg_x,
  output        io_pma_31_cfg_w,
  output        io_pma_31_cfg_r,
  output [45:0] io_pma_31_addr,
  output [47:0] io_pma_31_mask
  // END GENERATED
);

  pm_cfg_t [NUM-1:0]             pmp_cfg, pma_cfg;
  logic    [NUM-1:0][ADDR_W-1:0] pmp_addr, pma_addr;
  logic    [NUM-1:0][MASK_W-1:0] pmp_mask, pma_mask;

  xs_PMP_core u_core (
    .clock       (clock),
    .reset       (reset),
    .csr_w_valid (io_distribute_csr_w_valid),
    .csr_w_addr  (io_distribute_csr_w_bits_addr),
    .csr_w_data  (io_distribute_csr_w_bits_data),
    .pmp_cfg     (pmp_cfg),
    .pmp_addr    (pmp_addr),
    .pmp_mask    (pmp_mask),
    .pma_cfg     (pma_cfg),
    .pma_addr    (pma_addr),
    .pma_mask    (pma_mask)
  );

  // BEGIN GENERATED(pmp_outputs) —— scripts/gen_mmuleaf.py
  assign io_pmp_0_cfg_l = pmp_cfg[0].l;
  assign io_pmp_0_cfg_a = pmp_cfg[0].a;
  assign io_pmp_0_cfg_x = pmp_cfg[0].x;
  assign io_pmp_0_cfg_w = pmp_cfg[0].w;
  assign io_pmp_0_cfg_r = pmp_cfg[0].r;
  assign io_pmp_0_addr = pmp_addr[0];
  assign io_pmp_0_mask = pmp_mask[0];
  assign io_pmp_1_cfg_l = pmp_cfg[1].l;
  assign io_pmp_1_cfg_a = pmp_cfg[1].a;
  assign io_pmp_1_cfg_x = pmp_cfg[1].x;
  assign io_pmp_1_cfg_w = pmp_cfg[1].w;
  assign io_pmp_1_cfg_r = pmp_cfg[1].r;
  assign io_pmp_1_addr = pmp_addr[1];
  assign io_pmp_1_mask = pmp_mask[1];
  assign io_pmp_2_cfg_l = pmp_cfg[2].l;
  assign io_pmp_2_cfg_a = pmp_cfg[2].a;
  assign io_pmp_2_cfg_x = pmp_cfg[2].x;
  assign io_pmp_2_cfg_w = pmp_cfg[2].w;
  assign io_pmp_2_cfg_r = pmp_cfg[2].r;
  assign io_pmp_2_addr = pmp_addr[2];
  assign io_pmp_2_mask = pmp_mask[2];
  assign io_pmp_3_cfg_l = pmp_cfg[3].l;
  assign io_pmp_3_cfg_a = pmp_cfg[3].a;
  assign io_pmp_3_cfg_x = pmp_cfg[3].x;
  assign io_pmp_3_cfg_w = pmp_cfg[3].w;
  assign io_pmp_3_cfg_r = pmp_cfg[3].r;
  assign io_pmp_3_addr = pmp_addr[3];
  assign io_pmp_3_mask = pmp_mask[3];
  assign io_pmp_4_cfg_l = pmp_cfg[4].l;
  assign io_pmp_4_cfg_a = pmp_cfg[4].a;
  assign io_pmp_4_cfg_x = pmp_cfg[4].x;
  assign io_pmp_4_cfg_w = pmp_cfg[4].w;
  assign io_pmp_4_cfg_r = pmp_cfg[4].r;
  assign io_pmp_4_addr = pmp_addr[4];
  assign io_pmp_4_mask = pmp_mask[4];
  assign io_pmp_5_cfg_l = pmp_cfg[5].l;
  assign io_pmp_5_cfg_a = pmp_cfg[5].a;
  assign io_pmp_5_cfg_x = pmp_cfg[5].x;
  assign io_pmp_5_cfg_w = pmp_cfg[5].w;
  assign io_pmp_5_cfg_r = pmp_cfg[5].r;
  assign io_pmp_5_addr = pmp_addr[5];
  assign io_pmp_5_mask = pmp_mask[5];
  assign io_pmp_6_cfg_l = pmp_cfg[6].l;
  assign io_pmp_6_cfg_a = pmp_cfg[6].a;
  assign io_pmp_6_cfg_x = pmp_cfg[6].x;
  assign io_pmp_6_cfg_w = pmp_cfg[6].w;
  assign io_pmp_6_cfg_r = pmp_cfg[6].r;
  assign io_pmp_6_addr = pmp_addr[6];
  assign io_pmp_6_mask = pmp_mask[6];
  assign io_pmp_7_cfg_l = pmp_cfg[7].l;
  assign io_pmp_7_cfg_a = pmp_cfg[7].a;
  assign io_pmp_7_cfg_x = pmp_cfg[7].x;
  assign io_pmp_7_cfg_w = pmp_cfg[7].w;
  assign io_pmp_7_cfg_r = pmp_cfg[7].r;
  assign io_pmp_7_addr = pmp_addr[7];
  assign io_pmp_7_mask = pmp_mask[7];
  assign io_pmp_8_cfg_l = pmp_cfg[8].l;
  assign io_pmp_8_cfg_a = pmp_cfg[8].a;
  assign io_pmp_8_cfg_x = pmp_cfg[8].x;
  assign io_pmp_8_cfg_w = pmp_cfg[8].w;
  assign io_pmp_8_cfg_r = pmp_cfg[8].r;
  assign io_pmp_8_addr = pmp_addr[8];
  assign io_pmp_8_mask = pmp_mask[8];
  assign io_pmp_9_cfg_l = pmp_cfg[9].l;
  assign io_pmp_9_cfg_a = pmp_cfg[9].a;
  assign io_pmp_9_cfg_x = pmp_cfg[9].x;
  assign io_pmp_9_cfg_w = pmp_cfg[9].w;
  assign io_pmp_9_cfg_r = pmp_cfg[9].r;
  assign io_pmp_9_addr = pmp_addr[9];
  assign io_pmp_9_mask = pmp_mask[9];
  assign io_pmp_10_cfg_l = pmp_cfg[10].l;
  assign io_pmp_10_cfg_a = pmp_cfg[10].a;
  assign io_pmp_10_cfg_x = pmp_cfg[10].x;
  assign io_pmp_10_cfg_w = pmp_cfg[10].w;
  assign io_pmp_10_cfg_r = pmp_cfg[10].r;
  assign io_pmp_10_addr = pmp_addr[10];
  assign io_pmp_10_mask = pmp_mask[10];
  assign io_pmp_11_cfg_l = pmp_cfg[11].l;
  assign io_pmp_11_cfg_a = pmp_cfg[11].a;
  assign io_pmp_11_cfg_x = pmp_cfg[11].x;
  assign io_pmp_11_cfg_w = pmp_cfg[11].w;
  assign io_pmp_11_cfg_r = pmp_cfg[11].r;
  assign io_pmp_11_addr = pmp_addr[11];
  assign io_pmp_11_mask = pmp_mask[11];
  assign io_pmp_12_cfg_l = pmp_cfg[12].l;
  assign io_pmp_12_cfg_a = pmp_cfg[12].a;
  assign io_pmp_12_cfg_x = pmp_cfg[12].x;
  assign io_pmp_12_cfg_w = pmp_cfg[12].w;
  assign io_pmp_12_cfg_r = pmp_cfg[12].r;
  assign io_pmp_12_addr = pmp_addr[12];
  assign io_pmp_12_mask = pmp_mask[12];
  assign io_pmp_13_cfg_l = pmp_cfg[13].l;
  assign io_pmp_13_cfg_a = pmp_cfg[13].a;
  assign io_pmp_13_cfg_x = pmp_cfg[13].x;
  assign io_pmp_13_cfg_w = pmp_cfg[13].w;
  assign io_pmp_13_cfg_r = pmp_cfg[13].r;
  assign io_pmp_13_addr = pmp_addr[13];
  assign io_pmp_13_mask = pmp_mask[13];
  assign io_pmp_14_cfg_l = pmp_cfg[14].l;
  assign io_pmp_14_cfg_a = pmp_cfg[14].a;
  assign io_pmp_14_cfg_x = pmp_cfg[14].x;
  assign io_pmp_14_cfg_w = pmp_cfg[14].w;
  assign io_pmp_14_cfg_r = pmp_cfg[14].r;
  assign io_pmp_14_addr = pmp_addr[14];
  assign io_pmp_14_mask = pmp_mask[14];
  assign io_pmp_15_cfg_l = pmp_cfg[15].l;
  assign io_pmp_15_cfg_a = pmp_cfg[15].a;
  assign io_pmp_15_cfg_x = pmp_cfg[15].x;
  assign io_pmp_15_cfg_w = pmp_cfg[15].w;
  assign io_pmp_15_cfg_r = pmp_cfg[15].r;
  assign io_pmp_15_addr = pmp_addr[15];
  assign io_pmp_15_mask = pmp_mask[15];
  assign io_pmp_16_cfg_l = pmp_cfg[16].l;
  assign io_pmp_16_cfg_a = pmp_cfg[16].a;
  assign io_pmp_16_cfg_x = pmp_cfg[16].x;
  assign io_pmp_16_cfg_w = pmp_cfg[16].w;
  assign io_pmp_16_cfg_r = pmp_cfg[16].r;
  assign io_pmp_16_addr = pmp_addr[16];
  assign io_pmp_16_mask = pmp_mask[16];
  assign io_pmp_17_cfg_l = pmp_cfg[17].l;
  assign io_pmp_17_cfg_a = pmp_cfg[17].a;
  assign io_pmp_17_cfg_x = pmp_cfg[17].x;
  assign io_pmp_17_cfg_w = pmp_cfg[17].w;
  assign io_pmp_17_cfg_r = pmp_cfg[17].r;
  assign io_pmp_17_addr = pmp_addr[17];
  assign io_pmp_17_mask = pmp_mask[17];
  assign io_pmp_18_cfg_l = pmp_cfg[18].l;
  assign io_pmp_18_cfg_a = pmp_cfg[18].a;
  assign io_pmp_18_cfg_x = pmp_cfg[18].x;
  assign io_pmp_18_cfg_w = pmp_cfg[18].w;
  assign io_pmp_18_cfg_r = pmp_cfg[18].r;
  assign io_pmp_18_addr = pmp_addr[18];
  assign io_pmp_18_mask = pmp_mask[18];
  assign io_pmp_19_cfg_l = pmp_cfg[19].l;
  assign io_pmp_19_cfg_a = pmp_cfg[19].a;
  assign io_pmp_19_cfg_x = pmp_cfg[19].x;
  assign io_pmp_19_cfg_w = pmp_cfg[19].w;
  assign io_pmp_19_cfg_r = pmp_cfg[19].r;
  assign io_pmp_19_addr = pmp_addr[19];
  assign io_pmp_19_mask = pmp_mask[19];
  assign io_pmp_20_cfg_l = pmp_cfg[20].l;
  assign io_pmp_20_cfg_a = pmp_cfg[20].a;
  assign io_pmp_20_cfg_x = pmp_cfg[20].x;
  assign io_pmp_20_cfg_w = pmp_cfg[20].w;
  assign io_pmp_20_cfg_r = pmp_cfg[20].r;
  assign io_pmp_20_addr = pmp_addr[20];
  assign io_pmp_20_mask = pmp_mask[20];
  assign io_pmp_21_cfg_l = pmp_cfg[21].l;
  assign io_pmp_21_cfg_a = pmp_cfg[21].a;
  assign io_pmp_21_cfg_x = pmp_cfg[21].x;
  assign io_pmp_21_cfg_w = pmp_cfg[21].w;
  assign io_pmp_21_cfg_r = pmp_cfg[21].r;
  assign io_pmp_21_addr = pmp_addr[21];
  assign io_pmp_21_mask = pmp_mask[21];
  assign io_pmp_22_cfg_l = pmp_cfg[22].l;
  assign io_pmp_22_cfg_a = pmp_cfg[22].a;
  assign io_pmp_22_cfg_x = pmp_cfg[22].x;
  assign io_pmp_22_cfg_w = pmp_cfg[22].w;
  assign io_pmp_22_cfg_r = pmp_cfg[22].r;
  assign io_pmp_22_addr = pmp_addr[22];
  assign io_pmp_22_mask = pmp_mask[22];
  assign io_pmp_23_cfg_l = pmp_cfg[23].l;
  assign io_pmp_23_cfg_a = pmp_cfg[23].a;
  assign io_pmp_23_cfg_x = pmp_cfg[23].x;
  assign io_pmp_23_cfg_w = pmp_cfg[23].w;
  assign io_pmp_23_cfg_r = pmp_cfg[23].r;
  assign io_pmp_23_addr = pmp_addr[23];
  assign io_pmp_23_mask = pmp_mask[23];
  assign io_pmp_24_cfg_l = pmp_cfg[24].l;
  assign io_pmp_24_cfg_a = pmp_cfg[24].a;
  assign io_pmp_24_cfg_x = pmp_cfg[24].x;
  assign io_pmp_24_cfg_w = pmp_cfg[24].w;
  assign io_pmp_24_cfg_r = pmp_cfg[24].r;
  assign io_pmp_24_addr = pmp_addr[24];
  assign io_pmp_24_mask = pmp_mask[24];
  assign io_pmp_25_cfg_l = pmp_cfg[25].l;
  assign io_pmp_25_cfg_a = pmp_cfg[25].a;
  assign io_pmp_25_cfg_x = pmp_cfg[25].x;
  assign io_pmp_25_cfg_w = pmp_cfg[25].w;
  assign io_pmp_25_cfg_r = pmp_cfg[25].r;
  assign io_pmp_25_addr = pmp_addr[25];
  assign io_pmp_25_mask = pmp_mask[25];
  assign io_pmp_26_cfg_l = pmp_cfg[26].l;
  assign io_pmp_26_cfg_a = pmp_cfg[26].a;
  assign io_pmp_26_cfg_x = pmp_cfg[26].x;
  assign io_pmp_26_cfg_w = pmp_cfg[26].w;
  assign io_pmp_26_cfg_r = pmp_cfg[26].r;
  assign io_pmp_26_addr = pmp_addr[26];
  assign io_pmp_26_mask = pmp_mask[26];
  assign io_pmp_27_cfg_l = pmp_cfg[27].l;
  assign io_pmp_27_cfg_a = pmp_cfg[27].a;
  assign io_pmp_27_cfg_x = pmp_cfg[27].x;
  assign io_pmp_27_cfg_w = pmp_cfg[27].w;
  assign io_pmp_27_cfg_r = pmp_cfg[27].r;
  assign io_pmp_27_addr = pmp_addr[27];
  assign io_pmp_27_mask = pmp_mask[27];
  assign io_pmp_28_cfg_l = pmp_cfg[28].l;
  assign io_pmp_28_cfg_a = pmp_cfg[28].a;
  assign io_pmp_28_cfg_x = pmp_cfg[28].x;
  assign io_pmp_28_cfg_w = pmp_cfg[28].w;
  assign io_pmp_28_cfg_r = pmp_cfg[28].r;
  assign io_pmp_28_addr = pmp_addr[28];
  assign io_pmp_28_mask = pmp_mask[28];
  assign io_pmp_29_cfg_l = pmp_cfg[29].l;
  assign io_pmp_29_cfg_a = pmp_cfg[29].a;
  assign io_pmp_29_cfg_x = pmp_cfg[29].x;
  assign io_pmp_29_cfg_w = pmp_cfg[29].w;
  assign io_pmp_29_cfg_r = pmp_cfg[29].r;
  assign io_pmp_29_addr = pmp_addr[29];
  assign io_pmp_29_mask = pmp_mask[29];
  assign io_pmp_30_cfg_l = pmp_cfg[30].l;
  assign io_pmp_30_cfg_a = pmp_cfg[30].a;
  assign io_pmp_30_cfg_x = pmp_cfg[30].x;
  assign io_pmp_30_cfg_w = pmp_cfg[30].w;
  assign io_pmp_30_cfg_r = pmp_cfg[30].r;
  assign io_pmp_30_addr = pmp_addr[30];
  assign io_pmp_30_mask = pmp_mask[30];
  assign io_pmp_31_cfg_l = pmp_cfg[31].l;
  assign io_pmp_31_cfg_a = pmp_cfg[31].a;
  assign io_pmp_31_cfg_x = pmp_cfg[31].x;
  assign io_pmp_31_cfg_w = pmp_cfg[31].w;
  assign io_pmp_31_cfg_r = pmp_cfg[31].r;
  assign io_pmp_31_addr = pmp_addr[31];
  assign io_pmp_31_mask = pmp_mask[31];
  assign io_pma_0_cfg_c = pma_cfg[0].c;
  assign io_pma_0_cfg_atomic = pma_cfg[0].atomic;
  assign io_pma_0_cfg_a = pma_cfg[0].a;
  assign io_pma_0_cfg_x = pma_cfg[0].x;
  assign io_pma_0_cfg_w = pma_cfg[0].w;
  assign io_pma_0_cfg_r = pma_cfg[0].r;
  assign io_pma_0_addr = pma_addr[0];
  assign io_pma_0_mask = pma_mask[0];
  assign io_pma_1_cfg_c = pma_cfg[1].c;
  assign io_pma_1_cfg_atomic = pma_cfg[1].atomic;
  assign io_pma_1_cfg_a = pma_cfg[1].a;
  assign io_pma_1_cfg_x = pma_cfg[1].x;
  assign io_pma_1_cfg_w = pma_cfg[1].w;
  assign io_pma_1_cfg_r = pma_cfg[1].r;
  assign io_pma_1_addr = pma_addr[1];
  assign io_pma_1_mask = pma_mask[1];
  assign io_pma_2_cfg_c = pma_cfg[2].c;
  assign io_pma_2_cfg_atomic = pma_cfg[2].atomic;
  assign io_pma_2_cfg_a = pma_cfg[2].a;
  assign io_pma_2_cfg_x = pma_cfg[2].x;
  assign io_pma_2_cfg_w = pma_cfg[2].w;
  assign io_pma_2_cfg_r = pma_cfg[2].r;
  assign io_pma_2_addr = pma_addr[2];
  assign io_pma_2_mask = pma_mask[2];
  assign io_pma_3_cfg_c = pma_cfg[3].c;
  assign io_pma_3_cfg_atomic = pma_cfg[3].atomic;
  assign io_pma_3_cfg_a = pma_cfg[3].a;
  assign io_pma_3_cfg_x = pma_cfg[3].x;
  assign io_pma_3_cfg_w = pma_cfg[3].w;
  assign io_pma_3_cfg_r = pma_cfg[3].r;
  assign io_pma_3_addr = pma_addr[3];
  assign io_pma_3_mask = pma_mask[3];
  assign io_pma_4_cfg_c = pma_cfg[4].c;
  assign io_pma_4_cfg_atomic = pma_cfg[4].atomic;
  assign io_pma_4_cfg_a = pma_cfg[4].a;
  assign io_pma_4_cfg_x = pma_cfg[4].x;
  assign io_pma_4_cfg_w = pma_cfg[4].w;
  assign io_pma_4_cfg_r = pma_cfg[4].r;
  assign io_pma_4_addr = pma_addr[4];
  assign io_pma_4_mask = pma_mask[4];
  assign io_pma_5_cfg_c = pma_cfg[5].c;
  assign io_pma_5_cfg_atomic = pma_cfg[5].atomic;
  assign io_pma_5_cfg_a = pma_cfg[5].a;
  assign io_pma_5_cfg_x = pma_cfg[5].x;
  assign io_pma_5_cfg_w = pma_cfg[5].w;
  assign io_pma_5_cfg_r = pma_cfg[5].r;
  assign io_pma_5_addr = pma_addr[5];
  assign io_pma_5_mask = pma_mask[5];
  assign io_pma_6_cfg_c = pma_cfg[6].c;
  assign io_pma_6_cfg_atomic = pma_cfg[6].atomic;
  assign io_pma_6_cfg_a = pma_cfg[6].a;
  assign io_pma_6_cfg_x = pma_cfg[6].x;
  assign io_pma_6_cfg_w = pma_cfg[6].w;
  assign io_pma_6_cfg_r = pma_cfg[6].r;
  assign io_pma_6_addr = pma_addr[6];
  assign io_pma_6_mask = pma_mask[6];
  assign io_pma_7_cfg_c = pma_cfg[7].c;
  assign io_pma_7_cfg_atomic = pma_cfg[7].atomic;
  assign io_pma_7_cfg_a = pma_cfg[7].a;
  assign io_pma_7_cfg_x = pma_cfg[7].x;
  assign io_pma_7_cfg_w = pma_cfg[7].w;
  assign io_pma_7_cfg_r = pma_cfg[7].r;
  assign io_pma_7_addr = pma_addr[7];
  assign io_pma_7_mask = pma_mask[7];
  assign io_pma_8_cfg_c = pma_cfg[8].c;
  assign io_pma_8_cfg_atomic = pma_cfg[8].atomic;
  assign io_pma_8_cfg_a = pma_cfg[8].a;
  assign io_pma_8_cfg_x = pma_cfg[8].x;
  assign io_pma_8_cfg_w = pma_cfg[8].w;
  assign io_pma_8_cfg_r = pma_cfg[8].r;
  assign io_pma_8_addr = pma_addr[8];
  assign io_pma_8_mask = pma_mask[8];
  assign io_pma_9_cfg_c = pma_cfg[9].c;
  assign io_pma_9_cfg_atomic = pma_cfg[9].atomic;
  assign io_pma_9_cfg_a = pma_cfg[9].a;
  assign io_pma_9_cfg_x = pma_cfg[9].x;
  assign io_pma_9_cfg_w = pma_cfg[9].w;
  assign io_pma_9_cfg_r = pma_cfg[9].r;
  assign io_pma_9_addr = pma_addr[9];
  assign io_pma_9_mask = pma_mask[9];
  assign io_pma_10_cfg_c = pma_cfg[10].c;
  assign io_pma_10_cfg_atomic = pma_cfg[10].atomic;
  assign io_pma_10_cfg_a = pma_cfg[10].a;
  assign io_pma_10_cfg_x = pma_cfg[10].x;
  assign io_pma_10_cfg_w = pma_cfg[10].w;
  assign io_pma_10_cfg_r = pma_cfg[10].r;
  assign io_pma_10_addr = pma_addr[10];
  assign io_pma_10_mask = pma_mask[10];
  assign io_pma_11_cfg_c = pma_cfg[11].c;
  assign io_pma_11_cfg_atomic = pma_cfg[11].atomic;
  assign io_pma_11_cfg_a = pma_cfg[11].a;
  assign io_pma_11_cfg_x = pma_cfg[11].x;
  assign io_pma_11_cfg_w = pma_cfg[11].w;
  assign io_pma_11_cfg_r = pma_cfg[11].r;
  assign io_pma_11_addr = pma_addr[11];
  assign io_pma_11_mask = pma_mask[11];
  assign io_pma_12_cfg_c = pma_cfg[12].c;
  assign io_pma_12_cfg_atomic = pma_cfg[12].atomic;
  assign io_pma_12_cfg_a = pma_cfg[12].a;
  assign io_pma_12_cfg_x = pma_cfg[12].x;
  assign io_pma_12_cfg_w = pma_cfg[12].w;
  assign io_pma_12_cfg_r = pma_cfg[12].r;
  assign io_pma_12_addr = pma_addr[12];
  assign io_pma_12_mask = pma_mask[12];
  assign io_pma_13_cfg_c = pma_cfg[13].c;
  assign io_pma_13_cfg_atomic = pma_cfg[13].atomic;
  assign io_pma_13_cfg_a = pma_cfg[13].a;
  assign io_pma_13_cfg_x = pma_cfg[13].x;
  assign io_pma_13_cfg_w = pma_cfg[13].w;
  assign io_pma_13_cfg_r = pma_cfg[13].r;
  assign io_pma_13_addr = pma_addr[13];
  assign io_pma_13_mask = pma_mask[13];
  assign io_pma_14_cfg_c = pma_cfg[14].c;
  assign io_pma_14_cfg_atomic = pma_cfg[14].atomic;
  assign io_pma_14_cfg_a = pma_cfg[14].a;
  assign io_pma_14_cfg_x = pma_cfg[14].x;
  assign io_pma_14_cfg_w = pma_cfg[14].w;
  assign io_pma_14_cfg_r = pma_cfg[14].r;
  assign io_pma_14_addr = pma_addr[14];
  assign io_pma_14_mask = pma_mask[14];
  assign io_pma_15_cfg_c = pma_cfg[15].c;
  assign io_pma_15_cfg_atomic = pma_cfg[15].atomic;
  assign io_pma_15_cfg_a = pma_cfg[15].a;
  assign io_pma_15_cfg_x = pma_cfg[15].x;
  assign io_pma_15_cfg_w = pma_cfg[15].w;
  assign io_pma_15_cfg_r = pma_cfg[15].r;
  assign io_pma_15_addr = pma_addr[15];
  assign io_pma_15_mask = pma_mask[15];
  assign io_pma_16_cfg_c = pma_cfg[16].c;
  assign io_pma_16_cfg_atomic = pma_cfg[16].atomic;
  assign io_pma_16_cfg_a = pma_cfg[16].a;
  assign io_pma_16_cfg_x = pma_cfg[16].x;
  assign io_pma_16_cfg_w = pma_cfg[16].w;
  assign io_pma_16_cfg_r = pma_cfg[16].r;
  assign io_pma_16_addr = pma_addr[16];
  assign io_pma_16_mask = pma_mask[16];
  assign io_pma_17_cfg_c = pma_cfg[17].c;
  assign io_pma_17_cfg_atomic = pma_cfg[17].atomic;
  assign io_pma_17_cfg_a = pma_cfg[17].a;
  assign io_pma_17_cfg_x = pma_cfg[17].x;
  assign io_pma_17_cfg_w = pma_cfg[17].w;
  assign io_pma_17_cfg_r = pma_cfg[17].r;
  assign io_pma_17_addr = pma_addr[17];
  assign io_pma_17_mask = pma_mask[17];
  assign io_pma_18_cfg_c = pma_cfg[18].c;
  assign io_pma_18_cfg_atomic = pma_cfg[18].atomic;
  assign io_pma_18_cfg_a = pma_cfg[18].a;
  assign io_pma_18_cfg_x = pma_cfg[18].x;
  assign io_pma_18_cfg_w = pma_cfg[18].w;
  assign io_pma_18_cfg_r = pma_cfg[18].r;
  assign io_pma_18_addr = pma_addr[18];
  assign io_pma_18_mask = pma_mask[18];
  assign io_pma_19_cfg_c = pma_cfg[19].c;
  assign io_pma_19_cfg_atomic = pma_cfg[19].atomic;
  assign io_pma_19_cfg_a = pma_cfg[19].a;
  assign io_pma_19_cfg_x = pma_cfg[19].x;
  assign io_pma_19_cfg_w = pma_cfg[19].w;
  assign io_pma_19_cfg_r = pma_cfg[19].r;
  assign io_pma_19_addr = pma_addr[19];
  assign io_pma_19_mask = pma_mask[19];
  assign io_pma_20_cfg_c = pma_cfg[20].c;
  assign io_pma_20_cfg_atomic = pma_cfg[20].atomic;
  assign io_pma_20_cfg_a = pma_cfg[20].a;
  assign io_pma_20_cfg_x = pma_cfg[20].x;
  assign io_pma_20_cfg_w = pma_cfg[20].w;
  assign io_pma_20_cfg_r = pma_cfg[20].r;
  assign io_pma_20_addr = pma_addr[20];
  assign io_pma_20_mask = pma_mask[20];
  assign io_pma_21_cfg_c = pma_cfg[21].c;
  assign io_pma_21_cfg_atomic = pma_cfg[21].atomic;
  assign io_pma_21_cfg_a = pma_cfg[21].a;
  assign io_pma_21_cfg_x = pma_cfg[21].x;
  assign io_pma_21_cfg_w = pma_cfg[21].w;
  assign io_pma_21_cfg_r = pma_cfg[21].r;
  assign io_pma_21_addr = pma_addr[21];
  assign io_pma_21_mask = pma_mask[21];
  assign io_pma_22_cfg_c = pma_cfg[22].c;
  assign io_pma_22_cfg_atomic = pma_cfg[22].atomic;
  assign io_pma_22_cfg_a = pma_cfg[22].a;
  assign io_pma_22_cfg_x = pma_cfg[22].x;
  assign io_pma_22_cfg_w = pma_cfg[22].w;
  assign io_pma_22_cfg_r = pma_cfg[22].r;
  assign io_pma_22_addr = pma_addr[22];
  assign io_pma_22_mask = pma_mask[22];
  assign io_pma_23_cfg_c = pma_cfg[23].c;
  assign io_pma_23_cfg_atomic = pma_cfg[23].atomic;
  assign io_pma_23_cfg_a = pma_cfg[23].a;
  assign io_pma_23_cfg_x = pma_cfg[23].x;
  assign io_pma_23_cfg_w = pma_cfg[23].w;
  assign io_pma_23_cfg_r = pma_cfg[23].r;
  assign io_pma_23_addr = pma_addr[23];
  assign io_pma_23_mask = pma_mask[23];
  assign io_pma_24_cfg_c = pma_cfg[24].c;
  assign io_pma_24_cfg_atomic = pma_cfg[24].atomic;
  assign io_pma_24_cfg_a = pma_cfg[24].a;
  assign io_pma_24_cfg_x = pma_cfg[24].x;
  assign io_pma_24_cfg_w = pma_cfg[24].w;
  assign io_pma_24_cfg_r = pma_cfg[24].r;
  assign io_pma_24_addr = pma_addr[24];
  assign io_pma_24_mask = pma_mask[24];
  assign io_pma_25_cfg_c = pma_cfg[25].c;
  assign io_pma_25_cfg_atomic = pma_cfg[25].atomic;
  assign io_pma_25_cfg_a = pma_cfg[25].a;
  assign io_pma_25_cfg_x = pma_cfg[25].x;
  assign io_pma_25_cfg_w = pma_cfg[25].w;
  assign io_pma_25_cfg_r = pma_cfg[25].r;
  assign io_pma_25_addr = pma_addr[25];
  assign io_pma_25_mask = pma_mask[25];
  assign io_pma_26_cfg_c = pma_cfg[26].c;
  assign io_pma_26_cfg_atomic = pma_cfg[26].atomic;
  assign io_pma_26_cfg_a = pma_cfg[26].a;
  assign io_pma_26_cfg_x = pma_cfg[26].x;
  assign io_pma_26_cfg_w = pma_cfg[26].w;
  assign io_pma_26_cfg_r = pma_cfg[26].r;
  assign io_pma_26_addr = pma_addr[26];
  assign io_pma_26_mask = pma_mask[26];
  assign io_pma_27_cfg_c = pma_cfg[27].c;
  assign io_pma_27_cfg_atomic = pma_cfg[27].atomic;
  assign io_pma_27_cfg_a = pma_cfg[27].a;
  assign io_pma_27_cfg_x = pma_cfg[27].x;
  assign io_pma_27_cfg_w = pma_cfg[27].w;
  assign io_pma_27_cfg_r = pma_cfg[27].r;
  assign io_pma_27_addr = pma_addr[27];
  assign io_pma_27_mask = pma_mask[27];
  assign io_pma_28_cfg_c = pma_cfg[28].c;
  assign io_pma_28_cfg_atomic = pma_cfg[28].atomic;
  assign io_pma_28_cfg_a = pma_cfg[28].a;
  assign io_pma_28_cfg_x = pma_cfg[28].x;
  assign io_pma_28_cfg_w = pma_cfg[28].w;
  assign io_pma_28_cfg_r = pma_cfg[28].r;
  assign io_pma_28_addr = pma_addr[28];
  assign io_pma_28_mask = pma_mask[28];
  assign io_pma_29_cfg_c = pma_cfg[29].c;
  assign io_pma_29_cfg_atomic = pma_cfg[29].atomic;
  assign io_pma_29_cfg_a = pma_cfg[29].a;
  assign io_pma_29_cfg_x = pma_cfg[29].x;
  assign io_pma_29_cfg_w = pma_cfg[29].w;
  assign io_pma_29_cfg_r = pma_cfg[29].r;
  assign io_pma_29_addr = pma_addr[29];
  assign io_pma_29_mask = pma_mask[29];
  assign io_pma_30_cfg_c = pma_cfg[30].c;
  assign io_pma_30_cfg_atomic = pma_cfg[30].atomic;
  assign io_pma_30_cfg_a = pma_cfg[30].a;
  assign io_pma_30_cfg_x = pma_cfg[30].x;
  assign io_pma_30_cfg_w = pma_cfg[30].w;
  assign io_pma_30_cfg_r = pma_cfg[30].r;
  assign io_pma_30_addr = pma_addr[30];
  assign io_pma_30_mask = pma_mask[30];
  assign io_pma_31_cfg_c = pma_cfg[31].c;
  assign io_pma_31_cfg_atomic = pma_cfg[31].atomic;
  assign io_pma_31_cfg_a = pma_cfg[31].a;
  assign io_pma_31_cfg_x = pma_cfg[31].x;
  assign io_pma_31_cfg_w = pma_cfg[31].w;
  assign io_pma_31_cfg_r = pma_cfg[31].r;
  assign io_pma_31_addr = pma_addr[31];
  assign io_pma_31_mask = pma_mask[31];
  // END GENERATED

endmodule
