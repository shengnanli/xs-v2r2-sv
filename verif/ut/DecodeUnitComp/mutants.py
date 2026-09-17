#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""mutants.py —— DecodeUnitComp UT 的判别力负测（`make mutants`）。

为什么要有它：`errors=0` 只在「注入真 bug 时 UT 会红」的前提下才有意义。本模块
有 638 根输出线、43 个拆分分支，最容易出现的假象是「随机激励让某个分支从来没被
锁存进来」，那一轮的 errors=0 什么都没证明。

做法：把 rtl/ 与本目录复制进 neg_build/（已 gitignore，**变异不进库**），逐个注入
一个真 bug，跑 40k 拍，要求每个都被 UT 抓出来（errors > 0）。

**MUTANTS —— 必须被抓到**，分四类：
  · 复位域（M1/M2）：给 99 个本来**不复位**的锁存寄存器加上复位 / 去掉 3 个状态机
    寄存器的复位。这两条是本模块复位域结论的守门人 —— 四道机器闸
    （elaborate / portlint / 可读性 / 端口契约）对它们**一个都不响**。
  · Vec 越界语义（M3/M4）：count 超出本路实际组数时该取「本路第 0 项」。
    改成取 0 或取最后一项都是真 bug，而且都「看起来更合理」。
  · 拆分表细节（M5~M12）：每条对准一个「照字面抄 Chisel 就会写错」的点。
  · 状态机与出口（M13~M14）。

**EXPECTED_MISSED —— 预期抓不到，且必须抓不到**：
  把「我在 RTL 注释里声称等价」的改写钉成可复跑的断言。被抓到 = 注释里的论证
  被推翻，脚本报失败。

★同样重要：报告每个变异的 errors 数★。余量薄的换个 seed 就可能漏。

