# CSA3_2 位宽变体家族 UT —— 覆盖证据与变异测试记录

对位的 golden 顶层（9 个）：`CSA3_2_{3956,3960,3962,3987,3988,3992,4017,4111,4173}`。

形制照 BusyTable 家族：**一个参数化核 + 每变体一个薄 wrapper，核体绝不复制**。
核 = `rtl/backend/CSA3_2.sv` 的 `xs_CSA3_2_core #(.WIDTH)`（与基态 `CSA3_2` / `C32`
共用同一份）。9 个薄 wrapper 与本 UT 的 `tb.sv` 由 `verif/ut/CSA3_2Variants/gen.py` 生成。

★生成物防腐★：`gen.py` 放在 `verif/ut/*/gen.py` 这个位置是**有意的** ——
`scripts/test_gen_idempotent.py` 会自动扫这个 glob，在 detached worktree 里重跑并要求
产物逐字不变。于是本家族自动进闸，不需要改 `scripts/gate_all.sh`（那不在本 lane 所有权内），
也不会重演本仓「生成物进库却没有闸看着它」的老毛病。

## ★位宽与形态：逐个从 golden 实测，不是照抄清单★

不能假设"同名前缀 = 纯参数变体"。这里用的判据比读端口更强：**把「逐位独立全加器」
模板按位宽重建成文本，与 golden 模块体逐字节比较** —— 对角线错位、进位左移、
跨位耦合，任何一种都会让逐字节比较当场失败。

| 变体 | 位宽 | 逐字节同模板 | always/reg/子实例 | golden 里谁例化 |
|---|---|---|---|---|
| CSA3_2_3988 | 8 | ✓ | 0 / 0 / 0 | SelBlock_v4 ×4 |
| CSA3_2_3992 | 9 | ✓ | 0 / 0 / 0 | SpecBlock_v4 ×24 |
| CSA3_2_3956 | 10 | ✓ | 0 / 0 / 0 | SRT16DividerDataModule ×4 |
| CSA3_2_4017 | 11 | ✓ | 0 / 0 / 0 | IterBlock_v4 / _4 / _6 各 ×1 |
| CSA3_2_3962 | 13 | ✓ | 0 / 0 / 0 | SRT16DividerDataModule ×25 |
| CSA3_2_3987 | 22 | ✓ | 0 / 0 / 0 | IterBlock_v4 ×2 |
| CSA3_2_4111 | 38 | ✓ | 0 / 0 / 0 | IterBlock_v4_4 ×2 |
| CSA3_2_3960 | 68 | ✓ | 0 / 0 / 0 | SRT16DividerDataModule ×2 |
| CSA3_2_4173 | 70 | ✓ | 0 / 0 / 0 | IterBlock_v4_6 ×2 |

**9/9 全等**。五个端口在每个变体内宽度一致（无"输入宽输出窄"之类的不对称）。
全族**纯组合、零寄存器、零 always 块、零子实例**，无 clock 无 reset 端口 ——
所以本族没有复位域可言，这是结论不是省略。

它们全部属于 **DivUnit 的 Radix-16 SRT 除法器**（`SRT16DividerDataModule` 及其
`IterBlock_v4` / `SelBlock_v4` / `SpecBlock_v4` 助手），与乘法阵列
`ArrayMulDataModule` 用的那三个压缩器不在同一棵树上。

★注意不要并进来★：`CSA3to2` / `CSA4to2` 及其编号变体是**另一个 Chisel 类**——
端口叫 `io_in_a/b/c`、`io_out_sum/car`，而且进位输出自带左移一位。不是本族。

## 复跑

```bash
cd verif/ut/CSA3_2Variants
python3 gen.py                      # 幂等；产物已进库
for ir in 0 random; do for s in 1 7 42; do make run SEED=$s INITREG=$ir; done; done
make fm                             # 9 个变体逐个 FM
```

## 覆盖证据：逐位穷举（不是抽样）

本族每一位是**互不相干**的全加器，位与位之间无进位链 ⇒ 每个位位置的输入空间只有
8 种 `(a,b,c)`。向量级穷举在 W=70 时是 2^210，不可能；但**逐位走遍 8 种组合对
逐位独立的函数就是穷举证明**。tb 因此逐位统计，并把判据写进 `TEST PASSED`：

```
--- coverage: 每个变体每一位是否见过全部 8 种 (a,b,c) ---
  variant[0] W=10 : 10/10 位达成 8/8 组合
  variant[1] W=68 : 68/68 位达成 8/8 组合
  variant[2] W=13 : 13/13 位达成 8/8 组合
  variant[3] W=22 : 22/22 位达成 8/8 组合
  variant[4] W=8  : 8/8   位达成 8/8 组合
  variant[5] W=9  : 9/9   位达成 8/8 组合
  variant[6] W=11 : 11/11 位达成 8/8 组合
  variant[7] W=38 : 38/38 位达成 8/8 组合
  variant[8] W=70 : 70/70 位达成 8/8 组合
```

六轮（seed 1/7/42 × INITREG 0/random）× 200k 拍全部 `checks=3600000 errors=0`。
（本族零寄存器，initreg 对它没有作用面 —— 这是结论，不是免跑两轮的理由，两轮照跑。）

## 变异测试（注入真 bug，不进库）

| 变异 | 注入内容 | 结果 |
|---|---|---|
| `csa_diag`  | 给 `CSA3_2_4111` 的进位输出**左移一位**（对角线错位） | **CAUGHT** errors=1990 |
| `csa_width` | 把 `CSA3_2_4111` 的 `WIDTH` 设成 37（差一位，高位悬空） | **CAUGHT** errors=2522 |

这两条正是"以为是纯参数变体"最可能踩的两种坑：**移位**与**位宽差一**。
逐位覆盖判据加上双例化比对能把它们当场打出来。
