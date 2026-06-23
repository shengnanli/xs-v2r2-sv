#!/usr/bin/env python3
# MMU 簇 IT tb 生成器（构建辅助，非共享脚本）：
# 解析 golden L2TLB 顶层端口，生成 tb.sv —— 双例化 golden L2TLB(u_g) 与全重写 MMU_it(u_i)，
# 喂相同约束随机激励到簇边界，逐拍 !$isunknown 比对全部顶层输出。
# DFT/MBIST 旁路输出(bore/sigFromSrams/cg)单列 nonfunc_errors，打印但不计入 PASS。
import re, sys

GOLD = "../../../golden/chisel-rtl/L2TLB.sv"
src = open(GOLD).read().splitlines()

# 抓取 module L2TLB( ... ); 端口块
ports = []  # (dir, width_hi, name)  width_hi=None 表示 1 位
inmod = False
pat = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?([A-Za-z_][A-Za-z_0-9]*)\s*,?')
for ln in src:
    if ln.startswith('module L2TLB('):
        inmod = True
        continue
    if inmod:
        if ln.startswith(');'):
            break
        m = pat.match(ln)
        if m:
            d, hi, nm = m.group(1), m.group(2), m.group(3)
            ports.append((d, hi, nm))

assert ports, "no ports parsed"
inputs  = [p for p in ports if p[0] == 'input'  and p[2] not in ('clock', 'reset')]
outputs = [p for p in ports if p[0] == 'output']

def decl(width_hi, nm):
    if width_hi is None:
        return f"  logic {nm};"
    return f"  logic [{width_hi}:0] {nm};"

def is_nonfunc(nm):
    # DFT/MBIST bore 链 + SRAM sideband + clockgate side：非功能旁路口
    return ('bore' in nm) or nm.startswith('sigFromSrams') or nm.startswith('cg_') \
           or nm.endswith('_cgen') or 'Bd_' in nm

# 输入分类：DFT 输入恒驱 0（两侧一致）；功能输入随机
func_in  = [p for p in inputs if not is_nonfunc(p[2])]
dft_in   = [p for p in inputs if is_nonfunc(p[2])]
func_out = [p for p in outputs if not is_nonfunc(p[2])]
nf_out   = [p for p in outputs if is_nonfunc(p[2])]

L = []
A = L.append
A("// 自动生成：verif/it/MMU/gen_tb.py —— 勿手改")
A("// MMU 簇 IT：golden L2TLB (u_g) vs 全重写 MMU_it (u_i) 双例化（共用同名 golden 子模块/SRAM 宏），")
A("// 约束随机驱动簇边界(TileLink mem 通道 + 2 路 TLB req/resp + CSR distribute + sfence/csr)，")
A("// 逐拍 !$isunknown 比对全部功能输出；DFT/MBIST 旁路输出(bore/sigFromSrams/cg)单列 nonfunc_errors。")
A("`timescale 1ns/1ps")
A("module tb;")
A("  int unsigned NCYCLES = 200000;")
A("  int unsigned WARMUP  = 64;")
A("  bit clk = 0, rst;")
A("  int errors = 0, checks = 0, nonfunc_errors = 0;")
A("  int cyc = 0;")
A("  // 活跃度统计：证明集成确被激励到（PTW 发 mem 请求 / TLB 出 resp / cache 命中等）")
A("  int act_mem_req = 0, act_tlb0_resp = 0, act_tlb1_resp = 0;")
A("  always #5 clk = ~clk;")
A("")
A("  // ---- 簇边界输入信号 ----")
for d, hi, nm in inputs:
    A(decl(hi, nm))
A("")
A("  // ---- golden(g_) / it(i_) 各自输出信号 ----")
for pfx in ('g_', 'i_'):
    for d, hi, nm in outputs:
        A(decl(hi, pfx + nm))
A("")

