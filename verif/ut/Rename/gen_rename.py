#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_rename.py —— 生成 Rename 的 golden 同名 wrapper(写回 rtl/backend/Rename.sv 文件尾)与本目录 tb.sv。

★为什么机械生成★ golden Rename 有 1881 个扁平端口，其中 6 口 × ~100 个 DecodedInst 字段
纯直通、另 ~30 个字段由核算出。wrapper 里没有一行设计决策，只是"扁平端口 ↔ 核的
struct/数组"的拆装；手抄 1300 行 assign 漏一根线 UT 未必抓得住(漏的那根可能恰好总是 0)。
所以从 **G1 golden 的端口表**生成，并在生成时做三项机械核对(任何一项不符就拒绝生成)：

  1. 输入覆盖：每个 io_in_<i>_bits_<F> 都必须映射到 rename_pkg::decoded_inst_t 的某个成员，
     且位宽相等；struct 里每个成员在每个口都必须有来源(口 0 的 lsrc_2..4 是 golden
     消掉的已知例外，补 0)。
  2. 输出覆盖：每个 io_out_<i>_bits_<F> 要么在 COMPUTED 表里(接核的显式输出)，要么是
     直通(struct 里同名同宽成员)；两者都不是就拒绝。
  3. 其余端口(redirect/rabCommits/RAT 读写口/old_pdest/snpt/stallReason/perf/debug_rat)
     必须与本脚本的固定映射表逐个对上，不许多也不许少。

产物：
  rtl/backend/Rename.sv     —— 只覆写文件尾「golden 同名 wrapper」分节(标记行以下)，
                               package + xs_Rename_core 手写部分原样保留；
  verif/ut/Rename/tb.sv     —— golden vs 重写 双例化逐拍比对(全部输出口 + 层次探针)。

用法: python3 gen_rename.py [--check]
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = REPO / 'rtl' / 'backend' / 'Rename.sv'
MOD = 'Rename'
RW, CW, NSRC, NPERF = 6, 6, 5, 30
MARK = '// golden 同名 wrapper —— 由 verif/ut/Rename/gen_rename.py 生成，改请改生成器'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')


def die(msg):
    raise SystemExit('gen_rename: ★拒绝生成★ ' + msg)


def width(rng):
    if not rng:
        return 1
    m = re.fullmatch(r'\[(\d+):0\]', rng)
    if not m:
        die('不认识的位宽写法: %r' % rng)
    return int(m.group(1)) + 1


