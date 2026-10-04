#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。

golden Frontend 与派生 Frontend_xs（子树全部用重写件）双例化，同激励逐拍 4 态比全部 195 个输出。
覆盖闸挑的是"前端真的转起来了"的几件事（golden 内部线）：
  取指请求发出（FTQ→IFU&ICache 三方握手）、IBuffer 向后端交出指令、后端重定向冲刷、
  MMIO 取指请求、ITLB 未命中发 PTW、FTQ 重定向 BPU、ICache ECC 错误、自检三种跨拍记录。
"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'Frontend'
G = 'u_g_Frontend.'
COVERS = {
    'fetch_req_fire': f'{G}_inner_ftq_io_toIfu_req_valid && {G}_inner_ifu_io_ftqInter_fromFtq_req_ready'
                      f' && {G}_inner_icache_io_fetch_req_ready',
    'ibuf_out_fire': f'{G}io_backend_cfVec_0_ready && {G}_inner_ibuffer_io_out_0_valid',
    'redirect_flush': f'{G}inner_needFlush',
    'mmio_fetch_req': f'{G}_inner_ifu_io_uncacheInter_toUncache_valid && {G}_inner_instrUncache_io_req_ready',
    'itlb_ptw_req': f'{G}_inner_itlb_io_ptw_req_0_valid',
    'ftq_redirect_bpu': f'{G}_inner_ftq_io_toBpu_redirect_valid',
    'icache_error': f'{G}_inner_icache_io_error_valid',
    # 自检 (a) 的跨拍记录 inner_prevTakenValid 不设闸：它要 BPU 预测出 taken 的**条件分支**，而随机激励下
    # FTB 从未被训练出这样的项（9 档实测 0 次）；这组寄存器只喂断言、无观察者，由 FM（vmucp 真比）覆盖。
    'chk_taken_tgt_rec': f'{G}inner_prevTakenValid_1',
    'chk_not_taken_rec': f'{G}inner_prevNotTakenValid',
}
# 激励分相：每 5000 拍换一相，四相轮转（ph = (cyc / 5000) % 4）：
#   0 "M 态顺序取指"：不翻译（imode=M、satp/vsatp/hgatp=Bare），重定向稀疏，TL 回包高频 —— 让取指流真转起来；
#   1 "S 态 Sv39"：开地址翻译，PTW 回包是随机内容 —— 走 ITLB 未命中 / PTWFilter / Repeater 路径；
#   2 "全随机"：所有输入均匀随机（含 CSR 写、触发器、sfence、wfi）—— 压角落；
#   3 "频繁重定向 + MMIO 取指"：复位向量在不可缓存区，后端重定向 / 提交更密 —— 压 MMIO 取指、FTQ 恢复与 IBuffer 冲刷。
PH = '((cyc / 5000) % 4)'
R2 = '($urandom % 2)'
def by_phase(p0, p1=None, p2=R2, p3=None):
    p1 = p0 if p1 is None else p1
    p3 = p0 if p3 is None else p3
    return f'({PH} == 2) ? {p2} : ({PH} == 1) ? {p1} : ({PH} == 3) ? {p3} : {p0}'
NARROW = [
    # 复位向量：相 0/1/2 在 DDR 可缓存可执行区；相 3 放在 [0x1000_0000, 0x2000_0000) —— PMA 默认的
    # "可执行、不可缓存" 区，复位后取指走 MMIO（InstrUncache）路径。
    (r'^io_reset_vector$', f"({PH} == 3) ? 48'h10000000 : 48'h80000000"),
    (r'^io_hartId$', "6'h0"),
    (r'^io_backend_toFtq_redirect_valid$', by_phase('(($urandom % 400) == 0)', p3='(($urandom % 40) == 0)')),
    (r'^io_backend_toFtq_rob_commits_\d+_valid$', by_phase('(($urandom % 8) == 0)', p3='(($urandom % 3) == 0)')),
    (r'^io_backend_cfVec_\d+_ready$', by_phase('(($urandom % 8) != 0)')),
    (r'^io_backend_canAccept$', by_phase("1'b1")),
    (r'^io_backend_wfi_wfiReq$', by_phase('(($urandom % 5000) == 0)')),
    (r'^io_tlbCsr_priv_imode$', by_phase("2'h3", p1="2'h1", p2='$urandom')),
    (r'^io_tlbCsr_satp_mode$', by_phase("4'h0", p1="4'h8", p2='$urandom')),
    (r'^io_tlbCsr_(vsatp|hgatp)_mode$', by_phase("4'h0", p2='$urandom')),
    (r'^io_tlbCsr_priv_virt$', by_phase("1'b0")),
    (r'^io_tlbCsr_\w+_changed$', by_phase('(($urandom % 1000) == 0)')),
    (r'^io_csrCtrl_distribute_csr_w_valid$', by_phase("1'b0")),
    (r'^io_csrCtrl_bp_ctrl_\w+_enable$', by_phase("1'b1")),
    (r'^io_csrCtrl_pf_ctrl_l1I_pf_enable$', by_phase("1'b1")),
    (r'^io_csrCtrl_(frontend|mem)_trigger_(tUpdate_valid|tEnableVec_\d+)$', by_phase("1'b0")),
    (r'^io_sfence_valid$', by_phase('(($urandom % 2000) == 0)')),
    (r'^io_fencei$', by_phase('(($urandom % 3000) == 0)')),
    (r'^io_softPrefetch_\d+_valid$', by_phase('(($urandom % 50) == 0)')),
    (r'^io_dft_\w+$', by_phase("1'b0")),
    (r'^auto_inner_icache_client_out_a_ready$', by_phase("1'b1")),
    (r'^auto_inner_icache_client_out_d_bits_opcode$', by_phase("4'h1", p2='$urandom')),   # AccessAckData
    (r'^auto_inner_icache_client_out_d_bits_corrupt$', by_phase('(($urandom % 100) == 0)')),
    (r'^auto_inner_instrUncache_client_out_a_ready$', by_phase("1'b1")),
    (r'^auto_inner_instrUncache_client_out_d_bits_corrupt$', by_phase('(($urandom % 100) == 0)')),
    (r'^auto_inner_icache_ctrlUnitOpt_in_a_valid$', by_phase('(($urandom % 200) == 0)')),
    (r'^auto_inner_icache_ctrlUnitOpt_in_d_ready$', by_phase("1'b1")),
    (r'^io_ptw_req_0_ready$', by_phase("1'b1")),
    (r'^io_ptw_resp_valid$', by_phase('(($urandom % 4) == 0)')),
]
# 翻转闸 152/195（9 档实测：seed 1/7 为 152，seed 42 为 153）。从未翻转的 43 个输出（各档同一集合）：
#   cfVec_*_bits_debug_seqNum_{seqNum,uopIdx}（12）  golden IBuffer 里这些寄存器只被赋 0（IBuffer.sv:9978/21219），恒 0
#   以下 31 个在本激励下没翻转，原因**未逐一追查**（不是"不可达"的结论）：
#   cfVec_*_bits_pd_{isCall,isRet}（12）、cfVec_*_bits_crossPageIPFFix（6）、
#   cfVec_1..5_bits_{backendException,satpFlushFirstFetchFault}（10）、
#   instrUncache a.user_memPageType_NC / memBackType_MM（2）、io_error_ecc_error_valid（1）。
#   它们的等价性由 FM 逐位证明；UT 仍逐拍 4 态比对这些输出，只是不计入翻转闸。
MIN_TOGGLED = 152
args = ['--target', T, '--min-toggled', f'{T}:{MIN_TOGGLED}']
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
