// =============================================================================
// BloomFilter.sv —— DCache 预取「反馈导向预取(FDP)」用的布隆过滤器
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/mem/prefetch/FDP.scala
//        class BloomFilter(n = 4096, bypass = true)
// golden 对照:G1-canonical/golden-rtl/BloomFilter.sv(34563 行,18 端口,真叶子)
//
// ★ 它是什么 ★
// 一张 4096 位的位图,用来近似回答「这个 cache block 最近被预取进来过吗」。
// FDPrefetcherMonitor 拿它统计预取的**有用率(accuracy)**:
//   - 预取填充一条 block 时 set 该地址对应的位;
//   - 该 block 被换出/被判定无用时 clr;
//   - 三条 load 流水各有一个 query 口,命中即「这次 load 用上了之前的预取」。
// 布隆过滤器允许假阳性(两个地址折叠到同一位)——统计口径上可以接受,换来的是
// 4096 位就覆盖整个物理地址空间。地址折叠在**调用方**做
// (BloomQueryBundle.get_addr:block_paddr 的低 12 位 XOR 次低 12 位),
// 本模块只看已经折好的 12 位索引。
//
// ★ 核心机制(三条,逐条对着 golden 核过)★
//  1. 位图 data[4096]:每拍整体重算 data_next,clr **压过** set(见 §2 更新优先级)。
//  2. query 读的是 data_next 而不是 data(Chisel 的 bypass=true)——同拍 set/clr
//     的结果立刻可见,不用等下一拍。
//  3. 响应打一拍:resp.valid = query.valid 延迟一拍;resp.bits.res 是**带使能**的
//     寄存器(query.valid 才更新),所以无效拍上保持旧值。
//
// ★ 复位域(golden 实测,两个 always 块分类)★
//   data / resp_valid_q  : always @(posedge clock or posedge reset) —— **异步复位**到 0
//   resp_res_q           : always @(posedge clock) —— **完全不复位**,只有使能
//   照抄成「全复位」是真 bug,elaborate 与 lint 都不会报。
//
// ★ golden 里两片「看起来是逻辑其实没人读」的代码,本核**故意不生成** ★
//   (a) golden 21797-26179 行:一棵 4096 位的 PopCount 加法树(_GEN_33.._GEN_65),
//       来自 Chisel 的 XSPerfHistogram("valid_nums", PopCount(data), ...)。
//       perf 端口在 KunminghuV2Config 下被裁掉,加法树成了**悬空 wire**,全文
//       再无引用。纯组合、不产生 FM 比对点,不复制(复制了只是 4383 行噪音)。
//   (b) golden 12403-21796 行:assert(PopCount(data ^ data_next) <= 2) 展开,
//       整块在 `ifndef SYNTHESIS 里。FM 两侧与 UT 都带 -define SYNTHESIS,
//       它不参与任何判定。本文件在 §3 末尾用等价的一行 SVA 表达同一条不变量。
//
// 本文件结构(单文件规范):
//   §1 package bloomfilter_pkg —— 规模常量
//   §2 module xs_BloomFilter_core —— 可读核
//   §3 module BloomFilter —— golden 同名 wrapper(端口逐位对齐,例化 u_core)
// =============================================================================

// -----------------------------------------------------------------------------
// §1 规模常量
// -----------------------------------------------------------------------------
package bloomfilter_pkg;

  // n = 4096。FDP.scala 里 BloomFilter(dcacheParameters.nSets * dcacheParameters.nWays)
  // 在 KunminghuV2Config 下单态化成 4096(golden 的 reg [4095:0] data 实测)。
  localparam int unsigned BLOOM_N      = 4096;
  // BLOOMADDRWIDTH = log2Ceil(n) = 12(golden 的 io_set_bits_addr 实测 12 位)。
  localparam int unsigned BLOOM_ADDR_W = 12;
  // LoadPipelineWidth = 3(golden 的 io_query_0..2 / io_resp_0..2 实测)。
  localparam int unsigned QUERY_N      = 3;

