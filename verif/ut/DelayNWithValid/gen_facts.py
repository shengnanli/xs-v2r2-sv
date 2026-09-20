#!/usr/bin/env python3
"""从 G1 golden 机械抽取 DelayNWithValid 家族的事实，并**重建整个 golden 模块体**来验证。

## 验证方式：重建而不是抽查

一般的结构验证是「挑几条断言去查 golden」。这里做得更狠一点：从三个参数
（字段表、级数 STAGES、valid 链长 V）**把 golden 的模块体整段生成出来**，再和真的
golden 逐字比（只做空白归一化）。对得上，就等于证明了「这个变体的全部逻辑 = 家族
公式在这组参数上的取值」——没有任何一条语句落在公式之外，也不多也不少。
抽查式断言做不到这一点：它只能保证你想到要查的那些点。

## 家族公式（从 golden 反推、由重建逐条坐实）

对应 Chisel `utility.DelayNWithValid(in, valid, n)`：n 级 RegEnable 数据链 +
一条 valid 打拍链。三个自由参数：

  STAGES  n，数据级数（0/1/2/3）
  FIELDS  载荷字段表（名字 + 位宽），来自 golden 端口表
  V       valid 链保留下来的寄存器个数

V 不是自由的，它由「输出端口上有没有 io_out_valid」决定：

  V = 0                      当 STAGES == 0
  V = STAGES                 当 golden 有 io_out_valid（整条 valid 链都被读）
  V = STAGES - 1             当没有 io_out_valid（最后一级 valid 没人读，firtool 消掉）

★这就是本家族最大的坑★：同一个 n，光看寄存器个数会得出不同的"级数"。
DelayNWithValid_52（n=1，无 out_valid）整条 valid 链被消光，模块体只剩一个
`res_bits`，连 reset 端口都没有；而 DelayNWithValid_202（n=1，有 out_valid）
有 valid_REG 也有 reset。**两者是同一个公式的两组参数，不是两种电路。**

数据级使能：第 1 级用 io_in_valid，第 k 级（k>=2）用 valid 链的第 k-1 个寄存器。
命名沿用 golden：数据级 data / data_1 / … / res_bits（最后一级恒名 res_bits，
所以 n=1 时第 0 级就叫 res_bits）；valid 链 valid_REG / valid_REG_1 / …
"""
import os
import re
import sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')
MARK_BEGIN = "`ifdef ENABLE_INITIAL_REG_"
MARK_END = "`endif // ENABLE_INITIAL_REG_"


def _norm(s):
    """空白归一化：firtool 的折行与对齐是排版，不是结构。"""
    return re.sub(r"\s+", " ", s).strip()


def stage_name(s, stages):
    """数据级寄存器前缀：最后一级恒为 res_bits，第 0 级为 data，中间为 data_<s>。"""
    if s == stages - 1:
        return "res_bits"
    return "data" if s == 0 else "data_%d" % s


def valid_name(v):
    return "valid_REG" if v == 0 else "valid_REG_%d" % v


def _decl(w, name):
    return ("reg [%d:0] %s;" % (w - 1, name)) if w > 1 else ("reg %s;" % name)


def rebuild(fields, stages, V):
    """按家族公式重建 golden 的模块体（reg 声明 + always 块 + 连续赋值）。"""
    out = []
    # reg 声明：golden 按 FIRRTL 顺序交替发出「本级的 valid 寄存器 / 本级的数据寄存器」
    for s in range(stages):
        if s < V:
            out.append(_decl(1, valid_name(s)))
        pre = stage_name(s, stages)
        for f, w in fields:
            out.append(_decl(w, pre + f))

    # valid 链：异步高有效复位，整条链在同一个 always 里
    if V > 0:
        src = [("io_in_valid" if v == 0 else valid_name(v - 1)) for v in range(V)]
        if V == 1:
            out.append("always @(posedge clock or posedge reset) begin if (reset) "
                       "%s <= 1'h0; else %s <= %s; end // always @(posedge, posedge)"
                       % (valid_name(0), valid_name(0), src[0]))
        else:
            rst = " ".join("%s <= 1'h0;" % valid_name(v) for v in range(V))
            run = " ".join("%s <= %s;" % (valid_name(v), src[v]) for v in range(V))
            out.append("always @(posedge clock or posedge reset) begin if (reset) begin "
                       "%s end else begin %s end end // always @(posedge, posedge)" % (rst, run))

    # 数据级：每级一个 if(使能)，无复位
    if stages > 0:
        body = []
        for s in range(stages):
            en = "io_in_valid" if s == 0 else valid_name(s - 1)
            dst, src = stage_name(s, stages), ("io_in_bits" if s == 0 else stage_name(s - 1, stages))
            moves = ["%s <= %s;" % (dst + f, src + f) for f, _w in fields]
            body.append("if (%s)%s" % (en, (" begin %s end" % " ".join(moves))
                                       if len(moves) > 1 else " " + moves[0]))
        out.append("always @(posedge clock) begin %s end // always @(posedge)" % " ".join(body))

    # 连续赋值：载荷取最后一级；io_out_valid（若有）取 valid 链末端
    last = stage_name(stages - 1, stages) if stages > 0 else None
    for f, _w in fields:
        out.append("assign io_out_bits%s = %s;" % (f, (last + f) if stages else "io_in_bits" + f))
    if V == stages and stages > 0:
        out.append("assign io_out_valid = %s;" % valid_name(V - 1))
    return _norm(" ".join(out))


