// =============================================================================
// CSA3_2_3960.sv —— 3:2 进位保留加法器（全加器）阵列，**本变体位宽 68**
//
// 在哪一层：后端 DivUnit 的 Radix-16 SRT 除法器数据通路。除法每轮迭代要把
//   「上一轮余数 + 若干个商位对应的除数倍数」压成冗余形式再送下一轮，用的就是
//   进位保留加法（不传播进位，延迟与位宽无关）。本变体被 SRT16DividerDataModule ×2 例化。
//
// 核心机制：68 条**互不相干**的全加器并排 —— 第 i 位只吃三个输入的第 i 位，
//   位与位之间没有任何进位链：
//     out_0[i] = in_0[i] ^ in_1[i] ^ in_2[i]          （和位，留在本位）
//     out_1[i] = in_0[i]&in_1[i] | (in_0[i]^in_1[i])&in_2[i]  （进位，权重高一位）
//   注意进位**没有**在本模块里左移——移位由使用者按自己的权重约定处理。
//
// 规模与复位域：68×3 入 / 68×2 出，★纯组合，零寄存器、零子实例、零 always 块★
//   （golden CSA3_2_3960.sv 实测 always=0 / reg=0 / 实例=0，无 clock 无 reset 端口）。
//
// 本文件是家族薄 wrapper，只设参数与对位端口；逻辑核在 rtl/backend/CSA3_2.sv
// （模块 xs_CSA3_2_core），核体全家族共一份。本文件由
// verif/ut/CSA3_2Variants/gen.py 生成，勿手改。
//
// 设计源：src/main/scala/xiangshan/backend/fu/util/CSA.scala (class CSA3_2)
// golden 对照：G1-canonical/golden-rtl/CSA3_2_3960.sv
// =============================================================================
module CSA3_2_3960(
  input  [67:0] io_in_0,
  input  [67:0] io_in_1,
  input  [67:0] io_in_2,
  output [67:0] io_out_0,
  output [67:0] io_out_1
);
  xs_CSA3_2_core #(.WIDTH(68)) u_core (
    .in_0  (io_in_0),
    .in_1  (io_in_1),
    .in_2  (io_in_2),
    .out_0 (io_out_0),
    .out_1 (io_out_1)
  );
endmodule
