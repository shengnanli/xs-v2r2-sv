# iq-entry-leaves lane（agent/iq-entry-leaves）—— 跑前登记

本文件在 **FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `041221e7`（claim 提交），worktree `/home/eda/xs-env/wt-iq-entry-leaves` |
| 重写 commit | `ddb13c86` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标（19） | EnqEntry_20/24/30、EnqEntryVecMem/_2、OthersEntry_172/174/200/202/242/244、OthersEntryVecMem/_2/_14/_16、EnqPolicy/_8/_14/_18 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无 vmucp |

## 1. 15 个单条目（EnqEntry* / OthersEntry*）

### 1.1 做法：复用共享核，**核一个字节没改**

- 核 = `rtl/backend/xs_iq_entries_core.sv` 的 `xs_iq_entry`（`check_shared_impl_impact.py --file` 该文件被 59 份 receipt
  共用；本 lane diff 为空，故无重证义务）。
- 这 15 个的父级（EntriesLdu/StaMou/StdMoud/VlduVstu/VlduVstuVseglduVsegstu）都已用同一个核签核，
  核里访存族维度（ld1Cancel、needFeedBack、HAS_VEC_MEM 组）早已实现。缺的只是**生成器**：
  - `enqentry_gen.py` 的 `IMPLEMENTED_PARENTS` 是陈旧白名单（写于这些父级尚未签核时），补上 5 个父级；
  - 两个生成器原先对访存向量变体 `assert not has_vec_mem`。接线表新写在
    `verif/ut/Entries_common/entry_vecmem.py`（status.vecMem 打包顺序与 `Entries_common/gen_fm_pins.vm_layout` 同一张表），
    钉点生成器同步加 r_vm/r_vpr/r_vr_mask/r_vr_mbidx；
  - EnqEntryVecMem 的 enq 口有 `status.blocked` 输入（访存向量 blocked 有真次态），原断言放宽为「仅访存向量允许」。
- 与已签变体的维度差（全部由生成器从 golden 端口表机械量出、与父级 Variant 逐项断言一致）：
  | 目标 | 父级/角色 | 源 | WB/IQ 唤醒 | 新维度 |
  |---|---|---|---|---|
  | EnqEntry_20 / OthersEntry_172 / _174 | StaMou enq/simp/comp | 1 | 4 / 7 | ld1+ld2Cancel×3、regcache |
  | EnqEntry_24 / OthersEntry_200 / _202 | Ldu | 1 | 4 / 7 | 同上，IQ 自身是 load 流水 |
  | EnqEntry_30 / OthersEntry_242 / _244 | StdMoud | 1 | 10 / 7 | IQ 当拍/延迟窗口 wen 集合不同（5'b00001 vs 5'b00011） |
  | EnqEntryVecMem / OthersEntryVecMem / _2 | VlduVstuVseglduVsegstu | 5 | 16 / 0 | HAS_VEC_MEM、blocked 真次态 |
  | EnqEntryVecMem_2 / OthersEntryVecMem_14 / _16 | VlduVstu | 5 | 16 / 0 | 同上 |
- 子模块：StaMou/Ldu/StdMoud 的 golden 条目内含 `UIntCompressor_27_000011100000000000001010101`（纯组合 exuSources 压缩），
  与同族已签变体同一处置：ref 侧 golden 白盒，impl 侧核内展平，无黑盒。VecMem 与 EnqPolicy 0 child。
- 已知坑核对：Mux1H 非 one-hot 按位或（M1 变异抓住）、srcLoadTransCancel 用 WithoutCancel（M2 抓住）、
  replaceRC 比 currentStatus —— 都在核里，本 lane 不碰。

### 1.2 本 lane 抓到的 tb 缺陷（不是 RTL 缺陷）

访存族 WB 总线**一路同时带 rfWen/fpWen/vecWen**，tb 只驱动其中一个，其余停在上电初值：
`+vcs+initreg+0` 下恒 0，那一类源整轮不被 WB 唤醒 —— 首轮 9 档里 ir0 档 `wb_wake` 塌到 ~700（< 下限 3996），
errors 恒 0。是覆盖闸把它拦下来的（「errors=0 但覆盖红」）。修法：同一路的其余 wen 字段一并随机驱动
（生成器改动对已签 33 个变体输出逐字节不变）。修后 OthersEntry_202 seed1 ir0 wb_wake 675→11580。

### 1.3 UT（首轮，修 tb 后；最终版在 commit 上重跑，结果追加在对账节）

