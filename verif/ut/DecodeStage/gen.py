#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— DecodeStage 的机械派生区（rtl/backend/DecodeStage.sv 里的 GENERATED 段）与 UT tb。

DecodeStage 的 golden 有 **1103 个端口**（6 路输入 × 41 个 StaticInst 字段 + 6 路输出
× 107 个 DecodedInst 字段 + RAT 读口 + perf …），子模块 DecodeUnit×6 / DecodeUnitComp /
VTypeGen 的实例连线又有约 2,300 根。这些全是「按名字对位」的纯机械活，本脚本把它们
从 golden **现场读出来**写进 GENERATED 段，手写区只留真正的粘合逻辑：

  1. GENERATED(csr_struct)     —— csr_to_decode_t：io_fromCSR_* 的 24 个标志位。
  2. GENERATED(static_inst)    —— static_inst_t：IBuffer 送来的 StaticInst（41 字段），
                                  名字/位宽取自 golden 的 io_in_0_bits_* 端口。
  3. GENERATED(decoded_inst)   —— decoded_inst_t：送 Rename 的 DecodedInst（107 字段），
                                  取自 io_out_0_bits_*；exceptionVec/srcType/lsrc 收成向量。
  4. GENERATED(simple_decoders)—— 6 个 DecodeUnit 的 generate 例化；DecodeUnit 没有的
                                  10 个 DecodedInst 字段按 golden 里折出来的常量补上。
  5. GENERATED(complex_decoder)—— DecodeUnitComp 例化；第 1..5 路没有 firstUop 端口（恒 0）。
  6. GENERATED(vtype_gen)      —— VTypeGen 例化。
  7. GENERATED(ports)/(wrapper)—— golden 同名 wrapper 的端口表（逐字取自 golden）与打包/拆包。
  8. verif/ut/DecodeStage/tb.sv —— 双例化 tb（golden DecodeStage vs DecodeStage_xs，
                                  子模块两侧共用 golden 定义）。

★golden 的子模块端口不是「Bundle 的全部字段」★：firtool 把被父模块驱成常数、或父模块
不读的端口删掉了。所以「哪个字段缺、缺了以后取什么常量」不能凭 Bundle 定义猜，
必须对着 golden DecodeStage 的 assign 读。本脚本把这些差集**断言成固定的期望集合**
（EXPECT_SIMPLE_MISSING / EXPECT_COMPLEX_MISSING），golden 一变这里立刻红。

用法：
    python3 gen.py            # 生成（幂等）
    python3 gen.py --check    # 与库里的产物不一致则非零退出
