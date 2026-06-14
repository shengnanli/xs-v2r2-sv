// 手写可读核：RVC（16 位压缩指令）→ 32 位指令展开器
//
// 纯组合逻辑，无寄存器。给定 16 位压缩码 io_in[15:0]（高 16 位为下一条/无关），
// 按 RISC-V C 扩展译码出等价的 32 位指令 io_out_bits，并给出 io_ill（非法 / 需异常）。
// io_fsIsOff 表示浮点单元关闭，影响浮点类压缩指令的合法性判定。
//
// 关键译码量（沿用 golden 命名，便于 Formality 按名匹配）：
//   _io_out_T_2 = {io_in[1:0], io_in[15:13]}  —— 5 位主分类（quadrant + funct3）
//   _io_ill_T_2 同上，用于合法性判定。
// 展开结果按各压缩指令类别（CIW/CL/CS/CB/CJ/CR/CI/CSS 等）拼装 32 位 R/I/S/B/U/J 格式。
//
// 顶层模块名 RVCExpander 与 golden 一致：NewIFU 等上层按此名例化，亦供 FM 直接对照。
module RVCExpander(
  input  [31:0] io_in,
  input         io_fsIsOff,
  output [31:0] io_out_bits,
  output        io_ill
);
  xs_RVCExpander_core u_core (
    .io_in       (io_in),
    .io_fsIsOff  (io_fsIsOff),
    .io_out_bits (io_out_bits),
    .io_ill      (io_ill)
  );
endmodule

