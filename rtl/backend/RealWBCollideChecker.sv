// =============================================================================
// RealWBCollideChecker.sv —— 物理寄存器堆写回口的分组仲裁：家族参数化核 + 本变体 wrapper
//
// 在哪一层：后端 WbDataPath 里。所有执行单元（EXU）的结果先按「要写哪个寄存器堆」
//   分流（int / fp / vec / v0 / vl 五个域），每个域一个本族实例。一个域的写口
//   （物理寄存器堆写端口）比想写它的 EXU 少，于是配置里给每个 EXU 指定了
//   「写哪个端口号 + 在该端口上的优先级」—— 同一端口号的 EXU 组成一组，组内
//   固定优先级仲裁，每组的赢家占用那个写口。
//
// 核心机制（与 Scala WbArbiter.scala class RealWBCollideChecker 逐句对应）：
//   1. 分组：第 j 个写口 out[j] 的候选是 GROUP[j][0..GROUP_N[j]-1] 这几路输入，
//      排在前面的优先级高（这张表来自 BackendParams 的 wbCfgs，golden 已固化成
//      实例连线；本仓由 scripts/gen_realwbcc.py 从 golden 连线里逐条读出）。
//   2. 组内：编号小者先赢的固定优先级（共享件 rtl/common/xs_PriorityArbSelect.sv，
//      与 RealWBArbiter 族同一条法则）。写口本身恒就绪（Scala: arbOut.ready := true.B），
//      所以 out_valid = 组内任一路请求。
//   3. 回压：in_ready[i] = 「i 所在组里排在它前面的都没请求」|「i 自己没请求」。
//      组内第 0 名因此恒为 1；只有一路的组连 ready 端口都没有（golden 折掉了）。
//
// 纯组合，无时钟、无寄存器（golden 本族连 clock/reset 端口都没有）。
//
// payload：一个域只关心三样 —— 本域写使能 wen（rfWen/fpWen/vecWen/v0Wen/vlWen 之一）、
//   目的物理寄存器号 pdest、写回数据 data。golden 的 int / fp 两域里个别输入还多带
//   另一个域的 wen（例如 int 域的 fpWen），它们在 golden 里接进子仲裁器后，出口那一位
//   悬空（/* unused */）—— 没有任何读者，本核不搬运它们，wrapper 把这些输入端口留空。
//
// 家族差异（5 个变体只差 4 个维度，由 wrapper 传参）：
//   变体                       域   输入 写口 组宽上限 pdest data
//   RealWBCollideChecker       int   15   8    4       8    64
//   RealWBCollideChecker_1     fp    11   6    2       8    64
//   RealWBCollideChecker_2     vec    9   6    2       7   128
//   RealWBCollideChecker_3     v0     9   6    2       5   128
//   RealWBCollideChecker_4     vl     4   4    1       5     8
//
// 设计源：XiangShan src/main/scala/xiangshan/backend/datapath/WbArbiter.scala
// golden 对照：G1-canonical/golden-rtl/RealWBCollideChecker.sv（本文件的 wrapper 段）
// =============================================================================

// -----------------------------------------------------------------------------
// xs_RealWBCollideChecker_core —— 按分组表把 NUM_IN 路写回请求仲裁到 NUM_OUT 个写口
//
// GROUP[j][k]：第 j 个写口上优先级第 k 的那一路输入的编号（k < GROUP_N[j] 有效，
//   其余位置无意义）。每一路输入恰好出现在一个组里（生成器对 golden 实测断言）。
// -----------------------------------------------------------------------------
module xs_RealWBCollideChecker_core #(
  parameter int NUM_IN  = 1,
  parameter int NUM_OUT = 1,
  parameter int MAX_G   = 1,                              // 最大组宽
  parameter int PW      = 1,                              // payload 打平位宽
  parameter int GROUP_N [NUM_OUT]        = '{default: 1}, // 每组几路
  parameter int GROUP   [NUM_OUT][MAX_G] = '{default: 0}  // 每组成员（按优先级）
) (
  input  logic [NUM_IN-1:0]           in_valid,
  input  logic [NUM_IN-1:0][PW-1:0]   in_bits,
  output logic [NUM_IN-1:0]           in_ready,
  output logic [NUM_OUT-1:0]          out_valid,
  output logic [NUM_OUT-1:0][PW-1:0]  out_bits
);
  // 每组每个名次拿到的授权；名次超出组宽的位置不用，恒 1
  wire [NUM_OUT-1:0][MAX_G-1:0] grp_ready;

  // ---- 1+2. 每个写口：取出本组成员，组内固定优先级仲裁 -------------------------
  for (genvar j = 0; j < NUM_OUT; j++) begin : g_port
    localparam int N = GROUP_N[j];

    logic [N-1:0]         mem_valid;   // 本组成员按优先级排好的请求
    logic [N-1:0][PW-1:0] mem_bits;
    logic [N-1:0]         mem_ready;

    for (genvar k = 0; k < N; k++) begin : g_member
      assign mem_valid[k] = in_valid[GROUP[j][k]];
      assign mem_bits[k]  = in_bits[GROUP[j][k]];
    end

    xs_PriorityArbSelect #(.N(N), .PW(PW)) u_arb (
      .in_valid  (mem_valid),
      .eff_valid (mem_valid),     // 本族没有反饥饿级，原始请求直接参与竞争
      .in_bits   (mem_bits),
      .in_ready  (mem_ready),
      .out_valid (out_valid[j]),
      .out_bits  (out_bits[j])
    );

    for (genvar k = 0; k < MAX_G; k++) begin : g_rank
      if (k < N) begin : g_used
        assign grp_ready[j][k] = mem_ready[k];
      end else begin : g_pad
        assign grp_ready[j][k] = 1'b1;
      end
    end
  end

  // ---- 3. 回压：把「组 j 第 k 名」的授权送回它对应的那一路输入 -------------------
  always_comb begin
    in_ready = '1;
    for (int j = 0; j < NUM_OUT; j++)
      for (int k = 0; k < MAX_G; k++)
        if (k < GROUP_N[j]) in_ready[GROUP[j][k]] = grp_ready[j][k];
  end
