#!/usr/bin/env python3
# =============================================================================
# gen_regfile.py —— 物理寄存器堆分片(IntRegFilePart0-3 / FpRegFilePart0-3)
# 的 golden 同名 wrapper、UT 用 *_xs 变体、双例化 tb 的机械生成器。
#
# 可读核 rtl/backend/RegFilePart.sv(xs_RegFilePart_core)是手写的;本脚本只负责把
# golden 扁平端口(io_readPorts_N_addr/data、io_writePorts_N_*、io_debug_rports_N_*)
# 机械地打包成核的数组端口,并生成对比 tb。8 个 Part 同构,仅参数(NUM_PREGS/
# NUM_WRITE/HAS_ZERO)不同。
#
# 产出:
#   rtl/backend/<Mod>_wrapper.sv      golden 同名 wrapper(FM impl 侧)
#   verif/ut/<Mod>/variants_xs.sv     UT 用 <Mod>_xs(改名,避免与 golden 顶层撞名)
#   verif/ut/<Mod>/tb.sv              双例化逐拍比对 tb
#   verif/ut/<Mod>/Makefile           UT/FM 驱动
# =============================================================================
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RTL  = os.path.join(ROOT, "rtl", "backend")
VERIF= os.path.join(ROOT, "verif", "ut")

# 各分片公共参数
NUM_READ   = 11
NUM_DEBUG  = 32
DATA_WIDTH = 16
ADDR_WIDTH = 8

# (模块名, NUM_PREGS, NUM_WRITE, HAS_ZERO)
INT_PARTS = [(f"IntRegFilePart{i}", 224, 8, 1) for i in range(4)]
FP_PARTS  = [(f"FpRegFilePart{i}",  192, 6, 0) for i in range(4)]
ALL_PARTS = INT_PARTS + FP_PARTS


def port_decls(num_write):
    """golden 扁平端口声明(与 golden 顺序一致:read, write, debug)。"""
    lines = ["  input         clock,", "  input         reset,"]
    for r in range(NUM_READ):
        lines.append(f"  input  [{ADDR_WIDTH-1}:0]  io_readPorts_{r}_addr,")
        lines.append(f"  output [{DATA_WIDTH-1}:0] io_readPorts_{r}_data,")
    for w in range(num_write):
        lines.append(f"  input         io_writePorts_{w}_wen,")
        lines.append(f"  input  [{ADDR_WIDTH-1}:0]  io_writePorts_{w}_addr,")
        lines.append(f"  input  [{DATA_WIDTH-1}:0] io_writePorts_{w}_data,")
    for d in range(NUM_DEBUG):
        lines.append(f"  input  [{ADDR_WIDTH-1}:0]  io_debug_rports_{d}_addr,")
        comma = "" if d == NUM_DEBUG - 1 else ","
        lines.append(f"  output [{DATA_WIDTH-1}:0] io_debug_rports_{d}_data{comma}")
    return "\n".join(lines)


def body(num_pregs, num_write, has_zero):
    """把扁平端口打包进核的数组端口。"""
    L = []
    # read addr 打包
    ra = ", ".join(f"io_readPorts_{r}_addr" for r in range(NUM_READ - 1, -1, -1))
    L.append(f"  wire [{NUM_READ-1}:0][{ADDR_WIDTH-1}:0] rd_addr = {{{ra}}};")
    # write 打包
    we = ", ".join(f"io_writePorts_{w}_wen" for w in range(num_write - 1, -1, -1))
    L.append(f"  wire [{num_write-1}:0] wr_wen = {{{we}}};")
    wa = ", ".join(f"io_writePorts_{w}_addr" for w in range(num_write - 1, -1, -1))
    L.append(f"  wire [{num_write-1}:0][{ADDR_WIDTH-1}:0] wr_addr = {{{wa}}};")
    wd = ", ".join(f"io_writePorts_{w}_data" for w in range(num_write - 1, -1, -1))
    L.append(f"  wire [{num_write-1}:0][{DATA_WIDTH-1}:0] wr_data = {{{wd}}};")
    # debug addr 打包
    da = ", ".join(f"io_debug_rports_{d}_addr" for d in range(NUM_DEBUG - 1, -1, -1))
    L.append(f"  wire [{NUM_DEBUG-1}:0][{ADDR_WIDTH-1}:0] dbg_addr = {{{da}}};")
    # 输出 vec
    L.append(f"  wire [{NUM_READ-1}:0][{DATA_WIDTH-1}:0] rd_data;")
    L.append(f"  wire [{NUM_DEBUG-1}:0][{DATA_WIDTH-1}:0] dbg_data;")
    L.append("")
    # 例化核
    L.append("  xs_RegFilePart_core #(")
    L.append(f"    .NUM_PREGS({num_pregs}), .NUM_READ({NUM_READ}), .NUM_WRITE({num_write}),")
    L.append(f"    .NUM_DEBUG({NUM_DEBUG}), .DATA_WIDTH({DATA_WIDTH}), .ADDR_WIDTH({ADDR_WIDTH}),")
    L.append(f"    .HAS_ZERO({has_zero})")
    L.append("  ) u_core (")
    L.append("    .clock(clock), .reset(reset),")
    L.append("    .read_addr(rd_addr), .read_data(rd_data),")
    L.append("    .write_wen(wr_wen), .write_addr(wr_addr), .write_data(wr_data),")
    L.append("    .debug_addr(dbg_addr), .debug_data(dbg_data)")
    L.append("  );")
    L.append("")
    # 拆回扁平输出
    for r in range(NUM_READ):
        L.append(f"  assign io_readPorts_{r}_data = rd_data[{r}];")
    for d in range(NUM_DEBUG):
        L.append(f"  assign io_debug_rports_{d}_data = dbg_data[{d}];")
    return "\n".join(L)


