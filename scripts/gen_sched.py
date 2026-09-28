#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_sched.py —— 生成 Scheduler* 家族的 golden 同名 wrapper（rtl/backend/Scheduler<_N>.sv）

调度器本体几乎全是连线（Dispatch -> 各 IQ、各 IQ -> DataPath），逻辑只有性能事件与访存的
sta/std 成对派遣，写在手写核 rtl/backend/xs_Scheduler_core.sv。本脚本复用 gen_iq.py 的
golden 解析与 fail-closed 连线翻译（Ctx.res）：子模块输入只许接顶层端口/常量/子模块输出/
纯拼接，或下面胶合规则表里的核输出；任何含运算的 golden 表达式不在表里就生成失败。

胶合规则全部从 golden 的寄存器次态与具名线**按形状**识别，形状不符即报错：
  lastCycleIqEnqFireVec_<k> <= <IQ>_io_enq_<e>_ready & <valid>
  lastCycleIqFullVec_<q>    <= <IQ>_io_enq_0_ready
  io_perf_<i>_value_REG_1   （两拍延迟后的性能事件）
  _<IQ>_io_enq_<e>_valid_T_<n> = io_fromDispatch_uops_<k>_valid & ~io_fromDispatch_uops_<k>_bits_isDropAmocasSta
  io_fromDispatch_uops_<k>_ready = <staIQ>_io_enq_<e>_ready & <stdIQ>_io_enq_<e>_ready

