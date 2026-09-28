// IntRFWBCollideChecker.sv —— 整数寄存器堆写口的"撞口"仲裁：同一写口同拍只放一个写回者
// =============================================================================
// 在哪一层：DataPath 的 og0 级（发射后第 0 拍）。Chisel: backend/datapath/RFWBConflictChecker.scala
//   class IntRFWBCollideChecker extends RFWBCollideCheckerBase；golden: G1-canonical/golden-rtl/IntRFWBCollideChecker.sv。
//
// 机制：每个执行单元（EXU）的写回在配置期就被静态分到整数寄存器堆的某个写口（PregWB.port）
//   并带一个口内优先级（PregWB.priority）。多个 EXU 共用一个写口时，它们的 uop 可能在同一拍
//   发射、几拍后同拍写回 —— 为此在 og0 就先仲裁：每个写口 k 一个 WBArbiter（arbiters_k），
//   输入按 priority 升序接（in0 优先级最高）。
//     in.ready  = 该 uop 拿到了写口（或它本拍没请求）；拿不到的由 DataPath 在 og0 取消重发。
//     out_k.valid = 写口 k 本拍有赢家（io.out 只有 valid，bundle 不带任何字段）。
//   WBArbiter 自带反饥饿：某一路连续被拒 7 拍后该路被标"饿"，下一次请求优先放行（见 rtl/backend/WBArbiter.sv）。
//   不写整数寄存器堆的 EXU（NoWB）不经过任何仲裁器，ready 恒 1。
//
// 规模（KunminghuV2Config，golden 实测）：27 个输入（io_in_<iq>_<exu>：第 iq 个发射队列里第 exu 个
//   执行单元），8 个写口（每口竞争者数 3/4/2/1/2/1/1/1），12 个输入是 NoWB。
//
// 本层无寄存器、无组合逻辑，只有例化与常量；全部时序状态在 WBArbiter 里。WBArbiter 家族
// 已单独签核，这里以同名模块例化（UT/FM 两侧白盒：ref golden，impl 本仓重写件）。
// 下面 GENERATED 区由 scripts/gen_datapath_arb.py 从 golden 例化表解析产出：端口表逐行同 golden，
// 每个例化前一行注释写明"这个写口由谁竞争、优先级顺序"。
// =============================================================================
// BEGIN GENERATED(dp_arb) —— 由 scripts/gen_datapath_arb.py 从 golden 例化表产出，勿手改
module IntRFWBCollideChecker(
  input  clock,
  input  reset,
  output io_in_18_0_ready,
  input  io_in_18_0_valid,
  output io_in_17_0_ready,
  input  io_in_17_0_valid,
  output io_in_16_0_ready,
  input  io_in_16_0_valid,
  output io_in_15_0_ready,
  input  io_in_15_0_valid,
  output io_in_14_0_ready,
  input  io_in_14_0_valid,
  output io_in_13_0_ready,
  input  io_in_13_0_valid,
  output io_in_12_0_ready,
  input  io_in_12_0_valid,
  output io_in_11_0_ready,
  input  io_in_11_0_valid,
  output io_in_10_0_ready,
  input  io_in_10_0_valid,
  output io_in_9_0_ready,
  input  io_in_9_0_valid,
  output io_in_8_1_ready,
  input  io_in_8_1_valid,
  output io_in_8_0_ready,
  input  io_in_8_0_valid,
  output io_in_7_1_ready,
  input  io_in_7_1_valid,
  output io_in_7_0_ready,
  input  io_in_7_0_valid,
  output io_in_6_0_ready,
  input  io_in_6_0_valid,
  output io_in_5_1_ready,
  input  io_in_5_1_valid,
  output io_in_5_0_ready,
  input  io_in_5_0_valid,
  output io_in_4_1_ready,
  input  io_in_4_1_valid,
  output io_in_4_0_ready,
  input  io_in_4_0_valid,
  output io_in_3_1_ready,
  input  io_in_3_1_valid,
  output io_in_3_0_ready,
  input  io_in_3_0_valid,
  output io_in_2_1_ready,
  input  io_in_2_1_valid,
  output io_in_2_0_ready,
  input  io_in_2_0_valid,
  output io_in_1_1_ready,
  input  io_in_1_1_valid,
  output io_in_1_0_ready,
  input  io_in_1_0_valid,
  output io_in_0_1_ready,
  input  io_in_0_1_valid,
  output io_in_0_0_ready,
  input  io_in_0_0_valid,
  output io_out_0_valid,
  output io_out_1_valid,
  output io_out_2_valid,
  output io_out_3_valid,
  output io_out_4_valid,
  output io_out_5_valid,
  output io_out_6_valid,
  output io_out_7_valid
);

  // 写口 0：3 路竞争，优先级 IQ0.EXU0 > IQ0.EXU1 > IQ4.EXU0
  WBArbiter arbiters_0 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_0_0_ready),
    .io_in_0_valid (io_in_0_0_valid),
    .io_in_1_ready (io_in_0_1_ready),
    .io_in_1_valid (io_in_0_1_valid),
    .io_in_2_ready (io_in_4_0_ready),
    .io_in_2_valid (io_in_4_0_valid),
    .io_out_valid  (io_out_0_valid)
  );
  // 写口 1：4 路竞争，优先级 IQ1.EXU0 > IQ1.EXU1 > IQ7.EXU1 > IQ5.EXU0
  WBArbiter_1 arbiters_1 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_1_0_ready),
    .io_in_0_valid (io_in_1_0_valid),
    .io_in_1_ready (io_in_1_1_ready),
    .io_in_1_valid (io_in_1_1_valid),
    .io_in_2_ready (io_in_7_1_ready),
    .io_in_2_valid (io_in_7_1_valid),
    .io_in_3_ready (io_in_5_0_ready),
    .io_in_3_valid (io_in_5_0_valid),
    .io_out_valid  (io_out_1_valid)
  );
  // 写口 2：2 路竞争，优先级 IQ2.EXU0 > IQ6.EXU0
  WBArbiter_2 arbiters_2 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_2_0_ready),
    .io_in_0_valid (io_in_2_0_valid),
    .io_in_1_ready (io_in_6_0_ready),
    .io_in_1_valid (io_in_6_0_valid),
    .io_out_valid  (io_out_2_valid)
  );
  // 写口 3：只有 IQ3.EXU0 一路，永不冲突
  WBArbiter_3 arbiters_3 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_3_0_ready),
    .io_in_0_valid (io_in_3_0_valid),
    .io_out_valid  (io_out_3_valid)
  );
  // 写口 4：2 路竞争，优先级 IQ2.EXU1 > IQ3.EXU1
  WBArbiter_2 arbiters_4 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_2_1_ready),
    .io_in_0_valid (io_in_2_1_valid),
    .io_in_1_ready (io_in_3_1_ready),
    .io_in_1_valid (io_in_3_1_valid),
    .io_out_valid  (io_out_4_valid)
  );
  // 写口 5：只有 IQ12.EXU0 一路，永不冲突
  WBArbiter_3 arbiters_5 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_12_0_ready),
    .io_in_0_valid (io_in_12_0_valid),
    .io_out_valid  (io_out_5_valid)
  );
  // 写口 6：只有 IQ13.EXU0 一路，永不冲突
  WBArbiter_3 arbiters_6 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_13_0_ready),
    .io_in_0_valid (io_in_13_0_valid),
    .io_out_valid  (io_out_6_valid)
  );
  // 写口 7：只有 IQ14.EXU0 一路，永不冲突
  WBArbiter_3 arbiters_7 (
    .clock         (clock),
    .reset         (reset),
    .io_in_0_ready (io_in_14_0_ready),
    .io_in_0_valid (io_in_14_0_valid),
    .io_out_valid  (io_out_7_valid)
  );

  // 不经过本寄存器堆的输入（NoWB）：不参与任何仲裁，ready 恒 1
  assign io_in_18_0_ready = 1'b1;
  assign io_in_17_0_ready = 1'b1;
  assign io_in_16_0_ready = 1'b1;
  assign io_in_15_0_ready = 1'b1;
  assign io_in_11_0_ready = 1'b1;
  assign io_in_10_0_ready = 1'b1;
  assign io_in_9_0_ready = 1'b1;
  assign io_in_8_1_ready = 1'b1;
  assign io_in_8_0_ready = 1'b1;
  assign io_in_7_0_ready = 1'b1;
  assign io_in_5_1_ready = 1'b1;
  assign io_in_4_1_ready = 1'b1;
endmodule
// END GENERATED
