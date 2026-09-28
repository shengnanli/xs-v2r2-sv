// =============================================================================
//  MutiLevelPrefetchFilter.sv —— L1 流式预取器的「多级预取请求过滤表」
// -----------------------------------------------------------------------------
//  位置：MemBlock / L1Prefetcher 里的 pf_queue_filter（golden 实例名）。上游是 stream/stride
//        预取器，每拍最多送来两条「区域预取请求」：一条想预取进 L1 DCache（l1_prefetch_req），
//        一条想预取进 L2/L3（l2_l3_prefetch_req）。一条请求 = 一个 1KB 区域（region，
//        虚拟地址的 [49:10]）+ 16 位 bit_vec（区域里哪几个 64B cacheline 要预取）+ sink（目标层级）。
//  输出：io_tlb_req（把虚拟 region 翻成物理 region）、io_l1_req（发给 DCache 的逐行预取）、
//        io_l2_pf_addr（发给 L2 的逐行预取）。发往 L3 的那路在 golden 配置里没有端口（上层不接，
//        firtool 删掉了端口），但它的仲裁器仍在，仍会把表项的 sent_vec 置位 —— 照写。
//
//  核心机制（按本文件的组织顺序，也是一条请求一生的顺序）：
//    §1 表项结构：L1 表 16 项 + L2/L3 表 16 项。一项 = 一个区域：
//         tag(区域哈希) / region(先是虚拟、TLB 回来后换成物理) / bit_vec(还要发哪几行) /
//         sent_vec(已经发过哪几行) / sink(目标层级) / is_vaddr(region 还是虚地址吗) / …
//    §2 替换：优先挑「空闲或全部行都发完了」的项，挑不出就退化成全体 PLRU（ValidPseudoLRU）。
//    §3 入表/去重（两级流水）：s0 用 15 位区域哈希在表里 CAM，命中就记下项号，不中就选替换项；
//         s1 真正写表 —— 不中则整条覆盖（alloc），命中则把新 bit_vec 并进去（update）。
//    §4 TLB 查询（四级流水）：表里 is_vaddr 的项轮转仲裁出一个去查 TLB；s3 拿到物理地址后
//         把 region 换成物理 region；缺页/访问错/不可缓存 → 作废该项（invalidate）。
//    §5 L1 发出：已是物理地址、还有行要发的 L1 项轮转仲裁，每次取 bit_vec 里最低的一行发给 DCache。
//    §6 L2/L3 发出：同上，按 sink 分给 L2 仲裁器和 L3 仲裁器（都是「只看 sent_vec 没置位的行」）。
//
//  怪癖（都照 golden 写，理由在各节注释里）：
//    · 同一个 region 可能在两个表里各有一项（两表互不查）；哈希冲突的两个 region 会被当成同一项。
//    · L1 项发出靠「清 bit_vec」而不是「置 sent_vec」（sent_vec 只在 s0 仲裁成功时置，s1 真发出时
//      再清 bit_vec）；L2/L3 项只置 sent_vec。见 §5 的解释。
//    · 冲刷(io.flush)在本配置里被上层接成常 0（golden 无此端口），但「打一拍再清 valid」的 32 个
//      寄存器仍然存在（D 端恒 0、不复位）。golden 里还有 6 个只喂性能计数器的死寄存器。都照抄。
//
//  文件结构（单文件规范）：mutilevelprefetchfilter_pkg → xs_MutiLevelPrefetchFilter_core（可读核）
//    → MutiLevelPrefetchFilter（golden 同名 wrapper，端口逐位同名同序）。
//  子模块：4 个轮转仲裁器 RRArbiterInit_7(TLB,32 路) / _8(L1,16 路) / _9(L2,16 路) / _6(L3,16 路)，
//    都是本仓已签核的重写件（rtl/common/RRArbiterInit_*.sv，核在 rtl/common/RRArbiterInit.sv）。
//  设计源：src/main/scala/xiangshan/mem/prefetch/L1PrefetchComponent.scala（class MutiLevelPrefetchFilter）
// =============================================================================

