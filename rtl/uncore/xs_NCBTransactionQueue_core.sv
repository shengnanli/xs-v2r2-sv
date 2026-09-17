// =============================================================================
// xs_NCBTransactionQueue_core.sv —— OpenNCB「事务队列」参数化可读核
//   (NCBTransactionQueue / NCBTransactionQueue_1 两个单态化变体共享核体)
// -----------------------------------------------------------------------------
// 设计源：openLLC/openNCB src/main/scala/openncb/logical/NCBTransactionQueue.scala
// golden 对照：G1-canonical/golden-rtl/{NCBTransactionQueue,NCBTransactionQueue_1}.sv
//
// ★ 它是什么 ★
// NCB = Non-Cacheable Bridge，把 CHI 上的**不可缓存**请求翻译成 AXI4。
// 本模块是这座桥的「记分板」：每个在飞事务占一个槽位，槽里存
//   ① op 位——这笔事务**还欠哪些动作**（CHI 侧要回的 Comp/DBIDResp/CompDBIDResp/
//     ReadReceipt/CompData，AXI 侧要发的 AW/W/B/AR/R），做完一件清一位；
//   ② info——CHI 事务身份（QoS/TgtID/SrcID/TxnID/…），回包时原样带回；
//   ③ operand——地址与拍数（CHI 侧 48 位地址、AXI 侧 49 位地址/Size/Len，两侧各自
//     的 Critical[2]/Count 记「关键字优先」的剩余节拍）；
//   ④ order——可选的**前序依赖**：本槽必须等到它记的那个槽释放后才准上总线。
// 五个上下游子块（RXREQ / RXDAT / TXRSP / TXDAT / AW-W-B-AR-R）各自用一组
// **per-entry one-hot strobe** 读写这张表，没有任何仲裁在本模块内——它是纯存储 +
// 组合读多路（ParallelMux = OR-of-AND，不是优先级选择）。
// 槽位的分配/回收由兄弟模块 NCBTransactionFreeList 做，本模块只输出 free_strb。
//
// ★ 释放语义 ★
//   free_strb[i] = valid[i] & 所有 CHI op 位为 0 & 所有 AXI op 位为 0
// 也就是「欠的都还完了」即自动释放。free 只是**组合输出**，同时反过来清 valid。
//
// ★ 更新优先级（逐条对着 golden 展开核过，见 §6/§7；同拍撞车的结果不是想当然的）★
//   valid          ：allocate **压过** free          （Chisel 先写 free 再写 allocate）
//   每个 op 位      ：清除源 **压过** allocate        （clear 写在 allocate 之后）
//   chi Critical/Cnt：TXDAT.operandWrite > allocate
//   axi Critical/Cnt：R.operandAXIWrite > W.operandWrite > allocate
//   order.valid     ：allocate 分支里现算；非 allocate 拍才看 free 清除
//
// ★ 两个变体不是「纯尺寸单态化」★（实测推翻了立项时的猜测，详见两个 wrapper 文件头）
//   除 64 项 / 32 项之外，还有三处**特性**差异，全部来自 Top.scala 的 NCBParameters：
//     axiMasterOrder      ：v0=WriteAddress → 有 order；v1=None → order 整片被 DCE
//     acceptMemAttrDevice ：v0=false → 无 Device 位；v1=true  → axi operand 多一位
//     readReceiptAfterAcception：v0=false → ReadReceipt 无 AXIARready 屏障（连
//                           downstreamAr.opDone 端口都没有）；v1=true → 有该屏障
//   所以核体带三个开关，wrapper 只设参数；开关关掉的部分连寄存器都不生成。
//
// ★ golden 里三处「看起来是 bug / 冗余」的地方，一律照抄并在原地注明 ★
//   (1) info.ReturnNID / ReturnTxnID 是**只写不读**的死寄存器（每槽 23 位）：
//       Chisel 里存了，但四个 infoRead 读口的 ParallelMux 只有 38 位
//       ({QoS,TgtID,SrcID,TxnID})，firtool 于是把这两个字段从读侧全消掉、
//       却把寄存器与输入端口留了下来。impl 必须同样留着（见 §7 注释）。
//   (2) upstreamTxRsp.operandRead 在 Chisel 里**用错了 strobe**（写成
//       io.upstreamTxDat.operandRead.strb）。golden 里这条读口只剩常数输出，
//       所以这个笔误不可观测；本核照 golden 给常数，见 §8。
//   (3) ReadRespErr / WriteRespErr 读口**恒 0**：writeNoError=true 让 B 通道的
//       WriteRespErr 写口被折没，readCompDMT=false 让 R 通道的 ReadRespErr 写口
//       也被折没 —— 两个字段既没有寄存器也没有写端口，读出来只能是 0。
// =============================================================================

