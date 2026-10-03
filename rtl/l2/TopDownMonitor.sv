// =============================================================================
// TopDownMonitor.sv —— L2（coupledL2）的 TopDown 性能监视器：判断"ROB 头那条访存是不是正卡在 L2 miss 上"
//
// 位置：TL2CHICoupledL2 顶层，旁路监听 4 个 slice（bank）的 MSHR 状态。唯一的功能输出
//   io_debugTopDown_l2MissMatch 送回核的 TopDown 统计：ROB 头的物理地址（robHeadPaddr，36 位）
//   若正好落在某个"正在 miss"的 MSHR 所处理的 cache 块上，就说明 ROB 被 L2 miss 堵住了。
// 机制：块地址比对（64 B 块）。
//   · ROB 头块地址 = paddr >> 6（30 位）；
//   · MSHR 块地址 = {reqTag(31), set(9), bank(2)}（42 位；bank 号是 slice 下标 i）；
//   · 两者零扩展到同宽相等、MSHR valid 且 is_miss、robHeadPaddr.valid ⇒ 命中；64 个 MSHR 取或。
//   注意 MSHR 块地址比 ROB 头块地址宽 12 位：reqTag 高 12 位非 0 的 MSHR 永远不会命中（照 golden）。
// 其余输入（dirResult / msAlloc / hitPfInMSHR / pfSent / pfLateInMSHR / msStatus 的 channel、
//   is_prefetch，robTrueCommit 已被 firtool 删掉）在 Scala 里只喂 XSPerfAccumulate / XSPerfHistogram /
//   XSPerfRolling 性能计数器；本配置下这些计数器不生成任何硬件（golden 里 0 个寄存器、只剩死线），
//   所以它们在这里不连任何逻辑 —— 端口照 golden 保留。
// Chisel 源：coupledL2/src/main/scala/coupledL2/TopDownMonitor.scala（coupledL2@fb546983）。
// golden 对照：G1-canonical/golden-rtl/TopDownMonitor.sv（无子模块，纯组合）。
// wrapper 由 scripts/gen_topdownmonitor.py 生成（golden 端口表逐字照搬）。
// =============================================================================
module xs_TopDownMonitor_core #(
  parameter int NBANK = 4,         // L2 slice 数（bankBits = 2）
  parameter int NMSHR = 16         // 每个 slice 的 MSHR 数
) (
  input  logic                             rob_head_valid,
  input  logic [35:0]                      rob_head_paddr,
  input  logic [NBANK-1:0][NMSHR-1:0]       ms_valid,
  input  logic [NBANK-1:0][NMSHR-1:0]       ms_is_miss,
  input  logic [NBANK-1:0][NMSHR-1:0][8:0]  ms_set,
  input  logic [NBANK-1:0][NMSHR-1:0][30:0] ms_req_tag,
  output logic                             l2_miss_match
);
  logic [29:0] rob_head_block;     // ROB 头所在 64 B 块
  assign rob_head_block = rob_head_paddr[35:6];

  always_comb begin
    l2_miss_match = 1'b0;
    for (int b = 0; b < NBANK; b++) begin
      for (int m = 0; m < NMSHR; m++) begin
        logic [41:0] ms_block;     // MSHR 处理的块：{tag, set, bank}
        ms_block = {ms_req_tag[b][m], ms_set[b][m], 2'(b)};
        if (rob_head_valid && ms_valid[b][m] && ms_is_miss[b][m] && (ms_block == 42'(rob_head_block)))
          l2_miss_match = 1'b1;
      end
    end
  end
endmodule

// BEGIN GENERATED(tdm-wrapper)
module TopDownMonitor (
  input         io_dirResult_0_valid,
  input         io_dirResult_0_bits_hit,
  input         io_dirResult_0_bits_meta_prefetch,
  input  [2:0]  io_dirResult_0_bits_meta_prefetchSrc,
  input  [2:0]  io_dirResult_0_bits_replacerInfo_channel,
  input  [4:0]  io_dirResult_0_bits_replacerInfo_reqSource,
  input         io_dirResult_1_valid,
  input         io_dirResult_1_bits_hit,
  input         io_dirResult_1_bits_meta_prefetch,
  input  [2:0]  io_dirResult_1_bits_meta_prefetchSrc,
  input  [2:0]  io_dirResult_1_bits_replacerInfo_channel,
  input  [4:0]  io_dirResult_1_bits_replacerInfo_reqSource,
  input         io_dirResult_2_valid,
  input         io_dirResult_2_bits_hit,
  input         io_dirResult_2_bits_meta_prefetch,
  input  [2:0]  io_dirResult_2_bits_meta_prefetchSrc,
  input  [2:0]  io_dirResult_2_bits_replacerInfo_channel,
  input  [4:0]  io_dirResult_2_bits_replacerInfo_reqSource,
  input         io_dirResult_3_valid,
  input         io_dirResult_3_bits_hit,
  input         io_dirResult_3_bits_meta_prefetch,
  input  [2:0]  io_dirResult_3_bits_meta_prefetchSrc,
  input  [2:0]  io_dirResult_3_bits_replacerInfo_channel,
  input  [4:0]  io_dirResult_3_bits_replacerInfo_reqSource,
  input         io_msStatus_0_0_valid,
  input  [2:0]  io_msStatus_0_0_bits_channel,
  input  [8:0]  io_msStatus_0_0_bits_set,
  input  [30:0] io_msStatus_0_0_bits_reqTag,
  input         io_msStatus_0_0_bits_is_miss,
  input         io_msStatus_0_0_bits_is_prefetch,
  input         io_msStatus_0_1_valid,
  input  [2:0]  io_msStatus_0_1_bits_channel,
  input  [8:0]  io_msStatus_0_1_bits_set,
  input  [30:0] io_msStatus_0_1_bits_reqTag,
  input         io_msStatus_0_1_bits_is_miss,
  input         io_msStatus_0_1_bits_is_prefetch,
  input         io_msStatus_0_2_valid,
  input  [2:0]  io_msStatus_0_2_bits_channel,
  input  [8:0]  io_msStatus_0_2_bits_set,
  input  [30:0] io_msStatus_0_2_bits_reqTag,
  input         io_msStatus_0_2_bits_is_miss,
  input         io_msStatus_0_2_bits_is_prefetch,
  input         io_msStatus_0_3_valid,
  input  [2:0]  io_msStatus_0_3_bits_channel,
  input  [8:0]  io_msStatus_0_3_bits_set,
  input  [30:0] io_msStatus_0_3_bits_reqTag,
  input         io_msStatus_0_3_bits_is_miss,
  input         io_msStatus_0_3_bits_is_prefetch,
  input         io_msStatus_0_4_valid,
  input  [2:0]  io_msStatus_0_4_bits_channel,
  input  [8:0]  io_msStatus_0_4_bits_set,
  input  [30:0] io_msStatus_0_4_bits_reqTag,
  input         io_msStatus_0_4_bits_is_miss,
  input         io_msStatus_0_4_bits_is_prefetch,
  input         io_msStatus_0_5_valid,
  input  [2:0]  io_msStatus_0_5_bits_channel,
  input  [8:0]  io_msStatus_0_5_bits_set,
  input  [30:0] io_msStatus_0_5_bits_reqTag,
  input         io_msStatus_0_5_bits_is_miss,
  input         io_msStatus_0_5_bits_is_prefetch,
  input         io_msStatus_0_6_valid,
  input  [2:0]  io_msStatus_0_6_bits_channel,
  input  [8:0]  io_msStatus_0_6_bits_set,
  input  [30:0] io_msStatus_0_6_bits_reqTag,
  input         io_msStatus_0_6_bits_is_miss,
  input         io_msStatus_0_6_bits_is_prefetch,
  input         io_msStatus_0_7_valid,
  input  [2:0]  io_msStatus_0_7_bits_channel,
  input  [8:0]  io_msStatus_0_7_bits_set,
  input  [30:0] io_msStatus_0_7_bits_reqTag,
  input         io_msStatus_0_7_bits_is_miss,
  input         io_msStatus_0_7_bits_is_prefetch,
  input         io_msStatus_0_8_valid,
  input  [2:0]  io_msStatus_0_8_bits_channel,
  input  [8:0]  io_msStatus_0_8_bits_set,
  input  [30:0] io_msStatus_0_8_bits_reqTag,
  input         io_msStatus_0_8_bits_is_miss,
  input         io_msStatus_0_8_bits_is_prefetch,
  input         io_msStatus_0_9_valid,
  input  [2:0]  io_msStatus_0_9_bits_channel,
  input  [8:0]  io_msStatus_0_9_bits_set,
  input  [30:0] io_msStatus_0_9_bits_reqTag,
  input         io_msStatus_0_9_bits_is_miss,
  input         io_msStatus_0_9_bits_is_prefetch,
  input         io_msStatus_0_10_valid,
  input  [2:0]  io_msStatus_0_10_bits_channel,
  input  [8:0]  io_msStatus_0_10_bits_set,
  input  [30:0] io_msStatus_0_10_bits_reqTag,
  input         io_msStatus_0_10_bits_is_miss,
  input         io_msStatus_0_10_bits_is_prefetch,
  input         io_msStatus_0_11_valid,
  input  [2:0]  io_msStatus_0_11_bits_channel,
  input  [8:0]  io_msStatus_0_11_bits_set,
  input  [30:0] io_msStatus_0_11_bits_reqTag,
  input         io_msStatus_0_11_bits_is_miss,
  input         io_msStatus_0_11_bits_is_prefetch,
  input         io_msStatus_0_12_valid,
  input  [2:0]  io_msStatus_0_12_bits_channel,
  input  [8:0]  io_msStatus_0_12_bits_set,
  input  [30:0] io_msStatus_0_12_bits_reqTag,
  input         io_msStatus_0_12_bits_is_miss,
  input         io_msStatus_0_12_bits_is_prefetch,
  input         io_msStatus_0_13_valid,
  input  [2:0]  io_msStatus_0_13_bits_channel,
  input  [8:0]  io_msStatus_0_13_bits_set,
  input  [30:0] io_msStatus_0_13_bits_reqTag,
  input         io_msStatus_0_13_bits_is_miss,
  input         io_msStatus_0_13_bits_is_prefetch,
  input         io_msStatus_0_14_valid,
  input  [2:0]  io_msStatus_0_14_bits_channel,
  input  [8:0]  io_msStatus_0_14_bits_set,
  input  [30:0] io_msStatus_0_14_bits_reqTag,
  input         io_msStatus_0_14_bits_is_miss,
  input         io_msStatus_0_14_bits_is_prefetch,
  input         io_msStatus_0_15_valid,
  input  [2:0]  io_msStatus_0_15_bits_channel,
  input  [8:0]  io_msStatus_0_15_bits_set,
  input  [30:0] io_msStatus_0_15_bits_reqTag,
  input         io_msStatus_0_15_bits_is_miss,
  input         io_msStatus_0_15_bits_is_prefetch,
  input         io_msStatus_1_0_valid,
  input  [2:0]  io_msStatus_1_0_bits_channel,
  input  [8:0]  io_msStatus_1_0_bits_set,
  input  [30:0] io_msStatus_1_0_bits_reqTag,
  input         io_msStatus_1_0_bits_is_miss,
  input         io_msStatus_1_0_bits_is_prefetch,
  input         io_msStatus_1_1_valid,
  input  [2:0]  io_msStatus_1_1_bits_channel,
  input  [8:0]  io_msStatus_1_1_bits_set,
  input  [30:0] io_msStatus_1_1_bits_reqTag,
  input         io_msStatus_1_1_bits_is_miss,
  input         io_msStatus_1_1_bits_is_prefetch,
  input         io_msStatus_1_2_valid,
  input  [2:0]  io_msStatus_1_2_bits_channel,
  input  [8:0]  io_msStatus_1_2_bits_set,
  input  [30:0] io_msStatus_1_2_bits_reqTag,
  input         io_msStatus_1_2_bits_is_miss,
  input         io_msStatus_1_2_bits_is_prefetch,
  input         io_msStatus_1_3_valid,
  input  [2:0]  io_msStatus_1_3_bits_channel,
  input  [8:0]  io_msStatus_1_3_bits_set,
  input  [30:0] io_msStatus_1_3_bits_reqTag,
  input         io_msStatus_1_3_bits_is_miss,
  input         io_msStatus_1_3_bits_is_prefetch,
  input         io_msStatus_1_4_valid,
  input  [2:0]  io_msStatus_1_4_bits_channel,
  input  [8:0]  io_msStatus_1_4_bits_set,
  input  [30:0] io_msStatus_1_4_bits_reqTag,
  input         io_msStatus_1_4_bits_is_miss,
  input         io_msStatus_1_4_bits_is_prefetch,
  input         io_msStatus_1_5_valid,
  input  [2:0]  io_msStatus_1_5_bits_channel,
  input  [8:0]  io_msStatus_1_5_bits_set,
  input  [30:0] io_msStatus_1_5_bits_reqTag,
  input         io_msStatus_1_5_bits_is_miss,
  input         io_msStatus_1_5_bits_is_prefetch,
  input         io_msStatus_1_6_valid,
  input  [2:0]  io_msStatus_1_6_bits_channel,
  input  [8:0]  io_msStatus_1_6_bits_set,
  input  [30:0] io_msStatus_1_6_bits_reqTag,
  input         io_msStatus_1_6_bits_is_miss,
  input         io_msStatus_1_6_bits_is_prefetch,
  input         io_msStatus_1_7_valid,
  input  [2:0]  io_msStatus_1_7_bits_channel,
  input  [8:0]  io_msStatus_1_7_bits_set,
  input  [30:0] io_msStatus_1_7_bits_reqTag,
  input         io_msStatus_1_7_bits_is_miss,
  input         io_msStatus_1_7_bits_is_prefetch,
  input         io_msStatus_1_8_valid,
  input  [2:0]  io_msStatus_1_8_bits_channel,
  input  [8:0]  io_msStatus_1_8_bits_set,
  input  [30:0] io_msStatus_1_8_bits_reqTag,
  input         io_msStatus_1_8_bits_is_miss,
  input         io_msStatus_1_8_bits_is_prefetch,
  input         io_msStatus_1_9_valid,
  input  [2:0]  io_msStatus_1_9_bits_channel,
  input  [8:0]  io_msStatus_1_9_bits_set,
  input  [30:0] io_msStatus_1_9_bits_reqTag,
  input         io_msStatus_1_9_bits_is_miss,
  input         io_msStatus_1_9_bits_is_prefetch,
  input         io_msStatus_1_10_valid,
  input  [2:0]  io_msStatus_1_10_bits_channel,
  input  [8:0]  io_msStatus_1_10_bits_set,
  input  [30:0] io_msStatus_1_10_bits_reqTag,
  input         io_msStatus_1_10_bits_is_miss,
  input         io_msStatus_1_10_bits_is_prefetch,
  input         io_msStatus_1_11_valid,
  input  [2:0]  io_msStatus_1_11_bits_channel,
  input  [8:0]  io_msStatus_1_11_bits_set,
  input  [30:0] io_msStatus_1_11_bits_reqTag,
  input         io_msStatus_1_11_bits_is_miss,
  input         io_msStatus_1_11_bits_is_prefetch,
  input         io_msStatus_1_12_valid,
  input  [2:0]  io_msStatus_1_12_bits_channel,
  input  [8:0]  io_msStatus_1_12_bits_set,
  input  [30:0] io_msStatus_1_12_bits_reqTag,
  input         io_msStatus_1_12_bits_is_miss,
  input         io_msStatus_1_12_bits_is_prefetch,
  input         io_msStatus_1_13_valid,
  input  [2:0]  io_msStatus_1_13_bits_channel,
  input  [8:0]  io_msStatus_1_13_bits_set,
  input  [30:0] io_msStatus_1_13_bits_reqTag,
  input         io_msStatus_1_13_bits_is_miss,
  input         io_msStatus_1_13_bits_is_prefetch,
  input         io_msStatus_1_14_valid,
  input  [2:0]  io_msStatus_1_14_bits_channel,
  input  [8:0]  io_msStatus_1_14_bits_set,
  input  [30:0] io_msStatus_1_14_bits_reqTag,
  input         io_msStatus_1_14_bits_is_miss,
  input         io_msStatus_1_14_bits_is_prefetch,
  input         io_msStatus_1_15_valid,
  input  [2:0]  io_msStatus_1_15_bits_channel,
  input  [8:0]  io_msStatus_1_15_bits_set,
  input  [30:0] io_msStatus_1_15_bits_reqTag,
  input         io_msStatus_1_15_bits_is_miss,
  input         io_msStatus_1_15_bits_is_prefetch,
  input         io_msStatus_2_0_valid,
  input  [2:0]  io_msStatus_2_0_bits_channel,
  input  [8:0]  io_msStatus_2_0_bits_set,
  input  [30:0] io_msStatus_2_0_bits_reqTag,
  input         io_msStatus_2_0_bits_is_miss,
  input         io_msStatus_2_0_bits_is_prefetch,
  input         io_msStatus_2_1_valid,
  input  [2:0]  io_msStatus_2_1_bits_channel,
  input  [8:0]  io_msStatus_2_1_bits_set,
  input  [30:0] io_msStatus_2_1_bits_reqTag,
  input         io_msStatus_2_1_bits_is_miss,
  input         io_msStatus_2_1_bits_is_prefetch,
  input         io_msStatus_2_2_valid,
  input  [2:0]  io_msStatus_2_2_bits_channel,
  input  [8:0]  io_msStatus_2_2_bits_set,
  input  [30:0] io_msStatus_2_2_bits_reqTag,
  input         io_msStatus_2_2_bits_is_miss,
  input         io_msStatus_2_2_bits_is_prefetch,
  input         io_msStatus_2_3_valid,
  input  [2:0]  io_msStatus_2_3_bits_channel,
  input  [8:0]  io_msStatus_2_3_bits_set,
  input  [30:0] io_msStatus_2_3_bits_reqTag,
  input         io_msStatus_2_3_bits_is_miss,
  input         io_msStatus_2_3_bits_is_prefetch,
  input         io_msStatus_2_4_valid,
  input  [2:0]  io_msStatus_2_4_bits_channel,
  input  [8:0]  io_msStatus_2_4_bits_set,
  input  [30:0] io_msStatus_2_4_bits_reqTag,
  input         io_msStatus_2_4_bits_is_miss,
  input         io_msStatus_2_4_bits_is_prefetch,
  input         io_msStatus_2_5_valid,
  input  [2:0]  io_msStatus_2_5_bits_channel,
  input  [8:0]  io_msStatus_2_5_bits_set,
  input  [30:0] io_msStatus_2_5_bits_reqTag,
  input         io_msStatus_2_5_bits_is_miss,
  input         io_msStatus_2_5_bits_is_prefetch,
  input         io_msStatus_2_6_valid,
  input  [2:0]  io_msStatus_2_6_bits_channel,
  input  [8:0]  io_msStatus_2_6_bits_set,
  input  [30:0] io_msStatus_2_6_bits_reqTag,
  input         io_msStatus_2_6_bits_is_miss,
  input         io_msStatus_2_6_bits_is_prefetch,
  input         io_msStatus_2_7_valid,
  input  [2:0]  io_msStatus_2_7_bits_channel,
  input  [8:0]  io_msStatus_2_7_bits_set,
  input  [30:0] io_msStatus_2_7_bits_reqTag,
  input         io_msStatus_2_7_bits_is_miss,
  input         io_msStatus_2_7_bits_is_prefetch,
  input         io_msStatus_2_8_valid,
  input  [2:0]  io_msStatus_2_8_bits_channel,
  input  [8:0]  io_msStatus_2_8_bits_set,
  input  [30:0] io_msStatus_2_8_bits_reqTag,
  input         io_msStatus_2_8_bits_is_miss,
  input         io_msStatus_2_8_bits_is_prefetch,
  input         io_msStatus_2_9_valid,
  input  [2:0]  io_msStatus_2_9_bits_channel,
  input  [8:0]  io_msStatus_2_9_bits_set,
  input  [30:0] io_msStatus_2_9_bits_reqTag,
  input         io_msStatus_2_9_bits_is_miss,
  input         io_msStatus_2_9_bits_is_prefetch,
  input         io_msStatus_2_10_valid,
  input  [2:0]  io_msStatus_2_10_bits_channel,
  input  [8:0]  io_msStatus_2_10_bits_set,
  input  [30:0] io_msStatus_2_10_bits_reqTag,
  input         io_msStatus_2_10_bits_is_miss,
  input         io_msStatus_2_10_bits_is_prefetch,
  input         io_msStatus_2_11_valid,
  input  [2:0]  io_msStatus_2_11_bits_channel,
  input  [8:0]  io_msStatus_2_11_bits_set,
  input  [30:0] io_msStatus_2_11_bits_reqTag,
  input         io_msStatus_2_11_bits_is_miss,
  input         io_msStatus_2_11_bits_is_prefetch,
  input         io_msStatus_2_12_valid,
  input  [2:0]  io_msStatus_2_12_bits_channel,
  input  [8:0]  io_msStatus_2_12_bits_set,
  input  [30:0] io_msStatus_2_12_bits_reqTag,
  input         io_msStatus_2_12_bits_is_miss,
  input         io_msStatus_2_12_bits_is_prefetch,
  input         io_msStatus_2_13_valid,
  input  [2:0]  io_msStatus_2_13_bits_channel,
  input  [8:0]  io_msStatus_2_13_bits_set,
  input  [30:0] io_msStatus_2_13_bits_reqTag,
  input         io_msStatus_2_13_bits_is_miss,
  input         io_msStatus_2_13_bits_is_prefetch,
  input         io_msStatus_2_14_valid,
  input  [2:0]  io_msStatus_2_14_bits_channel,
  input  [8:0]  io_msStatus_2_14_bits_set,
  input  [30:0] io_msStatus_2_14_bits_reqTag,
  input         io_msStatus_2_14_bits_is_miss,
  input         io_msStatus_2_14_bits_is_prefetch,
  input         io_msStatus_2_15_valid,
  input  [2:0]  io_msStatus_2_15_bits_channel,
  input  [8:0]  io_msStatus_2_15_bits_set,
  input  [30:0] io_msStatus_2_15_bits_reqTag,
  input         io_msStatus_2_15_bits_is_miss,
  input         io_msStatus_2_15_bits_is_prefetch,
  input         io_msStatus_3_0_valid,
  input  [2:0]  io_msStatus_3_0_bits_channel,
  input  [8:0]  io_msStatus_3_0_bits_set,
  input  [30:0] io_msStatus_3_0_bits_reqTag,
  input         io_msStatus_3_0_bits_is_miss,
  input         io_msStatus_3_0_bits_is_prefetch,
  input         io_msStatus_3_1_valid,
  input  [2:0]  io_msStatus_3_1_bits_channel,
  input  [8:0]  io_msStatus_3_1_bits_set,
  input  [30:0] io_msStatus_3_1_bits_reqTag,
  input         io_msStatus_3_1_bits_is_miss,
  input         io_msStatus_3_1_bits_is_prefetch,
  input         io_msStatus_3_2_valid,
  input  [2:0]  io_msStatus_3_2_bits_channel,
  input  [8:0]  io_msStatus_3_2_bits_set,
  input  [30:0] io_msStatus_3_2_bits_reqTag,
  input         io_msStatus_3_2_bits_is_miss,
  input         io_msStatus_3_2_bits_is_prefetch,
  input         io_msStatus_3_3_valid,
  input  [2:0]  io_msStatus_3_3_bits_channel,
  input  [8:0]  io_msStatus_3_3_bits_set,
  input  [30:0] io_msStatus_3_3_bits_reqTag,
  input         io_msStatus_3_3_bits_is_miss,
  input         io_msStatus_3_3_bits_is_prefetch,
  input         io_msStatus_3_4_valid,
  input  [2:0]  io_msStatus_3_4_bits_channel,
  input  [8:0]  io_msStatus_3_4_bits_set,
  input  [30:0] io_msStatus_3_4_bits_reqTag,
  input         io_msStatus_3_4_bits_is_miss,
  input         io_msStatus_3_4_bits_is_prefetch,
  input         io_msStatus_3_5_valid,
  input  [2:0]  io_msStatus_3_5_bits_channel,
  input  [8:0]  io_msStatus_3_5_bits_set,
  input  [30:0] io_msStatus_3_5_bits_reqTag,
  input         io_msStatus_3_5_bits_is_miss,
  input         io_msStatus_3_5_bits_is_prefetch,
  input         io_msStatus_3_6_valid,
  input  [2:0]  io_msStatus_3_6_bits_channel,
  input  [8:0]  io_msStatus_3_6_bits_set,
  input  [30:0] io_msStatus_3_6_bits_reqTag,
  input         io_msStatus_3_6_bits_is_miss,
  input         io_msStatus_3_6_bits_is_prefetch,
  input         io_msStatus_3_7_valid,
  input  [2:0]  io_msStatus_3_7_bits_channel,
  input  [8:0]  io_msStatus_3_7_bits_set,
  input  [30:0] io_msStatus_3_7_bits_reqTag,
  input         io_msStatus_3_7_bits_is_miss,
  input         io_msStatus_3_7_bits_is_prefetch,
  input         io_msStatus_3_8_valid,
  input  [2:0]  io_msStatus_3_8_bits_channel,
  input  [8:0]  io_msStatus_3_8_bits_set,
  input  [30:0] io_msStatus_3_8_bits_reqTag,
  input         io_msStatus_3_8_bits_is_miss,
  input         io_msStatus_3_8_bits_is_prefetch,
  input         io_msStatus_3_9_valid,
  input  [2:0]  io_msStatus_3_9_bits_channel,
  input  [8:0]  io_msStatus_3_9_bits_set,
  input  [30:0] io_msStatus_3_9_bits_reqTag,
  input         io_msStatus_3_9_bits_is_miss,
  input         io_msStatus_3_9_bits_is_prefetch,
  input         io_msStatus_3_10_valid,
  input  [2:0]  io_msStatus_3_10_bits_channel,
  input  [8:0]  io_msStatus_3_10_bits_set,
  input  [30:0] io_msStatus_3_10_bits_reqTag,
  input         io_msStatus_3_10_bits_is_miss,
  input         io_msStatus_3_10_bits_is_prefetch,
  input         io_msStatus_3_11_valid,
  input  [2:0]  io_msStatus_3_11_bits_channel,
  input  [8:0]  io_msStatus_3_11_bits_set,
  input  [30:0] io_msStatus_3_11_bits_reqTag,
  input         io_msStatus_3_11_bits_is_miss,
  input         io_msStatus_3_11_bits_is_prefetch,
  input         io_msStatus_3_12_valid,
  input  [2:0]  io_msStatus_3_12_bits_channel,
  input  [8:0]  io_msStatus_3_12_bits_set,
  input  [30:0] io_msStatus_3_12_bits_reqTag,
  input         io_msStatus_3_12_bits_is_miss,
  input         io_msStatus_3_12_bits_is_prefetch,
  input         io_msStatus_3_13_valid,
  input  [2:0]  io_msStatus_3_13_bits_channel,
  input  [8:0]  io_msStatus_3_13_bits_set,
  input  [30:0] io_msStatus_3_13_bits_reqTag,
  input         io_msStatus_3_13_bits_is_miss,
  input         io_msStatus_3_13_bits_is_prefetch,
  input         io_msStatus_3_14_valid,
  input  [2:0]  io_msStatus_3_14_bits_channel,
  input  [8:0]  io_msStatus_3_14_bits_set,
  input  [30:0] io_msStatus_3_14_bits_reqTag,
  input         io_msStatus_3_14_bits_is_miss,
  input         io_msStatus_3_14_bits_is_prefetch,
  input         io_msStatus_3_15_valid,
  input  [2:0]  io_msStatus_3_15_bits_channel,
  input  [8:0]  io_msStatus_3_15_bits_set,
  input  [30:0] io_msStatus_3_15_bits_reqTag,
  input         io_msStatus_3_15_bits_is_miss,
  input         io_msStatus_3_15_bits_is_prefetch,
  input         io_msAlloc_0_0_valid,
  input  [2:0]  io_msAlloc_0_0_bits_channel,
  input         io_msAlloc_0_0_bits_is_miss,
  input         io_msAlloc_0_0_bits_is_prefetch,
  input         io_msAlloc_0_1_valid,
  input  [2:0]  io_msAlloc_0_1_bits_channel,
  input         io_msAlloc_0_1_bits_is_miss,
  input         io_msAlloc_0_1_bits_is_prefetch,
  input         io_msAlloc_0_2_valid,
  input  [2:0]  io_msAlloc_0_2_bits_channel,
  input         io_msAlloc_0_2_bits_is_miss,
  input         io_msAlloc_0_2_bits_is_prefetch,
  input         io_msAlloc_0_3_valid,
  input  [2:0]  io_msAlloc_0_3_bits_channel,
  input         io_msAlloc_0_3_bits_is_miss,
  input         io_msAlloc_0_3_bits_is_prefetch,
  input         io_msAlloc_0_4_valid,
  input  [2:0]  io_msAlloc_0_4_bits_channel,
  input         io_msAlloc_0_4_bits_is_miss,
  input         io_msAlloc_0_4_bits_is_prefetch,
  input         io_msAlloc_0_5_valid,
  input  [2:0]  io_msAlloc_0_5_bits_channel,
  input         io_msAlloc_0_5_bits_is_miss,
  input         io_msAlloc_0_5_bits_is_prefetch,
  input         io_msAlloc_0_6_valid,
  input  [2:0]  io_msAlloc_0_6_bits_channel,
  input         io_msAlloc_0_6_bits_is_miss,
  input         io_msAlloc_0_6_bits_is_prefetch,
  input         io_msAlloc_0_7_valid,
  input  [2:0]  io_msAlloc_0_7_bits_channel,
  input         io_msAlloc_0_7_bits_is_miss,
  input         io_msAlloc_0_7_bits_is_prefetch,
  input         io_msAlloc_0_8_valid,
  input  [2:0]  io_msAlloc_0_8_bits_channel,
  input         io_msAlloc_0_8_bits_is_miss,
  input         io_msAlloc_0_8_bits_is_prefetch,
  input         io_msAlloc_0_9_valid,
  input  [2:0]  io_msAlloc_0_9_bits_channel,
  input         io_msAlloc_0_9_bits_is_miss,
  input         io_msAlloc_0_9_bits_is_prefetch,
  input         io_msAlloc_0_10_valid,
  input  [2:0]  io_msAlloc_0_10_bits_channel,
  input         io_msAlloc_0_10_bits_is_miss,
  input         io_msAlloc_0_10_bits_is_prefetch,
  input         io_msAlloc_0_11_valid,
  input  [2:0]  io_msAlloc_0_11_bits_channel,
  input         io_msAlloc_0_11_bits_is_miss,
  input         io_msAlloc_0_11_bits_is_prefetch,
  input         io_msAlloc_0_12_valid,
  input  [2:0]  io_msAlloc_0_12_bits_channel,
  input         io_msAlloc_0_12_bits_is_miss,
  input         io_msAlloc_0_12_bits_is_prefetch,
  input         io_msAlloc_0_13_valid,
  input  [2:0]  io_msAlloc_0_13_bits_channel,
  input         io_msAlloc_0_13_bits_is_miss,
  input         io_msAlloc_0_13_bits_is_prefetch,
  input         io_msAlloc_0_14_valid,
  input  [2:0]  io_msAlloc_0_14_bits_channel,
  input         io_msAlloc_0_14_bits_is_miss,
  input         io_msAlloc_0_14_bits_is_prefetch,
  input         io_msAlloc_0_15_valid,
  input  [2:0]  io_msAlloc_0_15_bits_channel,
  input         io_msAlloc_0_15_bits_is_miss,
  input         io_msAlloc_0_15_bits_is_prefetch,
  input         io_msAlloc_1_0_valid,
  input  [2:0]  io_msAlloc_1_0_bits_channel,
  input         io_msAlloc_1_0_bits_is_miss,
  input         io_msAlloc_1_0_bits_is_prefetch,
  input         io_msAlloc_1_1_valid,
  input  [2:0]  io_msAlloc_1_1_bits_channel,
  input         io_msAlloc_1_1_bits_is_miss,
  input         io_msAlloc_1_1_bits_is_prefetch,
  input         io_msAlloc_1_2_valid,
  input  [2:0]  io_msAlloc_1_2_bits_channel,
  input         io_msAlloc_1_2_bits_is_miss,
  input         io_msAlloc_1_2_bits_is_prefetch,
  input         io_msAlloc_1_3_valid,
  input  [2:0]  io_msAlloc_1_3_bits_channel,
  input         io_msAlloc_1_3_bits_is_miss,
  input         io_msAlloc_1_3_bits_is_prefetch,
  input         io_msAlloc_1_4_valid,
  input  [2:0]  io_msAlloc_1_4_bits_channel,
  input         io_msAlloc_1_4_bits_is_miss,
  input         io_msAlloc_1_4_bits_is_prefetch,
  input         io_msAlloc_1_5_valid,
  input  [2:0]  io_msAlloc_1_5_bits_channel,
  input         io_msAlloc_1_5_bits_is_miss,
  input         io_msAlloc_1_5_bits_is_prefetch,
  input         io_msAlloc_1_6_valid,
  input  [2:0]  io_msAlloc_1_6_bits_channel,
  input         io_msAlloc_1_6_bits_is_miss,
  input         io_msAlloc_1_6_bits_is_prefetch,
  input         io_msAlloc_1_7_valid,
  input  [2:0]  io_msAlloc_1_7_bits_channel,
  input         io_msAlloc_1_7_bits_is_miss,
  input         io_msAlloc_1_7_bits_is_prefetch,
  input         io_msAlloc_1_8_valid,
  input  [2:0]  io_msAlloc_1_8_bits_channel,
  input         io_msAlloc_1_8_bits_is_miss,
  input         io_msAlloc_1_8_bits_is_prefetch,
  input         io_msAlloc_1_9_valid,
  input  [2:0]  io_msAlloc_1_9_bits_channel,
  input         io_msAlloc_1_9_bits_is_miss,
  input         io_msAlloc_1_9_bits_is_prefetch,
  input         io_msAlloc_1_10_valid,
  input  [2:0]  io_msAlloc_1_10_bits_channel,
  input         io_msAlloc_1_10_bits_is_miss,
  input         io_msAlloc_1_10_bits_is_prefetch,
  input         io_msAlloc_1_11_valid,
  input  [2:0]  io_msAlloc_1_11_bits_channel,
  input         io_msAlloc_1_11_bits_is_miss,
  input         io_msAlloc_1_11_bits_is_prefetch,
  input         io_msAlloc_1_12_valid,
  input  [2:0]  io_msAlloc_1_12_bits_channel,
  input         io_msAlloc_1_12_bits_is_miss,
  input         io_msAlloc_1_12_bits_is_prefetch,
  input         io_msAlloc_1_13_valid,
  input  [2:0]  io_msAlloc_1_13_bits_channel,
  input         io_msAlloc_1_13_bits_is_miss,
  input         io_msAlloc_1_13_bits_is_prefetch,
  input         io_msAlloc_1_14_valid,
  input  [2:0]  io_msAlloc_1_14_bits_channel,
  input         io_msAlloc_1_14_bits_is_miss,
  input         io_msAlloc_1_14_bits_is_prefetch,
  input         io_msAlloc_1_15_valid,
  input  [2:0]  io_msAlloc_1_15_bits_channel,
  input         io_msAlloc_1_15_bits_is_miss,
  input         io_msAlloc_1_15_bits_is_prefetch,
  input         io_msAlloc_2_0_valid,
  input  [2:0]  io_msAlloc_2_0_bits_channel,
  input         io_msAlloc_2_0_bits_is_miss,
  input         io_msAlloc_2_0_bits_is_prefetch,
  input         io_msAlloc_2_1_valid,
  input  [2:0]  io_msAlloc_2_1_bits_channel,
  input         io_msAlloc_2_1_bits_is_miss,
  input         io_msAlloc_2_1_bits_is_prefetch,
  input         io_msAlloc_2_2_valid,
  input  [2:0]  io_msAlloc_2_2_bits_channel,
  input         io_msAlloc_2_2_bits_is_miss,
  input         io_msAlloc_2_2_bits_is_prefetch,
  input         io_msAlloc_2_3_valid,
  input  [2:0]  io_msAlloc_2_3_bits_channel,
  input         io_msAlloc_2_3_bits_is_miss,
  input         io_msAlloc_2_3_bits_is_prefetch,
  input         io_msAlloc_2_4_valid,
  input  [2:0]  io_msAlloc_2_4_bits_channel,
  input         io_msAlloc_2_4_bits_is_miss,
  input         io_msAlloc_2_4_bits_is_prefetch,
  input         io_msAlloc_2_5_valid,
  input  [2:0]  io_msAlloc_2_5_bits_channel,
  input         io_msAlloc_2_5_bits_is_miss,
  input         io_msAlloc_2_5_bits_is_prefetch,
  input         io_msAlloc_2_6_valid,
  input  [2:0]  io_msAlloc_2_6_bits_channel,
  input         io_msAlloc_2_6_bits_is_miss,
  input         io_msAlloc_2_6_bits_is_prefetch,
  input         io_msAlloc_2_7_valid,
  input  [2:0]  io_msAlloc_2_7_bits_channel,
  input         io_msAlloc_2_7_bits_is_miss,
  input         io_msAlloc_2_7_bits_is_prefetch,
  input         io_msAlloc_2_8_valid,
  input  [2:0]  io_msAlloc_2_8_bits_channel,
  input         io_msAlloc_2_8_bits_is_miss,
  input         io_msAlloc_2_8_bits_is_prefetch,
  input         io_msAlloc_2_9_valid,
  input  [2:0]  io_msAlloc_2_9_bits_channel,
  input         io_msAlloc_2_9_bits_is_miss,
  input         io_msAlloc_2_9_bits_is_prefetch,
  input         io_msAlloc_2_10_valid,
  input  [2:0]  io_msAlloc_2_10_bits_channel,
  input         io_msAlloc_2_10_bits_is_miss,
  input         io_msAlloc_2_10_bits_is_prefetch,
  input         io_msAlloc_2_11_valid,
  input  [2:0]  io_msAlloc_2_11_bits_channel,
  input         io_msAlloc_2_11_bits_is_miss,
  input         io_msAlloc_2_11_bits_is_prefetch,
  input         io_msAlloc_2_12_valid,
  input  [2:0]  io_msAlloc_2_12_bits_channel,
  input         io_msAlloc_2_12_bits_is_miss,
  input         io_msAlloc_2_12_bits_is_prefetch,
  input         io_msAlloc_2_13_valid,
  input  [2:0]  io_msAlloc_2_13_bits_channel,
  input         io_msAlloc_2_13_bits_is_miss,
  input         io_msAlloc_2_13_bits_is_prefetch,
  input         io_msAlloc_2_14_valid,
  input  [2:0]  io_msAlloc_2_14_bits_channel,
  input         io_msAlloc_2_14_bits_is_miss,
  input         io_msAlloc_2_14_bits_is_prefetch,
  input         io_msAlloc_2_15_valid,
  input  [2:0]  io_msAlloc_2_15_bits_channel,
  input         io_msAlloc_2_15_bits_is_miss,
  input         io_msAlloc_2_15_bits_is_prefetch,
  input         io_msAlloc_3_0_valid,
  input  [2:0]  io_msAlloc_3_0_bits_channel,
  input         io_msAlloc_3_0_bits_is_miss,
  input         io_msAlloc_3_0_bits_is_prefetch,
  input         io_msAlloc_3_1_valid,
  input  [2:0]  io_msAlloc_3_1_bits_channel,
  input         io_msAlloc_3_1_bits_is_miss,
  input         io_msAlloc_3_1_bits_is_prefetch,
  input         io_msAlloc_3_2_valid,
  input  [2:0]  io_msAlloc_3_2_bits_channel,
  input         io_msAlloc_3_2_bits_is_miss,
  input         io_msAlloc_3_2_bits_is_prefetch,
  input         io_msAlloc_3_3_valid,
  input  [2:0]  io_msAlloc_3_3_bits_channel,
  input         io_msAlloc_3_3_bits_is_miss,
  input         io_msAlloc_3_3_bits_is_prefetch,
  input         io_msAlloc_3_4_valid,
  input  [2:0]  io_msAlloc_3_4_bits_channel,
  input         io_msAlloc_3_4_bits_is_miss,
  input         io_msAlloc_3_4_bits_is_prefetch,
  input         io_msAlloc_3_5_valid,
  input  [2:0]  io_msAlloc_3_5_bits_channel,
  input         io_msAlloc_3_5_bits_is_miss,
  input         io_msAlloc_3_5_bits_is_prefetch,
  input         io_msAlloc_3_6_valid,
  input  [2:0]  io_msAlloc_3_6_bits_channel,
  input         io_msAlloc_3_6_bits_is_miss,
  input         io_msAlloc_3_6_bits_is_prefetch,
  input         io_msAlloc_3_7_valid,
  input  [2:0]  io_msAlloc_3_7_bits_channel,
  input         io_msAlloc_3_7_bits_is_miss,
  input         io_msAlloc_3_7_bits_is_prefetch,
  input         io_msAlloc_3_8_valid,
  input  [2:0]  io_msAlloc_3_8_bits_channel,
  input         io_msAlloc_3_8_bits_is_miss,
  input         io_msAlloc_3_8_bits_is_prefetch,
  input         io_msAlloc_3_9_valid,
  input  [2:0]  io_msAlloc_3_9_bits_channel,
  input         io_msAlloc_3_9_bits_is_miss,
  input         io_msAlloc_3_9_bits_is_prefetch,
  input         io_msAlloc_3_10_valid,
  input  [2:0]  io_msAlloc_3_10_bits_channel,
  input         io_msAlloc_3_10_bits_is_miss,
  input         io_msAlloc_3_10_bits_is_prefetch,
  input         io_msAlloc_3_11_valid,
  input  [2:0]  io_msAlloc_3_11_bits_channel,
  input         io_msAlloc_3_11_bits_is_miss,
  input         io_msAlloc_3_11_bits_is_prefetch,
  input         io_msAlloc_3_12_valid,
  input  [2:0]  io_msAlloc_3_12_bits_channel,
  input         io_msAlloc_3_12_bits_is_miss,
  input         io_msAlloc_3_12_bits_is_prefetch,
  input         io_msAlloc_3_13_valid,
  input  [2:0]  io_msAlloc_3_13_bits_channel,
  input         io_msAlloc_3_13_bits_is_miss,
  input         io_msAlloc_3_13_bits_is_prefetch,
  input         io_msAlloc_3_14_valid,
  input  [2:0]  io_msAlloc_3_14_bits_channel,
  input         io_msAlloc_3_14_bits_is_miss,
  input         io_msAlloc_3_14_bits_is_prefetch,
  input         io_msAlloc_3_15_valid,
  input  [2:0]  io_msAlloc_3_15_bits_channel,
  input         io_msAlloc_3_15_bits_is_miss,
  input         io_msAlloc_3_15_bits_is_prefetch,
  input         io_hitPfInMSHR_0_valid,
  input  [2:0]  io_hitPfInMSHR_0_bits,
  input         io_hitPfInMSHR_1_valid,
  input  [2:0]  io_hitPfInMSHR_1_bits,
  input         io_hitPfInMSHR_2_valid,
  input  [2:0]  io_hitPfInMSHR_2_bits,
  input         io_hitPfInMSHR_3_valid,
  input  [2:0]  io_hitPfInMSHR_3_bits,
  input         io_pfSent_0_valid,
  input  [4:0]  io_pfSent_0_bits,
  input         io_pfSent_1_valid,
  input  [4:0]  io_pfSent_1_bits,
  input         io_pfSent_2_valid,
  input  [4:0]  io_pfSent_2_bits,
  input         io_pfSent_3_valid,
  input  [4:0]  io_pfSent_3_bits,
  input         io_pfLateInMSHR_0_valid,
  input  [4:0]  io_pfLateInMSHR_0_bits,
  input         io_pfLateInMSHR_1_valid,
  input  [4:0]  io_pfLateInMSHR_1_bits,
  input         io_pfLateInMSHR_2_valid,
  input  [4:0]  io_pfLateInMSHR_2_bits,
  input         io_pfLateInMSHR_3_valid,
  input  [4:0]  io_pfLateInMSHR_3_bits,
  input         io_debugTopDown_robHeadPaddr_valid,
  input  [35:0] io_debugTopDown_robHeadPaddr_bits,
  output        io_debugTopDown_l2MissMatch
);
  // 只喂性能计数器、本配置下无硬件的输入共 432 个（dirResult/msAlloc/hitPfInMSHR/pfSent/
  // pfLateInMSHR，及 msStatus 的 channel/is_prefetch）：不连任何逻辑。
  logic [3:0][15:0]       ms_valid, ms_is_miss;
  logic [3:0][15:0][8:0]  ms_set;
  logic [3:0][15:0][30:0] ms_req_tag;
  assign ms_valid[0][0] = io_msStatus_0_0_valid;
  assign ms_is_miss[0][0] = io_msStatus_0_0_bits_is_miss;
  assign ms_set[0][0] = io_msStatus_0_0_bits_set;
  assign ms_req_tag[0][0] = io_msStatus_0_0_bits_reqTag;
  assign ms_valid[0][1] = io_msStatus_0_1_valid;
  assign ms_is_miss[0][1] = io_msStatus_0_1_bits_is_miss;
  assign ms_set[0][1] = io_msStatus_0_1_bits_set;
  assign ms_req_tag[0][1] = io_msStatus_0_1_bits_reqTag;
  assign ms_valid[0][2] = io_msStatus_0_2_valid;
  assign ms_is_miss[0][2] = io_msStatus_0_2_bits_is_miss;
  assign ms_set[0][2] = io_msStatus_0_2_bits_set;
  assign ms_req_tag[0][2] = io_msStatus_0_2_bits_reqTag;
  assign ms_valid[0][3] = io_msStatus_0_3_valid;
  assign ms_is_miss[0][3] = io_msStatus_0_3_bits_is_miss;
  assign ms_set[0][3] = io_msStatus_0_3_bits_set;
  assign ms_req_tag[0][3] = io_msStatus_0_3_bits_reqTag;
  assign ms_valid[0][4] = io_msStatus_0_4_valid;
  assign ms_is_miss[0][4] = io_msStatus_0_4_bits_is_miss;
  assign ms_set[0][4] = io_msStatus_0_4_bits_set;
  assign ms_req_tag[0][4] = io_msStatus_0_4_bits_reqTag;
  assign ms_valid[0][5] = io_msStatus_0_5_valid;
  assign ms_is_miss[0][5] = io_msStatus_0_5_bits_is_miss;
  assign ms_set[0][5] = io_msStatus_0_5_bits_set;
  assign ms_req_tag[0][5] = io_msStatus_0_5_bits_reqTag;
  assign ms_valid[0][6] = io_msStatus_0_6_valid;
  assign ms_is_miss[0][6] = io_msStatus_0_6_bits_is_miss;
  assign ms_set[0][6] = io_msStatus_0_6_bits_set;
  assign ms_req_tag[0][6] = io_msStatus_0_6_bits_reqTag;
  assign ms_valid[0][7] = io_msStatus_0_7_valid;
  assign ms_is_miss[0][7] = io_msStatus_0_7_bits_is_miss;
  assign ms_set[0][7] = io_msStatus_0_7_bits_set;
  assign ms_req_tag[0][7] = io_msStatus_0_7_bits_reqTag;
  assign ms_valid[0][8] = io_msStatus_0_8_valid;
  assign ms_is_miss[0][8] = io_msStatus_0_8_bits_is_miss;
  assign ms_set[0][8] = io_msStatus_0_8_bits_set;
  assign ms_req_tag[0][8] = io_msStatus_0_8_bits_reqTag;
  assign ms_valid[0][9] = io_msStatus_0_9_valid;
  assign ms_is_miss[0][9] = io_msStatus_0_9_bits_is_miss;
  assign ms_set[0][9] = io_msStatus_0_9_bits_set;
  assign ms_req_tag[0][9] = io_msStatus_0_9_bits_reqTag;
  assign ms_valid[0][10] = io_msStatus_0_10_valid;
  assign ms_is_miss[0][10] = io_msStatus_0_10_bits_is_miss;
  assign ms_set[0][10] = io_msStatus_0_10_bits_set;
  assign ms_req_tag[0][10] = io_msStatus_0_10_bits_reqTag;
  assign ms_valid[0][11] = io_msStatus_0_11_valid;
  assign ms_is_miss[0][11] = io_msStatus_0_11_bits_is_miss;
  assign ms_set[0][11] = io_msStatus_0_11_bits_set;
  assign ms_req_tag[0][11] = io_msStatus_0_11_bits_reqTag;
  assign ms_valid[0][12] = io_msStatus_0_12_valid;
  assign ms_is_miss[0][12] = io_msStatus_0_12_bits_is_miss;
  assign ms_set[0][12] = io_msStatus_0_12_bits_set;
  assign ms_req_tag[0][12] = io_msStatus_0_12_bits_reqTag;
  assign ms_valid[0][13] = io_msStatus_0_13_valid;
  assign ms_is_miss[0][13] = io_msStatus_0_13_bits_is_miss;
  assign ms_set[0][13] = io_msStatus_0_13_bits_set;
  assign ms_req_tag[0][13] = io_msStatus_0_13_bits_reqTag;
  assign ms_valid[0][14] = io_msStatus_0_14_valid;
  assign ms_is_miss[0][14] = io_msStatus_0_14_bits_is_miss;
  assign ms_set[0][14] = io_msStatus_0_14_bits_set;
  assign ms_req_tag[0][14] = io_msStatus_0_14_bits_reqTag;
  assign ms_valid[0][15] = io_msStatus_0_15_valid;
  assign ms_is_miss[0][15] = io_msStatus_0_15_bits_is_miss;
  assign ms_set[0][15] = io_msStatus_0_15_bits_set;
  assign ms_req_tag[0][15] = io_msStatus_0_15_bits_reqTag;
  assign ms_valid[1][0] = io_msStatus_1_0_valid;
  assign ms_is_miss[1][0] = io_msStatus_1_0_bits_is_miss;
  assign ms_set[1][0] = io_msStatus_1_0_bits_set;
  assign ms_req_tag[1][0] = io_msStatus_1_0_bits_reqTag;
  assign ms_valid[1][1] = io_msStatus_1_1_valid;
  assign ms_is_miss[1][1] = io_msStatus_1_1_bits_is_miss;
  assign ms_set[1][1] = io_msStatus_1_1_bits_set;
  assign ms_req_tag[1][1] = io_msStatus_1_1_bits_reqTag;
  assign ms_valid[1][2] = io_msStatus_1_2_valid;
  assign ms_is_miss[1][2] = io_msStatus_1_2_bits_is_miss;
  assign ms_set[1][2] = io_msStatus_1_2_bits_set;
  assign ms_req_tag[1][2] = io_msStatus_1_2_bits_reqTag;
  assign ms_valid[1][3] = io_msStatus_1_3_valid;
  assign ms_is_miss[1][3] = io_msStatus_1_3_bits_is_miss;
  assign ms_set[1][3] = io_msStatus_1_3_bits_set;
  assign ms_req_tag[1][3] = io_msStatus_1_3_bits_reqTag;
  assign ms_valid[1][4] = io_msStatus_1_4_valid;
  assign ms_is_miss[1][4] = io_msStatus_1_4_bits_is_miss;
  assign ms_set[1][4] = io_msStatus_1_4_bits_set;
  assign ms_req_tag[1][4] = io_msStatus_1_4_bits_reqTag;
  assign ms_valid[1][5] = io_msStatus_1_5_valid;
  assign ms_is_miss[1][5] = io_msStatus_1_5_bits_is_miss;
  assign ms_set[1][5] = io_msStatus_1_5_bits_set;
  assign ms_req_tag[1][5] = io_msStatus_1_5_bits_reqTag;
  assign ms_valid[1][6] = io_msStatus_1_6_valid;
  assign ms_is_miss[1][6] = io_msStatus_1_6_bits_is_miss;
  assign ms_set[1][6] = io_msStatus_1_6_bits_set;
  assign ms_req_tag[1][6] = io_msStatus_1_6_bits_reqTag;
  assign ms_valid[1][7] = io_msStatus_1_7_valid;
  assign ms_is_miss[1][7] = io_msStatus_1_7_bits_is_miss;
  assign ms_set[1][7] = io_msStatus_1_7_bits_set;
  assign ms_req_tag[1][7] = io_msStatus_1_7_bits_reqTag;
  assign ms_valid[1][8] = io_msStatus_1_8_valid;
  assign ms_is_miss[1][8] = io_msStatus_1_8_bits_is_miss;
  assign ms_set[1][8] = io_msStatus_1_8_bits_set;
  assign ms_req_tag[1][8] = io_msStatus_1_8_bits_reqTag;
  assign ms_valid[1][9] = io_msStatus_1_9_valid;
  assign ms_is_miss[1][9] = io_msStatus_1_9_bits_is_miss;
  assign ms_set[1][9] = io_msStatus_1_9_bits_set;
  assign ms_req_tag[1][9] = io_msStatus_1_9_bits_reqTag;
  assign ms_valid[1][10] = io_msStatus_1_10_valid;
  assign ms_is_miss[1][10] = io_msStatus_1_10_bits_is_miss;
  assign ms_set[1][10] = io_msStatus_1_10_bits_set;
  assign ms_req_tag[1][10] = io_msStatus_1_10_bits_reqTag;
  assign ms_valid[1][11] = io_msStatus_1_11_valid;
  assign ms_is_miss[1][11] = io_msStatus_1_11_bits_is_miss;
  assign ms_set[1][11] = io_msStatus_1_11_bits_set;
  assign ms_req_tag[1][11] = io_msStatus_1_11_bits_reqTag;
  assign ms_valid[1][12] = io_msStatus_1_12_valid;
  assign ms_is_miss[1][12] = io_msStatus_1_12_bits_is_miss;
  assign ms_set[1][12] = io_msStatus_1_12_bits_set;
  assign ms_req_tag[1][12] = io_msStatus_1_12_bits_reqTag;
  assign ms_valid[1][13] = io_msStatus_1_13_valid;
  assign ms_is_miss[1][13] = io_msStatus_1_13_bits_is_miss;
  assign ms_set[1][13] = io_msStatus_1_13_bits_set;
  assign ms_req_tag[1][13] = io_msStatus_1_13_bits_reqTag;
  assign ms_valid[1][14] = io_msStatus_1_14_valid;
  assign ms_is_miss[1][14] = io_msStatus_1_14_bits_is_miss;
  assign ms_set[1][14] = io_msStatus_1_14_bits_set;
  assign ms_req_tag[1][14] = io_msStatus_1_14_bits_reqTag;
  assign ms_valid[1][15] = io_msStatus_1_15_valid;
  assign ms_is_miss[1][15] = io_msStatus_1_15_bits_is_miss;
  assign ms_set[1][15] = io_msStatus_1_15_bits_set;
  assign ms_req_tag[1][15] = io_msStatus_1_15_bits_reqTag;
  assign ms_valid[2][0] = io_msStatus_2_0_valid;
  assign ms_is_miss[2][0] = io_msStatus_2_0_bits_is_miss;
  assign ms_set[2][0] = io_msStatus_2_0_bits_set;
  assign ms_req_tag[2][0] = io_msStatus_2_0_bits_reqTag;
  assign ms_valid[2][1] = io_msStatus_2_1_valid;
  assign ms_is_miss[2][1] = io_msStatus_2_1_bits_is_miss;
  assign ms_set[2][1] = io_msStatus_2_1_bits_set;
  assign ms_req_tag[2][1] = io_msStatus_2_1_bits_reqTag;
  assign ms_valid[2][2] = io_msStatus_2_2_valid;
  assign ms_is_miss[2][2] = io_msStatus_2_2_bits_is_miss;
  assign ms_set[2][2] = io_msStatus_2_2_bits_set;
  assign ms_req_tag[2][2] = io_msStatus_2_2_bits_reqTag;
  assign ms_valid[2][3] = io_msStatus_2_3_valid;
  assign ms_is_miss[2][3] = io_msStatus_2_3_bits_is_miss;
  assign ms_set[2][3] = io_msStatus_2_3_bits_set;
  assign ms_req_tag[2][3] = io_msStatus_2_3_bits_reqTag;
  assign ms_valid[2][4] = io_msStatus_2_4_valid;
  assign ms_is_miss[2][4] = io_msStatus_2_4_bits_is_miss;
  assign ms_set[2][4] = io_msStatus_2_4_bits_set;
  assign ms_req_tag[2][4] = io_msStatus_2_4_bits_reqTag;
  assign ms_valid[2][5] = io_msStatus_2_5_valid;
  assign ms_is_miss[2][5] = io_msStatus_2_5_bits_is_miss;
  assign ms_set[2][5] = io_msStatus_2_5_bits_set;
  assign ms_req_tag[2][5] = io_msStatus_2_5_bits_reqTag;
  assign ms_valid[2][6] = io_msStatus_2_6_valid;
  assign ms_is_miss[2][6] = io_msStatus_2_6_bits_is_miss;
  assign ms_set[2][6] = io_msStatus_2_6_bits_set;
  assign ms_req_tag[2][6] = io_msStatus_2_6_bits_reqTag;
  assign ms_valid[2][7] = io_msStatus_2_7_valid;
  assign ms_is_miss[2][7] = io_msStatus_2_7_bits_is_miss;
  assign ms_set[2][7] = io_msStatus_2_7_bits_set;
  assign ms_req_tag[2][7] = io_msStatus_2_7_bits_reqTag;
  assign ms_valid[2][8] = io_msStatus_2_8_valid;
  assign ms_is_miss[2][8] = io_msStatus_2_8_bits_is_miss;
  assign ms_set[2][8] = io_msStatus_2_8_bits_set;
  assign ms_req_tag[2][8] = io_msStatus_2_8_bits_reqTag;
  assign ms_valid[2][9] = io_msStatus_2_9_valid;
  assign ms_is_miss[2][9] = io_msStatus_2_9_bits_is_miss;
  assign ms_set[2][9] = io_msStatus_2_9_bits_set;
  assign ms_req_tag[2][9] = io_msStatus_2_9_bits_reqTag;
  assign ms_valid[2][10] = io_msStatus_2_10_valid;
  assign ms_is_miss[2][10] = io_msStatus_2_10_bits_is_miss;
  assign ms_set[2][10] = io_msStatus_2_10_bits_set;
  assign ms_req_tag[2][10] = io_msStatus_2_10_bits_reqTag;
  assign ms_valid[2][11] = io_msStatus_2_11_valid;
  assign ms_is_miss[2][11] = io_msStatus_2_11_bits_is_miss;
  assign ms_set[2][11] = io_msStatus_2_11_bits_set;
  assign ms_req_tag[2][11] = io_msStatus_2_11_bits_reqTag;
  assign ms_valid[2][12] = io_msStatus_2_12_valid;
  assign ms_is_miss[2][12] = io_msStatus_2_12_bits_is_miss;
  assign ms_set[2][12] = io_msStatus_2_12_bits_set;
  assign ms_req_tag[2][12] = io_msStatus_2_12_bits_reqTag;
  assign ms_valid[2][13] = io_msStatus_2_13_valid;
  assign ms_is_miss[2][13] = io_msStatus_2_13_bits_is_miss;
  assign ms_set[2][13] = io_msStatus_2_13_bits_set;
  assign ms_req_tag[2][13] = io_msStatus_2_13_bits_reqTag;
  assign ms_valid[2][14] = io_msStatus_2_14_valid;
  assign ms_is_miss[2][14] = io_msStatus_2_14_bits_is_miss;
  assign ms_set[2][14] = io_msStatus_2_14_bits_set;
  assign ms_req_tag[2][14] = io_msStatus_2_14_bits_reqTag;
  assign ms_valid[2][15] = io_msStatus_2_15_valid;
  assign ms_is_miss[2][15] = io_msStatus_2_15_bits_is_miss;
  assign ms_set[2][15] = io_msStatus_2_15_bits_set;
  assign ms_req_tag[2][15] = io_msStatus_2_15_bits_reqTag;
  assign ms_valid[3][0] = io_msStatus_3_0_valid;
  assign ms_is_miss[3][0] = io_msStatus_3_0_bits_is_miss;
  assign ms_set[3][0] = io_msStatus_3_0_bits_set;
  assign ms_req_tag[3][0] = io_msStatus_3_0_bits_reqTag;
  assign ms_valid[3][1] = io_msStatus_3_1_valid;
  assign ms_is_miss[3][1] = io_msStatus_3_1_bits_is_miss;
  assign ms_set[3][1] = io_msStatus_3_1_bits_set;
  assign ms_req_tag[3][1] = io_msStatus_3_1_bits_reqTag;
  assign ms_valid[3][2] = io_msStatus_3_2_valid;
  assign ms_is_miss[3][2] = io_msStatus_3_2_bits_is_miss;
  assign ms_set[3][2] = io_msStatus_3_2_bits_set;
  assign ms_req_tag[3][2] = io_msStatus_3_2_bits_reqTag;
  assign ms_valid[3][3] = io_msStatus_3_3_valid;
  assign ms_is_miss[3][3] = io_msStatus_3_3_bits_is_miss;
  assign ms_set[3][3] = io_msStatus_3_3_bits_set;
  assign ms_req_tag[3][3] = io_msStatus_3_3_bits_reqTag;
  assign ms_valid[3][4] = io_msStatus_3_4_valid;
  assign ms_is_miss[3][4] = io_msStatus_3_4_bits_is_miss;
  assign ms_set[3][4] = io_msStatus_3_4_bits_set;
  assign ms_req_tag[3][4] = io_msStatus_3_4_bits_reqTag;
  assign ms_valid[3][5] = io_msStatus_3_5_valid;
  assign ms_is_miss[3][5] = io_msStatus_3_5_bits_is_miss;
  assign ms_set[3][5] = io_msStatus_3_5_bits_set;
  assign ms_req_tag[3][5] = io_msStatus_3_5_bits_reqTag;
  assign ms_valid[3][6] = io_msStatus_3_6_valid;
  assign ms_is_miss[3][6] = io_msStatus_3_6_bits_is_miss;
  assign ms_set[3][6] = io_msStatus_3_6_bits_set;
  assign ms_req_tag[3][6] = io_msStatus_3_6_bits_reqTag;
  assign ms_valid[3][7] = io_msStatus_3_7_valid;
  assign ms_is_miss[3][7] = io_msStatus_3_7_bits_is_miss;
  assign ms_set[3][7] = io_msStatus_3_7_bits_set;
  assign ms_req_tag[3][7] = io_msStatus_3_7_bits_reqTag;
  assign ms_valid[3][8] = io_msStatus_3_8_valid;
  assign ms_is_miss[3][8] = io_msStatus_3_8_bits_is_miss;
  assign ms_set[3][8] = io_msStatus_3_8_bits_set;
  assign ms_req_tag[3][8] = io_msStatus_3_8_bits_reqTag;
  assign ms_valid[3][9] = io_msStatus_3_9_valid;
  assign ms_is_miss[3][9] = io_msStatus_3_9_bits_is_miss;
  assign ms_set[3][9] = io_msStatus_3_9_bits_set;
  assign ms_req_tag[3][9] = io_msStatus_3_9_bits_reqTag;
  assign ms_valid[3][10] = io_msStatus_3_10_valid;
  assign ms_is_miss[3][10] = io_msStatus_3_10_bits_is_miss;
  assign ms_set[3][10] = io_msStatus_3_10_bits_set;
  assign ms_req_tag[3][10] = io_msStatus_3_10_bits_reqTag;
  assign ms_valid[3][11] = io_msStatus_3_11_valid;
  assign ms_is_miss[3][11] = io_msStatus_3_11_bits_is_miss;
  assign ms_set[3][11] = io_msStatus_3_11_bits_set;
  assign ms_req_tag[3][11] = io_msStatus_3_11_bits_reqTag;
  assign ms_valid[3][12] = io_msStatus_3_12_valid;
  assign ms_is_miss[3][12] = io_msStatus_3_12_bits_is_miss;
  assign ms_set[3][12] = io_msStatus_3_12_bits_set;
  assign ms_req_tag[3][12] = io_msStatus_3_12_bits_reqTag;
  assign ms_valid[3][13] = io_msStatus_3_13_valid;
  assign ms_is_miss[3][13] = io_msStatus_3_13_bits_is_miss;
  assign ms_set[3][13] = io_msStatus_3_13_bits_set;
  assign ms_req_tag[3][13] = io_msStatus_3_13_bits_reqTag;
  assign ms_valid[3][14] = io_msStatus_3_14_valid;
  assign ms_is_miss[3][14] = io_msStatus_3_14_bits_is_miss;
  assign ms_set[3][14] = io_msStatus_3_14_bits_set;
  assign ms_req_tag[3][14] = io_msStatus_3_14_bits_reqTag;
  assign ms_valid[3][15] = io_msStatus_3_15_valid;
  assign ms_is_miss[3][15] = io_msStatus_3_15_bits_is_miss;
  assign ms_set[3][15] = io_msStatus_3_15_bits_set;
  assign ms_req_tag[3][15] = io_msStatus_3_15_bits_reqTag;
  xs_TopDownMonitor_core #(.NBANK(4), .NMSHR(16)) u_core (
    .rob_head_valid (io_debugTopDown_robHeadPaddr_valid),
    .rob_head_paddr (io_debugTopDown_robHeadPaddr_bits),
    .ms_valid       (ms_valid),
    .ms_is_miss     (ms_is_miss),
    .ms_set         (ms_set),
    .ms_req_tag     (ms_req_tag),
    .l2_miss_match  (io_debugTopDown_l2MissMatch)
  );
endmodule
// END GENERATED
