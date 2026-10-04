// =============================================================================
// AluDataModule —— 整数 ALU 的组合数据通路（golden Alu 的子模块：src0/src1/func -> result）
//
// 设计源：src/main/scala/xiangshan/backend/fu/Alu.scala（class AluDataModule）。
//
// 本文件只有 golden 同名 wrapper：运算本体就是 Alu.sv 里的可读核 xs_Alu_core
// （按 func[6:4] 分 6 条结果通道：移位 / 字 / 加法 / 比较 / 杂项 / Zicond，
//  通道内再由低位 func 选具体运算，详见 Alu.sv 文件头与 alu_pkg）。
// golden AluDataModule 把每种基本运算拆成 11 个小模块（AddModule / SubModule /
// Left/RightShift(Word)Module / *ResultSelect / ConditionalZeroModule / AluResSel），
// xs_Alu_core 用 function 聚合表达，同一份核同时服务 Alu 与本模块，不另写第二份。
//
// 端口差别：golden io_func 为 9 位（FuOpTypeWidth），ALU 只解释低 7 位，
// func[8:7] 在 golden 里也无读者（WordResultSelect 收 9 位但只看 [3:0]）。
// =============================================================================
module AluDataModule (
  input  [63:0] io_src_0,
  input  [63:0] io_src_1,
  input  [8:0]  io_func,
  output [63:0] io_result
);

  xs_Alu_core u_core (
    .src1   (io_src_0),
    .src2   (io_src_1),
    .func   (io_func[6:0]),
    .result (io_result)
  );

endmodule
