#!/usr/bin/env python3
"""mutants.py —— 向量浮点转换子树各 UT 的变异体自检（判据自证：UT 看得见改变）。

做法：把 rtl/ scripts/ 与被测 UT 目录**复制到 scratchpad 镜像**里，在镜像上逐个施加变异
（每个变异必须在目标文件里恰好命中 1 处，否则判「变异未落地」），跑 UT（默认 SEED=901、
+vcs+initreg+0、200000 拍），要求 UT 判 FAIL。工作树里的 RTL **从不被改动**——这正是
2026-10-03 那条新规（变异体被提交进分支）要防的事：变异只活在镜像里。

用法：
  python3 verif/ut/VectorCvt_common/mutants.py <UT目录名> [--out <镜像根>] [--ncycles N] [--only M1,M3]
结果：打印每个变异体 CAUGHT / MISSED / NOT_APPLIED 与 errors / oracle_errors，退出码 = MISSED+NOT_APPLIED 个数。
"""
import argparse
import os
import pathlib
import re
import shutil
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parents[3]

# (编号, 文件, 原文, 替换, 说明)
MUTANTS = {
  'INT2FP': [
    ('M1', 'INT2FP.sv', "| ~signSrc & rm == 3'h2;", "| ~signSrc & rm == 3'h3;", 'rmin 的 RDN 判据写成 RUP'),
    ('M2', 'INT2FP.sv', "| out_f32 & (|shifted[39:0])", "| out_f32 & (|shifted[38:0])", 'f32 sticky 少收 1 位'),
    ('M3', 'INT2FP.sv', "{{57{is_signed & src[7]}},  src[7:0]}", "{57'h0,  src[7:0]}", 'i8 源不做符号扩展'),
    ('M4', 'INT2FP.sv', "13'd190", "13'd191", 'f32 指数偏置 +1'),
    ('M5', 'INT2FP.sv', "assign of_f16 = cout ? (&exp[4:1])", "assign of_f16 = cout ? (&exp[4:0])", 'f16 上溢判定忽略进位'),
    ('M6', 'INT2FP.sv', "fflags <= {2'b00, overflow, 1'b0, overflow | rnd_inexact};",
                        "fflags <= {2'b00, overflow, 1'b0, rnd_inexact};", '上溢不置 NX'),
  ],
  'Estimate7': [
    ('M1', 'Estimate7.sv', "(is_rec_next ? 13'd253  : 13'd380)", "(is_rec_next ? 13'd254  : 13'd380)", 'f32 rec7 指数常数 +1'),
    ('M2', 'Estimate7.sv', ".src ({expNormaled0, frac_norm[63:58]}),", ".src ({1'b0, frac_norm[63:58]}),", 'rsqrt7 查表丢掉指数奇偶位'),
    ('M3', 'Estimate7.sv', "assign rec_inf_out    = isZeroSrc | isSubnormalRec2 & ~rmin;",
                           "assign rec_inf_out    = isZeroSrc | isSubnormalRec2 & rmin;", 'rec7 上溢的 rmin 方向反了'),
    ('M4', 'Estimate7.sv', "assign nv = isRec ? isSNaNSrc : (signSrc & ~isZeroSrc & ~isQNaNSrc) | isSNaNSrc;",
                           "assign nv = isRec ? isSNaNSrc : (signSrc & ~isZeroSrc) | isSNaNSrc;", 'rsqrt7(-qNaN) 误置 NV'),
    ('M5', 'Estimate7.sv', "isSubnormalRec1 <= is_subnormal_next & ~frac_next[51] & frac_next[50];",
                           "isSubnormalRec1 <= is_subnormal_next & frac_next[50];", 'rec7 非规格化档判据少 1 项'),
    ('M6', 'Estimate7.sv', "(rec_sub2       ? {signSrc, 11'h0, 1'b1, frac_est, 44'h0}",
                           "(rec_sub2       ? {signSrc, 11'h0, 1'b1, frac_est, 44'h1}", 'f64 rec7 非规格化结果多 1 位'),
  ],
  'CVT64_1': [
    ('M1', 'CVT64_1.sv', "isFp2Int       <= ~out_is_fp;", "isFp2Int       <= ~out_is_fp & in_is_fp;", 'f2i 选择多加门控'),
    ('M2', 'CVT64_1.sv', "s2_isFPsrc     <= isFpWiden | isFpNarrow | isFpCrossHigh | isFpCrossLow | isFp2Int;",
                         "s2_isFPsrc     <= isFpWiden | isFpNarrow | isFpCrossHigh | isFp2Int;", '漏掉 cross-low'),
    ('M3', 'CVT64_1.sv', "    if (fireReg_last_r) begin\n      s2_isInt2Fp", "    if (fire) begin\n      s2_isInt2Fp", 's2 级使能用错（少一拍）'),
    ('M4', 'CVT64_1.sv', "| (s2_isEstimate7 ? est7_fflags   : 5'h0);", "| (s2_isEstimate7 ? 5'h0          : 5'h0);", '估算类 fflags 丢失'),
    ('M5', 'CVT64_1.sv', "isFpCrossLow   <= in_is_fp & out_is_fp & is_cross & (out_is_fp & out_width_1h[1]);",
                         "isFpCrossLow   <= in_is_fp & out_is_fp & is_cross & (out_is_fp & out_width_1h[2]);", 'cross-low 看错宽度位'),
  ],
  'CVT32': [
    ('M1', 'CVT32.sv', "| (fp16toint8  ? 8'd22  : 8'h0);  // 15 + 7", "| (fp16toint8  ? 8'd23  : 8'h0);  // 15 + 7", 'f16->i8 最大指数 +1'),
    ('M2', 'CVT32.sv', "assign use_clz32  = out_is_fp32 | exp_of;", "assign use_clz32  = out_is_fp32;", 'int2fp_clz 去掉 exp_of 怪癖'),
    ('M3', 'CVT32.sv', "assign exp_normalized_8  = (in_is_fp32 & is_vfrsqrt7 & is_poszero_posinf & is_normal | is_vfrec7 & is_normal",
                       "assign exp_normalized_8  = (in_is_fp32 & (is_vfrsqrt7 & is_poszero_posinf & is_normal | is_vfrec7 & is_normal)",
                       'exp_normalized_8 补上 Scala 漏掉的 in_is_fp32 门控'),
    ('M4', 'CVT32.sv', "assign nor_of_reg0     = nor_cout ? $signed(down_exp_reg0) > 9'sd29 : $signed(down_exp_reg0) > 9'sd30;",
                       "assign nor_of_reg0     = $signed(down_exp_reg0) > 9'sd30;", 'f2f 变窄上溢忽略舍入进位'),
    ('M5', 'CVT32.sv', "| fp2fp_widen & f16_exp_ones & f16_sig_nz & ~fp_sig[22];", "| fp2fp_widen & f16_exp_ones & f16_sig_nz;", 'f2f 变宽 qNaN 也置 NV'),
    ('M6', 'CVT32.sv', "    | (result1H[12] ? (rup_rtz ? 32'h0000FBFF : 32'h0000FC00)",
                       "    | (result1H[12] ? (rdn_rtz ? 32'h0000FBFF : 32'h0000FC00)", 'f16 rec7 负上溢方向反了'),
    ('M7', 'CVT32.sv', "    | (is_signed_int & int8tofp16   ? {{25{src_in[7]}}, src_in[7:0]}  : 33'h0);",
                       "    | (is_signed_int & int8tofp16   ? {25'h0, src_in[7:0]}            : 33'h0);", 'i8->f16 不符号扩展'),
    ('M8', 'CVT32.sv', "subnor_stickyBit_reg0    <= subnor_shift_sticky | nor_stickyBit;",
                       "subnor_stickyBit_reg0    <= subnor_shift_sticky;", 'f2f 变窄非规格化 sticky 漏低位'),
  ],
  'CVT16': [
    ('M1', 'CVT16.sv', "assign sel_lpath = exp >= 5'd25;", "assign sel_lpath = exp >= 5'd26;", '左路门限 +1'),
    ('M2', 'CVT16.sv', "& (in_exp_reg0 == 5'd22 | in_exp_reg0 == 5'd21 & cout_reg0)", "& (in_exp_reg0 == 5'd22)", 'i8 有符号正上溢漏进位档'),
    ('M3', 'CVT16.sv', "| (sel_rec_inf ? (is_neginf_reg0 ? 16'h8000 : 16'h0)         : 16'h0)",
                       "| (sel_rec_inf ? 16'h0                                        : 16'h0)", '去掉 fflags 第 15 位怪癖（输出不可见）'),
    ('M4', 'CVT16.sv', "assign out_exp_zero_negone = is_vfrec7 & out_exp_normalized == 5'h0 | (&out_exp_normalized);",
                       "assign out_exp_zero_negone = is_vfrec7 & out_exp_normalized == 5'h0;", 'rec7 漏掉指数 -1 档'),
    ('M5', 'CVT16.sv', "                             ? {1'b1, RESULT_GFIN} : {1'b1, RESULT_INF})",
                       "                             ? {1'b1, RESULT_INF} : {1'b1, RESULT_INF})", 'rec7 负上溢不给最大有限数'),
    ('M6', 'CVT16.sv', "assign exp_raw       = is_int2fp ? 5'(5'd30 - int2fp_clz) : 5'h0;",
                       "assign exp_raw       = is_int2fp ? 5'(5'd29 - int2fp_clz) : 5'h0;", 'i2f 指数偏 1'),
  ],
  'VectorCvt': [
    ('M1', 'VectorCvt.sv', "4'b10_01: begin input1H = 4'b0100; output1H = 4'b0010; end",
                           "4'b10_01: begin input1H = 4'b0010; output1H = 4'b0010; end", '变窄 32->16 源宽译错'),
    ('M2', 'VectorCvt.sv', "                   | (input1H[1] ? src[63:48]      : 16'h0);", "                   | (input1H[1] ? src[47:32]      : 16'h0);", '通道 3 取错元素'),
    ('M3', 'VectorCvt.sv', "    if (outputWidth1H_last_r)\n      outputWidth1H <= outputWidth1H_r;",
                           "    if (fire)\n      outputWidth1H <= outputWidth1H_r;", '第二级宽度寄存器使能用错'),
    ('M4', 'VectorCvt.sv', "                | (outputWidth1H[2] ? 20'({ff1, ff0})      : 20'h0)", "                | (outputWidth1H[2] ? 20'({ff0, ff1})      : 20'h0)", '32 位结果 fflags 通道序反了'),
  ],
  'VectorCvtTop': [
    ('M1', 'VectorCvtTop.sv', "assign widen_src = uop_idx ? src_hi : src_lo;", "assign widen_src = uop_idx ? src_lo : src_hi;", '变宽选半反了'),
    ('M2', 'VectorCvtTop.sv', "assign result = isNarrowCycle2 ? {64'h0, res1[31:0], res0[31:0]} : {res1, res0};",
                              "assign result = isNarrowCycle2 ? {64'h0, res0[31:0], res1[31:0]} : {res1, res0};", '变窄拼接顺序反了'),
    ('M3', 'VectorCvtTop.sv', "    | (outputWidth1HCycle2[1] ? (isNarrowCycle2 ? 40'({ff1[9:0], ff0[9:0]}) : ff_all)",
                              "    | (outputWidth1HCycle2[1] ? ff_all", '16 位变窄 fflags 不压缩'),
    ('M4', 'VectorCvtTop.sv', "      isNarrowCycle2_r      <= is_narrow;", "      isNarrowCycle2_r      <= is_widen;", '窄标志接成宽标志'),
  ],
  'VCVT_8': [
    ('M1', 'VCVT_8.sv', "assign isRod       = opcode[2] & ~opcode[1] & opcode[0];", "assign isRod       = opcode[2] & ~opcode[1];", 'ROD 判据少 1 位'),
    ('M2', 'VCVT_8.sv', "fflagsEn[i] = mask[i] & (11'(eNumEffectIdx) > 11'(eStart + 11'(i)));",
                        "fflagsEn[i] = mask[i] & (11'(eNumEffectIdx) >= 11'(eStart + 11'(i)));", 'fflags 元素尾界差 1'),
    ('M3', 'VCVT_8.sv', "      3'b10_1: decodeElemNum = 4'b0010;", "      3'b10_1: decodeElemNum = 4'b0100;", '32 位变宽/窄元素数错'),
    ('M4', 'VCVT_8.sv', "      vldThisFu[1] <= io_in_valid;", "      vldThisFu[1] <= io_in_valid & rdy[0];", 'valid 链加 ready 门控'),
    ('M5', 'VCVT_8.sv', "                   ? {vfcvt_result[63:0], oldVd[63:0]}", "                   ? {oldVd[127:64], vfcvt_result[63:0]}", '变窄高半 uop 拼错位置'),
    ('M6', 'VCVT_8.sv', "assign eNumMax        = io_in_bits_ctrl_vpu_vlmul[2] ? 7'(eNumMax_shr) : eNumMax_shl[6:0];",
                        "assign eNumMax        = eNumMax_shl[6:0];", '分数 LMUL 不右移'),
  ],
}


