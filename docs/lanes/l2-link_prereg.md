# l2-link lane（agent/l2-link）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `2139ff76c`（main 上 claim commit；worktree 由集成者预建） |
| 工作树 | `/home/eda/xs-env/wt-l2-link`，分支 `agent/l2-link` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `LCredit2Decoupled_1`（LinkMonitor 的 child）、`TLBuffer_15`、`TLBuffer_13`、`LinkMonitor` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（fm_predict 模型严格适用），allowlist 空，无 dont_verify |

### 0.1 为什么这几个目标此前没有有效 receipt（查明）

- `docs/receipt_harvest.tsv`：`LCredit2Decoupled_1` / `LinkMonitor` 只有 wt-chi 的 `4a19d583a6ce`/`40ec7fc36bb8`、
  `TLBuffer_13` 只有 wt-mismatch 的 `3e9c6f419205`/`d0d4d30f8bc4`，全标 SUPERSEDED、从未进库
  （harvest 判"台账里已有绿判决、多余一轮"，但那个台账判决来自上一轮，本仓 evidence/ 里一份也没有）。
- `verif/ut/TLBuffer_13/Makefile` 最后一次改动把 `FM_MODE=assembly` 改回 strict、ram 改 inline，
  注释自认"★未经 FM 重跑验证"。
- 三者 impl 侧都直接读 golden 子模块（`RTL_GOLDEN_DEPS` 里的 Queue2_* / LCredit2Decoupled_* 等），
  于是 child 在 `coverage_three_axis` 里记 GOLDEN_REUSE。现在这些 child 都已有本仓重写件并签核
  （Queue2_* / Queue4_CHISNP：evidence/1fda02fae0f1；Decoupled2LCredit{,_1,_2} / LCredit2Decoupled：
  evidence/40ec7fc36bb8；LCredit2Decoupled_2：evidence/2f9bb8a2b814），本 lane 改为**两侧白盒**：
  ref 读 golden，impl 读重写件。只有 ram_* 行为级叶子两侧同源 inline（不是黑盒）。

## 1. LCredit2Decoupled_1（golden 192 行 / 22 端口；LinkMonitor 的 RXRSP 接收端）

### 1.1 结构

- `rtl/uncore/LCredit2Decoupled_1.sv`（commit `4f860869e`）：按已签 `LCredit2Decoupled_2` 的样式重写——
  package（CHIRSP flit 结构体）+ 手写核 `xs_LCredit2Decoupled_1_core`（L-Credit 两计数器 + lcrdv 打拍 + 解包/吞 LCrdReturn）
  + golden 同名薄 wrapper。0 子模块、0 黑盒。`_GEN_`/`_T_` = 0。

### 1.2 UT（verif/ut/LCredit2Decoupled_1，gen.py 生成 tb；200k 拍，每拍比全部 76 个输出位）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=3199872 errors=0 | checks=3199872 errors=0 | checks=3199872 errors=0 |
| 7  | checks=3199872 errors=0 | checks=3199872 errors=0 | checks=3199872 errors=0 |
| 42 | checks=3199872 errors=0 | checks=3199872 errors=0 | checks=3199872 errors=0 |

全部 cov_fail=0（每个输出位见过 0/1 + 6 个覆盖计数）。seed 1 覆盖：lcrdv 86290、rsp_out 47374、
LCrdReturn 被吞 22910、同拍发+收 41736、池耗尽 58412、reclaim 10640。
变异（scratchpad，20k 拍，不进库）4/4 被抓：去 out_ready 门控 errors=4007；不吞 LCrdReturn 2173；
池复位 14 errors=1；同拍抵消破坏 5928。

复跑：`cd verif/ut/LCredit2Decoupled_1 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，docs/fm_predictions/LCredit2Decoupled_1.json）

| 目标 | passing 预测 | 其余 |
|---|---|---|
| LCredit2Decoupled_1 | **87**（寄存器 11 = 5+5+1；输出 76） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |

依据：同构的 LCredit2Decoupled_2 实测 436 = 11 + 425 输出位。无 vmucp、无 fm_pins。没有做过任何 FM 试跑。

## 2. TLBuffer_15（golden 189 行 / 46 端口；L2Top inner_i_mmio_buffer / inner_buffers / inner_buffers_1）

### 2.1 结构与子模块处置

- 新文件 `rtl/memblock/TLBuffer_15.sv`（commit 见 git log）：设参例化**已签共享核** `xs_TLBuffer_ad_core`
  （SOURCE_W=1、ADDR_W=48、DATA_W=64、MASK_W=8、A/D_SIZE_W=2、D_SINK_W=1、A_USER_W=2、A_RAM_WIDTH=133、D_RAM_WIDTH=76；
  **核未改一字节**），A/D 各接一个 Queue2。端口表/连线首稿用 `gen_tlbuffer_ad_family.py` 的 Variant/gen_rtl
  现读 golden 生成（该生成器本身不改、VARIANTS 不加：它的 tb 覆盖闸按 source>=8 设计，不适用 1 位 source），
  文件头手写。`_GEN_`/`_T_` = 0。
- child：Queue2_TLBundleA_12 / Queue2_TLBundleD_13 —— 已签（evidence/1fda02fae0f1，各 SUCCEEDED 404 / 233）。
  **两侧白盒**：ref = golden 同名件，impl = `rtl/uncore/Queue2_TLBundle{A_12,D_13}.sv` + `rtl/common/xs_ChiselQueue_core.sv`。
  ram_2x133 / ram_2x76 两侧读同一份 golden 文件（2^1 == 2 项，无 ELAB-147 越界问题）。无黑盒。

### 2.2 UT（verif/ut/TLBuffer_15，gen.py 生成；200k 拍，每拍比全部 213 个输出位）

arm：ram 无复位、deq_bits 空队列时也读 ram[deq_ptr]，故 A/D 各在 ptr=0/1 上入队过一次才开始比（armed_at 12~16 拍）。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=4399648 errors=0 | checks=4399648 errors=0 | checks=4399648 errors=0 |
| 7  | checks=4399736 errors=0 | checks=4399736 errors=0 | checks=4399736 errors=0 |
| 42 | checks=4399670 errors=0 | checks=4399670 errors=0 | checks=4399670 errors=0 |

全部 cov_fail=0。seed 1 覆盖：A 入/出 77993/77987、D 入/出 77830/77821、A/D 满反压 35308/34989、同拍进出 30527/30327。
变异 3/3 被抓（20k 拍）：user NC/MM 交叉 errors=9917；D sink 接成 source 10058；D 出口 ready 恒 1 27329。

复跑：`cd verif/ut/TLBuffer_15 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 2.3 跑前预测（★跑完不许改本节★）

