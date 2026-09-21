// =============================================================================
// DatamoduleResultBuffer.sv —— StoreQueue 出队侧的 2 条目乒乓缓冲
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/mem/lsqueue/DatamoduleResultBuffer.scala
// golden 对照:G1 golden-rtl/DatamoduleResultBuffer.sv(362 行 / 45 端口 / 22 寄存器)
//
// 【它是干什么的】
// StoreQueue 的数据/地址 module 是**同步读**(读地址打一拍才出数据)。出队时上游
// 一次可以给出 2 个条目,下游(sbuffer)也一次收 2 个,但两边的节拍不保证对齐。
// 本模块就是夹在中间的那个深度=2 的小 FIFO:enq 侧 2 口、deq 侧 2 口,用一对
// 1 bit 轮转指针(enq_flag / deq_flag)在两个条目之间乒乓,而不是用读写指针+计数。
//
//   enq 端口 p 落到条目 (enq_flag + p) % 2
//   deq 端口 p 取自条目 (deq_flag + p) % 2
//   每拍成交 1 个 → 指针翻转;成交 0 个或 2 个 → 指针不动(2 次翻转 = 不动)
//
// 【★ 与 golden 对齐时踩到/避开的三个点 ★】
//
//  1) ★复位域是"4 个异步复位 + 18 个完全不复位",零交集★
//     控制位 valids[0..1] / enq_flag / deq_flag 走
//         always @(posedge clock or posedge reset)  —— 异步复位
//     数据位 data[0..1] 的 8 个字段(共 18 个寄存器)走
//         always @(posedge clock)                   —— **根本没有复位**
//     这是 Chisel 里 RegInit(控制) vs 裸 Reg(数据) 的直接后果。照抄成全复位
//     是真 bug:elaborate 不报、lint 不报,只有 FM 抓得到。
//
//  2) ★enq 端口 1 没有 sqNeedDeq 端口,模块内部把它钉成常数 1★
//     golden 端口表里只有 io_enq_0_bits_sqNeedDeq,没有 io_enq_1_bits_sqNeedDeq;
//     被 enq 口 1 写入的条目其 sqNeedDeq 直接取 1'b1:
//         data_0_sqNeedDeq <= _GEN_3 | (_GEN_0 ? io_enq_0_bits_sqNeedDeq : ...)
//                             ^^^^^^ 端口1命中即置 1,不看任何输入
//     成因是父模块 StoreQueue 把 enq(1).bits.sqNeedDeq 接了 true.B,firtool 把它
//     常数折叠掉了。这里用 ENQ_SQ_NEED_DEQ_CONST 把这份不对称显式写出来,
//     **不要**为了"对称好看"给端口 1 补一个端口——那会多出一个 golden 没有的端口。
//
//  3) golden 把 1 bit 指针的"另一个下标"写成 1'(flag - 1'h1)(1 bit 减一)。
//     1 bit 下减一 == 取反,这里写成 ~flag 并在此注明,避免读者以为有进位语义。
//
// 【更新优先级】同一条目同拍被多源写时的优先级(golden if/else-if 顺序):
//     enq 端口 1 > enq 端口 0。
//     ——但在本设计里两个 enq 口按构造落在**不同**条目(p=0 去 enq_flag,
//       p=1 去 enq_flag^1),所以这条优先级永远不会真的仲裁。它只决定生成代码的
//       形状。下面用 "后写者胜" 的 for 循环复现同一形状。
//
// 【非综合断言】golden 带 4 条 assert(DatamoduleResultBuffer.scala:63/64/76/77):
//     deq/enq 两个端口的 valid 与 ready 都必须是"低位先满"的前缀形状。
//     这里原样保留(`ifndef SYNTHESIS`),它们是本模块对上下游的接口契约。
// =============================================================================

