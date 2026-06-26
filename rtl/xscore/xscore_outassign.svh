// 自动生成:scripts/gen_xscore.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 顶层 io 输出 assign:子模块黑盒输出直连顶层 io(个别带 BEU 错误 AND glue)。
// glue 组合式 -> 核内具名 wire(见 XSCore.sv 的 dcacheBeuEccErrorValid)。

  assign io_l2PfCtrl_l2_pf_recv_en = _backend_io_mem_csrCtrl_pf_ctrl_l2_pf_recv_enable;
  assign io_beu_errors_dcache_ecc_error_valid = dcacheBeuEccErrorValid;