9 档 = seed 1/7/42 × `+vcs+initreg+0` / `+random` / `+<seed>017`，各 200k 拍。15 个目标 135 次全部 `TEST PASSED`
（errors=0 且全部覆盖闸达标）。访存向量 4 个新覆盖桶按「族内最小 / 4」标定
（vec_blocked / vec_unblocked_vleff / vec_part_replay / vec_replay_mask_upd）。

变异自检（临时拷贝，仓内 RTL 不动）：
- `OthersEntry_common/mutants.py`：OthersEntry_172 14/14、OthersEntry_200 14/14、OthersEntryVecMem_14 10/10、
  OthersEntryVecMem_16 9/9 行为型全部抓住（含访存向量 M20/M21/M22）；结构型 M13/M15 UT 按构造看不见，闸在 FM。
  （D2 锚点原写 r_src_state，核早已改 cur_src_state，锚点失效；本 lane 跟上。）
- wrapper 新接线专属：W1 EnqEntryVecMem_2 enq_blocked 钉 0 → errors=1509；W2 lqDeqPtr.flag 钉 0 → errors=6483；
  W3 OthersEntryVecMem_14 enq_vpr 钉 0 → errors=69601。全部抓住。

### 1.4 跑前预测（★跑完不许改本节★；登记 docs/fm_predictions/*.json）

| 目标 | passing 预测（regs + outs） | 钉点 |
|---|---|---|
| EnqEntry_20 | **3453** (1392+2061) | 1380 |
| EnqEntry_24 | **3534** (1411+2123) | |
| EnqEntry_30 | **3396** (1380+2016) | |
| EnqEntryVecMem | **3940** (1502+2438) | |
| EnqEntryVecMem_2 | **3934** (1500+2434) | 1488 |
| OthersEntry_172 | **3454** (1392+2062) | |
| OthersEntry_174 | **1292** (623+669) | |
| OthersEntry_200 | **3535** (1411+2124) | |
| OthersEntry_202 | **1378** (666+712) | 651 |
| OthersEntry_242 | **3397** (1380+2017) | |
| OthersEntry_244 | **1226** (590+636) | |
| OthersEntryVecMem | **3940** (1501+2439) | 1483 |
| OthersEntryVecMem_2 | **1835** (899+936) | 881 |
| OthersEntryVecMem_14 | **3934** (1499+2435) | 1483 |
| OthersEntryVecMem_16 | **1831** (897+934) | 881 |

其余全部预测：failing 0 / unverified 0 / unmatched 0 / unread 0 / 黑盒 0 / dont_verify 无 / SUCCEEDED。
钉点计数字面写死在各 `fm_pins_pre.tcl`（fail-closed）。

### 1.5 明写可能出错的地方

1. 访存向量 r_vm 打包顺序若与 vm_layout 不一致，FM 会把 sqIdx/lqIdx 钉错对 → failing（不会被掩盖）。
2. comp 访存向量条目（OthersEntryVecMem_2/_16）numDeq=1 且无 transEntry：r_deq_port_idx 不应生成（核 §2.6a）；
   若 golden 侧却有该寄存器会出 unmatched。
3. StdMoud 的 IQ 延迟窗口 wen 集合与当拍不同（已按窗口分份），若 enq 条目在 FM 失败先看 IQD_WEN_PRESENT。
4. 若出现 passing 少于预测：先查 constant_reg（例如某状态位在单条目上恒常数被 FM 当常量），再查 unread。

## 2. EnqPolicy / _8 / _14 / _18

- 手写核 `rtl/backend/xs_EnqPolicy_core.sv`（W 参数化，纯组合）；4 个薄 wrapper 由 `scripts/gen_enqpolicy.py`（带 `--check`）
  生成，家族成员从 golden 机械发现并断言端口形状 / 0 寄存器 / 0 子模块。
- 语义：口 0 = 最低位空槽（valid=≥1）；口 1 = 最高位空槽（valid=≥2，bits 不被 valid 门控）—— Chisel `SelectOne("circ")` 的 n=1/n=2。
- UT `verif/ut/EnqPolicy`（四对同测）：W≤16 的三个前 2^W 拍穷举，W=22 五种形态随机；首轮 9 档全 PASSED。
  变异：P1 口1 valid 改成 ≥1 → errors=155930；P2 口1 漏扫 bit0 → 12226；P3 口0 valid 漏 bit0 → 12226。全部抓住。
- 预测：EnqPolicy **46** / _8 **34** / _14 **30** / _18 **18**（全为 output 位，0 寄存器）；其余全 0，SUCCEEDED。

## 3. 签后父级影响（只列，不做）

见对账节。

## 4. 追加登记（首跑后、重跑前；★以上各节数字未改★）

