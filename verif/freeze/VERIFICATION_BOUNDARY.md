# 验证边界:SimTop 冻结 harness vs XSTop DUT(2026-07)

> 回应二审对 SimTop 定位的修正。明确**重写 DUT 边界 = XSTop**,SimTop 是两次仿真共用的冻结
> 验证基础设施,不属于重写 DUT,因此**不做 FM**(除非将来连 SimTop 本身也重写)。

## 结构

```
        共同且冻结的 SimTop / difftest 仿真环境
        (时钟复位 / 内存模型 / DPI / NEMU / 配置 / 工具)
                          ↓
                DUT 边界:XSTop
                 ↙              ↘
          golden XSTop        重写 XSTop
```

同一个 SimTop 下**替换** golden 与重写的 XSTop —— SimTop 是两次仿真完全相同的基础,DUT 只是 XSTop 及以下。

## 两个明确状态

| 实体 | 状态 | 要求 |
|------|------|------|
| **SimTop.sv** | **COMMON_FROZEN_HARNESS** | 不做 FM;但须**同源**、**同字节/规范化逻辑体 hash**、**两侧共用**(golden-sim 与 rewrite-sim 用同一个 SimTop) |
| **XSTop 及以下** | **DUT_SIGNOFF_BOUNDARY** | 必须完成端到端可信 Formal + benchmark parity |

## git 派生内容的正确分类(二审修订:不止 SimTop!)

**⚠ 更正**:早前"所有 volatile 只落 SimTop、DUT 无需 git shim"是**错的**。git 元数据经三条路径进入不同产物,DUT 也受影响:

| 来源 | 内容 | 落点 | 是否 DUT | B2 处理 |
|------|------|------|----------|---------|
| build.sc `gitStatus` → **CommitIDModule.scala** | SHA(rev-parse 前 40 位)+ dirty | **`NewCSR.sv:2765`**: `gitDirty=1'h1` / `gitCommitSHA=40'hC8BBD5C6AC` | **是(NewCSR 是 DUT + 305 FM 目标)** | **必须 git shim 冻结**(rev-parse→c8bbd5c6a, status→dirty) |
| build.sc gitStatus + Makefile `.__diff__` | commit + `git log`/`git diff` 注释头 | SimTop.sv 文本头 + `.__diff__` 文件 | 否(harness/元数据) | shim 冻结(复现完整 SimTop/. __diff__) |
| publishVersion(`untaggedSuffix` user@host + `LocalDateTime.now()` buildtime) | 版本串 | **外部 DTS 生成物**(经 Top.scala:63 `model`)—— **不是** SimTop RTL | DTS artifact | 若 ST/启动流程用 DTS,须一并冻结 |

**关键更正**:`git rev-parse HEAD` 的 SHA 经 CommitIDModule 变成 **NewCSR 硬件常量**,而 NewCSR 在 DUT 内、是 FM 目标。所以 **B2 的 DUT 复现也需要 git shim**(冻结 SHA+dirty),不是只有 SimTop 需要。

除 NewCSR 的 git 常量外,XSTop/XSTile/XSCore/Backend/Frontend/MemBlock 等其余 DUT 文件是纯确定 firtool 输出(0 volatile);NewCSR 靠 shim 冻结 git 输入后同样可字节复现。SimTop 仍作冻结 harness(含 git 注释头 + 经 DTS 的 buildtime,天生非确定)。

## 做功能/性能仿真需满足(全部,缺一不可)

1. **XSTop 及以下整棵重写 RTL 完成可信 FM**(305 目标里的 DUT 部分全 REPLACEMENT/ASSEMBLY 签核)。
2. 两次仿真使用**同一个** SimTop / 时钟复位 / 内存模型 / DPI / NEMU / 配置 / 工具。
3. **difftest 观察信号不能被 Formal 排除、也不能在重写版中缺失**(否则 lockstep 看不到分叉)。
4. CoreMark / Dhrystone 做 **NEMU lockstep**,比较**输出、trap、最终状态、完成周期**。

## 当前尚未满足(诚实)

- 305 项里 XSCore / XSTile / XSTop **尚无可信签核结果**(旧日志假绿已废,新入口未跑)。
- SimTop **不在** 305 项(它是 harness,符合本模型)——但其"同字节/规范化逻辑体 hash + 两侧共用"尚未建立门禁。
- **Rob 仍 UNCONFIGURED**(无 FM 机制)。
- SimTop 1.14MB / ~1.86 万行,含复位/DPI/difftest/装配逻辑——**不能**说"几乎没有逻辑";它是**被冻结**而非"无需验证":两侧共用同一 SimTop 即等价,靠"同一份"而非"证等价"。

## 对 B2 的影响

- **formal golden 复现** = DUT(1853 个非-SimTop 确定文件)逐字节一致 → 无需 git shim。
- **SimTop** = 冻结 harness:G0 已字节保存(A0);git shim + publishVersion pin 仅用于**需要**逐字节复现 SimTop 时(ST/difftest artifact 完整复现),非 formal golden 门禁必需。
- difftest ST golden(SimTop+difftest)从同一 source lock 另产,两侧共用。
