// Readable implementation derived from G1-canonical/golden-rtl/MhpmeventModule.sv.
// mhpmevent fields are WARL: only event operation types 0, 1, 2, and 4 are accepted.
module MhpmeventModule(
  input  logic        clock,
  input  logic        reset,
  input  logic        w_wen,
  input  logic [63:0] w_wdata,
  output logic [63:0] rdata,
  output logic        regOut_OF,
  output logic        regOut_MINH,
  output logic        regOut_SINH,
  output logic        regOut_UINH,
  output logic        regOut_VSINH,
  output logic        regOut_VUINH,
  output logic [4:0]  regOut_OPTYPE2,
  output logic [4:0]  regOut_OPTYPE1,
  output logic [4:0]  regOut_OPTYPE0,
  output logic [9:0]  regOut_EVENT3,
  output logic [9:0]  regOut_EVENT2,
  output logic [9:0]  regOut_EVENT1,
  output logic [9:0]  regOut_EVENT0,
  input  logic        ofFromPerfCnt
);
  logic       of_q;
  logic       minh_q;
  logic       sinh_q;
  logic       uinh_q;
  logic       vsinh_q;
  logic       vuinh_q;
  logic [4:0] optype2_q;
  logic [4:0] optype1_q;
  logic [4:0] optype0_q;
  logic [9:0] event3_q;
  logic [9:0] event2_q;
  logic [9:0] event1_q;
  logic [9:0] event0_q;

  function automatic logic legal_optype(input logic [4:0] value);
    legal_optype = (value == 5'h00) || (value == 5'h01) ||
                   (value == 5'h02) || (value == 5'h04);
  endfunction

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      of_q     <= 1'b0;
      minh_q   <= 1'b0;
      sinh_q   <= 1'b0;
      uinh_q   <= 1'b0;
      vsinh_q  <= 1'b0;
      vuinh_q  <= 1'b0;
      optype2_q <= 5'h00;
      optype1_q <= 5'h00;
      optype0_q <= 5'h00;
      event3_q <= 10'h000;
      event2_q <= 10'h000;
      event1_q <= 10'h000;
      event0_q <= 10'h000;
    end else begin
      if (w_wen) begin
        of_q    <= w_wdata[63];
        minh_q  <= w_wdata[62];
        sinh_q  <= w_wdata[61];
        uinh_q  <= w_wdata[60];
        vsinh_q <= w_wdata[59];
        vuinh_q <= w_wdata[58];
        event3_q <= w_wdata[39:30];
        event2_q <= w_wdata[29:20];
        event1_q <= w_wdata[19:10];
        event0_q <= w_wdata[9:0];
      end else if (ofFromPerfCnt) begin
        of_q <= ofFromPerfCnt;
      end
      if (w_wen && legal_optype(w_wdata[54:50]))
        optype2_q <= w_wdata[54:50];
      if (w_wen && legal_optype(w_wdata[49:45]))
        optype1_q <= w_wdata[49:45];
      if (w_wen && legal_optype(w_wdata[44:40]))
        optype0_q <= w_wdata[44:40];
    end
  end

  assign rdata = {of_q, minh_q, sinh_q, uinh_q, vsinh_q, vuinh_q,
                  3'h0, optype2_q, optype1_q, optype0_q,
                  event3_q, event2_q, event1_q, event0_q};
  assign regOut_OF = of_q;
  assign regOut_MINH = minh_q;
  assign regOut_SINH = sinh_q;
  assign regOut_UINH = uinh_q;
  assign regOut_VSINH = vsinh_q;
  assign regOut_VUINH = vuinh_q;
  assign regOut_OPTYPE2 = optype2_q;
  assign regOut_OPTYPE1 = optype1_q;
  assign regOut_OPTYPE0 = optype0_q;
  assign regOut_EVENT3 = event3_q;
  assign regOut_EVENT2 = event2_q;
  assign regOut_EVENT1 = event1_q;
  assign regOut_EVENT0 = event0_q;
endmodule