| 目标 | passing 预测 | 其余 |
|---|---|---|
| TLBuffer_15 | **637**（寄存器 424 = A: 2x133+3 / D: 2x76+3；输出 213） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |

交叉核对：两个 child 单独签核实测 404 = 269+135、233 = 155+78，与本模型逐项一致。没有做过任何 FM 试跑。

## 3. TLBuffer_13（golden 917 行 / 374 端口；L2Top.inner_buffer，4 路 TL-C 五通道缓冲）

### 3.1 结构与子模块处置

- `rtl/memblock/TLBuffer_13.sv` 重写（旧件 1911 行：pkg 结构体 + core 复述全部 374 端口 + wrapper 再复述一遍，
  注释指向本仓没有的 xs-v2r2-sv 生成器、impl 读 golden Queue2）→ 新件 1047 行：
  手写 `xs_TLBuffer_13_bank`（一条 TL-C 链路的 5 个 Queue2，例化名同 golden bank 0）+
  `scripts/gen_tlbuffer13.py`（带 `--check`，fail-closed：4 bank 端口集合相同、手写 bank 端口表与之逐项相等、
  每个 golden 端口恰连一次）生成的 golden 同名 wrapper（4 个 `u_bank_<b>`）。`_GEN_`/`_T_` = 0。
- child：Queue2_TLBundle{A_19,B_1,C_1,D_20,E_1} 均已签（evidence/1fda02fae0f1：362 / 1018 / 968 / 851 / 29）。
  **两侧白盒**：ref = golden 同名件，impl = `rtl/uncore/` 重写件 + `rtl/common/xs_ChiselQueue_core.sv`。
  ram_2x119 / 2x352 / 2x321 / 2x283 / ram_sink_2x8 两侧同源 inline（2 项 / 1 位地址）。无黑盒。
- 名差：golden 20 个队列平铺（`nodeOut_a_q`、`nodeOut_a_q_1`…），impl 是 `u_bank_<b>/nodeOut_a_q`。
  不加 fm_pins，靠 FM 名字/签名匹配（上一轮 g_bank[N].u_bank 形态实测 0 unmatched）。

### 3.2 UT（verif/ut/TLBuffer_13，gen.py 生成；200k 拍，每拍比全部输出）

arm：20 个队列各在 ptr=0/1 入队过一次才开始比（40 个条件，armed_at≈21 拍）。
覆盖闸豁免（结构上恒定）：B 出口 size/source/mask/corrupt、D 出口 size（golden 写 ram 的常量位）、
E 入口 ready（E 出口 ready 恒 1，2 项队列满不了）——各 ×4 bank。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=36796136 errors=0 | checks=36796136 errors=0 | checks=36796136 errors=0 |
| 7  | checks=36797240 errors=0 | checks=36797240 errors=0 | checks=36797240 errors=0 |
| 42 | checks=36796688 errors=0 | checks=36796688 errors=0 | checks=36796688 errors=0 |

全部 cov_fail=0。seed 1 bank0 覆盖：A/B/C/D 满反压 23499/23425/23161/23624，同拍进出 33655/33127/33133/33264，E 同拍进出 57652。
变异 3/3 被抓（20k 拍）：bank1/2 A valid 串线 errors=127489；B address 接成 data 79916；D echo 接成 denied 39730。

复跑：`cd verif/ut/TLBuffer_13 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 3.3 跑前预测（★跑完不许改本节★）

| 目标 | 模型 expected | 预期 constant_reg | 预期实测 passing | 其余 |
|---|---|---|---|---|
| TLBuffer_13 | **13096**（寄存器 8724 + 输出 4372） | **184** = 4 × (B_1 的 43 + D_20 的 3) | **12912** | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |

依据：B_1 / D_20 单独签核 receipt 里 constant_reg 分别为 43 / 3（golden 写 ram 的常量位）；12912 也与旧 Makefile 注释里
上一轮 merge=false 的实测数一致。若 constant_reg 不是 184，差额按 bank×队列逐项指认。没有做过任何 FM 试跑。
