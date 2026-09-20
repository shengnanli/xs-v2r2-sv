// =============================================================================
// RenameTable —— 重命名映射表（RAT: Register Alias Table）
//
// 位置：backend/rename。它保存"逻辑寄存器号 -> 物理寄存器号"的映射。
// 每个 RenameTable 实例管一类寄存器堆；RenameTableWrapper 例化 5 个实例
// （int / fp / vec / v0 / vl），本文件是**参数化核 + int 变体 wrapper**。
//
// 两张表，两个用途：
//   spec_table  投机表：跟着 rename/walk 走，可能因为分支预测错而回滚；
//   arch_table  体系结构表：只跟着 commit 走，是"确定已经发生"的那份真值。
// 冲刷时用 arch_table（或快照）把 spec_table 拉回来。
//
// ★三级时序（Chisel 注释 "For better timing" 那一段，照抄不要合并）★
//   T0 给读地址与写请求；写在 T1 才真正落到表上；读是同步的；
//   T0 的写数据在 T1 旁路给读数据。于是本模块里几乎所有东西都带 t1_ 前缀：
//     t1_raddr    读地址寄存器，使能是 !hold（hold 住就保持上一次的地址）
//     t1_wSpec    投机写请求打一拍；**io_redirect 为真时打进去的是全 0**
//     t1_bypass   "这个读口本拍会被这个写口旁路"的判定，同样打一拍、同样被 redirect 清零
//     t1_redirect / t2_snpt  冲刷与快照选择各自延迟一拍 / 两拍
//
// ★spec_table 次态的三条路（优先级从高到低）★
//   1. RegNext(t1_redirect) 为真：整表恢复 —— useSnpt 时取快照，否则取 arch_table；
//   2. 有投机写命中本条目：取优先级最高（口号最大）的那个写数据；
//   3. 否则保持。
//
// ★"看起来冗余、一份都不许少"的两处（实测自 golden，不许合并）★
//   (a) `RegNext(t1_redirect)` 在 golden 里是 **N_ENTRIES 份**独立的 1 位寄存器
//       （spec_table_next_0_REG .. spec_table_next_31_REG），逐位恒等。
//       合成一份会让另外 N-1 份在 FM 里 globally unmatched（Entries canary 实测过
//       同一物种：846 failing）。核里用 spec_redirect_q[N_ENTRIES] 如实保留。
//   (b) t1_bypass 是 N_READ x N_WRITE 份独立寄存器，不是"每个读口一个 6 位向量"
//       打包后再比 —— 份数一样，这里只是提醒别按"算一次共用"去省。
//
// ★旁路优先级：写口号大的赢★（ParallelPriorityMux(matchVec.reverse, data.reverse)）
//   golden 展开成 `(oh5|oh4|oh3) ? (oh5?d5:oh4?d4:d3) : (oh2?d2:oh1?d1:d0)`，
//   即 5>4>3>2>1>0，全不命中时落到 d0。核里写成从高到低的优先链，
//   在全部 2^6 种 matchVec 取值上与那棵树逐一相同。
//
// ★old_pdest / need_free★
//   old_pdest(i) = 本次 arch 写之前该逻辑寄存器的旧物理号（&上 wen 掩码），
//                  并被**同拍更低口号**的写旁路（MuxCase，口号小的优先——
//                  注意这与投机写的优先级方向相反，是 golden 的不对称，照抄）。
//   need_free(i) = "旧物理号已经不在 arch_table 里任何一格" 且 "不与更低口号的
//                  old_pdest 重复"。它读的是**寄存器版**的 old_pdest 与 arch_table，
//                  所以比 old_pdest 晚一拍。
//
// ★复位域（两个 always 块，别混）★
//   异步复位块：spec_table / arch_table / old_pdest / need_free / t1_redirect /
//               t1_snpt_* / t2_snpt_*。
//   无复位块  ：t1_raddr / spec_redirect_q / t1_wSpec_* / t1_bypass。
//               后两者**只由 io_redirect 清零，没有 reset 臂** —— 照抄 golden，
//               不许"顺手"补一个复位（RenameBuffer 实测：给不复位的寄存器加复位，
//               UT 20k 拍全绿，FM 9 个点全 failed）。
//
// ★spec_table 初值★：int 变体全 0（Chisel `VecInit.fill(IntLogicRegs)(0.U)`），
//   fp/vec/v0/vl 变体是 identity（`VecInit.tabulate(i => i.U)`）—— 由
//   INIT_IDENTITY 参数区分，实测自 golden 的复位臂。
//
// ★子模块 SnapshotGenerator 例化在 wrapper 里，不在核里★
//   四个变体各用一个单态化变体（_4/_5/_6/_7，payload 宽度不同），实例名
//   与 golden 一致（snapshots_snapshotGen），这样 FM 两侧层次路径对得上。
//   核只把"喂给快照的 spec_table + 四个控制位"送出去、把四组快照读回来。
//
// 家族对照表（逐项量自 golden 的端口表与寄存器表，不是从 Chisel 推的）：
//   golden 模块   reg_t   条目数 addr宽 读口 diffRatBase debug_rdata need_free debug_v0 快照件
//   RenameTable   Reg_I     32     5    12    32 @0        32 @0        有       无     _4
//   RenameTable_1 Reg_F     34     6    18    32 @0        **无**      **无**    无     _5
//   RenameTable_2 Reg_V     47     6    18    31 @1        31 @1        有       无     _6
//   RenameTable_3 Reg_V0/Vl  1     0     6     1 @0         1 @0        有       有     _7
//   （_1 少掉的两组输出是 firtool DCE 的结果：RenameTableWrapper 里只有
//     vecRat/v0Rat/vlRat 带 dontTouch、intRat 的 need_free 被真的用到，
//     fpRat 两样都没有，于是它那两组输出整条锥被裁掉。）
//   （_3 的 addr 宽度是 0：V0LogicRegs = VlLogicRegs = 1，log2Ceil(1) = 0，
//     所以它**没有任何 addr 端口**，表只有一格。v0Rat 与 vlRat 两个实例被
//     firtool 判为同构而合并成同一个 RenameTable_3，在 wrapper 里例化两次。）
//
// 本文件 = 参数化核 xs_RenameTable_core + golden 同名 int 变体 wrapper RenameTable。
// 其余三个变体各一个薄文件：rtl/backend/RenameTable_{1,2,3}.sv。
// 薄文件与本文件的 wrapper 段由 verif/ut/RenameTable/gen_variants.py 生成。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_RenameTable_core —— 参数化可读核
// -----------------------------------------------------------------------------
module xs_RenameTable_core #(
  parameter int N_ENTRIES     = 32,      // 逻辑寄存器数（表的格数）
  parameter int ADDR_W        = 5,       // 逻辑寄存器号位宽；**可以是 0**（只有一格时）
  parameter int N_READ        = 12,      // 读口数 = readPortsNum * RenameWidth
  parameter int N_WRITE       = 6,       // 写口数 = RabCommitWidth（spec 与 arch 各一组）
  parameter bit INIT_IDENTITY = 1'b0,    // 复位初值：0 = 全 0，1 = 第 i 格填 i
  parameter int DIFF_N        = 32,      // diffRatBase 导出多少格
  parameter int DIFF_OFF      = 0,       // 从第几格开始导
  parameter int DBG_N         = 32,      // debug_rdata 导出多少格
  parameter int DBG_OFF       = 0,
  parameter bit HAS_NEED_FREE = 1'b1,    // golden 是否导出 need_free（_1 没有）
  parameter bit HAS_DBG       = 1'b1     // golden 是否导出 debug_rdata（_1 没有）
) (
  input  logic       clock,
  input  logic       reset,
  input  logic       io_redirect,

  // 读口：T0 给 addr（hold 住则沿用上一次的），T1 出 data
  input  logic                                 io_readPorts_hold [N_READ],
  input  logic [(ADDR_W > 0 ? ADDR_W : 1)-1:0] io_readPorts_addr [N_READ],
  output logic [7:0]                           io_readPorts_data [N_READ],

  // 投机写口（rename / walk）
  input  logic                                 io_specWritePorts_wen  [N_WRITE],
  input  logic [(ADDR_W > 0 ? ADDR_W : 1)-1:0] io_specWritePorts_addr [N_WRITE],
  input  logic [7:0]                           io_specWritePorts_data [N_WRITE],

  // 体系结构写口（commit）
  input  logic                                 io_archWritePorts_wen  [N_WRITE],
  input  logic [(ADDR_W > 0 ? ADDR_W : 1)-1:0] io_archWritePorts_addr [N_WRITE],
  input  logic [7:0]                           io_archWritePorts_data [N_WRITE],
  output logic [7:0]                           io_old_pdest [N_WRITE],
  output logic                                 io_need_free [N_WRITE],

  // 快照端口（来自 Rob 的 snapshot 控制）
  input  logic       io_snpt_snptEnq,
  input  logic       io_snpt_snptDeq,
  input  logic       io_snpt_useSnpt,
  input  logic [1:0] io_snpt_snptSelect,
  input  logic [3:0] io_snpt_flushVec,

  // 调试/difftest 导出
  output logic [7:0] io_diffRatBase  [DIFF_N],   // = spec_table 的**次态**（见 Chisel 注释）
  output logic [7:0] io_debug_rdata  [DBG_N],    // = arch_table
  output logic [7:0] io_debug_arch0,             // = arch_table[0]（只有 _3 导出）

  // 与外层 SnapshotGenerator_<N> 的接线（子模块例化在 wrapper 里）
  output logic [7:0] snpt_enq_data [N_ENTRIES],
  output logic       snpt_enq,
  output logic       snpt_deq,
  output logic       snpt_redirect,
  output logic [3:0] snpt_flush,
  input  logic [7:0] snpt_rdata [4][N_ENTRIES]
);

  // ADDR_W 可以是 0（只有一格的表）。SV 不允许 [-1:0]，所以对外用 AW 位宽，
  // 而"到底有没有地址寄存器"由下面的 generate 分支决定：ADDR_W==0 时
  // **一个地址寄存器都不生成**（golden RenameTable_3 里也确实一个都没有）。
  localparam int AW      = (ADDR_W > 0) ? ADDR_W : 1;
  localparam int LUT_N   = 1 << AW;      // golden 把表读展开成 2^AW 项查找表

  // ===========================================================================
  // 1. 两张表 + 提交侧输出寄存器
  // ===========================================================================
  logic [7:0] spec_table [N_ENTRIES];
  logic [7:0] arch_table [N_ENTRIES];
  logic [7:0] old_pdest  [N_WRITE];
  // ★need_free 寄存器只在 golden 导出它的变体里存在★：RenameTable_1（fp）被 firtool
  //   整条锥裁掉了，那 6 个寄存器**一个都没有**。这里按 HAS_NEED_FREE 条件生成，
  //   多生成一份就会在 FM 里变成 6 个 impl-only 未配对点。
  logic       need_free  [N_WRITE];

  // ===========================================================================
  // 2. T1 打拍件
  // ===========================================================================
  logic            t1_redirect;                       // 异步复位 0
  logic [AW-1:0]   t1_raddr    [N_READ];              // 无复位；ADDR_W==0 时是常量 0
  logic            t1_wSpec_wen  [N_WRITE];           // 无复位，只被 io_redirect 清零
  logic [AW-1:0]   t1_wSpec_addr [N_WRITE];           // 同上；ADDR_W==0 时是常量 0
  logic [7:0]      t1_wSpec_data [N_WRITE];           // 同上
  logic            t1_bypass [N_READ][N_WRITE];       // 同上
  logic            spec_redirect_q [N_ENTRIES];       // RegNext(t1_redirect)，每格各一份

  logic            t1_snpt_enq, t1_snpt_deq, t1_snpt_useSnpt;
  logic [1:0]      t1_snpt_sel;
  logic [3:0]      t1_snpt_flush;
  logic            t2_snpt_useSnpt;
  logic [1:0]      t2_snpt_sel;

  // ===========================================================================
  // 3. 投机写：地址译码 -> 每格的命中向量 -> 优先选数据
  // ===========================================================================
  // golden: `wire [N-1:0] t1_wSpec_addr_j = wen_j ? (N'h1 << addr_j) : N'h0;`
  // 移位量超出 N_ENTRIES 时自然得 0（那一格根本不存在）。
  logic [N_ENTRIES-1:0] wSpecOH [N_WRITE];
  always_comb
    for (int j = 0; j < N_WRITE; j++)
      wSpecOH[j] = t1_wSpec_wen[j] ? (N_ENTRIES'(1) << t1_wSpec_addr[j]) : '0;

  // 每格 i 的命中向量（第 j 位 = 写口 j 命中本格）与被选中的写数据。
  // 优先级：口号大的赢（ParallelPriorityMux 把两个 Vec 都 reverse 了）；
  // 一个都不命中时落到口 0 的数据（此时 matchAny 为 0，选谁都不会被采用）。
  logic [N_WRITE-1:0] matchVec [N_ENTRIES];
  logic [7:0]         wMatch   [N_ENTRIES];
  always_comb
    for (int i = 0; i < N_ENTRIES; i++) begin
      for (int j = 0; j < N_WRITE; j++) matchVec[i][j] = wSpecOH[j][i];
      wMatch[i] = t1_wSpec_data[0];
      for (int j = 1; j < N_WRITE; j++)
        if (matchVec[i][j]) wMatch[i] = t1_wSpec_data[j];
    end

  // ===========================================================================
  // 4. spec_table 次态
  // ===========================================================================
  // 冲刷恢复源：useSnpt 取被选中的那张快照，否则取 arch_table。
  logic [7:0] restore_src [N_ENTRIES];
  always_comb
    for (int i = 0; i < N_ENTRIES; i++)
      restore_src[i] = t2_snpt_useSnpt ? snpt_rdata[t2_snpt_sel][i] : arch_table[i];

  logic [7:0] spec_next [N_ENTRIES];
  always_comb
    for (int i = 0; i < N_ENTRIES; i++)
      spec_next[i] = spec_redirect_q[i] ? restore_src[i]
                   : (|matchVec[i])     ? wMatch[i]
                                        : spec_table[i];

  // ===========================================================================
  // 5. 读路径：旁路命中取写数据，否则查 spec_table
  // ===========================================================================
  // ★越界读语义★：t1_raddr 是 AW 位（0..2^AW-1），而表只有 N_ENTRIES 格。
  //   golden 把读展开成 2^AW 项查找表，N_ENTRIES..2^AW-1 这些项**全部填第 0 格**
  //   （实测 RenameTable_1.sv:458 的 `wire [63:0][7:0] _GEN`，前 30 项都是
  //   {spec_table_0}）。这里按同一形状写：默认第 0 格 + 逐项常量比较覆盖。
  //   不用 spec_table[t1_raddr[r]] 是因为 FM 会报 FMR_ELAB-147（下标可能越界）。
  logic [7:0] specRead [N_READ];
  always_comb
    for (int r = 0; r < N_READ; r++) begin
      specRead[r] = spec_table[0];
      for (int e = 1; e < N_ENTRIES; e++)
        if (t1_raddr[r] == AW'(e)) specRead[r] = spec_table[e];
    end

  // 旁路数据：与 wMatch 同一棵优先树（口号大的赢，全不命中落到口 0）
  logic [7:0] bypassData [N_READ];
  logic       bypassAny  [N_READ];
  always_comb
    for (int r = 0; r < N_READ; r++) begin
      bypassAny[r]  = 1'b0;
      bypassData[r] = t1_wSpec_data[0];
      for (int j = 0; j < N_WRITE; j++) if (t1_bypass[r][j]) bypassAny[r] = 1'b1;
      for (int j = 1; j < N_WRITE; j++) if (t1_bypass[r][j]) bypassData[r] = t1_wSpec_data[j];
    end

  for (genvar r = 0; r < N_READ; r++)
    assign io_readPorts_data[r] = bypassAny[r] ? bypassData[r] : specRead[r];

  // ===========================================================================
  // 6. 提交侧：arch_table 写 + old_pdest + need_free
  // ===========================================================================
  // arch_table 查找表（给 old_pdest 用），越界同样填第 0 格
  logic [7:0] archRead [N_WRITE];
  always_comb
    for (int w = 0; w < N_WRITE; w++) begin
      archRead[w] = arch_table[0];
      for (int e = 1; e < N_ENTRIES; e++)
        if (io_archWritePorts_addr[w] == AW'(e)) archRead[w] = arch_table[e];
    end

  // old_pdest(i)：默认取 arch_table 里的旧值，但被**口号更小**的同址写旁路
  //   （MuxCase 的候选表是 take(i).reverse，所以 i-1 最先命中 -> 口号大的优先，
  //     范围只在 0..i-1 之内）。整体再 &上 {8{wen_i}}。
  //   ★注意方向：这里是"更小的口号里、最靠近 i 的那个赢"，与投机写那边
  //     "全局口号最大的赢"不是一回事，golden 本来就不对称，别对齐。
  logic [7:0] old_pdest_next [N_WRITE];
  always_comb
    for (int w = 0; w < N_WRITE; w++) begin
      logic [7:0] sel;
      sel = archRead[w];
      for (int k = 0; k < w; k++)
        if (io_archWritePorts_wen[k] && io_archWritePorts_addr[k] == io_archWritePorts_addr[w])
          sel = io_archWritePorts_data[k];
      old_pdest_next[w] = sel & {8{io_archWritePorts_wen[w]}};
    end

  // need_free(i)：旧物理号在 arch_table 里一格都没有，且不与更低口号的 old_pdest 重复。
  // 读的是**寄存器版** old_pdest / arch_table，所以比 old_pdest 晚一拍。
  logic need_free_next [N_WRITE];
  always_comb
    for (int w = 0; w < N_WRITE; w++) begin
      logic notInArch, dup;
      notInArch = 1'b1;
      for (int e = 0; e < N_ENTRIES; e++)
        if (arch_table[e] == old_pdest[w]) notInArch = 1'b0;
      dup = 1'b0;
      for (int k = 0; k < w; k++) if (old_pdest[k] == old_pdest[w]) dup = 1'b1;
      need_free_next[w] = notInArch & ~dup;
    end

  // ===========================================================================
  // 7. 时序：异步复位块
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < N_ENTRIES; i++) begin
        spec_table[i] <= INIT_IDENTITY ? 8'(i) : 8'h0;
        arch_table[i] <= INIT_IDENTITY ? 8'(i) : 8'h0;
      end
      for (int w = 0; w < N_WRITE; w++) old_pdest[w] <= 8'h0;
      t1_redirect     <= 1'b0;
      t1_snpt_enq     <= 1'b0;
      t1_snpt_deq     <= 1'b0;
      t1_snpt_useSnpt <= 1'b0;
      t1_snpt_sel     <= 2'h0;
      t1_snpt_flush   <= 4'h0;
      t2_snpt_useSnpt <= 1'b0;
      t2_snpt_sel     <= 2'h0;
    end
    else begin
      // spec_table：冲刷恢复 > 投机写命中 > 保持
      for (int i = 0; i < N_ENTRIES; i++) begin
        if (spec_redirect_q[i])   spec_table[i] <= restore_src[i];
        else if (|matchVec[i])    spec_table[i] <= wMatch[i];
      end
      // arch_table：同址多口写，**口号大的赢**（golden 的 else-if 链从 5 数到 0）
      for (int e = 0; e < N_ENTRIES; e++)
        for (int w = 0; w < N_WRITE; w++)
          if (io_archWritePorts_wen[w] && io_archWritePorts_addr[w] == AW'(e))
            arch_table[e] <= io_archWritePorts_data[w];

      for (int w = 0; w < N_WRITE; w++) old_pdest[w] <= old_pdest_next[w];

      t1_redirect     <= io_redirect;
      t1_snpt_enq     <= io_snpt_snptEnq;
      t1_snpt_deq     <= io_snpt_snptDeq;
      t1_snpt_useSnpt <= io_snpt_useSnpt;
      t1_snpt_sel     <= io_snpt_snptSelect;
      t1_snpt_flush   <= io_snpt_flushVec;
      t2_snpt_useSnpt <= t1_snpt_useSnpt;
      t2_snpt_sel     <= t1_snpt_sel;
    end
  end

  // ===========================================================================
  // 8. 时序：无复位块（只被 io_redirect 清零的那一批）
  // ===========================================================================
  // ★这些寄存器在 golden 里没有 reset 臂★，两轮 +vcs+initreg 都要过。
  always_ff @(posedge clock) begin
    for (int i = 0; i < N_ENTRIES; i++) spec_redirect_q[i] <= t1_redirect;

    if (io_redirect) begin
      for (int w = 0; w < N_WRITE; w++) begin
        t1_wSpec_wen[w]  <= 1'b0;
        t1_wSpec_data[w] <= 8'h0;
      end
      for (int r = 0; r < N_READ; r++)
        for (int j = 0; j < N_WRITE; j++) t1_bypass[r][j] <= 1'b0;
    end
    else begin
      for (int w = 0; w < N_WRITE; w++) begin
        t1_wSpec_wen[w]  <= io_specWritePorts_wen[w];
        t1_wSpec_data[w] <= io_specWritePorts_data[w];
      end
      // 旁路判定：读口 hold 住时比的是**已锁存的**读地址，否则比本拍的读地址。
      for (int r = 0; r < N_READ; r++)
        for (int j = 0; j < N_WRITE; j++)
          t1_bypass[r][j] <= io_specWritePorts_wen[j]
                           & (io_readPorts_hold[r]
                                ? io_specWritePorts_addr[j] == t1_raddr[r]
                                : io_specWritePorts_addr[j] == io_readPorts_addr[r]);
    end
  end

  // need_free 寄存器：与 golden 同为异步复位，但只在导出它的变体里生成
  if (HAS_NEED_FREE) begin : g_need_free_reg
    always_ff @(posedge clock or posedge reset) begin
      if (reset) for (int w = 0; w < N_WRITE; w++) need_free[w] <= 1'b0;
      else       for (int w = 0; w < N_WRITE; w++) need_free[w] <= need_free_next[w];
    end
  end
  else begin : g_no_need_free
    for (genvar w = 0; w < N_WRITE; w++) assign need_free[w] = 1'b0;
  end

  // 地址寄存器只在表不止一格时存在（ADDR_W==0 的变体里 golden 一个都没有）
  if (ADDR_W > 0) begin : g_addr_regs
    always_ff @(posedge clock) begin
      for (int r = 0; r < N_READ; r++)
        if (!io_readPorts_hold[r]) t1_raddr[r] <= io_readPorts_addr[r];
      if (io_redirect)
        for (int w = 0; w < N_WRITE; w++) t1_wSpec_addr[w] <= '0;
      else
        for (int w = 0; w < N_WRITE; w++) t1_wSpec_addr[w] <= io_specWritePorts_addr[w];
    end
  end
  else begin : g_addr_const
    for (genvar r = 0; r < N_READ; r++)  assign t1_raddr[r] = '0;
    for (genvar w = 0; w < N_WRITE; w++) assign t1_wSpec_addr[w] = '0;
  end

  // ===========================================================================
  // 9. 输出
  // ===========================================================================
  for (genvar w = 0; w < N_WRITE; w++) begin : g_commit_out
    assign io_old_pdest[w] = old_pdest[w];
    assign io_need_free[w] = HAS_NEED_FREE ? need_free[w] : 1'b0;
  end

  // diffRatBase 导的是 spec_table 的**次态**（Chisel 注释：这是本拍 rename 更新之前的
  // 投机基线，复用它能让 difftest 与检查点/冲刷/walk 恢复路径对齐）。
  for (genvar k = 0; k < DIFF_N; k++)
    assign io_diffRatBase[k] = spec_next[DIFF_OFF + k];

  for (genvar k = 0; k < DBG_N; k++)
    assign io_debug_rdata[k] = HAS_DBG ? arch_table[DBG_OFF + k] : 8'h0;

  assign io_debug_arch0 = arch_table[0];

  // 快照件的接线（子模块在 wrapper 里）
  for (genvar i = 0; i < N_ENTRIES; i++) assign snpt_enq_data[i] = spec_table[i];
  assign snpt_enq      = t1_snpt_enq;
  assign snpt_deq      = t1_snpt_deq;
  assign snpt_redirect = t1_redirect;
  assign snpt_flush    = t1_snpt_flush;

endmodule

// BEGIN GENERATED(RenameTable-wrapper)
// golden 同名 wrapper —— 整数 RAT（Reg_I）：32 格 / 5 位地址 / 12 读口 /
// 全 0 初值 / 快照件 SnapshotGenerator_4。端口表与 golden 逐位同名同序。
module RenameTable(
  input        clock,
  input        reset,
  input        io_redirect,
  input        io_readPorts_0_hold,
  input  [4:0] io_readPorts_0_addr,
  output [7:0] io_readPorts_0_data,
  input        io_readPorts_1_hold,
  input  [4:0] io_readPorts_1_addr,
  output [7:0] io_readPorts_1_data,
  input        io_readPorts_2_hold,
  input  [4:0] io_readPorts_2_addr,
  output [7:0] io_readPorts_2_data,
  input        io_readPorts_3_hold,
  input  [4:0] io_readPorts_3_addr,
  output [7:0] io_readPorts_3_data,
  input        io_readPorts_4_hold,
  input  [4:0] io_readPorts_4_addr,
  output [7:0] io_readPorts_4_data,
  input        io_readPorts_5_hold,
  input  [4:0] io_readPorts_5_addr,
  output [7:0] io_readPorts_5_data,
  input        io_readPorts_6_hold,
  input  [4:0] io_readPorts_6_addr,
  output [7:0] io_readPorts_6_data,
  input        io_readPorts_7_hold,
  input  [4:0] io_readPorts_7_addr,
  output [7:0] io_readPorts_7_data,
  input        io_readPorts_8_hold,
  input  [4:0] io_readPorts_8_addr,
  output [7:0] io_readPorts_8_data,
  input        io_readPorts_9_hold,
  input  [4:0] io_readPorts_9_addr,
  output [7:0] io_readPorts_9_data,
  input        io_readPorts_10_hold,
  input  [4:0] io_readPorts_10_addr,
  output [7:0] io_readPorts_10_data,
  input        io_readPorts_11_hold,
  input  [4:0] io_readPorts_11_addr,
  output [7:0] io_readPorts_11_data,
  input        io_specWritePorts_0_wen,
  input  [4:0] io_specWritePorts_0_addr,
  input  [7:0] io_specWritePorts_0_data,
  input        io_specWritePorts_1_wen,
  input  [4:0] io_specWritePorts_1_addr,
  input  [7:0] io_specWritePorts_1_data,
  input        io_specWritePorts_2_wen,
  input  [4:0] io_specWritePorts_2_addr,
  input  [7:0] io_specWritePorts_2_data,
  input        io_specWritePorts_3_wen,
  input  [4:0] io_specWritePorts_3_addr,
  input  [7:0] io_specWritePorts_3_data,
  input        io_specWritePorts_4_wen,
  input  [4:0] io_specWritePorts_4_addr,
  input  [7:0] io_specWritePorts_4_data,
  input        io_specWritePorts_5_wen,
  input  [4:0] io_specWritePorts_5_addr,
  input  [7:0] io_specWritePorts_5_data,
  input        io_archWritePorts_0_wen,
  input  [4:0] io_archWritePorts_0_addr,
  input  [7:0] io_archWritePorts_0_data,
  input        io_archWritePorts_1_wen,
  input  [4:0] io_archWritePorts_1_addr,
  input  [7:0] io_archWritePorts_1_data,
  input        io_archWritePorts_2_wen,
  input  [4:0] io_archWritePorts_2_addr,
  input  [7:0] io_archWritePorts_2_data,
  input        io_archWritePorts_3_wen,
  input  [4:0] io_archWritePorts_3_addr,
  input  [7:0] io_archWritePorts_3_data,
  input        io_archWritePorts_4_wen,
  input  [4:0] io_archWritePorts_4_addr,
  input  [7:0] io_archWritePorts_4_data,
  input        io_archWritePorts_5_wen,
  input  [4:0] io_archWritePorts_5_addr,
  input  [7:0] io_archWritePorts_5_data,
  output [7:0] io_old_pdest_0,
  output [7:0] io_old_pdest_1,
  output [7:0] io_old_pdest_2,
  output [7:0] io_old_pdest_3,
  output [7:0] io_old_pdest_4,
  output [7:0] io_old_pdest_5,
  output       io_need_free_0,
  output       io_need_free_1,
  output       io_need_free_2,
  output       io_need_free_3,
  output       io_need_free_4,
  output       io_need_free_5,
  input        io_snpt_snptEnq,
  input        io_snpt_snptDeq,
  input        io_snpt_useSnpt,
  input  [1:0] io_snpt_snptSelect,
  input        io_snpt_flushVec_0,
  input        io_snpt_flushVec_1,
  input        io_snpt_flushVec_2,
  input        io_snpt_flushVec_3,
  output [7:0] io_diffRatBase_0,
  output [7:0] io_diffRatBase_1,
  output [7:0] io_diffRatBase_2,
  output [7:0] io_diffRatBase_3,
  output [7:0] io_diffRatBase_4,
  output [7:0] io_diffRatBase_5,
  output [7:0] io_diffRatBase_6,
  output [7:0] io_diffRatBase_7,
  output [7:0] io_diffRatBase_8,
  output [7:0] io_diffRatBase_9,
  output [7:0] io_diffRatBase_10,
  output [7:0] io_diffRatBase_11,
  output [7:0] io_diffRatBase_12,
  output [7:0] io_diffRatBase_13,
  output [7:0] io_diffRatBase_14,
  output [7:0] io_diffRatBase_15,
  output [7:0] io_diffRatBase_16,
  output [7:0] io_diffRatBase_17,
  output [7:0] io_diffRatBase_18,
  output [7:0] io_diffRatBase_19,
  output [7:0] io_diffRatBase_20,
  output [7:0] io_diffRatBase_21,
  output [7:0] io_diffRatBase_22,
  output [7:0] io_diffRatBase_23,
  output [7:0] io_diffRatBase_24,
  output [7:0] io_diffRatBase_25,
  output [7:0] io_diffRatBase_26,
  output [7:0] io_diffRatBase_27,
  output [7:0] io_diffRatBase_28,
  output [7:0] io_diffRatBase_29,
  output [7:0] io_diffRatBase_30,
  output [7:0] io_diffRatBase_31,
  output [7:0] io_debug_rdata_0,
  output [7:0] io_debug_rdata_1,
  output [7:0] io_debug_rdata_2,
  output [7:0] io_debug_rdata_3,
  output [7:0] io_debug_rdata_4,
  output [7:0] io_debug_rdata_5,
  output [7:0] io_debug_rdata_6,
  output [7:0] io_debug_rdata_7,
  output [7:0] io_debug_rdata_8,
  output [7:0] io_debug_rdata_9,
  output [7:0] io_debug_rdata_10,
  output [7:0] io_debug_rdata_11,
  output [7:0] io_debug_rdata_12,
  output [7:0] io_debug_rdata_13,
  output [7:0] io_debug_rdata_14,
  output [7:0] io_debug_rdata_15,
  output [7:0] io_debug_rdata_16,
  output [7:0] io_debug_rdata_17,
  output [7:0] io_debug_rdata_18,
  output [7:0] io_debug_rdata_19,
  output [7:0] io_debug_rdata_20,
  output [7:0] io_debug_rdata_21,
  output [7:0] io_debug_rdata_22,
  output [7:0] io_debug_rdata_23,
  output [7:0] io_debug_rdata_24,
  output [7:0] io_debug_rdata_25,
  output [7:0] io_debug_rdata_26,
  output [7:0] io_debug_rdata_27,
  output [7:0] io_debug_rdata_28,
  output [7:0] io_debug_rdata_29,
  output [7:0] io_debug_rdata_30,
  output [7:0] io_debug_rdata_31
);
  logic            rd_hold [12];
  logic [4:0]      rd_addr [12];
  logic [7:0]      rd_data [12];
  logic            sw_wen  [6];
  logic [4:0]      sw_addr [6];
  logic [7:0]      sw_data [6];
  logic            aw_wen  [6];
  logic [4:0]      aw_addr [6];
  logic [7:0]      aw_data [6];
  logic [7:0]      old_pdest [6];
  logic            need_free [6];
  logic [7:0]      diffRatBase [32];
  logic [7:0]      debug_rdata [32];
  logic [7:0]      debug_arch0;
  logic [7:0]      snpt_enq_data [32];
  logic            snpt_enq, snpt_deq, snpt_redirect;
  logic [3:0]      snpt_flush;
  logic [7:0]      snpt_rdata [4][32];

  assign rd_hold[0] = io_readPorts_0_hold;
  assign rd_addr[0] = io_readPorts_0_addr;
  assign rd_hold[1] = io_readPorts_1_hold;
  assign rd_addr[1] = io_readPorts_1_addr;
  assign rd_hold[2] = io_readPorts_2_hold;
  assign rd_addr[2] = io_readPorts_2_addr;
  assign rd_hold[3] = io_readPorts_3_hold;
  assign rd_addr[3] = io_readPorts_3_addr;
  assign rd_hold[4] = io_readPorts_4_hold;
  assign rd_addr[4] = io_readPorts_4_addr;
  assign rd_hold[5] = io_readPorts_5_hold;
  assign rd_addr[5] = io_readPorts_5_addr;
  assign rd_hold[6] = io_readPorts_6_hold;
  assign rd_addr[6] = io_readPorts_6_addr;
  assign rd_hold[7] = io_readPorts_7_hold;
  assign rd_addr[7] = io_readPorts_7_addr;
  assign rd_hold[8] = io_readPorts_8_hold;
  assign rd_addr[8] = io_readPorts_8_addr;
  assign rd_hold[9] = io_readPorts_9_hold;
  assign rd_addr[9] = io_readPorts_9_addr;
  assign rd_hold[10] = io_readPorts_10_hold;
  assign rd_addr[10] = io_readPorts_10_addr;
  assign rd_hold[11] = io_readPorts_11_hold;
  assign rd_addr[11] = io_readPorts_11_addr;
  assign sw_wen[0]  = io_specWritePorts_0_wen;
  assign sw_data[0] = io_specWritePorts_0_data;
  assign sw_addr[0] = io_specWritePorts_0_addr;
  assign aw_wen[0]  = io_archWritePorts_0_wen;
  assign aw_data[0] = io_archWritePorts_0_data;
  assign aw_addr[0] = io_archWritePorts_0_addr;
  assign sw_wen[1]  = io_specWritePorts_1_wen;
  assign sw_data[1] = io_specWritePorts_1_data;
  assign sw_addr[1] = io_specWritePorts_1_addr;
  assign aw_wen[1]  = io_archWritePorts_1_wen;
  assign aw_data[1] = io_archWritePorts_1_data;
  assign aw_addr[1] = io_archWritePorts_1_addr;
  assign sw_wen[2]  = io_specWritePorts_2_wen;
  assign sw_data[2] = io_specWritePorts_2_data;
  assign sw_addr[2] = io_specWritePorts_2_addr;
  assign aw_wen[2]  = io_archWritePorts_2_wen;
  assign aw_data[2] = io_archWritePorts_2_data;
  assign aw_addr[2] = io_archWritePorts_2_addr;
  assign sw_wen[3]  = io_specWritePorts_3_wen;
  assign sw_data[3] = io_specWritePorts_3_data;
  assign sw_addr[3] = io_specWritePorts_3_addr;
  assign aw_wen[3]  = io_archWritePorts_3_wen;
  assign aw_data[3] = io_archWritePorts_3_data;
  assign aw_addr[3] = io_archWritePorts_3_addr;
  assign sw_wen[4]  = io_specWritePorts_4_wen;
  assign sw_data[4] = io_specWritePorts_4_data;
  assign sw_addr[4] = io_specWritePorts_4_addr;
  assign aw_wen[4]  = io_archWritePorts_4_wen;
  assign aw_data[4] = io_archWritePorts_4_data;
  assign aw_addr[4] = io_archWritePorts_4_addr;
  assign sw_wen[5]  = io_specWritePorts_5_wen;
  assign sw_data[5] = io_specWritePorts_5_data;
  assign sw_addr[5] = io_specWritePorts_5_addr;
  assign aw_wen[5]  = io_archWritePorts_5_wen;
  assign aw_data[5] = io_archWritePorts_5_data;
  assign aw_addr[5] = io_archWritePorts_5_addr;

  assign io_readPorts_0_data = rd_data[0];
  assign io_readPorts_1_data = rd_data[1];
  assign io_readPorts_2_data = rd_data[2];
  assign io_readPorts_3_data = rd_data[3];
  assign io_readPorts_4_data = rd_data[4];
  assign io_readPorts_5_data = rd_data[5];
  assign io_readPorts_6_data = rd_data[6];
  assign io_readPorts_7_data = rd_data[7];
  assign io_readPorts_8_data = rd_data[8];
  assign io_readPorts_9_data = rd_data[9];
  assign io_readPorts_10_data = rd_data[10];
  assign io_readPorts_11_data = rd_data[11];
  assign io_old_pdest_0 = old_pdest[0];
  assign io_old_pdest_1 = old_pdest[1];
  assign io_old_pdest_2 = old_pdest[2];
  assign io_old_pdest_3 = old_pdest[3];
  assign io_old_pdest_4 = old_pdest[4];
  assign io_old_pdest_5 = old_pdest[5];
  assign io_need_free_0 = need_free[0];
  assign io_need_free_1 = need_free[1];
  assign io_need_free_2 = need_free[2];
  assign io_need_free_3 = need_free[3];
  assign io_need_free_4 = need_free[4];
  assign io_need_free_5 = need_free[5];
  assign io_diffRatBase_0 = diffRatBase[0];
  assign io_diffRatBase_1 = diffRatBase[1];
  assign io_diffRatBase_2 = diffRatBase[2];
  assign io_diffRatBase_3 = diffRatBase[3];
  assign io_diffRatBase_4 = diffRatBase[4];
  assign io_diffRatBase_5 = diffRatBase[5];
  assign io_diffRatBase_6 = diffRatBase[6];
  assign io_diffRatBase_7 = diffRatBase[7];
  assign io_diffRatBase_8 = diffRatBase[8];
  assign io_diffRatBase_9 = diffRatBase[9];
  assign io_diffRatBase_10 = diffRatBase[10];
  assign io_diffRatBase_11 = diffRatBase[11];
  assign io_diffRatBase_12 = diffRatBase[12];
  assign io_diffRatBase_13 = diffRatBase[13];
  assign io_diffRatBase_14 = diffRatBase[14];
  assign io_diffRatBase_15 = diffRatBase[15];
  assign io_diffRatBase_16 = diffRatBase[16];
  assign io_diffRatBase_17 = diffRatBase[17];
  assign io_diffRatBase_18 = diffRatBase[18];
  assign io_diffRatBase_19 = diffRatBase[19];
  assign io_diffRatBase_20 = diffRatBase[20];
  assign io_diffRatBase_21 = diffRatBase[21];
  assign io_diffRatBase_22 = diffRatBase[22];
  assign io_diffRatBase_23 = diffRatBase[23];
  assign io_diffRatBase_24 = diffRatBase[24];
  assign io_diffRatBase_25 = diffRatBase[25];
  assign io_diffRatBase_26 = diffRatBase[26];
  assign io_diffRatBase_27 = diffRatBase[27];
  assign io_diffRatBase_28 = diffRatBase[28];
  assign io_diffRatBase_29 = diffRatBase[29];
  assign io_diffRatBase_30 = diffRatBase[30];
  assign io_diffRatBase_31 = diffRatBase[31];
  assign io_debug_rdata_0 = debug_rdata[0];
  assign io_debug_rdata_1 = debug_rdata[1];
  assign io_debug_rdata_2 = debug_rdata[2];
  assign io_debug_rdata_3 = debug_rdata[3];
  assign io_debug_rdata_4 = debug_rdata[4];
  assign io_debug_rdata_5 = debug_rdata[5];
  assign io_debug_rdata_6 = debug_rdata[6];
  assign io_debug_rdata_7 = debug_rdata[7];
  assign io_debug_rdata_8 = debug_rdata[8];
  assign io_debug_rdata_9 = debug_rdata[9];
  assign io_debug_rdata_10 = debug_rdata[10];
  assign io_debug_rdata_11 = debug_rdata[11];
  assign io_debug_rdata_12 = debug_rdata[12];
  assign io_debug_rdata_13 = debug_rdata[13];
  assign io_debug_rdata_14 = debug_rdata[14];
  assign io_debug_rdata_15 = debug_rdata[15];
  assign io_debug_rdata_16 = debug_rdata[16];
  assign io_debug_rdata_17 = debug_rdata[17];
  assign io_debug_rdata_18 = debug_rdata[18];
  assign io_debug_rdata_19 = debug_rdata[19];
  assign io_debug_rdata_20 = debug_rdata[20];
  assign io_debug_rdata_21 = debug_rdata[21];
  assign io_debug_rdata_22 = debug_rdata[22];
  assign io_debug_rdata_23 = debug_rdata[23];
  assign io_debug_rdata_24 = debug_rdata[24];
  assign io_debug_rdata_25 = debug_rdata[25];
  assign io_debug_rdata_26 = debug_rdata[26];
  assign io_debug_rdata_27 = debug_rdata[27];
  assign io_debug_rdata_28 = debug_rdata[28];
  assign io_debug_rdata_29 = debug_rdata[29];
  assign io_debug_rdata_30 = debug_rdata[30];
  assign io_debug_rdata_31 = debug_rdata[31];

  xs_RenameTable_core #(
    .N_ENTRIES(32), .ADDR_W(5), .N_READ(12), .N_WRITE(6),
    .INIT_IDENTITY(1'b0), .DIFF_N(32), .DIFF_OFF(0),
    .DBG_N(32), .DBG_OFF(0),
    .HAS_NEED_FREE(1'b1), .HAS_DBG(1'b1)
  ) u_core (
    .clock                  (clock),
    .reset                  (reset),
    .io_redirect            (io_redirect),
    .io_readPorts_hold      (rd_hold),
    .io_readPorts_addr      (rd_addr),
    .io_readPorts_data      (rd_data),
    .io_specWritePorts_wen  (sw_wen),
    .io_specWritePorts_addr (sw_addr),
    .io_specWritePorts_data (sw_data),
    .io_archWritePorts_wen  (aw_wen),
    .io_archWritePorts_addr (aw_addr),
    .io_archWritePorts_data (aw_data),
    .io_old_pdest           (old_pdest),
    .io_need_free           (need_free),
    .io_snpt_snptEnq        (io_snpt_snptEnq),
    .io_snpt_snptDeq        (io_snpt_snptDeq),
    .io_snpt_useSnpt        (io_snpt_useSnpt),
    .io_snpt_snptSelect     (io_snpt_snptSelect),
    .io_snpt_flushVec       ({io_snpt_flushVec_3, io_snpt_flushVec_2,
                              io_snpt_flushVec_1, io_snpt_flushVec_0}),
    .io_diffRatBase         (diffRatBase),
    .io_debug_rdata         (debug_rdata),
    .io_debug_arch0         (debug_arch0),
    .snpt_enq_data          (snpt_enq_data),
    .snpt_enq               (snpt_enq),
    .snpt_deq               (snpt_deq),
    .snpt_redirect          (snpt_redirect),
    .snpt_flush             (snpt_flush),
    .snpt_rdata             (snpt_rdata)
  );

  // 实例名 snapshots_snapshotGen 与 golden 逐字一致：FM 按层次路径配对内部比对点。
  SnapshotGenerator_4 snapshots_snapshotGen (
    .clock       (clock),
    .reset       (reset),
    .io_enq      (snpt_enq),
    .io_enqData_0  (snpt_enq_data[0]),
    .io_enqData_1  (snpt_enq_data[1]),
    .io_enqData_2  (snpt_enq_data[2]),
    .io_enqData_3  (snpt_enq_data[3]),
    .io_enqData_4  (snpt_enq_data[4]),
    .io_enqData_5  (snpt_enq_data[5]),
    .io_enqData_6  (snpt_enq_data[6]),
    .io_enqData_7  (snpt_enq_data[7]),
    .io_enqData_8  (snpt_enq_data[8]),
    .io_enqData_9  (snpt_enq_data[9]),
    .io_enqData_10 (snpt_enq_data[10]),
    .io_enqData_11 (snpt_enq_data[11]),
    .io_enqData_12 (snpt_enq_data[12]),
    .io_enqData_13 (snpt_enq_data[13]),
    .io_enqData_14 (snpt_enq_data[14]),
    .io_enqData_15 (snpt_enq_data[15]),
    .io_enqData_16 (snpt_enq_data[16]),
    .io_enqData_17 (snpt_enq_data[17]),
    .io_enqData_18 (snpt_enq_data[18]),
    .io_enqData_19 (snpt_enq_data[19]),
    .io_enqData_20 (snpt_enq_data[20]),
    .io_enqData_21 (snpt_enq_data[21]),
    .io_enqData_22 (snpt_enq_data[22]),
    .io_enqData_23 (snpt_enq_data[23]),
    .io_enqData_24 (snpt_enq_data[24]),
    .io_enqData_25 (snpt_enq_data[25]),
    .io_enqData_26 (snpt_enq_data[26]),
    .io_enqData_27 (snpt_enq_data[27]),
    .io_enqData_28 (snpt_enq_data[28]),
    .io_enqData_29 (snpt_enq_data[29]),
    .io_enqData_30 (snpt_enq_data[30]),
    .io_enqData_31 (snpt_enq_data[31]),
    .io_deq      (snpt_deq),
    .io_redirect (snpt_redirect),
    .io_flushVec_0(snpt_flush[0]),
    .io_flushVec_1(snpt_flush[1]),
    .io_flushVec_2(snpt_flush[2]),
    .io_flushVec_3(snpt_flush[3]),
    .io_snapshots_0_0  (snpt_rdata[0][0]),
    .io_snapshots_0_1  (snpt_rdata[0][1]),
    .io_snapshots_0_2  (snpt_rdata[0][2]),
    .io_snapshots_0_3  (snpt_rdata[0][3]),
    .io_snapshots_0_4  (snpt_rdata[0][4]),
    .io_snapshots_0_5  (snpt_rdata[0][5]),
    .io_snapshots_0_6  (snpt_rdata[0][6]),
    .io_snapshots_0_7  (snpt_rdata[0][7]),
    .io_snapshots_0_8  (snpt_rdata[0][8]),
    .io_snapshots_0_9  (snpt_rdata[0][9]),
    .io_snapshots_0_10 (snpt_rdata[0][10]),
    .io_snapshots_0_11 (snpt_rdata[0][11]),
    .io_snapshots_0_12 (snpt_rdata[0][12]),
    .io_snapshots_0_13 (snpt_rdata[0][13]),
    .io_snapshots_0_14 (snpt_rdata[0][14]),
    .io_snapshots_0_15 (snpt_rdata[0][15]),
    .io_snapshots_0_16 (snpt_rdata[0][16]),
    .io_snapshots_0_17 (snpt_rdata[0][17]),
    .io_snapshots_0_18 (snpt_rdata[0][18]),
    .io_snapshots_0_19 (snpt_rdata[0][19]),
    .io_snapshots_0_20 (snpt_rdata[0][20]),
    .io_snapshots_0_21 (snpt_rdata[0][21]),
    .io_snapshots_0_22 (snpt_rdata[0][22]),
    .io_snapshots_0_23 (snpt_rdata[0][23]),
    .io_snapshots_0_24 (snpt_rdata[0][24]),
    .io_snapshots_0_25 (snpt_rdata[0][25]),
    .io_snapshots_0_26 (snpt_rdata[0][26]),
    .io_snapshots_0_27 (snpt_rdata[0][27]),
    .io_snapshots_0_28 (snpt_rdata[0][28]),
    .io_snapshots_0_29 (snpt_rdata[0][29]),
    .io_snapshots_0_30 (snpt_rdata[0][30]),
    .io_snapshots_0_31 (snpt_rdata[0][31]),
    .io_snapshots_1_0  (snpt_rdata[1][0]),
    .io_snapshots_1_1  (snpt_rdata[1][1]),
    .io_snapshots_1_2  (snpt_rdata[1][2]),
    .io_snapshots_1_3  (snpt_rdata[1][3]),
    .io_snapshots_1_4  (snpt_rdata[1][4]),
    .io_snapshots_1_5  (snpt_rdata[1][5]),
    .io_snapshots_1_6  (snpt_rdata[1][6]),
    .io_snapshots_1_7  (snpt_rdata[1][7]),
    .io_snapshots_1_8  (snpt_rdata[1][8]),
    .io_snapshots_1_9  (snpt_rdata[1][9]),
    .io_snapshots_1_10 (snpt_rdata[1][10]),
    .io_snapshots_1_11 (snpt_rdata[1][11]),
    .io_snapshots_1_12 (snpt_rdata[1][12]),
    .io_snapshots_1_13 (snpt_rdata[1][13]),
    .io_snapshots_1_14 (snpt_rdata[1][14]),
    .io_snapshots_1_15 (snpt_rdata[1][15]),
    .io_snapshots_1_16 (snpt_rdata[1][16]),
    .io_snapshots_1_17 (snpt_rdata[1][17]),
    .io_snapshots_1_18 (snpt_rdata[1][18]),
    .io_snapshots_1_19 (snpt_rdata[1][19]),
    .io_snapshots_1_20 (snpt_rdata[1][20]),
    .io_snapshots_1_21 (snpt_rdata[1][21]),
    .io_snapshots_1_22 (snpt_rdata[1][22]),
    .io_snapshots_1_23 (snpt_rdata[1][23]),
    .io_snapshots_1_24 (snpt_rdata[1][24]),
    .io_snapshots_1_25 (snpt_rdata[1][25]),
    .io_snapshots_1_26 (snpt_rdata[1][26]),
    .io_snapshots_1_27 (snpt_rdata[1][27]),
    .io_snapshots_1_28 (snpt_rdata[1][28]),
    .io_snapshots_1_29 (snpt_rdata[1][29]),
    .io_snapshots_1_30 (snpt_rdata[1][30]),
    .io_snapshots_1_31 (snpt_rdata[1][31]),
    .io_snapshots_2_0  (snpt_rdata[2][0]),
    .io_snapshots_2_1  (snpt_rdata[2][1]),
    .io_snapshots_2_2  (snpt_rdata[2][2]),
    .io_snapshots_2_3  (snpt_rdata[2][3]),
    .io_snapshots_2_4  (snpt_rdata[2][4]),
    .io_snapshots_2_5  (snpt_rdata[2][5]),
    .io_snapshots_2_6  (snpt_rdata[2][6]),
    .io_snapshots_2_7  (snpt_rdata[2][7]),
    .io_snapshots_2_8  (snpt_rdata[2][8]),
    .io_snapshots_2_9  (snpt_rdata[2][9]),
    .io_snapshots_2_10 (snpt_rdata[2][10]),
    .io_snapshots_2_11 (snpt_rdata[2][11]),
    .io_snapshots_2_12 (snpt_rdata[2][12]),
    .io_snapshots_2_13 (snpt_rdata[2][13]),
    .io_snapshots_2_14 (snpt_rdata[2][14]),
    .io_snapshots_2_15 (snpt_rdata[2][15]),
    .io_snapshots_2_16 (snpt_rdata[2][16]),
    .io_snapshots_2_17 (snpt_rdata[2][17]),
    .io_snapshots_2_18 (snpt_rdata[2][18]),
    .io_snapshots_2_19 (snpt_rdata[2][19]),
    .io_snapshots_2_20 (snpt_rdata[2][20]),
    .io_snapshots_2_21 (snpt_rdata[2][21]),
    .io_snapshots_2_22 (snpt_rdata[2][22]),
    .io_snapshots_2_23 (snpt_rdata[2][23]),
    .io_snapshots_2_24 (snpt_rdata[2][24]),
    .io_snapshots_2_25 (snpt_rdata[2][25]),
    .io_snapshots_2_26 (snpt_rdata[2][26]),
    .io_snapshots_2_27 (snpt_rdata[2][27]),
    .io_snapshots_2_28 (snpt_rdata[2][28]),
    .io_snapshots_2_29 (snpt_rdata[2][29]),
    .io_snapshots_2_30 (snpt_rdata[2][30]),
    .io_snapshots_2_31 (snpt_rdata[2][31]),
    .io_snapshots_3_0  (snpt_rdata[3][0]),
    .io_snapshots_3_1  (snpt_rdata[3][1]),
    .io_snapshots_3_2  (snpt_rdata[3][2]),
    .io_snapshots_3_3  (snpt_rdata[3][3]),
    .io_snapshots_3_4  (snpt_rdata[3][4]),
    .io_snapshots_3_5  (snpt_rdata[3][5]),
    .io_snapshots_3_6  (snpt_rdata[3][6]),
    .io_snapshots_3_7  (snpt_rdata[3][7]),
    .io_snapshots_3_8  (snpt_rdata[3][8]),
    .io_snapshots_3_9  (snpt_rdata[3][9]),
    .io_snapshots_3_10 (snpt_rdata[3][10]),
    .io_snapshots_3_11 (snpt_rdata[3][11]),
    .io_snapshots_3_12 (snpt_rdata[3][12]),
    .io_snapshots_3_13 (snpt_rdata[3][13]),
    .io_snapshots_3_14 (snpt_rdata[3][14]),
    .io_snapshots_3_15 (snpt_rdata[3][15]),
    .io_snapshots_3_16 (snpt_rdata[3][16]),
    .io_snapshots_3_17 (snpt_rdata[3][17]),
    .io_snapshots_3_18 (snpt_rdata[3][18]),
    .io_snapshots_3_19 (snpt_rdata[3][19]),
    .io_snapshots_3_20 (snpt_rdata[3][20]),
    .io_snapshots_3_21 (snpt_rdata[3][21]),
    .io_snapshots_3_22 (snpt_rdata[3][22]),
    .io_snapshots_3_23 (snpt_rdata[3][23]),
    .io_snapshots_3_24 (snpt_rdata[3][24]),
    .io_snapshots_3_25 (snpt_rdata[3][25]),
    .io_snapshots_3_26 (snpt_rdata[3][26]),
    .io_snapshots_3_27 (snpt_rdata[3][27]),
    .io_snapshots_3_28 (snpt_rdata[3][28]),
    .io_snapshots_3_29 (snpt_rdata[3][29]),
    .io_snapshots_3_30 (snpt_rdata[3][30]),
    .io_snapshots_3_31 (snpt_rdata[3][31])
  );
endmodule
// END GENERATED
