#!/usr/bin/env python3
"""verif/ut/SplittedSRAM/gen.py —— 生成 SplittedSRAM 家族 UT 的 tb.sv。

端口太多（SplittedSRAM_2 一个模块 1015 个端口），手抄必错，所以 tb 的例化端口表
与「整条 entry ↔ 扁平字段端口」的摊开全部由本脚本从 G1 golden 机械生成。

tb 的判据是 golden 与 _xs 逐拍全输出比对（不写参考模型），所以激励只负责**覆盖**：
  A 走 1：对每一路、entry 的每一个输入位，单独置 1 写入再读回 —— 任何字段错位、
    way/data 切分错位、位序颠倒都会当场暴露（纯随机很难把 456 位逐位分开）。
  B 同拍读写同址、同拍读写异址。
  C waymask 全组合（含跨 waySplit 组边界的 4'b0110 这种）。
  D set 边界（0 与最大）+ 每块 SRAM 各自的 ram_hold（只挡住其中一块的写）。
  E MBIST bore：每块一套、逐块给不同的地址/数据，路由接错立刻读出不同。
  F 其余拍数随机。
"""
import argparse
import difflib
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent.parent
GOLDEN = Path("/home/eda/xs-env/G1-canonical/golden-rtl")

NUM, ASID_W, VMID_W, PBMT_W, PPN_W, PERM_W = 8, 16, 14, 2, 38, 7
PERM_FIELDS = ["d", "a", "g", "u", "x", "w", "r"]   # 高位在前

VARIANTS = [
    dict(name="SplittedSRAM_1", pfx="v1", tag_w=24, has_perm=False, rsvd_w=2,
         set_w=2, sets=4, way=2, way_split=1, data_split=1),
    dict(name="SplittedSRAM_2", pfx="v2", tag_w=29, has_perm=True, rsvd_w=4,
         set_w=6, sets=64, way=4, way_split=2, data_split=8),
]


def port_widths(name):
    t = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\(\n(.*?)\n\);", t, re.S | re.M)
    w = {}
    for pm in re.finditer(r"^\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", m.group(1), re.M):
        w[pm.group(3)] = (pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1)
    return w


def offsets(v):
    perms_w = NUM * PERM_W if v["has_perm"] else 0
    o = {}
    p = 0
    o["rsvd"] = p; p += v["rsvd_w"]
    o["prefetch"] = p; p += 1
    o["perms"] = p; p += perms_w
    o["onlypf"] = p; p += NUM
    o["vs"] = p; p += NUM
    o["ppns"] = p; p += NUM * PPN_W
    o["pbmts"] = p; p += NUM * PBMT_W
    o["vmid"] = p; p += VMID_W
    o["asid"] = p; p += ASID_W
    o["tag"] = p; p += v["tag_w"]
    o["ENTRY_W"] = p
    return o


