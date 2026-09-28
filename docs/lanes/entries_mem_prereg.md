# Entries* 访存三变体 lane（agent/entries-mem）—— 跑前登记

本文件在**任何一次 FM 起跑之前**提交；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。对不上一律按 fail 报，不回头改预测。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（`git worktree add /home/eda/xs-env/wt-entries-mem -b agent/entries-mem 975b64e6`） |
| 目标 | `EntriesStaMou` / `EntriesVlduVstu` / `EntriesVlduVstuVseglduVsegstu`（新签）+ 共享核受影响的 38 个（重证） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（fm_predict 模型严格适用），allowlist 空，无 dont_verify，不加黑盒 |
| 依据 | `docs/lanes/entries-mem-coverage-judgment.md`（E1–E6）——本 lane 复核后照做，一个核、不开第二个 |

## 1. 核改动清单（E1–E6 逐条：哪些已在核里、哪些本 lane 新增）

| 条 | 状态 | 核里位置 | golden 依据 |
|---|---|---|---|
| E1 唤醒按源分份（kind × 每窗口 wen 存在性） | **已在核里**（29dd150a），本 lane 未动 | §1 MK_* / §2.2 `type_match` | Bundles.scala:325-348；EntryBundles.scala:185-193 |
| E2 当拍/入队延迟两窗口各一份对表 | **已在核里**（29dd150a），本 lane 未动 | `IQ_WEN_PRESENT`/`IQD_WEN_PRESENT` | EnqEntry_30.sv:1198 vs :1242 |
| E3 ld1Cancel / LD_PIPES / og0Resp_hasBits | 已有参数，不用动 | — | EnqEntry_24.sv:1218-1232 |
| E4 needFeedBack（阵列层访存响应） | **本 lane 新增** `MEM_RESP_MODE`（0/1/2）+ §5a | §5a | StaMou：EntriesStaMou.sv:19340-19349（`issueTimerRead[1] ? slowResp.valid & sqIdx== : ogTab`）；VecMem：EntriesVlduVstu.sv:21228-21260、:22966-22993（`&timer ? hit0|hit1|hit2 : ogTab`，★按位或★，sqIdx 与 lqIdx 同时相等） |
| E5 vecMem 状态组 + blocked 真逻辑 | **本 lane 新增** `HAS_VEC_MEM` | §2.6a（blocked 例外：三种条目都有，含 enq）/ §2.6c | EnqEntryVecMem_2.sv:908-920（寄存器）、:2017-2020（isVecPartReplay）、:2058-2062（blocked）、:2133-2141（装载，enq 清 mask/mbIdx）、:2398-2400（mask/mbIdx 只看 resp.isVecPartReplay）、:1475（★deqSuccess 带 `issued` 门控★）；OthersEntryVecMem_16.sv:886/:1092-1102 |
| E6 bypass2 分支 | 不需要，已从 §11 划掉并留行号 | §11(e) | EnqEntry_6.sv:2897-2902 / EnqEntry_24.sv:2359-2364 / EnqEntryVecMem_2.sv:2834-2837 |

判断文档 E4 一处更正：VecMem 的命中比的是条目的 **payload**.sqIdx/lqIdx
（`_enqEntries_0_io_commonOut_entry_bits_payload_sqIdx_flag`，EntriesVlduVstu.sv:21230），
不是 `status.vecMem`（两者入队值相同，但结构上是两组寄存器；FM 会分）。

★语义保持★：所有新增一律挂在 `HAS_VEC_MEM=0` / `MEM_RESP_MODE=0` 默认值后面：
新寄存器全部 `generate if`；已签核变体上新增的只有**组合**逻辑且输入钉常 0
（`deq_success & (~HAS_VEC_MEM | r_issued)`、`r_blocked <= load ? enq_blocked : u_blocked`，
`u_blocked = HAS_VEC_MEM & …` 恒 0）。xs_iq_entry 新增的 8 个输入在 OthersEntry*/EnqEntry*
两个生成器里钉 `'0`、8 个输出不接；14 个 Entries 薄层同样钉 0。

## 2. 预测

### 2.1 三个新目标（`python3 scripts/fm_predict.py model <t>`，登记 JSON 同 commit 进库）

| 目标 | 模型 expected（regs+outs） | 判据 |
|---|---|---|
| EntriesStaMou | **14530**（13082 + 1448） | 最终（vmucp 后）passing == expected − constant_reg；差额只许由 receipt 的 constant_reg 解释 |
| EntriesVlduVstu | **18570**（16762 + 1808） | 同上 |
| EntriesVlduVstuVseglduVsegstu | **18604**（16794 + 1810） | 同上 |

附带（信息性，非判据）预测：

- **constant_reg**：StaMou ≈ 14（同子族 Ldu/StdMoud 实测 14）；VlduVstu* ≈ 120–134
  （VEC 族 VfdivVidiv 128 / Vfma* 134；enq/simp 条目里 5 源 × 3 pipe × 2 位的
  srcLoadDependency 整条恒 0）。
- **首跑（vmucp 关）unread = matched_nc**：enq+simp 条目里「只为转移包存、发射口看不见」
  的负载 = (n_enq+n_simp) × (PL_TRANS_W − PL_DEQ_W)：StaMou 4×768 = **3072**，
  VlduVstu* 4×571 = **2284**（同子族 Ldu 实测比公式多 4，允许小额正偏）。
  unmatched 六项预测全 0（钉点：StaMou 12360 对，VlduVstu* 各 15224 对）。
- failing / unverified / aborted / unmatched：**0**。任一非零 = fail。

### 2.2 38 个受影响目标（重证）

预测：**全部 SUCCEEDED，passing 与各自最近一份 receipt 逐一相等**（语义保持，见 §1）。
旧值表（从 git 跟踪的最新 receipt 机械读出）：

