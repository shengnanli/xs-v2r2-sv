#!/usr/bin/env python3
"""
ITTage 顶层：解析 golden ITTage.sv 端口，生成
  - rtl/frontend/ITTage_wrapper.sv  : golden 同名 wrapper `ITTage`
  - verif/ut/ITTage/variants_xs.sv  : 镜像 `ITTage_xs`
  - verif/ut/ITTage/tb.sv           : 随机 req/redirect/update 逐拍比对

wrapper 例化：
  - 5 张 ITTageTable_* + RegionWays + MaxPeriodFibonacciLFSR（golden 黑盒）；
  - 可读核 xs_ITTage_core（实例名 u_core）做表间组合/选择/分配/更新逻辑。
  - s2/s3 full_pred 除 s3 jalr_target（=核输出）外全部旁路透传 io_in→io_out；
    last_stage_ftb_entry / spec_info 也旁路；last_stage_meta = 核输出。
  - 各表 folded_hist req 端口名不同，按表显式连线；其余 io_* 旁路直连。
"""
import re
from pathlib import Path

XSSV = Path(__file__).resolve().parent.parent
GOLDEN = XSSV / "golden/chisel-rtl"

# 每张表的 req folded_hist 连接（端口名 → ITTage 顶层 io_in 输入名），及 N_SRAM 拓扑
# 见 golden ITTage.sv 例化段（tables_0..4）。
TABLE_FH = [
    # (golden module, [(table_port, top_input)], n_sram)
    ("ITTageTable", [
        ("io_req_bits_folded_hist_hist_12_folded_hist", "io_in_bits_s1_folded_hist_3_hist_12_folded_hist"),
    ], 1),
    ("ITTageTable_1", [
        ("io_req_bits_folded_hist_hist_14_folded_hist", "io_in_bits_s1_folded_hist_3_hist_14_folded_hist"),
    ], 1),
    ("ITTageTable_2", [
        ("io_req_bits_folded_hist_hist_13_folded_hist", "io_in_bits_s1_folded_hist_3_hist_13_folded_hist"),
        ("io_req_bits_folded_hist_hist_4_folded_hist",  "io_in_bits_s1_folded_hist_3_hist_4_folded_hist"),
    ], 2),
    ("ITTageTable_3", [
        ("io_req_bits_folded_hist_hist_6_folded_hist", "io_in_bits_s1_folded_hist_3_hist_6_folded_hist"),
        ("io_req_bits_folded_hist_hist_2_folded_hist", "io_in_bits_s1_folded_hist_3_hist_2_folded_hist"),
    ], 2),
    ("ITTageTable_4", [
        ("io_req_bits_folded_hist_hist_10_folded_hist", "io_in_bits_s1_folded_hist_3_hist_10_folded_hist"),
        ("io_req_bits_folded_hist_hist_3_folded_hist",  "io_in_bits_s1_folded_hist_3_hist_3_folded_hist"),
    ], 2),
]

# 每张表 DFT bore 端口的前缀（golden 顶层 boreChildrenBd_bore{_k}/sigFromSrams_bore{_k}）
# tables_0: bore;  tables_1: bore_1;  tables_2: bore_2 + sig bore_2/_3;
# tables_3: bore_3 + sig bore_4/_5;  tables_4: bore_4 + sig bore_6/_7
TABLE_BORE = [
    ("boreChildrenBd_bore",   ["sigFromSrams_bore"]),
    ("boreChildrenBd_bore_1", ["sigFromSrams_bore_1"]),
    ("boreChildrenBd_bore_2", ["sigFromSrams_bore_2", "sigFromSrams_bore_3"]),
    ("boreChildrenBd_bore_3", ["sigFromSrams_bore_4", "sigFromSrams_bore_5"]),
    ("boreChildrenBd_bore_4", ["sigFromSrams_bore_6", "sigFromSrams_bore_7"]),
]

NUM_TBL = 5


