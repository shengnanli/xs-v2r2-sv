#!/usr/bin/env python3
"""生成 CryptoModule 的 UT testbench（tb.sv）：双例化逐拍比对 + 哈希分支独立参考模型。

一、双例化（scripts/dual_tb_lib.py，端口表读 G1 golden）：golden CryptoModule（例化 golden HashModule /
   BlockCipherModule）vs 重写 CryptoModule_xs（例化重写件 HashModule_xs / BlockCipherModule_xs），逐拍比 io_out。
   本模块只有 clock、无 reset，全部寄存器无复位：第一次 regEnable 之后才开始比（arm）。
   func 偏置：1/2 拍取合法密码编码（0x20..0x2F 分组密码类 / 0x30..0x39 哈希类），其余拍任意 9 位
   （证明 funcReg 只看 bit4、其余位两侧同死）；regEnable 3/4 拍为 1，1/4 拍为 0（保持路径）。
二、独立参考模型（只覆盖哈希分支，纯 SV，不读任一实现的内部信号）：tb 自己在 regEnable 拍锁存
   src0 / func，下一拍起若锁存的 func 是合法哈希编码（0x30..0x37 SHA-256/512 Σ/σ，0x38/0x39 SM3 P0/P1），
   按 RISC-V Zknh/Zksh 定义算期望值，与 golden 和重写件的 io_out 同时核对。
   分组密码分支的独立参考模型在 verif/ut/BlockCipherModule（查表 S 盒 + FIPS-197 / GB/T 32907 向量），本层只做差分。
覆盖闸：哈希 10 条指令各被 oracle 判过 >= 100 次；输出选择两路各 >= 100 拍；regEnable 保持拍 >= 100；
   io_out 每位见过 0/1。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = r"""
logic [63:0] ref_src;
logic [8:0]  ref_func;
int ref_checks = 0, ref_errors = 0;
function automatic logic [31:0] ref_ror32(input logic [31:0] x, input int n);
  return (x >> n) | (x << (32 - n));
endfunction
function automatic logic [63:0] ref_ror64(input logic [63:0] x, input int n);
  return (x >> n) | (x << (64 - n));
endfunction
function automatic logic [31:0] ref_rol32(input logic [31:0] x, input int n);
  return (x << n) | (x >> (32 - n));
endfunction
// Zknh / Zksh 指令定义（规范原式；SM3 用左旋写法，与 Chisel 的右旋写法独立）
function automatic logic [63:0] ref_hash(input logic [63:0] x, input logic [8:0] f);
  logic [31:0] w, r;
  w = x[31:0];
  case (f)
    9'h30: begin r = ref_ror32(w, 2) ^ ref_ror32(w, 13) ^ ref_ror32(w, 22); return {{32{r[31]}}, r}; end
    9'h31: begin r = ref_ror32(w, 6) ^ ref_ror32(w, 11) ^ ref_ror32(w, 25); return {{32{r[31]}}, r}; end
    9'h32: begin r = ref_ror32(w, 7) ^ ref_ror32(w, 18) ^ (w >> 3);         return {{32{r[31]}}, r}; end
    9'h33: begin r = ref_ror32(w, 17) ^ ref_ror32(w, 19) ^ (w >> 10);       return {{32{r[31]}}, r}; end
    9'h34: return ref_ror64(x, 28) ^ ref_ror64(x, 34) ^ ref_ror64(x, 39);
    9'h35: return ref_ror64(x, 14) ^ ref_ror64(x, 18) ^ ref_ror64(x, 41);
    9'h36: return ref_ror64(x, 1) ^ ref_ror64(x, 8) ^ (x >> 7);
    9'h37: return ref_ror64(x, 19) ^ ref_ror64(x, 61) ^ (x >> 6);
    9'h38: begin r = w ^ ref_rol32(w, 9) ^ ref_rol32(w, 17);  return {{32{r[31]}}, r}; end
    default: begin r = w ^ ref_rol32(w, 15) ^ ref_rol32(w, 23); return {{32{r[31]}}, r}; end
  endcase
endfunction
// 比较点（negedge 后 #4，与差分同一时刻）：锁存的 func 是合法哈希编码才判
always @(negedge clk) begin
  #4;
  if (tb.cm_armed_at >= 0 && cyc >= tb.cm_armed_at && ref_func >= 9'h30 && ref_func <= 9'h39) begin
    ref_checks++;
    if (tb.cm_g_io_out !== ref_hash(ref_src, ref_func) || tb.cm_i_io_out !== ref_hash(ref_src, ref_func)) begin
      ref_errors++; errors++;
      if (ref_errors <= 10) $display("[ORACLE] cyc=%0d func=%h src=%h ref=%h g=%h i=%h", cyc, ref_func, ref_src,
                                     ref_hash(ref_src, ref_func), tb.cm_g_io_out, tb.cm_i_io_out);
    end
  end
end
always @(posedge clk) if (tb.cm_io_regEnable) begin ref_src <= tb.cm_io_src_0; ref_func <= tb.cm_io_func; end
final $display("[ORACLE] hash checks=%0d errors=%0d", ref_checks, ref_errors);
"""

STIM = r"""
case ($urandom_range(0, 3))
  0: @io_func = 9'h20 + $urandom_range(0, 15);   // 分组密码类 aes*/sm4*
  1: @io_func = 9'h30 + $urandom_range(0, 9);    // 哈希类 sha*/sm3*
  default: ;                                      // 任意 9 位
endcase
@io_regEnable = ($urandom_range(0, 3) != 0);
"""

pair = Pair(
    top="CryptoModule", pfx="cm_", clocked=True, has_reset=False,
    decls=DECLS, stim=STIM,
    arm=["@io_regEnable"],
    cov=[
        ("sel_hash", "ref_func[4]"),
        ("sel_cipher", "!ref_func[4]"),
        ("hold", "!@io_regEnable"),
    ] + [(f"oracle_{0x30 + k:02x}", f"ref_func == 9'h{0x30 + k:02x}") for k in range(10)],
)
txt = render([pair], header=__doc__.strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
