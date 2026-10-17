#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）与 tb_pins.sv（子模块输入引脚逐拍比对）。
--check：生成到临时文件再与库里逐字比较，不写；--covcheck sim_<S>.log：判覆盖（见 scripts/gen_xscore_xstile.py ut_main）。

golden XSCore 与派生 XSCore_xs 双例化（两侧 frontend / backend / memBlock 是同一份 golden 定义），
同激励逐拍 4 态比全部输出。XSCore 本层是纯连线（0 寄存器），比的是 3 个子模块之间 2634 根线与
顶层 374 个端口的接法。覆盖闸挑的是"跨子模块的几条主通路真的有流量"（golden 内部线，>0 拍）。
"""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'XSCore'
G = 'u_g_XSCore.'
# 覆盖闸：每条都是一根跨子模块的 golden 线（本层接线的一端），见 rtl/xstile/XSCore.sv 的分组
COVERS = {
    'icache_req':     f'{G}_frontend_auto_inner_icache_client_out_a_valid',     # frontend → memBlock（取指 TileLink A）
    'icache_resp':    f'{G}_memBlock_auto_inner_frontendBridge_icache_in_d_valid',  # memBlock → frontend（取指回包）
    'cfvec':          f'{G}_frontend_io_backend_cfVec_0_valid',                 # frontend → backend（指令包）
    'redirect':       f'{G}_backend_io_frontend_toFtq_redirect_valid',          # backend → frontend（重定向）
    'lsq_enq':        f'{G}_backend_io_mem_lsqEnqIO_req_0_valid',               # backend → memBlock（LSQ 入队）
}
# 不设闸（20k 拍探针实测 0，原因见 docs/lanes/xscore-xstile-asm.md §UT）：ITLB→PTW（M 态不翻译）、load 发射 / 写回 / 唤醒
#   （随机 TileLink 回包下前端取到的是随机指令流；LSQ 入队有 247 次但没有一条 load 走到发射——★为什么没查明★，
#   未做观测，不在这里猜；记入 lane 文档的待办）。
#   这些接线由 tb_pins.sv 的逐引脚比较 + FM 逐点证明覆盖；引脚未翻转的逐条列在 PIN_NOT_TOGGLED_OK。
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
