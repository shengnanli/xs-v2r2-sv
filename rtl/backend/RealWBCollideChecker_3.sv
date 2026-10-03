// ============================================================================
// RealWBCollideChecker_3.sv —— RealWBCollideChecker 家族薄 wrapper：v0 域写回口分组仲裁
//
// 本文件只做参数设定（分组表、payload 形状）与端口对位；核体见
// rtl/backend/RealWBCollideChecker.sv（xs_RealWBCollideChecker_core），全家族共一份。
// 由 scripts/gen_realwbcc.py 从 golden 端口表与实例连线生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/RealWBCollideChecker_3.sv
// ============================================================================
module RealWBCollideChecker_3 (
  input          io_in_8_valid,
  input          io_in_8_bits_v0Wen,
  input  [4:0]   io_in_8_bits_pdest,
  input  [127:0] io_in_8_bits_data,
  input          io_in_7_valid,
  input          io_in_7_bits_v0Wen,
  input  [4:0]   io_in_7_bits_pdest,
  input  [127:0] io_in_7_bits_data,
  output         io_in_6_ready,
  input          io_in_6_valid,
  input          io_in_6_bits_v0Wen,
  input  [4:0]   io_in_6_bits_pdest,
  input  [127:0] io_in_6_bits_data,
  output         io_in_5_ready,
  input          io_in_5_valid,
  input          io_in_5_bits_v0Wen,
  input  [4:0]   io_in_5_bits_pdest,
  input  [127:0] io_in_5_bits_data,
  input          io_in_4_valid,
  input          io_in_4_bits_v0Wen,
  input  [4:0]   io_in_4_bits_pdest,
  input  [127:0] io_in_4_bits_data,
  output         io_in_3_ready,
  input          io_in_3_valid,
  input          io_in_3_bits_v0Wen,
  input  [4:0]   io_in_3_bits_pdest,
  input  [127:0] io_in_3_bits_data,
  output         io_in_2_ready,
  input          io_in_2_valid,
  input          io_in_2_bits_v0Wen,
  input  [4:0]   io_in_2_bits_pdest,
  input  [127:0] io_in_2_bits_data,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input          io_in_1_bits_v0Wen,
  input  [4:0]   io_in_1_bits_pdest,
  input  [127:0] io_in_1_bits_data,
  output         io_in_0_ready,
  input          io_in_0_valid,
  input          io_in_0_bits_v0Wen,
  input  [4:0]   io_in_0_bits_pdest,
  input  [127:0] io_in_0_bits_data,
  output         io_out_5_valid,
  output         io_out_5_bits_v0Wen,
  output [4:0]   io_out_5_bits_pdest,
  output [127:0] io_out_5_bits_data,
  output         io_out_4_valid,
  output         io_out_4_bits_v0Wen,
  output [4:0]   io_out_4_bits_pdest,
  output [127:0] io_out_4_bits_data,
  output         io_out_3_valid,
  output         io_out_3_bits_v0Wen,
  output [4:0]   io_out_3_bits_pdest,
  output [127:0] io_out_3_bits_data,
  output         io_out_2_valid,
  output         io_out_2_bits_v0Wen,
  output [4:0]   io_out_2_bits_pdest,
  output [127:0] io_out_2_bits_data,
  output         io_out_1_valid,
  output         io_out_1_bits_v0Wen,
  output [4:0]   io_out_1_bits_pdest,
  output [127:0] io_out_1_bits_data,
  output         io_out_0_valid,
  output         io_out_0_bits_v0Wen,
  output [4:0]   io_out_0_bits_pdest,
  output [127:0] io_out_0_bits_data
);
  // 域 = v0（本域写使能 v0Wen），pdest 5 位、data 128 位。
  localparam int NUM_IN  = 9;
  localparam int NUM_OUT = 6;
  localparam int MAX_G   = 2;
  // 分组表（取自 golden 实例连线）：写口 j 的候选输入，按优先级从高到低
  //   out[0] <- in 2, 3
  //   out[1] <- in 4
  //   out[2] <- in 0, 5
  //   out[3] <- in 1, 6
  //   out[4] <- in 7
  //   out[5] <- in 8
  localparam int GROUP_N [NUM_OUT] = '{2, 1, 2, 2, 1, 1};
  localparam int GROUP [NUM_OUT][MAX_G] = '{'{2, 3}, '{4, 0}, '{0, 5}, '{1, 6}, '{7, 0}, '{8, 0}};

  typedef struct packed {
    logic        wen;     // v0Wen
    logic [4:0] pdest;
    logic [127:0] data;
  } wb_t;

  logic [NUM_IN-1:0]  in_valid;
  wb_t  [NUM_IN-1:0]  in_bits;
  logic [NUM_IN-1:0]  in_ready;
  logic [NUM_OUT-1:0] out_valid;
  wb_t  [NUM_OUT-1:0] out_bits;

  assign in_valid[0] = io_in_0_valid;
  assign in_bits[0]  = '{io_in_0_bits_v0Wen, io_in_0_bits_pdest, io_in_0_bits_data};
  assign in_valid[1] = io_in_1_valid;
  assign in_bits[1]  = '{io_in_1_bits_v0Wen, io_in_1_bits_pdest, io_in_1_bits_data};
  assign in_valid[2] = io_in_2_valid;
  assign in_bits[2]  = '{io_in_2_bits_v0Wen, io_in_2_bits_pdest, io_in_2_bits_data};
  assign in_valid[3] = io_in_3_valid;
  assign in_bits[3]  = '{io_in_3_bits_v0Wen, io_in_3_bits_pdest, io_in_3_bits_data};
  assign in_valid[4] = io_in_4_valid;
  assign in_bits[4]  = '{io_in_4_bits_v0Wen, io_in_4_bits_pdest, io_in_4_bits_data};
  assign in_valid[5] = io_in_5_valid;
  assign in_bits[5]  = '{io_in_5_bits_v0Wen, io_in_5_bits_pdest, io_in_5_bits_data};
  assign in_valid[6] = io_in_6_valid;
  assign in_bits[6]  = '{io_in_6_bits_v0Wen, io_in_6_bits_pdest, io_in_6_bits_data};
  assign in_valid[7] = io_in_7_valid;
  assign in_bits[7]  = '{io_in_7_bits_v0Wen, io_in_7_bits_pdest, io_in_7_bits_data};
  assign in_valid[8] = io_in_8_valid;
  assign in_bits[8]  = '{io_in_8_bits_v0Wen, io_in_8_bits_pdest, io_in_8_bits_data};

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
  assign io_in_5_ready = in_ready[5];
  assign io_in_6_ready = in_ready[6];
  assign io_out_0_valid       = out_valid[0];
  assign io_out_0_bits_v0Wen = out_bits[0].wen;
  assign io_out_0_bits_pdest  = out_bits[0].pdest;
  assign io_out_0_bits_data   = out_bits[0].data;
  assign io_out_1_valid       = out_valid[1];
  assign io_out_1_bits_v0Wen = out_bits[1].wen;
  assign io_out_1_bits_pdest  = out_bits[1].pdest;
  assign io_out_1_bits_data   = out_bits[1].data;
  assign io_out_2_valid       = out_valid[2];
  assign io_out_2_bits_v0Wen = out_bits[2].wen;
  assign io_out_2_bits_pdest  = out_bits[2].pdest;
  assign io_out_2_bits_data   = out_bits[2].data;
  assign io_out_3_valid       = out_valid[3];
  assign io_out_3_bits_v0Wen = out_bits[3].wen;
  assign io_out_3_bits_pdest  = out_bits[3].pdest;
  assign io_out_3_bits_data   = out_bits[3].data;
  assign io_out_4_valid       = out_valid[4];
  assign io_out_4_bits_v0Wen = out_bits[4].wen;
  assign io_out_4_bits_pdest  = out_bits[4].pdest;
  assign io_out_4_bits_data   = out_bits[4].data;
  assign io_out_5_valid       = out_valid[5];
  assign io_out_5_bits_v0Wen = out_bits[5].wen;
  assign io_out_5_bits_pdest  = out_bits[5].pdest;
  assign io_out_5_bits_data   = out_bits[5].data;
endmodule
