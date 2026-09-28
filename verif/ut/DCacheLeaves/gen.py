#!/usr/bin/env python3
"""生成 DCacheLeaves 的双例化 UT testbench（tb.sv）。

DCache 的 7 个小 child 放在一个 tb 里各自双例化（golden <Top> vs 重写 <Top>_xs），
每拍逐位比较全部输出，端口表从 G1 golden 现读（scripts/dual_tb_lib.py）：
  Arbiter1_TagWriteReq / Arbiter1_L1BankedDataWriteReq / Arbiter1_L1BankedDataWriteReqCtrl
      单入直通；覆盖 = 每个输出位见过 0/1。
  TreeArbiter   4 路固定优先级；valid 位图按模式偏置，覆盖每一路单独胜出/无人请求/out_ready=0。
  MissReadyGen  4 口就绪预算；覆盖每一口 ready=1 与被更高优先级压住。
  PrefetcherMonitor  窗口计数器 + 开关；激励分阶段偏置到"坏预取多/晚到命中多/晚到 miss 多/安静"，
      覆盖 trigger_disable / trigger_late_hit / late_miss 压住 late_hit / 退避恢复 / 窗口结束。
  FDPrefetcherMonitor  golden 无输出：只做 elaborate 与端口连通（0 比较点，见 RTL 文件头）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

TREE_STIM = """
// valid 位图：mode 0-3 单热、4-7 全随机、8-11 稀疏（每路 1/4）、12-15 全 0
case (@mode[3:2])
  2'd0: {@io_in_0_valid, @io_in_1_valid, @io_in_2_valid, @io_in_3_valid} = 4'b1000 >> $urandom_range(0, 3);
  2'd1: ;
  2'd2: {@io_in_0_valid, @io_in_1_valid, @io_in_2_valid, @io_in_3_valid} =
          {$urandom_range(0,3)==0, $urandom_range(0,3)==0, $urandom_range(0,3)==0, $urandom_range(0,3)==0};
  2'd3: if ($urandom_range(0, 3) == 0) {@io_in_0_valid, @io_in_1_valid, @io_in_2_valid, @io_in_3_valid} = 4'b0;
endcase
"""

TREE_COV = [
    ("win0", "@io_in_0_valid"),
    ("win1", "!@io_in_0_valid && @io_in_1_valid"),
    ("win2", "!@io_in_0_valid && !@io_in_1_valid && @io_in_2_valid"),
    ("win3", "!@io_in_0_valid && !@io_in_1_valid && !@io_in_2_valid && @io_in_3_valid"),
    ("none", "!@io_in_0_valid && !@io_in_1_valid && !@io_in_2_valid && !@io_in_3_valid"),
    ("stall", "@io_out_valid && !@io_out_ready"),
]

MRG_STIM = """
if (@mode[0]) {@io_in_0_valid, @io_in_1_valid, @io_in_2_valid} = 3'b0;
"""

MRG_COV = [
    ("rdy0", "@io_in_0_ready"),
    ("rdy1", "@io_in_1_ready"),
    ("rdy2", "@io_in_2_ready"),
    ("rdy3", "@io_in_3_ready"),
    ("block1", "@io_queryMQ_1_ready && @io_in_0_valid"),
    ("block2", "@io_queryMQ_2_ready && !@io_in_0_valid && @io_in_1_valid"),
    ("block3", "@io_queryMQ_3_ready && !@io_in_0_valid && !@io_in_1_valid && @io_in_2_valid"),
]

# PrefetcherMonitor：输入是事件脉冲，按 mode 分阶段偏置概率（百分比）
PFM_STIM = """
int unsigned p_tot, p_lh, p_lm, p_good, p_bad;
case (@mode[2:0])
  3'd0: begin p_tot = 50; p_lh = 50; p_lm = 50; p_good = 50; p_bad = 50; end  // 全随机
  3'd1: begin p_tot = 60; p_lh = 5;  p_lm = 5;  p_good = 5;  p_bad = 95; end  // 坏预取多 -> trigger_disable
  3'd2: begin p_tot = 5;  p_lh = 97; p_lm = 2;  p_good = 50; p_bad = 50; end  // 晚到命中多 -> trigger_late_hit
  3'd3: begin p_tot = 5;  p_lh = 97; p_lm = 60; p_good = 50; p_bad = 50; end  // late_miss 压住 late_hit
  3'd4: begin p_tot = 0;  p_lh = 0;  p_lm = 0;  p_good = 0;  p_bad = 0;  end  // 安静：让退避计时走完
  3'd5: begin p_tot = 99; p_lh = 1;  p_lm = 30; p_good = 95; p_bad = 5;  end  // total 先到 1000
  default: begin p_tot = 50; p_lh = 90; p_lm = 25; p_good = 10; p_bad = 90; end
endcase
@io_timely_total_prefetch     = $urandom_range(0, 99) < p_tot;
@io_timely_late_hit_prefetch  = $urandom_range(0, 99) < p_lh;
@io_timely_late_miss_prefetch = $urandom_range(0, 99) < p_lm;
@io_validity_good_prefetch    = $urandom_range(0, 99) < p_good;
@io_validity_bad_prefetch     = $urandom_range(0, 99) < p_bad;
"""

PFM_COV = [
    ("timely_reset", "pfm_u_gold.timely_reset"),
    ("validity_reset", "pfm_u_gold.validity_reset"),
    ("trigger_disable", "pfm_u_gold.trigger_disable_probe"),
    ("trigger_late_hit_only",
     "pfm_u_gold.timely_reset && pfm_u_gold.late_hit_prefetch_cnt > 11'h383 && !(pfm_u_gold.late_miss_prefetch_cnt > 11'hC7)"),
    ("late_miss_masks_late_hit",
     "pfm_u_gold.timely_reset && pfm_u_gold.late_hit_prefetch_cnt > 11'h383 && pfm_u_gold.late_miss_prefetch_cnt > 11'hC7"),
    ("back_off_reset", "pfm_u_gold.back_off_reset"),
    ("enable_off", "!@io_pf_ctrl_enable"),
]

PAIRS = [
    Pair("Arbiter1_TagWriteReq", "atw_"),
    Pair("Arbiter1_L1BankedDataWriteReq", "adw_"),
    Pair("Arbiter1_L1BankedDataWriteReqCtrl", "adc_"),
    Pair("TreeArbiter", "tra_", stim=TREE_STIM, cov=TREE_COV, mode_period=64, cov_min=1000),
    Pair("MissReadyGen", "mrg_", stim=MRG_STIM, cov=MRG_COV, mode_period=16, cov_min=1000),
    # back_off_reset 在 200k 拍里只可能出现个位数次（每次要累计关 100000 拍），门槛取 1；
    # 中途复位会清掉退避计数，所以本对只打上电复位（reset_period=0）；
    # conf_reset 要关 200000 拍，200k 拍的 UT 结构上到不了，不设闸（FM 覆盖，见 Makefile）。
    Pair("PrefetcherMonitor", "pfm_", clocked=True, stim=PFM_STIM, cov=PFM_COV,
         mode_period=6000, reset_period=0, cov_min=1),
    Pair("FDPrefetcherMonitor", "fdp_"),
]

HEADER = """自动生成：verif/ut/DCacheLeaves/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
DCache 小 child 双例化逐拍比对：golden <Top> vs 重写 <Top>_xs，全部输出逐位 !==。
覆盖闸：每个输出位见过 0/1 + 各对的分支计数（见 gen.py）。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
