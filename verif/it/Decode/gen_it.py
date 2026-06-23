#!/usr/bin/env python3
# =============================================================================
# gen_it.py —— Decode(译码)簇 IT 装配生成器
#
# 目的: 把 rtl/backend 下「已重写」的 DecodeStage + DecodeUnit + FPDecoder +
#       UopInfoGen 这 4 个重写核机械地组装成 *_it 命名链, 使其能与 golden 顶层
#       DecodeStage 在同一次 VCS 编译里共存(u_g=golden, u_i=全重写 _it 链), 首次
#       把「DecodeStage glue → DecodeUnit → {FPDecoder, UopInfoGen}」这条重写边界
#       全程直连跑起来。
#
#  ----------------------------------------------------------------------------
#  Decode 簇装配树(golden 顶层 DecodeStage 的子模块):
#    DecodeStage
#     ├─ DecodeUnit ×6   →(重写) → FPDecoder + UopInfoGen  ←(均重写)
#     ├─ DecodeUnitComp  →(未重写, golden) → VecExceptionGen + tables...
#     └─ VTypeGen        →(未重写, golden) → VsetModule
#  ----------------------------------------------------------------------------
#
#  已重写 → 加 _it / 改名, 在 IT 中直连重写核:
#    - DecodeStage glue : rtl/backend/DecodeStage.sv 内 module xs_DecodeStage_core
#        (扁平端口=golden DecodeStage)。复制为 DecodeStage_it.sv, module 改名
#        DecodeStage_it, 并把它例化的 6 个 `DecodeUnit` 模块名 → DecodeUnit_it。
#        (DecodeUnitComp / VTypeGen 不改名 → 用 golden 共享叶子。)
#    - DecodeUnit       : rtl/backend/DecodeUnit_wrapper.sv 内 golden 同名 wrapper
#        module DecodeUnit(扁平端口) 内部例化 xs_DecodeUnit_core。复制为
#        DecodeUnit_it.sv, module DecodeUnit → DecodeUnit_it, 例化的核
#        xs_DecodeUnit_core → xs_DecodeUnit_core_it。
#    - DecodeUnit 核     : rtl/backend/DecodeUnit.sv 内 module xs_DecodeUnit_core,
#        内部例化 golden 名 `FPDecoder` / `UopInfoGen`。复制为
#        DecodeUnit_core_it.sv, module xs_DecodeUnit_core → xs_DecodeUnit_core_it,
#        FPDecoder → FPDecoder_it, UopInfoGen → UopInfoGen_it。
#    - FPDecoder / UopInfoGen : 复用 verif/ut/<M>/variants_xs.sv 里的 *_xs 适配器
#        (纯端口搬运 + 例化 xs_<M>_core)。复制为 FPDecoder_it.sv / UopInfoGen_it.sv,
#        module FPDecoder_xs → FPDecoder_it, UopInfoGen_xs → UopInfoGen_it。
#
#  未重写 → 用 golden 共享叶子(README §4 允许; 两侧 u_g/u_i 例化同一份):
#    DecodeUnitComp / VTypeGen 及其传递闭包(VecExceptionGen / VsetModule /
#    indexedLSUopTable_* / *NumOfUopTable)。它们不是 Decode glue 算法, 工程未单独
#    重写, 作为共享叶子保留 golden 是诚实的。Makefile 里只编一份给两侧共用。
# =============================================================================
import re, os

RTL = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../rtl/backend"))
UT  = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../ut"))
OUT = os.path.dirname(os.path.abspath(__file__))

def word_sub(text, old, new):
    """只替换整词出现(词边界), 避免误伤 xs_DecodeUnit_core 里的 DecodeUnit 等。"""
    return re.sub(r'(?<![A-Za-z0-9_])' + re.escape(old) + r'(?![A-Za-z0-9_])', new, text)

generated = []

# --- 1. DecodeStage glue 核 → DecodeStage_it (顶层, 扁平端口=golden) ---
with open(os.path.join(RTL, "DecodeStage.sv")) as f:
    t = f.read()
t = word_sub(t, "xs_DecodeStage_core", "DecodeStage_it")
# 把例化的 6 个 DecodeUnit(在 decodestage_decoders.svh 里)的模块名换成 _it:
# 这里 svh 是 `include 进来的, 故另生成 _it 版 svh 并改 include。
t = t.replace('`include "decodestage_decoders.svh"',
              '`include "decodestage_decoders_it.svh"')
with open(os.path.join(OUT, "DecodeStage_it.sv"), "w") as f:
    f.write(t)
generated.append("DecodeStage_it.sv")

# decoders svh: DecodeUnit 例化模块名 → DecodeUnit_it
with open(os.path.join(RTL, "decodestage_decoders.svh")) as f:
    t = f.read()
t = word_sub(t, "DecodeUnit", "DecodeUnit_it")
with open(os.path.join(OUT, "decodestage_decoders_it.svh"), "w") as f:
    f.write(t)
generated.append("decodestage_decoders_it.svh")

# --- 2. DecodeUnit golden 同名 wrapper → DecodeUnit_it (扁平端口=golden DecodeUnit) ---
with open(os.path.join(RTL, "DecodeUnit_wrapper.sv")) as f:
    t = f.read()
t = word_sub(t, "module DecodeUnit", "module DecodeUnit_it")
t = word_sub(t, "xs_DecodeUnit_core", "xs_DecodeUnit_core_it")
with open(os.path.join(OUT, "DecodeUnit_it.sv"), "w") as f:
    f.write(t)
generated.append("DecodeUnit_it.sv")

# --- 3. DecodeUnit 核 → xs_DecodeUnit_core_it, FPDecoder/UopInfoGen → *_it ---
with open(os.path.join(RTL, "DecodeUnit.sv")) as f:
    t = f.read()
t = word_sub(t, "xs_DecodeUnit_core", "xs_DecodeUnit_core_it")
t = word_sub(t, "FPDecoder", "FPDecoder_it")
t = word_sub(t, "UopInfoGen", "UopInfoGen_it")
with open(os.path.join(OUT, "DecodeUnit_core_it.sv"), "w") as f:
    f.write(t)
generated.append("DecodeUnit_core_it.sv")

# --- 4. FPDecoder / UopInfoGen 重写适配器(复用 UT variants_xs) → *_it ---
with open(os.path.join(UT, "FPDecoder", "variants_xs.sv")) as f:
    t = f.read()
t = word_sub(t, "module FPDecoder_xs", "module FPDecoder_it")
with open(os.path.join(OUT, "FPDecoder_it.sv"), "w") as f:
    f.write(t)
generated.append("FPDecoder_it.sv")

with open(os.path.join(UT, "UopInfoGen", "variants_xs.sv")) as f:
    t = f.read()
t = word_sub(t, "module UopInfoGen_xs", "module UopInfoGen_it")
with open(os.path.join(OUT, "UopInfoGen_it.sv"), "w") as f:
    f.write(t)
generated.append("UopInfoGen_it.sv")

print("generated:")
for g in sorted(generated):
    print("  ", g)
