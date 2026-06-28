// 自动生成:scripts/gen_openllc.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// ===== 顶层 glue(从 Scala 意图重写,golden 已具名可读,原样保留)=====
// 本层唯一时序逻辑:io.l3Miss := RegNext(OR(各 slice 的 l3Miss))。
// 4 个 slice 的 l3Miss 按位或后打一拍寄存,作为 L3 整体 miss 指示输出。

  reg          io_l3Miss_REG;
  always @(posedge clock)
    io_l3Miss_REG <=
      |{_slices_0_io_l3Miss,
        _slices_1_io_l3Miss,
        _slices_2_io_l3Miss,
        _slices_3_io_l3Miss};
