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
]

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

    out_gonly=[p for p in gonly if p[0]=='output']
    recon=[p for p in out_gonly if p[2] in passthru and passthru[p[2]] in gset]
    tied_out=[p for p in out_gonly if p[2] not in passthru]
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
    lines.append(f"  {amod} u_xs (")
    conns=[f"    .{n}({n})" for d,w,n in a]
    lines.append(",\n".join(conns))
    lines.append("  );")
    # 忠实重建 golden 纯透传 (e.g. ready 背压)
    for d,w,n in recon:
        lines.append(f"  assign {n} = {passthru[n]};  // golden passthrough reconstructed (functional)")
    # 其余 golden-only output 接 '0(rewrite 真省略的 debug/perf/metadata)
    for d,w,n in tied_out:
        lines.append(f"  assign {n} = '0;  // rewrite-omitted (nonfunc)")
    lines.append(f"endmodule")
    open(f"{M}_bt.sv","w").write("\n".join(lines)+"\n")
    print(f"{M}_bt.sv: golden={len(g)} adapter={len(a)} golden-only={len(gonly)} reconstructed={len(recon)} tied(nonfunc)={len(tied_out)}")

json.dump(nonfunc, open("nonfunc_ports.json","w"), indent=1)
print("wrote nonfunc_ports.json")
