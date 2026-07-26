#!/usr/bin/env python3
# 生成 fm_pins.tcl —— LoadQueueRAW 合成层次顶层 glue 寄存器 golden↔impl 双射钉名。
# golden firtool 的最老选择流水命名（detectedRollback_lqSelect_select_*）与 impl 可读
# 数组名（s1_*/s2_*）不同，顶层 auto_match_flattened_arrays 名规则够不着；这里按已知
# 逐拍对应关系 set_user_match（双射，值恒等——同源同更新逻辑，非 waiver/非删点/非放宽）。
#
# 映射（store 端口 p=0,1；组 g=0..3；组=entries[8g,8g+8)，与 golden 一致）：
#   s1_valid[p][g]     <-> select_selValidNext_{4p+g}            (idx0 无后缀)
#   s1_<f>[p][g]       <-> select_{g}_2{_1 if p==1}_uop_<gf>     (p0 无 _1)
#   s1_redir_*[p][g]   <-> select_REG_{4p+g}_valid/bits_*        (idx0 无后缀)
#   s2_valid[p]        <-> selValidNext_last_REG{_1 if p==1}
#   s2_<f>[p]          <-> lqSelect_2_0{_1 if p==1}_uop_<gf>
#   s2_redir_*[p]      <-> lqSelect_REG{_1 if p==1}_valid/bits_*
# 位下标寄存器（value）逐位钉；单比特无下标。
TOP = "LoadQueueRAW"
R = f"r:/WORK/{TOP}"
I = f"i:/WORK/{TOP}/u_core"

# golden uop 字段名 -> (impl 数组名, 位宽)
S1_FIELDS = {
    "preDecodeInfo_isRVC": ("s1_isRVC", 1),
    "ftqPtr_flag":         ("s1_ftqf", 1),
    "ftqPtr_value":        ("s1_ftqp", 6),
    "ftqOffset":           ("s1_ftqo", 4),
    "robIdx_flag":         ("s1_flag", 1),
    "robIdx_value":        ("s1_rob",  8),
}
S2_FIELDS = {
    "preDecodeInfo_isRVC": ("s2_isRVC", 1),
    "ftqPtr_flag":         ("s2_ftqf", 1),
    "ftqPtr_value":        ("s2_ftqp", 6),
    "ftqOffset":           ("s2_ftqo", 4),
    "robIdx_flag":         ("s2_flag", 1),
    "robIdx_value":        ("s2_rob",  8),
}

def esc(p):
    # Tcl escape of [ and ]
    return p.replace("[", r"\[").replace("]", r"\]")

# ref(golden): <name>_reg  (scalar) / <name>_reg[bit] (value)
# impl:        <array>_reg<idxs>  (scalar) / <array>_reg<idxs>[bit] (value)
#   iname 传入 "(arrayname, idxs_str)" ，idxs_str 形如 "[0][3]"
def emit(rname, iarr, iidx, w, out):
    if w == 1:
        out.append(f"set_user_match {esc(R+'/'+rname+'_reg')} {esc(I+'/'+iarr+'_reg'+iidx)}")
    else:
        for b in range(w):
            out.append(f"set_user_match {esc(R+'/'+rname+f'_reg[{b}]')} {esc(I+'/'+iarr+'_reg'+iidx+f'[{b}]')}")

# 条目 payload：golden uop_N_<gf> <-> impl entry_<field>_reg[N]
ENTRY_FIELDS = {
    "preDecodeInfo_isRVC": ("entry_isRVC",     1),
    "ftqPtr_flag":         ("entry_ftqFlag",   1),
    "ftqPtr_value":        ("entry_ftqPtr",    6),
    "ftqOffset":           ("entry_ftqOffset", 4),
    "robIdx_flag":         ("entry_robFlag",   1),
    "robIdx_value":        ("entry_robIdx",    8),
    "sqIdx_flag":          ("entry_sqFlag",    1),
    "sqIdx_value":         ("entry_sqIdx",     6),
}

