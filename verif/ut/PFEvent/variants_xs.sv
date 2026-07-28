// PFEvent_xs / perfEventsModule_xs -- UT dual-instantiation variants (renamed only,
// byte-identical to readable core in rtl/backend/pfevent.sv).
module PFEvent_xs(
  input         clock,
  input         reset,
  input         io_distribute_csr_w_valid,
  input  [11:0] io_distribute_csr_w_bits_addr,
  input  [63:0] io_distribute_csr_w_bits_data,
  output [63:0] io_hpmevent_0,
  output [63:0] io_hpmevent_1,
  output [63:0] io_hpmevent_2,
  output [63:0] io_hpmevent_3,
  output [63:0] io_hpmevent_4,
  output [63:0] io_hpmevent_5,
  output [63:0] io_hpmevent_6,
  output [63:0] io_hpmevent_7,
  output [63:0] io_hpmevent_8,
  output [63:0] io_hpmevent_9,
  output [63:0] io_hpmevent_10,
  output [63:0] io_hpmevent_11,
  output [63:0] io_hpmevent_12,
  output [63:0] io_hpmevent_13,
  output [63:0] io_hpmevent_14,
  output [63:0] io_hpmevent_15,
  output [63:0] io_hpmevent_16,
  output [63:0] io_hpmevent_17,
  output [63:0] io_hpmevent_18,
  output [63:0] io_hpmevent_19,
  output [63:0] io_hpmevent_20,
  output [63:0] io_hpmevent_21,
  output [63:0] io_hpmevent_22,
  output [63:0] io_hpmevent_23
);

  perfEventsModule_xs perfEvents_0 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h323),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_0)
  );
  perfEventsModule_xs perfEvents_1 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h324),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_1)
  );
  perfEventsModule_xs perfEvents_2 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h325),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_2)
  );
  perfEventsModule_xs perfEvents_3 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h326),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_3)
  );
  perfEventsModule_xs perfEvents_4 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h327),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_4)
  );
  perfEventsModule_xs perfEvents_5 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h328),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_5)
  );
  perfEventsModule_xs perfEvents_6 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h329),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_6)
  );
  perfEventsModule_xs perfEvents_7 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h32A),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_7)
  );
  perfEventsModule_xs perfEvents_8 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h32B),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_8)
  );
  perfEventsModule_xs perfEvents_9 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h32C),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_9)
  );
  perfEventsModule_xs perfEvents_10 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h32D),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_10)
  );
  perfEventsModule_xs perfEvents_11 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h32E),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_11)
  );
  perfEventsModule_xs perfEvents_12 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h32F),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_12)
  );
  perfEventsModule_xs perfEvents_13 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h330),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_13)
  );
  perfEventsModule_xs perfEvents_14 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h331),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_14)
  );
  perfEventsModule_xs perfEvents_15 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h332),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_15)
  );
  perfEventsModule_xs perfEvents_16 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h333),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_16)
  );
  perfEventsModule_xs perfEvents_17 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h334),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_17)
  );
  perfEventsModule_xs perfEvents_18 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h335),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_18)
  );
  perfEventsModule_xs perfEvents_19 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h336),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_19)
  );
  perfEventsModule_xs perfEvents_20 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h337),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_20)
  );
  perfEventsModule_xs perfEvents_21 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h338),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_21)
  );
  perfEventsModule_xs perfEvents_22 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h339),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_22)
  );
  perfEventsModule_xs perfEvents_23 (
    .clock   (clock),
    .reset   (reset),
    .w_wen   (io_distribute_csr_w_valid & io_distribute_csr_w_bits_addr == 12'h33A),
    .w_wdata (io_distribute_csr_w_bits_data),
    .rdata   (io_hpmevent_23)
  );
endmodule

module perfEventsModule_xs(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata
);

  reg       reg_OF;
  reg       reg_MINH;
  reg       reg_SINH;
  reg       reg_UINH;
  reg       reg_VSINH;
  reg       reg_VUINH;
  reg [4:0] reg_OPTYPE2;
  reg [4:0] reg_OPTYPE1;
  reg [4:0] reg_OPTYPE0;
  reg [9:0] reg_EVENT3;
  reg [9:0] reg_EVENT2;
  reg [9:0] reg_EVENT1;
  reg [9:0] reg_EVENT0;
  // OPTYPE 仅在写值属于合法算子集合 {0,1,2,4} 时更新(否则保持)。
  wire optype2_ok = w_wdata[54:50] == 5'h4 | w_wdata[54:50] == 5'h2
                  | w_wdata[54:50] == 5'h1 | w_wdata[54:50] == 5'h0;
  wire optype1_ok = w_wdata[49:45] == 5'h4 | w_wdata[49:45] == 5'h2
                  | w_wdata[49:45] == 5'h1 | w_wdata[49:45] == 5'h0;
  wire optype0_ok = w_wdata[44:40] == 5'h4 | w_wdata[44:40] == 5'h2
                  | w_wdata[44:40] == 5'h1 | w_wdata[44:40] == 5'h0;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      reg_OF <= 1'h0;
      reg_MINH <= 1'h0;
      reg_SINH <= 1'h0;
      reg_UINH <= 1'h0;
      reg_VSINH <= 1'h0;
      reg_VUINH <= 1'h0;
      reg_OPTYPE2 <= 5'h0;
      reg_OPTYPE1 <= 5'h0;
      reg_OPTYPE0 <= 5'h0;
      reg_EVENT3 <= 10'h0;
      reg_EVENT2 <= 10'h0;
      reg_EVENT1 <= 10'h0;
      reg_EVENT0 <= 10'h0;
    end
    else begin
      if (w_wen) begin
        reg_OF <= w_wdata[63];
        reg_MINH <= w_wdata[62];
        reg_SINH <= w_wdata[61];
        reg_UINH <= w_wdata[60];
        reg_VSINH <= w_wdata[59];
        reg_VUINH <= w_wdata[58];
        reg_EVENT3 <= w_wdata[39:30];
        reg_EVENT2 <= w_wdata[29:20];
        reg_EVENT1 <= w_wdata[19:10];
        reg_EVENT0 <= w_wdata[9:0];
      end
      if (w_wen & optype2_ok) reg_OPTYPE2 <= w_wdata[54:50];
      if (w_wen & optype1_ok) reg_OPTYPE1 <= w_wdata[49:45];
      if (w_wen & optype0_ok) reg_OPTYPE0 <= w_wdata[44:40];
    end
  end
  assign rdata =
    {reg_OF,
     reg_MINH,
     reg_SINH,
     reg_UINH,
     reg_VSINH,
     reg_VUINH,
     3'h0,
     reg_OPTYPE2,
     reg_OPTYPE1,
     reg_OPTYPE0,
     reg_EVENT3,
     reg_EVENT2,
     reg_EVENT1,
     reg_EVENT0};
endmodule
