#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_memblock.py —— MemBlock（访存子系统顶层装配）的 golden 同名 wrapper、布局包与 FM 钉点生成器。

手写区（文件头 + xs_MemBlock_core）脚本不碰；本脚本只产出机械派生的三处：
  1. rtl/memblock/MemBlock.sv 里 `// BEGIN GENERATED(mb_layout)` … `// END GENERATED`：
     package memblock_top_pkg —— 各"字段束"（BUNDLES，见下）的总位宽常量，核用它声明束端口；
  2. 同文件 `// BEGIN GENERATED(mb_wrapper)` … `// END GENERATED`：module MemBlock ——
     端口表（与 golden 逐位同名同序）、72 个子模块例化（模块名与实例名照搬 golden）、
     子模块之间的连线、字段束的拼装 / 拆分、可读核 u_core 的例化；
  3. verif/ut/MemBlock/fm_pins_pre.tcl —— golden MemBlock 本层全部寄存器逐位 set_user_match 到 u_core。

★fail-closed（对照 golden 现读，任何一条不满足就非零退出、不写文件）★
  1. 端口：golden MemBlock 的 2450 个端口按原序原宽原方向出现；
  2. 例化：72 个实例逐个照搬模块名与实例名；每个子模块**输入**的 golden 连接表达式（先沿 golden 的
     别名线 `wire x = y;` 解开）必须落进下面已知形状之一：
       a. 顶层输入端口                    → 原样
       b. 某个子模块的输出（golden 的 `_inner_<实例>_<端口>` 线或具名线）→ 改名 `<驱动别名>_<端口去 io_>`
       c. 常量                            → 原样
       d. golden 本层寄存器               → u_core 的同名输出口（CORE_REGS 给出对应的核寄存器）
       e. 其它（本层组合胶合逻辑）         → u_core 的一个输出口；**golden 表达式相同的输入共用同一个口**，
                                            口名默认 `<实例别名>_<端口去 io_>`，NAMES 表可改成语义名；
       f. 属于某个字段束（BUNDLES）的目的端口 → 束输出的对应位段；
     子模块**输出**一律接到 `<别名>_<端口去 io_>` 线（无读者的照 golden 悬空，直接驱动顶层输出的直连）。
  3. 顶层输出：golden 的驱动（同样先解别名）必须是：子模块输出（直连）、顶层输入（assign 直通）、
     golden 本层寄存器（u_core 同名口）、或胶合逻辑（u_core 里与顶层输出**同名**的口），或字段束；
  4. u_core 的端口：手写核的端口表逐个核对 —— 输入必须是顶层输入 / 子模块输出线 / 束输入，输出必须是
     上面要求的某个口，位宽逐个比对；核多一个口、少一个口都报错；
  5. 字段束：目的端口按前缀成组，每个源按同一字段名取（顶层输入或子模块输出）；源缺这个字段时用
     FILL 表的常量（默认 0）——那是子模块在本配置下被 firtool 钉死、从端口上删掉的输出。每个目的端口的
     golden 表达式里出现的信号，只许是各源的**同名字段**或该束声明的选择信号（换名 / 串位即报错）；
  6. 分组注释：实例之间每一对"谁连谁"都必须在 PAIR_DESC 里有一句说明（新连接对 = 报错）；
     顶层端口按 TOP_GROUPS 前缀归组，未归组 = 报错；
  7. 钉点：CORE_REGS 必须恰好覆盖 golden 本层的 385 个寄存器，对端核寄存器同宽；钉点数写成字面常数。

