# sramcore-d1d2d3 跑前登记（codex 0206 D1/D2/D3 + 集成者追加的 DataStorage_2 位宽修正）

分支 `agent/sramcore-d1d2d3`（基于 main 3cd47062，已并入 agent/dcachebody@0056a2a1、agent/slice@cc236e69，无冲突）。
本文件与 `docs/fm_predictions/*.json` 的提交**早于**下面所有证明 commit。

## 1. 改了什么

| 项 | 文件 | 内容 |
|---|---|---|
| D1 | `rtl/common/xs_SRAMTemplate_core.sv` | `MCP_HOLD=0 && ENABLE_HOLDREAD=0` 分支（同名 `g_nomcp`，条件生成互斥分支）不再声明/生成 `rdata_last_REG`，`readLast=1'b0`；`respReg`/`rckEn`/`wckEn`/`respCapture` 不变；`ENABLE_HOLDREAD=1` 分支保持 `rdata_last_REG <= ren`，层次名 `g_nomcp.rdata_last_REG` / `g_nomcp.respReg` 均不变；MCP/holdRead/MBIST 路径不动 |
| D1 连带 | `scripts/gen_bankeddataarray.py` → `verif/ut/BankedDataArray/fm_pins_pre.tcl` | 32 条 MBIST 采样使能钉点由 impl `g_nomcp.rdata_last_REG`（merge 幸存名）改为 `g_nomcp.respReg` |
| D1 连带 | `scripts/gen_dcache.py` | 删 `retarget_bda_resp`（BDA 钉点已是 respReg），改为见到 rdata_last_REG 即报错；生成物 `verif/ut/DCache/fm_pins_pre.tcl` 字节不变（`--check` OK） |
| 追加 | `scripts/gen_l2_datastorage.py` → `rtl/uncore/DataStorage_2.sv` | bore 字段位宽逐 bank 读 golden `childBd[_k]_<f>`；DataStorage_2 的 `sramBore_array` 声明 6 位、bank0 连接取 `[4:0]`（golden 5/6/6/6）。DataStorage/_1/_3 golden 各 bank 同宽，生成物不变 |
| D2 | `scripts/fm_verdict.py` | 新类别 `disabled_empty_module`，仅 `DISABLED_EMPTY_MODULES={StorePipe: golden sha256 daf59d16…, 父级 DCache, 实例 stu_0/stu_1, impl rtl/memblock/StorePipe.sv}` |
| D2 | `verif/allow/DCache.json` | `declare_allow.py DCache --class StorePipe=disabled_empty_module` 重生成：+4 条，其余 80 条逐字段不变 |
| D3 | `scripts/audit_ram_memory_model.py` | `MANUAL_REVIEW_PARENTS` / `check_parent_scope`：ram_10x89 授权父级 = 0202 的 GrantBuffer/Queue10 + codex_0206 的 Slice×4（仅 `grantBuf/pftRespQueue/ram_ext`，两侧各 1） |
| D3 | `scripts/fm_verdict.py` | assembly 判定对 MANUAL_REVIEW 名单里的 ram_* 调父级范围检查；经由 GrantBuffer 的须在父 commit 上验 `verif/proof_certificates/GrantBuffer.json` 当前有效（`_child_cert_current`） |
| D3 | `verif/proof_certificates/GrantBuffer.json` | `make_proof_certificate.py --evidence evidence/deb72ce588a2/GrantBuffer`（clean SUCCEEDED passing 11752） |

## 2. D1 的影响面（改前记录）

`python3 scripts/check_shared_impl_impact.py --file rtl/common/xs_SRAMTemplate_core.sv`（改前 HEAD，核 sha256
`55b51e13e6f58d98385d6fff52b16956e81da22d75b7cbda50279e8efe48d97e`）：**85 个目标**，其中本 lane 证明 5 个
（DCache、Slice×4），其余 **80 份**清单见 `docs/lanes/sramcore-d1d2d3_restale.tsv`（目标 / UT 目录 / 原 receipt）。
其中 DataStorage×4、GatedSplittedSRAM×4 共 8 个因 DataStorage_2 修正在本 lane 重证（tsv 第 4 列 yes），剩 72 个交集成者批量重证。
DataStorage_2.sv 的影响面：12 个目标（DataStorage×4、GatedSplittedSRAM×4、Slice×4），全部在本 lane 内。

## 3. 预测（fm_predict register 已写进 docs/fm_predictions/）

