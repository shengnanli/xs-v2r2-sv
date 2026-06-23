# 发射队列 FaluFcvtF2vFmacFdiv 变体(EntriesFaluFcvtF2vFmacFdiv)可读重写

设计源:`src/main/scala/xiangshan/backend/issue/{Entries,EntryBundles,EnqEntry,OthersEntry,IssueQueue}.scala`
golden 对照:`golden/chisel-rtl/EntriesFaluFcvtF2vFmacFdiv.sv`(叶子 `EnqEntry_8` /
`OthersEntry_88`(simp) / `OthersEntry_90`(comp) / `EnqPolicy_8` /
`UIntCompressor_27_000000000000001010100000000`)

## 1. 这是什么

发射队列(IssueQueue)是乱序后端的「调度心脏」:在条目阵列里缓存等待发射的 uop,
监听写回(WB)/发射(IQ)两类唤醒总线把就绪的源置位;当一条 uop 全部源就绪且未发射
时「可发射」,再由年龄检测器(AgeDetector)选出最老者发射。

本变体 **FaluFcvtF2vFmacFdiv = 浮点 IQ「全家桶」**,功能单元含:
FALU(浮点加减/比较)、FMAC(浮点乘加)、FDIV/FSQRT(浮点除/开方)、
**FCVT(浮点格式转换)、F2V(浮点→向量:把浮点结果写进向量/v0 寄存器)**。
它是 **FaluFmacFdiv** 变体的「近邻」:在其全栈基础上**多了 Fcvt 与 F2v 两类 FU**。

## 2. 与 FaluFmacFdiv 样板的差异(本次只改两处,全是「数据携带」型)

样板 = FaluFmacFdiv(`rtl/backend/EntriesFaluFmacFdiv.sv` + `IqEntryFfmacFdiv.sv` +
`iq_ffmacfdiv_pkg.sv`)。本变体的维度、唤醒匹配、numDeq=2 双端口、deqPortIdx、
og1Resp_1_bits_resp 动态 resp、exuSources 压缩、转移策略(EnqPolicy / finalSimp /
CompTransSel / simp→comp 提级)**全部与 FaluFmacFdiv 逐字相同**(直接 fork)。

实测端口 diff(golden EntriesFaluFcvtF2vFmacFdiv vs EntriesFaluFmacFdiv):本变体是
样板的**严格超集**,每个 enq/deqEntry 各多出 4 个端口,真正重写只在以下两处:

| 维度 | FaluFmacFdiv(样板) | FaluFcvtF2vFmacFdiv(本变体) |
|---|---|---|
| numEntries / Enq / Simp / Comp | 18 / 2 / 2 / 14 | 18 / 2 / 2 / 14(同) |
| numDeq | 2 | 2(同) |
| numRegSrc / WakeupFromIQ / WB | 3 / 3 / 6 | 3 / 3 / 6(同) |
| 唤醒匹配 | fpWen + srcType[1] | fpWen + srcType[1](同) |
| **FuType 保留位** | {11,12,14} | **{4,11,12,13,14}**(加 F2v=4 / Fcvt=13) |
| **payload 写使能** | rfWen,fpWen | **+ vecWen + v0Wen**(F2v 写向量/v0) |

### 2.1 FuType 多保留 F2v / Fcvt 两位

`src/main/scala/xiangshan/backend/fu/FuType.scala` 的 `addType` 自增顺序给出位号:
`f2v=4 … falu=11, fmac=12, fcvt=13, fDivSqrt=14`。本变体的 `IQFuType.readFuType`
保留 **{4,11,12,13,14}** 五位透传,其余位清零(FuType 总位宽仍 35)。

样板核里 fuType 在三处显式逐位选:`entry_update.status.fu_type`(条目次态)、
`o_fu_type`(输出)。本变体在 `{FU_FALU,FU_FMAC,FU_FDIV}` 基础上各补
`FU_F2V`(4)与 `FU_FCVT`(13)两行赋值。golden 把这 5 个 fuType 位**各自独立寄存/
透传**(EnqEntry_8.sv:`entryReg_status_fuType_{4,11,12,13,14}`),与本核逐位对应。

### 2.2 payload 多 vec_wen / v0_wen 两位

