// EnqPolicy 家族 UT —— golden 与重写件双例化（每个位宽变体一对），逐拍比全部输出。
//
// 激励：纯组合块，输入只有 canEnq 一根。
//   * W <= 16 的变体：前 2^W 拍把 canEnq 从 0 数到 2^W-1，**穷举**全部输入；
//   * 之后（以及 W > 16 的变体全程）按五种形态随机：全随机 / 全 0 / 只 1 位 /
//     只 2 位 / 全 1 去掉几位 —— 后四种专门打「0 个、1 个、2 个空槽」这几个
//     边界（全随机下 W=22 时 popcount<2 几乎不出现）。
// 覆盖闸：每个变体 popcount==0 / ==1 / >=2 三个桶都必须非零，否则判 FAIL。
//
// 自动生成：scripts/gen_enqpolicy.py —— 勿手改
`timescale 1ns/1ps

module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  longint checks = 0;
  int cov_fail = 0;

  function automatic int popc(input logic [63:0] x);
    popc = 0;
    for (int k = 0; k < 64; k++) popc += x[k];
  endfunction

  // ---- EnqPolicy（W=22）----
  logic [21:0] in_EnqPolicy;
  wire        g_EnqPolicy_v0, g_EnqPolicy_v1;
  wire [21:0] g_EnqPolicy_b0, g_EnqPolicy_b1;
  wire        i_EnqPolicy_v0, i_EnqPolicy_v1;
  wire [21:0] i_EnqPolicy_b0, i_EnqPolicy_b1;
  EnqPolicy u_g_EnqPolicy (
    .io_canEnq(in_EnqPolicy),
    .io_enqSelOHVec_0_valid(g_EnqPolicy_v0),
    .io_enqSelOHVec_0_bits(g_EnqPolicy_b0),
    .io_enqSelOHVec_1_valid(g_EnqPolicy_v1),
    .io_enqSelOHVec_1_bits(g_EnqPolicy_b1)
  );
  EnqPolicy_xs u_i_EnqPolicy (
    .io_canEnq(in_EnqPolicy),
    .io_enqSelOHVec_0_valid(i_EnqPolicy_v0),
    .io_enqSelOHVec_0_bits(i_EnqPolicy_b0),
    .io_enqSelOHVec_1_valid(i_EnqPolicy_v1),
    .io_enqSelOHVec_1_bits(i_EnqPolicy_b1)
  );
  int cov_EnqPolicy_pc0 = 0, cov_EnqPolicy_pc1 = 0, cov_EnqPolicy_pc2 = 0;

  // ---- EnqPolicy_14（W=14）----
  logic [13:0] in_EnqPolicy_14;
  wire        g_EnqPolicy_14_v0, g_EnqPolicy_14_v1;
  wire [13:0] g_EnqPolicy_14_b0, g_EnqPolicy_14_b1;
  wire        i_EnqPolicy_14_v0, i_EnqPolicy_14_v1;
  wire [13:0] i_EnqPolicy_14_b0, i_EnqPolicy_14_b1;
  EnqPolicy_14 u_g_EnqPolicy_14 (
    .io_canEnq(in_EnqPolicy_14),
    .io_enqSelOHVec_0_valid(g_EnqPolicy_14_v0),
    .io_enqSelOHVec_0_bits(g_EnqPolicy_14_b0),
    .io_enqSelOHVec_1_valid(g_EnqPolicy_14_v1),
    .io_enqSelOHVec_1_bits(g_EnqPolicy_14_b1)
  );
  EnqPolicy_14_xs u_i_EnqPolicy_14 (
    .io_canEnq(in_EnqPolicy_14),
    .io_enqSelOHVec_0_valid(i_EnqPolicy_14_v0),
    .io_enqSelOHVec_0_bits(i_EnqPolicy_14_b0),
    .io_enqSelOHVec_1_valid(i_EnqPolicy_14_v1),
    .io_enqSelOHVec_1_bits(i_EnqPolicy_14_b1)
  );
  int cov_EnqPolicy_14_pc0 = 0, cov_EnqPolicy_14_pc1 = 0, cov_EnqPolicy_14_pc2 = 0;

  // ---- EnqPolicy_18（W=8）----
  logic [7:0] in_EnqPolicy_18;
  wire        g_EnqPolicy_18_v0, g_EnqPolicy_18_v1;
  wire [7:0] g_EnqPolicy_18_b0, g_EnqPolicy_18_b1;
  wire        i_EnqPolicy_18_v0, i_EnqPolicy_18_v1;
  wire [7:0] i_EnqPolicy_18_b0, i_EnqPolicy_18_b1;
  EnqPolicy_18 u_g_EnqPolicy_18 (
    .io_canEnq(in_EnqPolicy_18),
    .io_enqSelOHVec_0_valid(g_EnqPolicy_18_v0),
    .io_enqSelOHVec_0_bits(g_EnqPolicy_18_b0),
    .io_enqSelOHVec_1_valid(g_EnqPolicy_18_v1),
    .io_enqSelOHVec_1_bits(g_EnqPolicy_18_b1)
  );
  EnqPolicy_18_xs u_i_EnqPolicy_18 (
    .io_canEnq(in_EnqPolicy_18),
    .io_enqSelOHVec_0_valid(i_EnqPolicy_18_v0),
    .io_enqSelOHVec_0_bits(i_EnqPolicy_18_b0),
    .io_enqSelOHVec_1_valid(i_EnqPolicy_18_v1),
    .io_enqSelOHVec_1_bits(i_EnqPolicy_18_b1)
  );
  int cov_EnqPolicy_18_pc0 = 0, cov_EnqPolicy_18_pc1 = 0, cov_EnqPolicy_18_pc2 = 0;

  // ---- EnqPolicy_8（W=16）----
  logic [15:0] in_EnqPolicy_8;
  wire        g_EnqPolicy_8_v0, g_EnqPolicy_8_v1;
  wire [15:0] g_EnqPolicy_8_b0, g_EnqPolicy_8_b1;
  wire        i_EnqPolicy_8_v0, i_EnqPolicy_8_v1;
  wire [15:0] i_EnqPolicy_8_b0, i_EnqPolicy_8_b1;
  EnqPolicy_8 u_g_EnqPolicy_8 (
    .io_canEnq(in_EnqPolicy_8),
    .io_enqSelOHVec_0_valid(g_EnqPolicy_8_v0),
    .io_enqSelOHVec_0_bits(g_EnqPolicy_8_b0),
    .io_enqSelOHVec_1_valid(g_EnqPolicy_8_v1),
    .io_enqSelOHVec_1_bits(g_EnqPolicy_8_b1)
  );
  EnqPolicy_8_xs u_i_EnqPolicy_8 (
    .io_canEnq(in_EnqPolicy_8),
    .io_enqSelOHVec_0_valid(i_EnqPolicy_8_v0),
    .io_enqSelOHVec_0_bits(i_EnqPolicy_8_b0),
    .io_enqSelOHVec_1_valid(i_EnqPolicy_8_v1),
    .io_enqSelOHVec_1_bits(i_EnqPolicy_8_b1)
  );
  int cov_EnqPolicy_8_pc0 = 0, cov_EnqPolicy_8_pc1 = 0, cov_EnqPolicy_8_pc2 = 0;

  `define CHK(G, I, NM) begin \
    checks++; \
    if ((G) !== (I)) begin \
      errors++; \
      if (errors <= 40) $display("[ERR] cyc=%0d %s golden=%h impl=%h", cyc, NM, G, I); \
    end \
  end

  // W 位的随机激励：五种形态（见文件头）
  function automatic logic [63:0] stim(input int w);
    logic [63:0] x;
    case ($urandom_range(0, 4))
      0: x = {$urandom(), $urandom()};
      1: x = '0;
      2: x = 64'(1) << $urandom_range(0, w - 1);
      3: x = (64'(1) << $urandom_range(0, w - 1)) | (64'(1) << $urandom_range(0, w - 1));
      default: x = ~((64'(1) << $urandom_range(0, w - 1)) | (64'(1) << $urandom_range(0, w - 1)));
    endcase
    return x;
  endfunction

  longint cyc = 0;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      in_EnqPolicy = 22'(stim(22));
      in_EnqPolicy_14 = (cyc < (64'(1) << 14)) ? 14'(cyc) : 14'(stim(14));
      in_EnqPolicy_18 = (cyc < (64'(1) << 8)) ? 8'(cyc) : 8'(stim(8));
      in_EnqPolicy_8 = (cyc < (64'(1) << 16)) ? 16'(cyc) : 16'(stim(16));
      #1;
      `CHK(g_EnqPolicy_v0, i_EnqPolicy_v0, "EnqPolicy.io_enqSelOHVec_0_valid")
      `CHK(g_EnqPolicy_b0, i_EnqPolicy_b0, "EnqPolicy.io_enqSelOHVec_0_bits")
      `CHK(g_EnqPolicy_v1, i_EnqPolicy_v1, "EnqPolicy.io_enqSelOHVec_1_valid")
      `CHK(g_EnqPolicy_b1, i_EnqPolicy_b1, "EnqPolicy.io_enqSelOHVec_1_bits")
      case (popc(64'(in_EnqPolicy)))
        0: cov_EnqPolicy_pc0++;
        1: cov_EnqPolicy_pc1++;
        default: cov_EnqPolicy_pc2++;
      endcase
      `CHK(g_EnqPolicy_14_v0, i_EnqPolicy_14_v0, "EnqPolicy_14.io_enqSelOHVec_0_valid")
      `CHK(g_EnqPolicy_14_b0, i_EnqPolicy_14_b0, "EnqPolicy_14.io_enqSelOHVec_0_bits")
      `CHK(g_EnqPolicy_14_v1, i_EnqPolicy_14_v1, "EnqPolicy_14.io_enqSelOHVec_1_valid")
      `CHK(g_EnqPolicy_14_b1, i_EnqPolicy_14_b1, "EnqPolicy_14.io_enqSelOHVec_1_bits")
      case (popc(64'(in_EnqPolicy_14)))
        0: cov_EnqPolicy_14_pc0++;
        1: cov_EnqPolicy_14_pc1++;
        default: cov_EnqPolicy_14_pc2++;
      endcase
      `CHK(g_EnqPolicy_18_v0, i_EnqPolicy_18_v0, "EnqPolicy_18.io_enqSelOHVec_0_valid")
      `CHK(g_EnqPolicy_18_b0, i_EnqPolicy_18_b0, "EnqPolicy_18.io_enqSelOHVec_0_bits")
      `CHK(g_EnqPolicy_18_v1, i_EnqPolicy_18_v1, "EnqPolicy_18.io_enqSelOHVec_1_valid")
      `CHK(g_EnqPolicy_18_b1, i_EnqPolicy_18_b1, "EnqPolicy_18.io_enqSelOHVec_1_bits")
      case (popc(64'(in_EnqPolicy_18)))
        0: cov_EnqPolicy_18_pc0++;
        1: cov_EnqPolicy_18_pc1++;
        default: cov_EnqPolicy_18_pc2++;
      endcase
      `CHK(g_EnqPolicy_8_v0, i_EnqPolicy_8_v0, "EnqPolicy_8.io_enqSelOHVec_0_valid")
      `CHK(g_EnqPolicy_8_b0, i_EnqPolicy_8_b0, "EnqPolicy_8.io_enqSelOHVec_0_bits")
      `CHK(g_EnqPolicy_8_v1, i_EnqPolicy_8_v1, "EnqPolicy_8.io_enqSelOHVec_1_valid")
      `CHK(g_EnqPolicy_8_b1, i_EnqPolicy_8_b1, "EnqPolicy_8.io_enqSelOHVec_1_bits")
      case (popc(64'(in_EnqPolicy_8)))
        0: cov_EnqPolicy_8_pc0++;
        1: cov_EnqPolicy_8_pc1++;
        default: cov_EnqPolicy_8_pc2++;
      endcase
      #1;
    end
    $display("=== %0d cycles, checks=%0d, errors=%0d ===", cyc, checks, errors);
    $display("  cov %-22s = %0d", "EnqPolicy_pc0", cov_EnqPolicy_pc0);
    if (cov_EnqPolicy_pc0 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_pc0"); end
    $display("  cov %-22s = %0d", "EnqPolicy_pc1", cov_EnqPolicy_pc1);
    if (cov_EnqPolicy_pc1 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_pc1"); end
    $display("  cov %-22s = %0d", "EnqPolicy_pc2", cov_EnqPolicy_pc2);
    if (cov_EnqPolicy_pc2 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_pc2"); end
    $display("  cov %-22s = %0d", "EnqPolicy_14_pc0", cov_EnqPolicy_14_pc0);
    if (cov_EnqPolicy_14_pc0 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_14_pc0"); end
    $display("  cov %-22s = %0d", "EnqPolicy_14_pc1", cov_EnqPolicy_14_pc1);
    if (cov_EnqPolicy_14_pc1 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_14_pc1"); end
    $display("  cov %-22s = %0d", "EnqPolicy_14_pc2", cov_EnqPolicy_14_pc2);
    if (cov_EnqPolicy_14_pc2 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_14_pc2"); end
    $display("  cov %-22s = %0d", "EnqPolicy_18_pc0", cov_EnqPolicy_18_pc0);
    if (cov_EnqPolicy_18_pc0 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_18_pc0"); end
    $display("  cov %-22s = %0d", "EnqPolicy_18_pc1", cov_EnqPolicy_18_pc1);
    if (cov_EnqPolicy_18_pc1 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_18_pc1"); end
    $display("  cov %-22s = %0d", "EnqPolicy_18_pc2", cov_EnqPolicy_18_pc2);
    if (cov_EnqPolicy_18_pc2 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_18_pc2"); end
    $display("  cov %-22s = %0d", "EnqPolicy_8_pc0", cov_EnqPolicy_8_pc0);
    if (cov_EnqPolicy_8_pc0 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_8_pc0"); end
    $display("  cov %-22s = %0d", "EnqPolicy_8_pc1", cov_EnqPolicy_8_pc1);
    if (cov_EnqPolicy_8_pc1 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_8_pc1"); end
    $display("  cov %-22s = %0d", "EnqPolicy_8_pc2", cov_EnqPolicy_8_pc2);
    if (cov_EnqPolicy_8_pc2 == 0) begin cov_fail++; $display("  *** COVERAGE HOLE: EnqPolicy_8_pc2"); end
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED (errors=%0d cov_fail=%0d checks=%0d)", errors, cov_fail, checks);
    $finish;
  end
endmodule
