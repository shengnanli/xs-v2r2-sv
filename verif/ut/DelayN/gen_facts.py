#!/usr/bin/env python3
"""从 G1 golden 机械抽取 DelayN 家族每个变体的事实（端口表 / 级数 / 寄存器总位数），
并**逐条验证**它确实是「无条件 N 级移位链」这个形状。

为什么要结构验证而不是只数位宽：位数守恒（payload × stages == reg_bits）是**必要
不充分**的——把一级的使能条件抄丢、把某一级接错上游、把输出接到中间级，位数一个
不差。本轮任务书明确点名的教训是「别拿名字对得上当结构证据」，位数对得上同样不是。

verify() 做的事（任何一条不成立就 SystemExit，生成器当场停）：
  1. 端口集合 = {clock（仅 stages>0）} ∪ io_in_* ∪ io_out_*，没有第三类；
  2. io_in_<f> 与 io_out_<f> 字段名逐个同名同宽同序（golden 的字段表就是载荷表）；
  3. reg 声明恰好是 stages × fields 个，名字 = REG[_<s>]<f>，宽度 = 该字段宽度；
  4. **只有一个** always 块，且是 `always @(posedge clock)`（无复位、无使能）；
     块里恰好 stages × fields 条非阻塞赋值，且构成 REG<f> <= io_in<f>、
     REG_<s><f> <= REG_<s-1><f> 的链——多一条少一条、接错上游都报错；
  5. 连续赋值恰好是 io_out<f> = REG_<stages-1><f>（输出取最后一级）。
stages == 0 的退化变体（DelayN_225）：无 clock、无 reg、无 always，输出直连输入。
"""
import re, sys, os
G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')
REGDECL = re.compile(r'^  reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);', re.M)
# 两种形态都要认：多语句版 `always @(...) begin ... end // always`，
# 以及只有一条赋值时 firtool 省掉 begin/end 的单语句版（DelayN_13 就是）。
ALWAYS = re.compile(r'^  always @\(([^)]*)\) begin\n(.*?)\n  end // always', re.M | re.S)
ALWAYS1 = re.compile(r'^  always @\(([^)]*)\)\n((?:    .*\n)+?)(?=  [`a-z])', re.M)
NBA = re.compile(r'^\s*(\w+)\s*<=\s*(\w+);\s*$')
CONT = re.compile(r'^  assign (\w+) =\s+(\w+);$', re.M | re.S)


def _unwrap(text):
    """firtool 会把过长的语句折行（`a <=\n  b;`）。判据要看语句不看行，
    所以先按「以 ; 结尾」把续行并回来，再逐条匹配。不并行的话，同一条赋值
    会被数成两行，判据就会在纯属排版的地方误报。"""
    out, cur = [], ""
    for ln in text.split("\n"):
        if not ln.strip():
            continue
        cur = (cur + " " + ln.strip()) if cur else ln.strip()
        if cur.endswith(";"):
            out.append(re.sub(r"\s+", " ", cur))
            cur = ""
    if cur:
        out.append(re.sub(r"\s+", " ", cur))
    return out


def _die(name, msg):
    raise SystemExit("golden 结构验证失败 %s: %s" % (name, msg))


def _stage_suffix(s):
    """golden 的命名：第 0 级叫 REG，第 s 级叫 REG_<s>。"""
    return "" if s == 0 else "_%d" % s


