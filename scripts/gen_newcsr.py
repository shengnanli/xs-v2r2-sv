#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_newcsr.py —— rtl/backend/NewCSR.sv 与其父 rtl/backend/CSR.sv 的 GENERATED 区生成器
（只生成"连线"，不生成逻辑）。

NewCSR（golden 15945 行）= 410 个子模块实例 + 约 4000 行父级胶合逻辑。胶合逻辑（地址译码、
写使能、读数据 Mux、特权态机、trap/xRET 事件、状态机、各类状态输出）在 NewCSR.sv 里**手写**；
本脚本只产出四段纯连线，全部从 golden 端口表 / 实例连线机械得出：

  newcsr-ports      模块端口表（golden 逐行、方向/位宽/顺序逐位对齐）；
  newcsr-childnets  410 个实例的输出线声明，统一命名 <实例名>_<端口名>；
  newcsr-regout     277 个 CSR 的 regOut 打包视图 regout_<csr>（每个 CSR 的字段按 golden
                    io_out_bits_regOut 里的位序拼回 64 位；只含子模块 regOut 字段与常数位）；
  newcsr-insts      410 个实例（实例名同 golden），每个端口的连接：
                      * 子模块输出   -> <实例名>_<端口名>（或 golden 直连的顶层输出口）；
                      * 不含运算符的 golden 表达式（顶层口 / 子模块输出 / 常数 / 位选 / 拼接）
                        原样改名照抄 —— 这是连线；
                      * 其中出现的父级胶合信号名经 ID_MAP 换成手写区里的名字；
                      * 含运算符的连接（写使能、事件 valid、触发器链 ...）一律经 CONN_RULES
                        换成手写区里定义的一根线 —— 逻辑本身在手写区，不在这里。

fail-closed：
  * golden 胶合信号名、含运算符的连接，任何一个没有映射规则 -> 退出（不猜）；
  * ID_MAP / CONN_RULES 里有没被用到的条目 -> 退出（防"映射写了但名字对不上"）；
  * regOut 打包视图的每一位必须是 (选择条件 & 子模块输出位) 或 (选择条件 & 常数 1)，
    每个选择条件必须能对应到唯一一个 CSR 地址名 -> 否则退出。

CSR（功能单元外壳，5 个子模块实例）同一套做法，只有 csr-ports / csr-childnets / csr-insts 三段，
映射表是 CSR_ID_MAP / csr_conn_rule（见 TARGETS）。

