// 自动生成：scripts/gen_imsic.py —— 勿手改
// IMSIC 双例化逐拍比对: golden IMSIC vs 可读重写 IMSIC_xs。
// 激励: fromCSR 访问 (privilege/virt/vgein 偏向合法组合: M/S/VS), 读/写/claim;
// msiio MSI 投递 (vld_req 稀疏翻转产生上升沿, data 含目标文件号+源号)。
// 两侧共享真实 IntFile×7 + IMSICGateWay (+3 级同步链)。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic fromCSR_addr_valid;
  logic [11:0] fromCSR_addr_bits_addr;
  logic fromCSR_addr_bits_virt;
  logic [1:0] fromCSR_addr_bits_priv;
  logic [5:0] fromCSR_vgein;
  logic fromCSR_wdata_valid;
  logic [1:0] fromCSR_wdata_bits_op;
  logic [63:0] fromCSR_wdata_bits_data;
  logic fromCSR_claims_0;
  logic fromCSR_claims_1;
  logic fromCSR_claims_2;
  logic msiio_vld_req;
  logic [10:0] msiio_data;
  wire g_toCSR_rdata_valid;
  wire i_toCSR_rdata_valid;
  wire [63:0] g_toCSR_rdata_bits;
  wire [63:0] i_toCSR_rdata_bits;
  wire g_toCSR_illegal;
  wire i_toCSR_illegal;
  wire [6:0] g_toCSR_pendings;
  wire [6:0] i_toCSR_pendings;
  wire [31:0] g_toCSR_topeis_0;
  wire [31:0] i_toCSR_topeis_0;
  wire [31:0] g_toCSR_topeis_1;
  wire [31:0] i_toCSR_topeis_1;
  wire [31:0] g_toCSR_topeis_2;
  wire [31:0] i_toCSR_topeis_2;

  IMSIC u_g (
    .clock(clock),
    .reset(reset),
    .toCSR_rdata_valid(g_toCSR_rdata_valid),
    .toCSR_rdata_bits(g_toCSR_rdata_bits),
    .toCSR_illegal(g_toCSR_illegal),
    .toCSR_pendings(g_toCSR_pendings),
    .toCSR_topeis_0(g_toCSR_topeis_0),
    .toCSR_topeis_1(g_toCSR_topeis_1),
    .toCSR_topeis_2(g_toCSR_topeis_2),
    .fromCSR_addr_valid(fromCSR_addr_valid),
    .fromCSR_addr_bits_addr(fromCSR_addr_bits_addr),
    .fromCSR_addr_bits_virt(fromCSR_addr_bits_virt),
    .fromCSR_addr_bits_priv(fromCSR_addr_bits_priv),
    .fromCSR_vgein(fromCSR_vgein),
    .fromCSR_wdata_valid(fromCSR_wdata_valid),
    .fromCSR_wdata_bits_op(fromCSR_wdata_bits_op),
    .fromCSR_wdata_bits_data(fromCSR_wdata_bits_data),
    .fromCSR_claims_0(fromCSR_claims_0),
    .fromCSR_claims_1(fromCSR_claims_1),
    .fromCSR_claims_2(fromCSR_claims_2),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data)
  );

  IMSIC_xs u_i (
    .clock(clock),
    .reset(reset),
    .toCSR_rdata_valid(i_toCSR_rdata_valid),
    .toCSR_rdata_bits(i_toCSR_rdata_bits),
    .toCSR_illegal(i_toCSR_illegal),
    .toCSR_pendings(i_toCSR_pendings),
    .toCSR_topeis_0(i_toCSR_topeis_0),
    .toCSR_topeis_1(i_toCSR_topeis_1),
    .toCSR_topeis_2(i_toCSR_topeis_2),
    .fromCSR_addr_valid(fromCSR_addr_valid),
    .fromCSR_addr_bits_addr(fromCSR_addr_bits_addr),
    .fromCSR_addr_bits_virt(fromCSR_addr_bits_virt),
    .fromCSR_addr_bits_priv(fromCSR_addr_bits_priv),
    .fromCSR_vgein(fromCSR_vgein),
    .fromCSR_wdata_valid(fromCSR_wdata_valid),
    .fromCSR_wdata_bits_op(fromCSR_wdata_bits_op),
    .fromCSR_wdata_bits_data(fromCSR_wdata_bits_data),
    .fromCSR_claims_0(fromCSR_claims_0),
    .fromCSR_claims_1(fromCSR_claims_1),
    .fromCSR_claims_2(fromCSR_claims_2),
    .msiio_vld_req(msiio_vld_req),
    .msiio_data(msiio_data)
  );

  // 选一组合法的 {priv, virt, vgein} 以提高文件命中率
  task automatic pick_priv();
    case ($urandom_range(0, 3))
      0: begin fromCSR_addr_bits_priv = 2'h3; fromCSR_addr_bits_virt = 1'b0; end // M
      1: begin fromCSR_addr_bits_priv = 2'h1; fromCSR_addr_bits_virt = 1'b0; end // S
      2: begin // VS: priv=S, virt=1, vgein∈[1,5]
        fromCSR_addr_bits_priv = 2'h1; fromCSR_addr_bits_virt = 1'b1;
        fromCSR_vgein = 6'($urandom_range(1, 5));
      end
      default: begin // 随机 (覆盖非法路径)
        fromCSR_addr_bits_priv = 2'($urandom);
        fromCSR_addr_bits_virt = $urandom_range(0,1);
        fromCSR_vgein = 6'($urandom_range(0, 7));
      end
    endcase
  endtask

  task automatic drive_random_inputs();
    pick_priv();
    fromCSR_addr_valid      = $urandom_range(0, 1);
    fromCSR_addr_bits_addr  = 12'($urandom);
    fromCSR_wdata_valid     = $urandom_range(0, 1);
    fromCSR_wdata_bits_op   = 2'($urandom);
    fromCSR_wdata_bits_data = {$urandom, $urandom};
    fromCSR_claims_0        = $urandom_range(0, 1);
    fromCSR_claims_1        = $urandom_range(0, 1);
    fromCSR_claims_2        = $urandom_range(0, 1);
    // MSI: vld_req 稀疏翻转 (产生上升沿), data = {文件号[10:8], 源号[7:0]}
    if ($urandom_range(0, 2) == 0) msiio_vld_req = ~msiio_vld_req;
    msiio_data = {3'($urandom_range(0, 6)), 8'($urandom)};
  endtask

  task automatic check_outputs();
    `CHECK(toCSR_rdata_valid)
    `CHECK(toCSR_rdata_bits)
    `CHECK(toCSR_illegal)
    `CHECK(toCSR_pendings)
    `CHECK(toCSR_topeis_0)
    `CHECK(toCSR_topeis_1)
    `CHECK(toCSR_topeis_2)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    fromCSR_addr_valid = '0;
    fromCSR_addr_bits_addr = '0;
    fromCSR_addr_bits_virt = '0;
    fromCSR_addr_bits_priv = '0;
    fromCSR_vgein = '0;
    fromCSR_wdata_valid = '0;
    fromCSR_wdata_bits_op = '0;
    fromCSR_wdata_bits_data = '0;
    fromCSR_claims_0 = '0;
    fromCSR_claims_1 = '0;
    fromCSR_claims_2 = '0;
    msiio_vld_req = '0;
    msiio_data = '0;
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("IMSIC checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
