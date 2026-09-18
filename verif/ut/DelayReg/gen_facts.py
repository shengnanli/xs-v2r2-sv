#!/usr/bin/env python3
"""从 G1 golden 机械抽取 DelayReg 家族每个变体的事实（端口表 / 级数 / 寄存器总位数）。

与 verif/ut/DelayN/gen_facts.py 同形，但这一族的 golden 多两根控制线
（reset 同步复位、enable 使能），寄存器名是 r_<级号>_<字段名>（1 起编号）。

★本文件另带一项别处没有的核对：reconstruct()★
把 (端口表, 级数) 两个事实重新拼成完整的 golden 模块体，与 golden 逐行比对。
11/11 一致 = 这些文件里除了字段表与级数没有任何别的内容 —— "一个核覆盖全族"
因此是**量出来的**，不是看着像。任何一份对不上，gen.py 当场拒绝生成。
"""
import re, sys, os

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

# 家族 11 个变体 -> 使用者与 delay= 的出处（在 XiangShan 源码里 grep 出来的调用点；
# 只写核对得上的，核对不上的宁可留白）。深度差异的**原因**在这里，不是异常。
USERS = {
    "DelayReg":    ("DiffInstrCommit（提交事件，8 条提交道各一份）",
                    "src/main/scala/xiangshan/backend/rob/Rob.scala:1543 delay = 3"),
    "DelayReg_16": ("重命名表快照 32 项 × 8 位（Int 与 Fp 两张表位宽相同，firtool 去重后共用一个模块，golden 里例化 2 次）",
                    "src/main/scala/xiangshan/backend/rename/RenameTable.scala:251/283 delay = 2"),
    "DelayReg_18": ("重命名表快照 64 项 × 9 位（向量表）",
                    "src/main/scala/xiangshan/backend/rename/RenameTable.scala:312 delay = 2"),
    "DelayReg_19": ("物理寄存器堆快照 224 项 × 64 位",
                    "src/main/scala/xiangshan/backend/datapath/DataPath.scala:307/317/329 delay = 2"),
    "DelayReg_20": ("物理寄存器堆快照 192 项 × 64 位",
                    "src/main/scala/xiangshan/backend/datapath/DataPath.scala:307/317/329 delay = 2"),
    "DelayReg_21": ("物理寄存器堆快照 300 项 × 64 位",
                    "src/main/scala/xiangshan/backend/datapath/DataPath.scala:307/317/329 delay = 2"),
    "DelayReg_22": ("DiffArchEvent（中断/异常事件）",
                    "src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala:1570 delay = 3"),
    "DelayReg_23": ("DiffCriticalErrorEvent（致命错误事件）—— ★全族最深的一个★",
                    "src/main/scala/xiangshan/backend/fu/NewCSR/NewCSR.scala:1584 delay = 4"),
    "DelayReg_24": ("DiffUncacheMMStoreEvent（uncache 访存 store，8 字节）",
                    "src/main/scala/xiangshan/cache/dcache/Uncache.scala:447 delay = 1"),
    "DelayReg_25": ("DiffSbufferEvent（sbuffer 整行 64 字节）",
                    "src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala:769 delay = 1"),
    "DelayReg_26": ("DiffStoreEvent（store 事件，golden 里例化 3 次）",
                    "src/main/scala/xiangshan/mem/sbuffer/Sbuffer.scala:920/945 delay = 2"),
}
VARIANTS = list(USERS)