用法：python3 scripts/gen_memblock.py [--check] [--print-core-ports]
"""
import argparse
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
OUT = REPO / 'rtl' / 'memblock' / 'MemBlock.sv'
PINS = REPO / 'verif' / 'ut' / 'MemBlock' / 'fm_pins_pre.tcl'
TOP = 'MemBlock'
CORE = 'xs_MemBlock_core'
PORT_RE = re.compile(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$')
CONST_RE = re.compile(r"\d+'h[0-9A-Fa-f]+")


def fail(msg):
    sys.stderr.write('gen_memblock: FAIL: %s\n' % msg)
    sys.exit(1)


def norm(s):
    return ' '.join(s.split())


# =============================================================================
# 实例别名与 wrapper 里的分节（顺序即 wrapper 里出现的顺序）
# =============================================================================
SECTIONS = [
    ('§A 访存流水：3 条 load 流水、2 条 store 地址流水、2 条 store 数据流水、原子指令单元、非对齐缓冲', [
        ('inner_LoadUnit_0', 'ldu0'), ('inner_LoadUnit_1', 'ldu1'), ('inner_LoadUnit_2', 'ldu2'),
        ('inner_StoreUnit_0', 'stu0'), ('inner_StoreUnit_1', 'stu1'),
        ('inner_stdExeUnits_0', 'std0'), ('inner_stdExeUnits_1', 'std1'),
        ('inner_atomicsUnit', 'amo'),
        ('inner_loadMisalignBuffer', 'lmb'), ('inner_storeMisalignBuffer', 'smb')]),
    ('§B 向量访存：拆分（split）→ 标量流水 → 合并（merge），外加 segment 单元与 fault-only-first 缓冲', [
        ('inner_vlSplit_0', 'vlSplit0'), ('inner_vlSplit_1', 'vlSplit1'),
        ('inner_vsSplit_0', 'vsSplit0'), ('inner_vsSplit_1', 'vsSplit1'),
        ('inner_VlSplitConnectLdu', 'vlToLdu0'), ('inner_VlSplitConnectLdu_1', 'vlToLdu1'),
        ('inner_VsSplitConnectStu', 'vsToStu0'), ('inner_VsSplitConnectStu_1', 'vsToStu1'),
        ('inner_vlMergeBuffer', 'vlMerge'),
        ('inner_vsMergeBuffer_0', 'vsMerge0'), ('inner_vsMergeBuffer_1', 'vsMerge1'),
        ('inner_vSegmentUnit', 'vSeg'), ('inner_vfofBuffer', 'vfof')]),
    ('§C 访存队列与写缓冲：LSQ（load/store 队列）、Sbuffer、MMIO / cbo.zero 写回打拍、Uncache 请求 / 回应打拍', [
        ('inner_lsq', 'lsq'), ('inner_sbuffer', 'sbuffer'), ('inner_otherStoutConnect', 'otherStout'),
        ('inner_pipelineReg', 'uncacheReqReg'), ('inner_pipelineReg_1', 'uncacheRespReg')]),
    ('§D L1 数据缓存与 Uncache，及它们去 L2 / 外设的 TileLink 通路', [
        ('inner_dcache', 'dcache'), ('inner_uncache', 'uncache'), ('inner_xbar', 'uncacheXbar'),
        ('inner_buffer', 'uncacheBuf'), ('inner_buffers_1', 'mmioBufA'), ('inner_buffers', 'mmioBufB'),
        ('inner_buffers_3', 'dcUncBufA'), ('inner_buffers_2', 'dcUncBufB'),
        ('inner_l1d_to_l2_buffer', 'l1dToL2Buf'), ('inner_frontendBridge', 'frontendBridge')]),
    ('§E 地址翻译与访问权限：3 个 DTLB → PTWNewFilter → L2TLB；ITLB 经 PTWRepeaterNB；PMP + 8 个检查口', [
        ('inner_dtlb_ld_tlb_ld', 'dtlbLd'), ('inner_dtlb_st_tlb_st', 'dtlbSt'),
        ('inner_dtlb_prefetch_tlb_prefetch', 'dtlbPf'), ('inner_dtlbRepeater', 'dtlbRepeater'),
        ('inner_itlbRepeater3', 'itlbRepeater'), ('inner_ptw', 'ptw'), ('inner_ptw_to_l2_buffer', 'ptwToL2Buf'),
        ('inner_pmp', 'pmp')] + [('inner_pmp_checkers_%d' % i, 'pmpCheck%d' % i) for i in range(8)]),
    ('§F 硬件预取：SMS（空间预取）、L1 流预取、预取请求打拍、向 L2 发预取的延迟线', [
        ('inner_prefetcherOpt', 'sms'), ('inner_l1PrefetcherOpt', 'l1Pf'),
        ('inner_l1_pf_req_pf_queue_to_ldu_reg', 'l1PfReqQueue'),
        ('inner_sms_pf_to_l2_pipMod', 'smsToL2Dly'), ('inner_l1_pf_to_l2_pipMod', 'l1PfToL2Dly')]),
    ('§G CSR / 错误 / 顶层旁路信号的延迟线', [
        ('inner_csrCtrl_delay', 'csrCtrlDly'), ('inner_dcacheError_pipMod', 'dcacheErrDly'),
        ('inner_io_uncacheError_ecc_error_pipMod', 'uncacheErrDly'),
        ('inner_delay', 'amoExcClrDly'), ('inner_delay_1', 'vsegExcClrDly'),
        ('inner_io_mem_to_ooo_topToBackendBypass_msiInfo_pipMod', 'msiInfoDly'),
        ('inner_io_mem_to_ooo_topToBackendBypass_clintTime_pipMod', 'clintTimeDly'),
        ('inner_io_outer_l2PfCtrl_delay', 'l2PfCtrlDly')]),
    ('§H 性能事件：PFEvent（CSR 选择）+ HPerfMonitor（汇成 8 路）', [
        ('inner_pfevent', 'pfevent'), ('inner_perfEvents_hpm', 'perfHpm')]),
    ('§I MBIST（存储器内建自测）分发树', [
        ('inner_mbistPl', 'mbistPl'), ('inner_mbistSmsPl', 'mbistSmsPl'), ('inner_mbistIntf', 'mbistIntf')]),
]
ALIAS = collections.OrderedDict((i, a) for _, lst in SECTIONS for i, a in lst)


# =============================================================================
# 字段束（BUNDLES）：同一组目的端口由几个"源包"按字段二选一 / 多选一。
#   dest   = ('top', 前缀) 或 (golden 实例名, 前缀)：目的端口集合 = 该处名字以前缀开头的输入（顶层则为输出）；
#   srcs   = [(标签, 'top' 或 golden 实例名, 前缀)]：源字段 = 前缀 + 目的字段名；
#   sel    = golden 表达式里允许出现的选择信号（golden 名，解别名后比对）；
#   fill   = {(源标签, 字段): 常量}：源缺这个字段时填的值（缺省 0）。
# 核里每个束有 `<束名>_<源标签>` 输入（位宽 <束名大写>_W）与 `<束名>` 输出；字段顺序 = 目的端口的 golden 顺序。
# =============================================================================
Bundle = collections.namedtuple('Bundle', 'name dest srcs sel fill exclude desc')
BUNDLES = [
    Bundle('wbLda0', ('top', 'io_mem_to_ooo_writebackLda_0_bits_'),
           [('amo', 'inner_atomicsUnit', 'io_out_bits_'), ('ldu', 'inner_LoadUnit_0', 'io_ldout_bits_')],
           [r'_inner_atomicsUnit_io_out_valid'], {}, (),
           'load 写回口 0：原子指令结果优先，否则 load 流水 0'),
    Bundle('wbLda1', ('top', 'io_mem_to_ooo_writebackLda_1_bits_'),
           [('ldu', 'inner_LoadUnit_1', 'io_ldout_bits_'), ('lmb', 'inner_loadMisalignBuffer', 'io_writeBack_bits_')],
           [r'_inner_LoadUnit_1_io_ldout_valid', r'_inner_loadMisalignBuffer_io_writeBack_valid'], {}, (),
           'load 写回口 1：load 流水 1 优先，否则非对齐 load 缓冲'),
    Bundle('wbSta0', ('top', 'io_mem_to_ooo_writebackSta_0_bits_'),
           [('smb', 'inner_storeMisalignBuffer', 'io_writeBack_bits_'),
            ('other', 'inner_otherStoutConnect', 'io_out_bits_'),
            ('stu', 'inner_StoreUnit_0', 'io_stout_bits_')],
           [r'inner__7', r'inner_'], {}, (),
           'store 写回口 0：非对齐 store 缓冲 > MMIO/cbo.zero 写回 > store 流水 0'),
    Bundle('wbVldu0', ('top', 'io_mem_to_ooo_writebackVldu_0_bits_'),
           [('seg', 'inner_vSegmentUnit', 'io_uopwriteback_bits_'),
            ('vl', 'inner_vlMergeBuffer', 'io_uopWriteback_0_bits_'),
            ('vs', 'inner_vsMergeBuffer_0', 'io_uopWriteback_0_bits_')],
           [r'_inner_vSegmentUnit_io_uopwriteback_valid', r'_inner_vlMergeBuffer_io_uopWriteback_0_valid'], {}, (),
           '向量写回口 0：segment 单元 > 向量 load 合并 > 向量 store 合并'),
    Bundle('wbVldu1', ('top', 'io_mem_to_ooo_writebackVldu_1_bits_'),
           [('vfof', 'inner_vfofBuffer', 'io_uopWriteback_bits_'),
            ('vl', 'inner_vlMergeBuffer', 'io_uopWriteback_1_bits_'),
            ('vs', 'inner_vsMergeBuffer_1', 'io_uopWriteback_0_bits_')],
           [r'_inner_vfofBuffer_io_uopWriteback_valid', r'_inner_vlMergeBuffer_io_uopWriteback_1_valid'], {}, (),
           '向量写回口 1：fault-only-first 改 vl > 向量 load 合并 > 向量 store 合并'),
    Bundle('vlMergeIn1', ('inner_vlMergeBuffer', 'io_fromPipeline_1_bits_'),
           [('ldu', 'inner_LoadUnit_1', 'io_vecldout_bits_'),
            ('lmb', 'inner_loadMisalignBuffer', 'io_vecWriteBack_bits_')],
           [r'_inner_LoadUnit_1_io_vecldout_valid'], {}, ('mBIndex',),
           '向量 load 合并缓冲的第 1 个流水口：load 流水 1 的向量结果优先，否则非对齐缓冲拆出来的向量元素'),
    Bundle('vsMergeIn0', ('inner_vsMergeBuffer_0', 'io_fromPipeline_0_'),
           [('stu', 'inner_StoreUnit_0', 'io_vecstout_'),
            ('smb', 'inner_storeMisalignBuffer', 'io_vecWriteBack_0_')],
           [r'_inner_StoreUnit_0_io_vecstout_valid'], {}, (),
           '向量 store 合并缓冲 0 的流水口：store 流水 0 的向量结果优先，否则非对齐 store 缓冲'),
    Bundle('vsMergeIn1', ('inner_vsMergeBuffer_1', 'io_fromPipeline_0_'),
           [('stu', 'inner_StoreUnit_1', 'io_vecstout_'),
            ('smb', 'inner_storeMisalignBuffer', 'io_vecWriteBack_1_')],
           [r'_inner_StoreUnit_1_io_vecstout_valid'], {}, (),
           '向量 store 合并缓冲 1 的流水口：store 流水 1 的向量结果优先，否则非对齐 store 缓冲'),
    Bundle('amoIn', ('inner_atomicsUnit', 'io_in_bits_'),
           [('sta0', 'top', 'io_ooo_to_mem_issueSta_0_bits_'), ('sta1', 'top', 'io_ooo_to_mem_issueSta_1_bits_')],
           [r'inner_st_atomics_0', r'inner_st_atomics_1'], {}, (),
           '原子指令单元的输入：两个 store 地址发射口里谁是 AMO 就选谁（独热）'),
    Bundle('otherStoutIn', ('inner_otherStoutConnect', 'io_in_bits_'),
           [('cbo', 'inner_lsq', 'io_cboZeroStout_bits_'), ('mmio', 'inner_lsq', 'io_mmioStout_bits_')],
           [r'_inner_lsq_io_cboZeroStout_valid'], {}, (),
           'StoreQueue 的"其它" store 写回：cbo.zero 优先，否则 MMIO store'),
    Bundle('staFb0', ('top', 'io_mem_to_ooo_staIqFeedback_0_feedbackSlow_'),
           [('amo', 'inner_atomicsUnit', 'io_feedbackSlow_'), ('stu', 'inner_StoreUnit_0', 'io_feedback_slow_')],
           [r'inner__19'], {}, (),
           'store 地址发射队列 0 的慢反馈：原子指令占用 store 口 0 时由原子单元回，否则 store 流水 0'),
    Bundle('staFb1', ('top', 'io_mem_to_ooo_staIqFeedback_1_feedbackSlow_'),
           [('amo', 'inner_atomicsUnit', 'io_feedbackSlow_'), ('stu', 'inner_StoreUnit_1', 'io_feedback_slow_')],
           [r'inner__20'], {}, (),
           'store 地址发射队列 1 的慢反馈：原子指令占用 store 口 1 时由原子单元回，否则 store 流水 1'),
    Bundle('vstuFb0', ('top', 'io_mem_to_ooo_vstuIqFeedback_0_feedbackSlow_'),
           [('seg', 'inner_vSegmentUnit', 'io_feedback_'), ('vs', 'inner_vsMergeBuffer_0', 'io_feedback_0_')],
           [], {}, (),
           '向量 store 发射队列 0 的慢反馈：segment 单元与向量 store 合并缓冲 0 独热合一'),
    Bundle('memVio', ('top', 'io_mem_to_ooo_memoryViolation_'),
           [('ldu0', 'inner_LoadUnit_0', 'io_rollback_'), ('ldu1', 'inner_LoadUnit_1', 'io_rollback_'),
            ('ldu2', 'inner_LoadUnit_2', 'io_rollback_'), ('nack', 'inner_lsq', 'io_nack_rollback_0_'),
            ('nuke0', 'inner_lsq', 'io_nuke_rollback_0_'), ('nuke1', 'inner_lsq', 'io_nuke_rollback_1_')],
           [r'inner__oldestOneHot_resultOnehot_T_\d+'], {}, (),
           '访存违例回滚：6 个回滚源里挑 ROB 序最老的那个（独热）'),
    Bundle('sbufIn0', ('inner_sbuffer', 'io_in_0_'),
           [('seg', 'inner_vSegmentUnit', 'io_sbuffer_'), ('lsq', 'inner_lsq', 'io_sbuffer_0_')],
           [], {}, (),
           'Sbuffer 写入口 0：segment 单元与 StoreQueue 出队口 0 独热合一'),
]
BUNDLE_BY_NAME = {b.name: b for b in BUNDLES}


# =============================================================================
# 胶合输出口的语义名：键 = 默认名 `<第一个使用者别名>_<端口去 io_>`，值 = 核里的口名。
# 只给"被几处共用"或默认名会误导的那些改名；其余沿用默认名（= 它喂给谁的哪个口）。
# =============================================================================
NAMES = {
    'ldu0_prefetch_req_valid': 'l1PfReq_valid',                 # 三条 load 流水共用：硬件预取请求（原子指令期间关掉）
    'stu0_stin_valid': 'sta0_issue_valid',                       # store 流水 0 与 vsSplit0 共用：非 AMO 的 store 地址发射
    'stu1_stin_valid': 'sta1_issue_valid',
    'vlSplit0_fromPipeline_1_valid': 'ldu1VecWb_valid',          # vlSplit0/1 与 vlMerge 共用：load 口 1 的向量写回
    'vlSplit0_fromPipeline_1_bits_mBIndex': 'ldu1VecWb_mBIndex',
    'vSeg_in_valid': 'segment_issue_valid',                      # segment 单元的发射，也拦住 vlSplit/vsSplit
    'vSeg_flush_sbuffer_empty': 'store_path_empty',              # Sbuffer 与 Uncache 都空了（原子单元也要）
}

# 字段束源缺字段时的非零填充：(束名, 源标签, 字段) → 常量。缺省 0。
#   这些是子模块在本配置下被钉死的输出（firtool 把常量传播进了父层、从子模块端口上删掉）：
FILLS = {
    ('wbLda0', 'ldu', 'isFromLoadUnit'): 1,          # LoadUnit 的写回包 isFromLoadUnit 恒 1
    ('wbVldu1', 'vfof', 'uop_vpu_vmask'): (1 << 128) - 1,   # VfofBuffer 写回的 vmask 恒全 1
    ('vlMergeIn1', 'lmb', 'trigger'): 0xF,           # 非对齐缓冲拆出来的向量元素不带触发器（TriggerAction.None = 4'hF）
    ('vsMergeIn0', 'smb', 'bits_hit'): 1,            # 非对齐 store 缓冲的向量结果 hit 恒 1
    ('vsMergeIn0', 'smb', 'bits_trigger'): 0xF,
    ('vsMergeIn1', 'smb', 'bits_hit'): 1,
    ('vsMergeIn1', 'smb', 'bits_trigger'): 0xF,
    ('staFb0', 'stu', 'bits_sourceType'): 1,         # StoreUnit 慢反馈的 sourceType 恒 1（RSFeedbackType.tlbMiss）
    ('staFb1', 'stu', 'bits_sourceType'): 1,
    ('staFb0', 'amo', 'bits_hit'): 1,                # 原子单元的慢反馈 hit 恒 1
    ('staFb1', 'amo', 'bits_hit'): 1,
    ('vstuFb0', 'seg', 'bits_hit'): 1,               # segment 单元的慢反馈 hit 恒 1
    ('memVio', 'nuke0', 'bits_level'): 1,            # st-ld 违例（nuke）回滚恒为 flush（level=1）
    ('memVio', 'nuke1', 'bits_level'): 1,
}

# =============================================================================
# 顶层端口分组（最长前缀命中）：只用于给子模块连接写注释
# =============================================================================
TOP_GROUPS = [
    ('clock', '时钟'), ('reset', '复位'),
    ('auto_inner_buffers_out', 'MMIO 主口（Uncache → xbar → 两级 TLBuffer → 外设总线）'),
    ('auto_inner_dcache_client_out', 'L1 数据缓存去 L2 的 TileLink 主口（经 l1dToL2Buf）'),
    ('auto_inner_frontendBridge', '前端（ICache / InstrUncache / ICache 控制寄存器）的 TileLink 通路桥'),
    ('auto_inner_ptw_to_l2_buffer_out', 'L2TLB 去 L2 读页表的 TileLink 主口（经 ptwToL2Buf）'),
    ('auto_inner_l1d_to_l2_buffer_out', 'L1 DCache 去 L2 的 TileLink 主口（经 l1dToL2Buf）'),
    ('gatewayIn_packed', 'MBIST 网关穿线'),
    ('io_dcacheError', 'DCache ECC 错误上报'),
    ('io_uncacheError', 'Uncache 总线错误上报'),
    ('io_debugTopDown', 'TopDown 调试：ROB 头的 vaddr 与"卡在哪"'),
    ('io_dft', 'DFT 广播（SRAM 测试控制）'),
    ('io_fetch_to_mem', '前端 ITLB 的页表遍历请求 / 回应（经 itlbRepeater 去 L2TLB）'),
    ('io_fromTopToBackend', 'SoC 送给后端的 MSI / 时钟计数（本层打一拍转发）'),
    ('io_hartId', '核号'),
    ('io_ifetchPrefetch', 'load 流水发现的软件取指预取（prefetch.i）送前端'),
    ('io_l2_pmp_resp', 'L2 预取地址翻译后的 PMP 检查结果'),
    ('io_l2_tlb_req', 'L2 预取器借用的 DTLB 请求口'),
    ('io_outer_l2PfCtrl', '送 L2 的预取控制（CSR 打两拍）'),
    ('io_topDownInfo_toBackend', 'TopDown：L1 缺失 / 队列满等状态送后端'),
    ('io_wfi', 'wfi 握手'),
    ('io_mem_to_ooo_ldCancel', 'load 推测唤醒的取消'),
    ('io_mem_to_ooo_ldaIqFeedback', 'load 发射队列的反馈'),
    ('io_mem_to_ooo_lqCancelCnt', 'LoadQueue 冲刷取消计数'),
    ('io_mem_to_ooo_lqDeq', 'LoadQueue 出队计数'),
    ('io_mem_to_ooo_lqDeqPtr', 'LoadQueue 出队指针'),
    ('io_mem_to_ooo_lsTopdownInfo', 'load 流水的 TopDown 信息'),
    ('io_mem_to_ooo_lsqio', 'LSQ 回给 ROB 的 MMIO / 例外信息'),
    ('io_mem_to_ooo_sqCancelCnt', 'StoreQueue 冲刷取消计数'),
    ('io_mem_to_ooo_sqDeq', 'StoreQueue 出队计数'),
    ('io_mem_to_ooo_sqDeqPtr', 'StoreQueue 出队指针'),
    ('io_mem_to_ooo_stIn', 'store 发射广播（给 LFST 等）'),
    ('io_mem_to_ooo_stIssuePtr', 'StoreQueue 已发射指针'),
    ('io_mem_to_ooo_storeDebugInfo', 'difftest 用的 store 调试信息'),
    ('io_mem_to_ooo_topToBackendBypass', 'SoC → 后端旁路（MSI / 时钟计数）'),
    ('io_mem_to_ooo_vlduIqFeedback', '向量 load 发射队列的反馈'),
    ('io_mem_to_ooo_vstuIqFeedback', '向量 store 发射队列的反馈'),
    ('io_mem_to_ooo_wakeup', 'load 推测唤醒'),
    ('io_mem_to_ooo_writebackLda', 'load 写回'),
    ('io_mem_to_ooo_writebackSta', 'store 地址写回'),
    ('io_mem_to_ooo_writebackStd', 'store 数据写回'),
    ('io_mem_to_ooo_writebackVldu', '向量访存写回'),
    ('io_ooo_to_mem_csrCtrl', '自定义 CSR 控制'),
    ('io_ooo_to_mem_enqLsq', '派遣进 LSQ'),
    ('io_ooo_to_mem_isStoreException', '例外是不是 store 引起的'),
    ('io_ooo_to_mem_issueLda', 'load 发射'),
    ('io_ooo_to_mem_issueSta', 'store 地址发射'),
    ('io_ooo_to_mem_issueStd', 'store 数据发射'),
    ('io_ooo_to_mem_issueVldu', '向量访存发射'),
    ('io_ooo_to_mem_lsqio', 'ROB 提交 / 待处理信息给 LSQ'),
]

# 实例之间"谁连谁"的说明（无序对，见 PAIRS 节）
PAIR_DESC = {
    ('amo', 'csrCtrlDly'): '自定义 CSR（cache 错误使能、访存触发器配置等，打两拍后）',
    ('amo', 'dcache'): '原子单元的 DCache 请求 / 回应口（lsu.atomics）',
    ('amo', 'dtlbLd'): '原子单元借用 load DTLB 口 0 的翻译结果',
    ('amo', 'pmpCheck0'): '原子单元复用 load 口 0 的 PMP 检查结果',
    ('amo', 'std0'): 'store 数据流水 0 的数据（AMO 的源操作数）',
    ('amo', 'std1'): 'store 数据流水 1 的数据（AMO 的源操作数）',
    ('csrCtrlDly', 'ldu0'): '自定义 CSR：ld-ld 违例检查 / 非对齐开关、触发器调试态（打两拍后）',
    ('csrCtrlDly', 'ldu1'): '自定义 CSR：ld-ld 违例检查 / 非对齐开关、触发器调试态（打两拍后）',
    ('csrCtrlDly', 'ldu2'): '自定义 CSR：ld-ld 违例检查 / 非对齐开关、触发器调试态（打两拍后）',
    ('csrCtrlDly', 'pfevent'): '性能事件选择 CSR 写广播（打两拍后）',
    ('csrCtrlDly', 'pmp'): 'pmpcfg / pmpaddr 等 CSR 写广播（打两拍后）',
    ('csrCtrlDly', 'ptw'): 'L2TLB 的 CSR 写广播（打两拍后）',
    ('csrCtrlDly', 'sbuffer'): 'Sbuffer 超时设置（打两拍后）',
    ('csrCtrlDly', 'stu0'): '自定义 CSR：非对齐 store 开关、触发器调试态（打两拍后）',
    ('csrCtrlDly', 'stu1'): '自定义 CSR：非对齐 store 开关、触发器调试态（打两拍后）',
    ('csrCtrlDly', 'vSeg'): '自定义 CSR：cache 错误使能、触发器调试态（打两拍后）',
    ('dcUncBufA', 'dcUncBufB'): 'Uncache 交叉开关 → DCache uncache 口的两级 TLBuffer 首尾相接',
    ('dcUncBufA', 'uncacheXbar'): 'Uncache 交叉开关的出口 1 → 去 DCache 的两级缓冲',
    ('dcache', 'dcacheErrDly'): 'DCache ECC 错误（延迟两拍后上报）',
    ('dcache', 'l1Pf'): 'DCache 给 L1 流预取的控制（使能 / 置信度）',
    ('dcache', 'l1dToL2Buf'): 'L1 DCache ↔ L2 的 TileLink A/B/C/D/E 通道（经一级缓冲）',
    ('dcache', 'ldu0'): 'load 流水 0 的 DCache 读口、MSHR / D 通道前递、bank 冲突',
    ('dcache', 'ldu1'): 'load 流水 1 的 DCache 读口、MSHR / D 通道前递、bank 冲突',
    ('dcache', 'ldu2'): 'load 流水 2 的 DCache 读口、MSHR / D 通道前递、bank 冲突',
    ('dcache', 'lsq'): 'LSQ ↔ DCache：LoadQueue 空、cbo 请求 / 回应、MSHR 释放、TileLink D 通道监听',
    ('dcache', 'mbistPl'): 'DCache 各 SRAM 的 MBIST 穿线',
    ('dcache', 'mmioBufB'): 'DCache 的 uncache 口（经两级 TLBuffer 接到 Uncache 交叉开关）',
    ('dcache', 'perfHpm'): 'DCache 性能事件',
    ('dcache', 'sbuffer'): 'Sbuffer 写 DCache 的请求 / 命中回应 / 重放',
    ('dcache', 'sms'): 'DCache 驱逐通知 SMS（agt 训练）',
    ('dcache', 'stu0'): 'store 流水 0 的 DCache 预取探测口（lsu.sta）',
    ('dcache', 'stu1'): 'store 流水 1 的 DCache 预取探测口（lsu.sta）',
    ('dcache', 'vSeg'): 'segment 单元经 load 口 0 读 DCache 的回应 / bank 冲突',
    ('dtlbLd', 'dtlbRepeater'): 'load DTLB 的 4 个缺失请求进 PTWNewFilter（valid 经本层过滤）',
    ('dtlbLd', 'l1Pf'): 'L1 流预取借用的 load DTLB 口 3（翻译结果回给预取器）',
    ('dtlbLd', 'ldu0'): 'load 流水 0 的地址翻译请求 / 回应（DTLB 口 0）',
    ('dtlbLd', 'ldu1'): 'load 流水 1 的地址翻译请求 / 回应（DTLB 口 1）',
    ('dtlbLd', 'ldu2'): 'load 流水 2 的地址翻译请求 / 回应（DTLB 口 2）',
    ('dtlbLd', 'perfHpm'): 'load DTLB 性能事件',
    ('dtlbLd', 'pmpCheck0'): 'DTLB 口 0 翻译出的物理地址送 PMP 检查口 0',
    ('dtlbLd', 'pmpCheck1'): 'DTLB 口 1 翻译出的物理地址送 PMP 检查口 1',
    ('dtlbLd', 'pmpCheck2'): 'DTLB 口 2 翻译出的物理地址送 PMP 检查口 2',
    ('dtlbLd', 'pmpCheck3'): 'DTLB 口 3 翻译出的物理地址送 PMP 检查口 3',
    ('dtlbLd', 'vSeg'): 'segment 单元借用 load DTLB 口 0 的翻译结果',
    ('dtlbPf', 'dtlbRepeater'): '预取 DTLB 的 2 个缺失请求进 PTWNewFilter（valid 经本层过滤）',
    ('dtlbPf', 'pmpCheck6'): '预取 DTLB 口 0 的物理地址送 PMP 检查口 6',
    ('dtlbPf', 'pmpCheck7'): '预取 DTLB 口 1 的物理地址送 PMP 检查口 7（L2 预取用）',
    ('dtlbPf', 'sms'): 'SMS 借用的预取 DTLB 口 0 的翻译请求 / 回应',
    ('dtlbRepeater', 'dtlbSt'): 'store DTLB 的 2 个缺失请求进 PTWNewFilter（valid 经本层过滤）',
    ('dtlbRepeater', 'ldu0'): 'PTWNewFilter 给 load 流水 0 的"等页表"提示 id',
    ('dtlbRepeater', 'ldu1'): 'PTWNewFilter 给 load 流水 1 的"等页表"提示 id',
    ('dtlbRepeater', 'ldu2'): 'PTWNewFilter 给 load 流水 2 的"等页表"提示 id',
    ('dtlbRepeater', 'lsq'): 'PTWNewFilter 的回应提示（让 LoadQueue 重放等这条页表的 load）',
    ('dtlbRepeater', 'ptw'): 'PTWNewFilter ↔ L2TLB 的 DTLB 请求 / 回应口（tlb(1)）',
    ('dtlbSt', 'perfHpm'): 'store DTLB 性能事件',
    ('dtlbSt', 'pmpCheck4'): 'store DTLB 口 0 的物理地址送 PMP 检查口 4',
    ('dtlbSt', 'pmpCheck5'): 'store DTLB 口 1 的物理地址送 PMP 检查口 5',
    ('dtlbSt', 'stu0'): 'store 流水 0 的地址翻译请求 / 回应',
    ('dtlbSt', 'stu1'): 'store 流水 1 的地址翻译请求 / 回应',
    ('itlbRepeater', 'ptw'): '前端 ITLB 的缺失经 PTWRepeaterNB ↔ L2TLB（tlb(0)）',
    ('l1Pf', 'l1PfReqQueue'): 'L1 流预取发出的 L1 预取请求进一级打拍',
    ('l1Pf', 'l1PfToL2Dly'): 'L1 流预取发往 L2 的预取请求（延迟两拍）',
    ('l1Pf', 'ldu0'): 'load 流水 0 训练 L1 流预取（L1 训练口）',
    ('l1Pf', 'ldu1'): 'load 流水 1 训练 L1 流预取（L1 训练口）',
    ('l1Pf', 'ldu2'): 'load 流水 2 训练 L1 流预取（L1 训练口）',
    ('l1Pf', 'pmpCheck3'): 'L1 流预取翻译结果的 PMP 检查（口 3）',
    ('l1PfReqQueue', 'ldu0'): 'L1 预取请求送 load 流水 0',
    ('l1PfReqQueue', 'ldu1'): 'L1 预取请求送 load 流水 1',
    ('l1PfReqQueue', 'ldu2'): 'L1 预取请求送 load 流水 2',
    ('ldu0', 'ldu0'): 'load 流水 0 的快速重放：fast_rep_out 直接绕回 fast_rep_in',
    ('ldu0', 'lmb'): 'load 流水 0 的非对齐请求进非对齐 load 缓冲',
    ('ldu0', 'lsq'): 'load 流水 0 ↔ LSQ：入 LoadQueue、store→load 前递、违例查询、重放、NC 回包',
    ('ldu0', 'perfHpm'): 'load 流水 0 性能事件',
    ('ldu0', 'pmpCheck0'): 'load 流水 0 的 PMP 检查结果',
    ('ldu0', 'sbuffer'): 'Sbuffer → load 流水 0 的 store 数据前递',
    ('ldu0', 'sms'): 'load 流水 0 训练 SMS',
    ('ldu0', 'stu0'): 'store 流水 0 的 st-ld 违例查询广播给 load 流水 0',
    ('ldu0', 'stu1'): 'store 流水 1 的 st-ld 违例查询广播给 load 流水 0',
    ('ldu0', 'uncache'): 'Uncache → load 流水 0 的 NC 写数据前递',
    ('ldu0', 'vlMerge'): 'load 流水 0 的向量结果进向量 load 合并缓冲',
    ('ldu0', 'vlSplit0'): 'load 流水 0 的向量结果回告 vlSplit0（流水进度）',
    ('ldu0', 'vlSplit1'): 'load 流水 0 的向量结果回告 vlSplit1（流水进度）',
    ('ldu0', 'vlToLdu0'): 'vlSplit0 拆出的向量元素经打拍级送 load 流水 0',
    ('ldu1', 'ldu1'): 'load 流水 1 的快速重放：fast_rep_out 直接绕回 fast_rep_in',
    ('ldu1', 'lmb'): 'load 流水 1 ↔ 非对齐 load 缓冲：入队，以及缓冲拆出来的子请求在流水 1 上执行、结果回缓冲',
    ('ldu1', 'lsq'): 'load 流水 1 ↔ LSQ：入 LoadQueue、store→load 前递、违例查询、重放、NC 回包',
    ('ldu1', 'perfHpm'): 'load 流水 1 性能事件',
    ('ldu1', 'pmpCheck1'): 'load 流水 1 的 PMP 检查结果',
    ('ldu1', 'sbuffer'): 'Sbuffer → load 流水 1 的 store 数据前递',
    ('ldu1', 'sms'): 'load 流水 1 训练 SMS',
    ('ldu1', 'stu0'): 'store 流水 0 的 st-ld 违例查询广播给 load 流水 1',
    ('ldu1', 'stu1'): 'store 流水 1 的 st-ld 违例查询广播给 load 流水 1',
    ('ldu1', 'uncache'): 'Uncache → load 流水 1 的 NC 写数据前递',
    ('ldu1', 'vlToLdu1'): 'vlSplit1 拆出的向量元素经打拍级送 load 流水 1',
    ('ldu2', 'ldu2'): 'load 流水 2 的快速重放：fast_rep_out 直接绕回 fast_rep_in',
    ('ldu2', 'lmb'): 'load 流水 2 的非对齐请求进非对齐 load 缓冲',
    ('ldu2', 'lsq'): 'load 流水 2 ↔ LSQ：入 LoadQueue、store→load 前递、违例查询、重放、NC 回包',
    ('ldu2', 'perfHpm'): 'load 流水 2 性能事件',
    ('ldu2', 'pmpCheck2'): 'load 流水 2 的 PMP 检查结果',
    ('ldu2', 'sbuffer'): 'Sbuffer → load 流水 2 的 store 数据前递',
    ('ldu2', 'sms'): 'load 流水 2 训练 SMS',
    ('ldu2', 'stu0'): 'store 流水 0 的 st-ld 违例查询广播给 load 流水 2',
    ('ldu2', 'stu1'): 'store 流水 1 的 st-ld 违例查询广播给 load 流水 2',
    ('ldu2', 'uncache'): 'Uncache → load 流水 2 的 NC 写数据前递',
    ('ldu2', 'vlMerge'): 'load 流水 2 的向量结果进向量 load 合并缓冲',
    ('ldu2', 'vlSplit0'): 'load 流水 2 的向量结果回告 vlSplit0（流水进度）',
    ('ldu2', 'vlSplit1'): 'load 流水 2 的向量结果回告 vlSplit1（流水进度）',
    ('lsq', 'otherStout'): 'StoreQueue 的 MMIO / cbo.zero store 写回进打拍级（ready 回给 StoreQueue）',
    ('lsq', 'perfHpm'): 'LSQ 性能事件',
    ('lsq', 'sbuffer'): 'StoreQueue 出队写 Sbuffer（口 1）、Sbuffer 空 / 强制写回',
    ('lsq', 'smb'): 'StoreQueue ↔ 非对齐 store 缓冲的控制握手',
    ('lsq', 'stu0'): 'store 流水 0 ↔ StoreQueue：地址 / 掩码写入、提交指针',
    ('lsq', 'stu1'): 'store 流水 1 ↔ StoreQueue：地址 / 掩码写入、提交指针',
    ('lsq', 'uncache'): 'Uncache 给 LSQ 的 idResp（出队编号）',
    ('lsq', 'uncacheReqReg'): 'LSQ 的 uncache 请求进一级打拍',
    ('lsq', 'uncacheRespReg'): 'Uncache 回应经一级打拍回 LSQ',
    ('lsq', 'vlMerge'): '向量 load 合并缓冲 → LoadQueue 的向量反馈',
    ('lsq', 'vlSplit0'): 'LoadQueue 出队位置（split 的发射门槛）',
    ('lsq', 'vlSplit1'): 'LoadQueue 出队位置（split 的发射门槛）',
    ('lsq', 'vsMerge0'): '向量 store 合并缓冲 0 → StoreQueue 的向量反馈',
    ('lsq', 'vsMerge1'): '向量 store 合并缓冲 1 → StoreQueue 的向量反馈',
    ('lsq', 'vsSplit0'): 'StoreQueue 提交位置（split 的发射门槛）与出队类型',
    ('lsq', 'vsSplit1'): 'StoreQueue 提交位置（split 的发射门槛）与出队类型',
    ('mbistIntf', 'mbistPl'): 'MBIST 接口 ↔ 本层分发流水',
    ('mbistPl', 'mbistSmsPl'): 'MBIST 分发流水 → SMS 的 MBIST 子流水',
    ('mbistPl', 'ptw'): 'L2TLB 各 SRAM 的 MBIST 穿线',
    ('mbistSmsPl', 'sms'): 'SMS 的 PHT SRAM 的 MBIST 穿线',
    ('mmioBufA', 'mmioBufB'): 'Uncache 交叉开关 → 外设总线的两级 TLBuffer 首尾相接',
    ('mmioBufA', 'uncacheXbar'): 'Uncache 交叉开关的出口 0 → 去外设总线的两级缓冲',
    ('perfHpm', 'pfevent'): 'CSR 选出的 8 个性能事件编码',
    ('perfHpm', 'ptw'): 'L2TLB 性能事件',
    ('perfHpm', 'sbuffer'): 'Sbuffer 性能事件',
    ('pmp', 'pmpCheck0'): 'PMP/PMA 表项给检查口 0',
    ('pmp', 'pmpCheck1'): 'PMP/PMA 表项给检查口 1',
    ('pmp', 'pmpCheck2'): 'PMP/PMA 表项给检查口 2',
    ('pmp', 'pmpCheck3'): 'PMP/PMA 表项给检查口 3',
    ('pmp', 'pmpCheck4'): 'PMP/PMA 表项给检查口 4',
    ('pmp', 'pmpCheck5'): 'PMP/PMA 表项给检查口 5',
    ('pmp', 'pmpCheck6'): 'PMP/PMA 表项给检查口 6',
    ('pmp', 'pmpCheck7'): 'PMP/PMA 表项给检查口 7',
    ('pmpCheck0', 'vSeg'): 'segment 单元复用 load 口 0 的 PMP 检查结果',
    ('pmpCheck4', 'stu0'): 'store 流水 0 的 PMP 检查结果',
    ('pmpCheck5', 'stu1'): 'store 流水 1 的 PMP 检查结果',
    ('pmpCheck6', 'sms'): 'SMS 翻译结果的 PMP 检查（口 6）',
    ('ptw', 'ptwToL2Buf'): 'L2TLB 读页表的 TileLink 主口（经一级缓冲去 L2）',
    ('sbuffer', 'vSeg'): 'Sbuffer 写入口 0 的 ready 回给 segment 单元',
    ('smb', 'stu0'): 'store 流水 0 ↔ 非对齐 store 缓冲：入队，以及拆出来的子请求在流水 0 上执行、结果回缓冲',
    ('smb', 'stu1'): 'store 流水 1 的非对齐请求进非对齐 store 缓冲',
    ('smb', 'vsSplit0'): '非对齐 store 缓冲是否为空（vsSplit 的向量数据要等它）',
    ('smb', 'vsSplit1'): '非对齐 store 缓冲是否为空（vsSplit 的向量数据要等它）',
    ('sms', 'smsToL2Dly'): 'SMS 发往 L2 的预取请求（延迟两拍）',
    ('stu0', 'vsToStu0'): 'vsSplit0 拆出的向量元素经打拍级送 store 流水 0',
    ('stu1', 'vsToStu1'): 'vsSplit1 拆出的向量元素经打拍级送 store 流水 1',
    ('uncache', 'uncacheBuf'): 'Uncache 的 TileLink 主口（经一级缓冲进交叉开关）',
    ('uncache', 'uncacheErrDly'): 'Uncache 总线错误（延迟两拍后上报）',
    ('uncache', 'uncacheReqReg'): '打拍后的 uncache 请求进 Uncache',
    ('uncache', 'uncacheRespReg'): 'Uncache 回应进一级打拍',
    ('uncacheBuf', 'uncacheXbar'): 'Uncache 的缓冲 → Uncache 交叉开关入口',
    ('vfof', 'vlMerge'): '向量 load 合并缓冲的写回同时告诉 VfofBuffer（fault-only-first 的 vl 修正）',
    ('vlMerge', 'vlSplit0'): 'vlSplit0 向向量 load 合并缓冲申请表项 / 门槛',
    ('vlMerge', 'vlSplit1'): 'vlSplit1 向向量 load 合并缓冲申请表项 / 门槛',
    ('vlSplit0', 'vlToLdu0'): 'vlSplit0 的输出进打拍级',
    ('vlSplit1', 'vlToLdu1'): 'vlSplit1 的输出进打拍级',
    ('vsMerge0', 'vsSplit0'): 'vsSplit0 向向量 store 合并缓冲 0 申请表项 / 门槛',
    ('vsMerge1', 'vsSplit1'): 'vsSplit1 向向量 store 合并缓冲 1 申请表项 / 门槛',
    ('vsSplit0', 'vsToStu0'): 'vsSplit0 的输出进打拍级',
    ('vsSplit1', 'vsToStu1'): 'vsSplit1 的输出进打拍级',
}

# =============================================================================
# 顶层胶合寄存器：golden 本层寄存器名 → u_core 里的寄存器（"名字" 或 "名字[下标]"）。
# 核把这些寄存器原样作为输出口送出（子模块或顶层要读的那些），钉点逐位对上。
# =============================================================================
CORE_REGS = collections.OrderedDict()


def _reg(g, c):
    CORE_REGS['inner_' + g] = c


# §1 重定向打一拍 / CSR 与预取开关
_reg('redirect_next_valid_last_REG', 'redirect_valid')
_reg('redirect_next_bits_r_robIdx_flag', 'redirect_robIdx_flag')
_reg('redirect_next_bits_r_robIdx_value', 'redirect_robIdx_value')
_reg('redirect_next_bits_r_level', 'redirect_level')
_reg('dcache_io_l2_pf_store_only_REG', 'l2_pf_store_only')
for _k, (_g, _c) in enumerate([('l1D_pf_enable_next_r', 'pf_l1d_enable'), ('sms_io_enable_next_r', 'pf_sms_recv_enable'),
                               ('sms_io_agt_en_next_r', 'pf_sms_agt_enable'), ('sms_io_pht_en_next_r', 'pf_sms_pht_enable'),
                               ('sms_io_act_threshold_next_r', 'pf_sms_act_threshold'),
                               ('sms_io_act_stride_next_r', 'pf_sms_act_stride'),
                               ('l1Prefetcher_io_enable_next_r', 'pf_l1_stride_enable')]):
    _reg(_g, '%s[0]' % _c)
    _reg(_g + '_1', '%s[1]' % _c)
_reg('pf_train_on_hit_REG', 'pf_train_on_hit[0]')
_reg('pf_train_on_hit', 'pf_train_on_hit[1]')
# §2 sfence / TLB CSR 打两拍
for _f in ('valid', 'bits_rs1', 'bits_rs2', 'bits_addr', 'bits_id', 'bits_flushPipe', 'bits_hv', 'bits_hg'):
    _c = _f.replace('bits_', '')
    _reg('sfence_REG_' + _f, 'sfence_d1_' + _c)
    _reg('sfence_' + _f, 'sfence_' + _c)
TLBCSR_FIELDS = ['satp_mode', 'satp_asid', 'satp_ppn', 'satp_changed', 'vsatp_mode', 'vsatp_asid', 'vsatp_ppn',
                 'vsatp_changed', 'hgatp_mode', 'hgatp_vmid', 'hgatp_ppn', 'hgatp_changed', 'mbmc_BME', 'mbmc_CMODE',
                 'mbmc_BCLEAR', 'mbmc_BMA', 'priv_mxr', 'priv_sum', 'priv_vmxr', 'priv_vsum', 'priv_virt',
                 'priv_virt_changed', 'priv_spvp', 'priv_imode', 'priv_dmode', 'priv_debug', 'mPBMTE', 'hPBMTE',
                 'pmm_mseccfg', 'pmm_menvcfg', 'pmm_henvcfg', 'pmm_hstatus', 'pmm_senvcfg']
for _f in TLBCSR_FIELDS:
    _reg('tlbcsr_REG_' + _f, 'tlbcsr_d1_' + _f)
    # firtool 把第二拍的 mbmc.CMODE 寄存器命名成了 inner__5（它只喂子模块的 cmode 口）
    _reg('_5' if _f == 'mbmc_CMODE' else 'tlbcsr_' + _f, 'tlbcsr_' + _f)
# §3 DTLB 回填打拍与重放
PTW_RESP_FIELDS = ['s2xlate', 's1_entry_tag', 's1_entry_asid', 's1_entry_vmid', 's1_entry_pbmt', 's1_entry_perm_d',
                   's1_entry_perm_a', 's1_entry_perm_g', 's1_entry_perm_u', 's1_entry_perm_x', 's1_entry_perm_w',
                   's1_entry_perm_r', 's1_entry_level', 's1_entry_v', 's1_entry_ppn', 's1_addr_low', 's1_pf',
                   's1_af', 's2_entry_tag', 's2_entry_vmid', 's2_entry_pbmt', 's2_entry_ppn', 's2_entry_perm_d',
                   's2_entry_perm_a', 's2_entry_perm_g', 's2_entry_perm_u', 's2_entry_perm_x', 's2_entry_perm_w',
                   's2_entry_perm_r', 's2_entry_level', 's2_gpf', 's2_gaf']
for _f in PTW_RESP_FIELDS:
    _reg('ptw_resp_next_data_' + _f, 'ptwResp_' + _f)
_reg('_tlbreplay_0_allStage_n_T', 'ptwResp_s1_entry_n')     # firtool 按用途给 s1.entry.n 起的名
_reg('_tlbreplay_0_allStage_n_T_3', 'ptwResp_s2_entry_n')
for _i in range(8):
    _reg('ptw_resp_next_data_s1_ppn_low_%d' % _i, 'ptwResp_s1_ppn_low[%d]' % _i)
    _reg('ptw_resp_next_data_s1_valididx_%d' % _i, 'ptwResp_s1_valididx[%d]' % _i)
    _reg('ptw_resp_next_data_s1_pteidx_%d' % _i, 'ptwResp_s1_pteidx[%d]' % _i)
for _v, _c in ((0, 'Ld'), (4, 'St'), (6, 'Pf')):
    _reg('ptw_resp_next_vector_%d' % _v, 'ptwResp_forDtlb%s' % _c)
    _reg('ptw_resp_next_getGpa_%d' % _v, 'ptwResp_getGpa%s' % _c)
_reg('ptw_resp_v', 'ptwResp_valid')
for _i in range(3):
    _reg('tlbreplay_reg_r_%d' % _i, 'tlbReplay_q[%d]' % _i)
for _i in range(4):
    _reg('dtlb_ld0_tlbreplay_reg_r_%d' % _i, 'dtlbLdReplay_q[%d]' % _i)
# §4 触发器
for _i in range(4):
    for _f in ('matchType', 'select', 'timing', 'action', 'chain', 'store', 'load', 'tdata2'):
        _reg('tdata_%d_%s' % (_i, _f), 'trig_%s[%d]' % (_f, _i))
    _reg('tEnable_%d' % _i, 'trig_enable[%d]' % _i)
# §5 vector segment 独占
_reg('vSegmentFlag', 'seg_active')
_reg('last_REG', 'seg_start_q')
_reg('last_REG_1', 'seg_done_q')
_reg('vSegmentFlagPrev', 'seg_active_q')
_reg('dtlb_ld_tlb_ld_io_requestor_0_req_valid_REG', 'segTlb_valid_q')
_reg('dtlb_ld_tlb_ld_io_requestor_0_req_bits_REG', 'segTlb_sel_q')
for _f, _c in (('vaddr', 'vaddr'), ('fullva', 'fullva'), ('cmd', 'cmd'), ('debug_robIdx_flag', 'robIdx_flag'),
               ('debug_robIdx_value', 'robIdx_value')):
    _reg('dtlb_ld_tlb_ld_io_requestor_0_req_bits_r_' + _f, 'segTlb_%s_q' % _c)
# §6 预取训练用的 PC 打拍：L1 流预取与 SMS 各一套（Chisel 里两处各自 RegNext，一份都不许少）
for _i in range(3):
    _reg('loadPc' if _i == 0 else 'loadPc_%d' % _i, 'l1pfPc_s1[%d]' % _i)
    _reg('l1Prefetcher_stride_train_%d_bits_uop_pc_r' % _i, 'l1pfPc_chase[%d]' % _i)
    _reg('l1Prefetcher_stride_train_%d_bits_uop_pc_r_1' % _i, 'l1pfPc_s2[%d]' % _i)
    _reg('l1Prefetcher_stride_train_%d_bits_uop_pc_r_2' % _i, 'l1pfPc_s3[%d]' % _i)
    _reg('loadPc_%d' % (_i + 3), 'smsPc_s1[%d]' % _i)
    _reg('prefetcherOpt_io_ld_in_%d_bits_uop_pc_r' % _i, 'smsPc_chase[%d]' % _i)
    _reg('prefetcherOpt_io_ld_in_%d_bits_uop_pc_r_1' % _i, 'smsPc_s2[%d]' % _i)
    _reg('prefetcherOpt_io_ld_in_%d_bits_uop_pc_r_2' % _i, 'smsPc_s3[%d]' % _i)
_reg('l2_hint_2_valid', 'l2hint_valid')
_reg('l2_hint_2_bits_sourceId', 'l2hint_sourceId')
_reg('l2_hint_2_bits_isKeyword', 'l2hint_isKeyword')
# §7 Uncache 状态机 / Sbuffer 冲刷 / 原子指令
_reg('uncacheState', 'uncache_state')
_reg('io_mem_to_ooo_sbIsEmpty_REG', 'sb_empty_q')
_reg('sbuffer_io_flush_valid_REG', 'sb_flush_valid')
_reg('state', 'amo_state')
# §8 例外地址
_reg('atomicsException', 'amo_exc_pending')
_reg('vSegmentException', 'seg_exc_pending')
_reg('atomicsExceptionAddress', 'amo_exc_vaddr')
_reg('vSegmentExceptionAddress', 'seg_exc_vaddr')
_reg('atomicsExceptionGPAddress', 'amo_exc_gpaddr')
_reg('vSegmentExceptionGPAddress', 'seg_exc_gpaddr')
_reg('atomicsExceptionIsForVSnonLeafPTE', 'amo_exc_nonLeafPte')
_reg('vSegmentExceptionIsForVSnonLeafPTE', 'seg_exc_nonLeafPte')
_reg('io_mem_to_ooo_lsqio_vaddr_REG', 'exc_vaddr_q')
_reg('io_mem_to_ooo_lsqio_gpaddr_REG', 'exc_gpaddr_q')
_reg('io_mem_to_ooo_lsqio_isForVSnonLeafPTE_REG', 'exc_nonLeafPte_q')
# §9 顶层旁路
_reg('io_mem_to_ooo_topToBackendBypass_l2FlushDone_REG', 'l2_flush_done_q')
for _f in ('msip', 'mtip', 'meip', 'seip', 'debug'):
    _reg('io_mem_to_ooo_topToBackendBypass_externalInterrupt_%s_REG' % _f, 'irq_%s_q' % _f)
_reg('io_mem_to_ooo_topToBackendBypass_externalInterrupt_nmi_nmi_31_REG', 'irq_nmi31_q')
_reg('io_mem_to_ooo_topToBackendBypass_externalInterrupt_nmi_nmi_43_REG', 'irq_nmi43_q')
_reg('io_inner_reset_vector_REG', 'reset_vector_q')
_reg('io_outer_cpu_halt_REG', 'cpu_halt_q')
_reg('io_outer_cpu_critical_error_REG', 'cpu_critical_error_q')
_reg('io_outer_beu_errors_icache_REG_ecc_error_valid', 'beu_icache_valid_q')
_reg('io_outer_beu_errors_icache_REG_ecc_error_bits', 'beu_icache_bits_q')
for _i in range(69):
    _reg('REG_%d_value' % _i, 'hc_perf_q[%d]' % _i)
_reg('io_traceCoreInterfaceBypass_fromBackend_fromEncoder_REG_enable', 'trace_enc_enable_q')
_reg('io_traceCoreInterfaceBypass_fromBackend_fromEncoder_REG_stall', 'trace_enc_stall_q')
_reg('io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_r_cause', 'trace_trap_cause_q')
_reg('io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_r_tval', 'trace_trap_tval_q')
_reg('io_traceCoreInterfaceBypass_toL2Top_toEncoder_priv_r', 'trace_priv_q')
_reg('io_traceCoreInterfaceBypass_toL2Top_toEncoder_mstatus_REG', 'trace_mstatus_q')
for _i in range(3):
    _p = 'io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_%d_' % _i
    _reg(_p + 'valid_REG', 'trace_grp_valid_q[%d]' % _i)
    _reg(_p + 'bits_iretire_REG', 'trace_grp_iretire_q[%d]' % _i)
    _reg(_p + 'bits_itype_REG', 'trace_grp_itype_q[%d]' % _i)
    _reg(_p + 'bits_ilastsize_r', 'trace_grp_ilastsize_q[%d]' % _i)
    _reg(_p + 'bits_iaddr_r', 'trace_grp_iaddr_q[%d]' % _i)
    _reg(_p + 'bits_iaddr_r_1', 'trace_grp_ftqOffset_q[%d]' % _i)
_reg('io_topDownInfo_toBackend_l2TopMiss_l2Miss_REG', 'l2_miss_q')
_reg('io_topDownInfo_toBackend_l2TopMiss_l3Miss_REG', 'l3_miss_q')
for _i in range(8):
    _reg('io_perf_%d_value_REG' % _i, 'perf_d1[%d]' % _i)
    _reg('io_perf_%d_value_REG_1' % _i, 'perf_d2[%d]' % _i)


# =============================================================================
# golden 解析
# =============================================================================
def golden_ports(mod):
    t = (G1 / ('%s.sv' % mod)).read_text(errors='replace')
    m = re.search(r'^module %s\(\n(.*?)\n\);' % re.escape(mod), t, re.M | re.S)
    if not m:
        fail('golden %s 端口表解析失败' % mod)
    out = []
    for ln in m.group(1).splitlines():
        pm = PORT_RE.match(ln)
        if not pm:
            fail('golden %s 端口行形状未知: %r' % (mod, ln))
        out.append((pm.group(1), int(pm.group(2) or 0) + 1, pm.group(3)))
    return out


class Golden:
    def __init__(self):
        t = (G1 / 'MemBlock.sv').read_text(errors='replace')
        st = re.search(r'^module MemBlock\(', t, re.M).start()
        body = t[st:]
        body = body[:body.index('\nendmodule')]
        self.ports = golden_ports(TOP)
        self.tdir = {n: d for d, w, n in self.ports}
        self.twid = {n: w for d, w, n in self.ports}
        code = body[body.index('\n);') + 3:]
        code = re.sub(r'`ifndef SYNTHESIS.*?`endif // not def SYNTHESIS', '', code, flags=re.S)
        code = re.sub(r'`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_', '', code, flags=re.S)
        self.defs = {}
        self.wid = {}
        for m in re.finditer(r'^  wire\s+(?:\[(\d+):0\]\s+)?(\w+)(?:\s*=\s*(.*?))?;', code, re.M | re.S):
            self.wid[m.group(2)] = int(m.group(1) or 0) + 1
            if m.group(3) is not None:
                self.defs[m.group(2)] = norm(m.group(3))
        for m in re.finditer(r'^  assign (\w+) =\s*(.*?);', code, re.M | re.S):
            if m.group(1) in self.defs:
                fail('golden %s 被定义两次' % m.group(1))
            self.defs[m.group(1)] = norm(m.group(2))
        self.regs = collections.OrderedDict(
            (m.group(2), int(m.group(1) or 0) + 1)
            for m in re.finditer(r'^  reg\s+(?:\[(\d+):0\]\s+)?(\w+);', code, re.M))
        self.insts = collections.OrderedDict()
        for m in re.finditer(r'^  (\w+) (\w+) \(\n(.*?)\n  \);', code, re.M | re.S):
            conns = [(c.group(1), norm(c.group(2)))
                     for c in re.finditer(r'\.(\w+)\s*\((.*?)\)(?=,\n|\Z)', m.group(3), re.S)]
            self.insts[m.group(2)] = (m.group(1), conns)
        self.cports = {}
        for i, (mod, conns) in self.insts.items():
            ps = golden_ports(mod)
            self.cports[i] = collections.OrderedDict((n, (d, w)) for d, w, n in ps)
            if sorted(p for p, _ in conns) != sorted(self.cports[i]):
                fail('%s(%s) 的连接端口集合与模块端口表不一致' % (i, mod))
        # 子模块输出驱动的线：golden `_inner_<实例>_<端口>` 或具名线 → (实例, 端口)
        self.drv = {}
        self.top_direct = {}            # 顶层输出 ← (实例, 端口)
        for i, (mod, conns) in self.insts.items():
            for p, e in conns:
                if self.cports[i][p][0] != 'output' or e in ('', '/* unused */'):
                    continue
                if e in self.tdir:
                    if self.tdir[e] != 'output':
                        fail('%s.%s 驱动顶层输入 %s' % (i, p, e))
                    self.top_direct[e] = (i, p)
                    continue
                if not re.fullmatch(r'\w+', e):
                    fail('%s.%s 输出接的是表达式 %r' % (i, p, e))
                if e in self.drv:
                    fail('线 %s 有两个驱动' % e)
                self.drv[e] = (i, p)

    def resolve(self, e):
        """沿 golden 的别名线（`wire x = y;` / `assign x = y;`，右边是单个名字或常量）解开。"""
        for _ in range(50):
            if not re.fullmatch(r'\w+', e) or e in self.tdir or e in self.drv or e in self.regs:
                return e
            n = self.defs.get(e)
            if n is None or not (re.fullmatch(r'\w+', n) or CONST_RE.fullmatch(n)):
                return e
            e = n
        fail('别名链过长: %s' % e)

    def kind(self, e):
        if e in ('', '/* unused */'):
            return 'unused'
        if e in self.tdir:
            return 'top'
        if e in self.drv:
            return 'child'
        if CONST_RE.fullmatch(e):
            return 'const'
        if e in self.regs:
            return 'reg'
        return 'glue'


def strip_io(p):
    return p[3:] if p.startswith('io_') else p


def net_name(g, e):
    i, p = g.drv[e]
    return '%s_%s' % (ALIAS[i], strip_io(p))


def idents(expr):
    """golden 表达式里出现的信号名（跳过 4'h0 这类常量里的字母）。"""
    out = set()
    for m in re.finditer(r"(?<!['\w])([A-Za-z_]\w*)", expr):
        out.add(m.group(1))
    return out


