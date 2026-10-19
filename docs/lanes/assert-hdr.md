# Lane assert-hdr（codex 0240 遗留 2）

Base: main 9ae0e8144（claim c7d17d48d）。提交：4c2833900 修复（仅两 rtl 文件）；bdbf3a203 两目标 evidence；
0277d4d1f 同 UT 目录 9 个兄弟叶 evidence；本文档另一提交。

## 问题
`rtl/backend/TrapEntryVSEventModule.sv`、`rtl/backend/VSstatusModule.sv` 的 `` `ifndef SYNTHESIS ``
断言块用 firtool 宏 `` `ASSERT_VERBOSE_COND_ `` / `` `STOP_COND_ ``，文件本身不定义；整芯片仿真
只因 `verif/sim/xstile_sim_filelist.py` 把 G1 `extern_modules.sv` 放清单最前才编得过（文件顺序依赖）。
改前实测：两文件不带 extern_modules.sv、不定义 SYNTHESIS 编译 → `Error-[UM] Undefined macro`（7/7 档全 COMPILE_FAIL）。
两文件只用到这两个宏（`PRINTF_COND_`、`RANDOMIZE*`、`ENABLE_INITIAL_*` 均未使用）。

## 做法（与任务书的偏差：没有用 .svh）
任务书建议新增 `rtl/common/<x>.svh` 并 `` `include ``。**本仓 gate 禁止**：
`scripts/check_no_svh_in_rtl.py`（`gate_all.sh` 第 227–228 行，CONVENTIONS「单文件规范」）
判据 A = rtl/ 下不许有 .svh，判据 B = rtl/ 的 .sv 里不许出现 `` `include ``（include .sv 也算）。
改闸要用户批准，不在本 lane 权限内。故改为**每个文件在 module 前自带同一段守卫定义**——这正是
firtool 自己的做法（G1 每个 golden 文件都带完整宏头）：

```systemverilog
`ifndef ASSERT_VERBOSE_COND_
  `ifdef ASSERT_VERBOSE_COND
    `define ASSERT_VERBOSE_COND_ (`ASSERT_VERBOSE_COND)
  `else
    `define ASSERT_VERBOSE_COND_ 1
  `endif
`endif
`ifndef STOP_COND_   ... 同构，默认 1
```

与 G1 `extern_modules.sv` 第 69–85 行（firtool-1.62.1）逐字同义：同名、同覆盖钩子、同默认值。
- 用户覆盖：`+define+ASSERT_VERBOSE_COND=<expr>` / `+define+STOP_COND=<expr>` 照旧生效；直接
  `+define+ASSERT_VERBOSE_COND_=...` 也照旧生效（外层 `ifndef` 跳过）。
- 与 golden 同编：外层守卫是带下划线的名字，谁先定义谁生效，后者 `ifndef` 跳过 → 永不重定义；
  两边定义文本相同，所以无论文件顺序结果一样（下面 newextfirst/newextlast 两档实测）。
- 两处副本（每文件 15 行）是 gate 下的代价；若日后要合成一份，需先改 `check_no_svh_in_rtl.py`（须用户批准）。
- 宏定义是 `$unit` 级，对后续文件可见——与 golden 宏头同一性质、同一取值，无泄漏差异。

