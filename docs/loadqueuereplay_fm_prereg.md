# LoadQueueReplay FM 预登记预测（跑 FM 之前写死）

**本文件在 `scripts/run_proof.sh LoadQueueReplay LoadQueueReplay` 之前写定并提交。**
事后不得修改任何一条预测；对账结果另写一节追加在下面，原文照留。

- 分支：`agent/lqreplay-fm`
- golden：`/home/eda/xs-env/G1-canonical/golden-rtl/LoadQueueReplay.sv`（138,860 行）
- 依赖的 golden 子模块（两侧同为 matched blackbox）：
  `LqVAddrModule` / `FreeList_5` / `AgeDetector_38`（×3 实例）

---

## 0. 我推翻了前一条 lane 的预登记，理由写在这里

前一条 lane 预登记的是 **passing ∈ [90,000, 105,000]**，锚点是"G0 基线 33,337"。
我把它**改成 [111,000, 115,000]，点估计 113,900**，并且是在跑 FM 之前改的。三条理由：

**(1) 它的锚点建立在一个未验证的前提上，而那个前提我查了——确实未验证。**
"G0 基线 33,337" 出自**上一轮仓库** `/home/eda/xs-env/xs-v2r2-sv`
`scripts/sidecar/signoff-evidence-delta2/LoadQueueReplay/native_facts.json`
（`run_id: SGN-LoadQueueReplay-1784603667`，`impl_commit: 7fd315f166b9294db24bde29e02068f380ad56e5`，
`native_verdict: SUCCEEDED`，`passing 33337 / failing 0 / unread_notcompared 144`，
`unmatched: compare_ref 144 / compare_impl 0 / unread_ref 33 / unread_impl 5373`，
判决 `PARTIAL`）。

任务交接里点名的那个 commit `b411cbb4`（"177 对称双射 + entry 128→72 + exceptionVec 窄化"）
**在本轮仓库里根本不存在**——它是上一轮 `xs-v2r2-sv` 的 commit。复核：

```
cd /home/eda/xs-env/xs-v2r2-sv
git merge-base --is-ancestor 7fd315f166b9294db24bde29e02068f380ad56e5 b411cbb4 && echo ancestor
git log --oneline -3 -- scripts/sidecar/signoff-evidence-delta2/LoadQueueReplay
```
第一条输出 `ancestor`（证据 commit 是修复 commit 的祖先，即**证据早于修复**），
第二条最后一次改动是 `6c7ab95e`，在 `b411cbb4` 之前。
**结论：上一轮那个修复之后，LoadQueueReplay 的 evidence 一次都没重跑过。**
所以 33,337 是"修复前"的数，拿它当锚点外推 G1 是在未验证前提上盖第二层。

**(2) 我换了一个不依赖任何历史 evidence 的锚点：golden 自己的结构。**
FM 的比较点 ≈ **golden 寄存器位数 + 输出端口位数 + 黑盒输入引脚位数**。
这三项都能从 golden 源码直接数，不需要跑任何工具、不依赖上一轮做了什么。

**(3) 这个模型在 G0 上校准过，误差 0.25%。** 见下。

---

## 1. 比较点结构模型与 G0 校准

复跑命令（只读 golden，秒级）：

```bash
cd /home/eda/xs-env && python3 - <<'PY'
import re
def model(root, insts):
    t=open(root+'/LoadQueueReplay.sv').read()
    rb=rc=0
    for ln in t.split('\n'):
        m=re.match(r'\s*reg\s*(\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s+(\w+)\s*;', ln)
        if m:
            rb += 1 if not m.group(2) else int(m.group(2))-int(m.group(3))+1; rc+=1
    mh=re.search(r'module\s+LoadQueueReplay\s*\((.*?)\);', t, re.S).group(1)
    ob=sum(1 if not g[0] else int(g[1])-int(g[2])+1
           for g in re.findall(r'output\s*(\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s+\w+', mh))
    bb=0
    for f,n in insts:
        s=open(root+'/'+f+'.sv').read()
        h=re.search(r'module\s+'+f+r'\s*\((.*?)\);', s, re.S).group(1)
        bb += n*sum(1 if not g[0] else int(g[1])-int(g[2])+1
                    for g in re.findall(r'input\s*(\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s+\w+', h))
    print(root, 'regs',rc,'regbits',rb,'outbits',ob,'bbinbits',bb,'TOTAL',rb+ob+bb)
I=[('LqVAddrModule',1),('FreeList_5',1),('AgeDetector_38',3)]
model('G0-canonical/golden-rtl', I)
model('G1-canonical/golden-rtl', I)
PY
```

