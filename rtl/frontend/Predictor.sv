// =============================================================================
// Predictor.sv —— 分支预测单元 BPU 的**顶层流水与历史管理器**
//                 (Chisel: xiangshan.frontend.Predictor)
//
// 【它在前端的位置】
//   取指流水的最前端是 BPU。BPU 不取指令，只回答一个问题：「下一个取指块从哪开始」。
//   它把答案(s0_pc)交给 FTQ(Ftq.sv)，FTQ 再驱动 ICache/IFU 去真正取指。
//
//     Predictor(本模块) ──s0_pc──▶ Composer(5 个预测器) ──预测包──▶ 本模块 ──▶ Ftq
//
//   本模块与 Composer 的分工非常干净：
//     · **Composer 只负责"猜"**：uFTB/TAGE-SC/FTB/ITTAGE/RAS 五个预测器串成菊花链，
//       吐出 s1/s2/s3 三级预测包(full_pred)。它不管流水、不管历史、不管重定向。
//     · **本模块负责"管"**：三件事 ——
//         (1) 覆盖式流水的 valid/ready/fire/flush 握手；
//         (2) 级间覆盖判定：s2 与上一拍 s1 比、s3 与上一拍 s2 比，不一致就发 override；
//         (3) **全局分支历史 GHV 的推测更新与重定向回滚**(本模块最重的部分)。
//
// 【S0~S3 四级覆盖式流水】
//   S0  由优先级选择器选出下一个 s0_pc（见下"五个 PhyPriorityMux"）
//   S1  uFTB 零气泡给第一版预测，当拍就能送 FTQ
//   S2  FTB/TAGE 给更准的结果；与上一拍 S1 的结论比，不同则 s2_redirect 覆盖
//   S3  SC/ITTAGE/RAS 最终修正；与上一拍 S2 比，不同则 s3_redirect 覆盖
//   越后级越准但越晚；每次覆盖都要把已经走错的取指流冲掉，并把历史回滚重算。
//
// 【五个 PhyPriorityMux：S0 状态从哪来】
//   S0 要同时选出 5 样东西：pc、折叠历史 FGH、历史指针 GHPtr、最后分支位置 OH、
//   以及折叠历史的"最老位" AFHOB。五者用**同一套优先级**从 5 个来源里选：
//
//     优先级(高→低)   来源            触发条件
//       最高          redirect_target do_redirect   FTQ 送来的真实重定向(后端/IFU)
//                     s3_target       s3_redirect   S3 覆盖
//                     s2_target       s2_redirect   S2 覆盖
//                     s1_target       s1_valid      S1 正常前进
//       兜底          stallPC         (无人要求)    S0 停住时保持原值
//
//   越"晚"越权威：真重定向是已经执行过的事实，压过一切推测；S3 比 S2 准，S2 比 S1 准。
//
//   ★读 golden 时的坑★：Chisel 侧 `gen.register(cond, data, name, prio)` 里那个 prio
//   数字(stall=0/redirect=2/s3=3/s1=4/s2=5)**不是**优先级高低，它只决定生成的
//   PriorityMuxModule 端口排列顺序；真正的优先级是**注册顺序、后注册者胜**
//   (BPU.scala 依次注册 stall→s1→s2→s3→redirect)。golden 把它编码在 sel 表达式里
//   而不是 mux 链里 —— 每一路 sel 都预先与所有更高优先级路取反相与，做成互斥 one-hot：
//       s2_sel = s2_redirect & ~s3_redirect & ~do_redirect
//       s1_sel = s1_valid    & ~s2_redirect & ~s3_redirect & ~do_redirect
//   所以照 PriorityMuxModule 的端口顺序(s2,s1,s3,redirect)去理解优先级会**读反**。
//   本重写直接写成按真实优先级排的 `? :` 链（见 SEL_ 节），语义等价且不会误读。
//
// 【★本次重写的核心：GHV 从 256 个散装寄存器收回成一个向量★】
//   全局历史 GHV 是一个 256 位的**环形位缓冲**，s0_ghist_ptr 指向它的写入点。
//   firtool 把它彻底摊平了：golden 里是 `ghv_0 … ghv_255` 256 个独立 1 位 reg，
//   全文出现 13,312 次（每次"读历史"都要把 256 个名字拼一遍），配套 256 个
//   `PriorityMuxModule_20` 实例(ghv_write_datas_0_ppm … _255_ppm)做每位的写数据选择。
//   仅这一项就撑起了 golden 44,908 行里的绝大部分。
//   本文件把它写回**一个 `logic [255:0] ghv` + 一个 generate 循环**（见 GHV_ 节）：
//   256 个实例塌缩成 4 行优先级链，13,312 次拼接塌缩成一次 `{ghv, ghv} >> ptr`。
//
// 【MBIST 直通：633 端口里 457 个不是功能端口】
//   本模块 633 个端口中 **457 个(72%)** 是 MBIST 扫描链(sigFromSrams_bore_* /
//   boreChildrenBd_bore_*)，一根不改地穿到 Composer，零逻辑。真正的功能端口只有 176 个。
//   所以那 457 根放在 wrapper 里由脚本生成(GENERATED(mbist_conn))，可读核根本看不见它们。
//
// 【可读核不做的事】
//   · 预测本身 —— 在 Composer 里(本文件只例化它)；
//   · 187 个预测包字段的输出 —— Composer 直连顶层输出，wrapper 里连线，不进核。
// =============================================================================
// 本文件导航（共 3384 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L38    它在前端的位置
//   L52    S0~S3 四级覆盖式流水
//   L59    五个 PhyPriorityMux：S0 状态从哪来
//   L82    ★本次重写的核心：GHV 从 256 个散装寄存器收回成一个向量★
//   L91    MBIST 直通：633 端口里 457 个不是功能端口
//   L96    可读核不做的事
//   L218   xs_Predictor_core —— 可读核
//   L288   PRED_ —— 从 full_pred 派生的预测属性
//   L415   PIPE_ —— S1/S2/S3 覆盖式流水握手
//   L515   GHV_ —— ★全局历史向量：一个 256 位环形位缓冲★
//   L520   怎么用】ghist_ptr 指向"最新一位的下一格"
//   L526   谁写】四个源，同一套优先级
//   L563   AFHOB_ —— 折叠历史的"最老位"预读
//   L589   FH_ —— 折叠历史的增量更新
//   L658   GHVWR_ —— 把"某一级要往 GHV 写什么"算成 256 位的 wen/wdata
//   L683   STAGE_ —— S1/S2/S3 的历史状态流水
//   L781   OVR_ —— 级间覆盖判定
//   L824   RDR_ —— FTQ 真重定向：锁存一拍，然后把历史整体回滚重算
//   L897   SEL_ —— S0 五选一
//   L939   流水寄存器本体
//   L944   s0_pc_reg 是全模块唯一**不带复位**的流水寄存器
//   L1045  GHV 写：四个源各自算 wen/wdata
//   L1062  GHIST_ —— 送 Composer 的"推测历史"
//   L1090  送 FTQ 的控制输出
//   L1120  TOPDOWN_ —— 取指气泡归因
//   L1192  上电复位状态
//   L1201  predCycle —— 打在预测包上的时间戳
//   L1237  SEGPC_ —— update pc 的分段打拍
//   L1257  PERF_ —— Composer 的 7 路性能计数各打 2 拍再送出
//   L1259  golden 这 14 个寄存器**不带复位**
//   L1272  Predictor —— golden 同名 wrapper
//

package predictor_pkg;

  // ---- KunminghuV2Config 下的 BPU 几何 ----------------------------------
  localparam int unsigned VADDR_BITS    = 50;   // 虚地址位宽
  localparam int unsigned PADDR_BITS    = 48;   // reset_vector 位宽
  localparam int unsigned HIST_LEN      = 256;  // 全局历史 GHV 的位数(环形)
  localparam int unsigned HIST_PTR_BITS = 8;    // log2(HIST_LEN)
  localparam int unsigned NUM_BR        = 2;    // 一个取指块最多 2 条分支
  localparam int unsigned TOTAL_SLOT    = 2;    // FTB 表项的槽数(1 个 br 槽 + 1 个尾槽)
  localparam int unsigned NUM_DUP       = 4;    // 扇出复制份数
  localparam int unsigned PREDICT_WIDTH = 16;   // 一个取指块最多 16 条指令
  localparam int unsigned OFFSET_BITS   = 4;    // log2(PREDICT_WIDTH)
  localparam int unsigned FETCH_BYTES   = 32;   // FetchWidth(8) * 4，"未命中"时的顺序步进
  localparam int unsigned FTQ_PTR_BITS  = 6;    // log2(FtqSize=64)
  localparam int unsigned NUM_STAGE     = 3;    // S1/S2/S3
  localparam int unsigned NUM_REASON    = 13;   // TopDownCounters 的槽位数

  // ---- 折叠历史(folded history) ----------------------------------------
  // TAGE/SC/ITTAGE 不直接用 256 位原始历史，而是用**折叠**后的短哈希：把 LEN 位历史
  // 按 CLEN 位一段切开、逐段 XOR 成 CLEN 位。每张预测表按自己的 (LEN,CLEN) 要一份。
  // 本 build 共 17 份(golden 的 hist_1..hist_17；Chisel 里还有个 hist_0=(4,8) 是 uFTB
  // 的，没有任何消费者，firtool 已消除，这里同样不建)。
  //
  // 维护方式："每拍重算" 太贵，所以增量更新：新分支方向从高位挤进来、最老的一位从
  // LEN-1 处退出。退出的那一位要在**它当初被 XOR 进去的位置**再 XOR 一次消掉 ——
  // 那个位置就是 (LEN-1) % CLEN。这些"最老位"由 AFHOB 预先从 GHV 读好(见下)。
  localparam int unsigned NUM_FH   = 17;
  localparam int unsigned FH_MAX_W = 11;        // 最宽的 CLEN

  // 下标 1..17 与 golden 的 hist_1..hist_17 逐一对应。
  //                                              1   2   3   4   5    6   7   8    9
  localparam int unsigned FH_LEN  [1:NUM_FH] = '{13, 16, 32, 13, 119, 16,  8, 119, 32,
  //                                             10  11  12  13  14  15   16   17
                                                 32, 10,  4, 13,  8, 13, 119,  32};
  localparam int unsigned FH_CLEN [1:NUM_FH] = '{11,  8,  8,  8,   7,  9,  7,   8,  7,
                                                  9,  8,  4,  9,  8,  7,  11,  11};

  // ---- AFHOB：折叠历史的"最老位"预读 -------------------------------------
  // 每个**不同的 LEN**(且 LEN>CLEN，即真的会绕回来)要预读 GHV 上 LEN..LEN-3 这 4 位。
  // 本 build 有 6 个不同的 LEN：
  localparam int unsigned NUM_AFHOB = 6;
  //                                                  0   1   2   3  4    5
  localparam int unsigned AFHOB_LEN [0:NUM_AFHOB-1] = '{10, 13, 32, 16, 8, 119};

  // 每份折叠历史用哪个 AFHOB（-1 = LEN<=CLEN，不绕回，不需要最老位）
  localparam int signed FH_AFHOB [1:NUM_FH] = '{1, 3, 2, 1, 5, 3, 4, 5, 2,
                                                2, 0, -1, 1, -1, 1, 5, 2};

  // ---- S0 状态五选一的优先级（大者胜；见文件头） ------------------------
  // 只用来给读代码的人对照 golden 的 PriorityMuxModule 端口顺序，逻辑里写成显式链。
  localparam int unsigned PRIO_S2 = 5, PRIO_S1 = 4, PRIO_S3 = 3, PRIO_REDIRECT = 2,
                          PRIO_STALL = 0;

  // ---- 类型 -------------------------------------------------------------
  typedef logic [VADDR_BITS-1:0]    vaddr_t;
  typedef logic [FH_MAX_W-1:0]      fh_word_t;              // 折叠历史(按 CLEN 右对齐)
  typedef fh_word_t [1:NUM_FH]      folded_hist_t;
  typedef logic [NUM_BR*2-1:0]      afhob_word_t;           // 一组 4 个最老位
  typedef afhob_word_t [0:NUM_AFHOB-1] afhob_t;

  // 环形历史指针：flag 是绕圈标志，value 是 GHV 下标
  typedef struct packed {
    logic                       flag;
    logic [HIST_PTR_BITS-1:0]   value;
  } cgh_ptr_t;

  // Composer 每级给出的完整预测包（1 份 dup）。字段名与 golden 端口逐一对应。
  typedef struct packed {
    logic [NUM_BR-1:0]                     br_taken_mask;
    logic [TOTAL_SLOT-1:0]                 slot_valids;
    vaddr_t [TOTAL_SLOT-1:0]               targets;
    vaddr_t                                jalr_target;
    logic [TOTAL_SLOT-1:0][OFFSET_BITS-1:0] offsets;
    vaddr_t                                fall_through_addr;
    logic                                  fall_through_err;
    logic                                  multi_hit;       // 只有 S3 有真值
    logic                                  is_br_sharing;
    logic                                  hit;
  } full_pred_t;


  // FTQ 送来的重定向包。本模块把整包锁存一拍(do_redirect)：
  //   · 上半部分字段本核要用（算历史回滚、topdown 气泡归因）；
  //   · 下半部分只是打一拍原样转发给 Composer，本核不看。
  typedef struct packed {
    // —— 本核使用 ——
    logic [1:0]   shift;            // 这次重定向要往历史里补几条分支
    logic         add_into_hist;
    logic         taken;
    cgh_ptr_t     hist_ptr;         // 重定向点当时的历史指针
    vaddr_t       target;
    logic         br_hit;           // 以下 4 个只用于 topdown 气泡归因
    logic         jr_hit;
    logic         sc_hit;
    logic         pd_is_ret;
    logic         debug_is_ctrl;
    logic         debug_is_mem_vio;
    logic         btb_miss_bubble;
    // —— 仅转发给 Composer ——
    logic [1:0]   level;
    vaddr_t       cfi_pc;
    logic         pd_valid;
    logic         pd_is_rvc;
    logic         pd_is_call;
    logic [4:0]   ssp;
    logic [2:0]   sctr;
    logic         tosw_flag;
    logic [4:0]   tosw_value;
    logic         tosr_flag;
    logic [4:0]   tosr_value;
    logic         nos_flag;
    logic [4:0]   nos_value;
  } redirect_bundle_t;

endpackage

// =============================================================================
// xs_Predictor_core —— 可读核
//
// 核只拿**功能信号**：Composer 的三级预测包 + FTQ 来的 update/redirect。
// 457 根 MBIST 扫描线、187 根预测包直连输出都在 wrapper 里接，不进核。
// =============================================================================
module xs_Predictor_core
  import predictor_pkg::*;
