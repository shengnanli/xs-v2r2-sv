// =============================================================================
// VcsrModule.sv —— 向量 CSR vcsr（vxsat 1 位 + vxrm 2 位），NewCSR unprivileged 叶
// 三个 CSR 地址共享这 3 位状态：vcsr 整字口（w_*，vxsat=[0]、vxrm=[2:1]）、
// vxsat 别名口（wAliasVxsat_*）、vxrm 别名口（wAliasVxrm_*）；
// robCommit_vxsat_* 是退休点的粘性累积置位，优先于软件写。
// 机制：vxsat 退休时 read-modify-write 置位；软件写两源同拍按位或合成；
//   vxrm 仅软件写一路来源，同拍两源同样或合成。rdata = {61'h0, vxrm, vxsat}。
// 复位域：★本模块没有 reset 端口、两个寄存器都不复位★（golden 的 always 只有
//   posedge clock）——照抄，不许自行加复位。
// wrapper（端口表与 u_core 连线）由 scripts/gen_csrctl_leaves5.py 生成，见文末 GENERATED 区。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_VcsrModule_core —— vxsat/vxrm 寄存器堆本体
// -----------------------------------------------------------------------------
module xs_VcsrModule_core (
  input  logic        clock,
  input  logic        csr_wen,           // vcsr 整字写使能
  input  logic [63:0] csr_wdata,         // 整字写数据：vxsat=[0]、vxrm=[2:1]
  input  logic        cmt_vxsat_valid,   // 退休点累积有效（粘性置位，优先于软件写）
  input  logic        cmt_vxsat_bits,
  input  logic        alias_vxsat_wen,   // vxsat 别名地址写
  input  logic [63:0] alias_vxsat_wdata,
  input  logic        alias_vxrm_wen,    // vxrm 别名地址写
  input  logic [63:0] alias_vxrm_wdata,
  output logic [63:0] rdata,             // 整字读：{61'h0, vxrm, vxsat}
  output logic        vxsat,             // 实时视图（给向量单元）
  output logic [1:0]  vxrm
);
  logic       vxsat_q;   // 向量定点饱和累积标志（无复位，照抄 golden）
  logic [1:0] vxrm_q;    // 向量定点舍入模式（无复位，照抄 golden）

  always_ff @(posedge clock) begin
    // vxsat：退休累积（粘性 OR）优先于软件写；两路软件写源同拍按位或合成
    if (cmt_vxsat_valid)
      vxsat_q <= vxsat_q | cmt_vxsat_bits;
    else if (csr_wen | alias_vxsat_wen)
      vxsat_q <= (alias_vxsat_wen & alias_vxsat_wdata[0]) | (csr_wen & csr_wdata[0]);
    // vxrm：没有退休来源，只有软件写（与 vxsat 分属两条独立的更新门，照抄 golden）
    if (csr_wen | alias_vxrm_wen)
      vxrm_q <= (alias_vxrm_wen ? alias_vxrm_wdata[1:0] : 2'h0)
              | (csr_wen        ? csr_wdata[2:1]         : 2'h0);
  end

  assign rdata = {61'h0, vxrm_q, vxsat_q};
  assign vxsat = vxsat_q;
  assign vxrm  = vxrm_q;
endmodule

// BEGIN GENERATED(csrctl5) —— 由 scripts/gen_csrctl_leaves5.py 从 golden 端口表产出，勿手改
module VcsrModule(
  input         clock,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         robCommit_vxsat_valid,
  input         robCommit_vxsat_bits,
  input         wAliasVxsat_wen,
  input  [63:0] wAliasVxsat_wdata,
  input         wAliasVxrm_wen,
  input  [63:0] wAliasVxrm_wdata,
  output        vxsat,
  output [1:0]  vxrm
);

  xs_VcsrModule_core u_core (
    .clock             (clock),
    .csr_wen           (w_wen),
    .csr_wdata         (w_wdata),
    .cmt_vxsat_valid   (robCommit_vxsat_valid),
    .cmt_vxsat_bits    (robCommit_vxsat_bits),
    .alias_vxsat_wen   (wAliasVxsat_wen),
    .alias_vxsat_wdata (wAliasVxsat_wdata),
    .alias_vxrm_wen    (wAliasVxrm_wen),
    .alias_vxrm_wdata  (wAliasVxrm_wdata),
    .rdata             (rdata),
    .vxsat             (vxsat),
    .vxrm              (vxrm)
  );
endmodule
// END GENERATED
