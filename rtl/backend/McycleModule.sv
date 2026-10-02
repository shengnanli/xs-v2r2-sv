// =============================================================================
// McycleModule.sv —— 机器周期计数器 mcycle（64 位），NewCSR machine 级叶
// 每拍自增 1；mcountinhibit_CY 置位时保持（调试/能耗场景下停表）；
// CSR 写口（w_*）优先级最高，软件可写入任意初值。
// 更新优先级：复位 > 软件写 > inhibit 保持 > 自增。inhibit 的「保持」在 golden
//   里是 `else if (mcountinhibit_CY) begin end` 空分支，这里等价为「!inhibit 才自增」。
// rdata 与 regOut_ALL 是同一路计数器的两个镜像读口。
// 复位域：计数器异步高有效清 0（对齐 golden 的 posedge clock or posedge reset）。
// wrapper（端口表与 u_core 连线）由 scripts/gen_csrctl_leaves5.py 生成，见文末 GENERATED 区。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_McycleModule_core —— 64 位周期计数器本体
// -----------------------------------------------------------------------------
module xs_McycleModule_core (
  input  logic        clock,
  input  logic        reset,        // 异步、高有效
  input  logic        csr_wen,      // CSR 软件写口（优先级高于计数）
  input  logic [63:0] csr_wdata,
  input  logic        inhibit,      // mcountinhibit.CY：置位时计数器保持
  output logic [63:0] value,        // 计数器整字读
  output logic [63:0] value_mirror  // 同一路值的镜像口
);
  logic [63:0] count_q;

  always_ff @(posedge clock or posedge reset) begin
    if (reset)         count_q <= 64'h0;
    else if (csr_wen)  count_q <= csr_wdata;
    else if (!inhibit) count_q <= count_q + 64'h1;
  end

  assign value        = count_q;
  assign value_mirror = count_q;
endmodule

// BEGIN GENERATED(csrctl5) —— 由 scripts/gen_csrctl_leaves5.py 从 golden 端口表产出，勿手改
module McycleModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [63:0] regOut_ALL,
  input         mcountinhibit_CY
);

  xs_McycleModule_core u_core (
    .clock        (clock),
    .reset        (reset),
    .csr_wen      (w_wen),
    .csr_wdata    (w_wdata),
    .inhibit      (mcountinhibit_CY),
    .value        (rdata),
    .value_mirror (regOut_ALL)
  );
endmodule
// END GENERATED
