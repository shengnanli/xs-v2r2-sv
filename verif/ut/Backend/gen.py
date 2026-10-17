#!/usr/bin/env python3
"""重新生成本目录 tb.sv（scripts/gen_l2slice_ut.py 的确切命令行在这里）。
--check：生成到临时文件再与库里 tb.sv 逐字比较，不写。

golden Backend（golden 子树）与派生 Backend_xs（31 种直接子模块都用各自签核 UT 的重写件）双例化，
同激励逐拍 4 态比全部输出。覆盖闸挑的是"本层 glue 真的被走到"的几件事（golden 内部线）：
  执行块冲刷、int 发射流水 src fire 与冲刷、load 流水 out fire、ROB 头访存发射、写回忙表清除、int / mem 唤醒总线有效、
  MSI RegEnable 更新。
"""
import filecmp, os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
T = 'Backend'
G = 'u_g_Backend.'
COVERS = {
    'exu_flush': f'{G}_inner_ctrlBlock_io_toExuBlock_flush_valid',
    'int0_src_fire': f'{G}_inner_bypassNetwork2intExuBlock_io_in_ready && {G}_inner_bypassNetwork_io_toExus_int_0_0_valid',
    'int0_isflush': f'{G}inner_bypassNetwork2intExuBlock.io_isFlush',
    'mem2_out_fire': f'{G}io_mem_issueLda_0_ready && {G}_inner_bypassNetwork2toMemExus_2_io_out_valid',
    'rob_head_ls_issue': f'{G}inner_ctrlBlock.io_robio_robHeadLsIssue',
    'wb_int0': f'{G}_inner_wbDataPath_io_toIntPreg_0_wen && {G}_inner_wbDataPath_io_toIntPreg_0_intWen',
    'int_wakeup0': f'{G}_inner_intScheduler_io_toSchedulers_wakeupVec_0_valid',
    'mem_wakeup0': f'{G}_inner_memScheduler_io_toSchedulers_wakeupVec_0_valid',
    'msi_update': f'{G}io_fromTop_msiInfo_valid',
}
# 不设闸（UT 走不到，由 FM 逐点证明）：Vldu 口的发射 / 卡住 / 超时 / 更老 uop（inner__0 / inner__issueTimeout_T_2 /
#   inner_issueTimeout / inner__1）与 vsetvl vtype 暂存更新 —— 本 tb 不送向量指令（理由见 INSTR 注释）。
# 激励按 5000 拍分相（ph = (cyc / 5000) % 4）：
#   0/1/3 "顺序执行"：前端送合法的整数 / 访存指令（见 INSTR），不带异常 / 触发器 / 预测跳转；
#           访存侧写回、反馈、违例、取消、MMIO、异常等全部稀疏 —— 让 ROB 真的提交、调度器真的发射；
#   2     "全随机"：所有输入均匀随机（含异常、违例、load 取消、反馈），压角落。
#   全程：核号 0；DFT 控制钉 0；外部中断 / L2 刷新完成 / MSI 稀疏；MemBlock 发射口 ready 偏高。
PH = '((cyc / 5000) % 4)'
def by_phase(calm, wild=None):
    wild = '$urandom' if wild is None else wild
    return f'({PH} == 2) ? {wild} : {calm}'
#   指令混合：lw / sw / R 型（funct7=0）/ OP-IMM。不送向量指令：本 tb 没有 MemBlock 模型，向量 load 发不出去、
#   vsetvl 在 ROB 头等 vl 写回会把 ROB 卡死（实测 robDeqPtr 停在一条 vsetvli 上，提交 0 次）；向量 / Vldu 相关胶合
#   （Vldu 超时 / 更老 uop / issueResp、vsetvl vtype 暂存）由 FM 逐点证明，UT 不设闸。
INSTR = ("(($urandom % 4) == 0) ? (($urandom & 32'hFFFF8F80) | 32'h00002003)"
         " : (($urandom % 3) == 0) ? (($urandom & 32'hFFFF8F80) | 32'h00002023)"
         " : (($urandom % 2) == 0) ? (($urandom & 32'h01FFFF80) | 32'h00000033)"
         " : (($urandom & 32'hFFFF8F80) | 32'h00000013)")
# 每相开头 200 拍"开机程序"：只用 0 号口顺序送 addi x1,x0,0x600 / csrrs mstatus,x1 / lui x2,6 / csrrs mstatus,x2，
#   把 mstatus.VS / FS 置成 Dirty（复位后为 Off，向量 / 浮点指令全判非法）。随机复位之后要等下一相开头才重新打开。
BOOT = '((cyc % 5000) < 200)'
BOOT_INSTR = ("((cyc % 4) == 0) ? 32'h60000093 : ((cyc % 4) == 1) ? 32'h3000A073"
              " : ((cyc % 4) == 2) ? 32'h00006137 : 32'h30012073")
