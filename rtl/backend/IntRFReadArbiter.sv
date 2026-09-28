// IntRFReadArbiter.sv —— 整数寄存器堆读口仲裁：每个物理读口同拍只给一个源操作数
// =============================================================================
// 在哪一层：DataPath 的 og0 级（发射后第 0 拍，读寄存器堆之前）。Chisel:
//   backend/datapath/RFReadArbiter.scala class IntRFReadArbiter extends RFReadArbiterBase；
//   golden: G1-canonical/golden-rtl/IntRFReadArbiter.sv（IntPregParams：224 项，物理寄存器号 8 位）。
//
// 机制：每个 EXU 的每个源操作数在配置期被静态分到整数寄存器堆的某个读口（RdConfig.port）并带
//   口内优先级（RdConfig.priority）。共用一个读口的源在同一拍发射时要仲裁：每个读口 k 一个
//   WBArbiter（arbiters_k），输入按 priority 升序接（in0 优先级最高），payload 是物理寄存器号 addr。
//     in.ready   = 该源拿到了读口（或本拍没请求）；拿不到的 uop 由 DataPath 在 og0 取消。
//     out_k      = {valid, addr}：读口 k 本拍送给寄存器堆的读地址。
//   WBArbiter 自带反饥饿（连续被拒 7 拍后优先放行，见 rtl/backend/WBArbiter.sv）。
//   不读整数寄存器堆的源（NoRD）不经过任何仲裁器，ready 恒 1。
//
// 端口命名：io_in_<iq>_<exu>_<src>：第 iq 个发射队列、第 exu 个执行单元、第 src 个源操作数的读请求
//   （每个源 5 种寄存器堆各一个请求位，本模块只接整数这一种）。
// 规模（KunminghuV2Config，golden 实测）：71 个请求输入，11 个读口（每口竞争者数 2/2/2/3/2/3/3/3/1/1/1），
//   48 个输入是 NoRD；仲裁器类型 WBArbiter_30/_33/_38（addr 8 位）。
//
// ★与 golden 不同之处（不影响任何输出）★：golden 里有一段 XSPerfAccumulate 留下的冲突统计
//   组合逻辑（hasConflict_* / hasRead0 / hasSameAddr，只对 Int 生成）。性能计数器在本配置下没有
//   引出，这些线网在 golden 里**没有任何负载**（不到端口、不进寄存器），不形成比较点，本文件不写。
//   生成器对"无负载"做了断言（被例化或 assign 引用即退出）。
//
// 本层无寄存器，只有例化与常量；全部时序状态在 WBArbiter 里。WBArbiter 家族已单独签核，
// 这里以同名模块例化（UT/FM 两侧白盒：ref golden，impl 本仓重写件）。
// 下面 GENERATED 区由 scripts/gen_datapath_arb.py 从 golden 例化表解析产出：端口表逐行同 golden，
// 每个例化前一行注释写明"这个读口由谁竞争、优先级顺序"。
// =============================================================================
// BEGIN GENERATED(dp_arb) —— 由 scripts/gen_datapath_arb.py 从 golden 例化表产出，勿手改
module IntRFReadArbiter(
  input        clock,
  input        reset,
  output       io_in_18_0_0_ready,
  input        io_in_18_0_0_valid,
  input  [7:0] io_in_18_0_0_bits_addr,
  output       io_in_17_0_0_ready,
  input        io_in_17_0_0_valid,
  input  [7:0] io_in_17_0_0_bits_addr,
  output       io_in_16_0_4_ready,
  input        io_in_16_0_4_valid,
  input  [7:0] io_in_16_0_4_bits_addr,
  output       io_in_16_0_3_ready,
  input        io_in_16_0_3_valid,
  input  [7:0] io_in_16_0_3_bits_addr,
  output       io_in_16_0_2_ready,
  input        io_in_16_0_2_valid,
  input  [7:0] io_in_16_0_2_bits_addr,
  output       io_in_16_0_1_ready,
  input        io_in_16_0_1_valid,
  input  [7:0] io_in_16_0_1_bits_addr,
  output       io_in_16_0_0_ready,
  input        io_in_16_0_0_valid,
  input  [7:0] io_in_16_0_0_bits_addr,
  output       io_in_15_0_4_ready,
  input        io_in_15_0_4_valid,
  input  [7:0] io_in_15_0_4_bits_addr,
  output       io_in_15_0_3_ready,
  input        io_in_15_0_3_valid,
  input  [7:0] io_in_15_0_3_bits_addr,
  output       io_in_15_0_2_ready,
  input        io_in_15_0_2_valid,
  input  [7:0] io_in_15_0_2_bits_addr,
  output       io_in_15_0_1_ready,
  input        io_in_15_0_1_valid,
  input  [7:0] io_in_15_0_1_bits_addr,
  output       io_in_15_0_0_ready,
  input        io_in_15_0_0_valid,
  input  [7:0] io_in_15_0_0_bits_addr,
  output       io_in_14_0_0_ready,
  input        io_in_14_0_0_valid,
  input  [7:0] io_in_14_0_0_bits_addr,
  output       io_in_13_0_0_ready,
  input        io_in_13_0_0_valid,
  input  [7:0] io_in_13_0_0_bits_addr,
  output       io_in_12_0_0_ready,
  input        io_in_12_0_0_valid,
  input  [7:0] io_in_12_0_0_bits_addr,
  output       io_in_11_0_0_ready,
  input        io_in_11_0_0_valid,
  input  [7:0] io_in_11_0_0_bits_addr,
  output       io_in_10_0_0_ready,
  input        io_in_10_0_0_valid,
  input  [7:0] io_in_10_0_0_bits_addr,
  output       io_in_9_0_4_ready,
  input        io_in_9_0_4_valid,
  input  [7:0] io_in_9_0_4_bits_addr,
  output       io_in_9_0_3_ready,
  input        io_in_9_0_3_valid,
  input  [7:0] io_in_9_0_3_bits_addr,
  output       io_in_9_0_2_ready,
  input        io_in_9_0_2_valid,
  input  [7:0] io_in_9_0_2_bits_addr,
  output       io_in_9_0_1_ready,
  input        io_in_9_0_1_valid,
  input  [7:0] io_in_9_0_1_bits_addr,
  output       io_in_9_0_0_ready,
  input        io_in_9_0_0_valid,
  input  [7:0] io_in_9_0_0_bits_addr,
  output       io_in_8_1_4_ready,
  input        io_in_8_1_4_valid,
  input  [7:0] io_in_8_1_4_bits_addr,
  output       io_in_8_1_3_ready,
  input        io_in_8_1_3_valid,
  input  [7:0] io_in_8_1_3_bits_addr,
  output       io_in_8_1_2_ready,
  input        io_in_8_1_2_valid,
  input  [7:0] io_in_8_1_2_bits_addr,
  output       io_in_8_1_1_ready,
  input        io_in_8_1_1_valid,
  input  [7:0] io_in_8_1_1_bits_addr,
  output       io_in_8_1_0_ready,
  input        io_in_8_1_0_valid,
  input  [7:0] io_in_8_1_0_bits_addr,
  output       io_in_8_0_4_ready,
  input        io_in_8_0_4_valid,
  input  [7:0] io_in_8_0_4_bits_addr,
  output       io_in_8_0_3_ready,
  input        io_in_8_0_3_valid,
  input  [7:0] io_in_8_0_3_bits_addr,
  output       io_in_8_0_2_ready,
  input        io_in_8_0_2_valid,
  input  [7:0] io_in_8_0_2_bits_addr,
  output       io_in_8_0_1_ready,
  input        io_in_8_0_1_valid,
  input  [7:0] io_in_8_0_1_bits_addr,
  output       io_in_8_0_0_ready,
  input        io_in_8_0_0_valid,
  input  [7:0] io_in_8_0_0_bits_addr,
  output       io_in_7_1_4_ready,
  input        io_in_7_1_4_valid,
  input  [7:0] io_in_7_1_4_bits_addr,
  output       io_in_7_1_3_ready,
  input        io_in_7_1_3_valid,
  input  [7:0] io_in_7_1_3_bits_addr,
  output       io_in_7_1_2_ready,
  input        io_in_7_1_2_valid,
  input  [7:0] io_in_7_1_2_bits_addr,
  output       io_in_7_1_1_ready,
  input        io_in_7_1_1_valid,
  input  [7:0] io_in_7_1_1_bits_addr,
  output       io_in_7_1_0_ready,
  input        io_in_7_1_0_valid,
  input  [7:0] io_in_7_1_0_bits_addr,
  output       io_in_7_0_4_ready,
  input        io_in_7_0_4_valid,
  input  [7:0] io_in_7_0_4_bits_addr,
  output       io_in_7_0_3_ready,
  input        io_in_7_0_3_valid,
  input  [7:0] io_in_7_0_3_bits_addr,
  output       io_in_7_0_2_ready,
  input        io_in_7_0_2_valid,
  input  [7:0] io_in_7_0_2_bits_addr,
  output       io_in_7_0_1_ready,
  input        io_in_7_0_1_valid,
  input  [7:0] io_in_7_0_1_bits_addr,
  output       io_in_7_0_0_ready,
  input        io_in_7_0_0_valid,
  input  [7:0] io_in_7_0_0_bits_addr,
  output       io_in_6_0_2_ready,
  input        io_in_6_0_2_valid,
  input  [7:0] io_in_6_0_2_bits_addr,
  output       io_in_6_0_1_ready,
  input        io_in_6_0_1_valid,
  input  [7:0] io_in_6_0_1_bits_addr,
  output       io_in_6_0_0_ready,
  input        io_in_6_0_0_valid,
  input  [7:0] io_in_6_0_0_bits_addr,
  output       io_in_5_1_1_ready,
  input        io_in_5_1_1_valid,
  input  [7:0] io_in_5_1_1_bits_addr,
  output       io_in_5_1_0_ready,
  input        io_in_5_1_0_valid,
  input  [7:0] io_in_5_1_0_bits_addr,
  output       io_in_5_0_2_ready,
  input        io_in_5_0_2_valid,
  input  [7:0] io_in_5_0_2_bits_addr,
  output       io_in_5_0_1_ready,
  input        io_in_5_0_1_valid,
  input  [7:0] io_in_5_0_1_bits_addr,
  output       io_in_5_0_0_ready,
  input        io_in_5_0_0_valid,
  input  [7:0] io_in_5_0_0_bits_addr,
  output       io_in_4_1_1_ready,
  input        io_in_4_1_1_valid,
  input  [7:0] io_in_4_1_1_bits_addr,
  output       io_in_4_1_0_ready,
  input        io_in_4_1_0_valid,
  input  [7:0] io_in_4_1_0_bits_addr,
  output       io_in_4_0_2_ready,
  input        io_in_4_0_2_valid,
  input  [7:0] io_in_4_0_2_bits_addr,
  output       io_in_4_0_1_ready,
  input        io_in_4_0_1_valid,
  input  [7:0] io_in_4_0_1_bits_addr,
  output       io_in_4_0_0_ready,
  input        io_in_4_0_0_valid,
  input  [7:0] io_in_4_0_0_bits_addr,
  output       io_in_3_1_1_ready,
  input        io_in_3_1_1_valid,
  input  [7:0] io_in_3_1_1_bits_addr,
  output       io_in_3_1_0_ready,
  input        io_in_3_1_0_valid,
  input  [7:0] io_in_3_1_0_bits_addr,
  output       io_in_3_0_1_ready,
  input        io_in_3_0_1_valid,
  input  [7:0] io_in_3_0_1_bits_addr,
  output       io_in_3_0_0_ready,
  input        io_in_3_0_0_valid,
  input  [7:0] io_in_3_0_0_bits_addr,
  output       io_in_2_1_1_ready,
  input        io_in_2_1_1_valid,
  input  [7:0] io_in_2_1_1_bits_addr,
  output       io_in_2_1_0_ready,
  input        io_in_2_1_0_valid,
  input  [7:0] io_in_2_1_0_bits_addr,
  output       io_in_2_0_1_ready,
  input        io_in_2_0_1_valid,
  input  [7:0] io_in_2_0_1_bits_addr,
  output       io_in_2_0_0_ready,
  input        io_in_2_0_0_valid,
  input  [7:0] io_in_2_0_0_bits_addr,
  output       io_in_1_1_1_ready,
  input        io_in_1_1_1_valid,
  input  [7:0] io_in_1_1_1_bits_addr,
  output       io_in_1_1_0_ready,
  input        io_in_1_1_0_valid,
  input  [7:0] io_in_1_1_0_bits_addr,
  output       io_in_1_0_1_ready,
  input        io_in_1_0_1_valid,
  input  [7:0] io_in_1_0_1_bits_addr,
  output       io_in_1_0_0_ready,
  input        io_in_1_0_0_valid,
  input  [7:0] io_in_1_0_0_bits_addr,
  output       io_in_0_1_1_ready,
  input        io_in_0_1_1_valid,
  input  [7:0] io_in_0_1_1_bits_addr,
  output       io_in_0_1_0_ready,
  input        io_in_0_1_0_valid,
  input  [7:0] io_in_0_1_0_bits_addr,
  output       io_in_0_0_1_ready,
  input        io_in_0_0_1_valid,
  input  [7:0] io_in_0_0_1_bits_addr,
  output       io_in_0_0_0_ready,
  input        io_in_0_0_0_valid,
  input  [7:0] io_in_0_0_0_bits_addr,
  output       io_out_0_valid,
  output [7:0] io_out_0_bits_addr,
  output       io_out_1_valid,
  output [7:0] io_out_1_bits_addr,
  output       io_out_2_valid,
  output [7:0] io_out_2_bits_addr,
  output       io_out_3_valid,
  output [7:0] io_out_3_bits_addr,
  output       io_out_4_valid,
  output [7:0] io_out_4_bits_addr,
  output       io_out_5_valid,
  output [7:0] io_out_5_bits_addr,
  output       io_out_6_valid,
  output [7:0] io_out_6_bits_addr,
  output       io_out_7_valid,
  output [7:0] io_out_7_bits_addr,
  output       io_out_8_valid,
  output [7:0] io_out_8_bits_addr,
  output       io_out_9_valid,
  output [7:0] io_out_9_bits_addr,
  output       io_out_10_valid,
  output [7:0] io_out_10_bits_addr
);

  // 读口 0：2 路竞争，优先级 IQ0.EXU0.src0 > IQ3.EXU1.src0
  WBArbiter_30 arbiters_0 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_0_0_0_ready),
    .io_in_0_valid     (io_in_0_0_0_valid),
    .io_in_0_bits_addr (io_in_0_0_0_bits_addr),
    .io_in_1_ready     (io_in_3_1_0_ready),
    .io_in_1_valid     (io_in_3_1_0_valid),
    .io_in_1_bits_addr (io_in_3_1_0_bits_addr),
    .io_out_valid      (io_out_0_valid),
    .io_out_bits_addr  (io_out_0_bits_addr)
  );
  // 读口 1：2 路竞争，优先级 IQ0.EXU0.src1 > IQ3.EXU1.src1
  WBArbiter_30 arbiters_1 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_0_0_1_ready),
    .io_in_0_valid     (io_in_0_0_1_valid),
    .io_in_0_bits_addr (io_in_0_0_1_bits_addr),
    .io_in_1_ready     (io_in_3_1_1_ready),
    .io_in_1_valid     (io_in_3_1_1_valid),
    .io_in_1_bits_addr (io_in_3_1_1_bits_addr),
    .io_out_valid      (io_out_1_valid),
    .io_out_bits_addr  (io_out_1_bits_addr)
  );
  // 读口 2：2 路竞争，优先级 IQ1.EXU0.src0 > IQ2.EXU1.src0
  WBArbiter_30 arbiters_2 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_1_0_0_ready),
    .io_in_0_valid     (io_in_1_0_0_valid),
    .io_in_0_bits_addr (io_in_1_0_0_bits_addr),
    .io_in_1_ready     (io_in_2_1_0_ready),
    .io_in_1_valid     (io_in_2_1_0_valid),
    .io_in_1_bits_addr (io_in_2_1_0_bits_addr),
    .io_out_valid      (io_out_2_valid),
    .io_out_bits_addr  (io_out_2_bits_addr)
  );
  // 读口 3：3 路竞争，优先级 IQ1.EXU0.src1 > IQ2.EXU1.src1 > IQ18.EXU0.src0
  WBArbiter_33 arbiters_3 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_1_0_1_ready),
    .io_in_0_valid     (io_in_1_0_1_valid),
    .io_in_0_bits_addr (io_in_1_0_1_bits_addr),
    .io_in_1_ready     (io_in_2_1_1_ready),
    .io_in_1_valid     (io_in_2_1_1_valid),
    .io_in_1_bits_addr (io_in_2_1_1_bits_addr),
    .io_in_2_ready     (io_in_18_0_0_ready),
    .io_in_2_valid     (io_in_18_0_0_valid),
    .io_in_2_bits_addr (io_in_18_0_0_bits_addr),
    .io_out_valid      (io_out_3_valid),
    .io_out_bits_addr  (io_out_3_bits_addr)
  );
  // 读口 4：2 路竞争，优先级 IQ2.EXU0.src0 > IQ1.EXU1.src0
  WBArbiter_30 arbiters_4 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_2_0_0_ready),
    .io_in_0_valid     (io_in_2_0_0_valid),
    .io_in_0_bits_addr (io_in_2_0_0_bits_addr),
    .io_in_1_ready     (io_in_1_1_0_ready),
    .io_in_1_valid     (io_in_1_1_0_valid),
    .io_in_1_bits_addr (io_in_1_1_0_bits_addr),
    .io_out_valid      (io_out_4_valid),
    .io_out_bits_addr  (io_out_4_bits_addr)
  );
  // 读口 5：3 路竞争，优先级 IQ2.EXU0.src1 > IQ1.EXU1.src1 > IQ17.EXU0.src0
  WBArbiter_33 arbiters_5 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_2_0_1_ready),
    .io_in_0_valid     (io_in_2_0_1_valid),
    .io_in_0_bits_addr (io_in_2_0_1_bits_addr),
    .io_in_1_ready     (io_in_1_1_1_ready),
    .io_in_1_valid     (io_in_1_1_1_valid),
    .io_in_1_bits_addr (io_in_1_1_1_bits_addr),
    .io_in_2_ready     (io_in_17_0_0_ready),
    .io_in_2_valid     (io_in_17_0_0_valid),
    .io_in_2_bits_addr (io_in_17_0_0_bits_addr),
    .io_out_valid      (io_out_5_valid),
    .io_out_bits_addr  (io_out_5_bits_addr)
  );
  // 读口 6：3 路竞争，优先级 IQ3.EXU0.src0 > IQ0.EXU1.src0 > IQ11.EXU0.src0
  WBArbiter_33 arbiters_6 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_3_0_0_ready),
    .io_in_0_valid     (io_in_3_0_0_valid),
    .io_in_0_bits_addr (io_in_3_0_0_bits_addr),
    .io_in_1_ready     (io_in_0_1_0_ready),
    .io_in_1_valid     (io_in_0_1_0_valid),
    .io_in_1_bits_addr (io_in_0_1_0_bits_addr),
    .io_in_2_ready     (io_in_11_0_0_ready),
    .io_in_2_valid     (io_in_11_0_0_valid),
    .io_in_2_bits_addr (io_in_11_0_0_bits_addr),
    .io_out_valid      (io_out_6_valid),
    .io_out_bits_addr  (io_out_6_bits_addr)
  );
  // 读口 7：3 路竞争，优先级 IQ3.EXU0.src1 > IQ0.EXU1.src1 > IQ10.EXU0.src0
  WBArbiter_33 arbiters_7 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_3_0_1_ready),
    .io_in_0_valid     (io_in_3_0_1_valid),
    .io_in_0_bits_addr (io_in_3_0_1_bits_addr),
    .io_in_1_ready     (io_in_0_1_1_ready),
    .io_in_1_valid     (io_in_0_1_1_valid),
    .io_in_1_bits_addr (io_in_0_1_1_bits_addr),
    .io_in_2_ready     (io_in_10_0_0_ready),
    .io_in_2_valid     (io_in_10_0_0_valid),
    .io_in_2_bits_addr (io_in_10_0_0_bits_addr),
    .io_out_valid      (io_out_7_valid),
    .io_out_bits_addr  (io_out_7_bits_addr)
  );
  // 读口 8：只有 IQ12.EXU0.src0 一路，永不冲突
  WBArbiter_38 arbiters_8 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_12_0_0_ready),
    .io_in_0_valid     (io_in_12_0_0_valid),
    .io_in_0_bits_addr (io_in_12_0_0_bits_addr),
    .io_out_valid      (io_out_8_valid),
    .io_out_bits_addr  (io_out_8_bits_addr)
  );
  // 读口 9：只有 IQ13.EXU0.src0 一路，永不冲突
  WBArbiter_38 arbiters_9 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_13_0_0_ready),
    .io_in_0_valid     (io_in_13_0_0_valid),
    .io_in_0_bits_addr (io_in_13_0_0_bits_addr),
    .io_out_valid      (io_out_9_valid),
    .io_out_bits_addr  (io_out_9_bits_addr)
  );
  // 读口 10：只有 IQ14.EXU0.src0 一路，永不冲突
  WBArbiter_38 arbiters_10 (
    .clock             (clock),
    .reset             (reset),
    .io_in_0_ready     (io_in_14_0_0_ready),
    .io_in_0_valid     (io_in_14_0_0_valid),
    .io_in_0_bits_addr (io_in_14_0_0_bits_addr),
    .io_out_valid      (io_out_10_valid),
    .io_out_bits_addr  (io_out_10_bits_addr)
  );

  // 不经过本寄存器堆的输入（NoRD）：不参与任何仲裁，ready 恒 1
  assign io_in_16_0_4_ready = 1'b1;
  assign io_in_16_0_3_ready = 1'b1;
  assign io_in_16_0_2_ready = 1'b1;
  assign io_in_16_0_1_ready = 1'b1;
  assign io_in_16_0_0_ready = 1'b1;
  assign io_in_15_0_4_ready = 1'b1;
  assign io_in_15_0_3_ready = 1'b1;
  assign io_in_15_0_2_ready = 1'b1;
  assign io_in_15_0_1_ready = 1'b1;
  assign io_in_15_0_0_ready = 1'b1;
  assign io_in_9_0_4_ready = 1'b1;
  assign io_in_9_0_3_ready = 1'b1;
  assign io_in_9_0_2_ready = 1'b1;
  assign io_in_9_0_1_ready = 1'b1;
  assign io_in_9_0_0_ready = 1'b1;
  assign io_in_8_1_4_ready = 1'b1;
  assign io_in_8_1_3_ready = 1'b1;
  assign io_in_8_1_2_ready = 1'b1;
  assign io_in_8_1_1_ready = 1'b1;
  assign io_in_8_1_0_ready = 1'b1;
  assign io_in_8_0_4_ready = 1'b1;
  assign io_in_8_0_3_ready = 1'b1;
  assign io_in_8_0_2_ready = 1'b1;
  assign io_in_8_0_1_ready = 1'b1;
  assign io_in_8_0_0_ready = 1'b1;
  assign io_in_7_1_4_ready = 1'b1;
  assign io_in_7_1_3_ready = 1'b1;
  assign io_in_7_1_2_ready = 1'b1;
  assign io_in_7_1_1_ready = 1'b1;
  assign io_in_7_1_0_ready = 1'b1;
  assign io_in_7_0_4_ready = 1'b1;
  assign io_in_7_0_3_ready = 1'b1;
  assign io_in_7_0_2_ready = 1'b1;
  assign io_in_7_0_1_ready = 1'b1;
  assign io_in_7_0_0_ready = 1'b1;
  assign io_in_6_0_2_ready = 1'b1;
  assign io_in_6_0_1_ready = 1'b1;
  assign io_in_6_0_0_ready = 1'b1;
  assign io_in_5_1_1_ready = 1'b1;
  assign io_in_5_1_0_ready = 1'b1;
  assign io_in_5_0_2_ready = 1'b1;
  assign io_in_5_0_1_ready = 1'b1;
  assign io_in_5_0_0_ready = 1'b1;
  assign io_in_4_1_1_ready = 1'b1;
  assign io_in_4_1_0_ready = 1'b1;
  assign io_in_4_0_2_ready = 1'b1;
  assign io_in_4_0_1_ready = 1'b1;
  assign io_in_4_0_0_ready = 1'b1;
endmodule
// END GENERATED
