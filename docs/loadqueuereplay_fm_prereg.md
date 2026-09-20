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

---
---

# 逐条对账（跑完之后追加；上面原文一字未改）

**run #1**：`scripts/run_proof.sh LoadQueueReplay LoadQueueReplay`，
commit `71138d6056818ae247cb0f3713845450a4f39a37`，
run_id `LoadQueueReplay-20260920T064832Z-71138d60`，
证据 `evidence/71138d605681/LoadQueueReplay/`（receipt.json / fm.log / black_boxes.rpt /
unread_points.txt / unmatched.rpt / sidecar/）。

    golden sha256 = ccdcf9d3dc28c7b07ae489ea0e892685807535a33a831a378cc49d80c5a3400a
                    (G1-canonical/golden-rtl/LoadQueueReplay.sv)
    impl   sha256 = b3f0aac04ad7aa4faa4dd3f79647fb892a350f3c6da646896ca1aa156794a35e
                    (rtl/memblock/LoadQueueReplay.sv)
    canonical_id  = G1-a4ea14f2ddf612bb4ad023d26a2ca1bf33eddcaebe470b0c620e9fba0e7afcf0
    impl_worktree_dirty = False

| # | 预测 | 实测 | 判 |
|---|---|---|---|
| P1 | native `SUCCEEDED` | `SUCCEEDED` | **HIT** |
| P2 | passing 113,900，区间 [111,000, 115,000] | **113,983** | **HIT**（差 83 = 0.07%） |
| P3 | failing 0 | 0 | **HIT** |
| P4 | aborted 0 | 0（unverified 也 0） | **HIT** |
| P5 | unmatched.compare_impl 0 | 0 | **HIT** |
| P6 | unmatched.compare_ref ≤ 200 | **0** | **HIT**（比预测还好） |
| P7 | matched blackbox pair = 5 | 5 | **HIT** |
| P8 | validator PARTIAL，原因是 matched-unread 须 vmucp | PARTIAL，`reason=strict_unread!=0`，unread=177，`dont_verify=false`、`elab147=false`、unmatched 两侧 0 | **HIT** |
| P9 | 峰值内存 4,000–15,000 MB | **3,959 MB** | ★**MISS**★（低于下界 41 MB，1.0%） |
| P10 | UT 3 seed × 2 initreg × 200k 全 PASSED | 6/6 PASSED，checks=117,564,400/轮，errors=0，26 个覆盖闸全非零 | **HIT** |

**9 命中 / 1 落空。** P9 是真落空，不做任何解释性挽救：我把下界定在 4,000 MB
是拿 CONVENTIONS 里 `Composer 4653 / Ftq 4047` 这一档外推的，而 LoadQueueReplay
虽然 golden 行数更大（138,860 行 vs Ftq），**寄存器锥体的结构比那两个浅**，
实际停在 3,959 MB。★区间定窄了就是定窄了，差 1% 也是差。★

比较点结构模型的收官对账（这是 P2 的立足点，单独记）：

    模型（golden 结构，跑 FM 前算出）        114,222
    FM 实测 matched compare points           113,983   = 5,532(user) + 106,975(name)
                                                         + 1,476(signature) + 0(topology)
    模型高估                                    239   = 0.21%
    （G0 校准时的高估是 0.25%，两轮一致）

`Unmatched reference(implementation) compare points = 0(0)`，
`Unmatched ... primary inputs, black-box outputs = 0(0)`。

## 177 个 matched-unread 的双射（机械核对，0 违例）

`unread_points.txt` 全 177 行都是 `matched_nc`，ref 与 impl 各 177 个互不重复的名字：

| ref 根 | 点数 | impl 根 | 语义 |
|---|---|---|---|
| `cause_<n>_reg[5]` / `[6]` | 144 | `cause_reg[<n>][5]` / `[6]` | 72 条 entry 的 cause 位 5/6：两侧都存、两侧都不读 |
| `s2_replayCauses{,_1,_2}_reg[b]`（b≠4） | 30 | `s2_cause_q_reg[<p>][b]` | s2 流水 cause，只有 bit4 被读 |
| `s2_replayMSHRId{,_1,_2}_reg[4]` | 3 | `s2_mshr_q_reg[<p>][4]` | 5 位存、输出只取 [3:0] |

逐点核对（下标对下标）**0 违例**，复跑：

