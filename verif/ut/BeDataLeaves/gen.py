#!/usr/bin/env python3
"""生成 BeDataLeaves 的双例化 UT testbench（tb.sv）。

五对 golden vs 重写 <名>_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍全部输出逐位 !==：
  * VsetModule：vsew/vlmul 全取值域均匀；reserved 多数为 0（否则恒非法）；avl 一半压到 0..300
    （与 vlmax 比较的边界附近），func 的 setVlmax 位与 vsetivli 编码各自打到。
  * strdied / indexedLSNumOfUopTable：输入 5/7 位，均匀随机每拍一组，200k 拍远超 32/128 种取值。
  * IntToFPDataModule：两级使能按 mode 偏置；typeTagOut 含越界的 3；wflags 0/1；rm 含 DYN(111)；
    src 按 mode 在全随机 / 小整数 / 符号边界之间切换。不复位流水寄存器：arm 等两级使能
    各至少一次后再比。
  * AluDataModule：func 一半取 alu_pkg 里的合法 ALUOpType 编码（取自 golden 选择树的分支），
    一半全随机；src1 低 6 位偏置出移位量 0/31/32/63。
用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

VS_STIM = """
if ($urandom_range(0, 7) != 0) @io_in_vtype_reserved = '0;
if ($urandom_range(0, 7) != 0) @io_in_vtype_illegal = 1'b0;
if ($urandom_range(0, 1)) @io_in_avl = 64'($urandom_range(0, 300));
case ($urandom_range(0, 3))
  0: @io_in_func = 9'h0A0 | 9'($urandom_range(0, 1));   // vsetvli（可带 setVlmax）
  1: @io_in_func = 9'h040 | 9'($urandom_range(0, 1));   // vsetvl
  2: @io_in_func = 9'h000 | 9'($urandom_range(0, 1));   // vsetivli
  default: ;
endcase
"""
VS_COV = [
    ("legal", "!@io_out_vconfig_vtype_illegal"),
    ("vl_is_vlmax", "!@io_out_vconfig_vtype_illegal && @io_out_vconfig_vl == @io_out_vlmax && @io_in_avl > 64'(@io_out_vlmax)"),
    ("vl_is_avl", "!@io_out_vconfig_vtype_illegal && @io_in_avl < 64'(@io_out_vlmax) && @io_in_avl != 0"),
    ("setvlmax", "!@io_out_vconfig_vtype_illegal && @io_in_func[0] && (|@io_in_func[7:6]) && @io_in_avl < 64'(@io_out_vlmax)"),
    ("frac_lmul", "!@io_out_vconfig_vtype_illegal && @io_in_vtype_vlmul[2]"),
]

I2F_STIM = """
case (@mode % 4)
  0: begin @regEnables_0 = 1'b1; @regEnables_1 = 1'b1; end
  1: begin @regEnables_0 = ($urandom_range(0, 3) == 0); @regEnables_1 = ($urandom_range(0, 3) == 0); end
  default: ;
endcase
case ($urandom_range(0, 3))
  0: @io_in_src_0 = 64'($signed(16'($urandom)));
  1: @io_in_src_0 = {$urandom_range(0, 1) ? 32'hFFFF_FFFF : 32'h0, 1'($urandom), 31'($urandom)};
  2: @io_in_src_0 = 64'h1 << $urandom_range(0, 63);
  default: ;
endcase
if ($urandom_range(0, 3) == 0) @io_in_fpCtrl_rm = 3'b111;
"""
I2F_COV = [
    ("tag0", "be_i2f_u_gold.s3_tag == 2'd0"),
    ("tag1", "be_i2f_u_gold.s3_tag == 2'd1"),
    ("tag2", "be_i2f_u_gold.s3_tag == 2'd2"),
    ("tag3", "be_i2f_u_gold.s3_tag == 2'd3"),
    ("nx", "@io_out_fflags[0]"),
    ("fmv", "@regEnables_1 && !be_i2f_u_gold.ctrlReg_wflags"),
    ("dyn_rm", "@regEnables_0 && @io_in_fpCtrl_rm == 3'b111"),
]

ALU_OPS = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D,
           0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D,
           0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F,
           0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
           0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4A, 0x4B,
           0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B,
           0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B,
           0x70, 0x71, 0x72, 0x73]
ALU_DECLS = "logic [6:0] alu_ops [%d] = '{%s};" % (len(ALU_OPS), ", ".join("7'h%02X" % o for o in ALU_OPS))
ALU_STIM = """
if ($urandom_range(0, 1)) @io_func = {2'($urandom), alu_ops[$urandom_range(0, $size(alu_ops) - 1)]};
case ($urandom_range(0, 5))
  0: @io_src_1[5:0] = 6'd0;
  1: @io_src_1[5:0] = 6'd31;
  2: @io_src_1[5:0] = 6'd32;
  3: @io_src_1[5:0] = 6'd63;
  default: ;
endcase
if ($urandom_range(0, 7) == 0) @io_src_1 = @io_src_0;
if ($urandom_range(0, 7) == 0) @io_src_1 = '0;
"""
ALU_COV = [("ch%d" % c, "@io_func[6:4] == 3'd%d" % c) for c in range(8)] + [
    ("eq_src", "@io_src_0 == @io_src_1"),
]

PAIRS = [
    Pair("VsetModule", "be_vs_", stim=VS_STIM, cov=VS_COV, cov_min=500,
         exempt=("io_out_vlmax[0]",)),   # vlmax >= VLEN/SEW >= 2，bit0 恒 0
    Pair("strdiedLSNumOfUopTable", "be_st_", cov_min=1),
    Pair("indexedLSNumOfUopTable", "be_ix_", exempt=("out[4]", "out[5]", "out[6]"), cov_min=1),
    Pair("IntToFPDataModule", "be_i2f_", stim=I2F_STIM, cov=I2F_COV, mode_period=300, cov_min=500,
         # 整数转浮点只可能置 OF(bit2) / NX(bit0)；UF/DZ/NV 恒 0（三个转换器 golden 同）
         exempt=("io_out_fflags[1]", "io_out_fflags[3]", "io_out_fflags[4]"),
         arm=("@regEnables_0", "@regEnables_1"), arm_delay=2),
    Pair("AluDataModule", "be_alu_", stim=ALU_STIM, cov=ALU_COV, decls=ALU_DECLS, cov_min=1000),
]

HEADER = """自动生成：verif/ut/BeDataLeaves/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
后端五个数据叶子双例化逐拍比对：golden <名> vs 重写 <名>_xs，全部输出逐位 !==。"""

def tie_clock(txt):
    """IntToFPDataModule 有 clock 无 reset，dual_tb_lib 的 clocked 模式要求两者都有；
    这里按非时钟对生成后把它的 clock 口接回 tb 时钟、删掉随机灌值那一行（两处都必须命中）。"""
    a = txt.count(".clock(be_i2f_clock)")
    b = txt.count("      be_i2f_clock = 1'($urandom);\n")
    if a != 2 or b != 1:
        raise SystemExit("tie_clock: 锚点计数不符 a=%d b=%d" % (a, b))
    txt = txt.replace(".clock(be_i2f_clock)", ".clock(clk)")
    return txt.replace("      be_i2f_clock = 1'($urandom);\n", "")


if __name__ == "__main__":
    txt = tie_clock(render(PAIRS, HEADER))
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
