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

---

# run #2：44 秒死在 vmucp 白名单（不是 FM 跑出来的结果，是没跑）

commit `4192b2c1`，证据 `evidence/4192b2c1faa0/LoadQueueReplay/`（只有 fm.log + MAKE_RC，
**没有 receipt.json、没有 native_facts.json** —— 这正是"根本没跑"的形态，
和集成者提醒的那种 44 秒 setup 死法长得一模一样，但根因不同）。

    FM_MODE_ERROR: matched-unread strengthening ????????, ?? LoadQueueReplay
    Maximum memory usage for this session: 867 MB      <- 即 Formality 启动地板
    Elapsed time: 44 seconds
    make_rc = 3

根因：`scripts/fm_eq.tcl` 对 vmucp 有一张**精确白名单**，LoadQueueReplay 不在上面。
这是设计如此（vmucp 必须逐个论证，不是打开就能用），不是缺陷。

顺带抓到的：★那条错误消息是中文的，进了 fm.log 全成问号★。
"是什么问题"的那半句全丢了，只有目标名侥幸是 ASCII 才看得见。
CONVENTIONS 早写过"进 fm.log 的字必须 ASCII"，这条漏网。本轮一并改成 ASCII。

**这一跑不产生任何可用于对账的数字**，除了一条：我的钉点 fail-closed 改动
**没有**在这一跑里被检验（脚本死在钉点之前）。留给 run #3。

---

# run #3 预登记（★写在 run #3 之前；与 run #1 的预登记同等约束★）

打开 vmucp 之后，177 个 matched-unread 会被 FM **真的比一遍**。所以：

| # | 量 | 预测 | 判 miss 的条件 |
|---|---|---|---|
| Q1 | `stats.passing` | **114,160**，即 `113983 + 177`，★一个不多一个不少★ | 任何别的值 |
| Q2 | `stats.unread_notcompared` | **0** | ≠ 0 |
| Q3 | `stats.failing` / `unverified` / `aborted` | 全 **0** | 任一 > 0 |
| Q4 | `unmatched` 六项 | 全 **0** | 任一 ≠ 0 |
| Q5 | native verdict | `SUCCEEDED` | 别的值 |
| Q6 | validator 判决 | **SIGNOFF_PASS**（条件绿，依赖见第 3 节） | 别的值 |
| Q7 | `LQR_PINS: accepted=... rejected=...` | **accepted=6290 rejected=0**（钉点全被接受） | rejected > 0，或这一行根本没出现 |
| Q8 | `grep -cE "^ *Error:" fm.log` | **0**（run #1 是 570） | > 0 |
| Q9 | `Compare points matched by user` | **> 5,532**（run #1 的值；6,290 条钉点全生效后应显著高于它） | ≤ 5532 |

★Q1 是这次最要紧的一条★：`passing` 必须**正好**加 177。
CONVENTIONS 里写过这条判据的反面 ——「passing 不增而 unread 归 0 = 点被吞掉，不算过」。
加得比 177 多也一样要查：那说明有别的点的状态跟着变了。

Q7/Q8 检验的是钉点 fail-closed 改动本身：run #2 死在钉点之前，这两条一次都没验过。

---

# UT 正式矩阵与变异体（与 FM 并列的另一半验收）

## 1. UT 正式矩阵 3 seed × 2 initreg × 200k

```bash
cd verif/ut/LoadQueueReplay
for s in 1 7 42; do make run SEED=$s INITREG=random; done
for s in 1 7 42; do make run SEED=$s INITREG=0;      done
```

6/6 全部 `TEST PASSED`，每轮 `cycles=200000 checks=117564400 errors=0`。
`TEST PASSED` 本身就带覆盖闸：26 个桶（11 个 cause + 15 个场景）任一为 0 就判 FAILED
（tb.sv 的 `cov_ok`），所以「errors=0」和「覆盖非零」是一条判据不是两条。

