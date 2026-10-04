#!/usr/bin/env python3
"""生成 PBestOffsetPrefetch 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden PBestOffsetPrefetch vs PBestOffsetPrefetch_xs（child 两侧各用各的：golden 侧 golden child，
重写侧本仓重写 child；厂商 SRAM 宏两侧共用 golden 行为模型），全部输出逐拍逐位 !==。
激励偏置（让 BOP 真的学到偏移并发出预取）：
  * 训练地址取自一个 8 页的小池子，页内块号是"基址 + 小步长 × k"——相同步长的流让 scoreTable
    的某个候选偏移得高分、rrTable 命中；
  * io_pfCtrlOfDelayLatency 取 0..15 小值（延迟太大 rrTable 很久写不进去）；
  * io_enable 7/8 时间为 1；io_req_ready 随机（3/4）；
  * MBIST / SRAM DFT 口 15/16 时间钉 0，其余时间随机（DFT 透传与 bore 读回也要比到）。
不复位的 req_{tag,set,needT,source}，以及 rrTable 里 SRAMTemplate_146 不复位的 MBIST 读回寄存器 rdataReg
（直出 boreChildrenBd_bore_rdata）：第一次训练被收下、且 SRAM 第一次读（respReg）之后再过 1 拍才开始比（arm）。

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
X = "pb_"

STIM = "\n".join([
    "@io_enable = ($urandom_range(0, 7) != 0);",
    "@io_pfCtrlOfDelayLatency = 10'($urandom_range(0, 15));",
    "@io_train_valid = ($urandom_range(0, 1) != 0);",
    "begin logic [41:0] a; a = pb_blk(); @io_train_bits_tag = a[41:9]; @io_train_bits_set = a[8:0]; end",
    "@io_req_ready = ($urandom_range(0, 3) != 0);",
    "if (pb_mode != 0) begin",
] + ["  @%s = '0;" % d for d in DFT] + ["end"])

DECLS = """
logic [35:0] pb_page [8];            // 8 个物理页号（块地址 42 位 = {36 位页号, 6 位页内块号}）
int unsigned pb_k = 0;
int          pb_step = 1;
initial for (int i = 0; i < 8; i++) pb_page[i] = 36'({$urandom, $urandom});
function automatic logic [41:0] pb_blk();
  // 页内块号 = (k × step) mod 64 —— 同一步长的流；偶尔换步长、换页
  if ($urandom_range(0, 255) == 0) pb_step = $urandom_range(1, 9) * (($urandom_range(0, 1) != 0) ? 1 : -1);
  if ($urandom_range(0, 1023) == 0) pb_page[$urandom_range(0, 7)] = 36'({$urandom, $urandom});   // 偶尔换一页，高位也翻得到
  pb_k++;
  return {pb_page[$urandom_range(0, 7)], 6'(pb_k * pb_step)};
endfunction
"""

COV = [
    ("train_fire", "@io_train_valid && @io_train_ready"),
    ("req_fire", "@io_req_valid && @io_req_ready"),
    ("req_stall", "@io_req_valid && !@io_req_ready"),
    ("train_blocked", "@io_train_valid && !@io_train_ready"),
    ("resp_ready_low", "!@io_resp_ready"),
    ("bore_rdata_nz", "@boreChildrenBd_bore_rdata != 0"),
    ("reset_mid", "@reset && cyc > 100"),
    # 本层内部分支（golden 侧内部信号）：跨页丢弃、scoreTable 禁用丢弃
    ("cross_page_drop", "pb_u_gold._GEN_0 && pb_u_gold.crossPage"),
    ("disable_drop", "pb_u_gold._GEN_0 && pb_u_gold._scoreTable_io_prefetchDisable"),
    ("enable_low_full", "!@io_enable && pb_u_gold.req_valid"),
]

PAIRS = [Pair("PBestOffsetPrefetch", X, clocked=True, stim=STIM, cov=COV, decls=DECLS,
              reset_period=20000, mode_period=2000, cov_min=5,
              arm=["@io_train_valid && @io_train_ready", "pb_u_gold.rrTable.rrTable.respReg"], arm_delay=1,
              exempt=["io_req_bits_vaddr"])]   # 物理版恒 0

HEADER = """自动生成：verif/ut/PBestOffsetPrefetch/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
PBestOffsetPrefetch 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
