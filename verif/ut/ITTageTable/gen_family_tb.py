#!/usr/bin/env python3
"""生成 ITTageTable / _1.._4 与 TageBTable 六个 UT 目录的双例化 testbench（各自的 tb.sv）。

替换原先 scripts/gen_zj_ut.py 的"全随机端口"tb（2026-10-03 agent/bpu-tables）：那份 tb 从复位后第一拍就比，
而这几张表的读出数据来自 SRAM 读出保持寄存器与表项 SRAM（都不复位），只在 +vcs+initreg+0 下两侧碰巧同为 0；
random 初值档开比第 5 拍就分叉（seed 7 实测）—— tb 违反"先写后读"契约，不是 RTL 差异。
本生成器（scripts/dual_tb_lib.py，端口表读 G1 golden，逐拍比全部输出）：
  · 读 PC / 更新 PC 从 16 项小池子取；ghist 与折叠历史在大部分阶段同时为 0（两者天然一致，写进表的项能被
    同样的 PC 查中），其余阶段全随机；更新字段全随机（ITTageTable：alloc/correct/uValid/reset_u 各路径都走到）；
  · MBIST 测试口与 SRAM 广播控制位平时钉 0，mode>=14 阶段全随机；
  · 比较窗口：golden 发生过一次读请求握手（req.valid && req.ready）后再过 3 拍开比；
  · 覆盖（golden 端口语义）：读命中 / 更新写入 / 分配（ITTageTable）/ reset_u（ITTageTable）/ 基础表更新（TageBTable）。

用法：python3 verif/ut/ITTageTable/gen_family_tb.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
UT = os.path.normpath(os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check, golden_ports  # noqa: E402

DECLS = """
logic [49:0] p_pool [16];
initial for (int k = 0; k < 16; k++) p_pool[k] = {$urandom, $urandom} & ~50'h1;
"""


def mbist_off(top):
    return "\n".join("  @%s = '0;" % n for d, _, n in golden_ports(top)
                     if d == "input" and (n.endswith("_req") or n.endswith("_all") or n.startswith("sigFromSrams")))


def pair(top):
    ports = golden_ports(top)
    if top == "TageBTable":
        stim = """
@io_req_bits = p_pool[$urandom_range(0, 15)];
@io_update_pc = p_pool[$urandom_range(0, 15)];
if (p_mode < 14) begin
%s
end
""" % mbist_off(top)
        cov = [("read_fire", "@io_req_valid && @io_req_ready"),
               ("resp_valid", "@io_s1_resp_valid"),
               ("update_any", "@io_update_mask_0 || @io_update_mask_1")]
        arm = ["@io_req_valid && @io_req_ready"]
    else:
        zero_fh = "\n".join("  @%s = '0;" % n for _, _, n in ports if "_folded_hist" in n)
        stim = """
@io_req_bits_pc = p_pool[$urandom_range(0, 15)];
@io_update_pc = p_pool[$urandom_range(0, 15)];
@io_update_reset_u = ($urandom_range(0, 255) == 0);
if (p_mode < 12) begin
  @io_update_ghist = '0;
%s
end
if (p_mode < 14) begin
%s
end
""" % (zero_fh, mbist_off(top))
        cov = [("read_fire", "@io_req_valid && @io_req_ready"),
               ("resp_hit", "@io_resp_valid"),
               ("update_alloc", "@io_update_valid && @io_update_alloc"),
               ("update_correct", "@io_update_valid && !@io_update_alloc && @io_update_correct"),
               ("reset_u", "@io_update_reset_u")]
        arm = ["@io_req_valid && @io_req_ready"]
    return Pair(top, "p_", clocked=True, reset_period=40000, stim=stim, decls=DECLS, mode_period=2000,
                arm=arm, arm_delay=3, cov=cov, cov_min=20)


def main():
    check = "--check" in sys.argv[1:]
    rc = 0
    for top in ["ITTageTable", "ITTageTable_1", "ITTageTable_2", "ITTageTable_3", "ITTageTable_4", "TageBTable"]:
        txt = render([pair(top)], header=(__doc__.split("用法")[0].strip() + "\n\n本文件：" + top))
        rc |= write_or_check(os.path.join(UT, top, "tb.sv"), txt, check)
    return rc


if __name__ == "__main__":
    sys.exit(main())
