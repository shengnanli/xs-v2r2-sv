#!/usr/bin/env python3
"""gen_tlbuffer_ad_family.py —— TLBuffer A/D 两通道变体家族的机械派生区生成器。

覆盖 TLBuffer_6 / _8 / _9 / _20 / _22：这 5 个 golden 模块都只是"A 通道插一个
Queue2、D 通道插一个 Queue2"的装配壳，彼此只差**位宽**与**队列型号**。逻辑核
写在 rtl/memblock/xs_TLBuffer_ad_core.sv（手写，本脚本不碰），本脚本只生成：

  rtl/memblock/TLBuffer_<n>.sv    变体薄文件（golden 端口表 + 设参 + 两个队列例化）
  verif/ut/TLBuffer_<n>/tb.sv     双例化逐拍比对 tb（含位宽覆盖闸与反压统计）
  verif/ut/TLBuffer_<n>/Makefile  UT/FM 入口

**所有位宽都从 G1 golden 现读**，不从 G0 继承、不手抄：G0->G1 这一轮改的就是
TL source id 位宽，而"剥掉端口后模块体逐字相同"的机械判据对位宽是瞎的。
队列内 ram_2x<N> 的 N 也一并读出来，作为载荷宽度等式塞给核做 elaborate 自检。

用法: python3 scripts/gen_tlbuffer_ad_family.py [--repo <dir>] [--check]
      --check 只比对不写盘（防止生成物与脚本漂移）。
"""
import argparse
import os
import pathlib
import re
import sys

GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
G0_GOLDEN = os.environ.get('G0_GOLDEN_RTL', '/home/eda/xs-env/G0-canonical/golden-rtl')
VARIANTS = ['TLBuffer_6', 'TLBuffer_8', 'TLBuffer_9', 'TLBuffer_20', 'TLBuffer_22']

PORT_RE = re.compile(
    r'^\s*(input|output|inout)\s+(?:wire\s+)?(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s+)?(\w+)\s*,?\s*$')
INST_RE = re.compile(r'^\s{2}(\w+)\s+(\w+)\s*\(', re.M)
RAM_RE = re.compile(r'^\s+ram_2x(\d+)\s+ram_ext\s*\(', re.M)

A_FIELDS = ['opcode', 'param', 'size', 'source', 'address', 'mask', 'data', 'corrupt']
D_FIELDS = ['opcode', 'param', 'size', 'source', 'sink', 'denied', 'data', 'corrupt']

# 核的 TL 侧端口（与 xs_TLBuffer_ad_core.sv 手写端口表一一对应；user 不过核）
CORE_TL_PORTS = (
    ['auto_in_a_ready', 'auto_in_a_valid']
    + [f'auto_in_a_bits_{f}' for f in A_FIELDS]
    + ['auto_out_a_ready', 'auto_out_a_valid']
    + [f'auto_out_a_bits_{f}' for f in A_FIELDS]
    + ['auto_out_d_ready', 'auto_out_d_valid']
    + [f'auto_out_d_bits_{f}' for f in D_FIELDS]
    + ['auto_in_d_ready', 'auto_in_d_valid']
    + [f'auto_in_d_bits_{f}' for f in D_FIELDS])


def parse_module(path, mod):
    """返回 (ports, body)；ports 为 [(name, dir, width)]，按 golden 端口顺序。"""
    txt = pathlib.Path(path).read_text()
    m = re.search(r'^module\s+%s\s*\((.*?)\n\);\n(.*?)\nendmodule' % re.escape(mod),
                  txt, re.S | re.M)
    if not m:
        raise SystemExit(f'解析失败: {path} 里找不到 module {mod}')
    ports = []
    for line in m.group(1).splitlines():
        pm = PORT_RE.match(line)
        if pm:
            d, hi, lo, nm = pm.groups()
            if hi is not None and int(lo) != 0:
                raise SystemExit(f'{mod}.{nm}: 非 [n:0] 端口，生成器未覆盖')
            ports.append((nm, d, 1 if hi is None else int(hi) + 1))
    return ports, m.group(2)


def decl(width, name):
    return name if width == 1 else f'[{width - 1}:0] {name}'