def build_variant(v, L):
    a = L.append
    n, P = v["name"], v["pfx"]
    W, WS, DS = v["way"], v["way_split"], v["data_split"]
    NARR = WS * DS
    o = offsets(v)
    EW = o["ENTRY_W"]
    pw = port_widths(n)

    a(f"  // ==================== {n}（{v['sets']} set × {W} way × {EW} bit，"
      f"waySplit={WS} dataSplit={DS} ⇒ {NARR} 块）====================")
    a(f"  localparam int {P.upper()}_WAY = {W}, {P.upper()}_NARR = {NARR}, "
      f"{P.upper()}_EW = {EW}, {P.upper()}_SETS = {v['sets']};")
    a(f"  logic [{P.upper()}_EW-1:0] {P}_ent [{P.upper()}_WAY];   // 激励：整条 entry，摊成下面的字段")
    a(f"  logic        {P}_rvalid, {P}_wvalid;")
    a(f"  logic [{v['set_w']-1}:0]  {P}_rset, {P}_wset;")
    a(f"  logic [{W-1}:0]  {P}_waymask;")
    # 字段激励（由 ent 摊开）
    a(f"  wire [{W-1}:0][{v['tag_w']-1}:0]  {P}_wtag;")
    a(f"  wire [{W-1}:0][{ASID_W-1}:0] {P}_wasid;")
    a(f"  wire [{W-1}:0][{VMID_W-1}:0] {P}_wvmid;")
    a(f"  wire [{W-1}:0][{NUM-1}:0][{PBMT_W-1}:0] {P}_wpbmt;")
    a(f"  wire [{W-1}:0][{NUM-1}:0][{PPN_W-1}:0]  {P}_wppn;")
    a(f"  wire [{W-1}:0][{NUM-1}:0] {P}_wvs;")
    a(f"  wire [{W-1}:0][{NUM-1}:0] {P}_wonlypf;")
    a(f"  wire [{W-1}:0][{NUM-1}:0][{PERM_W-1}:0] {P}_wperm;  // 位序 {{d,a,g,u,x,w,r}}")
    a(f"  wire [{W-1}:0] {P}_wpref;")
    a("  generate")
    a(f"    for (genvar w = 0; w < {W}; w++) begin : g_{P}_fields")
    a(f"      assign {P}_wtag [w] = {P}_ent[w][{o['tag']} +: {v['tag_w']}];")
    a(f"      assign {P}_wasid[w] = {P}_ent[w][{o['asid']} +: {ASID_W}];")
    a(f"      assign {P}_wvmid[w] = {P}_ent[w][{o['vmid']} +: {VMID_W}];")
    a(f"      assign {P}_wpref[w] = {P}_ent[w][{o['prefetch']}];")
    a(f"      for (genvar e = 0; e < {NUM}; e++) begin : g_{P}_vec")
    a(f"        assign {P}_wpbmt[w][e] = {P}_ent[w][{o['pbmts']} + e*{PBMT_W} +: {PBMT_W}];")
    a(f"        assign {P}_wppn [w][e] = {P}_ent[w][{o['ppns']} + e*{PPN_W} +: {PPN_W}];")
    a(f"        assign {P}_wvs  [w][e] = {P}_ent[w][{o['vs']} + e];")
    a(f"        assign {P}_wonlypf[w][e] = {P}_ent[w][{o['onlypf']} + e];")
    if v["has_perm"]:
        a(f"        assign {P}_wperm[w][e] = {P}_ent[w][{o['perms']} + e*{PERM_W} +: {PERM_W}];")
    else:
        a(f"        assign {P}_wperm[w][e] = '0;  // l1 无 perms 字段")
    a("      end")
    a("    end")
    a("  endgenerate")
    a("")
    # bore / sigFromSrams 激励（每块一套）
    aw = pw["boreChildrenBd_bore_addr"][1]
    dw = pw["boreChildrenBd_bore_wdata"][1]
    mw = pw["boreChildrenBd_bore_wmask"][1]
    sw = pw["boreChildrenBd_bore_selectedOH"][1]
    arw = max(pw[f"boreChildrenBd_bore{'' if i==0 else '_'+str(i)}_array"][1] for i in range(NARR))
    a(f"  // 每块 SRAM 一套 MBIST bore（**分份不是共用**）：逐块给不同值，路由接错即读出不同")
    a(f"  logic [{aw-1}:0] {P}_baddr [{NARR}], {P}_baddr_rd [{NARR}];")
    a(f"  logic [{dw-1}:0] {P}_bwdata [{NARR}];")
    a(f"  logic [{mw-1}:0] {P}_bwmask [{NARR}];")
    a(f"  logic [{sw-1}:0] {P}_bsel [{NARR}];")
    a(f"  logic [{arw-1}:0] {P}_barray [{NARR}];")
    a(f"  logic {P}_bre [{NARR}], {P}_bwe [{NARR}], {P}_back [{NARR}], {P}_hold [{NARR}];")
    a(f"  wire [{dw-1}:0] {P}_g_brdata [{NARR}], {P}_i_brdata [{NARR}];")
    a("")
    # 输出收集
    def odecl(side):
        a(f"  wire [{W-1}:0][{v['tag_w']-1}:0]  {P}_{side}_tag;")
        a(f"  wire [{W-1}:0][{ASID_W-1}:0] {P}_{side}_asid;")
        a(f"  wire [{W-1}:0][{VMID_W-1}:0] {P}_{side}_vmid;")
        a(f"  wire [{W-1}:0][{NUM-1}:0][{PBMT_W-1}:0] {P}_{side}_pbmt;")
        a(f"  wire [{W-1}:0][{NUM-1}:0][{PPN_W-1}:0]  {P}_{side}_ppn;")
        a(f"  wire [{W-1}:0][{NUM-1}:0] {P}_{side}_vs;")
        if any(k.endswith("_entries_onlypf_0") for k in pw):
            a(f"  wire [{W-1}:0][{NUM-1}:0] {P}_{side}_onlypf;")
        if v["has_perm"]:
            a(f"  wire [{W-1}:0][{NUM-1}:0][{PERM_W-1}:0] {P}_{side}_perm;")
        a(f"  wire [{W-1}:0] {P}_{side}_pref;")
    odecl("g"); odecl("i")
    a("")

    def inst(mod, side):
        a(f"  {mod} u_{P}_{side} (")
        ln = []
        ln.append((".clock", "clk"))
        ln.append((".reset", "rst"))
        ln.append((".io_r_req_valid", f"{P}_rvalid"))
        ln.append((".io_r_req_bits_setIdx", f"{P}_rset"))
        for w in range(W):
            pre = f"io_r_resp_data_{w}_entries_"
            ln.append((f".{pre}tag", f"{P}_{side}_tag[{w}]"))
            ln.append((f".{pre}asid", f"{P}_{side}_asid[{w}]"))
            ln.append((f".{pre}vmid", f"{P}_{side}_vmid[{w}]"))
            for e in range(NUM):
                ln.append((f".{pre}pbmts_{e}", f"{P}_{side}_pbmt[{w}][{e}]"))
            for e in range(NUM):
                ln.append((f".{pre}ppns_{e}", f"{P}_{side}_ppn[{w}][{e}]"))
            for e in range(NUM):
                ln.append((f".{pre}vs_{e}", f"{P}_{side}_vs[{w}][{e}]"))
            for e in range(NUM):
                if pre + f"onlypf_{e}" in pw:
                    ln.append((f".{pre}onlypf_{e}", f"{P}_{side}_onlypf[{w}][{e}]"))
            for e in range(NUM):
                for j, f in enumerate(PERM_FIELDS):
                    if pre + f"perms_{e}_{f}" in pw:
                        ln.append((f".{pre}perms_{e}_{f}",
                                   f"{P}_{side}_perm[{w}][{e}][{PERM_W-1-j}]"))
            ln.append((f".{pre}prefetch", f"{P}_{side}_pref[{w}]"))
        ln.append((".io_w_req_valid", f"{P}_wvalid"))
        ln.append((".io_w_req_bits_setIdx", f"{P}_wset"))
        for w in range(W):
            pre = f"io_w_req_bits_data_{w}_entries_"
            ln.append((f".{pre}tag", f"{P}_wtag[{w}]"))
            ln.append((f".{pre}asid", f"{P}_wasid[{w}]"))
            ln.append((f".{pre}vmid", f"{P}_wvmid[{w}]"))
            for e in range(NUM):
                ln.append((f".{pre}pbmts_{e}", f"{P}_wpbmt[{w}][{e}]"))
            for e in range(NUM):
                ln.append((f".{pre}ppns_{e}", f"{P}_wppn[{w}][{e}]"))
            for e in range(NUM):
                ln.append((f".{pre}vs_{e}", f"{P}_wvs[{w}][{e}]"))
            for e in range(NUM):
                if pre + f"onlypf_{e}" in pw:
                    ln.append((f".{pre}onlypf_{e}", f"{P}_wonlypf[{w}][{e}]"))
            for e in range(NUM):
                for j, f in enumerate(PERM_FIELDS):
                    if pre + f"perms_{e}_{f}" in pw:
                        ln.append((f".{pre}perms_{e}_{f}", f"{P}_wperm[{w}][{e}][{PERM_W-1-j}]"))
            ln.append((f".{pre}prefetch", f"{P}_wpref[{w}]"))
        ln.append((".io_w_req_bits_waymask", f"{P}_waymask"))
        for i in range(NARR):
            b = "boreChildrenBd_bore" + ("" if i == 0 else f"_{i}")
            s = "sigFromSrams_bore" + ("" if i == 0 else f"_{i}")
            ln.append((f".{b}_addr", f"{P}_baddr[{i}]"))
            ln.append((f".{b}_addr_rd", f"{P}_baddr_rd[{i}]"))
            ln.append((f".{b}_wdata", f"{P}_bwdata[{i}]"))
            ln.append((f".{b}_wmask", f"{P}_bwmask[{i}]"))
            ln.append((f".{b}_re", f"{P}_bre[{i}]"))
            ln.append((f".{b}_we", f"{P}_bwe[{i}]"))
            ln.append((f".{b}_rdata", f"{P}_{side}_brdata[{i}]"))
            ln.append((f".{b}_ack", f"{P}_back[{i}]"))
            ln.append((f".{b}_selectedOH", f"{P}_bsel[{i}]"))
            ln.append((f".{b}_array", f"{P}_barray[{i}][{pw[b+'_array'][1]-1}:0]"))
            ln.append((f".{s}_ram_hold", f"{P}_hold[{i}]"))
            ln.append((f".{s}_ram_bypass", "1'b0"))
            ln.append((f".{s}_ram_bp_clken", "1'b0"))
            ln.append((f".{s}_ram_aux_clk", "1'b0"))
            ln.append((f".{s}_ram_aux_ckbp", "1'b0"))
            ln.append((f".{s}_ram_mcp_hold", "1'b0"))
            ln.append((f".{s}_cgen", "1'b0"))
        wpad = max(len(p) for p, _ in ln)
        for i, (p, s) in enumerate(ln):
            a(f"    {p.ljust(wpad)} ({s}){'' if i == len(ln)-1 else ','}")
        a("  );")

    inst(n, "g")
    inst(n + "_xs", "i")
    a("")
    # 比对
    a(f"  task automatic chk_{P}();")
    a(f"    if ({P}_g_tag !== {P}_i_tag) begin")
    a(f"      rep(\"{n}.tag\");")
    a(f"      if (errors <= 10) $display(\"        g_tag=%h i_tag=%h rvalid=%b rset=%h\", {P}_g_tag, {P}_i_tag, {P}_rvalid, {P}_rset);")
    a(f"    end")
    a(f"    if ({P}_g_asid !== {P}_i_asid) rep(\"{n}.asid\");")
    a(f"    if ({P}_g_vmid !== {P}_i_vmid) rep(\"{n}.vmid\");")
    a(f"    if ({P}_g_pbmt !== {P}_i_pbmt) rep(\"{n}.pbmts\");")
    a(f"    if ({P}_g_ppn !== {P}_i_ppn) rep(\"{n}.ppns\");")
    a(f"    if ({P}_g_vs !== {P}_i_vs) rep(\"{n}.vs\");")
    if any(k.endswith("_entries_onlypf_0") for k in pw):
        a(f"    if ({P}_g_onlypf !== {P}_i_onlypf) rep(\"{n}.onlypf\");")
    if v["has_perm"]:
        a(f"    if ({P}_g_perm !== {P}_i_perm) rep(\"{n}.perms\");")
    a(f"    if ({P}_g_pref !== {P}_i_pref) rep(\"{n}.prefetch\");")
    a(f"    for (int i = 0; i < {NARR}; i++)")
    a(f"      if ({P}_g_brdata[i] !== {P}_i_brdata[i]) rep($sformatf(\"{n}.bore_rdata[%0d]\", i));")
    a("    checks++;")
    a("  endtask")
    a("")
    # 激励任务
    a(f"  function automatic logic [{P.upper()}_EW-1:0] rnd_ent_{P}();")
    a(f"    logic [{P.upper()}_EW-1:0] e;")
    a(f"    for (int b = 0; b < {P.upper()}_EW; b++) e[b] = $urandom_range(0,1);")
    a("    return e;")
    a("  endfunction")
    a("")
    a(f"  function automatic logic [{dw-1}:0] rnd_bits_{P}();")
    a(f"    logic [{dw-1}:0] e;")
    a(f"    for (int b = 0; b < {dw}; b++) e[b] = $urandom_range(0,1);")
    a("    return e;")
    a("  endfunction")
    a("")
    a(f"  // 随机一拍激励（含 bore 与 per-block ram_hold）")
    a(f"  task automatic rnd_{P}();")
    a(f"    {P}_rvalid <= ($urandom_range(0,3) != 0);")
    a(f"    {P}_wvalid <= ($urandom_range(0,2) == 0);")
    a(f"    {P}_rset   <= {v['set_w']}'($urandom);")
    a(f"    {P}_wset   <= {v['set_w']}'($urandom);")
    a(f"    {P}_waymask<= {W}'($urandom);")
    a(f"    for (int w = 0; w < {W}; w++) {P}_ent[w] <= rnd_ent_{P}();")
    a(f"    for (int i = 0; i < {NARR}; i++) begin")
    a(f"      {P}_baddr[i]    <= {aw}'($urandom ^ i);")
    a(f"      {P}_baddr_rd[i] <= {aw}'($urandom ^ (i*3));")
    a(f"      {P}_bwdata[i]   <= rnd_bits_{P}() ^ {dw}'(i);")
    a(f"      {P}_bwmask[i]   <= {mw}'($urandom);")
    a(f"      {P}_bsel[i]     <= {sw}'($urandom);")
    a(f"      {P}_barray[i]   <= {arw}'($urandom);")
    a(f"      {P}_bre[i]  <= $urandom; {P}_bwe[i] <= $urandom;")
    a(f"      {P}_back[i] <= ($urandom_range(0,7) == 0);")
    a(f"      {P}_hold[i] <= ($urandom_range(0,15) == 0);")
    a("    end")
    a("  endtask")
    a("")
    a(f"  task automatic idle_{P}();")
    a(f"    {P}_rvalid <= 0; {P}_wvalid <= 0;")
    a(f"    for (int i = 0; i < {NARR}; i++) begin")
    a(f"      {P}_bre[i] <= 0; {P}_bwe[i] <= 0; {P}_back[i] <= 0; {P}_hold[i] <= 0;")
    a(f"      {P}_baddr[i] <= '0; {P}_baddr_rd[i] <= '0; {P}_bwdata[i] <= '0;")
    a(f"      {P}_bwmask[i] <= '0; {P}_bsel[i] <= '0; {P}_barray[i] <= '0;")
    a("    end")
    a("  endtask")
    a("")
    # 定向序列
    a(f"  // ---- 覆盖率记账（对这种纯接线模块，line/branch 天然 100%，没有判别力；")
    a(f"  // 真正要证明的是「每一路的每一个 entry 输入位都被驱动过 1 并被读回观察过」、")
    a(f"  // 「waymask 全组合都出现过」、「每块 SRAM 的 hold/bore 都被单独激励过」。----")
    a(f"  bit [{P.upper()}_EW-1:0] cov_bit_{P} [{W}];     // 每路每位曾被写 1")
    a(f"  bit [(1<<{W})-1:0]       cov_wmask_{P};        // waymask 取值")
    a(f"  bit [{v['sets']}-1:0]    cov_wset_{P}, cov_rset_{P};  // 写/读到过的 set")
    a(f"  bit [{NARR}-1:0]         cov_hold_{P}, cov_back_{P};  // 逐块 hold / bore ack")
    a(f"  int cov_rw_same_{P}, cov_rw_diff_{P};          // 同拍读写同址 / 异址")
    a(f"  always @(posedge clk) if (!rst) begin")
    a(f"    if ({P}_wvalid) begin")
    a(f"      cov_wmask_{P}[{P}_waymask] <= 1;")
    a(f"      cov_wset_{P}[{P}_wset] <= 1;")
    a(f"      for (int w = 0; w < {W}; w++)")
    a(f"        if ({P}_waymask[w]) cov_bit_{P}[w] <= cov_bit_{P}[w] | {P}_ent[w];")
    a("    end")
    a(f"    if ({P}_rvalid) cov_rset_{P}[{P}_rset] <= 1;")
    a(f"    if ({P}_rvalid && {P}_wvalid)")
    a(f"      if ({P}_rset == {P}_wset) cov_rw_same_{P} <= cov_rw_same_{P} + 1;")
    a(f"      else cov_rw_diff_{P} <= cov_rw_diff_{P} + 1;")
    a(f"    for (int i = 0; i < {NARR}; i++) begin")
    a(f"      if ({P}_hold[i]) cov_hold_{P}[i] <= 1;")
    a(f"      if ({P}_back[i]) cov_back_{P}[i] <= 1;")
    a("    end")
    a("  end")
    a("")
    a(f"  task automatic cov_report_{P}();")
    a(f"    int nb = 0;")
    a(f"    for (int w = 0; w < {W}; w++) nb += $countones(cov_bit_{P}[w]);")
    a(f"    $display(\"[COV] {n}: entry 输入位写 1 覆盖 %0d/%0d（%0d 路 × %0d 位）\",")
    a(f"             nb, {W}*{P.upper()}_EW, {W}, {P.upper()}_EW);")
    a(f"    $display(\"[COV] {n}: waymask 取值 %0d/%0d  写 set %0d/{v['sets']}  读 set %0d/{v['sets']}\",")
    a(f"             $countones(cov_wmask_{P}), 1<<{W}, $countones(cov_wset_{P}), $countones(cov_rset_{P}));")
    a(f"    $display(\"[COV] {n}: 逐块 ram_hold %0d/{NARR}  逐块 bore ack %0d/{NARR}  同拍读写同址 %0d 次 异址 %0d 次\",")
    a(f"             $countones(cov_hold_{P}), $countones(cov_back_{P}), cov_rw_same_{P}, cov_rw_diff_{P});")
    a("  endtask")
    a("")
    a(f"  // 存储基线：把全部 {v['sets']} 个 set × {W} 路写一遍，再整体读一遍。")
    a(f"  // ★为什么必须有这一步★：内层 SRAMTemplate 的 rdataReg 与厂商宏里的存储阵列都**不复位**")
    a(f"  //   （golden SRAMTemplate_129 只有 respReg 带异步复位）。golden 与 _xs 是两个独立实例，")
    a(f"  //   `+vcs+initreg+random` 给它们灌的是**互不相同**的随机上电值，于是「从没写过的地址」")
    a(f"  //   两侧读出来本来就不同 —— 那不是 RTL 的差异，任何正确的实现都消不掉。实测：不做这一步时")
    a(f"  //   seed 7/42 从 cycle 17 一直错到 cycle 4123（正好是走 1 把最后一路写到为止），而")
    a(f"  //   `+vcs+initreg+0` 全绿。写完之后再比，才是在比逻辑。")
    a(f"  task automatic initmem_{P}();")
    a(f"    idle_{P}();")
    a(f"    @(negedge clk);")
    a(f"    for (int s = 0; s < {v['sets']}; s++) begin")
    a(f"      for (int x = 0; x < {W}; x++) {P}_ent[x] <= rnd_ent_{P}();")
    a(f"      {P}_wvalid <= 1; {P}_wset <= {v['set_w']}'(s); {P}_waymask <= '1; {P}_rvalid <= 0;")
    a(f"      @(negedge clk);")
    a("    end")
    a(f"    {P}_wvalid <= 0;")
    a(f"    for (int s = 0; s < {v['sets']}; s++) begin")
    a(f"      {P}_rvalid <= 1; {P}_rset <= {v['set_w']}'(s);")
    a(f"      @(negedge clk);")
    a("    end")
    a(f"    // 同样把 MBIST 侧的 rdataReg 读一遍（bore_rdata 就是这个寄存器）")
    a(f"    for (int i = 0; i < {NARR}; i++) begin")
    a(f"      {P}_back[i] <= 1; {P}_bre[i] <= 1; {P}_bwe[i] <= 0; {P}_baddr_rd[i] <= '0;")
    a("    end")
    a(f"    @(negedge clk);")
    a(f"    @(negedge clk);")
    a(f"    idle_{P}();")
    a(f"    @(negedge clk);")
    a("  endtask")
    a("")
    a(f"  // 定向激励：走 1 / 同拍读写 / waymask 全组合 / set 边界 / 单块 hold")
    a(f"  task automatic directed_{P}();")
    a(f"    int s;")
    a(f"    idle_{P}();")
    a(f"    @(negedge clk);")
    a(f"    // A 走 1：每路、每个 entry 输入位单独置 1，写进去再读回")
    a(f"    for (int w = 0; w < {W}; w++)")
    a(f"      for (int b = 0; b < {P.upper()}_EW; b++) begin")
    a(f"        s = (b + w) % {v['sets']};")
    a(f"        for (int x = 0; x < {W}; x++) {P}_ent[x] <= '0;")
    a(f"        {P}_ent[w] <= ({P.upper()}_EW'(1) << b);")
    a(f"        {P}_wvalid <= 1; {P}_wset <= {v['set_w']}'(s); {P}_waymask <= {W}'(1) << w;")
    a(f"        {P}_rvalid <= 0;")
    a(f"        @(negedge clk);")
    a(f"        {P}_wvalid <= 0; {P}_rvalid <= 1; {P}_rset <= {v['set_w']}'(s);")
    a(f"        @(negedge clk);")
    a(f"        @(negedge clk);")
    a("      end")
    a(f"    // B waymask 全组合 × set 边界；同时开读写同址")
    a(f"    for (int m = 0; m < (1 << {W}); m++)")
    a(f"      foreach_set_{P}(m);")
    a(f"    // C 逐块 ram_hold：只挡住其中一块的写，制造 slice 之间不一致")
    a(f"    for (int i = 0; i < {NARR}; i++) begin")
    a(f"      for (int x = 0; x < {W}; x++) {P}_ent[x] <= rnd_ent_{P}();")
    a(f"      for (int j = 0; j < {NARR}; j++) {P}_hold[j] <= (j == i);")
    a(f"      {P}_wvalid <= 1; {P}_waymask <= '1; {P}_wset <= {v['set_w']}'(i % {v['sets']});")
    a(f"      {P}_rvalid <= 1; {P}_rset <= {v['set_w']}'(i % {v['sets']});")
    a(f"      @(negedge clk);")
    a(f"      @(negedge clk);")
    a("    end")
    a(f"    for (int j = 0; j < {NARR}; j++) {P}_hold[j] <= 0;")
    a(f"    // D 逐块 MBIST bore：一次只 ack 一块，地址/数据带块号，路由错即读出不同")
    a(f"    for (int i = 0; i < {NARR}; i++) begin")
    a(f"      for (int j = 0; j < {NARR}; j++) begin")
    a(f"        {P}_back[j] <= (j == i); {P}_bwe[j] <= (j == i); {P}_bre[j] <= (j == i);")
    a(f"        {P}_baddr[j] <= {aw}'(j + 1); {P}_baddr_rd[j] <= {aw}'(j + 1);")
    a(f"        {P}_bwdata[j] <= {dw}'(j + 1);")
    a(f"        {P}_bwmask[j] <= '1; {P}_bsel[j] <= '1;")
    a("      end")
    a(f"      @(negedge clk);")
    a(f"      @(negedge clk);")
    a("    end")
    a(f"    idle_{P}();")
    a(f"    @(negedge clk);")
    a("  endtask")
    a("")
    a(f"  task automatic foreach_set_{P}(int m);")
    a(f"    int sets[$] = '{{0, 1, {v['sets']}/2, {v['sets']}-1}};")
    a(f"    foreach (sets[k]) begin")
    a(f"      for (int x = 0; x < {W}; x++) {P}_ent[x] <= rnd_ent_{P}();")
    a(f"      {P}_waymask <= {W}'(m);")
    a(f"      {P}_wvalid <= 1; {P}_wset <= {v['set_w']}'(sets[k]);")
    a(f"      {P}_rvalid <= 1; {P}_rset <= {v['set_w']}'(sets[k]);   // 同拍读写同址")
    a(f"      @(negedge clk);")
    a(f"      {P}_rset <= {v['set_w']}'(({v['sets']}-1) - sets[k]);  // 同拍读写异址")
    a(f"      @(negedge clk);")
    a("    end")
    a("  endtask")
    a("")


