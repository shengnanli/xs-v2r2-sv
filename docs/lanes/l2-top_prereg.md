# l2-top lane（agent/l2-top）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `ce53b9176`（main 0af8e1726 + claim；worktree 由集成者预建） |
| 工作树 | `/home/eda/xs-env/wt-l2-top`，分支 `agent/l2-top` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `Prefetcher`、`TL2CHICoupledL2`、`L2Top`（自底向上） |
| 口径 | `FM_MERGE_DUP=false`（fm_predict 模型严格适用）；无 dont_verify；黑盒只许 verif/allow/<T>.json 逐对象声明 |

### 0.1 child 核实（`python3 scripts/coverage_three_axis.py` 在本 worktree 重算后读第 3 列；派生表本身未提交）

仓里的 `docs/coverage_three_axis.tsv` 是旧的（早于 l2-link / l2-mem-parents / uncore-queues 合并），重算后：
三个目标的 golden 闭包里每个 child 都是 `PROVEN_DIRECT`（含此前表里写 UNPROVEN 的 PBestOffsetPrefetch /
VBestOffsetPrefetch / LinkMonitor / MMIOBridge / Queue78_PCrdGranted / TLBuffer_13 / TLBuffer_15）。
child 一律两侧白盒：ref 读 golden，impl 读本仓重写件（不走 green_child 证书路线）。

## 1. Prefetcher（golden 521 行 / 69 端口；TL2CHICoupledL2.prefetcher）

### 1.1 结构

- `rtl/l2/Prefetcher.sv`（536 行）：手写胶合核 `xs_Prefetcher_core`（§1 使能、§2 训练过滤、§3 回填分发、§4 出口让路、
  §5 recv_addr 两拍延迟）+ golden 同名顶层（7 个 child，实例名同 golden）。`_GEN_` / `_T_` = 0。
- child（全部 PROVEN_DIRECT，两侧白盒）：PBestOffsetPrefetch、VBestOffsetPrefetch、PrefetchReceiver、MbistPipeL2Prefetcher、
  PrefetchQueue、Pipeline_1（含 Queue1_PrefetchReq）、Arbiter4_PrefetchReq。
- 黑盒：只有厂商 SRAM 叶子 `array_13_ext`（pbop / vbop 的 rrTable 各 1，两侧对称，vendor_boundary 已审定）→
  `verif/allow/Prefetcher.json`（由诊断跑 black_boxes.rpt 经 `scripts/declare_allow.py` 生成，4 个对象）。

### 1.2 UT（verif/ut/Prefetcher，gen.py 生成 tb；200k 拍，每拍比全部 17 个输出端口、173 位）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | armed 36089 / checks=2786487 errors=0 | 同左 | 同左 |
| 7  | armed 102086 / checks=1664538 errors=0 | 同左 | 同左 |
| 42 | armed 26096 / checks=2956368 errors=0 | 同左 | 同左 |

全部 cov_fail=0（每个输出位见过 0/1，豁免只有 vbop 的 TLB 请求常量字段；另 13 个覆盖计数各 ≥5）。
arm = pbop / vbop 内部不复位寄存器各自第一次被写（沿用两个 child UT 的 arm 条件）+ pipe 第一次出数；
arm 前不比。arm 点三档 initreg 相同（arm 条件只看 golden，与初值无关）。
变异（scratchpad 脚本，seed 42 initreg 0、60k 拍，不进库）7/9 被抓：去训练过滤 errors=154884；vbop ready 恒 1 49988；
pbop 不让 vbop 9156；recv_addr 只延 1 拍 123198；第 2 级数据锁存使能错接 36330；vbop 使能不看 master 3573；
pfRcv 使能只延 1 拍 71185。未抓 2 个：回填分发 PBOP/BOP 互换（resp 只影响 BOP 打分的时机，60k 拍内输出不可分）、
pfRcv_en 复位值 1→0（只影响复位后 2 拍内恰好有 recv_addr 的情形）——两者都改变寄存器次态 / child 输入函数，
由 FM（merge_dup=false 逐寄存器比较）覆盖。
复跑：`cd verif/ut/Prefetcher && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`
（UT 跑完后 rtl/l2/Prefetcher.sv 只改过一行注释：「文件导航」→「本文件导航」，可读性闸 E 类要求的字样。）

