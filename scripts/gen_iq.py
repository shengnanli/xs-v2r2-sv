#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_iq.py —— 生成 IssueQueue* 家族的 golden 同名 wrapper（rtl/backend/IssueQueue<V>.sv）

为什么用生成器：每个 IQ wrapper 端口 456–721 个、条目阵列实例连线 600–870 个，逐位与 golden
同名同宽，手抄不可能不出错。可读逻辑全部在手写核 rtl/backend/xs_IssueQueue_core.sv 里；
本脚本只做**连线**，而且连线规则 fail-closed：

  golden 里每个子模块输入端口的驱动表达式，必须落进下面四类之一，否则生成失败：
    (1) 顶层端口（可带位选/段选）或常量             —— 原样接（纯连线）
    (2) 另一个子模块的输出（golden 里 `_inst_io_x` 或具名线）—— 接 wrapper 的同源线
    (3) 只由 (1)(2) 与拼接/复制/位选构成的表达式       —— 纯连线，逐个标识符翻译后照接
    (4) 规则表 GLUE 里列出的 golden 胶合信号           —— 接核的对应输出
  含任何运算符（& | ^ ~ ? + - == …）而又不在规则表里的表达式 —— 报错。
  也就是说：golden 的逻辑一行都不会被抄进 wrapper。

deqDelay（出队打一拍）的负载：按 golden 寄存器声明顺序逐字段拼包送核，核打一拍后拆包回端口；
每个字段的 deqBeforeDly 来源同样走上面四类规则。

用法:
  python3 scripts/gen_iq.py <Variant...>          # 写 rtl/backend/IssueQueue<V>.sv
  python3 scripts/gen_iq.py --check <Variant...>  # 只比对，不写盘；不一致非零退出
  Variant 省略 = 全部已登记变体（VARIANTS）
