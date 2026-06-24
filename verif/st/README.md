# ST 系统级验证（重写 SV 替换进香山 difftest）

把可读重写模块替换进香山 V2R2 golden RTL 库，用 **VCS difftest + NEMU** 跑真实程序
（coremark）做系统级（System Test）验证：重写模块在整片真实激励下与 NEMU 黄金模型逐
指令比对。本目录是该流程的**工具 + 脚手架**。

> 状态：工具就绪并已用 Alu / Bku / FAlu 三个 bundle 做过独立 VCS elaborate 干跑（exit 0）。
> 全片替换+difftest 实跑须等 golden 基线编完（基线在编时严禁碰 `build/rtl`）。

---

## 1. 为什么走 VCS difftest，而非 verilator emu

- 仓库里**预编译的 verilator `emu` 因宿主 glibc 版本不匹配跑不动**，故 ST 走宿主 VCS。
- VCS difftest 路径在宿主可行（已验证可编可跑）：

  ```bash
  cd $NOOP_HOME && make -C difftest simv \
      DESIGN_DIR=$PWD NUM_CORES=1 RTL_SUFFIX=sv WITH_CHISELDB=0 \
      NOOP_HOME=$PWD NEMU_HOME=$PWD
  make -C difftest simv-run        # coremark + NEMU difftest
  ```
- **`WITH_CHISELDB=0`**：避开缺 `sqlite3.h` 的编译失败。
- **`NUM_CORES=1`**：单核 difftest。
- **`RTL_SUFFIX=sv`**：库文件后缀。
- **`VCS_ARCH_OVERRIDE=linux` 必须配 `-full64`**（VCS 环境怪癖，run_st.sh 已固定）。

difftest 的 VCS 编译用 `-y $NOOP_HOME/build/rtl +libext+.v +libext+.sv` 把 `build/rtl`
当**库目录**，按 “文件名 = 模块名” 解析全部 ~1800 个 golden RTL。

---

## 2. 替换机制（bundle）

一个重写模块 `M` 的源在 `rtl/<sub>/` 下分三件（有的多一个 svh）：

| 文件 | 角色 |
|------|------|
| `<m>_pkg.sv`（如 `alu_pkg.sv`） | 类型/枚举/函数包 `package …;`（**注意包名不一定等于文件名**：`bku_pkg.sv` 内是 `xs_bku_pkg`） |
| `M.sv` | 可读核 `module xs_M_core`（真逻辑） |
| `M_wrapper.sv` | golden 同名 `module M`，端口与 golden 完全一致，内部例化 `xs_M_core` |
| `*.svh`（可选） | 大模块的端口/连线分片，被核 `` `include `` |

**机制**：`substitute.sh` 把 `[package… → 可读核（svh 内联）→ wrapper(module M)]` 拼成
**单文件 bundle**，命名 `M.sv` 覆盖进 `build/rtl/M.sv`（原 golden 备份为 `M.sv.golden`）。
VCS 的 `-y` 按模块名 `M` 拉到这个 bundle，**整文件一起编**：package 在最前先编，核次之，
wrapper（golden 同名 module M）在最后，被全片其它模块例化。

为什么 svh 必须**内联**而非 `` `include ``：difftest 的 VCS 只 `+incdir GEN_VSRC_DIR`，
不含 `rtl/` 子目录，bundle 里若留 `` `include "x.svh" `` 会找不到文件。脚本用一个内联器把
`` `include `` 行原地替换为 svh 内容（递归 + 去重）。

**叶子处理**：
- 纯叶子核（如 `xs_Alu_core` 不例化任何子模块）：bundle 自包含，golden 原来的叶子
  （`AluDataModule` 等）变孤儿，无害（没人例化它们）。
- 黑盒叶子核（如 `xs_FAlu_core` 黑盒 golden `FloatAdder`、`xs_MulUnit_core` 黑盒
  `ArrayMulDataModule`）：bundle 里**不带**那个叶子，靠 `-y` 在 `build/rtl` 里自动解析到
  原 golden 叶子文件。这些叶子文件保持原样、不替换。

---

## 3. 工具用法

所有脚本默认 `NOOP_HOME=/home/eda/xs-env/XiangShan`，可用环境变量覆盖。

