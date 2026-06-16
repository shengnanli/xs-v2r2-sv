#!/usr/bin/env python3
# =============================================================================
# gen_dtagarray.py —— DuplicatedTagArray UT 脚手架生成器
#   产出: verif/ut/DuplicatedTagArray/variants_xs.sv  (DuplicatedTagArray_xs 镜像)
#         verif/ut/DuplicatedTagArray/tb.sv           (golden vs _xs 双例化逐拍比对)
# 设计源 wrapper 已手写 (rtl/memblock/DuplicatedTagArray_wrapper.sv)，_xs 仅改模块名。
# =============================================================================
import re, os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WRAP = os.path.join(ROOT, "rtl/memblock/DuplicatedTagArray_wrapper.sv")
OUTD = os.path.join(ROOT, "verif/ut/DuplicatedTagArray")
os.makedirs(OUTD, exist_ok=True)

# ---- _xs 镜像：拷贝 wrapper，仅改顶层模块名 DuplicatedTagArray -> DuplicatedTagArray_xs ----
src = open(WRAP).read()
xs = src.replace("module DuplicatedTagArray import", "module DuplicatedTagArray_xs import", 1)
xs = ("// 自动生成: scripts/gen_dtagarray.py —— 勿手改\n"
      "// DuplicatedTagArray_xs: golden 同名 wrapper 的 UT 镜像 (仅模块名加 _xs 后缀)\n"
      + xs)
open(os.path.join(OUTD, "variants_xs.sv"), "w").write(xs)

# ---- 解析 golden 顶层端口 (方向/位宽/名字) ----
gold = open(os.path.join(ROOT, "golden/chisel-rtl/DuplicatedTagArray.sv")).read()
m = re.search(r"module DuplicatedTagArray\((.*?)\);", gold, re.S)
body = m.group(1)
ports = []  # (dir, width, name)
for line in body.split("\n"):
    line = line.strip().rstrip(",")
    if not line:
        continue
    mm = re.match(r"(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)", line)
    if mm:
        d = mm.group(1)
        w = (int(mm.group(2)) - int(mm.group(3)) + 1) if mm.group(2) else 1
        ports.append((d, w, mm.group(4)))

inputs  = [(w, n) for (d, w, n) in ports if d == "input"  and n not in ("clock", "reset")]
outputs = [(w, n) for (d, w, n) in ports if d == "output"]

def decl(w, n):
    return f"  logic [{w-1}:0] {n};" if w > 1 else f"  logic {n};"

# 输出按比对集合: io_resp_* 与 io_read_3_ready, boreChildrenBd_bore_outdata/ack
def is_checked(n):
    return n.startswith("io_resp_") or n in ("io_read_3_ready",)

tb = []
tb.append("// 自动生成: scripts/gen_dtagarray.py —— 勿手改")
tb.append("`timescale 1ns/1ps")
tb.append("module tb;")
tb.append("  int unsigned NVEC = 200000;")
tb.append("  int WARMUP = 300;   // 跳过上电逐组清零 + 复位窗口")
tb.append("  int errors = 0, checks = 0;")
tb.append("  logic clock = 0, reset;")
tb.append("  always #5 clock = ~clock;")
# 输入信号
for w, n in inputs:
    tb.append(decl(w, n))
# 输出双份 (g_/i_)
for w, n in outputs:
    if w > 1:
        tb.append(f"  wire [{w-1}:0] g_{n};  wire [{w-1}:0] i_{n};")
    else:
        tb.append(f"  wire g_{n};  wire i_{n};")

def inst(modname, prefix):
    conns = [".clock(clock)", ".reset(reset)"]
    for w, n in inputs:
        conns.append(f".{n}({n})")
    for w, n in outputs:
        conns.append(f".{n}({prefix}{n})")
    return f"  {modname} {prefix}u (" + ", ".join(conns) + ");"

tb.append(inst("DuplicatedTagArray", "g_"))
tb.append(inst("DuplicatedTagArray_xs", "i_"))

# 逐拍比对任务
tb.append("  task automatic do_check(int t);")
tb.append("    checks++;")
for w, n in outputs:
    if not is_checked(n):
        continue
    tb.append(f"    if (!$isunknown(g_{n}) && (g_{n} !== i_{n})) begin errors++;")
    tb.append(f"      if(errors<=60) $display(\"vec %0d {n} g=%h i=%h\",t,g_{n},i_{n}); end")
tb.append("  endtask")