# 驱动：功能输入随机，DFT 输入恒 0
# 协议感知驱动：以下功能输入由专用握手逻辑驱动，不进通用随机 task
PROTO = {
    'auto_out_a_ready', 'auto_out_d_valid', 'auto_out_d_bits_source',
    'auto_out_d_bits_opcode', 'auto_out_d_bits_size', 'auto_out_d_bits_data',
    'io_tlb_0_req_0_valid', 'io_tlb_1_req_0_valid', 'io_tlb_0_resp_ready',
    # CSR satp/vsatp/hgatp 整组保持稳定，仅偶发 changed 脉冲时刷新（避免持续 flush 丢请求）
    'io_csr_tlb_satp_mode', 'io_csr_tlb_satp_asid', 'io_csr_tlb_satp_ppn', 'io_csr_tlb_satp_changed',
    'io_csr_tlb_vsatp_mode', 'io_csr_tlb_vsatp_asid', 'io_csr_tlb_vsatp_ppn', 'io_csr_tlb_vsatp_changed',
    'io_csr_tlb_hgatp_mode', 'io_csr_tlb_hgatp_vmid', 'io_csr_tlb_hgatp_ppn', 'io_csr_tlb_hgatp_changed',
    'io_sfence_valid',
    # CSR 分发总线由 initial 一次性编程 PMP/PMA + 主循环偶发再写，避免覆盖权限配置
    'io_csr_distribute_csr_w_valid', 'io_csr_distribute_csr_w_bits_addr',
    'io_csr_distribute_csr_w_bits_data',
}
rand_in = [p for p in func_in if p[2] not in PROTO]

A("  // ---- 通用随机驱动：非握手类功能输入约束随机 ----")
A("  task automatic drive_inputs();")
for d, hi, nm in rand_in:
    if hi is None:
        A(f"    {nm} <= $random;")
    else:
        w = int(hi) + 1
        if w <= 32:
            A(f"    {nm} <= $random;")
        else:
            chunks = (w + 31) // 32
            expr = "{" + ", ".join(["$random"] * chunks) + "}"
            A(f"    {nm} <= {expr};")
A("  endtask")
A("")
A("  task automatic zero_dft();")
for d, hi, nm in dft_in:
    A(f"    {nm} <= '0;")
A("  endtask")
A("")

# 两份实例
def inst(modname, instname, outpfx):
    conns = ["    .clock(clk)", "    .reset(rst)"]
    for d, hi, nm in inputs:
        conns.append(f"    .{nm}({nm})")
    for d, hi, nm in outputs:
        conns.append(f"    .{nm}({outpfx}{nm})")
    return f"  {modname} {instname} (\n" + ",\n".join(conns) + "\n  );"

A("  // ---- 双例化：golden 参考模型 u_g / 全重写 IT u_i ----")
A(inst("L2TLB", "u_g", "g_"))
A("")
A(inst("MMU_it", "u_i", "i_"))
A("")

# 比对块
A("  // ---- 逐拍比对：功能输出 -> errors；DFT/MBIST 旁路输出 -> nonfunc_errors ----")
A("  always @(negedge clk) if (!rst) begin")
A("    #4;")
A("    if (cyc > WARMUP) begin")
A("      checks++;")
A("      if (g_auto_out_a_valid === 1'b1) act_mem_req++;")
A("      if (g_io_tlb_0_resp_valid === 1'b1) act_tlb0_resp++;")
A("      if (g_io_tlb_1_resp_valid === 1'b1) act_tlb1_resp++;")
for d, hi, nm in func_out:
    A(f"      if (!$isunknown(g_{nm}) && g_{nm} !== i_{nm}) begin errors++;")
    A(f"        if (errors<=60) $display(\"[%0t] {nm} g=%h i=%h\", $time, g_{nm}, i_{nm}); end")
for d, hi, nm in nf_out:
    A(f"      if (!$isunknown(g_{nm}) && g_{nm} !== i_{nm}) begin nonfunc_errors++;")
    A(f"        if (nonfunc_errors<=8) $display(\"[%0t] (nonfunc) {nm} g=%h i=%h\", $time, g_{nm}, i_{nm}); end")
A("    end")
A("  end")
A("")

# ---- 协议感知握手状态 ----
A("  // ---- 协议感知握手：TileLink mem A/D 通道、TLB req 保持、satp 模式偏置 ----")
A("  // mem 响应模型：A 请求被接受后入队 source，随机延迟后回 D（两侧 A 完全相同，模型一致）")
A("  bit [2:0] mem_q [$];")
A("  bit       d_pending;")
A("  bit [2:0] d_source;")
A("  int       d_delay;")
A("  bit       csr_busy;   // initial 编程 PMP/PMA 期间置 1，主循环让出 csr_distribute 总线")
A("")
A("  // 主激励：posedge 驱动下一拍输入；非阻塞，保证两侧采到同一激励")
A("  always @(posedge clk) begin")
A("    if (rst) begin")
A("      zero_dft();")
for d, hi, nm in func_in:
    A(f"      {nm} <= '0;")
