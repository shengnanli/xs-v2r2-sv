#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。

golden MemBlock 与派生 MemBlock_xs 双例化（两侧 72 个子模块是同一份 golden 定义），同激励逐拍 4 态比全部输出。
覆盖闸挑的是"本层胶合逻辑真的动起来了"的几件事（golden 内部线），见 COVERS。
"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'MemBlock'
G = 'u_g_MemBlock.'
# 覆盖闸：本层胶合逻辑的几条主路径确实走到过（golden 内部线，>0 拍）
COVERS = {
    'amo_active': f'({G}inner_state != 2\'h0)',                                   # 原子指令借 DTLB 口 0 / 写回口 0
    'amo_writeback': f'{G}_inner_atomicsUnit_io_out_valid',
    'segment_active': f'{G}inner_vSegmentFlag',                                    # segment 独占 DCache 口 0
    'ptw_resp_v': f'{G}inner_ptw_resp_v',                                          # PTW 回应打拍广播给 DTLB
    'mem_violation': f'{G}io_mem_to_ooo_memoryViolation_valid',                    # 最老回滚选择
    'uncache_busy': f'({G}inner_uncacheState != 2\'h0)',                          # Uncache 状态机离开空闲
    'lda1_from_misalign': f'{G}_inner_loadMisalignBuffer_io_writeBack_valid',
    'vldu_writeback': f'({G}io_mem_to_ooo_writebackVldu_0_valid | {G}io_mem_to_ooo_writebackVldu_1_valid)',
    'exc_pending': f'({G}inner_atomicsException | {G}inner_vSegmentException)',
}
# 激励分相：每 5000 拍换一相（ph = (cyc / 5000) % 4）：
#   0 "M 态、不翻译"：satp/vsatp/hgatp = Bare，重定向稀疏 —— 让访存流水按地址直接跑；
#   1 "S 态 Sv39"：开地址翻译，DTLB 缺失走 PTWNewFilter / L2TLB，PTW 回应会打拍广播回 DTLB；
#   2 "全随机"：所有输入均匀随机（含 CSR 写、触发器、sfence、wfi）—— 压角落；
#   3 "原子 / segment / 违例密集"：AMO 与 segment 指令更频繁、重定向更密。
PH = '((cyc / 5000) % 4)'
R2 = '($urandom % 2)'
def by_phase(p0, p1=None, p2=R2, p3=None):
    p1 = p0 if p1 is None else p1
    p3 = p0 if p3 is None else p3
    return f'({PH} == 2) ? {p2} : ({PH} == 1) ? {p1} : ({PH} == 3) ? {p3} : {p0}'
# fuType：store 地址口上第 17 位 = AMO（mou）；向量口第 33/34 位 = segment load/store
AMO_FUTYPE = "({$urandom, $urandom} & ~35'h2_0000) | ((($urandom % NNN) == 0) ? 35'h2_0000 : 35'h0)"
SEG_FUTYPE = "({$urandom, $urandom} & ~35'h6_0000_0000) | ((($urandom % NNN) == 0) ? 35'h2_0000_0000 : 35'h0)"
NARROW = [
    (r'^io_redirect_valid$', by_phase('(($urandom % 200) == 0)', p3='(($urandom % 20) == 0)')),
    (r'^io_ooo_to_mem_issueSta_\d+_bits_uop_fuType$', by_phase(AMO_FUTYPE.replace("NNN", "3000"), p2='{$urandom, $urandom}', p3=AMO_FUTYPE.replace("NNN", "300"))),
    (r'^io_ooo_to_mem_issueVldu_0_bits_uop_fuType$', by_phase(SEG_FUTYPE.replace("NNN", "3000"), p2='{$urandom, $urandom}', p3=SEG_FUTYPE.replace("NNN", "300"))),
    (r'^io_ooo_to_mem_tlbCsr_(satp|vsatp|hgatp)_mode$', by_phase("4'h0", p1="4'h8", p2='$urandom')),
    (r'^io_ooo_to_mem_tlbCsr_priv_virt$', by_phase("1'b0")),
    (r'^io_ooo_to_mem_tlbCsr_priv_dmode$', by_phase("2'h3", p1="2'h1", p2='$urandom')),
    (r'^io_ooo_to_mem_tlbCsr_\w+_changed$', by_phase('(($urandom % 1000) == 0)')),
    (r'^io_ooo_to_mem_sfence_valid$', by_phase('(($urandom % 2000) == 0)')),
    (r'^io_ooo_to_mem_csrCtrl_distribute_csr_w_valid$', by_phase("1'b0")),
    (r'^io_ooo_to_mem_csrCtrl_mem_trigger_tUpdate_valid$', by_phase('(($urandom % 100) == 0)')),
    (r'^io_ooo_to_mem_csrCtrl_pf_ctrl_\w*enable\w*$', by_phase("1'b1")),
    (r'^io_ooo_to_mem_flushSb$', by_phase('(($urandom % 100) == 0)')),
    (r'^io_dft_\w+$', by_phase("1'b0")),
    (r'^io_wfi_wfiReq$', by_phase('(($urandom % 5000) == 0)')),
]
# 翻转闸 950/1431（seed 7、initreg 0、2 万拍实测 953）。没翻转的输出多是：
#   * io_mem_to_ooo_wakeup_* 的 uop 字段（推测唤醒要 load 真正命中，随机 TileLink 回包下极少）；
#   * 写回包里只在特定路径出现的字段（MMIO / cbo.zero 写回、segment 写 Sbuffer、PTW 回应命中重放）——
#     这几条本层胶合路径在随机激励下几乎走不到（StoreQueue 要真有 MMIO store 出队、segment 要真完成一次 store、
#     L2TLB 要拿到合法的 L2 回包），不设闸；它们由 FM 逐点证明（本层全部组合逻辑与寄存器白盒受验）。
MIN_TOGGLED = 950
args = ['--target', T, '--min-toggled', f'{T}:{MIN_TOGGLED}', '--rst-period', '1000']
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
