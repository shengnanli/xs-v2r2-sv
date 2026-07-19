#!/usr/bin/env python3
"""harness dts/json gate(七审)。JSON 用解析器只删顶层 model 字段后 canonical 比较;
DTS 断言两侧各**恰一行**顶层 `model = `、删除后逐字节比较。
(旧 grep -v 是空证明: build/json 单行且含 "model" → 两侧全被滤空, 任何差异都过。)
用法: harness_gate.py <frozen-dir> <fresh-build-dir>"""
import sys, json

FZ, FR = sys.argv[1], sys.argv[2]

a = json.load(open(FZ + "/build_json.G0"))
b = json.load(open(FR + "/json"))
if "model" not in a or "model" not in b:
    print("JSON 缺顶层 model 字段"); sys.exit(1)
del a["model"]; del b["model"]
if json.dumps(a, sort_keys=True) != json.dumps(b, sort_keys=True):
    print("JSON 非-model 字段不一致"); sys.exit(1)

da = open(FZ + "/build_dts.G0").read().splitlines(True)
db = open(FR + "/dts").read().splitlines(True)
ma = [i for i, l in enumerate(da) if l.lstrip().startswith("model = ")]
mb = [i for i, l in enumerate(db) if l.lstrip().startswith("model = ")]
if len(ma) != 1 or len(mb) != 1:
    print("DTS model 行数异常: 冻结%d fresh%d(须恰1)" % (len(ma), len(mb))); sys.exit(1)
del da[ma[0]]; del db[mb[0]]
if "".join(da) != "".join(db):
    print("DTS 非-model 行不一致"); sys.exit(1)
print("harness dts/json gate OK(恰 model 差异)")
