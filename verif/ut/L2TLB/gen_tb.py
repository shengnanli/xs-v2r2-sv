#!/usr/bin/env python3
"""
tb.sv 生成器 —— L2TLB 双例化逐拍比对 testbench。

L2TLB 有 376 个端口（224 入 / 152 出），手写 tb 不现实，这里按 G1 golden 的端口表
机械生成：golden `L2TLB` 与重写 `L2TLB_xs` 吃同一份激励，每拍比全部 152 个输出。

激励分三类：
  * 功能输入（csr / sfence / tlb 请求 / TileLink 握手）：随机 + 定向；
  * TileLink D 通道：带**在途请求跟踪**的应答模型 —— 只对真正发出过的 source
    回数据，且按 2 beat 返回。纯随机 D 通道会让三个遍历器几乎永远收不到正确 id 的
    响应，走不进 refill/merge 路径，UT 就只测了个复位态。
  * DFT/MBIST 输入（176 根 bore/cgen）：钉 0（功能模式）。它们在本层是**纯透传**，
    没有逻辑；随机翻转只会把内部 SRAM 打进测试态，反而盖住功能路径。
    这一段的等价性交给 FM（透传线在 FM 里是实打实的比较点），不靠 UT。

用法：python3 gen_tb.py   （在本目录下跑，输出 tb.sv）
"""
import re
from pathlib import Path

GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl/L2TLB.sv")
TOP = "L2TLB"


def parse_ports():
    s = GOLDEN.read_text()
    m = re.search(rf"^module {TOP}\((.*?)\n\);", s, re.S | re.M)
    out = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            out.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return out


PORTS = parse_ports()
INS = [(w, n) for d, w, n in PORTS if d == "input" and n not in ("clock", "reset")]
OUTS = [(w, n) for d, w, n in PORTS if d == "output"]


def is_dft(n):
    return ("bore" in n) or ("cgen" in n) or n.startswith("sigFromSrams")


# TileLink / 握手类输入由应答模型或定向逻辑驱动，不参与 drive_random
MODELED = {"auto_out_a_ready", "auto_out_d_valid", "auto_out_d_bits_opcode",
           "auto_out_d_bits_size", "auto_out_d_bits_source", "auto_out_d_bits_data",
           "auto_out_d_bits_denied", "auto_out_d_bits_corrupt"}
MODELED = {n for _, n in INS} & MODELED

DFT = [(w, n) for w, n in INS if is_dft(n)]
FUNC = [(w, n) for w, n in INS if not is_dft(n) and n not in MODELED]

L = []
A = L.append
A("// 自动生成：verif/ut/L2TLB/gen_tb.py —— 勿手改（改生成器后重跑）")
A(f"// L2TLB（共享 MMU 顶层）双例化逐拍比对：golden {TOP} vs 重写 {TOP}_xs。")
A(f"// 端口 {len(PORTS)}（入 {len(INS)+2} / 出 {len(OUTS)}）；其中 DFT/MBIST 输入 "
  f"{len(DFT)} 根钉 0，功能输入 {len(FUNC)} 根随机，TileLink 应答 {len(MODELED)} 根由模型驱动。")
A("`timescale 1ns/1ps")
A("module tb;")
A("  int unsigned NVEC = 200000;")
A("  int errors = 0, checks = 0;")
A("  int unsigned n_a_fire = 0, n_d_fire = 0, n_resp_fire = 0, n_req_fire = 0;")
A("  logic clock = 0, reset;")
A("  always #5 clock = ~clock;")
A("")
for w, n in INS:
    A(f"  logic {'[%d:0] ' % (w - 1) if w > 1 else ''}{n};")
for w, n in OUTS:
    ws = "[%d:0] " % (w - 1) if w > 1 else ""
    A(f"  wire {ws}g_{n};")
    A(f"  wire {ws}i_{n};")
A("")


