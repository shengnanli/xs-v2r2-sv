# mmuleaf lane（agent/mmuleaf）—— 跑前登记

本文件在每个目标 **官方 FM（run_proof.sh）起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `d5564588`（main，`git worktree add /home/eda/xs-env/wt-mmuleaf -b agent/mmuleaf main`） |
| 工作树 | `/home/eda/xs-env/wt-mmuleaf`，分支 `agent/mmuleaf` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标（按顺序） | `StreamBitVectorArray` → `PrefetchFilter` → `TLB` → `PTWFilterEntry` → `PMP` |
| 冲突检查 | codex outbox 最新 0205（next-20 叶，均不含本 lane 目标）；claude_0204 第 6 批认领表把本 5 个目标划给 mmuleaf；codex/* 与 kimi/k3-next20 分支 diff 无本 lane 目标文件 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| 钉点生成器 | `scripts/gen_mmuleaf.py`（带 `--check`；golden 顶层寄存器逐位 set_user_match，规则表 fail-closed、单射、字面计数） |

## 1. StreamBitVectorArray（golden 2,803 行 / 0 child）

### 1.1 结构

- 设计源 `L1StreamPrefetcher.scala` class StreamBitVectorArray。可读核 `rtl/memblock/StreamBitVectorArray.sv`
  （package streambitvectorarray_pkg + xs_StreamBitVectorArray_core + golden 同名 wrapper），495 行，代码区 `_GEN_`/`_T_` = 0，
  readability_audit rc=0。golden 2,803 行。
- 表项 generate 块 `array[i]`（tag/bit_vec/active/cnt + 每项一份 RegNext(flush) `last_REG`）；PLRU 用共享辅助件
  `rtl/common/xs_PlruReplacer.sv`（golden 内联为 state_reg，状态编码与 rocket-chip PseudoLRU 一致）。
- 配置折掉的东西：io.flush（上层接 0，wrapper 给核接 1'b0）、decr_mode（ENABLE_DECR_MODE=false）、L3 预取 valid
  （enableL3StreamPrefetch=false，但 s5 载荷寄存器仍在且出现在 l2_l3 bits 上）、动态深度（USE_STREAM_FIXED_DEPTH）。
- golden-only 结构照抄：3 个断言打拍寄存器、s2_region_tag（性能计数器）、预取地址低 6 位、两份同值的 s3 valid。
- 无子模块、无黑盒。

### 1.2 UT（verif/ut/StreamBitVectorArray；3 seed × 3 档初值 × 200k 拍，串行，commit cfd0ad0d 字节）

逐拍比全部 11 根输出（118 位）；bits 在 golden 第一次发出后才开始比（不复位寄存器直接驱动，见 tb 头注释）。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=1796886 errors=0 PASS | checks=1796886 errors=0 PASS | (1017) checks=1796886 errors=0 PASS |
| 7  | checks=1799674 errors=0 PASS | checks=1799674 errors=0 PASS | (7017) checks=1799674 errors=0 PASS |
| 42 | checks=1799374 errors=0 PASS | checks=1799374 errors=0 PASS | (42017) checks=1799374 errors=0 PASS |

checks 按「每拍每根输出一次」计（约 9 次/拍）。覆盖（seed 1，各档相同）：alloc 47747 / update 66276 / 邻区激活 alloc 1665 /
L1 预取 12098 / L2 预取 12098 / 反压 5659 / 查询命中活跃 10178 / 哈希冲突 275；任一类为 0 即判 FAILED。
（seed 1 × random 档按 CONVENTIONS 实为全 1 档。）

变异自检（scratchpad，seed 1 +0，40k 拍）：14 个里 13 个 CAUGHT（哈希去一段异或 / 阈值 >= 改 > / cnt 无条件加 / 去 strict 触发 /
L2 宽度 / 去反压 / 邻区不查 cnt / 忽略 enable / sink 常量 / 查询不读 active / update 清 active / L1 深度 63 / -1 邻区写成 +1）。
存活 M5（OHToUInt 的「按位 OR」改成「取最后一个」）：表项哈希两两不同（入表去重 + s1 反压），可达状态下匹配向量恒为独热，
观测等价；FM 覆盖（组合逻辑结构比对）。

复跑：`cd verif/ut/StreamBitVectorArray && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`；`python3 scripts/gen_mmuleaf.py --check`。

### 1.3 lane 内非正式试跑（diagnostic-full，不出证）

1. 关 vmucp（commit cfd0ad0d）：native SUCCEEDED，passing 1475 / failing 0 / unmatched 全 0 / constant_reg 16，
   unread 319 全部 matched_nc（钉点 `SBVA_PIN_END ok=1692 bad=0`）；五族见 `verif/fm_target_config/StreamBitVectorArray.tcl`。
2. 开 vmucp：native SUCCEEDED，passing **1794**，unread_points 空。

### 1.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/StreamBitVectorArray.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **1810**（regs 1692 + outs 118）；实测预计 **1794**，差 16 由 receipt `constant_reg`=16 指认（last_REG/last_REG_1..15 = 每项一份 RegNext(io.flush)，flush 恒 0） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`SBVA_PIN_END … ok=1692 bad=0`） |
| 黑盒 | 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

可能出错的地方：诊断跑与官方跑只差 mode 与 detached worktree 路径；钉点路径若在 detached worktree 下格式不同会 error 早退
（表现为 FM 早退而非数字偏离）。

---

# 对账（跑完追加；上文各节未改一字）

## A. StreamBitVectorArray

| 项 | 值 |
|---|---|
| 跑前登记 / proof commit | `05a6fe8428263daba7de64638186ac82f4e55eb1`（登记与证明同一 commit） |
| 证据目录 | `evidence/05a6fe842826/StreamBitVectorArray/` |
| receipt sha256 | `ffdead3bd2de23b24d7894ed1d53f8a25aa7cef2cc16a8c389dc07424ab17bc4` |
| impl_closure | `rtl/memblock/StreamBitVectorArray.sv` f0385cee…bcca / `rtl/common/xs_PlruReplacer.sv` bf422014…3709 |

| 预测 | 实测 passing | 差 | 指认 | failing/unverified/aborted/unread_nc | unmatched 六项 | 黑盒 | verdict |
|---|---|---|---|---|---|---|---|
| 1810（预计实测 1794） | 1794 | 16 | constant_reg 16 | 0/0/0/0 | 全 0（`SBVA_PIN_END ok=1692 bad=0`） | 无 | SUCCEEDED |

`fm_predict.py check StreamBitVectorArray` → 「全部对上」rc=0。mode signoff-strict / vmucp true / merge_dup false / allowlist 0 /
dont_verify 无 / impl_worktree_dirty false / failing_truncated false。

复跑：`PROOF_COMMIT=05a6fe8428263daba7de64638186ac82f4e55eb1 bash scripts/run_proof.sh StreamBitVectorArray StreamBitVectorArray < /dev/null`

---

## 2. PrefetchFilter（golden 3,252 行 / child RRArbiterInit_5、RRArbiterInit_6）

### 2.1 结构

- 设计源 `SMSPrefetcher.scala` class PrefetchFilter（SMS 的预取请求过滤表，16 项）。可读核 `rtl/memblock/PrefetchFilter.sv`
  （prefetchfilter_pkg + xs_PrefetchFilter_core + golden 同名 wrapper），代码区 `_GEN_`/`_T_` = 0，readability_audit rc=0。
- 表项 generate 块 `entries[i]`（region_tag/region_addr/region_bits/filter_bits/paddr_valid/decr_mode）；PLRU 用共享辅助件
  `xs_PlruReplacer`；两个仲裁器的例化连线在 GENERATED 区，由 `scripts/gen_mmuleaf.py` 按 golden 子模块端口表逐口认领生成。
- 配置折掉的：alias_bits / debug_source_type（无出口，golden 已删）；TLB 请求 bits 除 vaddr 外全常量（寄存器仍在）。
  GatedValidRegNext 写成普通 RegNext（功能等价）。
- child 处置：RRArbiterInit_5 / _6 均 PROVEN_DIRECT，两侧白盒（ref golden 同名件，impl rtl/common 重写件 + 家族核 RRArbiterInit.sv）。无黑盒。

### 2.2 UT（verif/ut/PrefetchFilter；3 seed × 3 档初值 × 200k 拍，串行，commit 5cb5b16e 的 RTL 字节）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=3398572 errors=0 PASS | checks=3398572 errors=0 PASS | (1017) checks=3398572 errors=0 PASS |
| 7  | checks=3397221 errors=0 PASS | checks=3397221 errors=0 PASS | (7017) checks=3397221 errors=0 PASS |
| 42 | checks=3390823 errors=0 PASS | checks=3390823 errors=0 PASS | (42017) checks=3390823 errors=0 PASS |

覆盖（seed 1）：alloc 37956 / update 43547 / 去重丢弃 9330 / TLB 请求 23219 / 回填成功 16252 / 作废 3465 / 撤销 TLB 请求 6 /
L2 预取 行号偶 70639、奇 70343；任一类为 0 即 FAILED。（tb 只改过覆盖计数的注释措辞，激励与比较未动。）

变异自检（scratchpad，seed 1 +0，40k 拍；M6 另以 200k 拍复跑）：13 个里 12 个 CAUGHT。M6（去掉"撤销 TLB 请求"）40k 拍内该事件
未出现，只被覆盖闸判红（errors=1 = 覆盖不足，不算真抓到），200k 复跑出现 6 处 io_tlb_req_req_valid 真失配，计为 CAUGHT。
存活 M8（alloc 分支加 `& ~update`）：同一拍同一项不可能既 alloc 又 update（s1_hit 二选一），观测等价。

### 2.3 lane 内非正式试跑（diagnostic-full，不出证）

1. 关 vmucp（commit 5cb5b16e）：native SUCCEEDED，passing 2022 / failing 0 / unmatched 全 0 / constant_reg 0，unread 10 全部 matched_nc
   （`PFF_PIN_END ok=1792 bad=0`）= s3_tlb_resp_paddr_0[9:0]。
2. 开 vmucp：native SUCCEEDED，passing **2032**，unread_points 空。

### 2.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/PrefetchFilter.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **2032**（regs 1800 = 顶层 1792 + 两仲裁器 lastGrant 4+4；outs 232）；实测预计 **2032**，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`PFF_PIN_END … ok=1792 bad=0`） |
| 黑盒 | 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

# 对账 B. PrefetchFilter（跑完追加；§2 未改一字）

| 项 | 值 |
|---|---|
| 跑前登记 / proof commit | `0eb94b233e9db3934327ee6f7e1ff7e220794a3d`（登记与证明同一 commit） |
| 证据目录 | `evidence/0eb94b233e9d/PrefetchFilter/` |
| receipt sha256 | `aad0e7d5e11e10edd79d3ca0ba456cd5588d31e04e38b6b373ebefb3f89ea181` |

| 预测 | 实测 passing | 差 | failing/unverified/aborted/unread_nc | unmatched 六项 | 黑盒 | verdict |
|---|---|---|---|---|---|---|
| 2032（预计实测 2032） | 2032 | 0 | 0/0/0/0 | 全 0（`PFF_PIN_END ok=1792 bad=0`） | 无（2 仲裁器两侧白盒） | SUCCEEDED |

`fm_predict.py check PrefetchFilter` → 「全部对上」。mode signoff-strict / vmucp true / merge_dup false / allowlist 0 / dont_verify 无 /
impl_worktree_dirty false。复跑：`PROOF_COMMIT=0eb94b233e9db3934327ee6f7e1ff7e220794a3d bash scripts/run_proof.sh PrefetchFilter PrefetchFilter < /dev/null`

---

## 3. TLB（前端 itlb；golden 2,929 行 / child DelayN_9、DelayN_7、TlbStorageWrapper(→TLBFA)）

### 3.1 结构与"是哪一个 TLB"

- golden `TLB` 只有一个实例：Frontend.inner_itlb（Chisel `new TLB(itlbPortNum=3, nRespDups=1, Block=Seq(false,false,true), itlbParams)`）。
  它与 dtlb 的 TLBNonBlock{,_1,_2}（本仓 xs_TLBNonBlock_core，只做非阻塞）不是同一模块：itlb 有一条阻塞口（handle_block）、
  取指专用（cmd 恒 exec、imode、无 hyperinst/hlvx/fullva/robIdx/req_kill，故无前置故障、need_gpa 由 flushPipe 清、canGetGpa 恒真）。
  `TLB_*` 变体在 golden 里不存在（只有 TLBFA_*/TLBNonBlock_*/TLBuffer_* 等别的模块族）。