def gen_module(modname, suffix, num_pregs, num_write, has_zero):
    head = (
        "// 自动生成：scripts/gen_regfile.py —— 勿手改\n"
        "// golden 同名扁平端口 → 可读核 xs_RegFilePart_core 的机械适配层\n"
        f"module {modname}{suffix}(\n"
        f"{port_decls(num_write)}\n"
        ");\n"
    )
    return head + body(num_pregs, num_write, has_zero) + "\nendmodule\n"


def gen_tb(modname, num_pregs, num_write, has_zero):
    """双例化(golden vs _xs)逐拍比对 11 读口 + 32 debug 口。"""
    decl = []
    conn_common = []
    # inputs
    decl.append(f"  logic [{ADDR_WIDTH-1}:0] io_readPorts_addr [{NUM_READ}];")
    for r in range(NUM_READ):
        conn_common.append(f".io_readPorts_{r}_addr(io_readPorts_addr[{r}])")
    decl.append(f"  logic io_writePorts_wen [{num_write}];")
    decl.append(f"  logic [{ADDR_WIDTH-1}:0] io_writePorts_addr [{num_write}];")
    decl.append(f"  logic [{DATA_WIDTH-1}:0] io_writePorts_data [{num_write}];")
    for w in range(num_write):
        conn_common.append(f".io_writePorts_{w}_wen(io_writePorts_wen[{w}])")
        conn_common.append(f".io_writePorts_{w}_addr(io_writePorts_addr[{w}])")
        conn_common.append(f".io_writePorts_{w}_data(io_writePorts_data[{w}])")
    decl.append(f"  logic [{ADDR_WIDTH-1}:0] io_debug_rports_addr [{NUM_DEBUG}];")
    for d in range(NUM_DEBUG):
        conn_common.append(f".io_debug_rports_{d}_addr(io_debug_rports_addr[{d}])")
    # outputs (g_/i_)
    decl.append(f"  logic [{DATA_WIDTH-1}:0] g_read [{NUM_READ}];")
    decl.append(f"  logic [{DATA_WIDTH-1}:0] i_read [{NUM_READ}];")
    decl.append(f"  logic [{DATA_WIDTH-1}:0] g_dbg [{NUM_DEBUG}];")
    decl.append(f"  logic [{DATA_WIDTH-1}:0] i_dbg [{NUM_DEBUG}];")

    g_conn = list(conn_common) + [f".io_readPorts_{r}_data(g_read[{r}])" for r in range(NUM_READ)] \
             + [f".io_debug_rports_{d}_data(g_dbg[{d}])" for d in range(NUM_DEBUG)]
    i_conn = list(conn_common) + [f".io_readPorts_{r}_data(i_read[{r}])" for r in range(NUM_READ)] \
             + [f".io_debug_rports_{d}_data(i_dbg[{d}])" for d in range(NUM_DEBUG)]

    decl_s = "\n".join(decl)
    g_inst = f"  {modname} g_u (.clock(clk), .reset(rst), " + ", ".join(g_conn) + ");"
    i_inst = f"  {modname}_xs i_u (.clock(clk), .reset(rst), " + ", ".join(i_conn) + ");"

    # 地址约束:0..numPregs-1(避免越界 padding 的 don't-care 影响,且覆盖 x0/全部寄存器)
    addr_hi = num_pregs - 1

    return f"""// 自动生成：scripts/gen_regfile.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

{decl_s}

{g_inst}
{i_inst}

  // 随机地址:0..{addr_hi}(覆盖全部物理寄存器,含 x0)
  function automatic logic [{ADDR_WIDTH-1}:0] rnd_addr();
    return {ADDR_WIDTH}'($urandom_range(0,{addr_hi}));
  endfunction

  always @(negedge clk) begin
    if (rst) begin
      for (int r = 0; r < {NUM_READ}; r++) io_readPorts_addr[r] <= 0;
      for (int w = 0; w < {num_write}; w++) begin
        io_writePorts_wen[w] <= 0; io_writePorts_addr[w] <= 0; io_writePorts_data[w] <= 0;
      end
      for (int d = 0; d < {NUM_DEBUG}; d++) io_debug_rports_addr[d] <= 0;
    end else begin
      for (int r = 0; r < {NUM_READ}; r++) io_readPorts_addr[r] <= rnd_addr();
      // 写口:为遵守 golden assert(同拍不写同地址),每口分配互斥的地址区间。
      for (int w = 0; w < {num_write}; w++) begin
        io_writePorts_wen[w]  <= ($urandom_range(0,99) < 60);
        io_writePorts_addr[w] <= rnd_addr();
        io_writePorts_data[w] <= {DATA_WIDTH}'($urandom);
      end
      // 强制写地址两两不同(简单去重:第 w 口若与前面撞,则关其 wen)
      for (int d = 0; d < {NUM_DEBUG}; d++) io_debug_rports_addr[d] <= rnd_addr();
    end
  end

  // 同拍写同地址去重:在驱动后、时钟沿前调整(组合保证 g/i 看到同一激励)。
  // golden 对此情形有 assert,但 SYNTHESIS 下 assert 关闭;为语义清晰仍做去重。
  always @(io_writePorts_wen, io_writePorts_addr) begin
    for (int a = 0; a < {num_write}; a++)
      for (int b = a+1; b < {num_write}; b++)
        if (io_writePorts_wen[a] && io_writePorts_wen[b] &&
            io_writePorts_addr[a] == io_writePorts_addr[b])
          io_writePorts_wen[b] = 1'b0;
  end

  task automatic check(input string nm, input logic [{DATA_WIDTH-1}:0] g, input logic [{DATA_WIDTH-1}:0] i);
    checks++;
    if (!$isunknown(g) && g !== i) begin
      errors++;
      if (errors <= 80) $display("[%0t] %s g=%h i=%h", $time, nm, g, i);
    end
  endtask

  always @(negedge clk) if (!rst) begin
    #4;
    for (int r = 0; r < {NUM_READ}; r++) check($sformatf("read_%0d", r), g_read[r], i_read[r]);
    for (int d = 0; d < {NUM_DEBUG}; d++) check($sformatf("debug_%0d", d), g_dbg[d], i_dbg[d]);
  end

  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
"""


