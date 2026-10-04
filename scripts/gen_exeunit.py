#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_exeunit.py —— ExeUnit 家族（ExeUnit / _1 / _4 / _5 / _7 / _8 / _9 / _10）wrapper 与 FM 钉点生成器。

## 生成什么

对每个变体，从 G1 golden `ExeUnit_<k>.sv` 机械解析，生成：

  1. `rtl/backend/ExeUnit_<k>.sv` —— golden 同名 wrapper：端口表逐字照抄；Dispatcher / 各 FU /
     ClockGate 的例化（实例名、端口连线与 golden 一一对应）；外壳控制逻辑全部交给手写的
     `xs_ExeUnit_core`（参数由本脚本从 golden 解析）；写回选择交给 `xs_ExeUnit_wbsel`
     （按「产出该字段的 FU 集合」分组例化）。wrapper 里**没有手写逻辑**，只有连线与打包。
  2. `verif/ut/ExeUnit_<k>/fm_pins_pre.tcl` —— FM「匹配前」钉点：
     (a) 外壳寄存器：golden 扁平名（inPipe_1_2_pdest / fuVldVec_1_1 / busy …）↔ 核里的
         数组 / generate 名，一一对应、逐位；
     (b) 子 FU 自己签核时用过的钉点（FMA / FCVT / Bku / FAlu）：用 tclsh 桩真跑那份钉点
         文件，取出它实际发出的 set_user_match 序列，加上实例路径前缀照搬。条数必须等于
         docs/pin_call_seq.tsv 里该文件登记的调用数，否则拒绝生成。
  3. `verif/ut/ExeUnit_<k>/fm_pins.tcl`（只有含「动态钉点」子 FU 的变体才有，当前 = ExeUnit_7 的 CSR）——
     FM「匹配后」钉点：子 FU 签核用的动态钉点文件（按 report_unmatched_points 现场配对）机械改前缀：
     `/WORK/<FU 类型>/` -> `/WORK/<变体>/<实例>/`、守卫 `$top eq "<FU 类型>"` -> `$top eq "<变体>"`，
     替换次数逐项核对（fail-closed），其余逐字照搬。

## ExeUnit_7（CSR 外壳）比别的变体多的三样外壳结构（2026-10-04，exublock0 lane 加）

  * 常开时钟门控：csr / Fence 是不定延迟 FU 但 Scala 配置 ckAlwaysEn，ClockGate.E 恒 1'h1 ——
    golden 里它们的 uncer_en_reg 被 firtool 删光（clk_en 被覆盖成常 1，没有读者）。核里按「延迟 0、
    无不定延迟」给参数（不生成任何门控寄存器），wrapper 直接把 E 接 1'b1；
  * CSR 输入打拍：Scala `fuio.exception := DelayN(exuio.exception, 2)`、robDeqPtr 同理，golden 是两个
    DelayN_<n> 实例（已签核件），本脚本把它们当「辅助实例」原样例化（输入只许是顶层端口，输出只许喂 FU）；
  * 致命错误上报：HasCriticalErrors 的 `io_error(i) := RegNext(RegNext(fu.error))`，两级寄存器交给共享件
    rtl/common/xs_CriticalErrorDelay_core.sv（核 xs_ExeUnit_core 不改）。

## fail-closed（解析不认识的形状一律退出，不猜）

  * golden 每个 reg 都必须归入已知的五类之一（inPipe 字段 / inPipe valid / FU 门控链 /
    busy 快照 / instrAddrTransType 打拍），且与按参数推出的寄存器集合**逐个相等**；
  * inPipe 每个字段的保留深度必须等于「最晚读它的 FU 级」（robIdx 另加冲刷所需），
    即 golden 被 firtool 删剩的那组寄存器必须正好是这条规则的结果；
  * 每条实例连线的表达式必须是：顶层端口 / 另一实例的输出线 / 已知胶合信号之一；
  * 每个输出口必须是：实例端口直连 / 单元素直通（可零扩展）/ 若干 FU 的 Mux1H（valid 与
    数据成员一一对应）/ io_out_valid（全体 FU valid 的或）/ io_in_ready（busy 形状）。

## 用法

  python3 scripts/gen_exeunit.py            # 写全部
  python3 scripts/gen_exeunit.py --check    # 只比对不写；有漂移 rc=1（gate 自动扫描）
