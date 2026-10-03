// MemTrigger_3.sv —— 访存 store 的调试触发器地址匹配：StoreUnit s1 的 child（STORE 变体薄文件）。
//
// 共享核 xs_MemTrigger_core 在 MemTrigger.sv（机制讲解在那里）。本变体与 LOAD 变体的差别：
//   · 触发器使能位接 tdata1.store（而非 .load）；
//   · 多一个 isCbo 输入：cbo.zero/clean/flush/inval 这类缓存块操作按整条 64B 缓存行比较；
//   · 没有 isPrf（store 没有软件预取之说，核里钉 0）；
//   · golden 里 triggerMask 输出被 firtool 消掉了（StoreUnit 不用），核的该输出悬空。
// 规模：4 个触发器、VAddrBits=50、向量字节掩码 16 位，纯组合，无寄存器。

module MemTrigger_3 (

  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_0_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_0_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_0_store,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_1_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_1_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_1_store,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_2_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_2_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_2_store,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2,
  input  [1:0]  tdataVec_io_fromCsrTrigger_tdataVec_3_matchType,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_select,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_timing,
  input  [3:0]  tdataVec_io_fromCsrTrigger_tdataVec_3_action,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_chain,
  input         tdataVec_io_fromCsrTrigger_tdataVec_3_store,
  input  [63:0] tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_0,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_1,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_2,
  input         tdataVec_io_fromCsrTrigger_tEnableVec_3,
  input         tdataVec_io_fromCsrTrigger_debugMode,
  input         tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp,
  input  [49:0] tdataVec_io_fromLoadStore_vaddr,
  input         tdataVec_io_fromLoadStore_isVectorUnitStride,
  input  [15:0] tdataVec_io_fromLoadStore_mask,
  output [3:0]  tdataVec_io_toLoadStore_triggerAction,
  output [49:0] tdataVec_io_toLoadStore_triggerVaddr,
  input         tdataVec_io_isCbo
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
    .rwEnable             ({tdataVec_io_fromCsrTrigger_tdataVec_3_store,
                            tdataVec_io_fromCsrTrigger_tdataVec_2_store,
                            tdataVec_io_fromCsrTrigger_tdataVec_1_store,
                            tdataVec_io_fromCsrTrigger_tdataVec_0_store}),
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
    .isVectorUnitStride   (tdataVec_io_fromLoadStore_isVectorUnitStride),
    .mask                 (tdataVec_io_fromLoadStore_mask),
    .isPrf                (1'b0),
    .isCbo                (tdataVec_io_isCbo),
    .triggerAction        (tdataVec_io_toLoadStore_triggerAction),
    .triggerVaddr         (tdataVec_io_toLoadStore_triggerVaddr),
    .triggerMask          ()
  );

endmodule