def main():
    out = []
    # entryNeedCheck 打拍寄存器（golden entryNeedCheck_r_{p}_{e} <-> impl entry_need_check[p][e]）
    #   名字差异大（entryNeedCheck_r vs entry_need_check），auto-match 够不着且签名易错配，显式钉。
    for p in range(2):
        psuf = "" if p == 0 else "_1"
        for e in range(32):
            emit(f"detectedRollback_entryNeedCheck_r{psuf}_{e}", "entry_need_check", f"[{p}][{e}]", 1, out)
    # 条目 payload（32 entry × 8 field）
    for n in range(32):
        for gf, (arr, w) in ENTRY_FIELDS.items():
            emit(f"uop_{n}_{gf}", arr, f"[{n}]", w, out)
    for p in range(2):
        psuf = "" if p == 0 else "_1"
        pg = f"[{p}][{{g}}]"
        for g in range(4):
            idx = 4*p + g
            isuf = "" if idx == 0 else f"_{idx}"
            ig = f"[{p}][{g}]"
            # s1_valid
            emit(f"detectedRollback_lqSelect_select_selValidNext{isuf}",
                 "s1_valid", ig, 1, out)
            # s1 data fields
            for gf, (arr, w) in S1_FIELDS.items():
                emit(f"detectedRollback_lqSelect_select_{g}_2{psuf}_uop_{gf}",
                     arr, ig, w, out)
            # s1 redir (select_REG_{idx})
            emit(f"detectedRollback_lqSelect_select_REG{isuf}_valid",       "s1_redir_valid", ig, 1, out)
            emit(f"detectedRollback_lqSelect_select_REG{isuf}_bits_level",  "s1_redir_level", ig, 1, out)
            emit(f"detectedRollback_lqSelect_select_REG{isuf}_bits_robIdx_flag",  "s1_redir_robf", ig, 1, out)
            emit(f"detectedRollback_lqSelect_select_REG{isuf}_bits_robIdx_value", "s1_redir_robv", ig, 8, out)
        # s2_valid
        emit(f"detectedRollback_lqSelect_selValidNext_last_REG{psuf}", "s2_valid", f"[{p}]", 1, out)
        # s2 data fields
        for gf, (arr, w) in S2_FIELDS.items():
            emit(f"detectedRollback_lqSelect_2_0{psuf}_uop_{gf}", arr, f"[{p}]", w, out)
        # s2 redir (lqSelect_REG{_1})
        emit(f"detectedRollback_lqSelect_REG{psuf}_valid",           "s2_redir_valid", f"[{p}]", 1, out)
        emit(f"detectedRollback_lqSelect_REG{psuf}_bits_level",      "s2_redir_level", f"[{p}]", 1, out)
        emit(f"detectedRollback_lqSelect_REG{psuf}_bits_robIdx_flag","s2_redir_robf",  f"[{p}]", 1, out)
        emit(f"detectedRollback_lqSelect_REG{psuf}_bits_robIdx_value","s2_redir_robv", f"[{p}]", 8, out)

    # store 违例数据锁存。
    #   ★paddr: golden violationMdata_p_r 存满 48 位, CAM 只读 [27:4](PADDR_OFFSET +: PPA_W)。
    #   impl st_paddr_r 只存 [27:4](bit 下标 27..4 与 golden 同位)。故只钉 golden[27:4]↔impl[27:4];
    #   golden 高 20 位[47:28]+低 4 位[3:0] 无 impl 对应 → FM 判 ref-unread(golden-only cone-dead)
    #   → PASS_DEAD_REF(impl clean, 0 impl-unread)。
    #   mask: 全 16 位都读, 逐位钉。
    PADDR_OFFSET = 4
    PPA_W = 24  # [27:4]
    for p in range(2):
        for b in range(PADDR_OFFSET, PADDR_OFFSET + PPA_W):   # 4..27
            out.append(f"set_user_match {esc(R+f'/detectedRollback_paddrModule_io_violationMdata_{p}_r_reg[{b}]')} "
                       f"{esc(I+f'/st_paddr_r_reg[{p}][{b}]')}")
        emit(f"detectedRollback_maskModule_io_violationMdata_{p}_r",  "st_mask_r",  f"[{p}]", 16, out)
    # freeList 子模块 freeSlotOH（golden freeList/..._N_r[b] <-> impl freeList/..._r[N][b]）
    RF = f"r:/WORK/{TOP}/freeList"
    IF = f"i:/WORK/{TOP}/u_core/freeList"
    for n in range(4):
        for b in range(32):
            out.append(f"set_user_match {esc(RF+f'/freeSlotOH_next_nextVec_{n}_r_reg[{b}]')} "
                       f"{esc(IF+f'/freeSlotOH_next_nextVec_r_reg[{n}][{b}]')}")

    hdr = ["# fm_pins.tcl —— LoadQueueRAW 顶层 glue（最老选择流水 + 条目 payload + store 锁存",
           "#   + freeList OH）golden↔impl 双射钉名。",
           "# 自动生成: gen_fm_pins.py（勿手改）。双射值恒等，非 waiver/删点/放宽。",
           ""]
    open("fm_pins.tcl", "w").write("\n".join(hdr + out) + "\n")
    print(f"wrote fm_pins.tcl: {len(out)} set_user_match")

if __name__ == "__main__":
    main()
