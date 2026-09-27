#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_ctrlblock_pins.py —— CtrlBlock 的 FM 钉点生成器（glue 寄存器全族双射 + Rob 钉点重定位）。

产出：
  verif/ut/CtrlBlock/fm_pins_pre.tcl   匹配前钉点：golden CtrlBlock 的 2022 个 glue 寄存器（25852 位）
                                       逐位 set_user_match 到 u_core 里的对应寄存器位。golden 是 firtool
                                       展平名（delayedNotFlushedWriteBack_delayed_bits_r_7_pdest_reg[3]），
                                       可读核是 generate 作用域 + packed struct（g_wb[7].g_pdest.q_reg[3]、
                                       s2_s4_bits_reg[<struct 位偏移>]），名字与层次都不同，签名匹配在
                                       hold-clear 常数寄存器上会被 merge/常数池搅乱（上一轮 gate3 实测
                                       compare_ref=13 的根因），所以整族在首次 match 前钉死。
  verif/ut/CtrlBlock/fm_pins.tcl       匹配后钉点：verif/ut/Rob/fm_pins.tcl 的 168720 条 Rob 寄存器钉点
                                       原样搬到 CtrlBlock 层次（r:/WORK/CtrlBlock/rob/... ↔
                                       i:/WORK/CtrlBlock/rob/u_core/...），Rob 在本目标里两侧白盒。

★fail-closed★：
  · 每个 golden 寄存器必须命中恰好一条映射规则，映射到的 impl 寄存器必须在可读核里存在
    （按 rtl/backend/CtrlBlock.sv 现场解析：generate 块名、寄存器名、struct 位偏移都核对）；
  · 位数守恒：钉点位数 == golden 寄存器总位数；
  · 生成的 tcl 在运行时计数并 error 中止（scripts/test_fm_pins_wellformed.py 的 P2/P3）；
  · --check：重生成比对，漂移即非零。