endmodule

// BEGIN GENERATED(realwbcc-wrapper)
module RealWBCollideChecker (
  input         io_in_14_valid,
  input         io_in_14_bits_rfWen,
  input         io_in_14_bits_fpWen,
  input  [7:0]  io_in_14_bits_pdest,
  input  [63:0] io_in_14_bits_data,
  input         io_in_13_valid,
  input         io_in_13_bits_rfWen,
  input         io_in_13_bits_fpWen,
  input  [7:0]  io_in_13_bits_pdest,
  input  [63:0] io_in_13_bits_data,
  input         io_in_12_valid,
  input         io_in_12_bits_rfWen,
  input         io_in_12_bits_fpWen,
  input  [7:0]  io_in_12_bits_pdest,
  input  [63:0] io_in_12_bits_data,
  output        io_in_11_ready,
  input         io_in_11_valid,
  input         io_in_11_bits_rfWen,
  input  [7:0]  io_in_11_bits_pdest,
  input  [63:0] io_in_11_bits_data,
  output        io_in_10_ready,
  input         io_in_10_valid,
  input         io_in_10_bits_rfWen,
  input         io_in_10_bits_fpWen,
  input  [7:0]  io_in_10_bits_pdest,
  input  [63:0] io_in_10_bits_data,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input         io_in_9_bits_rfWen,
  input  [7:0]  io_in_9_bits_pdest,
  input  [63:0] io_in_9_bits_data,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input         io_in_8_bits_rfWen,
  input  [7:0]  io_in_8_bits_pdest,
  input  [63:0] io_in_8_bits_data,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input         io_in_7_bits_rfWen,
  input  [7:0]  io_in_7_bits_pdest,
  input  [63:0] io_in_7_bits_data,
  input         io_in_6_valid,
  input         io_in_6_bits_rfWen,
  input  [7:0]  io_in_6_bits_pdest,
  input  [63:0] io_in_6_bits_data,
  output        io_in_5_ready,
  input         io_in_5_valid,
  input         io_in_5_bits_rfWen,
  input         io_in_5_bits_fpWen,
  input  [7:0]  io_in_5_bits_pdest,
  input  [63:0] io_in_5_bits_data,
  output        io_in_4_ready,
  input         io_in_4_valid,
  input         io_in_4_bits_rfWen,
  input  [7:0]  io_in_4_bits_pdest,
  input  [63:0] io_in_4_bits_data,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input         io_in_3_bits_rfWen,
  input  [7:0]  io_in_3_bits_pdest,
  input  [63:0] io_in_3_bits_data,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input         io_in_2_bits_rfWen,
  input  [7:0]  io_in_2_bits_pdest,
  input  [63:0] io_in_2_bits_data,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input         io_in_1_bits_rfWen,
  input  [7:0]  io_in_1_bits_pdest,
  input  [63:0] io_in_1_bits_data,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input         io_in_0_bits_rfWen,
  input  [7:0]  io_in_0_bits_pdest,
  input  [63:0] io_in_0_bits_data,
  output        io_out_7_valid,
  output        io_out_7_bits_rfWen,
  output [7:0]  io_out_7_bits_pdest,
  output [63:0] io_out_7_bits_data,
  output        io_out_6_valid,
  output        io_out_6_bits_rfWen,
  output [7:0]  io_out_6_bits_pdest,
  output [63:0] io_out_6_bits_data,
  output        io_out_5_valid,
  output        io_out_5_bits_rfWen,
  output [7:0]  io_out_5_bits_pdest,
  output [63:0] io_out_5_bits_data,
  output        io_out_4_valid,
  output        io_out_4_bits_rfWen,
  output [7:0]  io_out_4_bits_pdest,
  output [63:0] io_out_4_bits_data,
  output        io_out_3_valid,
  output        io_out_3_bits_rfWen,
  output [7:0]  io_out_3_bits_pdest,
  output [63:0] io_out_3_bits_data,
  output        io_out_2_valid,
  output        io_out_2_bits_rfWen,
  output [7:0]  io_out_2_bits_pdest,
  output [63:0] io_out_2_bits_data,
  output        io_out_1_valid,
  output        io_out_1_bits_rfWen,
  output [7:0]  io_out_1_bits_pdest,
  output [63:0] io_out_1_bits_data,
  output        io_out_0_valid,
  output        io_out_0_bits_rfWen,
  output [7:0]  io_out_0_bits_pdest,
  output [63:0] io_out_0_bits_data
);
  // 域 = int（本域写使能 rfWen），pdest 8 位、data 64 位。
  localparam int NUM_IN  = 15;
  localparam int NUM_OUT = 8;
  localparam int MAX_G   = 4;
  // 分组表（取自 golden 实例连线）：写口 j 的候选输入，按优先级从高到低
  //   out[0] <- in 0, 1, 8
  //   out[1] <- in 2, 3, 11, 9
  //   out[2] <- in 4, 10
  //   out[3] <- in 6
  //   out[4] <- in 5, 7
  //   out[5] <- in 12
  //   out[6] <- in 13
  //   out[7] <- in 14
  localparam int GROUP_N [NUM_OUT] = '{3, 4, 2, 1, 2, 1, 1, 1};
  localparam int GROUP [NUM_OUT][MAX_G] = '{'{0, 1, 8, 0}, '{2, 3, 11, 9}, '{4, 10, 0, 0}, '{6, 0, 0, 0}, '{5, 7, 0, 0}, '{12, 0, 0, 0}, '{13, 0, 0, 0}, '{14, 0, 0, 0}};

  typedef struct packed {
    logic        wen;     // rfWen
    logic [7:0] pdest;
    logic [63:0] data;
  } wb_t;

  logic [NUM_IN-1:0]  in_valid;
  wb_t  [NUM_IN-1:0]  in_bits;
  logic [NUM_IN-1:0]  in_ready;
  logic [NUM_OUT-1:0] out_valid;
  wb_t  [NUM_OUT-1:0] out_bits;

  assign in_valid[0] = io_in_0_valid;
  assign in_bits[0]  = '{io_in_0_bits_rfWen, io_in_0_bits_pdest, io_in_0_bits_data};
  assign in_valid[1] = io_in_1_valid;
  assign in_bits[1]  = '{io_in_1_bits_rfWen, io_in_1_bits_pdest, io_in_1_bits_data};
  assign in_valid[2] = io_in_2_valid;
  assign in_bits[2]  = '{io_in_2_bits_rfWen, io_in_2_bits_pdest, io_in_2_bits_data};
  assign in_valid[3] = io_in_3_valid;
  assign in_bits[3]  = '{io_in_3_bits_rfWen, io_in_3_bits_pdest, io_in_3_bits_data};
  assign in_valid[4] = io_in_4_valid;
  assign in_bits[4]  = '{io_in_4_bits_rfWen, io_in_4_bits_pdest, io_in_4_bits_data};
  assign in_valid[5] = io_in_5_valid;
  assign in_bits[5]  = '{io_in_5_bits_rfWen, io_in_5_bits_pdest, io_in_5_bits_data};
  assign in_valid[6] = io_in_6_valid;
  assign in_bits[6]  = '{io_in_6_bits_rfWen, io_in_6_bits_pdest, io_in_6_bits_data};
  assign in_valid[7] = io_in_7_valid;
  assign in_bits[7]  = '{io_in_7_bits_rfWen, io_in_7_bits_pdest, io_in_7_bits_data};
  assign in_valid[8] = io_in_8_valid;
  assign in_bits[8]  = '{io_in_8_bits_rfWen, io_in_8_bits_pdest, io_in_8_bits_data};
  assign in_valid[9] = io_in_9_valid;
  assign in_bits[9]  = '{io_in_9_bits_rfWen, io_in_9_bits_pdest, io_in_9_bits_data};
  assign in_valid[10] = io_in_10_valid;
  assign in_bits[10]  = '{io_in_10_bits_rfWen, io_in_10_bits_pdest, io_in_10_bits_data};
  assign in_valid[11] = io_in_11_valid;
  assign in_bits[11]  = '{io_in_11_bits_rfWen, io_in_11_bits_pdest, io_in_11_bits_data};
  assign in_valid[12] = io_in_12_valid;
  assign in_bits[12]  = '{io_in_12_bits_rfWen, io_in_12_bits_pdest, io_in_12_bits_data};
  assign in_valid[13] = io_in_13_valid;
  assign in_bits[13]  = '{io_in_13_bits_rfWen, io_in_13_bits_pdest, io_in_13_bits_data};
  assign in_valid[14] = io_in_14_valid;
  assign in_bits[14]  = '{io_in_14_bits_rfWen, io_in_14_bits_pdest, io_in_14_bits_data};
  // 以下输入是别的域的写使能：golden 里它们进了子仲裁器，出口那一位悬空，
  // 没有读者，故不接：io_in_5_bits_fpWen, io_in_10_bits_fpWen, io_in_12_bits_fpWen, io_in_13_bits_fpWen, io_in_14_bits_fpWen

  xs_RealWBCollideChecker_core #(
    .NUM_IN  (NUM_IN),
    .NUM_OUT (NUM_OUT),
    .MAX_G   (MAX_G),
    .PW      ($bits(wb_t)),
    .GROUP_N (GROUP_N),
    .GROUP   (GROUP)
  ) u_core (
    .in_valid  (in_valid),
    .in_bits   (in_bits),
    .in_ready  (in_ready),
    .out_valid (out_valid),
    .out_bits  (out_bits)
  );

  // 只有组宽 >= 2 的输入在 golden 里有 ready 端口（组内第 0 名恒 1 也照样导出）
  assign io_in_0_ready = in_ready[0];
  assign io_in_1_ready = in_ready[1];
  assign io_in_2_ready = in_ready[2];
  assign io_in_3_ready = in_ready[3];
  assign io_in_4_ready = in_ready[4];
  assign io_in_5_ready = in_ready[5];
  assign io_in_7_ready = in_ready[7];
  assign io_in_8_ready = in_ready[8];
  assign io_in_9_ready = in_ready[9];
  assign io_in_10_ready = in_ready[10];
  assign io_in_11_ready = in_ready[11];
  assign io_out_0_valid       = out_valid[0];
  assign io_out_0_bits_rfWen = out_bits[0].wen;
  assign io_out_0_bits_pdest  = out_bits[0].pdest;
  assign io_out_0_bits_data   = out_bits[0].data;
  assign io_out_1_valid       = out_valid[1];
  assign io_out_1_bits_rfWen = out_bits[1].wen;
  assign io_out_1_bits_pdest  = out_bits[1].pdest;
  assign io_out_1_bits_data   = out_bits[1].data;
  assign io_out_2_valid       = out_valid[2];
  assign io_out_2_bits_rfWen = out_bits[2].wen;
  assign io_out_2_bits_pdest  = out_bits[2].pdest;
  assign io_out_2_bits_data   = out_bits[2].data;
  assign io_out_3_valid       = out_valid[3];
  assign io_out_3_bits_rfWen = out_bits[3].wen;
  assign io_out_3_bits_pdest  = out_bits[3].pdest;
  assign io_out_3_bits_data   = out_bits[3].data;
  assign io_out_4_valid       = out_valid[4];
  assign io_out_4_bits_rfWen = out_bits[4].wen;
  assign io_out_4_bits_pdest  = out_bits[4].pdest;
  assign io_out_4_bits_data   = out_bits[4].data;
  assign io_out_5_valid       = out_valid[5];
  assign io_out_5_bits_rfWen = out_bits[5].wen;
  assign io_out_5_bits_pdest  = out_bits[5].pdest;
  assign io_out_5_bits_data   = out_bits[5].data;
  assign io_out_6_valid       = out_valid[6];
  assign io_out_6_bits_rfWen = out_bits[6].wen;
  assign io_out_6_bits_pdest  = out_bits[6].pdest;
  assign io_out_6_bits_data   = out_bits[6].data;
  assign io_out_7_valid       = out_valid[7];
  assign io_out_7_bits_rfWen = out_bits[7].wen;
  assign io_out_7_bits_pdest  = out_bits[7].pdest;
  assign io_out_7_bits_data   = out_bits[7].data;
endmodule
// END GENERATED
