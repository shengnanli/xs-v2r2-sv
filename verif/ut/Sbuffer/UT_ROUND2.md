# Sbuffer UT 第二轮（改指重写件 + 修复 fwd_valid_q 复位域之后）

改了闭包文件集（impl 侧 `SbufferData` 从 golden 改指重写件）又改了 RTL
（`fwd_valid_q` 的复位域），第一轮的六轮证据**不再绑当前字节**，全部重跑。

## 绑定的字节

```
7cbd887059a4530c53457e90849ceccfb6711d3919033895bca67c105dd39813  rtl/memblock/Sbuffer.sv
df1ec7f762638157da7a1063d566b67c89b9afd9097b7b4e5aed1c6c8937d98c  rtl/memblock/SbufferData.sv
859d8f9928ccb19ca0be4203378e3b10f2a543b9be7b0c773d3ff0c6a9921e13  verif/ut/Sbuffer/Makefile
bc04b7f72e782b57a1ae96e414a3610fbcac48e5555cf3cc0f6f5a4dfe73d793  verif/ut/Sbuffer/tb.sv
```

commit `74f0107f65db644825d4f25c755950423fbb84be`（跑前跑后 sha 各验一次，一致）

## 例化链确实变成了真对比

`make compile` 输出（rc=0）：

```
derive_ut_impl: Sbuffer -> Sbuffer_xs
derive_ut_impl: SbufferData -> SbufferData_xs
--- portlint: 1 pass, 0 fail, 0 skip ---
9 modules and 0 UDP read: sbuffer_pkg / Sbuffer_xs / sbufferdata_pkg /
  xs_SbufferData_core / SbufferData_xs / StorePfWrapper / Sbuffer / SbufferData / tb
```

即 golden 侧 `Sbuffer` → `SbufferData`（golden 字节），
impl 侧 `Sbuffer_xs` → **`SbufferData_xs`（重写件）**。
改指之前 impl 侧那条边指向的是 golden `SbufferData` —— 两侧同一份，UT 也白比。

`StorePfWrapper` 两侧共用同一定义（`RTL_GOLDEN_DEPS` 的语义），不改名、不派生。

## 六轮结果（3 seed × 2 initreg × 200,000 拍）

复跑：`make run SEED=<s> INITREG=<v>`（`v ∈ {0, random}`）

| seed | initreg | simv 命令行（日志内实录） | cycles | checks | errors | fill_cycle | 判 |
|---|---|---|---|---|---|---|---|
| 1 | 0 | `+ntb_random_seed=1 +ncycles=200000 +vcs+initreg+0` | 200000 | 25,940,070 | **0** | 59 | TEST PASSED |
| 1 | random | `+ntb_random_seed=1 +ncycles=200000 +vcs+initreg+random` | 200000 | 25,940,070 | **0** | 59 | TEST PASSED |
| 7 | 0 | `+ntb_random_seed=7 +ncycles=200000 +vcs+initreg+0` | 200000 | 25,944,100 | **0** | 28 | TEST PASSED |
| 7 | random | `+ntb_random_seed=7 +ncycles=200000 +vcs+initreg+random` | 200000 | 25,944,100 | **0** | 28 | TEST PASSED |
| 42 | 0 | `+ntb_random_seed=42 +ncycles=200000 +vcs+initreg+0` | 200000 | 25,942,280 | **0** | 42 | TEST PASSED |
| 42 | random | `+ntb_random_seed=42 +ncycles=200000 +vcs+initreg+random` | 200000 | 25,942,280 | **0** | 42 | TEST PASSED |

合计 **155,652,900** 次逐拍逐位比较，errors 全 0。
落盘日志 `mkrun_<seed>_<initreg>.log`（含 simv 命令行原文）与
`sim_<seed>_initreg{0,random}.log`（均 gitignore，不进版本库）。

### ★一个会吃掉证据的交互（实测踩到）★

跑完六轮之后跑 `bash mutants.sh 1 30000`，它按自己的规矩先删日志防串味
（`mutants.sh:` `rm -f sim_$SEED.log sim_${SEED}_initregrandom.log`）——
于是 **seed=1 那两份 `sim_1*.log` 被删掉了**。`mutants.sh` 的删除是对的
（`ut_common.mk:117-123` 记过：编不过却读到上一轮的 errors 会记成假 CAUGHT），
问题是它和验收轮**共用日志名字空间**。

