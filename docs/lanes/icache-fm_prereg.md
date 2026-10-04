# ICache FM 收敛 lane（agent/icache-fm）—— 跑前登记

本文件在 official FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `dbbec84e`（含 fe-mem-misc 的 ICache 现场 `5a9a9e10d`）；main 后续到 `cdb0e122` 只改 2 个与 ICache 闭包无关的文件，未合入 |
| 工作树 | `/home/eda/xs-env/wt-icache-fm`，分支 `agent/icache-fm` |
| 目标 | `ICache`（assembly，signoff-strict 判定，merge_dup 默认 true，vmucp 白名单在册） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| RTL 改动 | **无**（rtl/ 与 child 重写件一字未动；8 个 child 的既有 receipt 继续有效） |

## 1. 根因

1. 前 lane 诊断 3 的阻塞（failing 808 / unmatched 24 impl）：golden ICacheMainPipe 给 MSHR 的请求是
   `blkPaddr = {s2_req_ptags_p, s2_req_vaddr_p[11:6]}`、`vSetIdx = s2_req_vaddr_p[13:6]`，两字段低 6 位是**同一组
   vaddr 位**，经 Arbiter2 / ICache 顶层 / fetchDemux 原样直通进 4 格取指 MSHR，同拍同使能写入 ⇒ 每格
   `blkPaddr[5:0] ≡ vSetIdx[5:0]`。golden 与重写件**都保留了这两份寄存器**（重写件 `blk_paddr_q` / `vset_idx_q`，
   与 golden 同构，不存在“重写件合并了 golden 副本”的问题）。差别只在 FM：merge_dup 下 ref 侧在
   `fetchMSHRs_<n>` 块里把 vSetIdx[5:0] 并进 blkPaddr[5:0]，impl 侧不并 ⇒ 24 个 impl 寄存器无对家、成自由状态，
   MSHR 命中 / 分配链连带 808 failing（预取 MSHR 的命中比较也读取指 MSHR，所以全 MSHR 阵列都红）。
2. merge_dup=false 的 8117 failing 是另一回事（MainPipe 里 golden 有 RegNext(s0_fire)×21 等恒等副本、
   重写件各一份），与 child ICacheMainPipe 单独签核同口径用 merge 开即可消，本 lane 不走 merge 关。

## 2. 方向选择与已排除路径

- **(a) bug-for-bug 结构对齐：不适用。** 冲突点上重写件与 golden 寄存器数相同（每格各一份 blkPaddr、vSetIdx）。
  唯一结构差是重写件 14 格 MSHR 共用一个核设计（golden 是 14 个单例模块）。**已实测排除**：给
  `xs_ICacheMSHR_core` 加 `MSHR_ID` 参数让 14 格展开成 14 个独立设计（FM 日志确认 14 个不同 design 名），
  诊断跑 1 读数**一字不变**（passing 20342 / failing 808 / unmatched 24），impl 侧仍无
  "Merging duplicated registers in block .../fetchMSHRs_n/u_core"。该改动已回滚（未提交；补丁留在 scratch
  `icache-fm/mshr_id_attempt.patch`），child 文件因此不需重证。期间 ICacheMSHR / ICacheMissUnit UT 9 档对该
  试验版本全绿（仅作记录）。
- **(b) 钉点精确绑定 merge 代表点：采用。** `scripts/gen_icache_pins.py` 对取指 MSHR 的 vSetIdx[5:0] 改钉
  ref `blkPaddr_reg[b]`（一对多：ref 代表点同时配 impl `blk_paddr_q[b]` 与 `vset_idx_q[b]`）。Formality 手册
  （set_user_match）："One reference design object may be matched with more than one implementation design
  object. In that case, each implementation object is verified against the reference object." —— impl 两份
  都要证明等于 golden，不约束 ref、不放宽 appvar、不 dont_verify、不扩黑盒。同源关系由生成器从 golden
  机械复核（MainPipe 两个口的位片、顶层直连、fetchDemux 四个出口直通、MSHR 接线），任何一处变了就拒绝生成。
- 诊断跑 2（一对多钉点后）：passing 21154 / failing 0 / unmatched 0 / native SUCCEEDED，verdict PARTIAL 只因
  两侧各 20 个 unmatched unread（名字不同的对称死位）：
  - `ctrlUnitOpt/out_back_q/ram_reg[53..68]` ↔ `slot_reg\[data][48..63]`（RegMapper 队列 data[63:48]，
    ICacheCtrlUnit 只读 data[47:0]；与 child ICacheCtrlUnit 自己的 fm_pins.tcl 同一组 16 位）；
  - `dataArray/res{,_1,_2,_3}/beReg_reg` ↔ `.../u_core/beReg_reg[0]`（MBIST 写使能锁存，父级不读）。
  追加进 post 钉点（33 → 53），由 vmucp 真比较。

## 3. 跑前预测（★跑完不许改本节★）

| 项 | 预测 |
|---|---|
| verdict | SUCCEEDED（assembly，official `scripts/run_proof.sh ICache ICache`） |
| passing | **21174** = 诊断跑 2 的 21154 + 20 个新钉死位（vmucp 打开后进入比较） |
| failing / unverified / aborted / unmatched | 0 / 0 / 0 / 0 |
| unread | 0 |
| 钉点 | `ICACHE_PRE_PIN_END ok=740 bad=0`、`ICACHE_POST_PIN_END ok=53 bad=0`；无 "Ignoring user match" |
| 黑盒 | 仅 allow 声明的 array_ext / array_0_ext（两侧各 36，共 72）；dont_verify / elab147 / relaxed_appvars 空 |

`fm_predict.py model ICache` = 21228（regs 15040 + outs 3380），merge_dup=true ⇒ 模型不适用；差额来源 = ref 侧
merge 掉的恒等寄存器（MainPipe RegNext 副本、取指 MSHR vSetIdx[5:0] 等）与 vmucp/端口计数口径，登记在
`docs/fm_predictions/ICache.json` 的 note 里。

明写可能出错的地方：一对多匹配可能让 FM 把 impl 第二个点计成独立比较点，passing 可能比 21174 多（至多 +24）；
若出现，属计数口径，failing 仍须 0。

## 4. UT

无 RTL 改动，沿用 fe-mem-misc 读数（verif/ut/ICache 9 档全绿，每档 checks=196999）；本 lane 复跑见对账。
