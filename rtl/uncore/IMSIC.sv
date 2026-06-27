// =============================================================================
//  IMSIC —— RISC-V AIA 消息中断控制器 (可读重写核 xs_IMSIC_core)
// -----------------------------------------------------------------------------
//  源自 ChiselAIA src/main/scala/IMSIC.scala (class IMSIC) 经 firtool 生成的
//  IMSIC.sv (450 行)。IMSIC (Incoming MSI Controller) 是核内接收 MSI(消息中断)
//  的控制器: 上游通过 msiio 投递 MSI, 写进对应「中断文件」(interrupt file) 的
//  eip 位; CPU 的 CSR 接口 (fromCSR/toCSR) 按特权态选中某个中断文件做读/写/claim。
//
//  本实例: 7 个中断文件 (intFilesNum=7), 映射为:
//    file 0  : M 模式      (priv=3, virt=0)
//    file 1  : HS/S 模式   (priv=1, virt=0)
//    file 2..6: VS 模式 5 个 guest (priv=1, virt=1, 由 vgein=1..5 选中)
//
//  ---------------------------------------------------------------------------
//  AIA 消息中断协议 (本核实现的全部行为):
//
//  1) 特权态合法性 illegal_priv:
//     仅当 fromCSR_addr_valid 时判定。访问的目标特权态由 {priv, virt} 决定:
//       virt=1 (VS): 合法要求 priv==1(S) 且 vgein∈[1,5] (1≤vgein<6);
//       virt=0     : 合法要求 priv==3(M) 或 priv==1(S/HS)。
//     不合法 ⇒ illegal_priv=1, 该拍不选中任何文件。
//
//  2) 中断文件选择 (one-hot):
//     pv = {priv, virt} (3 位)。读选择 intFilesSelOH_r (addr_valid 且合法时):
//       pv==6 (M)  → file0; pv==2 (S) → file1;
//       pv==3 (VS) → file (1 << (vgein+1)) 的 one-hot (vgein 1..5 → file 2..6);
//       其余 → 全 0。
//     写选择 intFilesSelOH_w: 同上, 但额外要求 wdata_valid 且写操作码非 0。
//
//  3) MSI 投递 (来自 IMSICGateWay):
//     IMSICGateWay 把上游 MSI 的目标文件号展开成 one-hot 写选通 msi_valid_o[6:0]
//     (单拍脉冲) + 源号 msi_data_o。本核把脉冲再打一拍 (msi_valid_delayed), 与本拍
//     脉冲相或后作为该文件的 seteipnum_valid (连续两拍有效, 容忍 IntFile 时序)。
//     源号 msi_data_o 广播给所有文件的 seteipnum_bits。
//
//  4) IntFile (黑盒子模块 ×7):
//     每个文件保存 eidelivery/eithreshold/eip/eie 等寄存器, 完成 seteipnum 置位、
//     CSR 读写、claim (取走最高优先级 eip)、并输出 topei(最高 pending 中断号)、
//     pending(是否有可投递中断)、rdata。本核例化 golden IntFile 作黑盒 (UT 编入真
//     实 IntFile, FM 视作黑盒), 自身只做选择/路由/聚合。
//     claim 路由: file0←claims_0, file1←claims_1, file2..6←claims_2 (VS 共享)。
//
//  5) 输出聚合:
//     rdata: 各文件 toCSR_rdata 先打一拍 (intfile_rdata_d), 再 OR 归约 (同一时刻
//            至多一个文件被选中, OR 即多路选择)。
//     illegal: (addr_valid|wdata_valid) & (任一文件 illegal | 写无效操作码 | illegal_priv)
//              打一拍输出 (toCSR_illegal_d)。
//     pendings: 7 个文件的 pending 位拼成 7 位向量。
//     topeis_0/1: file0/file1 的 topei (低 16 位与高 16 位各放一份, 见拼接)。
//     topeis_2  : 由 vgein-1 在 VS 文件 (2..6) 中选出对应 topei。
//
//  本核例化的子模块: xs_IMSICGateWay_core ×1 (复用已重写核), IntFile ×7 (黑盒)。
// =============================================================================
module xs_IMSIC_core
  import imsic_pkg::*;
