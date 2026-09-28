# VMergeBuffer lane（agent/vmergebuf）—— 跑前登记

本文件在 FM 正式证明（`scripts/run_proof.sh`）**之前**提交；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（main，`git worktree add /home/eda/xs-env/wt-vmergebuf -b agent/vmergebuf 975b64e6`） |
| 工作树 | `/home/eda/xs-env/wt-vmergebuf`，分支 `agent/vmergebuf` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `VLMergeBufferImp`（golden 14,173 行 / 411 端口）、`VSMergeBufferImp`（golden 8,007 行 / 191 端口） |
| UT 目录 | `verif/ut/VMergeBuffer`（一个 tb 两对双例化） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），`FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`（依据见 `verif/fm_target_config/<T>.tcl`），allowlist 0，无 dont_verify，无黑盒（FreeList/FreeList_1/NewPipelineConnectPipe_29 两侧白盒） |

## 1. 核与 wrapper

- `rtl/memblock/VLMergeBufferImp.sv`：`package vmergebuffer_pkg` + 参数化可读核 `xs_VMergeBuffer_core`
  （§1..§11，按 Chisel VMergeBuffer.scala 的赋值顺序写，条目按字段 SoA）+ golden 同名 wrapper。
- `rtl/memblock/VSMergeBufferImp.sv`：store 变体薄 wrapper（`IS_VSTORE=1`，1/1/1 口）。
- 机械区（端口 struct、uop 透传字段存储、流水缓冲连线、两个 wrapper、tb、fm_pins_pre.tcl）由
  `scripts/gen_vmergebuf.py` 生成（`--check`；生成时 fail-closed 对账：条目寄存器字段集合与 golden
  逐字相等、异常位集合 = exceptionOut、流水缓冲字段映射与 golden `data_*` 寄存器逐个同名同宽、
  wrapper 补常量的字段在该变体确实无端口）。
- `_GEN_` / `_T_<n>`（去注释代码区）：VLMergeBufferImp.sv 0 / 0，VSMergeBufferImp.sv 0 / 0；
  `scripts/readability_audit.py` 通过（>1500 行，已配导航）。

与 golden 对齐时查实的怪癖（都写在核文件头与各节注释里）：
1. 端口缺失的输入字段 = 上游常量被 firtool 跨模块传播：load 流水 hit≡1、sourceType≡0；store 流水
   sourceType≡1；flushState≡0；入队 uop 的 flushPipe/replayInst/psrc_2/trigger≡0。wrapper 补常量。
2. 两变体条目字段集合不同（store 无 data/vdIdx/vl/originVl/fof/flushState，却留着 debug 的 isPartReplay；
   load 无 uop_vpu_vmask/uop_vpu_vl）。
3. load 版的异常/计数写回用打一拍后的流水结果，同一 valid/mBIndex 在 golden 里是三份独立寄存器
   （pipeValidReg/latchWbValid/pipewbValidReg 等），核里一份不少。
4. 出队 SelectOne("circ")：口 0 取编号最小的 uopFinish，口 1 取编号最大的且需 ≥2 个完成。

## 2. UT（`verif/ut/VMergeBuffer`，seed 串行，每档 200k 拍）

见文末对账 D（跑在 proof commit 的同一份 RTL 字节上）。激励与暖机设计见 tb.sv 文件头；
tb 带覆盖计数（写回 / toLsq / 反馈 / 部分重放 / 带异常出队），另做过 5 个变异体自检（见对账 D）。

## 3. FM 名字鸿沟与钉点（lane 内诊断试跑发现，试跑不出 receipt）

- 首次试跑（VS，无钉点）：`2352 matched by name / 0 by signature / 17680(17680) unmatched`，
  且流水缓冲 payload 被 FM 按末段名错配（`data_data_reg[0]` ↔ `data_reg[6]`，与
  NewPipelineConnectPipe_29 单独签核时同一个坑）→ failing ≥ 20（截断）。
- 修法（只消名差，不修错配、不约束 ref）：
  - `fm_pins_pre.tcl`（生成）：匹配前按该模块已签核的字段映射逐位钉 payload，期望 1023 × 出队口数；
  - `fm_pins.tcl`：首次 match 后按机械叶名规则钉本层寄存器（`entries_<i>_<f>` ↔ `entries_<f>[i]` 等），
    四道 fail-closed（无规则 / 无对家 / set_user_match≠1 / impl 剩余≠0 均 error）；
    子模块 FreeList(_1) 的寄存器留给第二次 match 的签名分析（试跑实测 112/113 个全配上）。
- 同一轮试跑还抓到两个"只有 FM 看得见"的核缺陷并已修（commit e37a3c41）：`always_ff` 里声明的
  临时量被推成寄存器（idx/feedbackValid），`addrOffset` 未全路径赋值成锁存器。
- 加钉点后试跑（核字节 = e37a3c41，vmucp 关）：
  - VS：native SUCCEEDED passing **20022**，failing 0，unverified 0，unmatched 0，Constant reg 10，
    unread(matched_nc) 20 = isPartReplay×16 + 流水缓冲 load 类异常位×4。
  - VL：native SUCCEEDED passing **24245**，failing 0，unverified 0，unmatched 0，Constant reg 76，
    unread(matched_nc) 115 = brodenMergeDataReg 高字节 24 + brodenMergeMaskReg[31] 3 +
    replayFlowNum 80 + 流水缓冲 store 类异常位 8。
  两者 unread 全部两侧对称 → vmucp（六条证据写在 `verif/fm_target_config/<T>.tcl`）。

## 4. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

