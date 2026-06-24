# ST 系统级验证（重写 SV 替换进香山 difftest）

把可读重写模块替换进香山 V2R2 golden RTL 库，用 **VCS difftest + NEMU** 跑真实程序
（coremark）做系统级（System Test）验证：重写模块在整片真实激励下与 NEMU 黄金模型逐
指令比对。本目录是该流程的**工具 + 脚手架**。

> 状态：**已系统级实测通过**。golden 基线、替换 **Alu**(组合)、替换 **Bku**(2 拍流水)、
> 以及 **Alu+Bku 同替** 三种情形, coremark + NEMU difftest 均 **HIT GOOD TRAP @ cycle 6492**
> (与 golden 完全一致)。工具支持 **全端口 wrapper**(见 §2.1), 父模块例化不再 Undefined port。

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

## 2.1 全端口 wrapper（核心机制，已系统级实测）

**问题**：重写的子集 wrapper（`Alu_wrapper.sv` 等）为可读性**故意省略** golden 的
非功能口——背压 `io_in_ready`/`io_out_ready`、性能调试 `io_in/out_bits_perfDebugInfo_*`
（eliminatedMove/renameTime/dispatchTime/writebackTime/runahead_checkpoint_id/
tlbFirstReqTime/tlbRespTime）、`io_*_bits_debug_seqNum` 等（Alu ~22 个）。父模块
（`ExeUnit`）例化时**按 golden 全端口连线**，wrapper 少了这些口 → VCS
`Error-[UPIMI-E] Undefined port`，全片编译失败。

**解法**（`gen_full_wrapper.py`，`substitute.sh` 自动调用）：

1. 解析 **golden** `build/rtl/M.sv`（或已替换时的 `M.sv.golden` 备份）的**完整端口表**
   （名字 + 方向 + 位宽，逐行原样）。
2. 把重写子集 wrapper `module M(...)` **改名**为 `module xs_M_subset(...)`，原样保留
   （它例化重写核 `xs_M_core`），作为内部子模块。
3. 生成新的 `module M`：端口 = **golden 全端口 1:1**；内部例化 `xs_M_subset`，按名直连
   两边都有的口；golden 多余口这样驱动——
   - `io_in_ready` → `assign io_in_ready = io_out_ready;`（背压直通，等同 golden）；
   - 多余输出 `io_out_bits_X`，若有同位宽的 `io_in_bits_X` → `assign out = in;`
     （perf/debug **零延迟直通**）；否则 `assign out = '0;`（占位）；
   - 多余输入：声明即可，内部不接（无害）。

> **为什么对 difftest 无害**：difftest 的架构正确性比对（NEMU 逐指令）只看 ROB 提交的
> PC/指令/写回值/CSR/内存，**不看** FU 的 perf/debug/seqNum 旁路。真正功能相关的
> `io_out_valid`/`io_out_bits_ctrl_*`/`io_out_bits_res_data` 全部来自重写核；
> `io_in_ready` 背压直通 `io_out_ready`——这些 FU 写回端 `io_out_ready` 在本配置恒就绪，
> 故直通与 golden 行为一致，不死锁、不改时序。
>
> **实测**：替 Alu（组合，perf 本就零延迟直通 → 与 golden **逐位一致**）、替 Bku（2 拍
> 流水，5 个未建模 perf 字段零延迟直通、3 个建模字段经核打两拍）、Alu+Bku 同替——
> coremark difftest 均 **HIT GOOD TRAP @ cycle 6492**（== golden cycle 数）。

**root-scope 守护**：个别重写核（`Bku.sv`）在 `$root`（任何 package/module 之外）写了裸
`typedef struct {...} NAME;`。VCS 把 `build/rtl/M.sv` 当 `-y` 库文件用：先扫描建索引，
解析 `module M` 时**重读**整文件 → `$root` 裸构件被解析两次，报
`Identifier previously declared (IPD)` + `ICILF`（root 构件须包在
`` `ifndef/`define/`endif `` 内）。`substitute.sh` 的 **2b 步**把每个 root-scope
typedef/parameter 各自用**独立** guard（`ST_<M>_ROOT_G<n>`）包裹，令库重读时跳过。
（纯 `package + module` 的 bundle 如 Alu 无此问题——package/module 不受该规则限制。）

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