- 可读核 `rtl/memblock/TLB.sv`（itlb_pkg + xs_TLB_core + golden 同名 wrapper），1,339 行，代码区 `_GEN_`/`_T_` = 0，readability_audit rc=0。
  共享包 tlbnb_pkg（hit()/genPPN() 等）与 dtlb 共用；wrapper 的端口表、三个子模块连线、PTW 响应打包、输出展平在 GENERATED 区
  （`scripts/gen_mmuleaf.py`，逐口认领 fail-closed）。
- child 处置：DelayN_9 / DelayN_7 / TlbStorageWrapper / TLBFA 均 PROVEN_DIRECT，两侧白盒（ref golden 同名件，impl 本仓重写件：
  xs_DelayN_core + DelayN_7/9、xs_TlbStorageWrapper_core + TlbStorageWrapper、xs_TLBFA_core + TLBFA）。无黑盒、无厂商宏。

### 3.2 UT（verif/ut/TLB，tb 由 gen_tb.py 生成；3 seed × 3 档初值 × 200k 拍，串行，commit 0003e61b 的 RTL 字节）

逐拍比全部 43 根输出（1514 位；gpaddr 另门控见 tb 头）。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=8389252 errors=0 PASS | checks=8389252 errors=0 PASS | (1017) checks=8389252 errors=0 PASS |
| 7  | checks=8421738 errors=0 PASS | checks=8421738 errors=0 PASS | (7017) checks=8421738 errors=0 PASS |
| 42 | checks=8470263 errors=0 PASS | checks=8470263 errors=0 PASS | (42017) checks=8470263 errors=0 PASS |

