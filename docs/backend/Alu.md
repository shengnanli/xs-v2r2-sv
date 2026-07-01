# 香山 V2R2(昆明湖)整数 ALU —— 学习文档

> 可读重写:`rtl/backend/Alu.sv`(核 `xs_Alu_core`)+ `rtl/backend/alu_pkg.sv`。
> 设计源:`src/main/scala/xiangshan/backend/fu/Alu.scala`(`AluDataModule`)
> 与 `src/main/scala/xiangshan/package.scala`(`object ALUOpType`)。

## 1. ALU 在后端的位置与角色

后端乱序流水把就绪的整数微操作(uop)发射到执行单元簇 ExuBlock。ALU 是其中
**最常用、最简单**的执行单元:

```mermaid
flowchart LR
  IQ[IssueQueue 发射队列] --> DP[DataPath 读寄存器/旁路]
  DP -->|src1,src2,fuOpType| ALU[ALU 单周期组合]
  ALU -->|res.data| WB[WbDataPath 写回]
  WB --> ROB[ROB 提交]
```

ALU 是 **单周期纯组合** 的叶子功能单元:
- 输入:两个 64bit 操作数 `src1/src2`、7 位运算码 `fuOpType`。
- 输出:64bit 结果 `res.data`。
- 流水寄存/握手,以及 valid / robIdx / pdest / rfWen / perfDebugInfo 等控制位的**原样直通**,
  都由外层 `PipedFuncUnit`(golden 顶层 `Alu`)负责——**不在本核**。可读核 `xs_Alu_core`
  端口只有 `src1 / src2 / func → result`(见 `Alu.sv:22-29`),是纯组合运算,不接触任何控制位。

覆盖的指令:RV64I 的加减/比较/移位/逻辑,RV64 的 *W 字指令,以及 B 扩展
(Zba 移位加、Zbb 基本位操作、Zbs 单 bit 操作)与 Zicond 条件置零。

## 2. 核心思想:把"选哪条通道"编进运算码

ALU 的精髓在于 `fuOpType` 的 **7 位编码不是随意分配**,而是把"结果走哪条通道"
直接编进高 3 位 `func[6:4]`,把"通道内选哪种运算/变体"编进低 4 位 `func[3:0]`。
于是不需要任何译码查找表:所有运算 **并行算出**,顶层只用 `func[6:4]` 做一次
6 选 1 即可。各通道内部再用低位做小范围 mux。这样选择树天然分层,利于时序。

```mermaid
flowchart TD
  subgraph 并行计算所有通道
    SH[shift 通道<br/>sll/srl/sra/rol/ror<br/>bclr/bset/binv/bext]
    WD[word 通道<br/>addw/subw/sllw.../rolw<br/>结果 SEXT 到 64]
    AD[add 通道<br/>add/adduw/oddadd<br/>lui32add/srNadd/shNadd]
    CMP[compare 通道<br/>sub/sltu/slt/max/min]
    MS[misc 通道<br/>and/or/xor/orcb<br/>sextb/packh/rev8/...]
    CZ[cond 通道<br/>czero.eqz/czero.nez]
  end
  SH --> SEL{func[6:4]<br/>6 选 1}
  WD --> SEL
  AD --> SEL
  CMP --> SEL
  MS --> SEL
  CZ --> SEL
  SEL --> R[result 64bit]
```

`func[6:4]` 到通道的映射(见 `alu_pkg::alu_chan_e` 与 Scala `AluResSel`):

| func[6:4] | 通道       | 说明 |
|-----------|-----------|------|
| 000       | shift     | 移位 / 单 bit 操作 |
| 001       | word      | RV64 *W 字指令(低 32 位运算,结果符号扩展) |
| 010       | add       | 加法及其多种预处理变体 |
| 011       | compare   | 比较 / max / min |
| 100/101/110 | misc    | 逻辑运算 + Zbb 字节/半字操作 |
| 111       | cond      | Zicond 条件置零 |

> 注意 `func[6:5]==00` 时由 `func[4]` 在 shift(000x)/word(001x)间区分,
> `func[6:5]==01` 时由 `func[4]` 在 add(010x)/compare(011x)间区分;
> `func[6]==1` 时,仅 `func[5]&func[4]`(即 111)走 cond,其余走 misc。

## 3. 六条通道的实现要点

代码用 6 个 `function automatic` + 若干公共子函数表达,逐条对应 Scala 的
`ShiftResultSelect` / `WordResultSelect` / `AddModule` / `MiscResultSelect` /
`ConditionalZeroModule` / `AluResSel`。

### 3.1 移位通道 shift(`shift_channel`)
- 基本移位 `sll/srl/sra`,循环移位 `rol/ror`,Zbs 单 bit `bclr/bset/binv/bext`。
- **循环移位技巧**:`rol = (src1>>revShamt) | (sllSrc<<shamt)`,其中
  `revShamt = ~shamt + 1`,在 6 位下恰等于 `64-shamt`,省一个减法器。
- 左移源带 `func[0]` 掩码:`func[0]=1`(slliuw)时先 ZEXT(src1[31:0])。

