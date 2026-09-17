#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— DecodeUnitComp 的机械派生区与 UT tb。

DecodeUnitComp 的 golden 有 **748 个端口**（6 路输出 × 106 个 DecodedInst 字段
+ 96 个输入字段 + 若干控制），手抄注定出错。本脚本把三件纯机械的事从 golden
**现场读出来**，写进 rtl/backend/DecodeUnitComp.sv 的 GENERATED 区段：

  1. GENERATED(struct)  —— static_inst_t：被锁存的那份 DecodedInst（96 个字段，
     名字与位宽全部取自 golden 的 io_in_bits_simpleDecodedInst_* 端口）。
  2. GENERATED(ports)   —— wrapper 的端口表，逐字取自 golden 的端口表。
  3. GENERATED(wrapper) —— wrapper 体：输入打包成 struct 喂给核，核的输出再摊回
     748 根线。每根输出线走哪条路，是**从 golden 的 assign 现场分类**出来的：
       · `_GEN_xxxx[count]`  → 逐 uop 变化，走 out_var[slot]
       · `latchedInst_<同名>` → 直通，走 latched
       · 其余（exceptionVec_2 / numUops / numWB / valid / complexNum）单独列出
     分类结果会被**断言**成固定的期望集合（EXPECT_INDEXED 等）；golden 一变，
     这里立刻红，而不是悄悄生成一份错的接线。

  4. verif/ut/DecodeUnitComp/tb.sv —— 双例化 tb。

★ golden 的端口不是「DecodedInst 的全部字段」★：firtool 做整电路优化时，把父模块
驱成常数、或父模块根本不读的端口删掉了。实测三处：
  · 输出有 10 个字段没有对应输入端口（vlWen / uopIdx / firstUop / lastUop /
    vlsInstr / vpu_fpu_isFoldTo1_{2,4,8} / numUops / numWB）——
    前 8 个的锁存默认值因此是**常数 0**（父模块驱 0），核里必须照此写死，
    不能凭空造输入端口，否则端口契约闸立刻红。
  · lsrc 在 DecodedInst 里是 Vec(5)，golden 只剩 lsrc_0..2 —— Chisel 里对
    lsrc(4) 的赋值（VSET / VEC_US_FF_LD 两处）在 golden 里**完全不存在**。
  · firstUop 只有第 0 路输出有端口（其余 5 路恒 0，被删）。

用法：
    python3 gen.py            # 生成（幂等）
    python3 gen.py --check    # DRIFT 则非零退出
