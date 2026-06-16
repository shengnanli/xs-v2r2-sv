// 自动生成：scripts/gen_dcache.py —— 勿手改
// 顶层 assign 互联别名（机械接线；perf-out 由核手写）。

  assign clientNodeOut_d_ready = _GEN_13 ? _missQueue_io_mem_grant_ready : _GEN_14;
  assign _probe_6 = _ldu_0_io_banked_data_read_valid;
  assign _probe_7 = _ldu_1_io_banked_data_read_valid;
  assign _probe_8 = _ldu_2_io_banked_data_read_valid;
  assign _probe_9 = _mainPipe_io_data_readline_valid;
  assign _probe_10 = _mainPipe_io_prefetch_flag_write_valid;
  assign _probe_11 = _mainPipe_io_tag_write_valid;
  assign _probe_12 = _missQueue_io_prefetch_info_naive_late_miss_prefetch;
  assign _probe_13 = _missQueue_io_prefetch_info_fdp_late_miss_prefetch;
  assign _probe_14 = _missQueue_io_probe_block;
  assign _probe_15 = _dataWriteArb_io_out_valid;
  assign auto_client_out_a_valid = _missQueue_io_mem_acquire_valid;
  assign auto_client_out_a_bits_address = _missQueue_io_mem_acquire_bits_address;
  assign auto_client_out_b_ready = clientNodeOut_b_ready;
  assign auto_client_out_c_valid = _wb_io_mem_release_valid;
  assign auto_client_out_c_bits_address = _wb_io_mem_release_bits_address;
  assign auto_client_out_d_ready = clientNodeOut_d_ready;
  assign io_lsu_load_0_req_ready = _ldu_0_io_lsu_req_ready;
  assign io_lsu_load_1_req_ready = _ldu_1_io_lsu_req_ready;
  assign io_lsu_load_2_req_ready = _ldu_2_io_lsu_req_ready;
  assign io_lsu_tl_d_channel_valid = (_GEN | _GEN_1) & auto_client_out_d_valid;
  assign io_lsu_tl_d_channel_mshrid = auto_client_out_d_bits_source[3:0];
  assign io_lsu_store_replay_resp_valid = io_lsu_store_replay_resp_valid_REG;
  assign io_lsu_store_replay_resp_bits_id = io_lsu_store_replay_resp_bits_r_id;
  assign io_lsu_atomics_resp_valid = io_lsu_atomics_resp_valid_REG;
  assign io_lsu_atomics_resp_bits_data = io_lsu_atomics_resp_bits_r_data;
  assign io_lsu_atomics_resp_bits_miss = io_lsu_atomics_resp_bits_r_miss;
  assign io_lsu_atomics_resp_bits_replay = io_lsu_atomics_resp_bits_r_replay;
  assign io_lsu_atomics_resp_bits_error = io_lsu_atomics_resp_bits_r_error;
  assign io_lsu_atomics_resp_bits_id = io_lsu_atomics_resp_bits_r_id;
  assign io_lsu_release_valid = io_lsu_release_valid_REG;
  assign io_lsu_release_bits_paddr = io_lsu_release_bits_paddr_r;
  assign io_lsu_forward_D_0_valid = io_lsu_forward_D_2_valid_0;
  assign io_lsu_forward_D_0_data = auto_client_out_d_bits_data;
  assign io_lsu_forward_D_0_mshrid = auto_client_out_d_bits_source[3:0];
  assign io_lsu_forward_D_0_last =
    auto_client_out_d_bits_echo_isKeyword ^ (done_r_counter | ~done_r_beats1) & _done_T;
  assign io_lsu_forward_D_0_corrupt =
    _GEN & (auto_client_out_d_bits_corrupt | auto_client_out_d_bits_denied);
  assign io_lsu_forward_D_1_valid = io_lsu_forward_D_2_valid_0;
  assign io_lsu_forward_D_1_data = auto_client_out_d_bits_data;
  assign io_lsu_forward_D_1_mshrid = auto_client_out_d_bits_source[3:0];
  assign io_lsu_forward_D_1_last =
    auto_client_out_d_bits_echo_isKeyword ^ (done_r_counter_1 | ~done_r_beats1_1)
    & _done_T_1;
  assign io_lsu_forward_D_1_corrupt =
    _GEN & (auto_client_out_d_bits_corrupt | auto_client_out_d_bits_denied);
  assign io_lsu_forward_D_2_valid = io_lsu_forward_D_2_valid_0;
  assign io_lsu_forward_D_2_data = auto_client_out_d_bits_data;
  assign io_lsu_forward_D_2_mshrid = auto_client_out_d_bits_source[3:0];
  assign io_lsu_forward_D_2_last =
    auto_client_out_d_bits_echo_isKeyword ^ (done_r_counter_2 | ~done_r_beats1_2)
    & _done_T_2;
  assign io_lsu_forward_D_2_corrupt =
    _GEN & (auto_client_out_d_bits_corrupt | auto_client_out_d_bits_denied);
  assign io_error_valid = io_error_valid_REG_1;
  assign io_error_bits_paddr = io_error_bits_r_4_paddr;
  assign io_error_bits_report_to_beu = io_error_bits_r_4_report_to_beu;
