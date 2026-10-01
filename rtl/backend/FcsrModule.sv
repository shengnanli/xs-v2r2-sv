// =============================================================================
// FcsrModule.sv —— 浮点 CSR fcsr 寄存器堆（fflags 5 位 + frm 3 位），NewCSR unprivileged 叶
// 三个 CSR 地址共享这 8 位状态：fcsr 整字口（w_*）、fflags 别名口（wAliasFflags_*）、
// frm 别名口（wAliasFfm_*）；robCommit_fflags_* 是退休点的粘性累积置位，优先于软件写。
// 机制：fflags（[4]NV [3]DZ [2]OF [1]UF [0]NX）退休时 read-modify-write 置位；
//   软件写两源（整字/别名）同拍按位或合成；frm 仅软件写一路来源，同拍两源同样或合成。
//   rdata = {56'h0, frm, fflags}；fflags/frm 是实时视图，fflagsRdata/frmRdata 是别名读口。
// 复位域：8 位寄存器全部异步高有效清 0（对齐 golden 的 posedge clock or posedge reset）。
// wrapper（端口表与 u_core 连线）由 scripts/gen_csrctl_leaves5.py 生成，见文末 GENERATED 区。
// =============================================================================

// -----------------------------------------------------------------------------
// xs_FcsrModule_core —— fflags/frm 寄存器堆本体
// -----------------------------------------------------------------------------
module xs_FcsrModule_core (
  input  logic        clock,
  input  logic        reset,             // 异步、高有效
  input  logic        csr_wen,           // fcsr 整字写使能
  input  logic [63:0] csr_wdata,         // 整字写数据：fflags=[4:0]、frm=[7:5]
  input  logic        cmt_fflags_valid,  // 退休点累积有效（粘性置位，优先于软件写）
  input  logic [4:0]  cmt_fflags_bits,
  input  logic        alias_fflags_wen,  // fflags 别名地址写
  input  logic [63:0] alias_fflags_wdata,
  input  logic        alias_frm_wen,     // frm 别名地址写
  input  logic [63:0] alias_frm_wdata,
  output logic [63:0] rdata,             // 整字读：{56'h0, frm, fflags}
  output logic [4:0]  fflags,            // 实时视图（给 FPU）
  output logic [2:0]  frm,
  output logic [4:0]  fflags_rdata,      // fflags 别名地址的读数据
  output logic [2:0]  frm_rdata          // frm 别名地址的读数据
);
  // fflags 位布局（RISC-V 规范）：[0]NX 不精确 [1]UF 下溢 [2]OF 上溢 [3]DZ 除零 [4]NV 非法
  logic [4:0] fflags_q;
  logic [2:0] frm_q;

  // 两路软件写源同拍按位或合成（对应 golden 里每位 `alias_wen & adata | wen & wdata` 的形状）
  logic [4:0] sw_fflags;
  logic [2:0] sw_frm;
  assign sw_fflags = ({5{alias_fflags_wen}} & alias_fflags_wdata[4:0])
                   | ({5{csr_wen}}          & csr_wdata[4:0]);
  assign sw_frm    = (alias_frm_wen ? alias_frm_wdata[2:0] : 3'h0)
                   | (csr_wen       ? csr_wdata[7:5]       : 3'h0);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      fflags_q <= 5'h0;
      frm_q    <= 3'h0;
    end
    else begin
      // fflags：退休累积（粘性 OR）优先于软件写
      if (cmt_fflags_valid)
        fflags_q <= cmt_fflags_bits | fflags_q;
      else if (csr_wen | alias_fflags_wen)
        fflags_q <= sw_fflags;
      // frm：没有退休来源，只有软件写（与 fflags 分属两条独立的更新门，照抄 golden）
      if (csr_wen | alias_frm_wen)
        frm_q <= sw_frm;
    end
  end

  assign rdata        = {56'h0, frm_q, fflags_q};
  assign fflags       = fflags_q;
  assign frm          = frm_q;
  assign fflags_rdata = fflags_q;
  assign frm_rdata    = frm_q;
endmodule

// BEGIN GENERATED(csrctl5) —— 由 scripts/gen_csrctl_leaves5.py 从 golden 端口表产出，勿手改
module FcsrModule(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  input         robCommit_fflags_valid,
  input  [4:0]  robCommit_fflags_bits,
  input         wAliasFflags_wen,
  input  [63:0] wAliasFflags_wdata,
  input         wAliasFfm_wen,
  input  [63:0] wAliasFfm_wdata,
  output [4:0]  fflags,
  output [2:0]  frm,
  output [4:0]  fflagsRdata,
  output [2:0]  frmRdata
);

  xs_FcsrModule_core u_core (
    .clock              (clock),
    .reset              (reset),
    .csr_wen            (w_wen),
    .csr_wdata          (w_wdata),
    .cmt_fflags_valid   (robCommit_fflags_valid),
    .cmt_fflags_bits    (robCommit_fflags_bits),
    .alias_fflags_wen   (wAliasFflags_wen),
    .alias_fflags_wdata (wAliasFflags_wdata),
    .alias_frm_wen      (wAliasFfm_wen),
    .alias_frm_wdata    (wAliasFfm_wdata),
    .rdata              (rdata),
    .fflags             (fflags),
    .frm                (frm),
    .fflags_rdata       (fflagsRdata),
    .frm_rdata          (frmRdata)
  );
endmodule
// END GENERATED
