# 整芯片 SimTop 仿真对拍：使用说明（只依赖 main 检出）

本文是 `verif/sim/run_fcb.sh` 的复现入口：从**任意路径的 main 检出**出发，编出 golden / impl 两侧 simv，
跑 smoke / coremark / dhrystone / cputest，逐拍比对两侧提交 trace。判据与 2026-10-18 的结果记录在
`docs/lanes/fullchip-bench.md`（跑前登记 + 结果，本文不改它的判据，只引用其 §5 的数字）。

- **golden 侧**：G1 golden 整芯片 RTL（原版 SimTop）。
- **impl 侧**：SimTop → XSTop 里只把 `XSTile`（核 + L2）换成 `rtl/` 的重写版，核外件保持 G1 golden；
  清单由 `verif/sim/xstile_sim_filelist.py` 机械生成（`run_fcb.sh` 以 `XSTILE_ONLY=1` 调用），
  `-y` 库目录只放打补丁的 SimTop.sv，漏件当场编译报错，不可能静默回落 golden。
- 仿真顶层是 difftest 的真实 testbench **`tb_top`**（`tb_top → SimTop → XSTop → XSTile`）。
  核对：两侧 build.log 的 vcs 命令行都是 `vcs +define+DIFFTEST -full64 +v2k -top tb_top ...`
  （`difftest/vcs.mk` 的 `VCS_TOP = tb_top`）。XSTile 单独编译（`-top XSTile`）是另一件事，见 §6。

## 1. 外部依赖（仓库外，只读）

脚本里**没有任何 `wt-*` worktree 路径**；仓库内的东西（rtl/、docs/xstile_srcmap.tsv、脚本）都按脚本所在检出定位
（`SV_HOME=$(dirname $0)/../..`）。仓库外的依赖全部可用环境变量改：

| 依赖 | 默认路径 | 环境变量 | 说明 |
|---|---|---|---|
| G1 golden RTL | `/home/eda/xs-env/G1-canonical/golden-rtl` | `GOLDEN_RTL` | 只读。`SimTop.sv` sha256 `2ce638a35d378fc272b76491c85b7e2cb1533e65b9eaeaff0359205ad5e95b55` |
| 原版 difftest | `/home/eda/xs-env/sim-work/difftest`（OpenXiangShan/difftest `4f37f7e`） | `STOCK_SIMW` / `STOCK_DIFFTEST` | 每个工作区 `cp -a` 一份私有副本再打补丁，原版不动 |
| difftest DPI 胶水 | `$STOCK_SIMW/regen/build/generated-src` | （随 `STOCK_SIMW`） | 与 G1 同配置重生成；`run_fullchip.sh` 的 `check_dpic` 门禁（DPI 函数集合 == golden `GatewayEndpoint.sv` 例化集合）。缺了会自动 `make sim-verilog` 重生成（~20 分钟，需 `XS_HOME` + JDK 17 `/home/eda/xs-env/toolchain/jdk-17.0.13+11`） |
| XiangShan 检出 | `/home/eda/xs-env/XiangShan` | `XS_HOME` | 用到 `ready-to-run/riscv64-nemu-interpreter-so`（NEMU ref）、`build/{chisel_db,constantin,perfCCT}.*`（difftest 编译要的 C++ 桩） |
| NEMU ref so | `$XS_HOME/ready-to-run/riscv64-nemu-interpreter-so` | `REF_SO` | sha256 `7b5a235c9fa3406a82569d844e2d8c82201c1523c308f45956b84d3813d127cd` |
| VCS / Verdi | `/home/eda/app/synopsys/{vcs,verdi}/W-2024.09-SP1` | `PATH`、`VERDI_HOME` | **怪癖：必须 `VCS_ARCH_OVERRIDE=linux` 且配 `-full64`**（脚本已设；difftest 的 vcs.mk 自带 `-full64`）。gcc 8.5.0 |
| nexus-am（cputest、dhrystone 源） | `/home/eda/xs-env/nexus-am`（`196ebf4d`） | `AM_HOME`、`CT_DIR` | cputest 默认读 `$AM_HOME/tests/cputest/build/*-riscv64-xs.bin` |
| RISC-V 工具链 | `$XS_HOME/riscstar-toolchain-15.2-r1-x86_64-riscv64-none-linux-gnu/bin` | `PATH` | 只有 `riscv64-none-linux-gnu-`，nexus-am 默认找 `-unknown-`，须显式 `CROSS_COMPILE=` |

