// 由 verif/it/Exec/gen_it.py 生成 —— 勿手改。
// = rtl/backend/exeunit_connect.svh，仅把 3 个 FU 例化的模块名换成 _xs 适配器:
//   Alu->Alu_xs / MulUnit->MulUnit_xs / Bku->Bku_xs（Dispatcher/ClockGate 仍 golden）。
// 自动生成:scripts/gen_exeunit.py（ExeUnit）—— 勿手改(逻辑为从设计意图的可读重写)

// FU / Dispatcher(in1ToN) / ClockGate 黑盒例化 + 端口连线 + §3 输出仲裁。
// FU 与 Dispatcher、ClockGate 在 UT/FM 两侧均为 golden 黑盒(它们是 FU/分发实体)。
// 本表把可读核的流水/门控信号接到这些黑盒;无 golden _GEN_/_T_ 名。

  Alu_xs Alu (
    .io_in_valid (_in1ToN_io_out_0_valid),
    .io_in_bits_ctrl_fuOpType (_in1ToN_io_out_0_bits_fuOpType),
    .io_in_bits_ctrlPipe_0_robIdx_flag (io_in_bits_robIdx_flag),
    .io_in_bits_ctrlPipe_0_robIdx_value (io_in_bits_robIdx_value),
    .io_in_bits_ctrlPipe_0_pdest (io_in_bits_pdest),
    .io_in_bits_ctrlPipe_0_rfWen (io_in_bits_rfWen),
    .io_in_bits_data_src_1 (io_in_bits_src_1),
    .io_in_bits_data_src_0 (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (_in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (_in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_out_valid (_Alu_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (_Alu_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (_Alu_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (_Alu_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (_Alu_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data (_Alu_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime (_Alu_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (_Alu_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (_Alu_io_out_bits_perfDebugInfo_issueTime)
  );

  MulUnit_xs Mul (
    .clock (_ClockGate_Q),
    .reset (reset),
    .io_in_valid (_in1ToN_io_out_1_valid),
    .io_in_bits_ctrl_fuOpType (_in1ToN_io_out_1_bits_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag (ctrl_pipe[1].robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value (ctrl_pipe[1].robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest (ctrl_pipe[1].pdest),
    .io_in_bits_ctrlPipe_2_rfWen (ctrl_pipe[1].rfWen),
    .io_in_bits_validPipe_0 (io_in_valid),
    .io_in_bits_validPipe_1 (valid_pipe[0]),
    .io_in_bits_validPipe_2 (valid_pipe[1]),
    .io_in_bits_data_src_1 (io_in_bits_src_1),
    .io_in_bits_data_src_0 (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (_in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (_in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_out_valid (_Mul_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (_Mul_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (_Mul_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (_Mul_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (_Mul_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data (_Mul_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime (_Mul_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (_Mul_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (_Mul_io_out_bits_perfDebugInfo_issueTime)
  );

  Bku_xs Bku (
    .clock (_ClockGate_1_Q),
    .reset (reset),
    .io_in_valid (_in1ToN_io_out_2_valid),
    .io_in_bits_ctrl_fuOpType (_in1ToN_io_out_2_bits_fuOpType),
    .io_in_bits_ctrlPipe_2_robIdx_flag (ctrl_pipe[1].robIdx_flag),
    .io_in_bits_ctrlPipe_2_robIdx_value (ctrl_pipe[1].robIdx_value),
    .io_in_bits_ctrlPipe_2_pdest (ctrl_pipe[1].pdest),
    .io_in_bits_ctrlPipe_2_rfWen (ctrl_pipe[1].rfWen),
    .io_in_bits_validPipe_0 (io_in_valid),
    .io_in_bits_validPipe_1 (valid_pipe[0]),
    .io_in_bits_validPipe_2 (valid_pipe[1]),
    .io_in_bits_data_src_1 (io_in_bits_src_1),
    .io_in_bits_data_src_0 (io_in_bits_src_0),
    .io_in_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (_in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (_in1ToN_io_out_2_bits_perfDebugInfo_issueTime),
    .io_out_valid (_Bku_io_out_valid),
    .io_out_bits_ctrl_robIdx_flag (_Bku_io_out_bits_ctrl_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (_Bku_io_out_bits_ctrl_robIdx_value),
    .io_out_bits_ctrl_pdest (_Bku_io_out_bits_ctrl_pdest),
    .io_out_bits_ctrl_rfWen (_Bku_io_out_bits_ctrl_rfWen),
    .io_out_bits_res_data (_Bku_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime (_Bku_io_out_bits_perfDebugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (_Bku_io_out_bits_perfDebugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (_Bku_io_out_bits_perfDebugInfo_issueTime)
  );

  ClockGate ClockGate (
    .TE (cg_bore_cgen),
    .E (clk_en_Mul),
    .CK (clock),
    .Q (_ClockGate_Q)
  );

  ClockGate ClockGate_1 (
    .TE (cg_bore_1_cgen),
    .E (clk_en_Bku),
    .CK (clock),
    .Q (_ClockGate_1_Q)
  );

  Dispatcher in1ToN (
    .clock (clock),
    .reset (reset),
    .io_in_valid (io_in_valid),
    .io_in_bits_fuType (io_in_bits_fuType),
    .io_in_bits_fuOpType (io_in_bits_fuOpType),
    .io_in_bits_perfDebugInfo_enqRsTime (io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime (io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime (io_in_bits_perfDebugInfo_issueTime),
    .io_out_0_valid (_in1ToN_io_out_0_valid),
    .io_out_0_bits_fuOpType (_in1ToN_io_out_0_bits_fuOpType),
    .io_out_0_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_0_bits_perfDebugInfo_enqRsTime),
    .io_out_0_bits_perfDebugInfo_selectTime (_in1ToN_io_out_0_bits_perfDebugInfo_selectTime),
    .io_out_0_bits_perfDebugInfo_issueTime (_in1ToN_io_out_0_bits_perfDebugInfo_issueTime),
    .io_out_1_valid (_in1ToN_io_out_1_valid),
    .io_out_1_bits_fuOpType (_in1ToN_io_out_1_bits_fuOpType),
    .io_out_1_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_1_bits_perfDebugInfo_enqRsTime),
    .io_out_1_bits_perfDebugInfo_selectTime (_in1ToN_io_out_1_bits_perfDebugInfo_selectTime),
    .io_out_1_bits_perfDebugInfo_issueTime (_in1ToN_io_out_1_bits_perfDebugInfo_issueTime),
    .io_out_2_valid (_in1ToN_io_out_2_valid),
    .io_out_2_bits_fuOpType (_in1ToN_io_out_2_bits_fuOpType),
    .io_out_2_bits_perfDebugInfo_enqRsTime (_in1ToN_io_out_2_bits_perfDebugInfo_enqRsTime),
    .io_out_2_bits_perfDebugInfo_selectTime (_in1ToN_io_out_2_bits_perfDebugInfo_selectTime),
    .io_out_2_bits_perfDebugInfo_issueTime (_in1ToN_io_out_2_bits_perfDebugInfo_issueTime)
  );

  // §2 门控链入口:被分发选中(该 FU 的 io_in_valid)即注入有效链第 0 级。
  assign fuvld_Mul[0] = _in1ToN_io_out_1_valid;
  assign fuvld_Bku[0] = _in1ToN_io_out_2_valid;

  // ==========================================================================
  // §3 输出 one-hot 仲裁:同一拍至多一个 FU 有效。每个输出字段 = 各 FU
  //   "(该FU有效 ? 该FU字段 : 0)" 的按位或(等价 Chisel Mux1H,综合为与-或选择,
  //   无优先级歧义)。robIdx/intWen 等 1bit 字段写成 (valid & field) 的或;
  //   数据/pdest 等多 bit 字段写成 (valid ? field : 0) 的或;f2v 的 128b 向量
  //   结果按 golden 切片宽度对齐。下列各式由 golden 仲裁逻辑展开中间网得到。
  // ==========================================================================
  assign io_out_valid = |{_Alu_io_out_valid, _Mul_io_out_valid, _Bku_io_out_valid};

  // 仲裁中间网(被多个输出端口复用 / 需位切片;FU 黑盒输出的或归约结果)。
  wire [63:0] arb_w0 = (_Alu_io_out_valid ? _Alu_io_out_bits_res_data : 64'h0) | (_Mul_io_out_valid ? _Mul_io_out_bits_res_data : 64'h0) | (_Bku_io_out_valid ? _Bku_io_out_bits_res_data : 64'h0);

  assign io_out_bits_data_0 = arb_w0;
  assign io_out_bits_data_1 = arb_w0;
  assign io_out_bits_pdest = (_Alu_io_out_valid ? _Alu_io_out_bits_ctrl_pdest : 8'h0) | (_Mul_io_out_valid ? _Mul_io_out_bits_ctrl_pdest : 8'h0) | (_Bku_io_out_valid ? _Bku_io_out_bits_ctrl_pdest : 8'h0);
  assign io_out_bits_robIdx_flag = _Alu_io_out_valid & _Alu_io_out_bits_ctrl_robIdx_flag | _Mul_io_out_valid & _Mul_io_out_bits_ctrl_robIdx_flag | _Bku_io_out_valid & _Bku_io_out_bits_ctrl_robIdx_flag;
  assign io_out_bits_robIdx_value = (_Alu_io_out_valid ? _Alu_io_out_bits_ctrl_robIdx_value : 8'h0) | (_Mul_io_out_valid ? _Mul_io_out_bits_ctrl_robIdx_value : 8'h0) | (_Bku_io_out_valid ? _Bku_io_out_bits_ctrl_robIdx_value : 8'h0);
  assign io_out_bits_intWen = _Alu_io_out_valid & _Alu_io_out_bits_ctrl_rfWen | _Mul_io_out_valid & _Mul_io_out_bits_ctrl_rfWen | _Bku_io_out_valid & _Bku_io_out_bits_ctrl_rfWen;
  assign io_out_bits_debugInfo_enqRsTime = (_Alu_io_out_valid ? _Alu_io_out_bits_perfDebugInfo_enqRsTime : 64'h0) | (_Mul_io_out_valid ? _Mul_io_out_bits_perfDebugInfo_enqRsTime : 64'h0) | (_Bku_io_out_valid ? _Bku_io_out_bits_perfDebugInfo_enqRsTime : 64'h0);
  assign io_out_bits_debugInfo_selectTime = (_Alu_io_out_valid ? _Alu_io_out_bits_perfDebugInfo_selectTime : 64'h0) | (_Mul_io_out_valid ? _Mul_io_out_bits_perfDebugInfo_selectTime : 64'h0) | (_Bku_io_out_valid ? _Bku_io_out_bits_perfDebugInfo_selectTime : 64'h0);
  assign io_out_bits_debugInfo_issueTime = (_Alu_io_out_valid ? _Alu_io_out_bits_perfDebugInfo_issueTime : 64'h0) | (_Mul_io_out_valid ? _Mul_io_out_bits_perfDebugInfo_issueTime : 64'h0) | (_Bku_io_out_valid ? _Bku_io_out_bits_perfDebugInfo_issueTime : 64'h0);
