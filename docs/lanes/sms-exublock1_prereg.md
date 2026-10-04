# sms-exublock1 lane（agent/sms-exublock1）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `0af8e172`（worktree `/home/eda/xs-env/wt-sms-exublock1`，分支 `agent/sms-exublock1`，认领 commit `e96b826b`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `SMSPrefetcher`（§1）、`ExuBlock_1`（§2） |
| 口径 | `FM_MERGE_DUP=false`（模型严格适用）、无 dont_verify、无放宽 appvar；SMSPrefetcher 为 assembly（唯一黑盒 = 厂商宏叶子 array_12_ext，两侧对称，vendor_macro），ExuBlock_1 为 signoff-strict（无黑盒） |
| UT | 双例化 golden vs `_xs`，每拍全部输出逐位 `!==`；seed 1/7/42 × `+vcs+initreg+0` / `+vcs+initreg+random` / `+vcs+initreg+<seed>017`，各 200k 拍，串行 |

child 状态逐个核实（receipt verdict + impl 闭包 sha256 与当前字节一致）：
ActiveGenerationTable `evidence/e7a91a910053` SUCCEEDED、PatternHistoryTable `evidence/0394e97e720c` SUCCEEDED、
PrefetchFilter `evidence/0eb94b233e9d` SUCCEEDED、SMSTrainFilter `evidence/83fa26ae624e` SUCCEEDED、
StridePF `evidence/a5e1c2945d2a` SUCCEEDED；ExeUnit_8 `evidence/bbd73158a339`、ExeUnit_9 `evidence/41366b7e2f9c`、
ExeUnit_10 `evidence/21fcdf533a90` 均 SUCCEEDED。（`docs/coverage_three_axis.tsv` 里 PatternHistoryTable / ExeUnit_8/9/10
仍是 MISSING/UNPROVEN —— 派生表未重生成，以 receipt 为准；本 lane 不改派生表。）

## 1. SMSPrefetcher（golden 478 行）

### 1.1 结构与子模块处置

- `rtl/memblock/SMSPrefetcher.sv`（455 行，`_GEN_`/`_T_` = 0）：手写可读核 `xs_SMSPrefetcher_core`（§1 s0 训练寄存器：区域哈希 tag /
  相邻区域 tag 与越界判断 / PHT index·tag；§2 PHT 预取请求门控 io_pht_en；§3 L2 请求门控 io_enable + 物理内存范围）
  + golden 同名 wrapper（GENERATED 区，`scripts/gen_sms.py` 生成，带 `--check`）。
- 5 个直接 child 两侧白盒（ref golden / impl 重写件）：train_filter / active_gen_table / stride / pht / pf_filter。
  pht 下厂商宏叶子 array_12_ext 两侧对称黑盒（`verif/allow/SMSPrefetcher.json`，`scripts/declare_allow.py` 由实跑 black_boxes.rpt 生成）。
- FM「匹配前」钉点 `verif/ut/SMSPrefetcher/fm_pins_pre.tcl`（gen_sms.py 生成，fail-closed，字面 3987）：
  (a) 本层寄存器 186 位（golden 扁平名 ↔ u_core）；(b) 5 个 child 签核用过的钉点 3002 条（tclsh 桩取调用序列、加实例前缀，
  条数与 `docs/pin_call_seq.tsv` 登记核对）；(c) train_filter 进本层才变死的 799 位按语义整组钉（见 §1.3）。

### 1.2 UT（verif/ut/SMSPrefetcher，tb 由 gen.py 生成；在 commit c539eab5e 的 RTL 字节上跑）

激励偏置让 训练→AGT→PHT→pf_filter→L2 整条链路跑起来（PC 池 / 区域基址池 ±1 区域 / 原始区域地址全 1·全 0 越界 /
物理页映射落在物理内存范围 / TLB 回应 miss·异常·pbmt·PMP / 三个使能按 mode 关）。不复位寄存器直出端口 ⇒ pf_filter 16 项都 alloc 过、
golden 发过 TLB 请求、SRAM 读过一次之后 +4 拍才开始比（arm）。恒值输出位（TLB 请求常量字段、区域/块对齐低位）不要求见 0/1 但照比。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=3538512 errors=0 | checks=3538512 errors=0 | checks=3538512 errors=0 |
| 7  | checks=3520908 errors=0 | checks=3520908 errors=0 | checks=3520908 errors=0 |
| 42 | checks=3532194 errors=0 | checks=3532194 errors=0 | checks=3532194 errors=0 |

覆盖（seed 1，全部 >= 5 否则 TEST FAILED；另每个非豁免输出位都见过 0 和 1）：训练请求 196537、AGT 逐出 151162、AGT 查 PHT 135589、
+1 区域越界 5444、-1 区域越界 5651、PHT 预取 682、PHT 被 io_pht_en 挡 29、TLB 请求 286、pf_filter 吐地址 2576、L2 请求 2133、
范围外被挡 105、io_enable 关被挡 338、中途复位 14。

