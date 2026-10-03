#!/usr/bin/env python3
"""生成 FauFTB 的双例化 UT testbench（tb.sv）。

golden FauFTB（+ golden FauFTBWay ×32）vs 重写 FauFTB_xs（+ 重写 FauFTBWay_xs，已签核），scripts/dual_tb_lib.py，
端口表读 G1 golden，逐拍比全部输出（4 份 dup 的 S1 预测、entry_out、meta、perf）。

激励要点：
  · 预测 PC 与更新 PC 从同一个 48 项小池子取（tag = pc[16:1] 两两不同）——池子比 32 路大，表会被填满、
    PLRU 替换常发生；同一 tag 反复更新（命中写回、计数器饱和）；更新口的写旁路（本拍写同 tag）自然发生；
  · 4 份 dup 的 s0_pc / fire 各自独立随机（核只用 dup 0 算预测，其余只做 s1_pc 打拍）；
  · update 条目字段全随机（tarStat 含非法值 3，覆盖 Mux1H 全不选的那一支），br_taken_mask 随机，
    meta 低位随机（perf 的 hit/miss 两支）；
  · ubtb_enable 按阶段开关；复位每 ~30000 拍一次。
比较窗口：meta 两级打拍寄存器不复位 —— 等 golden 先后见过 s1_fire_0、s2_fire_0 再开比。
覆盖（golden 内部语义信号）：预测命中 / 更新命中写回 / 未命中走 PLRU 替换且表已满 / 计数器饱和停住 /
  fall-through 非法 / 两次 touch 同拍。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DECLS = """
logic [49:0] f_pool [48];
initial for (int k = 0; k < 48; k++) f_pool[k] = {$urandom, $urandom} & ~50'h1FFFE | (50'(k * 1237 + 5) << 1 & 50'h1FFFE);
"""
STIM = """
@io_in_bits_s0_pc_0 = f_pool[$urandom_range(0, 47)];
@io_in_bits_s0_pc_1 = f_pool[$urandom_range(0, 47)];
@io_in_bits_s0_pc_2 = f_pool[$urandom_range(0, 47)];
@io_in_bits_s0_pc_3 = f_pool[$urandom_range(0, 47)];
@io_update_bits_pc = f_pool[$urandom_range(0, 47)];
@io_update_valid = ($urandom_range(0, 3) != 0);
@io_ctrl_ubtb_enable = (f_mode != 3);
"""
g = "f_u_gold"
pair = Pair("FauFTB", "f_", clocked=True, reset_period=30000, stim=STIM, decls=DECLS, mode_period=3000,
            arm=["@io_s1_fire_0", "@io_s2_fire_0 && f_armed[0]"], arm_delay=2,
            cov=[("pred_hit", "|%s.s1_hit_oh && @io_s1_fire_0" % g),
                 ("update_hit_writeback", "%s.u_s1_valid && %s.u_s1_hit" % (g, g)),
                 ("replace_when_full", "%s.u_s1_valid && !%s.u_s1_hit && (&{%s}" % (g, g, ", ".join(
                     "%s.ways_%d.valid" % (g, w) for w in range(32))) + ")"),
                 ("ctr_sat_hold", "|{%s}" % ", ".join(
                     "%s.u_s1_ways_write_valid_%d && %s.u_s1_br_update_valids_0 && (&%s.ctrs_%d_0) && %s.u_s1_br_takens_0"
                     % (g, w, g, g, w, g) for w in range(32))),
                 ("fall_through_err", "@io_out_s1_full_pred_0_fallThroughErr && @io_out_s1_full_pred_0_hit"),
                 ("double_touch", "%s.replacer_touch_ways_0_valid_REG && %s.u_s1_valid" % (g, g))],
            cov_min=50,
            # 结构常量位（不是跑出来再填）：目标地址 bit0 恒 0（指令 2 字节对齐，Cat(..., 0.U(1.W))）；
            # last_stage_meta 只有低 6 位是 FauFTBMeta，高 510 位恒 0；perf 每路只有 bit0 有效。
            exempt=(["io_out_s1_full_pred_%d_%s[0]" % (d, f) for d in range(4)
                     for f in ("targets_0", "targets_1", "jalr_target")]
                    + ["io_out_last_stage_meta[%d]" % b for b in range(6, 516)]
                    + ["io_perf_%d_value[%d]" % (p, b) for p in range(2) for b in range(1, 6)]))
txt = render([pair], header=__doc__.split("用法")[0].strip())
sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, check="--check" in sys.argv))
