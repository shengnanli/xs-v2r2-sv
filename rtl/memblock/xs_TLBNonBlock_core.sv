// =============================================================================
// xs_TLBNonBlock_core —— L1 非阻塞 TLB（dtlb）的参数化可读核
//
// 位置：MemBlock 里三个 dtlb 各例化一个 TLBNonBlock：
//         dtlb_ld  (TLBNonBlock)   4 个请求端口，给 3 个 load 单元 + 1 个杂项口
//         dtlb_st  (TLBNonBlock_1) 2 个请求端口，给 2 个 store 地址单元
//         dtlb_pf  (TLBNonBlock_2) 2 个请求端口，给预取器
//       每个 TLBNonBlock 自己带一组全相联页表项（TlbStorageWrapper -> TLBFA），
//       查不到就向 L2TLB(PTW) 要，**不阻塞**：本拍来、下一拍必出响应，
//       miss 的话响应里 miss=1，请求方自己重发。
//
// 两拍的流水（读这个模块之前必须先记住这张时序图）：
//   拍 A（请求拍，信号名以 req_in / pre* 开头）
//     · 算 EffectiveVa（按 PMM 指针掩码把 fullva 截断/符号扩展）
//     · 算 pre 故障（prepf/pregpf/preaf）：地址高位越界，不用查页表就知道要报错
//     · 把 vpn 送进 entries 做全相联比较；同时和"本拍正好回来的 PTW 响应"比一次
//       （p_hit_fast，即 ptw_resp_bypass）
//     · 把请求打进 req_out 寄存器组
//   拍 B（响应拍，信号名以 req_out / resp 开头）
//     · entries 给出命中项，或者用上一拍旁路下来的 PTW 结果（p_hit）
//     · 权限检查 -> excp，物理地址 -> paddr，客户机物理地址 -> gpaddr
//     · miss 的话向 PTW 发请求，或者置 tlbreplay 让请求方重来
//
// 三个必须先懂的结构概念：
//   1) 两级地址翻译（H 扩展）：s2xlate ∈ {00 无, 01 只 VS-stage, 10 只 G-stage,
//      11 两级}。一次翻译的结果同时包含 s1（VS-stage）和 s2（G-stage）两套页表项，
//      权限要两套各查一遍再合并（见 §权限检查）。
//   2) need_gpa 状态机：G-stage 出故障（gpf）时，CSR 要拿到出错的**客户机物理地址**
//      gpaddr。但 gpaddr 只有 PTW 才知道，所以 TLB 要专门再向 PTW 要一次
//      （getGpa 请求），期间整个 TLB 进入 need_gpa 状态，别的 miss 一律 tlbreplay。
//      这是整个模块最绕的一段，见 §need_gpa。
//   3) nDups：响应里的 paddr/perm 复制成 nDups 份，纯粹为了后端时序（扇出），
//      **不是不同的值**。dup 之间共用 entries 的独立输出端口，各自算一遍。
//
// 本核只做非阻塞（Block=false）那一路。阻塞版（TLBBLock，itlb 用）是另一个模块
// （golden TLB.sv），不在本核范围内 —— 它的 handle_block 和这里的 handle_nonblock
// 是两套完全不同的握手。
//
// -----------------------------------------------------------------------------
// ★家族三变体的差异矩阵（全部实测自 golden 端口表与寄存器表，不是从 Chisel 推的）★
//
//   Chisel 侧三者的参数只差两项：
//     TLBNonBlock   = new TLBNonBlock(LduCnt+HyuCnt+1 = 4, nRespDups=2, ldtlbParams)
//     TLBNonBlock_1 = new TLBNonBlock(StaCnt = 2,          nRespDups=1, sttlbParams)
//     TLBNonBlock_2 = new TLBNonBlock(2,                   nRespDups=2, pftlbParams)
//   而 KunminghuV2Config 下 ldtlbParams/sttlbParams/pftlbParams **逐字段相同**
//   （NWays=4, partialStaticPMP, outsideRecvFlush, outReplace=false, lgMaxSize=4），
//   只有 name 不同（name 只影响 difftest 要不要上报，见 DIFFTEST_EN）。
//
//   所以三者 RTL 上的其余差异**全部来自 firtool -O=release 的消端口**：父级 MemBlock
//   没连的输入被折成常量、没用的输出被删掉，删掉之后它上游的寄存器跟着被消。
//   这不是"可以抹平的噪声"——FM 把寄存器当自由变量，impl 多一个 golden 没有的
//   寄存器就是一个 unmatched unread 点，直接判 PARTIAL。所以消端口的结果必须
//   **按 lane 逐条参数化重现**，这就是下面这堆 W 位掩码参数的由来。
//
//   requestor 通道字段存在矩阵（Y=golden 该变体该 lane 有这个端口）：
//
//     字段                        B0 B1 B2 B3 | _1.0 _1.1 | _2.0 _2.1
//     req.bits.hlvx               Y  Y  Y  Y  |  .    .   |  Y    .
//     req.bits.isPrefetch         Y  Y  Y  Y  |  .    .   |  Y    Y
//     req.bits.kill               Y  Y  Y  Y  |  .    .   |  Y    Y
//     req.bits.no_translate       Y  Y  Y  Y  |  .    .   |  Y    Y
//     req.bits.pmp_addr           Y  Y  Y  Y  |  .    .   |  Y    .
//     req.bits.memidx.idx         .  .  .  .  |  Y    Y   |  .    .
//     req_kill                    Y  Y  Y  .  |  .    .   |  .    .
//     resp.bits.excp(0).{pf,af}.st Y .  .  .  |  Y    Y   |  .    .
//     resp.bits.excp(0).isHyper   Y  Y  Y  .  |  Y    Y   |  .    .
//     resp.bits.excp(0).vaNeedExt Y  Y  Y  .  |  Y    Y   |  .    .
//     resp.bits.fullva            Y  Y  Y  .  |  Y    Y   |  .    .
//     resp.bits.gpaddr(0)         Y  Y  Y  .  |  Y    Y   |  .    .
//     resp.bits.isForVSnonLeafPTE Y  Y  Y  .  |  Y    Y   |  .    .
//     resp.bits.paddr(1)          Y  Y  Y  .  |  .    .   |  .    .
//     resp.bits.ptwBack           Y  Y  Y  .  |  Y    Y   |  .    .
//     resp.bits.memidx.idx        .  .  .  .  |  Y    Y   |  .    .
//     req.bits.debug_isFirstIssue Y  Y  Y  Y  |  Y    Y   |  Y    .
//     req.bits.debug_robIdx       Y  Y  Y  Y  |  Y    Y   |  Y    .
//     req.bits.frm_mabuf          Y  Y  Y  Y  |  Y    Y   |  Y    .
//     req.bits.hyperinst          Y  Y  Y  Y  |  Y    Y   |  Y    .
//     req.bits.fullva/checkfullva Y  Y  Y  Y  |  Y    Y   |  Y    .
//
//   ★缺输入端口也会消寄存器 —— 这一半第一轮漏了，FM 直接判 PARTIAL★
//   上面矩阵后半截那五行是**输入**。它们缺的时候，golden 里对应的打拍寄存器
//   （req_out_<i>_{hlvx,hyperinst,frm_mabuf,debug_robIdx_*}、useReqS1Paddr_<i>、
//   r/r_<n>、..._excp_0_*_REG、REG/REG_1）整组不存在。重写核照样生成，
//   就成了 impl-only 的 compare point：TLBNonBlock_2 实测 18 个，
//   signoff-strict 判 PARTIAL(reason=strict_unmatched!=0)，native 却是 SUCCEEDED
//   —— 因为这些点不参与任何匹配比较，failing 恒 0，**只看 native 会漏掉**。
//   现在由 HAS_FIRST_ISSUE / HAS_ROBIDX / HAS_FRM_MABUF / HAS_HYPERINST /
//   HAS_HLVX / HAS_NO_TRANSLATE / HAS_PRE_EXCP 七个掩码逐 lane 重现，
//   掩码值由 scripts/gen_tlbnb_family.py 从 **golden 的 reg 清单**现读。
//   模块级：
//     tlbreplay                   有          |  无       |  无
//     perf                        有          |  有       |  无
//     difftest.valid              真表达式    |  真表达式 |  恒 0（pftlb 不上报）
//     difftest index              3,4,5,6     |  7,8      |  9,10
//     nRespDups                   2           |  1        |  2
//
//   ★缺输入端口 vs 缺输出端口，处理方式完全不同★
//     · 缺输入 = golden 里那根线被折成常量 0。wrapper 直接给核灌 0 就行，
//       核里由它驱动的寄存器会被 FM 归进 "Constant reg / Not Compared"，不是 unread。
//     · 缺输出 = golden 里那条锥体连同上游寄存器一起被删了。核**必须不生成**
//       那些寄存器，否则就是 impl-only 的 unread 点。这就是 HAS_GPADDR /
//       HAS_RESP_FULLVA / HAS_MEMIDX 三个掩码要 generate-gate 的原因，
//       被 gate 的寄存器逐个列在下面每个 gate 的注释里。
//
//   ★三个变体的寄存器总数（golden 实测，本核必须一个不差地对上）★
//       TLBNonBlock 325（其中 28 个带异步复位） / _1 165（17） / _2 132（13）
//     其中 golden 自己就有的"没人读的寄存器"（FM 会报 unread 点，靠 vmucp 加强证明
//     成对消化，绝不能为了干净把它们删掉）：
//       base 8 个 = 每 lane 2 个 first_issue 打拍（XSPerfAccumulate 被消后的残留）
//       _1   4 个 = 同上 × 2 lane
//       _2   4 个 = lane0 的 2 个 first_issue + 2 个 result_ok（perf 端口没了）
//
// -----------------------------------------------------------------------------
// ★读这个模块最容易踩的坑：sector tag 的切片上下界要各自减 SECT_W★
//   s1 的表项 tag 是 **sector tag**（只存 vpn[37:3]，最低 3 位靠 valididx/pteidx 定位），
//   而 s2 的 tag 是完整 gvpn。于是同一句"比最低一级 vpnn"在两边的写法不一样：
//     s2：  tag[8:4] == gvpn[8:4]          （下标与 vpn 同）
//     s1：  tag[5:1] == vpn[8:4]           （上下界各减 SECT_W=3）
//   第一版把 s1 的上界跟着下界一起减，写成 tag[4:1]（4 位）去比 vpn[8:4]（5 位）——
//   SV 会把窄的一侧零扩展，**编译不报、lint 不报**，只有 s1.entry.n=1（Svnapot）
//   且 noS2 的那条路会错。它的外在症状离病灶很远：impl 侧变成"没命中"→ 多发一次
//   PTW 请求 → paddr/gpaddr 只剩页内偏移、pbmt=0、miss=1、tlbreplay 相位差。
//   实测：seed=1 / 50k 拍下 TLBNonBlock 58 个 + TLBNonBlock_1 61 个失配点（_2 当时未跑完），
//   全部由这一行引起；改对之后三个变体 3 seed x 2 initreg x 200k 全绿。
//   覆盖闸里的 c_napot_sup 桶就是为这条路留的（见 verif/ut/TLBNonBlock/gen_tb.py）。
// -----------------------------------------------------------------------------
//
// 本文件导航（共 1339 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   ——      package tlbnb_pkg 已搬到 rtl/memblock/memblock_common_pkg.sv
//   L161    module xs_TLBNonBlock_core
//   L332    §CSR 译码（全部用延迟后的 csr，见 DelayN_7）
//   L360    §PTW 响应旁路的命中键
//   L384    §状态声明
//   L481    §拍 A：请求拍的组合逻辑
//   L584    §打拍
//   L788    §拍 B：响应拍
//   L937    §权限检查（Chisel 的 perm_check，每 lane 每 dup 调一次）
//   L1061   §need_gpa —— 整个模块最绕的一段
//   L1236   §handle_nonblock：miss 了要么发 PTW 请求，要么叫请求方重来
//   L1279   §entries 回填：PTW 响应写进全相联表
//   L1288   §perf 事件：两个计数，各自打两拍出去（generatePerfEvent）
//   L1314   §difftest：每条 lane 一个 DiffL1TLBEvent，payload 打成 339 位从 bore 端口出去
//
// 判据是 golden RTL（G1-canonical/golden-rtl/TLBNonBlock{,_1,_2}.sv）；Chisel
// （XiangShan src/main/scala/xiangshan/cache/mmu/TLB.scala + MMUBundle.scala）
// 只用来解释"为什么"。几处"Chisel 读起来像 A、展开成 B"的地方已就地注明，以 golden 为准。
// =============================================================================
// ★包不在本文件★：tlbnb_pkg 被三个薄 wrapper（TLBNonBlock{,_1,_2}.sv）的模块头
// import，是**跨文件共享包**，按 CONVENTIONS.md 放在 rtl/memblock/memblock_common_pkg.sv。
// 藏在本文件里会制造文件顺序依赖（VCS 的 Error-[SV-LCM-PND]），这一条有实测先例：
// 同目录的 xs_tlbsw_pkg 当初就是这么搬出去的（见那个文件的头注释）。