"""
import argparse
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/DecodeUnitComp.sv')
RTL = REPO / 'rtl' / 'backend' / 'DecodeUnitComp.sv'

IN_PFX = 'io_in_bits_simpleDecodedInst_'
OUT_PFX = 'io_out_complexDecodedInsts_'

# 逐 uop 变化的 31 个字段（从 golden 现场分类，这里是期望值，用于 fail-closed 校验）
EXPECT_INDEXED = {
    'srcType_0', 'srcType_1', 'srcType_2', 'srcType_3', 'srcType_4',
    'lsrc_0', 'lsrc_1', 'lsrc_2', 'ldest', 'fuType', 'fuOpType',
    'rfWen', 'fpWen', 'vecWen', 'vlWen',
    'waitForward', 'blockBackward', 'flushPipe',
    'vpu_vill', 'vpu_vma', 'vpu_vta', 'vpu_vsew', 'vpu_vlmul',
    'vpu_fpu_isFoldTo1_2', 'vpu_fpu_isFoldTo1_4', 'vpu_fpu_isFoldTo1_8',
    'vpu_isReverse', 'vlsInstr', 'uopIdx', 'firstUop', 'lastUop',
}
# 既不是直通、也不是 [count] 索引的三个字段
EXPECT_SPECIAL = {'exceptionVec_2', 'numUops', 'numWB'}

# static_inst_t 里做成数组的三组字段：前缀 -> (成员名, 元素数)
ARRAYS = {'exceptionVec_': ('exceptionVec', 24),
          'srcType_': ('srcType', 5),
          'lsrc_': ('lsrc', 3)}

# uop_var_t 的成员顺序（读起来按「源→目的→功能单元→写使能→流水控制→vpu→序号」）
VAR_MEMBERS = [
    ('srcType', 'array', 5, 4, '五个源操作数的类型(imm/xp/fp/vp)'),
    ('lsrc', 'array', 3, 6, '三个源逻辑寄存器号'),
    ('ldest', 'scalar', 0, 6, '目的逻辑寄存器号'),
    ('fuType', 'scalar', 0, 35, '功能单元 one-hot'),
    ('fuOpType', 'scalar', 0, 9, '功能单元内的操作码'),
    ('rfWen', 'scalar', 0, 1, '写整数寄存器堆'),
    ('fpWen', 'scalar', 0, 1, '写浮点寄存器堆'),
    ('vecWen', 'scalar', 0, 1, '写向量寄存器堆'),
    ('vlWen', 'scalar', 0, 1, '写 vl'),
    ('waitForward', 'scalar', 0, 1, '等前面全部完成才发射'),
    ('blockBackward', 'scalar', 0, 1, '挡住后面的指令'),
    ('flushPipe', 'scalar', 0, 1, '提交时冲刷流水'),
    ('vpu_vill', 'scalar', 0, 1, 'vtype.vill'),
    ('vpu_vma', 'scalar', 0, 1, 'vtype.vma'),
    ('vpu_vta', 'scalar', 0, 1, 'vtype.vta'),
    ('vpu_vsew', 'scalar', 0, 2, 'vtype.vsew'),
    ('vpu_vlmul', 'scalar', 0, 3, 'vtype.vlmul'),
    ('vpu_fpu_isFoldTo1_2', 'scalar', 0, 1, '浮点归约折半'),
    ('vpu_fpu_isFoldTo1_4', 'scalar', 0, 1, '浮点归约折四分之一'),
    ('vpu_fpu_isFoldTo1_8', 'scalar', 0, 1, '浮点归约折八分之一'),
    ('vpu_isReverse', 'scalar', 0, 1, '源操作数换位'),
    ('vlsInstr', 'scalar', 0, 1, '属于向量访存指令'),
    ('uopIdx', 'scalar', 0, 7, '本 uop 在拆分序列里的序号'),
    ('firstUop', 'scalar', 0, 1, '序列第一个'),
    ('lastUop', 'scalar', 0, 1, '序列最后一个'),
]


def golden_ports():
    lines = GOLDEN.read_text().split('\n')
    ms = next(i for i, l in enumerate(lines) if l.startswith('module DecodeUnitComp('))
    pe = ms
    while not lines[pe].strip().endswith(');'):
        pe += 1
    raw = lines[ms + 1:pe + 1]
    ports = []
    for l in raw:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s*)?(\w+)', l)
        if m:
            w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
            ports.append((m.group(1), w, m.group(4)))
    body = '\n'.join(lines[pe + 1:])
    return raw, ports, body


def classify(body):
    indexed, passthru, special = set(), {}, {}
    for m in re.finditer(r'assign io_out_complexDecodedInsts_(\d)_bits_(\w+) =\s*([^;]+);', body):
        s, f, rhs = int(m.group(1)), m.group(2), ' '.join(m.group(3).split())
        if re.fullmatch(r'_GEN_\d+\[count\]', rhs):
            indexed.add(f)
        elif rhs == 'latchedInst_' + f:
            passthru.setdefault(f, set()).add(s)
        else:
            special.setdefault(f, set()).add(s)
    return indexed, passthru, special


def emit_struct(ports):
    fields = [(w, n[len(IN_PFX):]) for d, w, n in ports if n.startswith(IN_PFX)]
    lines = []
    lines.append('  // 下面这一段由 verif/ut/DecodeUnitComp/gen.py 从 golden 的')
    lines.append('  // io_in_bits_simpleDecodedInst_* 端口表机械生成，成员名与 golden 逐字同名')
    lines.append('  // （便于与 golden 对照），位宽也取自 golden。不要手改。')
    lines.append('  typedef struct packed {')
    done = set()
    for w, n in fields:
        hit = None
        for pfx, (mem, cnt) in ARRAYS.items():
            if n.startswith(pfx) and n[len(pfx):].isdigit():
                hit = (pfx, mem, cnt)
                break
        if hit:
            pfx, mem, cnt = hit
            if mem in done:
                continue
            done.add(mem)
            ew = w
            if ew == 1:
                lines.append(f'    logic [{cnt - 1}:0]{"":10s}{mem};')
            else:
                lines.append(f'    logic [{cnt - 1}:0][{ew - 1}:0]{"":4s}{mem};')
        else:
            decl = '' if w == 1 else f'[{w - 1}:0]'
            lines.append(f'    logic {decl:14s}{n};')
    lines.append('  } static_inst_t;')
    return lines


def emit_ports(raw):
    return ['  ' + l.strip() if l.strip() else l for l in raw[:-1]] + ['  ' + raw[-1].strip()[:-2]]


def sv_conn(field, src):
    return f'  assign {field} = {src};'


def emit_wrapper(ports, indexed, passthru, special):
    L = []
    L.append('  // 下面这一段由 verif/ut/DecodeUnitComp/gen.py 生成：输入打包成 struct、')
    L.append('  // 核的输出摊回 748 根扁平线。每根线走哪条路由 golden 的 assign 现场分类，')
    L.append('  // 分类结果与脚本里的期望集合逐个核对，golden 一变这里立刻红。不要手改。')
    L.append('')
    L.append('  static_inst_t  in_inst;')
    L.append('  uop_info_t     in_uop_info;')
    L.append('  vtype_t        vtype_bypass;')
    L.append('  static_inst_t  latched;')
    L.append('  uop_var_t [5:0] out_var;')
    L.append('  logic           exception_ii;')
    L.append('  logic [6:0]     latched_num_of_uop, latched_num_of_wb;')
    L.append('  logic [5:0]     out_valid;')
    L.append('')
    L.append('  // ---- 输入打包 ----')
    done = set()
    for d, w, n in ports:
        if not n.startswith(IN_PFX):
            continue
        f = n[len(IN_PFX):]
        hit = None
        for pfx, (mem, cnt) in ARRAYS.items():
            if f.startswith(pfx) and f[len(pfx):].isdigit():
                hit = (mem, int(f[len(pfx):]))
                break
        if hit:
            L.append(f'  assign in_inst.{hit[0]}[{hit[1]}] = {n};')
        else:
            L.append(f'  assign in_inst.{f} = {n};')
        done.add(f)
    L.append('  assign in_uop_info.numOfUop = io_in_bits_uopInfo_numOfUop;')
    L.append('  assign in_uop_info.numOfWB  = io_in_bits_uopInfo_numOfWB;')
    L.append('  assign in_uop_info.lmul     = io_in_bits_uopInfo_lmul;')
    L.append('  assign vtype_bypass.illegal = io_vtypeBypass_illegal;')
    L.append('  assign vtype_bypass.vma     = io_vtypeBypass_vma;')
    L.append('  assign vtype_bypass.vta     = io_vtypeBypass_vta;')
    L.append('  assign vtype_bypass.vsew    = io_vtypeBypass_vsew;')
    L.append('  assign vtype_bypass.vlmul   = io_vtypeBypass_vlmul;')
    L.append('')
    L.append('  xs_DecodeUnitComp_core u_core (')
    L.append('    .clock              (clock),')
    L.append('    .reset              (reset),')
    L.append('    .redirect           (io_redirect),')
    L.append('    .vtype_bypass       (vtype_bypass),')
    L.append('    .in_valid           (io_in_valid),')
    L.append('    .in_ready           (io_in_ready),')
    L.append('    .in_inst            (in_inst),')
    L.append('    .in_uop_info        (in_uop_info),')
    L.append('    .out0_ready         (io_out_complexDecodedInsts_0_ready),')
    L.append('    .out_valid          (out_valid),')
    L.append('    .complex_num        (io_complexNum),')
    L.append('    .latched            (latched),')
    L.append('    .latched_num_of_uop (latched_num_of_uop),')
    L.append('    .latched_num_of_wb  (latched_num_of_wb),')
    L.append('    .exception_ii       (exception_ii),')
    L.append('    .out_var            (out_var)')
    L.append('  );')
    L.append('')
    L.append('  // ---- 输出摊平 ----')
    for s in range(6):
        L.append(f'  assign {OUT_PFX}{s}_valid = out_valid[{s}];')
        for d, w, n in ports:
            m = re.match(rf'{OUT_PFX}{s}_bits_(\w+)$', n)
            if not m:
                continue
            f = m.group(1)
            if f in indexed:
                hit = None
                for pfx, (mem, cnt) in ARRAYS.items():
                    if f.startswith(pfx) and f[len(pfx):].isdigit() and mem in ('srcType', 'lsrc'):
                        hit = (mem, int(f[len(pfx):]))
                        break
                src = f'out_var[{s}].{hit[0]}[{hit[1]}]' if hit else f'out_var[{s}].{f}'
            elif f == 'exceptionVec_2':
                src = 'exception_ii'
            elif f == 'numUops':
                src = 'latched_num_of_uop'
            elif f == 'numWB':
                src = 'latched_num_of_wb'
            else:
                hit = None
                for pfx, (mem, cnt) in ARRAYS.items():
                    if f.startswith(pfx) and f[len(pfx):].isdigit():
                        hit = (mem, int(f[len(pfx):]))
                        break
                src = f'latched.{hit[0]}[{hit[1]}]' if hit else f'latched.{f}'
            L.append(f'  assign {n} = {src};')
        L.append('')
    return L


def emit_var_struct():
    L = ['  // uop_var_t —— 逐 uop 变化的 31 个字段（其余 75 个字段整条指令共用，走',
         '  // latched 直通）。这 31 个是从 golden 现场分类出来的：只有它们的输出',
         '  // assign 形如 `_GEN_xxxx[count]`。',
         '  typedef struct packed {']
    for name, kind, cnt, w, zh in VAR_MEMBERS:
        if kind == 'array':
            decl = f'[{cnt - 1}:0][{w - 1}:0]'
        else:
            decl = '' if w == 1 else f'[{w - 1}:0]'
        L.append(f'    logic {decl:14s}{name};   // {zh}')
    L.append('  } uop_var_t;')
    return L


def splice(txt, tag, lines):
    b = f'// BEGIN GENERATED({tag})'
    e = '// END GENERATED'
    i = txt.index(b)
    j = txt.index(e, i)
    indent = ' ' * (txt.rfind('\n', 0, i) and (i - txt.rfind('\n', 0, i) - 1))
    return txt[:i + len(b)] + '\n' + '\n'.join(lines) + '\n' + indent + txt[j:]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    raw, ports, body = golden_ports()
    indexed, passthru, special = classify(body)
    if indexed != EXPECT_INDEXED:
        sys.exit(f'gen.py: golden 的「逐 uop 字段」集合变了\n  多: {indexed - EXPECT_INDEXED}\n'
                 f'  少: {EXPECT_INDEXED - indexed}')
    if set(special) != EXPECT_SPECIAL:
        sys.exit(f'gen.py: golden 的「特殊字段」集合变了: {set(special)}')
    if len(ports) != 748:
        sys.exit(f'gen.py: golden 端口数变了：{len(ports)}')

    txt = RTL.read_text()
    txt = splice(txt, 'struct', emit_struct(ports))
    txt = splice(txt, 'varstruct', emit_var_struct())
    txt = splice(txt, 'ports', emit_ports(raw))
    txt = splice(txt, 'wrapper', emit_wrapper(ports, indexed, passthru, special))

    outs = [(RTL, txt), (HERE / 'tb.sv', emit_tb(ports))]
    rc = 0
    for p, t in outs:
        old = p.read_text() if p.exists() else None
        if old == t:
            print(f'  same  {p.relative_to(REPO)}')
        elif a.check:
            print(f'  DRIFT {p.relative_to(REPO)}')
            rc = 1
        else:
            p.write_text(t)
            print(f'  write {p.relative_to(REPO)}')
    return rc


def emit_tb(ports):
    return TB_TEXT(ports)



# ---------------------------------------------------------------------------
# tb.sv
# ---------------------------------------------------------------------------
SPLIT_TYPES = [
    ('SCA_SIM', 0x00), ('VEC_MVNR', 0x04), ('VSET', 0x11), ('VEC_VVV', 0x12),
    ('VEC_VXV', 0x13), ('VEC_0XV', 0x14), ('VEC_VVW', 0x15), ('VEC_WVW', 0x16),
    ('VEC_VXW', 0x17), ('VEC_WXW', 0x18), ('VEC_WVV', 0x19), ('VEC_WXV', 0x1A),
    ('VEC_EXT2', 0x1B), ('VEC_EXT4', 0x1C), ('VEC_EXT8', 0x1D), ('VEC_VVM', 0x1E),
    ('VEC_VXM', 0x1F), ('VEC_SLIDE1UP', 0x20), ('VEC_FSLIDE1UP', 0x21),
    ('VEC_SLIDE1DOWN', 0x22), ('VEC_FSLIDE1DOWN', 0x23), ('VEC_VRED', 0x24),
    ('VEC_SLIDEUP', 0x25), ('VEC_SLIDEDOWN', 0x27), ('VEC_M0X', 0x29),
    ('VEC_MVV', 0x2A), ('VEC_VWW', 0x2C), ('VEC_RGATHER', 0x2D),
    ('VEC_RGATHER_VX', 0x2E), ('VEC_RGATHEREI16', 0x2F), ('VEC_COMPRESS', 0x30),
    ('VEC_US_LDST', 0x31), ('VEC_S_LDST', 0x32), ('VEC_I_LDST', 0x33),
    ('VEC_US_FF_LD', 0x34), ('AMO_CAS_W', 0x35), ('AMO_CAS_D', 0x36),
    ('AMO_CAS_Q', 0x37), ('VEC_VFV', 0x38), ('VEC_VFW', 0x39), ('VEC_WFW', 0x3A),
    ('VEC_VFM', 0x3B), ('VEC_VFRED', 0x3C), ('VEC_VFREDOSUM', 0x3D),
    ('dummy', 0x3F),
]

TB_HEAD = '''// =============================================================================
// DecodeUnitComp UT —— golden DecodeUnitComp 对重写 DecodeUnitComp_xs 双例化，
// 同激励逐拍比对**全部输出线**（6 路 × 105/106 个 DecodedInst 字段 + 6 个 valid
// + complexNum + in_ready，共 638 根）。
//
// ★ 这个 DUT 的判别力全在「uopSplitType × vlmul × vsew × 握手相位」四维乘积上 ★
// 它是一张按 uopSplitType 分 43 个分支的大表，每个分支再按 vlmul/vsew 分叉，把一条
// 复杂向量指令拆成最多 65 个 uop，再每拍吐 6 个。所以：
//   · uopSplitType 必须**定向**覆盖 45 个已定义编码（含 SCA_SIM/dummy）与未定义编码；
//     6 位均匀随机既命不匀、也保证不了每个分支下的 vlmul/vsew 子分支都打到。
//   · numOfUop 必须常常 > 6，否则一拍出完、count 永远是 0，
//     「按 count 取第几组 uop」这条主路径等于没验。
//   · out0_ready 要做长条 0/1，让 count 一路走到 10。
//   · redirect 要在 count 走到一半时插进来。
//
// ★ 复位窗口也比对 ★
// 本模块有 99 个**不带复位**的锁存寄存器（latchedInst/latchedUopInfo）与 3 个带
// 异步复位的状态寄存器。比对窗口按绝对拍数开闸（暖机 WARMUP 拍），开了之后
// 连 rst 拉高的拍也一起比 —— 复位期间照常打激励，而且运行中会多次异步复位。
// 这样「复位域写错」才有可观测窗口（本轮别的 lane 踩过：只在 !rst 时比对，
// 复位域 mutant 直接漏检）。
//
// ★ 覆盖证据 ★
// 覆盖统计全部取自 **golden 侧**的内部信号（独立于被测件）：
// (uopSplitType, vlmul) 的命中次数、count 的取值分布、状态机迁移。
// 任何一个已定义 split 类型、或任何一个 count 取值为 0，这一轮 errors=0 都不作数。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  localparam int WARMUP = 64;      // 比对窗口按绝对拍数开闸，之后连复位拍一起比
  bit  clk = 0;
  logic rst;
  int  errors = 0;
  longint checks = 0;
  always #5 clk = ~clk;
'''

TB_STIM = '''
  // ---- 45 个已定义的 uopSplitType 编码（含 SCA_SIM 与 dummy）----
  localparam int NSPLIT = %(nsplit)d;
  logic [5:0] split_code [NSPLIT];
  string      split_name [NSPLIT];
  longint     cov_split  [64];
  longint     cov_split_vlmul [64][8];
  longint     cov_count  [16];
  longint     cov_state  [2];
  longint     cov_redir_active = 0;
  longint     cov_numuop_gt6 = 0;
  longint     cov_backpressure = 0;
  longint     cov_widen_osum = 0;   // VEC_VFREDOSUM 的「加宽」支
  longint     cov_plain_osum = 0;   // VEC_VFREDOSUM 的「非加宽」支
  longint     cov_us_seg = 0, cov_ix_seg = 0, cov_sd_seg = 0;  // 三种段访存

  initial begin
%(splitinit)s  end

  // numOfUop 的取值分布：小值（一拍出完）/ 刚过 6（count 走一两格）/
  // 大值（count 走到 10）/ 0（golden 有断言的非法值，输出仍须一致）。
  function automatic logic [6:0] gen_numuop();
    case ($urandom_range(0, 9))
      0:       return 7'd0;
      1, 2, 3: return 7'($urandom_range(1, 6));
      4, 5:    return 7'($urandom_range(7, 16));
      6, 7:    return 7'($urandom_range(17, 48));
      default: return 7'($urandom_range(49, 65));
    endcase
  endfunction

  // out0_ready 做成长条：连续若干拍全 1 或全 0，制造 count 连续推进与反压。
  int ready_run = 0;
  logic ready_lvl = 1'b1;
  function automatic logic next_ready();
    if (ready_run == 0) begin
      ready_run = $urandom_range(1, 12);
      ready_lvl = ($urandom_range(0, 3) != 0);   // 3/4 概率给 ready
    end
    ready_run--;
    return ready_lvl;
  endfunction

  task automatic drive_random_inputs();
    // 先给**所有**输入一份随机值（包括 75 个纯直通字段，它们的接线错也要能抓到），
    // 再把有判别力的几个覆盖掉。
%(randdrive)s  endtask
'''


def TB_TEXT(ports):
    ins = [(w, n) for d, w, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in ports if d == 'output']
    L = [TB_HEAD]
    L.append('  // ---- 输入（两个 DUT 共用）----')
    for w, n in ins:
        d = '' if w == 1 else f'[{w-1}:0]'
        L.append(f'  logic {d:10s} {n};')
    L.append('')
    L.append('  // ---- 输出（golden g_ / 重写 x_ 各一份）----')
    for w, n in outs:
        d = '' if w == 1 else f'[{w-1}:0]'
        L.append(f'  logic {d:10s} g_{n}, x_{n};')
    L.append('')
    for mod, inst, pfx in (('DecodeUnitComp', 'u_gold', 'g_'),
                           ('DecodeUnitComp_xs', 'u_xs', 'x_')):
        L.append(f'  {mod} {inst} (')
        conns = ['.clock(clk)', '.reset(rst)']
        conns += [f'.{n}({n})' for w, n in ins]
        conns += [f'.{n}({pfx}{n})' for w, n in outs]
        for k in range(0, len(conns), 3):
            last = (k + 3 >= len(conns))
            L.append('    ' + ', '.join(conns[k:k + 3]) + ('' if last else ','))
        L.append('  );')
        L.append('')

    splitinit = ''.join(
        f"    split_code[{i}] = 6'h{c:02X}; split_name[{i}] = \"{n}\";\n"
        for i, (n, c) in enumerate(SPLIT_TYPES))
    rand = ''
    for w, n in ins:
        if w <= 32:
            rand += f'    {n} = {w}\'($urandom);\n'
        else:
            rand += (f'    {n} = {{{w}\'($urandom), {w}\'($urandom)}} '
                     f'^ {w}\'($urandom);\n')
    L.append(TB_STIM % dict(nsplit=len(SPLIT_TYPES), splitinit=splitinit, randdrive=rand))

    # compare task
    L.append('  task automatic compare_outputs();')
    L.append('    checks++;')
    for w, n in outs:
        L.append(f'    if (g_{n} !== x_{n}) begin')
        L.append('      errors++;')
        L.append('      if (errors < 40)')
        L.append(f'        $display("MISMATCH %0t {n}: gold=%h xs=%h  split=%h vlmul=%h'
                 f' vsew=%h count=%0d state=%0b numOfUop=%0d",')
        L.append(f'                 $time, g_{n}, x_{n}, u_gold.latchedInst_uopSplitType,')
        L.append('                 u_gold.latchedInst_vpu_vlmul, u_gold.latchedInst_vpu_vsew,')
        L.append('                 u_gold.count, u_gold.state, u_gold.latchedUopInfo_numOfUop);')
        L.append('    end')
    L.append('  endtask')
    L.append('')
    L.append(TB_BODY)
    return '\n'.join(L)


TB_BODY = '''
  int si;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < 64; i++) begin
      cov_split[i] = 0;
      for (int j = 0; j < 8; j++) cov_split_vlmul[i][j] = 0;
    end
    for (int i = 0; i < 16; i++) cov_count[i] = 0;
    cov_state[0] = 0; cov_state[1] = 0;

    rst = 1'b1;
    drive_random_inputs();
    io_in_valid = 1'b0;
    io_redirect = 1'b0;
    repeat (4) @(negedge clk);
    rst = 1'b0;

    for (longint c = 0; c < NCYCLES; c++) begin
      // 运行中多次异步复位：每约 4000 拍来一次 3 拍的复位，复位期间照常打激励。
      rst = ((c % 4096) < 3) && (c > WARMUP);

      drive_random_inputs();
      // uopSplitType：85% 从 45 个已定义编码里定向取，15% 随机（含未定义编码）
      if ($urandom_range(0, 99) < 85) begin
        si = $urandom_range(0, NSPLIT - 1);
        io_in_bits_simpleDecodedInst_uopSplitType = split_code[si];
      end
      // vlmul / vsew 全取值等概率（分支全挂在它们上面）
      io_in_bits_simpleDecodedInst_vpu_vlmul = 3'($urandom);
      io_in_bits_simpleDecodedInst_vpu_vsew  = 2'($urandom);
      io_in_bits_uopInfo_lmul                = 4'($urandom_range(0, 8));
      io_in_bits_uopInfo_numOfUop            = gen_numuop();
      io_in_bits_uopInfo_numOfWB             = gen_numuop();
      // vstart：一半为 0（正常），一半非零（VSET 分支靠它改 flushPipe/blockBackward）
      io_in_bits_simpleDecodedInst_vpu_vstart =
          $urandom_range(0, 1) ? 8'($urandom) : 8'h0;
      // isVset / fuOpType：VSET 分支的四条子路径全靠它们 + rd/rs1 是否为 0。
      // ★fuOpType 还要定向打 9'h36★：VEC_VFREDOSUM 分支按
      // `fuOpType == VfaluType.vfwredosum`(=9'h36) 分成「加宽有序归约」与普通两支，
      // 9 位均匀随机只有 1/512 命中率，200k 拍下来那一支只有个位数次，等于没验。
      io_in_bits_simpleDecodedInst_isVset = ($urandom_range(0, 2) != 0);
      io_in_bits_simpleDecodedInst_fuOpType =
          ($urandom_range(0, 4) == 0) ? 9'h36 : 9'($urandom);
      // instr 的 rd/rs1 域：各 1/3 概率取 0（VSET 的分支条件）
      if ($urandom_range(0, 2) == 0) io_in_bits_simpleDecodedInst_instr[11:7]  = 5'h0;
      if ($urandom_range(0, 2) == 0) io_in_bits_simpleDecodedInst_instr[19:15] = 5'h0;
      // srcType_0：imm / fp / xp / vp 等概率（VEC_0XV / VEC_VXV 按它分叉）
      io_in_bits_simpleDecodedInst_srcType_0 =
          (4'h1 << $urandom_range(0, 3)) >> 1;
      io_in_valid = ($urandom_range(0, 9) != 0);          // 90% 有效
      io_redirect = ($urandom_range(0, 199) == 0);        // 0.5% 冲刷
      io_out_complexDecodedInsts_0_ready = next_ready();

      #1;
      if (c > WARMUP) compare_outputs();
      // 覆盖统计全部取自 golden 内部
      if (u_gold.state) begin
        cov_split[u_gold.latchedInst_uopSplitType]++;
        cov_split_vlmul[u_gold.latchedInst_uopSplitType][u_gold.latchedInst_vpu_vlmul]++;
        cov_count[u_gold.count]++;
        if (u_gold.latchedUopInfo_numOfUop > 7'd6) cov_numuop_gt6++;
        if (!io_out_complexDecodedInsts_0_ready) cov_backpressure++;
        if (io_redirect) cov_redir_active++;
        if (u_gold.latchedInst_uopSplitType == 6'h3D) begin
          if (u_gold.latchedInst_fuOpType == 9'h36) cov_widen_osum++;
          else                                      cov_plain_osum++;
        end
        if (u_gold.isUsSegment) cov_us_seg++;
        if (u_gold.isIxSegment) cov_ix_seg++;
        if (u_gold.isSdSegment) cov_sd_seg++;
      end
      cov_state[u_gold.state]++;
      @(negedge clk);
    end

    $display("=== COVERAGE (DecodeUnitComp) ===");
    $display("  checks=%0d  state idle=%0d active=%0d", checks, cov_state[0], cov_state[1]);
    $display("  numOfUop>6 while active=%0d  backpressure=%0d  redirect while active=%0d",
             cov_numuop_gt6, cov_backpressure, cov_redir_active);
    $display("  vfredosum 加宽支=%0d 非加宽支=%0d   段访存 us=%0d ix=%0d sd=%0d",
             cov_widen_osum, cov_plain_osum, cov_us_seg, cov_ix_seg, cov_sd_seg);
    begin
      int zero_split = 0, zero_count = 0;
      longint minsplit = -1;
      for (int i = 0; i < NSPLIT; i++) begin
        if (cov_split[split_code[i]] == 0) begin
          zero_split++;
          $display("  ZERO-HIT uopSplitType %s (6'h%02h)", split_name[i], split_code[i]);
        end
        if (minsplit < 0 || cov_split[split_code[i]] < minsplit)
          minsplit = cov_split[split_code[i]];
      end
      for (int k = 0; k < 11; k++)
        if (cov_count[k] == 0) begin
          zero_count++;
          $display("  ZERO-HIT count=%0d", k);
        end
      $display("  uopSplitType: %0d 个已定义编码，未命中 %0d，最少命中 %0d",
               NSPLIT, zero_split, minsplit);
      $display("  count 0..10 未命中 %0d 个", zero_count);
      if (zero_split != 0 || zero_count != 0) begin
        $display("COVERAGE INSUFFICIENT");
        errors++;
      end
      if (cov_numuop_gt6 == 0 || cov_backpressure == 0 || cov_redir_active == 0) begin
        $display("COVERAGE INSUFFICIENT: 长序列 / 反压 / 冲刷 有一项没打到");
        errors++;
      end
      // 这五项各自守着一个「整条分支只有一半被验到」的风险：
      // 加宽/非加宽有序归约是 VEC_VFREDOSUM 的两半，三种段访存各自决定
      // waitForward/blockBackward 那一对。
      if (cov_widen_osum == 0 || cov_plain_osum == 0 ||
          cov_us_seg == 0 || cov_ix_seg == 0 || cov_sd_seg == 0) begin
        $display("COVERAGE INSUFFICIENT: vfwredosum 两支 / 三种段访存 有一项没打到");
        errors++;
      end
    end

    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end

endmodule
'''


if __name__ == "__main__":
    sys.exit(main())