其它运行参数：`RAM_SIZE`（默认 `8589934592`，**必须给**，默认 8TB 会让 NEMU init_mem 崩）、`VCS_JOBS`（默认 16）。

## 2. 负载（路径、来源、sha256）

| 负载 | 来源 | sha256 |
|---|---|---|
| `flash_recursion_test.bin`（smoke） | `$XS_HOME/ready-to-run/`，原封不动 | `84c4156d673d71606a3c33f3abacf9db7b901a8746ffbf17dc4eda4d931dbb75` |
| `coremark-2-iteration.bin` | `$XS_HOME/ready-to-run/`，原封不动（ITERATIONS=2） | `c764afb8bfd69542620a4794b858867dd1e455efaac56c28eb477f1732f83e8e` |
| `dhrystone.bin` | nexus-am `apps/dhrystone` 重建，**只改一个常量** `NUMBER_OF_RUNS` 500000→1000（补丁 `verif/sim/results/dhrystone_dry.c.patch.txt`；改好的源 `/home/eda/xs-env/sim-fast/workloads-src/dhrystone/`） | `3139eaedacfaa1f81b2c9fa2c9d8637e5b0b1383beba52a72c8834409a87d2b0` |
| cputest ×33 | nexus-am `tests/cputest` 现编 | — |

已就绪的副本：`/home/eda/xs-env/sim-fcb/workloads/`（上表三个 + microbench，只读）。从源重建：

```bash
export AM_HOME=/home/eda/xs-env/nexus-am NOOP_HOME=/home/eda/xs-env/XiangShan
export PATH=/home/eda/xs-env/XiangShan/riscstar-toolchain-15.2-r1-x86_64-riscv64-none-linux-gnu/bin:$PATH
# cputest 33 个 -> $AM_HOME/tests/cputest/build/*-riscv64-xs.bin
make -C $AM_HOME/tests/cputest ARCH=riscv64-xs CROSS_COMPILE=riscv64-none-linux-gnu-
# dhrystone（1000 runs）：拷 apps/dhrystone，按 verif/sim/results/dhrystone_dry.c.patch.txt 改 dry.c 那一行
# （已改好的源就是 /home/eda/xs-env/sim-fast/workloads-src/dhrystone/），然后
make -C <dhrystone 源目录> ARCH=riscv64-xs CROSS_COMPILE=riscv64-none-linux-gnu-
# -> <源目录>/build/dhrystone-riscv64-xs.bin，sha256 应等于上表（现成那份已核对相等）
```

（dhrystone 为什么减次数：`dry.c:362` 只给 SOUTHLAKE 平台走 1000 次，`riscv64-xs` 走 500000 次 ≈ 1.7e8 条指令，
RTL 仿真跑不完；详见 `verif/sim/README.md`「负载」节。）

## 3. 一条命令序列（从 main 检出）