覆盖（seed 1）：命中 81410/81585/57911、miss 2914/2900/3677、PTW 请求 2262/2234/1393、阻塞口 PTW 直出 1195、flushPipe 回 pf 1310、
need_gpa 进入 1229、getGpa 往返完成态 14441 拍、pf 106374 / gpf 16912 / af 21462；任一类为 0 即 FAILED。

变异自检（scratchpad，seed 1 +0，30k 拍）：13 个里 11 个 CAUGHT。存活 2 个：M4（去掉 ptw_already_back：要求 PTW 响应回来的
下一拍同页请求仍在 miss，本激励下罕见）、M8（阻塞口挂起期间 sfence/satp 变化时重发 PTW 请求）。两处都是组合/寄存器次态的
结构差异，由 FM 覆盖。

### 3.3 lane 内非正式试跑（diagnostic-full，不出证）

1. 不钉点、关 vmucp（commit 0003e61b）：native SUCCEEDED，passing 11023 / failing 0 / unmatched compare 0，
   unread = 95(95) **unmatched** unread（子模块内部 itlb 不读的位，两侧名字不同；四族见 verif/fm_target_config/TLB.tcl）。
2. 加匹配后钉点 `verif/ut/TLB/fm_pins.tcl`（95 对，生成器现读 DelayN 载荷拼接偏移，fail-closed）+ vmucp：
   `TLB_PIN_END ok=95 bad=0`，native SUCCEEDED，passing **11118**，unread_points 空。

