#!/usr/bin/env python3
"""生成 CsrIrqHandle12 的双例化 UT testbench（tb.sv）。

12 对 golden <M> vs 重写 <M>_xs（scripts/dual_tb_lib.py，端口表读 G1 golden），每拍逐位
比较全部输出（`!==`）。默认每个输入每拍独立随机；下面各段 STIM 只做必要的偏置：
  * PMP/PMA：CSR 地址压到 cfg/addr CSR 窗口附近（纯随机 12 位地址几乎打不中）；
    mode 分"全不锁 / 随机锁 / 全锁"三档。
  * TrapHandle：异常向量分"独热 / 两位 / 稀疏 / 全随机"四档（全随机时最高优先级的
    doubleTrap 几乎恒中，其余优先级走不到）；中断号偏向 VS 三个号与本地号。
  * MStatus：各事件 valid 分"稀疏（单写者为主）/ 全随机（多写者按位或）"两档。
  * 中断向量族：sideband valid 分"稀疏 / 全随机"，否则 CSR 写永远被 sideband 压住。
覆盖闸：每个输出位都见过 0 和 1（EXEMPT 里逐条写明为什么是常数）+ 各 pair 的事件计数。

用法：python3 gen.py [--check]
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "..", "scripts"))
from dual_tb_lib import Pair, render, write_or_check  # noqa: E402

LOCALS = [n for n in range(14, 64)]


def lc(n, sfx):
    return {35: "LPRASEI", 43: "HPRASEI"}.get(n, "LC%dI" % n) + sfx


def bits(name, idx):
    return ["%s[%d]" % (name, i) for i in idx]


# ---- 中断向量族 ---------------------------------------------------------------
# rdata 的硬零位：supervisor 视图只有 1/5/9/13..63；mvien 1/9/14..63；hvien 14..63；
# mvip 1/5/9/13..63；hvip 2/6/10/14..63。
S_VIEW_ZERO = [0, 2, 3, 4, 6, 7, 8, 10, 11, 12]

SIE_STIM = """
if (@mode % 2 == 0) begin
""" + "".join("  if ($urandom_range(0, 7) != 0) @fromVSie_%s_valid = 1'b0;\n" % lc(n, "E") for n in LOCALS) + """end
"""
SIE_COV = [
    ("own_csr_wr", "@w_wen && !@mideleg_SSI && @mvien_SSIE"),
    ("alias_wr", "@toMie_SEIE_valid"),
    ("vsie_wr", "!@w_wen && @fromVSie_LC14IE_valid && @mvien_LC14IE"),
    ("both_wr", "@w_wen && @fromVSie_LC63IE_valid && @mvien_LC63IE"),
    ("own_read", "@regOut_LC14IE"),
]

SIP_COV = [
    ("mip_alias_wr", "@toMip_SSIP_valid"),
    ("mvip_alias_wr", "@toMvip_SSIP_valid"),
    ("local_wr", "@toMvip_LC14IP_valid && @toMvip_LC14IP_bits"),
    ("lcofi_mip", "@toMip_LCOFIP_valid && @toMip_LCOFIP_bits"),
]

VSIE_COV = [
    ("to_mie_vs", "@toMie_VSSIE_valid && @toMie_VSSIE_bits"),
    ("to_mie_lcofi", "@toMie_LCOFIE_valid"),
    ("own_wr", "@w_wen && @hvien_LC14IE"),
    ("own_read", "@regOut_LC63IE"),
    ("alias_read", "@regOut_SEIE"),
]
# toSie：sieIsAlias = hideleg & ~mideleg & mvien。VS 位 mideleg 恒 1、LCOFI 位 mvien 恒 0、
# 本地 14..63 位 hideleg 恒 0 —— 本配置下全部折成常数 0（golden 即 assign 1'h0）。
VSIE_EXEMPT = (bits("rdata", S_VIEW_ZERO)
               + ["toSie_%s_%s" % (n, k) for n in ("VSSIE", "VSTIE", "VSEIE", "LCOFIE")
                  for k in ("valid", "bits")]
               + ["toSie_%s_%s" % (lc(n, "E"), k) for n in LOCALS for k in ("valid", "bits")])

VSIP_COV = [
    ("to_hvip_vssip", "@toHvip_VSSIP_valid"),
    ("to_hvip_local", "@toHvip_LC14IP_valid"),
    ("to_mip_lcofi", "@toMip_LCOFIP_valid"),
    ("read_mip", "@regOut_SSIP"),
    ("read_local", "@regOut_LC63IP"),
]

MVIP_STIM = """
if (@mode % 2 == 0) begin
  if ($urandom_range(0, 7) != 0) @fromMip_SEIP_valid = 1'b0;
  if ($urandom_range(0, 7) != 0) @fromSip_SSIP_valid = 1'b0;
  if ($urandom_range(0, 7) != 0) @fromSip_LCOFIP_valid = 1'b0;
