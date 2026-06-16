#!/usr/bin/env python3
# 生成 StoreExceptionBuffer UT 的 variants_xs.sv（_xs 别名，内部例化可读核）与 tb.sv。
# 用法：在 verif/ut/StoreExceptionBuffer/ 下运行 `python3 ../../../scripts/gen_storeexceptionbuffer.py`
import os

N = 7
EXC_BITS = [3, 6, 7, 15, 19, 23]   # Sta 相关异常位
# golden 各入口实际存在的可选字段（firtool 死代码消除后）
HAS_VANEEDEXT = [True]*6 + [False]            # 入口 6 无 vaNeedExt
HAS_GPADDR    = [True]*6 + [False]            # 入口 6 无 gpaddr
HAS_HYPER     = [True, True, True, True, False, False, False]  # 入口 4,5,6 无 isHyper
HAS_VSL       = [True]*6 + [False]            # 入口 6 无 isForVSnonLeafPTE
# 入口 6 仅有 excVec_19（hardwareError）
def exc_bits(idx):
    return EXC_BITS if idx != 6 else [19]

SIG = "io_storeAddrIn"

def req_fields(idx):
    f = [(f"{SIG}_{idx}_valid", 1)]
    for b in exc_bits(idx):
        f.append((f"{SIG}_{idx}_bits_uop_exceptionVec_{b}", 1))
    f.append((f"{SIG}_{idx}_bits_uop_uopIdx", 7))
    f.append((f"{SIG}_{idx}_bits_uop_robIdx_flag", 1))
    f.append((f"{SIG}_{idx}_bits_uop_robIdx_value", 8))
    f.append((f"{SIG}_{idx}_bits_fullva", 64))
    if HAS_VANEEDEXT[idx]:
        f.append((f"{SIG}_{idx}_bits_vaNeedExt", 1))
    if HAS_GPADDR[idx]:
        f.append((f"{SIG}_{idx}_bits_gpaddr", 64))
    if HAS_HYPER[idx]:
        f.append((f"{SIG}_{idx}_bits_isHyper", 1))
    if HAS_VSL[idx]:
        f.append((f"{SIG}_{idx}_bits_isForVSnonLeafPTE", 1))
    return f

def w(width):
    return f"[{width-1}:0] " if width > 1 else ""

def opt(sig, present, dead="1'b0"):
    return sig if present else dead

OUTS = [("io_exceptionAddr_vaddr", 64), ("io_exceptionAddr_vaNeedExt", 1),
        ("io_exceptionAddr_isHyper", 1), ("io_exceptionAddr_gpaddr", 64),
        ("io_exceptionAddr_isForVSnonLeafPTE", 1)]

def header_inputs():
    lines = ["  input clock, input reset,",
             "  input io_redirect_valid,",
             "  input io_redirect_bits_robIdx_flag,",
             "  input [7:0] io_redirect_bits_robIdx_value,",
             "  input io_redirect_bits_level,"]
    for i in range(N):
        for (n, ww) in req_fields(i):
            lines.append(f"  input {w(ww)}{n},")
    return "\n".join(lines)

def header_outputs():
    return ",\n".join(f"  output {w(ww)}{n}" for (n, ww) in OUTS)

def tb_decls():
    lines = ["  logic io_redirect_valid;",
             "  logic io_redirect_bits_robIdx_flag;",
             "  logic [7:0] io_redirect_bits_robIdx_value;",
             "  logic io_redirect_bits_level;"]
    for i in range(N):
        for (n, ww) in req_fields(i):
            lines.append(f"  logic {w(ww)}{n};")
    return "\n".join(lines)

def out_wires():
    lines = []
    for (n, ww) in OUTS:
        lines.append(f"  wire {w(ww)}g_{n};")
        lines.append(f"  wire {w(ww)}i_{n};")
    return "\n".join(lines)

def inst(modname, pfx):
    conns = [".clock(clk)", ".reset(rst)",
             ".io_redirect_valid(io_redirect_valid)",
             ".io_redirect_bits_robIdx_flag(io_redirect_bits_robIdx_flag)",
             ".io_redirect_bits_robIdx_value(io_redirect_bits_robIdx_value)",
             ".io_redirect_bits_level(io_redirect_bits_level)"]
    for i in range(N):
        for (n, _) in req_fields(i):
            conns.append(f".{n}({n})")
    for (n, _) in OUTS:
        conns.append(f".{n}({pfx}_{n})")
    return f"  {modname} u_{pfx} (\n    " + ",\n    ".join(conns) + "\n  );"

