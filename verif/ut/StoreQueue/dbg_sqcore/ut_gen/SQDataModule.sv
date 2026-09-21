// =============================================================================
// SQDataModule_xs.sv —— StoreQueue_xs 数据阵列(16 个字节切片的装配壳)
// -----------------------------------------------------------------------------
// 设计源:XiangShan src/main/scala/xiangshan/mem/lsqueue/StoreQueueData.scala
//        class SQDataModule_xs(numEntries, numRead, numWrite, numForward)
//        —— Scala 注释原话:"SQDataModule_xs is a wrapper of SQData8Modules"
// golden 对照:G1 golden-rtl/SQDataModule_xs.sv(907 行 / 122 端口 / ★0 个寄存器★)
//
// 【它是干什么的】
// 纯装配壳。把 128 位(VLEN)的 store 数据按**字节**切成 16 片,每片交给一个
// SQData8Module_xs 实例;读写地址、使能、以及前递候选掩码 needForward 16 片**共享**,
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
// 所有状态都在 SQData8Module_xs 里。所以这里没有复位域问题。
//
// 【★ 端口名的小陷阱:forwardMask vs forwardValid ★】
// 子模块那一侧叫 io_forwardValid_p(一个字节的命中位),到了本模块被聚成
// 16 位的"前递字节掩码",端口名改叫 io_forwardMask_p_i。名字变了,含义没变。
// (golden 的例化行正是 `.io_forwardValid_0 (io_forwardMask_0_0)`。)
//
// 【★ 16 个子模块为什么是展开写而不是 generate 循环 ★】
// FM 按**名字**配对层次。golden 的实例名是扁平的 data16_0 … data16_15;
// generate 循环在 SV 里只能生成 g_byte[i].data16 这种带块名的路径,两边对不上。
// 实测代价:17984 个 unmatched(ref 与 impl 各 17984)+ 20 failing + 700 unverified,
// 整个目标判 FAILED。修法是**按 golden 的名字展开写 16 个实例**,不是去加名字
// 映射文件或放宽判据。下面的实例体由 scratchpad/gen_sqdata.py 机械生成,
// 16 份只有字节下标不同。
//
// 【非综合断言】golden 带 2 条(StoreQueueData.scala:332 / :337):同拍两个写口
// 不许落在同一地址。注意它和子模块里那两条(:211 / :216)是**各自独立**的两份,
// 父子都查一遍。这里同样保留。
// =============================================================================

