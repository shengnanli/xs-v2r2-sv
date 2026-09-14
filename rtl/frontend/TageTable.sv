// =============================================================================
// xs_TageTable_core —— TAGE 方向预测器的「单条几何历史长度标签表」核
//
// 对应 Chisel: xiangshan.frontend.TageTable（Tage.scala，class TageTable）
//
// 【它在前端 BPU 的位置】
//   TAGE（TAgged GEometric history length）是香山 S2/S3 级的主力条件分支方向预测器。
//   完整 TAGE 由「1 个基预测器(bimodal/base table) + N 张标签表(TageTable)」组成；本模块
//   就是其中 *一张* 标签表。N 张表用「几何递增」的全局历史长度（本设计 8/13/32/119 拍）
//   各自索引，历史越长越能捕捉远距离相关性。预测时所有表并行查询，由外层 Tage 选「命中且
//   历史最长」的表作 provider；不命中则回退到基预测器(altpred)。
//
//        s0(req): pc + 折叠历史 ──hash──▶ idx/tag ──▶ 读 SRAM ──┐
//                                                              ▼ s1
//                                            tag 比对 → 命中? ctr→方向, u→有用位
//        commit(update): pc + 原始历史 ──hash──▶ idx/tag ──▶ 改写 ctr/u/tag/valid
//
// 【一条目存什么 / 怎么给方向】
//   每个条目 = {valid, tag(TAG_LEN 位), ctr(3 位饱和计数)}，外加另存一份 u(useful) 位。
//     - tag：用 pc 与折叠历史异或得到的「校验位」。命中 = (读出 tag == 查询 tag) & valid。
//     - ctr：3 位饱和计数器，最高位即方向预测（>=4 → taken）。中间值 3/4 称「unconf」
//            （弱置信，刚分配的新条目），此时外层倾向用 altpred。
//     - u：useful 位。当本表 provider 命中且预测正确、而 altpred 会预测错时置 1，表示
//          「这条历史相关条目确实有用」。分配新条目只能挑 u=0 的空槽；u 位会被周期性
//          老化清零（reset_u），防止表被永久占满。
//
// 【折叠历史索引（FoldedHistory）——TAGE 的关键技巧】
//   要用「最长 119 拍全局历史」索引一张 2048 entry 的表，直接取历史低位会丢信息。
//   折叠历史把 HIST_LEN 位历史按目标宽度 L 切成若干 chunk 逐块异或，压成 L 位，既保留
//   了全部历史的影响，又恰好填满索引/ tag 宽度。本模块需要三份不同宽度的折叠历史：
//     - idx_fh ：宽 min(IDX_W, HIST_LEN)，与 pc 异或得到行索引 idx。
//     - tag_fh ：宽 min(HIST_LEN, TAG_LEN)，参与 tag 计算。
//     - alt_fh ：宽 min(HIST_LEN, TAG_LEN-1)，左移 1 位再参与 tag（让 tag 更分散）。
//   读路径(req)直接吃外层算好的折叠历史端口；更新路径(update)拿到的是「原始全局历史」，
//   需在本模块内用 compute_folded_ghist() 现折（见下）。两者算法一致，外层有 GHistDiff
//   断言保证读路径折叠历史与现折结果相等。
//   tag = (unhashed_idx ^ tag_fh ^ (alt_fh << 1))[TAG_LEN-1:0]
//   idx = (unhashed_idx ^ idx_fh)[IDX_W-1:0]，unhashed_idx = pc >> instOffsetBits
//
// 【分 bank 的物理组织】
//   逻辑上一张表有 NROWS_PER_BR=2048 行 × NUM_BR=2 way（两条并行分支各一份）。物理上
//   按 idx 低 2 位拆成 NBANKS=4 个 bank（各 512 行），每次请求只读命中那一个 bank
//   （单口 SRAM，省功耗、避免读写同 bank 冲突阻塞流水）。bank 内地址 = idx >> 2。
//
// 【两条分支(numBr) 与物理/逻辑 way 重排】
//   一个取指块最多含 2 条条件分支。为均衡两条分支在 SRAM 两个 way 上的占用，香山把
//   「逻辑分支号」按 unhashed_idx 低位异或后映射到「物理 way」(get_phy_br_idx)。读出后
//   再反映射回逻辑分支(get_lgc_br_idx，xor 自反)。本核保留该重排以与 golden 等价。
//
// 【silent update / 写旁路(WrBypass)】
//   若一次更新不会真正改变 ctr（饱和后同向、且非分配），则「静默」不写 SRAM(省功耗)。
//   又因连续两次更新同一行间隔短于 SRAM 写-读延迟，加 WrBypass 小缓存暂存最近写的 ctr，
//   更新时优先读旁路里的最新 ctr 再自增，避免用到 SRAM 里的陈旧值。每 bank 每分支一个。
//
// 【可读性要点】
//   - 条目用 tage_entry_t 结构体；ctr 用纯函数 inc_ctr / 饱和；折叠历史用 fold_hist()。
//   - 4 bank × 2 br 全用 genvar/for 展开，不手工堆 _0_0.._3_1。
//   - 物理/逻辑 way 重排写成 phy_br_idx()/oh1h，名字直述其意。
//   - bore*/sigFromSrams* 是 MBIST/DFT 旁路信号，对功能无影响，原样穿到 SRAM 黑盒。
//
// 【参数化 4 变体】
//   4 张表只差全局历史长度 HIST_LEN(8/13/32/119)，其余完全相同。HIST_LEN 决定三份折叠
//   历史端口的位宽（见上）。本核参数化 HIST_LEN/NROWS_PER_BR/TAG_LEN，wrapper 传不同值。
// =============================================================================

