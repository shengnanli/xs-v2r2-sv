// 自动生成:scripts/gen_slice.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 顶层 io 输出 assign + dontTouch 探针(_probe_<k>,死端)+ MBIST bore 回吐。
// 多为子模块输出网 / 打拍寄存直连;io_dirResult_valid 含一处与运算门控。

  assign _probe_0 = _sinkC_io_refillBufWrite_valid;
  assign _probe_1 = _directory_io_resp_bits_way;
  assign _probe_2 = _mainPipe_io_toMSHRCtl_mshr_alloc_s3_valid;
  assign _probe_3 = _mshrCtl_io_toMainPipe_mshr_alloc_ptr;
  assign io_dirResult_valid = _directory_io_resp_valid & ~_directory_io_replResp_valid;
  assign io_dirResult_bits_hit = _directory_io_resp_bits_hit;
  assign io_dirResult_bits_meta_prefetch = _directory_io_resp_bits_meta_prefetch;
  assign io_dirResult_bits_meta_prefetchSrc = _directory_io_resp_bits_meta_prefetchSrc;
  assign io_error_valid = io_error_valid_REG;
  assign io_error_bits_valid = io_error_bits_REG_valid;
  assign io_error_bits_address = io_error_bits_REG_address;
  assign io_perf_0_value = perf_0_value_s2;
  assign io_perf_1_value = perf_1_value_s2;
  assign io_perf_3_value = perf_3_value_s2;
  assign io_perf_4_value = perf_4_value_s2;
  assign io_perf_5_value = perf_5_value_s2;
  assign io_perf_6_value = perf_6_value_s2;
  assign io_perf_7_value = perf_7_value_s2;
  assign io_perf_8_value = perf_8_value_s2;
  assign io_perf_9_value = perf_9_value_s2;
  assign io_perf_10_value = perf_10_value_s2;
  assign io_perf_11_value = perf_11_value_s2;
  assign boreChildrenBd_bore_ack = bd_ack;
  assign boreChildrenBd_bore_outdata = bd_outdata;