def gen_makefile(modname):
    return f"""MODULE = {modname}

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包。UT 不编 {modname}_wrapper.sv(模块名与 golden 顶层冲突),
# 改用 variants_xs.sv 里的 {modname}_xs(同 wrapper 逻辑改名)。
RTL_SRCS = $(RTL_DIR)/backend/regfile_pkg.sv \\
           $(RTL_DIR)/backend/RegFilePart.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/{modname}.sv

# FM：golden {modname} vs 手写同名 wrapper(→核)。纯寄存器堆叶子,无子模块。
WRAPPER_SRCS = $(RTL_DIR)/backend/regfile_pkg.sv \\
               $(RTL_DIR)/backend/RegFilePart.sv \\
               $(RTL_DIR)/backend/{modname}_wrapper.sv
FM_VARIANTS = {modname}

include ../../../scripts/ut_common.mk

# golden 含 $fatal 断言;UT 关掉以免随机激励触发
VCS += +define+SYNTHESIS
"""


def main():
    # 1) 各 Part 的 golden 同名 wrapper(FM impl 侧)
    for mod, npr, nw, hz in ALL_PARTS:
        with open(os.path.join(RTL, f"{mod}_wrapper.sv"), "w") as f:
            f.write(gen_module(mod, "", npr, nw, hz))

    # 2) UT 工件:Int part0 与 Fp part0 各建一套(其余同构,在文档注明)
    for mod, npr, nw, hz in [INT_PARTS[0], FP_PARTS[0]]:
        d = os.path.join(VERIF, mod)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "variants_xs.sv"), "w") as f:
            f.write(gen_module(mod, "_xs", npr, nw, hz))
        with open(os.path.join(d, "tb.sv"), "w") as f:
            f.write(gen_tb(mod, npr, nw, hz))
        with open(os.path.join(d, "Makefile"), "w") as f:
            f.write(gen_makefile(mod))

    print("generated 8 wrappers + UT(IntRegFilePart0, FpRegFilePart0)")


if __name__ == "__main__":
    main()