### 3.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/TLB.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **11118**（regs 9604 + outs 1514）；实测预计 **11118**，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`TLB_PIN_END … ok=95 bad=0`） |
| 黑盒 | 无（3 个子模块两侧白盒） |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

## 4. PTWFilterEntry（golden 3,256 行 / 0 child）

### 4.1 结构

- 设计源 `Repeater.scala` class PTWFilterEntry，本实例 = PTWNewFilter.load_filter（Width=4、Size=16、hasHint）。
  可读核 `rtl/memblock/PTWFilterEntry.sv`（xs_PTWFilterEntry_core + golden 同名 wrapper），361 行，代码区 `_GEN_`/`_T_` = 0。
  wrapper 端口表与 PTW 响应命中键打包在 GENERATED 区（gen_mmuleaf.py）。PTWFilterEntry_1（store/prefetch 两张表）不在本 lane。
- firstValidIndex 的"后写者胜"= 取下标最大项；同拍更低 lane 同页 → 借用其 id/canenq（链式）；memidx 被删；
  inflight_counter（只喂 perf/assert）照抄。无子模块、无黑盒。

### 4.2 UT（verif/ut/PTWFilterEntry；3 seed × 3 档初值 × 200k 拍，串行，commit 64e843bb 的 RTL 字节）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=2998665 errors=0 PASS | checks=2998665 errors=0 PASS | (1017) checks=2998665 errors=0 PASS |
| 7  | checks=2997915 errors=0 PASS | checks=2997915 errors=0 PASS | (7017) checks=2997915 errors=0 PASS |
| 42 | checks=2997075 errors=0 PASS | checks=2997075 errors=0 PASS | (42017) checks=2997075 errors=0 PASS |