用法: python3 scripts/gen_sched.py [--check] [Scheduler ...]
"""
import argparse
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import gen_iq  # noqa: E402

VARIANTS = ['Scheduler', 'Scheduler_1', 'Scheduler_2', 'Scheduler_3']
OUT = gen_iq.OUT


def die(m):
    raise SystemExit(f'gen_sched: {m}')


def gen(v):
    c = gen_iq.Ctx(v)
    regs = dict(c.regs)
    # ---- 性能事件 ----
    fires, fulls = [], []
    for r, _ in c.regs:
        m = re.fullmatch(r'lastCycleIqEnqFireVec_(\d+)', r)
        if m:
            mm = re.fullmatch(r'(\w+) & (\w+)', c.reg_src[r])
            if not mm:
                die(f'{v}: {r} 次态形状不符: {c.reg_src[r]!r}')
            fires.append((int(m.group(1)), mm.group(1), mm.group(2)))
        m = re.fullmatch(r'lastCycleIqFullVec_(\d+)', r)
        if m:
            if not re.fullmatch(r'\w+', c.reg_src[r]):
                die(f'{v}: {r} 次态形状不符')
            fulls.append((int(m.group(1)), c.reg_src[r]))
    fires.sort()
    fulls.sort()
    if [k for k, _, _ in fires] != list(range(len(fires))) or [q for q, _ in fulls] != list(range(len(fulls))):
        die(f'{v}: 性能事件下标不连续')
    perf0_w = regs['io_perf_0_value_REG']
    c.glue['io_perf_0_value_REG_1'] = 'core_perf_enq_fire_cnt'
    for q in range(len(fulls)):
        if regs.get(f'io_perf_{q + 1}_value_REG_1') != 1:
            die(f'{v}: io_perf_{q + 1}_value_REG_1 缺失')
        c.glue[f'io_perf_{q + 1}_value_REG_1'] = f'core_perf_iq_full[{q}]'
    # ---- sta/std 成对派遣 ----
    sta = []
    for n, e in c.wires.items():
        m = re.fullmatch(r'_\w+_io_enq_\d+_valid_T_\d+', n)
        if m:
            mm = re.fullmatch(r'io_fromDispatch_uops_(\d+)_valid & ~io_fromDispatch_uops_\1_bits_isDropAmocasSta', e)
            if not mm:
                die(f'{v}: {n} 形状不符: {e!r}')
            sta.append((int(mm.group(1)), n))
    sta.sort()
    rdy = {}
    for n, e in c.wires.items():
        m = re.fullmatch(r'io_fromDispatch_uops_(\d+)_ready', n)
        if m and n in c.pdir and '&' in e:     # 只有 sta/std 成对口是"两路 ready 相与"，其余是纯连线
            mm = re.fullmatch(r'(\w+) & (\w+)', e)
            if not mm:
                die(f'{v}: {n} 形状不符: {e!r}')
            rdy[int(m.group(1))] = (mm.group(1), mm.group(2))
    if sorted(rdy) != [k for k, _ in sta]:
        die(f'{v}: sta 派遣口 {sorted(rdy)} 与 sta valid 门控口 {[k for k, _ in sta]} 不一致')
    for j, (k, n) in enumerate(sta):
        c.glue[n] = f'core_sta_enq_valid[{j}]'
        c.glue[f'@out:io_fromDispatch_uops_{k}_ready'] = f'core_dispatch_ready[{j}]'
    NE, NQ, NS = len(fires), len(fulls), len(sta)

    L = []
    hdr, _ = gen_iq.module_text(v)
    iqs = [(m, i) for m, i, _ in c.insts]
    L.append(f'// {v}.sv —— 调度器 {v}（golden 同名 wrapper）')
    L.append('// -----------------------------------------------------------------------------')
    L.append('// 逻辑（性能事件、访存 sta/std 成对派遣）在 xs_Scheduler_core.sv；本文件只做连线：')
    L.append('//   golden 端口表 + golden 同名 IssueQueue* 例化（本 lane 已签核件）+ 核接线。')
    L.append('//')
    L.append(f'// 本变体（G1 golden 量得）：IQ {len(iqs)} 个：' + '，'.join(i for _, i in iqs))
    L.append(f'//   入队口 {NE} 个（lastCycleIqEnqFireVec），perf(0) 位宽 {perf0_w}，sta/std 成对派遣口 {NS} 个')
    L.append('//')
    L.append('// 自动生成：scripts/gen_sched.py —— 勿手改')
    L.append('// =============================================================================')
    L.append(f'module {v}(')
    L.append(hdr.rstrip('\n'))
    L.append(');')
    L.append('')
    L.append('  // ' + '=' * 76)
    L.append('  // §A 子模块输出线（名字 = <实例>_<端口>）')
    for wn, w in c.child_out_w.items():
        L.append(f'  logic {gen_iq.sv_w(w)}{wn};')
    L.append('')
    L.append('  // ' + '=' * 76)
    L.append('  // §B 核接口与核输入接线')
    SS = max(NS, 1)
    L.append(f'''  logic             core_enq_ready     [{NE}];
  logic             core_enq_valid     [{NE}];
  logic             core_iq_enq0_ready [{NQ}];
  logic [{perf0_w - 1}:0]       core_perf_enq_fire_cnt;
  logic             core_perf_iq_full  [{NQ}];
  logic             core_sta_dispatch_valid [{SS}];
  logic             core_sta_drop_amocas    [{SS}];
  logic             core_sta_iq_ready       [{SS}];
  logic             core_std_iq_ready       [{SS}];
  logic             core_sta_enq_valid      [{SS}];
  logic             core_dispatch_ready     [{SS}];''')
    for k, a, b in fires:
        L.append(f'  assign core_enq_ready[{k}] = {c.res(a, f"fire{k}.ready")};')
        L.append(f'  assign core_enq_valid[{k}] = {c.res(b, f"fire{k}.valid")};')
    for q, x in fulls:
        L.append(f'  assign core_iq_enq0_ready[{q}] = {c.res(x, f"full{q}")};')
    for j, (k, n) in enumerate(sta):
        a, b = rdy[k]
        L.append(f'  assign core_sta_dispatch_valid[{j}] = io_fromDispatch_uops_{k}_valid;')
        L.append(f'  assign core_sta_drop_amocas[{j}] = io_fromDispatch_uops_{k}_bits_isDropAmocasSta;')
        L.append(f'  assign core_sta_iq_ready[{j}] = {c.res(a, f"sta{j}.ready")};')
        L.append(f'  assign core_std_iq_ready[{j}] = {c.res(b, f"std{j}.ready")};')
    if NS == 0:
        L += ["  assign core_sta_dispatch_valid[0] = 1'h0;", "  assign core_sta_drop_amocas[0] = 1'h0;",
              "  assign core_sta_iq_ready[0] = 1'h0;", "  assign core_std_iq_ready[0] = 1'h0;"]
    L.append('')
    L.append('  // ' + '=' * 76)
    L.append('  // §C 调度核例化')
    L.append(f'''  xs_Scheduler_core #(
    .N_ENQ  ({NE}),
    .N_IQ   ({NQ}),
    .PERF0_W({perf0_w}),
    .N_STA  ({NS})
  ) u_core (
    .clock             (clock),
    .enq_ready         (core_enq_ready),
    .enq_valid         (core_enq_valid),
    .iq_enq0_ready     (core_iq_enq0_ready),
    .perf_enq_fire_cnt (core_perf_enq_fire_cnt),
    .perf_iq_full      (core_perf_iq_full),
    .sta_dispatch_valid(core_sta_dispatch_valid),
    .sta_drop_amocas   (core_sta_drop_amocas),
    .sta_iq_ready      (core_sta_iq_ready),
    .std_iq_ready      (core_std_iq_ready),
    .sta_enq_valid     (core_sta_enq_valid),
    .dispatch_ready    (core_dispatch_ready)
  );
''')
    L.append('  // ' + '=' * 76)
    L.append('  // §D 发射队列例化（golden 同名实例，均为本 lane 已签核件）')
    for mod, inst, conns in c.insts:
        cp = {n: (dd, w) for dd, w, n in c.child_ports[mod]}
        items = []
        for port, e in conns:
            dd, w = cp[port]
            if dd == 'output':
                if not e or e.startswith('/*'):
                    items.append((port, '/* unused */'))
                elif e in c.pdir:
                    items.append((port, e))
                else:
                    items.append((port, f'{inst}_{port}'))
            else:
                items.append((port, c.res(e, f'{inst}.{port}')))
        L.append(f'  {mod} {inst} (')
        wmax = max(len(p) for p, _ in items)
        for j, (p, x) in enumerate(items):
            L.append(f'    .{p.ljust(wmax)} ({x})' + (',' if j < len(items) - 1 else ''))
        L.append('  );')
        L.append('')
    L.append('  // ' + '=' * 76)
    L.append('  // §E 顶层输出')
    driven = set()
    for mod, inst, conns in c.insts:
        cp = {n: dd for dd, _, n in c.child_ports[mod]}
        for p, e in conns:
            if cp[p] == 'output' and e in c.pdir:
                driven.add(e)
    for dd, w, n in c.ports:
        if dd != 'output' or n in driven:
            continue
        if f'@out:{n}' in c.glue:
            L.append(f'  assign {n} = {c.glue["@out:" + n]};')
            continue
        e = c.wires.get(n)
        if e is None:
            die(f'{v}: 输出 {n} 没有驱动')
        L.append(f'  assign {n} = {c.res(e, n)};')
    L.append('endmodule')
    return gen_iq.with_nav('\n'.join(L) + '\n')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('variants', nargs='*')
    a = ap.parse_args()
    bad = 0
    for v in a.variants or VARIANTS:
        txt = gen(v)
        dst = OUT / f'{v}.sv'
        if a.check:
            ok = dst.exists() and dst.read_text() == txt
            print(f'gen_sched --check: {v} ' + ('OK' if ok else '不一致'))
            bad |= not ok
        else:
            dst.write_text(txt)
            print(f'gen_sched: 写 {dst}')
    return int(bad)


if __name__ == '__main__':
    sys.exit(main())
