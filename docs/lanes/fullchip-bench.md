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

---

## 5. 结果（2026-10-18，跑后追加；§0–§4 判据未改）

### 5.1 编译组成（impl 实际编译清单，`/home/eda/xs-env/sim-fcb/impl/files_impl_nosimtop.f`，2028 项 + Makefile 另传的打补丁 SimTop.sv）

> 更正 §1.1 的两个数：登记时闭包漏了 `rtl/backend/Rename.sv` 里经 `` `STD_FL `` 宏例化的 `StdFreeList{,_1,_2,_3}`
> （impl 的 `-y` 库目录为空，VCS 当场 `Error-[CFCILFBI]`，fail-closed 生效）。生成器加宏例化识别后：
> 闭包 **2136 = rtl 2039 + 登记存储模型 97**，rtl 模块文件 1513 → **1517**，不用的核外同名重写件 173 → 169。

| 来源 | 项数 |
|---|---|
| rtl/（12 个 package-only + 1517 个模块文件，定义 XSTile 闭包内 2039 个模块） | 1529 |
| G1 golden：核内登记存储模型（array* 40 / ram_* 34 / sram_array_* 20 / 3 个具名阵列） | 97 |
| G1 golden：核外逻辑 326（+ SimTop 由 Makefile 另传）、核外存储模型 46 | 372 |
| G1 golden：firtool 宏头 `extern_modules.sv`（0 模块，见下 5.5-2） | 1 |
| 核外 golden 拷贝（8 个共用模块改名 + 21 个核外父模块例化类型名改名） | 29 |

- 与 A 线源表 `docs/xstile_srcmap.tsv`（agent/xstile-srcmap@320ccb643，2136 = RTL 2039 / MEMORY_MODEL 97 / golden 逻辑 0）逐模块对照：
  `verif/sim/check_xstile_srcmap.py` → (a) 取源不一致 **0**、(b) golden 文件定义闭包内非存储模块 **0**、重复定义 0：**CONSISTENT**。
  同一检查对 `scripts/full_elab_filelist.py --with-difftest` 的产物也是 **CONSISTENT**（0 / 0 / 0）。
- impl `build.log`：读入 design file 2036 个（清单 2028 全部读入 + SimTop + difftest vsrc），**从 `-y` 库目录读入 0 个**。

### 5.2 结果总表（两侧同一 difftest 副本、同一 VCS 开关、同一 plusarg）

| 负载 | 侧 | trap | instrCnt | cycleCnt | IPC | A: difftest | B: 逐拍 | trace 事件 | sim CPU s |
|---|---|---|---|---|---|---|---|---|---|
| flash_recursion（smoke） | golden | GOOD @0xe | 289 | 4,642 | 0.062258 | PASS | — | 245 | 12.98 |
| | impl | GOOD @0xe | 289 | 4,642 | 0.062258 | PASS | **MATCH** | 245 | 13.59 |
| coremark-2-iteration | golden | GOOD @0x80001ca0 | 663,692 | 320,376 | 2.071603 | PASS | — | 493,592 | 3731 |
| | impl | GOOD @0x80001ca0 | 663,692 | 320,376 | 2.071603 | PASS | **MATCH** | 493,592 | 5065 |
| dhrystone（1000 runs） | golden | GOOD @0x80000da4 | 429,370 | 147,946 | 2.902208 | PASS | — | 378,536 | 1846 |
| | impl | GOOD @0x80000da4 | 429,370 | 147,946 | 2.902208 | PASS | **MATCH** | 378,536 | 2503 |
| cputest ×33 | 两侧 | 33/33 GOOD | 逐项相等 | 逐项相等 | | 33/33 PASS | **33/33 MATCH** | | |

- 两侧 `commit.trace` **整文件 sha256 相同**（`verif/sim/results/fcb/trace_sha256.txt`；coremark 78,984,808 字节）。
  所以 B 不只是"首个失配之前一致"，而是全程逐拍逐字段一致，包括每拍每槽的 pc/inst/wdest/wdata/robIdx/lqIdx/sqIdx。
- 计数与 2026-09（只重写约 7% 时）完全相同：coremark 663,692 / 320,376，dhrystone 429,370 / 147,946。
- UART 输出（sim.log 去仿真器噪声与下述运行期 Warning 后）两侧逐行相同。
- 观测到的事实（不是判据变更）：smoke 的 trace 没有 `T` 行（flash 负载的 trap 在 `check_all` 之前就结束了这一步），
  两侧同样没有；cputest/coremark/dhrystone 都有 `T` 行且相等。

### 5.3 判定

- **A（NEMU difftest 架构正确性）**：golden、impl 两侧在 smoke / coremark / dhrystone / cputest 33 个上**全部 PASS**。
- **B（重写 vs golden 逐拍一致）**：全部 **MATCH**，无首个失配可报。主配置即 §1.2 原始配置，所以 §4.3 的 Z0 诊断档**未触发、未跑**。
- 适用范围：本结论验证的是 **XSTile 替换**；XSTop 核外件全部是 G1 golden（rtl/ 里 169 个核外同名重写件本轮未用）。

### 5.4 结果文件（`verif/sim/results/fcb/`）

`compare_{smoke,coremark,dhrystone}.txt`（commit_compare 输出）、`{smoke,coremark,dhrystone}_{golden,impl}.sim.log`
（去掉运行期 Warning 块与空行）、`cputest.tsv`、`trace_sha256.txt`、`impl_runtime_warnings_sample.txt`。
trace 本体（coremark 约 79MB/侧）留在工作区 `/home/eda/xs-env/sim-fcb/{golden,impl}/run/<tag>/commit.trace`，不入库。

### 5.5 遗留 / 给 rtl owner 的观察（未改 RTL）

1. **impl 侧每次运行 307 条 VCS 运行期 `Warning-[RT-NCMUCS]`，全部在 time 0**（golden 侧 0 条）：
   `rtl/mmu/PTWFilter.sv:97` `ptwfilter_pkg::level_match` 的 `unique case (level)` 无 default（294 条），
   `rtl/memblock/VLMergeBufferImp.sv:169` `merge_by_elem` 的 `unique case (aligned)`（其余）。复位前输入为 X 触发，
   不影响结果（trace 全等），但会淹没日志、也是与 golden 的可观察差异；建议补 `default` 或改 `case`。
2. **两个 rtl 文件依赖 firtool 宏却不自带定义**：`rtl/backend/{TrapEntryVSEventModule,VSstatusModule}.sv` 用
   `` `ASSERT_VERBOSE_COND_ `` 等。golden 流里宏由先编的 golden 文件头带进来；rtl 在前的清单会 `Error-[UM]`。
   本 lane 的处理是清单最前放 G1 的 `extern_modules.sv`（宏头，0 模块）。这是文件顺序依赖，建议 owner 自带宏头。
