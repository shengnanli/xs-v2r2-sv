# fullchip-bench lane（agent/fullchip-bench）—— 整芯片 SimTop「只换 XSTile」benchmark 对拍

codex 0238 主线 B。本文件 §0–§4 是**跑前登记**（观测点、有效条件、判据、比对脚本在任何 benchmark 运行之前提交）；
跑完只在 §5 之后追加结果，★不修改 §0–§4 的任何判据★。

## 0. 本轮验证的是什么（以及不是什么）

- **验证对象：XSTile 替换。** SimTop → XiangShanSim → XSTop 里，`XSTile`（核 + L2）整棵子树换成 `rtl/` 的重写版；
  XSTop 的**核外件**（OpenLLC/L3、TL↔AXI 桥、IMSIC 总线、调试模块、时钟/中断同步……）**保持 G1 golden 基线不动**。
- **不是** XSTop 核外重写的验证：rtl/ 里有 173 个核外同名重写件（OpenLLC 家族、TLPLIC、CHI 交叉开关等），本轮**一个都不用**。
- 仿真 / 复位 / 存储初始化配置与 golden 完全相同（同一份 difftest 副本、同一组 VCS 开关、同一组 plusarg）。

## 1. 输入（固定）

| 项 | 值 |
|---|---|
| 基线 | main `dabf1cda0` + 认领 `ab528085b`，工作树 `/home/eda/xs-env/wt-fullchip-bench` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读；`SimTop.sv` sha256 `2ce638a3…5b95`） |
| DPI 胶水 | `/home/eda/xs-env/sim-work/regen/build/generated-src`（与 G1 同配置重生成，`check_dpic` 门禁，见 verif/sim/README.md） |
| difftest | `/home/eda/xs-env/sim-work/difftest` 的私有拷贝 `/home/eda/xs-env/sim-fcb/difftest`，三处补丁（下面），**两侧共用同一份** |
| NEMU ref | `XiangShan/ready-to-run/riscv64-nemu-interpreter-so`（sha256 `7b5a235c…27cd`） |
| 工作区 | `/home/eda/xs-env/sim-fcb/{golden,impl}`（本 lane 专用，不复用 sim-fast / sim-work） |

负载（`/home/eda/xs-env/sim-fcb/workloads/`，拷自 2026-09 fastsim 泳道，sha256）：

| 负载 | sha256 | 说明 |
|---|---|---|
| `flash_recursion_test.bin` | `84c4156d…bb75` | 启动 smoke（2026-09 两侧 289 instr / 4,642 cycle） |
| `coremark-2-iteration.bin` | `c764afb8…e8e` | CoreMark 2 迭代（2026-09：663,692 / 320,376，那时只重写约 7%） |
| `dhrystone.bin` | `3139eaed…d2b0` | Dhrystone，NUMBER_OF_RUNS=1000（补丁见 `verif/sim/results/dhrystone_dry.c.patch.txt`；2026-09：429,370 / 147,946） |
| nexus-am cputest 33 个 | `/home/eda/xs-env/nexus-am/tests/cputest/build/*-riscv64-xs.bin` | 便宜就跑 |

### 1.1 编译组成（impl 侧）

`verif/sim/xstile_sim_filelist.py`（`run_fcb.sh` 以 `XSTILE_ONLY=1` 调用）：

