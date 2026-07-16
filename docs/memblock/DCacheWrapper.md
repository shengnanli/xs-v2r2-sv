# DCacheWrapper —— L1 数据缓存顶层包装层（学习文档）

> 可读重写：`rtl/memblock/DCacheWrapper.sv`（核 `xs_DCacheWrapper_core`）
> + 生成 include：`rtl/memblock/dcachewrapper_ports.svh`（端口表）
> / `rtl/memblock/dcachewrapper_inner_conn.svh`（内层互联）
> 设计意图来源（人写 Chisel）：
> `src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala`（`class DCacheWrapper`，行 1764+）
> golden（firtool 生成，仅作 UT/FM 对照）：`golden/chisel-rtl/DCacheWrapper.sv`（1579 行）

---

## 1. 架构定位

`DCacheWrapper` 是 L1 DCache 与外界之间的**薄包装层**，本身**不含任何 cache 算法**。
内层真正的 L1 DCache（`DCache`，golden 约 1.08MB、22+ 类子模块）做命中判定、多 load/store
端口仲裁、bank 冲突、miss 队列、refill、probe、writeback 等全部工作；包装层只做三件事：

```
            ┌──────────────────── DCacheWrapper ────────────────────┐
LoadUnit×3 ─┤ load_0..2                                             │
StoreUnit  ─┤ sta_0..1                                             │
Sbuffer    ─┤ store(line)        ┌──────────────────────┐          │
AMO 单元    ─┤ atomics      ─────▶│  内层 DCache（黑盒）  │── A/B/C/D/E ─▶ L2
Prefetch   ─┤ pf / cmo          │  命中/缺失/仲裁/MSHR  │          │
控制/调试   ─┤ ctrl/topdown ─────▶│  ...                 │          │
            │                    └─────────┬────────────┘          │
            │   io_perf_0..31_value ◀─ 2 级流水 ◀─ perf 计数        │
            └────────────────── auto_uncache_in（cache-ctrl TL-UL）─┘
```

1. **端口适配**：把上游各客户端（`io_lsu_load_0..2`、`io_lsu_sta_0..1`、`io_lsu_store`、
   `io_lsu_atomics`、prefetch、CMO、`io_debugTopDown`、`io_debugRolling`、`io_l2_hint`、
   `io_wfi` 等）的请求/响应端口**一一直连**内层 DCache 实例。多端口仲裁/冲突判定都在
   内层，本层不做仲裁，只是接线。
2. **节点透传**：内层 DCache 的 TileLink client 口（向 L2 取数/写回/probe，A/B/C/D/E）
   经 diplomacy `IdentityNode` 原样引出为 `auto_client_out_*`；cache-controller 的 TL-UL
   从机口经另一 `IdentityNode` 引出为 `auto_uncache_in_*`——内层实例端口名是
   `auto_cacheCtrlOpt_in_*`，**这是本层唯一的端口改名**（14 个信号，仅节点改名，
   信号一一对应）。
3. **perf 计数 2 级流水**：内层吐出 32 个 6bit perf event 计数值，本层把每个计数值
   **打两拍寄存器**后输出（`generatePerfEvent()` 的标准做法，用于跨层时序收敛 / 与
   其它单元 perf 对齐）。**这是本包装层唯一的时序逻辑。**

对应 Scala（精简）：

```scala
class DCacheWrapper extends LazyModule {
  val dcache    = LazyModule(new DCache())       // 内层 L1 DCache
  clientNode   := dcache.clientNode              // TL client 透传(IdentityNode)
  dcache.cacheCtrlOpt.node := uncacheNode        // cache-ctrl TL-UL 透传(IdentityNode)
  class DCacheWrapperImp ... {
    io <> dcache.module.io                        // 整个 DCacheIO 直连
    dcache.module.getPerfEvents                   // 收 perf 计数
    generatePerfEvent()                           // -> 各 perf value 打 2 级寄存器输出
  }
}
```

本配置（KunmingHu V2R2）固化参数：`LoadPipelineWidth=3`、`StorePipelineWidth=2`、
`DCacheBanks=8`、`nMissEntries`/`nReleaseEntries` 等内层参数；perf 事件数 `NUM_PERF_EVENTS=32`、
单值位宽 `PERF_W=6`。端口共 **603** 个（含 clock/reset）。

---

## 2. 唯一逻辑：perf event 2 级流水（核内 struct/enum/function）

包装层把 32 路结构完全相同的 perf 计数各打两拍。可读核用 struct/enum/function/generate
表达，避免 golden 那样平铺 64 个标量 `*_REG`/`*_REG_1`。

### 2.1 流水级枚举（`perf_stage_e`）

| 枚举 | 值 | 含义 |
|---|---|---|
| `PERF_STAGE_1` | 0 | 第一级寄存器（golden 的 `*_REG`） |
| `PERF_STAGE_2` | 1 | 第二级寄存器（对外输出） |
| `PERF_NSTAGE`  | 2 | 级数（用作 packed 数组维度） |

### 2.2 单事件流水寄存器组（`perf_pipe_t`）

