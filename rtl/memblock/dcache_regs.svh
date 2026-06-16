// 自动生成：scripts/gen_dcache.py —— 勿手改
// 寄存器声明（错误聚合 / 原子响应 / release / TL-edge 拍数等机械寄存）。
// 替换器 state_vec 与 perf REG 由可读核手写，不在此。

  reg               missQueue_io_l2_pf_store_only_REG;
  reg               missQueue_io_l2_hint_REG_valid;
  reg  [3:0]        missQueue_io_l2_hint_REG_bits_sourceId;
  reg               io_error_bits_REG;
  reg  [47:0]       io_error_bits_r_paddr;
  reg               io_error_bits_r_report_to_beu;
  reg               io_error_bits_REG_1;
  reg  [47:0]       io_error_bits_r_1_paddr;
  reg               io_error_bits_r_1_report_to_beu;
  reg               io_error_bits_REG_2;
  reg  [47:0]       io_error_bits_r_2_paddr;
  reg               io_error_bits_r_2_report_to_beu;
  reg  [47:0]       io_error_bits_r_3_paddr;
  reg               io_error_bits_r_3_report_to_beu;
  reg               io_error_bits_REG_4;
  reg  [47:0]       io_error_bits_r_4_paddr;
  reg               io_error_bits_r_4_report_to_beu;
  reg               io_error_valid_REG;
  reg               io_error_valid_REG_1;
  reg               extra_flag_valid;
  reg  [3:0]        extra_flag_way_en;
  reg               REG;
  reg               done_r_counter;
  reg               done_r_counter_1;
  reg               done_r_counter_2;
  reg               io_lsu_atomics_resp_valid_REG;
  reg  [127:0]      io_lsu_atomics_resp_bits_r_data;
  reg               io_lsu_atomics_resp_bits_r_miss;
  reg               io_lsu_atomics_resp_bits_r_replay;
  reg               io_lsu_atomics_resp_bits_r_error;
  reg  [5:0]        io_lsu_atomics_resp_bits_r_id;
  reg               missQueue_io_main_pipe_resp_valid_REG;
  reg  [3:0]        missQueue_io_main_pipe_resp_bits_r_miss_id;
  reg               missQueue_io_main_pipe_resp_bits_r_ack_miss_queue;
  reg               io_lsu_store_replay_resp_valid_REG;
  reg  [5:0]        io_lsu_store_replay_resp_bits_r_id;
  reg               mainPipe_io_invalid_resv_set_REG;
  reg               io_lsu_release_valid_REG;
  reg  [47:0]       io_lsu_release_bits_paddr_r;
