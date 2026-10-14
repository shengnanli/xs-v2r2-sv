#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_audit_ram_memory_model.py —— audit_ram_memory_model.py 的正反例自测（进 gate_all）。

审的是「判据本身有没有分辨力」：每一条判据都要有一个**本该通过的正例**和至少一个
**本该拦下的负例**。全部在临时目录里用合成文件跑，不读 golden、不读仓库 RTL、不跑 FM。

覆盖（2026-09-27 扩展项 + 原有形态 A）：
  M1  多写口模板逐字相等（正）/ 多一条 assign（负）/ 写口编号不连续（负）/ 宏定义头不同（负）
  M1  多读口 nRmW（codex 0230）：1R1W 不变 / 3R2W / 8R6W（正）；读口编号不连续 / 读口错接地址 /
      读 assign 乱序 / 少一条读 assign / 读口夹在写口之后 / 多读口外加逻辑 / 写序颠倒（负）
  M2  generate-for 倍数（正）/ 两侧展开数不等（负）/ 常量连接签名不等（负）/ 循环上界非静态（负）
  M3  形态 A 环形指针归纳（正）/ 形态 B 输入偏移 + 契约（正）/ 无契约（负 MANUAL）/
      契约不充分（负 FAIL）/ V 位宽让 F=0 支路越界（负 FAIL）/ 地址是寄存器（负 MANUAL）/
      地址表达式混入内部信号（负 MANUAL）