// =============================================================================
// 可读核本体
//
// 端口按 lane 打成数组（[W-1:0][...]），薄 wrapper 负责把 golden 的扁平 io_* 名
// 接过来；哪条 lane 缺哪个 golden 端口，由 wrapper 灌常量 0 / 不接，见文件头矩阵。
// =============================================================================
module xs_TLBNonBlock_core
  import tlbnb_pkg::*;
#(
  // 请求端口数：dtlb_ld 4 / dtlb_st 2 / dtlb_pf 2
  parameter int W      = 4,
  // 响应复制份数（只影响 paddr/pbmt/perm 的份数，值完全相同，为后端扇出）
  parameter int N_DUPS = 2,

  // ---- 下面四个是"父级消端口"的逐 lane 重现，判据见文件头矩阵 ----
  // resp.bits.gpaddr(0) 端口存在的 lane。为 0 的 lane 不生成
  //   req_out_fullva / p_gvpn / p_s2xlate / p_s1_level / p_s1_isLeaf / p_s1_isFakePte
  // 六组寄存器；全 0 时连模块级的 resp_gpa_gvpn / resp_s1_* 四个也不生成。
  parameter logic [W-1:0] HAS_GPADDR      = {W{1'b1}},
  // resp.bits.fullva 端口存在的 lane。为 0 的 lane 不生成 resp_fullva_r。
  parameter logic [W-1:0] HAS_RESP_FULLVA = {W{1'b1}},
  // resp.bits.memidx 端口存在的 lane。为 0 的 lane 不生成 resp_memidx_r。
  parameter logic [W-1:0] HAS_MEMIDX      = {W{1'b0}},
  // resp.bits.excp(0).{pf,af}.st 端口存在的 lane。这两路的 pre-fault 打拍寄存器
  // 只要"端口存在 或 difftest 开着"就得留（difftest 会读它们），见 KEEP_ST_PRE。
  parameter logic [W-1:0] HAS_ST_EXCP     = {W{1'b1}},
  // requestor.req_kill 端口存在的 lane。为 0 的 lane 不生成 last_req_fire。
  parameter logic [W-1:0] HAS_REQ_KILL    = {W{1'b1}},

  // ---- 缺**输入**端口造成的逐 lane 消寄存器（判据是 golden 的寄存器清单本身）----
  // 之前只按"缺输出端口"做了 gate，漏了这一半：某条 lane 的输入被父级折成常量时，
  // firtool 连它的打拍寄存器一起消掉，而重写核照样生成 —— 那就是 impl-only 的
  // compare point，signoff-strict 直接判 PARTIAL（TLBNonBlock_2 实测 18 个）。
  // 每个 mask 的判据都是"golden 该变体里有没有这个名字的 reg"，机械可复核，
  // 由 scripts/gen_tlbnb_family.py 从 golden 源文件现读，不是手抄。
  //   HAS_FIRST_ISSUE  <- golden 有 io_requestor_<i>_req_bits_debug_isFirstIssue 端口
  //   HAS_ROBIDX       <- golden 有 reg req_out_<i>_debug_robIdx_flag
  //   HAS_FRM_MABUF    <- golden 有 reg req_out_<i>_frm_mabuf
  //   HAS_HYPERINST    <- golden 有 reg req_out_<i>_hyperinst
  //   HAS_HLVX         <- golden 有 reg req_out_<i>_hlvx
  //   HAS_NO_TRANSLATE <- golden 有 reg useReqS1Paddr_<i>
  //   HAS_PRE_EXCP     <- golden 有 reg io_requestor_<i>_resp_bits_excp_0_pf_ld_REG
  //   HAS_IS_PREFETCH  <- golden 有 reg req_out_<i>_isPrefetch
  // ★被 gate 掉的那半边一律用 `always_comb x[i] = 0;`，**不许用 `assign`**★
  //   —— 这是实测踩出来的坑，不是风格偏好：同一个 unpacked 数组里，只要有一个元素
  //   由连续赋值驱动，VCS 的 `+vcs+initreg` 就**整个数组都不初始化**，剩下那些
  //   always_ff 元素在复位后第一次被写之前保持 X。最小复现（scratchpad 的 t2/t3）：
  //       logic [63:0] a [2];  always_ff ... a[0] <= d;  assign a[1] = 0;
  //         -> +vcs+initreg+0 下 a[0] 仍是 X
  //       同样的代码把 assign 换成 always_comb -> a[0] = 0（random 时是随机值）
  //   本轮 seed=7/initreg=0 的 io_requestor_1_resp_bits_fullva 与 gpaddr 两个失配
  //   就是这个（golden 那边是普通标量 reg，照常被初始化成 0，于是 0 vs X）。
  //   FM 看不见它（无复位寄存器两侧都是自由变量），所以这条**只有 UT 能抓**。
  //
  // ★被 gate 掉的一律接常量 0，而不是"少一个寄存器"★：这些 lane 的对应输入本来
  // 就被 wrapper 灌了 0，寄存器复位后恒 0，所以接常量与保留寄存器功能等价；
  // 区别只在 FM 的 compare point 集合（以及 +vcs+initreg+random 的第一拍）。
  parameter logic [W-1:0] HAS_FIRST_ISSUE  = {W{1'b1}},
  parameter logic [W-1:0] HAS_ROBIDX       = {W{1'b1}},
  parameter logic [W-1:0] HAS_FRM_MABUF    = {W{1'b1}},
  parameter logic [W-1:0] HAS_HYPERINST    = {W{1'b1}},
  parameter logic [W-1:0] HAS_HLVX         = {W{1'b1}},
  parameter logic [W-1:0] HAS_NO_TRANSLATE = {W{1'b1}},
  parameter logic [W-1:0] HAS_PRE_EXCP     = {W{1'b1}},
  parameter logic [W-1:0] HAS_IS_PREFETCH  = {W{1'b1}},
  // tlbreplay 端口存在（dtlb_ld 才有）
  parameter bit  HAS_TLBREPLAY = 1'b1,
  // perf 端口存在（dtlb_pf 没有）
  parameter bit  HAS_PERF      = 1'b1,
  // difftest.valid 是不是真表达式。Chisel 里只有 itlb/ldtlb/sttlb 上报，
  // pftlb 被一句 `difftest.valid := false.B` 关掉，于是它上游整条锥体全折没了。
  parameter bit  DIFFTEST_EN   = 1'b1,
  // 本变体第 0 条 lane 的 DiffL1TLBEvent index（全局计数器分配：itlb 0..2、
  // dtlb_ld 3..6、dtlb_st 7..8、dtlb_pf 9..10）
  parameter int  DIFF_INDEX_0  = 3
)(
  input  logic clock,
  input  logic reset,

  // ---- 延迟 2 拍后的 sfence.valid 与 CSR 现场（wrapper 里的 DelayN 给）----
  input  logic       sfence_valid_d,
  input  tlb_csr_t   csr,
  input  logic [5:0] hart_id,

  // ---- 后端 redirect 与 ROB 指针 ----
  input  logic                 redirect_valid,
  input  logic                 redirect_robidx_flag,
  input  logic [ROB_IDX_W-1:0] redirect_robidx_value,
  input  logic                 redirect_level,
  input  logic                 rob_pending_flag,
  input  logic [ROB_IDX_W-1:0] rob_pending_value,

  // ---- requestor 请求（req.ready 恒 1，故 golden 没有 ready 端口）----
  input  logic [W-1:0]                req_valid,
  input  logic [W-1:0][VADDR_W-1:0]   req_vaddr,
  input  logic [W-1:0][XLEN-1:0]      req_fullva,
  input  logic [W-1:0]                req_checkfullva,
  input  logic [W-1:0][2:0]           req_cmd,
  input  logic [W-1:0]                req_hyperinst,
  input  logic [W-1:0]                req_hlvx,
  input  logic [W-1:0]                req_kill_bit,     // req.bits.kill：本拍就作废
  input  logic [W-1:0]                req_is_prefetch,
  input  logic [W-1:0]                req_no_translate,
  input  logic [W-1:0][PADDR_W-1:0]   req_pmp_addr,
  input  logic [W-1:0]                req_frm_mabuf,
  input  logic [W-1:0]                req_robidx_flag,
  input  logic [W-1:0][ROB_IDX_W-1:0] req_robidx_value,
  input  logic [W-1:0]                req_first_issue,
  input  logic [W-1:0][MEMIDX_W-1:0]  req_memidx,
  input  logic [W-1:0]                req_kill,         // requestor.req_kill：下一拍作废

  // ---- requestor 响应（请求的下一拍必出）----
  output logic [W-1:0]                             resp_valid,
  output logic [W-1:0]                             resp_miss,
  output logic [W-1:0][N_DUPS-1:0][PADDR_W-1:0]    resp_paddr,
  output logic [W-1:0][N_DUPS-1:0][XLEN-1:0]       resp_gpaddr,
  output logic [W-1:0][N_DUPS-1:0][1:0]            resp_pbmt,
  output logic [W-1:0][XLEN-1:0]                   resp_fullva,
  output logic [W-1:0][MEMIDX_W-1:0]               resp_memidx,
  output logic [W-1:0]                             resp_ptw_back,
  output logic [W-1:0]                             resp_is_for_vs_non_leaf_pte,
  output logic [W-1:0]                             resp_excp_pf_ld,
  output logic [W-1:0]                             resp_excp_pf_st,
  output logic [W-1:0]                             resp_excp_gpf_ld,
  output logic [W-1:0]                             resp_excp_gpf_st,
  output logic [W-1:0]                             resp_excp_af_ld,
  output logic [W-1:0]                             resp_excp_af_st,
  output logic [W-1:0]                             resp_excp_is_hyper,
  output logic [W-1:0]                             resp_excp_va_need_ext,

  // ---- 向 L2TLB(PTW) 要翻译 ----
  output logic [W-1:0]              ptw_req_valid,
  output logic [W-1:0][VPN_W-1:0]   ptw_req_vpn,
  output logic [W-1:0][1:0]         ptw_req_s2xlate,
  output logic [W-1:0]              ptw_req_get_gpa,
  input  logic                      ptw_resp_valid,   // resp.ready 恒 1，fire == valid
  input  ptw_resp_t                 ptw_resp,

  // ---- PMP 检查（把 paddr 交给外面的 PMPChecker）----
  output logic [W-1:0]              pmp_valid,
  output logic [W-1:0][PADDR_W-1:0] pmp_addr,
  output logic [W-1:0][2:0]         pmp_cmd,
  output logic [W-1:0][1:0]         pmp_mode,

  // ---- miss 但不能发 PTW 请求时，叫请求方重来 ----
  output logic [W-1:0]              tlbreplay,

  // ---- 两个 perf 事件：access / miss（各自打两拍出去）----
  output logic [5:0]                perf_access,
  output logic [5:0]                perf_miss,

  // ---- entries（TlbStorageWrapper）查询/回填接口 ----
  output logic [W-1:0]                          stor_r_req_valid,
  output logic [W-1:0][VPN_W-1:0]               stor_r_req_vpn,
  output logic [W-1:0][1:0]                     stor_r_req_s2xlate,
  input  logic [W-1:0]                          stor_r_hit,
  input  logic [W-1:0][N_DUPS-1:0][PPN_W-1:0]   stor_r_ppn,
  input  logic [W-1:0][N_DUPS-1:0][1:0]         stor_r_pbmt,
  input  logic [W-1:0][N_DUPS-1:0][1:0]         stor_r_g_pbmt,
  input  tlb_perm_t [W-1:0][N_DUPS-1:0]         stor_r_perm,
  input  tlb_gperm_t [W-1:0][N_DUPS-1:0]        stor_r_g_perm,
  input  logic [W-1:0][N_DUPS-1:0][1:0]         stor_r_s2xlate,
  output logic                                  stor_w_valid,

  // ---- difftest：DiffL1TLBEvent 的 339 位 payload，每 lane 一份 ----
  output logic [W-1:0][338:0]                   difftest_packed
);

  // perf 计数宽度：最多 W 个 lane 同时命中，故 $clog2(W+1) 位（golden 实测 base 3 位、
  // _1 2 位），再零扩展到 golden 的 6 位端口。
  localparam int PERF_W = $clog2(W + 1);
  // pre-fault 的 st 方向打拍寄存器要不要留：端口在、或 difftest 要读，二者之一即可。
  localparam logic [W-1:0] KEEP_ST_PRE = HAS_ST_EXCP | {W{DIFFTEST_EN}};
  // 只要有任意一条 lane 要 gpaddr，模块级那四个 gpa 负载寄存器就得在。
  localparam bit ANY_GPADDR = |HAS_GPADDR;

  // ===========================================================================
  // §CSR 译码（全部用延迟后的 csr，见 DelayN_7）
  // ===========================================================================
  wire sv39_en     = csr.satp_mode  == SV39;
  wire sv48_en     = csr.satp_mode  == SV48;
  wire sv39vs_en   = csr.vsatp_mode == SV39;
  wire sv48vs_en   = csr.vsatp_mode == SV48;
  wire sv39x4_en   = csr.hgatp_mode == SV39;
  wire sv48x4_en   = csr.hgatp_mode == SV48;
  wire s1_en_any   = sv39_en   | sv48_en;
  wire vs_en_any   = sv39vs_en | sv48vs_en;
  wire s2_en_any   = vs_en_any | sv39x4_en | sv48x4_en;

  // useDmode=true（dtlb），所以基准特权级取 dmode；hypervisor 指令改用 spvp。
  wire [1:0] mode_base = csr.priv_dmode;
  wire [1:0] mode_hyp  = {1'b0, csr.priv_spvp};

  // s2xlate 的四选一：三个 CSR mode 决定这次翻译要走哪几级。
  // Chisel 是 MuxCase，默认 noS2xlate；这里照抄展开后的形状。
  function automatic logic [1:0] pick_s2xlate(input logic virt_or_hyper,
                                              input logic [3:0] vsatp_mode,
                                              input logic [3:0] hgatp_mode);
    if (!virt_or_hyper)                              return NO_S2XLATE;
    else if ((|vsatp_mode) && (|hgatp_mode))         return ALL_STAGE;
    else if (vsatp_mode == 4'h0)                     return ONLY_S2;
    else                                             return {1'b0, hgatp_mode == 4'h0};
  endfunction

  // ===========================================================================
  // §PTW 响应旁路的命中键
  // 本拍回来的 PTW 响应，取出 hit() 要用的那几项（见 hit_key_t 的注释）。
  // ===========================================================================
  hit_key_t ptw_key;
  always_comb begin
    ptw_key.s2xlate     = ptw_resp.s2xlate;
    ptw_key.s1_tag      = ptw_resp.s1.entry_tag;
    ptw_key.s1_asid     = ptw_resp.s1.entry_asid;
    ptw_key.s1_vmid     = ptw_resp.s1.entry_vmid;
    ptw_key.s1_n        = ptw_resp.s1.entry_n;
    ptw_key.s1_level    = ptw_resp.s1.entry_level;
    ptw_key.s1_perm_g   = ptw_resp.s1.entry_perm_g;
    ptw_key.s1_addr_low = ptw_resp.s1.addr_low;
    ptw_key.s1_valididx = ptw_resp.s1.valididx;
    ptw_key.s2_tag      = ptw_resp.s2.entry_tag;
    ptw_key.s2_vmid     = ptw_resp.s2.entry_vmid;
    ptw_key.s2_n        = ptw_resp.s2.entry_n;
    ptw_key.s2_level    = ptw_resp.s2.entry_level;
  end

  wire ptw_s1_is_leaf     = s1_is_leaf(ptw_resp);
  wire ptw_s1_is_fake_pte = s1_is_fake_pte(ptw_resp);

  // ===========================================================================
  // §状态声明
  // 用 unpacked 数组（`[W]` 在名字后面），这样每条 lane 是独立变量，
  // generate 里才能只给"该变体有这条 lane 的这个寄存器"的那些元素接驱动。
  // ★复位域★：golden 只有下面标了 [RST] 的寄存器带**异步**复位
  // （always_ff @(posedge clock or posedge reset)），其余一律无复位。
  // 全加复位是真 bug，而且 elaborate/lint 都不会报。
  // ===========================================================================
  // --- 请求打拍（enable = req_valid）---
  logic [VADDR_W-1:0]   req_out_vaddr        [W];
  logic [XLEN-1:0]      req_out_fullva       [W];  // gate: HAS_GPADDR
  logic [2:0]           req_out_cmd          [W];
  logic                 req_out_hyperinst    [W];
  logic                 req_out_hlvx         [W];
  logic                 req_out_is_prefetch  [W];
  logic                 req_out_frm_mabuf    [W];
  logic                 req_out_robidx_flag  [W];
  logic [ROB_IDX_W-1:0] req_out_robidx_value [W];
  logic                 virt_out             [W];
  logic [XLEN-1:0]      resp_fullva_r        [W];  // gate: HAS_RESP_FULLVA
  logic [MEMIDX_W-1:0]  resp_memidx_r        [W];  // gate: HAS_MEMIDX
  logic [VPN_W-1:0]     difftest_vpn_r       [W];
  // ★golden 自己就有的两个没人读的寄存器★：Chisel 里 XSPerfAccumulate 的
  // "first_access"/"first_miss" 两处各写了一个 RegEnable(isFirstIssue, req.valid)，
  // 计数器本身被消掉了，寄存器留下来。不许合并成一个，也不许删 —— FM 按名字/结构
  // 配对，少一个就是 ref 侧的 unmatched unread 点。
  logic                 first_issue_r        [W];
  logic                 first_issue_r2       [W];

  logic                 req_out_v            [W];  // [RST]
  // 同一个 RegNext(no_translate) 在 Chisel 里被写了两次（TLBRead 里叫 useReqS1Paddr、
  // perm 检查里叫 noTranslateReg），firtool 因此生成两个**值恒等**的寄存器。照抄。
  logic                 use_req_s1_paddr     [W];
  logic                 no_translate_r       [W];

  // --- PTW 响应旁路打拍（enable = ptw_resp_valid）---
  logic                 p_hit_last           [W];  // [RST]
  logic [PPN_W-1:0]     p_ppn                [W];
  logic [1:0]           p_pbmt               [W];
  tlb_perm_t            p_perm               [W];
  logic [PTE_PPN_W-1:0] p_gvpn               [W];  // gate: HAS_GPADDR
  logic [1:0]           p_g_pbmt             [W];
  tlb_gperm_t           p_g_perm             [W];
  logic [1:0]           p_s2xlate            [W];  // gate: HAS_GPADDR
  logic [1:0]           p_s1_level           [W];  // gate: HAS_GPADDR
  logic                 p_s1_is_leaf         [W];  // gate: HAS_GPADDR
  logic                 p_s1_is_fake_pte     [W];  // gate: HAS_GPADDR

  // --- handle_nonblock 里"上一拍的 PTW 响应"（每 lane 一份，见 hit_key_t）---
  hit_key_t             ptw_reg              [W];
  logic                 ptw_already_back_last[W];  // [RST]
  // 同样是 GatedValidRegNext(req.fire) 被写了两次：req_kill 门控用 last_req_fire、
  // perf 事件用 result_ok_last。两个寄存器值恒等，照抄。
  logic                 last_req_fire        [W];  // [RST] gate: HAS_REQ_KILL
  logic                 result_ok_last       [W];  // [RST]

  // --- 上一拍的 redirect（每 lane 一份，Chisel 在 TLBRead(i) 里各写了一次）---
  logic                 redirect_last_valid  [W];
  logic                 redirect_last_flag   [W];
  logic [ROB_IDX_W-1:0] redirect_last_value  [W];
  logic                 redirect_last_level  [W];

  // --- pre-fault 打拍：Chisel 的 perm_check 每条 lane 调 N_DUPS 次，
  //     每次都写一个 RegNext(prepf||pregpf||preaf) —— 于是每 (lane,dup) 一个。
  logic [N_DUPS-1:0]    pre_fault_r          [W];
  // 下面六个是 RegNext(prepf)/RegNext(pregpf)/RegNext(preaf) 各被写两次的结果
  //（ld 方向一份、st 方向一份），值两两恒等，一个都不能省。
  logic                 pre_pf_ld_r          [W];
  logic                 pre_pf_st_r          [W];  // gate: KEEP_ST_PRE
  logic                 pre_gpf_ld_r         [W];
  logic                 pre_gpf_st_r         [W];  // 恒留：hasGpf 内部要读
  logic                 pre_af_ld_r          [W];
  logic                 pre_af_st_r          [W];  // gate: KEEP_ST_PRE

  // --- difftest 打拍 ---
  logic                 difftest_valid_r     [W];
  logic                 difftest_s2x_r       [W];

  // --- 模块级 need_gpa 状态 ---
  logic                 need_gpa;                  // [RST]
  logic [8:0]           need_gpa_count;            // [RST] 512 次上限的看门狗
  logic                 need_clear_need_gpa;       // [RST]
  logic                 need_gpa_robidx_flag;
  logic [ROB_IDX_W-1:0] need_gpa_robidx_value;
  logic                 need_gpa_robidx_valid;     // [RST]
  logic [VPN_W-1:0]     need_gpa_vpn;
  logic [1:0]           need_gpa_s2xlate;          // [RST]
  logic                 resp_gpa_refill;           // [RST]
  logic [PTE_PPN_W-1:0] resp_gpa_gvpn;             // gate: ANY_GPADDR
  logic [1:0]           resp_s1_level;             // [RST] gate: ANY_GPADDR
  logic                 resp_s1_is_leaf;           // [RST] gate: ANY_GPADDR
  logic                 resp_s1_is_fake_pte;       // [RST] gate: ANY_GPADDR

  // --- perf 事件各打两拍 ---
  logic [PERF_W-1:0]    perf_acc_r,  perf_acc_r2;
  logic [PERF_W-1:0]    perf_miss_r, perf_miss_r2;

  // ===========================================================================
  // §拍 A：请求拍的组合逻辑
  // ===========================================================================
  logic [1:0]      premode        [W];
  logic            virt_or_hyp_in [W];
  logic [1:0]      req_in_s2xlate [W];
  logic            prevm_en       [W];
  logic            pres2x_en      [W];
  logic [1:0]      pmm            [W];
  logic [XLEN-1:0] eff_va         [W];
  logic            prepf          [W];
  logic            pregpf         [W];
  logic            preaf          [W];
  logic            pre_fault      [W];
  logic            p_hit_fast     [W];
  logic            sign_extend_va [W];  // 高位做符号扩展（=开了地址翻译）还是零扩展
  logic            va_pf48        [W];  // Sv48 下高 16 位不是 bit47 的符号扩展
  logic            va_pf39        [W];  // Sv39 下高 25 位不是 bit38 的符号扩展
  logic            va_checking    [W];  // 本拍要做 fullva 高位检查
  logic            va_in_xlate    [W];  // 本拍走地址翻译（否则是直通物理地址）

  for (genvar i = 0; i < W; i++) begin : g_req_phase
    assign premode[i]        = req_hyperinst[i] ? mode_hyp : mode_base;
    assign virt_or_hyp_in[i] = csr.priv_virt | req_hyperinst[i];
    assign req_in_s2xlate[i] = pick_s2xlate(virt_or_hyp_in[i], csr.vsatp_mode, csr.hgatp_mode);
    assign prevm_en[i]       = ~virt_or_hyp_in[i] & s1_en_any & (premode[i] != MODE_M);
    assign pres2x_en[i]      =  virt_or_hyp_in[i] & s2_en_any & (premode[i] != MODE_M);

    // PMM（指针掩码）：按当前特权级/虚拟化状态选一个 envcfg.PMM 字段。
    // 第一条 `ifetch || hlvx` 里的 ifetch 对 dtlb 恒 0，故只剩 hlvx。
    always_comb begin
      if (req_hlvx[i])                                             pmm[i] = 2'h0;
      else if (premode[i] == MODE_M)                               pmm[i] = csr.pmm_mseccfg;
      else if ((virt_or_hyp_in[i] & csr.priv_vmxr) | csr.priv_mxr) pmm[i] = 2'h0;
      else if (~virt_or_hyp_in[i] & (premode[i] == MODE_S))        pmm[i] = csr.pmm_menvcfg;
      else if ( virt_or_hyp_in[i] & (premode[i] == MODE_S))        pmm[i] = csr.pmm_henvcfg;
      else if (req_hyperinst[i] & (csr.priv_imode == MODE_U))      pmm[i] = csr.pmm_hstatus;
      else if (premode[i] == MODE_U)                               pmm[i] = csr.pmm_senvcfg;
      else                                                         pmm[i] = 2'h0;
    end

    // EffectiveVa：按 PMM 把 fullva 的高位掩掉。开了地址翻译时高位做符号扩展
    //（虚地址要求高位是低位符号的重复），否则零扩展。
    assign sign_extend_va[i] = prevm_en[i] | (pres2x_en[i] & (|csr.vsatp_mode));
    always_comb begin
      if (pmm[i] == PMLEN7)
        eff_va[i] = sign_extend_va[i] ? {{7 {req_fullva[i][56]}}, req_fullva[i][56:0]}
                                      : {7'h0,  req_fullva[i][56:0]};
      else if (pmm[i] == PMLEN16)
        eff_va[i] = sign_extend_va[i] ? {{16{req_fullva[i][47]}}, req_fullva[i][47:0]}
                                      : {16'h0, req_fullva[i][47:0]};
      else
        eff_va[i] = req_fullva[i];
    end

    // pre 故障：高位越界，不查页表就知道结果。checkfullva 只有访存口会置。
    //   prepf  = VS/S 级虚地址高位不是符号扩展
    //   pregpf = G 级客户机物理地址超出 Sv39x4/Sv48x4 的范围（比 pf 多 2 位）
    //   preaf  = 不翻译时地址超出物理地址位宽
    assign va_pf48[i]   = ({{16{eff_va[i][47]}}, eff_va[i][47:0]} != eff_va[i]);
    assign va_pf39[i]   = ({{25{eff_va[i][38]}}, eff_va[i][38:0]} != eff_va[i]);
    assign va_checking[i] = req_valid[i] & req_checkfullva[i];
    assign va_in_xlate[i] = prevm_en[i] | pres2x_en[i];
    assign pregpf[i] = va_checking[i] & va_in_xlate[i] & (req_in_s2xlate[i] == ONLY_S2)
                       & (sv48x4_en ? (|eff_va[i][XLEN-1:50])
                                    : (sv39x4_en & (|eff_va[i][XLEN-1:41])));
    assign prepf[i]  = va_checking[i] & va_in_xlate[i] & (req_in_s2xlate[i] != ONLY_S2)
                       & (((req_in_s2xlate[i] == ONLY_S1) | (req_in_s2xlate[i] == ALL_STAGE))
                            ? (sv48vs_en ? va_pf48[i] : (sv39vs_en & va_pf39[i]))
                            : (sv48_en   ? va_pf48[i] : (sv39_en   & va_pf39[i])));
    assign preaf[i]  = va_checking[i] & ~va_in_xlate[i] & (|eff_va[i][XLEN-1:PADDR_W]);
    assign pre_fault[i] = prepf[i] | pregpf[i] | preaf[i];

    // PTW 响应旁路：本拍回来的 PTW 结果如果正好是这条请求要的页，下一拍直接用它，
    // 不用等它写进 entries 再查（entries 这一拍还在写）。
    assign p_hit_fast[i] = ptw_hit(ptw_key, req_vaddr[i][VADDR_W-1:OFF_W],
                                   csr.satp_asid, csr.vsatp_asid, csr.hgatp_vmid)
                           & ptw_resp_valid
                           & (req_in_s2xlate[i] == ptw_resp.s2xlate);

    // entries 查询：请求拍发地址，响应拍取结果。
    assign stor_r_req_valid[i]   = req_valid[i];
    assign stor_r_req_vpn[i]     = req_vaddr[i][VADDR_W-1:OFF_W];
    assign stor_r_req_s2xlate[i] = req_in_s2xlate[i];
  end

  // 旁路 ppn：两级翻译时最终物理页号来自 G-stage，否则来自 VS-stage。
  // gvpn 是喂给 G-stage 的中间结果：只有 G-stage 时就是请求的 vpn，
  // 否则是 VS-stage 翻出来的 ppn（Chisel 的 Mux 把 36 位零扩展到 38 位）。
  logic [PPN_W-1:0]  bypass_ppn_s1 [W];
  logic [VPN_W-1:0]  bypass_gvpn   [W];
  logic [PPN_W-1:0]  bypass_ppn    [W];
  for (genvar i = 0; i < W; i++) begin : g_bypass_ppn
    assign bypass_ppn_s1[i] = s1_gen_ppn(ptw_resp, req_vaddr[i][VADDR_W-1:OFF_W]);
    assign bypass_gvpn[i]   = (req_in_s2xlate[i] == ONLY_S2)
                              ? req_vaddr[i][VADDR_W-1:OFF_W]
                              : {{(VPN_W-PPN_W){1'b0}}, bypass_ppn_s1[i]};
    assign bypass_ppn[i]    = ((req_in_s2xlate[i] == ONLY_S2)
                               | (req_in_s2xlate[i] == ALL_STAGE))
                              ? s2_gen_ppn(ptw_resp, bypass_gvpn[i])
                              : bypass_ppn_s1[i];
  end

  // ===========================================================================
  // §打拍
  // 分成好几个 always_ff 写，只是为了让"这组寄存器为什么存在"讲得清楚；
  // golden 把它们塞在同一个 always 块里，对 FM 没有区别。
  // ===========================================================================
  for (genvar i = 0; i < W; i++) begin : g_regs
    // --- 请求现场：req.fire 时把请求存下来，响应拍再用 ---
    always_ff @(posedge clock) begin
      if (req_valid[i]) begin
        req_out_vaddr[i]        <= req_vaddr[i];
        req_out_cmd[i]          <= req_cmd[i];
        virt_out[i]             <= csr.priv_virt;
        difftest_vpn_r[i]       <= req_vaddr[i][VADDR_W-1:OFF_W];
      end
    end
    // 下面这几组各自带一个 mask：父级没接这个输入的 lane，golden 里连寄存器都没有。
    if (HAS_IS_PREFETCH[i]) begin : g_is_prefetch
      always_ff @(posedge clock) if (req_valid[i]) req_out_is_prefetch[i] <= req_is_prefetch[i];
    end else begin : g_no_is_prefetch
      always_comb req_out_is_prefetch[i] = 1'b0;
    end
    if (HAS_HYPERINST[i]) begin : g_hyperinst
      always_ff @(posedge clock) if (req_valid[i]) req_out_hyperinst[i] <= req_hyperinst[i];
    end else begin : g_no_hyperinst
      always_comb req_out_hyperinst[i] = 1'b0;
    end
    if (HAS_HLVX[i]) begin : g_hlvx
      always_ff @(posedge clock) if (req_valid[i]) req_out_hlvx[i] <= req_hlvx[i];
    end else begin : g_no_hlvx
      always_comb req_out_hlvx[i] = 1'b0;
    end
    if (HAS_FRM_MABUF[i]) begin : g_frm_mabuf
      always_ff @(posedge clock) if (req_valid[i]) req_out_frm_mabuf[i] <= req_frm_mabuf[i];
    end else begin : g_no_frm_mabuf
      always_comb req_out_frm_mabuf[i] = 1'b0;
    end
    if (HAS_ROBIDX[i]) begin : g_robidx
      always_ff @(posedge clock) if (req_valid[i]) begin
        req_out_robidx_flag[i]  <= req_robidx_flag[i];
        req_out_robidx_value[i] <= req_robidx_value[i];
      end
    end else begin : g_no_robidx
      always_comb req_out_robidx_flag[i] = 1'b0;
      always_comb req_out_robidx_value[i] = '0;
    end
    // first_issue 只喂 XSPerfAccumulate，firtool 把统计消掉之后剩下两个没人读的
    // 打拍寄存器。★golden 留着它们，所以不许删★；但父级没接
    // debug_isFirstIssue 的 lane，golden 自己也没有。
    if (HAS_FIRST_ISSUE[i]) begin : g_first_issue
      always_ff @(posedge clock) if (req_valid[i]) begin
        first_issue_r[i]  <= req_first_issue[i];
        first_issue_r2[i] <= req_first_issue[i];
      end
    end else begin : g_no_first_issue
      always_comb first_issue_r[i] = 1'b0;
      always_comb first_issue_r2[i] = 1'b0;
    end
    // req_out.fullva 存的是 EffectiveVa（Chisel 里 `req_out(i).fullva := EffectiveVa(i)`
    // 紧跟在 `req_out(i) := req(i).bits` 后面覆盖掉原值）。
    if (HAS_GPADDR[i]) begin : g_req_fullva
      always_ff @(posedge clock) if (req_valid[i]) req_out_fullva[i] <= eff_va[i];
    end else begin : g_no_req_fullva
      always_comb req_out_fullva[i] = '0;
    end
    if (HAS_RESP_FULLVA[i]) begin : g_resp_fullva
      always_ff @(posedge clock) if (req_valid[i]) resp_fullva_r[i] <= eff_va[i];
    end else begin : g_no_resp_fullva
      always_comb resp_fullva_r[i] = '0;
    end
    if (HAS_MEMIDX[i]) begin : g_resp_memidx
      always_ff @(posedge clock) if (req_valid[i]) resp_memidx_r[i] <= req_memidx[i];
    end else begin : g_no_resp_memidx
      always_comb resp_memidx_r[i] = '0;
    end

    // --- 无 enable 的一拍延迟 ---
    always_ff @(posedge clock) begin
      redirect_last_valid[i]  <= redirect_valid;
      redirect_last_flag[i]   <= redirect_robidx_flag;
      redirect_last_value[i]  <= redirect_robidx_value;
      redirect_last_level[i]  <= redirect_level;
      difftest_s2x_r[i]       <= virt_or_hyp_in[i];
    end
    // useReqS1Paddr / noTranslateReg 是 golden 写了两遍的**同值重复寄存器**
    // （见 §状态声明的注释），要么两个都有、要么两个都没有。
    if (HAS_NO_TRANSLATE[i]) begin : g_no_translate_r
      always_ff @(posedge clock) begin
        use_req_s1_paddr[i] <= req_no_translate[i];
        no_translate_r[i]   <= req_no_translate[i];
      end
    end else begin : g_no_no_translate_r
      always_comb use_req_s1_paddr[i] = 1'b0;
      always_comb no_translate_r[i] = 1'b0;
    end
    if (HAS_PRE_EXCP[i]) begin : g_pre_excp
      always_ff @(posedge clock) begin
        pre_pf_ld_r[i]  <= prepf[i];
        pre_gpf_ld_r[i] <= pregpf[i];
        pre_gpf_st_r[i] <= pregpf[i];
        pre_af_ld_r[i]  <= preaf[i];
      end
    end else begin : g_no_pre_excp
      always_comb pre_pf_ld_r[i] = 1'b0;
      always_comb pre_gpf_ld_r[i] = 1'b0;
      always_comb pre_gpf_st_r[i] = 1'b0;
      always_comb pre_af_ld_r[i] = 1'b0;
    end
    // difftest.valid 被关掉的变体（pftlb）里这个寄存器没人读，golden 把它消掉了。
    // difftest_vpn_r / req_s2xlate_REG 不受影响 —— payload 的其余字段还在接出去。
    if (DIFFTEST_EN) begin : g_difftest_valid
      always_ff @(posedge clock) difftest_valid_r[i] <= req_valid[i];
    end else begin : g_no_difftest_valid
      always_comb difftest_valid_r[i] = 1'b0;
    end
    if (KEEP_ST_PRE[i]) begin : g_st_pre
      always_ff @(posedge clock) begin
        pre_pf_st_r[i] <= prepf[i];
        pre_af_st_r[i] <= preaf[i];
      end
    end else begin : g_no_st_pre
      always_comb pre_pf_st_r[i] = 1'b0;
      always_comb pre_af_st_r[i] = 1'b0;
    end
    // N_DUPS 个**值恒等**的拷贝：Chisel 的 perm_check 每个 dup 调一次，每次都写一个
    // RegNext(prepf||pregpf||preaf)。合并成一个是"抹平 golden 的冗余结构"，不许。
    if (HAS_PRE_EXCP[i]) begin : g_pre_fault
      always_ff @(posedge clock) pre_fault_r[i] <= {N_DUPS{pre_fault[i]}};
    end else begin : g_no_pre_fault
      always_comb pre_fault_r[i] = '0;
    end

    // --- 带异步复位的一拍延迟（Chisel 的 GatedValidRegNext / RegInit）---
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        req_out_v[i]             <= 1'b0;
        p_hit_last[i]            <= 1'b0;
        ptw_already_back_last[i] <= 1'b0;
        result_ok_last[i]        <= 1'b0;
      end else begin
        // ValidHold(req.fire && !kill, resp.fire, flush_pipe) 里 resp.fire 恒 1、
        // flush_pipe 端口被父级消掉（恒 0），所以化简成一个普通 RegNext。
        req_out_v[i]             <= req_valid[i] & ~req_kill_bit[i];
        p_hit_last[i]            <= p_hit_fast[i];
        ptw_already_back_last[i] <= ptw_resp_valid;
        result_ok_last[i]        <= req_valid[i];
      end
    end
    if (HAS_REQ_KILL[i]) begin : g_last_fire
      always_ff @(posedge clock or posedge reset) begin
        if (reset) last_req_fire[i] <= 1'b0;
        else       last_req_fire[i] <= req_valid[i];
      end
    end else begin : g_no_last_fire
      always_comb last_req_fire[i] = 1'b0;
    end

    // --- PTW 响应旁路寄存器（ptw_resp_bypass 里那一串 RegEnable）---
    always_ff @(posedge clock) begin
      if (ptw_resp_valid) begin
        p_ppn[i]      <= bypass_ppn[i];
        p_pbmt[i]     <= ptw_resp.s1.entry_pbmt;
        p_perm[i].pf  <= ptw_resp.s1.pf;
        p_perm[i].af  <= ptw_resp.s1.af;
        p_perm[i].v   <= ptw_resp.s1.entry_v;
        p_perm[i].d   <= ptw_resp.s1.entry_perm_d;
        p_perm[i].a   <= ptw_resp.s1.entry_perm_a;
        p_perm[i].u   <= ptw_resp.s1.entry_perm_u;
        p_perm[i].x   <= ptw_resp.s1.entry_perm_x;
        p_perm[i].w   <= ptw_resp.s1.entry_perm_w;
        p_perm[i].r   <= ptw_resp.s1.entry_perm_r;
        p_g_pbmt[i]   <= ptw_resp.s2.entry_pbmt;
        p_g_perm[i].pf <= ptw_resp.s2.gpf;
        p_g_perm[i].af <= ptw_resp.s2.gaf;
        p_g_perm[i].d  <= ptw_resp.s2.entry_perm_d;
        p_g_perm[i].a  <= ptw_resp.s2.entry_perm_a;
        p_g_perm[i].x  <= ptw_resp.s2.entry_perm_x;
        p_g_perm[i].w  <= ptw_resp.s2.entry_perm_w;
        p_g_perm[i].r  <= ptw_resp.s2.entry_perm_r;
      end
    end
    if (HAS_GPADDR[i]) begin : g_bypass_gpa
      always_ff @(posedge clock) begin
        if (ptw_resp_valid) begin
          p_gvpn[i]           <= (req_in_s2xlate[i] == ONLY_S2)
                                 ? {{(PTE_PPN_W-GVPN_W){1'b0}}, ptw_resp.s2.entry_tag}
                                 : s1_gen_gvpn(ptw_resp, req_vaddr[i][VADDR_W-1:OFF_W]);
          p_s2xlate[i]        <= ptw_resp.s2xlate;
          p_s1_level[i]       <= ptw_resp.s1.entry_level;
          p_s1_is_leaf[i]     <= ptw_s1_is_leaf;
          p_s1_is_fake_pte[i] <= ptw_s1_is_fake_pte;
        end
      end
    end else begin : g_no_bypass_gpa
      always_comb p_gvpn[i] = '0;
      always_comb p_s2xlate[i] = '0;
      always_comb p_s1_level[i] = '0;
      always_comb p_s1_is_leaf[i] = 1'b0;
      always_comb p_s1_is_fake_pte[i] = 1'b0;
    end

    // --- handle_nonblock 的 "上一拍 PTW 响应" ---
    always_ff @(posedge clock) if (ptw_resp_valid) ptw_reg[i] <= ptw_key;
  end

  // ===========================================================================
  // §拍 B：响应拍
  // ===========================================================================
  logic                 is_hyper_inst   [W];
  logic [1:0]           mode            [W];
  logic                 virt_or_hyp_out [W];
  logic                 sum_eff         [W];
  logic                 mxr_eff         [W];
  logic [1:0]           req_out_s2xlate [W];
  logic                 port_xlate_en   [W];
  logic                 only_s2         [W];
  logic                 all_stage       [W];
  logic                 is_itlb         [W];
  logic                 hit_read        [W];
  logic                 miss_read       [W];
  logic [PADDR_W-1:0]   not_xlate_paddr [W];
  logic [XLEN-1:0]      cross_page_va   [W];
  logic [1:0]           vpn_idx         [W];
  logic [OFF_W-1:0]     gpaddr_offset   [W];
  logic                 has_gpf         [W];
  logic                 need_gpa_match_out [W];   // 用 req_out_s2xlate 比（TLBRead 里）
  logic                 need_gpa_match_ptw [W];   // 用 req_s2xlate    比（handle_nonblock 里）
  logic                 last_cycle_redirect[W];
  logic                 cur_redirect       [W];
  logic                 can_get_gpa        [W];
  logic [1:0]           req_s2xlate_ptw    [W];
  logic                 ptw_just_back      [W];
  logic                 ptw_already_back   [W];
  logic                 need_replay        [W];

  // 从 entries / PTW 旁路二选一得到的表项内容
  logic [PPN_W-1:0]     sel_ppn     [W][N_DUPS];
  logic [1:0]           sel_pbmt    [W][N_DUPS];
  logic [1:0]           sel_g_pbmt  [W][N_DUPS];
  tlb_perm_t            sel_perm    [W][N_DUPS];
  tlb_gperm_t           sel_g_perm  [W][N_DUPS];
  logic [1:0]           sel_s2xlate [W][N_DUPS];
  logic [1:0]           pbmt_res    [W][N_DUPS];
  // 下面四个在 Chisel 里也写在 d 循环里，但取值与 d 无关（p_* 是每 lane 一份、
  // resp_s1_* 是模块级），firtool 因此只生成了每 lane 一份。照抄成每 lane 一份。
  logic                 sel_is_fake_pte [W];
  logic                 sel_is_leaf     [W];
  logic [1:0]           sel_level       [W];
  logic [PTE_PPN_W-1:0] sel_gvpn        [W];

  // 权限检查的中间量（每 lane 每 dup 一份）
  logic is_ld [W], is_st [W], is_inst [W];
  logic af_fault   [W][N_DUPS];
  logic has_pf     [W][N_DUPS];
  logic s1_valid   [W][N_DUPS];
  logic s2_valid   [W][N_DUPS];
  logic perm_fake_pte [W][N_DUPS];
  logic perm_non_leaf [W][N_DUPS];
  logic excp_pf_ld [W][N_DUPS], excp_pf_st [W][N_DUPS], excp_pf_instr [W][N_DUPS];
  logic excp_gpf_ld[W][N_DUPS], excp_gpf_st[W][N_DUPS], excp_gpf_instr[W][N_DUPS];
  logic excp_af_ld [W][N_DUPS], excp_af_st [W][N_DUPS], excp_af_instr [W][N_DUPS];
  logic excp_vs_non_leaf [W][N_DUPS];

  for (genvar i = 0; i < W; i++) begin : g_resp_phase
    assign is_hyper_inst[i]   = req_out_v[i] & req_out_hyperinst[i];
    assign mode[i]            = is_hyper_inst[i] ? mode_hyp : mode_base;
    assign virt_or_hyp_out[i] = virt_out[i] | is_hyper_inst[i];
    assign sum_eff[i]         = virt_or_hyp_out[i] ? csr.priv_vsum : csr.priv_sum;
    assign mxr_eff[i]         = virt_or_hyp_out[i] ? (csr.priv_vmxr | csr.priv_mxr)
                                                   : csr.priv_mxr;
    assign req_out_s2xlate[i] = pick_s2xlate(virt_or_hyp_out[i], csr.vsatp_mode,
                                             csr.hgatp_mode);
    assign only_s2[i]         = req_out_s2xlate[i] == ONLY_S2;
    assign all_stage[i]       = req_out_s2xlate[i] == ALL_STAGE;
    // 本口这一拍到底要不要翻译：开了页表 + 特权级低于 M + 请求没说"直接给物理地址"
    assign port_xlate_en[i]   =
        ((~virt_or_hyp_out[i] & s1_en_any & (mode[i] != MODE_M))
         | (virt_or_hyp_out[i] & s2_en_any & (mode[i] != MODE_M)))
        & ~use_req_s1_paddr[i];
    assign is_itlb[i]         = req_out_cmd[i][1:0] == CMD_EXEC;

    // entries 命中 或 上一拍 PTW 旁路命中
    assign hit_read[i] = stor_r_hit[i] | p_hit_last[i];

    for (genvar d = 0; d < N_DUPS; d++) begin : g_sel
      assign sel_ppn[i][d]     = p_hit_last[i] ? p_ppn[i]    : stor_r_ppn[i][d];
      assign sel_pbmt[i][d]    = p_hit_last[i] ? p_pbmt[i]   : stor_r_pbmt[i][d];
      assign sel_g_pbmt[i][d]  = p_hit_last[i] ? p_g_pbmt[i] : stor_r_g_pbmt[i][d];
      assign sel_perm[i][d]    = p_hit_last[i] ? p_perm[i]   : stor_r_perm[i][d];
      assign sel_g_perm[i][d]  = p_hit_last[i] ? p_g_perm[i] : stor_r_g_perm[i][d];
      assign sel_s2xlate[i][d] = p_hit_last[i] ? p_s2xlate[i]: stor_r_s2xlate[i][d];
    end
    assign sel_is_fake_pte[i] = p_hit_last[i] ? p_s1_is_fake_pte[i] : resp_s1_is_fake_pte;
    assign sel_is_leaf[i]     = p_hit_last[i] ? p_s1_is_leaf[i]     : resp_s1_is_leaf;
    assign sel_level[i]       = p_hit_last[i] ? p_s1_level[i]       : resp_s1_level;
    assign sel_gvpn[i]        = p_hit_last[i] ? p_gvpn[i]           : resp_gpa_gvpn;

    // miss 的两种来源：(1) 要翻译却没命中；(2) 命中了但报 gpf，需要专门去要 gpaddr。
    assign miss_read[i] =
        (~hit_read[i] & port_xlate_en[i])
        | (has_gpf[i] & ~p_hit_last[i]
           & ~(resp_gpa_refill & need_gpa_match_out[i]) & ~only_s2[i]
           & ~req_out_is_prefetch[i] & ~last_cycle_redirect[i]);

    // 不翻译时的物理地址：请求自己带的 pmp_addr（★取的是本拍的 req_in，不是打拍值★），
    // 否则就是虚地址低 48 位（SignExt(vaddr,48) 对 50 位来说就是截断）。
    assign not_xlate_paddr[i] = use_req_s1_paddr[i] ? req_pmp_addr[i]
                                                   : req_out_vaddr[i][PADDR_W-1:0];

    // 跨页非对齐访存：fullva 与 vaddr 不在同一页时用 vaddr（新页首地址），
    // 否则用 fullva（原始地址）。取指（itlb）永远用 vaddr —— 但本模块是 dtlb，
    // is_itlb 只在 cmd 是 exec 时为真，照抄 golden 保留这一支。
    assign cross_page_va[i] =
        (is_itlb[i] | (req_out_fullva[i][OFF_W] != req_out_vaddr[i][OFF_W]))
        ? {{(XLEN-VADDR_W){1'b0}}, req_out_vaddr[i]}
        : req_out_fullva[i];

    // ★Mux1H 在 firtool 里是"按位或"，不是优先选择★（三条条件互斥，见 Chisel）
    assign vpn_idx[i] = {(sel_is_fake_pte[i] & sv39vs_en), 1'b0}
                      | {2{sel_is_fake_pte[i] & sv48vs_en}}
                      | (sel_is_fake_pte[i] ? 2'h0 : (sel_level[i] - 2'h1));
    assign gpaddr_offset[i] =
        sel_is_leaf[i] ? cross_page_va[i][OFF_W-1:0]
                       : {get_vpnn(cross_page_va[i][VADDR_W-1:OFF_W], vpn_idx[i]), 3'h0};

    assign resp_valid[i]    = req_out_v[i];
    assign resp_fullva[i]   = resp_fullva_r[i];
    assign resp_memidx[i]   = resp_memidx_r[i];
    assign resp_ptw_back[i] = ptw_resp_valid;

    for (genvar d = 0; d < N_DUPS; d++) begin : g_resp_dup
      assign resp_paddr[i][d] = port_xlate_en[i]
                                ? {sel_ppn[i][d], req_out_vaddr[i][OFF_W-1:0]}
                                : not_xlate_paddr[i];
      // 前置故障那一拍 gpaddr 直接回 fullva（Chisel 的 when 分支覆盖）
      assign resp_gpaddr[i][d] =
          pre_fault_r[i][d] ? req_out_fullva[i]
        : (sel_s2xlate[i][d] == ONLY_S2) ? cross_page_va[i]
        : {{(XLEN-PTE_PPN_W-OFF_W){1'b0}}, sel_gvpn[i], gpaddr_offset[i]};
      // Svpbmt：两级都开时 VS-stage 的 pbmt 优先，为 0 才看 G-stage 的
      always_comb begin
        case (req_out_s2xlate[i])
          ONLY_S2:   pbmt_res[i][d] = sel_g_pbmt[i][d];
          ALL_STAGE: pbmt_res[i][d] = (|sel_pbmt[i][d]) ? sel_pbmt[i][d] : sel_g_pbmt[i][d];
          default:   pbmt_res[i][d] = sel_pbmt[i][d];   // ONLY_S1 与 NO_S2XLATE 同
        endcase
      end
      assign resp_pbmt[i][d] = port_xlate_en[i] ? pbmt_res[i][d] : 2'h0;
    end

    // 任一 dup 的前置故障都会把 miss 压掉（Chisel 里每个 dup 的 when 各写一次 miss）
    assign resp_miss[i] = ~(|pre_fault_r[i]) & miss_read[i];
  end

  // ===========================================================================
  // §权限检查（Chisel 的 perm_check，每 lane 每 dup 调一次）
  //
  // 两级翻译时要查两套权限：VS-stage 用 perm（报 pf），G-stage 用 g_perm（报 gpf）。
  // 优先级：af > pf > gpf —— 访问故障说明 PTW 自己就没走通，页故障的结论不可信。
  // 另外"上一拍就判出的高位越界故障"（pre_fault_r）会整段覆盖掉正常结果。
  // ===========================================================================
  logic mode_check   [W][N_DUPS];
  logic ld_perm_fail [W][N_DUPS], st_perm_fail [W][N_DUPS], instr_perm_fail [W][N_DUPS];
  logic ld_pf        [W][N_DUPS], st_pf        [W][N_DUPS], instr_pf        [W][N_DUPS];
  logic ld_update    [W][N_DUPS], st_update    [W][N_DUPS], instr_update    [W][N_DUPS];
  logic ld_gpf       [W][N_DUPS], st_gpf       [W][N_DUPS], instr_gpf       [W][N_DUPS];
  logic g_ld_update  [W][N_DUPS], g_st_update  [W][N_DUPS], g_instr_update  [W][N_DUPS];
  logic fault_valid  [W][N_DUPS];

  for (genvar i = 0; i < W; i++) begin : g_cmd_kind
    // amo（cmd==5）算写；lr（cmd==4）低两位是 0，所以算读。
    assign is_ld[i]   = ~(|req_out_cmd[i][1:0]) & (req_out_cmd[i] != CMD_AMO);
    assign is_st[i]   = (req_out_cmd[i][1:0] == CMD_WRITE) | (req_out_cmd[i] == CMD_AMO);
    assign is_inst[i] = req_out_cmd[i][1:0] == CMD_EXEC;
  end

  for (genvar i = 0; i < W; i++) begin : g_perm_lane
    for (genvar d = 0; d < N_DUPS; d++) begin : g_perm_dup
      // af：只有 G-stage 时看 g_perm.af，两级都有时两个都算
      assign af_fault[i][d] = (~only_s2[i] & sel_perm[i][d].af)
                            | ((only_s2[i] | all_stage[i]) & sel_g_perm[i][d].af);

      // U/S 模式的页归属检查（ifetch 对 dtlb 恒 0，故 SUM 那一项只剩 ~sum）
      assign mode_check[i][d] = ~(((mode[i] == MODE_U) & ~sel_perm[i][d].u)
                                | ((mode[i] == MODE_S) &  sel_perm[i][d].u & ~sum_eff[i]));
      // MXR：允许把只可执行页当可读页读（hlvx 则强制只看 x）
      assign ld_perm_fail[i][d] = ~(mode_check[i][d]
                                    & (req_out_hlvx[i] ? sel_perm[i][d].x
                                       : (sel_perm[i][d].r | (mxr_eff[i] & sel_perm[i][d].x))));
      assign st_perm_fail[i][d]    = ~(mode_check[i][d] & sel_perm[i][d].w);
      assign instr_perm_fail[i][d] = ~(mode_check[i][d] & sel_perm[i][d].x);
      assign ld_pf[i][d]    = (ld_perm_fail[i][d]    | sel_perm[i][d].pf) & is_ld[i];
      assign st_pf[i][d]    = (st_perm_fail[i][d]    | sel_perm[i][d].pf) & is_st[i];
      assign instr_pf[i][d] = (instr_perm_fail[i][d] | sel_perm[i][d].pf) & is_inst[i];
      // A/D 位没置上也要报页故障，让软件去补（本核不做硬件 A/D 更新）
      assign ld_update[i][d]    = ~sel_perm[i][d].a & is_ld[i];
      assign st_update[i][d]    = (~sel_perm[i][d].a | ~sel_perm[i][d].d) & is_st[i];
      assign instr_update[i][d] = ~sel_perm[i][d].a & is_inst[i];

      // 伪 PTE / 非叶子：PTW 在中间级就停了，这时的权限位没有意义，
      // 不报 pf，而是把 isForVSnonLeafPTE 报给 CSR 去改 htinst。
      assign perm_fake_pte[i][d] = ~sel_perm[i][d].v & ~sel_perm[i][d].pf
                                   & ~sel_perm[i][d].af & ~only_s2[i];
      assign perm_non_leaf[i][d] = ~(sel_perm[i][d].r | sel_perm[i][d].w | sel_perm[i][d].x)
                                   & sel_perm[i][d].v & ~sel_perm[i][d].pf & ~sel_perm[i][d].af;

      assign s1_valid[i][d]    = port_xlate_en[i] & ~only_s2[i];
      assign s2_valid[i][d]    = port_xlate_en[i] & (only_s2[i] | all_stage[i]);
      assign fault_valid[i][d] = s1_valid[i][d] | s2_valid[i][d];
      assign has_pf[i][d] = (ld_pf[i][d] | ld_update[i][d] | st_pf[i][d] | st_update[i][d]
                             | instr_pf[i][d] | instr_update[i][d])
                            & s1_valid[i][d] & ~af_fault[i][d]
                            & ~perm_fake_pte[i][d] & ~perm_non_leaf[i][d];

      // G-stage：没有 U/SUM 检查（客户机物理地址不分用户页），MXR 用宿主机的 mxr
      assign ld_gpf[i][d] = (~(req_out_hlvx[i] ? sel_g_perm[i][d].x
                               : (sel_g_perm[i][d].r | (csr.priv_mxr & sel_g_perm[i][d].x)))
                             | sel_g_perm[i][d].pf) & is_ld[i];
      assign st_gpf[i][d] = (~sel_g_perm[i][d].w | sel_g_perm[i][d].pf) & is_st[i];
      assign instr_gpf[i][d] = (~sel_g_perm[i][d].x | sel_g_perm[i][d].pf) & is_inst[i];
      assign g_ld_update[i][d]    = ~sel_g_perm[i][d].a & is_ld[i];
      assign g_st_update[i][d]    = (~sel_g_perm[i][d].a | ~sel_g_perm[i][d].d) & is_st[i];
      assign g_instr_update[i][d] = ~sel_g_perm[i][d].a & is_inst[i];

      // 前置故障拍：把上一拍算出的 prepf/pregpf/preaf 按访问方向分发，
      // 其余一律清零（instr 方向 golden 直接写死 false）。
      assign excp_pf_ld[i][d] = pre_fault_r[i][d]
          ? (pre_pf_ld_r[i] & is_ld[i])
          : ((ld_pf[i][d] | ld_update[i][d]) & s1_valid[i][d] & ~af_fault[i][d]
             & ~perm_fake_pte[i][d] & ~perm_non_leaf[i][d]);
      assign excp_pf_st[i][d] = pre_fault_r[i][d]
          ? (pre_pf_st_r[i] & is_st[i])
          : ((st_pf[i][d] | st_update[i][d]) & s1_valid[i][d] & ~af_fault[i][d]
             & ~perm_fake_pte[i][d] & ~perm_non_leaf[i][d]);
      assign excp_pf_instr[i][d] = ~pre_fault_r[i][d]
          & ((instr_pf[i][d] | instr_update[i][d]) & s1_valid[i][d] & ~af_fault[i][d]
             & ~perm_fake_pte[i][d] & ~perm_non_leaf[i][d]);
      assign excp_gpf_ld[i][d] = pre_fault_r[i][d]
          ? (pre_gpf_ld_r[i] & is_ld[i])
          : ((ld_gpf[i][d] | g_ld_update[i][d]) & s2_valid[i][d] & ~af_fault[i][d]
             & ~has_pf[i][d]);
      assign excp_gpf_st[i][d] = pre_fault_r[i][d]
          ? (pre_gpf_st_r[i] & is_st[i])
          : ((st_gpf[i][d] | g_st_update[i][d]) & s2_valid[i][d] & ~af_fault[i][d]
             & ~has_pf[i][d]);
      assign excp_gpf_instr[i][d] = ~pre_fault_r[i][d]
          & ((instr_gpf[i][d] | g_instr_update[i][d]) & s2_valid[i][d] & ~af_fault[i][d]
             & ~has_pf[i][d]);
      // af 按 cmd 的原始方向分（lr 也算读、sc 也算写），不是 is_ld/is_st
      assign excp_af_ld[i][d] = pre_fault_r[i][d]
          ? (pre_af_ld_r[i] & (req_out_cmd[i][1:0] == CMD_READ))
          : (af_fault[i][d] & (req_out_cmd[i][1:0] == CMD_READ) & fault_valid[i][d]);
      assign excp_af_st[i][d] = pre_fault_r[i][d]
          ? (pre_af_st_r[i] & (req_out_cmd[i][1:0] == CMD_WRITE))
          : (af_fault[i][d] & (req_out_cmd[i][1:0] == CMD_WRITE) & fault_valid[i][d]);
      assign excp_af_instr[i][d] = ~pre_fault_r[i][d]
          & (af_fault[i][d] & (req_out_cmd[i][1:0] == CMD_EXEC) & fault_valid[i][d]);
      assign excp_vs_non_leaf[i][d] = ~pre_fault_r[i][d]
          & (perm_non_leaf[i][d] | perm_fake_pte[i][d]);
    end

    // 接出去的 excp 只有第 0 份；isForVSnonLeafPTE 在 Chisel 里不带 dup 下标，
    // 于是 d 循环里被**最后一个 dup 覆盖**（last-connect），所以取 N_DUPS-1。
    assign resp_excp_pf_ld[i]   = excp_pf_ld[i][0];
    assign resp_excp_pf_st[i]   = excp_pf_st[i][0];
    assign resp_excp_gpf_ld[i]  = excp_gpf_ld[i][0];
    assign resp_excp_gpf_st[i]  = excp_gpf_st[i][0];
    assign resp_excp_af_ld[i]   = excp_af_ld[i][0];
    assign resp_excp_af_st[i]   = excp_af_st[i][0];
    assign resp_excp_is_hyper[i]        = is_hyper_inst[i];
    assign resp_excp_va_need_ext[i]     = ~pre_fault_r[i][0];
    assign resp_is_for_vs_non_leaf_pte[i] = excp_vs_non_leaf[i][N_DUPS-1];

    // 命中了却报 G-stage 故障 —— 这时要专门去问 PTW 要 gpaddr（见 §need_gpa）
    assign has_gpf[i] = hit_read[i]
                        & (excp_gpf_ld[i][0] | excp_gpf_st[i][0] | excp_gpf_instr[i][0]);
  end

  // ===========================================================================
  // §need_gpa —— 整个模块最绕的一段
  //
  // 背景：G-stage 出故障时 CSR 要看到客户机物理地址 gpaddr。gpaddr 只能由 PTW 算，
  // 所以 TLB 要带着 getGpa 标志再问 PTW 一次。这期间：
  //   · 整个 TLB（不是某条 lane）进入 need_gpa 状态，记下是哪条 vpn / 哪个 robIdx；
  //   · 其它 lane 的 miss 一律 tlbreplay，不许发新的 PTW 请求（不然回来的响应分不清）；
  //   · PTW 回来且对得上，就把 gvpn/level/isLeaf/isFakePte 存进 resp_gpa_* 并置 refill；
  //   · 出故障那条请求被 redirect 冲掉、或等太久（need_gpa_count 512 次），就放弃。
  //
  // ★跨 lane 的优先级是"后面的 lane 覆盖前面的"★：Chisel 在 for(i) 里对同一批
  // 模块级寄存器反复 when/elsewhen，last-connect 语义 = 下标大的赢。下面的 for 循环
  // 按同样顺序写，**不要改成并行选择**。
  // ===========================================================================
  logic                 clear_gpa      [W];
  logic                 want_gpa       [W];
  logic                 second_clear   [W];
  logic [W-1:0]         state_clear_vec;
  logic [W-1:0]         need_clear_vec;
  logic                 need_gpa_wire;          // 本拍有 lane 抢到了 need_gpa
  logic                 ptw_gpa_hit;            // PTW 送回来的正是我等的那一页
  logic                 need_gpa_count_full;
  // 次态
  logic                 nx_need_gpa;
  logic [VPN_W-1:0]     nx_need_gpa_vpn;
  logic [1:0]           nx_need_gpa_s2xlate;
  logic                 nx_need_gpa_robidx_flag;
  logic [ROB_IDX_W-1:0] nx_need_gpa_robidx_value;
  logic                 nx_need_gpa_robidx_valid;
  logic                 nx_resp_gpa_refill;
  logic [PTE_PPN_W-1:0] nx_resp_gpa_gvpn;
  logic [1:0]           nx_resp_s1_level;
  logic                 nx_resp_s1_is_leaf;
  logic                 nx_resp_s1_is_fake_pte;

  assign need_gpa_count_full = &need_gpa_count;
  assign ptw_gpa_hit = ptw_resp_valid & need_gpa
                     & (need_gpa_s2xlate == ptw_resp.s2xlate)
                     & (need_gpa_vpn == ptw_get_vpn(ptw_resp, need_gpa_vpn));

  for (genvar i = 0; i < W; i++) begin : g_gpa_cond
    assign need_gpa_match_out[i] = (need_gpa_vpn == req_out_vaddr[i][VADDR_W-1:OFF_W])
                                 & (need_gpa_s2xlate == req_out_s2xlate[i]);
    assign last_cycle_redirect[i] = rob_need_flush(redirect_last_valid[i],
                                                   redirect_last_level[i],
                                                   redirect_last_flag[i],
                                                   redirect_last_value[i],
                                                   req_out_robidx_flag[i],
                                                   req_out_robidx_value[i]);
    assign cur_redirect[i] = rob_need_flush(redirect_valid, redirect_level,
                                            redirect_robidx_flag, redirect_robidx_value,
                                            req_out_robidx_flag[i],
                                            req_out_robidx_value[i]);
    // 只有"这条请求已经到了 ROB 头部 / 是取指 / 是 misalign buffer 发来的"才值得
    // 花一次 PTW 往返去要 gpaddr；否则直接 replay，等它成为最老的再说。
    assign can_get_gpa[i] = ({req_out_robidx_flag[i], req_out_robidx_value[i]}
                             == {rob_pending_flag, rob_pending_value})
                            | is_itlb[i] | req_out_frm_mabuf[i];
    // flush_pipe 端口被父级消掉（恒 0），所以 `isitlb && flush_pipe(i)` 这一项没了。
    assign clear_gpa[i] = (~is_itlb[i] & need_gpa_robidx_valid
                           & rob_need_flush(redirect_valid, redirect_level,
                                            redirect_robidx_flag, redirect_robidx_value,
                                            need_gpa_robidx_flag, need_gpa_robidx_value))
                        | need_clear_need_gpa | need_gpa_count_full;
    assign want_gpa[i] = req_out_v[i] & ~p_hit_last[i]
                       & ~(resp_gpa_refill & need_gpa_match_out[i]) & ~only_s2[i]
                       & has_gpf[i] & ~need_gpa & ~req_kill[i] & ~req_out_is_prefetch[i]
                       & ~cur_redirect[i] & ~last_cycle_redirect[i];
    assign second_clear[i] = req_out_v[i] & has_gpf[i] & resp_gpa_refill
                           & need_gpa_match_out[i];
  end

  always_comb begin
    nx_need_gpa              = need_gpa;
    nx_need_gpa_vpn          = need_gpa_vpn;
    nx_need_gpa_s2xlate      = need_gpa_s2xlate;
    nx_need_gpa_robidx_flag  = need_gpa_robidx_flag;
    nx_need_gpa_robidx_value = need_gpa_robidx_value;
    nx_need_gpa_robidx_valid = need_gpa_robidx_valid;
    nx_resp_gpa_refill       = resp_gpa_refill;
    nx_resp_gpa_gvpn         = resp_gpa_gvpn;
    nx_resp_s1_level         = resp_s1_level;
    nx_resp_s1_is_leaf       = resp_s1_is_leaf;
    nx_resp_s1_is_fake_pte   = resp_s1_is_fake_pte;
    // 这两个是 Chisel 的 WireInit(false)，循环里只置位不清零 —— 于是跨 lane 是"或"。
    need_gpa_wire   = 1'b0;
    state_clear_vec = '0;
    need_clear_vec  = '0;
    need_replay     = '{default: 1'b0};
    for (int i = 0; i < W; i++) begin
      if (clear_gpa[i]) begin
        nx_need_gpa              = 1'b0;
        state_clear_vec[i]       = 1'b1;
        nx_resp_gpa_refill       = 1'b0;
        nx_need_gpa_vpn          = '0;
        nx_need_gpa_robidx_valid = 1'b0;
      end else if (want_gpa[i]) begin
        if (can_get_gpa[i]) begin
          need_gpa_wire            = 1'b1;
          nx_need_gpa              = 1'b1;
          nx_need_gpa_vpn          = req_out_vaddr[i][VADDR_W-1:OFF_W];
          nx_need_gpa_s2xlate      = req_out_s2xlate[i];
          nx_resp_gpa_refill       = 1'b0;
          nx_need_gpa_robidx_flag  = req_out_robidx_flag[i];
          nx_need_gpa_robidx_value = req_out_robidx_value[i];
          nx_need_gpa_robidx_valid = 1'b1;
          // 本拍 PTW 旁路就命中了，那这次 getGpa 立刻就能收尾
          if (p_hit_fast[i]) need_clear_vec[i] = 1'b1;
        end else begin
          need_replay[i] = 1'b1;
        end
      end else if (ptw_gpa_hit) begin
        nx_resp_gpa_gvpn       = (ptw_resp.s2xlate == ONLY_S2)
                                 ? {{(PTE_PPN_W-GVPN_W){1'b0}}, ptw_resp.s2.entry_tag}
                                 : s1_gen_gvpn(ptw_resp, need_gpa_vpn);
        nx_resp_s1_level       = ptw_resp.s1.entry_level;
        nx_resp_s1_is_leaf     = ptw_s1_is_leaf;
        nx_resp_s1_is_fake_pte = ptw_s1_is_fake_pte;
        nx_resp_gpa_refill     = 1'b1;
      end
      // 上面那串 when 之外还有独立的一条：gpaddr 已经拿到并对上了，退出 need_gpa。
      if (second_clear[i]) begin
        nx_need_gpa        = 1'b0;
        state_clear_vec[i] = 1'b1;
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      need_gpa              <= 1'b0;
      need_gpa_count        <= 9'h0;
      need_clear_need_gpa   <= 1'b0;
      need_gpa_robidx_valid <= 1'b0;
      need_gpa_s2xlate      <= 2'h0;
      resp_gpa_refill       <= 1'b0;
    end else begin
      need_gpa              <= nx_need_gpa;
      need_clear_need_gpa   <= |need_clear_vec;
      need_gpa_robidx_valid <= nx_need_gpa_robidx_valid;
      need_gpa_s2xlate      <= nx_need_gpa_s2xlate;
      resp_gpa_refill       <= nx_resp_gpa_refill;
      // 看门狗：连着 512 次 getGpa 响应还没收尾就强制退出，防止死等
      if (need_gpa_wire | (|state_clear_vec) | need_gpa_count_full)
        need_gpa_count <= 9'h0;
      else if (need_gpa & ptw_resp_valid & ptw_resp.get_gpa)
        need_gpa_count <= need_gpa_count + 9'h1;
    end
  end
  always_ff @(posedge clock) begin
    need_gpa_robidx_flag  <= nx_need_gpa_robidx_flag;
    need_gpa_robidx_value <= nx_need_gpa_robidx_value;
    need_gpa_vpn          <= nx_need_gpa_vpn;
  end
  if (ANY_GPADDR) begin : g_gpa_payload
    always_ff @(posedge clock) resp_gpa_gvpn <= nx_resp_gpa_gvpn;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        resp_s1_level       <= 2'h0;
        resp_s1_is_leaf     <= 1'b0;
        resp_s1_is_fake_pte <= 1'b0;
      end else begin
        resp_s1_level       <= nx_resp_s1_level;
        resp_s1_is_leaf     <= nx_resp_s1_is_leaf;
        resp_s1_is_fake_pte <= nx_resp_s1_is_fake_pte;
      end
    end
  end else begin : g_no_gpa_payload
    // 没有任何 lane 要 gpaddr 的变体（dtlb_pf），这四个寄存器 golden 里不存在。
    assign resp_gpa_gvpn       = '0;
    assign resp_s1_level       = '0;
    assign resp_s1_is_leaf     = 1'b0;
    assign resp_s1_is_fake_pte = 1'b0;
  end

  // ===========================================================================
  // §handle_nonblock：miss 了要么发 PTW 请求，要么叫请求方重来
  // ===========================================================================
  for (genvar i = 0; i < W; i++) begin : g_ptw_req
    // ★注意和 req_out_s2xlate 的区别★：这里用的是 req_out.hyperinst 本身，
    // 没有和 req_out_v 与一下。golden 两个表达式并存，不是笔误。
    assign req_s2xlate_ptw[i] = pick_s2xlate(virt_out[i] | req_out_hyperinst[i],
                                             csr.vsatp_mode, csr.hgatp_mode);
    // 本拍刚回来的 PTW 响应 / 上一拍回来的 PTW 响应，正好就是这条 miss 要的页
    assign ptw_just_back[i] = ptw_resp_valid
                            & (req_s2xlate_ptw[i] == ptw_resp.s2xlate)
                            & ptw_hit(ptw_key, req_out_vaddr[i][VADDR_W-1:OFF_W],
                                      csr.satp_asid, csr.vsatp_asid, csr.hgatp_vmid);
    assign ptw_already_back[i] = ptw_already_back_last[i]
                               & (req_s2xlate_ptw[i] == ptw_reg[i].s2xlate)
                               & ptw_hit(ptw_reg[i], req_out_vaddr[i][VADDR_W-1:OFF_W],
                                         csr.satp_asid, csr.vsatp_asid, csr.hgatp_vmid);
    assign need_gpa_match_ptw[i] = (need_gpa_vpn == req_out_vaddr[i][VADDR_W-1:OFF_W])
                                 & (need_gpa_s2xlate == req_s2xlate_ptw[i]);

    // 三种 replay：PTW 刚回来（重查一次就命中了）/ 别人占着 need_gpa / 本条被取消
    assign tlbreplay[i] = HAS_TLBREPLAY
        & ((req_kill[i] & last_req_fire[i])
           | (req_out_v[i] & miss_read[i]
              & ((ptw_just_back[i] | ptw_already_back[i] | need_replay[i])
                 | (need_gpa & ~need_gpa_match_ptw[i] & ~resp_gpa_refill))));
    assign ptw_req_valid[i] = ~(req_kill[i] & last_req_fire[i])
        & req_out_v[i] & miss_read[i]
        & ~(ptw_just_back[i] | ptw_already_back[i] | need_replay[i])
        & ~(need_gpa & ~need_gpa_match_ptw[i] & ~resp_gpa_refill);
    assign ptw_req_vpn[i]     = req_out_vaddr[i][VADDR_W-1:OFF_W];
    assign ptw_req_s2xlate[i] = req_s2xlate_ptw[i];
    assign ptw_req_get_gpa[i] = has_gpf[i] & hit_read[i];

    // ---- PMP：把算出来的物理地址交给外面的 PMPChecker ----
    // no_translate 的请求即使 req_out_v=0 也要查 PMP（它的地址是请求方直接给的）。
    assign pmp_valid[i] = req_out_v[i] | no_translate_r[i];
    assign pmp_addr[i]  = no_translate_r[i] ? req_pmp_addr[i] : resp_paddr[i][0];
    assign pmp_cmd[i]   = req_out_hlvx[i] ? CMD_RX : req_out_cmd[i];
    // 预取请求不按 hypervisor 的 spvp 降级（它没有"代客户机执行"的语义）
    assign pmp_mode[i]  = (req_out_is_prefetch[i] | ~is_hyper_inst[i]) ? mode_base : mode_hyp;
  end

  // ===========================================================================
  // §entries 回填：PTW 响应写进全相联表
  // 三种情况不写：这次是专门要 gpaddr 的、TLB 正处在 need_gpa 状态、MMU 正在被刷。
  // ===========================================================================
  wire flush_mmu = sfence_valid_d | csr.satp_changed | csr.vsatp_changed
                 | csr.hgatp_changed | csr.priv_virt_changed;
  assign stor_w_valid = ptw_resp_valid & ~ptw_resp.get_gpa & ~need_gpa & ~need_gpa_wire
                        & ~flush_mmu;

  // ===========================================================================
  // §perf 事件：两个计数，各自打两拍出去（generatePerfEvent）
  // ===========================================================================
  logic [W-1:0] perf_acc_vec, perf_miss_vec;
  for (genvar i = 0; i < W; i++) begin : g_perf_vec
    assign perf_acc_vec[i]  = port_xlate_en[i] & result_ok_last[i];
    assign perf_miss_vec[i] = ptw_req_valid[i];
  end
  if (HAS_PERF) begin : g_perf
    always_ff @(posedge clock) begin
      perf_acc_r   <= PERF_W'($countones(perf_acc_vec));
      perf_acc_r2  <= perf_acc_r;
      perf_miss_r  <= PERF_W'($countones(perf_miss_vec));
      perf_miss_r2 <= perf_miss_r;
    end
    assign perf_access = {{(6-PERF_W){1'b0}}, perf_acc_r2};
    assign perf_miss   = {{(6-PERF_W){1'b0}}, perf_miss_r2};
  end else begin : g_no_perf
    assign perf_acc_r   = '0;
    assign perf_acc_r2  = '0;
    assign perf_miss_r  = '0;
    assign perf_miss_r2 = '0;
    assign perf_access  = 6'h0;
    assign perf_miss    = 6'h0;
  end

  // ===========================================================================
  // §difftest：每条 lane 一个 DiffL1TLBEvent，payload 打成 339 位从 bore 端口出去
  // 上报条件 = 这一拍真的完成了一次翻译（有请求、没被取消、没 miss、没故障）。
  // pftlb 不参与对比（Chisel 里一句 difftest.valid := false.B），见 DIFFTEST_EN。
  // ===========================================================================
  logic [W-1:0] dt_valid, dt_pf, dt_gpf, dt_af;
  for (genvar i = 0; i < W; i++) begin : g_difftest
    assign dt_pf[i]  = excp_pf_instr[i][0]  | excp_pf_st[i][0]  | excp_pf_ld[i][0];
    assign dt_gpf[i] = excp_gpf_instr[i][0] | excp_gpf_st[i][0] | excp_gpf_ld[i][0];
    assign dt_af[i]  = excp_af_instr[i][0]  | excp_af_st[i][0]  | excp_af_ld[i][0];
    assign dt_valid[i] = DIFFTEST_EN
        & difftest_valid_r[i] & ~req_kill[i] & req_out_v[i] & ~resp_miss[i]
        & ~dt_pf[i] & ~dt_af[i] & ~dt_gpf[i] & port_xlate_en[i];
    assign difftest_packed[i] = {
        dt_valid[i],
        {csr.satp_mode,  csr.satp_asid,  csr.satp_ppn},                 // satp  64
        {{(XLEN-VPN_W){1'b0}}, difftest_vpn_r[i]},                      // vpn   64
        {{(XLEN-PPN_W){1'b0}}, resp_paddr[i][0][PADDR_W-1:OFF_W]},      // ppn   64
        {csr.vsatp_mode, csr.vsatp_asid, csr.vsatp_ppn},                // vsatp 64
        {csr.hgatp_mode, csr.hgatp_vmid, csr.hgatp_ppn},                // hgatp 64
        pick_s2xlate(difftest_s2x_r[i], csr.vsatp_mode, csr.hgatp_mode),// s2xlate 2
        {2'h0, hart_id},                                                // coreid  8
        8'(DIFF_INDEX_0 + i)                                            // index   8
    };
  end

endmodule
