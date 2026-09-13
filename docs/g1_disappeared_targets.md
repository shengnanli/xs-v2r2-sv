# 上轮 306 里在 G1 消失的目标——去向定位

> **2026-09-12 更新（codex 0150 D54 第 2 步）**：本文原先列 7 个「需人工定位」的目标。
> 用**槽位判据**（模块身份 = 它占据的 `(父模块, 实例名)` 集合）机器重算后，**7 个里 6 个
> 已机器定位**，去向全部写回 `docs/g1_universe.tsv` / `docs/g1_old_to_new_map.tsv`
> （`resolve=slot_map`），逐条依据在 `docs/g1_slot_map_evidence.tsv`，
> 由 `scripts/check_universe_freeze.py` 的 C5 每次重算校验。
> 只剩 `CLINT` 一个仍是 `gone_in_g1`。
>
> 原文里有两处**事实错误**，一并订正（见下表 ★ 标注）。

判据分档，**不把"看起来像"当成"就是"**：
- **槽位判据（机器）**：两侧 `(父模块, 实例名)` 集合相等（`site`），或存在两版共有的槽位
  且该槽位在对侧唯一指向一个模块（`site_common`），或父模块自己也被重编号、
  先把父映射过去再查（`site_via_parent`）→ **可自动改判**，写进台账。
- **人工判断**：槽位判据不给答案（父模块改名、实例名也改了、一处例化被拆成多处）
  → **如实留白**，台账保留 `gone_in_g1`，人工结论只记在本文，机器不背书。

## 已机器定位的 6 个

| 上轮目标 | G1 去向 | 判据 | 机器依据（端口数 / 槽位） |
|---|---|---|---|
| `FastArbiter_44` | **`FastArbiter_43`** | `site` | 44→44 端口；两侧槽位集合都恰好是 `{RNXbar.rxsnpArbs_0}` |
| `FastArbiter_47` | **`FastArbiter_46`** | `site` | 84→84 端口；两侧槽位集合都恰好是 `{SNXbar.txreqArb}` |
| `SRAMTemplate_66` | **`SRAMTemplate_68`** | `site_common` | 33→33 端口；G0 占 `SCTable{,_1,_2,_3}.table_0` 4 个槽位，G1 的 `_68` 占这 4 个**加上**新增的 `.table_1` 共 8 个；共有的 4 个槽位在 G1 侧唯一指向 `_68` |
| `PMPChecker_10` | **`PMPChecker_12`** | `site` | 251→492 端口（内容大改，但身份确定）；两侧槽位集合都恰好是 `MemBlock.inner_pmp_checkers_0..7` |
| `NewPipelineConnectPipe_32` | **`NewPipelineConnectPipe_34`** ★订正★ | `site` | 71→99 端口；两侧槽位集合都恰好是 `{MemBlock.inner_otherStoutConnect}`。**原文说「`_34`/`_35` 一对多、具体对应尚未确认」是错的**——`_34` 与 `_35` 各占一组互不相交的槽位：`_35`（356 端口）占的是 `MemBlock.inner_V{l,s}Split*` 4 个槽位，那是 G0 `NewPipelineConnectPipe_33` 的去向，与 `_32` 无关。 |
| `L1FlagMetaArray_1` | **`L1FlagMetaArray`** ★订正★ | `site` | 45→45 端口；两侧槽位集合都恰好是 `{DCache.accessArray}`。**原文说「并入 `L1FlagMetaArray`、`_1` 变体不复存在」是错的**——G1 `DCache` 仍然例化两个 meta array，只是**名字整体平移**了：`accessArray` 槽位上的类从 `L1FlagMetaArray_1` 改叫 `L1FlagMetaArray`，而 `errorArray` 槽位上原来的 `L1FlagMetaArray`（30 端口）改叫 `L1ErrorMetaArray`（47 端口）。这是一次**同名不同物**的改名，不是合并；按名字配对会把 30 端口的错误阵列顶到 45 端口的访问阵列上。 |

顺带（不在原 7 个里、由同一次重算发现）：`L1FlagMetaArray` 自己也不是 `same_name`，
它的去向是 `L1ErrorMetaArray`。台账已改。

## 仍然留白的 1 个

| 上轮目标 | 人工判断的去向 | 为什么机器不判 |
|---|---|---|
| `CLINT` | `TIMER`（同位替换，须重写） | G0 `MemMisc.clint` 在 G1 里**实例名也改了**（`MemMisc.timer`），两侧无共有槽位，槽位判据不给答案。接口方向还翻转了：G0 `CLINT` 自己产生时间（`input io_rtcTick`、`output io_time_valid/bits`），G1 `TIMER` 改为**接收**时间（`input io_time_valid/bits`），时间源移到模块外。属重新设计。台账保留 `gone_in_g1`；`TIMER` 在 `g1_configured_universe.tsv` 里作为 `new_target` 独立计数，守恒不漏。 |

## 结论对 MAIN 分母的影响

- 6 个已定位的目标**回到 MAIN 分母**（`resolve=slot_map`），不再按 removed 处理。
  连带效果：`SRAMTemplate_68` 从 AUX 升为 MAIN 且已有合格 receipt（`REVALIDATED_PASS`），
  即上一版台账把一条**已经证完的覆盖**误记成了"目标已消失/未开始"。
- `CLINT` 仍按 removed 处理，其 G1 对应物 `TIMER` 作为 new_target 独立计数与证明。
- **没有任何一个可以继承上轮结论**：槽位判据只确定「是同一个设计元素」，
  不保证内容没变（`PMPChecker_10→_12` 端口 251→492 就是明证）。
  继承与否仍须逐个看 delta 并重新证明。
