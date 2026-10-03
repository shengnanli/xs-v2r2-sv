// VSegmentTrigger.sv — four-slot chained load/store address trigger evaluator.
// Each slot performs match, enable, chain, and timing checks before selecting an action.
// The lowest eligible action wins and breakpoint gating follows the G1 trigger contract.
module VSegmentTrigger(
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

  wire trigger_hit_0 =
    ~tdataVec_io_fromCsrTrigger_tdataVec_0_select & ~tdataVec_io_fromCsrTrigger_debugMode
    & ((&tdataVec_io_fromCsrTrigger_tdataVec_0_matchType)
         ? tdataVec_io_fromLoadStore_vaddr < tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2[49:0]
         : tdataVec_io_fromCsrTrigger_tdataVec_0_matchType == 2'h2
             ? tdataVec_io_fromLoadStore_vaddr >= tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2[49:0]
             : tdataVec_io_fromCsrTrigger_tdataVec_0_matchType == 2'h0
               & tdataVec_io_fromLoadStore_vaddr == tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2[49:0])
    & tdataVec_io_fromCsrTrigger_tEnableVec_0
    & (tdataVec_io_memType
         ? tdataVec_io_fromCsrTrigger_tdataVec_0_load
         : tdataVec_io_fromCsrTrigger_tdataVec_0_store);
  wire trigger_hit_1 =
    ~tdataVec_io_fromCsrTrigger_tdataVec_1_select & ~tdataVec_io_fromCsrTrigger_debugMode
    & ((&tdataVec_io_fromCsrTrigger_tdataVec_1_matchType)
         ? tdataVec_io_fromLoadStore_vaddr < tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2[49:0]
         : tdataVec_io_fromCsrTrigger_tdataVec_1_matchType == 2'h2
             ? tdataVec_io_fromLoadStore_vaddr >= tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2[49:0]
             : tdataVec_io_fromCsrTrigger_tdataVec_1_matchType == 2'h0
               & tdataVec_io_fromLoadStore_vaddr == tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2[49:0])
    & tdataVec_io_fromCsrTrigger_tEnableVec_1
    & (tdataVec_io_memType
         ? tdataVec_io_fromCsrTrigger_tdataVec_1_load
         : tdataVec_io_fromCsrTrigger_tdataVec_1_store);
  wire trigger_hit_2 =
    ~tdataVec_io_fromCsrTrigger_tdataVec_2_select & ~tdataVec_io_fromCsrTrigger_debugMode
    & ((&tdataVec_io_fromCsrTrigger_tdataVec_2_matchType)
         ? tdataVec_io_fromLoadStore_vaddr < tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2[49:0]
         : tdataVec_io_fromCsrTrigger_tdataVec_2_matchType == 2'h2
             ? tdataVec_io_fromLoadStore_vaddr >= tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2[49:0]
             : tdataVec_io_fromCsrTrigger_tdataVec_2_matchType == 2'h0
               & tdataVec_io_fromLoadStore_vaddr == tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2[49:0])
    & tdataVec_io_fromCsrTrigger_tEnableVec_2
    & (tdataVec_io_memType
         ? tdataVec_io_fromCsrTrigger_tdataVec_2_load
         : tdataVec_io_fromCsrTrigger_tdataVec_2_store);
  wire trigger_fire_0 =
    trigger_hit_0 & ~tdataVec_io_fromCsrTrigger_tdataVec_0_chain;
  wire trigger_fire_1 =
    (tdataVec_io_fromCsrTrigger_tdataVec_0_chain & trigger_hit_0
     | ~tdataVec_io_fromCsrTrigger_tdataVec_0_chain)
    & (tdataVec_io_fromCsrTrigger_tdataVec_0_chain
       & ~tdataVec_io_fromCsrTrigger_tdataVec_1_chain
       & tdataVec_io_fromCsrTrigger_tdataVec_0_timing == tdataVec_io_fromCsrTrigger_tdataVec_1_timing
       | ~tdataVec_io_fromCsrTrigger_tdataVec_0_chain) & trigger_hit_1
    & ~tdataVec_io_fromCsrTrigger_tdataVec_1_chain;
  wire trigger_fire_2 =
    (tdataVec_io_fromCsrTrigger_tdataVec_1_chain & trigger_hit_1
     | ~tdataVec_io_fromCsrTrigger_tdataVec_1_chain)
    & (tdataVec_io_fromCsrTrigger_tdataVec_1_chain
       & ~tdataVec_io_fromCsrTrigger_tdataVec_2_chain
       & tdataVec_io_fromCsrTrigger_tdataVec_1_timing == tdataVec_io_fromCsrTrigger_tdataVec_2_timing
       | ~tdataVec_io_fromCsrTrigger_tdataVec_1_chain) & trigger_hit_2
    & ~tdataVec_io_fromCsrTrigger_tdataVec_2_chain;
  wire trigger_fire_3 =
    (tdataVec_io_fromCsrTrigger_tdataVec_2_chain & trigger_hit_2
     | ~tdataVec_io_fromCsrTrigger_tdataVec_2_chain)
    & (tdataVec_io_fromCsrTrigger_tdataVec_2_chain
       & ~tdataVec_io_fromCsrTrigger_tdataVec_3_chain
       & tdataVec_io_fromCsrTrigger_tdataVec_2_timing == tdataVec_io_fromCsrTrigger_tdataVec_3_timing
       | ~tdataVec_io_fromCsrTrigger_tdataVec_2_chain)
    & ~tdataVec_io_fromCsrTrigger_tdataVec_3_select
    & ~tdataVec_io_fromCsrTrigger_debugMode
    & ((&tdataVec_io_fromCsrTrigger_tdataVec_3_matchType)
         ? tdataVec_io_fromLoadStore_vaddr < tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2[49:0]
         : tdataVec_io_fromCsrTrigger_tdataVec_3_matchType == 2'h2
             ? tdataVec_io_fromLoadStore_vaddr >= tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2[49:0]
             : tdataVec_io_fromCsrTrigger_tdataVec_3_matchType == 2'h0
               & tdataVec_io_fromLoadStore_vaddr == tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2[49:0])
    & tdataVec_io_fromCsrTrigger_tEnableVec_3
    & (tdataVec_io_memType
         ? tdataVec_io_fromCsrTrigger_tdataVec_3_load
         : tdataVec_io_fromCsrTrigger_tdataVec_3_store)
    & ~tdataVec_io_fromCsrTrigger_tdataVec_3_chain;
  assign tdataVec_io_toLoadStore_triggerAction =
    (|{trigger_fire_3 & tdataVec_io_fromCsrTrigger_tdataVec_3_action == 4'h1,
       trigger_fire_2 & tdataVec_io_fromCsrTrigger_tdataVec_2_action == 4'h1,
       trigger_fire_1 & tdataVec_io_fromCsrTrigger_tdataVec_1_action == 4'h1,
       trigger_fire_0 & tdataVec_io_fromCsrTrigger_tdataVec_0_action == 4'h1})
      ? 4'h1
      : (|{trigger_fire_3 & tdataVec_io_fromCsrTrigger_tdataVec_3_action == 4'h0,
           trigger_fire_2 & tdataVec_io_fromCsrTrigger_tdataVec_2_action == 4'h0,
           trigger_fire_1 & tdataVec_io_fromCsrTrigger_tdataVec_1_action == 4'h0,
           trigger_fire_0 & tdataVec_io_fromCsrTrigger_tdataVec_0_action == 4'h0})
        & tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp
          ? 4'h0
          : 4'hF;
endmodule
