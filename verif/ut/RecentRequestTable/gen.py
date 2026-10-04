#!/usr/bin/env python3
"""生成 RecentRequestTable / RecentRequestTable_1 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

两对：golden RecentRequestTable(_1) vs RecentRequestTable(_1)_xs，全部输出逐拍逐位比较。
rrTable（SRAMTemplate_146，shouldReset）复位后要用 256 拍把表清零，期间读写都不 ready ——
所以 reset 只偶尔打（每 ~20000 拍一次），给表足够时间清完、被写满、被命中。
激励偏置（让读口真的命中）：
  * 写地址、读地址都从一个 16 条行的小池子里挑（池里行地址的 hash/tag 两两不同的概率高，
    又足够小，写过的行很快被读到）；testOffset 3/4 时间取 0（直接查写过的那条行）、其余小随机；
  * r.req.valid 约 1/2（读优先压写 ⇒ 读写冲突常发生），w.valid 约 3/4；
  * MBIST / SRAM 控制 DFT 口 15/16 时间钉 0（否则大多数拍在做 MBIST，功能路径没机会走），
    其余时间随机（DFT 透传与 bore 读回也要比到）。
不复位的 resp.{ptr,hit} 保持寄存器：第一次 resp.valid 之后才开始比（arm）。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

DFT = ["boreChildrenBd_bore_re", "boreChildrenBd_bore_we", "boreChildrenBd_bore_ack",
       "boreChildrenBd_bore_selectedOH", "boreChildrenBd_bore_array", "boreChildrenBd_bore_wmask",
       "sigFromSrams_bore_ram_hold", "sigFromSrams_bore_ram_bypass", "sigFromSrams_bore_ram_bp_clken",
       "sigFromSrams_bore_ram_aux_clk", "sigFromSrams_bore_ram_aux_ckbp",
       "sigFromSrams_bore_ram_mcp_hold", "sigFromSrams_bore_cgen"]


def stim(x, aw, ow):
    s = ["@io_w_valid = ($urandom_range(0, 3) != 0);"]
    s.append("@io_w_bits = %sline($urandom_range(0, 15));" % x)
    s.append("@io_r_req_bits_addr = %sline($urandom_range(0, 15));" % x)
    s.append("if ($urandom_range(0, 3) != 0) @io_r_req_bits_testOffset = '0;")
    s.append("else @io_r_req_bits_testOffset = %d'($signed(4'($urandom)));" % ow)
    s.append("if (%smode != 0) begin" % x)
    for d in DFT:
        s.append("  @%s = '0;" % d)
    s.append("end")
    return "\n".join(s)


def decls(x, aw):
    return f"""
logic [{aw-1}:0] {x}pool [16];
initial for (int i = 0; i < 16; i++) {x}pool[i] = {aw}'({{$urandom, $urandom}});
function automatic logic [{aw-1}:0] {x}line(input int unsigned k);
  return {x}pool[k] ^ {aw}'($urandom_range(0, 63));   // 同一行内随机字节偏移
endfunction
"""


def cov(x):
    return [
        ("w_fire", "@io_w_valid && @io_w_ready"),
        ("w_blocked_by_r", "@io_w_valid && @io_r_req_valid"),
        ("resp", "@io_r_resp_valid"),
        ("hit", "@io_r_resp_valid && @io_r_resp_bits_hit"),
        ("miss", "@io_r_resp_valid && !@io_r_resp_bits_hit"),
        ("offset_nz", "@io_r_req_valid && @io_r_req_bits_testOffset != 0"),
        ("reset_mid", "@reset && cyc > 100"),
    ]


PAIRS = []
for top, x, aw, ow in (("RecentRequestTable", "r0_", 48, 7), ("RecentRequestTable_1", "r1_", 50, 10)):
    PAIRS.append(Pair(top, x, clocked=True, stim=stim(x, aw, ow), cov=cov(x), decls=decls(x, aw),
                      reset_period=20000, mode_period=2000, cov_min=5,
                      arm=["@io_r_resp_valid"]))

HEADER = """自动生成：verif/ut/RecentRequestTable/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
RecentRequestTable / RecentRequestTable_1 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