# =============================================================================
# 核端口解析
# =============================================================================
def parse_params(text):
    ps = {}
    for m in re.finditer(r'localparam\s+int\s+(\w+)\s*=\s*(\d+)\s*;', text):
        ps[m.group(1)] = int(m.group(2))
    return ps


def eval_dim(s, ps):
    s = s.strip()
    for k in sorted(ps, key=len, reverse=True):
        s = re.sub(r'\b%s\b' % k, str(ps[k]), s)
    if not re.fullmatch(r'[\d\s+\-*()]+', s):
        fail('核端口维度表达式看不懂: %r' % s)
    return eval(s)                                          # noqa: S307  只含数字与 + - * ()


def parse_core(text, ps):
    m = re.search(r'^module %s\b.*?\(\n(.*?)\n\);' % CORE, text, re.M | re.S)
    if not m:
        return None
    ports = collections.OrderedDict()
    for ln in m.group(1).splitlines():
        s = ln.split('//')[0].strip()
        if not s:
            continue
        pm = re.fullmatch(r'(input|output)\s+logic\s+(?:\[([^\]]+):0\]\s+)?(\w+)(?:\s*\[(\w+)\])?\s*,?', s)
        if not pm:
            fail('核端口行形状未知: %r' % ln)
        w = eval_dim(pm.group(2), ps) + 1 if pm.group(2) else 1
        n = eval_dim(pm.group(4), ps) if pm.group(4) else None
        if pm.group(3) in ports:
            fail('核端口重名 %s' % pm.group(3))
        ports[pm.group(3)] = (pm.group(1), w, n)
    return ports


