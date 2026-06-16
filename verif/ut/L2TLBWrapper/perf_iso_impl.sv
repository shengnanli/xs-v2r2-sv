// 隔离 FM 反证（impl 侧）：本核同款 perf 2 级流水（struct/enum/function/genvar），
// 端口与 perf_iso_ref 完全一致，用真实 primary input 驱动，无黑盒。
module perf_iso(
  input         clock,
  input         reset,
  input  [5:0]  perf_in_0,  input [5:0] perf_in_1,  input [5:0] perf_in_2,
  input  [5:0]  perf_in_3,  input [5:0] perf_in_4,  input [5:0] perf_in_5,
  input  [5:0]  perf_in_6,  input [5:0] perf_in_7,  input [5:0] perf_in_8,
  input  [5:0]  perf_in_9,  input [5:0] perf_in_10, input [5:0] perf_in_11,
  input  [5:0]  perf_in_12, input [5:0] perf_in_13, input [5:0] perf_in_14,
  input  [5:0]  perf_in_15, input [5:0] perf_in_16, input [5:0] perf_in_17,
  input  [5:0]  perf_in_18,
  output [5:0]  io_perf_0_value,  output [5:0] io_perf_1_value,  output [5:0] io_perf_2_value,
  output [5:0]  io_perf_3_value,  output [5:0] io_perf_4_value,  output [5:0] io_perf_5_value,
  output [5:0]  io_perf_6_value,  output [5:0] io_perf_7_value,  output [5:0] io_perf_8_value,
  output [5:0]  io_perf_9_value,  output [5:0] io_perf_10_value, output [5:0] io_perf_11_value,
  output [5:0]  io_perf_12_value, output [5:0] io_perf_13_value, output [5:0] io_perf_14_value,
  output [5:0]  io_perf_15_value, output [5:0] io_perf_16_value, output [5:0] io_perf_17_value,
  output [5:0]  io_perf_18_value
);
  localparam int NUM_PERF_EVENTS = 19;
  localparam int PERF_W          = 6;
  typedef enum int { PERF_STAGE_1 = 0, PERF_STAGE_2 = 1, PERF_NSTAGE = 2 } perf_stage_e;
  typedef struct packed { logic [PERF_NSTAGE-1:0][PERF_W-1:0] stage; } perf_pipe_t;
  function automatic perf_pipe_t perf_advance(perf_pipe_t cur, logic [PERF_W-1:0] raw);
    perf_pipe_t nxt;
    nxt.stage[PERF_STAGE_2] = cur.stage[PERF_STAGE_1];
    nxt.stage[PERF_STAGE_1] = raw;
    return nxt;
  endfunction

  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_raw;
  perf_pipe_t        perf_pipe [NUM_PERF_EVENTS];
  logic [NUM_PERF_EVENTS-1:0][PERF_W-1:0] perf_out;

  assign perf_raw[0]=perf_in_0;   assign perf_raw[1]=perf_in_1;   assign perf_raw[2]=perf_in_2;
  assign perf_raw[3]=perf_in_3;   assign perf_raw[4]=perf_in_4;   assign perf_raw[5]=perf_in_5;
  assign perf_raw[6]=perf_in_6;   assign perf_raw[7]=perf_in_7;   assign perf_raw[8]=perf_in_8;
  assign perf_raw[9]=perf_in_9;   assign perf_raw[10]=perf_in_10; assign perf_raw[11]=perf_in_11;
  assign perf_raw[12]=perf_in_12; assign perf_raw[13]=perf_in_13; assign perf_raw[14]=perf_in_14;
  assign perf_raw[15]=perf_in_15; assign perf_raw[16]=perf_in_16; assign perf_raw[17]=perf_in_17;
  assign perf_raw[18]=perf_in_18;

  genvar gi;
  generate
    for (gi = 0; gi < NUM_PERF_EVENTS; gi++) begin : g_perf
      always_ff @(posedge clock) begin
        if (reset) perf_pipe[gi] <= '0;
        else       perf_pipe[gi] <= perf_advance(perf_pipe[gi], perf_raw[gi]);
      end
      assign perf_out[gi] = perf_pipe[gi].stage[PERF_STAGE_2];
    end
  endgenerate

  assign io_perf_0_value=perf_out[0];   assign io_perf_1_value=perf_out[1];   assign io_perf_2_value=perf_out[2];
  assign io_perf_3_value=perf_out[3];   assign io_perf_4_value=perf_out[4];   assign io_perf_5_value=perf_out[5];
  assign io_perf_6_value=perf_out[6];   assign io_perf_7_value=perf_out[7];   assign io_perf_8_value=perf_out[8];
  assign io_perf_9_value=perf_out[9];   assign io_perf_10_value=perf_out[10]; assign io_perf_11_value=perf_out[11];
  assign io_perf_12_value=perf_out[12]; assign io_perf_13_value=perf_out[13]; assign io_perf_14_value=perf_out[14];
  assign io_perf_15_value=perf_out[15]; assign io_perf_16_value=perf_out[16]; assign io_perf_17_value=perf_out[17];
  assign io_perf_18_value=perf_out[18];
endmodule
