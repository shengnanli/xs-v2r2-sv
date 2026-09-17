// NCBTransactionQueue_1.sv —— OpenNCB 事务队列（CHI→AXI 的 **MMIO 桥**（Top.scala chi_mmioBridge_opt，每核一份））薄包装层
// ---------------------------------------------------------------------------
// 核体见 xs_NCBTransactionQueue_core.sv（家族共享参数化核）。本文件只做端口
// 打包与参数设定：把 golden 逐槽展平的 1212 个标量端口收成 N 位向量接给核。
//
// 本变体参数（对应 XiangShan src/main/scala/top/Top.scala 的 NCBParameters）：
//   outstandingDepth=32, axiMasterOrder=None, acceptMemAttrDevice=true, readReceiptAfterAcception=true
// 于是核参数为：
//   N = 32，HAS_ORDER = 0，HAS_DEVICE = 1，HAS_AR_READY_BARRIER = 1
//
// ★两个变体不是「纯尺寸单态化」★（立项时的猜测被实测推翻）。除 64 项/32 项外，
// 归一化后的 golden 端口表还差这几项（逐条量得，见 verif/ut/NCBTransactionQueue/gen.py）：
//   本变体**没有** io_allocate_bits_order_{valid,index}，也没有 order 寄存器
//   （axiMasterOrder=None → 上游把 order.valid 钉成常数 0，整片 32×32 依赖
//   阵列被 firtool 折没；这正是它只有 11k 行而 64 项变体有 30k 行的主因之一）。
//   本变体**多出** io_allocate_bits_operand_axi_Device 与
//   io_downstreamAr_operandRead_bits_Device（acceptMemAttrDevice=true），
//   以及 io_downstreamAr_opDone_strb_*（readReceiptAfterAcception=true 时
//   ReadReceipt 要等 AXI ARREADY，于是每槽多一位屏障寄存器）。
//
// 规模：golden NCBTransactionQueue_1.sv 共 11134 行、1212 个端口、每槽 34 个寄存器（32 槽 = 1088 个）。
//
// 自动生成：verif/ut/NCBTransactionQueue/gen.py —— 勿手改
// ===========================================================================
// 本文件导航（共 2705 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L1250  本变体参数
//   L1259  核侧信号声明
//   L1340  输入：逐槽展平的 golden 端口收成 N 位向量
//   L2202  输入：标量端口
//   L2262  参数化核例化
//   L2372  输出：核侧向量散回 golden 的逐槽标量端口
//
module NCBTransactionQueue_1
(
  input          clock,
  input          reset,
  output         io_free_strb_0,
  output         io_free_strb_1,
  output         io_free_strb_2,
  output         io_free_strb_3,
  output         io_free_strb_4,
  output         io_free_strb_5,
  output         io_free_strb_6,
  output         io_free_strb_7,
  output         io_free_strb_8,
  output         io_free_strb_9,
  output         io_free_strb_10,
  output         io_free_strb_11,
  output         io_free_strb_12,
  output         io_free_strb_13,
  output         io_free_strb_14,
  output         io_free_strb_15,
  output         io_free_strb_16,
  output         io_free_strb_17,
  output         io_free_strb_18,
  output         io_free_strb_19,
  output         io_free_strb_20,
  output         io_free_strb_21,
  output         io_free_strb_22,
  output         io_free_strb_23,
  output         io_free_strb_24,
  output         io_free_strb_25,
  output         io_free_strb_26,
  output         io_free_strb_27,
  output         io_free_strb_28,
  output         io_free_strb_29,
  output         io_free_strb_30,
  output         io_free_strb_31,
  input          io_allocate_en,
  input          io_allocate_strb_0,
  input          io_allocate_strb_1,
  input          io_allocate_strb_2,
  input          io_allocate_strb_3,
  input          io_allocate_strb_4,
  input          io_allocate_strb_5,
  input          io_allocate_strb_6,
  input          io_allocate_strb_7,
  input          io_allocate_strb_8,
  input          io_allocate_strb_9,
  input          io_allocate_strb_10,
  input          io_allocate_strb_11,
  input          io_allocate_strb_12,
  input          io_allocate_strb_13,
  input          io_allocate_strb_14,
  input          io_allocate_strb_15,
  input          io_allocate_strb_16,
  input          io_allocate_strb_17,
  input          io_allocate_strb_18,
  input          io_allocate_strb_19,
  input          io_allocate_strb_20,
  input          io_allocate_strb_21,
  input          io_allocate_strb_22,
  input          io_allocate_strb_23,
  input          io_allocate_strb_24,
  input          io_allocate_strb_25,
  input          io_allocate_strb_26,
  input          io_allocate_strb_27,
  input          io_allocate_strb_28,
  input          io_allocate_strb_29,
  input          io_allocate_strb_30,
  input          io_allocate_strb_31,
  input          io_allocate_bits_op_chi_Comp_valid,
  input          io_allocate_bits_op_chi_Comp_barrier_CHICancelOrAXIBresp,
  input          io_allocate_bits_op_chi_DBIDResp_valid,
  input          io_allocate_bits_op_chi_CompDBIDResp_valid,
  input          io_allocate_bits_op_chi_ReadReceipt_valid,
  input          io_allocate_bits_op_chi_CompData_valid,
  input          io_allocate_bits_op_chi_CompData_sep,
  input          io_allocate_bits_op_axi_WriteAddress_valid,
  input          io_allocate_bits_op_axi_WriteAddress_barrier_CHIWriteBackData,
  input          io_allocate_bits_op_axi_WriteData_valid,
  input          io_allocate_bits_op_axi_WriteResponse_valid,
  input          io_allocate_bits_op_axi_ReadAddress_valid,
  input          io_allocate_bits_op_axi_ReadData_valid,
  input  [3:0]   io_allocate_bits_info_QoS,
  input  [10:0]  io_allocate_bits_info_TgtID,
  input  [10:0]  io_allocate_bits_info_SrcID,
  input  [11:0]  io_allocate_bits_info_TxnID,
  input  [10:0]  io_allocate_bits_info_ReturnNID,
  input  [11:0]  io_allocate_bits_info_ReturnTxnID,
  input  [47:0]  io_allocate_bits_operand_chi_Addr,
  input          io_allocate_bits_operand_chi_WriteFull,
  input          io_allocate_bits_operand_chi_WritePtl,
  input          io_allocate_bits_operand_chi_Critical_0,
  input          io_allocate_bits_operand_chi_Critical_1,
  input          io_allocate_bits_operand_chi_Count,
  input  [48:0]  io_allocate_bits_operand_axi_Addr,
  input  [2:0]   io_allocate_bits_operand_axi_Size,
  input  [7:0]   io_allocate_bits_operand_axi_Len,
  input          io_allocate_bits_operand_axi_Device,
  input          io_allocate_bits_operand_axi_Critical_0,
  input          io_allocate_bits_operand_axi_Critical_1,
  input          io_allocate_bits_operand_axi_Count,
  input          io_upstreamRxDat_query_en,
  input          io_upstreamRxDat_query_strb_0,
  input          io_upstreamRxDat_query_strb_1,
  input          io_upstreamRxDat_query_strb_2,
  input          io_upstreamRxDat_query_strb_3,
  input          io_upstreamRxDat_query_strb_4,
  input          io_upstreamRxDat_query_strb_5,
  input          io_upstreamRxDat_query_strb_6,
  input          io_upstreamRxDat_query_strb_7,
  input          io_upstreamRxDat_query_strb_8,
  input          io_upstreamRxDat_query_strb_9,
  input          io_upstreamRxDat_query_strb_10,
  input          io_upstreamRxDat_query_strb_11,
  input          io_upstreamRxDat_query_strb_12,
  input          io_upstreamRxDat_query_strb_13,
  input          io_upstreamRxDat_query_strb_14,
  input          io_upstreamRxDat_query_strb_15,
  input          io_upstreamRxDat_query_strb_16,
  input          io_upstreamRxDat_query_strb_17,
  input          io_upstreamRxDat_query_strb_18,
  input          io_upstreamRxDat_query_strb_19,
  input          io_upstreamRxDat_query_strb_20,
  input          io_upstreamRxDat_query_strb_21,
  input          io_upstreamRxDat_query_strb_22,
  input          io_upstreamRxDat_query_strb_23,
  input          io_upstreamRxDat_query_strb_24,
  input          io_upstreamRxDat_query_strb_25,
  input          io_upstreamRxDat_query_strb_26,
  input          io_upstreamRxDat_query_strb_27,
  input          io_upstreamRxDat_query_strb_28,
  input          io_upstreamRxDat_query_strb_29,
  input          io_upstreamRxDat_query_strb_30,
  input          io_upstreamRxDat_query_strb_31,
  output         io_upstreamRxDat_query_result_valid,
  output         io_upstreamRxDat_query_result_WriteFull,
  output         io_upstreamRxDat_query_result_WritePtl,
  input          io_upstreamRxDat_cancel_en,
  input          io_upstreamRxDat_cancel_strb_0,
  input          io_upstreamRxDat_cancel_strb_1,
  input          io_upstreamRxDat_cancel_strb_2,
  input          io_upstreamRxDat_cancel_strb_3,
  input          io_upstreamRxDat_cancel_strb_4,
  input          io_upstreamRxDat_cancel_strb_5,
  input          io_upstreamRxDat_cancel_strb_6,
  input          io_upstreamRxDat_cancel_strb_7,
  input          io_upstreamRxDat_cancel_strb_8,
  input          io_upstreamRxDat_cancel_strb_9,
  input          io_upstreamRxDat_cancel_strb_10,
  input          io_upstreamRxDat_cancel_strb_11,
  input          io_upstreamRxDat_cancel_strb_12,
  input          io_upstreamRxDat_cancel_strb_13,
  input          io_upstreamRxDat_cancel_strb_14,
  input          io_upstreamRxDat_cancel_strb_15,
  input          io_upstreamRxDat_cancel_strb_16,
  input          io_upstreamRxDat_cancel_strb_17,
  input          io_upstreamRxDat_cancel_strb_18,
  input          io_upstreamRxDat_cancel_strb_19,
  input          io_upstreamRxDat_cancel_strb_20,
  input          io_upstreamRxDat_cancel_strb_21,
  input          io_upstreamRxDat_cancel_strb_22,
  input          io_upstreamRxDat_cancel_strb_23,
  input          io_upstreamRxDat_cancel_strb_24,
  input          io_upstreamRxDat_cancel_strb_25,
  input          io_upstreamRxDat_cancel_strb_26,
  input          io_upstreamRxDat_cancel_strb_27,
  input          io_upstreamRxDat_cancel_strb_28,
  input          io_upstreamRxDat_cancel_strb_29,
  input          io_upstreamRxDat_cancel_strb_30,
  input          io_upstreamRxDat_cancel_strb_31,
  input          io_upstreamRxDat_writeData_en,
  input          io_upstreamRxDat_writeData_strb_0,
  input          io_upstreamRxDat_writeData_strb_1,
  input          io_upstreamRxDat_writeData_strb_2,
  input          io_upstreamRxDat_writeData_strb_3,
  input          io_upstreamRxDat_writeData_strb_4,
  input          io_upstreamRxDat_writeData_strb_5,
  input          io_upstreamRxDat_writeData_strb_6,
  input          io_upstreamRxDat_writeData_strb_7,
  input          io_upstreamRxDat_writeData_strb_8,
  input          io_upstreamRxDat_writeData_strb_9,
  input          io_upstreamRxDat_writeData_strb_10,
  input          io_upstreamRxDat_writeData_strb_11,
  input          io_upstreamRxDat_writeData_strb_12,
  input          io_upstreamRxDat_writeData_strb_13,
  input          io_upstreamRxDat_writeData_strb_14,
  input          io_upstreamRxDat_writeData_strb_15,
  input          io_upstreamRxDat_writeData_strb_16,
  input          io_upstreamRxDat_writeData_strb_17,
  input          io_upstreamRxDat_writeData_strb_18,
  input          io_upstreamRxDat_writeData_strb_19,
  input          io_upstreamRxDat_writeData_strb_20,
  input          io_upstreamRxDat_writeData_strb_21,
  input          io_upstreamRxDat_writeData_strb_22,
  input          io_upstreamRxDat_writeData_strb_23,
  input          io_upstreamRxDat_writeData_strb_24,
  input          io_upstreamRxDat_writeData_strb_25,
  input          io_upstreamRxDat_writeData_strb_26,
  input          io_upstreamRxDat_writeData_strb_27,
  input          io_upstreamRxDat_writeData_strb_28,
  input          io_upstreamRxDat_writeData_strb_29,
  input          io_upstreamRxDat_writeData_strb_30,
  input          io_upstreamRxDat_writeData_strb_31,
  output         io_upstreamTxRsp_opValid_valid_0,
  output         io_upstreamTxRsp_opValid_valid_1,
  output         io_upstreamTxRsp_opValid_valid_2,
  output         io_upstreamTxRsp_opValid_valid_3,
  output         io_upstreamTxRsp_opValid_valid_4,
  output         io_upstreamTxRsp_opValid_valid_5,
  output         io_upstreamTxRsp_opValid_valid_6,
  output         io_upstreamTxRsp_opValid_valid_7,
  output         io_upstreamTxRsp_opValid_valid_8,
  output         io_upstreamTxRsp_opValid_valid_9,
  output         io_upstreamTxRsp_opValid_valid_10,
  output         io_upstreamTxRsp_opValid_valid_11,
  output         io_upstreamTxRsp_opValid_valid_12,
  output         io_upstreamTxRsp_opValid_valid_13,
  output         io_upstreamTxRsp_opValid_valid_14,
  output         io_upstreamTxRsp_opValid_valid_15,
  output         io_upstreamTxRsp_opValid_valid_16,
  output         io_upstreamTxRsp_opValid_valid_17,
  output         io_upstreamTxRsp_opValid_valid_18,
  output         io_upstreamTxRsp_opValid_valid_19,
  output         io_upstreamTxRsp_opValid_valid_20,
  output         io_upstreamTxRsp_opValid_valid_21,
  output         io_upstreamTxRsp_opValid_valid_22,
  output         io_upstreamTxRsp_opValid_valid_23,
  output         io_upstreamTxRsp_opValid_valid_24,
  output         io_upstreamTxRsp_opValid_valid_25,
  output         io_upstreamTxRsp_opValid_valid_26,
  output         io_upstreamTxRsp_opValid_valid_27,
  output         io_upstreamTxRsp_opValid_valid_28,
  output         io_upstreamTxRsp_opValid_valid_29,
  output         io_upstreamTxRsp_opValid_valid_30,
  output         io_upstreamTxRsp_opValid_valid_31,
  input          io_upstreamTxRsp_opRead_strb_0,
  input          io_upstreamTxRsp_opRead_strb_1,
  input          io_upstreamTxRsp_opRead_strb_2,
  input          io_upstreamTxRsp_opRead_strb_3,
  input          io_upstreamTxRsp_opRead_strb_4,
  input          io_upstreamTxRsp_opRead_strb_5,
  input          io_upstreamTxRsp_opRead_strb_6,
  input          io_upstreamTxRsp_opRead_strb_7,
  input          io_upstreamTxRsp_opRead_strb_8,
  input          io_upstreamTxRsp_opRead_strb_9,
  input          io_upstreamTxRsp_opRead_strb_10,
  input          io_upstreamTxRsp_opRead_strb_11,
  input          io_upstreamTxRsp_opRead_strb_12,
  input          io_upstreamTxRsp_opRead_strb_13,
  input          io_upstreamTxRsp_opRead_strb_14,
  input          io_upstreamTxRsp_opRead_strb_15,
  input          io_upstreamTxRsp_opRead_strb_16,
  input          io_upstreamTxRsp_opRead_strb_17,
  input          io_upstreamTxRsp_opRead_strb_18,
  input          io_upstreamTxRsp_opRead_strb_19,
  input          io_upstreamTxRsp_opRead_strb_20,
  input          io_upstreamTxRsp_opRead_strb_21,
  input          io_upstreamTxRsp_opRead_strb_22,
  input          io_upstreamTxRsp_opRead_strb_23,
  input          io_upstreamTxRsp_opRead_strb_24,
  input          io_upstreamTxRsp_opRead_strb_25,
  input          io_upstreamTxRsp_opRead_strb_26,
  input          io_upstreamTxRsp_opRead_strb_27,
  input          io_upstreamTxRsp_opRead_strb_28,
  input          io_upstreamTxRsp_opRead_strb_29,
  input          io_upstreamTxRsp_opRead_strb_30,
  input          io_upstreamTxRsp_opRead_strb_31,
  output         io_upstreamTxRsp_opRead_bits_Comp,
  output         io_upstreamTxRsp_opRead_bits_DBIDResp,
  output         io_upstreamTxRsp_opRead_bits_CompDBIDResp,
  output         io_upstreamTxRsp_opRead_bits_ReadReceipt,
  input          io_upstreamTxRsp_opDone_strb_0,
  input          io_upstreamTxRsp_opDone_strb_1,
  input          io_upstreamTxRsp_opDone_strb_2,
  input          io_upstreamTxRsp_opDone_strb_3,
  input          io_upstreamTxRsp_opDone_strb_4,
  input          io_upstreamTxRsp_opDone_strb_5,
  input          io_upstreamTxRsp_opDone_strb_6,
  input          io_upstreamTxRsp_opDone_strb_7,
  input          io_upstreamTxRsp_opDone_strb_8,
  input          io_upstreamTxRsp_opDone_strb_9,
  input          io_upstreamTxRsp_opDone_strb_10,
  input          io_upstreamTxRsp_opDone_strb_11,
  input          io_upstreamTxRsp_opDone_strb_12,
  input          io_upstreamTxRsp_opDone_strb_13,
  input          io_upstreamTxRsp_opDone_strb_14,
  input          io_upstreamTxRsp_opDone_strb_15,
  input          io_upstreamTxRsp_opDone_strb_16,
  input          io_upstreamTxRsp_opDone_strb_17,
  input          io_upstreamTxRsp_opDone_strb_18,
  input          io_upstreamTxRsp_opDone_strb_19,
  input          io_upstreamTxRsp_opDone_strb_20,
  input          io_upstreamTxRsp_opDone_strb_21,
  input          io_upstreamTxRsp_opDone_strb_22,
  input          io_upstreamTxRsp_opDone_strb_23,
  input          io_upstreamTxRsp_opDone_strb_24,
  input          io_upstreamTxRsp_opDone_strb_25,
  input          io_upstreamTxRsp_opDone_strb_26,
  input          io_upstreamTxRsp_opDone_strb_27,
  input          io_upstreamTxRsp_opDone_strb_28,
  input          io_upstreamTxRsp_opDone_strb_29,
  input          io_upstreamTxRsp_opDone_strb_30,
  input          io_upstreamTxRsp_opDone_strb_31,
  input          io_upstreamTxRsp_opDone_bits_Comp,
  input          io_upstreamTxRsp_opDone_bits_DBIDResp,
  input          io_upstreamTxRsp_opDone_bits_CompDBIDResp,
  input          io_upstreamTxRsp_opDone_bits_ReadReceipt,
  input          io_upstreamTxRsp_infoRead_strb_0,
  input          io_upstreamTxRsp_infoRead_strb_1,
  input          io_upstreamTxRsp_infoRead_strb_2,
  input          io_upstreamTxRsp_infoRead_strb_3,
  input          io_upstreamTxRsp_infoRead_strb_4,
  input          io_upstreamTxRsp_infoRead_strb_5,
  input          io_upstreamTxRsp_infoRead_strb_6,
  input          io_upstreamTxRsp_infoRead_strb_7,
  input          io_upstreamTxRsp_infoRead_strb_8,
  input          io_upstreamTxRsp_infoRead_strb_9,
  input          io_upstreamTxRsp_infoRead_strb_10,
  input          io_upstreamTxRsp_infoRead_strb_11,
  input          io_upstreamTxRsp_infoRead_strb_12,
  input          io_upstreamTxRsp_infoRead_strb_13,
  input          io_upstreamTxRsp_infoRead_strb_14,
  input          io_upstreamTxRsp_infoRead_strb_15,
  input          io_upstreamTxRsp_infoRead_strb_16,
  input          io_upstreamTxRsp_infoRead_strb_17,
  input          io_upstreamTxRsp_infoRead_strb_18,
  input          io_upstreamTxRsp_infoRead_strb_19,
  input          io_upstreamTxRsp_infoRead_strb_20,
  input          io_upstreamTxRsp_infoRead_strb_21,
  input          io_upstreamTxRsp_infoRead_strb_22,
  input          io_upstreamTxRsp_infoRead_strb_23,
  input          io_upstreamTxRsp_infoRead_strb_24,
  input          io_upstreamTxRsp_infoRead_strb_25,
  input          io_upstreamTxRsp_infoRead_strb_26,
  input          io_upstreamTxRsp_infoRead_strb_27,
  input          io_upstreamTxRsp_infoRead_strb_28,
  input          io_upstreamTxRsp_infoRead_strb_29,
  input          io_upstreamTxRsp_infoRead_strb_30,
  input          io_upstreamTxRsp_infoRead_strb_31,
  output [3:0]   io_upstreamTxRsp_infoRead_bits_QoS,
  output [10:0]  io_upstreamTxRsp_infoRead_bits_TgtID,
  output [10:0]  io_upstreamTxRsp_infoRead_bits_SrcID,
  output [11:0]  io_upstreamTxRsp_infoRead_bits_TxnID,
  output [1:0]   io_upstreamTxRsp_operandRead_bits_WriteRespErr,
  output         io_upstreamTxDat_opValid_valid_0,
  output         io_upstreamTxDat_opValid_valid_1,
  output         io_upstreamTxDat_opValid_valid_2,
  output         io_upstreamTxDat_opValid_valid_3,
  output         io_upstreamTxDat_opValid_valid_4,
  output         io_upstreamTxDat_opValid_valid_5,
  output         io_upstreamTxDat_opValid_valid_6,
  output         io_upstreamTxDat_opValid_valid_7,
  output         io_upstreamTxDat_opValid_valid_8,
  output         io_upstreamTxDat_opValid_valid_9,
  output         io_upstreamTxDat_opValid_valid_10,
  output         io_upstreamTxDat_opValid_valid_11,
  output         io_upstreamTxDat_opValid_valid_12,
  output         io_upstreamTxDat_opValid_valid_13,
  output         io_upstreamTxDat_opValid_valid_14,
  output         io_upstreamTxDat_opValid_valid_15,
  output         io_upstreamTxDat_opValid_valid_16,
  output         io_upstreamTxDat_opValid_valid_17,
  output         io_upstreamTxDat_opValid_valid_18,
  output         io_upstreamTxDat_opValid_valid_19,
  output         io_upstreamTxDat_opValid_valid_20,
  output         io_upstreamTxDat_opValid_valid_21,
  output         io_upstreamTxDat_opValid_valid_22,
  output         io_upstreamTxDat_opValid_valid_23,
  output         io_upstreamTxDat_opValid_valid_24,
  output         io_upstreamTxDat_opValid_valid_25,
  output         io_upstreamTxDat_opValid_valid_26,
  output         io_upstreamTxDat_opValid_valid_27,
  output         io_upstreamTxDat_opValid_valid_28,
  output         io_upstreamTxDat_opValid_valid_29,
  output         io_upstreamTxDat_opValid_valid_30,
  output         io_upstreamTxDat_opValid_valid_31,
  output         io_upstreamTxDat_opValid_bits_Critical_0_0,
  output         io_upstreamTxDat_opValid_bits_Critical_0_1,
  output         io_upstreamTxDat_opValid_bits_Critical_1_0,
  output         io_upstreamTxDat_opValid_bits_Critical_1_1,
  output         io_upstreamTxDat_opValid_bits_Critical_2_0,
  output         io_upstreamTxDat_opValid_bits_Critical_2_1,
  output         io_upstreamTxDat_opValid_bits_Critical_3_0,
  output         io_upstreamTxDat_opValid_bits_Critical_3_1,
  output         io_upstreamTxDat_opValid_bits_Critical_4_0,
  output         io_upstreamTxDat_opValid_bits_Critical_4_1,
  output         io_upstreamTxDat_opValid_bits_Critical_5_0,
  output         io_upstreamTxDat_opValid_bits_Critical_5_1,
  output         io_upstreamTxDat_opValid_bits_Critical_6_0,
  output         io_upstreamTxDat_opValid_bits_Critical_6_1,
  output         io_upstreamTxDat_opValid_bits_Critical_7_0,
  output         io_upstreamTxDat_opValid_bits_Critical_7_1,
  output         io_upstreamTxDat_opValid_bits_Critical_8_0,
  output         io_upstreamTxDat_opValid_bits_Critical_8_1,
  output         io_upstreamTxDat_opValid_bits_Critical_9_0,
  output         io_upstreamTxDat_opValid_bits_Critical_9_1,
  output         io_upstreamTxDat_opValid_bits_Critical_10_0,
  output         io_upstreamTxDat_opValid_bits_Critical_10_1,
  output         io_upstreamTxDat_opValid_bits_Critical_11_0,
  output         io_upstreamTxDat_opValid_bits_Critical_11_1,
  output         io_upstreamTxDat_opValid_bits_Critical_12_0,
  output         io_upstreamTxDat_opValid_bits_Critical_12_1,
  output         io_upstreamTxDat_opValid_bits_Critical_13_0,
  output         io_upstreamTxDat_opValid_bits_Critical_13_1,
  output         io_upstreamTxDat_opValid_bits_Critical_14_0,
  output         io_upstreamTxDat_opValid_bits_Critical_14_1,
  output         io_upstreamTxDat_opValid_bits_Critical_15_0,
  output         io_upstreamTxDat_opValid_bits_Critical_15_1,
  output         io_upstreamTxDat_opValid_bits_Critical_16_0,
  output         io_upstreamTxDat_opValid_bits_Critical_16_1,
  output         io_upstreamTxDat_opValid_bits_Critical_17_0,
  output         io_upstreamTxDat_opValid_bits_Critical_17_1,
  output         io_upstreamTxDat_opValid_bits_Critical_18_0,
  output         io_upstreamTxDat_opValid_bits_Critical_18_1,
  output         io_upstreamTxDat_opValid_bits_Critical_19_0,
  output         io_upstreamTxDat_opValid_bits_Critical_19_1,
  output         io_upstreamTxDat_opValid_bits_Critical_20_0,
  output         io_upstreamTxDat_opValid_bits_Critical_20_1,
  output         io_upstreamTxDat_opValid_bits_Critical_21_0,
  output         io_upstreamTxDat_opValid_bits_Critical_21_1,
  output         io_upstreamTxDat_opValid_bits_Critical_22_0,
  output         io_upstreamTxDat_opValid_bits_Critical_22_1,
  output         io_upstreamTxDat_opValid_bits_Critical_23_0,
  output         io_upstreamTxDat_opValid_bits_Critical_23_1,
  output         io_upstreamTxDat_opValid_bits_Critical_24_0,
  output         io_upstreamTxDat_opValid_bits_Critical_24_1,
  output         io_upstreamTxDat_opValid_bits_Critical_25_0,
  output         io_upstreamTxDat_opValid_bits_Critical_25_1,
  output         io_upstreamTxDat_opValid_bits_Critical_26_0,
  output         io_upstreamTxDat_opValid_bits_Critical_26_1,
  output         io_upstreamTxDat_opValid_bits_Critical_27_0,
  output         io_upstreamTxDat_opValid_bits_Critical_27_1,
  output         io_upstreamTxDat_opValid_bits_Critical_28_0,
  output         io_upstreamTxDat_opValid_bits_Critical_28_1,
  output         io_upstreamTxDat_opValid_bits_Critical_29_0,
  output         io_upstreamTxDat_opValid_bits_Critical_29_1,
  output         io_upstreamTxDat_opValid_bits_Critical_30_0,
  output         io_upstreamTxDat_opValid_bits_Critical_30_1,
  output         io_upstreamTxDat_opValid_bits_Critical_31_0,
  output         io_upstreamTxDat_opValid_bits_Critical_31_1,
  input          io_upstreamTxDat_opRead_strb_0,
  input          io_upstreamTxDat_opRead_strb_1,
  input          io_upstreamTxDat_opRead_strb_2,
  input          io_upstreamTxDat_opRead_strb_3,
  input          io_upstreamTxDat_opRead_strb_4,
  input          io_upstreamTxDat_opRead_strb_5,
  input          io_upstreamTxDat_opRead_strb_6,
  input          io_upstreamTxDat_opRead_strb_7,
  input          io_upstreamTxDat_opRead_strb_8,
  input          io_upstreamTxDat_opRead_strb_9,
  input          io_upstreamTxDat_opRead_strb_10,
  input          io_upstreamTxDat_opRead_strb_11,
  input          io_upstreamTxDat_opRead_strb_12,
  input          io_upstreamTxDat_opRead_strb_13,
  input          io_upstreamTxDat_opRead_strb_14,
  input          io_upstreamTxDat_opRead_strb_15,
  input          io_upstreamTxDat_opRead_strb_16,
  input          io_upstreamTxDat_opRead_strb_17,
  input          io_upstreamTxDat_opRead_strb_18,
  input          io_upstreamTxDat_opRead_strb_19,
  input          io_upstreamTxDat_opRead_strb_20,
  input          io_upstreamTxDat_opRead_strb_21,
  input          io_upstreamTxDat_opRead_strb_22,
  input          io_upstreamTxDat_opRead_strb_23,
  input          io_upstreamTxDat_opRead_strb_24,
  input          io_upstreamTxDat_opRead_strb_25,
  input          io_upstreamTxDat_opRead_strb_26,
  input          io_upstreamTxDat_opRead_strb_27,
  input          io_upstreamTxDat_opRead_strb_28,
  input          io_upstreamTxDat_opRead_strb_29,
  input          io_upstreamTxDat_opRead_strb_30,
  input          io_upstreamTxDat_opRead_strb_31,
  output         io_upstreamTxDat_opRead_bits_CompData_valid,
  output         io_upstreamTxDat_opRead_bits_CompData_sep,
  input          io_upstreamTxDat_opDone_strb_0,
  input          io_upstreamTxDat_opDone_strb_1,
  input          io_upstreamTxDat_opDone_strb_2,
  input          io_upstreamTxDat_opDone_strb_3,
  input          io_upstreamTxDat_opDone_strb_4,
  input          io_upstreamTxDat_opDone_strb_5,
  input          io_upstreamTxDat_opDone_strb_6,
  input          io_upstreamTxDat_opDone_strb_7,
  input          io_upstreamTxDat_opDone_strb_8,
  input          io_upstreamTxDat_opDone_strb_9,
  input          io_upstreamTxDat_opDone_strb_10,
  input          io_upstreamTxDat_opDone_strb_11,
  input          io_upstreamTxDat_opDone_strb_12,
  input          io_upstreamTxDat_opDone_strb_13,
  input          io_upstreamTxDat_opDone_strb_14,
  input          io_upstreamTxDat_opDone_strb_15,
  input          io_upstreamTxDat_opDone_strb_16,
  input          io_upstreamTxDat_opDone_strb_17,
  input          io_upstreamTxDat_opDone_strb_18,
  input          io_upstreamTxDat_opDone_strb_19,
  input          io_upstreamTxDat_opDone_strb_20,
  input          io_upstreamTxDat_opDone_strb_21,
  input          io_upstreamTxDat_opDone_strb_22,
  input          io_upstreamTxDat_opDone_strb_23,
  input          io_upstreamTxDat_opDone_strb_24,
  input          io_upstreamTxDat_opDone_strb_25,
  input          io_upstreamTxDat_opDone_strb_26,
  input          io_upstreamTxDat_opDone_strb_27,
  input          io_upstreamTxDat_opDone_strb_28,
  input          io_upstreamTxDat_opDone_strb_29,
  input          io_upstreamTxDat_opDone_strb_30,
  input          io_upstreamTxDat_opDone_strb_31,
  input          io_upstreamTxDat_opDone_bits_CompData,
  input          io_upstreamTxDat_infoRead_strb_0,
  input          io_upstreamTxDat_infoRead_strb_1,
  input          io_upstreamTxDat_infoRead_strb_2,
  input          io_upstreamTxDat_infoRead_strb_3,
  input          io_upstreamTxDat_infoRead_strb_4,
  input          io_upstreamTxDat_infoRead_strb_5,
  input          io_upstreamTxDat_infoRead_strb_6,
  input          io_upstreamTxDat_infoRead_strb_7,
  input          io_upstreamTxDat_infoRead_strb_8,
  input          io_upstreamTxDat_infoRead_strb_9,
  input          io_upstreamTxDat_infoRead_strb_10,
  input          io_upstreamTxDat_infoRead_strb_11,
  input          io_upstreamTxDat_infoRead_strb_12,
  input          io_upstreamTxDat_infoRead_strb_13,
  input          io_upstreamTxDat_infoRead_strb_14,
  input          io_upstreamTxDat_infoRead_strb_15,
  input          io_upstreamTxDat_infoRead_strb_16,
  input          io_upstreamTxDat_infoRead_strb_17,
  input          io_upstreamTxDat_infoRead_strb_18,
  input          io_upstreamTxDat_infoRead_strb_19,
  input          io_upstreamTxDat_infoRead_strb_20,
  input          io_upstreamTxDat_infoRead_strb_21,
  input          io_upstreamTxDat_infoRead_strb_22,
  input          io_upstreamTxDat_infoRead_strb_23,
  input          io_upstreamTxDat_infoRead_strb_24,
  input          io_upstreamTxDat_infoRead_strb_25,
  input          io_upstreamTxDat_infoRead_strb_26,
  input          io_upstreamTxDat_infoRead_strb_27,
  input          io_upstreamTxDat_infoRead_strb_28,
  input          io_upstreamTxDat_infoRead_strb_29,
  input          io_upstreamTxDat_infoRead_strb_30,
  input          io_upstreamTxDat_infoRead_strb_31,
  output [3:0]   io_upstreamTxDat_infoRead_bits_QoS,
  output [10:0]  io_upstreamTxDat_infoRead_bits_TgtID,
  output [10:0]  io_upstreamTxDat_infoRead_bits_SrcID,
  output [11:0]  io_upstreamTxDat_infoRead_bits_TxnID,
  input          io_upstreamTxDat_operandRead_strb_0,
  input          io_upstreamTxDat_operandRead_strb_1,
  input          io_upstreamTxDat_operandRead_strb_2,
  input          io_upstreamTxDat_operandRead_strb_3,
  input          io_upstreamTxDat_operandRead_strb_4,
  input          io_upstreamTxDat_operandRead_strb_5,
  input          io_upstreamTxDat_operandRead_strb_6,
  input          io_upstreamTxDat_operandRead_strb_7,
  input          io_upstreamTxDat_operandRead_strb_8,
  input          io_upstreamTxDat_operandRead_strb_9,
  input          io_upstreamTxDat_operandRead_strb_10,
  input          io_upstreamTxDat_operandRead_strb_11,
  input          io_upstreamTxDat_operandRead_strb_12,
  input          io_upstreamTxDat_operandRead_strb_13,
  input          io_upstreamTxDat_operandRead_strb_14,
  input          io_upstreamTxDat_operandRead_strb_15,
  input          io_upstreamTxDat_operandRead_strb_16,
  input          io_upstreamTxDat_operandRead_strb_17,
  input          io_upstreamTxDat_operandRead_strb_18,
  input          io_upstreamTxDat_operandRead_strb_19,
  input          io_upstreamTxDat_operandRead_strb_20,
  input          io_upstreamTxDat_operandRead_strb_21,
  input          io_upstreamTxDat_operandRead_strb_22,
  input          io_upstreamTxDat_operandRead_strb_23,
  input          io_upstreamTxDat_operandRead_strb_24,
  input          io_upstreamTxDat_operandRead_strb_25,
  input          io_upstreamTxDat_operandRead_strb_26,
  input          io_upstreamTxDat_operandRead_strb_27,
  input          io_upstreamTxDat_operandRead_strb_28,
  input          io_upstreamTxDat_operandRead_strb_29,
  input          io_upstreamTxDat_operandRead_strb_30,
  input          io_upstreamTxDat_operandRead_strb_31,
  output [47:0]  io_upstreamTxDat_operandRead_bits_Addr,
  output [1:0]   io_upstreamTxDat_operandRead_bits_ReadRespErr,
  output         io_upstreamTxDat_operandRead_bits_Critical_0,
  output         io_upstreamTxDat_operandRead_bits_Critical_1,
  output         io_upstreamTxDat_operandRead_bits_Count,
  input          io_upstreamTxDat_operandWrite_strb_0,
  input          io_upstreamTxDat_operandWrite_strb_1,
  input          io_upstreamTxDat_operandWrite_strb_2,
  input          io_upstreamTxDat_operandWrite_strb_3,
  input          io_upstreamTxDat_operandWrite_strb_4,
  input          io_upstreamTxDat_operandWrite_strb_5,
  input          io_upstreamTxDat_operandWrite_strb_6,
  input          io_upstreamTxDat_operandWrite_strb_7,
  input          io_upstreamTxDat_operandWrite_strb_8,
  input          io_upstreamTxDat_operandWrite_strb_9,
  input          io_upstreamTxDat_operandWrite_strb_10,
  input          io_upstreamTxDat_operandWrite_strb_11,
  input          io_upstreamTxDat_operandWrite_strb_12,
  input          io_upstreamTxDat_operandWrite_strb_13,
  input          io_upstreamTxDat_operandWrite_strb_14,
  input          io_upstreamTxDat_operandWrite_strb_15,
  input          io_upstreamTxDat_operandWrite_strb_16,
  input          io_upstreamTxDat_operandWrite_strb_17,
  input          io_upstreamTxDat_operandWrite_strb_18,
  input          io_upstreamTxDat_operandWrite_strb_19,
  input          io_upstreamTxDat_operandWrite_strb_20,
  input          io_upstreamTxDat_operandWrite_strb_21,
  input          io_upstreamTxDat_operandWrite_strb_22,
  input          io_upstreamTxDat_operandWrite_strb_23,
  input          io_upstreamTxDat_operandWrite_strb_24,
  input          io_upstreamTxDat_operandWrite_strb_25,
  input          io_upstreamTxDat_operandWrite_strb_26,
  input          io_upstreamTxDat_operandWrite_strb_27,
  input          io_upstreamTxDat_operandWrite_strb_28,
  input          io_upstreamTxDat_operandWrite_strb_29,
  input          io_upstreamTxDat_operandWrite_strb_30,
  input          io_upstreamTxDat_operandWrite_strb_31,
  input          io_upstreamTxDat_operandWrite_bits_Critical_0,
  input          io_upstreamTxDat_operandWrite_bits_Critical_1,
  input          io_upstreamTxDat_operandWrite_bits_Count,
  output         io_downstreamAw_opValid_valid_0,
  output         io_downstreamAw_opValid_valid_1,
  output         io_downstreamAw_opValid_valid_2,
  output         io_downstreamAw_opValid_valid_3,
  output         io_downstreamAw_opValid_valid_4,
  output         io_downstreamAw_opValid_valid_5,
  output         io_downstreamAw_opValid_valid_6,
  output         io_downstreamAw_opValid_valid_7,
  output         io_downstreamAw_opValid_valid_8,
  output         io_downstreamAw_opValid_valid_9,
  output         io_downstreamAw_opValid_valid_10,
  output         io_downstreamAw_opValid_valid_11,
  output         io_downstreamAw_opValid_valid_12,
  output         io_downstreamAw_opValid_valid_13,
  output         io_downstreamAw_opValid_valid_14,
  output         io_downstreamAw_opValid_valid_15,
  output         io_downstreamAw_opValid_valid_16,
  output         io_downstreamAw_opValid_valid_17,
  output         io_downstreamAw_opValid_valid_18,
  output         io_downstreamAw_opValid_valid_19,
  output         io_downstreamAw_opValid_valid_20,
  output         io_downstreamAw_opValid_valid_21,
  output         io_downstreamAw_opValid_valid_22,
  output         io_downstreamAw_opValid_valid_23,
  output         io_downstreamAw_opValid_valid_24,
  output         io_downstreamAw_opValid_valid_25,
  output         io_downstreamAw_opValid_valid_26,
  output         io_downstreamAw_opValid_valid_27,
  output         io_downstreamAw_opValid_valid_28,
  output         io_downstreamAw_opValid_valid_29,
  output         io_downstreamAw_opValid_valid_30,
  output         io_downstreamAw_opValid_valid_31,
  input          io_downstreamAw_opPoNR_strb_0,
  input          io_downstreamAw_opPoNR_strb_1,
  input          io_downstreamAw_opPoNR_strb_2,
  input          io_downstreamAw_opPoNR_strb_3,
  input          io_downstreamAw_opPoNR_strb_4,
  input          io_downstreamAw_opPoNR_strb_5,
  input          io_downstreamAw_opPoNR_strb_6,
  input          io_downstreamAw_opPoNR_strb_7,
  input          io_downstreamAw_opPoNR_strb_8,
  input          io_downstreamAw_opPoNR_strb_9,
  input          io_downstreamAw_opPoNR_strb_10,
  input          io_downstreamAw_opPoNR_strb_11,
  input          io_downstreamAw_opPoNR_strb_12,
  input          io_downstreamAw_opPoNR_strb_13,
  input          io_downstreamAw_opPoNR_strb_14,
  input          io_downstreamAw_opPoNR_strb_15,
  input          io_downstreamAw_opPoNR_strb_16,
  input          io_downstreamAw_opPoNR_strb_17,
  input          io_downstreamAw_opPoNR_strb_18,
  input          io_downstreamAw_opPoNR_strb_19,
  input          io_downstreamAw_opPoNR_strb_20,
  input          io_downstreamAw_opPoNR_strb_21,
  input          io_downstreamAw_opPoNR_strb_22,
  input          io_downstreamAw_opPoNR_strb_23,
  input          io_downstreamAw_opPoNR_strb_24,
  input          io_downstreamAw_opPoNR_strb_25,
  input          io_downstreamAw_opPoNR_strb_26,
  input          io_downstreamAw_opPoNR_strb_27,
  input          io_downstreamAw_opPoNR_strb_28,
  input          io_downstreamAw_opPoNR_strb_29,
  input          io_downstreamAw_opPoNR_strb_30,
  input          io_downstreamAw_opPoNR_strb_31,
  input          io_downstreamAw_infoRead_strb_0,
  input          io_downstreamAw_infoRead_strb_1,
  input          io_downstreamAw_infoRead_strb_2,
  input          io_downstreamAw_infoRead_strb_3,
  input          io_downstreamAw_infoRead_strb_4,
  input          io_downstreamAw_infoRead_strb_5,
  input          io_downstreamAw_infoRead_strb_6,
  input          io_downstreamAw_infoRead_strb_7,
  input          io_downstreamAw_infoRead_strb_8,
  input          io_downstreamAw_infoRead_strb_9,
  input          io_downstreamAw_infoRead_strb_10,
  input          io_downstreamAw_infoRead_strb_11,
  input          io_downstreamAw_infoRead_strb_12,
  input          io_downstreamAw_infoRead_strb_13,
  input          io_downstreamAw_infoRead_strb_14,
  input          io_downstreamAw_infoRead_strb_15,
  input          io_downstreamAw_infoRead_strb_16,
  input          io_downstreamAw_infoRead_strb_17,
  input          io_downstreamAw_infoRead_strb_18,
  input          io_downstreamAw_infoRead_strb_19,
  input          io_downstreamAw_infoRead_strb_20,
  input          io_downstreamAw_infoRead_strb_21,
  input          io_downstreamAw_infoRead_strb_22,
  input          io_downstreamAw_infoRead_strb_23,
  input          io_downstreamAw_infoRead_strb_24,
  input          io_downstreamAw_infoRead_strb_25,
  input          io_downstreamAw_infoRead_strb_26,
  input          io_downstreamAw_infoRead_strb_27,
  input          io_downstreamAw_infoRead_strb_28,
  input          io_downstreamAw_infoRead_strb_29,
  input          io_downstreamAw_infoRead_strb_30,
  input          io_downstreamAw_infoRead_strb_31,
  output [3:0]   io_downstreamAw_infoRead_bits_QoS,
  input          io_downstreamAw_operandRead_strb_0,
  input          io_downstreamAw_operandRead_strb_1,
  input          io_downstreamAw_operandRead_strb_2,
  input          io_downstreamAw_operandRead_strb_3,
  input          io_downstreamAw_operandRead_strb_4,
  input          io_downstreamAw_operandRead_strb_5,
  input          io_downstreamAw_operandRead_strb_6,
  input          io_downstreamAw_operandRead_strb_7,
  input          io_downstreamAw_operandRead_strb_8,
  input          io_downstreamAw_operandRead_strb_9,
  input          io_downstreamAw_operandRead_strb_10,
  input          io_downstreamAw_operandRead_strb_11,
  input          io_downstreamAw_operandRead_strb_12,
  input          io_downstreamAw_operandRead_strb_13,
  input          io_downstreamAw_operandRead_strb_14,
  input          io_downstreamAw_operandRead_strb_15,
  input          io_downstreamAw_operandRead_strb_16,
  input          io_downstreamAw_operandRead_strb_17,
  input          io_downstreamAw_operandRead_strb_18,
  input          io_downstreamAw_operandRead_strb_19,
  input          io_downstreamAw_operandRead_strb_20,
  input          io_downstreamAw_operandRead_strb_21,
  input          io_downstreamAw_operandRead_strb_22,
  input          io_downstreamAw_operandRead_strb_23,
  input          io_downstreamAw_operandRead_strb_24,
  input          io_downstreamAw_operandRead_strb_25,
  input          io_downstreamAw_operandRead_strb_26,
  input          io_downstreamAw_operandRead_strb_27,
  input          io_downstreamAw_operandRead_strb_28,
  input          io_downstreamAw_operandRead_strb_29,
  input          io_downstreamAw_operandRead_strb_30,
  input          io_downstreamAw_operandRead_strb_31,
  output [48:0]  io_downstreamAw_operandRead_bits_Addr,
  output [1:0]   io_downstreamAw_operandRead_bits_Burst,
  output [2:0]   io_downstreamAw_operandRead_bits_Size,
  output [7:0]   io_downstreamAw_operandRead_bits_Len,
  input          io_downstreamW_opPoNR_strb_0,
  input          io_downstreamW_opPoNR_strb_1,
  input          io_downstreamW_opPoNR_strb_2,
  input          io_downstreamW_opPoNR_strb_3,
  input          io_downstreamW_opPoNR_strb_4,
  input          io_downstreamW_opPoNR_strb_5,
  input          io_downstreamW_opPoNR_strb_6,
  input          io_downstreamW_opPoNR_strb_7,
  input          io_downstreamW_opPoNR_strb_8,
  input          io_downstreamW_opPoNR_strb_9,
  input          io_downstreamW_opPoNR_strb_10,
  input          io_downstreamW_opPoNR_strb_11,
  input          io_downstreamW_opPoNR_strb_12,
  input          io_downstreamW_opPoNR_strb_13,
  input          io_downstreamW_opPoNR_strb_14,
  input          io_downstreamW_opPoNR_strb_15,
  input          io_downstreamW_opPoNR_strb_16,
  input          io_downstreamW_opPoNR_strb_17,
  input          io_downstreamW_opPoNR_strb_18,
  input          io_downstreamW_opPoNR_strb_19,
  input          io_downstreamW_opPoNR_strb_20,
  input          io_downstreamW_opPoNR_strb_21,
  input          io_downstreamW_opPoNR_strb_22,
  input          io_downstreamW_opPoNR_strb_23,
  input          io_downstreamW_opPoNR_strb_24,
  input          io_downstreamW_opPoNR_strb_25,
  input          io_downstreamW_opPoNR_strb_26,
  input          io_downstreamW_opPoNR_strb_27,
  input          io_downstreamW_opPoNR_strb_28,
  input          io_downstreamW_opPoNR_strb_29,
  input          io_downstreamW_opPoNR_strb_30,
  input          io_downstreamW_opPoNR_strb_31,
  input          io_downstreamW_operandRead_strb_0,
  input          io_downstreamW_operandRead_strb_1,
  input          io_downstreamW_operandRead_strb_2,
  input          io_downstreamW_operandRead_strb_3,
  input          io_downstreamW_operandRead_strb_4,
  input          io_downstreamW_operandRead_strb_5,
  input          io_downstreamW_operandRead_strb_6,
  input          io_downstreamW_operandRead_strb_7,
  input          io_downstreamW_operandRead_strb_8,
  input          io_downstreamW_operandRead_strb_9,
  input          io_downstreamW_operandRead_strb_10,
  input          io_downstreamW_operandRead_strb_11,
  input          io_downstreamW_operandRead_strb_12,
  input          io_downstreamW_operandRead_strb_13,
  input          io_downstreamW_operandRead_strb_14,
  input          io_downstreamW_operandRead_strb_15,
  input          io_downstreamW_operandRead_strb_16,
  input          io_downstreamW_operandRead_strb_17,
  input          io_downstreamW_operandRead_strb_18,
  input          io_downstreamW_operandRead_strb_19,
  input          io_downstreamW_operandRead_strb_20,
  input          io_downstreamW_operandRead_strb_21,
  input          io_downstreamW_operandRead_strb_22,
  input          io_downstreamW_operandRead_strb_23,
  input          io_downstreamW_operandRead_strb_24,
  input          io_downstreamW_operandRead_strb_25,
  input          io_downstreamW_operandRead_strb_26,
  input          io_downstreamW_operandRead_strb_27,
  input          io_downstreamW_operandRead_strb_28,
  input          io_downstreamW_operandRead_strb_29,
  input          io_downstreamW_operandRead_strb_30,
  input          io_downstreamW_operandRead_strb_31,
  output         io_downstreamW_operandRead_bits_Critical_0,
  output         io_downstreamW_operandRead_bits_Critical_1,
  output         io_downstreamW_operandRead_bits_Count,
  input          io_downstreamW_operandWrite_strb_0,
  input          io_downstreamW_operandWrite_strb_1,
  input          io_downstreamW_operandWrite_strb_2,
  input          io_downstreamW_operandWrite_strb_3,
  input          io_downstreamW_operandWrite_strb_4,
  input          io_downstreamW_operandWrite_strb_5,
  input          io_downstreamW_operandWrite_strb_6,
  input          io_downstreamW_operandWrite_strb_7,
  input          io_downstreamW_operandWrite_strb_8,
  input          io_downstreamW_operandWrite_strb_9,
  input          io_downstreamW_operandWrite_strb_10,
  input          io_downstreamW_operandWrite_strb_11,
  input          io_downstreamW_operandWrite_strb_12,
  input          io_downstreamW_operandWrite_strb_13,
  input          io_downstreamW_operandWrite_strb_14,
  input          io_downstreamW_operandWrite_strb_15,
  input          io_downstreamW_operandWrite_strb_16,
  input          io_downstreamW_operandWrite_strb_17,
  input          io_downstreamW_operandWrite_strb_18,
  input          io_downstreamW_operandWrite_strb_19,
  input          io_downstreamW_operandWrite_strb_20,
  input          io_downstreamW_operandWrite_strb_21,
  input          io_downstreamW_operandWrite_strb_22,
  input          io_downstreamW_operandWrite_strb_23,
  input          io_downstreamW_operandWrite_strb_24,
  input          io_downstreamW_operandWrite_strb_25,
  input          io_downstreamW_operandWrite_strb_26,
  input          io_downstreamW_operandWrite_strb_27,
  input          io_downstreamW_operandWrite_strb_28,
  input          io_downstreamW_operandWrite_strb_29,
  input          io_downstreamW_operandWrite_strb_30,
  input          io_downstreamW_operandWrite_strb_31,
  input          io_downstreamW_operandWrite_bits_Critical_0,
  input          io_downstreamW_operandWrite_bits_Critical_1,
  input          io_downstreamW_operandWrite_bits_Count,
  input          io_downstreamB_opDone_strb_0,
  input          io_downstreamB_opDone_strb_1,
  input          io_downstreamB_opDone_strb_2,
  input          io_downstreamB_opDone_strb_3,
  input          io_downstreamB_opDone_strb_4,
  input          io_downstreamB_opDone_strb_5,
  input          io_downstreamB_opDone_strb_6,
  input          io_downstreamB_opDone_strb_7,
  input          io_downstreamB_opDone_strb_8,
  input          io_downstreamB_opDone_strb_9,
  input          io_downstreamB_opDone_strb_10,
  input          io_downstreamB_opDone_strb_11,
  input          io_downstreamB_opDone_strb_12,
  input          io_downstreamB_opDone_strb_13,
  input          io_downstreamB_opDone_strb_14,
  input          io_downstreamB_opDone_strb_15,
  input          io_downstreamB_opDone_strb_16,
  input          io_downstreamB_opDone_strb_17,
  input          io_downstreamB_opDone_strb_18,
  input          io_downstreamB_opDone_strb_19,
  input          io_downstreamB_opDone_strb_20,
  input          io_downstreamB_opDone_strb_21,
  input          io_downstreamB_opDone_strb_22,
  input          io_downstreamB_opDone_strb_23,
  input          io_downstreamB_opDone_strb_24,
  input          io_downstreamB_opDone_strb_25,
  input          io_downstreamB_opDone_strb_26,
  input          io_downstreamB_opDone_strb_27,
  input          io_downstreamB_opDone_strb_28,
  input          io_downstreamB_opDone_strb_29,
  input          io_downstreamB_opDone_strb_30,
  input          io_downstreamB_opDone_strb_31,
  output         io_downstreamAr_opValid_valid_0,
  output         io_downstreamAr_opValid_valid_1,
  output         io_downstreamAr_opValid_valid_2,
  output         io_downstreamAr_opValid_valid_3,
  output         io_downstreamAr_opValid_valid_4,
  output         io_downstreamAr_opValid_valid_5,
  output         io_downstreamAr_opValid_valid_6,
  output         io_downstreamAr_opValid_valid_7,
  output         io_downstreamAr_opValid_valid_8,
  output         io_downstreamAr_opValid_valid_9,
  output         io_downstreamAr_opValid_valid_10,
  output         io_downstreamAr_opValid_valid_11,
  output         io_downstreamAr_opValid_valid_12,
  output         io_downstreamAr_opValid_valid_13,
  output         io_downstreamAr_opValid_valid_14,
  output         io_downstreamAr_opValid_valid_15,
  output         io_downstreamAr_opValid_valid_16,
  output         io_downstreamAr_opValid_valid_17,
  output         io_downstreamAr_opValid_valid_18,
  output         io_downstreamAr_opValid_valid_19,
  output         io_downstreamAr_opValid_valid_20,
  output         io_downstreamAr_opValid_valid_21,
  output         io_downstreamAr_opValid_valid_22,
  output         io_downstreamAr_opValid_valid_23,
  output         io_downstreamAr_opValid_valid_24,
  output         io_downstreamAr_opValid_valid_25,
  output         io_downstreamAr_opValid_valid_26,
  output         io_downstreamAr_opValid_valid_27,
  output         io_downstreamAr_opValid_valid_28,
  output         io_downstreamAr_opValid_valid_29,
  output         io_downstreamAr_opValid_valid_30,
  output         io_downstreamAr_opValid_valid_31,
  input          io_downstreamAr_opPoNR_strb_0,
  input          io_downstreamAr_opPoNR_strb_1,
  input          io_downstreamAr_opPoNR_strb_2,
  input          io_downstreamAr_opPoNR_strb_3,
  input          io_downstreamAr_opPoNR_strb_4,
  input          io_downstreamAr_opPoNR_strb_5,
  input          io_downstreamAr_opPoNR_strb_6,
  input          io_downstreamAr_opPoNR_strb_7,
  input          io_downstreamAr_opPoNR_strb_8,
  input          io_downstreamAr_opPoNR_strb_9,
  input          io_downstreamAr_opPoNR_strb_10,
  input          io_downstreamAr_opPoNR_strb_11,
  input          io_downstreamAr_opPoNR_strb_12,
  input          io_downstreamAr_opPoNR_strb_13,
  input          io_downstreamAr_opPoNR_strb_14,
  input          io_downstreamAr_opPoNR_strb_15,
  input          io_downstreamAr_opPoNR_strb_16,
  input          io_downstreamAr_opPoNR_strb_17,
  input          io_downstreamAr_opPoNR_strb_18,
  input          io_downstreamAr_opPoNR_strb_19,
  input          io_downstreamAr_opPoNR_strb_20,
  input          io_downstreamAr_opPoNR_strb_21,
  input          io_downstreamAr_opPoNR_strb_22,
  input          io_downstreamAr_opPoNR_strb_23,
  input          io_downstreamAr_opPoNR_strb_24,
  input          io_downstreamAr_opPoNR_strb_25,
  input          io_downstreamAr_opPoNR_strb_26,
  input          io_downstreamAr_opPoNR_strb_27,
  input          io_downstreamAr_opPoNR_strb_28,
  input          io_downstreamAr_opPoNR_strb_29,
  input          io_downstreamAr_opPoNR_strb_30,
  input          io_downstreamAr_opPoNR_strb_31,
  input          io_downstreamAr_opDone_strb_0,
  input          io_downstreamAr_opDone_strb_1,
  input          io_downstreamAr_opDone_strb_2,
  input          io_downstreamAr_opDone_strb_3,
  input          io_downstreamAr_opDone_strb_4,
  input          io_downstreamAr_opDone_strb_5,
  input          io_downstreamAr_opDone_strb_6,
  input          io_downstreamAr_opDone_strb_7,
  input          io_downstreamAr_opDone_strb_8,
  input          io_downstreamAr_opDone_strb_9,
  input          io_downstreamAr_opDone_strb_10,
  input          io_downstreamAr_opDone_strb_11,
  input          io_downstreamAr_opDone_strb_12,
  input          io_downstreamAr_opDone_strb_13,
  input          io_downstreamAr_opDone_strb_14,
  input          io_downstreamAr_opDone_strb_15,
  input          io_downstreamAr_opDone_strb_16,
  input          io_downstreamAr_opDone_strb_17,
  input          io_downstreamAr_opDone_strb_18,
  input          io_downstreamAr_opDone_strb_19,
  input          io_downstreamAr_opDone_strb_20,
  input          io_downstreamAr_opDone_strb_21,
  input          io_downstreamAr_opDone_strb_22,
  input          io_downstreamAr_opDone_strb_23,
  input          io_downstreamAr_opDone_strb_24,
  input          io_downstreamAr_opDone_strb_25,
  input          io_downstreamAr_opDone_strb_26,
  input          io_downstreamAr_opDone_strb_27,
  input          io_downstreamAr_opDone_strb_28,
  input          io_downstreamAr_opDone_strb_29,
  input          io_downstreamAr_opDone_strb_30,
  input          io_downstreamAr_opDone_strb_31,
  input          io_downstreamAr_infoRead_strb_0,
  input          io_downstreamAr_infoRead_strb_1,
  input          io_downstreamAr_infoRead_strb_2,
  input          io_downstreamAr_infoRead_strb_3,
  input          io_downstreamAr_infoRead_strb_4,
  input          io_downstreamAr_infoRead_strb_5,
  input          io_downstreamAr_infoRead_strb_6,
  input          io_downstreamAr_infoRead_strb_7,
  input          io_downstreamAr_infoRead_strb_8,
  input          io_downstreamAr_infoRead_strb_9,
  input          io_downstreamAr_infoRead_strb_10,
  input          io_downstreamAr_infoRead_strb_11,
  input          io_downstreamAr_infoRead_strb_12,
  input          io_downstreamAr_infoRead_strb_13,
  input          io_downstreamAr_infoRead_strb_14,
  input          io_downstreamAr_infoRead_strb_15,
  input          io_downstreamAr_infoRead_strb_16,
  input          io_downstreamAr_infoRead_strb_17,
  input          io_downstreamAr_infoRead_strb_18,
  input          io_downstreamAr_infoRead_strb_19,
  input          io_downstreamAr_infoRead_strb_20,
  input          io_downstreamAr_infoRead_strb_21,
  input          io_downstreamAr_infoRead_strb_22,
  input          io_downstreamAr_infoRead_strb_23,
  input          io_downstreamAr_infoRead_strb_24,
  input          io_downstreamAr_infoRead_strb_25,
  input          io_downstreamAr_infoRead_strb_26,
  input          io_downstreamAr_infoRead_strb_27,
  input          io_downstreamAr_infoRead_strb_28,
  input          io_downstreamAr_infoRead_strb_29,
  input          io_downstreamAr_infoRead_strb_30,
  input          io_downstreamAr_infoRead_strb_31,
  output [3:0]   io_downstreamAr_infoRead_bits_QoS,
  input          io_downstreamAr_operandRead_strb_0,
  input          io_downstreamAr_operandRead_strb_1,
  input          io_downstreamAr_operandRead_strb_2,
  input          io_downstreamAr_operandRead_strb_3,
  input          io_downstreamAr_operandRead_strb_4,
  input          io_downstreamAr_operandRead_strb_5,
  input          io_downstreamAr_operandRead_strb_6,
  input          io_downstreamAr_operandRead_strb_7,
  input          io_downstreamAr_operandRead_strb_8,
  input          io_downstreamAr_operandRead_strb_9,
  input          io_downstreamAr_operandRead_strb_10,
  input          io_downstreamAr_operandRead_strb_11,
  input          io_downstreamAr_operandRead_strb_12,
  input          io_downstreamAr_operandRead_strb_13,
  input          io_downstreamAr_operandRead_strb_14,
  input          io_downstreamAr_operandRead_strb_15,
  input          io_downstreamAr_operandRead_strb_16,
  input          io_downstreamAr_operandRead_strb_17,
  input          io_downstreamAr_operandRead_strb_18,
  input          io_downstreamAr_operandRead_strb_19,
  input          io_downstreamAr_operandRead_strb_20,
  input          io_downstreamAr_operandRead_strb_21,
  input          io_downstreamAr_operandRead_strb_22,
  input          io_downstreamAr_operandRead_strb_23,
  input          io_downstreamAr_operandRead_strb_24,
  input          io_downstreamAr_operandRead_strb_25,
  input          io_downstreamAr_operandRead_strb_26,
  input          io_downstreamAr_operandRead_strb_27,
  input          io_downstreamAr_operandRead_strb_28,
  input          io_downstreamAr_operandRead_strb_29,
  input          io_downstreamAr_operandRead_strb_30,
  input          io_downstreamAr_operandRead_strb_31,
  output [48:0]  io_downstreamAr_operandRead_bits_Addr,
  output [1:0]   io_downstreamAr_operandRead_bits_Burst,
  output [2:0]   io_downstreamAr_operandRead_bits_Size,
  output [7:0]   io_downstreamAr_operandRead_bits_Len,
  output         io_downstreamAr_operandRead_bits_Device,
  input          io_downstreamR_opDone_strb_0,
  input          io_downstreamR_opDone_strb_1,
  input          io_downstreamR_opDone_strb_2,
  input          io_downstreamR_opDone_strb_3,
  input          io_downstreamR_opDone_strb_4,
  input          io_downstreamR_opDone_strb_5,
  input          io_downstreamR_opDone_strb_6,
  input          io_downstreamR_opDone_strb_7,
  input          io_downstreamR_opDone_strb_8,
  input          io_downstreamR_opDone_strb_9,
  input          io_downstreamR_opDone_strb_10,
  input          io_downstreamR_opDone_strb_11,
  input          io_downstreamR_opDone_strb_12,
  input          io_downstreamR_opDone_strb_13,
  input          io_downstreamR_opDone_strb_14,
  input          io_downstreamR_opDone_strb_15,
  input          io_downstreamR_opDone_strb_16,
  input          io_downstreamR_opDone_strb_17,
  input          io_downstreamR_opDone_strb_18,
  input          io_downstreamR_opDone_strb_19,
  input          io_downstreamR_opDone_strb_20,
  input          io_downstreamR_opDone_strb_21,
  input          io_downstreamR_opDone_strb_22,
  input          io_downstreamR_opDone_strb_23,
  input          io_downstreamR_opDone_strb_24,
  input          io_downstreamR_opDone_strb_25,
  input          io_downstreamR_opDone_strb_26,
  input          io_downstreamR_opDone_strb_27,
  input          io_downstreamR_opDone_strb_28,
  input          io_downstreamR_opDone_strb_29,
  input          io_downstreamR_opDone_strb_30,
  input          io_downstreamR_opDone_strb_31,
  input          io_downstreamR_operandRead_strb_0,
  input          io_downstreamR_operandRead_strb_1,
  input          io_downstreamR_operandRead_strb_2,
  input          io_downstreamR_operandRead_strb_3,
  input          io_downstreamR_operandRead_strb_4,
  input          io_downstreamR_operandRead_strb_5,
  input          io_downstreamR_operandRead_strb_6,
  input          io_downstreamR_operandRead_strb_7,
  input          io_downstreamR_operandRead_strb_8,
  input          io_downstreamR_operandRead_strb_9,
  input          io_downstreamR_operandRead_strb_10,
  input          io_downstreamR_operandRead_strb_11,
  input          io_downstreamR_operandRead_strb_12,
  input          io_downstreamR_operandRead_strb_13,
  input          io_downstreamR_operandRead_strb_14,
  input          io_downstreamR_operandRead_strb_15,
  input          io_downstreamR_operandRead_strb_16,
  input          io_downstreamR_operandRead_strb_17,
  input          io_downstreamR_operandRead_strb_18,
  input          io_downstreamR_operandRead_strb_19,
  input          io_downstreamR_operandRead_strb_20,
  input          io_downstreamR_operandRead_strb_21,
  input          io_downstreamR_operandRead_strb_22,
  input          io_downstreamR_operandRead_strb_23,
  input          io_downstreamR_operandRead_strb_24,
  input          io_downstreamR_operandRead_strb_25,
  input          io_downstreamR_operandRead_strb_26,
  input          io_downstreamR_operandRead_strb_27,
  input          io_downstreamR_operandRead_strb_28,
  input          io_downstreamR_operandRead_strb_29,
  input          io_downstreamR_operandRead_strb_30,
  input          io_downstreamR_operandRead_strb_31,
  output         io_downstreamR_operandRead_bits_Critical_0,
  output         io_downstreamR_operandRead_bits_Critical_1,
  output         io_downstreamR_operandRead_bits_Count,
  input          io_downstreamR_operandAXIWrite_strb_0,
  input          io_downstreamR_operandAXIWrite_strb_1,
  input          io_downstreamR_operandAXIWrite_strb_2,
  input          io_downstreamR_operandAXIWrite_strb_3,
  input          io_downstreamR_operandAXIWrite_strb_4,
  input          io_downstreamR_operandAXIWrite_strb_5,
  input          io_downstreamR_operandAXIWrite_strb_6,
  input          io_downstreamR_operandAXIWrite_strb_7,
  input          io_downstreamR_operandAXIWrite_strb_8,
  input          io_downstreamR_operandAXIWrite_strb_9,
  input          io_downstreamR_operandAXIWrite_strb_10,
  input          io_downstreamR_operandAXIWrite_strb_11,
  input          io_downstreamR_operandAXIWrite_strb_12,
  input          io_downstreamR_operandAXIWrite_strb_13,
  input          io_downstreamR_operandAXIWrite_strb_14,
  input          io_downstreamR_operandAXIWrite_strb_15,
  input          io_downstreamR_operandAXIWrite_strb_16,
  input          io_downstreamR_operandAXIWrite_strb_17,
  input          io_downstreamR_operandAXIWrite_strb_18,
  input          io_downstreamR_operandAXIWrite_strb_19,
  input          io_downstreamR_operandAXIWrite_strb_20,
  input          io_downstreamR_operandAXIWrite_strb_21,
  input          io_downstreamR_operandAXIWrite_strb_22,
  input          io_downstreamR_operandAXIWrite_strb_23,
  input          io_downstreamR_operandAXIWrite_strb_24,
  input          io_downstreamR_operandAXIWrite_strb_25,
  input          io_downstreamR_operandAXIWrite_strb_26,
  input          io_downstreamR_operandAXIWrite_strb_27,
  input          io_downstreamR_operandAXIWrite_strb_28,
  input          io_downstreamR_operandAXIWrite_strb_29,
  input          io_downstreamR_operandAXIWrite_strb_30,
  input          io_downstreamR_operandAXIWrite_strb_31,
  input          io_downstreamR_operandAXIWrite_bits_Critical_0,
  input          io_downstreamR_operandAXIWrite_bits_Critical_1,
  input          io_downstreamR_operandAXIWrite_bits_Count,
  output         debug_DoubleAllocation_0,
  output         debug_DoubleAllocation_1,
  output         debug_DoubleAllocation_2,
  output         debug_DoubleAllocation_3,
  output         debug_DoubleAllocation_4,
  output         debug_DoubleAllocation_5,
  output         debug_DoubleAllocation_6,
  output         debug_DoubleAllocation_7,
  output         debug_DoubleAllocation_8,
  output         debug_DoubleAllocation_9,
  output         debug_DoubleAllocation_10,
  output         debug_DoubleAllocation_11,
  output         debug_DoubleAllocation_12,
  output         debug_DoubleAllocation_13,
  output         debug_DoubleAllocation_14,
  output         debug_DoubleAllocation_15,
  output         debug_DoubleAllocation_16,
  output         debug_DoubleAllocation_17,
  output         debug_DoubleAllocation_18,
  output         debug_DoubleAllocation_19,
  output         debug_DoubleAllocation_20,
  output         debug_DoubleAllocation_21,
  output         debug_DoubleAllocation_22,
  output         debug_DoubleAllocation_23,
  output         debug_DoubleAllocation_24,
  output         debug_DoubleAllocation_25,
  output         debug_DoubleAllocation_26,
  output         debug_DoubleAllocation_27,
  output         debug_DoubleAllocation_28,
  output         debug_DoubleAllocation_29,
  output         debug_DoubleAllocation_30,
  output         debug_DoubleAllocation_31,
  output         debug_DanglingAXIWriteResponse_0,
  output         debug_DanglingAXIWriteResponse_1,
  output         debug_DanglingAXIWriteResponse_2,
  output         debug_DanglingAXIWriteResponse_3,
  output         debug_DanglingAXIWriteResponse_4,
  output         debug_DanglingAXIWriteResponse_5,
  output         debug_DanglingAXIWriteResponse_6,
  output         debug_DanglingAXIWriteResponse_7,
  output         debug_DanglingAXIWriteResponse_8,
  output         debug_DanglingAXIWriteResponse_9,
  output         debug_DanglingAXIWriteResponse_10,
  output         debug_DanglingAXIWriteResponse_11,
  output         debug_DanglingAXIWriteResponse_12,
  output         debug_DanglingAXIWriteResponse_13,
  output         debug_DanglingAXIWriteResponse_14,
  output         debug_DanglingAXIWriteResponse_15,
  output         debug_DanglingAXIWriteResponse_16,
  output         debug_DanglingAXIWriteResponse_17,
  output         debug_DanglingAXIWriteResponse_18,
  output         debug_DanglingAXIWriteResponse_19,
  output         debug_DanglingAXIWriteResponse_20,
  output         debug_DanglingAXIWriteResponse_21,
  output         debug_DanglingAXIWriteResponse_22,
  output         debug_DanglingAXIWriteResponse_23,
  output         debug_DanglingAXIWriteResponse_24,
  output         debug_DanglingAXIWriteResponse_25,
  output         debug_DanglingAXIWriteResponse_26,
  output         debug_DanglingAXIWriteResponse_27,
  output         debug_DanglingAXIWriteResponse_28,
  output         debug_DanglingAXIWriteResponse_29,
  output         debug_DanglingAXIWriteResponse_30,
  output         debug_DanglingAXIWriteResponse_31
);

  // -------------------------------------------------------------------------
  // 本变体参数
  // -------------------------------------------------------------------------
  localparam int N          = 32;
  localparam bit HAS_ORDER  = 1'b0;
  localparam bit HAS_DEVICE = 1'b1;
  localparam bit HAS_AR_BAR = 1'b1;
  localparam int IDX_W      = 5;

  // -------------------------------------------------------------------------
  // 核侧信号声明
  // -------------------------------------------------------------------------

  // 核侧信号（名字与 xs_NCBTransactionQueue_core 的端口一一对应）
  logic [N-1:0]  free_strb;
  logic          alloc_en;
  logic [N-1:0]  alloc_strb;
  // ★位宽写字面值而不是引用核文件里的包★：跨文件共享 package 会制造文件顺序依赖
  // （VCS 报 SV-LCM-PND），本仓 scripts/check_pkg_scope.py 直接判违规。所以
  // ncb_txnq_pkg 只服务核文件自己，wrapper 这边全用字面位宽，并在注释里标出出处。
  logic [12:0]   alloc_op_bits;     // ncb_op_t：13 个 op 位，字段顺序见核文件 §1
  logic [60:0]   alloc_info_bits;   // ncb_info_t：QoS4+TgtID11+SrcID11+TxnID12
                                    //             +ReturnNID11+ReturnTxnID12
  logic [47:0]   alloc_chi_addr;
  logic          alloc_chi_write_full, alloc_chi_write_ptl;
  logic [1:0] alloc_chi_critical;
  logic [0:0]  alloc_chi_count;
  logic [48:0] alloc_axi_addr;
  logic [2:0] alloc_axi_size;
  logic [7:0]  alloc_axi_len;
  logic          alloc_axi_device;
  logic [1:0] alloc_axi_critical;
  logic [0:0]  alloc_axi_count;
  logic          alloc_order_valid;
  logic [IDX_W-1:0] alloc_order_index;

  logic          rxdat_query_en, rxdat_query_valid;
  logic          rxdat_query_write_full, rxdat_query_write_ptl;
  logic [1:0] rxdat_query_read_resp_err, rxdat_query_write_resp_err;
  logic [N-1:0]  rxdat_query_strb, rxdat_cancel_strb, rxdat_write_data_strb;
  logic          rxdat_cancel_en, rxdat_write_data_en;

  logic [N-1:0]  txrsp_op_valid, txrsp_op_read_strb, txrsp_op_done_strb;
  logic [N-1:0]  txrsp_info_read_strb;
  logic          txrsp_op_read_comp, txrsp_op_read_dbidresp;
  logic          txrsp_op_read_compdbidresp, txrsp_op_read_readreceipt;
  logic          txrsp_op_done_comp, txrsp_op_done_dbidresp;
  logic          txrsp_op_done_compdbidresp, txrsp_op_done_readreceipt;
  logic [37:0] txrsp_info_read_bits;
  logic [1:0] txrsp_operand_write_resp_err;

  logic [N-1:0]  txdat_op_valid, txdat_op_read_strb, txdat_op_done_strb;
  logic [N-1:0]  txdat_info_read_strb, txdat_operand_read_strb, txdat_operand_write_strb;
  logic [N-1:0][1:0] txdat_op_valid_critical;
  logic          txdat_op_read_compdata_valid, txdat_op_read_compdata_sep;
  logic          txdat_op_done_compdata;
  logic [37:0] txdat_info_read_bits;
  logic [47:0] txdat_operand_read_addr;
  logic [1:0]  txdat_operand_read_read_resp_err;
  logic [1:0] txdat_operand_read_critical, txdat_operand_write_critical;
  logic [0:0]  txdat_operand_read_count, txdat_operand_write_count;

  logic [N-1:0]  aw_op_valid, aw_op_ponr_strb, aw_info_read_strb, aw_operand_read_strb;
  logic [3:0] aw_info_read_qos;
  logic [48:0]  aw_operand_read_addr;
  logic [1:0] aw_operand_read_burst;
  logic [2:0]  aw_operand_read_size;
  logic [7:0]   aw_operand_read_len;

  logic [N-1:0]  w_op_ponr_strb, w_operand_read_strb, w_operand_write_strb;
  logic [1:0] w_operand_read_critical, w_operand_write_critical;
  logic [0:0]  w_operand_read_count, w_operand_write_count;

  logic [N-1:0]  b_op_done_strb;

  logic [N-1:0]  ar_op_valid, ar_op_ponr_strb, ar_op_done_strb;
  logic [N-1:0]  ar_info_read_strb, ar_operand_read_strb;
  logic [3:0] ar_info_read_qos;
  logic [48:0]  ar_operand_read_addr;
  logic [1:0] ar_operand_read_burst;
  logic [2:0]  ar_operand_read_size;
  logic [7:0]   ar_operand_read_len;
  logic                   ar_operand_read_device;

  logic [N-1:0]  r_op_done_strb, r_operand_read_strb, r_operand_axi_write_strb;
  logic [1:0] r_operand_read_critical, r_operand_axi_write_critical;
  logic [0:0]  r_operand_read_count, r_operand_axi_write_count;

  logic [N-1:0]  dbg_double_allocation, dbg_dangling_axi_write_response;

  // -------------------------------------------------------------------------
  // 输入：逐槽展平的 golden 端口收成 N 位向量
  // -------------------------------------------------------------------------
  assign alloc_strb = {
      io_allocate_strb_31,
      io_allocate_strb_30,
      io_allocate_strb_29,
      io_allocate_strb_28,
      io_allocate_strb_27,
      io_allocate_strb_26,
      io_allocate_strb_25,
      io_allocate_strb_24,
      io_allocate_strb_23,
      io_allocate_strb_22,
      io_allocate_strb_21,
      io_allocate_strb_20,
      io_allocate_strb_19,
      io_allocate_strb_18,
      io_allocate_strb_17,
      io_allocate_strb_16,
      io_allocate_strb_15,
      io_allocate_strb_14,
      io_allocate_strb_13,
      io_allocate_strb_12,
      io_allocate_strb_11,
      io_allocate_strb_10,
      io_allocate_strb_9,
      io_allocate_strb_8,
      io_allocate_strb_7,
      io_allocate_strb_6,
      io_allocate_strb_5,
      io_allocate_strb_4,
      io_allocate_strb_3,
      io_allocate_strb_2,
      io_allocate_strb_1,
      io_allocate_strb_0};
  assign rxdat_query_strb = {
      io_upstreamRxDat_query_strb_31,
      io_upstreamRxDat_query_strb_30,
      io_upstreamRxDat_query_strb_29,
      io_upstreamRxDat_query_strb_28,
      io_upstreamRxDat_query_strb_27,
      io_upstreamRxDat_query_strb_26,
      io_upstreamRxDat_query_strb_25,
      io_upstreamRxDat_query_strb_24,
      io_upstreamRxDat_query_strb_23,
      io_upstreamRxDat_query_strb_22,
      io_upstreamRxDat_query_strb_21,
      io_upstreamRxDat_query_strb_20,
      io_upstreamRxDat_query_strb_19,
      io_upstreamRxDat_query_strb_18,
      io_upstreamRxDat_query_strb_17,
      io_upstreamRxDat_query_strb_16,
      io_upstreamRxDat_query_strb_15,
      io_upstreamRxDat_query_strb_14,
      io_upstreamRxDat_query_strb_13,
      io_upstreamRxDat_query_strb_12,
      io_upstreamRxDat_query_strb_11,
      io_upstreamRxDat_query_strb_10,
      io_upstreamRxDat_query_strb_9,
      io_upstreamRxDat_query_strb_8,
      io_upstreamRxDat_query_strb_7,
      io_upstreamRxDat_query_strb_6,
      io_upstreamRxDat_query_strb_5,
      io_upstreamRxDat_query_strb_4,
      io_upstreamRxDat_query_strb_3,
      io_upstreamRxDat_query_strb_2,
      io_upstreamRxDat_query_strb_1,
      io_upstreamRxDat_query_strb_0};
  assign rxdat_cancel_strb = {
      io_upstreamRxDat_cancel_strb_31,
      io_upstreamRxDat_cancel_strb_30,
      io_upstreamRxDat_cancel_strb_29,
      io_upstreamRxDat_cancel_strb_28,
      io_upstreamRxDat_cancel_strb_27,
      io_upstreamRxDat_cancel_strb_26,
      io_upstreamRxDat_cancel_strb_25,
      io_upstreamRxDat_cancel_strb_24,
      io_upstreamRxDat_cancel_strb_23,
      io_upstreamRxDat_cancel_strb_22,
      io_upstreamRxDat_cancel_strb_21,
      io_upstreamRxDat_cancel_strb_20,
      io_upstreamRxDat_cancel_strb_19,
      io_upstreamRxDat_cancel_strb_18,
      io_upstreamRxDat_cancel_strb_17,
      io_upstreamRxDat_cancel_strb_16,
      io_upstreamRxDat_cancel_strb_15,
      io_upstreamRxDat_cancel_strb_14,
      io_upstreamRxDat_cancel_strb_13,
      io_upstreamRxDat_cancel_strb_12,
      io_upstreamRxDat_cancel_strb_11,
      io_upstreamRxDat_cancel_strb_10,
      io_upstreamRxDat_cancel_strb_9,
      io_upstreamRxDat_cancel_strb_8,
      io_upstreamRxDat_cancel_strb_7,
      io_upstreamRxDat_cancel_strb_6,
      io_upstreamRxDat_cancel_strb_5,
      io_upstreamRxDat_cancel_strb_4,
      io_upstreamRxDat_cancel_strb_3,
      io_upstreamRxDat_cancel_strb_2,
      io_upstreamRxDat_cancel_strb_1,
      io_upstreamRxDat_cancel_strb_0};
  assign rxdat_write_data_strb = {
      io_upstreamRxDat_writeData_strb_31,
      io_upstreamRxDat_writeData_strb_30,
      io_upstreamRxDat_writeData_strb_29,
      io_upstreamRxDat_writeData_strb_28,
      io_upstreamRxDat_writeData_strb_27,
      io_upstreamRxDat_writeData_strb_26,
      io_upstreamRxDat_writeData_strb_25,
      io_upstreamRxDat_writeData_strb_24,
      io_upstreamRxDat_writeData_strb_23,
      io_upstreamRxDat_writeData_strb_22,
      io_upstreamRxDat_writeData_strb_21,
      io_upstreamRxDat_writeData_strb_20,
      io_upstreamRxDat_writeData_strb_19,
      io_upstreamRxDat_writeData_strb_18,
      io_upstreamRxDat_writeData_strb_17,
      io_upstreamRxDat_writeData_strb_16,
      io_upstreamRxDat_writeData_strb_15,
      io_upstreamRxDat_writeData_strb_14,
      io_upstreamRxDat_writeData_strb_13,
      io_upstreamRxDat_writeData_strb_12,
      io_upstreamRxDat_writeData_strb_11,
      io_upstreamRxDat_writeData_strb_10,
      io_upstreamRxDat_writeData_strb_9,
      io_upstreamRxDat_writeData_strb_8,
      io_upstreamRxDat_writeData_strb_7,
      io_upstreamRxDat_writeData_strb_6,
      io_upstreamRxDat_writeData_strb_5,
      io_upstreamRxDat_writeData_strb_4,
      io_upstreamRxDat_writeData_strb_3,
      io_upstreamRxDat_writeData_strb_2,
      io_upstreamRxDat_writeData_strb_1,
      io_upstreamRxDat_writeData_strb_0};
  assign txrsp_op_read_strb = {
      io_upstreamTxRsp_opRead_strb_31,
      io_upstreamTxRsp_opRead_strb_30,
      io_upstreamTxRsp_opRead_strb_29,
      io_upstreamTxRsp_opRead_strb_28,
      io_upstreamTxRsp_opRead_strb_27,
      io_upstreamTxRsp_opRead_strb_26,
      io_upstreamTxRsp_opRead_strb_25,
      io_upstreamTxRsp_opRead_strb_24,
      io_upstreamTxRsp_opRead_strb_23,
      io_upstreamTxRsp_opRead_strb_22,
      io_upstreamTxRsp_opRead_strb_21,
      io_upstreamTxRsp_opRead_strb_20,
      io_upstreamTxRsp_opRead_strb_19,
      io_upstreamTxRsp_opRead_strb_18,
      io_upstreamTxRsp_opRead_strb_17,
      io_upstreamTxRsp_opRead_strb_16,
      io_upstreamTxRsp_opRead_strb_15,
      io_upstreamTxRsp_opRead_strb_14,
      io_upstreamTxRsp_opRead_strb_13,
      io_upstreamTxRsp_opRead_strb_12,
      io_upstreamTxRsp_opRead_strb_11,
      io_upstreamTxRsp_opRead_strb_10,
      io_upstreamTxRsp_opRead_strb_9,
      io_upstreamTxRsp_opRead_strb_8,
      io_upstreamTxRsp_opRead_strb_7,
      io_upstreamTxRsp_opRead_strb_6,
      io_upstreamTxRsp_opRead_strb_5,
      io_upstreamTxRsp_opRead_strb_4,
      io_upstreamTxRsp_opRead_strb_3,
      io_upstreamTxRsp_opRead_strb_2,
      io_upstreamTxRsp_opRead_strb_1,
      io_upstreamTxRsp_opRead_strb_0};
  assign txrsp_op_done_strb = {
      io_upstreamTxRsp_opDone_strb_31,
      io_upstreamTxRsp_opDone_strb_30,
      io_upstreamTxRsp_opDone_strb_29,
      io_upstreamTxRsp_opDone_strb_28,
      io_upstreamTxRsp_opDone_strb_27,
      io_upstreamTxRsp_opDone_strb_26,
      io_upstreamTxRsp_opDone_strb_25,
      io_upstreamTxRsp_opDone_strb_24,
      io_upstreamTxRsp_opDone_strb_23,
      io_upstreamTxRsp_opDone_strb_22,
      io_upstreamTxRsp_opDone_strb_21,
      io_upstreamTxRsp_opDone_strb_20,
      io_upstreamTxRsp_opDone_strb_19,
      io_upstreamTxRsp_opDone_strb_18,
      io_upstreamTxRsp_opDone_strb_17,
      io_upstreamTxRsp_opDone_strb_16,
      io_upstreamTxRsp_opDone_strb_15,
      io_upstreamTxRsp_opDone_strb_14,
      io_upstreamTxRsp_opDone_strb_13,
      io_upstreamTxRsp_opDone_strb_12,
      io_upstreamTxRsp_opDone_strb_11,
      io_upstreamTxRsp_opDone_strb_10,
      io_upstreamTxRsp_opDone_strb_9,
      io_upstreamTxRsp_opDone_strb_8,
      io_upstreamTxRsp_opDone_strb_7,
      io_upstreamTxRsp_opDone_strb_6,
      io_upstreamTxRsp_opDone_strb_5,
      io_upstreamTxRsp_opDone_strb_4,
      io_upstreamTxRsp_opDone_strb_3,
      io_upstreamTxRsp_opDone_strb_2,
      io_upstreamTxRsp_opDone_strb_1,
      io_upstreamTxRsp_opDone_strb_0};
  assign txrsp_info_read_strb = {
      io_upstreamTxRsp_infoRead_strb_31,
      io_upstreamTxRsp_infoRead_strb_30,
      io_upstreamTxRsp_infoRead_strb_29,
      io_upstreamTxRsp_infoRead_strb_28,
      io_upstreamTxRsp_infoRead_strb_27,
      io_upstreamTxRsp_infoRead_strb_26,
      io_upstreamTxRsp_infoRead_strb_25,
      io_upstreamTxRsp_infoRead_strb_24,
      io_upstreamTxRsp_infoRead_strb_23,
      io_upstreamTxRsp_infoRead_strb_22,
      io_upstreamTxRsp_infoRead_strb_21,
      io_upstreamTxRsp_infoRead_strb_20,
      io_upstreamTxRsp_infoRead_strb_19,
      io_upstreamTxRsp_infoRead_strb_18,
      io_upstreamTxRsp_infoRead_strb_17,
      io_upstreamTxRsp_infoRead_strb_16,
      io_upstreamTxRsp_infoRead_strb_15,
      io_upstreamTxRsp_infoRead_strb_14,
      io_upstreamTxRsp_infoRead_strb_13,
      io_upstreamTxRsp_infoRead_strb_12,
      io_upstreamTxRsp_infoRead_strb_11,
      io_upstreamTxRsp_infoRead_strb_10,
      io_upstreamTxRsp_infoRead_strb_9,
      io_upstreamTxRsp_infoRead_strb_8,
      io_upstreamTxRsp_infoRead_strb_7,
      io_upstreamTxRsp_infoRead_strb_6,
      io_upstreamTxRsp_infoRead_strb_5,
      io_upstreamTxRsp_infoRead_strb_4,
      io_upstreamTxRsp_infoRead_strb_3,
      io_upstreamTxRsp_infoRead_strb_2,
      io_upstreamTxRsp_infoRead_strb_1,
      io_upstreamTxRsp_infoRead_strb_0};
  assign txdat_op_read_strb = {
      io_upstreamTxDat_opRead_strb_31,
      io_upstreamTxDat_opRead_strb_30,
      io_upstreamTxDat_opRead_strb_29,
      io_upstreamTxDat_opRead_strb_28,
      io_upstreamTxDat_opRead_strb_27,
      io_upstreamTxDat_opRead_strb_26,
      io_upstreamTxDat_opRead_strb_25,
      io_upstreamTxDat_opRead_strb_24,
      io_upstreamTxDat_opRead_strb_23,
      io_upstreamTxDat_opRead_strb_22,
      io_upstreamTxDat_opRead_strb_21,
      io_upstreamTxDat_opRead_strb_20,
      io_upstreamTxDat_opRead_strb_19,
      io_upstreamTxDat_opRead_strb_18,
      io_upstreamTxDat_opRead_strb_17,
      io_upstreamTxDat_opRead_strb_16,
      io_upstreamTxDat_opRead_strb_15,
      io_upstreamTxDat_opRead_strb_14,
      io_upstreamTxDat_opRead_strb_13,
      io_upstreamTxDat_opRead_strb_12,
      io_upstreamTxDat_opRead_strb_11,
      io_upstreamTxDat_opRead_strb_10,
      io_upstreamTxDat_opRead_strb_9,
      io_upstreamTxDat_opRead_strb_8,
      io_upstreamTxDat_opRead_strb_7,
      io_upstreamTxDat_opRead_strb_6,
      io_upstreamTxDat_opRead_strb_5,
      io_upstreamTxDat_opRead_strb_4,
      io_upstreamTxDat_opRead_strb_3,
      io_upstreamTxDat_opRead_strb_2,
      io_upstreamTxDat_opRead_strb_1,
      io_upstreamTxDat_opRead_strb_0};
  assign txdat_op_done_strb = {
      io_upstreamTxDat_opDone_strb_31,
      io_upstreamTxDat_opDone_strb_30,
      io_upstreamTxDat_opDone_strb_29,
      io_upstreamTxDat_opDone_strb_28,
      io_upstreamTxDat_opDone_strb_27,
      io_upstreamTxDat_opDone_strb_26,
      io_upstreamTxDat_opDone_strb_25,
      io_upstreamTxDat_opDone_strb_24,
      io_upstreamTxDat_opDone_strb_23,
      io_upstreamTxDat_opDone_strb_22,
      io_upstreamTxDat_opDone_strb_21,
      io_upstreamTxDat_opDone_strb_20,
      io_upstreamTxDat_opDone_strb_19,
      io_upstreamTxDat_opDone_strb_18,
      io_upstreamTxDat_opDone_strb_17,
      io_upstreamTxDat_opDone_strb_16,
      io_upstreamTxDat_opDone_strb_15,
      io_upstreamTxDat_opDone_strb_14,
      io_upstreamTxDat_opDone_strb_13,
      io_upstreamTxDat_opDone_strb_12,
      io_upstreamTxDat_opDone_strb_11,
      io_upstreamTxDat_opDone_strb_10,
      io_upstreamTxDat_opDone_strb_9,
      io_upstreamTxDat_opDone_strb_8,
      io_upstreamTxDat_opDone_strb_7,
      io_upstreamTxDat_opDone_strb_6,
      io_upstreamTxDat_opDone_strb_5,
      io_upstreamTxDat_opDone_strb_4,
      io_upstreamTxDat_opDone_strb_3,
      io_upstreamTxDat_opDone_strb_2,
      io_upstreamTxDat_opDone_strb_1,
      io_upstreamTxDat_opDone_strb_0};
  assign txdat_info_read_strb = {
      io_upstreamTxDat_infoRead_strb_31,
      io_upstreamTxDat_infoRead_strb_30,
      io_upstreamTxDat_infoRead_strb_29,
      io_upstreamTxDat_infoRead_strb_28,
      io_upstreamTxDat_infoRead_strb_27,
      io_upstreamTxDat_infoRead_strb_26,
      io_upstreamTxDat_infoRead_strb_25,
      io_upstreamTxDat_infoRead_strb_24,
      io_upstreamTxDat_infoRead_strb_23,
      io_upstreamTxDat_infoRead_strb_22,
      io_upstreamTxDat_infoRead_strb_21,
      io_upstreamTxDat_infoRead_strb_20,
      io_upstreamTxDat_infoRead_strb_19,
      io_upstreamTxDat_infoRead_strb_18,
      io_upstreamTxDat_infoRead_strb_17,
      io_upstreamTxDat_infoRead_strb_16,
      io_upstreamTxDat_infoRead_strb_15,
      io_upstreamTxDat_infoRead_strb_14,
      io_upstreamTxDat_infoRead_strb_13,
      io_upstreamTxDat_infoRead_strb_12,
      io_upstreamTxDat_infoRead_strb_11,
      io_upstreamTxDat_infoRead_strb_10,
      io_upstreamTxDat_infoRead_strb_9,
      io_upstreamTxDat_infoRead_strb_8,
      io_upstreamTxDat_infoRead_strb_7,
      io_upstreamTxDat_infoRead_strb_6,
      io_upstreamTxDat_infoRead_strb_5,
      io_upstreamTxDat_infoRead_strb_4,
      io_upstreamTxDat_infoRead_strb_3,
      io_upstreamTxDat_infoRead_strb_2,
      io_upstreamTxDat_infoRead_strb_1,
      io_upstreamTxDat_infoRead_strb_0};
  assign txdat_operand_read_strb = {
      io_upstreamTxDat_operandRead_strb_31,
      io_upstreamTxDat_operandRead_strb_30,
      io_upstreamTxDat_operandRead_strb_29,
      io_upstreamTxDat_operandRead_strb_28,
      io_upstreamTxDat_operandRead_strb_27,
      io_upstreamTxDat_operandRead_strb_26,
      io_upstreamTxDat_operandRead_strb_25,
      io_upstreamTxDat_operandRead_strb_24,
      io_upstreamTxDat_operandRead_strb_23,
      io_upstreamTxDat_operandRead_strb_22,
      io_upstreamTxDat_operandRead_strb_21,
      io_upstreamTxDat_operandRead_strb_20,
      io_upstreamTxDat_operandRead_strb_19,
      io_upstreamTxDat_operandRead_strb_18,
      io_upstreamTxDat_operandRead_strb_17,
      io_upstreamTxDat_operandRead_strb_16,
      io_upstreamTxDat_operandRead_strb_15,
      io_upstreamTxDat_operandRead_strb_14,
      io_upstreamTxDat_operandRead_strb_13,
      io_upstreamTxDat_operandRead_strb_12,
      io_upstreamTxDat_operandRead_strb_11,
      io_upstreamTxDat_operandRead_strb_10,
      io_upstreamTxDat_operandRead_strb_9,
      io_upstreamTxDat_operandRead_strb_8,
      io_upstreamTxDat_operandRead_strb_7,
      io_upstreamTxDat_operandRead_strb_6,
      io_upstreamTxDat_operandRead_strb_5,
      io_upstreamTxDat_operandRead_strb_4,
      io_upstreamTxDat_operandRead_strb_3,
      io_upstreamTxDat_operandRead_strb_2,
      io_upstreamTxDat_operandRead_strb_1,
      io_upstreamTxDat_operandRead_strb_0};
  assign txdat_operand_write_strb = {
      io_upstreamTxDat_operandWrite_strb_31,
      io_upstreamTxDat_operandWrite_strb_30,
      io_upstreamTxDat_operandWrite_strb_29,
      io_upstreamTxDat_operandWrite_strb_28,
      io_upstreamTxDat_operandWrite_strb_27,
      io_upstreamTxDat_operandWrite_strb_26,
      io_upstreamTxDat_operandWrite_strb_25,
      io_upstreamTxDat_operandWrite_strb_24,
      io_upstreamTxDat_operandWrite_strb_23,
      io_upstreamTxDat_operandWrite_strb_22,
      io_upstreamTxDat_operandWrite_strb_21,
      io_upstreamTxDat_operandWrite_strb_20,
      io_upstreamTxDat_operandWrite_strb_19,
      io_upstreamTxDat_operandWrite_strb_18,
      io_upstreamTxDat_operandWrite_strb_17,
      io_upstreamTxDat_operandWrite_strb_16,
      io_upstreamTxDat_operandWrite_strb_15,
      io_upstreamTxDat_operandWrite_strb_14,
      io_upstreamTxDat_operandWrite_strb_13,
      io_upstreamTxDat_operandWrite_strb_12,
      io_upstreamTxDat_operandWrite_strb_11,
      io_upstreamTxDat_operandWrite_strb_10,
      io_upstreamTxDat_operandWrite_strb_9,
      io_upstreamTxDat_operandWrite_strb_8,
      io_upstreamTxDat_operandWrite_strb_7,
      io_upstreamTxDat_operandWrite_strb_6,
      io_upstreamTxDat_operandWrite_strb_5,
      io_upstreamTxDat_operandWrite_strb_4,
      io_upstreamTxDat_operandWrite_strb_3,
      io_upstreamTxDat_operandWrite_strb_2,
      io_upstreamTxDat_operandWrite_strb_1,
      io_upstreamTxDat_operandWrite_strb_0};
  assign aw_op_ponr_strb = {
      io_downstreamAw_opPoNR_strb_31,
      io_downstreamAw_opPoNR_strb_30,
      io_downstreamAw_opPoNR_strb_29,
      io_downstreamAw_opPoNR_strb_28,
      io_downstreamAw_opPoNR_strb_27,
      io_downstreamAw_opPoNR_strb_26,
      io_downstreamAw_opPoNR_strb_25,
      io_downstreamAw_opPoNR_strb_24,
      io_downstreamAw_opPoNR_strb_23,
      io_downstreamAw_opPoNR_strb_22,
      io_downstreamAw_opPoNR_strb_21,
      io_downstreamAw_opPoNR_strb_20,
      io_downstreamAw_opPoNR_strb_19,
      io_downstreamAw_opPoNR_strb_18,
      io_downstreamAw_opPoNR_strb_17,
      io_downstreamAw_opPoNR_strb_16,
      io_downstreamAw_opPoNR_strb_15,
      io_downstreamAw_opPoNR_strb_14,
      io_downstreamAw_opPoNR_strb_13,
      io_downstreamAw_opPoNR_strb_12,
      io_downstreamAw_opPoNR_strb_11,
      io_downstreamAw_opPoNR_strb_10,
      io_downstreamAw_opPoNR_strb_9,
      io_downstreamAw_opPoNR_strb_8,
      io_downstreamAw_opPoNR_strb_7,
      io_downstreamAw_opPoNR_strb_6,
      io_downstreamAw_opPoNR_strb_5,
      io_downstreamAw_opPoNR_strb_4,
      io_downstreamAw_opPoNR_strb_3,
      io_downstreamAw_opPoNR_strb_2,
      io_downstreamAw_opPoNR_strb_1,
      io_downstreamAw_opPoNR_strb_0};
  assign aw_info_read_strb = {
      io_downstreamAw_infoRead_strb_31,
      io_downstreamAw_infoRead_strb_30,
      io_downstreamAw_infoRead_strb_29,
      io_downstreamAw_infoRead_strb_28,
      io_downstreamAw_infoRead_strb_27,
      io_downstreamAw_infoRead_strb_26,
      io_downstreamAw_infoRead_strb_25,
      io_downstreamAw_infoRead_strb_24,
      io_downstreamAw_infoRead_strb_23,
      io_downstreamAw_infoRead_strb_22,
      io_downstreamAw_infoRead_strb_21,
      io_downstreamAw_infoRead_strb_20,
      io_downstreamAw_infoRead_strb_19,
      io_downstreamAw_infoRead_strb_18,
      io_downstreamAw_infoRead_strb_17,
      io_downstreamAw_infoRead_strb_16,
      io_downstreamAw_infoRead_strb_15,
      io_downstreamAw_infoRead_strb_14,
      io_downstreamAw_infoRead_strb_13,
      io_downstreamAw_infoRead_strb_12,
      io_downstreamAw_infoRead_strb_11,
      io_downstreamAw_infoRead_strb_10,
      io_downstreamAw_infoRead_strb_9,
      io_downstreamAw_infoRead_strb_8,
      io_downstreamAw_infoRead_strb_7,
      io_downstreamAw_infoRead_strb_6,
      io_downstreamAw_infoRead_strb_5,
      io_downstreamAw_infoRead_strb_4,
      io_downstreamAw_infoRead_strb_3,
      io_downstreamAw_infoRead_strb_2,
      io_downstreamAw_infoRead_strb_1,
      io_downstreamAw_infoRead_strb_0};
  assign aw_operand_read_strb = {
      io_downstreamAw_operandRead_strb_31,
      io_downstreamAw_operandRead_strb_30,
      io_downstreamAw_operandRead_strb_29,
      io_downstreamAw_operandRead_strb_28,
      io_downstreamAw_operandRead_strb_27,
      io_downstreamAw_operandRead_strb_26,
      io_downstreamAw_operandRead_strb_25,
      io_downstreamAw_operandRead_strb_24,
      io_downstreamAw_operandRead_strb_23,
      io_downstreamAw_operandRead_strb_22,
      io_downstreamAw_operandRead_strb_21,
      io_downstreamAw_operandRead_strb_20,
      io_downstreamAw_operandRead_strb_19,
      io_downstreamAw_operandRead_strb_18,
      io_downstreamAw_operandRead_strb_17,
      io_downstreamAw_operandRead_strb_16,
      io_downstreamAw_operandRead_strb_15,
      io_downstreamAw_operandRead_strb_14,
      io_downstreamAw_operandRead_strb_13,
      io_downstreamAw_operandRead_strb_12,
      io_downstreamAw_operandRead_strb_11,
      io_downstreamAw_operandRead_strb_10,
      io_downstreamAw_operandRead_strb_9,
      io_downstreamAw_operandRead_strb_8,
      io_downstreamAw_operandRead_strb_7,
      io_downstreamAw_operandRead_strb_6,
      io_downstreamAw_operandRead_strb_5,
      io_downstreamAw_operandRead_strb_4,
      io_downstreamAw_operandRead_strb_3,
      io_downstreamAw_operandRead_strb_2,
      io_downstreamAw_operandRead_strb_1,
      io_downstreamAw_operandRead_strb_0};
  assign w_op_ponr_strb = {
      io_downstreamW_opPoNR_strb_31,
      io_downstreamW_opPoNR_strb_30,
      io_downstreamW_opPoNR_strb_29,
      io_downstreamW_opPoNR_strb_28,
      io_downstreamW_opPoNR_strb_27,
      io_downstreamW_opPoNR_strb_26,
      io_downstreamW_opPoNR_strb_25,
      io_downstreamW_opPoNR_strb_24,
      io_downstreamW_opPoNR_strb_23,
      io_downstreamW_opPoNR_strb_22,
      io_downstreamW_opPoNR_strb_21,
      io_downstreamW_opPoNR_strb_20,
      io_downstreamW_opPoNR_strb_19,
      io_downstreamW_opPoNR_strb_18,
      io_downstreamW_opPoNR_strb_17,
      io_downstreamW_opPoNR_strb_16,
      io_downstreamW_opPoNR_strb_15,
      io_downstreamW_opPoNR_strb_14,
      io_downstreamW_opPoNR_strb_13,
      io_downstreamW_opPoNR_strb_12,
      io_downstreamW_opPoNR_strb_11,
      io_downstreamW_opPoNR_strb_10,
      io_downstreamW_opPoNR_strb_9,
      io_downstreamW_opPoNR_strb_8,
      io_downstreamW_opPoNR_strb_7,
      io_downstreamW_opPoNR_strb_6,
      io_downstreamW_opPoNR_strb_5,
      io_downstreamW_opPoNR_strb_4,
      io_downstreamW_opPoNR_strb_3,
      io_downstreamW_opPoNR_strb_2,
      io_downstreamW_opPoNR_strb_1,
      io_downstreamW_opPoNR_strb_0};
  assign w_operand_read_strb = {
      io_downstreamW_operandRead_strb_31,
      io_downstreamW_operandRead_strb_30,
      io_downstreamW_operandRead_strb_29,
      io_downstreamW_operandRead_strb_28,
      io_downstreamW_operandRead_strb_27,
      io_downstreamW_operandRead_strb_26,
      io_downstreamW_operandRead_strb_25,
      io_downstreamW_operandRead_strb_24,
      io_downstreamW_operandRead_strb_23,
      io_downstreamW_operandRead_strb_22,
      io_downstreamW_operandRead_strb_21,
      io_downstreamW_operandRead_strb_20,
      io_downstreamW_operandRead_strb_19,
      io_downstreamW_operandRead_strb_18,
      io_downstreamW_operandRead_strb_17,
      io_downstreamW_operandRead_strb_16,
      io_downstreamW_operandRead_strb_15,
      io_downstreamW_operandRead_strb_14,
      io_downstreamW_operandRead_strb_13,
      io_downstreamW_operandRead_strb_12,
      io_downstreamW_operandRead_strb_11,
      io_downstreamW_operandRead_strb_10,
      io_downstreamW_operandRead_strb_9,
      io_downstreamW_operandRead_strb_8,
      io_downstreamW_operandRead_strb_7,
      io_downstreamW_operandRead_strb_6,
      io_downstreamW_operandRead_strb_5,
      io_downstreamW_operandRead_strb_4,
      io_downstreamW_operandRead_strb_3,
      io_downstreamW_operandRead_strb_2,
      io_downstreamW_operandRead_strb_1,
      io_downstreamW_operandRead_strb_0};
  assign w_operand_write_strb = {
      io_downstreamW_operandWrite_strb_31,
      io_downstreamW_operandWrite_strb_30,
      io_downstreamW_operandWrite_strb_29,
      io_downstreamW_operandWrite_strb_28,
      io_downstreamW_operandWrite_strb_27,
      io_downstreamW_operandWrite_strb_26,
      io_downstreamW_operandWrite_strb_25,
      io_downstreamW_operandWrite_strb_24,
      io_downstreamW_operandWrite_strb_23,
      io_downstreamW_operandWrite_strb_22,
      io_downstreamW_operandWrite_strb_21,
      io_downstreamW_operandWrite_strb_20,
      io_downstreamW_operandWrite_strb_19,
      io_downstreamW_operandWrite_strb_18,
      io_downstreamW_operandWrite_strb_17,
      io_downstreamW_operandWrite_strb_16,
      io_downstreamW_operandWrite_strb_15,
      io_downstreamW_operandWrite_strb_14,
      io_downstreamW_operandWrite_strb_13,
      io_downstreamW_operandWrite_strb_12,
      io_downstreamW_operandWrite_strb_11,
      io_downstreamW_operandWrite_strb_10,
      io_downstreamW_operandWrite_strb_9,
      io_downstreamW_operandWrite_strb_8,
      io_downstreamW_operandWrite_strb_7,
      io_downstreamW_operandWrite_strb_6,
      io_downstreamW_operandWrite_strb_5,
      io_downstreamW_operandWrite_strb_4,
      io_downstreamW_operandWrite_strb_3,
      io_downstreamW_operandWrite_strb_2,
      io_downstreamW_operandWrite_strb_1,
      io_downstreamW_operandWrite_strb_0};
  assign b_op_done_strb = {
      io_downstreamB_opDone_strb_31,
      io_downstreamB_opDone_strb_30,
      io_downstreamB_opDone_strb_29,
      io_downstreamB_opDone_strb_28,
      io_downstreamB_opDone_strb_27,
      io_downstreamB_opDone_strb_26,
      io_downstreamB_opDone_strb_25,
      io_downstreamB_opDone_strb_24,
      io_downstreamB_opDone_strb_23,
      io_downstreamB_opDone_strb_22,
      io_downstreamB_opDone_strb_21,
      io_downstreamB_opDone_strb_20,
      io_downstreamB_opDone_strb_19,
      io_downstreamB_opDone_strb_18,
      io_downstreamB_opDone_strb_17,
      io_downstreamB_opDone_strb_16,
      io_downstreamB_opDone_strb_15,
      io_downstreamB_opDone_strb_14,
      io_downstreamB_opDone_strb_13,
      io_downstreamB_opDone_strb_12,
      io_downstreamB_opDone_strb_11,
      io_downstreamB_opDone_strb_10,
      io_downstreamB_opDone_strb_9,
      io_downstreamB_opDone_strb_8,
      io_downstreamB_opDone_strb_7,
      io_downstreamB_opDone_strb_6,
      io_downstreamB_opDone_strb_5,
      io_downstreamB_opDone_strb_4,
      io_downstreamB_opDone_strb_3,
      io_downstreamB_opDone_strb_2,
      io_downstreamB_opDone_strb_1,
      io_downstreamB_opDone_strb_0};
  assign ar_op_ponr_strb = {
      io_downstreamAr_opPoNR_strb_31,
      io_downstreamAr_opPoNR_strb_30,
      io_downstreamAr_opPoNR_strb_29,
      io_downstreamAr_opPoNR_strb_28,
      io_downstreamAr_opPoNR_strb_27,
      io_downstreamAr_opPoNR_strb_26,
      io_downstreamAr_opPoNR_strb_25,
      io_downstreamAr_opPoNR_strb_24,
      io_downstreamAr_opPoNR_strb_23,
      io_downstreamAr_opPoNR_strb_22,
      io_downstreamAr_opPoNR_strb_21,
      io_downstreamAr_opPoNR_strb_20,
      io_downstreamAr_opPoNR_strb_19,
      io_downstreamAr_opPoNR_strb_18,
      io_downstreamAr_opPoNR_strb_17,
      io_downstreamAr_opPoNR_strb_16,
      io_downstreamAr_opPoNR_strb_15,
      io_downstreamAr_opPoNR_strb_14,
      io_downstreamAr_opPoNR_strb_13,
      io_downstreamAr_opPoNR_strb_12,
      io_downstreamAr_opPoNR_strb_11,
      io_downstreamAr_opPoNR_strb_10,
      io_downstreamAr_opPoNR_strb_9,
      io_downstreamAr_opPoNR_strb_8,
      io_downstreamAr_opPoNR_strb_7,
      io_downstreamAr_opPoNR_strb_6,
      io_downstreamAr_opPoNR_strb_5,
      io_downstreamAr_opPoNR_strb_4,
      io_downstreamAr_opPoNR_strb_3,
      io_downstreamAr_opPoNR_strb_2,
      io_downstreamAr_opPoNR_strb_1,
      io_downstreamAr_opPoNR_strb_0};
  assign ar_op_done_strb = {
      io_downstreamAr_opDone_strb_31,
      io_downstreamAr_opDone_strb_30,
      io_downstreamAr_opDone_strb_29,
      io_downstreamAr_opDone_strb_28,
      io_downstreamAr_opDone_strb_27,
      io_downstreamAr_opDone_strb_26,
      io_downstreamAr_opDone_strb_25,
      io_downstreamAr_opDone_strb_24,
      io_downstreamAr_opDone_strb_23,
      io_downstreamAr_opDone_strb_22,
      io_downstreamAr_opDone_strb_21,
      io_downstreamAr_opDone_strb_20,
      io_downstreamAr_opDone_strb_19,
      io_downstreamAr_opDone_strb_18,
      io_downstreamAr_opDone_strb_17,
      io_downstreamAr_opDone_strb_16,
      io_downstreamAr_opDone_strb_15,
      io_downstreamAr_opDone_strb_14,
      io_downstreamAr_opDone_strb_13,
      io_downstreamAr_opDone_strb_12,
      io_downstreamAr_opDone_strb_11,
      io_downstreamAr_opDone_strb_10,
      io_downstreamAr_opDone_strb_9,
      io_downstreamAr_opDone_strb_8,
      io_downstreamAr_opDone_strb_7,
      io_downstreamAr_opDone_strb_6,
      io_downstreamAr_opDone_strb_5,
      io_downstreamAr_opDone_strb_4,
      io_downstreamAr_opDone_strb_3,
      io_downstreamAr_opDone_strb_2,
      io_downstreamAr_opDone_strb_1,
      io_downstreamAr_opDone_strb_0};
  assign ar_info_read_strb = {
      io_downstreamAr_infoRead_strb_31,
      io_downstreamAr_infoRead_strb_30,
      io_downstreamAr_infoRead_strb_29,
      io_downstreamAr_infoRead_strb_28,
      io_downstreamAr_infoRead_strb_27,
      io_downstreamAr_infoRead_strb_26,
      io_downstreamAr_infoRead_strb_25,
      io_downstreamAr_infoRead_strb_24,
      io_downstreamAr_infoRead_strb_23,
      io_downstreamAr_infoRead_strb_22,
      io_downstreamAr_infoRead_strb_21,
      io_downstreamAr_infoRead_strb_20,
      io_downstreamAr_infoRead_strb_19,
      io_downstreamAr_infoRead_strb_18,
      io_downstreamAr_infoRead_strb_17,
      io_downstreamAr_infoRead_strb_16,
      io_downstreamAr_infoRead_strb_15,
      io_downstreamAr_infoRead_strb_14,
      io_downstreamAr_infoRead_strb_13,
      io_downstreamAr_infoRead_strb_12,
      io_downstreamAr_infoRead_strb_11,
      io_downstreamAr_infoRead_strb_10,
      io_downstreamAr_infoRead_strb_9,
      io_downstreamAr_infoRead_strb_8,
      io_downstreamAr_infoRead_strb_7,
      io_downstreamAr_infoRead_strb_6,
      io_downstreamAr_infoRead_strb_5,
      io_downstreamAr_infoRead_strb_4,
      io_downstreamAr_infoRead_strb_3,
      io_downstreamAr_infoRead_strb_2,
      io_downstreamAr_infoRead_strb_1,
      io_downstreamAr_infoRead_strb_0};
  assign ar_operand_read_strb = {
      io_downstreamAr_operandRead_strb_31,
      io_downstreamAr_operandRead_strb_30,
      io_downstreamAr_operandRead_strb_29,
      io_downstreamAr_operandRead_strb_28,
      io_downstreamAr_operandRead_strb_27,
      io_downstreamAr_operandRead_strb_26,
      io_downstreamAr_operandRead_strb_25,
      io_downstreamAr_operandRead_strb_24,
      io_downstreamAr_operandRead_strb_23,
      io_downstreamAr_operandRead_strb_22,
      io_downstreamAr_operandRead_strb_21,
      io_downstreamAr_operandRead_strb_20,
      io_downstreamAr_operandRead_strb_19,
      io_downstreamAr_operandRead_strb_18,
      io_downstreamAr_operandRead_strb_17,
      io_downstreamAr_operandRead_strb_16,
      io_downstreamAr_operandRead_strb_15,
      io_downstreamAr_operandRead_strb_14,
      io_downstreamAr_operandRead_strb_13,
      io_downstreamAr_operandRead_strb_12,
      io_downstreamAr_operandRead_strb_11,
      io_downstreamAr_operandRead_strb_10,
      io_downstreamAr_operandRead_strb_9,
      io_downstreamAr_operandRead_strb_8,
      io_downstreamAr_operandRead_strb_7,
      io_downstreamAr_operandRead_strb_6,
      io_downstreamAr_operandRead_strb_5,
      io_downstreamAr_operandRead_strb_4,
      io_downstreamAr_operandRead_strb_3,
      io_downstreamAr_operandRead_strb_2,
      io_downstreamAr_operandRead_strb_1,
      io_downstreamAr_operandRead_strb_0};
  assign r_op_done_strb = {
      io_downstreamR_opDone_strb_31,
      io_downstreamR_opDone_strb_30,
      io_downstreamR_opDone_strb_29,
      io_downstreamR_opDone_strb_28,
      io_downstreamR_opDone_strb_27,
      io_downstreamR_opDone_strb_26,
      io_downstreamR_opDone_strb_25,
      io_downstreamR_opDone_strb_24,
      io_downstreamR_opDone_strb_23,
      io_downstreamR_opDone_strb_22,
      io_downstreamR_opDone_strb_21,
      io_downstreamR_opDone_strb_20,
      io_downstreamR_opDone_strb_19,
      io_downstreamR_opDone_strb_18,
      io_downstreamR_opDone_strb_17,
      io_downstreamR_opDone_strb_16,
      io_downstreamR_opDone_strb_15,
      io_downstreamR_opDone_strb_14,
      io_downstreamR_opDone_strb_13,
      io_downstreamR_opDone_strb_12,
      io_downstreamR_opDone_strb_11,
      io_downstreamR_opDone_strb_10,
      io_downstreamR_opDone_strb_9,
      io_downstreamR_opDone_strb_8,
      io_downstreamR_opDone_strb_7,
      io_downstreamR_opDone_strb_6,
      io_downstreamR_opDone_strb_5,
      io_downstreamR_opDone_strb_4,
      io_downstreamR_opDone_strb_3,
      io_downstreamR_opDone_strb_2,
      io_downstreamR_opDone_strb_1,
      io_downstreamR_opDone_strb_0};
  assign r_operand_read_strb = {
      io_downstreamR_operandRead_strb_31,
      io_downstreamR_operandRead_strb_30,
      io_downstreamR_operandRead_strb_29,
      io_downstreamR_operandRead_strb_28,
      io_downstreamR_operandRead_strb_27,
      io_downstreamR_operandRead_strb_26,
      io_downstreamR_operandRead_strb_25,
      io_downstreamR_operandRead_strb_24,
      io_downstreamR_operandRead_strb_23,
      io_downstreamR_operandRead_strb_22,
      io_downstreamR_operandRead_strb_21,
      io_downstreamR_operandRead_strb_20,
      io_downstreamR_operandRead_strb_19,
      io_downstreamR_operandRead_strb_18,
      io_downstreamR_operandRead_strb_17,
      io_downstreamR_operandRead_strb_16,
      io_downstreamR_operandRead_strb_15,
      io_downstreamR_operandRead_strb_14,
      io_downstreamR_operandRead_strb_13,
      io_downstreamR_operandRead_strb_12,
      io_downstreamR_operandRead_strb_11,
      io_downstreamR_operandRead_strb_10,
      io_downstreamR_operandRead_strb_9,
      io_downstreamR_operandRead_strb_8,
      io_downstreamR_operandRead_strb_7,
      io_downstreamR_operandRead_strb_6,
      io_downstreamR_operandRead_strb_5,
      io_downstreamR_operandRead_strb_4,
      io_downstreamR_operandRead_strb_3,
      io_downstreamR_operandRead_strb_2,
      io_downstreamR_operandRead_strb_1,
      io_downstreamR_operandRead_strb_0};
  assign r_operand_axi_write_strb = {
      io_downstreamR_operandAXIWrite_strb_31,
      io_downstreamR_operandAXIWrite_strb_30,
      io_downstreamR_operandAXIWrite_strb_29,
      io_downstreamR_operandAXIWrite_strb_28,
      io_downstreamR_operandAXIWrite_strb_27,
      io_downstreamR_operandAXIWrite_strb_26,
      io_downstreamR_operandAXIWrite_strb_25,
      io_downstreamR_operandAXIWrite_strb_24,
      io_downstreamR_operandAXIWrite_strb_23,
      io_downstreamR_operandAXIWrite_strb_22,
      io_downstreamR_operandAXIWrite_strb_21,
      io_downstreamR_operandAXIWrite_strb_20,
      io_downstreamR_operandAXIWrite_strb_19,
      io_downstreamR_operandAXIWrite_strb_18,
      io_downstreamR_operandAXIWrite_strb_17,
      io_downstreamR_operandAXIWrite_strb_16,
      io_downstreamR_operandAXIWrite_strb_15,
      io_downstreamR_operandAXIWrite_strb_14,
      io_downstreamR_operandAXIWrite_strb_13,
      io_downstreamR_operandAXIWrite_strb_12,
      io_downstreamR_operandAXIWrite_strb_11,
      io_downstreamR_operandAXIWrite_strb_10,
      io_downstreamR_operandAXIWrite_strb_9,
      io_downstreamR_operandAXIWrite_strb_8,
      io_downstreamR_operandAXIWrite_strb_7,
      io_downstreamR_operandAXIWrite_strb_6,
      io_downstreamR_operandAXIWrite_strb_5,
      io_downstreamR_operandAXIWrite_strb_4,
      io_downstreamR_operandAXIWrite_strb_3,
      io_downstreamR_operandAXIWrite_strb_2,
      io_downstreamR_operandAXIWrite_strb_1,
      io_downstreamR_operandAXIWrite_strb_0};

  // -------------------------------------------------------------------------
  // 输入：标量端口
  // -------------------------------------------------------------------------

  // ncb_op_t 的字段顺序（核文件 §1，先声明的在高位）：
  assign alloc_op_bits = {
      io_allocate_bits_op_chi_Comp_valid,   // [12] chi_comp_valid
      io_allocate_bits_op_chi_Comp_barrier_CHICancelOrAXIBresp,   // [11] chi_comp_barrier_cancel_or_bresp
      io_allocate_bits_op_chi_DBIDResp_valid,   // [10] chi_dbidresp_valid
      io_allocate_bits_op_chi_CompDBIDResp_valid,   // [9] chi_compdbidresp_valid
      io_allocate_bits_op_chi_ReadReceipt_valid,   // [8] chi_readreceipt_valid
      io_allocate_bits_op_chi_CompData_valid,   // [7] chi_compdata_valid
      io_allocate_bits_op_chi_CompData_sep,   // [6] chi_compdata_sep
      io_allocate_bits_op_axi_WriteAddress_valid,   // [5] axi_wa_valid
      io_allocate_bits_op_axi_WriteAddress_barrier_CHIWriteBackData,   // [4] axi_wa_barrier_wbdata
      io_allocate_bits_op_axi_WriteData_valid,   // [3] axi_wd_valid
      io_allocate_bits_op_axi_WriteResponse_valid,   // [2] axi_wresp_valid
      io_allocate_bits_op_axi_ReadAddress_valid,   // [1] axi_ra_valid
      io_allocate_bits_op_axi_ReadData_valid   // [0] axi_rd_valid
  };
  // ★return_nid / return_txn_id 存进去就没有读者★ —— golden 的四个 infoRead
  //   读口只输出 38 位 {QoS,TgtID,SrcID,TxnID}。照抄结构，不删也不合并。
  assign alloc_info_bits = {
      io_allocate_bits_info_QoS,   // qos
      io_allocate_bits_info_TgtID,   // tgt_id
      io_allocate_bits_info_SrcID,   // src_id
      io_allocate_bits_info_TxnID,   // txn_id
      io_allocate_bits_info_ReturnNID,   // return_nid
      io_allocate_bits_info_ReturnTxnID   // return_txn_id
  };
  assign alloc_en = io_allocate_en;
  assign alloc_chi_addr = io_allocate_bits_operand_chi_Addr;
  assign alloc_chi_write_full = io_allocate_bits_operand_chi_WriteFull;
  assign alloc_chi_write_ptl = io_allocate_bits_operand_chi_WritePtl;
  assign alloc_chi_critical = {io_allocate_bits_operand_chi_Critical_1, io_allocate_bits_operand_chi_Critical_0};
  assign alloc_chi_count = io_allocate_bits_operand_chi_Count;
  assign alloc_axi_addr = io_allocate_bits_operand_axi_Addr;
  assign alloc_axi_size = io_allocate_bits_operand_axi_Size;
  assign alloc_axi_len = io_allocate_bits_operand_axi_Len;
  assign alloc_axi_critical = {io_allocate_bits_operand_axi_Critical_1, io_allocate_bits_operand_axi_Critical_0};
  assign alloc_axi_count = io_allocate_bits_operand_axi_Count;
  assign rxdat_query_en = io_upstreamRxDat_query_en;
  assign rxdat_cancel_en = io_upstreamRxDat_cancel_en;
  assign rxdat_write_data_en = io_upstreamRxDat_writeData_en;
  assign txrsp_op_done_comp = io_upstreamTxRsp_opDone_bits_Comp;
  assign txrsp_op_done_dbidresp = io_upstreamTxRsp_opDone_bits_DBIDResp;
  assign txrsp_op_done_compdbidresp = io_upstreamTxRsp_opDone_bits_CompDBIDResp;
  assign txrsp_op_done_readreceipt = io_upstreamTxRsp_opDone_bits_ReadReceipt;
  assign txdat_op_done_compdata = io_upstreamTxDat_opDone_bits_CompData;
  assign txdat_operand_write_critical = {io_upstreamTxDat_operandWrite_bits_Critical_1, io_upstreamTxDat_operandWrite_bits_Critical_0};
  assign txdat_operand_write_count = io_upstreamTxDat_operandWrite_bits_Count;
  assign w_operand_write_critical = {io_downstreamW_operandWrite_bits_Critical_1, io_downstreamW_operandWrite_bits_Critical_0};
  assign w_operand_write_count = io_downstreamW_operandWrite_bits_Count;
  assign r_operand_axi_write_critical = {io_downstreamR_operandAXIWrite_bits_Critical_1, io_downstreamR_operandAXIWrite_bits_Critical_0};
  assign r_operand_axi_write_count = io_downstreamR_operandAXIWrite_bits_Count;
  assign alloc_axi_device = io_allocate_bits_operand_axi_Device;
  // axiMasterOrder=None：上游把 order.valid 钉成常数 0，两个端口都不存在。
  assign alloc_order_valid = 1'b0;
  assign alloc_order_index = '0;

  // -------------------------------------------------------------------------
  // 参数化核例化（固定实例名 u_core）
  // -------------------------------------------------------------------------
  xs_NCBTransactionQueue_core #(
      .N                    (N),
      .HAS_ORDER            (HAS_ORDER),
      .HAS_DEVICE           (HAS_DEVICE),
      .HAS_AR_READY_BARRIER (HAS_AR_BAR)
  ) u_core (
      .clock                             (clock),
      .reset                             (reset),
      .free_strb                         (free_strb),
      .alloc_en                          (alloc_en),
      .alloc_strb                        (alloc_strb),
      .alloc_op_bits                     (alloc_op_bits),
      .alloc_info_bits                   (alloc_info_bits),
      .alloc_chi_addr                    (alloc_chi_addr),
      .alloc_chi_write_full              (alloc_chi_write_full),
      .alloc_chi_write_ptl               (alloc_chi_write_ptl),
      .alloc_chi_critical                (alloc_chi_critical),
      .alloc_chi_count                   (alloc_chi_count),
      .alloc_axi_addr                    (alloc_axi_addr),
      .alloc_axi_size                    (alloc_axi_size),
      .alloc_axi_len                     (alloc_axi_len),
      .alloc_axi_device                  (alloc_axi_device),
      .alloc_axi_critical                (alloc_axi_critical),
      .alloc_axi_count                   (alloc_axi_count),
      .alloc_order_valid                 (alloc_order_valid),
      .alloc_order_index                 (alloc_order_index),
      .rxdat_query_en                    (rxdat_query_en),
      .rxdat_query_strb                  (rxdat_query_strb),
      .rxdat_query_valid                 (rxdat_query_valid),
      .rxdat_query_write_full            (rxdat_query_write_full),
      .rxdat_query_write_ptl             (rxdat_query_write_ptl),
      .rxdat_query_read_resp_err         (rxdat_query_read_resp_err),
      .rxdat_query_write_resp_err        (rxdat_query_write_resp_err),
      .rxdat_cancel_en                   (rxdat_cancel_en),
      .rxdat_cancel_strb                 (rxdat_cancel_strb),
      .rxdat_write_data_en               (rxdat_write_data_en),
      .rxdat_write_data_strb             (rxdat_write_data_strb),
      .txrsp_op_valid                    (txrsp_op_valid),
      .txrsp_op_read_strb                (txrsp_op_read_strb),
      .txrsp_op_read_comp                (txrsp_op_read_comp),
      .txrsp_op_read_dbidresp            (txrsp_op_read_dbidresp),
      .txrsp_op_read_compdbidresp        (txrsp_op_read_compdbidresp),
      .txrsp_op_read_readreceipt         (txrsp_op_read_readreceipt),
      .txrsp_op_done_strb                (txrsp_op_done_strb),
      .txrsp_op_done_comp                (txrsp_op_done_comp),
      .txrsp_op_done_dbidresp            (txrsp_op_done_dbidresp),
      .txrsp_op_done_compdbidresp        (txrsp_op_done_compdbidresp),
      .txrsp_op_done_readreceipt         (txrsp_op_done_readreceipt),
      .txrsp_info_read_strb              (txrsp_info_read_strb),
      .txrsp_info_read_bits              (txrsp_info_read_bits),
      .txrsp_operand_write_resp_err      (txrsp_operand_write_resp_err),
      .txdat_op_valid                    (txdat_op_valid),
      .txdat_op_valid_critical           (txdat_op_valid_critical),
      .txdat_op_read_strb                (txdat_op_read_strb),
      .txdat_op_read_compdata_valid      (txdat_op_read_compdata_valid),
      .txdat_op_read_compdata_sep        (txdat_op_read_compdata_sep),
      .txdat_op_done_strb                (txdat_op_done_strb),
      .txdat_op_done_compdata            (txdat_op_done_compdata),
      .txdat_info_read_strb              (txdat_info_read_strb),
      .txdat_info_read_bits              (txdat_info_read_bits),
      .txdat_operand_read_strb           (txdat_operand_read_strb),
      .txdat_operand_read_addr           (txdat_operand_read_addr),
      .txdat_operand_read_read_resp_err  (txdat_operand_read_read_resp_err),
      .txdat_operand_read_critical       (txdat_operand_read_critical),
      .txdat_operand_read_count          (txdat_operand_read_count),
      .txdat_operand_write_strb          (txdat_operand_write_strb),
      .txdat_operand_write_critical      (txdat_operand_write_critical),
      .txdat_operand_write_count         (txdat_operand_write_count),
      .aw_op_valid                       (aw_op_valid),
      .aw_op_ponr_strb                   (aw_op_ponr_strb),
      .aw_info_read_strb                 (aw_info_read_strb),
      .aw_info_read_qos                  (aw_info_read_qos),
      .aw_operand_read_strb              (aw_operand_read_strb),
      .aw_operand_read_addr              (aw_operand_read_addr),
      .aw_operand_read_burst             (aw_operand_read_burst),
      .aw_operand_read_size              (aw_operand_read_size),
      .aw_operand_read_len               (aw_operand_read_len),
      .w_op_ponr_strb                    (w_op_ponr_strb),
      .w_operand_read_strb               (w_operand_read_strb),
      .w_operand_read_critical           (w_operand_read_critical),
      .w_operand_read_count              (w_operand_read_count),
      .w_operand_write_strb              (w_operand_write_strb),
      .w_operand_write_critical          (w_operand_write_critical),
      .w_operand_write_count             (w_operand_write_count),
      .b_op_done_strb                    (b_op_done_strb),
      .ar_op_valid                       (ar_op_valid),
      .ar_op_ponr_strb                   (ar_op_ponr_strb),
      .ar_op_done_strb                   (ar_op_done_strb),
      .ar_info_read_strb                 (ar_info_read_strb),
      .ar_info_read_qos                  (ar_info_read_qos),
      .ar_operand_read_strb              (ar_operand_read_strb),
      .ar_operand_read_addr              (ar_operand_read_addr),
      .ar_operand_read_burst             (ar_operand_read_burst),
      .ar_operand_read_size              (ar_operand_read_size),
      .ar_operand_read_len               (ar_operand_read_len),
      .ar_operand_read_device            (ar_operand_read_device),
      .r_op_done_strb                    (r_op_done_strb),
      .r_operand_read_strb               (r_operand_read_strb),
      .r_operand_read_critical           (r_operand_read_critical),
      .r_operand_read_count              (r_operand_read_count),
      .r_operand_axi_write_strb          (r_operand_axi_write_strb),
      .r_operand_axi_write_critical      (r_operand_axi_write_critical),
      .r_operand_axi_write_count         (r_operand_axi_write_count),
      .dbg_double_allocation             (dbg_double_allocation),
      .dbg_dangling_axi_write_response   (dbg_dangling_axi_write_response)
  );

  // -------------------------------------------------------------------------
  // 输出：核侧向量散回 golden 的逐槽标量端口
  // -------------------------------------------------------------------------
  assign io_free_strb_0 = free_strb[0];
  assign io_free_strb_1 = free_strb[1];
  assign io_free_strb_2 = free_strb[2];
  assign io_free_strb_3 = free_strb[3];
  assign io_free_strb_4 = free_strb[4];
  assign io_free_strb_5 = free_strb[5];
  assign io_free_strb_6 = free_strb[6];
  assign io_free_strb_7 = free_strb[7];
  assign io_free_strb_8 = free_strb[8];
  assign io_free_strb_9 = free_strb[9];
  assign io_free_strb_10 = free_strb[10];
  assign io_free_strb_11 = free_strb[11];
  assign io_free_strb_12 = free_strb[12];
  assign io_free_strb_13 = free_strb[13];
  assign io_free_strb_14 = free_strb[14];
  assign io_free_strb_15 = free_strb[15];
  assign io_free_strb_16 = free_strb[16];
  assign io_free_strb_17 = free_strb[17];
  assign io_free_strb_18 = free_strb[18];
  assign io_free_strb_19 = free_strb[19];
  assign io_free_strb_20 = free_strb[20];
  assign io_free_strb_21 = free_strb[21];
  assign io_free_strb_22 = free_strb[22];
  assign io_free_strb_23 = free_strb[23];
  assign io_free_strb_24 = free_strb[24];
  assign io_free_strb_25 = free_strb[25];
  assign io_free_strb_26 = free_strb[26];
  assign io_free_strb_27 = free_strb[27];
  assign io_free_strb_28 = free_strb[28];
  assign io_free_strb_29 = free_strb[29];
  assign io_free_strb_30 = free_strb[30];
  assign io_free_strb_31 = free_strb[31];
  assign io_upstreamTxRsp_opValid_valid_0 = txrsp_op_valid[0];
  assign io_upstreamTxRsp_opValid_valid_1 = txrsp_op_valid[1];
  assign io_upstreamTxRsp_opValid_valid_2 = txrsp_op_valid[2];
  assign io_upstreamTxRsp_opValid_valid_3 = txrsp_op_valid[3];
  assign io_upstreamTxRsp_opValid_valid_4 = txrsp_op_valid[4];
  assign io_upstreamTxRsp_opValid_valid_5 = txrsp_op_valid[5];
  assign io_upstreamTxRsp_opValid_valid_6 = txrsp_op_valid[6];
  assign io_upstreamTxRsp_opValid_valid_7 = txrsp_op_valid[7];
  assign io_upstreamTxRsp_opValid_valid_8 = txrsp_op_valid[8];
  assign io_upstreamTxRsp_opValid_valid_9 = txrsp_op_valid[9];
  assign io_upstreamTxRsp_opValid_valid_10 = txrsp_op_valid[10];
  assign io_upstreamTxRsp_opValid_valid_11 = txrsp_op_valid[11];
  assign io_upstreamTxRsp_opValid_valid_12 = txrsp_op_valid[12];
  assign io_upstreamTxRsp_opValid_valid_13 = txrsp_op_valid[13];
  assign io_upstreamTxRsp_opValid_valid_14 = txrsp_op_valid[14];
  assign io_upstreamTxRsp_opValid_valid_15 = txrsp_op_valid[15];
  assign io_upstreamTxRsp_opValid_valid_16 = txrsp_op_valid[16];
  assign io_upstreamTxRsp_opValid_valid_17 = txrsp_op_valid[17];
  assign io_upstreamTxRsp_opValid_valid_18 = txrsp_op_valid[18];
  assign io_upstreamTxRsp_opValid_valid_19 = txrsp_op_valid[19];
  assign io_upstreamTxRsp_opValid_valid_20 = txrsp_op_valid[20];
  assign io_upstreamTxRsp_opValid_valid_21 = txrsp_op_valid[21];
  assign io_upstreamTxRsp_opValid_valid_22 = txrsp_op_valid[22];
  assign io_upstreamTxRsp_opValid_valid_23 = txrsp_op_valid[23];
  assign io_upstreamTxRsp_opValid_valid_24 = txrsp_op_valid[24];
  assign io_upstreamTxRsp_opValid_valid_25 = txrsp_op_valid[25];
  assign io_upstreamTxRsp_opValid_valid_26 = txrsp_op_valid[26];
  assign io_upstreamTxRsp_opValid_valid_27 = txrsp_op_valid[27];
  assign io_upstreamTxRsp_opValid_valid_28 = txrsp_op_valid[28];
  assign io_upstreamTxRsp_opValid_valid_29 = txrsp_op_valid[29];
  assign io_upstreamTxRsp_opValid_valid_30 = txrsp_op_valid[30];
  assign io_upstreamTxRsp_opValid_valid_31 = txrsp_op_valid[31];
  assign io_upstreamTxDat_opValid_valid_0 = txdat_op_valid[0];
  assign io_upstreamTxDat_opValid_valid_1 = txdat_op_valid[1];
  assign io_upstreamTxDat_opValid_valid_2 = txdat_op_valid[2];
  assign io_upstreamTxDat_opValid_valid_3 = txdat_op_valid[3];
  assign io_upstreamTxDat_opValid_valid_4 = txdat_op_valid[4];
  assign io_upstreamTxDat_opValid_valid_5 = txdat_op_valid[5];
  assign io_upstreamTxDat_opValid_valid_6 = txdat_op_valid[6];
  assign io_upstreamTxDat_opValid_valid_7 = txdat_op_valid[7];
  assign io_upstreamTxDat_opValid_valid_8 = txdat_op_valid[8];
  assign io_upstreamTxDat_opValid_valid_9 = txdat_op_valid[9];
  assign io_upstreamTxDat_opValid_valid_10 = txdat_op_valid[10];
  assign io_upstreamTxDat_opValid_valid_11 = txdat_op_valid[11];
  assign io_upstreamTxDat_opValid_valid_12 = txdat_op_valid[12];
  assign io_upstreamTxDat_opValid_valid_13 = txdat_op_valid[13];
  assign io_upstreamTxDat_opValid_valid_14 = txdat_op_valid[14];
  assign io_upstreamTxDat_opValid_valid_15 = txdat_op_valid[15];
  assign io_upstreamTxDat_opValid_valid_16 = txdat_op_valid[16];
  assign io_upstreamTxDat_opValid_valid_17 = txdat_op_valid[17];
  assign io_upstreamTxDat_opValid_valid_18 = txdat_op_valid[18];
  assign io_upstreamTxDat_opValid_valid_19 = txdat_op_valid[19];
  assign io_upstreamTxDat_opValid_valid_20 = txdat_op_valid[20];
  assign io_upstreamTxDat_opValid_valid_21 = txdat_op_valid[21];
  assign io_upstreamTxDat_opValid_valid_22 = txdat_op_valid[22];
  assign io_upstreamTxDat_opValid_valid_23 = txdat_op_valid[23];
  assign io_upstreamTxDat_opValid_valid_24 = txdat_op_valid[24];
  assign io_upstreamTxDat_opValid_valid_25 = txdat_op_valid[25];
  assign io_upstreamTxDat_opValid_valid_26 = txdat_op_valid[26];
  assign io_upstreamTxDat_opValid_valid_27 = txdat_op_valid[27];
  assign io_upstreamTxDat_opValid_valid_28 = txdat_op_valid[28];
  assign io_upstreamTxDat_opValid_valid_29 = txdat_op_valid[29];
  assign io_upstreamTxDat_opValid_valid_30 = txdat_op_valid[30];
  assign io_upstreamTxDat_opValid_valid_31 = txdat_op_valid[31];
  assign io_downstreamAw_opValid_valid_0 = aw_op_valid[0];
  assign io_downstreamAw_opValid_valid_1 = aw_op_valid[1];
  assign io_downstreamAw_opValid_valid_2 = aw_op_valid[2];
  assign io_downstreamAw_opValid_valid_3 = aw_op_valid[3];
  assign io_downstreamAw_opValid_valid_4 = aw_op_valid[4];
  assign io_downstreamAw_opValid_valid_5 = aw_op_valid[5];
  assign io_downstreamAw_opValid_valid_6 = aw_op_valid[6];
  assign io_downstreamAw_opValid_valid_7 = aw_op_valid[7];
  assign io_downstreamAw_opValid_valid_8 = aw_op_valid[8];
  assign io_downstreamAw_opValid_valid_9 = aw_op_valid[9];
  assign io_downstreamAw_opValid_valid_10 = aw_op_valid[10];
  assign io_downstreamAw_opValid_valid_11 = aw_op_valid[11];
  assign io_downstreamAw_opValid_valid_12 = aw_op_valid[12];
  assign io_downstreamAw_opValid_valid_13 = aw_op_valid[13];
  assign io_downstreamAw_opValid_valid_14 = aw_op_valid[14];
  assign io_downstreamAw_opValid_valid_15 = aw_op_valid[15];
  assign io_downstreamAw_opValid_valid_16 = aw_op_valid[16];
  assign io_downstreamAw_opValid_valid_17 = aw_op_valid[17];
  assign io_downstreamAw_opValid_valid_18 = aw_op_valid[18];
  assign io_downstreamAw_opValid_valid_19 = aw_op_valid[19];
  assign io_downstreamAw_opValid_valid_20 = aw_op_valid[20];
  assign io_downstreamAw_opValid_valid_21 = aw_op_valid[21];
  assign io_downstreamAw_opValid_valid_22 = aw_op_valid[22];
  assign io_downstreamAw_opValid_valid_23 = aw_op_valid[23];
  assign io_downstreamAw_opValid_valid_24 = aw_op_valid[24];
  assign io_downstreamAw_opValid_valid_25 = aw_op_valid[25];
  assign io_downstreamAw_opValid_valid_26 = aw_op_valid[26];
  assign io_downstreamAw_opValid_valid_27 = aw_op_valid[27];
  assign io_downstreamAw_opValid_valid_28 = aw_op_valid[28];
  assign io_downstreamAw_opValid_valid_29 = aw_op_valid[29];
  assign io_downstreamAw_opValid_valid_30 = aw_op_valid[30];
  assign io_downstreamAw_opValid_valid_31 = aw_op_valid[31];
  assign io_downstreamAr_opValid_valid_0 = ar_op_valid[0];
  assign io_downstreamAr_opValid_valid_1 = ar_op_valid[1];
  assign io_downstreamAr_opValid_valid_2 = ar_op_valid[2];
  assign io_downstreamAr_opValid_valid_3 = ar_op_valid[3];
  assign io_downstreamAr_opValid_valid_4 = ar_op_valid[4];
  assign io_downstreamAr_opValid_valid_5 = ar_op_valid[5];
  assign io_downstreamAr_opValid_valid_6 = ar_op_valid[6];
  assign io_downstreamAr_opValid_valid_7 = ar_op_valid[7];
  assign io_downstreamAr_opValid_valid_8 = ar_op_valid[8];
  assign io_downstreamAr_opValid_valid_9 = ar_op_valid[9];
  assign io_downstreamAr_opValid_valid_10 = ar_op_valid[10];
  assign io_downstreamAr_opValid_valid_11 = ar_op_valid[11];
  assign io_downstreamAr_opValid_valid_12 = ar_op_valid[12];
  assign io_downstreamAr_opValid_valid_13 = ar_op_valid[13];
  assign io_downstreamAr_opValid_valid_14 = ar_op_valid[14];
  assign io_downstreamAr_opValid_valid_15 = ar_op_valid[15];
  assign io_downstreamAr_opValid_valid_16 = ar_op_valid[16];
  assign io_downstreamAr_opValid_valid_17 = ar_op_valid[17];
  assign io_downstreamAr_opValid_valid_18 = ar_op_valid[18];
  assign io_downstreamAr_opValid_valid_19 = ar_op_valid[19];
  assign io_downstreamAr_opValid_valid_20 = ar_op_valid[20];
  assign io_downstreamAr_opValid_valid_21 = ar_op_valid[21];
  assign io_downstreamAr_opValid_valid_22 = ar_op_valid[22];
  assign io_downstreamAr_opValid_valid_23 = ar_op_valid[23];
  assign io_downstreamAr_opValid_valid_24 = ar_op_valid[24];
  assign io_downstreamAr_opValid_valid_25 = ar_op_valid[25];
  assign io_downstreamAr_opValid_valid_26 = ar_op_valid[26];
  assign io_downstreamAr_opValid_valid_27 = ar_op_valid[27];
  assign io_downstreamAr_opValid_valid_28 = ar_op_valid[28];
  assign io_downstreamAr_opValid_valid_29 = ar_op_valid[29];
  assign io_downstreamAr_opValid_valid_30 = ar_op_valid[30];
  assign io_downstreamAr_opValid_valid_31 = ar_op_valid[31];
  assign debug_DoubleAllocation_0 = dbg_double_allocation[0];
  assign debug_DoubleAllocation_1 = dbg_double_allocation[1];
  assign debug_DoubleAllocation_2 = dbg_double_allocation[2];
  assign debug_DoubleAllocation_3 = dbg_double_allocation[3];
  assign debug_DoubleAllocation_4 = dbg_double_allocation[4];
  assign debug_DoubleAllocation_5 = dbg_double_allocation[5];
  assign debug_DoubleAllocation_6 = dbg_double_allocation[6];
  assign debug_DoubleAllocation_7 = dbg_double_allocation[7];
  assign debug_DoubleAllocation_8 = dbg_double_allocation[8];
  assign debug_DoubleAllocation_9 = dbg_double_allocation[9];
  assign debug_DoubleAllocation_10 = dbg_double_allocation[10];
  assign debug_DoubleAllocation_11 = dbg_double_allocation[11];
  assign debug_DoubleAllocation_12 = dbg_double_allocation[12];
  assign debug_DoubleAllocation_13 = dbg_double_allocation[13];
  assign debug_DoubleAllocation_14 = dbg_double_allocation[14];
  assign debug_DoubleAllocation_15 = dbg_double_allocation[15];
  assign debug_DoubleAllocation_16 = dbg_double_allocation[16];
  assign debug_DoubleAllocation_17 = dbg_double_allocation[17];
  assign debug_DoubleAllocation_18 = dbg_double_allocation[18];
  assign debug_DoubleAllocation_19 = dbg_double_allocation[19];
  assign debug_DoubleAllocation_20 = dbg_double_allocation[20];
  assign debug_DoubleAllocation_21 = dbg_double_allocation[21];
  assign debug_DoubleAllocation_22 = dbg_double_allocation[22];
  assign debug_DoubleAllocation_23 = dbg_double_allocation[23];
  assign debug_DoubleAllocation_24 = dbg_double_allocation[24];
  assign debug_DoubleAllocation_25 = dbg_double_allocation[25];
  assign debug_DoubleAllocation_26 = dbg_double_allocation[26];
  assign debug_DoubleAllocation_27 = dbg_double_allocation[27];
  assign debug_DoubleAllocation_28 = dbg_double_allocation[28];
  assign debug_DoubleAllocation_29 = dbg_double_allocation[29];
  assign debug_DoubleAllocation_30 = dbg_double_allocation[30];
  assign debug_DoubleAllocation_31 = dbg_double_allocation[31];
  assign debug_DanglingAXIWriteResponse_0 = dbg_dangling_axi_write_response[0];
  assign debug_DanglingAXIWriteResponse_1 = dbg_dangling_axi_write_response[1];
  assign debug_DanglingAXIWriteResponse_2 = dbg_dangling_axi_write_response[2];
  assign debug_DanglingAXIWriteResponse_3 = dbg_dangling_axi_write_response[3];
  assign debug_DanglingAXIWriteResponse_4 = dbg_dangling_axi_write_response[4];
  assign debug_DanglingAXIWriteResponse_5 = dbg_dangling_axi_write_response[5];
  assign debug_DanglingAXIWriteResponse_6 = dbg_dangling_axi_write_response[6];
  assign debug_DanglingAXIWriteResponse_7 = dbg_dangling_axi_write_response[7];
  assign debug_DanglingAXIWriteResponse_8 = dbg_dangling_axi_write_response[8];
  assign debug_DanglingAXIWriteResponse_9 = dbg_dangling_axi_write_response[9];
  assign debug_DanglingAXIWriteResponse_10 = dbg_dangling_axi_write_response[10];
  assign debug_DanglingAXIWriteResponse_11 = dbg_dangling_axi_write_response[11];
  assign debug_DanglingAXIWriteResponse_12 = dbg_dangling_axi_write_response[12];
  assign debug_DanglingAXIWriteResponse_13 = dbg_dangling_axi_write_response[13];
  assign debug_DanglingAXIWriteResponse_14 = dbg_dangling_axi_write_response[14];
  assign debug_DanglingAXIWriteResponse_15 = dbg_dangling_axi_write_response[15];
  assign debug_DanglingAXIWriteResponse_16 = dbg_dangling_axi_write_response[16];
  assign debug_DanglingAXIWriteResponse_17 = dbg_dangling_axi_write_response[17];
  assign debug_DanglingAXIWriteResponse_18 = dbg_dangling_axi_write_response[18];
  assign debug_DanglingAXIWriteResponse_19 = dbg_dangling_axi_write_response[19];
  assign debug_DanglingAXIWriteResponse_20 = dbg_dangling_axi_write_response[20];
  assign debug_DanglingAXIWriteResponse_21 = dbg_dangling_axi_write_response[21];
  assign debug_DanglingAXIWriteResponse_22 = dbg_dangling_axi_write_response[22];
  assign debug_DanglingAXIWriteResponse_23 = dbg_dangling_axi_write_response[23];
  assign debug_DanglingAXIWriteResponse_24 = dbg_dangling_axi_write_response[24];
  assign debug_DanglingAXIWriteResponse_25 = dbg_dangling_axi_write_response[25];
  assign debug_DanglingAXIWriteResponse_26 = dbg_dangling_axi_write_response[26];
  assign debug_DanglingAXIWriteResponse_27 = dbg_dangling_axi_write_response[27];
  assign debug_DanglingAXIWriteResponse_28 = dbg_dangling_axi_write_response[28];
  assign debug_DanglingAXIWriteResponse_29 = dbg_dangling_axi_write_response[29];
  assign debug_DanglingAXIWriteResponse_30 = dbg_dangling_axi_write_response[30];
  assign debug_DanglingAXIWriteResponse_31 = dbg_dangling_axi_write_response[31];
  // 每一槽的 CHI Critical 全都拉出去（32×2 根线），给 TXDAT 挑关键字优先的那一拍。
  assign io_upstreamTxDat_opValid_bits_Critical_0_0 = txdat_op_valid_critical[0][0];
  assign io_upstreamTxDat_opValid_bits_Critical_0_1 = txdat_op_valid_critical[0][1];
  assign io_upstreamTxDat_opValid_bits_Critical_1_0 = txdat_op_valid_critical[1][0];
  assign io_upstreamTxDat_opValid_bits_Critical_1_1 = txdat_op_valid_critical[1][1];
  assign io_upstreamTxDat_opValid_bits_Critical_2_0 = txdat_op_valid_critical[2][0];
  assign io_upstreamTxDat_opValid_bits_Critical_2_1 = txdat_op_valid_critical[2][1];
  assign io_upstreamTxDat_opValid_bits_Critical_3_0 = txdat_op_valid_critical[3][0];
  assign io_upstreamTxDat_opValid_bits_Critical_3_1 = txdat_op_valid_critical[3][1];
  assign io_upstreamTxDat_opValid_bits_Critical_4_0 = txdat_op_valid_critical[4][0];
  assign io_upstreamTxDat_opValid_bits_Critical_4_1 = txdat_op_valid_critical[4][1];
  assign io_upstreamTxDat_opValid_bits_Critical_5_0 = txdat_op_valid_critical[5][0];
  assign io_upstreamTxDat_opValid_bits_Critical_5_1 = txdat_op_valid_critical[5][1];
  assign io_upstreamTxDat_opValid_bits_Critical_6_0 = txdat_op_valid_critical[6][0];
  assign io_upstreamTxDat_opValid_bits_Critical_6_1 = txdat_op_valid_critical[6][1];
  assign io_upstreamTxDat_opValid_bits_Critical_7_0 = txdat_op_valid_critical[7][0];
  assign io_upstreamTxDat_opValid_bits_Critical_7_1 = txdat_op_valid_critical[7][1];
  assign io_upstreamTxDat_opValid_bits_Critical_8_0 = txdat_op_valid_critical[8][0];
  assign io_upstreamTxDat_opValid_bits_Critical_8_1 = txdat_op_valid_critical[8][1];
  assign io_upstreamTxDat_opValid_bits_Critical_9_0 = txdat_op_valid_critical[9][0];
  assign io_upstreamTxDat_opValid_bits_Critical_9_1 = txdat_op_valid_critical[9][1];
  assign io_upstreamTxDat_opValid_bits_Critical_10_0 = txdat_op_valid_critical[10][0];
  assign io_upstreamTxDat_opValid_bits_Critical_10_1 = txdat_op_valid_critical[10][1];
  assign io_upstreamTxDat_opValid_bits_Critical_11_0 = txdat_op_valid_critical[11][0];
  assign io_upstreamTxDat_opValid_bits_Critical_11_1 = txdat_op_valid_critical[11][1];
  assign io_upstreamTxDat_opValid_bits_Critical_12_0 = txdat_op_valid_critical[12][0];
  assign io_upstreamTxDat_opValid_bits_Critical_12_1 = txdat_op_valid_critical[12][1];
  assign io_upstreamTxDat_opValid_bits_Critical_13_0 = txdat_op_valid_critical[13][0];
  assign io_upstreamTxDat_opValid_bits_Critical_13_1 = txdat_op_valid_critical[13][1];
  assign io_upstreamTxDat_opValid_bits_Critical_14_0 = txdat_op_valid_critical[14][0];
  assign io_upstreamTxDat_opValid_bits_Critical_14_1 = txdat_op_valid_critical[14][1];
  assign io_upstreamTxDat_opValid_bits_Critical_15_0 = txdat_op_valid_critical[15][0];
  assign io_upstreamTxDat_opValid_bits_Critical_15_1 = txdat_op_valid_critical[15][1];
  assign io_upstreamTxDat_opValid_bits_Critical_16_0 = txdat_op_valid_critical[16][0];
  assign io_upstreamTxDat_opValid_bits_Critical_16_1 = txdat_op_valid_critical[16][1];
  assign io_upstreamTxDat_opValid_bits_Critical_17_0 = txdat_op_valid_critical[17][0];
  assign io_upstreamTxDat_opValid_bits_Critical_17_1 = txdat_op_valid_critical[17][1];
  assign io_upstreamTxDat_opValid_bits_Critical_18_0 = txdat_op_valid_critical[18][0];
  assign io_upstreamTxDat_opValid_bits_Critical_18_1 = txdat_op_valid_critical[18][1];
  assign io_upstreamTxDat_opValid_bits_Critical_19_0 = txdat_op_valid_critical[19][0];
  assign io_upstreamTxDat_opValid_bits_Critical_19_1 = txdat_op_valid_critical[19][1];
  assign io_upstreamTxDat_opValid_bits_Critical_20_0 = txdat_op_valid_critical[20][0];
  assign io_upstreamTxDat_opValid_bits_Critical_20_1 = txdat_op_valid_critical[20][1];
  assign io_upstreamTxDat_opValid_bits_Critical_21_0 = txdat_op_valid_critical[21][0];
  assign io_upstreamTxDat_opValid_bits_Critical_21_1 = txdat_op_valid_critical[21][1];
  assign io_upstreamTxDat_opValid_bits_Critical_22_0 = txdat_op_valid_critical[22][0];
  assign io_upstreamTxDat_opValid_bits_Critical_22_1 = txdat_op_valid_critical[22][1];
  assign io_upstreamTxDat_opValid_bits_Critical_23_0 = txdat_op_valid_critical[23][0];
  assign io_upstreamTxDat_opValid_bits_Critical_23_1 = txdat_op_valid_critical[23][1];
  assign io_upstreamTxDat_opValid_bits_Critical_24_0 = txdat_op_valid_critical[24][0];
  assign io_upstreamTxDat_opValid_bits_Critical_24_1 = txdat_op_valid_critical[24][1];
  assign io_upstreamTxDat_opValid_bits_Critical_25_0 = txdat_op_valid_critical[25][0];
  assign io_upstreamTxDat_opValid_bits_Critical_25_1 = txdat_op_valid_critical[25][1];
  assign io_upstreamTxDat_opValid_bits_Critical_26_0 = txdat_op_valid_critical[26][0];
  assign io_upstreamTxDat_opValid_bits_Critical_26_1 = txdat_op_valid_critical[26][1];
  assign io_upstreamTxDat_opValid_bits_Critical_27_0 = txdat_op_valid_critical[27][0];
  assign io_upstreamTxDat_opValid_bits_Critical_27_1 = txdat_op_valid_critical[27][1];
  assign io_upstreamTxDat_opValid_bits_Critical_28_0 = txdat_op_valid_critical[28][0];
  assign io_upstreamTxDat_opValid_bits_Critical_28_1 = txdat_op_valid_critical[28][1];
  assign io_upstreamTxDat_opValid_bits_Critical_29_0 = txdat_op_valid_critical[29][0];
  assign io_upstreamTxDat_opValid_bits_Critical_29_1 = txdat_op_valid_critical[29][1];
  assign io_upstreamTxDat_opValid_bits_Critical_30_0 = txdat_op_valid_critical[30][0];
  assign io_upstreamTxDat_opValid_bits_Critical_30_1 = txdat_op_valid_critical[30][1];
  assign io_upstreamTxDat_opValid_bits_Critical_31_0 = txdat_op_valid_critical[31][0];
  assign io_upstreamTxDat_opValid_bits_Critical_31_1 = txdat_op_valid_critical[31][1];
  // 标量输出
  assign io_upstreamRxDat_query_result_valid = rxdat_query_valid;
  assign io_upstreamRxDat_query_result_WriteFull = rxdat_query_write_full;
  assign io_upstreamRxDat_query_result_WritePtl = rxdat_query_write_ptl;
  assign io_upstreamTxRsp_opRead_bits_Comp = txrsp_op_read_comp;
  assign io_upstreamTxRsp_opRead_bits_DBIDResp = txrsp_op_read_dbidresp;
  assign io_upstreamTxRsp_opRead_bits_CompDBIDResp = txrsp_op_read_compdbidresp;
  assign io_upstreamTxRsp_opRead_bits_ReadReceipt = txrsp_op_read_readreceipt;
  assign io_upstreamTxRsp_infoRead_bits_QoS = txrsp_info_read_bits[37:34];
  assign io_upstreamTxRsp_infoRead_bits_TgtID = txrsp_info_read_bits[33:23];
  assign io_upstreamTxRsp_infoRead_bits_SrcID = txrsp_info_read_bits[22:12];
  assign io_upstreamTxRsp_infoRead_bits_TxnID = txrsp_info_read_bits[11:0];
  assign io_upstreamTxRsp_operandRead_bits_WriteRespErr = txrsp_operand_write_resp_err;
  assign io_upstreamTxDat_opRead_bits_CompData_valid = txdat_op_read_compdata_valid;
  assign io_upstreamTxDat_opRead_bits_CompData_sep = txdat_op_read_compdata_sep;
  assign io_upstreamTxDat_infoRead_bits_QoS = txdat_info_read_bits[37:34];
  assign io_upstreamTxDat_infoRead_bits_TgtID = txdat_info_read_bits[33:23];
  assign io_upstreamTxDat_infoRead_bits_SrcID = txdat_info_read_bits[22:12];
  assign io_upstreamTxDat_infoRead_bits_TxnID = txdat_info_read_bits[11:0];
  assign io_upstreamTxDat_operandRead_bits_Addr = txdat_operand_read_addr;
  assign io_upstreamTxDat_operandRead_bits_ReadRespErr = txdat_operand_read_read_resp_err;
  assign io_upstreamTxDat_operandRead_bits_Critical_0 = txdat_operand_read_critical[0];
  assign io_upstreamTxDat_operandRead_bits_Critical_1 = txdat_operand_read_critical[1];
  assign io_upstreamTxDat_operandRead_bits_Count = txdat_operand_read_count;
  assign io_downstreamAw_infoRead_bits_QoS = aw_info_read_qos;
  assign io_downstreamAw_operandRead_bits_Addr = aw_operand_read_addr;
  assign io_downstreamAw_operandRead_bits_Burst = aw_operand_read_burst;
  assign io_downstreamAw_operandRead_bits_Size = aw_operand_read_size;
  assign io_downstreamAw_operandRead_bits_Len = aw_operand_read_len;
  assign io_downstreamW_operandRead_bits_Critical_0 = w_operand_read_critical[0];
  assign io_downstreamW_operandRead_bits_Critical_1 = w_operand_read_critical[1];
  assign io_downstreamW_operandRead_bits_Count = w_operand_read_count;
  assign io_downstreamAr_infoRead_bits_QoS = ar_info_read_qos;
  assign io_downstreamAr_operandRead_bits_Addr = ar_operand_read_addr;
  assign io_downstreamAr_operandRead_bits_Burst = ar_operand_read_burst;
  assign io_downstreamAr_operandRead_bits_Size = ar_operand_read_size;
  assign io_downstreamAr_operandRead_bits_Len = ar_operand_read_len;
  assign io_downstreamAr_operandRead_bits_Device = ar_operand_read_device;
  assign io_downstreamR_operandRead_bits_Critical_0 = r_operand_read_critical[0];
  assign io_downstreamR_operandRead_bits_Critical_1 = r_operand_read_critical[1];
  assign io_downstreamR_operandRead_bits_Count = r_operand_read_count;

endmodule : NCBTransactionQueue_1