变异自检（scratchpad 改核、seed 7 × random × 20k 拍，改完原样恢复）：M1 +1 越界判断取错位 errors=32812；M2 去掉 io_pht_en 门控 17700；
M3 去掉物理内存上界 12；M4 PHT index 取 pc[7] 46266；**M5 区域实地址高 2 位补 01 而非 00：errors=0** —— 这两位进 AGT 表项 /
PHT 查询的 region_paddr[39:38]，在 L2 地址里被截掉（48 位物理地址只用区域地址 [37:0]），端口上不可见；FM 覆盖：AGT/PHT/pf_filter
存这两位的寄存器是比较点（vmucp 下无读者的也比），常量差异必被抓。

复跑：`cd verif/ut/SMSPrefetcher && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 诊断跑（如实记；diagnostic-full，关 vmucp，未出证，commit c539eab5e，钉点只有 (a)(b) 两节 3188 条）

native SUCCEEDED、passing 7612、failing 0、unmatched compare 0、constant_reg 0，unread 1107：
- matched-unread 308：本层 train_s0_pc 50 位（只有 [9:0] 送对外不可见的 StridePF）+ child 签核时已入白名单的 258 位
  （StridePF 220 / PHT 19 / PrefetchFilter 10 / SMSTrainFilter 8 / AGT 1）；
- unmatched-unread 799/799：SMSTrainFilter 的 pc[0]、pc[49:20]、paddr[9:0]、vaddr[5:0] × (3 级重排 × 3 路 + 8 表项)，本层无读者、
  无扇出签名 ⇒ 加第 (c) 节钉点，钉点集合与诊断跑 unmatched unread 集合逐条比对：两侧均精确相等（799 = 799）。
vmucp 依据与六条证据：`verif/fm_target_config/SMSPrefetcher.tcl`。

### 1.4 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/SMSPrefetcher.json）

| 目标 | 模型 expected | 诊断 passing / constant / unread | 预测 passing | 其余 |
|---|---|---|---|---|
| SMSPrefetcher | 8719（regs 8181 + outs 380 + 黑盒输入 158） | 7612 / 0 / 1107 | **8719**（+1107） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 黑盒 = array_12_ext 两侧各 1 / 无 dont_verify / SUCCEEDED（assembly） |

可能出错的地方：(1) 若 passing = 8719 − 799，说明第 (c) 节钉点没生效（FM 拒钉会 error，不会静默）；(2) vendor_macro 声明路径与
实测不等 ⇒ verdict PARTIAL，不改 RTL，修声明。

## 2. ExuBlock_1（golden 823 行）

### 2.1 结构与子模块处置

- 本层只有一样时序逻辑：每个 ExeUnit 一份 `RegNext(io_frm)`（5 × 3 位，不复位）。手写核 `rtl/backend/xs_ExuBlock_core.sv`（37 行，
  参数 N_FRM，§1 frm 打拍；文件头写明本层**没有**握手仲裁 / 唤醒 / og0·og1 取消 / perf —— 前两者直连 ExeUnit、取消在 IQ/DataPath、
  perf 计数在综合口径被删，golden 只剩无读者的 `_GEN*` fire 线）。
- golden 同名 wrapper `rtl/backend/ExuBlock_1.sv`（636 行，`_GEN_`/`_T_` = 0）由新生成器 `scripts/gen_exublock.py`（沿用 gen_exeunit.py
  风格，带 `--check`）生成，按 §1 发射口→ExeUnit 分发 / §2 本层核 / §3 ExeUnit 例化 / §4 唤醒·取消·perf（本层无）分节；
  fail-closed：寄存器必须全是 frm 打拍、`_GEN*` 必须是无读者的 fire、连线只能是端口 / child 输出 / frm 寄存器 / 1'h1。
  未改已签共享核 xs_ExeUnit_core 与 gen_exeunit.py（只 import 其 golden 解析）。
- 5 个直接 child 两侧白盒：exus = ExeUnit_8、exus_1/exus_3 = ExeUnit_9、exus_2/exus_4 = ExeUnit_10；闭包 = 三者 UT Makefile 的
  RTL_SRCS / RTL_GOLDEN_DEPS / FM_REF_DEPS 并集，原样继承其处置。无黑盒。
- FM「匹配前」钉点 `verif/ut/ExuBlock_1/fm_pins_pre.tcl`（字面 5497）：(a) frm 寄存器 15 位；(b) 三种 ExeUnit 签核钉点
  1920 + 2×11 + 2×1770 = 5482 条（tclsh 桩取调用序列、加实例前缀，条数与 pin_call_seq.tsv 核对）。

### 2.2 UT（verif/ut/ExuBlock_1，tb 由 gen.py 生成；在 commit 729e16270 的 RTL 字节上跑，每拍逐位比全部输出口）

激励按各口所接 ExeUnit 的结构自动推出（fuType 85% 取 Dispatcher acceptVec 编码、valid 60%、ExeUnit_9 口 10% 反压、robIdx 3/4 窄范围、
冲刷 10%、FDivSqrt 1/8 除数为 0、frm 每拍随机、cg_bore 1/20）；复位后 48 拍暖机轮流灌每个 FU。恒值输出位（无 busy 外壳的 in.ready、
无 FDivSqrt 的 fflags[3]、golden 写成 {64'h0,..} 的数据高 64 位）不要求见 0/1，照比。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=23993280 errors=0 | checks=23993280 errors=0 | checks=23993280 errors=0 |
| 7  | checks=23993280 errors=0 | checks=23993280 errors=0 | checks=23993280 errors=0 |
| 42 | checks=23993280 errors=0 | checks=23993280 errors=0 | checks=23993280 errors=0 |

覆盖（seed 1 × initreg 0，全部 >= 1000，另每个非豁免输出位都见过 0 和 1）：冲刷 20079；fire exus 119701 / exus_1 31242 / exus_2 120384 /
exus_3 31054 / exus_4 120348；FU 写回 exus{Falu 23962, Fcvt 23096, f2v 25427, Fmac 21702}、exus_1 Fdiv 25670、exus_2{Falu 48298, Fmac 43814}、
exus_3 Fdiv 25475、exus_4{Falu 48677, Fmac 43524}；反压 exus_1 2565 / exus_3 2506；busy exus_1 147978 / exus_3 148310。
（seed 42 × 42017 一档因后台作业 2 小时上限被截断，单独重跑一遍得上表读数。）

变异自检（seed 7 × random × 20k 拍，改完 `git checkout` 恢复）：E1 核里第 3 份 frm 恒 0 ⇒ errors=185；E2 io_in_0_1_ready 接成 exus_3 的 ready ⇒ 6812；
E3 exus 的 io_frm 不打拍直连 io_frm ⇒ 115。（把 5 份 frm 互换接口是等价变换 —— 5 份值恒相同 —— UT 与 FM 都不该也不会区分。）

复跑：`cd verif/ut/ExuBlock_1 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 2.3 诊断跑（如实记；diagnostic-full，关 vmucp，未出证，钉点 5497 条全部生效）