(
  input  logic                    clock,
  input  logic                    reset,
  input  logic [PADDR_BITS-1:0]   io_reset_vector,

  // ---- 来自 Composer 的三级预测 ----------------------------------------
  input  vaddr_t                  s1_pc      [0:NUM_DUP-1],
  input  vaddr_t                  s2_pc      [0:NUM_DUP-1],
  input  vaddr_t                  s3_pc      [0:NUM_DUP-1],
  input  full_pred_t              s1_pred    [0:NUM_DUP-1],
  input  full_pred_t              s2_pred    [0:NUM_DUP-1],
  input  full_pred_t              s3_pred    [0:NUM_DUP-1],
  input  logic                    comp_s1_ready,
  input  logic                    comp_s2_ready,
  input  logic                    comp_s3_ready,

  // ---- 来自 FTQ ---------------------------------------------------------
  input  logic                    ftq_resp_ready,
  input  logic                    ftq_enq_ptr_flag,
  input  logic [FTQ_PTR_BITS-1:0] ftq_enq_ptr_value,
  input  logic                    ftq_redirect_from_ifu,
  input  logic                    ftq_redirect_valid,
  input  logic                    ftq_update_valid,
  input  cgh_ptr_t                ftq_update_hist_ptr,
  input  vaddr_t                  ftq_update_pc,
  input  logic [5:0]              comp_perf   [0:6],   // Composer 的 7 路性能计数
  input  redirect_bundle_t        redirect_in,         // FTQ 当拍送来的重定向包（未锁存）


  // ---- 送 Composer 的 S0 状态与流水握手 --------------------------------
  output vaddr_t                  s0_pc_sel      [0:NUM_DUP-1],
  output folded_hist_t            s0_folded_gh   [0:NUM_DUP-1],
  output cgh_ptr_t                s0_ghist_ptr   [0:NUM_DUP-1],
  output logic [NUM_BR:0]         s0_last_br_num_oh [0:NUM_DUP-1],
  output folded_hist_t            s1_folded_gh_o [0:NUM_DUP-1],
  output logic [HIST_LEN-1:0]     s0_ghist,
  output logic [HIST_LEN-1:0]     update_ghist,
  output logic                    s0_fire        [0:NUM_DUP-1],
  output logic                    s1_fire        [0:NUM_DUP-1],
  output logic                    s2_fire        [0:NUM_DUP-1],
  output logic                    s3_fire        [0:NUM_DUP-1],
  output logic                    s2_redirect    [0:NUM_DUP-1],
  output logic                    s3_redirect    [0:NUM_DUP-1],
  output logic                    redirect_from_ifu_q,
  output logic                    do_redirect_valid,   // 锁存后的重定向 valid（送 Composer）
  output redirect_bundle_t        do_redirect_bits,

  // ---- 送 FTQ -----------------------------------------------------------
  output logic                    bpu_resp_valid,
  output logic                    to_ftq_s2_valid,
  output logic                    to_ftq_s3_valid,
  output cgh_ptr_t                s3_ghist_ptr_o,
  output logic                    s2_ftq_idx_flag,
  output logic [FTQ_PTR_BITS-1:0] s2_ftq_idx_value,
  output logic                    s3_ftq_idx_flag,
  output logic [FTQ_PTR_BITS-1:0] s3_ftq_idx_value,
  output logic [NUM_REASON-1:0]   topdown_info_reasons,
  output logic [63:0]             pred_cycle,
  output vaddr_t                  update_pc_seg,       // 分段打拍后的 update pc（送 Composer）
  output logic [5:0]              perf_out    [0:6]
);

  // ===========================================================================
  // PRED_ —— 从 full_pred 派生的预测属性
  //
  // Composer 只给原始字段(哪个槽有效、哪个方向、目标地址…)。"这次预测到底跳不跳、
  // 跳到哪、历史该移几位"全部是**组合派生**，Chisel 里写成 FullBranchPrediction
  // 的一堆 def。下面把它们一次算全，放进 derived_t 供全模块共用 —— 既避免同一串
  // 逻辑被重复展开，也让每个派生量只有一处定义可读。
  //
  //   槽的含义：slot[0] 是**专用分支槽**，slot[1] 是**尾槽**——尾槽平时放跳转
  //   (jal/jalr/call/ret)，但当 is_br_sharing 时它被第二条分支借用。
  //   numBr = totalSlot = 2，下面已按此展开。
  // ===========================================================================
  typedef struct packed {
    logic [NUM_BR-1:0]      br_valids;        // 每个槽装的是不是条件分支
    logic [TOTAL_SLOT-1:0]  taken_on_slot;    // 每个槽"要跳"(还没看 hit)
    logic [TOTAL_SLOT-1:0]  real_slot_taken;  // 上一行 & hit
    logic [NUM_BR-1:0]      real_br_taken;    // 真正生效的**分支**跳转掩码
    logic [NUM_BR-1:0]      should_shift;     // 每条分支要不要进全局历史
    logic [NUM_BR:0]        last_br_pos_oh;   // one-hot：最后一条进历史的分支在哪
    logic                   br_taken;         // 这块里有分支跳了
    logic                   cfi_valid;        // 这块真的发生了跳转
    logic [OFFSET_BITS-1:0] cfi_index;        // 跳转指令在块内的偏移
  } derived_t;

  // 一次算全。刻意全部内联、不互相调用：VCS W-2024.09-SP1 在"函数里套调带 struct
  // 参数的函数"到一定深度时会 elaborate 段错误（已最小化复现），而且共享子表达式
  // 本来就该只算一次。
  function automatic derived_t derive(full_pred_t p);
    derived_t d;
    logic [TOTAL_SLOT-1:0] tms;
    // 尾槽被第二条分支借用时才算分支
    d.br_valids       = {p.slot_valids[1] & p.is_br_sharing, p.slot_valids[0]};
    // 尾槽若不是分支，它一有效就是无条件跳
    tms               = {p.slot_valids[1] & ((p.is_br_sharing & p.br_taken_mask[1]) | ~p.is_br_sharing),
                         p.slot_valids[0] &  p.br_taken_mask[0]};
    d.taken_on_slot   = tms;
    d.real_slot_taken = tms & {TOTAL_SLOT{p.hit}};
    d.real_br_taken   = {p.br_taken_mask[1] & p.slot_valids[1] & p.is_br_sharing & p.hit,
                         tms[0] & p.hit};
    // 前面已有分支跳了，后面的分支就不进历史了
    d.should_shift    = {d.br_valids[1] & p.hit & ~d.real_br_taken[0],
                         d.br_valids[0] & p.hit};
    d.last_br_pos_oh  = {d.br_valids[1] & ~d.real_br_taken[0] & p.hit,
                         d.br_valids[0] & (d.real_br_taken[0] | ~d.br_valids[1]) & p.hit,
                         ~p.hit | ~(d.br_valids[0] | d.br_valids[1])};
    d.br_taken        = ((d.br_valids[0] & p.br_taken_mask[0])
                       | (d.br_valids[1] & p.br_taken_mask[1])) & p.hit;
    d.cfi_valid       = |d.real_slot_taken;
    // 都不跳时钉成全 1（FTQ 按"块尾"处理）
    d.cfi_index       = (d.real_slot_taken[0] ? p.offsets[0]
                       : d.real_slot_taken[1] ? p.offsets[1] : '0)
                      | {OFFSET_BITS{~(|d.real_slot_taken)}};
    return d;
  endfunction

  // allTarget：所有候选目标，顺序固定
  //   [0]=槽0 目标 [1]=槽1 目标 [2]=顺序落空地址 [3]=未命中(pc+32)
  function automatic vaddr_t all_target_of(full_pred_t p, vaddr_t pc, int unsigned i);
    case (i)
      0:       return p.targets[0];
      1:       return p.targets[1];
      2:       return p.fall_through_addr;
      default: return vaddr_t'(pc + FETCH_BYTES);
    endcase
  endfunction

  // selectByTaken：按"第一个要跳的槽"选目标；都不跳选落空；没命中选 pc+32。
  // hit_eff：S1/S2 直接用 hit；S3 还要求落空地址没算错（S3 才有纠错权）。
  //
  // ★写成 Mux1H（或-与）而不是 ? : 优先级链★：四个 sel 互斥且**穷尽**，两种写法在
  // 二值逻辑下等价，FM 判不出差别。但优先级链必须有个兜底 `else '0`，而那条路在
  // hit_eff=X 时会被走到 —— 把 X **变成确定的 0**，于是 target_diff 从 X 变成确定的 1，
  // 凭空触发 S3 覆盖。golden 是 Mux1H，X 进 X 出。本轮 UT 的幽灵 override 就是这么来的。
  function automatic vaddr_t target_sel(full_pred_t p, vaddr_t pc,
                                        logic [TOTAL_SLOT-1:0] tms, logic hit_eff);
    logic [3:0] sel;
    sel[0] =   tms[0]            & hit_eff;   // 槽0 跳
    sel[1] =  ~tms[0] &  tms[1]  & hit_eff;   // 槽0 不跳、槽1 跳
    sel[2] =  ~(|tms)            & hit_eff;   // 都不跳 → 顺序落空
    sel[3] =  ~hit_eff;                       // 没命中 FTB → pc+32
    return ({VADDR_BITS{sel[0]}} & p.targets[0])
         | ({VADDR_BITS{sel[1]}} & p.targets[1])
         | ({VADDR_BITS{sel[2]}} & p.fall_through_addr)
         | ({VADDR_BITS{sel[3]}} & vaddr_t'(pc + FETCH_BYTES));
  endfunction

  // ---- 每级预测包的派生属性算一次，全模块共用 ----------------------------
  // 另外三份"上一拍的结论"也在这里声明，好让派生量集中在一处算完。
  typedef struct packed {
    logic                   hit;
    vaddr_t                 target;
    logic [NUM_BR:0]        last_br_pos_oh;
    logic                   taken;
    logic [TOTAL_SLOT-1:0]  taken_mask;
    logic [OFFSET_BITS-1:0] cfi_index;
  } prev_s1_t;
  prev_s1_t   prev_s1    [0:NUM_DUP-1];   // 上一拍 S1 的结论（s1_fire 时锁存）
  full_pred_t prev_s2    [0:NUM_DUP-1];   // 上一拍 S2 的结论（s2_fire 时锁存）
  vaddr_t     prev_s2_pc [0:NUM_DUP-1];

  derived_t d_s1 [0:NUM_DUP-1], d_s2 [0:NUM_DUP-1], d_s3 [0:NUM_DUP-1], d_ps2 [0:NUM_DUP-1];
  vaddr_t   tgt_s1 [0:NUM_DUP-1], tgt_s2 [0:NUM_DUP-1], tgt_s3 [0:NUM_DUP-1], tgt_ps2 [0:NUM_DUP-1];

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_derive
    assign d_s1[d]  = derive(s1_pred[d]);
    assign d_s2[d]  = derive(s2_pred[d]);
    assign d_s3[d]  = derive(s3_pred[d]);
    assign d_ps2[d] = derive(prev_s2[d]);
    assign tgt_s1[d]  = target_sel(s1_pred[d],  s1_pc[d],      d_s1[d].taken_on_slot,  s1_pred[d].hit);
    assign tgt_s2[d]  = target_sel(s2_pred[d],  s2_pc[d],      d_s2[d].taken_on_slot,  s2_pred[d].hit);
    // S3 是末级：落空地址算错时不能再信 hit（Chisel 的 isNotS3=false 分支）
    assign tgt_s3[d]  = target_sel(s3_pred[d],  s3_pc[d],      d_s3[d].taken_on_slot,
                                   s3_pred[d].hit & ~s3_pred[d].fall_through_err);
    assign tgt_ps2[d] = target_sel(prev_s2[d], prev_s2_pc[d], d_ps2[d].taken_on_slot, prev_s2[d].hit);
  end

  // ===========================================================================
  // 复位脉冲
  //   modified_reset 在复位放开后**只为真一拍**，用来把 s0_pc/s1_pc 装上复位向量。
  //   (G1 相对 G0 把两级 REG 改成单寄存器，脉冲提前了一拍。)
  // ===========================================================================
  logic modified_reset;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) modified_reset <= 1'b1;
    else       modified_reset <= 1'b0;
  end

  // ===========================================================================
  // PIPE_ —— S1/S2/S3 覆盖式流水握手
  //
  //   valid : 这一级手上有一个还没交出去的预测
  //   fire  : 这一级这一拍把结果交给下一级/FTQ
  //   flush : 后面来了更权威的结论，本级在飞的东西作废
  //   ready : 本级空着，或本级这拍就会交出去
  //
  //   冲刷是**自后向前**级联的：真重定向冲 S3，S3 再冲 S2，S2 再冲 S1。
  // ===========================================================================
  logic s1_valid_q, s2_valid_q, s3_valid_q;
  logic s1_flush [0:NUM_DUP-1], s2_flush [0:NUM_DUP-1], s3_flush;
  logic s1_ready, s2_ready, s3_ready;
  logic s1_comp_ready, s2_comp_ready, s3_comp_ready;
  logic s0_fire_w, s1_fire_w, s2_fire_w, s3_fire_w;

  assign s3_flush = ftq_redirect_valid;                    // FTQ 的真重定向
  for (genvar d = 0; d < NUM_DUP; d++) begin : g_flush
    assign s2_flush[d] = s3_flush      | s3_redirect[d];   // S3 覆盖
    assign s1_flush[d] = s2_flush[d]   | s2_redirect[d];   // S2 覆盖
  end

  assign s1_comp_ready = comp_s1_ready;
  assign s2_comp_ready = comp_s2_ready;
  assign s3_comp_ready = comp_s3_ready;

  assign s1_ready  = s1_fire_w | ~s1_valid_q;
  // ★s2_ready / s3_ready 在本配置下恒为 1，这里照 golden 写成常量★
  //   S3 是末级，s3_fire ≡ s3_valid  ⇒ s3_ready = s3_valid | ~s3_valid ≡ 1
  //   Composer 的 io_s2_ready/io_s3_ready 端口在 golden 里**根本不存在**
  //   (BasePredictor 里恒 true.B，被 firtool 整根消掉)，所以 s2/s3_comp_ready ≡ 1
  //   ⇒ s2_fire ≡ s2_valid ⇒ s2_ready = s2_valid | ~s2_valid ≡ 1。
  // golden 里 firtool 已经把这两个常量折掉了(见 io_bpu_to_ftq_resp_valid_0 只剩
  // s1_valid | s2_valid&s2_redirect | s3_valid&s3_redirect)。这里若照抄未折叠的
  // `x | ~x` 形式，**仿真里会凭空造出 X 悲观**——本轮 UT 实测就是被这个淹掉的。
  assign s2_ready  = 1'b1;
  assign s3_ready  = 1'b1;

  assign s0_fire_w = s1_comp_ready & s1_ready;
  assign s1_fire_w = s1_valid_q & s2_comp_ready & s2_ready & ftq_resp_ready;
  assign s2_fire_w = s2_valid_q & s3_comp_ready & s3_ready;
  assign s3_fire_w = s3_valid_q;                           // S3 是末级，有就发

  // ★四份 dup 依次写同一个寄存器，后写者胜 —— 不能只按一份 dup 算★
  //
  // Chisel 里 `dup_seq(RegInit(false.B))` 是 Seq.tabulate(4)(_ => src)，**四个元素
  // 是同一个寄存器对象**；随后那个 `for ((s0_fire, s1_flush, s1_fire, s1_valid) <- ...)`
  // 就变成"四条 when 链依次写同一个寄存器"。某一份 dup 的四个条件全不成立时，
  // 值**落到上一份 dup 的结果**上，而不是保持原值。golden 里因此是一个四层嵌套
  //     ~redirect & (s0_fire_3 | ~(s1_flush_3|s1_fire_3|redirect) & (s0_fire_2 | …))
  // 只按 dup0（或只按 dup3）算都是错的 —— s1_flush/s2_flush 每份 dup 不同
  // （它们含各自 dup 的 s2_redirect/s3_redirect）。
  // 下面这个 for 循环就是那条级联的直写形式，比 golden 的嵌套表达式好读得多。
  logic s1_valid_d, s2_valid_d, s3_valid_d;
  always_comb begin
    s1_valid_d = s1_valid_q;
    s2_valid_d = s2_valid_q;
    s3_valid_d = s3_valid_q;
    for (int d = 0; d < NUM_DUP; d++) begin
      // S1：真重定向最优先清，其次进人，再次冲刷/发走
      if      (ftq_redirect_valid) s1_valid_d = 1'b0;
      else if (s0_fire[d])         s1_valid_d = 1'b1;
      else if (s1_flush[d])        s1_valid_d = 1'b0;
      else if (s1_fire[d])         s1_valid_d = 1'b0;
      // S2/S3：进人时若上一级同拍被冲，进来的就是废的，直接不置 valid
      if      (s2_flush[d])        s2_valid_d = 1'b0;
      else if (s1_fire[d])         s2_valid_d = ~s1_flush[d];
      else if (s2_fire[d])         s2_valid_d = 1'b0;

      if      (s3_flush)           s3_valid_d = 1'b0;
      else if (s2_fire[d])         s3_valid_d = ~s2_flush[d];
      else if (s3_fire[d])         s3_valid_d = 1'b0;
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s1_valid_q <= 1'b0;
      s2_valid_q <= 1'b0;
      s3_valid_q <= 1'b0;
    end else begin
      s1_valid_q <= s1_valid_d;
      s2_valid_q <= s2_valid_d;
      s3_valid_q <= s3_valid_d;
    end
  end

  // 四份扇出复制：golden 里 s*_fire/s*_flush 是 wire（firtool 已把四份 CSE 成一个值），
  // 这里同样一处计算多处引用；只有 s2_redirect/s3_redirect 各 dup 真的不同（见 OVR_ 节）。
  for (genvar d = 0; d < NUM_DUP; d++) begin : g_fire_dup
    assign s0_fire[d] = s0_fire_w;
    assign s1_fire[d] = s1_fire_w;
    assign s2_fire[d] = s2_fire_w;
    assign s3_fire[d] = s3_fire_w;
  end

  // S0 停住：没有任何一个源要求换 pc 时，s0_pc 保持不动。
  //
  // ★这里必须是四份，不能共用一份★（2026-09-16，FM 抓到的第 9 个静默 bug）
  //   golden 有四个独立的 s0_stall（Predictor.sv:2828-2839）：
  //     _s0_stall_dup_d_T_2 = s1_valid_dup_3 | s2_redirect_dup_d | s3_redirect_dup_d
  //                           | do_redirect_dup_next_valid_last_REG
  //   注意它的形状是**部分共用、部分分份**：`s1_valid` 四份共用 dup_3、
  //   `do_redirect` 四份共用，只有 s2/s3_redirect 是 per-dup。这种混合形状最容易
  //   写错 —— 本文件先前就写成一份、且写死取 dup0。
  //
  //   后果：golden 里每份 dup 的 S0 保持寄存器用**自己那份**使能
  //   （Predictor.sv:25562-25569 四条 if 各用各的），而各 dup 的 s2/s3_redirect
  //   取值可以不同，于是 dup1/2/3 的 s0_pc / s0_folded_gh / s0_afhob /
  //   s0_ghist_ptr / s0_brnum 会在那些拍跟错。
  //
  //   ★为什么 UT 抓不到★：elaborate 干净、portlint 干净、UT errors=0、
  //   34 个覆盖点全非零，它照样藏着。FM 一跑，504 个失配点里 376 个 DFF 全部
  //   落在这五组 S0 寄存器上 —— 它们彼此无关，唯一共同点就是这个使能。
  //   同一形状的第一次是 to_ftq_s2_valid 误用 s2_flush[0]（golden 是 dup_3）。
  logic s0_stall [0:NUM_DUP-1];
  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s0_stall
    assign s0_stall[d] = ~(s1_valid_q | s2_redirect[d] | s3_redirect[d]
                           | do_redirect_valid);
  end

  // ===========================================================================
  // GHV_ —— ★全局历史向量：一个 256 位环形位缓冲★
  //
  // golden 把它摊成 ghv_0..ghv_255 共 256 个 1 位寄存器（全文引用 13,312 次），
  // 并给每一位配一个 PriorityMuxModule_20 选写数据。这里收回成一个向量 + generate。
  //
  // 【怎么用】ghist_ptr 指向"最新一位的下一格"。读历史 = 从 ptr+1 开始往回取 256 位，
  //   实现上把 ghv 拼两份再右移，天然处理绕回：
  //       getHist(ptr) = ({ghv, ghv} >> (ptr+1))[255:0]
  //   golden 里这一行要把 256 个寄存器名字拼一遍，每处 256 行 —— 这就是那 39,068 行
  //   表达式续行的主要来源。
  //
  // 【谁写】四个源，同一套优先级（与 S0 五选一同源，只是没有 stall 兜底，所以
  //   最低优先级的 redirect 直接当默认值 —— 这正是 PriorityMuxModule_20 只有 3 组
  //   sel/src 而不是 4 组的原因）。
  //   第 b 条分支要写的是环上 ptr-b 那一格，所以"第 n 位这拍被写"当且仅当
  //   存在 b 使得 ptr == n+b。
  // ===========================================================================
  logic [HIST_LEN-1:0] ghv_q;

  // 每一级/重定向各自的写使能与写数据（按位）
  logic [HIST_LEN-1:0] s1_ghv_wen, s2_ghv_wen, s3_ghv_wen, rdr_ghv_wen;
  logic [HIST_LEN-1:0] s1_ghv_wdata, s2_ghv_wdata, s3_ghv_wdata, rdr_ghv_wdata;
  logic [HIST_LEN-1:0] ghv_wen, ghv_wdata;

  // 本模块对外提供的"当前历史"读口（Composer 的 io_in_bits_ghist 要用推测值，
  // 见 GHIST_ 节；这里的 ghv_wire 与 golden 的 ghv_wire 一致 = 未经本拍写入的值）
  // ghv 显式当参数传进来，不在函数体里引用模块级变量 —— Formality 会对
  // "task/function 里用非局部变量"报 FMR_VLOG-091，而这条是**不可抑制**的，
  // 直接让 set_top 失败（本轮实测 FM-262 → FM-156）。
  function automatic logic [HIST_LEN-1:0] get_hist(logic [HIST_LEN-1:0] ghv, cgh_ptr_t ptr);
    return HIST_LEN'({ghv, ghv} >> (ptr.value + 1'b1));
  endfunction

  for (genvar n = 0; n < HIST_LEN; n++) begin : g_ghv
    assign ghv_wen[n]   = s1_ghv_wen[n] | s2_ghv_wen[n] | s3_ghv_wen[n] | rdr_ghv_wen[n];
    // 优先级 redirect > s3 > s2 > s1（与 S0 选择器同一套，见文件头的"坑"一节）
    assign ghv_wdata[n] = rdr_ghv_wen[n] ? rdr_ghv_wdata[n]
                        : s3_ghv_wen[n]  ? s3_ghv_wdata[n]
                        : s2_ghv_wen[n]  ? s2_ghv_wdata[n]
                        : s1_ghv_wen[n]  ? s1_ghv_wdata[n]
                                         : rdr_ghv_wdata[n];  // 无人写时兜底(同 golden)
    always_ff @(posedge clock or posedge reset) begin
      if (reset)        ghv_q[n] <= 1'b0;
      else if (ghv_wen[n]) ghv_q[n] <= ghv_wdata[n];
    end
  end

  // ===========================================================================
  // AFHOB_ —— 折叠历史的"最老位"预读
  //
  // 增量更新折叠历史时，要把**即将退出窗口的那一位**从折叠值里 XOR 掉。这一位在
  // GHV 上的下标是 ptr+LEN（往回数第 LEN 位）。一次最多进 2 条分支，所以每个 LEN
  // 要预读 4 位：ptr+LEN、ptr+LEN-1、ptr+LEN-2、ptr+LEN-3。
  // 6 个不同的 LEN 共 6 组，各 4 位。
  // ===========================================================================
  function automatic afhob_t afhob_read(logic [HIST_LEN-1:0] ghv, cgh_ptr_t ptr);
    afhob_t r;
    for (int g = 0; g < NUM_AFHOB; g++)
      for (int i = 0; i < NUM_BR*2; i++)
        r[g][i] = ghv[HIST_PTR_BITS'(ptr.value + HIST_PTR_BITS'(AFHOB_LEN[g] - i))];
    return r;
  endfunction

  // getRealOb：AFHOB 存的是"往回 0..3 位"，到底取哪两位取决于**上一个取指块进了几条
  // 分支**(last_br_num_oh，one-hot：没进/进1条/进2条)。进得越多，窗口滑得越远。
  function automatic logic [NUM_BR-1:0] afhob_real_ob(afhob_word_t bits,
                                                      logic [NUM_BR:0] br_num_oh);
    logic [NUM_BR-1:0] ob;
    for (int i = 0; i < NUM_BR; i++)
      ob[i] = (br_num_oh[0] & bits[i]) | (br_num_oh[1] & bits[i+1]) | (br_num_oh[2] & bits[i+2]);
    return ob;
  endfunction

  // ===========================================================================
  // FH_ —— 折叠历史的增量更新
  //
  // 一份折叠历史 = LEN 位原始历史按 CLEN 位分段 XOR 的结果。加入 num 条新分支时：
  //   1) 把**退出窗口**的 num 个最老位，在它们当初落进的位置 (LEN-1-i)%CLEN 再 XOR
  //      一次消掉 —— 只有真的绕回过的位才需要(否则它从没被折叠进来)；
  //   2) 把**新进来**的方向位 XOR 到高位 CLEN-1-i；
  //   3) 整体循环左移 num 位。
  // LEN<=CLEN 时根本不绕回，退化成普通左移。
  // ===========================================================================
  for (genvar h = 1; h <= NUM_FH; h++) begin : g_fh_def
    localparam int unsigned LEN     = FH_LEN[h];
    localparam int unsigned CLEN    = FH_CLEN[h];
    localparam bit          NEED_OB = (LEN > CLEN);
    localparam bit          WRAP0   = NEED_OB && (((LEN-1)/CLEN) > 0);
    localparam bit          WRAP1   = NEED_OB && (((LEN-2)/CLEN) > 0);
    localparam int unsigned POS0    = NEED_OB ? ((LEN-1) % CLEN) : 0;
    localparam int unsigned POS1    = NEED_OB ? ((LEN-2) % CLEN) : 0;

    function automatic fh_word_t update(fh_word_t cur, logic [NUM_BR-1:0] ob,
                                        int unsigned num, logic taken);
      logic [CLEN-1:0] x, sh;
      logic [2*CLEN-1:0] dbl;
      if (!NEED_OB) begin
        // 窗口比折叠宽度还短：没有位需要退出，直接左移进新方向
        x = CLEN'((CLEN'(cur) << num) | CLEN'(taken));
        return fh_word_t'(x);
      end
      // 1) 原值；num 大到把某些位整段推出去时那些位不参与（只有 LEN<=CLEN+1 才可能）
      for (int j = 0; j < CLEN; j++)
        x[j] = cur[j] & ~(num >= (LEN - j));
      // 2) 消掉退出窗口的最老位（i<num 才真的退出）
      if (WRAP0) x[POS0] = x[POS0] ^ (ob[0] & (0 < num));
      if (WRAP1) x[POS1] = x[POS1] ^ (ob[1] & (1 < num));
      // 3) 新方向位进高位；一次最多一条分支是 taken，所以只有第 num 条可能为 1
      for (int i = 0; i < NUM_BR; i++)
        if (taken && ((i + 1) == num)) x[CLEN-1-i] = x[CLEN-1-i] ^ 1'b1;
      // 4) 循环左移 num
      dbl = {x, x};
      sh  = CLEN'(dbl >> (CLEN - num));
      return fh_word_t'(sh);
    endfunction
  end

  // 把一整份 17 路折叠历史按 num 条分支更新（快路：用预读好的 AFHOB）
  function automatic folded_hist_t fh_update_all(folded_hist_t cur, afhob_t afh,
                                                 logic [NUM_BR:0] br_num_oh,
                                                 int unsigned num, logic taken);
    folded_hist_t r;
    r[ 1] = g_fh_def[ 1].update(cur[ 1], afhob_real_ob(afh[1], br_num_oh), num, taken);
    r[ 2] = g_fh_def[ 2].update(cur[ 2], afhob_real_ob(afh[3], br_num_oh), num, taken);
    r[ 3] = g_fh_def[ 3].update(cur[ 3], afhob_real_ob(afh[2], br_num_oh), num, taken);
    r[ 4] = g_fh_def[ 4].update(cur[ 4], afhob_real_ob(afh[1], br_num_oh), num, taken);
    r[ 5] = g_fh_def[ 5].update(cur[ 5], afhob_real_ob(afh[5], br_num_oh), num, taken);
    r[ 6] = g_fh_def[ 6].update(cur[ 6], afhob_real_ob(afh[3], br_num_oh), num, taken);
    r[ 7] = g_fh_def[ 7].update(cur[ 7], afhob_real_ob(afh[4], br_num_oh), num, taken);
    r[ 8] = g_fh_def[ 8].update(cur[ 8], afhob_real_ob(afh[5], br_num_oh), num, taken);
    r[ 9] = g_fh_def[ 9].update(cur[ 9], afhob_real_ob(afh[2], br_num_oh), num, taken);
    r[10] = g_fh_def[10].update(cur[10], afhob_real_ob(afh[2], br_num_oh), num, taken);
    r[11] = g_fh_def[11].update(cur[11], afhob_real_ob(afh[0], br_num_oh), num, taken);
    r[12] = g_fh_def[12].update(cur[12], '0,                               num, taken);
    r[13] = g_fh_def[13].update(cur[13], afhob_real_ob(afh[1], br_num_oh), num, taken);
    r[14] = g_fh_def[14].update(cur[14], '0,                               num, taken);
    r[15] = g_fh_def[15].update(cur[15], afhob_real_ob(afh[1], br_num_oh), num, taken);
    r[16] = g_fh_def[16].update(cur[16], afhob_real_ob(afh[5], br_num_oh), num, taken);
    r[17] = g_fh_def[17].update(cur[17], afhob_real_ob(afh[2], br_num_oh), num, taken);
    return r;
  endfunction

  // ===========================================================================
  // GHVWR_ —— 把"某一级要往 GHV 写什么"算成 256 位的 wen/wdata
  //
  // 第 b 条分支写的是环上 ptr-b 那一格。把 ptr 的 one-hot 循环右移 b 位，就得到
  // "第 b 条分支写哪一位"的 256 位 one-hot；两条分支或起来就是整级的 wen。
  // ===========================================================================
  typedef struct packed { logic [HIST_LEN-1:0] wen; logic [HIST_LEN-1:0] wdata; } ghv_wr_t;

  function automatic logic [HIST_LEN-1:0] ptr_onehot_rot(cgh_ptr_t ptr, int unsigned b);
    logic [HIST_LEN-1:0] oh;
    oh = HIST_LEN'(1) << ptr.value;
    return HIST_LEN'({oh, oh} >> b);            // 第 n 位为 1 ⟺ ptr == n + b
  endfunction

  function automatic ghv_wr_t ghv_write_of(cgh_ptr_t ptr, logic [NUM_BR-1:0] should_shift,
                                           logic [NUM_BR-1:0] dir, logic gate);
    ghv_wr_t r;
    logic [HIST_LEN-1:0] sel0, sel1;
    sel0 = ptr_onehot_rot(ptr, 0) & {HIST_LEN{should_shift[0]}};
    sel1 = ptr_onehot_rot(ptr, 1) & {HIST_LEN{should_shift[1]}};
    r.wen   = (sel0 | sel1) & {HIST_LEN{gate}};
    r.wdata = (sel0 & {HIST_LEN{dir[0]}}) | (sel1 & {HIST_LEN{dir[1]}});
    return r;
  endfunction

  // ===========================================================================
  // STAGE_ —— S1/S2/S3 的历史状态流水
  //
  // 每一级都随 pc 一起，把当拍用到的历史快照往下带一级：历史指针、17 路折叠历史、
  // 最老位 AFHOB、上一块进了几条分支(last_br_num_oh)。为什么要带？因为覆盖发生时
  // 要**回滚到那一级看到的历史**再重算，而不是回滚到"现在"。
  //
  // 扇出复制的实况（与 golden 逐一对齐，不多建也不少建）：
  //   · pc / ghist_ptr      —— 4 份都在（Composer 四个 dup 都要）
  //   · folded_gh / afhob / last_br_num_oh —— **只有 dup1 和 dup3**，其余两份在
  //     golden 里已被 firtool 消掉（Composer 只消费 folded_hist_1 / _3）。
  //     这几份彼此并不相同：它们的选择器用各自 dup 的 s2_redirect/s3_redirect。
  // ===========================================================================
  localparam int unsigned FH_DUP [0:1] = '{1, 3};   // 活着的 folded/afhob/brnum dup 下标

  // ---- S0 保持寄存器（stall 时保持） ----
  vaddr_t       s0_pc_reg        [0:NUM_DUP-1];
  cgh_ptr_t     s0_ghist_ptr_reg [0:NUM_DUP-1];
  folded_hist_t s0_folded_gh_reg [0:1];
  afhob_t       s0_afhob_reg     [0:1];
  logic [NUM_BR:0] s0_brnum_reg   [0:1];

  // ---- S1/S2/S3 流水寄存器 ----
  cgh_ptr_t     s1_ghist_ptr [0:NUM_DUP-1], s2_ghist_ptr [0:NUM_DUP-1], s3_ghist_ptr [0:NUM_DUP-1];
  folded_hist_t s1_folded_gh [0:1], s2_folded_gh [0:1], s3_folded_gh [0:1];
  afhob_t       s1_afhob [0:1], s2_afhob [0:1], s3_afhob [0:1];
  logic [NUM_BR:0] s1_brnum [0:1], s2_brnum [0:1], s3_brnum [0:1];

  // S0 选择器的输出（组合）
  vaddr_t       s0_pc_next        [0:NUM_DUP-1];
  cgh_ptr_t     s0_ghist_ptr_next [0:NUM_DUP-1];
  folded_hist_t s0_folded_gh_next [0:1];
  afhob_t       s0_afhob_next     [0:1];
  logic [NUM_BR:0] s0_brnum_next   [0:1];

  // 各级算出的"预测之后历史会变成什么"
  cgh_ptr_t     s1_pred_ptr [0:NUM_DUP-1], s2_pred_ptr [0:NUM_DUP-1], s3_pred_ptr [0:NUM_DUP-1];
  folded_hist_t s1_pred_fh [0:1], s2_pred_fh [0:1], s3_pred_fh [0:1];
  afhob_t       s1_ob_src [0:1], s2_ob_src [0:1], s3_ob_src [0:1];
  logic [NUM_BR:0] s1_brpos [0:NUM_DUP-1], s2_brpos [0:NUM_DUP-1], s3_brpos [0:NUM_DUP-1];

  // 历史指针按"本块进了几条分支"后退：Mux1H(lastBrPosOH, {ptr, ptr-1, ptr-2})
  function automatic cgh_ptr_t ptr_advance(cgh_ptr_t p, logic [NUM_BR:0] oh);
    cgh_ptr_t r;
    logic [HIST_PTR_BITS:0] m0, m1, m2;
    m0 = {p.flag, p.value};
    m1 = m0 - 1'b1;
    m2 = m0 - 2'd2;
    {r.flag, r.value} = ({(HIST_PTR_BITS+1){oh[0]}} & m0)
                      | ({(HIST_PTR_BITS+1){oh[1]}} & m1)
                      | ({(HIST_PTR_BITS+1){oh[2]}} & m2);
    return r;
  endfunction

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_brpos
    assign s1_brpos[d]    = d_s1[d].last_br_pos_oh;
    assign s2_brpos[d]    = d_s2[d].last_br_pos_oh;
    assign s3_brpos[d]    = d_s3[d].last_br_pos_oh;
    assign s1_pred_ptr[d] = ptr_advance(s1_ghist_ptr[d], s1_brpos[d]);
    assign s2_pred_ptr[d] = ptr_advance(s2_ghist_ptr[d], s2_brpos[d]);
    assign s3_pred_ptr[d] = ptr_advance(s3_ghist_ptr[d], s3_brpos[d]);
  end

  // 折叠历史的预测值：对"进 0/1/2 条分支"各算一版，再按 lastBrPosOH 选
  //   · S1 的方向位用 brTaken & lastBrPosOH[i]（uFTB 只给"这块跳没跳"）
  //   · S2/S3 用 br_taken_mask[i-1]（已经有逐条分支的方向）
  for (genvar k = 0; k < 2; k++) begin : g_fh_pred
    localparam int unsigned D = FH_DUP[k];
    folded_hist_t c1 [0:NUM_BR], c2 [0:NUM_BR], c3 [0:NUM_BR];
    for (genvar i = 0; i <= NUM_BR; i++) begin : g_cand
      // S1 只知道"这块跳没跳"(brTaken)，方向位靠 lastBrPosOH 定位到具体是第几条
      assign c1[i] = fh_update_all(s1_folded_gh[k], s1_afhob[k], s1_brnum[k], i,
                                   d_s1[D].br_taken & s1_brpos[D][i]);
      // S2/S3 已有逐条分支方向：进 i 条时，方向位取第 i 条(i=0 表示没进分支)
      if (i == 0) begin : g_none
        assign c2[i] = fh_update_all(s2_folded_gh[k], s2_afhob[k], s2_brnum[k], i, 1'b0);
        assign c3[i] = fh_update_all(s3_folded_gh[k], s3_afhob[k], s3_brnum[k], i, 1'b0);
      end else begin : g_some
        assign c2[i] = fh_update_all(s2_folded_gh[k], s2_afhob[k], s2_brnum[k], i,
                                     s2_pred[D].br_taken_mask[i-1]);
        assign c3[i] = fh_update_all(s3_folded_gh[k], s3_afhob[k], s3_brnum[k], i,
                                     s3_pred[D].br_taken_mask[i-1]);
      end
    end
    assign s1_pred_fh[k] = ({$bits(folded_hist_t){s1_brpos[D][0]}} & c1[0])
                         | ({$bits(folded_hist_t){s1_brpos[D][1]}} & c1[1])
                         | ({$bits(folded_hist_t){s1_brpos[D][2]}} & c1[2]);
    assign s2_pred_fh[k] = ({$bits(folded_hist_t){s2_brpos[D][0]}} & c2[0])
                         | ({$bits(folded_hist_t){s2_brpos[D][1]}} & c2[1])
                         | ({$bits(folded_hist_t){s2_brpos[D][2]}} & c2[2]);
    assign s3_pred_fh[k] = ({$bits(folded_hist_t){s3_brpos[D][0]}} & c3[0])
                         | ({$bits(folded_hist_t){s3_brpos[D][1]}} & c3[1])
                         | ({$bits(folded_hist_t){s3_brpos[D][2]}} & c3[2]);
    assign s1_ob_src[k]  = afhob_read(ghv_q, s1_ghist_ptr[D]);
    assign s2_ob_src[k]  = afhob_read(ghv_q, s2_ghist_ptr[D]);
    assign s3_ob_src[k]  = afhob_read(ghv_q, s3_ghist_ptr[D]);
  end

  // ===========================================================================
  // OVR_ —— 级间覆盖判定（S2 覆盖 S1，S3 覆盖 S2）
  //
  // 后一级比前一级准。每一级把自己的结论和**上一拍前一级的结论**比，不一致就发
  // override：把已经按旧结论走的取指流冲掉，并让 S0 从新目标重来。
  // ===========================================================================

  // S2 与上一拍 S1 比四项：目标、最后分支位置、跳/不跳、跳转指令位置。
  // 先把**所有候选目标**都和上一拍的目标比一遍，再按上一拍自己的 taken/hit 去选
  // 该信哪一个 —— 目标比 taken 早出来，这样选择不在关键路径上（golden 的时序优化）。
  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s2_ovr
    logic [3:0] dvec;
    logic       tgt_diff, pos_diff, tk_diff, off_diff;
    for (genvar i = 0; i < 4; i++)
      assign dvec[i] = (all_target_of(s2_pred[d], s2_pc[d], i) != prev_s1[d].target);
    // 同样写成 Mux1H，理由见 target_sel 的注释（别用带兜底的优先级链）
    logic [3:0] tsel;
    assign tsel[0] =   prev_s1[d].taken_mask[0]                              & prev_s1[d].hit;
    assign tsel[1] =  ~prev_s1[d].taken_mask[0] & prev_s1[d].taken_mask[1]   & prev_s1[d].hit;
    assign tsel[2] =  ~(|prev_s1[d].taken_mask)                              & prev_s1[d].hit;
    assign tsel[3] =  ~prev_s1[d].hit;
    assign tgt_diff = |(tsel & dvec);
    assign pos_diff = (prev_s1[d].last_br_pos_oh != d_s2[d].last_br_pos_oh);
    assign tk_diff  = (prev_s1[d].taken          != d_s2[d].cfi_valid);
    assign off_diff = prev_s1[d].taken & d_s2[d].cfi_valid
                    & (prev_s1[d].cfi_index != d_s2[d].cfi_index);
    assign s2_redirect[d] = s2_fire_w & (tgt_diff | pos_diff | tk_diff | off_diff);
  end

  // 上一拍 S2 的结论。golden 在这里做了时钟门控优化：targets 只在"该槽要跳"时才打拍，
  // fallThroughAddr 只在"命中且槽0不跳"时才打拍 —— 省翻转，但寄存器本身照建。
  for (genvar d = 0; d < NUM_DUP; d++) begin : g_s3_ovr
    logic br_taken_diff, both_first_taken, target_diff;
    assign br_taken_diff    = (d_s3[d].real_br_taken != d_ps2[d].real_br_taken);
    assign both_first_taken = d_s3[d].real_br_taken[0] & d_ps2[d].real_br_taken[0];
    assign target_diff      = (tgt_s3[d] != tgt_ps2[d]);
    // 两边都是"第一条分支跳"时方向差异不算覆盖（目标比较会兜住）
    assign s3_redirect[d] = s3_fire_w & ((br_taken_diff & ~both_first_taken)
                                         | target_diff
                                         | (s3_pred[d].hit & s3_pred[d].fall_through_err)
                                         | (s3_pred[d].hit & s3_pred[d].multi_hit));
  end

  // ===========================================================================
  // RDR_ —— FTQ 真重定向：锁存一拍，然后把历史整体回滚重算
  //
  // 后端/IFU 发现预测错了会送 redirect，带着"错在哪条分支(shift)、方向是什么(taken)、
  // 当时的历史指针(hist_ptr)"。本模块据此把 GHV 指针退回、折叠历史按当时的 GHV 重算。
  // 注意这里用的是**慢路**：直接从 GHV 现读最老位，而不是用预读好的 AFHOB ——
  // 因为重定向点的历史指针是任意的，没有预读过。
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) do_redirect_valid <= 1'b0;
    else       do_redirect_valid <= ftq_redirect_valid;
  end
  // 包体不带复位（valid 为 0 时没人看它）
  always_ff @(posedge clock) begin
    if (ftq_redirect_valid) do_redirect_bits <= redirect_in;
  end

  logic redirect_from_ifu_r;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) redirect_from_ifu_r <= 1'b0;
    else       redirect_from_ifu_r <= ftq_redirect_from_ifu;
  end
  assign redirect_from_ifu_q = redirect_from_ifu_r;

  // shift 条分支要进历史 → 低 shift 位为 1 的掩码
  logic [NUM_BR-1:0] rdr_should_shift, rdr_real_br_taken;
  cgh_ptr_t          rdr_old_ptr, rdr_updated_ptr;
  logic [NUM_BR:0]   rdr_this_br_num_oh;

  assign rdr_should_shift   = (do_redirect_bits.shift == 2'd0) ? 2'b00
                            : (do_redirect_bits.shift == 2'd1) ? 2'b01 : 2'b11;
  for (genvar b = 0; b < NUM_BR; b++)
    assign rdr_real_br_taken[b] = (do_redirect_bits.shift == 2'(b+1))
                                & do_redirect_bits.taken & do_redirect_bits.add_into_hist;
  assign rdr_old_ptr        = do_redirect_bits.hist_ptr;
  assign {rdr_updated_ptr.flag, rdr_updated_ptr.value} =
           {rdr_old_ptr.flag, rdr_old_ptr.value} - {1'b0, do_redirect_bits.shift};
  assign rdr_this_br_num_oh = 3'(1) << do_redirect_bits.shift;

  // 重定向点的折叠历史：**按当时的原始历史整段重算**（不是增量），再补上这次的分支
  function automatic folded_hist_t fh_recompute(logic [HIST_LEN-1:0] hist);
    folded_hist_t r;
    for (int h = 1; h <= NUM_FH; h++) begin
      automatic logic [FH_MAX_W-1:0] acc = '0;
      for (int j = 0; j < FH_LEN[h]; j++)
        acc[j % FH_CLEN[h]] = acc[j % FH_CLEN[h]] ^ hist[j];
      r[h] = acc;
    end
    return r;
  endfunction

  // 慢路最老位：重定向指针处直接读 GHV
  function automatic afhob_t afhob_slow(logic [HIST_LEN-1:0] ghv, cgh_ptr_t ptr);
    return afhob_read(ghv, ptr);
  endfunction

  folded_hist_t rdr_old_fh, rdr_updated_fh;
  // 4 项而不是 3 项：shift 是 2 位，合法值只有 0/1/2，但硬件上还能取到 3。
  // golden 的四选一把越界的第 3 项**填成第 0 项**（Chisel Vec 越界读的 firtool 展开），
  // 这里照抄 —— 既消掉 FM 的数组越界告警(FMR_ELAB-147)，也保证 shift=3 时同值。
  folded_hist_t rdr_fh_cand [0:3];
  afhob_t       rdr_ahead_ob;

  assign rdr_old_fh   = fh_recompute(get_hist(ghv_q, rdr_old_ptr));
  assign rdr_ahead_ob = afhob_slow(ghv_q, rdr_old_ptr);
  for (genvar i = 0; i <= NUM_BR; i++) begin : g_rdr_fh
    // 慢路：ob 直接取 GHV 上 ptr+LEN / ptr+LEN-1（不经 lastBrNumOH 选择）
    assign rdr_fh_cand[i] = fh_update_all(rdr_old_fh, rdr_ahead_ob, 3'b001, i,
                                          do_redirect_bits.taken & do_redirect_bits.add_into_hist);
  end
  assign rdr_fh_cand[3] = rdr_fh_cand[0];          // 越界项，与 golden 同
  assign rdr_updated_fh = rdr_fh_cand[do_redirect_bits.shift];

  // ===========================================================================
  // SEL_ —— S0 五选一（见文件头的优先级表）
  //
  // golden 把这套选择器实例化成 PriorityMuxModule 家族：npc 用 PriorityMuxModule、
  // 折叠历史用 _4、历史指针用 _8、AFHOB 用 _12、最后分支位置用 _16，
  // 每位 GHV 用 _20（共 256 个实例）。它们全是纯组合、零寄存器，所以这里直接写成
  // 优先级链，语义完全一致，而 256 个实例塌缩成 GHV_ 节里的 4 行。
  // ===========================================================================
  for (genvar d = 0; d < NUM_DUP; d++) begin : g_sel_pc
    assign s0_pc_next[d]        = do_redirect_valid ? do_redirect_bits.target
                                : s3_redirect[d]    ? tgt_s3[d]
                                : s2_redirect[d]    ? tgt_s2[d]
                                : s1_valid_q        ? tgt_s1[d]
                                                    : s0_pc_reg[d];
    assign s0_ghist_ptr_next[d] = do_redirect_valid ? rdr_updated_ptr
                                : s3_redirect[d]    ? s3_pred_ptr[d]
                                : s2_redirect[d]    ? s2_pred_ptr[d]
                                : s1_valid_q        ? s1_pred_ptr[d]
                                                    : s0_ghist_ptr_reg[d];
    assign s0_pc_sel[d]      = s0_pc_next[d];
    assign s0_ghist_ptr[d]   = s0_ghist_ptr_next[d];
  end

  for (genvar k = 0; k < 2; k++) begin : g_sel_fh
    localparam int unsigned D = FH_DUP[k];
    assign s0_folded_gh_next[k] = do_redirect_valid ? rdr_updated_fh
                                : s3_redirect[D]    ? s3_pred_fh[k]
                                : s2_redirect[D]    ? s2_pred_fh[k]
                                : s1_valid_q        ? s1_pred_fh[k]
                                                    : s0_folded_gh_reg[k];
    assign s0_afhob_next[k]     = do_redirect_valid ? rdr_ahead_ob
                                : s3_redirect[D]    ? s3_ob_src[k]
                                : s2_redirect[D]    ? s2_ob_src[k]
                                : s1_valid_q        ? s1_ob_src[k]
                                                    : s0_afhob_reg[k];
    assign s0_brnum_next[k]     = do_redirect_valid ? rdr_this_br_num_oh
                                : s3_redirect[D]    ? s3_brpos[D]
                                : s2_redirect[D]    ? s2_brpos[D]
                                : s1_valid_q        ? s1_brpos[D]
                                                    : s0_brnum_reg[k];
  end

  // ===========================================================================
  // 流水寄存器本体
  //   S0 保持寄存器：!s0_stall 时吃新值；复位脉冲那拍装复位向量
  //   S1/S2/S3：分别由 s0_fire/s1_fire/s2_fire 打拍（注意 golden 里除 pc 外
  //             统一用 dup1 的 fire 作使能，这里照抄）
  // ===========================================================================
  // s0_pc_reg 是全模块唯一**不带复位**的流水寄存器（golden 同）：它靠 modified_reset
  // 那一拍脉冲装复位向量，而不是靠复位端。
  always_ff @(posedge clock) begin
    for (int d = 0; d < NUM_DUP; d++) begin
      if (modified_reset) s0_pc_reg[d] <= vaddr_t'(io_reset_vector);
      else if (~s0_stall[d]) s0_pc_reg[d] <= s0_pc_next[d];
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int d = 0; d < NUM_DUP; d++) begin
        s0_ghist_ptr_reg[d] <= '0;
        s1_ghist_ptr[d]     <= '0;
        s2_ghist_ptr[d]     <= '0;
        s3_ghist_ptr[d]     <= '0;
      end
      for (int k = 0; k < 2; k++) begin
        s0_folded_gh_reg[k] <= '0; s1_folded_gh[k] <= '0;
        s2_folded_gh[k]     <= '0; s3_folded_gh[k] <= '0;
        s0_afhob_reg[k]     <= '0; s1_afhob[k]     <= '0;
        s2_afhob[k]         <= '0; s3_afhob[k]     <= '0;
        s0_brnum_reg[k]     <= '0; s1_brnum[k]     <= '0;
        s2_brnum[k]         <= '0; s3_brnum[k]     <= '0;
      end
    end else begin
      for (int d = 0; d < NUM_DUP; d++) begin
        if (~s0_stall[d])  s0_ghist_ptr_reg[d] <= s0_ghist_ptr_next[d];
        if (s0_fire_w)  s1_ghist_ptr[d]     <= s0_ghist_ptr_next[d];
        if (s1_fire_w)  s2_ghist_ptr[d]     <= s1_ghist_ptr[d];
        if (s2_fire_w)  s3_ghist_ptr[d]     <= s2_ghist_ptr[d];
      end
      for (int k = 0; k < 2; k++) begin
        // 这三组只活 dup1/dup3（FH_DUP），所以使能取**它自己那份** dup 的 s0_stall：
        // golden 里 s0_folded_gh_reg_dup_1 由 _s0_stall_dup_1_T_2 门控（:24132）、
        // dup_3 由 _s0_stall_dup_3_T_2 门控（:24217）。取 dup0 是错的。
        if (~s0_stall[FH_DUP[k]]) begin
          s0_folded_gh_reg[k] <= s0_folded_gh_next[k];
          s0_afhob_reg[k]     <= s0_afhob_next[k];
          s0_brnum_reg[k]     <= s0_brnum_next[k];
        end
        if (s0_fire_w) begin
          s1_folded_gh[k] <= s0_folded_gh_next[k];
          s1_afhob[k]     <= s0_afhob_next[k];
          s1_brnum[k]     <= s0_brnum_next[k];
        end
        if (s1_fire_w) begin
          s2_folded_gh[k] <= s1_folded_gh[k];
          s2_afhob[k]     <= s1_afhob[k];
          s2_brnum[k]     <= s1_brnum[k];
        end
        if (s2_fire_w) begin
          s3_folded_gh[k] <= s2_folded_gh[k];
          s3_afhob[k]     <= s2_afhob[k];
          s3_brnum[k]     <= s2_brnum[k];
        end
      end
    end
  end

  // 上一拍 S1 / S2 结论的锁存
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int d = 0; d < NUM_DUP; d++) prev_s1[d] <= '0;
    end else if (s1_fire_w) begin
      for (int d = 0; d < NUM_DUP; d++) begin
        prev_s1[d].hit            <= s1_pred[d].hit;
        prev_s1[d].target         <= tgt_s1[d];
        prev_s1[d].last_br_pos_oh <= d_s1[d].last_br_pos_oh;
        prev_s1[d].taken          <= d_s1[d].cfi_valid;
        prev_s1[d].taken_mask     <= d_s1[d].taken_on_slot;
        prev_s1[d].cfi_index      <= d_s1[d].cfi_index;
      end
    end
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int d = 0; d < NUM_DUP; d++) begin prev_s2[d] <= '0; prev_s2_pc[d] <= '0; end
    end else begin
      for (int d = 0; d < NUM_DUP; d++) begin
        if (s2_fire_w) begin
          prev_s2_pc[d]                 <= s2_pc[d];
          prev_s2[d].br_taken_mask      <= s2_pred[d].br_taken_mask;
          prev_s2[d].slot_valids        <= s2_pred[d].slot_valids;
          prev_s2[d].jalr_target        <= s2_pred[d].jalr_target;
          prev_s2[d].offsets            <= s2_pred[d].offsets;
          prev_s2[d].fall_through_err   <= s2_pred[d].fall_through_err;
          prev_s2[d].multi_hit          <= s2_pred[d].multi_hit;
          prev_s2[d].is_br_sharing      <= s2_pred[d].is_br_sharing;
          prev_s2[d].hit                <= s2_pred[d].hit;
        end
        // 时钟门控优化：目标只在该槽真的要跳时才打拍
        for (int s = 0; s < TOTAL_SLOT; s++)
          if (s2_fire_w & d_s2[d].taken_on_slot[s])
            prev_s2[d].targets[s] <= s2_pred[d].targets[s];
        // 落空地址只在"命中且槽0不跳"时才打拍（用 dup0 的条件，golden 如此）
        if (s2_fire_w & s2_pred[0].hit & ~d_s2[0].taken_on_slot[0])
          prev_s2[d].fall_through_addr <= s2_pred[d].fall_through_addr;
      end
    end
  end

  // ===========================================================================
  // GHV 写：四个源各自算 wen/wdata（优先级在 GHV_ 节合并）
  // ===========================================================================
  ghv_wr_t s1_wr, s2_wr, s3_wr, rdr_wr;
  assign s1_wr = ghv_write_of(s1_ghist_ptr[0], d_s1[0].should_shift,
                              {d_s1[0].br_taken & s1_brpos[0][2],
                               d_s1[0].br_taken & s1_brpos[0][1]}, s1_valid_q);
  assign s2_wr = ghv_write_of(s2_ghist_ptr[0], d_s2[0].should_shift,
                              d_s2[0].real_br_taken, s2_redirect[0]);
  assign s3_wr = ghv_write_of(s3_ghist_ptr[0], d_s3[0].should_shift,
                              d_s3[0].real_br_taken, s3_redirect[0]);
  assign rdr_wr = ghv_write_of(rdr_old_ptr, rdr_should_shift, rdr_real_br_taken, do_redirect_valid);
  assign {s1_ghv_wen, s1_ghv_wdata} = s1_wr;
  assign {s2_ghv_wen, s2_ghv_wdata} = s2_wr;
  assign {s3_ghv_wen, s3_ghv_wdata} = s3_wr;
  assign {rdr_ghv_wen, rdr_ghv_wdata} = rdr_wr;

  // ===========================================================================
  // GHIST_ —— 送 Composer 的"推测历史"
  //
  // Composer 要的是"如果本级预测成立，历史会变成什么样"。取预测之后的指针处历史，
  // 再把最低 numBr 位按本块的分支方向改写（只有第 0 条分支可能是 taken）。
  // 四个源同样按优先级覆盖（真重定向最优先）。
  // ===========================================================================
  function automatic logic [HIST_LEN-1:0] patch_low(logic [HIST_LEN-1:0] h,
                                                    logic [NUM_BR-1:0] shift_mask, logic taken);
    logic [HIST_LEN-1:0] r;
    r = h;
    for (int i = 0; i < NUM_BR; i++)
      if (shift_mask[i]) r[i] = taken & (i == 0);
    return r;
  endfunction

  assign s0_ghist =
      do_redirect_valid ? patch_low(get_hist(ghv_q, rdr_updated_ptr), rdr_should_shift,
                                    do_redirect_bits.taken & do_redirect_bits.add_into_hist)
    : s3_redirect[0]    ? patch_low(get_hist(ghv_q, s3_pred_ptr[0]), d_s3[0].should_shift, d_s3[0].br_taken)
    : s2_redirect[0]    ? patch_low(get_hist(ghv_q, s2_pred_ptr[0]), d_s2[0].should_shift, d_s2[0].br_taken)
    : s1_valid_q        ? patch_low(get_hist(ghv_q, s1_pred_ptr[0]), d_s1[0].should_shift, d_s1[0].br_taken)
    // 兜底不是 0：BPU.scala 在 when 链之前有一句 `s0_ghist := getHist(s0_ghist_ptr_dup(0))`，
    // 即四个源都不动时，送出去的是**S0 选择器选出的那个指针**处的当前历史。
                        : get_hist(ghv_q, s0_ghist_ptr_next[0]);

  assign update_ghist = get_hist(ghv_q, ftq_update_hist_ptr);

  // ===========================================================================
  // 送 FTQ 的控制输出
  // ===========================================================================
  logic                    s2_fi_flag, s3_fi_flag;
  logic [FTQ_PTR_BITS-1:0] s2_fi_value, s3_fi_value;
  // golden 这 4 个也不带复位（复位后第一次 s1_fire 就会装进正确的 ftqIdx）
  always_ff @(posedge clock) begin
    if (s1_fire_w) begin s2_fi_flag <= ftq_enq_ptr_flag; s2_fi_value <= ftq_enq_ptr_value; end
    if (s2_fire_w) begin s3_fi_flag <= s2_fi_flag;       s3_fi_value <= s2_fi_value;       end
  end
  assign s2_ftq_idx_flag  = s2_fi_flag;
  assign s2_ftq_idx_value = s2_fi_value;
  assign s3_ftq_idx_flag  = s3_fi_flag;
  assign s3_ftq_idx_value = s3_fi_value;

  // ★这里的 dup 下标必须是 3，不是 0★：golden 是
  //     assign io_bpu_to_ftq_resp_bits_s2_valid_3 = s2_valid_dup_3 & ~s2_flush_dup_3;
  //     (Predictor.sv:44814, 而 s2_flush_dup_3 = redirect | s3_redirect_dup_3)
  // s2_flush 是**每份 dup 各不相同**的（它含各自 dup 的 s3_redirect），拿 dup0 去
  // 门 dup3 的输出，在本 UT 里看不出来——Composer 的四份 dup 输出恒等，四个
  // s3_redirect 也就恒等——但对 FM 来说这四根是独立输入锥，是真差异。
  assign to_ftq_s2_valid = s2_fire_w & ~s2_flush[3];
  assign to_ftq_s3_valid = s3_fire_w & ~s3_flush;
  assign s3_ghist_ptr_o  = s3_ghist_ptr[2];

  // FTQ 什么时候该收：S1 正常前进，或 S2/S3 发生覆盖（覆盖也要告诉 FTQ 改）
  assign bpu_resp_valid = (s1_valid_q & s2_comp_ready & s2_ready)
                        | (s2_fire_w & s2_redirect[2])
                        | (s3_fire_w & s3_redirect[2]);

  // ===========================================================================
  // TOPDOWN_ —— 取指气泡归因
  //
  // 每拍给前端记一笔"这拍为什么没能顺利出指令"。原因码随流水一起往后推(stage0→1→2)，
  // 到末级才送给 FTQ，这样气泡才能和它真正拖慢的那个取指块对上。
  // 本模块负责其中 10 个原因（枚举 id 见右侧），其余由 IFU/ICache 负责。
  // ===========================================================================
  localparam int R_OVERRIDE = 1, R_FTQ_UPD = 2, R_TAGE = 3, R_SC = 4, R_ITTAGE = 5,
                 R_RAS = 6, R_MEMVIO = 7, R_OTHER = 8, R_FTQ_FULL = 9, R_BTB = 12;

  logic [NUM_REASON-1:0] td_q [0:NUM_STAGE-1];   // 三级原因寄存器
  logic [NUM_REASON-1:0] td_d [0:NUM_STAGE-1];
  logic [NUM_REASON-1:0] td_out_now;             // 本拍直接叠加到输出上的原因

  // 重定向气泡的细分归因（全部来自锁存后的重定向包）
  logic ctrl_bubble, btb_miss_b, tage_miss_b, sc_miss_b, ittage_miss_b, ras_miss_b;
  logic memvio_bubble, other_bubble, btb_bubble, ftq_full_stall;
  assign ctrl_bubble   = do_redirect_valid & do_redirect_bits.debug_is_ctrl;
  assign btb_miss_b    = do_redirect_bits.debug_is_ctrl & ~do_redirect_bits.br_hit
                                                        & ~do_redirect_bits.jr_hit;
  assign tage_miss_b   = do_redirect_bits.debug_is_ctrl &  do_redirect_bits.br_hit
                                                        & ~do_redirect_bits.sc_hit;
  assign sc_miss_b     = do_redirect_bits.debug_is_ctrl &  do_redirect_bits.br_hit
                                                        &  do_redirect_bits.sc_hit;
  assign ittage_miss_b = do_redirect_bits.debug_is_ctrl &  do_redirect_bits.jr_hit
                                                        & ~do_redirect_bits.pd_is_ret;
  assign ras_miss_b    = do_redirect_bits.debug_is_ctrl &  do_redirect_bits.jr_hit
                                                        &  do_redirect_bits.pd_is_ret;
  assign memvio_bubble = do_redirect_valid & do_redirect_bits.debug_is_mem_vio;
  assign other_bubble  = do_redirect_valid & ~do_redirect_bits.debug_is_ctrl
                                           & ~do_redirect_bits.debug_is_mem_vio;
  assign btb_bubble    = do_redirect_valid & do_redirect_bits.btb_miss_bubble;
  assign ftq_full_stall = ~ftq_resp_ready;

  always_comb begin
    // 默认：stage0 清零，其余逐级下推
    td_d[0] = '0;
    td_d[1] = td_q[0];
    td_d[2] = td_q[1];
    td_out_now = '0;

    // 控制重定向：五选一归因（互斥，按 BTB>TAGE>SC>ITTAGE>RAS 的顺序）
    if (ctrl_bubble) begin
      if      (btb_miss_b)    begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_BTB]    = 1'b1; td_out_now[R_BTB]    = 1'b1; end
      else if (tage_miss_b)   begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_TAGE]   = 1'b1; td_out_now[R_TAGE]   = 1'b1; end
      else if (sc_miss_b)     begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_SC]     = 1'b1; td_out_now[R_SC]     = 1'b1; end
      else if (ittage_miss_b) begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_ITTAGE] = 1'b1; td_out_now[R_ITTAGE] = 1'b1; end
      else if (ras_miss_b)    begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_RAS]    = 1'b1; td_out_now[R_RAS]    = 1'b1; end
    end
    if (memvio_bubble) begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_MEMVIO] = 1'b1; td_out_now[R_MEMVIO] = 1'b1; end
    if (other_bubble)  begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_OTHER]  = 1'b1; td_out_now[R_OTHER]  = 1'b1; end
    if (btb_bubble)    begin for (int i=0;i<NUM_STAGE;i++) td_d[i][R_BTB]    = 1'b1; td_out_now[R_BTB]    = 1'b1; end

    // 覆盖气泡：S2 覆盖只怪 stage0；S3 覆盖怪 stage0 和 stage1
    if (s2_redirect[0])  td_d[0][R_OVERRIDE] = 1'b1;
    if (s3_redirect[0]) begin td_d[0][R_OVERRIDE] = 1'b1; td_d[1][R_OVERRIDE] = 1'b1; end
    // 预测器没就绪：怪对应那一级
    if (~s1_comp_ready) td_d[0][R_FTQ_UPD] = 1'b1;
    if (~s2_comp_ready) td_d[1][R_FTQ_UPD] = 1'b1;
    if (~s3_comp_ready) td_d[2][R_FTQ_UPD] = 1'b1;
    // FTQ 满：只怪 stage0
    if (ftq_full_stall) td_d[0][R_FTQ_FULL] = 1'b1;
  end

  always_ff @(posedge clock or posedge reset) begin
    if (reset) for (int i = 0; i < NUM_STAGE; i++) td_q[i] <= '0;
    else       for (int i = 0; i < NUM_STAGE; i++) td_q[i] <= td_d[i];
  end

  // 输出 = 末级寄存器 | 本拍直接归因（覆盖/FtqUpdate/FtqFull 只走寄存器路径）
  assign topdown_info_reasons = td_q[NUM_STAGE-1] | td_out_now;

  // ===========================================================================
  // 上电复位状态（golden 里只喂断言，SYNTHESIS 下无扇出，但它是真寄存器）
  // ===========================================================================
  logic power_on_reset_state;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)          power_on_reset_state <= 1'b1;
    else if (s0_fire_w) power_on_reset_state <= 1'b0;
  end

  // ===========================================================================
  // predCycle —— 打在预测包上的时间戳（供 profiling 对齐），12 个自由计数器
  //
  // golden 为 s1/s2/s3 × 4 个 dup 各建了一个 64 位自由计数器(全都同步 +1，值恒等)。
  // 只有每级 dup0 接到了输出；其余 9 个在 golden 里同样没有消费者。这里照建 12 个
  // 与 golden 逐一配对（对称死位，FM 用 verify_matched_unread_compare_points 加强证明）。
  // ===========================================================================
  logic [63:0] pred_cycle_q [0:NUM_STAGE-1][0:NUM_DUP-1];
  // 写成「if (reset) 打头」的形式：Formality 不接受异步复位块里第一条语句不是 if
  // （FMR_VLOG-144，本轮实测踩到）。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int s = 0; s < NUM_STAGE; s++)
        for (int d = 0; d < NUM_DUP; d++) pred_cycle_q[s][d] <= 64'h0;
    end else begin
      for (int s = 0; s < NUM_STAGE; s++)
        for (int d = 0; d < NUM_DUP; d++) pred_cycle_q[s][d] <= pred_cycle_q[s][d] + 64'h1;
    end
  end
  assign pred_cycle = pred_cycle_q[0][0];

  // 折叠历史送 Composer：s0 的两份 + s1 的一份（Composer 只消费 s1_folded_hist_3）
  for (genvar k = 0; k < 2; k++) begin : g_fh_out
    assign s0_folded_gh[FH_DUP[k]]      = s0_folded_gh_next[k];
    assign s0_last_br_num_oh[FH_DUP[k]] = s0_brnum_next[k];
    assign s1_folded_gh_o[FH_DUP[k]]    = s1_folded_gh[k];
  end
  // 其余两份 dup 在 golden 里已被消除，这里钉零、wrapper 不接（保持端口形状整齐）
  for (genvar k = 0; k < NUM_DUP; k++) begin : g_fh_out_dead
    if (k != 1 && k != 3) begin : g_z
      assign s0_folded_gh[k]      = '0;
      assign s0_last_br_num_oh[k] = '0;
      assign s1_folded_gh_o[k]    = '0;
    end
  end

  // ===========================================================================
  // SEGPC_ —— update pc 的分段打拍（utility.SegmentedAddrNext）
  //
  // 把 50 位 pc 切成 [49:24]/[23:12]/[11:0] 三段，**每段只在值真的变了时才打拍**。
  // 高位段变化稀疏，这样能省掉大量无谓翻转（低功耗手法）。读出时再拼回整地址。
  // 这条流水是给 Composer 的 update 口用的，Predictor 自己不看。
  // ===========================================================================
  logic [25:0] upc_seg0;
  logic [11:0] upc_seg1, upc_seg2;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      upc_seg0 <= '0; upc_seg1 <= '0; upc_seg2 <= '0;
    end else if (ftq_update_valid) begin
      if (upc_seg0 != ftq_update_pc[49:24]) upc_seg0 <= ftq_update_pc[49:24];
      if (upc_seg1 != ftq_update_pc[23:12]) upc_seg1 <= ftq_update_pc[23:12];
      if (upc_seg2 != ftq_update_pc[11:0])  upc_seg2 <= ftq_update_pc[11:0];
    end
  end
  assign update_pc_seg = {upc_seg0, upc_seg1, upc_seg2};

  // ===========================================================================
  // PERF_ —— Composer 的 7 路性能计数各打 2 拍再送出（与取指流水对齐）
  // ===========================================================================
  // golden 这 14 个寄存器**不带复位**（性能计数丢一两拍无所谓）
  logic [5:0] perf_q1 [0:6], perf_q2 [0:6];
  always_ff @(posedge clock) begin
    for (int i = 0; i < 7; i++) begin
      perf_q1[i] <= comp_perf[i];
      perf_q2[i] <= perf_q1[i];
    end
  end
  for (genvar i = 0; i < 7; i++) assign perf_out[i] = perf_q2[i];