# =============================================================================
# 主分析
# =============================================================================
class Plan:
    pass


def analyse(g, core_text, strict=True):
    P = Plan()
    if set(g.insts) != set(ALIAS):
        fail('golden 实例集合与 ALIAS 不一致: 缺 %s 多 %s'
             % (sorted(set(g.insts) - set(ALIAS)), sorted(set(ALIAS) - set(g.insts))))
    # ---- 字段束 ----
    bfield = {}               # (inst 或 'top', 端口) -> (束名, 偏移, 宽)
    P.bundles = collections.OrderedDict()
    for b in BUNDLES:
        dk, dpfx = b.dest
        if dk == 'top':
            dports = [(n, w) for d, w, n in g.ports if d == 'output' and n.startswith(dpfx)]
        else:
            dports = [(n, w) for n, (d, w) in g.cports[dk].items() if d == 'input' and n.startswith(dpfx)]
        dports = [(n, w) for n, w in dports if n[len(dpfx):] not in b.exclude]
        if not dports:
            fail('字段束 %s 没有目的端口' % b.name)
        fields = []
        off = sum(w for _, w in dports)
        total = off
        for n, w in dports:
            f = n[len(dpfx):]
            off -= w
            srcs = []
            for tag, sk, spfx in b.srcs:
                if sk == 'top':
                    sn = spfx + f
                    if sn in g.tdir:
                        if g.tdir[sn] != 'input' or g.twid[sn] != w:
                            fail('字段束 %s 源 %s 字段 %s 方向/宽不符' % (b.name, tag, f))
                        srcs.append((tag, sn, sn))
                    else:
                        srcs.append((tag, None, b.fill.get((tag, f), FILLS.get((b.name, tag, f), 0))))
                else:
                    sp = spfx + f
                    if sp in g.cports[sk] and g.cports[sk][sp][0] == 'output':
                        if g.cports[sk][sp][1] != w:
                            fail('字段束 %s 源 %s 字段 %s 宽 %d != %d' % (b.name, tag, f, g.cports[sk][sp][1], w))
                        gnet = [e for e, (i, p) in g.drv.items() if i == sk and p == sp]
                        srcs.append((tag, gnet[0] if gnet else None,
                                     '%s_%s' % (ALIAS[sk], strip_io(sp)) if gnet else
                                     ('UNUSED', sk, sp)))
                    else:
                        srcs.append((tag, None, b.fill.get((tag, f), FILLS.get((b.name, tag, f), 0))))
            fields.append((n, f, w, off, srcs))
            key = ('top' if dk == 'top' else dk, n)
            if key in bfield:
                fail('端口 %s 落进两个字段束' % (key,))
            bfield[key] = (b.name, off, w)
        P.bundles[b.name] = (b, fields, total)
    # golden 表达式自检：每个目的字段的 golden 表达式只许引用同名字段的源与选择信号
    for bname, (b, fields, total) in P.bundles.items():
        dk, _ = b.dest
        for n, f, w, off, srcs in fields:
            if dk == 'top':
                ge = g.defs.get(n)
                if ge is None:
                    fail('字段束 %s 目的 %s 在 golden 里没有 assign（是直连？）' % (bname, n))
            else:
                ge = dict(g.insts[dk][1])[n]
            ge = g.resolve(ge)
            ok_src = {s[1] for s in srcs if s[1]}
            todo, seen = list(idents(ge)), set()
            while todo:
                x = todo.pop()
                if x in seen:
                    continue
                seen.add(x)
                if x in ok_src:
                    continue
                if x in g.defs and x not in g.drv and x not in g.tdir and x not in g.regs \
                        and not any(re.fullmatch(p, x) for p in b.sel):
                    todo.extend(idents(g.defs[x]))     # golden 临时线（如 _GEN_6 = 选择信号的组合）展开再查
                    continue
                if any(re.fullmatch(p, x) for p in b.sel):
                    continue
                if x in g.drv and any(x == s[1] for s in srcs):
                    continue
                if x in g.drv and g.drv[x][1].endswith('_valid') and any(
                        g.drv[x][0] == sk for _, sk, _ in b.srcs if sk != 'top'):
                    continue      # 源自己的 valid 作选择
                if x in g.tdir and g.tdir[x] == 'input' and x.endswith('_valid') and any(
                        sk == 'top' for _, sk, _ in b.srcs):
                    continue
                fail('字段束 %s 字段 %s 的 golden 表达式引用了 %s（不是同名字段源也不是选择信号）：%s'
                     % (bname, f, x, ge[:200]))
            for tag, gnet, v in srcs:
                if isinstance(v, tuple):
                    fail('字段束 %s 源 %s 字段 %s 在 golden 里悬空却被要求读' % (bname, tag, f))

    # ---- 子模块输入逐个分类 ----
    groups = collections.OrderedDict()      # golden 胶合表达式 -> 核输出口名
    P.rows = collections.OrderedDict()      # inst -> [(port, rendered, dir, kind)]
    need_core_out = collections.OrderedDict()   # 名字 -> 宽（及数组维）
    used_regs = set()
    consumers = collections.defaultdict(list)
    for inst, (mod, conns) in g.insts.items():
        a = ALIAS[inst]
        rows = []
        for p, e in conns:
            d, w = g.cports[inst][p]
            if d == 'output':
                if e in ('', '/* unused */'):
                    rows.append((p, '', d, ('unused', None)))
                elif e in g.tdir:
                    rows.append((p, e, d, ('topout', None)))
                else:
                    rows.append((p, net_name(g, e), d, ('drv', None)))
                continue
            if (inst, p) in bfield:
                bn, off, bw = bfield[(inst, p)]
                rows.append((p, '%s[%d:%d]' % (bn, off + bw - 1, off) if bw > 1 else '%s[%d]' % (bn, off),
                             d, ('core', None)))
                consumers[bn].append(a)
                continue
            r = g.resolve(e)
            k = g.kind(r)
            if k == 'top':
                if g.tdir[r] != 'input' or g.twid[r] != w:
                    fail('%s.%s 接顶层 %s 方向/宽不符' % (inst, p, r))
                rows.append((p, r, d, ('top', r)))
            elif k == 'child':
                n = net_name(g, r)
                di, dp = g.drv[r]
                if g.cports[di][dp][1] != w:
                    fail('%s.%s 宽 %d 与驱动 %s 宽不符' % (inst, p, w, n))
                consumers[n].append(a)
                rows.append((p, n, d, ('inst', ALIAS[di])))
            elif k == 'const':
                rows.append((p, r, d, ('const', None)))
            elif k == 'reg':
                if r not in CORE_REGS:
                    if strict:
                        fail('%s.%s 接 golden 寄存器 %s，CORE_REGS 里没有' % (inst, p, r))
                    cn = 'REG?' + r
                else:
                    cn = CORE_REGS[r]
                used_regs.add(r)
                rows.append((p, cn, d, ('core', None)))
                base = cn.split('[')[0]
                consumers[base].append(a)
                need_core_out.setdefault(base, ('reg', r))
            else:
                if r not in groups:
                    _dn = '%s_%s' % (a, strip_io(p))
                    groups[r] = NAMES.get(_dn, _dn)
                cn = groups[r]
                rows.append((p, cn, d, ('core', None)))
                consumers[cn].append(a)
                prev = need_core_out.get(cn)
                if prev and prev != ('glue', w):
                    fail('核输出 %s 被两种宽/类用到: %s vs %s' % (cn, prev, ('glue', w)))
                need_core_out[cn] = ('glue', w)
        P.rows[inst] = rows
    # ---- 顶层输出 ----
    P.top_assign = collections.OrderedDict()      # 顶层输出 -> (kind, rhs)
    for d, w, n in g.ports:
        if d != 'output':
            continue
        if n in g.top_direct:
            if n in g.defs:
                fail('顶层输出 %s 既由实例直驱又有 assign' % n)
            continue
        if ('top', n) in bfield:
            bn, off, bw = bfield[('top', n)]
            P.top_assign[n] = ('bundle', '%s[%d:%d]' % (bn, off + bw - 1, off) if bw > 1 else '%s[%d]' % (bn, off))
            consumers[bn].append('top')
            continue
        if n not in g.defs:
            fail('顶层输出 %s 没有驱动' % n)
        r = g.resolve(g.defs[n])
        k = g.kind(r)
        if k == 'top':
            P.top_assign[n] = ('top', r)
        elif k == 'child':
            P.top_assign[n] = ('child', net_name(g, r))
            consumers[net_name(g, r)].append('top')
        elif k == 'const':
            P.top_assign[n] = ('const', r)
        elif k == 'reg':
            if r not in CORE_REGS:
                if strict:
                    fail('顶层输出 %s 接 golden 寄存器 %s，CORE_REGS 里没有' % (n, r))
                cn = 'REG?' + r
            else:
                cn = CORE_REGS[r]
            used_regs.add(r)
            P.top_assign[n] = ('reg', cn)
            need_core_out.setdefault(cn.split('[')[0], ('reg', r))
        else:
            if r in groups:
                # 与某个子模块输入同一 golden 表达式：顶层输出直接取那个核输出口
                P.top_assign[n] = ('glue', groups[r])
            else:
                groups[r] = n
                P.top_assign[n] = ('core', n)
                need_core_out[n] = ('glue', w)
    P.groups = groups
    P.need_core_out = need_core_out
    P.consumers = consumers
    P.bfield = bfield
    P.used_regs = used_regs
    return P