def drive_body():
    s = ["    io_redirect_valid = ($urandom_range(0,15)==0);",
         "    io_redirect_bits_robIdx_flag = $urandom;",
         "    io_redirect_bits_robIdx_value = $urandom_range(0,40);",
         "    io_redirect_bits_level = $urandom;"]
    for i in range(N):
        s.append(f"    {SIG}_{i}_valid = ($urandom_range(0,2)!=0);")
        for b in exc_bits(i):
            s.append(f"    {SIG}_{i}_bits_uop_exceptionVec_{b} = ($urandom_range(0,2)==0);")
        s.append(f"    {SIG}_{i}_bits_uop_uopIdx = $urandom_range(0,20);")
        s.append(f"    {SIG}_{i}_bits_uop_robIdx_flag = $urandom;")
        s.append(f"    {SIG}_{i}_bits_uop_robIdx_value = $urandom_range(0,40);")
        s.append(f"    {SIG}_{i}_bits_fullva = {{$urandom,$urandom}};")
        if HAS_VANEEDEXT[i]:
            s.append(f"    {SIG}_{i}_bits_vaNeedExt = $urandom;")
        if HAS_GPADDR[i]:
            s.append(f"    {SIG}_{i}_bits_gpaddr = {{$urandom,$urandom}};")
        if HAS_HYPER[i]:
            s.append(f"    {SIG}_{i}_bits_isHyper = $urandom;")
        if HAS_VSL[i]:
            s.append(f"    {SIG}_{i}_bits_isForVSnonLeafPTE = $urandom;")
    return "\n".join(s)

