# uncore-queues lane（agent/uncore-queues）—— 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `1ce47a77a`（+ 认领 commit `777ed77e5`） |
| 工作树 | `/home/eda/xs-env/wt-uncore-queues`，分支 `agent/uncore-queues` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify / vmucp / fm_pins |

## 1. 结构

- 薄文件全部由 `scripts/gen_uncore_queues.py`（带 `--check`）从 golden 机械生成，fail-closed：golden 体每一行都须被
  认出、always 块与按（深度/指针名/pipe/flush/deq.ready 是否被折）重建的模板逐字相等、ram 例化 8 口逐个核对、
  W0_data（含常量段）推出的每个字段区间与出队切片逐位一致、无同名入队字段的出队切片必须落在常量段。
  负测（scratch 改 golden 副本，GOLDEN_RTL 指过去）：改切片 / enq_ready 加 pipe 项 / 改常量 / 改回卷常数 /
  加一行多余 wire / Pipeline 换连线 / ram R0_en 改接 —— 7 例全部 rc≠0；原样 rc=0。
- 控制核：
  - 普通 Queue（24 个）：已签共享核 `rtl/common/xs_ChiselQueue_core.sv`，**未改动**。
  - `Queue4_CHISNP`（pipe=true）：新增手写 `rtl/uncore/xs_ChiselQueuePipe_core.sv`（与上者同端口、多 pipe 语义）。
    不给已签核加 PIPE 参数，以免其 16+ 已签目标 STALE（同 L2TlbMissQueue.sv 头注理由）。
  - `Queue40_L2TlbMQBundle`（flush）：复用已签 `xs_L2TlbMissQueue_core`（rtl/memblock/L2TlbMissQueue.sv，**未改动**）。
  - `Pipeline_12/13`：只有一个 `stages_0` 例化，child = 已签 `Queue1_CHIDAT/Queue1_CHIRSP`（PROVEN_DIRECT），两侧白盒。
- ram 存储叶子：FM 目标里的 ram 全部 2 的幂深度（2/4/16），按 codex 0151 D60 两侧同源 inline，无黑盒。
  ★`Queue78_PCrdGranted`（ram_78x15）与 `Queue40_L2TlbMQBundle`（ram_40x47）深度非 2 的幂，FM 只能两侧对称黑盒，
  须 codex 新裁定（ram_78x15 未入表；ram_40x47 的已审定父级不含 Queue40_L2TlbMQBundle，0209 明言不自动传递）——
  **本轮不跑它们的 FM**，只做 RTL + UT。★

## 2. UT（三个目录；seed 1/7/42 × initreg 0 / random / <seed>017，各 200k 拍，串行）

| 目录 | 目标 | 每档读数 |
|---|---|---|
| verif/ut/UncoreTLQueues | 21 个 Queue2_TLBundle* | 9/9 `checks=43000000 errors=0 TEST PASSED` |
| verif/ut/UncoreChiQueues | Queue16_CHIREQ/CHIRSP、Queue4_CHISNP、Queue2_PCrdGranted、Queue78_PCrdGranted、Queue40_L2TlbMQBundle | 9/9 `checks=15000000 errors=0 TEST PASSED` |
| verif/ut/ChiRxPipelines | Pipeline_12/13 | 9/9 `errors=0 cov_fail=0 TEST PASSED`（checks 7799625 / seed 42 为 7799523，arm 后才比） |

覆盖闸（每目标）：满、入队、出队、同拍进出、满时被拒；Queue4_CHISNP 满时 pipe 直通入队；Queue78/Queue40 指针在
DEPTH-1 回卷（enq/deq 各 ~1000/~1800 次）；Queue40 非空 flush / flush 同拍入队；Pipeline 反压/同拍进出/满拒。
翻转闸：每个输出都要翻转，**除了**整段只读 ram 常量段的出队输出（由 gen_uncore_queues 解析现算）与
Queue2_TLBundleE_1.io_enq_ready（deq.ready 恒 1，永不满）——它们是否翻转只取决于 ram/寄存器初值。

变异自检（scratch 副本，不进库；seed 7、initreg 7017、20k 拍）：
B_1 常量 FFFFFFFF→FFFFFFFE errors=19999；A_6 param 切片错位 17516；去掉 pipe 61506；Queue40 flush 接 0 20820；
Pipeline_13 resp/fwdState 对调 34976；CHIRSP count 最高位置 0 4861；E_1 deq_ready 改接 20178 —— 全部抓到。

复跑：`cd verif/ut/<目录> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`；`python3 gen.py --check`。

## 3. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（merge_dup=false）。预期其余：failing 0 / unverified 0 / unmatched 0 /
unread 0（每个 ram 位都有出队端口读，生成器现算 0 个未读位）/ 无黑盒 / SUCCEEDED。