// =============================================================================
//  mutilevelprefetchfilter_pkg —— 位宽常量 / 端口 bundle / 纯函数
// =============================================================================
package mutilevelprefetchfilter_pkg;

  // ---- 容量 ------------------------------------------------------------------
  localparam int L1_SIZE  = 16;                 // MLP_L1_SIZE
  localparam int L2_SIZE  = 16;                 // MLP_L2L3_SIZE（L2 与 L3 共用一张表）
  localparam int MLP_SIZE = L1_SIZE + L2_SIZE;  // TLB 仲裁器的路数：0..15 = L1 表，16..31 = L2 表

  // ---- 地址切分 ---------------------------------------------------------------
  //  vaddr(50 位) = | region(40) | 区域内行号(4) | 行内偏移(6) |
  //  一个区域 = 1KB = 16 条 64B cacheline，bit_vec 的第 k 位 = 区域内第 k 行。
  localparam int VADDR_W   = 50;
  localparam int PADDR_W   = 48;
  localparam int REGION_W  = 40;                // REGION_TAG_BITS
  localparam int BITVEC_W  = 16;                // BIT_VEC_WITDH
  localparam int BLK_OFF_W = 6;                 // log2(64B)
  localparam int TAG_W     = 15;                // HASH_TAG_WIDTH = 5(哈希) + 10(原样低位)

  // ---- sink：预取目标层级（数值越小越靠近核）----------------------------------------
  localparam logic [1:0] SINK_L1 = 2'd0;
  localparam logic [1:0] SINK_L2 = 2'd1;
  localparam logic [1:0] SINK_L3 = 2'd2;

  // ---- 预取来源编码 ------------------------------------------------------------
  localparam logic [2:0] L1_HW_PREFETCH_STRIDE = 3'd2;
  localparam logic [2:0] L1_HW_PREFETCH_STREAM = 3'd3;
  //  送往 L2 的 reqSource（utility MemReqSource 枚举的序号）
  localparam logic [4:0] PF2L2_STREAM  = 5'd11;
  localparam logic [4:0] PF2L2_STRIDE  = 5'd12;
  localparam logic [4:0] PF2L2_UNKNOWN = 5'd16;

  // ---- 物理内存范围（PmemRanges）：只有落在这里的地址才真的发给 DCache ---------------
  localparam logic [PADDR_W-1:0] PMEM_BASE = 48'h0000_8000_0000;
  localparam logic [PADDR_W-1:0] PMEM_END  = 48'h0800_0000_0000;

  // ---- 端口 bundle ------------------------------------------------------------
  // 上游送来的「区域预取请求」（StreamPrefetchReqBundle 在本模块用到的字段）
  typedef struct packed {
    logic [REGION_W-1:0] region;
    logic [BITVEC_W-1:0] bit_vec;
    logic [1:0]          sink;
    logic [2:0]          source_value;
  } stream_pf_req_t;

  // 发给 TLB 的请求（TlbReq 在 golden 里留下的字段；除 vaddr 外都是常量或 DontCare=0）
  typedef struct packed {
    logic [VADDR_W-1:0] vaddr;
    logic [63:0]        fullva;
    logic               checkfullva;
    logic [2:0]         cmd;
    logic               hyperinst;
    logic               hlvx;
    logic               kill;
    logic               isPrefetch;
    logic               no_translate;
    logic [PADDR_W-1:0] pmp_addr;
    logic               frm_mabuf;
    logic               debug_robIdx_flag;
    logic [7:0]         debug_robIdx_value;
    logic               debug_isFirstIssue;
  } tlb_req_t;

  // TLB 回应（第 0 份复制）
  typedef struct packed {
    logic [PADDR_W-1:0] paddr;
    logic [1:0]         pbmt;
    logic               miss;
    logic               gpf_ld;
    logic               pf_ld;
    logic               af_ld;
  } tlb_resp_t;

  // 发给 DCache 的 L1 预取（L1PrefetchReq）。alias 是 SV 关键字，故字段名带下划线。
  typedef struct packed {
    logic [PADDR_W-1:0] paddr;
    logic [1:0]         alias_;
    logic               confidence;
    logic               is_store;
    logic [2:0]         pf_source_value;
  } l1_pf_req_t;

  // 发给 L2 的预取（L2PrefetchReq）
  typedef struct packed {
    logic [PADDR_W-1:0] addr;
    logic [4:0]         source;
  } l2_pf_req_t;

  // ---- 纯函数 ------------------------------------------------------------------
  // 区域哈希（region_hash_tag）：低 10 位原样，再把 [24:10] 三段 5 位异或成 5 位。
  //   ★region[39:25] 完全不参与★ —— 高位不同、低 25 位相同的两个区域哈希相同，
  //   在表里会被当成「同一项」（这是设计取舍：用 15 位比较器换 40 位）。
  function automatic logic [TAG_W-1:0] region_hash_tag(input logic [REGION_W-1:0] r);
    return {r[14:10] ^ r[19:15] ^ r[24:20], r[9:0]};
  endfunction

  // PriorityEncoder：最低置位的下标；全 0 时 Chisel 的 PriorityMux 落到最后一项 = 15。
  function automatic logic [3:0] lowest_set_line(input logic [BITVEC_W-1:0] v);
    for (int k = 0; k < BITVEC_W; k++)
      if (v[k]) return 4'(k);
    return 4'd15;
  endfunction

  // OHToUInt：独热码转下标。Chisel 的实现是「高低半折叠 OR」，展开后等于
  //   「把所有置位位置的下标按位 OR 起来」—— 独热时就是那个下标，非独热时是它们的 OR。
  function automatic logic [3:0] oh_to_uint16(input logic [15:0] oh);
    logic [3:0] r;
    r = '0;
    for (int k = 0; k < 16; k++)
      if (oh[k]) r |= 4'(k);
    return r;
  endfunction

  function automatic logic [4:0] oh_to_uint32(input logic [31:0] oh);
    logic [4:0] r;
    r = '0;
    for (int k = 0; k < 32; k++)
      if (oh[k]) r |= 5'(k);
    return r;
  endfunction

  // 这一项现在能不能发预取（MLPReqFilterBundle.can_send_pf）：
  //   必须已翻成物理地址；目标是 L1 时只看 bit_vec（L1 靠清 bit_vec 记账），
  //   目标是 L2/L3 时看「bit_vec 里还有没被 sent_vec 标掉的行」。
  function automatic logic can_send_pf(input logic valid, input logic is_vaddr, input logic [1:0] sink,
                                       input logic [BITVEC_W-1:0] bit_vec,
                                       input logic [BITVEC_W-1:0] sent_vec);
    if (sink == SINK_L1) return valid & ~is_vaddr & (|bit_vec);
    else                 return valid & ~is_vaddr & (|(bit_vec & ~sent_vec));
  endfunction

  // 这一项下一条要发的行号（get_pf_addr 里的 candidate）：规则同上。
  function automatic logic [3:0] pf_candidate(input logic [1:0] sink,
                                              input logic [BITVEC_W-1:0] bit_vec,
                                              input logic [BITVEC_W-1:0] sent_vec);
    if (sink == SINK_L1) return lowest_set_line(bit_vec);
    else                 return lowest_set_line(bit_vec & ~sent_vec);
  endfunction

  // 预取地址 = Cat(region, 行号, 6'b0) 截到 48 位 → 只剩 region 的低 38 位。
  function automatic logic [PADDR_W-1:0] pf_addr(input logic [REGION_W-1:0] region,
                                                 input logic [3:0] line);
    return {region[37:0], line, {BLK_OFF_W{1'b0}}};
  endfunction

  // 预取地址所在行在区域内的独热码（get_candidate_oh）
  function automatic logic [BITVEC_W-1:0] line_oh(input logic [PADDR_W-1:0] addr);
    return BITVEC_W'(1) << addr[9:6];
  endfunction

  // Pbmt.isUncache：页表属性 NC(1) 或 IO(2) 都算不可缓存，不预取。
  function automatic logic pbmt_is_uncache(input logic [1:0] pbmt);
    return (pbmt == 2'd1) | (pbmt == 2'd2);
  endfunction

  // ===========================================================================
  //  ValidPseudoLRU(16)：15 位树状态上的「在候选里挑最旧的那个」与「touch 更新」
  // ---------------------------------------------------------------------------
  //  （与 rtl/memblock/Sbuffer.sv 的同名小节是同一棵 rocket-chip 树，这里独立一份，避免跨文件
  //   依赖；两份都是照 rocket-chip util/Replacement.scala 写的。）
  //  树叶布局：最左叶 = way15，最右叶 = way0（Scala 调用处写的是 way(vec.reverse)）。
  //  节点 state 位的语义是「左子树更旧」：两边都有候选时按它选边，只有一边有候选就选那一边
  //  （左 → 本级下标位 1），两边都没有候选时 Scala 的默认值是 Cat(0, 左子结果)。
  //    叶对：15/14→s[11] 13/12→s[10] 11/10→s[8] 9/8→s[7] 7/6→s[4] 5/4→s[3] 3/2→s[1] 1/0→s[0]
  //    四叶：s[12] s[9] s[5] s[2]    八叶：s[13] s[6]    根：s[14]
  // ===========================================================================
  // 一级合并：nsub = 子下标的有效位数（叶对 0 / 四叶 1 / 八叶 2 / 根 3），本级选边位放在它之上。
  function automatic logic [4:0] plru_join(input logic lv, input logic [3:0] lidx,
                                           input logic rv, input logic [3:0] ridx,
                                           input logic s, input int nsub);
    logic       top;
    logic [3:0] sub;
    if (lv & rv)      begin top = s;    sub = s  ? lidx : ridx; end
    else if (lv | rv) begin top = lv;   sub = lv ? lidx : ridx; end
    else              begin top = 1'b0; sub = lidx;             end
    return {lv | rv, 4'((4'(top) << nsub) | sub)};
  endfunction

  localparam int PLRU_PAIR_S [8] = '{11, 10, 8, 7, 4, 3, 1, 0};   // 叶对节点的 state 位
  localparam int PLRU_QUAD_S [4] = '{12, 9, 5, 2};                 // 四叶节点的 state 位

  function automatic logic [3:0] plru_victim(input logic [14:0] st, input logic [15:0] cand);
    logic       pv [8]; logic [3:0] pi [8];
    logic       qv [4]; logic [3:0] qi [4];
    logic       ov [2]; logic [3:0] oi [2];
    logic       rv;     logic [3:0] ri;
    for (int k = 0; k < 8; k++)
      {pv[k], pi[k]} = plru_join(cand[15-2*k], 4'h0, cand[14-2*k], 4'h0, st[PLRU_PAIR_S[k]], 0);
    for (int k = 0; k < 4; k++)
      {qv[k], qi[k]} = plru_join(pv[2*k], pi[2*k], pv[2*k+1], pi[2*k+1], st[PLRU_QUAD_S[k]], 1);
    {ov[0], oi[0]} = plru_join(qv[0], qi[0], qv[1], qi[1], st[13], 2);
    {ov[1], oi[1]} = plru_join(qv[2], qi[2], qv[3], qi[3], st[6],  2);
    {rv, ri}       = plru_join(ov[0], oi[0], ov[1], oi[1], st[14], 3);
    return ri;
  endfunction

  // touch：把被访问 way 路径上的每个节点置成「指向另一侧」（另一侧更旧）
  function automatic logic [14:0] plru_touch(input logic [14:0] st, input logic [3:0] way);
    logic [14:0] ns;
    ns     = st;
    ns[14] = ~way[3];                                         // 根
    if (way[3]) ns[13] = ~way[2]; else ns[6] = ~way[2];        // 八叶
    if (way[3]) begin                                          // 四叶
      if (way[2]) ns[12] = ~way[1]; else ns[9] = ~way[1];
    end else begin
      if (way[2]) ns[5]  = ~way[1]; else ns[2] = ~way[1];
    end
    if (way[3]) begin                                          // 叶对
      if (way[2]) begin if (way[1]) ns[11] = ~way[0]; else ns[10] = ~way[0]; end
      else        begin if (way[1]) ns[8]  = ~way[0]; else ns[7]  = ~way[0]; end
    end else begin
      if (way[2]) begin if (way[1]) ns[4]  = ~way[0]; else ns[3]  = ~way[0]; end
      else        begin if (way[1]) ns[1]  = ~way[0]; else ns[0]  = ~way[0]; end
    end
    return ns;
  endfunction

endpackage

// =============================================================================
//  xs_MutiLevelPrefetchFilter_core —— 可读核
// -----------------------------------------------------------------------------
//  分节：§1 表项结构  §2 替换  §3 入表/去重  §4 TLB 查询  §5 L1 发出  §6 L2/L3 发出  §7 冲刷与死寄存器
//
//  ★寄存器命名★：本核的寄存器名（含 generate 块名 l1_array / l2_array）都与 golden 的展平名
//    对齐（golden 的 l1_array_3_tag ↔ 本核 l1_array[3].tag），Formality 按名字配对；
//    少数 golden 名字本身没有语义的（REG_*、state_reg、*_REG）在声明处注明它是什么。
// =============================================================================
module xs_MutiLevelPrefetchFilter_core
  import mutilevelprefetchfilter_pkg::*;
(
  input  logic           clock,
  input  logic           reset,
  input  logic           enable,             // 总开关：只门控发往 DCache 的那一路
  input  logic           flush,              // 冲刷整张表（本配置上层接常 0，见 wrapper）
  input  logic           confidence,         // 原样带给 DCache 的置信度位
  // 上游：两路区域预取请求
  input  logic           l1_prefetch_req_valid,
  input  stream_pf_req_t l1_prefetch_req,
  input  logic           l2_l3_prefetch_req_valid,
  input  stream_pf_req_t l2_l3_prefetch_req,
  // TLB / PMP
  output logic           tlb_req_valid,
  output tlb_req_t       tlb_req,
  input  logic           tlb_resp_valid,
  input  tlb_resp_t      tlb_resp,
  input  logic           pmp_resp_ld,        // PMP 访问错
  input  logic           pmp_resp_mmio,      // PMP 判为 MMIO
  // 发往 DCache / L2 / L3
  input  logic           l1_req_ready,
  output logic           l1_req_valid,
  output l1_pf_req_t     l1_req,
  output logic           l2_pf_valid,
  output l2_pf_req_t     l2_pf,
  output logic           l3_pf_valid,        // golden 配置里上层不接：wrapper 不引出
  output logic [PADDR_W-1:0] l3_pf_addr
);

  // ---------------------------------------------------------------------------
  //  跨节使用的信号先声明（每一项表项都要看这些「广播」来决定自己怎么更新）
  // ---------------------------------------------------------------------------
  // §3 入表
  logic                s1_l1_valid, s1_l1_hit, s1_l1_alloc, s1_l1_update;
  logic [3:0]          s1_l1_index;
  logic                s1_l2_valid, s1_l2_hit, s1_l2_alloc, s1_l2_update;
  logic [3:0]          s1_l2_index;
  logic [TAG_W-1:0]    s1_l1_prefetch_req_tag,    s1_l2_prefetch_req_tag;
  logic [REGION_W-1:0] s1_l1_prefetch_req_region, s1_l2_prefetch_req_region;
  logic [BITVEC_W-1:0] s1_l1_prefetch_req_bit_vec, s1_l2_prefetch_req_bit_vec;
  logic [1:0]          s1_l1_prefetch_req_alias;
  logic [2:0]          s1_l1_prefetch_req_source_value, s1_l2_prefetch_req_source_value;
  logic [1:0]          s1_l2_prefetch_req_sink;
  logic [TAG_W-1:0]    s0_l1_region_hash, s0_l2_region_hash;
  logic [REGION_W-1:0] s1_l1_region,      s1_l2_region;
  logic [TAG_W-1:0]    s1_l1_region_hash, s1_l2_region_hash;
  logic                s0_l1_valid, s0_l2_valid;
  // §4 TLB 回填
  logic                s3_tlb_resp_valid, s3_tlb_evict;
  logic [4:0]          s3_tlb_update_index;
  logic                s3_tlb_resp_miss;
  logic                s3_drop;
  logic [REGION_W-1:0] s3_paddr_region;
  // §5 L1 发出
  logic                s0_pf_fire, s1_pf_fire;
  logic [3:0]          l1_pf_chosen, s1_pf_index;
  logic [BITVEC_W-1:0] s0_pf_candidate_oh, s1_pf_candidate_oh;
  // §6 L2/L3 发出
  logic                l2_arb_out_valid, l3_arb_out_valid;
  logic [3:0]          l2_arb_chosen, l3_arb_chosen;
  logic [PADDR_W-1:0]  l2_arb_out_addr;
  logic [4:0]          l2_arb_out_source;
  // §7 冲刷：golden 名 REG_6..REG_37 = RegNext(io.flush)，每项一份（6..21 = L1 表，22..37 = L2 表）
  logic                REG [6:37];

  // 每一项对外导出的「视图」（由各项自己在 §1 的 generate 块里算好）
  logic [L1_SIZE-1:0]  l1_s0_match, l1_can_send, l1_is_vaddr, l1_all_sent;
  logic [L2_SIZE-1:0]  l2_s0_match, l2_can_send, l2_is_vaddr, l2_all_sent;
  logic [L2_SIZE-1:0]  l2_sink_is_l2, l2_sink_is_l3;
  logic [PADDR_W-1:0]  l1_pf_addr [L1_SIZE];
  logic [PADDR_W-1:0]  l2_pf_addr_e [L2_SIZE];
  logic [1:0]          l1_alias [L1_SIZE];
  logic [2:0]          l1_source [L1_SIZE];
  logic [4:0]          l2_reqsource [L2_SIZE];
  logic [REGION_W-1:0] l1_region_e [L1_SIZE], l2_region_e [L2_SIZE];

  // 两个 s3 回填目标：TLB 仲裁号 0..15 落在 L1 表，16..31 落在 L2 表（低 4 位是表内项号）
  logic s3_fill;                  // 本拍 s3 真的要回填某一项
  assign s3_fill = s3_tlb_resp_valid & ~s3_tlb_evict;

  // ===========================================================================
  //  §1 表项结构（MLPReqFilterBundle）
  // ---------------------------------------------------------------------------
  //  每一项在这里用一个 generate 块表达，块名就是 golden 的数组名：
  //    tag          15 位区域哈希（入表时算好存着，CAM 只比它）
  //    region       区域地址：入表时是虚拟 region；TLB 回来后换成 {2'b0, paddr[47:10]}
  //    bit_vec      还要发的行；sent_vec 已经仲裁出去的行
  //    sink         目标层级；alias_ 区域的 vaddr[13:12]（给 DCache 处理别名，只有 L1 表有）
  //    is_vaddr     1 = region 还是虚地址，要先查 TLB；0 = 已是物理地址，可以发预取
  //    source_value 预取来源（stride / stream …）
  //  除 valid 外全部不复位（golden 同样）：valid=0 时这些值一律不被看。
  //
  //  每一项在同一拍里可能被四件事同时改，写法按 Chisel「后写者胜」的顺序排：
  //    ① s1 入表（alloc 整条覆盖 / update 合并 bit_vec）
  //    ② s3 TLB 回填（换物理 region；出错就作废）
  //    ③ 发出仲裁成功 → 置 sent_vec
  //    ④（仅 L1）s1 真的发给 DCache → 清 bit_vec 里那一行
  // ===========================================================================
  logic l1_valids [L1_SIZE];
  logic l2_valids [L2_SIZE];

  // golden 名 l1_opt_replace_vec_REG / _REG_1 … _REG_31：每项两位，
  //   [2i]   = RegNext(valid)
  //   [2i+1] = RegNext(sent_vec 16 位全置)   （「这一项的行都发完了」）
  //   合起来是 §2 的 may_be_replace 的打拍部分。L2 表同理。
  logic l1_opt_replace_vec_REG [2*L1_SIZE];
  logic l2_opt_replace_vec_REG [2*L2_SIZE];

  for (genvar i = 0; i < L1_SIZE; i++) begin : l1_array
    logic [TAG_W-1:0]    tag;
    logic [REGION_W-1:0] region;
    logic [BITVEC_W-1:0] bit_vec;
    logic [BITVEC_W-1:0] sent_vec;
    logic [1:0]          sink;
    logic [1:0]          alias_;
    logic                is_vaddr;
    logic [2:0]          source_value;

    wire s1_is_me = (s1_l1_index == 4'(i));
    wire s3_is_me = s3_fill & ~s3_tlb_update_index[4] & (s3_tlb_update_index[3:0] == 4'(i));

    always_ff @(posedge clock) begin
      // ① s1 入表。L1 请求的 sink 恒为 SINK_L1（上游如此，golden 里已折成常量），
      //    所以 update 里「新 sink 更靠近核」的判据就是「我原来的 sink 不是 L1」。
      if (s1_l1_alloc & s1_is_me) begin
        tag          <= s1_l1_prefetch_req_tag;
        region       <= s1_l1_prefetch_req_region;
        bit_vec      <= s1_l1_prefetch_req_bit_vec;
        sent_vec     <= '0;
        sink         <= SINK_L1;
        alias_       <= s1_l1_prefetch_req_alias;
        is_vaddr     <= 1'b1;
        source_value <= s1_l1_prefetch_req_source_value;
      end else if (s1_l1_update & s1_is_me) begin
        if (SINK_L1 < sink) begin
          // 目标层级升级：已经按旧层级发出去的行（sent_vec）也要按新层级重发，
          // 所以先把它们从 bit_vec 里剔掉再并入新请求 —— 这是 Scala 的原话，照写。
          bit_vec <= (bit_vec & ~sent_vec) | s1_l1_prefetch_req_bit_vec;
          sink    <= SINK_L1;
        end else begin
          bit_vec <= bit_vec | s1_l1_prefetch_req_bit_vec;
        end
      end
      // ② s3 TLB 回填
      if (s3_is_me) begin
        is_vaddr <= s3_tlb_resp_miss;               // TLB miss：保持虚地址，下次再查
        if (!s3_tlb_resp_miss) begin
          region <= s3_paddr_region;
          if (s3_drop) begin                        // invalidate：让它再也发不出东西
            if (sink == SINK_L1) bit_vec  <= '0;
            else                 sent_vec <= '1;
            is_vaddr <= 1'b0;
          end
        end
      end
      // ③ L1 仲裁器选中本项：记下这一行已经「在路上」
      if (s0_pf_fire & (l1_pf_chosen == 4'(i)))
        sent_vec <= sent_vec | s0_pf_candidate_oh;
      // ④ s1 真的发给 DCache：从 bit_vec 里划掉这一行
      if (s1_pf_fire & (s1_pf_index == 4'(i)))
        bit_vec <= bit_vec & ~s1_pf_candidate_oh;
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) l1_valids[i] <= 1'b0;
      else begin
        if (s1_l1_alloc & s1_is_me)                     l1_valids[i] <= 1'b1;
        if (s3_is_me & ~s3_tlb_resp_miss & s3_drop)     l1_valids[i] <= 1'b0;
        if (REG[6 + i])                                 l1_valids[i] <= 1'b0;
      end
    end

    always_ff @(posedge clock) begin
      l1_opt_replace_vec_REG[2*i]   <= l1_valids[i];
      l1_opt_replace_vec_REG[2*i+1] <= &sent_vec;     // PopCount(sent_vec) === 16
    end

    // ---- 本项对外的视图 ----
    assign l1_s0_match[i] = (tag == s0_l1_region_hash) & l1_valids[i] & s0_l1_valid;
    assign l1_can_send[i] = can_send_pf(l1_valids[i], is_vaddr, sink, bit_vec, sent_vec);
    assign l1_is_vaddr[i] = is_vaddr;
    assign l1_all_sent[i] = l1_opt_replace_vec_REG[2*i] & l1_opt_replace_vec_REG[2*i+1];
    assign l1_pf_addr[i]  = pf_addr(region, pf_candidate(sink, bit_vec, sent_vec));
    assign l1_alias[i]    = alias_;
    assign l1_source[i]   = source_value;
    assign l1_region_e[i] = region;
  end

  for (genvar i = 0; i < L2_SIZE; i++) begin : l2_array
    logic [TAG_W-1:0]    tag;
    logic [REGION_W-1:0] region;
    logic [BITVEC_W-1:0] bit_vec;
    logic [BITVEC_W-1:0] sent_vec;
    logic [1:0]          sink;
    logic                is_vaddr;
    logic [2:0]          source_value;

    wire s1_is_me = (s1_l2_index == 4'(i));
    wire s3_is_me = s3_fill & s3_tlb_update_index[4] & (s3_tlb_update_index[3:0] == 4'(i));

    always_ff @(posedge clock) begin
      // ① s1 入表
      if (s1_l2_alloc & s1_is_me) begin
        tag          <= s1_l2_prefetch_req_tag;
        region       <= s1_l2_prefetch_req_region;
        bit_vec      <= s1_l2_prefetch_req_bit_vec;
        sent_vec     <= '0;
        sink         <= s1_l2_prefetch_req_sink;
        is_vaddr     <= 1'b1;
        source_value <= s1_l2_prefetch_req_source_value;
      end else if (s1_l2_update & s1_is_me) begin
        if (s1_l2_prefetch_req_sink < sink) begin   // 目标层级升级（L3 → L2），见 L1 表的注释
          bit_vec <= (bit_vec & ~sent_vec) | s1_l2_prefetch_req_bit_vec;
          sink    <= s1_l2_prefetch_req_sink;
        end else begin
          bit_vec <= bit_vec | s1_l2_prefetch_req_bit_vec;
        end
      end
      // ② s3 TLB 回填
      if (s3_is_me) begin
        is_vaddr <= s3_tlb_resp_miss;
        if (!s3_tlb_resp_miss) begin
          region <= s3_paddr_region;
          if (s3_drop) begin
            if (sink == SINK_L1) bit_vec  <= '0;
            else                 sent_vec <= '1;
            is_vaddr <= 1'b0;
          end
        end
      end
      // ③ L2 仲裁器 / L3 仲裁器选中本项（两者 sink 不同，不会同拍选中同一项；
      //    Scala 里 L3 写在后面，照顺序写）
      if (l2_arb_out_valid & (l2_arb_chosen == 4'(i)))
        sent_vec <= sent_vec | line_oh(l2_arb_out_addr);
      if (l3_arb_out_valid & (l3_arb_chosen == 4'(i)))
        sent_vec <= sent_vec | line_oh(l3_pf_addr);
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) l2_valids[i] <= 1'b0;
      else begin
        if (s1_l2_alloc & s1_is_me)                     l2_valids[i] <= 1'b1;
        if (s3_is_me & ~s3_tlb_resp_miss & s3_drop)     l2_valids[i] <= 1'b0;
        if (REG[22 + i])                                l2_valids[i] <= 1'b0;
      end
    end

    always_ff @(posedge clock) begin
      l2_opt_replace_vec_REG[2*i]   <= l2_valids[i];
      l2_opt_replace_vec_REG[2*i+1] <= &sent_vec;
    end

    // ---- 本项对外的视图 ----
    assign l2_s0_match[i]   = (tag == s0_l2_region_hash) & l2_valids[i] & s0_l2_valid;
    assign l2_can_send[i]   = can_send_pf(l2_valids[i], is_vaddr, sink, bit_vec, sent_vec);
    assign l2_is_vaddr[i]   = is_vaddr;
    assign l2_all_sent[i]   = l2_opt_replace_vec_REG[2*i] & l2_opt_replace_vec_REG[2*i+1];
    assign l2_pf_addr_e[i]  = pf_addr(region, pf_candidate(sink, bit_vec, sent_vec));
    assign l2_sink_is_l2[i] = (sink == SINK_L2);
    assign l2_sink_is_l3[i] = (sink == SINK_L3);
    assign l2_region_e[i]   = region;
    // 来源编码翻成 L2 的 reqSource（MuxLookup，默认 Unknown）
    assign l2_reqsource[i]  = (source_value == L1_HW_PREFETCH_STREAM) ? PF2L2_STREAM :
                              (source_value == L1_HW_PREFETCH_STRIDE) ? PF2L2_STRIDE : PF2L2_UNKNOWN;
  end

  // ===========================================================================
  //  §2 替换：先挑「可以放心覆盖」的项，挑不出再退化成全体 PLRU
  // ---------------------------------------------------------------------------
  //  may_be_replace = !valid || (上一拍 valid && 上一拍 sent_vec 全置)
  //  （后半句用打过一拍的值：golden 如此，于是「刚发完」的项要晚一拍才被当成可替换。）
  //  ValidPseudoLRU 只在这些候选里挑最旧的；一个候选都没有时候选 = 全体。
  //  golden 名 state_reg = L1 表的 PLRU 树，state_reg_1 = L2 表的，异步复位成 0。
  // ===========================================================================
  logic [14:0]        state_reg, state_reg_1;
  logic [L1_SIZE-1:0] l1_opt_replace_vec, l1_real_replace_vec;
  logic [L2_SIZE-1:0] l2_opt_replace_vec, l2_real_replace_vec;
  always_comb begin
    for (int i = 0; i < L1_SIZE; i++) l1_opt_replace_vec[i] = ~l1_valids[i] | l1_all_sent[i];
    for (int i = 0; i < L2_SIZE; i++) l2_opt_replace_vec[i] = ~l2_valids[i] | l2_all_sent[i];
  end
  assign l1_real_replace_vec = (|l1_opt_replace_vec) ? l1_opt_replace_vec : '1;
  assign l2_real_replace_vec = (|l2_opt_replace_vec) ? l2_opt_replace_vec : '1;

  wire [3:0] l1_victim = plru_victim(state_reg,   l1_real_replace_vec);
  wire [3:0] l2_victim = plru_victim(state_reg_1, l2_real_replace_vec);

  // ===========================================================================
  //  §3 入表/去重：s0 查表选项号，s1 写表（两表各一条完全对称的流水）
  // ---------------------------------------------------------------------------
  //  s0：算 15 位哈希，与表里每个有效项的 tag 比（l*_s0_match 由各项自己算）。
  //      命中 → 项号 = 命中位置；不中 → 项号 = §2 选出的替换项。
  //      只要 s0 有效（真的入表）就 touch PLRU —— 命中也 touch。
  //  s1：不中 → alloc（整条覆盖、valid 置 1）；命中 → update（并入 bit_vec）。
  //  s0 反压：如果 s1 正在 alloc 一个同哈希的区域，s0 这条就拒收（can_accept=0）——
  //      否则它在 s0 看不到这项（s1 还没写进表），会再 alloc 一份，同一区域占两项。
  //      上游不重发：被拒的请求直接丢掉。
  // ===========================================================================
  // ---- L1 表 ----
  wire s0_l1_can_accept = ~(s1_l1_valid & s1_l1_alloc & (s0_l1_region_hash == s1_l1_region_hash));
  assign s0_l1_region_hash = region_hash_tag(l1_prefetch_req.region);
  assign s0_l1_valid       = l1_prefetch_req_valid & s0_l1_can_accept;
  wire       s0_l1_hit   = |l1_s0_match;
  wire [3:0] s0_l1_index = s0_l1_hit ? oh_to_uint16(l1_s0_match) : l1_victim;

  // s1 流水寄存器（golden 里区域和哈希各存了两份：s1_l1_region/_region_hash 与
  //   s1_l1_prefetch_req_region/_tag，值恒等；照抄，不合并）
  always_ff @(posedge clock) begin
    s1_l1_valid <= s0_l1_valid;
    if (s0_l1_valid) begin
      s1_l1_region                    <= l1_prefetch_req.region;
      s1_l1_region_hash               <= s0_l1_region_hash;
      s1_l1_hit                       <= s0_l1_hit;
      s1_l1_index                     <= s0_l1_index;
      s1_l1_prefetch_req_tag          <= s0_l1_region_hash;
      s1_l1_prefetch_req_region       <= l1_prefetch_req.region;
      s1_l1_prefetch_req_bit_vec      <= l1_prefetch_req.bit_vec;
      s1_l1_prefetch_req_alias        <= l1_prefetch_req.region[3:2];   // vaddr[13:12]
      s1_l1_prefetch_req_source_value <= l1_prefetch_req.source_value;
    end
  end
  assign s1_l1_alloc  = s1_l1_valid & ~s1_l1_hit;
  assign s1_l1_update = s1_l1_valid &  s1_l1_hit;

  // ---- L2/L3 表 ----
  wire s0_l2_can_accept = ~(s1_l2_valid & s1_l2_alloc & (s0_l2_region_hash == s1_l2_region_hash));
  assign s0_l2_region_hash = region_hash_tag(l2_l3_prefetch_req.region);
  assign s0_l2_valid       = l2_l3_prefetch_req_valid & s0_l2_can_accept;
  wire       s0_l2_hit   = |l2_s0_match;
  wire [3:0] s0_l2_index = s0_l2_hit ? oh_to_uint16(l2_s0_match) : l2_victim;

  always_ff @(posedge clock) begin
    s1_l2_valid <= s0_l2_valid;
    if (s0_l2_valid) begin
      s1_l2_region                    <= l2_l3_prefetch_req.region;
      s1_l2_region_hash               <= s0_l2_region_hash;
      s1_l2_hit                       <= s0_l2_hit;
      s1_l2_index                     <= s0_l2_index;
      s1_l2_prefetch_req_tag          <= s0_l2_region_hash;
      s1_l2_prefetch_req_region       <= l2_l3_prefetch_req.region;
      s1_l2_prefetch_req_bit_vec      <= l2_l3_prefetch_req.bit_vec;
      s1_l2_prefetch_req_sink         <= l2_l3_prefetch_req.sink;
      s1_l2_prefetch_req_source_value <= l2_l3_prefetch_req.source_value;
    end
  end
  assign s1_l2_alloc  = s1_l2_valid & ~s1_l2_hit;
  assign s1_l2_update = s1_l2_valid &  s1_l2_hit;

  // PLRU touch（异步复位）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state_reg   <= '0;
      state_reg_1 <= '0;
    end else begin
      if (s0_l1_valid) state_reg   <= plru_touch(state_reg,   s0_l1_index);
      if (s0_l2_valid) state_reg_1 <= plru_touch(state_reg_1, s0_l2_index);
    end
  end

  // ===========================================================================
  //  §4 TLB 查询（s0 仲裁 → s1 发请求 → s2 收回应 → s3 收 PMP 并回填）
  // ---------------------------------------------------------------------------
  //  s0：32 路（两表合起来）轮转仲裁，候选 = 有效 && is_vaddr && 不在查询途中 && 本拍没被 s1 alloc 覆盖。
  //      「在查询途中」= 最近三拍内自己赢过仲裁（s1/s2/s3_tlb_fire_vec），防止同一项重复查。
  //  s1：把赢家的请求打一拍发给 TLB；如果这一拍它正被 s1 alloc 覆盖（evict），请求撤掉。
  //  s2：TLB 回应到达（下标随 s1 打过来）；s3：回应与下标再打一拍，同拍收 PMP 的判定。
  //      s2 那拍若该项又被 alloc 覆盖，s3 的回填作废（s3_tlb_evict）。
  //  s3 的回填见 §1 ②：miss 保持虚地址；否则换物理 region，遇到
  //      缺页/访问错/客户页错/MMIO/不可缓存/PMP 访问错 就作废（s3_drop）。
  // ===========================================================================
  logic [MLP_SIZE-1:0] tlb_in_valid, tlb_in_ready, s0_tlb_fire_vec;
  logic [VADDR_W-1:0]  tlb_in_vaddr [MLP_SIZE];
  logic                tlb_arb_out_valid;
  logic [VADDR_W-1:0]  tlb_arb_out_vaddr;

  // golden 名 s1/s2/s3_tlb_fire_vec_r：GatedValidRegNext —— 值变了才打拍（门控时钟友好），
  //   功能上等于带复位的 RegNext。
  logic [MLP_SIZE-1:0] s1_tlb_fire_vec_r, s2_tlb_fire_vec_r, s3_tlb_fire_vec_r;

  // s1 alloc 正在覆盖的那一项（按 TLB 仲裁号编：L2 表加 16）
  wire [4:0] s1_l1_alloc_tlb_idx = {1'b0, s1_l1_index};
  wire [4:0] s1_l2_alloc_tlb_idx = {1'b1, s1_l2_index};
  function automatic logic alloc_hits(input logic l1_alloc, input logic [4:0] l1_idx,
                                      input logic l2_alloc, input logic [4:0] l2_idx,
                                      input logic [4:0] idx);
    return (l1_alloc & (l1_idx == idx)) | (l2_alloc & (l2_idx == idx));
  endfunction

  logic [MLP_SIZE-1:0] not_tlbing_vec, tlb_evict_vec;
  assign not_tlbing_vec = ~s1_tlb_fire_vec_r & ~s2_tlb_fire_vec_r & ~s3_tlb_fire_vec_r;
  always_comb
    for (int i = 0; i < MLP_SIZE; i++) begin
      tlb_evict_vec[i] = alloc_hits(s1_l1_alloc, s1_l1_alloc_tlb_idx,
                                    s1_l2_alloc, s1_l2_alloc_tlb_idx, 5'(i));
      if (i < L1_SIZE) begin
        tlb_in_valid[i] = l1_valids[i] & l1_is_vaddr[i] & not_tlbing_vec[i] & ~tlb_evict_vec[i];
        tlb_in_vaddr[i] = {l1_region_e[i], 10'b0};            // get_tlb_va：区域首地址
      end else begin
        tlb_in_valid[i] = l2_valids[i-L1_SIZE] & l2_is_vaddr[i-L1_SIZE] & not_tlbing_vec[i]
                        & ~tlb_evict_vec[i];
        tlb_in_vaddr[i] = {l2_region_e[i-L1_SIZE], 10'b0};
      end
    end
  assign s0_tlb_fire_vec = tlb_in_valid & tlb_in_ready;

  // BEGIN GENERATED(tlb_req_arb) —— verif/ut/MutiLevelPrefetchFilter/gen.py
  RRArbiterInit_7 tlb_req_arb (
    .clock               (clock),
    .reset               (reset),
    .io_in_0_ready       (tlb_in_ready[0]),
    .io_in_0_valid       (tlb_in_valid[0]),
    .io_in_0_bits_vaddr  (tlb_in_vaddr[0]),
    .io_in_1_ready       (tlb_in_ready[1]),
    .io_in_1_valid       (tlb_in_valid[1]),
    .io_in_1_bits_vaddr  (tlb_in_vaddr[1]),
    .io_in_2_ready       (tlb_in_ready[2]),
    .io_in_2_valid       (tlb_in_valid[2]),
    .io_in_2_bits_vaddr  (tlb_in_vaddr[2]),
    .io_in_3_ready       (tlb_in_ready[3]),
    .io_in_3_valid       (tlb_in_valid[3]),
    .io_in_3_bits_vaddr  (tlb_in_vaddr[3]),
    .io_in_4_ready       (tlb_in_ready[4]),
    .io_in_4_valid       (tlb_in_valid[4]),
    .io_in_4_bits_vaddr  (tlb_in_vaddr[4]),
    .io_in_5_ready       (tlb_in_ready[5]),
    .io_in_5_valid       (tlb_in_valid[5]),
    .io_in_5_bits_vaddr  (tlb_in_vaddr[5]),
    .io_in_6_ready       (tlb_in_ready[6]),
    .io_in_6_valid       (tlb_in_valid[6]),
    .io_in_6_bits_vaddr  (tlb_in_vaddr[6]),
    .io_in_7_ready       (tlb_in_ready[7]),
    .io_in_7_valid       (tlb_in_valid[7]),
    .io_in_7_bits_vaddr  (tlb_in_vaddr[7]),
    .io_in_8_ready       (tlb_in_ready[8]),
    .io_in_8_valid       (tlb_in_valid[8]),
    .io_in_8_bits_vaddr  (tlb_in_vaddr[8]),
    .io_in_9_ready       (tlb_in_ready[9]),
    .io_in_9_valid       (tlb_in_valid[9]),
    .io_in_9_bits_vaddr  (tlb_in_vaddr[9]),
    .io_in_10_ready      (tlb_in_ready[10]),
    .io_in_10_valid      (tlb_in_valid[10]),
    .io_in_10_bits_vaddr (tlb_in_vaddr[10]),
    .io_in_11_ready      (tlb_in_ready[11]),
    .io_in_11_valid      (tlb_in_valid[11]),
    .io_in_11_bits_vaddr (tlb_in_vaddr[11]),
    .io_in_12_ready      (tlb_in_ready[12]),
    .io_in_12_valid      (tlb_in_valid[12]),
    .io_in_12_bits_vaddr (tlb_in_vaddr[12]),
    .io_in_13_ready      (tlb_in_ready[13]),
    .io_in_13_valid      (tlb_in_valid[13]),
    .io_in_13_bits_vaddr (tlb_in_vaddr[13]),
    .io_in_14_ready      (tlb_in_ready[14]),
    .io_in_14_valid      (tlb_in_valid[14]),
    .io_in_14_bits_vaddr (tlb_in_vaddr[14]),
    .io_in_15_ready      (tlb_in_ready[15]),
    .io_in_15_valid      (tlb_in_valid[15]),
    .io_in_15_bits_vaddr (tlb_in_vaddr[15]),
    .io_in_16_ready      (tlb_in_ready[16]),
    .io_in_16_valid      (tlb_in_valid[16]),
    .io_in_16_bits_vaddr (tlb_in_vaddr[16]),
    .io_in_17_ready      (tlb_in_ready[17]),
    .io_in_17_valid      (tlb_in_valid[17]),
    .io_in_17_bits_vaddr (tlb_in_vaddr[17]),
    .io_in_18_ready      (tlb_in_ready[18]),
    .io_in_18_valid      (tlb_in_valid[18]),
    .io_in_18_bits_vaddr (tlb_in_vaddr[18]),
    .io_in_19_ready      (tlb_in_ready[19]),
    .io_in_19_valid      (tlb_in_valid[19]),
    .io_in_19_bits_vaddr (tlb_in_vaddr[19]),
    .io_in_20_ready      (tlb_in_ready[20]),
    .io_in_20_valid      (tlb_in_valid[20]),
    .io_in_20_bits_vaddr (tlb_in_vaddr[20]),
    .io_in_21_ready      (tlb_in_ready[21]),
    .io_in_21_valid      (tlb_in_valid[21]),
    .io_in_21_bits_vaddr (tlb_in_vaddr[21]),
    .io_in_22_ready      (tlb_in_ready[22]),
    .io_in_22_valid      (tlb_in_valid[22]),
    .io_in_22_bits_vaddr (tlb_in_vaddr[22]),
    .io_in_23_ready      (tlb_in_ready[23]),
    .io_in_23_valid      (tlb_in_valid[23]),
    .io_in_23_bits_vaddr (tlb_in_vaddr[23]),
    .io_in_24_ready      (tlb_in_ready[24]),
    .io_in_24_valid      (tlb_in_valid[24]),
    .io_in_24_bits_vaddr (tlb_in_vaddr[24]),
    .io_in_25_ready      (tlb_in_ready[25]),
    .io_in_25_valid      (tlb_in_valid[25]),
    .io_in_25_bits_vaddr (tlb_in_vaddr[25]),
    .io_in_26_ready      (tlb_in_ready[26]),
    .io_in_26_valid      (tlb_in_valid[26]),
    .io_in_26_bits_vaddr (tlb_in_vaddr[26]),
    .io_in_27_ready      (tlb_in_ready[27]),
    .io_in_27_valid      (tlb_in_valid[27]),
    .io_in_27_bits_vaddr (tlb_in_vaddr[27]),
    .io_in_28_ready      (tlb_in_ready[28]),
    .io_in_28_valid      (tlb_in_valid[28]),
    .io_in_28_bits_vaddr (tlb_in_vaddr[28]),
    .io_in_29_ready      (tlb_in_ready[29]),
    .io_in_29_valid      (tlb_in_valid[29]),
    .io_in_29_bits_vaddr (tlb_in_vaddr[29]),
    .io_in_30_ready      (tlb_in_ready[30]),
    .io_in_30_valid      (tlb_in_valid[30]),
    .io_in_30_bits_vaddr (tlb_in_vaddr[30]),
    .io_in_31_ready      (tlb_in_ready[31]),
    .io_in_31_valid      (tlb_in_valid[31]),
    .io_in_31_bits_vaddr (tlb_in_vaddr[31]),
    .io_out_valid        (tlb_arb_out_valid),
    .io_out_bits_vaddr   (tlb_arb_out_vaddr)
  );
  // END GENERATED

  // ---- s1：发请求 ----
  logic                s1_tlb_req_valid_last_REG;   // golden 名：GatedValidRegNext(仲裁 out.valid)
  logic [VADDR_W-1:0]  s1_tlb_req_bits_vaddr;
  logic [63:0]         s1_tlb_req_bits_fullva;
  logic                s1_tlb_req_bits_checkfullva;
  logic [2:0]          s1_tlb_req_bits_cmd;
  logic                s1_tlb_req_bits_hyperinst;
  logic                s1_tlb_req_bits_hlvx;
  logic                s1_tlb_req_bits_kill;
  logic                s1_tlb_req_bits_isPrefetch;
  logic                s1_tlb_req_bits_no_translate;
  logic [PADDR_W-1:0]  s1_tlb_req_bits_pmp_addr;
  logic                s1_tlb_req_bits_frm_mabuf;
  logic                s1_tlb_req_bits_debug_robIdx_flag;
  logic [7:0]          s1_tlb_req_bits_debug_robIdx_value;
  logic                s1_tlb_req_bits_debug_isFirstIssue;
  logic [4:0]          s1_tlb_req_index;
  logic [4:0]          s2_tlb_update_index;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_tlb_fire_vec_r         <= '0;
      s2_tlb_fire_vec_r         <= '0;
      s3_tlb_fire_vec_r         <= '0;
      s1_tlb_req_valid_last_REG <= 1'b0;
    end else begin
      if (s0_tlb_fire_vec   != s1_tlb_fire_vec_r) s1_tlb_fire_vec_r <= s0_tlb_fire_vec;
      if (s1_tlb_fire_vec_r != s2_tlb_fire_vec_r) s2_tlb_fire_vec_r <= s1_tlb_fire_vec_r;
      if (s2_tlb_fire_vec_r != s3_tlb_fire_vec_r) s3_tlb_fire_vec_r <= s2_tlb_fire_vec_r;
      s1_tlb_req_valid_last_REG <= tlb_arb_out_valid;
    end
  end

  // 请求内容：vaddr 来自仲裁器，其余字段是常量（read / isPrefetch）或 DontCare（golden 取 0）
  always_ff @(posedge clock) begin
    if (tlb_arb_out_valid) begin
      s1_tlb_req_bits_vaddr              <= tlb_arb_out_vaddr;
      s1_tlb_req_bits_fullva             <= 64'h0;
      s1_tlb_req_bits_checkfullva        <= 1'b0;
      s1_tlb_req_bits_cmd                <= 3'h0;       // TlbCmd.read
      s1_tlb_req_bits_hyperinst          <= 1'b0;
      s1_tlb_req_bits_hlvx               <= 1'b0;
      s1_tlb_req_bits_kill               <= 1'b0;
      s1_tlb_req_bits_isPrefetch         <= 1'b1;
      s1_tlb_req_bits_no_translate       <= 1'b0;
      s1_tlb_req_bits_pmp_addr           <= '0;
      s1_tlb_req_bits_frm_mabuf          <= 1'b0;
      s1_tlb_req_bits_debug_robIdx_flag  <= 1'b0;
      s1_tlb_req_bits_debug_robIdx_value <= 8'h0;
      s1_tlb_req_bits_debug_isFirstIssue <= 1'b0;
      s1_tlb_req_index                   <= oh_to_uint32(s0_tlb_fire_vec);
    end
    if (s1_tlb_req_valid_last_REG)
      s2_tlb_update_index <= s1_tlb_req_index;
  end

  wire s1_tlb_evict = alloc_hits(s1_l1_alloc, s1_l1_alloc_tlb_idx,
                                 s1_l2_alloc, s1_l2_alloc_tlb_idx, s1_tlb_req_index);
  assign tlb_req_valid = s1_tlb_req_valid_last_REG & ~s1_tlb_evict;
  assign tlb_req = '{vaddr:              s1_tlb_req_bits_vaddr,
                     fullva:             s1_tlb_req_bits_fullva,
                     checkfullva:        s1_tlb_req_bits_checkfullva,
                     cmd:                s1_tlb_req_bits_cmd,
                     hyperinst:          s1_tlb_req_bits_hyperinst,
                     hlvx:               s1_tlb_req_bits_hlvx,
                     kill:               s1_tlb_req_bits_kill,
                     isPrefetch:         s1_tlb_req_bits_isPrefetch,
                     no_translate:       s1_tlb_req_bits_no_translate,
                     pmp_addr:           s1_tlb_req_bits_pmp_addr,
                     frm_mabuf:          s1_tlb_req_bits_frm_mabuf,
                     debug_robIdx_flag:  s1_tlb_req_bits_debug_robIdx_flag,
                     debug_robIdx_value: s1_tlb_req_bits_debug_robIdx_value,
                     debug_isFirstIssue: s1_tlb_req_bits_debug_isFirstIssue};

  // ---- s2 / s3：收回应 ----
  wire s2_tlb_evict = alloc_hits(s1_l1_alloc, s1_l1_alloc_tlb_idx,
                                 s1_l2_alloc, s1_l2_alloc_tlb_idx, s2_tlb_update_index);
  logic [PADDR_W-1:0] s3_tlb_resp_paddr_0;
  logic [1:0]         s3_tlb_resp_pbmt_0;
  logic               s3_tlb_resp_excp_0_gpf_ld, s3_tlb_resp_excp_0_pf_ld, s3_tlb_resp_excp_0_af_ld;
  always_ff @(posedge clock) begin
    s3_tlb_resp_valid <= tlb_resp_valid;
    if (tlb_resp_valid) begin
      s3_tlb_resp_paddr_0       <= tlb_resp.paddr;
      s3_tlb_resp_pbmt_0        <= tlb_resp.pbmt;
      s3_tlb_resp_miss          <= tlb_resp.miss;
      s3_tlb_resp_excp_0_gpf_ld <= tlb_resp.gpf_ld;
      s3_tlb_resp_excp_0_pf_ld  <= tlb_resp.pf_ld;
      s3_tlb_resp_excp_0_af_ld  <= tlb_resp.af_ld;
      s3_tlb_update_index       <= s2_tlb_update_index;
    end
    s3_tlb_evict <= s2_tlb_evict;
  end

  wire s3_update_valid = s3_tlb_resp_valid & ~s3_tlb_evict & ~s3_tlb_resp_miss;
  assign s3_drop = s3_update_valid &
                   (s3_tlb_resp_excp_0_pf_ld | s3_tlb_resp_excp_0_gpf_ld | s3_tlb_resp_excp_0_af_ld |
                    pmp_resp_mmio | pbmt_is_uncache(s3_tlb_resp_pbmt_0) | pmp_resp_ld);
  assign s3_paddr_region = {2'b0, s3_tlb_resp_paddr_0[PADDR_W-1:10]};

  // ===========================================================================
  //  §5 L1 发出（s0 仲裁 → s1 发给 DCache）
  // ---------------------------------------------------------------------------
  //  s0：16 路轮转仲裁，候选 = can_send_pf && 本拍没被 s1 alloc 覆盖；每项报出自己 bit_vec 里
  //      最低的那一行。赢家：sent_vec 置上这一行（§1 ③）。s1 空着或能走时才接新赢家。
  //  s1：打一拍后发给 DCache。若这一拍本项正被 s1 入表 alloc 或 update，这次发送就作废
  //      （bit_vec 刚被改写，不能再清）——但 s1 照样被腾空（can_go=0 时才留着），
  //      bit_vec 那一行没被清，下次还会再发。真发出（fire）才清 bit_vec（§1 ④）。
  //  ★为什么 L1 用「清 bit_vec」而 L2/L3 用「置 sent_vec」★：Scala 的注释说 L1 不看 sent_vec，
  //      是为了「给 L1 多发一些预取」—— sent_vec 只在 sink 从别的层级升级成 L1 时起作用。
  //  发给 DCache 前还要过两道闸：地址落在物理内存范围里（PmemRanges）、总开关 enable。
  // ===========================================================================
  logic [L1_SIZE-1:0] l1_arb_in_valid;
  l1_pf_req_t         l1_arb_in_bits [L1_SIZE];
  logic               l1_arb_out_valid, l1_arb_out_ready;
  logic [PADDR_W-1:0] l1_arb_out_paddr;
  logic [1:0]         l1_arb_out_alias;
  logic               l1_arb_out_confidence;
  logic [2:0]         l1_arb_out_pf_source_value;
  l1_pf_req_t         l1_arb_out_bits;
  always_comb
    for (int i = 0; i < L1_SIZE; i++) begin
      l1_arb_in_valid[i] = l1_can_send[i] & ~(s1_l1_alloc & (s1_l1_index == 4'(i)));
      l1_arb_in_bits[i]  = '{paddr:           l1_pf_addr[i],
                             alias_:          l1_alias[i],
                             confidence:      confidence,
                             is_store:        1'b0,
                             pf_source_value: l1_source[i]};
    end

  // BEGIN GENERATED(l1_pf_req_arb) —— verif/ut/MutiLevelPrefetchFilter/gen.py
  RRArbiterInit_8 l1_pf_req_arb (
    .clock                             (clock),
    .reset                             (reset),
    .io_in_0_ready                     (),
    .io_in_0_valid                     (l1_arb_in_valid[0]),
    .io_in_0_bits_req_paddr            (l1_arb_in_bits[0].paddr),
    .io_in_0_bits_req_alias            (l1_arb_in_bits[0].alias_),
    .io_in_0_bits_req_confidence       (l1_arb_in_bits[0].confidence),
    .io_in_0_bits_req_pf_source_value  (l1_arb_in_bits[0].pf_source_value),
    .io_in_1_ready                     (),
    .io_in_1_valid                     (l1_arb_in_valid[1]),
    .io_in_1_bits_req_paddr            (l1_arb_in_bits[1].paddr),
    .io_in_1_bits_req_alias            (l1_arb_in_bits[1].alias_),
    .io_in_1_bits_req_confidence       (l1_arb_in_bits[1].confidence),
    .io_in_1_bits_req_pf_source_value  (l1_arb_in_bits[1].pf_source_value),
    .io_in_2_ready                     (),
    .io_in_2_valid                     (l1_arb_in_valid[2]),
    .io_in_2_bits_req_paddr            (l1_arb_in_bits[2].paddr),
    .io_in_2_bits_req_alias            (l1_arb_in_bits[2].alias_),
    .io_in_2_bits_req_confidence       (l1_arb_in_bits[2].confidence),
    .io_in_2_bits_req_pf_source_value  (l1_arb_in_bits[2].pf_source_value),
    .io_in_3_ready                     (),
    .io_in_3_valid                     (l1_arb_in_valid[3]),
    .io_in_3_bits_req_paddr            (l1_arb_in_bits[3].paddr),
    .io_in_3_bits_req_alias            (l1_arb_in_bits[3].alias_),
    .io_in_3_bits_req_confidence       (l1_arb_in_bits[3].confidence),
    .io_in_3_bits_req_pf_source_value  (l1_arb_in_bits[3].pf_source_value),
    .io_in_4_ready                     (),
    .io_in_4_valid                     (l1_arb_in_valid[4]),
    .io_in_4_bits_req_paddr            (l1_arb_in_bits[4].paddr),
    .io_in_4_bits_req_alias            (l1_arb_in_bits[4].alias_),
    .io_in_4_bits_req_confidence       (l1_arb_in_bits[4].confidence),
    .io_in_4_bits_req_pf_source_value  (l1_arb_in_bits[4].pf_source_value),
    .io_in_5_ready                     (),
    .io_in_5_valid                     (l1_arb_in_valid[5]),
    .io_in_5_bits_req_paddr            (l1_arb_in_bits[5].paddr),
    .io_in_5_bits_req_alias            (l1_arb_in_bits[5].alias_),
    .io_in_5_bits_req_confidence       (l1_arb_in_bits[5].confidence),
    .io_in_5_bits_req_pf_source_value  (l1_arb_in_bits[5].pf_source_value),
    .io_in_6_ready                     (),
    .io_in_6_valid                     (l1_arb_in_valid[6]),
    .io_in_6_bits_req_paddr            (l1_arb_in_bits[6].paddr),
    .io_in_6_bits_req_alias            (l1_arb_in_bits[6].alias_),
    .io_in_6_bits_req_confidence       (l1_arb_in_bits[6].confidence),
    .io_in_6_bits_req_pf_source_value  (l1_arb_in_bits[6].pf_source_value),
    .io_in_7_ready                     (),
    .io_in_7_valid                     (l1_arb_in_valid[7]),
    .io_in_7_bits_req_paddr            (l1_arb_in_bits[7].paddr),
    .io_in_7_bits_req_alias            (l1_arb_in_bits[7].alias_),
    .io_in_7_bits_req_confidence       (l1_arb_in_bits[7].confidence),
    .io_in_7_bits_req_pf_source_value  (l1_arb_in_bits[7].pf_source_value),
    .io_in_8_ready                     (),
    .io_in_8_valid                     (l1_arb_in_valid[8]),
    .io_in_8_bits_req_paddr            (l1_arb_in_bits[8].paddr),
    .io_in_8_bits_req_alias            (l1_arb_in_bits[8].alias_),
    .io_in_8_bits_req_confidence       (l1_arb_in_bits[8].confidence),
    .io_in_8_bits_req_pf_source_value  (l1_arb_in_bits[8].pf_source_value),
    .io_in_9_ready                     (),
    .io_in_9_valid                     (l1_arb_in_valid[9]),
    .io_in_9_bits_req_paddr            (l1_arb_in_bits[9].paddr),
    .io_in_9_bits_req_alias            (l1_arb_in_bits[9].alias_),
    .io_in_9_bits_req_confidence       (l1_arb_in_bits[9].confidence),
    .io_in_9_bits_req_pf_source_value  (l1_arb_in_bits[9].pf_source_value),
    .io_in_10_ready                    (),
    .io_in_10_valid                    (l1_arb_in_valid[10]),
    .io_in_10_bits_req_paddr           (l1_arb_in_bits[10].paddr),
    .io_in_10_bits_req_alias           (l1_arb_in_bits[10].alias_),
    .io_in_10_bits_req_confidence      (l1_arb_in_bits[10].confidence),
    .io_in_10_bits_req_pf_source_value (l1_arb_in_bits[10].pf_source_value),
    .io_in_11_ready                    (),
    .io_in_11_valid                    (l1_arb_in_valid[11]),
    .io_in_11_bits_req_paddr           (l1_arb_in_bits[11].paddr),
    .io_in_11_bits_req_alias           (l1_arb_in_bits[11].alias_),
    .io_in_11_bits_req_confidence      (l1_arb_in_bits[11].confidence),
    .io_in_11_bits_req_pf_source_value (l1_arb_in_bits[11].pf_source_value),
    .io_in_12_ready                    (),
    .io_in_12_valid                    (l1_arb_in_valid[12]),
    .io_in_12_bits_req_paddr           (l1_arb_in_bits[12].paddr),
    .io_in_12_bits_req_alias           (l1_arb_in_bits[12].alias_),
    .io_in_12_bits_req_confidence      (l1_arb_in_bits[12].confidence),
    .io_in_12_bits_req_pf_source_value (l1_arb_in_bits[12].pf_source_value),
    .io_in_13_ready                    (),
    .io_in_13_valid                    (l1_arb_in_valid[13]),
    .io_in_13_bits_req_paddr           (l1_arb_in_bits[13].paddr),
    .io_in_13_bits_req_alias           (l1_arb_in_bits[13].alias_),
    .io_in_13_bits_req_confidence      (l1_arb_in_bits[13].confidence),
    .io_in_13_bits_req_pf_source_value (l1_arb_in_bits[13].pf_source_value),
    .io_in_14_ready                    (),
    .io_in_14_valid                    (l1_arb_in_valid[14]),
    .io_in_14_bits_req_paddr           (l1_arb_in_bits[14].paddr),
    .io_in_14_bits_req_alias           (l1_arb_in_bits[14].alias_),
    .io_in_14_bits_req_confidence      (l1_arb_in_bits[14].confidence),
    .io_in_14_bits_req_pf_source_value (l1_arb_in_bits[14].pf_source_value),
    .io_in_15_ready                    (),
    .io_in_15_valid                    (l1_arb_in_valid[15]),
    .io_in_15_bits_req_paddr           (l1_arb_in_bits[15].paddr),
    .io_in_15_bits_req_alias           (l1_arb_in_bits[15].alias_),
    .io_in_15_bits_req_confidence      (l1_arb_in_bits[15].confidence),
    .io_in_15_bits_req_pf_source_value (l1_arb_in_bits[15].pf_source_value),
    .io_out_ready                      (l1_arb_out_ready),
    .io_out_valid                      (l1_arb_out_valid),
    .io_out_bits_req_paddr             (l1_arb_out_paddr),
    .io_out_bits_req_alias             (l1_arb_out_alias),
    .io_out_bits_req_confidence        (l1_arb_out_confidence),
    .io_out_bits_req_pf_source_value   (l1_arb_out_pf_source_value),
    .io_chosen                         (l1_pf_chosen)
  );
  // END GENERATED

  // 仲裁器出口重新打包。is_store 在每一路都是常 0，golden 的 RRArbiterInit_8 连这个字段都没留。
  assign l1_arb_out_bits = '{paddr:           l1_arb_out_paddr,
                             alias_:          l1_arb_out_alias,
                             confidence:      l1_arb_out_confidence,
                             is_store:        1'b0,
                             pf_source_value: l1_arb_out_pf_source_value};

  // s1 流水
  logic               s1_pf_valid;           // 不复位（golden: Reg(Bool())）
  logic [PADDR_W-1:0] s1_pf_bits_req_paddr;
  logic [1:0]         s1_pf_bits_req_alias;
  logic               s1_pf_bits_req_confidence;
  logic               s1_pf_bits_req_is_store;
  logic [2:0]         s1_pf_bits_req_pf_source_value;

  wire s1_pf_evict  = s1_l1_alloc  & (s1_l1_index == s1_pf_index);
  wire s1_pf_update = s1_l1_update & (s1_l1_index == s1_pf_index);
  wire s1_pf_can_go = l1_req_ready & ~s1_pf_evict & ~s1_pf_update;
  assign s1_pf_fire       = s1_pf_valid & s1_pf_can_go;
  assign l1_arb_out_ready = s1_pf_can_go | ~s1_pf_valid;
  assign s0_pf_fire       = l1_arb_out_valid & l1_arb_out_ready;
  assign s0_pf_candidate_oh = line_oh(l1_arb_out_bits.paddr);

  always_ff @(posedge clock) begin
    if (s1_pf_can_go) s1_pf_valid <= 1'b0;
    if (s0_pf_fire)   s1_pf_valid <= 1'b1;
    if (s0_pf_fire) begin
      s1_pf_bits_req_paddr           <= l1_arb_out_bits.paddr;
      s1_pf_bits_req_alias           <= l1_arb_out_bits.alias_;
      s1_pf_bits_req_confidence      <= l1_arb_out_bits.confidence;
      s1_pf_bits_req_is_store        <= l1_arb_out_bits.is_store;
      s1_pf_bits_req_pf_source_value <= l1_arb_out_bits.pf_source_value;
      s1_pf_index                    <= l1_pf_chosen;
      s1_pf_candidate_oh             <= s0_pf_candidate_oh;
    end
  end

  wire in_pmem = (s1_pf_bits_req_paddr >= PMEM_BASE) & (s1_pf_bits_req_paddr < PMEM_END);
  assign l1_req_valid = s1_pf_valid & ~s1_pf_evict & ~s1_pf_update & in_pmem & enable;
  assign l1_req = '{paddr:           s1_pf_bits_req_paddr,
                    alias_:          s1_pf_bits_req_alias,
                    confidence:      s1_pf_bits_req_confidence,
                    is_store:        s1_pf_bits_req_is_store,
                    pf_source_value: s1_pf_bits_req_pf_source_value};

  // ===========================================================================
  //  §6 L2 / L3 发出（各一个 16 路轮转仲裁器，没有 s1 级：仲裁出来当拍就发）
  // ---------------------------------------------------------------------------
  //  同一张 L2 表，按 sink 分流：sink==L2 进 L2 仲裁器，sink==L3 进 L3 仲裁器；两个仲裁器的
  //  出口 ready 都恒为 1（下游不反压），赢家当拍置 sent_vec（§1 ③）。
  // ===========================================================================
  logic [L2_SIZE-1:0] l2_arb_in_valid, l3_arb_in_valid, l2_evict_vec;
  always_comb
    for (int i = 0; i < L2_SIZE; i++) begin
      l2_evict_vec[i]    = s1_l2_alloc & (s1_l2_index == 4'(i));
      l2_arb_in_valid[i] = l2_can_send[i] & l2_sink_is_l2[i] & ~l2_evict_vec[i];
      l3_arb_in_valid[i] = l2_can_send[i] & l2_sink_is_l3[i] & ~l2_evict_vec[i];
    end

  // BEGIN GENERATED(l2_l3_pf_req_arb) —— verif/ut/MutiLevelPrefetchFilter/gen.py
  RRArbiterInit_9 l2_pf_req_arb (
    .clock                    (clock),
    .reset                    (reset),
    .io_in_0_valid            (l2_arb_in_valid[0]),
    .io_in_0_bits_req_addr    (l2_pf_addr_e[0]),
    .io_in_0_bits_req_source  (l2_reqsource[0]),
    .io_in_1_valid            (l2_arb_in_valid[1]),
    .io_in_1_bits_req_addr    (l2_pf_addr_e[1]),
    .io_in_1_bits_req_source  (l2_reqsource[1]),
    .io_in_2_valid            (l2_arb_in_valid[2]),
    .io_in_2_bits_req_addr    (l2_pf_addr_e[2]),
    .io_in_2_bits_req_source  (l2_reqsource[2]),
    .io_in_3_valid            (l2_arb_in_valid[3]),
    .io_in_3_bits_req_addr    (l2_pf_addr_e[3]),
    .io_in_3_bits_req_source  (l2_reqsource[3]),
    .io_in_4_valid            (l2_arb_in_valid[4]),
    .io_in_4_bits_req_addr    (l2_pf_addr_e[4]),
    .io_in_4_bits_req_source  (l2_reqsource[4]),
    .io_in_5_valid            (l2_arb_in_valid[5]),
    .io_in_5_bits_req_addr    (l2_pf_addr_e[5]),
    .io_in_5_bits_req_source  (l2_reqsource[5]),
    .io_in_6_valid            (l2_arb_in_valid[6]),
    .io_in_6_bits_req_addr    (l2_pf_addr_e[6]),
    .io_in_6_bits_req_source  (l2_reqsource[6]),
    .io_in_7_valid            (l2_arb_in_valid[7]),
    .io_in_7_bits_req_addr    (l2_pf_addr_e[7]),
    .io_in_7_bits_req_source  (l2_reqsource[7]),
    .io_in_8_valid            (l2_arb_in_valid[8]),
    .io_in_8_bits_req_addr    (l2_pf_addr_e[8]),
    .io_in_8_bits_req_source  (l2_reqsource[8]),
    .io_in_9_valid            (l2_arb_in_valid[9]),
    .io_in_9_bits_req_addr    (l2_pf_addr_e[9]),
    .io_in_9_bits_req_source  (l2_reqsource[9]),
    .io_in_10_valid           (l2_arb_in_valid[10]),
    .io_in_10_bits_req_addr   (l2_pf_addr_e[10]),
    .io_in_10_bits_req_source (l2_reqsource[10]),
    .io_in_11_valid           (l2_arb_in_valid[11]),
    .io_in_11_bits_req_addr   (l2_pf_addr_e[11]),
    .io_in_11_bits_req_source (l2_reqsource[11]),
    .io_in_12_valid           (l2_arb_in_valid[12]),
    .io_in_12_bits_req_addr   (l2_pf_addr_e[12]),
    .io_in_12_bits_req_source (l2_reqsource[12]),
    .io_in_13_valid           (l2_arb_in_valid[13]),
    .io_in_13_bits_req_addr   (l2_pf_addr_e[13]),
    .io_in_13_bits_req_source (l2_reqsource[13]),
    .io_in_14_valid           (l2_arb_in_valid[14]),
    .io_in_14_bits_req_addr   (l2_pf_addr_e[14]),
    .io_in_14_bits_req_source (l2_reqsource[14]),
    .io_in_15_valid           (l2_arb_in_valid[15]),
    .io_in_15_bits_req_addr   (l2_pf_addr_e[15]),
    .io_in_15_bits_req_source (l2_reqsource[15]),
    .io_out_valid             (l2_arb_out_valid),
    .io_out_bits_req_addr     (l2_arb_out_addr),
    .io_out_bits_req_source   (l2_arb_out_source),
    .io_chosen                (l2_arb_chosen)
  );

  RRArbiterInit_6 l3_pf_req_arb (
    .clock          (clock),
    .reset          (reset),
    .io_in_0_ready  (),
    .io_in_0_valid  (l3_arb_in_valid[0]),
    .io_in_0_bits   (l2_pf_addr_e[0]),
    .io_in_1_ready  (),
    .io_in_1_valid  (l3_arb_in_valid[1]),
    .io_in_1_bits   (l2_pf_addr_e[1]),
    .io_in_2_ready  (),
    .io_in_2_valid  (l3_arb_in_valid[2]),
    .io_in_2_bits   (l2_pf_addr_e[2]),
    .io_in_3_ready  (),
    .io_in_3_valid  (l3_arb_in_valid[3]),
    .io_in_3_bits   (l2_pf_addr_e[3]),
    .io_in_4_ready  (),
    .io_in_4_valid  (l3_arb_in_valid[4]),
    .io_in_4_bits   (l2_pf_addr_e[4]),
    .io_in_5_ready  (),
    .io_in_5_valid  (l3_arb_in_valid[5]),
    .io_in_5_bits   (l2_pf_addr_e[5]),
    .io_in_6_ready  (),
    .io_in_6_valid  (l3_arb_in_valid[6]),
    .io_in_6_bits   (l2_pf_addr_e[6]),
    .io_in_7_ready  (),
    .io_in_7_valid  (l3_arb_in_valid[7]),
    .io_in_7_bits   (l2_pf_addr_e[7]),
    .io_in_8_ready  (),
    .io_in_8_valid  (l3_arb_in_valid[8]),
    .io_in_8_bits   (l2_pf_addr_e[8]),
    .io_in_9_ready  (),
    .io_in_9_valid  (l3_arb_in_valid[9]),
    .io_in_9_bits   (l2_pf_addr_e[9]),
    .io_in_10_ready (),
    .io_in_10_valid (l3_arb_in_valid[10]),
    .io_in_10_bits  (l2_pf_addr_e[10]),
    .io_in_11_ready (),
    .io_in_11_valid (l3_arb_in_valid[11]),
    .io_in_11_bits  (l2_pf_addr_e[11]),
    .io_in_12_ready (),
    .io_in_12_valid (l3_arb_in_valid[12]),
    .io_in_12_bits  (l2_pf_addr_e[12]),
    .io_in_13_ready (),
    .io_in_13_valid (l3_arb_in_valid[13]),
    .io_in_13_bits  (l2_pf_addr_e[13]),
    .io_in_14_ready (),
    .io_in_14_valid (l3_arb_in_valid[14]),
    .io_in_14_bits  (l2_pf_addr_e[14]),
    .io_in_15_ready (),
    .io_in_15_valid (l3_arb_in_valid[15]),
    .io_in_15_bits  (l2_pf_addr_e[15]),
    .io_out_valid   (l3_arb_out_valid),
    .io_out_bits    (l3_pf_addr),
    .io_chosen      (l3_arb_chosen)
  );
  // END GENERATED

  assign l2_pf_valid = l2_arb_out_valid;
  assign l2_pf       = '{addr: l2_arb_out_addr, source: l2_arb_out_source};
  assign l3_pf_valid = l3_arb_out_valid;

  // ===========================================================================
  //  §7 冲刷与只喂性能计数器的死寄存器
  // ---------------------------------------------------------------------------
  //  冲刷：每项一份 RegNext(flush)，下一拍清该项 valid（§1）。本配置 flush 恒 0，于是这 32 个
  //    寄存器 D 端恒 0、不复位 —— golden 同样留着它们（REG_6..REG_37），照抄。
  //  死寄存器：golden 的 hash_conflict 性能计数器需要 s1 的 valid/region/hash 再打一拍
  //    （golden 名 REG/REG_1/REG_2 = L1 表，REG_3/REG_4/REG_5 = L2 表）。计数器本身在综合口径下
  //    被删了，这 6 个寄存器却留在 golden 里、没有读者。照抄（两侧对称的死位），
  //    本核的 REG_0 就是 golden 的 REG（与冲刷数组 REG 撞名，只能改一个字）。
  // ===========================================================================
  always_ff @(posedge clock)
    for (int i = 6; i <= 37; i++) REG[i] <= flush;

  logic                REG_0,  REG_3;
  logic [REGION_W-1:0] REG_1,  REG_4;
  logic [TAG_W-1:0]    REG_2,  REG_5;
  always_ff @(posedge clock) begin
    REG_0 <= s1_l1_valid;
    REG_1 <= s1_l1_region;
    REG_2 <= s1_l1_region_hash;
    REG_3 <= s1_l2_valid;
    REG_4 <= s1_l2_region;
    REG_5 <= s1_l2_region_hash;
  end

endmodule

// =============================================================================
//  MutiLevelPrefetchFilter —— golden 同名 wrapper
// -----------------------------------------------------------------------------
//  端口与 golden 逐位同名同序（端口表由 verif/ut/MutiLevelPrefetchFilter/gen.py 从 golden 取）。
//  这里只做 struct 打包/拆包，外加三处「golden 配置里被折掉的接口」：
//    · io.flush：上层 L1Prefetcher 接常 0，golden 无此端口 → 核的 flush 接 1'b0；
//    · io.l1_prefetch_req.bits.sink：上层恒为 SINK_L1，golden 无此端口 → 接 SINK_L1；
//    · io.l3_pf_addr：上层不接，golden 无此端口 → 核的输出悬空。
// =============================================================================
module MutiLevelPrefetchFilter
  import mutilevelprefetchfilter_pkg::*;
(
  // BEGIN GENERATED(ports) —— verif/ut/MutiLevelPrefetchFilter/gen.py
  input         clock,
  input         reset,
  input         io_enable,
  input         io_l1_prefetch_req_valid,
  input  [39:0] io_l1_prefetch_req_bits_region,
  input  [15:0] io_l1_prefetch_req_bits_bit_vec,
  input  [2:0]  io_l1_prefetch_req_bits_source_value,
  input         io_l2_l3_prefetch_req_valid,
  input  [39:0] io_l2_l3_prefetch_req_bits_region,
  input  [15:0] io_l2_l3_prefetch_req_bits_bit_vec,
  input  [1:0]  io_l2_l3_prefetch_req_bits_sink,
  input  [2:0]  io_l2_l3_prefetch_req_bits_source_value,
  output        io_tlb_req_req_valid,
  output [49:0] io_tlb_req_req_bits_vaddr,
  output [63:0] io_tlb_req_req_bits_fullva,
  output        io_tlb_req_req_bits_checkfullva,
  output [2:0]  io_tlb_req_req_bits_cmd,
  output        io_tlb_req_req_bits_hyperinst,
  output        io_tlb_req_req_bits_hlvx,
  output        io_tlb_req_req_bits_kill,
  output        io_tlb_req_req_bits_isPrefetch,
  output        io_tlb_req_req_bits_no_translate,
  output [47:0] io_tlb_req_req_bits_pmp_addr,
  output        io_tlb_req_req_bits_frm_mabuf,
  output        io_tlb_req_req_bits_debug_robIdx_flag,
  output [7:0]  io_tlb_req_req_bits_debug_robIdx_value,
  output        io_tlb_req_req_bits_debug_isFirstIssue,
  input         io_tlb_req_resp_valid,
  input  [47:0] io_tlb_req_resp_bits_paddr_0,
  input  [1:0]  io_tlb_req_resp_bits_pbmt_0,
  input         io_tlb_req_resp_bits_miss,
  input         io_tlb_req_resp_bits_excp_0_gpf_ld,
  input         io_tlb_req_resp_bits_excp_0_pf_ld,
  input         io_tlb_req_resp_bits_excp_0_af_ld,
  input         io_pmp_resp_ld,
  input         io_pmp_resp_mmio,
  input         io_l1_req_ready,
  output        io_l1_req_valid,
  output [47:0] io_l1_req_bits_paddr,
  output [1:0]  io_l1_req_bits_alias,
  output        io_l1_req_bits_confidence,
  output        io_l1_req_bits_is_store,
  output [2:0]  io_l1_req_bits_pf_source_value,
  output        io_l2_pf_addr_valid,
  output [47:0] io_l2_pf_addr_bits_addr,
  output [4:0]  io_l2_pf_addr_bits_source,
  input         io_confidence
  // END GENERATED
);
  stream_pf_req_t l1_prefetch_req, l2_l3_prefetch_req;
  tlb_resp_t      tlb_resp;
  tlb_req_t       tlb_req;
  l1_pf_req_t     l1_req;
  l2_pf_req_t     l2_pf;

  assign l1_prefetch_req    = '{region:       io_l1_prefetch_req_bits_region,
                                bit_vec:      io_l1_prefetch_req_bits_bit_vec,
                                sink:         SINK_L1,
                                source_value: io_l1_prefetch_req_bits_source_value};
  assign l2_l3_prefetch_req = '{region:       io_l2_l3_prefetch_req_bits_region,
                                bit_vec:      io_l2_l3_prefetch_req_bits_bit_vec,
                                sink:         io_l2_l3_prefetch_req_bits_sink,
                                source_value: io_l2_l3_prefetch_req_bits_source_value};
  assign tlb_resp           = '{paddr:  io_tlb_req_resp_bits_paddr_0,
                                pbmt:   io_tlb_req_resp_bits_pbmt_0,
                                miss:   io_tlb_req_resp_bits_miss,
                                gpf_ld: io_tlb_req_resp_bits_excp_0_gpf_ld,
                                pf_ld:  io_tlb_req_resp_bits_excp_0_pf_ld,
                                af_ld:  io_tlb_req_resp_bits_excp_0_af_ld};

  xs_MutiLevelPrefetchFilter_core u_core (
    .clock                    (clock),
    .reset                    (reset),
    .enable                   (io_enable),
    .flush                    (1'b0),
    .confidence               (io_confidence),
    .l1_prefetch_req_valid    (io_l1_prefetch_req_valid),
    .l1_prefetch_req          (l1_prefetch_req),
    .l2_l3_prefetch_req_valid (io_l2_l3_prefetch_req_valid),
    .l2_l3_prefetch_req       (l2_l3_prefetch_req),
    .tlb_req_valid            (io_tlb_req_req_valid),
    .tlb_req                  (tlb_req),
    .tlb_resp_valid           (io_tlb_req_resp_valid),
    .tlb_resp                 (tlb_resp),
    .pmp_resp_ld              (io_pmp_resp_ld),
    .pmp_resp_mmio            (io_pmp_resp_mmio),
    .l1_req_ready             (io_l1_req_ready),
    .l1_req_valid             (io_l1_req_valid),
    .l1_req                   (l1_req),
    .l2_pf_valid              (io_l2_pf_addr_valid),
    .l2_pf                    (l2_pf),
    .l3_pf_valid              (),
    .l3_pf_addr               ()
  );

  assign io_tlb_req_req_bits_vaddr              = tlb_req.vaddr;
  assign io_tlb_req_req_bits_fullva             = tlb_req.fullva;
  assign io_tlb_req_req_bits_checkfullva        = tlb_req.checkfullva;
  assign io_tlb_req_req_bits_cmd                = tlb_req.cmd;
  assign io_tlb_req_req_bits_hyperinst          = tlb_req.hyperinst;
  assign io_tlb_req_req_bits_hlvx               = tlb_req.hlvx;
  assign io_tlb_req_req_bits_kill               = tlb_req.kill;
  assign io_tlb_req_req_bits_isPrefetch         = tlb_req.isPrefetch;
  assign io_tlb_req_req_bits_no_translate       = tlb_req.no_translate;
  assign io_tlb_req_req_bits_pmp_addr           = tlb_req.pmp_addr;
  assign io_tlb_req_req_bits_frm_mabuf          = tlb_req.frm_mabuf;
  assign io_tlb_req_req_bits_debug_robIdx_flag  = tlb_req.debug_robIdx_flag;
  assign io_tlb_req_req_bits_debug_robIdx_value = tlb_req.debug_robIdx_value;
  assign io_tlb_req_req_bits_debug_isFirstIssue = tlb_req.debug_isFirstIssue;
  assign io_l1_req_bits_paddr                   = l1_req.paddr;
  assign io_l1_req_bits_alias                   = l1_req.alias_;
  assign io_l1_req_bits_confidence              = l1_req.confidence;
  assign io_l1_req_bits_is_store                = l1_req.is_store;
  assign io_l1_req_bits_pf_source_value         = l1_req.pf_source_value;
  assign io_l2_pf_addr_bits_addr                = l2_pf.addr;
  assign io_l2_pf_addr_bits_source              = l2_pf.source;
endmodule
