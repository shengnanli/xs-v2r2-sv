// xs_Trigger_core.sv — canonical Sdtrig mcontrol6 and match-value register cores.
// Four trigger slots share these exact state machines; wrappers retain golden names.
module xs_trigger_tdata1_core (
  input  logic clock,
  input  logic reset,
  input  logic w_wen,
  input  logic [63:0] w_wdata,
  output logic [63:0] rdata,
  input  logic can_write_dmode,
  input  logic chainable,
  input  logic dmode_next_trigger
);
  logic [3:0] type_q;
  logic dmode_q;
  logic [58:0] data_q;
  logic is_mcontrol6;
  logic dmode_value;
  logic match_legal;

  assign is_mcontrol6 = w_wdata[63:60] == 4'h6;
  assign dmode_value = w_wdata[59] & can_write_dmode;
  assign match_legal = (w_wdata[10:7] == 4'h3) ||
                       (w_wdata[10:7] == 4'h2) ||
                       (w_wdata[10:7] == 4'h0);

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      type_q  <= 4'hf;
      dmode_q <= 1'b0;
      data_q  <= 59'h0;
    end else if (w_wen) begin
      type_q  <= is_mcontrol6 ? w_wdata[63:60] : 4'hf;
      dmode_q <= dmode_value;
      data_q  <= is_mcontrol6
        ? {34'h0, w_wdata[24:23], 7'h0,
           ((w_wdata[15:12] == 4'h0) ||
            ((w_wdata[15:12] == 4'h1) && dmode_value))
             ? w_wdata[15:12] : 4'h0,
           w_wdata[11] & chainable & ~(~dmode_value & dmode_next_trigger),
           match_legal ? w_wdata[10:7] : 4'h0,
           w_wdata[6], 1'b0, w_wdata[4:0]}
        : 59'h0;
    end
  end

  assign rdata = {type_q, dmode_q, data_q};
endmodule

module xs_trigger_tdata2_core (
  input logic clock,
  input logic w_wen,
  input logic [63:0] w_wdata,
  output logic [63:0] rdata
);
  logic [63:0] value_q;
  always_ff @(posedge clock) begin
    if (w_wen) value_q <= w_wdata;
  end
  assign rdata = value_q;
endmodule
