// SyncDataModuleTemplate__64entry_4 —— 外层同步读存储（分 bank + 输入寄存器复制）
// 形状：64 项 × 9 位，8 读口 / 6 写口；载荷字段：vtype_illegal, vtype_vma, vtype_vta, vtype_vsew…
// 核体见 rtl/common/xs_SyncDataModule.sv；本文件只做参数化与端口展平。
// 自动生成：scripts/gen_dm_wrappers.py（G1 基线驱动）—— 勿手改
module SyncDataModuleTemplate__64entry_4(
  input  clock,
  input  reset,
  input  [5:0] io_raddr_0,
  input  [5:0] io_raddr_1,
  input  [5:0] io_raddr_2,
  input  [5:0] io_raddr_3,
  input  [5:0] io_raddr_4,
  input  [5:0] io_raddr_5,
  input  [5:0] io_raddr_6,
  input  [5:0] io_raddr_7,
  output io_rdata_0_vtype_illegal,
  output io_rdata_0_vtype_vma,
  output io_rdata_0_vtype_vta,
  output [1:0] io_rdata_0_vtype_vsew,
  output [2:0] io_rdata_0_vtype_vlmul,
  output io_rdata_0_isVsetvl,
  output io_rdata_1_vtype_illegal,
  output io_rdata_1_vtype_vma,
  output io_rdata_1_vtype_vta,
  output [1:0] io_rdata_1_vtype_vsew,
  output [2:0] io_rdata_1_vtype_vlmul,
  output io_rdata_1_isVsetvl,
  output io_rdata_2_vtype_illegal,
  output io_rdata_2_vtype_vma,
  output io_rdata_2_vtype_vta,
  output [1:0] io_rdata_2_vtype_vsew,
  output [2:0] io_rdata_2_vtype_vlmul,
  output io_rdata_2_isVsetvl,
  output io_rdata_3_vtype_illegal,
  output io_rdata_3_vtype_vma,
  output io_rdata_3_vtype_vta,
  output [1:0] io_rdata_3_vtype_vsew,
  output [2:0] io_rdata_3_vtype_vlmul,
  output io_rdata_3_isVsetvl,
  output io_rdata_4_vtype_illegal,
  output io_rdata_4_vtype_vma,
  output io_rdata_4_vtype_vta,
  output [1:0] io_rdata_4_vtype_vsew,
  output [2:0] io_rdata_4_vtype_vlmul,
  output io_rdata_4_isVsetvl,
  output io_rdata_5_vtype_illegal,
  output io_rdata_5_vtype_vma,
  output io_rdata_5_vtype_vta,
  output [1:0] io_rdata_5_vtype_vsew,
  output [2:0] io_rdata_5_vtype_vlmul,
  output io_rdata_5_isVsetvl,
  output io_rdata_6_vtype_illegal,
  output io_rdata_6_vtype_vma,
  output io_rdata_6_vtype_vta,
  output [1:0] io_rdata_6_vtype_vsew,
  output [2:0] io_rdata_6_vtype_vlmul,
  output io_rdata_6_isVsetvl,
  output io_rdata_7_vtype_illegal,
  output io_rdata_7_vtype_vma,
  output io_rdata_7_vtype_vta,
  output [1:0] io_rdata_7_vtype_vsew,
  output [2:0] io_rdata_7_vtype_vlmul,
  output io_rdata_7_isVsetvl,
  input  io_wen_0,
  input  io_wen_1,
  input  io_wen_2,
  input  io_wen_3,
  input  io_wen_4,
  input  io_wen_5,
  input  [5:0] io_waddr_0,
  input  [5:0] io_waddr_1,
  input  [5:0] io_waddr_2,
  input  [5:0] io_waddr_3,
  input  [5:0] io_waddr_4,
  input  [5:0] io_waddr_5,
  input  io_wdata_0_vtype_illegal,
  input  io_wdata_0_vtype_vma,
  input  io_wdata_0_vtype_vta,
  input  [1:0] io_wdata_0_vtype_vsew,
  input  [2:0] io_wdata_0_vtype_vlmul,
  input  io_wdata_0_isVsetvl,
  input  io_wdata_1_vtype_illegal,
  input  io_wdata_1_vtype_vma,
  input  io_wdata_1_vtype_vta,
  input  [1:0] io_wdata_1_vtype_vsew,
  input  [2:0] io_wdata_1_vtype_vlmul,
  input  io_wdata_1_isVsetvl,
  input  io_wdata_2_vtype_illegal,
  input  io_wdata_2_vtype_vma,
  input  io_wdata_2_vtype_vta,
  input  [1:0] io_wdata_2_vtype_vsew,
  input  [2:0] io_wdata_2_vtype_vlmul,
  input  io_wdata_2_isVsetvl,
  input  io_wdata_3_vtype_illegal,
  input  io_wdata_3_vtype_vma,
  input  io_wdata_3_vtype_vta,
  input  [1:0] io_wdata_3_vtype_vsew,
  input  [2:0] io_wdata_3_vtype_vlmul,
  input  io_wdata_3_isVsetvl,
  input  io_wdata_4_vtype_illegal,
  input  io_wdata_4_vtype_vma,
  input  io_wdata_4_vtype_vta,
  input  [1:0] io_wdata_4_vtype_vsew,
  input  [2:0] io_wdata_4_vtype_vlmul,
  input  io_wdata_4_isVsetvl,
  input  io_wdata_5_vtype_illegal,
  input  io_wdata_5_vtype_vma,
  input  io_wdata_5_vtype_vta,
  input  [1:0] io_wdata_5_vtype_vsew,
  input  [2:0] io_wdata_5_vtype_vlmul,
  input  io_wdata_5_isVsetvl
);
  wire [8-1:0][9-1:0] rdata_bus;
  assign io_rdata_0_vtype_illegal = rdata_bus[0][0:0];
  assign io_rdata_0_vtype_vma = rdata_bus[0][1:1];
  assign io_rdata_0_vtype_vta = rdata_bus[0][2:2];
  assign io_rdata_0_vtype_vsew = rdata_bus[0][4:3];
  assign io_rdata_0_vtype_vlmul = rdata_bus[0][7:5];
  assign io_rdata_0_isVsetvl = rdata_bus[0][8:8];
  assign io_rdata_1_vtype_illegal = rdata_bus[1][0:0];
  assign io_rdata_1_vtype_vma = rdata_bus[1][1:1];
  assign io_rdata_1_vtype_vta = rdata_bus[1][2:2];
  assign io_rdata_1_vtype_vsew = rdata_bus[1][4:3];
  assign io_rdata_1_vtype_vlmul = rdata_bus[1][7:5];
  assign io_rdata_1_isVsetvl = rdata_bus[1][8:8];
  assign io_rdata_2_vtype_illegal = rdata_bus[2][0:0];
  assign io_rdata_2_vtype_vma = rdata_bus[2][1:1];
  assign io_rdata_2_vtype_vta = rdata_bus[2][2:2];
  assign io_rdata_2_vtype_vsew = rdata_bus[2][4:3];
  assign io_rdata_2_vtype_vlmul = rdata_bus[2][7:5];
  assign io_rdata_2_isVsetvl = rdata_bus[2][8:8];
  assign io_rdata_3_vtype_illegal = rdata_bus[3][0:0];
  assign io_rdata_3_vtype_vma = rdata_bus[3][1:1];
  assign io_rdata_3_vtype_vta = rdata_bus[3][2:2];
  assign io_rdata_3_vtype_vsew = rdata_bus[3][4:3];
  assign io_rdata_3_vtype_vlmul = rdata_bus[3][7:5];
  assign io_rdata_3_isVsetvl = rdata_bus[3][8:8];
  assign io_rdata_4_vtype_illegal = rdata_bus[4][0:0];
  assign io_rdata_4_vtype_vma = rdata_bus[4][1:1];
  assign io_rdata_4_vtype_vta = rdata_bus[4][2:2];
  assign io_rdata_4_vtype_vsew = rdata_bus[4][4:3];
  assign io_rdata_4_vtype_vlmul = rdata_bus[4][7:5];
  assign io_rdata_4_isVsetvl = rdata_bus[4][8:8];
  assign io_rdata_5_vtype_illegal = rdata_bus[5][0:0];
  assign io_rdata_5_vtype_vma = rdata_bus[5][1:1];
  assign io_rdata_5_vtype_vta = rdata_bus[5][2:2];
  assign io_rdata_5_vtype_vsew = rdata_bus[5][4:3];
  assign io_rdata_5_vtype_vlmul = rdata_bus[5][7:5];
  assign io_rdata_5_isVsetvl = rdata_bus[5][8:8];
  assign io_rdata_6_vtype_illegal = rdata_bus[6][0:0];
  assign io_rdata_6_vtype_vma = rdata_bus[6][1:1];
  assign io_rdata_6_vtype_vta = rdata_bus[6][2:2];
  assign io_rdata_6_vtype_vsew = rdata_bus[6][4:3];
  assign io_rdata_6_vtype_vlmul = rdata_bus[6][7:5];
  assign io_rdata_6_isVsetvl = rdata_bus[6][8:8];
  assign io_rdata_7_vtype_illegal = rdata_bus[7][0:0];
  assign io_rdata_7_vtype_vma = rdata_bus[7][1:1];
  assign io_rdata_7_vtype_vta = rdata_bus[7][2:2];
  assign io_rdata_7_vtype_vsew = rdata_bus[7][4:3];
  assign io_rdata_7_vtype_vlmul = rdata_bus[7][7:5];
  assign io_rdata_7_isVsetvl = rdata_bus[7][8:8];
  xs_SyncDataModule #(
    .NUM_ENTRIES(64),
    .NUM_READ(8),
    .NUM_WRITE(6),
    .DATA_WIDTH(9),
    .HAS_REN(0),
    .BYPASS_EN(8'b11111111),
    // G1 锚点：golden SyncDataModuleTemplate__64entry_4.sv 里例化了 4 个 DataModule* 子模块 = 应分出的 bank 数
    .G1_NUM_BANKS(4)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .io_ren({8{1'b1}}),
    .io_raddr({io_raddr_7, io_raddr_6, io_raddr_5, io_raddr_4, io_raddr_3, io_raddr_2, io_raddr_1, io_raddr_0}),
    .io_rdata(rdata_bus),
    .io_wen({io_wen_5, io_wen_4, io_wen_3, io_wen_2, io_wen_1, io_wen_0}),
    .io_waddr({io_waddr_5, io_waddr_4, io_waddr_3, io_waddr_2, io_waddr_1, io_waddr_0}),
    .io_wdata({{io_wdata_5_isVsetvl, io_wdata_5_vtype_vlmul, io_wdata_5_vtype_vsew, io_wdata_5_vtype_vta, io_wdata_5_vtype_vma, io_wdata_5_vtype_illegal}, {io_wdata_4_isVsetvl, io_wdata_4_vtype_vlmul, io_wdata_4_vtype_vsew, io_wdata_4_vtype_vta, io_wdata_4_vtype_vma, io_wdata_4_vtype_illegal}, {io_wdata_3_isVsetvl, io_wdata_3_vtype_vlmul, io_wdata_3_vtype_vsew, io_wdata_3_vtype_vta, io_wdata_3_vtype_vma, io_wdata_3_vtype_illegal}, {io_wdata_2_isVsetvl, io_wdata_2_vtype_vlmul, io_wdata_2_vtype_vsew, io_wdata_2_vtype_vta, io_wdata_2_vtype_vma, io_wdata_2_vtype_illegal}, {io_wdata_1_isVsetvl, io_wdata_1_vtype_vlmul, io_wdata_1_vtype_vsew, io_wdata_1_vtype_vta, io_wdata_1_vtype_vma, io_wdata_1_vtype_illegal}, {io_wdata_0_isVsetvl, io_wdata_0_vtype_vlmul, io_wdata_0_vtype_vsew, io_wdata_0_vtype_vta, io_wdata_0_vtype_vma, io_wdata_0_vtype_illegal}})
  );
endmodule