class Variant:
    """从 G1 golden 现读出来的一个变体的全部事实（G0 仅用于生成迁移说明）。"""

    def __init__(self, name):
        self.name = name
        self.ports, body = parse_module(os.path.join(GOLDEN, name + '.sv'), name)
        self.w = {n: wd for n, _, wd in self.ports}
        insts = INST_RE.findall(body)
        if [i[1] for i in insts] != ['nodeOut_a_q', 'nodeIn_d_q']:
            raise SystemExit(f'{name}: 实例不是预期的 nodeOut_a_q/nodeIn_d_q: {insts}')
        self.qa, self.qd = insts[0][0], insts[1][0]
        self.qa_ports, qa_body = parse_module(os.path.join(GOLDEN, self.qa + '.sv'), self.qa)
        self.qd_ports, qd_body = parse_module(os.path.join(GOLDEN, self.qd + '.sv'), self.qd)
        self.a_ram = int(RAM_RE.search(qa_body).group(1))
        self.d_ram = int(RAM_RE.search(qd_body).group(1))
        # A 通道 user：随变体而异的不透明附带位，不过核，端口直连队列
        self.user = [n[len('auto_in_a_bits_user_'):]
                     for n, _, _ in self.ports if n.startswith('auto_in_a_bits_user_')]
        self.user_w = {u: self.w['auto_in_a_bits_user_' + u] for u in self.user}
        self.g0_src = self._g0_source_width()
        self._crosscheck()

    def _g0_source_width(self):
        p = os.path.join(G0_GOLDEN, self.name + '.sv')
        if not os.path.exists(p):
            return None
        ports, _ = parse_module(p, self.name)
        return dict((n, wd) for n, _, wd in ports).get('auto_in_a_bits_source')

    def _crosscheck(self):
        """golden 内部一致性：同一字段在 in/out、A/D、TLBuffer/Queue2 上必须同宽。"""
        s = self.w['auto_in_a_bits_source']
        for n in ('auto_in_d_bits_source', 'auto_out_a_bits_source', 'auto_out_d_bits_source'):
            if self.w[n] != s:
                raise SystemExit(f'{self.name}: source 位宽在 {n} 上与 A.in 不一致')
        qa = {n: wd for n, _, wd in self.qa_ports}
        qd = {n: wd for n, _, wd in self.qd_ports}
        for f in A_FIELDS:
            if qa['io_enq_bits_' + f] != self.w['auto_in_a_bits_' + f]:
                raise SystemExit(f'{self.name}: A.{f} 与 {self.qa} 端口位宽不一致')
        for f in D_FIELDS:
            if qd['io_enq_bits_' + f] != self.w['auto_in_d_bits_' + f]:
                raise SystemExit(f'{self.name}: D.{f} 与 {self.qd} 端口位宽不一致')
        pay_a = sum(qa['io_enq_bits_' + f] for f in A_FIELDS) + sum(self.user_w.values())
        pay_d = sum(qd['io_enq_bits_' + f] for f in D_FIELDS)
        if pay_a != self.a_ram or pay_d != self.d_ram:
            raise SystemExit(f'{self.name}: 载荷宽度 A={pay_a}(ram {self.a_ram}) '
                             f'D={pay_d}(ram {self.d_ram}) 与 golden ram 不符')

    def params(self):
        """核参数，全部来自 G1 golden 实测。"""
        return [('A_SIZE_W', self.w['auto_in_a_bits_size']),
                ('D_SIZE_W', self.w['auto_in_d_bits_size']),
                ('SOURCE_W', self.w['auto_in_a_bits_source']),
                ('ADDR_W', self.w['auto_in_a_bits_address']),
                ('MASK_W', self.w['auto_in_a_bits_mask']),
                ('DATA_W', self.w['auto_in_a_bits_data']),
                ('D_SINK_W', self.w['auto_in_d_bits_sink']),
                ('A_USER_W', sum(self.user_w.values())),
                ('A_RAM_WIDTH', self.a_ram),
                ('D_RAM_WIDTH', self.d_ram)]

    def user_desc(self):
        if not self.user:
            return '无'
        return ' + '.join(f'{u}({self.user_w[u]}b)' for u in self.user)

    def core_wires(self):
        """核与队列之间的内部线，按 A.enq / A.deq / D.enq / D.deq 分组（不排序，保持可读顺序）。"""
        out = []
        for side in ('enq', 'deq'):
            out.append((f'a_q_{side}_valid', 1))
            out.append((f'a_q_{side}_ready', 1))
            for f in A_FIELDS:
                out.append((f'a_q_{side}_{f}', self.w['auto_in_a_bits_' + f]))
        for side in ('enq', 'deq'):
            out.append((f'd_q_{side}_valid', 1))
            out.append((f'd_q_{side}_ready', 1))
            for f in D_FIELDS:
                out.append((f'd_q_{side}_{f}', self.w['auto_in_d_bits_' + f]))
        return out


