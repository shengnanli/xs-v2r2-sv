# RRArbiterInit 家族 UT（15 个变体）

golden 里同一份 Chisel（rocket-chip `LockingRRArbiter`(count=1)）生成了 15 个模块。
本 UT 一口气双例化全部 15 个变体逐拍比对；FM 逐变体各出一份 receipt。

## 差异维度矩阵（全部从 golden 端口表实测，见 gen.py 的解析）

| 变体 | golden 行数 | N | payload W / 字段数 | chosen 位宽 | in_ready | out_ready | io_chosen | 例化者 |
|---|---|---|---|---|---|---|---|---|
| `RRArbiterInit` | 216 | 8 | 36 / 1 | 3 | 无 | 有 | 有 | Bitmap.sv |
| `RRArbiterInit_1` | 298 | 6 | 127 / 7 | 3 | 无 | 有 | 有 | LLPTW.sv |
| `RRArbiterInit_4` | 264 | 6 | 81 / 5 | 3 | 无 | 有 | 有 | LLPTW.sv |
| `RRArbiterInit_5` | 393 | 16 | 50 / 1 | 4 | 有 | 无（常量 1） | 无 | PrefetchFilter.sv |
| `RRArbiterInit_6` | 395 | 16 | 48 / 1 | 4 | 有 | 无（常量 1） | 有 | PrefetchFilter.sv / MutiLevelPrefetchFilter.sv |
| `RRArbiterInit_7` | 666 | 32 | 50 / 1 | 5 | 有 | 无（常量 1） | 无 | MutiLevelPrefetchFilter.sv |
| `RRArbiterInit_8` | 514 | 16 | 54 / 4 | 4 | 有 | 有 | 有 | MutiLevelPrefetchFilter.sv |
| `RRArbiterInit_9` | 354 | 16 | 53 / 2 | 4 | 无 | 无（常量 1） | 有 | MutiLevelPrefetchFilter.sv |
| `RRArbiterInit_11` | 636 | 16 | 117 / 7 | 4 | 有 | 有 | 无 | LoadQueueUncache.sv |
| `RRArbiterInit_12` | 171 | 3 | 40 / 2 | 2 | 有 | 有 | 无 | PTWNewFilter.sv |
| `RRArbiterInit_13` | 687 | 16 | 79 / 9 | 4 | 有 | 有 | 无 | MMIOBridge.sv |
| `RRArbiterInit_14` | 393 | 16 | 50 / 1 | 4 | 有 | 无（常量 1） | 无 | PrefetchReqBuffer.sv |
| `RRArbiterInit_15` | 547 | 16 | 94 / 5 | 4 | 有 | 有 | 无 | PrefetchReqBuffer.sv |
| `RRArbiterInit_16` | 1181 | 4 | 383 / 94 | 2 | 有 | 有 | 无 | SinkC.sv |
| `RRArbiterInit_20` | 618 | 5 | 151 / 28 | 3 | 有 | 有 | 有 | TL2CHICoupledL2.sv |

结论：**15/15 全部落在同一个核**（`xs_RRArbiterInit_core`，rtl/common/RRArbiterInit.sv）。
依据是上表只有 6 个维度在变，且每一个都能由参数或 wrapper 接线吸收：

1. `N`（3/4/5/6/8/16/32）→ 核参数；
2. payload（36..383 位、1..94 个字段）→ 打平成核参数 `W`，wrapper 负责拼/拆；
3. `chosen` 位宽 = `$clog2(N)`，不是独立维度（脚本已 assert 15/15 相符）；
4. 无 `in_ready` 输出 → wrapper 把核的 `in_ready` 悬空；
5. 无 `out_ready` 输入 → wrapper 接 `1'b1`（golden 里就是被常量 1 折掉的）；
6. 无 `io_chosen` 输出 → wrapper 把核的 `chosen` 悬空。

另有两处 **golden 自己的不对称**，由 wrapper 逐字照抄，不许"补齐"：

- `RRArbiterInit_20.bits_size`：只有 `io_in_4` 有真端口，其余各路在 golden 的选择表里是常量 `3'h6`；
- `RRArbiterInit_20.bits_tgtID`：只有 `io_in_4` 有真端口，其余各路在 golden 的选择表里是常量 `11'h0`；
- `RRArbiterInit_11.bits_id`：没有任何输入来源，golden 用一张「下标即取值」的 7 位常数表按 `chosen` 取（等价于零扩展），wrapper 照抄该结构。

还有一条实测结论：`RRArbiterInit_5` 与 `RRArbiterInit_14` 的 golden 文件**逐字节相同**
（`diff <(sed s/_5/XX/ RRArbiterInit_5.sv) <(sed s/_14/XX/ RRArbiterInit_14.sv)` 为空），
firtool 没有把它们 dedup 掉；本仓照样给两个薄 wrapper、各证一次。

## 非 2 的幂的 N：选择表怎么补

N=3/5/6 时 `chosen` 的取值域比请求方多。golden 把多出来的表项**填第 0 路**（实测
`RRArbiterInit_12` 的 `{in0, in2, in1, in0}`、`_4` 的 8 项表尾两项、`_20` 的尾三项），
核里照抄这条补法。

★这一条**不要**拿"FM 不做可达性分析"去解释★ —— 实测不成立：`mutants.py` 的 F3
把填法改成填 0，FM 照样 `native SUCCEEDED / failing 0`。因为 `chosen` 不是自由变量，
它的取值域由逻辑本身决定（只会被赋 0..N-1），这些表项在任何输入组合下都选不中。
所以照抄是**零成本的忠实**，不是 FM 逼的；那条规矩真正管的是自由寄存器 `lastGrant`
（F1 实证：异步复位改同步复位，UT 全绿而 FM 当场 failing 2）。

## 判别力负测（双向）

`make mutants` 往核里逐个注入真 bug，要求 UT 全部抓到；`make mutants-cov` 反过来
考覆盖闸自己（跑 20 拍，errors=0 但覆盖不全 —— 闸必须判 TEST FAILED）；
`make mutants-fm` 在 FM 侧做同样的两个方向，其中一条是**只有 FM 看得见**的
复位域变异（异步复位改同步），另一条是**不该报警的对照**。表与口径见 mutants.py。

## 跑法

```
make run SEED=1 INITREG=random     # 3 seed × 2 initreg × 200k 拍
make fm                            # 15 个变体逐个 FM
make mutants && make mutants-cov   # 判别力负测（两个方向）
bash ../../../scripts/run_proof.sh RRArbiterInitVariants <变体名>...
```