1. R_in：从 `rtl/xstile/XSTile.sv` 沿重写件例化关系求闭包 → **2131 个模块 = rtl 2034 个（1513 个文件 + 12 个 package-only 文件）
   + golden 登记存储模型 97 个**（array/array_N/*_ext 40、ram_* 34、sram_array_* 20、diff_rat_state_bank_320x776、
   dt_pcTransType_160x2、stateBankTags_320x3）。闭包里出现任何非存储 golden 逻辑件 → fail-closed。
2. G_out：从 golden `SimTop` 沿 golden 例化关系求闭包，遇 `XSTile` 不下钻 → **402 个模块，全取 golden**。
3. 核内外**共用**的同名逻辑模块 8 个（`AsyncResetSynchronizerPrimitiveShiftReg_d3_i0`、`AsyncResetSynchronizerShiftReg_w1_d3_i0`、
   `Decoupled2LCredit{,_1,_2}`、`FastArbiter_26`、`IntBuffer`、`PMPChecker`）：一个名字只能有一份定义，所以核内用 rtl，
   **核外一侧机械改名**为 `<名>__golden_outcore`（golden 文件拷贝到工作区，只改 `module` 行和核外父模块里的例化类型名；
   涉及 29 个核外 golden 文件拷贝，逐行 diff 只有类型名变化，见 §5）。
4. impl 的 `build/rtl`（= vcs `-y` 库兜底目录）**只放打补丁的 SimTop.sv**：清单漏件会当场编译报错，不可能静默回落 golden。
5. impl 的 SimTop：9897 条 perfCnt_bore XMR 接 `'0`（既有做法，LogPerfEndpoint 纯 input 观测 sink，不进 difftest 判定；
   perf 验证另走 run_perfbind，不在本 lane）。golden 用原版 SimTop。

### 1.2 两侧共同的仿真配置

difftest 私有拷贝的补丁（两侧同一份）：
- `vcs.mk`：去 `-debug_access+all`，`-j200 → -j16`（run_fastsim.sh 既有补丁）；
- `top.v`：去 `$vcdplusfile/$vcdpluson`（无 debug_access 时编不过）；
- `difftest.cpp`：`FCB_COMMIT_TRACE` —— 在 `Difftest::check_all()` 开头、任何 checker 消费之前，把 DUT 送来的提交/事件原样写到
  `$XS_COMMIT_TRACE`（未设该环境变量时不写；**不改任何判定路径**）。

功能 define / 运行参数完全沿用 difftest 默认：`+define+DIFFTEST +define+VCS +vcs+initreg+random`
`+define+RANDOMIZE_{GARBAGE_ASSIGN,INVALID_ASSIGN,MEM_INIT,REG_INIT} +define+RANDOMIZE_DELAY=1 +define+UNIT_DELAY`
`-timescale=1ns/1ns`；运行 `+workload=<bin> +diff=<nemu.so> +ram_size=8589934592 +max-cycles=<N>`。

## 2. 观测点与有效条件（跑前固定）

每个 difftest 步（= DUT 每拍一次 `Difftest::step()`），`cycle = trap_event.cycleCnt`（DUT 核内周期计数）：

| 行 | 有效条件 | 字段（全部参与比较） |
|---|---|---|
| `C <cycle> <slot> …` | `commit[slot].valid`（slot 0..7） | pc、inst、rvc、rfwen、fpwen、vecwen、v0wen、wdest、**wdata**、skip、fused、special、robIdx、lqIdx、sqIdx、isLoad、isStore |
| `E <cycle> …` | `event.valid`（中断/异常） | interrupt、exception、exceptionPC、exceptionInst、hasNMI |
| `T <cycle> …` | `trap.hasTrap` | instrCnt、code、pc |

- `wdata` = `get_commit_data(dut, slot)`（本配置 `CONFIG_DIFFTEST_COMMITDATA`：DUT 逐提交槽送出的写回数据）；
  仅当 `rfwen|fpwen|vecwen` 时取值，否则固定写 0（不写回的槽没有定义的 wdata）。这是唯一的条件取值，跑前定死。
- 另比 sim.log 的终点：`HIT GOOD/BAD TRAP at pc`、`instrCnt / cycleCnt / IPC`、`DIFFTEST WORKLOAD DONE at cycle`、`EXCEEDED MAX CYCLE`。

## 3. 判据（两件事分开报，互不替代）

**A. NEMU difftest 架构正确性（每侧独立判）** —— PASS 当且仅当：出现 `Difftest enabled`、`HIT GOOD TRAP`、
没有 `different at pc|Mismatch|DIFFTEST FAILED|ABORT at pc|HIT BAD TRAP`、没有 `EXCEEDED MAX CYCLE`。
GOOD TRAP 单独不算通过。

**B. 重写 vs golden 逐拍一致** —— MATCH 当且仅当：两侧 `commit.trace`（去 `#` 头）**逐行逐字节相等**，且 §2 终点各项相等。
不剔字段、不设容差、不对齐/重排。第一处不等即 MISMATCH，`commit_compare.py` 打印两侧该行（cycle/slot/pc/inst/valid…）、
不同字段与前 5 行上下文。

比对脚本：`verif/sim/commit_compare.py <golden_rundir> <impl_rundir>`（= `run_fcb.sh compare <tag>`）。

## 4. 失配处置（跑前固定）

1. 保留两侧 trace 与 sim.log，记首个失配的两侧 cycle/PC/inst/valid。**不放宽比较、不把任何件换回 golden 来"修好"**。
2. 诊断：先用 trace 定位首失配前后的提交流；必要时编带 `-debug_access+all` 的 debug simv（两侧同开关）在首失配附近窗口
   `+dump-wave=vpd` 看波形，向下定位到模块。
3. 已知的仿真伪差来源要先排除再下结论：golden firtool `RANDOMIZE_*_INIT` 用无种子 `$random` 全局流，整棵 XSTile 换掉后
   核外 golden 寄存器的初值流必然平移（memory: perf-random-init-stream，codex 0207）。**主判据仍是 §1.2 的原始配置**；
   若主判据 MISMATCH，补一档 Z0（两侧去 RANDOMIZE_*、运行 `+vcs+initreg+0`）**仅作诊断**——Z0 MATCH 只说明差异来自初值，
   不把主判据改判为 MATCH，两档分别报告。
4. rtl/ 不归本 lane：只报告可疑模块与证据，不改 RTL。

## 复现命令

```bash
cd /home/eda/xs-env/wt-fullchip-bench
verif/sim/run_fcb.sh build golden &   verif/sim/run_fcb.sh build impl &   wait
W=/home/eda/xs-env/sim-fcb/workloads
for s in golden impl; do verif/sim/run_fcb.sh run $s $W/flash_recursion_test.bin "" smoke & done; wait
verif/sim/run_fcb.sh compare smoke
for s in golden impl; do verif/sim/run_fcb.sh run $s $W/coremark-2-iteration.bin 50000000 coremark & \
                         verif/sim/run_fcb.sh run $s $W/dhrystone.bin 50000000 dhrystone & done; wait
verif/sim/run_fcb.sh compare coremark; verif/sim/run_fcb.sh compare dhrystone
```