def queue_conn(v, which):
    """按 golden 队列自己的端口顺序生成连线；user 字段直连本模块端口（不过核）。"""
    ports = v.qa_ports if which == 'a' else v.qd_ports
    pairs = []
    for nm, _, _ in ports:
        if nm in ('clock', 'reset'):
            tgt = nm
        elif nm.startswith('io_enq_bits_user_'):
            tgt = 'auto_in_a_bits_user_' + nm[len('io_enq_bits_user_'):]
        elif nm.startswith('io_deq_bits_user_'):
            tgt = 'auto_out_a_bits_user_' + nm[len('io_deq_bits_user_'):]
        else:
            side = 'enq' if nm.startswith('io_enq') else 'deq'
            rest = nm[len('io_enq'):] if side == 'enq' else nm[len('io_deq'):]
            field = rest[len('_bits_'):] if rest.startswith('_bits_') else rest[1:]
            tgt = f'{which}_q_{side}_{field}'
        pairs.append((nm, tgt))
    wd = max(len(n) for n, _ in pairs)
    body = [f'    .{n.ljust(wd)} ({t})' for n, t in pairs]
    return ',\n'.join(body)


def gen_rtl(v):
    ps = v.params()
    pw = max(len(k) for k, _ in ps)
    param_txt = ',\n'.join(f'    .{k.ljust(pw)}({val})' for k, val in ps)

    wires = v.core_wires()
    wire_txt = '\n'.join(f'  wire {decl(w, n)};' for n, w in wires)
    all_conn = CORE_TL_PORTS + [n for n, _ in wires]
    ww = max(len(n) for n in all_conn)
    conn_txt = ',\n'.join(f'    .{n.ljust(ww)} ({n})' for n in all_conn)

    port_txt = ',\n'.join(
        f'  {d} {"" if w == 1 else f"[{w - 1}:0] "}{nm}' for nm, d, w in v.ports)

    srcw = v.w['auto_in_a_bits_source']
    g0 = f'{v.g0_src} 位' if v.g0_src else '(G0 缺该模块)'
    hdr = f"""// =============================================================================
// {v.name} —— TileLink A/D 两通道时序缓冲（xs_TLBuffer_ad_core 家族的一个变体）
//
// 本变体的规模与参数（按 G1 golden 现读，不从上一轮继承）：
//   端口 {len(v.ports)} 个；golden 模块体只有两条 Queue2 例化，本层无状态、无组合逻辑。
//   A 通道：size {v.w['auto_in_a_bits_size']}b、source {srcw}b、address {v.w['auto_in_a_bits_address']}b、mask {v.w['auto_in_a_bits_mask']}b、data {v.w['auto_in_a_bits_data']}b，
//           user 附带位 = {v.user_desc()}。
//   D 通道：size {v.w['auto_in_d_bits_size']}b、source {srcw}b、sink {v.w['auto_in_d_bits_sink']}b、data {v.w['auto_in_d_bits_data']}b。
//   队列型号：A = {v.qa}（载荷 {v.a_ram} 位，内含 ram_2x{v.a_ram}）
//             D = {v.qd}（载荷 {v.d_ram} 位，内含 ram_2x{v.d_ram}）
//   两个 Queue2 是 golden 叶子，UT/FM 两侧共用同一份定义，本文件只例化不重写。
//
// 结构：golden 同名端口表 -> 设参例化 xs_TLBuffer_ad_core（核体见 xs_TLBuffer_ad_core.sv）
//   -> 核暴露的 a_q_*/d_q_* 接到上面两个队列。A 通道的 user 位是本变体特有的不透明
//   附带位，缓冲不解释它，直接从端口接到队列，不过核。
//
// G0 -> G1 的唯一改动：source 由 {g0}加宽到 {srcw} 位
//   （auto_in_a / auto_in_d / auto_out_a / auto_out_d 四根 source 端口同改），
//   队列与其 ram 行为模型随之变宽（ram_2x{v.a_ram} / ram_2x{v.d_ram}）；装配结构逐字未变。
//   核里的载荷宽度等式会在 elaborate 时兜住"位宽写回旧值"这类静默错误。
// 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
// =============================================================================
module {v.name}(
{port_txt}
);

  // 核 <-> 队列的内部线（A/D 各一组 enq/deq）
{wire_txt}

  xs_TLBuffer_ad_core #(
{param_txt}
  ) u_core (
{conn_txt}
  );

  // A 通道队列：client -> manager 的请求打一拍
  {v.qa} nodeOut_a_q (
{queue_conn(v, 'a')}
  );

  // D 通道队列：manager -> client 的应答打一拍
  {v.qd} nodeIn_d_q (
{queue_conn(v, 'd')}
  );

endmodule
"""
    return hdr


