// 自动生成:scripts/gen_exeunit.py（ExeUnit_8）—— 勿手改(逻辑为从设计意图的可读重写)

// FU / Dispatcher(in1ToN) / ClockGate 黑盒例化 + 端口连线 + §3 输出仲裁。
// FU 与 Dispatcher、ClockGate 在 UT/FM 两侧均为 golden 黑盒(它们是 FU/分发实体)。
// 本表把可读核的流水/门控信号接到这些黑盒;无 golden _GEN_/_T_ 名。

  FAlu Falu (
    .clock (_ClockGate_Q),
    .reset (reset),
    .io_in_valid (_in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType (_in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrl_fpu_fmt (_in1ToN_io_out_0_bits_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm (_in1ToN_io_out_0_bits_fpu_rm),
    .io_in_bits_ctrlPipe_1_robIdx_flag (ctrl_pipe[0].robIdx_flag),
    .io_in_bits_ctrlPipe_1_robIdx_value (ctrl_pipe[0].robIdx_value),
    .io_in_bits_ctrlPipe_1_pdest (ctrl_pipe[0].pdest),
    .io_in_bits_ctrlPipe_1_rfWen (ctrl_pipe[0].rfWen),
    .io_in_bits_ctrlPipe_1_fpWen (ctrl_pipe[0].fpWen),
    .io_in_bits_ctrlPipe_1_fpu_wflags (ctrl_pipe[0].fpu_wflags),
    .io_in_bits_validPipe_1 (valid_pipe[0]),
    .io_in_bits_data_src_1 (io_in_bits_src_1),
    .io_in_bits_data_src_0 (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (_in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (_in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_out_valid (_Falu_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (_Falu_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (_Falu_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (_Falu_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (_Falu_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_fpWen (_Falu_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags (_Falu_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data (_Falu_io_out_bits_res_data),
    .io_out_bits_res_fflags (_Falu_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_enqRsTime (_Falu_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (_Falu_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (_Falu_io_out_bits_perfDebugInfo_issueTime),
    .io_frm (io_frm)
  );

  FCVT Fcvt (
    .clock (_ClockGate_1_Q),
    .reset (reset),
    .io_in_valid (_in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType (_in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrl_fpu_fmt (_in1ToN_io_out_1_bits_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm (_in1ToN_io_out_1_bits_fpu_rm),
    .io_in_bits_ctrlPipe_2_fuOpType (ctrl_pipe[1].fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag (ctrl_pipe[1].robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value (ctrl_pipe[1].robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest (ctrl_pipe[1].pdest),
    .io_in_bits_ctrlPipe_2_rfWen (ctrl_pipe[1].rfWen),
    .io_in_bits_ctrlPipe_2_fpWen (ctrl_pipe[1].fpWen),
    .io_in_bits_ctrlPipe_2_fpu_wflags (ctrl_pipe[1].fpu_wflags),
    .io_in_bits_validPipe_2 (valid_pipe[1]),
    .io_in_bits_data_src_0 (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (_in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (_in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_out_valid (_Fcvt_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (_Fcvt_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (_Fcvt_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (_Fcvt_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (_Fcvt_io_out_bits_ctrl_rfWen),
    .io_out_bits_ctrl_fpWen (_Fcvt_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags (_Fcvt_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data (_Fcvt_io_out_bits_res_data),
    .io_out_bits_res_fflags (_Fcvt_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_enqRsTime (_Fcvt_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (_Fcvt_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (_Fcvt_io_out_bits_perfDebugInfo_issueTime),
    .io_frm (io_frm)
  );

  IntFPToVec f2v (
    .io_in_valid (_in1ToN_io_out_2_valid),
    .io_in_bits_ctrl_fuOpType (_in1ToN_io_out_2_bits_fuOpType),
    .io_in_bits_ctrl_robIdx_flag (_in1ToN_io_out_2_bits_robIdx_flag),
    .io_in_bits_ctrl_robIdx_value (_in1ToN_io_out_2_bits_robIdx_value),
    .io_in_bits_ctrl_pdest (_in1ToN_io_out_2_bits_pdest),
    .io_in_bits_ctrl_fpWen (_in1ToN_io_out_2_bits_fpWen),
    .io_in_bits_ctrl_vecWen (_in1ToN_io_out_2_bits_vecWen),
    .io_in_bits_ctrl_v0Wen (_in1ToN_io_out_2_bits_v0Wen),
    .io_in_bits_validPipe_0 (io_in_valid),
    .io_in_bits_data_src_1 (io_in_bits_src_1),
    .io_in_bits_data_src_0 (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (_in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (_in1ToN_io_out_2_bits_perfDebugInfo_issueTime),
    .io_out_valid (_f2v_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (_f2v_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (_f2v_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (_f2v_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen (_f2v_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_vecWen (_f2v_io_out_bits_ctrl_vecWen),
    .io_out_bits_ctrl_v0Wen (_f2v_io_out_bits_ctrl_v0Wen),
    .io_out_bits_res_data (_f2v_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime (_f2v_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (_f2v_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (_f2v_io_out_bits_perfDebugInfo_issueTime)
  );

  FMA Fmac (
    .clock (_ClockGate_2_Q),
    .reset (reset),
    .io_in_valid (_in1ToN_io_out_3_valid),
    .io_in_bits_ctrl_fuOpType (_in1ToN_io_out_3_bits_fuOpType),
    .io_in_bits_ctrl_fpu_fmt (_in1ToN_io_out_3_bits_fpu_fmt),
    .io_in_bits_ctrl_fpu_rm (_in1ToN_io_out_3_bits_fpu_rm),
    .io_in_bits_ctrlPipe_3_robIdx_flag (ctrl_pipe[2].robIdx_flag),
    .io_in_bits_ctrlPipe_3_robIdx_value (ctrl_pipe[2].robIdx_value),
    .io_in_bits_ctrlPipe_3_pdest (ctrl_pipe[2].pdest),
    .io_in_bits_ctrlPipe_3_fpWen (ctrl_pipe[2].fpWen),
    .io_in_bits_ctrlPipe_3_fpu_wflags (ctrl_pipe[2].fpu_wflags),
    .io_in_bits_validPipe_3 (valid_pipe[2]),
    .io_in_bits_data_src_2 (io_in_bits_src_2),
    .io_in_bits_data_src_1 (io_in_bits_src_1),
    .io_in_bits_data_src_0 (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (_in1ToN_io_out_3_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (_in1ToN_io_out_3_bits_perfDebugInfo_issueTime),
    .io_out_valid (_Fmac_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (_Fmac_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (_Fmac_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (_Fmac_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_fpWen (_Fmac_io_out_bits_ctrl_fpWen),
    .io_out_bits_ctrl_fpu_wflags (_Fmac_io_out_bits_ctrl_fpu_wflags),
    .io_out_bits_res_data (_Fmac_io_out_bits_res_data),
    .io_out_bits_res_fflags (_Fmac_io_out_bits_res_fflags),
    .io_out_bits_perfDebugInfo_enqRsTime (_Fmac_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (_Fmac_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (_Fmac_io_out_bits_perfDebugInfo_issueTime),
    .io_frm (io_frm)
  );

  ClockGate ClockGate (
    .TE (cg_bore_cgen),
    .E (clk_en_Falu),
    .CK (clock),
    .Q (_ClockGate_Q)
  );

  ClockGate ClockGate_1 (
    .TE (cg_bore_1_cgen),
    .E (clk_en_Fcvt),
    .CK (clock),
    .Q (_ClockGate_1_Q)
  );

  ClockGate ClockGate_2 (
    .TE (cg_bore_2_cgen),
    .E (clk_en_Fmac),
    .CK (clock),
    .Q (_ClockGate_2_Q)
  );

  Dispatcher_8 in1ToN (
    .clock (clock),
    .reset (reset),
    .io_in_valid (io_in_valid),
    .io_in_bits_fuType (io_in_bits_fuType),
    .io_in_bits_fuOpType (io_in_bits_fuOpType),
    .io_in_bits_robIdx_flag (io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value (io_in_bits_robIdx_value),
    .io_in_bits_pdest (io_in_bits_pdest),
    .io_in_bits_fpWen (io_in_bits_fpWen),
    .io_in_bits_vecWen (io_in_bits_vecWen),
    .io_in_bits_v0Wen (io_in_bits_v0Wen),
    .io_in_bits_fpu_fmt (io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm (io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_enqRsTime (io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (io_in_bits_perfDebugInfo_issueTime),
    .io_out_0_valid (_in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType (_in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_fpu_fmt (_in1ToN_io_out_0_bits_fpu_fmt),
    .io_out_0_bits_fpu_rm (_in1ToN_io_out_0_bits_fpu_rm),
    .io_out_0_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_out_0_bits_perfDebugInfo_selectTime (_in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_out_0_bits_perfDebugInfo_issueTime (_in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_out_1_valid (_in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType (_in1ToN_io_out_1_bits_fuOpType),
    .io_out_1_bits_fpu_fmt (_in1ToN_io_out_1_bits_fpu_fmt),
    .io_out_1_bits_fpu_rm (_in1ToN_io_out_1_bits_fpu_rm),
    .io_out_1_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_out_1_bits_perfDebugInfo_selectTime (_in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_out_1_bits_perfDebugInfo_issueTime (_in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_out_2_valid (_in1ToN_io_out_2_valid),
    .io_out_2_bits_fuOpType (_in1ToN_io_out_2_bits_fuOpType),
    .io_out_2_bits_robIdx_flag (_in1ToN_io_out_2_bits_robIdx_flag),
    .io_out_2_bits_robIdx_value (_in1ToN_io_out_2_bits_robIdx_value),
    .io_out_2_bits_pdest (_in1ToN_io_out_2_bits_pdest),
    .io_out_2_bits_fpWen (_in1ToN_io_out_2_bits_fpWen),
    .io_out_2_bits_vecWen (_in1ToN_io_out_2_bits_vecWen),
    .io_out_2_bits_v0Wen (_in1ToN_io_out_2_bits_v0Wen),
    .io_out_2_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_out_2_bits_perfDebugInfo_selectTime (_in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_out_2_bits_perfDebugInfo_issueTime (_in1ToN_io_out_2_bits_perfDebugInfo_issueTime),
    .io_out_3_valid (_in1ToN_io_out_3_valid),
    .io_out_3_bits_fuOpType (_in1ToN_io_out_3_bits_fuOpType),
    .io_out_3_bits_fpu_fmt (_in1ToN_io_out_3_bits_fpu_fmt),
    .io_out_3_bits_fpu_rm (_in1ToN_io_out_3_bits_fpu_rm),
    .io_out_3_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_3_bits_perfDebugInfo_enqRsTime),
    .io_out_3_bits_perfDebugInfo_selectTime (_in1ToN_io_out_3_bits_perfDebugInfo_selectTime),
    .io_out_3_bits_perfDebugInfo_issueTime (_in1ToN_io_out_3_bits_perfDebugInfo_issueTime)
  );

  // §2 门控链入口:被分发选中(该 FU 的 io_in_valid)即注入有效链第 0 级。
  assign fuvld_Falu[0] = _in1ToN_io_out_0_valid;
  assign fuvld_Fcvt[0] = _in1ToN_io_out_1_valid;
  assign fuvld_Fmac[0] = _in1ToN_io_out_3_valid;

  // ==========================================================================
  // §3 输出 one-hot 仲裁:同一拍至多一个 FU 有效。每个输出字段 = 各 FU
  //   "(该FU有效 ? 该FU字段 : 0)" 的按位或(等价 Chisel Mux1H,综合为与-或选择,
  //   无优先级歧义)。robIdx/intWen 等 1bit 字段写成 (valid & field) 的或;
  //   数据/pdest 等多 bit 字段写成 (valid ? field : 0) 的或;f2v 的 128b 向量
  //   结果按 golden 切片宽度对齐。下列各式由 golden 仲裁逻辑展开中间网得到。
  // ==========================================================================
  assign io_out_valid = |{_Falu_io_out_valid, _Fcvt_io_out_valid, _f2v_io_out_valid, _Fmac_io_out_valid};

  // 仲裁中间网(被多个输出端口复用 / 需位切片;FU 黑盒输出的或归约结果)。
  wire [63:0] arb_w0 = (_Falu_io_out_valid ? _Falu_io_out_bits_res_data : 64'h0) | (_Fcvt_io_out_valid ? _Fcvt_io_out_bits_res_data : 64'h0);
  wire [127:0] arb_w1 = {64'h0, arb_w0} | (_f2v_io_out_valid ? _f2v_io_out_bits_res_data : 128'h0);
  wire [127:0] arb_w2 = {arb_w1[127:64], arb_w1[63:0] | (_Fmac_io_out_valid ? _Fmac_io_out_bits_res_data : 64'h0)};

  assign io_out_bits_data_0 = arb_w2;
  assign io_out_bits_data_1 = {64'h0, arb_w0};
  assign io_out_bits_data_2 = arb_w2;
  assign io_out_bits_data_3 = _f2v_io_out_bits_res_data;
  assign io_out_bits_data_4 = _f2v_io_out_bits_res_data;
  assign io_out_bits_pdest = (_Falu_io_out_valid ? _Falu_io_out_bits_ctrl_pdest : 8'h0) | (_Fcvt_io_out_valid ? _Fcvt_io_out_bits_ctrl_pdest : 8'h0) | (_f2v_io_out_valid ? _f2v_io_out_bits_ctrl_pdest : 8'h0) | (_Fmac_io_out_valid ? _Fmac_io_out_bits_ctrl_pdest : 8'h0);
  assign io_out_bits_robIdx_flag = _Falu_io_out_valid & _Falu_io_out_bits_ctrl_robIdx_flag | _Fcvt_io_out_valid & _Fcvt_io_out_bits_ctrl_robIdx_flag | _f2v_io_out_valid & _f2v_io_out_bits_ctrl_robIdx_flag | _Fmac_io_out_valid & _Fmac_io_out_bits_ctrl_robIdx_flag;
  assign io_out_bits_robIdx_value = (_Falu_io_out_valid ? _Falu_io_out_bits_ctrl_robIdx_value : 8'h0) | (_Fcvt_io_out_valid ? _Fcvt_io_out_bits_ctrl_robIdx_value : 8'h0) | (_f2v_io_out_valid ? _f2v_io_out_bits_ctrl_robIdx_value : 8'h0) | (_Fmac_io_out_valid ? _Fmac_io_out_bits_ctrl_robIdx_value : 8'h0);
  assign io_out_bits_intWen = _Falu_io_out_valid & _Falu_io_out_bits_ctrl_rfWen | _Fcvt_io_out_valid & _Fcvt_io_out_bits_ctrl_rfWen;
  assign io_out_bits_fpWen = _Falu_io_out_valid & _Falu_io_out_bits_ctrl_fpWen | _Fcvt_io_out_valid & _Fcvt_io_out_bits_ctrl_fpWen | _f2v_io_out_valid & _f2v_io_out_bits_ctrl_fpWen | _Fmac_io_out_valid & _Fmac_io_out_bits_ctrl_fpWen;
  assign io_out_bits_vecWen = _f2v_io_out_valid & _f2v_io_out_bits_ctrl_vecWen;
  assign io_out_bits_v0Wen = _f2v_io_out_valid & _f2v_io_out_bits_ctrl_v0Wen;
  assign io_out_bits_fflags = (_Falu_io_out_valid ? _Falu_io_out_bits_res_fflags : 5'h0) | (_Fcvt_io_out_valid ? _Fcvt_io_out_bits_res_fflags : 5'h0) | (_Fmac_io_out_valid ? _Fmac_io_out_bits_res_fflags : 5'h0);
  assign io_out_bits_wflags = _Falu_io_out_valid & _Falu_io_out_bits_ctrl_fpu_wflags | _Fcvt_io_out_valid & _Fcvt_io_out_bits_ctrl_fpu_wflags | _Fmac_io_out_valid & _Fmac_io_out_bits_ctrl_fpu_wflags;
  assign io_out_bits_debugInfo_enqRsTime = (_Falu_io_out_valid ? _Falu_io_out_bits_perfDebugInfo_enqRsTime : 64'h0) | (_Fcvt_io_out_valid ? _Fcvt_io_out_bits_perfDebugInfo_enqRsTime : 64'h0) | (_f2v_io_out_valid ? _f2v_io_out_bits_perfDebugInfo_enqRsTime : 64'h0) | (_Fmac_io_out_valid ? _Fmac_io_out_bits_perfDebugInfo_enqRsTime : 64'h0);
  assign io_out_bits_debugInfo_selectTime = (_Falu_io_out_valid ? _Falu_io_out_bits_perfDebugInfo_selectTime : 64'h0) | (_Fcvt_io_out_valid ? _Fcvt_io_out_bits_perfDebugInfo_selectTime : 64'h0) | (_f2v_io_out_valid ? _f2v_io_out_bits_perfDebugInfo_selectTime : 64'h0) | (_Fmac_io_out_valid ? _Fmac_io_out_bits_perfDebugInfo_selectTime : 64'h0);
  assign io_out_bits_debugInfo_issueTime = (_Falu_io_out_valid ? _Falu_io_out_bits_perfDebugInfo_issueTime : 64'h0) | (_Fcvt_io_out_valid ? _Fcvt_io_out_bits_perfDebugInfo_issueTime : 64'h0) | (_f2v_io_out_valid ? _f2v_io_out_bits_perfDebugInfo_issueTime : 64'h0) | (_Fmac_io_out_valid ? _Fmac_io_out_bits_perfDebugInfo_issueTime : 64'h0);