```bash
git clone <repo> xs-v2-sv && cd xs-v2-sv            # 或任意已有的 main 检出 / worktree
export SIMF=/home/eda/xs-env/sim-fcb-$USER           # ★新工作区★；不要往已有的 /home/eda/xs-env/sim-fcb 里编
export VCS_ARCH_OVERRIDE=linux                       # 脚本内部也会设
W=/home/eda/xs-env/sim-fcb/workloads                 # 负载（只读）

# 1) build：两侧可并行，各约 20 分钟（16 job）
verif/sim/run_fcb.sh build golden > $SIMF.golden.build.out 2>&1 &
verif/sim/run_fcb.sh build impl   > $SIMF.impl.build.out   2>&1 &
wait
verif/sim/run_fcb.sh srcmap-check                    # impl 清单 vs 仓内 docs/xstile_srcmap.tsv，应 VERDICT: CONSISTENT

# 2) smoke
for s in golden impl; do verif/sim/run_fcb.sh run $s $W/flash_recursion_test.bin "" smoke >/dev/null & done; wait
verif/sim/run_fcb.sh compare smoke

# 3) coremark + dhrystone（四个进程并行，约 1~1.5 小时墙钟）
for s in golden impl; do
  verif/sim/run_fcb.sh run $s $W/coremark-2-iteration.bin 50000000 coremark >/dev/null &
  verif/sim/run_fcb.sh run $s $W/dhrystone.bin            50000000 dhrystone >/dev/null &
done; wait
verif/sim/run_fcb.sh compare coremark; verif/sim/run_fcb.sh compare dhrystone

# 4) cputest 33 个（两侧各跑 + 逐个 compare；参数=并行度；负载目录 CT_DIR 可改）
verif/sim/run_fcb.sh cputest 10
```

子命令一览（`verif/sim/run_fcb.sh` 不带参数打印）：`setup` / `build` / `run` / `compare` / `cputest` / `srcmap-check`，
以及调试模式 `build-debug` / `run-debug` / `verdi`（§5）。

产物（都在 `$SIMF` 下，**不入库**）：`{golden,impl}/build/simv`、`{golden,impl}/build.log`、`impl/files_impl_nosimtop.f`（impl 实际编译清单）、
`impl/srcmap.tsv`、`impl/outcore_renamed/`（核外 8 个共用模块改名拷贝）、`{golden,impl}/run/<tag>/{sim.log,assert.log,commit.trace}`、
`difftest/`（私有副本，补丁记录 `vcs.mk.patch.txt`、`top.v.patch.txt`、`commit_trace.patch.txt`）。

`srcmap-check` 说明：impl 清单里的 rtl 项是**编译那次所在检出**的绝对路径。若与当前检出不同，
`check_xstile_srcmap.py` 按相对路径比对，并逐文件比 sha256（内容不同 → INCONSISTENT；原文件已删 → UNVERIFIABLE，须从当前检出重编）。
源表默认读当前检出的 `docs/xstile_srcmap.tsv`，可 `--srcmap` 改。

## 4. 预期结果（引自 docs/lanes/fullchip-bench.md §5，2026-10-18，main 9ae0e8144 的 rtl/）

| 负载 | trap | instrCnt | cycleCnt | IPC | A: difftest（每侧） | B: 逐拍 |
|---|---|---|---|---|---|---|
| flash_recursion（smoke） | GOOD @0xe | 289 | 4,642 | 0.062258 | PASS | MATCH |
| coremark-2-iteration | GOOD @0x80001ca0 | 663,692 | 320,376 | 2.071603 | PASS | MATCH |
| dhrystone（1000 runs） | GOOD @0x80000da4 | 429,370 | 147,946 | 2.902208 | PASS | MATCH |
| cputest ×33 | 33/33 GOOD | 逐项相等 | 逐项相等 | | 33/33 PASS | 33/33 MATCH |

两侧 `commit.trace` 整文件 sha256（`verif/sim/results/fcb/trace_sha256.txt`；golden 与 impl 相同）：

```
smoke      7b376d39b418c5e942040732f2d88b4bf0f5926d35e78aa64dad167142a52f08
dhrystone  41c7457eb45600729c469cae7b750bfefe8a47adbfcfbab3a08198a662f36dd6
coremark   1583d0570e3901e70fc71f2533832730d6cb4a3baf9792e7aecece2f4a9c327c   (78,984,808 字节)
```

