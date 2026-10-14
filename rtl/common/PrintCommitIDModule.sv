// PrintCommitIDModule.sv —— 仿真专用的"版本号打印"终端（simulation-only sink），没有输出、没有状态。
// =============================================================================
// 在哪一层：NewCSR → CommitIDModule 的叶子（Chisel utility.PrintCommitID 的 BlackBox 外部模块；
//   G1 golden 是行为模型 golden-rtl/PrintCommitIDModule.v）。CommitIDModule 把核号、生成 RTL 时的 git commit
//   SHA（40 位）和"工作树是否 dirty"三个常量接进来，本模块在仿真开始时把它们打印一行，方便从仿真日志认出
//   跑的是哪一版 RTL。
//
// 行为（codex 0230 第 2 题：本地重写，不再让 impl 侧读 golden）：
//   * `ifndef SYNTHESIS`：0 时刻打印一次 "Core <hartID>'s Commit SHA is: <commitID 十六进制>, dirty: <dirty>"，
//     写到 STDOUT（文件描述符 32'h8000_0001），与 golden 的输出文本逐字相同；
//   * SYNTHESIS 下：无寄存器、无输出，综合 / Formality 里不产生任何比较点。模块体里只留一根无读者的常量线
//     body_present：模块体若完全为空，Formality 会把它当"空设计"自动黑盒（black_boxes 属性 e），impl 侧多出
//     47 个黑盒输入比较点而 ref 侧没有（golden .v 用 `_dummy_unused` 线做同一件事）—— ExuBlock official 实测。
//   端口严格是 hartID[5:0] / commitID[39:0] / dirty，全是输入（父层把它们接常量）。
// =============================================================================

module PrintCommitIDModule (
  input logic [5:0]  hartID,
  input logic [39:0] commitID,
  input logic        dirty
);

  // 让模块体非空（不是功能：无读者，综合后被删掉）。理由见文件头。
  logic body_present;
  assign body_present = 1'b1;

`ifndef SYNTHESIS
  // 仿真开始时报一次版本：STDOUT 的多通道描述符是 32'h8000_0001
  localparam int unsigned STDOUT_FD = 32'h8000_0001;
  initial begin
    $fwrite(STDOUT_FD, "Core %d's Commit SHA is: %h, dirty: %d\n", hartID, commitID, dirty);
  end
`endif

endmodule