## xs_assert_v2 的来源（DPI，不自包含，沿用测试平台依赖）
- 声明：`difftest/src/test/vsrc/common/assert.v` 第 23 行 `import "DPI-C" function void xs_assert_v2(input string filename, input longint line);`
  （包在 `` `ifndef TB_NO_DPIC `` 里，`$unit` 级）。
- 实现：`difftest/src/test/csrc/common/common.cpp` 第 40 行（打印 `Assertion failed at <file>:<line>.` 并计数），
  原型 `common.h:126`。
- 因此：不定义 SYNTHESIS 时，两文件仍需测试平台提供 assert.v（以及 C 实现）。这与 golden 完全相同：
  golden `VSstatusModule.sv` / `TrapEntryVSEventModule.sv` 单独、不定义 SYNTHESIS 编译同样报
  `Error-[IND] Identifier 'xs_assert_v2'` ×2（实测）。本 lane 只消除宏的文件顺序依赖，不消除 DPI 依赖。

## 验证
### 1. 单文件编译（不带 extern_modules.sv）
`vcs -full64 -sverilog [+define+SYNTHESIS] rtl/backend/<f>.sv -top <f>`

| 文件 | +define+SYNTHESIS | 不定义 SYNTHESIS | 不定义 SYNTHESIS + difftest assert.v + DPI C |
|---|---|---|---|
| VSstatusModule | rc=0, 0 err, 0 warn | 宏全部解析；仅剩 `xs_assert_v2` 未声明 ×2（同 golden） | rc=0, 0 err |
| TrapEntryVSEventModule | rc=0, 0 err, 0 warn | 同上 | rc=0, 0 err |

### 2. 断言开关行为不变
harness：`/home/eda/xs-env/tmp-ah/beh/`（`gen_tb.py` 从端口表生成 tb：两模块同时例化、全部输入每拍
`$random` 驱动、3000 拍、seed 7；`dpi.c` 实现 xs_assert_v2 打印 `XS_ASSERT_V2 <file>:<line>`；
`run_matrix.sh <tag> <srcs...>` 跑 7 档宏设定，抽取 `Assertion failed` 与 `XS_ASSERT_V2` 行，
把 `file:line` 归一成模块名后取 sha256——行号因插入 21 行而平移，属预期）。

| 宏档 | 改前 + extern_modules.sv（基准） | 改后单独 | 改后 + ext 在前 | 改后 + ext 在后 |
|---|---|---|---|---|
| 无定义 | fwrite 1379 / dpi 1379 / f8b81bd10781 | 同 | 同 | 同 |
| ASSERT_VERBOSE_COND=0 | 0 / 1379 / d34968645aa3 | 同 | 同 | 同 |
| ASSERT_VERBOSE_COND=1 | 1379 / 1379 / f8b81bd10781 | 同 | 同 | 同 |
| STOP_COND=0 | 1379 / 0 / a5c1423ebf00 | 同 | 同 | 同 |
| 两者=0 | 0 / 0 / 63467f3d723a | 同 | 同 | 同 |
| ASSERT_VERBOSE_COND_=0（直接） | 0 / 1379 / d34968645aa3 | 同 | 同 | 同 |
| STOP_COND_=0（直接） | 1379 / 0 / a5c1423ebf00 | 同 | 同 | 同 |

改前单独编译：7 档全部 `Error-[UM] Undefined macro`。所有改后编译日志无宏重定义告警。

### 3. FM（官方 run_proof.sh，PROOF 钉 4c2833900，signoff-strict）
- `bash scripts/run_proof.sh TrapEntry200c TrapEntryVSEventModule` → SUCCEEDED passing 283 / failing 0 / unmatched 0，
  dont_verify=false（与此前 evidence/93b434c9-final 的 283 相同）。
- `bash scripts/run_proof.sh NewcsrLeaves6 VSstatusModule` → SUCCEEDED passing 84 / failing 0 / unmatched 0
  （与 evidence/383bb8897f14 的 84 相同）；`fm_predict.py check VSstatusModule` 全部对上。
  TrapEntryVSEventModule 无预测登记文件（老目标，batch_reproof 口径 = unregistered）。
- evidence：`evidence/4c28339009f1/{TrapEntryVSEventModule,VSstatusModule}/`（-f 提交）。

### 4. UT 6 档（seed 1/7/42 × initreg 0/1，各 200000 拍）
- TrapEntry200c：6/6 TEST PASSED，checks=200000 errors=0。
- NewcsrLeaves6：6/6 TEST PASSED，checks=200000 errors=0。
- 注：两 UT 都编 `+define+SYNTHESIS`，断言块不在其中；断言路径由第 2 节覆盖。

### 5. `bash scripts/xstile_rtl_elab.sh <wd>` → `XSTILE_RTL_ELAB: PASS`（rtl 1529 文件 + 存储模型 97；闭包 2136 模块），vcs errors=0。

### 6. 同 UT 目录兄弟叶（receipt 层面）
`ut_common.mk` 的 `FM_IMPL_SRCS` = 该 UT 目录**全部** RTL_SRCS，所以 TrapEntry200c 另 4 叶、NewcsrLeaves6 另 5 叶的
receipt 闭包也含被改文件（`gen_receipt_harvest.py` 判 NEEDS_RERUN）。已在 bdbf3a203 上 official 重证，全部 SUCCEEDED、
failing 0、unmatched 0、dont_verify=false，passing 与旧 round 台账逐个相同：
TrapEntryD 166 / TrapEntryHS 447 / TrapEntryM 428 / TrapEntryMN 207 / VSiselect 91 / Vstart 78 / VStimecmp 192 / Vtype 73 / VirtualLevelPermit 2。
evidence：`evidence/bdbf3a20366c/`。

### 7. gate_all（在 bdbf3a203 上跑；整套跑到第 290 行被我设的 3000 s 外部超时截断，余下 20 步单独补跑）
全部 PASS，除以下 3 个**派生表幂等闸**（本 lane 不许改派生表，交 integrator 重生成）：
- `round 台账幂等`（harvest_round_ledger --check）：只是 TrapEntryVSEventModule / VSstatusModule 两行改指新 receipt（p283/p84 不变）；
  加上兄弟叶后另有 9 行同理。
- `覆盖率台账幂等`（rewrite_coverage --check）：unique_design_proven 989→978、golden_lines_proven 3248480→3222955 等——
  是 ExuBlock/Backend/XSCore/XSTile 证书失效的直接后果（见下节），不是新问题。
- `receipt 收录表复算`（gen_receipt_harvest --check）：重算后 NEEDS_RERUN 仅剩 CSR / ExeUnit_7 / ExuBlock / NewCSR 四个祖先
  （receipt 闭包含两文件；这三个 + ExuBlock 都没重跑，按指示停下）；其余 11 行（两目标 + 9 兄弟）重新 COLLECTED。
三项在基线 c7d17d48d 上均 PASS（实测）。`rtl 无 svh 闸` PASS。

## 受影响父证明（`tools/batch_reproof.py validate`，全部 505 份证书）
基线（HEAD c7d17d48d，改前）已有 175 个 current-valid≠True（多为 `green_child_script_closure_changed:...:scripts/fm_eq.tcl`
等既存原因，与本 lane 无关）。改后（HEAD 4c2833900，及最终 0277d4d1f 复核同样结果）逐行 diff，**新增 4 个**：

| target | 改前 | 改后原因 |
|---|---|---|
| ExuBlock | True | `green_child_closure_changed:ExuBlock:rtl/backend/TrapEntryVSEventModule.sv`（证书 input_closure 直接含两文件；PASS_DEAD_REF@2e0390dff） |
| Backend | True | `green_child_nested_via_Backend:green_child_closure_changed:ExuBlock:...TrapEntryVSEventModule.sv` |
| XSCore | True | 同上（经 Backend → ExuBlock） |
| XSTile | True | 同上 |

其余 501 个结果与基线逐行一致（ExuBlock_1 仍 True）。只报首个变化文件；VSstatusModule.sv 同在 ExuBlock 闭包内。
NewCSR / CSR / ExeUnit_7 没有 tracked 证书（不在 validate 名单内），但 receipt 层面 NEEDS_RERUN（上节）。
**未重跑**任何祖先 official（NewCSR/CSR/ExeUnit_7/ExuBlock/Backend/XSCore/XSTile），按指示停下交 integrator 决定。
恢复路径：ExuBlock 在新提交上 official 重证 + 出证书，然后 Backend / XSCore / XSTile 依次重证（或至少重出证书）。

## 遗留
- 任务书要求的「.svh + include」形态与 `check_no_svh_in_rtl.py` 冲突，本 lane 用文件内守卫替代；若要单一宏头需用户批准改闸。
- `verif/sim/xstile_sim_filelist.py` 仍把 extern_modules.sv 放最前（C 线范围，未动）；对这两个文件已不再必要，但清单里 golden 件可能还需要它。
- 派生表 docs/fm_round_20260917.tsv、docs/rewrite_coverage.tsv、docs/receipt_harvest.tsv 需 integrator 重生成。
- DPI `xs_assert_v2` 仍由测试平台（difftest assert.v + common.cpp）提供。
