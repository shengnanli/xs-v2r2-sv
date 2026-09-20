#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 negtest_bad.sv / negtest_ok.sv —— xs_DelayReg_core 端口契约不变式的★双向★负测台。

两半都从 rtl/common/DelayReg_26.sv 复制而来（同一份字节），区别只有一处：
  negtest_bad.sv  把 i_mask 从 16 位抄成 15 位  -> 不变式**必须**拦下；
  negtest_ok.sv   原样不动（只改模块名）        -> 不变式**必须不**拦。
只做反向那一半是不够的：一个"恒 $fatal"的核会让反向显示 PASS 而毫无判别力。

用法: python3 gen_negtest.py （改了 DelayReg_26 的形状要重跑并提交）
"""
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
SRC = HERE.parent.parent.parent / 'rtl' / 'common' / 'DelayReg_26.sv'

TB = """
module neg_tb;
  bit clock = 0;
  wire o_valid, o_wLine, o_vecNeedSplit;
  wire [63:0] o_addr, o_data, o_highData, o_pc;
  wire [15:0] o_mask, o_offset;
  wire [7:0]  o_eew, o_coreid, o_index;
  wire [9:0]  o_robidx;
  %(MOD)s u_dut (
    .clock(clock), .reset(1'b1), .enable(1'b0),
    .i_valid(1'b0), .i_addr(64'h0), .i_data(64'h0), .i_highData(64'h0),
    .i_mask(%(MASK)s), .i_wLine(1'b0), .i_vecNeedSplit(1'b0), .i_eew(8'h0),
    .i_offset(16'h0), .i_pc(64'h0), .i_robidx(10'h0), .i_coreid(8'h0), .i_index(8'h0),
    .o_valid(o_valid), .o_addr(o_addr), .o_data(o_data), .o_highData(o_highData),
    .o_mask(o_mask), .o_wLine(o_wLine), .o_vecNeedSplit(o_vecNeedSplit), .o_eew(o_eew),
    .o_offset(o_offset), .o_pc(o_pc), .o_robidx(o_robidx), .o_coreid(o_coreid),
    .o_index(o_index)
  );
  initial begin
    #10;
    $display("%(MARK)s");
    $finish;
  end
endmodule
"""

HDR_BAD = """// 负测台[反向 必须拦下]：证明 xs_DelayReg_core 的端口契约不变式真会拦下
// "位宽被静默改小"。下面是 DelayReg_26 薄文件的复制品，唯一改动：
// i_mask 从 golden 的 16 位抄成 15 位（本轮已发生 3 次的事故形态——端口位宽变了、
// 逻辑一行没动、UT 按旧位宽驱动照样全绿，只有 FM 才炸）。
// 期望：PORT_BITS_IN=324 != WIDTH=325，core 在 time 0 $fatal。
// 若跑到 NEGTEST_UNREACHED，说明不变式形同虚设，Makefile 的 negtest 判 FAIL。
// ★这一半单独看是不够的★：一个"恒 $fatal"的核也会让它显示 PASS。
// 正向那一半在 negtest_ok.sv。
// 自动生成：verif/ut/DelayReg/gen_negtest.py —— 勿手改
"""

HDR_OK = """// 负测台[正向 必须不拦]：同一份 DelayReg_26 薄文件**原样不动**，
// 只改模块名。期望：不变式全部成立，core 不 $fatal，跑到 NEGTEST_OK_REACHED。
// 若被拦下，说明这个不变式是"恒报警"的闸——那么 negtest_bad.sv 的 PASS
// 什么也证明不了。
// 自动生成：verif/ut/DelayReg/gen_negtest.py —— 勿手改
"""


def main():
    src = SRC.read_text()
    body = src[src.index('module DelayReg_26('):]

    bad = body.replace('module DelayReg_26(', 'module neg_delayreg_narrow_port(', 1)
    old = '  input  [15:0] i_mask,'
    if old not in bad:
        raise SystemExit('锚点 i_mask 没找到 —— DelayReg_26 的端口表变了，请同步本文件')
    bad = bad.replace(old, '  input  [14:0] i_mask,   // <-- 抄错：golden 是 [15:0]', 1)
    (HERE / 'negtest_bad.sv').write_text(
        HDR_BAD + '\n' + bad.rstrip() + '\n' +
        TB % dict(MOD='neg_delayreg_narrow_port', MASK="15'h0",
                  MARK='NEGTEST_UNREACHED: 不变式没有拦下位宽抄错'))

    ok = body.replace('module DelayReg_26(', 'module neg_delayreg_correct_port(', 1)
    (HERE / 'negtest_ok.sv').write_text(
        HDR_OK + '\n' + ok.rstrip() + '\n' +
        TB % dict(MOD='neg_delayreg_correct_port', MASK="16'h0",
                  MARK='NEGTEST_OK_REACHED: 位宽正确，不变式没有误报'))
    print('wrote negtest_bad.sv / negtest_ok.sv')


if __name__ == '__main__':
    main()
