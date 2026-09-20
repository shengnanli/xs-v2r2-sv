// =============================================================================
// FuBusyTableRead.sv —— 发射队列「功能单元忙表」读侧：家族参数化核 + 本变体 wrapper
//
// 在哪一层：后端乱序发射队列（IssueQueue*）内部。发射队列为**每一条出射通道**维护
//   一张 fuBusyTable（忙表，由同文件族的 FuBusyTableWrite 维护），表里按「还差几拍
//   才写回」分槽记录「这一槽已经被某个功能单元占了」。本模块把那张表**翻译成
//   逐条目的屏蔽位**：条目 e 的 mask 位为 1 表示「e 想用的功能单元此刻忙，这一拍
//   不许选它」。下游是发射队列的选择逻辑（Entries/选择器）。
//
// 核心机制（一句话）：
//   busy_mask[e] = 或_b ( fuBusyTable[b] & (条目 e 的 fuType 落在槽 b 的功能单元集合里) )
//   —— fuType 是 35 位 one-hot 向量（FuType.num=35），「落在集合里」= 与该槽的
//   位掩码相与后有任何一位为 1。golden 把这个与/或矩阵整个展平成一条 assign。
//
// 家族差异（18 个变体只差 3 个维度，一个核全覆盖）：条目数 NE（16/18/24）、
//   表宽 TW（1..5）、以及每个槽的 fuType 位掩码 FU_SEL。逐变体矩阵见
//   verif/ut/FuBusyTableReadVariants/README.md；17 个薄 wrapper 由
//   scripts/gen_fubusy_wbarb.py 生成。
//
// ★golden 的不对称照抄★：TW 位里常常只有一部分槽在 golden 的表达式里出现
//   （例如本变体 TW=3 只有槽 0 与槽 2 出现，槽 1 没有）。那是 Chisel 侧该槽的
//   功能单元集合为空，firtool 把整项折没了。核里用「掩码为 0 的槽贡献 0」表达，
//   既不补齐也不少算。
//
// 设计源：XiangShan src/main/scala/xiangshan/backend/issue/FuBusyTable.scala
// golden 对照：G1-canonical/golden-rtl/FuBusyTableRead.sv（本文件的 wrapper 段）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_FuBusyTableRead_core —— 忙表 → 条目屏蔽位的与/或矩阵
//
// FU_SEL 固定给 8 个槽的位置（家族实测最大 TW=5，留 8 是为了让参数类型与 TW 无关，
// 例化处只填前 TW 个，其余保持全 0；全 0 的槽在下面的循环里天然贡献 0）。
// -----------------------------------------------------------------------------
module xs_FuBusyTableRead_core #(
  parameter int NE = 24,                      // 发射队列条目数
  parameter int TW = 3,                       // fuBusyTable 位宽（= 本队列最长功能单元延迟 + 1）
  parameter logic [7:0][34:0] FU_SEL = '{default: '0}  // 每个槽认领的 fuType 位掩码
) (
  input  logic [TW-1:0]        fu_busy_table,  // 忙表：按剩余延迟分槽
  input  logic [NE-1:0][34:0]  fu_type,        // 每个条目的 fuType（35 位 one-hot）
  output logic [NE-1:0]        busy_mask       // 1 = 该条目本拍被屏蔽
);
  always_comb begin
    busy_mask = '0;
    for (int b = 0; b < TW; b++)
      if (fu_busy_table[b])
        for (int e = 0; e < NE; e++)
          // 条目 e 的功能单元是否属于槽 b 认领的那一组
          busy_mask[e] |= |(fu_type[e] & FU_SEL[b]);
  end
endmodule

// -----------------------------------------------------------------------------
// FuBusyTableRead —— 家族里最朴素的一个：24 条目 / TW=3。
//   槽 0 认领 fuType[6]（i2f），槽 2 认领 fuType[7]|fuType[10]（mul / bku）。
//   例化者：IssueQueueAluMulBkuBrhJmp.sv
// -----------------------------------------------------------------------------
module FuBusyTableRead(
  input  [2:0]  io_in_fuBusyTable,
  input  [34:0] io_in_fuTypeRegVec_0,
  input  [34:0] io_in_fuTypeRegVec_1,
  input  [34:0] io_in_fuTypeRegVec_2,
  input  [34:0] io_in_fuTypeRegVec_3,
  input  [34:0] io_in_fuTypeRegVec_4,
  input  [34:0] io_in_fuTypeRegVec_5,
  input  [34:0] io_in_fuTypeRegVec_6,
  input  [34:0] io_in_fuTypeRegVec_7,
  input  [34:0] io_in_fuTypeRegVec_8,
  input  [34:0] io_in_fuTypeRegVec_9,
  input  [34:0] io_in_fuTypeRegVec_10,
  input  [34:0] io_in_fuTypeRegVec_11,
  input  [34:0] io_in_fuTypeRegVec_12,
  input  [34:0] io_in_fuTypeRegVec_13,
  input  [34:0] io_in_fuTypeRegVec_14,
  input  [34:0] io_in_fuTypeRegVec_15,
  input  [34:0] io_in_fuTypeRegVec_16,
  input  [34:0] io_in_fuTypeRegVec_17,
  input  [34:0] io_in_fuTypeRegVec_18,
  input  [34:0] io_in_fuTypeRegVec_19,
  input  [34:0] io_in_fuTypeRegVec_20,
  input  [34:0] io_in_fuTypeRegVec_21,
  input  [34:0] io_in_fuTypeRegVec_22,
  input  [34:0] io_in_fuTypeRegVec_23,
  output [23:0] io_out_fuBusyTableMask
);
  localparam int NE = 24;
  localparam int TW = 3;
  // 槽 1 的集合为空（golden 的表达式里没有这一项），保持全 0。
  localparam logic [7:0][34:0] FU_SEL = '{
    35'h0, 35'h0, 35'h0, 35'h0, 35'h0,          // 槽 7..3：本变体没有
    35'h480,                              // 槽 2：fuType[7] | fuType[10]
    35'h0,                                       // 槽 1：空
    35'h40};                             // 槽 0：fuType[6]

  logic [NE-1:0][34:0] fu_type;
  assign fu_type = {
    io_in_fuTypeRegVec_23, io_in_fuTypeRegVec_22, io_in_fuTypeRegVec_21,
    io_in_fuTypeRegVec_20, io_in_fuTypeRegVec_19, io_in_fuTypeRegVec_18,
    io_in_fuTypeRegVec_17, io_in_fuTypeRegVec_16, io_in_fuTypeRegVec_15,
    io_in_fuTypeRegVec_14, io_in_fuTypeRegVec_13, io_in_fuTypeRegVec_12,
    io_in_fuTypeRegVec_11, io_in_fuTypeRegVec_10, io_in_fuTypeRegVec_9,
    io_in_fuTypeRegVec_8,  io_in_fuTypeRegVec_7,  io_in_fuTypeRegVec_6,
    io_in_fuTypeRegVec_5,  io_in_fuTypeRegVec_4,  io_in_fuTypeRegVec_3,
    io_in_fuTypeRegVec_2,  io_in_fuTypeRegVec_1,  io_in_fuTypeRegVec_0};

  xs_FuBusyTableRead_core #(.NE(NE), .TW(TW), .FU_SEL(FU_SEL)) u_core (
    .fu_busy_table (io_in_fuBusyTable),
    .fu_type       (fu_type),
    .busy_mask     (io_out_fuBusyTableMask)
  );
endmodule
