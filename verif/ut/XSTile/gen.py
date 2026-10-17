#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）与 tb_pins.sv（子模块输入引脚逐拍比对）。
--check：生成到临时文件再与库里逐字比较，不写；--covcheck sim_<S>.log：判覆盖（见 scripts/gen_xscore_xstile.py ut_main）。

golden XSTile 与派生 XSTile_xs 双例化（两侧 core / l2top / 4 个 IntBuffer 是同一份 golden 定义），
同激励逐拍 4 态比全部输出。XSTile 本层是纯连线（0 寄存器），比的是 6 个子模块之间 408 根线与
顶层 150 个端口的接法。覆盖闸挑的是"跨子模块的几条主通路真的有流量"（golden 内部线，>0 拍）。
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'XSTile'
G = 'u_g_XSTile.'
# 覆盖闸：每条都是一根跨子模块的 golden 线（本层接线的一端），见 rtl/xstile/XSTile.sv 的分组
COVERS = {
    'immio_a':      f'{G}_core_auto_memBlock_inner_frontendBridge_instr_uncache_out_a_valid',  # core → l2top（指令 uncache A）
    'trace_v':      f'{G}_core_io_traceCoreInterface_toEncoder_groups_0_valid',        # core → l2top（trace 组 0）
    'msi_v':        f'{G}_l2top_io_msiInfo_toCore_valid',                               # l2top → core（MSI）
    'int_clint':    f'{G}_intBuffer_auto_out_0',                                        # intBuffer → core
    'int_plic':     f'{G}_intBuffer_1_auto_out_0_0',                                    # intBuffer_1 → core
    'int_debug':    f'{G}_intBuffer_2_auto_out_0',                                      # intBuffer_2 → core
    'int_nmi':      f'{G}_intBuffer_3_auto_out_0',                                      # intBuffer_3 → core
}
# 不设闸（20k 拍探针实测 0 或个位数）：L1D / ICache / PTW 的 TileLink A、各 D 回包、CHI 请求——tile 里核只走指令 uncache
#   取指（★ICache 为什么不发请求没查明★：同样的复位向量在 XSCore UT 里会走 ICache），L2 也拿不到合法 CHI 回包；
#   这些接线由 tb_pins.sv 逐引脚比较（源端动过才看得见）+ FM 逐点证明覆盖。
# 激励分相（ph = (cyc / 5000) % 4）：0/1/3 相 DFT 控制全 0（正常功能模式），2 相全随机压角落。
PH = '((cyc / 5000) % 4)'
NARROW = [
    (r'^io_dft_', f"({PH} == 2) ? $urandom : '0"),
    # 复位向量：非 2 相钉在 DRAM 起点 0x8000_0000（可缓存、PMA 可执行），让取指走 ICache → L2 这条主通路；
    # 全随机的 48 位地址绝大多数落在 PMA 非法区，前端只会走指令 uncache / 取指异常。
    (r'^io_reset_vector$', f"({PH} == 2) ? rnd(48) : 48'h8000_0000"),
]
# 翻转：tb 只要求 >=1 个输出翻转（冒烟）；翻转数只报告不设门限，理由见 scripts/gen_xscore_xstile.py ut_main。
args = ['--target', T, '--rst-period', '20000', '--min-toggled', f'{T}:1']
for pat, rhs in NARROW:
    args += ['--narrow', f'{T}:{pat}={rhs}']
for k, v in COVERS.items():
    args += ['--cover', f'{T}:{k}={v}']
sys.path.insert(0, os.path.join(HERE, '../../../scripts'))
import gen_xscore_xstile as GX   # noqa: E402
sys.exit(GX.ut_main(T, HERE, args, sys.argv[1:]))