// -----------------------------------------------------------------------------
// §1 尺寸常量
// -----------------------------------------------------------------------------
package datamodule_result_buffer_pkg;

  // golden 规模:2 条目 / 2 个 enq 口 / 2 个 deq 口(DatamoduleResultBuffer.scala
  // 在 StoreQueue 里以 numEntries=2, numEnq=2, numDeq=2 单态化)。
  localparam int NUM_ENTRIES = 2;
  localparam int NUM_ENQ     = 2;
  localparam int NUM_DEQ     = 2;

  // 负载字段宽度,全部从 golden 端口表机械量得。
  localparam int ADDR_W  = 48;   // io_*_bits_addr   —— 物理地址 PAddrBits
  localparam int VADDR_W = 50;   // io_*_bits_vaddr  —— 虚地址 VAddrBits+1
  localparam int DATA_W  = 128;  // io_*_bits_data   —— VLEN
  localparam int MASK_W  = 16;   // io_*_bits_mask   —— VLEN/8
  localparam int SQPTR_W = 6;    // io_*_bits_sqPtr_value —— log2Up(StoreQueueSize=56)

  // 一个条目的全部负载。golden 把它摊平成独立寄存器,这里打包成 struct:
  // 打包只改可读性,不改寄存器集合(每个字段仍是一个独立寄存器)。
  typedef struct packed {
    logic [ADDR_W-1:0]  addr;
    logic [VADDR_W-1:0] vaddr;
    logic [DATA_W-1:0]  data;
    logic [MASK_W-1:0]  mask;
    logic               wline;
    logic               sqPtr_flag;
    logic [SQPTR_W-1:0] sqPtr_value;
    logic               vecValid;
    logic               sqNeedDeq;
  } entry_t;

endpackage

// -----------------------------------------------------------------------------
// §2 xs_DatamoduleResultBuffer_core —— 可读核
// -----------------------------------------------------------------------------
module xs_DatamoduleResultBuffer_core
  import datamodule_result_buffer_pkg::*;
