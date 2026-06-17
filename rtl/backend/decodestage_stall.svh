// 由 scripts/gen_decodestage.py 生成：stallReason out.reason[i] 接出。
// out.reason[i] = backReason.valid ? backReason.bits : in.reason[i]（背压回灌）。
  assign io_stallReason_out_reason_0 = io_stallReason_out_backReason_valid ? io_stallReason_out_backReason_bits : io_stallReason_in_reason_0;
  assign io_stallReason_out_reason_1 = io_stallReason_out_backReason_valid ? io_stallReason_out_backReason_bits : io_stallReason_in_reason_1;
  assign io_stallReason_out_reason_2 = io_stallReason_out_backReason_valid ? io_stallReason_out_backReason_bits : io_stallReason_in_reason_2;
  assign io_stallReason_out_reason_3 = io_stallReason_out_backReason_valid ? io_stallReason_out_backReason_bits : io_stallReason_in_reason_3;
  assign io_stallReason_out_reason_4 = io_stallReason_out_backReason_valid ? io_stallReason_out_backReason_bits : io_stallReason_in_reason_4;
  assign io_stallReason_out_reason_5 = io_stallReason_out_backReason_valid ? io_stallReason_out_backReason_bits : io_stallReason_in_reason_5;
