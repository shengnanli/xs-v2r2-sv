# verif/sim/collateral —— 干净 checkout 跑仿真缺的那一小块

codex 0160 §Canonical simulation collateral：

> Add the six required generated-src/DPI interface files (~120 KiB) to the canonical
> simulation collateral, **or** provide a deterministic generator command that recreates
> those exact interfaces before build. **Prefer the smaller option that makes a clean
> checkout runnable**; do not retain the mismatched FPGA DPI objects.

**选了 A（把文件纳入版本库）。** 13 个文件，212 191 字节（207 KiB）。理由在下面第 2 节，
是实测出来的，不是偏好。

---

## 1. 为什么会缺这一块

`G1-canonical/` 冻结的是 **`golden-rtl/` 2061 个文件**（.sv/.v/.conf/.fir）。
它**不含 `generated-src/`** —— 也就是 difftest 的 DPI C++ 胶水。

于是「工程有唯一 golden 对照」这句话在仿真这件事上是**不成立**的：
拿着 G1-canonical 和一份干净 checkout，VCS 连 **golden 侧**都编不出来。
少的不是 RTL，是 RTL 里 `DummyDPICWrapper_*` 所声明的那 27 个 DPI 函数的 C++ 实现。

## 2. 为什么选 A 而不是 B（生成命令）

B 的生成命令就是 `run_fullchip.sh` 里 `regen_generated_src()` 跑的那条：

```
make sim-verilog CONFIG=KunminghuV2Config NUM_CORES=1 ISSUE=E.b \
     BUILD_DIR=<isolated> NOOP_HOME=<isolated>
```

它能产出正确的一份（本目录这 13 个文件就是它的产物），但**不适合当交付路径**，三条实测理由：

**(a) 它不是 hermetic 的 —— 它必然写进 `$XS_HOME/build/`，无视 BUILD_DIR/NOOP_HOME。**

`XiangShan/src/main/scala/top/Top.scala:680`：

```scala
FileRegisters.write(fileDir = "./build", filePrefix = "XSTop.")
```

`./build` 是**相对 mill 进程 CWD** 的硬编码路径，而 CWD 是 `$XS_HOME`。
所以无论把 BUILD_DIR / NOOP_HOME 指到哪里，这一批都落在 `$XS_HOME/build/`。

实测证据（mtime）：2026-09-14 12:36→13:05 那次隔离重生成跑完后，
`$XS_HOME/build/` 下 `chisel_db.cpp` `constantin.*` `perfCCT.*` `dts` `graphml` `json`
`MbistFrontend.csv` `MbistL2.csv` `MbistMemBlk.csv` `plusArgs` 全部变成 **13:05**。
（`generated-src/` 没被动，它跟 NOOP_HOME 走，落在隔离目录 —— 所以只是「部分隔离」。）

⚠ `run_fullchip.sh` 里 `regen_generated_src()` 的注释写着
「两个都指向隔离目录，`$XS_HOME/build` 一个字节都不动」—— **这句与实测不符**，
不动的只有 `generated-src/`。本目录的存在正好让这条命令不必再跑，问题也就不再发作。

而 `$XS_HOME/build/` 正是整个 collateral 事故的案发现场：它同时是
`--fpga-platform --disable-all --remove-assert` 那次 make 的落点。让交付路径
必须去写它，等于把「下一次配错」写进流程。

**(b) 代价不对称。** 实测 `regen/build/time.log`：
wall clock **28:49.89**，user 4677 s，Max RSS **19 369 428 KiB（≈18.5 GiB）**。
还要 JDK17 + mill 0.12.3 + ivy 依赖 + XiangShan Scala 源码停在同一个 commit。
对面是 **207 KiB 文本**。codex 说「prefer the smaller option」，量级差了五个数量级。

**(c) B 的确定性我没有证据，而且证不了。** 任务书要求「选 B 必须跑两遍逐字节相同」。
在本机跑第二遍就会再写一次 `$XS_HOME/build/`（见 (a)），而这轮工单明令
**不要碰 `XiangShan/build/`**，并行还有别的 worker 在用它。所以我没跑第二遍，
也不声称 B 是确定性的。

★ 顺带纠正一处引用：上一位 sim worker 的「重生成 2061 个文件里 2057 个逐字节相同」
是 **`build/rtl`（golden RTL）** 的复现证据，**不是 `generated-src` 的**。
`generated-src` 只有 6 个文件，从来没进过那次比对。拿它当 B 的确定性依据是张冠李戴。

## 3. 目录里是什么

`generated-src/` —— **6 个，编译必读**（difftest Makefile: `GEN_CSRC_DIR` / `GEN_VSRC_DIR`）

