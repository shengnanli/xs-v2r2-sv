// VSegmentTrigger.sv —— 向量 segment 访存的调试触发器地址匹配：VSegmentUnit 的 child（薄文件）。
//
// 共享核 xs_MemTrigger_core 在 MemTrigger.sv（机制讲解在那里）。本变体的特点：
//   · VSegmentUnit 一个模块既做 segment load 也做 segment store，所以触发器使能位由 memType
//     现选：memType=1（load）取 tdata1.load，否则取 tdata1.store；
//   · segment 指令逐元素访问，没有"128 位 unit-stride"与缓存块操作那两支（isVectorUnitStride / isCbo
//     钉 0，mask 钉 0）；也没有软件预取（isPrf 钉 0）；
//   · golden 里只留下 triggerAction 一个输出（triggerVaddr / triggerMask 父模块不用，被 firtool 消掉），
//     核的那两个输出悬空。
// 规模：4 个触发器、VAddrBits=50，纯组合，无寄存器。

module VSegmentTrigger (
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_0_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_0_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_store,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_1_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_1_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_store,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_2_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_2_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_store,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_3_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_3_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_store,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_load,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_0,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_1,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_2,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_3,
  input         tdataVec_io_fromCsrTrigger_debugMode,
  input         tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp,
  input  [49:0] tdataVec_io_fromLoadStore_vaddr,
  output [3:0]  tdataVec_io_toLoadStore_triggerAction,
  input         tdataVec_io_memType
);

  xs_MemTrigger_core u_core (
    .matchType            ({tdataVec_io_fromCsrTrigger_tdataVec_3_matchType,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_matchType,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_matchType,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_matchType}),
    .select               ({tdataVec_io_fromCsrTrigger_tdataVec_3_select,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_select,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_select,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_select}),
    .timing               ({tdataVec_io_fromCsrTrigger_tdataVec_3_timing,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_timing,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_timing,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_timing}),
    .action               ({tdataVec_io_fromCsrTrigger_tdataVec_3_action,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_action,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_action,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_action}),
    .chain                ({tdataVec_io_fromCsrTrigger_tdataVec_3_chain,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_chain,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_chain,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_chain}),
    .rwEnable             ({
                            tdataVec_io_memType ? tdataVec_io_fromCsrTrigger_tdataVec_3_load : tdataVec_io_fromCsrTrigger_tdataVec_3_store,
                            tdataVec_io_memType ? tdataVec_io_fromCsrTrigger_tdataVec_2_load : tdataVec_io_fromCsrTrigger_tdataVec_2_store,
                            tdataVec_io_memType ? tdataVec_io_fromCsrTrigger_tdataVec_1_load : tdataVec_io_fromCsrTrigger_tdataVec_1_store,
                            tdataVec_io_memType ? tdataVec_io_fromCsrTrigger_tdataVec_0_load : tdataVec_io_fromCsrTrigger_tdataVec_0_store}),
    .tdata2               ({tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2}),
    .tEnable              ({tdataVec_io_fromCsrTrigger_tEnableVec_3,
                            tdataVec_io_fromCsrTrigger_tEnableVec_2,
                            tdataVec_io_fromCsrTrigger_tEnableVec_1,
                            tdataVec_io_fromCsrTrigger_tEnableVec_0}),
    .debugMode            (tdataVec_io_fromCsrTrigger_debugMode),
    .triggerCanRaiseBpExp (tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp),
    .vaddr                (tdataVec_io_fromLoadStore_vaddr),
    .isVectorUnitStride   (1'b0),
    .mask                 (16'h0),
    .isPrf                (1'b0),
    .isCbo                (1'b0),
    .triggerAction        (tdataVec_io_toLoadStore_triggerAction),
    .triggerVaddr         (),
    .triggerMask          ()
  );

endmodule
