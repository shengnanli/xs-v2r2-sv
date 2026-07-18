# 香山 V2R2 (昆明湖) SystemVerilog 手工重写工程

将香山 V2R2（XiangShan `kunminghu-v2r2` 分支）的 Chisel/Scala 代码逐模块手工重写为
**可读、可维护的 SystemVerilog**，为每个模块撰写设计文档，并建立 UT/IT/BT/ST 四级验证体系。

## 当前进度

| 子系统 | 状态 | 说明 |
|--------|------|------|
| **Frontend 前端** | ✅ 100% | 分支预测 / 取指 / ICache / Ftq / 顶层（34 模块） |
| **MemBlock 访存** | ✅ 100% | LSU / 队列 / MMU（含 L2TLB·PtwCache） / DCache / 顶层（46 模块） |
| **Backend 后端** | ✅ 基本完成 | FU / 译码 / 重命名 / 写回 / 旁路 / ROB / DataPath / Dispatch / CtrlBlock / 14 个发射队列变体 / 4 个 Scheduler / ExeUnit / NewCSR / Backend 顶层（60+ 模块，均 UT+FM 验证） |

详细模块清单与验证状态见 `status.md`；各子系统导读见 `docs/{frontend,memblock,backend}/`（`MEMBLOCK_OVERVIEW.md` / `BACKEND_OVERVIEW.md`）。重写硬性标准见 `docs/REWRITE_STYLE.md`。

## 总体方法学

每个模块的交付物与验证闭环：

```
Scala 源码 ──阅读理解──► 手写可读 SV (rtl/)  +  模块文档 (docs/)
                              │
        ┌─────────────────────┼──────────────────────┐
        ▼                     ▼                      ▼
   UT 单元仿真           FM 等价性检查           (逐级集成)
  VCS testbench         手写 SV vs golden        IT → BT → ST
  双例化比对golden       (每个单态化变体)
```

- **golden reference**：`golden/chisel-rtl/`（软链至**非 difftest 冻结基线**，当前为
  `xs-clean/build/rtl/`，Chisel+firtool 生成的分模块 SV）。生成来源（主仓 commit、子模块 SHA、
  配置、difftest 开关、工具版本、复现步骤）与 1802 个文件的字节 hash 见
  **`verif/freeze/GOLDEN_MANIFEST.md`** 与 **`verif/freeze/golden.sha256`**——FM/UT 结果只有在
  golden 字节 hash 与该清单一致时才可复核。Chisel 会把参数化模块单态化为多个变体（如 `WrBypass.sv`、
  `WrBypass_32.sv`...）；手写 SV 写成**一个参数化模块**，每个变体用对应参数例化后分别做
  等价验证。
- **端口命名约定**：手写模块的顶层端口名与 Chisel 生成 RTL 完全一致（`io_*` 风格），
  以便 Formality 自动匹配端口、以及在 ST 级直接替换进香山仿真环境。模块内部信号则
  使用可读命名、自由重构。
- **等价性**：Formality (`fm_shell`) 做形式等价；FM 因黑盒/SRAM/时序差异不可判定时，
  退回 UT 双例化随机比对 + BT/ST 仿真回归兜底。

## 四级验证平台

| 级别 | 对象 | 平台 | 参考模型 |
|------|------|------|----------|
| UT 单元级 | 单个模块 | VCS testbench（SV，随机+定向激励）+ Formality | golden RTL 双例化 / FM |
| IT 集成级 | 若干模块互联（如 BPU=Composer+各预测器） | VCS testbench | golden 子层次双例化 |
| BT 块级 | Frontend 整个子系统 | VCS testbench，桩掉/接入下游 | golden Frontend |
| ST 系统级 | 全核跑程序 | 复用香山 difftest + NEMU（VCS `make simv` 流程），手写 SV 替换进 build/rtl | NEMU 指令级比对 |

## 目录结构

```
xs-v2r2-sv/
├── README.md            本文件
├── status.md            模块进度跟踪表（重写顺序、各级验证状态）
├── rtl/
│   ├── common/          公共 package / 工具模块（如参数化队列、SRAM wrapper）
│   ├── frontend/        前端手写 SV（✅ 完成）
│   ├── memblock/        访存手写 SV（✅ 完成）
│   └── backend/         后端手写 SV（✅ 基本完成）
├── docs/
│   ├── frontend/        每模块一份中文 Markdown 设计文档
│   ├── memblock/        访存（含 MEMBLOCK_OVERVIEW.md 导读）
│   ├── backend/         后端（含 BACKEND_OVERVIEW.md 导读）
│   └── REWRITE_STYLE.md 可读重写硬性闸门（结构指标 + .svh 套壳检查）
├── golden/chisel-rtl@   软链 → XiangShan/build/rtl（Chisel 生成的参考 RTL）
├── verif/
│   ├── ut/<Module>/     单元级：tb.sv + Makefile + fm/ 等价检查
│   ├── it/              集成级
│   ├── bt/              块级（Frontend 子系统）
│   └── st/              系统级（difftest 替换流程脚本）
└── scripts/
    ├── env.sh           工具环境（VCS 须 -full64，见下）
    ├── ut_common.mk     UT 通用 Makefile（vcs 编译/仿真/verdi/fm 目标）
    └── fm_eq.tcl        Formality 等价检查通用脚本（参数经环境变量传入）
```

## 工具环境注意事项

- 本机 `VCS_ARCH_OVERRIDE=linux`（.bashrc 已设）是**必需**的，且 vcs **必须带 `-full64`**，
  否则报 OS 不支持 / 找不到编译器（Rocky 8.10 + VCS W-2024.09-SP1 的兼容性问题）。
- 工具版本：VCS/Verdi W-2024.09-SP1，Formality V-2023.12-SP3，license `27080@localhost`。

## 常用命令

```bash
# 跑某个模块的 UT（编译+仿真+比对）
cd verif/ut/WrBypass && make run

# 跑该模块所有变体的 Formality 等价检查
cd verif/ut/WrBypass && make fm

# 打开 Verdi 看波形
cd verif/ut/WrBypass && make verdi
```

## 重新生成 golden RTL

```bash
cd /home/eda/xs-env/XiangShan
tools/kunminghu_v2r2_flow.sh gen-rtl   # 产物在 build/rtl/
```