| 文件 | 字节 | 作用 |
|---|---:|---|
| `difftest-dpic.cpp` | 38 477 | 27 个 `v_difftest_*` DPI 实现（→ `difftest-dpic.o`） |
| `difftest-dpic.h` | 12 351 | 上者的声明 |
| `difftest-state.h` | 8 075 | 架构状态结构体布局（**ABI 关键**，见第 6 节） |
| `difftest-query.h` | 43 862 | 状态查询接口 |
| `difftest_profile.json` | 7 774 | difftest profile |
| `DifftestMacros.svh` | 153 | **Verilog** include，被 `difftest/src/test/vsrc/common/DifftestClockGate.v` `` `include `` |

`build/` —— **7 个，`run_fullchip.sh` 的 `setup()` 会往工作区 `cp` 的那批**

实测哪些真进了链接（`sim-work/golden/build/simv-compile/*.o`，456 个 `.o`）：

- ✅ `constantin.cpp` → `constantin.o` 在。`WITH_CONSTANTIN` 默认 1，必需。
- ❌ `chisel_db.cpp` / `perfCCT.cpp` → **没有** `chisel_db.o` / `perfCCT.o`。
  `run_fullchip.sh` 传 `WITH_CHISELDB=0`，而 `perfCCT.cpp` 嵌在同一个
  `ifeq ($(WITH_CHISELDB),1)` 块里，一起被关掉。
- `chisel_db.h` / `perfCCT.h` / `constantin.hpp` / `constantin.txt`：当前配置下没人 include。

那为什么还收着后 6 个？因为 `setup()` 是无条件 `cp` 的：

```sh
for f in chisel_db.cpp chisel_db.h constantin.cpp constantin.hpp constantin.txt perfCCT.cpp perfCCT.h; do
  [ -f "$dd/build/$f" ] || cp "$XS_HOME/build/$f" "$dd/build/$f"
done
```

少一个，`set -e` 就当场挂掉。收齐这 7 个才能**真正切断对 `$XS_HOME/build/` 的依赖**
（也就是切断对那份 FPGA 产物所在目录的依赖）；顺带谁要把 `WITH_CHISELDB` 打开也不用重新找文件。

已核对：这 7 个在 `--fpga-platform` 那次（Sep 9）与 `--enable-difftest` 那次（Sep 14）
**逐字节相同**，所以它们不区分配置，收哪份都一样，没有二义性。

## 4. 怎么用（干净 checkout → golden 侧仿真跑起来）

```sh
git clone <repo> xs-v2-sv && cd xs-v2-sv
SIMW=<空目录> verif/sim/collateral/seed.sh golden   # 摊开 collateral（秒级）
SIMW=<同一目录> verif/sim/run_fullchip.sh build golden
SIMW=<同一目录> verif/sim/run_fullchip.sh run golden <workload.bin> 200000
```

**实测跑通一次（2026-09-14，本泳道，全程从 `git clone` 起算）**：

| 步 | 结果 |
|---|---|
| `seed.sh golden` | 秒级；**没有触发**那次 29 分钟的重生成（`$SIMW/regen/gen.log` 不存在＝`check_dpic` 早退生效） |
| `build golden` | 21:47:28 → 22:02:28，**约 15 分钟**，`Error-` 0 条，产出 `simv` 1 975 424 B |
| `run golden bubble-sort` | `HIT GOOD TRAP at pc = 0x800001d8`，`instrCnt = 3,173, cycleCnt = 7,973`，difftest 全程无失配 |

★ 交叉验证：`cycleCnt = 7,973` 与 `verif/sim/cputest_results.tsv` 第 5 行记的
`bubble-sort 3,173, 7,973` **逐位相同** —— 说明这份进库的 collateral 复现出的是
当初那次 golden 的行为，不是「能编过就算」。

另外核对过：这一趟**没有写 `$XS_HOME/build/` 一个字节**（`constantin.cpp` 仍是 13:05、
`generated-src/difftest-dpic.cpp` 仍是 Sep 9 22:01），且 `$SIMW/<side>/build` 下那 13 个
文件与库里逐字节相同（13/13）。

⚠ 前提（与本目录无关，记在这里免得下一个人卡住）：`run_fullchip.sh` 在
`bash 4.4 + set -u` 下有 `local side=$1 dd=$SIMW/$side` 的 unbound-variable bug，
`setup/build/run` 三处，**照原样一条都跑不起来**。上面这趟是打了那个补丁跑的。
该 bug 已由 fastsim 泳道在 `agent/fastsim@e39f5e5` 修掉（拆成两条 `local`），
本目录不重复修。

`seed.sh` **不改 `run_fullchip.sh` 一个字节**，它利用那边已有的两处「已存在就跳过」：

1. `regen_generated_src()` 开头 `if [ -f "$gs/difftest-dpic.cpp" ] && check_dpic ...; then return 0; fi`
   —— 先把 collateral 摆进 `$SIMW/regen/build/generated-src`，那次 29 分钟的 make 整段跳过。
2. `setup()` 里 `[ -f "$dd/build/$f" ] || cp "$XS_HOME/build/$f" ...`
   —— 先摆好这 7 个，就不会去读 `$XS_HOME/build`。

★ `check_dpic` 这道 fail-closed 门禁**没有被绕开**：摆进去的 dpic 照样要过它
（提供的 `v_difftest_*` 集合必须等于 golden `GatewayEndpoint.sv` 例化的
`DummyDPICWrapper_*` 集合），对不上就仍旧去重生成。本目录这份实测 **27 == 27**。

仍需外部依赖（不属于本仓库，也不该由本仓库冻结）：VCS、`$SIMW/difftest`（difftest 仓库，
1.8 MiB）、`$XS_HOME/ready-to-run/riscv64-nemu-interpreter-so`（REF_SO）、workload 二进制。
用 `SIMW=` / `DIFFTEST=` / `REF_SO=` 覆盖落点。

## 5. 防腐：`scripts/check_sim_collateral.py`（已接进 `scripts/gate_all.sh`）

生成物进版本库就有腐烂风险 —— RTL 换一版、DPI 接口跟着变，而库里这份不会自己跟着走。
所以配闸，三条判据：

- **A 清单完整性（双向）**：`MANIFEST.sha256` 与树互相不许有缺漏或多余。
- **B DPI 接口集合 == golden 例化集合**：把 `run_fullchip.sh` 的 `check_dpic`
  从「跑仿真才发现」提前到「跑闸就发现」。
- **C canonical 绑定**：清单头 `# g1-canonical-id:` 必须等于 `G1-canonical/CANONICAL_ID.txt`。
  换 golden 基线而忘了重出 collateral，当场红。

负测（`--selftest`，种病必须被抓）：1 个干净样本要求不误报 + **6 个病例**要求逐个被抓，
实测 7 项全 PASS。6 个病例是：换成 `--fpga-platform` 那份 dpic（少 12 个函数）／
文件被手工改过／塞进清单外的文件／删掉清单内的文件／golden 换基线而 collateral 没跟着重出／
**对照物缺失时必须 fail-closed**（找不到 golden `GatewayEndpoint.sv` 不算通过）。

负测用的是合成样本，所以另外拿**真东西**验过一次：把
`$XS_HOME/build/generated-src`（真的那份 FPGA 产物）当成 collateral 喂给闸，
判据 A 报 6 条 `HASH_MISMATCH`、判据 B 报
`DPI_SET_MISMATCH  collateral 提供 21 个 v_difftest_*，golden … 例化 27 种`
并逐个列出缺的那 12 个名字。闸抓得住的是真病，不只是自己造的病。

换基线后重出：`python3 scripts/check_sim_collateral.py --write-manifest`。

## 6. 两个值得记住的坑

**DPI 函数集合对不上 ⇒ golden 自己就跑不起来。**
golden RTL 例化 27 种 `DummyDPICWrapper_*`；`$XS_HOME/build/generated-src` 那份
（`--fpga-platform --disable-all --remove-assert`）只给 21 个，少 12 个：
`ArchFpRegState ArchIntRegState ArchVecRegState AtomicEvent CMOInvalEvent CommitData
L1TLBEvent L2TLBEvent RefillEvent SbufferEvent StoreEvent UncacheMMStoreEvent`。
症状 `Error-[DPI-DIFNF] 'v_difftest_ArchFpRegState' does not exist`。
**这不是 impl 的 bug，是 collateral 配错了 —— 但它长得很像 bug。**

**换了 generated-src 必须删掉 C++ 的 `.o`。**
`difftest-state.h` 的结构体布局会跟着接口变，而 `vcs.mk` 的依赖里**没有头文件**，
增量编译会留下按旧布局编出来的 `difftest.o` / `diffstate.o` …。
症状是「整数寄存器对得上、pc 和浮点是随机值」的**假失配**
（`pc right=0x10000000, wrong=0x002d002c002d002c`）甚至裸 segfault。
`run_fullchip.sh` 的 `build()` 已经在做这件事（只删 C++ 的 `.o`，
RTL 的 `interfaceF.*.o` 不能动，否则整芯片要重编 ~55 分钟）。

## 7. 那份不匹配的 FPGA 产物

codex：「do not retain the mismatched FPGA DPI objects」。

- 本 collateral **不含**它，闸判据 B 也保证它永远进不来 —— 拿真的那份喂进闸实测当场红
  （21 vs 27，逐个列出缺的 12 个名字），见第 5 节。
- `sim-work/golden/build/generated-src.STALE-FPGA-PROFILE/`：上一位 sim worker 已改名隔离，
  现无人引用。可删，但它在并行 worker 的工作区里，本泳道没动。
- `XiangShan/build/generated-src/`（Sep 9 那份，21 个函数）：**仍在原处**。
  本轮工单明令不碰 `XiangShan/build/`，故未删。有了本目录 + `seed.sh`，
  仿真流程已**不再读取**它；但它仍是个可被误取的陷阱，建议由 `XiangShan/build/` 的
  owner 清掉。
