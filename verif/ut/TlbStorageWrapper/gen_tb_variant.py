#!/usr/bin/env python3
"""tb_<n>.sv 生成器 —— TlbStorageWrapper 家族变体的双例化逐拍比对 testbench。

本文件原来是 gen_tb_1.py（只生成变体 _1）。2026-09-20 加 _2/_3 时改成按 --top 参数化：
端口表、读端口数、内层阵列名全部从 golden 读，所以三个变体共用同一份 tb 生成逻辑，
不用把 200 行 tb 抄三遍。

★重构是保值的★：`--top TlbStorageWrapper_1` 重新生成的 tb_1.sv 与重构前
**逐字节相同**（判据见 --check-1），所以变体 _1 已签核的那套 UT 语义没有被动过。

★2026-09-20 实测补强：纯均匀随机激励的命中率是 0，UT 等于只在验"两边都 miss"★
  vpn 是 38 位均匀随机、entry.tag 也是 35 位均匀随机，48 条全相联 ——
  单端口单拍命中概率 ~ 48 * 2^-35 ~= 1.4e-9，200k 拍的期望命中数 ~ 3e-4。
  而 do_check 里**除 hit 外的每一个 resp 字段都由 `g_hit &&` 把门**，所以
  "errors=0 / checks=200000" 实际只证明了 hit 恒等于 0 —— 命中路径、替换器
  (Tree-PLRU)、每端口的 vpn 路由**一位都没验到**。
  变异实测佐证（8000 拍）：C1/C2(PLRU 更新)、W1/W2(touch way 与 refill wayIdx 接线)、
  W3(端口 0 vpn 误接端口 1) 五个真 bug **全都没被抓出来**。
  修法 = 加 drive_pooled()：读写 vpn/tag 都取自 POOL=64 的小值域（>48 路，
  按构造强制发生替换），与原均匀随机各占一半拍。原 drive_random() 一字未改，
  所以它原有的 sfence/s2xlate/边界覆盖一点没丢。
  并加**覆盖闸**：命中数/替换数/双端口同拍命中数/sfence 数任一为 0 就判 TEST FAILED，
  防止"激励退化成 miss-only"再次悄悄发生。

结构与变体 0 的手写 tb.sv 一一对应：
  - 随机激励 200k 拍，逐拍比全部输出（resp 数据段只在 golden 命中时比 —— 未命中时
    golden 里是 OR 树残值，是 don't-care）；
  - directed_mbmc_sfence(): 钉 io_csr_mbmc_BME/CMODE 必须透传给内层 TLBFA_<n>，
    并且**先自证前提成立**（写入后 golden 必须命中、sfence 后 golden 必须失效），
    前提不成立就报错而不是静默算过。

用法：
  python3 gen_tb_variant.py --top TlbStorageWrapper_2     # 写 tb_2.sv
  python3 gen_tb_variant.py --all                          # 写 tb_1/tb_2/tb_3.sv
  python3 gen_tb_variant.py --check                        # 幂等闸：产物必须与生成器一致
"""
import argparse
import sys
import re, os

GOLDEN_DIR = "/home/eda/xs-env/G1-canonical/golden-rtl"
VARIANTS = ["TlbStorageWrapper_1", "TlbStorageWrapper_2", "TlbStorageWrapper_3"]

def parse_ports(path, top):
    s = open(path).read()
    m = re.search(r'module %s\((.*?)\n\);' % top, s, re.S)
    ports = []
    for line in m.group(1).split(","):
        line = line.strip()
        if not line:
            continue
        mm = re.match(r'(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)$', line)
        assert mm, repr(line)
        hi = int(mm.group(2)) if mm.group(2) else 0
        ports.append((mm.group(1), hi + 1, mm.group(4)))
    return ports

def decl(w, name, kind="logic"):
    return "  %s %s%s;" % (kind, ("[%d:0] " % (w - 1)) if w > 1 else "", name)

def rnd(w, name):
    """按端口语义给随机激励，和 tb.sv 的 drive_random 对齐。"""
    if re.search(r'_s2xlate$', name) and '_r_req_' in name:
        return "    %s = ($urandom_range(0,1)) ? 2'($urandom_range(0,3)) : 2'b0;" % name
    if re.search(r'_entry_level$', name):
        return "    %s = 2'($urandom_range(0,2));" % name
    if w == 1:
        return "    %s = $urandom_range(0,1);" % name
    if w <= 32:
        return "    %s = %d'($urandom);" % (name, w)
    words = (w + 31) // 32
    return "    %s = {%s};" % (name, ", ".join(["$urandom"] * words))


