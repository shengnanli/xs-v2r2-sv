// ============================================================================
// xs_Composer_core —— BPU 预测器组合器（Composer）的可读核
// ============================================================================
//
// 【在前端的位置】
//   香山前端的分支预测单元 BPU 采用**多级覆盖式预测**：地址（s0_pc）一产生，最快的
//   预测器先出结果让取指立刻动起来，后面更慢更准的预测器在随后几拍**覆盖**前者。
//   各预测器由 Composer 组合，最终结果（s1/s2/s3 三级 full_pred + meta）写入 FTQ。
//
//   预测器与其覆盖时序（详见 docs/frontend/Composer.md）：
//     uFTB(FauFTB)  S1 当拍最快，32 路全相联微 FTB，给出第一版预测
//     FTB           容量大的取指目标缓冲，S2 给 fall-through / 分支槽
//     TAGE-SC       主方向预测器（几何历史标签表 + 统计校正），S2/S3 覆盖方向
//     ITTAGE        间接跳转目标预测，S3 覆盖 jalr_target
//     RAS           返回地址栈，预测 ret 目标，链尾，携最终 s2/s3 输出
//
// 【Composer 到底做什么】
//   关键观察：**覆盖式合成发生在各预测器内部**，不在 Composer 里。
//   Composer 把 5 个预测器串成一条**菊花链**：每个预测器吃上一级的 resp_in（前序预测
//   结果），在自己负责的字段上覆盖，再把整包结果传给下一级。链序为
//       uFTB → FTB(+TAGE) → ITTAGE → RAS → 最终输出
//   因此各级 full_pred / s2_pc / s3_pc 等输出由链尾 RAS（及链首 uFTB 的 s1）实例**直接
//   驱动顶层端口**，这些接线放在结构性 wrapper（Composer_wrapper.sv）里。
//
//   Composer 自身真正产生输出的逻辑只有三件事，全部落在本可读核里：
//     1. perf 计数对齐 ：把 uFTB/TAGE/FTB 的 perf 计数经 2 级寄存器打拍对齐后输出
//        （各预测器 perf 产生于不同流水级，统一延迟 2 拍便于上层 FTQ 采样）。
//     2. meta 拼接     ：把 5 个预测器各自的 last_stage_meta 段按固定布局拼成一个大 meta
//        （update 时再按同样布局拆开分发回各预测器，见文档“meta 组织”）。
//     3. s1_ready 相与 ：tage / ftb / ittage 三者都 ready 才允许 s1 接收新请求
//        （uFTB/RAS 永远 ready，不参与）。
//
// 【关于 golden 里的 s1/s2/s3_pc_dup】
//   firtool 生成的 golden 还含一大坨 s1/s2/s3_pc_dup 分段寄存器（把 PC 拆成 3 段、只在
//   段值变化时打拍的“debug PC 跟踪”）。在本 build 里它是**结构性死逻辑**——只喂
//   s2_pc_addr/s3_pc_addr 两个谁都不消费的 wire，对任何输出端口无影响（真正的 s2_pc/s3_pc
//   由 RAS 实例驱动）。故本可读核**不实现**它，仅在此说明，以免读者误以为遗漏。
//
// ============================================================================
module xs_Composer_core #(
    parameter int PERF_W = 6,    // 每个 perf 计数位宽
    parameter int META_W = 516,  // 拼接后 meta 总位宽
    // 各预测器 meta 段的有效位宽（见下方拼接布局）
    parameter int META_UFTB_W   = 6,
    parameter int META_TAGE_W   = 144,
    parameter int META_FTB_W    = 67,
    parameter int META_ITTAGE_W = 182,
    parameter int META_RAS_W    = 10
) (
    input  logic clock,
    input  logic reset,

    // ---- perf 计数源（来自各预测器，未对齐）----
    // perf_in_0/1 : uFTB ; perf_in_2/3/4 : TAGE-SC ; perf_in_5/6 : FTB
    input  logic [PERF_W-1:0] perf_in_0,
    input  logic [PERF_W-1:0] perf_in_1,
    input  logic [PERF_W-1:0] perf_in_2,
    input  logic [PERF_W-1:0] perf_in_3,
    input  logic [PERF_W-1:0] perf_in_4,
    input  logic [PERF_W-1:0] perf_in_5,
    input  logic [PERF_W-1:0] perf_in_6,

    // ---- 各预测器 last_stage_meta 的有效低位段（wrapper 已按 golden 同样的位宽切片，
    //      只送实际拼接进 meta 的那几位；其余高位在 wrapper 处即丢弃，不跨模块边界，
    //      以与 golden 的“仅读低位段”行为完全一致，避免 FM 把未读高位当比对点）----
    input  logic [META_UFTB_W-1:0]   meta_in_0,   // uFTB
    input  logic [META_TAGE_W-1:0]   meta_in_1,   // TAGE-SC
    input  logic [META_FTB_W-1:0]    meta_in_2,   // FTB
    input  logic [META_ITTAGE_W-1:0] meta_in_3,   // ITTAGE
    input  logic [META_RAS_W-1:0]    meta_in_4,   // RAS

    // ---- s1_ready 源 ----
    input  logic ready_in_0,   // TAGE-SC
    input  logic ready_in_1,   // FTB
    input  logic ready_in_2,   // ITTAGE

    // ---- 输出 ----
    output logic [PERF_W-1:0] io_perf_0_value,
    output logic [PERF_W-1:0] io_perf_1_value,
    output logic [PERF_W-1:0] io_perf_2_value,
    output logic [PERF_W-1:0] io_perf_3_value,
    output logic [PERF_W-1:0] io_perf_4_value,
    output logic [PERF_W-1:0] io_perf_5_value,
    output logic [PERF_W-1:0] io_perf_6_value,
    output logic [META_W-1:0] io_out_last_stage_meta,
    output logic              io_s1_ready
);

  // --------------------------------------------------------------------------
  // 1) perf 计数 2 级流水对齐
  //    各预测器 perf 产生于不同流水级，这里统一打 2 拍，让上层在同一时刻采到对齐的计数。
  //    用数组 + for 表达 7 路、每路 2 级寄存器，避免手工展开 14 个寄存器。
  // --------------------------------------------------------------------------
  localparam int N_PERF = 7;
  logic [PERF_W-1:0] perf_in   [N_PERF];
  logic [PERF_W-1:0] perf_s1   [N_PERF];   // 第 1 级
  logic [PERF_W-1:0] perf_s2   [N_PERF];   // 第 2 级（= 输出）

  always_comb begin
    perf_in[0] = perf_in_0; perf_in[1] = perf_in_1; perf_in[2] = perf_in_2;
    perf_in[3] = perf_in_3; perf_in[4] = perf_in_4; perf_in[5] = perf_in_5;
    perf_in[6] = perf_in_6;
  end

  for (genvar p = 0; p < N_PERF; p++) begin : g_perf_pipe
    always_ff @(posedge clock) begin
      perf_s1[p] <= perf_in[p];
      perf_s2[p] <= perf_s1[p];
    end
  end

  assign io_perf_0_value = perf_s2[0];
  assign io_perf_1_value = perf_s2[1];
  assign io_perf_2_value = perf_s2[2];
  assign io_perf_3_value = perf_s2[3];
  assign io_perf_4_value = perf_s2[4];
  assign io_perf_5_value = perf_s2[5];
  assign io_perf_6_value = perf_s2[6];

  // --------------------------------------------------------------------------
  // 2) meta 拼接
  //    把 5 个预测器各自有效的 meta 低位段，按固定布局拼成一个 516 位大 meta 写回 FTQ。
  //    update 时上层按完全相同的布局/偏移把 meta 拆回分发给各预测器（见文档）。
  //    布局（从高位到低位，高位补 0 填满 516）：
  //        [ 0 填充 | uFTB | TAGE | FTB | ITTAGE | RAS ]
  //    各段宽度： 107 | 6 | 144 | 67 | 182 | 10  = 516
  // --------------------------------------------------------------------------
  localparam int META_PAD_W = META_W - META_UFTB_W - META_TAGE_W
                            - META_FTB_W - META_ITTAGE_W - META_RAS_W;  // = 107

  assign io_out_last_stage_meta = {
      {META_PAD_W{1'b0}},
      meta_in_0,     // uFTB
      meta_in_1,     // TAGE-SC
      meta_in_2,     // FTB
      meta_in_3,     // ITTAGE
      meta_in_4      // RAS
  };

  // --------------------------------------------------------------------------
  // 3) s1_ready：方向/目标三大表都就绪才放行 s1 请求
  //    uFTB（全相联小表）与 RAS（栈）永远 ready，不参与该握手。
  // --------------------------------------------------------------------------
  assign io_s1_ready = ready_in_0 & ready_in_1 & ready_in_2;

endmodule