3. **核内外共用 8 个同名模块**（§1.1-3）：本轮靠核外侧改名两全；若将来核外也换重写件，或要求"rtl 里同名件全局唯一"，需要决定口径。
4. impl simv 比 golden 慢约 35%（coremark 5065 s vs 3731 s CPU）；2026-09 时 impl 反而快，原因未查。
5. 未做：perf 计数对拍（另一条路径，非本 lane）、Z0 档（未触发）、波形诊断（无失配，不需要）。

### 5.6 复现（实际执行的命令）

```bash
cd /home/eda/xs-env/wt-fullchip-bench
verif/sim/run_fcb.sh build golden; verif/sim/run_fcb.sh build impl          # 两侧可并行，各约 20 分钟
W=/home/eda/xs-env/sim-fcb/workloads
verif/sim/run_fcb.sh run golden $W/flash_recursion_test.bin "" smoke; verif/sim/run_fcb.sh run impl $W/flash_recursion_test.bin "" smoke
verif/sim/run_fcb.sh compare smoke
for s in golden impl; do verif/sim/run_fcb.sh run $s $W/coremark-2-iteration.bin 50000000 coremark &
                         verif/sim/run_fcb.sh run $s $W/dhrystone.bin 50000000 dhrystone & done; wait
verif/sim/run_fcb.sh compare coremark; verif/sim/run_fcb.sh compare dhrystone
verif/sim/run_fcb.sh cputest 10
python3 verif/sim/check_xstile_srcmap.py --srcmap /home/eda/xs-env/wt-xstile-srcmap/docs/xstile_srcmap.tsv \
    --filelist /home/eda/xs-env/sim-fcb/impl/files_impl_nosimtop.f --build-log /home/eda/xs-env/sim-fcb/impl/build.log
```