| 目标 | 模型 expected | 预测 passing | 预测 unread | 预测 verdict | 理由 |
|---|---|---|---|---|---|
| DCache | 82495 | 82086 | 0（原 40） | SUCCEEDED | passing = 82495 − constant_reg 411 + 2；40 个 rdata_last_REG 是 impl 独有未读、无 golden 对家，本来就不计 passing，删掉只让 unread 归零；StorePipe×4 由 D2 声明 |
| Slice | 69845 | 68305 | 0（原 7） | SUCCEEDED | 同理，Directory 7 块 SRAM 的 rdata_last_REG；ram_10x89 按 codex_0206 |
| Slice_1 | 69848 | 68308 | 0（原 7） | SUCCEEDED | 同上 |
| Slice_2 | 69850 | 68310 | 0（原 7） | SUCCEEDED | 同上 |
| Slice_3 | 69851 | 68311 | 0（原 7） | SUCCEEDED | 同上 |
| DataStorage / _1 / _2 / _3 | 2532 / 2533 / 2534 / 2534 | 同左 | 0 | SUCCEEDED | 闭包 SRAM 全为 MCP（D1 不触及）；DataStorage_2 补回的 bit5 在 golden SRAMTemplate_178 只到 `mbistBd_array` 探针 wire，无扇出 |
| GatedSplittedSRAM / _1 / _2 / _3 | 2272 ×4 | 2272 ×4 | 0 | SUCCEEDED | 同上 |

DCache 的 +2：上一跑 BBPin 实测 3450 比模型 3448 多 2，推测是两个 StorePipe 空壳各 1 位输入 `io_lsu_req_valid`
的黑盒输入比较点（父级驱动该输入的逻辑被比较，空壳内部无比较点）。跑后从 matched 报告核实。

**停止条件（codex 0206 原话）**：共享核清理后若出现任何新 failing/unmatched，停止推广并报告首个最小反例，不用 policy 吸收。
DataStorage_2 若 passing 与预测不同 = 该位可观测，按真 bug 报首个反例。

## 4. UT（9 档，seed 串行，三个 UT 目录并行）

- DCache：seed 1/7/42 × INITREG {0, glue, glue017}（沿用 dcachebody 档位）
- Slice、DataStorage：seed 1/7/42 × INITREG {0, random, <seed>017}
- 复跑：`cd verif/ut/<ut> && make run SEED=<s> INITREG=<档>`

## 5. FM

`bash scripts/run_proof.sh DCache DCache < /dev/null`；`bash scripts/run_proof.sh Slice <T> < /dev/null`（T=Slice/Slice_1/Slice_2/Slice_3）；
`bash scripts/run_proof.sh DataStorage <T> < /dev/null`（8 个）。DataStorage 先于 Slice（集成者要求）。

## 6. 负测（进 gate_all）

- `python3 scripts/test_disabled_empty_module.py`：1 正 + 14 负（sha 不符、多/少实例、impl 有寄存器/输出/例化、别的 design、u 非 e、混入别的 unresolved、父级不是 DCache、父级 unmatched/native/dont_verify、golden 正文有 output）
- `python3 scripts/test_audit_ram_manual_review.py`：原 1 正 7 负 + 父级范围 S0（6 个授权父级）/ S1 别的父级 / S2 别的 ram / S3 别的路径 / S4 不对称 / S5 一侧两个 / S6 class 不对 / C0 HEAD 证书有效 / C1 证书不在 commit / C2 impl 闭包变 / C3 golden 闭包变 / C4 G1 不同源

## 7. 跑后对账（只追加，不改上文）

FM（`bash scripts/run_proof.sh <ut> <T> < /dev/null`，全部 native SUCCEEDED、判定 SUCCEEDED，failing/unverified/aborted/unmatched/unread 0，无 dont_verify）：

| 目标 | 预测 passing | 实测 | constant_reg | 黑盒对象 | evidence |
|---|---|---|---|---|---|
| DCache | 82086 | 82086 | 411 | 84（array_7_ext 64 + array_8_ext 16 + StorePipe 4） | evidence/f009d7b3c6d1/DCache（正式）；ce9d0692bc8e/DCache 同读数，但当时登记 82495 未计 StorePipe BBPin，check 余额 −2 判红，故改模型、重登记、重证 |
| Slice / _1 / _2 / _3 | 68305 / 68308 / 68310 / 68311 | 同左 | 1540 | 24 | evidence/ce9d0692bc8e/Slice* |
| DataStorage / _1 / _2 / _3 | 2532 / 2533 / 2534 / 2534 | 同左 | — | 8 | evidence/ce9d0692bc8e/DataStorage* |
| GatedSplittedSRAM ×4 | 2272 | 2272 | — | 8 | evidence/ce9d0692bc8e/GatedSplittedSRAM* |

DCache 实测 BBPin 3450 = 模型 3448 + StorePipe 2 实例 × 1 位输入（fm_passing_model 修正后模型 82497，差 411 = constant_reg）。
DataStorage_2 位宽修正前后 passing 均为 2534：补回的 bit5 不可观测（golden 只到 mbistBd_array 探针 wire），不是功能 bug，按 golden 位宽修正。
`python3 scripts/fm_predict.py check <13 个目标>` rc=0「全部对上」；`python3 scripts/check_lane_receipts.py <worktree>` rc=0。

UT（200k 拍，errors 全 0）：DCache 9/9（checks=199977/档，cov_fail=0）；Slice 9/9（checks=267200000/档，cover_zero=0）；
DataStorage 9/9（checks=3200000/档，rd/wr/err 覆盖各变体约 5 万/5 万/3 万）。D1 前的 SRAMTemplate（holdRead=1 变体）20k 冒烟也 PASS。