RARE = lambda n: f'(($urandom % {n}) == 0)'
NARROW = [
    (r'^io_fromTop_hartId$', "6'h0"),
    (r'^io_dft_\w+$', "1'b0"),
    (r'^io_fromTop_externalInterrupt_\w+$', by_phase("1'b0", RARE(200))),
    (r'^io_fromTop_l2FlushDone$', RARE(200)),
    (r'^io_fromTop_msiInfo_valid$', RARE(50)),
    (r'^io_mem_issue\w+_ready$', '(($urandom % 8) != 0)'),
    (r'^io_frontend_cfVec_0_bits_instr$', f'{BOOT} ? ({BOOT_INSTR}) : ' + by_phase(INSTR)),
    (r'^io_frontend_cfVec_[1-5]_bits_instr$', by_phase(INSTR)),
    (r'^io_frontend_cfVec_0_valid$', f"{BOOT} ? 1'b1 : ($urandom % 2)"),
    (r'^io_frontend_cfVec_[1-5]_valid$', f"{BOOT} ? 1'b0 : ($urandom % 2)"),
    (r'^io_frontend_cfVec_\d+_bits_(exceptionVec_\d+|backendException|crossPageIPFFix|satpFlushFirstFetchFault'
     r'|pd_isRVC|pd_isCall|pd_isRet|pred_taken)$', by_phase("1'b0")),
    # trigger = TriggerAction：0 是 BreakpointExp（断点异常），15 才是"无动作"
    (r'^io_frontend_cfVec_\d+_bits_trigger$', by_phase("4'hF")),
    (r'^io_mem_(writeback\w+|wakeup)_\d+_bits_(uop_)?trigger$', by_phase("4'hF")),
    # PC 与 FTQ 写进 PC 存储的起始地址放在低 2 GB（裸模式下高位非零 = 取指地址越界，ROB 头直接报异常冲刷，后端转不起来）
    (r'^io_frontend_(cfVec_\d+_bits_pc|fromFtq_pc_mem_wdata_startAddr|fromFtq_newest_entry_target)$',
     by_phase("($urandom & 32'h7FFFFFFE)")),
    (r'^io_frontend_cfVec_\d+_bits_pd_brType$', by_phase("2'h0")),
    (r'^io_mem_memoryViolation_valid$', by_phase(RARE(3000))),
    (r'^io_mem_ldCancel_\d+_ld2Cancel$', by_phase(RARE(50))),
    (r'^io_mem_\w+IqFeedback_\d+_feedbackSlow_valid$', by_phase(RARE(20))),
    (r'^io_mem_(writeback\w+|wakeup)_\d+_bits_(uop_)?(exceptionVec_\d+|flushPipe|replayInst)$', by_phase('1\'b0')),
    (r'^io_mem_(writeback\w+|wakeup)_\d+_valid$', by_phase(RARE(4))),
    (r'^io_mem_robLsqIO_\w+Mmio\w*$', by_phase("1'b0")),
    (r'^io_mem_(lsqEnqIO_canAccept|lqCanAccept|sqCanAccept)$', by_phase("1'b1")),
    (r'^io_mem_stIn_\d+_valid$', by_phase(RARE(4))),
]
# "MemBlock 回声"（只在顺序相）：访存写回口直接回放同一拍送出去的访存 uop（valid = 该发射口 valid，robIdx / pdest /
#   各写使能 / fuType 等同名同宽字段照抄，load 标 isFromLoadUnit），让 ROB 里的访存指令能完成、ROB 能提交。
#   写回数据仍随机；全随机相照旧。条目放在 NARROW 最前（gen_l2slice_ut 按第一条命中）。
import re as _re
def _golden_ports():
    t = open('/home/eda/xs-env/G1-canonical/golden-rtl/Backend.sv').read()
    i = t.index('module Backend('); j = t.index('\n);', i)
    out = {}
    for ln in t[i:j].splitlines()[1:]:
        m = _re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', ln)
        if m:
            out[m.group(3)] = (m.group(1), int(m.group(2) or 0) + 1)
    return out
_GP = _golden_ports()
ECHO = []
for _n, (_d, _w) in _GP.items():
    _m = _re.fullmatch(r'io_mem_writeback(\w+?)_(\d+)_(valid|bits_uop_\w+|bits_isFromLoadUnit)', _n)
    if _d != 'input' or not _m:
        continue
    _src = 'io_mem_issue%s_%s_%s' % _m.groups()
    if _m.group(3) == 'bits_isFromLoadUnit':
        ECHO.append(('^%s$' % _n, by_phase("1'b1")))
    elif _src in _GP and _GP[_src] == ('output', _w):
        ECHO.append(('^%s$' % _n, by_phase('g_Backend__' + _src)))
NARROW = ECHO + NARROW
MIN_TOGGLED = 400
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