两档日志在磁盘上并存（CONVENTIONS 要求的那条「看文件名就知道接没接上」）：

    sim_{1,7,42}_initreg0.log  与  sim_{1,7,42}_initregrandom.log  各 3 份

## 2. ★initreg 确实改变了待测状态★（codex 0168 要求的那条自证）

「两档日志都在」只能证明**跑过两轮**，证明不了**注入生效**。
CONVENTIONS 记过两种死法（编译期没给 / 运行期写死），本仓还有第三种更隐蔽的：
非打包数组混合驱动会让 VCS 静默关掉整族的初始化，0 error 0 warning。
所以直接测：

```bash
# 探针 tb 只连 clock/reset，其余端口悬空，t=1ns 打两侧不复位寄存器的签名
S=<scratch>; cd $S
VCS_ARCH_OVERRIDE=linux vcs -full64 -sverilog -timescale=1ns/1ps -lca \
  +define+SYNTHESIS +vcs+initreg+random \
  <repo>/verif/ut/LoadQueueReplay/ut_gen/LoadQueueReplay.sv \
  <G1>/LoadQueueReplay.sv <G1>/LqVAddrModule.sv <G1>/FreeList_5.sv \
  <G1>/AgeDetector_38.sv <G1>/DelayN_13.sv <G1>/DelayNWithValid_152.sv \
  <G1>/DelayNWithValid_155.sv probe_tb.sv -top tb -o probe_simv
./probe_simv +ntb_random_seed=7 +vcs+initreg+0
./probe_simv +ntb_random_seed=7 +vcs+initreg+random
```

实测：

| 运行参数 | impl 侧 uop/vec/blockSqIdx 签名 | golden 侧 uop_0_pc / uop_37_pc / uop_71_pc |
|---|---|---|
| `+vcs+initreg+0` seed 1 / 7 | `0000000000000000` ×3（两 seed 相同） | 全 0 |
| `+vcs+initreg+random` seed 1 | `00000001ffffffb8` / `…ffb8` / `…00b8` | 全 1 |
| `+vcs+initreg+random` seed 7 | `a054a5ca` / `8df26d55` / `1b` | `1a257ac7e2458` / `34cd770355de0` / `25b9e3195ff63` |

**两侧的不复位寄存器都被真的改写了**，而且 impl 侧那三族正是非打包数组
（`lqr_uop_t uop[72]` / `lqr_vec_t vecReplay[72]` / `sq_ptr_t blockSqIdx[72]`），
即那条静默失效的坑在本目标上**不存在**。

★顺带一条值得记的★：`+vcs+initreg+random` 配 `+ntb_random_seed=1` 给出的是
**全 1** 这种退化图样（不是杂乱值）；换 seed 7 才是真随机。
用单个 seed 判断"random 档有没有生效"会看到一个很可疑的全 1，容易误判。

★还有一条踩过的★：探针**在 `#0` 采样读到的全是 x**，`#1` 才看得到注入值。
按 `#0` 的结果会得出"initreg 根本没生效"这个错结论。

## 3. 「3 seed 全绿不足以说明没有上电值问题」——补 40 seed 扫

72 条 entry 的 `uop` / `vecReplay` / `blockSqIdx` 不复位，两侧独立例化，
在 `initreg=random` 下各抽各的上电值。tb 靠 `WARM=400` 拍只灌入队不释放
（freelist 每拍分 3 个槽，24 拍填满 72 条）把比较窗口推到全部 entry 都被写过之后。
CONVENTIONS 记过 `StdFreeList` 那次要扫 40 个 seed 才命中 3 个，常用的 1/7/42 全绿。
所以补扫：

```bash
cd verif/ut/LoadQueueReplay
seq 1 40 | xargs -P 10 -I{} ./simv +ntb_random_seed={} +ncycles=20000 \
  +vcs+initreg+random -l <scratch>/sw_{}.log
```

