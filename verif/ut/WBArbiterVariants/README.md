# WBArbiter 家族 UT（13 个变体）

## ★先回答一个容易搞错的问题：`WBArbiter` 与 `RealWBArbiter` 是什么关系★

**不是同一个模块，也不是同一个家族的变体。** 判据全部来自 golden 实测，不是名字：

| | `WBArbiter`（13 变体） | `RealWBArbiter`（9 变体） |
|---|---|---|
| clock / reset 端口 | **有** | **没有** |
| 寄存器 | 2N+1 个（cancelCounter[N]×3 + isFull[N] + hasFull） | **0 个，纯组合** |
| payload | 单个 `addr`（5/7/8 位），或**完全没有 bits 端口** | `{xxWen, pdest, data}`，14..136 位 |
| 父模块 | `*RFWBCollideChecker` / `*RFReadArbiter` | `RealWBCollideChecker*` |
| 在做什么 | 寄存器堆**读口**仲裁 / 写回端口撞车检查 | 写回**数据通路**合流 |

两族**共有的**只有一半：优先级法则。实测它们逐字可化简为同一式子 ——
把 `WBArbiter` 的 `isFull ≡ 0`、`hasFull ≡ 0` 代进去：

```
golden WBArbiter    : io_in_2_ready = ~(fv0|fv1) & fv2 | ~v2      (fv = finalValid)
golden RealWBArbiter: io_in_2_ready = ~(v0|v1) | ~v2
fv ≡ v 时两者恒等（A & v | ~v ≡ A | ~v）
```

所以本仓的处理是**共享法则 + 各自的核**，不是"合成一个核"：
`rtl/common/xs_PriorityArbSelect.sv` 是两族共用的那一半（零重复），
`xs_WBArbiter_core` 在它外面套上反饥饿级，`RealWBArbiter` 的 wrapper 直接例化它
（本族的核体就是那条法则，不再套一层空壳）。

## 这个模块在做什么

两级：

1. **反饥饿级**（本族独有）：每一路一个 3 位 `cancelCounter`，被拒一拍 +1（饱和在 7），
   握手成功清 0；计数到 6 或 7（`cnt[2:1]` 全 1）该路置 `isFull`。只要有任何一路
   `isFull`（`hasFull`）且这一拍有 `isFull` 的路在请求，**这一拍只让 isFull 的路竞争**。
2. **优先级级**：编号小者先赢（共享件）。

## 差异维度矩阵（全部从 golden 实测）

| 变体 | golden 行数 | N | payload | 寄存器位数 | 例化者 |
|---|---|---|---|---|---|
| `WBArbiter` | 219 | 3 | **无** | 13 | IntRFWBCollideChecker.sv |
| `WBArbiter_1` | 251 | 4 | **无** | 17 | IntRFWBCollideChecker.sv |
| `WBArbiter_2` | 186 | 2 | **无** | 9 | FpRFWBCollideChecker.sv / IntRFWBCollideChecker.sv / V0RFWBCollideChecker.sv / VfRFWBCollideChecker.sv |
| `WBArbiter_3` | 152 | 1 | **无** | 5 | FpRFWBCollideChecker.sv / IntRFWBCollideChecker.sv / V0RFWBCollideChecker.sv / VfRFWBCollideChecker.sv / VlRFWBCollideChecker.sv |
| `WBArbiter_30` | 190 | 2 | `addr[7:0]` | 9 | FpRFReadArbiter.sv / IntRFReadArbiter.sv |
| `WBArbiter_33` | 227 | 3 | `addr[7:0]` | 13 | IntRFReadArbiter.sv |
| `WBArbiter_38` | 155 | 1 | `addr[7:0]` | 5 | FpRFReadArbiter.sv / IntRFReadArbiter.sv |
| `WBArbiter_52` | 190 | 2 | `addr[6:0]` | 9 | VfRFReadArbiter.sv |
| `WBArbiter_55` | 227 | 3 | `addr[6:0]` | 13 | VfRFReadArbiter.sv |
| `WBArbiter_58` | 155 | 1 | `addr[6:0]` | 5 | VfRFReadArbiter.sv |
| `WBArbiter_64` | 190 | 2 | `addr[4:0]` | 9 | V0RFReadArbiter.sv / VlRFReadArbiter.sv |
| `WBArbiter_65` | 227 | 3 | `addr[4:0]` | 13 | V0RFReadArbiter.sv / VlRFReadArbiter.sv |
| `WBArbiter_66` | 155 | 1 | `addr[4:0]` | 5 | V0RFReadArbiter.sv / VlRFReadArbiter.sv |

