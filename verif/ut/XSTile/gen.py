#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。

golden XSTile 与派生 XSTile_xs 双例化（两侧 core / l2top / 4 个 IntBuffer 是同一份 golden 定义），
同激励逐拍 4 态比全部输出。XSTile 本层是纯连线（0 寄存器），比的是 6 个子模块之间 408 根线与
顶层 150 个端口的接法。覆盖闸挑的是"跨子模块的几条主通路真的有流量"（golden 内部线，>0 拍）。
"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'XSTile'
G = 'u_g_XSTile.'
# 覆盖闸：每条都是一根跨子模块的 golden 线（本层接线的一端），见 rtl/xstile/XSTile.sv 的分组
COVERS = {
    'dcache_a':     f'{G}_core_auto_memBlock_inner_dcache_client_out_a_valid',          # core → l2top（L1D TileLink A）
    'icache_a':     f'{G}_core_auto_memBlock_inner_frontendBridge_icache_out_a_valid',  # core → l2top（ICache 桥 A）
    'ptw_a':        f'{G}_core_auto_memBlock_inner_ptw_to_l2_buffer_out_a_valid',       # core → l2top（PTW A）
    'ptw_d':        f'{G}_l2top_auto_inner_ptw_to_l2_buffer_in_d_valid',                # l2top → core（PTW 回包）
    'l1d_d':        f'{G}_l2top_auto_inner_logger_in_0_d_valid',                        # l2top → core（TileLink D）
    'chi_txreq':    f'{G}io_chi_tx_req_flitv',                                          # l2top → 顶层（CHI 请求）
    'int_clint':    f'{G}_intBuffer_auto_out_0',                                        # intBuffer → core
    'int_plic':     f'{G}_intBuffer_1_auto_out_0_0',                                    # intBuffer_1 → core
    'int_debug':    f'{G}_intBuffer_2_auto_out_0',                                      # intBuffer_2 → core
    'int_nmi':      f'{G}_intBuffer_3_auto_out_0',                                      # intBuffer_3 → core
}
# 激励分相（ph = (cyc / 5000) % 4）：0/1/3 相 DFT 控制全 0（正常功能模式），2 相全随机压角落。
PH = '((cyc / 5000) % 4)'
NARROW = [
    (r'^io_dft_', f"({PH} == 2) ? $urandom : '0"),
]
MIN_TOGGLED = 0   # 见 Makefile 头：翻转闸的门限按列名豁免定，不按"实测能过多少"定
args = ['--target', T, '--rst-period', '20000']
for pat, rhs in NARROW:
    args += ['--narrow', f'{T}:{pat}={rhs}']
for k, v in COVERS.items():
    args += ['--cover', f'{T}:{k}={v}']
GEN = os.path.join(HERE, '../../../scripts/gen_l2slice_ut.py')
TB = os.path.join(HERE, 'tb.sv')
if '--check' in sys.argv[1:]:
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, 'tb.sv')
        rc = subprocess.call([sys.executable, GEN, '--out', out] + args, stdout=subprocess.DEVNULL)
        ok = rc == 0 and os.path.exists(TB) and filecmp.cmp(out, TB, shallow=False)
    print(('OK: ' if ok else 'DRIFT: ') + TB)
    sys.exit(0 if ok else 1)
sys.exit(subprocess.call([sys.executable, GEN, '--out', TB] + args))