module xs_TageTable_core #(parameter int unsigned NROWS_PER_BR = 2048,                 // 每分支行数（逻辑深度）
  parameter int unsigned HIST_LEN     = 8,                    // 本表使用的全局历史长度
  parameter int unsigned TAG_LEN      = 8,                    // tag 位宽
  parameter int unsigned CTR_W        = 3,                    // ctr 饱和计数位宽
  parameter int unsigned PC_W         = 50,                   // 取指 PC 位宽 (VAddrBits)
  parameter int unsigned GHIST_W      = 256,                  // 原始全局历史位宽
  // 派生参数（不要外部覆盖）
  parameter int unsigned NUM_BR       = 2,
  parameter int unsigned NBANKS       = 4,
  parameter int unsigned BANK_IDX_W   = 2,                    // log2(NBANKS)
  parameter int unsigned IDX_W        = $clog2(NROWS_PER_BR), // =11
  parameter int unsigned BANK_SIZE    = NROWS_PER_BR/NBANKS,  // =512
  parameter int unsigned BANK_ADDR_W  = $clog2(BANK_SIZE),    // =9
  parameter int unsigned IDX_FH_W     = (HIST_LEN < IDX_W)        ? HIST_LEN : IDX_W,
  parameter int unsigned TAG_FH_W     = (HIST_LEN < TAG_LEN)      ? HIST_LEN : TAG_LEN,
  parameter int unsigned ALT_FH_W     = (HIST_LEN < (TAG_LEN-1))  ? HIST_LEN : (TAG_LEN-1),
  parameter int unsigned BORE_AW      = 9,  // us 的 bore 地址宽（table_banks 用 10）

  // ---- G1 锚点（fail-closed，无可用默认值）----------------------------------
  // 三份折叠历史的位数是本核最典型的**派生算术**：
  //   IDX_FH_W = min(HIST_LEN, IDX_W)、TAG_FH_W = min(HIST_LEN, TAG_LEN)、
  //   ALT_FH_W = min(HIST_LEN, TAG_LEN-1)
  // 只要 HIST_LEN / NROWS_PER_BR / TAG_LEN 有一个抄错，这三个位数就跟着错，而
  // 逻辑一行都不用改 —— 正是"只有 FM 才炸"的那类静默错误。
  // 薄文件把 golden 对应端口的位数（$bits(io_req_bits_folded_hist_hist_<n>_folded_hist)）
  // 原样传进来：那三个端口宽度由 G1 端口表决定（port_contract_lint 已对着 golden 核过），
  // 所以是**从 golden 现读**的常量，不是谁心算出来的期望值。
  parameter int unsigned G1_IDX_FH_W  = 0,
  parameter int unsigned G1_TAG_FH_W  = 0,
  parameter int unsigned G1_ALT_FH_W  = 0
)(
  input  logic                clock,
  input  logic                reset,

  // ---- 预测请求 (s0) ----
  output logic                io_req_ready,
  input  logic                io_req_valid,
  input  logic [PC_W-1:0]     io_req_bits_pc,
  input  logic [GHIST_W-1:0]  io_req_bits_ghist,        // 读路径不实际使用（仅 GHistDiff 断言）
  input  logic [IDX_FH_W-1:0] io_req_idx_fh,            // idx 折叠历史
  input  logic [TAG_FH_W-1:0] io_req_tag_fh,            // tag 折叠历史
  input  logic [ALT_FH_W-1:0] io_req_alt_fh,            // alt tag 折叠历史

  // ---- 预测响应 (s1)，每条逻辑分支一份 ----
  output logic                io_resps_0_valid,
  output logic [CTR_W-1:0]    io_resps_0_bits_ctr,
  output logic                io_resps_0_bits_u,
  output logic                io_resps_0_bits_unconf,
  output logic                io_resps_1_valid,
  output logic [CTR_W-1:0]    io_resps_1_bits_ctr,
  output logic                io_resps_1_bits_u,
  output logic                io_resps_1_bits_unconf,

  // ---- 更新 (commit)，每条逻辑分支一份 ----
  input  logic [PC_W-1:0]     io_update_pc,
  input  logic [GHIST_W-1:0]  io_update_ghist,
  input  logic                io_update_mask_0,
  input  logic                io_update_mask_1,
  input  logic                io_update_takens_0,
  input  logic                io_update_takens_1,
  input  logic                io_update_alloc_0,
  input  logic                io_update_alloc_1,
  input  logic [CTR_W-1:0]    io_update_oldCtrs_0,
  input  logic [CTR_W-1:0]    io_update_oldCtrs_1,
  input  logic                io_update_uMask_0,
  input  logic                io_update_uMask_1,
  input  logic                io_update_us_0,
  input  logic                io_update_us_1,
  input  logic                io_update_reset_u_0,
  input  logic                io_update_reset_u_1,

  // ---- DFT/MBIST 旁路：us 一组 + 4 个 table_banks 各一组（黑盒透传） ----
  input  logic [BORE_AW-1:0]  bore_us_addr,
  input  logic [BORE_AW-1:0]  bore_us_addr_rd,
  input  logic [15:0]         bore_us_wdata,
  input  logic [15:0]         bore_us_wmask,
  input  logic                bore_us_re,
  input  logic                bore_us_we,
  output logic [15:0]         bore_us_rdata,
  input  logic                bore_us_ack,
  input  logic                bore_us_selectedOH,
  input  logic [5:0]          bore_us_array,

  input  logic [BORE_AW:0]    bore_bank_addr    [NBANKS],
  input  logic [BORE_AW:0]    bore_bank_addr_rd [NBANKS],
  input  logic [23:0]         bore_bank_wdata   [NBANKS],
  input  logic [1:0]          bore_bank_wmask   [NBANKS],
  input  logic                bore_bank_re      [NBANKS],
  input  logic                bore_bank_we      [NBANKS],
  output logic [23:0]         bore_bank_rdata   [NBANKS],
  input  logic                bore_bank_ack     [NBANKS],
  input  logic                bore_bank_selectedOH [NBANKS],
  input  logic [5:0]          bore_bank_array   [NBANKS],

  // sigFromSrams：us 一组 + 4 banks 各一组（DFT 时钟控制，黑盒透传）
  input  logic [6:0]          sig_us,                   // 7 位打包 {cgen,mcp,ckbp,aux,bp,bypass,hold}
  input  logic [6:0]          sig_bank [NBANKS]
);


  // =========================================================================
  // §参数自检（elaboration-time system task）
  // $fatal 写在**模块体**里而不是 initial 里：VCS 在 elaborate 阶段就报
  // `Error-[FEST] $fatal elaboration system task` 并 rc=255 退出, 纯 elaborate /
  // 综合流程也拦得住; initial 形式只有仿真启动 time 0 才炸。Formality
  // (V-2023.12-SP3) 两种都读得进, 条件为真时打印同一条消息并把本模块降级成黑盒,
  // 被 fm_verdict 的 bbox 闸拦下, 仍是 fail-closed。
  // 消息里避开 UTF-8 含 0xAE 字节的汉字(位宽/宏/实/定/段/算…): VCS 在 elaboration
  // 消息里会把该字节打成 '.', 整句变乱码(运行期 $fatal 显示正常)。
  // =========================================================================
  if (G1_IDX_FH_W == 0 || G1_TAG_FH_W == 0 || G1_ALT_FH_W == 0)
    $fatal(1, "xs_TageTable_core: 薄文件必须传 G1_IDX_FH_W/G1_TAG_FH_W/G1_ALT_FH_W(= golden 三个 folded_hist 端口的 $bits), 不传不给过 -- 当前 %0d/%0d/%0d",
           G1_IDX_FH_W, G1_TAG_FH_W, G1_ALT_FH_W);
  if (IDX_FH_W != G1_IDX_FH_W)
    $fatal(1, "xs_TageTable_core: idx 折叠历史 min(HIST_LEN=%0d, IDX_W=%0d)=%0d 位, 但 golden 端口是 %0d 位",
           HIST_LEN, IDX_W, IDX_FH_W, G1_IDX_FH_W);
  if (TAG_FH_W != G1_TAG_FH_W)
    $fatal(1, "xs_TageTable_core: tag 折叠历史 min(HIST_LEN=%0d, TAG_LEN=%0d)=%0d 位, 但 golden 端口是 %0d 位",
           HIST_LEN, TAG_LEN, TAG_FH_W, G1_TAG_FH_W);
  if (ALT_FH_W != G1_ALT_FH_W)
    $fatal(1, "xs_TageTable_core: alt 折叠历史 min(HIST_LEN=%0d, TAG_LEN-1=%0d)=%0d 位, 但 golden 端口是 %0d 位",
           HIST_LEN, TAG_LEN-1, ALT_FH_W, G1_ALT_FH_W);

  // ---- 下面几条是锚点管不到的纯派生算术: 分 bank 的整除/取幂关系 ----
  // BANK_SIZE = NROWS_PER_BR/NBANKS 除不尽 -> 被静默截断, 高地址行永远访问不到。
  if (NROWS_PER_BR % NBANKS != 0)
    $fatal(1, "xs_TageTable_core: NROWS_PER_BR=%0d 除不尽 NBANKS=%0d, BANK_SIZE 会被截断",
           NROWS_PER_BR, NBANKS);
  // idx 低 BANK_IDX_W 位选 bank、高 BANK_ADDR_W 位当行号, 两段必须正好拼成 IDX_W。
  if (BANK_IDX_W + BANK_ADDR_W != IDX_W)
    $fatal(1, "xs_TageTable_core: bank 选择 %0d 位 + bank 内行号 %0d 位 != idx 的 %0d 位, 地址会被切错",
           BANK_IDX_W, BANK_ADDR_W, IDX_W);
  if ((32'd1 << BANK_IDX_W) != NBANKS)
    $fatal(1, "xs_TageTable_core: bank 选择 %0d 位能表示 %0d 个 bank, 但只有 %0d 个 -- 会越界",
           BANK_IDX_W, 32'd1 << BANK_IDX_W, NBANKS);

  // ===========================================================================
  // 局部类型与纯函数
  // ===========================================================================
  localparam int unsigned INST_OFF_BITS = 1;   // 指令对齐位（RVC，2 字节 → 1 位）

  // 一个条目（与 golden TageEntry 等价）
  typedef struct packed {
    logic               valid;
    logic [TAG_LEN-1:0] tag;
    logic [CTR_W-1:0]   ctr;
  } tage_entry_t;

  // ---- 3 位饱和计数自增：taken +1（封顶 7），否则 -1（封底 0） ----
  function automatic logic [CTR_W-1:0] inc_ctr(input logic [CTR_W-1:0] c, input logic taken);
    if (taken) return (&c)      ? c : (c + 1'b1);
    else       return (c == '0) ? c : (c - 1'b1);
  endfunction

  // ---- unconf：ctr 处于「弱置信」中点（恰好 011 或 100），新分配条目即此态 ----
  function automatic logic is_unconf(input logic [CTR_W-1:0] c);
    logic pos_unconf, neg_unconf;
    pos_unconf = (c == (1 << (CTR_W-1)));        // 100b：刚分配为 taken
    neg_unconf = (c == ((1 << (CTR_W-1)) - 1));  // 011b：刚分配为 not-taken
    return pos_unconf | neg_unconf;
  endfunction

  // ---- silent update：饱和后同向、又不是分配 → 写下去 ctr 不变，可静默跳过 ----
  function automatic logic is_silent(input logic [CTR_W-1:0] c, input logic taken);
    return (&c & taken) | (~(|c) & ~taken);
  endfunction

  // ---- 物理 way 重排说明 ----
  // phy = (unhashed_idx 低 log2(NUM_BR) 位) ^ 逻辑分支号。numBr=2 → 仅 unhashed_idx[0]
  // 决定是否交换两条分支。xor 自反，反映射用同一式子（见各 lgc_* 函数 / s1_swap）。

  // ===========================================================================
  // 折叠历史现折（仅更新路径用）：把 GHIST 按目标宽度 L 分块异或压成 L 位
  //   nChunks = ceil(HIST_LEN / L)，第 i 块 = ghist[min((i+1)L,HIST_LEN)-1 : i*L]。
  //   读路径的折叠历史由外层提供（io_req_*_fh），二者算法一致。
  // ===========================================================================
  function automatic logic [IDX_W-1:0] fold_hist(input logic [GHIST_W-1:0] gh, input int unsigned L);
    logic [IDX_W-1:0] acc;
    int unsigned hi;
    acc = '0;
    if (HIST_LEN > 0) begin
      for (int unsigned i = 0; i*L < HIST_LEN; i++) begin
        // 取 [i*L +: 本块长度] 并异或进 acc 低位
        logic [IDX_W-1:0] chunk;
        chunk = '0;
        hi = ((i+1)*L < HIST_LEN) ? ((i+1)*L) : HIST_LEN;   // 本块上界(不含)
        for (int unsigned b = i*L; b < hi; b++)
          chunk[b - i*L] = gh[b];
        acc = acc ^ chunk;
      end
    end
    return acc;
  endfunction

  // ===========================================================================
  // S0：读请求 hash —— 由 pc + 折叠历史算出行索引 idx / 校验 tag / bank 选择
  // ===========================================================================
  wire [PC_W-1-INST_OFF_BITS:0] req_unhashed = io_req_bits_pc[PC_W-1:INST_OFF_BITS];

  // idx = (unhashed ^ idx_fh) 取低 IDX_W 位；idx_fh 只覆盖低 IDX_FH_W 位，高位来自 unhashed
  wire [IDX_W-1:0] s0_idx =
      req_unhashed[IDX_W-1:0] ^ {{(IDX_W-IDX_FH_W){1'b0}}, io_req_idx_fh};

  // tag = (unhashed ^ tag_fh ^ (alt_fh<<1)) 取低 TAG_LEN 位
  wire [TAG_LEN-1:0] s0_tag =
      req_unhashed[TAG_LEN-1:0]
    ^ {{(TAG_LEN-TAG_FH_W){1'b0}}, io_req_tag_fh}
    ^ ({{(TAG_LEN-ALT_FH_W){1'b0}}, io_req_alt_fh} << 1);

  // bank 选择 one-hot：idx 低 BANK_IDX_W 位；bank 内地址 = idx >> BANK_IDX_W
  logic [NBANKS-1:0]      s0_bank_1h;
  wire  [BANK_ADDR_W-1:0] s0_bank_addr = s0_idx[IDX_W-1:BANK_IDX_W];
  always_comb
    for (int b = 0; b < NBANKS; b++)
      s0_bank_1h[b] = (s0_idx[BANK_IDX_W-1:0] == BANK_IDX_W'(b));

  wire req_fire = io_req_valid & io_req_ready;

  // ===========================================================================
  // Update 路径 hash —— 注意更新拿的是原始 ghist，需现折
  // ===========================================================================
  wire [PC_W-1-INST_OFF_BITS:0] upd_unhashed = io_update_pc[PC_W-1:INST_OFF_BITS];

  wire [IDX_W-1:0]   upd_idx_fh = fold_hist(io_update_ghist, IDX_W);          // 注：宽度同 idx
  wire [IDX_W-1:0]   upd_tag_fh = fold_hist(io_update_ghist, TAG_LEN);
  wire [IDX_W-1:0]   upd_alt_fh = fold_hist(io_update_ghist, TAG_LEN-1);

  wire [IDX_W-1:0] update_idx =
      upd_unhashed[IDX_W-1:0] ^ upd_idx_fh[IDX_W-1:0];
  wire [TAG_LEN-1:0] update_tag =
      upd_unhashed[TAG_LEN-1:0] ^ upd_tag_fh[TAG_LEN-1:0]
    ^ (upd_alt_fh[TAG_LEN-1:0] << 1);

  logic [NBANKS-1:0]      update_bank_1h;
  wire  [BANK_ADDR_W-1:0] update_bank_addr = update_idx[IDX_W-1:BANK_IDX_W];
  always_comb
    for (int b = 0; b < NBANKS; b++)
      update_bank_1h[b] = (update_idx[BANK_IDX_W-1:0] == BANK_IDX_W'(b));

  // 物理/逻辑分支号映射（numBr=2，仅看 idx[0]）。
  //   phy = idx[0] ^ lidx；输入两条逻辑分支信号据此可能交换。
  wire upd_swap = upd_unhashed[0];   // 1 → 物理 way 与逻辑分支号互换

  // ===========================================================================
  // 写旁路 wrbypass —— 每 bank 每逻辑分支一个，缓存最近写入的 ctr
  //   声明在 SRAM 例化之前；hit/hit_data 由各 WrBypass 反馈，供 wdata 计算。
  // ===========================================================================
  logic [NBANKS-1:0][NUM_BR-1:0]            wb_hit;
  logic [NBANKS-1:0][NUM_BR-1:0]            wb_hit_valid;
  logic [NBANKS-1:0][NUM_BR-1:0][CTR_W-1:0] wb_hit_ctr;

  // ===========================================================================
  // 计算每 bank 每物理 way 的写数据(ctr/tag/valid) 与 not_silent 标志
  //   逻辑分支 → 物理 way 重排后再算。alloc 时 ctr 直接置弱态(taken→4, ntk→3)；
  //   否则取「旁路命中值 或 oldCtr」自增。
  // ===========================================================================
  logic [NBANKS-1:0][NUM_BR-1:0] not_silent;             // 物理 way 维度
  tage_entry_t  bank_wdata [NBANKS][NUM_BR];             // 物理 way 维度

  // 把逐逻辑分支 update 信号按 swap 映射到物理 way pi 上使用。
  // 注意：物理 way 号 pi 是 genvar/常量，但 (pi^upd_swap) 含运行时信号 upd_swap，
  // 故不能写成「以 pi 为参数的 automatic function」——VCS 在 generate 连续赋值上下文里
  // 对这类函数求值会把结果整体污染成 X。这里改为直接内联三元选择（pi 取 genvar 字面量）。

  genvar gb, gp;
  generate
    for (gb = 0; gb < NBANKS; gb++) begin : g_wdata_bank
      for (gp = 0; gp < NUM_BR; gp++) begin : g_wdata_way
        // 该物理 way 对应的逻辑分支 = gp ^ upd_swap（用 1 位索引，避免 32 位 genvar 越界告警）
        localparam logic gp_bit = gp[0];
        wire li_idx = gp_bit ^ upd_swap;
        wire                taken  = li_idx ? io_update_takens_1  : io_update_takens_0;
        wire                alloc  = li_idx ? io_update_alloc_1   : io_update_alloc_0;
        wire [CTR_W-1:0]    oldctr = li_idx ? io_update_oldCtrs_1 : io_update_oldCtrs_0;
        // 旁路（按逻辑分支号索引 wrbypass）：物理 way gp → 逻辑分支 li_idx
        wire                wbh    = wb_hit      [gb][li_idx];
        wire                wbhv   = wb_hit_valid[gb][li_idx] & wbh;
        wire [CTR_W-1:0]    wbc    = wb_hit_ctr  [gb][li_idx];
        // 自增基准有两个候选：旁路命中值 wbc / commit 传入旧值 oldctr。
        // **先分别对两个候选算结果，再用 wbhv 三元选择**（与 golden 同构）：
        //   这样当 wbhv 在早期仿真为 X 但两候选结果相同时，三元 `x?v:v` 收敛为 v，
        //   避免"先选 base 得 X、再算得 X"的 X 悲观传播污染写使能。
        wire [CTR_W-1:0]    inc_wb  = inc_ctr(wbc,    taken);
        wire [CTR_W-1:0]    inc_old = inc_ctr(oldctr, taken);
        wire                nsil_wb  = ~is_silent(wbc,    taken);
        wire                nsil_old = ~is_silent(oldctr, taken);

        always_comb begin
          bank_wdata[gb][gp].valid = 1'b1;
          bank_wdata[gb][gp].tag   = update_tag;
          if (alloc)
            bank_wdata[gb][gp].ctr = taken ? CTR_W'(1 << (CTR_W-1))         // 100b 弱 taken
                                           : CTR_W'((1 << (CTR_W-1)) - 1);  // 011b 弱 ntk
          else
            bank_wdata[gb][gp].ctr = wbhv ? inc_wb : inc_old;
        end
        // 非静默 = (不会静默) | 分配。分配总是真写。
        assign not_silent[gb][gp] = (wbhv ? nsil_wb : nsil_old) | alloc;
      end
    end
  endgenerate

  // ---- 每 bank 的写 way mask（物理 way 维度）+ 写使能 ----
  //   某物理 way 要写 ⟺ 映射到它的逻辑分支本次 mask 置位 且 该 way not_silent。
  logic [NBANKS-1:0][NUM_BR-1:0] bank_way_mask;
  logic [NBANKS-1:0]             bank_wen;            // 本 bank 是否发生写
  // 物理 way pi 对应逻辑分支 (pi^upd_swap) 的 mask：way0→(upd_swap?mask1:mask0)，way1→(upd_swap?mask0:mask1)
  wire phy_mask0 = upd_swap ? io_update_mask_1 : io_update_mask_0;
  wire phy_mask1 = upd_swap ? io_update_mask_0 : io_update_mask_1;
  always_comb begin
    for (int b = 0; b < NBANKS; b++) begin
      bank_way_mask[b][0] = phy_mask0 & not_silent[b][0];
      bank_way_mask[b][1] = phy_mask1 & not_silent[b][1];
      bank_wen[b] = (|bank_way_mask[b]) & update_bank_1h[b];
    end
  end

  // ===========================================================================
  // S1 流水寄存：随 req_fire 推进 idx/tag/bank 选择/unhashed；
  //   s1_bank_has_write：本拍读的 bank 若同时正被写，则读出数据失效(resp_invalid)。
  // ===========================================================================
  logic                s1_swap_reg;   // 只需 unhashed[0]（way 反映射）；高位无扇出故只寄这一位
  logic [TAG_LEN-1:0]  s1_tag;
  logic [NBANKS-1:0]   s1_bank_1h;
  logic [NBANKS-1:0]   s1_bank_has_write;

  always_ff @(posedge clock) begin
    if (req_fire) begin
      s1_swap_reg <= io_req_bits_pc[INST_OFF_BITS]; // = unhashed[0]（唯一被读的位）
      s1_tag      <= s0_tag;
      s1_bank_1h  <= s0_bank_1h;
    end
    if (io_req_valid)   // 与 golden 一致：用 valid（非 fire）锁存写冲突标志
      for (int b = 0; b < NBANKS; b++)
        s1_bank_has_write[b] <= bank_wen[b];
  end

  wire s1_swap = s1_swap_reg;   // s1 物理 way → 逻辑分支反映射

  // ===========================================================================
  // SRAM 例化：us(useful 位, 每 way 1 bit) + 4 个 table_banks(条目)
  //   均为 golden 同名模块（rtl/common, rtl/frontend 提供的可读 wrapper / golden）。
  //   us 深度 = NROWS_PER_BR(折叠在内部)；setIdx = s0_idx / update_idx 全宽。
  //   bank setIdx = bank 内地址(BANK_ADDR_W)。
  // ===========================================================================
  // us 读出（s1）：每逻辑分支 1 bit useful
  wire us_r_d0, us_r_d1;
  wire us_ready;

  // us 写：物理 way mask/数据按 swap 映射
  wire us_wen = (io_update_mask_0 | io_update_mask_1) & (io_update_uMask_0 | io_update_uMask_1);
  wire us_extra_reset = (io_update_reset_u_0 | io_update_reset_u_1)
                      & (io_update_mask_0 | io_update_mask_1);
  // 物理 way0/1 的 u 数据与 mask（u 写 idx = update_idx 全宽，不分 bank）
  wire us_w_d0 = upd_swap ? io_update_us_1 : io_update_us_0;
  wire us_w_d1 = upd_swap ? io_update_us_0 : io_update_us_1;
  wire us_wm0  = upd_swap ? io_update_uMask_1 : io_update_uMask_0;
  wire us_wm1  = upd_swap ? io_update_uMask_0 : io_update_uMask_1;

  FoldedSRAMTemplate us (
    .clock(clock), .reset(reset),
    .io_r_req_ready       (us_ready),
    .io_r_req_valid       (req_fire),
    .io_r_req_bits_setIdx (s0_idx),
    .io_r_resp_data_0     (us_r_d0),
    .io_r_resp_data_1     (us_r_d1),
    .io_w_req_valid       (us_wen),
    .io_w_req_bits_setIdx (update_idx),
    .io_w_req_bits_data_0 (us_w_d0),
    .io_w_req_bits_data_1 (us_w_d1),
    .io_w_req_bits_waymask({us_wm1, us_wm0}),
    .extra_reset          (us_extra_reset),
    .boreChildrenBd_bore_addr      (bore_us_addr),
    .boreChildrenBd_bore_addr_rd   (bore_us_addr_rd),
    .boreChildrenBd_bore_wdata     (bore_us_wdata),
    .boreChildrenBd_bore_wmask     (bore_us_wmask),
    .boreChildrenBd_bore_re        (bore_us_re),
    .boreChildrenBd_bore_we        (bore_us_we),
    .boreChildrenBd_bore_rdata     (bore_us_rdata),
    .boreChildrenBd_bore_ack       (bore_us_ack),
    .boreChildrenBd_bore_selectedOH(bore_us_selectedOH),
    .boreChildrenBd_bore_array     (bore_us_array),
    .sigFromSrams_bore_ram_hold    (sig_us[0]),
    .sigFromSrams_bore_ram_bypass  (sig_us[1]),
    .sigFromSrams_bore_ram_bp_clken(sig_us[2]),
    .sigFromSrams_bore_ram_aux_clk (sig_us[3]),
    .sigFromSrams_bore_ram_aux_ckbp(sig_us[4]),
    .sigFromSrams_bore_ram_mcp_hold(sig_us[5]),
    .sigFromSrams_bore_cgen        (sig_us[6])
  );

  // 4 个条目 bank
  tage_entry_t  bank_rdata [NBANKS][NUM_BR];   // s1 读出
  wire [NBANKS-1:0] bank_r_ready;

  generate
    for (gb = 0; gb < NBANKS; gb++) begin : g_bank
      FoldedSRAMTemplate_1 table_bank (
        .clock(clock), .reset(reset),
        .io_r_req_ready        (bank_r_ready[gb]),
        .io_r_req_valid        (req_fire & s0_bank_1h[gb]),
        .io_r_req_bits_setIdx  (s0_bank_addr),
        .io_r_resp_data_0_valid(bank_rdata[gb][0].valid),
        .io_r_resp_data_0_tag  (bank_rdata[gb][0].tag),
        .io_r_resp_data_0_ctr  (bank_rdata[gb][0].ctr),
        .io_r_resp_data_1_valid(bank_rdata[gb][1].valid),
        .io_r_resp_data_1_tag  (bank_rdata[gb][1].tag),
        .io_r_resp_data_1_ctr  (bank_rdata[gb][1].ctr),
        .io_w_req_valid        (bank_wen[gb]),
        .io_w_req_bits_setIdx  (update_bank_addr),
        .io_w_req_bits_data_0_tag(bank_wdata[gb][0].tag),
        .io_w_req_bits_data_0_ctr(bank_wdata[gb][0].ctr),
        .io_w_req_bits_data_1_tag(bank_wdata[gb][1].tag),
        .io_w_req_bits_data_1_ctr(bank_wdata[gb][1].ctr),
        .io_w_req_bits_waymask (bank_way_mask[gb]),
        .boreChildrenBd_bore_addr      (bore_bank_addr[gb]),
        .boreChildrenBd_bore_addr_rd   (bore_bank_addr_rd[gb]),
        .boreChildrenBd_bore_wdata     (bore_bank_wdata[gb]),
        .boreChildrenBd_bore_wmask     (bore_bank_wmask[gb]),
        .boreChildrenBd_bore_re        (bore_bank_re[gb]),
        .boreChildrenBd_bore_we        (bore_bank_we[gb]),
        .boreChildrenBd_bore_rdata     (bore_bank_rdata[gb]),
        .boreChildrenBd_bore_ack       (bore_bank_ack[gb]),
        .boreChildrenBd_bore_selectedOH(bore_bank_selectedOH[gb]),
        .boreChildrenBd_bore_array     (bore_bank_array[gb]),
        .sigFromSrams_bore_ram_hold    (sig_bank[gb][0]),
        .sigFromSrams_bore_ram_bypass  (sig_bank[gb][1]),
        .sigFromSrams_bore_ram_bp_clken(sig_bank[gb][2]),
        .sigFromSrams_bore_ram_aux_clk (sig_bank[gb][3]),
        .sigFromSrams_bore_ram_aux_ckbp(sig_bank[gb][4]),
        .sigFromSrams_bore_ram_mcp_hold(sig_bank[gb][5]),
        .sigFromSrams_bore_cgen        (sig_bank[gb][6])
      );
    end
  endgenerate

  // ---- 写旁路例化：每 bank 每逻辑分支一个 ----
  //   io_write_idx = bank 内地址；io_write_data = 该逻辑分支对应物理 way 的新 ctr。
  generate
    for (gb = 0; gb < NBANKS; gb++) begin : g_wb_bank
      for (gp = 0; gp < NUM_BR; gp++) begin : g_wb_br   // gp 此处为逻辑分支号 li
        // 逻辑分支 li=gp 对应的物理 way = gp ^ upd_swap（1 位索引避免越界告警）
        localparam logic gp_bit = gp[0];
        wire             pi_idx   = gp_bit ^ upd_swap;
        wire [CTR_W-1:0] wb_wdata = bank_wdata[gb][pi_idx].ctr;
        wire             wb_wen   = (gp_bit ? io_update_mask_1 : io_update_mask_0) & update_bank_1h[gb];
        WrBypass bank_wrbypass (
          .clock(clock), .reset(reset),
          .io_wen             (wb_wen),
          .io_write_idx       (update_bank_addr),
          .io_write_data_0    (wb_wdata),
          .io_hit             (wb_hit[gb][gp]),
          .io_hit_data_0_valid(wb_hit_valid[gb][gp]),
          .io_hit_data_0_bits (wb_hit_ctr[gb][gp])
        );
      end
    end
  endgenerate

  // ===========================================================================
  // S1 预测合成
  //   每 bank：算 unconf / hit（tag 匹配 & valid & 未被写覆盖）。
  //   resp_invalid_by_write = 选中 bank 本拍正被写 → 命中作废。
  //   **hit / unconf 必须先逐 bank 算布尔条件、再用 s1_bank_1h 做 Mux1H-OR**
  //   （与 golden _hit_selected / _unconf_selected 同构）：因 tag 比对、is_unconf
  //   是非线性运算，"先 Mux1H 合并 entry 再比对" 与 "先逐 bank 比对再 Mux1H" 在
  //   bank 选择多热/全零等输入组合下不等价，FM 会判 io_resps_*_valid/unconf 失配。
  //   ctr / u 是线性取值，仍可对数据做 Mux1H（与 golden _resp_selected 同构）。
  // ===========================================================================
  wire resp_invalid_by_write =
      |(s1_bank_1h & s1_bank_has_write);

  // 物理 way 维度：ctr/u 取值用数据 Mux1H；hit/unconf 用逐 bank 条件 Mux1H-OR
  logic [CTR_W-1:0]    phy_ctr    [NUM_BR];
  logic                phy_u      [NUM_BR];
  logic                phy_hit    [NUM_BR];
  logic                phy_unconf [NUM_BR];
  always_comb begin
    for (int w = 0; w < NUM_BR; w++) begin
      phy_ctr[w]    = '0;
      phy_hit[w]    = 1'b0;
      phy_unconf[w] = 1'b0;
      for (int b = 0; b < NBANKS; b++) begin
        phy_ctr[w]    = phy_ctr[w]    | (s1_bank_1h[b] ? bank_rdata[b][w].ctr : '0);
        phy_hit[w]    = phy_hit[w]    | (s1_bank_1h[b] & (bank_rdata[b][w].tag == s1_tag)
                                                       & bank_rdata[b][w].valid
                                                       & ~resp_invalid_by_write);
        phy_unconf[w] = phy_unconf[w] | (s1_bank_1h[b] & is_unconf(bank_rdata[b][w].ctr));
      end
    end
  end
  assign phy_u[0] = us_r_d0;
  assign phy_u[1] = us_r_d1;

  // 物理 way → 逻辑分支反映射后输出每分支响应（li 读物理 way li^s1_swap）
  logic                br_valid [NUM_BR];
  logic [CTR_W-1:0]    br_ctr   [NUM_BR];
  logic                br_u     [NUM_BR];
  logic                br_unconf[NUM_BR];
  always_comb begin
    for (int li = 0; li < NUM_BR; li++) begin
      automatic logic pi = li[0] ^ s1_swap;   // 1 位索引避免越界告警
      br_ctr[li]    = phy_ctr[pi];
      br_u[li]      = phy_u[pi];
      br_unconf[li] = phy_unconf[pi];
      br_valid[li]  = phy_hit[pi];
    end
  end

  assign io_resps_0_valid       = br_valid[0];
  assign io_resps_0_bits_ctr    = br_ctr[0];
  assign io_resps_0_bits_u      = br_u[0];
  assign io_resps_0_bits_unconf = br_unconf[0];
  assign io_resps_1_valid       = br_valid[1];
  assign io_resps_1_bits_ctr    = br_ctr[1];
  assign io_resps_1_bits_u      = br_u[1];
  assign io_resps_1_bits_unconf = br_unconf[1];

  // ===========================================================================
  // 上电复位：所有 SRAM 首次 ready 前 io_req_ready 拉低，挡住 BPU 流水。
  //   单口 SRAM 的 r_req_ready := !wen，故不能直接用作 req_ready，需单独锁存。
  // ===========================================================================
  logic power_on_reset;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      power_on_reset <= 1'b1;
    else if (us_ready & (&bank_r_ready))
      power_on_reset <= 1'b0;
  end
  assign io_req_ready = ~power_on_reset;

  // 抑制未用占位函数 lint
  wire _unused = &{1'b0, io_req_bits_ghist, 1'b0};

endmodule

// 自动生成：xs-v2r2-sv/scripts/gen_tagetable_wrappers.py —— 例化 xs_TageTable_core

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module TageTable(
  input clock,
  input reset,
  output io_req_ready,
  input io_req_valid,
  input [49:0] io_req_bits_pc,
  input [255:0] io_req_bits_ghist,
  input [7:0] io_req_bits_folded_hist_hist_14_folded_hist,
  input [6:0] io_req_bits_folded_hist_hist_7_folded_hist,
  output io_resps_0_valid,
  output [2:0] io_resps_0_bits_ctr,
  output io_resps_0_bits_u,
  output io_resps_0_bits_unconf,
  output io_resps_1_valid,
  output [2:0] io_resps_1_bits_ctr,
  output io_resps_1_bits_u,
  output io_resps_1_bits_unconf,
  input [49:0] io_update_pc,
  input [255:0] io_update_ghist,
  input io_update_mask_0,
  input io_update_mask_1,
  input io_update_takens_0,
  input io_update_takens_1,
  input io_update_alloc_0,
  input io_update_alloc_1,
  input [2:0] io_update_oldCtrs_0,
  input [2:0] io_update_oldCtrs_1,
  input io_update_uMask_0,
  input io_update_uMask_1,
  input io_update_us_0,
  input io_update_us_1,
  input io_update_reset_u_0,
  input io_update_reset_u_1,
  input [8:0] boreChildrenBd_bore_addr,
  input [8:0] boreChildrenBd_bore_addr_rd,
  input [15:0] boreChildrenBd_bore_wdata,
  input [15:0] boreChildrenBd_bore_wmask,
  input boreChildrenBd_bore_re,
  input boreChildrenBd_bore_we,
  output [15:0] boreChildrenBd_bore_rdata,
  input boreChildrenBd_bore_ack,
  input boreChildrenBd_bore_selectedOH,
  input [5:0] boreChildrenBd_bore_array,
  input [9:0] boreChildrenBd_bore_1_addr,
  input [9:0] boreChildrenBd_bore_1_addr_rd,
  input [23:0] boreChildrenBd_bore_1_wdata,
  input [1:0] boreChildrenBd_bore_1_wmask,
  input boreChildrenBd_bore_1_re,
  input boreChildrenBd_bore_1_we,
  output [23:0] boreChildrenBd_bore_1_rdata,
  input boreChildrenBd_bore_1_ack,
  input boreChildrenBd_bore_1_selectedOH,
  input [5:0] boreChildrenBd_bore_1_array,
  input [9:0] boreChildrenBd_bore_2_addr,
  input [9:0] boreChildrenBd_bore_2_addr_rd,
  input [23:0] boreChildrenBd_bore_2_wdata,
  input [1:0] boreChildrenBd_bore_2_wmask,
  input boreChildrenBd_bore_2_re,
  input boreChildrenBd_bore_2_we,
  output [23:0] boreChildrenBd_bore_2_rdata,
  input boreChildrenBd_bore_2_ack,
  input boreChildrenBd_bore_2_selectedOH,
  input [5:0] boreChildrenBd_bore_2_array,
  input [9:0] boreChildrenBd_bore_3_addr,
  input [9:0] boreChildrenBd_bore_3_addr_rd,
  input [23:0] boreChildrenBd_bore_3_wdata,
  input [1:0] boreChildrenBd_bore_3_wmask,
  input boreChildrenBd_bore_3_re,
  input boreChildrenBd_bore_3_we,
  output [23:0] boreChildrenBd_bore_3_rdata,
  input boreChildrenBd_bore_3_ack,
  input boreChildrenBd_bore_3_selectedOH,
  input [5:0] boreChildrenBd_bore_3_array,
  input [9:0] boreChildrenBd_bore_4_addr,
  input [9:0] boreChildrenBd_bore_4_addr_rd,
  input [23:0] boreChildrenBd_bore_4_wdata,
  input [1:0] boreChildrenBd_bore_4_wmask,
  input boreChildrenBd_bore_4_re,
  input boreChildrenBd_bore_4_we,
  output [23:0] boreChildrenBd_bore_4_rdata,
  input boreChildrenBd_bore_4_ack,
  input boreChildrenBd_bore_4_selectedOH,
  input [5:0] boreChildrenBd_bore_4_array,
  input sigFromSrams_bore_ram_hold,
  input sigFromSrams_bore_ram_bypass,
  input sigFromSrams_bore_ram_bp_clken,
  input sigFromSrams_bore_ram_aux_clk,
  input sigFromSrams_bore_ram_aux_ckbp,
  input sigFromSrams_bore_ram_mcp_hold,
  input sigFromSrams_bore_cgen,
  input sigFromSrams_bore_1_ram_hold,
  input sigFromSrams_bore_1_ram_bypass,
  input sigFromSrams_bore_1_ram_bp_clken,
  input sigFromSrams_bore_1_ram_aux_clk,
  input sigFromSrams_bore_1_ram_aux_ckbp,
  input sigFromSrams_bore_1_ram_mcp_hold,
  input sigFromSrams_bore_1_cgen,
  input sigFromSrams_bore_2_ram_hold,
  input sigFromSrams_bore_2_ram_bypass,
  input sigFromSrams_bore_2_ram_bp_clken,
  input sigFromSrams_bore_2_ram_aux_clk,
  input sigFromSrams_bore_2_ram_aux_ckbp,
  input sigFromSrams_bore_2_ram_mcp_hold,
  input sigFromSrams_bore_2_cgen,
  input sigFromSrams_bore_3_ram_hold,
  input sigFromSrams_bore_3_ram_bypass,
  input sigFromSrams_bore_3_ram_bp_clken,
  input sigFromSrams_bore_3_ram_aux_clk,
  input sigFromSrams_bore_3_ram_aux_ckbp,
  input sigFromSrams_bore_3_ram_mcp_hold,
  input sigFromSrams_bore_3_cgen,
  input sigFromSrams_bore_4_ram_hold,
  input sigFromSrams_bore_4_ram_bypass,
  input sigFromSrams_bore_4_ram_bp_clken,
  input sigFromSrams_bore_4_ram_aux_clk,
  input sigFromSrams_bore_4_ram_aux_ckbp,
  input sigFromSrams_bore_4_ram_mcp_hold,
  input sigFromSrams_bore_4_cgen
);
  // ---- bore_bank/sig_bank 打包（golden bore_1..4 → 数组 [0..3]）----
  wire [9:0]  bb_addr [4], bb_addr_rd [4];
  wire [23:0] bb_wdata [4];
  wire [1:0]  bb_wmask [4];
  wire        bb_re [4], bb_we [4], bb_ack [4], bb_sel [4];
  wire [23:0] bb_rdata [4];
  wire [5:0]  bb_array [4];
  wire [6:0]  sig_bk [4];
  assign bb_addr[0]=boreChildrenBd_bore_1_addr;    assign bb_addr_rd[0]=boreChildrenBd_bore_1_addr_rd;
  assign bb_wdata[0]=boreChildrenBd_bore_1_wdata;  assign bb_wmask[0]=boreChildrenBd_bore_1_wmask;
  assign bb_re[0]=boreChildrenBd_bore_1_re;        assign bb_we[0]=boreChildrenBd_bore_1_we;
  assign bb_ack[0]=boreChildrenBd_bore_1_ack;      assign bb_sel[0]=boreChildrenBd_bore_1_selectedOH;
  assign bb_array[0]=boreChildrenBd_bore_1_array;
  assign boreChildrenBd_bore_1_rdata=bb_rdata[0];
  assign sig_bk[0]={sigFromSrams_bore_1_cgen,sigFromSrams_bore_1_ram_mcp_hold,sigFromSrams_bore_1_ram_aux_ckbp,sigFromSrams_bore_1_ram_aux_clk,sigFromSrams_bore_1_ram_bp_clken,sigFromSrams_bore_1_ram_bypass,sigFromSrams_bore_1_ram_hold};
  assign bb_addr[1]=boreChildrenBd_bore_2_addr;    assign bb_addr_rd[1]=boreChildrenBd_bore_2_addr_rd;
  assign bb_wdata[1]=boreChildrenBd_bore_2_wdata;  assign bb_wmask[1]=boreChildrenBd_bore_2_wmask;
  assign bb_re[1]=boreChildrenBd_bore_2_re;        assign bb_we[1]=boreChildrenBd_bore_2_we;
  assign bb_ack[1]=boreChildrenBd_bore_2_ack;      assign bb_sel[1]=boreChildrenBd_bore_2_selectedOH;
  assign bb_array[1]=boreChildrenBd_bore_2_array;
  assign boreChildrenBd_bore_2_rdata=bb_rdata[1];
  assign sig_bk[1]={sigFromSrams_bore_2_cgen,sigFromSrams_bore_2_ram_mcp_hold,sigFromSrams_bore_2_ram_aux_ckbp,sigFromSrams_bore_2_ram_aux_clk,sigFromSrams_bore_2_ram_bp_clken,sigFromSrams_bore_2_ram_bypass,sigFromSrams_bore_2_ram_hold};
  assign bb_addr[2]=boreChildrenBd_bore_3_addr;    assign bb_addr_rd[2]=boreChildrenBd_bore_3_addr_rd;
  assign bb_wdata[2]=boreChildrenBd_bore_3_wdata;  assign bb_wmask[2]=boreChildrenBd_bore_3_wmask;
  assign bb_re[2]=boreChildrenBd_bore_3_re;        assign bb_we[2]=boreChildrenBd_bore_3_we;
  assign bb_ack[2]=boreChildrenBd_bore_3_ack;      assign bb_sel[2]=boreChildrenBd_bore_3_selectedOH;
  assign bb_array[2]=boreChildrenBd_bore_3_array;
  assign boreChildrenBd_bore_3_rdata=bb_rdata[2];
  assign sig_bk[2]={sigFromSrams_bore_3_cgen,sigFromSrams_bore_3_ram_mcp_hold,sigFromSrams_bore_3_ram_aux_ckbp,sigFromSrams_bore_3_ram_aux_clk,sigFromSrams_bore_3_ram_bp_clken,sigFromSrams_bore_3_ram_bypass,sigFromSrams_bore_3_ram_hold};
  assign bb_addr[3]=boreChildrenBd_bore_4_addr;    assign bb_addr_rd[3]=boreChildrenBd_bore_4_addr_rd;
  assign bb_wdata[3]=boreChildrenBd_bore_4_wdata;  assign bb_wmask[3]=boreChildrenBd_bore_4_wmask;
  assign bb_re[3]=boreChildrenBd_bore_4_re;        assign bb_we[3]=boreChildrenBd_bore_4_we;
  assign bb_ack[3]=boreChildrenBd_bore_4_ack;      assign bb_sel[3]=boreChildrenBd_bore_4_selectedOH;
  assign bb_array[3]=boreChildrenBd_bore_4_array;
  assign boreChildrenBd_bore_4_rdata=bb_rdata[3];
  assign sig_bk[3]={sigFromSrams_bore_4_cgen,sigFromSrams_bore_4_ram_mcp_hold,sigFromSrams_bore_4_ram_aux_ckbp,sigFromSrams_bore_4_ram_aux_clk,sigFromSrams_bore_4_ram_bp_clken,sigFromSrams_bore_4_ram_bypass,sigFromSrams_bore_4_ram_hold};
  xs_TageTable_core #(
    .HIST_LEN(8),
    // G1 锚点: 直接取 golden 三个 folded_hist 端口的位数(端口表已由
    // port_contract_lint 对着 G1 golden 核过), 不做人工转写。
    .G1_IDX_FH_W($bits(io_req_bits_folded_hist_hist_14_folded_hist)),
    .G1_TAG_FH_W($bits(io_req_bits_folded_hist_hist_14_folded_hist)),
    .G1_ALT_FH_W($bits(io_req_bits_folded_hist_hist_7_folded_hist))
  ) u_core (
    .clock(clock), .reset(reset),
    .io_req_ready(io_req_ready), .io_req_valid(io_req_valid),
    .io_req_bits_pc(io_req_bits_pc), .io_req_bits_ghist(io_req_bits_ghist),
    .io_req_idx_fh(io_req_bits_folded_hist_hist_14_folded_hist), .io_req_tag_fh(io_req_bits_folded_hist_hist_14_folded_hist), .io_req_alt_fh(io_req_bits_folded_hist_hist_7_folded_hist),
    .io_resps_0_valid(io_resps_0_valid), .io_resps_0_bits_ctr(io_resps_0_bits_ctr),
    .io_resps_0_bits_u(io_resps_0_bits_u), .io_resps_0_bits_unconf(io_resps_0_bits_unconf),
    .io_resps_1_valid(io_resps_1_valid), .io_resps_1_bits_ctr(io_resps_1_bits_ctr),
    .io_resps_1_bits_u(io_resps_1_bits_u), .io_resps_1_bits_unconf(io_resps_1_bits_unconf),
    .io_update_pc(io_update_pc), .io_update_ghist(io_update_ghist),
    .io_update_mask_0(io_update_mask_0), .io_update_mask_1(io_update_mask_1),
    .io_update_takens_0(io_update_takens_0), .io_update_takens_1(io_update_takens_1),
    .io_update_alloc_0(io_update_alloc_0), .io_update_alloc_1(io_update_alloc_1),
    .io_update_oldCtrs_0(io_update_oldCtrs_0), .io_update_oldCtrs_1(io_update_oldCtrs_1),
    .io_update_uMask_0(io_update_uMask_0), .io_update_uMask_1(io_update_uMask_1),
    .io_update_us_0(io_update_us_0), .io_update_us_1(io_update_us_1),
    .io_update_reset_u_0(io_update_reset_u_0), .io_update_reset_u_1(io_update_reset_u_1),
    .bore_us_addr(boreChildrenBd_bore_addr), .bore_us_addr_rd(boreChildrenBd_bore_addr_rd),
    .bore_us_wdata(boreChildrenBd_bore_wdata), .bore_us_wmask(boreChildrenBd_bore_wmask),
    .bore_us_re(boreChildrenBd_bore_re), .bore_us_we(boreChildrenBd_bore_we),
    .bore_us_rdata(boreChildrenBd_bore_rdata), .bore_us_ack(boreChildrenBd_bore_ack),
    .bore_us_selectedOH(boreChildrenBd_bore_selectedOH), .bore_us_array(boreChildrenBd_bore_array),
    .bore_bank_addr(bb_addr), .bore_bank_addr_rd(bb_addr_rd),
    .bore_bank_wdata(bb_wdata), .bore_bank_wmask(bb_wmask),
    .bore_bank_re(bb_re), .bore_bank_we(bb_we), .bore_bank_rdata(bb_rdata),
    .bore_bank_ack(bb_ack), .bore_bank_selectedOH(bb_sel), .bore_bank_array(bb_array),
    .sig_us({sigFromSrams_bore_cgen,sigFromSrams_bore_ram_mcp_hold,sigFromSrams_bore_ram_aux_ckbp,sigFromSrams_bore_ram_aux_clk,sigFromSrams_bore_ram_bp_clken,sigFromSrams_bore_ram_bypass,sigFromSrams_bore_ram_hold}),
    .sig_bank(sig_bk)
  );
endmodule
