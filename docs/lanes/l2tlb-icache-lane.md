# lane「L2TLB / ICache（/ OpenLLC 已判核外）」收工记录

分支 `agent/l2tmisc`，基线 main@`8910df43d1b98adad8c5d6eaf19d1e5caadfd621`。
**本分支没有改过任何 rtl/ 文件**：`git diff --name-only main...HEAD -- rtl/` 为空。
改的只有证明配置（UT Makefile / fm_target_config）、黑盒声明（verif/allow）、
一个只读对比工具（scripts/openllc_topology_diff.py）和证据。

全部 FM 读数钉在同一个 commit 上：

    76d345fc6c4fce999720466c539a8fa998db267e
    worktree_digest = 6d47dc66d1f21381ed505f97289b1276c2a7e116f438a0c38902451be4f6b52a
    证据目录 evidence/76d345fc6c4f/（8 个 target 同一 RUN_CONTEXT，可横向并列）

---

## 一、L2TLB（核内，共享 MMU 顶层）

复跑：`bash scripts/run_proof.sh L2TLB L2TLB`

| 量 | 打开 vmucp 前（07e6b07e） | 本轮（76d345fc） |
|---|---|---|
| native_verdict | SUCCEEDED | **SUCCEEDED** |
| passing | 28263 | **29072**（+809，与登记的预测逐个对上） |
| failing / unverified / aborted | 0 / 0 / 0 | **0 / 0 / 0** |
| unread_notcompared（matched） | 809 | **0** |
| unmatched compare (ref/impl) | 0 / 0 | **0 / 0** |
| unmatched **unread** (ref/impl) | 128 / 128 | 128 / 128 |
| mode | assembly | assembly |
| dont_verify / relaxed appvar / elab147 | 无 | 无 |
| **validator verdict** | PARTIAL | **PARTIAL** |
| 卡点 | `assembly_green_child_not_fm_target:Bitmap` | 同 |

**本层 glue 是证明了的**（29072 个比较点全过、零失配）。**卡点不在本层**：

1. 8 个带内部状态的大子模块在两侧对称 interface_only 黑盒
   （PtwCache / PTW / LLPTW / HPTW / L2TlbMissQueue / L2TlbPrefetch / Bitmap / BitmapCache），
   按 D57 每个都要持 `verif/proof_certificates/<target>.json` 背书。
   这 8 个**一个都没有重写**（impl 侧例化的就是 golden 子模块），
   其中 6 个连 FM target 都不是（没有任何 UT Makefile 的 FM_VARIANTS 声明它们），
   所以 validator 停在 `green_child_not_fm_target:Bitmap`。
   golden 规模：PtwCache 45308 行 / LLPTW 5293 / PMP 4408 / Bitmap 3349 / PTW 2036 /
   BitmapCache 940 / HPTW 545 / L2TlbPrefetch 214 / L2TlbMissQueue 133。
2. 剩余 128+128 个 unread 点是 `resp_pte_sector` 的 PTE 保留位
   （每个 64 bit PTE 的 bit 8/9，即 8,9,72,73,136,137,…,456,457），两侧都无读者：
       ref : r:/WORK/L2TLB/resp_pte_sector_r_<i>[_<j>]_reg[b]   （golden 展平成 17 个寄存器）
       impl: i:/WORK/L2TLB/u_core/resp_pte_sector_reg[i][b]     （可读核用打包数组）
   数量两侧相等、位下标集合相同，配不上是**命名形态差异**（正是本工程要的可读性改进）。
   要收掉需要给本目标写一份 `verif/ut/L2TLB/fm_map/L2TLB.txt` 字段映射；本轮没做。

vmucp 的打开依据与可复跑的双射判据写在 `verif/fm_target_config/L2TLB.tcl`。

UT：`make -C verif/ut/L2TLB run SEED=<s> INITREG=0`，seed 1/7/42 各 200000 拍

    seed 1  checks=200000 errors=0  a_fire=4961 d_fire=9922 tlb_req_fire=56201 tlb_resp=18700
    seed 7  checks=200000 errors=0  a_fire=5056 d_fire=10112 tlb_req_fire=55917 tlb_resp=18356
    seed 42 checks=200000 errors=0  a_fire=4886 d_fire=9772  tlb_req_fire=56432 tlb_resp=19197

---

## 二、ICache（核内，前端）

