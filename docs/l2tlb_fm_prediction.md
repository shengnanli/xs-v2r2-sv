# L2TLB FM 预测（★跑 FM 之前登记，跑完逐条对账★）

登记时间：本文件进入 git 的那个 commit 即为登记时刻。此时 **FM 一次都还没跑过**。

## 预测怎么来的（不是拍脑袋）

用上一轮 G0 的 L2TLB assembly 证明做标定。G0 实测（证据：
`xs-v2r2-sv/scripts/sidecar/signoff-evidence-delta2/L2TLB/verdict.sidecar.json`，
`run_id=SGN-L2TLB-1784603356`，`native_verdict=SUCCEEDED`）：

    passing 19975 / failing 0 / unverified 0 / aborted 0 / unread_notcompared 537
    matched_blackbox_pairs 6, unmatched.compare_impl 6

比较点预算模型（四项相加）：

| 项 | G0 | G1 |
|---|---|---|
| 顶层寄存器位 | 12332 | 13795 |
| 一级输出位   | 1141  | 3589  |
| 黑盒输入位   | 4151(6 个) | 6286(8 个) |
| 展开子模块寄存器位 | 3635 | 6997 |
| **模型合计** | **21259** | **30667** |

G0 实际比较点 = passing 19975 + unread 537 = **20512**，模型高估 3.6%
（`FM_MERGE_DUP=true` 把 csr/sfence 的多份同值副本归一，模型没扣这部分）。
把这个 0.9649 的标定系数套到 G1：

## 预测值

| 量 | 预测 | 区间 |
|---|---|---|
| 比较点合计 | ~29600 | 26500 – 33000 |
| **passing** | **~28500** | **26000 – 32000** |
| failing | **0** | 硬要求，非 0 即失败 |
| unverified | 0 | |
| aborted | 0 | |
| unread_notcompared | ~1000 | 400 – 1600（G0 的 537 全在 PMP 的 pmaMapping 死寄存器上；G1 的 PMP 由 2269 行涨到 4408 行，按比例外推 537×1.94≈1043） |
| unmatched（各项） | 0 | compare_impl 允许 = 黑盒数（G0 是 6，G1 预期 8） |
| matched_blackbox_pairs | **8** | PtwCache/PTW/LLPTW/HPTW/L2TlbMissQueue/L2TlbPrefetch/Bitmap/BitmapCache |

## 预测里明确不确定的地方

1. **unread 的外推最弱**。G0 的 537 个 unread 是 PMP 内部 cone-dead 的 pmaMapping
   寄存器，按行数外推只是数量级估计，不是推导。真实值落在区间外我不会去圆它。
2. **黑盒输入位**算的是 golden 子模块声明的输入位宽合计，FM 实际建的 BBPin 比较点
   可能按位合并或按 bus 计，两者不一定 1:1。
3. PMP / PMPChecker / 各 Arbiter / DelayN 是**两侧 elaborate**（不黑盒），
   这是照搬 G0 那次成功证明的配置；PMP 若改成黑盒，passing 会显著变小。

## 验收判据（与预测无关的硬线）

- `native_verdict = SUCCEEDED`
- `failing = 0`，`unverified = 0`，`aborted = 0`
- 不得出现 `dont_verify` / relaxed appvar / 假白名单
- ★条件绿★：8 个黑盒 child 在本轮台账里**都还是 MISSING**（没有独立签核）。
  所以本目标即使 native SUCCEEDED，也只能记 **PASS_PENDING_CHILDREN**，
  不得计入闭包，直到这 8 个各自 SIGNOFF_PASS。

---

# 附：2026-09-20 复核 + 重新预登记（★这一段写完就 commit，之后才跑 FM★）

上面那份预测是 `822a7ea` 落地时登记的，**FM 一次都还没跑过**（`evidence/` 下
`find evidence -iname '*L2TLB*'` 为空可验）。本段做三件事：把上面的数字**自己重量一遍**、
**修正一处内部矛盾**、把跑前状态用 sha256 钉死。

## 1. 上面那份预测的数字，我独立重算了一遍

不复用 `scripts/gen_l2tlb.py`，另写解析器直接从 G1 golden 数：

| 项 | 上面登记的 | 我独立重算 | 差 |
|---|---|---|---|
| 顶层寄存器位 | 13795 | **13795** | 0 |
| 一级输出位 | 3589 | **3589** | 0 |
| 黑盒输入位 | 6286 | **6270** | 16 |
| 展开子模块寄存器位 | 6997 | **6998** | 1 |
| 模型合计 | 30667 | **30652** | 15 (0.05%) |

也重核了端口/实例：`376 端口（224 入 / 152 出）/ 29 顶层实例`，以及本轮的
`598 条 glue`（独立解析器同样得 598）。**结论：上面那份预测的模型是可复算的，不是拍脑袋。**

G0 标定数也逐个核过（`xs-v2r2-sv/scripts/sidecar/signoff-evidence-delta2/L2TLB/native_facts.json`）：
`passing 19975 / failing 0 / unverified 0 / aborted 0 / unread_notcompared 537`，
`unmatched.compare_impl 6`，`matched_blackbox_pairs 6` —— 与上面引用的完全一致。
★但 G0 那一侧的模型（21259）我**没有**独立重算★（要另开 G0 解析），
所以 0.9649 这个标定系数是**继承的**，不是我验的。下面的区间按这一点放宽。