def gen_tb(v):
    drv, chk, ini, wires, g_conn, i_conn = [], [], [], [], [], []
    for nm, d, w in v.ports:
        if nm in ('clock', 'reset'):
            g_conn.append(f'    .{nm}({nm})')
            i_conn.append(f'    .{nm}({nm})')
            continue
        if d == 'input':
            wires.append(f'  logic {decl(w, nm)};')
            g_conn.append(f'    .{nm}({nm})')
            i_conn.append(f'    .{nm}({nm})')
            ini.append(f"    {nm} = '0;")
            n32 = (w + 31) // 32
            rhs = '$urandom_range(0, 1)' if w == 1 else \
                  "%d'({%s})" % (w, ', '.join(['$urandom'] * n32))
            drv.append(f'    {nm} <= {rhs};')
        else:
            wires.append(f'  wire {decl(w, "g_" + nm)};')
            wires.append(f'  wire {decl(w, "i_" + nm)};')
            g_conn.append(f'    .{nm}(g_{nm})')
            i_conn.append(f'    .{nm}(i_{nm})')
            chk.append(f'    `CHECK({nm})')
    srcw = v.w['auto_in_a_bits_source']
    nl = '\n'
    return f"""// {v.name} 双例化逐拍比对: golden {v.name} vs 可读 {v.name}_xs。
// 本轮 G0->G1 改的是**位宽**（source {v.g0_src}b -> {srcw}b），光"逐拍比输出"不够：
// 若激励永远只用低位，把 source 写窄了也照样全绿。所以除比对外还守三个闸，
// 任一不满足即 FAIL：
//   1. source 取到过 >= 8 的值（A/D 两侧各计数）——G0 的 {v.g0_src} 位 source 根本到不了这个区间；
//   2. source 每一位都被置 1 过（按位或 = 全 1）——最高位没翻过就等于没测最高位；
//   3. 真发生过反压拍（valid & ~ready）——TL 是握手协议，激励不能永远畅通。
// 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
`timescale 1ns/1ps
`define CHECK(SIG) begin \\
  if (!$isunknown(g_``SIG)) begin \\
    checks++; \\
    if (g_``SIG !== i_``SIG) begin \\
      errors++; \\
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \\
    end \\
  end \\
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  // 覆盖统计
  int a_fire = 0, d_fire = 0;              // 握手成功（valid & ready）的事务数
  int a_src_ge8 = 0, d_src_ge8 = 0;        // 其中 source >= 8（G0 的 {v.g0_src} 位到不了的区间）
  int stall_cycles = 0;                    // 任一握手点 valid & ~ready 的拍数
  logic [{srcw - 1}:0] a_src_or = '0, d_src_or = '0;   // source 取值的按位或
  always #5 clock = ~clock;

{nl.join(wires)}

  {v.name} u_g (
{(',' + nl).join(g_conn)}
  );

  {v.name}_xs u_i (
{(',' + nl).join(i_conn)}
  );

  task automatic drive_random_inputs();
{nl.join(drv)}
  endtask

  task automatic check_outputs();
{nl.join(chk)}
  endtask

  // 覆盖统计：在 posedge 之后的稳定点看握手与 source 取值（ready 取 golden 侧）。
  task automatic sample_coverage();
    if (auto_in_a_valid && g_auto_in_a_ready === 1'b1) begin
      a_fire++;
      a_src_or |= auto_in_a_bits_source;
      if (auto_in_a_bits_source >= 8) a_src_ge8++;
    end
    if (auto_out_d_valid && g_auto_out_d_ready === 1'b1) begin
      d_fire++;
      d_src_or |= auto_out_d_bits_source;
      if (auto_out_d_bits_source >= 8) d_src_ge8++;
    end
    if ((auto_in_a_valid  && g_auto_in_a_ready  === 1'b0)
     || (g_auto_out_a_valid === 1'b1 && !auto_out_a_ready)
     || (auto_out_d_valid && g_auto_out_d_ready === 1'b0)
     || (g_auto_in_d_valid  === 1'b1 && !auto_in_d_ready)) stall_cycles++;
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
{nl.join(ini)}
    repeat (8) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
      sample_coverage();
    end
    $display("{v.name} checks=%0d errors=%0d", checks, errors);
    $display("{v.name} coverage: a_fire=%0d a_src_ge8=%0d a_src_or=%0h | d_fire=%0d d_src_ge8=%0d d_src_or=%0h | stall_cycles=%0d",
             a_fire, a_src_ge8, a_src_or, d_fire, d_src_ge8, d_src_or, stall_cycles);
    if (a_src_ge8 == 0 || d_src_ge8 == 0) begin
      $display("COVERAGE HOLE: source 从未取到 >= 8 —— 加宽出来的高位根本没被激励打到");
      $display("TEST FAILED");
      $fatal(1);
    end
    if (!(&a_src_or) || !(&d_src_or)) begin
      $display("COVERAGE HOLE: source 有某些位从未置 1（a=%0h d=%0h, 期望 {srcw} 位全 1）",
               a_src_or, d_src_or);
      $display("TEST FAILED");
      $fatal(1);
    end
    if (stall_cycles == 0) begin
      $display("COVERAGE HOLE: 全程无反压拍 —— 握手路径没被压过");
      $display("TEST FAILED");
      $fatal(1);
    end
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK
"""