用法：python3 scripts/gen_ctrlblock_pins.py [--check]
"""
import argparse
import collections
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gen_ctrlblock as GC   # noqa: E402

REPO = HERE.parent
UT = REPO / 'verif' / 'ut' / 'CtrlBlock'
ROB_PINS = REPO / 'verif' / 'ut' / 'Rob' / 'fm_pins.tcl'


class Layout(object):
    """packed struct 的位偏移（成员按声明序从 MSB 排到 LSB）。"""
    def __init__(self, ty):
        self.ty = ty

    def offset(self, et, path):
        """path: 形如 '.redirect.cfiUpdate.ssp' / '.data[3]' / '.exceptionVec[2]' / '.afhob[5][1]'。
        返回 (lsb_offset, width)。"""
        if path == '':
            return 0, self.ty.struct_width(et) if et != 'logic' else 1
        m = re.match(r'^\.(\w+)((?:\[\d+\])*)(.*)$', path)
        if not m:
            raise ValueError(path)
        mn, idxs, rest = m.group(1), m.group(2), m.group(3)
        members = self.ty.structs[et]
        below = 0
        found = None
        for name, met, mdl in reversed(members):
            if name == mn:
                found = (met, mdl)
                break
            below += self.ty.width(met, mdl)
        if found is None:
            raise KeyError('%s.%s' % (et, mn))
        met, mdl = found
        ks = [int(x) for x in re.findall(r'\d+', idxs)]
        off = below
        dims = list(mdl)
        for k in ks:
            if not dims:
                raise ValueError('too many indices %s' % path)
            elem_w = self.ty.width(met, dims[1:])
            off += k * elem_w
            dims = dims[1:]
        if met == 'logic':
            if rest:
                raise ValueError(path)
            w = 1
            for d in dims:
                w *= d
            return off, w
        if dims:
            if rest:
                raise ValueError('array of struct needs full index: %s' % path)
            return off, self.ty.width(met, dims)
        o2, w2 = self.offset(met, rest)
        return off + o2, w2


def build_pairs(g, ty, table):
    """golden 寄存器 → [(golden_point, impl_point)]"""
    lay = Layout(ty)
    pairs = []
    lane_of_timer = {}
    lane_of_valid = {}
    for (inst, pin), e in g.pins.items():
        if inst != 'rob':
            continue
        m = re.match(r'io_(?:exuW|w)riteback_(\d+)_bits_debugInfo_writebackTime$', pin)
        if m:
            lane_of_timer[e] = int(m.group(1))
        m = re.match(r'io_writeback_(\d+)_valid$', pin)
        if m:
            lane_of_valid[e] = int(m.group(1))
    perf_pos = dict((n, k) for k, n in enumerate(sorted(g.perf_src)))

    def struct_path(field):
        """golden 字段名（如 redirect_bits_cfiUpdate_ssp）→ ('.redirect.cfiUpdate.ssp')"""
        return GC.canon(field)

    def reg_name(ibase):
        """impl 寄存器基名 → Formality 的 cell 名：`x` → `x_reg`；非打包数组元素 `x[3]` → `x_reg[3]`。"""
        um = re.match(r'^(.*?)\[(\d+)\]$', ibase)
        if um:
            return '%s_reg[%s]' % (um.group(1), um.group(2))
        return ibase + '_reg'

    def emit(gname, gw, ibase, ioff, iw=None):
        """golden 寄存器 gname（gw 位）↔ impl 的 logic 向量/标量寄存器 ibase 从位 ioff 起
        （Formality 对 logic 向量点名 x_reg[b]，1 位标量点名 x_reg 无下标；packed 二维 x_reg[k][b]）。"""
        if iw is not None and iw != gw:
            GC.die('%s: golden %d 位 vs impl 目标 %d 位' % (gname, gw, iw))
        base = reg_name(ibase)
        # 1 位 golden 寄存器 ↔ impl 1 位标量：Formality 点名无 [0]；只有 PACKED_VEC 里的向量按位下标
        scalar = gw == 1 and ibase.split('.')[-1].split('[')[0] not in PACKED_VEC
        for b in range(gw):
            gp = gname + ('_reg[%d]' % b if gw > 1 else '_reg')
            ip = base if scalar else '%s[%d]' % (base, ioff + b)
            pairs.append((gp, ip))

    def field_in(struct_t, field, gname, gw, ibase):
        """golden 寄存器 ↔ impl 的 packed struct 寄存器成员。Formality 对 struct 寄存器按成员名点名：
        s2_s4_bits_reg\\[cfiUpdate]\\[afhob][5][1]（成员 \\[name]，数组下标 [k]，1 位叶子无位下标）。"""
        r = ty.resolve(struct_t, [], struct_path(field))
        if r is None:
            GC.die('%s：字段 %s 在 %s 里解析不到' % (gname, field, struct_t))
        off, w = lay.offset(struct_t, r[0])
        if w != gw:
            GC.die('%s: golden %d 位 vs impl 成员 %s %d 位' % (gname, gw, r[0], w))
        mp = re.sub(r'\.(\w+)', r'\\[\1]', r[0])
        base = reg_name(ibase) + mp
        for b in range(gw):
            gp = gname + ('_reg[%d]' % b if gw > 1 else '_reg')
            ip = base if gw == 1 else '%s[%d]' % (base, b)
            pairs.append((gp, ip))

    # 写回口字段 → generate 块里的寄存器
    WB_SIMPLE = {
        'robIdx_value': ('g_base', 'robidx_value_q'), 'debugInfo_enqRsTime': ('g_base', 'enqRsTime_q'),
        'debugInfo_selectTime': ('g_base', 'selectTime_q'), 'debugInfo_issueTime': ('g_base', 'issueTime_q'),
        'robIdx_flag': ('g_flag', 'q'), 'pdest': ('g_pdest', 'q'), 'intWen': ('g_intwen', 'q'),
        'fpWen': ('g_fpwen', 'q'), 'vecWen': ('g_vecwen', 'vec_q'), 'v0Wen': ('g_vecwen', 'v0_q'),
        'vlWen': ('g_vlwen', 'q'), 'vxsat': ('g_vxsat', 'q'), 'fflags': ('g_fflags', 'fflags_q'),
        'wflags': ('g_fflags', 'wflags_q'), 'redirect_valid': ('g_rlite', 'valid_q'),
        'redirect_bits_cfiUpdate_taken': ('g_rlite.g_tm', 'taken_q'), 'redirect_bits_cfiUpdate_isMisPred': ('g_rlite.g_tm', 'mispred_q'),
        'flushPipe': ('g_flushpipe', 'q'), 'satpFlushPipe': ('g_satpfp', 'q'), 'replay': ('g_replay', 'q'),
        'trigger': ('g_trigger', 'q'), 'debug_isPerfCnt': ('g_perfcnt', 'q'),
        'debug_isMMIO': ('g_dbgmem', 'mmio_q'), 'debug_isNCIO': ('g_dbgmem', 'ncio_q'),
        'debug_paddr': ('g_dbgmem', 'paddr_q'), 'debug_vaddr': ('g_dbgmem', 'vaddr_q'),
        'debugInfo_eliminatedMove': ('g_dbglong', 'eliminatedMove_q'), 'debugInfo_renameTime': ('g_dbglong', 'renameTime_q'),
        'debugInfo_dispatchTime': ('g_dbglong', 'dispatchTime_q'), 'debugInfo_runahead_checkpoint_id': ('g_dbglong', 'runahead_q'),
        'debugInfo_tlbFirstReqTime': ('g_dbglong', 'tlbFirstReqTime_q'), 'debugInfo_tlbRespTime': ('g_dbglong', 'tlbRespTime_q'),
    }
    for gname, gw in g.regs.items():
        m = re.match(r'delayedNotFlushedWriteBack_delayed_bits_r(?:_(\d+))?_(.+)$', gname)
        if m:
            lane = int(m.group(1)) if m.group(1) else 0
            f = m.group(2)
            base = 'g_wb[%d].' % lane
            md = re.match(r'data_(\d)$', f)
            me = re.match(r'exceptionVec_(\d+)$', f)
            if f == 'robIdx_value' and not table[lane]['has_base']:
                emit(gname, gw, base + 'g_std.robidx_value_q', 0)
            elif f in WB_SIMPLE and not (table[lane]['has_redir_full'] and f.startswith('redirect_bits_cfiUpdate_')):
                blk, reg = WB_SIMPLE[f]
                emit(gname, gw, base + blk + '.' + reg, 0)
            elif md:
                emit(gname, gw, base + 'g_data[%s].g_y.q' % md.group(1), 0)
            elif me:
                emit(gname, gw, base + 'g_exc[%s].g_y.q' % me.group(1), 0)
            elif f.startswith('redirect_bits_'):
                field_in('redirect_t', f[len('redirect_bits_'):], gname, gw, base + 'g_rfull.q')
            elif f.startswith('lqIdx_'):
                field_in('lqptr_t', f[len('lqIdx_'):], gname, gw, base + 'g_lqidx.q')
            elif f.startswith('sqIdx_'):
                field_in('sqptr_t', f[len('sqIdx_'):], gname, gw, base + 'g_sqidx.q')
            elif f.startswith('predecodeInfo_'):
                field_in('predecode_t', f[len('predecodeInfo_'):], gname, gw, base + 'g_pd.q')
            elif f.startswith('debug_seqNum_'):
                field_in('seq_num_t', f[len('debug_seqNum_'):], gname, gw, base + 'g_dbglong.seqnum_q')
            elif f.startswith('vls_'):
                field_in('vls_info_t', f[len('vls_'):], gname, gw, base + 'g_vls.q')
            else:
                GC.die('写回字段 %s 没有钉点规则' % gname)
            continue
        m = re.match(r'delayedNotFlushedWriteBack_delayed_bits_debugInfo_writebackTime_c(?:_\d+)?$', gname)
        if m:
            emit(gname, gw, 'g_wb[%d].g_base.gtimer_q' % lane_of_timer[gname], 0)
            continue
        m = re.match(r'delayedNotFlushedWriteBack_delayed_valid_last_REG(?:_\d+)?$', gname)
        if m:
            emit(gname, gw, 'g_wb[%d].g_valid.valid_q' % lane_of_valid[gname], 0)
            continue
        m = re.match(r'delayedWriteBack_(\d+)_valid_last_REG$', gname)
        if m:
            emit(gname, gw, 'g_wb[%s].exu_valid_q' % m.group(1), 0)
            continue
        m = re.match(r'delayedNotFlushedWriteBackNums_delayed_bits_r(?:_(\d+))?$', gname)
        if m:
            emit(gname, gw, 'g_wb[%d].g_nums.nums_q' % (int(m.group(1)) if m.group(1) else 0), 0)
            continue
        # ---- 重定向流水 ----
        if gname == 's1_robFlushRedirect_valid_last_REG':
            emit(gname, gw, 's1_rob_flush_valid', 0); continue
        m = re.match(r's1_robFlushRedirect_bits_r_(.+)$', gname)
        if m:
            field_in('rob_flush_t', m.group(1), gname, gw, 's1_rob_flush_bits'); continue
        if gname == 's1_robFlushPc_r':
            emit(gname, gw, 's1_rob_flush_pc_offset', 0); continue
        if gname == 's2_s4_pendingRedirectValid':
            emit(gname, gw, 'pending_redirect_q', 0); continue
        if gname == 'last_REG':
            emit(gname, gw, 'to_ftq_redirect_valid_q', 0); continue
        if gname == 's2_s4_redirect_next_valid_last_REG':
            emit(gname, gw, 's2_s4_valid', 0); continue
        m = re.match(r's2_s4_redirect_next_bits_r_(.+)$', gname)
        if m:
            field_in('redirect_t', m.group(1), gname, gw, 's2_s4_bits'); continue
        if gname == 's3_s5_redirect_next_valid_last_REG':
            emit(gname, gw, 's3_s5_valid', 0); continue
        m = re.match(r's3_s5_redirect_next_bits_r_robIdx_(flag|value)$', gname)
        if m:
            field_in('robptr_t', m.group(1), gname, gw, 's3_s5_robIdx'); continue
        if gname == 's3_s5_redirect_next_bits_r_level':
            emit(gname, gw, 's3_s5_level', 0); continue
        # ---- load 违例 ----
        if gname == 'loadReplay_valid_last_REG':
            emit(gname, gw, 'load_replay_valid_q', 0); continue
        m = re.match(r'loadReplay_bits_r_(.+)$', gname)
        if m:
            field_in('mem_violation_t', m.group(1), gname, gw, 'load_replay_bits_q'); continue
        if gname == 'redirectGen_io_memPredPcRead_data_r':
            emit(gname, gw, 'mempred_offset_q', 0); continue
        if gname == 'loadRedirectPcFtqOffset':
            emit(gname, gw, 'load_redirect_pc_offset_q', 0); continue
        # ---- pcMem / newest ----
        if gname == 'newestEn':
            emit(gname, gw, 'newest_en_q', 0); continue
        if gname == 'newestTarget':
            emit(gname, gw, 'newest_target_q', 0); continue
        if gname == 'newestPtr_value':
            emit(gname, gw, 'newest_ptr_q', 0); continue
        if gname == 'newestTargetNext':
            emit(gname, gw, 'newest_target_next_q', 0); continue
        m = re.match(r'needNewest(?:_(\d+))?$', gname)
        if m:
            emit(gname, gw, 'need_newest_q', int(m.group(1)) if m.group(1) else 0); continue
        if gname == 'pcMem_io_wen_0_last_REG':
            emit(gname, gw, 'pcmem_wen_q', 0); continue
        if gname == 'pcMem_io_waddr_0_r':
            emit(gname, gw, 'pcmem_waddr_q', 0); continue
        if gname == 'pcMem_io_wdata_0_r_startAddr':
            emit(gname, gw, 'pcmem_wdata_q', 0); continue
        # ---- 最老 exu 重定向 ----
        if gname == 'redirectGen_io_oldestExuRedirect_valid_REG':
            emit(gname, gw, 'exu_oldest_valid_q', 0); continue
        m = re.match(r'redirectGen_io_oldestExuRedirect_bits_REG_(.+)$', gname)
        if m:
            field_in('exu_redirect_t', m.group(1), gname, gw, 'exu_oldest_bits_q'); continue
        if gname == 'redirectGen_io_oldestExuRedirectIsCSR_REG':
            emit(gname, gw, 'exu_oldest_is_csr_q', 0); continue
        m = re.match(r'redirectGen_io_instrAddrTransType_REG_(.+)$', gname)
        if m:
            field_in('addr_trans_type_t', m.group(1), gname, gw, 'instr_addr_trans_type_q'); continue
        m = re.match(r'redirectGen_io_oldestExuOutPredecode_REG_(.+)$', gname)
        if m:
            field_in('predecode_t', m.group(1), gname, gw, 'exu_oldest_pd_q'); continue
        if gname == 'io_frontend_toFtq_ftqIdxAhead_0_valid_REG':
            emit(gname, gw, 'ftq_ahead0_valid_q', 0); continue
        if gname == 'io_frontend_toFtq_ftqIdxAhead_0_bits_r_value':
            emit(gname, gw, 'ftq_ahead0_value_q', 0); continue
        # ---- 前端 flush ----
        if gname == 's6_flushFromRobValid_last_REG':
            emit(gname, gw, 's6_flush_valid_q', 0); continue
        m = re.match(r'frontendFlushBits_ftqIdx_(flag|value)$', gname)
        if m:
            field_in('ftqptr_t', m.group(1), gname, gw, 'fe_flush_ftqIdx_q'); continue
        if gname == 'frontendFlushBits_ftqOffset':
            emit(gname, gw, 'fe_flush_ftqOffset_q', 0); continue
        if gname == 'frontendFlushBits_satpFlush':
            emit(gname, gw, 'fe_flush_satpFlush_q', 0); continue
        if gname == 's2_robFlushPc':
            emit(gname, gw, 's2_rob_flush_pc_q', 0); continue
        if gname == 'io_frontend_toFtq_redirect_bits_cfiUpdate_target_r':
            emit(gname, gw, 'fe_flush_target_q', 0); continue
        m = re.match(r'io_frontend_toFtq_redirect_bits_cfiUpdate_backendI(AF|PF|GPF)_r$', gname)
        if m:
            emit(gname, gw, 'fe_flush_i%s_q' % m.group(1).lower(), 0); continue
        m = re.match(r'io_frontend_toFtq_rob_commits_(\d)_valid_last_REG$', gname)
        if m:
            emit(gname, gw, 'g_commit[%s].valid_q' % m.group(1), 0); continue
        m = re.match(r'io_frontend_toFtq_rob_commits_(\d)_bits_r_(.+)$', gname)
        if m:
            field_in('commit_to_ftq_t', m.group(2), gname, gw, 'g_commit[%s].bits_q' % m.group(1)); continue
        # ---- 译码缓冲 ----
        m = re.match(r'decodeBufValid_(\d)$', gname)
        if m:
            emit(gname, gw, 'dbuf_valid_q', int(m.group(1))); continue
        m = re.match(r'decodeBufBits_(\d)_(.+)$', gname)
        if m:
            field_in('static_inst_t', m.group(2), gname, gw, 'dbuf_bits_q[%s]' % m.group(1)); continue
        m = re.match(r'decode_io_csrCtrl_REG_(.+)$', gname)
        if m:
            field_in('csr_ctrl_t', m.group(1), gname, gw, 'csr_ctrl_q'); continue
        # ---- 快照 ----
        m = re.match(r'flushVecNext_last_REG(?:_(\d))?$', gname)
        if m:
            emit(gname, gw, 'flush_vec_next_q', int(m.group(1)) if m.group(1) else 0); continue
        # ---- mdp / singleStep ----
        m = re.match(r'mdpFlodPcVecVld_(\d)_last_REG$', gname)
        if m:
            emit(gname, gw, 'g_mdp[%s].fire_q' % m.group(1), 0); continue
        if gname == 'rename_io_singleStep_last_REG':
            emit(gname, gw, 'rename_single_step_q', 0); continue
        if gname == 'dispatch_io_singleStep_last_REG':
            emit(gname, gw, 'dispatch_single_step_q', 0); continue
        # ---- Rob 入队 ----
        m = re.match(r'enqRob_req_(\d)_valid_REG$', gname)
        if m:
            emit(gname, gw, 'enq_valid_q[%s]' % m.group(1), 0); continue
        m = re.match(r'enqRob_req_(\d)_bits_r_(.+)$', gname)
        if m:
            field_in('dyn_inst_t', m.group(2), gname, gw, 'enq_bits_q[%s]' % m.group(1)); continue
        # ---- 杂项 ----
        if gname == 'io_robio_csr_perfinfo_retiredInstr_REG':
            emit(gname, gw, 'retired_instr_q', 0); continue
        m = re.match(r'(v0|vec)Valid(?:_(\d))?$', gname)
        if m:
            emit(gname, gw, 'g_old_pdest[%d].%s_valid_q' % (int(m.group(2)) if m.group(2) else 0, m.group(1)), 0); continue
        m = re.match(r'io_toVecExcpMod_ratOldPest_(v0|vec)OldVdPdest_(\d)_valid_REG$', gname)
        if m:
            emit(gname, gw, 'g_old_pdest[%s].%s_out_valid_q' % (m.group(2), m.group(1)), 0); continue
        m = re.match(r'io_toVecExcpMod_ratOldPest_(v0|vec)OldVdPdest_(\d)_bits_r$', gname)
        if m:
            emit(gname, gw, 'g_old_pdest[%s].%s_bits_q' % (m.group(2), m.group(1)), 0); continue
        m = re.match(r'io_perf_(\d+)_value_REG(_1)?$', gname)
        if m:
            emit(gname, gw, ('perf_q2' if m.group(2) else 'perf_q1') + '[%d]' % perf_pos[int(m.group(1))], 0); continue
        m = re.match(r'io_error_0_REG(_1)?$', gname)
        if m:
            emit(gname, gw, 'error_q2' if m.group(1) else 'error_q1', 0); continue
        GC.die('golden 寄存器 %s 没有钉点规则' % gname)
    return pairs


def impl_reg_widths(text):
    """从可读核文本里收集寄存器声明的位宽（含 generate 作用域名），用来核对 impl 目标存在且够宽。
    只认 always_ff 里被赋值的变量。"""
    core = text[text.index('module xs_CtrlBlock_core'):text.index('endmodule', text.index('module xs_CtrlBlock_core'))]
    return core


def render_pre(pairs, total_bits):
    """按 impl 目标分组：同一 impl 寄存器的连续位段合成循环，减少行数。"""
    L = ['# fm_pins_pre.tcl for CtrlBlock -- GENERATED by scripts/gen_ctrlblock_pins.py. Do not hand-edit.',
         '# Pre-match bijection: every golden glue register bit (%d bits) <-> the readable core register bit.' % total_bits,
         '# All puts are ASCII (fm.log is not UTF-8).',
         'set _pinned 0',
         'set _want 0',
         'puts "CB_PIN_BEGIN CtrlBlock expect=%d"' % total_bits,
         'proc _cbpin {r i} { upvar _pinned p _want w; incr w; if {[set_user_match $r $i]} {incr p} }']
    for gp, ip in pairs:
        # Tcl 裸字里：数组下标 [k] 写成 \[k\]；struct 成员分隔符 \[name] 是对象名的一部分，写成 \\\[name\]
        esc = lambda x: x.replace('\\[', '\x00').replace('[', '\\[').replace(']', '\\]').replace('\x00', '\\\\\\[')
        L.append('_cbpin r:/WORK/CtrlBlock/%s i:/WORK/CtrlBlock/u_core/%s' % (esc(gp), esc(ip)))
    L.append('puts "CB_PIN_END CtrlBlock n=$_pinned miss=[expr {$_want - $_pinned}] expect=%d"' % total_bits)
    L.append('if {$_pinned != $_want} { error "CB_PINS_FAIL not every pin was accepted" }')
    L.append('if {$_want != %d} { error "CB_PINS_FAIL expected %d pins, built $_want" }' % (total_bits, total_bits))
    return '\n'.join(L) + '\n'


# impl 侧声明为 1 位标量 logic 的寄存器名：Formality 的点名没有 [0]
SCALAR_IMPL = set()
# golden 1 位寄存器落在 impl 打包向量某一位上的那几个向量（要带位下标）
PACKED_VEC = {'dbuf_valid_q', 'flush_vec_next_q', 'need_newest_q', 'nums_q'}   # nums_q 有 1 位宽的口（logic [0:0]），照样带 [0]


def scan_scalar_impl(text):
    """可读核里所有 1 位标量 `logic a, b;` 声明的名字（逐条语句拆，含 generate 块里的）。
    同一名字若在别处声明成向量则剔除（各块里都叫 q 的寄存器有标量也有向量），用时按基名判。"""
    core = text[text.index('module xs_CtrlBlock_core'):]
    core = core[:core.index('endmodule')]
    core = re.sub(r'//[^\n]*', '', core)
    scal, vec = set(), set()
    for st in core.split(';'):
        m = re.match(r'\s*logic\s+(.*)$', st.strip(), re.S)
        if not m:
            continue
        decl = m.group(1)
        if '[' in decl:
            for n in re.findall(r'\]\s*(\w+)', decl) + re.findall(r'(\w+)\s*\[', decl):
                vec.add(n)
        else:
            for n in decl.split(','):
                scal.add(n.strip())
    return scal - vec


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    g = GC.Golden(GC.GOLDEN.read_text())
    rtl = GC.RTL.read_text()
    ty = GC.Types(rtl)
    table, exu_lanes, csr_lanes = GC.lane_table(g)
    global SCALAR_IMPL
    SCALAR_IMPL = scan_scalar_impl(rtl)
    pairs = build_pairs(g, ty, table)
    total = sum(g.regs.values())
    if len(pairs) != total:
        GC.die('钉点位数 %d != golden 寄存器位数 %d' % (len(pairs), total))
    # 双射：impl 位不许被两个 golden 位占用
    seen = {}
    for gp, ip in pairs:
        if ip in seen:
            GC.die('impl 位 %s 被 %s 与 %s 同时钉住' % (ip, seen[ip], gp))
        seen[ip] = gp
    pre = render_pre(pairs, total)
    # Rob 钉点重定位
    rob = ROB_PINS.read_text()
    n_r = rob.count('r:/WORK/Rob/')
    n_i = rob.count('i:/WORK/Rob/u_core/')
    if n_r != n_i or n_r == 0 or rob.count('WORK/Rob') != n_r + n_i:
        GC.die('verif/ut/Rob/fm_pins.tcl 的路径形态变了（r=%d i=%d）' % (n_r, n_i))
    rob2 = rob.replace('r:/WORK/Rob/', 'r:/WORK/CtrlBlock/rob/').replace('i:/WORK/Rob/u_core/', 'i:/WORK/CtrlBlock/rob/u_core/')
    post = ('# fm_pins.tcl for CtrlBlock -- GENERATED by scripts/gen_ctrlblock_pins.py. Do not hand-edit.\n'
            '# Rob is elaborated white-box on both sides inside CtrlBlock, so the Rob register bijection\n'
            '# (verif/ut/Rob/fm_pins.tcl, %d set_user_match sites) is re-based one hierarchy level down:\n'
            '#   r:/WORK/Rob/...  -> r:/WORK/CtrlBlock/rob/...    i:/WORK/Rob/u_core/... -> i:/WORK/CtrlBlock/rob/u_core/...\n'
            '# Everything else in that file (counting, the 448-bit debug_otherPdest exclusion, the fail-closed error) is kept verbatim.\n' % n_r) + rob2
    outs = {UT / 'fm_pins_pre.tcl': pre, UT / 'fm_pins.tcl': post}
    rc = 0
    for p, txt in outs.items():
        if a.check:
            if not p.exists() or p.read_text() != txt:
                print('gen_ctrlblock_pins --check: %s 漂移' % p.name)
                rc = 1
        elif not p.exists() or p.read_text() != txt:
            p.write_text(txt)
            print('gen_ctrlblock_pins: 写入 %s' % p)
    print('gen_ctrlblock_pins: glue 钉点 %d 位 / %d 个寄存器；Rob 钉点 %d 处重定位' % (total, len(g.regs), n_r))
    if a.check and rc == 0:
        print('gen_ctrlblock_pins --check: OK')
    return rc


if __name__ == '__main__':
    sys.exit(main())