| 目标 | 旧 passing | 旧 receipt |
|---|---|---|
| EnqEntry | 3618 | evidence/77833f567f84 |
| EnqEntry_10 | 3501 | evidence/77833f567f84 |
| EnqEntry_12 | 3496 | evidence/77833f567f84 |
| EnqEntry_14 | 3828 | evidence/77833f567f84 |
| EnqEntry_16 | 3766 | evidence/77833f567f84 |
| EnqEntry_18 | 3760 | evidence/77833f567f84 |
| EnqEntry_4 | 3638 | evidence/77833f567f84 |
| EnqEntry_6 | 3616 | evidence/77833f567f84 |
| EnqEntry_8 | 3509 | evidence/77833f567f84 |
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | 25300 | evidence/fc1f3cddb64e |
| EntriesAluCsrFenceDiv | 25001 | evidence/fc1f3cddb64e |
| EntriesAluMulBkuBrhJmp | 25010 | evidence/fc1f3cddb64e |
| EntriesFaluFcvtF2vFmacFdiv | 16619 | evidence/fc1f3cddb64e |
| EntriesFaluFmac | 15934 | evidence/fc1f3cddb64e |
| EntriesFaluFmacFdiv | 16549 | evidence/fc1f3cddb64e |
| EntriesLdu | 15151 | evidence/b30e47ce2c38 |
| EntriesStdMoud | 14039 | evidence/b30e47ce2c38 |
| EntriesVfdivVidiv | 12136 | evidence/fc1f3cddb64e |
| EntriesVfmaVialuFixVfalu | 18369 | evidence/fc1f3cddb64e |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 18755 | evidence/fc1f3cddb64e |
| OthersEntry | 3619 | evidence/563e6f964222 |
| OthersEntry_104 | 3520 | evidence/563e6f964222 |
| OthersEntry_106 | 1293 | evidence/563e6f964222 |
| OthersEntry_120 | 3516 | evidence/563e6f964222 |
| OthersEntry_122 | 1289 | evidence/563e6f964222 |
| OthersEntry_136 | 3859 | evidence/563e6f964222 |
| OthersEntry_138 | 1763 | evidence/563e6f964222 |
| OthersEntry_150 | 3797 | evidence/563e6f964222 |
| OthersEntry_152 | 1719 | evidence/563e6f964222 |
| OthersEntry_164 | 3792 | evidence/563e6f964222 |
| OthersEntry_166 | 1713 | evidence/563e6f964222 |
| OthersEntry_44 | 3639 | evidence/563e6f964222 |
| OthersEntry_50 | 1426 | evidence/563e6f964222 |
| OthersEntry_6 | 1394 | evidence/563e6f964222 |
| OthersEntry_66 | 3617 | evidence/563e6f964222 |
| OthersEntry_72 | 1394 | evidence/563e6f964222 |
| OthersEntry_88 | 3528 | evidence/563e6f964222 |
| OthersEntry_90 | 1301 | evidence/563e6f964222 |

任一不等 = 逐个说明（不是"解释一下就过"：不等说明新增组合逻辑没被常数传播吃干净，
或者钉 0 的端口在某个变体上其实有读者——两者都是要查的真问题）。

## 3. UT

UT（3 seed × `+vcs+initreg+random`/`+vcs+initreg+0` × 200k 拍，同一目标 seed 串行）
与三个新目标的首轮 FM 并行起跑（机器共享、FM 慢）；UT 不是预测项，结果与 FM 读数
一起记在文末「对账」。UT 任一档非零 = 先修 RTL，FM 重跑。

启跑时点：本文件所在 commit 之后才起第一个 FM。

---

## 对账（跑后追加；上方数字未改）

### A. 三个新目标

| 目标 | 首跑（impl 8c789148，vmucp 关） | 终跑（impl cfd09082，vmucp 开） | 模型 | 差额 = constant_reg |
|---|---|---|---|---|
| EntriesStaMou | native SUCCEEDED，passing 11440 / unread 3076（预测 3072，+4 与 Ldu 同形）/ failing 0 / unmatched 0 | **SUCCEEDED 14516**（恰 +3076），failing 0，unread 0，unmatched 0 | 14530 | 14 ✔ |
| EntriesVlduVstu | native SUCCEEDED，16162 / 2288（预测 2284，+4）/ 0 / 0 | **SUCCEEDED 18450**（+2288） | 18570 | 120 ✔ |
| EntriesVlduVstuVseglduVsegstu | native SUCCEEDED，16196 / 2288 / 0 / 0 | **SUCCEEDED 18484**（+2288） | 18604 | 120 ✔ |

constant_reg 预测（StaMou≈14 / VecMem≈120–134）落在带内。`fm_predict.py check` 41 个全部对上，rc=0。
首跑没有任何 failing —— 核改动一次到位，没有中途改核。

### B. 38 个重证（impl cfd09082，核字节与 5d2fbd21 相同）

38/38 SUCCEEDED，passing **逐一等于** §2.2 旧值（0 个不等），failing/unread/unmatched 全 0。

### C. UT（3 seed × 2 initreg × 200k，seed 串行，全部 errors=0 + TEST PASSED）

| 目标 | checks（seed 1 / 7 / 42，两档 initreg 各自相同） |
|---|---|
| EntriesStaMou | 26975700 / 26943300 / 26963685 |
| EntriesVlduVstu | 36389990 / 36390718 / 36390718 |
| EntriesVlduVstuVseglduVsegstu | 36794664 / 36785832 / 36792824 |

变异靶子：StaMou 12/12 适用行为型抓住（M12 在本变体是空变异，已更正判据）；
VlduVstu 5/5（M18–M22 全抓住，含 M19「按位或 vs 覆盖」errors=33）。