// 可读核：逻辑忠实保留 golden 组合表达式（boolean 函数与 golden 完全一致，FM 直接判等）。
module xs_RVCExpander_core(
  input  [31:0] io_in,
  input         io_fsIsOff,
  output [31:0] io_out_bits,
  output        io_ill
);

  // funct 选择（用于 CA 类 sub/xor/or/and 等运算的 funct3 区分）
  wire [2:0]      _io_out_s_funct_T_2 = {io_in[12], io_in[6:5]};
  wire [2:0]      _io_out_s_funct_T_4 = {_io_out_s_funct_T_2 == 3'h1, 2'h0};
  wire [7:0][2:0] _GEN =
    {{3'h3},
     {3'h0},
     {3'h0},
     {3'h0},
     {3'h7},
     {3'h6},
     {_io_out_s_funct_T_4},
     {_io_out_s_funct_T_4}};
  wire [3:0]      _GEN_0 = {4{io_in[12]}};
  wire [6:0]      io_out_s_load_opc = (|(io_in[11:7])) ? 7'h3 : 7'h1F;
  // 主分类：{quadrant[1:0], funct3[2:0]}
  wire [4:0]      _io_out_T_2 = {io_in[1:0], io_in[15:13]};
  wire [31:0]     _io_out_T_26_bits =
    _io_out_T_2 == 5'hC
      ? ((&(io_in[11:10]))
           ? ((&{io_in[12], io_in[6:5]})
                ? ((&(io_in[4:2])) | io_in[4:2] == 3'h6
                     ? 32'h0
                     : io_in[4:2] == 3'h5
                         ? {14'h3FFD, io_in[9:7], 5'h11, io_in[9:7], 7'h13}
                         : {1'h0,
                            io_in[4:2] == 3'h4
                              ? {13'h201, io_in[9:7], 5'h1, io_in[9:7], 7'h3B}
                              : io_in[4:2] == 3'h3
                                  ? {13'h1815, io_in[9:7], 5'h5, io_in[9:7], 7'h13}
                                  : io_in[4:2] == 3'h2
                                      ? {13'h201, io_in[9:7], 5'h11, io_in[9:7], 7'h3B}
                                      : {io_in[4:2] == 3'h1
                                           ? {13'h1811, io_in[9:7], 5'h5}
                                           : {13'h3FD, io_in[9:7], 5'h1D},
                                         io_in[9:7],
                                         7'h13}})
                : {1'h0,
                   io_in[6:5] == 2'h0,
                   4'h0,
                   {io_in[12], io_in[6:5]} == 3'h6,
                   2'h1,
                   io_in[4:2],
                   2'h1,
                   io_in[9:7],
                   _GEN[_io_out_s_funct_T_2],
                   2'h1,
                   io_in[9:7],
                   io_in[12] ? {3'h3, ~(io_in[6]), 3'h3} : 7'h33})
           : {io_in[11:10] == 2'h2
                ? {{7{io_in[12]}}, io_in[6:2], 2'h1, io_in[9:7], 5'h1D}
                : {1'h0,
                   io_in[11:10] == 2'h1,
                   4'h0,
                   io_in[12],
                   io_in[6:2],
                   2'h1,
                   io_in[9:7],
                   5'h15},
              io_in[9:7],
              7'h13})
      : _io_out_T_2 == 5'hB
          ? (io_in[7] & io_in[6:2] == 5'h0 & io_in[12:11] == 2'h0
               ? 32'h13
               : {{3{io_in[12]}},
                  io_in[11:7] == 5'h2
                    ? {io_in[4:3],
                       io_in[5],
                       io_in[2],
                       io_in[6],
                       4'h0,
                       io_in[11:7],
                       3'h0,
                       io_in[11:7],
                       (|{{7{io_in[12]}}, io_in[6:2]}) ? 7'h13 : 7'h1F}
                    : {{12{io_in[12]}},
                       io_in[6:2],
                       io_in[11:7],
                       3'h3,
                       {{7{io_in[12]}}, io_in[6:2]} == 12'h0,
                       3'h7}})
          : _io_out_T_2 == 5'hA
              ? {{7{io_in[12]}}, io_in[6:2], 8'h0, io_in[11:7], 7'h13}
              : _io_out_T_2 == 5'h9
                  ? {{7{io_in[12]}},
                     io_in[6:2],
                     io_in[11:7],
                     3'h0,
                     io_in[11:7],
                     4'h3,
                     io_in[11:7] == 5'h0,
                     2'h3}
                  : _io_out_T_2 == 5'h8
                      ? ((|(io_in[11:7]))
                           ? {{7{io_in[12]}},
                              io_in[6:2],
                              io_in[11:7],
                              3'h0,
                              io_in[11:7],
                              7'h13}
                           : 32'h13)
                      : _io_out_T_2 == 5'h7
                          ? {4'h0,
                             io_in[6:5],
                             io_in[12],
                             2'h1,
                             io_in[4:2],
                             2'h1,
                             io_in[9:7],
                             3'h3,
                             io_in[11:10],
                             10'h23}
                          : _io_out_T_2 == 5'h6
                              ? {5'h0,
                                 io_in[5],
                                 io_in[12],
                                 2'h1,
                                 io_in[4:2],
                                 2'h1,
                                 io_in[9:7],
                                 3'h2,
                                 io_in[11:10],
                                 io_in[6],
                                 9'h23}
                              : _io_out_T_2 == 5'h5
                                  ? {4'h0,
                                     io_in[6:5],
                                     io_in[12],
                                     2'h1,
                                     io_in[4:2],
                                     2'h1,
                                     io_in[9:7],
                                     3'h3,
                                     io_in[11:10],
                                     10'h27}
                                  : _io_out_T_2 == 5'h4
                                      ? {7'h0,
                                         (&(io_in[11:10]))
                                           ? {2'h1,
                                              io_in[4:2],
                                              2'h1,
                                              io_in[9:7],
                                              6'h8,
                                              io_in[5],
                                              8'h23}
                                           : io_in[11:10] == 2'h2
                                               ? {2'h1,
                                                  io_in[4:2],
                                                  2'h1,
                                                  io_in[9:7],
                                                  6'h0,
                                                  io_in[5],
                                                  io_in[6],
                                                  7'h23}
                                               : {3'h0,
                                                  io_in[5],
                                                  io_in[11:10] == 2'h1
                                                    ? {3'h1,
                                                       io_in[9:7],
                                                       ~(io_in[6]),
                                                       4'h5}
                                                    : {io_in[6], 2'h1, io_in[9:7], 5'h11},
                                                  io_in[4:2],
                                                  7'h3}}
                                      : _io_out_T_2 == 5'h3
                                          ? {4'h0,
                                             io_in[6:5],
                                             io_in[12:10],
                                             5'h1,
                                             io_in[9:7],
                                             5'hD,
                                             io_in[4:2],
                                             7'h3}
                                          : _io_out_T_2 == 5'h2
                                              ? {5'h0,
                                                 io_in[5],
                                                 io_in[12:10],
                                                 io_in[6],
                                                 4'h1,
                                                 io_in[9:7],
                                                 5'h9,
                                                 io_in[4:2],
                                                 7'h3}
                                              : _io_out_T_2 == 5'h1
                                                  ? {4'h0,
                                                     io_in[6:5],
                                                     io_in[12:10],
                                                     5'h1,
                                                     io_in[9:7],
                                                     5'hD,
                                                     io_in[4:2],
                                                     7'h7}
                                                  : {2'h0,
                                                     io_in[10:7],
                                                     io_in[12:11],
                                                     io_in[5],
                                                     io_in[6],
                                                     12'h41,
                                                     io_in[4:2],
                                                     (|(io_in[12:5])) ? 7'h13 : 7'h1F};
  wire [4:0]      _io_ill_T_2 = {io_in[1:0], io_in[15:13]};
  // 高优先级类别（已是 32 位/特殊编码）直接透传 io_in，否则进入上面的展开树
  assign io_out_bits =
    (&_io_out_T_2) | _io_out_T_2 == 5'h1E | _io_out_T_2 == 5'h1D | _io_out_T_2 == 5'h1C
    | _io_out_T_2 == 5'h1B | _io_out_T_2 == 5'h1A | _io_out_T_2 == 5'h19
    | _io_out_T_2 == 5'h18
      ? io_in
      : _io_out_T_2 == 5'h17
          ? {3'h0, io_in[9:7], io_in[12], io_in[6:2], 8'h13, io_in[11:10], 10'h23}
          : _io_out_T_2 == 5'h16
              ? {4'h0, io_in[8:7], io_in[12], io_in[6:2], 8'h12, io_in[11:9], 9'h23}
              : _io_out_T_2 == 5'h15
                  ? {3'h0, io_in[9:7], io_in[12], io_in[6:2], 8'h13, io_in[11:10], 10'h27}
                  : _io_out_T_2 == 5'h14
                      ? (io_in[12]
                           ? {7'h0,
                              (|(io_in[6:2]))
                                ? {io_in[6:2], io_in[11:7], 3'h0, io_in[11:7], 7'h33}
                                : (|(io_in[11:7]))
                                    ? {io_in[6:2], io_in[11:7], 15'hE7}
                                    : {io_in[6:3], 1'h1, io_in[11:7], 15'h73}}
                           : (|(io_in[6:2]))
                               ? {12'h0, io_in[6:2], 3'h0, io_in[11:7], 7'h13}
                               : {7'h0,
                                  io_in[6:2],
                                  io_in[11:7],
                                  (|(io_in[11:7])) ? 15'h67 : 15'h1F})
                      : _io_out_T_2 == 5'h13
                          ? {3'h0,
                             io_in[4:2],
                             io_in[12],
                             io_in[6:5],
                             11'h13,
                             io_in[11:7],
                             io_out_s_load_opc}
                          : _io_out_T_2 == 5'h12
                              ? {4'h0,
                                 io_in[3:2],
                                 io_in[12],
                                 io_in[6:4],
                                 10'h12,
                                 io_in[11:7],
                                 io_out_s_load_opc}
                              : _io_out_T_2 == 5'h11
                                  ? {3'h0,
                                     io_in[4:2],
                                     io_in[12],
                                     io_in[6:5],
                                     11'h13,
                                     io_in[11:7],
                                     7'h7}
                                  : _io_out_T_2 == 5'h10
                                      ? {6'h0,
                                         io_in[12],
                                         io_in[6:2],
                                         io_in[11:7],
                                         3'h1,
                                         io_in[11:7],
                                         7'h13}
                                      : _io_out_T_2 == 5'hF
                                          ? {_GEN_0,
                                             io_in[6:5],
                                             io_in[2],
                                             7'h1,
                                             io_in[9:7],
                                             3'h1,
                                             io_in[11:10],
                                             io_in[4:3],
                                             io_in[12],
                                             7'h63}
                                          : _io_out_T_2 == 5'hE
                                              ? {_GEN_0,
                                                 io_in[6:5],
                                                 io_in[2],
                                                 7'h1,
                                                 io_in[9:7],
                                                 3'h0,
                                                 io_in[11:10],
                                                 io_in[4:3],
                                                 io_in[12],
                                                 7'h63}
                                              : _io_out_T_2 == 5'hD
                                                  ? {io_in[12],
                                                     io_in[8],
                                                     io_in[10:9],
                                                     io_in[6],
                                                     io_in[7],
                                                     io_in[2],
                                                     io_in[11],
                                                     io_in[5:3],
                                                     {9{io_in[12]}},
                                                     12'h6F}
                                                  : _io_out_T_26_bits;
  // 合法性：部分类别恒合法（透传），其余按编码字段判定，浮点类受 io_fsIsOff 影响
  assign io_ill =
    ~((&_io_ill_T_2) | _io_ill_T_2 == 5'h1E | _io_ill_T_2 == 5'h1D | _io_ill_T_2 == 5'h1C
      | _io_ill_T_2 == 5'h1B | _io_ill_T_2 == 5'h1A | _io_ill_T_2 == 5'h19
      | _io_ill_T_2 == 5'h18 | _io_ill_T_2 == 5'h17 | _io_ill_T_2 == 5'h16)
    & (_io_ill_T_2 == 5'h15
         ? io_fsIsOff
         : _io_ill_T_2 == 5'h14
             ? io_in[12:2] == 11'h0
             : _io_ill_T_2 == 5'h13
                 ? ~(|(io_in[11:7]))
                 : _io_ill_T_2 == 5'h12
                     ? ~(|(io_in[11:7]))
                     : _io_ill_T_2 == 5'h11
                         ? io_fsIsOff
                         : ~(_io_ill_T_2 == 5'h10 | _io_ill_T_2 == 5'hF
                             | _io_ill_T_2 == 5'hE | _io_ill_T_2 == 5'hD)
                           & (_io_ill_T_2 == 5'hC
                                ? (&(io_in[12:10])) & (&(io_in[6:3]))
                                : _io_ill_T_2 == 5'hB
                                    ? ~(io_in[12] | (|(io_in[6:2])))
                                      & ~(~(io_in[11]) & io_in[7])
                                    : _io_ill_T_2 != 5'hA
                                      & (_io_ill_T_2 == 5'h9
                                           ? ~(|(io_in[11:7]))
                                           : ~(_io_ill_T_2 == 5'h8 | _io_ill_T_2 == 5'h7
                                               | _io_ill_T_2 == 5'h6)
                                             & (_io_ill_T_2 == 5'h5
                                                  ? io_fsIsOff
                                                  : _io_ill_T_2 == 5'h4
                                                      ? io_in[12] | io_in[11] & io_in[10]
                                                        & io_in[6]
                                                      : ~(_io_ill_T_2 == 5'h3
                                                          | _io_ill_T_2 == 5'h2)
                                                        & (_io_ill_T_2 == 5'h1
                                                             ? io_fsIsOff
                                                             : io_in[12:5] == 8'h0)))));
endmodule
