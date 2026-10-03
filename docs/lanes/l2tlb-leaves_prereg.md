# l2tlb-leaves lane（agent/l2tlb-leaves）—— 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `59c860f2`（集成者预建 worktree + 认领文件） |
| 工作树 | `/home/eda/xs-env/wt-l2tlb-leaves`，分支 `agent/l2tlb-leaves` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | L2TLB 的 7 个未签 child：`Arbiter1_L2TLBImp_Anon` `Arbiter2_L2TLBImp_Anon_1` `Arbiter3_bitmapReqBundle` `Arbiter4_L2TlbMemReqBundle` `Arbiter5_L2TlbWithHptwIdBundle` `L2TlbMissQueue` `L2TlbPrefetch` |
| 冲突检查 | codex outbox 最近 20 条 + 26 个 `codex/*` 分支 rtl diff：不涉及本 lane 目标；全部 worktree 的 `*_claim.md` 精确名：只有本 lane 认领这 7 个；其他 prereg 里的出现均为引用（L2TlbMissQueue 作 ram_40x47 先例） |
| 口径 | 5 个仲裁器 + L2TlbPrefetch：`signoff-strict`；L2TlbMissQueue：`assembly`（ram_40x47 两侧对称黑盒，APPROVED_MEMORY_MACRO_MODEL，`scripts/audit_ram_memory_model.py --check` AUDIT_PASS）。全部 `FM_MERGE_DUP=false`，无 dont_verify、无 vmucp、无 fm_pins |

## 1. 五个仲裁器（UT = verif/ut/L2TlbArbLeaves）

### 1.1 结构
- 2 路及以上复用已签核核 `rtl/frontend/xs_FixedPriorityArbiter_core.sv`（**不改核**）；薄文件由
  `scripts/gen_arbiter_l2tlb_leaves.py`（带 `--check`）从 golden 端口表生成，放 `rtl/mmu/`。
- 被上游接成常量的字段（firtool 删了端口）在拼载荷时填常量；常量表逐项带 Scala 出处，生成器 fail-closed
  要求"缺的字段 == 登记的字段"。共 22 处（Arbiter2_1:1 / Arbiter3:7 / Arbiter4:5 / Arbiter5:9）。
- Arbiter1_L2TLBImp_Anon 单入口 = 直通，不例化核（核要求 NUM_IN>=2），先例 `rtl/memblock/Arbiter1_TagWriteReq.sv`。
- Arbiter2_L2TLBImp_Anon_1：Scala `out.ready := true.B`，golden 删了 io_out_ready / io_in_0_ready，核 out_ready 接 1。
- Arbiter5_L2TlbWithHptwIdBundle：golden 有 io_chosen，薄文件另算（第一个 valid 的下标，都不 valid 为 4）。
- 核的端口数恒等式按标准 Arbiter 接口算，两种增删在生成器里核实后显式加回/扣掉。

### 1.2 FM 预测（模型 = 顶层 output 位，无寄存器；登记 docs/fm_predictions/*.json）

| 目标 | passing | 其余 |
|---|---|---|
| Arbiter1_L2TLBImp_Anon | **272** | failing/unverified/unread/unmatched 全 0，无黑盒，SUCCEEDED |
| Arbiter2_L2TLBImp_Anon_1 | **109** | 同上 |
| Arbiter3_bitmapReqBundle | **91** | 同上 |
| Arbiter4_L2TlbMemReqBundle | **58** | 同上 |
| Arbiter5_L2TlbWithHptwIdBundle | **55** | 同上 |

可能出错处：常量值若抄错，FM 会在对应 output 位上 failing（UT 同样会抓到：每路胜出都覆盖 >= 200 拍）。

## 2. L2TlbMissQueue（UT = verif/ut/L2TlbMissQueue）

### 2.1 结构
- golden 两层（L2TlbMissQueue → Queue40_L2TlbMQBundle → ram_40x47）压成一层：可读核 `xs_L2TlbMissQueue_core`
  = chisel Queue 控制 + flush + golden 同名 ram_40x47 例化（例化名改成与 golden 相同的 `ram_ext`，allow 文件同步）。
- **不复用 `xs_ChiselQueue_core`**：它没有 flush 口；`check_shared_impl_impact.py` 实测加口会让 16 个已签目标 STALE。
  G1 里带 flush 的 Queue 只此一个，故就地写控制。
- ref 侧 FM_REF_DEPS = Queue40_L2TlbMQBundle.sv（白盒），ram_40x47 两侧对称黑盒。

### 2.2 FM 预测
| 项 | 预测 |
|---|---|
| passing | **125**（regs 13 + outs 49 + ram_40x47 输入引脚 63） |
| failing / unverified / unread / unmatched | 0 |
| 黑盒 | ram_40x47 ×1 / ×1 对称（allow：APPROVED_MEMORY_MACRO_MODEL） |
| verdict | SUCCEEDED（assembly） |

可能出错处：W0_data 里 4 位恒 0（isHptwReq/hptwId）的黑盒引脚可能被 FM 归为常量而不计 passing —— 若 passing 少 4，
即此原因（届时按 receipt 的 const 字段对账，不改本表）。

## 3. L2TlbPrefetch（UT = verif/ut/L2TlbPrefetch）

### 3.1 结构
单叶子，按 训练 / 去重 / 发出 三节手写。去重窗口只存 35 位行号（golden 38 位、低 3 位写恒 0 且不读），
golden 那 12 个死位按 `verif/dead_ref/L2TlbPrefetch.json` 逐条声明 → PASS_DEAD_REF（impl 侧 unread 0）。

### 3.2 FM 预测
| 项 | 预测 |
|---|---|
| model expected | 238（regs 197 + outs 41） |
| passing | **223** = 238 − 12（ref-only unread，dead_ref 声明）− 3（两侧 next_req[2:0] 只装 0 → Constant reg） |
| failing / unverified / unmatched / impl unread | 0 |
| ref unread | 12（全部在 dead_ref 声明里） |
| 黑盒 | 无 |
| verdict | SUCCEEDED → PASS_DEAD_REF |

依据：上一轮同结构实现的记录（beec8f6d 提交说明：passing 223 / unread(ref) 12）；本轮没有做任何 FM 试跑。

## 4. UT 口径
三个 UT 都由各自 gen.py（dual_tb_lib，`--check`）生成，逐拍比全部输出；seed 1/7/42 × `+vcs+initreg+0` /
`+vcs+initreg+random` / `+vcs+initreg+<seed>017`，各 200k 拍，seed 串行。读数见文末对账。

## 对账（跑完追加，不改上文任何数字）
