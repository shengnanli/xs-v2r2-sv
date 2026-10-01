// =============================================================================
// MinstretModule.sv —— 机器退休指令计数器 minstret（64 位），NewCSR machine 级叶
// 每拍累加本拍退休的指令数（robCommit_instNum_bits，0..6 条）；mcountinhibit_IR
// 置位时保持；CSR 写口（w_*）优先级最高。
// 更新优先级：复位 > 软件写 > inhibit 保持 > 累加（与 McycleModule 同构，只是
//   增量从固定 1 换成退休指令数）。
// ★golden 端口表里没有 instNum.valid★：Chisel 源里累加条件写的是
//   `!inhibit && robCommit.instNum.valid`，但 valid 无效时 bits 恒 0（加 0 等价
//   于保持），firtool 把 valid 折叠掉了——以 golden 端口表为准，照抄。
// 复位域：计数器异步高有效清 0（对齐 golden 的 posedge clock or posedge reset）。
// wrapper（端口表与 u_core 连线）由 scripts/gen_csrctl_leaves5.py 生成，见文末 GENERATED 区。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_MinstretModule_core —— 64 位退休指令计数器本体
// -----------------------------------------------------------------------------
module xs_MinstretModule_core (
  input  logic        clock,
  input  logic        reset,        // 异步、高有效
  input  logic        csr_wen,      // CSR 软件写口（优先级高于计数）
  input  logic [63:0] csr_wdata,
  input  logic        inhibit,      // mcountinhibit.IR：置位时计数器保持
  input  logic [6:0]  retired_num,  // 本拍退休的指令数（无 valid 同伴，见文件头）
  output logic [63:0] value,        // 计数器整字读
  output logic [63:0] value_mirror  // 同一路值的镜像口
);
  logic [63:0] count_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)         count_q <= 64'h0;
    else if (csr_wen)  count_q <= csr_wdata;
    else if (!inhibit) count_q <= count_q + 64'(retired_num);
  end

  assign value        = count_q;
  assign value_mirror = count_q;
endmodule

// BEGIN GENERATED(csrctl5) —— 由 scripts/gen_csrctl_leaves5.py 从 golden 端口表产出，勿手改
module MinstretModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_IR,
  input  [6:0]  robCommit_instNum_bits
);

  xs_MinstretModule_core u_core (
    .clock        (clock),
    .reset        (reset),
    .csr_wen      (w_wen),
    .csr_wdata    (w_wdata),
    .inhibit      (mcountinhibit_IR),
    .retired_num  (robCommit_instNum_bits),
    .value        (rdata),
    .value_mirror (regOut_ALL)
  );
endmodule
// END GENERATED
