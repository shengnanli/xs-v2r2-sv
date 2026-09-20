#!/usr/bin/env python3
"""从 G1 golden 机械抽取 CLZ 家族的事实，并**重建整个 golden 模块体**来验证。

## 验证方式：重建而不是抽查

和 DelayNWithValid 家族同一套做法：从两个参数（WIDTH、SCAN_LOW）把 golden 的
`assign io_out = ...` 整条三元链生成出来，再和真 golden 逐字比（只做空白归一化）。
对得上，就等于证明了「这个变体的全部逻辑 = 家族公式在这组参数上的取值」——
没有任何一条落在公式之外。抽查式断言做不到这一点。

## 家族公式

CLZ = count leading zeros：从最高位往下找第一个 1，输出它前面有几个 0。
golden 把它展开成一条从 io_in[WIDTH-1] 一路问到 io_in[SCAN_LOW] 的三元链，
第 i 位命中时输出 WIDTH-1-i；扫描范围内一个 1 都没有时输出 NONE = WIDTH - SCAN_LOW。

★SCAN_LOW 是本家族唯一有语义后果的那个参数★

  SCAN_LOW = 0  （CLZ_6/_7/_9/_11/_28/_29/_30/_31，8 个）
      扫到 io_in[0]，全零输入输出 WIDTH —— 教科书意义上的 CLZ。
      OUT_W 因此要能装下 WIDTH。

  SCAN_LOW = 1  （**只有 CLZ 本体**）
      io_in[0] 根本没被读。全零输入输出 WIDTH-1 = 63，**不是 64**。
      这是 Chisel `PriorityEncoder` 的语义：它把最后一个候选索引当作**无条件
      兜底**分支，于是"没找到"和"在最低位找到"这两件事输出相同。
      OUT_W = 6 只装得下 63，也正是这个缘故。
      ★这是 golden 的真实行为，不是需要补齐的不对称 —— 照抄，bug-for-bug。★

## firtool 的尾部因子分解

链的最后两个取值是 `io_in[SCAN_LOW] ? NONE-1 : NONE`。当 NONE-1 是**偶数**时，
这两个数只差最低位，firtool 把它写成 `{高位共同前缀, ~(io_in[SCAN_LOW])}`；
否则原样留一个三元。9 个变体逐个符合，重建比对会坐实这一点。
"""
import os
import re
import sys

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")

PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')


def _norm(s):
    """空白归一化：firtool 的折行与对齐是排版，不是结构。"""
    return re.sub(r"\s+", " ", s).strip()


def lit(width, value):
    """firtool 的字面量写法：<位宽>'h<大写十六进制，无前导零>。"""
    return "%d'h%X" % (width, value)


def rebuild(width, scan_low, out_w):
    """按家族公式重建 golden 的 `assign io_out = ...;`。"""
    none = width - scan_low          # 扫描范围内没有 1 时的输出
    terms = []
    # 从最高位往下问到 SCAN_LOW+1；SCAN_LOW 那一位与兜底值一起做尾部处理
    for i in range(width - 1, scan_low, -1):
        terms.append("io_in[%d] ? %s : " % (i, lit(out_w, width - 1 - i)))
    hit_low = none - 1               # io_in[SCAN_LOW] 命中时的输出
    if hit_low % 2 == 0 and hit_low + 1 == none:
        # 只差最低位 -> firtool 提公共前缀，低位写成 ~(io_in[SCAN_LOW])
        tail = "{%s, ~(io_in[%d])}" % (lit(out_w - 1, hit_low >> 1), scan_low)
    else:
        tail = "io_in[%d] ? %s : %s" % (scan_low, lit(out_w, hit_low), lit(out_w, none))
    return _norm("assign io_out = " + "".join(terms) + tail + ";")


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
    if names != ["io_in", "io_out"]:
        raise SystemExit("%s: 端口表不是 {io_in, io_out}: %s" % (name, names))
    width, out_w = ports[0]["w"], ports[1]["w"]

    logic = _norm(body[body.index("\n);") + 3:].rsplit("endmodule", 1)[0])

    # SCAN_LOW 从 golden 真正引用到的最低位索引读出来（不是猜的、也不是按 name 分的）
    idx = sorted(set(int(x) for x in re.findall(r'io_in\[(\d+)\]', logic)))
    if not idx:
        raise SystemExit("%s: 模块体里没有任何 io_in[..] 引用" % name)
    scan_low = idx[0]
    if idx != list(range(scan_low, width)):
        raise SystemExit("%s: 被引用的位不是连续的 [%d..%d]，实际 %s"
                         % (name, scan_low, width - 1, idx))

    # ★硬断言★：输出位宽恰好够装下"没找到"那个值，一位不多一位不少
    none = width - scan_low
    want_out = max(1, none.bit_length())
    if out_w != want_out:
        raise SystemExit("%s: io_out 宽 %d != 装下 NONE=%d 所需的 %d 位"
                         % (name, out_w, none, want_out))

    # ★重建比对★
    want = rebuild(width, scan_low, out_w)
    if logic != want:
        raise SystemExit("%s: golden 模块体与家族公式重建结果不一致\n  golden: %s\n  重建  : %s"
                         % (name, logic, want))

    return dict(name=name, ports=ports, width=width, out_w=out_w,
                scan_low=scan_low, none=none, head_text=head + "\n);")


if __name__ == "__main__":
    for n in sys.argv[1:]:
        f = facts(n)
        print("%-8s WIDTH=%-3d OUT_W=%d SCAN_LOW=%d NONE=%-3d "
              "[模块体 = 家族公式重建结果，逐字一致]"
              % (n, f["width"], f["out_w"], f["scan_low"], f["none"]))
