# SbufferData UT —— 覆盖证据与变异测试记录

对位的 golden 顶层：`SbufferData`（2064 端口）。重写件：`rtl/memblock/SbufferData.sv`。
`sbd_bridge.sv` 是机械桥接件（4157 行，两侧各 2048 个扁平输出打包成向量），
由 `scripts/gen_sbufferdata.py --bridge` 生成，**勿手改**。

生成物防腐：`python3 scripts/gen_sbufferdata.py --check` 同时校验
`rtl/memblock/SbufferData.sv` 的两段派生区与本桥接件，任一过期即 rc=1。
两条判据都做过负测（各改一条连线 → rc=1，还原 → rc=0）。
★这条闸**还没接进 `scripts/gate_all.sh`**★ —— 那个文件不属于本 lane，
由集成者决定是否在生成器列表里加一行 `scripts/gen_sbufferdata.py`。

## 复跑

```bash
cd verif/ut/SbufferData
for ir in 0 random; do for s in 1 7 42; do make run SEED=$s INITREG=$ir; done; done
```

## golden 行数构成（先量清膨胀机制，再动手）

`SbufferData.sv` 24872 行按行段分类：

| 行段 | 行数 | 占比 | 是什么 |
|---|---|---|---|
| L1-86 | 86 | 0.3% | firtool 宏样板头 |
| L87-2153 | 2067 | 8.3% | 端口表（**2064 个端口**：1024 dataOut + 1024 maskOut + 16 输入） |
| L2154-11481 | 9328 | 37.5% | 声明 + 组合 wire（2224 个 `reg` + 2176 个 `wire`，其余是多行表达式的续行） |
| L11482-15771 | 4290 | 17.2% | `always @(posedge clock)` —— **不复位域** |
| L15772-19345 | 3574 | 14.4% | `always @(posedge clock or posedge reset)` —— 复位域 |
| L19346-22822 | 3477 | 14.0% | `initial` randomize —— 仿真专用，不是逻辑 |
| L22823-24870 | 2048 | 8.2% | 1024+1024 条输出 `assign` |

整体归一化后**唯一行模板 695 条**。

膨胀机制是**按 [行][vword][字节] 三重复制**：1024 个字节单元 + 1024 个掩码位，
每个都独立占一个 reg、一个端口、一条 assign、一条 always 语句。真正的"设计"只有
一段：s1 使能 → s2 缓冲 → 按 mask/vword/wline 算 write_byte → 写字节 + 更新掩码。
重写件手写区 277 行（另有 4098 行是 wrapper 的 2048 端口 + 2048 连线，
由 `scripts/gen_sbufferdata.py` 机械派生）。

## 结构对账（跑 UT 之前先把"形状"对上）

| 量 | golden 实测 | 重写件 |
|---|---|---|
| always 块 | **恰好 2 个** | 3 个 always_ff（划分不同，复位域相同，见下） |
| `always @(posedge clock)`（**不复位**）里的寄存器 | `data`×1024(8位) + `line_write_buffer_{data,wline,mask,offset}`×32 | `data` + `s2_{data,wline,mask,vword}`（均 32 份） |
| `always @(posedge clock or posedge reset)`（**复位到 0**）里的寄存器 | `mask`×1024(1位) + `line_mask_clean_flag_last_REG`×16 + `sbuffer_in_s2_line_wen_last_REG`×32 | `mask` + `line_mask_clean`×16 + `s2_line_wen`×32 |

★`data` 不复位、`mask` 复位★ 是本模块的关键复位域事实（Chisel 侧 `Reg(...)` vs
`RegInit(...false)`）。golden 侧复跑：

```bash
G=/home/eda/xs-env/G1-canonical/golden-rtl/SbufferData.sv
grep -nE '^  always' $G
#   11482:  always @(posedge clock)                 ← 不复位域
#   15772:  always @(posedge clock or posedge reset) ← 复位域
sed -n '11482,15771p' $G | grep -oE '^\s+\w+\s*<=' | sed -E 's/_[0-9]+//g;s/[ <=]//g' | sort | uniq -c
#   2048 data / 32 line_write_buffer_data / 32 line_write_buffer_mask
#   32 line_write_buffer_offset / 32 line_write_buffer_wline
sed -n '15772,19345p' $G | grep -oE '^\s+\w+\s*<=' | sed -E 's/_[0-9]+//g;s/[ <=]//g' | sort | uniq -c
#   32 line_mask_clean_flag_last_REG / 2048 mask / 64 sbuffer_in_s2_line_wen_last_REG
```