(
  input  logic        clock,
  input  logic        reset,

  // ---- 输出到 CSR ----
  output logic        toCSR_rdata_valid,   // 读数据有效 (聚合, 打一拍)
  output logic [63:0] toCSR_rdata_bits,    // 读数据 (聚合)
  output logic        toCSR_illegal,       // 本次访问非法 (打一拍)
  output logic [6:0]  toCSR_pendings,      // 7 个文件各自是否有可投递中断
  output logic [31:0] toCSR_topeis_0,      // file0 (M) 的 topei
  output logic [31:0] toCSR_topeis_1,      // file1 (S) 的 topei
  output logic [31:0] toCSR_topeis_2,      // 当前 VS guest 的 topei

  // ---- 来自 CSR ----
  input  logic        fromCSR_addr_valid,
  input  logic [11:0] fromCSR_addr_bits_addr,
  input  logic        fromCSR_addr_bits_virt,
  input  logic [1:0]  fromCSR_addr_bits_priv,
  input  logic [5:0]  fromCSR_vgein,
  input  logic        fromCSR_wdata_valid,
  input  logic [1:0]  fromCSR_wdata_bits_op,
  input  logic [63:0] fromCSR_wdata_bits_data,
  input  logic        fromCSR_claims_0,
  input  logic        fromCSR_claims_1,
  input  logic        fromCSR_claims_2,

  // ---- MSI 投递总线 (上游 → IMSICGateWay) ----
  input  logic        msiio_vld_req,
  input  logic [10:0] msiio_data
);

  localparam int NF = IMSIC_INT_FILES_NUM;   // 7 个中断文件

  // ===========================================================================
  //  特权态合法性 illegal_priv
  // ---------------------------------------------------------------------------
  //  vgein7 = {1'b0, vgein} (7 位), 用于与文件号 (0..6) 比较 / 移位。
  //  virt=1(VS): 合法 = priv==1(S) 且 vgein!=0 且 vgein<6;
  //  virt=0    : 合法 = priv==3(M) 或 priv==1(S)。
  // ===========================================================================
  wire        priv_is_s = (fromCSR_addr_bits_priv == 2'h1);   // S/HS
  wire [6:0]  vgein7    = {1'b0, fromCSR_vgein};
  wire        illegal_priv =
    fromCSR_addr_valid
    & (fromCSR_addr_bits_virt
         ? ~(priv_is_s & (|fromCSR_vgein) & (vgein7 < 7'h6))
         : ~((&fromCSR_addr_bits_priv) | priv_is_s));

  // ===========================================================================
  //  中断文件选择 (读 / 写各一套 one-hot)
  // ---------------------------------------------------------------------------
  //  pv = {priv, virt}; VS 模式选 file (1<<(vgein+1)) 的低 7 位 one-hot。
  // ===========================================================================
  wire [2:0]   pv      = {fromCSR_addr_bits_priv, fromCSR_addr_bits_virt};
  // VS 模式 one-hot: 把 1 左移 (vgein+1) (用宽位移再截低 7 位, 与 golden 同构,
  // 避免 7 位移位在量大时的截断歧义)。
  wire [127:0] vs_oh_full = 128'h1 << 7'(vgein7 + 7'h1);
  wire [6:0]   vs_oh      = vs_oh_full[6:0];          // VS: file (vgein+1) 的 one-hot

  // 文件选择 (与 golden 三元链同构): pv==6→file0(M); pv==2→file1(S);
  // pv==3→vs_oh(VS); 其余→0。读/写各自的 gate 不同。
  wire [NF-1:0] file_sel_r =
      (pv == 3'h6) ? 7'h1
    : (pv == 3'h2) ? 7'h2
    : (pv == 3'h3) ? vs_oh
    :                7'h0;

  wire sel_gate_r = fromCSR_addr_valid & ~illegal_priv;
  wire sel_gate_w = fromCSR_addr_valid & fromCSR_wdata_valid
                    & (|fromCSR_wdata_bits_op) & ~illegal_priv;

  wire [NF-1:0] intFilesSelOH_r = sel_gate_r ? file_sel_r : '0;
  wire [NF-1:0] intFilesSelOH_w = sel_gate_w ? file_sel_r : '0;

  // ===========================================================================
  //  IMSICGateWay: MSI 入口握手 (黑盒子模块)
  // ---------------------------------------------------------------------------
  //  按 golden 同名例化 IMSICGateWay: UT 编入真实块 (已重写核, 行为一致逐拍可比),
  //  FM 视作黑盒 (ref/impl 两侧同名黑盒, 比对聚焦 IMSIC 自身路由/聚合逻辑)。
  // ===========================================================================
  wire [IMSIC_INT_SRC_WIDTH-1:0] gw_msi_data;   // MSI 源号
  wire [NF-1:0]                  gw_msi_valid;   // 各文件单拍写选通脉冲
  IMSICGateWay imsicGateWay (
    .clock         (clock),
    .reset         (reset),
    .msiio_vld_req (msiio_vld_req),
    .msiio_data    (msiio_data),
    .msi_data_o    (gw_msi_data),
    .msi_valid_o   (gw_msi_valid)
  );

  // MSI 写选通延迟一拍 (异步复位)，与本拍脉冲相或 ⇒ seteipnum 有效持续两拍。
  logic [NF-1:0] msi_valid_delayed;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) msi_valid_delayed <= '0;
    else       msi_valid_delayed <= gw_msi_valid;
  end

  // ===========================================================================
  //  IntFile ×7 (黑盒): claim 路由 file0←claims_0, file1←claims_1, 其余←claims_2
  // ===========================================================================
  wire          if_rdata_valid [NF];
  wire [63:0]   if_rdata_bits  [NF];
  wire          if_illegal     [NF];
  wire          if_pending     [NF];
  wire [7:0]    if_topei       [NF];

  // 每个文件的 claim 来源 (打包成向量, 按下标取):
  //   file0←claims_0, file1←claims_1, file2..6←claims_2 (VS 文件共享 claims_2)
  wire [NF-1:0] claim_vec = {fromCSR_claims_2, fromCSR_claims_2, fromCSR_claims_2,
                             fromCSR_claims_2, fromCSR_claims_2,
                             fromCSR_claims_1, fromCSR_claims_0};

  generate
    for (genvar f = 0; f < NF; f++) begin : g_intfile
      IntFile u_intFile (
        .clock                   (clock),
        .reset                   (reset),
        // seteipnum: 本拍脉冲 | 延迟一拍脉冲; 源号广播
        .fromCSR_seteipnum_valid (gw_msi_valid[f] | msi_valid_delayed[f]),
        .fromCSR_seteipnum_bits  (gw_msi_data),
        .fromCSR_addr_valid      (fromCSR_addr_valid & intFilesSelOH_r[f]),
        .fromCSR_addr_bits       (fromCSR_addr_bits_addr),
        .fromCSR_wdata_valid     (fromCSR_wdata_valid & intFilesSelOH_w[f]),
        .fromCSR_wdata_bits_op   (fromCSR_wdata_bits_op),
        .fromCSR_wdata_bits_data (fromCSR_wdata_bits_data),
        .fromCSR_claim           (claim_vec[f]),
        .toCSR_rdata_valid       (if_rdata_valid[f]),
        .toCSR_rdata_bits        (if_rdata_bits[f]),
        .toCSR_illegal           (if_illegal[f]),
        .toCSR_pending           (if_pending[f]),
        .toCSR_topei             (if_topei[f]),
        .illegal_io_illegal_priv (illegal_priv)
      );
    end
  endgenerate

  // ===========================================================================
  //  读数据聚合: 各文件 rdata 打一拍后 OR 归约
  // ===========================================================================
  logic        rdata_d_valid [NF];
  logic [63:0] rdata_d_bits  [NF];
  logic        illegal_d;

  always_ff @(posedge clock) begin
    for (int f = 0; f < NF; f++) begin
      rdata_d_valid[f] <= if_rdata_valid[f];
      rdata_d_bits[f]  <= if_rdata_bits[f];
    end
    // illegal: 有访问 (读或写) 且 (任一文件非法 | 写了无效操作码 | 特权非法)
    illegal_d <=
      (fromCSR_addr_valid | fromCSR_wdata_valid)
      & ( (|{if_illegal[6], if_illegal[5], if_illegal[4], if_illegal[3],
             if_illegal[2], if_illegal[1], if_illegal[0]})
          | (fromCSR_wdata_valid & ~(|fromCSR_wdata_bits_op))
          | illegal_priv );
  end

  // rdata 聚合 (同一时刻至多一个文件选中 ⇒ OR = 多路选择)。
  // 用连续赋值 (与 golden 的 assign 一致) 而非 always_comb, 避免双例化逐拍比对时
  // 「过程块 vs 连续赋值」在同一时间步的调度顺序差异 (功能等价, 仅消除 tb 采样竞态)。
  assign toCSR_rdata_valid =
    rdata_d_valid[0] | rdata_d_valid[1] | rdata_d_valid[2] | rdata_d_valid[3]
    | rdata_d_valid[4] | rdata_d_valid[5] | rdata_d_valid[6];
  assign toCSR_rdata_bits =
    rdata_d_bits[0] | rdata_d_bits[1] | rdata_d_bits[2] | rdata_d_bits[3]
    | rdata_d_bits[4] | rdata_d_bits[5] | rdata_d_bits[6];
  assign toCSR_illegal = illegal_d;

  // ===========================================================================
  //  pending 向量: 7 个文件各自的 pending 位
  // ===========================================================================
  assign toCSR_pendings =
    {if_pending[6], if_pending[5], if_pending[4], if_pending[3],
     if_pending[2], if_pending[1], if_pending[0]};

  // ===========================================================================
  //  topei 输出
  // ---------------------------------------------------------------------------
  //  topeis_0/1: file0/file1 的 topei, 复制到 [15:8] 与 [31:24]? 实为
  //              {8'h0, topei, 8'h0, topei}: 低 16 位 = {8'h0,topei}, 高 16 位同。
  //  topeis_2  : VS guest 选择, 索引 = vgein-1 (vgein∈1..5 → VS 文件 2..6)。
  // ===========================================================================
  wire [2:0] vs_idx = 3'(fromCSR_vgein[2:0] - 3'h1);   // 0..4 选 file2..6
  // vs_idx==k ⇒ 选 file (k+2) 的 topei (与 golden 同构: 各项相或多路选择)
  wire [7:0] topei_vs =
      (vs_idx == 3'h0 ? if_topei[2] : 8'h0)
    | (vs_idx == 3'h1 ? if_topei[3] : 8'h0)
    | (vs_idx == 3'h2 ? if_topei[4] : 8'h0)
    | (vs_idx == 3'h3 ? if_topei[5] : 8'h0)
    | (vs_idx == 3'h4 ? if_topei[6] : 8'h0);

  assign toCSR_topeis_0 = {8'h0, if_topei[0], 8'h0, if_topei[0]};
  assign toCSR_topeis_1 = {8'h0, if_topei[1], 8'h0, if_topei[1]};
  assign toCSR_topeis_2 = {8'h0, topei_vs,    8'h0, topei_vs};

endmodule
