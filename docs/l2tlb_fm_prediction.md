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
