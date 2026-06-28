#!/usr/bin/env python3
# Backend BT 生成器 —— 勿手改产物
# 为可清晰替换的 3 个重写核(DataPath/BypassNetwork/WbFuBusyTable)生成
# 「全 golden 端口」的 _bt 包装:复用已验证的 _xs 适配器(含真 glue, 暴露 golden 名子集端口),
# 补齐 golden-only 端口(input 悬空, output 接 '0),并记录被补 '0 的 output 名(供 tb 列 nonfunc)。
import re, json, sys, os
GOLD='../../../golden/chisel-rtl'
UT='../../ut'
HERE=os.path.dirname(os.path.abspath(__file__))
os.chdir(HERE)

PORT_RE=re.compile(r'(input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)*(\[[^\]]+\]\s*)?([A-Za-z_][A-Za-z0-9_]*)$')
def parse_block(b):
    o=[]
    for line in b.split('\n'):
        line=line.split('//')[0].strip().rstrip(',')
        mm=PORT_RE.match(line)
        if mm:o.append((mm.group(1),(mm.group(2)or'').strip(),mm.group(3)))
    return o
def mod_ports(path,mod):
    t=open(path).read()
    m=re.search(r'(?m)^module\s+'+re.escape(mod)+r'\b',t)
    p=t.index('(',m.start()); r=t[p+1:]; e=re.search(r'\n\);',r)
    return parse_block(r[:e.start()])

# (golden module, golden file, _xs adapter file, adapter module)
MODS=[
 ('DataPath',     f'{GOLD}/DataPath.sv',     f'{UT}/DataPath/variants_xs.sv',     'DataPath_xs'),
 ('BypassNetwork',f'{GOLD}/BypassNetwork.sv',f'{UT}/BypassNetwork/variants_xs.sv','BypassNetwork_xs'),
 ('WbFuBusyTable',f'{GOLD}/WbFuBusyTable.sv',f'{UT}/WbFuBusyTable/variants_xs.sv','WbFuBusyTable_xs'),
 ('ExuBlock',     f'{GOLD}/ExuBlock.sv',     f'{UT}/ExuBlock/variants_xs.sv',     'ExuBlock_xs'),
 ('ExuBlock_1',   f'{GOLD}/ExuBlock_1.sv',   f'{UT}/ExuBlock_1/variants_xs.sv',   'ExuBlock_1_xs'),
 ('WbDataPath',   f'{GOLD}/WbDataPath.sv',   f'{UT}/WbDataPath/variants_xs.sv',   'WbDataPath_xs'),
 # Int Scheduler: 适配器=改名后的重写 drop-in 核(Scheduler_core_bt, 见上 gen_scheduler_int_subtree)。
 ('Scheduler',    f'{GOLD}/Scheduler.sv',    'Scheduler_core_bt.sv',              'Scheduler_core_bt'),
]

# —— difftest 探针撞名消解(`_bt` 改名机制)。
#   某些重写适配器例化的 DummyDPICWrapper_<N>(纯 write-only difftest sink, 不驱动设计输出)
#   在 WbDataPath 单核 elaboration 里编号 N 与 golden Backend 全闭包里 **同号但不同端口** 的
#   DummyDPICWrapper_<N> 撞名 → VCS 端口未定义错。因这些探针对功能行为无影响, 在 _bt 侧把它们
#   改名 `_<suffix>` 并配套本地空 stub(端口对齐), 与 golden 侧的同号真探针隔离。
#   golden 侧(u_g)仍用其真 DummyDPICWrapper(-y 解析); 重写侧(u_i)用改名 stub。
# M -> (stub_src, [probe module names], suffix)
DPIC_RENAME={
 'WbDataPath': ('../../../rtl/backend/WbDataPath_dpic_stub.sv',
                ['DummyDPICWrapper_24','DummyDPICWrapper_32','DummyDPICWrapper_38','DummyDPICWrapper_44'],
                'wbdp'),
}
def rename_probes(text, probes, suffix):
    for p in probes:
        text=re.sub(r'(?<![A-Za-z0-9_])'+re.escape(p)+r'(?![A-Za-z0-9_])', p+'_'+suffix, text)
    return text

