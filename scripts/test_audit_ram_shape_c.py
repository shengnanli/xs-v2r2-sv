#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_audit_ram_shape_c.py —— M3 形态 C（codex 0232）的正负测（进 gate_all）。

全部在临时目录里用合成文件跑：一个 depth 6 / addr 3 位的 1R1W RAM 叶子 mem_6x2，一个「G1」子模块
PtrA（两个 3 位指针寄存器，带 `x>=6 ? x-6 : x` 回卷），ref 父级 ParentC（firtool 风格，写地址经
`_G[io_sel]` 拼接选择），impl 父级（薄 wrapper + 可读核，写地址经「默认 + 逐项覆盖」选择）。
形态 C 表由用例注入（不读、不改仓库里的 SHAPE_C）。

覆盖（codex 0231 所列 6 项 + 0232 追加 2 项 + 实例/闭包核对）：
  P1 同源子模块正例（无条件 PASS_C，redirect 支路对任意 3 位输入都回卷进 [0,5]）
  N1 子模块两侧/写死 sha 不同                          -> MANUAL
  N2 子模块端口由组合逻辑（输入直通）驱动               -> MANUAL（追不到寄存器）
  N3 选择的某个候选分支越界（一个候选是外部输入）        -> FAIL
  N4 契约缺失：外部 idx 未归一化直接写进地址寄存器      -> FAIL（给出反例，不偷偷加契约）
  N5 递归超限：子模块里还有子实例                        -> MANUAL
  N6 (0232-a) reset 合法但某条 next-state 支路可产生 6    -> FAIL
  N7 (0232-b) 选择候选全合法但下标有未覆盖的 OOB/X 分支   -> MANUAL（ref 侧拼接 3 元素/2 位下标）
  N8 (0232-b) impl 可读核缺默认赋值（未覆盖的 default）   -> MANUAL
  N9 impl 侧同名单侧 wrapper（PtrA 定义在 impl 文件里）    -> MANUAL
  N10 子实例带参数覆盖                                    -> MANUAL
  N11 子模块里有 reset 之外的未建模语句（case）           -> MANUAL
  N12 闭包核对：RTL_SRCS 里有同名定义                     -> 不过
  N13 闭包核对：子模块不在 GOLDEN_CLOSURE_SHARED          -> 不过
  P2 闭包核对正例
