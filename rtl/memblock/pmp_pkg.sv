// =============================================================================
// xs_pmp_pkg —— 物理内存保护 / 物理内存属性 共享类型与纯函数
//
// 对应 Chisel: xiangshan.backend.fu.PMP.scala / PMA.scala
//   - PMPConfig / PMPBase / PMPEntry           （条目类型）
//   - PMPReadWriteMethod / PMPMatchMethod       （CSR 写、地址匹配纯函数）
//
// PMP(物理内存保护) 是地址翻译链上的“权限关卡”：ITLB 翻完取指地址、DTLB 翻完
// 访存地址后，物理地址都要送进 PMPChecker，按当前 M 系统里配置的 16 条 PMP 条目
// 逐条匹配，得出该物理地址允许读/写/执行与否；PMA(物理内存属性) 则并行给出该地址
// 是否可缓存(c)、是否支持原子(atomic)、是否 MMIO 等“属性”（不是保护，而是描述）。
//
// 关键参数（香山 KunmingHu V2R2 配置，见 PMParameters.scala / SoC.scala）：
//   - PMPAddrBits   = 48   物理地址位宽 (PAddrBits)
//   - PMPOffBits    = 2    PMP 地址寄存器丢弃的最低 2 位（最小保护粒度 4 字节）
//   - PlatformGrain = 12   平台保护粒度 log2(4KB)，即一个页
//   - NumPMP = NumPMA = 16 条目数
//   - addr 寄存器宽度 = PMPAddrBits-PMPOffBits = 46
//   - mask 寄存器宽度 = PMPAddrBits            = 48
//   - KeyIDBits = 0        无内存加密，地址 MSB 不含 KeyID
//
// 由于 PlatformGrain(12) > PMPOffBits(2)，CoarserGrain = true：
//   - NA4 模式不可选；A 字段写入时被规整为 {a[1], |a[1:0]}（OFF/TOR/NAPOT 三态）
//   - lgMaxSize(=3) <= PlatformGrain(=12)，故匹配/对齐都走“简单分支”，与访问 size 无关
// =============================================================================
package xs_pmp_pkg;

  // ---- 参数 ----
  localparam int PMP_ADDR_BITS    = 48;   // 物理地址位宽
  localparam int PMP_OFF_BITS     = 2;    // 地址寄存器丢弃的低位数
  localparam int PLATFORM_GRAIN   = 12;   // 平台保护粒度 log2(4KB)
  localparam int PMP_ADDR_REG_W   = PMP_ADDR_BITS - PMP_OFF_BITS; // 46，addr 寄存器宽
  localparam int NUM_PMP          = 16;
  localparam int NUM_PMA          = 16;

  // A 字段编码（地址匹配模式）
  localparam logic [1:0] A_OFF   = 2'd0;  // 关闭，本条目不参与匹配
  localparam logic [1:0] A_TOR   = 2'd1;  // Top-Of-Range，与“前一条目地址”构成区间 [prev,cur)
  localparam logic [1:0] A_NA4   = 2'd2;  // 4 字节 NAPOT（CoarserGrain 下不可选）
  localparam logic [1:0] A_NAPOT = 2'd3;  // 2 的幂次对齐区域，用 mask 匹配

  // ---- PMP/PMA 配置字段 (8 bit cfg) ----
  // 物理布局(与 RISC-V pmpcfg 一致)：[7]=l [6]=c [5]=atomic [4:3]=a [2]=x [1]=w [0]=r
  // 在 PMP 中 c/atomic 为保留位(res)，仅在 PMA 中有意义(cacheable / 支持原子)。
  typedef struct packed {
    logic       l;        // locked：锁定后该条目(及其地址)在 M 模式下也不可改、且强制生效
    logic       c;        // cacheable（PMA 用；PMP 保留）
    logic       atomic;   // 支持原子访问（PMA 用；PMP 保留）
    logic [1:0] a;        // 地址匹配模式 OFF/TOR/NA4/NAPOT
    logic       x;        // 可执行
    logic       w;        // 可写
    logic       r;        // 可读
  } pmp_cfg_t;

  // 一个 PMP/PMA 条目：cfg + 内部地址 + napot 匹配掩码
  typedef struct packed {
    pmp_cfg_t                    cfg;
    logic [PMP_ADDR_REG_W-1:0]   addr;   // 内部地址(已丢弃低 PMP_OFF_BITS 位)
    logic [PMP_ADDR_BITS-1:0]    mask;   // NAPOT 匹配掩码(低位连续 1)
  } pmp_entry_t;

  // 8 个 cfg 打包进一个 64 位 CSR：pmpcfg0 放条目 0..7，pmpcfg2 放条目 8..15
  localparam int CFG_PER_CSR = 8;

  // 把 64 位 cfgMerged 中的第 i 个字节解析成 pmp_cfg_t
  function automatic pmp_cfg_t xs_cfg_from_byte(input logic [63:0] merged, input int i);
    logic [7:0] b = merged[i*8 +: 8];
    xs_cfg_from_byte = '{ l:b[7], c:b[6], atomic:b[5], a:b[4:3], x:b[2], w:b[1], r:b[0] };
  endfunction

  // a 字段语义判定
  function automatic logic xs_a_off(input logic [1:0] a);     return (a == A_OFF);  endfunction
  function automatic logic xs_a_tor(input logic [1:0] a);     return (a == A_TOR);  endfunction
  // na4_napot：A 的高位为 1（NA4 或 NAPOT）。CoarserGrain 下 NA4 不可达，等价于 NAPOT
  function automatic logic xs_a_na4_napot(input logic [1:0] a); return a[1]; endfunction
  // off_tor：A 的高位为 0（OFF 或 TOR）
  function automatic logic xs_a_off_tor(input logic [1:0] a);   return ~a[1]; endfunction

  // -------------------------------------------------------------------------
  // 写 cfg 时的 A 字段规整 (CoarserGrain)：NA4 不可选，把写入值 a 规整为
  //   {a[1], a[1]|a[0]}  → OFF(00) 保持, TOR(01)保持, NA4(10)→NAPOT(11)? 实为 {1, 1}=NAPOT
  // 即去掉 NA4：a=10 → 11(NAPOT)。这是 Chisel `Cat(a(1), a.orR)`。
  // -------------------------------------------------------------------------
  function automatic logic [1:0] xs_coarsen_a(input logic [1:0] a);
    return {a[1], (a[1] | a[0])};
  endfunction

  // -------------------------------------------------------------------------
  // match_mask：由“物理地址(内部) + a[0]”生成 NAPOT 匹配掩码。
  // Chisel:
  //   c = Cat(paddr, a[0]) | (((1<<Grain)-1) >> OffBits)      // 低 (Grain-OffBits)=10 位置 1
  //   mask = Cat(c & ~(c+1), (1<<OffBits)-1)                  // 末尾再接 OffBits 个 1
  // 物理意义：NAPOT 区域大小由地址里“最低的连续 1 串”决定；c&~(c+1) 取出最低 0 位以下
  // 的全 1 串，左移 OffBits 后补低位 1，得到“区域内位”掩码（这些位比较时被忽略）。
  // paddr 为 46 位内部地址，结果 48 位。
  // -------------------------------------------------------------------------
  function automatic logic [PMP_ADDR_BITS-1:0]
      xs_match_mask(input logic [PMP_ADDR_REG_W-1:0] paddr, input logic a0);
    // c 宽度 = 46+1 = 47 位
    logic [PMP_ADDR_REG_W:0] c;
    logic [PMP_ADDR_REG_W:0] low;
    // (((1<<12)-1)>>2) = 0x3FF，低 10 位为 1
    c   = {paddr, a0} | {{(PMP_ADDR_REG_W+1-10){1'b0}}, 10'h3FF};
    low = c & ~(c + 1'b1);
    return {low, {PMP_OFF_BITS{1'b1}}};  // 47 + 2 = 49? -> 取低 48 位
  endfunction

  // -------------------------------------------------------------------------
  // compare_addr：把内部地址还原成“用于比较的物理地址”，并清掉粒度内低位。
  // Chisel: compare_addr = (addr << OffBits) & ~((1<<Grain)-1)
  // 即 {addr, 2'b0} 再清低 Grain=12 位。等价于 {addr[45:10], 12'b0}。
  // golden 里写作 (addr & 46'h3FFFFFFFFC00) << 2，46'h3F..FC00 即清 addr 低 10 位。
  // 返回 48 位。
  // -------------------------------------------------------------------------
  function automatic logic [PMP_ADDR_BITS-1:0]
      xs_compare_addr(input logic [PMP_ADDR_REG_W-1:0] addr);
    logic [PMP_ADDR_REG_W-1:0] addr_hi = addr & 46'h3FFFFFFFFC00; // 清低 10 位
    return {addr_hi, {PMP_OFF_BITS{1'b0}}};
  endfunction

  // -------------------------------------------------------------------------
  // 单条目匹配 is_match（lgMaxSize <= PlatformGrain 的简化版，与访问 size 无关）：
  //   NAPOT(a[1]=1)：(paddr & ~mask) == (compare_addr & ~mask)  —— 掩码外位相等
  //   TOR  (a=01)  ：prev_cmp <= paddr < cur_cmp                 —— 区间匹配
  //   OFF          ：不匹配
  // 注意 TOR 的下界用“前一条目的 compare_addr”，条目 0 的“前一条目”是默认全 0。
  // -------------------------------------------------------------------------
  function automatic logic xs_is_match(
      input logic [PMP_ADDR_BITS-1:0] paddr,
      input pmp_cfg_t                 cfg,
      input logic [PMP_ADDR_REG_W-1:0] addr,
      input logic [PMP_ADDR_BITS-1:0] mask,
      input logic [PMP_ADDR_BITS-1:0] prev_cmp);  // 前一条目 compare_addr
    logic [PMP_ADDR_BITS-1:0] cur_cmp = xs_compare_addr(addr);
    if (xs_a_na4_napot(cfg.a))
      return (paddr & ~mask) == (cur_cmp & ~mask);
    else if (xs_a_tor(cfg.a))
      return (paddr >= prev_cmp) && (paddr < cur_cmp);
    else
      return 1'b0;
  endfunction

endpackage