# =============================================================================
# Int Scheduler 子树 `_bt` 改名(照 verif/it/Issue/gen_it.py 的 `_it` 机制, 改 `_bt`)。
#   重写 Int Scheduler 是 golden 同名 drop-in(module Scheduler, 端口为 golden 子集),
#   其下 3 个 IssueQueue + 3 个 Entries wrapper 也是 golden 同名 → BT 双例化撞名。
#   机械地把这 6 个算法模块 + Scheduler 顶层加 `_bt` 后缀(声明+例化引用, 整词匹配),
#   xs_*_core / xs_iq_entry_* / 共享 golden 结构原语(AgeDetector/FuBusyTable*/
#   MultiWakeupQueue/EnqPolicy/UIntCompressor, -y 自动解析)不改名。
#   生成的 Scheduler_core_bt(782 端口=golden 子集)再被 gen_bt.py 的全端口 Scheduler_bt 包装。
# =============================================================================
RTLB='../../../rtl/backend'
SCHED_RENAME=['IssueQueueAluCsrFenceDiv','IssueQueueAluMulBkuBrhJmp',
              'IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v',
              'EntriesAluCsrFenceDiv','EntriesAluMulBkuBrhJmp',
              'EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v']
def apply_sched_bt(text):
    for n in SCHED_RENAME:   # 整词(避免误伤 xs_<name>_core 子串)
        text=re.sub(r'(?<![A-Za-z0-9_])'+re.escape(n)+r'(?![A-Za-z0-9_])', n+'_bt', text)
    return text
def gen_scheduler_int_subtree():
    gen=[]
    # IQ 文件(xs core + golden 同名 wrapper → _bt; 内部 Entries 例化 → _bt)
    for f in ['IssueQueueAluCsrFenceDiv','IssueQueueAluMulBkuBrhJmp',
              'IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v']:
        t=apply_sched_bt(open(f'{RTLB}/{f}.sv').read())
        open(f'{f}_bt.sv','w').write(t); gen.append(f'{f}_bt.sv')
    # Entries wrapper(golden 同名 → _bt)
    for f in ['EntriesAluCsrFenceDiv_wrapper','EntriesAluMulBkuBrhJmp_wrapper',
              'EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v_wrapper']:
        t=apply_sched_bt(open(f'{RTLB}/{f}.sv').read())
        open(f'{f}_bt.sv','w').write(t); gen.append(f'{f}_bt.sv')
    # Scheduler 核(module Scheduler → Scheduler_core_bt; include _bt 连接 svh)
    t=open(f'{RTLB}/Scheduler.sv').read()
    t=t.replace('module Scheduler import scheduler_int_pkg::*;',
                'module Scheduler_core_bt import scheduler_int_pkg::*;')
    t=t.replace('`include "scheduler_int_iq_connect.svh"',
                '`include "scheduler_int_iq_connect_bt.svh"')
    open('Scheduler_core_bt.sv','w').write(t); gen.append('Scheduler_core_bt.sv')
    # 连接 svh(4 个 IQ 例化的模块名 → _bt)
    t=apply_sched_bt(open(f'{RTLB}/scheduler_int_iq_connect.svh').read())
    open('scheduler_int_iq_connect_bt.svh','w').write(t); gen.append('scheduler_int_iq_connect_bt.svh')
    print("Scheduler-int subtree _bt:", " ".join(gen))
gen_scheduler_int_subtree()

