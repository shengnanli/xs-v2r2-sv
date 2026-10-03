// BusErrorUnit.sv — ECC error capture, interrupt status, and MMIO view.
// A request is accepted only when the D channel is ready.  Error capture has
// deterministic priority (L2, uncache, D-cache, I-cache), while accrued bits
// remember every raw valid pulse independent of the per-source enable bit.

module xs_BusErrorUnit_core (
  input  logic        clock,
  input  logic        reset,
  output logic        auto_in_a_ready,
  input  logic        auto_in_a_valid,
  input  logic [3:0]  auto_in_a_bits_opcode,
  input  logic [1:0]  auto_in_a_bits_size,
  input  logic [4:0]  auto_in_a_bits_source,
  input  logic [29:0] auto_in_a_bits_address,
  input  logic [7:0]  auto_in_a_bits_mask,
  input  logic [63:0] auto_in_a_bits_data,
  input  logic        auto_in_d_ready,
  output logic        auto_in_d_valid,
  output logic [3:0]  auto_in_d_bits_opcode,
  output logic [1:0]  auto_in_d_bits_size,
  output logic [4:0]  auto_in_d_bits_source,
  output logic [63:0] auto_in_d_bits_data,
  output logic        auto_int_out_0,
  input  logic        io_errors_icache_ecc_error_valid,
  input  logic [47:0] io_errors_icache_ecc_error_bits,
  input  logic        io_errors_dcache_ecc_error_valid,
  input  logic [47:0] io_errors_dcache_ecc_error_bits,
  input  logic        io_errors_uncache_ecc_error_valid,
  input  logic [47:0] io_errors_uncache_ecc_error_bits,
  input  logic        io_errors_l2_ecc_error_valid,
  input  logic [47:0] io_errors_l2_ecc_error_bits,
  output logic        io_interrupt
);
  logic [1:0] cause_q;
  logic [47:0] pad_q;
  logic [3:0] enable_q, global_interrupt_q;
  logic [3:0] accrued_q, local_interrupt_q;

  logic is_read;
  logic write_fire;
  logic [2:0] register_index;
  logic address_page_zero;
  logic write_cause, write_pad, write_enable, write_global;
  logic write_accrued, write_local;
  logic error_icache, error_dcache, error_uncache, error_l2;
  logic enabled_error;
  logic pending_error;
  logic [47:0] selected_error_bits;
  logic [47:0] read_data;

  assign is_read = (auto_in_a_bits_opcode == 4'h4);
  assign write_fire = auto_in_a_valid && auto_in_d_ready && !is_read;
  assign register_index = auto_in_a_bits_address[5:3];
  assign address_page_zero = (auto_in_a_bits_address[11:6] == 6'h0);

  assign write_cause = write_fire && address_page_zero && register_index == 3'd0 && auto_in_a_bits_mask[0];
  assign write_pad = write_fire && address_page_zero && register_index == 3'd1;
  assign write_enable = write_fire && address_page_zero && register_index == 3'd2 && auto_in_a_bits_mask[0];
  assign write_global = write_fire && address_page_zero && register_index == 3'd3 && auto_in_a_bits_mask[0];
  assign write_accrued = write_fire && address_page_zero && register_index == 3'd4 && auto_in_a_bits_mask[0];
  assign write_local = write_fire && address_page_zero && register_index == 3'd5 && auto_in_a_bits_mask[0];

  assign error_icache = io_errors_icache_ecc_error_valid && enable_q[0];
  assign error_dcache = io_errors_dcache_ecc_error_valid && enable_q[1];
  assign error_uncache = io_errors_uncache_ecc_error_valid && enable_q[2];
  assign error_l2 = io_errors_l2_ecc_error_valid && enable_q[3];
  assign enabled_error = error_icache || error_dcache || error_uncache || error_l2;
  assign pending_error = (cause_q == 2'd0) && enabled_error;

  always_comb begin
    if (error_l2)
      selected_error_bits = io_errors_l2_ecc_error_bits;
    else if (error_uncache)
      selected_error_bits = io_errors_uncache_ecc_error_bits;
    else if (error_dcache)
      selected_error_bits = io_errors_dcache_ecc_error_bits;
    else
      selected_error_bits = io_errors_icache_ecc_error_bits;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      cause_q <= 2'd0;
      enable_q <= 4'hf;
      global_interrupt_q <= 4'h0;
      accrued_q <= 4'h0;
      local_interrupt_q <= 4'h0;
    end else begin
      if (write_cause)
        cause_q <= auto_in_a_bits_data[1:0];
      else if (pending_error) begin
        if (error_l2)
          cause_q <= 2'd3;
        else if (error_uncache)
          cause_q <= 2'd2;
        else if (error_dcache)
          cause_q <= 2'd1;
        else
          cause_q <= 2'd0;
      end

      if (write_enable)
        enable_q <= auto_in_a_bits_data[3:0];
      if (write_global)
        global_interrupt_q <= auto_in_a_bits_data[3:0];
      if (write_accrued)
        accrued_q <= auto_in_a_bits_data[3:0];
      else
        accrued_q <= accrued_q | {
          io_errors_l2_ecc_error_valid,
          io_errors_uncache_ecc_error_valid,
          io_errors_dcache_ecc_error_valid,
          io_errors_icache_ecc_error_valid
        };
      if (write_local)
        local_interrupt_q <= auto_in_a_bits_data[3:0];
    end
  end

  // The pad register has byte write enables and is intentionally not reset.
  // Until a write or an enabled error arrives, that matches the generated
  // design's uninitialized diagnostic payload behavior.
  always_ff @(posedge clock) begin
    if (write_pad && (|auto_in_a_bits_mask[5:0])) begin
      for (int byte_index = 0; byte_index < 6; byte_index++)
        if (auto_in_a_bits_mask[byte_index])
          pad_q[byte_index * 8 +: 8] <= auto_in_a_bits_data[byte_index * 8 +: 8];
    end else if (pending_error) begin
      pad_q <= selected_error_bits;
    end
  end

  always_comb begin
    // All six implemented registers are visible only in the low address page;
    // the remaining two slots read as zero.
    read_data = 48'h0;
    if (address_page_zero) begin
      case (register_index)
        3'd0: read_data = {{46{1'b0}}, cause_q};
        3'd1: read_data = pad_q;
        3'd2: read_data = {{44{1'b0}}, enable_q};
        3'd3: read_data = {{44{1'b0}}, global_interrupt_q};
        3'd4: read_data = {{44{1'b0}}, accrued_q};
        3'd5: read_data = {{44{1'b0}}, local_interrupt_q};
        default: read_data = 48'h0;
      endcase
    end
  end

  assign auto_in_a_ready = auto_in_d_ready;
  assign auto_in_d_valid = auto_in_a_valid;
  assign auto_in_d_bits_opcode = {3'h0, is_read};
  assign auto_in_d_bits_size = auto_in_a_bits_size;
  assign auto_in_d_bits_source = auto_in_a_bits_source;
  assign auto_in_d_bits_data = {16'h0, read_data};
  assign auto_int_out_0 = |(accrued_q & global_interrupt_q);
  assign io_interrupt = |(accrued_q & local_interrupt_q);
endmodule

module BusErrorUnit (
  input  logic clock,
  input  logic reset,
  output logic auto_in_a_ready,
  input  logic auto_in_a_valid,
  input  logic [3:0] auto_in_a_bits_opcode,
  input  logic [1:0] auto_in_a_bits_size,
  input  logic [4:0] auto_in_a_bits_source,
  input  logic [29:0] auto_in_a_bits_address,
  input  logic [7:0] auto_in_a_bits_mask,
  input  logic [63:0] auto_in_a_bits_data,
  input  logic auto_in_d_ready,
  output logic auto_in_d_valid,
  output logic [3:0] auto_in_d_bits_opcode,
  output logic [1:0] auto_in_d_bits_size,
  output logic [4:0] auto_in_d_bits_source,
  output logic [63:0] auto_in_d_bits_data,
  output logic auto_int_out_0,
  input  logic io_errors_icache_ecc_error_valid,
  input  logic [47:0] io_errors_icache_ecc_error_bits,
  input  logic io_errors_dcache_ecc_error_valid,
  input  logic [47:0] io_errors_dcache_ecc_error_bits,
  input  logic io_errors_uncache_ecc_error_valid,
  input  logic [47:0] io_errors_uncache_ecc_error_bits,
  input  logic io_errors_l2_ecc_error_valid,
  input  logic [47:0] io_errors_l2_ecc_error_bits,
  output logic io_interrupt
);
  xs_BusErrorUnit_core u_core (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(auto_in_d_valid),
    .auto_in_d_bits_opcode(auto_in_d_bits_opcode),
    .auto_in_d_bits_size(auto_in_d_bits_size),
    .auto_in_d_bits_source(auto_in_d_bits_source),
    .auto_in_d_bits_data(auto_in_d_bits_data),
    .auto_int_out_0(auto_int_out_0),
    .io_errors_icache_ecc_error_valid(io_errors_icache_ecc_error_valid),
    .io_errors_icache_ecc_error_bits(io_errors_icache_ecc_error_bits),
    .io_errors_dcache_ecc_error_valid(io_errors_dcache_ecc_error_valid),
    .io_errors_dcache_ecc_error_bits(io_errors_dcache_ecc_error_bits),
    .io_errors_uncache_ecc_error_valid(io_errors_uncache_ecc_error_valid),
    .io_errors_uncache_ecc_error_bits(io_errors_uncache_ecc_error_bits),
    .io_errors_l2_ecc_error_valid(io_errors_l2_ecc_error_valid),
    .io_errors_l2_ecc_error_bits(io_errors_l2_ecc_error_bits),
    .io_interrupt(io_interrupt)
  );
endmodule
