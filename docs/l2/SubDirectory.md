# SubDirectory / SubDirectory_1 —— openLLC 目录子块可读重写

> 源: `openLLC/src/main/scala/openLLC/Directory.scala` 的 `class SubDirectory[T]`
> golden: `golden/chisel-rtl/SubDirectory.sv`(516 行)、`SubDirectory_1.sv`(824 行)
> 重写: `rtl/uncore/SubDirectory.sv`(核) + `SubDirectory_wrapper.sv`(装配壳)
>       `rtl/uncore/SubDirectory_1.sv`(核) + `SubDirectory_1_wrapper.sv`(装配壳)
> 生成: `scripts/gen_subdirectory.py` / `scripts/gen_subdirectory1.py`

## 1. 这两个模块是什么

openLLC 顶层 `Directory` 例化两个 `SubDirectory`:

| 实例 | golden | 路数 | set | tag | meta | 替换 |
|------|--------|------|-----|-----|------|------|
| `clientDir`(snoop filter) | `SubDirectory`   | 10 | 1024 | 30 | `Vec(numRNs=1) of ClientMetaEntry{valid}` | random(LFSR) |
| `selfDir`                 | `SubDirectory_1` | 16 | 4096 | 28 | `SelfMetaEntry{valid,dirty}`              | plru(replacer SRAM) |

两者共享同一套三级流水骨架, 差别只在 meta 字段、路数/位宽、替换策略。

## 2. 三级流水(对照 Scala 注释 stage1/2/3)

```
stage1: io.read.fire        → 向 tagArray/metaArray(/replacer)SRAM 发读
stage2: SRAM 数据回来         → 用 reqValid_s2 门控锁存 tagAll_s3 / metaAll_s3
                              (selfDir 还锁存 repl_state_s3)
stage3: 算 hit/way, 选 meta/tag → io.resp.valid = reqValid_s3
```

- `io.read.ready = ~metaWen & ~tagWen & (~replacerWen) & resetFinish`
  - clientDir(random): 无 replacerWen
  - selfDir(plru): 含 replacerWen 反压(写 replacer SRAM 那拍不接读)
- 复位扫写: `resetIdx` 从 `sets-1` 递减到 0, 期间向 metaArray 全路写 init(valid=0);
  到 0 后 `resetFinish` 拉高才开始服务。

## 3. 选路逻辑(stage3, 全组合)

```
hitVec[w]  = (tagAll_s3[w] == req_s3_tag) & metaAll_s3[w].valid
hit_s3     = |hitVec
hitWay     = OHToUInt(hitVec)               // 按下标各 bit 的 OR 重写, 非优先编码
invalidWay = 最小下标的空路(ParallelPriorityMux over ~valid)
replaceWay = clientDir: LFSR 低 7 位经非均匀阈值梯映射到 [0,9]
             selfDir:   PLRU 二叉树(15 节点)从根节点逐级下降到 LRU 叶子
chosenWay  = hasInvalid ? invalidWay : replaceWay
way_s3     = hit_s3 ? hitWay : chosenWay
```

`io_resp_bits_{tag,meta_*}` 按 `way_s3` 从 16/10 路里选(golden 的 `_GEN_*[way_s3]`
打包 mux, 对 10 路时下标 10~15 回落到 0, 重写用 case + default 等价)。

### selfDir PLRU 回写
命中且 opcode∈{ReadUnique=0x07, ReadNotSharedDirty=0x26} 或 refill 时 `replacerWen=1`,
把 `way_s3` 路径上各树节点翻向"非该路"(MRU), 写回 replacer SRAM(`get_next_state`)。
该 15 位更新表达式逐位忠实复刻 golden。

## 4. 装配方法学(同 Directory)

SRAM/LFSR 全部黑盒, 由 wrapper 例化, 核只出 `o_*` 控制 / 收 `i_*` 读数据:

| 模块 | 黑盒子块 |
|------|----------|
| SubDirectory   | `SRAMTemplate_197`(tag)、`SRAMTemplate_198`(meta)、`MaxPeriodFibonacciLFSR_3`(随机替换, 自由运行取低 7 位) |
| SubDirectory_1 | `SRAMTemplate_199`(tag)、`SRAMTemplate_200`(meta)、`SRAMTemplate_201`(replacer, 15bit, shouldReset) |

gen 脚本从 golden 原样 lift 这些实例, 仅把"已被核接管的驱动信号名"(读使能/写控制)
定点替换成核的 `o_*` 输出; 纯依赖外部端口的连接(如 tag 写 waymask `16'h1<<way`)留在
wrapper 内联。寄存器命名与 golden 完全一致(`resetFinish/resetIdx/reqValid_s2/req_s2_*/
reqValid_s3/req_s3_*/metaAll_s3_*/tagAll_s3_*/repl_state_s3`)以利 Formality 按名配对。

### 踩过的两个坑(SubDirectory_1)
1. **贪婪正则误伤 tagArray**: replacer 写数据是多行 PLRU 表达式, 折叠成 `o_replWdata`
   的 `re.S` 贪婪匹配若不限定模块, 会把 tagArray 的 `io_w_req_bits_data_0` 一路吃到
   waymask, 抹掉 data_1..15。→ 仅对 `SRAMTemplate_201` 块施加该折叠。
2. **漏掉 metaArray waymask 替换**: 漏写一条 SUBS 导致 wrapper 里 `resetFinish ?
   wayOH : 16'hFFFF` 的 `resetFinish` 变成悬空隐式网。UT 侥幸过、**FM 精确报出 16 个
   `metaArray/io_w_req_bits_waymask` 失配**点。补上替换后 FM 即过。
   → 教训: gen 完务必 grep wrapper 是否残留核内部信号名(resetFinish/resetIdx/way_s3…)。

## 5. 验证结果

| 模块 | UT(seed 1/7/42) | FM |
|------|------------------|----|
| SubDirectory   | 各 1,600,000 checks, errors=0, ierr=0(内部探针全配) | SUCCEEDED |
| SubDirectory_1 | 各 1,800,000 checks, errors=0, ierr=0(内部探针全配) | SUCCEEDED |

- 核代码区 `grep -E "io_[a-z_]+_[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE"` = 0
- 无 `.svh` 套壳; struct/enum/genvar/localparam 充分。
- UT: `+define+SYNTHESIS +vcs+initreg+random` 编译, `+vcs+initreg+0` 跑, 逐拍 `!$isunknown` 比对。
- FM: SRAM/LFSR 两侧黑盒, 寄存器按名(含 `u_core/` 层次剥离)自动配对。

## 6. L2/openLLC 目录通道摸到的要点
- openLLC 是 CHI 侧的"包含式 self 目录 + 非包含 snoop filter(client 目录)"双子目录结构;
  `Directory` 把读/写分别 fan 到两个 `SubDirectory`, 要求两者 resp.valid 同步(全 0 或全 1)。
- SRAM 均单口、同步读(fire 后 1 拍出数据), 目录用 reqValid_s2 门控把读出锁进 s3。
- DRRIP 在 coupledL2 `Directory`(已重写), 这里 self 用经典 PLRU、client 用 random。

## 7. 下一轮入口
- 同族剩余: openLLC `MSHRCtl`/`MainPipe_5`(openLLC 主流水)、coupledL2 `RequestArb_4`(922 行)。
- L2 通道侧: `GrantBuffer`(1599)、`RequestArb`(3344, L2 主仲裁)、`RefillUnit`。
- 边界最清晰、可复用本套 lift 方法学的是 `RequestArb_4` 与 `RefillUnit`。
