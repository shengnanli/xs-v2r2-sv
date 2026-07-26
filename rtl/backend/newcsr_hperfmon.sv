// NewCSR hardware performance monitor — readable transcriptions.
//
//   HPerfMonitor_1 : routes the raw performance-event set into the hpmcounter
//                    increment inputs and instantiates the per-counter logic.
//   HPerfCounter_8 : one HPM counter's event mux + increment accumulation; the
//                    64-entry event-select lookup (renamed eventSelTable) picks
//                    the counted event by hpmevent number.
// Both are plain structural RTL; the readable rewrite drops the sim randomize-
// init block and renames the CIRCT lookup wire. HPerfCounter_8 is a shared child
// module elaborated on BOTH sides of the proof (not a black box). FM-verified
// strict golden-vs-impl SUCCEEDED, no black box, no dont_verify.


module HPerfMonitor_1(
  input         clock,
  input  [63:0] io_hpm_event_0,
  input  [63:0] io_hpm_event_1,
  input  [63:0] io_hpm_event_2,
  input  [63:0] io_hpm_event_3,
  input  [63:0] io_hpm_event_4,
  input  [5:0]  io_events_sets_0_value,
  input  [5:0]  io_events_sets_1_value,
  input  [5:0]  io_events_sets_2_value,
  input  [5:0]  io_events_sets_3_value,
  input  [5:0]  io_events_sets_4_value,
  input  [5:0]  io_events_sets_5_value,
  input  [5:0]  io_events_sets_6_value,
  input  [5:0]  io_events_sets_7_value,
  input  [5:0]  io_events_sets_8_value,
  input  [5:0]  io_events_sets_9_value,
  input  [5:0]  io_events_sets_10_value,
  input  [5:0]  io_events_sets_11_value,
  input  [5:0]  io_events_sets_12_value,
  input  [5:0]  io_events_sets_13_value,
  input  [5:0]  io_events_sets_14_value,
  input  [5:0]  io_events_sets_15_value,
  input  [5:0]  io_events_sets_16_value,
  input  [5:0]  io_events_sets_17_value,
  input  [5:0]  io_events_sets_18_value,
  input  [5:0]  io_events_sets_19_value,
  input  [5:0]  io_events_sets_20_value,
  input  [5:0]  io_events_sets_21_value,
  input  [5:0]  io_events_sets_22_value,
  input  [5:0]  io_events_sets_23_value,
  input  [5:0]  io_events_sets_24_value,
  input  [5:0]  io_events_sets_25_value,
  input  [5:0]  io_events_sets_26_value,
  input  [5:0]  io_events_sets_27_value,
  input  [5:0]  io_events_sets_28_value,
  input  [5:0]  io_events_sets_29_value,
  input  [5:0]  io_events_sets_30_value,
  input  [5:0]  io_events_sets_31_value,
  input  [5:0]  io_events_sets_32_value,
  input  [5:0]  io_events_sets_33_value,
  input  [5:0]  io_events_sets_34_value,
  input  [5:0]  io_events_sets_35_value,
  input  [5:0]  io_events_sets_36_value,
  input  [5:0]  io_events_sets_37_value,
  input  [5:0]  io_events_sets_38_value,
  input  [5:0]  io_events_sets_39_value,
  input  [5:0]  io_events_sets_40_value,
  input  [5:0]  io_events_sets_41_value,
  input  [5:0]  io_events_sets_42_value,
  input  [5:0]  io_events_sets_43_value,
  input  [5:0]  io_events_sets_44_value,
  input  [5:0]  io_events_sets_45_value,
  input  [5:0]  io_events_sets_46_value,
  input  [5:0]  io_events_sets_47_value,
  output [5:0]  io_perf_0_value,
  output [5:0]  io_perf_1_value,
  output [5:0]  io_perf_2_value,
  output [5:0]  io_perf_3_value,
  output [5:0]  io_perf_4_value
);

  wire [5:0] _perfEvents_hpc_4_io_perf_0_value;
  wire [5:0] _perfEvents_hpc_3_io_perf_0_value;
  wire [5:0] _perfEvents_hpc_2_io_perf_0_value;
  wire [5:0] _perfEvents_hpc_1_io_perf_0_value;
  wire [5:0] _perfEvents_hpc_io_perf_0_value;
  reg  [5:0] io_perf_0_value_REG;
  reg  [5:0] io_perf_0_value_REG_1;
  reg  [5:0] io_perf_1_value_REG;
  reg  [5:0] io_perf_1_value_REG_1;
  reg  [5:0] io_perf_2_value_REG;
  reg  [5:0] io_perf_2_value_REG_1;
  reg  [5:0] io_perf_3_value_REG;
  reg  [5:0] io_perf_3_value_REG_1;
  reg  [5:0] io_perf_4_value_REG;
  reg  [5:0] io_perf_4_value_REG_1;
  always @(posedge clock) begin
    io_perf_0_value_REG <= _perfEvents_hpc_io_perf_0_value;
    io_perf_0_value_REG_1 <= io_perf_0_value_REG;
    io_perf_1_value_REG <= _perfEvents_hpc_1_io_perf_0_value;
    io_perf_1_value_REG_1 <= io_perf_1_value_REG;
    io_perf_2_value_REG <= _perfEvents_hpc_2_io_perf_0_value;
    io_perf_2_value_REG_1 <= io_perf_2_value_REG;
    io_perf_3_value_REG <= _perfEvents_hpc_3_io_perf_0_value;
    io_perf_3_value_REG_1 <= io_perf_3_value_REG;
    io_perf_4_value_REG <= _perfEvents_hpc_4_io_perf_0_value;
    io_perf_4_value_REG_1 <= io_perf_4_value_REG;
  end
  HPerfCounter_8 perfEvents_hpc (
    .clock                   (clock),
    .io_hpm_event            (io_hpm_event_0),
    .io_events_sets_0_value  (io_events_sets_0_value),
    .io_events_sets_1_value  (io_events_sets_1_value),
    .io_events_sets_2_value  (io_events_sets_2_value),
    .io_events_sets_3_value  (io_events_sets_3_value),
    .io_events_sets_4_value  (io_events_sets_4_value),
    .io_events_sets_5_value  (io_events_sets_5_value),
    .io_events_sets_6_value  (io_events_sets_6_value),
    .io_events_sets_7_value  (io_events_sets_7_value),
    .io_events_sets_8_value  (io_events_sets_8_value),
    .io_events_sets_9_value  (io_events_sets_9_value),
    .io_events_sets_10_value (io_events_sets_10_value),
    .io_events_sets_11_value (io_events_sets_11_value),
    .io_events_sets_12_value (io_events_sets_12_value),
    .io_events_sets_13_value (io_events_sets_13_value),
    .io_events_sets_14_value (io_events_sets_14_value),
    .io_events_sets_15_value (io_events_sets_15_value),
    .io_events_sets_16_value (io_events_sets_16_value),
    .io_events_sets_17_value (io_events_sets_17_value),
    .io_events_sets_18_value (io_events_sets_18_value),
    .io_events_sets_19_value (io_events_sets_19_value),
    .io_events_sets_20_value (io_events_sets_20_value),
    .io_events_sets_21_value (io_events_sets_21_value),
    .io_events_sets_22_value (io_events_sets_22_value),
    .io_events_sets_23_value (io_events_sets_23_value),
    .io_events_sets_24_value (io_events_sets_24_value),
    .io_events_sets_25_value (io_events_sets_25_value),
    .io_events_sets_26_value (io_events_sets_26_value),
    .io_events_sets_27_value (io_events_sets_27_value),
    .io_events_sets_28_value (io_events_sets_28_value),
    .io_events_sets_29_value (io_events_sets_29_value),
    .io_events_sets_30_value (io_events_sets_30_value),
    .io_events_sets_31_value (io_events_sets_31_value),
    .io_events_sets_32_value (io_events_sets_32_value),
    .io_events_sets_33_value (io_events_sets_33_value),
    .io_events_sets_34_value (io_events_sets_34_value),
    .io_events_sets_35_value (io_events_sets_35_value),
    .io_events_sets_36_value (io_events_sets_36_value),
    .io_events_sets_37_value (io_events_sets_37_value),
    .io_events_sets_38_value (io_events_sets_38_value),
    .io_events_sets_39_value (io_events_sets_39_value),
    .io_events_sets_40_value (io_events_sets_40_value),
    .io_events_sets_41_value (io_events_sets_41_value),
    .io_events_sets_42_value (io_events_sets_42_value),
    .io_events_sets_43_value (io_events_sets_43_value),
    .io_events_sets_44_value (io_events_sets_44_value),
    .io_events_sets_45_value (io_events_sets_45_value),
    .io_events_sets_46_value (io_events_sets_46_value),
    .io_events_sets_47_value (io_events_sets_47_value),
    .io_perf_0_value         (_perfEvents_hpc_io_perf_0_value)
  );
  HPerfCounter_8 perfEvents_hpc_1 (
    .clock                   (clock),
    .io_hpm_event            (io_hpm_event_1),
    .io_events_sets_0_value  (io_events_sets_0_value),
    .io_events_sets_1_value  (io_events_sets_1_value),
    .io_events_sets_2_value  (io_events_sets_2_value),
    .io_events_sets_3_value  (io_events_sets_3_value),
    .io_events_sets_4_value  (io_events_sets_4_value),
    .io_events_sets_5_value  (io_events_sets_5_value),
    .io_events_sets_6_value  (io_events_sets_6_value),
    .io_events_sets_7_value  (io_events_sets_7_value),
    .io_events_sets_8_value  (io_events_sets_8_value),
    .io_events_sets_9_value  (io_events_sets_9_value),
    .io_events_sets_10_value (io_events_sets_10_value),
    .io_events_sets_11_value (io_events_sets_11_value),
    .io_events_sets_12_value (io_events_sets_12_value),
    .io_events_sets_13_value (io_events_sets_13_value),
    .io_events_sets_14_value (io_events_sets_14_value),
    .io_events_sets_15_value (io_events_sets_15_value),
    .io_events_sets_16_value (io_events_sets_16_value),
    .io_events_sets_17_value (io_events_sets_17_value),
    .io_events_sets_18_value (io_events_sets_18_value),
    .io_events_sets_19_value (io_events_sets_19_value),
    .io_events_sets_20_value (io_events_sets_20_value),
    .io_events_sets_21_value (io_events_sets_21_value),
    .io_events_sets_22_value (io_events_sets_22_value),
    .io_events_sets_23_value (io_events_sets_23_value),
    .io_events_sets_24_value (io_events_sets_24_value),
    .io_events_sets_25_value (io_events_sets_25_value),
    .io_events_sets_26_value (io_events_sets_26_value),
    .io_events_sets_27_value (io_events_sets_27_value),
    .io_events_sets_28_value (io_events_sets_28_value),
    .io_events_sets_29_value (io_events_sets_29_value),
    .io_events_sets_30_value (io_events_sets_30_value),
    .io_events_sets_31_value (io_events_sets_31_value),
    .io_events_sets_32_value (io_events_sets_32_value),
    .io_events_sets_33_value (io_events_sets_33_value),
    .io_events_sets_34_value (io_events_sets_34_value),
    .io_events_sets_35_value (io_events_sets_35_value),
    .io_events_sets_36_value (io_events_sets_36_value),
    .io_events_sets_37_value (io_events_sets_37_value),
    .io_events_sets_38_value (io_events_sets_38_value),
    .io_events_sets_39_value (io_events_sets_39_value),
    .io_events_sets_40_value (io_events_sets_40_value),
    .io_events_sets_41_value (io_events_sets_41_value),
    .io_events_sets_42_value (io_events_sets_42_value),
    .io_events_sets_43_value (io_events_sets_43_value),
    .io_events_sets_44_value (io_events_sets_44_value),
    .io_events_sets_45_value (io_events_sets_45_value),
    .io_events_sets_46_value (io_events_sets_46_value),
    .io_events_sets_47_value (io_events_sets_47_value),
    .io_perf_0_value         (_perfEvents_hpc_1_io_perf_0_value)
  );
  HPerfCounter_8 perfEvents_hpc_2 (
    .clock                   (clock),
    .io_hpm_event            (io_hpm_event_2),
    .io_events_sets_0_value  (io_events_sets_0_value),
    .io_events_sets_1_value  (io_events_sets_1_value),
    .io_events_sets_2_value  (io_events_sets_2_value),
    .io_events_sets_3_value  (io_events_sets_3_value),
    .io_events_sets_4_value  (io_events_sets_4_value),
    .io_events_sets_5_value  (io_events_sets_5_value),
    .io_events_sets_6_value  (io_events_sets_6_value),
    .io_events_sets_7_value  (io_events_sets_7_value),
    .io_events_sets_8_value  (io_events_sets_8_value),
    .io_events_sets_9_value  (io_events_sets_9_value),
    .io_events_sets_10_value (io_events_sets_10_value),
    .io_events_sets_11_value (io_events_sets_11_value),
    .io_events_sets_12_value (io_events_sets_12_value),
    .io_events_sets_13_value (io_events_sets_13_value),
    .io_events_sets_14_value (io_events_sets_14_value),
    .io_events_sets_15_value (io_events_sets_15_value),
    .io_events_sets_16_value (io_events_sets_16_value),
    .io_events_sets_17_value (io_events_sets_17_value),
    .io_events_sets_18_value (io_events_sets_18_value),
    .io_events_sets_19_value (io_events_sets_19_value),
    .io_events_sets_20_value (io_events_sets_20_value),
    .io_events_sets_21_value (io_events_sets_21_value),
    .io_events_sets_22_value (io_events_sets_22_value),
    .io_events_sets_23_value (io_events_sets_23_value),
    .io_events_sets_24_value (io_events_sets_24_value),
    .io_events_sets_25_value (io_events_sets_25_value),
    .io_events_sets_26_value (io_events_sets_26_value),
    .io_events_sets_27_value (io_events_sets_27_value),
    .io_events_sets_28_value (io_events_sets_28_value),
    .io_events_sets_29_value (io_events_sets_29_value),
    .io_events_sets_30_value (io_events_sets_30_value),
    .io_events_sets_31_value (io_events_sets_31_value),
    .io_events_sets_32_value (io_events_sets_32_value),
    .io_events_sets_33_value (io_events_sets_33_value),
    .io_events_sets_34_value (io_events_sets_34_value),
    .io_events_sets_35_value (io_events_sets_35_value),
    .io_events_sets_36_value (io_events_sets_36_value),
    .io_events_sets_37_value (io_events_sets_37_value),
    .io_events_sets_38_value (io_events_sets_38_value),
    .io_events_sets_39_value (io_events_sets_39_value),
    .io_events_sets_40_value (io_events_sets_40_value),
    .io_events_sets_41_value (io_events_sets_41_value),
    .io_events_sets_42_value (io_events_sets_42_value),
    .io_events_sets_43_value (io_events_sets_43_value),
    .io_events_sets_44_value (io_events_sets_44_value),
    .io_events_sets_45_value (io_events_sets_45_value),
    .io_events_sets_46_value (io_events_sets_46_value),
    .io_events_sets_47_value (io_events_sets_47_value),
    .io_perf_0_value         (_perfEvents_hpc_2_io_perf_0_value)
  );
  HPerfCounter_8 perfEvents_hpc_3 (
    .clock                   (clock),
    .io_hpm_event            (io_hpm_event_3),
    .io_events_sets_0_value  (io_events_sets_0_value),
    .io_events_sets_1_value  (io_events_sets_1_value),
    .io_events_sets_2_value  (io_events_sets_2_value),
    .io_events_sets_3_value  (io_events_sets_3_value),
    .io_events_sets_4_value  (io_events_sets_4_value),
    .io_events_sets_5_value  (io_events_sets_5_value),
    .io_events_sets_6_value  (io_events_sets_6_value),
    .io_events_sets_7_value  (io_events_sets_7_value),
    .io_events_sets_8_value  (io_events_sets_8_value),
    .io_events_sets_9_value  (io_events_sets_9_value),
    .io_events_sets_10_value (io_events_sets_10_value),
    .io_events_sets_11_value (io_events_sets_11_value),
    .io_events_sets_12_value (io_events_sets_12_value),
    .io_events_sets_13_value (io_events_sets_13_value),
    .io_events_sets_14_value (io_events_sets_14_value),
    .io_events_sets_15_value (io_events_sets_15_value),
    .io_events_sets_16_value (io_events_sets_16_value),
    .io_events_sets_17_value (io_events_sets_17_value),
    .io_events_sets_18_value (io_events_sets_18_value),
    .io_events_sets_19_value (io_events_sets_19_value),
    .io_events_sets_20_value (io_events_sets_20_value),
    .io_events_sets_21_value (io_events_sets_21_value),
    .io_events_sets_22_value (io_events_sets_22_value),
    .io_events_sets_23_value (io_events_sets_23_value),
    .io_events_sets_24_value (io_events_sets_24_value),
    .io_events_sets_25_value (io_events_sets_25_value),
    .io_events_sets_26_value (io_events_sets_26_value),
    .io_events_sets_27_value (io_events_sets_27_value),
    .io_events_sets_28_value (io_events_sets_28_value),
    .io_events_sets_29_value (io_events_sets_29_value),
    .io_events_sets_30_value (io_events_sets_30_value),
    .io_events_sets_31_value (io_events_sets_31_value),
    .io_events_sets_32_value (io_events_sets_32_value),
    .io_events_sets_33_value (io_events_sets_33_value),
    .io_events_sets_34_value (io_events_sets_34_value),
    .io_events_sets_35_value (io_events_sets_35_value),
    .io_events_sets_36_value (io_events_sets_36_value),
    .io_events_sets_37_value (io_events_sets_37_value),
    .io_events_sets_38_value (io_events_sets_38_value),
    .io_events_sets_39_value (io_events_sets_39_value),
    .io_events_sets_40_value (io_events_sets_40_value),
    .io_events_sets_41_value (io_events_sets_41_value),
    .io_events_sets_42_value (io_events_sets_42_value),
    .io_events_sets_43_value (io_events_sets_43_value),
    .io_events_sets_44_value (io_events_sets_44_value),
    .io_events_sets_45_value (io_events_sets_45_value),
    .io_events_sets_46_value (io_events_sets_46_value),
    .io_events_sets_47_value (io_events_sets_47_value),
    .io_perf_0_value         (_perfEvents_hpc_3_io_perf_0_value)
  );
  HPerfCounter_8 perfEvents_hpc_4 (
    .clock                   (clock),
    .io_hpm_event            (io_hpm_event_4),
    .io_events_sets_0_value  (io_events_sets_0_value),
    .io_events_sets_1_value  (io_events_sets_1_value),
    .io_events_sets_2_value  (io_events_sets_2_value),
    .io_events_sets_3_value  (io_events_sets_3_value),
    .io_events_sets_4_value  (io_events_sets_4_value),
    .io_events_sets_5_value  (io_events_sets_5_value),
    .io_events_sets_6_value  (io_events_sets_6_value),
    .io_events_sets_7_value  (io_events_sets_7_value),
    .io_events_sets_8_value  (io_events_sets_8_value),
    .io_events_sets_9_value  (io_events_sets_9_value),
    .io_events_sets_10_value (io_events_sets_10_value),
    .io_events_sets_11_value (io_events_sets_11_value),
    .io_events_sets_12_value (io_events_sets_12_value),
    .io_events_sets_13_value (io_events_sets_13_value),
    .io_events_sets_14_value (io_events_sets_14_value),
    .io_events_sets_15_value (io_events_sets_15_value),
    .io_events_sets_16_value (io_events_sets_16_value),
    .io_events_sets_17_value (io_events_sets_17_value),
    .io_events_sets_18_value (io_events_sets_18_value),
    .io_events_sets_19_value (io_events_sets_19_value),
    .io_events_sets_20_value (io_events_sets_20_value),
    .io_events_sets_21_value (io_events_sets_21_value),
    .io_events_sets_22_value (io_events_sets_22_value),
    .io_events_sets_23_value (io_events_sets_23_value),
    .io_events_sets_24_value (io_events_sets_24_value),
    .io_events_sets_25_value (io_events_sets_25_value),
    .io_events_sets_26_value (io_events_sets_26_value),
    .io_events_sets_27_value (io_events_sets_27_value),
    .io_events_sets_28_value (io_events_sets_28_value),
    .io_events_sets_29_value (io_events_sets_29_value),
    .io_events_sets_30_value (io_events_sets_30_value),
    .io_events_sets_31_value (io_events_sets_31_value),
    .io_events_sets_32_value (io_events_sets_32_value),
    .io_events_sets_33_value (io_events_sets_33_value),
    .io_events_sets_34_value (io_events_sets_34_value),
    .io_events_sets_35_value (io_events_sets_35_value),
    .io_events_sets_36_value (io_events_sets_36_value),
    .io_events_sets_37_value (io_events_sets_37_value),
    .io_events_sets_38_value (io_events_sets_38_value),
    .io_events_sets_39_value (io_events_sets_39_value),
    .io_events_sets_40_value (io_events_sets_40_value),
    .io_events_sets_41_value (io_events_sets_41_value),
    .io_events_sets_42_value (io_events_sets_42_value),
    .io_events_sets_43_value (io_events_sets_43_value),
    .io_events_sets_44_value (io_events_sets_44_value),
    .io_events_sets_45_value (io_events_sets_45_value),
    .io_events_sets_46_value (io_events_sets_46_value),
    .io_events_sets_47_value (io_events_sets_47_value),
    .io_perf_0_value         (_perfEvents_hpc_4_io_perf_0_value)
  );
  assign io_perf_0_value = io_perf_0_value_REG_1;
  assign io_perf_1_value = io_perf_1_value_REG_1;
  assign io_perf_2_value = io_perf_2_value_REG_1;
  assign io_perf_3_value = io_perf_3_value_REG_1;
  assign io_perf_4_value = io_perf_4_value_REG_1;