### 1.3 跑前预测（★跑完不许改本节★，docs/fm_predictions/Prefetcher.json）

模型 expected = **9301**（`python3 scripts/fm_predict.py model Prefetcher`）。

诊断跑（`make fm-Prefetcher FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，关 vmucp、带 884 位 child 钉点，未出证）：
native SUCCEEDED，passing **8325** / failing 0 / unmatched compare 0；unread = matched-unread **900**（pbop/vbop 内 884 +
vbop s1_newFullAddr 6 + mbistPl addrReg 9 / addrRdReg 1）+ 两侧各 **76** 位 unmatched-unread（recv_addr 延迟 44、
pftQueue valids_0..30 31、mbistPl beReg 1）。8325 + 900 + 76 = 9301 = 模型。

正式跑配置：钉点 960 位（`scripts/gen_prefetcher_pins.py`，884 + 76）+ vmucp 开（`verif/fm_target_config/Prefetcher.tcl` 六条证据）。

| 目标 | passing 预测 | 其余 |
|---|---|---|
| Prefetcher | **9301** | failing 0 / unverified 0 / aborted 0 / unmatched 全 0 / unread 0 / 黑盒 = allow 声明的 4 个 array_13_ext / 无 dont_verify / SUCCEEDED |

## 9. 对账（跑后追加；以上各节数字未改）

| 目标 | receipt | 预测 passing | 实测 passing | 差 | 指认 | 其余 | 判决 |
|---|---|---|---|---|---|---|---|
| Prefetcher | evidence/16617425bad6/Prefetcher（receipt.json sha256 `023beefc97a0addac8383d5c47fea95598788fae3e7ae6779408b85e8e4ad026`） | 9301 | 9301 | 0 | — | failing 0 / unverified 0 / aborted 0 / unmatched 0(0) / unread 0（matched_unread_notcompared 0、unmatched_unread 0）/ 黑盒 = array_13_ext 两侧各 2（allow 声明）/ dont_verify [] / elab147 [] / relaxed_appvars [] / 钉点 ok=960 bad=0 / 418 s | **SUCCEEDED** |

`python3 scripts/fm_predict.py check Prefetcher` rc=0（逐位相等）。
复跑：`bash scripts/run_proof.sh Prefetcher Prefetcher < /dev/null`（PROOF_COMMIT=16617425b）。

## 2. TL2CHICoupledL2（golden 7663 行 / 324 端口；L2Top.inner_l2cache）—— FM 待 codex 扩授权

### 2.1 结构

- `rtl/uncore/TL2CHICoupledL2.sv`（7310 行）：手写胶合核 `xs_TL2CHICoupledL2_core`（约 380 行：§1 hint 引导 D 放行、§2 预取
  bank 分发与训练地址补 bank、§3 B/ECC 地址补 bank、§4 perf/l2Miss、§5 TXREQ 一致性门控与 txnID 编码、§6 RXSNP 分发、
  §7 RXRSP/RXDAT 分发与 txnID 还原、§8 P-Credit）+ golden 同名 wrapper（32 个 child，实例名同 golden；
  `scripts/gen_tl2chi.py` 生成，规则实现 `scripts/parent_wrapper_lib.py`，fail-closed，带 `--check`）。`_GEN_` / `_T_` = 0。
- child：32 个实例（含 Slice×4、MMIOBridge、Prefetcher、LinkMonitor、L2Cache、MbistIntfL2、Queue78/Queue2_PCrdGranted、
  Pipeline_2/3/10/11/12/13、FastArbiter/_1/_26/_27/_28、RRArbiterInit_20、Arbiter4_*、TopDownMonitor），闭包 176 个 golden 模块，
  全部 PROVEN_DIRECT，两侧白盒（impl 167 个 rtl 文件）。
- 两侧共读 golden 的只有行为级存储模型（ram_* / sram_array_* / array_N，22 个文件）与本地 ClockGate。
- FM 两侧对称黑盒：厂商叶子 array_13..18_ext（vendor_boundary 已审定）+ **ram_10x89 ×4（slices_<k>/grantBuf/pftRespQueue/ram_ext）
  + ram_78x15 ×1（pCrdQueue_s2/ram_ext）——这两个 APPROVED_MEMORY_MACRO_MODEL 的授权父级不含本目标，需 codex 逐父级扩授权，
  本 lane 未声明 allow、未跑正式 FM。**
- 钉点：`scripts/gen_tl2chi_pins.py` → `verif/ut/TL2CHICoupledL2/fm_pins_pre.tcl`（4 个 Slice 变体各 29381 + Prefetcher 960 =
  118484 位，全部是已签件钉点只换层次前缀）。

### 2.2 UT（verif/ut/TL2CHICoupledL2，gen_tb.py 生成 tb；200k 拍，每拍比全部 324 端口里的输出）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=33198224 errors=0 | 同左 | 同左 |
| 7  | checks=33198242 errors=0 | 同左 | 同左 |
| 42 | checks=33198356 errors=0 | 同左 | 同左 |

9 档 cover_zero=0（必需覆盖项全非 0；必需 arm 组 CHI TX req/rsp/dat flit 全 arm）。seed 1 initreg 0 覆盖：hint 457、
slice0/3 D 放行 3979/3914、D 被 hint 挡住 22、A 收下 979、B 发出 70、TXREQ 可缓存 1480 / MMIO 355 / 被一致性挡住 53、
TXDAT 610、TXRSP 2149、RXRSP 到 slice 1875 / 到 MMIO 855、RXDAT 到 slice 2419 / 到 MMIO 103、PCrdGrant 入队 5026、
P-Credit 授出 64、MMIO D 184、预取请求到 slice 322、预取 train 432、ECC error 1404、topDown MissMatch 11246。
只打印不计入：releaseSourceD 0、L2 TLB 请求 0（vbop 学不出偏移；TLB req bits 组不比，由 Prefetcher UT 与 FM 覆盖）。
初值同步表从 Slice / MMIOBridge / L2Cache 的 UT tb 机械收割 + 本层 3 个队列存储体。
跑法：`make compile` 产出的同一个 simv，3 个 seed 各拷一份并行（与 `make run SEED=<s> INITREG=<x>` 同参数）。
复跑：`cd verif/ut/TL2CHICoupledL2 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

