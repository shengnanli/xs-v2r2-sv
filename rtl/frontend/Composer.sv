// =============================================================================
// Composer.sv —— BPU 五个分支预测器的**组合层**（Chisel: xiangshan.frontend.Composer）
//
// 【它在前端的位置】
//   香山前端的分支预测单元 BPU 是一条 **S0→S1→S2→S3 的多级覆盖式预测流水**：
//   S0 产生取指地址 s0_pc，最快的预测器在 S1 当拍就给出第一版预测让取指立刻动起来，
//   随后更慢更准的预测器在 S2/S3 **覆盖**前者；每一级如果和前一级结论不同，就由上层
//   Predictor 发出 override 重定向，把已经走错的取指流冲掉重来。
//
//     S0  算下一个 s0_pc（由各级预测/重定向选出）
//     S1  uFTB 零气泡出第一版（当拍组合出结果，不占一拍）
//     S2  FTB 给准确的取指块结构；TAGE 给方向
//     S3  SC 校正方向、ITTAGE 给间接目标、RAS 给 ret 目标
//
//   Composer 就是把这 5 个预测器**串起来**的那一层，本身几乎不做预测决策。
//
// 【菊花链：覆盖发生在预测器内部，不在本层】
//   关键结构观察：Composer 不写"谁覆盖谁"的仲裁逻辑。它把预测器接成一条链，每一级
//   吃上一级的完整预测包（io_in_bits_resp_in_0_*），只在自己负责的字段上改写，再把
//   整包传给下一级。链序不是例化顺序，而是 resp_in 的连接方向，实测如下（连接根数）：
//
//     uftb ──2──▶ tage ──18──▶ ftb ──168──▶ ittage ──169──▶ ras ──▶ 顶层 S2/S3 输出
//       │        (TAGE-SC)                 (间接目标)      (链尾)
//       └──▶ 顶层 S1 输出（74 根，S1 当拍就要给取指用，来不及等后面几级）
//
//   所以两件事要分清：
//     · **S1 输出直接来自 uFTB**（74 个顶层输出端口），因为 S1 要零气泡；
//     · **S2/S3 与末级 meta 全部来自链尾 ras**（186 个顶层输出端口 = S2 的 76 根
//       + S3 的 80 根 + last_stage_* 的 30 根），它拿到的是被 TAGE→FTB→ITTAGE
//       逐级改写过、再由 RAS 补上 ret 目标的最终包。
//   顶层 293 个输出里 282 个就是这样的子模块直连（ftb/tage/ittage 各只直驱自己的
//   MBIST 端口），只有 11 个由本层自己算。这正是 golden 模块体 3871 行里 81%（3135 行）
//   是例化连线的原因。
//
// 【Composer 自己算的 11 个输出（= 可读核 xs_Composer_core 的全部职责）】
//   1. io_perf_0..6_value —— 7 路性能计数各打 2 拍对齐后输出；
//   2. io_out_last_stage_meta —— 把 5 个预测器的 meta 段按固定布局拼成 516 位大包
//      写回 FTQ（commit 时上层按同布局拆开、原样送回各预测器做训练）；
//   3. io_s1_ready —— tage & ftb & ittage 三者都就绪才放行 S1（uFTB/RAS 恒 ready）；
//   加上两根纯扇出：io_out_s1_full_pred_0_br_taken_mask_{0,1}（见下，在 wrapper 里接）。
//
// 【核里还有一条"影子 PC 流水"：SegmentedAddrNext】
//   golden 里有 s1_pc_dup / s2_pc_dup / s3_pc_dup 一大坨寄存器。它们是 utility 的
//   **SegmentedAddrNext**——把 50 位 PC 切成 [49:24]/[23:12]/[11:0] 三段，每段只在
//   **值真的变了**时才打拍（高位段变化稀疏 → 省翻转功耗），读出时再拼回。
//   本 build 里这条链是 **cone-dead 的**：s3 段寄存器拼出的地址没有任何消费者，真正
//   送出去的 io_out_s1_pc 由链头 uftb 驱动、io_out_s2/s3_pc 由链尾 ras 驱动，都跟这条
//   影子流水无关。但它们是**真寄存器**，FM 会当作比对点，所以核里照实现，不能省。
//
// 【G1 相对 G0 的改动（本文件对照 /home/eda/xs-env/G1-canonical/golden-rtl 重生成）】
//   · MBIST：boreChildrenBd_bore_{2,3,4,5}_{addr,addr_rd} 由 9 位收窄到 8 位；
//     sigFromSrams 新增 6 组 bore（42 根输入），tage 的 bore 用量 26→32，ras 的 bore
//     索引整体后移 6（34..41 → 40..47）。全部是扫描链管脚，无功能。
//   · 复位脉冲重构：G0 用 REG/REG_1 两级把"复位刚放开"延迟成一拍脉冲，G1 改成单个
//     modified_reset 寄存器，**脉冲提前了一拍**（s1_pc 装载复位向量的时刻早一拍）。
//   · 真功能改动：TAGE-SC 新增两个输入端口，收 uFTB 在 S1 给出的 br_taken_mask[1:0]，
//     即 TAGE 现在能看到微 BTB 的当拍方向预测。G0 里 tage 的 resp_in 一根都没接
//     （它才是那条链真正的头），G1 给它接上了 uftb 的 2 根 —— 链头由 tage 变成 uftb。
//     Composer 这一层的动作就是把 uftb 的这两根输出**同时**扇给顶层输出和 tage 输入。
//
// 【本文件结构】（单文件规范：package → xs_*_core → golden 同名 wrapper）
//   wrapper 里的端口表 / 子模块输出网 / 9 个例化块是**机械派生区**，由
//   tools/predictor_composer/gen_assembly.py 从 G1 golden 现取现生成，
//   `// BEGIN GENERATED(<tag>)` 圈起来；手改无效，改了跑 `--check` 会报不同步。
// =============================================================================
// 本文件导航（共 3510 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L35    它在前端的位置
//   L48    菊花链：覆盖发生在预测器内部，不在本层
//   L66    Composer 自己算的 11 个输出
//   L73    核里还有一条"影子 PC 流水"：SegmentedAddrNext
//   L81    G1 相对 G0 的改动
//   L92    本文件结构】
//   L125   xs_Composer_core —— Composer 这一层自己算的全部逻辑
//   L163   1) modified_reset —— "复位刚放开"的一拍脉冲
//   L175   2) 影子 PC 流水
//   L248   3) 性能计数对齐：7 路各打 2 拍
//   L262   4) last_stage_meta 拼接
//   L275   5) S1 就绪：三大带表预测器都能收才放行
//   L283   Composer —— golden 同名 wrapper
//   L1138  子模块输出网：golden 叫 `_<inst>_io_*`
//   L1141  BEGIN GENERATED(child-nets)
//   L1551  五个预测器 + 四个 ctrl 打拍器的例化
//   L1556  BEGIN GENERATED(instances)
//   L1559  FTB ftb —— 链 3/5 大容量组相联 FTB：给取指块的 CFI 槽/目标/fall-through
//   L1905  FauFTB uftb —— 链头 uFTB(FauFTB)：32 路全相联微 FTB，S1 零气泡出第一版预测；74 个顶层 
//   L2064  Tage_SC tage —— 链 2/5 TAGE-SC：主方向预测器
//   L2437  RAS ras —— 链尾 RAS：返回地址栈，补 ret 目标；186 个顶层输出由它直驱
//   L2857  ITTage ittage —— 链 4/5 ITTAGE：间接跳转目标预测，改写 jalr_target
//   L3367  DelayN uftb_io_ctrl_delay —— ctrl 打拍：CSR 开关信号延迟对齐到各预测器的使用级
//   L3387  DelayN tage_io_ctrl_delay —— ctrl 打拍
//   L3407  DelayN ftb_io_ctrl_delay —— ctrl 打拍
//   L3427  DelayN ras_io_ctrl_delay —— ctrl 打拍
//   L3448  uFTB 在 S1 给出的 br_taken_mask：一路送顶层输出，一路旁路给 TAGE-SC
//   L3457  可读核：本层自己算的 11 个输出
//   L3459  核用数组端口表达"4 份 dup / 7 路 perf"这类对称结构，wrapper 这里把 golden 的
//


package composer_pkg;
  // 预测请求/PC 在 BPU 里复制成 4 份（纯扇出复制，缓解顶层布线时序），值恒等。
  localparam int NUM_DUP = 4;
  localparam int PC_W    = 50;

  // 性能计数：7 路，每路 6 位，统一打 2 拍对齐后输出。
  localparam int NUM_PERF = 7;
  localparam int PERF_W   = 6;

  // last_stage_meta 布局（从高位到低位）：[107 位 0 填充 | uFTB | TAGE | FTB | ITTAGE | RAS]
  localparam int META_W        = 516;
  localparam int META_UFTB_W   = 6;
  localparam int META_TAGE_W   = 144;
  localparam int META_FTB_W    = 67;
  localparam int META_ITTAGE_W = 182;
  localparam int META_RAS_W    = 10;
  localparam int META_PAD_W    = META_W - META_UFTB_W - META_TAGE_W
                               - META_FTB_W - META_ITTAGE_W - META_RAS_W;  // = 107

  // SegmentedAddrNext 的分段：PC 由高到低切三段，高两段"变了才打拍"，最低段每次都打。
  localparam int SEG_HI_W  = 26;  // pc[49:24]
  localparam int SEG_MID_W = 12;  // pc[23:12]
  localparam int SEG_LO_W  = 12;  // pc[11:0]
endpackage

// =============================================================================
// xs_Composer_core —— Composer 这一层自己算的全部逻辑
//   （子模块例化与 282 根直连输出在下面的 wrapper 里，本核不涉及）
// =============================================================================
module xs_Composer_core
  import composer_pkg::*;