def build():
    L = []
    a = L.append
    a("// SplittedSRAM 家族 UT —— golden 与 _xs 双例化逐拍全输出比对。")
    a("// 覆盖 SplittedSRAM_1（PtwCache l1，4set×2way×393bit，1 块）与")
    a("// SplittedSRAM_2（PtwCache l0，64set×4way×456bit，waySplit2×dataSplit8=16 块）。")
    a("// 两侧都例化各自的内层 SRAMTemplate 与同一份厂商 SRAM 宏，故本 UT 测的是")
    a("// Splitted 这一层：entry 打包、way/data 切分、读回拼接、以及每块各自的")
    a("// MBIST bore / sigFromSrams 路由（16 块 16 套，接错一根就是静默真 bug）。")
    a("// 激励含定向段（逐位走 1、同拍读写同址、waymask 全组合、逐块 hold/bore）")
    a("// 与随机段；判据是 errors==0。")
    a("// 自动生成：verif/ut/SplittedSRAM/gen.py —— 勿手改。")
    a("`timescale 1ns/1ps")
    a("module tb;")
    a("  int unsigned NCYCLES = 200000;")
    a("  int unsigned WARMUP  = 8;")
    a("  bit clk = 0;")
    a("  logic rst = 1;")
    a("  int errors = 0, checks = 0;")
    a("  int unsigned cycle = 0;")
    a("  bit checking = 0;")
    a("  always #5 clk = ~clk;")
    a("  always @(posedge clk) cycle++;")
    a("")
    a("  int last_err_cycle = -1;")
    a("  task automatic rep(string what);")
    a("    errors++;")
    a("    last_err_cycle = cycle;")
    a("    if (errors <= 60) $display(\"[%0t] cycle=%0d MISMATCH %s\", $time, cycle, what);")
    a("  endtask")
    a("")
    for v in VARIANTS:
        build_variant(v, L)
    a("  // 逐拍比对（在时钟沿后稳定点采样）")
    a("  always @(posedge clk) if (checking) begin")
    a("    #1;")
    for v in VARIANTS:
        a(f"    chk_{v['pfx']}();")
    a("  end")
    a("")
    a("  initial begin")
    a("    if ($value$plusargs(\"ncycles=%d\", NCYCLES)) ;")
    for v in VARIANTS:
        a(f"    idle_{v['pfx']}();")
    a("    rst = 1;")
    a("    repeat (8) @(negedge clk);")
    a("    rst = 0;")
    a("    repeat (WARMUP) @(negedge clk);")
    a("    // 先把两侧存储灌成同一份确定内容，再开始比对（理由见 initmem_* 的注释）")
    a("    fork")
    a("      initmem_v1();")
    a("      initmem_v2();")
    a("    join")
    a("    checking = 1;")
    a("    fork")
    for v in VARIANTS:
        a(f"      directed_{v['pfx']}();")
    a("    join")
    a("    while (cycle < NCYCLES) begin")
    for v in VARIANTS:
        a(f"      rnd_{v['pfx']}();")
    a("      @(negedge clk);")
    a("    end")
    for v in VARIANTS:
        a(f"    cov_report_{v['pfx']}();")
    a("    $display(\"=== SplittedSRAM UT: cycles=%0d checks=%0d errors=%0d last_err_cycle=%0d\", cycle, checks, errors, last_err_cycle);")
    a("    if (errors == 0) $display(\"TEST PASSED\");")
    a("    else $display(\"TEST FAILED\");")
    a("    $finish;")
    a("  end")
    a("endmodule")
    return "\n".join(L) + "\n"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    text = build()
    dst = HERE / "tb.sv"
    old = dst.read_text() if dst.exists() else None
    if args.check:
        if old != text:
            print("DRIFT: tb.sv")
            for ln in list(difflib.unified_diff((old or "").splitlines(), text.splitlines(),
                                                "repo", "gen", lineterm=""))[:40]:
                print("  " + ln)
            return 1
        print("OK: tb.sv")
        return 0
    if old != text:
        dst.write_text(text)
        print(f"written: {dst} ({text.count(chr(10))} 行)")
    else:
        print("unchanged: tb.sv")
    return 0


if __name__ == "__main__":
    sys.exit(main())