""" + "".join("  if ($urandom_range(0, 7) != 0) @fromSip_%s_valid = 1'b0;\n" % lc(n, "P") for n in LOCALS) + """end
"""
MVIP_COV = [
    ("ssip_csr_wr", "@w_wen && @mvien_SSIE && !@fromSip_SSIP_valid"),
    ("ssip_sip_wr", "@fromSip_SSIP_valid"),
    ("ssip_alias", "@toMip_SSIP_valid"),
    ("stip_alias", "@toMip_STIP_valid"),
    ("seip_mip_wr", "@fromMip_SEIP_valid"),
    ("seip_csr_wr", "@w_wen && !@fromMip_SEIP_valid"),
    ("local_csr_wr", "@w_wen && !@fromSip_LC14IP_valid"),
    ("local_both", "@w_wen && @fromSip_LC14IP_valid"),
]

HVIP_STIM = """
if (@mode % 2 == 0) begin
  if ($urandom_range(0, 7) != 0) @fromMip_VSSIP_valid = 1'b0;
  if ($urandom_range(0, 7) != 0) @fromHip_VSSIP_valid = 1'b0;
  if ($urandom_range(0, 7) != 0) @fromVSip_VSSIP_valid = 1'b0;
""" + "".join("  if ($urandom_range(0, 7) != 0) @fromVSip_%s_valid = 1'b0;\n" % lc(n, "P") for n in LOCALS) + """end
"""
HVIP_COV = [
    ("vssip_csr_wr", "@w_wen && !@fromMip_VSSIP_valid && !@fromHip_VSSIP_valid && !@fromVSip_VSSIP_valid"),
    ("vssip_one", "@fromMip_VSSIP_valid && !@fromHip_VSSIP_valid && !@fromVSip_VSSIP_valid"),
    ("vssip_multi", "@fromMip_VSSIP_valid && @fromHip_VSSIP_valid"),
    ("local_csr_wr", "@w_wen && !@fromVSip_LC14IP_valid"),
    ("local_vsip_wr", "@fromVSip_LC14IP_valid"),
]

# ---- MStatus -------------------------------------------------------------------
MS_EVENTS = ["trapToM_mstatus_valid", "trapToHS_mstatus_valid", "retFromD_mstatus_valid",
             "retFromM_mstatus_valid", "retFromMN_mstatus_valid", "retFromS_mstatus_valid",
             "w_wen", "wAliasSstatus_wen", "robCommit_fsDirty", "robCommit_vsDirty",
             "robCommit_vstart_valid", "writeFCSR", "writeVCSR"]
MS_STIM = """
if (@mode % 4 != 0) begin
""" + "".join("  if ($urandom_range(0, 7) != 0) @%s = 1'b0;\n" % e for e in MS_EVENTS) + """end
if (@mode % 8 == 1) @menvcfg_DTE = 1'b1;
if (@mode % 8 == 2) @menvcfg_DTE = 1'b0;
if ($urandom_range(0, 3) == 0) @robCommit_vstart_bits = 7'h0;
"""
MS_COV = [
    ("csr_wr", "@w_wen"),
    ("alias_wr_only", "@wAliasSstatus_wen && !@w_wen"),
    ("trap_m", "@trapToM_mstatus_valid"),
    ("trap_hs", "@trapToHS_mstatus_valid"),
    ("ret_m", "@retFromM_mstatus_valid"),
    ("ret_s", "@retFromS_mstatus_valid"),
    ("ret_d", "@retFromD_mstatus_valid"),
    ("ret_mn", "@retFromMN_mstatus_valid"),
    ("mpp_illegal_wr", "@w_wen && @w_wdata[12:11] == 2'b10 && !@trapToM_mstatus_valid && !@retFromM_mstatus_valid"),
    ("mdt_clears_mie", "@w_wen && @w_wdata[42] && @w_wdata[3]"),
    ("sdt_alias_dte0", "@wAliasSstatus_wen && !@w_wen && !@menvcfg_DTE && @regOut_SDT"),
    ("sdt_alias_dte1", "@wAliasSstatus_wen && !@w_wen && @menvcfg_DTE && @wAliasSstatus_wdata[24]"),
    ("fs_dirty", "@robCommit_fsDirty || @writeFCSR"),
    ("vstart_dirty", "@robCommit_vstart_valid && @robCommit_vstart_bits != 0 && !@robCommit_vsDirty && !@writeVCSR"),
    ("vstart_zero", "@robCommit_vstart_valid && @robCommit_vstart_bits == 0 && !@robCommit_vsDirty && !@writeVCSR"),
]
# mstatus 可变位：1 3 5 7 8 9:10 11:12 13:14 17..22 24 38 39 42 63；UXL/SXL 恒 2'b10。
MS_VAR = [1, 3, 5, 7, 8, 9, 10, 11, 12, 13, 14, 17, 18, 19, 20, 21, 22, 24, 38, 39, 42, 63]
SS_VAR = [1, 5, 8, 9, 10, 13, 14, 18, 19, 24, 63]
MS_EXEMPT = (bits("rdata", [i for i in range(64) if i not in MS_VAR])
             + bits("sstatusRdata", [i for i in range(64) if i not in SS_VAR]))

# ---- TrapHandle -----------------------------------------------------------------
TH_STIM = """
case (@mode % 4)
  0: @io_in_trapInfo_bits_trapVec = 64'h1 << $urandom_range(0, 23);
  1: @io_in_trapInfo_bits_trapVec = (64'h1 << $urandom_range(0, 23)) | (64'h1 << $urandom_range(0, 23));
  2: @io_in_trapInfo_bits_trapVec = @io_in_trapInfo_bits_trapVec & {2{$urandom}} & {2{$urandom}};
  default: ;
