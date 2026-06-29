#!/usr/bin/env python3
# MemBlock BT 生成器 —— 勿手改产物
# ----------------------------------------------------------------------------
# 为 MemBlock 子系统里「能干净双例化、且重写核功能完整」的子模块生成
# 「全 golden 端口」的 _bt 包装:复用已验证的 <M>_xs 适配器(含真重写 glue +
# xs_<M>_core),补齐 golden-only 端口——
#   golden-only input  : 悬空(适配器不消费, 重写核确实不建模这些 debug/uop-metadata 入口)
#   golden-only output : 先扫 golden 模块体 `assign out = port;` 纯透传, 能机械重建的按同规则
#                        重建(保功能等价); 其余接 '0 并列入 nonfunc 名单(打印不计 PASS)。
# 仅对「golden-only output 全部可重建或为 0」的子模块生成包装(clean swap set), 其余子模块
# 保留 golden(详见 README §覆盖范围)。
# ----------------------------------------------------------------------------
import re, json, os
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
# 只列 clean swap set:适配器端口 ⊆ golden 端口, 且 golden-only output 可重建/为空。
MODS=[
 ('DCacheWrapper', f'{GOLD}/DCacheWrapper.sv', f'{UT}/DCacheWrapper/variants_xs.sv', 'DCacheWrapper_xs'),
 ('Uncache',       f'{GOLD}/Uncache.sv',       f'{UT}/Uncache/variants_xs.sv',       'Uncache_xs'),
 ('L2TLBWrapper',  f'{GOLD}/L2TLBWrapper.sv',  f'{UT}/L2TLBWrapper/variants_xs.sv',  'L2TLBWrapper_xs'),
 ('Sbuffer',       f'{GOLD}/Sbuffer.sv',       f'{UT}/Sbuffer/variants_xs.sv',       'Sbuffer_xs'),
 ('TLBNonBlock',   f'{GOLD}/TLBNonBlock.sv',   f'{UT}/TLBNonBlock/variants_xs.sv',   'TLBNonBlock_xs'),
]

nonfunc={}
for M,gpath,apath,amod in MODS:
    g=mod_ports(gpath,M)
    a=mod_ports(apath,amod)
    aset={p[2] for p in a}
    gset={p[2] for p in g}
    gonly=[p for p in g if p[2] not in aset]
    # 适配器不得有 golden 没有的端口(否则不是 drop-in)
    aonly=[p for p in a if p[2] not in gset]
    assert not aonly, f"{M}: adapter has {len(aonly)} ports not in golden: {[x[2] for x in aonly][:5]}"

    gtxt=open(gpath).read()
    passthru={}
    for mm in re.finditer(r'(?m)^\s*assign\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([A-Za-z_][A-Za-z0-9_]*)\s*;', gtxt):
        out,rhs=mm.group(1),mm.group(2)
        if out in gset and rhs in gset:
            passthru[out]=rhs

    out_gonly=[p for p in gonly if p[0]=='output']
    recon=[p for p in out_gonly if p[2] in passthru and passthru[p[2]] in gset]
    tied_out=[p for p in out_gonly if p[2] not in passthru]
    nonfunc[M]=[p[2] for p in tied_out]

    lines=[]
    lines.append(f"// 自动生成: verif/bt/MemBlock/gen_bt.py —— 勿手改")
    lines.append(f"// {M}_bt: 全 golden 端口 BT 包装, 例化已验证的 {amod}(暴露 golden 名子集 + 真重写 glue + xs_{M}_core),")
    lines.append(f"//   golden-only input 悬空 / golden-only output 透传重建或接 '0(rewrite 省略的元数据/debug 端口)。")
    lines.append(f"module {M}_bt(")
    decl=[]
    for d,w,n in g:
        decl.append(f"  {d} {w+' ' if w else ''}{n}")
    lines.append(",\n".join(decl))
    lines.append(");")
    lines.append(f"  {amod} u_xs (")
    conns=[f"    .{n}({n})" for d,w,n in a]
    lines.append(",\n".join(conns))
    lines.append("  );")
    for d,w,n in recon:
        lines.append(f"  assign {n} = {passthru[n]};  // golden passthrough reconstructed (functional)")
    for d,w,n in tied_out:
        lines.append(f"  assign {n} = '0;  // rewrite-omitted (nonfunc)")
    lines.append(f"endmodule")
    open(f"{M}_bt.sv","w").write("\n".join(lines)+"\n")
    print(f"{M}_bt.sv: golden={len(g)} adapter={len(a)} golden-only={len(gonly)} reconstructed={len(recon)} tied(nonfunc)={len(tied_out)}")

json.dump(nonfunc, open("nonfunc_ports.json","w"), indent=1)
print("wrote nonfunc_ports.json")
