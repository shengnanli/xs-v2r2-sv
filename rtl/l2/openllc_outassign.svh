// 自动生成:scripts/gen_openllc.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 顶层 io 输出 assign + probe(共 3 条,全部纯连线无运算)。
//   _probe                      : difftest/dontTouch 探针(topDown.addrMatch 镜像);
//   io_debugTopDown_addrMatch_0 : topDown 输出直通;
//   io_l3Miss                   : 打拍后的 l3Miss 输出。

  assign _probe = _topDown_io_debugTopDown_addrMatch_0;
  assign io_debugTopDown_addrMatch_0 = _topDown_io_debugTopDown_addrMatch_0;
  assign io_l3Miss = io_l3Miss_REG;
