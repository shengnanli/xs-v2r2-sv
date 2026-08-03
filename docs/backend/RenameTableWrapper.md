# RenameTableWrapper —— 五张重命名表(RAT)的聚合壳

| | |
|---|---|
| 手写 SV | `rtl/backend/RenameTableWrapper_core.sv`(`xs_RenameTableWrapper`,含 5 个 RAT 实例)+ `RenameTableWrapper_wrapper.sv` |
| 生成器 | `scripts/gen_renametablewrapper.py` |
| Scala 来源 | `xiangshan/backend/rename/RenameTable.scala`(class RenameTableWrapper) |
| golden | `golden/chisel-rtl/RenameTableWrapper.sv`(8005 行,几乎全是 5 实例连线) |
| 依赖 | RenameTable / RenameTable_1 / _2 / _3(均已独立签核,见 [RenameTable](RenameTable.md) / [变体](RenameTable_variants.md));SnapshotGenerator 在各 RAT 内部 |
| 验证 | UT seed 1/7/42 各 199992 checks errors=0;FM assembly SUCCEEDED(18440 点 / 0 failing,5 实例对称 interface_only 黑盒,依赖闭包已闭合) |

## 1. 架构定位:为什么是"五张"表

重命名消除 WAR/WAW 假相关的核心数据结构是 RAT(逻辑寄存器号 → 物理寄存器号)。
香山后端把体系结构寄存器分成 **5 类独立重命名的资源**,各有自己的物理寄存器堆、
freelist 和映射表:

| 实例 | 类型 | 资源 | 表项数 | 读口 |
|------|------|------|--------|------|
| intRat | `RenameTable` | 整数 x0..x31 | 32 | 2/条 ×6 = 12 |
| fpRat | `RenameTable_1` | 浮点 f0..f31 + 2 个内部临时(I2F、stride) | 34 | 3/条 ×6 = 18 |
| vecRat | `RenameTable_2` | 向量 32 逻辑号 + 15 个内部临时(v0 实际映射在 v0Rat) | 47 | 3/条 ×6 = 18 |
| v0Rat | `RenameTable_3` | v0(RVV 掩码寄存器) | 1 | 1/条 ×6 = 6 |
| vlRat | `RenameTable_3` | vl | 1 | 1/条 ×6 = 6 |

v0 与 vl 单独成表的动机:带掩码的向量指令**隐式**读 v0、几乎所有向量指令依赖 vl
——把它们做成独立重命名资源,隐式相关也走重命名消除(否则每条掩码指令都对
"上一次写 v0 者"形成串行化真相关),且不占用 vec 表的通用读口。

RenameTableWrapper 本身是**纯连线壳(0 寄存器)**:五张表需要的
arch/spec 写控制完全同源(都来自 RAB 提交总线 `rabCommits` 和 Rename 的写口),
wrapper 把这些派生信号算一次、按寄存器类型分发五份;读口、快照口、redirect 原样透传。
上游:Rename(读口 + rename 写口)、RAB/Rob(`rabCommits`)、CtrlBlock
(redirect、snpt);下游:Rename(读数据、old_pdest、need_free)、difftest。

## 2. 结构

```mermaid
flowchart LR
  RAB["rabCommits<br/>(isCommit/isWalk, commitValid/walkValid,<br/>info: ldest/pdest/rfWen/fpWen/vecWen/v0Wen/vlWen)"] --> DRV["写控制派生(每端口 p)<br/>archWen = isCommit&commitValid_p&典型Wen<br/>specWen = isWalk&walkValid_p&典型Wen"]
  RN["Rename renamePorts<br/>(wen/addr/data ×5 类)"] --> DRV
  DRV -->|arch 写 ×6| INT["intRat"] & FP["fpRat"] & VEC["vecRat"] & V0["v0Rat"] & VL["vlRat"]
  DRV -->|spec 写 ×6(rename 优先)| INT & FP & VEC & V0 & VL
  RD["Rename 读口<br/>12+18+18+6+6"] --> INT & FP & VEC & V0 & VL
  SNPT["snpt(Enq/Deq/useSnpt/<br/>snptSelect/flushVec)"] --> INT & FP & VEC & V0 & VL
  INT -->|old_pdest + need_free| OUT["Rename / freelist 回收"]
  FP & VEC & V0 & VL -->|old_pdest| OUT
```