实测输出：

| golden | reg 条数 | reg 位数 | 输出位数 | 黑盒输入位数 | 模型总比较点 |
|---|---|---|---|---|---|
| G0 | 4,767 | 31,775 | 1,292 | 643 | **33,710** |
| G1 | 14,748 | 109,190 | 4,389 | 643 | **114,222** |

G0 校准（对着上一轮 `native_facts.json` 的实测）：

```
实测 golden 侧比较点总数 = passing 33,337 + unread_notcompared 144 + unmatched.compare_ref 144
                        = 33,625
模型                     = 33,710
模型高估                 = 85 点 = 0.25%
```

★这 0.25% 是本预测的全部立足点，也是它的已知上限。★ 模型没有考虑：
FM 对常数化寄存器的优化、`_GEN_` 中间量、以及 impl 侧独有的死寄存器
（G0 那轮 `unread_impl=5373` 就是 impl 声明了 128 条 entry 造成的，本轮 RTL
已按真实深度 72 声明，注释写在 `rtl/memblock/LoadQueueReplay.sv` §0）。

G1 外推：`114,222 × (33,625/33,710) = 113,934`。

---

## 2. 预登记预测（★以下各条跑 FM 前写死，不得事后修改★）

| # | 量 | 预测 | 判 miss 的条件 |
|---|---|---|---|
| P1 | native verdict | `SUCCEEDED` | 任何别的值 |
| P2 | `stats.passing` | 点估计 **113,900**，区间 **[111,000, 115,000]** | 落在区间外 |
| P3 | `stats.failing` | **0** | > 0 |
| P4 | `stats.aborted` | **0** | > 0 |
| P5 | `unmatched.compare_impl` | **0** | > 0 |
| P6 | `unmatched.compare_ref` | **≤ 200**（G0 是 144） | > 200 |
| P7 | matched blackbox pair 数 | **5**（vaddrModule / freeList / ageOldest_age×3） | ≠ 5 |
| P8 | validator（官方 gate）判决 | **PARTIAL**，原因是 matched-unread 非零、须 vmucp 双射；**不是** RTL 错 | 若判 PARTIAL 但原因是 failing/unmatched_impl，算 miss |
| P9 | FM 峰值内存（`fm.log` 的 `Maximum memory usage`） | **4,000–15,000 MB** | 落区间外 |
| P10 | UT 3 seed × 2 initreg × 200k | 全部 `TEST PASSED`（errors=0 且 26 个覆盖闸全非零） | 任何一轮不 PASSED |

**P8 的写法说明**：G0 那轮 native `SUCCEEDED` 但 validator `PARTIAL`，卡在
`unread_notcompared=144`（strict 的 unread 铁律）。本轮 `fm_pins_pre.tcl` 已钉了
一批结构双射，但没有任何证据说它把 unread 清成 0，所以我**不预测它能一把清零**。
P8 若实测直接 `SIGNOFF_PASS`，算"比预测好"，仍然逐条记。

**我没有预测的量**（不编）：`unread_notcompared` / `unread_ref` / `unread_impl`
的具体数值、FM 运行墙钟时间。我没有能支撑一个区间的模型，所以不给数，
而不是给一个宽到无意义的区间。

---

## 3. 条件绿（跑之前就声明）

本目标即使 FM 全绿也只能是**条件绿**，依赖两个当前 UNPROVEN 的子模块：

| 子模块 | 状态 | 依据 |
|---|---|---|
| `FreeList_5` | 已独立签核 SUCCEEDED（passing 724） | 交接信息，我未独立复核 |
| `LqVAddrModule` | **UNPROVEN** | 本轮未签核 |
| `AgeDetector_38` | **UNPROVEN** | 本轮未签核 |

黑盒边界审核（按 CONVENTIONS「黑盒边界要审」）：这三个都是**独立签核目标**，
不是 golden 逻辑复用，也不是厂商 SRAM 宏 → 属于"独立签核目标条件可黑盒"那一档。
`FreeList_5` 无条件成立；另两个在它们各自签核之前，本目标的绿是**挂着的**。
