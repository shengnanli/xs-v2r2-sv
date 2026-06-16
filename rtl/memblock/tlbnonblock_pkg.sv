// =============================================================================
// xs_tlbnb_pkg —— 非阻塞 DTLB（TLBNonBlock）的类型与纯函数
//
// 对应 Chisel:
//   xiangshan.cache.mmu.TLB.scala  class TLB / class TLBNonBlock
//   （非阻塞 DTLB：Width=4 个请求端口、nRespDups=2、全相联存储 TlbStorageWrapper_1）
//
// 角色：TLBNonBlock 是数据侧 TLB 的“顶层控制”。它本身不存页表项（存储在内层
//   TlbStorageWrapper_1 里），只负责：
//     1. s0：收 LSU/预取的 vaddr 请求，转发给存储查询；
//     2. s1：拿存储命中结果 + PTW 刚回填的旁路结果，合成 paddr/perm/异常；
//        - 命中 → 出物理地址 + 权限检查异常（pf/gpf/af）；
//        - miss → 向 PTW（io_ptw.req）发缺页请求，但**不阻塞**后续请求（non-block）；
//          若该 miss 的 PTW 回填刚好这拍/上拍回来，则改为 replay（io_tlbreplay）；
//     3. 收 PTW 回填（io_ptw_resp）：写进内层存储，并做 1 拍旁路（ptw_resp_bypass）；
//     4. sfence/csr 经 fenceDelay=2 拍延迟后透传给存储（flush 旧项 + flush inflight）。
//
//   本工程把 TLBNonBlock 的存储匹配 + PLRU 都放在内层 golden 黑盒 TlbStorageWrapper_1，
//   核 xs_TLBNonBlock_core 只实现“顶层控制”：请求打拍、命中/miss 判定、地址/权限合成、
//   PTW 请求/replay 仲裁、need_gpa 状态机、PTW 回填旁路。
//
// ------------------------------------------------------------------------------
// 两阶段地址翻译（RISC-V H 扩展，hypervisor）
//   s2xlate 编码（2 位）表示本次翻译要经过哪些阶段：
//     noS2xlate(0) —— 仅 VS/S 单阶段（无虚拟化）
//     onlyStage1(1) —— 仅做 VS-stage（vsatp 有效、hgatp 关）
//     onlyStage2(2) —— 仅做 G-stage（vsatp 关、hgatp 有效）
//     allStage(3)   —— VS-stage + G-stage 两级都做
//   普通 DTLB 多数请求是 noS2xlate（非虚拟化场景），但结构必须覆盖全部。
// =============================================================================
package xs_tlbnb_pkg;

  // ---------------- 基本参数（取自本 DTLB 配置 / golden 位宽）----------------
  localparam int WIDTH      = 4;   // 请求端口数
  localparam int NDUP       = 2;   // resp 复制份数（nRespDups，timing 优化用）
  localparam int VADDR_W    = 50;  // vaddr 位宽
  localparam int VPN_W      = 38;  // vpn = vaddr[49:12]
  localparam int PPN_W      = 36;  // 存储返回的 ppn 位宽
  localparam int PADDR_W    = 48;  // 物理地址位宽
  localparam int GVPN_W     = 44;  // guest vpn 位宽（gpaddr 高位）
  localparam int ROB_W      = 8;   // robIdx.value 位宽

  // s2xlate 编码
  typedef enum logic [1:0] {
    NO_S2XLATE  = 2'h0,
    ONLY_STAGE1 = 2'h1,
    ONLY_STAGE2 = 2'h2,
    ALL_STAGE   = 2'h3
  } s2xlate_e;

  // ---------------- TLB 命令（TlbCmd）----------------
  //   cmd[1:0]：00=read(load) 01=write(store) 10=exec(ifetch)；cmd==5=atomic(amo)
  function automatic logic cmd_is_ld(input logic [2:0] cmd);
    return (cmd[1:0] == 2'h0) && (cmd != 3'h5);
  endfunction
  function automatic logic cmd_is_st(input logic [2:0] cmd);
    return (cmd[1:0] == 2'h1) || (cmd == 3'h5);
  endfunction
  function automatic logic cmd_is_inst(input logic [2:0] cmd);
    return cmd[1:0] == 2'h2;
  endfunction
  function automatic logic cmd_is_read(input logic [2:0] cmd);  // load 或 amo
    return cmd[1:0] == 2'h0;
  endfunction
  function automatic logic cmd_is_write(input logic [2:0] cmd); // store
    return cmd[1:0] == 2'h1;
  endfunction

  // ---------------- 单阶段权限位（TlbPermBundle）----------------
  //   存储/PTW 回填里每个页表项的权限。v=有效 d=dirty a=accessed u=user
  //   x/w/r=执行/写/读 pf=本级 page fault af=access fault
  typedef struct packed {
    logic pf, af, v, d, a, u, x, w, r;
  } tlb_perm_t;

  // G-stage 权限位（无 u）
  typedef struct packed {
    logic pf, af, d, a, x, w, r;
  } tlb_gperm_t;

  // ---------------- s1 合成出的“一次翻译读结果”（per dup）----------------
  // 把 TLBRead 在某 dup 上算出的 ppn/perm/pbmt 等聚成一个 bundle，便于逐 dup 处理。
  typedef struct packed {
    logic [PPN_W-1:0]  ppn;
    logic [1:0]        pbmt;
    logic [1:0]        g_pbmt;
    tlb_perm_t         perm;
    tlb_gperm_t        g_perm;
    logic [1:0]        s2xlate;
  } read_dup_t;

  // ---------------- 选择 s2xlate（MuxCase，对应 Scala req_*_s2xlate）----------------
  //   据当前 virt/hyperinst 与 vsatp/hgatp 模式决定本次翻译经过哪些阶段。
  function automatic s2xlate_e calc_s2xlate(
    input logic virt_or_hyper,         // virt(=priv.virt 或 virt_out) 或 hyperinst
    input logic vsatp_on,              // vsatp.mode != 0
    input logic hgatp_on               // hgatp.mode != 0
  );
    if (!virt_or_hyper)           return NO_S2XLATE;
    else if (vsatp_on && hgatp_on) return ALL_STAGE;
    else if (!vsatp_on)            return ONLY_STAGE2;
    else                           return ONLY_STAGE1;  // hgatp 关
  endfunction

  // ---------------- 取 vpn 第 idx 段（getVpnn，每段 vpnnLen=9 位）----------------
  function automatic logic [8:0] get_vpnn(input logic [VPN_W-1:0] vpn, input logic [1:0] idx);
    case (idx)
      2'h0: return vpn[8:0];
      2'h1: return vpn[17:9];
      2'h2: return vpn[26:18];
      default: return vpn[35:27];
    endcase
  endfunction

endpackage
