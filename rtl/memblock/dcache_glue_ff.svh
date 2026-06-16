// 自动生成：scripts/gen_dcache.py —— 勿手改

// 复位/寄存 always 块（错误聚合 / 原子响应 / release / TL-edge 拍数等）。
// 替换器 state_vec 更新 与 perf REG 更新由可读核手写，不在此。

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      missQueue_io_l2_pf_store_only_REG <= 1'h0;
      io_error_valid_REG <= 1'h0;
      io_error_valid_REG_1 <= 1'h0;
      done_r_counter <= 1'h0;
      done_r_counter_1 <= 1'h0;
      done_r_counter_2 <= 1'h0;
    end
    else begin
      missQueue_io_l2_pf_store_only_REG <= io_l2_pf_store_only;
      io_error_valid_REG <= error_valid;
      io_error_valid_REG_1 <= io_error_valid_REG;
      if (_done_T) begin
        if (done_r_counter)
          done_r_counter <= 1'(done_r_counter - 1'h1);
        else
          done_r_counter <= done_r_beats1;
      end
      if (_done_T_1) begin
        if (done_r_counter_1)
          done_r_counter_1 <= 1'(done_r_counter_1 - 1'h1);
        else
          done_r_counter_1 <= done_r_beats1_1;
      end
      if (_done_T_2) begin
        if (done_r_counter_2)
          done_r_counter_2 <= 1'(done_r_counter_2 - 1'h1);
        else
          done_r_counter_2 <= done_r_beats1_2;
      end
    end
  end // always @(posedge, posedge)

  always @(posedge clock) begin
    missQueue_io_l2_hint_REG_valid <= io_l2_hint_valid;
    missQueue_io_l2_hint_REG_bits_sourceId <= io_l2_hint_bits_sourceId;
    io_error_bits_REG <= _mainPipe_io_error_valid;
    if (_mainPipe_io_error_valid) begin
      io_error_bits_r_paddr <= _mainPipe_io_error_bits_paddr;
      io_error_bits_r_report_to_beu <= _mainPipe_io_error_bits_report_to_beu;
    end
    io_error_bits_REG_1 <= _ldu_0_io_error_valid;
    if (_ldu_0_io_error_valid) begin
      io_error_bits_r_1_paddr <= _ldu_0_io_error_bits_paddr;
      io_error_bits_r_1_report_to_beu <= _ldu_0_io_error_bits_report_to_beu;
    end
    io_error_bits_REG_2 <= _ldu_1_io_error_valid;
    if (_ldu_1_io_error_valid) begin
      io_error_bits_r_2_paddr <= _ldu_1_io_error_bits_paddr;
      io_error_bits_r_2_report_to_beu <= _ldu_1_io_error_bits_report_to_beu;
    end
    if (_ldu_2_io_error_valid) begin
      io_error_bits_r_3_paddr <= _ldu_2_io_error_bits_paddr;
      io_error_bits_r_3_report_to_beu <= _ldu_2_io_error_bits_report_to_beu;
    end
    io_error_bits_REG_4 <= error_valid;
    if (io_error_bits_REG_4) begin
      io_error_bits_r_4_paddr <=
        _io_error_bits_T
          ? (io_error_bits_REG ? io_error_bits_r_paddr : io_error_bits_r_1_paddr)
          : io_error_bits_REG_2 ? io_error_bits_r_2_paddr : io_error_bits_r_3_paddr;
      io_error_bits_r_4_report_to_beu <=
        _io_error_bits_T
          ? (io_error_bits_REG
               ? io_error_bits_r_report_to_beu
               : io_error_bits_r_1_report_to_beu)
          : io_error_bits_REG_2
              ? io_error_bits_r_2_report_to_beu
              : io_error_bits_r_3_report_to_beu;
    end
    extra_flag_valid <= _mainPipe_io_prefetch_flag_write_valid;
    if (_mainPipe_io_prefetch_flag_write_valid)
      extra_flag_way_en <= _mainPipe_io_prefetch_flag_write_bits_way_en;
    REG <= ~_mainPipe_io_tag_write_intend & _tag_write_arb_io_out_valid;
    io_lsu_atomics_resp_valid_REG <= atomic_resp_valid;
    if (atomic_resp_valid) begin
      io_lsu_atomics_resp_bits_r_data <= _mainPipe_io_atomic_resp_bits_data;
      io_lsu_atomics_resp_bits_r_miss <= _mainPipe_io_atomic_resp_bits_miss;
      io_lsu_atomics_resp_bits_r_replay <= _mainPipe_io_atomic_resp_bits_replay;
      io_lsu_atomics_resp_bits_r_error <= _mainPipe_io_atomic_resp_bits_error;
      io_lsu_atomics_resp_bits_r_id <= _mainPipe_io_atomic_resp_bits_id;
    end
    missQueue_io_main_pipe_resp_valid_REG <= _mainPipe_io_atomic_resp_valid;
    if (_mainPipe_io_atomic_resp_valid) begin
      missQueue_io_main_pipe_resp_bits_r_miss_id <= _mainPipe_io_atomic_resp_bits_miss_id;
      missQueue_io_main_pipe_resp_bits_r_ack_miss_queue <=
        _mainPipe_io_atomic_resp_bits_ack_miss_queue;
    end
    io_lsu_store_replay_resp_valid_REG <= _mainPipe_io_store_replay_resp_valid;
    if (_mainPipe_io_store_replay_resp_valid)
      io_lsu_store_replay_resp_bits_r_id <= _mainPipe_io_store_replay_resp_bits_id;
    mainPipe_io_invalid_resv_set_REG <=
      _io_lsu_release_bits_paddr_T
      & _mainPipe_io_wb_bits_addr == _mainPipe_io_lrsc_locked_block_bits
      & _mainPipe_io_lrsc_locked_block_valid;
    io_lsu_release_valid_REG <= _io_lsu_release_bits_paddr_T;
    if (_io_lsu_release_bits_paddr_T)
      io_lsu_release_bits_paddr_r <= _mainPipe_io_wb_bits_addr;
  end // always @(posedge)

