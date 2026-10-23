# bench-closure lane（agent/bench-closure）—— 整芯片 benchmark 执行闭包复核

codex 0244 第 3 条：保留祖先链与最终 benchmark 的已有成果，但要先确认**最终提交的执行闭包**仍与跑 benchmark 时相同；
「此后 rtl 零改动」不能单独当证明，**源选择、参数、define、存储模型**都要一致；只有执行输入变化或真实缺口才重跑。

本 lane 的对象：`/home/eda/xs-env/sim-main-2d1d`（main `2d1d134e0` 构建的 impl simv；smoke / coremark / dhrystone
difftest PASS 且逐拍 trace sha 与 golden 相同，cputest 33/33 MATCH）与当前 main `ba506f83c`。

## 结论

**`2d1d134e0` 与 `ba506f83c` 的执行闭包逐字节相同；`sim-main-2d1d` 的实际构建就是脚本算出的 `2d1d134e0` 闭包。不需要重建、不需要重跑。**

| 检查 | 结果 |
|---|---|
| `compute` 2d1d134e0 vs ba506f83c，`diff` | **IDENTICAL**（去掉 `commit`/`computed_at` 两字段后整份 JSON 逐字节相同） |
| `verify-build` 清单(2d1d134e0) vs `sim-main-2d1d` 实际构建 | **VERIFIED**，21 项检查 0 失败（见下「实际构建核对」） |
| 生成器确定性（`--determinism`，同提交再跑一次） | 两次 filelist / srcmap / 改名拷贝完全相同 |

两提交之间 main 的变化（17493 个文件）都在证书、台账、派生表、FM Makefile 与证明脚本上；执行闭包的每一项都没动：

- `rtl/` 整棵树 git tree id 两提交相同（`53a7f99e…`），`verif/sim/` tree id 相同（`d3770358…`），
  选源脚本 `xstile_sim_filelist.py` / `scripts/full_elab_filelist.py` 相同。
- rr-mcnarrow 改的 `scripts/gen_sram_wrappers.py`、`verif/ut/SRAMTemplateNewForm/gen.py` 与 4+3 个 `verif/ut/*/Makefile`：
  改的全是 `fm-<variant>: RTL_GOLDEN_DEPS = …` 这类 **FM 目标作用域**的 Makefile 变量（impl 侧 MC 存储模型逐 variant 共读），
  整芯片构建流程不读 `verif/ut/`，也不调用这两个生成器（其产物是已提交的 `rtl/common/SRAMTemplate_*.sv`）。
  另做了生成器幂等核对：两提交各自 `git archive` 到 `$TMPDIR` 后跑 `gen_sram_wrappers.py --check`（35 个产物）与
  `SRAMTemplateNewForm/gen.py --check`，**两提交都与已提交产物逐字节一致**——即 rr-mcnarrow 之后重新生成 wrapper，
  得到的 rtl 仍是 benchmark 编进去的那份。

## 执行闭包的构成（`scripts/bench_exec_closure.py` 的清单字段）

构建链：`verif/sim/run_fcb.sh build impl` → `run_fastsim.sh`（建工作区、打 vcs.mk/top.v 补丁）+ `patch_trace`（difftest.cpp
加只写文件的 commit trace）→ `run_fullchip.sh`（`XSTILE_ONLY=1` 调 `xstile_sim_filelist.py` 出清单、SimTop XMR 补丁、
`make -C difftest simv`）。impl 构建时 `SV_HOME=/home/eda/xs-env/xs-v2-sv`（main 检出），工作区 `SIMF=/home/eda/xs-env/sim-main-2d1d`。