endmodule

// =============================================================================
// Predictor —— golden 同名 wrapper
//
// 职责只有三件，全是"接线"，没有预测/流水逻辑（那些都在 xs_Predictor_core 里）：
//   1. 633 个端口与 golden 逐位同名、同宽、同序（端口表由 scripts/gen_predictor.py
//      从 golden 生成，见 GENERATED(ports)）；
//   2. 例化 Composer(五个预测器) 与 DelayN(ctrl 打一拍)，把 457 根 MBIST 扫描线
//      原样穿过去（GENERATED(composer_inst)）；
//   3. 把 Composer 吐出的散装预测字段打包成 full_pred_t 喂给核，再把核算出的
//      S0 状态/流水握手回接给 Composer。
// =============================================================================
module Predictor(
  // BEGIN GENERATED(ports)
  input          clock,
  input          reset,
  input          io_bpu_to_ftq_resp_ready,
  output         io_bpu_to_ftq_resp_valid,
  output [49:0]  io_bpu_to_ftq_resp_bits_s1_pc_3,
  output [63:0]  io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle,
  output         io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0,
  output         io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1,
  output         io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0,
  output         io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1,
  output [49:0]  io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0,
  output [49:0]  io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1,
  output [3:0]   io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0,
  output [3:0]   io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1,
  output [49:0]  io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr,
  output         io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr,
  output         io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing,
  output         io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit,
  output [49:0]  io_bpu_to_ftq_resp_bits_s2_pc_3,
  output         io_bpu_to_ftq_resp_bits_s2_valid_3,
  output         io_bpu_to_ftq_resp_bits_s2_hasRedirect_3,
  output         io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag,
  output [5:0]   io_bpu_to_ftq_resp_bits_s2_ftq_idx_value,
  output [63:0]  io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle,
  output         io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0,
  output         io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1,
  output         io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0,
  output         io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1,
  output [49:0]  io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0,
  output [49:0]  io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1,
  output [3:0]   io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0,
  output [3:0]   io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1,
  output [49:0]  io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr,
  output         io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr,
  output         io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing,
  output         io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit,
  output [49:0]  io_bpu_to_ftq_resp_bits_s3_pc_0,
  output [49:0]  io_bpu_to_ftq_resp_bits_s3_pc_3,
  output         io_bpu_to_ftq_resp_bits_s3_valid_0,
  output         io_bpu_to_ftq_resp_bits_s3_valid_3,
  output         io_bpu_to_ftq_resp_bits_s3_hasRedirect_3,
  output         io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag,
  output [5:0]   io_bpu_to_ftq_resp_bits_s3_ftq_idx_value,
  output [63:0]  io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle,
  output         io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0,
  output         io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1,
  output         io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0,
  output         io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1,
  output [49:0]  io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0,
  output [49:0]  io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1,
  output [3:0]   io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0,
  output [3:0]   io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1,
  output [49:0]  io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr,
  output         io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr,
  output         io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing,
  output         io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit,
  output [515:0] io_bpu_to_ftq_resp_bits_last_stage_meta,
  output         io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag,
  output [7:0]   io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value,
  output [3:0]   io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp,
  output [2:0]   io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr,
  output         io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag,
  output [4:0]   io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value,
  output         io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag,
  output [4:0]   io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value,
  output         io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag,
  output [4:0]   io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value,
  output [49:0]  io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr,
  output         io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0,
  output         io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid,
  output [3:0]   io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid,
  output [11:0]  io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower,
  output [1:0]   io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat,
  output [3:0]   io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid,
  output [19:0]  io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower,
  output [1:0]   io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat,
  output [3:0]   io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0,
  output         io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_1,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_2,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_3,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_4,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_5,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_6,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_7,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_8,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_9,
  output         io_bpu_to_ftq_resp_bits_topdown_info_reasons_12,
  input          io_ftq_to_bpu_redirect_valid,
  input          io_ftq_to_bpu_redirect_bits_level,
  input  [49:0]  io_ftq_to_bpu_redirect_bits_cfiUpdate_pc,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet,
  input  [3:0]   io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp,
  input  [2:0]   io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag,
  input  [4:0]   io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag,
  input  [4:0]   io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag,
  input  [4:0]   io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag,
  input  [7:0]   io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit,
  input  [49:0]  io_ftq_to_bpu_redirect_bits_cfiUpdate_target,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_taken,
  input  [1:0]   io_ftq_to_bpu_redirect_bits_cfiUpdate_shift,
  input          io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist,
  input          io_ftq_to_bpu_redirect_bits_debugIsCtrl,
  input          io_ftq_to_bpu_redirect_bits_debugIsMemVio,
  input          io_ftq_to_bpu_redirect_bits_BTBMissBubble,
  input          io_ftq_to_bpu_update_valid,
  input  [49:0]  io_ftq_to_bpu_update_bits_pc,
  input  [7:0]   io_ftq_to_bpu_update_bits_spec_info_histPtr_value,
  input          io_ftq_to_bpu_update_bits_ftb_entry_isCall,
  input          io_ftq_to_bpu_update_bits_ftb_entry_isRet,
  input          io_ftq_to_bpu_update_bits_ftb_entry_isJalr,
  input          io_ftq_to_bpu_update_bits_ftb_entry_valid,
  input  [3:0]   io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset,
  input          io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing,
  input          io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid,
  input  [11:0]  io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower,
  input  [1:0]   io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat,
  input  [3:0]   io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset,
  input          io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing,
  input          io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid,
  input  [19:0]  io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower,
  input  [1:0]   io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat,
  input  [3:0]   io_ftq_to_bpu_update_bits_ftb_entry_pftAddr,
  input          io_ftq_to_bpu_update_bits_ftb_entry_carry,
  input          io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call,
  input          io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0,
  input          io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1,
  input          io_ftq_to_bpu_update_bits_cfi_idx_valid,
  input  [3:0]   io_ftq_to_bpu_update_bits_cfi_idx_bits,
  input          io_ftq_to_bpu_update_bits_br_taken_mask_0,
  input          io_ftq_to_bpu_update_bits_br_taken_mask_1,
  input          io_ftq_to_bpu_update_bits_jmp_taken,
  input          io_ftq_to_bpu_update_bits_mispred_mask_0,
  input          io_ftq_to_bpu_update_bits_mispred_mask_1,
  input          io_ftq_to_bpu_update_bits_mispred_mask_2,
  input          io_ftq_to_bpu_update_bits_false_hit,
  input          io_ftq_to_bpu_update_bits_old_entry,
  input  [515:0] io_ftq_to_bpu_update_bits_meta,
  input  [49:0]  io_ftq_to_bpu_update_bits_full_target,
  input          io_ftq_to_bpu_enq_ptr_flag,
  input  [5:0]   io_ftq_to_bpu_enq_ptr_value,
  input          io_ftq_to_bpu_redirctFromIFU,
  input          io_ctrl_ubtb_enable,
  input          io_ctrl_btb_enable,
  input          io_ctrl_tage_enable,
  input          io_ctrl_sc_enable,
  input          io_ctrl_ras_enable,
  input  [47:0]  io_reset_vector,
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value,
  input  [5:0]   boreChildrenBd_bore_array,
  input          boreChildrenBd_bore_all,
  input          boreChildrenBd_bore_req,
  output         boreChildrenBd_bore_ack,
  input          boreChildrenBd_bore_writeen,
  input  [3:0]   boreChildrenBd_bore_be,
  input  [9:0]   boreChildrenBd_bore_addr,
  input  [39:0]  boreChildrenBd_bore_indata,
  input          boreChildrenBd_bore_readen,
  input  [9:0]   boreChildrenBd_bore_addr_rd,
  output [39:0]  boreChildrenBd_bore_outdata,
  input  [6:0]   boreChildrenBd_bore_1_array,
  input          boreChildrenBd_bore_1_all,
  input          boreChildrenBd_bore_1_req,
  output         boreChildrenBd_bore_1_ack,
  input          boreChildrenBd_bore_1_writeen,
  input  [15:0]  boreChildrenBd_bore_1_be,
  input  [9:0]   boreChildrenBd_bore_1_addr,
  input  [23:0]  boreChildrenBd_bore_1_indata,
  input          boreChildrenBd_bore_1_readen,
  input  [9:0]   boreChildrenBd_bore_1_addr_rd,
  output [23:0]  boreChildrenBd_bore_1_outdata,
  input  [6:0]   boreChildrenBd_bore_2_array,
  input          boreChildrenBd_bore_2_all,
  input          boreChildrenBd_bore_2_req,
  output         boreChildrenBd_bore_2_ack,
  input          boreChildrenBd_bore_2_writeen,
  input  [3:0]   boreChildrenBd_bore_2_be,
  input  [7:0]   boreChildrenBd_bore_2_addr,
  input  [23:0]  boreChildrenBd_bore_2_indata,
  input          boreChildrenBd_bore_2_readen,
  input  [7:0]   boreChildrenBd_bore_2_addr_rd,
  output [23:0]  boreChildrenBd_bore_2_outdata,
  input  [6:0]   boreChildrenBd_bore_3_array,
  input          boreChildrenBd_bore_3_all,
  input          boreChildrenBd_bore_3_req,
  output         boreChildrenBd_bore_3_ack,
  input          boreChildrenBd_bore_3_writeen,
  input  [3:0]   boreChildrenBd_bore_3_be,
  input  [7:0]   boreChildrenBd_bore_3_addr,
  input  [23:0]  boreChildrenBd_bore_3_indata,
  input          boreChildrenBd_bore_3_readen,
  input  [7:0]   boreChildrenBd_bore_3_addr_rd,
  output [23:0]  boreChildrenBd_bore_3_outdata,
  input  [6:0]   boreChildrenBd_bore_4_array,
  input          boreChildrenBd_bore_4_all,
  input          boreChildrenBd_bore_4_req,
  output         boreChildrenBd_bore_4_ack,
  input          boreChildrenBd_bore_4_writeen,
  input  [3:0]   boreChildrenBd_bore_4_be,
  input  [7:0]   boreChildrenBd_bore_4_addr,
  input  [23:0]  boreChildrenBd_bore_4_indata,
  input          boreChildrenBd_bore_4_readen,
  input  [7:0]   boreChildrenBd_bore_4_addr_rd,
  output [23:0]  boreChildrenBd_bore_4_outdata,
  input  [6:0]   boreChildrenBd_bore_5_array,
  input          boreChildrenBd_bore_5_all,
  input          boreChildrenBd_bore_5_req,
  output         boreChildrenBd_bore_5_ack,
  input          boreChildrenBd_bore_5_writeen,
  input  [3:0]   boreChildrenBd_bore_5_be,
  input  [7:0]   boreChildrenBd_bore_5_addr,
  input  [23:0]  boreChildrenBd_bore_5_indata,
  input          boreChildrenBd_bore_5_readen,
  input  [7:0]   boreChildrenBd_bore_5_addr_rd,
  output [23:0]  boreChildrenBd_bore_5_outdata,
  input  [6:0]   boreChildrenBd_bore_6_array,
  input          boreChildrenBd_bore_6_all,
  input          boreChildrenBd_bore_6_req,
  output         boreChildrenBd_bore_6_ack,
  input          boreChildrenBd_bore_6_writeen,
  input  [75:0]  boreChildrenBd_bore_6_be,
  input  [7:0]   boreChildrenBd_bore_6_addr,
  input  [75:0]  boreChildrenBd_bore_6_indata,
  input          boreChildrenBd_bore_6_readen,
  input  [7:0]   boreChildrenBd_bore_6_addr_rd,
  output [75:0]  boreChildrenBd_bore_6_outdata,
  input  [6:0]   boreChildrenBd_bore_7_array,
  input          boreChildrenBd_bore_7_all,
  input          boreChildrenBd_bore_7_req,
  output         boreChildrenBd_bore_7_ack,
  input          boreChildrenBd_bore_7_writeen,
  input  [75:0]  boreChildrenBd_bore_7_be,
  input  [7:0]   boreChildrenBd_bore_7_addr,
  input  [75:0]  boreChildrenBd_bore_7_indata,
  input          boreChildrenBd_bore_7_readen,
  input  [7:0]   boreChildrenBd_bore_7_addr_rd,
  output [75:0]  boreChildrenBd_bore_7_outdata,
  input  [6:0]   boreChildrenBd_bore_8_array,
  input          boreChildrenBd_bore_8_all,
  input          boreChildrenBd_bore_8_req,
  output         boreChildrenBd_bore_8_ack,
  input          boreChildrenBd_bore_8_writeen,
  input  [75:0]  boreChildrenBd_bore_8_be,
  input  [7:0]   boreChildrenBd_bore_8_addr,
  input  [75:0]  boreChildrenBd_bore_8_indata,
  input          boreChildrenBd_bore_8_readen,
  input  [7:0]   boreChildrenBd_bore_8_addr_rd,
  output [75:0]  boreChildrenBd_bore_8_outdata,
  input  [6:0]   boreChildrenBd_bore_9_array,
  input          boreChildrenBd_bore_9_all,
  input          boreChildrenBd_bore_9_req,
  output         boreChildrenBd_bore_9_ack,
  input          boreChildrenBd_bore_9_writeen,
  input  [75:0]  boreChildrenBd_bore_9_be,
  input  [7:0]   boreChildrenBd_bore_9_addr,
  input  [75:0]  boreChildrenBd_bore_9_indata,
  input          boreChildrenBd_bore_9_readen,
  input  [7:0]   boreChildrenBd_bore_9_addr_rd,
  output [75:0]  boreChildrenBd_bore_9_outdata,
  input  [6:0]   boreChildrenBd_bore_10_array,
  input          boreChildrenBd_bore_10_all,
  input          boreChildrenBd_bore_10_req,
  output         boreChildrenBd_bore_10_ack,
  input          boreChildrenBd_bore_10_writeen,
  input  [75:0]  boreChildrenBd_bore_10_be,
  input  [7:0]   boreChildrenBd_bore_10_addr,
  input  [75:0]  boreChildrenBd_bore_10_indata,
  input          boreChildrenBd_bore_10_readen,
  input  [7:0]   boreChildrenBd_bore_10_addr_rd,
  output [75:0]  boreChildrenBd_bore_10_outdata,
  input          sigFromSrams_bore_ram_hold,
  input          sigFromSrams_bore_ram_bypass,
  input          sigFromSrams_bore_ram_bp_clken,
  input          sigFromSrams_bore_ram_aux_clk,
  input          sigFromSrams_bore_ram_aux_ckbp,
  input          sigFromSrams_bore_ram_mcp_hold,
  input          sigFromSrams_bore_cgen,
  input          sigFromSrams_bore_1_ram_hold,
  input          sigFromSrams_bore_1_ram_bypass,
  input          sigFromSrams_bore_1_ram_bp_clken,
  input          sigFromSrams_bore_1_ram_aux_clk,
  input          sigFromSrams_bore_1_ram_aux_ckbp,
  input          sigFromSrams_bore_1_ram_mcp_hold,
  input          sigFromSrams_bore_1_cgen,
  input          sigFromSrams_bore_2_ram_hold,
  input          sigFromSrams_bore_2_ram_bypass,
  input          sigFromSrams_bore_2_ram_bp_clken,
  input          sigFromSrams_bore_2_ram_aux_clk,
  input          sigFromSrams_bore_2_ram_aux_ckbp,
  input          sigFromSrams_bore_2_ram_mcp_hold,
  input          sigFromSrams_bore_2_cgen,
  input          sigFromSrams_bore_3_ram_hold,
  input          sigFromSrams_bore_3_ram_bypass,
  input          sigFromSrams_bore_3_ram_bp_clken,
  input          sigFromSrams_bore_3_ram_aux_clk,
  input          sigFromSrams_bore_3_ram_aux_ckbp,
  input          sigFromSrams_bore_3_ram_mcp_hold,
  input          sigFromSrams_bore_3_cgen,
  input          sigFromSrams_bore_4_ram_hold,
  input          sigFromSrams_bore_4_ram_bypass,
  input          sigFromSrams_bore_4_ram_bp_clken,
  input          sigFromSrams_bore_4_ram_aux_clk,
  input          sigFromSrams_bore_4_ram_aux_ckbp,
  input          sigFromSrams_bore_4_ram_mcp_hold,
  input          sigFromSrams_bore_4_cgen,
  input          sigFromSrams_bore_5_ram_hold,
  input          sigFromSrams_bore_5_ram_bypass,
  input          sigFromSrams_bore_5_ram_bp_clken,
  input          sigFromSrams_bore_5_ram_aux_clk,
  input          sigFromSrams_bore_5_ram_aux_ckbp,
  input          sigFromSrams_bore_5_ram_mcp_hold,
  input          sigFromSrams_bore_5_cgen,
  input          sigFromSrams_bore_6_ram_hold,
  input          sigFromSrams_bore_6_ram_bypass,
  input          sigFromSrams_bore_6_ram_bp_clken,
  input          sigFromSrams_bore_6_ram_aux_clk,
  input          sigFromSrams_bore_6_ram_aux_ckbp,
  input          sigFromSrams_bore_6_ram_mcp_hold,
  input          sigFromSrams_bore_6_cgen,
  input          sigFromSrams_bore_7_ram_hold,
  input          sigFromSrams_bore_7_ram_bypass,
  input          sigFromSrams_bore_7_ram_bp_clken,
  input          sigFromSrams_bore_7_ram_aux_clk,
  input          sigFromSrams_bore_7_ram_aux_ckbp,
  input          sigFromSrams_bore_7_ram_mcp_hold,
  input          sigFromSrams_bore_7_cgen,
  input          sigFromSrams_bore_8_ram_hold,
  input          sigFromSrams_bore_8_ram_bypass,
  input          sigFromSrams_bore_8_ram_bp_clken,
  input          sigFromSrams_bore_8_ram_aux_clk,
  input          sigFromSrams_bore_8_ram_aux_ckbp,
  input          sigFromSrams_bore_8_ram_mcp_hold,
  input          sigFromSrams_bore_8_cgen,
  input          sigFromSrams_bore_9_ram_hold,
  input          sigFromSrams_bore_9_ram_bypass,
  input          sigFromSrams_bore_9_ram_bp_clken,
  input          sigFromSrams_bore_9_ram_aux_clk,
  input          sigFromSrams_bore_9_ram_aux_ckbp,
  input          sigFromSrams_bore_9_ram_mcp_hold,
  input          sigFromSrams_bore_9_cgen,
  input          sigFromSrams_bore_10_ram_hold,
  input          sigFromSrams_bore_10_ram_bypass,
  input          sigFromSrams_bore_10_ram_bp_clken,
  input          sigFromSrams_bore_10_ram_aux_clk,
  input          sigFromSrams_bore_10_ram_aux_ckbp,
  input          sigFromSrams_bore_10_ram_mcp_hold,
  input          sigFromSrams_bore_10_cgen,
  input          sigFromSrams_bore_11_ram_hold,
  input          sigFromSrams_bore_11_ram_bypass,
  input          sigFromSrams_bore_11_ram_bp_clken,
  input          sigFromSrams_bore_11_ram_aux_clk,
  input          sigFromSrams_bore_11_ram_aux_ckbp,
  input          sigFromSrams_bore_11_ram_mcp_hold,
  input          sigFromSrams_bore_11_cgen,
  input          sigFromSrams_bore_12_ram_hold,
  input          sigFromSrams_bore_12_ram_bypass,
  input          sigFromSrams_bore_12_ram_bp_clken,
  input          sigFromSrams_bore_12_ram_aux_clk,
  input          sigFromSrams_bore_12_ram_aux_ckbp,
  input          sigFromSrams_bore_12_ram_mcp_hold,
  input          sigFromSrams_bore_12_cgen,
  input          sigFromSrams_bore_13_ram_hold,
  input          sigFromSrams_bore_13_ram_bypass,
  input          sigFromSrams_bore_13_ram_bp_clken,
  input          sigFromSrams_bore_13_ram_aux_clk,
  input          sigFromSrams_bore_13_ram_aux_ckbp,
  input          sigFromSrams_bore_13_ram_mcp_hold,
  input          sigFromSrams_bore_13_cgen,
  input          sigFromSrams_bore_14_ram_hold,
  input          sigFromSrams_bore_14_ram_bypass,
  input          sigFromSrams_bore_14_ram_bp_clken,
  input          sigFromSrams_bore_14_ram_aux_clk,
  input          sigFromSrams_bore_14_ram_aux_ckbp,
  input          sigFromSrams_bore_14_ram_mcp_hold,
  input          sigFromSrams_bore_14_cgen,
  input          sigFromSrams_bore_15_ram_hold,
  input          sigFromSrams_bore_15_ram_bypass,
  input          sigFromSrams_bore_15_ram_bp_clken,
  input          sigFromSrams_bore_15_ram_aux_clk,
  input          sigFromSrams_bore_15_ram_aux_ckbp,
  input          sigFromSrams_bore_15_ram_mcp_hold,
  input          sigFromSrams_bore_15_cgen,
  input          sigFromSrams_bore_16_ram_hold,
  input          sigFromSrams_bore_16_ram_bypass,
  input          sigFromSrams_bore_16_ram_bp_clken,
  input          sigFromSrams_bore_16_ram_aux_clk,
  input          sigFromSrams_bore_16_ram_aux_ckbp,
  input          sigFromSrams_bore_16_ram_mcp_hold,
  input          sigFromSrams_bore_16_cgen,
  input          sigFromSrams_bore_17_ram_hold,
  input          sigFromSrams_bore_17_ram_bypass,
  input          sigFromSrams_bore_17_ram_bp_clken,
  input          sigFromSrams_bore_17_ram_aux_clk,
  input          sigFromSrams_bore_17_ram_aux_ckbp,
  input          sigFromSrams_bore_17_ram_mcp_hold,
  input          sigFromSrams_bore_17_cgen,
  input          sigFromSrams_bore_18_ram_hold,
  input          sigFromSrams_bore_18_ram_bypass,
  input          sigFromSrams_bore_18_ram_bp_clken,
  input          sigFromSrams_bore_18_ram_aux_clk,
  input          sigFromSrams_bore_18_ram_aux_ckbp,
  input          sigFromSrams_bore_18_ram_mcp_hold,
  input          sigFromSrams_bore_18_cgen,
  input          sigFromSrams_bore_19_ram_hold,
  input          sigFromSrams_bore_19_ram_bypass,
  input          sigFromSrams_bore_19_ram_bp_clken,
  input          sigFromSrams_bore_19_ram_aux_clk,
  input          sigFromSrams_bore_19_ram_aux_ckbp,
  input          sigFromSrams_bore_19_ram_mcp_hold,
  input          sigFromSrams_bore_19_cgen,
  input          sigFromSrams_bore_20_ram_hold,
  input          sigFromSrams_bore_20_ram_bypass,
  input          sigFromSrams_bore_20_ram_bp_clken,
  input          sigFromSrams_bore_20_ram_aux_clk,
  input          sigFromSrams_bore_20_ram_aux_ckbp,
  input          sigFromSrams_bore_20_ram_mcp_hold,
  input          sigFromSrams_bore_20_cgen,
  input          sigFromSrams_bore_21_ram_hold,
  input          sigFromSrams_bore_21_ram_bypass,
  input          sigFromSrams_bore_21_ram_bp_clken,
  input          sigFromSrams_bore_21_ram_aux_clk,
  input          sigFromSrams_bore_21_ram_aux_ckbp,
  input          sigFromSrams_bore_21_ram_mcp_hold,
  input          sigFromSrams_bore_21_cgen,
  input          sigFromSrams_bore_22_ram_hold,
  input          sigFromSrams_bore_22_ram_bypass,
  input          sigFromSrams_bore_22_ram_bp_clken,
  input          sigFromSrams_bore_22_ram_aux_clk,
  input          sigFromSrams_bore_22_ram_aux_ckbp,
  input          sigFromSrams_bore_22_ram_mcp_hold,
  input          sigFromSrams_bore_22_cgen,
  input          sigFromSrams_bore_23_ram_hold,
  input          sigFromSrams_bore_23_ram_bypass,
  input          sigFromSrams_bore_23_ram_bp_clken,
  input          sigFromSrams_bore_23_ram_aux_clk,
  input          sigFromSrams_bore_23_ram_aux_ckbp,
  input          sigFromSrams_bore_23_ram_mcp_hold,
  input          sigFromSrams_bore_23_cgen,
  input          sigFromSrams_bore_24_ram_hold,
  input          sigFromSrams_bore_24_ram_bypass,
  input          sigFromSrams_bore_24_ram_bp_clken,
  input          sigFromSrams_bore_24_ram_aux_clk,
  input          sigFromSrams_bore_24_ram_aux_ckbp,
  input          sigFromSrams_bore_24_ram_mcp_hold,
  input          sigFromSrams_bore_24_cgen,
  input          sigFromSrams_bore_25_ram_hold,
  input          sigFromSrams_bore_25_ram_bypass,
  input          sigFromSrams_bore_25_ram_bp_clken,
  input          sigFromSrams_bore_25_ram_aux_clk,
  input          sigFromSrams_bore_25_ram_aux_ckbp,
  input          sigFromSrams_bore_25_ram_mcp_hold,
  input          sigFromSrams_bore_25_cgen,
  input          sigFromSrams_bore_26_ram_hold,
  input          sigFromSrams_bore_26_ram_bypass,
  input          sigFromSrams_bore_26_ram_bp_clken,
  input          sigFromSrams_bore_26_ram_aux_clk,
  input          sigFromSrams_bore_26_ram_aux_ckbp,
  input          sigFromSrams_bore_26_ram_mcp_hold,
  input          sigFromSrams_bore_26_cgen,
  input          sigFromSrams_bore_27_ram_hold,
  input          sigFromSrams_bore_27_ram_bypass,
  input          sigFromSrams_bore_27_ram_bp_clken,
  input          sigFromSrams_bore_27_ram_aux_clk,
  input          sigFromSrams_bore_27_ram_aux_ckbp,
  input          sigFromSrams_bore_27_ram_mcp_hold,
  input          sigFromSrams_bore_27_cgen,
  input          sigFromSrams_bore_28_ram_hold,
  input          sigFromSrams_bore_28_ram_bypass,
  input          sigFromSrams_bore_28_ram_bp_clken,
  input          sigFromSrams_bore_28_ram_aux_clk,
  input          sigFromSrams_bore_28_ram_aux_ckbp,
  input          sigFromSrams_bore_28_ram_mcp_hold,
  input          sigFromSrams_bore_28_cgen,
  input          sigFromSrams_bore_29_ram_hold,
  input          sigFromSrams_bore_29_ram_bypass,
  input          sigFromSrams_bore_29_ram_bp_clken,
  input          sigFromSrams_bore_29_ram_aux_clk,
  input          sigFromSrams_bore_29_ram_aux_ckbp,
  input          sigFromSrams_bore_29_ram_mcp_hold,
  input          sigFromSrams_bore_29_cgen,
  input          sigFromSrams_bore_30_ram_hold,
  input          sigFromSrams_bore_30_ram_bypass,
  input          sigFromSrams_bore_30_ram_bp_clken,
  input          sigFromSrams_bore_30_ram_aux_clk,
  input          sigFromSrams_bore_30_ram_aux_ckbp,
  input          sigFromSrams_bore_30_ram_mcp_hold,
  input          sigFromSrams_bore_30_cgen,
  input          sigFromSrams_bore_31_ram_hold,
  input          sigFromSrams_bore_31_ram_bypass,
  input          sigFromSrams_bore_31_ram_bp_clken,
  input          sigFromSrams_bore_31_ram_aux_clk,
  input          sigFromSrams_bore_31_ram_aux_ckbp,
  input          sigFromSrams_bore_31_ram_mcp_hold,
  input          sigFromSrams_bore_31_cgen,
  input          sigFromSrams_bore_32_ram_hold,
  input          sigFromSrams_bore_32_ram_bypass,
  input          sigFromSrams_bore_32_ram_bp_clken,
  input          sigFromSrams_bore_32_ram_aux_clk,
  input          sigFromSrams_bore_32_ram_aux_ckbp,
  input          sigFromSrams_bore_32_ram_mcp_hold,
  input          sigFromSrams_bore_32_cgen,
  input          sigFromSrams_bore_33_ram_hold,
  input          sigFromSrams_bore_33_ram_bypass,
  input          sigFromSrams_bore_33_ram_bp_clken,
  input          sigFromSrams_bore_33_ram_aux_clk,
  input          sigFromSrams_bore_33_ram_aux_ckbp,
  input          sigFromSrams_bore_33_ram_mcp_hold,
  input          sigFromSrams_bore_33_cgen,
  input          sigFromSrams_bore_34_ram_hold,
  input          sigFromSrams_bore_34_ram_bypass,
  input          sigFromSrams_bore_34_ram_bp_clken,
  input          sigFromSrams_bore_34_ram_aux_clk,
  input          sigFromSrams_bore_34_ram_aux_ckbp,
  input          sigFromSrams_bore_34_ram_mcp_hold,
  input          sigFromSrams_bore_34_cgen,
  input          sigFromSrams_bore_35_ram_hold,
  input          sigFromSrams_bore_35_ram_bypass,
  input          sigFromSrams_bore_35_ram_bp_clken,
  input          sigFromSrams_bore_35_ram_aux_clk,
  input          sigFromSrams_bore_35_ram_aux_ckbp,
  input          sigFromSrams_bore_35_ram_mcp_hold,
  input          sigFromSrams_bore_35_cgen,
  input          sigFromSrams_bore_36_ram_hold,
  input          sigFromSrams_bore_36_ram_bypass,
  input          sigFromSrams_bore_36_ram_bp_clken,
  input          sigFromSrams_bore_36_ram_aux_clk,
  input          sigFromSrams_bore_36_ram_aux_ckbp,
  input          sigFromSrams_bore_36_ram_mcp_hold,
  input          sigFromSrams_bore_36_cgen,
  input          sigFromSrams_bore_37_ram_hold,
  input          sigFromSrams_bore_37_ram_bypass,
  input          sigFromSrams_bore_37_ram_bp_clken,
  input          sigFromSrams_bore_37_ram_aux_clk,
  input          sigFromSrams_bore_37_ram_aux_ckbp,
  input          sigFromSrams_bore_37_ram_mcp_hold,
  input          sigFromSrams_bore_37_cgen,
  input          sigFromSrams_bore_38_ram_hold,
  input          sigFromSrams_bore_38_ram_bypass,
  input          sigFromSrams_bore_38_ram_bp_clken,
  input          sigFromSrams_bore_38_ram_aux_clk,
  input          sigFromSrams_bore_38_ram_aux_ckbp,
  input          sigFromSrams_bore_38_ram_mcp_hold,
  input          sigFromSrams_bore_38_cgen,
  input          sigFromSrams_bore_39_ram_hold,
  input          sigFromSrams_bore_39_ram_bypass,
  input          sigFromSrams_bore_39_ram_bp_clken,
  input          sigFromSrams_bore_39_ram_aux_clk,
  input          sigFromSrams_bore_39_ram_aux_ckbp,
  input          sigFromSrams_bore_39_ram_mcp_hold,
  input          sigFromSrams_bore_39_cgen,
  input          sigFromSrams_bore_40_ram_hold,
  input          sigFromSrams_bore_40_ram_bypass,
  input          sigFromSrams_bore_40_ram_bp_clken,
  input          sigFromSrams_bore_40_ram_aux_clk,
  input          sigFromSrams_bore_40_ram_aux_ckbp,
  input          sigFromSrams_bore_40_ram_mcp_hold,
  input          sigFromSrams_bore_40_cgen,
  input          sigFromSrams_bore_41_ram_hold,
  input          sigFromSrams_bore_41_ram_bypass,
  input          sigFromSrams_bore_41_ram_bp_clken,
  input          sigFromSrams_bore_41_ram_aux_clk,
  input          sigFromSrams_bore_41_ram_aux_ckbp,
  input          sigFromSrams_bore_41_ram_mcp_hold,
  input          sigFromSrams_bore_41_cgen,
  input          sigFromSrams_bore_42_ram_hold,
  input          sigFromSrams_bore_42_ram_bypass,
  input          sigFromSrams_bore_42_ram_bp_clken,
  input          sigFromSrams_bore_42_ram_aux_clk,
  input          sigFromSrams_bore_42_ram_aux_ckbp,
  input          sigFromSrams_bore_42_ram_mcp_hold,
  input          sigFromSrams_bore_42_cgen,
  input          sigFromSrams_bore_43_ram_hold,
  input          sigFromSrams_bore_43_ram_bypass,
  input          sigFromSrams_bore_43_ram_bp_clken,
  input          sigFromSrams_bore_43_ram_aux_clk,
  input          sigFromSrams_bore_43_ram_aux_ckbp,
  input          sigFromSrams_bore_43_ram_mcp_hold,
  input          sigFromSrams_bore_43_cgen,
  input          sigFromSrams_bore_44_ram_hold,
  input          sigFromSrams_bore_44_ram_bypass,
  input          sigFromSrams_bore_44_ram_bp_clken,
  input          sigFromSrams_bore_44_ram_aux_clk,
  input          sigFromSrams_bore_44_ram_aux_ckbp,
  input          sigFromSrams_bore_44_ram_mcp_hold,
  input          sigFromSrams_bore_44_cgen,
  input          sigFromSrams_bore_45_ram_hold,
  input          sigFromSrams_bore_45_ram_bypass,
  input          sigFromSrams_bore_45_ram_bp_clken,
  input          sigFromSrams_bore_45_ram_aux_clk,
  input          sigFromSrams_bore_45_ram_aux_ckbp,
  input          sigFromSrams_bore_45_ram_mcp_hold,
  input          sigFromSrams_bore_45_cgen,
  input          sigFromSrams_bore_46_ram_hold,
  input          sigFromSrams_bore_46_ram_bypass,
  input          sigFromSrams_bore_46_ram_bp_clken,
  input          sigFromSrams_bore_46_ram_aux_clk,
  input          sigFromSrams_bore_46_ram_aux_ckbp,
  input          sigFromSrams_bore_46_ram_mcp_hold,
  input          sigFromSrams_bore_46_cgen,
  input          sigFromSrams_bore_47_ram_hold,
  input          sigFromSrams_bore_47_ram_bypass,
  input          sigFromSrams_bore_47_ram_bp_clken,
  input          sigFromSrams_bore_47_ram_aux_clk,
  input          sigFromSrams_bore_47_ram_aux_ckbp,
  input          sigFromSrams_bore_47_ram_mcp_hold,
  input          sigFromSrams_bore_47_cgen
  // END GENERATED(ports)
);
  import predictor_pkg::*;

  // ---- Composer 侧中间线（宽度取自 Composer 端口表，由脚本生成） ----------
  // BEGIN GENERATED(glue_decls)
  logic         comp_s1_full_pred_0_br_taken_mask_0;
  logic         comp_s1_full_pred_0_br_taken_mask_1;
  logic [49:0]  comp_s1_full_pred_0_fallThroughAddr;
  logic         comp_s1_full_pred_0_fallThroughErr;
  logic         comp_s1_full_pred_0_hit;
  logic         comp_s1_full_pred_0_is_br_sharing;
  logic         comp_s1_full_pred_0_is_call;
  logic         comp_s1_full_pred_0_is_jal;
  logic         comp_s1_full_pred_0_is_jalr;
  logic         comp_s1_full_pred_0_is_ret;
  logic [49:0]  comp_s1_full_pred_0_jalr_target;
  logic         comp_s1_full_pred_0_last_may_be_rvi_call;
  logic [3:0]   comp_s1_full_pred_0_offsets_0;
  logic [3:0]   comp_s1_full_pred_0_offsets_1;
  logic         comp_s1_full_pred_0_slot_valids_0;
  logic         comp_s1_full_pred_0_slot_valids_1;
  logic [49:0]  comp_s1_full_pred_0_targets_0;
  logic [49:0]  comp_s1_full_pred_0_targets_1;
  logic         comp_s1_full_pred_1_br_taken_mask_0;
  logic         comp_s1_full_pred_1_br_taken_mask_1;
  logic [49:0]  comp_s1_full_pred_1_fallThroughAddr;
  logic         comp_s1_full_pred_1_fallThroughErr;
  logic         comp_s1_full_pred_1_hit;
  logic         comp_s1_full_pred_1_is_br_sharing;
  logic         comp_s1_full_pred_1_is_call;
  logic         comp_s1_full_pred_1_is_jal;
  logic         comp_s1_full_pred_1_is_jalr;
  logic         comp_s1_full_pred_1_is_ret;
  logic [49:0]  comp_s1_full_pred_1_jalr_target;
  logic         comp_s1_full_pred_1_last_may_be_rvi_call;
  logic [3:0]   comp_s1_full_pred_1_offsets_0;
  logic [3:0]   comp_s1_full_pred_1_offsets_1;
  logic         comp_s1_full_pred_1_slot_valids_0;
  logic         comp_s1_full_pred_1_slot_valids_1;
  logic [49:0]  comp_s1_full_pred_1_targets_0;
  logic [49:0]  comp_s1_full_pred_1_targets_1;
  logic         comp_s1_full_pred_2_br_taken_mask_0;
  logic         comp_s1_full_pred_2_br_taken_mask_1;
  logic [49:0]  comp_s1_full_pred_2_fallThroughAddr;
  logic         comp_s1_full_pred_2_fallThroughErr;
  logic         comp_s1_full_pred_2_hit;
  logic         comp_s1_full_pred_2_is_br_sharing;
  logic         comp_s1_full_pred_2_is_call;
  logic         comp_s1_full_pred_2_is_jal;
  logic         comp_s1_full_pred_2_is_jalr;
  logic         comp_s1_full_pred_2_is_ret;
  logic [49:0]  comp_s1_full_pred_2_jalr_target;
  logic         comp_s1_full_pred_2_last_may_be_rvi_call;
  logic [3:0]   comp_s1_full_pred_2_offsets_0;
  logic [3:0]   comp_s1_full_pred_2_offsets_1;
  logic         comp_s1_full_pred_2_slot_valids_0;
  logic         comp_s1_full_pred_2_slot_valids_1;
  logic [49:0]  comp_s1_full_pred_2_targets_0;
  logic [49:0]  comp_s1_full_pred_2_targets_1;
  logic         comp_s1_full_pred_3_br_taken_mask_0;
  logic         comp_s1_full_pred_3_br_taken_mask_1;
  logic [49:0]  comp_s1_full_pred_3_fallThroughAddr;
  logic         comp_s1_full_pred_3_fallThroughErr;
  logic         comp_s1_full_pred_3_hit;
  logic         comp_s1_full_pred_3_is_br_sharing;
  logic         comp_s1_full_pred_3_is_call;
  logic         comp_s1_full_pred_3_is_jal;
  logic         comp_s1_full_pred_3_is_jalr;
  logic         comp_s1_full_pred_3_is_ret;
  logic [49:0]  comp_s1_full_pred_3_jalr_target;
  logic         comp_s1_full_pred_3_last_may_be_rvi_call;
  logic [3:0]   comp_s1_full_pred_3_offsets_0;
  logic [3:0]   comp_s1_full_pred_3_offsets_1;
  logic         comp_s1_full_pred_3_slot_valids_0;
  logic         comp_s1_full_pred_3_slot_valids_1;
  logic [49:0]  comp_s1_full_pred_3_targets_0;
  logic [49:0]  comp_s1_full_pred_3_targets_1;
  logic [49:0]  comp_s1_pc_0;
  logic [49:0]  comp_s1_pc_1;
  logic [49:0]  comp_s1_pc_2;
  logic [49:0]  comp_s1_pc_3;
  logic         comp_s1_ready_w;
  logic         comp_s2_full_pred_0_br_taken_mask_0;
  logic         comp_s2_full_pred_0_br_taken_mask_1;
  logic [49:0]  comp_s2_full_pred_0_fallThroughAddr;
  logic         comp_s2_full_pred_0_fallThroughErr;
  logic         comp_s2_full_pred_0_hit;
  logic         comp_s2_full_pred_0_is_br_sharing;
  logic         comp_s2_full_pred_0_is_call;
  logic         comp_s2_full_pred_0_is_jal;
  logic         comp_s2_full_pred_0_is_jalr;
  logic         comp_s2_full_pred_0_is_ret;
  logic [49:0]  comp_s2_full_pred_0_jalr_target;
  logic         comp_s2_full_pred_0_last_may_be_rvi_call;
  logic [3:0]   comp_s2_full_pred_0_offsets_0;
  logic [3:0]   comp_s2_full_pred_0_offsets_1;
  logic         comp_s2_full_pred_0_slot_valids_0;
  logic         comp_s2_full_pred_0_slot_valids_1;
  logic [49:0]  comp_s2_full_pred_0_targets_0;
  logic [49:0]  comp_s2_full_pred_0_targets_1;
  logic         comp_s2_full_pred_1_br_taken_mask_0;
  logic         comp_s2_full_pred_1_br_taken_mask_1;
  logic [49:0]  comp_s2_full_pred_1_fallThroughAddr;
  logic         comp_s2_full_pred_1_fallThroughErr;
  logic         comp_s2_full_pred_1_hit;
  logic         comp_s2_full_pred_1_is_br_sharing;
  logic         comp_s2_full_pred_1_is_call;
  logic         comp_s2_full_pred_1_is_jal;
  logic         comp_s2_full_pred_1_is_jalr;
  logic         comp_s2_full_pred_1_is_ret;
  logic [49:0]  comp_s2_full_pred_1_jalr_target;
  logic         comp_s2_full_pred_1_last_may_be_rvi_call;
  logic [3:0]   comp_s2_full_pred_1_offsets_0;
  logic [3:0]   comp_s2_full_pred_1_offsets_1;
  logic         comp_s2_full_pred_1_slot_valids_0;
  logic         comp_s2_full_pred_1_slot_valids_1;
  logic [49:0]  comp_s2_full_pred_1_targets_0;
  logic [49:0]  comp_s2_full_pred_1_targets_1;
  logic         comp_s2_full_pred_2_br_taken_mask_0;
  logic         comp_s2_full_pred_2_br_taken_mask_1;
  logic [49:0]  comp_s2_full_pred_2_fallThroughAddr;
  logic         comp_s2_full_pred_2_fallThroughErr;
  logic         comp_s2_full_pred_2_hit;
  logic         comp_s2_full_pred_2_is_br_sharing;
  logic         comp_s2_full_pred_2_is_call;
  logic         comp_s2_full_pred_2_is_jal;
  logic         comp_s2_full_pred_2_is_jalr;
  logic         comp_s2_full_pred_2_is_ret;
  logic [49:0]  comp_s2_full_pred_2_jalr_target;
  logic         comp_s2_full_pred_2_last_may_be_rvi_call;
  logic [3:0]   comp_s2_full_pred_2_offsets_0;
  logic [3:0]   comp_s2_full_pred_2_offsets_1;
  logic         comp_s2_full_pred_2_slot_valids_0;
  logic         comp_s2_full_pred_2_slot_valids_1;
  logic [49:0]  comp_s2_full_pred_2_targets_0;
  logic [49:0]  comp_s2_full_pred_2_targets_1;
  logic         comp_s2_full_pred_3_br_taken_mask_0;
  logic         comp_s2_full_pred_3_br_taken_mask_1;
  logic [49:0]  comp_s2_full_pred_3_fallThroughAddr;
  logic         comp_s2_full_pred_3_fallThroughErr;
  logic         comp_s2_full_pred_3_hit;
  logic         comp_s2_full_pred_3_is_br_sharing;
  logic         comp_s2_full_pred_3_is_call;
  logic         comp_s2_full_pred_3_is_jal;
  logic         comp_s2_full_pred_3_is_jalr;
  logic         comp_s2_full_pred_3_is_ret;
  logic [49:0]  comp_s2_full_pred_3_jalr_target;
  logic         comp_s2_full_pred_3_last_may_be_rvi_call;
  logic [3:0]   comp_s2_full_pred_3_offsets_0;
  logic [3:0]   comp_s2_full_pred_3_offsets_1;
  logic         comp_s2_full_pred_3_slot_valids_0;
  logic         comp_s2_full_pred_3_slot_valids_1;
  logic [49:0]  comp_s2_full_pred_3_targets_0;
  logic [49:0]  comp_s2_full_pred_3_targets_1;
  logic [49:0]  comp_s2_pc_0;
  logic [49:0]  comp_s2_pc_1;
  logic [49:0]  comp_s2_pc_2;
  logic [49:0]  comp_s2_pc_3;
  logic         comp_s3_full_pred_0_br_taken_mask_0;
  logic         comp_s3_full_pred_0_br_taken_mask_1;
  logic [49:0]  comp_s3_full_pred_0_fallThroughAddr;
  logic         comp_s3_full_pred_0_fallThroughErr;
  logic         comp_s3_full_pred_0_hit;
  logic         comp_s3_full_pred_0_is_br_sharing;
  logic         comp_s3_full_pred_0_is_call;
  logic         comp_s3_full_pred_0_is_jal;
  logic         comp_s3_full_pred_0_is_jalr;
  logic         comp_s3_full_pred_0_is_ret;
  logic [49:0]  comp_s3_full_pred_0_jalr_target;
  logic         comp_s3_full_pred_0_last_may_be_rvi_call;
  logic         comp_s3_full_pred_0_multiHit;
  logic [3:0]   comp_s3_full_pred_0_offsets_0;
  logic [3:0]   comp_s3_full_pred_0_offsets_1;
  logic         comp_s3_full_pred_0_slot_valids_0;
  logic         comp_s3_full_pred_0_slot_valids_1;
  logic [49:0]  comp_s3_full_pred_0_targets_0;
  logic [49:0]  comp_s3_full_pred_0_targets_1;
  logic         comp_s3_full_pred_1_br_taken_mask_0;
  logic         comp_s3_full_pred_1_br_taken_mask_1;
  logic [49:0]  comp_s3_full_pred_1_fallThroughAddr;
  logic         comp_s3_full_pred_1_fallThroughErr;
  logic         comp_s3_full_pred_1_hit;
  logic         comp_s3_full_pred_1_is_br_sharing;
  logic         comp_s3_full_pred_1_is_call;
  logic         comp_s3_full_pred_1_is_jal;
  logic         comp_s3_full_pred_1_is_jalr;
  logic         comp_s3_full_pred_1_is_ret;
  logic [49:0]  comp_s3_full_pred_1_jalr_target;
  logic         comp_s3_full_pred_1_last_may_be_rvi_call;
  logic         comp_s3_full_pred_1_multiHit;
  logic [3:0]   comp_s3_full_pred_1_offsets_0;
  logic [3:0]   comp_s3_full_pred_1_offsets_1;
  logic         comp_s3_full_pred_1_slot_valids_0;
  logic         comp_s3_full_pred_1_slot_valids_1;
  logic [49:0]  comp_s3_full_pred_1_targets_0;
  logic [49:0]  comp_s3_full_pred_1_targets_1;
  logic         comp_s3_full_pred_2_br_taken_mask_0;
  logic         comp_s3_full_pred_2_br_taken_mask_1;
  logic [49:0]  comp_s3_full_pred_2_fallThroughAddr;
  logic         comp_s3_full_pred_2_fallThroughErr;
  logic         comp_s3_full_pred_2_hit;
  logic         comp_s3_full_pred_2_is_br_sharing;
  logic         comp_s3_full_pred_2_is_call;
  logic         comp_s3_full_pred_2_is_jal;
  logic         comp_s3_full_pred_2_is_jalr;
  logic         comp_s3_full_pred_2_is_ret;
  logic [49:0]  comp_s3_full_pred_2_jalr_target;
  logic         comp_s3_full_pred_2_last_may_be_rvi_call;
  logic         comp_s3_full_pred_2_multiHit;
  logic [3:0]   comp_s3_full_pred_2_offsets_0;
  logic [3:0]   comp_s3_full_pred_2_offsets_1;
  logic         comp_s3_full_pred_2_slot_valids_0;
  logic         comp_s3_full_pred_2_slot_valids_1;
  logic [49:0]  comp_s3_full_pred_2_targets_0;
  logic [49:0]  comp_s3_full_pred_2_targets_1;
  logic         comp_s3_full_pred_3_br_taken_mask_0;
  logic         comp_s3_full_pred_3_br_taken_mask_1;
  logic [49:0]  comp_s3_full_pred_3_fallThroughAddr;
  logic         comp_s3_full_pred_3_fallThroughErr;
  logic         comp_s3_full_pred_3_hit;
  logic         comp_s3_full_pred_3_is_br_sharing;
  logic         comp_s3_full_pred_3_is_call;
  logic         comp_s3_full_pred_3_is_jal;
  logic         comp_s3_full_pred_3_is_jalr;
  logic         comp_s3_full_pred_3_is_ret;
  logic [49:0]  comp_s3_full_pred_3_jalr_target;
  logic         comp_s3_full_pred_3_last_may_be_rvi_call;
  logic         comp_s3_full_pred_3_multiHit;
  logic [3:0]   comp_s3_full_pred_3_offsets_0;
  logic [3:0]   comp_s3_full_pred_3_offsets_1;
  logic         comp_s3_full_pred_3_slot_valids_0;
  logic         comp_s3_full_pred_3_slot_valids_1;
  logic [49:0]  comp_s3_full_pred_3_targets_0;
  logic [49:0]  comp_s3_full_pred_3_targets_1;
  logic [49:0]  comp_s3_pc_0;
  logic [49:0]  comp_s3_pc_1;
  logic [49:0]  comp_s3_pc_2;
  logic [49:0]  comp_s3_pc_3;
  logic         ctrl_q_btb_enable;
  logic         ctrl_q_ras_enable;
  logic         ctrl_q_sc_enable;
  logic         ctrl_q_tage_enable;
  logic         ctrl_q_ubtb_enable;
  logic         do_redirect_valid_w;
  logic         rdr_q_cfiUpdate_NOS_flag;
  logic [4:0]   rdr_q_cfiUpdate_NOS_value;
  logic         rdr_q_cfiUpdate_TOSR_flag;
  logic [4:0]   rdr_q_cfiUpdate_TOSR_value;
  logic         rdr_q_cfiUpdate_TOSW_flag;
  logic [4:0]   rdr_q_cfiUpdate_TOSW_value;
  logic [49:0]  rdr_q_cfiUpdate_pc;
  logic         rdr_q_cfiUpdate_pd_isCall;
  logic         rdr_q_cfiUpdate_pd_isRVC;
  logic         rdr_q_cfiUpdate_pd_isRet;
  logic         rdr_q_cfiUpdate_pd_valid;
  logic [2:0]   rdr_q_cfiUpdate_sctr;
  logic [3:0]   rdr_q_cfiUpdate_ssp;
  logic         rdr_q_level;
  logic         redirect_from_ifu_q_w;
  logic [255:0] s0_ghist_w;
  logic [255:0] update_ghist_w;
  logic [49:0]  update_pc_seg_w;
  // END GENERATED(glue_decls)

  // ---- 核与 Composer 之间的结构化信号（手写） ----------------------------
  vaddr_t       s0_pc_w   [0:NUM_DUP-1];
  folded_hist_t s0_fg_w   [0:NUM_DUP-1], s1_fg_w [0:NUM_DUP-1];
  cgh_ptr_t     s0_gp_w   [0:NUM_DUP-1];
  logic [NUM_BR:0] s0_bn_w [0:NUM_DUP-1];
  // s0_ghist_w 由 GENERATED(glue_decls) 声明（宽度取自 Composer 端口表）
  logic         s0_fire_w [0:NUM_DUP-1], s1_fire_w [0:NUM_DUP-1];
  logic         s2_fire_w [0:NUM_DUP-1], s3_fire_w [0:NUM_DUP-1];
  logic         s2_redirect_w [0:NUM_DUP-1], s3_redirect_w [0:NUM_DUP-1];
  logic [5:0]   comp_perf_w [0:6], perf_out_w [0:6];
  full_pred_t   s1_pred_w [0:NUM_DUP-1], s2_pred_w [0:NUM_DUP-1], s3_pred_w [0:NUM_DUP-1];
  vaddr_t       s1_pc_w [0:NUM_DUP-1], s2_pc_w [0:NUM_DUP-1], s3_pc_w [0:NUM_DUP-1];
  redirect_bundle_t rdr_in_w, rdr_q_w;
  logic [NUM_REASON-1:0] topdown_reasons_w;
  logic [63:0]           pred_cycle_w;
  cgh_ptr_t     s3_gp_o_w, upd_hp_w;

  // Composer 的 io_s2_ready / io_s3_ready 在 golden 里**不存在** —— BasePredictor 里
  // 它们恒为 true.B，firtool 把端口整根消掉了。这里照样钉 1，不凭空造端口。
  logic comp_s2_ready_w, comp_s3_ready_w;
  assign comp_s2_ready_w = 1'b1;
  assign comp_s3_ready_w = 1'b1;

  // ---- Composer 的三级预测包：散装字段 → full_pred_t（脚本生成） ---------
  // BEGIN GENERATED(pred_pack)
  assign s1_pred_w[0] = '{
      br_taken_mask:     {comp_s1_full_pred_0_br_taken_mask_1, comp_s1_full_pred_0_br_taken_mask_0},
      slot_valids:       {comp_s1_full_pred_0_slot_valids_1, comp_s1_full_pred_0_slot_valids_0},
      targets:           {comp_s1_full_pred_0_targets_1, comp_s1_full_pred_0_targets_0},
      jalr_target:       comp_s1_full_pred_0_jalr_target,
      offsets:           {comp_s1_full_pred_0_offsets_1, comp_s1_full_pred_0_offsets_0},
      fall_through_addr: comp_s1_full_pred_0_fallThroughAddr,
      fall_through_err:  comp_s1_full_pred_0_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s1_full_pred_0_is_br_sharing,
      hit:               comp_s1_full_pred_0_hit};
  assign s1_pred_w[1] = '{
      br_taken_mask:     {comp_s1_full_pred_1_br_taken_mask_1, comp_s1_full_pred_1_br_taken_mask_0},
      slot_valids:       {comp_s1_full_pred_1_slot_valids_1, comp_s1_full_pred_1_slot_valids_0},
      targets:           {comp_s1_full_pred_1_targets_1, comp_s1_full_pred_1_targets_0},
      jalr_target:       comp_s1_full_pred_1_jalr_target,
      offsets:           {comp_s1_full_pred_1_offsets_1, comp_s1_full_pred_1_offsets_0},
      fall_through_addr: comp_s1_full_pred_1_fallThroughAddr,
      fall_through_err:  comp_s1_full_pred_1_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s1_full_pred_1_is_br_sharing,
      hit:               comp_s1_full_pred_1_hit};
  assign s1_pred_w[2] = '{
      br_taken_mask:     {comp_s1_full_pred_2_br_taken_mask_1, comp_s1_full_pred_2_br_taken_mask_0},
      slot_valids:       {comp_s1_full_pred_2_slot_valids_1, comp_s1_full_pred_2_slot_valids_0},
      targets:           {comp_s1_full_pred_2_targets_1, comp_s1_full_pred_2_targets_0},
      jalr_target:       comp_s1_full_pred_2_jalr_target,
      offsets:           {comp_s1_full_pred_2_offsets_1, comp_s1_full_pred_2_offsets_0},
      fall_through_addr: comp_s1_full_pred_2_fallThroughAddr,
      fall_through_err:  comp_s1_full_pred_2_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s1_full_pred_2_is_br_sharing,
      hit:               comp_s1_full_pred_2_hit};
  assign s1_pred_w[3] = '{
      br_taken_mask:     {comp_s1_full_pred_3_br_taken_mask_1, comp_s1_full_pred_3_br_taken_mask_0},
      slot_valids:       {comp_s1_full_pred_3_slot_valids_1, comp_s1_full_pred_3_slot_valids_0},
      targets:           {comp_s1_full_pred_3_targets_1, comp_s1_full_pred_3_targets_0},
      jalr_target:       comp_s1_full_pred_3_jalr_target,
      offsets:           {comp_s1_full_pred_3_offsets_1, comp_s1_full_pred_3_offsets_0},
      fall_through_addr: comp_s1_full_pred_3_fallThroughAddr,
      fall_through_err:  comp_s1_full_pred_3_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s1_full_pred_3_is_br_sharing,
      hit:               comp_s1_full_pred_3_hit};

  assign s2_pred_w[0] = '{
      br_taken_mask:     {comp_s2_full_pred_0_br_taken_mask_1, comp_s2_full_pred_0_br_taken_mask_0},
      slot_valids:       {comp_s2_full_pred_0_slot_valids_1, comp_s2_full_pred_0_slot_valids_0},
      targets:           {comp_s2_full_pred_0_targets_1, comp_s2_full_pred_0_targets_0},
      jalr_target:       comp_s2_full_pred_0_jalr_target,
      offsets:           {comp_s2_full_pred_0_offsets_1, comp_s2_full_pred_0_offsets_0},
      fall_through_addr: comp_s2_full_pred_0_fallThroughAddr,
      fall_through_err:  comp_s2_full_pred_0_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s2_full_pred_0_is_br_sharing,
      hit:               comp_s2_full_pred_0_hit};
  assign s2_pred_w[1] = '{
      br_taken_mask:     {comp_s2_full_pred_1_br_taken_mask_1, comp_s2_full_pred_1_br_taken_mask_0},
      slot_valids:       {comp_s2_full_pred_1_slot_valids_1, comp_s2_full_pred_1_slot_valids_0},
      targets:           {comp_s2_full_pred_1_targets_1, comp_s2_full_pred_1_targets_0},
      jalr_target:       comp_s2_full_pred_1_jalr_target,
      offsets:           {comp_s2_full_pred_1_offsets_1, comp_s2_full_pred_1_offsets_0},
      fall_through_addr: comp_s2_full_pred_1_fallThroughAddr,
      fall_through_err:  comp_s2_full_pred_1_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s2_full_pred_1_is_br_sharing,
      hit:               comp_s2_full_pred_1_hit};
  assign s2_pred_w[2] = '{
      br_taken_mask:     {comp_s2_full_pred_2_br_taken_mask_1, comp_s2_full_pred_2_br_taken_mask_0},
      slot_valids:       {comp_s2_full_pred_2_slot_valids_1, comp_s2_full_pred_2_slot_valids_0},
      targets:           {comp_s2_full_pred_2_targets_1, comp_s2_full_pred_2_targets_0},
      jalr_target:       comp_s2_full_pred_2_jalr_target,
      offsets:           {comp_s2_full_pred_2_offsets_1, comp_s2_full_pred_2_offsets_0},
      fall_through_addr: comp_s2_full_pred_2_fallThroughAddr,
      fall_through_err:  comp_s2_full_pred_2_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s2_full_pred_2_is_br_sharing,
      hit:               comp_s2_full_pred_2_hit};
  assign s2_pred_w[3] = '{
      br_taken_mask:     {comp_s2_full_pred_3_br_taken_mask_1, comp_s2_full_pred_3_br_taken_mask_0},
      slot_valids:       {comp_s2_full_pred_3_slot_valids_1, comp_s2_full_pred_3_slot_valids_0},
      targets:           {comp_s2_full_pred_3_targets_1, comp_s2_full_pred_3_targets_0},
      jalr_target:       comp_s2_full_pred_3_jalr_target,
      offsets:           {comp_s2_full_pred_3_offsets_1, comp_s2_full_pred_3_offsets_0},
      fall_through_addr: comp_s2_full_pred_3_fallThroughAddr,
      fall_through_err:  comp_s2_full_pred_3_fallThroughErr,
      multi_hit:         1'b0,
      is_br_sharing:     comp_s2_full_pred_3_is_br_sharing,
      hit:               comp_s2_full_pred_3_hit};

  assign s3_pred_w[0] = '{
      br_taken_mask:     {comp_s3_full_pred_0_br_taken_mask_1, comp_s3_full_pred_0_br_taken_mask_0},
      slot_valids:       {comp_s3_full_pred_0_slot_valids_1, comp_s3_full_pred_0_slot_valids_0},
      targets:           {comp_s3_full_pred_0_targets_1, comp_s3_full_pred_0_targets_0},
      jalr_target:       comp_s3_full_pred_0_jalr_target,
      offsets:           {comp_s3_full_pred_0_offsets_1, comp_s3_full_pred_0_offsets_0},
      fall_through_addr: comp_s3_full_pred_0_fallThroughAddr,
      fall_through_err:  comp_s3_full_pred_0_fallThroughErr,
      multi_hit:         comp_s3_full_pred_0_multiHit,
      is_br_sharing:     comp_s3_full_pred_0_is_br_sharing,
      hit:               comp_s3_full_pred_0_hit};
  assign s3_pred_w[1] = '{
      br_taken_mask:     {comp_s3_full_pred_1_br_taken_mask_1, comp_s3_full_pred_1_br_taken_mask_0},
      slot_valids:       {comp_s3_full_pred_1_slot_valids_1, comp_s3_full_pred_1_slot_valids_0},
      targets:           {comp_s3_full_pred_1_targets_1, comp_s3_full_pred_1_targets_0},
      jalr_target:       comp_s3_full_pred_1_jalr_target,
      offsets:           {comp_s3_full_pred_1_offsets_1, comp_s3_full_pred_1_offsets_0},
      fall_through_addr: comp_s3_full_pred_1_fallThroughAddr,
      fall_through_err:  comp_s3_full_pred_1_fallThroughErr,
      multi_hit:         comp_s3_full_pred_1_multiHit,
      is_br_sharing:     comp_s3_full_pred_1_is_br_sharing,
      hit:               comp_s3_full_pred_1_hit};
  assign s3_pred_w[2] = '{
      br_taken_mask:     {comp_s3_full_pred_2_br_taken_mask_1, comp_s3_full_pred_2_br_taken_mask_0},
      slot_valids:       {comp_s3_full_pred_2_slot_valids_1, comp_s3_full_pred_2_slot_valids_0},
      targets:           {comp_s3_full_pred_2_targets_1, comp_s3_full_pred_2_targets_0},
      jalr_target:       comp_s3_full_pred_2_jalr_target,
      offsets:           {comp_s3_full_pred_2_offsets_1, comp_s3_full_pred_2_offsets_0},
      fall_through_addr: comp_s3_full_pred_2_fallThroughAddr,
      fall_through_err:  comp_s3_full_pred_2_fallThroughErr,
      multi_hit:         comp_s3_full_pred_2_multiHit,
      is_br_sharing:     comp_s3_full_pred_2_is_br_sharing,
      hit:               comp_s3_full_pred_2_hit};
  assign s3_pred_w[3] = '{
      br_taken_mask:     {comp_s3_full_pred_3_br_taken_mask_1, comp_s3_full_pred_3_br_taken_mask_0},
      slot_valids:       {comp_s3_full_pred_3_slot_valids_1, comp_s3_full_pred_3_slot_valids_0},
      targets:           {comp_s3_full_pred_3_targets_1, comp_s3_full_pred_3_targets_0},
      jalr_target:       comp_s3_full_pred_3_jalr_target,
      offsets:           {comp_s3_full_pred_3_offsets_1, comp_s3_full_pred_3_offsets_0},
      fall_through_addr: comp_s3_full_pred_3_fallThroughAddr,
      fall_through_err:  comp_s3_full_pred_3_fallThroughErr,
      multi_hit:         comp_s3_full_pred_3_multiHit,
      is_br_sharing:     comp_s3_full_pred_3_is_br_sharing,
      hit:               comp_s3_full_pred_3_hit};
  // END GENERATED(pred_pack)

  assign s1_pc_w = '{comp_s1_pc_0, comp_s1_pc_1, comp_s1_pc_2, comp_s1_pc_3};
  assign s2_pc_w = '{comp_s2_pc_0, comp_s2_pc_1, comp_s2_pc_2, comp_s2_pc_3};
  assign s3_pc_w = '{comp_s3_pc_0, comp_s3_pc_1, comp_s3_pc_2, comp_s3_pc_3};

  // ---- FTQ 重定向包：顶层散装端口 → redirect_bundle_t ---------------------
  assign rdr_in_w = '{
      shift:            io_ftq_to_bpu_redirect_bits_cfiUpdate_shift,
      add_into_hist:    io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist,
      taken:            io_ftq_to_bpu_redirect_bits_cfiUpdate_taken,
      hist_ptr:         '{flag:  io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag,
                          value: io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value},
      target:           io_ftq_to_bpu_redirect_bits_cfiUpdate_target,
      br_hit:           io_ftq_to_bpu_redirect_bits_cfiUpdate_br_hit,
      jr_hit:           io_ftq_to_bpu_redirect_bits_cfiUpdate_jr_hit,
      sc_hit:           io_ftq_to_bpu_redirect_bits_cfiUpdate_sc_hit,
      pd_is_ret:        io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRet,
      debug_is_ctrl:    io_ftq_to_bpu_redirect_bits_debugIsCtrl,
      debug_is_mem_vio: io_ftq_to_bpu_redirect_bits_debugIsMemVio,
      btb_miss_bubble:  io_ftq_to_bpu_redirect_bits_BTBMissBubble,
      level:            io_ftq_to_bpu_redirect_bits_level,
      cfi_pc:           io_ftq_to_bpu_redirect_bits_cfiUpdate_pc,
      pd_valid:         io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_valid,
      pd_is_rvc:        io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isRVC,
      pd_is_call:       io_ftq_to_bpu_redirect_bits_cfiUpdate_pd_isCall,
      ssp:              io_ftq_to_bpu_redirect_bits_cfiUpdate_ssp,
      sctr:             io_ftq_to_bpu_redirect_bits_cfiUpdate_sctr,
      tosw_flag:        io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_flag,
      tosw_value:       io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSW_value,
      tosr_flag:        io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_flag,
      tosr_value:       io_ftq_to_bpu_redirect_bits_cfiUpdate_TOSR_value,
      nos_flag:         io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_flag,
      nos_value:        io_ftq_to_bpu_redirect_bits_cfiUpdate_NOS_value};

  // 锁存后的重定向包 → Composer 的散装 io_redirect_bits_* 端口
  assign rdr_q_cfiUpdate_shift        = rdr_q_w.shift;
  assign rdr_q_cfiUpdate_addIntoHist  = rdr_q_w.add_into_hist;
  assign rdr_q_cfiUpdate_taken        = rdr_q_w.taken;
  assign rdr_q_cfiUpdate_histPtr_flag = rdr_q_w.hist_ptr.flag;
  assign rdr_q_cfiUpdate_histPtr_value= rdr_q_w.hist_ptr.value;
  assign rdr_q_cfiUpdate_target       = rdr_q_w.target;
  assign rdr_q_cfiUpdate_br_hit       = rdr_q_w.br_hit;
  assign rdr_q_cfiUpdate_jr_hit       = rdr_q_w.jr_hit;
  assign rdr_q_cfiUpdate_sc_hit       = rdr_q_w.sc_hit;
  assign rdr_q_cfiUpdate_pd_isRet     = rdr_q_w.pd_is_ret;
  assign rdr_q_debugIsCtrl            = rdr_q_w.debug_is_ctrl;
  assign rdr_q_debugIsMemVio          = rdr_q_w.debug_is_mem_vio;
  assign rdr_q_BTBMissBubble          = rdr_q_w.btb_miss_bubble;
  assign rdr_q_level                  = rdr_q_w.level;
  assign rdr_q_cfiUpdate_pc           = rdr_q_w.cfi_pc;
  assign rdr_q_cfiUpdate_pd_valid     = rdr_q_w.pd_valid;
  assign rdr_q_cfiUpdate_pd_isRVC     = rdr_q_w.pd_is_rvc;
  assign rdr_q_cfiUpdate_pd_isCall    = rdr_q_w.pd_is_call;
  assign rdr_q_cfiUpdate_ssp          = rdr_q_w.ssp;
  assign rdr_q_cfiUpdate_sctr         = rdr_q_w.sctr;
  assign rdr_q_cfiUpdate_TOSW_flag    = rdr_q_w.tosw_flag;
  assign rdr_q_cfiUpdate_TOSW_value   = rdr_q_w.tosw_value;
  assign rdr_q_cfiUpdate_TOSR_flag    = rdr_q_w.tosr_flag;
  assign rdr_q_cfiUpdate_TOSR_value   = rdr_q_w.tosr_value;
  assign rdr_q_cfiUpdate_NOS_flag     = rdr_q_w.nos_flag;
  assign rdr_q_cfiUpdate_NOS_value    = rdr_q_w.nos_value;

  // 注意：golden 顶层**没有** update_bits_spec_info_histPtr_flag 这个端口 ——
  // getHist(ptr) 只用 ptr.value（环形缓冲的读出与绕圈标志无关），flag 被 firtool
  // 整根消掉了。这里同样钉 0，不新增端口。
  assign upd_hp_w = '{flag: 1'b0,
                      value: io_ftq_to_bpu_update_bits_spec_info_histPtr_value};

  // ---- ctrl 打一拍（golden: DelayN(io.ctrl, 1)） --------------------------
  DelayN ctrl_delay (
    .clock            (clock),
    .io_in_ubtb_enable(io_ctrl_ubtb_enable),
    .io_in_btb_enable (io_ctrl_btb_enable),
    .io_in_tage_enable(io_ctrl_tage_enable),
    .io_in_sc_enable  (io_ctrl_sc_enable),
    .io_in_ras_enable (io_ctrl_ras_enable),
    .io_out_ubtb_enable(ctrl_q_ubtb_enable),
    .io_out_btb_enable (ctrl_q_btb_enable),
    .io_out_tage_enable(ctrl_q_tage_enable),
    .io_out_sc_enable  (ctrl_q_sc_enable),
    .io_out_ras_enable (ctrl_q_ras_enable)
  );

  // ---- 可读核 -------------------------------------------------------------
  xs_Predictor_core u_core (
    .clock                (clock),
    .reset                (reset),
    .io_reset_vector      (io_reset_vector),
    .s1_pc                (s1_pc_w),
    .s2_pc                (s2_pc_w),
    .s3_pc                (s3_pc_w),
    .s1_pred              (s1_pred_w),
    .s2_pred              (s2_pred_w),
    .s3_pred              (s3_pred_w),
    .comp_s1_ready        (comp_s1_ready_w),
    .comp_s2_ready        (comp_s2_ready_w),
    .comp_s3_ready        (comp_s3_ready_w),
    .ftq_resp_ready       (io_bpu_to_ftq_resp_ready),
    .ftq_enq_ptr_flag     (io_ftq_to_bpu_enq_ptr_flag),
    .ftq_enq_ptr_value    (io_ftq_to_bpu_enq_ptr_value),
    .ftq_redirect_from_ifu(io_ftq_to_bpu_redirctFromIFU),
    .ftq_redirect_valid   (io_ftq_to_bpu_redirect_valid),
    .ftq_update_valid     (io_ftq_to_bpu_update_valid),
    .ftq_update_hist_ptr  (upd_hp_w),
    .ftq_update_pc        (io_ftq_to_bpu_update_bits_pc),
    .comp_perf            (comp_perf_w),
    .redirect_in          (rdr_in_w),
    .s0_pc_sel            (s0_pc_w),
    .s0_folded_gh         (s0_fg_w),
    .s0_ghist_ptr         (s0_gp_w),
    .s0_last_br_num_oh    (s0_bn_w),
    .s1_folded_gh_o       (s1_fg_w),
    .s0_ghist             (s0_ghist_w),
    .update_ghist         (update_ghist_w),
    .s0_fire              (s0_fire_w),
    .s1_fire              (s1_fire_w),
    .s2_fire              (s2_fire_w),
    .s3_fire              (s3_fire_w),
    .s2_redirect          (s2_redirect_w),
    .s3_redirect          (s3_redirect_w),
    .redirect_from_ifu_q  (redirect_from_ifu_q_w),
    .do_redirect_valid    (do_redirect_valid_w),
    .do_redirect_bits     (rdr_q_w),
    .bpu_resp_valid       (io_bpu_to_ftq_resp_valid),
    .to_ftq_s2_valid      (io_bpu_to_ftq_resp_bits_s2_valid_3),
    .to_ftq_s3_valid      (io_bpu_to_ftq_resp_bits_s3_valid_3),
    .s3_ghist_ptr_o       (s3_gp_o_w),
    .s2_ftq_idx_flag      (io_bpu_to_ftq_resp_bits_s2_ftq_idx_flag),
    .s2_ftq_idx_value     (io_bpu_to_ftq_resp_bits_s2_ftq_idx_value),
    .s3_ftq_idx_flag      (io_bpu_to_ftq_resp_bits_s3_ftq_idx_flag),
    .s3_ftq_idx_value     (io_bpu_to_ftq_resp_bits_s3_ftq_idx_value),
    .topdown_info_reasons (topdown_reasons_w),
    .pred_cycle           (pred_cycle_w),
    .update_pc_seg        (update_pc_seg_w),
    .perf_out             (perf_out_w)
  );

  // ---- 顶层输出（本模块自己算的那 15 根；其余 110 根由 Composer 直连） ----
  assign io_bpu_to_ftq_resp_bits_s3_valid_0       = io_bpu_to_ftq_resp_bits_s3_valid_3;
  assign io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 = s2_redirect_w[3];
  assign io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 = s3_redirect_w[3];
  assign io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag  = s3_gp_o_w.flag;
  assign io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value = s3_gp_o_w.value;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_0_predCycle = pred_cycle_w;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_0_predCycle = pred_cycle_w;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_0_predCycle = pred_cycle_w;
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_1  = topdown_reasons_w[1];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_2  = topdown_reasons_w[2];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_3  = topdown_reasons_w[3];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_4  = topdown_reasons_w[4];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_5  = topdown_reasons_w[5];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_6  = topdown_reasons_w[6];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_7  = topdown_reasons_w[7];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_8  = topdown_reasons_w[8];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_9  = topdown_reasons_w[9];
  assign io_bpu_to_ftq_resp_bits_topdown_info_reasons_12 = topdown_reasons_w[12];
  assign io_perf_0_value = perf_out_w[0];
  assign io_perf_1_value = perf_out_w[1];
  assign io_perf_2_value = perf_out_w[2];
  assign io_perf_3_value = perf_out_w[3];
  assign io_perf_4_value = perf_out_w[4];
  assign io_perf_5_value = perf_out_w[5];
  assign io_perf_6_value = perf_out_w[6];

  // ---- Composer 预测包直通顶层输出（golden 用 assign 接的那 40 根，脚本生成） ----
  // BEGIN GENERATED(passthru)
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_0 = comp_s1_full_pred_3_br_taken_mask_0;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_br_taken_mask_1 = comp_s1_full_pred_3_br_taken_mask_1;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughAddr = comp_s1_full_pred_3_fallThroughAddr;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_fallThroughErr  = comp_s1_full_pred_3_fallThroughErr;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_hit             = comp_s1_full_pred_3_hit;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_is_br_sharing   = comp_s1_full_pred_3_is_br_sharing;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_0       = comp_s1_full_pred_3_offsets_0;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_offsets_1       = comp_s1_full_pred_3_offsets_1;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_0   = comp_s1_full_pred_3_slot_valids_0;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_slot_valids_1   = comp_s1_full_pred_3_slot_valids_1;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_0       = comp_s1_full_pred_3_targets_0;
  assign io_bpu_to_ftq_resp_bits_s1_full_pred_3_targets_1       = comp_s1_full_pred_3_targets_1;
  assign io_bpu_to_ftq_resp_bits_s1_pc_3                        = comp_s1_pc_3;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_0 = comp_s2_full_pred_3_br_taken_mask_0;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_br_taken_mask_1 = comp_s2_full_pred_3_br_taken_mask_1;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughAddr = comp_s2_full_pred_3_fallThroughAddr;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_fallThroughErr  = comp_s2_full_pred_3_fallThroughErr;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_hit             = comp_s2_full_pred_3_hit;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_is_br_sharing   = comp_s2_full_pred_3_is_br_sharing;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_0       = comp_s2_full_pred_3_offsets_0;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_offsets_1       = comp_s2_full_pred_3_offsets_1;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_0   = comp_s2_full_pred_3_slot_valids_0;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_slot_valids_1   = comp_s2_full_pred_3_slot_valids_1;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_0       = comp_s2_full_pred_3_targets_0;
  assign io_bpu_to_ftq_resp_bits_s2_full_pred_3_targets_1       = comp_s2_full_pred_3_targets_1;
  assign io_bpu_to_ftq_resp_bits_s2_pc_3                        = comp_s2_pc_3;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_0 = comp_s3_full_pred_3_br_taken_mask_0;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_br_taken_mask_1 = comp_s3_full_pred_3_br_taken_mask_1;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughAddr = comp_s3_full_pred_3_fallThroughAddr;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_fallThroughErr  = comp_s3_full_pred_3_fallThroughErr;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_hit             = comp_s3_full_pred_3_hit;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_is_br_sharing   = comp_s3_full_pred_3_is_br_sharing;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_0       = comp_s3_full_pred_3_offsets_0;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_offsets_1       = comp_s3_full_pred_3_offsets_1;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_0   = comp_s3_full_pred_3_slot_valids_0;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_slot_valids_1   = comp_s3_full_pred_3_slot_valids_1;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_0       = comp_s3_full_pred_3_targets_0;
  assign io_bpu_to_ftq_resp_bits_s3_full_pred_3_targets_1       = comp_s3_full_pred_3_targets_1;
  assign io_bpu_to_ftq_resp_bits_s3_pc_0                        = comp_s3_pc_0;
  assign io_bpu_to_ftq_resp_bits_s3_pc_3                        = comp_s3_pc_3;
  // END GENERATED(passthru)

  // ---- Composer：五个预测器 + 457 根 MBIST 直通（脚本生成） ---------------
  // BEGIN GENERATED(composer_inst)
  Composer predictors (
    .clock                                            (clock),
    .reset                                            (reset),
    .io_reset_vector                                  (io_reset_vector),
    .io_in_bits_s0_pc_0                               (s0_pc_w[0]),
    .io_in_bits_s0_pc_1                               (s0_pc_w[1]),
    .io_in_bits_s0_pc_2                               (s0_pc_w[2]),
    .io_in_bits_s0_pc_3                               (s0_pc_w[3]),
    .io_in_bits_folded_hist_1_hist_17_folded_hist     (s0_fg_w[1][17][10:0]),
    .io_in_bits_folded_hist_1_hist_16_folded_hist     (s0_fg_w[1][16][10:0]),
    .io_in_bits_folded_hist_1_hist_15_folded_hist     (s0_fg_w[1][15][6:0]),
    .io_in_bits_folded_hist_1_hist_14_folded_hist     (s0_fg_w[1][14][7:0]),
    .io_in_bits_folded_hist_1_hist_9_folded_hist      (s0_fg_w[1][9][6:0]),
    .io_in_bits_folded_hist_1_hist_8_folded_hist      (s0_fg_w[1][8][7:0]),
    .io_in_bits_folded_hist_1_hist_7_folded_hist      (s0_fg_w[1][7][6:0]),
    .io_in_bits_folded_hist_1_hist_5_folded_hist      (s0_fg_w[1][5][6:0]),
    .io_in_bits_folded_hist_1_hist_4_folded_hist      (s0_fg_w[1][4][7:0]),
    .io_in_bits_folded_hist_1_hist_3_folded_hist      (s0_fg_w[1][3][7:0]),
    .io_in_bits_folded_hist_1_hist_1_folded_hist      (s0_fg_w[1][1][10:0]),
    .io_in_bits_folded_hist_3_hist_12_folded_hist     (s0_fg_w[3][12][3:0]),
    .io_in_bits_folded_hist_3_hist_11_folded_hist     (s0_fg_w[3][11][7:0]),
    .io_in_bits_folded_hist_3_hist_2_folded_hist      (s0_fg_w[3][2][7:0]),
    .io_in_bits_s1_folded_hist_3_hist_14_folded_hist  (s1_fg_w[3][14][7:0]),
    .io_in_bits_s1_folded_hist_3_hist_13_folded_hist  (s1_fg_w[3][13][8:0]),
    .io_in_bits_s1_folded_hist_3_hist_12_folded_hist  (s1_fg_w[3][12][3:0]),
    .io_in_bits_s1_folded_hist_3_hist_10_folded_hist  (s1_fg_w[3][10][8:0]),
    .io_in_bits_s1_folded_hist_3_hist_6_folded_hist   (s1_fg_w[3][6][8:0]),
    .io_in_bits_s1_folded_hist_3_hist_4_folded_hist   (s1_fg_w[3][4][7:0]),
    .io_in_bits_s1_folded_hist_3_hist_3_folded_hist   (s1_fg_w[3][3][7:0]),
    .io_in_bits_s1_folded_hist_3_hist_2_folded_hist   (s1_fg_w[3][2][7:0]),
    .io_in_bits_ghist                                 (s0_ghist_w),
    .io_out_s1_pc_0                                   (comp_s1_pc_0),
    .io_out_s1_pc_1                                   (comp_s1_pc_1),
    .io_out_s1_pc_2                                   (comp_s1_pc_2),
    .io_out_s1_pc_3                                   (comp_s1_pc_3),
    .io_out_s1_full_pred_0_br_taken_mask_0            (comp_s1_full_pred_0_br_taken_mask_0),
    .io_out_s1_full_pred_0_br_taken_mask_1            (comp_s1_full_pred_0_br_taken_mask_1),
    .io_out_s1_full_pred_0_slot_valids_0              (comp_s1_full_pred_0_slot_valids_0),
    .io_out_s1_full_pred_0_slot_valids_1              (comp_s1_full_pred_0_slot_valids_1),
    .io_out_s1_full_pred_0_targets_0                  (comp_s1_full_pred_0_targets_0),
    .io_out_s1_full_pred_0_targets_1                  (comp_s1_full_pred_0_targets_1),
    .io_out_s1_full_pred_0_jalr_target                (comp_s1_full_pred_0_jalr_target),
    .io_out_s1_full_pred_0_offsets_0                  (comp_s1_full_pred_0_offsets_0),
    .io_out_s1_full_pred_0_offsets_1                  (comp_s1_full_pred_0_offsets_1),
    .io_out_s1_full_pred_0_fallThroughAddr            (comp_s1_full_pred_0_fallThroughAddr),
    .io_out_s1_full_pred_0_fallThroughErr             (comp_s1_full_pred_0_fallThroughErr),
    .io_out_s1_full_pred_0_is_jal                     (comp_s1_full_pred_0_is_jal),
    .io_out_s1_full_pred_0_is_jalr                    (comp_s1_full_pred_0_is_jalr),
    .io_out_s1_full_pred_0_is_call                    (comp_s1_full_pred_0_is_call),
    .io_out_s1_full_pred_0_is_ret                     (comp_s1_full_pred_0_is_ret),
    .io_out_s1_full_pred_0_last_may_be_rvi_call       (comp_s1_full_pred_0_last_may_be_rvi_call),
    .io_out_s1_full_pred_0_is_br_sharing              (comp_s1_full_pred_0_is_br_sharing),
    .io_out_s1_full_pred_0_hit                        (comp_s1_full_pred_0_hit),
    .io_out_s1_full_pred_1_br_taken_mask_0            (comp_s1_full_pred_1_br_taken_mask_0),
    .io_out_s1_full_pred_1_br_taken_mask_1            (comp_s1_full_pred_1_br_taken_mask_1),
    .io_out_s1_full_pred_1_slot_valids_0              (comp_s1_full_pred_1_slot_valids_0),
    .io_out_s1_full_pred_1_slot_valids_1              (comp_s1_full_pred_1_slot_valids_1),
    .io_out_s1_full_pred_1_targets_0                  (comp_s1_full_pred_1_targets_0),
    .io_out_s1_full_pred_1_targets_1                  (comp_s1_full_pred_1_targets_1),
    .io_out_s1_full_pred_1_jalr_target                (comp_s1_full_pred_1_jalr_target),
    .io_out_s1_full_pred_1_offsets_0                  (comp_s1_full_pred_1_offsets_0),
    .io_out_s1_full_pred_1_offsets_1                  (comp_s1_full_pred_1_offsets_1),
    .io_out_s1_full_pred_1_fallThroughAddr            (comp_s1_full_pred_1_fallThroughAddr),
    .io_out_s1_full_pred_1_fallThroughErr             (comp_s1_full_pred_1_fallThroughErr),
    .io_out_s1_full_pred_1_is_jal                     (comp_s1_full_pred_1_is_jal),
    .io_out_s1_full_pred_1_is_jalr                    (comp_s1_full_pred_1_is_jalr),
    .io_out_s1_full_pred_1_is_call                    (comp_s1_full_pred_1_is_call),
    .io_out_s1_full_pred_1_is_ret                     (comp_s1_full_pred_1_is_ret),
    .io_out_s1_full_pred_1_last_may_be_rvi_call       (comp_s1_full_pred_1_last_may_be_rvi_call),
    .io_out_s1_full_pred_1_is_br_sharing              (comp_s1_full_pred_1_is_br_sharing),
    .io_out_s1_full_pred_1_hit                        (comp_s1_full_pred_1_hit),
    .io_out_s1_full_pred_2_br_taken_mask_0            (comp_s1_full_pred_2_br_taken_mask_0),
    .io_out_s1_full_pred_2_br_taken_mask_1            (comp_s1_full_pred_2_br_taken_mask_1),
    .io_out_s1_full_pred_2_slot_valids_0              (comp_s1_full_pred_2_slot_valids_0),
    .io_out_s1_full_pred_2_slot_valids_1              (comp_s1_full_pred_2_slot_valids_1),
    .io_out_s1_full_pred_2_targets_0                  (comp_s1_full_pred_2_targets_0),
    .io_out_s1_full_pred_2_targets_1                  (comp_s1_full_pred_2_targets_1),
    .io_out_s1_full_pred_2_jalr_target                (comp_s1_full_pred_2_jalr_target),
    .io_out_s1_full_pred_2_offsets_0                  (comp_s1_full_pred_2_offsets_0),
    .io_out_s1_full_pred_2_offsets_1                  (comp_s1_full_pred_2_offsets_1),
    .io_out_s1_full_pred_2_fallThroughAddr            (comp_s1_full_pred_2_fallThroughAddr),
    .io_out_s1_full_pred_2_fallThroughErr             (comp_s1_full_pred_2_fallThroughErr),
    .io_out_s1_full_pred_2_is_jal                     (comp_s1_full_pred_2_is_jal),
    .io_out_s1_full_pred_2_is_jalr                    (comp_s1_full_pred_2_is_jalr),
    .io_out_s1_full_pred_2_is_call                    (comp_s1_full_pred_2_is_call),
    .io_out_s1_full_pred_2_is_ret                     (comp_s1_full_pred_2_is_ret),
    .io_out_s1_full_pred_2_last_may_be_rvi_call       (comp_s1_full_pred_2_last_may_be_rvi_call),
    .io_out_s1_full_pred_2_is_br_sharing              (comp_s1_full_pred_2_is_br_sharing),
    .io_out_s1_full_pred_2_hit                        (comp_s1_full_pred_2_hit),
    .io_out_s1_full_pred_3_br_taken_mask_0            (comp_s1_full_pred_3_br_taken_mask_0),
    .io_out_s1_full_pred_3_br_taken_mask_1            (comp_s1_full_pred_3_br_taken_mask_1),
    .io_out_s1_full_pred_3_slot_valids_0              (comp_s1_full_pred_3_slot_valids_0),
    .io_out_s1_full_pred_3_slot_valids_1              (comp_s1_full_pred_3_slot_valids_1),
    .io_out_s1_full_pred_3_targets_0                  (comp_s1_full_pred_3_targets_0),
    .io_out_s1_full_pred_3_targets_1                  (comp_s1_full_pred_3_targets_1),
    .io_out_s1_full_pred_3_jalr_target                (comp_s1_full_pred_3_jalr_target),
    .io_out_s1_full_pred_3_offsets_0                  (comp_s1_full_pred_3_offsets_0),
    .io_out_s1_full_pred_3_offsets_1                  (comp_s1_full_pred_3_offsets_1),
    .io_out_s1_full_pred_3_fallThroughAddr            (comp_s1_full_pred_3_fallThroughAddr),
    .io_out_s1_full_pred_3_fallThroughErr             (comp_s1_full_pred_3_fallThroughErr),
    .io_out_s1_full_pred_3_is_jal                     (comp_s1_full_pred_3_is_jal),
    .io_out_s1_full_pred_3_is_jalr                    (comp_s1_full_pred_3_is_jalr),
    .io_out_s1_full_pred_3_is_call                    (comp_s1_full_pred_3_is_call),
    .io_out_s1_full_pred_3_is_ret                     (comp_s1_full_pred_3_is_ret),
    .io_out_s1_full_pred_3_last_may_be_rvi_call       (comp_s1_full_pred_3_last_may_be_rvi_call),
    .io_out_s1_full_pred_3_is_br_sharing              (comp_s1_full_pred_3_is_br_sharing),
    .io_out_s1_full_pred_3_hit                        (comp_s1_full_pred_3_hit),
    .io_out_s2_pc_0                                   (comp_s2_pc_0),
    .io_out_s2_pc_1                                   (comp_s2_pc_1),
    .io_out_s2_pc_2                                   (comp_s2_pc_2),
    .io_out_s2_pc_3                                   (comp_s2_pc_3),
    .io_out_s2_full_pred_0_br_taken_mask_0            (comp_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1            (comp_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0              (comp_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1              (comp_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0                  (comp_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1                  (comp_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target                (comp_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0                  (comp_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1                  (comp_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr            (comp_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr             (comp_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal                     (comp_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr                    (comp_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call                    (comp_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret                     (comp_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call       (comp_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing              (comp_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit                        (comp_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0            (comp_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1            (comp_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0              (comp_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1              (comp_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0                  (comp_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1                  (comp_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target                (comp_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0                  (comp_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1                  (comp_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr            (comp_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr             (comp_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal                     (comp_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr                    (comp_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call                    (comp_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret                     (comp_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call       (comp_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing              (comp_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit                        (comp_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0            (comp_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1            (comp_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0              (comp_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1              (comp_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0                  (comp_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1                  (comp_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target                (comp_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0                  (comp_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1                  (comp_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr            (comp_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr             (comp_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal                     (comp_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr                    (comp_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call                    (comp_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret                     (comp_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call       (comp_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing              (comp_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit                        (comp_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0            (comp_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1            (comp_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0              (comp_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1              (comp_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0                  (comp_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1                  (comp_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target                (comp_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0                  (comp_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1                  (comp_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr            (comp_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr             (comp_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal                     (comp_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr                    (comp_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call                    (comp_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret                     (comp_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call       (comp_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing              (comp_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit                        (comp_s2_full_pred_3_hit),
    .io_out_s3_pc_0                                   (comp_s3_pc_0),
    .io_out_s3_pc_1                                   (comp_s3_pc_1),
    .io_out_s3_pc_2                                   (comp_s3_pc_2),
    .io_out_s3_pc_3                                   (comp_s3_pc_3),
    .io_out_s3_full_pred_0_br_taken_mask_0            (comp_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1            (comp_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0              (comp_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1              (comp_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0                  (comp_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1                  (comp_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target                (comp_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0                  (comp_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1                  (comp_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr            (comp_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr             (comp_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit                   (comp_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal                     (comp_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr                    (comp_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call                    (comp_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret                     (comp_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call       (comp_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing              (comp_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit                        (comp_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0            (comp_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1            (comp_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0              (comp_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1              (comp_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0                  (comp_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1                  (comp_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target                (comp_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0                  (comp_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1                  (comp_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr            (comp_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr             (comp_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit                   (comp_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal                     (comp_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr                    (comp_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call                    (comp_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret                     (comp_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call       (comp_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing              (comp_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit                        (comp_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0            (comp_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1            (comp_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0              (comp_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1              (comp_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0                  (comp_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1                  (comp_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target                (comp_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0                  (comp_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1                  (comp_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr            (comp_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr             (comp_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit                   (comp_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal                     (comp_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr                    (comp_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call                    (comp_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret                     (comp_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call       (comp_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing              (comp_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit                        (comp_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0            (comp_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1            (comp_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0              (comp_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1              (comp_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0                  (comp_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1                  (comp_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target                (comp_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0                  (comp_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1                  (comp_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr            (comp_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr             (comp_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit                   (comp_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal                     (comp_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr                    (comp_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call                    (comp_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret                     (comp_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call       (comp_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing              (comp_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit                        (comp_s3_full_pred_3_hit),
    .io_out_last_stage_meta                           (io_bpu_to_ftq_resp_bits_last_stage_meta),
    .io_out_last_stage_spec_info_ssp                  (io_bpu_to_ftq_resp_bits_last_stage_spec_info_ssp),
    .io_out_last_stage_spec_info_sctr                 (io_bpu_to_ftq_resp_bits_last_stage_spec_info_sctr),
    .io_out_last_stage_spec_info_TOSW_flag            (io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_flag),
    .io_out_last_stage_spec_info_TOSW_value           (io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSW_value),
    .io_out_last_stage_spec_info_TOSR_flag            (io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_flag),
    .io_out_last_stage_spec_info_TOSR_value           (io_bpu_to_ftq_resp_bits_last_stage_spec_info_TOSR_value),
    .io_out_last_stage_spec_info_NOS_flag             (io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_flag),
    .io_out_last_stage_spec_info_NOS_value            (io_bpu_to_ftq_resp_bits_last_stage_spec_info_NOS_value),
    .io_out_last_stage_spec_info_topAddr              (io_bpu_to_ftq_resp_bits_last_stage_spec_info_topAddr),
    .io_out_last_stage_spec_info_sc_disagree_0        (io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1        (io_bpu_to_ftq_resp_bits_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall               (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet                (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr               (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid                (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset     (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing    (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid      (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower      (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat    (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset      (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing     (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid       (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower       (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat     (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr              (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry                (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0        (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1        (io_bpu_to_ftq_resp_bits_last_stage_ftb_entry_strong_bias_1),
    .io_ctrl_ubtb_enable                              (ctrl_q_ubtb_enable),
    .io_ctrl_btb_enable                               (ctrl_q_btb_enable),
    .io_ctrl_tage_enable                              (ctrl_q_tage_enable),
    .io_ctrl_sc_enable                                (ctrl_q_sc_enable),
    .io_ctrl_ras_enable                               (ctrl_q_ras_enable),
    .io_s0_fire_0                                     (s0_fire_w[0]),
    .io_s0_fire_1                                     (s0_fire_w[1]),
    .io_s0_fire_2                                     (s0_fire_w[2]),
    .io_s0_fire_3                                     (s0_fire_w[3]),
    .io_s1_fire_0                                     (s1_fire_w[0]),
    .io_s1_fire_1                                     (s1_fire_w[1]),
    .io_s1_fire_2                                     (s1_fire_w[2]),
    .io_s1_fire_3                                     (s1_fire_w[3]),
    .io_s2_fire_0                                     (s2_fire_w[0]),
    .io_s2_fire_1                                     (s2_fire_w[1]),
    .io_s2_fire_2                                     (s2_fire_w[2]),
    .io_s2_fire_3                                     (s2_fire_w[3]),
    .io_s3_fire_0                                     (s3_fire_w[0]),
    .io_s3_fire_2                                     (s3_fire_w[2]),
    .io_s3_redirect_2                                 (s3_redirect_w[2]),
    .io_s1_ready                                      (comp_s1_ready_w),
    .io_update_valid                                  (io_ftq_to_bpu_update_valid),
    .io_update_bits_pc                                (update_pc_seg_w),
    .io_update_bits_ftb_entry_isCall                  (io_ftq_to_bpu_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet                   (io_ftq_to_bpu_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr                  (io_ftq_to_bpu_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid                   (io_ftq_to_bpu_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset        (io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing       (io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid         (io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower         (io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat       (io_ftq_to_bpu_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset         (io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing        (io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid          (io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower          (io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat        (io_ftq_to_bpu_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr                 (io_ftq_to_bpu_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry                   (io_ftq_to_bpu_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call    (io_ftq_to_bpu_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0           (io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1           (io_ftq_to_bpu_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_cfi_idx_valid                     (io_ftq_to_bpu_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits                      (io_ftq_to_bpu_update_bits_cfi_idx_bits),
    .io_update_bits_br_taken_mask_0                   (io_ftq_to_bpu_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1                   (io_ftq_to_bpu_update_bits_br_taken_mask_1),
    .io_update_bits_jmp_taken                         (io_ftq_to_bpu_update_bits_jmp_taken),
    .io_update_bits_mispred_mask_0                    (io_ftq_to_bpu_update_bits_mispred_mask_0),
    .io_update_bits_mispred_mask_1                    (io_ftq_to_bpu_update_bits_mispred_mask_1),
    .io_update_bits_mispred_mask_2                    (io_ftq_to_bpu_update_bits_mispred_mask_2),
    .io_update_bits_false_hit                         (io_ftq_to_bpu_update_bits_false_hit),
    .io_update_bits_old_entry                         (io_ftq_to_bpu_update_bits_old_entry),
    .io_update_bits_meta                              (io_ftq_to_bpu_update_bits_meta),
    .io_update_bits_full_target                       (io_ftq_to_bpu_update_bits_full_target),
    .io_update_bits_ghist                             (update_ghist_w),
    .io_redirect_valid                                (do_redirect_valid_w),
    .io_redirect_bits_level                           (rdr_q_level),
    .io_redirect_bits_cfiUpdate_pc                    (rdr_q_cfiUpdate_pc),
    .io_redirect_bits_cfiUpdate_pd_valid              (rdr_q_cfiUpdate_pd_valid),
    .io_redirect_bits_cfiUpdate_pd_isRVC              (rdr_q_cfiUpdate_pd_isRVC),
    .io_redirect_bits_cfiUpdate_pd_isCall             (rdr_q_cfiUpdate_pd_isCall),
    .io_redirect_bits_cfiUpdate_pd_isRet              (rdr_q_cfiUpdate_pd_isRet),
    .io_redirect_bits_cfiUpdate_ssp                   (rdr_q_cfiUpdate_ssp),
    .io_redirect_bits_cfiUpdate_sctr                  (rdr_q_cfiUpdate_sctr),
    .io_redirect_bits_cfiUpdate_TOSW_flag             (rdr_q_cfiUpdate_TOSW_flag),
    .io_redirect_bits_cfiUpdate_TOSW_value            (rdr_q_cfiUpdate_TOSW_value),
    .io_redirect_bits_cfiUpdate_TOSR_flag             (rdr_q_cfiUpdate_TOSR_flag),
    .io_redirect_bits_cfiUpdate_TOSR_value            (rdr_q_cfiUpdate_TOSR_value),
    .io_redirect_bits_cfiUpdate_NOS_flag              (rdr_q_cfiUpdate_NOS_flag),
    .io_redirect_bits_cfiUpdate_NOS_value             (rdr_q_cfiUpdate_NOS_value),
    .io_redirectFromIFU                               (redirect_from_ifu_q_w),
    .io_perf_0_value                                  (comp_perf_w[0]),
    .io_perf_1_value                                  (comp_perf_w[1]),
    .io_perf_2_value                                  (comp_perf_w[2]),
    .io_perf_3_value                                  (comp_perf_w[3]),
    .io_perf_4_value                                  (comp_perf_w[4]),
    .io_perf_5_value                                  (comp_perf_w[5]),
    .io_perf_6_value                                  (comp_perf_w[6]),
    .boreChildrenBd_bore_array                        (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                          (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                          (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                          (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                      (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                           (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                         (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                       (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                       (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                      (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                      (boreChildrenBd_bore_outdata),
    .boreChildrenBd_bore_1_array                      (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_1_all                        (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_1_req                        (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_1_ack                        (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_1_writeen                    (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_1_be                         (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_1_addr                       (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_1_indata                     (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_1_readen                     (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_1_addr_rd                    (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_1_outdata                    (boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_2_array                      (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_2_all                        (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_2_req                        (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_2_ack                        (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_2_writeen                    (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_2_be                         (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_2_addr                       (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_2_indata                     (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_2_readen                     (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_2_addr_rd                    (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_2_outdata                    (boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_3_array                      (boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_3_all                        (boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_3_req                        (boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_3_ack                        (boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_3_writeen                    (boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_3_be                         (boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_3_addr                       (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_3_indata                     (boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_3_readen                     (boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_3_addr_rd                    (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_3_outdata                    (boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_4_array                      (boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_4_all                        (boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_4_req                        (boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_4_ack                        (boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_4_writeen                    (boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_4_be                         (boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_4_addr                       (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_4_indata                     (boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_4_readen                     (boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_4_addr_rd                    (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_4_outdata                    (boreChildrenBd_bore_4_outdata),
    .boreChildrenBd_bore_5_array                      (boreChildrenBd_bore_5_array),
    .boreChildrenBd_bore_5_all                        (boreChildrenBd_bore_5_all),
    .boreChildrenBd_bore_5_req                        (boreChildrenBd_bore_5_req),
    .boreChildrenBd_bore_5_ack                        (boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_5_writeen                    (boreChildrenBd_bore_5_writeen),
    .boreChildrenBd_bore_5_be                         (boreChildrenBd_bore_5_be),
    .boreChildrenBd_bore_5_addr                       (boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_5_indata                     (boreChildrenBd_bore_5_indata),
    .boreChildrenBd_bore_5_readen                     (boreChildrenBd_bore_5_readen),
    .boreChildrenBd_bore_5_addr_rd                    (boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_5_outdata                    (boreChildrenBd_bore_5_outdata),
    .boreChildrenBd_bore_6_array                      (boreChildrenBd_bore_6_array),
    .boreChildrenBd_bore_6_all                        (boreChildrenBd_bore_6_all),
    .boreChildrenBd_bore_6_req                        (boreChildrenBd_bore_6_req),
    .boreChildrenBd_bore_6_ack                        (boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_6_writeen                    (boreChildrenBd_bore_6_writeen),
    .boreChildrenBd_bore_6_be                         (boreChildrenBd_bore_6_be),
    .boreChildrenBd_bore_6_addr                       (boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_6_indata                     (boreChildrenBd_bore_6_indata),
    .boreChildrenBd_bore_6_readen                     (boreChildrenBd_bore_6_readen),
    .boreChildrenBd_bore_6_addr_rd                    (boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_6_outdata                    (boreChildrenBd_bore_6_outdata),
    .boreChildrenBd_bore_7_array                      (boreChildrenBd_bore_7_array),
    .boreChildrenBd_bore_7_all                        (boreChildrenBd_bore_7_all),
    .boreChildrenBd_bore_7_req                        (boreChildrenBd_bore_7_req),
    .boreChildrenBd_bore_7_ack                        (boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_7_writeen                    (boreChildrenBd_bore_7_writeen),
    .boreChildrenBd_bore_7_be                         (boreChildrenBd_bore_7_be),
    .boreChildrenBd_bore_7_addr                       (boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_7_indata                     (boreChildrenBd_bore_7_indata),
    .boreChildrenBd_bore_7_readen                     (boreChildrenBd_bore_7_readen),
    .boreChildrenBd_bore_7_addr_rd                    (boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_7_outdata                    (boreChildrenBd_bore_7_outdata),
    .boreChildrenBd_bore_8_array                      (boreChildrenBd_bore_8_array),
    .boreChildrenBd_bore_8_all                        (boreChildrenBd_bore_8_all),
    .boreChildrenBd_bore_8_req                        (boreChildrenBd_bore_8_req),
    .boreChildrenBd_bore_8_ack                        (boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_8_writeen                    (boreChildrenBd_bore_8_writeen),
    .boreChildrenBd_bore_8_be                         (boreChildrenBd_bore_8_be),
    .boreChildrenBd_bore_8_addr                       (boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_8_indata                     (boreChildrenBd_bore_8_indata),
    .boreChildrenBd_bore_8_readen                     (boreChildrenBd_bore_8_readen),
    .boreChildrenBd_bore_8_addr_rd                    (boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_8_outdata                    (boreChildrenBd_bore_8_outdata),
    .boreChildrenBd_bore_9_array                      (boreChildrenBd_bore_9_array),
    .boreChildrenBd_bore_9_all                        (boreChildrenBd_bore_9_all),
    .boreChildrenBd_bore_9_req                        (boreChildrenBd_bore_9_req),
    .boreChildrenBd_bore_9_ack                        (boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_9_writeen                    (boreChildrenBd_bore_9_writeen),
    .boreChildrenBd_bore_9_be                         (boreChildrenBd_bore_9_be),
    .boreChildrenBd_bore_9_addr                       (boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_9_indata                     (boreChildrenBd_bore_9_indata),
    .boreChildrenBd_bore_9_readen                     (boreChildrenBd_bore_9_readen),
    .boreChildrenBd_bore_9_addr_rd                    (boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_9_outdata                    (boreChildrenBd_bore_9_outdata),
    .boreChildrenBd_bore_10_array                     (boreChildrenBd_bore_10_array),
    .boreChildrenBd_bore_10_all                       (boreChildrenBd_bore_10_all),
    .boreChildrenBd_bore_10_req                       (boreChildrenBd_bore_10_req),
    .boreChildrenBd_bore_10_ack                       (boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_10_writeen                   (boreChildrenBd_bore_10_writeen),
    .boreChildrenBd_bore_10_be                        (boreChildrenBd_bore_10_be),
    .boreChildrenBd_bore_10_addr                      (boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_10_indata                    (boreChildrenBd_bore_10_indata),
    .boreChildrenBd_bore_10_readen                    (boreChildrenBd_bore_10_readen),
    .boreChildrenBd_bore_10_addr_rd                   (boreChildrenBd_bore_10_addr_rd),
    .boreChildrenBd_bore_10_outdata                   (boreChildrenBd_bore_10_outdata),
    .sigFromSrams_bore_ram_hold                       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass                     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken                   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp                   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold                   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold                     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass                   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken                 (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk                  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp                 (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold                 (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold                     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass                   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken                 (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk                  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp                 (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold                 (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold                     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass                   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken                 (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk                  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp                 (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold                 (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                         (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold                     (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass                   (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken                 (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk                  (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp                 (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold                 (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                         (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold                     (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass                   (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken                 (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk                  (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp                 (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold                 (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                         (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold                     (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass                   (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken                 (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk                  (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp                 (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold                 (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                         (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold                     (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass                   (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken                 (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk                  (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp                 (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold                 (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                         (sigFromSrams_bore_7_cgen),
    .sigFromSrams_bore_8_ram_hold                     (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_8_ram_bypass                   (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken                 (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk                  (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp                 (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold                 (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                         (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_9_ram_hold                     (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_9_ram_bypass                   (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken                 (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk                  (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp                 (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold                 (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                         (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_10_ram_hold                    (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_10_ram_bypass                  (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken                (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk                 (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp                (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold                (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                        (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_11_ram_hold                    (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_11_ram_bypass                  (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken                (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk                 (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp                (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold                (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                        (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_12_ram_hold                    (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_12_ram_bypass                  (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken                (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk                 (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp                (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold                (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                        (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_13_ram_hold                    (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_13_ram_bypass                  (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken                (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk                 (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp                (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold                (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                        (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_14_ram_hold                    (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_14_ram_bypass                  (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken                (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk                 (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp                (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold                (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                        (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_15_ram_hold                    (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_15_ram_bypass                  (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken                (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk                 (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp                (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold                (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                        (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_16_ram_hold                    (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_16_ram_bypass                  (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken                (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk                 (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp                (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold                (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                        (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_17_ram_hold                    (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_17_ram_bypass                  (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken                (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk                 (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp                (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold                (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen                        (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_18_ram_hold                    (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_18_ram_bypass                  (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken                (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk                 (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp                (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold                (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen                        (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_19_ram_hold                    (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_19_ram_bypass                  (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken                (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk                 (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp                (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold                (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen                        (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_20_ram_hold                    (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_20_ram_bypass                  (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken                (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk                 (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp                (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold                (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen                        (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_21_ram_hold                    (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_21_ram_bypass                  (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken                (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk                 (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp                (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold                (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen                        (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_22_ram_hold                    (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_22_ram_bypass                  (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken                (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk                 (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp                (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold                (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen                        (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_23_ram_hold                    (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_23_ram_bypass                  (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken                (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk                 (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp                (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold                (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen                        (sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_24_ram_hold                    (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_24_ram_bypass                  (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken                (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk                 (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp                (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold                (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen                        (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_25_ram_hold                    (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_25_ram_bypass                  (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken                (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk                 (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp                (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold                (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen                        (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_26_ram_hold                    (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_26_ram_bypass                  (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken                (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk                 (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp                (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold                (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen                        (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_27_ram_hold                    (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_27_ram_bypass                  (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken                (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk                 (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp                (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold                (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen                        (sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_28_ram_hold                    (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_28_ram_bypass                  (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken                (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk                 (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp                (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold                (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen                        (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_29_ram_hold                    (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_29_ram_bypass                  (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken                (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk                 (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp                (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold                (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen                        (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_30_ram_hold                    (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_30_ram_bypass                  (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken                (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk                 (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp                (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold                (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen                        (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_31_ram_hold                    (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_31_ram_bypass                  (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken                (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk                 (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp                (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold                (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen                        (sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_32_ram_hold                    (sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_32_ram_bypass                  (sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_32_ram_bp_clken                (sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_32_ram_aux_clk                 (sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_32_ram_aux_ckbp                (sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_32_ram_mcp_hold                (sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_32_cgen                        (sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_33_ram_hold                    (sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_33_ram_bypass                  (sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_33_ram_bp_clken                (sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_33_ram_aux_clk                 (sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_33_ram_aux_ckbp                (sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_33_ram_mcp_hold                (sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_33_cgen                        (sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_34_ram_hold                    (sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_34_ram_bypass                  (sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_34_ram_bp_clken                (sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_34_ram_aux_clk                 (sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_34_ram_aux_ckbp                (sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_34_ram_mcp_hold                (sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_34_cgen                        (sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_35_ram_hold                    (sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_35_ram_bypass                  (sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_35_ram_bp_clken                (sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_35_ram_aux_clk                 (sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_35_ram_aux_ckbp                (sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_35_ram_mcp_hold                (sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_35_cgen                        (sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_36_ram_hold                    (sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_36_ram_bypass                  (sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_36_ram_bp_clken                (sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_36_ram_aux_clk                 (sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_36_ram_aux_ckbp                (sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_36_ram_mcp_hold                (sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_36_cgen                        (sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_37_ram_hold                    (sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_37_ram_bypass                  (sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_37_ram_bp_clken                (sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_37_ram_aux_clk                 (sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_37_ram_aux_ckbp                (sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_37_ram_mcp_hold                (sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_37_cgen                        (sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_38_ram_hold                    (sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_38_ram_bypass                  (sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_38_ram_bp_clken                (sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_38_ram_aux_clk                 (sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_38_ram_aux_ckbp                (sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_38_ram_mcp_hold                (sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_38_cgen                        (sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_39_ram_hold                    (sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_39_ram_bypass                  (sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_39_ram_bp_clken                (sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_39_ram_aux_clk                 (sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_39_ram_aux_ckbp                (sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_39_ram_mcp_hold                (sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_39_cgen                        (sigFromSrams_bore_39_cgen),
    .sigFromSrams_bore_40_ram_hold                    (sigFromSrams_bore_40_ram_hold),
    .sigFromSrams_bore_40_ram_bypass                  (sigFromSrams_bore_40_ram_bypass),
    .sigFromSrams_bore_40_ram_bp_clken                (sigFromSrams_bore_40_ram_bp_clken),
    .sigFromSrams_bore_40_ram_aux_clk                 (sigFromSrams_bore_40_ram_aux_clk),
    .sigFromSrams_bore_40_ram_aux_ckbp                (sigFromSrams_bore_40_ram_aux_ckbp),
    .sigFromSrams_bore_40_ram_mcp_hold                (sigFromSrams_bore_40_ram_mcp_hold),
    .sigFromSrams_bore_40_cgen                        (sigFromSrams_bore_40_cgen),
    .sigFromSrams_bore_41_ram_hold                    (sigFromSrams_bore_41_ram_hold),
    .sigFromSrams_bore_41_ram_bypass                  (sigFromSrams_bore_41_ram_bypass),
    .sigFromSrams_bore_41_ram_bp_clken                (sigFromSrams_bore_41_ram_bp_clken),
    .sigFromSrams_bore_41_ram_aux_clk                 (sigFromSrams_bore_41_ram_aux_clk),
    .sigFromSrams_bore_41_ram_aux_ckbp                (sigFromSrams_bore_41_ram_aux_ckbp),
    .sigFromSrams_bore_41_ram_mcp_hold                (sigFromSrams_bore_41_ram_mcp_hold),
    .sigFromSrams_bore_41_cgen                        (sigFromSrams_bore_41_cgen),
    .sigFromSrams_bore_42_ram_hold                    (sigFromSrams_bore_42_ram_hold),
    .sigFromSrams_bore_42_ram_bypass                  (sigFromSrams_bore_42_ram_bypass),
    .sigFromSrams_bore_42_ram_bp_clken                (sigFromSrams_bore_42_ram_bp_clken),
    .sigFromSrams_bore_42_ram_aux_clk                 (sigFromSrams_bore_42_ram_aux_clk),
    .sigFromSrams_bore_42_ram_aux_ckbp                (sigFromSrams_bore_42_ram_aux_ckbp),
    .sigFromSrams_bore_42_ram_mcp_hold                (sigFromSrams_bore_42_ram_mcp_hold),
    .sigFromSrams_bore_42_cgen                        (sigFromSrams_bore_42_cgen),
    .sigFromSrams_bore_43_ram_hold                    (sigFromSrams_bore_43_ram_hold),
    .sigFromSrams_bore_43_ram_bypass                  (sigFromSrams_bore_43_ram_bypass),
    .sigFromSrams_bore_43_ram_bp_clken                (sigFromSrams_bore_43_ram_bp_clken),
    .sigFromSrams_bore_43_ram_aux_clk                 (sigFromSrams_bore_43_ram_aux_clk),
    .sigFromSrams_bore_43_ram_aux_ckbp                (sigFromSrams_bore_43_ram_aux_ckbp),
    .sigFromSrams_bore_43_ram_mcp_hold                (sigFromSrams_bore_43_ram_mcp_hold),
    .sigFromSrams_bore_43_cgen                        (sigFromSrams_bore_43_cgen),
    .sigFromSrams_bore_44_ram_hold                    (sigFromSrams_bore_44_ram_hold),
    .sigFromSrams_bore_44_ram_bypass                  (sigFromSrams_bore_44_ram_bypass),
    .sigFromSrams_bore_44_ram_bp_clken                (sigFromSrams_bore_44_ram_bp_clken),
    .sigFromSrams_bore_44_ram_aux_clk                 (sigFromSrams_bore_44_ram_aux_clk),
    .sigFromSrams_bore_44_ram_aux_ckbp                (sigFromSrams_bore_44_ram_aux_ckbp),
    .sigFromSrams_bore_44_ram_mcp_hold                (sigFromSrams_bore_44_ram_mcp_hold),
    .sigFromSrams_bore_44_cgen                        (sigFromSrams_bore_44_cgen),
    .sigFromSrams_bore_45_ram_hold                    (sigFromSrams_bore_45_ram_hold),
    .sigFromSrams_bore_45_ram_bypass                  (sigFromSrams_bore_45_ram_bypass),
    .sigFromSrams_bore_45_ram_bp_clken                (sigFromSrams_bore_45_ram_bp_clken),
    .sigFromSrams_bore_45_ram_aux_clk                 (sigFromSrams_bore_45_ram_aux_clk),
    .sigFromSrams_bore_45_ram_aux_ckbp                (sigFromSrams_bore_45_ram_aux_ckbp),
    .sigFromSrams_bore_45_ram_mcp_hold                (sigFromSrams_bore_45_ram_mcp_hold),
    .sigFromSrams_bore_45_cgen                        (sigFromSrams_bore_45_cgen),
    .sigFromSrams_bore_46_ram_hold                    (sigFromSrams_bore_46_ram_hold),
    .sigFromSrams_bore_46_ram_bypass                  (sigFromSrams_bore_46_ram_bypass),
    .sigFromSrams_bore_46_ram_bp_clken                (sigFromSrams_bore_46_ram_bp_clken),
    .sigFromSrams_bore_46_ram_aux_clk                 (sigFromSrams_bore_46_ram_aux_clk),
    .sigFromSrams_bore_46_ram_aux_ckbp                (sigFromSrams_bore_46_ram_aux_ckbp),
    .sigFromSrams_bore_46_ram_mcp_hold                (sigFromSrams_bore_46_ram_mcp_hold),
    .sigFromSrams_bore_46_cgen                        (sigFromSrams_bore_46_cgen),
    .sigFromSrams_bore_47_ram_hold                    (sigFromSrams_bore_47_ram_hold),
    .sigFromSrams_bore_47_ram_bypass                  (sigFromSrams_bore_47_ram_bypass),
    .sigFromSrams_bore_47_ram_bp_clken                (sigFromSrams_bore_47_ram_bp_clken),
    .sigFromSrams_bore_47_ram_aux_clk                 (sigFromSrams_bore_47_ram_aux_clk),
    .sigFromSrams_bore_47_ram_aux_ckbp                (sigFromSrams_bore_47_ram_aux_ckbp),
    .sigFromSrams_bore_47_ram_mcp_hold                (sigFromSrams_bore_47_ram_mcp_hold),
    .sigFromSrams_bore_47_cgen                        (sigFromSrams_bore_47_cgen)
  );
  // END GENERATED(composer_inst)

endmodule