endcase
case ($urandom_range(0, 7))
  0: @io_in_trapInfo_bits_intrVec = 8'd2;
  1: @io_in_trapInfo_bits_intrVec = 8'd6;
  2: @io_in_trapInfo_bits_intrVec = 8'd10;
  3: @io_in_trapInfo_bits_intrVec = 8'($urandom_range(0, 63));
  default: ;
endcase
if ($urandom_range(0, 7) != 0) @io_in_trapInfo_valid = 1'b1;
if ($urandom_range(0, 3) != 0) @io_in_trapInfo_bits_singleStep = 1'b0;
if (@mode % 8 >= 4) begin
  // 委托全开档：让 trap 能真的落到 HS / VS
  if ($urandom_range(0, 3) != 0) begin
    @io_in_mstatus_MDT = 1'b0; @io_in_sstatus_SDT = 1'b0; @io_in_vsstatus_SDT = 1'b0;
  end
end
"""
TH_COV = [
    ("exc", "@io_in_trapInfo_valid && !@io_in_trapInfo_bits_isInterrupt"),
    ("intr", "@io_out_causeNO_Interrupt"),
    ("to_vs", "@io_out_entryPrivState_V"),
    ("to_hs", "!@io_out_entryPrivState_V && @io_out_entryPrivState_PRVM == 2'b01"),
    ("to_m", "@io_in_trapInfo_valid && @io_out_entryPrivState_PRVM == 2'b11"),
    ("dbl_m", "@io_out_dbltrpToMN"),
    ("dbl_any", "@io_out_hasDTExcp && !@io_out_dbltrpToMN"),
    ("vectored_vs", "@io_out_entryPrivState_V && @io_out_causeNO_Interrupt && @io_in_vstvec_mode == 2'b01 && @io_in_trapInfo_bits_intrVec == 8'd6 && @io_in_trapInfo_bits_irToVS"),
    ("single_step", "@io_in_trapInfo_bits_singleStep && !@io_out_causeNO_Interrupt"),
] + [("exc_code_%d" % c,
      "@io_in_trapInfo_valid && !@io_in_trapInfo_bits_isInterrupt && !@io_in_trapInfo_bits_singleStep"
      " && @io_out_causeNO_ExceptionCode == 63'd%d && @io_in_trapInfo_bits_trapVec[%d]" % (c, c))
     for c in (16, 3, 12, 20, 1, 18, 2, 22, 0, 11, 9, 10, 8, 6, 4, 15, 13, 23, 21, 7, 5, 19)]
# cause 码只有低 8 位（中断号 8 位 / 异常号 6 位），其余恒 0；pc 低两位恒 0；
# 进入陷入后的特权级只会是 S(01) 或 M(11)，低位恒 1。
TH_EXEMPT = (bits("io_out_causeNO_ExceptionCode", range(8, 63))
             + bits("io_out_pcFromXtvec", [0, 1])
             + ["io_out_entryPrivState_PRVM[0]"])

# ---- PMP / PMA -------------------------------------------------------------------


def pm_stim(pfx, cfg_base, addr_base):
    lock = "".join("  @io_in_%sCfg_%d_L = v;\n" % (pfx, i) for i in range(32))
    return """