def gen_makefile(v):
    deps = sorted(set([v.qa + '.sv', v.qd + '.sv'])) + \
        sorted({f'ram_2x{v.a_ram}.sv', f'ram_2x{v.d_ram}.sv'})
    pad = ' ' * len('RTL_GOLDEN_DEPS = ')
    gdeps = (' \\\n').join([f'{"RTL_GOLDEN_DEPS = " if i == 0 else pad}$(GOLDEN_RTL)/{d}'
                            for i, d in enumerate(deps)])
    return f"""# {v.name} UT/FM 入口（xs_TLBuffer_ad_core 家族变体）
# 重写件只有两个：共享参数化核 + 本变体薄文件。
# Queue2_*/ram_2x* 是 golden 叶子，放 RTL_GOLDEN_DEPS：UT 两侧共用同一份定义
# （不改名、不复制），FM 时与 ref 侧同源 elaborate。
# 自动生成：scripts/gen_tlbuffer_ad_family.py —— 勿手改
MODULE = {v.name}

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_TLBuffer_ad_core.sv \\
           $(RTL_DIR)/memblock/{v.name}.sv
TB_SRCS = tb.sv

{gdeps}

FM_REF_DEPS_{v.name} = {' '.join(deps)}
GOLDEN_SRCS = $(GOLDEN_RTL)/{v.name}.sv
FM_VARIANTS = {v.name}

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
"""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', default=str(pathlib.Path(__file__).resolve().parent.parent))
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    repo = pathlib.Path(a.repo)
    bad = 0
    for name in VARIANTS:
        v = Variant(name)
        out = {repo / 'rtl' / 'memblock' / f'{name}.sv': gen_rtl(v),
               repo / 'verif' / 'ut' / name / 'tb.sv': gen_tb(v),
               repo / 'verif' / 'ut' / name / 'Makefile': gen_makefile(v)}
        for p, txt in out.items():
            if a.check:
                if (p.read_text() if p.exists() else None) != txt:
                    print(f'DRIFT: {p}')
                    bad += 1
            else:
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(txt)
        print(f'{name}: source {v.g0_src}b(G0) -> {v.w["auto_in_a_bits_source"]}b(G1)  '
              f'queues={v.qa}/{v.qd}  ram={v.a_ram}/{v.d_ram}  '
              f'user=[{v.user_desc()}]  ports={len(v.ports)}')
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())