def inst(mod, u, pfx):
    c = [".clock(clock)", ".reset(reset)"]
    c += [f".{n}({n})" for _, n in INS]
    c += [f".{n}({pfx}{n})" for _, n in OUTS]
    return f"  {mod} {u} (\n    " + ",\n    ".join(c) + "\n  );"


A(inst(TOP, "u_g", "g_"))
A("")
A(inst(TOP + "_xs", "u_i", "i_"))
A("")

# ---- 逐拍比对 ----
A("  task automatic do_check(int t);")
A("    checks++;")
for w, n in OUTS:
    fmt = "%b" if w == 1 else "%h"
    A(f"    if (g_{n} !== i_{n}) begin errors++;")
    A(f'      if (errors<=60) $display("vec %0d {n} g={fmt} i={fmt}", t, g_{n}, i_{n}); end')
A("  endtask")
A("")

# ---- DFT 钉 0 ----
A("  // DFT/MBIST 输入：功能模式恒 0（见文件头说明）。")
A("  task automatic drive_dft_zero();")
for w, n in DFT:
    A(f"    {n} = '0;")
A("  endtask")
A("")

# ---- 功能输入随机 ----
A("  // 功能输入随机激励。CSR 的 mode/asid 等取窄范围，让 satp/vsatp/hgatp 真的会命中")
A("  // 同一组页表；全 32bit 随机会让每拍都像换了个地址空间，遍历器永远走不完一次。")
A("  task automatic drive_random();")
A("    automatic int act = $urandom_range(0, 15);")
for w, n in FUNC:
    if n.endswith("_changed") or n == "io_sfence_valid":
        A(f"    {n} = ($urandom_range(0, 63) == 0);")   # 稀疏：别每拍都 flush
    elif re.search(r"satp_mode$|hgatp_mode$", n):
        A(f"    {n} = ($urandom_range(0,1)) ? 4'h8 : 4'h9;")
    elif re.search(r"_asid$|_vmid$", n):
        A(f"    {n} = {w}'($urandom_range(0, 3));")
    elif re.search(r"_ppn$", n):
        A(f"    {n} = {w}'($urandom_range(0, 15));")
    elif re.search(r"req_0_valid$", n):
        A(f"    {n} = (act < 6);")
    elif re.search(r"resp_ready$", n):
        A(f"    {n} = ($urandom_range(0, 3) != 0);")
    elif re.search(r"_vpn$", n):
        A(f"    {n} = {w}'($urandom_range(0, 63));")
    elif w == 1:
        A(f"    {n} = $urandom_range(0, 1);")
    elif w <= 32:
        A(f"    {n} = {w}'($urandom);")
    else:
        A(f"    {n} = {{{', '.join(['$urandom'] * ((w + 31) // 32))}}};")
A("  endtask")
A("")

