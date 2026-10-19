# usability lane（agent/usability，codex 0240 C 线）—— 整芯片对拍工具的最终可用性整理

基线 main `9ae0e8144`，认领 `987466a49`（`docs/lanes/usability_claim.md`）。不碰 rtl/、allow、证书、派生表、G0/G1；
`/home/eda/xs-env/sim-fcb` 只读（没在里面编译或写文件），没碰 `sim-prof`。

## 1. 改了什么

| 文件 | 改动 |
|---|---|
| `docs/fullchip_sim.md`（新） | 使用说明：从任意 main 检出 build golden/impl → smoke/coremark/dhrystone → compare → cputest 的命令序列；外部依赖（G1、原版 difftest、DPI regen、XS_HOME/NEMU so、VCS/Verdi W-2024.09-SP1 与 `VCS_ARCH_OVERRIDE=linux`+`-full64` 怪癖、nexus-am、工具链）及其环境变量；负载来源与 sha256；预期结果（引 fullchip-bench §5，含 trace sha256）；调试/Verdi；XSTile 单独 elaborate；仿真顶层 `tb_top` 的核对 |
| `verif/sim/run_fcb.sh` | 新子命令 `build-debug` / `run-debug` / `verdi` / `srcmap-check`；`patch_trace` 改成接受 difftest 目录参数。`setup`/`build`/`run`/`compare`/`cputest` 的行为不变 |
| `verif/sim/run_fastsim.sh` | `run` 加 `SIM_PLUSARGS` 透传（默认空 = 行为不变），供 `run-debug` 传 `+dump-wave` 等参数 |
| `verif/sim/check_xstile_srcmap.py` | `--srcmap` 默认读本检出的 `docs/xstile_srcmap.tsv`；`--golden`/`GOLDEN_RTL`；清单是在别的检出生成的时候，按相对路径比对，并逐文件比 sha256（内容不同 → INCONSISTENT，原文件已删 → UNVERIFIABLE rc=1，不会默默放过） |
| `verif/sim/bore_audit.py` | 去掉写死的 `/home/eda/xs-env/wt-sim/rtl/`，改成取本检出的 rtl/；其它路径可用环境变量改 |
| `scripts/xstile_rtl_elab.sh` | 主 elaborate 改成显式 `-top XSTile`；原来不给 `-top` 的闭包核对保留为独立的 `closure` 步，两步并行跑；`XSTILE_ELAB_STEPS=main\|closure\|all`。默认工作目录从仓内 `build_xstile_rtl/`（**不在 .gitignore 里**，原默认会弄脏工作树）移到 `${TMPDIR:-/tmp}/xstile_rtl_elab` |
| `verif/sim/README.md` | 顶部加一行指向 `docs/fullchip_sim.md` |
| `docs/lanes/fullchip-bench.md` | 只在末尾追加一行「复现入口已迁至 docs/fullchip_sim.md」；§0–§5 未改 |

wt-* 路径扫描：`grep -rn 'wt-' verif/sim scripts/*.sh` 改完后只剩 fullchip-bench.md §1/§5.6 的历史记录（不改）。
`run_fcb.sh` 的 `cputest` 本来就用 `CT_DIR` 环境变量，不依赖任何 worktree。

### 调试模式的设计

- 工作区是 `DSIMF`（默认 `${SIMF}-debug`，即 `/home/eda/xs-env/sim-fcb-debug`；脚本拒绝 `DSIMF == SIMF`）。它有自己的原版 difftest 副本，
  golden/impl 构建目录也各自独立。
- `vcs.mk`：**保留**原版的 `-debug_access+all`，再加 `-kdb +define+CONSIDER_FSDB`，`-j200→-j16`。不走 vcs.mk 自带的 `CONSIDER_FSDB=1`，
  因为那个分支给 `EXTRA` 赋值，而 impl 侧在命令行上传了 `EXTRA="-f 清单"`，会把它整个盖掉。
- `top.v`：fsdb 分支加了可选窗口 `+wave-begin=<ns> +wave-end=<ns>`；VPD 分支保持原版。
- 用的是同一份 `FCB_COMMIT_TRACE` 补丁，所以调试 run 的 trace 可以直接和快速路径的 trace 比较。

## 2. 验证（2026-10-18/19）