"""
import argparse
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
VARIANTS = ['ExeUnit', 'ExeUnit_1', 'ExeUnit_4', 'ExeUnit_5', 'ExeUnit_7', 'ExeUnit_8', 'ExeUnit_9', 'ExeUnit_10']

# 子 FU 自己签核用过的「匹配前/后」钉点文件（相对 verif/ut/）；本脚本用 tclsh 桩取其调用序列
CHILD_PIN_FILES = {
    'FMA':  'FMA/fm_pins_pre.tcl',
    'FCVT': 'FCVT/fm_pins_pre.tcl',
    'Bku':  'Bku/fm_pins_pre.tcl',
    'FAlu': 'FAlu/fm_pins.tcl',
}

# 子 FU 自己签核用过的**动态**钉点文件（匹配后跑，按 report_unmatched_points 现场配对；相对 verif/ut/）。
# 进外壳后路径多一层实例名：机械改前缀后整份照搬成 verif/ut/<变体>/fm_pins.tcl（见 gen_dyn_pins）。
DYN_CHILD_PIN_FILES = {
    'CSR': 'CSR/fm_pins.tcl',
}

ATT_BITS = ['bare', 'sv39', 'sv39x4', 'sv48', 'sv48x4']

def _bits(ref, impl, bits):
    return [(f'{ref}[{b}]', f'{impl}[{b}]') for b in bits]


# 子 FU 在外壳里**额外**需要的钉点（子 FU 自己签核时不需要：那时这些寄存器靠扇出签名就能配上，
# 进了外壳后写回经 Mux1H 合流，签名变对称 / 变成无扇出死位，FM 就分不清了）。
# 每一组都是**按语义整组写定**的双射，不是照诊断跑的 unmatched 名单抄的：
EXTRA_CHILD_PINS = {
    # FAlu（fudian 浮点加法器，impl 读重写件）：三组「同一个值存两份」的寄存器 ——
    #   F32 加法器 fadd0_result1_r / _r_1（a 为零时的 ±b，f32 / f16 两种拼法）低 15 位两份逐位同值
    #     （[14:0] 在两种拼法里都是 b 的同一段；FAlu 自己的钉点已钉了其中 6/7/9/11/12）；
    #   F32 加法器 fadd0_result0_r / fadd0_result0_r_1[16]（两零相加的符号，f32 / f16 各一份）；
    #   F64 close path 的 close_exponent_result_r / EA_sub_value_r_1（都是 EA 的副本：被减数 / 备用减数）。
    'FAlu': (
        _bits('falu/F32Adder/fadd0_result1_r_reg', 'u_core/falu/F32Adder/u_core/b_signed_f32_q_reg',
              [0, 1, 2, 3, 4, 5, 8, 10, 13, 14])
        + _bits('falu/F32Adder/fadd0_result1_r_1_reg', 'u_core/falu/F32Adder/u_core/b_signed_f16_q_reg',
                [0, 1, 2, 3, 4, 5, 8, 10, 13, 14])
        + [('falu/F32Adder/fadd0_result0_r_reg', 'u_core/falu/F32Adder/u_core/zero_sign_f32_q_reg')]
        + _bits('falu/F32Adder/fadd0_result0_r_1_reg', 'u_core/falu/F32Adder/u_core/zero_sign_f16_q_reg', [16])
        + _bits('falu/F64Adder/U_close_path/close_exponent_result_r_reg',
                'u_core/falu/F64Adder/U_close_path/u_core/exp_big_q_reg', range(11))
        + _bits('falu/F64Adder/U_close_path/EA_sub_value_r_1_reg',
                'u_core/falu/F64Adder/U_close_path/u_core/exp_big_alt_q_reg', range(11))
    ),
    # MulUnit：外壳里 ArrayMulDataModule 改读重写件（MulUnit 自己签核时两侧同读 golden）。
    #   golden 把部分积 / 中间级寄存器展平成 r_0..r_2306（= 重写件 pp_reg[0..2306]）与
    #   r_2307..r_2561（= mid_reg[0..254]）。其中 r_2303..r_2306 / r_2558..r_2561 两侧都无读者（死位，
    #   无扇出签名）FM 配不上，按这条下标规则钉；其余位靠签名能配上。
    # DivUnit：golden 孩子 SRT16DividerDataModule 的 6 个自带死位（aLZCReg/dLZCReg[6] 恒 0 且读者只取 [5:0]；
    #   udNegReg_{0,1,3,4}[67] 无读者），两侧同死、层次名不同（divDataModule vs u_core/u_div/u_core），
    #   无扇出签名配不上。DivUnit 自己签核时由 verif/ut/ArithVecLeaves5/fm_pins.tcl 匹配后按叶名逐对钉
    #   （那份文件按「全设计 unread 恰 6 个」自检，进了外壳不再成立，不能照搬），这里按同一组字面名静态钉，
    #   再交 vmucp 实比（白名单 verif/fm_target_config/ExeUnit_7.tcl）。名字取自 evidence/c2fc93f125d3/DivUnit/fm.log。
    'DivUnit': (
        [(f'divDataModule/{r}', f'u_core/u_div/u_core/{r}')
         for r in ('aLZCReg_reg[6]', 'dLZCReg_reg[6]', 'udNegReg_0_reg[67]', 'udNegReg_1_reg[67]',
                   'udNegReg_3_reg[67]', 'udNegReg_4_reg[67]')]
    ),
    # Fence（ExeUnit_7）：锁存的 uop 操作码 9 位。golden 是标量 uop_ctrl_fuOpType，重写件聚合成 struct uop
    #   （fence_uop_t；FM 按字段名给 struct 寄存器起名：uop_reg[fuOpType][b]，fm_shell find_cells 实查）。Fence 单独签核时靠签名配上；进了 ExeUnit_7，同一个发射口 fuOpType 还被
    #   CSR 的 trapInstMod faultCsrUop fuOpType 锁存（ref 侧 [8:3] 是 golden 死位，verif/dead_ref/CSR.json），两组签名
    #   撞在一起，诊断跑里 ref 的 [8:3] 6 位配不上 —— 按字段整组钉 9 位。
    'Fence': (
        [(f'uop_ctrl_fuOpType_reg[{b}]', f'u_core/uop_reg[fuOpType][{b}]') for b in range(9)]
    ),
    # CSR（ExeUnit_7）：几族「golden 展平标量 / 重写件数组」寄存器。CSR 单独签核时它们全靠签名分析配上（CSR 自己的
    #   钉点只管匹配后剩下的四族，verif/ut/CSR/fm_pins.tcl）；进了 ExeUnit_7（输入多过一层 Dispatcher / DelayN），
    #   诊断跑里签名分析没能配上这几族（ref 侧 4921 个孤儿全落在下面各族里）。按结构整族钉（全部条目全部位，不是照
    #   孤儿名单抄）：
    #   * imsic 9 个 IntFile 的 eies_1..3 / eithreshold（各 64 位）：golden intFile{,_k}/eies_<w> ↔ 重写
    #     u_core/g_file[k].intFile/u_core/eies_reg[w]、eithreshold_reg（eies_0 / eidelivery 高位留给匹配后的 CSR 钉点）；
    #   * imsic 读数据打拍：golden intfile_rdata_d{,_k}_bits / _valid ↔ 重写 u_core/rdata_d_bits_reg[k] / rdata_d_valid_reg[k]；
    #   * csrMod 的 PMP / PMA 32 个地址寄存器（各 46 位）：golden pmpAddr_<k>_ADDRESS / pmaAddr_<k> ↔ 重写
    #     u_core/g_entry[k].addr_q_reg；
    #   * isPerfCnt 两拍保持：golden io_csrio_isPerfCnt_r ↔ 重写 not_jmp_q（CSR.sv：本条不是系统指令）、golden
    #     csrMod/io_out_bits_isPerfCnt_r ↔ 重写 csrMod/is_perf_cnt_q；
    #   * 两个 1 位中断使能 / 挂起位：golden csrMod/mvip/reg_SSIP ↔ 重写 mvip/u_core/ssip_q、golden csrMod/sie/reg_SSIE ↔
    #     重写 sie/u_core/g_bit[1].g_flop.q（SSIE 是 sie 的第 1 位）—— 第二次诊断跑匹配后仅剩的 2 个族外孤儿。
    'CSR': (
        [(f'imsic/imsic/intFile{"_%d" % k if k else ""}/eies_{w}_reg[{b}]',
          f'imsic/imsic/u_core/g_file[{k}].intFile/u_core/eies_reg[{w}][{b}]')
         for k in range(9) for w in (1, 2, 3) for b in range(64)]
        + [(f'imsic/imsic/intFile{"_%d" % k if k else ""}/eithreshold_reg[{b}]',
            f'imsic/imsic/u_core/g_file[{k}].intFile/u_core/eithreshold_reg[{b}]')
           for k in range(9) for b in range(64)]
        + [(f'imsic/imsic/intfile_rdata_d{"_%d" % k if k else ""}_bits_reg[{b}]',
            f'imsic/imsic/u_core/rdata_d_bits_reg[{k}][{b}]')
           for k in range(9) for b in range(64)]
        + [(f'imsic/imsic/intfile_rdata_d{"_%d" % k if k else ""}_valid_reg',
            f'imsic/imsic/u_core/rdata_d_valid_reg[{k}]') for k in range(9)]
        + [(f'csrMod/pmpEntryMod/pmpAddr_{k}_ADDRESS_reg[{b}]',
            f'csrMod/pmpEntryMod/u_core/g_entry[{k}].addr_q_reg[{b}]') for k in range(32) for b in range(46)]
        + [(f'csrMod/pmaEntryMod/pmaAddr_{k}_reg[{b}]',
            f'csrMod/pmaEntryMod/u_core/g_entry[{k}].addr_q_reg[{b}]') for k in range(32) for b in range(46)]
        + [('io_csrio_isPerfCnt_r_reg', 'not_jmp_q_reg'),
           ('csrMod/io_out_bits_isPerfCnt_r_reg', 'csrMod/is_perf_cnt_q_reg'),
           ('csrMod/mvip/reg_SSIP_reg', 'csrMod/mvip/u_core/ssip_q_reg'),
           ('csrMod/sie/reg_SSIE_reg', 'csrMod/sie/u_core/g_bit[1].g_flop.q_reg')]
    ),
    'MulUnit': (
        [(f'mulDataModule/r_{k}_reg', f'u_core/mulDataModule/u_core/pp_reg_reg[{k}]') for k in (2303, 2304, 2305, 2306)]
        + [(f'mulDataModule/r_{2307 + j}_reg', f'u_core/mulDataModule/u_core/mid_reg_reg[{j}]')
           for j in (251, 252, 253, 254)]
    ),
}



def die(msg):
    sys.exit('gen_exeunit: ERROR: ' + msg)


# =============================================================================
#  golden 解析
# =============================================================================
class Golden(object):
    def __init__(self, top):
        self.top = top
        text = (GOLDEN / f'{top}.sv').read_text()
        m = re.search(r'^module ' + re.escape(top) + r'\((.*?)\n\);\n(.*?)^endmodule', text, re.S | re.M)
        if not m:
            die(f'{top}: 找不到 module 体')
        self.port_text = m.group(1)
        body = m.group(2)
        # 去掉仿真专用块（断言、寄存器随机初始化）
        body = re.sub(r'^[ \t]*`ifndef SYNTHESIS.*?`endif // not def SYNTHESIS\n', '', body, flags=re.S | re.M)
        body = re.sub(r'^[ \t]*`ifdef ENABLE_INITIAL_REG_.*?`endif // ENABLE_INITIAL_REG_\n', '', body,
                      flags=re.S | re.M)
        if '`' in body:
            die(f'{top}: 去掉仿真块后仍有宏: ' + body[body.index('`'):][:80])
        # 端口
        self.ports = []
        for ln in self.port_text.splitlines():
            if not ln.strip():
                continue
            pm = re.match(r'^\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$', ln)
            if not pm:
                die(f'{top}: 端口行无法解析 {ln!r}')
            self.ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
        self.port_w = {n: w for _, w, n in self.ports}
        self.port_dir = {n: d for d, _, n in self.ports}
        # 实例
        self.insts = []
        def take_inst(mm):
            typ, name, conns = mm.group(1), mm.group(2), mm.group(3)
            self.insts.append((typ, name, self.parse_conns(conns, name)))
            return ''
        body = re.sub(r'^  ([A-Z]\w*) (\w+) \(\n(.*?)^  \);\n', take_inst, body, flags=re.S | re.M)
        # always 块
        self.always = []
        def take_always(mm):
            self.always.append(mm.group(0))
            return ''
        body = re.sub(r'^  always @\(posedge clock(?: or posedge reset)?\) begin\n.*?^  end // always @\(posedge[^\n]*\n',
                      take_always, body, flags=re.S | re.M)
        # 其余语句
        self.wire_w = {}
        self.wire_expr = {}
        self.reg_w = {}
        self.assign = {}
        for st in body.split(';'):
            st = ' '.join(st.split())
            if not st:
                continue
            mm = re.match(r'^wire (?:\[(\d+):0\] )?(\w+)(?: = (.*))?$', st)
            if mm:
                self.wire_w[mm.group(2)] = int(mm.group(1)) + 1 if mm.group(1) else 1
                if mm.group(3) is not None:
                    self.wire_expr[mm.group(2)] = mm.group(3)
                continue
            mm = re.match(r'^reg (?:\[(\d+):0\] )?(\w+)$', st)
            if mm:
                self.reg_w[mm.group(2)] = int(mm.group(1)) + 1 if mm.group(1) else 1
                continue
            mm = re.match(r'^assign (\w+) = (.*)$', st)
            if mm:
                if mm.group(1) in self.port_dir:
                    self.assign[mm.group(1)] = mm.group(2)
                else:
                    self.wire_expr[mm.group(1)] = mm.group(2)
                continue
            die(f'{top}: 不认识的语句: {st[:120]}')

    @staticmethod
    def parse_conns(text, iname):
        conns = []
        i = 0
        t = text
        while True:
            m = re.compile(r'\.(\w+)\s*\(').search(t, i)
            if not m:
                break
            depth, j = 1, m.end()
            while depth:
                if t[j] == '(':
                    depth += 1
                elif t[j] == ')':
                    depth -= 1
                j += 1
            expr = ' '.join(t[m.end():j - 1].split())
            conns.append((m.group(1), expr))
            i = j
        return conns


LIT = re.compile(r"\d+'[hbdo][0-9a-fA-FxzXZ_]+")
IDENT = re.compile(r'\b[A-Za-z_]\w*\b')


def idents(expr):
    return IDENT.findall(LIT.sub(' ', expr.replace('/* unused */', '')))


# =============================================================================
#  语义抽取
# =============================================================================
class Variant(object):
    def __init__(self, top):
        g = self.g = Golden(top)
        self.top = top
        disp = [x for x in g.insts if x[0].startswith('Dispatcher')]
        cgs = [x for x in g.insts if x[0] == 'ClockGate']
        # 辅助实例：Scala 在 ExeUnit 里给 FU 输入做的 DelayN 打拍（ExeUnit_7 的 CSR exception / robDeqPtr）
        aux = [x for x in g.insts if re.fullmatch(r'DelayN_\d+', x[0])]
        fus = [x for x in g.insts if x[0] != 'ClockGate' and not x[0].startswith('Dispatcher') and x not in aux]
        if len(disp) != 1 or disp[0][1] != 'in1ToN':
            die(f'{top}: Dispatcher 实例不唯一或名字不是 in1ToN')
        self.disp = disp[0]
        # FU 按 Dispatcher 出口序号排序
        order = {}
        for typ, name, conns in fus:
            cv = dict(conns).get('io_in_valid', '')
            mm = re.fullmatch(r'_in1ToN_io_out_(\d+)_valid', cv)
            if not mm:
                die(f'{top}.{name}: io_in_valid 不是 Dispatcher 出口: {cv}')
            order[int(mm.group(1))] = (typ, name, conns)
        if sorted(order) != list(range(len(order))):
            die(f'{top}: Dispatcher 出口序号不连续 {sorted(order)}')
        self.fus = [order[k] for k in range(len(order))]
        self.fu_names = [n for _, n, _ in self.fus]
        self.fu_idx = {n: k for k, n in enumerate(self.fu_names)}
        self.cgs = cgs
        self.aux = aux
        self.analyze_aux()
        self.analyze_clock_gates()
        self.analyze_inpipe()
        self.analyze_busy()
        self.analyze_att()
        self.analyze_err()
        self.check_regs()
        self.analyze_outputs()

    # ---- 辅助实例（DelayN）-----------------------------------------------------
    def analyze_aux(self):
        g, top = self.g, self.top
        fu_names = {n for _, n, _ in self.fus}
        for typ, name, conns in self.aux:
            for p, e in conns:
                if p == 'clock':
                    if e != 'clock':
                        die(f'{top}.{name}: clock 不接 clock')
                elif p.startswith('io_in_'):
                    if g.port_dir.get(e) != 'input':
                        die(f'{top}.{name}.{p}: 输入不是顶层输入端口 {e}')
                elif p.startswith('io_out_'):
                    if e != f'_{name}_{p}' or e not in g.wire_w:
                        die(f'{top}.{name}.{p}: 输出线名不认识 {e}')
                    # 读者只许是 FU 的输入
                    readers = [(n, q) for _, n, cs in self.fus + [self.disp] + self.cgs + self.aux
                               for q, x in cs if e in idents(x) and (n, q) != (name, p)]
                    if not readers or any(n not in fu_names for n, _ in readers):
                        die(f'{top}.{name}.{p}: 输出 {e} 的读者不全是 FU {readers}')
                    if any(e in idents(x) for x in list(g.assign.values()) + list(g.wire_expr.values())):
                        die(f'{top}.{name}.{p}: 输出 {e} 被胶合逻辑读')
                else:
                    die(f'{top}.{name}: 不认识的端口 {p}')

    # ---- 时钟门控 -------------------------------------------------------------
    def analyze_clock_gates(self):
        g, top = self.g, self.top
        self.fu_lat = [0] * len(self.fus)
        self.fu_unc = [0] * len(self.fus)
        self.fu_cg = [None] * len(self.fus)          # ClockGate 实例名
        self.fu_cg_on = [0] * len(self.fus)           # 常开门控（Scala ckAlwaysEn：E 恒 1）
        self.cg_te = {}                               # ClockGate 实例名 -> cg_bore 端口
        self.reg_pin = {}                             # golden reg -> (impl 路径模板, 位映射)
        for typ, cname, conns in self.cgs:
            c = dict(conns)
            if c.get('CK') != 'clock':
                die(f'{top}.{cname}: CK 不是 clock')
            te = c.get('TE', '')
            mm = re.fullmatch(r'(\w+)_clock_te_cgen', te)
            if not mm or mm.group(1) not in self.fu_idx:
                die(f'{top}.{cname}: TE 形状不认识 {te}')
            fu = mm.group(1)
            bore = g.wire_expr.get(te, '')
            if not re.fullmatch(r'cg_bore(_\d+)?_cgen', bore) or g.port_dir.get(bore) != 'input':
                die(f'{top}.{cname}: TE 源不是 cg_bore 端口 {bore}')
            self.cg_te[cname] = bore
            k = self.fu_idx[fu]
            fconn = dict(self.fus[k][2])
            if fconn.get('clock') != f'_{cname}_Q':
                die(f'{top}.{fu}: clock 不接 {cname}.Q')
            if c.get('Q') != f'_{cname}_Q':
                die(f'{top}.{cname}: Q 线名不认识')
            self.fu_cg[k] = cname
            en = c.get('E', '')
            ex = g.wire_expr.get(en, '')
            m1 = re.fullmatch(r'(fuVld_en(?:_\d+)?) \| (fuVld_en_reg(?:_\d+)?)', ex)
            m2 = re.fullmatch(r'(_GEN(?:_\d+)?) \| (uncer_en_reg(?:_\d+)?)', ex)
            if en == "1'h1":
                # ckAlwaysEn：门控恒开，FU 当作延迟 0 处理（不读后级 ctrlPipe，下面另核）、核里不生成门控寄存器
                self.fu_cg_on[k] = 1
            elif m1:
                chain = g.wire_expr.get(m1.group(1), '').split(' | ')
                if chain[0] != f'_in1ToN_io_out_{k}_valid':
                    die(f'{top}.{fu}: fuVld_en 第 0 项不是本 FU 的 in.valid: {chain}')
                regs = chain[1:]
                if not regs or any(r not in g.reg_w for r in regs):
                    die(f'{top}.{fu}: fuVld_en 链寄存器不认识 {regs}')
                self.fu_lat[k] = len(regs)
                for s, r in enumerate(regs, 1):
                    self.reg_pin[r] = (f'u_core/g_fu\\[{k}\\].g_lat.vld_q_reg\\[{s}\\]', None)
                self.reg_pin[m1.group(2)] = (f'u_core/g_fu\\[{k}\\].g_lat.en_q_reg', None)
                # 链的前移形状：第 s 级寄存器在 always 里取第 s-1 级
                al = '\n'.join(g.always)
                for s in range(2, len(regs) + 1):
                    if f'{regs[s-1]} <= {regs[s-2]};' not in al:
                        die(f'{top}.{fu}: 门控链第 {s} 级前移形状不对')
            elif m2:
                fire = g.wire_expr.get(m2.group(1), '')
                if fire != f'_{fu}_io_in_ready & _in1ToN_io_out_{k}_valid':
                    die(f'{top}.{fu}: 不定延迟门控的 fire 形状不认识 {fire}')
                self.fu_unc[k] = 1
                self.reg_pin[m2.group(2)] = (f'u_core/g_fu\\[{k}\\].g_unc.uncer_q_reg', None)
            else:
                die(f'{top}.{cname}: E 形状不认识 {en} = {ex}')
        # 无门控的 FU 必须延迟 0：不接任何第 s>0 级的 ctrlPipe / validPipe
        for k, (typ, name, conns) in enumerate(self.fus):
            stages = [int(m.group(1)) for p, _ in conns
                      for m in [re.match(r'io_in_bits_(?:ctrlPipe|validPipe)_(\d+)', p)] if m]
            mx = max(stages) if stages else 0
            if self.fu_cg[k] is None:
                if mx != 0:
                    die(f'{top}.{name}: 无门控却读第 {mx} 级')
                if dict(conns).get('clock', 'clock') != 'clock':
                    die(f'{top}.{name}: 无门控却不接 clock')
            elif not self.fu_unc[k] and mx != self.fu_lat[k]:
                die(f'{top}.{name}: 门控链长 {self.fu_lat[k]} 与读到的最深级 {mx} 不符')

    # ---- inPipe ---------------------------------------------------------------
    def analyze_inpipe(self):
        g, top = self.g, self.top
        vregs = {}
        fregs = {}
        for r, w in g.reg_w.items():
            m = re.fullmatch(r'inPipe_2_(\d+)', r)
            if m:
                vregs[int(m.group(1))] = r
                continue
            m = re.fullmatch(r'inPipe_1_(\d+)_(\w+)', r)
            if m:
                fregs.setdefault(m.group(2), {})[int(m.group(1))] = (r, w)
        self.lat_max = max(vregs) if vregs else 0
        if sorted(vregs) != list(range(1, self.lat_max + 1)):
            die(f'{top}: inPipe valid 级不连续 {sorted(vregs)}')
        if self.lat_max != max(self.fu_lat + [0]):
            die(f'{top}: inPipe 级数 {self.lat_max} != 最大 FU 延迟 {max(self.fu_lat)}')
        al = '\n'.join(g.always)
        for s, r in vregs.items():
            self.reg_pin[r] = (f'u_core/g_pipe.stage_valid_q_reg\\[{s}\\]', None)
            prev_v = 'io_in_valid' if s == 1 else vregs[s - 1]
            prev_rob = 'io_in_bits_robIdx' if s == 1 else f'inPipe_1_{s-1}_robIdx'
            pat = re.compile(re.escape(r) + r' <=\s*' + re.escape(prev_v) + r'\s*& ~\(' + re.escape(prev_v)
                             + r' & io_flush_valid.*?' + re.escape(prev_rob + '_flag'), re.S)
            if not pat.search(al):
                die(f'{top}: inPipe valid 第 {s} 级冲刷形状不认识')
        # robIdx {flag,value} 合成一个字段；其余字段按出现顺序
        names = []
        for f in fregs:
            base = 'robIdx' if f in ('robIdx_flag', 'robIdx_value') else f
            if base not in names:
                names.append(base)
        if self.lat_max and 'robIdx' not in names:
            die(f'{top}: inPipe 没有 robIdx 字段')
        names = ['robIdx'] + [n for n in names if n != 'robIdx']
        self.fields = []       # (name, width, depth, [golden 子字段 (后缀, 位宽, 低位)])
        lo = 0
        for n in names:
            if n == 'robIdx':
                subs = [('robIdx_value', 8, 0), ('robIdx_flag', 1, 8)]
                w = 9
            else:
                ws = {w for (_, w) in fregs[n].values()}
                if len(ws) != 1:
                    die(f'{top}: 字段 {n} 各级位宽不一')
                w = ws.pop()
                subs = [(n, w, 0)]
            depth = 0
            for sub, sw, _ in subs:
                st = sorted(fregs.get(sub, {}))
                if st != list(range(1, len(st) + 1)):
                    die(f'{top}: 字段 {sub} 的级不连续 {st}')
                if depth and len(st) != depth:
                    die(f'{top}: robIdx flag/value 深度不一')
                depth = len(st)
            # 来源端口：第 1 级取 io_in_bits_<sub>，第 s 级取第 s-1 级
            for sub, sw, slo in subs:
                if f'io_in_bits_{sub}' not in g.port_w:
                    die(f'{top}: 字段 {sub} 没有输入端口')
                for s in range(1, depth + 1):
                    src = f'io_in_bits_{sub}' if s == 1 else f'inPipe_1_{s-1}_{sub}'
                    if f'inPipe_1_{s}_{sub} <= {src};' not in al:
                        die(f'{top}: inPipe_1_{s}_{sub} 的赋值形状不对')
                    r = f'inPipe_1_{s}_{sub}'
                    fi = len(self.fields)
                    self.reg_pin[r] = (f'u_core/g_pipe.g_fld\\[{fi}\\].g_reg.q_reg\\[{s}\\]', slo)
            self.fields.append((n, w, depth, subs, lo))
            lo += w
        self.pay_w = lo
        # 保留规则核对：深度 = max(最晚读它的 FU 级, robIdx 时 LAT_MAX-1)
        reads = {}
        for typ, name, conns in self.fus:
            for p, e in conns:
                m = re.fullmatch(r'io_in_bits_ctrlPipe_(\d+)_(\w+)', p)
                if not m:
                    continue
                s, sub = int(m.group(1)), m.group(2)
                if s == 0:
                    if e != f'io_in_bits_{sub}':
                        die(f'{top}.{name}: ctrlPipe_0_{sub} 不接顶层端口: {e}')
                    continue
                if e != f'inPipe_1_{s}_{sub}':
                    die(f'{top}.{name}: ctrlPipe_{s}_{sub} 不接 inPipe: {e}')
                base = 'robIdx' if sub.startswith('robIdx_') else sub
                reads[base] = max(reads.get(base, 0), s)
        for n, w, depth, subs, lo in self.fields:
            want = reads.get(n, 0)
            if n == 'robIdx':
                want = max(want, self.lat_max - 1)
            if want != depth:
                die(f'{top}: 字段 {n} golden 深度 {depth} != 保留规则 {want}')

    # ---- busy -----------------------------------------------------------------
    def analyze_busy(self):
        g, top = self.g, self.top
        self.has_busy = 'busy' in g.reg_w
        if not self.has_busy:
            return
        dv = dict(self.disp[2]).get('io_in_valid')
        if dv != 'io_in_valid & ~busy':
            die(f'{top}: busy 外壳的 Dispatcher in.valid 形状不认识 {dv}')
        if g.assign.get('io_in_ready') != 'io_in_ready_0' or \
                g.wire_expr.get('io_in_ready_0') != '~busy & _in1ToN_io_in_ready':
            die(f'{top}: busy 外壳的 io_in_ready 形状不认识')
        if g.reg_w.get('robIdx_flag') != 1 or g.reg_w.get('robIdx_value') != 8:
            die(f'{top}: busy 外壳没有 robIdx 快照')
        self.reg_pin['busy'] = ('u_core/g_busy.busy_q_reg', None)
        self.reg_pin['robIdx_flag'] = ('u_core/g_busy.rob_q_reg', 8)
        self.reg_pin['robIdx_value'] = ('u_core/g_busy.rob_q_reg', 0)

    # ---- instrAddrTransType ---------------------------------------------------
    def analyze_att(self):
        g, top = self.g, self.top
        self.att_fus = []
        al = '\n'.join(g.always)
        for k, name in enumerate(self.fu_names):
            regs = [f'{name}_io_instrAddrTransType_REG_{b}' for b in ATT_BITS]
            have = [r in g.reg_w for r in regs]
            if any(have) and not all(have):
                die(f'{top}.{name}: instrAddrTransType 打拍寄存器不全')
            if all(have):
                a = len(self.att_fus)
                self.att_fus.append(name)
                for bi, (b, r) in enumerate(zip(ATT_BITS, regs)):
                    if f'{r} <= io_instrAddrTransType_{b};' not in al:
                        die(f'{top}: {r} 赋值形状不对')
                    if dict(self.fus[k][2]).get(f'io_instrAddrTransType_{b}') != r:
                        die(f'{top}.{name}: io_instrAddrTransType_{b} 不接打拍寄存器')
                    self.reg_pin[r] = (f'u_core/att_q_reg\\[{a}\\]', bi)

    # ---- 致命错误上报（HasCriticalErrors：RegNext(RegNext(fu.io_error))）-------------------
    def analyze_err(self):
        g, top = self.g, self.top
        al = '\n'.join(g.always)
        self.err = []                 # [(k, 来源 FU, FU 的 io_error 下标)]
        for r in g.reg_w:
            m = re.fullmatch(r'io_error_(\d+)_REG', r)
            if not m:
                continue
            k = int(m.group(1))
            r2 = f'io_error_{k}_REG_1'
            if g.reg_w[r] != 1 or g.reg_w.get(r2) != 1:
                die(f'{top}: {r} / {r2} 不是一对 1 位寄存器')
            mm = re.search(re.escape(r) + r' <= _(\w+?)_io_error_(\d+);', al)
            if not mm or mm.group(1) not in self.fu_idx:
                die(f'{top}: {r} 的来源不是某个 FU 的 io_error')
            if f'{r2} <= {r};' not in al:
                die(f'{top}: {r2} 不是 {r} 的下一拍')
            if g.assign.get(f'io_error_{k}') != r2:
                die(f'{top}: io_error_{k} 不是直接取 {r2}')
            self.err.append((k, mm.group(1), int(mm.group(2))))
        self.err.sort()
        if [k for k, _, _ in self.err] != list(range(len(self.err))):
            die(f'{top}: io_error 下标不连续 {self.err}')
        for k, _, _ in self.err:
            self.reg_pin[f'io_error_{k}_REG'] = ('u_err/stage1_q_reg', k)
            self.reg_pin[f'io_error_{k}_REG_1'] = ('u_err/stage2_q_reg', k)

    def check_regs(self):
        extra = set(self.g.reg_w) - set(self.reg_pin)
        if extra:
            die(f'{self.top}: 有不认识的 golden 寄存器 {sorted(extra)}')

    # ---- 输出口 -----------------------------------------------------------------
    def inline(self, expr, depth=0):
        if depth > 20:
            die(f'{self.top}: 内联过深')
        g = self.g

        def rep(m):
            n = m.group(0)
            if n in g.wire_expr and not re.match(r'_(\w+?)_io_', n) and n not in g.port_w:
                return '(' + self.inline(g.wire_expr[n], depth + 1) + ')'
            return n
        return IDENT.sub(rep, LIT.sub(lambda m: m.group(0).replace("'", "\x00"), expr)).replace("\x00", "'")

    def analyze_outputs(self):
        g, top = self.g, self.top
        self.out_direct = {}     # 输出口 -> (实例, 端口)：实例端口直连
        for typ, name, conns in [self.disp] + self.fus + self.cgs:
            for p, e in conns:
                if e in g.port_dir and g.port_dir[e] == 'output':
                    self.out_direct[e] = (name, p)
        self.out_kind = {}       # 输出口 -> ('valid',) / ('ready',) / ('pass', src, ext) / ('mux', members, field)
        fu_set = set(self.fu_names)
        for d, w, n in g.ports:
            if d != 'output':
                continue
            m = re.fullmatch(r'io_error_(\d+)', n)
            if m and int(m.group(1)) < len(self.err):
                self.out_kind[n] = ('err', int(m.group(1)))
                continue
            if n in self.out_direct:
                inst, p = self.out_direct[n]
                if n == 'io_in_ready':
                    if inst != 'in1ToN' or self.has_busy:
                        die(f'{top}: io_in_ready 直连形状不对')
                    self.out_kind[n] = ('ready',)
                else:
                    # 单 FU 外壳：写回字段即单元素 Mux1H 直通；多 FU 外壳：只允许 FU 专属的旁路口
                    # （vtype / vlIsZero / vlIsVlmax …，Scala 里是 exuio := fuio 直接赋值）
                    # 例外：redirect 在 Scala 里是「先按有没有 redirect 过滤 FU、再 Mux1H」
                    #   （ExeUnit.scala `Mux1H((fuOutValidOH zip fuRedirectVec).filter(_._2.isDefined)...)`），
                    #   只有一个 FU（ExeUnit_7 的 csr）有 redirect 时是单元素 Mux1H —— 直连、不与 valid 相与
                    filtered = n.startswith('io_out_bits_redirect_') and \
                        p == 'io_out_bits_res_redirect_' + n[len('io_out_bits_redirect_'):]
                    # isPerfCnt 不走 Mux1H：Scala 是全体 FU 的 csrio.isPerfCnt 相或（没有 csrio 的给 false），
                    #   只有 csr 有 ⇒ 直连
                    filtered = filtered or (n == 'io_out_bits_debug_isPerfCnt' and p == 'io_csrio_isPerfCnt')
                    if inst not in fu_set or (len(self.fus) != 1 and n.startswith('io_out_bits_') and not filtered):
                        die(f'{top}: {n} 直连到 {inst}.{p}（写回字段只允许单 FU 外壳直通）')
                    self.out_kind[n] = ('direct', inst, p)
                continue
            if n not in g.assign:
                die(f'{top}: 输出 {n} 无驱动')
            ex = self.inline(g.assign[n])
            ids = idents(ex)
            if n == 'io_in_ready':
                if not self.has_busy:
                    die(f'{top}: 非 busy 外壳的 io_in_ready 由 assign 驱动')
                self.out_kind[n] = ('ready',)
                continue
            valids = []
            srcs = []
            for i in ids:
                m = re.fullmatch(r'_(\w+?)_io_out_valid', i)
                if m and m.group(1) in fu_set:
                    valids.append(m.group(1))
                    continue
                m = re.fullmatch(r'_(\w+?)_io_out_bits_(\w+)', i)
                if m and m.group(1) in fu_set:
                    srcs.append((m.group(1), m.group(2)))
                    continue
                die(f'{top}: 输出 {n} 引用了不认识的信号 {i}')
            if n == 'io_out_valid':
                if srcs or sorted(set(valids)) != sorted(fu_set):
                    die(f'{top}: io_out_valid 不是全体 FU valid 的或')
                self.out_kind[n] = ('valid',)
                continue
            if not srcs:
                die(f'{top}: 输出 {n} 不含任何 FU 数据')
            members = sorted({f for f, _ in srcs}, key=lambda f: self.fu_idx[f])
            for f in members:
                fs = {x for (ff, x) in srcs if ff == f}
                if len(fs) != 1:
                    die(f'{top}: 输出 {n} 从 {f} 取了多个字段 {fs}')
            fields = {f: x for f, x in srcs}
            if not valids:
                if len(members) != 1 or len(srcs) != 1:
                    die(f'{top}: 输出 {n} 无 valid 却有多个来源')
                f = members[0]
                sw = g.wire_w[f'_{f}_io_out_bits_{fields[f]}']
                ok = ex == f'_{f}_io_out_bits_{fields[f]}' or \
                    re.fullmatch(r"\{\d+'h0, _" + re.escape(f'{f}_io_out_bits_{fields[f]}') + r'\}', ex)
                if not ok:
                    die(f'{top}: 输出 {n} 的单元素直通形状不认识: {ex}')
                self.out_kind[n] = ('pass', f, fields[f])
                continue
            if sorted(set(valids), key=lambda f: self.fu_idx[f]) != members:
                die(f'{top}: 输出 {n} 的 valid 集合 {valids} 与数据成员 {members} 不一致')
            self.out_kind[n] = ('mux', tuple(members), fields)


# =============================================================================
#  生成 wrapper
# =============================================================================
def wname(e):
    """golden 实例输出线 `_X_io_...` -> wrapper 里的 `X_io_...`。"""
    return e[1:] if e.startswith('_') else e


def gen_wrapper(v):
    g = v.g
    L = []
    nf = len(v.fus)
    fu_desc = ', '.join(
        (f'{n}({t}, 不定延迟·常开门控)' if v.fu_cg_on[k] else
         f'{n}({t}, ' + ('不定延迟' if v.fu_unc[k] else f'延迟 {v.fu_lat[k]}') +
         (', 门控' if v.fu_cg[k] else '') + ')')
        for k, (t, n, _) in enumerate(v.fus))
    L.append('// =============================================================================')
    L.append(f'// {v.top} —— 执行单元外壳（golden 同名 wrapper；由 scripts/gen_exeunit.py 从 G1 golden 生成，勿手改）')
    L.append('// -----------------------------------------------------------------------------')
    L.append(f'// FU（按 Dispatcher 出口序）：{fu_desc}')
    L.append(f'// inPipe：{v.lat_max} 级；字段 ' + (', '.join(f'{n}[{w}]×{d}级' for n, w, d, _, _ in v.fields)
                                              if v.lat_max else '无') +
             ('；含 busy（不定延迟外壳一次只放一条）' if v.has_busy else ''))
    if v.att_fus:
        L.append(f'// instrAddrTransType 打一拍：{", ".join(v.att_fus)} 各一份')
    if v.aux:
        L.append('// FU 输入打拍（Scala DelayN，已签核件原样例化）：' +
                 ', '.join(f'{n}({t})' for t, n, _ in v.aux))
    if v.err:
        L.append(f'// 致命错误上报 io_error × {len(v.err)}：本层再打两拍（xs_CriticalErrorDelay_core，HasCriticalErrors）')
    L.append('// 机制全部在 xs_ExeUnit_core（发射握手 / inPipe 冲刷流水 / 时钟门控使能 / 写回有效）与')
    L.append('//   xs_ExeUnit_wbsel（写回字段 Mux1H）里；本文件只有例化、连线与字段打包。')
    L.append('// 子模块：Dispatcher 与各 FU、ClockGate' + ('、DelayN' if v.aux else '') +
             ' 均为已签核件（两侧白盒，实例名与 golden 相同）。')
    L.append(f'// golden 对照：G1-canonical/golden-rtl/{v.top}.sv')
    L.append('// 本文件导航（一个 golden 模块一个文件，不拆；行号由生成器回填）：')
    nav_at = len(L)
    L.append('@@NAV@@')
    L.append('// =============================================================================')
    L.append(f'module {v.top}(')
    L.append(g.port_text.strip('\n'))
    L.append(');')
    L.append('')
    # ---- 子模块输出线
    L.append('  // ---- 子模块输出线（名字 = golden 的 _<实例>_<端口> 去掉前导下划线）----')
    for n, w in g.wire_w.items():
        if n in g.wire_expr:
            continue
        if not n.startswith('_'):
            continue
        L.append(f'  wire {"[%d:0] " % (w - 1) if w > 1 else ""}{wname(n)};')
    if '_in1ToN_io_in_ready' not in g.wire_w:
        L.append('  wire in1ToN_io_in_ready;')
    L.append('')
    # ---- 核
    lat_p = v.lat_max
    L.append('  // ---- 外壳控制核 ----')
    L.append('  localparam int N_FU    = %d;' % nf)
    L.append('  localparam int LAT_MAX = %d;' % v.lat_max)
    L.append('  localparam int PAY_W   = %d;' % v.pay_w)
    natt = max(len(v.att_fus), 1)
    L.append(f'  wire                     disp_in_valid;')
    L.append(f'  wire [LAT_MAX:0]         pipe_valid;')
    L.append(f'  wire [LAT_MAX:0][PAY_W-1:0] pipe_data;')
    L.append(f'  wire [N_FU-1:0]          fu_clk_en;')
    L.append(f'  wire [{natt - 1}:0][4:0]        att_q;')
    L.append(f'  wire                     out_valid;')
    # payload 拼接（字段从高到低：最后一个字段在最高位）
    pay = []
    for n, w, d, subs, lo in reversed(v.fields):
        if n == 'robIdx':
            pay.append('io_in_bits_robIdx_flag, io_in_bits_robIdx_value')
        else:
            pay.append(f'io_in_bits_{n}')
    pay_expr = '{' + ', '.join(pay) + '}' if pay else "9'h0"
    if not v.fields:
        # 无 inPipe：payload 只放 robIdx（busy 用）；没有 robIdx 端口时给 0
        pay_expr = '{io_in_bits_robIdx_flag, io_in_bits_robIdx_value}' \
            if 'io_in_bits_robIdx_flag' in g.port_w else "9'h0"
    att_in = '{' + ', '.join(f'io_instrAddrTransType_{b}' for b in reversed(ATT_BITS)) + '}' \
        if v.att_fus else "5'h0"
    sel = lambda vec: '{' + ', '.join(reversed(vec)) + '}'
    fw = [w for _, w, _, _, _ in v.fields] or [9]
    fd = [d for _, _, d, _, _ in v.fields] or [0]
    L.append('  xs_ExeUnit_core #(')
    L.append(f'    .N_FU         (N_FU),')
    L.append(f"    .FU_LAT       ('{{{', '.join(map(str, v.fu_lat))}}}),")
    L.append(f"    .FU_UNCERTAIN ('{{{', '.join(map(str, v.fu_unc))}}}),")
    L.append(f"    .HAS_BUSY     (1'b{int(v.has_busy)}),")
    L.append(f'    .LAT_MAX      (LAT_MAX),')
    L.append(f'    .NF           ({len(fw)}),')
    L.append(f"    .FIELD_W      ('{{{', '.join(map(str, fw))}}}),")
    L.append(f"    .FIELD_DEPTH  ('{{{', '.join(map(str, fd))}}}),")
    L.append(f'    .PAY_W        (PAY_W),')
    L.append(f'    .N_ATT        ({len(v.att_fus)})')
    L.append('  ) u_core (')
    has_flush = 'io_flush_valid' in g.port_w
    conns = [
        ('clock', 'clock'), ('reset', 'reset'),
        ('flush_valid', 'io_flush_valid' if has_flush else "1'b0"),
        ('flush_rob_flag', 'io_flush_bits_robIdx_flag' if has_flush else "1'b0"),
        ('flush_rob_value', 'io_flush_bits_robIdx_value' if has_flush else "8'h0"),
        ('flush_level', 'io_flush_bits_level' if has_flush else "1'b0"),
        ('in_valid', 'io_in_valid'), ('in_ready', 'io_in_ready'),
        ('in_payload', pay_expr),
        ('disp_in_valid', 'disp_in_valid'), ('disp_in_ready', 'in1ToN_io_in_ready'),
        ('pipe_valid', 'pipe_valid'), ('pipe_data', 'pipe_data'),
        ('fu_in_valid', sel([f'in1ToN_io_out_{k}_valid' for k in range(nf)])),
        ('fu_in_ready', sel([f'{n}_io_in_ready' for n in v.fu_names])),
        ('fu_out_valid', sel([f'{n}_io_out_valid' for n in v.fu_names])),
        ('out_ready', 'io_out_ready'), ('fu_clk_en', 'fu_clk_en'),
        ('att_in', att_in), ('att_q', 'att_q'), ('out_valid', 'out_valid'),
    ]
    wmax = max(len(a) for a, _ in conns)
    L.append(',\n'.join(f'    .{a.ljust(wmax)} ({b})' for a, b in conns))
    L.append('  );')
    L.append('')
    # inPipe 拆包
    if v.lat_max:
        L.append('  // ---- inPipe 第 s 级字段拆包（只拆有 FU 读的那些）----')
        used = set()
        for typ, name, cs in v.fus:
            for p, e in cs:
                m = re.fullmatch(r'inPipe_1_(\d+)_(\w+)', e)
                if m:
                    used.add((int(m.group(1)), m.group(2)))
        for s, sub in sorted(used):
            for n, w, d, subs, lo in v.fields:
                for sn, sw, slo in subs:
                    if sn == sub:
                        rng = f'[{lo + slo}]' if sw == 1 else f'[{lo + slo + sw - 1}:{lo + slo}]'
                        L.append(f'  wire {"[%d:0] " % (sw - 1) if sw > 1 else ""}pipe{s}_{sub} = pipe_data[{s}]{rng};')
        L.append('')

    def conn_expr(iname, p, e):
        if e in ('', '/* unused */'):
            return e
        # Dispatcher 入口握手经过核（busy 拦截；无 busy 时核里是直通）
        if p == 'io_in_valid' and iname == 'in1ToN':
            return 'disp_in_valid'
        if p == 'io_in_ready' and iname == 'in1ToN':
            return 'in1ToN_io_in_ready'
        if e in g.port_w:
            return e
        m = re.fullmatch(r'inPipe_1_(\d+)_(\w+)', e)
        if m:
            return f'pipe{m.group(1)}_{m.group(2)}'
        m = re.fullmatch(r'inPipe_2_(\d+)', e)
        if m:
            return f'pipe_valid[{m.group(1)}]'
        m = re.fullmatch(r'(\w+)_io_instrAddrTransType_REG_(\w+)', e)
        if m:
            return f'att_q[{v.att_fus.index(m.group(1))}][{ATT_BITS.index(m.group(2))}]'
        if re.fullmatch(r'_\w+', e) and (e in g.wire_w):
            return wname(e)
        die(f'{v.top}.{iname}.{p}: 连线表达式不认识 {e}')

    def emit_inst(typ, name, cs, override=None):
        L.append(f'  {typ} {name} (')
        rows = []
        for p, e in cs:
            if override and p in override:
                ex = override[p]
            else:
                ex = conn_expr(name, p, e)
            rows.append((p, ex))
        wm = max(len(p) for p, _ in rows)
        L.append(',\n'.join(f'    .{p.ljust(wm)} ({e})' for p, e in rows))
        L.append('  );')

    L.append('  // ---- Dispatcher：按 fuType 把指令派给一个 FU ----')
    emit_inst(*v.disp)
    L.append('')
    L.append('  // ---- 功能单元 ----')
    for typ, name, cs in v.fus:
        emit_inst(typ, name, cs)
    if v.aux:
        L.append('')
        L.append('  // ---- FU 输入打拍：Scala `DelayN(exuio.exception, 2)` / `DelayN(exuio.robDeqPtr, 2)` ----')
        for typ, name, cs in v.aux:
            emit_inst(typ, name, cs)
    if v.cgs:
        L.append('')
        if any(v.fu_cg_on):
            L.append('  // ---- 时钟门控（E 来自核 §3，常开门控的 FU 接 1；TE 来自 DFT 的 cg_bore）----')
        else:
            L.append('  // ---- 时钟门控（E 来自核 §3；TE 来自 DFT 的 cg_bore）----')
        for typ, name, cs in v.cgs:
            k = v.fu_cg.index(name)
            emit_inst(typ, name, cs, override={'TE': v.cg_te[name],
                                               'E': "1'b1" if v.fu_cg_on[k] else f'fu_clk_en[{k}]',
                                               'CK': 'clock', 'Q': f'{name}_Q'})
    if v.err:
        L.append('')
        L.append('  // ---- 致命错误上报：FU 的 io_error 在本层再打两拍（HasCriticalErrors）----')
        L.append(f'  wire [{len(v.err) - 1}:0] err_out;')
        L.append(f'  xs_CriticalErrorDelay_core #(.N({len(v.err)})) u_err (')
        L.append('    .clock   (clock),')
        L.append('    .err_in  (' + sel([f'{f}_io_error_{j}' for _, f, j in v.err]) + '),')
        L.append('    .err_out (err_out)')
        L.append('  );')
        for k, _, _ in v.err:
            L.append(f'  assign io_error_{k} = err_out[{k}];')
    # ---- 写回
    L.append('')
    L.append('  // ---- 写回：io.out.valid 与各字段的 Mux1H ----')
    L.append('  assign io_out_valid = out_valid;')
    groups = {}
    for d, w, n in g.ports:
        if d != 'output':
            continue
        k = v.out_kind[n]
        if k[0] == 'mux':
            groups.setdefault(k[1], []).append(n)
    for n, k in v.out_kind.items():
        if k[0] == 'pass':
            src = f'{k[1]}_io_out_bits_{k[2]}'
            sw = g.wire_w['_' + src]
            ow = g.port_w[n]
            ex = src if sw == ow else f"{{{ow - sw}'h0, {src}}}"
            L.append(f'  assign {n} = {ex};   // 只有 {k[1]} 产出：单元素 Mux1H 直通')
    for gi, (members, outs) in enumerate(groups.items()):
        W = sum(g.port_w[o] for o in outs)
        L.append(f'  // 第 {gi} 组：{", ".join(members)} 共同产出 —— {", ".join(o[len("io_out_bits_"):] for o in outs)}')
        L.append(f'  wire [{W - 1}:0] wb{gi}_out;')
        datas = []
        for f in members:
            parts = []
            for o in outs:
                fld = v.out_kind[o][2][f]
                src = f'{f}_io_out_bits_{fld}'
                sw = g.wire_w['_' + src]
                ow = g.port_w[o]
                parts.append(src if sw == ow else f"{{{ow - sw}'h0, {src}}}")
            datas.append((f, parts))
        L.append(f"  xs_ExeUnit_wbsel #(.N({len(members)}), .W({W})) wb{gi} (")
        L.append(f"    .sel  ({sel([f'{f}_io_out_valid' for f in members])}),")
        # data 端口 = {成员 N-1, …, 成员 0}，每个成员的字段与输出口同序、一行一个
        L.append('    .data ({')
        blocks = []
        for f, parts in reversed(datas):
            if len(parts) == 1:
                blocks.append(f'      {parts[0]}')
            else:
                blocks.append('      {' + (',\n       ').join(parts) + '}')
        L.append(',\n'.join(blocks))
        L.append('    }),')
        L.append(f'    .out  (wb{gi}_out)')
        L.append('  );')
        if len(outs) == 1:
            L.append(f'  assign {outs[0]} = wb{gi}_out;')
        else:
            L.append('  assign {')
            L.append(',\n'.join(f'    {o}' for o in outs))
            L.append(f'  }} = wb{gi}_out;')
    L.append('')
    L.append('endmodule')
    # 导航回填：每个「// ---- 」分节注释一行（先用同样行数的占位展开全文，再按真实行号回填）
    secs = [ln for ln in L if isinstance(ln, str) and ln.startswith('  // ---- ')]
    draft = '\n'.join(L[:nav_at] + ['@@'] * len(secs) + L[nav_at + 1:]).split('\n')
    nav = []
    for ln in secs:
        no = draft.index(ln) + 1
        title = ln.strip()[len('// ---- '):].rstrip(' -')
        nav.append(f'//   L{no:<5d} {title}')
    L = L[:nav_at] + nav + L[nav_at + 1:]
    return '\n'.join(L) + '\n'


# =============================================================================
#  钉点
# =============================================================================
def child_pin_pairs(fu_type):
    """用 tclsh 桩真跑子 FU 的钉点文件，取 set_user_match 调用序列。"""
    f = REPO / 'verif' / 'ut' / CHILD_PIN_FILES[fu_type]
    stub = (
        'rename puts ::__orig_puts\n'
        'proc puts {args} {}\n'
        'set ::CALLS {}\n'
        'proc set_user_match {args} { lappend ::CALLS $args; return 1 }\n'
        f'set top {fu_type}\n'
        f'source {{{f}}}\n'
        'foreach c $::CALLS { ::__orig_puts stdout [join $c "\\t"] }\n'
    )
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as t:
        t.write(stub)
        tn = t.name
    r = subprocess.run(['tclsh', tn], stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    pathlib.Path(tn).unlink()
    if r.returncode != 0:
        die(f'tclsh 跑 {f} 失败: {r.stderr[:300]}')
    pairs = [tuple(ln.split('\t')) for ln in r.stdout.splitlines() if ln.strip()]
    # 与 docs/pin_call_seq.tsv 登记的调用数核对
    want = None
    for ln in (REPO / 'docs' / 'pin_call_seq.tsv').read_text().splitlines():
        c = ln.split('\t')
        if len(c) >= 3 and c[0] == f'verif/ut/{CHILD_PIN_FILES[fu_type]}' and c[1] == fu_type:
            want = int(c[2])
    if want is None or want != len(pairs):
        die(f'{fu_type}: 钉点调用数 {len(pairs)} 与 pin_call_seq.tsv 登记 {want} 不符')
    for p in pairs:
        if len(p) != 2 or not p[0].startswith(f'r:/WORK/{fu_type}/') or not p[1].startswith(f'i:/WORK/{fu_type}/'):
            die(f'{fu_type}: 钉点形状不认识 {p}')
    return pairs


def tcl_esc(s):
    return s.replace('[', '\\[').replace(']', '\\]')


def gen_pins(v):
    g = v.g
    rows = []
    # (a) 外壳寄存器
    for r in sorted(g.reg_w):
        path, base = v.reg_pin[r]
        w = g.reg_w[r]
        if base is None:
            if w != 1:
                die(f'{v.top}: {r} 多位却没有位映射')
            rows.append((f'{r}_reg', path))
        else:
            for b in range(w):
                ref = f'{r}_reg' if w == 1 else f'{r}_reg\\[{b}\\]'
                rows.append((ref, f'{path}\\[{base + b}\\]'))
    shell_n = len(rows)
    # (b) 子 FU 钉点
    child = []
    for typ, name, cs in v.fus:
        if typ in CHILD_PIN_FILES:
            for rp, ip in child_pin_pairs(typ):
                child.append((name, typ, tcl_esc(rp[len(f'r:/WORK/{typ}/'):]),
                              tcl_esc(ip[len(f'i:/WORK/{typ}/'):])))
        for rp, ip in EXTRA_CHILD_PINS.get(typ, []):
            child.append((name, typ + ' 外壳附加', tcl_esc(rp), tcl_esc(ip)))
    total = shell_n + len(child)
    if total == 0:
        return None          # 没有要钉的点：不生成钉点文件（空钉点文件没有意义，gate 的钉点结构闸要求期望数为正）
    tag = re.sub(r'\W', '_', v.top).upper()
    L = []
    L.append(f'# {v.top} FM「匹配前」钉点 —— 自动生成：scripts/gen_exeunit.py（勿手改）')
    L.append('#')
    L.append('# 只消命名差：set_user_match 只声明两点对应，比较照比；不约束 ref、不改 appvar、不加黑盒。')
    L.append(f'# (a) 外壳寄存器 {shell_n} 位：golden 扁平名 <-> xs_ExeUnit_core 的数组 / generate 名；')
    L.append(f'# (b) 子 FU 签核时用过的钉点 {len(child)} 条：tclsh 桩真跑原钉点文件取调用序列，加实例前缀。')
    L.append('# fail-closed：逐条数返回值；拒一条或总数 != 字面整数即 error。输出一律 ASCII。')
    L.append(f'set ::{tag}_PIN_OK 0')
    L.append(f'set ::{tag}_PIN_BAD 0')
    L.append(f'proc {tag.lower()}_pin {{r i}} {{')
    L.append(f'  set rr "r:/WORK/{v.top}/$r"')
    L.append(f'  set ii "i:/WORK/{v.top}/$i"')
    L.append(f'  if {{[set_user_match $rr $ii]}} {{ incr ::{tag}_PIN_OK }} else {{')
    L.append(f'    incr ::{tag}_PIN_BAD')
    L.append(f'    if {{$::{tag}_PIN_BAD <= 10}} {{ puts "{tag}_PIN_FAIL: $rr <-> $ii" }}')
    L.append('  }')
    L.append('}')
    L.append(f'puts "{tag}_PIN_BEGIN {v.top} expect={total}"')
    L.append('# ---- (a) 外壳寄存器 ----')
    for r, i in rows:
        L.append(f'{tag.lower()}_pin {r} {i}')
    cur = None
    for name, typ, rp, ip in child:
        if cur != (name, typ):
            if typ.endswith(' 外壳附加'):
                L.append(f'# ---- (c) {name}（{typ}）：gen_exeunit.py EXTRA_CHILD_PINS（依据见该表注释）----')
            else:
                L.append(f'# ---- (b) {name}（{typ}）：verif/ut/{CHILD_PIN_FILES[typ]} 的调用序列 ----')
            cur = (name, typ)
        L.append(f'{tag.lower()}_pin {name}/{rp} {name}/{ip}')
    L.append(f'puts "{tag}_PIN_END ok=$::{tag}_PIN_OK bad=$::{tag}_PIN_BAD expect={total}"')
    L.append(f'if {{$::{tag}_PIN_BAD != 0}} {{ error "{tag}_PIN_REFUSED=$::{tag}_PIN_BAD" }}')
    L.append(f'if {{$::{tag}_PIN_OK != {total}}} {{ error "{tag}_PIN_COUNT=$::{tag}_PIN_OK expected {total}" }}')
    return '\n'.join(L) + '\n'


def gen_dyn_pins(v):
    """含动态钉点子 FU 的变体：把子 FU 的匹配后钉点文件机械改前缀照搬（逐项核替换次数）。"""
    parts = []
    for typ, name, cs in v.fus:
        if typ not in DYN_CHILD_PIN_FILES:
            continue
        rel = DYN_CHILD_PIN_FILES[typ]
        src = (REPO / 'verif' / 'ut' / rel).read_text()
        old_pfx, new_pfx = f'/WORK/{typ}/', f'/WORK/{v.top}/{name}/'
        old_g, new_g = f'if {{$top eq "{typ}"}} {{', f'if {{$top eq "{v.top}"}} {{'
        n_pfx = src.count(old_pfx)
        if n_pfx == 0 or src.count(old_g) != 1:
            die(f'{v.top}.{name}: {rel} 的前缀 / 守卫形状不认识（前缀 {n_pfx} 处，守卫 {src.count(old_g)} 处）')
        out = src.replace(old_pfx, new_pfx).replace(old_g, new_g)
        if out.count(new_pfx) != n_pfx + src.count(new_pfx) or f'"{typ}"' in out.replace(f'"{v.top}"', ''):
            die(f'{v.top}.{name}: {rel} 改前缀后核对不过')
        parts.append((name, typ, rel, n_pfx, out))
    if not parts:
        return None
    L = [f'# {v.top} FM「匹配后」钉点 —— 自动生成：scripts/gen_exeunit.py gen_dyn_pins（勿手改）',
         '#',
         '# 子 FU 签核用的动态钉点文件（匹配后按 report_unmatched_points 现场配对、fail-closed）整份照搬，',
         '# 只做两处机械替换：点名前缀 /WORK/<FU 类型>/ -> /WORK/<本变体>/<实例名>/，守卫 $top eq "<FU 类型>" -> 本变体。',
         '# 族的定义、自检与 error 判据一字未改（见原文件头）。']
    for name, typ, rel, n_pfx, _ in parts:
        L.append(f'#   {name}（{typ}）<- verif/ut/{rel}：前缀替换 {n_pfx} 处，守卫 1 处')
    L.append('')
    body = '\n'.join(L) + '\n'
    for name, typ, rel, n_pfx, out in parts:
        body += f'# ==== {name}（{typ}）：verif/ut/{rel} 改前缀 ====\n' + out
    return body


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    ap.add_argument('variants', nargs='*')
    a = ap.parse_args()
    drift = 0
    for top in a.variants or VARIANTS:
        v = Variant(top)
        outs = {
            REPO / 'rtl' / 'backend' / f'{top}.sv': gen_wrapper(v),
            REPO / 'verif' / 'ut' / top / 'fm_pins_pre.tcl': gen_pins(v),
        }
        dyn = gen_dyn_pins(v)
        if dyn is not None:            # 只有含动态钉点子 FU 的变体才管这个文件，其余变体不碰
            outs[REPO / 'verif' / 'ut' / top / 'fm_pins.tcl'] = dyn
        for p, text in outs.items():
            cur = p.read_text() if p.exists() else None
            if text is None:                       # 本变体不该有这个文件
                if cur is not None:
                    if a.check:
                        print(f'DRIFT {p.relative_to(REPO)}（应不存在）')
                        drift = 1
                    else:
                        p.unlink()
                        print(f'removed {p.relative_to(REPO)}')
                continue
            if a.check:
                if cur != text:
                    print(f'DRIFT {p.relative_to(REPO)}')
                    drift = 1
            elif cur != text:
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(text)
                print(f'wrote {p.relative_to(REPO)}')
    if a.check and not drift:
        print('gen_exeunit: 全部与生成结果一致')
    return drift


if __name__ == '__main__':
    sys.exit(main())