F2v 会把浮点结果写进向量寄存器堆与 v0 掩码寄存器,所以 payload 多两位写使能。
它们在条目里**纯透传**:随 `enq` 寄存、随 `transEntry` 转移、由 `deqEntry` 输出,
**不参与唤醒匹配 / canIssue / oldest 选择**(唤醒仍只看 `fpWen + srcType[1]=isFp`)。
golden EnqEntry_8.sv 对它们也只是 `entryReg_payload_{vecWen,v0Wen} <= io_..._enq_bits_...`
的寄存-转发,无任何控制逻辑分支。

因为 payload 是 `packed struct`,在 `entry_t` 里整体寄存/透传,核里只需在 `payload_t`
结构体里加这两个字段,**无需任何额外逻辑**——entry_update 的 `payload = entry_reg.payload`
与 enq 的整体覆写自然把它们带上。阵列层(Entries)更是「FU 类型无关」,逐字 fork 即可。

## 3. 实现结构

| 文件 | 角色 |
|---|---|
| `rtl/backend/iq_ffcfmacfdiv_pkg.sv` | 维度参数 + struct/enum(payload 加 vec_wen/v0_wen;FU_F2V/FU_FCVT) |
| `rtl/backend/IqEntryFaluFcvtF2vFmacFdiv.sv` | 单条目核(EnqEntry/OthersEntry simp/comp 三态由参数选);fuType 5 位 |
| `rtl/backend/EntriesFaluFcvtF2vFmacFdiv.sv` | 条目阵列(18 条)+ 转移策略 + 双端口 issueResp/oldest-mux |
| `rtl/backend/EntriesFaluFcvtF2vFmacFdiv_wrapper.sv` | golden 同名扁平 wrapper(gen 脚本产,纯 glue,无逻辑) |
| `scripts/gen_iq_ffcfmacfdiv.py` | 端口解析 → wrapper + 双例化 tb + _xs 变体 |

单条目核三态(对应 golden 三个 leaf):
- **IS_ENQ=1**:入队条目(EnqEntry_8),带 1 拍 enqDelay 唤醒。
- **IS_ENQ=0,IS_COMP=0**:简单条目(OthersEntry_88),无 canIssueBypass。
- **IS_ENQ=0,IS_COMP=1**:复杂条目(OthersEntry_90),有 canIssueBypass + 即时前递输出。

EnqPolicy_8 / UIntCompressor 作 golden 黑盒例化(拓扑与配置绑定,与样板同款)。

## 4. 验证

### UT(双例化逐拍比对全部 172 个输出端口)

`verif/ut/IssueQueueFaluFcvtF2vFmacFdiv/`:`u_g`=golden `EntriesFaluFcvtF2vFmacFdiv`,
`u_i`=可读核 wrapper(重命名 `_xs`)。两侧共享 golden 黑盒 + golden 单条目。
入队 srcType 偏置 isFp 以保证唤醒命中覆盖;`+vcs+initreg+0` 消 golden 上电 X 假象。

| seed | checks | errors |
|---|---|---|
| 1  | 200000 | **0** |
| 7  | 200000 | **0** |
| 42 | 200000 | **0** |

(以上为最终二进制 `./simv` 复跑实测,非编译期推断。)

### FM(Formality 形式等价)

`make fm`:golden `EntriesFaluFcvtF2vFmacFdiv` vs 可读核 wrapper(黑盒+golden leaf 两侧共享)。

```
FM_RESULT: Verification SUCCEEDED for EntriesFaluFcvtF2vFmacFdiv
3036 Passing compare points (1179 Port + 1857 DFF), 0 Failing, 0 Unmatched
```

1857 个 DFF 比较点全部 equivalent——含新增 `payload_{vec_wen,v0_wen}` 与
`fuType_{4,13}` 寄存器,逐位等价,非黑盒糊弄。

## 5. 硬性闸门(实测)

- 核 `iq_ffcfmacfdiv_pkg`:8 struct + 3 enum;`IqEntryFaluFcvtF2vFmacFdiv`:3 function
  + 1 genvar;`EntriesFaluFcvtF2vFmacFdiv`:1 genvar。
- 代码区(去注释)`grep -E "io_[a-z_]+_[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE"`
  三个核文件 **全 0**;wrapper(glue,只含 golden 层次化端口名,无 firtool `io_x_N_N`
  相邻索引中间线签名)亦 0。无套壳。
- 坑规避(继承自样板):`!ety_valid[i]` 用逻辑非(避免 `~` 在 32 位加法上下文下溢);
  oldest/Mux1H 用 `sel ? entry : 0` 累加(sel=0 不引 X);issueResp/deqPortIdx 全 always_comb。
