// 自动生成: golden 同名 wrapper(FM impl), 例化 xs_SnapshotGenerator_3_core。
module SnapshotGenerator_3(
  input clock,
  input reset,
  input io_enq,
  input io_enqData_0_flag,
  input [7:0] io_enqData_0_value,
  input io_deq,
  input io_redirect,
  input io_flushVec_0,
  input io_flushVec_1,
  input io_flushVec_2,
  input io_flushVec_3,
  output io_snapshots_0_0_flag,
  output [7:0] io_snapshots_0_0_value,
  output io_snapshots_1_0_flag,
  output [7:0] io_snapshots_1_0_value,
  output io_snapshots_2_0_flag,
  output [7:0] io_snapshots_2_0_value,
  output io_snapshots_3_0_flag,
  output [7:0] io_snapshots_3_0_value
);
  xs_SnapshotGenerator_3_core u_core (
    .clock(clock),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_0_flag(io_enqData_0_flag),
    .io_enqData_0_value(io_enqData_0_value),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_0_flag(io_snapshots_0_0_flag),
    .io_snapshots_0_0_value(io_snapshots_0_0_value),
    .io_snapshots_1_0_flag(io_snapshots_1_0_flag),
    .io_snapshots_1_0_value(io_snapshots_1_0_value),
    .io_snapshots_2_0_flag(io_snapshots_2_0_flag),
    .io_snapshots_2_0_value(io_snapshots_2_0_value),
    .io_snapshots_3_0_flag(io_snapshots_3_0_flag),
    .io_snapshots_3_0_value(io_snapshots_3_0_value)
  );
endmodule