(
  input  logic   clock,
  input  logic   reset,

  // enq 侧(Decoupled):上游给,本模块收
  output logic   enq_ready [NUM_ENQ],
  input  logic   enq_valid [NUM_ENQ],
  input  entry_t enq_bits  [NUM_ENQ],

  // deq 侧(Decoupled):本模块给,下游收
  input  logic   deq_ready [NUM_DEQ],
  output logic   deq_valid [NUM_DEQ],
  output entry_t deq_bits  [NUM_DEQ]
);

  // ---------------------------------------------------------------------------
  // §2.1 状态
  // ---------------------------------------------------------------------------
  // ★ 数据条目:不复位 ★(golden 的 data_{0,1}_* 全在裸 always @(posedge clock) 里)
  entry_t entries [NUM_ENTRIES];

  // ★ 控制位:异步复位 ★
  logic                    valids   [NUM_ENTRIES];
  logic                    enq_flag;   // 下一个 enq 落点
  logic                    deq_flag;   // 下一个 deq 取点

  // 1 bit 指针的"另一个下标"。golden 写作 1'(flag - 1'h1);1 bit 位宽下
  // 减一与取反等价,这里取更直白的写法。
  wire  logic enq_flag_n = ~enq_flag;
  wire  logic deq_flag_n = ~deq_flag;

  // ---------------------------------------------------------------------------
  // §2.2 端口 ↔ 条目的轮转映射
  // ---------------------------------------------------------------------------
  // enq 端口 p → 条目 (enq_flag + p) % 2;deq 端口 p → 条目 (deq_flag + p) % 2。
  // NUM_ENQ/NUM_DEQ 都等于 NUM_ENTRIES=2,故 p∈{0,1} 恰好覆盖两个条目。
  logic enq_idx [NUM_ENQ];
  logic deq_idx [NUM_DEQ];
  always_comb begin
    enq_idx[0] = enq_flag;
    enq_idx[1] = enq_flag_n;
    deq_idx[0] = deq_flag;
    deq_idx[1] = deq_flag_n;
  end

  // ---------------------------------------------------------------------------
  // §2.3 deq 侧:valid / bits
  // ---------------------------------------------------------------------------
  // 端口 p 只有在端口 p-1 也有效时才有效 —— 出队必须是连续前缀,下游按序收。
  logic deq_valid_i [NUM_DEQ];
  always_comb begin
    deq_valid_i[0] = valids[deq_idx[0]];
    deq_valid_i[1] = valids[deq_idx[1]] & deq_valid_i[0];
  end

  logic deq_fire [NUM_DEQ];
  always_comb for (int p = 0; p < NUM_DEQ; p++) deq_fire[p] = deq_ready[p] & deq_valid_i[p];

  // ---------------------------------------------------------------------------
  // §2.4 enq 侧:ready
  // ---------------------------------------------------------------------------
  // 条目可进新数据 = 它本来就空,或者本拍正被某个 deq 口取走(取走与写入同拍直通)。
  logic entry_allowin [NUM_ENTRIES];
  always_comb begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      entry_allowin[e] = ~valids[e];
      for (int p = 0; p < NUM_DEQ; p++)
        if (deq_fire[p] & (deq_idx[p] == e[0])) entry_allowin[e] = 1'b1;
    end
  end

  logic enq_ready_i [NUM_ENQ];
  always_comb begin
    enq_ready_i[0] = entry_allowin[enq_idx[0]];
    enq_ready_i[1] = entry_allowin[enq_idx[1]] & enq_ready_i[0];
  end

  logic enq_fire [NUM_ENQ];
  always_comb for (int p = 0; p < NUM_ENQ; p++) enq_fire[p] = enq_ready_i[p] & enq_valid[p];

  // ---------------------------------------------------------------------------
  // §2.5 命中向量:本拍哪个条目被写 / 被取
  // ---------------------------------------------------------------------------
  logic enq_hit [NUM_ENTRIES];
  logic deq_hit [NUM_ENTRIES];
  always_comb begin
    for (int e = 0; e < NUM_ENTRIES; e++) begin
      enq_hit[e] = 1'b0;
      deq_hit[e] = 1'b0;
      for (int p = 0; p < NUM_ENQ; p++) if (enq_fire[p] & (enq_idx[p] == e[0])) enq_hit[e] = 1'b1;
      for (int p = 0; p < NUM_DEQ; p++) if (deq_fire[p] & (deq_idx[p] == e[0])) deq_hit[e] = 1'b1;
    end
  end

  // ---------------------------------------------------------------------------
  // §2.6 时序:数据条目(★不复位★)
  // ---------------------------------------------------------------------------
  // for 循环内的阻塞语义 = "后写者胜",即 enq 端口号大的赢 —— 与 golden 的
  // if(端口1) / else if(端口0) 同形。见文件头【更新优先级】:两个端口按构造
  // 落在不同条目,这条优先级不会真的仲裁。
  always_ff @(posedge clock) begin
    for (int e = 0; e < NUM_ENTRIES; e++)
      for (int p = 0; p < NUM_ENQ; p++)
        if (enq_fire[p] & (enq_idx[p] == e[0])) entries[e] <= enq_bits[p];
  end

  // ---------------------------------------------------------------------------
  // §2.7 时序:控制位(★异步复位★)
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int e = 0; e < NUM_ENTRIES; e++) valids[e] <= 1'b0;
      enq_flag <= 1'b0;
      deq_flag <= 1'b0;
    end else begin
      // 新写入置位优先于被取走清位:同拍既取走又写入 = 仍然有效。
      for (int e = 0; e < NUM_ENTRIES; e++)
        valids[e] <= (valids[e] & ~deq_hit[e]) | enq_hit[e];

      // 指针按"本拍成交个数"前进。成交 2 个 = 转一圈回到原位,故只在
      // 恰好成交 1 个(端口 0 成而端口 1 不成)时翻转。
      if (enq_fire[0] & ~enq_fire[1]) enq_flag <= enq_flag_n;
      if (deq_fire[0] & ~deq_fire[1]) deq_flag <= deq_flag_n;
    end
  end

  // ---------------------------------------------------------------------------
  // §2.8 组合输出
  // ---------------------------------------------------------------------------
  always_comb begin
    for (int p = 0; p < NUM_ENQ; p++) enq_ready[p] = enq_ready_i[p];
    for (int p = 0; p < NUM_DEQ; p++) begin
      deq_valid[p] = deq_valid_i[p];
      deq_bits[p]  = entries[deq_idx[p]];
    end
  end

  // ---------------------------------------------------------------------------
  // §2.9 接口契约断言(golden DatamoduleResultBuffer.scala:63/64/76/77)
  // ---------------------------------------------------------------------------
  // valid / ready 在两个方向上都必须是"低位先满"的连续前缀。
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (~reset) begin
      for (int p = 1; p < NUM_DEQ; p++) begin
        assert (!(deq_valid_i[p] && !deq_valid_i[p-1]))
          else $fatal(1, "DatamoduleResultBuffer: deq(%0d).valid without deq(%0d).valid", p, p-1);
        assert (!(deq_ready[p] && !deq_ready[p-1]))
          else $fatal(1, "DatamoduleResultBuffer: deq(%0d).ready without deq(%0d).ready", p, p-1);
      end
      for (int p = 1; p < NUM_ENQ; p++) begin
        assert (!(enq_ready_i[p] && !enq_ready_i[p-1]))
          else $fatal(1, "DatamoduleResultBuffer: enq(%0d).ready without enq(%0d).ready", p, p-1);
        assert (!(enq_valid[p] && !enq_valid[p-1]))
          else $fatal(1, "DatamoduleResultBuffer: enq(%0d).valid without enq(%0d).valid", p, p-1);
      end
    end
  end