def verify(name, body, ports, ins, outs, stages):
    field = [p["name"][len("io_in"):] for p in ins]          # "" 或 "_bits_addr" 这样
    widths = [p["w"] for p in ins]

    # 1. 端口只有三类
    others = [p["name"] for p in ports if p not in ins and p not in outs]
    want_other = ["clock"] if stages > 0 else []
    if others != want_other:
        _die(name, "端口表除 io_in_*/io_out_* 外应为 %r，实为 %r" % (want_other, others))

    # 2. 输入字段表 == 输出字段表
    if field != [p["name"][len("io_out"):] for p in outs]:
        _die(name, "io_in_* 与 io_out_* 字段名/顺序不一致")
    if widths != [p["w"] for p in outs]:
        _die(name, "io_in_* 与 io_out_* 字段位宽不一致")

    # 3. reg 声明表
    got = [(m.group(3), (int(m.group(1)) - int(m.group(2)) + 1) if m.group(1) else 1)
           for m in REGDECL.finditer(body)]
    want = [("REG%s%s" % (_stage_suffix(s), f), w)
            for s in range(stages) for f, w in zip(field, widths)]
    if got != want:
        _die(name, "reg 声明表与「%d 级 × %d 字段」不符\n  期望 %r\n  实际 %r"
             % (stages, len(field), want, got))

    # 4. always 块：只有一个，无复位无使能，内容是整条移位链
    blocks = ALWAYS.findall(body) or ALWAYS1.findall(body)
    if stages == 0:
        if blocks:
            _die(name, "stages=0 的变体不应有 always 块，实际有 %d 个" % len(blocks))
    else:
        if len(blocks) != 1:
            _die(name, "应恰有 1 个 always 块，实际 %d 个" % len(blocks))
        sens, inner = blocks[0]
        if sens.strip() != "posedge clock":
            _die(name, "always 敏感表应为 'posedge clock'（无复位），实为 %r" % sens)
        stmts = _unwrap(inner)
        want_nba = [("REG%s%s" % (_stage_suffix(s), f),
                     ("io_in%s" % f) if s == 0 else ("REG%s%s" % (_stage_suffix(s - 1), f)))
                    for s in range(stages) for f in field]
        if len(stmts) != len(want_nba):
            _die(name, "always 块应有 %d 条赋值（含任何 if/else 都会让这条不成立），实际 %d 行:\n%s"
                 % (len(want_nba), len(stmts), inner))
        for ln, (lhs, rhs) in zip(stmts, want_nba):
            m = NBA.match(ln)
            if not m:
                _die(name, "always 块里出现非「a <= b;」的语句（使能/条件会落在这里）: %r" % ln)
            if (m.group(1), m.group(2)) != (lhs, rhs):
                _die(name, "移位链接错: 期望 %s <= %s，实际 %s <= %s"
                     % (lhs, rhs, m.group(1), m.group(2)))

    # 5. 输出连续赋值取最后一级
    # 连续赋值区在 ENABLE_INITIAL_REG_ 的 `ifdef 块之后；那块里有 `ifdef/initial，
    # 不是语句，混进来会把第一条 assign 粘掉，所以先切到块尾再取。
    mark = "`endif // ENABLE_INITIAL_REG_"
    tail = body[body.rindex(mark) + len(mark):] if mark in body \
        else body[body.index("\n);") + 3:]
    conts = [tuple(re.match(r'assign (\w+) = (\w+);$', s).groups())
             for s in _unwrap(tail) if s.startswith("assign ")]
    last = "REG%s" % _stage_suffix(stages - 1) if stages > 0 else "io_in"
    want_cont = [("io_out%s" % f, ("%s%s" % (last, f)) if stages > 0 else "io_in%s" % f)
                 for f in field]
    if conts != want_cont:
        _die(name, "输出连续赋值不是「取最后一级」\n  期望 %r\n  实际 %r" % (want_cont, conts))


def facts(name):
    txt = open("%s/%s.sv" % (G, name)).read()
    i = txt.index("\nmodule %s(" % name)
    body = txt[i + 1:]
    head = body[:body.index("\n);")]
    ports = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit("%s: 端口行解析失败: %r" % (name, ln))
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        ports.append(dict(dir=m.group(1), w=w, name=m.group(4), text=ln))
    # 寄存器：级数 + 总位数
    regs = REGDECL.findall(body)
    tot = 0
    stages = set()
    for hi, lo, rn in regs:
        tot += (int(hi) - int(lo) + 1) if hi else 1
        m = re.match(r'REG(_(\d+))?(_.*)?$', rn)
        stages.add(int(m.group(2)) if m and m.group(2) else 0)
    ins = [p for p in ports if p["name"].startswith("io_in")]
    outs = [p for p in ports if p["name"].startswith("io_out")]
    other = [p for p in ports if p not in ins and p not in outs]
    nstage = len(stages)
    payload = sum(p["w"] for p in ins)
    if payload * nstage != tot:
        raise SystemExit("%s: 位数不守恒 payload=%d × stages=%d != reg_bits=%d"
                         % (name, payload, nstage, tot))
    verify(name, body, ports, ins, outs, nstage)
    return dict(name=name, ports=ports, ins=ins, outs=outs, other=[p["name"] for p in other],
                stages=nstage, reg_bits=tot, payload=payload, head_text=head + "\n);")


if __name__ == "__main__":
    for n in sys.argv[1:]:
        f = facts(n)
        print("%s: stages=%d reg_bits=%d payload=%d ports=%d other=%s "
              "[结构验证通过：无条件 %d 级移位链]"
              % (n, f["stages"], f["reg_bits"], f["payload"], len(f["ports"]),
                 f["other"], f["stages"]))
