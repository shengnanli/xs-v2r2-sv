#!/usr/bin/env python3
"""生成 VBestOffsetPrefetch 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden VBestOffsetPrefetch vs VBestOffsetPrefetch_xs（child 两侧各用各的：golden 侧 golden child，
重写侧本仓重写 child；厂商 SRAM 宏两侧共用 golden 行为模型），全部输出逐拍逐位 !==。
激励偏置：
  * 训练虚地址取自 8 页小池子，页内块号是"小步长 × k"的流（让 scoreTable 学到偏移、rrTable 命中）；
  * TLB 响应模型：golden 上一拍发出 tlb_req（req_valid=1）则本拍 resp_valid=1——reqFilter 按
    "s1 发 / s2 收"的固定节拍记账；回答 1/4 miss、少量 pf/gpf/af、pbmt/paddr 随机，PMP 每拍随机；
  * io_pfCtrlOfDelayLatency 0..15；io_enable 7/8 为 1；io_req_ready 3/4，mode 1 相位（约 1/16 时间）恒 0
    让 reqFilter 16 项全部占满（否则第 16 项几乎分配不到）；
  * MBIST / SRAM DFT 口 15/16 时间钉 0。
不复位寄存器（s1_* 与 rrTable 里 SRAM 的 MBIST 读回 rdataReg、reqFilter 的 tlb_req bits 寄存器）：
第一次 scoreTable 收训练、SRAM 第一次读、第一次 tlb_req、reqFilter 16 项都被分配过之后再过 1 拍才开始比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DFT = ["boreChildrenBd_bore_re", "boreChildrenBd_bore_we", "boreChildrenBd_bore_ack",
       "boreChildrenBd_bore_selectedOH", "boreChildrenBd_bore_array", "boreChildrenBd_bore_wmask",
       "sigFromSrams_bore_ram_hold", "sigFromSrams_bore_ram_bypass", "sigFromSrams_bore_ram_bp_clken",
       "sigFromSrams_bore_ram_aux_clk", "sigFromSrams_bore_ram_aux_ckbp",
       "sigFromSrams_bore_ram_mcp_hold", "sigFromSrams_bore_cgen"]
X = "vb_"

STIM = "\n".join([
    "@io_enable = ($urandom_range(0, 7) != 0);",
    "@io_pfCtrlOfDelayLatency = 10'($urandom_range(0, 15));",
    "@io_train_valid = ($urandom_range(0, 1) != 0);",
    "@io_train_bits_vaddr = vb_blk();",
    "@io_req_ready = (vb_mode == 1) ? 1'b0 : ($urandom_range(0, 3) != 0);   // mode 1：下游长时间不收，把 16 项填满",
    "@io_tlb_req_resp_valid = vb_tlb_q;",
    "vb_tlb_q = @io_tlb_req_req_valid;",
    "@io_tlb_req_resp_bits_miss = ($urandom_range(0, 3) == 0);",
    "@io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 19) == 0);",
    "@io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 19) == 0);",
    "@io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 19) == 0);",
    "@io_tlb_req_pmp_resp_ld = ($urandom_range(0, 9) == 0);",
    "@io_tlb_req_pmp_resp_mmio = ($urandom_range(0, 9) == 0);",
    "if (vb_mode != 0) begin",
] + ["  @%s = '0;" % d for d in DFT] + ["end"])

DECLS = """
logic [37:0] vb_page [8];            // 8 个虚拟页号（块号 44 位 = {38 位页号, 6 位页内块号}）
int unsigned vb_k = 0;
int          vb_step = 1;
logic        vb_tlb_q = 1'b0;        // 上一拍 golden 是否发了 tlb_req
initial for (int i = 0; i < 8; i++) vb_page[i] = 38'({$urandom, $urandom});
function automatic logic [43:0] vb_blk();
  if ($urandom_range(0, 255) == 0) vb_step = $urandom_range(1, 9) * (($urandom_range(0, 1) != 0) ? 1 : -1);
  if ($urandom_range(0, 1023) == 0) vb_page[$urandom_range(0, 7)] = 38'({$urandom, $urandom});   // 偶尔换一页，高位也翻得到
  vb_k++;
  return {vb_page[$urandom_range(0, 7)], 6'(vb_k * vb_step)};
endfunction
// reqFilter 16 项条目数据不复位：每项至少被分配（alloc）过一次后，出口 bits 两侧才有确定的同值
logic [15:0] vb_alloc_seen = '0;
always @(posedge clk) vb_alloc_seen <= vb_alloc_seen | {vb_u_gold.reqFilter.alloc_15, vb_u_gold.reqFilter.alloc_14, vb_u_gold.reqFilter.alloc_13, vb_u_gold.reqFilter.alloc_12, vb_u_gold.reqFilter.alloc_11, vb_u_gold.reqFilter.alloc_10, vb_u_gold.reqFilter.alloc_9, vb_u_gold.reqFilter.alloc_8, vb_u_gold.reqFilter.alloc_7, vb_u_gold.reqFilter.alloc_6, vb_u_gold.reqFilter.alloc_5, vb_u_gold.reqFilter.alloc_4, vb_u_gold.reqFilter.alloc_3, vb_u_gold.reqFilter.alloc_2, vb_u_gold.reqFilter.alloc_1, vb_u_gold.reqFilter.alloc_0};
"""

COV = [
    ("s0_fire", "vb_u_gold._s0_fire_T"),
    ("s1_hold", "vb_u_gold.s1_req_valid && !vb_u_gold.s1_ready"),
    ("disable_drop", "vb_u_gold.s1_req_valid && vb_u_gold._scoreTable_io_prefetchDisable"),
    ("tlb_req", "@io_tlb_req_req_valid"),
    ("req_fire", "@io_req_valid && @io_req_ready"),
    ("req_stall", "@io_req_valid && !@io_req_ready"),
    ("enable_low", "!@io_enable && vb_u_gold._reqFilter_io_out_req_valid"),
    ("bore_rdata_nz", "@boreChildrenBd_bore_rdata != 0"),
    ("reset_mid", "@reset && cyc > 100"),
]

PAIRS = [Pair("VBestOffsetPrefetch", X, clocked=True, stim=STIM, cov=COV, decls=DECLS,
              reset_period=20000, mode_period=2000, cov_min=5,
              arm=["vb_u_gold._s0_fire_T", "vb_u_gold.rrTable.rrTable.respReg", "@io_tlb_req_req_valid",
                   "&vb_alloc_seen"],
              arm_delay=1,
              # reqFilter 的 tlb_req 常量字段（RegEnable(常量) 寄存器 / 块内偏移 6 位恒 0）
              exempt=["io_tlb_req_req_bits_vaddr[%d]" % b for b in range(6)]
                     + ["io_tlb_req_req_bits_cmd", "io_tlb_req_req_bits_isPrefetch",
                        "io_tlb_req_req_bits_kill", "io_tlb_req_req_bits_no_translate"])]

HEADER = """自动生成：verif/ut/VBestOffsetPrefetch/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
VBestOffsetPrefetch 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
