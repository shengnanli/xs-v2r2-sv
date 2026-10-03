# srt-divblocks lane 第三阶段 —— 跑前登记（VIDiv）

本文件在 **FM 起跑之前**提交 §0–§4；跑完在文末追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `09da2b26`（集成者把 main `3f23a91c` 合入并追加第三阶段认领）；实现 commit `ad190dab` |
| 目标 | `VIDiv`（向量整数除法 FU 外壳，ExeUnit_17 的 child；ExeUnit_17 本身不做） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 冲突核查 | 全部分支 `diff main...` 的 rtl 无 VIDiv；全部 worktree claim 只有本 lane |
| child | VectorIdiv（本 lane 第二阶段签）、Mgu（PROVEN_DIRECT，其下 ByteMaskTailGen / UIntToContLow1s / UIntToContLow0s / MaskExtractor）——两侧白盒 |
| 已签件改动 | 无（本阶段只新增 `rtl/backend/VIDiv.sv`） |

## 1. 结构

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` |
|---|---:|---:|---:|
| VIDiv | 397 | 343（`rtl/backend/VIDiv.sv`：vidiv_pkg + xs_VIDiv_core + wrapper） | 0 |

核分节：§1 保持旁路（DataHoldBypass）/ §2 RobPtr.needFlush / §3 VectorIdiv / §4 Mgu 与 vl=0 旧值 / §5 出口透传寄存器。
bug-for-bug：掩码先判 VialuFixType.needClearMask（0x84/0x86，对除法 opType 永不命中，照抄）；Mgu vdIdx 取 vuopIdx[2:0]；
fuOpType=0xFF 的非 SYNTHESIS 断言不实现（同 FAlu 口径）。

## 2. UT（`verif/ut/VIDiv`，RTL 字节 = `ad190dab`，读数在 §6 追加）

golden vs `_xs` 逐拍对拍全部出口 + 每次出口握手的独立 oracle：写回数据按 SEW 逐元素（RISC-V 除法语义的商/余数，再按
vl=0 / vstart≥vl / prestart / tail(vta) / 掩掉(vma) / active 合并），透传字段对照发射时的 uop；冲刷用独立 RobPtr 模型判定。
九档：seed 1/7/42 × initreg 0 / random / `<seed>017`，各 200k 拍。

## 3. 证明计划

先诊断跑看配对与 unread（VectorIdiv 子树的 1600 个档位/死位钉点要按 `vidiv/` 前缀重出；外壳的结构体寄存器名需实测），
再按需补钉点 / vmucp，补登 §5 后跑 official。

## 4. 跑前预测（★跑完不许改本节★）

| 目标 | expected | 预测 |
|---|---:|---|
| VIDiv | 13884（regs 13094 + outs 790） | constant_reg **8**（VectorIdiv 子树里 8 个 I8DivNr4 各 1）；unread **100** = VectorIdiv 子树 96 + `outCtrl_r_vpu_vuopIdx[6:3]` 4 位（Mgu 只读低 3 位）；钉点 + vmucp 后 passing **13876**，failing / unmatched / 黑盒 0 |
