// 自动生成:scripts/gen_exeunit.py（ExeUnit_4）—— 勿手改(逻辑为从设计意图的可读重写)

// FU / Dispatcher(in1ToN) / ClockGate 黑盒例化 + 端口连线 + §3 输出仲裁。
// FU 与 Dispatcher、ClockGate 在 UT/FM 两侧均为 golden 黑盒(它们是 FU/分发实体)。
// 本表把可读核的流水/门控信号接到这些黑盒;无 golden _GEN_/_T_ 名。

  Alu Alu (
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
    .io_out_bits_ctrl_robIdx_flag (io_out_bits_robIdx_flag),
    .io_out_bits_ctrl_robIdx_value (io_out_bits_robIdx_value),
    .io_out_bits_ctrl_pdest (io_out_bits_pdest),
    .io_out_bits_ctrl_rfWen (io_out_bits_intWen),
    .io_out_bits_res_data (_Alu_io_out_bits_res_data),
    .io_out_bits_perfDebugInfo_enqRsTime (io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_perfDebugInfo_selectTime (io_out_bits_debugInfo_selectTime),
    .io_out_bits_perfDebugInfo_issueTime (io_out_bits_debugInfo_issueTime)
  );

  Dispatcher_4 in1ToN (
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
    .io_out_0_bits_perfDebugInfo_issueTime (_in1ToN_io_out_0_bits_perfDebugInfo_issueTime)
  );

  // ==========================================================================
  // §3 输出 one-hot 仲裁:同一拍至多一个 FU 有效。每个输出字段 = 各 FU
  //   "(该FU有效 ? 该FU字段 : 0)" 的按位或(等价 Chisel Mux1H,综合为与-或选择,
  //   无优先级歧义)。robIdx/intWen 等 1bit 字段写成 (valid & field) 的或;
  //   数据/pdest 等多 bit 字段写成 (valid ? field : 0) 的或;f2v 的 128b 向量
  //   结果按 golden 切片宽度对齐。下列各式由 golden 仲裁逻辑展开中间网得到。
  // ==========================================================================
  assign io_out_valid = |{_Alu_io_out_valid};

  assign io_out_bits_data_0 = _Alu_io_out_bits_res_data;
  assign io_out_bits_data_1 = _Alu_io_out_bits_res_data;
