// 自动生成: _xs 变体(UT), 例化 xs_SnapshotGenerator_1_core。
module SnapshotGenerator_1_xs(
  input        clock,
  input        reset,
  input        io_enq,
  input        io_enqData_flag,
  input  [5:0] io_enqData_value,
  input        io_deq,
  input        io_redirect,
  input        io_flushVec_0,
  input        io_flushVec_1,
  input        io_flushVec_2,
  input        io_flushVec_3,
  output       io_snapshots_0_flag,
  output [5:0] io_snapshots_0_value,
  output       io_snapshots_1_flag,
  output [5:0] io_snapshots_1_value,
  output       io_snapshots_2_flag,
  output [5:0] io_snapshots_2_value,
  output       io_snapshots_3_flag,
  output [5:0] io_snapshots_3_value
);
  xs_SnapshotGenerator_1_core u_core (
    .clock(clock),
    .reset(reset),
    .io_enq(io_enq),
    .io_enqData_flag(io_enqData_flag),
    .io_enqData_value(io_enqData_value),
    .io_deq(io_deq),
    .io_redirect(io_redirect),
    .io_flushVec_0(io_flushVec_0),
    .io_flushVec_1(io_flushVec_1),
    .io_flushVec_2(io_flushVec_2),
    .io_flushVec_3(io_flushVec_3),
    .io_snapshots_0_flag(io_snapshots_0_flag),
    .io_snapshots_0_value(io_snapshots_0_value),
    .io_snapshots_1_flag(io_snapshots_1_flag),
    .io_snapshots_1_value(io_snapshots_1_value),
    .io_snapshots_2_flag(io_snapshots_2_flag),
    .io_snapshots_2_value(io_snapshots_2_value),
    .io_snapshots_3_flag(io_snapshots_3_flag),
    .io_snapshots_3_value(io_snapshots_3_value)
  );
endmodule
