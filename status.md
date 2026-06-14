# 前端重写进度跟踪

状态：⬜ 未开始 / 🔨 进行中 / ✅ 完成
验证列：UT=单元仿真 FM=形式等价 DOC=文档

## 第 1 阶段：公共基础库（所有模块的依赖，最先做）

| # | 模块 | 来源 | Scala行数 | 变体数 | SV | DOC | UT | FM | 备注 |
|---|------|------|------|------|----|----|----|----|------|
| 1.1 | WrBypass | frontend/WrBypass.scala | 128 | 5 | ✅ | ✅ | ✅ | ✅ | 样板模块，含 xs_IndexableCAM / xs_PlruReplacer；UT 25万拍0错，FM 5变体全过 |
| 1.2 | CircularQueuePtr | utility | ~300 | 参数化 | — | — | — | — | 是 Chisel Bundle 类型不生成独立模块，并入使用者(FTQ/IBuffer)随其重写为 SV package |
| 1.3 | SRAMTemplate | utility/sram | ~1500 | 50 | 🔨 | ✅ | ✅ | ✅ | xs_SRAMTemplate_core+生成器；ICache单端口族6变体(icsh_tag/dat)全UT+FM过；SRAM宏/门控当黑盒。余变体多为后端/L2/双口/bitmask(非前端)，待对应子系统按族扩展 |
| 1.4 | FoldedSRAMTemplate | utility/sram | ~400 | 24 | ⬜ | ⬜ | ⬜ | ⬜ | TAGE/SC/ITTAGE 用 |
| 1.5 | SplittedSRAMTemplate | utility/sram | ~300 | 7 | ⬜ | ⬜ | ⬜ | ⬜ | FTB/FTQ 用 |
| 1.6 | SyncDataModuleTemplate | utility/sram | ~200 | 9 | ✅ | ✅ | ✅ | ✅ | xs_SyncDataModule，含分bank/扇出复制；9变体全过 |
| 1.7 | DataModuleTemplate | utility | ~250 | 9 | ✅ | ✅ | ✅ | ✅ | xs_DataModule（内层），随 1.6 一起完成；9变体全过 |
| 1.8 | PipelineConnect | backend/datapath | ~80 | 18 | ✅ | ✅ | ✅ | ✅ | xs_PipelineConnect；18变体(11完整握手+7下游恒就绪)全过；新增FM扁平payload字段映射机制 |

## 第 2 阶段：BPU 分支预测（叶子表→预测器→Composer）

| # | 模块 | Scala行数 | 生成SV行数 | SV | DOC | UT | FM | 备注 |
|---|------|------|------|----|----|----|----|------|
| 2.1 | RAS (newRAS) | 804 | 1342 | ⬜ | ⬜ | ⬜ | ⬜ | 返回地址栈 |
| 2.2 | TageBTable | 143 | 300 | ⬜ | ⬜ | ⬜ | ⬜ | 基础双峰表 |
| 2.3 | TageTable | 251 | ~300×16 | ⬜ | ⬜ | ⬜ | ⬜ | 16 个变体 |
| 2.4 | Tage | 617 | ~3800 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 2.5 | SCTable / SC | 448 | ~200×4 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 2.6 | Tage_SC | 1069 | 7608 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 2.7 | ITTageTable / ITTage | 833 | 2431 | ⬜ | ⬜ | ⬜ | ⬜ | 间接跳转预测 |
| 2.8 | FauFTB | 233 | 6886 | ⬜ | ⬜ | ⬜ | ⬜ | uFTB |
| 2.9 | FTB | 912 | 3381 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 2.10 | Composer / Predictor | 1310 | 44818 | ⬜ | ⬜ | ⬜ | ⬜ | BPU 顶层 |

## 第 3 阶段：ICache

| # | 模块 | Scala行数 | 生成SV行数 | SV | DOC | UT | FM | 备注 |
|---|------|------|------|----|----|----|----|------|
| 3.1 | ICacheMetaArray | 内嵌 | 671 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.2 | ICacheDataArray | 内嵌 | 2527 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.3 | WayLookup | 186 | 3483 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.4 | ICacheMainPipe | 654 | 1329 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.5 | ICacheMissUnit + MSHR | 479 | 1163 | ⬜ | ⬜ | ⬜ | ⬜ | MSHR 13 变体 |
| 3.6 | ICacheReplacer | 内嵌 | 7058 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.7 | IPrefetchPipe | 623 | 818 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.8 | ICacheCtrlUnit | 297 | 335 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.9 | ICache 顶层 | 897 | 1721 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 3.10 | InstrUncache | 236 | 187 | ⬜ | ⬜ | ⬜ | ⬜ | |

