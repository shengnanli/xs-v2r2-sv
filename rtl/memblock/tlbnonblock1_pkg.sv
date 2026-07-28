// =============================================================================
// xs_tlbnb1_pkg —— 非阻塞存储 DTLB（TLBNonBlock_1，store TLB）的类型与纯函数
//
// 对应 Chisel: xiangshan.cache.mmu.TLB.scala class TLB（Block=false），本实例配置：
//   Width=2 个请求端口、nRespDups=1、全相联存储 TlbStorageWrapper_2。
//   store TLB 特化：requestor 无 hlvx/kill/isPrefetch/no_translate/pmp_addr/s1-kill 输入，
//   两个端口都是「完整」端口（都有 ld+st 异常/gpaddr/isHyper/fullva/isForVSnonLeafPTE）。
//
// 与 load DTLB（xs_tlbnb_pkg, Width=4/nRespDups=2）唯一差异：WIDTH/NDUP + 端口特性。
//   核心 TLB 逻辑（s2xlate/EffectiveVa/perm 检查/PTW 命中/need_gpa FSM）完全相同。
// =============================================================================
package xs_tlbnb1_pkg;

  localparam int WIDTH      = 2;   // 请求端口数（dtlb_st 2 端口）
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
  function automatic logic cmd_is_write(input logic [2:0] cmd);
    return cmd[1:0] == 2'h1;
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

  function automatic logic [8:0] get_vpnn(input logic [VPN_W-1:0] vpn, input logic [1:0] idx);
    case (idx)
      2'h0: return vpn[8:0];
      2'h1: return vpn[17:9];
      2'h2: return vpn[26:18];
      default: return vpn[35:27];
    endcase
  endfunction

endpackage