用法: python3 scripts/gen_newcsr.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（gate_all.sh 自动扫描进闸）。
"""
import argparse
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))


def die(msg):
    print('gen_newcsr: ERROR: ' + msg, file=sys.stderr)
    sys.exit(2)


# ---------------------------------------------------------------------------
# 极小的 Verilog 表达式解析器（只覆盖 firtool 输出用到的写法）
# ---------------------------------------------------------------------------
TOK = re.compile(r"\s*(?:(\d+'[hbdo][0-9a-fA-F_]+)|(\d+)|([A-Za-z_][A-Za-z_0-9$]*)|"
                 r"(<=|>=|==|!=|&&|\|\||<<|>>>|>>|[~!&|^+\-*/<>?:(){}\[\],]))")
BIN = {'||': 1, '&&': 2, '|': 3, '^': 4, '&': 5, '==': 6, '!=': 6, '<': 7, '>': 7, '<=': 7,
       '>=': 7, '<<': 8, '>>': 8, '>>>': 8, '+': 9, '-': 9, '*': 10, '/': 10}


def tokenize(s):
    out, i = [], 0
    s = re.sub(r"(\d+)'\(", r"__CAST\1(", s.strip())
    while i < len(s):
        m = TOK.match(s, i)
        if not m or m.end() == i:
            die('表达式无法分词: %r' % s[i:i + 40])
        i = m.end()
        if m.group(1):
            out.append(('const', m.group(1)))
        elif m.group(2):
            out.append(('int', m.group(2)))
        elif m.group(3):
            out.append(('id', m.group(3)))
        else:
            out.append(('op', m.group(4)))
        while i < len(s) and s[i].isspace():
            i += 1
    return out


class _P:
    def __init__(self, toks):
        self.t, self.i = toks, 0

    def peek(self):
        return self.t[self.i] if self.i < len(self.t) else (None, None)

    def nxt(self):
        self.i += 1
        return self.t[self.i - 1]

    def expect(self, v):
        if self.nxt()[1] != v:
            die('表达式语法: 期望 %r' % v)

    def expr(self):
        c = self.binop(0)
        if self.peek() == ('op', '?'):
            self.nxt()
            a = self.expr()
            self.expect(':')
            return ('?', c, a, self.expr())
        return c

    def binop(self, minp):
        lhs = self.unary()
        while True:
            k, x = self.peek()
            if not (k == 'op' and x in BIN and BIN[x] > minp):
                return lhs
            self.nxt()
            lhs = (x, lhs, self.binop(BIN[x]))

    def unary(self):
        k, x = self.peek()
        if k == 'op' and x in ('~', '!', '&', '|', '^', '-'):
            self.nxt()
            return ('u' + x, self.unary())
        e = self.primary()
        while self.peek() == ('op', '['):
            self.nxt()
            a = self.expr()
            if self.peek() == ('op', ':'):
                self.nxt()
                b = self.expr()
                self.expect(']')
                e = ('slice', e, a, b)
            else:
                self.expect(']')
                e = ('bit', e, a)
        return e

    def primary(self):
        k, x = self.nxt()
        if k == 'const':
            return ('const', x)
        if k == 'int':
            return ('int', int(x))
        if k == 'id' and x.startswith('__CAST'):
            self.expect('(')
            e = self.expr()
            self.expect(')')
            return ('cast', int(x[6:]), e)
        if k == 'id':
            return ('id', x)
        if x == '(':
            e = self.expr()
            self.expect(')')
            return e
        if x == '{':
            first = self.expr()
            if self.peek() == ('op', '{'):
                self.nxt()
                inner = [self.expr()]
                while self.peek() == ('op', ','):
                    self.nxt()
                    inner.append(self.expr())
                self.expect('}')
                self.expect('}')
                return ('rep', first, ('cat', inner))
            items = [first]
            while self.peek() == ('op', ','):
                self.nxt()
                items.append(self.expr())
            self.expect('}')
            return ('cat', items)
        die('表达式语法: 意外的 %r' % (x,))


def parse_expr(s):
    p = _P(tokenize(s))
    e = p.expr()
    if p.i != len(p.t):
        die('表达式有多余部分: %r' % s[:120])
    return e


def const_val(c):
    w, rest = c.split("'")
    return int(w), int(rest[1:].replace('_', ''), {'h': 16, 'b': 2, 'd': 10, 'o': 8}[rest[0]])


def ids_of(e, acc):
    if e[0] == 'id':
        acc.append(e[1])
    for x in e[1:]:
        if isinstance(x, tuple):
            ids_of(x, acc)
        elif isinstance(x, list):
            for y in x:
                ids_of(y, acc)
    return acc


def operator_free(e):
    k = e[0]
    if k in ('id', 'const', 'int'):
        return True
    if k in ('slice', 'bit'):
        return operator_free(e[1])
    if k == 'cat':
        return all(operator_free(x) for x in e[1])
    if k == 'rep':
        return operator_free(e[2])
    return False


def show(e):
    k = e[0]
    if k in ('id', 'const'):
        return e[1]
    if k == 'int':
        return str(e[1])
    if k == 'slice':
        return '%s[%s:%s]' % (show(e[1]), show(e[2]), show(e[3]))
    if k == 'bit':
        return '%s[%s]' % (show(e[1]), show(e[2]))
    if k == 'cat':
        return '{' + ', '.join(show(x) for x in e[1]) + '}'
    if k == 'rep':
        return '{%s{%s}}' % (show(e[1]), ', '.join(show(x) for x in e[2][1]))
    if k == '?':
        return '(%s ? %s : %s)' % (show(e[1]), show(e[2]), show(e[3]))
    if k.startswith('u'):
        return '%s(%s)' % (k[1:], show(e[1]))
    return '(%s %s %s)' % (show(e[1]), k, show(e[2]))


def rename(e, f):
    """把表达式里的标识符经 f 改名后重新打印（只用于不含运算符的连线表达式）。"""
    k = e[0]
    if k == 'id':
        return f(e[1])
    if k in ('const',):
        return e[1]
    if k == 'int':
        return str(e[1])
    if k == 'slice':
        return '%s[%s:%s]' % (rename(e[1], f), show(e[2]), show(e[3]))
    if k == 'bit':
        return '%s[%s]' % (rename(e[1], f), show(e[2]))
    if k == 'cat':
        return '{' + ', '.join(rename(x, f) for x in e[1]) + '}'
    if k == 'rep':
        return '{%s{%s}}' % (show(e[1]), ', '.join(rename(x, f) for x in e[2][1]))
    die('rename: 非连线表达式 %s' % show(e))


# ---------------------------------------------------------------------------
# golden 模块解析
# ---------------------------------------------------------------------------
def strip_comments(t):
    return re.sub(r'//[^\n]*', '', re.sub(r'/\*.*?\*/', '', t, flags=re.S))


class Mod:
    pass


_MOD_CACHE = {}


def golden_module(name):
    if name in _MOD_CACHE:
        return _MOD_CACHE[name]
    path = GOLDEN / (name + '.sv')
    if not path.exists():
        path = GOLDEN / (name + '.v')
    text = path.read_text()
    m = re.search(r'^module\s+%s\s*\(' % re.escape(name), text, re.M)
    if not m:
        die('golden 里找不到 module %s' % name)
    end = text.index('\nendmodule', m.end())
    src = text[m.start():end]
    hdr_end = src.index(');\n')
    M = Mod()
    M.name = name
    M.port_lines = [ln for ln in src[:hdr_end].split('\n')[1:] if ln.strip()]
    M.ports = [(d, int(w) + 1 if w else 1, n) for d, w, n in re.findall(
        r'\b(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)', strip_comments(src[:hdr_end]))]
    M.width = {n: w for _, w, n in M.ports}
    M.wires, M.assigns, M.insts = {}, {}, []
    lines = src[hdr_end + 3:].split('\n')
    i = 0

    def collect(i, done):
        buf = []
        while True:
            buf.append(lines[i])
            i += 1
            if done(buf[-1]):
                return '\n'.join(buf), i
    while i < len(lines):
        s = lines[i].strip()
        if not s or s.startswith('//'):
            i += 1
            continue
        if s.startswith('`if'):
            depth = 0
            while True:
                t = lines[i].strip()
                depth += t.startswith('`ifdef') or t.startswith('`ifndef')
                depth -= t.startswith('`endif')
                i += 1
                if depth == 0:
                    break
            continue
        if s.startswith('always'):
            _, i = collect(i, lambda x: x.startswith('  end') and 'always' in x)
            continue
        if s == 'wire':
            lines[i + 1] = '  wire ' + lines[i + 1].strip()
            i += 1
            continue
        mw = re.match(r'(wire|reg|logic)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*(=|;)', s)
        if mw:
            kind, w, n, eq = mw.groups()
            M.width[n] = int(w) + 1 if w else 1
            if eq == ';':
                M.wires.setdefault(n, None)
                i += 1
            else:
                txt, i = collect(i, lambda x: x.rstrip().endswith(';'))
                M.wires[n] = strip_comments(txt).split('=', 1)[1].strip().rstrip(';')
            continue
        if s.startswith('assign'):
            txt, i = collect(i, lambda x: x.rstrip().endswith(';'))
            mm = re.match(r'\s*assign\s+(\w+)\s*=\s*(.*);\s*$', strip_comments(txt), re.S)
            M.assigns[mm.group(1)] = mm.group(2).strip()
            continue
        mi = re.match(r'(\w+)\s+(\w+)\s*\($', s)
        if mi:
            txt, i = collect(i, lambda x: x.strip() == ');')
            conns = [(c.group(1), ' '.join(strip_comments(c.group(2)).split()))
                     for c in re.finditer(r'\.(\w+)\s*\((.*?)\)\s*(?=,\s*\n|\n\s*\);|$)', txt, re.S)]
            M.insts.append((mi.group(1), mi.group(2), conns))
            continue
        die('%s: 无法识别的行: %r' % (name, lines[i]))
    _MOD_CACHE[name] = M
    return M


# ---------------------------------------------------------------------------
# golden 胶合信号名 -> 手写区名字（出现在"不含运算符"的子模块连线里）
# ---------------------------------------------------------------------------
ID_MAP = {
    # 特权态 / 调试态寄存器
    'PRVM': 'prvm',
    'V': 'virt',
    'debugMode': 'debug_mode',
    'debug': 'intr_is_debug_q',
    'debugIntr': 'debug_intr',
    'entryDebugMode': 'entry_debug_mode',
    'holdDpc': 'hold_dpc',
    'criticalErrorState': 'critical_error_state',
    'debugModeStopCount': 'debug_stop_count_q',
    'unprivCountUpdate': 'unpriv_count_update',
    # 访问请求
    'ren': 'ren',
    'wen': 'wen',
    'wenLegalReg_last_REG': 'wen_legal_q',
    # 中断
    'intrVec': 'intr_vec_q',
    'irToHS': 'ir_to_hs_q',
    'irToVS': 'ir_to_vs_q',
    'nmip_NMI_31': 'nmip_31_q',
    'nmip_NMI_43': 'nmip_43_q',
    # 写使能（被多个子模块共用的那几根 golden 起了独立名字）
    'io_status_satp_valid_0': 'wen_satp',
    'io_status_vsatp_valid_0': 'wen_vsatp',
    '_mstatus_w_wen_T_1': 'wen_mstatus',
    '_mstatus_wAliasSstatus_wen_T_3': 'wen_sstatus',
    '_fcsr_w_wen_T_1': 'wen_fcsr',
    '_fcsr_wAliasFfm_wen_T_1': 'wen_frm',
    '_vsstatus_w_wen_T_6': 'wen_vsstatus',
    '_vstart_w_wen_T_1': 'wen_vstart',
    '_menvcfg_w_wen_T_1': 'wen_menvcfg',
    '_henvcfg_w_wen_T_1': 'wen_henvcfg',
    '_hgatp_w_wen_T_1': 'wen_hgatp',
    '_htimedelta_w_wen_T_1': 'wen_htimedelta',
    '_stimecmp_w_wen_T_3': 'wen_stimecmp',
    '_vstimecmp_w_wen_T_6': 'wen_vstimecmp',
    # Sstc 中断生成器的写使能打一拍
    'sstcIRGen_i_stimecmp_wen_last_REG': 'sstc_stimecmp_wen_q',
    'sstcIRGen_i_vstimecmp_wen_last_REG': 'sstc_vstimecmp_wen_q',
    'sstcIRGen_i_menvcfg_wen_last_REG': 'sstc_menvcfg_wen_q',
    'sstcIRGen_i_henvcfg_wen_last_REG': 'sstc_henvcfg_wen_q',
    'sstcIRGen_i_htimedeltaWen_last_REG': 'sstc_htimedelta_wen_q',
    # FS/VS Off
    '_io_toDecode_illegalInst_fsIsOff_T': 'mstatus_fs_off',
    '_io_toDecode_illegalInst_fsIsOff_T_2': 'vsstatus_fs_off',
    '_io_toDecode_illegalInst_vsIsOff_T': 'mstatus_vs_off',
    '_io_toDecode_illegalInst_vsIsOff_T_2': 'vsstatus_vs_off',
    # trap 事件的公共输入
    'trapEntryMEvent_in_iMode_PRVM_cloned': 'trap_imode_prvm',
    'trapEntryMEvent_in_iMode_V_cloned': 'trap_imode_v',
    '_trapEntryMEvent_in_dMode_V_WIRE': 'trap_dmode_v',
    # 触发器
    'tdata1Update': 'tdata1_update',
    'tdata2Update': 'tdata2_update',
    # 间接 CSR 读
    'siregRData': 'sireg_iprio_rdata',
}
# 退休提交信息打一拍（Scala 在 for 循环里给每个 HasRobCommitBundle 模块各 RegNext 一份，
# 所以 golden 每个消费者一套寄存器；手写区照样保留每消费者一套，名字 <消费者>_cmt_<字段>）
for _who in ('mstatus', 'vsstatus', 'vstart'):
    ID_MAP['%s_robCommit_vsDirty_last_REG' % _who] = '%s_cmt_vs_dirty_q' % _who
    ID_MAP['%s_robCommit_vstart_next_valid_last_REG' % _who] = '%s_cmt_vstart_valid_q' % _who
    ID_MAP['%s_robCommit_vstart_next_bits_r' % _who] = '%s_cmt_vstart_bits_q' % _who
for _who in ('mstatus', 'vsstatus'):
    ID_MAP['%s_robCommit_fsDirty_last_REG' % _who] = '%s_cmt_fs_dirty_q' % _who
ID_MAP['fcsr_robCommit_fflags_next_valid_last_REG'] = 'fcsr_cmt_fflags_valid_q'
ID_MAP['fcsr_robCommit_fflags_next_bits_r'] = 'fcsr_cmt_fflags_bits_q'
ID_MAP['vcsr_robCommit_vxsat_next_valid_last_REG'] = 'vcsr_cmt_vxsat_valid_q'
ID_MAP['vcsr_robCommit_vxsat_next_bits_r'] = 'vcsr_cmt_vxsat_bits_q'
ID_MAP['vtype_robCommit_vtype_next_valid_last_REG'] = 'vtype_cmt_valid_q'
for _f in ('VILL', 'VMA', 'VTA', 'VSEW', 'VLMUL'):
    ID_MAP['vtype_robCommit_vtype_next_bits_r_' + _f] = 'vtype_cmt_%s_q' % _f.lower()
# 29 个硬件性能计数器的计数使能
for _i in range(29):
    ID_MAP['countingEn_%d' % _i] = 'counting_en[%d]' % _i
# PMP / PMA 配置字节写数据（PMPEntryHandleModule / PMAEntryHandleModule 输出的 64 位按字节拆）
for _i in range(8):
    ID_MAP['_GEN_%d' % _i] = 'pmpcfg_byte_wdata[%d]' % _i
    ID_MAP['_GEN_%d' % (_i + 8)] = 'pmacfg_byte_wdata[%d]' % _i


# ---------------------------------------------------------------------------
# 含运算符的连接 -> 手写区里的一根线
# ---------------------------------------------------------------------------
TRAP_EVENTS = ('trapEntryMEvent', 'trapEntryMNEvent', 'trapEntryHSEvent', 'trapEntryVSEvent',
               'trapEntryDEvent')


def conn_rule(inst, port):
    """返回手写区里的线名；None = 没有规则（调用方 fail-closed）。"""
    if port == 'w_wen':
        m = re.fullmatch(r'pmpcfgs_(\d+)', inst)
        if m:
            return 'wen_pmpcfg_%d' % (int(m.group(1)) // 8)
        m = re.fullmatch(r'pmacfgs_(\d+)', inst)
        if m:
            return 'wen_pmacfg_%d' % (int(m.group(1)) // 8)
        return 'wen_' + inst
    if port in ('wAliasFflags_wen', 'wAliasVxsat_wen', 'wAliasVxrm_wen'):
        return {'wAliasFflags_wen': 'wen_fflags', 'wAliasVxsat_wen': 'wen_vxsat',
                'wAliasVxrm_wen': 'wen_vxrm'}[port]
    if inst in TRAP_EVENTS and port in ('in_oldSatp_MODE', 'in_oldVsatp_MODE'):
        return {'in_oldSatp_MODE': 'trap_old_satp_mode', 'in_oldVsatp_MODE': 'trap_old_vsatp_mode'}[port]
    if port == 'valid' and inst in TRAP_EVENTS:
        return 'valid_' + inst
    m = re.fullmatch(r'tdata1RegVec_(\d)', inst)
    if m and port in ('canWriteDmode', 'dmodeNextTrigger'):
        return '%s_%s' % ({'canWriteDmode': 'trigger_can_write_dmode',
                           'dmodeNextTrigger': 'trigger_dmode_next'}[port], m.group(1))
    single = {
        ('mip', 'lcofiReq'): 'lcofi_req',
        ('time_0', 'nextV'): 'next_virt',
        ('time_0', 'debugModeStopTime'): 'debug_stop_time',
        ('mireg', 'iregRead_mireg'): 'mireg_iprio_rdata',
        ('tdata1', 'tdataRead_tdata1'): 'tdata1_selected_rdata',
        ('tdata2', 'tdataRead_tdata2'): 'tdata2_selected_rdata',
        ('dcsr', 'nmip'): 'nmi_pending',
        ('intrMod', 'io_in_nmi'): 'nmi_pending',
        ('permitMod', 'io_in_csrAccess_ren'): 'permit_ren',
        ('permitMod', 'io_in_xRet_mnret'): 'xret_mnret',
        ('permitMod', 'io_in_xRet_mret'): 'xret_mret',
        ('permitMod', 'io_in_xRet_sret'): 'xret_sret',
        ('permitMod', 'io_in_xRet_dret'): 'xret_dret',
        ('trapHandleMod', 'io_in_trapInfo_bits_singleStep'): 'trap_single_step',
        ('debugMod', 'io_in_triggerCanRaiseBpExp'): 'trigger_can_raise_bp_exp',
    }
    return single.get((inst, port))


# ---------------------------------------------------------------------------
# CSR（NewCSR 的父：功能单元外壳）—— 胶合信号名与含运算符连接的映射
# ---------------------------------------------------------------------------
CSR_ID_MAP = {
    'wdataReg': 'wdata_q',
    'trapInstMod_io_fromDecode_trapInstInfo_next_valid_last_REG': 'trap_inst_info_valid_q',
    'trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_instr': 'trap_inst_info_instr_q',
    'trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_flag': 'trap_inst_info_ftq_flag_q',
    'trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqPtr_value': 'trap_inst_info_ftq_value_q',
    'trapInstMod_io_fromDecode_trapInstInfo_next_bits_r_ftqOffset': 'trap_inst_info_ftq_offset_q',
}


def csr_conn_rule(inst, port):
    return {
        ('csrMod', 'io_in_bits_wen'): 'csr_wen',
        ('csrMod', 'io_in_bits_ren'): 'csr_ren',
        ('csrMod', 'io_in_bits_src'): 'csr_src',
        ('csrMod', 'io_in_bits_mnret'): 'is_mnret',
        ('csrMod', 'io_in_bits_mret'): 'is_mret',
        ('csrMod', 'io_in_bits_sret'): 'is_sret',
        ('csrMod', 'io_in_bits_dret'): 'is_dret',
        ('csrMod', 'io_in_bits_redirectFlush'): 'redirect_flush',
        ('trapInstMod', 'io_faultCsrUop_valid'): 'fault_csr_uop_valid',
        ('trapInstMod', 'io_faultCsrUop_bits_fuOpType'): 'fault_csr_uop_fuoptype',
        ('trapInstMod', 'io_faultCsrUop_bits_imm'): 'fault_csr_uop_imm',
        ('trapInstMod', 'io_faultCsrUop_bits_ftqInfo_ftqPtr_flag'): 'fault_csr_uop_ftq_flag',
        ('trapInstMod', 'io_faultCsrUop_bits_ftqInfo_ftqPtr_value'): 'fault_csr_uop_ftq_value',
        ('trapInstMod', 'io_faultCsrUop_bits_ftqInfo_ftqOffset'): 'fault_csr_uop_ftq_offset',
        ('trapInstMod', 'io_readClear'): 'trap_inst_read_clear',
        ('trapTvalMod', 'io_clear'): 'trap_tval_clear',
    }.get((inst, port))


TARGETS = [
    dict(top='NewCSR', path=REPO / 'rtl' / 'backend' / 'NewCSR.sv', prefix='newcsr',
         id_map=ID_MAP, rule=conn_rule, regout=True),
    dict(top='CSR', path=REPO / 'rtl' / 'backend' / 'CSR.sv', prefix='csr',
         id_map=CSR_ID_MAP, rule=csr_conn_rule, regout=False),
]


# ---------------------------------------------------------------------------
# regOut 打包视图：把 golden io_out_bits_regOut 拆成 "每个选择条件 -> 64 位字段视图"
# ---------------------------------------------------------------------------
REGOUT_TREE = re.compile(r'(_regOut_T_\d+|_GEN_(?:16|17|18|19|20)|rdata|_rdata_T_\d+)$')


def width_of(M, e):
    k = e[0]
    if k == 'id':
        return M.width[e[1]]
    if k == 'const':
        return const_val(e[1])[0]
    if k == 'slice':
        return e[2][1] - e[3][1] + 1
    if k == 'bit':
        return 1
    if k == 'cat':
        return sum(width_of(M, x) for x in e[1])
    if k == 'rep':
        return e[1][1] * width_of(M, e[2])
    if k == '?':
        return max(width_of(M, e[2]), width_of(M, e[3]))
    if k in ('u~',):
        return width_of(M, e[1])
    if k.startswith('u') or k in ('==', '!=', '<', '>', '<=', '>='):
        return 1
    return max(width_of(M, e[1]), width_of(M, e[2]))


def mux_terms(M, e, cache):
    """返回每一位（lsb 起）的 [(条件文本 or None, 源)]，源 = ('1',) 或 (信号名, 位)。"""
    k, W = e[0], width_of(M, e)
    if k == 'const':
        v = const_val(e[1])[1]
        return [[(None, ('1',))] if (v >> i) & 1 else [] for i in range(W)]
    if k == 'id':
        n = e[1]
        if REGOUT_TREE.match(n) and M.wires.get(n):
            if n not in cache:
                cache[n] = mux_terms(M, parse_expr(M.wires[n]), cache)
            return cache[n]
        return [[(None, (n, i))] for i in range(W)]
    if k == 'slice':
        return mux_terms(M, e[1], cache)[e[3][1]:e[2][1] + 1]
    if k == 'bit':
        return [mux_terms(M, e[1], cache)[e[2][1]]]
    if k == 'cat':
        out = []
        for x in reversed(e[1]):
            out += mux_terms(M, x, cache)
        return out
    if k == '|':
        a, b = mux_terms(M, e[1], cache), mux_terms(M, e[2], cache)
        a = a + [[] for _ in range(W - len(a))]
        b = b + [[] for _ in range(W - len(b))]
        return [a[i] + b[i] for i in range(W)]
    if k == '?':
        if any(mux_terms(M, e[3], cache)):
            die('regOut Mux 出现非零 else 分支: ' + show(e)[:160])
        c = show(e[1])
        out = []
        for bit in mux_terms(M, e[2], cache):
            if any(cond is not None for cond, _ in bit):
                die('regOut Mux 出现嵌套条件: ' + show(e)[:160])
            out.append([(c, src) for _, src in bit])
        return out + [[] for _ in range(W - len(out))]
    if k == '&' and W == 1 and e[1][0] == 'id' and e[2][0] == 'id':
        return [[(e[1][1], (e[2][1], 0))]]      # 1 位读数据：sel & 源位
    die('regOut Mux 出现不认识的写法 %s: %s' % (k, show(e)[:160]))


def csr_addr_of_cond(cond, dec):
    """选择条件文本 -> CSR 地址（S/VS 别名取"自己的"地址，即非 VS 态下的那个）。"""
    m = re.fullmatch(r'(\w+)', cond)
    if m and cond in dec:
        return dec[cond]
    m = re.fullmatch(r'\(~\(isModeVS\) & (\w+)\)', cond)
    if m and m.group(1) in dec:
        return dec[m.group(1)]
    m = re.fullmatch(r'\(\(isModeVS & (\w+)\) \| \(~\(isModeVS\) & (\w+)\)\)', cond)
    if m and m.group(2) in dec:
        return dec[m.group(2)]
    die('regOut 选择条件无法对应到 CSR 地址: ' + cond)


# 读数据源名 -> CSR 名（少数 CSR 的读数据不是 <实例>_rdata，或是常数）
CSR_NAME_OVERRIDE = {0x001: 'fflags', 0x002: 'frm', 0x009: 'vxsat', 0x00A: 'vxrm',
                     0x100: 'sstatus', 0x301: 'misa', 0x7A4: 'tinfo', 0xC01: 'time',
                     0xC22: 'vlenb', 0xF11: 'mvendorid', 0xF12: 'marchid'}


def build(T):
    top = golden_module(T['top'])
    id_map, rule = T['id_map'], T['rule']
    port_names = {n for _, _, n in top.ports}
    out_ports = {n for d, _, n in top.ports if d == 'output'}

    # ---- 子模块输出线：golden 线名 -> (实例, 端口) ----
    childnet = {}       # golden 线名 -> impl 线名
    child_decls = []    # (inst, [(width, implname)])
    for typ, inst, conns in top.insts:
        sub = golden_module(typ)
        sdir = {n: d for d, _, n in sub.ports}
        swid = {n: w for _, w, n in sub.ports}
        if [p for p, _ in conns] != [n for _, _, n in sub.ports]:
            die('%s(%s): 连线端口序列与 golden 子模块端口表不一致' % (inst, typ))
        decl = []
        for p, e in conns:
            if sdir[p] != 'output':
                continue
            if e == '':
                continue
            if e in out_ports:
                continue                     # golden 直连顶层输出口，impl 同样直连
            if not re.fullmatch(r'_\w+', e):
                die('%s.%s: 子模块输出接到了非线名 %r' % (inst, p, e))
            if e in childnet:
                die('%s: 多个子模块输出驱动同一根线' % e)
            impl = '%s_%s' % (inst, p)
            childnet[e] = impl
            decl.append((swid[p], impl))
        child_decls.append((inst, decl))

    # ---- 地址译码线（golden）：只用来给 regOut 视图起名字 ----
    dec = {}
    for n, e in top.wires.items():
        if e:
            m = re.fullmatch(r"io_in_bits_addr == 12'h([0-9A-F]+)", e)
            if m:
                dec[n] = int(m.group(1), 16)

    def map_id(i, used):
        if i in port_names or i in ('clock', 'reset'):
            return i
        if i in childnet:
            return childnet[i]
        if i in id_map:
            used.add(i)
            return id_map[i]
        die('%s: golden 胶合信号 %r 没有 ID_MAP 映射（不猜）' % (T['top'], i))

    # ---- 实例 ----
    used_ids, used_rules = set(), set()
    inst_blocks = []
    for typ, inst, conns in top.insts:
        sub = golden_module(typ)
        sdir = {n: d for d, _, n in sub.ports}
        rows = []
        for p, e in conns:
            if sdir[p] == 'output':
                if e == '':
                    rows.append((p, ''))
                elif e in out_ports:
                    rows.append((p, e))
                else:
                    rows.append((p, childnet[e]))
                continue
            if e == '':
                die('%s.%s: 输入悬空' % (inst, p))
            x = parse_expr(e)
            if operator_free(x):
                rows.append((p, rename(x, lambda i: map_id(i, used_ids))))
            else:
                r = rule(inst, p)
                if r is None:
                    die('%s: %s.%s: 含运算符的连接没有 CONN 规则: %s' % (T['top'], inst, p, e[:120]))
                used_rules.add((inst, p))
                rows.append((p, r))
        inst_blocks.append((typ, inst, rows))
    unused = sorted(set(id_map) - used_ids)
    if unused:
        die('%s: ID_MAP 里有没被用到的条目: %s' % (T['top'], unused[:10]))
    if not T['regout']:
        return top, child_decls, inst_blocks, []

    # ---- regOut 视图 ----
    cache = {}
    terms = mux_terms(top, parse_expr(top.assigns['io_out_bits_regOut']), cache)
    rdterms = mux_terms(top, parse_expr(top.wires['rdata']), {})
    by = collections.OrderedDict()
    for i, bit in enumerate(terms):
        for cond, src in bit:
            if cond is None:
                die('regOut 第 %d 位有无条件项' % i)
            by.setdefault(cond, {})
            if i in by[cond]:
                die('regOut 选择条件 %s 第 %d 位被驱动两次' % (cond, i))
            if src[0] != '1' and src[0] not in childnet:
                die('regOut 源 %s 不是子模块输出' % src[0])
            by[cond][i] = src
    # 名字：取同一选择条件下 rdata 的源实例名
    rdsrc = collections.defaultdict(set)
    for bit in rdterms:
        for cond, src in bit:
            if cond is not None and src[0] != '1':
                rdsrc[cond].add(src[0])
    views = []
    names = set()
    for cond, bits in by.items():
        addr = csr_addr_of_cond(cond, dec)
        if addr in CSR_NAME_OVERRIDE:
            name = CSR_NAME_OVERRIDE[addr]
        else:
            s = sorted(rdsrc.get(cond, ()))
            if len(s) != 1 or not re.fullmatch(r'_\w+_rdata', s[0]):
                die('regOut 选择条件 %s (0x%03X) 无法从读数据源起名: %s' % (cond, addr, s))
            name = childnet[s[0]][:-len('_rdata')]
        if name in names:
            die('regOut 视图重名: ' + name)
        names.add(name)
        views.append((addr, name, bits))
    return top, child_decls, inst_blocks, views


def pack(bits):
    """64 位视图 -> {..} 拼接，相邻同源位合并成片段。"""
    segs = []   # (src_name or None for const, hi, lo, const_bits)
    i = 63
    while i >= 0:
        s = bits.get(i)
        if s is None or s[0] == '1':
            j = i
            while j - 1 >= 0 and (bits.get(j - 1) is None or bits.get(j - 1)[0] == '1'):
                j -= 1
            v = 0
            for b in range(i, j - 1, -1):
                v = (v << 1) | (1 if bits.get(b) == ('1',) else 0)
            segs.append("%d'h%X" % (i - j + 1, v))
            i = j - 1
            continue
        name, hi = s
        j = i
        while j - 1 >= 0 and bits.get(j - 1) is not None and bits[j - 1][0] == name \
                and bits[j - 1][1] == bits[j][1] - 1:
            j -= 1
        lo = bits[j][1]
        segs.append((name, hi, lo))
        i = j - 1
    return segs


def render(T, top, child_decls, inst_blocks, views, childnet_w):
    R = {}
    pre = T['prefix']
    R[pre + '-ports'] = '\n'.join(top.port_lines)
    out = []
    for inst, decl in child_decls:
        if not decl:
            continue
        out.append('  // %s' % inst)
        for w, n in decl:
            out.append('  wire %-9s %s;' % ('[%d:0]' % (w - 1) if w > 1 else '', n))
    R[pre + '-childnets'] = '\n'.join(out)
    out = []
    for addr, name, bits in sorted(views):
        segs = pack(bits)
        parts = []
        for s in segs:
            if isinstance(s, str):
                parts.append(s)
            else:
                n, hi, lo = s
                impl = childnet_w[n]
                w = childnet_w['#' + n]
                parts.append(impl if (hi == w - 1 and lo == 0) else
                             ('%s[%d]' % (impl, hi) if hi == lo else '%s[%d:%d]' % (impl, hi, lo)))
        out.append('  // 0x%03X %s' % (addr, name))
        if len(parts) == 1:
            out.append('  wire [63:0] regout_%s = %s;' % (name, parts[0]))
        else:
            out.append('  wire [63:0] regout_%s = {' % name)
            for k, p in enumerate(parts):
                out.append('    %s%s' % (p, ',' if k < len(parts) - 1 else ''))
            out.append('  };')
    if T['regout']:
        R[pre + '-regout'] = '\n'.join(out)
    out = []
    for typ, inst, rows in inst_blocks:
        out.append('  %s %s (' % (typ, inst))
        wp = max(len(p) for p, _ in rows)
        for k, (p, c) in enumerate(rows):
            out.append('    .%s (%s)%s' % (p.ljust(wp), c, ',' if k < len(rows) - 1 else ''))
        out.append('  );')
    R[pre + '-insts'] = '\n'.join(out)
    return R


def run_target(T, check):
    top, child_decls, inst_blocks, views = build(T)
    # golden 子模块输出线名 -> impl 名 / 位宽（regOut 视图打印用）
    cw = {}
    for typ, inst, conns in top.insts:
        sub = golden_module(typ)
        swid = {n: w for _, w, n in sub.ports}
        sdir = {n: d for d, _, n in sub.ports}
        for p, e in conns:
            if sdir[p] == 'output' and re.fullmatch(r'_\w+', e or ''):
                cw[e] = '%s_%s' % (inst, p)
                cw['#' + e] = swid[p]
    R = render(T, top, child_decls, inst_blocks, views, cw)
    path = T['path']
    if not path.exists():
        die('%s 不存在：手写部分要先写好（本脚本只替换 GENERATED 区）' % path)
    txt = path.read_text()
    new = txt
    for r in R:
        b = '// BEGIN GENERATED(%s) —— 由 scripts/gen_newcsr.py 从 golden 机械产出，勿手改' % r
        e = '// END GENERATED(%s)' % r
        if new.count(b) != 1 or new.count(e) != 1:
            die('%s: GENERATED(%s) 标记必须各恰好一个' % (path.name, r))
        head, rest = new.split(b, 1)
        _, tail = rest.split(e, 1)
        new = head + b + '\n' + R[r] + '\n' + e + tail
    what = '%d 实例%s' % (len(inst_blocks), '，%d 个 regOut 视图' % len(views) if T['regout'] else '')
    if new != txt:
        if check:
            print('gen_newcsr --check: DRIFT %s' % path.relative_to(REPO))
            return 1
        path.write_text(new)
        print('wrote %s（%s）' % (path.relative_to(REPO), what))
    else:
        print('gen_newcsr%s: %s OK（%s，无漂移）' % (' --check' if check else '', path.name, what))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    rc = 0
    for T in TARGETS:
        rc |= run_target(T, args.check)
    return rc


if __name__ == '__main__':
    sys.exit(main())
