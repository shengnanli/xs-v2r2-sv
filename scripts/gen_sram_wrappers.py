#!/usr/bin/env python3
"""
为单端口 SRAMTemplate 变体生成：
  1) rtl/common/SRAMTemplate_variants.sv      变体包装（golden 同名，FM/ST 用）
  2) verif/ut/SRAMTemplate/variants_xs.sv      _xs 镜像（UT 用）
  3) verif/ut/SRAMTemplate/tb.sv               全变体 golden vs _xs 随机比对
  4) verif/ut/SRAMTemplate/sram_deps.mk        各变体宏链文件依赖（UT/FM）

每个变体例化 xs_SRAMTemplate_core（功能核）+ 对应厂商 SRAM 宏黑盒。生成器从 golden
变体源码与其宏定义自动提取参数（SET/WAY/DATA/BORE_AW）与特征（reset/holdRead/
clockgate/有无 ready 口/有无 waymask），并解析宏子模块链（sram_array_*→array_N→
array_N_ext）。

仅处理“单端口、单读口、per-way 掩码”族（ICache 等）。多读口/双口/bitmask/多周期
变体会被检测并跳过（打印 SKIP）。
"""
import re
import sys
from pathlib import Path
pathlib_Path = Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = pathlib_Path("/home/eda/xs-env/G1-canonical/golden-rtl")

# 要覆盖的单端口 SRAMTemplate 变体（generator 自动提参/检测特征/解析宏链；
# 不支持形态——多读口/双口/bitmask/extra_reset——会被 supported 检测并 SKIP）
#   ICache：icsh_tag / icsh_dat
#   BPU 内层（被 Splitted/Folded 包裹）：bp_ftb(_36)、bp_tage(_45)
VARIANTS = None  # None = 自动枚举 G1 全部 SRAMTemplate* 变体（supported 检测过滤）


# impl 侧 MC 存储模型逐 variant 共读：**每个** variant 的 FM impl golden 依赖 = 它自己的 FM_REF_DEPS
# （见 Makefile 生成处的说明）。原先是一份名单 MC_SPLIT_VARIANTS（7 个），漏下的 variant 全部判
# green_child_impl_golden_mc_not_shared（rr-special §3.1）——改成生成器默认行为，不再维护名单。


def read(name):
    return (GOLDEN / f"{name}.sv").read_text()


def port_list(name):
    text = read(name)
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    assert m, name
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            d, w, n = pm.group(1), pm.group(2), pm.group(3)
            ports.append((d, int(w) + 1 if w else 1, n))
    return ports


def pwidth(ports, pname):
    for d, w, n in ports:
        if n == pname:
            return w
    return None


def has_port(ports, pname):
    return any(n == pname for _, _, n in ports)


def macro_chain(name):
    """返回 (macro, child_array, array_ext, macro_has_wmask, macro_has_bypass)"""
    text = read(name)
    macro = re.search(r"\b(sram_array_\w+)\s+array\s*\(", text).group(1)
    mtext = read(macro)
    mports = port_list(macro)
    has_wmask = has_port(mports, "RW0_wmask")
    has_bypass = has_port(mports, "mbist_dft_ram_bypass")
    child = re.search(r"^\s+(\w+)\s+array\s*\(", mtext, re.M).group(1)
    ctext = read(child)
    ext = re.search(r"\b(\w+_ext)\s+\w+\s*\(", ctext).group(1)
    return macro, child, ext, has_wmask, has_bypass