# ---- TileLink 应答模型 ----
A("""  // ---------------------------------------------------------------------------
  // TileLink 应答模型
  // ---------------------------------------------------------------------------
  // L2TLB 用 source 当 mem id（0..5 LLPTW / 6 PTW / 7 HPTW / 8..15 Bitmap），每次请求
  // 取回 64B（2 个 256bit beat）。这里跟踪在途 source，只对**真发过**的 source 回
  // 数据：随机乱回 id 的话，waiting_resp 永远对不上，refill / merge / sector 合并这
  // 几条主路径一拍也走不到。
  //   outstanding[i] —— id i 有请求在途
  //   d_beat         —— 当前应答处在第几个 beat（0=首，1=末）
  logic [15:0] outstanding;
  logic        d_beat;
  logic [3:0]  d_cur_src;

  task automatic tl_reset();
    outstanding = '0;  d_beat = 1'b0;  d_cur_src = '0;
    auto_out_a_ready     = 1'b1;
    auto_out_d_valid     = 1'b0;
    auto_out_d_bits_opcode = 3'h1;   // AccessAckData：带数据、多 beat
    auto_out_d_bits_size   = 3'h6;   // 64B
    auto_out_d_bits_source = '0;
    auto_out_d_bits_data   = '0;
  endtask

  // 每拍在时钟沿后推进：先记 A 通道握手，再决定这一拍 D 通道给什么。
  task automatic tl_step();
    automatic int pick;
    auto_out_a_ready = ($urandom_range(0, 7) != 0);   // 偶尔背压
    // A 通道握手 → 登记在途
    if (g_auto_out_a_valid && auto_out_a_ready) begin
      outstanding[g_auto_out_a_bits_source] = 1'b1;
      n_a_fire++;
    end
    // D 通道
    if (auto_out_d_valid) begin
      n_d_fire++;
      if (d_beat) begin                    // 末 beat 交付完毕
        outstanding[d_cur_src] = 1'b0;
        d_beat = 1'b0;
        auto_out_d_valid = 1'b0;
      end else begin                       // 继续送第二个 beat
        d_beat = 1'b1;
        auto_out_d_bits_data = {$urandom, $urandom, $urandom, $urandom,
                                $urandom, $urandom, $urandom, $urandom};
      end
    end else if (|outstanding && $urandom_range(0, 2) != 0) begin
      // 从在途集合里挑一个开始应答
      pick = -1;
      for (int k = 0; k < 16; k++)
        if (outstanding[k] && (pick < 0 || $urandom_range(0, 3) == 0)) pick = k;
      if (pick >= 0) begin
        d_cur_src = 4'(pick);
        auto_out_d_bits_source = 4'(pick);
        auto_out_d_valid = 1'b1;
        d_beat = 1'b0;
        // PTE 内容：大部分位清 0 只留低位，让 v/r/w/x/pbmt/n 这些判定位真的有机会
        // 取到合法组合；全随机时 reserved 段几乎必非 0，每条 PTE 都直接判 page fault。
        auto_out_d_bits_data = '0;
        for (int b = 0; b < 4; b++)
          auto_out_d_bits_data[b*64 +: 16] = 16'($urandom);
      end
    end
  endtask
""")
A("")
A("  initial begin")
A("    if (!$value$plusargs(\"ncycles=%d\", NVEC)) NVEC = 200000;")
A("    drive_dft_zero();")
A("    tl_reset();")
A("    drive_random();")
A("    reset = 1'b1;")
A("    repeat (8) @(posedge clock);")
A("    #1 reset = 1'b0;")
A("    for (int t = 0; t < NVEC; t++) begin")
A("      @(posedge clock); #1;")
A("      do_check(t);")
A("      if (g_io_tlb_0_resp_valid || g_io_tlb_1_resp_valid) n_resp_fire++;")
A("      if (io_tlb_0_req_0_valid && g_io_tlb_0_req_0_ready) n_req_fire++;")
A("      drive_random();")
A("      drive_dft_zero();")
A("      tl_step();")
A("    end")
A("    $display(\"checks=%0d errors=%0d  a_fire=%0d d_fire=%0d tlb_req_fire=%0d tlb_resp=%0d\",")
A("             checks, errors, n_a_fire, n_d_fire, n_req_fire, n_resp_fire);")
A("    // 覆盖闸：光 errors=0 不算数 —— 比较点、访存握手、TLB 请求都必须真的发生过。")
A("    if (checks == 0)      begin $display(\"TEST FAILED: checks=0\"); $finish; end")
A("    if (n_a_fire == 0)    begin $display(\"TEST FAILED: 访存通道一次都没握手\"); $finish; end")
A("    if (n_d_fire == 0)    begin $display(\"TEST FAILED: D 通道一次都没应答\"); $finish; end")
A("    if (n_req_fire == 0)  begin $display(\"TEST FAILED: TLB 请求一次都没被接受\"); $finish; end")
A("    if (errors == 0) $display(\"TEST PASSED\"); else $display(\"TEST FAILED\");")
A("    $finish;")
A("  end")
A("endmodule")

Path("tb.sv").write_text("\n".join(L) + "\n")
print(f"tb.sv: ports={len(PORTS)} ins={len(INS)} outs={len(OUTS)} "
      f"dft={len(DFT)} func={len(FUNC)} modeled={len(MODELED)}")