**40/40 `errors=0` 且 40/40 `TEST PASSED`**（覆盖闸在 20k 拍下也全非零）。

## 4. 变异体矩阵（13 个，50k 拍 / seed 1）

```bash
cd verif/ut/LoadQueueReplay
python3 mutants.py --check                                  # 毫秒级：表没和 RTL 脱钩
MUT_CYCLES=50000 MUT_SEED=1 python3 mutants.py              # 全跑（分组见 MUT_WORK）
```

baseline `errors=0 checks=29214400`。**13/13 符合期望，无 COMPILE_FAIL / PATCH_MISS。**

| ID | 期望 | 实测 | errors | 打的是什么 |
|---|---|---|---|---|
| M1 | CAUGHT | CAUGHT | 1,785,437 | C_MF 解除条件退回 G0（lqIdx vs ldWbPtr） |
| M2 | CAUGHT | CAUGHT | 17,696,272 | 把 G0 的 hasExceptions 门控补回 needEnqueue |
| M3 | EXPECTED_MISSED | MISSED | 0 | 三份 D-channel 打拍合并成一份（功能等价、结构不等价） |
| M4 | CAUGHT | CAUGHT | 39,207 | 去掉 G1 新增的「上一拍 D-channel」 |
| M5 | CAUGHT | CAUGHT | **2** | replayAllocate 漏掉最后一条 entry |
| M6 | CAUGHT | CAUGHT | 1,857,461 | 入队存 exceptionVec 而不是清 0 |
| M7 | CAUGHT | CAUGHT | 127,791 | SQ 就绪向量越界读返回 0 而不是第 0 项 |
| M8 | CAUGHT | CAUGHT | 3,932 | topdown 的 robHeadLoadMSHR 取 C_DM 而不是 C_DR |
| M9 | EXPECTED_MISSED | MISSED | 0 | s1_cancel 读 uop 时加 valid 门控 |
| M10 | EXPECTED_MISSED | MISSED | 0 | 给 golden 无复位的 s1_oldestSel_bits 加复位 |
| M11 | EXPECTED_MISSED | MISSED | 0 | topdown 归约树两个实参对调（平局才分叉） |
| M11b | CAUGHT | CAUGHT | 4,111 | topdown 归约取最新而不是最老 |
| M12 | CAUGHT | CAUGHT | 40,164 | 冷却阈值 12 → 13 |

★M5 要点名★：50k 拍也只抓到 **errors=2**，余量极薄（只有"第 71 条是唯一 allocated"
那一拍可观测）。20k 拍时同样是 2，**加拍数并不加余量** —— 它真正的兜底在 FM
（`io_replayAllocate` 是 `allocated` 的纯组合归约，FM 全取值域逐点比）。
这条留着不删，但**不能算 UT 的判别力证据**。

4 个 `EXPECTED_MISSED` 都不是"没人管"：M3/M10 归 FM（结构/复位域），
M9 是 golden 无条件读、加门控会把 valid 引进次态锥（FM 看得见），
M11 是归约树形状只在 robIdx 平局时分叉（仿真按构造几乎产生不出）。
★M11 曾经被前人当成"真功能变异"，复盘发现它近乎空变异（isAfter 反对称 ⇒ 逐位相同），
理由与替代的 M11b 一起写在 mutants.py 里 —— 剔掉它会让人以为树形无所谓。★

---

# 附：交接里两条「支柱测量」我自己复现了一遍

CONVENTIONS「继承来的数字与断言，第一次引用时必须重新测量」。两条都逐字复现：

**(1) 端口 610 → 1391，新增 789 里 786 个是 `_uop_` payload。**

