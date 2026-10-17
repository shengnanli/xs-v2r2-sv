#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。

golden XSCore 与派生 XSCore_xs 双例化（两侧 frontend / backend / memBlock 是同一份 golden 定义），
同激励逐拍 4 态比全部输出。XSCore 本层是纯连线（0 寄存器），比的是 3 个子模块之间 2634 根线与
顶层 374 个端口的接法。覆盖闸挑的是"跨子模块的几条主通路真的有流量"（golden 内部线，>0 拍）。
"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'XSCore'
G = 'u_g_XSCore.'
# 覆盖闸：每条都是一根跨子模块的 golden 线（本层接线的一端），见 rtl/xstile/XSCore.sv 的分组
COVERS = {
    'icache_req':     f'{G}_frontend_auto_inner_icache_client_out_a_valid',     # frontend → memBlock（取指 TileLink A）
    'icache_resp':    f'{G}_memBlock_auto_inner_frontendBridge_icache_in_d_valid',  # memBlock → frontend（取指回包）
    'itlb_ptw_req':   f'{G}_frontend_io_ptw_req_0_valid',                       # frontend → memBlock（ITLB 缺失）
    'itlb_ptw_resp':  f'{G}_memBlock_io_fetch_to_mem_itlb_resp_valid',          # memBlock → frontend（PTW 回应）
    'cfvec':          f'{G}_frontend_io_backend_cfVec_0_valid',                 # frontend → backend（指令包）
    'redirect':       f'{G}_backend_io_frontend_toFtq_redirect_valid',          # backend → frontend（重定向）
    'lsq_enq':        f'{G}_backend_io_mem_lsqEnqIO_req_0_valid',               # backend → memBlock（LSQ 入队）
    'issue_lda':      f'{G}_backend_io_mem_issueLda_0_valid',                   # backend → memBlock（load 发射）
    'wb_lda':         f'{G}_memBlock_io_mem_to_ooo_writebackLda_0_valid',       # memBlock → backend（load 写回）
    'wakeup':         f'{G}_memBlock_io_mem_to_ooo_wakeup_0_valid',             # memBlock → backend（唤醒）
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