**结论/建议**：验收轮的证据不要只依赖 `sim_<seed>*.log`。
本轮另存了一份 `mkrun_<seed>_<initreg>.log`，六轮都在，且日志里带 simv 命令行原文，
所以没有丢证据。要么像这样另存一份，要么让 mutants 用一个不在 {1,7,42} 里的 seed。

## 变异体：10/10 全 CAUGHT

复跑：`bash mutants.sh 1 30000`（每个变异先自证改到了电路文本，编译失败一律判 FAIL）

| MUT | VERDICT | ERRORS | 说明 |
|---|---|---|---|
| M1 | CAUGHT | 327,090 | PLRU 逐层下标位置参数 nsub 从 1 改成 0 |
| M2 | CAUGHT | 5,287 | coh 超时比较 `>=` 改成 `>`（G1 新增的 CSR 门限边界） |
| M3 | CAUGHT | 170,199 | `prio_enc16_deflast` 的「全 0 默认末项 15」改成默认 0 |
| M4 | CAUGHT | 28,215 | cohCount 优先级翻转：merge/alloc 清 0 抢在 +1 之前 |
| M5 | CAUGHT | 110,377 | forwardData 被 forwardMask 门控为 0 |
| M6 | CAUGHT | 411 | `io_sbFull` 用 ActiveCount==16 而不是 ValidCount==16 |
| M7 | CAUGHT | 59,078 | difftest bore 50/51 的 index 字段两路对调 |
| M8 | CAUGHT | 157,466 | alloc 时 ptag/vtag 覆盖优先级从 port1 改成 port0 |
| M9 | CAUGHT | 7,888 | mask 清除的 wvec 只比 id 低 4 位 |
| M10 | CAUGHT | 677,675 | `out_s1_valid` 两条更新语句互换 |

跑完自动还原并重编，`rtl/memblock/Sbuffer.sv` 的 sha256 回到
`7cbd887059a…5dd39813`（已核）。

## ★UT 的能力边界：这六轮抓不到本轮那条真 bug★

本轮 FM 抓到的 bug（`fwd_valid_q` 多了一个 golden 没有的异步复位，详见
`FM_PREDICTION.md` §6）**在上面六轮里一次都没响**，10 个变异体也没响。

机理不神秘：`fwd_valid_q` 是**逐拍无条件覆写**的，复位释放后一拍就与 golden 同步；
而 tb 的比较窗口要等暖机完成（`fill_cycle` 28~59 拍）才打开。
**差异只存在于复位期与复位后第一拍，正好在比较窗口之外。**

这正是 CONVENTIONS 那句「两轮 initreg 都绿 ≠ 复位域正确」的又一个实例。
区别在于：TLBFA 家族那次是靠**复位域结构闸**拦住的，这次是靠 **FM** 拦住的。
**把它记在这里，是为了让下一个人别把"六轮全绿 + 变异全抓"读成"复位域已验"。**

## `+vcs+initreg` 确实改变了待测状态（codex 0168 要求的自证）

不能只看命令行里有没有那个词。三层证据，全部可复跑（见 `FM_PREDICTION.md` §5）：

1. **UCLI 直读**两侧无复位存储：`+0` → `00`，`+1` → `ff`，`+12345` → 两侧不同的伪随机值。
2. **仿真自己印出来**了随机源：
   `Note-[VIUNRD] initreg using ntb_random_seed  +vcs+initreg using seed from +ntb_random_seed=1`
3. **扰动能传到被比较的输出**：用 tb 自带的 `+diag_cmp_now`（跳过暖机，只作诊断）
   同一份 simv 只改 initreg 取值，seed 7 → errors 30、seed 42 → errors 13，而 `+0` 全是 0。

★附带纠正一条口径★：`+ntb_random_seed=1` 是**退化种子** ——
它让 `+vcs+initreg+random` 把所有无复位位初始化成全 1，**两侧完全相同**，
所以 seed=1 的"random 轮"实际测的是「全 1 上电」，不是随机上电。
它与 `+0` 轮仍是两个不同的初值模式，不是白跑，但**不能叫"随机"**。
seed 7 / 42 的 random 轮才是真随机，且两侧取值不同。
`tb.sv` 里「在 `+vcs+initreg+random` 下两侧各自抽到不同的上电值 ⇒ 必然不等」
这句话，在 seed=1 下不成立；暖机窗口的必要性只由 seed 7/42 支撑。