endpackage : bloomfilter_pkg

// =============================================================================
// §2 xs_BloomFilter_core —— 可读核
// =============================================================================
module xs_BloomFilter_core
  import bloomfilter_pkg::*;
#(
  parameter int unsigned N       = BLOOM_N,       // 位图位数
  parameter int unsigned NQUERY  = QUERY_N,       // 查询口数
  // bypass:查询读 data_next(1) 还是 data(0)。KunminghuV2Config 走默认 true。
  // 留参数是因为 Chisel 有这个开关;本核只在 1 的形态下与 golden 对照过。
  parameter bit          BYPASS  = 1'b1,
  // 派生量,例化时不要覆盖
  parameter int unsigned ADDR_W  = $clog2(N)
) (
  input  logic                              clock,
  input  logic                              reset,   // 异步高有效

  // 置位口:预取填充一条 block
  input  logic                              set_valid,
  input  logic [ADDR_W-1:0]                 set_addr,
  // 清位口:该 block 被换出/判定无用
  input  logic                              clr_valid,
  input  logic [ADDR_W-1:0]                 clr_addr,

  // 查询口(每条 load 流水一个)
  input  logic [NQUERY-1:0]                 query_valid,
  input  logic [NQUERY-1:0][ADDR_W-1:0]     query_addr,

  // 响应(固定延迟一拍)
  output logic [NQUERY-1:0]                 resp_valid,
  output logic [NQUERY-1:0]                 resp_res
);

  // ---------------------------------------------------------------------------
  // §2.1 位图与次态
  //
  // ★ 更新优先级 ★ 同一位同拍被 clr 和 set 同时点中时,**clr 赢**。
  // Chisel 写成 when(clr)…elsewhen(set)…otherwise(保持);golden 折成
  //   data_next[i] = ~(clr_valid & clr_addr==i) & (set_valid & set_addr==i | data[i])
  // 两者同义(clr 的 ~(...) 罩在最外层)。这里照 golden 的形状写,顺带把优先级
  // 摆在最显眼的位置。
  //
  // 为什么是「整条 4096 位每拍重算」而不是「单点写」:set/clr 各只有一个口,
  // 逻辑上等价于 data[set_addr]<=1 / data[clr_addr]<=0,但 Chisel 写成了
  // 逐位 Mux,firtool 就逐位展平成了 12288 行。综合后是同一块逻辑;
  // 这里用一个 always_comb 循环表达,读者一眼能看出「每位独立、优先级相同」。
  // ---------------------------------------------------------------------------
  logic [N-1:0] data;        // 位图本体(异步复位到全 0)
  logic [N-1:0] data_next;   // 本拍写回值,同时也是 bypass 读口的数据源

  always_comb begin
    for (int unsigned i = 0; i < N; i++) begin
      data_next[i] = ~(clr_valid & (clr_addr == ADDR_W'(i)))
                     & (  (set_valid & (set_addr == ADDR_W'(i)))
                        | data[i] );
    end
  end

  // ---------------------------------------------------------------------------
  // §2.2 位图寄存器 + 响应 valid —— 异步复位域
  //
  // golden always @(posedge clock or posedge reset):data 与三个 resp valid 打拍
  // 寄存器同在这一个块里,复位值全 0。data 的更新是**无条件**的(没有时钟使能)。
  // ---------------------------------------------------------------------------
  logic [NQUERY-1:0] resp_valid_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      data         <= '0;
      resp_valid_q <= '0;
    end else begin
      data         <= data_next;
      resp_valid_q <= query_valid;
    end
  end

  // ---------------------------------------------------------------------------
  // §2.3 查询结果寄存器 —— ★ 无复位域 ★
  //
  // golden 第二个 always @(posedge clock) 里**没有 reset 臂**:res 寄存器上电后
  // 保持不定值,直到第一次 query_valid 把它写掉。这不是疏漏而是 Chisel 的
  // RegEnable(无 init) 语义。照抄成带复位会凭空多出复位逻辑,FM 立刻失配。
  //
  // 读的是 data_next(BYPASS=1):同拍的 set/clr 对本拍的查询立即可见。
  // 索引位宽 ADDR_W = log2(N) 且数组恰好 N 项 —— 没有越界项,不需要补零扩展
  // (这正是 FMR_ELAB-147 那类「索引域比数组大」写法要避开的场景)。
  // ---------------------------------------------------------------------------
  logic [NQUERY-1:0] resp_res_q;
  wire  [N-1:0]      read_src = BYPASS ? data_next : data;

  always_ff @(posedge clock) begin
    for (int unsigned q = 0; q < NQUERY; q++) begin
      if (query_valid[q]) begin
        resp_res_q[q] <= read_src[query_addr[q]];
      end
    end
  end

  assign resp_valid = resp_valid_q;
  assign resp_res   = resp_res_q;

  // ---------------------------------------------------------------------------
  // §2.4 设计不变量(与 golden 的 FDP.scala:203 assert 同义)
  // 一拍最多一个 set 加一个 clr ⇒ 位图最多翻转 2 位。仅仿真,`ifndef SYNTHESIS
  // 与 golden 一致 —— FM 两侧、UT 都带 -define SYNTHESIS,这块不参与任何判定。
  // ---------------------------------------------------------------------------
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (!reset) begin
      assert ($countones(data ^ data_next) <= 2)
        else $error("BloomFilter: more than 2 bits toggled in one cycle");
    end
  end
`endif

endmodule : xs_BloomFilter_core

// =============================================================================
// §3 BloomFilter —— golden 同名 wrapper
// 端口名/顺序/位宽与 G1 golden 逐位一致(scripts/port_contract_lint.py --order fail)。
// 只做「扁平 io_* 名 ↔ 核的数组端口」的换名,无逻辑。
// =============================================================================
module BloomFilter (
  input         clock,
  input         reset,
  input         io_set_valid,
  input  [11:0] io_set_bits_addr,
  input         io_clr_valid,
  input  [11:0] io_clr_bits_addr,
  input         io_query_0_valid,
  input  [11:0] io_query_0_bits_addr,
  input         io_query_1_valid,
  input  [11:0] io_query_1_bits_addr,
  input         io_query_2_valid,
  input  [11:0] io_query_2_bits_addr,
  output        io_resp_0_valid,
  output        io_resp_0_bits_res,
  output        io_resp_1_valid,
  output        io_resp_1_bits_res,
  output        io_resp_2_valid,
  output        io_resp_2_bits_res
);

  wire [2:0]       query_valid = {io_query_2_valid, io_query_1_valid, io_query_0_valid};
  wire [2:0][11:0] query_addr  = {io_query_2_bits_addr, io_query_1_bits_addr,
                                  io_query_0_bits_addr};
  wire [2:0]       resp_valid;
  wire [2:0]       resp_res;

  xs_BloomFilter_core #(
    .N      (4096),
    .NQUERY (3),
    .BYPASS (1'b1)
  ) u_core (
    .clock       (clock),
    .reset       (reset),
    .set_valid   (io_set_valid),
    .set_addr    (io_set_bits_addr),
    .clr_valid   (io_clr_valid),
    .clr_addr    (io_clr_bits_addr),
    .query_valid (query_valid),
    .query_addr  (query_addr),
    .resp_valid  (resp_valid),
    .resp_res    (resp_res)
  );

  assign io_resp_0_valid    = resp_valid[0];
  assign io_resp_0_bits_res = resp_res[0];
  assign io_resp_1_valid    = resp_valid[1];
  assign io_resp_1_bits_res = resp_res[1];
  assign io_resp_2_valid    = resp_valid[2];
  assign io_resp_2_bits_res = resp_res[2];

endmodule : BloomFilter