（`data`/`mask` 各 2048 行赋值 = 1024 个寄存器 × 两条路径：`data` 是 if/else-if 两个
写口，`mask` 是复位段 + 次态段。）

★写缓冲是"每口每行各一份"共 32 份★，不是每口一份 —— golden 的
`line_write_buffer_data_0..15` 与 `_0_1.._15_1` 就是 32 组。合并成 2 组在仿真里看不出
差别（同口同拍的 data/mask 本来就相同），但那是 Predictor 那种"多份结构写成一份"的
形态，FM 会大面积失配。变异 `sbd_shared` 就是这一条。

## 更新优先级（对着 golden 核过）

1. **data 字节**：写口 1 压过写口 0（golden `if (write_byte_1024) … else if (write_byte)`）。
2. **mask 位**：`wb1 | wb0 | ~clean & mask` —— **写压过清**。
3. 同口多热 wvec 命中多行：32 份缓冲各自独立，互不影响。

## 覆盖证据（seed=1 / INITREG=random / 200k 拍的 tb 自报）

```
stimulus modes 0..7        : 8/8,   min hits = 24778
vwordOffset[1:0] 0..3      : 4/4,   min hits = 57520     <- vword 边界
lines 0..15 written        : 16/16, min hits = 100633    <- 行边界
byte-mask classes 0/1/n/all: 4/4,   min hits = 22187     <- 全0 / 单点 / 稀疏 / 全1
whole-line writes (wline)  : 48159
both ports active          : 132539
two ports -> SAME byte     : 45831    <- 写口优先级冲突（定向；纯随机极少撞上）
write vs maskFlush 同行    : 46709    <- 写 vs 清掩码冲突（定向）
idle cycles (hold)         : 26215    <- 不复位寄存器"使能低时保持"
cycles maskOut gained bits : 103680
cycles maskOut lost bits   : 67639
mid-test reset pulses      : 88       <- 复位域判别力来源
checks=399992 errors=0
```

这些判据写进了 `TEST PASSED` 的条件里（最低水位 >0 / >100），覆盖不到位不给绿灯。

六轮（seed 1/7/42 × INITREG 0/random）全部 `checks=399992 errors=0`，逐轮实测值见
各 `run_<seed>_<initreg>.log`。

## 变异测试（注入真 bug，不进库）

| 变异 | 注入内容 | 结果 |
|---|---|---|
| `sbd_prio`   | data 写口优先级反转（写口 0 压过写口 1） | **CAUGHT**（errors=5574） |
| `sbd_clean`  | mask 次态改成"清压过写"（`~clean & (wb1|wb0|mask)`） | **CAUGHT**（errors=4337） |
| `sbd_shared` | 32 份写缓冲退化成每口 1 份（`[p][l]` → `[p][0]`） | **CAUGHT**（errors=9619） |
| `sbd_reset`  | ★给 `data` 加异步复位★（golden 的 data 不复位） | **CAUGHT**（errors=43） |

### 为什么 `sbd_reset` 抓得到（这条最容易假绿）

`data` 不复位 ⇒ 上电是垃圾值，`+vcs+initreg+random` 会给两侧**各自不同**的随机值，
所以 tb 必须先暖机（一发 `wvec=0xFFFF, wline=1` 的整行写，一拍写满全部 1024 字节）
才能比 `dataOut`。**暖机之后再比初值就什么也证明不了**——这正是
CONVENTIONS 里"两轮都绿 ≠ 复位域正确"说的情形。

本 tb 的做法是：暖机把两侧 data 对齐到同一份**已知非零**值之后，
在测试中途随机拉 2 拍 `reset`。golden 的 `data` 不复位 ⇒ 原样保持；
带复位的变异件 ⇒ 清零，当场失配。这条判别力**与 initreg 取值无关**，
因为比的是"复位前后 data 有没有变"，不是上电值。

另有一条副产品：因为重写件把 `data` 单独放在一个 `always_ff` 里，
最早那版 `sbd_reset` 变异（把 `data <= '0` 加进复位块）**直接编不过**
（`Illegal combination of procedural drivers`）。也就是说这个写法本身就让
"顺手给 data 加个复位"变成编译错误而不是静默 bug。正式的变异是把 `data` 那个
`always_ff` 整个改成带异步复位，才跑得起来。

变异脚本位置（本次会话的 scratchpad，未进库）：`…/scratchpad/mut/run_mutant.sh` + `p_sbd_*.py`。