def analyze(name):
    ports = port_list(name)
    text = read(name)
    info = {}
    info["name"] = name
    info["aw"] = pwidth(ports, "io_r_req_bits_setIdx")
    info["set"] = 1 << info["aw"]
    info["way"] = len([1 for _, _, n in ports if re.match(r"io_w_req_bits_data_\d+$", n)])
    info["data_w"] = pwidth(ports, "io_r_resp_data_0")
    info["has_ready"] = has_port(ports, "io_r_req_ready")
    info["has_waymask"] = has_port(ports, "io_w_req_bits_waymask")
    info["extra_reset"] = has_port(ports, "extra_reset")
    info["bore_aw"] = pwidth(ports, "boreChildrenBd_bore_addr")
    info["bore_array_w"] = pwidth(ports, "boreChildrenBd_bore_array")
    info["reset"] = "_resetState" in text
    info["hold"] = "rdata_hold" in text
    info["clockgate"] = "MbistClockGateCell" in text
    # 读口数：io_r_resp_data_* 端口个数 / way
    nresp = len([1 for _, _, n in ports if re.match(r"io_r_resp_data_\d+$", n)])
    info["read_ports"] = nresp // max(info["way"], 1)
    info["ports"] = ports
    info["macro"], info["child"], info["ext"], info["m_wmask"], info["m_bypass"] = macro_chain(name)
    # ---- G1 锚点：一律从 golden 机械提取（宏名 + 该变体自己的端口表），不手填 ----
    # 宏名就是宏的规格书：sram_array_1p<SETS>x<BITS>m<MASK>s<S>h<H>l<LAT>b_<用途>。
    # 核在 elaborate 期拿这 6 个数去比对自己算出来的位宽（见 xs_SRAMTemplate_core
    # 的 §参数自检）；不传 = $fatal，所以生成器必须发，别指望事后手工补。
    mm = re.match(r"sram_array_1p(\d+)x(\d+)m(\d+)s(\d+)h(\d+)l(\d+)b_", info["macro"])
    assert mm, f"{name}: 宏名不符合 1p<SETS>x<BITS>m<MASK>s<S>h<H>l<LAT>b_ 规格: {info['macro']}"
    info["g1_sets"] = int(mm.group(1))
    info["g1_bits"] = int(mm.group(2))
    info["g1_mask"] = int(mm.group(3))
    info["g1_lat"] = int(mm.group(6))
    info["g1_way_ports"] = nresp            # golden io_r_resp_data_<k> 端口个数
    info["g1_bore_aw"] = info["bore_aw"]    # golden bore_addr 端口位宽
    info["bitmask"] = has_port(ports, "io_w_req_bits_flattened_bitmask")
    info["wmask_w"] = info["way"] * info["data_w"] if info["bitmask"] else info["way"]
    # G1 新形态检测（fail-closed：任何本核不驱动的输出端口都判不支持，
    # 绝不生成"输出悬空"的 wrapper——那会让 UT 比出 z 且 FM 伪等价）：
    #   external_cg : 模块把时钟门控外置（导出 mbistCgCtl_en/rckEn/wckEn + 取 rclk），
    #                 本核只支持内置 MbistClockGateCell ⇒ 需核扩展后才能覆盖；
    #   mask_repl   : 宏的 wmask 粒度细于 way（每 way 复制 N 位掩码，如 ptw_l1
    #                 786b/131b=6 位对 2 way）⇒ 需核支持掩码复制。
    info["external_cg"] = has_port(ports, "io_mbistCgCtl_en")
    mports = port_list(info["macro"])
    mwm = pwidth(mports, "RW0_wmask")
    info["mask_repl"] = (not info["bitmask"] and mwm is not None and mwm != info["way"])
    undriven = [n for d, w, n in ports if d == "output"
                and n.startswith("io_mbistCgCtl")]
    info["unsupported_reason"] = ("external_cg" if info["external_cg"] else
                                  "mask_repl" if info["mask_repl"] else
                                  f"undriven:{undriven[0]}" if undriven else
                                  "multi_read_port" if info["read_ports"] != 1 else
                                  "no_rdata_port" if pwidth(ports, "io_r_resp_data_0") is None
                                  else "")
    info["supported"] = not info["unsupported_reason"]
    return info


