# verif/sim —— 整芯片（SimTop + difftest + NEMU）仿真泳道

## 一句话

`scripts/full_elab.sh` 证明的是「整芯片 **XSTop** 在 `+define+SYNTHESIS` 下能 elaborate」。
**仿真是另一次完全不同的编译**：top 是 `tb_top` → `SimTop` → `XSTop`，
**不定义 SYNTHESIS**、定义 `DIFFTEST`，走 difftest 官方 VCS 流。
前者 0 error 不蕴含后者能编，实测也确实不蕴含（见下）。

## 三个编译维度的差别

| | full_elab.sh | 本泳道（仿真） |
|---|---|---|
| top | `XSTop` | `tb_top`（difftest）→ `SimTop` → `XSTop` |
| `SYNTHESIS` | **定义** | **不定义**（golden 的断言/随机初值/DPI 全部生效） |
| `DIFFTEST` | 无 | 定义（DPI-C 架构状态导出） |
| 寄存器初值 | — | `+vcs+initreg+random` + `RANDOMIZE_*`（golden 默认配置） |
| `SimTop.sv` | 不参与 | 参与，且带 9897 条层次引用（见下） |

## 已知阻塞：SimTop 的 9897 条 perfCnt_bore 层次引用（XMR）

golden `SimTop.sv` 里 `LogPerfEndpoint logEndpoint(...)` 这一个例化，用 **9897 条
绝对层次引用** 把模块**内部**信号直接引上来，例如：

```
.perfCnt_bore_3 (SimTop.cpu.l_soc.core_with_l2.core.frontend.inner_icache.mainPipe._GEN_0),
.perfCnt_bore_11(SimTop.cpu.l_soc.core_with_l2.core.frontend.inner_icache.missUnit._priorityFIFO_io_enq_valid_T_probe),
```

被引的名字是 firtool 产物（`_GEN_n` / `_T_n_probe` / `*_probe`），**重写件里根本不存在
同名内部信号**，于是整芯片仿真编译直接
`Error-[XMRE] Cross-module reference resolution error` 报死。
这是**端口级 bore（`gatewayIn_packed_bore` / `sigFromSrams_bore_*`，docs 里已登记）
之外的另一套机制**，此前未在本仓登记过。

`LogPerfEndpoint` 共 9903 个端口，**全部是 input**（无任何 output），是纯观测 sink；
perfCnt 只喂性能计数器，不参与 difftest 架构状态比对。所以本泳道的处理是：
在**自己的工作区**生成 `SimTop.sv` 的打补丁副本，把这 9897 条 XMR 接成常量 `'0`。
**不改 golden（只读）、不改 `rtl/`**。补丁由 `run_fullchip.sh setup impl` 机械生成，可复算。

> 代价（如实记）：impl 侧的性能计数器全灭。架构行为与 difftest 判定不受影响，
> 但「perf 计数与 golden 一致」这条不在本轮验收范围内了。
> 若要恢复，唯一的正路是让重写件按 golden 的内部信号名保留这些探针（层次重绑泳道）。

## 用法

```bash
verif/sim/run_fullchip.sh build golden     # golden 对照基线（不打补丁）
verif/sim/run_fullchip.sh build impl       # 重写件优先 + SimTop 打补丁
verif/sim/run_fullchip.sh run   golden     # coremark-2-iteration + NEMU difftest
verif/sim/run_fullchip.sh run   impl
```

工作区默认 `/home/eda/xs-env/sim-work/{golden,impl}`（`SIMW=` 可改），
不落在任何 git worktree 里。

## 里程碑怎么读

- **出时钟**：`tb_top` 自己产生，`initial #100 reset=0`。
- **复位释放**：仿真时间 100ns。
- **第一条指令提交（retirement）**：日志出现
  `The first instruction of core 0 has commited. Difftest enabled.`
  判据在 difftest C++ 侧：`commit[0].pc == FIRST_INST_ADDRESS`(0x10000000)。
  超时则是 `The first instruction of core 0 at 0x10000000 does not commit after N cycles.`
  —— **本工程踩过一次坑**：这条超时信息曾经不是 DUT 坏，而是 golden RTL 生成时
  `--enable-difftest` 没生效、commit pc 恒 0（见 memory `golden-coremark-difftest.md`）。
  G1-canonical 已复核：`DiffExtInstrCommit` 的 `io_pc [63:0]` 端口在、
  `GatewayEndpoint.sv` 里接的是真信号 `_validated_module_out_bits_6_bits_pc`，**不是常量**。
- **终点**：`HIT GOOD TRAP` + `DIFFTEST WORKLOAD DONE at cycle N`（golden 上一轮 = 6492）。
- **功能失配**：difftest 打 `Mismatch detected ...` 并 dump ref/dut 寄存器对照。

## 运行必需参数

`+ram_size=8589934592`（8GiB）—— 默认 8TB 会让 NEMU `init_mem` 崩。