| 项 | 命令 | 结果 |
|---|---|---|
| XSTile 主 elaborate + 闭包核对 | `TMPDIR=/home/eda/xs-env/tmp-us bash scripts/xstile_rtl_elab.sh /home/eda/xs-env/tmp-us/xelab` | **PASS**，墙钟 8:31。`[main]` rc=0、0 error、Top Level Modules = `XSTile`；`[closure]` rc=0、0 error，顶层 = XSTile + 11 个闭包外闲置件（C22 C53 CSA3_2 F3Predecoder FrontendTrigger IndexableCAMTemplate PreDecode PredChecker RVCExpander RegCacheTagModule xs_StorePipe_core），闭包内没有模块成为顶层。清单：rtl 1529 文件 + 存储模型 97；闭包 2136 模块 |
| 仿真顶层是 tb_top | 看两侧 `build.log` 第一条 vcs 命令行 | `-top tb_top`（sim-fcb golden/impl、sim-fcb-debug/impl 都是） |
| srcmap-check（默认读仓内源表） | `verif/sim/run_fcb.sh srcmap-check`（等价于 `check_xstile_srcmap.py --filelist $SIMF/impl/files_impl_nosimtop.f --build-log $SIMF/impl/build.log`） | **CONSISTENT**：(a) 0 / (b) 0 / 重复 0；清单生成于 `wt-fullchip-bench`，按相对路径比对，内容与本检出不同 0；从 -y 库读入 0 |
| srcmap-check 正反测 | 复制 rtl 到假根并改写清单：原样 / 改一个文件 / 删掉假根 | CONSISTENT / **INCONSISTENT**（content differs AMOALU.sv）/ **UNVERIFIABLE**（1529 个文件已不存在） |
| 调试构建 impl（实际编了一次） | `verif/sim/run_fcb.sh build-debug impl` | **simv 编出来了**，墙钟 959 s；`Verdi KDB elaboration done and the database successfully generated`；`simv.daidir` 已生成。vcs 命令行和快速路径 impl 逐 token 比（工作区路径归一化后）**只多 `-debug_access+all -kdb +define+CONSIDER_FSDB` 三项**；impl 清单除检出根之外完全相同 |
| 调试 run + 全程 fsdb | `run_fcb.sh run-debug impl $W/flash_recursion_test.bin "" smoke +dump-wave=fsdb` | HIT GOOD TRAP，289 / 4,642，Difftest enabled；`simv.fsdb` 79 MB；**commit.trace sha256 `7b376d39…2f08` = 预期 smoke sha**（调试开关不改变行为） |
| 调试 run + 窗口 fsdb | `... smoke_win +dump-wave=fsdb +wave-begin=4000 +wave-end=6000` | `fsdb dump on at 4000` / `off at 6000`，fsdb 22 MB；trace sha 同上 |
| Verdi 加载 | `verdi -nogui -dbdir $DSIMF/impl/build/simv.daidir -ssf $DSIMF/impl/run/smoke_win/simv.fsdb -play q.tcl` | rc=0；activeScope=`tb_top`，读到 FSDB dumper 版本信息。GUI 入口是 `run_fcb.sh verdi impl <tag>`（本机 DISPLAY=:0；本 lane 没开 GUI 窗口） |
| gate_all 全量 | `TMPDIR=/home/eda/xs-env/tmp-us bash scripts/gate_all.sh`（@27699eb45） | 见 §3 |

注：smoke 的 sim.log 里有一行 `HIT CRITICAL ERROR: please check if software cause a double trap`。这行在已入库的
`verif/sim/results/fcb/smoke_{golden,impl}.sim.log` 里也有，两侧都一样，是 flash 负载本身的输出，不是调试构建带来的。

## 3. gate_all

全量跑：`TMPDIR=/home/eda/xs-env/tmp-us bash scripts/gate_all.sh`，跑在 `27699eb457` 上（本 lane 的第一个提交，脚本与说明都已在内）。
**`GATE_RC=0`**，`GATE_COMMIT=27699eb457`（开跑和收尾时一致，不脏），PASS 262 行，FAIL 0，墙钟 4585 s。
与本 lane 改动直接相关的项：`XSTile 源表幂等`、`XSTile 源表正反测`、工具派生态闸（本 lane 没有提交 build/日志/simv）全部 PASS。
`scripts/xstile_rtl_elab.sh` 不在 gate_all 里（约 9 分钟，gate 注释写明了不进本闸），所以单独跑了，结果见 §2。
本文件（usability.md）是在 gate 之后提交的，只有文档，没动脚本。

## 4. 未做 / 遗留

- 调试构建只编了 impl 一侧，golden 侧没编（命令相同：`build-debug golden`，约 16 分钟）。
- 本 lane 没有从零重编快速路径的 golden/impl，也没重跑 coremark/dhrystone/cputest（sim-fcb 只读）。§3 的命令序列在本检出上走通的部分是：
  调试 impl 构建、调试 smoke run、srcmap-check。快速路径的 build/run 脚本逻辑没改（diff 只有 `SIM_PLUSARGS` 默认为空的追加）。
- sim-fcb 里现有 impl 清单指向 `wt-fullchip-bench/rtl/...`。那个 worktree 清理以后，`srcmap-check` 会如实报 UNVERIFIABLE
  （simv 本身不受影响）。要想核对恢复绿色，得从 main 检出用新 SIMF 重编 impl。
- `/home/eda/xs-env/sim-fcb-debug` 是本 lane 建的调试工作区（约数 GB，不入库），保留着方便后续调试复用，不要可以直接删。
