// 负测台：证明 xs_PriorityMuxModule_core 的端口数恒等式真会拦下"字段数抄错"。
// 下面是 PriorityMuxModule_8 薄文件的复制品，唯一改动：NUM_FIELDS 抄成 1
// （应为 2 —— GHPtr 有 flag 与 value 两个字段）。端口表、载荷拼接一字未改，
// 逻辑也完全正确，随机激励永远发现不了这个参数错。
// 期望：GOLDEN_PORTS(16) != NUM_WAYS(4) + (4+2)*NUM_FIELDS(1) = 10，time 0 $fatal。
module neg_pmux_wrong_fieldcount(
  input        s2_GHPtr_sel,
  input        s2_GHPtr_src_flag,
  input  [7:0] s2_GHPtr_src_value,
  input        s1_GHPtr_sel,
  input        s1_GHPtr_src_flag,
  input  [7:0] s1_GHPtr_src_value,
  input        s3_GHPtr_sel,
  input        s3_GHPtr_src_flag,
  input  [7:0] s3_GHPtr_src_value,
  input        redirect_GHPtr_sel,
  input        redirect_GHPtr_src_flag,
  input  [7:0] redirect_GHPtr_src_value,
  input        stallGHPtr_src_flag,
  input  [7:0] stallGHPtr_src_value,
  output       out_res_flag,
  output [7:0] out_res_value
);
  localparam int unsigned NUM_WAYS     = 4;
  localparam int unsigned NUM_FIELDS   = 1;    // <-- 抄错：GHPtr 有 2 个字段
  localparam int unsigned GOLDEN_PORTS = 16;
  localparam int unsigned PAYLOAD_W    = 9;

  logic [PAYLOAD_W-1:0] res;

  xs_PriorityMuxModule_core #(
    .WIDTH         (PAYLOAD_W),
    .NUM_WAYS      (NUM_WAYS),
    .NUM_FIELDS    (NUM_FIELDS),
    .GOLDEN_PORTS  (GOLDEN_PORTS),
    .PORT_BITS_SRC ($bits({s2_GHPtr_src_flag, s2_GHPtr_src_value,
                           s1_GHPtr_src_flag, s1_GHPtr_src_value,
                           s3_GHPtr_src_flag, s3_GHPtr_src_value,
                           redirect_GHPtr_src_flag, redirect_GHPtr_src_value})),
    .PORT_BITS_DFLT($bits({stallGHPtr_src_flag, stallGHPtr_src_value})),
    .PORT_BITS_OUT ($bits({out_res_flag, out_res_value}))
  ) u_core (
    .sel ({s2_GHPtr_sel, s1_GHPtr_sel, s3_GHPtr_sel, redirect_GHPtr_sel}),
    .src ({s2_GHPtr_src_flag, s2_GHPtr_src_value, s1_GHPtr_src_flag, s1_GHPtr_src_value,
           s3_GHPtr_src_flag, s3_GHPtr_src_value, redirect_GHPtr_src_flag,
           redirect_GHPtr_src_value}),
    .dflt({stallGHPtr_src_flag, stallGHPtr_src_value}),
    .res (res)
  );

  assign {out_res_flag, out_res_value} = res;
endmodule

module neg_tb;
  wire o_flag;
  wire [7:0] o_value;
  neg_pmux_wrong_fieldcount u_dut (
    .s2_GHPtr_sel(1'b0), .s2_GHPtr_src_flag(1'b0), .s2_GHPtr_src_value(8'h0),
    .s1_GHPtr_sel(1'b0), .s1_GHPtr_src_flag(1'b0), .s1_GHPtr_src_value(8'h0),
    .s3_GHPtr_sel(1'b0), .s3_GHPtr_src_flag(1'b0), .s3_GHPtr_src_value(8'h0),
    .redirect_GHPtr_sel(1'b0), .redirect_GHPtr_src_flag(1'b0),
    .redirect_GHPtr_src_value(8'h0),
    .stallGHPtr_src_flag(1'b0), .stallGHPtr_src_value(8'h0),
    .out_res_flag(o_flag), .out_res_value(o_value)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下字段数抄错");
    $finish;
  end
endmodule
