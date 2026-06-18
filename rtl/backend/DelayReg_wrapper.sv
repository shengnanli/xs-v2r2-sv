// =============================================================================
// DelayReg (wrapper) —— golden 同名顶层,端口与 golden/chisel-rtl/DelayReg.sv 一致。
// -----------------------------------------------------------------------------
// 作用:把 DiffInstrCommit payload 的 42 个展平端口打包成 diff_commit_t struct,
//   交给通用延迟核 xs_delay_reg_core(N=3)整体打 3 拍,再拆回展平端口。
//   本层是机械的「端口 <-> struct」适配 + 直通,核心延迟逻辑在 core 里。
// =============================================================================
module DelayReg
  import delayreg_pkg::*;
(
  input         clock,
  input         reset,
  input         i_valid,
  input         i_skip,
  input         i_isRVC,
  input         i_rfwen,
  input         i_fpwen,
  input         i_vecwen,
  input         i_v0wen,
  input  [7:0]  i_wpdest,
  input  [7:0]  i_wdest,
  input  [7:0]  i_otherwpdest_0,
  input  [7:0]  i_otherwpdest_1,
  input  [7:0]  i_otherwpdest_2,
  input  [7:0]  i_otherwpdest_3,
  input  [7:0]  i_otherwpdest_4,
  input  [7:0]  i_otherwpdest_5,
  input  [7:0]  i_otherwpdest_6,
  input  [7:0]  i_otherwpdest_7,
  input  [7:0]  i_nFused,
  input  [7:0]  i_coreid,
  input  [7:0]  i_index,
  output        o_valid,
  output        o_skip,
  output        o_isRVC,
  output        o_rfwen,
  output        o_fpwen,
  output        o_vecwen,
  output        o_v0wen,
  output [7:0]  o_wpdest,
  output [7:0]  o_wdest,
  output [7:0]  o_otherwpdest_0,
  output [7:0]  o_otherwpdest_1,
  output [7:0]  o_otherwpdest_2,
  output [7:0]  o_otherwpdest_3,
  output [7:0]  o_otherwpdest_4,
  output [7:0]  o_otherwpdest_5,
  output [7:0]  o_otherwpdest_6,
  output [7:0]  o_otherwpdest_7,
  output [7:0]  o_nFused,
  output [7:0]  o_coreid,
  output [7:0]  o_index
);

  // 展平输入 -> struct。
  diff_commit_t din, dout;
  always_comb begin
    din.valid          = i_valid;
    din.skip           = i_skip;
    din.isRVC          = i_isRVC;
    din.rfwen          = i_rfwen;
    din.fpwen          = i_fpwen;
    din.vecwen         = i_vecwen;
    din.v0wen          = i_v0wen;
    din.wpdest         = i_wpdest;
    din.wdest          = i_wdest;
    din.otherwpdest[0] = i_otherwpdest_0;
    din.otherwpdest[1] = i_otherwpdest_1;
    din.otherwpdest[2] = i_otherwpdest_2;
    din.otherwpdest[3] = i_otherwpdest_3;
    din.otherwpdest[4] = i_otherwpdest_4;
    din.otherwpdest[5] = i_otherwpdest_5;
    din.otherwpdest[6] = i_otherwpdest_6;
    din.otherwpdest[7] = i_otherwpdest_7;
    din.nFused         = i_nFused;
    din.coreid         = i_coreid;
    din.index          = i_index;
  end

  // 通用延迟核:整个 payload 打 DELAY_N(=3) 拍。
  xs_delay_reg_core #(
    .WIDTH($bits(diff_commit_t)),
    .N    (DELAY_N)
  ) u_core (
    .clock(clock),
    .reset(reset),
    .in   (din),
    .out  (dout)
  );

  // struct -> 展平输出。
  assign o_valid         = dout.valid;
  assign o_skip          = dout.skip;
  assign o_isRVC         = dout.isRVC;
  assign o_rfwen         = dout.rfwen;
  assign o_fpwen         = dout.fpwen;
  assign o_vecwen        = dout.vecwen;
  assign o_v0wen         = dout.v0wen;
  assign o_wpdest        = dout.wpdest;
  assign o_wdest         = dout.wdest;
  assign o_otherwpdest_0 = dout.otherwpdest[0];
  assign o_otherwpdest_1 = dout.otherwpdest[1];
  assign o_otherwpdest_2 = dout.otherwpdest[2];
  assign o_otherwpdest_3 = dout.otherwpdest[3];
  assign o_otherwpdest_4 = dout.otherwpdest[4];
  assign o_otherwpdest_5 = dout.otherwpdest[5];
  assign o_otherwpdest_6 = dout.otherwpdest[6];
  assign o_otherwpdest_7 = dout.otherwpdest[7];
  assign o_nFused        = dout.nFused;
  assign o_coreid        = dout.coreid;
  assign o_index         = dout.index;

endmodule