def run(cmd, cwd):
    return subprocess.run(cmd, cwd=str(cwd), shell=True, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, universal_newlines=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('ut')
    ap.add_argument('--out', default=None)
    ap.add_argument('--ncycles', type=int, default=200000)
    ap.add_argument('--seed', type=int, default=901)
    ap.add_argument('--only', default=None)
    args = ap.parse_args()
    if args.ut not in MUTANTS:
        print(f'未知 UT {args.ut}'); return 2
    root = pathlib.Path(args.out or os.environ.get('MUT_ROOT', '/tmp')) / f'mut_{args.ut}_{os.getpid()}'
    root.mkdir(parents=True, exist_ok=False)
    # 镜像：rtl/ scripts/ verif/ut/<UT>/ verif/ut/VectorCvt_common/（只拷源文件）
    shutil.copytree(REPO / 'rtl', root / 'rtl')
    shutil.copytree(REPO / 'scripts', root / 'scripts')
    (root / 'verif' / 'ut').mkdir(parents=True)
    for d in (args.ut, 'VectorCvt_common'):
        dst = root / 'verif' / 'ut' / d
        dst.mkdir()
        for f in (REPO / 'verif' / 'ut' / d).iterdir():
            if f.is_file() and f.suffix in ('.sv', '.py') or f.name == 'Makefile':
                shutil.copy2(f, dst / f.name)
    utdir = root / 'verif' / 'ut' / args.ut
    only = set(args.only.split(',')) if args.only else None
    missed = 0
    print(f'镜像根 {root}；基准 commit {run("git rev-parse HEAD", REPO).stdout.strip()}')
    for (mid, fname, old, new, desc) in MUTANTS[args.ut]:
        if only and mid not in only:
            continue
        src = REPO / 'rtl' / 'backend' / fname
        dst = root / 'rtl' / 'backend' / fname
        text = src.read_text()
        n = text.count(old)
        if n != 1:
            print(f'{mid} NOT_APPLIED（命中 {n} 处）: {desc}')
            missed += 1
            continue
        dst.write_text(text.replace(old, new))
        for lg in utdir.glob(f'sim_{args.seed}*.log'):
            lg.unlink()
        r = run(f'make run SEED={args.seed} INITREG=0 NCYCLES={args.ncycles}', utdir)
        log = utdir / f'sim_{args.seed}.log'
        body = log.read_text(errors='replace') if log.exists() else ''
        m = re.findall(r'^checks=\d+ errors=(\d+)', body, re.M)
        mo = re.findall(r'^oracle_checks=\d+ oracle_errors=(\d+)', body, re.M)
        err = m[-1] if m else '?'
        oerr = mo[-1] if mo else '-'
        if not body:
            verdict = 'BUILD_FAIL'
            missed += 1
        elif (err not in ('?', '0')) or (oerr not in ('-', '0')):
            # ★判据只认失配计数★：TEST FAILED 也可能只是覆盖门限没够（短跑时），那不算抓到
            verdict = 'CAUGHT'
        else:
            verdict = 'MISSED'
            missed += 1
        print(f'{mid} {verdict:7s} errors={err} oracle_errors={oerr} : {desc}')
        dst.write_text(text)   # 还原镜像
    # 镜像与工作树逐字节一致（变异全部还原）
    for (mid, fname, *_ ) in MUTANTS[args.ut]:
        a = (REPO / 'rtl' / 'backend' / fname).read_bytes()
        b = (root / 'rtl' / 'backend' / fname).read_bytes()
        if a != b:
            print(f'!! 镜像 {fname} 未还原'); missed += 1
    print(f'MISSED_OR_NOT_APPLIED={missed}')
    return missed


if __name__ == '__main__':
    sys.exit(main())