### 3.2 字通道 word(`word_channel`)
- 在低 32 位上算 add/sub/shift/rotate,最后 `SEXT` 到 64 位。
- addw 的第二加数复用 64bit 加法的 `add_operand1`(处理了 lui32addw 的
  `{src2[63:12],12'b0}`),保证与 golden 共用同一加法器语义。
- addwbit/byte/zexth/sexth 只是取加法结果的不同位段。

### 3.3 加法通道 add(`add_operand0/1`)
一个 64bit 加法器服务多种变体,差别只在两个加数的预处理(四级优先):
1. `func[3]=1` → shadd:`(masked_src1) << (1..4)`(Zba 的 sh1add..sh4add)。
2. `func[2]=1` → srNadd:取 `src1[63:N]` 并 ZEXT。
3. `func[1]=1` → lui32add(SEXT(src2[11:0]))/ oddadd(src1[0])。
4. 否则 → 普通 add / adduw(带 func[0] 掩码)。
- lui32add(`func[3:0]==0011`)时第二加数为 `{src2[63:12],12'b0}`。
- **实现坑**:shadd 移位量 = `func[2:1]+1`,相加要用 ≥3 位避免 2 位回绕。

### 3.4 比较通道 compare(`sub_ext`)
- 用一个 65 位带借位减法器 `sub = src1 + ~src2 + 1`。
- `sub[64]` 是进位:无进位 ⇒ 有借位 ⇒ `src1 < src2`(无符号),即 `sltu`。
- 有符号 `slt = src1[63] ^ src2[63] ^ sltu`。max/min 据此选 src1/src2。

### 3.5 杂项通道 misc(`misc_channel`)
- 逻辑 `and/or/xor`,取反变体 `andn/orn/xnor`(`func[0]=1 且 func[5]=0` 时取反 src2),
  `orcb`(逐字节 OR-combine)。
- Zbb 扩展:`sextb/packh/sexth/packw/revb/rev8/pack/orh48`,以及
  `func[5]=1` 的 LSB / ZEXTH 变体(对逻辑结果加掩码)。
- 字节/位级并行用 `for` 表达(`orc_b`/`rev_b`/`rev_8`)。

### 3.6 Zicond 通道 cond(`cond_res`)
- `czero.eqz`:`src2==0 ? 0 : src1`;`czero.nez`:`src2!=0 ? 0 : src1`。
- `func[1]` 选 eqz(0)/nez(1)。

## 4. 接口

可读核 `xs_Alu_core`(组合):

| 端口   | 方向 | 位宽 | 含义 |
|--------|------|------|------|
| src1   | in   | 64   | 操作数 1(rs1) |
| src2   | in   | 64   | 操作数 2(rs2) |
| func   | in   | 7    | fuOpType 低 7 位(运算码) |
| result | out  | 64   | 运算结果 |

golden 同名 wrapper `Alu`(`Alu_wrapper.sv`)额外把 valid/robIdx/pdest/rfWen/
perfDebugInfo 直通,端口与 `golden/chisel-rtl/Alu.sv` 完全一致,供 FM 与系统替换。

## 5. 验证结果

- **UT(双例化逐拍比对)**:tb 同时例化 golden `Alu`(含 `AluDataModule` +
  11 个运算叶子)与可读核 `Alu_xs`,每拍随机驱动 src0/src1/fuOpType(90% 取
  全部合法 opType 做定向覆盖 + 10% 随机 func),比对全部输出。
  - seed 1 / 7 / 42:各 `checks=1,800,000`(其中 res_data 比对 200,000 次),
    `errors=0`,`TEST PASSED`。
- **Formality 等价**:golden 顶层 `Alu`(+全部叶子) vs 可读核 wrapper。
  `Verification SUCCEEDED`,275 个比对点全部按名匹配,0 unmatched,0 failing。

### 复跑

```bash
cd verif/ut/Alu
make run SEED=1   # 同理 SEED=7 / SEED=42
make fm
```

## 6. 重写关键坑(供后续 FU 复用)

1. **函数读模块网的双重陷阱**:`function` 在 `assign` 中调用时只对显式实参敏感,
   不会因其读到的模块信号变化而重算 → 漏更新;且 Formality 把
   "function 内用 non-local variable"(FMR_VLOG-091)当作 RTL 解释错误而拒读
   impl 设计。**解法**:所有共享量(shamt/revShamt/移位源/掩码)一律经实参传入,
   既保证组合敏感正确,又通过 FM。
2. **窄位宽算术回绕**:shadd 的移位量 `func[2:1]+1` 若用 2 位相加,`3+1` 回绕为 0
   → 不移位。须显式扩位(`{1'b0,sh}+3'd1`)。
3. **共用加法器的第二加数**:word 通道 addw 必须复用 64bit 加法的第二加数
   (含 lui32addw 的 `{src2[63:12],12'b0}`),不能直接用 `src2[31:0]`。
4. ALU 是纯组合无状态机/无流水寄存器,故无 `typedef struct packed`(本工程
   结构闸门中 struct 为"若有"项);enum / function / genvar(for)均 >0。
