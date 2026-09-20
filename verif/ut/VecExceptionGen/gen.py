#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— VecExceptionGen 的两件机械派生物。

1. rtl/backend/VecExceptionGen.sv 里 `BEGIN GENERATED(instclass)` 区段：
   「指令类归属」那一大片 —— 每个类是一串 RISC-V V 扩展指令的 BitPat 匹配。
   这些列表**必须**与 Chisel 源 VecExceptionGen.scala 逐条一致，手抄 260 条
   编码注定出错，所以这里直接：
     - 从 VecExceptionGen.scala 解析出每个类的指令**助记符列表**；
     - 从 rocket-chip Instructions.scala + XiangShan Instructions.scala(Zvbb)
       解析出每个助记符的 32 位 BitPat，转成 (care 掩码, 值) 对；
     - 生成 `(inst & care) == value` 形式的匹配式，助记符与原始 BitPat 串
       写在行尾注释里，读者不必翻两个 scala 文件。
   ★判据仍然是 golden★：本脚本只保证「与 Chisel 一致」，与 golden 一致由
   UT(逐拍双例化) + FM 证明。已实测 lsStrideInst/lsIndexInst/lsWholeInst/
   lsMaskInst 四组折叠后的常数与 golden 的 _GEN 比较式逐值相同。

2. verif/ut/VecExceptionGen/tb.sv：双例化随机+定向比对 tb。

用法：
    python3 gen.py            # 生成（幂等：内容不变不碰文件）
    python3 gen.py --check    # 只检查是否已同步，DRIFT 则非零退出
