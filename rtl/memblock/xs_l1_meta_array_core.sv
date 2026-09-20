// =============================================================================
// xs_l1_meta_array_core —— L1 DCache「异步元数据阵列」家族的参数化可读核
//
// 对应 Chisel: xiangshan/cache/dcache/meta/AsynchronousMetaArray.scala
// 覆盖 G1 golden 三个同族模块（各自的薄 wrapper 在同目录）：
//
//   golden 模块              Chisel class              golden 行数   本核参数
//   ----------------------   -----------------------   -----------   --------------------------
//   L1ErrorMetaArray         L1ErrorMetaArray          14951         DATA_W=2 RP=4 WP=1  旁路 S1+S0
//   L1FlagMetaArray          L1FlagMetaArray           12691         DATA_W=1 RP=5 WP=4  无旁路
//   L1PrefetchSourceArray    L1PrefetchSourceArray     11923         DATA_W=3 RP=5 WP=4  旁路仅 S1
//
// ★注意 L1CohMetaArray 不在本核之内★：它是同一个 Scala 文件里的第四个 class，
//   走 bypassRead=true 分支，非旁路路径锁存的是**数据**而不是**地址**（见下 §读路径），
//   寄存器结构不同，不能用同一个核。它已单独重写在 rtl/memblock/L1CohMetaArray.sv。
//
// -----------------------------------------------------------------------------
// 这族阵列在 DCache 里干什么
// -----------------------------------------------------------------------------
// DCache 每条 cacheline 除了 tag / data，还要挂几份"附加元数据"。它们的索引方式
// 完全一样（按 set idx 读，一次返回该 set 全部 nWays 路），只是每路存的东西不同：
//   · errorArray    存 TileLink 错误位 {denied, corrupt} —— refill 带回来的错误，
//                   命中这条线的 load 要把它转成异常上报。
//   · accessArray   存 1 bit「这条线被访问过」—— 给预取器算命中率用。
//   · prefetchArray 存 3 bit「这条线最初是被谁预取进来的」(L1PfSource)。
// 三者都用**寄存器堆**而不是 SRAM（所以 Chisel 里这族叫 AsynchronousMetaArray）：
// 读是组合的，本核里就是 meta_array[idx][way] 一个下标。
//
// -----------------------------------------------------------------------------
// 写路径：S0 按 way_en 拆 -> S1 打一拍 -> 落寄存器堆
// -----------------------------------------------------------------------------
// 写请求带 one-hot 的 way_en，S0 拆成每路一份；S1（下一拍）才真正写进 meta_array。
// 多写口时**写口号大的赢**（Chisel 里是 io.write.zipWithIndex.foreach 顺序执行的
// when 链，后执行的覆盖先执行的），本核用升序 for 循环里的非阻塞赋值复刻这一点。
//
// ★WDATA_IS_CONST：firtool 从 DCache 传播进来的常数★
//   L1FlagMetaArray 与 L1PrefetchSourceArray 的 4 个写口里，0/1/2 号口来自三条
//   load 流水，它们的数据端**在 DCache 里就是个常数**（access flag 恒写 1；
//   prefetch source 恒写 1 = 该线由硬件预取引入）。firtool 做跨模块常数传播后
//   把这三个口的数据端口整个删掉了 —— 所以 golden 的端口表里只有 3 号口带数据，
//   s1_way_wdata 寄存器也只有 4 个（4 路 × 1 个写口）而不是 16 个。
//   本核照此建模：WDATA_IS_CONST[wp]=1 的写口不产生 s1 数据寄存器，直接用
//   WDATA_CONST。这是**如实复刻 golden 的形态**，不是简化 —— 若改成一律建寄存器，
//   impl 会比 golden 多出 12 个没有对应物的触发器，FM 当场 unmatched。
//
// -----------------------------------------------------------------------------
// 读路径：1 拍延迟；是否带在途写旁路由 HAS_BYPASS / BYPASS_S0 决定
// -----------------------------------------------------------------------------
// 非旁路路径三家一致：S0 锁存 idx，S1 用锁存的 idx **组合读**寄存器堆
//   （Chisel: meta_array(RegEnable(read.bits.idx, read.valid))(way)）。
//
// 旁路存在的理由：写有 2 拍延迟，若读 idx 撞上在途写，直接读堆会读到旧值。
//   HAS_BYPASS=0  L1FlagMetaArray：Chisel 的 enableBypass 默认 false，DCache 也没传
//                 true，所以 resp 直接取寄存器堆 —— 连旁路判定都被 DCE 掉了。
//                 ★这不是"旁路被优化没了"，是这个阵列压根不做旁路★，
//                 它存的是"访问过没有"，读到旧值只让预取统计差一拍，无功能影响。
//   HAS_BYPASS=1, BYPASS_S0=0  L1PrefetchSourceArray：Chisel 里只有 S1 那一条 when，
//                 **没有 S0 那条**。所以同拍发起的写不会被转发。
//   HAS_BYPASS=1, BYPASS_S0=1  L1ErrorMetaArray：S1 与 S0 两条 when 都有，
//                 且 S0 写在后面 —— 同时命中时 S0（更新的那个）赢。
//
// S0->S1 三个锁存的使能各不相同，逐字复刻 Chisel 的三个 RegEnable：
//     sel_r      <= 旁路命中        使能 = read.valid
//     bypass_r   <= 旁路数据        使能 = 旁路命中     ← 不是 read.valid
//     idx_r      <= read.bits.idx   使能 = read.valid
// 无旁路时只剩 idx_r。
//
// 旁路数据在多写口间同样"写口号大的赢"；BYPASS_S0=1 时同一写口内 S0 赢 S1。
// 未命中时 Chisel 给的是 DontCare，此处取 '0：命中位为 0 时该值既不被锁存
// （使能关着）也不被选中，取什么都不影响等价性。
// =============================================================================
module xs_l1_meta_array_core #(
  parameter int N_SETS      = 256,  // nSets
  parameter int IDX_BITS    = 8,    // log2(nSets)
  parameter int N_WAYS      = 4,    // nWays
  parameter int DATA_W      = 1,    // 每路每 set 存几位元数据
  parameter int READ_PORTS  = 4,
  parameter int WRITE_PORTS = 1,
  parameter bit HAS_BYPASS  = 1'b1, // 0 = 读直接取寄存器堆，不做在途写转发
  parameter bit BYPASS_S0   = 1'b1, // 1 = 旁路除 S1 外还看同拍的 S0 在途写
  // 位 wp 为 1 表示该写口的数据在 golden 里已被常数折叠（见文件头）
  parameter logic [31:0]       WDATA_IS_CONST = 32'h0,
  parameter logic [DATA_W-1:0] WDATA_CONST    = '0
)(
  input  logic                clock,
  input  logic                reset,

  // 读口：给 idx，下一拍返回该 set 全部 N_WAYS 路的元数据
  input  logic                io_read_valid [READ_PORTS],
  input  logic [IDX_BITS-1:0] io_read_idx   [READ_PORTS],
  output logic [DATA_W-1:0]   io_resp       [READ_PORTS][N_WAYS],

  // 写口：way_en 为 one-hot 路选择。WDATA_IS_CONST[wp]=1 的写口不看 io_write_data。
  input  logic                io_write_valid  [WRITE_PORTS],
  input  logic [IDX_BITS-1:0] io_write_idx    [WRITE_PORTS],
  input  logic [N_WAYS-1:0]   io_write_way_en [WRITE_PORTS],
  input  logic [DATA_W-1:0]   io_write_data   [WRITE_PORTS]
);

  // =========================================================================
  // 架构状态：寄存器堆 N_SETS × N_WAYS 条，每条 DATA_W 位
  // =========================================================================
  logic [DATA_W-1:0] meta_array [N_SETS][N_WAYS];

  // =========================================================================
  // 写路径 S0：纯组合，按 way_en 把每个写口拆到各路
  // 下标顺序 [way][wport] 与 Chisel 的 s0_way_wen(way)(wport) 一致
  // =========================================================================
  logic s0_way_wen [N_WAYS][WRITE_PORTS];

  always_comb
    for (int wp = 0; wp < WRITE_PORTS; wp++)
      for (int w = 0; w < N_WAYS; w++)
        s0_way_wen[w][wp] = io_write_valid[wp] & io_write_way_en[wp][w];

  // =========================================================================
  // 写路径 S1：在途写寄存。golden 侧这组寄存器**无复位**（上电 X），照搬不加。
  //   wen   用 RegNext（每拍都更新）
  //   waddr 用 RegEnable(s0_wen)
  //   wdata 见 WDATA_IS_CONST：常数口不建寄存器
  // =========================================================================
  logic [IDX_BITS-1:0] s1_way_waddr [N_WAYS][WRITE_PORTS];
  logic                s1_way_wen   [N_WAYS][WRITE_PORTS];
  wire  [DATA_W-1:0]   s1_way_wdata [N_WAYS][WRITE_PORTS];

  always_ff @(posedge clock)
    for (int wp = 0; wp < WRITE_PORTS; wp++)
      for (int w = 0; w < N_WAYS; w++) begin
        s1_way_wen[w][wp] <= s0_way_wen[w][wp];
        if (s0_way_wen[w][wp])
          s1_way_waddr[w][wp] <= io_write_idx[wp];
      end

  genvar gw, gwp, gp;
  generate
    for (gw = 0; gw < N_WAYS; gw++) begin : g_wdata_way
      for (gwp = 0; gwp < WRITE_PORTS; gwp++) begin : g_wdata_port
        if (WDATA_IS_CONST[gwp]) begin : g_const
          // 该写口的数据在 DCache 里就是常数，firtool 已把它传播进来（见文件头）
          assign s1_way_wdata[gw][gwp] = WDATA_CONST;
        end
        else begin : g_reg
          logic [DATA_W-1:0] wdata_r;
          always_ff @(posedge clock)
            if (s0_way_wen[gw][gwp])
              wdata_r <= io_write_data[gwp];
          assign s1_way_wdata[gw][gwp] = wdata_r;
        end
      end
    end
  endgenerate

  // =========================================================================
  // 写路径落盘：**异步复位**清 0（golden 是 always @(posedge clock or posedge reset)，
  // 对应 DFF 的异步清零引脚，FM 按此比对，必须保持异步语义）。
  // 写口升序遍历 ⇒ 号大的写口后赋值、覆盖号小的，与 Chisel 的 when 链一致。
  // =========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < N_SETS; s++)
        for (int w = 0; w < N_WAYS; w++)
          meta_array[s][w] <= '0;
    end
    else begin
      for (int wp = 0; wp < WRITE_PORTS; wp++)
        for (int w = 0; w < N_WAYS; w++)
          if (s1_way_wen[w][wp])
            meta_array[s1_way_waddr[w][wp]][w] <= s1_way_wdata[w][wp];
    end
  end

  // =========================================================================
  // 读路径：每个 (读口, way) 一份
  // =========================================================================
  generate
    for (gp = 0; gp < READ_PORTS; gp++) begin : g_rport
      for (gw = 0; gw < N_WAYS; gw++) begin : g_way

        // S0 锁存读地址（三家一致），S1 用它组合读寄存器堆
        logic [IDX_BITS-1:0] idx_r;
        always_ff @(posedge clock)
          if (io_read_valid[gp])
            idx_r <= io_read_idx[gp];

        if (!HAS_BYPASS) begin : g_no_bypass
          // L1FlagMetaArray：enableBypass=false，读直接取寄存器堆
          assign io_resp[gp][gw] = meta_array[idx_r][gw];
        end
        else begin : g_bypass
          // --- S0 组合：本读口本 way 是否命中在途写，命中则给出转发数据 ---
          logic              sel;
          logic [DATA_W-1:0] sel_data;
          always_comb begin
            sel      = 1'b0;
            sel_data = '0;                 // 对齐 Chisel 的 DontCare（见文件头）
            for (int wp = 0; wp < WRITE_PORTS; wp++) begin
              // 升序遍历写口 ⇒ 号大的写口赢；BYPASS_S0 时同口内 S0 赢 S1
              if (s1_way_wen[gw][wp] & (s1_way_waddr[gw][wp] == io_read_idx[gp])) begin
                sel      = 1'b1;
                sel_data = s1_way_wdata[gw][wp];
              end
              if (BYPASS_S0 &&
                  s0_way_wen[gw][wp] & (io_write_idx[wp] == io_read_idx[gp])) begin
                sel      = 1'b1;
                // 常数口同样按常数转发（本族目前只有 BYPASS_S0=0 的变体带常数口，
                // 这里仍按一般情形写，免得将来加变体时留个只在特定组合下才错的坑）
                sel_data = WDATA_IS_CONST[wp] ? WDATA_CONST : io_write_data[wp];
              end
            end
          end

          // --- S0 -> S1：两个锁存，使能不同（见文件头）---
          logic              sel_r;      // RegEnable(sel,      read.valid)
          logic [DATA_W-1:0] bypass_r;   // RegEnable(sel_data, sel)  ← 使能是 sel
          always_ff @(posedge clock) begin
            if (io_read_valid[gp]) sel_r    <= sel;
            if (sel)               bypass_r <= sel_data;
          end

          assign io_resp[gp][gw] = sel_r ? bypass_r : meta_array[idx_r][gw];
        end

      end
    end
  endgenerate

endmodule