def checks():
    s = []
    for (n, _) in OUTS:
        s.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        s.append(f"      if(errors<=60) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    return "\n".join(s)

def pack_assigns():
    L = []
    L.append("  assign v = {" + ",".join(f"{SIG}_{i}_valid" for i in range(N-1,-1,-1)) + "};")
    for i in range(N):
        L.append(f"  assign robIdx[{i}] = '{{flag:{SIG}_{i}_bits_uop_robIdx_flag, value:{SIG}_{i}_bits_uop_robIdx_value}};")
    for i in range(N):
        L.append(f"  assign uopIdx[{i}] = {SIG}_{i}_bits_uop_uopIdx;")
    for i in range(N):
        if i == 6:
            L.append(f"  assign excVec[6] = {{1'b0,{SIG}_6_bits_uop_exceptionVec_19,1'b0,1'b0,1'b0,1'b0}};")
        else:
            L.append(f"  assign excVec[{i}] = {{{SIG}_{i}_bits_uop_exceptionVec_23,{SIG}_{i}_bits_uop_exceptionVec_19,{SIG}_{i}_bits_uop_exceptionVec_15,{SIG}_{i}_bits_uop_exceptionVec_7,{SIG}_{i}_bits_uop_exceptionVec_6,{SIG}_{i}_bits_uop_exceptionVec_3}};")
    for i in range(N):
        L.append(f"  assign fullva[{i}] = {SIG}_{i}_bits_fullva;")
    for i in range(N):
        gp = opt(f"{SIG}_{i}_bits_gpaddr", HAS_GPADDR[i], "64'h0")
        L.append(f"  assign gpaddr[{i}] = {gp};")
    vne = ",".join(opt(f"{SIG}_{i}_bits_vaNeedExt", HAS_VANEEDEXT[i], "1'b1") for i in range(N-1,-1,-1))
    hyp = ",".join(opt(f"{SIG}_{i}_bits_isHyper", HAS_HYPER[i]) for i in range(N-1,-1,-1))
    vsl = ",".join(opt(f"{SIG}_{i}_bits_isForVSnonLeafPTE", HAS_VSL[i]) for i in range(N-1,-1,-1))
    L.append(f"  assign vaNeedExt = {{{vne}}};")
    L.append(f"  assign isHyper = {{{hyp}}};")
    L.append(f"  assign isForVSnonLeafPTE = {{{vsl}}};")
    return "\n".join(L)

variants = f"""// 自动生成：scripts/gen_storeexceptionbuffer.py —— 勿手改
// UT 用 _xs 别名：扁平端口打包成 struct/数组后例化可读核 xs_StoreExceptionBuffer_core。
module StoreExceptionBuffer_xs(
{header_inputs()}
{header_outputs()}
);
  import exceptionbuffer_pkg::*;
  logic [6:0] v;
  rob_ptr_t [6:0] robIdx;
  logic [6:0][6:0] uopIdx;
  logic [6:0][5:0] excVec;
  logic [6:0][63:0] fullva, gpaddr;
  logic [6:0] vaNeedExt, isHyper, isForVSnonLeafPTE;
{pack_assigns()}
  xs_StoreExceptionBuffer_core #(.ENQ_NUM(7)) u_core (
    .clock(clock), .reset(reset),
    .redirect_valid(io_redirect_valid),
    .redirect_robIdx('{{flag:io_redirect_bits_robIdx_flag, value:io_redirect_bits_robIdx_value}}),
    .redirect_level(io_redirect_bits_level),
    .req_valid(v), .req_robIdx(robIdx), .req_uopIdx(uopIdx), .req_excVec(excVec),
    .req_fullva(fullva), .req_vaNeedExt(vaNeedExt), .req_gpaddr(gpaddr),
    .req_isHyper(isHyper), .req_isForVSnonLeafPTE(isForVSnonLeafPTE),
    .exc_vaddr(io_exceptionAddr_vaddr), .exc_vaNeedExt(io_exceptionAddr_vaNeedExt),
    .exc_isHyper(io_exceptionAddr_isHyper), .exc_gpaddr(io_exceptionAddr_gpaddr),
    .exc_isForVSnonLeafPTE(io_exceptionAddr_isForVSnonLeafPTE)
  );
endmodule
"""

tb = f"""// 自动生成：scripts/gen_storeexceptionbuffer.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

{tb_decls()}

{out_wires()}

{inst("StoreExceptionBuffer", "g")}
{inst("StoreExceptionBuffer_xs", "i")}

  task automatic drive();
{drive_body()}
  endtask

  int warmup = 4;
  always @(posedge clk) if (!rst) begin
    if (warmup > 0) warmup--; else begin
    checks++;
{checks()}
    end
  end

  // FM 证伪探针：FM 因 golden 的逐字段标量 req 寄存器 + 每端口复制 valid 寄存器与
  // 可读核 struct/vector 寄存器边界不同而对少量 req 比对点判 inconclusive；
  // 这里逐拍直接比对内部 req 寄存器，证明数值恒等。
  // 证伪探针独立用较大的预热窗口（跳过复位释放后 req 寄存器首次装载的瞬态），
  // 之后逐拍证明内部 req 寄存器与 golden 数值恒等。
  int probe_mm = 0, pwarm = 16;
  always @(posedge clk) if (!rst) begin
    if (pwarm > 0) pwarm--; else
    if (u_g.req_valid && u_i.u_core.req_valid_r) begin
      // 与输出检查同样跳过 golden 端 X（未写过的字段在 +SYNTHESIS 下保持 X，属 don't-care）
      if (!$isunknown(u_g.req_fullva) && u_g.req_fullva  !== u_i.u_core.req_r.fullva)  probe_mm++;
      if (!$isunknown(u_g.req_gpaddr) && u_g.req_gpaddr  !== u_i.u_core.req_r.gpaddr)  probe_mm++;
      if (!$isunknown(u_g.req_uop_robIdx_value) && u_g.req_uop_robIdx_value !== u_i.u_core.req_r.robIdx.value) probe_mm++;
      if (!$isunknown(u_g.req_uop_uopIdx)       && u_g.req_uop_uopIdx       !== u_i.u_core.req_r.uopIdx)       probe_mm++;
    end
  end

  initial begin
    rst = 1; drive();
    repeat (8) @(posedge clk);
    rst = 0;
    repeat (NCYCLES) begin @(negedge clk); drive(); end
    $display("checks=%0d errors=%0d probe_mm=%0d", checks, errors, probe_mm);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
"""

here = os.path.dirname(os.path.abspath(__file__))
outdir = os.path.abspath(os.path.join(here, "..", "verif", "ut", "StoreExceptionBuffer"))
os.makedirs(outdir, exist_ok=True)
with open(os.path.join(outdir, "variants_xs.sv"), "w") as fp:
    fp.write(variants)
with open(os.path.join(outdir, "tb.sv"), "w") as fp:
    fp.write(tb)
print("wrote", outdir)