"""
import argparse
import pathlib
import re
import sys

GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = pathlib.Path(__file__).resolve().parents[1]
OUT = REPO / 'rtl' / 'backend'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$')

# -----------------------------------------------------------------------------
# 每个变体的"表外事实"：golden 端口表里读不出、必须从 Chisel 配置核对的参数。
# 其余参数（条目数、分段、口数、源数、FuType 保留位、接受掩码……）全部从 golden 量。
#   lat: MultiWakeupQueue 的 getDeqLat 表 [(FuType 位, 延迟)]；无 lat 端口的变体为 []
#   wk_wen: MWQ 出口的写使能端口名（wakeupToIQ 的 xxWen = valid && wen）
# -----------------------------------------------------------------------------
VARIANTS = {
    'IssueQueueAluCsrFenceDiv': dict(lat=[], wk_wen='rfWen'),
}


def die(msg):
    raise SystemExit(f'gen_iq: {msg}')


# ============================================================================
# golden 解析
# ============================================================================
def module_text(name):
    t = (GOLDEN / f'{name}.sv').read_text()
    m = re.search(r'^module %s\(\n(.*?)^\);\n(.*?)^endmodule' % re.escape(name), t, re.M | re.S)
    if not m:
        die(f'{name}: 找不到模块')
    return m.group(1), m.group(2)


def parse_ports(header, name):
    ports = []
    for l in header.splitlines():
        m = PORT_RE.match(l)
        if not m:
            die(f'{name}: 端口行解析失败 {l!r}')
        ports.append((m.group(1), int(m.group(2)) + 1 if m.group(2) else 1, m.group(3)))
    return ports


def norm(e):
    return ' '.join(e.split())


def parse_body(body):
    """返回 wires{name: expr}（含 `wire x = e;` 与 `assign x = e;`）、insts[(mod, inst, [(port, expr)])]、
    regs[(name, width)]（声明顺序）、reg_src{reg: expr}（always 块里的 `reg <= expr;`）。"""
    # 去掉 `ifndef SYNTHESIS / ENABLE_INITIAL_REG_ 块（断言与随机初值）
    body = re.sub(r'^[ \t]*`ifndef SYNTHESIS.*?`endif // not def SYNTHESIS\n', '', body, flags=re.S | re.M)
    body = re.sub(r'^[ \t]*`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '', body,
                  flags=re.S | re.M)
    wires = {}
    for m in re.finditer(r'^\s+wire\s+(?:\[\d+:0\]\s+)?(\w+)\s*=\s*(.*?);\s*$', body, re.M | re.S):
        wires[m.group(1)] = norm(m.group(2))
    for m in re.finditer(r'^\s+assign\s+(\w+)\s*=\s*(.*?);\s*$', body, re.M | re.S):
        wires[m.group(1)] = norm(m.group(2))
    wire_w = {}
    for m in re.finditer(r'^\s+wire\s+(?:\[(\d+):0\]\s+)?(\w+)\b', body, re.M):
        wire_w[m.group(2)] = int(m.group(1)) + 1 if m.group(1) else 1
    regs = [(m.group(2), int(m.group(1)) + 1 if m.group(1) else 1)
            for m in re.finditer(r'^\s+reg\s+(?:\[(\d+):0\]\s+)?(\w+);', body, re.M)]
    reg_src = {}
    for m in re.finditer(r'^\s+(\w+)\s*<=\s*(.*?);\s*$', body, re.M | re.S):
        reg_src.setdefault(m.group(1), norm(m.group(2)))
    insts = []
    for m in re.finditer(r'^  ([A-Z]\w*) (\w+) \(\n(.*?)^  \);', body, re.M | re.S):
        conns = []
        for it in re.split(r'\n(?=\s{4}\.)', m.group(3).rstrip()):
            mm = re.match(r'\s*\.(\w+)\s*\((.*)\),?\s*$', it, re.S)
            if not mm:
                die(f'实例 {m.group(2)} 连线解析失败: {it!r}')
            conns.append((mm.group(1), norm(mm.group(2))))
        insts.append((m.group(1), m.group(2), conns))
    return wires, wire_w, regs, reg_src, insts


# ============================================================================
# 表达式分类与翻译
# ============================================================================
TOKEN_RE = re.compile(r"\s*(\d+'h[0-9A-Fa-f]+|\d+'b[01]+|\d+|[A-Za-z_]\w*|\[|\]|:|\{|\}|,|.)")
CONST_RE = re.compile(r"^\d+'[hb][0-9A-Fa-f]+$")


def tokens(e):
    out, pos = [], 0
    while pos < len(e):
        m = TOKEN_RE.match(e, pos)
        if not m:
            die(f'无法分词: {e!r}')
        if m.group(1).strip():
            out.append(m.group(1))
        pos = m.end()
    return out


class Ctx:
    def __init__(self, v):
        self.v = v
        hdr, body = module_text(v)
        self.ports = parse_ports(hdr, v)
        self.pdir = {n: d for d, _, n in self.ports}
        self.pw = {n: w for _, w, n in self.ports}
        self.wires, self.wire_w, self.regs, self.reg_src, self.insts = parse_body(body)
        self.child_ports = {}
        for mod, _, _ in self.insts:
            if mod not in self.child_ports:
                h, _ = module_text(mod)
                self.child_ports[mod] = parse_ports(h, mod)
        # golden 名 -> wrapper 线名（子模块输出）
        self.child_out = {}
        self.child_out_w = {}
        for mod, inst, conns in self.insts:
            cp = {n: (d, w) for d, w, n in self.child_ports[mod]}
            for port, e in conns:
                if port not in cp:
                    die(f'{inst}.{port} 不在 {mod} 端口表里')
                d, w = cp[port]
                if d == 'output' and e and not e.startswith('/*'):
                    if e in self.pdir:                   # 直接接顶层输出端口
                        continue
                    if not re.fullmatch(r'\w+', e):
                        die(f'{inst}.{port} 输出接了表达式 {e!r}')
                    self.child_out[e] = f'{inst}_{port}'
                    self.child_out_w[f'{inst}_{port}'] = w
        self.glue = {}      # golden 胶合名/表达式 -> 核信号（由 build_glue 填）

    # ---- 纯连线翻译 ----
    def res(self, e, why):
        e = norm(e)
        if e in self.glue:
            return self.glue[e]
        toks = tokens(e)
        ops = [t for t in toks if not (re.fullmatch(r'\w+', t) or t in '[]:{},' or CONST_RE.match(t))]
        if ops:
            die(f'{self.v}: {why}: 表达式含运算且不在胶合规则表里: {e!r}')
        out = []
        for j, t in enumerate(toks):
            if re.fullmatch(r'[A-Za-z_]\w*', t):
                r = self.res_name(t, why)
                if j + 1 < len(toks) and toks[j + 1] == '[' and not re.fullmatch(r'[\w\[\]]+', r):
                    die(f'{self.v}: {why}: 对非简单名 {r!r} 做位选')
                out.append(r)
            else:
                out.append(t)
        s = ''
        for t in out:
            s += (t + ' ') if t == ',' else t
        return s.strip()

    def res_name(self, n, why):
        if n in self.glue:
            return self.glue[n]
        if n in self.pdir:
            return n
        if n in self.child_out:
            return self.child_out[n]
        if n in self.wires:
            return self.res(self.wires[n], f'{why} <- {n}')
        die(f'{self.v}: {why}: 名字 {n} 既不是端口、子模块输出、胶合规则，也没有定义式')


# ============================================================================
# 变体参数（从 golden 量）
# ============================================================================
def measure(c):
    en = 'Entries' + c.v[len('IssueQueue'):]
    ent = [x for x in c.insts if x[0] == en]
    if len(ent) != 1:
        die(f'{c.v}: 条目阵列实例数 != 1')
    ep = {n: (d, w) for d, w, n in c.child_ports[en]}
    P = {}
    P['N_ENTRIES'] = ep['io_valid'][1]
    P['N_DEQ'] = len([n for n in ep if re.fullmatch(r'io_deqSelOH_\d+_bits', n)])
    P['N_ENQ'] = len([n for n in ep if re.fullmatch(r'io_enq_\d+_valid', n)])
    P['N_SIMP'] = ep['io_simpEntryOldestSel_0_bits'][1]
    P['N_COMP'] = ep['io_compEntryOldestSel_0_bits'][1]
    P['N_SRC'] = len([n for n in ep if re.fullmatch(r'io_enq_0_bits_status_srcStatus_\d+_srcType', n)])
    P['PSRC_W'] = ep['io_enq_0_bits_status_srcStatus_0_psrc'][1]
    P['LD_CNT'] = len([n for n in ep if re.fullmatch(r'io_enq_0_bits_status_srcStatus_0_srcLoadDependency_\d+', n)])
    P['N_EXU'] = len([n for n in ep if re.fullmatch(r'io_exuSources_0_\d+_value', n)])
    P['EXU_W'] = ep['io_exuSources_0_0_value'][1] if P['N_EXU'] else 1
    if P['N_ENTRIES'] != P['N_ENQ'] + P['N_SIMP'] + P['N_COMP']:
        die(f'{c.v}: 条目数 != enq+simp+comp')
    # 每口能接受的 FuType 位：deqCanIssue_<d> 或 deqCanAcceptVec_<d>_0 里出现的 fuTypeVec_0[k]
    acc = []
    for d in range(P['N_DEQ']):
        e = c.wires.get(f'deqCanIssue_{d}', '')
        bits = {int(x) for x in re.findall(r'fuTypeVec_0\[(\d+)\]', e)}
        if not bits:
            bits = {int(x) for x in re.findall(r'fuTypeVec_0\[(\d+)\]', c.wires.get(f'deqCanAcceptVec_{d}_0', ''))}
        if not bits:
            die(f'{c.v}: 口 {d} 的接受 FuType 位量不到')
        acc.append(sum(1 << b for b in bits))
    P['ACCEPT'] = acc
    P['IQIDX_W'] = c.pw.get('io_deqDelay_0_bits_common_iqIdx')
    vc = [d for d in range(P['N_DEQ']) if f'io_validCntDeqVec_{d}' in c.pw]
    P['HAS_VCNT'] = [1 if d in vc else 0 for d in range(P['N_DEQ'])]
    P['VCNT_OUT_W'] = c.pw[f'io_validCntDeqVec_{vc[0]}'] if vc else 1
    return P, en


# ============================================================================
# 胶合规则表：golden 胶合名 -> 核信号
# ============================================================================
def build_glue(c, P, en):
    g = c.glue
    for e in range(P['N_ENQ']):
        g[f's0_doEnqSelValidVec_{e}'] = f'core_enq_do[{e}]'
        g[f'io_enq_{e}_ready_0'] = f'core_enq_ready[{e}]'
    for d in range(P['N_DEQ']):
        g[f'deqSelValidVec_{d}'] = f'core_sel_valid[{d}]'
        g[f'deqBeforeDly_{d}_bits_addrOH'] = f'core_sel_oh[{d}]'
        g[f'deqBeforeDly_{d}_valid'] = f'core_deq_valid[{d}]'
        g[f'deqBeforeDly_{d}_ready'] = "1'h1"            # Chisel: deq.ready := true.B
        g[f'deqBeforeDly_{d}_bits_common_iqIdx'] = f'core_deq_iq_idx[{d}]'
        g[f'deqBeforeDly_{d}_bits_common_perfDebugInfo_selectTime'] = f'core_deq_select_time[{d}]'
        g[f'deqBeforeDly_{d}_bits_common_perfDebugInfo_issueTime'] = f'core_deq_issue_time[{d}]'
        for s in range(P['N_SRC']):
            g[f'deqBeforeDly_{d}_bits_common_dataSources_{s}_value'] = f'core_deq_data_src[{d}][{s}]'
        for s in range(P['N_EXU']):
            g[f'deqBeforeDly_{d}_bits_common_exuSources_{s}_value'] = f'core_deq_exu_src[{d}][{s}]'
        for k in range(P['LD_CNT']):
            g[f'deqBeforeDly_{d}_bits_common_loadDependency_{k}'] = f'core_deq_ld_dep[{d}][{k}]'
        g[f'deqCanIssue_{d}[{P["N_ENQ"] - 1}:0]'] = f'core_age_enq_req[{d}]'
        g[f'simpAgeDetectRequest_{d}'] = f'core_age_simp_req[{d}]'
        g[f'|simpAgeDetectRequest_{d}'] = f'core_simp_oldest_valid[{d}]'
        hi, lo = P['N_ENTRIES'] - 1, P['N_ENQ'] + P['N_SIMP']
        g[f'_deqCanIssue_{d}_{hi}to{lo}'] = f'core_age_comp_req[{d}]'
        g[f'|_deqCanIssue_{d}_{hi}to{lo}'] = f'core_comp_oldest_valid[{d}]'
        if P['HAS_VCNT'][d]:
            g[f'@out:io_validCntDeqVec_{d}'] = f'core_valid_cnt[{d}]'
    for k in range(P['N_DEQ'], P['N_DEQ'] + P['N_ENQ']):
        g[f'simpAgeDetectRequest_{k}'] = f'core_age_simp_req[{k}]'
    # 条目阵列入队状态里由核翻译的字段（按端口名）
    for e in range(P['N_ENQ']):
        for s in range(P['N_SRC']):
            pre = f'{en}.io_enq_{e}_bits_status_srcStatus_{s}_'
            g[pre + 'srcState'] = f'core_st_src_state[{e}][{s}]'
            g[pre + 'dataSources_value'] = f'core_st_data_src[{e}][{s}]'
            for k in range(P['LD_CNT']):
                g[pre + f'srcLoadDependency_{k}'] = f'core_st_src_ld[{e}][{s}][{k}]'


# ============================================================================
# 生成
# ============================================================================
def sv_w(w):
    return f'[{w - 1}:0] ' if w > 1 else ''


def gen(v):
    extra = VARIANTS[v]
    c = Ctx(v)
    P, en = measure(c)
    build_glue(c, P, en)
    L = []
    hdr, _ = module_text(v)
    ninst = {}
    for mod, _, _ in c.insts:
        ninst[mod] = ninst.get(mod, 0) + 1

    # ---- deqDelay 负载：寄存器声明顺序 ----
    payload = {d: [] for d in range(P['N_DEQ'])}
    for r, w in c.regs:
        m = re.fullmatch(r'deqDelay_(\d+)_(\w+)', r)
        if not m or m.group(2) == 'valid':
            continue
        d, f = int(m.group(1)), m.group(2)
        src = c.reg_src.get(r)
        if src != f'deqBeforeDly_{d}_{f}':
            die(f'{v}: {r} 的次态不是 deqBeforeDly_{d}_{f}: {src!r}')
        payload[d].append((f, w))
    W = [sum(w for _, w in payload[d]) for d in range(P['N_DEQ'])]

    # ---- 文件头 ----
    L.append(f'// {v}.sv —— 发射队列 {v[len("IssueQueue"):]}（golden 同名 wrapper）')
    L.append('// -----------------------------------------------------------------------------')
    L.append('// 调度逻辑全部在 xs_IssueQueue_core.sv（家族共享参数化核）；本文件只做连线：')
    L.append('//   golden 端口表 + golden 同名子模块例化（已签核件）+ 核的数组接口接线 + deqDelay 负载拼包/拆包。')
    L.append('//')
    L.append('// 本变体规模（全部从 G1 golden 量得）：')
    L.append(f'//   条目 {P["N_ENTRIES"]} = enq {P["N_ENQ"]} + simp {P["N_SIMP"]} + comp {P["N_COMP"]}，'
             f'发射口 {P["N_DEQ"]}，源 {P["N_SRC"]}，loadDependency {P["LD_CNT"]} 路，exuSources {P["N_EXU"]}')
    for d in range(P['N_DEQ']):
        bits = [b for b in range(35) if P['ACCEPT'][d] >> b & 1]
        L.append(f'//   口 {d}：接受 FuType 位 {bits}；deqDelay 负载 {len(payload[d])} 个字段 / {W[d]} 位')
    L.append('//   子模块：' + '，'.join(f'{m}×{n}' for m, n in ninst.items()))
    L.append('//')
    L.append('// 自动生成：scripts/gen_iq.py —— 勿手改')
    L.append('// =============================================================================')
    L.append(f'module {v}(')
    L.append(hdr.rstrip('\n'))
    L.append(');')
    L.append('')

    # ---- 子模块输出线 ----
    L.append('  // ---- 子模块输出线（名字 = <实例>_<端口>）----')
    for wn, w in c.child_out_w.items():
        L.append(f'  logic {sv_w(w)}{wn};')
    L.append('')

    # ---- 核接口数组 ----
    N, NE, ND, NS = P['N_ENTRIES'], P['N_ENQ'], P['N_DEQ'], P['N_SRC']
    LDs, EXs = max(P['LD_CNT'], 1), max(P['N_EXU'], 1)
    busy = {d: [] for d in range(ND)}
    for mod, inst, conns in c.insts:
        m = re.fullmatch(r'(?:fu|int|fp|vf|v0|vl)(?:Wb)?BusyTableRead_(\d+)', inst)
        if m:
            busy[int(m.group(1))].append(f'{inst}_io_out_fuBusyTableMask')
    NB = max(1, max(len(b) for b in busy.values()))
    decl = f'''  // ---- 核接口 ----
  logic             core_enq_valid     [{NE}];
  logic             core_enq_ready     [{NE}];
  logic             core_enq_do        [{NE}];
  logic [3:0]       core_enq_src_type  [{NE}][{NS}];
  logic [{P["PSRC_W"] - 1}:0]       core_enq_psrc      [{NE}][{NS}];
  logic             core_enq_src_state [{NE}][{NS}];
  logic [1:0]       core_enq_src_ld    [{NE}][{NS}][{LDs}];
  logic             core_st_src_state  [{NE}][{NS}];
  logic [3:0]       core_st_data_src   [{NE}][{NS}];
  logic [1:0]       core_st_src_ld     [{NE}][{NS}][{LDs}];
  logic [{N - 1}:0]      core_ent_valid;
  logic [{N - 1}:0]      core_ent_issued;
  logic [{N - 1}:0]      core_ent_can_issue;
  logic [34:0]      core_ent_fu_type   [{N}];
  logic [3:0]       core_ent_data_src  [{N}][{NS}];
  logic [{P["EXU_W"] - 1}:0]       core_ent_exu_src   [{N}][{EXs}];
  logic [1:0]       core_ent_ld_dep    [{N}][{LDs}];
  logic             core_ent_cancel_deq [{ND}];
  logic [{N - 1}:0]      core_busy_mask     [{ND}][{NB}];
  logic [{NE - 1}:0]       core_age_enq_req   [{ND}];
  logic [{P["N_SIMP"] - 1}:0]       core_age_simp_req  [{ND + NE}];
  logic [{P["N_COMP"] - 1}:0]      core_age_comp_req  [{ND}];
  logic [{NE - 1}:0]       core_age_enq_out   [{ND}];
  logic [{P["N_SIMP"] - 1}:0]       core_age_simp_out  [{ND + NE}];
  logic [{P["N_COMP"] - 1}:0]      core_age_comp_out  [{ND}];
  logic             core_sel_valid     [{ND}];
  logic [{N - 1}:0]      core_sel_oh        [{ND}];
  logic             core_simp_oldest_valid [{ND}];
  logic             core_comp_oldest_valid [{ND}];
  logic             core_deq_valid     [{ND}];
  logic [{P["IQIDX_W"] - 1}:0]       core_deq_iq_idx    [{ND}];
  logic [3:0]       core_deq_data_src  [{ND}][{NS}];
  logic [{P["EXU_W"] - 1}:0]       core_deq_exu_src   [{ND}][{EXs}];
  logic [1:0]       core_deq_ld_dep    [{ND}][{LDs}];
  logic [63:0]      core_deq_select_time [{ND}];
  logic [63:0]      core_deq_issue_time  [{ND}];
  logic [{W[0] - 1}:0]    core_deq0_payload;
  logic [{(W[1] if ND > 1 else 1) - 1}:0]    core_deq1_payload;
  logic             core_dly_valid     [{ND}];
  logic [{W[0] - 1}:0]    core_dly0_payload;
  logic [{(W[1] if ND > 1 else 1) - 1}:0]    core_dly1_payload;
  logic             core_dly_ready     [{ND}];
  logic [{P["VCNT_OUT_W"] - 1}:0]       core_valid_cnt     [{ND}];
  logic [34:0]      core_wk_enq_fu_type;
  logic             core_wk_enq_lat;
  logic             core_wk_deq_valid;
  logic             core_wk_deq_wen;
  logic             core_wk_out_wen;
'''
    L.append(decl)

    # ---- 核输入接线 ----
    A = []
    ep = {n for _, _, n in c.child_ports[en]}
    einst = [x for x in c.insts if x[0] == en][0][1]
    for e in range(NE):
        A.append(f'  assign core_enq_valid[{e}] = io_enq_{e}_valid;')
        for s in range(NS):
            A.append(f'  assign core_enq_src_type[{e}][{s}] = io_enq_{e}_bits_srcType_{s};')
            A.append(f'  assign core_enq_psrc[{e}][{s}] = io_enq_{e}_bits_psrc_{s};')
            A.append(f'  assign core_enq_src_state[{e}][{s}] = io_enq_{e}_bits_srcState_{s};')
            for k in range(LDs):
                A.append(f'  assign core_enq_src_ld[{e}][{s}][{k}] = ' +
                         (f'io_enq_{e}_bits_srcLoadDependency_{s}_{k};' if P['LD_CNT'] else "2'h0;"))
    A.append(f'  assign core_ent_valid = {einst}_io_valid;')
    A.append(f'  assign core_ent_issued = {einst}_io_issued;')
    A.append(f'  assign core_ent_can_issue = {einst}_io_canIssue;')
    for i in range(N):
        A.append(f'  assign core_ent_fu_type[{i}] = {einst}_io_fuType_{i};')
        for s in range(NS):
            A.append(f'  assign core_ent_data_src[{i}][{s}] = {einst}_io_dataSources_{i}_{s}_value;')
        for s in range(EXs):
            A.append(f'  assign core_ent_exu_src[{i}][{s}] = ' +
                     (f'{einst}_io_exuSources_{i}_{s}_value;' if P['N_EXU'] else "'0;"))
        for k in range(LDs):
            A.append(f'  assign core_ent_ld_dep[{i}][{k}] = ' +
                     (f'{einst}_io_loadDependency_{i}_{k};' if P['LD_CNT'] else "2'h0;"))
    for d in range(ND):
        A.append(f'  assign core_ent_cancel_deq[{d}] = ' +
                 (f'{einst}_io_cancelDeqVec_{d};' if f'io_cancelDeqVec_{d}' in ep else "1'h0;"))
        for b in range(NB):
            A.append(f'  assign core_busy_mask[{d}][{b}] = ' + (busy[d][b] + ';' if b < len(busy[d]) else "'0;"))
        A.append(f'  assign core_dly_ready[{d}] = io_deqDelay_{d}_ready;')
    # 年龄选择器输出
    ages = {m: inst for m, inst, _ in c.insts if 'AgeDetector' in m}
    enq_age = [i for m, i in ages.items() if m.startswith('NewAgeDetector')][0]
    simp_age = [i for m, i, cn in c.insts if 'AgeDetector' in m and not m.startswith('New')
                and any('simpEntryEnqSelVec' in x for _, x in cn)][0]
    comp_age = [i for m, i, cn in c.insts if 'AgeDetector' in m and not m.startswith('New')
                and any('compEntryEnqSelVec' in x for _, x in cn)][0]
    for d in range(ND):
        A.append(f'  assign core_age_enq_out[{d}] = {enq_age}_io_out_{d};')
        A.append(f'  assign core_age_comp_out[{d}] = {comp_age}_io_out_{d};')
    for k in range(ND + NE):
        A.append(f'  assign core_age_simp_out[{k}] = {simp_age}_io_out_{k};')
    L.append('  // ---- 核输入 ----')
    L += A
    L.append('')

    # ---- deqDelay 负载拼包/拆包 ----
    outs_done = set()
    for d in range(ND):
        parts = [c.res(f'deqBeforeDly_{d}_{f}', f'deqDelay_{d}_{f}') for f, _ in payload[d]]
        L.append(f'  // ---- 口 {d} deqDelay 负载（golden 寄存器声明顺序，高位在前）----')
        L.append(f'  assign core_deq{d}_payload = {{')
        L.append(',\n'.join(f'    {p}' for p in parts))
        L.append('  };')
        # 拆包：每个字段一根线
        off = W[d]
        for f, w in payload[d]:
            off -= w
            L.append(f'  wire {sv_w(w)}dly{d}_{f} = core_dly{d}_payload[{off + w - 1}:{off}];')
        L.append('')
    if ND == 1:
        L.append("  assign core_deq1_payload = 1'h0;")

    # ---- 子模块例化 ----
    for mod, inst, conns in c.insts:
        cp = {n: (dd, w) for dd, w, n in c.child_ports[mod]}
        L.append(f'  {mod} {inst} (')
        items = []
        for port, e in conns:
            dd, w = cp[port]
            if dd == 'output':
                if not e or e.startswith('/*'):
                    items.append((port, '/* unused */'))
                elif e in c.pdir:
                    items.append((port, e))
                else:
                    items.append((port, f'{inst}_{port}'))
            else:
                key = f'{mod}.{port}'
                if key in c.glue:
                    items.append((port, c.glue[key]))
                elif port == 'io_enq_bits_lat' and mod.startswith('MultiWakeupQueue'):
                    items.append((port, 'core_wk_enq_lat'))
                else:
                    items.append((port, c.res(e, f'{inst}.{port}')))
        wmax = max(len(p) for p, _ in items)
        for j, (p, x) in enumerate(items):
            L.append(f'    .{p.ljust(wmax)} ({x})' + (',' if j < len(items) - 1 else ''))
        L.append('  );')
        L.append('')

    # ---- MWQ 胶合 ----
    mwq = [x for x in c.insts if x[0].startswith('MultiWakeupQueue')]
    if mwq:
        mi = mwq[0][1]
        fe = [e for p, e in mwq[0][2] if p == 'io_enq_bits_uop_fuType']
        A2 = [f'  assign core_wk_enq_fu_type = {c.res(fe[0], "wk fuType") if fe else chr(39) + "0"};',
              f'  assign core_wk_deq_valid = {mi}_io_deq_valid;',
              f'  assign core_wk_deq_wen = {mi}_io_deq_bits_{extra["wk_wen"]};']
    else:
        A2 = ["  assign core_wk_enq_fu_type = '0;", "  assign core_wk_deq_valid = 1'h0;",
              "  assign core_wk_deq_wen = 1'h0;"]
    L += A2
    L.append('')

    # ---- 核例化 ----
    acc = ', '.join(f"35'h{a:X}" for a in P['ACCEPT'])
    hv = ', '.join(f"1'b{x}" for x in P['HAS_VCNT'])
    L.append(f'''  xs_IssueQueue_core #(
    .N_ENTRIES ({N}),
    .N_ENQ     ({NE}),
    .N_SIMP    ({P["N_SIMP"]}),
    .N_COMP    ({P["N_COMP"]}),
    .N_DEQ     ({ND}),
    .N_SRC     ({NS}),
    .PSRC_W    ({P["PSRC_W"]}),
    .LD_CNT    ({P["LD_CNT"]}),
    .N_EXU     ({P["N_EXU"]}),
    .EXU_W     ({P["EXU_W"]}),
    .N_BUSY    ({NB}),
    .ACCEPT    ('{{{acc}}}),
    .IQIDX_W   ({P["IQIDX_W"]}),
    .HAS_VCNT  ('{{{hv}}}),
    .VCNT_OUT_W({P["VCNT_OUT_W"]}),
    .W0        ({W[0]}),
    .W1        ({W[1] if ND > 1 else 1})
  ) u_core (
    .clock            (clock),
    .reset            (reset),
    .flush_valid      (io_flush_valid),
    .enq_valid        (core_enq_valid),
    .enq_ready        (core_enq_ready),
    .enq_do           (core_enq_do),
    .enq_src_type     (core_enq_src_type),
    .enq_psrc         (core_enq_psrc),
    .enq_src_state    (core_enq_src_state),
    .enq_src_ld       (core_enq_src_ld),
    .st_src_state     (core_st_src_state),
    .st_data_src      (core_st_data_src),
    .st_src_ld        (core_st_src_ld),
    .ent_valid        (core_ent_valid),
    .ent_issued       (core_ent_issued),
    .ent_can_issue    (core_ent_can_issue),
    .ent_fu_type      (core_ent_fu_type),
    .ent_data_src     (core_ent_data_src),
    .ent_exu_src      (core_ent_exu_src),
    .ent_ld_dep       (core_ent_ld_dep),
    .ent_cancel_deq   (core_ent_cancel_deq),
    .busy_mask        (core_busy_mask),
    .age_enq_req      (core_age_enq_req),
    .age_simp_req     (core_age_simp_req),
    .age_comp_req     (core_age_comp_req),
    .age_enq_out      (core_age_enq_out),
    .age_simp_out     (core_age_simp_out),
    .age_comp_out     (core_age_comp_out),
    .sel_valid        (core_sel_valid),
    .sel_oh           (core_sel_oh),
    .simp_oldest_valid(core_simp_oldest_valid),
    .comp_oldest_valid(core_comp_oldest_valid),
    .deq_valid        (core_deq_valid),
    .deq_iq_idx       (core_deq_iq_idx),
    .deq_data_src     (core_deq_data_src),
    .deq_exu_src      (core_deq_exu_src),
    .deq_ld_dep       (core_deq_ld_dep),
    .deq_select_time  (core_deq_select_time),
    .deq_issue_time   (core_deq_issue_time),
    .deq0_payload     (core_deq0_payload),
    .deq1_payload     (core_deq1_payload),
    .dly_valid        (core_dly_valid),
    .dly0_payload     (core_dly0_payload),
    .dly1_payload     (core_dly1_payload),
    .dly_ready        (core_dly_ready),
    .valid_cnt        (core_valid_cnt),
    .wk_enq_fu_type   (core_wk_enq_fu_type),
    .wk_enq_lat       (core_wk_enq_lat),
    .wk_deq_valid     (core_wk_deq_valid),
    .wk_deq_wen       (core_wk_deq_wen),
    .wk_out_wen       (core_wk_out_wen)
  );
''')

    # ---- 顶层输出 ----
    L.append('  // ---- 顶层输出 ----')
    driven_by_child = set()
    for mod, inst, conns in c.insts:
        cp = {n: dd for dd, _, n in c.child_ports[mod]}
        for p, e in conns:
            if cp[p] == 'output' and e in c.pdir:
                driven_by_child.add(e)
    for dd, w, n in c.ports:
        if dd != 'output' or n in driven_by_child:
            continue
        m = re.fullmatch(r'io_deqDelay_(\d+)_(\w+)', n)
        if m and m.group(2) == 'valid':
            L.append(f'  assign {n} = core_dly_valid[{m.group(1)}];')
            continue
        if f'@out:{n}' in c.glue:
            L.append(f'  assign {n} = {c.glue["@out:" + n]};')
            continue
        e = c.wires.get(n)
        if e is None:
            die(f'{v}: 输出 {n} 没有驱动')
        mm = re.fullmatch(r'deqDelay_(\d+)_(\w+)', e)
        if mm:
            L.append(f'  assign {n} = dly{mm.group(1)}_{mm.group(2)};')
            continue
        if re.fullmatch(r'io_wakeupToIQ_\d+_bits_(rf|fp|vec|v0|vl)Wen', n):
            L.append(f'  assign {n} = core_wk_out_wen;')
            continue
        L.append(f'  assign {n} = {c.res(e, n)};')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('variants', nargs='*')
    a = ap.parse_args()
    vs = a.variants or sorted(VARIANTS)
    bad = 0
    for v in vs:
        if v not in VARIANTS:
            die(f'{v} 未登记在 VARIANTS')
        txt = gen(v)
        dst = OUT / f'{v}.sv'
        if a.check:
            if not dst.exists() or dst.read_text() != txt:
                print(f'gen_iq --check: {dst} 与生成结果不一致')
                bad = 1
            else:
                print(f'gen_iq --check: {v} OK')
        else:
            dst.write_text(txt)
            print(f'gen_iq: 写 {dst}')
    return bad


if __name__ == '__main__':
    sys.exit(main())