def ports(name):
    text = (GOLDEN / f"{name}.sv").read_text()
    m = re.search(rf"^module {re.escape(name)}\((.*?)\n\);", text, re.S | re.M)
    res = []
    for line in m.group(1).splitlines():
        pm = re.match(r"\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$", line)
        if pm:
            res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res


def table_ports(name):
    return {n: (d, w) for d, w, n in ports(name)}


def width_str(w):
    return f"[{w-1}:0] " if w > 1 else ""


def emit_module(modname, ps):
    """生成 wrapper / _xs：端口与 golden 一致；内部例化子模块 + 核 + 旁路。"""
    L = []
    # ---- 端口声明 ----
    decls = []
    for d, w, n in ps:
        decls.append(f"  {d:6s} {width_str(w)}{n}")
    L.append(f"module {modname}(")
    L.append(",\n".join(decls))
    L.append(");")
    L.append("")

    pd = {n: (d, w) for d, w, n in ps}

    # ---- 子模块 resp/ready 等内部线 ----
    L.append("  // ---- 5 张表 resp / ready 内部线 ----")
    for t in range(NUM_TBL):
        L.append(f"  wire        t{t}_req_ready;")
        L.append(f"  wire        t{t}_resp_valid;")
        L.append(f"  wire [1:0]  t{t}_resp_ctr;")
        L.append(f"  wire        t{t}_resp_u;")
        L.append(f"  wire [19:0] t{t}_resp_off;")
        L.append(f"  wire [3:0]  t{t}_resp_ptr;")
        L.append(f"  wire        t{t}_resp_usePCRegion;")
    L.append("  // ---- 核驱动的各表 update 端口 ----")
    for t in range(NUM_TBL):
        L.append(f"  wire        t{t}_upd_valid, t{t}_upd_correct, t{t}_upd_alloc;")
        L.append(f"  wire [1:0]  t{t}_upd_oldCtr;")
        L.append(f"  wire        t{t}_upd_uValid, t{t}_upd_u, t{t}_upd_reset_u;")
        L.append(f"  wire [49:0] t{t}_upd_pc;")
        L.append(f"  wire [255:0]t{t}_upd_ghist;")
        L.append(f"  wire [19:0] t{t}_upd_off; wire [3:0] t{t}_upd_ptr; wire t{t}_upd_usePCRegion;")
        L.append(f"  wire [19:0] t{t}_upd_old_off; wire [3:0] t{t}_upd_old_ptr; wire t{t}_upd_old_usePCRegion;")
    L.append("  // ---- RegionWays / LFSR 内部线 ----")
    for t in range(NUM_TBL):
        L.append(f"  wire        rt_resp_hit_{t};")
        L.append(f"  wire [29:0] rt_resp_region_{t};")
    L.append("  wire        rt_update_hit_0, rt_update_hit_1;")
    L.append("  wire [3:0]  rt_update_ptr_0, rt_update_ptr_1, rt_write_ptr;")
    L.append("  wire [29:0] rt_update_region_0, rt_update_region_1, rt_write_region;")
    L.append("  wire        rt_write_valid;")
    for t in range(NUM_TBL):
        L.append(f"  wire        lfsr_out_{t};")
    L.append("  wire        core_s1_ready;")
    L.append("  wire        core_req_valid;")
    L.append("  wire [49:0] core_req_pc;")
    for d in range(4):
        L.append(f"  wire [49:0] core_s3_jalr_target_{d};")
    L.append("")

    # ---- 例化 5 张表 ----
    for t, (mod, fhs, nsram) in enumerate(TABLE_FH):
        tp = table_ports(mod)
        L.append(f"  {mod} tables_{t} (")
        conns = [".clock(clock)", ".reset(reset)"]
        conns.append(f".io_req_ready(t{t}_req_ready)")
        conns.append(".io_req_valid(core_req_valid)")
        conns.append(".io_req_bits_pc(core_req_pc)")
        for port, top in fhs:
            conns.append(f".{port}({top})")
        conns.append(f".io_resp_valid(t{t}_resp_valid)")
        conns.append(f".io_resp_bits_ctr(t{t}_resp_ctr)")
        conns.append(f".io_resp_bits_u(t{t}_resp_u)")
        conns.append(f".io_resp_bits_target_offset_offset(t{t}_resp_off)")
        conns.append(f".io_resp_bits_target_offset_pointer(t{t}_resp_ptr)")
        conns.append(f".io_resp_bits_target_offset_usePCRegion(t{t}_resp_usePCRegion)")
        conns.append(f".io_update_pc(t{t}_upd_pc)")
        conns.append(f".io_update_ghist(t{t}_upd_ghist)")
        conns.append(f".io_update_valid(t{t}_upd_valid)")
        conns.append(f".io_update_correct(t{t}_upd_correct)")
        conns.append(f".io_update_alloc(t{t}_upd_alloc)")
        conns.append(f".io_update_oldCtr(t{t}_upd_oldCtr)")
        conns.append(f".io_update_uValid(t{t}_upd_uValid)")
        conns.append(f".io_update_u(t{t}_upd_u)")
        conns.append(f".io_update_reset_u(t{t}_upd_reset_u)")
        conns.append(f".io_update_target_offset_offset(t{t}_upd_off)")
        conns.append(f".io_update_target_offset_pointer(t{t}_upd_ptr)")
        conns.append(f".io_update_target_offset_usePCRegion(t{t}_upd_usePCRegion)")
        conns.append(f".io_update_old_target_offset_offset(t{t}_upd_old_off)")
        conns.append(f".io_update_old_target_offset_pointer(t{t}_upd_old_ptr)")
        conns.append(f".io_update_old_target_offset_usePCRegion(t{t}_upd_old_usePCRegion)")
        # DFT bore：直连顶层同名端口
        bore_pref, sig_prefs = TABLE_BORE[t]
        for bp in ["array", "all", "req", "ack", "writeen", "be", "addr", "indata",
                   "readen", "addr_rd", "outdata"]:
            conns.append(f".boreChildrenBd_bore_{bp}({bore_pref}_{bp})")
        for si, sp in enumerate(sig_prefs):
            tag = "" if si == 0 else f"_{si}"
            for sg in ["ram_hold", "ram_bypass", "ram_bp_clken", "ram_aux_clk",
                       "ram_aux_ckbp", "ram_mcp_hold", "cgen"]:
                conns.append(f".sigFromSrams_bore{tag}_{sg}({sp}_{sg})")
        L.append("    " + ",\n    ".join(conns))
        L.append("  );")
    L.append("")

    # ---- RegionWays ----
    L.append("  RegionWays rTable (")
    rc = [".clock(clock)", ".reset(reset)"]
    # pointer 由各表直连（与 golden 同构，便于 FM 黑盒引脚配对）
    for t in range(NUM_TBL):
        rc.append(f".io_req_pointer_{t}(t{t}_resp_ptr)")
    for t in range(NUM_TBL):
        rc.append(f".io_resp_hit_{t}(rt_resp_hit_{t})")
    for t in range(NUM_TBL):
        rc.append(f".io_resp_region_{t}(rt_resp_region_{t})")
    rc.append(".io_update_region_0(rt_update_region_0)")
    rc.append(".io_update_region_1(rt_update_region_1)")
    rc.append(".io_update_hit_0(rt_update_hit_0)")
    rc.append(".io_update_hit_1(rt_update_hit_1)")
    rc.append(".io_update_pointer_0(rt_update_ptr_0)")
    rc.append(".io_update_pointer_1(rt_update_ptr_1)")
    rc.append(".io_write_valid(rt_write_valid)")
    rc.append(".io_write_region(rt_write_region)")
    rc.append(".io_write_pointer(rt_write_ptr)")
    L.append("    " + ",\n    ".join(rc))
    L.append("  );")
    L.append("")

    # ---- LFSR ----
    L.append("  MaxPeriodFibonacciLFSR s2_allocLFSR_prng (")
    lc = [".clock(clock)", ".reset(reset)"]
    for t in range(NUM_TBL):
        lc.append(f".io_out_{t}(lfsr_out_{t})")
    for u in range(NUM_TBL, 15):
        lc.append(f".io_out_{u}()")
    L.append("    " + ",\n    ".join(lc))
    L.append("  );")
    L.append("")

    # ---- 核例化 ----
    L.append("  xs_ITTage_core u_core (")
    cc = [".clock(clock)", ".reset(reset)", ".io_reset_vector(io_reset_vector)"]
    # 数组端口用 '{...} 连接（SV 端口数组，元素 [0]..[3]）
    cc.append(".io_in_s0_pc('{io_in_bits_s0_pc_0, io_in_bits_s0_pc_1, io_in_bits_s0_pc_2, io_in_bits_s0_pc_3})")
    cc.append(".io_s0_fire('{io_s0_fire_0, io_s0_fire_1, io_s0_fire_2, io_s0_fire_3})")
    cc.append(".io_s1_fire('{io_s1_fire_0, io_s1_fire_1, io_s1_fire_2, io_s1_fire_3})")
    cc.append(".io_s2_fire('{io_s2_fire_0, io_s2_fire_1, io_s2_fire_2, io_s2_fire_3})")
    cc.append(".io_s1_uftbHit(io_in_bits_resp_in_0_s1_uftbHit)")
    cc.append(".io_s1_uftbHasIndirect(io_in_bits_resp_in_0_s1_uftbHasIndirect)")
    cc.append(".io_s1_ftbCloseReq(io_in_bits_resp_in_0_s1_ftbCloseReq)")
    cc.append(".io_in_s2_jalr_target_3(io_in_bits_resp_in_0_s2_full_pred_3_jalr_target)")
    cc.append(".io_s1_ready(core_s1_ready)")
    cc.append(".io_out_s3_jalr_target('{core_s3_jalr_target_0, core_s3_jalr_target_1, core_s3_jalr_target_2, core_s3_jalr_target_3})")
    cc.append(".io_out_last_stage_meta(io_out_last_stage_meta)")
    # update inputs
    cc.append(".io_update_valid(io_update_valid)")
    cc.append(".io_update_pc(io_update_bits_pc)")
    cc.append(".io_update_ftb_isRet(io_update_bits_ftb_entry_isRet)")
    cc.append(".io_update_ftb_isJalr(io_update_bits_ftb_entry_isJalr)")
    cc.append(".io_update_ftb_tailSlot_offset(io_update_bits_ftb_entry_tailSlot_offset)")
    cc.append(".io_update_ftb_tailSlot_sharing(io_update_bits_ftb_entry_tailSlot_sharing)")
    cc.append(".io_update_ftb_tailSlot_valid(io_update_bits_ftb_entry_tailSlot_valid)")
    cc.append(".io_update_ftb_strong_bias_1(io_update_bits_ftb_entry_strong_bias_1)")
    cc.append(".io_update_cfi_idx_valid(io_update_bits_cfi_idx_valid)")
    cc.append(".io_update_cfi_idx_bits(io_update_bits_cfi_idx_bits)")
    cc.append(".io_update_jmp_taken(io_update_bits_jmp_taken)")
    cc.append(".io_update_mispred_mask_2(io_update_bits_mispred_mask_2)")
    cc.append(".io_update_meta(io_update_bits_meta)")
    cc.append(".io_update_full_target(io_update_bits_full_target)")
    cc.append(".io_update_ghist(io_update_bits_ghist)")
    # 与子模块对接
    cc.append(".tbl_req_valid(core_req_valid)")
    cc.append(".tbl_req_pc(core_req_pc)")
    cc.append(".tbl_req_ready('{" + ", ".join(f"t{t}_req_ready" for t in range(NUM_TBL)) + "})")
    for f, sig in [("tbl_resp_valid", "resp_valid"), ("tbl_resp_ctr", "resp_ctr"),
                   ("tbl_resp_u", "resp_u"), ("tbl_resp_off", "resp_off"),
                   ("tbl_resp_ptr", "resp_ptr"), ("tbl_resp_usePCRegion", "resp_usePCRegion")]:
        cc.append(f".{f}('{{" + ", ".join(f"t{t}_{sig}" for t in range(NUM_TBL)) + "})")
    for f, sig in [("tbl_upd_valid", "upd_valid"), ("tbl_upd_correct", "upd_correct"),
                   ("tbl_upd_alloc", "upd_alloc"), ("tbl_upd_oldCtr", "upd_oldCtr"),
                   ("tbl_upd_uValid", "upd_uValid"), ("tbl_upd_u", "upd_u"),
                   ("tbl_upd_reset_u", "upd_reset_u"), ("tbl_upd_pc", "upd_pc"),
                   ("tbl_upd_ghist", "upd_ghist"), ("tbl_upd_off", "upd_off"),
                   ("tbl_upd_ptr", "upd_ptr"), ("tbl_upd_usePCRegion", "upd_usePCRegion"),
                   ("tbl_upd_old_off", "upd_old_off"), ("tbl_upd_old_ptr", "upd_old_ptr"),
                   ("tbl_upd_old_usePCRegion", "upd_old_usePCRegion")]:
        cc.append(f".{f}('{{" + ", ".join(f"t{t}_{sig}" for t in range(NUM_TBL)) + "})")
    cc.append(".rt_resp_hit('{" + ", ".join(f"rt_resp_hit_{t}" for t in range(NUM_TBL)) + "})")
    cc.append(".rt_resp_region('{" + ", ".join(f"rt_resp_region_{t}" for t in range(NUM_TBL)) + "})")
    cc.append(".rt_update_region_0(rt_update_region_0)")
    cc.append(".rt_update_region_1(rt_update_region_1)")
    cc.append(".rt_update_hit_0(rt_update_hit_0)")
    cc.append(".rt_update_hit_1(rt_update_hit_1)")
    cc.append(".rt_update_pointer_0(rt_update_ptr_0)")
    cc.append(".rt_update_pointer_1(rt_update_ptr_1)")
    cc.append(".rt_write_valid(rt_write_valid)")
    cc.append(".rt_write_region(rt_write_region)")
    cc.append(".rt_write_pointer(rt_write_ptr)")
    cc.append(".lfsr_out('{" + ", ".join(f"lfsr_out_{t}" for t in range(NUM_TBL)) + "})")
    L.append("    " + ",\n    ".join(cc))
    L.append("  );")
    L.append("")

    # ---- 输出连接 ----
    L.append("  assign io_s1_ready = core_s1_ready;")
    for d in range(4):
        L.append(f"  assign io_out_s3_full_pred_{d}_jalr_target = core_s3_jalr_target_{d};")
    L.append("")

    # ---- 旁路透传：所有 io_out_* 中未被核驱动者 = 对应 io_in_*  ----
    # 规则：io_out_s2_full_pred_d_X        <= io_in_bits_resp_in_0_s2_full_pred_d_X
    #       io_out_s3_full_pred_d_X (X!=jalr_target) <= io_in_..._s3_full_pred_d_X
    #       io_out_last_stage_spec_info_X  <= io_in_..._last_stage_spec_info_X
    #       io_out_last_stage_ftb_entry_X  <= io_in_..._last_stage_ftb_entry_X
    L.append("  // ---- 旁路透传（ITTAGE 只改 s3 jalr_target / last_stage_meta，其余原样透传）----")
    driven = {f"io_out_s3_full_pred_{d}_jalr_target" for d in range(4)}
    driven |= {"io_s1_ready", "io_out_last_stage_meta"}
    for d, w, n in ps:
        if d != "output" or n in driven:
            continue
        # DFT bore 输出（ack/outdata）由表实例直接驱动顶层同名端口，非旁路
        if n.startswith("boreChildrenBd_bore"):
            continue
        inn = "io_in_bits_resp_in_0_" + n[len("io_out_"):]
        if inn in pd:
            L.append(f"  assign {n} = {inn};")
        else:
            raise RuntimeError(f"no bypass source for output {n}")
    L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(ps):
    ins = [(w, n) for d, w, n in ps if d == "input" and n not in ("clock", "reset")]
    outs = [(w, n) for d, w, n in ps if d == "output"]
    T = ["""// 自动生成：scripts/gen_ittage.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 60000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;
"""]
    for w, n in ins:
        T.append(f"  logic {width_str(w)}{n};")
    for w, n in outs:
        T.append(f"  wire {width_str(w)}g_{n};")
        T.append(f"  wire {width_str(w)}i_{n};")
    gc = [".clock(clk)", ".reset(rst)"] + [f".{n}({n})" for _, n in ins]
    gg = gc + [f".{n}(g_{n})" for _, n in outs]
    ig = gc + [f".{n}(i_{n})" for _, n in outs]
    T.append(f"  ITTage    u_g ({', '.join(gg)});")
    T.append(f"  ITTage_xs u_i ({', '.join(ig)});")

    fire_sigs = [f"io_s{s}_fire_{d}" for s in range(3) for d in range(4)]
    pc_sigs = ["io_in_bits_s0_pc_0", "io_in_bits_s0_pc_1", "io_in_bits_s0_pc_2",
               "io_in_bits_s0_pc_3", "io_update_bits_pc", "io_update_bits_full_target"]

    T.append("  always @(negedge clk) begin")
    T.append("    if (rst) begin")
    T.append("      io_update_valid <= 1'b0;")
    for s in fire_sigs:
        T.append(f"      {s} <= 1'b0;")
    T.append("    end else begin")
    for w, n in ins:
        if n in fire_sigs:
            T.append(f"      {n} <= ($urandom_range(0,1)==0);")
        elif n == "io_update_valid":
            T.append(f"      {n} <= ($urandom_range(0,3)==0);")
        elif n in pc_sigs:
            # 压缩低位提高 region/tag/idx 命中率
            T.append(f"      {n} <= {{{w-13}'($urandom), 12'($urandom_range(0,63)), 1'b0}};")
        elif n == "io_update_bits_meta":
            # meta 低位字段（provider/alt/ctr/target）需在合法值域，给随机但限制 provider/alt bits 在 0..4
            T.append(f"      {n} <= {w}'({{$urandom(),$urandom(),$urandom(),$urandom(),"
                     f"$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),"
                     f"$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom(),$urandom()}});")
        elif w <= 32:
            T.append(f"      {n} <= {w}'($urandom);")
        else:
            rep = (w + 31) // 32
            T.append(f"      {n} <= {w}'({{{', '.join(['$urandom()']*rep)}}});")
    T.append("    end")
    T.append("  end")

    T.append("  always @(negedge clk) if (!rst) begin")
    T.append("    #4; checks++;")
    for w, n in outs:
        T.append(f"    if (!$isunknown(g_{n}) && g_{n} !== i_{n}) begin errors++;")
        T.append(f"      if(errors<=40) $display(\"[%0t] {n} g=%h i=%h\", $time, g_{n}, i_{n}); end")
    T.append("  end")
    T.append("""  initial begin
    rst = 1; repeat (12) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
""")
    return "\n".join(T)


def main():
    ps = ports("ITTage")
    hdr = "// 自动生成：scripts/gen_ittage.py —— 勿手改\n"
    (XSSV / "rtl/frontend/ITTage_wrapper.sv").write_text(hdr + emit_module("ITTage", ps))
    ut = XSSV / "verif/ut/ITTage"
    ut.mkdir(parents=True, exist_ok=True)
    (ut / "variants_xs.sv").write_text(hdr + emit_module("ITTage_xs", ps))
    (ut / "tb.sv").write_text(emit_tb(ps))
    ins = [n for d, w, n in ps if d == "input"]
    outs = [n for d, w, n in ps if d == "output"]
    print(f"ITTage: {len(ins)} inputs, {len(outs)} outputs")


if __name__ == "__main__":
    main()
