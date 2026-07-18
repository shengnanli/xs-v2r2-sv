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

## 为什么 SimTop 可作冻结 harness(实证)

G0 逐文件核查:**所有 volatile/非确定内容全部只落在 SimTop.sv 一个文件**:
- git 头(commit c8bbd5c6a + status + submodule + `git diff` 注释,来自 build.sc gitStatus + Makefile `.__diff__`);
- 唯一的时间戳 `Sun Jun 15 2025`(= **commit date**,确定,非 buildtime);
- publishVersion(`untaggedSuffix` 含 user@host + `LocalDateTime.now()` buildtime,经 Top.scala 进设备树 model)。

**XSTop / XSTile / XSCore / Backend / Frontend / MemBlock 及全部非-SimTop 的 1853 个 .sv:volatile 痕迹 = 0**
(逐一 grep 确认)。即 **DUT 是纯确定的 firtool-1.62.1 输出**,可复现、可 FM。

> ⚠ publishVersion 的 buildtime/user@host **确实**是非确定输入(build.sc:320),但它只经设备树进入
> **SimTop 层**,不落入 DUT 任何 .sv → 不影响 DUT 的可复现性与 FM。这是 SimTop 必须作**冻结** harness
> (而非每次重生)的根本原因:它天生含非确定内容。

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
