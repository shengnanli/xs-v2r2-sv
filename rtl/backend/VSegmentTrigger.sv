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
  // Internal procedural nets keep the recovered module port declarations unchanged.
  logic [3:0] tdataVec_io_toLoadStore_triggerAction_i;


  // Address matching is shared by all four slots; the slot-specific code below
  // only supplies policy bits and the chain/timing relationships.
  function automatic logic address_match(
    input logic [1:0]  mode,
    input logic [49:0] address,
    input logic [49:0] threshold
  );
    case (mode)
      2'b11: address_match = address < threshold;
      2'b10: address_match = address >= threshold;
      2'b00: address_match = address == threshold;
      default: address_match = 1'b0;
    endcase
  endfunction

  wire slot0_match = address_match(
    tdataVec_io_fromCsrTrigger_tdataVec_0_matchType,
    tdataVec_io_fromLoadStore_vaddr,
    tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2[49:0]);
  wire slot1_match = address_match(
    tdataVec_io_fromCsrTrigger_tdataVec_1_matchType,
    tdataVec_io_fromLoadStore_vaddr,
    tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2[49:0]);
  wire slot2_match = address_match(
    tdataVec_io_fromCsrTrigger_tdataVec_2_matchType,
    tdataVec_io_fromLoadStore_vaddr,
    tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2[49:0]);
  wire slot3_match = address_match(
    tdataVec_io_fromCsrTrigger_tdataVec_3_matchType,
    tdataVec_io_fromLoadStore_vaddr,
    tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2[49:0]);

  wire slot0_access = tdataVec_io_memType
    ? tdataVec_io_fromCsrTrigger_tdataVec_0_load
    : tdataVec_io_fromCsrTrigger_tdataVec_0_store;
  wire slot1_access = tdataVec_io_memType
    ? tdataVec_io_fromCsrTrigger_tdataVec_1_load
    : tdataVec_io_fromCsrTrigger_tdataVec_1_store;
  wire slot2_access = tdataVec_io_memType
    ? tdataVec_io_fromCsrTrigger_tdataVec_2_load
    : tdataVec_io_fromCsrTrigger_tdataVec_2_store;
  wire slot3_access = tdataVec_io_memType
    ? tdataVec_io_fromCsrTrigger_tdataVec_3_load
    : tdataVec_io_fromCsrTrigger_tdataVec_3_store;

  wire slot0_hit = ~tdataVec_io_fromCsrTrigger_tdataVec_0_select &
    ~tdataVec_io_fromCsrTrigger_debugMode &
    slot0_match & tdataVec_io_fromCsrTrigger_tEnableVec_0 & slot0_access;
  wire slot1_hit = ~tdataVec_io_fromCsrTrigger_tdataVec_1_select &
    ~tdataVec_io_fromCsrTrigger_debugMode &
    slot1_match & tdataVec_io_fromCsrTrigger_tEnableVec_1 & slot1_access;
  wire slot2_hit = ~tdataVec_io_fromCsrTrigger_tdataVec_2_select &
    ~tdataVec_io_fromCsrTrigger_debugMode &
    slot2_match & tdataVec_io_fromCsrTrigger_tEnableVec_2 & slot2_access;
  wire slot3_hit = ~tdataVec_io_fromCsrTrigger_tdataVec_3_select &
    ~tdataVec_io_fromCsrTrigger_debugMode &
    slot3_match & tdataVec_io_fromCsrTrigger_tEnableVec_3 & slot3_access;

  wire fire0 = slot0_hit & ~tdataVec_io_fromCsrTrigger_tdataVec_0_chain;
  wire fire1 = slot1_hit & ~tdataVec_io_fromCsrTrigger_tdataVec_1_chain &
    (~tdataVec_io_fromCsrTrigger_tdataVec_0_chain |
     (tdataVec_io_fromCsrTrigger_tdataVec_0_chain & slot0_hit &
      (tdataVec_io_fromCsrTrigger_tdataVec_0_timing ==
       tdataVec_io_fromCsrTrigger_tdataVec_1_timing)));
  wire fire2 = slot2_hit & ~tdataVec_io_fromCsrTrigger_tdataVec_2_chain &
    (~tdataVec_io_fromCsrTrigger_tdataVec_1_chain |
     (tdataVec_io_fromCsrTrigger_tdataVec_1_chain & slot1_hit &
      (tdataVec_io_fromCsrTrigger_tdataVec_1_timing ==
       tdataVec_io_fromCsrTrigger_tdataVec_2_timing)));
  wire fire3 = slot3_hit & ~tdataVec_io_fromCsrTrigger_tdataVec_3_chain &
    (~tdataVec_io_fromCsrTrigger_tdataVec_2_chain |
     (tdataVec_io_fromCsrTrigger_tdataVec_2_chain & slot2_hit &
      (tdataVec_io_fromCsrTrigger_tdataVec_2_timing ==
       tdataVec_io_fromCsrTrigger_tdataVec_3_timing)));

  always_comb begin
    if ((fire3 & (tdataVec_io_fromCsrTrigger_tdataVec_3_action == 4'h1)) |
        (fire2 & (tdataVec_io_fromCsrTrigger_tdataVec_2_action == 4'h1)) |
        (fire1 & (tdataVec_io_fromCsrTrigger_tdataVec_1_action == 4'h1)) |
        (fire0 & (tdataVec_io_fromCsrTrigger_tdataVec_0_action == 4'h1))) begin
      tdataVec_io_toLoadStore_triggerAction_i = 4'h1;
    end else if (tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp &&
        ((fire3 & (tdataVec_io_fromCsrTrigger_tdataVec_3_action == 4'h0)) |
         (fire2 & (tdataVec_io_fromCsrTrigger_tdataVec_2_action == 4'h0)) |
         (fire1 & (tdataVec_io_fromCsrTrigger_tdataVec_1_action == 4'h0)) |
         (fire0 & (tdataVec_io_fromCsrTrigger_tdataVec_0_action == 4'h0)))) begin
      tdataVec_io_toLoadStore_triggerAction_i = 4'h0;
    end else begin
      tdataVec_io_toLoadStore_triggerAction_i = 4'hF;
    end
  end

  assign tdataVec_io_toLoadStore_triggerAction = tdataVec_io_toLoadStore_triggerAction_i;
endmodule
