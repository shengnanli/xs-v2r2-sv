// =============================================================================
// IMSIC.sv —— per-hart 的 AIA 外部中断控制器（Incoming MSI Controller）
//
// 在哪一层：uncore，每个 hart 一个。上游 IMSICGateWay 把总线侧写进来的 MSI（{文件号, 中断号}）
//   同步到核时钟域；本件把它分发到 9 个中断文件（intFile 0=M、1=S、2..8=guest 1..7），
//   并把 CSR 侧的间接访问（*iselect/*ireg）、claim（读 *topei 时清 pending）按特权级与 vgein
//   路由到对应文件，再把各文件的读数据 / pending / topei 汇总给 NewCSR。
// 设计源：ChiselAIA/src/main/scala/IMSIC.scala class IMSIC（geilen=7，intFilesNum=9，privNum=3）。
//
// §1 特权级合法性与文件选择（纯组合）
//   illegal_priv：非虚拟化访问只允许 priv ∈ {M,S}；虚拟化访问只允许 priv=S 且 1 <= vgein <= 7。
//   selOH_r / selOH_w：按 {priv,virt} 选文件：M→0，S→1，VS→1+vgein（one-hot）。写路径还要求
//   wdata.valid 且 op != 0。注意 vgein 加 1 之后按 7 位算、再对 9 位 one-hot 截断（golden 如此）。
// §2 九个 IntFile 实例的输入
//   seteipnum.valid = 网关当拍的 valid | 它打一拍的副本（msi_valid_delayed，异步复位 0），
//   即每个 MSI 置位脉冲被拉宽成两拍；claim：文件 0/1 直接用 claims[0]/[1]，guest 文件 i 还要
//   vgein+1 == i（7 位比较）。
// §3 汇总
//   rdata：各文件的 rdata 先各自打一拍（intfile_rdata_d_*，无复位），再按位或——同一拍最多一个文件
//   被选中，其余读出 0。illegal 也打一拍：有 CSR 访问 且（任一文件报非法 | 写 op 非法 | 特权级非法）。
//   pendings 直通 9 位；topeis[0]/[1] 分别是 M/S 文件的 topei 按 AIA 格式 {0,id,0,id} 包装；
//   topeis[2] 按 vgein[2:0]-1 在 7 个 guest 文件里选（★只看 vgein 低 3 位、3 位减法回绕★，golden 如此）。
// 子模块：IMSICGateWay（本仓已签核）、IntFile ×9（本 lane 重写，同名白盒）。
// golden 对照：G1-canonical/golden-rtl/IMSIC.sv
// =============================================================================
module xs_IMSIC_core (
  input  logic        clock,
  input  logic        reset,
  // CSR 侧
  input  logic        addr_valid,
  input  logic [11:0] addr,
  input  logic        addr_virt,
  input  logic [1:0]  addr_priv,       // 0 U / 1 S / 2 H / 3 M
  input  logic [5:0]  vgein,
  input  logic        wdata_valid,
  input  logic [1:0]  wdata_op,
  input  logic [63:0] wdata_data,
  input  logic [2:0]  claims,          // M / S / VS
  output logic        rdata_valid,
  output logic [63:0] rdata,
  output logic        illegal,
  output logic [8:0]  pendings,
  output logic [31:0] topeis [3],
  // 总线侧 MSI
  input  logic        msiio_vld_req,
  input  logic [11:0] msiio_data,
  output logic        msiio_vld_ack
);
  localparam int N_FILE = 9;
  localparam logic [1:0] PRIV_S = 2'd1, PRIV_M = 2'd3;

  // ---- §1 特权级合法性与文件选择 ----
  logic        illegal_priv;
  logic [6:0]  vgein_ext;                // 7 位，防加 1 溢出
  logic [6:0]  guest_file;               // 1 + vgein
  logic [2:0]  pv;                       // {priv, virt}
  logic [8:0]  sel_oh;                   // 按 {priv,virt} 选出的文件（未加 valid 门控）
  logic [8:0]  sel_oh_r, sel_oh_w;

  assign vgein_ext  = {1'b0, vgein};
  assign guest_file = vgein_ext + 7'd1;
  assign pv         = {addr_priv, addr_virt};
  assign illegal_priv = addr_valid &
    (addr_virt ? ~((addr_priv == PRIV_S) & (|vgein) & (vgein_ext < 7'd8))
               : ~((addr_priv == PRIV_M) | (addr_priv == PRIV_S)));
  always_comb begin
    case (pv)
      {PRIV_M, 1'b0}: sel_oh = 9'd1;
      {PRIV_S, 1'b0}: sel_oh = 9'd2;
      {PRIV_S, 1'b1}: sel_oh = 9'd1 << guest_file;
      default:        sel_oh = 9'd0;
    endcase
  end
  assign sel_oh_r = (addr_valid & ~illegal_priv) ? sel_oh : 9'd0;
  assign sel_oh_w = (addr_valid & wdata_valid & (|wdata_op) & ~illegal_priv) ? sel_oh : 9'd0;

  // ---- §2 网关 + 九个中断文件 ----
  logic [7:0]  msi_id;
  logic [8:0]  msi_valid;
  logic [8:0]  msi_valid_delayed;
  IMSICGateWay imsicGateWay (
    .clock         (clock),
    .reset         (reset),
    .msiio_vld_req (msiio_vld_req),
    .msiio_data    (msiio_data),
    .msiio_vld_ack (msiio_vld_ack),
    .msi_data_o    (msi_id),
    .msi_valid_o   (msi_valid)
  );
  always_ff @(posedge clock or posedge reset) begin
    if (reset) msi_valid_delayed <= '0;
    else       msi_valid_delayed <= msi_valid;
  end

  logic        file_rdata_valid [N_FILE];
  logic [63:0] file_rdata       [N_FILE];
  logic        file_illegal     [N_FILE];
  logic [7:0]  file_topei       [N_FILE];
  logic        file_claim       [N_FILE];
  for (genvar i = 0; i < N_FILE; i++) begin : g_file
    if (i < 2) begin : g_claim_ms
      assign file_claim[i] = claims[i];
    end else begin : g_claim_vs
      assign file_claim[i] = claims[2] & (guest_file == 7'(i));
    end
    IntFile intFile (
      .clock                   (clock),
      .reset                   (reset),
      .fromCSR_seteipnum_valid (msi_valid[i] | msi_valid_delayed[i]),
      .fromCSR_seteipnum_bits  (msi_id),
      .fromCSR_addr_valid      (addr_valid & sel_oh_r[i]),
      .fromCSR_addr_bits       (addr),
      .fromCSR_wdata_valid     (wdata_valid & sel_oh_w[i]),
      .fromCSR_wdata_bits_op   (wdata_op),
      .fromCSR_wdata_bits_data (wdata_data),
      .fromCSR_claim           (file_claim[i]),
      .toCSR_rdata_valid       (file_rdata_valid[i]),
      .toCSR_rdata_bits        (file_rdata[i]),
      .toCSR_illegal           (file_illegal[i]),
      .toCSR_pending           (pendings[i]),
      .toCSR_topei             (file_topei[i]),
      .illegal_io_illegal_priv (illegal_priv)
    );
  end

  // ---- §3 汇总：读数据/非法各打一拍（无复位），按位或 ----
  logic        rdata_d_valid [N_FILE];
  logic [63:0] rdata_d_bits  [N_FILE];
  logic        illegal_d;
  logic        any_file_illegal;
  always_comb begin
    any_file_illegal = 1'b0;
    for (int i = 0; i < N_FILE; i++) any_file_illegal |= file_illegal[i];
  end
  always_ff @(posedge clock) begin
    for (int i = 0; i < N_FILE; i++) begin
      rdata_d_valid[i] <= file_rdata_valid[i];
      rdata_d_bits[i]  <= file_rdata[i];
    end
    illegal_d <= (addr_valid | wdata_valid)
               & (any_file_illegal | (wdata_valid & ~(|wdata_op)) | illegal_priv);
  end
  always_comb begin
    rdata_valid = 1'b0;
    rdata       = '0;
    for (int i = 0; i < N_FILE; i++) begin
      rdata_valid |= rdata_d_valid[i];
      rdata       |= rdata_d_bits[i];
    end
  end
  assign illegal = illegal_d;

  // topei 按 AIA *topei 格式包装：[26:16] 身份、[10:0] 优先级（等于身份），其余 0
  function automatic logic [31:0] wrap_topei(input logic [7:0] id);
    wrap_topei = {8'b0, id, 8'b0, id};
  endfunction
  logic [2:0] guest_sel;                 // 只看 vgein 低 3 位，减 1 回绕（golden 如此）
  logic [7:0] guest_topei;
  assign guest_sel = vgein[2:0] - 3'd1;
  always_comb begin
    guest_topei = '0;
    for (int g = 0; g < 7; g++)
      if (guest_sel == 3'(g)) guest_topei = file_topei[2 + g];
  end
  assign topeis[0] = wrap_topei(file_topei[0]);
  assign topeis[1] = wrap_topei(file_topei[1]);
  assign topeis[2] = wrap_topei(guest_topei);
endmodule

module IMSIC (
  input         clock,
  input         reset,
  output        toCSR_rdata_valid,
  output [63:0] toCSR_rdata_bits,
  output        toCSR_illegal,
  output [8:0]  toCSR_pendings,
  output [31:0] toCSR_topeis_0,
  output [31:0] toCSR_topeis_1,
  output [31:0] toCSR_topeis_2,
  input         fromCSR_addr_valid,
  input  [11:0] fromCSR_addr_bits_addr,
  input         fromCSR_addr_bits_virt,
  input  [1:0]  fromCSR_addr_bits_priv,
  input  [5:0]  fromCSR_vgein,
  input         fromCSR_wdata_valid,
  input  [1:0]  fromCSR_wdata_bits_op,
  input  [63:0] fromCSR_wdata_bits_data,
  input         fromCSR_claims_0,
  input         fromCSR_claims_1,
  input         fromCSR_claims_2,
  input         msiio_vld_req,
  input  [11:0] msiio_data,
  output        msiio_vld_ack
);
  logic [31:0] topeis [3];
  xs_IMSIC_core u_core (
    .clock         (clock),
    .reset         (reset),
    .addr_valid    (fromCSR_addr_valid),
    .addr          (fromCSR_addr_bits_addr),
    .addr_virt     (fromCSR_addr_bits_virt),
    .addr_priv     (fromCSR_addr_bits_priv),
    .vgein         (fromCSR_vgein),
    .wdata_valid   (fromCSR_wdata_valid),
    .wdata_op      (fromCSR_wdata_bits_op),
    .wdata_data    (fromCSR_wdata_bits_data),
    .claims        ({fromCSR_claims_2, fromCSR_claims_1, fromCSR_claims_0}),
    .rdata_valid   (toCSR_rdata_valid),
    .rdata         (toCSR_rdata_bits),
    .illegal       (toCSR_illegal),
    .pendings      (toCSR_pendings),
    .topeis        (topeis),
    .msiio_vld_req (msiio_vld_req),
    .msiio_data    (msiio_data),
    .msiio_vld_ack (msiio_vld_ack)
  );
  assign toCSR_topeis_0 = topeis[0];
  assign toCSR_topeis_1 = topeis[1];
  assign toCSR_topeis_2 = topeis[2];
endmodule
