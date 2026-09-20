#!/usr/bin/env python3
"""从 G1 golden 机械抽取 PipeWithFlush 家族的事实，并**重建整个 golden 模块体**来验证。

## 验证方式：重建而不是抽查

同 DelayNWithValid / CLZ 两族的做法：从「字段表 + 级数 STAGES」两个参数把 golden
的模块体整段生成出来，与真 golden 逐字比（只做空白归一化）。8/8 对得上，就等于
证明了每个变体的全部逻辑 = 家族公式在这组参数上的取值，没有任何一条落在公式之外。

## 这个模块是什么

对应 Chisel `PipeWithFlush`：后端发射流水线上的 N 级"带冲刷的寄存器流水"。
一条 valid 链 + 一份随行的 bits 载荷，中途可以被重定向（redirect）冲掉。

  valids_1 <= io_enq_valid                      ← 第 1 级**不冲刷**
  valids_k <= valids_{k-1} & ~flush_k   (k>=2)  ← 第 2 级起才冲刷
  bits_1   <= io_enq_bits        当 io_enq_valid
  bits_k   <= bits_{k-1}         当 valids_{k-1}

★为什么第 1 级不冲刷★：冲刷判据要读**这一拍正待前移的那个条目的 robIdx**，
而第 1 级的来源是组合输入 io_enq_bits，还没有落进寄存器；上游发射级自己会挡。
于是 golden 的 N=1 变体（_6 / _10）**一个 flush 端口都没有** —— 不是被裁剪掉了，
是公式里本来就用不到。

## flush_k 的三项（缺一不可，都从 golden 读出来）

  1) redirect：`redirect.valid & (level & robIdx == redirRobIdx | isAfter)`
     其中 isAfter = `flag ^ redirFlag ^ (value > redirValue)` —— 这是香山的
     环形 robIdx 比较（flag 是回绕位）。★Verilog 优先级：`>` 紧于 `^`，
     所以那一长串是 flag ^ redirFlag ^ (value > redirValue)，不是别的断法。★
  2) ldCancel：`ldCancel_j & loadDependency_j[LDW-1]` 逐路或起来。
     只有**带 loadDependency 字段**的变体才有（本家族里只有 _1）。
  3) og(k-2)Fail：第 k 级专属的一根"上一级发射失败"输入。
     N=2 只用到 og0Fail，N=3 用到 og0Fail 与 og1Fail。

## ★loadDependency 在级间要左移一位★

  bits_k_loadDependency_j <= {bits_{k-1}_loadDependency_j[LDW-2:0], 1'h0}   (k>=2)

它是"这个条目还欠第 j 路 load 几拍"的移位计数器，每前移一级就老化一位。
**第 1 级不移**（`bits_1_loadDependency_j <= io_enq_bits_loadDependency_j` 原样收），
因为入口那份已经是当前拍的值。其余字段一律原样搬。
本家族里只有 _1 同时满足「有 loadDependency」且「STAGES>=2」，所以只有它看得到
这条移位；但公式是按级数写的，不是按变体特判的 —— 重建比对会把这件事坐实。
"""
import os
import re
import sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')
MARK_BEGIN = "`ifdef ENABLE_INITIAL_REG_"
MARK_END = "`endif // ENABLE_INITIAL_REG_"

REDIR = "{io_flush_redirect_bits_robIdx_flag, io_flush_redirect_bits_robIdx_value}"
# firtool 在 redirect 比较用到 2 次及以上时会把右操作数提成一个 wire（CSE）。
CSE_WIRE = "_valids_%d_redirectFlush_flushItself_T_2"


def _norm(s):
    return re.sub(r"\s+", " ", s).strip()


def _decl(w, name):
    return ("reg [%d:0] %s;" % (w - 1, name)) if w > 1 else ("reg %s;" % name)


def _slice(name, hi, lo):
    return "%s[%d]" % (name, hi) if hi == lo else "%s[%d:%d]" % (name, hi, lo)