首跑（PROOF_COMMIT `cc6120772`）17/19 SUCCEEDED；OthersEntryVecMem / _14 两个访存向量 simp 为
**PARTIAL（strict_unread=15）**：native SUCCEEDED、passing 3925 / 3919、failing 0、unmatched 0、黑盒 0，
15 个 unread 全部 matched_nc、ref 15 ↔ impl 15 严格双射，正是钉点钉上的 `r_ld_dep_reg[s][q][1]`
（影子 bit[1]，本族无 ldCancel ⇒ 两侧同为纯写入死位，与已在白名单的 OthersEntry_164/_150/_136 同因同型）。

处置 = vmucp standing rule（六条）：`verif/fm_target_config/OthersEntryVecMem{,_14}.tcl` + Makefile
`FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=true`（由生成器 VMUCP 表产出）。
**重跑预测**：OthersEntryVecMem 3925 → **3940**、OthersEntryVecMem_14 3919 → **3934**（恰好 +15，
等于已登记的模型值），unread 0 / failing 0 / unmatched 0 / 无 dont_verify / 无新黑盒。

## 5. 对账（跑后追加）

### 5.1 UT（最终版，在 commit `ddb13c86` 字节上重跑；9 档 × 200k 拍）

16 个 UT 目录（15 单条目 + EnqPolicy 四对同测）× 9 档 = 144 次，**144/144 TEST PASSED**（errors=0、覆盖闸全部达标，
含新标定的 4 个访存向量桶）。复跑：`verif/ut/<T>` 下 `make simv && ./simv +ntb_random_seed=<1|7|42> +ncycles=200000 +vcs+initreg+<0|random|<seed>017>`。

### 5.2 FM（signoff-strict，全部 native SUCCEEDED，failing/unmatched/黑盒 0，无 dont_verify）

| 目标 | 预测 | 实测 passing | 差 | 指认 |
|---|---|---|---|---|
| EnqEntry_20 | 3453 | 3452 | −1 | constant_reg 1 = entryReg_status_deqPortIdx（numDeq=1，入队清 0、次态恒 0，两侧同为常数；golden EnqEntry_20.sv:1910） |
| EnqEntry_24 | 3534 | 3533 | −1 | 同上 |
| EnqEntry_30 | 3396 | 3395 | −1 | 同上 |
| EnqEntryVecMem | 3940 | 3909 | −31 | constant_reg 31 = deqPortIdx 1 + srcLoadDependency 影子 5 源×3 流水×2 位 = 30（本族 enq 口无该输入，装载 2'h0、次态左移仍 0；golden EnqEntryVecMem_2.sv:2089-2091 / :2359） |
| EnqEntryVecMem_2 | 3934 | 3903 | −31 | 同上 |
| OthersEntry_172 / _174 / _200 / _202 / _242 / _244 | 3454/1292/3535/1378/3397/1226 | 同 | 0 | — |
| OthersEntryVecMem_2 / _16 | 1835/1831 | 同 | 0 | — |
| OthersEntryVecMem / _14 | 3940/3934 | 首跑 3925/3919 + unread 15（PARTIAL）→ vmucp 后 **3940/3934** | 0 | 恰好 +15，见 §4 |
| EnqPolicy / _8 / _14 / _18 | 46/34/30/18 | 同 | 0 | — |

`fm_predict.py check` 19/19「全部对上」（差额全部被 constant_reg 指认）；`check_lane_receipts.py` rc=0。
★本节如实记一处跑前判断错误★：§1.4 写「预测差额 0」，而 EnqEntry 访存族 5 个实际有常数寄存器 —— 模型本来就
把常数寄存器算在 regs 里，差额由工具的 constant_reg 指认，没有指认不了的部分。

### 5.3 父级影响（只列，不做）

14 个 Entries* 父级的**直接子模块现已全部 PROVEN**（本 lane 签的 + 早已签的），孙级 UIntCompressor_27_* 也都是 PROVEN_DIRECT：
- 本 lane 补齐最后缺口的 5 个访存父级：EntriesLdu、EntriesStaMou、EntriesStdMoud、EntriesVlduVstu、EntriesVlduVstuVseglduVsegstu
  （四个直接子模块全是本 lane 新签）；
- 只缺 EnqPolicy* 的 9 个：EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v / AluCsrFenceDiv / AluMulBkuBrhJmp（EnqPolicy）、
  EntriesFaluFcvtF2vFmacFdiv / FaluFmacFdiv / FaluFmac（EnqPolicy_8）、EntriesVfdivVidiv（EnqPolicy_18）、
  EntriesVfmaVialuFixVfalu / VfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf（EnqPolicy_14）。