## 3. 关键机制

### 3.1 spec 写口的时分复用(walk 恢复 vs rename 写)

每张表的 6 个投机写口有两个使用者,按流水线状态分时:

- **正常拍**:Rename 的映射写(`renamePorts_p.wen`,新分配的 ldest→pdest);
- **walk 拍**:redirect 后,RAB 沿 ROB **重放**尚未提交、且比 redirect 老的映射
  (`isWalk && walkValid_p && 类型Wen`),把整表恢复推进到 redirect 点。

派生逻辑(Chisel last-connect,rename 优先):

```
wen  = renamePorts_p.wen | (isWalk & walkValid_p & info_p.<类型>Wen)
addr = renamePorts_p.wen ? renamePorts_p.addr : info_p.ldest
data = renamePorts_p.wen ? renamePorts_p.data : info_p.pdest
```

复用之所以安全:walk 期间前端被冲刷、Rename 不产生新写,两个使用者天然错峰。

### 3.2 arch 写:只有 RAB 提交才落盘

`archWen = isCommit & commitValid_p & 类型Wen`,地址/数据取 `info_p.ldest/pdest`。
arch_table 是"确定不会回退"的映射,是 redirect 恢复的兜底基准(见 RenameTable.md §3)。
整数口带断言:向 x0 提交的 pdest 必须为 0。

### 3.3 快照端口为什么存在

redirect 时 spec_table 的恢复有两条路:

1. **arch_table + walk**:恢复到提交点,再由 RAB 重放走到 redirect 点——
   walk 拍数正比于"redirect 点与提交点的距离",深回滚很慢;
2. **snapshot**:CtrlBlock 周期性(snptEnq)让各 RAT 对**整张 spec_table** 打
   检查点(RAT 内部的 SnapshotGenerator,4 份);redirect 若落在某快照之后,
   选离它最近的快照恢复(`useSnpt/snptSelect`),只需 walk 快照点→redirect 点
   这一小段,大幅缩短误预测恢复延迟。

wrapper 只负责把同一份 `snpt` 广播给五张表——五张表必须**同步**打/删/用快照,
否则恢复后五类映射不一致。快照本体与两拍对齐细节在 RenameTable.md §5。

### 3.4 old_pdest 与 need_free:为什么只有 int 有 need_free

每个提交口输出 `old_pdest`(被本次提交覆盖前的旧物理号),供 freelist 回收:

- **fp/vec/v0/vl** 用 `StdFreeList`:一个逻辑号同时只映射一个物理号,
  old_pdest 提交即可直接回收——不需要额外判断;
- **int** 用 `MEFreeList`(move elimination):`mv rd,rs` 不占新物理寄存器,
  而是让 rd、rs **共享**同一物理号(引用计数)。于是覆盖一个映射并不代表旧物理号
  没人用了——`need_free` 由 intRat 计算:"old_pdest 在 arch_table 中已无任何项引用,
  且不与同拍前序口的 old_pdest 重复",为真才允许回收。

这就是接口不对称(`int_need_free` 存在、其它类没有)的微架构原因。

## 4. 与 golden / Chisel 的对应

- Chisel `RenameTableWrapper` ≈ 5 个 `Module(new RenameTable(Reg_X))` + 三段
  for 循环连线;golden 8005 行几乎全为实例端口展开。可读核保留 golden 的派生
  wire 公式(§3.1),去掉 SYNTHESIS 断言与死 wire。
- 与 [RenameTable.md](RenameTable.md) 的分工:表内的两拍读写时序、旁路、
  redirect 两拍恢复、快照对拍、need_free 算法都在**表内**,本模块只做派生+分发;
  变体参数差异见 [RenameTable_variants.md](RenameTable_variants.md)。

## 5. 验证状态

UT seed 1/7/42 各 199992 checks errors=0(比对全部 193 输出端口)。
FM assembly SUCCEEDED:18440 点(16938 黑盒 pin + 1502 端口)/ 0 failing /
0 unread,5 个 RAT 实例对称 interface_only 黑盒;依赖闭包已闭合
(RenameTable 及 _1/_2/_3 变体均已各自 SIGNOFF/PASS)。