变异（20k 拍，seed 1 initreg 0）14 个抓 9：allCanFire 链深度 345、D ready 不门控 325、预取 slice 选择位 267110、ECC 地址不补 bank 19991、
P-Credit 不比 srcID 320704、perf 少一拍 14164、coEnable 不看 syscoack 3922、hint ready 恒 1 40、l2Miss 或改与 18618。
未抓 5：hint 不查 DCache source（tb 的 source 都 < 36）、训练 set 不补 bank（只改 BOP 内部学习，20k 拍不外显）、
txnID 的 MMIO 位改按 chosen==4（与 mmioFire 在 out.valid 时可能等价）、RXRSP ready 去掉 PCrdGrant 项（slice / MMIO 的 rsp ready
在本配置恒 1，功能等价）、txnID 还原保留 slice 号（slice 只用低位）——由 FM 判定（等价则无害、不等价必报）。

### 2.3 FM 诊断跑（diagnostic-full，不出证；在 fd55d88e0 的 detached worktree 里跑，未登记）

带 118484 位钉点（`TL2_PIN_END ok=118484 bad=0`），vmucp 关。黑盒恰为 8 类（array_13..18_ext 与 ram_10x89 / ram_78x15，两侧对称）。
**匹配不完整**：matched by user 98392 / by name 120402 / by signature 0 / by topology 816；**unmatched compare 25051(25050)**、
unmatched unread 17831(17832)。unmatched 主体：slices_<k>/mshrCtl 的 16 个 MSHR（每 slice ≈4.5k 位，impl 在
`slices_<k>/u_core/mshrCtl/u_core/mshrs[..]`）、prefetcher/pftQueue、vbop reqFilter / scoreTable、pbop/vbop delayQueue。
成因（读 scripts/fm_eq.tcl 的 auto_match_flattened_arrays 得出）：它只剥掉**顶层**的 `u_core/` 再按展平名配对，child 单独签核时这些
数组寄存器正是靠它自动配上的；进了父级后路径是 `slices_<k>/u_core/...`，规则不再命中，签名分析在这个规模下也一个没配上。
匹配不完整导致下游数据寄存器（releaseBuf buffer、txreq/txrsp 队列存储等）成批"failing"——是匹配伪影还是真差异，**未判定**
（已停掉该诊断跑：25051 个未配对点下 verify 跑完无意义）。下一步：钉点生成器再收割 child 签核时的全部配对（不只是钉点文件），
或把父级实例前缀纳入自动配对（fm_eq.tcl 是共享脚本，须集成者 / codex 同意）。
UT 9 档 errors=0 是目前对本层胶合逻辑的唯一正面证据。