| 目标 | UT 目录 | passing 预测 |
|---|---|---|
| Queue2_TLBundleA_6 | UncoreTLQueues | **1073** (715 + 358) |
| Queue2_TLBundleA_7 | UncoreTLQueues | **1223** (815 + 408) |
| Queue2_TLBundleA_8 | UncoreTLQueues | **1082** (721 + 361) |
| Queue2_TLBundleA_10 | UncoreTLQueues | **356** (237 + 119) |
| Queue2_TLBundleA_12 | UncoreTLQueues | **404** (269 + 135) |
| Queue2_TLBundleA_14 | UncoreTLQueues | **413** (275 + 138) |
| Queue2_TLBundleA_15 | UncoreTLQueues | **353** (235 + 118) |
| Queue2_TLBundleA_19 | UncoreTLQueues | **362** (241 + 121) |
| Queue2_TLBundleA_31 | UncoreTLQueues | **416** (277 + 139) |
| Queue2_TLBundleB | UncoreTLQueues | **932** (621 + 311) |
| Queue2_TLBundleB_1 | UncoreTLQueues | **1061** (707 + 354) |
| Queue2_TLBundleC | UncoreTLQueues | **1124** (749 + 375) |
| Queue2_TLBundleC_1 | UncoreTLQueues | **968** (645 + 323) |
| Queue2_TLBundleD_7 | UncoreTLQueues | **848** (565 + 283) |
| Queue2_TLBundleD_8 | UncoreTLQueues | **857** (571 + 286) |
| Queue2_TLBundleD_11 | UncoreTLQueues | **245** (163 + 82) |
| Queue2_TLBundleD_13 | UncoreTLQueues | **233** (155 + 78) |
| Queue2_TLBundleD_15 | UncoreTLQueues | **242** (161 + 81) |
| Queue2_TLBundleD_20 | UncoreTLQueues | **854** (569 + 285) |
| Queue2_TLBundleE | UncoreTLQueues | **35** (23 + 12) |
| Queue2_TLBundleE_1 | UncoreTLQueues | **29** (19 + 10) |
| Queue16_CHIREQ | UncoreChiQueues | **2344** (2201 + 143) |
| Queue16_CHIRSP | UncoreChiQueues | **1069** (1001 + 68) |
| Queue4_CHISNP | UncoreChiQueues | **585** (465 + 120) |
| Queue2_PCrdGranted | UncoreChiQueues | **50** (33 + 17) |
| Pipeline_12 | ChiRxPipelines | **847** (423 + 424) |
| Pipeline_13 | ChiRxPipelines | **149** (74 + 75) |

### 明写可能出错的地方

1. 常量段 ram 位（如 Queue2_TLBundleA_7 的 257'h0、Queue16_CHIREQ 的 5 段 0）：两侧写入同一常量，FM 可能把它们判
   `constant_reg`（初值未知，预计不会）；若 passing 少，先核对 receipt 的 constant_reg 是否恰好等于差额。
2. 指针名不同（golden `wrap`/`enq_ptr_value`，impl `u_core/enq_ptr`），靠签名匹配；L2Queues 先例无需钉点。
3. Queue2_TLBundleE_1 无 io_deq_ready（恒 1），impl 把核的 deq_ready 接 1'b1；FM 应当常量传播后等价。
4. 本节之前没有做过任何 FM 试跑。

## 4. 对账（证明 commit `1fda02fae`，evidence/1fda02fae0f1，追加于跑后）

27/27 native SUCCEEDED，全部 failing 0 / unverified 0 / aborted 0 / unread_notcompared 0 / unmatched 全 0 /
无黑盒 / 无 dont_verify / 无 ELAB-147 / 无放宽 appvar。`python3 scripts/fm_predict.py check <27 个>` rc=0：

- 21 个逐位等于预测。
- 6 个差额全部 = receipt 的 constant_reg：Queue2_TLBundleA_7 −257、B_1 −43、C −53、D_20 −3、Queue16_CHIREQ −54、
  Queue16_CHIRSP −9。即 W0_data 常量段的 ram 位被 FM 判为常量寄存器、不产生比较点
  （每个常量位计 1，不随深度翻倍）。★§3「明写可能出错」第 1 条我写的是"预计不会"——这条判断错了，
  passing 数字照登记不改，差额由 constant_reg 逐位指认。★
- `scripts/check_lane_receipts.py /home/eda/xs-env/wt-uncore-queues` rc=0。

未跑 FM：Queue78_PCrdGranted、Queue40_L2TlbMQBundle（ram 边界待 codex 裁定，见 §1）。