endmodule


module HPerfCounter_8(
  input         clock,
  input  [63:0] io_hpm_event,
  input  [5:0]  io_events_sets_0_value,
  input  [5:0]  io_events_sets_1_value,
  input  [5:0]  io_events_sets_2_value,
  input  [5:0]  io_events_sets_3_value,
  input  [5:0]  io_events_sets_4_value,
  input  [5:0]  io_events_sets_5_value,
  input  [5:0]  io_events_sets_6_value,
  input  [5:0]  io_events_sets_7_value,
  input  [5:0]  io_events_sets_8_value,
  input  [5:0]  io_events_sets_9_value,
  input  [5:0]  io_events_sets_10_value,
  input  [5:0]  io_events_sets_11_value,
  input  [5:0]  io_events_sets_12_value,
  input  [5:0]  io_events_sets_13_value,
  input  [5:0]  io_events_sets_14_value,
  input  [5:0]  io_events_sets_15_value,
  input  [5:0]  io_events_sets_16_value,
  input  [5:0]  io_events_sets_17_value,
  input  [5:0]  io_events_sets_18_value,
  input  [5:0]  io_events_sets_19_value,
  input  [5:0]  io_events_sets_20_value,
  input  [5:0]  io_events_sets_21_value,
  input  [5:0]  io_events_sets_22_value,
  input  [5:0]  io_events_sets_23_value,
  input  [5:0]  io_events_sets_24_value,
  input  [5:0]  io_events_sets_25_value,
  input  [5:0]  io_events_sets_26_value,
  input  [5:0]  io_events_sets_27_value,
  input  [5:0]  io_events_sets_28_value,
  input  [5:0]  io_events_sets_29_value,
  input  [5:0]  io_events_sets_30_value,
  input  [5:0]  io_events_sets_31_value,
  input  [5:0]  io_events_sets_32_value,
  input  [5:0]  io_events_sets_33_value,
  input  [5:0]  io_events_sets_34_value,
  input  [5:0]  io_events_sets_35_value,
  input  [5:0]  io_events_sets_36_value,
  input  [5:0]  io_events_sets_37_value,
  input  [5:0]  io_events_sets_38_value,
  input  [5:0]  io_events_sets_39_value,
  input  [5:0]  io_events_sets_40_value,
  input  [5:0]  io_events_sets_41_value,
  input  [5:0]  io_events_sets_42_value,
  input  [5:0]  io_events_sets_43_value,
  input  [5:0]  io_events_sets_44_value,
  input  [5:0]  io_events_sets_45_value,
  input  [5:0]  io_events_sets_46_value,
  input  [5:0]  io_events_sets_47_value,
  output [5:0]  io_perf_0_value
);

  reg  [5:0]       events_incr_0_value;
  reg  [5:0]       events_incr_1_value;
  reg  [5:0]       events_incr_2_value;
  reg  [5:0]       events_incr_3_value;
  reg  [4:0]       event_op_0;
  reg  [4:0]       event_op_1;
  reg  [4:0]       event_op_2;
  reg  [4:0]       event_op_2_reg;
  reg  [5:0]       event_step_0_reg;
  reg  [5:0]       event_step_1_reg;
  reg  [5:0]       io_perf_0_value_REG;
  reg  [5:0]       io_perf_0_value_REG_1;
  wire [63:0][5:0] eventSelTable =
    {{io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_0_value},
     {io_events_sets_47_value},
     {io_events_sets_46_value},
     {io_events_sets_45_value},
     {io_events_sets_44_value},
     {io_events_sets_43_value},
     {io_events_sets_42_value},
     {io_events_sets_41_value},
     {io_events_sets_40_value},
     {io_events_sets_39_value},
     {io_events_sets_38_value},
     {io_events_sets_37_value},
     {io_events_sets_36_value},
     {io_events_sets_35_value},
     {io_events_sets_34_value},
     {io_events_sets_33_value},
     {io_events_sets_32_value},
     {io_events_sets_31_value},
     {io_events_sets_30_value},
     {io_events_sets_29_value},
     {io_events_sets_28_value},
     {io_events_sets_27_value},
     {io_events_sets_26_value},
     {io_events_sets_25_value},
     {io_events_sets_24_value},
     {io_events_sets_23_value},
     {io_events_sets_22_value},
     {io_events_sets_21_value},
     {io_events_sets_20_value},
     {io_events_sets_19_value},
     {io_events_sets_18_value},
     {io_events_sets_17_value},
     {io_events_sets_16_value},
     {io_events_sets_15_value},
     {io_events_sets_14_value},
     {io_events_sets_13_value},
     {io_events_sets_12_value},
     {io_events_sets_11_value},
     {io_events_sets_10_value},
     {io_events_sets_9_value},
     {io_events_sets_8_value},
     {io_events_sets_7_value},
     {io_events_sets_6_value},
     {io_events_sets_5_value},
     {io_events_sets_4_value},
     {io_events_sets_3_value},
     {io_events_sets_2_value},
     {io_events_sets_1_value},
     {io_events_sets_0_value}};
  always @(posedge clock) begin
    events_incr_0_value <= eventSelTable[io_hpm_event[5:0]];
    events_incr_1_value <= eventSelTable[io_hpm_event[15:10]];
    events_incr_2_value <= eventSelTable[io_hpm_event[25:20]];
    events_incr_3_value <= eventSelTable[io_hpm_event[35:30]];
    event_op_0 <= io_hpm_event[44:40];
    event_op_1 <= io_hpm_event[49:45];
    event_op_2 <= io_hpm_event[54:50];
    event_op_2_reg <= event_op_2;
    event_step_0_reg <=
      event_op_0[0]
        ? events_incr_0_value & events_incr_1_value
        : event_op_0[1]
            ? events_incr_0_value ^ events_incr_1_value
            : event_op_0[2]
                ? 6'(events_incr_0_value + events_incr_1_value)
                : events_incr_0_value | events_incr_1_value;
    event_step_1_reg <=
      event_op_1[0]
        ? events_incr_2_value & events_incr_3_value
        : event_op_1[1]
            ? events_incr_2_value ^ events_incr_3_value
            : event_op_1[2]
                ? 6'(events_incr_2_value + events_incr_3_value)
                : events_incr_2_value | events_incr_3_value;
    io_perf_0_value_REG <=
      event_op_2_reg[0]
        ? event_step_0_reg & event_step_1_reg
        : event_op_2_reg[1]
            ? event_step_0_reg ^ event_step_1_reg
            : event_op_2_reg[2]
                ? 6'(event_step_0_reg + event_step_1_reg)
                : event_step_0_reg | event_step_1_reg;
    io_perf_0_value_REG_1 <= io_perf_0_value_REG;
  end
  assign io_perf_0_value = io_perf_0_value_REG_1;
endmodule