def expected_core_ports(g, P):
    """核应有的端口：输出 = need_core_out + 束输出；输入 = 核实际引用到的（由核端口表决定，这里只给候选集）。"""
    outs = collections.OrderedDict()
    for n, (k, x) in P.need_core_out.items():
        if k == 'glue':
            outs[n] = x
        else:
            outs[n] = ('reg', x)
    for bname, (b, fields, total) in P.bundles.items():
        outs[bname] = total
    cand_in = {}
    for d, w, n in g.ports:
        if d == 'input':
            cand_in[n] = w
    for e, (i, p) in g.drv.items():
        cand_in['%s_%s' % (ALIAS[i], strip_io(p))] = g.cports[i][p][1]
    for bname, (b, fields, total) in P.bundles.items():
        for tag, _, _ in b.srcs:
            cand_in['%s_%s' % (bname, tag)] = total
    return outs, cand_in


# =============================================================================
# 核端口核对
# =============================================================================
def check_core(g, P, cports):
    """核端口表与本层要求逐个核对。返回 (输入列表, 输出列表)。"""
    outs, cand_in = expected_core_ports(g, P)
    regw = {}
    for gr, cn in CORE_REGS.items():
        mm = re.fullmatch(r'(\w+)(?:\[(\d+)\])?', cn)
        base, idx = mm.group(1), mm.group(2)
        regw.setdefault(base, []).append((gr, g.regs[gr], None if idx is None else int(idx)))
    for n, (d, w, dim) in cports.items():
        if n in ('clock', 'reset'):
            if d != 'input' or w != 1 or dim is not None:
                fail('核端口 %s 应为 1 位输入' % n)
            continue
        if d == 'input':
            if n not in cand_in:
                fail('核输入 %s 既不是顶层输入、子模块输出线，也不是字段束输入' % n)
            if cand_in[n] != w or dim is not None:
                fail('核输入 %s 宽 %d 与对端宽 %d 不符' % (n, w, cand_in[n]))
            continue
        if n not in outs and n not in regw:
            fail('核输出 %s 不是本层要求的任何口（多余）' % n)
    for n, x in outs.items():
        if n not in cports:
            fail('核缺输出口 %s' % n)
        d, w, dim = cports[n]
        if d != 'output':
            fail('核口 %s 应为输出' % n)
        if isinstance(x, tuple):          # 寄存器口
            for gr, gw, idx in regw[n]:
                if gw != w or (idx is None) != (dim is None) or (idx is not None and idx >= dim):
                    fail('核寄存器口 %s（宽 %d 维 %s）与 golden %s（宽 %d，下标 %s）不符' % (n, w, dim, gr, gw, idx))
        elif w != x or dim is not None:
            fail('核输出 %s 宽 %d 维 %s，应为 %d' % (n, w, dim, x))
    return cports