module SQDataModule_xs(
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

  // 16 片按字节切开例化 —— ★实例名必须与 golden 逐个一致(data16_<i>)★,
  // 见文件头。地址/使能/needForward 全片共享,只有数据和掩码按位切片。
  SQData8Module_xs data16_0 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[0][0]),
    .io_rdata_0_data    (slice_rdata [0][0]),
    .io_rdata_1_valid   (slice_rvalid[0][1]),
    .io_rdata_1_data    (slice_rdata [0][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[0 +: 8]),   // 第 0 个字节
    .io_data_wdata_1    (io_data_wdata_1[0 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[0]),
    .io_mask_wdata_1    (io_mask_wdata_1[0]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][0]),
    .io_forwardValid_1  (fwd_mask[1][0]),
    .io_forwardValid_2  (fwd_mask[2][0]),
    .io_forwardData_0   (fwd_data[0][0]),
    .io_forwardData_1   (fwd_data[1][0]),
    .io_forwardData_2   (fwd_data[2][0])
  );
  SQData8Module_xs data16_1 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[1][0]),
    .io_rdata_0_data    (slice_rdata [1][0]),
    .io_rdata_1_valid   (slice_rvalid[1][1]),
    .io_rdata_1_data    (slice_rdata [1][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[8 +: 8]),   // 第 1 个字节
    .io_data_wdata_1    (io_data_wdata_1[8 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[1]),
    .io_mask_wdata_1    (io_mask_wdata_1[1]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][1]),
    .io_forwardValid_1  (fwd_mask[1][1]),
    .io_forwardValid_2  (fwd_mask[2][1]),
    .io_forwardData_0   (fwd_data[0][1]),
    .io_forwardData_1   (fwd_data[1][1]),
    .io_forwardData_2   (fwd_data[2][1])
  );
  SQData8Module_xs data16_2 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[2][0]),
    .io_rdata_0_data    (slice_rdata [2][0]),
    .io_rdata_1_valid   (slice_rvalid[2][1]),
    .io_rdata_1_data    (slice_rdata [2][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[16 +: 8]),   // 第 2 个字节
    .io_data_wdata_1    (io_data_wdata_1[16 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[2]),
    .io_mask_wdata_1    (io_mask_wdata_1[2]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][2]),
    .io_forwardValid_1  (fwd_mask[1][2]),
    .io_forwardValid_2  (fwd_mask[2][2]),
    .io_forwardData_0   (fwd_data[0][2]),
    .io_forwardData_1   (fwd_data[1][2]),
    .io_forwardData_2   (fwd_data[2][2])
  );
  SQData8Module_xs data16_3 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[3][0]),
    .io_rdata_0_data    (slice_rdata [3][0]),
    .io_rdata_1_valid   (slice_rvalid[3][1]),
    .io_rdata_1_data    (slice_rdata [3][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[24 +: 8]),   // 第 3 个字节
    .io_data_wdata_1    (io_data_wdata_1[24 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[3]),
    .io_mask_wdata_1    (io_mask_wdata_1[3]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][3]),
    .io_forwardValid_1  (fwd_mask[1][3]),
    .io_forwardValid_2  (fwd_mask[2][3]),
    .io_forwardData_0   (fwd_data[0][3]),
    .io_forwardData_1   (fwd_data[1][3]),
    .io_forwardData_2   (fwd_data[2][3])
  );
  SQData8Module_xs data16_4 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[4][0]),
    .io_rdata_0_data    (slice_rdata [4][0]),
    .io_rdata_1_valid   (slice_rvalid[4][1]),
    .io_rdata_1_data    (slice_rdata [4][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[32 +: 8]),   // 第 4 个字节
    .io_data_wdata_1    (io_data_wdata_1[32 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[4]),
    .io_mask_wdata_1    (io_mask_wdata_1[4]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][4]),
    .io_forwardValid_1  (fwd_mask[1][4]),
    .io_forwardValid_2  (fwd_mask[2][4]),
    .io_forwardData_0   (fwd_data[0][4]),
    .io_forwardData_1   (fwd_data[1][4]),
    .io_forwardData_2   (fwd_data[2][4])
  );
  SQData8Module_xs data16_5 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[5][0]),
    .io_rdata_0_data    (slice_rdata [5][0]),
    .io_rdata_1_valid   (slice_rvalid[5][1]),
    .io_rdata_1_data    (slice_rdata [5][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[40 +: 8]),   // 第 5 个字节
    .io_data_wdata_1    (io_data_wdata_1[40 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[5]),
    .io_mask_wdata_1    (io_mask_wdata_1[5]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][5]),
    .io_forwardValid_1  (fwd_mask[1][5]),
    .io_forwardValid_2  (fwd_mask[2][5]),
    .io_forwardData_0   (fwd_data[0][5]),
    .io_forwardData_1   (fwd_data[1][5]),
    .io_forwardData_2   (fwd_data[2][5])
  );
  SQData8Module_xs data16_6 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[6][0]),
    .io_rdata_0_data    (slice_rdata [6][0]),
    .io_rdata_1_valid   (slice_rvalid[6][1]),
    .io_rdata_1_data    (slice_rdata [6][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[48 +: 8]),   // 第 6 个字节
    .io_data_wdata_1    (io_data_wdata_1[48 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[6]),
    .io_mask_wdata_1    (io_mask_wdata_1[6]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][6]),
    .io_forwardValid_1  (fwd_mask[1][6]),
    .io_forwardValid_2  (fwd_mask[2][6]),
    .io_forwardData_0   (fwd_data[0][6]),
    .io_forwardData_1   (fwd_data[1][6]),
    .io_forwardData_2   (fwd_data[2][6])
  );
  SQData8Module_xs data16_7 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[7][0]),
    .io_rdata_0_data    (slice_rdata [7][0]),
    .io_rdata_1_valid   (slice_rvalid[7][1]),
    .io_rdata_1_data    (slice_rdata [7][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[56 +: 8]),   // 第 7 个字节
    .io_data_wdata_1    (io_data_wdata_1[56 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[7]),
    .io_mask_wdata_1    (io_mask_wdata_1[7]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][7]),
    .io_forwardValid_1  (fwd_mask[1][7]),
    .io_forwardValid_2  (fwd_mask[2][7]),
    .io_forwardData_0   (fwd_data[0][7]),
    .io_forwardData_1   (fwd_data[1][7]),
    .io_forwardData_2   (fwd_data[2][7])
  );
  SQData8Module_xs data16_8 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[8][0]),
    .io_rdata_0_data    (slice_rdata [8][0]),
    .io_rdata_1_valid   (slice_rvalid[8][1]),
    .io_rdata_1_data    (slice_rdata [8][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[64 +: 8]),   // 第 8 个字节
    .io_data_wdata_1    (io_data_wdata_1[64 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[8]),
    .io_mask_wdata_1    (io_mask_wdata_1[8]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][8]),
    .io_forwardValid_1  (fwd_mask[1][8]),
    .io_forwardValid_2  (fwd_mask[2][8]),
    .io_forwardData_0   (fwd_data[0][8]),
    .io_forwardData_1   (fwd_data[1][8]),
    .io_forwardData_2   (fwd_data[2][8])
  );
  SQData8Module_xs data16_9 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[9][0]),
    .io_rdata_0_data    (slice_rdata [9][0]),
    .io_rdata_1_valid   (slice_rvalid[9][1]),
    .io_rdata_1_data    (slice_rdata [9][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[72 +: 8]),   // 第 9 个字节
    .io_data_wdata_1    (io_data_wdata_1[72 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[9]),
    .io_mask_wdata_1    (io_mask_wdata_1[9]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][9]),
    .io_forwardValid_1  (fwd_mask[1][9]),
    .io_forwardValid_2  (fwd_mask[2][9]),
    .io_forwardData_0   (fwd_data[0][9]),
    .io_forwardData_1   (fwd_data[1][9]),
    .io_forwardData_2   (fwd_data[2][9])
  );
  SQData8Module_xs data16_10 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[10][0]),
    .io_rdata_0_data    (slice_rdata [10][0]),
    .io_rdata_1_valid   (slice_rvalid[10][1]),
    .io_rdata_1_data    (slice_rdata [10][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[80 +: 8]),   // 第 10 个字节
    .io_data_wdata_1    (io_data_wdata_1[80 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[10]),
    .io_mask_wdata_1    (io_mask_wdata_1[10]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][10]),
    .io_forwardValid_1  (fwd_mask[1][10]),
    .io_forwardValid_2  (fwd_mask[2][10]),
    .io_forwardData_0   (fwd_data[0][10]),
    .io_forwardData_1   (fwd_data[1][10]),
    .io_forwardData_2   (fwd_data[2][10])
  );
  SQData8Module_xs data16_11 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[11][0]),
    .io_rdata_0_data    (slice_rdata [11][0]),
    .io_rdata_1_valid   (slice_rvalid[11][1]),
    .io_rdata_1_data    (slice_rdata [11][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[88 +: 8]),   // 第 11 个字节
    .io_data_wdata_1    (io_data_wdata_1[88 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[11]),
    .io_mask_wdata_1    (io_mask_wdata_1[11]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][11]),
    .io_forwardValid_1  (fwd_mask[1][11]),
    .io_forwardValid_2  (fwd_mask[2][11]),
    .io_forwardData_0   (fwd_data[0][11]),
    .io_forwardData_1   (fwd_data[1][11]),
    .io_forwardData_2   (fwd_data[2][11])
  );
  SQData8Module_xs data16_12 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[12][0]),
    .io_rdata_0_data    (slice_rdata [12][0]),
    .io_rdata_1_valid   (slice_rvalid[12][1]),
    .io_rdata_1_data    (slice_rdata [12][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[96 +: 8]),   // 第 12 个字节
    .io_data_wdata_1    (io_data_wdata_1[96 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[12]),
    .io_mask_wdata_1    (io_mask_wdata_1[12]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][12]),
    .io_forwardValid_1  (fwd_mask[1][12]),
    .io_forwardValid_2  (fwd_mask[2][12]),
    .io_forwardData_0   (fwd_data[0][12]),
    .io_forwardData_1   (fwd_data[1][12]),
    .io_forwardData_2   (fwd_data[2][12])
  );
  SQData8Module_xs data16_13 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[13][0]),
    .io_rdata_0_data    (slice_rdata [13][0]),
    .io_rdata_1_valid   (slice_rvalid[13][1]),
    .io_rdata_1_data    (slice_rdata [13][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[104 +: 8]),   // 第 13 个字节
    .io_data_wdata_1    (io_data_wdata_1[104 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[13]),
    .io_mask_wdata_1    (io_mask_wdata_1[13]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][13]),
    .io_forwardValid_1  (fwd_mask[1][13]),
    .io_forwardValid_2  (fwd_mask[2][13]),
    .io_forwardData_0   (fwd_data[0][13]),
    .io_forwardData_1   (fwd_data[1][13]),
    .io_forwardData_2   (fwd_data[2][13])
  );
  SQData8Module_xs data16_14 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[14][0]),
    .io_rdata_0_data    (slice_rdata [14][0]),
    .io_rdata_1_valid   (slice_rvalid[14][1]),
    .io_rdata_1_data    (slice_rdata [14][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[112 +: 8]),   // 第 14 个字节
    .io_data_wdata_1    (io_data_wdata_1[112 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[14]),
    .io_mask_wdata_1    (io_mask_wdata_1[14]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][14]),
    .io_forwardValid_1  (fwd_mask[1][14]),
    .io_forwardValid_2  (fwd_mask[2][14]),
    .io_forwardData_0   (fwd_data[0][14]),
    .io_forwardData_1   (fwd_data[1][14]),
    .io_forwardData_2   (fwd_data[2][14])
  );
  SQData8Module_xs data16_15 (
    .clock              (clock),
    .reset              (reset),
    .io_raddr_0         (io_raddr_0),
    .io_raddr_1         (io_raddr_1),
    .io_rdata_0_valid   (slice_rvalid[15][0]),
    .io_rdata_0_data    (slice_rdata [15][0]),
    .io_rdata_1_valid   (slice_rvalid[15][1]),
    .io_rdata_1_data    (slice_rdata [15][1]),
    .io_data_wen_0      (io_data_wen_0),
    .io_data_wen_1      (io_data_wen_1),
    .io_data_waddr_0    (io_data_waddr_0),
    .io_data_waddr_1    (io_data_waddr_1),
    .io_data_wdata_0    (io_data_wdata_0[120 +: 8]),   // 第 15 个字节
    .io_data_wdata_1    (io_data_wdata_1[120 +: 8]),
    .io_mask_wen_0      (io_mask_wen_0),
    .io_mask_wen_1      (io_mask_wen_1),
    .io_mask_waddr_0    (io_mask_waddr_0),
    .io_mask_waddr_1    (io_mask_waddr_1),
    .io_mask_wdata_0    (io_mask_wdata_0[15]),
    .io_mask_wdata_1    (io_mask_wdata_1[15]),
    .io_needForward_0_0 (io_needForward_0_0),
    .io_needForward_0_1 (io_needForward_0_1),
    .io_needForward_1_0 (io_needForward_1_0),
    .io_needForward_1_1 (io_needForward_1_1),
    .io_needForward_2_0 (io_needForward_2_0),
    .io_needForward_2_1 (io_needForward_2_1),
    .io_forwardValid_0  (fwd_mask[0][15]),
    .io_forwardValid_1  (fwd_mask[1][15]),
    .io_forwardValid_2  (fwd_mask[2][15]),
    .io_forwardData_0   (fwd_data[0][15]),
    .io_forwardData_1   (fwd_data[1][15]),
    .io_forwardData_2   (fwd_data[2][15])
  );

  // 读结果重新拼回 128 位数据 + 16 位掩码。
  assign io_rdata_0_mask[0]      = slice_rvalid[0][0];
  assign io_rdata_0_data[0 +: 8] = slice_rdata [0][0];
  assign io_rdata_1_mask[0]      = slice_rvalid[0][1];
  assign io_rdata_1_data[0 +: 8] = slice_rdata [0][1];
  assign io_rdata_0_mask[1]      = slice_rvalid[1][0];
  assign io_rdata_0_data[8 +: 8] = slice_rdata [1][0];
  assign io_rdata_1_mask[1]      = slice_rvalid[1][1];
  assign io_rdata_1_data[8 +: 8] = slice_rdata [1][1];
  assign io_rdata_0_mask[2]      = slice_rvalid[2][0];
  assign io_rdata_0_data[16 +: 8] = slice_rdata [2][0];
  assign io_rdata_1_mask[2]      = slice_rvalid[2][1];
  assign io_rdata_1_data[16 +: 8] = slice_rdata [2][1];
  assign io_rdata_0_mask[3]      = slice_rvalid[3][0];
  assign io_rdata_0_data[24 +: 8] = slice_rdata [3][0];
  assign io_rdata_1_mask[3]      = slice_rvalid[3][1];
  assign io_rdata_1_data[24 +: 8] = slice_rdata [3][1];
  assign io_rdata_0_mask[4]      = slice_rvalid[4][0];
  assign io_rdata_0_data[32 +: 8] = slice_rdata [4][0];
  assign io_rdata_1_mask[4]      = slice_rvalid[4][1];
  assign io_rdata_1_data[32 +: 8] = slice_rdata [4][1];
  assign io_rdata_0_mask[5]      = slice_rvalid[5][0];
  assign io_rdata_0_data[40 +: 8] = slice_rdata [5][0];
  assign io_rdata_1_mask[5]      = slice_rvalid[5][1];
  assign io_rdata_1_data[40 +: 8] = slice_rdata [5][1];
  assign io_rdata_0_mask[6]      = slice_rvalid[6][0];
  assign io_rdata_0_data[48 +: 8] = slice_rdata [6][0];
  assign io_rdata_1_mask[6]      = slice_rvalid[6][1];
  assign io_rdata_1_data[48 +: 8] = slice_rdata [6][1];
  assign io_rdata_0_mask[7]      = slice_rvalid[7][0];
  assign io_rdata_0_data[56 +: 8] = slice_rdata [7][0];
  assign io_rdata_1_mask[7]      = slice_rvalid[7][1];
  assign io_rdata_1_data[56 +: 8] = slice_rdata [7][1];
  assign io_rdata_0_mask[8]      = slice_rvalid[8][0];
  assign io_rdata_0_data[64 +: 8] = slice_rdata [8][0];
  assign io_rdata_1_mask[8]      = slice_rvalid[8][1];
  assign io_rdata_1_data[64 +: 8] = slice_rdata [8][1];
  assign io_rdata_0_mask[9]      = slice_rvalid[9][0];
  assign io_rdata_0_data[72 +: 8] = slice_rdata [9][0];
  assign io_rdata_1_mask[9]      = slice_rvalid[9][1];
  assign io_rdata_1_data[72 +: 8] = slice_rdata [9][1];
  assign io_rdata_0_mask[10]      = slice_rvalid[10][0];
  assign io_rdata_0_data[80 +: 8] = slice_rdata [10][0];
  assign io_rdata_1_mask[10]      = slice_rvalid[10][1];
  assign io_rdata_1_data[80 +: 8] = slice_rdata [10][1];
  assign io_rdata_0_mask[11]      = slice_rvalid[11][0];
  assign io_rdata_0_data[88 +: 8] = slice_rdata [11][0];
  assign io_rdata_1_mask[11]      = slice_rvalid[11][1];
  assign io_rdata_1_data[88 +: 8] = slice_rdata [11][1];
  assign io_rdata_0_mask[12]      = slice_rvalid[12][0];
  assign io_rdata_0_data[96 +: 8] = slice_rdata [12][0];
  assign io_rdata_1_mask[12]      = slice_rvalid[12][1];
  assign io_rdata_1_data[96 +: 8] = slice_rdata [12][1];
  assign io_rdata_0_mask[13]      = slice_rvalid[13][0];
  assign io_rdata_0_data[104 +: 8] = slice_rdata [13][0];
  assign io_rdata_1_mask[13]      = slice_rvalid[13][1];
  assign io_rdata_1_data[104 +: 8] = slice_rdata [13][1];
  assign io_rdata_0_mask[14]      = slice_rvalid[14][0];
  assign io_rdata_0_data[112 +: 8] = slice_rdata [14][0];
  assign io_rdata_1_mask[14]      = slice_rvalid[14][1];
  assign io_rdata_1_data[112 +: 8] = slice_rdata [14][1];
  assign io_rdata_0_mask[15]      = slice_rvalid[15][0];
  assign io_rdata_0_data[120 +: 8] = slice_rdata [15][0];
  assign io_rdata_1_mask[15]      = slice_rvalid[15][1];
  assign io_rdata_1_data[120 +: 8] = slice_rdata [15][1];

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
        else $fatal(1, "SQDataModule_xs: data write ports collide on entry %0d", io_data_waddr_0);
      assert (!(io_mask_wen_0 && io_mask_wen_1 && io_mask_waddr_0 == io_mask_waddr_1))
        else $fatal(1, "SQDataModule_xs: mask write ports collide on entry %0d", io_mask_waddr_0);
    end
  end
`endif

endmodule
