// =============================================================================
// tb —— CVT64 双例化 UT（由 scripts/gen_exeunits_ut.py 生成，勿手改）
//   golden CVT64 vs 重写 CVT64_xs；每拍比较全部 2 个输出口（!==）。
//   激励 / 覆盖 / 判据见生成器 TARGETS 里本目标一节。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int WARM = 10;
  localparam int RESET_ODDS = 20000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  always #5 clock = ~clock;
  logic reset;

  logic io_fire;
  logic [63:0] io_src;
  logic [7:0] io_opType;
  logic [2:0] io_rm;
  logic [3:0] io_input1H;
  logic [3:0] io_output1H;
  logic [1:0] io_isFround;
  logic io_isFcvtmod;
  wire  [63:0] g_io_result, i_io_result;
  wire  [4:0] g_io_fflags, i_io_fflags;

  function automatic logic [7:0] fpcvt_w1h(logic [1:0] w, logic [1:0] sew);   // {in1H, out1H}
    case ({w, sew})
      4'b00_01: return 8'b0010_0010;  4'b00_10: return 8'b0100_0100;  4'b00_11: return 8'b1000_1000;
      4'b01_00: return 8'b0001_0010;  4'b01_01: return 8'b0010_0100;  4'b01_10: return 8'b0100_1000;
      4'b10_00: return 8'b0010_0001;  4'b10_01: return 8'b0100_0010;  4'b10_10: return 8'b1000_0100;
      4'b11_01: return 8'b0010_1000;  4'b11_11: return 8'b1000_0010;
      default:  return 8'b0000_0000;
    endcase
  endfunction
  // 浮点源定向值池（按宽度放在低位）：0 / ±inf / qNaN / sNaN / 最小非规格化 / 1.0 / 最大有限
  function automatic logic [63:0] fp_pick(int w);
    logic [63:0] v;
    int k;
    k = $urandom_range(0, 9);
    v = {$urandom(), $urandom()};
    case (w)
      16: case (k) 0: v[15:0] = 16'h0000; 1: v[15:0] = 16'h7C00; 2: v[15:0] = 16'hFC00; 3: v[15:0] = 16'h7E00;
                   4: v[15:0] = 16'h7D00; 5: v[15:0] = 16'h0001; 6: v[15:0] = 16'h3C00; 7: v[15:0] = 16'h7BFF;
                   default: ; endcase
      32: case (k) 0: v[31:0] = 32'h0; 1: v[31:0] = 32'h7F800000; 2: v[31:0] = 32'hFF800000;
                   3: v[31:0] = 32'h7FC00000; 4: v[31:0] = 32'h7FA00000; 5: v[31:0] = 32'h1;
                   6: v[31:0] = 32'h3F800000; 7: v[31:0] = 32'h7F7FFFFF; default: ; endcase
      default: case (k) 0: v = 64'h0; 1: v = 64'h7FF0000000000000; 2: v = 64'hFFF0000000000000;
                   3: v = 64'h7FF8000000000000; 4: v = 64'h7FF4000000000000; 5: v = 64'h1;
                   6: v = 64'h3FF0000000000000; 7: v = 64'h7FEFFFFFFFFFFFFF; default: ; endcase
    endcase
    return v;
  endfunction

  // 标量 FCVT 会送进来的 opType（fcvt_pkg 注释里的编码）：f2i / i2f / f2f / fround / fcvtmod
  logic [7:0] cvt_pool [26] = '{8'h80, 8'h81, 8'h86, 8'h87, 8'h88, 8'h89, 8'h8E, 8'h8F, 8'h90, 8'h91,
                                8'h98, 8'h99, 8'h42, 8'h43, 8'h4A, 8'h4B, 8'h52, 8'h53, 8'hC8, 8'hD0,
                                8'hD4, 8'hD8, 8'hC0, 8'hC4, 8'h96, 8'h97};
  longint c_cnan_i = 0, c_cnan_f = 0, c_cnan_fround = 0, c_f2i = 0, c_i2f = 0, c_f2f = 0, c_fround = 0, c_fcvtmod = 0;

  CVT64 u_g (
    .clock(clock),
    .reset(reset),
    .io_fire(io_fire),
    .io_src(io_src),
    .io_opType(io_opType),
    .io_rm(io_rm),
    .io_input1H(io_input1H),
    .io_output1H(io_output1H),
    .io_isFround(io_isFround),
    .io_isFcvtmod(io_isFcvtmod),
    .io_result(g_io_result),
    .io_fflags(g_io_fflags)
  );
  CVT64_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_fire(io_fire),
    .io_src(io_src),
    .io_opType(io_opType),
    .io_rm(io_rm),
    .io_input1H(io_input1H),
    .io_output1H(io_output1H),
    .io_isFround(io_isFround),
    .io_isFcvtmod(io_isFcvtmod),
    .io_result(i_io_result),
    .io_fflags(i_io_fflags)
  );

  // 每拍激励：先全随机，再按目标语义覆盖
  task automatic drive();
    io_fire = 1'($urandom);
    io_src = 64'({$urandom(), $urandom()});
    io_opType = 8'($urandom);
    io_rm = 3'($urandom);
    io_input1H = 4'($urandom);
    io_output1H = 4'($urandom);
    io_isFround = 2'($urandom);
    io_isFcvtmod = 1'($urandom);

    if ($urandom_range(0, 99) < 90) begin
      logic [1:0] sew;
      logic [7:0] w1h;
      int iw;
      io_opType = cvt_pool[$urandom_range(0, 25)];
      sew = 2'($urandom_range(0, 3));
      w1h = fpcvt_w1h(io_opType[4:3], sew);
      if ($urandom_range(0, 99) < 90) {io_input1H, io_output1H} = w1h;
      io_isFround  = (io_opType == 8'hC0) ? 2'b01 : (io_opType == 8'hC4) ? 2'b10 : 2'b00;
      io_isFcvtmod = (io_opType == 8'h91) && $urandom_range(0, 1);
      if ($urandom_range(0, 19) == 0) io_isFround = 2'($urandom);
      if ($urandom_range(0, 3) != 0) io_rm = 3'($urandom_range(0, 4));
      iw = io_input1H[1] ? 16 : io_input1H[2] ? 32 : 64;
      if (io_opType[7]) begin
        io_src = fp_pick(iw);
        // 一半给合法 NaN-box（高位全 1），一半留随机高位（触发规范 NaN 通路）
        if ($urandom_range(0, 1)) begin
          if (iw == 16) io_src[63:16] = '1;
          if (iw == 32) io_src[63:32] = '1;
        end
      end
    end
    // 暖机：复位撤销后连发有效请求，把两级不复位的寄存器写成确定值再开始比
    io_fire = ($urandom_range(0, 9) < 7) || (cyc < WARM);

  endtask

  task automatic compare();
    checks++; if (g_io_result !== i_io_result) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_result g=%h i=%h", cyc, g_io_result, i_io_result); end
    checks++; if (g_io_fflags !== i_io_fflags) begin errors++; if (errors <= 30) $display("[%0d] MISMATCH io_fflags g=%h i=%h", cyc, g_io_fflags, i_io_fflags); end
  endtask

  task automatic sample_cov();

    if (io_fire) begin
      bit cnan;
      cnan = io_opType[7] && ((io_input1H[1] && io_src[63:16] != '1) || (io_input1H[2] && io_src[63:32] != '1));
      if (cnan && !io_opType[6]) c_cnan_i++;
      if (cnan &&  io_opType[6]) c_cnan_f++;
      if (cnan && |io_isFround) c_cnan_fround++;
      if (io_opType[7] && !io_opType[6]) c_f2i++;
      if (!io_opType[7]) c_i2f++;
      if (io_opType[7] && io_opType[6]) c_f2f++;
      if (|io_isFround) c_fround++;
      if (io_isFcvtmod) c_fcvtmod++;
    end

  endtask

  initial begin
    bit ok;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    reset = 1;
    drive();
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      reset = (cyc < 5) || ($urandom_range(0, RESET_ODDS - 1) == 0);
      drive();
      #4;
      if (cyc >= WARM) compare();
      if (!reset) sample_cov();
    end
    $display("cov cnan int/fp/fround=%0d/%0d/%0d f2i=%0d i2f=%0d f2f=%0d fround=%0d fcvtmod=%0d", c_cnan_i, c_cnan_f, c_cnan_fround, c_f2i, c_i2f, c_f2f, c_fround, c_fcvtmod);
    ok = (errors == 0) && (checks > 1000);
    if (!(c_cnan_i > 1000)) begin ok = 0; $display("cov LOW: c_cnan_i > 1000"); end
    if (!(c_cnan_f > 1000)) begin ok = 0; $display("cov LOW: c_cnan_f > 1000"); end
    if (!(c_cnan_fround > 500)) begin ok = 0; $display("cov LOW: c_cnan_fround > 500"); end
    if (!(c_f2i > 1000)) begin ok = 0; $display("cov LOW: c_f2i > 1000"); end
    if (!(c_i2f > 1000)) begin ok = 0; $display("cov LOW: c_i2f > 1000"); end
    if (!(c_f2f > 1000)) begin ok = 0; $display("cov LOW: c_f2f > 1000"); end
    if (!(c_fround > 1000)) begin ok = 0; $display("cov LOW: c_fround > 1000"); end
    if (!(c_fcvtmod > 500)) begin ok = 0; $display("cov LOW: c_fcvtmod > 500"); end
    $display("checks=%0d errors=%0d", checks, errors);
    if (ok) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
