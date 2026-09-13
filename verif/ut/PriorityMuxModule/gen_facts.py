#!/usr/bin/env python3
"""从 G1 golden 机械抽取 PriorityMuxModule 家族每个变体的结构事实。

golden 的每个输出字段都是同一条形状的右结合三元链：
    out_f = selA ? srcA_f : selB ? srcB_f : ... : dflt_f
叶子全是标识符，所以按 '?' / ':' 切开后的记号序列就是
    [selA, srcA_f, selB, srcB_f, ..., selN, srcN_f, dflt_f]
本脚本据此还原出 (sel 序列, 每字段的各路源端口, 兜底源端口)，并校验：
  * 所有输出字段用的 sel 序列**完全相同**（否则就不是一个优先级选择器，家族不成立）；
  * 各路同名字段位宽一致；
  * 端口总数 == NUM_WAYS + (NUM_WAYS + 2) * NUM_FIELDS。
"""
import re, os, sys
G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')


def facts(name):
    txt = open(f"{G}/{name}.sv").read()
    body = txt[txt.index(f"\nmodule {name}(") + 1:]
    head = body[:body.index("\n);")]
    ports, width = [], {}
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"{name}: 端口行解析失败: {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        ports.append(dict(dir=m.group(1), w=w, name=m.group(4)))
        width[m.group(4)] = w
    rest = body[body.index("\n);") + 3:]
    flat = re.sub(r'\s+', ' ', rest)
    chains = re.findall(r'assign (\w+) = ([^;]+);', flat)
    sels, fields = None, []
    for out, expr in chains:
        tok = [t.strip() for t in re.split(r'[?:]', expr)]
        assert len(tok) % 2 == 1, (name, out, tok)
        s = tok[0::2][:-1]
        srcs = tok[1::2]
        dflt = tok[-1]
        if sels is None:
            sels = s
        assert sels == s, f"{name}: {out} 的 sel 序列与其它字段不同 —— 家族假设不成立"
        fields.append(dict(out=out, srcs=srcs, dflt=dflt, w=width[out]))
    nw, nf = len(sels), len(fields)
    assert len(ports) == nw + (nw + 2) * nf, (name, len(ports), nw, nf)
    for f in fields:
        for s in f["srcs"] + [f["dflt"]]:
            assert width[s] == f["w"], (name, f["out"], s)
    return dict(name=name, ports=ports, head_text=head + "\n);", sels=sels,
                fields=fields, num_ways=nw, num_fields=nf,
                payload=sum(f["w"] for f in fields))


if __name__ == "__main__":
    for n in sys.argv[1:]:
        f = facts(n)
        print(f"{n}: ways={f['num_ways']} fields={f['num_fields']} payload={f['payload']}b "
              f"ports={len(f['ports'])} sels={f['sels']} dflt_grp={f['fields'][0]['dflt']}")
