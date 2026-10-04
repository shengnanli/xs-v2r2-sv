#!/usr/bin/env python3
"""生成 PFEvent 的 UT testbench（tb.sv）：双例化逐拍比对 + 独立参考模型。

一、双例化（scripts/dual_tb_lib.py，端口表读 G1 golden）：golden PFEvent（24 个 golden perfEventsModule）vs
   重写 PFEvent_xs（24 个重写 perfEventsModule_xs），逐拍比 24 个 64 位输出。全部寄存器异步复位，
   上电复位 8 拍后即开始比；另按 1/40000 概率随机打复位。
二、独立参考模型（纯 SV，不读任何实现内部信号）：tb 自己存 24 个 64 位 mhpmevent 影子，按 RISC-V 特权规范
   + Sstc/Sscofpmf 字段布局建模：w.valid 且 addr ∈ [0x323, 0x33A] 时写第 addr-0x323 个；[57:55] 保留读 0；
   三个 OPTYPE 字段（[44:40]/[49:45]/[54:50]）WARL，只收合法值 {0 OR, 1 AND, 2 XOR, 4 ADD}，非法值保持原值；
   异步复位全 0。每拍把模型与 golden、重写件两侧输出逐个核对。
激励偏置：w.valid 1/2；addr 1/2 落在 24 个合法地址、1/8 落在相邻的 0x320..0x322 / 0x33B..0x33F（打边界），其余任意 12 位；
   写数据每个 OPTYPE 字段 1/2 取合法值、1/2 任意 5 位。
覆盖闸：24 个副本各被写 >= 100 次；OPTYPE 非法值被拒（保持）>= 100 次；边界外地址写 >= 100 次；
   每个输出位见过 0/1（豁免：保留位 [57:55] 恒 0；三个 OPTYPE 的 [4:3] —— 合法值 {0,1,2,4} 最大 0b00100，
   复位 0 之后只收合法值，这 6 位结构上恒 0）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

N = 24

cmp_lines = "\n".join(
    f"    if (tb.pf_g_io_hpmevent_{k} !== ref_ev[{k}] || tb.pf_i_io_hpmevent_{k} !== ref_ev[{k}]) begin\n"
    f"      ref_errors++; errors++;\n"
    f"      if (ref_errors <= 10) $display(\"[ORACLE] cyc=%0d hpmevent_{k} ref=%h g=%h i=%h\", cyc, ref_ev[{k}],"
    f" tb.pf_g_io_hpmevent_{k}, tb.pf_i_io_hpmevent_{k});\n"
    f"    end"
    for k in range(N))

DECLS = r"""
// ============================ 独立参考模型 ============================
logic [63:0] ref_ev [24];
int ref_checks = 0, ref_errors = 0, ref_rejects = 0;
function automatic bit ref_legal_op(input logic [4:0] op);
  return op == 5'd0 || op == 5'd1 || op == 5'd2 || op == 5'd4;
endfunction
function automatic logic [63:0] ref_write(input logic [63:0] old, input logic [63:0] d);
  logic [63:0] n;
  n = d;
  n[57:55] = 3'b000;                                   // 保留位读 0
  for (int f = 40; f <= 50; f += 5)                    // OPTYPE0/1/2：WARL，非法值保持
    if (!ref_legal_op(d[f +: 5])) n[f +: 5] = old[f +: 5];
  return n;
endfunction
always @(posedge clk or posedge tb.pf_reset) begin
  if (tb.pf_reset) begin
    for (int k = 0; k < 24; k++) ref_ev[k] <= '0;
  end else if (tb.pf_io_distribute_csr_w_valid && tb.pf_io_distribute_csr_w_bits_addr >= 12'h323
               && tb.pf_io_distribute_csr_w_bits_addr <= 12'h33A) begin
    ref_ev[tb.pf_io_distribute_csr_w_bits_addr - 12'h323] <=
      ref_write(ref_ev[tb.pf_io_distribute_csr_w_bits_addr - 12'h323], tb.pf_io_distribute_csr_w_bits_data);
    for (int f = 40; f <= 50; f += 5)
      if (!ref_legal_op(tb.pf_io_distribute_csr_w_bits_data[f +: 5])) ref_rejects++;
  end
end
always @(negedge clk) begin
  #4;
  if (cyc >= RESET_CYC) begin
    ref_checks++;
@CMP@
  end
end
final $display("[ORACLE] checks=%0d errors=%0d optype_rejects=%0d", ref_checks, ref_errors, ref_rejects);
""".replace("@CMP@", cmp_lines)

STIM = r"""
case ($urandom_range(0, 7))
  0, 1, 2, 3: @io_distribute_csr_w_bits_addr = 12'h323 + $urandom_range(0, 23);
  4: @io_distribute_csr_w_bits_addr = ($urandom_range(0, 1) == 0) ? 12'h320 + $urandom_range(0, 2) : 12'h33B + $urandom_range(0, 4);
  default: ;
endcase
for (int f = 40; f <= 50; f += 5)
  if ($urandom_range(0, 1) == 0) begin
    case ($urandom_range(0, 3))
      0: @io_distribute_csr_w_bits_data[f +: 5] = 5'd0;
      1: @io_distribute_csr_w_bits_data[f +: 5] = 5'd1;
      2: @io_distribute_csr_w_bits_data[f +: 5] = 5'd2;
      default: @io_distribute_csr_w_bits_data[f +: 5] = 5'd4;
    endcase
  end
"""

cov = [(f"wr{k}", f"@io_distribute_csr_w_valid && @io_distribute_csr_w_bits_addr == 12'h{0x323 + k:03X}")
       for k in range(N)]
cov.append(("wr_outside", "@io_distribute_csr_w_valid && (@io_distribute_csr_w_bits_addr inside {[12'h320:12'h322], [12'h33B:12'h33F]})"))
cov.append(("optype_reject", "@io_distribute_csr_w_valid && @io_distribute_csr_w_bits_addr inside {[12'h323:12'h33A]}"
            " && !(@io_distribute_csr_w_bits_data[44:40] inside {0, 1, 2, 4})"))

pair = Pair(
    top="PFEvent", pfx="pf_", clocked=True,
    decls=DECLS, stim=STIM, cov=cov,
    exempt=[f"io_hpmevent_{k}[{b}]" for k in range(N) for b in (43, 44, 48, 49, 53, 54, 55, 56, 57)],
)
txt = render([pair], header=__doc__.strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
