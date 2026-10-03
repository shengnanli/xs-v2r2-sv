// ============================================================================
// RealWBCollideChecker_4.sv —— RealWBCollideChecker 家族薄 wrapper：vl 域写回口分组仲裁
//
// 本文件只做参数设定（分组表、payload 形状）与端口对位；核体见
// rtl/backend/RealWBCollideChecker.sv（xs_RealWBCollideChecker_core），全家族共一份。
// 由 scripts/gen_realwbcc.py 从 golden 端口表与实例连线生成，勿手改。
// golden 对照：G1-canonical/golden-rtl/RealWBCollideChecker_4.sv
// ============================================================================
module RealWBCollideChecker_4 (
  input        io_in_3_valid,
  input        io_in_3_bits_vlWen,
  input  [4:0] io_in_3_bits_pdest,
  input  [7:0] io_in_3_bits_data,
  input        io_in_2_valid,
  input        io_in_2_bits_vlWen,
  input  [4:0] io_in_2_bits_pdest,
  input  [7:0] io_in_2_bits_data,
  input        io_in_1_valid,
  input        io_in_1_bits_vlWen,
  input  [4:0] io_in_1_bits_pdest,
  input  [7:0] io_in_1_bits_data,
  input        io_in_0_valid,
  input        io_in_0_bits_vlWen,
  input  [4:0] io_in_0_bits_pdest,
  input  [7:0] io_in_0_bits_data,
  output       io_out_3_valid,
  output       io_out_3_bits_vlWen,
  output [4:0] io_out_3_bits_pdest,
  output [7:0] io_out_3_bits_data,
  output       io_out_2_valid,
  output       io_out_2_bits_vlWen,
  output [4:0] io_out_2_bits_pdest,
  output [7:0] io_out_2_bits_data,
  output       io_out_1_valid,
  output       io_out_1_bits_vlWen,
  output [4:0] io_out_1_bits_pdest,
  output [7:0] io_out_1_bits_data,
  output       io_out_0_valid,
  output       io_out_0_bits_vlWen,
  output [4:0] io_out_0_bits_pdest,
  output [7:0] io_out_0_bits_data
);
  // 域 = vl（本域写使能 vlWen），pdest 5 位、data 8 位。
  localparam int NUM_IN  = 4;
  localparam int NUM_OUT = 4;
  localparam int MAX_G   = 1;
  // 分组表（取自 golden 实例连线）：写口 j 的候选输入，按优先级从高到低
  //   out[0] <- in 0
  //   out[1] <- in 1
  //   out[2] <- in 2
  //   out[3] <- in 3
  localparam int GROUP_N [NUM_OUT] = '{1, 1, 1, 1};
  localparam int GROUP [NUM_OUT][MAX_G] = '{'{0}, '{1}, '{2}, '{3}};

  typedef struct packed {
    logic        wen;     // vlWen
    logic [4:0] pdest;
    logic [7:0] data;
  } wb_t;

  logic [NUM_IN-1:0]  in_valid;
  wb_t  [NUM_IN-1:0]  in_bits;
  logic [NUM_IN-1:0]  in_ready;
  logic [NUM_OUT-1:0] out_valid;
  wb_t  [NUM_OUT-1:0] out_bits;

  assign in_valid[0] = io_in_0_valid;
  assign in_bits[0]  = '{io_in_0_bits_vlWen, io_in_0_bits_pdest, io_in_0_bits_data};
  assign in_valid[1] = io_in_1_valid;
  assign in_bits[1]  = '{io_in_1_bits_vlWen, io_in_1_bits_pdest, io_in_1_bits_data};
  assign in_valid[2] = io_in_2_valid;
  assign in_bits[2]  = '{io_in_2_bits_vlWen, io_in_2_bits_pdest, io_in_2_bits_data};
  assign in_valid[3] = io_in_3_valid;
  assign in_bits[3]  = '{io_in_3_bits_vlWen, io_in_3_bits_pdest, io_in_3_bits_data};

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
  assign io_out_0_valid       = out_valid[0];
  assign io_out_0_bits_vlWen = out_bits[0].wen;
  assign io_out_0_bits_pdest  = out_bits[0].pdest;
  assign io_out_0_bits_data   = out_bits[0].data;
  assign io_out_1_valid       = out_valid[1];
  assign io_out_1_bits_vlWen = out_bits[1].wen;
  assign io_out_1_bits_pdest  = out_bits[1].pdest;
  assign io_out_1_bits_data   = out_bits[1].data;
  assign io_out_2_valid       = out_valid[2];
  assign io_out_2_bits_vlWen = out_bits[2].wen;
  assign io_out_2_bits_pdest  = out_bits[2].pdest;
  assign io_out_2_bits_data   = out_bits[2].data;
  assign io_out_3_valid       = out_valid[3];
  assign io_out_3_bits_vlWen = out_bits[3].wen;
  assign io_out_3_bits_pdest  = out_bits[3].pdest;
  assign io_out_3_bits_data   = out_bits[3].data;
endmodule