## 3. L2Top（golden 3779 行 / 382 端口；XSTile.l2top）—— FM 待 codex 扩授权

### 3.1 结构

- `rtl/l2/L2Top.sv`（3503 行）：手写核 `xs_L2Top_core`（约 140 行：§1 MSI / halt / critical error / L3 miss 打拍、§2 trace 接口打拍与
  条件锁存、§3 hartIsInReset、§4 BEU 的 L2 ECC 地址补位）+ golden 同名 wrapper（21 个 child，实例名同 golden；`scripts/gen_l2top.py`，
  共用 parent_wrapper_lib，`--check`）。`_GEN_` / `_T_` = 0。
- child：TL2CHICoupledL2（本 lane）、TLBuffer_13/15×3/20×2/22/6/8×2、TLXbar_5/6、TLLogger/_1/_2、BusErrorUnit、BusPerfMonitor、
  IntBuffer、DelayN_334、DelayNWithValid_203；闭包 221 个 golden 模块，除 TL2CHICoupledL2 外全部 PROVEN_DIRECT，两侧白盒（impl 203 个 rtl 文件）。
- FM 对称黑盒与 TL2CHICoupledL2 相同（路径多一层 inner_l2cache/），**同样需要 ram_10x89 ×4 / ram_78x15 ×1 对父级 L2Top 扩授权**；
  另 L2Top 自己的 ram_2x* / ram_sink_2x8 全是 2 的幂深度，两侧同源白盒，不需要授权。钉点同 TL2（前缀 inner_l2cache/，118484 位）。
- 依赖：L2Top 的正式 FM 还要等 TL2CHICoupledL2 签核（它是 L2Top 的 child）。

### 3.2 UT（verif/ut/L2Top，gen_tb.py 复用 TL2 tb 骨架；200k 拍，每拍比全部 382 端口里的输出）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=40598236 errors=0 | 同左 | 同左 |
| 7  | checks=40598350 errors=0 | 同左 | 同左 |
| 42 | checks=40598170 errors=0 | 同左 | 同左 |

9 档 cover_zero=0。seed 1 initreg 0 覆盖：hint 128、D 被 hint 挡住 17、TXREQ 可缓存 980 / MMIO 208 / 被一致性挡住 34、TXDAT 89、
TXRSP 1108、RXRSP 到 slice 1275 / MMIO 671、RXDAT 到 slice 1607 / MMIO 110、PCrdGrant 5024、P-Credit 授出 51、预取请求 153、
DCache A 413 / D 846 / B 31、ICache D 409、PTW D 318、外部 MMIO A 106、trace trap 锁存 28357、hartIsInReset 3109。
（第一版 tb 在 random / <seed>017 档有 3~6 个前几拍的失配：trap_cause/tval、msiInfo bits、clintTime bits 这些只在使能时锁存、
不复位的寄存器上电值两侧不同——tb 补了初值同步后 9 档全 0，RTL 未改。）
变异（20k 拍）8 个抓 7：critical error 复位值 1、trap 不看 itype、priv 无条件锁存、hartIsInReset 复位 0、MSI bits 无条件锁存、
iaddr/ilastsize 用第 0 组 valid、l3Miss 接错；未抓：BEU 的 L2 错误地址错位（只进 BEU 内部寄存器，经 TL 读口才外显）→ FM 覆盖。
复跑：`cd verif/ut/L2Top && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`