退出码 0 = 全部符合预期；1 = 有判据失去分辨力。
"""
import contextlib
import io
import pathlib
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import audit_ram_memory_model as A  # noqa: E402

HDR = "// synthetic firtool header (test fixture)\n`ifndef RANDOM\n  `define RANDOM $random\n`endif\n\n"


def leaf(design, aw, dw, depth, nw, extra='', header=HDR, wports=None, nr=1, rports=None,
         rassign=None):
    wports = wports if wports is not None else list(range(nw))
    rports = rports if rports is not None else list(range(nr))
    ports = []
    for k in rports:
        ports += [f'  input  [{aw-1}:0] R{k}_addr,', f'  input R{k}_en,', f'  input R{k}_clk,',
                  f'  output [{dw-1}:0] R{k}_data,']
    for i in wports:
        ports += [f'  input [{aw-1}:0] W{i}_addr,', f'  input W{i}_en,', f'  input W{i}_clk,',
                  f'  input [{dw-1}:0] W{i}_data,']
    ports[-1] = ports[-1].rstrip(',')
    w = '\n'.join(f"    if (W{i}_en & 1'h1)\n      Memory[W{i}_addr] <= W{i}_data;" for i in wports)
    return (header + f'module {design}(\n' + '\n'.join(ports) + '\n);\n'
            f'  reg [{dw-1}:0] Memory[0:{depth-1}];\n  always @(posedge W0_clk) begin\n{w}\n  end\n'
            '  `ifdef ENABLE_INITIAL_MEM_\n    reg [31:0] _RANDOM_MEM;\n    initial begin\n'
            '      `INIT_RANDOM_PROLOG_\n      `ifdef RANDOMIZE_MEM_INIT\n'
            f"        for (logic [{aw-1}:0] i = {aw}'h0; i < {aw}'h{depth:X}; i += {aw}'h1) begin\n"
            f'          _RANDOM_MEM = `RANDOM;\n          Memory[i] = _RANDOM_MEM[{dw-1}:0];\n'
            '        end\n      `endif\n    end\n  `endif\n'
            + (rassign if rassign is not None else
               ''.join(f"  assign R{k}_data = R{k}_en ? Memory[R{k}_addr] : {dw}'bx;\n" for k in rports))
            + f'{extra}endmodule\n')


# ---- 形态 B 的父级：depth 6 = 2 * K(3)，V 2 位（F=0 时最大 3 < 6）--------------------
REF_B = '''module ParentB(
  input        clock,
  input  [1:0] io_c_value,
  input        io_c_flag,
  input  [1:0] io_u_0_value,
  input        io_u_0_flag,
  input  [1:0] io_u_1_value,
  input        io_u_1_flag,
  input        wv_0,
  input        wv_1,
  output [3:0] d0, output [3:0] d1, output [1:0] t
);
  wire [2:0] _rs_T = 3'({1'h0, io_c_value} + (io_c_flag ? 3'h3 : 3'h0));
  wire [2:0] _ws_T_0 = 3'({1'h0, io_u_0_value} + (io_u_0_flag ? 3'h3 : 3'h0));
  wire [2:0] _ws_T_1 = 3'({1'h0, io_u_1_value} + (io_u_1_flag ? 3'h3 : 3'h0));
  bank_6x4 bank_0_ext (.R0_addr(_rs_T), .R0_en(1'h1), .R0_clk(clock), .R0_data(d0),
                       .W0_addr(_ws_T_0), .W0_en(wv_0), .W0_clk(clock), .W0_data(4'h0));
  bank_6x4 bank_1_ext (.R0_addr(_rs_T), .R0_en(1'h1), .R0_clk(clock), .R0_data(d1),
                       .W0_addr(_ws_T_1), .W0_en(wv_1), .W0_clk(clock), .W0_data(4'h0));
  tags_6x2 tags_ext (.R0_addr(_rs_T), .R0_en(1'h1), .R0_clk(clock), .R0_data(t),
                     .W0_addr(_ws_T_1), .W0_en(wv_1), .W0_clk(clock), .W0_data(2'h1),
                     .W1_addr(_ws_T_0), .W1_en(wv_0), .W1_clk(clock), .W1_data(2'h0));
endmodule
'''

IMPL_B_T = '''package pb_pkg;
  localparam int unsigned N = {N};
  localparam int unsigned K = 3;
  localparam int unsigned SLOT_W = 3;
  localparam int unsigned VW = {VW};
  typedef struct packed {{
    logic          flag;
    logic [VW-1:0] value;
  }} upd_t;
  function automatic logic [SLOT_W-1:0] slot_of(input logic flag, input logic [VW-1:0] value);
    return {{1'b0, value}} + (flag ? SLOT_W'(K) : SLOT_W'(0));
  endfunction
endpackage

module xs_ParentB_core import pb_pkg::*; (
  input  logic          clock,
  input  logic          c_flag,
  input  logic [VW-1:0] c_value,
  input  upd_t [1:0]    u,
  input  logic [1:0]    wv,
  output logic [1:0][3:0] d, output logic [1:0] t
);
  {RS}
  logic [1:0][SLOT_W-1:0] ws;
  always_comb for (int k = 0; k < 2; k++) ws[k] = slot_of(u[k].flag, u[k].value);
  for (genvar k = 0; k < N; k++) begin : g_bank
    bank_6x4 bank_ext (.R0_addr(rs), .R0_en(1'b1), .R0_clk(clock), .R0_data(d[k]),
                       .W0_addr(ws[k]), .W0_en(wv[k]), .W0_clk(clock), .W0_data(4'h0));
  end
  tags_6x2 tags_ext (.R0_addr(rs), .R0_en(1'b1), .R0_clk(clock), .R0_data(t),
                     .W0_addr(ws[1]), .W0_en(wv[1]), .W0_clk(clock), .W0_data({T0}),
                     .W1_addr(ws[0]), .W1_en(wv[0]), .W1_clk(clock), .W1_data(2'd0));
endmodule
'''


def impl_b(N='2', VW='2', RS='wire [SLOT_W-1:0] rs = slot_of(c_flag, c_value);', T0="2'd1"):
    return IMPL_B_T.format(N=N, VW=VW, RS=RS, T0=T0)


# ---- 形态 A 的父级（环形指针，深度 6 / 地址 3 位）----------------------------------
REF_A = '''module ParentA(input clock, input reset, input en, output [3:0] q);
  reg [2:0] ptr;
  always @(posedge clock) begin
    if (reset) ptr <= 3'h0;
    else if (en) begin
      if (ptr == 3'h5) ptr <= 3'h0;
      else ptr <= 3'(ptr + 3'h1);
    end
  end
  bank_6x4 ram_ext (.R0_addr(ptr), .R0_en(1'h1), .R0_clk(clock), .R0_data(q),
                    .W0_addr(ptr), .W0_en(en), .W0_clk(clock), .W0_data(4'h0));
endmodule
'''
IMPL_A = '''module xs_ParentA_core(input clock, input reset, input en, output [3:0] q);
  localparam int DEPTH = 6;
  localparam int PW = 3;
  function automatic logic [PW-1:0] nxt(input logic [PW-1:0] p);
    return (p == PW'(DEPTH-1)) ? '0 : p + 1'b1;
  endfunction
  logic [PW-1:0] ptr;
  always_ff @(posedge clock) if (reset) ptr <= '0; else if (en) ptr <= nxt(ptr);
  bank_6x4 mem_ext (.R0_addr(ptr), .R0_en(1'b1), .R0_clk(clock), .R0_data(q),
                    .W0_addr(ptr), .W0_en(en), .W0_clk(clock), .W0_data(4'h0));
endmodule
'''


def run(design, gold_files, ref, impl, contract=None):
    with tempfile.TemporaryDirectory() as td:
        g = pathlib.Path(td) / 'golden'
        g.mkdir()
        # 家族参照件：header 与本组一致的最小单写口叶子
        (g / A.FAMILY_HEADER_REF).write_text(leaf('ram_40x47', 6, 47, 40, 1))
        for n, t in gold_files.items():
            (g / n).write_text(t)
        (pathlib.Path(td) / 'ref.sv').write_text(ref)
        (pathlib.Path(td) / 'impl.sv').write_text(impl)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = A.audit(design, str(g), str(pathlib.Path(td) / 'ref.sv'),
                         str(pathlib.Path(td) / 'impl.sv'), contract)
        return rc, buf.getvalue()


def main():
    bank = leaf('bank_6x4', 3, 4, 6, 1)
    tags = leaf('tags_6x2', 3, 2, 6, 2)
    G = {'bank_6x4.sv': bank, 'tags_6x2.sv': tags}
    C = 'value<3'
    cases = [
        # (名字, 期望 rc, 输出必含, design, golden 文件, ref, impl, contract)
        ('P 多写口 M1 + 形态B M3', 0, 'M3 PASS_INPUT_CONTRACT[impl]', 'tags_6x2', G, REF_B, impl_b(), C),
        ('P generate 倍数 M2', 0, 'M2 PASS: 两侧展开后各 2 个例化', 'bank_6x4', G, REF_B, impl_b(), C),
        ('P 形态A 环形指针', 0, 'M3 PASS[impl]', 'bank_6x4', G, REF_A, IMPL_A, None),
        ('N M1 多一条 assign', 1, 'M1 FAIL', 'bank_6x4',
         {'bank_6x4.sv': leaf('bank_6x4', 3, 4, 6, 1, extra='  assign R0_data[0] = 1;\n'), 'tags_6x2.sv': tags},
         REF_B, impl_b(), C),
        ('N M1 写口编号不连续', 1, 'M1 FAIL: 写口编号', 'tags_6x2',
         {'bank_6x4.sv': bank, 'tags_6x2.sv': leaf('tags_6x2', 3, 2, 6, 2, wports=[0, 2])},
         REF_B, impl_b(), C),
        ('N M1 宏定义头不同', 1, '宏定义头与家族参照件不逐字节相同', 'bank_6x4',
         {'bank_6x4.sv': leaf('bank_6x4', 3, 4, 6, 1, header=HDR + '`define EXTRA 1\n'), 'tags_6x2.sv': tags},
         REF_B, impl_b(), C),
        ('N M2 展开数不等', 1, 'M2 FAIL: 展开后实例数不等 —— ref 2 个 / impl 3 个', 'bank_6x4',
         G, REF_B, impl_b(N='3'), C),
        ('N M2 常量连接签名不等', 1, 'M2 FAIL: 两侧「每实例常量连接签名」多重集不等', 'tags_6x2',
         G, REF_B, impl_b(T0="2'd2"), C),
        ('N M2 循环上界非静态', 1, 'M2 MANUAL', 'bank_6x4', G, REF_B, impl_b(N='wv'), C),
        ('N M3 无契约', 1, '须在 parent 对照表第 4 列写明接口契约', 'bank_6x4', G, REF_B, impl_b(), None),
        ('N M3 契约不充分', 1, 'M3 FAIL[ref]: 契约 value<4', 'bank_6x4', G, REF_B, impl_b(), 'value<4'),
        ('N M3 V 位宽越界 F=0', 1, 'M3 FAIL[impl]: F=0 时 V[2:0] 可达 7 >= depth 6', 'bank_6x4',
         G, REF_B, impl_b(VW='3'), C),
        ('N M3 地址是寄存器', 1, '是寄存器，不是输入的纯函数', 'bank_6x4', G, REF_B,
         impl_b(RS='logic [SLOT_W-1:0] rs; always_ff @(posedge clock) rs <= slot_of(c_flag, c_value);'), C),
        ('N M3 混入内部信号', 1, '既不是环形指针也不是', 'bank_6x4', G, REF_B,
         impl_b(RS='wire [SLOT_W-1:0] rs = slot_of(c_flag, c_value) + wv[0];'), C),
        ('N M3 形态A 回卷常量错', 1, 'M3 MANUAL[impl]', 'bank_6x4', G, REF_A,
         IMPL_A.replace('localparam int DEPTH = 6;', 'localparam int DEPTH = 7;'), None),
    ]
    bad = 0
    # ---- M1 多读口（codex 0230 问题 1：nRmW 精确模板）—— 只跑 M1，不需要 parent ----
    def ra(nr, dw, f):
        return ''.join(f"  assign R{k}_data = R{k}_en ? Memory[{f(k)}] : {dw}'bx;\n" for k in range(nr))
    m1_cases = [
        # (名字, 期望 ok, 输出必含, 文件正文)
        ('P M1 1R1W 原模板不变', True, '1 个组合读 assign', leaf('m_6x4', 3, 4, 6, 1)),
        ('P M1 3R2W 多读多写', True, '3 个组合读 assign（R0..R2）', leaf('m_6x4', 3, 4, 6, 2, nr=3)),
        ('P M1 8R6W（dt_pcTransType 形状）', True, '8 个组合读 assign（R0..R7）',
         leaf('m_6x4', 8, 2, 160, 6, nr=8)),
        ('N M1 读口编号不连续', False, 'M1 FAIL: 读口编号', leaf('m_6x4', 3, 4, 6, 2, rports=[0, 2])),
        ('N M1 读口错接地址', False, 'M1 FAIL: 正文与 firtool',
         leaf('m_6x4', 3, 4, 6, 2, nr=3, rassign=ra(3, 4, lambda k: 'R0_addr' if k == 2 else f'R{k}_addr'))),
        ('N M1 读 assign 乱序', False, 'M1 FAIL: 正文与 firtool',
         leaf('m_6x4', 3, 4, 6, 2, nr=2,
              rassign="  assign R1_data = R1_en ? Memory[R1_addr] : 4'bx;\n"
                      "  assign R0_data = R0_en ? Memory[R0_addr] : 4'bx;\n")),
        ('N M1 少一条读 assign', False, 'M1 FAIL: 正文与 firtool',
         leaf('m_6x4', 3, 4, 6, 2, nr=3, rassign=ra(2, 4, lambda k: f'R{k}_addr'))),
        ('N M1 读口夹在写口之后', False, 'M1 FAIL: 正文与 firtool',
         leaf('m_6x4', 3, 4, 6, 1, nr=2).replace(
             "  input  [2:0] R1_addr,\n  input R1_en,\n  input R1_clk,\n  output [3:0] R1_data,\n", '').replace(
             '  input [3:0] W0_data\n',
             '  input [3:0] W0_data,\n  input  [2:0] R1_addr,\n  input R1_en,\n  input R1_clk,\n'
             '  output [3:0] R1_data\n')),
        ('N M1 多读口外加逻辑', False, 'M1 FAIL: 正文与 firtool',
         leaf('m_6x4', 3, 4, 6, 2, nr=3, extra="  assign R2_data[0] = 1'b0;\n")),
        ('N M1 写口后赢被改成先赢（写序颠倒）', False, 'M1 FAIL: 正文与 firtool',
         leaf('m_6x4', 3, 4, 6, 2, nr=2, wports=[1, 0])),
    ]
    with tempfile.TemporaryDirectory() as td:
        for name, exp_ok, must, text in m1_cases:
            f = pathlib.Path(td) / 'm_6x4.sv'
            f.write_text(text)
            ok1, msg1, _ = A.m1_memory_only(f, 'm_6x4')
            good = (ok1 == exp_ok) and (must in msg1)
            print(f'{"PASS" if good else "★FAIL"}  {name}  (ok={ok1} 期望 {exp_ok}; 须含 {must!r})')
            if not good:
                bad += 1
                print('      ' + msg1[:400])
    for name, exp_rc, must, design, gf, ref, impl, contract in cases:
        rc, out = run(design, gf, ref, impl, contract)
        ok = (rc == exp_rc) and (must in out)
        print(f'{"PASS" if ok else "★FAIL"}  {name}  (rc={rc} 期望 {exp_rc}; 须含 {must!r})')
        if not ok:
            bad += 1
            print('\n'.join('      ' + ln for ln in out.splitlines()[-8:]))
    print(f'=== test_audit_ram_memory_model: {len(cases) + len(m1_cases) - bad}/{len(cases) + len(m1_cases)} ===')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