## 2. ★修正一处内部矛盾：PMP 到底黑不黑盒★

`verif/ut/L2TLB/Makefile` 落地时 `FM_INTERFACE_ONLY` 写了 **9** 项（含 PMP），
而上面这份预测写的是 **8 个黑盒**，并明说「PMP / PMPChecker / 各 Arbiter / DelayN
是两侧 elaborate（不黑盒），这是照搬 G0 那次成功证明的配置」，
预测里 ~1000 条 unread 也全部外推自**被展开的** PMP 的死寄存器。两者互斥。

查 G0 原始配置（可复跑）：

    grep FM_INTERFACE_ONLY .../signoff-evidence-delta2/L2TLB/make.out
    -> FM_INTERFACE_ONLY="PtwCache PTW LLPTW HPTW L2TlbMissQueue L2TlbPrefetch"   (6 项，无 PMP)

同目录 `native_facts.json` 的 537 条 unread 全是
`r:/WORK/L2TLB/pmp/pmaMapping_*_reg[*]` ↔ `i:/…/u_pmp/pmaMapping_*_reg[*]` 的**配对**点 ——
能配上对，正说明 PMP 当时是两侧展开的。

**按预测 + G0 实证取 8 项，Makefile 已改**。方向也对：黑盒少一个 = 证明强一分。

## 3. unread 改用**寄存器位数**外推，不用行数

上面按 PMP 行数 2269→4408 外推 537×1.94≈1043。行数是弱信号。直接数寄存器：

    G0 PMP.sv  pmpMapping/pmaMapping 寄存器  68 个 / 3264 bit
    G1 PMP.sv  同上                         136 个 / 6528 bit      比值 = 2.0000

**unread 预测 = 537 × 2 = 1074。**（和行数外推的 1043 落在同一处，互为旁证。）

## 4. ★预测值（跑前登记，跑完逐条对账，对不上按 fail 报）★

| 量 | 预测 | 可接受区间 |
|---|---|---|
| `native_verdict` | `SUCCEEDED` | 硬要求 |
| `failing` | **0** | 硬要求 |
| `unverified` | **0** | 硬要求 |
| `aborted` | **0** | 硬要求 |
| 比较点合计 | **29580** | 26000 – 33000 |
| `passing` | **28500** | 25000 – 32000 |
| `unread_notcompared` | **1074** | 700 – 1600 |
| `matched_blackbox_pairs` | **8** | 硬要求（就是下面那 8 个） |
| `unmatched.compare_impl` | **8** | 允许 = 黑盒数 |
| `unmatched` 其余各项 | **0** | 硬要求 |
| `dont_verify` / relaxed appvar / 假白名单 | **无** | 硬要求 |

## 5. 跑前状态（sha256 钉死；跑完用同样的命令复验）

    66b264267941f96d118da7c4cc1ae592777e64b1ccc6ce500032bdb21e27c6e5  rtl/memblock/L2TLB.sv
    df4b803f193cadd4703e424cdd3d005702932178b2281fd55bed5fc5ddd6e157  verif/ut/L2TLB/Makefile
    03eba6145e863c0eff181e316e015f7c076de7e529c0fe85335e408ea7ac1e00  verif/ut/L2TLB/tb.sv
    53395a462d83d533a4b4c87352bcfdd908b714ffffffff14acf28e8c31922f1b  scripts/fm_eq.tcl
    cd32f268b479a12ce47537652f7e0306f0624a80e65396e5b2cc59091f648529  scripts/gen_l2tlb.py
    d247762508746190bd608b8f792c53be8fb2f3fd6c6604b9378e149a0e60f7f7  /home/eda/xs-env/G1-canonical/golden-rtl/L2TLB.sv  (ref, 20101 行)

## 6. ★条件绿依赖（8 个黑盒 child，本轮台账里全是 MISSING）★

    PtwCache  PTW  LLPTW  HPTW  L2TlbMissQueue  L2TlbPrefetch  Bitmap  BitmapCache

前 6 个在 `docs/g1_universe.tsv`（306 目标）里是 `REWRITE_*/REQUIRED/UNVERIFIED`；
`Bitmap` / `BitmapCache` **不在**那 306 里，在 `docs/g1_configured_universe.tsv` 里是
`new_target`（G1 新增）。两类都不是厂商 SRAM 宏，所以按黑盒边界审核判据只能算
**独立目标条件绿**，不能当无条件绿。

本目标即使 native `SUCCEEDED`，也只记 **PASS_PENDING_CHILDREN**，不计入闭包，
直到这 8 个各自 `SIGNOFF_PASS`。

## 7. 一处**没有**改的地方，连同理由

`FM_MERGE_DUP=true` 保持不变。它是**放宽**（把同值重复寄存器合并后比，比较点只减不增），
按 CONVENTIONS「appvar 也是判据，改它之前必须双向负测」本该两个取值各跑一次。
这里保留 `true` 的理由是：G0 那次成功证明用的就是 `FM_MERGE_DUP=true`
（`make.out` 可查），换值就换了标定口径，预测会失效。
★诚实记着：`false` 那一轮**本轮没跑**，所以"没有东西被 merge_dup 遮住"这句话
本 lane 没有证据。★ 留作后续。
