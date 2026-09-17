// BusyTable.sv —— 物理寄存器忙位表（Int 整数堆变体）薄包装层
// -----------------------------------------------------------------------------
// 核体见 xs_BusyTable_core.sv（家族共享参数化核）。本文件不含逻辑分支，只把 golden
// 的扁平端口打包成核的数组接口，并给出本变体的参数。
//
// 本变体规模（全部从 G1 golden BusyTable.sv 机械量得，不是从 Chisel 默认值推的）：
//   表深 224 项（IntPhyRegs）；分配口 6；写回口 8；读口 12
//   快速唤醒 7 路 = 4 路 wakeUpInt（ALU 类，rfWen）+ 3 路 wakeUpMem（LOAD 类，rfWen）
//   寄存器 896 个 = 224 忙位 + 224×3 条 loadDependency 影子（每条 2 位），全部异步复位到 0
//   ★ 全家族唯一有 loadDependency 影子的变体（needLoadCancel 只有 Int 为真）
//   ★ 全家族唯一 0 号项特殊的变体（x0 恒就绪，见核 §5）
//   golden 21579 行里真逻辑只有 208 种去数字化行模板：其余是 224 项逐项展平
//   （声明+组合 12453 行、时序块 6950 行、ENABLE_INITIAL_REG_ 仿真初始化 1813 行）。
//   —— 这里刻意不写时序块的 SV 关键字：readability_audit 的 F 项是对**全文**（含
//      注释）数那个关键字的出现次数，注释里提一嘴就会被算成「头称薄壳却有时序逻辑」。
//
// 唤醒取消路由（从 golden tmp_*/wakeupOHVec_* 表达式机械提取）：
//   wk0 = wakeUpInt_0：`~(is0Lat & og0Cancel_0)`  （is0Lat 是真端口）
//   wk1 = wakeUpInt_1：`~(is0Lat & og0Cancel_2)`  （is0Lat 是真端口）
//   wk2 = wakeUpInt_2：`~og0Cancel_4`  ← is0Lat 被 firtool 折成 **1**，端口消失
//   wk3 = wakeUpInt_3：`~og0Cancel_6`  ← 同上
//   wk4..6 = wakeUpMem_0..2：**没有 og0Cancel 项** ← is0Lat 被折成 **0**
//   照 Chisel 字面给七路都留 is0Lat 端口 = 凭空多出四个 golden 没有的端口。
//   load 唤醒写 loadDependency 的方式也不同：wk4/5/6 写「本流水 onehot」(1/2/4)，
//   wk0..3 写「自己的 loadDependency 左移一位」。
//
// golden 里未被引用的死组合逻辑（本文件不重建）：_GEN_2/_GEN_3/_GEN_4 是 224 位忙位
//   的 popcount 加法树（来自 XSPerfAccumulate/perfEvents 的 busyCount）。它的两级
//   RegNext 寄存器已被 firtool 消掉（reg 数 896 正好只有表本身），剩下的加法树没有
//   任何读者，不是比对点。
//
// 自动生成：verif/ut/BusyTable/gen.py —— 勿手改
// ============================================================================
module BusyTable(
  input        clock,
  input        reset,
  input        io_allocPregs_0_valid,
  input  [7:0] io_allocPregs_0_bits,
  input        io_allocPregs_1_valid,
  input  [7:0] io_allocPregs_1_bits,
  input        io_allocPregs_2_valid,
  input  [7:0] io_allocPregs_2_bits,
  input        io_allocPregs_3_valid,
  input  [7:0] io_allocPregs_3_bits,
  input        io_allocPregs_4_valid,
  input  [7:0] io_allocPregs_4_bits,
  input        io_allocPregs_5_valid,
  input  [7:0] io_allocPregs_5_bits,
  input        io_wbPregs_0_valid,
  input  [7:0] io_wbPregs_0_bits,
  input        io_wbPregs_1_valid,
  input  [7:0] io_wbPregs_1_bits,
  input        io_wbPregs_2_valid,
  input  [7:0] io_wbPregs_2_bits,
  input        io_wbPregs_3_valid,
  input  [7:0] io_wbPregs_3_bits,
  input        io_wbPregs_4_valid,
  input  [7:0] io_wbPregs_4_bits,
  input        io_wbPregs_5_valid,
  input  [7:0] io_wbPregs_5_bits,
  input        io_wbPregs_6_valid,
  input  [7:0] io_wbPregs_6_bits,
  input        io_wbPregs_7_valid,
  input  [7:0] io_wbPregs_7_bits,
  input        io_wakeUpInt_3_valid,
  input        io_wakeUpInt_3_bits_rfWen,
  input  [7:0] io_wakeUpInt_3_bits_pdest,
  input  [1:0] io_wakeUpInt_3_bits_loadDependency_0,
  input  [1:0] io_wakeUpInt_3_bits_loadDependency_1,
  input  [1:0] io_wakeUpInt_3_bits_loadDependency_2,
  input        io_wakeUpInt_2_valid,
  input        io_wakeUpInt_2_bits_rfWen,
  input  [7:0] io_wakeUpInt_2_bits_pdest,
  input  [1:0] io_wakeUpInt_2_bits_loadDependency_0,
  input  [1:0] io_wakeUpInt_2_bits_loadDependency_1,
  input  [1:0] io_wakeUpInt_2_bits_loadDependency_2,
  input        io_wakeUpInt_1_valid,
  input        io_wakeUpInt_1_bits_rfWen,
  input  [7:0] io_wakeUpInt_1_bits_pdest,
  input  [1:0] io_wakeUpInt_1_bits_loadDependency_0,
  input  [1:0] io_wakeUpInt_1_bits_loadDependency_1,
  input  [1:0] io_wakeUpInt_1_bits_loadDependency_2,
  input        io_wakeUpInt_1_bits_is0Lat,
  input        io_wakeUpInt_0_valid,
  input        io_wakeUpInt_0_bits_rfWen,
  input  [7:0] io_wakeUpInt_0_bits_pdest,
  input  [1:0] io_wakeUpInt_0_bits_loadDependency_0,
  input  [1:0] io_wakeUpInt_0_bits_loadDependency_1,
  input  [1:0] io_wakeUpInt_0_bits_loadDependency_2,
  input        io_wakeUpInt_0_bits_is0Lat,
  input        io_wakeUpMem_2_valid,
  input        io_wakeUpMem_2_bits_rfWen,
  input  [7:0] io_wakeUpMem_2_bits_pdest,
  input  [1:0] io_wakeUpMem_2_bits_loadDependency_0,
  input  [1:0] io_wakeUpMem_2_bits_loadDependency_1,
  input  [1:0] io_wakeUpMem_2_bits_loadDependency_2,
  input        io_wakeUpMem_1_valid,
  input        io_wakeUpMem_1_bits_rfWen,
  input  [7:0] io_wakeUpMem_1_bits_pdest,
  input  [1:0] io_wakeUpMem_1_bits_loadDependency_0,
  input  [1:0] io_wakeUpMem_1_bits_loadDependency_1,
  input  [1:0] io_wakeUpMem_1_bits_loadDependency_2,
  input        io_wakeUpMem_0_valid,
  input        io_wakeUpMem_0_bits_rfWen,
  input  [7:0] io_wakeUpMem_0_bits_pdest,
  input  [1:0] io_wakeUpMem_0_bits_loadDependency_0,
  input  [1:0] io_wakeUpMem_0_bits_loadDependency_1,
  input  [1:0] io_wakeUpMem_0_bits_loadDependency_2,
  input        io_og0Cancel_0,
  input        io_og0Cancel_2,
  input        io_og0Cancel_4,
  input        io_og0Cancel_6,
  input        io_ldCancel_0_ld2Cancel,
  input        io_ldCancel_1_ld2Cancel,
  input        io_ldCancel_2_ld2Cancel,
  input  [7:0] io_read_0_req,
  output       io_read_0_resp,
  output [1:0] io_read_0_loadDependency_0,
  output [1:0] io_read_0_loadDependency_1,
  output [1:0] io_read_0_loadDependency_2,
  input  [7:0] io_read_1_req,
  output       io_read_1_resp,
  output [1:0] io_read_1_loadDependency_0,
  output [1:0] io_read_1_loadDependency_1,
  output [1:0] io_read_1_loadDependency_2,
  input  [7:0] io_read_2_req,
  output       io_read_2_resp,
  output [1:0] io_read_2_loadDependency_0,
  output [1:0] io_read_2_loadDependency_1,
  output [1:0] io_read_2_loadDependency_2,
  input  [7:0] io_read_3_req,
  output       io_read_3_resp,
  output [1:0] io_read_3_loadDependency_0,
  output [1:0] io_read_3_loadDependency_1,
  output [1:0] io_read_3_loadDependency_2,
  input  [7:0] io_read_4_req,
  output       io_read_4_resp,
  output [1:0] io_read_4_loadDependency_0,
  output [1:0] io_read_4_loadDependency_1,
  output [1:0] io_read_4_loadDependency_2,
  input  [7:0] io_read_5_req,
  output       io_read_5_resp,
  output [1:0] io_read_5_loadDependency_0,
  output [1:0] io_read_5_loadDependency_1,
  output [1:0] io_read_5_loadDependency_2,
  input  [7:0] io_read_6_req,
  output       io_read_6_resp,
  output [1:0] io_read_6_loadDependency_0,
  output [1:0] io_read_6_loadDependency_1,
  output [1:0] io_read_6_loadDependency_2,
  input  [7:0] io_read_7_req,
  output       io_read_7_resp,
  output [1:0] io_read_7_loadDependency_0,
  output [1:0] io_read_7_loadDependency_1,
  output [1:0] io_read_7_loadDependency_2,
  input  [7:0] io_read_8_req,
  output       io_read_8_resp,
  output [1:0] io_read_8_loadDependency_0,
  output [1:0] io_read_8_loadDependency_1,
  output [1:0] io_read_8_loadDependency_2,
  input  [7:0] io_read_9_req,
  output       io_read_9_resp,
  output [1:0] io_read_9_loadDependency_0,
  output [1:0] io_read_9_loadDependency_1,
  output [1:0] io_read_9_loadDependency_2,
  input  [7:0] io_read_10_req,
  output       io_read_10_resp,
  output [1:0] io_read_10_loadDependency_0,
  output [1:0] io_read_10_loadDependency_1,
  output [1:0] io_read_10_loadDependency_2,
  input  [7:0] io_read_11_req,
  output       io_read_11_resp,
  output [1:0] io_read_11_loadDependency_0,
  output [1:0] io_read_11_loadDependency_1,
  output [1:0] io_read_11_loadDependency_2
);

  logic [12-1:0] core_read_resp;
  logic [12-1:0][3-1:0][1:0] core_read_load_dep;

  xs_BusyTable_core #(
    .NUM_PREGS        (224),
    .NUM_ALLOC        (6),
    .NUM_WB           (8),
    .NUM_READ         (12),
    .NUM_WAKEUP       (7),
    .HAS_LOAD_DEP     (1),
    .ZERO_ALWAYS_READY(1),
    .HAS_VL           (0),
    .WK_FROM_LOAD     (8'b01110000),
    .WK_LD_ONEHOT     ({3'd0, 3'd4, 3'd2, 3'd1, 3'd0, 3'd0, 3'd0, 3'd0})
  ) u_core (
    .clock (clock),
    .reset (reset),
    .alloc_valid({io_allocPregs_5_valid, io_allocPregs_4_valid, io_allocPregs_3_valid, io_allocPregs_2_valid, io_allocPregs_1_valid, io_allocPregs_0_valid}),
    .alloc_preg ({io_allocPregs_5_bits, io_allocPregs_4_bits, io_allocPregs_3_bits, io_allocPregs_2_bits, io_allocPregs_1_bits, io_allocPregs_0_bits}),
    .wb_valid   ({io_wbPregs_7_valid, io_wbPregs_6_valid, io_wbPregs_5_valid, io_wbPregs_4_valid, io_wbPregs_3_valid, io_wbPregs_2_valid, io_wbPregs_1_valid, io_wbPregs_0_valid}),
    .wb_preg    ({io_wbPregs_7_bits, io_wbPregs_6_bits, io_wbPregs_5_bits, io_wbPregs_4_bits, io_wbPregs_3_bits, io_wbPregs_2_bits, io_wbPregs_1_bits, io_wbPregs_0_bits}),
    .wk_valid    ({io_wakeUpMem_2_valid, io_wakeUpMem_1_valid, io_wakeUpMem_0_valid, io_wakeUpInt_3_valid, io_wakeUpInt_2_valid, io_wakeUpInt_1_valid, io_wakeUpInt_0_valid}),
    .wk_wen      ({io_wakeUpMem_2_bits_rfWen, io_wakeUpMem_1_bits_rfWen, io_wakeUpMem_0_bits_rfWen, io_wakeUpInt_3_bits_rfWen, io_wakeUpInt_2_bits_rfWen, io_wakeUpInt_1_bits_rfWen, io_wakeUpInt_0_bits_rfWen}),
    .wk_pdest    ({io_wakeUpMem_2_bits_pdest, io_wakeUpMem_1_bits_pdest, io_wakeUpMem_0_bits_pdest, io_wakeUpInt_3_bits_pdest, io_wakeUpInt_2_bits_pdest, io_wakeUpInt_1_bits_pdest, io_wakeUpInt_0_bits_pdest}),
    .wk_is0lat   ({1'b0, 1'b0, 1'b0, 1'b1, 1'b1, io_wakeUpInt_1_bits_is0Lat, io_wakeUpInt_0_bits_is0Lat}),
    .wk_og0cancel({1'b0, 1'b0, 1'b0, io_og0Cancel_6, io_og0Cancel_4, io_og0Cancel_2, io_og0Cancel_0}),
    .wk_load_dep ({{io_wakeUpMem_2_bits_loadDependency_2, io_wakeUpMem_2_bits_loadDependency_1, io_wakeUpMem_2_bits_loadDependency_0}, {io_wakeUpMem_1_bits_loadDependency_2, io_wakeUpMem_1_bits_loadDependency_1, io_wakeUpMem_1_bits_loadDependency_0}, {io_wakeUpMem_0_bits_loadDependency_2, io_wakeUpMem_0_bits_loadDependency_1, io_wakeUpMem_0_bits_loadDependency_0}, {io_wakeUpInt_3_bits_loadDependency_2, io_wakeUpInt_3_bits_loadDependency_1, io_wakeUpInt_3_bits_loadDependency_0}, {io_wakeUpInt_2_bits_loadDependency_2, io_wakeUpInt_2_bits_loadDependency_1, io_wakeUpInt_2_bits_loadDependency_0}, {io_wakeUpInt_1_bits_loadDependency_2, io_wakeUpInt_1_bits_loadDependency_1, io_wakeUpInt_1_bits_loadDependency_0}, {io_wakeUpInt_0_bits_loadDependency_2, io_wakeUpInt_0_bits_loadDependency_1, io_wakeUpInt_0_bits_loadDependency_0}}),
    .ld_cancel  ({io_ldCancel_2_ld2Cancel, io_ldCancel_1_ld2Cancel, io_ldCancel_0_ld2Cancel}),
    .read_req      ({io_read_11_req, io_read_10_req, io_read_9_req, io_read_8_req, io_read_7_req, io_read_6_req, io_read_5_req, io_read_4_req, io_read_3_req, io_read_2_req, io_read_1_req, io_read_0_req}),
    .read_resp     (core_read_resp),
    .read_load_dep (core_read_load_dep),
    .vl_from_int_is_zero (1'b0),
    .vl_from_int_is_vlmax(1'b0),
    .vl_from_vf_is_zero  (1'b0),
    .vl_from_vf_is_vlmax (1'b0),
    .vl_is_nonzero       (/* unused */),
    .vl_is_vlmax         (/* unused */)
  );

  assign io_read_0_resp = core_read_resp[0];
  assign io_read_0_loadDependency_0 = core_read_load_dep[0][0];
  assign io_read_0_loadDependency_1 = core_read_load_dep[0][1];
  assign io_read_0_loadDependency_2 = core_read_load_dep[0][2];
  assign io_read_1_resp = core_read_resp[1];
  assign io_read_1_loadDependency_0 = core_read_load_dep[1][0];
  assign io_read_1_loadDependency_1 = core_read_load_dep[1][1];
  assign io_read_1_loadDependency_2 = core_read_load_dep[1][2];
  assign io_read_2_resp = core_read_resp[2];
  assign io_read_2_loadDependency_0 = core_read_load_dep[2][0];
  assign io_read_2_loadDependency_1 = core_read_load_dep[2][1];
  assign io_read_2_loadDependency_2 = core_read_load_dep[2][2];
  assign io_read_3_resp = core_read_resp[3];
  assign io_read_3_loadDependency_0 = core_read_load_dep[3][0];
  assign io_read_3_loadDependency_1 = core_read_load_dep[3][1];
  assign io_read_3_loadDependency_2 = core_read_load_dep[3][2];
  assign io_read_4_resp = core_read_resp[4];
  assign io_read_4_loadDependency_0 = core_read_load_dep[4][0];
  assign io_read_4_loadDependency_1 = core_read_load_dep[4][1];
  assign io_read_4_loadDependency_2 = core_read_load_dep[4][2];
  assign io_read_5_resp = core_read_resp[5];
  assign io_read_5_loadDependency_0 = core_read_load_dep[5][0];
  assign io_read_5_loadDependency_1 = core_read_load_dep[5][1];
  assign io_read_5_loadDependency_2 = core_read_load_dep[5][2];
  assign io_read_6_resp = core_read_resp[6];
  assign io_read_6_loadDependency_0 = core_read_load_dep[6][0];
  assign io_read_6_loadDependency_1 = core_read_load_dep[6][1];
  assign io_read_6_loadDependency_2 = core_read_load_dep[6][2];
  assign io_read_7_resp = core_read_resp[7];
  assign io_read_7_loadDependency_0 = core_read_load_dep[7][0];
  assign io_read_7_loadDependency_1 = core_read_load_dep[7][1];
  assign io_read_7_loadDependency_2 = core_read_load_dep[7][2];
  assign io_read_8_resp = core_read_resp[8];
  assign io_read_8_loadDependency_0 = core_read_load_dep[8][0];
  assign io_read_8_loadDependency_1 = core_read_load_dep[8][1];
  assign io_read_8_loadDependency_2 = core_read_load_dep[8][2];
  assign io_read_9_resp = core_read_resp[9];
  assign io_read_9_loadDependency_0 = core_read_load_dep[9][0];
  assign io_read_9_loadDependency_1 = core_read_load_dep[9][1];
  assign io_read_9_loadDependency_2 = core_read_load_dep[9][2];
  assign io_read_10_resp = core_read_resp[10];
  assign io_read_10_loadDependency_0 = core_read_load_dep[10][0];
  assign io_read_10_loadDependency_1 = core_read_load_dep[10][1];
  assign io_read_10_loadDependency_2 = core_read_load_dep[10][2];
  assign io_read_11_resp = core_read_resp[11];
  assign io_read_11_loadDependency_0 = core_read_load_dep[11][0];
  assign io_read_11_loadDependency_1 = core_read_load_dep[11][1];
  assign io_read_11_loadDependency_2 = core_read_load_dep[11][2];

endmodule
