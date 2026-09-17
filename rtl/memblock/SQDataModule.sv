// =============================================================================
// SQDataModule.sv —— StoreQueue 数据阵列(16 个字节切片的装配壳)
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/mem/lsqueue/StoreQueueData.scala
//        class SQDataModule(numEntries, numRead, numWrite, numForward)
//        —— Scala 注释原话:"SQDataModule is a wrapper of SQData8Modules"
// golden 对照:G1 golden-rtl/SQDataModule.sv(907 行 / 122 端口 / ★0 个寄存器★)
//
// 【它是干什么的】
// 纯装配壳。把 128 位(VLEN)的 store 数据按**字节**切成 16 片,每片交给一个
// SQData8Module 实例;读写地址、使能、以及前递候选掩码 needForward 16 片**共享**,
// 只有数据和掩码按位切开:
//
//   第 i 片拿 data_wdata[8i+7 : 8i]  和  mask_wdata[i]
//   第 i 片的 rdata.valid → io_rdata_*_mask[i]
//   第 i 片的 rdata.data  → io_rdata_*_data[8i+7 : 8i]
//   第 i 片的 forwardValid[p] → io_forwardMask_p_i
//   第 i 片的 forwardData[p]  → io_forwardData_p_i
//
// 为什么按字节切:store 的字节使能(mask)是逐字节的,前递也必须逐字节判断
// ——同一个 load 的 16 个字节完全可能来自 16 条不同的 store。切开之后每片
// 独立做"挑最年轻的命中者",天然就是正确的逐字节前递。
//
// 【★ 本模块自己没有任何状态 ★】
// golden 里 0 个 reg、0 条 always_ff,只有 16 个子模块例化 + 4 条位拼接 + 2 条断言。
// 所有状态都在 SQData8Module 里。所以这里没有复位域问题。
//
// 【★ 端口名的小陷阱:forwardMask vs forwardValid ★】
// 子模块那一侧叫 io_forwardValid_p(一个字节的命中位),到了本模块被聚成
// 16 位的"前递字节掩码",端口名改叫 io_forwardMask_p_i。名字变了,含义没变。
// (golden 的例化行正是 `.io_forwardValid_0 (io_forwardMask_0_0)`。)
//
// 【非综合断言】golden 带 2 条(StoreQueueData.scala:332 / :337):同拍两个写口
// 不许落在同一地址。注意它和子模块里那两条(:211 / :216)是**各自独立**的两份,
// 父子都查一遍。这里同样保留。
// =============================================================================

