#!/usr/bin/env python3
# =============================================================================
# gen_it.py —— Rename-Dispatch(重命名)簇 IT 装配生成器
#
# 选层: golden 顶层 `Rename`(=重命名流水), 它直接例化:
#   CompressUnit  + MEFreeList(intFreeList) + StdFreeList{,_1,_2,_3}(fp/vec/v0/vl)
# 这是边界最清晰、且把多个「已重写叶子」一起连起来跑的层。
# (RenameTable 在 golden 里由 RenameTableWrapper 例化、不在 Rename 内; RenameBuffer/
#  NewDispatch 在 CtrlBlock 这个 1.2MB 自动生成互联体内, 边界不清晰 → 不选。)
#
# IT 装配 = u_g(纯 golden Rename) vs u_i(Rename_it):
#   Rename_it     : golden 同名扁平端口 → 例化重写算法核 xs_Rename_core_it
#                   (从 verif/ut/Rename/variants_xs.sv 的 Rename_xs 适配器改名而来,
#                    core 实例指向 _it 版核)。
#   xs_Rename_core_it : 复制 rtl/backend/Rename.sv 的 xs_Rename_core, 把其内部
#                    3 个「可重写叶子」实例的模块名重定向到 UT 的 _xs 适配器:
#                       CompressUnit  → CompressUnit_xs   (→ xs_CompressUnit_core)
#                       MEFreeList    → MEFreeList_xs     (→ xs_MEFreeList_core)
#                       StdFreeList   → StdFreeList_xs    (→ xs_StdFreeList_core)  [base/fp]
#                    ⇒ 重写 glue 核 ↔ 重写叶子核 首次直连。
#
# 诚实标注(不偷用 golden 充重写, 也不假造重写):
#   - StdFreeList_1/_2/_3 (vec/v0/vl, 空闲池 81/21/31) 保持 golden 叶子:
#     xs_StdFreeList_core 的 SIZE 是 pkg 里的 localparam(158, =fp), 无参数化, 无法
#     覆盖另外 3 个尺寸的变体 → 这 3 个没有可用的重写核, 如实保留 golden。
#   - SnapshotGenerator{,_11,_12}: 快照存储原语(memory model), 两侧共享 golden(README 规则3)。
#
# 输出文件(本目录):
#   xs_Rename_core_it.sv   (= rtl Rename.sv 核 + 3 处叶子模块名重定向 + 核改名 _it)
#   Rename_it.sv           (= UT Rename_xs 适配器, 模块改名 Rename_it, core→_it)
# =============================================================================
import os, re

HERE = os.path.dirname(os.path.abspath(__file__))
RTL  = os.path.abspath(os.path.join(HERE, "../../../rtl/backend"))
UT   = os.path.abspath(os.path.join(HERE, "../../ut"))

# ---- 1. xs_Rename_core_it.sv : 复制核, 重定向 3 个可重写叶子的模块名 ----
with open(os.path.join(RTL, "Rename.sv")) as f:
    core = f.read()

# 核改名(避免与 UT 共享的 xs_Rename_core 撞名; 本 IT 只编一份, 但保持唯一性纪律)
core = core.replace("module xs_Rename_core", "module xs_Rename_core_it")

# 叶子重定向: 只改例化处的「模块名」token。词边界精确替换, 不误伤端口/信号。
# CompressUnit compressUnit ( → CompressUnit_xs compressUnit (
core = re.sub(r'(?m)^(  )CompressUnit( +compressUnit )',
              r'\1CompressUnit_xs\2', core)
# MEFreeList intFreeList ( → MEFreeList_xs intFreeList (
core = re.sub(r'(?m)^(  )MEFreeList( +intFreeList )',
              r'\1MEFreeList_xs\2', core)
# `STD_FL(StdFreeList, ...) → `STD_FL(StdFreeList_xs, ...)  仅 base(fp)那一行
core = re.sub(r'(`STD_FL\()StdFreeList(,)',
              r'\1StdFreeList_xs\2', core)
#   StdFreeList_1/_2/_3 不在上面正则匹配范围(逗号前是 _1 等), 保持 golden。

with open(os.path.join(HERE, "xs_Rename_core_it.sv"), "w") as f:
    f.write(core)

# ---- 2. Rename_it.sv : 复制 UT Rename_xs 适配器, 改名 + core 指向 _it ----
with open(os.path.join(UT, "Rename", "variants_xs.sv")) as f:
    wrap = f.read()
wrap = re.sub(r'(?<![A-Za-z0-9_])module Rename_xs', 'module Rename_it', wrap)
wrap = wrap.replace("xs_Rename_core u_core", "xs_Rename_core_it u_core")
with open(os.path.join(HERE, "Rename_it.sv"), "w") as f:
    f.write(wrap)

print("generated:")
print("   xs_Rename_core_it.sv  (core + 3 leaf redirects: CompressUnit/MEFreeList/StdFreeList[base])")
print("   Rename_it.sv          (top adapter -> xs_Rename_core_it)")
# 重定向自检
n_cu  = core.count("CompressUnit_xs")
n_me  = core.count("MEFreeList_xs")
n_fl  = core.count("StdFreeList_xs")
n_g1  = len(re.findall(r'STD_FL\(StdFreeList_[123]', core))
print(f"   self-check: CompressUnit_xs={n_cu} MEFreeList_xs={n_me} StdFreeList_xs(base)={n_fl} golden StdFreeList_1/2/3 kept={n_g1}")