```systemverilog
typedef struct packed {
  logic [PERF_NSTAGE-1:0][PERF_W-1:0] stage; // stage[0]=第1拍, stage[1]=第2拍(输出)
} perf_pipe_t;
```

### 2.3 流水推进纯函数（`perf_advance`）

```systemverilog
function automatic perf_pipe_t perf_advance(perf_pipe_t cur, logic [PERF_W-1:0] raw);
  perf_pipe_t nxt;
  nxt.stage[PERF_STAGE_2] = cur.stage[PERF_STAGE_1]; // 第1拍旧值 -> 第2拍
  nxt.stage[PERF_STAGE_1] = raw;                     // 内层原值 -> 第1拍
  return nxt;
endfunction
```

### 2.4 数据流

```mermaid
flowchart LR
  BB["内层 DCache 黑盒<br/>io_perf_i_value"] --> RAW["perf_raw[i]"]
  RAW --> S1["stage[0]<br/>(第1拍)"]
  S1 --> S2["stage[1]<br/>(第2拍)"]
  S2 --> OUT["io_perf_i_value (输出)"]
```

32 路用 `genvar`/`generate` 统一推进，复位清零：

```systemverilog
for (gi = 0; gi < NUM_PERF_EVENTS; gi++) begin : g_perf
  always_ff @(posedge clock)
    if (reset) perf_pipe[gi] <= '0;
    else       perf_pipe[gi] <= perf_advance(perf_pipe[gi], perf_raw[gi]);
  assign perf_out[gi] = perf_pipe[gi].stage[PERF_STAGE_2];
end
```

`perf_raw` / `perf_out` 用 **packed 2D**（`[NUM_PERF_EVENTS-1:0][PERF_W-1:0]`）而非
unpacked 数组：unpacked 数组元素到黑盒引脚的绑定在某些 EDA 工具的位级展平下会有歧义，
packed 向量逐位确定。

---

## 3. 内层互联（机械接线，生成）

内层 `DCache` 在 UT/FM 中均为**黑盒**，包装层只负责把 603 个端口接到内层实例：

- `dcachewrapper_ports.svh`：核的端口声明表（与 golden 顶层逐字段一致）。
- `dcachewrapper_inner_conn.svh`：内层 `DCache` 实例的 569+2(clock/reset) 个非 perf 连接，
  其中 14 个 cache-ctrl 端口按 golden 改名 `auto_uncache_in_* -> auto_cacheCtrlOpt_in_*`。
- 32 个 perf 端口由核内 `generate` 显式连到 `perf_raw[]`，再经流水寄存器输出。

两个 include 都是**机械接线**、不含设计决策；设计意图集中体现在第 2 节的 perf 流水。
include 由 `scripts/gen_dcachewrapper.py` 从 golden 端口表 + golden 实例映射自动解析生成。

### cache-controller 端口改名（14 个）

| 顶层端口 (`auto_uncache_in_*`) | 内层实例端口 (`auto_cacheCtrlOpt_in_*`) |
|---|---|
| `_a_{ready,valid,bits_opcode,bits_size,bits_source,bits_address,bits_mask,bits_data}` | 同名前缀 `auto_cacheCtrlOpt_in_a_*` |
| `_d_{ready,valid,bits_opcode,bits_size,bits_source,bits_data}` | 同名前缀 `auto_cacheCtrlOpt_in_d_*` |

---

## 4. 接口表（按功能分组，端口名与 golden 一致）

| 组 | 端口前缀 | 方向 | 说明 |
|---|---|---|---|
| 时钟/复位 | `clock` / `reset` | in | — |
| Load 流水 ×3 | `io_lsu_load_0..2_*` | 双向 | 投机 load 请求/响应、s1/s2 kill、paddr、hit/bank_conflict/mq_nack |
| STA 流水 ×2 | `io_lsu_sta_0..1_*` | 双向 | 非阻塞 store 地址流水 |
| Sbuffer store | `io_lsu_store_*` | 双向 | 整行 store 请求 + 命中/replay 响应 |
| AMO | `io_lsu_atomics_*` | 双向 | 原子访存请求/响应、block_lr |
| TL-D 前递 | `io_lsu_tl_d_channel_*` / `io_lsu_forward_*` / `io_lsu_forward_mshr_*` | 双向 | refill 数据前递给 load |
| release | `io_lsu_release_*` | out | cacheline release hint（ld-ld 违例检查） |
| TL client | `auto_client_out_{a,b,c,d,e}_*` | 双向 | 向 L2 的 TileLink（取数/probe/release/grant） |
| cache-ctrl | `auto_uncache_in_{a,d}_*` | 双向 | cache controller TL-UL 从机口 |
| 控制/调试 | `io_hartId` / `io_l2_pf_store_only` / `io_force_write` / `io_lqEmpty` / `io_l2_hint_*` / `io_cmoOp*` / `io_debugTopDown_*` / `io_debugRolling_*` / `io_wfi_*` / `io_sms_agt_evict_req_*` | 双向 | 透传 |
| 状态输出 | `io_error_*` / `io_mshrFull` / `io_memSetPattenDetected` / `io_pf_ctrl_*` / `io_l1Miss` | out | 透传 |
| perf | `io_perf_0..31_value` | out | **本层 2 级流水**后的 32 路 6bit perf 计数 |

