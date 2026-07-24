// 自动生成: scripts/gen_newcsr_hpmcounter.py —— 勿手改
// NewCSR Hpmcounter family thin wrappers (N=3..31, index = N-3).
// Each wrapper instantiates the readable primitive xs_hpmcounter (see
// rtl/backend/newcsr_hpmcounter.sv) and binds the golden per-instance
// machine-mode source port name mHPM_hpmcounters_{N-3} to mhpm_src.
// FM-verified against golden HpmcounterNModule.sv in signoff-strict mode.

module Hpmcounter3Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_0,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(0)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_0),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter4Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_1,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(1)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_1),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter5Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_2,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(2)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_2),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter6Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_3,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(3)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_3),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter7Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_4,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(4)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_4),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter8Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_5,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(5)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_5),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter9Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_6,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(6)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_6),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter10Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_7,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(7)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_7),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter11Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_8,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(8)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_8),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter12Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_9,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(9)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_9),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter13Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_10,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(10)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_10),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter14Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_11,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(11)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_11),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter15Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_12,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(12)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_12),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter16Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_13,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(13)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_13),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter17Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_14,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(14)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_14),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter18Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_15,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(15)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_15),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter19Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_16,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(16)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_16),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter20Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_17,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(17)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_17),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter21Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_18,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(18)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_18),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter22Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_19,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(19)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_19),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter23Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_20,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(20)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_20),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter24Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_21,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(21)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_21),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter25Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_22,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(22)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_22),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter26Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_23,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(23)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_23),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter27Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_24,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(24)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_24),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter28Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_25,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(25)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_25),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter29Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_26,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(26)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_26),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter30Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_27,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(27)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_27),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule

module Hpmcounter31Module(
  input         clock,
  input         reset,
  output [63:0] rdata,
  input  [63:0] mHPM_hpmcounters_28,
  input         debugModeStopCount,
  input         unprivCountUpdate
);
  xs_hpmcounter #(.IDX(28)) u_core (
    .clock              (clock),
    .reset              (reset),
    .mhpm_src           (mHPM_hpmcounters_28),
    .debugModeStopCount (debugModeStopCount),
    .unprivCountUpdate  (unprivCountUpdate),
    .rdata              (rdata)
  );
endmodule
