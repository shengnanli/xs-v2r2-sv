// =============================================================================
// tb —— IMSIC UT：golden IMSIC（含 golden IntFile ×9 / IMSICGateWay / 同步链）与重写件 IMSIC_xs
// （含重写 IntFile_xs / IMSICGateWay_xs，同一份 golden 同步链）双例化，同激励逐拍比全部 10 个输出。
//
// 激励（每拍独立随机）：
//   CSR 侧 addr.valid 50%；{priv,virt} 60% 取三种合法组合（M / S / VS），40% 任意；vgein 60% 在 1..7，
//   其余任意 6 位（含 0 与 >=8 的非法值）；地址 70% 取 10 个合法间接 CSR 号，15% 奇数非法号，15% 任意；
//   wdata.valid 50%，op 均匀 4 种；data 四种形状；claims 各 20%。
//   MSI 侧：msiio_vld_req 按"保持若干拍再翻转"驱动（同步链 3 拍 + 握手需要电平保持），data 12 位随机
//   （文件号字段 [11:8] 覆盖 0..8 及非法值）。
// 复位：前 5 拍 reset=1；复位撤销后前 2 拍不比对（无复位的打拍寄存器尚未被写过）。
// 覆盖（写进 PASS 判据）：9 个文件各自被读命中（rdata_valid 由该文件拉起）、各自收到 MSI 置位、
//   各自 claim 命中（claim 且该文件 topei!=0）；topeis_2 的 7 个 guest 选择各有非 0 输出；illegal=1；
//   每个输出都见过 0/1。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  longint errors = 0, checks = 0;
  int cyc;
  bit clock = 0;
  bit reset = 1;
  always #5 clock = ~clock;

  logic        addr_valid, addr_virt, wdata_valid, claims_0, claims_1, claims_2, msiio_vld_req;
  logic [11:0] addr, msiio_data;
  logic [1:0]  addr_priv, wdata_op;
  logic [5:0]  vgein;
  logic [63:0] wdata_data;
  logic        g_rdata_valid, i_rdata_valid, g_illegal, i_illegal, g_ack, i_ack;
  logic [63:0] g_rdata, i_rdata;
  logic [8:0]  g_pendings, i_pendings;
  logic [31:0] g_topeis_0, i_topeis_0, g_topeis_1, i_topeis_1, g_topeis_2, i_topeis_2;

  `define INST(MOD, INST, P) \
    MOD INST ( \
      .clock(clock), .reset(reset), \
      .toCSR_rdata_valid(P``rdata_valid), .toCSR_rdata_bits(P``rdata), .toCSR_illegal(P``illegal), \
      .toCSR_pendings(P``pendings), .toCSR_topeis_0(P``topeis_0), .toCSR_topeis_1(P``topeis_1), \
      .toCSR_topeis_2(P``topeis_2), \
      .fromCSR_addr_valid(addr_valid), .fromCSR_addr_bits_addr(addr), .fromCSR_addr_bits_virt(addr_virt), \
      .fromCSR_addr_bits_priv(addr_priv), .fromCSR_vgein(vgein), .fromCSR_wdata_valid(wdata_valid), \
      .fromCSR_wdata_bits_op(wdata_op), .fromCSR_wdata_bits_data(wdata_data), \
      .fromCSR_claims_0(claims_0), .fromCSR_claims_1(claims_1), .fromCSR_claims_2(claims_2), \
      .msiio_vld_req(msiio_vld_req), .msiio_data(msiio_data), .msiio_vld_ack(P``ack));
  `INST(IMSIC, u_g, g_)
  `INST(IMSIC_xs, u_i, i_)

  localparam int NADDR = 10;
  logic [11:0] ADDRS [NADDR] = '{12'h070, 12'h072, 12'h080, 12'h082, 12'h084, 12'h086,
                                 12'h0C0, 12'h0C2, 12'h0C4, 12'h0C6};
  int cov_read [9], cov_msi [9], cov_claim [9], cov_guest_topei [7];
  int cov_illegal;
  bit seen0 [10], seen1 [10];
  int hold;

  `define CMP(k, g, i, nm) \
    begin checks++; if ((g) !== (i)) begin errors++; \
      if (errors <= 30) $display("[%0d] MISMATCH %s golden=%h impl=%h", cyc, nm, (g), (i)); end \
      if (|(g)) seen1[k] = 1; if (!(&(g))) seen0[k] = 1; end

  function automatic logic [63:0] shape64();
    logic [63:0] x;
    x = {$urandom, $urandom};
    case ($urandom_range(0, 3))
      0: return x;
      1: return x & {$urandom, $urandom} & {$urandom, $urandom};
      2: return '1;
      default: return 64'($urandom_range(0, 300));
    endcase
  endfunction

  task automatic drive();
    addr_valid = $urandom_range(0, 1);
    case ($urandom_range(0, 9))
      0, 1:    {addr_priv, addr_virt} = {2'd3, 1'b0};     // M
      2, 3:    {addr_priv, addr_virt} = {2'd1, 1'b0};     // S
      4, 5:    {addr_priv, addr_virt} = {2'd1, 1'b1};     // VS
      default: {addr_priv, addr_virt} = 3'($urandom);
    endcase
    vgein = ($urandom_range(0, 4) < 3) ? 6'($urandom_range(1, 7)) : 6'($urandom);
    case ($urandom_range(0, 19))
      0, 1, 2:  addr = 12'h080 + 12'($urandom_range(0, 127)) * 2 + 12'd1;
      3, 4, 5:  addr = $urandom;
      default:  addr = ADDRS[$urandom_range(0, NADDR - 1)];
    endcase
    wdata_valid = $urandom_range(0, 1);
    wdata_op    = $urandom;
    wdata_data  = shape64();
    claims_0 = ($urandom_range(0, 4) == 0);
    claims_1 = ($urandom_range(0, 4) == 0);
    claims_2 = ($urandom_range(0, 4) == 0);
    if (hold == 0) begin
      msiio_vld_req = ~msiio_vld_req;
      hold = $urandom_range(1, 12);
      if (msiio_vld_req) msiio_data = ($urandom_range(0, 9) == 0) ? 12'($urandom) : {4'($urandom_range(0, 8)), 8'($urandom)};
    end else hold--;
  endtask

  initial begin
    int bad;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    hold = 0; msiio_vld_req = 0; msiio_data = 0;
    drive();
    repeat (5) @(posedge clock);
    #1 reset = 0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clock);
      drive();
      #1;
      if (cyc >= 2) begin
        `CMP(0, g_rdata_valid, i_rdata_valid, "rdata_valid")
        `CMP(1, g_rdata, i_rdata, "rdata")
        `CMP(2, g_illegal, i_illegal, "illegal")
        `CMP(3, g_pendings, i_pendings, "pendings")
        `CMP(4, g_topeis_0, i_topeis_0, "topeis_0")
        `CMP(5, g_topeis_1, i_topeis_1, "topeis_1")
        `CMP(6, g_topeis_2, i_topeis_2, "topeis_2")
        `CMP(7, g_ack, i_ack, "msiio_vld_ack")
        `CMP(8, g_pendings[0], i_pendings[0], "pendings0")
        `CMP(9, g_pendings[8], i_pendings[8], "pendings8")
      end
      // 覆盖：从 golden 内部观测各文件的输入（只读探针，不改变行为）
      if (u_g.intFile.fromCSR_addr_valid)   cov_read[0]++;
      if (u_g.intFile_1.fromCSR_addr_valid) cov_read[1]++;
      if (u_g.intFile_2.fromCSR_addr_valid) cov_read[2]++;
      if (u_g.intFile_3.fromCSR_addr_valid) cov_read[3]++;
      if (u_g.intFile_4.fromCSR_addr_valid) cov_read[4]++;
      if (u_g.intFile_5.fromCSR_addr_valid) cov_read[5]++;
      if (u_g.intFile_6.fromCSR_addr_valid) cov_read[6]++;
      if (u_g.intFile_7.fromCSR_addr_valid) cov_read[7]++;
      if (u_g.intFile_8.fromCSR_addr_valid) cov_read[8]++;
      if (u_g.intFile.fromCSR_seteipnum_valid)   cov_msi[0]++;
      if (u_g.intFile_1.fromCSR_seteipnum_valid) cov_msi[1]++;
      if (u_g.intFile_2.fromCSR_seteipnum_valid) cov_msi[2]++;
      if (u_g.intFile_3.fromCSR_seteipnum_valid) cov_msi[3]++;
      if (u_g.intFile_4.fromCSR_seteipnum_valid) cov_msi[4]++;
      if (u_g.intFile_5.fromCSR_seteipnum_valid) cov_msi[5]++;
      if (u_g.intFile_6.fromCSR_seteipnum_valid) cov_msi[6]++;
      if (u_g.intFile_7.fromCSR_seteipnum_valid) cov_msi[7]++;
      if (u_g.intFile_8.fromCSR_seteipnum_valid) cov_msi[8]++;
      if (u_g.intFile.fromCSR_claim   && u_g.intFile.toCSR_topei   != 0) cov_claim[0]++;
      if (u_g.intFile_1.fromCSR_claim && u_g.intFile_1.toCSR_topei != 0) cov_claim[1]++;
      if (u_g.intFile_2.fromCSR_claim && u_g.intFile_2.toCSR_topei != 0) cov_claim[2]++;
      if (u_g.intFile_3.fromCSR_claim && u_g.intFile_3.toCSR_topei != 0) cov_claim[3]++;
      if (u_g.intFile_4.fromCSR_claim && u_g.intFile_4.toCSR_topei != 0) cov_claim[4]++;
      if (u_g.intFile_5.fromCSR_claim && u_g.intFile_5.toCSR_topei != 0) cov_claim[5]++;
      if (u_g.intFile_6.fromCSR_claim && u_g.intFile_6.toCSR_topei != 0) cov_claim[6]++;
      if (u_g.intFile_7.fromCSR_claim && u_g.intFile_7.toCSR_topei != 0) cov_claim[7]++;
      if (u_g.intFile_8.fromCSR_claim && u_g.intFile_8.toCSR_topei != 0) cov_claim[8]++;
      if (g_topeis_2[7:0] != 0 && vgein[2:0] != 0) cov_guest_topei[vgein[2:0] - 1]++;
      if (g_illegal) cov_illegal++;
    end
    bad = 0;
    for (int f = 0; f < 9; f++) begin
      $display("cov file=%0d read=%0d msi=%0d claim_hit=%0d", f, cov_read[f], cov_msi[f], cov_claim[f]);
      if (cov_read[f] < NCYCLES / 1000 || cov_msi[f] < NCYCLES / 2000 || cov_claim[f] < NCYCLES / 2000) bad++;
    end
    for (int g = 0; g < 7; g++) begin
      $display("cov guest_topei sel=%0d : %0d", g, cov_guest_topei[g]);
      if (cov_guest_topei[g] < NCYCLES / 1000) bad++;
    end
    $display("cov illegal=%0d", cov_illegal);
    if (cov_illegal < NCYCLES / 1000) bad++;
    for (int o = 0; o < 10; o++) if (!seen0[o] || !seen1[o]) begin bad++; $display("output %0d stuck", o); end
    $display("checks=%0d errors=%0d bad_cov=%0d", checks, errors, bad);
    if (errors == 0 && checks > 1000 && bad == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