退出码 0 = 全部符合预期。
"""
import contextlib
import hashlib
import io
import pathlib
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import audit_ram_memory_model as A  # noqa: E402
from test_audit_ram_memory_model import leaf  # noqa: E402

PTRA = '''module PtrA(
  input        clock,
  input        reset,
  input        io_inc,
  input        io_redir,
  input  [2:0] io_idx,
  output [2:0] io_out_0_value,
  output [2:0] io_out_1_value
);
  reg  [2:0] p0;
  reg  [2:0] p1;
  wire [3:0] _s0 = 4'({1'h0, p0} + {3'h0, io_inc});
  wire [4:0] _d0 = 5'({1'h0, _s0} - 5'h6);
  wire       _w0 = $signed(_d0) > -5'sh1;
  wire [3:0] _r = {1'h0, io_idx};
  wire [4:0] _dr = 5'({1'h0, _r} - 5'h6);
  wire       _wr = $signed(_dr) > -5'sh1;
  wire [3:0] _s1 = 4'({1'h0, p1} + 4'h1);
  wire [4:0] _d1 = 5'({1'h0, _s1} - 5'h6);
  wire       _w1 = $signed(_d1) > -5'sh1;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      p0 <= 3'h0;
      p1 <= 3'h1;
    end
    else if (io_redir) begin
      p0 <= @@P0REDIR@@;
      p1 <= _w1 ? _d1[2:0] : _s1[2:0];
    end
    else begin
      p0 <= _w0 ? _d0[2:0] : _s0[2:0];@@EXTRA@@
    end
  end
  `ifdef ENABLE_INITIAL_REG_
    initial begin
      p0 = 3'h7;
    end
  `endif // ENABLE_INITIAL_REG_
  assign io_out_0_value = @@OUT0@@;
  assign io_out_1_value = p1;@@SUB@@
endmodule
'''


def ptra(p0redir='_wr ? _dr[2:0] : io_idx', out0='p0', extra='', sub=''):
    return (PTRA.replace('@@P0REDIR@@', p0redir).replace('@@OUT0@@', out0)
            .replace('@@EXTRA@@', extra).replace('@@SUB@@', sub))


REF = '''module ParentC(
  input        clock,
  input        reset,
  input        io_inc,
  input        io_redir,
  input  [2:0] io_idx,
  input  [@@SW@@:0] io_sel,
  output [1:0] io_q
);
  wire [2:0] a0;
  wire [2:0] a1;
  wire [@@GN@@:0][2:0] _G = @@G@@;
  wire [2:0] pick = _G[io_sel];
  PtrA ptr (
    .clock          (clock),
    .reset          (reset),
    .io_inc         (io_inc),
    .io_redir       (io_redir),
    .io_idx         (io_idx),
    .io_out_0_value (a0),
    .io_out_1_value (a1)
  );
  mem_6x2 mem_ext (
    .R0_addr (a0),
    .R0_en   (1'h1),
    .R0_clk  (clock),
    .R0_data (io_q),
    .W0_addr (pick),
    .W0_en   (io_inc),
    .W0_clk  (clock),
    .W0_data (2'h0)
  );
endmodule
'''


def ref(g='{{a1}, {a0}}', gn='1', sw='0'):
    return REF.replace('@@G@@', g).replace('@@GN@@', gn).replace('@@SW@@', sw)


IMPL = '''package pc_pkg;
  localparam int N  = 2;
  localparam int PW = 3;
endpackage

module xs_ParentC_core
  import pc_pkg::*;
(
  input  logic          io_sel,
  input  logic [PW-1:0] a0,
  input  logic [PW-1:0] a1,
  output logic [PW-1:0] pick
);
  logic [PW-1:0] src [N];
  logic [PW-1:0] arr [N];
  logic          sel [N];
  always_comb begin
    src[0] = a0;
    src[1] = @@SRC1@@;
  end
  always_comb begin
    for (int i = 0; i < N; i++) sel[i] = io_sel;
    for (int i = 0; i < N; i++) begin
@@DEFAULT@@      for (int k = 0; k < N; k++)
        if (sel[i] == 1'(k)) arr[i] = src[k];
    end
  end
  assign pick = arr[1];
endmodule
@@LOCALPTR@@
module ParentC(
  input        clock,
  input        reset,
  input        io_inc,
  input        io_redir,
  input  [2:0] io_idx,
  input        io_sel,
  output [1:0] io_q
);
  logic [2:0] n_a0;
  logic [2:0] n_a1;
  logic [2:0] n_pick;
  xs_ParentC_core u_core (
    .io_sel (io_sel),
    .a0     (n_a0),
    .a1     (n_a1),
    .pick   (n_pick)
  );
  PtrA @@PARAM@@ptr (
    .clock          (clock),
    .reset          (reset),
    .io_inc         (io_inc),
    .io_redir       (io_redir),
    .io_idx         (io_idx),
    .io_out_0_value (n_a0),
    .io_out_1_value (n_a1)
  );
  mem_6x2 mem_ext (
    .R0_addr (n_a0),
    .R0_en   (1'h1),
    .R0_clk  (clock),
    .R0_data (io_q),
    .W0_addr (n_pick),
    .W0_en   (io_inc),
    .W0_clk  (clock),
    .W0_data (2'h0)
  );
endmodule
'''


def impl(src1='a1', default='      arr[i] = src[0];\n', localptr='', param=''):
    return (IMPL.replace('@@SRC1@@', src1).replace('@@DEFAULT@@', default)
            .replace('@@LOCALPTR@@', localptr).replace('@@PARAM@@', param))


def run(child_txt, ref_txt, impl_txt, sha=None):
    with tempfile.TemporaryDirectory() as td:
        g = pathlib.Path(td) / 'golden'
        g.mkdir()
        (g / A.FAMILY_HEADER_REF).write_text(leaf('ram_40x47', 6, 47, 40, 1))
        (g / 'mem_6x2.sv').write_text(leaf('mem_6x2', 3, 2, 6, 1))
        (g / 'PtrA.sv').write_text(child_txt)
        real = hashlib.sha256(child_txt.encode()).hexdigest()
        tab = {'mem_6x2': {'msg': 'codex_0232', 'parents': ('ParentC',),
                           'children': {'PtrA': sha or real}, 'closure': None}}
        (pathlib.Path(td) / 'ref.sv').write_text(ref_txt)
        (pathlib.Path(td) / 'impl.sv').write_text(impl_txt)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = A.audit('mem_6x2', str(g), str(pathlib.Path(td) / 'ref.sv'),
                         str(pathlib.Path(td) / 'impl.sv'), shape_c=tab)
        A._SC_READ.clear()
        A._SC_STRIP.clear()
        return rc, buf.getvalue()


def closure_case(rtl_defines_ptra, shared_has_ptra):
    with tempfile.TemporaryDirectory() as td:
        r = pathlib.Path(td)
        (r / 'rtl').mkdir()
        (r / 'rtl' / 'P.sv').write_text('module ParentC(); endmodule\n'
                                         + ('module PtrA(); endmodule\n' if rtl_defines_ptra else ''))
        (r / 'Makefile').write_text('RTL_SRCS = $(RTL_DIR)/P.sv\n')
        (r / 'closure.mk').write_text('GOLDEN_CLOSURE_REPLACED = ParentC.sv\nGOLDEN_CLOSURE_SHARED = \\\n  '
                                      + ('PtrA.sv \\\n  ' if shared_has_ptra else '') + 'mem_6x2.sv\n')
        cfg = {'children': {'PtrA': '0' * 64}, 'closure': {'makefile': 'Makefile', 'closure_mk': 'closure.mk'}}
        ok, msg, _ = A.sc_closure_checks(cfg, repo=r)
        A._SC_READ.clear()
        A._SC_STRIP.clear()
        return ok, msg


def main():
    cases = [
        # (名字, 期望 rc, 输出必含, child, ref, impl, sha)
        ('P1 同源子模块正例（无条件）', 0, 'M3 PASS_C[impl]', ptra(), ref(), impl(), None),
        ('N1 写死 sha 与 G1 不同', 1, 'sha256', ptra(), ref(), impl(), 'f' * 64),
        ('N2 子模块端口由输入直通驱动', 1, '追不到任何 3 位寄存器', ptra(out0='io_idx'), ref(), impl(), None),
        ('N3 选择的一个候选越界（外部输入）', 1, 'M3 FAIL[impl]', ptra(), ref(), impl(src1='io_sel_w'), None),
        ('N4 契约缺失：外部 idx 直写指针', 1, 'M3 FAIL: PtrA.p0 路径0', ptra(p0redir='io_idx'), ref(), impl(), None),
        ('N5 递归超限：子模块里还有子实例', 1, '还有子实例', ptra(sub='\n  Leaf u_leaf (.a(p0));'),
         ref(), impl(), None),
        ('N6 reset 合法但 next-state 支路可产生 6', 1, '可产生 6',
         ptra(p0redir="_wr ? 3'h6 : io_idx"), ref(), impl(), None),
        ('N7 ref 选择下标有 OOB/X 分支', 1, '越出声明范围',
         ptra(), ref(g='{{a1}, {a1}, {a0}}', gn='2', sw='1'), impl(), None),
        ('N8 impl 选择缺默认赋值', 1, 'M3 MANUAL[impl]', ptra(), ref(), impl(default=''), None),
        ('N9 impl 侧同名单侧 wrapper', 1, '单侧 wrapper', ptra(), ref(),
         impl(localptr='\nmodule PtrA(input clock, input reset, input io_inc, input io_redir, input [2:0] io_idx,'
                       ' output [2:0] io_out_0_value, output [2:0] io_out_1_value);\n'
                       "  assign io_out_0_value = 3'h0;\n  assign io_out_1_value = 3'h0;\nendmodule\n"), None),
        ('N10 子实例带参数覆盖', 1, '参数覆盖', ptra(), ref(), impl(param='#(.W(3)) '), None),
        ('N11 子模块 always 里有未建模语句', 1, 'M3 MANUAL',
         ptra(extra='\n      case (io_idx) 3\'h0: p1 <= 3\'h0; endcase'), ref(), impl(), None),
    ]
    # N3 需要 impl 里存在一个 3 位外部输入当越界候选
    bad = 0
    for name, exp_rc, must, ch, rf, im, sha in cases:
        if 'io_sel_w' in im:
            im = im.replace('  input  logic          io_sel,', '  input  logic          io_sel,\n'
                            '  input  logic [PW-1:0] io_sel_w,', 1)
            im = im.replace('    .io_sel (io_sel),', '    .io_sel (io_sel),\n    .io_sel_w (io_idx),', 1)
        rc, out = run(ch, rf, im, sha)
        ok = (rc == exp_rc) and (must in out)
        print(f'{"PASS" if ok else "★FAIL"}  {name}  (rc={rc} 期望 {exp_rc}; 须含 {must!r})')
        if not ok:
            bad += 1
            print('\n'.join('      ' + ln[:300] for ln in out.splitlines()[-14:]))
    for name, args, exp_ok, must in [
            ('P2 闭包核对正例', (False, True), True, 'GOLDEN_CLOSURE_SHARED'),
            ('N12 闭包核对：RTL_SRCS 有同名定义', (True, True), False, '单侧 wrapper'),
            ('N13 闭包核对：不在 GOLDEN_CLOSURE_SHARED', (False, False), False, '不在')]:
        okc, msg = closure_case(*args)
        good = okc == exp_ok and must in msg
        print(f'{"PASS" if good else "★FAIL"}  {name}  (ok={okc} 期望 {exp_ok}; 须含 {must!r}) {msg[:120]}')
        bad += 0 if good else 1
    n = len(cases) + 3
    print(f'=== test_audit_ram_shape_c: {n - bad}/{n} ===')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