def flush_expr(prev, ld_fields, ld_w, stage, cse):
    """第 stage 级的冲刷条件；prev = stage-1，读的是上一级寄存器里的 robIdx。"""
    rhs = cse if cse else REDIR
    parts = ["io_flush_redirect_valid & (io_flush_redirect_bits_level"
             " & {bits_%d_robIdx_flag, bits_%d_robIdx_value} == %s"
             " | bits_%d_robIdx_flag ^ io_flush_redirect_bits_robIdx_flag"
             " ^ bits_%d_robIdx_value > io_flush_redirect_bits_robIdx_value)"
             % (prev, prev, rhs, prev, prev)]
    for j, f in enumerate(ld_fields):
        parts.append("io_flush_ldCancel_%d_ld2Cancel & %s"
                     % (j, _slice("bits_%d%s" % (prev, f), ld_w - 1, ld_w - 1)))
    parts.append("io_flush_og%dFail" % (stage - 2))
    return " | ".join(parts)


def rebuild(fields, stages, ld_fields, ld_w):
    out = []
    if stages == 0:
        out.append("assign io_deq_valid = io_enq_valid;")
        for f, _w in fields:
            out.append("assign io_deq_bits%s = io_enq_bits%s;" % (f, f))
        return _norm(" ".join(out))

    # reg 声明：先整条 valid 链，再逐级的 bits
    for k in range(1, stages + 1):
        out.append(_decl(1, "valids_%d" % k))
    for k in range(1, stages + 1):
        for f, w in fields:
            out.append(_decl(w, "bits_%d%s" % (k, f)))

    # redirect 右操作数用到 >=2 次时被 firtool 提成 wire
    cse = None
    if stages >= 3:
        cse = CSE_WIRE % stages
        out.append("wire [8:0] %s = %s;" % (cse, REDIR))

    # valid 链：异步高有效复位
    if stages == 1:
        out.append("always @(posedge clock or posedge reset) begin if (reset) "
                   "valids_1 <= 1'h0; else valids_1 <= io_enq_valid; end"
                   " // always @(posedge, posedge)")
    else:
        rst = " ".join("valids_%d <= 1'h0;" % k for k in range(1, stages + 1))
        run = ["valids_1 <= io_enq_valid;"]
        for k in range(2, stages + 1):
            run.append("valids_%d <= valids_%d & ~(%s);"
                       % (k, k - 1, flush_expr(k - 1, ld_fields, ld_w, k, cse)))
        out.append("always @(posedge clock or posedge reset) begin if (reset) begin %s end"
                   " else begin %s end end // always @(posedge, posedge)"
                   % (rst, " ".join(run)))

    # 数据级：每级一个 if(使能)，无复位；loadDependency 在 k>=2 时左移一位
    body = []
    for k in range(1, stages + 1):
        en = "io_enq_valid" if k == 1 else "valids_%d" % (k - 1)
        moves = []
        for f, w in fields:
            if k == 1:
                src = "io_enq_bits%s" % f
            elif f in ld_fields:
                src = "{%s, 1'h0}" % _slice("bits_%d%s" % (k - 1, f), ld_w - 2, 0)
            else:
                src = "bits_%d%s" % (k - 1, f)
            moves.append("bits_%d%s <= %s;" % (k, f, src))
        body.append("if (%s)%s" % (en, (" begin %s end" % " ".join(moves))
                                   if len(moves) > 1 else " " + moves[0]))
    out.append("always @(posedge clock) begin %s end // always @(posedge)" % " ".join(body))

    out.append("assign io_deq_valid = valids_%d;" % stages)
    for f, _w in fields:
        out.append("assign io_deq_bits%s = bits_%d%s;" % (f, stages, f))
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

    names = [p["name"] for p in ports]
    ins = [p for p in ports if p["name"].startswith("io_enq_bits")]
    outs = [p for p in ports if p["name"].startswith("io_deq_bits")]
    fields = [(p["name"][len("io_enq_bits"):], p["w"]) for p in ins]
    if fields != [(p["name"][len("io_deq_bits"):], p["w"]) for p in outs]:
        raise SystemExit("%s: io_enq_bits_* 与 io_deq_bits_* 字段表不一致" % name)

    # 级数从 valids_* reg 声明数出来（不是从名字猜）
    regs = re.findall(r'^  reg\s+(?:\[(\d+):(\d+)\]\s+)?(\w+);', body, re.M)
    stages = len([r for r in regs if r[2].startswith("valids_")])
    nf = len(fields)
    dregs = [r for r in regs if r[2].startswith("bits_")]
    if len(dregs) != stages * nf:
        raise SystemExit("%s: bits_* reg 个数 %d != 级数 %d × 字段数 %d"
                         % (name, len(dregs), stages, nf))

    ld_fields = [f for f, _w in fields if f.startswith("_loadDependency")]
    ld_ws = set(w for f, w in fields if f in ld_fields)
    if len(ld_ws) > 1:
        raise SystemExit("%s: loadDependency 各路位宽不一致: %s" % (name, ld_ws))
    ld_w = ld_ws.pop() if ld_ws else 0
    # 第 2 级起才有冲刷，也才用得到 ldCancel
    ld_used = ld_fields if stages >= 2 else []

    # ★端口表与形状的硬断言★
    has_clock, has_reset = "clock" in names, "reset" in names
    if has_clock != (stages > 0) or has_reset != (stages > 0):
        raise SystemExit("%s: clock(%s)/reset(%s) 与 STAGES=%d 不相容"
                         % (name, has_clock, has_reset, stages))
    want_flush = (["io_flush_redirect_valid", "io_flush_redirect_bits_robIdx_flag",
                   "io_flush_redirect_bits_robIdx_value", "io_flush_redirect_bits_level"]
                  + ["io_flush_ldCancel_%d_ld2Cancel" % j for j in range(len(ld_used))]
                  + ["io_flush_og%dFail" % k for k in range(stages - 1)]
                  ) if stages >= 2 else []
    got_flush = [n for n in names if n.startswith("io_flush_")]
    if got_flush != want_flush:
        raise SystemExit("%s: flush 端口表与公式不符\n  golden: %s\n  公式  : %s"
                         % (name, got_flush, want_flush))
    if stages >= 2:
        need = [("_robIdx_flag", 1), ("_robIdx_value", 8)]
        for f, w in need:
            if (f, w) not in fields:
                raise SystemExit("%s: STAGES=%d 需要冲刷判据，但字段表里没有 %s(%db)"
                                 % (name, stages, f, w))

    # ★重建比对★
    region = body[body.index("\n);") + 3:]
    if MARK_BEGIN in region:
        logic = region[:region.index(MARK_BEGIN)] + region[region.rindex(MARK_END) + len(MARK_END):]
    else:
        logic = region
    logic = _norm(logic[:logic.rindex("endmodule")])
    want = rebuild(fields, stages, ld_used, ld_w)
    if logic != want:
        raise SystemExit("%s: golden 模块体与家族公式重建结果不一致\n  golden: %s\n  重建  : %s"
                         % (name, logic, want))

    return dict(name=name, ports=ports, ins=ins, outs=outs, fields=fields,
                stages=stages, ld_fields=ld_used, ld_w=ld_w,
                has_flush=(stages >= 2), n_ldcancel=len(ld_used),
                payload=sum(w for _f, w in fields),
                reg_bits=stages * (1 + sum(w for _f, w in fields)),
                head_text=head + "\n);")


if __name__ == "__main__":
    for n in sys.argv[1:]:
        f = facts(n)
        print("%-18s STAGES=%d fields=%-2d payload=%-3d reg_bits=%-4d flush=%s ldCancel=%d "
              "[模块体 = 家族公式重建结果，逐字一致]"
              % (n, f["stages"], len(f["fields"]), f["payload"], f["reg_bits"],
                 f["has_flush"], f["n_ldcancel"]))
