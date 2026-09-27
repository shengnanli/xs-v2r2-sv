// SignDec —— SRT 除法器的相邻符号关系解码器。
// 四个输入符号描述连续的部分余数候选；五位输出分别指示最上方同正、
// 正到负的跨越、以及后续两个边界的符号组合。输出不是 one-hot 编码，
// 而是下游选择逻辑直接使用的五个布尔条件。

module xs_SignDec_core (
  input  logic [3:0] signs,
  output logic [4:0] relation
);
  assign relation[4] =  signs[0] &  signs[1];
  assign relation[3] = ~signs[0] &  signs[1];
  assign relation[2] = ~signs[1] &  signs[2];
  assign relation[1] = ~signs[2] &  signs[3];
  assign relation[0] = ~signs[2] & ~signs[3];
endmodule


module SignDec (
  input  logic       io_sign_0,
  input  logic       io_sign_1,
  input  logic       io_sign_2,
  input  logic       io_sign_3,
  output logic [4:0] io_q
);
  xs_SignDec_core u_core (
    .signs   ({io_sign_3, io_sign_2, io_sign_1, io_sign_0}),
    .relation(io_q)
  );
endmodule
