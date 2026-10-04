#!/usr/bin/env python3
"""生成 Prefetcher 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden Prefetcher vs Prefetcher_xs（child 两侧各用各的：golden 侧 golden child，重写侧本仓重写 child；
SRAM 行为模型两侧共用 golden），全部输出逐拍逐位 !==。
激励偏置（训练流沿用 PBestOffsetPrefetch / VBestOffsetPrefetch 两个 UT 的做法）：
  * 训练：8 页小池子里"小步长 × k"的块号流；tag/set 与 vaddr 由同一个块号拼出，pbop / vbop 都学得到偏移；
    reqsource 1/4 时间是 L1DataPrefetch(6)（本层要把它滤掉）；
  * 预取控制：master_en 15/16、各 en 7/8、recv_en 7/8；delay_latency 0..15；
  * TLB 响应模型：golden 上一拍发出 tlb_req 则本拍 resp_valid=1（vbop 的 reqFilter 按固定节拍记账）；
  * 回填 io_resp：pfSource 多数取 8（vbop）/ 9（pbop），少量别的值；
  * recv_addr：valid 1/4，pfSource 7/8 取 SMS/Stream/Stride/Berti（10/11/12/14），1/8 随机；
  * io_req_ready 3/4，mode 1 相位（与开头 6000 拍，让 arm 早一点）恒 0；同样的相位 recv_addr 恒 valid（pfRcv 连续出请求，vbop/pbop 一直让路，
    vbop 的 reqFilter 16 项才塞得满）；
  * MBIST / SRAM DFT 口 15/16 时间钉 0。
不复位寄存器（两个 BOP 内部的 s1_* / SRAM 读回 / reqFilter 条目、pipe 的数据寄存器）：
各自第一次被写过之后再过 1 拍才开始比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

X = "pf_"
DFT = ["boreChildrenBd_bore_array", "boreChildrenBd_bore_all", "boreChildrenBd_bore_req",
       "boreChildrenBd_bore_writeen", "boreChildrenBd_bore_be", "boreChildrenBd_bore_readen"]
DFT += ["sigFromSrams_bore%s_%s" % (s, f) for s in ("", "_1")
        for f in ("ram_hold", "ram_bypass", "ram_bp_clken", "ram_aux_clk", "ram_aux_ckbp", "ram_mcp_hold", "cgen")]

STIM = "\n".join([
    "@pfCtrlFromCore_l2_pf_master_en = ($urandom_range(0, 15) != 0);",
    "@pfCtrlFromCore_l2_pf_recv_en = ($urandom_range(0, 7) != 0);",
    "@pfCtrlFromCore_l2_pbop_en = ($urandom_range(0, 7) != 0);",
    "@pfCtrlFromCore_l2_vbop_en = ($urandom_range(0, 7) != 0);",
    "@pfCtrlFromCore_l2_pf_delay_latency = 10'($urandom_range(0, 15));",
    "@io_train_valid = ($urandom_range(0, 1) != 0);",
    "begin logic [43:0] b; b = pf_blk(); @io_train_bits_vaddr = b; @io_train_bits_tag = b[41:9]; @io_train_bits_set = b[8:0]; end",
    "@io_train_bits_reqsource = ($urandom_range(0, 3) == 0) ? 5'd6 : 5'($urandom_range(0, 15));",
    "@io_req_ready = (pf_mode == 1 || cyc < 6000) ? 1'b0 : ($urandom_range(0, 3) != 0);",
    "@io_tlb_req_resp_valid = pf_tlb_q;",
    "pf_tlb_q = @io_tlb_req_req_valid;",
    "@io_tlb_req_resp_bits_miss = ($urandom_range(0, 3) == 0);",
    "@io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 19) == 0);",
    "@io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 19) == 0);",
    "@io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 19) == 0);",
    "@io_tlb_req_pmp_resp_ld = ($urandom_range(0, 9) == 0);",
    "@io_tlb_req_pmp_resp_mmio = ($urandom_range(0, 9) == 0);",
    "case ($urandom_range(0, 7))",
    "  0, 1, 2: @io_resp_bits_pfSource = 5'd8;",
    "  3, 4, 5: @io_resp_bits_pfSource = 5'd9;",
    "  default: ;",
    "endcase",
    "@io_recv_addr_valid = ($urandom_range(0, 3) == 0);",
    "case ($urandom_range(0, 7))",
    "  0, 1: @io_recv_addr_bits_pfSource = 5'd10;",
    "  2, 3: @io_recv_addr_bits_pfSource = 5'd11;",
    "  4:    @io_recv_addr_bits_pfSource = 5'd12;",
    "  5, 6: @io_recv_addr_bits_pfSource = 5'd14;",
    "  default: ;   // 1/8 随机值：Scala 的 assert 只在仿真里报，硬件照样透传（让 pfSource 高位也翻到）",
    "endcase",
    "if (pf_mode == 1 || cyc < 6000) begin   // mode 1（与开头 6000 拍）：pfRcv 连续出请求，vbop/pbop 一直让路，把 vbop reqFilter 16 项塞满",
    "  @io_recv_addr_valid = 1'b1;",
    "  @pfCtrlFromCore_l2_pf_master_en = 1'b1;",
    "  @pfCtrlFromCore_l2_pf_recv_en = 1'b1;",
    "end",
    "if (pf_mode != 0) begin",
] + ["  @%s = '0;" % d for d in DFT] + ["end"])

DECLS = """
logic [37:0] pf_page [8];            // 8 个页号（块号 44 位 = {38 位页号, 6 位页内块号}）
int unsigned pf_k = 0;
int          pf_step = 1;
logic        pf_tlb_q = 1'b0;        // 上一拍 golden 是否发了 tlb_req
initial for (int i = 0; i < 8; i++) pf_page[i] = 38'({$urandom, $urandom});
function automatic logic [43:0] pf_blk();
  if ($urandom_range(0, 255) == 0) pf_step = $urandom_range(1, 9) * (($urandom_range(0, 1) != 0) ? 1 : -1);
  if ($urandom_range(0, 1023) == 0) pf_page[$urandom_range(0, 7)] = 38'({$urandom, $urandom});
  pf_k++;
  return {pf_page[$urandom_range(0, 7)], 6'(pf_k * pf_step)};
endfunction
// vbop reqFilter 16 项条目数据不复位：每项至少被分配过一次后，出口 bits 两侧才同值
logic [15:0] pf_alloc_seen = '0;
always @(posedge clk) pf_alloc_seen <= pf_alloc_seen | {%s};
""" % ", ".join("pf_u_gold.vbop.reqFilter.alloc_%d" % i for i in range(15, -1, -1))

G = "pf_u_gold"
COV = [
    ("train_filtered", "@io_train_valid && @io_train_bits_reqsource == 5'd6"),
    ("pbop_req", "%s._pbop_io_req_valid" % G),
    ("vbop_req", "%s._vbop_io_req_valid" % G),
    ("rcv_req", "%s._pfRcv_io_req_valid" % G),
    ("vbop_yield_rcv", "%s._vbop_io_req_valid && %s._pfRcv_io_req_valid" % (G, G)),
    ("pbop_yield_vbop", "%s._pbop_io_req_valid && %s._vbop_io_req_valid" % (G, G)),
    ("resp_pbop", "@io_resp_valid && @io_resp_bits_pfSource == 5'd9"),
    ("resp_vbop", "@io_resp_valid && @io_resp_bits_pfSource == 5'd8"),
    ("rcv_disabled", "!%s.pfRcv_en && %s.pfRcv_io_recv_addr_v_last_REG_1" % (G, G)),
    ("tlb_req", "@io_tlb_req_req_valid"),
    ("req_fire", "@io_req_valid && @io_req_ready"),
    ("req_stall", "@io_req_valid && !@io_req_ready"),
    ("bore_outdata_nz", "@boreChildrenBd_bore_outdata != 0"),
]

PAIRS = [Pair("Prefetcher", X, clocked=True, stim=STIM, cov=COV, decls=DECLS,
              reset_period=50000, mode_period=2000, cov_min=5,
              arm=["@io_train_valid && @io_train_ready", "%s.pbop.rrTable.rrTable.respReg" % G,
                   "%s.vbop._s0_fire_T" % G, "%s.vbop.rrTable.rrTable.respReg" % G,
                   "@io_tlb_req_req_valid", "&pf_alloc_seen", "@io_req_valid"],
              arm_delay=1,
              # vbop reqFilter 的 tlb_req 常量字段（块内偏移 6 位恒 0 / 常量寄存器）
              exempt=["io_tlb_req_req_bits_vaddr[%d]" % b for b in range(6)]
                     + ["io_tlb_req_req_bits_cmd", "io_tlb_req_req_bits_isPrefetch",
                        "io_tlb_req_req_bits_kill", "io_tlb_req_req_bits_no_translate"])]

HEADER = """自动生成：verif/ut/Prefetcher/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
Prefetcher 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