```bash
cd /home/eda/xs-env && python3 - <<'PY'
import re
def ports(p):
    t=open(p).read()
    b=re.search(r'module\s+LoadQueueReplay\s*\((.*?)\);', t, re.S).group(1)
    return set(re.findall(r'(?:input|output)\s*(?:\[\s*\d+\s*:\s*\d+\s*\])?\s+(\w+)', b))
g0=ports('G0-canonical/golden-rtl/LoadQueueReplay.sv')
g1=ports('G1-canonical/golden-rtl/LoadQueueReplay.sv')
new=g1-g0
print(len(g0), len(g1), len(new), sum('_uop_' in n for n in new), sorted(n for n in new if '_uop_' not in n))
PY
# -> 610 1391 789 786 ['io_replayAllocate', 'io_robDeqPtr_flag', 'io_robDeqPtr_value']
```

**(2) 具名 wire 根 G0 654 / G1 648，新增 0 个。**

```bash
cd /home/eda/xs-env && python3 - <<'PY'
import re
def roots(p):
    t=open(p).read()
    return {re.sub(r'_\d+$','',n)
            for n in re.findall(r'^\s*wire\s*(?:\[[^\]]*\])?\s*(\w+)\s*(?:=|;)', t, re.M)
            if not re.match(r'^_(GEN|T)', n)}
g0=roots('G0-canonical/golden-rtl/LoadQueueReplay.sv')
g1=roots('G1-canonical/golden-rtl/LoadQueueReplay.sv')
print(len(g0), len(g1), "new:", len(g1-g0), "gone:", sorted(g0-g1))
PY
# -> 654 648 new: 0 gone: ['data_0','data_0_6_probe','data_0_7_probe','data_0_8_probe','debug_robIdx','hasExceptions']
```

两条都对上了。第二条顺带给出一个有用的细节：G1 消掉的 6 个根里有 `hasExceptions` ——
正是变异体 M2「把 G0 的 hasExceptions 门控补回 needEnqueue」打的那个点
（M2 抓到 errors=17,696,272）。golden 的行数翻 2.5 倍确实几乎全是 payload 复制：
wire 声明 4275 → 9222，而**具名根一个没多**。

---

# run #3 逐条对账：**9/9 全中，verdict = SUCCEEDED**