def facts(name):
    txt = open("%s/%s.sv" % (G, name)).read()
    body = txt[txt.index("\nmodule %s(" % name) + 1:]
    head = body[:body.index("\n);")]
    ports = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit("%s: 端口行解析失败: %r" % (name, ln))
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        ports.append(dict(dir=m.group(1), w=w, name=m.group(4)))

    ins = [p for p in ports if p["name"].startswith("io_in_bits")]
    outs = [p for p in ports if p["name"].startswith("io_out_bits")]
    names = [p["name"] for p in ports]
    has_out_valid = "io_out_valid" in names
    has_clock = "clock" in names
    has_reset = "reset" in names
    fields = [(p["name"][len("io_in_bits"):], p["w"]) for p in ins]
    if fields != [(p["name"][len("io_out_bits"):], p["w"]) for p in outs]:
        raise SystemExit("%s: io_in_bits_* 与 io_out_bits_* 字段表不一致" % name)

    # 级数与 valid 链长从 reg 声明数出来（不是从名字猜）
    regs = re.findall(r'^  reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);', body, re.M)
    vregs = [r for r in regs if r[2].startswith("valid_REG")]
    dregs = [r for r in regs if not r[2].startswith("valid_REG")]
    V = len(vregs)
    nf = len(fields)
    if len(dregs) % nf:
        raise SystemExit("%s: 数据 reg 个数 %d 不是字段数 %d 的整数倍" % (name, len(dregs), nf))
    stages = len(dregs) // nf

    # ★家族公式的三条硬断言★
    want_V = 0 if stages == 0 else (stages if has_out_valid else stages - 1)
    if V != want_V:
        raise SystemExit("%s: valid 链长 %d != 公式值 %d（STAGES=%d, out_valid=%s）"
                         % (name, V, want_V, stages, has_out_valid))
    if has_clock != (stages > 0):
        raise SystemExit("%s: clock 端口(%s) 与 STAGES=%d 不相容" % (name, has_clock, stages))
    if has_reset != (V > 0):
        raise SystemExit("%s: reset 端口(%s) 与 valid 链长 %d 不相容" % (name, has_reset, V))
    if ("io_in_valid" in names) != (stages > 0):
        raise SystemExit("%s: io_in_valid 端口与 STAGES=%d 不相容" % (name, stages))

    # ★重建比对★：把 golden 的逻辑区整段拿出来，和公式生成的逐字比
    region = body[body.index("\n);") + 3:]
    if MARK_BEGIN in region:          # 有寄存器的变体带 RANDOMIZE 初始化块，跳过它
        logic = region[:region.index(MARK_BEGIN)] + region[region.rindex(MARK_END) + len(MARK_END):]
    else:
        logic = region
    logic = _norm(logic[:logic.rindex("endmodule")])
    want = rebuild(fields, stages, V)
    if logic != want:
        raise SystemExit("%s: golden 模块体与家族公式重建结果不一致\n  golden: %s\n  重建  : %s"
                         % (name, logic, want))

    return dict(name=name, ports=ports, ins=ins, outs=outs, fields=fields,
                stages=stages, valid_chain=V, has_out_valid=has_out_valid,
                has_clock=has_clock, has_reset=has_reset,
                payload=sum(w for _f, w in fields),
                reg_bits=V + stages * sum(w for _f, w in fields),
                head_text=head + "\n);")


if __name__ == "__main__":
    for n in sys.argv[1:]:
        f = facts(n)
        print("%-22s STAGES=%d V=%d out_valid=%d fields=%-2d payload=%-3d reg_bits=%-4d "
              "[模块体 = 家族公式重建结果，逐字一致]"
              % (n, f["stages"], f["valid_chain"], f["has_out_valid"], len(f["fields"]),
                 f["payload"], f["reg_bits"]))