native SUCCEEDED、passing 25302、failing 0、unmatched compare 0、unmatched unread 0、constant_reg 903，unread 22 全部 matched：
恰为 5 个 ExeUnit 各自签核时的 vmucp 集合（exus 10 / exus_1 1 / exus_2 5 / exus_3 1 / exus_4 5），本层无新增。
constant_reg 903 = 299 + 2×30 + 2×272（与三者单独签核一致）。vmucp 依据：`verif/fm_target_config/ExuBlock_1.tcl`。

### 2.4 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/ExuBlock_1.json）

| 目标 | 模型 expected | 诊断 passing / constant / unread | 预测 passing | 其余 |
|---|---|---|---|---|
| ExuBlock_1 | 26227（regs 21607 + outs 4620） | 25302 / 903 / 22 | **25324**（+22；差 903 = constant_reg） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / 无 dont_verify / SUCCEEDED（signoff-strict） |

可能出错的地方：5 份 frm 寄存器值恒相同，merge_dup 关故不合并；若 passing 少 12，是被合并成 1 份（配置问题，不是 RTL 问题）。

## 3. 对账（跑后追加；上面各节数字未改）

| 目标 | 证明 commit | 预测 passing | 实测 passing | constant_reg | failing / unverified / aborted / unmatched / unread | 黑盒 / dont_verify | 判决 | fm_predict check |
|---|---|---|---|---|---|---|---|---|
| SMSPrefetcher | 77ecedcaa49c | 8719 | 8719 | 0 | 0 / 0 / 0 / 0 / 0（vmucp 1107 点，+1107；钉点 ok=3987 bad=0） | array_12_ext 两侧各 1（vendor_macro，声明精确相等）/ 否 | SUCCEEDED（assembly，145 s） | 差 0，逐位相等 |
| ExuBlock_1 | 1e7fbcc94d3c | 25324 | 25324 | 903 | 0 / 0 / 0 / 0 / 0（vmucp 22 点，+22；钉点 ok=5497 bad=0） | 无 / 否 | SUCCEEDED（signoff-strict，769 s） | 差 903 = constant_reg 903，全部指认 |

receipt：`evidence/77ecedcaa49c/SMSPrefetcher/receipt.json`，sha256 `673afd4d0c2bef12e0a63895c7f147860ad799b2ff2f5eed3bc442fd69e10e9e`。
复跑：`PROOF_COMMIT=77ecedcaa bash scripts/run_proof.sh SMSPrefetcher SMSPrefetcher < /dev/null`；`python3 scripts/fm_predict.py check SMSPrefetcher`。

receipt：`evidence/1e7fbcc94d3c/ExuBlock_1/receipt.json`，sha256 `5d70330ff19a9d01d81b1ddc5faa986bee815bec0da3ec5bdc11c1b02a371cf2`。
复跑：`bash scripts/run_proof.sh ExuBlock_1 ExuBlock_1 < /dev/null`（或 `PROOF_COMMIT=1e7fbcc94 ...`）；`python3 scripts/fm_predict.py check ExuBlock_1`。
两个目标预测与实测均零偏差。
