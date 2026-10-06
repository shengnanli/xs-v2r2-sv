// FloatAdder UT — golden 与重写件双例化逐拍逐位比较
// 输入覆盖 f16、f32、f64，加减、min/max、比较、符号注入、分类和 min/max magnitude。
// 特殊输入覆盖零、负零、无穷、qNaN、sNaN、次正规数、正规数和指数边界。
// 两侧寄存器均不复位，因此第一次 fire 之后才开始比较；之后每拍检查全部输出端口。
// 随机激励由 $urandom 提供，运行参数 +ntb_random_seed 控制随机种子。

`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  longint unsigned checks = 0;
  longint unsigned errors = 0;

  logic clock = 1'b0;
  always #5 clock = ~clock;

  logic        io_fire;
  logic [63:0] io_fp_a;
  logic [63:0] io_fp_b;
  logic [2:0]  io_round_mode;
  logic [1:0]  io_fp_format;
  logic [4:0]  io_op_code;
  logic        io_fp_aIsFpCanonicalNAN;
  logic        io_fp_bIsFpCanonicalNAN;

  logic [63:0] golden_result;
  logic [4:0]  golden_fflags;
  logic [63:0] impl_result;
  logic [4:0]  impl_fflags;

  FloatAdder g (
    .clock                   (clock),
    .io_fire                 (io_fire),
    .io_fp_a                 (io_fp_a),
    .io_fp_b                 (io_fp_b),
    .io_round_mode            (io_round_mode),
    .io_fp_format             (io_fp_format),
    .io_op_code               (io_op_code),
    .io_fp_aIsFpCanonicalNAN (io_fp_aIsFpCanonicalNAN),
    .io_fp_bIsFpCanonicalNAN (io_fp_bIsFpCanonicalNAN),
    .io_fp_result             (golden_result),
    .io_fflags                (golden_fflags)
  );

  FloatAdder_xs x (
    .clock                   (clock),
    .io_fire                 (io_fire),
    .io_fp_a                 (io_fp_a),
    .io_fp_b                 (io_fp_b),
    .io_round_mode           (io_round_mode),
    .io_fp_format            (io_fp_format),
    .io_op_code              (io_op_code),
    .io_fp_aIsFpCanonicalNAN (io_fp_aIsFpCanonicalNAN),
    .io_fp_bIsFpCanonicalNAN (io_fp_bIsFpCanonicalNAN),
    .io_fp_result            (impl_result),
    .io_fflags               (impl_fflags)
  );

  int unsigned format_count [1:3];
  int unsigned opcode_count [0:31];
  int unsigned round_count [0:7];
  int unsigned special_count;
  int unsigned canonical_nan_count;

  logic [63:0] seen_result_ones;
  logic [63:0] seen_result_zeros;
  logic [4:0]  seen_flags_ones;
  logic [4:0]  seen_flags_zeros;

  localparam logic [4:0] COVERED_OPS [0:14] = '{
    5'h00, 5'h01, 5'h02, 5'h03, 5'h06, 5'h07, 5'h08, 5'h09,
    5'h0b, 5'h0c, 5'h0f, 5'h13, 5'h1b, 5'h1c, 5'h1e
  };

  function automatic logic [4:0] choose_opcode(input int unsigned n);
    case (n % 20)
      0:  choose_opcode = 5'h00;
      1:  choose_opcode = 5'h01;
      2:  choose_opcode = 5'h02;
      3:  choose_opcode = 5'h03;
      4:  choose_opcode = 5'h06;
      5:  choose_opcode = 5'h07;
      6:  choose_opcode = 5'h08;
      7:  choose_opcode = 5'h09;
      8:  choose_opcode = 5'h0b;
      9:  choose_opcode = 5'h0c;
      10: choose_opcode = 5'h0f;
      11: choose_opcode = 5'h13;
      12: choose_opcode = 5'h1b;
      13: choose_opcode = 5'h1c;
      14: choose_opcode = 5'h1e;
      default: choose_opcode = 5'($urandom_range(0, 31));
    endcase
  endfunction

  task automatic drive_inputs(input int unsigned n);
    int unsigned special_sel;
    logic [31:0] a32;
    logic [31:0] b32;
    logic [15:0] a16;
    logic [15:0] b16;
    begin
      io_fire = ($urandom_range(0, 3) != 0);

      case (n % 3)
        0: io_fp_format = 2'b01;
        1: io_fp_format = 2'b10;
        default: io_fp_format = 2'b11;
      endcase

      if (n < 8)
        io_round_mode = n[2:0];
      else
        io_round_mode = $urandom_range(0, 7);

      io_op_code = choose_opcode(n);
      io_fp_aIsFpCanonicalNAN = ($urandom_range(0, 15) == 0);
      io_fp_bIsFpCanonicalNAN = ($urandom_range(0, 15) == 0);

      special_sel = $urandom_range(0, 15);
      if (special_sel < 8) begin
        a32 = $urandom;
        b32 = $urandom;
      end else begin
        case (special_sel)
          8: begin a32 = 32'h0000_0000; b32 = 32'h8000_0000; end
          9: begin a32 = 32'h8000_0000; b32 = 32'h0000_0000; end
          10: begin a32 = 32'h7f80_0000; b32 = 32'hff80_0000; end
          11: begin a32 = 32'h7f80_0000; b32 = 32'h3f80_0000; end
          12: begin a32 = 32'h7fc0_0001; b32 = 32'h3f80_0000; end
          13: begin a32 = 32'h7f80_0001; b32 = 32'h7fc0_0000; end
          14: begin a32 = 32'h0000_0001; b32 = 32'h8000_0002; end
          default: begin a32 = 32'h007f_ffff; b32 = 32'h0080_0000; end
        endcase
        special_count++;
      end

      if (io_fp_format == 2'b01) begin
        a16 = a32[15:0];
        b16 = b32[15:0];
        io_fp_a = {$urandom, 16'h0000, a16};
        io_fp_b = {$urandom, 16'h0000, b16};
      end else if (io_fp_format == 2'b10) begin
        io_fp_a = {$urandom, a32};
        io_fp_b = {$urandom, b32};
      end else begin
        io_fp_a = {$urandom, $urandom};
        io_fp_b = {$urandom, $urandom};
        if (special_sel >= 8) begin
          io_fp_a = {32'h0, a32};
          io_fp_b = {32'h0, b32};
        end
      end

      if (io_fp_aIsFpCanonicalNAN || io_fp_bIsFpCanonicalNAN)
        canonical_nan_count++;
    end
  endtask

  initial begin
    bit armed;
    bit coverage_ok;

    if ($value$plusargs("ncycles=%d", NCYCLES))
      ;

    for (int unsigned k = 1; k <= 3; k++)
      format_count[k] = 0;
    for (int unsigned k = 0; k < 32; k++)
      opcode_count[k] = 0;
    for (int unsigned k = 0; k < 8; k++)
      round_count[k] = 0;

    seen_result_ones = 64'h0;
    seen_result_zeros = 64'h0;
    seen_flags_ones = 5'h0;
    seen_flags_zeros = 5'h0;
    special_count = 0;
    canonical_nan_count = 0;
    armed = 1'b0;
    coverage_ok = 1'b1;

    io_fire = 1'b0;
    io_fp_a = 64'h0;
    io_fp_b = 64'h0;
    io_round_mode = 3'h0;
    io_fp_format = 2'b01;
    io_op_code = 5'h0;
    io_fp_aIsFpCanonicalNAN = 1'b0;
    io_fp_bIsFpCanonicalNAN = 1'b0;

    for (int unsigned cycle_number = 0;
         cycle_number < NCYCLES;
         cycle_number++) begin
      drive_inputs(cycle_number);
      #1;

      if (armed) begin
        checks++;
        if ((golden_result !== impl_result) ||
            (golden_fflags !== impl_fflags)) begin
          errors++;
          if (errors <= 40)
            $display("MISMATCH cycle=%0d fmt=%b op=%b rm=%0d fire=%0d a=%h b=%h result=%h/%h flags=%b/%b",
                     cycle_number, io_fp_format, io_op_code, io_round_mode,
                     io_fire, io_fp_a, io_fp_b, golden_result, impl_result,
                     golden_fflags, impl_fflags);
        end
        seen_result_ones |= golden_result;
        seen_result_zeros |= ~golden_result;
        seen_flags_ones |= golden_fflags;
        seen_flags_zeros |= ~golden_fflags;
      end

      if (io_fire) begin
        armed = 1'b1;
        format_count[io_fp_format]++;
        opcode_count[io_op_code]++;
        round_count[io_round_mode]++;
      end

      @(posedge clock);
      #1;
    end

    for (int unsigned k = 1; k <= 3; k++) begin
      if (format_count[k] < 1000) begin
        coverage_ok = 1'b0;
        $display("COV FAIL format=%0d count=%0d", k, format_count[k]);
      end
    end

    for (int unsigned k = 0; k < 8; k++) begin
      if (round_count[k] < 500) begin
        coverage_ok = 1'b0;
        $display("COV FAIL round_mode=%0d count=%0d", k, round_count[k]);
      end
    end

    foreach (COVERED_OPS[k]) begin
      if (opcode_count[COVERED_OPS[k]] < 300) begin
        coverage_ok = 1'b0;
        $display("COV FAIL opcode=%h count=%0d",
                 COVERED_OPS[k], opcode_count[COVERED_OPS[k]]);
      end
    end

    if (special_count < 10000) begin
      coverage_ok = 1'b0;
      $display("COV FAIL special_count=%0d", special_count);
    end

    if (canonical_nan_count < 5000) begin
      coverage_ok = 1'b0;
      $display("COV FAIL canonical_nan_count=%0d", canonical_nan_count);
    end

    if (seen_result_ones != 64'hffff_ffff_ffff_ffff ||
        seen_result_zeros != 64'hffff_ffff_ffff_ffff) begin
      coverage_ok = 1'b0;
      $display("COV FAIL result toggle ones=%h zeros=%h",
               seen_result_ones, seen_result_zeros);
    end

    if (seen_flags_ones == 5'b0 ||
        seen_flags_zeros != 5'b1_1111) begin
      coverage_ok = 1'b0;
      $display("COV FAIL flags toggle ones=%b zeros=%b",
               seen_flags_ones, seen_flags_zeros);
    end

    $display("coverage formats=%0d/%0d/%0d special=%0d canonical_nan=%0d",
             format_count[1], format_count[2], format_count[3],
             special_count, canonical_nan_count);
    $display("checks=%0d errors=%0d", checks, errors);

    if ((errors == 0) && coverage_ok)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");

    $finish;
  end

endmodule