// CSR 地址：7/8 落在 cfg..addr 窗口（含相邻未命中地址），1/8 全随机
if ($urandom_range(0, 7) != 0)
  @io_in_addr = 12'(%d + $urandom_range(0, %d));
case (@mode %% 4)
  0: begin : all_unlocked
    logic v; v = 1'b0;
%s  end
  1: begin : all_locked
    logic v; v = 1'b1;
%s  end
  2: begin : tor_lock_next   // 条目 1 以 TOR 上锁 -> 条目 0 的地址被"下一条"锁住
    logic v; v = 1'b0;
%s    @io_in_%sCfg_1_L = 1'b1; @io_in_%sCfg_1_A = 2'b01;
  end
  default: ;
endcase
""" % (cfg_base - 2, addr_base + 32 + 1 - (cfg_base - 2), lock, lock, lock, pfx, pfx)


def pm_cov(pfx, cfg_base, addr_base):
    c = "@io_in_%sCfg_" % pfx
    return [
        ("cfg0_wr", "@io_in_wen && @io_in_addr == 12'd%d" % cfg_base),
        ("cfg6_wr", "@io_in_wen && @io_in_addr == 12'd%d" % (cfg_base + 6)),
        ("cfg_odd_miss", "@io_in_wen && @io_in_addr == 12'd%d" % (cfg_base + 1)),
        ("addr0_wr", "@io_in_wen && @io_in_addr == 12'd%d && !%s0_L && !(%s1_L && %s1_A == 2'b01)"
         % (addr_base, c, c, c)),
        ("addr0_tor_lock", "@io_in_wen && @io_in_addr == 12'd%d && !%s0_L && %s1_L && %s1_A == 2'b01"
         % (addr_base, c, c, c)),
        ("addr31_wr", "@io_in_wen && @io_in_addr == 12'd%d && !%s31_L" % (addr_base + 31, c)),
        ("addr31_locked", "@io_in_wen && @io_in_addr == 12'd%d && %s31_L" % (addr_base + 31, c)),
        ("rd_napot", "@io_in_ren && @io_in_addr == 12'd%d && %s5_A[1]" % (addr_base + 5, c)),
        ("rd_tor", "@io_in_ren && @io_in_addr == 12'd%d && !%s5_A[1]" % (addr_base + 5, c)),
    ]


# pmpaddr 读值高 18 位恒 0（地址寄存器 46 位）。
PM_EXEMPT_RD = lambda pfx: ["io_out_%sAddrRData_%d[%d]" % (pfx, i, b)  # noqa: E731
                            for i in range(32) for b in range(46, 64)]

PAIRS = [
    Pair("SieModule", "sie_", clocked=True, stim=SIE_STIM, cov=SIE_COV,
         exempt=bits("rdata", S_VIEW_ZERO), cov_min=500),
    # sip.toMvip.LCOFIP：mvipIsAlias[13] = ~mideleg[13] & mvien[13]，而 mvien[13] 在本配置
    # 恒 0（MvienBundle.LCOFIE RO）→ valid/bits 折成常数 0（golden 里也是常数表达式）。
    Pair("SipModule", "sip_", cov=SIP_COV,
         exempt=bits("rdata", S_VIEW_ZERO) + ["toMvip_LCOFIP_valid", "toMvip_LCOFIP_bits"],
         cov_min=500),
    Pair("VSieModule", "vsie_", clocked=True, cov=VSIE_COV, exempt=VSIE_EXEMPT, cov_min=500),
    Pair("VSipModule", "vsip_", cov=VSIP_COV, exempt=bits("rdata", S_VIEW_ZERO), cov_min=500),
    Pair("MvipModule", "mvip_", clocked=True, stim=MVIP_STIM, cov=MVIP_COV,
         exempt=bits("rdata", S_VIEW_ZERO), cov_min=500),
    # hvip.LCOFIP 是 RO 且唯一写者（fromVSip.LCOFIP.valid）在 golden 里无端口 → 恒 0。
    Pair("HvipModule", "hvip_", clocked=True, stim=HVIP_STIM, cov=HVIP_COV,
         exempt=bits("rdata", [0, 1, 3, 4, 5, 7, 8, 9, 11, 12, 13]) + ["regOut_LCOFIP"],
         cov_min=500),
    Pair("MvienModule", "mvien_", clocked=True, cov=[("wr", "@w_wen")],
         exempt=bits("rdata", [0, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13]), cov_min=500),
    Pair("HvienModule", "hvien_", clocked=True, cov=[("wr", "@w_wen")],
         exempt=bits("rdata", range(0, 14)), cov_min=500),
    Pair("MStatusModule", "ms_", clocked=True, stim=MS_STIM, cov=MS_COV,
         exempt=MS_EXEMPT, mode_period=500, cov_min=200),
    Pair("TrapHandleModule", "th_", stim=TH_STIM, cov=TH_COV, exempt=TH_EXEMPT,
         mode_period=500, cov_min=100),
    Pair("PMPEntryHandleModule", "pmp_", clocked=True, stim=pm_stim("pmp", 0x3A0, 0x3B0),
         cov=pm_cov("pmp", 0x3A0, 0x3B0), exempt=PM_EXEMPT_RD("pmp"),
         mode_period=500, cov_min=100),
    Pair("PMAEntryHandleModule", "pma_", clocked=True, stim=pm_stim("pma", 0x7C0, 0x7C8),
         cov=pm_cov("pma", 0x7C0, 0x7C8), exempt=PM_EXEMPT_RD("pma"),
         mode_period=500, cov_min=100),
]

HEADER = """自动生成：verif/ut/CsrIrqHandle12/gen.py（scripts/dual_tb_lib.py，读 G1 golden 端口表）—— 勿手改
CsrIrqHandle12 双例化逐拍比对：12 对 golden <M> vs 重写 <M>_xs，全部输出逐位 !==。
激励偏置、覆盖项与常数位豁免的理由见 gen.py。"""

if __name__ == "__main__":
    txt = render(PAIRS, HEADER)
    sys.exit(write_or_check(os.path.join(HERE, "tb.sv"), txt, "--check" in sys.argv))
