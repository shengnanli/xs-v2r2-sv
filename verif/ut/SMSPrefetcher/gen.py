#!/usr/bin/env python3
"""生成 SMSPrefetcher 的双例化 UT testbench（tb.sv，scripts/dual_tb_lib.py）。

golden SMSPrefetcher vs SMSPrefetcher_xs（child 两侧各用各的：golden 侧 golden child，重写侧本仓重写 child；
厂商 SRAM 宏 array_12_ext 两侧共用 golden 行为模型），全部输出逐拍逐位 !==。

激励偏置（让整条 训练→AGT→PHT→pf_filter→L2 链路真的跑起来，纯随机地址几乎从不命中）：
  * 3 路 load 训练口：PC 取自 8 个固定值的池子（PHT 的 index/tag 撞得上）；vaddr = 6 个"区域基址"之一
    + 1/4 概率 ±1 个区域（相邻区域、跨区域预取）+ 随机块偏移；1/8 概率完全随机地址；
    偶尔把 21 位原始区域地址钉成全 1 / 全 0（相邻区域 ±1 越界、不许跨的路径）；
    paddr = 物理内存范围内的页号 + vaddr 的页内偏移（这样 AGT/PHT 存下的区域实地址经 pf_filter 出来
    也在 [0x8000_0000, 0x800_0000_0000) 里，L2 请求不会全被范围门挡掉）；
  * dcache evict 1/16 概率、vaddr 取同一组区域（AGT 的"被 dcache 逐出"路径）；
  * io_enable / io_agt_en / io_pht_en 按 mode 偶尔关（三个门控的两侧都走到）；act_threshold / act_stride 随机；
  * TLB 回应：valid 1/2、miss 1/4、物理地址 3/4 落在物理内存范围；异常位 / pbmt / PMP 小概率；
  * MBIST / SRAM DFT 口在 mode != 0 时钉 0。
恒值输出（TLB 请求里的常量字段、区域/块对齐的低位）不要求见过 0/1（EXEMPT），但照样逐拍比。
不复位寄存器：pf_filter 的 TLB 请求 bits 与表项、PHT SRAM 的 MBIST 读回寄存器都直出到端口，+random 档两侧
初值各摇各的 —— pf_filter 16 项每项都 alloc 过、golden 发过 TLB 请求、SRAM 读过一次之后再过 4 拍才开始比（arm）。
厂商 SRAM 行为模型的存储阵列上电初值：0 时刻后把重写侧拷成 golden 侧（见 DECLS）。

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
X = "sm_"
G = X + "u_gold"

STIM = "\n".join(
    ["for (int k = 0; k < 3; k++) begin : ld",
     "  logic [49:0] va;",
     "  va = sm_rnd_vaddr();",
     "  case (k)"]
    + ["    %d: begin @io_ld_in_%d_valid = ($urandom_range(0, 1) != 0); @io_ld_in_%d_bits_uop_pc = sm_pcs[$urandom_range(0, 7)];"
       " @io_ld_in_%d_bits_vaddr = va; @io_ld_in_%d_bits_paddr = sm_paddr_of(va); end" % (k, k, k, k, k) for k in range(3)]
    + ["  endcase",
       "end",
       "@io_dcache_evict_valid = ($urandom_range(0, 15) == 0);",
       "@io_dcache_evict_bits_vaddr = sm_rnd_vaddr();",
       "@io_enable = (sm_mode != 1);",
       "@io_agt_en = (sm_mode != 2);",
       "@io_pht_en = (sm_mode != 3);",
       "@io_tlb_req_resp_valid = ($urandom_range(0, 1) != 0);",
       "@io_tlb_req_resp_bits_miss = ($urandom_range(0, 3) == 0);",
       "if ($urandom_range(0, 3) != 0) @io_tlb_req_resp_bits_paddr_0 = {5'h0, 1'b0, 42'($urandom_range(0, 32'hffff_ffff)) | 42'h8000_0000};",
       "@io_tlb_req_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 31) == 0);",
       "@io_tlb_req_resp_bits_excp_0_pf_ld = ($urandom_range(0, 31) == 0);",
       "@io_tlb_req_resp_bits_excp_0_af_ld = ($urandom_range(0, 31) == 0);",
       "@io_tlb_req_resp_bits_pbmt_0 = ($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'd0;",
       "@io_pmp_resp_ld = ($urandom_range(0, 31) == 0);",
       "@io_pmp_resp_mmio = ($urandom_range(0, 31) == 0);",
       "if (sm_mode != 0) begin"]
    + ["  @%s = '0;" % d for d in DFT] + ["end"])

DECLS = """
logic [49:0] sm_pcs [8];
logic [39:0] sm_rbase [6];
logic [35:0] sm_ppn [6];
initial begin
  for (int i = 0; i < 8; i++) sm_pcs[i] = 50'({$urandom, $urandom});
  for (int i = 0; i < 6; i++) begin
    sm_rbase[i] = 40'({$urandom, $urandom});
    sm_ppn[i] = 36'(32'h0008_0000 + $urandom_range(0, 32'h07ff_ffff));
  end
end
// 训练 / evict 用的 vaddr：6 个区域基址 ±1 区域 + 随机块偏移；1/8 完全随机
function automatic logic [49:0] sm_rnd_vaddr();
  logic [39:0] rg;
  if ($urandom_range(0, 7) == 0) return 50'({$urandom, $urandom});
  rg = sm_rbase[$urandom_range(0, 5)];
  case ($urandom_range(0, 7))
    0: rg = rg + 40'd1;
    1: rg = rg - 40'd1;
    2: if ($urandom_range(0, 3) == 0) rg[20:0] = '1;   // 原始区域地址全 1：+1 越界
    3: if ($urandom_range(0, 3) == 0) rg[20:0] = '0;   // 全 0：-1 越界
    default: ;
  endcase
  return {rg, 4'($urandom), 6'($urandom)};
endfunction
// paddr：按 vaddr 页号挑一个物理页（同一虚页恒定映射），拼页内偏移
function automatic logic [47:0] sm_paddr_of(input logic [49:0] va);
  return {sm_ppn[va[17:12] % 6], va[11:0]};
endfunction
// 厂商 SRAM 行为模型（两侧同一份 golden array_12_ext）的存储阵列与读地址寄存器上电不复位：
// +vcs+initreg+<seed> 下两个实例各摇各的初值，MBIST 读到没写过的行时两侧不同（与重写无关）。
// 0 时刻之后把重写侧拷成 golden 侧（普通 always 驱动的变量，可直接过程赋值；只对齐上电初值）。
initial begin
  #1;
  for (int k = 0; k < 32; k++)
    sm_u_impl.pht.pht_ram.array.array.array_12_ext.ram[k] = sm_u_gold.pht.pht_ram.array.array.array_12_ext.ram[k];
  sm_u_impl.pht.pht_ram.array.array.array_12_ext.reg_RW0_addr = sm_u_gold.pht.pht_ram.array.array.array_12_ext.reg_RW0_addr;
  sm_u_impl.pht.pht_ram.array.array.array_12_ext.reg_RW0_ren = sm_u_gold.pht.pht_ram.array.array.array_12_ext.reg_RW0_ren;
end
"""

COV = [
    ("train_req",    "%s._train_filter_io_train_req_valid" % G),
    ("agt_evict",    "%s._active_gen_table_io_s2_evict_valid" % G),
    ("agt_lookup",   "%s._active_gen_table_io_s2_pht_lookup_valid" % G),
    ("no_cross_p1",  "%s.train_vld_s0_last_REG && !%s.train_allow_cross_region_p1_s0" % (G, G)),
    ("no_cross_m1",  "%s.train_vld_s0_last_REG && !%s.train_allow_cross_region_m1_s0" % (G, G)),
    ("pht_gen",      "%s._pht_io_pf_gen_req_valid && @io_pht_en" % G),
    ("pht_gated",    "%s._pht_io_pf_gen_req_valid && !@io_pht_en" % G),
    ("tlb_req",      "@io_tlb_req_req_valid"),
    ("pf_out",       "%s._pf_filter_io_l2_pf_addr_valid" % G),
    ("l2_req",       "@io_l2_req_valid"),
    ("l2_out_range", "%s._pf_filter_io_l2_pf_addr_valid && @io_enable && !@io_l2_req_valid" % G),
    ("l2_disabled",  "%s._pf_filter_io_l2_pf_addr_valid && !@io_enable" % G),
    ("reset_mid",    "@reset && cyc > 100"),
]

ARM = ["%s.pf_filter.valids_%d" % (G, k) for k in range(16)] + [
    "@io_tlb_req_req_valid", "%s.pht.pht_ram.respReg" % G]

# 恒值输出（golden 在 pf_filter 里把它们写成常量 / 区域对齐 / 块对齐）：不要求见过 0 和 1
EXEMPT = (["io_tlb_req_req_bits_vaddr[%d]" % b for b in range(10)]
          + ["io_l2_req_bits_addr[%d]" % b for b in range(6)]
          + ["io_tlb_req_req_bits_" + n for n in (
              "fullva", "checkfullva", "cmd", "hyperinst", "hlvx", "kill", "isPrefetch", "no_translate",
              "pmp_addr", "frm_mabuf", "debug_robIdx_flag", "debug_robIdx_value", "debug_isFirstIssue")])

PAIRS = [Pair("SMSPrefetcher", X, clocked=True, stim=STIM, cov=COV, decls=DECLS, exempt=EXEMPT,
              reset_period=10000, mode_period=2000, cov_min=5, arm=ARM, arm_delay=4)]

HEADER = """自动生成：verif/ut/SMSPrefetcher/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
SMSPrefetcher 双例化逐拍比对，全部输出逐位 !==。"""

if __name__ == "__main__":
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), render(PAIRS, HEADER), "--check" in sys.argv))