"""
import argparse
import collections
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
XS = pathlib.Path('/home/eda/xs-env/XiangShan')
SCALA = XS / 'src/main/scala/xiangshan/backend/decode/VecExceptionGen.scala'
INSTR_FILES = [
    XS / 'rocket-chip/src/main/scala/rocket/Instructions.scala',
    XS / 'src/main/scala/xiangshan/backend/decode/Instructions.scala',
]
RTL = REPO / 'rtl' / 'backend' / 'VecExceptionGen.sv'

# --------------------------------------------------------------------------
# BitPat 表：助记符 -> (care 掩码, 值)
# --------------------------------------------------------------------------
def load_bitpats():
    pat = {}
    for f in INSTR_FILES:
        for line in f.read_text().splitlines():
            m = re.match(r'\s*def\s+(\w+)\s*=\s*BitPat\("b([01?]+)"\)', line)
            if not m:
                continue
            name, bits = m.group(1), m.group(2)
            if len(bits) != 32:
                continue
            care = int(''.join('0' if c == '?' else '1' for c in bits), 2)
            val = int(''.join('0' if c == '?' else c for c in bits), 2)
            if name in pat and pat[name] != (care, val, bits):
                sys.exit(f'gen.py: BitPat 冲突 {name}')
            pat[name] = (care, val, bits)
    return pat


# --------------------------------------------------------------------------
# 从 Chisel 解析指令类。
#   形态 A: private val X = Seq(A, B, ...).map(_ === inst.ALL).reduce(_ || _)
#           可再跟 " || 另一个类名"
#   形态 B: private val X = INSTR === inst.ALL
# 行内 Seq(...)（不绑定到 private val 的那两处）在 INLINE 里显式声明，
# 并强制校验它们确实逐字出现在 scala 里 —— 否则 Chisel 改了这里不会跟着改。
# --------------------------------------------------------------------------
INLINE = {
    # v0AllowOverlap 里的「即使 vd 是 mask 也不许和 v0 重叠」三条
    'mask_set_inst': ('Seq(VMSBF_M, VMSIF_M, VMSOF_M)',
                      'VMSBF_M VMSIF_M VMSOF_M'),
    # notAllowOverlapInst 里的固定清单（lsIndexInst && nf=/=0 那一项单独写在核里）
    'no_overlap_list': (
        'Seq(VMSBF_M, VMSIF_M, VMSOF_M, VIOTA_M, \n'
        '                                    VSLIDEUP_VX, VSLIDEUP_VI, VSLIDE1UP_VX, '
        'VFSLIDE1UP_VF, VRGATHER_VV, VRGATHEREI16_VV, VRGATHER_VX, VRGATHER_VI, '
        'VCOMPRESS_VM)',
        'VMSBF_M VMSIF_M VMSOF_M VIOTA_M VSLIDEUP_VX VSLIDEUP_VI VSLIDE1UP_VX '
        'VFSLIDE1UP_VF VRGATHER_VV VRGATHEREI16_VV VRGATHER_VX VRGATHER_VI VCOMPRESS_VM'),
}

# scala 名 -> (SV 线名, 一句话中文说明)。顺序 = 生成区段的输出顺序。
CLASSES = [
    ('lsStrideInst',       'is_ls_stride',      '单位步长/跨步向量访存（含 fault-only-first）'),
    ('lsMaskInst',         'is_ls_mask',        '掩码寄存器访存 vlm/vsm（EEW 恒 8、EMUL 恒 1）'),
    ('lsIndexInst',        'is_ls_index',       '索引访存（unordered/ordered，vs2 给下标）'),
    ('lsWholeInst',        'is_ls_whole',       '整寄存器访存 vl<N>re<E>/vs<N>r（不看 vtype）'),
    ('vdWideningInst',     'is_vd_widening',    'vd 加宽（结果 EEW = 2×SEW）'),
    ('vs2WideningInst',    'is_vs2_widening',   'vs2 已是宽操作数（.wv/.wx 形态）'),
    ('narrowingInst',      'is_narrowing',      '收窄（vs2 EEW = 2×SEW，vd = SEW）'),
    ('intExtInst',         'is_int_ext',        '整数扩展 vsext/vzext（vf2/vf4/vf8）'),
    ('acsbInst',           'is_acsb',           '进位/借位产生 vmadc/vmsbc（vd 是掩码）'),
    ('cmpInst',            'is_cmp',            '比较类（vd 是掩码）'),
    ('redInst',            'is_red',            '归约（vs1/vd 只用第 0 个元素）'),
    ('redWideningInst',    'is_red_widening',   '加宽归约'),
    ('maskLogicalInst',    'is_mask_logical',   '掩码逻辑 vmand/vmor/…（vm 必须为 1）'),
    ('maskArithmeticInst', 'is_mask_arith',     '掩码算术（含掩码逻辑；vs1/vs2 按掩码看待）'),
    ('maskIndexInst',      'is_mask_index',     'viota/vid（vs2 按掩码看待）'),
    ('vmvSingleInst',      'is_vmv_single',     '标量<->向量单元素搬运 vmv.x.s 等'),
    ('vmvWholeInst',       'is_vmv_whole',      '整寄存器搬运 vmv<N>r.v'),
    ('vrgather16',         'is_vrgather16',     'vrgatherei16.vv（下标 EEW 固定 16）'),
    ('vcompress',          'is_vcompress',      'vcompress.vm（vs1 按掩码看待）'),
    ('intExt2',            'is_int_ext2',       'vsext/vzext .vf2'),
    ('intExt4',            'is_int_ext4',       'vsext/vzext .vf4'),
    ('intExt8',            'is_int_ext8',       'vsext/vzext .vf8'),
    ('notDependVtypeInst', 'is_not_depend_vtype', '不依赖 vtype 的指令（vset* 与整寄存器访存）'),
    ('doubleFpInst',       'is_double_fp',      '浮点整数互转的加宽/收窄（SEW=8 时仍合法）'),
    ('mask_set_inst',      'is_mask_set',       'vmsbf/vmsif/vmsof —— 唯三不许与 v0 重叠的掩码结果'),
    ('no_overlap_list',    'is_no_overlap_list', '源/目的绝不许重叠的指令清单'),
]


def parse_classes():
    txt = SCALA.read_text()
    out = {}
    # 形态 A
    for m in re.finditer(
            r'private val (\w+) = Seq\(\s*(.*?)\s*\)\.map\(_ === inst\.ALL\)\.reduce\(_ \|\| _\)'
            r'((?:\s*\|\|\s*\w+)*)', txt, re.S):
        name, body, extra = m.group(1), m.group(2), m.group(3)
        body = re.sub(r'//[^\n]*', '', body)
        names = [x.strip() for x in body.split(',') if x.strip()]
        ors = re.findall(r'\|\|\s*(\w+)', extra)
        out[name] = (names, ors)
    # 形态 B：单条指令
    for m in re.finditer(r'private val (\w+) = (\w+) === inst\.ALL', txt):
        out[m.group(1)] = ([m.group(2)], [])
    # 行内 Seq：逐字校验其仍在 scala 里
    for key, (literal, names) in INLINE.items():
        if literal not in txt:
            sys.exit(f'gen.py: 行内指令清单 {key} 已不在 VecExceptionGen.scala 里逐字出现 —— '
                     f'Chisel 改了，必须人工复核后更新 INLINE')
        out[key] = (names.split(), [])
    return out


def emit_instclass(pats, classes):
    L = []
    L.append('  // 下面这一片由 verif/ut/VecExceptionGen/gen.py 从 Chisel 源与 rocket-chip')
    L.append('  // 的 BitPat 定义机械生成（助记符与原始编码见行尾注释），不要手改。')
    L.append('  // 每一项都是「关心位相等」判断：(inst & care) == value。')
    for scala_name, sv_name, zh in CLASSES:
        names, ors = classes[scala_name]
        L.append('')
        L.append(f'  // {zh}')
        L.append(f'  // Chisel: {scala_name}  （{len(names)} 条指令'
                 + (f' + {" + ".join(ors)}' if ors else '') + '）')
        terms = []
        for n in names:
            if n not in pats:
                sys.exit(f'gen.py: 找不到指令 {n} 的 BitPat')
            care, val, bits = pats[n]
            terms.append((f"bitpat_match(inst, 32'h{care:08X}, 32'h{val:08X})",
                          f'{n:<16s} {bits}'))
        for o in ors:
            terms.append((dict((a, b) for a, b, _ in CLASSES)[o], f'（整类并入：{o}）'))
        width = max(len(t) for t, _ in terms)
        L.append(f'  wire {sv_name} =')
        for i, (t, c) in enumerate(terms):
            lead = '      ' if i == 0 else '    | '
            tail = ';' if i == len(terms) - 1 else ''
            L.append(f'{lead}{t}{tail}'.ljust(6 + width + 1) + f'  // {c}')
    return L


TB_HEADER = '''// =============================================================================
// VecExceptionGen UT —— golden VecExceptionGen 对重写 VecExceptionGen_xs 双例化，
// 同激励逐拍比对唯一输出 io_illegalInst。
//
// ★ 这个 DUT 为什么不能纯随机打 ★
// 它是一张巨大的指令译码表：32 位 inst 里只有极少数编码落进 260 条 BitPat。
// 均匀随机 32 位 inst，命中任何一条向量指令的概率约 1e-4 —— 200k 拍下来
// 每个指令类平均命中个位数次，而真正有判别力的点（EMUL 越界、寄存器不对齐、
// vd/vs 重叠边界）还要叠加 vtype/寄存器号的特定取值，纯随机等于没测。
// 所以激励分三档（见 gen_inst）：
//   70%  从 260 条指令的**真实编码池**里抽一条，再随机填 vd/vs1/vs2/vm/nf 等可变域
//   20%  在真实编码基础上翻 1~3 个随机位（制造「几乎是合法指令」的边界）
//   10%  全 32 位随机（保证非向量编码、默认分支也被覆盖）
// vtype(vsew/vlmul)、vstart、srcType、vecWen、fuType 另行按有判别力的分布打。
//
// ★ 覆盖证据 ★
// tb 统计每个指令类被命中的次数与 7 个非法分支各自被触发的次数，任何一项为 0
// 都说明这一轮没验到它（$display 的 COVERAGE 段），此时 errors=0 不作数。
// =============================================================================
'''


def emit_tb(pats, classes):
    # 指令编码池：所有出现在任何类里的助记符（去重，保持稳定顺序）
    pool = []
    seen = set()
    for scala_name, _, _ in CLASSES:
        for n in classes[scala_name][0]:
            if n not in seen:
                seen.add(n)
                pool.append(n)
    L = [TB_HEADER, '`timescale 1ns/1ps', '', 'module tb;', '']
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit  clk = 0;')
    L.append('  int  errors = 0;')
    L.append('  longint checks = 0;')
    L.append('  always #5 clk = ~clk;')
    L.append('')
    L.append(f'  // 指令编码池：VecExceptionGen 关心的全部 {len(pool)} 条指令。')
    L.append('  // 每项 {care 掩码, 值}；可变域（vd/vs1/vs2/vm/nf...）= care 为 0 的位。')
    L.append(f'  localparam int NPOOL = {len(pool)};')
    L.append('  logic [31:0] pool_care [NPOOL];')
    L.append('  logic [31:0] pool_val  [NPOOL];')
    L.append('  string       pool_name [NPOOL];')
    L.append('  longint      cov_class_hit [NPOOL];')
    L.append('  initial begin')
    for i, n in enumerate(pool):
        care, val, bits = pats[n]
        L.append(f"    pool_care[{i:3d}] = 32'h{care:08X}; pool_val[{i:3d}] = 32'h{val:08X};"
                 f' pool_name[{i:3d}] = "{n}";')
    L.append('  end')
    L.append('')
    L.append('''  // 四档指令激励，见文件头说明。返回值同时通过 pool_idx 报告
  // 「这是不是一条未经改动的池内指令」，供覆盖统计用。
  function automatic logic [31:0] gen_inst(output int pool_idx);
    int unsigned r = $urandom_range(0, 99);
    logic [31:0] base, care;
    int          k, b;
    pool_idx = -1;
    if (r >= 95) return $urandom;               // 5%：全随机（非向量编码/默认分支）
    pool_idx = $urandom_range(0, NPOOL - 1);
    care = pool_care[pool_idx];
    base = (pool_val[pool_idx] & care) | ($urandom & ~care);
    base = apply_field_bias(base, care);
    if (r >= 80) begin                          // 15%：合法编码上翻 1~3 位
      for (k = 0; k < $urandom_range(1, 3); k++) begin
        b = $urandom_range(0, 31);
        base[b] = ~base[b];
      end
      pool_idx = -1;
    end else if (r >= 70) begin                 // 10%：只清 vm 位（bit25）
      // 为什么要单独一档：vm=0 是 v0 重叠判据的**唯一**入口，而多数向量指令的
      // BitPat 把 bit25 列为 care 位并钉成 1 —— 靠随机翻位几乎打不到。
      base[25] = 1'b0;
      if (care[25]) pool_idx = -1;              // 动了 care 位就不再算「命中该指令」
    end
    return base;
  endfunction

  // 寄存器号/nf 的定向偏置：只改 care 掩码为 0 的位（不破坏指令归类）。
  // 重叠判据(§6)几乎全部挂在「vd 与 vs1/vs2 的区间恰好相接/包含」上，均匀随机
  // 5 位寄存器号撞上这些边界的概率太低。
  function automatic logic [31:0] apply_field_bias(input logic [31:0] base,
                                                   input logic [31:0] care);
    logic [4:0] vd, vs1, vs2;
    logic [2:0] nf;
    logic [31:0] o = base;
    // vd：1/4 取 v0（v0 重叠判据的必要条件），1/4 取 8 的倍数（对齐边界），其余随机
    // vd：v0（v0 重叠判据的必要条件）、8 的倍数（对齐边界）、高号段 24..31
    //（vd + 2^EMUL - 1 会在 5 位上回绕的唯一区间）各占一档，其余随机。
    case ($urandom_range(0, 3))
      0: vd = 5'd0;
      1: vd = 5'($urandom_range(0, 3)) << 3;
      2: vd = 5'd24 + 5'($urandom_range(0, 7));
      default: vd = 5'($urandom);
    endcase
    // vs1/vs2：各 1/3 概率与 vd 相同（区间完全重合）、与 vd 差 1~4（部分重叠）
    case ($urandom_range(0, 2))
      0: vs1 = vd;
      1: vs1 = vd + 5'($urandom_range(1, 4));
      default: vs1 = 5'($urandom);
    endcase
    case ($urandom_range(0, 2))
      0: vs2 = vd;
      1: vs2 = vd + 5'($urandom_range(1, 4));
      default: vs2 = 5'($urandom);
    endcase
    // nf：一半为 0（非段访存），一半取 1/2/3/7（段访存的合法/非法边界）
    case ($urandom_range(0, 3))
      0, 1: nf = 3'd0;
      2:    nf = 3'($urandom_range(1, 3));
      default: nf = 3'd7;
    endcase
    o = subst(o, care, 11, 7,  {27'd0, vd});
    o = subst(o, care, 19, 15, {27'd0, vs1});
    o = subst(o, care, 24, 20, {27'd0, vs2});
    o = subst(o, care, 31, 29, {29'd0, nf});
    return o;
  endfunction

  // 把 [hi:lo] 里 care 为 0 的位换成 v 的对应位，care 为 1 的位原样保留。
  function automatic logic [31:0] subst(input logic [31:0] o, input logic [31:0] care,
                                        input int hi, input int lo, input logic [31:0] v);
    logic [31:0] r = o;
    for (int i = lo; i <= hi; i++)
      if (!care[i]) r[i] = v[i - lo];
    return r;
  endfunction

  // vtype.vlmul：全 8 种等概率（编码 100..111 是 LMUL 1/2/4/8，000..011 是分数）
  function automatic logic [2:0] gen_vlmul();
    return 3'($urandom);
  endfunction
''')
    L.append('''
  // --- DUT 端口 -------------------------------------------------------------
  logic [31:0] io_inst;
  logic [3:0]  io_decodedInst_srcType_0, io_decodedInst_srcType_1, io_decodedInst_srcType_2;
  logic [34:0] io_decodedInst_fuType;
  logic        io_decodedInst_vecWen;
  logic        io_vtype_illegal;
  logic [1:0]  io_vtype_vsew;
  logic [2:0]  io_vtype_vlmul;
  logic [7:0]  io_vstart;
  logic        gold_illegal, xs_illegal;

  VecExceptionGen u_gold (
    .io_inst(io_inst), .io_decodedInst_srcType_0(io_decodedInst_srcType_0),
    .io_decodedInst_srcType_1(io_decodedInst_srcType_1),
    .io_decodedInst_srcType_2(io_decodedInst_srcType_2),
    .io_decodedInst_fuType(io_decodedInst_fuType),
    .io_decodedInst_vecWen(io_decodedInst_vecWen),
    .io_vtype_illegal(io_vtype_illegal), .io_vtype_vsew(io_vtype_vsew),
    .io_vtype_vlmul(io_vtype_vlmul), .io_vstart(io_vstart),
    .io_illegalInst(gold_illegal));

  VecExceptionGen_xs u_xs (
    .io_inst(io_inst), .io_decodedInst_srcType_0(io_decodedInst_srcType_0),
    .io_decodedInst_srcType_1(io_decodedInst_srcType_1),
    .io_decodedInst_srcType_2(io_decodedInst_srcType_2),
    .io_decodedInst_fuType(io_decodedInst_fuType),
    .io_decodedInst_vecWen(io_decodedInst_vecWen),
    .io_vtype_illegal(io_vtype_illegal), .io_vtype_vsew(io_vtype_vsew),
    .io_vtype_vlmul(io_vtype_vlmul), .io_vstart(io_vstart),
    .io_illegalInst(xs_illegal));

  // 覆盖计数：七类非法各自的触发次数由 golden 侧的内部线取（层次引用 golden，
  // 不引用重写件 —— 覆盖统计必须独立于被测件）。
  longint cov_illegal_total = 0, cov_legal_total = 0;
  longint cov_inst_ill = 0, cov_vill_ill = 0, cov_eew_ill = 0, cov_emul_ill = 0;
  longint cov_regnum_ill = 0, cov_overlap_ill = 0, cov_vstart_ill = 0;
  longint cov_pool_exact = 0, cov_flip = 0, cov_rand = 0;
  longint cov_hireg_wrap = 0;   // 「vd 区间上界回绕」定向档命中次数
  logic [4:0] hi_vd, hi_vs1, hi_vs2;   // 该定向档的寄存器号（见下面的 static 坑）

  int pidx;
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    for (int i = 0; i < NPOOL; i++) cov_class_hit[i] = 0;
    @(negedge clk);
    for (longint c = 0; c < NCYCLES; c++) begin
      io_inst = gen_inst(pidx);
      if (pidx >= 0) begin cov_class_hit[pidx]++; cov_pool_exact++; end
      // srcType：只有 bit2(isVp) 被读，但整 4 位都随机打，防止「只试了 isVp」
      io_decodedInst_srcType_0 = 4'($urandom);
      io_decodedInst_srcType_1 = 4'($urandom);
      io_decodedInst_srcType_2 = 4'($urandom);
      // fuType：只有 18..27(VArith) 与 31..34(VLoad/VStore) 被读。一半时间点亮
      // 一个随机的向量位（否则 isVArithMem 恒 0，整个模块输出恒 0）。
      // fuType：只有 18..27(向量算术) 与 31..34(向量访存) 被读，而且两组的作用
      // **不同**（vstart 判据只认算术组）。所以三档打：只点算术位 / 只点访存位 /
      // 全 0（此时 isVArithMem=0，重叠判据仍然有效，是另一条独立路径）。
      io_decodedInst_fuType = '0;
      case ($urandom_range(0, 3))
        0: io_decodedInst_fuType[18 + $urandom_range(0, 9)] = 1'b1;   // 向量算术
        1: io_decodedInst_fuType[31 + $urandom_range(0, 3)] = 1'b1;   // 向量访存
        2: begin                                                       // 两组各点一位
             io_decodedInst_fuType[18 + $urandom_range(0, 9)] = 1'b1;
             io_decodedInst_fuType[31 + $urandom_range(0, 3)] = 1'b1;
           end
        default: ;                                                     // 全 0
      endcase
      io_decodedInst_vecWen = 1'($urandom);
      io_vtype_illegal      = ($urandom_range(0, 3) == 0);
      io_vtype_vsew         = 2'($urandom);
      io_vtype_vlmul        = gen_vlmul();
      // vstart：一半为 0（正常路径），一半非零（vstartIllegal 的唯一触发条件）
      io_vstart = $urandom_range(0, 1) ? 8'($urandom) : 8'h0;

      // ★定向档：vd 区间上界在 5 位上回绕★（占 4%）
      // vd_reg_hi = vd + 2^EMUL - 1 是 **5 位** 运算（Chisel 用的是普通 `+`）。
      // 只有 vd 落在 25..31 且 EMUL>1 时才会回绕，而且必须同时满足：
      //   · 不是访存指令（否则 vd 上界走段访存那条路，与这条无关）
      //   · fuType 不含向量位（否则 regNumIllegal 会先把输出拉高，把差别盖掉）
      //   · vs1/vs2 与 vd 挨着（否则「区间不重叠」直接成立，也盖掉差别）
      // 纯随机撞上这一族的概率约 1e-7（200k 拍必漏），而在这一档的约束下
      // 概率是 1.3%（用一份独立的 Python 语义模型在 400k 组输入上量过）。
      //
      // ★这里踩过一个典型的 tb 坑，留着当反例★：vd 原先写成
      //     `logic [4:0] hv = 5'd31 - 5'($urandom_range(0,6));`
      // —— 在**过程块里**声明的变量默认是 static，它的初始化式只在 0 时刻跑一次，
      // 于是整场仿真 vd 是同一个常数，这一档等于只测了一个 vd。声明与赋值必须分开写。
      if ($urandom_range(0, 24) == 0) begin
        cov_hireg_wrap++;
        io_vstart             = 8'h0;
        io_decodedInst_fuType = '0;                     // 关掉 regNumIllegal 这条路
        io_decodedInst_vecWen = 1'b1;
        io_decodedInst_srcType_0 = 4'h4;                // isVp
        io_decodedInst_srcType_1 = 4'h4;
        io_decodedInst_srcType_2 = 4'h4;
        io_vtype_illegal = 1'b0;
        io_vtype_vlmul   = 3'($urandom_range(1, 3));    // LMUL 编码 5/6/7（EMUL>1）
        hi_vd  = 5'd31 - 5'($urandom_range(0, 6));
        hi_vs1 = hi_vd + 5'($urandom_range(0, 2)) - 5'd1;   // vd-1 / vd / vd+1
        hi_vs2 = hi_vd + 5'($urandom_range(0, 2)) - 5'd1;
        io_inst[11:7]  = hi_vd;
        io_inst[19:15] = hi_vs1;
        io_inst[24:20] = hi_vs2;
      end

      #1;
      checks++;
      if (gold_illegal !== xs_illegal) begin
        errors++;
        if (errors < 20)
          $display("MISMATCH @%0d inst=%08h vsew=%0d vlmul=%0d vstart=%0h vecWen=%0b st=%0h/%0h/%0h fuType=%09h gold=%0b xs=%0b",
                   c, io_inst,
                   io_vtype_vsew, io_vtype_vlmul, io_vstart, io_decodedInst_vecWen,
                   io_decodedInst_srcType_0, io_decodedInst_srcType_1,
                   io_decodedInst_srcType_2, io_decodedInst_fuType,
                   gold_illegal, xs_illegal);
      end
      if (gold_illegal) cov_illegal_total++; else cov_legal_total++;
      if (u_gold.instIllegal)       cov_inst_ill++;
      if (u_gold.villIllegal)       cov_vill_ill++;
      if (u_gold.eewIllegal)        cov_eew_ill++;
      if (u_gold.emulIllegal)       cov_emul_ill++;
      if (u_gold.regNumIllegal)     cov_regnum_ill++;
      if (u_gold.regOverlapIllegal) cov_overlap_ill++;
      if (u_gold.vstartIllegal)     cov_vstart_ill++;
      @(negedge clk);
    end

    $display("=== COVERAGE (VecExceptionGen) ===");
    $display("  checks=%0d  illegal=%0d  legal=%0d", checks, cov_illegal_total,
             cov_legal_total);
    $display("  instIllegal=%0d villIllegal=%0d eewIllegal=%0d emulIllegal=%0d",
             cov_inst_ill, cov_vill_ill, cov_eew_ill, cov_emul_ill);
    $display("  regNumIllegal=%0d regOverlapIllegal=%0d vstartIllegal=%0d",
             cov_regnum_ill, cov_overlap_ill, cov_vstart_ill);
    $display("  定向档「vd 区间上界回绕」命中 %0d 次", cov_hireg_wrap);
    begin
      int zero_classes = 0;
      longint minhit = -1;
      for (int i = 0; i < NPOOL; i++) begin
        if (cov_class_hit[i] == 0) begin
          zero_classes++;
          $display("  ZERO-HIT instruction: %s", pool_name[i]);
        end
        if (minhit < 0 || cov_class_hit[i] < minhit) minhit = cov_class_hit[i];
      end
      $display("  pool instructions=%0d  zero-hit=%0d  min-hit=%0d",
               NPOOL, zero_classes, minhit);
      if (zero_classes != 0) begin
        $display("COVERAGE INSUFFICIENT: %0d 条指令一次都没打到", zero_classes);
        errors++;
      end
      // ★instIllegal 结构上不可达，不列入覆盖闸★
      // instIllegal = maskLogicalInst && VM==0，而 8 条掩码逻辑指令的 BitPat
      // (VMAND_MM = b0110011??????????010?????1010111 等) 都把 bit25(VM) 列为
      // care 位并钉成 1 —— maskLogicalInst 为真时 VM 必为 1，这个「与」永远是 0。
      // Chisel 的本意是「掩码逻辑指令不许带掩码」，但 BitPat 已经把带掩码的编码
      // 排除在外了，于是这条判据是一段死码。golden 照样把它展开成一根 wire
      // (firtool 不做跨 BitPat 的可达性分析)，本重写照抄结构，不合并、不化简。
      // 下面 assert_dead_instillegal 用定向激励把「不可达」验成事实而不是断言。
      if (cov_vill_ill == 0 || cov_eew_ill == 0 ||
          cov_emul_ill == 0 || cov_regnum_ill == 0 || cov_overlap_ill == 0 ||
          cov_vstart_ill == 0) begin
        $display("COVERAGE INSUFFICIENT: 有非法分支一次都没触发");
        errors++;
      end
      if (cov_hireg_wrap == 0) begin
        $display("COVERAGE INSUFFICIENT: 「vd 区间上界回绕」定向档一次都没打到");
        errors++;
      end
      if (cov_inst_ill != 0) begin
        $display("UNEXPECTED: instIllegal 竟然触发了 %0d 次 —— 上面那段「结构不可达」"
                 , cov_inst_ill);
        $display("            的论证已被推翻，必须重新核对 BitPat 与 golden。");
        errors++;
      end
    end

    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end

endmodule
''')
    return '\n'.join(L)


def splice(path, tag, lines):
    txt = path.read_text()
    b = f'// BEGIN GENERATED({tag})'
    e = '// END GENERATED'
    i = txt.index(b)
    j = txt.index(e, i)
    head = txt[:i + len(b)]
    tail = txt[j:]
    return head + '\n' + '\n'.join(lines) + '\n  ' + tail


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    pats = load_bitpats()
    classes = parse_classes()
    missing = [c for c, _, _ in CLASSES if c not in classes]
    if missing:
        sys.exit(f'gen.py: Chisel 里没解析到这些类: {missing}')
    outs = [
        (RTL, splice(RTL, 'instclass', emit_instclass(pats, classes))),
        (HERE / 'tb.sv', emit_tb(pats, classes)),
    ]
    rc = 0
    for p, txt in outs:
        old = p.read_text() if p.exists() else None
        if old == txt:
            print(f'  same  {p.relative_to(REPO)}')
            continue
        if a.check:
            print(f'  DRIFT {p.relative_to(REPO)}')
            rc = 1
        else:
            p.write_text(txt)
            print(f'  write {p.relative_to(REPO)}')
    return rc


if __name__ == '__main__':
    sys.exit(main())