def build(TOP):
    GOLDEN = os.path.join(GOLDEN_DIR, TOP + ".sv")
    SUF = TOP.split("_")[-1]              # 变体号，用于 tb_<n>.sv / 内层 TLBFA_<n>
    CHILD = "TLBFA_" + SUF
    ports = parse_ports(GOLDEN, TOP)
    ins   = [p for p in ports if p[0] == 'input'  and p[2] not in ('clock', 'reset')]
    outs  = [p for p in ports if p[0] == 'output']
    nread = 1 + max(int(m.group(1)) for m in
                    (re.match(r'io_r_req_(\d+)_valid', p[2]) for p in ins) if m)

    L = []
    A = L.append
    A("// 自动生成：verif/ut/TlbStorageWrapper/gen_tb_variant.py —— 勿手改（改生成器后重跑）")
    A("// " + TOP + "（%d 读端口 / 48 路全相联）双例化逐拍比对:" % nread)
    A("//   golden " + TOP + "  vs  可读重写 " + TOP + "_xs。")
    A("// 含 directed_mbmc_sfence(): 钉 io_csr_mbmc_BME/CMODE 必须透传给内层 TLBFA_1。")
    A("`timescale 1ns/1ps")
    A("module tb;")
    A("  int unsigned NVEC = 200000;")
    A("  int errors = 0, checks = 0;")
    A("  // ---- 覆盖计数（只看 golden 侧，激励是否真把路径走到了）----")
    for k in range(nread):
        A("  longint cov_hit_%d = 0;" % k)
    A("  longint cov_hit_multi = 0;   // 同一拍两个及以上读端口同时命中（PLRU 多端口叠加序）")
    A("  longint cov_refill_pool = 0; // 池模式下的 refill 次数（>48 即已强制发生替换）")
    A("  longint cov_sfence = 0;")
    A("  longint cov_pool = 0;        // 走池模式的拍数")
    A("  bit     cov_ok;")
    A("  int     POOLPCT = 50;        // 池化激励占比（%），+poolpct=<n> 可改")
    A("  logic clock = 0, reset;")
    A("  always #5 clock = ~clock;")
    for _, w, n in ins:
        A(decl(w, n))
    for _, w, n in outs:
        A(decl(w, "g_" + n, "wire"))
        A(decl(w, "i_" + n, "wire"))
    A("")

    def inst(mod, u, pfx):
        conns = [".clock(clock)", ".reset(reset)"]
        conns += [".%s(%s)" % (n, n) for _, _, n in ins]
        conns += [".%s(%s%s)" % (n, pfx, n) for _, _, n in outs]
        return "  %s %s (%s);" % (mod, u, ", ".join(conns))

    A(inst(TOP, "u_g_", "g_"))
    A(inst(TOP + "_xs", "u_i_", "i_"))
    A("")

    A("  task automatic do_check(int t);")
    A("    checks++;")
    A("    // 覆盖统计：以 golden 的 hit 为准（比较窗口里它就是黄金事实）")
    for k in range(nread):
        A("    if (g_io_r_resp_%d_bits_hit) cov_hit_%d++;" % (k, k))
    A("    if ((%s) >= 2) cov_hit_multi++;" %
      " + ".join("32'(g_io_r_resp_%d_bits_hit)" % k for k in range(nread)))
    for _, w, n in outs:
        m = re.match(r'io_r_resp_(\d+)_bits_(.*)', n)
        port, field = m.group(1), m.group(2)
        fmt = "%b" if w == 1 else "%h"
        if field == "hit":
            cond = "g_%s !== i_%s" % (n, n)
        else:
            # 未命中时 resp 的数据段是 don't-care（golden 里是 OR 树残值），只在命中时比
            cond = "g_io_r_resp_%s_bits_hit && (g_%s !== i_%s)" % (port, n, n)
        A("    if (%s) begin errors++;" % cond)
        A('      if(errors<=80) $display("vec %%0d %s g=%s i=%s",t,g_%s,i_%s); end' % (n, fmt, fmt, n, n))
    A("  endtask")
    A("")

    A("  task automatic drive_random();")
    A("    automatic int act = $urandom_range(0,9);")
    for _, w, n in ins:
        if n == 'io_w_valid':
            A("    io_w_valid = ($urandom_range(0,3) == 0);")
        elif n == 'io_sfence_valid':
            A("    io_sfence_valid = (act == 0);")
        else:
            A(rnd(w, n))
    A("  endtask")
    A("")

    # -----------------------------------------------------------------------
    # 池化激励：让"命中"真的发生
    #
    # 命中条件（见 rtl/memblock/xs_TLBFA_core.sv 的 entry_hit）在 s2xlate=00 下化简为：
    #     entry.v && entry.s2xlate==req.s2xlate && (entry.asid==asid || entry.perm.g)
    #  && 全部 tag 段相等 && entry.valididx[vpn[2:0]]
    # 取 entry.tag = 35'(k)、req.vpn = {35'(k), 3'(j)}，k < POOL <= 64：
    #   tag_match[0] 比 tag[5:0] vs vpn[8:3] = k[5:0]  → k 不同即不同（POOL<=64 才成立）
    #   其余各段两边都是 0 → 恒等
    # 所以命中 ⟺ 该 k 还驻留在阵列里。level 取 0（4KB，非超页）⇒ 全部 tag 段都要比，
    # 不给"超页放行低段"留后门。perm.g=1 ⇒ asid 不参与，命中不受随机 asid 干扰。
    #
    # ★POOL=64 > NWAYS=48 是故意的★：按构造必然发生替换，Tree-PLRU 选错路就会把
    # 别的 k 顶出去，下一次查那个 k 两侧结果不同 —— 这正是 C1/C2/W1/W2 变异体的抓手。
    # entry 的 ppn / ppn_low / perm 都做成 k 的函数，所以"命中了但命中的是别的路"
    # 也会在数据段上暴露，而不只是 hit 位。
    # -----------------------------------------------------------------------
    have = {n for _, _, n in ins}
    A("  localparam int POOL = 64;   // > NWAYS(48)，按构造强制替换")
    A("  task automatic drive_pooled();")
    A("    automatic int kw = $urandom_range(0, POOL-1);   // 本拍要写的 tag")
    for k in range(nread):
        A("    automatic int kr%d = $urandom_range(0, POOL-1);" % k)
    A("    drive_random();                                 // 先铺满所有输入，再覆盖池相关的")
    A("    cov_pool++;")
    A("    io_sfence_valid = ($urandom_range(0,63) == 0);  // 池模式下少发 sfence，否则驻留留不住")
    for k in range(nread):
        if ("io_r_req_%d_bits_vpn" % k) in have:
            A("    io_r_req_%d_valid     = 1'b1;" % k)
            A("    io_r_req_%d_bits_vpn  = {35'(kr%d), 3'($urandom_range(0,7))};" % (k, k))
            A("    io_r_req_%d_bits_s2xlate = 2'b00;" % k)
    A("    io_w_valid = ($urandom_range(0,3) == 0);")
    A("    if (io_w_valid) cov_refill_pool++;")
    A("    io_w_bits_data_s2xlate            = 2'b00;")
    A("    io_w_bits_data_s1_entry_tag       = 35'(kw);")
    A("    io_w_bits_data_s1_entry_n         = 1'b0;    // 非 NAPOT：低位也要比")
    A("    io_w_bits_data_s1_entry_level     = 2'd0;    // 4KB：全部 tag 段都要比")
    A("    io_w_bits_data_s1_entry_v         = 1'b1;")
    A("    io_w_bits_data_s1_entry_perm_g    = 1'b1;    // global ⇒ asid 不参与命中")
    A("    // 数据段做成 kw 的函数：命中错路会在 ppn/perm 上暴露，而不只是 hit 位")
    A("    io_w_bits_data_s1_entry_ppn       = 41'(kw * 8191 + 1);")
    for j in range(8):
        A("    io_w_bits_data_s1_ppn_low_%d      = 3'(kw + %d);" % (j, j))
        A("    io_w_bits_data_s1_valididx_%d     = 1'b1;" % j)
        A("    io_w_bits_data_s1_pteidx_%d       = 1'b1;" % j)
    A("    io_w_bits_data_s1_entry_perm_r    = kw[0];")
    A("    io_w_bits_data_s1_entry_perm_w    = kw[1];")
    A("    io_w_bits_data_s1_entry_perm_x    = kw[2];")
    A("    io_w_bits_data_s1_entry_perm_u    = kw[3];")
    A("    io_w_bits_data_s1_entry_perm_a    = kw[4];")
    A("    io_w_bits_data_s1_entry_perm_d    = kw[5];")
    A("    io_w_bits_data_s1_pf              = kw[0];")
    A("    io_w_bits_data_s1_af              = kw[1];")
    A("  endtask")
    A("")

    # ---- directed: mbmc 透传（与 tb.sv 同一套, 只用读端口 0）----
    A(("""  // ---------------------------------------------------------------------------
  // 定向激励: sfence 的失效范围要看 mbmc.BME/CMODE（golden {CHILD}.sv）
  //   else if (io_sfence_valid & ~hg & ~hv)
  //     if (rs1 | priv_virt | io_csr_mbmc_BME & ~io_csr_mbmc_CMODE)
  //   本层只透传这两根线。透传漏了 ⇒ 内层输入悬空 ⇒ if(x) 判假 ⇒ 掉进按地址失效的
  //   `else if (rs2)` 分支。所以 sfence 地址必须**不匹配**写入的 tag，否则两侧都失效、
  //   激励白做（addr[49:39] 全 1 vs tag[34:24]=0）。
  // ---------------------------------------------------------------------------
  int directed_errors = 0;
  task automatic dir_clear();""").format(CHILD=CHILD))
    for _, w, n in ins:
        A("    %s = '0;" % n)
    A("  endtask")
    A("")
    A("  task automatic dir_write_one_entry();")
    A("    // s2xlate=0 / perm_g=1 / level=3 / valididx 全 1 ⇒ 读回命中只取决于 v_way")
    A("    io_w_valid = 1;")
    wnames = {n for _, _, n in ins}
    def setw(n, v):
        if n in wnames:
            A("    %s = %s;" % (n, v))
    setw("io_w_bits_data_s2xlate", "2'b00")
    setw("io_w_bits_data_s1_entry_perm_g", "1'b1")
    setw("io_w_bits_data_s1_entry_perm_r", "1'b1")
    setw("io_w_bits_data_s1_entry_level", "2'b11")
    setw("io_w_bits_data_s1_entry_v", "1'b1")
    for i in range(8):
        setw("io_w_bits_data_s1_valididx_%d" % i, "1'b1")
    A("    @(posedge clock); #1;")
    A("    io_w_valid = 0;")
    A("    @(posedge clock); #1;   // 等 refill_mask 落下")
    A("  endtask")
    A("")
    A("  task automatic dir_read(output logic gh, output logic ih);")
    A("    io_r_req_0_valid = 1; io_r_req_0_bits_vpn = '0; io_r_req_0_bits_s2xlate = '0;")
    A("    @(posedge clock); #1;")
    A("    gh = g_io_r_resp_0_bits_hit;")
    A("    ih = i_io_r_resp_0_bits_hit;")
    A("    io_r_req_0_valid = 0;")
    A("  endtask")
    A("")
    A("""  task automatic directed_mbmc_sfence();
    logic gh, ih;
    dir_clear();
    @(posedge clock); #1;
    dir_write_one_entry();
    dir_read(gh, ih);
    if (gh !== 1'b1) begin
      directed_errors++;
      $display("DIRECTED mbmc: 前提不成立 —— 写入后 golden 未命中 (g_hit=%%b), 激励假设错了", gh);
    end
    if (ih !== gh) begin
      directed_errors++;
      $display("DIRECTED mbmc: 写入/读回阶段就已失配 g_hit=%%b i_hit=%%b", gh, ih);
    end
    io_sfence_valid = 1; io_sfence_bits_rs1 = 0; io_sfence_bits_rs2 = 1;
    io_sfence_bits_addr = {11'h7FF, 39'h0};
    io_sfence_bits_hv = 0; io_sfence_bits_hg = 0;
    io_csr_priv_virt = 0; io_csr_mbmc_BME = 1; io_csr_mbmc_CMODE = 0;
    @(posedge clock); #1;
    io_sfence_valid = 0;
    @(posedge clock); #1;
    dir_read(gh, ih);
    if (gh !== 1'b0) begin
      directed_errors++;
      $display("DIRECTED mbmc: 前提不成立 —— BME sfence 后 golden 仍命中 (g_hit=%%b), 激励假设错了", gh);
    end
    if (ih !== gh) begin
      directed_errors++;
      $display("DIRECTED mbmc MISMATCH: sfence(BME=1,CMODE=0,rs1=0,priv_virt=0) 后 g_hit=%%b i_hit=%%b —— io_csr_mbmc_BME/CMODE 没透传给内层 %s", gh, ih);
    end
    dir_clear();
    @(posedge clock); #1;
    $display("DIRECTED mbmc_sfence errors=%%0d", directed_errors);
  endtask
""" % CHILD)
        # -------------------------------------------------------------------
    # ★每个读端口都要先发一拍 valid 请求，比较窗口才有意义★
    #   （2026-09-20 实测定位，见本文件下方注释与 selfcmp.sh）
    # golden 的 hitVecReg_<port>_<way> 是 RegEnable(..., io_r_req_<port>_valid)：
    #   **该端口收到第一个 valid 请求之前，它一直保持上电随机值**。而 resp.hit /
    #   resp.ppn 都是这 48 位的或树，于是该端口在被用过之前，响应完全是上电噪声。
    # 定向段只驱动端口 0，所以端口 1..N-1 的第一拍比较比的是两边各自的随机初值 ——
    #   ★用 golden 对 golden 的自比实测过：seed=7 + initreg=random 时
    #     两个**逐字节相同**的 golden 实例在 vec 0 就不一致★（g=ffffffffe / i=fffffffbf）。
    #   也就是说这一拍任何实现都过不去，它量的不是设计而是随机数。
    # 加了这段预热后，7 个 seed 的 golden 自比全部 errors=0。
    # -------------------------------------------------------------------
    A("  task automatic dir_warm_ports();")
    A("    dir_clear();")
    for k in range(nread):
        A("    io_r_req_%d_valid = 1;" % k)
    A("    repeat (2) @(posedge clock); #1;")
    A("    dir_clear();")
    A("    @(posedge clock); #1;")
    A("  endtask")
    A("")
    A("  initial begin")
    A("    void'($value$plusargs(\"ncycles=%d\", NVEC));   // ut_common 统一下发 +ncycles")
    A("    void'($value$plusargs(\"poolpct=%d\", POOLPCT)); // 诊断用：0 = 退回补强前的纯均匀随机")
    A("    reset = 1;")
    A("    dir_clear();")
    A("    repeat (3) @(posedge clock); #1; reset = 0;")
    A("    @(posedge clock);")
    A("    directed_mbmc_sfence();")
    A("    dir_warm_ports();")
    A("    errors += directed_errors;")
    A("    for (int t = 0; t < NVEC; t++) begin")
    A("      // 一半拍走池化激励（制造命中与替换），一半拍走原均匀随机（保住原有覆盖）")
    A("      // +poolpct=0 可复现补强之前的纯均匀随机激励（用来量它的命中率是 0）")
    A("      if (32'($urandom_range(0,99)) < POOLPCT) drive_pooled(); else drive_random();")
    A("      if (io_sfence_valid) cov_sfence++;")
    A("      @(posedge clock); #1;")
    A("      do_check(t);")
    A("    end")
    A('    $display("checks=%0d errors=%0d (含 directed=%0d)", checks, errors, directed_errors);')
    A("    // ---- 覆盖闸：任一路径没走到就判 FAILED（防止激励退化成 miss-only 还报绿）----")
    A('    $display("COVERAGE pool=%%0d refill_pool=%%0d sfence=%%0d hit_multi=%%0d%s",'
      % "".join(" hit_%d=%%0d" % k for k in range(nread)))
    A("             cov_pool, cov_refill_pool, cov_sfence, cov_hit_multi%s);" % "".join(
        ", cov_hit_%d" % k for k in range(nread)))
    A("    cov_ok = (cov_refill_pool >= 200) && (cov_sfence >= 100) && (cov_hit_multi >= 100)")
    for k in range(nread):
        A("            && (cov_hit_%d >= 1000)" % k)
    A("            ;")
    A('    if (!cov_ok) $display("COVERAGE GATE FAILED: 某条路径的拍数低于下限，本轮 UT 不算数");')
    A('    if (errors == 0 && checks > 1000 && cov_ok) $display("TEST PASSED");')
    A('    else $display("TEST FAILED");')
    A("    $finish;")
    A("  end")
    A("endmodule")


    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--check", action="store_true")
    a = ap.parse_args()
    here = os.path.dirname(os.path.abspath(__file__))
    tops = VARIANTS if (a.all or a.check) else [a.top]
    if not tops or tops == [None]:
        ap.error("要 --top <名> 或 --all 或 --check")
    rc = 0
    for TOP in tops:
        text = build(TOP)
        dst = os.path.join(here, "tb_%s.sv" % TOP.split("_")[-1])
        if a.check:
            cur = open(dst).read() if os.path.exists(dst) else None
            if cur != text:
                print("DRIFT: %s 与生成器不一致" % dst); rc = 1
            else:
                print("OK: %s" % dst)
        else:
            open(dst, "w").write(text)
            print("wrote %s" % dst)
    return rc


if __name__ == "__main__":
    sys.exit(main())