def ports():
    text = (GOLDEN / (MOD + '.sv')).read_text()
    m = re.search(r'^module %s\((.*?)\n\);' % MOD, text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = PORT_RE.match(line)
        if pm:
            res.append((pm.group(1), width(pm.group(2)), pm.group(3)))
    return res


def struct_members():
    """从 rename_pkg 的 decoded_inst_t 读成员表 {名: 位宽}(packed 数组成员展开成 名_i)。"""
    text = RTL.read_text()
    m = re.search(r'typedef struct packed \{(.*?)\} decoded_inst_t;', text, re.S)
    if not m:
        die('rename_pkg 里找不到 decoded_inst_t')
    # 位宽里会用包常量(SRCTYPE_W 等)：从同一个包里把 `localparam int X = N;` 读出来代入
    consts = {k: int(v) for k, v in re.findall(r'localparam int (\w+)\s*=\s*(\d+)\s*;', text)}

    def dim(expr):
        e = expr.strip()
        for k, v in consts.items():
            e = re.sub(r'\b%s\b' % k, str(v), e)
        if not re.fullmatch(r'[\d\s+\-*()]+', e):
            die('struct 位宽表达式算不出来: %r' % expr)
        return eval(e)  # 只含数字与 + - * ()
    members = {}
    for line in m.group(1).splitlines():
        line = line.split('//')[0].strip()
        if not line:
            continue
        mm = re.match(r'logic\s*((?:\[[^\]]*\]\s*)*)(\w+);', line)
        if not mm:
            die('struct 成员行看不懂: %r' % line)
        dims = [dim(d) for d in re.findall(r'\[([^\]:]+):0\]', mm.group(1))]
        name = mm.group(2)
        if len(dims) == 2:                      # [N-1:0][W-1:0] name → name_i
            n, w = dims[0] + 1, dims[1] + 1
            for i in range(n):
                members['%s_%d' % (name, i)] = w
        elif len(dims) == 1:
            members[name] = dims[0] + 1
        else:
            members[name] = 1
    # exceptionVec 是 24 位一根：golden 是 exceptionVec_0..23 各 1 位
    del members['exceptionVec']
    for k in range(24):
        members['exceptionVec_%d' % k] = 1
    return members


def member_ref(port, field):
    """扁平字段名 → struct 成员引用。"""
    m = re.match(r'exceptionVec_(\d+)$', field)
    if m:
        return 'exceptionVec[%s]' % m.group(1)
    m = re.match(r'(srcType|lsrc)_(\d)$', field)
    if m:
        return '%s[%s]' % (m.group(1), m.group(2))
    return field


# 由核算出的 io_out 字段 → 核输出表达式
def computed(i, f):
    m = re.match(r'psrc_(\d)$', f)
    if m:
        return 'o_psrc[%d][%s]' % (i, m.group(1))
    tbl = {
        'pdest': 'o_pdest', 'robIdx_flag': 'o_robIdx_flag', 'robIdx_value': 'o_robIdx_value',
        'eliminatedMove': 'o_isMove', 'isMove': 'o_isMove', 'snapshot': 'o_snapshot',
        'hasException': 'o_hasException', 'srcType_0': 'o_srcType0', 'imm': 'o_imm',
        'debugInfo_renameTime': 'o_renameTime', 'instrSize': 'o_instrSize',
        'dirtyFs': 'o_dirtyFs', 'dirtyVs': 'o_dirtyVs', 'debug_sim_trig': 'o_simTrig',
        'traceBlockInPipe_itype': 'o_itype', 'traceBlockInPipe_iretire': 'o_iretire',
        'traceBlockInPipe_ilastsize': 'o_ilastsize', 'lastUop': 'o_lastUop',
        'numUops': 'o_numUops', 'numWB': 'o_numWB', 'wfflags': 'o_wfflags',
        'numLsElem': 'o_numLsElem', 'ftqPtr_flag': 'o_ftqFlag', 'ftqPtr_value': 'o_ftqValue',
        'ftqOffset': 'o_ftqOff', 'firstUop': 'o_firstUop', 'waitForward': 'o_waitForward',
        'blockBackward': 'o_blockBackward',
    }
    return ('%s[%d]' % (tbl[f], i)) if f in tbl else None


# 固定映射表：非 io_in/io_out 端口 → wrapper 内的载体
def fixed_map():
    m = {}
    scal = ['clock', 'reset', 'io_redirect_valid', 'io_redirect_bits_robIdx_flag',
            'io_redirect_bits_robIdx_value', 'io_redirect_bits_level',
            'io_redirect_bits_debugIsCtrl', 'io_redirect_bits_debugIsMemVio',
            'io_rabCommits_isCommit', 'io_rabCommits_isWalk', 'io_singleStep',
            'io_snpt_snptDeq', 'io_snpt_useSnpt', 'io_snpt_snptSelect',
            'io_snptLastEnq_valid', 'io_snptLastEnq_bits_flag', 'io_snptLastEnq_bits_value',
            'io_snptIsFull', 'io_stallReason_out_backReason_valid',
            'io_stallReason_in_backReason_valid', 'io_stallReason_in_backReason_bits']
    for s in scal:
        m[s] = s                                    # 直接接核同名端口
    for i in range(CW):
        m['io_rabCommits_commitValid_%d' % i] = 'rab_cv[%d]' % i
        m['io_rabCommits_walkValid_%d' % i] = 'rab_wv[%d]' % i
        for f, v in (('rfWen', 'rab_rf'), ('fpWen', 'rab_fp'), ('vecWen', 'rab_vec'),
                     ('v0Wen', 'rab_v0'), ('vlWen', 'rab_vl'), ('isMove', 'rab_mv')):
            m['io_rabCommits_info_%d_%s' % (i, f)] = '%s[%d]' % (v, i)
        m['io_int_need_free_%d' % i] = 'int_nf[%d]' % i
        for f, v in (('int', 'int_oldpd'), ('fp', 'fp_oldpd'), ('vec', 'vec_oldpd'),
                     ('v0', 'v0_oldpd'), ('vl', 'vl_oldpd')):
            m['io_%s_old_pdest_%d' % (f, i)] = '%s[%d]' % (v, i)
        for f, v in (('int', 'intRP'), ('fp', 'fpRP'), ('vec', 'vecRP')):
            m['io_%sRenamePorts_%d_wen' % (f, i)] = '%s[%d].wen' % (v, i)
            m['io_%sRenamePorts_%d_addr' % (f, i)] = ('%s[%d].addr[4:0]' if f == 'int' else '%s[%d].addr') % (v, i)
            m['io_%sRenamePorts_%d_data' % (f, i)] = '%s[%d].data' % (v, i)
        for f in ('v0', 'vl'):
            m['io_%sRenamePorts_%d_wen' % (f, i)] = '%sRP_wen[%d]' % (f, i)
            m['io_%sRenamePorts_%d_data' % (f, i)] = '%sRP_data[%d]' % (f, i)
    for i in range(RW - 1):
        for f in ('rs2FromRs1', 'rs2FromRs2', 'rs2FromZero'):
            m['io_fusionInfo_%d_%s' % (i, f)] = 'fi_%s[%d]' % (f, i)
    for i in range(RW):
        m['io_in_%d_valid' % i] = 'in_v[%d]' % i
        m['io_in_%d_ready' % i] = 'in_r[%d]' % i
        m['io_out_%d_valid' % i] = 'out_v[%d]' % i
        m['io_out_%d_ready' % i] = 'out_r[%d]' % i
        for s in range(2):
            m['io_intReadPorts_%d_%d' % (i, s)] = 'intRd[%d][%d]' % (i, s)
        for s in range(3):
            m['io_fpReadPorts_%d_%d' % (i, s)] = 'fpRd[%d][%d]' % (i, s)
            m['io_vecReadPorts_%d_%d' % (i, s)] = 'vecRd[%d][%d]' % (i, s)
        m['io_v0ReadPorts_%d_0' % i] = 'v0Rd[%d]' % i
        m['io_vlReadPorts_%d_0' % i] = 'vlRd[%d]' % i
        m['io_stallReason_in_reason_%d' % i] = 'sr_in[%d]' % i
        m['io_stallReason_out_reason_%d' % i] = 'sr_out[%d]' % i
    for k in range(4):
        m['io_snpt_flushVec_%d' % k] = 'flushv[%d]' % k
    for k in range(32):
        m['io_debug_int_rat_%d' % k] = 'dbg_int_rat[%d]' % k
    for p in range(NPERF):
        m['io_perf_%d_value' % p] = 'perf_v[%d]' % p
    return m


def make_wrapper(ps, members):
    fm = fixed_map()
    L = []
    A = L.append
    A(MARK)
    A('// (本行以下由生成器整段覆写；golden 扁平 %d 端口 ↔ 核 struct/数组 的机械拆装)' % len(ps))
    A('// =====================================================================')
    A('module %s' % MOD)
    A('  import rename_pkg::*;')
    A('(')
    decls = []
    for d, w, n in ps:
        ws = ('[%d:0] ' % (w - 1)) if w > 1 else '       '
        decls.append('  %s %s%s' % ('input ' if d == 'input' else 'output', ws, n))
    A(',\n'.join(decls))
    A(');')
    A('')
    A('  // ---- 中间载体 ----')
    A('  decoded_inst_t in_b [RENAME_WIDTH];')
    A('  decoded_inst_t out_pt [RENAME_WIDTH];')
    A('  logic [RENAME_WIDTH-1:0] in_v, in_r, out_v, out_r;')
    A('  logic [PHYREG_W-1:0] o_psrc [RENAME_WIDTH][NUM_SRC];')
    A('  logic [PHYREG_W-1:0] o_pdest [RENAME_WIDTH];')
    A('  logic o_robIdx_flag [RENAME_WIDTH];')
    A('  logic [ROB_PTR_W-1:0] o_robIdx_value [RENAME_WIDTH];')
    A('  logic o_isMove [RENAME_WIDTH], o_snapshot [RENAME_WIDTH], o_hasException [RENAME_WIDTH];')
    A('  logic [SRCTYPE_W-1:0] o_srcType0 [RENAME_WIDTH];')
    A('  logic [IMM_OUT_W-1:0] o_imm [RENAME_WIDTH];')
    A('  logic [63:0] o_renameTime [RENAME_WIDTH];')
    A('  logic [2:0] o_instrSize [RENAME_WIDTH];')
    A('  logic o_dirtyFs [RENAME_WIDTH], o_dirtyVs [RENAME_WIDTH], o_simTrig [RENAME_WIDTH], o_ilastsize [RENAME_WIDTH];')
    A('  logic [3:0] o_itype [RENAME_WIDTH], o_iretire [RENAME_WIDTH];')
    A('  logic o_lastUop [RENAME_WIDTH], o_wfflags [RENAME_WIDTH], o_firstUop [RENAME_WIDTH];')
    A('  logic o_waitForward [RENAME_WIDTH], o_blockBackward [RENAME_WIDTH];')
    A('  logic [6:0] o_numUops [RENAME_WIDTH], o_numWB [RENAME_WIDTH];')
    A('  logic [4:0] o_numLsElem [RENAME_WIDTH];')
    A('  logic o_ftqFlag [RENAME_WIDTH];')
    A('  logic [5:0] o_ftqValue [RENAME_WIDTH];')
    A('  logic [3:0] o_ftqOff [RENAME_WIDTH];')
    A('  rat_wport_t intRP [COMMIT_WIDTH], fpRP [COMMIT_WIDTH], vecRP [COMMIT_WIDTH];')
    A('  logic v0RP_wen [COMMIT_WIDTH], vlRP_wen [COMMIT_WIDTH];')
    A('  logic [PHYREG_W-1:0] v0RP_data [COMMIT_WIDTH], vlRP_data [COMMIT_WIDTH];')
    A('  logic [PHYREG_W-1:0] intRd [RENAME_WIDTH][2], fpRd [RENAME_WIDTH][3], vecRd [RENAME_WIDTH][3];')
    A('  logic [PHYREG_W-1:0] v0Rd [RENAME_WIDTH], vlRd [RENAME_WIDTH];')
    A('  logic [PHYREG_W-1:0] int_oldpd [COMMIT_WIDTH], fp_oldpd [COMMIT_WIDTH], vec_oldpd [COMMIT_WIDTH], v0_oldpd [COMMIT_WIDTH], vl_oldpd [COMMIT_WIDTH];')
    A('  logic [PHYREG_W-1:0] dbg_int_rat [INT_LREGS];')
    A('  logic [5:0] sr_in [RENAME_WIDTH], sr_out [RENAME_WIDTH];')
    A('  logic [5:0] perf_v [NUM_PERF];')
    A('  logic [3:0] flushv;')
    A('  logic [COMMIT_WIDTH-1:0] rab_cv, rab_wv, rab_rf, rab_fp, rab_vec, rab_v0, rab_vl, rab_mv, int_nf;')
    A('  logic [RENAME_WIDTH-1:0] fi_rs2FromRs1, fi_rs2FromRs2, fi_rs2FromZero;')
    A('')
    used = set()
    # ---- 输入：扁平 → 载体 ----
    A('  // ---- 输入打平 → struct / 数组 ----')
    covered = {i: set() for i in range(RW)}
    for d, w, n in ps:
        if d != 'input':
            continue
        m = re.match(r'io_in_(\d)_bits_(\w+)$', n)
        if m:
            i, f = int(m.group(1)), m.group(2)
            if f not in members:
                die('输入 %s 在 decoded_inst_t 里没有对应成员' % n)
            if members[f] != w:
                die('输入 %s 位宽 %d != struct 成员位宽 %d' % (n, w, members[f]))
            A('  assign in_b[%d].%s = %s;' % (i, member_ref(i, f), n))
            covered[i].add(f)
            used.add(n)
            continue
        if n not in fm:
            die('输入端口 %s 不在固定映射表里' % n)
        if fm[n] == n:          # 直接接核同名端口的标量：不写 assign（自己赋自己会成多驱动 X）
            used.add(n)
            continue
        A('  assign %s = %s;' % (fm[n], n))
        used.add(n)
    # 口 0 缺 lsrc_2..4：golden 消掉了(没人读)，补 0
    for i in range(RW):
        missing = sorted(set(members) - covered[i])
        allowed = {'lsrc_2', 'lsrc_3', 'lsrc_4'} if i == 0 else set()
        if set(missing) != allowed:
            die('口 %d 的 struct 成员没有来源: %s' % (i, missing))
        for f in missing:
            A("  assign in_b[%d].%s = '0;   // golden 口 0 没有 %s(firtool 消掉)，补 0" % (i, member_ref(i, f), f))
    # 口 5 没有 fusionInfo
    A("  assign fi_rs2FromRs1[%d] = 1'b0; assign fi_rs2FromRs2[%d] = 1'b0; assign fi_rs2FromZero[%d] = 1'b0;" % (RW - 1, RW - 1, RW - 1))
    A('')
    # ---- 输出 ----
    A('  // ---- 输出重组：直通字段来自 out_pt，计算字段来自核显式输出 ----')
    for d, w, n in ps:
        if d != 'output':
            continue
        m = re.match(r'io_out_(\d)_bits_(\w+)$', n)
        if m:
            i, f = int(m.group(1)), m.group(2)
            c = computed(i, f)
            if c is not None:
                A('  assign %s = %s;' % (n, c))
            else:
                if f not in members:
                    die('输出 %s 既不是计算字段、也不是 struct 直通成员' % n)
                if members[f] != w:
                    die('输出 %s 位宽 %d != struct 成员位宽 %d' % (n, w, members[f]))
                A('  assign %s = out_pt[%d].%s;' % (n, i, member_ref(i, f)))
            used.add(n)
            continue
        if n not in fm:
            die('输出端口 %s 不在固定映射表里' % n)
        if fm[n] != n:
            A('  assign %s = %s;' % (n, fm[n]))
        used.add(n)
    extra = set(fm) - used
    if extra:
        die('固定映射表里这些端口 golden 没有: %s' % sorted(extra))
    A('')
    A('  xs_Rename_core u_core (')
    A('    .clock(clock), .reset(reset),')
    A('    .io_redirect_valid(io_redirect_valid),')
    A('    .io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag),')
    A('    .io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value),')
    A('    .io_redirect_bits_level(io_redirect_bits_level),')
    A('    .io_redirect_bits_debugIsCtrl(io_redirect_bits_debugIsCtrl),')
    A('    .io_redirect_bits_debugIsMemVio(io_redirect_bits_debugIsMemVio),')
    A('    .io_rabCommits_isCommit(io_rabCommits_isCommit), .io_rabCommits_isWalk(io_rabCommits_isWalk),')
    A('    .io_rabCommits_commitValid(rab_cv), .io_rabCommits_walkValid(rab_wv),')
    A('    .io_rabCommits_info_rfWen(rab_rf), .io_rabCommits_info_fpWen(rab_fp),')
    A('    .io_rabCommits_info_vecWen(rab_vec), .io_rabCommits_info_v0Wen(rab_v0),')
    A('    .io_rabCommits_info_vlWen(rab_vl), .io_rabCommits_info_isMove(rab_mv),')
    A('    .io_singleStep(io_singleStep),')
    A('    .io_in_bits(in_b), .io_in_valid(in_v), .io_in_ready(in_r),')
    A('    .io_fusionInfo_rs2FromRs1(fi_rs2FromRs1), .io_fusionInfo_rs2FromRs2(fi_rs2FromRs2), .io_fusionInfo_rs2FromZero(fi_rs2FromZero),')
    A('    .io_intReadPorts(intRd), .io_fpReadPorts(fpRd), .io_vecReadPorts(vecRd),')
    A('    .io_v0ReadPorts(v0Rd), .io_vlReadPorts(vlRd),')
    A('    .io_intRenamePorts(intRP), .io_fpRenamePorts(fpRP), .io_vecRenamePorts(vecRP),')
    A('    .io_v0RenamePorts_wen(v0RP_wen), .io_v0RenamePorts_data(v0RP_data),')
    A('    .io_vlRenamePorts_wen(vlRP_wen), .io_vlRenamePorts_data(vlRP_data),')
    A('    .io_int_old_pdest(int_oldpd), .io_fp_old_pdest(fp_oldpd), .io_vec_old_pdest(vec_oldpd),')
    A('    .io_v0_old_pdest(v0_oldpd), .io_vl_old_pdest(vl_oldpd), .io_int_need_free(int_nf),')
    A('    .io_out_valid(out_v), .io_out_ready(out_r), .io_out_passthru(out_pt),')
    A('    .io_out_psrc(o_psrc), .io_out_pdest(o_pdest),')
    A('    .io_out_robIdx_flag(o_robIdx_flag), .io_out_robIdx_value(o_robIdx_value),')
    A('    .io_out_isMove_o(o_isMove), .io_out_snapshot(o_snapshot),')
    A('    .io_out_hasException(o_hasException), .io_out_srcType0(o_srcType0),')
    A('    .io_out_imm(o_imm), .io_out_debugInfo_renameTime(o_renameTime),')
    A('    .io_out_instrSize(o_instrSize), .io_out_dirtyFs(o_dirtyFs), .io_out_dirtyVs(o_dirtyVs),')
    A('    .io_out_debug_sim_trig(o_simTrig),')
    A('    .io_out_itype(o_itype), .io_out_iretire(o_iretire), .io_out_ilastsize(o_ilastsize),')
    A('    .io_out_lastUop_o(o_lastUop), .io_out_numUops_o(o_numUops), .io_out_numWB_o(o_numWB),')
    A('    .io_out_wfflags_o(o_wfflags), .io_out_numLsElem(o_numLsElem),')
    A('    .io_out_ftqPtr_flag_o(o_ftqFlag), .io_out_ftqPtr_value_o(o_ftqValue), .io_out_ftqOffset_o(o_ftqOff),')
    A('    .io_out_firstUop_o(o_firstUop), .io_out_waitForward_o(o_waitForward), .io_out_blockBackward_o(o_blockBackward),')
    A('    .io_snpt_snptDeq(io_snpt_snptDeq), .io_snpt_useSnpt(io_snpt_useSnpt),')
    A('    .io_snpt_snptSelect(io_snpt_snptSelect), .io_snpt_flushVec(flushv),')
    A('    .io_snptLastEnq_valid(io_snptLastEnq_valid), .io_snptLastEnq_bits_flag(io_snptLastEnq_bits_flag),')
    A('    .io_snptLastEnq_bits_value(io_snptLastEnq_bits_value), .io_snptIsFull(io_snptIsFull),')
    A('    .io_debug_int_rat(dbg_int_rat),')
    A('    .io_stallReason_in_reason(sr_in), .io_stallReason_out_backReason_valid(io_stallReason_out_backReason_valid),')
    A('    .io_stallReason_in_backReason_valid(io_stallReason_in_backReason_valid),')
    A('    .io_stallReason_in_backReason_bits(io_stallReason_in_backReason_bits),')
    A('    .io_stallReason_out_reason(sr_out), .io_perf_value(perf_v)')
    A('  );')
    A('endmodule')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
# 只读 CSR 读(csrr)豁免路径要撞上白名单里的地址才有分辨力：这里把 golden 两张白名单
# (rename_pkg 注释里的 27/15 个)连同几个不在名单上的地址一起做成采样池。
CSR_POOL = ['12\'h001', '12\'h003', '12\'h009', '12\'h00F', '12\'h008', '12\'h100', '12\'h200', '12\'h300',
            '12\'h600', '12\'h744', '12\'h7B0', '12\'hC21', '12\'h351', '12\'h151', '12\'h251', '12\'hFB0',
            '12\'hDB0', '12\'hEB0', '12\'h35C', '12\'h15C', '12\'h25C', '12\'h344', '12\'h144', '12\'h244',
            '12\'h644', '12\'h645', '12\'h309', '12\'h305', '12\'hC00', '12\'h180', '12\'hF14', '12\'h000']


def stim_expr(name, w):
    """按端口名给随机激励表达式(偏置的理由写在旁边)。"""
    if re.match(r'io_in_\d_bits_(ldest|lsrc_\d)$', name):
        return "rl()"                                   # 窄域 0..8：提高同拍旁路命中率
    if re.match(r'io_in_\d_bits_srcType_\d$', name):
        return "rst4()"                                 # one-hot 风格 srcType 采样
    if re.search(r'ReadPorts_\d_\d$|_old_pdest_\d$|io_debug_int_rat_\d+$', name):
        return "rp()"                                   # 物理号窄域 0..40
    if re.match(r'io_in_\d_bits_instr$', name):
        return "rinstr()"                               # 含 csrr 形态 / SIM_TRIG 偏置
    if re.match(r'io_in_\d_bits_fuType$', name):
        return "rfutype()"
    if re.match(r'io_in_\d_bits_(debug_fuType)$', name):
        return "$urandom_range(0,40)"
    if re.match(r'io_in_\d_bits_uopSplitType$', name):
        return "($urandom_range(0,99)<20) ? 6'h0 : ($urandom_range(0,99)<15) ? (6'h35+$urandom_range(0,2)) : $urandom_range(0,63)"
    if re.match(r'io_in_\d_bits_selImm$', name):
        return "rst4()"                                 # 撞 U(2) / LUI32(B) 之外也要有杂值
    if re.match(r'io_in_\d_bits_exceptionVec_\d+$', name):
        return "($urandom_range(0,99)<4)"
    if re.match(r'io_in_\d_valid$', name):
        return "($urandom_range(0,99)<80)"
    if re.match(r'io_out_\d_ready$', name):
        return "($urandom_range(0,99)<85)"
    if name == 'io_redirect_valid':
        return "($urandom_range(0,99)<3)"
    if name in ('io_redirect_bits_robIdx_value', 'io_snptLastEnq_bits_value'):
        return "$urandom_range(0,159)"
    if name == 'io_rabCommits_isWalk':
        return "($urandom_range(0,99)<10)"
    if name == 'io_singleStep':
        return "($urandom_range(0,99)<5)"
    if re.match(r'io_snpt_flushVec_\d$', name):
        return "($urandom_range(0,99)<5)"
    if re.match(r'io_fusionInfo_\d_\w+$', name):
        return "($urandom_range(0,99)<8)"
    if re.match(r'io_in_\d_bits_vpu_isVleff$', name):
        return "($urandom_range(0,99)<30)"
    if w == 1:
        return "$urandom_range(0,1)"
    if w <= 32:
        return "$urandom_range(0,%d)" % ((1 << w) - 1) if w < 31 else "$urandom"
    return "{%s}" % ', '.join(['$urandom'] * ((w + 31) // 32))   # 宽字段：拼多个 $urandom


def make_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ps if d == 'output']
    L = []
    A = L.append
    A('// ★本文件由 gen_rename.py 生成，改请改生成器★')
    A('// Rename 双例化逐拍比对：golden Rename vs 重写 Rename_xs，全部 %d 个输出口 + 层次探针。' % len(outs))
    A('// 暖机窗口(WARM_CYCLES)：五个 FreeList 的快照槽 payload 不复位，+vcs+initreg+random 下两侧')
    A('//   初值各异；窗口内用确定性激励让每个槽都被真实写过(见激励块里的说明)。')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clk = 0, rst;')
    A('  int errors = 0, checks = 0;')
    A('  localparam int WARM_CYCLES = 64;')
    A('  int cyc = 0;')
    A('  always @(negedge clk) if (!rst) cyc <= cyc + 1;')
    A('  always #5 clk = ~clk;')
    A('')
    for w, n in ins:
        A('  logic %s%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', n))
    for w, n in outs:
        for p in ('g', 'i'):
            A('  logic %s%s_%s;' % (('[%d:0] ' % (w - 1)) if w > 1 else '', p, n))
    A('')

    def inst(m, p):
        c = ['.clock(clk)', '.reset(rst)']
        c += ['.%s(%s)' % (n, n) for _, n in ins]
        c += ['.%s(%s_%s)' % (n, p, n) for _, n in outs]
        return '  %s %s_u (\n    %s);' % (m, p, ',\n    '.join(c))
    A(inst(MOD, 'g'))
    A(inst(MOD + '_xs', 'i'))
    A('')
    A("  function automatic logic [5:0] rl(); return 6'($urandom_range(0,8)); endfunction")
    A("  function automatic logic [7:0] rp(); return 8'($urandom_range(0,40)); endfunction")
    A('  function automatic logic [3:0] rst4();')
    A('    int x; x = $urandom_range(0,6);')
    A("    case (x) 0: return 4'h0; 1: return 4'h1; 2: return 4'h2; 3: return 4'h4; 4: return 4'h8; default: return 4'h1; endcase")
    A('  endfunction')
    A('  // fuType：偏置覆盖 alu(lui32 融合)/ldu(fused-lui-load)/fence/jmp、向量访存(31..34)、')
    A('  //   vfalu(24)/vipu(18)(dirtyVs 特例)、csr(5)(itype Xret)，其余杂值。')
    A('  function automatic logic [34:0] rfutype();')
    A('    int x; x = $urandom_range(0,99);')
    A("    if (x < 25) begin case ($urandom_range(0,3)) 0: return 35'h40; 1: return 35'h8000; 2: return 35'h200; default: return 35'h1; endcase end")
    A("    else if (x < 55) begin case ($urandom_range(0,4)) 0: return 35'h1<<31; 1: return 35'h1<<32; 2: return 35'h1<<33; 3: return 35'h1<<34; default: return 35'h1<<24; endcase end")
    A("    else if (x < 70) return ($urandom_range(0,1)==0) ? (35'h1<<18) : (35'h1<<5);")
    A("    else return 35'($urandom_range(0,40));")
    A('  endfunction')
    A('  // instr：10% csrr 形态(SYSTEM + funct3∈{2,3,6,7} + rs1=x0 + 白名单内外的 csr 地址)，')
    A('  //   2% SIM_TRIG HINT，其余全随机。')
    A('  function automatic logic [31:0] rinstr();')
    A('    int x; logic [11:0] csr; logic [2:0] f3;')
    A('    x = $urandom_range(0,99);')
    A("    if (x < 2) return 32'hDFA92013;")
    A('    if (x < 12) begin')
    A('      case ($urandom_range(0,%d))' % (len(CSR_POOL) - 1))
    for k, c in enumerate(CSR_POOL):
        A('        %d: csr = %s;' % (k, c))
    A('        default: csr = 12\'h000;')
    A('      endcase')
    A("      case ($urandom_range(0,3)) 0: f3 = 3'd2; 1: f3 = 3'd3; 2: f3 = 3'd6; default: f3 = 3'd7; endcase")
    A("      return {csr, 5'd0, f3, 5'($urandom_range(0,31)), 7'h73};")
    A('    end')
    A('    return $urandom;')
    A('  endfunction')
    A('  always @(negedge clk) begin')
    A('    if (rst) begin')
    for w, n in ins:
        A('      %s <= 0;' % n)
    A('    end else begin')
    for w, n in ins:
        A('      %s <= %s;' % (n, stim_expr(n, w)))
    A('      // ★暖机窗口：确定性地把五个 FreeList 的 4 个快照槽都写一遍★')
    A('      //   快照槽 payload 是不复位的 unpacked 数组，+vcs+initreg+random 不给它们初值(那是 initmem 的事)，')
    A('      //   golden 那边却是被 initreg 随机化的标量寄存器 —— 没写过的槽一旦被 useSnpt 选中，impl 出 X、')
    A('      //   golden 出随机值(2026-09-27 seed=1 实测：8400 拍处 canAllocate 变 X 后一路错下去)。')
    A('      //   这里让 genSnapshot 每隔一拍触发一次(允许条件全部拉满、不分配寄存器以保持 canOut)，')
    A('      //   并同时 deq 腾位，64 拍内 4 个槽都被真实写过；之后再放开随机。')
    A('      if (cyc < WARM_CYCLES) begin')
    warm = {
        'io_redirect_valid': "1'b0", 'io_rabCommits_isWalk': "1'b0", 'io_rabCommits_isCommit': "1'b1",
        'io_singleStep': "1'b0", 'io_snptLastEnq_valid': "1'b0", 'io_snptIsFull': "1'b0",
        'io_snpt_useSnpt': "1'b0", 'io_snpt_snptDeq': "1'b1",
    }
    for k in range(4):
        warm['io_snpt_flushVec_%d' % k] = "1'b0"
    for i in range(CW):
        warm['io_rabCommits_commitValid_%d' % i] = "1'b1"
        for f in ('rfWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen', 'isMove'):
            warm['io_rabCommits_info_%d_%s' % (i, f)] = "1'b0"
    for i in range(RW):
        warm['io_in_%d_valid' % i] = "1'b1"
        warm['io_out_%d_ready' % i] = "1'b1"
        for f, v in (('firstUop', "1'b1"), ('lastUop', "1'b1"), ('canRobCompress', "1'b0"),
                     ('trigger', "4'h0"), ('preDecodeInfo_brType', "2'h2"), ('isMove', "1'b0"),
                     ('rfWen', "1'b0"), ('fpWen', "1'b0"), ('vecWen', "1'b0"), ('v0Wen', "1'b0"), ('vlWen', "1'b0")):
            warm['io_in_%d_bits_%s' % (i, f)] = v
        for k in range(24):
            warm['io_in_%d_bits_exceptionVec_%d' % (i, k)] = "1'b0"
    names = {n for _, n in ins}
    for k in sorted(warm):
        if k not in names:
            die('暖机覆盖表里的 %s 不是 golden 输入' % k)
        A('        %s <= %s;' % (k, warm[k]))
    A('      end')
    A('    end')
    A('  end')
    A('')
    A('  always @(negedge clk) if (!rst) begin')
    A('    #4; checks++;')
    for w, n in outs:
        A('    if (!$isunknown(g_%s) && g_%s !== i_%s) begin errors++;' % (n, n, n))
        A('      if(errors<=120) $display("[%%0t] %s g=%%h i=%%h", $time, g_%s, i_%s); end' % (n, n, n))
    A('    // 层次探针：robIdxHead / 五个 FreeList 的 headPtrOH(golden 扁平名 vs 核层次)')
    A('    if (!$isunknown(g_u.robIdxHead_value) && g_u.robIdxHead_value !== i_u.u_core.robIdxHead_value) begin errors++;')
    A('      if(errors<=120) $display("[%0t] PROBE robIdxHead_value g=%h i=%h", $time, g_u.robIdxHead_value, i_u.u_core.robIdxHead_value); end')
    for fl in ('intFreeList', 'fpFreeList', 'vecFreeList', 'v0FreeList', 'vlFreeList'):
        A('    if (!$isunknown(g_u.%s.headPtrOH) && g_u.%s.headPtrOH !== i_u.u_core.%s.u_core.headPtrOH) begin errors++;' % (fl, fl, fl))
        A('      if(errors<=120) $display("[%%0t] PROBE %s.headPtrOH mismatch", $time); end' % fl)
    A('  end')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    rst = 1; repeat (8) @(posedge clk); rst = 0;')
    A('    repeat (NCYCLES) @(posedge clk);')
    A('    $display("checks=%0d errors=%0d", checks, errors);')
    A('    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


def main(argv):
    check = '--check' in argv
    ps = ports()
    members = struct_members()
    wrapper = make_wrapper(ps, members)
    text = RTL.read_text()
    if MARK not in text:
        die('rtl/backend/Rename.sv 里找不到 wrapper 标记行')
    head = text[:text.index(MARK)]
    new_rtl = head + wrapper
    tb = make_tb(ps)
    outputs = {RTL: new_rtl, HERE / 'tb.sv': tb}
    stale = []
    for path, content in outputs.items():
        if check:
            if not path.exists() or path.read_text() != content:
                stale.append(path)
        else:
            path.write_text(content)
            print('生成', path.relative_to(REPO))
    if check:
        if stale:
            print('gen_rename --check: 以下产物与生成器不一致：')
            for p in stale:
                print('  ' + str(p.relative_to(REPO)))
            return 1
        print('gen_rename --check: %d 个产物与生成器一致' % len(outputs))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
