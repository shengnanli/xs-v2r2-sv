#!/usr/bin/env python3
"""生成 BoothEncoderF64F32F16 的双例化 UT testbench（tb.sv）。

golden BoothEncoderF64F32F16（标量 FloatFMA 用）vs 重写 BoothEncoderF64F32F16_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），
纯组合，逐拍比 27 个 107 位加数。

激励：格式三选一（另有 1/16 的拍 is_fp64 / is_fp32 全随机，含两者同时为 1 —— fp64 优先）；
  in_a / in_b：一半全随机，一半按 f16 通道（11 位一段）放特殊值（全 0 / 全 1 / 只最高位 / 只最低位 /
  0101 / 1010 / 随机），段间的 2~5 位空隙也随机 —— f32/f64 把这些段拼起来看，同样打到长串 0/1。
覆盖闸：三种格式各自的拍数；27 个 Booth 数字 × {+1, +2, -1, -2} 每一种都译出过（看 golden 的
  booth_4bit_onehot_<i>；第 26 个数字的窗口最高位恒 0，只可能是 0/+1/+2，所以它的 -1/-2 两项不设；
  第 0 个数字的窗口最低位 b[-1] 恒 0，不可能是 +2，该项也不设）；
  每个输出位见过 0 和 1。
豁免的输出位由本脚本按结构算出（不是跑出来再填）：三种格式下该位都是同一个常量（高位的 0、
  移位空出的 0、f32 的第 13 个数字整项恒 0 之类）才豁免；任何一种格式下它是变量、或各格式常量不同，都必须见过 0/1。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

SUM_W, NDIG = 107, 27
# (有效数宽, [(数字基址, 107 位里的起始位)])
FORMATS = {
    "f64": (53, [(0, 0)]),
    "f32": (24, [(0, 0)]),          # 标量：每种格式只有通道 0
    "f16": (11, [(0, 0)]),
}


def bit_kinds(w, lanes):
    """返回 kinds[i][b] ∈ {'v', 0, 1}：该格式下第 i 个加数第 b 位是变量还是常量。"""
    n = w // 2 + 1
    kinds = [[0] * SUM_W for _ in range(NDIG)]
    for d0, off in lanes:
        for k in range(n):
            row = kinds[d0 + k]
            if k == 0:
                for b in range(w + 4):          # {~neg, neg, neg, pp[W:0]}
                    row[off + b] = 'v'
                continue
            sh = off + 2 * (k - 1)
            row[sh] = 'v'                        # neg_prev；sh+1 恒 0
            if k < n - 1:
                for b in range(w + 1):
                    row[sh + 2 + b] = 'v'
                row[sh + w + 3] = 'v'            # ~neg
                row[sh + w + 4] = 1
            elif w % 2 == 1:
                for b in range(w + 1):
                    row[sh + 2 + b] = 'v'
                row[sh + w + 3] = 1
            else:
                for b in range(w):
                    row[sh + 2 + b] = 'v'
    return kinds


def exempt_bits():
    ks = [bit_kinds(w, lanes) for w, lanes in FORMATS.values()]
    out = []
    for i in range(NDIG):
        for b in range(SUM_W):
            vals = {k[i][b] for k in ks}
            if 'v' not in vals and len(vals) == 1:
                out.append("io_out_pp_%d[%d]" % (i, b))
    return out


DECLS = """
function automatic logic [52:0] be_rnd_sig();
  logic [52:0] d;
  d = {$urandom, $urandom};
  if ($urandom_range(0, 1) == 0) begin
    // f16 的四段：[10:0] [23:13] [39:29] [52:42]
    for (int l = 0; l < 4; l++) begin
      int lsb;
      logic [10:0] v;
      lsb = (l == 0) ? 0 : (l == 1) ? 13 : (l == 2) ? 29 : 42;
      case ($urandom_range(0, 7))
        0:       v = 11'h000;
        1:       v = 11'h7ff;
        2:       v = 11'h400;
        3:       v = 11'h001;
        4:       v = 11'h555;
        5:       v = 11'h2aa;
        default: v = 11'($urandom);
      endcase
      d[lsb +: 11] = v;
    end
  end
  return d;
endfunction
"""

STIM = """
@io_in_a = be_rnd_sig();
@io_in_b = be_rnd_sig();
if ($urandom_range(0, 15) != 0) begin
  case ($urandom_range(0, 2))
    0:       begin @io_is_fp64 = 1'b1; @io_is_fp32 = 1'b0; end
    1:       begin @io_is_fp64 = 1'b0; @io_is_fp32 = 1'b1; end
    default: begin @io_is_fp64 = 1'b0; @io_is_fp32 = 1'b0; end
  endcase
end
"""

G = "be_u_gold."
COV = [("fmt_f64", "@io_is_fp64 && !@io_is_fp32"),
       ("fmt_f32", "!@io_is_fp64 && @io_is_fp32"),
       ("fmt_f16", "!@io_is_fp64 && !@io_is_fp32"),
       ("fmt_both", "@io_is_fp64 && @io_is_fp32")]
for i in range(NDIG):
    for bit, nm in ((3, "pos1"), (2, "pos2"), (1, "neg1"), (0, "neg2")):
        if (i == NDIG - 1 and bit < 2) or (i == 0 and bit == 2):
            continue
        COV.append(("d%d_%s" % (i, nm), "%sbooth_4bit_onehot_%d[%d]" % (G, i, bit)))

PAIRS = [
    Pair("BoothEncoderF64F32F16", "be_", clocked=False, stim=STIM, decls=DECLS, cov=COV,
         exempt=exempt_bits(), cov_min=300),
]

HEADER = """自动生成：verif/ut/BoothEncoderF64F32F16/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
BoothEncoderF64F32F16 双例化逐拍比对：golden vs 重写 BoothEncoderF64F32F16_xs，27 个加数逐位 !==。"""

if __name__ == "__main__":
    if "--exempt-count" in sys.argv:
        print(len(exempt_bits()), "of", NDIG * SUM_W)
        sys.exit(0)
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
