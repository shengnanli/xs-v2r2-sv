// =============================================================================
// xs_tlbnb2_pkg —— 非阻塞 DTLB 变体 2（TLBNonBlock_2）的类型与纯函数
//
// 对应 Chisel: xiangshan.cache.mmu.TLB.scala class TLB（Block=false），本实例配置：
//   Width=2 / nRespDups=1 / 全相联存储 TlbStorageWrapper_3。
//   端口不对称：port0 = 完整 load 端口（有 preflight/EffectiveVa/REG+REG_1/kill/isPrefetch/
//     no_translate/pmp_addr/hlvx/hyperinst/fullva/checkfullva）；
//     port1 = 裸端口（仅 cmd/kill/no_translate/vaddr，无 preflight/无 REG）。
//   输出精简：两端口仅 {valid, paddr_0, pbmt_0, miss, pf_ld, af_ld, gpf_ld}
//     （无 gpaddr/isForVS/fullva/vaNeedExt/isHyper/paddr_1/store 异常输出）。
//   典型用途：硬件预取/PTW-walker 侧 DTLB。
//
// 复用同款类型/纯函数(同 xs_tlbnb_pkg)，仅 WIDTH=2/NDUP=1。
// =============================================================================
package xs_tlbnb2_pkg;

  localparam int WIDTH      = 2;
  localparam int VADDR_W    = 50;
  localparam int VPN_W      = 38;
  localparam int PPN_W      = 36;
  localparam int PADDR_W    = 48;
  localparam int GVPN_W     = 44;
  localparam int ROB_W      = 8;

  typedef enum logic [1:0] {
    NO_S2XLATE  = 2'h0, ONLY_STAGE1 = 2'h1, ONLY_STAGE2 = 2'h2, ALL_STAGE = 2'h3
  } s2xlate_e;

  function automatic logic cmd_is_ld(input logic [2:0] cmd);
    return (cmd[1:0] == 2'h0) && (cmd != 3'h5);
  endfunction
  function automatic logic cmd_is_st(input logic [2:0] cmd);
    return (cmd[1:0] == 2'h1) || (cmd == 3'h5);
  endfunction
  function automatic logic cmd_is_inst(input logic [2:0] cmd);
    return cmd[1:0] == 2'h2;
  endfunction
  function automatic logic cmd_is_read(input logic [2:0] cmd);
    return cmd[1:0] == 2'h0;
  endfunction

  typedef struct packed { logic pf, af, v, d, a, u, x, w, r; } tlb_perm_t;
  typedef struct packed { logic pf, af, d, a, x, w, r; }       tlb_gperm_t;

  function automatic s2xlate_e calc_s2xlate(
    input logic virt_or_hyper, input logic vsatp_on, input logic hgatp_on);
    if (!virt_or_hyper)            return NO_S2XLATE;
    else if (vsatp_on && hgatp_on) return ALL_STAGE;
    else if (!vsatp_on)            return ONLY_STAGE2;
    else                           return ONLY_STAGE1;
  endfunction

endpackage
