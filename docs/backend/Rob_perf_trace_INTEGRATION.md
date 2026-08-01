# Rob perf(18) + trace(48) 集成说明 — for Rob-integrator

owner: rob-perf-trace (codex 0090 P2) · branch `agent/rob-perf-trace` · 基于 agent/rob (15d5d7d)

本 patch 只动**核** `rtl/backend/Rob.sv`(xs_Rob_core)+ 两个 UT tb, **不碰**
`Rob_wrapper.sv` / `Rob.json` / manifest / gap_schedule(integrator 单点写)。

## 一、核新增端口(xs_Rob_core)

### 新增输入(3, 供 io_perf_16 的 misPred_probe)
| 核输入 | wrapper 侧 golden flat 端口重建 |
|---|---|
| `io_wb1_redir` | `io_exuWriteback_1_valid & io_exuWriteback_1_bits_redirect_valid` |
| `io_wb3_redir` | `io_exuWriteback_3_valid & io_exuWriteback_3_bits_redirect_valid` |
| `io_wb5_redir` | `io_exuWriteback_5_valid & io_exuWriteback_5_bits_redirect_valid` |

golden `misPred_probe = 3'(mp + mp)` 其中 `mp = wb1 + wb3 + wb5`(即 2×sum,
golden 自带的翻倍 "bug", 已 bug-for-bug 复刻)。这 3 个 flat 端口 wrapper 已有
(Rob_wrapper.sv line 837/853/867), integrator 组合重建后接核。

### 新增输出(18 perf + 6 trace 数组/向量)
perf: `o_perf_0_value` .. `o_perf_17_value`,均 `[5:0]`。
trace(8 块,索引 0..7):
- `o_trace_valid`        `[7:0]`            → blocks_N_valid
- `o_trace_ftqIdx_value` `[6][5:0]?` → 数组 `[FTQ_PTR_W-1:0][COMMIT_WIDTH]`  → blocks_N_bits_ftqIdx_value
- `o_trace_ftqOffset`    数组 `[FTQ_OFFSET_W-1:0][8]` → blocks_N_bits_ftqOffset
- `o_trace_itype`        数组 `[ITYPE_W-1:0][8]`      → blocks_N_bits_tracePipe_itype
- `o_trace_iretire`      数组 `[IRETIRE_W-1:0][8]`    → blocks_N_bits_tracePipe_iretire
- `o_trace_ilastsize`    `[7:0]`                       → blocks_N_bits_tracePipe_ilastsize

## 二、wrapper 连接(66 golden 端口 ← 核输出)

```
// PERF (18)
.io_perf_0_value  (u_core.o_perf_0_value),   ...  .io_perf_17_value (u_core.o_perf_17_value),
// TRACE (48) — N = 0..7
.io_trace_traceCommitInfo_blocks_N_valid                     (u_core.o_trace_valid[N]),
.io_trace_traceCommitInfo_blocks_N_bits_ftqIdx_value         (u_core.o_trace_ftqIdx_value[N]),
.io_trace_traceCommitInfo_blocks_N_bits_ftqOffset            (u_core.o_trace_ftqOffset[N]),
.io_trace_traceCommitInfo_blocks_N_bits_tracePipe_itype      (u_core.o_trace_itype[N]),
.io_trace_traceCommitInfo_blocks_N_bits_tracePipe_iretire    (u_core.o_trace_iretire[N]),
.io_trace_traceCommitInfo_blocks_N_bits_tracePipe_ilastsize  (u_core.o_trace_ilastsize[N]),
```

注: golden `blocks_N_bits_ftqIdx_value` 是 `[5:0]` (=FTQ_PTR_W), `ftqOffset` `[3:0]`
(=FTQ_OFFSET_W), `tracePipe_itype/iretire` `[3:0]` (=ITYPE_W/IRETIRE_W), 位宽逐一对齐。

## 三、验证状态(本 worker 局部)
- VCS elaborate xs_Rob_core: PASS(0 err)。
- `verif/ut/Rob/tb_perftrace.sv`(golden 公式参考块 + 层次探针比对 66 端口):
  seed 1/7/42 各 ~200k cycles,`checks=199994 errors=0 (perf_err=0 trace_err=0)` TEST PASSED。
- `verif/ut/Rob/tb.sv`(smoke, 已加 3 输入 + perf/trace X-check):seed1 `checks=200000 errors=0` PASS。
- **不含** golden 双例化 cycle-exact(核接口是控制锥,非 golden port-for-port);
  端口面等价由 assembly FM 在 wrapper 补齐后覆盖(FM_VARIANTS=Rob 启用时)。

## 四、边界(与其他 Rob 组)
- A_CORE(70): 已由 agent/rob 核产出,本 patch 不动。
- B_SHALLOW(92): 属另一组(rabCommits/exception REG 等)。本 patch **只读**内部
  `exceptionValidReg`(核已有,§10)与本地 `isInterrupt_r`(核内新增本地副本,不产
  exception 端口),供 trace block0 的 itype 异常覆盖;不与 B_SHALLOW 的
  `io_exception_bits_isInterrupt_r` 端口冲突。
- 其余 C_DEEP(csr/lsq/debugTopDown/vecExcp/toDecode/error 等,共 100-66=34):属其他组。
```