def emit_wrapper(info, suffix=""):
    n = info["name"] + suffix
    ports = info["ports"]
    way, dw, mw = info["way"], info["data_w"], info["way"] * info["data_w"]
    decls = []
    for d, w, nm in ports:
        ws = f"[{w-1}:0] " if w > 1 else ""
        decls.append(f"  {d:6s} {ws}{nm}")
    wmask_w = info["wmask_w"]
    L = [f"module {n}(", ",\n".join(decls) + "\n);"]
    L.append(f"  wire        ram_clk, ram_bypass, ram_bp_clken, ram_en, ram_wmode;")
    L.append(f"  wire [{info['aw']-1}:0]  ram_addr;")
    L.append(f"  wire [{wmask_w-1}:0]  ram_wmask;")
    L.append(f"  wire [{mw-1}:0] ram_wdata, ram_rdata;")

    # core 连接
    rdata_cat = "{" + ", ".join(f"io_r_resp_data_{i}" for i in reversed(range(way))) + "}" if way > 1 else "io_r_resp_data_0"
    wdata_cat = "{" + ", ".join(f"io_w_req_bits_data_{i}" for i in reversed(range(way))) + "}" if way > 1 else "io_w_req_bits_data_0"
    rdy = "io_r_req_ready" if info["has_ready"] else "/* no ready port */"
    if info["bitmask"]:
        wmask = "io_w_req_bits_flattened_bitmask"
    elif info["has_waymask"]:
        wmask = "io_w_req_bits_waymask"
    else:
        wmask = "1'b1"
    extra = "extra_reset" if info["extra_reset"] else "1'b0"
    L.append(f"  xs_SRAMTemplate_core #(")
    L.append(f"    .SET({info['set']}), .WAY({way}), .DATA_WIDTH({dw}), .BORE_AW({info['bore_aw']}),")
    L.append(f"    .ENABLE_RESET({int(info['reset'])}), .ENABLE_HOLDREAD({int(info['hold'])}),")
    L.append(f"    .ENABLE_CLOCKGATE({int(info['clockgate'])}), .EXTRA_RESET({int(info['extra_reset'])}),")
    L.append(f"    .USE_BITMASK({int(info['bitmask'])}),")
    L.append(f"    // G1 锚点（勿手改，全部来自 golden {info['name']}.sv）：")
    L.append(f"    //   宏名 sram_array_1p{info['g1_sets']}x{info['g1_bits']}m{info['g1_mask']}"
             f"...l{info['g1_lat']}b_* / io_r_resp_data_<k> 共 {info['g1_way_ports']} 个"
             f" / bore_addr {info['g1_bore_aw']} 位")
    L.append(f"    .G1_MACRO_SETS({info['g1_sets']}), .G1_MACRO_BITS({info['g1_bits']}), "
             f".G1_MACRO_MASK({info['g1_mask']}),")
    L.append(f"    .G1_MACRO_LAT({info['g1_lat']}), .G1_WAY_PORTS({info['g1_way_ports']}), "
             f".G1_BORE_AW({info['g1_bore_aw']})")
    L.append(f"  ) u_core (")
    L.append(f"    .clock(clock), .reset(reset), .io_extra_reset({extra}),")
    L.append(f"    .io_r_req_ready({rdy}),")
    L.append(f"    .io_r_req_valid(io_r_req_valid), .io_r_req_bits_setIdx(io_r_req_bits_setIdx),")
    L.append(f"    .io_r_resp_data({rdata_cat}),")
    L.append(f"    .io_w_req_valid(io_w_req_valid), .io_w_req_bits_setIdx(io_w_req_bits_setIdx),")
    L.append(f"    .io_w_req_bits_data({wdata_cat}), .io_w_mask({wmask}),")
    # 清零完成：本族这 33 个变体的 golden 端口表里都没有这根线（既不叫 io_resetDone
    # 也不当 io_w_req_ready 用），核里照样无条件驱动它 —— 所以显式写成空连接，表示
    # "知道有、故意不接"，而不是漏连。省掉这一行 = 整芯片 elaborate 的
    # Warning-[TFIPC]（UT 侧编译开了 +lint=TFIPC-L，则是同一条的逐端口明细）。
    L.append(f"    .io_resetDone(/* 本变体 golden 不引出清零完成 */),")
    L.append(f"    .io_broadcast_ram_hold(io_broadcast_ram_hold),")
    L.append(f"    .io_broadcast_ram_bypass(io_broadcast_ram_bypass),")
    L.append(f"    .io_broadcast_ram_bp_clken(io_broadcast_ram_bp_clken),")
    L.append(f"    .io_broadcast_cgen(io_broadcast_cgen),")
    # 外置时钟门控接口：本族这 33 个变体一律 EXT_CLOCKGATE=0（门控单元在核内例化，
    # 或宏时钟直连 clock），三个使能输出不外引，rclk 被核里的 generate-if 挡在
    # EXT_CLOCKGATE=1 分支内、根本不会被读 —— 功能上无风险，但必须显式写出来。
    # 输入钉 1'b0 而不是留空：与已签核的 9 个新形态变体（128/145/146/152/155/163/
    # 166/178/185）同一写法。实测 VCS 对 .写错的端口名() 与 .写错的端口名(1'b0)
    # 报的都是 Error-[UPIMI-E]，两种写法同等 fail-closed，于是按家族统一取后者。
    L.append(f"    .io_mbistCgCtl_en(/* 门控不外置 */), .io_mbistCgCtl_rckEn(/* 门控不外置 */),")
    L.append(f"    .io_mbistCgCtl_wckEn(/* 门控不外置 */), .io_mbistCgCtl_rclk(1'b0),")
    L.append(f"    .boreChildrenBd_bore_addr(boreChildrenBd_bore_addr),")
    L.append(f"    .boreChildrenBd_bore_addr_rd(boreChildrenBd_bore_addr_rd),")
    L.append(f"    .boreChildrenBd_bore_wdata(boreChildrenBd_bore_wdata),")
    bwmask = "boreChildrenBd_bore_wmask" if info["has_waymask"] else "boreChildrenBd_bore_wmask"
    L.append(f"    .boreChildrenBd_bore_wmask({bwmask}),")
    L.append(f"    .boreChildrenBd_bore_re(boreChildrenBd_bore_re),")
    L.append(f"    .boreChildrenBd_bore_we(boreChildrenBd_bore_we),")
    L.append(f"    .boreChildrenBd_bore_rdata(boreChildrenBd_bore_rdata),")
    L.append(f"    .boreChildrenBd_bore_ack(boreChildrenBd_bore_ack),")
    L.append(f"    .boreChildrenBd_bore_selectedOH(boreChildrenBd_bore_selectedOH),")
    L.append(f"    .ram_clk(ram_clk), .ram_bypass(ram_bypass), .ram_bp_clken(ram_bp_clken),")
    L.append(f"    .ram_addr(ram_addr), .ram_en(ram_en), .ram_wmode(ram_wmode),")
    L.append(f"    .ram_wmask(ram_wmask), .ram_wdata(ram_wdata), .ram_rdata(ram_rdata)")
    L.append(f"  );")

    # 宏例化（按宏实际端口）
    L.append(f"  {info['macro']} array (")
    if info["m_bypass"]:
        L.append(f"    .mbist_dft_ram_bypass(ram_bypass), .mbist_dft_ram_bp_clken(ram_bp_clken),")
    L.append(f"    .RW0_clk(ram_clk), .RW0_addr(ram_addr), .RW0_en(ram_en), .RW0_wmode(ram_wmode),")
    if info["m_wmask"]:
        L.append(f"    .RW0_wmask(ram_wmask),")
    L.append(f"    .RW0_wdata(ram_wdata), .RW0_rdata(ram_rdata)")
    L.append(f"  );")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(infos):
    L = ["""// 自动生成：scripts/gen_sram_wrappers.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 40000;
  int unsigned WARMUP  = 400;   // 等最大 set 的 reset FSM 清零完成
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;
"""]
    for info in infos:
        nm = info["name"]
        pre = "v" + nm
        ins = [(w, n) for d, w, n in info["ports"] if d == "input" and n not in ("clock", "reset")]
        outs = [(w, n) for d, w, n in info["ports"] if d == "output"]
        for w, n in ins:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  logic {ws}{pre}_{n};")
        for w, n in outs:
            ws = f"[{w-1}:0] " if w > 1 else ""
            L.append(f"  wire {ws}{pre}_g_{n};")
            L.append(f"  wire {ws}{pre}_i_{n};")
        gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({pre}_{n})" for _, n in ins]
        ic = list(gc)
        gc += [f".{n}({pre}_g_{n})" for _, n in outs]
        ic += [f".{n}({pre}_i_{n})" for _, n in outs]
        L.append(f"  {nm} u_g_{nm} ({', '.join(gc)});")
        L.append(f"  {nm}_xs u_i_{nm} ({', '.join(ic)});")
        # 激励
        L.append("  always @(negedge clk) begin")
        L.append("    if (rst) begin")
        for w, n in ins:
            if re.search(r"(valid|_re$|_we$|_ack$|_hold$)", n):
                L.append(f"      {pre}_{n} <= 1'b0;")
        L.append("    end else begin")
        for w, n in ins:
            if re.search(r"req_valid$", n):
                pct = "($urandom_range(0,2)==0)" if "_w_" in n else "($urandom_range(0,3)!=0)"
                L.append(f"      {pre}_{n} <= {pct};")
            elif re.search(r"(_re$|_we$|_ack$)", n):
                L.append(f"      {pre}_{n} <= ($urandom_range(0,7)==0);")
            elif re.search(r"ram_hold$", n):
                L.append(f"      {pre}_{n} <= ($urandom_range(0,15)==0);")
            elif re.search(r"(bypass|bp_clken|aux_clk|aux_ckbp|mcp_hold)$", n):
                L.append(f"      {pre}_{n} <= 1'b0;")
            elif w <= 32:
                L.append(f"      {pre}_{n} <= {w}'($urandom);")
            else:
                rep = (w + 31) // 32
                rnd = "{" + ", ".join(["$urandom()"] * rep) + "}"
                L.append(f"      {pre}_{n} <= {w}'({rnd});")
        L.append("    end")
        L.append("  end")
        L.append("  always @(negedge clk) if (!rst && cycle > WARMUP) begin")
        L.append("    #4; checks++;")
        for w, n in outs:
            L.append(f"    if ({pre}_g_{n} !== {pre}_i_{n}) begin errors++;")
            L.append(f"      $display(\"[%0t] {nm}.{n} g=%h i=%h\", $time, {pre}_g_{n}, {pre}_i_{n}); end")
        L.append("  end")
        L.append("")
    L.append("""  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 40000;
    $fsdbDumpfile("novas.fsdb"); $fsdbDumpvars(0, tb);
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(L)


# negtest 段：UT Makefile 的一部分，**由生成器发**，不许手工贴在产物后面。
# 教训（tlbuffer lane 实测）：手工贴在生成产物末尾的段，谁跑一次生成器它就被静默
# 删掉，而那往往正是该家族唯一病因形态的防护。本族踩的是同一个坑 —— 这一段和上面
# 的 6 个 G1_* 锚点，2026-09-14 之前都是手工补的，一跑生成器就全没。
NEGTEST_MK = r"""
# ---------------------------------------------------------------------------
# negtest：G1 锚点不变式的必失败负测（codex 0145 决策三要求"错误参数放一个必失败
# 负测"）。negtest.sv 拿 SRAMTemplate_148 的规格做原型，三个负例各只抄错一处参数：
#   NEG_DW_NARROW 位宽抄小 / NEG_WAY_SPLIT way 劈错(乘积仍对) / NEG_NO_ANCHOR 不传锚点。
# 判据：三个都必须让 VCS 在 **elaborate 期** 非零退出（Error-[FEST]）。
# 任何一个能链接成功 = 不变式形同虚设，判 FAIL。
# 注意：这里不用 $(VCS)（不需要 -kdb/-debug_access，负测只看 elaborate 是否炸）。
NEG_CASES = NEG_DW_NARROW NEG_WAY_SPLIT NEG_NO_ANCHOR
.PHONY: negtest
negtest:
	@rc=0; for c in $(NEG_CASES); do \
	  rm -rf neg_csrc simv_neg simv_neg.daidir; \
	  if vcs -full64 -sverilog -Mdir=neg_csrc +define+SYNTHESIS +define+$$c \
	         $(RTL_DIR)/common/xs_SRAMTemplate_core.sv negtest.sv \
	         -top neg_sram_probe -o simv_neg > neg_$$c.log 2>&1; then \
	    echo "=== NEGTEST FAILED ($$c)：抄错的参数竟然 elaborate 过了 ==="; rc=1; \
	  elif grep -q 'Error-\[FEST\]' neg_$$c.log; then \
	    echo "=== NEGTEST PASSED ($$c)：elaborate 期被不变式拦下 ==="; \
	    sed -n '/FEST/,/^$$/p' neg_$$c.log | grep -m2 'msg:' || true; \
	  else \
	    echo "=== NEGTEST FAILED ($$c)：编译是失败了, 但不是 \$$fatal 不变式拦的(看 neg_$$c.log) ==="; \
	    grep -m3 -E '^Error' neg_$$c.log || true; rc=1; \
	  fi; \
	done; rm -rf neg_csrc simv_neg simv_neg.daidir; exit $$rc
"""


def main():
    # --check：只重算、不写盘，逐字节比对现有产物（进 scripts/gate_all.sh 的幂等闸）。
    check = "--check" in sys.argv[1:]
    names = ([p.stem for p in sorted(GOLDEN.glob("SRAMTemplate*.sv"))]
             if VARIANTS is None else VARIANTS)
    infos, skipped = [], []
    for v in names:
        try:
            info = analyze(v)
        except Exception as e:                      # 形态不符(无宏链/端口异常)
            skipped.append(f"{v}(analyze:{type(e).__name__})")
            continue
        if info["supported"]:
            infos.append(info)
        else:
            skipped.append(f"{v}({info['unsupported_reason']})")

    hdr = ("// 自动生成：scripts/gen_sram_wrappers.py（G1 基线驱动）—— 勿手改\n"
           "// 变体薄文件：例化 xs_SRAMTemplate_core（rtl/common/xs_SRAMTemplate_core.sv）\n"
           "// + 厂商 SRAM 宏（golden 同源，两侧同读；唯一黑盒是宏内 *_ext 叶子）\n")
    common = XSSV / "rtl/common"

    ut = XSSV / "verif/ut/SRAMTemplate"

    # 宏链依赖：UT 需 array_*_ext.v 行为模型；FM 两侧同读宏与 array_N（不读 ext）
    sim_deps, fm_deps, fm_ref = set(), set(), {}
    for i in infos:
        sim_deps |= {i["macro"] + ".sv", i["child"] + ".sv", i["ext"] + ".v"}
        fm_deps |= {i["macro"] + ".sv", i["child"] + ".sv"}
        deps = [i["macro"] + ".sv", i["child"] + ".sv"]
        if i["clockgate"]:
            deps += ["MbistClockGateCell.sv", "ClockGate.sv"]
            fm_deps |= {"MbistClockGateCell.sv", "ClockGate.sv"}
            sim_deps |= {"MbistClockGateCell.sv", "ClockGate.sv"}
        fm_ref[i["name"]] = deps

    # 本地已重写签核的共享基元：impl 侧（RTL_GOLDEN_DEPS）读本地件，ref 侧照旧读 golden。
    # 与 scripts/ut_common.mk 的 LOCAL_SHARED_PRIMITIVES 同一份清单（那边有 fail-closed 闸）。
    LOCAL_PRIMITIVES = {"ClockGate.sv": "$(XSSV_HOME)/rtl/common/ClockGate.sv"}
    rtl_srcs = ["$(RTL_DIR)/common/xs_SRAMTemplate_core.sv"]
    rtl_srcs += [f"$(RTL_DIR)/common/{i['name']}.sv" for i in infos]
    mk = ["# 自动生成：scripts/gen_sram_wrappers.py（G1 基线驱动）—— 勿手改",
          "MODULE = SRAMTemplate", "", "RTL_DIR = ../../../rtl",
          "RTL_SRCS = " + " \\\n           ".join(rtl_srcs),
          "TB_SRCS = tb.sv", "",
          "# 厂商 SRAM 宏链：golden 同源文件, 两侧同读(FM impl 侧经 RTL_GOLDEN_DEPS)。",
          "# 宏内 array_*_ext 是 vendor 叶子(.v, FM 不读)⇒ 对称未解析黑盒, 见 FM_MODE 说明。",
          "# ClockGate 例外：impl 侧读本地重写签核件 rtl/common/ClockGate.sv（codex 0208），",
          "# ref 侧 FM_REF_DEPS 仍是 golden ClockGate.sv。",
          "RTL_GOLDEN_DEPS = " + " \\\n                  ".join(
              LOCAL_PRIMITIVES.get(d, f"$(GOLDEN_RTL)/{d}") for d in sorted(fm_deps)),
          ""]
    # codex 0222/0226：impl 侧 MC 存储模型须与 ref 侧逐字节共读（proof_certificate 的 mc_not_shared 判据）。
    # 每个 variant 的 FM impl 只读自己 golden 闭包里真用到的那几份 = 它的 FM_REF_DEPS（ClockGate 换本地签核件）。
    # 默认对全部 variant 生效（rr-mcnarrow，2026-10-20）；原 MC_SPLIT_VARIANTS 那 7 行字节不变。
    # UT（simv）仍用上面整张 RTL_GOLDEN_DEPS。
    if infos:
        mk += ["# codex 0222/0226：impl 侧 MC 存储模型必须与 ref 侧逐字节共读（proof_certificate 的 mc_not_shared 判据）——",
               "# 每个 variant 的 FM impl 只给自己 golden 闭包里真用到的那几份（= 它的 FM_REF_DEPS；生成器默认，UT 不变）。"]
        for i in infos:
            mk.append(f"fm-{i['name']}: RTL_GOLDEN_DEPS = " + " ".join(
                LOCAL_PRIMITIVES.get(d, f"$(GOLDEN_RTL)/{d}") for d in sorted(fm_ref[i["name"]])))
        mk += ["", ""]
    mk += [
          "GOLDEN_SRCS = " + " \\\n              ".join(
              [f"$(GOLDEN_RTL)/{i['name']}.sv" for i in infos]
              + [f"$(GOLDEN_RTL)/{d}" for d in sorted(sim_deps)]),
          ""]
    for i in infos:
        mk.append(f"FM_REF_DEPS_{i['name']} = " + " ".join(fm_ref[i["name"]]))
    mk += ["",
           "# FM_MODE=assembly: 唯一抽象边界 = 厂商 SRAM 宏叶子 array_*_ext(.v 行为模型,",
           "# 两侧同一文件, FM 不读 ⇒ 对称未解析黑盒)。老战役 reviewer 裁定: vendor 宏",
           "# 无条件可黑盒。allowlist 为对称未匹配点配额(非对称一律 PARTIAL, 见 fm_verdict)。",
           "FM_MODE = assembly",
           "FM_ALLOWLIST ?= 8",
           "FM_VARIANTS = " + " ".join(i["name"] for i in infos), "",
           "include ../../../scripts/ut_common.mk", "",
           "VCS += +define+SYNTHESIS", ""]

    # ---- 全部产物先攒齐，再统一写盘 / 比对（--check 幂等闸靠这个）------------
    outputs = {}
    for i in infos:
        outputs[common / f"{i['name']}.sv"] = hdr + emit_wrapper(i)
    outputs[ut / "tb.sv"] = emit_tb(infos)
    outputs[ut / "Makefile"] = "\n".join(mk) + NEGTEST_MK

    if check:
        drift = [q for q, c in sorted(outputs.items())
                 if (not q.exists()) or q.read_text() != c]
        for q in drift:
            print(f"DRIFT: {q.relative_to(XSSV)}")
        if drift:
            print(f"★ {len(drift)}/{len(outputs)} 个产物与生成器重算结果不一致。"
                  f"手改生成产物 = 下一次跑生成器时被静默删掉，先把差异并回生成器。")
            return 1
        print(f"生成器幂等 OK：{len(outputs)} 个产物与 G1 golden 重算结果逐字节一致")
        return 0

    for q, c in outputs.items():
        q.parent.mkdir(parents=True, exist_ok=True)
        q.write_text(c)

    print(f"covered {len(infos)} variants")
    for i in infos:
        print(f"  {i['name']}: set={i['set']} way={i['way']} dw={i['data_w']} "
              f"reset={int(i['reset'])} hold={int(i['hold'])} cg={int(i['clockgate'])} "
              f"macro={i['macro']}")
    if skipped:
        print(f"SKIPPED({len(skipped)}): {', '.join(str(s) for s in skipped)}")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