| 字段 | 内容 | 2d1d134e0 = ba506f83c |
|---|---|---|
| `selection_inputs` | 决定**选哪些源**：`rtl/` tree id、`verif/sim/` tree id、选源脚本 sha256 | 相同 |
| `filelist` | 用**该提交自己的**选源脚本对该提交 `rtl/` + G1 golden 实算的有序编译清单，逐项路径+sha256：2028 项 = 宏头 `extern_modules.sv` 1 + rtl 1529（package-only 12 + 模块文件 1517）+ golden 469（核内登记存储模型 97、核外逻辑 326、核外存储模型 46）+ 核外改名拷贝 29 | 相同（digest `e166f0c7a15050c2…`） |
| `srcmap` | 2538 个模块 → 来源类别 → 文件（RTL_XSTILE 2039 / GOLDEN_MEM 97 / GOLDEN_OUTCORE 327 / GOLDEN_MEM_OUTCORE 46 / 改名 8+21） | 相同 |
| `outcore_renamed` | 8 个核内外共用模块的核外侧改名拷贝（29 个生成文件）sha256 | 相同 |
| `simtop_patched` | 执行该提交 `run_fullchip.sh` 里的补丁原文，对 G1 `SimTop.sv`（`2ce638a3…5b55`）9897 条 XMR→`'0` 的结果 sha256 `d6c6bff8…220b` | 相同 |
| `flow` / `flow_params` | `run_fcb.sh` / `run_fastsim.sh` / `run_fullchip.sh` sha256（vcs.mk 去 `-debug_access+all`、`-j16`、top.v 去 VPD、`FCB_COMMIT_TRACE`、make 变量 `NUM_CORES=1 RTL_SUFFIX=sv WITH_CHISELDB=0`、plusarg `+workload +diff +ram_size=8589934592`、NEMU so 路径、G1 路径都写死在里面） | 相同 |
| `verdict_tools` | `commit_compare.py` / `bench_verdict.py`（判定工具，不进 simv） | 相同 |
| `external`（工作区实测，不随提交变） | difftest 副本 185 个已打补丁文件（src/ config/ *.mk Makefile）、`impl/build/generated-src` 6 个（= `regen` 门禁源）、`chisel_db/constantin/perfCCT` 7 个拷贝、NEMU so、负载 36 个（smoke/coremark/dhrystone + cputest 33）、G1 `MANIFEST.tsv` / `CANONICAL_ID.txt`、vcs 可执行路径 | 相同（同一工作区） |

功能 define / VCS 开关（从实际 `build.log` 抽取；golden 侧 `sim-fcb/golden/build.log` 逐个相同，VCS 同为 W-2024.09-SP1）：
`+define+DIFFTEST -full64 +v2k -top tb_top -timescale=1ns/1ns -sverilog +lint=TFIPC-L -j16 +define+VCS +vcs+initreg+random
+define+RANDOMIZE_{GARBAGE_ASSIGN,INVALID_ASSIGN,MEM_INIT,REG_INIT} +define+RANDOMIZE_DELAY=1 +define+UNIT_DELAY +define+no_warning`。
参数/配置：rtl 是手写 SV，配置已固化在源里；golden 与 DPI 胶水同为 G1（KunminghuV2Config）一次生成，`check_dpic` 门禁。

## 实际构建核对（`verify-build`，sim-main-2d1d 对 2d1d134e0 清单）

1. `impl/files_impl_nosimtop.f` 2028 项与清单**逐行含顺序**一致；`srcmap.tsv` 2538 行一致；`outcore_renamed/` 29 个 sha256 一致；
   `build/rtl/SimTop.sv` sha256 = 清单补丁结果；`-y` 库目录只有 `SimTop.sv`。
