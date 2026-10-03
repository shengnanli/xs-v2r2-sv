`timescale 1ns/1ps
// Differential UT for Std (store-data FU) and MemExeUnit (its exe-unit shell).
// Both are pure combinational pass-throughs.  Each vector drives random
// handshake and payload bits into golden and rewritten copies of BOTH
// modules (Std standalone, and MemExeUnit whose impl copy instantiates the
// rewritten Std via the derived _xs wrappers) and compares every output;
// an in-tb oracle re-derives each output from the Scala field mapping.
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;
  int unsigned hs[4];   // {in_valid, out_ready} combinations seen

  // shared stimulus
  logic        in_valid, out_ready, rob_flag, sq_flag;
  logic [7:0]  rob_value;
  logic [5:0]  sq_value;
  logic [34:0] fu_type;
  logic [8:0]  fu_op_type;
  logic [63:0] src0;

  // ---- Std ----
  wire        s_in_ready_g, s_out_valid_g, s_rob_flag_g;
  wire [7:0]  s_rob_value_g;
  wire [63:0] s_data_g;
  wire        s_in_ready_i, s_out_valid_i, s_rob_flag_i;
  wire [7:0]  s_rob_value_i;
  wire [63:0] s_data_i;
  Std g_std (
    .io_in_ready(s_in_ready_g), .io_in_valid(in_valid),
    .io_in_bits_ctrl_robIdx_flag(rob_flag), .io_in_bits_ctrl_robIdx_value(rob_value),
    .io_in_bits_data_src_0(src0), .io_out_ready(out_ready), .io_out_valid(s_out_valid_g),
    .io_out_bits_ctrl_robIdx_flag(s_rob_flag_g), .io_out_bits_ctrl_robIdx_value(s_rob_value_g),
    .io_out_bits_res_data(s_data_g)
  );
  Std_xs i_std (
    .io_in_ready(s_in_ready_i), .io_in_valid(in_valid),
    .io_in_bits_ctrl_robIdx_flag(rob_flag), .io_in_bits_ctrl_robIdx_value(rob_value),
    .io_in_bits_data_src_0(src0), .io_out_ready(out_ready), .io_out_valid(s_out_valid_i),
    .io_out_bits_ctrl_robIdx_flag(s_rob_flag_i), .io_out_bits_ctrl_robIdx_value(s_rob_value_i),
    .io_out_bits_res_data(s_data_i)
  );

  // ---- MemExeUnit ----
  wire        m_in_ready_g, m_out_valid_g, m_rob_flag_g, m_sq_flag_g;
  wire [34:0] m_fu_type_g;
  wire [8:0]  m_fu_op_g;
  wire [7:0]  m_rob_value_g;
  wire [5:0]  m_sq_value_g;
  wire [63:0] m_data_g;
  wire        m_in_ready_i, m_out_valid_i, m_rob_flag_i, m_sq_flag_i;
  wire [34:0] m_fu_type_i;
  wire [8:0]  m_fu_op_i;
  wire [7:0]  m_rob_value_i;
  wire [5:0]  m_sq_value_i;
  wire [63:0] m_data_i;
  MemExeUnit g_meu (
    .io_in_ready(m_in_ready_g), .io_in_valid(in_valid),
    .io_in_bits_uop_fuType(fu_type), .io_in_bits_uop_fuOpType(fu_op_type),
    .io_in_bits_uop_robIdx_flag(rob_flag), .io_in_bits_uop_robIdx_value(rob_value),
    .io_in_bits_uop_sqIdx_flag(sq_flag), .io_in_bits_uop_sqIdx_value(sq_value),
    .io_in_bits_src_0(src0), .io_out_ready(out_ready), .io_out_valid(m_out_valid_g),
    .io_out_bits_uop_fuType(m_fu_type_g), .io_out_bits_uop_fuOpType(m_fu_op_g),
    .io_out_bits_uop_robIdx_flag(m_rob_flag_g), .io_out_bits_uop_robIdx_value(m_rob_value_g),
    .io_out_bits_uop_sqIdx_flag(m_sq_flag_g), .io_out_bits_uop_sqIdx_value(m_sq_value_g),
    .io_out_bits_data(m_data_g)
  );
  MemExeUnit_xs i_meu (
    .io_in_ready(m_in_ready_i), .io_in_valid(in_valid),
    .io_in_bits_uop_fuType(fu_type), .io_in_bits_uop_fuOpType(fu_op_type),
    .io_in_bits_uop_robIdx_flag(rob_flag), .io_in_bits_uop_robIdx_value(rob_value),
    .io_in_bits_uop_sqIdx_flag(sq_flag), .io_in_bits_uop_sqIdx_value(sq_value),
    .io_in_bits_src_0(src0), .io_out_ready(out_ready), .io_out_valid(m_out_valid_i),
    .io_out_bits_uop_fuType(m_fu_type_i), .io_out_bits_uop_fuOpType(m_fu_op_i),
    .io_out_bits_uop_robIdx_flag(m_rob_flag_i), .io_out_bits_uop_robIdx_value(m_rob_value_i),
    .io_out_bits_uop_sqIdx_flag(m_sq_flag_i), .io_out_bits_uop_sqIdx_value(m_sq_value_i),
    .io_out_bits_data(m_data_i)
  );

  task automatic compare_now;
    begin
      #1;
      vectors++;
      hs[{in_valid, out_ready}]++;
      if ({s_in_ready_g, s_out_valid_g, s_rob_flag_g, s_rob_value_g, s_data_g} !==
          {s_in_ready_i, s_out_valid_i, s_rob_flag_i, s_rob_value_i, s_data_i}) begin
        errors++;
        if (errors < 8) $display("Std golden mismatch @%0d", vectors);
      end
      if ({m_in_ready_g, m_out_valid_g, m_fu_type_g, m_fu_op_g, m_rob_flag_g, m_rob_value_g,
           m_sq_flag_g, m_sq_value_g, m_data_g} !==
          {m_in_ready_i, m_out_valid_i, m_fu_type_i, m_fu_op_i, m_rob_flag_i, m_rob_value_i,
           m_sq_flag_i, m_sq_value_i, m_data_i}) begin
        errors++;
        if (errors < 8) $display("MemExeUnit golden mismatch @%0d", vectors);
      end
      // oracle: Scala field mapping
      if ({s_in_ready_i, s_out_valid_i, s_rob_flag_i, s_rob_value_i, s_data_i} !==
          {out_ready, in_valid, rob_flag, rob_value, src0} ||
          {m_in_ready_i, m_out_valid_i, m_fu_type_i, m_fu_op_i, m_rob_flag_i, m_rob_value_i,
           m_sq_flag_i, m_sq_value_i, m_data_i} !==
          {out_ready, in_valid, fu_type, fu_op_type, rob_flag, rob_value, sq_flag, sq_value, src0}) begin
        errors++;
        if (errors < 8) $display("oracle mismatch @%0d", vectors);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    repeat (NCYCLES) begin
      {in_valid, out_ready, rob_flag, sq_flag} = 4'($urandom);
      rob_value  = 8'($urandom);
      sq_value   = 6'($urandom);
      fu_type    = {3'($urandom), 32'($urandom)};
      fu_op_type = 9'($urandom);
      src0       = {$urandom, $urandom};
      if ($urandom % 16 == 0) begin  // all-ones / all-zero payload corners
        {fu_type, fu_op_type, rob_value, sq_value, src0} = ($urandom % 2) ? '1 : '0;
      end
      compare_now();
    end
    $display("COVERAGE handshake {valid,ready}: 00=%0d 01=%0d 10=%0d 11=%0d", hs[0], hs[1], hs[2], hs[3]);
    if (hs[0] == 0 || hs[1] == 0 || hs[2] == 0 || hs[3] == 0) begin
      errors++;
      $display("coverage hole");
    end
    $display("MemExeUnit UT (Std + MemExeUnit): vectors=%0d errors=%0d", vectors, errors);
    if (errors == 0) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
