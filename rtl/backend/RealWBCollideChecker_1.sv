// ============================================================================
// RealWBCollideChecker_1.sv —— RealWBCollideChecker 家族薄 wrapper：fp 域写回口分组仲裁
//
// 本文件只做参数设定（分组表、payload 形状）与端口对位；核体见
// rtl/backend/RealWBCollideChecker.sv（xs_RealWBCollideChecker_core），全家族共一份。
// 由 scripts/gen_realwbcc.py 从 golden 端口表与实例连线生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/RealWBCollideChecker_1.sv
// ============================================================================
module RealWBCollideChecker_1 (
  input         io_in_10_valid,
  input         io_in_10_bits_rfWen,
  input         io_in_10_bits_fpWen,
  input  [7:0]  io_in_10_bits_pdest,
  input  [63:0] io_in_10_bits_data,
  output        io_in_9_ready,
  input         io_in_9_valid,
  input         io_in_9_bits_rfWen,
  input         io_in_9_bits_fpWen,
  input  [7:0]  io_in_9_bits_pdest,
  input  [63:0] io_in_9_bits_data,
  output        io_in_8_ready,
  input         io_in_8_valid,
  input         io_in_8_bits_rfWen,
  input         io_in_8_bits_fpWen,
  input  [7:0]  io_in_8_bits_pdest,
  input  [63:0] io_in_8_bits_data,
  output        io_in_7_ready,
  input         io_in_7_valid,
  input         io_in_7_bits_fpWen,
  input  [7:0]  io_in_7_bits_pdest,
  input  [63:0] io_in_7_bits_data,
  output        io_in_6_ready,
  input         io_in_6_valid,
  input         io_in_6_bits_rfWen,
  input         io_in_6_bits_fpWen,
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
  input         io_in_4_bits_fpWen,
  input  [7:0]  io_in_4_bits_pdest,
  input  [63:0] io_in_4_bits_data,
  output        io_in_3_ready,
  input         io_in_3_valid,
  input         io_in_3_bits_rfWen,
  input         io_in_3_bits_fpWen,
  input  [7:0]  io_in_3_bits_pdest,
  input  [63:0] io_in_3_bits_data,
  output        io_in_2_ready,
  input         io_in_2_valid,
  input         io_in_2_bits_fpWen,
  input  [7:0]  io_in_2_bits_pdest,
  input  [63:0] io_in_2_bits_data,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input         io_in_1_bits_rfWen,
  input         io_in_1_bits_fpWen,
  input  [7:0]  io_in_1_bits_pdest,
  input  [63:0] io_in_1_bits_data,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input         io_in_0_bits_rfWen,
  input         io_in_0_bits_fpWen,
  input  [7:0]  io_in_0_bits_pdest,
  input  [63:0] io_in_0_bits_data,
  output        io_out_5_valid,
  output        io_out_5_bits_fpWen,
  output [7:0]  io_out_5_bits_pdest,
  output [63:0] io_out_5_bits_data,
  output        io_out_4_valid,
  output        io_out_4_bits_fpWen,
  output [7:0]  io_out_4_bits_pdest,
  output [63:0] io_out_4_bits_data,
  output        io_out_3_valid,
  output        io_out_3_bits_fpWen,
  output [7:0]  io_out_3_bits_pdest,
  output [63:0] io_out_3_bits_data,
  output        io_out_2_valid,
  output        io_out_2_bits_fpWen,
  output [7:0]  io_out_2_bits_pdest,
  output [63:0] io_out_2_bits_data,
  output        io_out_1_valid,
  output        io_out_1_bits_fpWen,
  output [7:0]  io_out_1_bits_pdest,
  output [63:0] io_out_1_bits_data,
  output        io_out_0_valid,
  output        io_out_0_bits_fpWen,
  output [7:0]  io_out_0_bits_pdest,
  output [63:0] io_out_0_bits_data
);
  // 域 = fp（本域写使能 fpWen），pdest 8 位、data 64 位。
  localparam int NUM_IN  = 11;
  localparam int NUM_OUT = 6;
  localparam int MAX_G   = 2;
  // 分组表（取自 golden 实例连线）：写口 j 的候选输入，按优先级从高到低
  //   out[0] <- in 1, 6
  //   out[1] <- in 3, 7
  //   out[2] <- in 5, 0
  //   out[3] <- in 8, 2
  //   out[4] <- in 9, 4
  //   out[5] <- in 10
  localparam int GROUP_N [NUM_OUT] = '{2, 2, 2, 2, 2, 1};
  localparam int GROUP [NUM_OUT][MAX_G] = '{'{1, 6}, '{3, 7}, '{5, 0}, '{8, 2}, '{9, 4}, '{10, 0}};

  typedef struct packed {
    logic        wen;     // fpWen
    logic [7:0] pdest;
    logic [63:0] data;
  } wb_t;

  logic [NUM_IN-1:0]  in_valid;
  wb_t  [NUM_IN-1:0]  in_bits;
  logic [NUM_IN-1:0]  in_ready;
  logic [NUM_OUT-1:0] out_valid;
  wb_t  [NUM_OUT-1:0] out_bits;

  assign in_valid[0] = io_in_0_valid;
  assign in_bits[0]  = '{io_in_0_bits_fpWen, io_in_0_bits_pdest, io_in_0_bits_data};
  assign in_valid[1] = io_in_1_valid;
  assign in_bits[1]  = '{io_in_1_bits_fpWen, io_in_1_bits_pdest, io_in_1_bits_data};
  assign in_valid[2] = io_in_2_valid;
  assign in_bits[2]  = '{io_in_2_bits_fpWen, io_in_2_bits_pdest, io_in_2_bits_data};
  assign in_valid[3] = io_in_3_valid;
  assign in_bits[3]  = '{io_in_3_bits_fpWen, io_in_3_bits_pdest, io_in_3_bits_data};
  assign in_valid[4] = io_in_4_valid;
  assign in_bits[4]  = '{io_in_4_bits_fpWen, io_in_4_bits_pdest, io_in_4_bits_data};
  assign in_valid[5] = io_in_5_valid;
  assign in_bits[5]  = '{io_in_5_bits_fpWen, io_in_5_bits_pdest, io_in_5_bits_data};
  assign in_valid[6] = io_in_6_valid;
  assign in_bits[6]  = '{io_in_6_bits_fpWen, io_in_6_bits_pdest, io_in_6_bits_data};
  assign in_valid[7] = io_in_7_valid;
  assign in_bits[7]  = '{io_in_7_bits_fpWen, io_in_7_bits_pdest, io_in_7_bits_data};
  assign in_valid[8] = io_in_8_valid;
  assign in_bits[8]  = '{io_in_8_bits_fpWen, io_in_8_bits_pdest, io_in_8_bits_data};
  assign in_valid[9] = io_in_9_valid;
  assign in_bits[9]  = '{io_in_9_bits_fpWen, io_in_9_bits_pdest, io_in_9_bits_data};
  assign in_valid[10] = io_in_10_valid;
  assign in_bits[10]  = '{io_in_10_bits_fpWen, io_in_10_bits_pdest, io_in_10_bits_data};
  // 以下输入是别的域的写使能：golden 里它们进了子仲裁器，出口那一位悬空，
  // 没有读者，故不接：io_in_0_bits_rfWen, io_in_1_bits_rfWen, io_in_3_bits_rfWen, io_in_5_bits_rfWen, io_in_6_bits_rfWen, io_in_8_bits_rfWen, io_in_9_bits_rfWen, io_in_10_bits_rfWen

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
  assign io_in_6_ready = in_ready[6];
  assign io_in_7_ready = in_ready[7];
  assign io_in_8_ready = in_ready[8];
  assign io_in_9_ready = in_ready[9];
  assign io_out_0_valid       = out_valid[0];
  assign io_out_0_bits_fpWen = out_bits[0].wen;
  assign io_out_0_bits_pdest  = out_bits[0].pdest;
  assign io_out_0_bits_data   = out_bits[0].data;
  assign io_out_1_valid       = out_valid[1];
  assign io_out_1_bits_fpWen = out_bits[1].wen;
  assign io_out_1_bits_pdest  = out_bits[1].pdest;
  assign io_out_1_bits_data   = out_bits[1].data;
  assign io_out_2_valid       = out_valid[2];
  assign io_out_2_bits_fpWen = out_bits[2].wen;
  assign io_out_2_bits_pdest  = out_bits[2].pdest;
  assign io_out_2_bits_data   = out_bits[2].data;
  assign io_out_3_valid       = out_valid[3];
  assign io_out_3_bits_fpWen = out_bits[3].wen;
  assign io_out_3_bits_pdest  = out_bits[3].pdest;
  assign io_out_3_bits_data   = out_bits[3].data;
  assign io_out_4_valid       = out_valid[4];
  assign io_out_4_bits_fpWen = out_bits[4].wen;
  assign io_out_4_bits_pdest  = out_bits[4].pdest;
  assign io_out_4_bits_data   = out_bits[4].data;
  assign io_out_5_valid       = out_valid[5];
  assign io_out_5_bits_fpWen = out_bits[5].wen;
  assign io_out_5_bits_pdest  = out_bits[5].pdest;
  assign io_out_5_bits_data   = out_bits[5].data;
endmodule