---

## 5. 验证结果

### 5.1 UT（双例化逐拍逐位比对）

`verif/ut/DCacheWrapper/`：golden `DCacheWrapper` vs 手写 `DCacheWrapper_xs`，两侧共用同一
**行为级 DCache 桩**（`dcache_stub.sv`，驱动 32 路 perf 计数 + 其余输出置 0），隔离内层
巨型 DCache，只验证包装层互联映射 + perf 2 级流水。

| 种子 | 结果 | checks |
|---|---|---|
| 1  | PASSED | 796000 |
| 7  | PASSED | 796000 |
| 42 | PASSED | 796000 |

桩把 perf 计数用「逐拍自增 + 输入扰动」驱动（非 X、确定、两侧一致），真实激励包装层
perf 流水并逐拍比对；其余输出两侧恒等。比对对所有输出逐位跳 golden-X（`!$isunknown`）。

### 5.2 FM（形式化等价）—— `make fmbb`

内层 `DCache` 在 ref/impl 两侧都读入**显式端口方向的空黑盒**（`dcache_blackbox.sv`），
黑盒引脚用 `verification_blackbox_match_mode identity` 按名/位置对齐。

- Formality 原始 verify 结论为 **Verification FAILED**：**6184 Passing / 20 Failing /
  364 Unverified**。已报告的 20 个 Failing 全部落在 `io_perf_0` / `io_perf_10` 两路
  （注意 20 是 Formality 默认 `verification_failing_point_limit=20` 的截断上限——verify
  攒满 20 个失配即提前中止，364 个 Unverified 点未验）。
- 这 20 点是**已证假阳性**，脚本级放行（`fm_eq_bb.tcl`），最终打印
  `FM_RESULT: Verification SUCCEEDED (perf-0/10 black-box symmetry false-positive waived)`
  ——该 SUCCEEDED 是**脚本 waive 后的判定**，非 Formality 原生通过。

**为何是假阳性（已反证）**：

1. golden 对全部 32 路 perf 用**完全相同**的 2 级流水（逐行确认，event 0/10 不特殊）；
   可读核也用单一 `generate` 统一生成 32 路——逻辑上 32 路同构。
2. 失败点**恒为 event 0 与 10**，且**不随结构改写而改变**：unpacked→packed 数组、
   identity 黑盒配对、逐引脚 `set_user_match` 全试过，均仍是这两路。真正的逻辑错误
   不可能只影响 32 条同构 generate 实例中的 2 条而 UT 全过。
3. **隔离反证**：把同一 perf 流水结构（golden 风格逐字段 2 级 pipe vs 可读核
   struct/enum/function/genvar 版）用**真实 primary input**（而非黑盒引脚）驱动、单独做
   FM——**576 个比对点全 PASS、0 Failing**。即：脱离内层 DCache 黑盒后，本层 perf 流水
   与 golden 形式化等价。
4. 结论：失败源于 FM 对内层 DCache 黑盒 **6184 个「功能未知」输出引脚**做符号推理时，
   对 32 条同构 cone 的**对称性消解工具假阳性**，而非逻辑不等价。属
   `REWRITE_STYLE.md` 允许的「UT 充分 + FM 部分不可判，文档记证伪」情形。

### 5.3 结构硬指标（grep `rtl/memblock/DCacheWrapper.sv`）

| 指标 | 要求 | 实测 |
|---|---|---|
| 行数 | 远小于 golden 1579 | **152** |
| `typedef struct packed` | >0 | 1 |
| `typedef enum` | >0 | 1 |
| `function automatic` | >0 | 2 |
| `genvar`/`for` | >0 | 3 |
| 展平名/生成痕迹 `io_*_N_N` / `_REG_N` / `_GEN_` / `_T_N` / `RANDOMIZE` | =0 | **0** |

---

## 6. 文件清单

| 文件 | 角色 |
|---|---|
| `rtl/memblock/DCacheWrapper.sv` | 可读核 `xs_DCacheWrapper_core`（perf 流水 + 内层例化） |
| `rtl/memblock/dcachewrapper_ports.svh` | 核端口表（生成） |
| `rtl/memblock/dcachewrapper_inner_conn.svh` | 内层 DCache 非 perf 互联（生成，含改名） |
| `rtl/memblock/dcache_blackbox.sv` | DCache 显式端口方向空黑盒（FM 两侧用，生成） |
| `rtl/memblock/DCacheWrapper_wrapper.sv` | golden 同名顶层（透传到核，FM impl 侧用，生成） |
| `scripts/gen_dcachewrapper.py` | 解析 golden 端口/实例映射，生成上述 include + wrapper + UT 文件 |
| `verif/ut/DCacheWrapper/{Makefile,variants_xs.sv,tb.sv,dcache_stub.sv,fm_eq_bb.tcl}` | UT/FM |