### `substitute.sh <M> [--dry-run] [--out <file>]`
找 `M` 的 pkg/核/wrapper/svh，拼 bundle。
- `--dry-run`：**只生成 bundle 到临时文件，绝不碰 `build/rtl`**。golden 基线在编时只用这个。
- `--out <file>`：把 bundle 另存（配合 `--dry-run` 做独立 elaborate）。
- 无 `--dry-run`：install 模式——备份 golden 为 `.golden`，覆盖 `build/rtl/M.sv`。
- **包冲突守卫**：install 时若 bundle 的某 package 已被另一已安装 bundle 定义（共享包，如
  `xs_ftb_pkg`、`vset_pkg`），脚本拒绝并提示先 restore 那个模块（否则全片编译 package 重定义）。

```bash
# 安全干跑：生成 Alu bundle 并存出来，不动 build/rtl
verif/st/substitute.sh Alu --dry-run --out /tmp/alu_bundle.sv
# 真正安装（基线编完后再做）
verif/st/substitute.sh Alu
```

### 独立 elaborate 干跑（验证 bundle 编得过、模块名对）
在临时目录、用 golden 库作 `-y` 喂 bundle（**不动 build/rtl**）：

```bash
export VCS_ARCH_OVERRIDE=linux
vcs -full64 -sverilog -timescale=1ns/1ps +v2k \
    -y $NOOP_HOME/build/rtl +libext+.v+.sv +define+SYNTHESIS \
    -top M /tmp/M_bundle.sv -o simv_M
```
看到 `Top Level Modules: M` + `recompiling package …` + `recompiling module M` + 链接成功
即过。**已验证**：Alu / Bku / FAlu 均 exit 0。

### `restore.sh <M> | --all | --list`
把 `build/rtl/M.sv.golden` 还原回 `M.sv`。`--list` 列当前被替换的模块；`--all` 全还原。

### `run_st.sh {env|build|run|sub <M…>|restore-all}`
封装基线编译 + difftest 运行。
- `env`：打印环境并自检 vcs / workload / build/rtl / 已替换模块。
- `build`：编 golden 基线 simv。
- `run`：跑当前 simv（默认 `coremark-2-iteration.bin`；设 `REF_SO=<nemu.so>` 开 difftest 比对）。
- `sub <M…>`：substitute 安装这些模块 → 重编 → 跑。
- `restore-all`：还原所有替换（之后需重新 `build`）。

```bash
verif/st/run_st.sh env
verif/st/run_st.sh build && verif/st/run_st.sh run
verif/st/run_st.sh sub Alu          # 替 Alu 后整片重编+跑
verif/st/run_st.sh restore-all
```

---

## 4. 已知环境约束 / 风险

- **golden 基线在编时严禁碰 `build/rtl`**：只用 `substitute.sh --dry-run` + 独立 elaborate。
- **共享 package 冲突**：`xs_ftb_pkg`（FTB/FauFTB/… 4 模块）、`vset_pkg`（VSetRiWi+VSetRvfWvf）、
  `xs_ptw_pkg`、`xs_pmp_pkg`、`xs_predecode_pkg`、`xs_l1metaarray_pkg`、`exceptionbuffer_pkg`
  被多模块共用。**不能同时替换共用同一包的两个模块**（package 会重定义）。守卫已拦截；要同时上
  须把它们 co-bundle（共享包只出现一次）——首批候选刻意避开这种情形。
- **`SYNTHESIS` define**：全片 difftest 编译默认会带各种 `RANDOMIZE_*`/断言宏。重写核无随机初始化、
  无非综合断言，行为与 `SYNTHESIS` 下的 golden 对齐；独立 elaborate 干跑统一加 `+define+SYNTHESIS`。
  全片实跑沿用 difftest 自己的宏集即可（重写核对这些宏不敏感）。
- **包名 ≠ 文件名**：脚本靠解析 `import X::*` + 全库搜 `package X;` 定位包文件，不靠文件名猜。
- **wrapper 端口必须与 golden 逐位一致**：这是替换正确性的前提（已由各模块 FM 等价保证）。
  ST 只是把 FM/UT 已验证的 wrapper 放进真实系统再跑一遍动态确认。
- **license**：VCS/FM 依赖 Synopsys license（`lmgrd`）；许可证偶发 DOWN 时需先起 `lmgrd`。

---

## 5. 候选模块清单

见 `candidates.md`——列出适合首批替换的自包含模块（纯叶子 FU + 黑盒单叶子 FU）及各自
bundle 文件清单与黑盒依赖。