nonfunc={}   # module -> list of golden output ports we tie to '0 (rewrite omits)
for M,gpath,apath,amod in MODS:
    g=mod_ports(gpath,M)
    a=mod_ports(apath,amod)
    aset={p[2] for p in a}
    gset={p[2] for p in g}
    gonly=[p for p in g if p[2] not in aset]

    # —— 忠实重建:扫描 golden 模块体里 `assign <out> = <single_port>;` 的纯透传赋值。
    #    若某 golden-only output 在 golden 里就是「= 另一个 golden 端口」的直通(无逻辑),
    #    则在 _bt 包装里按同规则重建(而非接 '0),保功能等价(典型:ready 背压直通)。
    gtxt=open(gpath).read()
    passthru={}   # out_name -> rhs_port_name (both must be wrapper ports)
    for mm in re.finditer(r'(?m)^\s*assign\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([A-Za-z_][A-Za-z0-9_]*)\s*;', gtxt):
        out,rhs=mm.group(1),mm.group(2)
        if out in gset and rhs in gset:
            passthru[out]=rhs

    # —— 常量重建:扫描 golden `assign <out> = <literal>;`(纯位宽常量, e.g. `1'h1`
    #    的 "always ready" 背压, 或 `'0`)。golden 里就是写死的常量,rewrite 省略时
    #    照 golden 同常量重建(而非一律接 '0,避免把 ready=1 误置 0 造成功能分叉)。
    const_re=re.compile(r"^(?:[0-9]+'[hbdHBD][0-9a-fA-FxXzZ_]+|[0-9]+|'[01])$")
    const_recon={}  # out_name -> literal
    for mm in re.finditer(r'(?m)^\s*assign\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]+?)\s*;', gtxt):
        out,rhs=mm.group(1),mm.group(2).strip()
        if out in gset and out not in passthru and const_re.match(rhs):
            const_recon[out]=rhs

    # —— difftest 探针改名: 生成本地改名适配器 + stub, 包装改用改名后的适配器模块。
    inst_amod=amod
    if M in DPIC_RENAME:
        stub_src,probes,suffix=DPIC_RENAME[M]
        inst_amod=f"{amod}_bt"
        atxt=open(apath).read()
        atxt=rename_probes(atxt, probes, suffix)
        # 适配器模块名也改 _bt, 避免与 UT 侧 <M>_xs 在他处共编时撞名
        atxt=re.sub(r'(?<![A-Za-z0-9_])'+re.escape(amod)+r'(?![A-Za-z0-9_])', inst_amod, atxt)
        open(f"{amod}_bt.sv","w").write(atxt)
        stxt=open(stub_src).read()
        stxt=rename_probes(stxt, probes, suffix)
        open(f"{M}_dpic_stub_bt.sv","w").write(stxt)

    out_gonly=[p for p in gonly if p[0]=='output']
    recon=[p for p in out_gonly if p[2] in passthru and passthru[p[2]] in gset]
    crecon=[p for p in out_gonly if p[2] not in passthru and p[2] in const_recon]
    tied_out=[p for p in out_gonly if p[2] not in passthru and p[2] not in const_recon]
    nonfunc[M]=[p[2] for p in tied_out]
    lines=[]
    lines.append(f"// 自动生成: verif/bt/Backend/gen_bt.py —— 勿手改")
    lines.append(f"// {M}_bt: 全 golden 端口 BT 包装, 例化已验证的 {amod}(暴露 golden 名子集 + 真重写 glue),")
    lines.append(f"//   golden-only input 悬空 / golden-only output 接 '0(rewrite 省略的透传/元数据端口)。")
    lines.append(f"//   被接 '0 的 output 列入 tb nonfunc 名单, 打印不计 PASS(照 Frontend BT/README §4)。")
    lines.append(f"module {M}_bt(")
    decl=[]
    for d,w,n in g:
        decl.append(f"  {d} {w+' ' if w else ''}{n}")
    lines.append(",\n".join(decl))
    lines.append(");")
    # connect adapter by name for the ports it has; tie golden-only outputs to 0
    lines.append(f"  {inst_amod} u_xs (")
    conns=[f"    .{n}({n})" for d,w,n in a]
    lines.append(",\n".join(conns))
    lines.append("  );")
    # 忠实重建 golden 纯透传 (e.g. ready 背压)
    for d,w,n in recon:
        lines.append(f"  assign {n} = {passthru[n]};  // golden passthrough reconstructed (functional)")
    # 忠实重建 golden 写死常量 (e.g. always-ready=1'h1)
    for d,w,n in crecon:
        lines.append(f"  assign {n} = {const_recon[n]};  // golden constant reconstructed (functional)")
    # 其余 golden-only output 接 '0(rewrite 真省略的 debug/perf/metadata)
    for d,w,n in tied_out:
        lines.append(f"  assign {n} = '0;  // rewrite-omitted (nonfunc)")
    lines.append(f"endmodule")
    open(f"{M}_bt.sv","w").write("\n".join(lines)+"\n")
    print(f"{M}_bt.sv: golden={len(g)} adapter={len(a)} golden-only={len(gonly)} passthru={len(recon)} const={len(crecon)} tied(nonfunc)={len(tied_out)}")

json.dump(nonfunc, open("nonfunc_ports.json","w"), indent=1)
print("wrote nonfunc_ports.json")