用法: python3 mutants.py      （或 make mutants）
"""
import pathlib
import re
import shutil
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
BUILD = HERE / 'neg_build'
RTL = ['VecExceptionGen.sv', 'xs_indexedLSUopTable_core.sv', 'DecodeUnitComp.sv'] + \
      [f'indexedLSUopTable_{i}.sv' for i in range(1, 8)]
NCYCLES = '40000'
TGT = 'DecodeUnitComp.sv'

MUTANTS = [
    ('M1 给 99 个锁存寄存器加上复位（golden 这条 always 没有 reset 分支）',
     "  always_ff @(posedge clock) begin\n    if (in_valid && in_ready) begin\n"
     "      latched_q          <= in_fixed;\n      latched_uop_info_q <= in_uop_info;\n    end\n  end",
     "  always_ff @(posedge clock or posedge reset) begin\n    if (reset) begin\n"
     "      latched_q <= '0;\n      latched_uop_info_q <= '0;\n"
     "    end else if (in_valid && in_ready) begin\n"
     "      latched_q          <= in_fixed;\n      latched_uop_info_q <= in_uop_info;\n    end\n  end"),
    ('M2 去掉状态机 3 个寄存器的复位（golden 是异步高有效复位、复位值全 0）',
     "  always_ff @(posedge clock or posedge reset) begin\n    if (reset) begin\n"
     "      state_q   <= 1'b0;\n      uop_res_q <= 7'd0;\n      count_q   <= 4'd0;\n    end else begin",
     "  always_ff @(posedge clock) begin\n    if (1'b0) begin\n"
     "      state_q   <= 1'b0;\n      uop_res_q <= 7'd0;\n      count_q   <= 4'd0;\n    end else begin"),
    ('M3 count 越界的组填 0（golden 是填**本路第 0 项**）',
     "        slot_tab[s][k] = (k * RENAME_W + s < MAX_UOP) ? fixed[k * RENAME_W + s]\n"
     "                                                      : fixed[s];",
     "        slot_tab[s][k] = (k * RENAME_W + s < MAX_UOP) ? fixed[k * RENAME_W + s]\n"
     "                                                      : '0;"),
    ('M4 count 越界的组填本路最后一项（另一种「看起来合理」的猜法）',
     "        slot_tab[s][k] = (k * RENAME_W + s < MAX_UOP) ? fixed[k * RENAME_W + s]\n"
     "                                                      : fixed[s];",
     "        slot_tab[s][k] = (k * RENAME_W + s < MAX_UOP) ? fixed[k * RENAME_W + s]\n"
     "                                                      : fixed[60 + s];"),
    ('M5 VEC_M0X 第 0 个 uop 的 lsrc(0) 写成 v32（Chisel 详细描述期算出来是 v31）',
     "          cs[i].lsrc[0]    = VTMP + 6'(i) - 6'd1;",
     "          cs[i].lsrc[0]    = VTMP + 6'(i);"),
    ('M6 VEC_S_LDST 的跨距源取指令字里的 rs2，而不是译码出的 lsrc(1)',
     "        cs[1].lsrc[0]    = latched_q.lsrc[1];",
     "        cs[1].lsrc[0]    = src2;"),
    ('M7 vslideup/vslidedown 的标量搬运用 Dup 版操作码（应是非 Dup 的 imm2Vec/i2Vec）',
     "        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMM2VEC : IF2V_I2VEC, vsew_r};\n"
     "        cs[0].vecWen     = 1'b1;\n        for (int i = 0; i < MAX_VLMUL; i++) begin\n"
     "          for (int j = 0; j <= i; j++) begin",
     "        cs[0].fuOpType   = {4'd0, src1_is_imm ? IF2V_IMMDUP2VEC : IF2V_IDUP2VEC, vsew_r};\n"
     "        cs[0].vecWen     = 1'b1;\n        for (int i = 0; i < MAX_VLMUL; i++) begin\n"
     "          for (int j = 0; j <= i; j++) begin"),
    ('M8 索引访存漏掉 indexedLSUopTable 查出来的 vs2 偏移',
     "            cs[i + 1].lsrc[1]    = src2 + {3'b000, idx_off_vs2[i]};",
     "            cs[i + 1].lsrc[1]    = src2;"),
    ('M9 VSET 的 keepVl / setVlmax 两个位搞反',
     "        in_fixed.fuOpType = in_inst.fuOpType | (9'd1 << VSET_KEEPVL_BIT);",
     "        in_fixed.fuOpType = in_inst.fuOpType | (9'd1 << VSET_SETVLMAX_BIT);"),
    # ★注意：变异必须**真的改变电路**★。这条第一版写成给同一根 3 位线套一层
    # `3'(…)`，等于什么都没改，跑出来是假的 MISSED（同型错误在 VecExceptionGen
    # 的负测里也犯过一次）。现在连声明一起加宽，才真的把截断去掉。
    ('M10 vemul 算成 4 位不截断（Chisel 的 `+` 在 3 位上做模运算）',
     "  logic [2:0] vemul_raw;\n  logic [1:0] simple_lmul, simple_emul;\n"
     "  assign vemul_raw = ({1'b0, width} + vlmul_r) + (~{1'b0, vsew_r} + 3'd1);",
     "  logic [3:0] vemul_raw;\n  logic [1:0] simple_lmul, simple_emul;\n"
     "  assign vemul_raw = ({2'b0, width} + {1'b0, vlmul_r}) + (~{2'b0, vsew_r} + 4'd1);"),
    ('M11 fixedDecodedInst 的 flushPipe 回收打在第 0 个 uop 而不是最后一个',
     "      if (7'(i) == last_uop_idx) fixed[i].flushPipe = latched_q.flushPipe;",
     "      if (i == 0) fixed[i].flushPipe = latched_q.flushPipe;"),
    ('M12 VEC_VFREDOSUM 的 e32 折叠标志把 isWiden 取反',
     "              cs[i].vpu_fpu_isFoldTo1_2 =  is_widen_ordered_red && (i % 4 != 0);\n"
     "              cs[i].vpu_fpu_isFoldTo1_4 = !is_widen_ordered_red && (i % 4 != 0);",
     "              cs[i].vpu_fpu_isFoldTo1_2 = !is_widen_ordered_red && (i % 4 != 0);\n"
     "              cs[i].vpu_fpu_isFoldTo1_4 =  is_widen_ordered_red && (i % 4 != 0);"),
    ('M13 uopRes 的更新优先级：把 redirect 降到「本拍吐完」之后',
     "      if (redirect) begin\n        uop_res_q <= 7'd0;\n        count_q   <= 4'd0;\n"
     "      end else if (state_q) begin",
     "      if (state_q && this_all_out) begin\n"
     "        uop_res_q <= in_valid ? in_uop_info.numOfUop : 7'd0;\n        count_q <= 4'd0;\n"
     "      end else if (redirect) begin\n        uop_res_q <= 7'd0;\n        count_q   <= 4'd0;\n"
     "      end else if (state_q) begin"),
    ('M14 in_ready 漏掉 thisAllOut（active 态永远不收新指令）',
     "  assign in_ready    = ~state_q | (state_q & this_all_out);",
     "  assign in_ready    = ~state_q;"),
    # 这一条把「Chisel 的 DontCare 在条件赋值里等于不赋值」从假设变成证据：
    # 如果改成「赋 0」会被 UT 抓到，说明 golden 确实是「保持默认」那一种。
    ('M16 vcompress 的「进位」uop 把 DontCare 当成赋 0（应是保持默认）',
     "              if (j != i + 1) begin\n"
     "                cs[i * (i + 3) / 2 + j].srcType[0] = ST_VP;\n"
     "                cs[i * (i + 3) / 2 + j].srcType[2] = ST_VP;\n"
     "              end",
     "              if (j != i + 1) begin\n"
     "                cs[i * (i + 3) / 2 + j].srcType[0] = ST_VP;\n"
     "                cs[i * (i + 3) / 2 + j].srcType[2] = ST_VP;\n"
     "              end else begin\n"
     "                cs[i * (i + 3) / 2 + j].srcType[0] = ST_IMM;\n"
     "                cs[i * (i + 3) / 2 + j].srcType[2] = ST_IMM;\n"
     "              end"),
    ('M15 vrgather.vx 把「先 len=1 再按 vlmul 覆盖」的顺序反过来',
     "        // len = 1（无条件）\n        cs[1].srcType[0] = ST_VP;\n"
     "        cs[1].lsrc[0]    = VTMP;\n        cs[1].lsrc[1]    = src2;\n"
     "        cs[1].lsrc[2]    = vdst;\n        cs[1].ldest      = vdst;\n"
     "        cs[1].uopIdx     = 7'd0;\n        case (vlmul_r)",
     "        case (vlmul_r)"),
]

# 预期抓不到：RTL 注释里声称「行为等价、只是写法照抄 golden」的地方。
EXPECTED_MISSED = [
    # X1 与 X2 是同一条不变量的两面：**idle 态下 uopRes 恒为 0**
    #   （复位清 0；active 且 thisAllOut 且无新指令时写 0；redirect 时写 0；
    #     idle 且无新指令时保持 0），于是 complexNum = min(uopRes, readyCounter) = 0。
    # golden 在这上面是**不对称**的：complexNum 有一层 state 门控，out_valid 没有 ——
    # 而两者其实都是冗余的。本重写逐字照抄 golden 的这份不对称，不替它补齐、也不替它
    # 化简；这两条变异就是把「照抄」这件事钉成可复跑的断言。
    # （X2 原本列在「必须抓到」里，实测抓不到，追下去发现是同一条不变量 —— 已改判，
    #   连同这段论证一起留档。）
    ('X1 给 out_valid 加一层 state 门控',
     "      out_valid[i] = (complex_num_full > 7'(i));",
     "      out_valid[i] = state_q && (complex_num_full > 7'(i));",
     'idle 态下 uopRes 恒为 0（复位清 0，且离开 active 时也写 0），complexNum 因此也是 0，'
     '`0 > i` 恒假 —— 加不加 state 门控输出相同。RTL 里照 golden 不加。'),
    ('X2 去掉 complexNum 的 state 门控',
     "  assign complex_num = state_q ? complex_num_full[2:0] : 3'd0;",
     "  assign complex_num = complex_num_full[2:0];",
     '同一条不变量：idle 态下 complexNum 本来就是 0，门控去掉与否输出相同。'
     'RTL 里照 golden **保留**这层门控（golden 有它）。'),
]


def prepare():
    if BUILD.exists():
        shutil.rmtree(BUILD)
    (BUILD / 'rtl' / 'backend').mkdir(parents=True)
    (BUILD / 'verif' / 'ut' / 'DecodeUnitComp').mkdir(parents=True)
    (BUILD / 'scripts').symlink_to(REPO / 'scripts')
    restore()
    for f in ('Makefile', 'tb.sv'):
        shutil.copy(HERE / f, BUILD / 'verif' / 'ut' / 'DecodeUnitComp' / f)


def restore():
    for f in RTL:
        shutil.copy(REPO / 'rtl' / 'backend' / f, BUILD / 'rtl' / 'backend' / f)


def run_ut():
    ut = BUILD / 'verif' / 'ut' / 'DecodeUnitComp'
    subprocess.run(['make', 'run', 'SEED=1', 'NCYCLES=' + NCYCLES], cwd=str(ut),
                   stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   universal_newlines=True)
    log = ut / 'sim_1.log'
    if not log.exists():
        return None
    txt = log.read_text()
    m = re.search(r'TEST FAILED errors=(\d+) \(checks=(\d+)\)', txt)
    if m:
        return (int(m.group(2)), int(m.group(1)))
    m = re.search(r'TEST PASSED \(checks=(\d+)\)', txt)
    return (int(m.group(1)), 0) if m else None


def apply_and_run(name, old, new):
    restore()
    tgt = BUILD / 'rtl' / 'backend' / TGT
    t = tgt.read_text()
    if old not in t:
        print('!! %s：锚点没找到，变异未生效（源码改过？请同步本文件）' % name)
        return None
    tgt.write_text(t.replace(old, new, 1))
    return run_ut()


def main():
    prepare()
    print('=== 基线（未变异，%s 拍）===' % NCYCLES)
    base = run_ut()
    if base is None or base[1] != 0:
        print('基线就不是 errors=0，负测无意义：', base)
        return 2
    print('    checks=%d errors=%d' % base)

    missed = []
    for name, old, new in MUTANTS:
        res = apply_and_run(name, old, new)
        if res is None:
            missed.append(name)
            continue
        ok = res[1] > 0
        print('  %-60s checks=%-8d errors=%-10d %s'
              % (name, res[0], res[1], 'CAUGHT' if ok else '★MISSED★'))
        if not ok:
            missed.append(name)

    print('=== 预期抓不到的变异（论证见本文件 EXPECTED_MISSED）===')
    unexpected = []
    for name, old, new, why in EXPECTED_MISSED:
        res = apply_and_run(name, old, new)
        if res is None:
            unexpected.append(name)
            continue
        ok = (res[1] == 0)
        print('  %-60s checks=%-8d errors=%-10d %s'
              % (name, res[0], res[1],
                 'MISSED(如预期)' if ok else '★UNEXPECTEDLY CAUGHT★'))
        print('        论证：%s' % why)
        if not ok:
            unexpected.append(name)

    restore()
    rc = 0
    if missed:
        print('=== MUTANTS FAILED：以下变异没被 UT 抓到 ===')
        for m in missed:
            print('   ', m)
        rc = 1
    else:
        print('=== %d/%d 个「应当抓到」的变异全部被 UT 抓到 ===' % (len(MUTANTS), len(MUTANTS)))
    if unexpected:
        print('=== 论证被推翻：以下「预期抓不到」的变异竟然被抓到了 ===')
        for m in unexpected:
            print('   ', m)
        rc = 1
    else:
        print('=== %d/%d 个「预期抓不到」的变异确实没被抓到（论证成立）==='
              % (len(EXPECTED_MISSED), len(EXPECTED_MISSED)))
    return rc


if __name__ == '__main__':
    sys.exit(main())
