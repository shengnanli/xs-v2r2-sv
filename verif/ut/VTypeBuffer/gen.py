#!/usr/bin/env python3
"""生成 VTypeBuffer 的双例化 UT testbench（tb.sv）。

golden VTypeBuffer vs 重写 VTypeBuffer_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍全部输出逐位 !==。
激励按 mode 分相：
  FILL   ：vset 分配密、commitSize=0 —— 队列涨满，逼出 canEnq / canEnqForDispatch 拉低；
  DRAIN  ：不分配、commitSize 0..8 —— 提交侧把队列抽空；
  CHURN  ：分配与提交都中等；
  其余   ：全随机。
冲刷 redirect 稀疏（1/48），useSnpt 一半；walkEnd 1/6；snpt enq/deq 1/8；walkSize 多数 0..6。
不复位存储：64 项存储体与两个快照生成器的 4 个槽不复位，random 档两侧初值不同、而
commitVType 的数据输出不看 valid 直接读存储体。所以 arm = 存储体 64 项都被写过一遍
（tb 按 golden 写口自己记位图）且快照 4 个槽都写过，之后才开始比。
覆盖：三态都进过、special walk→walk、walk→idle、useSnapshot、walkToArchVType、hasVsetvl、
canEnq=0、canEnqForDispatch=0、enqPtr 回绕。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

G = "vb_u_gold."
DECLS = """
logic [63:0] vb_wmask = '0;
always @(posedge clk) begin
  if (vb_u_gold.vtypeBuffer.io_wen_0) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_0] <= 1'b1;
  if (vb_u_gold.vtypeBuffer.io_wen_1) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_1] <= 1'b1;
  if (vb_u_gold.vtypeBuffer.io_wen_2) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_2] <= 1'b1;
  if (vb_u_gold.vtypeBuffer.io_wen_3) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_3] <= 1'b1;
  if (vb_u_gold.vtypeBuffer.io_wen_4) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_4] <= 1'b1;
  if (vb_u_gold.vtypeBuffer.io_wen_5) vb_wmask[vb_u_gold.vtypeBuffer.io_waddr_5] <= 1'b1;
end
"""

STIM = """
@io_redirect_valid = ($urandom_range(0, 47) == 0);
@io_fromRob_walkEnd = ($urandom_range(0, 5) == 0);
@io_fromRob_walkSize = ($urandom_range(0, 3) == 0) ? 6'($urandom) : 6'($urandom_range(0, 6));
@io_snpt_snptEnq = ($urandom_range(0, 7) == 0);
@io_snpt_snptDeq = ($urandom_range(0, 7) == 0);
case (@mode % 4)
  0: begin  // FILL
    @io_fromRob_commitSize = 6'd0;
    @io_req_0_bits_isVset = 1'b1; @io_req_0_bits_lastUop = 1'b1;
    @io_req_3_bits_isVset = 1'b1; @io_req_3_bits_lastUop = 1'b1;
  end
  1: begin  // DRAIN
    @io_fromRob_commitSize = 6'($urandom_range(0, 8));
    {@io_req_5_valid, @io_req_4_valid, @io_req_3_valid, @io_req_2_valid, @io_req_1_valid, @io_req_0_valid} = 6'd0;
  end
  2: begin  // CHURN
    @io_fromRob_commitSize = 6'($urandom_range(0, 3));
  end
  default: ;
endcase
"""

COV = [
    ("st_spcl", G + "state == 2'd1"),
    ("st_walk", G + "state == 2'd2"),
    ("spcl_to_walk", G + "state == 2'd1 && " + G + "stateNext == 2'd2"),
    ("walk_to_idle", G + "state == 2'd2 && " + G + "stateNext == 2'd0"),
    ("use_snapshot", G + "useSnapshot"),
    ("walk_to_arch", "@io_toDecode_walkToArchVType"),
    ("walk_vtype", "@io_toDecode_walkVType_valid"),
    ("commit_vtype", "@io_toDecode_commitVType_vtype_valid"),
    ("has_vsetvl", "@io_toDecode_commitVType_hasVsetvl"),
    ("full_canenq", "!@io_canEnq && " + G + "state == 2'd0"),
    ("full_dispatch", "!@io_canEnqForDispatch && @io_canEnq"),
    ("enq_wrap", G + "enqPtrVec_0_flag"),
]

ARM = ["&vb_wmask"] + [G + "walkPtrSnapshots_snapshotGen._GEN_%d" % k for k in range(4)]

PAIRS = [
    Pair("VTypeBuffer", "vb_", clocked=True, stim=STIM, cov=COV, decls=DECLS, arm=ARM,
         mode_period=400, reset_period=60000, cov_min=100),
]

HEADER = """自动生成：verif/ut/VTypeBuffer/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
VTypeBuffer 双例化逐拍比对：golden VTypeBuffer vs 重写 VTypeBuffer_xs，全部输出逐位 !==。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