module SQDataModule(
  input          clock,
  input          reset,
  input  [5:0]   io_raddr_0,
  input  [5:0]   io_raddr_1,
  output [15:0]  io_rdata_0_mask,
  output [127:0] io_rdata_0_data,
  output [15:0]  io_rdata_1_mask,
  output [127:0] io_rdata_1_data,
  input          io_data_wen_0,
  input          io_data_wen_1,
  input  [5:0]   io_data_waddr_0,
  input  [5:0]   io_data_waddr_1,
  input  [127:0] io_data_wdata_0,
  input  [127:0] io_data_wdata_1,
  input          io_mask_wen_0,
  input          io_mask_wen_1,
  input  [5:0]   io_mask_waddr_0,
  input  [5:0]   io_mask_waddr_1,
  input  [15:0]  io_mask_wdata_0,
  input  [15:0]  io_mask_wdata_1,
  input  [55:0]  io_needForward_0_0,
  input  [55:0]  io_needForward_0_1,
  input  [55:0]  io_needForward_1_0,
  input  [55:0]  io_needForward_1_1,
  input  [55:0]  io_needForward_2_0,
  input  [55:0]  io_needForward_2_1,
  output         io_forwardMask_0_0,
  output         io_forwardMask_0_1,
  output         io_forwardMask_0_2,
  output         io_forwardMask_0_3,
  output         io_forwardMask_0_4,
  output         io_forwardMask_0_5,
  output         io_forwardMask_0_6,
  output         io_forwardMask_0_7,
  output         io_forwardMask_0_8,
  output         io_forwardMask_0_9,
  output         io_forwardMask_0_10,
  output         io_forwardMask_0_11,
  output         io_forwardMask_0_12,
  output         io_forwardMask_0_13,
  output         io_forwardMask_0_14,
  output         io_forwardMask_0_15,
  output         io_forwardMask_1_0,
  output         io_forwardMask_1_1,
  output         io_forwardMask_1_2,
  output         io_forwardMask_1_3,
  output         io_forwardMask_1_4,
  output         io_forwardMask_1_5,
  output         io_forwardMask_1_6,
  output         io_forwardMask_1_7,
  output         io_forwardMask_1_8,
  output         io_forwardMask_1_9,
  output         io_forwardMask_1_10,
  output         io_forwardMask_1_11,
  output         io_forwardMask_1_12,
  output         io_forwardMask_1_13,
  output         io_forwardMask_1_14,
  output         io_forwardMask_1_15,
  output         io_forwardMask_2_0,
  output         io_forwardMask_2_1,
  output         io_forwardMask_2_2,
  output         io_forwardMask_2_3,
  output         io_forwardMask_2_4,
  output         io_forwardMask_2_5,
  output         io_forwardMask_2_6,
  output         io_forwardMask_2_7,
  output         io_forwardMask_2_8,
  output         io_forwardMask_2_9,
  output         io_forwardMask_2_10,
  output         io_forwardMask_2_11,
  output         io_forwardMask_2_12,
  output         io_forwardMask_2_13,
  output         io_forwardMask_2_14,
  output         io_forwardMask_2_15,
  output [7:0]   io_forwardData_0_0,
  output [7:0]   io_forwardData_0_1,
  output [7:0]   io_forwardData_0_2,
  output [7:0]   io_forwardData_0_3,
  output [7:0]   io_forwardData_0_4,
  output [7:0]   io_forwardData_0_5,
  output [7:0]   io_forwardData_0_6,
  output [7:0]   io_forwardData_0_7,
  output [7:0]   io_forwardData_0_8,
  output [7:0]   io_forwardData_0_9,
  output [7:0]   io_forwardData_0_10,
  output [7:0]   io_forwardData_0_11,
  output [7:0]   io_forwardData_0_12,
  output [7:0]   io_forwardData_0_13,
  output [7:0]   io_forwardData_0_14,
  output [7:0]   io_forwardData_0_15,
  output [7:0]   io_forwardData_1_0,
  output [7:0]   io_forwardData_1_1,
  output [7:0]   io_forwardData_1_2,
  output [7:0]   io_forwardData_1_3,
  output [7:0]   io_forwardData_1_4,
  output [7:0]   io_forwardData_1_5,
  output [7:0]   io_forwardData_1_6,
  output [7:0]   io_forwardData_1_7,
  output [7:0]   io_forwardData_1_8,
  output [7:0]   io_forwardData_1_9,
  output [7:0]   io_forwardData_1_10,
  output [7:0]   io_forwardData_1_11,
  output [7:0]   io_forwardData_1_12,
  output [7:0]   io_forwardData_1_13,
  output [7:0]   io_forwardData_1_14,
  output [7:0]   io_forwardData_1_15,
  output [7:0]   io_forwardData_2_0,
  output [7:0]   io_forwardData_2_1,
  output [7:0]   io_forwardData_2_2,
  output [7:0]   io_forwardData_2_3,
  output [7:0]   io_forwardData_2_4,
  output [7:0]   io_forwardData_2_5,
  output [7:0]   io_forwardData_2_6,
  output [7:0]   io_forwardData_2_7,
  output [7:0]   io_forwardData_2_8,
  output [7:0]   io_forwardData_2_9,
  output [7:0]   io_forwardData_2_10,
  output [7:0]   io_forwardData_2_11,
  output [7:0]   io_forwardData_2_12,
  output [7:0]   io_forwardData_2_13,
  output [7:0]   io_forwardData_2_14,
  output [7:0]   io_forwardData_2_15);

  // 子模块侧的读结果:16 片 × 2 个读口。
  logic       slice_rvalid [16][2];
  logic [7:0] slice_rdata  [16][2];

  // 前递结果:3 个口 × 16 字节。
  logic       fwd_mask [3][16];
  logic [7:0] fwd_data [3][16];

  // 16 片按字节切开例化。地址/使能/needForward 全片共享,只有数据和掩码切片。
  for (genvar i = 0; i < 16; i++) begin : g_byte
    SQData8Module data16 (
      .clock              (clock),
      .reset              (reset),
      .io_raddr_0         (io_raddr_0),
      .io_raddr_1         (io_raddr_1),
      .io_rdata_0_valid   (slice_rvalid[i][0]),
      .io_rdata_0_data    (slice_rdata [i][0]),
      .io_rdata_1_valid   (slice_rvalid[i][1]),
      .io_rdata_1_data    (slice_rdata [i][1]),
      .io_data_wen_0      (io_data_wen_0),
      .io_data_wen_1      (io_data_wen_1),
      .io_data_waddr_0    (io_data_waddr_0),
      .io_data_waddr_1    (io_data_waddr_1),
      // ★ 按字节切数据:第 i 片只拿第 i 个字节 ★
      .io_data_wdata_0    (io_data_wdata_0[8*i +: 8]),
      .io_data_wdata_1    (io_data_wdata_1[8*i +: 8]),
      .io_mask_wen_0      (io_mask_wen_0),
      .io_mask_wen_1      (io_mask_wen_1),
      .io_mask_waddr_0    (io_mask_waddr_0),
      .io_mask_waddr_1    (io_mask_waddr_1),
      .io_mask_wdata_0    (io_mask_wdata_0[i]),
      .io_mask_wdata_1    (io_mask_wdata_1[i]),
      // 前递候选掩码是"哪些条目比我老",与字节位置无关 → 16 片共享同一份
      .io_needForward_0_0 (io_needForward_0_0),
      .io_needForward_0_1 (io_needForward_0_1),
      .io_needForward_1_0 (io_needForward_1_0),
      .io_needForward_1_1 (io_needForward_1_1),
      .io_needForward_2_0 (io_needForward_2_0),
      .io_needForward_2_1 (io_needForward_2_1),
      // 子模块叫 forwardValid(单字节命中位),聚到本层叫 forwardMask(16 位掩码)
      .io_forwardValid_0  (fwd_mask[0][i]),
      .io_forwardValid_1  (fwd_mask[1][i]),
      .io_forwardValid_2  (fwd_mask[2][i]),
      .io_forwardData_0   (fwd_data[0][i]),
      .io_forwardData_1   (fwd_data[1][i]),
      .io_forwardData_2   (fwd_data[2][i])
    );
  end

  // 读结果重新拼回 128 位数据 + 16 位掩码。
  for (genvar i = 0; i < 16; i++) begin : g_rdata
    assign io_rdata_0_mask[i]        = slice_rvalid[i][0];
    assign io_rdata_0_data[8*i +: 8] = slice_rdata [i][0];
    assign io_rdata_1_mask[i]        = slice_rvalid[i][1];
    assign io_rdata_1_data[8*i +: 8] = slice_rdata [i][1];
  end

  // 前递结果摊平成 golden 的扁平端口。
  assign io_forwardMask_0_0 = fwd_mask[0][0];
  assign io_forwardMask_0_1 = fwd_mask[0][1];
  assign io_forwardMask_0_2 = fwd_mask[0][2];
  assign io_forwardMask_0_3 = fwd_mask[0][3];
  assign io_forwardMask_0_4 = fwd_mask[0][4];
  assign io_forwardMask_0_5 = fwd_mask[0][5];
  assign io_forwardMask_0_6 = fwd_mask[0][6];
  assign io_forwardMask_0_7 = fwd_mask[0][7];
  assign io_forwardMask_0_8 = fwd_mask[0][8];
  assign io_forwardMask_0_9 = fwd_mask[0][9];
  assign io_forwardMask_0_10 = fwd_mask[0][10];
  assign io_forwardMask_0_11 = fwd_mask[0][11];
  assign io_forwardMask_0_12 = fwd_mask[0][12];
  assign io_forwardMask_0_13 = fwd_mask[0][13];
  assign io_forwardMask_0_14 = fwd_mask[0][14];
  assign io_forwardMask_0_15 = fwd_mask[0][15];
  assign io_forwardMask_1_0 = fwd_mask[1][0];
  assign io_forwardMask_1_1 = fwd_mask[1][1];
  assign io_forwardMask_1_2 = fwd_mask[1][2];
  assign io_forwardMask_1_3 = fwd_mask[1][3];
  assign io_forwardMask_1_4 = fwd_mask[1][4];
  assign io_forwardMask_1_5 = fwd_mask[1][5];
  assign io_forwardMask_1_6 = fwd_mask[1][6];
  assign io_forwardMask_1_7 = fwd_mask[1][7];
  assign io_forwardMask_1_8 = fwd_mask[1][8];
  assign io_forwardMask_1_9 = fwd_mask[1][9];
  assign io_forwardMask_1_10 = fwd_mask[1][10];
  assign io_forwardMask_1_11 = fwd_mask[1][11];
  assign io_forwardMask_1_12 = fwd_mask[1][12];
  assign io_forwardMask_1_13 = fwd_mask[1][13];
  assign io_forwardMask_1_14 = fwd_mask[1][14];
  assign io_forwardMask_1_15 = fwd_mask[1][15];
  assign io_forwardMask_2_0 = fwd_mask[2][0];
  assign io_forwardMask_2_1 = fwd_mask[2][1];
  assign io_forwardMask_2_2 = fwd_mask[2][2];
  assign io_forwardMask_2_3 = fwd_mask[2][3];
  assign io_forwardMask_2_4 = fwd_mask[2][4];
  assign io_forwardMask_2_5 = fwd_mask[2][5];
  assign io_forwardMask_2_6 = fwd_mask[2][6];
  assign io_forwardMask_2_7 = fwd_mask[2][7];
  assign io_forwardMask_2_8 = fwd_mask[2][8];
  assign io_forwardMask_2_9 = fwd_mask[2][9];
  assign io_forwardMask_2_10 = fwd_mask[2][10];
  assign io_forwardMask_2_11 = fwd_mask[2][11];
  assign io_forwardMask_2_12 = fwd_mask[2][12];
  assign io_forwardMask_2_13 = fwd_mask[2][13];
  assign io_forwardMask_2_14 = fwd_mask[2][14];
  assign io_forwardMask_2_15 = fwd_mask[2][15];
  assign io_forwardData_0_0 = fwd_data[0][0];
  assign io_forwardData_0_1 = fwd_data[0][1];
  assign io_forwardData_0_2 = fwd_data[0][2];
  assign io_forwardData_0_3 = fwd_data[0][3];
  assign io_forwardData_0_4 = fwd_data[0][4];
  assign io_forwardData_0_5 = fwd_data[0][5];
  assign io_forwardData_0_6 = fwd_data[0][6];
  assign io_forwardData_0_7 = fwd_data[0][7];
  assign io_forwardData_0_8 = fwd_data[0][8];
  assign io_forwardData_0_9 = fwd_data[0][9];
  assign io_forwardData_0_10 = fwd_data[0][10];
  assign io_forwardData_0_11 = fwd_data[0][11];
  assign io_forwardData_0_12 = fwd_data[0][12];
  assign io_forwardData_0_13 = fwd_data[0][13];
  assign io_forwardData_0_14 = fwd_data[0][14];
  assign io_forwardData_0_15 = fwd_data[0][15];
  assign io_forwardData_1_0 = fwd_data[1][0];
  assign io_forwardData_1_1 = fwd_data[1][1];
  assign io_forwardData_1_2 = fwd_data[1][2];
  assign io_forwardData_1_3 = fwd_data[1][3];
  assign io_forwardData_1_4 = fwd_data[1][4];
  assign io_forwardData_1_5 = fwd_data[1][5];
  assign io_forwardData_1_6 = fwd_data[1][6];
  assign io_forwardData_1_7 = fwd_data[1][7];
  assign io_forwardData_1_8 = fwd_data[1][8];
  assign io_forwardData_1_9 = fwd_data[1][9];
  assign io_forwardData_1_10 = fwd_data[1][10];
  assign io_forwardData_1_11 = fwd_data[1][11];
  assign io_forwardData_1_12 = fwd_data[1][12];
  assign io_forwardData_1_13 = fwd_data[1][13];
  assign io_forwardData_1_14 = fwd_data[1][14];
  assign io_forwardData_1_15 = fwd_data[1][15];
  assign io_forwardData_2_0 = fwd_data[2][0];
  assign io_forwardData_2_1 = fwd_data[2][1];
  assign io_forwardData_2_2 = fwd_data[2][2];
  assign io_forwardData_2_3 = fwd_data[2][3];
  assign io_forwardData_2_4 = fwd_data[2][4];
  assign io_forwardData_2_5 = fwd_data[2][5];
  assign io_forwardData_2_6 = fwd_data[2][6];
  assign io_forwardData_2_7 = fwd_data[2][7];
  assign io_forwardData_2_8 = fwd_data[2][8];
  assign io_forwardData_2_9 = fwd_data[2][9];
  assign io_forwardData_2_10 = fwd_data[2][10];
  assign io_forwardData_2_11 = fwd_data[2][11];
  assign io_forwardData_2_12 = fwd_data[2][12];
  assign io_forwardData_2_13 = fwd_data[2][13];
  assign io_forwardData_2_14 = fwd_data[2][14];
  assign io_forwardData_2_15 = fwd_data[2][15];

  // ---------------------------------------------------------------------------
  // 接口契约断言(StoreQueueData.scala:332 / :337)
  // ---------------------------------------------------------------------------
  // 与子模块里的 :211/:216 是各自独立的两份,父子都查。
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (~reset) begin
      assert (!(io_data_wen_0 && io_data_wen_1 && io_data_waddr_0 == io_data_waddr_1))
        else $fatal(1, "SQDataModule: data write ports collide on entry %0d", io_data_waddr_0);
      assert (!(io_mask_wen_0 && io_mask_wen_1 && io_mask_waddr_0 == io_mask_waddr_1))
        else $fatal(1, "SQDataModule: mask write ports collide on entry %0d", io_mask_waddr_0);
    end
  end
`endif

endmodule