```bash
python3 - <<'PY'
import re, collections
refs=[];imps=[]
for ln in open("evidence/71138d605681/LoadQueueReplay/unread_points.txt"):
    k,rest=ln.rstrip("\n").split("\t",1); assert k=="matched_nc"
    m=re.match(r'\{([^}]*)\} \{([^}]*)\}$', rest); refs.append(m.group(1)); imps.append(m.group(2))
assert len(refs)==len(set(refs))==len(set(imps))==177
bad=0
for r,i in zip(refs,imps):
    m=re.match(r'r:/WORK/LoadQueueReplay/cause_(\d+)_reg\[(\d+)\]$',r)
    if m: bad += (i!="i:/WORK/LoadQueueReplay/u_core/cause_reg[%s][%s]"%m.groups()); continue
    m=re.match(r'r:/WORK/LoadQueueReplay/s2_replayCauses(_\d+)?_reg\[(\d+)\]$',r)
    if m: p=0 if not m.group(1) else int(m.group(1)[1:]); bad += (i!="i:/WORK/LoadQueueReplay/u_core/s2_cause_q_reg[%d][%s]"%(p,m.group(2))); continue
    m=re.match(r'r:/WORK/LoadQueueReplay/s2_replayMSHRId(_\d+)?_reg\[(\d+)\]$',r)
    if m: p=0 if not m.group(1) else int(m.group(1)[1:]); bad += (i!="i:/WORK/LoadQueueReplay/u_core/s2_mshr_q_reg[%d][%s]"%(p,m.group(2))); continue
    bad+=1
print("bijection violations:", bad)     # -> 0
PY
```

这正是上一轮 `b411cbb4` 标题里那个 **177**。上一轮那条 lane 修完没重跑 evidence，
所以这个数在本轮之前**没有任何当前基线上的证据**；现在有了。

## ★run #1 抓到的缺陷：573 条钉点被 FM 拒，而脚本一声不吭★

`fm.log` 里有 **570 行 `Error: Unknown name: ... (FM-036)`**（另有 3 处 "FM-036"
是 `scripts/fm_eq.tcl` 注释被回显，不是错误 —— 这正是 CONVENTIONS「别拿裸错误号当判据」
说的那件事，所以计数要用行首锚定的 `grep -cE "^ *Error:"`）。

被拒的全在 impl 侧，只有三个信号根：

    504  blockSqIdx_reg[n][b]       = 72 x 7   （全灭）
     33  red_q_s0_reg[i][b]         = 3 x 11   （全灭）
     33  red_q_s1_reg[i][b]         = 3 x 11   （全灭）

根因是**名字形状猜错**，不是 RTL 有问题。从本轮 `matched.rpt` 里逐条读出来的真实形状：

| impl 声明 | FM 里的名字 |
|---|---|
| `logic [10:0] cause [72]`（非打包数组 + 纯向量） | `cause_reg[5][3]` |
| `entry_ctrl_t ent [72]`（非打包数组 + packed struct） | `ent_reg[0]\[allocated]` |
| `sq_ptr_t blockSqIdx [72]`（嵌套向量字段） | `blockSqIdx_reg[0]\[value][0]` |
| `redirect_q_t red_q_s0 [3]`（嵌套 struct 字段） | `red_q_s0_reg[0]\[robIdx]\[value][3]` |

即：**packed struct 成员用字段名下标，而且字段括号前带一个反斜杠**；数字下标不带。
`ent_reg[$n]\[allocated]` 当初蒙对了，另外两族全错。

★这 570 个点最后**还是被自动匹配配上了**★（`blockSqIdx` 走 Name、`red_q_s*` 走 Func），
所以 run #1 的结论**不受影响** —— unmatched 两侧都是 0。但那是运气，不是判据：
钉点被拒之后静默退回自动匹配，和「没钉」无法区分。原脚本还在结尾打了
`LQR_PINS: applied`，等于**自报了一件没发生的事**。

顺带一个可复核的观测：run #1 的 `matched.rpt` 显示 golden 三份 redirect 副本
（`s0_can_go_REG{,_1,_2}`）被**同一个** impl 寄存器 `red_q_s0_reg[0]\[...]` 接走，
`tl_d_valid_q` 同理 —— 这是 `verification_merge_duplicated_registers = true`
把 impl 的三份合并之后的结果。**六份副本仍然必须写**（不写就有 55 个 ref 侧
unmatched，上一版实测过），合并是 FM 的事，不是可以省掉副本的理由。