覆盖（seed 1）：入表 87889 / 已在表 47201 / 同拍同页 10480 / 响应同页 13489 / 分区满 148409 / 发出 104119 / refill 81330 /
replay_all 6166 / getGpa 21194 / rob_head 68421。

### 4.3 lane 内非正式试跑（diagnostic-full，不出证）

1. 关 vmucp（commit 64e843bb）：native SUCCEEDED，passing 753，unread 4 = matched_nc（inflight_counter，按名配上）。
2. 开 vmucp：native SUCCEEDED，passing **757**，unread_points 空。

### 4.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/PTWFilterEntry.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **757**（regs 692 + outs 65）；实测预计 **757**，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0 / 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

## 5. PMP（golden 4,408 行 / 0 child）

### 5.1 结构与"谁在复用 golden"

- 设计源 `backend/fu/PMP.scala` class PMP（分布式 PMP/PMA 表副本：72 个 CSR 写入口 → 32 项 PMP + 32 项 PMA）。
  可读核 `rtl/memblock/PMP.sv`（pmp_pkg + xs_PMP_core + golden 同名 wrapper），1,240 行（含 487 行端口表与 448 行输出展平生成区），
  代码区 `_GEN_`/`_T_` = 0。
- 复用方：唯一一处 —— **L2TLB**（`verif/ut/L2TLB/Makefile` 把 golden `PMP.sv` 放在 RTL_GOLDEN_DEPS，impl 侧
  `rtl/memblock/L2TLB.sv` 的 `PMP u_pmp` 直接例化 golden 模块，两侧同源展开；L2TLB 的 vmucp 依据里 809 个 pmaMapping_* 死位
  就是靠"两侧同名"配上的）。改用重写件后 L2TLB 按 STALE 规则须重证，见文末对账里的处置。
- ★FM 抓出、UT 不可达的一处★：mask 有两个写者（addr CSR 写 / cfg CSR 写 NAPOT 重算），可达状态下不会同拍，但 golden 的
  when 链次序来自 Scala Map 的哈希遍历序、逐项不同；FM 比全部状态组合下的次态函数，第一版"addr 恒优先"在 2460 个比较点失败。
  现由 gen_mmuleaf.py 按 golden wen_reg 生成序号逐项算出 ADDR_WRITE_WINS 表（GENERATED 区）。
- 钉点 `verif/ut/PMP/fm_pins_pre.tcl`：golden 顶层寄存器 6664 位逐位；72 个 wen_reg 按 golden 赋值语句里的 CSR 地址对应到
  cfg_wen / addr_wen。无子模块、无黑盒。