// -----------------------------------------------------------------------------
// §1 家族公共常量。变体差异全部走 parameter，所以这个包很薄。
// -----------------------------------------------------------------------------
package ncb_txnq_pkg;

  // CHI 一个数据包最多 512 位，本配置 CHI flit 与 AXI4 数据线都是 256 位，
  // 于是上下游「最大节拍数」都是 2，Count 只要 1 位（log2Up(2)）。
  // 两个变体一致，故做成常量而不是 parameter。
  localparam int BEAT_N = 2;
  localparam int CNT_W  = 1;

  // CHI 事务身份字段宽度（KunminghuV2Config 下 CHI issue-E，从 golden 端口表量得）
  localparam int QOS_W        = 4;
  localparam int TGTID_W      = 11;
  localparam int SRCID_W      = 11;
  localparam int TXNID_W      = 12;
  localparam int RTNNID_W     = 11;
  localparam int RTNTXNID_W   = 12;
  // infoRead 读口实际输出的宽度：只有前四个字段被读（见文件头 (1)）。
  localparam int INFO_RD_W    = QOS_W + TGTID_W + SRCID_W + TXNID_W;  // 38

  localparam int CHI_ADDR_W   = 48;
  localparam int AXI_ADDR_W   = 49;
  localparam int AXI_SIZE_W   = 3;
  localparam int AXI_LEN_W    = 8;
  localparam int AXI_BURST_W  = 2;
  localparam int RESPERR_W    = 2;

  // axiBurstAlwaysIncr=true：Burst 字段在两个变体里都被折成常数 INCR，
  // 既没有寄存器也没有 allocate 输入端口。
  localparam logic [AXI_BURST_W-1:0] AXI_BURST_INCR = 2'b01;

  // allocate 口送进来的 op 位。★注意这里是 13 位而不是 14 位★：
  // ReadReceipt 的 AXIARready 屏障在两个变体里都**不是** allocate 输入
  // （v0 折成常数 0、v1 折成常数 1），所以它不在这个结构里，见 §7。
  typedef struct packed {
    logic chi_comp_valid;
    logic chi_comp_barrier_cancel_or_bresp;  // 等 CHI WriteDataCancel 或 AXI BRESP
    logic chi_dbidresp_valid;
    logic chi_compdbidresp_valid;
    logic chi_readreceipt_valid;
    logic chi_compdata_valid;
    logic chi_compdata_sep;                  // CompData 是否用 separate 形式
    logic axi_wa_valid;
    logic axi_wa_barrier_wbdata;             // 等 CHI 把写数据送齐
    logic axi_wd_valid;
    logic axi_wresp_valid;
    logic axi_ra_valid;
    logic axi_rd_valid;
  } ncb_op_t;

  // 事务身份。六个字段都存，但后两个没有读者（文件头 (1)）。
  typedef struct packed {
    logic [QOS_W-1:0]      qos;
    logic [TGTID_W-1:0]    tgt_id;
    logic [SRCID_W-1:0]    src_id;
    logic [TXNID_W-1:0]    txn_id;
    logic [RTNNID_W-1:0]   return_nid;
    logic [RTNTXNID_W-1:0] return_txn_id;
  } ncb_info_t;

  // 两个 bundle 的总位宽。★wrapper 不 import 本包★（包放在核文件里，跨文件共享包
  // 会制造文件顺序依赖，本仓 scripts/check_pkg_scope.py 判为违规），所以核的
  // allocate 端口收的是**扁平向量**，进来之后再 cast 回 struct —— 位序即下面
  // 两个 typedef 的字段顺序（先声明的在高位）。
  localparam int OP_W   = $bits(ncb_op_t);     // 13
  localparam int INFO_W = $bits(ncb_info_t);   // 61

endpackage : ncb_txnq_pkg

// =============================================================================
// §2 xs_NCBTransactionQueue_core —— 参数化核体
// =============================================================================
module xs_NCBTransactionQueue_core
  import ncb_txnq_pkg::*;