"""
import pathlib, re, sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
RTL = REPO / 'rtl' / 'backend' / 'DecodeStage.sv'
TB = HERE / 'tb.sv'
DW = 6

# ---------------------------------------------------------------------------
# golden 端口表解析
# ---------------------------------------------------------------------------
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')

def parse_ports(fname, module):
    txt = (GOLDEN / fname).read_text()
    start = txt.index(f'module {module}(')
    end = txt.index(');', start)
    ports = []
    for line in txt[start:end].split('\n')[1:]:
        m = PORT_RE.match(line)
        if m:
            d, hi, name = m.groups()
            ports.append((d, (int(hi) + 1) if hi else 1, name))
    assert ports, f'{fname}: 没解析到端口'
    return ports

def width_decl(w):
    return f'logic [{w-1}:0]' if w > 1 else 'logic      '

# 把 golden 的展平字段名折成 struct 成员访问：exceptionVec_3 -> .exceptionVec[3] 等
VEC_FIELDS = ('exceptionVec', 'srcType', 'lsrc')

def field_expr(base, flat):
    for v in VEC_FIELDS:
        m = re.fullmatch(v + r'_(\d+)', flat)
        if m:
            return f'{base}.{v}[{m.group(1)}]'
    return f'{base}.{flat}'

def collect_struct(ports, prefix):
    """按 golden 端口顺序收字段；向量字段（exceptionVec_K…）收成一个 [N-1:0] 成员。"""
    fields = []   # (name, width, count or None)
    seen = {}
    for d, w, name in ports:
        if not name.startswith(prefix):
            continue
        f = name[len(prefix):]
        vec = None
        for v in VEC_FIELDS:
            m = re.fullmatch(v + r'_(\d+)', f)
            if m:
                vec = (v, int(m.group(1)))
        if vec:
            v, k = vec
            if v in seen:
                fields[seen[v]] = (v, w, max(fields[seen[v]][2], k + 1))
            else:
                seen[v] = len(fields)
                fields.append((v, w, k + 1))
        else:
            assert f not in seen, f
            seen[f] = len(fields)
            fields.append((f, w, None))
    return fields

def emit_struct(fields, tname, comment):
    L = [f'  typedef struct packed {{']
    for name, w, cnt in fields:
        if cnt is None:
            L.append(f'    {width_decl(w)} {name};')
        else:
            dim = f'[{cnt-1}:0]' + (f'[{w-1}:0]' if w > 1 else '')
            L.append(f'    logic {dim} {name};')
    L.append(f'  }} {tname};')
    return L

# ---------------------------------------------------------------------------
# 读 golden
# ---------------------------------------------------------------------------
DS = parse_ports('DecodeStage.sv', 'DecodeStage')
DU = parse_ports('DecodeUnit.sv', 'DecodeUnit')
DC = parse_ports('DecodeUnitComp.sv', 'DecodeUnitComp')
VG = parse_ports('VTypeGen.sv', 'VTypeGen')
DS_NAMES = {n for _, _, n in DS}

static_fields = collect_struct(DS, 'io_in_0_bits_')
decoded_fields = collect_struct(DS, 'io_out_0_bits_')
csr_fields = collect_struct(DS, 'io_fromCSR_')
STATIC = {f for f, _, _ in static_fields}
DECODED = {f for f, _, _ in decoded_fields}

def flat_fields(ports, prefix):
    return [n[len(prefix):] for _, _, n in ports if n.startswith(prefix)]

def collapse(flat):
    """展平字段名集合 -> struct 成员名集合（exceptionVec_3 -> exceptionVec）"""
    out = set()
    for f in flat:
        hit = False
        for v in VEC_FIELDS:
            if re.fullmatch(v + r'_\d+', f):
                out.add(v); hit = True
        if not hit:
            out.add(f)
    return out

# DecodeUnit 的 deq 字段 vs decoded_inst_t：缺的 10 个在 golden 里折成了常量
du_deq = flat_fields(DU, 'io_deq_decodedInst_')
SIMPLE_MISSING = DECODED - collapse(du_deq)
EXPECT_SIMPLE_MISSING = {
    # 字段: 常量（读自 golden DecodeStage 的 assign：简单译码那一支取的值）
    'firstUop': "1'b1", 'lastUop': "1'b1", 'numUops': "7'd1", 'numWB': "7'd1",
    'uopIdx': "7'd0", 'vlWen': "1'b0",
    'vpu_fpu_isFoldTo1_2': "1'b0", 'vpu_fpu_isFoldTo1_4': "1'b0", 'vpu_fpu_isFoldTo1_8': "1'b0",
    'v0Wen': "1'b0",   # 输出侧由 vecWen & ldest==0 现算，两支的 v0Wen 都不用
}
assert SIMPLE_MISSING == set(EXPECT_SIMPLE_MISSING), (SIMPLE_MISSING, set(EXPECT_SIMPLE_MISSING))
assert not (collapse(du_deq) - DECODED), collapse(du_deq) - DECODED
# DecodeUnit 的 enq 字段 ⊂ static_inst_t（exceptionVec_3/_22 不在，DecodeUnit 自己产）
du_enq = flat_fields(DU, 'io_enq_ctrlFlow_')
assert not (collapse(du_enq) - STATIC), collapse(du_enq) - STATIC
# DecodeUnitComp 每路输出字段
COMPLEX_MISSING = {}
for n in range(DW):
    cx = flat_fields(DC, f'io_out_complexDecodedInsts_{n}_bits_')
    COMPLEX_MISSING[n] = DECODED - collapse(cx)
    assert not (collapse(cx) - DECODED)
EXPECT_COMPLEX_MISSING = {0: {'v0Wen'}, **{n: {'v0Wen', 'firstUop'} for n in range(1, DW)}}
assert COMPLEX_MISSING == EXPECT_COMPLEX_MISSING, COMPLEX_MISSING
# DecodeUnitComp 输入字段 ⊂ decoded_inst_t
dc_in = flat_fields(DC, 'io_in_bits_simpleDecodedInst_')
assert not (collapse(dc_in) - DECODED), collapse(dc_in) - DECODED

# ---------------------------------------------------------------------------
# 各 GENERATED 段
# ---------------------------------------------------------------------------
def gen_structs():
    out = {}
    out['csr_struct'] = ['  // csr_to_decode_t —— CSR 告诉译码器哪些指令当前非法/虚拟化非法（io_fromCSR_*，24 位）'] + \
        emit_struct(csr_fields, 'csr_to_decode_t', '')
    out['static_inst'] = ['  // static_inst_t —— IBuffer 送来的 StaticInst（41 个字段，名字/位宽取自 golden io_in_0_bits_*）'] + \
        emit_struct(static_fields, 'static_inst_t', '')
    out['decoded_inst'] = ['  // decoded_inst_t —— 送 Rename 的 DecodedInst（107 个字段，取自 golden io_out_0_bits_*；',
                           '  //   exceptionVec/srcType/lsrc 收成向量，其余成员名与 golden 逐字同名）'] + \
        emit_struct(decoded_fields, 'decoded_inst_t', '')
    return out

def gen_simple_decoders():
    L = []
    L.append('  // 6 个简单译码器：每路一个 DecodeUnit（纯组合，无 clock/reset），')
    L.append('  // 输入 = 本路 StaticInst + 当前推测 vtype/vstart + CSR 标志，输出 = DecodedInst + isComplex + uopInfo。')
    L.append('  for (genvar i = 0; i < DECODE_WIDTH; i++) begin : g_simple')
    L.append('    DecodeUnit u_decoder (')
    conns = []
    for d, w, name in DU:
        if name.startswith('io_enq_ctrlFlow_'):
            conns.append((name, field_expr('in_bits[i]', name[len('io_enq_ctrlFlow_'):])))
        elif name.startswith('io_enq_vtype_'):
            conns.append((name, f'vtype.{name[len("io_enq_vtype_"):]}'))
        elif name == 'io_enq_vstart':
            conns.append((name, 'vstart'))
        elif name.startswith('io_deq_decodedInst_'):
            conns.append((name, field_expr('simple_inst[i]', name[len('io_deq_decodedInst_'):])))
        elif name == 'io_deq_isComplex':
            conns.append((name, 'simple_is_complex[i]'))
        elif name.startswith('io_deq_uopInfo_'):
            conns.append((name, f'simple_uop_info[i].{name[len("io_deq_uopInfo_"):]}'))
        elif name == 'io_csrCtrl_singlestep':
            conns.append((name, 'csrCtrl_singlestep'))
        elif name.startswith('io_fromCSR_'):
            conns.append((name, f'fromCSR.{name[len("io_fromCSR_"):]}'))
        else:
            raise AssertionError(f'DecodeUnit 端口没归类: {name}')
    for k, (p, e) in enumerate(conns):
        L.append(f'      .{p:44s} ({e}){"," if k < len(conns)-1 else ""}')
    L.append('    );')
    L.append('    // DecodeUnit 没有这 10 个 DecodedInst 字段（firtool 在 golden 里把它们折成了常量），')
    L.append('    // 常量取自 golden DecodeStage 简单译码那一支的 assign。')
    for f in [x for x, _, _ in decoded_fields if x in EXPECT_SIMPLE_MISSING]:
        L.append(f'    assign simple_inst[i].{f} = {EXPECT_SIMPLE_MISSING[f]};')
    L.append('  end')
    return L

def gen_complex_decoder():
    L = []
    L.append('  // 复杂译码器：一次锁存一条复杂指令，按 uopSplitType 拆成最多 65 个 uop，每拍最多吐 6 个。')
    L.append('  DecodeUnitComp u_complex (')
    conns = []
    for d, w, name in DC:
        if name in ('clock', 'reset'):
            conns.append((name, name))
        elif name == 'io_redirect':
            conns.append((name, 'redirect'))
        elif name.startswith('io_vtypeBypass_'):
            conns.append((name, f'vtype.{name[len("io_vtypeBypass_"):]}'))
        elif name == 'io_in_ready':
            conns.append((name, 'complex_in_ready'))
        elif name == 'io_in_valid':
            conns.append((name, 'complex_in_valid'))
        elif name.startswith('io_in_bits_simpleDecodedInst_'):
            conns.append((name, field_expr('complex_in_inst', name[len('io_in_bits_simpleDecodedInst_'):])))
        elif name.startswith('io_in_bits_uopInfo_'):
            conns.append((name, f'complex_in_uop_info.{name[len("io_in_bits_uopInfo_"):]}'))
        elif name == 'io_out_complexDecodedInsts_0_ready':
            conns.append((name, 'out_ready[0]'))
        elif re.fullmatch(r'io_out_complexDecodedInsts_(\d)_valid', name):
            n = re.fullmatch(r'io_out_complexDecodedInsts_(\d)_valid', name).group(1)
            conns.append((name, f'complex_valid[{n}]'))
        elif name.startswith('io_out_complexDecodedInsts_'):
            m = re.fullmatch(r'io_out_complexDecodedInsts_(\d)_bits_(\w+)', name)
            conns.append((name, field_expr(f'complex_inst[{m.group(1)}]', m.group(2))))
        elif name == 'io_complexNum':
            conns.append((name, 'complexNum'))
        else:
            raise AssertionError(f'DecodeUnitComp 端口没归类: {name}')
    for k, (p, e) in enumerate(conns):
        L.append(f'    .{p:46s} ({e}){"," if k < len(conns)-1 else ""}')
    L.append('  );')
    L.append('  // golden 里第 1..5 路没有 firstUop 端口（恒 0 被删）；v0Wen 两支都不用（输出侧现算）。')
    for n in range(DW):
        for f in sorted(EXPECT_COMPLEX_MISSING[n]):
            L.append(f"  assign complex_inst[{n}].{f} = 1'b0;")
    return L

def gen_vtype_gen():
    L = []
    L.append('  // vtype 生成：跟踪推测 vtype（vset 指令一进复杂译码器就更新），供 6 个 DecodeUnit 与 DecodeUnitComp 用。')
    L.append('  VTypeGen u_vtype_gen (')
    conns = []
    for d, w, name in VG:
        if name in ('clock', 'reset'):
            conns.append((name, name))
        elif re.fullmatch(r'io_insts_(\d)_valid', name):
            conns.append((name, f'in_valid[{name.split("_")[2]}]'))
        elif re.fullmatch(r'io_insts_(\d)_bits', name):
            conns.append((name, f'in_bits[{name.split("_")[2]}].instr'))
        elif name == 'io_walkToArchVType':
            conns.append((name, 'fromRob.walkToArchVType'))
        elif name == 'io_walkVType_valid':
            conns.append((name, 'fromRob.walkVType_valid'))
        elif name.startswith('io_walkVType_bits_'):
            conns.append((name, f'fromRob.walkVType.{name[len("io_walkVType_bits_"):]}'))
        elif name == 'io_canUpdateVType':
            conns.append((name, 'vtype_can_update'))
        elif name.startswith('io_vtype_'):
            conns.append((name, f'vtype.{name[len("io_vtype_"):]}'))
        elif name.startswith('io_vsetvlVType_'):
            conns.append((name, f'vsetvlVType.{name[len("io_vsetvlVType_"):]}'))
        elif name == 'io_commitVType_vtype_valid':
            conns.append((name, 'fromRob.commitVType_valid'))
        elif name.startswith('io_commitVType_vtype_bits_'):
            conns.append((name, f'fromRob.commitVType.{name[len("io_commitVType_vtype_bits_"):]}'))
        elif name == 'io_commitVType_hasVsetvl':
            conns.append((name, 'fromRob.commitVType_hasVsetvl'))
        else:
            raise AssertionError(f'VTypeGen 端口没归类: {name}')
    for k, (p, e) in enumerate(conns):
        L.append(f'    .{p:34s} ({e}){"," if k < len(conns)-1 else ""}')
    L.append('  );')
    return L

# wrapper：golden 每个端口 -> 核端口/结构体成员
def map_top_port(name):
    m = re.fullmatch(r'io_in_(\d)_valid', name)
    if m: return f'in_valid[{m.group(1)}]'
    m = re.fullmatch(r'io_in_(\d)_ready', name)
    if m: return f'in_ready[{m.group(1)}]'
    m = re.fullmatch(r'io_in_(\d)_bits_(\w+)', name)
    if m: return field_expr(f'in_bits[{m.group(1)}]', m.group(2))
    m = re.fullmatch(r'io_out_(\d)_valid', name)
    if m: return f'out_valid[{m.group(1)}]'
    m = re.fullmatch(r'io_out_(\d)_ready', name)
    if m: return f'out_ready[{m.group(1)}]'
    m = re.fullmatch(r'io_out_(\d)_bits_(\w+)', name)
    if m: return field_expr(f'out_bits[{m.group(1)}]', m.group(2))
    m = re.fullmatch(r'io_(intRat|fpRat|vecRat)_(\d)_(\d)_(addr|hold)', name)
    if m: return f'{m.group(1)}_{m.group(4)}[{m.group(2)}][{m.group(3)}]'
    m = re.fullmatch(r'io_(v0Rat|vlRat)_(\d)_hold', name)
    if m: return f'{m.group(1)}_hold[{m.group(2)}]'
    m = re.fullmatch(r'io_fusion_(\d)', name)
    if m: return f'fusion[{m.group(1)}]'
    m = re.fullmatch(r'io_perf_(\d)_value', name)
    if m: return f'perf_value[{m.group(1)}]'
    m = re.fullmatch(r'io_stallReason_in_reason_(\d)', name)
    if m: return f'stallReason_in_reason[{m.group(1)}]'
    m = re.fullmatch(r'io_stallReason_out_reason_(\d)', name)
    if m: return f'stallReason_out_reason[{m.group(1)}]'
    m = re.fullmatch(r'io_stallReason_out_backReason_(valid|bits)', name)
    if m: return f'stallReason_out_backReason_{m.group(1)}'
    m = re.fullmatch(r'io_stallReason_in_backReason_(valid|bits)', name)
    if m: return f'stallReason_in_backReason_{m.group(1)}'
    m = re.fullmatch(r'io_fromCSR_(\w+)', name)
    if m: return f'fromCSR.{m.group(1)}'
    m = re.fullmatch(r'io_fromRob_commitVType_vtype_bits_(\w+)', name)
    if m: return f'fromRob.commitVType.{m.group(1)}'
    m = re.fullmatch(r'io_fromRob_walkVType_bits_(\w+)', name)
    if m: return f'fromRob.walkVType.{m.group(1)}'
    fixed = {
        'clock': 'clock', 'reset': 'reset', 'io_redirect': 'redirect', 'io_canAccept': 'canAccept',
        'io_csrCtrl_singlestep': 'csrCtrl_singlestep', 'io_backendCanAccept': 'backendCanAccept',
        'io_fromRob_isResumeVType': 'fromRob.isResumeVType',
        'io_fromRob_walkToArchVType': 'fromRob.walkToArchVType',
        'io_fromRob_commitVType_vtype_valid': 'fromRob.commitVType_valid',
        'io_fromRob_commitVType_hasVsetvl': 'fromRob.commitVType_hasVsetvl',
        'io_fromRob_walkVType_valid': 'fromRob.walkVType_valid',
        'io_vstart': 'vstart',
        'io_toCSR_trapInstInfo_valid': 'trapInstInfo_valid',
    }
    if name in fixed: return fixed[name]
    m = re.fullmatch(r'io_vsetvlVType_(\w+)', name)
    if m: return f'vsetvlVType.{m.group(1)}'
    m = re.fullmatch(r'io_toCSR_trapInstInfo_bits_(\w+)', name)
    if m: return f'trapInstInfo.{m.group(1)}'
    raise AssertionError(f'DecodeStage 顶层端口没归类: {name}')

def gen_ports():
    L = []
    for k, (d, w, name) in enumerate(DS):
        ww = f'[{w-1}:0]' if w > 1 else ''
        L.append(f'  {d:6s} {ww:8s} {name}{"," if k < len(DS)-1 else ""}')
    return L

def gen_wrapper():
    L = []
    L.append('  // 核的结构体/数组端口 <-> golden 扁平端口（每根线一行，按 golden 端口顺序）')
    ins, outs = [], []
    for d, w, name in DS:
        if name in ('clock', 'reset'):
            continue
        e = map_top_port(name)
        (ins if d == 'input' else outs).append((name, e))
    L.append('  logic [DECODE_WIDTH-1:0]            in_valid, in_ready, out_valid, out_ready;')
    L.append('  static_inst_t  [DECODE_WIDTH-1:0]   in_bits;')
    L.append('  decoded_inst_t [DECODE_WIDTH-1:0]   out_bits;')
    L.append('  logic [DECODE_WIDTH-1:0][1:0][31:0] intRat_addr;')
    L.append('  logic [DECODE_WIDTH-1:0][1:0]       intRat_hold;')
    L.append('  logic [DECODE_WIDTH-1:0][2:0][33:0] fpRat_addr;')
    L.append('  logic [DECODE_WIDTH-1:0][2:0]       fpRat_hold;')
    L.append('  logic [DECODE_WIDTH-1:0][2:0][46:0] vecRat_addr;')
    L.append('  logic [DECODE_WIDTH-1:0][2:0]       vecRat_hold;')
    L.append('  logic [DECODE_WIDTH-1:0]            v0Rat_hold, vlRat_hold;')
    L.append('  logic [DECODE_WIDTH-2:0]            fusion;')
    L.append('  logic [7:0][5:0]                    perf_value;')
    L.append('  logic [DECODE_WIDTH-1:0][5:0]       stallReason_in_reason, stallReason_out_reason;')
    L.append('  logic                               stallReason_out_backReason_valid, stallReason_in_backReason_valid;')
    L.append('  logic [5:0]                         stallReason_out_backReason_bits, stallReason_in_backReason_bits;')
    L.append('  csr_to_decode_t                     fromCSR;')
    L.append('  from_rob_t                          fromRob;')
    L.append('  vtype_t                             vsetvlVType;')
    L.append('  logic                               trapInstInfo_valid;')
    L.append('  trap_inst_info_t                    trapInstInfo;')
    L.append('')
    L.append('  // ---- 输入打包 ----')
    for name, e in ins:
        L.append(f'  assign {e} = {name};')
    L.append('')
    L.append('  xs_DecodeStage_core u_core (')
    L.append('    // golden 没有 io_canAccept 端口（CtrlBlock 不读，firtool 删掉了），核的 canAccept 悬空')
    L.append('    .clock(clock), .reset(reset), .redirect(io_redirect), .canAccept(),')
    L.append('    .in_valid(in_valid), .in_bits(in_bits), .in_ready(in_ready),')
    L.append('    .out_valid(out_valid), .out_bits(out_bits), .out_ready(out_ready),')
    L.append('    .intRat_addr(intRat_addr), .intRat_hold(intRat_hold),')
    L.append('    .fpRat_addr(fpRat_addr), .fpRat_hold(fpRat_hold),')
    L.append('    .vecRat_addr(vecRat_addr), .vecRat_hold(vecRat_hold),')
    L.append('    .v0Rat_hold(v0Rat_hold), .vlRat_hold(vlRat_hold),')
    L.append('    .csrCtrl_singlestep(io_csrCtrl_singlestep), .fromCSR(fromCSR),')
    L.append('    .fusion(fusion), .backendCanAccept(io_backendCanAccept), .fromRob(fromRob),')
    L.append('    .stallReason_in_reason(stallReason_in_reason),')
    L.append('    .stallReason_out_backReason_valid(stallReason_out_backReason_valid),')
    L.append('    .stallReason_out_backReason_bits(stallReason_out_backReason_bits),')
    L.append('    .stallReason_in_backReason_valid(stallReason_in_backReason_valid),')
    L.append('    .stallReason_in_backReason_bits(stallReason_in_backReason_bits),')
    L.append('    .stallReason_out_reason(stallReason_out_reason),')
    L.append('    .vsetvlVType(vsetvlVType), .vstart(io_vstart),')
    L.append('    .trapInstInfo_valid(trapInstInfo_valid), .trapInstInfo(trapInstInfo),')
    L.append('    .perf_value(perf_value)')
    L.append('  );')
    L.append('')
    L.append('  // ---- 输出拆包 ----')
    for name, e in outs:
        if name == 'io_canAccept':
            continue
        L.append(f'  assign {name} = {e};')
    return L

# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
def gen_tb():
    ins = [(w, n) for d, w, n in DS if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in DS if d == 'output']
    L = []
    A = L.append
    A('// =============================================================================')
    A('// DecodeStage UT —— golden DecodeStage 对重写 DecodeStage_xs 双例化，同激励逐拍比对')
    A(f'// 全部 {len(outs)} 根输出线。子模块（DecodeUnit×6 / DecodeUnitComp / VTypeGen 及其闭包）两侧')
    A('// 共用 golden 定义（RTL_GOLDEN_DEPS），所以本 UT 验的是 DecodeStage 这一层的粘合逻辑：')
    A('// 复杂/简单指令的排布与 ready 计算、finalDecodedInst 选择、输出修饰、RAT 读口、trapInstInfo、perf。')
    A('// 本文件由 gen.py 生成，不要手改（改 gen.py 再重跑）。')
    A('//')
    A('// ★判别力在「isComplex 的分布 × complexNum × ready 相位」★')
    A('//   指令流里定向放向量算术/向量访存/vset/amocas（让 DecodeUnit 报 isComplex），')
    A('//   让 DecodeUnitComp 真的锁存并多拍吐 uop（complexNum 走遍 0..6），')
    A('//   out_ready[0] 做长条 0/1，redirect / isResumeVType 随机插入，非法指令走 trapInstInfo。')
    A('// ★无复位寄存器★ trapInstInfo 的 REG_* 与 perf 两级打拍无复位但每拍都写，')
    A('//   DecodeUnitComp 的锁存寄存器无复位、只在 in.fire 时写：暖机 WARMUP 拍里全 valid、全 ready、')
    A('//   定向喂复杂指令让它锁存一次，之后才开比对窗口，所以两档 initreg 都必须 errors=0。')
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  localparam int WARMUP = 64;')
    A('  bit clk = 0; logic rst; int errors = 0; longint checks = 0;')
    A('  always #5 clk = ~clk;')
    A('')
    for w, n in ins:
        A(f'  logic {("["+str(w-1)+":0]") if w>1 else "":8s} {n};')
    for side in ('g', 'x'):
        for w, n in outs:
            A(f'  logic {("["+str(w-1)+":0]") if w>1 else "":8s} {side}_{n};')
    A('')
    for side, mod, inst in (('g', 'DecodeStage', 'u_gold'), ('x', 'DecodeStage_xs', 'u_xs')):
        A(f'  {mod} {inst} (')
        A('    .clock(clk), .reset(rst),')
        conns = [f'.{n}({n})' for w, n in ins] + [f'.{n}({side}_{n})' for w, n in outs]
        for k in range(0, len(conns), 4):
            chunk = conns[k:k+4]
            A('    ' + ', '.join(chunk) + (',' if k + 4 < len(conns) else ''))
        A('  );')
        A('')
    # ---- stimulus ----
    A('  // ---- 指令构造 ----')
    A('  // 定向模板：让 DecodeUnit 报 isComplex 的（向量算术 OP-V / 向量访存 / vset / amocas）+ 常见标量 + 非法')
    A('  function automatic logic [31:0] mk_instr();')
    A('    logic [4:0] rd = 5\'($urandom), rs1 = 5\'($urandom), rs2 = 5\'($urandom);')
    A('    logic [2:0] f3 = 3\'($urandom);')
    A('    int pick = $urandom_range(0, 99);')
    A('    if (pick < 25)      return {6\'($urandom), 1\'($urandom), rs2, rs1, (f3 == 3\'b111) ? 3\'b000 : f3, rd, 7\'h57};   // OP-V 算术（funct3 != 111）')
    A('    else if (pick < 33) return {6\'($urandom), 1\'($urandom), rs2, rs1, 3\'b111, rd, 7\'h57};                        // vsetvli/vsetivli/vsetvl')
    A('    else if (pick < 43) return {3\'($urandom), 2\'($urandom), 1\'($urandom), 1\'($urandom), rs2, rs1, (pick & 1) ? 3\'b000 : 3\'b110, rd, 7\'h07}; // 向量 load')
    A('    else if (pick < 50) return {3\'($urandom), 2\'($urandom), 1\'($urandom), 1\'($urandom), rs2, rs1, (pick & 1) ? 3\'b101 : 3\'b111, rd, 7\'h27}; // 向量 store')
    A('    else if (pick < 53) return {5\'b00101, 1\'($urandom), 1\'($urandom), rs2, rs1, (pick & 1) ? 3\'b011 : 3\'b010, rd, 7\'h2F};   // amocas')
    A('    else if (pick < 63) return {7\'($urandom), rs2, rs1, f3, rd, 7\'h33};                                             // R 型整数')
    A('    else if (pick < 70) return {12\'($urandom), rs1, f3, rd, 7\'h13};                                                 // I 型整数')
    A('    else if (pick < 75) return {12\'($urandom), rs1, (f3 == 3\'b111) ? 3\'b011 : f3, rd, 7\'h03};                         // load')
    A('    else if (pick < 80) return {7\'($urandom), rs2, rs1, f3, rd, 7\'h53};                                             // FP')
    A('    else if (pick < 84) return {12\'($urandom), rs1, f3, rd, 7\'h73};                                                 // SYSTEM/CSR')
    A('    else if (pick < 88) return {12\'h000, 5\'h0, 3\'b000, 5\'h0, 7\'h0F};                                             // fence')
    A('    else if (pick < 92) return 32\'h0;                                                                           // 非法（全 0）')
    A('    else                return $urandom;')
    A('  endfunction')
    A('')
    A('  function automatic logic next_ready();')
    A('    static int hold = 0; static logic cur = 1;')
    A('    if (hold == 0) begin cur = ($urandom_range(0, 3) != 0); hold = $urandom_range(1, 12); end')
    A('    hold--; return cur;')
    A('  endfunction')
    A('')
    A('  logic i_ready_0;   // out[0].ready 的长条 0/1 源')
    A('  task automatic drive_inputs(input bit warm);')
    for w, n in ins:
        if w == 1:
            A(f'    {n} = 1\'($urandom);')
        else:
            A(f'    {n} = {w}\'($urandom);')
    A('    // 主控信号按分布覆盖')
    for i in range(DW):
        A(f'    io_in_{i}_bits_instr = mk_instr();')
        A(f'    io_in_{i}_valid = warm ? 1\'b1 : ($urandom_range(0, 9) < 8);')
        A(f'    io_out_{i}_ready = warm ? 1\'b1 : (i_ready_0 | ($urandom_range(0, 3) != 0));')
    A('    io_out_0_ready = warm ? 1\'b1 : i_ready_0;')
    A('    io_redirect = warm ? 1\'b0 : ($urandom_range(0, 49) == 0);')
    A('    io_fromRob_isResumeVType = warm ? 1\'b0 : ($urandom_range(0, 29) == 0);')
    A('    io_fromRob_walkToArchVType = warm ? 1\'b0 : ($urandom_range(0, 29) == 0);')
    A('    io_fromRob_commitVType_vtype_valid = warm ? 1\'b0 : ($urandom_range(0, 9) == 0);')
    A('    io_fromRob_walkVType_valid = warm ? 1\'b0 : ($urandom_range(0, 19) == 0);')
    A('    io_backendCanAccept = ($urandom_range(0, 3) != 0);')
    A('    io_csrCtrl_singlestep = ($urandom_range(0, 19) == 0);')
    A('    io_stallReason_out_backReason_valid = ($urandom_range(0, 3) == 0);')
    A('  endtask')
    A('')
    A('  task automatic compare_outputs();')
    A('    checks++;')
    for w, n in outs:
        A(f'    if (g_{n} !== x_{n}) begin errors++; if (errors < 20) $display("MISMATCH @%0t {n} g=%h x=%h", $time, g_{n}, x_{n}); end')
    A('  endtask')
    A('')
    A('  longint cov_cnum[8]; longint cov_inready[7]; longint cov_outvalid[7]; longint cov_trap = 0, cov_resume = 0, cov_redir_cplx = 0, cov_cplx_fire = 0, cov_backpressure = 0;')
    A('  task automatic collect_cov();')
    A('    int nr = 0, nv = 0;')
    A('    cov_cnum[u_gold.complexNum]++;')
    for i in range(DW):
        A(f'    if (g_io_in_{i}_ready === 1\'b1) nr++;')
        A(f'    if (g_io_out_{i}_valid === 1\'b1) nv++;')
    A('    cov_inready[nr]++; cov_outvalid[nv]++;')
    A('    if (g_io_toCSR_trapInstInfo_valid === 1\'b1) cov_trap++;')
    A('    if (io_fromRob_isResumeVType) cov_resume++;')
    A('    if (io_redirect && u_gold.complexNum != 0) cov_redir_cplx++;')
    A('    if (u_gold._decoderComp_io_in_ready && u_gold._decoderComp_io_in_valid_T_1) cov_cplx_fire++;')
    A('    if (!io_out_0_ready) cov_backpressure++;')
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    for (int i = 0; i < 8; i++) cov_cnum[i] = 0;')
    A('    for (int i = 0; i < 7; i++) begin cov_inready[i] = 0; cov_outvalid[i] = 0; end')
    A('    i_ready_0 = 1; rst = 1\'b1; drive_inputs(1\'b1);')
    A('    repeat (4) @(negedge clk);')
    A('    rst = 1\'b0;')
    A('    for (longint c = 0; c < NCYCLES; c++) begin')
    A('      // 运行中多次异步复位（每 ~16000 拍 2 拍），复位期间照常打激励并比对')
    A('      rst = ((c % 16384) < 2) && (c > WARMUP);')
    A('      i_ready_0 = next_ready();')
    A('      drive_inputs(c < WARMUP);')
    A('      #1;')
    A('      if (c >= WARMUP) begin compare_outputs(); collect_cov(); end')
    A('      @(negedge clk);')
    A('    end')
    A('    $display("=== COVERAGE (DecodeStage) ===");')
    A('    $display("  checks=%0d trap=%0d resume=%0d redirect_while_complex=%0d complex_fire=%0d backpressure=%0d", checks, cov_trap, cov_resume, cov_redir_cplx, cov_cplx_fire, cov_backpressure);')
    A('    for (int i = 0; i < 7; i++) $display("  complexNum=%0d: %0d   #in_ready=%0d: %0d   #out_valid=%0d: %0d", i, cov_cnum[i], i, cov_inready[i], i, cov_outvalid[i]);')
    A('    begin')
    A('      int bad = 0;')
    A('      for (int i = 0; i < 7; i++) if (cov_cnum[i] == 0 || cov_inready[i] == 0 || cov_outvalid[i] == 0) bad++;')
    A('      if (bad != 0 || cov_trap == 0 || cov_resume == 0 || cov_redir_cplx == 0 || cov_cplx_fire == 0 || cov_backpressure == 0) begin')
    A('        $display("COVERAGE INSUFFICIENT"); errors++;')
    A('      end')
    A('    end')
    A('    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);')
    A('    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'

# ---------------------------------------------------------------------------
# 原地替换 GENERATED 段
# ---------------------------------------------------------------------------
def splice(text, tag, body):
    b = f'  // BEGIN GENERATED({tag})'
    e = '  // END GENERATED'
    i = text.index(b)
    j = text.index(e, i)
    return text[:i + len(b)] + '\n' + '\n'.join(body) + '\n' + text[j:]

def render_rtl(text):
    st = gen_structs()
    for tag in ('csr_struct', 'static_inst', 'decoded_inst'):
        text = splice(text, tag, st[tag])
    text = splice(text, 'simple_decoders', gen_simple_decoders())
    text = splice(text, 'complex_decoder', gen_complex_decoder())
    text = splice(text, 'vtype_gen', gen_vtype_gen())
    text = splice(text, 'ports', gen_ports())
    text = splice(text, 'wrapper', gen_wrapper())
    return text

def main():
    check = '--check' in sys.argv
    old = RTL.read_text()
    new = render_rtl(old)
    tb = gen_tb()
    drift = []
    if new != old: drift.append(str(RTL))
    if not TB.exists() or TB.read_text() != tb: drift.append(str(TB))
    if check:
        if drift:
            print('DRIFT:', *drift); return 1
        print('OK: DecodeStage 生成产物幂等'); return 0
    if new != old: RTL.write_text(new); print('wrote', RTL)
    if not TB.exists() or TB.read_text() != tb: TB.write_text(tb); print('wrote', TB)
    if not drift: print('unchanged')
    return 0

if __name__ == '__main__':
    sys.exit(main())