trace 事件数：smoke 245、coremark 493,592、dhrystone 378,536。参考 CPU 时间：coremark golden 3731 s / impl 5065 s。
`compare` 输出 `[A]`（每侧 difftest 判据）与 `[B] 逐拍`（trace 逐行逐字节 + 终点计数），判据定义见 fullchip-bench.md §3。
impl 侧每次运行有 307 条 time-0 的 `Warning-[RT-NCMUCS]`（fullchip-bench.md §5.5-1，已知，不影响结果）。
rtl/ 改了之后数字可能变——上表只对 9ae0e8144 的 rtl/ 成立；sha256 相同才说明逐拍全等。

## 5. 调试构建与 Verdi

快速路径（`build`/`run`）为速度去掉了 `-debug_access+all`，没有波形能力。调试模式是**另一套独立工作区**，
不改快速路径的任何行为与输出：

```bash
export SIMF=...                       # 同 §3；调试工作区 DSIMF 默认 ${SIMF}-debug（可显式设，不能等于 SIMF）
verif/sim/run_fcb.sh build-debug impl             # 或 golden；约 30+ 分钟
# 全程 fsdb：
verif/sim/run_fcb.sh run-debug impl $W/flash_recursion_test.bin "" smoke +dump-wave=fsdb
# 只 dump 一个时间窗口（单位 ns；时钟周期 2ns，reset 在 100ns 释放，cycleCnt≈(t-100)/2）：
verif/sim/run_fcb.sh run-debug impl $W/coremark-2-iteration.bin 50000000 cm_win +dump-wave=fsdb +wave-begin=400000 +wave-end=420000
# VPD（原版 difftest 分支，全程）：... +dump-wave=vpd
verif/sim/run_fcb.sh verdi impl smoke             # 起 Verdi（有 DISPLAY 时），等价于：
verdi -dbdir $DSIMF/impl/build/simv.daidir -ssf $DSIMF/impl/run/smoke/simv.fsdb
```

调试工作区里的东西：
- `difftest/`：原版 difftest 的私有副本；`vcs.mk` **保留原版 `-debug_access+all`**，再加 `-kdb`（Verdi KDB）和
  `+define+CONSIDER_FSDB`（打开 top.v 的 fsdb 分支），`-j200→-j$VCS_JOBS`（补丁记录 `vcs.mk.debug.patch.txt`）。
  不走 vcs.mk 自带的 `CONSIDER_FSDB=1`：那个分支给 `EXTRA` 赋值，impl 侧命令行的 `EXTRA="-f 清单"` 会把它整个盖掉。
- `top.v`：fsdb 分支加可选窗口 `+wave-begin/+wave-end`（`top.v.debug.patch.txt`）；VPD 分支保持原版。
- 同一份 `FCB_COMMIT_TRACE` 补丁，`run-debug` 也写 `run/<tag>/commit.trace`，可以和快速路径的 trace 直接 `cmp`。
- 功能 define（`DIFFTEST`/`VCS`/`RANDOMIZE_*`/`UNIT_DELAY`/`+vcs+initreg+random`/`-timescale=1ns/1ns`）与快速路径逐个相同，
  只多调试开关；`run-debug` 的 plusarg 也与 `run` 相同，额外 plusarg 经 `SIM_PLUSARGS` 追加。

## 6. XSTile 单独 elaborate（可综合口径，非仿真）

```bash
TMPDIR=/home/eda/xs-env/tmp-$USER bash scripts/xstile_rtl_elab.sh [workdir]   # 默认 ${TMPDIR:-/tmp}/xstile_rtl_elab
```

清单由 `scripts/xstile_srcmap.py` 生成（闭包 rtl + 登记存储模型，`+define+SYNTHESIS`），两步并行：
- **main**：`vcs ... -top XSTile` 真 elaborate，判据 rc=0、0 Error、Top Level Modules 恰为 XSTile；
- **closure**：同一清单不给 `-top`，VCS 推断出的顶层必须 = XSTile ∪ 闭包外闲置件（闭包内模块成了顶层 = srcmap 多认例化 → 红）。

`XSTILE_ELAB_STEPS=main|closure` 可只跑一步。约 10 分钟，不进 `scripts/gate_all.sh`（gate 里是秒级的 `xstile_srcmap.py --check` 与正反测）。
