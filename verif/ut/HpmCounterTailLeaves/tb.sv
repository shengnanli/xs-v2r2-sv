`timescale 1ns/1ps

// Differential UT for the childless HPM CSR tail leaves.
// HPM leaves compare the live/debug snapshot path; machine leaves compare
// CSR write priority, event accumulation, inhibit selection, and overflow.
module tb;
  localparam int NHPM = 21;
  localparam int NMHPM = 29;
  int unsigned ncycles = 200000;
  int unsigned seed = 1;
  int unsigned cycle;
  int errors = 0;
  longint unsigned checks = 0;
  longint unsigned hpm_updates = 0;
  longint unsigned hpm_stop_cycles = 0;
  longint unsigned mhpm_writes = 0;
  longint unsigned mhpm_events = 0;
  longint unsigned mhpm_inhibited = 0;
  longint unsigned mhpm_overflows = 0;
  longint unsigned reset_events = 0;

  logic clock = 1'b0;
  logic reset = 1'b1;
  logic [63:0] live_counter [0:NHPM-1];
  logic debug_stop_count = 1'b0;
  logic count_update = 1'b0;
  logic w_wen = 1'b0;
  logic [63:0] w_wdata = 64'b0;
  logic mcountinhibit_CY = 1'b0;
  logic mcountinhibit_IR = 1'b0;
  logic [28:0] mcountinhibit_HPM3 = 29'b0;
  logic countingEn = 1'b1;
  logic [5:0] perf_value = 6'b0;

  wire [63:0] hpm_golden [0:NHPM-1];
  wire [63:0] hpm_readable [0:NHPM-1];
  wire [63:0] mhpm_golden [0:NMHPM-1];
  wire [63:0] mhpm_readable [0:NMHPM-1];
  wire mhpm_of_golden [0:NMHPM-1];
  wire mhpm_of_readable [0:NMHPM-1];

  Hpmcounter11Module g_hpm_11 (.clock(clock), .reset(reset), .rdata(hpm_golden[0]), .mHPM_hpmcounters_8(live_counter[0]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter12Module g_hpm_12 (.clock(clock), .reset(reset), .rdata(hpm_golden[1]), .mHPM_hpmcounters_9(live_counter[1]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter13Module g_hpm_13 (.clock(clock), .reset(reset), .rdata(hpm_golden[2]), .mHPM_hpmcounters_10(live_counter[2]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter14Module g_hpm_14 (.clock(clock), .reset(reset), .rdata(hpm_golden[3]), .mHPM_hpmcounters_11(live_counter[3]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter15Module g_hpm_15 (.clock(clock), .reset(reset), .rdata(hpm_golden[4]), .mHPM_hpmcounters_12(live_counter[4]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter16Module g_hpm_16 (.clock(clock), .reset(reset), .rdata(hpm_golden[5]), .mHPM_hpmcounters_13(live_counter[5]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter17Module g_hpm_17 (.clock(clock), .reset(reset), .rdata(hpm_golden[6]), .mHPM_hpmcounters_14(live_counter[6]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter18Module g_hpm_18 (.clock(clock), .reset(reset), .rdata(hpm_golden[7]), .mHPM_hpmcounters_15(live_counter[7]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter19Module g_hpm_19 (.clock(clock), .reset(reset), .rdata(hpm_golden[8]), .mHPM_hpmcounters_16(live_counter[8]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter20Module g_hpm_20 (.clock(clock), .reset(reset), .rdata(hpm_golden[9]), .mHPM_hpmcounters_17(live_counter[9]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter21Module g_hpm_21 (.clock(clock), .reset(reset), .rdata(hpm_golden[10]), .mHPM_hpmcounters_18(live_counter[10]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter22Module g_hpm_22 (.clock(clock), .reset(reset), .rdata(hpm_golden[11]), .mHPM_hpmcounters_19(live_counter[11]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter23Module g_hpm_23 (.clock(clock), .reset(reset), .rdata(hpm_golden[12]), .mHPM_hpmcounters_20(live_counter[12]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter24Module g_hpm_24 (.clock(clock), .reset(reset), .rdata(hpm_golden[13]), .mHPM_hpmcounters_21(live_counter[13]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter25Module g_hpm_25 (.clock(clock), .reset(reset), .rdata(hpm_golden[14]), .mHPM_hpmcounters_22(live_counter[14]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter26Module g_hpm_26 (.clock(clock), .reset(reset), .rdata(hpm_golden[15]), .mHPM_hpmcounters_23(live_counter[15]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter27Module g_hpm_27 (.clock(clock), .reset(reset), .rdata(hpm_golden[16]), .mHPM_hpmcounters_24(live_counter[16]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter28Module g_hpm_28 (.clock(clock), .reset(reset), .rdata(hpm_golden[17]), .mHPM_hpmcounters_25(live_counter[17]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter29Module g_hpm_29 (.clock(clock), .reset(reset), .rdata(hpm_golden[18]), .mHPM_hpmcounters_26(live_counter[18]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter30Module g_hpm_30 (.clock(clock), .reset(reset), .rdata(hpm_golden[19]), .mHPM_hpmcounters_27(live_counter[19]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter31Module g_hpm_31 (.clock(clock), .reset(reset), .rdata(hpm_golden[20]), .mHPM_hpmcounters_28(live_counter[20]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter11Module_xs i_hpm_11 (.clock(clock), .reset(reset), .rdata(hpm_readable[0]), .mHPM_hpmcounters_8(live_counter[0]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter12Module_xs i_hpm_12 (.clock(clock), .reset(reset), .rdata(hpm_readable[1]), .mHPM_hpmcounters_9(live_counter[1]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter13Module_xs i_hpm_13 (.clock(clock), .reset(reset), .rdata(hpm_readable[2]), .mHPM_hpmcounters_10(live_counter[2]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter14Module_xs i_hpm_14 (.clock(clock), .reset(reset), .rdata(hpm_readable[3]), .mHPM_hpmcounters_11(live_counter[3]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter15Module_xs i_hpm_15 (.clock(clock), .reset(reset), .rdata(hpm_readable[4]), .mHPM_hpmcounters_12(live_counter[4]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter16Module_xs i_hpm_16 (.clock(clock), .reset(reset), .rdata(hpm_readable[5]), .mHPM_hpmcounters_13(live_counter[5]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter17Module_xs i_hpm_17 (.clock(clock), .reset(reset), .rdata(hpm_readable[6]), .mHPM_hpmcounters_14(live_counter[6]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter18Module_xs i_hpm_18 (.clock(clock), .reset(reset), .rdata(hpm_readable[7]), .mHPM_hpmcounters_15(live_counter[7]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter19Module_xs i_hpm_19 (.clock(clock), .reset(reset), .rdata(hpm_readable[8]), .mHPM_hpmcounters_16(live_counter[8]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter20Module_xs i_hpm_20 (.clock(clock), .reset(reset), .rdata(hpm_readable[9]), .mHPM_hpmcounters_17(live_counter[9]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter21Module_xs i_hpm_21 (.clock(clock), .reset(reset), .rdata(hpm_readable[10]), .mHPM_hpmcounters_18(live_counter[10]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter22Module_xs i_hpm_22 (.clock(clock), .reset(reset), .rdata(hpm_readable[11]), .mHPM_hpmcounters_19(live_counter[11]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter23Module_xs i_hpm_23 (.clock(clock), .reset(reset), .rdata(hpm_readable[12]), .mHPM_hpmcounters_20(live_counter[12]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter24Module_xs i_hpm_24 (.clock(clock), .reset(reset), .rdata(hpm_readable[13]), .mHPM_hpmcounters_21(live_counter[13]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter25Module_xs i_hpm_25 (.clock(clock), .reset(reset), .rdata(hpm_readable[14]), .mHPM_hpmcounters_22(live_counter[14]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter26Module_xs i_hpm_26 (.clock(clock), .reset(reset), .rdata(hpm_readable[15]), .mHPM_hpmcounters_23(live_counter[15]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter27Module_xs i_hpm_27 (.clock(clock), .reset(reset), .rdata(hpm_readable[16]), .mHPM_hpmcounters_24(live_counter[16]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter28Module_xs i_hpm_28 (.clock(clock), .reset(reset), .rdata(hpm_readable[17]), .mHPM_hpmcounters_25(live_counter[17]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter29Module_xs i_hpm_29 (.clock(clock), .reset(reset), .rdata(hpm_readable[18]), .mHPM_hpmcounters_26(live_counter[18]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter30Module_xs i_hpm_30 (.clock(clock), .reset(reset), .rdata(hpm_readable[19]), .mHPM_hpmcounters_27(live_counter[19]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Hpmcounter31Module_xs i_hpm_31 (.clock(clock), .reset(reset), .rdata(hpm_readable[20]), .mHPM_hpmcounters_28(live_counter[20]), .debugModeStopCount(debug_stop_count), .unprivCountUpdate(count_update));
  Mhpmcounter3Module g_mhpm_3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[0]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[0]));
  Mhpmcounter4Module g_mhpm_4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[1]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[1]));
  Mhpmcounter5Module g_mhpm_5 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[2]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[2]));
  Mhpmcounter6Module g_mhpm_6 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[3]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[3]));
  Mhpmcounter7Module g_mhpm_7 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[4]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[4]));
  Mhpmcounter8Module g_mhpm_8 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[5]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[5]));
  Mhpmcounter9Module g_mhpm_9 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[6]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[6]));
  Mhpmcounter10Module g_mhpm_10 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[7]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[7]));
  Mhpmcounter11Module g_mhpm_11 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[8]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[8]));
  Mhpmcounter12Module g_mhpm_12 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[9]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[9]));
  Mhpmcounter13Module g_mhpm_13 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[10]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[10]));
  Mhpmcounter14Module g_mhpm_14 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[11]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[11]));
  Mhpmcounter15Module g_mhpm_15 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[12]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[12]));
  Mhpmcounter16Module g_mhpm_16 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[13]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[13]));
  Mhpmcounter17Module g_mhpm_17 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[14]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[14]));
  Mhpmcounter18Module g_mhpm_18 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[15]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[15]));
  Mhpmcounter19Module g_mhpm_19 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[16]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[16]));
  Mhpmcounter20Module g_mhpm_20 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[17]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[17]));
  Mhpmcounter21Module g_mhpm_21 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[18]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[18]));
  Mhpmcounter22Module g_mhpm_22 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[19]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[19]));
  Mhpmcounter23Module g_mhpm_23 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[20]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[20]));
  Mhpmcounter24Module g_mhpm_24 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[21]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[21]));
  Mhpmcounter25Module g_mhpm_25 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[22]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[22]));
  Mhpmcounter26Module g_mhpm_26 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[23]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[23]));
  Mhpmcounter27Module g_mhpm_27 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[24]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[24]));
  Mhpmcounter28Module g_mhpm_28 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[25]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[25]));
  Mhpmcounter29Module g_mhpm_29 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[26]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[26]));
  Mhpmcounter30Module g_mhpm_30 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[27]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[27]));
  Mhpmcounter31Module g_mhpm_31 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_golden[28]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_golden[28]));
  Mhpmcounter3Module_xs i_mhpm_3 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[0]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[0]));
  Mhpmcounter4Module_xs i_mhpm_4 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[1]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[1]));
  Mhpmcounter5Module_xs i_mhpm_5 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[2]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[2]));
  Mhpmcounter6Module_xs i_mhpm_6 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[3]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[3]));
  Mhpmcounter7Module_xs i_mhpm_7 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[4]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[4]));
  Mhpmcounter8Module_xs i_mhpm_8 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[5]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[5]));
  Mhpmcounter9Module_xs i_mhpm_9 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[6]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[6]));
  Mhpmcounter10Module_xs i_mhpm_10 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[7]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[7]));
  Mhpmcounter11Module_xs i_mhpm_11 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[8]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[8]));
  Mhpmcounter12Module_xs i_mhpm_12 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[9]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[9]));
  Mhpmcounter13Module_xs i_mhpm_13 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[10]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[10]));
  Mhpmcounter14Module_xs i_mhpm_14 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[11]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[11]));
  Mhpmcounter15Module_xs i_mhpm_15 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[12]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[12]));
  Mhpmcounter16Module_xs i_mhpm_16 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[13]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[13]));
  Mhpmcounter17Module_xs i_mhpm_17 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[14]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[14]));
  Mhpmcounter18Module_xs i_mhpm_18 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[15]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[15]));
  Mhpmcounter19Module_xs i_mhpm_19 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[16]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[16]));
  Mhpmcounter20Module_xs i_mhpm_20 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[17]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[17]));
  Mhpmcounter21Module_xs i_mhpm_21 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[18]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[18]));
  Mhpmcounter22Module_xs i_mhpm_22 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[19]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[19]));
  Mhpmcounter23Module_xs i_mhpm_23 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[20]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[20]));
  Mhpmcounter24Module_xs i_mhpm_24 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[21]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[21]));
  Mhpmcounter25Module_xs i_mhpm_25 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[22]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[22]));
  Mhpmcounter26Module_xs i_mhpm_26 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[23]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[23]));
  Mhpmcounter27Module_xs i_mhpm_27 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[24]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[24]));
  Mhpmcounter28Module_xs i_mhpm_28 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[25]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[25]));
  Mhpmcounter29Module_xs i_mhpm_29 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[26]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[26]));
  Mhpmcounter30Module_xs i_mhpm_30 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[27]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[27]));
  Mhpmcounter31Module_xs i_mhpm_31 (.clock(clock), .reset(reset), .w_wen(w_wen), .w_wdata(w_wdata), .rdata(mhpm_readable[28]), .regOut_ALL(), .mcountinhibit_CY(mcountinhibit_CY), .mcountinhibit_IR(mcountinhibit_IR), .mcountinhibit_HPM3(mcountinhibit_HPM3), .countingEn(countingEn), .perf_value(perf_value), .toMhpmeventOF(mhpm_of_readable[28]));

  always #5 clock = ~clock;

  task automatic compare_outputs;
    int i;
    begin
      #1;
      for (i = 0; i < NHPM; i++) begin
        checks++;
        if (hpm_golden[i] !== hpm_readable[i]) begin
          errors++;
          if (errors <= 12) $display("HPM mismatch index=%0d golden=%h readable=%h", i+8, hpm_golden[i], hpm_readable[i]);
        end
      end
      for (i = 0; i < NMHPM; i++) begin
        checks++;
        if (mhpm_golden[i] !== mhpm_readable[i] || mhpm_of_golden[i] !== mhpm_of_readable[i]) begin
          errors++;
          if (errors <= 12) $display("mHPM mismatch index=%0d golden=%h/%b readable=%h/%b", i, mhpm_golden[i], mhpm_of_golden[i], mhpm_readable[i], mhpm_of_readable[i]);
        end
      end
    end
  endtask

  task automatic drive(input int unsigned step);
    int i;
    begin
      // Directed prefix hits reset, all live reads, snapshot capture, hold,
      // CSR-write priority, each inhibit bit, and an overflow carry.
      if (step == 0) begin
        reset = 1'b1; reset_events++; debug_stop_count = 1'b0; count_update = 1'b0;
        w_wen = 1'b0; w_wdata = 64'b0; mcountinhibit_HPM3 = 29'b0; countingEn = 1'b1; perf_value = 6'd0;
      end else if (step == 1) begin
        reset = 1'b0; debug_stop_count = 1'b0; count_update = 1'b0;
        w_wen = 1'b1; w_wdata = 64'h0123_4567_89ab_cdef; mcountinhibit_HPM3 = 29'b0; countingEn = 1'b1; perf_value = 6'd0;
      end else if (step == 2) begin
        reset = 1'b0; debug_stop_count = 1'b1; count_update = 1'b1;
        w_wen = 1'b0; w_wdata = 64'h0; mcountinhibit_HPM3 = 29'b0; countingEn = 1'b1; perf_value = 6'd0;
      end else if (step == 3) begin
        reset = 1'b0; debug_stop_count = 1'b1; count_update = 1'b0;
        w_wen = 1'b0; w_wdata = 64'h0; mcountinhibit_HPM3 = 29'b0; countingEn = 1'b0; perf_value = 6'd63;
      end else if (step == 4) begin
        reset = 1'b0; debug_stop_count = 1'b0; count_update = 1'b0;
        w_wen = 1'b1; w_wdata = 64'hffff_ffff_ffff_fffc; mcountinhibit_HPM3 = 29'b0; countingEn = 1'b1; perf_value = 6'd7;
      end else if (step == 5) begin
        reset = 1'b0; debug_stop_count = 1'b0; count_update = 1'b0;
        w_wen = 1'b0; w_wdata = 64'h0; mcountinhibit_HPM3 = 29'b1; countingEn = 1'b1; perf_value = 6'd63;
      end else begin
        reset = 1'b0;
        debug_stop_count = (($urandom_range(0, 99)) < 37);
        count_update = (($urandom_range(0, 99)) < 17);
        w_wen = (($urandom_range(0, 99)) < 19);
        w_wdata = {$urandom, $urandom};
        mcountinhibit_HPM3 = $urandom;
        countingEn = (($urandom_range(0, 99)) < 83);
        perf_value = $urandom_range(0, 63);
      end
      for (i = 0; i < NHPM; i++) live_counter[i] = {$urandom, $urandom};
      if (count_update) hpm_updates++;
      if (debug_stop_count) hpm_stop_cycles++;
      if (w_wen) mhpm_writes++;
      if (|perf_value) mhpm_events++;
      if (!countingEn || (|mcountinhibit_HPM3)) mhpm_inhibited++;
    end
  endtask

  initial begin
    void'($value$plusargs("ntb_random_seed=%d", seed));
    void'($value$plusargs("ncycles=%d", ncycles));
    void'($urandom(seed));
    for (int i = 0; i < NHPM; i++) live_counter[i] = 64'b0;
    drive(0);
    repeat (2) @(posedge clock);
    compare_outputs();
    for (cycle = 1; cycle < ncycles; cycle++) begin
      @(negedge clock);
      drive(cycle);
      @(posedge clock);
      compare_outputs();
    end
    $display("HpmCounterTailLeaves seed=%0d cycles=%0d checks=%0d errors=%0d hpm_updates=%0d hpm_stop=%0d mhpm_writes=%0d mhpm_events=%0d mhpm_inhibited=%0d", seed, ncycles, checks, errors, hpm_updates, hpm_stop_cycles, mhpm_writes, mhpm_events, mhpm_inhibited);
    if (hpm_updates == 0 || hpm_stop_cycles == 0 || mhpm_writes == 0 || mhpm_events == 0 || mhpm_inhibited == 0) begin
      $display("COVERAGE HOLE: HPM tail stimulus did not exercise every control class");
      errors++;
    end
    if (checks < (NHPM + NMHPM) * ncycles) begin
      $display("CHECK GUARD FAILED: checks=%0d expected_at_least=%0d", checks, (NHPM + NMHPM) * ncycles);
      errors++;
    end
    if (errors == 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