结论：**13/13 全部落在同一个核**（`xs_WBArbiter_core`）。只有 2 个维度：
仲裁宽度 `N`（1/2/3/4）与 payload 位宽 `PW`（0 / 5 / 7 / 8）。
`PW=0` 的 8 个变体由 wrapper 传 `PW=1`、`in_bits` 接 0、`out_bits` 悬空
（那条 1 位多路选择没有任何读者，不进任何输出锥）。

## ★可达性分析：哪些路"够得着" isFull★

把 golden 的次态方程原样搬进脚本做**穷举**可达性分析（脚本 `scripts/wbarbiter_reachability.py`，`--check` 把下表变成机器闸），
结果决定了 tb 的覆盖要求，也决定了哪些是 golden 自己的死逻辑：

| N | 可达状态数 | `isFull_i` 可达 | `cancelCounter_i` 上界 | 饱和分支（7 又被拒） |
|---|---|---|---|---|
| 1 | **1**（全 0） | 都不可达 | 0 | 不可达 |
| 2 | 9 | 只有第 1 路 | 第 0 路 **1**，第 1 路 7 | 不可达 |
| 3 | 133 | 全部 | 全 7 | 可达 |
| 4 | 1479 | 全部 | 全 7 | 可达 |

两条由此得到的结论：

- **N=1 的四个变体（`_3`/`_38`/`_58`/`_66`）那 5 位寄存器是死逻辑。**
  因为 `finalValid_0 = v0 & (~hasFull | ~(v0 & isFull0) | isFull0)` 恒等于 `v0`
  （`isFull0=1` 时第三项真，`=0` 时第二项真），所以 `in_ready` 恒 1、永不被拒。
  golden 有它们，本仓照样有 —— **不许"优化掉"**。
- **最高优先级那一路永远饿不着**（N≤2 时 `isFull_0` 根本不可达）：它要攒够 6 次被拒，
  而每一次被拒都需要有别的路处于 isFull，制造那个 isFull 又必须让第 0 路赢并握手，
  握手就把它的计数清零了。N≥3 时靠"多路同时 isFull 连续排队"才够得着。

tb 把这张表**两个方向都用上**：该到的必须到（N≥3 逐路 isFull、饱和分支），
不该到的必须不到（N=1 三个寄存器恒 0、N=2 的 `isFull_0` 恒 0 且 `cnt_0 ≤ 1`、
N≤2 不得出现饱和分支）。

tb 里为此专门有一种激励形状 **「饥饿猎手」**：除第 0 路外全程请求，而第 0 路
**只在 golden 报 `hasFull` 的那一拍请求**。这是唯一能把最高优先级那一路的计数
累加到 6 的形状 —— 随机激励跑 200k 拍一次都到不了（实测：换上这个形状之前
`isFull_0` 覆盖是 0/N，换上之后 N≥3 全满）。另外所有形状都**连续保持 1..40 拍**，
逐拍换形状的话状态机根本攒不起计数。

## 判别力负测

`make mutants` 10 条 CATCH/MISS_FM + 1 条空变异对照。其中两条是
**"UT 看不见、只有 FM 看得见"**：

- `M7` 异步复位改同步复位（经典款）；
- `M9` 把 starving 判据里的 `has_full_q` 换成 `|is_full_q` —— 这两个信号在
  **复位可达的状态空间里恒等**（两个寄存器同一复位值、次态都来自同一个 `is_full_d`），
  UT 永远看不见；FM 把它们当两个自由寄存器比，当场报不等价。
  它和「异步/同步复位」是同一类：**判据差在不可达状态上**。
  两条都在 `python3 mutants.py --fm` 里有对应条目实证。

## 跑法

```
make run SEED=1 INITREG=random       # 3 seed × 2 initreg × 200k 拍
make fm                              # 13 个变体逐个 FM
make mutants ; python3 mutants.py --fm
bash ../../../scripts/run_proof.sh WBArbiterVariants <变体名>...
```
