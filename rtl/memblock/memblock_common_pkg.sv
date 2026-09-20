// memblock_common_pkg.sv —— 访存（memblock）子系统的公共包文件（跨模块共享类型/函数的唯一落点）
//
// 规范依据（CONVENTIONS.md「单文件规范」）：一个 golden 模块 = 一个 .sv 文件，
// 包只在该文件内私有；**跨模块共享**的类型/参数/函数是明确的例外，放
// `rtl/<subsys>/<subsys>_common_pkg.sv`，每个子系统至多一个这样的文件。
// 本文件就是 memblock 子系统的那一个。
//
// 为什么必须有它（2026-09-14 实测，非预防性重构）：`xs_tlbsw_pkg` 原先住在
// `rtl/memblock/TlbStorageWrapper.sv` 里，却被 `rtl/memblock/TlbStorageWrapper_1.sv` 引用 —— 这是**跨文件共享包**。
// 单目标 UT 每次只编一个重写文件，所以一直没人撞到；但 SystemVerilog 要求 package
// 先于使用者编译，而文件顺序就成了承重结构。实测（2026-09-14，VCS W-2024.09-SP1，
// 两个文件单独编一次）：TlbStorageWrapper.sv 排在 TlbStorageWrapper_1.sv 之前（`.` < `_`），今天**恰好**
// 是定义者在先，所以没炸；把两个文件的顺序对调，当场：
//     Error-[SV-LCM-PND] Package not defined
// 外加连锁的 UTFP/IND/SE。
// 也就是说这一处**今天不炸靠的是字母序的运气**（同批三处里 xs_ftb_pkg 就没这个运气：
// FTBBank.sv 按字母序排在定义者 FTBEntryGen.sv 之前，整芯片第一次跑就当场 PND）。
// 包搬到本文件后，使用者只依赖「公共包排在最前」这一条统一规则
// （见 scripts/full_elab_filelist.py 的 pkg_order），两种顺序实测都 rc=0；
// 读者要找类型定义也有唯一落点。
//
// 当前收录：
//   xs_tlbsw_pkg —— TLB 替换策略 Tree-PLRU 的类型与纯函数（TlbStorageWrapper / TlbStorageWrapper_1 共用）
//   tlbnb_pkg    —— 非阻塞 dtlb 的常量/类型/纯函数（TLBNonBlock{,_1,_2} 三个薄 wrapper 的模块头 import）
// 新增共享包时追加到本文件，不要再开第二个 memblock 公共包文件。
// =============================================================================
// xs_tlbsw_pkg —— TlbStorageWrapper 的替换策略（Tree-PLRU）类型与纯函数
//
// 对应 Chisel:
//   xiangshan.cache.mmu.TLBStorage.scala  class TlbStorageWrapper
//     （outReplace=false 分支：val re = ReplacementPolicy.fromString("plru", NWays)）
//   replacement 算法本体：rocket-chip util/Replacement.scala  class PseudoLRU
//
// 角色：TlbStorageWrapper 是 ITLB/DTLB 的“存储 + 替换”包装层。它本身几乎是透明路由：
//   把多端口读请求/响应、sfence、csr、refill 数据原样接到内层全相联存储 TLBFA。
//   它**唯一拥有的有状态逻辑**就是这里实现的 Tree-PLRU 替换器：
//     - 每拍收集各端口 TLBFA 反馈的 access.touch_ways（命中/刚 refill 的 way），
//       依次（foldLeft）更新 PLRU 树状态；
//     - 组合地从当前树状态算出 victim way（refillIdx），驱动 io_w_bits_wayIdx，
//       告诉 TLBFA 下次 refill 写哪一路。
//
// ------------------------------------------------------------------------------
// Tree-PLRU（伪 LRU 二叉树，见 Wikipedia Pseudo-LRU#Tree-PLRU）
//
//   n 路用 n-1 个状态位，每个内部节点 1 位，记录“左子树是否比右子树更老(更该被换)”。
//   - 查 victim：从根沿“指向更老子树”的方向下行，到叶子即得 way 编码（MSB→LSB）。
//   - 命中/refill 后更新：把被访问 way 路径上的每个节点翻成“指向另一侧”，即把刚访问
//     的子树标记为“更新(不该被换)”。
//
//   非 2 的幂拆分规则（与 rocket-chip 完全一致）：
//     right_nways = 1 << (log2Ceil(nways)-1)   // 右子树取最大的 2 的幂
//     left_nways  = nways - right_nways         // 左子树取剩余（可能更小、非平衡）
//   本配置 nways=48：root 把 48 拆成 left=16 / right=32。
//
//   状态位布局（与 rocket-chip extract 索引一致，子树 nways 个 way 用 nways-1 位）：
//     node_bit(本节点)   = state[nways-2]                 （子树状态的最高位）
//     left_subtree_state = state[nways-3 : right_nways-1] （紧邻其下，左子树 left-1 位）
//     right_subtree_state= state[right_nways-2 : 0]       （最低 right-1 位）
//
// 这里把 golden(firtool) 展平成几百行嵌套三元的 victim 选择 + 状态更新，收敛成两个
//   递归纯函数（plru_replace_way / plru_next_state）+ 一个多端口 foldLeft 包装。
//   nways 固定为 48，递归在综合期完全展开。
// =============================================================================
package xs_tlbsw_pkg;

  localparam int NWAYS    = 48;
  localparam int WAY_W    = 6;            // log2Up(NWAYS)
  localparam int PLRU_W   = NWAYS - 1;    // 47：PLRU 树状态位数

  // ---------------- 替换访问反馈 bundle（= TLBFA 的 io_access[i].touch_ways）----------------
  // 对应 Chisel 的 Valid[UInt]：valid=本拍该端口命中/刚 refill；way=对应的 way 编号。
  //   替换器据此（仅在 valid 时）把该 way 标记为“最近使用”，更新 PLRU 树。
  typedef struct packed {
    logic              valid;
    logic [WAY_W-1:0]  way;
  } tlb_access_t;

  // ---------------- PLRU 节点决策方向 ----------------
  // 每个内部节点的状态位语义：左子树是否比右子树更老（更该被替换）。下行选 victim 时
  //   据此决定走哪一侧；以 enum 表意，避免到处裸用 1'b1/1'b0。
  typedef enum logic {
    PLRU_GO_RIGHT = 1'b0,   // 本节点：右子树更老 → 下钻右侧（way 高位记 0）
    PLRU_GO_LEFT  = 1'b1    // 本节点：左子树更老 → 下钻左侧（way 高位记 1）
  } plru_dir_e;

  // log2Ceil（向上取整），用于 PLRU 子树拆分；nways<=64 足够。
  function automatic int xs_log2ceil(input int n);
    int r;
    r = 0;
    // 最小满足 2^r >= n 的 r
    while ((1 << r) < n) r++;
    return r;
  endfunction

  // ---------------------------------------------------------------------------
  // plru_replace_way —— 从树状态求 victim way（= PseudoLRU.get_replace_way）
  //
  // 递归处理一棵 tree_nways 路的子树。state_lo/state 用全宽 47 位总线 + 偏移传递：
  //   子树状态 = state_bus[state_lo +: (tree_nways-1)]，本节点位 = 子树状态最高位。
  // 返回 way 的“相对本子树”的编码（MSB 先确定，递归拼接 LSB）。
  // ---------------------------------------------------------------------------
  // 返回值是**右对齐**的 way 编码：宽度 = log2Ceil(tree_nways)，本节点位在该子树编码的
  //   最高位（bit log2Ceil(tree_nways)-1），递归把子树编码拼在其下。对应 rocket-chip 的
  //   Cat(node_bit, child_way)（Mux 把较窄的左子树编码零扩展到与右子树同宽）。
  function automatic logic [WAY_W-1:0] plru_replace_way(
      input logic [PLRU_W-1:0] state,
      input int                state_lo,   // 子树状态在 state 中的起始位
      input int                tree_nways);
    int right_nways, left_nways, node_pos;
    plru_dir_e node_dir;          // 本节点决策：左子树是否更老（→ 走左/右）
    logic [WAY_W-1:0] sub;
    if (tree_nways <= 1) begin
      return '0;                  // 空节点（非平衡树补位，0 位编码）
    end else if (tree_nways == 2) begin
      // 叶子：单个状态位直接作为最低位（宽度 1）
      return {{(WAY_W-1){1'b0}}, state[state_lo]};
    end else begin
      right_nways = 1 << (xs_log2ceil(tree_nways) - 1);
      left_nways  = tree_nways - right_nways;
      node_pos    = xs_log2ceil(tree_nways) - 1;   // 本节点位在 way 编码中的位置
      // 本节点状态位 = 子树状态最高位 = state[state_lo + (tree_nways-1) - 1]
      node_dir    = plru_dir_e'(state[state_lo + tree_nways - 2]);
      // 子树状态切片：左子树紧贴本节点位之下占 left_nways-1 位（lo=state_lo+right_nways-1），
      //   右子树占最低 right_nways-1 位（lo=state_lo）。
      if (node_dir == PLRU_GO_LEFT) begin
        // 左子树更老 → 下钻左侧（编码右对齐，宽度 log2Ceil(left_nways)≤node_pos）
        if (left_nways > 1)
          sub = plru_replace_way(state, state_lo + right_nways - 1, left_nways);
        else
          sub = '0;               // 左只有 1 路（非平衡叶），编码为 0
      end else begin
        // 右子树更老 → 下钻右侧（编码宽度恰为 node_pos）
        sub = plru_replace_way(state, state_lo, right_nways);
      end
      // 本节点位放到 node_pos，子树编码拼在其下（右对齐）
      return (logic'(node_dir == PLRU_GO_LEFT) << node_pos) | sub;
    end
  endfunction

  // ---------------------------------------------------------------------------
  // plru_next_state —— 访问 touch_way 后的新树状态（= PseudoLRU.get_next_state）
  //
  // 沿 touch_way 指示的路径，把每个经过节点翻成“指向另一侧子树”（标记被访问侧为新），
  // 未经过的子树状态保持不变。touch_way 用全宽 WAY_W 传，按本层 log2 位取方向。
  // 返回**整棵 47 位**新状态（未涉及位原样保留），便于多端口 foldLeft 串联。
  // ---------------------------------------------------------------------------
  function automatic logic [PLRU_W-1:0] plru_next_state(
      input logic [PLRU_W-1:0] state,
      input logic [WAY_W-1:0]  touch_way,
      input int                state_lo,
      input int                tree_nways);
    int right_nways, left_nways, level_bit;
    logic set_left_older;
    logic [PLRU_W-1:0] ns;
    ns = state;
    if (tree_nways == 2) begin
      // 叶子：状态位 = !touch_way[0]（访问 way0 → 标记 way1 更老，反之亦然）
      ns[state_lo] = ~touch_way[0];
      return ns;
    end else if (tree_nways <= 1) begin
      return ns;                  // 空节点，不变
    end else begin
      right_nways = 1 << (xs_log2ceil(tree_nways) - 1);
      left_nways  = tree_nways - right_nways;
      level_bit   = xs_log2ceil(tree_nways) - 1;       // 本层在 touch_way 中的方向位
      set_left_older = ~touch_way[level_bit];          // 访问右侧→左变老；访问左侧→右变老
      // 本节点位置 = state_lo + tree_nways - 2
      ns[state_lo + tree_nways - 2] = set_left_older;
      if (set_left_older) begin
        // 访问的是右子树 → 仅递归更新右子树（左子树整体标记更老，不下钻）
        ns = plru_next_state(ns, touch_way, state_lo, right_nways);
      end else if (left_nways > 1) begin
        // 访问的是左子树 → 递归更新左子树（左有分支才下钻）
        ns = plru_next_state(ns, touch_way, state_lo + right_nways - 1, left_nways);
      end
      return ns;
    end
  endfunction

endpackage

package tlbnb_pkg;

  // ---- KunminghuV2Config 下的地址/页表常量 ----
  // 每个值都和 golden 的端口位宽对过账，注释里写的是对账依据。
  localparam int XLEN       = 64;
  localparam int VADDR_W    = 50;  // VAddrBits；req.bits.vaddr 宽度
  localparam int PADDR_W    = 48;  // PAddrBits；resp.bits.paddr 宽度
  localparam int OFF_W      = 12;  // 页内偏移
  localparam int VPN_W      = 38;  // vpnLen = VADDR_W - OFF_W；ptw.req.bits.vpn 宽度
  localparam int VPNN_W     = 9;   // 每级页表索引位数
  localparam int LEVEL      = 3;   // Sv48：level ∈ 0..3，最高级下标就是 3
  localparam int SECT_W     = 3;   // sectortlbwidth
  localparam int SVPN_W     = 35;  // sectorvpnLen = VPN_W - SECT_W；s1.entry.tag 宽度
  localparam int PPN_W      = 36;  // ppnLen = PADDR_W - OFF_W；resp ppn 宽度
  localparam int SPPN_W     = 41;  // sectorptePPNLen = 44 - 3；s1.entry.ppn 宽度
  localparam int PTE_PPN_W  = 44;  // ptePPNLen；gvpn 宽度
  localparam int GVPN_W     = 38;  // gvpnLen = GPAddrBits(50) - OFF_W；s2.entry.tag/ppn 宽度
  localparam int NAPOT_W    = 4;   // pteNapotBits：Svnapot 64KB = 16 页
  localparam int ASID_W     = 16;
  localparam int VMID_W     = 14;  // s1/s2.entry.vmid 宽度（注意比 hgatp.vmid 窄 2 位）
  localparam int ROB_IDX_W  = 8;   // RobPtr.value
  localparam int MEMIDX_W   = 7;   // MemBlockidxBundle.idx
  localparam int SECT_N     = 8;   // tlbcontiguous

  // ---- s2xlate 编码（MMUConst）----
  localparam logic [1:0] NO_S2XLATE = 2'h0;
  localparam logic [1:0] ONLY_S1    = 2'h1;
  localparam logic [1:0] ONLY_S2    = 2'h2;
  localparam logic [1:0] ALL_STAGE  = 2'h3;

  // ---- satp/vsatp/hgatp.mode ----
  localparam logic [3:0] SV39 = 4'h8;
  localparam logic [3:0] SV48 = 4'h9;

  // ---- 特权级 ----
  localparam logic [1:0] MODE_U = 2'h0;
  localparam logic [1:0] MODE_S = 2'h1;
  localparam logic [1:0] MODE_M = 2'h3;

  // ---- PMM（指针掩码）----
  localparam logic [1:0] PMLEN7  = 2'b10;
  localparam logic [1:0] PMLEN16 = 2'b11;

  // ---- TlbCmd：低 2 位区分读/写/取指，cmd==5 是 amo（算写）----
  localparam logic [1:0] CMD_READ  = 2'h0;
  localparam logic [1:0] CMD_WRITE = 2'h1;
  localparam logic [1:0] CMD_EXEC  = 2'h2;
  localparam logic [2:0] CMD_AMO   = 3'h5;  // atom_write（sc/amo）
  localparam logic [2:0] CMD_RX    = 3'h7;  // read_exec，HLVX 的 PMP 检查用

  // TLB 表项权限（TlbPermBundle）。g 位本核用不到（entries 不给），故不进 struct。
  typedef struct packed {
    logic pf;   // stage-1 页故障
    logic af;   // 访问故障
    logic v;    // 表项 valid
    logic d;    // dirty
    logic a;    // accessed
    logic u;    // user
    logic x;
    logic w;
    logic r;
  } tlb_perm_t;

  // G-stage（s2）权限只用得到这 7 位：Chisel 的 hptwresp_to_tlbperm 把 v 置成
  // DontCare、u 虽然赋了值但 perm_check 的 G-stage 分支从不读它，于是 golden 里
  // p_g_perm 只留下 7 个寄存器（entries 的 g_perm 输出端口也正好是这 7 个）。
  // ★不要图省事复用 tlb_perm_t★：那会凭空多出 v/u 两个 golden 没有的寄存器。
  typedef struct packed {
    logic pf;   // G-stage 页故障（HptwResp.gpf）
    logic af;   // G-stage 访问故障（HptwResp.gaf）
    logic d;
    logic a;
    logic x;
    logic w;
    logic r;
  } tlb_gperm_t;

  // PTW 响应里 VS-stage（s1）那一半。字段名与 golden 端口一一对应。
  typedef struct packed {
    logic [SVPN_W-1:0]  entry_tag;
    logic [ASID_W-1:0]  entry_asid;
    logic [VMID_W-1:0]  entry_vmid;
    logic               entry_n;      // Svnapot 64KB
    logic [1:0]         entry_pbmt;
    logic               entry_perm_d;
    logic               entry_perm_a;
    logic               entry_perm_g;  // global：命中时不看 asid
    logic               entry_perm_u;
    logic               entry_perm_x;
    logic               entry_perm_w;
    logic               entry_perm_r;
    logic [1:0]         entry_level;
    logic               entry_v;
    logic [SPPN_W-1:0]  entry_ppn;
    logic [SECT_W-1:0]  addr_low;
    logic [SECT_N-1:0][SECT_W-1:0] ppn_low;
    logic [SECT_N-1:0]  valididx;
    logic [SECT_N-1:0]  pteidx;
    logic               pf;
    logic               af;
  } ptw_s1_t;

  // PTW 响应里 G-stage（s2）那一半。
  typedef struct packed {
    logic [GVPN_W-1:0] entry_tag;
    logic [VMID_W-1:0] entry_vmid;
    logic              entry_n;
    logic [1:0]        entry_pbmt;
    logic [GVPN_W-1:0] entry_ppn;
    logic              entry_perm_d;
    logic              entry_perm_a;
    logic              entry_perm_g;
    logic              entry_perm_u;
    logic              entry_perm_x;
    logic              entry_perm_w;
    logic              entry_perm_r;
    logic [1:0]        entry_level;
    logic              gpf;
    logic              gaf;
  } ptw_s2_t;

  typedef struct packed {
    logic [1:0] s2xlate;
    ptw_s1_t    s1;
    ptw_s2_t    s2;
    logic       get_gpa;
  } ptw_resp_t;

  // 延迟 fenceDelay(=2) 拍之后的 CSR 现场（wrapper 里的 DelayN_7 出来的）。
  // priv.debug 本核用不到（golden 里 DelayN_7 的 io_out_priv_debug 就是接
  // /* unused */ 的），故不在这里出现。
  typedef struct packed {
    // changed 位只服务 refill 的 flush_mmu 门控（见 §refill）
    logic              satp_changed;
    logic              vsatp_changed;
    logic              hgatp_changed;
    logic              priv_virt_changed;
    logic [3:0]        satp_mode;
    logic [ASID_W-1:0] satp_asid;
    logic [PTE_PPN_W-1:0] satp_ppn;    // 仅 difftest 打包用
    logic [3:0]        vsatp_mode;
    logic [ASID_W-1:0] vsatp_asid;
    logic [PTE_PPN_W-1:0] vsatp_ppn;   // 仅 difftest
    logic [3:0]        hgatp_mode;
    logic [ASID_W-1:0] hgatp_vmid;     // 注意：CSR 侧 16 位，表项里只存低 14 位
    logic [PTE_PPN_W-1:0] hgatp_ppn;   // 仅 difftest
    logic              priv_mxr;
    logic              priv_sum;
    logic              priv_vmxr;
    logic              priv_vsum;
    logic              priv_virt;
    logic              priv_spvp;
    logic [1:0]        priv_imode;
    logic [1:0]        priv_dmode;
    logic [1:0]        pmm_mseccfg;
    logic [1:0]        pmm_menvcfg;
    logic [1:0]        pmm_henvcfg;
    logic [1:0]        pmm_hstatus;
    logic [1:0]        pmm_senvcfg;
  } tlb_csr_t;

  // PtwRespS2.hit() / PtwSectorResp.hit() / HptwResp.hit() 三个命中比较**只用到**
  // 下面这些字段。golden 里 handle_nonblock 为每条 lane 存了一份"上一拍的 PTW 响应"
  // （ptw_resp_bits_reg），存的恰好就是这几项 —— 其余字段没人读，firtool 消掉了。
  // 所以这个 struct 不是"为了好看抽出来的子集"，它就是 golden 那组寄存器的字段表。
  typedef struct packed {
    logic [1:0]         s2xlate;
    logic [SVPN_W-1:0]  s1_tag;
    logic [ASID_W-1:0]  s1_asid;
    logic [VMID_W-1:0]  s1_vmid;
    logic               s1_n;
    logic [1:0]         s1_level;
    logic               s1_perm_g;
    logic [SECT_W-1:0]  s1_addr_low;
    logic [SECT_N-1:0]  s1_valididx;
    logic [GVPN_W-1:0]  s2_tag;
    logic [VMID_W-1:0]  s2_vmid;
    logic               s2_n;
    logic [1:0]         s2_level;
  } hit_key_t;

  // 超页/NAPOT 的 tag 比较阶梯：level=0 比到最低一级，level=3 只比最高一级。
  // tm[k] = 第 k 级 vpnn 段相等。
  function automatic logic level_match(input logic [1:0] level, input logic [LEVEL:0] tm);
    return (level == 2'h0) ? (tm[3] & tm[2] & tm[1] & tm[0])
         : (level == 2'h1) ? (tm[3] & tm[2] & tm[1])
         : (level == 2'h2) ? (tm[3] & tm[2])
                           :  tm[3];
  endfunction

  // PtwSectorResp.hit(vpn, satp.asid)：无两级翻译时的命中判据。
  // sector 表项：tag 只存 vpn[37:3]，最低 3 位靠 valididx 逐页标记。
  function automatic logic s1_hit(input hit_key_t k,
                                  input logic [VPN_W-1:0] vpn,
                                  input logic [ASID_W-1:0] asid);
    logic [LEVEL:0] tm;
    logic asid_hit, super_page;
    asid_hit   = (k.s1_asid == asid) | k.s1_perm_g;
    // ★tag 是 sector tag：tag[k] 对应 vpn[k+SECT_W]★，所以两条分支的 tag 切片
    // 上下界要各自减 SECT_W，**上界不随下界一起减**：
    //   n=1（Svnapot 64KB）比 vpn[8:NAPOT_W] -> tag[8-SECT_W : NAPOT_W-SECT_W] = tag[5:1]
    //   n=0             比 vpn[8:SECT_W]     -> tag[8-SECT_W : 0]              = tag[5:0]
    // 判据 golden TLBNonBlock_1.sv:1337-1339（noS2 分支）/ TLBNonBlock.sv 同形。
    tm[0]      = k.s1_n ? (k.s1_tag[VPNN_W-1-SECT_W : NAPOT_W-SECT_W] == vpn[VPNN_W-1:NAPOT_W])
                        : (k.s1_tag[VPNN_W-1-SECT_W : 0]             == vpn[VPNN_W-1:SECT_W]);
    tm[1]      = k.s1_tag[VPNN_W*2-SECT_W-1 : VPNN_W-SECT_W]   == vpn[VPNN_W*2-1 : VPNN_W];
    tm[2]      = k.s1_tag[VPNN_W*3-SECT_W-1 : VPNN_W*2-SECT_W] == vpn[VPNN_W*3-1 : VPNN_W*2];
    tm[3]      = k.s1_tag[SVPN_W-1 : VPNN_W*3-SECT_W]          == vpn[VPN_W-1 : VPNN_W*3];
    super_page = (|k.s1_level) | k.s1_n;
    return asid_hit & level_match(k.s1_level, tm)
           & (super_page | k.s1_valididx[vpn[SECT_W-1:0]]);
  endfunction

  // HptwResp.hit(gvpn, hgatp.vmid)：只有 G-stage 时的命中判据。
  // s2 表项不是 sector 的，tag 就是完整 gvpn，所以没有 valididx 那一项。
  function automatic logic s2_hit(input hit_key_t k,
                                  input logic [VPN_W-1:0] gvpn,
                                  input logic [ASID_W-1:0] vmid);
    logic [LEVEL:0] tm;
    tm[0] = k.s2_n ? (k.s2_tag[VPNN_W-1:NAPOT_W] == gvpn[VPNN_W-1:NAPOT_W])
                   : (k.s2_tag[VPNN_W-1:0]       == gvpn[VPNN_W-1:0]);
    tm[1] = k.s2_tag[VPNN_W*2-1 : VPNN_W]   == gvpn[VPNN_W*2-1 : VPNN_W];
    tm[2] = k.s2_tag[VPNN_W*3-1 : VPNN_W*2] == gvpn[VPNN_W*3-1 : VPNN_W*2];
    tm[3] = k.s2_tag[GVPN_W-1 : VPNN_W*3]   == gvpn[VPN_W-1 : VPNN_W*3];
    // vmid：表项只存 14 位，CSR 侧 16 位，golden 是把表项零扩展后全宽比较。
    return ({2'h0, k.s2_vmid} == vmid) & level_match(k.s2_level, tm);
  endfunction

  // 两级都有（onlyStage1 / allStage）时：命中看的是 s1 的 {tag, addr_low} 拼出来的
  // 完整 vpn，且 level / n 取两级里"更小的那个页"（页大小以小的为准）。
  function automatic logic all_s1_hit(input hit_key_t k,
                                      input logic [VPN_W-1:0] vpn,
                                      input logic [ASID_W-1:0] vsatp_asid,
                                      input logic [ASID_W-1:0] hgatp_vmid);
    logic [VPN_W-1:0] s1vpn;
    logic [LEVEL:0]   tm;
    logic [1:0]       level;
    logic             n, all_stage_n, vasid_hit;
    s1vpn       = {k.s1_tag, k.s1_addr_low};
    all_stage_n = (k.s1_n & (|k.s2_level)) | (k.s2_n & (|k.s1_level)) | (k.s1_n & k.s2_n);
    level       = ((k.s2xlate == ONLY_S1) | (k.s1_level < k.s2_level)) ? k.s1_level : k.s2_level;
    n           = (k.s2xlate == ONLY_S1) ? k.s1_n : all_stage_n;
    tm[0] = n ? (vpn[VPNN_W-1:NAPOT_W] == s1vpn[VPNN_W-1:NAPOT_W])
              : (vpn[VPNN_W-1:0]       == s1vpn[VPNN_W-1:0]);
    tm[1] = vpn[VPNN_W*2-1 : VPNN_W]   == s1vpn[VPNN_W*2-1 : VPNN_W];
    tm[2] = vpn[VPNN_W*3-1 : VPNN_W*2] == s1vpn[VPNN_W*3-1 : VPNN_W*2];
    tm[3] = vpn[VPN_W-1 : VPNN_W*3]    == s1vpn[VPN_W-1 : VPNN_W*3];
    vasid_hit = (k.s1_asid == vsatp_asid) | k.s1_perm_g;
    return level_match(level, tm) & ({2'h0, k.s1_vmid} == hgatp_vmid) & vasid_hit;
  endfunction

  // PtwRespS2.hit：按 s2xlate 选上面三条中的一条。
  function automatic logic ptw_hit(input hit_key_t k,
                                   input logic [VPN_W-1:0] vpn,
                                   input logic [ASID_W-1:0] satp_asid,
                                   input logic [ASID_W-1:0] vsatp_asid,
                                   input logic [ASID_W-1:0] hgatp_vmid);
    return (k.s2xlate == NO_S2XLATE) ? s1_hit(k, vpn, satp_asid)
         : (k.s2xlate == ONLY_S2)    ? s2_hit(k, vpn, hgatp_vmid)
                                     : all_s1_hit(k, vpn, vsatp_asid, hgatp_vmid);
  endfunction

  // 取 vpn 的第 idx 段（每段 VPNN_W 位）。idx 越界（>3）时 golden 取第 0 段 —— 这是
  // firtool 展开 Chisel Vec 越界读的结果，不是回绕，见 CONVENTIONS.md。
  function automatic logic [VPNN_W-1:0] get_vpnn(input logic [VPN_W-1:0] vpn,
                                                 input logic [1:0] idx);
    return (idx == 2'h1) ? vpn[VPNN_W*2-1 : VPNN_W]
         : (idx == 2'h2) ? vpn[VPNN_W*3-1 : VPNN_W*2]
         : (idx == 2'h3) ? vpn[VPNN_W*4-1 : VPNN_W*3]
                         : vpn[VPNN_W-1 : 0];
  endfunction


  // ---------------------------------------------------------------------------
  // 下面这组函数**必须把 ptw_resp 当参数传进来**，不许在模块里捕获模块级信号：
  // CONVENTIONS.md 记着的坑 —— generate-for 里调用捕获模块级信号的 function，
  // VCS 仿真会返 X。所以它们住在 package 里，只看参数。
  // ---------------------------------------------------------------------------

  // PtwSectorResp 的三个形态判据
  function automatic logic s1_is_leaf(input ptw_resp_t p);
    return (p.s1.entry_perm_r | p.s1.entry_perm_x | p.s1.entry_perm_w) & p.s1.entry_v;
  endfunction
  function automatic logic s1_is_fake_pte(input ptw_resp_t p);
    return ~p.s1.pf & ~p.s1.entry_v & ~p.s1.af;
  endfunction
  // 非叶子：r/w/x 全 0 但表项有效且没故障 —— PTW 停在了中间级页表
  function automatic logic s1_is_non_leaf(input ptw_resp_t p);
    return ~(p.s1.entry_perm_r | p.s1.entry_perm_w | p.s1.entry_perm_x)
           & p.s1.entry_v & ~p.s1.pf & ~p.s1.af;
  endfunction

  // PtwSectorResp.genPPN(vpn)：按 level 把表项 ppn 的高位和 vpn 的低位拼起来。
  // level=0 且非 NAPOT 时最低 3 位来自 ppn_low[vpn[2:0]]（sector 表项每页各存一份）。
  function automatic logic [PTE_PPN_W-1:0] s1_gen_ppn(input ptw_resp_t p,
                                                      input logic [VPN_W-1:0] vpn);
    case (p.s1.entry_level)
      2'h3: return {p.s1.entry_ppn[SPPN_W-1 : VPNN_W*3-SECT_W], vpn[VPNN_W*3-1:0]};
      2'h2: return {p.s1.entry_ppn[SPPN_W-1 : VPNN_W*2-SECT_W], vpn[VPNN_W*2-1:0]};
      2'h1: return {p.s1.entry_ppn[SPPN_W-1 : VPNN_W-SECT_W],   vpn[VPNN_W-1:0]};
      default: return p.s1.entry_n
                      ? {p.s1.entry_ppn[SPPN_W-1 : NAPOT_W-SECT_W], vpn[NAPOT_W-1:0]}
                      : {p.s1.entry_ppn, p.s1.ppn_low[vpn[SECT_W-1:0]]};
    endcase
  endfunction

  // PtwSectorResp.genGVPN(vpn)：非叶子时 gvpn 就是"表项里那一页"，否则同 genPPN。
  function automatic logic [PTE_PPN_W-1:0] s1_gen_gvpn(input ptw_resp_t p,
                                                       input logic [VPN_W-1:0] vpn);
    return s1_is_non_leaf(p) ? {p.s1.entry_ppn, p.s1.ppn_low[vpn[SECT_W-1:0]]}
                             : s1_gen_ppn(p, vpn);
  endfunction

  // HptwResp.genPPNS2(gvpn)：G-stage 的同一件事，表项不是 sector 的所以没有 ppn_low。
  function automatic logic [GVPN_W-1:0] s2_gen_ppn(input ptw_resp_t p,
                                                   input logic [VPN_W-1:0] gvpn);
    case (p.s2.entry_level)
      2'h3: return {p.s2.entry_ppn[GVPN_W-1 : VPNN_W*3], gvpn[VPNN_W*3-1:0]};
      2'h2: return {p.s2.entry_ppn[GVPN_W-1 : VPNN_W*2], gvpn[VPNN_W*2-1:0]};
      2'h1: return {p.s2.entry_ppn[GVPN_W-1 : VPNN_W],   gvpn[VPNN_W-1:0]};
      default: return p.s2.entry_n
                      ? {p.s2.entry_ppn[GVPN_W-1 : NAPOT_W], gvpn[NAPOT_W-1:0]}
                      : p.s2.entry_ppn;
    endcase
  endfunction

  // OHToUInt：pteidx 是 one-hot，转成 3 位下标。★是按位或，不是优先编码★
  function automatic logic [SECT_W-1:0] oh_to_uint8(input logic [SECT_N-1:0] oh);
    return {|oh[7:4], |{oh[7:6], oh[3:2]}, |{oh[7], oh[5], oh[3], oh[1]}};
  endfunction

  // PtwRespS2.getVpn(vpn)：把响应还原成它覆盖的那条 vpn，need_gpa 用它对账。
  // level / n 在两级都有时取"更小的页"，与 hit() 里的规则一致。
  function automatic logic [VPN_W-1:0] ptw_get_vpn(input ptw_resp_t p,
                                                   input logic [VPN_W-1:0] vpn);
    logic [1:0]       lvl;
    logic             nn, all_stage_n;
    logic [VPN_W-1:0] s1_vpn, s2_vpn;
    all_stage_n = (p.s1.entry_n & (|p.s2.entry_level))
                | (p.s2.entry_n & (|p.s1.entry_level))
                | (p.s1.entry_n &   p.s2.entry_n);
    lvl = (|p.s2xlate)
          ? ((&p.s2xlate) ? ((p.s1.entry_level < p.s2.entry_level) ? p.s1.entry_level
                                                                   : p.s2.entry_level)
                          : ((p.s2xlate == ONLY_S2) ? p.s2.entry_level : p.s1.entry_level))
          : p.s1.entry_level;
    nn  = (|p.s2xlate)
          ? ((&p.s2xlate) ? all_stage_n
                          : ((p.s2xlate == ONLY_S2) ? p.s2.entry_n : p.s1.entry_n))
          : p.s1.entry_n;
    case (lvl)
      2'h3: s1_vpn = {p.s1.entry_tag[SVPN_W-1 : VPNN_W*3-SECT_W], vpn[VPNN_W*3-1:0]};
      2'h2: s1_vpn = {p.s1.entry_tag[SVPN_W-1 : VPNN_W*2-SECT_W], vpn[VPNN_W*2-1:0]};
      2'h1: s1_vpn = {p.s1.entry_tag[SVPN_W-1 : VPNN_W-SECT_W],   vpn[VPNN_W-1:0]};
      default: s1_vpn = nn ? {p.s1.entry_tag[SVPN_W-1 : NAPOT_W-SECT_W], vpn[NAPOT_W-1:0]}
                           : {p.s1.entry_tag, oh_to_uint8(p.s1.pteidx)};
    endcase
    case (lvl)
      2'h3: s2_vpn = {p.s2.entry_tag[GVPN_W-1 : VPNN_W*3], vpn[VPNN_W*3-1:0]};
      2'h2: s2_vpn = {p.s2.entry_tag[GVPN_W-1 : VPNN_W*2], vpn[VPNN_W*2-1:0]};
      2'h1: s2_vpn = {p.s2.entry_tag[GVPN_W-1 : VPNN_W],   vpn[VPNN_W-1:0]};
      default: s2_vpn = nn ? {p.s2.entry_tag[GVPN_W-1 : NAPOT_W], vpn[NAPOT_W-1:0]}
                           : p.s2.entry_tag;
    endcase
    return (p.s2xlate == ONLY_S2) ? s2_vpn : s1_vpn;
  endfunction

  // RobPtr 比较：{flag, value} 的环形序。needFlush = 本条在 redirect 指向的条目之后。
  // golden 展开成 `flag ^ r_flag ^ (value > r_value)`（异或链，不是减法），照抄。
  function automatic logic rob_need_flush(
      input logic        r_valid,
      input logic        r_level,
      input logic        r_flag,
      input logic [ROB_IDX_W-1:0] r_value,
      input logic        flag,
      input logic [ROB_IDX_W-1:0] value);
    logic flush_itself;
    flush_itself = r_level & ({flag, value} == {r_flag, r_value});
    return r_valid & (flush_itself | (flag ^ r_flag ^ (value > r_value)));
  endfunction

endpackage