2. `build.log`：读入 design file 2036 个 = 清单 2028 + SimTop 1 + difftest vsrc 7（集合相等）；从 `-y` 库读入 0 个；
   included file 只有 `impl/build/generated-src/DifftestMacros.svh`（rtl 无 `` `include ``）。
3. 构建读入的 2028 个文件**当前内容** == 清单 sha256，且 mtime **全部早于** VCS 启动时刻（2026-10-19 10:45:38）——
   构建之后没有被改写过，所以当时读到的字节就是现在的字节。
4. main 检出的 reflog：VCS 启动时刻的 HEAD = `2d1d134e0`（10:44:14 提交，14:36 才前进）。
5. golden 侧所用 471 个 G1 文件（含 SimTop）sha256 == `G1-canonical/MANIFEST.tsv`。
6. 外部输入：difftest / generated-src / build 拷贝 == 清单，且 mtime 早于构建；`impl/build/generated-src` 与 `regen` 门禁源逐文件相同。
   另：golden 侧使用的 `sim-fcb/difftest` 与 `sim-main-2d1d/difftest` `diff -rq` 只差三份 `*.patch.txt` 记录（头部路径/时间戳），
   实际被编译的文件全同；负载 `sim-fcb/workloads/*`（`sim-main-2d1d/workloads/` 为空，run 用的是 sim-fcb 那份，sim.log 可见）。

## 不在闭包里、也不需要的东西

- `verif/ut/**`、证书、台账、派生表、`scripts/proof_*` 等证明侧文件：不进 simv，也不影响选源。
- golden 侧 simv（sim-fcb）不依赖本仓提交（G1 + 同一套 difftest 与开关），其 trace 是对比基线，不受影响。

## 复现

```bash
export TMPDIR=/home/eda/xs-env/tmp-bcl; mkdir -p $TMPDIR
cd /home/eda/xs-env/wt-bench-closure            # 或任一含本脚本的检出
S=scripts/bench_exec_closure.py; W=/home/eda/xs-env/sim-main-2d1d; R=/home/eda/xs-env/xs-v2-sv
python3 $S compute --repo $R --commit 2d1d134e0 --workspace $W --determinism --out $TMPDIR/closure_2d1d.json
python3 $S compute --repo $R --commit ba506f83c --workspace $W --determinism --out $TMPDIR/closure_ba506.json
python3 $S diff $TMPDIR/closure_2d1d.json $TMPDIR/closure_ba506.json            # -> IDENTICAL, rc=0
python3 $S verify-build --manifest $TMPDIR/closure_2d1d.json --workspace $W --checkout $R \
    --golden-build-log /home/eda/xs-env/sim-fcb/golden/build.log               # -> VERIFIED, rc=0
python3 scripts/test_bench_exec_closure.py                                       # 7 PASS / 0 FAIL
# 生成器幂等（可选）：for c in 2d1d134e0 ba506f83c; do d=$TMPDIR/gencheck-$c; mkdir -p $d;
#   git -C $R archive $c scripts rtl verif/ut/SRAMTemplate verif/ut/SRAMTemplateNewForm | tar -x -C $d;
#   (cd $d && python3 scripts/gen_sram_wrappers.py --check && python3 verif/ut/SRAMTemplateNewForm/gen.py --check); done
```

`compute` 只用 `git archive` 把提交的 `rtl/ verif/sim/ scripts/full_elab_filelist.py` 解到 `$TMPDIR/bcl-<sha>`，不切换任何 worktree 的分支；
每次约 40 s（`--determinism` 再加一次）。清单 JSON 约 0.5 MB，不入库。

以后新提交是否需要重跑 benchmark：对新提交 `compute` 再 `diff` 本次的 `closure_2d1d.json`；IDENTICAL 即沿用
sim-main-2d1d 的结果，DIFFERENT 则按差异条目（filelist/srcmap 选中件 → 重建 impl 并重跑；仅 `selection_inputs.rtl_tree`
变而 filelist 不变 → 未选中件变化，选源结果已证明不变，可不重跑但应在报告中写明；`flow`/`external` 变 → 两侧都要重建）。

## 测试

`scripts/test_bench_exec_closure.py`（合成小仓 + 合成 golden，约 5 s）：同提交两次 IDENTICAL；选中 rtl 改一字节 → 指名报差；
只加未选中 rtl → 清单不变但 `rtl_tree` 报差；流程脚本改 `RAM_SIZE` → `flow`/`flow_params` 报差；存储模型改一字节 → 报差；
按清单搭的伪构建 VERIFIED，构建后改写 checkout 的 rtl → MISMATCH。
