# PMPChecker —— 物理地址权限与属性检查器

> 可读重写：`rtl/memblock/PMPChecker.sv`（核 `xs_PMPChecker_core`，参数 `REGISTERED`）+ `rtl/memblock/pmp_pkg.sv`
> golden：`golden/chisel-rtl/PMPChecker.sv`（组合）、`PMPChecker_10.sv`（寄存）；Scala：`PMP.scala`（`PMPCheckMethod` + `PMACheckMethod`）

## 1. 角色

地址翻译链的「权限关卡」。ITLB/DTLB/PTW 完成虚实转换后，把**物理地址 + 访问命令 + 当前特权 mode + 一份 PMP/PMA 条目快照**送进本模块，得到：

| 输出 | 含义 |
|------|------|
| `resp.ld` | 读访问越权（load access fault） |
| `resp.st` | 写/原子访问越权（store access fault） |
| `resp.instr` | 取指越权（instruction access fault） |
| `resp.mmio` | 目标是不可缓存的 MMIO 区 |
| `resp.atomic` | 目标区域支持原子操作 |

条目快照来自 [PMP](PMP.md) 模块。

## 2. 算法（每周期对一个物理地址）

```mermaid
flowchart TD
  A[paddr + cmd + mode + pmp16/pma16] --> M1[逐条目匹配<br/>NAPOT 掩码 / TOR 区间]
  M1 --> P[优先级选择<br/>低序号优先]
  P --> R[按 cmd 算 resp]
  R --> O[PMP|PMA 合并<br/>ld/st/instr + mmio/atomic]
```

1. **逐条目匹配**（`xs_is_match`）：
   - NAPOT（`a[1]=1`）：`(paddr & ~mask) == (compare_addr & ~mask)`，掩码外位相等。
   - TOR（`a=01`）：`prev_cmp <= paddr < cur_cmp`，与「前一条目地址」构成区间；条目 0 的前一条目取全 0。
   - OFF：不匹配。
   - `compare_addr = (addr << 2) & ~0xFFF`（清掉粒度内低 12 位）。
2. **优先级选择**（`prio_sel`，对应 Chisel `ParallelPriorityMux`）：序号最低的命中条目胜出（RISC-V PMP 优先级）。都不命中用「默认条目」：
   - PMP 默认随 mode 放行（`mode[1]`，即 M 模式 passThrough）；
   - PMA 默认全 0。
3. **按命令算 resp**（`pmp_check`/`pma_check`）+ **PMP|PMA 合并**：任一拒绝即拒绝。

### PMP 的「ignore」放行
对每条目，`r/w/x` 叠加 `ignore = M 模式 && !locked`——M 模式对未锁定条目默认放行，体现 RISC-V「M 模式默认全权、PMP 锁定后才约束 M」。

### TlbCmd 编码
`read=000 write=001 exec=010 atom_read=100 atom_write(sc/amo)=101`；
`isRead=cmd[1:0]==00`，`isWrite==01`，`isExec==10`，`isAmo=cmd==101`。

### PMA 的属性判定
- `ld = 读 & !r`；`st = 原子?( !atomic||!w ):( 写?!w:0 )`；`instr = 取指 & !x`；
- `mmio = !c & !(ld|st|instr)`（越权优先报 fault，而非 mmio）；`atomic = 选中条目的 atomic`。

## 3. 简化前提

本配置 `lgMaxSize = 3 <= PlatformGrain = 12`，因此：
- **对齐恒为真**（`aligned`），匹配/对齐均与访问 size 无关 → 无 size 端口；
- `torMatch`/`napotMatch` 退化为简单地址比较/掩码，golden RTL 里也看不到 size 相关逻辑。

## 4. 两个变体（`REGISTERED` 参数）

| 变体 | golden | REGISTERED | 时序 |
|------|--------|-----------|------|
| 组合 | `PMPChecker` | 0 | 纯组合，`sameCycle`，输出当拍给出 |
| 寄存 | `PMPChecker_10` | 1 | `leaveHitMux`：把「每条目匹配位 + 调整后 cfg + cmd/mode」在 `io_req_valid` 时打一拍，优先级选择与 resp 仍组合，输出延后一拍 |

寄存变体的实现细节（与 golden 对齐）：
- 匹配位 `res_pmp_r`/`res_pma_r` 用**异步复位清零**（对应 `RegEnable(_, false.B, valid)`）；
- 其余打拍寄存器（cfg 权限/属性、cmd、mode）**无复位**，仅 `io_req_valid` 时更新。

## 5. 接口

| 端口 | 方向 | 含义 |
|------|------|------|
| `clock`/`reset` | in | 仅 REGISTERED=1 用 |
| `io_req_valid` | in | REGISTERED=1 时作打拍使能 |
| `io_req_bits_addr[47:0]` | in | 待检查物理地址 |
| `io_req_bits_cmd[2:0]` | in | TlbCmd |
| `io_check_env_mode[1:0]` | in | 当前特权模式 |
| `io_check_env_pmp[16]` (`pmp_entry_t`) | in | PMP 条目快照 |
| `io_check_env_pma[16]` (`pmp_entry_t`) | in | PMA 条目快照 |
| `io_resp_ld/st/instr/mmio/atomic` | out | 检查结果 |

> golden 把条目快照展平成 `io_check_env_pmp_<i>_cfg_*`/`addr`/`mask`；wrapper 做扁平↔结构适配。

## 6. 验证

- **UT**（`verif/ut/PMPChecker/`）：随机条目 + 随机地址/命令/mode，golden vs 可读核逐拍比对全部输出。
  - 组合变体（`make compile && make run`）多种子 1/7/42：各 `checks=200000 errors=0` → **TEST PASSED**。
  - 寄存变体（`make compile10 && make run10`，tb 为 `tb_10.sv`）多种子 1/7/42：各 `checks=200000 errors=0` → **TEST PASSED**。
- **FM**（`make fm`，两个变体）：
  - `FM_RESULT: Verification SUCCEEDED for PMPChecker`
  - `FM_RESULT: Verification SUCCEEDED for PMPChecker_10`

## 7. 踩坑记录

1. **`logic x = expr;` 模块级声明初值被 Formality 忽略（FMR_VLOG-038）**：会让这些网络在 FM 里悬空 → X 传播 → 全部输出判不等价（但仿真里 VCS 当连续赋值，UT 反而过）。修复：模块级组合赋值一律用 `wire x = expr;`（连续赋值，FM 支持）。
2. **寄存变体的复位范围**：golden 只对匹配位 `res_*` 异步复位，cmd/cfg 寄存器无复位；可读核须同构，否则 FM 在复位状态判不等价。
3. **寄存变体 wrapper 必须暴露 `reset` 端口**并连到核（golden `PMPChecker_10` 有 reset）；否则 FM 出现 `reset` 全局未匹配 + 元素 0 寄存器未配对的连锁失败。