(
  input  logic                     clock,
  input  logic                     reset,

  // ---- S0/S1/S2 流水握手与请求 PC（4 份 dup，逐份独立打拍）----
  input  logic [47:0]              io_reset_vector,          // 复位后第一个取指地址
  input  logic [PC_W-1:0]          s0_pc      [NUM_DUP],
  input  logic                     s0_fire    [NUM_DUP],
  input  logic                     s1_fire    [NUM_DUP],
  input  logic                     s2_fire    [NUM_DUP],

  // ---- 各预测器给的性能计数（未对齐）：0/1=uFTB, 2/3/4=TAGE-SC, 5/6=FTB ----
  input  logic [PERF_W-1:0]        perf_in    [NUM_PERF],

  // ---- 各预测器 last_stage_meta 的有效段（wrapper 已按 golden 的位宽切好）----
  input  logic [META_UFTB_W-1:0]   meta_uftb,
  input  logic [META_TAGE_W-1:0]   meta_tage,
  input  logic [META_FTB_W-1:0]    meta_ftb,
  input  logic [META_ITTAGE_W-1:0] meta_ittage,
  input  logic [META_RAS_W-1:0]    meta_ras,

  // ---- s1_ready 来源（uFTB / RAS 恒 ready，不参与）----
  input  logic                     s1_ready_tage,
  input  logic                     s1_ready_ftb,
  input  logic                     s1_ready_ittage,

  // ---- 输出 ----
  output logic [PERF_W-1:0]        perf_out   [NUM_PERF],
  output logic [META_W-1:0]        last_stage_meta,
  output logic                     s1_ready
);

  // ===========================================================================
  // 1) modified_reset —— "复位刚放开"的一拍脉冲
  //
  //   异步复位期间恒为 1；复位放开后的**第一个时钟沿**它还是 1（用来把 s1_pc 装成
  //   复位向量），同一沿把自己清 0，之后一直是 0。
  //
  //   ★ G0→G1 的行为差异就在这里：G0 是 `REG <= reset; REG_1 <= REG & ~reset;`
  //     两级，脉冲落在复位放开后的**第二**拍；G1 单级，落在**第一**拍。装载复位
  //     向量的时刻整体提前了一拍。这是 bug-for-bug 必须照抄的时序细节。
  // ===========================================================================
  logic modified_reset;

  // ===========================================================================
  // 2) 影子 PC 流水（utility.SegmentedAddrNext）
  //
  //   s1_pc  : 复位脉冲时装复位向量，否则 s0_fire 时锁存 s0_pc（普通使能寄存器）。
  //   s2_pc  : s1_pc 经"分段打拍"后一级；s3_pc 再一级。
  //   分段打拍 = 把地址切三段，**只有该段的新值和已存值不同**且本级 fire，才更新
  //   这一段。高位段在顺序取指时长期不变 → 大部分拍不翻转，省动态功耗。
  //   最低段 [11:0] 几乎每次都变，golden 直接把它的 "modified" 条件常量化成 1。
  //
  //   ★ 本 build 里这条链是死的：s3 段寄存器拼出来的地址无人消费（真正送出去的
  //     io_out_s1_pc 由 uftb、io_out_s{2,3}_pc 由 ras 直接驱动）。保留是因为它们是真寄存器，
  //     FM 逐点比对时是比对点，少一个就对不上。
  // ===========================================================================
  logic [PC_W-1:0]      s1_pc     [NUM_DUP];
  logic [SEG_HI_W-1:0]  s2_pc_hi  [NUM_DUP];
  logic [SEG_MID_W-1:0] s2_pc_mid [NUM_DUP];
  logic [SEG_LO_W-1:0]  s2_pc_lo  [NUM_DUP];
  logic [SEG_HI_W-1:0]  s3_pc_hi  [NUM_DUP];
  logic [SEG_MID_W-1:0] s3_pc_mid [NUM_DUP];
  logic [SEG_LO_W-1:0]  s3_pc_lo  [NUM_DUP];

  // SegmentedAddrNext.getAddr()：三段拼回完整地址。本 build 里无消费者（见上），
  // 保留成命名信号是为了让读者看见"分段存、整段读"这件事是完整的。
  wire [PC_W-1:0] s2_pc_addr [NUM_DUP];
  wire [PC_W-1:0] s3_pc_addr [NUM_DUP];

  for (genvar d = 0; d < NUM_DUP; d++) begin : g_pc_pipe
    assign s2_pc_addr[d] = {s2_pc_hi[d], s2_pc_mid[d], s2_pc_lo[d]};
    assign s3_pc_addr[d] = {s3_pc_hi[d], s3_pc_mid[d], s3_pc_lo[d]};

    // 段更新条件：该段值变了才打拍；最低段恒"变了"（golden 常量化为 1'h1）。
    wire s2_hi_mod  = s2_pc_hi[d]  != s1_pc[d][49:24];
    wire s2_mid_mod = s2_pc_mid[d] != s1_pc[d][23:12];
    wire s3_hi_mod  = s3_pc_hi[d]  != s2_pc_hi[d];
    wire s3_mid_mod = s3_pc_mid[d] != s2_pc_mid[d];

    // s1_pc：无复位端口的使能寄存器（golden 就是 always @(posedge clock)，
    // 初值靠 modified_reset 那一拍灌复位向量，不靠 reset 引脚）。
    always_ff @(posedge clock) begin
      if (modified_reset)
        s1_pc[d] <= {2'h0, io_reset_vector};
      else if (s0_fire[d])
        s1_pc[d] <= s0_pc[d];
    end

    // s2/s3 段寄存器：异步复位清零 + 分段使能。
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        s2_pc_hi[d]  <= '0;
        s2_pc_mid[d] <= '0;
        s2_pc_lo[d]  <= '0;
        s3_pc_hi[d]  <= '0;
        s3_pc_mid[d] <= '0;
        s3_pc_lo[d]  <= '0;
      end
      else begin
        if (s2_hi_mod  & s1_fire[d]) s2_pc_hi[d]  <= s1_pc[d][49:24];
        if (s2_mid_mod & s1_fire[d]) s2_pc_mid[d] <= s1_pc[d][23:12];
        if (             s1_fire[d]) s2_pc_lo[d]  <= s1_pc[d][11:0];
        if (s3_hi_mod  & s2_fire[d]) s3_pc_hi[d]  <= s2_pc_hi[d];
        if (s3_mid_mod & s2_fire[d]) s3_pc_mid[d] <= s2_pc_mid[d];
        if (             s2_fire[d]) s3_pc_lo[d]  <= s2_pc_lo[d];
      end
    end
  end

  // modified_reset 与上面的 s2/s3 段寄存器同属一个异步复位域（golden 同一个
  // always 块），这里单列一段以突出它的语义。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) modified_reset <= 1'b1;
    else       modified_reset <= 1'b0;
  end

  // ===========================================================================
  // 3) 性能计数对齐：7 路各打 2 拍
  //   各预测器的 perf 产生于不同流水级，统一延迟 2 拍，让上层在同一时刻采到齐的值。
  //   无复位（golden 同样无复位；初值由 initreg 随机化决定）。
  // ===========================================================================
  logic [PERF_W-1:0] perf_d1 [NUM_PERF];

  for (genvar p = 0; p < NUM_PERF; p++) begin : g_perf_pipe
    always_ff @(posedge clock) begin
      perf_d1[p]  <= perf_in[p];
      perf_out[p] <= perf_d1[p];
    end
  end

  // ===========================================================================
  // 4) last_stage_meta 拼接
  //   5 个预测器各交出自己那一段训练元数据，本层按固定布局拼成一个 516 位大包写回
  //   FTQ；commit 时上层按**完全相同**的布局切开、原样送回各预测器做更新。
  //   顺序即链序（uFTB 在最高位段，RAS 在最低位段），高位补 0 填满 516。
  // ===========================================================================
  assign last_stage_meta = {{META_PAD_W{1'b0}},
                            meta_uftb,
                            meta_tage,
                            meta_ftb,
                            meta_ittage,
                            meta_ras};

  // ===========================================================================
  // 5) S1 就绪：三大带表预测器都能收才放行
  //   uFTB（全相联小表，组合查）与 RAS（栈）恒 ready，不进这个与。
  // ===========================================================================
  assign s1_ready = s1_ready_tage & s1_ready_ftb & s1_ready_ittage;

endmodule

// =============================================================================
// Composer —— golden 同名 wrapper
//   职责：顶层端口表（828 根）+ 5 个预测器与 4 个 DelayN 的例化连线 + 可读核例化。
//   端口表 / 子模块输出网 / 例化块三段由 tools/predictor_composer/gen_assembly.py
//   从 G1 golden 生成，连接配对逐条搬运、一个字不动。
// =============================================================================
module Composer(
  // BEGIN GENERATED(ports)
  // ---- 时钟与复位 ----
  input          clock,
  input          reset,
  // ---- 复位向量（复位后第一个取指 PC） ----
  input  [47:0]  io_reset_vector,
  // ---- S0 预测请求：PC + 全局/折叠历史 ----
  input  [49:0]  io_in_bits_s0_pc_0,
  input  [49:0]  io_in_bits_s0_pc_1,
  input  [49:0]  io_in_bits_s0_pc_2,
  input  [49:0]  io_in_bits_s0_pc_3,
  input  [10:0]  io_in_bits_folded_hist_1_hist_17_folded_hist,
  input  [10:0]  io_in_bits_folded_hist_1_hist_16_folded_hist,
  input  [6:0]   io_in_bits_folded_hist_1_hist_15_folded_hist,
  input  [7:0]   io_in_bits_folded_hist_1_hist_14_folded_hist,
  input  [6:0]   io_in_bits_folded_hist_1_hist_9_folded_hist,
  input  [7:0]   io_in_bits_folded_hist_1_hist_8_folded_hist,
  input  [6:0]   io_in_bits_folded_hist_1_hist_7_folded_hist,
  input  [6:0]   io_in_bits_folded_hist_1_hist_5_folded_hist,
  input  [7:0]   io_in_bits_folded_hist_1_hist_4_folded_hist,
  input  [7:0]   io_in_bits_folded_hist_1_hist_3_folded_hist,
  input  [10:0]  io_in_bits_folded_hist_1_hist_1_folded_hist,
  input  [3:0]   io_in_bits_folded_hist_3_hist_12_folded_hist,
  input  [7:0]   io_in_bits_folded_hist_3_hist_11_folded_hist,
  input  [7:0]   io_in_bits_folded_hist_3_hist_2_folded_hist,
  input  [7:0]   io_in_bits_s1_folded_hist_3_hist_14_folded_hist,
  input  [8:0]   io_in_bits_s1_folded_hist_3_hist_13_folded_hist,
  input  [3:0]   io_in_bits_s1_folded_hist_3_hist_12_folded_hist,
  input  [8:0]   io_in_bits_s1_folded_hist_3_hist_10_folded_hist,
  input  [8:0]   io_in_bits_s1_folded_hist_3_hist_6_folded_hist,
  input  [7:0]   io_in_bits_s1_folded_hist_3_hist_4_folded_hist,
  input  [7:0]   io_in_bits_s1_folded_hist_3_hist_3_folded_hist,
  input  [7:0]   io_in_bits_s1_folded_hist_3_hist_2_folded_hist,
  input  [255:0] io_in_bits_ghist,
  // ---- S1 预测输出（uFTB 零气泡首版） ----
  output [49:0]  io_out_s1_pc_0,
  output [49:0]  io_out_s1_pc_1,
  output [49:0]  io_out_s1_pc_2,
  output [49:0]  io_out_s1_pc_3,
  output         io_out_s1_full_pred_0_br_taken_mask_0,
  output         io_out_s1_full_pred_0_br_taken_mask_1,
  output         io_out_s1_full_pred_0_slot_valids_0,
  output         io_out_s1_full_pred_0_slot_valids_1,
  output [49:0]  io_out_s1_full_pred_0_targets_0,
  output [49:0]  io_out_s1_full_pred_0_targets_1,
  output [49:0]  io_out_s1_full_pred_0_jalr_target,
  output [3:0]   io_out_s1_full_pred_0_offsets_0,
  output [3:0]   io_out_s1_full_pred_0_offsets_1,
  output [49:0]  io_out_s1_full_pred_0_fallThroughAddr,
  output         io_out_s1_full_pred_0_fallThroughErr,
  output         io_out_s1_full_pred_0_is_jal,
  output         io_out_s1_full_pred_0_is_jalr,
  output         io_out_s1_full_pred_0_is_call,
  output         io_out_s1_full_pred_0_is_ret,
  output         io_out_s1_full_pred_0_last_may_be_rvi_call,
  output         io_out_s1_full_pred_0_is_br_sharing,
  output         io_out_s1_full_pred_0_hit,
  output         io_out_s1_full_pred_1_br_taken_mask_0,
  output         io_out_s1_full_pred_1_br_taken_mask_1,
  output         io_out_s1_full_pred_1_slot_valids_0,
  output         io_out_s1_full_pred_1_slot_valids_1,
  output [49:0]  io_out_s1_full_pred_1_targets_0,
  output [49:0]  io_out_s1_full_pred_1_targets_1,
  output [49:0]  io_out_s1_full_pred_1_jalr_target,
  output [3:0]   io_out_s1_full_pred_1_offsets_0,
  output [3:0]   io_out_s1_full_pred_1_offsets_1,
  output [49:0]  io_out_s1_full_pred_1_fallThroughAddr,
  output         io_out_s1_full_pred_1_fallThroughErr,
  output         io_out_s1_full_pred_1_is_jal,
  output         io_out_s1_full_pred_1_is_jalr,
  output         io_out_s1_full_pred_1_is_call,
  output         io_out_s1_full_pred_1_is_ret,
  output         io_out_s1_full_pred_1_last_may_be_rvi_call,
  output         io_out_s1_full_pred_1_is_br_sharing,
  output         io_out_s1_full_pred_1_hit,
  output         io_out_s1_full_pred_2_br_taken_mask_0,
  output         io_out_s1_full_pred_2_br_taken_mask_1,
  output         io_out_s1_full_pred_2_slot_valids_0,
  output         io_out_s1_full_pred_2_slot_valids_1,
  output [49:0]  io_out_s1_full_pred_2_targets_0,
  output [49:0]  io_out_s1_full_pred_2_targets_1,
  output [49:0]  io_out_s1_full_pred_2_jalr_target,
  output [3:0]   io_out_s1_full_pred_2_offsets_0,
  output [3:0]   io_out_s1_full_pred_2_offsets_1,
  output [49:0]  io_out_s1_full_pred_2_fallThroughAddr,
  output         io_out_s1_full_pred_2_fallThroughErr,
  output         io_out_s1_full_pred_2_is_jal,
  output         io_out_s1_full_pred_2_is_jalr,
  output         io_out_s1_full_pred_2_is_call,
  output         io_out_s1_full_pred_2_is_ret,
  output         io_out_s1_full_pred_2_last_may_be_rvi_call,
  output         io_out_s1_full_pred_2_is_br_sharing,
  output         io_out_s1_full_pred_2_hit,
  output         io_out_s1_full_pred_3_br_taken_mask_0,
  output         io_out_s1_full_pred_3_br_taken_mask_1,
  output         io_out_s1_full_pred_3_slot_valids_0,
  output         io_out_s1_full_pred_3_slot_valids_1,
  output [49:0]  io_out_s1_full_pred_3_targets_0,
  output [49:0]  io_out_s1_full_pred_3_targets_1,
  output [49:0]  io_out_s1_full_pred_3_jalr_target,
  output [3:0]   io_out_s1_full_pred_3_offsets_0,
  output [3:0]   io_out_s1_full_pred_3_offsets_1,
  output [49:0]  io_out_s1_full_pred_3_fallThroughAddr,
  output         io_out_s1_full_pred_3_fallThroughErr,
  output         io_out_s1_full_pred_3_is_jal,
  output         io_out_s1_full_pred_3_is_jalr,
  output         io_out_s1_full_pred_3_is_call,
  output         io_out_s1_full_pred_3_is_ret,
  output         io_out_s1_full_pred_3_last_may_be_rvi_call,
  output         io_out_s1_full_pred_3_is_br_sharing,
  output         io_out_s1_full_pred_3_hit,
  // ---- S2 预测输出（FTB / TAGE 覆盖） ----
  output [49:0]  io_out_s2_pc_0,
  output [49:0]  io_out_s2_pc_1,
  output [49:0]  io_out_s2_pc_2,
  output [49:0]  io_out_s2_pc_3,
  output         io_out_s2_full_pred_0_br_taken_mask_0,
  output         io_out_s2_full_pred_0_br_taken_mask_1,
  output         io_out_s2_full_pred_0_slot_valids_0,
  output         io_out_s2_full_pred_0_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_0_targets_0,
  output [49:0]  io_out_s2_full_pred_0_targets_1,
  output [49:0]  io_out_s2_full_pred_0_jalr_target,
  output [3:0]   io_out_s2_full_pred_0_offsets_0,
  output [3:0]   io_out_s2_full_pred_0_offsets_1,
  output [49:0]  io_out_s2_full_pred_0_fallThroughAddr,
  output         io_out_s2_full_pred_0_fallThroughErr,
  output         io_out_s2_full_pred_0_is_jal,
  output         io_out_s2_full_pred_0_is_jalr,
  output         io_out_s2_full_pred_0_is_call,
  output         io_out_s2_full_pred_0_is_ret,
  output         io_out_s2_full_pred_0_last_may_be_rvi_call,
  output         io_out_s2_full_pred_0_is_br_sharing,
  output         io_out_s2_full_pred_0_hit,
  output         io_out_s2_full_pred_1_br_taken_mask_0,
  output         io_out_s2_full_pred_1_br_taken_mask_1,
  output         io_out_s2_full_pred_1_slot_valids_0,
  output         io_out_s2_full_pred_1_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_1_targets_0,
  output [49:0]  io_out_s2_full_pred_1_targets_1,
  output [49:0]  io_out_s2_full_pred_1_jalr_target,
  output [3:0]   io_out_s2_full_pred_1_offsets_0,
  output [3:0]   io_out_s2_full_pred_1_offsets_1,
  output [49:0]  io_out_s2_full_pred_1_fallThroughAddr,
  output         io_out_s2_full_pred_1_fallThroughErr,
  output         io_out_s2_full_pred_1_is_jal,
  output         io_out_s2_full_pred_1_is_jalr,
  output         io_out_s2_full_pred_1_is_call,
  output         io_out_s2_full_pred_1_is_ret,
  output         io_out_s2_full_pred_1_last_may_be_rvi_call,
  output         io_out_s2_full_pred_1_is_br_sharing,
  output         io_out_s2_full_pred_1_hit,
  output         io_out_s2_full_pred_2_br_taken_mask_0,
  output         io_out_s2_full_pred_2_br_taken_mask_1,
  output         io_out_s2_full_pred_2_slot_valids_0,
  output         io_out_s2_full_pred_2_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_2_targets_0,
  output [49:0]  io_out_s2_full_pred_2_targets_1,
  output [49:0]  io_out_s2_full_pred_2_jalr_target,
  output [3:0]   io_out_s2_full_pred_2_offsets_0,
  output [3:0]   io_out_s2_full_pred_2_offsets_1,
  output [49:0]  io_out_s2_full_pred_2_fallThroughAddr,
  output         io_out_s2_full_pred_2_fallThroughErr,
  output         io_out_s2_full_pred_2_is_jal,
  output         io_out_s2_full_pred_2_is_jalr,
  output         io_out_s2_full_pred_2_is_call,
  output         io_out_s2_full_pred_2_is_ret,
  output         io_out_s2_full_pred_2_last_may_be_rvi_call,
  output         io_out_s2_full_pred_2_is_br_sharing,
  output         io_out_s2_full_pred_2_hit,
  output         io_out_s2_full_pred_3_br_taken_mask_0,
  output         io_out_s2_full_pred_3_br_taken_mask_1,
  output         io_out_s2_full_pred_3_slot_valids_0,
  output         io_out_s2_full_pred_3_slot_valids_1,
  output [49:0]  io_out_s2_full_pred_3_targets_0,
  output [49:0]  io_out_s2_full_pred_3_targets_1,
  output [49:0]  io_out_s2_full_pred_3_jalr_target,
  output [3:0]   io_out_s2_full_pred_3_offsets_0,
  output [3:0]   io_out_s2_full_pred_3_offsets_1,
  output [49:0]  io_out_s2_full_pred_3_fallThroughAddr,
  output         io_out_s2_full_pred_3_fallThroughErr,
  output         io_out_s2_full_pred_3_is_jal,
  output         io_out_s2_full_pred_3_is_jalr,
  output         io_out_s2_full_pred_3_is_call,
  output         io_out_s2_full_pred_3_is_ret,
  output         io_out_s2_full_pred_3_last_may_be_rvi_call,
  output         io_out_s2_full_pred_3_is_br_sharing,
  output         io_out_s2_full_pred_3_hit,
  // ---- S3 预测输出（SC / ITTAGE / RAS 覆盖） ----
  output [49:0]  io_out_s3_pc_0,
  output [49:0]  io_out_s3_pc_1,
  output [49:0]  io_out_s3_pc_2,
  output [49:0]  io_out_s3_pc_3,
  output         io_out_s3_full_pred_0_br_taken_mask_0,
  output         io_out_s3_full_pred_0_br_taken_mask_1,
  output         io_out_s3_full_pred_0_slot_valids_0,
  output         io_out_s3_full_pred_0_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_0_targets_0,
  output [49:0]  io_out_s3_full_pred_0_targets_1,
  output [49:0]  io_out_s3_full_pred_0_jalr_target,
  output [3:0]   io_out_s3_full_pred_0_offsets_0,
  output [3:0]   io_out_s3_full_pred_0_offsets_1,
  output [49:0]  io_out_s3_full_pred_0_fallThroughAddr,
  output         io_out_s3_full_pred_0_fallThroughErr,
  output         io_out_s3_full_pred_0_multiHit,
  output         io_out_s3_full_pred_0_is_jal,
  output         io_out_s3_full_pred_0_is_jalr,
  output         io_out_s3_full_pred_0_is_call,
  output         io_out_s3_full_pred_0_is_ret,
  output         io_out_s3_full_pred_0_last_may_be_rvi_call,
  output         io_out_s3_full_pred_0_is_br_sharing,
  output         io_out_s3_full_pred_0_hit,
  output         io_out_s3_full_pred_1_br_taken_mask_0,
  output         io_out_s3_full_pred_1_br_taken_mask_1,
  output         io_out_s3_full_pred_1_slot_valids_0,
  output         io_out_s3_full_pred_1_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_1_targets_0,
  output [49:0]  io_out_s3_full_pred_1_targets_1,
  output [49:0]  io_out_s3_full_pred_1_jalr_target,
  output [3:0]   io_out_s3_full_pred_1_offsets_0,
  output [3:0]   io_out_s3_full_pred_1_offsets_1,
  output [49:0]  io_out_s3_full_pred_1_fallThroughAddr,
  output         io_out_s3_full_pred_1_fallThroughErr,
  output         io_out_s3_full_pred_1_multiHit,
  output         io_out_s3_full_pred_1_is_jal,
  output         io_out_s3_full_pred_1_is_jalr,
  output         io_out_s3_full_pred_1_is_call,
  output         io_out_s3_full_pred_1_is_ret,
  output         io_out_s3_full_pred_1_last_may_be_rvi_call,
  output         io_out_s3_full_pred_1_is_br_sharing,
  output         io_out_s3_full_pred_1_hit,
  output         io_out_s3_full_pred_2_br_taken_mask_0,
  output         io_out_s3_full_pred_2_br_taken_mask_1,
  output         io_out_s3_full_pred_2_slot_valids_0,
  output         io_out_s3_full_pred_2_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_2_targets_0,
  output [49:0]  io_out_s3_full_pred_2_targets_1,
  output [49:0]  io_out_s3_full_pred_2_jalr_target,
  output [3:0]   io_out_s3_full_pred_2_offsets_0,
  output [3:0]   io_out_s3_full_pred_2_offsets_1,
  output [49:0]  io_out_s3_full_pred_2_fallThroughAddr,
  output         io_out_s3_full_pred_2_fallThroughErr,
  output         io_out_s3_full_pred_2_multiHit,
  output         io_out_s3_full_pred_2_is_jal,
  output         io_out_s3_full_pred_2_is_jalr,
  output         io_out_s3_full_pred_2_is_call,
  output         io_out_s3_full_pred_2_is_ret,
  output         io_out_s3_full_pred_2_last_may_be_rvi_call,
  output         io_out_s3_full_pred_2_is_br_sharing,
  output         io_out_s3_full_pred_2_hit,
  output         io_out_s3_full_pred_3_br_taken_mask_0,
  output         io_out_s3_full_pred_3_br_taken_mask_1,
  output         io_out_s3_full_pred_3_slot_valids_0,
  output         io_out_s3_full_pred_3_slot_valids_1,
  output [49:0]  io_out_s3_full_pred_3_targets_0,
  output [49:0]  io_out_s3_full_pred_3_targets_1,
  output [49:0]  io_out_s3_full_pred_3_jalr_target,
  output [3:0]   io_out_s3_full_pred_3_offsets_0,
  output [3:0]   io_out_s3_full_pred_3_offsets_1,
  output [49:0]  io_out_s3_full_pred_3_fallThroughAddr,
  output         io_out_s3_full_pred_3_fallThroughErr,
  output         io_out_s3_full_pred_3_multiHit,
  output         io_out_s3_full_pred_3_is_jal,
  output         io_out_s3_full_pred_3_is_jalr,
  output         io_out_s3_full_pred_3_is_call,
  output         io_out_s3_full_pred_3_is_ret,
  output         io_out_s3_full_pred_3_last_may_be_rvi_call,
  output         io_out_s3_full_pred_3_is_br_sharing,
  output         io_out_s3_full_pred_3_hit,
  // ---- 末级 meta / FTB entry（写回 FTQ，update 时原样送回） ----
  output [515:0] io_out_last_stage_meta,
  output [3:0]   io_out_last_stage_spec_info_ssp,
  output [2:0]   io_out_last_stage_spec_info_sctr,
  output         io_out_last_stage_spec_info_TOSW_flag,
  output [4:0]   io_out_last_stage_spec_info_TOSW_value,
  output         io_out_last_stage_spec_info_TOSR_flag,
  output [4:0]   io_out_last_stage_spec_info_TOSR_value,
  output         io_out_last_stage_spec_info_NOS_flag,
  output [4:0]   io_out_last_stage_spec_info_NOS_value,
  output [49:0]  io_out_last_stage_spec_info_topAddr,
  output         io_out_last_stage_spec_info_sc_disagree_0,
  output         io_out_last_stage_spec_info_sc_disagree_1,
  output         io_out_last_stage_ftb_entry_isCall,
  output         io_out_last_stage_ftb_entry_isRet,
  output         io_out_last_stage_ftb_entry_isJalr,
  output         io_out_last_stage_ftb_entry_valid,
  output [3:0]   io_out_last_stage_ftb_entry_brSlots_0_offset,
  output         io_out_last_stage_ftb_entry_brSlots_0_sharing,
  output         io_out_last_stage_ftb_entry_brSlots_0_valid,
  output [11:0]  io_out_last_stage_ftb_entry_brSlots_0_lower,
  output [1:0]   io_out_last_stage_ftb_entry_brSlots_0_tarStat,
  output [3:0]   io_out_last_stage_ftb_entry_tailSlot_offset,
  output         io_out_last_stage_ftb_entry_tailSlot_sharing,
  output         io_out_last_stage_ftb_entry_tailSlot_valid,
  output [19:0]  io_out_last_stage_ftb_entry_tailSlot_lower,
  output [1:0]   io_out_last_stage_ftb_entry_tailSlot_tarStat,
  output [3:0]   io_out_last_stage_ftb_entry_pftAddr,
  output         io_out_last_stage_ftb_entry_carry,
  output         io_out_last_stage_ftb_entry_last_may_be_rvi_call,
  output         io_out_last_stage_ftb_entry_strong_bias_0,
  output         io_out_last_stage_ftb_entry_strong_bias_1,
  // ---- 各预测器使能开关（CSR 可关） ----
  input          io_ctrl_ubtb_enable,
  input          io_ctrl_btb_enable,
  input          io_ctrl_tage_enable,
  input          io_ctrl_sc_enable,
  input          io_ctrl_ras_enable,
  // ---- S0~S3 流水握手（fire = valid & ready，4 份 dup） ----
  input          io_s0_fire_0,
  input          io_s0_fire_1,
  input          io_s0_fire_2,
  input          io_s0_fire_3,
  input          io_s1_fire_0,
  input          io_s1_fire_1,
  input          io_s1_fire_2,
  input          io_s1_fire_3,
  input          io_s2_fire_0,
  input          io_s2_fire_1,
  input          io_s2_fire_2,
  input          io_s2_fire_3,
  input          io_s3_fire_0,
  input          io_s3_fire_2,
  // ---- 其余 io ----
  input          io_s3_redirect_2,
  // ---- S1 就绪（三大表相与） ----
  output         io_s1_ready,
  // ---- FTQ commit 回来的训练更新 ----
  input          io_update_valid,
  input  [49:0]  io_update_bits_pc,
  input          io_update_bits_ftb_entry_isCall,
  input          io_update_bits_ftb_entry_isRet,
  input          io_update_bits_ftb_entry_isJalr,
  input          io_update_bits_ftb_entry_valid,
  input  [3:0]   io_update_bits_ftb_entry_brSlots_0_offset,
  input          io_update_bits_ftb_entry_brSlots_0_sharing,
  input          io_update_bits_ftb_entry_brSlots_0_valid,
  input  [11:0]  io_update_bits_ftb_entry_brSlots_0_lower,
  input  [1:0]   io_update_bits_ftb_entry_brSlots_0_tarStat,
  input  [3:0]   io_update_bits_ftb_entry_tailSlot_offset,
  input          io_update_bits_ftb_entry_tailSlot_sharing,
  input          io_update_bits_ftb_entry_tailSlot_valid,
  input  [19:0]  io_update_bits_ftb_entry_tailSlot_lower,
  input  [1:0]   io_update_bits_ftb_entry_tailSlot_tarStat,
  input  [3:0]   io_update_bits_ftb_entry_pftAddr,
  input          io_update_bits_ftb_entry_carry,
  input          io_update_bits_ftb_entry_last_may_be_rvi_call,
  input          io_update_bits_ftb_entry_strong_bias_0,
  input          io_update_bits_ftb_entry_strong_bias_1,
  input          io_update_bits_cfi_idx_valid,
  input  [3:0]   io_update_bits_cfi_idx_bits,
  input          io_update_bits_br_taken_mask_0,
  input          io_update_bits_br_taken_mask_1,
  input          io_update_bits_jmp_taken,
  input          io_update_bits_mispred_mask_0,
  input          io_update_bits_mispred_mask_1,
  input          io_update_bits_mispred_mask_2,
  input          io_update_bits_false_hit,
  input          io_update_bits_old_entry,
  input  [515:0] io_update_bits_meta,
  input  [49:0]  io_update_bits_full_target,
  input  [255:0] io_update_bits_ghist,
  // ---- 重定向（错预测纠正 / 恢复历史） ----
  input          io_redirect_valid,
  input          io_redirect_bits_level,
  input  [49:0]  io_redirect_bits_cfiUpdate_pc,
  input          io_redirect_bits_cfiUpdate_pd_valid,
  input          io_redirect_bits_cfiUpdate_pd_isRVC,
  input          io_redirect_bits_cfiUpdate_pd_isCall,
  input          io_redirect_bits_cfiUpdate_pd_isRet,
  input  [3:0]   io_redirect_bits_cfiUpdate_ssp,
  input  [2:0]   io_redirect_bits_cfiUpdate_sctr,
  input          io_redirect_bits_cfiUpdate_TOSW_flag,
  input  [4:0]   io_redirect_bits_cfiUpdate_TOSW_value,
  input          io_redirect_bits_cfiUpdate_TOSR_flag,
  input  [4:0]   io_redirect_bits_cfiUpdate_TOSR_value,
  input          io_redirect_bits_cfiUpdate_NOS_flag,
  input  [4:0]   io_redirect_bits_cfiUpdate_NOS_value,
  input          io_redirectFromIFU,
  // ---- 性能计数（对齐 2 拍后输出） ----
  output [5:0]   io_perf_0_value,
  output [5:0]   io_perf_1_value,
  output [5:0]   io_perf_2_value,
  output [5:0]   io_perf_3_value,
  output [5:0]   io_perf_4_value,
  output [5:0]   io_perf_5_value,
  output [5:0]   io_perf_6_value,
  // ---- MBIST 子链地址/数据（bore）—— G1 把 addr/addr_rd 由 9 位收窄到 8 位 ----
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
  // ---- MBIST SRAM 侧带外控制（每 bore 7 根：hold/bypass/bp_clken/aux_clk/aux_ckbp/mcp_hold/cgen） ----
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
  // END GENERATED
);

  // ---------------------------------------------------------------------------
  // 子模块输出网：golden 叫 `_<inst>_io_*`（前导下划线只是 firtool 防撞名），
  // 这里去掉前导下划线，仍与 golden 一一对应。
  // ---------------------------------------------------------------------------
  // BEGIN GENERATED(child-nets)
  // ---- ras 的输出 ----
  wire         ras_io_ctrl_delay_io_out_ras_enable;
  // ---- ftb 的输出 ----
  wire         ftb_io_ctrl_delay_io_out_btb_enable;
  // ---- tage 的输出 ----
  wire         tage_io_ctrl_delay_io_out_tage_enable;
  wire         tage_io_ctrl_delay_io_out_sc_enable;
  // ---- uftb 的输出 ----
  wire         uftb_io_ctrl_delay_io_out_ubtb_enable;
  // ---- ittage 的输出 ----
  wire         ittage_io_out_s2_full_pred_0_br_taken_mask_0;
  wire         ittage_io_out_s2_full_pred_0_br_taken_mask_1;
  wire         ittage_io_out_s2_full_pred_0_slot_valids_0;
  wire         ittage_io_out_s2_full_pred_0_slot_valids_1;
  wire [49:0]  ittage_io_out_s2_full_pred_0_targets_0;
  wire [49:0]  ittage_io_out_s2_full_pred_0_targets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_0_jalr_target;
  wire [3:0]   ittage_io_out_s2_full_pred_0_offsets_0;
  wire [3:0]   ittage_io_out_s2_full_pred_0_offsets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_0_fallThroughAddr;
  wire         ittage_io_out_s2_full_pred_0_fallThroughErr;
  wire         ittage_io_out_s2_full_pred_0_is_jal;
  wire         ittage_io_out_s2_full_pred_0_is_jalr;
  wire         ittage_io_out_s2_full_pred_0_is_call;
  wire         ittage_io_out_s2_full_pred_0_is_ret;
  wire         ittage_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire         ittage_io_out_s2_full_pred_0_is_br_sharing;
  wire         ittage_io_out_s2_full_pred_0_hit;
  wire         ittage_io_out_s2_full_pred_1_br_taken_mask_0;
  wire         ittage_io_out_s2_full_pred_1_br_taken_mask_1;
  wire         ittage_io_out_s2_full_pred_1_slot_valids_0;
  wire         ittage_io_out_s2_full_pred_1_slot_valids_1;
  wire [49:0]  ittage_io_out_s2_full_pred_1_targets_0;
  wire [49:0]  ittage_io_out_s2_full_pred_1_targets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_1_jalr_target;
  wire [3:0]   ittage_io_out_s2_full_pred_1_offsets_0;
  wire [3:0]   ittage_io_out_s2_full_pred_1_offsets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_1_fallThroughAddr;
  wire         ittage_io_out_s2_full_pred_1_fallThroughErr;
  wire         ittage_io_out_s2_full_pred_1_is_jal;
  wire         ittage_io_out_s2_full_pred_1_is_jalr;
  wire         ittage_io_out_s2_full_pred_1_is_call;
  wire         ittage_io_out_s2_full_pred_1_is_ret;
  wire         ittage_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire         ittage_io_out_s2_full_pred_1_is_br_sharing;
  wire         ittage_io_out_s2_full_pred_1_hit;
  wire         ittage_io_out_s2_full_pred_2_br_taken_mask_0;
  wire         ittage_io_out_s2_full_pred_2_br_taken_mask_1;
  wire         ittage_io_out_s2_full_pred_2_slot_valids_0;
  wire         ittage_io_out_s2_full_pred_2_slot_valids_1;
  wire [49:0]  ittage_io_out_s2_full_pred_2_targets_0;
  wire [49:0]  ittage_io_out_s2_full_pred_2_targets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_2_jalr_target;
  wire [3:0]   ittage_io_out_s2_full_pred_2_offsets_0;
  wire [3:0]   ittage_io_out_s2_full_pred_2_offsets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_2_fallThroughAddr;
  wire         ittage_io_out_s2_full_pred_2_fallThroughErr;
  wire         ittage_io_out_s2_full_pred_2_is_jal;
  wire         ittage_io_out_s2_full_pred_2_is_jalr;
  wire         ittage_io_out_s2_full_pred_2_is_call;
  wire         ittage_io_out_s2_full_pred_2_is_ret;
  wire         ittage_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire         ittage_io_out_s2_full_pred_2_is_br_sharing;
  wire         ittage_io_out_s2_full_pred_2_hit;
  wire         ittage_io_out_s2_full_pred_3_br_taken_mask_0;
  wire         ittage_io_out_s2_full_pred_3_br_taken_mask_1;
  wire         ittage_io_out_s2_full_pred_3_slot_valids_0;
  wire         ittage_io_out_s2_full_pred_3_slot_valids_1;
  wire [49:0]  ittage_io_out_s2_full_pred_3_targets_0;
  wire [49:0]  ittage_io_out_s2_full_pred_3_targets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_3_jalr_target;
  wire [3:0]   ittage_io_out_s2_full_pred_3_offsets_0;
  wire [3:0]   ittage_io_out_s2_full_pred_3_offsets_1;
  wire [49:0]  ittage_io_out_s2_full_pred_3_fallThroughAddr;
  wire         ittage_io_out_s2_full_pred_3_fallThroughErr;
  wire         ittage_io_out_s2_full_pred_3_is_jal;
  wire         ittage_io_out_s2_full_pred_3_is_jalr;
  wire         ittage_io_out_s2_full_pred_3_is_call;
  wire         ittage_io_out_s2_full_pred_3_is_ret;
  wire         ittage_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire         ittage_io_out_s2_full_pred_3_is_br_sharing;
  wire         ittage_io_out_s2_full_pred_3_hit;
  wire         ittage_io_out_s3_full_pred_0_br_taken_mask_0;
  wire         ittage_io_out_s3_full_pred_0_br_taken_mask_1;
  wire         ittage_io_out_s3_full_pred_0_slot_valids_0;
  wire         ittage_io_out_s3_full_pred_0_slot_valids_1;
  wire [49:0]  ittage_io_out_s3_full_pred_0_targets_0;
  wire [49:0]  ittage_io_out_s3_full_pred_0_targets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_0_jalr_target;
  wire [3:0]   ittage_io_out_s3_full_pred_0_offsets_0;
  wire [3:0]   ittage_io_out_s3_full_pred_0_offsets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_0_fallThroughAddr;
  wire         ittage_io_out_s3_full_pred_0_fallThroughErr;
  wire         ittage_io_out_s3_full_pred_0_multiHit;
  wire         ittage_io_out_s3_full_pred_0_is_jal;
  wire         ittage_io_out_s3_full_pred_0_is_jalr;
  wire         ittage_io_out_s3_full_pred_0_is_call;
  wire         ittage_io_out_s3_full_pred_0_is_ret;
  wire         ittage_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire         ittage_io_out_s3_full_pred_0_is_br_sharing;
  wire         ittage_io_out_s3_full_pred_0_hit;
  wire         ittage_io_out_s3_full_pred_1_br_taken_mask_0;
  wire         ittage_io_out_s3_full_pred_1_br_taken_mask_1;
  wire         ittage_io_out_s3_full_pred_1_slot_valids_0;
  wire         ittage_io_out_s3_full_pred_1_slot_valids_1;
  wire [49:0]  ittage_io_out_s3_full_pred_1_targets_0;
  wire [49:0]  ittage_io_out_s3_full_pred_1_targets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_1_jalr_target;
  wire [3:0]   ittage_io_out_s3_full_pred_1_offsets_0;
  wire [3:0]   ittage_io_out_s3_full_pred_1_offsets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_1_fallThroughAddr;
  wire         ittage_io_out_s3_full_pred_1_fallThroughErr;
  wire         ittage_io_out_s3_full_pred_1_multiHit;
  wire         ittage_io_out_s3_full_pred_1_is_jal;
  wire         ittage_io_out_s3_full_pred_1_is_jalr;
  wire         ittage_io_out_s3_full_pred_1_is_call;
  wire         ittage_io_out_s3_full_pred_1_is_ret;
  wire         ittage_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire         ittage_io_out_s3_full_pred_1_is_br_sharing;
  wire         ittage_io_out_s3_full_pred_1_hit;
  wire         ittage_io_out_s3_full_pred_2_br_taken_mask_0;
  wire         ittage_io_out_s3_full_pred_2_br_taken_mask_1;
  wire         ittage_io_out_s3_full_pred_2_slot_valids_0;
  wire         ittage_io_out_s3_full_pred_2_slot_valids_1;
  wire [49:0]  ittage_io_out_s3_full_pred_2_targets_0;
  wire [49:0]  ittage_io_out_s3_full_pred_2_targets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_2_jalr_target;
  wire [3:0]   ittage_io_out_s3_full_pred_2_offsets_0;
  wire [3:0]   ittage_io_out_s3_full_pred_2_offsets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_2_fallThroughAddr;
  wire         ittage_io_out_s3_full_pred_2_fallThroughErr;
  wire         ittage_io_out_s3_full_pred_2_multiHit;
  wire         ittage_io_out_s3_full_pred_2_is_jal;
  wire         ittage_io_out_s3_full_pred_2_is_jalr;
  wire         ittage_io_out_s3_full_pred_2_is_call;
  wire         ittage_io_out_s3_full_pred_2_is_ret;
  wire         ittage_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire         ittage_io_out_s3_full_pred_2_is_br_sharing;
  wire         ittage_io_out_s3_full_pred_2_hit;
  wire         ittage_io_out_s3_full_pred_3_br_taken_mask_0;
  wire         ittage_io_out_s3_full_pred_3_br_taken_mask_1;
  wire         ittage_io_out_s3_full_pred_3_slot_valids_0;
  wire         ittage_io_out_s3_full_pred_3_slot_valids_1;
  wire [49:0]  ittage_io_out_s3_full_pred_3_targets_0;
  wire [49:0]  ittage_io_out_s3_full_pred_3_targets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_3_jalr_target;
  wire [3:0]   ittage_io_out_s3_full_pred_3_offsets_0;
  wire [3:0]   ittage_io_out_s3_full_pred_3_offsets_1;
  wire [49:0]  ittage_io_out_s3_full_pred_3_fallThroughAddr;
  wire         ittage_io_out_s3_full_pred_3_fallThroughErr;
  wire         ittage_io_out_s3_full_pred_3_multiHit;
  wire         ittage_io_out_s3_full_pred_3_is_jal;
  wire         ittage_io_out_s3_full_pred_3_is_jalr;
  wire         ittage_io_out_s3_full_pred_3_is_call;
  wire         ittage_io_out_s3_full_pred_3_is_ret;
  wire         ittage_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire         ittage_io_out_s3_full_pred_3_is_br_sharing;
  wire         ittage_io_out_s3_full_pred_3_hit;
  wire [515:0] ittage_io_out_last_stage_meta;
  wire         ittage_io_out_last_stage_spec_info_sc_disagree_0;
  wire         ittage_io_out_last_stage_spec_info_sc_disagree_1;
  wire         ittage_io_out_last_stage_ftb_entry_isCall;
  wire         ittage_io_out_last_stage_ftb_entry_isRet;
  wire         ittage_io_out_last_stage_ftb_entry_isJalr;
  wire         ittage_io_out_last_stage_ftb_entry_valid;
  wire [3:0]   ittage_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire         ittage_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire         ittage_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0]  ittage_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0]   ittage_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0]   ittage_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire         ittage_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire         ittage_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0]  ittage_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0]   ittage_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0]   ittage_io_out_last_stage_ftb_entry_pftAddr;
  wire         ittage_io_out_last_stage_ftb_entry_carry;
  wire         ittage_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire         ittage_io_out_last_stage_ftb_entry_strong_bias_0;
  wire         ittage_io_out_last_stage_ftb_entry_strong_bias_1;
  wire         ittage_io_s1_ready;
  // ---- ras 的输出 ----
  wire [515:0] ras_io_out_last_stage_meta;
  // ---- tage 的输出 ----
  wire         tage_io_out_s2_full_pred_0_br_taken_mask_0;
  wire         tage_io_out_s2_full_pred_0_br_taken_mask_1;
  wire         tage_io_out_s2_full_pred_1_br_taken_mask_0;
  wire         tage_io_out_s2_full_pred_1_br_taken_mask_1;
  wire         tage_io_out_s2_full_pred_2_br_taken_mask_0;
  wire         tage_io_out_s2_full_pred_2_br_taken_mask_1;
  wire         tage_io_out_s2_full_pred_3_br_taken_mask_0;
  wire         tage_io_out_s2_full_pred_3_br_taken_mask_1;
  wire         tage_io_out_s3_full_pred_0_br_taken_mask_0;
  wire         tage_io_out_s3_full_pred_0_br_taken_mask_1;
  wire         tage_io_out_s3_full_pred_1_br_taken_mask_0;
  wire         tage_io_out_s3_full_pred_1_br_taken_mask_1;
  wire         tage_io_out_s3_full_pred_2_br_taken_mask_0;
  wire         tage_io_out_s3_full_pred_2_br_taken_mask_1;
  wire         tage_io_out_s3_full_pred_3_br_taken_mask_0;
  wire         tage_io_out_s3_full_pred_3_br_taken_mask_1;
  wire [515:0] tage_io_out_last_stage_meta;
  wire         tage_io_out_last_stage_spec_info_sc_disagree_0;
  wire         tage_io_out_last_stage_spec_info_sc_disagree_1;
  wire         tage_io_s1_ready;
  wire [5:0]   tage_io_perf_0_value;
  wire [5:0]   tage_io_perf_1_value;
  wire [5:0]   tage_io_perf_2_value;
  // ---- uftb 的输出 ----
  wire         uftb_io_out_s1_full_pred_0_br_taken_mask_0;
  wire         uftb_io_out_s1_full_pred_0_br_taken_mask_1;
  wire [515:0] uftb_io_out_last_stage_meta;
  wire         uftb_io_fauftb_entry_out_isCall;
  wire         uftb_io_fauftb_entry_out_isRet;
  wire         uftb_io_fauftb_entry_out_isJalr;
  wire         uftb_io_fauftb_entry_out_valid;
  wire [3:0]   uftb_io_fauftb_entry_out_brSlots_0_offset;
  wire         uftb_io_fauftb_entry_out_brSlots_0_sharing;
  wire         uftb_io_fauftb_entry_out_brSlots_0_valid;
  wire [11:0]  uftb_io_fauftb_entry_out_brSlots_0_lower;
  wire [1:0]   uftb_io_fauftb_entry_out_brSlots_0_tarStat;
  wire [3:0]   uftb_io_fauftb_entry_out_tailSlot_offset;
  wire         uftb_io_fauftb_entry_out_tailSlot_sharing;
  wire         uftb_io_fauftb_entry_out_tailSlot_valid;
  wire [19:0]  uftb_io_fauftb_entry_out_tailSlot_lower;
  wire [1:0]   uftb_io_fauftb_entry_out_tailSlot_tarStat;
  wire [3:0]   uftb_io_fauftb_entry_out_pftAddr;
  wire         uftb_io_fauftb_entry_out_carry;
  wire         uftb_io_fauftb_entry_out_last_may_be_rvi_call;
  wire         uftb_io_fauftb_entry_out_strong_bias_0;
  wire         uftb_io_fauftb_entry_out_strong_bias_1;
  wire         uftb_io_fauftb_entry_hit_out;
  wire [5:0]   uftb_io_perf_0_value;
  wire [5:0]   uftb_io_perf_1_value;
  // ---- ftb 的输出 ----
  wire         ftb_io_out_s2_full_pred_0_br_taken_mask_0;
  wire         ftb_io_out_s2_full_pred_0_br_taken_mask_1;
  wire         ftb_io_out_s2_full_pred_0_slot_valids_0;
  wire         ftb_io_out_s2_full_pred_0_slot_valids_1;
  wire [49:0]  ftb_io_out_s2_full_pred_0_targets_0;
  wire [49:0]  ftb_io_out_s2_full_pred_0_targets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_0_jalr_target;
  wire [3:0]   ftb_io_out_s2_full_pred_0_offsets_0;
  wire [3:0]   ftb_io_out_s2_full_pred_0_offsets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_0_fallThroughAddr;
  wire         ftb_io_out_s2_full_pred_0_fallThroughErr;
  wire         ftb_io_out_s2_full_pred_0_is_jal;
  wire         ftb_io_out_s2_full_pred_0_is_jalr;
  wire         ftb_io_out_s2_full_pred_0_is_call;
  wire         ftb_io_out_s2_full_pred_0_is_ret;
  wire         ftb_io_out_s2_full_pred_0_last_may_be_rvi_call;
  wire         ftb_io_out_s2_full_pred_0_is_br_sharing;
  wire         ftb_io_out_s2_full_pred_0_hit;
  wire         ftb_io_out_s2_full_pred_1_br_taken_mask_0;
  wire         ftb_io_out_s2_full_pred_1_br_taken_mask_1;
  wire         ftb_io_out_s2_full_pred_1_slot_valids_0;
  wire         ftb_io_out_s2_full_pred_1_slot_valids_1;
  wire [49:0]  ftb_io_out_s2_full_pred_1_targets_0;
  wire [49:0]  ftb_io_out_s2_full_pred_1_targets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_1_jalr_target;
  wire [3:0]   ftb_io_out_s2_full_pred_1_offsets_0;
  wire [3:0]   ftb_io_out_s2_full_pred_1_offsets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_1_fallThroughAddr;
  wire         ftb_io_out_s2_full_pred_1_fallThroughErr;
  wire         ftb_io_out_s2_full_pred_1_is_jal;
  wire         ftb_io_out_s2_full_pred_1_is_jalr;
  wire         ftb_io_out_s2_full_pred_1_is_call;
  wire         ftb_io_out_s2_full_pred_1_is_ret;
  wire         ftb_io_out_s2_full_pred_1_last_may_be_rvi_call;
  wire         ftb_io_out_s2_full_pred_1_is_br_sharing;
  wire         ftb_io_out_s2_full_pred_1_hit;
  wire         ftb_io_out_s2_full_pred_2_br_taken_mask_0;
  wire         ftb_io_out_s2_full_pred_2_br_taken_mask_1;
  wire         ftb_io_out_s2_full_pred_2_slot_valids_0;
  wire         ftb_io_out_s2_full_pred_2_slot_valids_1;
  wire [49:0]  ftb_io_out_s2_full_pred_2_targets_0;
  wire [49:0]  ftb_io_out_s2_full_pred_2_targets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_2_jalr_target;
  wire [3:0]   ftb_io_out_s2_full_pred_2_offsets_0;
  wire [3:0]   ftb_io_out_s2_full_pred_2_offsets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_2_fallThroughAddr;
  wire         ftb_io_out_s2_full_pred_2_fallThroughErr;
  wire         ftb_io_out_s2_full_pred_2_is_jal;
  wire         ftb_io_out_s2_full_pred_2_is_jalr;
  wire         ftb_io_out_s2_full_pred_2_is_call;
  wire         ftb_io_out_s2_full_pred_2_is_ret;
  wire         ftb_io_out_s2_full_pred_2_last_may_be_rvi_call;
  wire         ftb_io_out_s2_full_pred_2_is_br_sharing;
  wire         ftb_io_out_s2_full_pred_2_hit;
  wire         ftb_io_out_s2_full_pred_3_br_taken_mask_0;
  wire         ftb_io_out_s2_full_pred_3_br_taken_mask_1;
  wire         ftb_io_out_s2_full_pred_3_slot_valids_0;
  wire         ftb_io_out_s2_full_pred_3_slot_valids_1;
  wire [49:0]  ftb_io_out_s2_full_pred_3_targets_0;
  wire [49:0]  ftb_io_out_s2_full_pred_3_targets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_3_jalr_target;
  wire [3:0]   ftb_io_out_s2_full_pred_3_offsets_0;
  wire [3:0]   ftb_io_out_s2_full_pred_3_offsets_1;
  wire [49:0]  ftb_io_out_s2_full_pred_3_fallThroughAddr;
  wire         ftb_io_out_s2_full_pred_3_fallThroughErr;
  wire         ftb_io_out_s2_full_pred_3_is_jal;
  wire         ftb_io_out_s2_full_pred_3_is_jalr;
  wire         ftb_io_out_s2_full_pred_3_is_call;
  wire         ftb_io_out_s2_full_pred_3_is_ret;
  wire         ftb_io_out_s2_full_pred_3_last_may_be_rvi_call;
  wire         ftb_io_out_s2_full_pred_3_is_br_sharing;
  wire         ftb_io_out_s2_full_pred_3_hit;
  wire         ftb_io_out_s3_full_pred_0_br_taken_mask_0;
  wire         ftb_io_out_s3_full_pred_0_br_taken_mask_1;
  wire         ftb_io_out_s3_full_pred_0_slot_valids_0;
  wire         ftb_io_out_s3_full_pred_0_slot_valids_1;
  wire [49:0]  ftb_io_out_s3_full_pred_0_targets_0;
  wire [49:0]  ftb_io_out_s3_full_pred_0_targets_1;
  wire [3:0]   ftb_io_out_s3_full_pred_0_offsets_0;
  wire [3:0]   ftb_io_out_s3_full_pred_0_offsets_1;
  wire [49:0]  ftb_io_out_s3_full_pred_0_fallThroughAddr;
  wire         ftb_io_out_s3_full_pred_0_fallThroughErr;
  wire         ftb_io_out_s3_full_pred_0_multiHit;
  wire         ftb_io_out_s3_full_pred_0_is_jal;
  wire         ftb_io_out_s3_full_pred_0_is_jalr;
  wire         ftb_io_out_s3_full_pred_0_is_call;
  wire         ftb_io_out_s3_full_pred_0_is_ret;
  wire         ftb_io_out_s3_full_pred_0_last_may_be_rvi_call;
  wire         ftb_io_out_s3_full_pred_0_is_br_sharing;
  wire         ftb_io_out_s3_full_pred_0_hit;
  wire         ftb_io_out_s3_full_pred_1_br_taken_mask_0;
  wire         ftb_io_out_s3_full_pred_1_br_taken_mask_1;
  wire         ftb_io_out_s3_full_pred_1_slot_valids_0;
  wire         ftb_io_out_s3_full_pred_1_slot_valids_1;
  wire [49:0]  ftb_io_out_s3_full_pred_1_targets_0;
  wire [49:0]  ftb_io_out_s3_full_pred_1_targets_1;
  wire [3:0]   ftb_io_out_s3_full_pred_1_offsets_0;
  wire [3:0]   ftb_io_out_s3_full_pred_1_offsets_1;
  wire [49:0]  ftb_io_out_s3_full_pred_1_fallThroughAddr;
  wire         ftb_io_out_s3_full_pred_1_fallThroughErr;
  wire         ftb_io_out_s3_full_pred_1_multiHit;
  wire         ftb_io_out_s3_full_pred_1_is_jal;
  wire         ftb_io_out_s3_full_pred_1_is_jalr;
  wire         ftb_io_out_s3_full_pred_1_is_call;
  wire         ftb_io_out_s3_full_pred_1_is_ret;
  wire         ftb_io_out_s3_full_pred_1_last_may_be_rvi_call;
  wire         ftb_io_out_s3_full_pred_1_is_br_sharing;
  wire         ftb_io_out_s3_full_pred_1_hit;
  wire         ftb_io_out_s3_full_pred_2_br_taken_mask_0;
  wire         ftb_io_out_s3_full_pred_2_br_taken_mask_1;
  wire         ftb_io_out_s3_full_pred_2_slot_valids_0;
  wire         ftb_io_out_s3_full_pred_2_slot_valids_1;
  wire [49:0]  ftb_io_out_s3_full_pred_2_targets_0;
  wire [49:0]  ftb_io_out_s3_full_pred_2_targets_1;
  wire [3:0]   ftb_io_out_s3_full_pred_2_offsets_0;
  wire [3:0]   ftb_io_out_s3_full_pred_2_offsets_1;
  wire [49:0]  ftb_io_out_s3_full_pred_2_fallThroughAddr;
  wire         ftb_io_out_s3_full_pred_2_fallThroughErr;
  wire         ftb_io_out_s3_full_pred_2_multiHit;
  wire         ftb_io_out_s3_full_pred_2_is_jal;
  wire         ftb_io_out_s3_full_pred_2_is_jalr;
  wire         ftb_io_out_s3_full_pred_2_is_call;
  wire         ftb_io_out_s3_full_pred_2_is_ret;
  wire         ftb_io_out_s3_full_pred_2_last_may_be_rvi_call;
  wire         ftb_io_out_s3_full_pred_2_is_br_sharing;
  wire         ftb_io_out_s3_full_pred_2_hit;
  wire         ftb_io_out_s3_full_pred_3_br_taken_mask_0;
  wire         ftb_io_out_s3_full_pred_3_br_taken_mask_1;
  wire         ftb_io_out_s3_full_pred_3_slot_valids_0;
  wire         ftb_io_out_s3_full_pred_3_slot_valids_1;
  wire [49:0]  ftb_io_out_s3_full_pred_3_targets_0;
  wire [49:0]  ftb_io_out_s3_full_pred_3_targets_1;
  wire [3:0]   ftb_io_out_s3_full_pred_3_offsets_0;
  wire [3:0]   ftb_io_out_s3_full_pred_3_offsets_1;
  wire [49:0]  ftb_io_out_s3_full_pred_3_fallThroughAddr;
  wire         ftb_io_out_s3_full_pred_3_fallThroughErr;
  wire         ftb_io_out_s3_full_pred_3_multiHit;
  wire         ftb_io_out_s3_full_pred_3_is_jal;
  wire         ftb_io_out_s3_full_pred_3_is_jalr;
  wire         ftb_io_out_s3_full_pred_3_is_call;
  wire         ftb_io_out_s3_full_pred_3_is_ret;
  wire         ftb_io_out_s3_full_pred_3_last_may_be_rvi_call;
  wire         ftb_io_out_s3_full_pred_3_is_br_sharing;
  wire         ftb_io_out_s3_full_pred_3_hit;
  wire         ftb_io_out_s1_uftbHit;
  wire         ftb_io_out_s1_uftbHasIndirect;
  wire         ftb_io_out_s1_ftbCloseReq;
  wire [515:0] ftb_io_out_last_stage_meta;
  wire         ftb_io_out_last_stage_spec_info_sc_disagree_0;
  wire         ftb_io_out_last_stage_spec_info_sc_disagree_1;
  wire         ftb_io_out_last_stage_ftb_entry_isCall;
  wire         ftb_io_out_last_stage_ftb_entry_isRet;
  wire         ftb_io_out_last_stage_ftb_entry_isJalr;
  wire         ftb_io_out_last_stage_ftb_entry_valid;
  wire [3:0]   ftb_io_out_last_stage_ftb_entry_brSlots_0_offset;
  wire         ftb_io_out_last_stage_ftb_entry_brSlots_0_sharing;
  wire         ftb_io_out_last_stage_ftb_entry_brSlots_0_valid;
  wire [11:0]  ftb_io_out_last_stage_ftb_entry_brSlots_0_lower;
  wire [1:0]   ftb_io_out_last_stage_ftb_entry_brSlots_0_tarStat;
  wire [3:0]   ftb_io_out_last_stage_ftb_entry_tailSlot_offset;
  wire         ftb_io_out_last_stage_ftb_entry_tailSlot_sharing;
  wire         ftb_io_out_last_stage_ftb_entry_tailSlot_valid;
  wire [19:0]  ftb_io_out_last_stage_ftb_entry_tailSlot_lower;
  wire [1:0]   ftb_io_out_last_stage_ftb_entry_tailSlot_tarStat;
  wire [3:0]   ftb_io_out_last_stage_ftb_entry_pftAddr;
  wire         ftb_io_out_last_stage_ftb_entry_carry;
  wire         ftb_io_out_last_stage_ftb_entry_last_may_be_rvi_call;
  wire         ftb_io_out_last_stage_ftb_entry_strong_bias_0;
  wire         ftb_io_out_last_stage_ftb_entry_strong_bias_1;
  wire         ftb_io_s1_ready;
  wire [5:0]   ftb_io_perf_0_value;
  wire [5:0]   ftb_io_perf_1_value;
  // END GENERATED

  // ---------------------------------------------------------------------------
  // 五个预测器 + 四个 ctrl 打拍器的例化。
  // resp_in 链序：uftb → tage → ftb → ittage → ras（链尾）。S1 输出由链头 uftb 直驱，
  // S2/S3 输出由链尾 ras 直驱，所以下面这些例化块里 `(io_out_*)` 形式的连接就是
  // "该输出端口的驱动者"。
  // ---------------------------------------------------------------------------
  // BEGIN GENERATED(instances)

  // ---------------------------------------------------------------------------
  // FTB ftb —— 链 3/5 大容量组相联 FTB：给取指块的 CFI 槽/目标/fall-through
  // ---------------------------------------------------------------------------
  FTB ftb (
    // -- 时钟与复位 --
    .clock                                                   (clock),
    .reset                                                   (reset),
    // -- 复位向量（复位后第一个取指 PC） --
    .io_reset_vector                                         (io_reset_vector),
    // -- S0 预测请求：PC + 全局/折叠历史 --
    .io_in_bits_s0_pc_0                                      (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                                      (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                                      (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                                      (io_in_bits_s0_pc_3),
    // -- S0 预测请求：其余字段 --
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0     (tage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1     (tage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0     (tage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1     (tage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0     (tage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1     (tage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0     (tage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1     (tage_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0     (tage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1     (tage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0     (tage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1     (tage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0     (tage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1     (tage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0     (tage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1     (tage_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0 (tage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1 (tage_io_out_last_stage_spec_info_sc_disagree_1),
    // -- S2 预测输出（FTB / TAGE 覆盖） --
    .io_out_s2_full_pred_0_br_taken_mask_0                   (ftb_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1                   (ftb_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0                     (ftb_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1                     (ftb_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0                         (ftb_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1                         (ftb_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target                       (ftb_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0                         (ftb_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1                         (ftb_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr                   (ftb_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr                    (ftb_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal                            (ftb_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr                           (ftb_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call                           (ftb_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret                            (ftb_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call              (ftb_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing                     (ftb_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit                               (ftb_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0                   (ftb_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1                   (ftb_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0                     (ftb_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1                     (ftb_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0                         (ftb_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1                         (ftb_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target                       (ftb_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0                         (ftb_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1                         (ftb_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr                   (ftb_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr                    (ftb_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal                            (ftb_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr                           (ftb_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call                           (ftb_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret                            (ftb_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call              (ftb_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing                     (ftb_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit                               (ftb_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0                   (ftb_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1                   (ftb_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0                     (ftb_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1                     (ftb_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0                         (ftb_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1                         (ftb_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target                       (ftb_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0                         (ftb_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1                         (ftb_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr                   (ftb_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr                    (ftb_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal                            (ftb_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr                           (ftb_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call                           (ftb_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret                            (ftb_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call              (ftb_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing                     (ftb_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit                               (ftb_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0                   (ftb_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1                   (ftb_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0                     (ftb_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1                     (ftb_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0                         (ftb_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1                         (ftb_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target                       (ftb_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0                         (ftb_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1                         (ftb_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr                   (ftb_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr                    (ftb_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal                            (ftb_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr                           (ftb_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call                           (ftb_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret                            (ftb_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call              (ftb_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing                     (ftb_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit                               (ftb_io_out_s2_full_pred_3_hit),
    // -- S3 预测输出（SC / ITTAGE / RAS 覆盖） --
    .io_out_s3_full_pred_0_br_taken_mask_0                   (ftb_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1                   (ftb_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0                     (ftb_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1                     (ftb_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0                         (ftb_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1                         (ftb_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_offsets_0                         (ftb_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1                         (ftb_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr                   (ftb_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr                    (ftb_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit                          (ftb_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal                            (ftb_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr                           (ftb_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call                           (ftb_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret                            (ftb_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call              (ftb_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing                     (ftb_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit                               (ftb_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0                   (ftb_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1                   (ftb_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0                     (ftb_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1                     (ftb_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0                         (ftb_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1                         (ftb_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_offsets_0                         (ftb_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1                         (ftb_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr                   (ftb_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr                    (ftb_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit                          (ftb_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal                            (ftb_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr                           (ftb_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call                           (ftb_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret                            (ftb_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call              (ftb_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing                     (ftb_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit                               (ftb_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0                   (ftb_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1                   (ftb_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0                     (ftb_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1                     (ftb_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0                         (ftb_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1                         (ftb_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_offsets_0                         (ftb_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1                         (ftb_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr                   (ftb_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr                    (ftb_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit                          (ftb_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal                            (ftb_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr                           (ftb_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call                           (ftb_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret                            (ftb_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call              (ftb_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing                     (ftb_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit                               (ftb_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0                   (ftb_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1                   (ftb_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0                     (ftb_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1                     (ftb_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0                         (ftb_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1                         (ftb_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_offsets_0                         (ftb_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1                         (ftb_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr                   (ftb_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr                    (ftb_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit                          (ftb_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal                            (ftb_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr                           (ftb_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call                           (ftb_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret                            (ftb_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call              (ftb_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing                     (ftb_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit                               (ftb_io_out_s3_full_pred_3_hit),
    // -- S1 预测输出（uFTB 零气泡首版） --
    .io_out_s1_uftbHit                                       (ftb_io_out_s1_uftbHit),
    .io_out_s1_uftbHasIndirect                               (ftb_io_out_s1_uftbHasIndirect),
    .io_out_s1_ftbCloseReq                                   (ftb_io_out_s1_ftbCloseReq),
    // -- 末级 meta / FTB entry（写回 FTQ，update 时原样送回） --
    .io_out_last_stage_meta                                  (ftb_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0               (ftb_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1               (ftb_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall                      (ftb_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet                       (ftb_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr                      (ftb_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid                       (ftb_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset            (ftb_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing           (ftb_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid             (ftb_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower             (ftb_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat           (ftb_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset             (ftb_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing            (ftb_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid              (ftb_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower              (ftb_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat            (ftb_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr                     (ftb_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry                       (ftb_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call        (ftb_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0               (ftb_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1               (ftb_io_out_last_stage_ftb_entry_strong_bias_1),
    // -- 其余 io --
    .io_fauftb_entry_in_isCall                               (uftb_io_fauftb_entry_out_isCall),
    .io_fauftb_entry_in_isRet                                (uftb_io_fauftb_entry_out_isRet),
    .io_fauftb_entry_in_isJalr                               (uftb_io_fauftb_entry_out_isJalr),
    .io_fauftb_entry_in_valid                                (uftb_io_fauftb_entry_out_valid),
    .io_fauftb_entry_in_brSlots_0_offset                     (uftb_io_fauftb_entry_out_brSlots_0_offset),
    .io_fauftb_entry_in_brSlots_0_sharing                    (uftb_io_fauftb_entry_out_brSlots_0_sharing),
    .io_fauftb_entry_in_brSlots_0_valid                      (uftb_io_fauftb_entry_out_brSlots_0_valid),
    .io_fauftb_entry_in_brSlots_0_lower                      (uftb_io_fauftb_entry_out_brSlots_0_lower),
    .io_fauftb_entry_in_brSlots_0_tarStat                    (uftb_io_fauftb_entry_out_brSlots_0_tarStat),
    .io_fauftb_entry_in_tailSlot_offset                      (uftb_io_fauftb_entry_out_tailSlot_offset),
    .io_fauftb_entry_in_tailSlot_sharing                     (uftb_io_fauftb_entry_out_tailSlot_sharing),
    .io_fauftb_entry_in_tailSlot_valid                       (uftb_io_fauftb_entry_out_tailSlot_valid),
    .io_fauftb_entry_in_tailSlot_lower                       (uftb_io_fauftb_entry_out_tailSlot_lower),
    .io_fauftb_entry_in_tailSlot_tarStat                     (uftb_io_fauftb_entry_out_tailSlot_tarStat),
    .io_fauftb_entry_in_pftAddr                              (uftb_io_fauftb_entry_out_pftAddr),
    .io_fauftb_entry_in_carry                                (uftb_io_fauftb_entry_out_carry),
    .io_fauftb_entry_in_last_may_be_rvi_call                 (uftb_io_fauftb_entry_out_last_may_be_rvi_call),
    .io_fauftb_entry_in_strong_bias_0                        (uftb_io_fauftb_entry_out_strong_bias_0),
    .io_fauftb_entry_in_strong_bias_1                        (uftb_io_fauftb_entry_out_strong_bias_1),
    .io_fauftb_entry_hit_in                                  (uftb_io_fauftb_entry_hit_out),
    // -- 各预测器使能开关（CSR 可关） --
    .io_ctrl_btb_enable                                      (ftb_io_ctrl_delay_io_out_btb_enable),
    // -- S0~S3 流水握手（fire = valid & ready，4 份 dup） --
    .io_s0_fire_0                                            (io_s0_fire_0),
    .io_s0_fire_1                                            (io_s0_fire_1),
    .io_s0_fire_2                                            (io_s0_fire_2),
    .io_s0_fire_3                                            (io_s0_fire_3),
    .io_s1_fire_0                                            (io_s1_fire_0),
    .io_s1_fire_1                                            (io_s1_fire_1),
    .io_s1_fire_2                                            (io_s1_fire_2),
    .io_s1_fire_3                                            (io_s1_fire_3),
    .io_s2_fire_0                                            (io_s2_fire_0),
    .io_s2_fire_1                                            (io_s2_fire_1),
    .io_s2_fire_2                                            (io_s2_fire_2),
    .io_s2_fire_3                                            (io_s2_fire_3),
    .io_s3_fire_0                                            (io_s3_fire_0),
    // -- S1 就绪（三大表相与） --
    .io_s1_ready                                             (ftb_io_s1_ready),
    // -- FTQ commit 回来的训练更新 --
    .io_update_valid                                         (io_update_valid),
    .io_update_bits_pc                                       (io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall                         (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet                          (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr                         (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid                          (io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset               (io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing              (io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid                (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower                (io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat              (io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset                (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing               (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid                 (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower                 (io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat               (io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr                        (io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry                          (io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call           (io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0                  (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1                  (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_false_hit                                (io_update_bits_false_hit),
    .io_update_bits_old_entry                                (io_update_bits_old_entry),
    .io_update_bits_meta                                     ({192'h0, io_update_bits_meta[515:192]}),
    // -- 重定向（错预测纠正 / 恢复历史） --
    .io_redirectFromIFU                                      (io_redirectFromIFU),
    // -- 性能计数（对齐 2 拍后输出） --
    .io_perf_0_value                                         (ftb_io_perf_0_value),
    .io_perf_1_value                                         (ftb_io_perf_1_value),
    // -- MBIST 子链地址/数据（bore）—— G1 把 addr/addr_rd 由 9 位收窄到 8 位 --
    .boreChildrenBd_bore_array                               (boreChildrenBd_bore_array),
    .boreChildrenBd_bore_all                                 (boreChildrenBd_bore_all),
    .boreChildrenBd_bore_req                                 (boreChildrenBd_bore_req),
    .boreChildrenBd_bore_ack                                 (boreChildrenBd_bore_ack),
    .boreChildrenBd_bore_writeen                             (boreChildrenBd_bore_writeen),
    .boreChildrenBd_bore_be                                  (boreChildrenBd_bore_be),
    .boreChildrenBd_bore_addr                                (boreChildrenBd_bore_addr),
    .boreChildrenBd_bore_indata                              (boreChildrenBd_bore_indata),
    .boreChildrenBd_bore_readen                              (boreChildrenBd_bore_readen),
    .boreChildrenBd_bore_addr_rd                             (boreChildrenBd_bore_addr_rd),
    .boreChildrenBd_bore_outdata                             (boreChildrenBd_bore_outdata),
    // -- MBIST SRAM 侧带外控制（每 bore 7 根：hold/bypass/bp_clken/aux_clk/aux_ckbp/mcp_hold/cgen） --
    .sigFromSrams_bore_ram_hold                              (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass                            (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken                          (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                           (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp                          (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold                          (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen                                  (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold                            (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass                          (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken                        (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk                         (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp                        (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold                        (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                                (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold                            (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass                          (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken                        (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk                         (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp                        (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold                        (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                                (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold                            (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass                          (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken                        (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk                         (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp                        (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold                        (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                                (sigFromSrams_bore_3_cgen),
    .sigFromSrams_bore_4_ram_hold                            (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_4_ram_bypass                          (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken                        (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk                         (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp                        (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold                        (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                                (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_5_ram_hold                            (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_5_ram_bypass                          (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken                        (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk                         (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp                        (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold                        (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                                (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_6_ram_hold                            (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_6_ram_bypass                          (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken                        (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk                         (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp                        (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold                        (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                                (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_7_ram_hold                            (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_7_ram_bypass                          (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken                        (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk                         (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp                        (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold                        (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                                (sigFromSrams_bore_7_cgen)
  );

  // ---------------------------------------------------------------------------
  // FauFTB uftb —— 链头 uFTB(FauFTB)：32 路全相联微 FTB，S1 零气泡出第一版预测；74 个顶层 S1 输出由它直驱，另把 s1 br_taken_mask 送给 tage
  // ---------------------------------------------------------------------------
  FauFTB uftb (
    // -- 时钟与复位 --
    .clock                                         (clock),
    .reset                                         (reset),
    // -- 复位向量（复位后第一个取指 PC） --
    .io_reset_vector                               (io_reset_vector),
    // -- S0 预测请求：PC + 全局/折叠历史 --
    .io_in_bits_s0_pc_0                            (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                            (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                            (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                            (io_in_bits_s0_pc_3),
    // -- S1 预测输出（uFTB 零气泡首版） --
    .io_out_s1_pc_0                                (io_out_s1_pc_0),
    .io_out_s1_pc_1                                (io_out_s1_pc_1),
    .io_out_s1_pc_2                                (io_out_s1_pc_2),
    .io_out_s1_pc_3                                (io_out_s1_pc_3),
    .io_out_s1_full_pred_0_br_taken_mask_0         (uftb_io_out_s1_full_pred_0_br_taken_mask_0),
    .io_out_s1_full_pred_0_br_taken_mask_1         (uftb_io_out_s1_full_pred_0_br_taken_mask_1),
    .io_out_s1_full_pred_0_slot_valids_0           (io_out_s1_full_pred_0_slot_valids_0),
    .io_out_s1_full_pred_0_slot_valids_1           (io_out_s1_full_pred_0_slot_valids_1),
    .io_out_s1_full_pred_0_targets_0               (io_out_s1_full_pred_0_targets_0),
    .io_out_s1_full_pred_0_targets_1               (io_out_s1_full_pred_0_targets_1),
    .io_out_s1_full_pred_0_jalr_target             (io_out_s1_full_pred_0_jalr_target),
    .io_out_s1_full_pred_0_offsets_0               (io_out_s1_full_pred_0_offsets_0),
    .io_out_s1_full_pred_0_offsets_1               (io_out_s1_full_pred_0_offsets_1),
    .io_out_s1_full_pred_0_fallThroughAddr         (io_out_s1_full_pred_0_fallThroughAddr),
    .io_out_s1_full_pred_0_fallThroughErr          (io_out_s1_full_pred_0_fallThroughErr),
    .io_out_s1_full_pred_0_is_jal                  (io_out_s1_full_pred_0_is_jal),
    .io_out_s1_full_pred_0_is_jalr                 (io_out_s1_full_pred_0_is_jalr),
    .io_out_s1_full_pred_0_is_call                 (io_out_s1_full_pred_0_is_call),
    .io_out_s1_full_pred_0_is_ret                  (io_out_s1_full_pred_0_is_ret),
    .io_out_s1_full_pred_0_last_may_be_rvi_call    (io_out_s1_full_pred_0_last_may_be_rvi_call),
    .io_out_s1_full_pred_0_is_br_sharing           (io_out_s1_full_pred_0_is_br_sharing),
    .io_out_s1_full_pred_0_hit                     (io_out_s1_full_pred_0_hit),
    .io_out_s1_full_pred_1_br_taken_mask_0         (io_out_s1_full_pred_1_br_taken_mask_0),
    .io_out_s1_full_pred_1_br_taken_mask_1         (io_out_s1_full_pred_1_br_taken_mask_1),
    .io_out_s1_full_pred_1_slot_valids_0           (io_out_s1_full_pred_1_slot_valids_0),
    .io_out_s1_full_pred_1_slot_valids_1           (io_out_s1_full_pred_1_slot_valids_1),
    .io_out_s1_full_pred_1_targets_0               (io_out_s1_full_pred_1_targets_0),
    .io_out_s1_full_pred_1_targets_1               (io_out_s1_full_pred_1_targets_1),
    .io_out_s1_full_pred_1_jalr_target             (io_out_s1_full_pred_1_jalr_target),
    .io_out_s1_full_pred_1_offsets_0               (io_out_s1_full_pred_1_offsets_0),
    .io_out_s1_full_pred_1_offsets_1               (io_out_s1_full_pred_1_offsets_1),
    .io_out_s1_full_pred_1_fallThroughAddr         (io_out_s1_full_pred_1_fallThroughAddr),
    .io_out_s1_full_pred_1_fallThroughErr          (io_out_s1_full_pred_1_fallThroughErr),
    .io_out_s1_full_pred_1_is_jal                  (io_out_s1_full_pred_1_is_jal),
    .io_out_s1_full_pred_1_is_jalr                 (io_out_s1_full_pred_1_is_jalr),
    .io_out_s1_full_pred_1_is_call                 (io_out_s1_full_pred_1_is_call),
    .io_out_s1_full_pred_1_is_ret                  (io_out_s1_full_pred_1_is_ret),
    .io_out_s1_full_pred_1_last_may_be_rvi_call    (io_out_s1_full_pred_1_last_may_be_rvi_call),
    .io_out_s1_full_pred_1_is_br_sharing           (io_out_s1_full_pred_1_is_br_sharing),
    .io_out_s1_full_pred_1_hit                     (io_out_s1_full_pred_1_hit),
    .io_out_s1_full_pred_2_br_taken_mask_0         (io_out_s1_full_pred_2_br_taken_mask_0),
    .io_out_s1_full_pred_2_br_taken_mask_1         (io_out_s1_full_pred_2_br_taken_mask_1),
    .io_out_s1_full_pred_2_slot_valids_0           (io_out_s1_full_pred_2_slot_valids_0),
    .io_out_s1_full_pred_2_slot_valids_1           (io_out_s1_full_pred_2_slot_valids_1),
    .io_out_s1_full_pred_2_targets_0               (io_out_s1_full_pred_2_targets_0),
    .io_out_s1_full_pred_2_targets_1               (io_out_s1_full_pred_2_targets_1),
    .io_out_s1_full_pred_2_jalr_target             (io_out_s1_full_pred_2_jalr_target),
    .io_out_s1_full_pred_2_offsets_0               (io_out_s1_full_pred_2_offsets_0),
    .io_out_s1_full_pred_2_offsets_1               (io_out_s1_full_pred_2_offsets_1),
    .io_out_s1_full_pred_2_fallThroughAddr         (io_out_s1_full_pred_2_fallThroughAddr),
    .io_out_s1_full_pred_2_fallThroughErr          (io_out_s1_full_pred_2_fallThroughErr),
    .io_out_s1_full_pred_2_is_jal                  (io_out_s1_full_pred_2_is_jal),
    .io_out_s1_full_pred_2_is_jalr                 (io_out_s1_full_pred_2_is_jalr),
    .io_out_s1_full_pred_2_is_call                 (io_out_s1_full_pred_2_is_call),
    .io_out_s1_full_pred_2_is_ret                  (io_out_s1_full_pred_2_is_ret),
    .io_out_s1_full_pred_2_last_may_be_rvi_call    (io_out_s1_full_pred_2_last_may_be_rvi_call),
    .io_out_s1_full_pred_2_is_br_sharing           (io_out_s1_full_pred_2_is_br_sharing),
    .io_out_s1_full_pred_2_hit                     (io_out_s1_full_pred_2_hit),
    .io_out_s1_full_pred_3_br_taken_mask_0         (io_out_s1_full_pred_3_br_taken_mask_0),
    .io_out_s1_full_pred_3_br_taken_mask_1         (io_out_s1_full_pred_3_br_taken_mask_1),
    .io_out_s1_full_pred_3_slot_valids_0           (io_out_s1_full_pred_3_slot_valids_0),
    .io_out_s1_full_pred_3_slot_valids_1           (io_out_s1_full_pred_3_slot_valids_1),
    .io_out_s1_full_pred_3_targets_0               (io_out_s1_full_pred_3_targets_0),
    .io_out_s1_full_pred_3_targets_1               (io_out_s1_full_pred_3_targets_1),
    .io_out_s1_full_pred_3_jalr_target             (io_out_s1_full_pred_3_jalr_target),
    .io_out_s1_full_pred_3_offsets_0               (io_out_s1_full_pred_3_offsets_0),
    .io_out_s1_full_pred_3_offsets_1               (io_out_s1_full_pred_3_offsets_1),
    .io_out_s1_full_pred_3_fallThroughAddr         (io_out_s1_full_pred_3_fallThroughAddr),
    .io_out_s1_full_pred_3_fallThroughErr          (io_out_s1_full_pred_3_fallThroughErr),
    .io_out_s1_full_pred_3_is_jal                  (io_out_s1_full_pred_3_is_jal),
    .io_out_s1_full_pred_3_is_jalr                 (io_out_s1_full_pred_3_is_jalr),
    .io_out_s1_full_pred_3_is_call                 (io_out_s1_full_pred_3_is_call),
    .io_out_s1_full_pred_3_is_ret                  (io_out_s1_full_pred_3_is_ret),
    .io_out_s1_full_pred_3_last_may_be_rvi_call    (io_out_s1_full_pred_3_last_may_be_rvi_call),
    .io_out_s1_full_pred_3_is_br_sharing           (io_out_s1_full_pred_3_is_br_sharing),
    .io_out_s1_full_pred_3_hit                     (io_out_s1_full_pred_3_hit),
    // -- 末级 meta / FTB entry（写回 FTQ，update 时原样送回） --
    .io_out_last_stage_meta                        (uftb_io_out_last_stage_meta),
    // -- 其余 io --
    .io_fauftb_entry_out_isCall                    (uftb_io_fauftb_entry_out_isCall),
    .io_fauftb_entry_out_isRet                     (uftb_io_fauftb_entry_out_isRet),
    .io_fauftb_entry_out_isJalr                    (uftb_io_fauftb_entry_out_isJalr),
    .io_fauftb_entry_out_valid                     (uftb_io_fauftb_entry_out_valid),
    .io_fauftb_entry_out_brSlots_0_offset          (uftb_io_fauftb_entry_out_brSlots_0_offset),
    .io_fauftb_entry_out_brSlots_0_sharing         (uftb_io_fauftb_entry_out_brSlots_0_sharing),
    .io_fauftb_entry_out_brSlots_0_valid           (uftb_io_fauftb_entry_out_brSlots_0_valid),
    .io_fauftb_entry_out_brSlots_0_lower           (uftb_io_fauftb_entry_out_brSlots_0_lower),
    .io_fauftb_entry_out_brSlots_0_tarStat         (uftb_io_fauftb_entry_out_brSlots_0_tarStat),
    .io_fauftb_entry_out_tailSlot_offset           (uftb_io_fauftb_entry_out_tailSlot_offset),
    .io_fauftb_entry_out_tailSlot_sharing          (uftb_io_fauftb_entry_out_tailSlot_sharing),
    .io_fauftb_entry_out_tailSlot_valid            (uftb_io_fauftb_entry_out_tailSlot_valid),
    .io_fauftb_entry_out_tailSlot_lower            (uftb_io_fauftb_entry_out_tailSlot_lower),
    .io_fauftb_entry_out_tailSlot_tarStat          (uftb_io_fauftb_entry_out_tailSlot_tarStat),
    .io_fauftb_entry_out_pftAddr                   (uftb_io_fauftb_entry_out_pftAddr),
    .io_fauftb_entry_out_carry                     (uftb_io_fauftb_entry_out_carry),
    .io_fauftb_entry_out_last_may_be_rvi_call      (uftb_io_fauftb_entry_out_last_may_be_rvi_call),
    .io_fauftb_entry_out_strong_bias_0             (uftb_io_fauftb_entry_out_strong_bias_0),
    .io_fauftb_entry_out_strong_bias_1             (uftb_io_fauftb_entry_out_strong_bias_1),
    .io_fauftb_entry_hit_out                       (uftb_io_fauftb_entry_hit_out),
    // -- 各预测器使能开关（CSR 可关） --
    .io_ctrl_ubtb_enable                           (uftb_io_ctrl_delay_io_out_ubtb_enable),
    // -- S0~S3 流水握手（fire = valid & ready，4 份 dup） --
    .io_s0_fire_0                                  (io_s0_fire_0),
    .io_s0_fire_1                                  (io_s0_fire_1),
    .io_s0_fire_2                                  (io_s0_fire_2),
    .io_s0_fire_3                                  (io_s0_fire_3),
    .io_s1_fire_0                                  (io_s1_fire_0),
    .io_s1_fire_1                                  (io_s1_fire_1),
    .io_s1_fire_2                                  (io_s1_fire_2),
    .io_s1_fire_3                                  (io_s1_fire_3),
    .io_s2_fire_0                                  (io_s2_fire_0),
    .io_s2_fire_1                                  (io_s2_fire_1),
    .io_s2_fire_2                                  (io_s2_fire_2),
    .io_s2_fire_3                                  (io_s2_fire_3),
    // -- FTQ commit 回来的训练更新 --
    .io_update_valid                               (io_update_valid),
    .io_update_bits_pc                             (io_update_bits_pc),
    .io_update_bits_ftb_entry_isCall               (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet                (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr               (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_valid                (io_update_bits_ftb_entry_valid),
    .io_update_bits_ftb_entry_brSlots_0_offset     (io_update_bits_ftb_entry_brSlots_0_offset),
    .io_update_bits_ftb_entry_brSlots_0_sharing    (io_update_bits_ftb_entry_brSlots_0_sharing),
    .io_update_bits_ftb_entry_brSlots_0_valid      (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_brSlots_0_lower      (io_update_bits_ftb_entry_brSlots_0_lower),
    .io_update_bits_ftb_entry_brSlots_0_tarStat    (io_update_bits_ftb_entry_brSlots_0_tarStat),
    .io_update_bits_ftb_entry_tailSlot_offset      (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing     (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid       (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_tailSlot_lower       (io_update_bits_ftb_entry_tailSlot_lower),
    .io_update_bits_ftb_entry_tailSlot_tarStat     (io_update_bits_ftb_entry_tailSlot_tarStat),
    .io_update_bits_ftb_entry_pftAddr              (io_update_bits_ftb_entry_pftAddr),
    .io_update_bits_ftb_entry_carry                (io_update_bits_ftb_entry_carry),
    .io_update_bits_ftb_entry_last_may_be_rvi_call (io_update_bits_ftb_entry_last_may_be_rvi_call),
    .io_update_bits_ftb_entry_strong_bias_0        (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1        (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0                (io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1                (io_update_bits_br_taken_mask_1),
    .io_update_bits_meta                           ({403'h0, io_update_bits_meta[515:403]}),
    // -- 性能计数（对齐 2 拍后输出） --
    .io_perf_0_value                               (uftb_io_perf_0_value),
    .io_perf_1_value                               (uftb_io_perf_1_value)
  );

  // ---------------------------------------------------------------------------
  // Tage_SC tage —— 链 2/5 TAGE-SC：主方向预测器（几何历史标签表 + 统计校正），改写方向后传给 ftb
  // ---------------------------------------------------------------------------
  Tage_SC tage (
    // -- 时钟与复位 --
    .clock                                               (clock),
    .reset                                               (reset),
    // -- 复位向量（复位后第一个取指 PC） --
    .io_reset_vector                                     (io_reset_vector),
    // -- S0 预测请求：PC + 全局/折叠历史 --
    .io_in_bits_s0_pc_0                                  (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                                  (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                                  (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                                  (io_in_bits_s0_pc_3),
    .io_in_bits_folded_hist_1_hist_17_folded_hist        (io_in_bits_folded_hist_1_hist_17_folded_hist),
    .io_in_bits_folded_hist_1_hist_16_folded_hist        (io_in_bits_folded_hist_1_hist_16_folded_hist),
    .io_in_bits_folded_hist_1_hist_15_folded_hist        (io_in_bits_folded_hist_1_hist_15_folded_hist),
    .io_in_bits_folded_hist_1_hist_14_folded_hist        (io_in_bits_folded_hist_1_hist_14_folded_hist),
    .io_in_bits_folded_hist_1_hist_9_folded_hist         (io_in_bits_folded_hist_1_hist_9_folded_hist),
    .io_in_bits_folded_hist_1_hist_8_folded_hist         (io_in_bits_folded_hist_1_hist_8_folded_hist),
    .io_in_bits_folded_hist_1_hist_7_folded_hist         (io_in_bits_folded_hist_1_hist_7_folded_hist),
    .io_in_bits_folded_hist_1_hist_5_folded_hist         (io_in_bits_folded_hist_1_hist_5_folded_hist),
    .io_in_bits_folded_hist_1_hist_4_folded_hist         (io_in_bits_folded_hist_1_hist_4_folded_hist),
    .io_in_bits_folded_hist_1_hist_3_folded_hist         (io_in_bits_folded_hist_1_hist_3_folded_hist),
    .io_in_bits_folded_hist_1_hist_1_folded_hist         (io_in_bits_folded_hist_1_hist_1_folded_hist),
    .io_in_bits_folded_hist_3_hist_12_folded_hist        (io_in_bits_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_folded_hist_3_hist_11_folded_hist        (io_in_bits_folded_hist_3_hist_11_folded_hist),
    .io_in_bits_folded_hist_3_hist_2_folded_hist         (io_in_bits_folded_hist_3_hist_2_folded_hist),
    .io_in_bits_ghist                                    (io_in_bits_ghist),
    // -- S0 预测请求：其余字段 --
    .io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_0 (uftb_io_out_s1_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_1 (uftb_io_out_s1_full_pred_0_br_taken_mask_1),
    // -- S2 预测输出（FTB / TAGE 覆盖） --
    .io_out_s2_full_pred_0_br_taken_mask_0               (tage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1               (tage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_1_br_taken_mask_0               (tage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1               (tage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_2_br_taken_mask_0               (tage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1               (tage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_3_br_taken_mask_0               (tage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1               (tage_io_out_s2_full_pred_3_br_taken_mask_1),
    // -- S3 预测输出（SC / ITTAGE / RAS 覆盖） --
    .io_out_s3_full_pred_0_br_taken_mask_0               (tage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1               (tage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_1_br_taken_mask_0               (tage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1               (tage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_2_br_taken_mask_0               (tage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1               (tage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_3_br_taken_mask_0               (tage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1               (tage_io_out_s3_full_pred_3_br_taken_mask_1),
    // -- 末级 meta / FTB entry（写回 FTQ，update 时原样送回） --
    .io_out_last_stage_meta                              (tage_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0           (tage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1           (tage_io_out_last_stage_spec_info_sc_disagree_1),
    // -- 各预测器使能开关（CSR 可关） --
    .io_ctrl_tage_enable                                 (tage_io_ctrl_delay_io_out_tage_enable),
    .io_ctrl_sc_enable                                   (tage_io_ctrl_delay_io_out_sc_enable),
    // -- S0~S3 流水握手（fire = valid & ready，4 份 dup） --
    .io_s0_fire_0                                        (io_s0_fire_0),
    .io_s0_fire_1                                        (io_s0_fire_1),
    .io_s0_fire_2                                        (io_s0_fire_2),
    .io_s0_fire_3                                        (io_s0_fire_3),
    .io_s1_fire_0                                        (io_s1_fire_0),
    .io_s1_fire_1                                        (io_s1_fire_1),
    .io_s1_fire_2                                        (io_s1_fire_2),
    .io_s1_fire_3                                        (io_s1_fire_3),
    .io_s2_fire_0                                        (io_s2_fire_0),
    .io_s2_fire_1                                        (io_s2_fire_1),
    .io_s2_fire_2                                        (io_s2_fire_2),
    .io_s2_fire_3                                        (io_s2_fire_3),
    // -- S1 就绪（三大表相与） --
    .io_s1_ready                                         (tage_io_s1_ready),
    // -- FTQ commit 回来的训练更新 --
    .io_update_valid                                     (io_update_valid),
    .io_update_bits_pc                                   (io_update_bits_pc),
    .io_update_bits_ftb_entry_brSlots_0_valid            (io_update_bits_ftb_entry_brSlots_0_valid),
    .io_update_bits_ftb_entry_tailSlot_sharing           (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid             (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_strong_bias_0              (io_update_bits_ftb_entry_strong_bias_0),
    .io_update_bits_ftb_entry_strong_bias_1              (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_br_taken_mask_0                      (io_update_bits_br_taken_mask_0),
    .io_update_bits_br_taken_mask_1                      (io_update_bits_br_taken_mask_1),
    .io_update_bits_mispred_mask_0                       (io_update_bits_mispred_mask_0),
    .io_update_bits_mispred_mask_1                       (io_update_bits_mispred_mask_1),
    .io_update_bits_meta                                 ({259'h0, io_update_bits_meta[515:259]}),
    .io_update_bits_ghist                                (io_update_bits_ghist),
    // -- 性能计数（对齐 2 拍后输出） --
    .io_perf_0_value                                     (tage_io_perf_0_value),
    .io_perf_1_value                                     (tage_io_perf_1_value),
    .io_perf_2_value                                     (tage_io_perf_2_value),
    // -- MBIST 子链地址/数据（bore）—— G1 把 addr/addr_rd 由 9 位收窄到 8 位 --
    .boreChildrenBd_bore_array                           (boreChildrenBd_bore_1_array),
    .boreChildrenBd_bore_all                             (boreChildrenBd_bore_1_all),
    .boreChildrenBd_bore_req                             (boreChildrenBd_bore_1_req),
    .boreChildrenBd_bore_ack                             (boreChildrenBd_bore_1_ack),
    .boreChildrenBd_bore_writeen                         (boreChildrenBd_bore_1_writeen),
    .boreChildrenBd_bore_be                              (boreChildrenBd_bore_1_be),
    .boreChildrenBd_bore_addr                            (boreChildrenBd_bore_1_addr),
    .boreChildrenBd_bore_indata                          (boreChildrenBd_bore_1_indata),
    .boreChildrenBd_bore_readen                          (boreChildrenBd_bore_1_readen),
    .boreChildrenBd_bore_addr_rd                         (boreChildrenBd_bore_1_addr_rd),
    .boreChildrenBd_bore_outdata                         (boreChildrenBd_bore_1_outdata),
    .boreChildrenBd_bore_1_array                         (boreChildrenBd_bore_2_array),
    .boreChildrenBd_bore_1_all                           (boreChildrenBd_bore_2_all),
    .boreChildrenBd_bore_1_req                           (boreChildrenBd_bore_2_req),
    .boreChildrenBd_bore_1_ack                           (boreChildrenBd_bore_2_ack),
    .boreChildrenBd_bore_1_writeen                       (boreChildrenBd_bore_2_writeen),
    .boreChildrenBd_bore_1_be                            (boreChildrenBd_bore_2_be),
    .boreChildrenBd_bore_1_addr                          (boreChildrenBd_bore_2_addr),
    .boreChildrenBd_bore_1_indata                        (boreChildrenBd_bore_2_indata),
    .boreChildrenBd_bore_1_readen                        (boreChildrenBd_bore_2_readen),
    .boreChildrenBd_bore_1_addr_rd                       (boreChildrenBd_bore_2_addr_rd),
    .boreChildrenBd_bore_1_outdata                       (boreChildrenBd_bore_2_outdata),
    .boreChildrenBd_bore_2_array                         (boreChildrenBd_bore_3_array),
    .boreChildrenBd_bore_2_all                           (boreChildrenBd_bore_3_all),
    .boreChildrenBd_bore_2_req                           (boreChildrenBd_bore_3_req),
    .boreChildrenBd_bore_2_ack                           (boreChildrenBd_bore_3_ack),
    .boreChildrenBd_bore_2_writeen                       (boreChildrenBd_bore_3_writeen),
    .boreChildrenBd_bore_2_be                            (boreChildrenBd_bore_3_be),
    .boreChildrenBd_bore_2_addr                          (boreChildrenBd_bore_3_addr),
    .boreChildrenBd_bore_2_indata                        (boreChildrenBd_bore_3_indata),
    .boreChildrenBd_bore_2_readen                        (boreChildrenBd_bore_3_readen),
    .boreChildrenBd_bore_2_addr_rd                       (boreChildrenBd_bore_3_addr_rd),
    .boreChildrenBd_bore_2_outdata                       (boreChildrenBd_bore_3_outdata),
    .boreChildrenBd_bore_3_array                         (boreChildrenBd_bore_4_array),
    .boreChildrenBd_bore_3_all                           (boreChildrenBd_bore_4_all),
    .boreChildrenBd_bore_3_req                           (boreChildrenBd_bore_4_req),
    .boreChildrenBd_bore_3_ack                           (boreChildrenBd_bore_4_ack),
    .boreChildrenBd_bore_3_writeen                       (boreChildrenBd_bore_4_writeen),
    .boreChildrenBd_bore_3_be                            (boreChildrenBd_bore_4_be),
    .boreChildrenBd_bore_3_addr                          (boreChildrenBd_bore_4_addr),
    .boreChildrenBd_bore_3_indata                        (boreChildrenBd_bore_4_indata),
    .boreChildrenBd_bore_3_readen                        (boreChildrenBd_bore_4_readen),
    .boreChildrenBd_bore_3_addr_rd                       (boreChildrenBd_bore_4_addr_rd),
    .boreChildrenBd_bore_3_outdata                       (boreChildrenBd_bore_4_outdata),
    .boreChildrenBd_bore_4_array                         (boreChildrenBd_bore_5_array),
    .boreChildrenBd_bore_4_all                           (boreChildrenBd_bore_5_all),
    .boreChildrenBd_bore_4_req                           (boreChildrenBd_bore_5_req),
    .boreChildrenBd_bore_4_ack                           (boreChildrenBd_bore_5_ack),
    .boreChildrenBd_bore_4_writeen                       (boreChildrenBd_bore_5_writeen),
    .boreChildrenBd_bore_4_be                            (boreChildrenBd_bore_5_be),
    .boreChildrenBd_bore_4_addr                          (boreChildrenBd_bore_5_addr),
    .boreChildrenBd_bore_4_indata                        (boreChildrenBd_bore_5_indata),
    .boreChildrenBd_bore_4_readen                        (boreChildrenBd_bore_5_readen),
    .boreChildrenBd_bore_4_addr_rd                       (boreChildrenBd_bore_5_addr_rd),
    .boreChildrenBd_bore_4_outdata                       (boreChildrenBd_bore_5_outdata),
    // -- MBIST SRAM 侧带外控制（每 bore 7 根：hold/bypass/bp_clken/aux_clk/aux_ckbp/mcp_hold/cgen） --
    .sigFromSrams_bore_ram_hold                          (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_ram_bypass                        (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken                      (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                       (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp                      (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold                      (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_cgen                              (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_1_ram_hold                        (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_1_ram_bypass                      (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken                    (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk                     (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp                    (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold                    (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                            (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_2_ram_hold                        (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_2_ram_bypass                      (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken                    (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk                     (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp                    (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold                    (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                            (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_3_ram_hold                        (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_3_ram_bypass                      (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken                    (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk                     (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp                    (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold                    (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                            (sigFromSrams_bore_11_cgen),
    .sigFromSrams_bore_4_ram_hold                        (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_4_ram_bypass                      (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken                    (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk                     (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp                    (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold                    (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                            (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_5_ram_hold                        (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_5_ram_bypass                      (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken                    (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk                     (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp                    (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold                    (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                            (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_6_ram_hold                        (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_6_ram_bypass                      (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken                    (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk                     (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp                    (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold                    (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                            (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_7_ram_hold                        (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_7_ram_bypass                      (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken                    (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk                     (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp                    (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold                    (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                            (sigFromSrams_bore_15_cgen),
    .sigFromSrams_bore_8_ram_hold                        (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_8_ram_bypass                      (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_8_ram_bp_clken                    (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_8_ram_aux_clk                     (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_8_ram_aux_ckbp                    (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_8_ram_mcp_hold                    (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_8_cgen                            (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_9_ram_hold                        (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_9_ram_bypass                      (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_9_ram_bp_clken                    (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_9_ram_aux_clk                     (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_9_ram_aux_ckbp                    (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_9_ram_mcp_hold                    (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_9_cgen                            (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_10_ram_hold                       (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_10_ram_bypass                     (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_10_ram_bp_clken                   (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_10_ram_aux_clk                    (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_10_ram_aux_ckbp                   (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_10_ram_mcp_hold                   (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_10_cgen                           (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_11_ram_hold                       (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_11_ram_bypass                     (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_11_ram_bp_clken                   (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_11_ram_aux_clk                    (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_11_ram_aux_ckbp                   (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_11_ram_mcp_hold                   (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_11_cgen                           (sigFromSrams_bore_19_cgen),
    .sigFromSrams_bore_12_ram_hold                       (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_12_ram_bypass                     (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_12_ram_bp_clken                   (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_12_ram_aux_clk                    (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_12_ram_aux_ckbp                   (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_12_ram_mcp_hold                   (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_12_cgen                           (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_13_ram_hold                       (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_13_ram_bypass                     (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_13_ram_bp_clken                   (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_13_ram_aux_clk                    (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_13_ram_aux_ckbp                   (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_13_ram_mcp_hold                   (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_13_cgen                           (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_14_ram_hold                       (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_14_ram_bypass                     (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_14_ram_bp_clken                   (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_14_ram_aux_clk                    (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_14_ram_aux_ckbp                   (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_14_ram_mcp_hold                   (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_14_cgen                           (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_15_ram_hold                       (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_15_ram_bypass                     (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_15_ram_bp_clken                   (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_15_ram_aux_clk                    (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_15_ram_aux_ckbp                   (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_15_ram_mcp_hold                   (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_15_cgen                           (sigFromSrams_bore_23_cgen),
    .sigFromSrams_bore_16_ram_hold                       (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_16_ram_bypass                     (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_16_ram_bp_clken                   (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_16_ram_aux_clk                    (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_16_ram_aux_ckbp                   (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_16_ram_mcp_hold                   (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_16_cgen                           (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_17_ram_hold                       (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_17_ram_bypass                     (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_17_ram_bp_clken                   (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_17_ram_aux_clk                    (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_17_ram_aux_ckbp                   (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_17_ram_mcp_hold                   (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_17_cgen                           (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_18_ram_hold                       (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_18_ram_bypass                     (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_18_ram_bp_clken                   (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_18_ram_aux_clk                    (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_18_ram_aux_ckbp                   (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_18_ram_mcp_hold                   (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_18_cgen                           (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_19_ram_hold                       (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_19_ram_bypass                     (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_19_ram_bp_clken                   (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_19_ram_aux_clk                    (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_19_ram_aux_ckbp                   (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_19_ram_mcp_hold                   (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_19_cgen                           (sigFromSrams_bore_27_cgen),
    .sigFromSrams_bore_20_ram_hold                       (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_20_ram_bypass                     (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_20_ram_bp_clken                   (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_20_ram_aux_clk                    (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_20_ram_aux_ckbp                   (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_20_ram_mcp_hold                   (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_20_cgen                           (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_21_ram_hold                       (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_21_ram_bypass                     (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_21_ram_bp_clken                   (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_21_ram_aux_clk                    (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_21_ram_aux_ckbp                   (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_21_ram_mcp_hold                   (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_21_cgen                           (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_22_ram_hold                       (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_22_ram_bypass                     (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_22_ram_bp_clken                   (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_22_ram_aux_clk                    (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_22_ram_aux_ckbp                   (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_22_ram_mcp_hold                   (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_22_cgen                           (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_23_ram_hold                       (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_23_ram_bypass                     (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_23_ram_bp_clken                   (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_23_ram_aux_clk                    (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_23_ram_aux_ckbp                   (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_23_ram_mcp_hold                   (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_23_cgen                           (sigFromSrams_bore_31_cgen),
    .sigFromSrams_bore_24_ram_hold                       (sigFromSrams_bore_32_ram_hold),
    .sigFromSrams_bore_24_ram_bypass                     (sigFromSrams_bore_32_ram_bypass),
    .sigFromSrams_bore_24_ram_bp_clken                   (sigFromSrams_bore_32_ram_bp_clken),
    .sigFromSrams_bore_24_ram_aux_clk                    (sigFromSrams_bore_32_ram_aux_clk),
    .sigFromSrams_bore_24_ram_aux_ckbp                   (sigFromSrams_bore_32_ram_aux_ckbp),
    .sigFromSrams_bore_24_ram_mcp_hold                   (sigFromSrams_bore_32_ram_mcp_hold),
    .sigFromSrams_bore_24_cgen                           (sigFromSrams_bore_32_cgen),
    .sigFromSrams_bore_25_ram_hold                       (sigFromSrams_bore_33_ram_hold),
    .sigFromSrams_bore_25_ram_bypass                     (sigFromSrams_bore_33_ram_bypass),
    .sigFromSrams_bore_25_ram_bp_clken                   (sigFromSrams_bore_33_ram_bp_clken),
    .sigFromSrams_bore_25_ram_aux_clk                    (sigFromSrams_bore_33_ram_aux_clk),
    .sigFromSrams_bore_25_ram_aux_ckbp                   (sigFromSrams_bore_33_ram_aux_ckbp),
    .sigFromSrams_bore_25_ram_mcp_hold                   (sigFromSrams_bore_33_ram_mcp_hold),
    .sigFromSrams_bore_25_cgen                           (sigFromSrams_bore_33_cgen),
    .sigFromSrams_bore_26_ram_hold                       (sigFromSrams_bore_34_ram_hold),
    .sigFromSrams_bore_26_ram_bypass                     (sigFromSrams_bore_34_ram_bypass),
    .sigFromSrams_bore_26_ram_bp_clken                   (sigFromSrams_bore_34_ram_bp_clken),
    .sigFromSrams_bore_26_ram_aux_clk                    (sigFromSrams_bore_34_ram_aux_clk),
    .sigFromSrams_bore_26_ram_aux_ckbp                   (sigFromSrams_bore_34_ram_aux_ckbp),
    .sigFromSrams_bore_26_ram_mcp_hold                   (sigFromSrams_bore_34_ram_mcp_hold),
    .sigFromSrams_bore_26_cgen                           (sigFromSrams_bore_34_cgen),
    .sigFromSrams_bore_27_ram_hold                       (sigFromSrams_bore_35_ram_hold),
    .sigFromSrams_bore_27_ram_bypass                     (sigFromSrams_bore_35_ram_bypass),
    .sigFromSrams_bore_27_ram_bp_clken                   (sigFromSrams_bore_35_ram_bp_clken),
    .sigFromSrams_bore_27_ram_aux_clk                    (sigFromSrams_bore_35_ram_aux_clk),
    .sigFromSrams_bore_27_ram_aux_ckbp                   (sigFromSrams_bore_35_ram_aux_ckbp),
    .sigFromSrams_bore_27_ram_mcp_hold                   (sigFromSrams_bore_35_ram_mcp_hold),
    .sigFromSrams_bore_27_cgen                           (sigFromSrams_bore_35_cgen),
    .sigFromSrams_bore_28_ram_hold                       (sigFromSrams_bore_36_ram_hold),
    .sigFromSrams_bore_28_ram_bypass                     (sigFromSrams_bore_36_ram_bypass),
    .sigFromSrams_bore_28_ram_bp_clken                   (sigFromSrams_bore_36_ram_bp_clken),
    .sigFromSrams_bore_28_ram_aux_clk                    (sigFromSrams_bore_36_ram_aux_clk),
    .sigFromSrams_bore_28_ram_aux_ckbp                   (sigFromSrams_bore_36_ram_aux_ckbp),
    .sigFromSrams_bore_28_ram_mcp_hold                   (sigFromSrams_bore_36_ram_mcp_hold),
    .sigFromSrams_bore_28_cgen                           (sigFromSrams_bore_36_cgen),
    .sigFromSrams_bore_29_ram_hold                       (sigFromSrams_bore_37_ram_hold),
    .sigFromSrams_bore_29_ram_bypass                     (sigFromSrams_bore_37_ram_bypass),
    .sigFromSrams_bore_29_ram_bp_clken                   (sigFromSrams_bore_37_ram_bp_clken),
    .sigFromSrams_bore_29_ram_aux_clk                    (sigFromSrams_bore_37_ram_aux_clk),
    .sigFromSrams_bore_29_ram_aux_ckbp                   (sigFromSrams_bore_37_ram_aux_ckbp),
    .sigFromSrams_bore_29_ram_mcp_hold                   (sigFromSrams_bore_37_ram_mcp_hold),
    .sigFromSrams_bore_29_cgen                           (sigFromSrams_bore_37_cgen),
    .sigFromSrams_bore_30_ram_hold                       (sigFromSrams_bore_38_ram_hold),
    .sigFromSrams_bore_30_ram_bypass                     (sigFromSrams_bore_38_ram_bypass),
    .sigFromSrams_bore_30_ram_bp_clken                   (sigFromSrams_bore_38_ram_bp_clken),
    .sigFromSrams_bore_30_ram_aux_clk                    (sigFromSrams_bore_38_ram_aux_clk),
    .sigFromSrams_bore_30_ram_aux_ckbp                   (sigFromSrams_bore_38_ram_aux_ckbp),
    .sigFromSrams_bore_30_ram_mcp_hold                   (sigFromSrams_bore_38_ram_mcp_hold),
    .sigFromSrams_bore_30_cgen                           (sigFromSrams_bore_38_cgen),
    .sigFromSrams_bore_31_ram_hold                       (sigFromSrams_bore_39_ram_hold),
    .sigFromSrams_bore_31_ram_bypass                     (sigFromSrams_bore_39_ram_bypass),
    .sigFromSrams_bore_31_ram_bp_clken                   (sigFromSrams_bore_39_ram_bp_clken),
    .sigFromSrams_bore_31_ram_aux_clk                    (sigFromSrams_bore_39_ram_aux_clk),
    .sigFromSrams_bore_31_ram_aux_ckbp                   (sigFromSrams_bore_39_ram_aux_ckbp),
    .sigFromSrams_bore_31_ram_mcp_hold                   (sigFromSrams_bore_39_ram_mcp_hold),
    .sigFromSrams_bore_31_cgen                           (sigFromSrams_bore_39_cgen)
  );

  // ---------------------------------------------------------------------------
  // RAS ras —— 链尾 RAS：返回地址栈，补 ret 目标；186 个顶层输出由它直驱（S2 76 + S3 80 + last_stage 30）
  // ---------------------------------------------------------------------------
  RAS ras (
    // -- 时钟与复位 --
    .clock                                                          (clock),
    .reset                                                          (reset),
    // -- 复位向量（复位后第一个取指 PC） --
    .io_reset_vector                                                (io_reset_vector),
    // -- S0 预测请求：PC + 全局/折叠历史 --
    .io_in_bits_s0_pc_0                                             (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                                             (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                                             (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                                             (io_in_bits_s0_pc_3),
    // -- S0 预测请求：其余字段 --
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0            (ittage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1            (ittage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0              (ittage_io_out_s2_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1              (ittage_io_out_s2_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_0                  (ittage_io_out_s2_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_1                  (ittage_io_out_s2_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target                (ittage_io_out_s2_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0                  (ittage_io_out_s2_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1                  (ittage_io_out_s2_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr            (ittage_io_out_s2_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr             (ittage_io_out_s2_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jal                     (ittage_io_out_s2_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr                    (ittage_io_out_s2_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_call                    (ittage_io_out_s2_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_ret                     (ittage_io_out_s2_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call       (ittage_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing              (ittage_io_out_s2_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_0_hit                        (ittage_io_out_s2_full_pred_0_hit),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0            (ittage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1            (ittage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0              (ittage_io_out_s2_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1              (ittage_io_out_s2_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_0                  (ittage_io_out_s2_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_1                  (ittage_io_out_s2_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target                (ittage_io_out_s2_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0                  (ittage_io_out_s2_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1                  (ittage_io_out_s2_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr            (ittage_io_out_s2_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr             (ittage_io_out_s2_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jal                     (ittage_io_out_s2_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr                    (ittage_io_out_s2_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_call                    (ittage_io_out_s2_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_ret                     (ittage_io_out_s2_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call       (ittage_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing              (ittage_io_out_s2_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_1_hit                        (ittage_io_out_s2_full_pred_1_hit),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0            (ittage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1            (ittage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0              (ittage_io_out_s2_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1              (ittage_io_out_s2_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_0                  (ittage_io_out_s2_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_1                  (ittage_io_out_s2_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target                (ittage_io_out_s2_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0                  (ittage_io_out_s2_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1                  (ittage_io_out_s2_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr            (ittage_io_out_s2_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr             (ittage_io_out_s2_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jal                     (ittage_io_out_s2_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr                    (ittage_io_out_s2_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_call                    (ittage_io_out_s2_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_ret                     (ittage_io_out_s2_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call       (ittage_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing              (ittage_io_out_s2_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_2_hit                        (ittage_io_out_s2_full_pred_2_hit),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0            (ittage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1            (ittage_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0              (ittage_io_out_s2_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1              (ittage_io_out_s2_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_0                  (ittage_io_out_s2_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_1                  (ittage_io_out_s2_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target                (ittage_io_out_s2_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0                  (ittage_io_out_s2_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1                  (ittage_io_out_s2_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr            (ittage_io_out_s2_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr             (ittage_io_out_s2_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jal                     (ittage_io_out_s2_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr                    (ittage_io_out_s2_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_call                    (ittage_io_out_s2_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_ret                     (ittage_io_out_s2_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call       (ittage_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing              (ittage_io_out_s2_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_3_hit                        (ittage_io_out_s2_full_pred_3_hit),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0            (ittage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1            (ittage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0              (ittage_io_out_s3_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1              (ittage_io_out_s3_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_0                  (ittage_io_out_s3_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_1                  (ittage_io_out_s3_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_jalr_target                (ittage_io_out_s3_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0                  (ittage_io_out_s3_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1                  (ittage_io_out_s3_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr            (ittage_io_out_s3_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr             (ittage_io_out_s3_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_0_multiHit                   (ittage_io_out_s3_full_pred_0_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jal                     (ittage_io_out_s3_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr                    (ittage_io_out_s3_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_call                    (ittage_io_out_s3_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_ret                     (ittage_io_out_s3_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call       (ittage_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing              (ittage_io_out_s3_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_0_hit                        (ittage_io_out_s3_full_pred_0_hit),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0            (ittage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1            (ittage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0              (ittage_io_out_s3_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1              (ittage_io_out_s3_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_0                  (ittage_io_out_s3_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_1                  (ittage_io_out_s3_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_jalr_target                (ittage_io_out_s3_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0                  (ittage_io_out_s3_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1                  (ittage_io_out_s3_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr            (ittage_io_out_s3_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr             (ittage_io_out_s3_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_1_multiHit                   (ittage_io_out_s3_full_pred_1_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jal                     (ittage_io_out_s3_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr                    (ittage_io_out_s3_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_call                    (ittage_io_out_s3_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_ret                     (ittage_io_out_s3_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call       (ittage_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing              (ittage_io_out_s3_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_1_hit                        (ittage_io_out_s3_full_pred_1_hit),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0            (ittage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1            (ittage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0              (ittage_io_out_s3_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1              (ittage_io_out_s3_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_0                  (ittage_io_out_s3_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_1                  (ittage_io_out_s3_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_jalr_target                (ittage_io_out_s3_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0                  (ittage_io_out_s3_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1                  (ittage_io_out_s3_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr            (ittage_io_out_s3_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr             (ittage_io_out_s3_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_2_multiHit                   (ittage_io_out_s3_full_pred_2_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jal                     (ittage_io_out_s3_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr                    (ittage_io_out_s3_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_call                    (ittage_io_out_s3_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_ret                     (ittage_io_out_s3_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call       (ittage_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing              (ittage_io_out_s3_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_2_hit                        (ittage_io_out_s3_full_pred_2_hit),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0            (ittage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1            (ittage_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0              (ittage_io_out_s3_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1              (ittage_io_out_s3_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_0                  (ittage_io_out_s3_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_1                  (ittage_io_out_s3_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_jalr_target                (ittage_io_out_s3_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0                  (ittage_io_out_s3_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1                  (ittage_io_out_s3_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr            (ittage_io_out_s3_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr             (ittage_io_out_s3_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_3_multiHit                   (ittage_io_out_s3_full_pred_3_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jal                     (ittage_io_out_s3_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr                    (ittage_io_out_s3_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_call                    (ittage_io_out_s3_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_ret                     (ittage_io_out_s3_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call       (ittage_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing              (ittage_io_out_s3_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_3_hit                        (ittage_io_out_s3_full_pred_3_hit),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0        (ittage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1        (ittage_io_out_last_stage_spec_info_sc_disagree_1),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall               (ittage_io_out_last_stage_ftb_entry_isCall),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet                (ittage_io_out_last_stage_ftb_entry_isRet),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr               (ittage_io_out_last_stage_ftb_entry_isJalr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_valid                (ittage_io_out_last_stage_ftb_entry_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset     (ittage_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing    (ittage_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid      (ittage_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower      (ittage_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat    (ittage_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset      (ittage_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing     (ittage_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid       (ittage_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower       (ittage_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat     (ittage_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr              (ittage_io_out_last_stage_ftb_entry_pftAddr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_carry                (ittage_io_out_last_stage_ftb_entry_carry),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call (ittage_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0        (ittage_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1        (ittage_io_out_last_stage_ftb_entry_strong_bias_1),
    // -- S2 预测输出（FTB / TAGE 覆盖） --
    .io_out_s2_pc_0                                                 (io_out_s2_pc_0),
    .io_out_s2_pc_1                                                 (io_out_s2_pc_1),
    .io_out_s2_pc_2                                                 (io_out_s2_pc_2),
    .io_out_s2_pc_3                                                 (io_out_s2_pc_3),
    .io_out_s2_full_pred_0_br_taken_mask_0                          (io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1                          (io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0                            (io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1                            (io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0                                (io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1                                (io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target                              (io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0                                (io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1                                (io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr                          (io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr                           (io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal                                   (io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr                                  (io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call                                  (io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret                                   (io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call                     (io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing                            (io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit                                      (io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0                          (io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1                          (io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0                            (io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1                            (io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0                                (io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1                                (io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target                              (io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0                                (io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1                                (io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr                          (io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr                           (io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal                                   (io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr                                  (io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call                                  (io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret                                   (io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call                     (io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing                            (io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit                                      (io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0                          (io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1                          (io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0                            (io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1                            (io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0                                (io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1                                (io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target                              (io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0                                (io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1                                (io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr                          (io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr                           (io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal                                   (io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr                                  (io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call                                  (io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret                                   (io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call                     (io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing                            (io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit                                      (io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0                          (io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1                          (io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0                            (io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1                            (io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0                                (io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1                                (io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target                              (io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0                                (io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1                                (io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr                          (io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr                           (io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal                                   (io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr                                  (io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call                                  (io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret                                   (io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call                     (io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing                            (io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit                                      (io_out_s2_full_pred_3_hit),
    // -- S3 预测输出（SC / ITTAGE / RAS 覆盖） --
    .io_out_s3_pc_0                                                 (io_out_s3_pc_0),
    .io_out_s3_pc_1                                                 (io_out_s3_pc_1),
    .io_out_s3_pc_2                                                 (io_out_s3_pc_2),
    .io_out_s3_pc_3                                                 (io_out_s3_pc_3),
    .io_out_s3_full_pred_0_br_taken_mask_0                          (io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1                          (io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0                            (io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1                            (io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0                                (io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1                                (io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target                              (io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0                                (io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1                                (io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr                          (io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr                           (io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit                                 (io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal                                   (io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr                                  (io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call                                  (io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret                                   (io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call                     (io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing                            (io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit                                      (io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0                          (io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1                          (io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0                            (io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1                            (io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0                                (io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1                                (io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target                              (io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0                                (io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1                                (io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr                          (io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr                           (io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit                                 (io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal                                   (io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr                                  (io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call                                  (io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret                                   (io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call                     (io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing                            (io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit                                      (io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0                          (io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1                          (io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0                            (io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1                            (io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0                                (io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1                                (io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target                              (io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0                                (io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1                                (io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr                          (io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr                           (io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit                                 (io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal                                   (io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr                                  (io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call                                  (io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret                                   (io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call                     (io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing                            (io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit                                      (io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0                          (io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1                          (io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0                            (io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1                            (io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0                                (io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1                                (io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target                              (io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0                                (io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1                                (io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr                          (io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr                           (io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit                                 (io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal                                   (io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr                                  (io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call                                  (io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret                                   (io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call                     (io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing                            (io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit                                      (io_out_s3_full_pred_3_hit),
    // -- 末级 meta / FTB entry（写回 FTQ，update 时原样送回） --
    .io_out_last_stage_meta                                         (ras_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_ssp                                (io_out_last_stage_spec_info_ssp),
    .io_out_last_stage_spec_info_sctr                               (io_out_last_stage_spec_info_sctr),
    .io_out_last_stage_spec_info_TOSW_flag                          (io_out_last_stage_spec_info_TOSW_flag),
    .io_out_last_stage_spec_info_TOSW_value                         (io_out_last_stage_spec_info_TOSW_value),
    .io_out_last_stage_spec_info_TOSR_flag                          (io_out_last_stage_spec_info_TOSR_flag),
    .io_out_last_stage_spec_info_TOSR_value                         (io_out_last_stage_spec_info_TOSR_value),
    .io_out_last_stage_spec_info_NOS_flag                           (io_out_last_stage_spec_info_NOS_flag),
    .io_out_last_stage_spec_info_NOS_value                          (io_out_last_stage_spec_info_NOS_value),
    .io_out_last_stage_spec_info_topAddr                            (io_out_last_stage_spec_info_topAddr),
    .io_out_last_stage_spec_info_sc_disagree_0                      (io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1                      (io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall                             (io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet                              (io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr                             (io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid                              (io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset                   (io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing                  (io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid                    (io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower                    (io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat                  (io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset                    (io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing                   (io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid                     (io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower                     (io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat                   (io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr                            (io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry                              (io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call               (io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0                      (io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1                      (io_out_last_stage_ftb_entry_strong_bias_1),
    // -- 各预测器使能开关（CSR 可关） --
    .io_ctrl_ras_enable                                             (ras_io_ctrl_delay_io_out_ras_enable),
    // -- S0~S3 流水握手（fire = valid & ready，4 份 dup） --
    .io_s0_fire_0                                                   (io_s0_fire_0),
    .io_s0_fire_1                                                   (io_s0_fire_1),
    .io_s0_fire_2                                                   (io_s0_fire_2),
    .io_s0_fire_3                                                   (io_s0_fire_3),
    .io_s1_fire_0                                                   (io_s1_fire_0),
    .io_s1_fire_1                                                   (io_s1_fire_1),
    .io_s1_fire_2                                                   (io_s1_fire_2),
    .io_s1_fire_3                                                   (io_s1_fire_3),
    .io_s2_fire_0                                                   (io_s2_fire_0),
    .io_s2_fire_1                                                   (io_s2_fire_1),
    .io_s2_fire_2                                                   (io_s2_fire_2),
    .io_s2_fire_3                                                   (io_s2_fire_3),
    .io_s3_fire_2                                                   (io_s3_fire_2),
    // -- 其余 io --
    .io_s3_redirect_2                                               (io_s3_redirect_2),
    // -- FTQ commit 回来的训练更新 --
    .io_update_valid                                                (io_update_valid),
    .io_update_bits_ftb_entry_isCall                                (io_update_bits_ftb_entry_isCall),
    .io_update_bits_ftb_entry_isRet                                 (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_tailSlot_offset                       (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_valid                        (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_cfi_idx_valid                                   (io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits                                    (io_update_bits_cfi_idx_bits),
    .io_update_bits_jmp_taken                                       (io_update_bits_jmp_taken),
    .io_update_bits_meta                                            (io_update_bits_meta),
    // -- 重定向（错预测纠正 / 恢复历史） --
    .io_redirect_valid                                              (io_redirect_valid),
    .io_redirect_bits_level                                         (io_redirect_bits_level),
    .io_redirect_bits_cfiUpdate_pc                                  (io_redirect_bits_cfiUpdate_pc),
    .io_redirect_bits_cfiUpdate_pd_valid                            (io_redirect_bits_cfiUpdate_pd_valid),
    .io_redirect_bits_cfiUpdate_pd_isRVC                            (io_redirect_bits_cfiUpdate_pd_isRVC),
    .io_redirect_bits_cfiUpdate_pd_isCall                           (io_redirect_bits_cfiUpdate_pd_isCall),
    .io_redirect_bits_cfiUpdate_pd_isRet                            (io_redirect_bits_cfiUpdate_pd_isRet),
    .io_redirect_bits_cfiUpdate_ssp                                 (io_redirect_bits_cfiUpdate_ssp),
    .io_redirect_bits_cfiUpdate_sctr                                (io_redirect_bits_cfiUpdate_sctr),
    .io_redirect_bits_cfiUpdate_TOSW_flag                           (io_redirect_bits_cfiUpdate_TOSW_flag),
    .io_redirect_bits_cfiUpdate_TOSW_value                          (io_redirect_bits_cfiUpdate_TOSW_value),
    .io_redirect_bits_cfiUpdate_TOSR_flag                           (io_redirect_bits_cfiUpdate_TOSR_flag),
    .io_redirect_bits_cfiUpdate_TOSR_value                          (io_redirect_bits_cfiUpdate_TOSR_value),
    .io_redirect_bits_cfiUpdate_NOS_flag                            (io_redirect_bits_cfiUpdate_NOS_flag),
    .io_redirect_bits_cfiUpdate_NOS_value                           (io_redirect_bits_cfiUpdate_NOS_value)
  );

  // ---------------------------------------------------------------------------
  // ITTage ittage —— 链 4/5 ITTAGE：间接跳转目标预测，改写 jalr_target
  // ---------------------------------------------------------------------------
  ITTage ittage (
    // -- 时钟与复位 --
    .clock                                                          (clock),
    .reset                                                          (reset),
    // -- 复位向量（复位后第一个取指 PC） --
    .io_reset_vector                                                (io_reset_vector),
    // -- S0 预测请求：PC + 全局/折叠历史 --
    .io_in_bits_s0_pc_0                                             (io_in_bits_s0_pc_0),
    .io_in_bits_s0_pc_1                                             (io_in_bits_s0_pc_1),
    .io_in_bits_s0_pc_2                                             (io_in_bits_s0_pc_2),
    .io_in_bits_s0_pc_3                                             (io_in_bits_s0_pc_3),
    .io_in_bits_s1_folded_hist_3_hist_14_folded_hist                (io_in_bits_s1_folded_hist_3_hist_14_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_13_folded_hist                (io_in_bits_s1_folded_hist_3_hist_13_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_12_folded_hist                (io_in_bits_s1_folded_hist_3_hist_12_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_10_folded_hist                (io_in_bits_s1_folded_hist_3_hist_10_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_6_folded_hist                 (io_in_bits_s1_folded_hist_3_hist_6_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_4_folded_hist                 (io_in_bits_s1_folded_hist_3_hist_4_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_3_folded_hist                 (io_in_bits_s1_folded_hist_3_hist_3_folded_hist),
    .io_in_bits_s1_folded_hist_3_hist_2_folded_hist                 (io_in_bits_s1_folded_hist_3_hist_2_folded_hist),
    // -- S0 预测请求：其余字段 --
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_0            (ftb_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_br_taken_mask_1            (ftb_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_0              (ftb_io_out_s2_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_slot_valids_1              (ftb_io_out_s2_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_0                  (ftb_io_out_s2_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_targets_1                  (ftb_io_out_s2_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_jalr_target                (ftb_io_out_s2_full_pred_0_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_0                  (ftb_io_out_s2_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_0_offsets_1                  (ftb_io_out_s2_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughAddr            (ftb_io_out_s2_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_0_fallThroughErr             (ftb_io_out_s2_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jal                     (ftb_io_out_s2_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_jalr                    (ftb_io_out_s2_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_call                    (ftb_io_out_s2_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_ret                     (ftb_io_out_s2_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_0_last_may_be_rvi_call       (ftb_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_0_is_br_sharing              (ftb_io_out_s2_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_0_hit                        (ftb_io_out_s2_full_pred_0_hit),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_0            (ftb_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_br_taken_mask_1            (ftb_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_0              (ftb_io_out_s2_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_slot_valids_1              (ftb_io_out_s2_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_0                  (ftb_io_out_s2_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_targets_1                  (ftb_io_out_s2_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_jalr_target                (ftb_io_out_s2_full_pred_1_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_0                  (ftb_io_out_s2_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_1_offsets_1                  (ftb_io_out_s2_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughAddr            (ftb_io_out_s2_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_1_fallThroughErr             (ftb_io_out_s2_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jal                     (ftb_io_out_s2_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_jalr                    (ftb_io_out_s2_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_call                    (ftb_io_out_s2_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_ret                     (ftb_io_out_s2_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_1_last_may_be_rvi_call       (ftb_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_1_is_br_sharing              (ftb_io_out_s2_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_1_hit                        (ftb_io_out_s2_full_pred_1_hit),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_0            (ftb_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_br_taken_mask_1            (ftb_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_0              (ftb_io_out_s2_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_slot_valids_1              (ftb_io_out_s2_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_0                  (ftb_io_out_s2_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_targets_1                  (ftb_io_out_s2_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_jalr_target                (ftb_io_out_s2_full_pred_2_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_0                  (ftb_io_out_s2_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_2_offsets_1                  (ftb_io_out_s2_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughAddr            (ftb_io_out_s2_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_2_fallThroughErr             (ftb_io_out_s2_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jal                     (ftb_io_out_s2_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_jalr                    (ftb_io_out_s2_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_call                    (ftb_io_out_s2_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_ret                     (ftb_io_out_s2_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_2_last_may_be_rvi_call       (ftb_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_2_is_br_sharing              (ftb_io_out_s2_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_2_hit                        (ftb_io_out_s2_full_pred_2_hit),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_0            (ftb_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_br_taken_mask_1            (ftb_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_0              (ftb_io_out_s2_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_slot_valids_1              (ftb_io_out_s2_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_0                  (ftb_io_out_s2_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_targets_1                  (ftb_io_out_s2_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_jalr_target                (ftb_io_out_s2_full_pred_3_jalr_target),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_0                  (ftb_io_out_s2_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s2_full_pred_3_offsets_1                  (ftb_io_out_s2_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughAddr            (ftb_io_out_s2_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s2_full_pred_3_fallThroughErr             (ftb_io_out_s2_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jal                     (ftb_io_out_s2_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_jalr                    (ftb_io_out_s2_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_call                    (ftb_io_out_s2_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_ret                     (ftb_io_out_s2_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s2_full_pred_3_last_may_be_rvi_call       (ftb_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s2_full_pred_3_is_br_sharing              (ftb_io_out_s2_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s2_full_pred_3_hit                        (ftb_io_out_s2_full_pred_3_hit),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_0            (ftb_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_br_taken_mask_1            (ftb_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_0              (ftb_io_out_s3_full_pred_0_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_slot_valids_1              (ftb_io_out_s3_full_pred_0_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_0                  (ftb_io_out_s3_full_pred_0_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_targets_1                  (ftb_io_out_s3_full_pred_0_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_0                  (ftb_io_out_s3_full_pred_0_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_0_offsets_1                  (ftb_io_out_s3_full_pred_0_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughAddr            (ftb_io_out_s3_full_pred_0_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_0_fallThroughErr             (ftb_io_out_s3_full_pred_0_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_0_multiHit                   (ftb_io_out_s3_full_pred_0_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jal                     (ftb_io_out_s3_full_pred_0_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_jalr                    (ftb_io_out_s3_full_pred_0_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_call                    (ftb_io_out_s3_full_pred_0_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_ret                     (ftb_io_out_s3_full_pred_0_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_0_last_may_be_rvi_call       (ftb_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_0_is_br_sharing              (ftb_io_out_s3_full_pred_0_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_0_hit                        (ftb_io_out_s3_full_pred_0_hit),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_0            (ftb_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_br_taken_mask_1            (ftb_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_0              (ftb_io_out_s3_full_pred_1_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_slot_valids_1              (ftb_io_out_s3_full_pred_1_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_0                  (ftb_io_out_s3_full_pred_1_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_targets_1                  (ftb_io_out_s3_full_pred_1_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_0                  (ftb_io_out_s3_full_pred_1_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_1_offsets_1                  (ftb_io_out_s3_full_pred_1_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughAddr            (ftb_io_out_s3_full_pred_1_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_1_fallThroughErr             (ftb_io_out_s3_full_pred_1_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_1_multiHit                   (ftb_io_out_s3_full_pred_1_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jal                     (ftb_io_out_s3_full_pred_1_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_jalr                    (ftb_io_out_s3_full_pred_1_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_call                    (ftb_io_out_s3_full_pred_1_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_ret                     (ftb_io_out_s3_full_pred_1_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_1_last_may_be_rvi_call       (ftb_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_1_is_br_sharing              (ftb_io_out_s3_full_pred_1_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_1_hit                        (ftb_io_out_s3_full_pred_1_hit),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_0            (ftb_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_br_taken_mask_1            (ftb_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_0              (ftb_io_out_s3_full_pred_2_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_slot_valids_1              (ftb_io_out_s3_full_pred_2_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_0                  (ftb_io_out_s3_full_pred_2_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_targets_1                  (ftb_io_out_s3_full_pred_2_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_0                  (ftb_io_out_s3_full_pred_2_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_2_offsets_1                  (ftb_io_out_s3_full_pred_2_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughAddr            (ftb_io_out_s3_full_pred_2_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_2_fallThroughErr             (ftb_io_out_s3_full_pred_2_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_2_multiHit                   (ftb_io_out_s3_full_pred_2_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jal                     (ftb_io_out_s3_full_pred_2_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_jalr                    (ftb_io_out_s3_full_pred_2_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_call                    (ftb_io_out_s3_full_pred_2_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_ret                     (ftb_io_out_s3_full_pred_2_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_2_last_may_be_rvi_call       (ftb_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_2_is_br_sharing              (ftb_io_out_s3_full_pred_2_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_2_hit                        (ftb_io_out_s3_full_pred_2_hit),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_0            (ftb_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_br_taken_mask_1            (ftb_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_0              (ftb_io_out_s3_full_pred_3_slot_valids_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_slot_valids_1              (ftb_io_out_s3_full_pred_3_slot_valids_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_0                  (ftb_io_out_s3_full_pred_3_targets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_targets_1                  (ftb_io_out_s3_full_pred_3_targets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_0                  (ftb_io_out_s3_full_pred_3_offsets_0),
    .io_in_bits_resp_in_0_s3_full_pred_3_offsets_1                  (ftb_io_out_s3_full_pred_3_offsets_1),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughAddr            (ftb_io_out_s3_full_pred_3_fallThroughAddr),
    .io_in_bits_resp_in_0_s3_full_pred_3_fallThroughErr             (ftb_io_out_s3_full_pred_3_fallThroughErr),
    .io_in_bits_resp_in_0_s3_full_pred_3_multiHit                   (ftb_io_out_s3_full_pred_3_multiHit),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jal                     (ftb_io_out_s3_full_pred_3_is_jal),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_jalr                    (ftb_io_out_s3_full_pred_3_is_jalr),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_call                    (ftb_io_out_s3_full_pred_3_is_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_ret                     (ftb_io_out_s3_full_pred_3_is_ret),
    .io_in_bits_resp_in_0_s3_full_pred_3_last_may_be_rvi_call       (ftb_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_s3_full_pred_3_is_br_sharing              (ftb_io_out_s3_full_pred_3_is_br_sharing),
    .io_in_bits_resp_in_0_s3_full_pred_3_hit                        (ftb_io_out_s3_full_pred_3_hit),
    .io_in_bits_resp_in_0_s1_uftbHit                                (ftb_io_out_s1_uftbHit),
    .io_in_bits_resp_in_0_s1_uftbHasIndirect                        (ftb_io_out_s1_uftbHasIndirect),
    .io_in_bits_resp_in_0_s1_ftbCloseReq                            (ftb_io_out_s1_ftbCloseReq),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_0        (ftb_io_out_last_stage_spec_info_sc_disagree_0),
    .io_in_bits_resp_in_0_last_stage_spec_info_sc_disagree_1        (ftb_io_out_last_stage_spec_info_sc_disagree_1),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isCall               (ftb_io_out_last_stage_ftb_entry_isCall),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isRet                (ftb_io_out_last_stage_ftb_entry_isRet),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_isJalr               (ftb_io_out_last_stage_ftb_entry_isJalr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_valid                (ftb_io_out_last_stage_ftb_entry_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_offset     (ftb_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_sharing    (ftb_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_valid      (ftb_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_lower      (ftb_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_brSlots_0_tarStat    (ftb_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_offset      (ftb_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_sharing     (ftb_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_valid       (ftb_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_lower       (ftb_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_tailSlot_tarStat     (ftb_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_pftAddr              (ftb_io_out_last_stage_ftb_entry_pftAddr),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_carry                (ftb_io_out_last_stage_ftb_entry_carry),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_last_may_be_rvi_call (ftb_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_0        (ftb_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_in_bits_resp_in_0_last_stage_ftb_entry_strong_bias_1        (ftb_io_out_last_stage_ftb_entry_strong_bias_1),
    // -- S2 预测输出（FTB / TAGE 覆盖） --
    .io_out_s2_full_pred_0_br_taken_mask_0                          (ittage_io_out_s2_full_pred_0_br_taken_mask_0),
    .io_out_s2_full_pred_0_br_taken_mask_1                          (ittage_io_out_s2_full_pred_0_br_taken_mask_1),
    .io_out_s2_full_pred_0_slot_valids_0                            (ittage_io_out_s2_full_pred_0_slot_valids_0),
    .io_out_s2_full_pred_0_slot_valids_1                            (ittage_io_out_s2_full_pred_0_slot_valids_1),
    .io_out_s2_full_pred_0_targets_0                                (ittage_io_out_s2_full_pred_0_targets_0),
    .io_out_s2_full_pred_0_targets_1                                (ittage_io_out_s2_full_pred_0_targets_1),
    .io_out_s2_full_pred_0_jalr_target                              (ittage_io_out_s2_full_pred_0_jalr_target),
    .io_out_s2_full_pred_0_offsets_0                                (ittage_io_out_s2_full_pred_0_offsets_0),
    .io_out_s2_full_pred_0_offsets_1                                (ittage_io_out_s2_full_pred_0_offsets_1),
    .io_out_s2_full_pred_0_fallThroughAddr                          (ittage_io_out_s2_full_pred_0_fallThroughAddr),
    .io_out_s2_full_pred_0_fallThroughErr                           (ittage_io_out_s2_full_pred_0_fallThroughErr),
    .io_out_s2_full_pred_0_is_jal                                   (ittage_io_out_s2_full_pred_0_is_jal),
    .io_out_s2_full_pred_0_is_jalr                                  (ittage_io_out_s2_full_pred_0_is_jalr),
    .io_out_s2_full_pred_0_is_call                                  (ittage_io_out_s2_full_pred_0_is_call),
    .io_out_s2_full_pred_0_is_ret                                   (ittage_io_out_s2_full_pred_0_is_ret),
    .io_out_s2_full_pred_0_last_may_be_rvi_call                     (ittage_io_out_s2_full_pred_0_last_may_be_rvi_call),
    .io_out_s2_full_pred_0_is_br_sharing                            (ittage_io_out_s2_full_pred_0_is_br_sharing),
    .io_out_s2_full_pred_0_hit                                      (ittage_io_out_s2_full_pred_0_hit),
    .io_out_s2_full_pred_1_br_taken_mask_0                          (ittage_io_out_s2_full_pred_1_br_taken_mask_0),
    .io_out_s2_full_pred_1_br_taken_mask_1                          (ittage_io_out_s2_full_pred_1_br_taken_mask_1),
    .io_out_s2_full_pred_1_slot_valids_0                            (ittage_io_out_s2_full_pred_1_slot_valids_0),
    .io_out_s2_full_pred_1_slot_valids_1                            (ittage_io_out_s2_full_pred_1_slot_valids_1),
    .io_out_s2_full_pred_1_targets_0                                (ittage_io_out_s2_full_pred_1_targets_0),
    .io_out_s2_full_pred_1_targets_1                                (ittage_io_out_s2_full_pred_1_targets_1),
    .io_out_s2_full_pred_1_jalr_target                              (ittage_io_out_s2_full_pred_1_jalr_target),
    .io_out_s2_full_pred_1_offsets_0                                (ittage_io_out_s2_full_pred_1_offsets_0),
    .io_out_s2_full_pred_1_offsets_1                                (ittage_io_out_s2_full_pred_1_offsets_1),
    .io_out_s2_full_pred_1_fallThroughAddr                          (ittage_io_out_s2_full_pred_1_fallThroughAddr),
    .io_out_s2_full_pred_1_fallThroughErr                           (ittage_io_out_s2_full_pred_1_fallThroughErr),
    .io_out_s2_full_pred_1_is_jal                                   (ittage_io_out_s2_full_pred_1_is_jal),
    .io_out_s2_full_pred_1_is_jalr                                  (ittage_io_out_s2_full_pred_1_is_jalr),
    .io_out_s2_full_pred_1_is_call                                  (ittage_io_out_s2_full_pred_1_is_call),
    .io_out_s2_full_pred_1_is_ret                                   (ittage_io_out_s2_full_pred_1_is_ret),
    .io_out_s2_full_pred_1_last_may_be_rvi_call                     (ittage_io_out_s2_full_pred_1_last_may_be_rvi_call),
    .io_out_s2_full_pred_1_is_br_sharing                            (ittage_io_out_s2_full_pred_1_is_br_sharing),
    .io_out_s2_full_pred_1_hit                                      (ittage_io_out_s2_full_pred_1_hit),
    .io_out_s2_full_pred_2_br_taken_mask_0                          (ittage_io_out_s2_full_pred_2_br_taken_mask_0),
    .io_out_s2_full_pred_2_br_taken_mask_1                          (ittage_io_out_s2_full_pred_2_br_taken_mask_1),
    .io_out_s2_full_pred_2_slot_valids_0                            (ittage_io_out_s2_full_pred_2_slot_valids_0),
    .io_out_s2_full_pred_2_slot_valids_1                            (ittage_io_out_s2_full_pred_2_slot_valids_1),
    .io_out_s2_full_pred_2_targets_0                                (ittage_io_out_s2_full_pred_2_targets_0),
    .io_out_s2_full_pred_2_targets_1                                (ittage_io_out_s2_full_pred_2_targets_1),
    .io_out_s2_full_pred_2_jalr_target                              (ittage_io_out_s2_full_pred_2_jalr_target),
    .io_out_s2_full_pred_2_offsets_0                                (ittage_io_out_s2_full_pred_2_offsets_0),
    .io_out_s2_full_pred_2_offsets_1                                (ittage_io_out_s2_full_pred_2_offsets_1),
    .io_out_s2_full_pred_2_fallThroughAddr                          (ittage_io_out_s2_full_pred_2_fallThroughAddr),
    .io_out_s2_full_pred_2_fallThroughErr                           (ittage_io_out_s2_full_pred_2_fallThroughErr),
    .io_out_s2_full_pred_2_is_jal                                   (ittage_io_out_s2_full_pred_2_is_jal),
    .io_out_s2_full_pred_2_is_jalr                                  (ittage_io_out_s2_full_pred_2_is_jalr),
    .io_out_s2_full_pred_2_is_call                                  (ittage_io_out_s2_full_pred_2_is_call),
    .io_out_s2_full_pred_2_is_ret                                   (ittage_io_out_s2_full_pred_2_is_ret),
    .io_out_s2_full_pred_2_last_may_be_rvi_call                     (ittage_io_out_s2_full_pred_2_last_may_be_rvi_call),
    .io_out_s2_full_pred_2_is_br_sharing                            (ittage_io_out_s2_full_pred_2_is_br_sharing),
    .io_out_s2_full_pred_2_hit                                      (ittage_io_out_s2_full_pred_2_hit),
    .io_out_s2_full_pred_3_br_taken_mask_0                          (ittage_io_out_s2_full_pred_3_br_taken_mask_0),
    .io_out_s2_full_pred_3_br_taken_mask_1                          (ittage_io_out_s2_full_pred_3_br_taken_mask_1),
    .io_out_s2_full_pred_3_slot_valids_0                            (ittage_io_out_s2_full_pred_3_slot_valids_0),
    .io_out_s2_full_pred_3_slot_valids_1                            (ittage_io_out_s2_full_pred_3_slot_valids_1),
    .io_out_s2_full_pred_3_targets_0                                (ittage_io_out_s2_full_pred_3_targets_0),
    .io_out_s2_full_pred_3_targets_1                                (ittage_io_out_s2_full_pred_3_targets_1),
    .io_out_s2_full_pred_3_jalr_target                              (ittage_io_out_s2_full_pred_3_jalr_target),
    .io_out_s2_full_pred_3_offsets_0                                (ittage_io_out_s2_full_pred_3_offsets_0),
    .io_out_s2_full_pred_3_offsets_1                                (ittage_io_out_s2_full_pred_3_offsets_1),
    .io_out_s2_full_pred_3_fallThroughAddr                          (ittage_io_out_s2_full_pred_3_fallThroughAddr),
    .io_out_s2_full_pred_3_fallThroughErr                           (ittage_io_out_s2_full_pred_3_fallThroughErr),
    .io_out_s2_full_pred_3_is_jal                                   (ittage_io_out_s2_full_pred_3_is_jal),
    .io_out_s2_full_pred_3_is_jalr                                  (ittage_io_out_s2_full_pred_3_is_jalr),
    .io_out_s2_full_pred_3_is_call                                  (ittage_io_out_s2_full_pred_3_is_call),
    .io_out_s2_full_pred_3_is_ret                                   (ittage_io_out_s2_full_pred_3_is_ret),
    .io_out_s2_full_pred_3_last_may_be_rvi_call                     (ittage_io_out_s2_full_pred_3_last_may_be_rvi_call),
    .io_out_s2_full_pred_3_is_br_sharing                            (ittage_io_out_s2_full_pred_3_is_br_sharing),
    .io_out_s2_full_pred_3_hit                                      (ittage_io_out_s2_full_pred_3_hit),
    // -- S3 预测输出（SC / ITTAGE / RAS 覆盖） --
    .io_out_s3_full_pred_0_br_taken_mask_0                          (ittage_io_out_s3_full_pred_0_br_taken_mask_0),
    .io_out_s3_full_pred_0_br_taken_mask_1                          (ittage_io_out_s3_full_pred_0_br_taken_mask_1),
    .io_out_s3_full_pred_0_slot_valids_0                            (ittage_io_out_s3_full_pred_0_slot_valids_0),
    .io_out_s3_full_pred_0_slot_valids_1                            (ittage_io_out_s3_full_pred_0_slot_valids_1),
    .io_out_s3_full_pred_0_targets_0                                (ittage_io_out_s3_full_pred_0_targets_0),
    .io_out_s3_full_pred_0_targets_1                                (ittage_io_out_s3_full_pred_0_targets_1),
    .io_out_s3_full_pred_0_jalr_target                              (ittage_io_out_s3_full_pred_0_jalr_target),
    .io_out_s3_full_pred_0_offsets_0                                (ittage_io_out_s3_full_pred_0_offsets_0),
    .io_out_s3_full_pred_0_offsets_1                                (ittage_io_out_s3_full_pred_0_offsets_1),
    .io_out_s3_full_pred_0_fallThroughAddr                          (ittage_io_out_s3_full_pred_0_fallThroughAddr),
    .io_out_s3_full_pred_0_fallThroughErr                           (ittage_io_out_s3_full_pred_0_fallThroughErr),
    .io_out_s3_full_pred_0_multiHit                                 (ittage_io_out_s3_full_pred_0_multiHit),
    .io_out_s3_full_pred_0_is_jal                                   (ittage_io_out_s3_full_pred_0_is_jal),
    .io_out_s3_full_pred_0_is_jalr                                  (ittage_io_out_s3_full_pred_0_is_jalr),
    .io_out_s3_full_pred_0_is_call                                  (ittage_io_out_s3_full_pred_0_is_call),
    .io_out_s3_full_pred_0_is_ret                                   (ittage_io_out_s3_full_pred_0_is_ret),
    .io_out_s3_full_pred_0_last_may_be_rvi_call                     (ittage_io_out_s3_full_pred_0_last_may_be_rvi_call),
    .io_out_s3_full_pred_0_is_br_sharing                            (ittage_io_out_s3_full_pred_0_is_br_sharing),
    .io_out_s3_full_pred_0_hit                                      (ittage_io_out_s3_full_pred_0_hit),
    .io_out_s3_full_pred_1_br_taken_mask_0                          (ittage_io_out_s3_full_pred_1_br_taken_mask_0),
    .io_out_s3_full_pred_1_br_taken_mask_1                          (ittage_io_out_s3_full_pred_1_br_taken_mask_1),
    .io_out_s3_full_pred_1_slot_valids_0                            (ittage_io_out_s3_full_pred_1_slot_valids_0),
    .io_out_s3_full_pred_1_slot_valids_1                            (ittage_io_out_s3_full_pred_1_slot_valids_1),
    .io_out_s3_full_pred_1_targets_0                                (ittage_io_out_s3_full_pred_1_targets_0),
    .io_out_s3_full_pred_1_targets_1                                (ittage_io_out_s3_full_pred_1_targets_1),
    .io_out_s3_full_pred_1_jalr_target                              (ittage_io_out_s3_full_pred_1_jalr_target),
    .io_out_s3_full_pred_1_offsets_0                                (ittage_io_out_s3_full_pred_1_offsets_0),
    .io_out_s3_full_pred_1_offsets_1                                (ittage_io_out_s3_full_pred_1_offsets_1),
    .io_out_s3_full_pred_1_fallThroughAddr                          (ittage_io_out_s3_full_pred_1_fallThroughAddr),
    .io_out_s3_full_pred_1_fallThroughErr                           (ittage_io_out_s3_full_pred_1_fallThroughErr),
    .io_out_s3_full_pred_1_multiHit                                 (ittage_io_out_s3_full_pred_1_multiHit),
    .io_out_s3_full_pred_1_is_jal                                   (ittage_io_out_s3_full_pred_1_is_jal),
    .io_out_s3_full_pred_1_is_jalr                                  (ittage_io_out_s3_full_pred_1_is_jalr),
    .io_out_s3_full_pred_1_is_call                                  (ittage_io_out_s3_full_pred_1_is_call),
    .io_out_s3_full_pred_1_is_ret                                   (ittage_io_out_s3_full_pred_1_is_ret),
    .io_out_s3_full_pred_1_last_may_be_rvi_call                     (ittage_io_out_s3_full_pred_1_last_may_be_rvi_call),
    .io_out_s3_full_pred_1_is_br_sharing                            (ittage_io_out_s3_full_pred_1_is_br_sharing),
    .io_out_s3_full_pred_1_hit                                      (ittage_io_out_s3_full_pred_1_hit),
    .io_out_s3_full_pred_2_br_taken_mask_0                          (ittage_io_out_s3_full_pred_2_br_taken_mask_0),
    .io_out_s3_full_pred_2_br_taken_mask_1                          (ittage_io_out_s3_full_pred_2_br_taken_mask_1),
    .io_out_s3_full_pred_2_slot_valids_0                            (ittage_io_out_s3_full_pred_2_slot_valids_0),
    .io_out_s3_full_pred_2_slot_valids_1                            (ittage_io_out_s3_full_pred_2_slot_valids_1),
    .io_out_s3_full_pred_2_targets_0                                (ittage_io_out_s3_full_pred_2_targets_0),
    .io_out_s3_full_pred_2_targets_1                                (ittage_io_out_s3_full_pred_2_targets_1),
    .io_out_s3_full_pred_2_jalr_target                              (ittage_io_out_s3_full_pred_2_jalr_target),
    .io_out_s3_full_pred_2_offsets_0                                (ittage_io_out_s3_full_pred_2_offsets_0),
    .io_out_s3_full_pred_2_offsets_1                                (ittage_io_out_s3_full_pred_2_offsets_1),
    .io_out_s3_full_pred_2_fallThroughAddr                          (ittage_io_out_s3_full_pred_2_fallThroughAddr),
    .io_out_s3_full_pred_2_fallThroughErr                           (ittage_io_out_s3_full_pred_2_fallThroughErr),
    .io_out_s3_full_pred_2_multiHit                                 (ittage_io_out_s3_full_pred_2_multiHit),
    .io_out_s3_full_pred_2_is_jal                                   (ittage_io_out_s3_full_pred_2_is_jal),
    .io_out_s3_full_pred_2_is_jalr                                  (ittage_io_out_s3_full_pred_2_is_jalr),
    .io_out_s3_full_pred_2_is_call                                  (ittage_io_out_s3_full_pred_2_is_call),
    .io_out_s3_full_pred_2_is_ret                                   (ittage_io_out_s3_full_pred_2_is_ret),
    .io_out_s3_full_pred_2_last_may_be_rvi_call                     (ittage_io_out_s3_full_pred_2_last_may_be_rvi_call),
    .io_out_s3_full_pred_2_is_br_sharing                            (ittage_io_out_s3_full_pred_2_is_br_sharing),
    .io_out_s3_full_pred_2_hit                                      (ittage_io_out_s3_full_pred_2_hit),
    .io_out_s3_full_pred_3_br_taken_mask_0                          (ittage_io_out_s3_full_pred_3_br_taken_mask_0),
    .io_out_s3_full_pred_3_br_taken_mask_1                          (ittage_io_out_s3_full_pred_3_br_taken_mask_1),
    .io_out_s3_full_pred_3_slot_valids_0                            (ittage_io_out_s3_full_pred_3_slot_valids_0),
    .io_out_s3_full_pred_3_slot_valids_1                            (ittage_io_out_s3_full_pred_3_slot_valids_1),
    .io_out_s3_full_pred_3_targets_0                                (ittage_io_out_s3_full_pred_3_targets_0),
    .io_out_s3_full_pred_3_targets_1                                (ittage_io_out_s3_full_pred_3_targets_1),
    .io_out_s3_full_pred_3_jalr_target                              (ittage_io_out_s3_full_pred_3_jalr_target),
    .io_out_s3_full_pred_3_offsets_0                                (ittage_io_out_s3_full_pred_3_offsets_0),
    .io_out_s3_full_pred_3_offsets_1                                (ittage_io_out_s3_full_pred_3_offsets_1),
    .io_out_s3_full_pred_3_fallThroughAddr                          (ittage_io_out_s3_full_pred_3_fallThroughAddr),
    .io_out_s3_full_pred_3_fallThroughErr                           (ittage_io_out_s3_full_pred_3_fallThroughErr),
    .io_out_s3_full_pred_3_multiHit                                 (ittage_io_out_s3_full_pred_3_multiHit),
    .io_out_s3_full_pred_3_is_jal                                   (ittage_io_out_s3_full_pred_3_is_jal),
    .io_out_s3_full_pred_3_is_jalr                                  (ittage_io_out_s3_full_pred_3_is_jalr),
    .io_out_s3_full_pred_3_is_call                                  (ittage_io_out_s3_full_pred_3_is_call),
    .io_out_s3_full_pred_3_is_ret                                   (ittage_io_out_s3_full_pred_3_is_ret),
    .io_out_s3_full_pred_3_last_may_be_rvi_call                     (ittage_io_out_s3_full_pred_3_last_may_be_rvi_call),
    .io_out_s3_full_pred_3_is_br_sharing                            (ittage_io_out_s3_full_pred_3_is_br_sharing),
    .io_out_s3_full_pred_3_hit                                      (ittage_io_out_s3_full_pred_3_hit),
    // -- 末级 meta / FTB entry（写回 FTQ，update 时原样送回） --
    .io_out_last_stage_meta                                         (ittage_io_out_last_stage_meta),
    .io_out_last_stage_spec_info_sc_disagree_0                      (ittage_io_out_last_stage_spec_info_sc_disagree_0),
    .io_out_last_stage_spec_info_sc_disagree_1                      (ittage_io_out_last_stage_spec_info_sc_disagree_1),
    .io_out_last_stage_ftb_entry_isCall                             (ittage_io_out_last_stage_ftb_entry_isCall),
    .io_out_last_stage_ftb_entry_isRet                              (ittage_io_out_last_stage_ftb_entry_isRet),
    .io_out_last_stage_ftb_entry_isJalr                             (ittage_io_out_last_stage_ftb_entry_isJalr),
    .io_out_last_stage_ftb_entry_valid                              (ittage_io_out_last_stage_ftb_entry_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_offset                   (ittage_io_out_last_stage_ftb_entry_brSlots_0_offset),
    .io_out_last_stage_ftb_entry_brSlots_0_sharing                  (ittage_io_out_last_stage_ftb_entry_brSlots_0_sharing),
    .io_out_last_stage_ftb_entry_brSlots_0_valid                    (ittage_io_out_last_stage_ftb_entry_brSlots_0_valid),
    .io_out_last_stage_ftb_entry_brSlots_0_lower                    (ittage_io_out_last_stage_ftb_entry_brSlots_0_lower),
    .io_out_last_stage_ftb_entry_brSlots_0_tarStat                  (ittage_io_out_last_stage_ftb_entry_brSlots_0_tarStat),
    .io_out_last_stage_ftb_entry_tailSlot_offset                    (ittage_io_out_last_stage_ftb_entry_tailSlot_offset),
    .io_out_last_stage_ftb_entry_tailSlot_sharing                   (ittage_io_out_last_stage_ftb_entry_tailSlot_sharing),
    .io_out_last_stage_ftb_entry_tailSlot_valid                     (ittage_io_out_last_stage_ftb_entry_tailSlot_valid),
    .io_out_last_stage_ftb_entry_tailSlot_lower                     (ittage_io_out_last_stage_ftb_entry_tailSlot_lower),
    .io_out_last_stage_ftb_entry_tailSlot_tarStat                   (ittage_io_out_last_stage_ftb_entry_tailSlot_tarStat),
    .io_out_last_stage_ftb_entry_pftAddr                            (ittage_io_out_last_stage_ftb_entry_pftAddr),
    .io_out_last_stage_ftb_entry_carry                              (ittage_io_out_last_stage_ftb_entry_carry),
    .io_out_last_stage_ftb_entry_last_may_be_rvi_call               (ittage_io_out_last_stage_ftb_entry_last_may_be_rvi_call),
    .io_out_last_stage_ftb_entry_strong_bias_0                      (ittage_io_out_last_stage_ftb_entry_strong_bias_0),
    .io_out_last_stage_ftb_entry_strong_bias_1                      (ittage_io_out_last_stage_ftb_entry_strong_bias_1),
    // -- S0~S3 流水握手（fire = valid & ready，4 份 dup） --
    .io_s0_fire_0                                                   (io_s0_fire_0),
    .io_s0_fire_1                                                   (io_s0_fire_1),
    .io_s0_fire_2                                                   (io_s0_fire_2),
    .io_s0_fire_3                                                   (io_s0_fire_3),
    .io_s1_fire_0                                                   (io_s1_fire_0),
    .io_s1_fire_1                                                   (io_s1_fire_1),
    .io_s1_fire_2                                                   (io_s1_fire_2),
    .io_s1_fire_3                                                   (io_s1_fire_3),
    .io_s2_fire_0                                                   (io_s2_fire_0),
    .io_s2_fire_1                                                   (io_s2_fire_1),
    .io_s2_fire_2                                                   (io_s2_fire_2),
    .io_s2_fire_3                                                   (io_s2_fire_3),
    // -- S1 就绪（三大表相与） --
    .io_s1_ready                                                    (ittage_io_s1_ready),
    // -- FTQ commit 回来的训练更新 --
    .io_update_valid                                                (io_update_valid),
    .io_update_bits_pc                                              (io_update_bits_pc),
    .io_update_bits_ftb_entry_isRet                                 (io_update_bits_ftb_entry_isRet),
    .io_update_bits_ftb_entry_isJalr                                (io_update_bits_ftb_entry_isJalr),
    .io_update_bits_ftb_entry_tailSlot_offset                       (io_update_bits_ftb_entry_tailSlot_offset),
    .io_update_bits_ftb_entry_tailSlot_sharing                      (io_update_bits_ftb_entry_tailSlot_sharing),
    .io_update_bits_ftb_entry_tailSlot_valid                        (io_update_bits_ftb_entry_tailSlot_valid),
    .io_update_bits_ftb_entry_strong_bias_1                         (io_update_bits_ftb_entry_strong_bias_1),
    .io_update_bits_cfi_idx_valid                                   (io_update_bits_cfi_idx_valid),
    .io_update_bits_cfi_idx_bits                                    (io_update_bits_cfi_idx_bits),
    .io_update_bits_jmp_taken                                       (io_update_bits_jmp_taken),
    .io_update_bits_mispred_mask_2                                  (io_update_bits_mispred_mask_2),
    .io_update_bits_meta                                            ({10'h0, io_update_bits_meta[515:10]}),
    .io_update_bits_full_target                                     (io_update_bits_full_target),
    .io_update_bits_ghist                                           (io_update_bits_ghist),
    // -- MBIST 子链地址/数据（bore）—— G1 把 addr/addr_rd 由 9 位收窄到 8 位 --
    .boreChildrenBd_bore_array                                      (boreChildrenBd_bore_6_array),
    .boreChildrenBd_bore_all                                        (boreChildrenBd_bore_6_all),
    .boreChildrenBd_bore_req                                        (boreChildrenBd_bore_6_req),
    .boreChildrenBd_bore_ack                                        (boreChildrenBd_bore_6_ack),
    .boreChildrenBd_bore_writeen                                    (boreChildrenBd_bore_6_writeen),
    .boreChildrenBd_bore_be                                         (boreChildrenBd_bore_6_be),
    .boreChildrenBd_bore_addr                                       (boreChildrenBd_bore_6_addr),
    .boreChildrenBd_bore_indata                                     (boreChildrenBd_bore_6_indata),
    .boreChildrenBd_bore_readen                                     (boreChildrenBd_bore_6_readen),
    .boreChildrenBd_bore_addr_rd                                    (boreChildrenBd_bore_6_addr_rd),
    .boreChildrenBd_bore_outdata                                    (boreChildrenBd_bore_6_outdata),
    .boreChildrenBd_bore_1_array                                    (boreChildrenBd_bore_7_array),
    .boreChildrenBd_bore_1_all                                      (boreChildrenBd_bore_7_all),
    .boreChildrenBd_bore_1_req                                      (boreChildrenBd_bore_7_req),
    .boreChildrenBd_bore_1_ack                                      (boreChildrenBd_bore_7_ack),
    .boreChildrenBd_bore_1_writeen                                  (boreChildrenBd_bore_7_writeen),
    .boreChildrenBd_bore_1_be                                       (boreChildrenBd_bore_7_be),
    .boreChildrenBd_bore_1_addr                                     (boreChildrenBd_bore_7_addr),
    .boreChildrenBd_bore_1_indata                                   (boreChildrenBd_bore_7_indata),
    .boreChildrenBd_bore_1_readen                                   (boreChildrenBd_bore_7_readen),
    .boreChildrenBd_bore_1_addr_rd                                  (boreChildrenBd_bore_7_addr_rd),
    .boreChildrenBd_bore_1_outdata                                  (boreChildrenBd_bore_7_outdata),
    .boreChildrenBd_bore_2_array                                    (boreChildrenBd_bore_8_array),
    .boreChildrenBd_bore_2_all                                      (boreChildrenBd_bore_8_all),
    .boreChildrenBd_bore_2_req                                      (boreChildrenBd_bore_8_req),
    .boreChildrenBd_bore_2_ack                                      (boreChildrenBd_bore_8_ack),
    .boreChildrenBd_bore_2_writeen                                  (boreChildrenBd_bore_8_writeen),
    .boreChildrenBd_bore_2_be                                       (boreChildrenBd_bore_8_be),
    .boreChildrenBd_bore_2_addr                                     (boreChildrenBd_bore_8_addr),
    .boreChildrenBd_bore_2_indata                                   (boreChildrenBd_bore_8_indata),
    .boreChildrenBd_bore_2_readen                                   (boreChildrenBd_bore_8_readen),
    .boreChildrenBd_bore_2_addr_rd                                  (boreChildrenBd_bore_8_addr_rd),
    .boreChildrenBd_bore_2_outdata                                  (boreChildrenBd_bore_8_outdata),
    .boreChildrenBd_bore_3_array                                    (boreChildrenBd_bore_9_array),
    .boreChildrenBd_bore_3_all                                      (boreChildrenBd_bore_9_all),
    .boreChildrenBd_bore_3_req                                      (boreChildrenBd_bore_9_req),
    .boreChildrenBd_bore_3_ack                                      (boreChildrenBd_bore_9_ack),
    .boreChildrenBd_bore_3_writeen                                  (boreChildrenBd_bore_9_writeen),
    .boreChildrenBd_bore_3_be                                       (boreChildrenBd_bore_9_be),
    .boreChildrenBd_bore_3_addr                                     (boreChildrenBd_bore_9_addr),
    .boreChildrenBd_bore_3_indata                                   (boreChildrenBd_bore_9_indata),
    .boreChildrenBd_bore_3_readen                                   (boreChildrenBd_bore_9_readen),
    .boreChildrenBd_bore_3_addr_rd                                  (boreChildrenBd_bore_9_addr_rd),
    .boreChildrenBd_bore_3_outdata                                  (boreChildrenBd_bore_9_outdata),
    .boreChildrenBd_bore_4_array                                    (boreChildrenBd_bore_10_array),
    .boreChildrenBd_bore_4_all                                      (boreChildrenBd_bore_10_all),
    .boreChildrenBd_bore_4_req                                      (boreChildrenBd_bore_10_req),
    .boreChildrenBd_bore_4_ack                                      (boreChildrenBd_bore_10_ack),
    .boreChildrenBd_bore_4_writeen                                  (boreChildrenBd_bore_10_writeen),
    .boreChildrenBd_bore_4_be                                       (boreChildrenBd_bore_10_be),
    .boreChildrenBd_bore_4_addr                                     (boreChildrenBd_bore_10_addr),
    .boreChildrenBd_bore_4_indata                                   (boreChildrenBd_bore_10_indata),
    .boreChildrenBd_bore_4_readen                                   (boreChildrenBd_bore_10_readen),
    .boreChildrenBd_bore_4_addr_rd                                  (boreChildrenBd_bore_10_addr_rd),
    .boreChildrenBd_bore_4_outdata                                  (boreChildrenBd_bore_10_outdata),
    // -- MBIST SRAM 侧带外控制（每 bore 7 根：hold/bypass/bp_clken/aux_clk/aux_ckbp/mcp_hold/cgen） --
    .sigFromSrams_bore_ram_hold                                     (sigFromSrams_bore_40_ram_hold),
    .sigFromSrams_bore_ram_bypass                                   (sigFromSrams_bore_40_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken                                 (sigFromSrams_bore_40_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk                                  (sigFromSrams_bore_40_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp                                 (sigFromSrams_bore_40_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold                                 (sigFromSrams_bore_40_ram_mcp_hold),
    .sigFromSrams_bore_cgen                                         (sigFromSrams_bore_40_cgen),
    .sigFromSrams_bore_1_ram_hold                                   (sigFromSrams_bore_41_ram_hold),
    .sigFromSrams_bore_1_ram_bypass                                 (sigFromSrams_bore_41_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken                               (sigFromSrams_bore_41_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk                                (sigFromSrams_bore_41_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp                               (sigFromSrams_bore_41_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold                               (sigFromSrams_bore_41_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen                                       (sigFromSrams_bore_41_cgen),
    .sigFromSrams_bore_2_ram_hold                                   (sigFromSrams_bore_42_ram_hold),
    .sigFromSrams_bore_2_ram_bypass                                 (sigFromSrams_bore_42_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken                               (sigFromSrams_bore_42_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk                                (sigFromSrams_bore_42_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp                               (sigFromSrams_bore_42_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold                               (sigFromSrams_bore_42_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen                                       (sigFromSrams_bore_42_cgen),
    .sigFromSrams_bore_3_ram_hold                                   (sigFromSrams_bore_43_ram_hold),
    .sigFromSrams_bore_3_ram_bypass                                 (sigFromSrams_bore_43_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken                               (sigFromSrams_bore_43_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk                                (sigFromSrams_bore_43_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp                               (sigFromSrams_bore_43_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold                               (sigFromSrams_bore_43_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen                                       (sigFromSrams_bore_43_cgen),
    .sigFromSrams_bore_4_ram_hold                                   (sigFromSrams_bore_44_ram_hold),
    .sigFromSrams_bore_4_ram_bypass                                 (sigFromSrams_bore_44_ram_bypass),
    .sigFromSrams_bore_4_ram_bp_clken                               (sigFromSrams_bore_44_ram_bp_clken),
    .sigFromSrams_bore_4_ram_aux_clk                                (sigFromSrams_bore_44_ram_aux_clk),
    .sigFromSrams_bore_4_ram_aux_ckbp                               (sigFromSrams_bore_44_ram_aux_ckbp),
    .sigFromSrams_bore_4_ram_mcp_hold                               (sigFromSrams_bore_44_ram_mcp_hold),
    .sigFromSrams_bore_4_cgen                                       (sigFromSrams_bore_44_cgen),
    .sigFromSrams_bore_5_ram_hold                                   (sigFromSrams_bore_45_ram_hold),
    .sigFromSrams_bore_5_ram_bypass                                 (sigFromSrams_bore_45_ram_bypass),
    .sigFromSrams_bore_5_ram_bp_clken                               (sigFromSrams_bore_45_ram_bp_clken),
    .sigFromSrams_bore_5_ram_aux_clk                                (sigFromSrams_bore_45_ram_aux_clk),
    .sigFromSrams_bore_5_ram_aux_ckbp                               (sigFromSrams_bore_45_ram_aux_ckbp),
    .sigFromSrams_bore_5_ram_mcp_hold                               (sigFromSrams_bore_45_ram_mcp_hold),
    .sigFromSrams_bore_5_cgen                                       (sigFromSrams_bore_45_cgen),
    .sigFromSrams_bore_6_ram_hold                                   (sigFromSrams_bore_46_ram_hold),
    .sigFromSrams_bore_6_ram_bypass                                 (sigFromSrams_bore_46_ram_bypass),
    .sigFromSrams_bore_6_ram_bp_clken                               (sigFromSrams_bore_46_ram_bp_clken),
    .sigFromSrams_bore_6_ram_aux_clk                                (sigFromSrams_bore_46_ram_aux_clk),
    .sigFromSrams_bore_6_ram_aux_ckbp                               (sigFromSrams_bore_46_ram_aux_ckbp),
    .sigFromSrams_bore_6_ram_mcp_hold                               (sigFromSrams_bore_46_ram_mcp_hold),
    .sigFromSrams_bore_6_cgen                                       (sigFromSrams_bore_46_cgen),
    .sigFromSrams_bore_7_ram_hold                                   (sigFromSrams_bore_47_ram_hold),
    .sigFromSrams_bore_7_ram_bypass                                 (sigFromSrams_bore_47_ram_bypass),
    .sigFromSrams_bore_7_ram_bp_clken                               (sigFromSrams_bore_47_ram_bp_clken),
    .sigFromSrams_bore_7_ram_aux_clk                                (sigFromSrams_bore_47_ram_aux_clk),
    .sigFromSrams_bore_7_ram_aux_ckbp                               (sigFromSrams_bore_47_ram_aux_ckbp),
    .sigFromSrams_bore_7_ram_mcp_hold                               (sigFromSrams_bore_47_ram_mcp_hold),
    .sigFromSrams_bore_7_cgen                                       (sigFromSrams_bore_47_cgen)
  );

  // ---------------------------------------------------------------------------
  // DelayN uftb_io_ctrl_delay —— ctrl 打拍：CSR 开关信号延迟对齐到各预测器的使用级
  // ---------------------------------------------------------------------------
  DelayN uftb_io_ctrl_delay (
    // -- 时钟与复位 --
    .clock              (clock),
    // -- 其余 io --
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    // -- 其余预测输出 --
    .io_out_ubtb_enable (uftb_io_ctrl_delay_io_out_ubtb_enable),
    .io_out_btb_enable  (/* unused */),
    .io_out_tage_enable (/* unused */),
    .io_out_sc_enable   (/* unused */),
    .io_out_ras_enable  (/* unused */)
  );

  // ---------------------------------------------------------------------------
  // DelayN tage_io_ctrl_delay —— ctrl 打拍（同上）
  // ---------------------------------------------------------------------------
  DelayN tage_io_ctrl_delay (
    // -- 时钟与复位 --
    .clock              (clock),
    // -- 其余 io --
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    // -- 其余预测输出 --
    .io_out_ubtb_enable (/* unused */),
    .io_out_btb_enable  (/* unused */),
    .io_out_tage_enable (tage_io_ctrl_delay_io_out_tage_enable),
    .io_out_sc_enable   (tage_io_ctrl_delay_io_out_sc_enable),
    .io_out_ras_enable  (/* unused */)
  );

  // ---------------------------------------------------------------------------
  // DelayN ftb_io_ctrl_delay —— ctrl 打拍（同上）
  // ---------------------------------------------------------------------------
  DelayN ftb_io_ctrl_delay (
    // -- 时钟与复位 --
    .clock              (clock),
    // -- 其余 io --
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    // -- 其余预测输出 --
    .io_out_ubtb_enable (/* unused */),
    .io_out_btb_enable  (ftb_io_ctrl_delay_io_out_btb_enable),
    .io_out_tage_enable (/* unused */),
    .io_out_sc_enable   (/* unused */),
    .io_out_ras_enable  (/* unused */)
  );

  // ---------------------------------------------------------------------------
  // DelayN ras_io_ctrl_delay —— ctrl 打拍（同上）
  // ---------------------------------------------------------------------------
  DelayN ras_io_ctrl_delay (
    // -- 时钟与复位 --
    .clock              (clock),
    // -- 其余 io --
    .io_in_ubtb_enable  (io_ctrl_ubtb_enable),
    .io_in_btb_enable   (io_ctrl_btb_enable),
    .io_in_tage_enable  (io_ctrl_tage_enable),
    .io_in_sc_enable    (io_ctrl_sc_enable),
    .io_in_ras_enable   (io_ctrl_ras_enable),
    // -- 其余预测输出 --
    .io_out_ubtb_enable (/* unused */),
    .io_out_btb_enable  (/* unused */),
    .io_out_tage_enable (/* unused */),
    .io_out_sc_enable   (/* unused */),
    .io_out_ras_enable  (ras_io_ctrl_delay_io_out_ras_enable)
  );
  // END GENERATED

  // ---------------------------------------------------------------------------
  // uFTB 在 S1 给出的 br_taken_mask：一路送顶层输出，一路旁路给 TAGE-SC。
  // （★ G1 新增的功能连接：G0 里 uftb 这两根只接顶层输出，TAGE 看不到它。
  //   对应 Tage_SC 新增的两个 io_in_bits_resp_in_0_s1_full_pred_0_br_taken_mask_* 端口，
  //   连接在上面 tage 例化块里。）
  // ---------------------------------------------------------------------------
  assign io_out_s1_full_pred_0_br_taken_mask_0 = uftb_io_out_s1_full_pred_0_br_taken_mask_0;
  assign io_out_s1_full_pred_0_br_taken_mask_1 = uftb_io_out_s1_full_pred_0_br_taken_mask_1;

  // ---------------------------------------------------------------------------
  // 可读核：本层自己算的 11 个输出（perf ×7 / meta / s1_ready）与影子 PC 流水。
  // ---------------------------------------------------------------------------
  // 核用数组端口表达"4 份 dup / 7 路 perf"这类对称结构，wrapper 这里把 golden 的
  // 扁平端口装进数组网再接过去（装配层唯一的"改形状"动作，无逻辑）。
  wire [49:0] core_s0_pc   [composer_pkg::NUM_DUP];
  wire        core_s0_fire [composer_pkg::NUM_DUP];
  wire        core_s1_fire [composer_pkg::NUM_DUP];
  wire        core_s2_fire [composer_pkg::NUM_DUP];
  wire [5:0]  core_perf_in [composer_pkg::NUM_PERF];
  wire [5:0]  core_perf_out[composer_pkg::NUM_PERF];

  assign core_s0_pc   = '{io_in_bits_s0_pc_0, io_in_bits_s0_pc_1,
                          io_in_bits_s0_pc_2, io_in_bits_s0_pc_3};
  assign core_s0_fire = '{io_s0_fire_0, io_s0_fire_1, io_s0_fire_2, io_s0_fire_3};
  assign core_s1_fire = '{io_s1_fire_0, io_s1_fire_1, io_s1_fire_2, io_s1_fire_3};
  assign core_s2_fire = '{io_s2_fire_0, io_s2_fire_1, io_s2_fire_2, io_s2_fire_3};
  // perf 源顺序：0/1 = uFTB, 2/3/4 = TAGE-SC, 5/6 = FTB
  assign core_perf_in = '{uftb_io_perf_0_value, uftb_io_perf_1_value,
                          tage_io_perf_0_value, tage_io_perf_1_value,
                          tage_io_perf_2_value,
                          ftb_io_perf_0_value,  ftb_io_perf_1_value};

  assign io_perf_0_value = core_perf_out[0];
  assign io_perf_1_value = core_perf_out[1];
  assign io_perf_2_value = core_perf_out[2];
  assign io_perf_3_value = core_perf_out[3];
  assign io_perf_4_value = core_perf_out[4];
  assign io_perf_5_value = core_perf_out[5];
  assign io_perf_6_value = core_perf_out[6];

  xs_Composer_core u_core (
    .clock            (clock),
    .reset            (reset),
    .io_reset_vector  (io_reset_vector),
    .s0_pc            (core_s0_pc),
    .s0_fire          (core_s0_fire),
    .s1_fire          (core_s1_fire),
    .s2_fire          (core_s2_fire),
    .perf_in          (core_perf_in),
    // meta 段宽度与 golden 的切片逐位一致
    .meta_uftb        (uftb_io_out_last_stage_meta[5:0]),
    .meta_tage        (tage_io_out_last_stage_meta[143:0]),
    .meta_ftb         (ftb_io_out_last_stage_meta[66:0]),
    .meta_ittage      (ittage_io_out_last_stage_meta[181:0]),
    .meta_ras         (ras_io_out_last_stage_meta[9:0]),
    .s1_ready_tage    (tage_io_s1_ready),
    .s1_ready_ftb     (ftb_io_s1_ready),
    .s1_ready_ittage  (ittage_io_s1_ready),
    .perf_out         (core_perf_out),
    .last_stage_meta  (io_out_last_stage_meta),
    .s1_ready         (io_s1_ready)
  );

endmodule
