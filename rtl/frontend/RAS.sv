// =============================================================================
// xs_RASStack —— 返回地址栈（RAS）的核心：投机栈 + 提交栈 双栈结构
//
// 对应 Chisel: xiangshan.frontend.RAS.RASStack（newRAS.scala 内部类 RASStack）
//
// 【它在前端的位置】
//   RAS 是分支预测器之一（BasePredictor），专门预测「函数返回（ret）的目标地址」。
//   调用约定保证 call 之后必然返回到 call 的下一条指令，所以维护一个栈：
//     · 遇到 call（taken）→ push「返回地址」（= call 落地址，RVI call 还要 +2）；
//     · 遇到 ret （taken）→ pop 栈顶作为预测的返回目标。
//   RASStack 是这套栈的「存储 + 指针 + 恢复」核心。外层 RAS（本工程未重写）负责从
//   s2/s3 流水译码结果里识别 call/ret 并驱动本模块，并把本模块输出的指针打成快照
//   随预测块下发，供 redirect 时回滚。
//
// 【为什么要「投机栈 + 提交栈」两套？】
//   预测发生在取指阶段（s2/s3），此时分支是否真的 taken 还没确认；若预测错了
//   （s3 自纠、后端 redirect），已经做过的 push/pop 必须能回滚。设计因此分两层：
//
//     spec_queue[32] + spec_nos[32]  —— 投机栈（speculative，持久栈 persistent stack）。
//        环形缓冲，记录所有「在途（in-flight，已预测未提交）」的 push。
//        指针：TOSW（写指针，下一个要写的槽）/ TOSR（读指针，当前逻辑栈顶所在槽）
//        / BOS（底，已提交边界）/ NOS（next-on-stack，每项记的「下一项位置」，存 spec_nos）。
//        关键点：pop 不抹数据，只移动 TOSR，靠每项的 NOS 链把逻辑栈顶往下指。
//        于是 redirect 只需恢复几个指针即可，无需恢复数据 —— 这正是双栈廉价回滚的根源。
//
//     commit_stack[16]               —— 提交栈（committed，真值）。后端 commit/update 后才更新。
//        当投机栈因 pop/redirect 把逻辑栈顶退到 BOS 以下时，回落到提交栈取数据
//        （getCommitTop）。指针 nsp。
//
// 【ctr：尾递归 / 重复返回地址的压缩】
//   连续 call 到「同一返回地址」（循环里反复调用同一函数、自递归）不分配新槽，而是把
//   栈顶 entry 的 ctr +1（饱和到 CTR_MAX=7）；pop 时先 ctr-1，ctr 到 0 才真正退栈。
//   有限栈深因此能容纳很深的同地址嵌套，避免溢出丢预测。
//
// 【三个恢复入口（优先级从高到低）】
//   redirect（后端重定向） > s3_cancel（s2/s3 预测不一致，自我纠正） > 正常 s2 push/pop。
//   redirect / s3_cancel 都带一份「快照 meta」（ssp/sctr/TOSR/TOSW/NOS），恢复时把指针
//   写回快照，再按需补做一次 push（误预测的 call 漏 push）或 pop（漏 pop）。
//
// 【时序：writeBypass 与 timingTop】
//   spec_queue 是寄存器堆：s2 决定 push，但要到 s3 才真正写入（realPush）。为让「下一拍
//   栈顶预测地址」及时可用，用 writeBypassEntry 旁路本拍刚算出的 push entry，并用
//   timingTop 寄存器**提前一拍**算好「下一拍栈顶 retAddr」（= 输出 spec_pop_addr）。
//
// 【与外层接口约定】
//   外层在 push/pop/redirect/commit 各端口已做好 spec_near_overflow 反压与时序对齐，
//   本模块只需按上述优先级维护状态并提前算好输出。
// =============================================================================
package xs_ras_pkg;
  // ---- 容量/位宽参数（KunminghuV2：RasSize=16, RasSpecSize=32, RasCtrSize=3）----
  localparam int unsigned VADDR_W       = 50;  // VAddrBits：返回地址宽
  localparam int unsigned RAS_SIZE      = 16;  // 提交栈深度
  localparam int unsigned RAS_SPEC_SIZE = 32;  // 投机环形栈深度（必须是 2 的幂）
  localparam int unsigned CTR_W         = 3;   // ctr 位宽
  localparam int unsigned SSP_W         = 4;   // log2Up(RAS_SIZE)：ssp/nsp 宽
  localparam int unsigned SPTR_W        = 5;   // log2(RAS_SPEC_SIZE)：环形指针 value 宽

  localparam logic [CTR_W-1:0] CTR_MAX = 3'h7; // ctr 饱和值 ((1<<CTR_W)-1)

  // ---- 栈中一项：返回地址 + 重复计数 ----
  typedef struct packed {
    logic [VADDR_W-1:0] retAddr;
    logic [CTR_W-1:0]   ctr;     // 同一 retAddr 连续 call 的层数（尾递归压缩）
  } ras_entry_t;

  // ---- 投机环形指针：{flag, value}。flag 是绕回标志，用于区分「写追上读」与「空」----
  typedef struct packed {
    logic              flag;
    logic [SPTR_W-1:0] value;
  } ras_ptr_t;

  // 环形指针 +1 / -1（value 自然回绕时翻转 flag，由多一位的进位/借位实现）
  function automatic ras_ptr_t ptr_inc(input ras_ptr_t p);
    logic [SPTR_W:0] nxt;
    nxt = {p.flag, p.value} + 1'b1;
    return '{flag: nxt[SPTR_W], value: nxt[SPTR_W-1:0]};
  endfunction

  function automatic ras_ptr_t ptr_dec(input ras_ptr_t p);
    logic [SPTR_W:0] nxt;
    nxt = {p.flag, p.value} - 1'b1;
    return '{flag: nxt[SPTR_W], value: nxt[SPTR_W-1:0]};
  endfunction

  // CircularQueuePtr 的 a < b（环形「在 b 之前」）：flag 相同比 value，flag 不同则取反。
  function automatic logic is_before(input ras_ptr_t a, input ras_ptr_t b);
    return (a.flag ^ b.flag) ^ (a.value < b.value);
  endfunction

  // distanceBetween(enq, deq)：enq 领先 deq 多少（6 位含绕回）。
  // 注意：flag 相同时是「value 域内的 5 位减法」再零扩展（与 Chisel UInt 减法等宽语义一致）；
  // 对合法环形指针 enq>=deq 时两者相同，但非法 meta（value 回绕）下必须保持此语义才与 golden 等价。
  function automatic logic [SPTR_W:0] distance(input ras_ptr_t enq, input ras_ptr_t deq);
    if (enq.flag == deq.flag) return {1'b0, (enq.value - deq.value)};
    else return (SPTR_W+1)'(RAS_SPEC_SIZE) + {1'b0, enq.value} - {1'b0, deq.value};
  endfunction

  // 提交栈 / 普通深度指针（ssp/nsp，模 RAS_SIZE）的 +1/-1
  function automatic logic [SSP_W-1:0] sp_inc(input logic [SSP_W-1:0] p);
    return p + 1'b1;
  endfunction
  function automatic logic [SSP_W-1:0] sp_dec(input logic [SSP_W-1:0] p);
    return p - 1'b1;
  endfunction
endpackage


module xs_RASStack
  import xs_ras_pkg::*;
(
  input  logic       clock,
  input  logic       reset,

  // ---- 投机 push/pop（来自 s2，外层已用 spec_near_overflow 反压）----
  input  logic               spec_push_valid,
  input  logic               spec_pop_valid,
  input  logic [VADDR_W-1:0] spec_push_addr,
  output logic [VADDR_W-1:0] spec_pop_addr,   // 预测的返回目标（栈顶 retAddr）

  // ---- s2→s3 旁路 / s3 自我纠正 ----
  input  logic               s2_fire,
  input  logic               s3_fire,
  input  logic               s3_cancel,       // s3 与 s2 预测不一致，回滚到 s3 快照
  input  logic [SSP_W-1:0]   s3_meta_ssp,     // s3 快照 meta（push 时记录的指针状态）
  input  logic [CTR_W-1:0]   s3_meta_sctr,
  input  ras_ptr_t           s3_meta_TOSW,
  input  ras_ptr_t           s3_meta_TOSR,
  input  ras_ptr_t           s3_meta_NOS,
  input  logic               s3_missed_pop,   // s2 漏了 pop，s3 补做
  input  logic               s3_missed_push,  // s2 漏了 push，s3 补做
  input  logic [VADDR_W-1:0] s3_pushAddr,

  // ---- commit（来自后端 update，维护提交栈）----
  input  logic               commit_valid,
  input  logic               commit_push_valid,
  input  logic               commit_pop_valid,
  input  ras_ptr_t           commit_meta_TOSW,
  input  logic [SSP_W-1:0]   commit_meta_ssp,

  // ---- redirect（后端重定向，最高优先级恢复）----
  input  logic               redirect_valid,
  input  logic               redirect_isCall, // 误预测的是 call → 需补 push
  input  logic               redirect_isRet,  // 误预测的是 ret  → 需补 pop
  input  logic [SSP_W-1:0]   redirect_meta_ssp,
  input  logic [CTR_W-1:0]   redirect_meta_sctr,
  input  ras_ptr_t           redirect_meta_TOSW,
  input  ras_ptr_t           redirect_meta_TOSR,
  input  ras_ptr_t           redirect_meta_NOS,
  input  logic [VADDR_W-1:0] redirect_callAddr,

  // ---- 指针输出（外层打快照写进 cfiUpdate / spec_info）----
  output logic [SSP_W-1:0]   ssp_o,
  output logic [CTR_W-1:0]   sctr_o,
  output ras_ptr_t           TOSR_o,
  output ras_ptr_t           TOSW_o,
  output ras_ptr_t           NOS_o,
  output logic               spec_near_overflow_o
);

  // ===========================================================================
  // 状态寄存器
  // ===========================================================================
  ras_entry_t [RAS_SIZE-1:0]      commit_stack;   // 提交栈（真值）
  ras_entry_t [RAS_SPEC_SIZE-1:0] spec_queue;     // 投机栈：每项的 retAddr+ctr
  ras_ptr_t   [RAS_SPEC_SIZE-1:0] spec_nos;       // 投机栈：每项的 NOS（下一项位置）

  logic [SSP_W-1:0] nsp;   // 提交栈指针
  logic [SSP_W-1:0] ssp;   // 投机栈逻辑深度指针
  logic [CTR_W-1:0] sctr;  // 投机栈顶 ctr
  ras_ptr_t TOSR;          // top-of-spec-read：当前逻辑栈顶所在的 spec 槽
  ras_ptr_t TOSW;          // top-of-spec-write：下一个要写入的 spec 槽
  ras_ptr_t BOS;           // bottom-of-spec：已提交边界

  logic spec_near_overflowed;

  // 旁路：本拍刚算出的 push entry，供「同拍即用」与下一拍 timingTop
  ras_entry_t writeBypassEntry;
  ras_ptr_t   writeBypassNos;
  logic       writeBypassValid;

  wire redir_call = redirect_valid & redirect_isCall;

  // ===========================================================================
  // 组合：栈顶查询
  //   tosr_in_range：TOSR 是否落在「有效在途区间」[BOS, TOSW)。
  //     在区间内 → 栈顶数据在 spec_queue；否则逻辑栈已退到提交边界以下 → 取 commit_stack。
  // ===========================================================================
  // 纯函数（所有读入都经实参传入，便于 FM 签名分析，无 FMR_VLOG-091）。
  // tosr_in_range：不早于 BOS（!isBefore(tosr,BOS)）且 严格早于 TOSW（isBefore(tosr,tosw)）。
  function automatic logic tosr_in_range(input ras_ptr_t cur_tosr, input ras_ptr_t cur_tosw,
                                         input ras_ptr_t cur_bos);
    return (~is_before(cur_tosr, cur_bos)) & is_before(cur_tosr, cur_tosw);
  endfunction

  // getTop：在「旁路项 / 在途项 / 提交项」三者间选逻辑栈顶。三个候选与判定均由调用处算好传入。
  function automatic ras_entry_t sel_top(
      input logic allow_bypass, input logic bypass_valid, input logic in_range,
      input ras_entry_t bypass_entry, input ras_entry_t spec_entry, input ras_entry_t commit_entry);
    if (allow_bypass && bypass_valid) return bypass_entry;
    else if (in_range)                return spec_entry;
    else                              return commit_entry;
  endfunction

  // 各路径的栈顶/NOS：把数组索引、旁路、in_range 在 always_comb 里算好（数组读在过程块内，FM 友好）
  ras_entry_t topEntry, redirectTopEntry, s3TopEntry;
  ras_ptr_t   topNos;
  always_comb topEntry = sel_top(1'b1, writeBypassValid,
                                 tosr_in_range(TOSR, TOSW, BOS),
                                 writeBypassEntry, spec_queue[TOSR.value], commit_stack[ssp]);
  always_comb topNos   = writeBypassValid ? writeBypassNos : spec_nos[TOSR.value];
  always_comb redirectTopEntry = sel_top(1'b0, writeBypassValid,
                                 tosr_in_range(redirect_meta_TOSR, redirect_meta_TOSW, BOS),
                                 writeBypassEntry, spec_queue[redirect_meta_TOSR.value],
                                 commit_stack[redirect_meta_ssp]);
  always_comb s3TopEntry = sel_top(1'b0, writeBypassValid,
                                 tosr_in_range(s3_meta_TOSR, s3_meta_TOSW, BOS),
                                 writeBypassEntry, spec_queue[s3_meta_TOSR.value],
                                 commit_stack[s3_meta_ssp]);

  // ===========================================================================
  // 组合：本拍要写入投机栈的 entry（writeEntry）/ 其 NOS（writeNos）
  //   来源二选一：redirect 补 push（用 redirect_callAddr / redirect 快照）
  //              或 正常 s2 push（用 spec_push_addr / 当前栈顶）。
  //   ctr：新地址 == 栈顶地址 且未饱和 → 复用栈顶并 +1（尾递归）；否则 0。
  // ===========================================================================
  ras_entry_t writeEntry;
  ras_ptr_t   writeNos;
  always_comb begin
    if (redir_call) begin
      writeEntry.retAddr = redirect_callAddr;
      writeEntry.ctr     = (redirectTopEntry.retAddr == redirect_callAddr
                            && redirectTopEntry.ctr < CTR_MAX) ? (redirect_meta_sctr + 1'b1) : '0;
      writeNos           = redirect_meta_TOSR;
    end else begin
      writeEntry.retAddr = spec_push_addr;
      writeEntry.ctr     = (topEntry.retAddr == spec_push_addr
                            && topEntry.ctr < CTR_MAX) ? (sctr + 1'b1) : '0;
      writeNos           = TOSR;
    end
  end

  // ===========================================================================
  // 组合：writeBypassValid 的下一拍值
  //   redirect-call 置 1（旁路补 push 的项）；其它 redirect 清 0；s2_fire 跟随 push_valid；
  //   s3_fire 清 0；否则保持。
  // ===========================================================================
  logic writeBypassValidWire;
  always_comb begin
    if (redir_call)          writeBypassValidWire = 1'b1;
    else if (redirect_valid) writeBypassValidWire = 1'b0;
    else if (s2_fire)        writeBypassValidWire = spec_push_valid;
    else if (s3_fire)        writeBypassValidWire = 1'b0;
    else                     writeBypassValidWire = writeBypassValid;
  end

  // ===========================================================================
  // realPush —— s3 真正写入 spec_queue 的时机
  //   = s3_fire 时 (s2 预测的 push 未被取消) 或 (s3 补 push)，或 redirect-call 的下一拍。
  // ===========================================================================
  logic realPush_specPush_q;  // RegEnable(spec_push_valid, s2_fire)
  logic realPush_redir_q;     // RegNext(redirect_valid & redirect_isCall)
  wire  realPush = (s3_fire & ((~s3_cancel & realPush_specPush_q) | s3_missed_push)) | realPush_redir_q;

  // realPush 写入用的 entry / 地址 / NOS：
  //   use_snapshot_push 时用 s2 打拍快照（realWriteEntry_next 等），否则用 s3 补 push 现算值。
  ras_entry_t realWriteEntry_next;
  // 写到哪个 spec 槽（= 当时的 TOSW 的 value 域）。只需 5 位 value 作 32 深索引，
  // TOSW 的 flag（绕回位）对「写哪个槽」无影响 → 与 golden 一致只存 value，不存 flag，
  // 避免 flag 位成为 impl-only cone-dead 寄存器。
  logic [SPTR_W-1:0] realWriteAddr_next;
  ras_ptr_t   realNos_next;

  wire use_snapshot_push = redirect_isCall | ~s3_missed_push;  // golden _GEN_11

  // s3 补 push 时现算的 entry（含尾递归 ctr）
  ras_entry_t s3_missPushEntry;
  always_comb begin
    s3_missPushEntry.retAddr = s3_pushAddr;
    s3_missPushEntry.ctr     = (s3TopEntry.retAddr == s3_pushAddr && s3TopEntry.ctr < CTR_MAX)
                               ? (s3_meta_sctr + 1'b1) : '0;
  end

  wire ras_entry_t realWriteEntry = use_snapshot_push ? realWriteEntry_next : s3_missPushEntry;
  // realWriteAddr 只取 value（写槽索引）；s3 补 push 路径用 s3_meta_TOSW.value。
  wire [SPTR_W-1:0] realWriteAddr = use_snapshot_push ? realWriteAddr_next : s3_meta_TOSW.value;
  wire ras_ptr_t   realNos        = use_snapshot_push ? realNos_next        : s3_meta_TOSR;

  // ===========================================================================
  // 时序：spec_queue / spec_nos 写入（realPush 时写 realWriteAddr 指向的槽）
  //   每槽独立 always_ff，靠 index 比较选中（与 golden 结构一致，便于 FM 签名分析）。
  // ===========================================================================
  genvar gs;
  generate
    for (gs = 0; gs < RAS_SPEC_SIZE; gs++) begin : g_spec
      wire hit = realPush & (realWriteAddr == SPTR_W'(gs));
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          spec_queue[gs] <= '0;
          spec_nos[gs]   <= '0;
        end else if (hit) begin
          spec_queue[gs] <= realWriteEntry;
          spec_nos[gs]   <= realNos;
        end
      end
    end
  endgenerate

  // ===========================================================================
  // 组合：specPush / specPop 的「下一拍指针值」纯函数
  //   把 Scala 的 specPush/specPop 写成「目标值计算」，再在统一的指针 always_ff
  //   里按优先级（redirect > s3_cancel > 正常）选用。
  // ===========================================================================
  // specPush：push 后的 (ssp,sctr,TOSR,TOSW)。
  //   ssp_we：是否写 ssp —— 仅「新地址」分支写（栈深 +1）；尾递归分支只 +ctr，不写 ssp。
  //   这与 specPop 的 ssp_we 同理：push 与 pop 同拍 last-connect 时，尾递归 push 不能
  //   覆盖 pop 已写好的 ssp（Scala 中 specPush 的 ssp 赋值只在 .otherwise 分支）。
  function automatic void calc_push(
      input logic [VADDR_W-1:0] ret_addr,
      input logic [SSP_W-1:0] c_ssp, input logic [CTR_W-1:0] c_sctr,
      input ras_ptr_t c_tosr, input ras_ptr_t c_tosw, input ras_entry_t c_top,
      output logic [SSP_W-1:0] n_ssp, output logic [CTR_W-1:0] n_sctr,
      output ras_ptr_t n_tosr, output ras_ptr_t n_tosw, output logic ssp_we);
    n_tosr = c_tosw;             // 新栈顶 = 刚写入的槽
    n_tosw = ptr_inc(c_tosw);    // 写指针前移
    if (c_top.retAddr == ret_addr && c_sctr < CTR_MAX) begin
      n_ssp   = c_ssp;           // 尾递归：不增深度，只 +ctr
      n_sctr  = c_sctr + 1'b1;
      ssp_we  = 1'b0;            // 不写 ssp
    end else begin
      n_ssp   = sp_inc(c_ssp);   // 新地址：栈深 +1，ctr 清 0
      n_sctr  = '0;
      ssp_we  = 1'b1;
    end
  endfunction

  // specPop：pop 后的 (ssp,sctr,TOSR)（TOSW 不变）。
  //   tosr_we：是否更新 TOSR（仅栈非空）。
  //   ssp_we ：是否更新 ssp（仅 sctr==0，即真正退一层时；sctr>0 只 ctr-1 不动 ssp）。
  //   这两个「写使能」对应 Scala 中 specPop 只在特定分支才写对应寄存器 —— 当 push 与 pop
  //   同拍时（last-connect），未被 pop 写的寄存器要保留 push 的结果，故必须显式区分。
  //   下层 ctr 的两个候选（nos_spec_ctr=spec_queue[topNos].ctr、commit_dec_ctr=commit_stack[ssp-1].ctr）
  //   与 c_bos 都由调用处传入，保持本函数纯净。
  function automatic void calc_pop(
      input logic [SSP_W-1:0] c_ssp, input logic [CTR_W-1:0] c_sctr,
      input ras_ptr_t c_tosr, input ras_ptr_t c_tosw, input ras_ptr_t c_topnos, input ras_ptr_t c_bos,
      input logic [CTR_W-1:0] nos_spec_ctr, input logic [CTR_W-1:0] commit_dec_ctr,
      output logic [SSP_W-1:0] n_ssp, output logic [CTR_W-1:0] n_sctr,
      output ras_ptr_t n_tosr, output logic tosr_we, output logic ssp_we);
    tosr_we = tosr_in_range(c_tosr, c_tosw, c_bos);  // 仅栈非空时回退 TOSR
    ssp_we  = (c_sctr == 0);                         // 仅退一层时写 ssp
    n_tosr  = c_topnos;
    if (c_sctr > 0) begin
      n_ssp  = c_ssp;            // 尾递归层未退完：只 ctr-1
      n_sctr = c_sctr - 1'b1;
    end else if (tosr_in_range(c_topnos, c_tosw, c_bos)) begin
      n_ssp  = sp_dec(c_ssp);    // 退一层，下层 ctr 来自在途数据
      n_sctr = nos_spec_ctr;
    end else begin
      n_ssp  = sp_dec(c_ssp);    // 退到提交边界以下，下层 ctr 来自提交栈
      n_sctr = commit_dec_ctr;
    end
  endfunction

  // 各恢复/正常路径的 calc 结果
  logic [SSP_W-1:0] rp_ssp, rpop_ssp, pop_ssp, push_ssp, s3p_ssp, s3pop_ssp;
  logic [CTR_W-1:0] rp_sctr, rpop_sctr, pop_sctr, push_sctr, s3p_sctr, s3pop_sctr;
  ras_ptr_t         rp_tosr, rpop_tosr, pop_tosr, push_tosr, s3p_tosr, s3pop_tosr;
  ras_ptr_t         rp_tosw, push_tosw, s3p_tosw;
  logic             rpop_we, pop_we, s3pop_we;
  logic             rpop_ssp_we, pop_ssp_we, s3pop_ssp_we;
  logic             rp_ssp_we, push_ssp_we, s3p_ssp_we;

  always_comb begin
    calc_push(redirect_callAddr, redirect_meta_ssp, redirect_meta_sctr,
              redirect_meta_TOSR, redirect_meta_TOSW, redirectTopEntry,
              rp_ssp, rp_sctr, rp_tosr, rp_tosw, rp_ssp_we);            // redirect 补 push
    calc_pop(redirect_meta_ssp, redirect_meta_sctr, redirect_meta_TOSR,
             redirect_meta_TOSW, redirect_meta_NOS, BOS,
             spec_queue[redirect_meta_NOS.value].ctr, commit_stack[sp_dec(redirect_meta_ssp)].ctr,
             rpop_ssp, rpop_sctr, rpop_tosr, rpop_we, rpop_ssp_we);     // redirect 补 pop
    calc_pop(ssp, sctr, TOSR, TOSW, topNos, BOS,
             spec_queue[topNos.value].ctr, commit_stack[sp_dec(ssp)].ctr,
             pop_ssp, pop_sctr, pop_tosr, pop_we, pop_ssp_we);          // 正常 pop
    calc_push(spec_push_addr, ssp, sctr, TOSR, TOSW, topEntry,
              push_ssp, push_sctr, push_tosr, push_tosw, push_ssp_we);  // 正常 push
    calc_push(s3_pushAddr, s3_meta_ssp, s3_meta_sctr, s3_meta_TOSR, s3_meta_TOSW, s3TopEntry,
              s3p_ssp, s3p_sctr, s3p_tosr, s3p_tosw, s3p_ssp_we);       // s3 补 push
    calc_pop(s3_meta_ssp, s3_meta_sctr, s3_meta_TOSR, s3_meta_TOSW, s3_meta_NOS, BOS,
             spec_queue[s3_meta_NOS.value].ctr, commit_stack[sp_dec(s3_meta_ssp)].ctr,
             s3pop_ssp, s3pop_sctr, s3pop_tosr, s3pop_we, s3pop_ssp_we);// s3 补 pop
  end

  // ===========================================================================
  // 时序：投机指针 (ssp, sctr, TOSR, TOSW) 更新
  //   优先级：redirect（含补 push/pop） > s3_cancel（含补 push/pop） > 正常 push/pop。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      ssp  <= '0;
      sctr <= '0;
      TOSR <= '{flag: 1'b1, value: SPTR_W'(RAS_SPEC_SIZE-1)};  // 见模块头初值说明
      TOSW <= '{flag: 1'b0, value: '0};
    end else if (redirect_valid) begin
      // 先恢复到 redirect 快照，再按需补 push/pop。
      // 注意：Scala 用两个独立 when（isCall→specPush，isRet→specPop），并非互斥 elsewhen。
      // 正常 CFI 不会既是 call 又是 ret，但 RTL 语义是「last-connect 胜出」：两者都置位时
      // specPop（isRet）在 ssp/sctr/TOSR 上覆盖 specPush，而 TOSW 仍保留 push 的值。
      ssp  <= redirect_meta_ssp;
      sctr <= redirect_meta_sctr;
      TOSR <= redirect_meta_TOSR;
      TOSW <= redirect_meta_TOSW;
      // push 先（isCall），pop 后（isRet）—— pop 以「写使能」局部覆盖 push 的结果
      if (redirect_isCall) begin
        sctr <= rp_sctr; TOSR <= rp_tosr; TOSW <= rp_tosw;
        if (rp_ssp_we) ssp <= rp_ssp;
      end
      if (redirect_isRet) begin
        sctr <= rpop_sctr;
        if (rpop_ssp_we) ssp  <= rpop_ssp;
        if (rpop_we)     TOSR <= rpop_tosr;
      end
    end else if (s3_cancel) begin
      // 恢复到 s3 快照，再按需补 push/pop。Scala 序：specPop（missed_pop）先、
      // specPush（missed_push）后 —— push 后写，整体覆盖 pop。
      ssp  <= s3_meta_ssp;
      sctr <= s3_meta_sctr;
      TOSR <= s3_meta_TOSR;
      TOSW <= s3_meta_TOSW;
      if (s3_missed_pop) begin
        sctr <= s3pop_sctr;
        if (s3pop_ssp_we) ssp  <= s3pop_ssp;
        if (s3pop_we)     TOSR <= s3pop_tosr;
      end
      if (s3_missed_push) begin
        sctr <= s3p_sctr; TOSR <= s3p_tosr; TOSW <= s3p_tosw;
        if (s3p_ssp_we) ssp <= s3p_ssp;
      end
    end else begin
      // 正常路径：Scala 序为 specPush 先、specPop 后（pop 后写，局部覆盖 push）。
      // 二者可同拍有效：ssp 取 push 结果但若 pop 真正退一层(sctr==0)则由 pop 覆盖；
      // sctr/TOSR 优先 pop；TOSW 仅 push 推进。
      if (spec_push_valid) begin
        sctr <= push_sctr; TOSR <= push_tosr; TOSW <= push_tosw;
        if (push_ssp_we) ssp <= push_ssp;
      end
      if (spec_pop_valid) begin
        sctr <= pop_sctr;
        if (pop_ssp_we) ssp  <= pop_ssp;
        if (pop_we)     TOSR <= pop_tosr;
      end
    end
  end

  // ===========================================================================
  // 时序：提交栈 commit_stack / nsp / BOS（后端 commit 维护「真值」）
  // ===========================================================================
  wire ras_entry_t   commitTop        = commit_stack[nsp];
  // 提交侧要 push 的地址：来自投机栈在 commit_meta_TOSW 槽记录的 retAddr
  wire [VADDR_W-1:0] commit_push_addr = spec_queue[commit_meta_TOSW.value].retAddr;

  // 若提交侧记录的 ssp 与本地 nsp 不一致，强制对齐（容错，避免永久错位）
  wire [SSP_W-1:0] nsp_aligned = (commit_meta_ssp != nsp) ? commit_meta_ssp : nsp;

  // commit pop：ctr>0 → --ctr（nsp 对齐不动）；否则 --nsp
  wire commit_pop_dec_ctr  = commit_pop_valid & (commitTop.ctr > 0);
  // commit push：未饱和且地址相同 → ++ctr；否则 ++nsp 并写新项
  wire commit_push_inc_ctr = commit_push_valid & (commitTop.ctr < CTR_MAX)
                                              & (commitTop.retAddr == commit_push_addr);
  wire [SSP_W-1:0] nsp_pushed = sp_inc(nsp_aligned);

  genvar gc;
  generate
    for (gc = 0; gc < RAS_SIZE; gc++) begin : g_commit
      wire pop_hit_ctr  = commit_pop_dec_ctr  & (nsp_aligned == SSP_W'(gc)); // --ctr 目标
      wire push_hit_ctr = commit_push_inc_ctr & (nsp_aligned == SSP_W'(gc)); // ++ctr 目标
      wire push_hit_new = commit_push_valid & ~commit_push_inc_ctr
                                            & (nsp_pushed == SSP_W'(gc));     // 新项目标
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          commit_stack[gc] <= '0;
        end else if (push_hit_new) begin
          commit_stack[gc].retAddr <= commit_push_addr;
          commit_stack[gc].ctr     <= '0;
        end else if (push_hit_ctr) begin
          commit_stack[gc].ctr <= commitTop.ctr + 1'b1;
        end else if (pop_hit_ctr) begin
          commit_stack[gc].ctr <= commitTop.ctr - 1'b1;
        end
      end
    end
  endgenerate

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      nsp <= '0;
      BOS <= '{flag: 1'b0, value: '0};
    end else begin
      // nsp
      if (commit_push_valid)
        nsp <= commit_push_inc_ctr ? nsp_aligned : nsp_pushed;
      else if (commit_pop_valid)
        nsp <= commit_pop_dec_ctr ? nsp_aligned : sp_dec(nsp_aligned);
      // BOS：commit push 跟到 commit_meta_TOSW；否则提交边界落后太多时推进一格
      if (commit_push_valid)
        BOS <= commit_meta_TOSW;
      else if (commit_valid && (distance(commit_meta_TOSW, BOS) > (SPTR_W+1)'(2)))
        BOS <= ptr_dec(commit_meta_TOSW);
    end
  end

  // ===========================================================================
  // 时序：spec_near_overflow —— 投机栈快满（在途项逼近容量）时反压上游
  //   distance(TOSW, BOS) > RAS_SPEC_SIZE-2 即认为将溢出。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) spec_near_overflowed <= 1'b0;
    else       spec_near_overflowed <= distance(TOSW, BOS) > (SPTR_W+1)'(RAS_SPEC_SIZE-2);
  end

  // ===========================================================================
  // 时序：writeBypass 旁路寄存器
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) writeBypassValid <= 1'b0;
    else       writeBypassValid <= writeBypassValidWire;
  end

  always_ff @(posedge clock) begin
    // 仅在「有 push（正常或 redirect-call）」时刷新旁路 entry/NOS
    if (spec_push_valid | redir_call) begin
      writeBypassEntry <= writeEntry;
      writeBypassNos   <= writeNos;
    end
  end

  // ===========================================================================
  // 时序：realPush 写入用的「s2 打拍快照」
  //   注意两组 enable 不同（与 Scala 一致）：
  //     · realWriteEntry_next 的 enable 是 (s2_fire | redirect_isCall)——用「裸 isCall」，
  //       不要求 redirect_valid；
  //     · realWriteAddr_next / realNos_next 的 enable 是 (s2_fire | redir_call)。
  //   写入值里仍用 redir_call（=valid&isCall）选 redirect 快照还是当前 TOSW/TOSR。
  // ===========================================================================
  always_ff @(posedge clock) begin
    if (s2_fire | redirect_isCall) begin
      realWriteEntry_next <= writeEntry;
    end
    if (s2_fire | redir_call) begin
      realWriteAddr_next  <= redir_call ? redirect_meta_TOSW.value : TOSW.value;
      realNos_next        <= redir_call ? redirect_meta_TOSR : TOSR;
    end
    if (s2_fire) realPush_specPush_q <= spec_push_valid;
    realPush_redir_q <= redir_call;
  end

  // ===========================================================================
  // 时序：timingTop —— 提前一拍算好「下一拍栈顶 retAddr」，作为 spec_pop_addr 输出
  //   按与指针更新相同的优先级，预测下一拍逻辑栈顶会落在哪。
  // ===========================================================================
  // pop 后的「下一拍栈顶」（不走旁路），用 NOS 作为新 TOSR；下一拍 ssp 由 sctr 决定。
  //   纯函数：候选项（spec_entry/commit_entry）与 in_range 由调用处算好传入。
  function automatic ras_entry_t pop_next_top(
      input logic [CTR_W-1:0] c_sctr, input logic in_range,
      input ras_entry_t spec_entry, input ras_entry_t commit_entry);
    // 注：c_sctr>0 时下一拍仍在同一深度（ssp 不变），否则退一层（ssp-1）——
    // 但取栈顶只看 in_range：在途则取 spec_entry，否则取 commit_entry（已按正确 ssp 取好）。
    return sel_top(1'b0, 1'b0, in_range, '0, spec_entry, commit_entry);
  endfunction

  // 各 timingTop 分支的候选栈顶（在 always_comb 内做数组索引，FM 友好）
  ras_entry_t tt_redir_ret, tt_redir, tt_pop, tt_s3, tt_cur, s3_cancel_top;
  // 下一拍 ssp（pop 路径）：sctr>0 不变，否则 -1
  wire [SSP_W-1:0] pop_nssp_cur   = (sctr > 0)                ? ssp                : sp_dec(ssp);
  wire [SSP_W-1:0] pop_nssp_redir = (redirect_meta_sctr > 0)  ? redirect_meta_ssp  : sp_dec(redirect_meta_ssp);
  wire [SSP_W-1:0] pop_nssp_s3    = (s3_meta_sctr > 0)        ? s3_meta_ssp        : sp_dec(s3_meta_ssp);
  always_comb begin
    // redirect-ret 下一拍栈顶：新 TOSR=NOS
    tt_redir_ret = pop_next_top(redirect_meta_sctr,
                     tosr_in_range(redirect_meta_NOS, redirect_meta_TOSW, BOS),
                     spec_queue[redirect_meta_NOS.value], commit_stack[pop_nssp_redir]);
    // redirect 非 ret：当前快照栈顶
    tt_redir = sel_top(1'b0, writeBypassValid,
                 tosr_in_range(redirect_meta_TOSR, redirect_meta_TOSW, BOS),
                 writeBypassEntry, spec_queue[redirect_meta_TOSR.value], commit_stack[redirect_meta_ssp]);
    // 正常 pop 下一拍栈顶
    tt_pop = pop_next_top(sctr, tosr_in_range(topNos, TOSW, BOS),
                 spec_queue[topNos.value], commit_stack[pop_nssp_cur]);
    // 当前栈顶（不走旁路）
    tt_cur = sel_top(1'b0, writeBypassValid, tosr_in_range(TOSR, TOSW, BOS),
                 writeBypassEntry, spec_queue[TOSR.value], commit_stack[ssp]);
    // s3 快照栈顶（不走旁路）
    tt_s3 = sel_top(1'b0, writeBypassValid, tosr_in_range(s3_meta_TOSR, s3_meta_TOSW, BOS),
                 writeBypassEntry, spec_queue[s3_meta_TOSR.value], commit_stack[s3_meta_ssp]);
    // s3_cancel 路径的下一拍栈顶
    if (s3_missed_push) begin
      s3_cancel_top.retAddr = s3_pushAddr;   // golden 此分支只用 retAddr，ctr 不参与输出
      s3_cancel_top.ctr     = '0;
    end else if (s3_missed_pop) begin
      s3_cancel_top = pop_next_top(s3_meta_sctr,
                        tosr_in_range(s3_meta_NOS, s3_meta_TOSW, BOS),
                        spec_queue[s3_meta_NOS.value], commit_stack[pop_nssp_s3]);
    end else begin
      s3_cancel_top = tt_s3;
    end
  end

  // timingTop 只输出 retAddr（= spec_pop_addr），下一拍栈顶的 ctr 从不被读 →
  // 与 golden 一致只存 retAddr，不存 ctr，避免 ctr[2:0] 成为 impl-only cone-dead 寄存器。
  logic [VADDR_W-1:0] timingTop_retAddr;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      timingTop_retAddr <= '0;
    end else if (writeBypassValidWire) begin
      timingTop_retAddr <= (redir_call | spec_push_valid) ? writeEntry.retAddr : writeBypassEntry.retAddr;
    end else if (redirect_valid & redirect_isRet) begin
      timingTop_retAddr <= tt_redir_ret.retAddr;
    end else if (redirect_valid) begin
      timingTop_retAddr <= tt_redir.retAddr;
    end else if (spec_pop_valid) begin
      timingTop_retAddr <= tt_pop.retAddr;
    end else if (realPush) begin
      timingTop_retAddr <= realWriteEntry.retAddr;
    end else if (s3_cancel) begin
      timingTop_retAddr <= s3_cancel_top.retAddr;
    end else begin
      timingTop_retAddr <= tt_cur.retAddr;
    end
  end

  // ===========================================================================
  // 输出
  // ===========================================================================
  assign spec_pop_addr        = timingTop_retAddr;
  assign ssp_o                = ssp;
  assign sctr_o               = sctr;
  assign TOSR_o               = TOSR;
  assign TOSW_o               = TOSW;
  assign NOS_o                = topNos;
  assign spec_near_overflow_o = spec_near_overflowed;

endmodule