A("      cyc <= 0;")
A("      mem_q.delete(); d_pending <= 0; d_delay <= 0;")
A("      // CSR 复位初值：satp/vsatp = Sv39 有效，使 PTW 自起步即活跃")
A("      io_csr_tlb_satp_mode <= 4'd8; io_csr_tlb_vsatp_mode <= 4'd8; io_csr_tlb_hgatp_mode <= 4'd8;")
A("    end else begin")
A("      drive_inputs();")
A("      zero_dft();")
A("      cyc <= cyc + 1;")
A("")
A("      // --- TLB req：保持 valid 直到被 ready 接受，接受后换新 vpn ---")
A("      if (io_tlb_0_req_0_valid && g_io_tlb_0_req_0_ready) begin")
A("        io_tlb_0_req_0_bits_vpn <= $random; io_tlb_0_req_0_bits_s2xlate <= $random;")
A("        io_tlb_0_req_0_valid <= ($urandom_range(0,3) != 0);")
A("      end else if (!io_tlb_0_req_0_valid) begin")
A("        io_tlb_0_req_0_valid <= ($urandom_range(0,3) != 0);")
A("        io_tlb_0_req_0_bits_vpn <= $random; io_tlb_0_req_0_bits_s2xlate <= $random;")
A("      end")
A("      if (io_tlb_1_req_0_valid && g_io_tlb_1_req_0_ready) begin")
A("        io_tlb_1_req_0_bits_vpn <= $random; io_tlb_1_req_0_bits_s2xlate <= $random;")
A("        io_tlb_1_req_0_valid <= ($urandom_range(0,3) != 0);")
A("      end else if (!io_tlb_1_req_0_valid) begin")
A("        io_tlb_1_req_0_valid <= ($urandom_range(0,3) != 0);")
A("        io_tlb_1_req_0_bits_vpn <= $random; io_tlb_1_req_0_bits_s2xlate <= $random;")
A("      end")
A("      io_tlb_0_resp_ready <= ($urandom_range(0,3) != 0);")
A("")
A("      // --- CSR satp/vsatp/hgatp：值整组保持稳定；约每 ~512 拍偶发 changed 脉冲刷新一次 ---")
A("      io_csr_tlb_satp_changed  <= 1'b0;")
A("      io_csr_tlb_vsatp_changed <= 1'b0;")
A("      io_csr_tlb_hgatp_changed <= 1'b0;")
A("      io_sfence_valid          <= 1'b0;")
A("      // mode 固定有效(Sv39=8 / hgatp Sv39x4=8)，仅刷新 asid/ppn —— 保证 PTW 持续活跃")
A("      if ($urandom_range(0,511) == 0) begin")
A("        io_csr_tlb_satp_mode <= 4'd8;")
A("        io_csr_tlb_satp_asid <= $random; io_csr_tlb_satp_ppn <= {$random,$random};")
A("        io_csr_tlb_satp_changed <= 1'b1;")
A("      end")
A("      if ($urandom_range(0,511) == 0) begin")
A("        io_csr_tlb_vsatp_mode <= 4'd8;")
A("        io_csr_tlb_vsatp_asid <= $random; io_csr_tlb_vsatp_ppn <= {$random,$random};")
A("        io_csr_tlb_vsatp_changed <= 1'b1;")
A("      end")
A("      if ($urandom_range(0,511) == 0) begin")
A("        io_csr_tlb_hgatp_mode <= 4'd8;")
A("        io_csr_tlb_hgatp_vmid <= $random; io_csr_tlb_hgatp_ppn <= {$random,$random};")
A("        io_csr_tlb_hgatp_changed <= 1'b1;")
A("      end")
A("      // sfence 偶发（~每 256 拍），制造 flush 边界（IT 要覆盖的传播路径）")
A("      if ($urandom_range(0,255) == 0) io_sfence_valid <= 1'b1;")
A("")
A("      // csr_distribute：编程期由 initial 独占；否则默认拉低（保持 PMP/PMA 配置稳定）")
A("      if (!csr_busy) io_csr_distribute_csr_w_valid <= 1'b0;")
A("")
A("      // --- TileLink mem：A 通道几乎总 ready；接受的请求入队等待回 D ---")
A("      auto_out_a_ready <= ($urandom_range(0,7) != 0);")
A("      if (g_auto_out_a_valid && auto_out_a_ready)")
A("        mem_q.push_back(g_auto_out_a_bits_source);")
A("      // D 通道：有挂起则倒计时后拉高一拍，source 取自队首")
A("      if (!d_pending && (mem_q.size() > 0) && ($urandom_range(0,2) != 0)) begin")
A("        d_pending <= 1; d_source <= mem_q.pop_front(); d_delay <= $urandom_range(0,3);")
A("      end")
A("      if (d_pending) begin")
A("        if (d_delay > 0) begin d_delay <= d_delay - 1; auto_out_d_valid <= 0; end")
A("        else begin")
A("          auto_out_d_valid <= 1;")
A("          auto_out_d_bits_source <= d_source;")
A("          auto_out_d_bits_opcode <= 4'd1;   // AccessAckData")
A("          auto_out_d_bits_size   <= 3'd5;   // 32B beat")
A("          // 数据=8 个 64b PTE：偶发构造\"有效非叶\"PTE(V=1,RWX=0,带 ppn)促使页表继续向下走，")
A("          // 触发 PTW 发出后续 mem 请求；否则随机(多为无效->页错误，走 resp 路径)。")
A("          if ($urandom_range(0,1)) begin")
A("            auto_out_d_bits_data <= { {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1,")
A("                                      {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1,")
A("                                      {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1,")
A("                                      {2{$random}} & 64'h003F_FFFF_FFFF_FC00 | 64'h1 };")
A("          end else begin")
A("            auto_out_d_bits_data <= {$random,$random,$random,$random,$random,$random,$random,$random};")
A("          end")
A("          d_pending <= 0;")
A("        end")
A("      end else begin")
A("        auto_out_d_valid <= 0;")
A("      end")
A("    end")
A("  end")
A("")
A("  // 复位后一次性编程 PMP/PMA：覆盖全地址空间、可缓存 RWX，使页表走查地址被判为正常内存")
A("  // （否则随机 satp.ppn 落在默认 MMIO 区，PTW 走 accessFault 路径、不发 DRAM 请求）。")
A("  task automatic prog_csr(input [11:0] a, input [63:0] dval);")
A("    @(negedge clk);")
A("    io_csr_distribute_csr_w_valid     = 1'b1;")
A("    io_csr_distribute_csr_w_bits_addr = a;")
A("    io_csr_distribute_csr_w_bits_data = dval;")
A("    @(negedge clk);")
A("    io_csr_distribute_csr_w_valid     = 1'b0;")
A("  endtask")
A("")
A("  initial begin")
A("    void'($value$plusargs(\"NCYCLES=%d\", NCYCLES));")
A("    rst = 1; repeat (16) @(posedge clk); rst = 0;")
A("    csr_busy = 1'b1;")
A("    // pmaaddr0 = 全 1 NAPOT(覆盖全空间)；pmacfg0 byte = NAPOT(A=3)+cacheable+RWX")
A("    prog_csr(12'h7C8, 64'hFFFF_FFFF_FFFF_FFFF);")
A("    prog_csr(12'h7C0, 64'h0000_0000_0000_007F);")
A("    // pmpaddr0 = 全 1 NAPOT；pmpcfg0 byte = NAPOT+RWX")
A("    prog_csr(12'h3B0, 64'hFFFF_FFFF_FFFF_FFFF);")
A("    prog_csr(12'h3A0, 64'h0000_0000_0000_001F);")
A("    csr_busy = 1'b0;")
A("    repeat (NCYCLES) @(posedge clk);")
A("    $display(\"checks=%0d errors=%0d nonfunc_errors=%0d\", checks, errors, nonfunc_errors);")
A("    $display(\"activity: mem_req=%0d tlb0_resp=%0d tlb1_resp=%0d\", act_mem_req, act_tlb0_resp, act_tlb1_resp);")
A("    if (errors == 0 && checks > 1000) $display(\"TEST PASSED\"); else $display(\"TEST FAILED\");")
A("    $finish;")
A("  end")
A("endmodule")

open("tb.sv", "w").write("\n".join(L) + "\n")
print(f"tb.sv written: {len(inputs)} inputs ({len(func_in)} func + {len(dft_in)} dft), "
      f"{len(outputs)} outputs ({len(func_out)} func + {len(nf_out)} nonfunc)")