| 目标 | 模型 expected | 预计实测 passing | 差额与指认 | 其余 |
|---|---|---|---|---|
| VLMergeBufferImp | **24436**（regs 21953 + outs 2483） | **24360**（= 24245 + 115） | 76 = receipt `constant_reg` | failing 0 / unverified 0 / aborted 0 / unread 0 / unmatched 六项 0 / 无黑盒 / SUCCEEDED |
| VSMergeBufferImp | **20052**（regs 18819 + outs 1233） | **20042**（= 20022 + 20） | 10 = receipt `constant_reg` | 同上 |

钉点期望：`MB_PREPIN_END n=2046`（VL）/ `n=1023`（VS）；`MB_PIN_END … impl_left=0`。

### 明写可能出错的地方
1. `constant_reg` 由 FM 逐侧折叠决定（Rename 实测过折叠结果随匹配状态变）；若开 vmucp 后
   constant_reg 与试跑不同，差额按 receipt 指认，指认不了按 fail 查。
2. fm_pins.tcl 的"本层"过滤依赖 FM 对 generate 块的命名（`g_x.name`，用 "." 连接）；若证明 worktree
   里的 FM 命名不同，会表现为 `MB_PIN_NO_PARTNER` 早退而不是数字偏离。
3. VL 试跑 FM 墙钟约 16 分钟，正式证明开 vmucp 后可能更长。

---

# 对账（跑完追加；上文各节未改一字）

## A. 起止 commit

| 项 | 值 |
|---|---|
| 跑前登记 / proof commit | `0282c93b52b40ab85b16333244c1cb73d929494e`（登记与预测 JSON 即在此 commit 进库，证明钉在同一 commit） |
| 证据目录 | `evidence/0282c93b52b4/{VLMergeBufferImp,VSMergeBufferImp}`（`git add -f`） |
| VLMergeBufferImp receipt.json sha256 | `64200a9ee8f349bf2ae408701142f19b4e181dc1e80c2fb40fd58aa8e9df1af7` |
| VSMergeBufferImp receipt.json sha256 | `b5991649f512aec929297abfda95133c978d5cc94663934f0c552499da102f87` |

## B. 逐条对账（`python3 scripts/fm_predict.py check VLMergeBufferImp VSMergeBufferImp` rc=0，「全部对上」）

| 目标 | 模型 | 预计 | 实测 passing | 差 | 指认 | failing/unverified/aborted/unread_nc | unmatched | 黑盒 | verdict | FM 墙钟 |
|---|---|---|---|---|---|---|---|---|---|---|
| VLMergeBufferImp | 24436 | 24360 | **24360** | 76 | constant_reg 76 | 0/0/0/0 | 0(0)，unread 0 | 无（matched_blackbox_pairs []） | SUCCEEDED | 896 s |
| VSMergeBufferImp | 20052 | 20042 | **20042** | 10 | constant_reg 10 | 0/0/0/0 | 0(0)，unread 0 | 无 | SUCCEEDED | 319 s |

两者：mode signoff-strict / vmucp true / merge_dup false / allowlist 0 / dont_verify_objects [] /
elab147 [] / relaxed_appvars [] / failing_truncated false / fm.log 行首 `Error:` 0 / impl_worktree_dirty false。
钉点：VL `MB_PREPIN_END n=2046 expect=2046`、`MB_PIN_END n=18807 impl_left=0`；
VS `MB_PREPIN_END n=1023 expect=1023`、`MB_PIN_END n=17584 impl_left=0`。§4 的三条「可能出错」都没发生。

## C. 复跑

```
cd /home/eda/xs-env/wt-vmergebuf
PROOF_COMMIT=0282c93b52b40ab85b16333244c1cb73d929494e bash scripts/run_proof.sh VMergeBuffer VSMergeBufferImp VLMergeBufferImp < /dev/null
python3 scripts/fm_predict.py check VLMergeBufferImp VSMergeBufferImp
cd verif/ut/VMergeBuffer && make run SEED=1 INITREG=+vcs+initreg+0     # 另 +vcs+initreg+random；SEED=7/42，串行
```

## D. UT（RTL 字节 = proof commit 的 rtl/，4d4e2363 起未再改 rtl；每档 200000 拍，两对同跑）

| seed | +vcs+initreg+0 | +vcs+initreg+random |
|---|---|---|
| 1  | checks=12744416 errors=0 TEST PASSED | checks=12744416 errors=0 TEST PASSED |
| 7  | checks=12649639 errors=0 TEST PASSED | checks=12649639 errors=0 TEST PASSED |
| 42 | checks=12728406 errors=0 TEST PASSED | checks=12728406 errors=0 TEST PASSED |

覆盖（seed 1，只数 golden 侧）：VL 写回 64450 / toLsq 46166 / 反馈 46166 / 带异常出队 7635（部分重放 0：
load 版 hit≡1，结构上不存在）；VS 写回 33838 / toLsq 24174 / 反馈 36874 / 部分重放 12700 / 带异常出队 4736。
两档 initreg 读数逐位相同：暖机把所有只在异常时写的条目字段写满，且 bits 只在 valid 时比较，
上电初值不再可观测 —— 按 CONVENTIONS，这意味着两档 UT **证明不了复位域**，复位域由 FM 全比较点
（含 16 条目控制位的异步复位）覆盖。
变异自检（seed 1，20k 拍，commit b1e89be4 的核）：selectOldest `<`→`<=` 抓到（16 errors）、出队口 0/1
互换抓到（318361）、unit-stride mask 偏移 +1 抓到（3236）、word 合并改成先到者胜抓到（73）；
fof 截断 `<`→`<=` 未抓到 —— 等价变异体（相等时两支取值相同）。
