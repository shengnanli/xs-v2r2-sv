// =============================================================================
//  CHILogger —— CHI 链路层 透明监视器 可读重写核 (xs_CHILogger_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/CHILogger.scala
//  插在 up(上游 RN/L2) 与 down(下游互联) 之间的纯透传探针: 把两侧 CHI 链路接口
//  (sysco 握手 / linkactive 握手 / TX·RX 的 REQ/RSP/DAT/SNP flit 与 lcrdv 信用)
//  一一直连; 仿真时另在 `ifndef SYNTHESIS 下打印事务日志 (综合/本核不含)。
//  方向: down_* (送往下游) 由对应 up_* 驱动 = TX/请求下行; up_* (回给上游) 由
//        对应 down_* 驱动 = RX/响应上行。纯组合, 无寄存器/子模块。
// =============================================================================
module xs_CHILogger_core(
  input          io_up_txsactive,
  output         io_up_rxsactive,
  input          io_up_syscoreq,
  output         io_up_syscoack,
  input          io_up_tx_linkactivereq,
  output         io_up_tx_linkactiveack,
  input          io_up_tx_req_flitpend,
  input          io_up_tx_req_flitv,
  input  [161:0] io_up_tx_req_flit,
  output         io_up_tx_req_lcrdv,
  input          io_up_tx_rsp_flitpend,
  input          io_up_tx_rsp_flitv,
  input  [72:0]  io_up_tx_rsp_flit,
  output         io_up_tx_rsp_lcrdv,
  input          io_up_tx_dat_flitpend,
  input          io_up_tx_dat_flitv,
  input  [421:0] io_up_tx_dat_flit,
  output         io_up_tx_dat_lcrdv,
  output         io_up_rx_linkactivereq,
  input          io_up_rx_linkactiveack,
  output         io_up_rx_rsp_flitpend,
  output         io_up_rx_rsp_flitv,
  output [72:0]  io_up_rx_rsp_flit,
  input          io_up_rx_rsp_lcrdv,
  output         io_up_rx_dat_flitpend,
  output         io_up_rx_dat_flitv,
  output [421:0] io_up_rx_dat_flit,
  input          io_up_rx_dat_lcrdv,
  output         io_up_rx_snp_flitpend,
  output         io_up_rx_snp_flitv,
  output [114:0] io_up_rx_snp_flit,
  input          io_up_rx_snp_lcrdv,
  output         io_down_txsactive,
  input          io_down_rxsactive,
  output         io_down_syscoreq,
  input          io_down_syscoack,
  output         io_down_tx_linkactivereq,
  input          io_down_tx_linkactiveack,
  output         io_down_tx_req_flitpend,
  output         io_down_tx_req_flitv,
  output [161:0] io_down_tx_req_flit,
  input          io_down_tx_req_lcrdv,
  output         io_down_tx_rsp_flitpend,
  output         io_down_tx_rsp_flitv,
  output [72:0]  io_down_tx_rsp_flit,
  input          io_down_tx_rsp_lcrdv,
  output         io_down_tx_dat_flitpend,
  output         io_down_tx_dat_flitv,
  output [421:0] io_down_tx_dat_flit,
  input          io_down_tx_dat_lcrdv,
  input          io_down_rx_linkactivereq,
  output         io_down_rx_linkactiveack,
  input          io_down_rx_rsp_flitpend,
  input          io_down_rx_rsp_flitv,
  input  [72:0]  io_down_rx_rsp_flit,
  output         io_down_rx_rsp_lcrdv,
  input          io_down_rx_dat_flitpend,
  input          io_down_rx_dat_flitv,
  input  [421:0] io_down_rx_dat_flit,
  output         io_down_rx_dat_lcrdv,
  input          io_down_rx_snp_flitpend,
  input          io_down_rx_snp_flitv,
  input  [114:0] io_down_rx_snp_flit,
  output         io_down_rx_snp_lcrdv
);

  // 透传连线 (综合可见的全部功能逻辑)
  assign io_up_rxsactive = io_down_rxsactive;
  assign io_up_syscoack = io_down_syscoack;
  assign io_up_tx_linkactiveack = io_down_tx_linkactiveack;
  assign io_up_tx_req_lcrdv = io_down_tx_req_lcrdv;
  assign io_up_tx_rsp_lcrdv = io_down_tx_rsp_lcrdv;
  assign io_up_tx_dat_lcrdv = io_down_tx_dat_lcrdv;
  assign io_up_rx_linkactivereq = io_down_rx_linkactivereq;
  assign io_up_rx_rsp_flitpend = io_down_rx_rsp_flitpend;
  assign io_up_rx_rsp_flitv = io_down_rx_rsp_flitv;
  assign io_up_rx_rsp_flit = io_down_rx_rsp_flit;
  assign io_up_rx_dat_flitpend = io_down_rx_dat_flitpend;
  assign io_up_rx_dat_flitv = io_down_rx_dat_flitv;
  assign io_up_rx_dat_flit = io_down_rx_dat_flit;
  assign io_up_rx_snp_flitpend = io_down_rx_snp_flitpend;
  assign io_up_rx_snp_flitv = io_down_rx_snp_flitv;
  assign io_up_rx_snp_flit = io_down_rx_snp_flit;
  assign io_down_txsactive = io_up_txsactive;
  assign io_down_syscoreq = io_up_syscoreq;
  assign io_down_tx_linkactivereq = io_up_tx_linkactivereq;
  assign io_down_tx_req_flitpend = io_up_tx_req_flitpend;
  assign io_down_tx_req_flitv = io_up_tx_req_flitv;
  assign io_down_tx_req_flit = io_up_tx_req_flit;
  assign io_down_tx_rsp_flitpend = io_up_tx_rsp_flitpend;
  assign io_down_tx_rsp_flitv = io_up_tx_rsp_flitv;
  assign io_down_tx_rsp_flit = io_up_tx_rsp_flit;
  assign io_down_tx_dat_flitpend = io_up_tx_dat_flitpend;
  assign io_down_tx_dat_flitv = io_up_tx_dat_flitv;
  assign io_down_tx_dat_flit = io_up_tx_dat_flit;
  assign io_down_rx_linkactiveack = io_up_rx_linkactiveack;
  assign io_down_rx_rsp_lcrdv = io_up_rx_rsp_lcrdv;
  assign io_down_rx_dat_lcrdv = io_up_rx_dat_lcrdv;
  assign io_down_rx_snp_lcrdv = io_up_rx_snp_lcrdv;

endmodule