def core_regs_decl(text, ps):
    """核体里声明的寄存器（logic 声明，含端口）：名字 -> (宽, 维)。"""
    m = re.search(r'^module %s\b(.*?)^endmodule' % CORE, text, re.M | re.S)
    body = m.group(1)
    out = {}
    for mm in re.finditer(r'^\s*(?:input|output)?\s*logic\s+(?:\[([^\]]+):0\]\s+)?([^;=]+?)\s*[;,]?\s*(?://.*)?$',
                          body, re.M):
        w = eval_dim(mm.group(1), ps) + 1 if mm.group(1) else 1
        for item in mm.group(2).split(','):
            im = re.fullmatch(r'\s*(\w+)(?:\s*\[(\w+)\])?\s*', item)
            if not im:
                continue
            n = eval_dim(im.group(2), ps) if im.group(2) else None
            out[im.group(1)] = (w, n)
    return out


# =============================================================================
# 渲染
# =============================================================================
def top_group(name):
    best = None
    for pfx, desc in TOP_GROUPS:
        if name == pfx or name.startswith(pfx + '_') or (pfx.endswith('_') and name.startswith(pfx)):
            if best is None or len(pfx) > len(best[0]):
                best = (pfx, desc)
    if best is None:
        fail('顶层端口 %s 没有归组（补 TOP_GROUPS）' % name)
    return best