`endif

endmodule

// -----------------------------------------------------------------------------
// §3 DatamoduleResultBuffer —— golden 同名薄 wrapper
// -----------------------------------------------------------------------------
// 端口名/顺序/位宽逐位对齐 G1 golden。★enq 口 1 没有 sqNeedDeq★:wrapper 在
// 打包时给它填常数 1(见文件头第 2 点),这是 golden 的行为,不是省略。
module DatamoduleResultBuffer(
  input          clock,
  input          reset,
  output         io_enq_0_ready,
  input          io_enq_0_valid,
  input  [47:0]  io_enq_0_bits_addr,
  input  [49:0]  io_enq_0_bits_vaddr,
  input  [127:0] io_enq_0_bits_data,
  input  [15:0]  io_enq_0_bits_mask,
  input          io_enq_0_bits_wline,
  input          io_enq_0_bits_sqPtr_flag,
  input  [5:0]   io_enq_0_bits_sqPtr_value,
  input          io_enq_0_bits_vecValid,
  input          io_enq_0_bits_sqNeedDeq,
  output         io_enq_1_ready,
  input          io_enq_1_valid,
  input  [47:0]  io_enq_1_bits_addr,
  input  [49:0]  io_enq_1_bits_vaddr,
  input  [127:0] io_enq_1_bits_data,
  input  [15:0]  io_enq_1_bits_mask,
  input          io_enq_1_bits_wline,
  input          io_enq_1_bits_sqPtr_flag,
  input  [5:0]   io_enq_1_bits_sqPtr_value,
  input          io_enq_1_bits_vecValid,
  input          io_deq_0_ready,
  output         io_deq_0_valid,
  output [47:0]  io_deq_0_bits_addr,
  output [49:0]  io_deq_0_bits_vaddr,
  output [127:0] io_deq_0_bits_data,
  output [15:0]  io_deq_0_bits_mask,
  output         io_deq_0_bits_wline,
  output         io_deq_0_bits_sqPtr_flag,
  output [5:0]   io_deq_0_bits_sqPtr_value,
  output         io_deq_0_bits_vecValid,
  output         io_deq_0_bits_sqNeedDeq,
  input          io_deq_1_ready,
  output         io_deq_1_valid,
  output [47:0]  io_deq_1_bits_addr,
  output [49:0]  io_deq_1_bits_vaddr,
  output [127:0] io_deq_1_bits_data,
  output [15:0]  io_deq_1_bits_mask,
  output         io_deq_1_bits_wline,
  output         io_deq_1_bits_sqPtr_flag,
  output [5:0]   io_deq_1_bits_sqPtr_value,
  output         io_deq_1_bits_vecValid,
  output         io_deq_1_bits_sqNeedDeq
);

  datamodule_result_buffer_pkg::entry_t enq_bits [2];
  datamodule_result_buffer_pkg::entry_t deq_bits [2];
  logic enq_ready [2], enq_valid [2];
  logic deq_ready [2], deq_valid [2];

  always_comb begin
    enq_valid[0] = io_enq_0_valid;
    enq_bits[0]  = '{addr        : io_enq_0_bits_addr,
                     vaddr       : io_enq_0_bits_vaddr,
                     data        : io_enq_0_bits_data,
                     mask        : io_enq_0_bits_mask,
                     wline       : io_enq_0_bits_wline,
                     sqPtr_flag  : io_enq_0_bits_sqPtr_flag,
                     sqPtr_value : io_enq_0_bits_sqPtr_value,
                     vecValid    : io_enq_0_bits_vecValid,
                     sqNeedDeq   : io_enq_0_bits_sqNeedDeq};

    enq_valid[1] = io_enq_1_valid;
    enq_bits[1]  = '{addr        : io_enq_1_bits_addr,
                     vaddr       : io_enq_1_bits_vaddr,
                     data        : io_enq_1_bits_data,
                     mask        : io_enq_1_bits_mask,
                     wline       : io_enq_1_bits_wline,
                     sqPtr_flag  : io_enq_1_bits_sqPtr_flag,
                     sqPtr_value : io_enq_1_bits_sqPtr_value,
                     vecValid    : io_enq_1_bits_vecValid,
                     // ★ golden 没有 io_enq_1_bits_sqNeedDeq 端口:父模块把它接了
                     //   true.B,firtool 常数折叠。此处必须是常数 1,不是端口。
                     sqNeedDeq   : 1'b1};

    deq_ready[0] = io_deq_0_ready;
    deq_ready[1] = io_deq_1_ready;
  end

  xs_DatamoduleResultBuffer_core u_core (
    .clock     (clock),
    .reset     (reset),
    .enq_ready (enq_ready),
    .enq_valid (enq_valid),
    .enq_bits  (enq_bits),
    .deq_ready (deq_ready),
    .deq_valid (deq_valid),
    .deq_bits  (deq_bits)
  );

  assign io_enq_0_ready           = enq_ready[0];
  assign io_enq_1_ready           = enq_ready[1];

  assign io_deq_0_valid           = deq_valid[0];
  assign io_deq_0_bits_addr       = deq_bits[0].addr;
  assign io_deq_0_bits_vaddr      = deq_bits[0].vaddr;
  assign io_deq_0_bits_data       = deq_bits[0].data;
  assign io_deq_0_bits_mask       = deq_bits[0].mask;
  assign io_deq_0_bits_wline      = deq_bits[0].wline;
  assign io_deq_0_bits_sqPtr_flag = deq_bits[0].sqPtr_flag;
  assign io_deq_0_bits_sqPtr_value= deq_bits[0].sqPtr_value;
  assign io_deq_0_bits_vecValid   = deq_bits[0].vecValid;
  assign io_deq_0_bits_sqNeedDeq  = deq_bits[0].sqNeedDeq;

  assign io_deq_1_valid           = deq_valid[1];
  assign io_deq_1_bits_addr       = deq_bits[1].addr;
  assign io_deq_1_bits_vaddr      = deq_bits[1].vaddr;
  assign io_deq_1_bits_data       = deq_bits[1].data;
  assign io_deq_1_bits_mask       = deq_bits[1].mask;
  assign io_deq_1_bits_wline      = deq_bits[1].wline;
  assign io_deq_1_bits_sqPtr_flag = deq_bits[1].sqPtr_flag;
  assign io_deq_1_bits_sqPtr_value= deq_bits[1].sqPtr_value;
  assign io_deq_1_bits_vecValid   = deq_bits[1].vecValid;
  assign io_deq_1_bits_sqNeedDeq  = deq_bits[1].sqNeedDeq;

endmodule