#(
  // 槽位数 = NCBParameters.outstandingDepth。v0=64，v1=32。
  parameter int N = 64,

  // axiMasterOrder != None 时才有前序依赖网络（v0=1，v1=0）。
  parameter bit HAS_ORDER = 1,

  // acceptMemAttrDevice 时 AXI operand 多存一位 Device，且只有 AR 读口读它
  // （AW 读口的 Device 在两个变体里都没有读者，被 firtool 消掉）。v0=0，v1=1。
  parameter bit HAS_DEVICE = 0,

  // readReceiptAfterAcception 时 ReadReceipt 要等 AXI ARREADY 才准回，
  // 于是多一位屏障寄存器 + 一组 downstreamAr.opDone strobe 输入。v0=0，v1=1。
  parameter bit HAS_AR_READY_BARRIER = 0,

  // 前序依赖索引位宽。order.index 取值域就是槽号，所以位宽必须与槽数精确匹配
  // （FM 的 FMR_ELAB-147：索引位宽与数组项数不等会让 set_top 失败）。
  localparam int IDX_W = (N <= 1) ? 1 : $clog2(N)
) (
  input  logic clock,
  // ★异步高有效复位★（golden 的 always @(posedge clock or posedge reset)）。
  // 只有 valid 与 op 位在复位域里；info/operand/order 一个都不复位，见 §7。
  input  logic reset,

  // --- 释放输出（给 NCBTransactionFreeList）-----------------------------------
  output logic [N-1:0]              free_strb,

  // --- 分配口（来自 RXREQ）----------------------------------------------------
  input  logic                      alloc_en,
  input  logic [N-1:0]              alloc_strb,
  input  logic [OP_W-1:0]           alloc_op_bits,     // 位序见 ncb_op_t
  input  logic [INFO_W-1:0]         alloc_info_bits,   // 位序见 ncb_info_t
  input  logic [CHI_ADDR_W-1:0]     alloc_chi_addr,
  input  logic                      alloc_chi_write_full,
  input  logic                      alloc_chi_write_ptl,
  input  logic [BEAT_N-1:0]         alloc_chi_critical,
  input  logic [CNT_W-1:0]          alloc_chi_count,
  input  logic [AXI_ADDR_W-1:0]     alloc_axi_addr,
  input  logic [AXI_SIZE_W-1:0]     alloc_axi_size,
  input  logic [AXI_LEN_W-1:0]      alloc_axi_len,
  input  logic                      alloc_axi_device,      // 仅 HAS_DEVICE 有效
  input  logic [BEAT_N-1:0]         alloc_axi_critical,
  input  logic [CNT_W-1:0]          alloc_axi_count,
  input  logic                      alloc_order_valid,     // 仅 HAS_ORDER 有效
  input  logic [IDX_W-1:0]          alloc_order_index,     // 仅 HAS_ORDER 有效

  // --- 上游 RXDAT（CHI 写数据通道）-------------------------------------------
  input  logic                      rxdat_query_en,
  input  logic [N-1:0]              rxdat_query_strb,
  output logic                      rxdat_query_valid,
  output logic                      rxdat_query_write_full,
  output logic                      rxdat_query_write_ptl,
  output logic [RESPERR_W-1:0]      rxdat_query_read_resp_err,   // 恒 0，见 §8
  output logic [RESPERR_W-1:0]      rxdat_query_write_resp_err,  // 恒 0，见 §8
  input  logic                      rxdat_cancel_en,
  input  logic [N-1:0]              rxdat_cancel_strb,
  input  logic                      rxdat_write_data_en,
  input  logic [N-1:0]              rxdat_write_data_strb,

  // --- 上游 TXRSP（CHI 响应通道）---------------------------------------------
  output logic [N-1:0]              txrsp_op_valid,
  input  logic [N-1:0]              txrsp_op_read_strb,
  output logic                      txrsp_op_read_comp,
  output logic                      txrsp_op_read_dbidresp,
  output logic                      txrsp_op_read_compdbidresp,
  output logic                      txrsp_op_read_readreceipt,
  input  logic [N-1:0]              txrsp_op_done_strb,
  input  logic                      txrsp_op_done_comp,
  input  logic                      txrsp_op_done_dbidresp,
  input  logic                      txrsp_op_done_compdbidresp,
  input  logic                      txrsp_op_done_readreceipt,
  input  logic [N-1:0]              txrsp_info_read_strb,
  output logic [INFO_RD_W-1:0]      txrsp_info_read_bits,
  output logic [RESPERR_W-1:0]      txrsp_operand_write_resp_err,  // 恒 0，见 §8

  // --- 上游 TXDAT（CHI 数据通道）---------------------------------------------
  output logic [N-1:0]              txdat_op_valid,
  output logic [N-1:0][BEAT_N-1:0]  txdat_op_valid_critical,
  input  logic [N-1:0]              txdat_op_read_strb,
  output logic                      txdat_op_read_compdata_valid,
  output logic                      txdat_op_read_compdata_sep,
  input  logic [N-1:0]              txdat_op_done_strb,
  input  logic                      txdat_op_done_compdata,
  input  logic [N-1:0]              txdat_info_read_strb,
  output logic [INFO_RD_W-1:0]      txdat_info_read_bits,
  input  logic [N-1:0]              txdat_operand_read_strb,
  output logic [CHI_ADDR_W-1:0]     txdat_operand_read_addr,
  output logic [RESPERR_W-1:0]      txdat_operand_read_read_resp_err,  // 恒 0，见 §8
  output logic [BEAT_N-1:0]         txdat_operand_read_critical,
  output logic [CNT_W-1:0]          txdat_operand_read_count,
  input  logic [N-1:0]              txdat_operand_write_strb,
  input  logic [BEAT_N-1:0]         txdat_operand_write_critical,
  input  logic [CNT_W-1:0]          txdat_operand_write_count,

  // --- 下游 AXI AW -----------------------------------------------------------
  output logic [N-1:0]              aw_op_valid,
  input  logic [N-1:0]              aw_op_ponr_strb,
  input  logic [N-1:0]              aw_info_read_strb,
  output logic [QOS_W-1:0]          aw_info_read_qos,
  input  logic [N-1:0]              aw_operand_read_strb,
  output logic [AXI_ADDR_W-1:0]     aw_operand_read_addr,
  output logic [AXI_BURST_W-1:0]    aw_operand_read_burst,
  output logic [AXI_SIZE_W-1:0]     aw_operand_read_size,
  output logic [AXI_LEN_W-1:0]      aw_operand_read_len,

  // --- 下游 AXI W ------------------------------------------------------------
  input  logic [N-1:0]              w_op_ponr_strb,
  input  logic [N-1:0]              w_operand_read_strb,
  output logic [BEAT_N-1:0]         w_operand_read_critical,
  output logic [CNT_W-1:0]          w_operand_read_count,
  input  logic [N-1:0]              w_operand_write_strb,
  input  logic [BEAT_N-1:0]         w_operand_write_critical,
  input  logic [CNT_W-1:0]          w_operand_write_count,

  // --- 下游 AXI B ------------------------------------------------------------
  input  logic [N-1:0]              b_op_done_strb,

  // --- 下游 AXI AR -----------------------------------------------------------
  output logic [N-1:0]              ar_op_valid,
  input  logic [N-1:0]              ar_op_ponr_strb,
  input  logic [N-1:0]              ar_op_done_strb,      // 仅 HAS_AR_READY_BARRIER 有效
  input  logic [N-1:0]              ar_info_read_strb,
  output logic [QOS_W-1:0]          ar_info_read_qos,
  input  logic [N-1:0]              ar_operand_read_strb,
  output logic [AXI_ADDR_W-1:0]     ar_operand_read_addr,
  output logic [AXI_BURST_W-1:0]    ar_operand_read_burst,
  output logic [AXI_SIZE_W-1:0]     ar_operand_read_size,
  output logic [AXI_LEN_W-1:0]      ar_operand_read_len,
  output logic                      ar_operand_read_device,   // 仅 HAS_DEVICE 有效

  // --- 下游 AXI R ------------------------------------------------------------
  input  logic [N-1:0]              r_op_done_strb,
  input  logic [N-1:0]              r_operand_read_strb,
  output logic [BEAT_N-1:0]         r_operand_read_critical,
  output logic [CNT_W-1:0]          r_operand_read_count,
  input  logic [N-1:0]              r_operand_axi_write_strb,
  input  logic [BEAT_N-1:0]         r_operand_axi_write_critical,
  input  logic [CNT_W-1:0]          r_operand_axi_write_count,

  // --- debug（golden 把两条断言的条件也引成了真端口）--------------------------
  output logic [N-1:0]              dbg_double_allocation,
  output logic [N-1:0]              dbg_dangling_axi_write_response
);

  // ===========================================================================
  // §3 队列寄存器
  // ---------------------------------------------------------------------------
  // 按「谁写它」分三组，与 golden 的两个 always 块一一对应：
  //   组 A（异步复位域）：valid + 13/14 个 op 位 —— 每个都有独立清除源
  //   组 B（**无复位**）：info / chi_addr / axi_addr,size,len[,device] / order
  //   组 C（**无复位**）：chi Critical+Count、axi Critical+Count —— 多写口有优先级
  // ★复位域是逐个数 golden 复位臂得到的★：golden 的复位臂里**只有** valid 与 op 位
  // （v0 每槽 14 条、v1 每槽 15 条），info/operand/order 一条都没有。照抄成全复位
  // 会是真 bug（上电前几拍的读口行为不同）。
  // ===========================================================================
  logic     [N-1:0]              entry_valid_q;
  // op 位逐个用独立的 N 位向量存，而不是「struct 数组」——这样每条更新式子、
  // 每个读口都能直接对整列做位运算，读起来就是 golden 里那 13 组同名寄存器。
  logic     [N-1:0]              op_comp_valid_q;
  logic     [N-1:0]              op_comp_barrier_q;      // CHICancelOrAXIBresp
  logic     [N-1:0]              op_dbidresp_valid_q;
  logic     [N-1:0]              op_compdbidresp_valid_q;
  logic     [N-1:0]              op_readreceipt_valid_q;
  logic     [N-1:0]              op_compdata_valid_q;
  logic     [N-1:0]              op_compdata_sep_q;
  logic     [N-1:0]              op_wa_valid_q;
  logic     [N-1:0]              op_wa_barrier_q;        // CHIWriteBackData
  logic     [N-1:0]              op_wd_valid_q;
  logic     [N-1:0]              op_wresp_valid_q;
  logic     [N-1:0]              op_ra_valid_q;
  logic     [N-1:0]              op_rd_valid_q;
  ncb_info_t[N-1:0]              info_q;
  logic     [N-1:0][CHI_ADDR_W-1:0] chi_addr_q;
  logic     [N-1:0]              chi_write_full_q;
  logic     [N-1:0]              chi_write_ptl_q;
  logic     [N-1:0][BEAT_N-1:0]  chi_critical_q;
  logic     [N-1:0][CNT_W-1:0]   chi_count_q;
  logic     [N-1:0][AXI_ADDR_W-1:0] axi_addr_q;
  logic     [N-1:0][AXI_SIZE_W-1:0] axi_size_q;
  logic     [N-1:0][AXI_LEN_W-1:0]  axi_len_q;
  logic     [N-1:0][BEAT_N-1:0]  axi_critical_q;
  logic     [N-1:0][CNT_W-1:0]   axi_count_q;
  // 下面三组只在对应开关打开时才**被赋值**（因而才被推断成寄存器）。
  logic     [N-1:0]              axi_device_q;         // HAS_DEVICE
  logic     [N-1:0]              rr_barrier_q;         // HAS_AR_READY_BARRIER
  logic     [N-1:0]              order_valid_q;        // HAS_ORDER
  logic     [N-1:0][IDX_W-1:0]   order_index_q;        // HAS_ORDER

  // ===========================================================================
  // §4 每槽的事件译码
  // ---------------------------------------------------------------------------
  // 上下游子块给的都是 per-entry strobe；带 en 的那几路要先与 en 相与。
  // ===========================================================================
  // allocate 口进来的扁平向量在这里 cast 回 struct，后面一律按字段名读。
  ncb_op_t   alloc_op;
  ncb_info_t alloc_info;
  assign alloc_op   = ncb_op_t'(alloc_op_bits);
  assign alloc_info = ncb_info_t'(alloc_info_bits);

  logic [N-1:0] alloc_hit;      // 本拍分配到第 i 槽
  logic [N-1:0] cancel_hit;     // CHI WriteDataCancel 撤销第 i 槽的写
  logic [N-1:0] wdata_hit;      // CHI NonCopyBackWrData 把写数据送齐

  assign alloc_hit  = {N{alloc_en}}             & alloc_strb;
  assign cancel_hit = {N{rxdat_cancel_en}}      & rxdat_cancel_strb;
  assign wdata_hit  = {N{rxdat_write_data_en}}  & rxdat_write_data_strb;

  // ===========================================================================
  // §5 释放逻辑
  // ---------------------------------------------------------------------------
  // 「欠的都还完了」= valid 且 5 个 CHI op 位与 5 个 AXI op 位全 0。
  // ★注意用的是原始 valid 位而不是带屏障的 ready★：一个还挂着屏障的 op 同样算「欠着」。
  // ===========================================================================
  always_comb begin
    for (int i = 0; i < N; i++)
      free_strb[i] = entry_valid_q[i]
                   & ~(op_comp_valid_q[i]         | op_dbidresp_valid_q[i]
                     | op_compdbidresp_valid_q[i] | op_readreceipt_valid_q[i]
                     | op_compdata_valid_q[i])
                   & ~(op_wa_valid_q[i]    | op_wd_valid_q[i]
                     | op_wresp_valid_q[i] | op_ra_valid_q[i]
                     | op_rd_valid_q[i]);
  end

  // ===========================================================================
  // §6 前序依赖网络（axiMasterOrder != None 时才存在）
  // ---------------------------------------------------------------------------
  // 语义：槽 i 记着「我要等槽 order_index[i] 先走完」。被等的那一槽一旦释放，
  // 依赖就解除（order_valid 清 0），槽 i 才准往 TXRSP/TXDAT/AW/AR 上冒泡。
  // 这是一张 N×N 的比较阵列（v0 里 64×63 项），也是 golden 30k 行里最大的一块膨胀。
  //
  // 两个命中信号的差别只在「拿谁的 index 去比」：
  //   alloc_order_hit[i]：拿**本拍分配请求**带来的 index —— 如果被依赖的槽正在本拍
  //       释放，那这条依赖一出生就该作废，于是 order_valid 直接写 0；
  //   free_order_hit[i] ：拿**已存**的 index —— 正常的解除路径。
  // 两者都排除 j == i（自己不会依赖自己）。
  // ===========================================================================
  logic [N-1:0] alloc_order_hit;
  logic [N-1:0] free_order_hit;
  logic [N-1:0] order_blocks;   // 该槽当前被前序依赖挡住

  if (HAS_ORDER) begin : g_order
    logic [N-1:0] alloc_order_ordinal;   // 分配请求的 index 的 one-hot 译码

    always_comb begin
      for (int j = 0; j < N; j++)
        alloc_order_ordinal[j] = (alloc_order_index == IDX_W'(j));

      for (int i = 0; i < N; i++) begin
        alloc_order_hit[i] = 1'b0;
        free_order_hit[i]  = 1'b0;
        for (int j = 0; j < N; j++) begin
          if (i != j) begin
            alloc_order_hit[i] |= free_strb[j] & alloc_order_ordinal[j];
            free_order_hit[i]  |= free_strb[j] & (order_index_q[i] == IDX_W'(j));
          end
        end
      end
    end

    assign order_blocks = order_valid_q;

    // 组 B 里属于 order 的两个字段（无复位）
    always_ff @(posedge clock) begin
      for (int i = 0; i < N; i++) begin
        if (alloc_hit[i]) begin
          order_index_q[i] <= alloc_order_index;
          order_valid_q[i] <= ~alloc_order_hit[i] & alloc_order_valid;
        end else begin
          // ★只有在**没有**分配的拍才看 free 清除★ —— golden 是 if/else，
          // 不是两条独立的 when。分配拍上 order_valid 完全由上面那行决定。
          order_valid_q[i] <= ~free_order_hit[i] & order_valid_q[i];
        end
      end
    end
  end else begin : g_no_order
    // axiMasterOrder=None：RXREQ 把 order.valid 钉成常数 0，firtool 于是把整片
    // 依赖网络、两个 order 寄存器、两个 allocate 端口全部消掉。
    assign alloc_order_hit = '0;
    assign free_order_hit  = '0;
    assign order_blocks    = '0;
  end

  // ===========================================================================
  // §7 状态更新
  // ===========================================================================

  // --- 组 A：valid + op 位（★异步复位，全部复位到 0★）------------------------
  //
  // 每个 op 位的形状都是   次态 = ~清除源 & (分配 ? 分配值 : 现值)
  // ——★清除压过分配★。同一拍既分配又收到 done 时，这一位**不会**被置起。
  // 这是 Chisel 里 allocate 的 when 块写在所有 clear 之前造成的，且可观测。
  //
  // valid 的形状相反：  次态 = 分配 | (~释放 & 现值)  ——★分配压过释放★。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      entry_valid_q           <= '0;
      op_comp_valid_q         <= '0;
      op_comp_barrier_q       <= '0;
      op_dbidresp_valid_q     <= '0;
      op_compdbidresp_valid_q <= '0;
      op_readreceipt_valid_q  <= '0;
      op_compdata_valid_q     <= '0;
      op_compdata_sep_q       <= '0;
      op_wa_valid_q           <= '0;
      op_wa_barrier_q         <= '0;
      op_wd_valid_q           <= '0;
      op_wresp_valid_q        <= '0;
      op_ra_valid_q           <= '0;
      op_rd_valid_q           <= '0;
    end else begin
      for (int i = 0; i < N; i++) begin
        entry_valid_q[i] <= alloc_hit[i] | (~free_strb[i] & entry_valid_q[i]);

        // CHI 侧 ------------------------------------------------------------
        op_comp_valid_q[i] <=
            ~(txrsp_op_done_strb[i] & txrsp_op_done_comp)
          & (alloc_hit[i] ? alloc_op.chi_comp_valid : op_comp_valid_q[i]);

        // Comp 的屏障：CHI 侧撤销写、或 AXI 侧 BRESP 回来，都算「可以回 Comp 了」
        op_comp_barrier_q[i] <=
            ~(b_op_done_strb[i] | cancel_hit[i])
          & (alloc_hit[i] ? alloc_op.chi_comp_barrier_cancel_or_bresp
                          : op_comp_barrier_q[i]);

        op_dbidresp_valid_q[i] <=
            ~(txrsp_op_done_strb[i] & txrsp_op_done_dbidresp)
          & (alloc_hit[i] ? alloc_op.chi_dbidresp_valid : op_dbidresp_valid_q[i]);

        op_compdbidresp_valid_q[i] <=
            ~(txrsp_op_done_strb[i] & txrsp_op_done_compdbidresp)
          & (alloc_hit[i] ? alloc_op.chi_compdbidresp_valid
                          : op_compdbidresp_valid_q[i]);

        op_readreceipt_valid_q[i] <=
            ~(txrsp_op_done_strb[i] & txrsp_op_done_readreceipt)
          & (alloc_hit[i] ? alloc_op.chi_readreceipt_valid
                          : op_readreceipt_valid_q[i]);

        // CompData 的清除多一个条件：只有**最后一拍**（Count 归 0）才算做完。
        op_compdata_valid_q[i] <=
            ~(txdat_op_done_strb[i] & txdat_op_done_compdata & (chi_count_q[i] == '0))
          & (alloc_hit[i] ? alloc_op.chi_compdata_valid : op_compdata_valid_q[i]);

        // sep 只有分配一个写源，没有清除源（golden 是裸 if，没有 else）。
        if (alloc_hit[i])
          op_compdata_sep_q[i] <= alloc_op.chi_compdata_sep;

        // AXI 侧 ------------------------------------------------------------
        // WriteDataCancel 会把三个写任务一起撤掉（AW/W/B）。
        op_wa_valid_q[i] <=
            ~(aw_op_ponr_strb[i] | cancel_hit[i])
          & (alloc_hit[i] ? alloc_op.axi_wa_valid : op_wa_valid_q[i]);

        op_wa_barrier_q[i] <=
            ~wdata_hit[i]
          & (alloc_hit[i] ? alloc_op.axi_wa_barrier_wbdata : op_wa_barrier_q[i]);

        op_wd_valid_q[i] <=
            ~(w_op_ponr_strb[i] | cancel_hit[i])
          & (alloc_hit[i] ? alloc_op.axi_wd_valid : op_wd_valid_q[i]);

        op_wresp_valid_q[i] <=
            ~(b_op_done_strb[i] | cancel_hit[i])
          & (alloc_hit[i] ? alloc_op.axi_wresp_valid : op_wresp_valid_q[i]);

        op_ra_valid_q[i] <=
            ~ar_op_ponr_strb[i]
          & (alloc_hit[i] ? alloc_op.axi_ra_valid : op_ra_valid_q[i]);

        op_rd_valid_q[i] <=
            ~r_op_done_strb[i]
          & (alloc_hit[i] ? alloc_op.axi_rd_valid : op_rd_valid_q[i]);
      end
    end
  end

  // ReadReceipt 的 AXIARready 屏障：也在异步复位域里（golden v1 的复位臂第 7 条）。
  // ★分配值是常数 1 而不是端口★：readReceiptAfterAcception=true 让 RXREQ 恒送 1，
  // firtool 于是把这个 allocate 输入折没了，只剩 `alloc | 现值`。
  logic [N-1:0] rr_ready;   // ReadReceipt 这一步现在可以做了吗
  if (HAS_AR_READY_BARRIER) begin : g_ar_barrier
    always_ff @(posedge clock or posedge reset) begin
      if (reset)
        rr_barrier_q <= '0;
      else
        for (int i = 0; i < N; i++)
          rr_barrier_q[i] <= ~ar_op_done_strb[i] & (alloc_hit[i] | rr_barrier_q[i]);
    end
    assign rr_ready = op_readreceipt_valid_q & ~rr_barrier_q;
  end else begin : g_no_ar_barrier
    // readReceiptAfterAcception=false：屏障恒 0，连 downstreamAr.opDone 端口都不存在。
    assign rr_ready = op_readreceipt_valid_q;
  end

  // --- 组 B：分配才写的载荷（★无复位★）--------------------------------------
  always_ff @(posedge clock) begin
    for (int i = 0; i < N; i++) begin
      if (alloc_hit[i]) begin
        // ★info 的后两个字段 return_nid / return_txn_id 在 golden 里是只写不读的
        //   死寄存器（每槽 23 位、全队 64×23=1472 位）。这里照抄结构，不合并也不删：
        //   删了 FM 会多出一堆 unmatched；合并了就不是同一个结构。
        info_q[i]           <= alloc_info;
        chi_addr_q[i]       <= alloc_chi_addr;
        chi_write_full_q[i] <= alloc_chi_write_full;
        chi_write_ptl_q[i]  <= alloc_chi_write_ptl;
        axi_addr_q[i]       <= alloc_axi_addr;
        axi_size_q[i]       <= alloc_axi_size;
        axi_len_q[i]        <= alloc_axi_len;
      end
    end
  end

  if (HAS_DEVICE) begin : g_device
    always_ff @(posedge clock) begin
      for (int i = 0; i < N; i++)
        if (alloc_hit[i]) axi_device_q[i] <= alloc_axi_device;
    end
    assign ar_operand_read_device = |(ar_operand_read_strb & axi_device_q);
  end else begin : g_no_device
    // acceptMemAttrDevice=false：Device 恒 0，寄存器与两个端口都被消掉。
    assign ar_operand_read_device = 1'b0;
  end

  // --- 组 C：多写口的 Critical/Count（★无复位★）------------------------------
  // Critical[b] = 「第 b 拍是关键字」，Count = 剩余拍数。上下游各自维护一份。
  //
  // ★优先级逐条对着 golden 的 if/else-if 链核过★：
  //   CHI 侧：TXDAT.operandWrite  >  allocate
  //   AXI 侧：R.operandAXIWrite   >  W.operandWrite  >  allocate
  // Chisel 里这几条是并列的 when，优先级来自**书写顺序**（后写者胜），
  // 不是任何显式的 prio 参数。
  always_ff @(posedge clock) begin
    for (int i = 0; i < N; i++) begin
      if (txdat_operand_write_strb[i]) begin
        chi_critical_q[i] <= txdat_operand_write_critical;
        chi_count_q[i]    <= txdat_operand_write_count;
      end else if (alloc_hit[i]) begin
        chi_critical_q[i] <= alloc_chi_critical;
        chi_count_q[i]    <= alloc_chi_count;
      end

      if (r_operand_axi_write_strb[i]) begin
        axi_critical_q[i] <= r_operand_axi_write_critical;
        axi_count_q[i]    <= r_operand_axi_write_count;
      end else if (w_operand_write_strb[i]) begin
        axi_critical_q[i] <= w_operand_write_critical;
        axi_count_q[i]    <= w_operand_write_count;
      end else if (alloc_hit[i]) begin
        axi_critical_q[i] <= alloc_axi_critical;
        axi_count_q[i]    <= alloc_axi_count;
      end
    end
  end

  // ===========================================================================
  // §8 读口
  // ---------------------------------------------------------------------------
  // 全部是 Chisel 的 ParallelMux = OR-of-AND 的**一热多路**，不是优先级选择：
  //     out = OR_i ( strb[i] ? field[i] : 0 )
  // 于是 strb 多热时读出的是**按位或**、全 0 时读出 0。这一点是可观测的，
  // UT 必须专门打多热/全零的激励（真实上游只会给一热，但 FM 会比全空间）。
  // ===========================================================================

  // --- RXDAT query：整条结果再被 query_en 门控一次（ValidMux）-----------------
  assign rxdat_query_valid      = rxdat_query_en & (|(rxdat_query_strb & entry_valid_q));
  assign rxdat_query_write_full = rxdat_query_en & (|(rxdat_query_strb & chi_write_full_q));
  assign rxdat_query_write_ptl  = rxdat_query_en & (|(rxdat_query_strb & chi_write_ptl_q));
  // ★两个 RespErr 结果位恒 0★：见文件头 (3)。golden 连端口都没有留，
  // 这里留出端口是为了让 wrapper 的接线表整齐，wrapper 侧原样丢弃。
  assign rxdat_query_read_resp_err  = '0;
  assign rxdat_query_write_resp_err = '0;

  // --- 冒泡给上下游的「这一槽现在可以做」---------------------------------------
  // 四条都要再与 ~order_blocks（前序依赖没解除就不准冒泡）。
  logic [N-1:0] comp_ready;
  assign comp_ready = op_comp_valid_q & ~op_comp_barrier_q;

  assign txrsp_op_valid = (comp_ready | op_dbidresp_valid_q
                         | op_compdbidresp_valid_q | rr_ready) & ~order_blocks;
  assign txdat_op_valid = op_compdata_valid_q & ~order_blocks;
  assign aw_op_valid    = op_wa_valid_q & ~op_wa_barrier_q & ~order_blocks;
  assign ar_op_valid    = op_ra_valid_q & ~order_blocks;

  // TXDAT 还要把**每一槽**的 chi Critical 全都拉出去（N×2 根线），
  // 让 TXDAT 自己挑关键字优先的那一拍。
  always_comb
    for (int i = 0; i < N; i++)
      txdat_op_valid_critical[i] = chi_critical_q[i];

  // --- op 读口 ---------------------------------------------------------------
  assign txrsp_op_read_comp         = |(txrsp_op_read_strb & comp_ready);
  assign txrsp_op_read_dbidresp     = |(txrsp_op_read_strb & op_dbidresp_valid_q);
  assign txrsp_op_read_compdbidresp = |(txrsp_op_read_strb & op_compdbidresp_valid_q);
  assign txrsp_op_read_readreceipt  = |(txrsp_op_read_strb & rr_ready);

  assign txdat_op_read_compdata_valid = |(txdat_op_read_strb & op_compdata_valid_q);
  assign txdat_op_read_compdata_sep   = |(txdat_op_read_strb & op_compdata_sep_q);

  // --- info 读口 -------------------------------------------------------------
  // 只输出 {QoS,TgtID,SrcID,TxnID} 这 38 位（见文件头 (1)）。
  always_comb begin
    txrsp_info_read_bits = '0;
    txdat_info_read_bits = '0;
    aw_info_read_qos     = '0;
    ar_info_read_qos     = '0;
    for (int i = 0; i < N; i++) begin
      if (txrsp_info_read_strb[i])
        txrsp_info_read_bits |= {info_q[i].qos, info_q[i].tgt_id,
                                 info_q[i].src_id, info_q[i].txn_id};
      if (txdat_info_read_strb[i])
        txdat_info_read_bits |= {info_q[i].qos, info_q[i].tgt_id,
                                 info_q[i].src_id, info_q[i].txn_id};
      if (aw_info_read_strb[i]) aw_info_read_qos |= info_q[i].qos;
      if (ar_info_read_strb[i]) ar_info_read_qos |= info_q[i].qos;
    end
  end

  // --- operand 读口 ----------------------------------------------------------
  always_comb begin
    txdat_operand_read_addr     = '0;
    txdat_operand_read_critical = '0;
    txdat_operand_read_count    = '0;
    aw_operand_read_addr        = '0;
    aw_operand_read_size        = '0;
    aw_operand_read_len         = '0;
    ar_operand_read_addr        = '0;
    ar_operand_read_size        = '0;
    ar_operand_read_len         = '0;
    w_operand_read_critical     = '0;
    w_operand_read_count        = '0;
    r_operand_read_critical     = '0;
    r_operand_read_count        = '0;
    for (int i = 0; i < N; i++) begin
      if (txdat_operand_read_strb[i]) begin
        txdat_operand_read_addr     |= chi_addr_q[i];
        txdat_operand_read_critical |= chi_critical_q[i];
        txdat_operand_read_count    |= chi_count_q[i];
      end
      if (aw_operand_read_strb[i]) begin
        aw_operand_read_addr |= axi_addr_q[i];
        aw_operand_read_size |= axi_size_q[i];
        aw_operand_read_len  |= axi_len_q[i];
      end
      if (ar_operand_read_strb[i]) begin
        ar_operand_read_addr |= axi_addr_q[i];
        ar_operand_read_size |= axi_size_q[i];
        ar_operand_read_len  |= axi_len_q[i];
      end
      if (w_operand_read_strb[i]) begin
        w_operand_read_critical |= axi_critical_q[i];
        w_operand_read_count    |= axi_count_q[i];
      end
      if (r_operand_read_strb[i]) begin
        r_operand_read_critical |= axi_critical_q[i];
        r_operand_read_count    |= axi_count_q[i];
      end
    end
  end

  // Burst 恒 INCR（axiBurstAlwaysIncr=true），但仍要经过一次 ValidMux：
  // 没有任何 strobe 时读出 0 而不是 INCR。golden 写成 {1'h0, |strb}，等价。
  assign aw_operand_read_burst = (|aw_operand_read_strb) ? AXI_BURST_INCR : '0;
  assign ar_operand_read_burst = (|ar_operand_read_strb) ? AXI_BURST_INCR : '0;

  // 两个 RespErr 读口恒 0：见文件头 (3)。
  assign txdat_operand_read_read_resp_err = '0;
  assign txrsp_operand_write_resp_err     = '0;

  // ===========================================================================
  // §9 debug / 断言条件
  // ---------------------------------------------------------------------------
  // golden 把这两条断言的条件也引成了真端口（DebugSignal），所以它们参与 FM 比对，
  // UT 也要逐拍比。断言本身在 `ifndef SYNTHESIS 里，UT/FM 两侧都定义 SYNTHESIS。
  // ===========================================================================
  assign dbg_double_allocation = alloc_hit & entry_valid_q;   // 占着的槽又被分配
  assign dbg_dangling_axi_write_response =
      b_op_done_strb & ~(entry_valid_q & op_wresp_valid_q);

endmodule : xs_NCBTransactionQueue_core