commit `75e1d8be8148...`，run_id `LoadQueueReplay-20260920T075542Z-75e1d8be`，
证据 `evidence/75e1d8be8148/LoadQueueReplay/`。

    verdict        = SUCCEEDED     (official gate, mode=signoff-strict, allowlist=0)
    native         = SUCCEEDED
    passing 114160 / failing 0 / unverified 0 / aborted 0 / unread_notcompared 0
    unmatched: compare_ref 0  compare_impl 0  unread_ref 0  unread_impl 0
               bbout_ref 0    bbout_impl 0
    matched blackbox pairs = 5
    vmucp = true, dont_verify = false, elab147 = false, markers = 1
    Maximum memory usage 3960 MB
    grep -cE "^ *Error:" fm.log  ->  0        (run #1 是 570)
    LQR_PINS: accepted=6290 rejected=0
    matched: 6213 user / 106471 name / 1476 signature / 0 topology  = 114160
    golden sha256 ccdcf9d3dc28c7b07ae489ea0e892685807535a33a831a378cc49d80c5a3400a
    impl   sha256 b3f0aac04ad7aa4faa4dd3f79647fb892a350f3c6da646896ca1aa156794a35e
    fm_pins_pre.tcl sha256 42a194a6d0249e7cc03e68ce2f840763dd5b7bd6fd2428fb5587b94953133bcb
    impl_worktree_dirty = False

| # | 预测 | 实测 | 判 |
|---|---|---|---|
| Q1 | passing **114,160**（= 113983 + 177，一个不多一个不少） | **114,160** | **HIT** |
| Q2 | unread_notcompared 0 | 0 | **HIT** |
| Q3 | failing / unverified / aborted 全 0 | 全 0 | **HIT** |
| Q4 | unmatched 六项全 0 | 六项全 0 | **HIT** |
| Q5 | native SUCCEEDED | SUCCEEDED | **HIT** |
| Q6 | validator 判 SIGNOFF_PASS | `verdict = SUCCEEDED`（reason=null） | **HIT** |
| Q7 | `accepted=6290 rejected=0` | `accepted=6290 rejected=0` | **HIT** |
| Q8 | `grep -cE "^ *Error:" fm.log` = 0 | 0 | **HIT** |
| Q9 | matched by user > 5,532 | 6,213 | **HIT** |

两轮预登记合计 **18 条里中 17 条**，唯一落空的是 run #1 的 P9 峰值内存
（押 4,000–15,000 MB，实测 3,959 / 3,960 MB）。

## ★钉点「被接受」不等于「生效」——fail-closed 只挡住了前一半★

run #3 的 fm.log 里有 **24 条 Warning**（不是 Error，所以 Q8 仍是 0）：

    12  Ignoring user match: no implementation object     (r:.../s0_can_go_REG_1_* 等)
    12  Ignoring user match: no reference object

机理：钉点发生在 **match 之前**，那时 impl 的 `red_q_s0_reg[1]` / `[2]`、
`tl_d_valid_q_reg[1]` 都还在，所以 `set_user_match` **被接受**（6290/0）；
但随后 `verification_merge_duplicated_registers = true` 把 impl 那几份完全相同的
副本合并掉了，指向被合并对象的 user match 就被 FM 丢弃 —— 于是
6290 条钉点只有 **6213** 条变成 `Compare points matched by user`。

**所以本轮加的 fail-closed 判据有明确的上限，写在这里免得被读成更强的东西**：

    它保证的是  ——  钉点名字在 elaborate 之后的设计里存在（拒一条就 exit 3）
    它不保证的是 ——  钉点最终被 match 采纳

后半段要另外一条判据（比如把 `Ignoring user match` 计数与预期数对账）。
本轮没做，**记为缺口**。当前之所以仍然安全，是因为
`Unmatched reference(implementation) compare points = 0(0)` ——
被丢弃的那些点全被 FM 自己按名字/函数配上了，一个点都没漏。
★但那还是「结果对」而不是「判据管住了」。★

## 结论

`LoadQueueReplay` 在 G1-canonical 基线上 **FM 等价证明通过**（signoff-strict，
allowlist=0，无 dont_verify、无 relaxed appvar、无假白名单），
唯一的加强项 vmucp 是**让 FM 多比 177 个点**，方向与放宽相反。

★但这是**条件绿**★：5 个 matched blackbox 里，`LqVAddrModule` 与 `AgeDetector_38`
本轮**尚未签核**（`FreeList_5` 据交接已签核 passing 724，我未独立复核）。
三者都是 `docs/g1_configured_universe.tsv` 里的独立 FM target（各自 `yes / new_target`），
属于"独立签核目标条件可黑盒"那一档，不是 golden 逻辑复用。

**receipt 本身没有字段承载这个依赖**：`green_child_closure_checks` 是空的，
因为那套机制只在 assembly 模式 + `verif/allow/<top>.json` 的 `class: green_child`
下才起作用，而本目标走的是 strict + matched blackbox。
依赖声明因此只存在于 `verif/ut/LoadQueueReplay/Makefile` 的注释和本文件里 ——
**这是工具侧的缺口，不是我判断它可以不挂**。集成者接手时请按条件绿处理。

---

# 剩下的缺口（我没修的，以及为什么没修）

## 1. `verif/ut/LoadQueueReplay/fm_pins_pre.tcl` 过不了 `scripts/test_fm_pins_wellformed.py`

四条，其中 **三条是我接手前就有的**（用 run #1 之前的文件版本复算过）：

| 判据 | 内容 | 我改之前 | 现在 |
|---|---|---|---|
| P1 | 第 11 行 `setup` | 有 | 有 |
| P1 | 第 49/50 行 `set_app_var` ×2 | 有 | 有 |
| P2 | 没有 fail-closed 的 `error` 路径 | 有（裸 catch，完全 fail-open） | **仍报**，但形态变了 |

**P2 这条要说清楚**：本轮已经把钉点改成 fail-closed，但用的是 `exit 3` 而不是
Tcl 的 `error`，而闸的正则找的是 `if {<比较>} { … error … }`。
`exit 3` 比 `error` **更强**（直接终止 fm_shell，run #2 实测 make_rc=3 就是这条路径），
所以这是**闸的形状与实现的形状不匹配**，不是真的 fail-open。
但我不打算"为了让闸变绿"去改一个已经出了证的钉点文件 ——
receipt 里记着 `fm_pins_pre.tcl` 的 sha256
（`42a194a6d0249e7cc03e68ce2f840763dd5b7bd6fd2428fb5587b94953133bcb`），
proof 之后再动它，文件和证据就对不上了。**留给下一轮：要么闸认 `exit`，要么改钉点文件并重跑。**

fail-closed 路径本身**已经双向负测过**（tclsh stub，不占 Formality，秒级）：

```bash
# 负例：让 6 条钉点被拒 -> 必须打 FM_PINS_ERROR 且 exit 3
# 正例：全部接受       -> 必须跑到结尾不 exit
```

    负例  LQR_PINS: accepted=6284 rejected=6
          FM_PINS_ERROR: first rejected pair = r:.../blockSqIdx_37_value_reg[0] <-> i:.../blockSqIdx_reg[37]\[value][0]
          NEGTEST: exit code = 3                       <- fail-closed 生效
    正例  LQR_PINS: accepted=6290 rejected=0，跑到结尾没有 exit

## 2. ★P1 的两个 `set_app_var` 是真问题，不只是闸的形状问题★

钉点文件里改了两个 appvar：

    set_app_var verification_assume_reg_init none
    set_app_var verification_set_undriven_signals BINARY

核过 `scripts/fm_eq.tcl`：**它自己一个都不设**，所以这两行是唯一的来源
（receipt 的 `entry_appvars_readback` 读回 `verification_assume_reg_init = "None"`、
`verification_set_undriven_signals = "BINARY"`，与之一致）。

- `verification_set_undriven_signals BINARY` 就是 Formality 的默认值，**是个空操作**。
- `verification_assume_reg_init none` **不是**：默认是 `Auto`，会让 FM 假定寄存器从初值
  出发，那是在**缩小**状态空间。改成 `none` 取消这个假定 ⇒ 方向上是**加强**。

CONVENTIONS 写得很清楚：★appvar 也是判据，改它之前必须双向负测★
（造"该抓到"的样本确认仍抓得到，**再**造"可能被遮"的样本确认没被放行）。
**这两行没有这样的负测，我也没补。** 补它要改证明输入 + 重跑（约一小时），
而且它本身值得一条独立的 lane（Rob 那次 `verification_set_undriven_signals`
的四跑实验就是先例）。**记为缺口，不要读成"已经论证过了"。**

## 3. 钉点「被接受」不等于「被采纳」（run #3 那 24 条 Warning）

见 run #3 那一节。缺一条把 `Ignoring user match` 计数与预期对账的判据。

## 4. 条件绿的依赖没有机器可读的载体

`LqVAddrModule` / `AgeDetector_38` 未签核，但 receipt 的
`green_child_closure_checks` 是空的（那套机制只在 assembly + `verif/allow/<top>.json`
的 `class: green_child` 下生效，strict + matched blackbox 走不到）。
依赖声明现在只在 Makefile 注释与本文件里，**人能读、机器读不到**。

---
---

# run #4：拆掉钉点文件里的两个 appvar 与 `setup`，重跑出证

## 起因：★我守的那个 `exit 3` 一行都执行不到，我的"负测"是空的★

另一条 lane 指出 `set_user_match` 从不抛 Tcl 异常。**我用两容器最小设计实测，它是对的**：

```tcl
read_verilog -r tiny.v ; set_top r:/WORK/tiny
read_verilog -i tiny.v ; set_top i:/WORK/tiny
set rc [catch {set_user_match r:/WORK/tiny/r_reg i:/WORK/tiny/r_reg} m]            ;# 名字都在
set rc [catch {set_user_match r:/WORK/tiny/r_reg i:/WORK/tiny/THIS_DOES_NOT_EXIST} m]  ;# 名字不在
```

    名字都在   -> catch_rc=0, 返回值 1
    名字不存在 -> catch_rc=0, 返回值 0, 并往 fm.log 写行首 `Error: Unknown name: ... (FM-036)`

⇒ 上一版 `if {[catch {set_user_match ...}]} {incr BAD} else {incr OK}` 里 **BAD 恒 0**，
末尾 `exit 3` **不可达**，日志里那个 `rejected=0` 是恒真的，不是测出来的。

★更该记的是我那个"双向负测"为什么没抓到它★：桩写的是 `error "Unknown name..."`，
**模拟的是一个不存在的行为**。于是它只证明了"如果它抛异常我能抓到"，而它不抛。
CONVENTIONS 要求"闸的负测必须双向"，这里补一条：**负测的桩必须照真命令的真行为建模，
否则负测本身就是空的**。这一条和"变异体必须自证改变了电路"是同一族。

## 两个 appvar：我先前的判断没有测量支撑，这次补测了

钉点文件里原有两行（`fm_eq.tcl` 自己一个都不设，所以它们是唯一来源）：

    set_app_var verification_assume_reg_init      none      # 默认 Auto
    set_app_var verification_set_undriven_signals BINARY    # 默认 binary:X

**(1) `BINARY` 不等于默认。** `get_app_var` 逐字读回：默认 `binary:X`，设成 `BINARY` 后读回
`BINARY`。★我先前报告里说它"就是默认值、是个空操作"，错了，这里更正。★

用 Rob 那套四跑探针（`evidence/rob-selfcompare-4aa8838b/undriven_safety/` 的原样源码）
扩成三档 × 两种 ref 实测（impl 固定为经典缺陷：`o2` 漏驱动）：

| ref 驱动 o2 | `binary:X`（默认） | `BINARY` | `0` |
|---|---|---|---|
| `a & b` 真逻辑 | FAILED(1) | FAILED(1) | FAILED(1) |
| `a & ~a` 死驱动 | FAILED(1) | FAILED(1) | ★SUCCEEDED —— 缺陷被遮★ |

探针**自证有分辨力**：它确实把 `0` 那档和另外两档分开了（复现 Rob 的结论）。
而 `BINARY` 与 `binary:X` 两档**行为完全相同** ⇒ 没有证据说它是放宽，也没有证据说它有用。

**(2) `verification_assume_reg_init none`：我造了两个探针，两个都分辨不出 `Auto` 与 `None`。**

    探针 A：ref/impl 各有一个从不被写的寄存器，初值 0 vs 1   -> Auto FAILED(1) / None FAILED(1)
    探针 B：ref 是从不被写的寄存器(初值 0)，impl 折成常量 0  -> Auto FAILED(1) / None FAILED(1)

★两个探针都**没有**自证分辨力，所以它们什么都没证明。★
我先前报告里写"方向上是加强"，那是**没有测量支撑的推断**，这里更正为：**未确定**。

## 处置：选 (c)，理由

**(c) = 把 `setup` 与两个 `set_app_var` 一并从钉点文件删掉，回到工具默认，并重跑出证。**

- 不选 (a)（挪进 Makefile/共享入口）：那是把一个**未经论证**的目标专属旋钮塞进共享配置，
  等于把问题换个地方放着；而且 `BINARY` 那档已实测与默认同行为，`none` 那档未确定，
  两个都没有"必须保留"的理由。
- 不选 (b)（保留 + 补负测 + 开 P1 豁免）：`P1` 按设计对谁都不豁免，开豁免要动闸；
  而且我补的负测结论是"一个与默认同行为、一个未确定"，**论证不出"必须保留"**，
  拿这种结论去申请豁免是本末倒置。
- (c) 的关键好处：**重跑同时就是那个决定性实验**。删掉之后如果结果逐位不变，
  就地证明了这两个旋钮对本目标是惰性的；如果结果变了，那才是真发现。
  ★而且 (a)/(b) 也一样绕不过重跑★（改的是证明输入），所以 (c) 不比它们贵。
- 顺带：既然要重跑，第二步那些守卫改动（`catch`→返回值、`exit`→`error`、
  期望数量、marker）就一并进这一跑。**一次真跑强于一次等价性论证**，
  所以我没有用 `pin_call_equiv` 免跑 —— 但我仍然做了那个比对（见下），当交叉验证。

★没有采用的做法：为了过闸把 appvar 悄悄删掉而不重跑。★ 那等于改了证明输入而证据没动。

## 守卫改动是"守卫专属"的（交叉验证，不用于免跑）

桩照真行为建模（返回 1/0、从不抛），跑两版并逐字节比对实际发生的调用序列：

    已出证版本 75e1d8be : 6290 行  sha256 32344c5ae0c260454d232c432547589f002af80da565a57464515c3da52008d0
    新版本               : 6290 行  sha256 32344c5ae0c260454d232c432547589f002af80da565a57464515c3da52008d0
    cmp -> 逐字节相同

新守卫的双向负测（这次桩建模的是**真行为**）：

    正例（全返回 1）  -> LQR_PIN_END n=6290 miss=0 expect=6290，不抛
    负例（让 6 条返回 0）-> 逐条打 LQR_PIN_FAIL，末尾 error
                          `LQR_PIN_MISS=LoadQueueReplay miss=6 first=r:.../blockSqIdx_37_value_reg[0] <-> ...`

## 期望数量 6290 是**我自己分析式手算**出来的，不是抄的

按 13 组循环逐组相乘（与桩执行计数两法互证）：

    ent 4 字段 x 72                288
    dataInLastBeat                  72
    s0_loadFreeSelMask 72 位        72
    missMSHRId+tlbHintId 72x5x2    720
    cause 72x11                    792
    debug_vaddr 72x50             3600
    blockSqIdx 72x(1+6)            504
    s1/s2 oldestSel 3x(2+7x2)       48
    lastReplay+coldCounter 3x5      15
    redirect 2x3x(1+1+1+8)          66
    tl_d blocking_REG 3x(1+4)       15
    s2 causes+mshr 3x(11+5)         48
    perf k=3->2 ; 其余 12 组 x4      50
    ----------------------------------
                                  6290

（转达里提到有人第一版心算成 1990。**差的正是 `debug_vaddr` 那 3600 那一整族** ——
1990 + 3600 = 5590 仍不对，说明不止漏一族。这也是为什么这个数必须两法互证。）

## run #4 预登记（★写在跑之前★）

| # | 量 | 预测 | 判 miss |
|---|---|---|---|
| R1 | `stats.passing` | **114,160**，与 run #3 **逐位不变** | 任何别的值 |
| R2 | unread / failing / unverified / aborted | 全 **0** | 任一 ≠ 0 |
| R3 | `unmatched` 六项 | 全 **0** | 任一 ≠ 0 |
| R4 | verdict | **SUCCEEDED** | 别的值 |
| R5 | `grep -cE "^ *Error:" fm.log` | **0** | > 0 |
| R6 | fm.log 里 | `LQR_PIN_END LoadQueueReplay n=6290 miss=0 expect=6290` | 别的值或没有这一行 |
| R7 | `scripts/test_fm_pins_wellformed.py` 对本文件 | **ok** | 仍 FAIL |

★R1 是这次的主判据★：如果 passing 变了，说明那两个 appvar 对本目标**不是**惰性的，
run #3 的绿就建立在一个没论证过的旋钮上 —— 那样的话这一跑才是真正重要的发现。