def pair(a, b):
    k = tuple(sorted((a, b)))
    return PAIR_DESC.get(k)


def hexc(v, w):
    return "%d'h%X" % (w, v)


def render_layout(P):
    L = []
    A = L.append
    A('// BEGIN GENERATED(mb_layout) —— 由 scripts/gen_memblock.py 从 golden 端口表产出，勿手改')
    A('// 字段束（多个源按字段二选一 / 多选一的那几组宽总线）的总位宽。字段顺序 = 目的端口在 golden 里的顺序，')
    A('// 拼装 / 拆分在 wrapper 里机械完成，核只按整束选择。')
    A('package memblock_top_pkg;')
    for bname, (b, fields, total) in P.bundles.items():
        A('  localparam int %s_W = %d;   // %s（%d 个字段）' % (bname.upper(), total, b.desc, len(fields)))
    A('endpackage')
    A('// END GENERATED')
    return '\n'.join(L) + '\n'


def render_wrapper(g, P, cports):
    L = []
    A = L.append
    A('// BEGIN GENERATED(mb_wrapper) —— 由 scripts/gen_memblock.py 从 golden 端口表与例化表产出，勿手改')
    A('// golden 同名 wrapper：端口与 golden 逐位同名同序；72 个子模块的模块名、实例名与 golden 一致；')
    A('// 子模块之间的线一律命名为"<驱动实例别名>_<端口名去掉 io_>"；本层的胶合逻辑全部在 u_core 里。')
    A('module MemBlock')
    A('  import memblock_top_pkg::*;')
    A('(')
    for k, (d, w, n) in enumerate(g.ports):
        A('  %-6s logic %s%s%s' % (d, ('[%d:0] ' % (w - 1)) if w > 1 else '', n, ',' if k + 1 < len(g.ports) else ''))
    A(');')
    A('')
    # ---- 线声明 ----
    used_nets = set()
    for inst, rows in P.rows.items():
        for p, e, d, k in rows:
            if d == 'input' and k[0] == 'inst':
                used_nets.add(e)
    for n, (d, w, dim) in cports.items():
        if d == 'input':
            used_nets.add(n)
    bundle_src_nets = set()
    for bname, (b, fields, total) in P.bundles.items():
        for n, f, w, off, srcs in fields:
            for tag, gnet, v in srcs:
                if isinstance(v, str) and gnet:
                    bundle_src_nets.add(v)
    used_nets |= bundle_src_nets
    for lhs, (k, rhs) in P.top_assign.items():
        if k == 'child':
            used_nets.add(rhs)
    A('  // ===========================================================================')
    A('  // 子模块输出线（只声明有读者的；直接驱动顶层输出的口不经线）')
    A('  // ===========================================================================')
    by_drv = collections.OrderedDict((i, []) for i in ALIAS)
    for e, (i, p) in g.drv.items():
        n = '%s_%s' % (ALIAS[i], strip_io(p))
        if n in used_nets:
            by_drv[i].append((n, g.cports[i][p][1]))
    for i, nets in by_drv.items():
        if nets:
            A('  // ---- %s（%s）----' % (ALIAS[i], i))
            for n, w in nets:
                A('  logic %s%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', n))
    A('  // ---- 可读核的输出（送进子模块 / 驱动顶层输出）----')
    for n, (d, w, dim) in cports.items():
        if d == 'output' and n not in g.tdir:
            A('  logic %s%s%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', n, (' [%d]' % dim) if dim else ''))
    A('  // ---- 字段束：源包（各字段按 golden 目的端口顺序拼接；源缺的字段填本配置下钉死的常量）----')
    for bname, (b, fields, total) in P.bundles.items():
        for tag, sk, spfx in b.srcs:
            A('  logic [%s_W-1:0] %s_%s;' % (bname.upper(), bname, tag))
    A('')
    A('  // ===========================================================================')
    A('  // 字段束的拼装（纯连线）')
    A('  // ===========================================================================')
    for bname, (b, fields, total) in P.bundles.items():
        A('  // ---- %s：%s ----' % (bname, b.desc))
        for si, (tag, sk, spfx) in enumerate(b.srcs):
            parts = []
            for n, f, w, off, srcs in fields:
                v = srcs[si][2]
                parts.append(v if isinstance(v, str) else hexc(v, w))
            A('  assign %s_%s = {' % (bname, tag))
            for k, x in enumerate(parts):
                A('    %s%s' % (x, ',' if k + 1 < len(parts) else ''))
            A('  };')
    A('')
    A('  // ===========================================================================')
    A('  // 可读核：本层全部胶合逻辑与 %d 个寄存器' % len(g.regs))
    A('  // ===========================================================================')
    A('  %s u_core (' % CORE)
    names = list(cports)
    for k, n in enumerate(names):
        A('    .%s (%s)%s' % (n, n, ',' if k + 1 < len(names) else ''))
    A('  );')
    # ---- 实例 ----
    for title, lst in SECTIONS:
        A('')
        A('  // ===========================================================================')
        A('  // %s' % title)
        A('  // ===========================================================================')
        for inst, alias in lst:
            mod = g.insts[inst][0]
            rows = P.rows[inst]
            groups = collections.OrderedDict()
            for p, e, d, k in rows:
                if k[0] == 'top' and k[1] in ('clock', 'reset'):
                    key, head = ('top', 'clock/reset'), '时钟 / 复位'
                elif k[0] == 'top':
                    tg = top_group(k[1])
                    key, head = ('top', tg[0]), '顶层 %s* —— %s' % (tg[0], tg[1])
                elif k[0] == 'topout':
                    tg = top_group(e)
                    key, head = ('topout', tg[0]), '→ 顶层输出 %s* —— %s' % (tg[0], tg[1])
                elif k[0] == 'inst':
                    desc = pair(alias, k[1])
                    if desc is None:
                        fail('PAIR_DESC 缺 (%s, %s)' % tuple(sorted((alias, k[1]))))
                    key, head = ('inst', k[1]), '← %s：%s' % (k[1], desc)
                elif k[0] == 'core':
                    key, head = ('core',), '← u_core（本层胶合逻辑 / 寄存器）'
                elif k[0] == 'drv':
                    cs = [c for c in collections.OrderedDict.fromkeys(P.consumers.get(e, []))]
                    key = ('drv', tuple(cs))
                    parts = []
                    for c in cs:
                        if c == 'top':
                            parts.append('顶层输出')
                        elif c == 'core':
                            parts.append('u_core')
                        else:
                            desc = pair(alias, c)
                            if desc is None:
                                fail('PAIR_DESC 缺 (%s, %s)' % tuple(sorted((alias, c))))
                            parts.append('%s（%s）' % (c, desc))
                    head = '→ ' + ('；'.join(parts) if parts else '（只被 u_core / 字段束读）')
                elif k[0] == 'const':
                    key, head = ('const',), '常量（golden 在本配置下钉死的输入）'
                else:
                    key, head = ('unused',), '无读者的输出（golden 同样悬空）'
                groups.setdefault(key, (head, []))[1].append((p, e))
            pw = max(len(p) for p, _, _, _ in rows)
            A('  %s %s (' % (mod, inst))
            flat = [(key, head, p, e) for key, (head, items) in groups.items() for p, e in items]
            prev = None
            for idx, (key, head, p, e) in enumerate(flat):
                if key != prev:
                    A('    // ---- %s ----' % head)
                    prev = key
                A('    .%-*s (%s)%s' % (pw, p, e, ',' if idx + 1 < len(flat) else ''))
            A('  );')
    A('')
    A('  // ===========================================================================')
    A('  // 顶层输出：直通顶层输入 / 子模块输出、核里寄存器、字段束（核里同名输出口直接驱动的不在此列）')
    A('  // ===========================================================================')
    for lhs, (k, rhs) in P.top_assign.items():
        if k == 'core':
            continue
        A('  assign %s = %s;' % (lhs, rhs))
    A('')
    A('endmodule')
    A('// END GENERATED')
    return '\n'.join(L) + '\n'