## 第 4 阶段：FTQ

| # | 模块 | Scala行数 | 生成SV行数 | SV | DOC | UT | FM | 备注 |
|---|------|------|------|----|----|----|----|------|
| 4.1 | FtqPcMemWrapper | 445 | ~3000 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 4.2 | FTBEntryGen | 176 | ~2000 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 4.3 | Ftq | 1824 | 112955 | ⬜ | ⬜ | ⬜ | ⬜ | 前端最复杂模块 |

## 第 5 阶段：IFU / IBuffer

| # | 模块 | Scala行数 | 生成SV行数 | SV | DOC | UT | FM | 备注 |
|---|------|------|------|----|----|----|----|------|
| 5.1 | PreDecode | 502 | ~1100 | ✅ | ✅ | ✅ | ✅ | 首个设计模块；纯组合，RVC两段式边界+分支译码+跳转偏移；UT 20万向量0错，FM SUCCEEDED；分支译码抽到 predecode_pkg 共享 |
| 5.1b | F3Predecoder | ~15 | ~1100 | ✅ | ✅ | ✅ | ✅ | F3级分支预译码，复用 predecode_pkg；UT 20万向量0错，FM SUCCEEDED |
| 5.2 | NewIFU | 1252 | 5574 | ⬜ | ⬜ | ⬜ | ⬜ | |
| 5.3 | IBuffer | 502 | 20517 | ⬜ | ⬜ | ⬜ | ⬜ | |

## 第 6 阶段：Frontend 顶层 + BT/ST

| # | 模块 | SV | DOC | 验证 | 备注 |
|---|------|----|----|------|------|
| 6.1 | Frontend 顶层组装 | ⬜ | ⬜ | ⬜ | |
| 6.2 | BT 块级平台 | — | — | ⬜ | Frontend vs golden 双例化 |
| 6.3 | ST 系统级（difftest 替换） | — | — | ⬜ | make simv + NEMU |

## 命名与方法学约定

- 手写参数化模块名加 `xs_` 前缀（如 `xs_WrBypass`），避免与 golden 同名冲突，UT 直接例化。
- 每个模块另写一份"变体包装文件"（如 `WrBypass_variants.sv`），用 golden 的单态化模块名
  （`WrBypass_32` 等）例化参数化核心，用于：① FM 与 golden 同名顶层直接比对；② ST 级
  直接替换 build/rtl 同名文件。
- 寄存器命名尽量沿用 Scala 源码信号名（即 golden RTL 的寄存器名），帮助 FM 名字匹配。
- firtool 会裁剪上层未用的输出端口（如 WrBypass_41 没有 io_hit_data_0_valid），包装层
  按 golden 实际端口写，未用输出悬空。

## 设计模块（无SRAM，已完成）
- PreDecode ✅ / F3Predecoder ✅ / FauFTBWay ✅（均 UT+FM 通过）
- SplittedSRAMTemplate（base 变体）✅ — Splitted 层，内层 SRAMTemplate 当黑盒，UT+FM 过
- FauFTB ✅（并行 agent 重写，主线核验）— uFTB 32路全相联，复用 FauFTBWay；UT 4万拍0错+FM SUCCEEDED
- InstrMMIOEntry/InstrUncache ✅（主线）— MMIO取指FSM+TileLink路由；UT 6万拍0错，3模块FM全过
- FTBEntryGen ✅（agent，主线核验）— FTB条目生成纯组合；UT 20万向量0错+FM
- WayLookup ✅（agent，主线核验）— ICache way查询FIFO；UT 6万拍0错+FM
- SRAMTemplate BP变体 _36(bp_ftb)/_45(bp_tage) ✅（主线）— 8变体UT+FM全过
- IPrefetchPipe ✅（agent，主线核验）— ICache预取3级流水；UT 8万拍0错+FM 901点全过
- ICacheMainPipe ✅（agent，主线核验）— ICache主流水3级s0/s1/s2；UT 12万拍0错+FM 2793点全过
- ICacheCtrlUnit (+Queue1) ✅（agent，主线核验）— ECC控制/注入FSM+TileLink寄存器映射；UT 6万拍0错+FM 2模块全过