### 5.2 UT（verif/ut/PMP；3 seed × 3 档初值 × 200k 拍，串行，commit 7016bef2 的 RTL 字节）

逐拍比全部输出（6432 位拼成一个向量）。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=200000 errors=0 PASS | checks=200000 errors=0 PASS | (1017) checks=200000 errors=0 PASS |
| 7  | checks=200000 errors=0 PASS | checks=200000 errors=0 PASS | (7017) checks=200000 errors=0 PASS |
| 42 | checks=200000 errors=0 PASS | checks=200000 errors=0 PASS | (42017) checks=200000 errors=0 PASS |

覆盖（seed 1）：cfg 写 50873 / addr 写 51468 / cfg 锁拒写 253616 项次 / addr 锁拒写 32157 / TOR 锁前项 6794 / NAPOT 重算 mask 77104。

### 5.3 lane 内非正式试跑（diagnostic-full，不出证）

1. 第一版（mask 写者 addr 恒优先）：native **FAILED**，2460 failing（全部是 pmp/pmaMapping_mask_*，见 5.1）—— 修 RTL 后：
2. 关 vmucp：native SUCCEEDED，passing 13032 / failing 0 / unmatched 全 0，unread 64 = matched_nc（PMP 表 cfg 字节的保留位 c/atomic，无出口）。
3. 开 vmucp：native SUCCEEDED，passing **13096**，unread_points 空。

### 5.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/PMP.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **13096**（regs 6664 + outs 6432）；实测预计 **13096**，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0（`PMP_PIN_END … ok=6664 bad=0`）/ 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

# 对账 C. TLB（跑完追加；§3 未改一字）

| 项 | 值 |
|---|---|
| 跑前登记 / proof commit | `6571efce8ce6d3e8c9085a3063f3a065392f8432`（登记与证明同一 commit） |
| 证据目录 | `evidence/6571efce8ce6/TLB/` |
| receipt sha256 | `a8e4a56cb8c11a0c2db384a0f200c507670e2d47524c28adc914aa2708f2e27a` |

| 预测 | 实测 passing | 差 | failing/unverified/aborted/unread_nc | unmatched 六项 | 黑盒 | verdict |
|---|---|---|---|---|---|---|
| 11118 | 11118 | 0 | 0/0/0/0 | 全 0（`TLB_PIN_END ok=95 bad=0`） | 无（3 子模块两侧白盒） | SUCCEEDED |

`fm_predict.py check TLB` → 「全部对上」。mode signoff-strict / vmucp true / merge_dup false / allowlist 0 / dont_verify 无 / fm.log 行首 Error 0 /
impl_worktree_dirty false。复跑：`PROOF_COMMIT=6571efce8ce6d3e8c9085a3063f3a065392f8432 bash scripts/run_proof.sh TLB TLB < /dev/null`

# 对账 D. PTWFilterEntry（跑完追加；§4 未改一字）

| 项 | 值 |
|---|---|
| 跑前登记 / proof commit | `6571efce8ce6d3e8c9085a3063f3a065392f8432` |
| 证据目录 | `evidence/6571efce8ce6/PTWFilterEntry/` |
| receipt sha256 | `fa743f01e447920bf09f6277b2a70792a4badbaf7a8fbae616419fc76f766c85` |

| 预测 | 实测 passing | 差 | failing/unverified/aborted/unread_nc | unmatched 六项 | 黑盒 | verdict |
|---|---|---|---|---|---|---|
| 757 | 757 | 0 | 0/0/0/0 | 全 0 | 无 | SUCCEEDED |

`fm_predict.py check PTWFilterEntry` → 「全部对上」。mode signoff-strict / vmucp true / merge_dup false / allowlist 0 / dont_verify 无。
复跑：`PROOF_COMMIT=6571efce8ce6d3e8c9085a3063f3a065392f8432 bash scripts/run_proof.sh PTWFilterEntry PTWFilterEntry < /dev/null`