# 激励: 随机读 4 口 + 偶发写; MBIST 旁带置默认 (mbist 不激活)
tb.append("""
  // MBIST / 旁带信号: 不激活 mbist (req=0), 旁带恒 0 (功能态), 仅验证读写主链
  initial begin
    boreChildrenBd_bore_array=0; boreChildrenBd_bore_all=0; boreChildrenBd_bore_req=0;
    boreChildrenBd_bore_writeen=0; boreChildrenBd_bore_be=0; boreChildrenBd_bore_addr=0;
    boreChildrenBd_bore_indata=0; boreChildrenBd_bore_readen=0; boreChildrenBd_bore_addr_rd=0;
    sigFromSrams_bore_ram_hold=0; sigFromSrams_bore_ram_bypass=0; sigFromSrams_bore_ram_bp_clken=0;
    sigFromSrams_bore_ram_aux_clk=0; sigFromSrams_bore_ram_aux_ckbp=0; sigFromSrams_bore_ram_mcp_hold=0; sigFromSrams_bore_cgen=0;
    sigFromSrams_bore_1_ram_hold=0; sigFromSrams_bore_1_ram_bypass=0; sigFromSrams_bore_1_ram_bp_clken=0;
    sigFromSrams_bore_1_ram_aux_clk=0; sigFromSrams_bore_1_ram_aux_ckbp=0; sigFromSrams_bore_1_ram_mcp_hold=0; sigFromSrams_bore_1_cgen=0;
    sigFromSrams_bore_2_ram_hold=0; sigFromSrams_bore_2_ram_bypass=0; sigFromSrams_bore_2_ram_bp_clken=0;
    sigFromSrams_bore_2_ram_aux_clk=0; sigFromSrams_bore_2_ram_aux_ckbp=0; sigFromSrams_bore_2_ram_mcp_hold=0; sigFromSrams_bore_2_cgen=0;
    sigFromSrams_bore_3_ram_hold=0; sigFromSrams_bore_3_ram_bypass=0; sigFromSrams_bore_3_ram_bp_clken=0;
    sigFromSrams_bore_3_ram_aux_clk=0; sigFromSrams_bore_3_ram_aux_ckbp=0; sigFromSrams_bore_3_ram_mcp_hold=0; sigFromSrams_bore_3_cgen=0;
    sigFromSrams_bore_4_ram_hold=0; sigFromSrams_bore_4_ram_bypass=0; sigFromSrams_bore_4_ram_bp_clken=0;
    sigFromSrams_bore_4_ram_aux_clk=0; sigFromSrams_bore_4_ram_aux_ckbp=0; sigFromSrams_bore_4_ram_mcp_hold=0; sigFromSrams_bore_4_cgen=0;
    sigFromSrams_bore_5_ram_hold=0; sigFromSrams_bore_5_ram_bypass=0; sigFromSrams_bore_5_ram_bp_clken=0;
    sigFromSrams_bore_5_ram_aux_clk=0; sigFromSrams_bore_5_ram_aux_ckbp=0; sigFromSrams_bore_5_ram_mcp_hold=0; sigFromSrams_bore_5_cgen=0;
    sigFromSrams_bore_6_ram_hold=0; sigFromSrams_bore_6_ram_bypass=0; sigFromSrams_bore_6_ram_bp_clken=0;
    sigFromSrams_bore_6_ram_aux_clk=0; sigFromSrams_bore_6_ram_aux_ckbp=0; sigFromSrams_bore_6_ram_mcp_hold=0; sigFromSrams_bore_6_cgen=0;
    sigFromSrams_bore_7_ram_hold=0; sigFromSrams_bore_7_ram_bypass=0; sigFromSrams_bore_7_ram_bp_clken=0;
    sigFromSrams_bore_7_ram_aux_clk=0; sigFromSrams_bore_7_ram_aux_ckbp=0; sigFromSrams_bore_7_ram_mcp_hold=0; sigFromSrams_bore_7_cgen=0;
  end

  // 随机激励: 4 读口 valid/idx + 偶发写 (idx/way_en/tag)
  task automatic drive();
    io_read_0_valid = $urandom; io_read_0_bits_idx = $urandom;
    io_read_1_valid = $urandom; io_read_1_bits_idx = $urandom;
    io_read_2_valid = $urandom; io_read_2_bits_idx = $urandom;
    io_read_3_valid = $urandom; io_read_3_bits_idx = $urandom;
    io_write_valid    = ($urandom % 4 == 0);  // 25% 写
    io_write_bits_idx = $urandom;
    io_write_bits_way_en = $urandom;
    io_write_bits_tag = {$urandom, $urandom};
  endtask

  initial begin
    reset = 1;
    io_read_0_valid=0; io_read_1_valid=0; io_read_2_valid=0; io_read_3_valid=0;
    io_read_0_bits_idx=0; io_read_1_bits_idx=0; io_read_2_bits_idx=0; io_read_3_bits_idx=0;
    io_write_valid=0; io_write_bits_idx=0; io_write_bits_way_en=0; io_write_bits_tag=0;
    repeat (20) @(posedge clock);
    reset = 0;
    for (int t = 0; t < NVEC; t++) begin
      drive();
      @(posedge clock);
      #1;
      if (t >= WARMUP) do_check(t);
    end
    if (errors == 0) $display("TEST PASSED  checks=%0d errors=%0d", checks, errors);
    else             $display("TEST FAILED  checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule
""")
open(os.path.join(OUTD, "tb.sv"), "w").write("\n".join(tb))
print("generated variants_xs.sv + tb.sv in", OUTD)