def facts(name):
    txt = open(f"{G}/{name}.sv").read()
    i = txt.index(f"\nmodule {name}(")
    body = txt[i + 1:]
    head = body[:body.index("\n);")]
    ports = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"{name}: 端口行解析失败: {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        ports.append(dict(dir=m.group(1), w=w, name=m.group(4), text=ln))

    regs = re.findall(r'^  reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);', body, re.M)
    tot, stages = 0, set()
    for hi, lo, rn in regs:
        tot += (int(hi) - int(lo) + 1) if hi else 1
        m = re.match(r'r_(\d+)_', rn)
        if not m:
            raise SystemExit(f"{name}: 寄存器名不是 r_<级>_<字段> 形式: {rn}")
        stages.add(int(m.group(1)))

    ins = [p for p in ports if p["name"].startswith("i_")]
    outs = [p for p in ports if p["name"].startswith("o_")]
    ctrl = [p["name"] for p in ports if not p["name"].startswith(("i_", "o_"))]
    if ctrl != ["clock", "reset", "enable"]:
        raise SystemExit(f"{name}: 控制端口不是 clock/reset/enable 而是 {ctrl}")
    # 级号必须是 1..n 连续
    if sorted(stages) != list(range(1, max(stages) + 1)):
        raise SystemExit(f"{name}: 级号不连续: {sorted(stages)}")
    return dict(name=name, ports=ports, ins=ins, outs=outs, ctrl=ctrl,
                stages=max(stages), reg_bits=tot,
                payload=sum(p["w"] for p in ins),
                head_text=head + "\n);")


def reconstruct(f):
    """只用 (端口表, 级数) 重建 golden 模块体（不含 firtool 随机初值段）。"""
    t, depth = f["name"], f["stages"]
    fld = [(p["name"][2:], p["w"], p["text"]) for p in f["ins"]]
    out = [f"module {t}("]
    for k, p in enumerate(f["ports"]):
        out.append(p["text"].rstrip().rstrip(",") + ("" if k == len(f["ports"]) - 1 else ","))
    out += [");", ""]
    def decl(w):
        return "" if w == 1 else f" [{w-1}:0]"
    for k in range(1, depth + 1):
        for nm, w, _ in fld:
            out.append(f"  reg{decl(w)} r_{k}_{nm};")
    out += ["  always @(posedge clock) begin", "    if (reset) begin"]
    for k in range(1, depth + 1):
        for nm, w, _ in fld:
            out.append(f"      r_{k}_{nm} <= {w}'h0;")
    out += ["    end", "    else if (enable) begin"]
    for k in range(1, depth + 1):
        for nm, w, _ in fld:
            out.append(f"      r_{k}_{nm} <= {'i_'+nm if k == 1 else f'r_{k-1}_{nm}'};")
    out += ["    end", "  end // always @(posedge)"]
    for nm, w, _ in fld:
        out.append(f"  assign o_{nm} = r_{depth}_{nm};")
    out.append("endmodule")
    return out


def golden_body(name):
    lines = open(f"{G}/{name}.sv").read().split("\n")
    s = next(i for i, l in enumerate(lines) if l.startswith(f"module {name}("))
    e = next(i for i, l in enumerate(lines) if l == "endmodule")
    out, skip = [], False
    for l in lines[s:e + 1]:
        if "`ifdef ENABLE_INITIAL_REG_" in l:
            skip = True
        if not skip:
            out.append(l)
        if skip and l.strip() == "`endif // ENABLE_INITIAL_REG_":
            skip = False
    return out


def norm(s):
    return re.sub(r"\s+", " ", s).strip()


def verify_reconstruct(name):
    f = facts(name)
    a = [norm(x) for x in golden_body(name) if norm(x)]
    b = [norm(x) for x in reconstruct(f) if norm(x)]
    return a == b, f


if __name__ == "__main__":
    names = sys.argv[1:] or VARIANTS
    allok = True
    for n in names:
        ok, f = verify_reconstruct(n)
        allok &= ok
        nm_ok = [p["name"][2:] for p in f["ins"]] == [p["name"][2:] for p in f["outs"]]
        w_ok = [p["w"] for p in f["ins"]] == [p["w"] for p in f["outs"]]
        print(f"{n}: stages={f['stages']} reg_bits={f['reg_bits']} payload={f['payload']} "
              f"ports={len(f['ports'])} fields={len(f['ins'])} "
              f"eq={f['payload']*f['stages']==f['reg_bits']} "
              f"io_names_match={nm_ok} io_widths_match={w_ok} RECONSTRUCT_EXACT={ok}")
    print("ALL_RECONSTRUCT_EXACT =", allok)
    sys.exit(0 if allok else 1)
