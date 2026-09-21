# VARIANTS: InstrUncache InstrMMIOEntry
# ---------------------------------------------------------------------------
# InstrUncache 钉点文件的**夹具**：给 scripts/pin_call_equiv.py 用，
# 不参与任何 FM 跑（FM 那边 find_cells 是 Formality 自己的动词）。
#
# 为什么现在需要它：fm_pins_pre.tcl 新增的 InstrMMIOEntry 分支用 find_cells
# 做存在性 discover（因为 set_user_match 不抛异常、catch 守卫是空的，见该文件注释），
# 于是这份钉点文件从"静态"变成了"动态"——它发出的 set_user_match 调用序列成了
# find_cells 输出的函数。要判"以后某次改动是不是守卫专属"，必须先把这个输入固定住。
#
# 点名照钉点文件自己声明的规则造，数量机械推导：InstrMMIOEntry 锁存的 48 位
# MMIO 取指地址里**只有 bit 0 没有读者**（req_addr[2:1] 选半字、req_addr[47:3]
# 按 8 字节对齐发 Get），所以两侧各恰 1 个点、钉 1 对。
# 两条 pattern 与本 lane 在真 Formality 上跑过的探针逐字节同形（含两条负测）：
#   find_cells {r:/WORK/InstrMMIOEntry/req_addr_reg[0]}            -> 1
#   find_cells {i:/WORK/xs_InstrMMIOEntry_core/req_reg\[addr][0]}  -> 1
#   find_cells {r:/WORK/InstrMMIOEntry/req_addr_reg_NOSUCH[0]}     -> 0
#   find_cells {i:/WORK/xs_InstrMMIOEntry_core/req_reg\[addr][99]} -> 0
# 注意 impl 侧断言用的是**设计作用域名** xs_InstrMMIOEntry_core/...，
# 而 set_user_match 用的是实例路径 InstrMMIOEntry/u_core/...（find_cells 在实例
# 路径下枚举不到寄存器，见 verif/ut/Predictor/fm_pins_pre.tcl 的 J 组探针）。
#
# ★夹具造错了不会掩盖什么★：钉点文件自己的 `llength != 1` 守卫会当场 error，
# 闸（RC 非 0 / 调用数对不上）就红。
#
# $top eq "InstrUncache" 那一支不调 find_cells，夹具对它是透明的：
# 它照旧只发 1 次 set_user_match，基线表里那一行的 sha256 不该变。
# ---------------------------------------------------------------------------
proc find_cells {pattern} {
    switch -exact -- $pattern {
        {r:/WORK/InstrMMIOEntry/req_addr_reg[0]} {
            return [list {r:/WORK/InstrMMIOEntry/req_addr_reg[0]}]
        }
        {i:/WORK/xs_InstrMMIOEntry_core/req_reg\[addr][0]} {
            return [list {i:/WORK/xs_InstrMMIOEntry_core/req_reg\[addr][0]}]
        }
    }
    return {}
}
