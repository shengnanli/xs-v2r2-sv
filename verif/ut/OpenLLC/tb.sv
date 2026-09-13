// 自动生成：scripts/gen_zj_ut.py OpenLLC —— 勿手改
// OpenLLC 双例化逐拍比对：golden OpenLLC vs 重写 OpenLLC_xs（derive_ut_impl.py 派生）。
// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；
// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。
`timescale 1ns/1ps
module tb;
  // 拍数：默认 120000（>= CONVENTIONS 要求的 10 万），可被 ut_common 下发的
  // +ncycles=<n> 覆盖，这样全工程统一调拍数的开关对本 tb 同样生效。
  int unsigned NCYCLES = 120000;
  localparam int unsigned MIN_TOGGLED = 22;
  localparam int unsigned MIN_FIRES   = 0;
  localparam int unsigned N_OUT       = 29;

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint checks = 0, errors = 0, fires = 0;
  int      toggled = 0;

  // 宽随机：$urandom 一次 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int w);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  logic io_rn_0_txsactive;
  logic io_rn_0_syscoreq;
  logic io_rn_0_tx_linkactivereq;
  logic io_rn_0_tx_req_flitpend;
  logic io_rn_0_tx_req_flitv;
  logic [161:0] io_rn_0_tx_req_flit;
  logic io_rn_0_tx_rsp_flitpend;
  logic io_rn_0_tx_rsp_flitv;
  logic [72:0] io_rn_0_tx_rsp_flit;
  logic io_rn_0_tx_dat_flitpend;
  logic io_rn_0_tx_dat_flitv;
  logic [421:0] io_rn_0_tx_dat_flit;
  logic io_rn_0_rx_linkactiveack;
  logic io_rn_0_rx_rsp_lcrdv;
  logic io_rn_0_rx_dat_lcrdv;
  logic io_rn_0_rx_snp_lcrdv;
  logic io_sn_rxsactive;
  logic io_sn_tx_linkactiveack;
  logic io_sn_tx_req_lcrdv;
  logic io_sn_tx_dat_lcrdv;
  logic io_sn_rx_linkactivereq;
  logic io_sn_rx_rsp_flitpend;
  logic io_sn_rx_rsp_flitv;
  logic [72:0] io_sn_rx_rsp_flit;
  logic io_sn_rx_dat_flitpend;
  logic io_sn_rx_dat_flitv;
  logic [421:0] io_sn_rx_dat_flit;
  logic io_debugTopDown_robHeadPaddr_0_valid;
  logic [47:0] io_debugTopDown_robHeadPaddr_0_bits;

  wire g_io_rn_0_rxsactive;
  wire i_io_rn_0_rxsactive;
  wire g_io_rn_0_syscoack;
  wire i_io_rn_0_syscoack;
  wire g_io_rn_0_tx_linkactiveack;
  wire i_io_rn_0_tx_linkactiveack;
  wire g_io_rn_0_tx_req_lcrdv;
  wire i_io_rn_0_tx_req_lcrdv;
  wire g_io_rn_0_tx_rsp_lcrdv;
  wire i_io_rn_0_tx_rsp_lcrdv;
  wire g_io_rn_0_tx_dat_lcrdv;
  wire i_io_rn_0_tx_dat_lcrdv;
  wire g_io_rn_0_rx_linkactivereq;
  wire i_io_rn_0_rx_linkactivereq;
  wire g_io_rn_0_rx_rsp_flitpend;
  wire i_io_rn_0_rx_rsp_flitpend;
  wire g_io_rn_0_rx_rsp_flitv;
  wire i_io_rn_0_rx_rsp_flitv;
  wire [72:0] g_io_rn_0_rx_rsp_flit;
  wire [72:0] i_io_rn_0_rx_rsp_flit;
  wire g_io_rn_0_rx_dat_flitpend;
  wire i_io_rn_0_rx_dat_flitpend;
  wire g_io_rn_0_rx_dat_flitv;
  wire i_io_rn_0_rx_dat_flitv;
  wire [421:0] g_io_rn_0_rx_dat_flit;
  wire [421:0] i_io_rn_0_rx_dat_flit;
  wire g_io_rn_0_rx_snp_flitpend;
  wire i_io_rn_0_rx_snp_flitpend;
  wire g_io_rn_0_rx_snp_flitv;
  wire i_io_rn_0_rx_snp_flitv;
  wire [114:0] g_io_rn_0_rx_snp_flit;
  wire [114:0] i_io_rn_0_rx_snp_flit;
  wire g_io_sn_txsactive;
  wire i_io_sn_txsactive;
  wire g_io_sn_tx_linkactivereq;
  wire i_io_sn_tx_linkactivereq;
  wire g_io_sn_tx_req_flitpend;
  wire i_io_sn_tx_req_flitpend;
  wire g_io_sn_tx_req_flitv;
  wire i_io_sn_tx_req_flitv;
  wire [161:0] g_io_sn_tx_req_flit;
  wire [161:0] i_io_sn_tx_req_flit;
  wire g_io_sn_tx_dat_flitpend;
  wire i_io_sn_tx_dat_flitpend;
  wire g_io_sn_tx_dat_flitv;
  wire i_io_sn_tx_dat_flitv;
  wire [421:0] g_io_sn_tx_dat_flit;
  wire [421:0] i_io_sn_tx_dat_flit;
  wire g_io_sn_rx_linkactiveack;
  wire i_io_sn_rx_linkactiveack;
  wire g_io_sn_rx_rsp_lcrdv;
  wire i_io_sn_rx_rsp_lcrdv;
  wire g_io_sn_rx_dat_lcrdv;
  wire i_io_sn_rx_dat_lcrdv;
  wire g_io_debugTopDown_addrMatch_0;
  wire i_io_debugTopDown_addrMatch_0;
  wire g_io_l3Miss;
  wire i_io_l3Miss;

  logic p_io_rn_0_rxsactive;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rxsactive;
  logic p_io_rn_0_syscoack;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_syscoack;
  logic p_io_rn_0_tx_linkactiveack;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_tx_linkactiveack;
  logic p_io_rn_0_tx_req_lcrdv;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_tx_req_lcrdv;
  logic p_io_rn_0_tx_rsp_lcrdv;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_tx_rsp_lcrdv;
  logic p_io_rn_0_tx_dat_lcrdv;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_tx_dat_lcrdv;
  logic p_io_rn_0_rx_linkactivereq;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_linkactivereq;
  logic p_io_rn_0_rx_rsp_flitpend;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_rsp_flitpend;
  logic p_io_rn_0_rx_rsp_flitv;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_rsp_flitv;
  logic [72:0] p_io_rn_0_rx_rsp_flit;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_rsp_flit;
  logic p_io_rn_0_rx_dat_flitpend;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_dat_flitpend;
  logic p_io_rn_0_rx_dat_flitv;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_dat_flitv;
  logic [421:0] p_io_rn_0_rx_dat_flit;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_dat_flit;
  logic p_io_rn_0_rx_snp_flitpend;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_snp_flitpend;
  logic p_io_rn_0_rx_snp_flitv;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_snp_flitv;
  logic [114:0] p_io_rn_0_rx_snp_flit;   // 上一拍值（toggle 统计）
  bit tog_io_rn_0_rx_snp_flit;
  logic p_io_sn_txsactive;   // 上一拍值（toggle 统计）
  bit tog_io_sn_txsactive;
  logic p_io_sn_tx_linkactivereq;   // 上一拍值（toggle 统计）
  bit tog_io_sn_tx_linkactivereq;
  logic p_io_sn_tx_req_flitpend;   // 上一拍值（toggle 统计）
  bit tog_io_sn_tx_req_flitpend;
  logic p_io_sn_tx_req_flitv;   // 上一拍值（toggle 统计）
  bit tog_io_sn_tx_req_flitv;
  logic [161:0] p_io_sn_tx_req_flit;   // 上一拍值（toggle 统计）
  bit tog_io_sn_tx_req_flit;
  logic p_io_sn_tx_dat_flitpend;   // 上一拍值（toggle 统计）
  bit tog_io_sn_tx_dat_flitpend;
  logic p_io_sn_tx_dat_flitv;   // 上一拍值（toggle 统计）
  bit tog_io_sn_tx_dat_flitv;
  logic [421:0] p_io_sn_tx_dat_flit;   // 上一拍值（toggle 统计）
  bit tog_io_sn_tx_dat_flit;
  logic p_io_sn_rx_linkactiveack;   // 上一拍值（toggle 统计）
  bit tog_io_sn_rx_linkactiveack;
  logic p_io_sn_rx_rsp_lcrdv;   // 上一拍值（toggle 统计）
  bit tog_io_sn_rx_rsp_lcrdv;
  logic p_io_sn_rx_dat_lcrdv;   // 上一拍值（toggle 统计）
  bit tog_io_sn_rx_dat_lcrdv;
  logic p_io_debugTopDown_addrMatch_0;   // 上一拍值（toggle 统计）
  bit tog_io_debugTopDown_addrMatch_0;
  logic p_io_l3Miss;   // 上一拍值（toggle 统计）
  bit tog_io_l3Miss;

  OpenLLC u_g (
    .clock(clock),
    .reset(reset),
    .io_rn_0_txsactive(io_rn_0_txsactive),
    .io_rn_0_rxsactive(g_io_rn_0_rxsactive),
    .io_rn_0_syscoreq(io_rn_0_syscoreq),
    .io_rn_0_syscoack(g_io_rn_0_syscoack),
    .io_rn_0_tx_linkactivereq(io_rn_0_tx_linkactivereq),
    .io_rn_0_tx_linkactiveack(g_io_rn_0_tx_linkactiveack),
    .io_rn_0_tx_req_flitpend(io_rn_0_tx_req_flitpend),
    .io_rn_0_tx_req_flitv(io_rn_0_tx_req_flitv),
    .io_rn_0_tx_req_flit(io_rn_0_tx_req_flit),
    .io_rn_0_tx_req_lcrdv(g_io_rn_0_tx_req_lcrdv),
    .io_rn_0_tx_rsp_flitpend(io_rn_0_tx_rsp_flitpend),
    .io_rn_0_tx_rsp_flitv(io_rn_0_tx_rsp_flitv),
    .io_rn_0_tx_rsp_flit(io_rn_0_tx_rsp_flit),
    .io_rn_0_tx_rsp_lcrdv(g_io_rn_0_tx_rsp_lcrdv),
    .io_rn_0_tx_dat_flitpend(io_rn_0_tx_dat_flitpend),
    .io_rn_0_tx_dat_flitv(io_rn_0_tx_dat_flitv),
    .io_rn_0_tx_dat_flit(io_rn_0_tx_dat_flit),
    .io_rn_0_tx_dat_lcrdv(g_io_rn_0_tx_dat_lcrdv),
    .io_rn_0_rx_linkactivereq(g_io_rn_0_rx_linkactivereq),
    .io_rn_0_rx_linkactiveack(io_rn_0_rx_linkactiveack),
    .io_rn_0_rx_rsp_flitpend(g_io_rn_0_rx_rsp_flitpend),
    .io_rn_0_rx_rsp_flitv(g_io_rn_0_rx_rsp_flitv),
    .io_rn_0_rx_rsp_flit(g_io_rn_0_rx_rsp_flit),
    .io_rn_0_rx_rsp_lcrdv(io_rn_0_rx_rsp_lcrdv),
    .io_rn_0_rx_dat_flitpend(g_io_rn_0_rx_dat_flitpend),
    .io_rn_0_rx_dat_flitv(g_io_rn_0_rx_dat_flitv),
    .io_rn_0_rx_dat_flit(g_io_rn_0_rx_dat_flit),
    .io_rn_0_rx_dat_lcrdv(io_rn_0_rx_dat_lcrdv),
    .io_rn_0_rx_snp_flitpend(g_io_rn_0_rx_snp_flitpend),
    .io_rn_0_rx_snp_flitv(g_io_rn_0_rx_snp_flitv),
    .io_rn_0_rx_snp_flit(g_io_rn_0_rx_snp_flit),
    .io_rn_0_rx_snp_lcrdv(io_rn_0_rx_snp_lcrdv),
    .io_sn_txsactive(g_io_sn_txsactive),
    .io_sn_rxsactive(io_sn_rxsactive),
    .io_sn_tx_linkactivereq(g_io_sn_tx_linkactivereq),
    .io_sn_tx_linkactiveack(io_sn_tx_linkactiveack),
    .io_sn_tx_req_flitpend(g_io_sn_tx_req_flitpend),
    .io_sn_tx_req_flitv(g_io_sn_tx_req_flitv),
    .io_sn_tx_req_flit(g_io_sn_tx_req_flit),
    .io_sn_tx_req_lcrdv(io_sn_tx_req_lcrdv),
    .io_sn_tx_dat_flitpend(g_io_sn_tx_dat_flitpend),
    .io_sn_tx_dat_flitv(g_io_sn_tx_dat_flitv),
    .io_sn_tx_dat_flit(g_io_sn_tx_dat_flit),
    .io_sn_tx_dat_lcrdv(io_sn_tx_dat_lcrdv),
    .io_sn_rx_linkactivereq(io_sn_rx_linkactivereq),
    .io_sn_rx_linkactiveack(g_io_sn_rx_linkactiveack),
    .io_sn_rx_rsp_flitpend(io_sn_rx_rsp_flitpend),
    .io_sn_rx_rsp_flitv(io_sn_rx_rsp_flitv),
    .io_sn_rx_rsp_flit(io_sn_rx_rsp_flit),
    .io_sn_rx_rsp_lcrdv(g_io_sn_rx_rsp_lcrdv),
    .io_sn_rx_dat_flitpend(io_sn_rx_dat_flitpend),
    .io_sn_rx_dat_flitv(io_sn_rx_dat_flitv),
    .io_sn_rx_dat_flit(io_sn_rx_dat_flit),
    .io_sn_rx_dat_lcrdv(g_io_sn_rx_dat_lcrdv),
    .io_debugTopDown_robHeadPaddr_0_valid(io_debugTopDown_robHeadPaddr_0_valid),
    .io_debugTopDown_robHeadPaddr_0_bits(io_debugTopDown_robHeadPaddr_0_bits),
    .io_debugTopDown_addrMatch_0(g_io_debugTopDown_addrMatch_0),
    .io_l3Miss(g_io_l3Miss)
  );
  OpenLLC_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_rn_0_txsactive(io_rn_0_txsactive),
    .io_rn_0_rxsactive(i_io_rn_0_rxsactive),
    .io_rn_0_syscoreq(io_rn_0_syscoreq),
    .io_rn_0_syscoack(i_io_rn_0_syscoack),
    .io_rn_0_tx_linkactivereq(io_rn_0_tx_linkactivereq),
    .io_rn_0_tx_linkactiveack(i_io_rn_0_tx_linkactiveack),
    .io_rn_0_tx_req_flitpend(io_rn_0_tx_req_flitpend),
    .io_rn_0_tx_req_flitv(io_rn_0_tx_req_flitv),
    .io_rn_0_tx_req_flit(io_rn_0_tx_req_flit),
    .io_rn_0_tx_req_lcrdv(i_io_rn_0_tx_req_lcrdv),
    .io_rn_0_tx_rsp_flitpend(io_rn_0_tx_rsp_flitpend),
    .io_rn_0_tx_rsp_flitv(io_rn_0_tx_rsp_flitv),
    .io_rn_0_tx_rsp_flit(io_rn_0_tx_rsp_flit),
    .io_rn_0_tx_rsp_lcrdv(i_io_rn_0_tx_rsp_lcrdv),
    .io_rn_0_tx_dat_flitpend(io_rn_0_tx_dat_flitpend),
    .io_rn_0_tx_dat_flitv(io_rn_0_tx_dat_flitv),
    .io_rn_0_tx_dat_flit(io_rn_0_tx_dat_flit),
    .io_rn_0_tx_dat_lcrdv(i_io_rn_0_tx_dat_lcrdv),
    .io_rn_0_rx_linkactivereq(i_io_rn_0_rx_linkactivereq),
    .io_rn_0_rx_linkactiveack(io_rn_0_rx_linkactiveack),
    .io_rn_0_rx_rsp_flitpend(i_io_rn_0_rx_rsp_flitpend),
    .io_rn_0_rx_rsp_flitv(i_io_rn_0_rx_rsp_flitv),
    .io_rn_0_rx_rsp_flit(i_io_rn_0_rx_rsp_flit),
    .io_rn_0_rx_rsp_lcrdv(io_rn_0_rx_rsp_lcrdv),
    .io_rn_0_rx_dat_flitpend(i_io_rn_0_rx_dat_flitpend),
    .io_rn_0_rx_dat_flitv(i_io_rn_0_rx_dat_flitv),
    .io_rn_0_rx_dat_flit(i_io_rn_0_rx_dat_flit),
    .io_rn_0_rx_dat_lcrdv(io_rn_0_rx_dat_lcrdv),
    .io_rn_0_rx_snp_flitpend(i_io_rn_0_rx_snp_flitpend),
    .io_rn_0_rx_snp_flitv(i_io_rn_0_rx_snp_flitv),
    .io_rn_0_rx_snp_flit(i_io_rn_0_rx_snp_flit),
    .io_rn_0_rx_snp_lcrdv(io_rn_0_rx_snp_lcrdv),
    .io_sn_txsactive(i_io_sn_txsactive),
    .io_sn_rxsactive(io_sn_rxsactive),
    .io_sn_tx_linkactivereq(i_io_sn_tx_linkactivereq),
    .io_sn_tx_linkactiveack(io_sn_tx_linkactiveack),
    .io_sn_tx_req_flitpend(i_io_sn_tx_req_flitpend),
    .io_sn_tx_req_flitv(i_io_sn_tx_req_flitv),
    .io_sn_tx_req_flit(i_io_sn_tx_req_flit),
    .io_sn_tx_req_lcrdv(io_sn_tx_req_lcrdv),
    .io_sn_tx_dat_flitpend(i_io_sn_tx_dat_flitpend),
    .io_sn_tx_dat_flitv(i_io_sn_tx_dat_flitv),
    .io_sn_tx_dat_flit(i_io_sn_tx_dat_flit),
    .io_sn_tx_dat_lcrdv(io_sn_tx_dat_lcrdv),
    .io_sn_rx_linkactivereq(io_sn_rx_linkactivereq),
    .io_sn_rx_linkactiveack(i_io_sn_rx_linkactiveack),
    .io_sn_rx_rsp_flitpend(io_sn_rx_rsp_flitpend),
    .io_sn_rx_rsp_flitv(io_sn_rx_rsp_flitv),
    .io_sn_rx_rsp_flit(io_sn_rx_rsp_flit),
    .io_sn_rx_rsp_lcrdv(i_io_sn_rx_rsp_lcrdv),
    .io_sn_rx_dat_flitpend(io_sn_rx_dat_flitpend),
    .io_sn_rx_dat_flitv(io_sn_rx_dat_flitv),
    .io_sn_rx_dat_flit(io_sn_rx_dat_flit),
    .io_sn_rx_dat_lcrdv(i_io_sn_rx_dat_lcrdv),
    .io_debugTopDown_robHeadPaddr_0_valid(io_debugTopDown_robHeadPaddr_0_valid),
    .io_debugTopDown_robHeadPaddr_0_bits(io_debugTopDown_robHeadPaddr_0_bits),
    .io_debugTopDown_addrMatch_0(i_io_debugTopDown_addrMatch_0),
    .io_l3Miss(i_io_l3Miss)
  );

  task automatic drive_random();
    io_rn_0_txsactive = 1'b1;   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_rn_0_syscoreq = 1'b1;   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_rn_0_tx_linkactivereq = 1'b1;   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_rn_0_tx_req_flitpend = $urandom % 2;
    io_rn_0_tx_req_flitv = $urandom % 2;
    io_rn_0_tx_req_flit = rnd(162);
    io_rn_0_tx_rsp_flitpend = $urandom % 2;
    io_rn_0_tx_rsp_flitv = $urandom % 2;
    io_rn_0_tx_rsp_flit = rnd(73);
    io_rn_0_tx_dat_flitpend = $urandom % 2;
    io_rn_0_tx_dat_flitv = $urandom % 2;
    io_rn_0_tx_dat_flit = rnd(422);
    io_rn_0_rx_linkactiveack = 1'b1;   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_rn_0_rx_rsp_lcrdv = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_rn_0_rx_dat_lcrdv = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_rn_0_rx_snp_lcrdv = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_sn_rxsactive = 1'b1;   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_sn_tx_linkactiveack = 1'b1;   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_sn_tx_req_lcrdv = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_sn_tx_dat_lcrdv = (($urandom % 4) != 0);            // 75% 高：制造反压
    io_sn_rx_linkactivereq = 1'b1;   // 域收窄：让"必须相等/必须全 1"的路径有非零概率
    io_sn_rx_rsp_flitpend = $urandom % 2;
    io_sn_rx_rsp_flitv = $urandom % 2;
    io_sn_rx_rsp_flit = rnd(73);
    io_sn_rx_dat_flitpend = $urandom % 2;
    io_sn_rx_dat_flitv = $urandom % 2;
    io_sn_rx_dat_flit = rnd(422);
    io_debugTopDown_robHeadPaddr_0_valid = $urandom % 2;
    io_debugTopDown_robHeadPaddr_0_bits = rnd(48);
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_io_rn_0_rxsactive)) begin
      checks++;
      if (g_io_rn_0_rxsactive !== i_io_rn_0_rxsactive) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rxsactive g=%0h i=%0h", $time, g_io_rn_0_rxsactive, i_io_rn_0_rxsactive);
      end
    end
    if (!$isunknown(g_io_rn_0_syscoack)) begin
      checks++;
      if (g_io_rn_0_syscoack !== i_io_rn_0_syscoack) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_syscoack g=%0h i=%0h", $time, g_io_rn_0_syscoack, i_io_rn_0_syscoack);
      end
    end
    if (!$isunknown(g_io_rn_0_tx_linkactiveack)) begin
      checks++;
      if (g_io_rn_0_tx_linkactiveack !== i_io_rn_0_tx_linkactiveack) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_tx_linkactiveack g=%0h i=%0h", $time, g_io_rn_0_tx_linkactiveack, i_io_rn_0_tx_linkactiveack);
      end
    end
    if (!$isunknown(g_io_rn_0_tx_req_lcrdv)) begin
      checks++;
      if (g_io_rn_0_tx_req_lcrdv !== i_io_rn_0_tx_req_lcrdv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_tx_req_lcrdv g=%0h i=%0h", $time, g_io_rn_0_tx_req_lcrdv, i_io_rn_0_tx_req_lcrdv);
      end
    end
    if (!$isunknown(g_io_rn_0_tx_rsp_lcrdv)) begin
      checks++;
      if (g_io_rn_0_tx_rsp_lcrdv !== i_io_rn_0_tx_rsp_lcrdv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_tx_rsp_lcrdv g=%0h i=%0h", $time, g_io_rn_0_tx_rsp_lcrdv, i_io_rn_0_tx_rsp_lcrdv);
      end
    end
    if (!$isunknown(g_io_rn_0_tx_dat_lcrdv)) begin
      checks++;
      if (g_io_rn_0_tx_dat_lcrdv !== i_io_rn_0_tx_dat_lcrdv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_tx_dat_lcrdv g=%0h i=%0h", $time, g_io_rn_0_tx_dat_lcrdv, i_io_rn_0_tx_dat_lcrdv);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_linkactivereq)) begin
      checks++;
      if (g_io_rn_0_rx_linkactivereq !== i_io_rn_0_rx_linkactivereq) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_linkactivereq g=%0h i=%0h", $time, g_io_rn_0_rx_linkactivereq, i_io_rn_0_rx_linkactivereq);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_rsp_flitpend)) begin
      checks++;
      if (g_io_rn_0_rx_rsp_flitpend !== i_io_rn_0_rx_rsp_flitpend) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_rsp_flitpend g=%0h i=%0h", $time, g_io_rn_0_rx_rsp_flitpend, i_io_rn_0_rx_rsp_flitpend);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_rsp_flitv)) begin
      checks++;
      if (g_io_rn_0_rx_rsp_flitv !== i_io_rn_0_rx_rsp_flitv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_rsp_flitv g=%0h i=%0h", $time, g_io_rn_0_rx_rsp_flitv, i_io_rn_0_rx_rsp_flitv);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_rsp_flit)) begin
      checks++;
      if (g_io_rn_0_rx_rsp_flit !== i_io_rn_0_rx_rsp_flit) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_rsp_flit g=%0h i=%0h", $time, g_io_rn_0_rx_rsp_flit, i_io_rn_0_rx_rsp_flit);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_dat_flitpend)) begin
      checks++;
      if (g_io_rn_0_rx_dat_flitpend !== i_io_rn_0_rx_dat_flitpend) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_dat_flitpend g=%0h i=%0h", $time, g_io_rn_0_rx_dat_flitpend, i_io_rn_0_rx_dat_flitpend);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_dat_flitv)) begin
      checks++;
      if (g_io_rn_0_rx_dat_flitv !== i_io_rn_0_rx_dat_flitv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_dat_flitv g=%0h i=%0h", $time, g_io_rn_0_rx_dat_flitv, i_io_rn_0_rx_dat_flitv);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_dat_flit)) begin
      checks++;
      if (g_io_rn_0_rx_dat_flit !== i_io_rn_0_rx_dat_flit) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_dat_flit g=%0h i=%0h", $time, g_io_rn_0_rx_dat_flit, i_io_rn_0_rx_dat_flit);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_snp_flitpend)) begin
      checks++;
      if (g_io_rn_0_rx_snp_flitpend !== i_io_rn_0_rx_snp_flitpend) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_snp_flitpend g=%0h i=%0h", $time, g_io_rn_0_rx_snp_flitpend, i_io_rn_0_rx_snp_flitpend);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_snp_flitv)) begin
      checks++;
      if (g_io_rn_0_rx_snp_flitv !== i_io_rn_0_rx_snp_flitv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_snp_flitv g=%0h i=%0h", $time, g_io_rn_0_rx_snp_flitv, i_io_rn_0_rx_snp_flitv);
      end
    end
    if (!$isunknown(g_io_rn_0_rx_snp_flit)) begin
      checks++;
      if (g_io_rn_0_rx_snp_flit !== i_io_rn_0_rx_snp_flit) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_rn_0_rx_snp_flit g=%0h i=%0h", $time, g_io_rn_0_rx_snp_flit, i_io_rn_0_rx_snp_flit);
      end
    end
    if (!$isunknown(g_io_sn_txsactive)) begin
      checks++;
      if (g_io_sn_txsactive !== i_io_sn_txsactive) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_txsactive g=%0h i=%0h", $time, g_io_sn_txsactive, i_io_sn_txsactive);
      end
    end
    if (!$isunknown(g_io_sn_tx_linkactivereq)) begin
      checks++;
      if (g_io_sn_tx_linkactivereq !== i_io_sn_tx_linkactivereq) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_tx_linkactivereq g=%0h i=%0h", $time, g_io_sn_tx_linkactivereq, i_io_sn_tx_linkactivereq);
      end
    end
    if (!$isunknown(g_io_sn_tx_req_flitpend)) begin
      checks++;
      if (g_io_sn_tx_req_flitpend !== i_io_sn_tx_req_flitpend) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_tx_req_flitpend g=%0h i=%0h", $time, g_io_sn_tx_req_flitpend, i_io_sn_tx_req_flitpend);
      end
    end
    if (!$isunknown(g_io_sn_tx_req_flitv)) begin
      checks++;
      if (g_io_sn_tx_req_flitv !== i_io_sn_tx_req_flitv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_tx_req_flitv g=%0h i=%0h", $time, g_io_sn_tx_req_flitv, i_io_sn_tx_req_flitv);
      end
    end
    if (!$isunknown(g_io_sn_tx_req_flit)) begin
      checks++;
      if (g_io_sn_tx_req_flit !== i_io_sn_tx_req_flit) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_tx_req_flit g=%0h i=%0h", $time, g_io_sn_tx_req_flit, i_io_sn_tx_req_flit);
      end
    end
    if (!$isunknown(g_io_sn_tx_dat_flitpend)) begin
      checks++;
      if (g_io_sn_tx_dat_flitpend !== i_io_sn_tx_dat_flitpend) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_tx_dat_flitpend g=%0h i=%0h", $time, g_io_sn_tx_dat_flitpend, i_io_sn_tx_dat_flitpend);
      end
    end
    if (!$isunknown(g_io_sn_tx_dat_flitv)) begin
      checks++;
      if (g_io_sn_tx_dat_flitv !== i_io_sn_tx_dat_flitv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_tx_dat_flitv g=%0h i=%0h", $time, g_io_sn_tx_dat_flitv, i_io_sn_tx_dat_flitv);
      end
    end
    if (!$isunknown(g_io_sn_tx_dat_flit)) begin
      checks++;
      if (g_io_sn_tx_dat_flit !== i_io_sn_tx_dat_flit) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_tx_dat_flit g=%0h i=%0h", $time, g_io_sn_tx_dat_flit, i_io_sn_tx_dat_flit);
      end
    end
    if (!$isunknown(g_io_sn_rx_linkactiveack)) begin
      checks++;
      if (g_io_sn_rx_linkactiveack !== i_io_sn_rx_linkactiveack) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_rx_linkactiveack g=%0h i=%0h", $time, g_io_sn_rx_linkactiveack, i_io_sn_rx_linkactiveack);
      end
    end
    if (!$isunknown(g_io_sn_rx_rsp_lcrdv)) begin
      checks++;
      if (g_io_sn_rx_rsp_lcrdv !== i_io_sn_rx_rsp_lcrdv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_rx_rsp_lcrdv g=%0h i=%0h", $time, g_io_sn_rx_rsp_lcrdv, i_io_sn_rx_rsp_lcrdv);
      end
    end
    if (!$isunknown(g_io_sn_rx_dat_lcrdv)) begin
      checks++;
      if (g_io_sn_rx_dat_lcrdv !== i_io_sn_rx_dat_lcrdv) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_sn_rx_dat_lcrdv g=%0h i=%0h", $time, g_io_sn_rx_dat_lcrdv, i_io_sn_rx_dat_lcrdv);
      end
    end
    if (!$isunknown(g_io_debugTopDown_addrMatch_0)) begin
      checks++;
      if (g_io_debugTopDown_addrMatch_0 !== i_io_debugTopDown_addrMatch_0) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_debugTopDown_addrMatch_0 g=%0h i=%0h", $time, g_io_debugTopDown_addrMatch_0, i_io_debugTopDown_addrMatch_0);
      end
    end
    if (!$isunknown(g_io_l3Miss)) begin
      checks++;
      if (g_io_l3Miss !== i_io_l3Miss) begin
        errors++;
        if (errors <= 30) $display("[%0t] MISMATCH io_l3Miss g=%0h i=%0h", $time, g_io_l3Miss, i_io_l3Miss);
      end
    end
  endtask

  task automatic sample_coverage();
    if (g_io_rn_0_rxsactive !== p_io_rn_0_rxsactive) tog_io_rn_0_rxsactive = 1'b1;
    p_io_rn_0_rxsactive = g_io_rn_0_rxsactive;
    if (g_io_rn_0_syscoack !== p_io_rn_0_syscoack) tog_io_rn_0_syscoack = 1'b1;
    p_io_rn_0_syscoack = g_io_rn_0_syscoack;
    if (g_io_rn_0_tx_linkactiveack !== p_io_rn_0_tx_linkactiveack) tog_io_rn_0_tx_linkactiveack = 1'b1;
    p_io_rn_0_tx_linkactiveack = g_io_rn_0_tx_linkactiveack;
    if (g_io_rn_0_tx_req_lcrdv !== p_io_rn_0_tx_req_lcrdv) tog_io_rn_0_tx_req_lcrdv = 1'b1;
    p_io_rn_0_tx_req_lcrdv = g_io_rn_0_tx_req_lcrdv;
    if (g_io_rn_0_tx_rsp_lcrdv !== p_io_rn_0_tx_rsp_lcrdv) tog_io_rn_0_tx_rsp_lcrdv = 1'b1;
    p_io_rn_0_tx_rsp_lcrdv = g_io_rn_0_tx_rsp_lcrdv;
    if (g_io_rn_0_tx_dat_lcrdv !== p_io_rn_0_tx_dat_lcrdv) tog_io_rn_0_tx_dat_lcrdv = 1'b1;
    p_io_rn_0_tx_dat_lcrdv = g_io_rn_0_tx_dat_lcrdv;
    if (g_io_rn_0_rx_linkactivereq !== p_io_rn_0_rx_linkactivereq) tog_io_rn_0_rx_linkactivereq = 1'b1;
    p_io_rn_0_rx_linkactivereq = g_io_rn_0_rx_linkactivereq;
    if (g_io_rn_0_rx_rsp_flitpend !== p_io_rn_0_rx_rsp_flitpend) tog_io_rn_0_rx_rsp_flitpend = 1'b1;
    p_io_rn_0_rx_rsp_flitpend = g_io_rn_0_rx_rsp_flitpend;
    if (g_io_rn_0_rx_rsp_flitv !== p_io_rn_0_rx_rsp_flitv) tog_io_rn_0_rx_rsp_flitv = 1'b1;
    p_io_rn_0_rx_rsp_flitv = g_io_rn_0_rx_rsp_flitv;
    if (g_io_rn_0_rx_rsp_flit !== p_io_rn_0_rx_rsp_flit) tog_io_rn_0_rx_rsp_flit = 1'b1;
    p_io_rn_0_rx_rsp_flit = g_io_rn_0_rx_rsp_flit;
    if (g_io_rn_0_rx_dat_flitpend !== p_io_rn_0_rx_dat_flitpend) tog_io_rn_0_rx_dat_flitpend = 1'b1;
    p_io_rn_0_rx_dat_flitpend = g_io_rn_0_rx_dat_flitpend;
    if (g_io_rn_0_rx_dat_flitv !== p_io_rn_0_rx_dat_flitv) tog_io_rn_0_rx_dat_flitv = 1'b1;
    p_io_rn_0_rx_dat_flitv = g_io_rn_0_rx_dat_flitv;
    if (g_io_rn_0_rx_dat_flit !== p_io_rn_0_rx_dat_flit) tog_io_rn_0_rx_dat_flit = 1'b1;
    p_io_rn_0_rx_dat_flit = g_io_rn_0_rx_dat_flit;
    if (g_io_rn_0_rx_snp_flitpend !== p_io_rn_0_rx_snp_flitpend) tog_io_rn_0_rx_snp_flitpend = 1'b1;
    p_io_rn_0_rx_snp_flitpend = g_io_rn_0_rx_snp_flitpend;
    if (g_io_rn_0_rx_snp_flitv !== p_io_rn_0_rx_snp_flitv) tog_io_rn_0_rx_snp_flitv = 1'b1;
    p_io_rn_0_rx_snp_flitv = g_io_rn_0_rx_snp_flitv;
    if (g_io_rn_0_rx_snp_flit !== p_io_rn_0_rx_snp_flit) tog_io_rn_0_rx_snp_flit = 1'b1;
    p_io_rn_0_rx_snp_flit = g_io_rn_0_rx_snp_flit;
    if (g_io_sn_txsactive !== p_io_sn_txsactive) tog_io_sn_txsactive = 1'b1;
    p_io_sn_txsactive = g_io_sn_txsactive;
    if (g_io_sn_tx_linkactivereq !== p_io_sn_tx_linkactivereq) tog_io_sn_tx_linkactivereq = 1'b1;
    p_io_sn_tx_linkactivereq = g_io_sn_tx_linkactivereq;
    if (g_io_sn_tx_req_flitpend !== p_io_sn_tx_req_flitpend) tog_io_sn_tx_req_flitpend = 1'b1;
    p_io_sn_tx_req_flitpend = g_io_sn_tx_req_flitpend;
    if (g_io_sn_tx_req_flitv !== p_io_sn_tx_req_flitv) tog_io_sn_tx_req_flitv = 1'b1;
    p_io_sn_tx_req_flitv = g_io_sn_tx_req_flitv;
    if (g_io_sn_tx_req_flit !== p_io_sn_tx_req_flit) tog_io_sn_tx_req_flit = 1'b1;
    p_io_sn_tx_req_flit = g_io_sn_tx_req_flit;
    if (g_io_sn_tx_dat_flitpend !== p_io_sn_tx_dat_flitpend) tog_io_sn_tx_dat_flitpend = 1'b1;
    p_io_sn_tx_dat_flitpend = g_io_sn_tx_dat_flitpend;
    if (g_io_sn_tx_dat_flitv !== p_io_sn_tx_dat_flitv) tog_io_sn_tx_dat_flitv = 1'b1;
    p_io_sn_tx_dat_flitv = g_io_sn_tx_dat_flitv;
    if (g_io_sn_tx_dat_flit !== p_io_sn_tx_dat_flit) tog_io_sn_tx_dat_flit = 1'b1;
    p_io_sn_tx_dat_flit = g_io_sn_tx_dat_flit;
    if (g_io_sn_rx_linkactiveack !== p_io_sn_rx_linkactiveack) tog_io_sn_rx_linkactiveack = 1'b1;
    p_io_sn_rx_linkactiveack = g_io_sn_rx_linkactiveack;
    if (g_io_sn_rx_rsp_lcrdv !== p_io_sn_rx_rsp_lcrdv) tog_io_sn_rx_rsp_lcrdv = 1'b1;
    p_io_sn_rx_rsp_lcrdv = g_io_sn_rx_rsp_lcrdv;
    if (g_io_sn_rx_dat_lcrdv !== p_io_sn_rx_dat_lcrdv) tog_io_sn_rx_dat_lcrdv = 1'b1;
    p_io_sn_rx_dat_lcrdv = g_io_sn_rx_dat_lcrdv;
    if (g_io_debugTopDown_addrMatch_0 !== p_io_debugTopDown_addrMatch_0) tog_io_debugTopDown_addrMatch_0 = 1'b1;
    p_io_debugTopDown_addrMatch_0 = g_io_debugTopDown_addrMatch_0;
    if (g_io_l3Miss !== p_io_l3Miss) tog_io_l3Miss = 1'b1;
    p_io_l3Miss = g_io_l3Miss;
  endtask

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    io_rn_0_txsactive = '0;
    io_rn_0_syscoreq = '0;
    io_rn_0_tx_linkactivereq = '0;
    io_rn_0_tx_req_flitpend = '0;
    io_rn_0_tx_req_flitv = '0;
    io_rn_0_tx_req_flit = '0;
    io_rn_0_tx_rsp_flitpend = '0;
    io_rn_0_tx_rsp_flitv = '0;
    io_rn_0_tx_rsp_flit = '0;
    io_rn_0_tx_dat_flitpend = '0;
    io_rn_0_tx_dat_flitv = '0;
    io_rn_0_tx_dat_flit = '0;
    io_rn_0_rx_linkactiveack = '0;
    io_rn_0_rx_rsp_lcrdv = '0;
    io_rn_0_rx_dat_lcrdv = '0;
    io_rn_0_rx_snp_lcrdv = '0;
    io_sn_rxsactive = '0;
    io_sn_tx_linkactiveack = '0;
    io_sn_tx_req_lcrdv = '0;
    io_sn_tx_dat_lcrdv = '0;
    io_sn_rx_linkactivereq = '0;
    io_sn_rx_rsp_flitpend = '0;
    io_sn_rx_rsp_flitv = '0;
    io_sn_rx_rsp_flit = '0;
    io_sn_rx_dat_flitpend = '0;
    io_sn_rx_dat_flitv = '0;
    io_sn_rx_dat_flit = '0;
    io_debugTopDown_robHeadPaddr_0_valid = '0;
    io_debugTopDown_robHeadPaddr_0_bits = '0;
    p_io_rn_0_rxsactive = '0; tog_io_rn_0_rxsactive = 1'b0;
    p_io_rn_0_syscoack = '0; tog_io_rn_0_syscoack = 1'b0;
    p_io_rn_0_tx_linkactiveack = '0; tog_io_rn_0_tx_linkactiveack = 1'b0;
    p_io_rn_0_tx_req_lcrdv = '0; tog_io_rn_0_tx_req_lcrdv = 1'b0;
    p_io_rn_0_tx_rsp_lcrdv = '0; tog_io_rn_0_tx_rsp_lcrdv = 1'b0;
    p_io_rn_0_tx_dat_lcrdv = '0; tog_io_rn_0_tx_dat_lcrdv = 1'b0;
    p_io_rn_0_rx_linkactivereq = '0; tog_io_rn_0_rx_linkactivereq = 1'b0;
    p_io_rn_0_rx_rsp_flitpend = '0; tog_io_rn_0_rx_rsp_flitpend = 1'b0;
    p_io_rn_0_rx_rsp_flitv = '0; tog_io_rn_0_rx_rsp_flitv = 1'b0;
    p_io_rn_0_rx_rsp_flit = '0; tog_io_rn_0_rx_rsp_flit = 1'b0;
    p_io_rn_0_rx_dat_flitpend = '0; tog_io_rn_0_rx_dat_flitpend = 1'b0;
    p_io_rn_0_rx_dat_flitv = '0; tog_io_rn_0_rx_dat_flitv = 1'b0;
    p_io_rn_0_rx_dat_flit = '0; tog_io_rn_0_rx_dat_flit = 1'b0;
    p_io_rn_0_rx_snp_flitpend = '0; tog_io_rn_0_rx_snp_flitpend = 1'b0;
    p_io_rn_0_rx_snp_flitv = '0; tog_io_rn_0_rx_snp_flitv = 1'b0;
    p_io_rn_0_rx_snp_flit = '0; tog_io_rn_0_rx_snp_flit = 1'b0;
    p_io_sn_txsactive = '0; tog_io_sn_txsactive = 1'b0;
    p_io_sn_tx_linkactivereq = '0; tog_io_sn_tx_linkactivereq = 1'b0;
    p_io_sn_tx_req_flitpend = '0; tog_io_sn_tx_req_flitpend = 1'b0;
    p_io_sn_tx_req_flitv = '0; tog_io_sn_tx_req_flitv = 1'b0;
    p_io_sn_tx_req_flit = '0; tog_io_sn_tx_req_flit = 1'b0;
    p_io_sn_tx_dat_flitpend = '0; tog_io_sn_tx_dat_flitpend = 1'b0;
    p_io_sn_tx_dat_flitv = '0; tog_io_sn_tx_dat_flitv = 1'b0;
    p_io_sn_tx_dat_flit = '0; tog_io_sn_tx_dat_flit = 1'b0;
    p_io_sn_rx_linkactiveack = '0; tog_io_sn_rx_linkactiveack = 1'b0;
    p_io_sn_rx_rsp_lcrdv = '0; tog_io_sn_rx_rsp_lcrdv = 1'b0;
    p_io_sn_rx_dat_lcrdv = '0; tog_io_sn_rx_dat_lcrdv = 1'b0;
    p_io_debugTopDown_addrMatch_0 = '0; tog_io_debugTopDown_addrMatch_0 = 1'b0;
    p_io_l3Miss = '0; tog_io_l3Miss = 1'b0;
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_random();
      #1 check_outputs();
      sample_coverage();
      @(posedge clock);
    end

    if (tog_io_rn_0_rxsactive) toggled++; else $display("COV: output io_rn_0_rxsactive never toggled");
    if (tog_io_rn_0_syscoack) toggled++; else $display("COV: output io_rn_0_syscoack never toggled");
    if (tog_io_rn_0_tx_linkactiveack) toggled++; else $display("COV: output io_rn_0_tx_linkactiveack never toggled");
    if (tog_io_rn_0_tx_req_lcrdv) toggled++; else $display("COV: output io_rn_0_tx_req_lcrdv never toggled");
    if (tog_io_rn_0_tx_rsp_lcrdv) toggled++; else $display("COV: output io_rn_0_tx_rsp_lcrdv never toggled");
    if (tog_io_rn_0_tx_dat_lcrdv) toggled++; else $display("COV: output io_rn_0_tx_dat_lcrdv never toggled");
    if (tog_io_rn_0_rx_linkactivereq) toggled++; else $display("COV: output io_rn_0_rx_linkactivereq never toggled");
    if (tog_io_rn_0_rx_rsp_flitpend) toggled++; else $display("COV: output io_rn_0_rx_rsp_flitpend never toggled");
    if (tog_io_rn_0_rx_rsp_flitv) toggled++; else $display("COV: output io_rn_0_rx_rsp_flitv never toggled");
    if (tog_io_rn_0_rx_rsp_flit) toggled++; else $display("COV: output io_rn_0_rx_rsp_flit never toggled");
    if (tog_io_rn_0_rx_dat_flitpend) toggled++; else $display("COV: output io_rn_0_rx_dat_flitpend never toggled");
    if (tog_io_rn_0_rx_dat_flitv) toggled++; else $display("COV: output io_rn_0_rx_dat_flitv never toggled");
    if (tog_io_rn_0_rx_dat_flit) toggled++; else $display("COV: output io_rn_0_rx_dat_flit never toggled");
    if (tog_io_rn_0_rx_snp_flitpend) toggled++; else $display("COV: output io_rn_0_rx_snp_flitpend never toggled");
    if (tog_io_rn_0_rx_snp_flitv) toggled++; else $display("COV: output io_rn_0_rx_snp_flitv never toggled");
    if (tog_io_rn_0_rx_snp_flit) toggled++; else $display("COV: output io_rn_0_rx_snp_flit never toggled");
    if (tog_io_sn_txsactive) toggled++; else $display("COV: output io_sn_txsactive never toggled");
    if (tog_io_sn_tx_linkactivereq) toggled++; else $display("COV: output io_sn_tx_linkactivereq never toggled");
    if (tog_io_sn_tx_req_flitpend) toggled++; else $display("COV: output io_sn_tx_req_flitpend never toggled");
    if (tog_io_sn_tx_req_flitv) toggled++; else $display("COV: output io_sn_tx_req_flitv never toggled");
    if (tog_io_sn_tx_req_flit) toggled++; else $display("COV: output io_sn_tx_req_flit never toggled");
    if (tog_io_sn_tx_dat_flitpend) toggled++; else $display("COV: output io_sn_tx_dat_flitpend never toggled");
    if (tog_io_sn_tx_dat_flitv) toggled++; else $display("COV: output io_sn_tx_dat_flitv never toggled");
    if (tog_io_sn_tx_dat_flit) toggled++; else $display("COV: output io_sn_tx_dat_flit never toggled");
    if (tog_io_sn_rx_linkactiveack) toggled++; else $display("COV: output io_sn_rx_linkactiveack never toggled");
    if (tog_io_sn_rx_rsp_lcrdv) toggled++; else $display("COV: output io_sn_rx_rsp_lcrdv never toggled");
    if (tog_io_sn_rx_dat_lcrdv) toggled++; else $display("COV: output io_sn_rx_dat_lcrdv never toggled");
    if (tog_io_debugTopDown_addrMatch_0) toggled++; else $display("COV: output io_debugTopDown_addrMatch_0 never toggled");
    if (tog_io_l3Miss) toggled++; else $display("COV: output io_l3Miss never toggled");
    $display("OpenLLC checks=%0d errors=%0d toggled=%0d/%0d fires=%0d", checks, errors, toggled, N_OUT, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks == 0) begin $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end
    if (toggled < MIN_TOGGLED) begin $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)", toggled, MIN_TOGGLED); $fatal(1); end
    $display("TEST PASSED");
    $finish;
  end
endmodule
