// RASStack_xs —— UT 用变体（与 RAS_wrapper 同，仅模块名改为 RASStack_xs）
module RASStack_xs
  import xs_ras_pkg::*;
(
  input         clock,
  input         reset,
  input         io_spec_push_valid,
  input         io_spec_pop_valid,
  input  [49:0] io_spec_push_addr,
  input         io_s2_fire,
  input         io_s3_fire,
  input         io_s3_cancel,
  input  [3:0]  io_s3_meta_ssp,
  input  [2:0]  io_s3_meta_sctr,
  input         io_s3_meta_TOSW_flag,
  input  [4:0]  io_s3_meta_TOSW_value,
  input         io_s3_meta_TOSR_flag,
  input  [4:0]  io_s3_meta_TOSR_value,
  input         io_s3_meta_NOS_flag,
  input  [4:0]  io_s3_meta_NOS_value,
  input         io_s3_missed_pop,
  input         io_s3_missed_push,
  input  [49:0] io_s3_pushAddr,
  output [49:0] io_spec_pop_addr,
  input         io_commit_valid,
  input         io_commit_push_valid,
  input         io_commit_pop_valid,
  input         io_commit_meta_TOSW_flag,
  input  [4:0]  io_commit_meta_TOSW_value,
  input  [3:0]  io_commit_meta_ssp,
  input         io_redirect_valid,
  input         io_redirect_isCall,
  input         io_redirect_isRet,
  input  [3:0]  io_redirect_meta_ssp,
  input  [2:0]  io_redirect_meta_sctr,
  input         io_redirect_meta_TOSW_flag,
  input  [4:0]  io_redirect_meta_TOSW_value,
  input         io_redirect_meta_TOSR_flag,
  input  [4:0]  io_redirect_meta_TOSR_value,
  input         io_redirect_meta_NOS_flag,
  input  [4:0]  io_redirect_meta_NOS_value,
  input  [49:0] io_redirect_callAddr,
  output [3:0]  io_ssp,
  output [2:0]  io_sctr,
  output        io_TOSR_flag,
  output [4:0]  io_TOSR_value,
  output        io_TOSW_flag,
  output [4:0]  io_TOSW_value,
  output        io_NOS_flag,
  output [4:0]  io_NOS_value,
  output        io_spec_near_overflow
);

  // ---- flat → struct（指针打包）----
  ras_ptr_t s3_meta_TOSW, s3_meta_TOSR, s3_meta_NOS;
  ras_ptr_t commit_meta_TOSW;
  ras_ptr_t redirect_meta_TOSW, redirect_meta_TOSR, redirect_meta_NOS;
  assign s3_meta_TOSW       = '{flag: io_s3_meta_TOSW_flag,       value: io_s3_meta_TOSW_value};
  assign s3_meta_TOSR       = '{flag: io_s3_meta_TOSR_flag,       value: io_s3_meta_TOSR_value};
  assign s3_meta_NOS        = '{flag: io_s3_meta_NOS_flag,        value: io_s3_meta_NOS_value};
  assign commit_meta_TOSW   = '{flag: io_commit_meta_TOSW_flag,   value: io_commit_meta_TOSW_value};
  assign redirect_meta_TOSW = '{flag: io_redirect_meta_TOSW_flag, value: io_redirect_meta_TOSW_value};
  assign redirect_meta_TOSR = '{flag: io_redirect_meta_TOSR_flag, value: io_redirect_meta_TOSR_value};
  assign redirect_meta_NOS  = '{flag: io_redirect_meta_NOS_flag,  value: io_redirect_meta_NOS_value};

  // ---- struct → flat（指针拆包）----
  ras_ptr_t tosr_o, tosw_o, nos_o;
  assign io_TOSR_flag  = tosr_o.flag;
  assign io_TOSR_value = tosr_o.value;
  assign io_TOSW_flag  = tosw_o.flag;
  assign io_TOSW_value = tosw_o.value;
  assign io_NOS_flag   = nos_o.flag;
  assign io_NOS_value  = nos_o.value;

  xs_RASStack u_core (
    .clock                (clock),
    .reset                (reset),
    .spec_push_valid      (io_spec_push_valid),
    .spec_pop_valid       (io_spec_pop_valid),
    .spec_push_addr       (io_spec_push_addr),
    .spec_pop_addr        (io_spec_pop_addr),
    .s2_fire              (io_s2_fire),
    .s3_fire              (io_s3_fire),
    .s3_cancel            (io_s3_cancel),
    .s3_meta_ssp          (io_s3_meta_ssp),
    .s3_meta_sctr         (io_s3_meta_sctr),
    .s3_meta_TOSW         (s3_meta_TOSW),
    .s3_meta_TOSR         (s3_meta_TOSR),
    .s3_meta_NOS          (s3_meta_NOS),
    .s3_missed_pop        (io_s3_missed_pop),
    .s3_missed_push       (io_s3_missed_push),
    .s3_pushAddr          (io_s3_pushAddr),
    .commit_valid         (io_commit_valid),
    .commit_push_valid    (io_commit_push_valid),
    .commit_pop_valid     (io_commit_pop_valid),
    .commit_meta_TOSW     (commit_meta_TOSW),
    .commit_meta_ssp      (io_commit_meta_ssp),
    .redirect_valid       (io_redirect_valid),
    .redirect_isCall      (io_redirect_isCall),
    .redirect_isRet       (io_redirect_isRet),
    .redirect_meta_ssp    (io_redirect_meta_ssp),
    .redirect_meta_sctr   (io_redirect_meta_sctr),
    .redirect_meta_TOSW   (redirect_meta_TOSW),
    .redirect_meta_TOSR   (redirect_meta_TOSR),
    .redirect_meta_NOS    (redirect_meta_NOS),
    .redirect_callAddr    (io_redirect_callAddr),
    .ssp_o                (io_ssp),
    .sctr_o               (io_sctr),
    .TOSR_o               (tosr_o),
    .TOSW_o               (tosw_o),
    .NOS_o                (nos_o),
    .spec_near_overflow_o (io_spec_near_overflow)
  );

endmodule