复跑：`bash scripts/run_proof.sh ICache ICache`

    native SUCCEEDED
    passing 10347 / failing 0 / unverified 0 / aborted 0 / unread_notcompared 0
    unmatched 全 0（compare/unread/bbout，ref 与 impl 都是 0）
    8 对对称 unresolved 黑盒；mode=assembly；无 dont_verify / relaxed appvar / elab147
    validator verdict = PARTIAL，reason = assembly_green_child_certificate_not_in_commit:ICacheCtrlUnit

本轮把缺的**声明**补上了（`verif/allow/ICache.json`，16 条 = 8 设计 × ref/impl），
判定理由因此从含糊的 `assembly_no_allow_decl` 变成指名道姓的"某个 child 没有证书"。

**顺手把 6 个 child 在同一 commit 上跑绿了**（各自是 306 universe 里的独立 target）：

| child | mode | passing | failing | unmatched | unread | verdict |
|---|---|---|---|---|---|---|
| ICacheCtrlUnit  | signoff-strict | 307  | 0 | 0 | 0 | SUCCEEDED |
| ICacheReplacer  | signoff-strict | 781  | 0 | 0 | 0 | SUCCEEDED |
| ICacheMetaArray | assembly       | 2500 | 0 | 0 | 0 | SUCCEEDED |
| ICacheMissUnit  | signoff-strict | 3215 | 0 | 0 | 0 | SUCCEEDED |
| WayLookup       | signoff-strict | 3633 | 0 | 0 | 0 | SUCCEEDED |
| ICacheDataArray | assembly       | 8237 | 0 | 0 | 0 | SUCCEEDED |

**剩下的缺口是真缺口，不是"跑一下就绿"**：

* `ICacheMainPipe`（golden 1532 行）与 `IPrefetchPipe`（golden 857 行）
  **在 rtl/ 下根本没有实现文件**，也没有 UT 目录。ICache 的 8 个黑盒少这两个就封不了口。
* 还有一道与 child 进度无关的**全局闸**：`verif/proof_certificates/POLICY.json` 的
  `freeze_commit` 是 `null`，而 `scripts/proof_certificate.py:669` 明写
  `if not fc: return 'green_child_policy_no_freeze_commit'`。
  也就是说 **在 integrator 于 freeze 时填上那个 40-hex commit 之前，
  任何带 green_child 边界的 assembly 父目标都不可能转绿**，跟 child 做到什么程度无关。
  这是 fail-closed 的设计（D57 第 5 条要求全部 child 在 freeze commit 上 clean 重跑后
  才生成证书），不是缺陷；但它意味着"把 ICache / L2TLB 收进 proven"这件事
  **不是任何一条 lane 在 freeze 之前能做到的**。所以本轮没有去铸证书 —— 在非 freeze
  commit 上铸出来的证书 `impl_commit != freeze_commit`，validator 照样拒。

UT：seed 1/7/42

    ICache          checks=200000  errors=0     （200000 拍）
    ICacheCtrlUnit  checks=3800000 errors=0 toggled=19/19 fires≈12.0e4
    ICacheMissUnit  checks≈4.79e6  errors=0 ncompare≈199800 x_skips=0
    ICacheMetaArray checks=199407  errors=0
    WayLookup       checks=60000   errors=0
    ICacheDataArray checks=28019   errors=0
    ICacheReplacer  checks=19999   errors=0

★诚实标注★：`ut_common.mk` 下发 `NCYCLES ?= 200000`，但 **ICacheReplacer /
ICacheDataArray / WayLookup 三个 tb 不读 `+ncycles`**（ut_common.mk 自己注释里
写明"tb 若不读 +ncycles 则该参数被忽略"），所以它们实际跑的是 tb 内置拍数
（分别约 2 万 / 2.8 万 / 6 万 check），**没有达到每 seed ≥ 100k 拍的标准**。
这三个 UT 要补 `+ncycles` 支持才算满足 CONVENTIONS。

---

## 三、OpenLLC —— **核外，本轮不做**

见 `docs/openllc_scope_note.md`。不是"没做完"：OpenLLC 例化在 XSTop
（`XSTop.sv:2210: OpenLLC chi_openllc_opt (`），不在 XSTile 闭包内，
按用户长期约束"核外面的文件不重写"排除在范围外，后续 lane 不必接。

本轮在范围裁定下来之前跑出的诊断保留备查（旧登记
`UNRUNNABLE_RESOURCE_LIMIT_CURRENT_HOST` 的**病因写错了**，真因是闭包里混进了厂商
SRAM 行为模型 `*_ext.v`）。改后的 FM 配置**没有跑完过**，不得据此声称任何 PASS。