def render_pins(g, text, ps):
    c = core_regs_decl(text, ps)
    pairs = []
    for gr, ir in CORE_REGS.items():
        w = g.regs[gr]
        mm = re.fullmatch(r'(\w+)(?:\[(\d+)\])?', ir)
        base, idx = mm.group(1), mm.group(2)
        if base not in c:
            fail('u_core 里找不到寄存器 %s' % base)
        cw, cn = c[base]
        if cw != w or (idx is None) != (cn is None) or (idx is not None and int(idx) >= cn):
            fail('寄存器 %s(宽 %d) 与 u_core.%s(宽 %d, 维 %s) 不符' % (gr, w, ir, cw, cn))
        ipre = 'u_core/%s_reg%s' % (base, '' if idx is None else '[%s]' % idx)
        for b in range(w):
            rb = '' if w == 1 else '[%d]' % b
            pairs.append(('r:/WORK/%s/%s_reg%s' % (TOP, gr, rb), 'i:/WORK/%s/%s%s' % (TOP, ipre, rb)))
    L = []
    A = L.append
    A('# MemBlock FM 「匹配前」钉点 —— 自动生成：scripts/gen_memblock.py（勿手改；规则与理由见生成器文件头）')
    A('# 只 set_user_match 消名差：不约束 ref、不改 appvar、不加黑盒。逐条数返回值，拒一条或总数不等于字面常数即 error。')
    A('# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。进 fm.log 的输出一律 ASCII。')
    A('if {$top ne "MemBlock"} { error "MEMBLOCK_PRE_PIN_UNKNOWN_TOP=$top" }')
    A('# ---- 本层胶合寄存器（golden 本层 %d 个寄存器 / %d 位 -> u_core）----' % (len(g.regs), len(pairs)))
    A('set ::MB_CORE_EXPECT %d' % len(pairs))
    A('set ::MB_CORE_OK 0')
    A('set ::MB_CORE_BAD 0')
    A('proc mb_core_pin {r i} {')
    A('  if {[set_user_match $r $i]} { incr ::MB_CORE_OK } else {')
    A('    incr ::MB_CORE_BAD')
    A('    if {$::MB_CORE_BAD <= 10} { puts "MB_CORE_PIN_FAIL: $r <-> $i" }')
    A('  }')
    A('}')
    A('puts "MB_CORE_PIN_BEGIN expect=$::MB_CORE_EXPECT"')
    for r, i in pairs:
        A('mb_core_pin {%s} {%s}' % (r, i))
    A('puts "MB_CORE_PIN_END ok=$::MB_CORE_OK bad=$::MB_CORE_BAD expect=$::MB_CORE_EXPECT"')
    A('if {$::MB_CORE_BAD != 0 || $::MB_CORE_OK != $::MB_CORE_EXPECT} {')
    A('  error "MB_CORE_PIN: ok=$::MB_CORE_OK bad=$::MB_CORE_BAD expect=$::MB_CORE_EXPECT"')
    A('}')
    return '\n'.join(L) + '\n'


def splice(text, tag, gen):
    b = '// BEGIN GENERATED(%s)' % tag
    if b in text:
        i = text.index(b)
        j = text.index('// END GENERATED', i) + len('// END GENERATED') + 1
        return text[:i] + gen + text[j:]
    fail('%s 里没有 %s 标记' % (OUT.name, b))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--print-core-ports', action='store_true')
    ap.add_argument('--loose', action='store_true', help='开发用：不做核端口核对')
    a = ap.parse_args()
    g = Golden()
    text = OUT.read_text() if OUT.exists() else ''
    P = analyse(g, text)
    if a.print_core_ports:
        outs, cand = expected_core_ports(g, P)
        for n, x in outs.items():
            print('OUT\t%s\t%s\t%s' % (n, x, ','.join(collections.OrderedDict.fromkeys(P.consumers.get(n, [])))))
        for bname, (b, fields, total) in P.bundles.items():
            print('BUNDLE\t%s\t%d\t%d fields' % (bname, total, len(fields)))
        return 0
    layout = render_layout(P)
    text1 = splice(text, 'mb_layout', layout)
    ps = parse_params(text1)
    cports = parse_core(text1, ps)
    if cports is None:
        fail('rtl/memblock/MemBlock.sv 里找不到手写核 %s' % CORE)
    check_core(g, P, cports)
    text2 = splice(text1, 'mb_wrapper', render_wrapper(g, P, cports))
    pins = render_pins(g, text2, ps)
    outs = [(OUT, text, text2), (PINS, PINS.read_text() if PINS.exists() else '', pins)]
    rc = 0
    for path, old, new in outs:
        if a.check:
            if new != old:
                print('DRIFT: %s 与生成器输出不一致' % path.relative_to(REPO))
                rc = 1
            else:
                print('OK: %s' % path.relative_to(REPO))
        elif new != old:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(new)
            print('wrote %s' % path.relative_to(REPO))
        else:
            print('unchanged %s' % path.relative_to(REPO))
    return rc


if __name__ == '__main__':
    sys.exit(main())
