# Slice_1 / Slice_2 / Slice_3 —— TL2 direct-child shard 2(L2 cache slice 变体)

## 是什么
`Slice_N`(N=1,2,3)是香山 V2R2 L2 cache 的一个 bank 装配壳,与已签核绿基线
`Slice`(sliceId=0, SIGNOFF_PASS / gap_schedule VMUCP+BB)**仅是参数变体**。golden
`Slice_N.sv` 与 `Slice.sv` 全文 10019 行,name-normalize 后逐行 diff 只差 8/14/14 行:

| 差异点 | Slice(base) | Slice_1 | Slice_2 | Slice_3 |
|---|---|---|---|---|
| `io_sliceId`(喂 mainPipe) | 2'h0 | 2'h1 | 2'h2 | 2'h3 |
| 子模块 `directory` 类型 | Directory | Directory_1 | Directory_2 | Directory_3 |
| 子模块 `dataStorage` 类型 | DataStorage | DataStorage_1 | DataStorage_2 | DataStorage_3 |
| 子模块 `mbistPl` 类型 | L2Slice | L2Slice_1 | L2Slice_2 | L2Slice_3 |
| port `boreChildrenBd_bore_array` | [4:0] | [4:0] | [5:0] | [5:0] |
| wire `bd_array` | [4:0] | [4:0] | [5:0] | [5:0] |
| wire `childBd_array`(→directory) | [3:0] | [4:0] | [5:0] | [5:0] |
| wire `childBd_1_array`(→dataStorage) | [4:0] | [4:0] | [5:0] | [5:0] |

其余 ~10000 行(SinkA/SinkC/reqArb/mainPipe/mshrCtl/TX·RX 六通道/refill·release
buffer/MBIST bore 改名/error·perf 打拍/24 条顶层 io assign)逐字一致。array 位宽差
= MBIST 自测树对下级 SRAM 阵列的 array-id 编址位数,不影响 cache 数据通路行为。

## 实现(复用绿基线核)
`scripts/gen_slice_variants.py` 从绿基线 impl(`rtl/l2/{Slice.sv,Slice_wrapper.sv,
slice_*.svh}`)机械派生:
- 变体核 `xs_Slice_{N}_core`(`rtl/l2/slice_variants/Slice_{N}_core.sv`)= 复用基线核
  结构,只 `include` 变体 svh(收窄/加宽 array 网 + 换绿子模块名 + 设 sliceId);
- 变体扁平 wrapper `Slice_{N}`(golden 同名同端口,例化变体核);
- 变体 UT 双例化(golden `Slice_{N}` vs impl `Slice_{N}_xs`)。

## 签核(assembly 父,AUTHORITATIVE = fm.log FM_RESULT SUCCEEDED + 0 failing/0 unmatched)
每 `Slice_N` 为 **assembly 父**,边界镜像绿基线 Slice(codex_0036 裁定):
- **两侧 elaborate(非 305 逻辑子,真实受验)**:DataStorage_N + 其 golden 递归闭包
  (GatedSplittedSRAM_N / L2DataStorage_N / SRAMTemplate_{151|174} / sram_array…)、
  RequestBuffer、RXSNP(+Queue 闭包)、MSHRBuffer、MSHRBuffer_1、ClockGate/ClockMux/
  FastArbiter_3/ram_2x98 等依赖。SRAM 模板/MBIST/仲裁/队列逻辑全参与比对。
- **黑盒(独立已证绿 / green-AUX + 厂商宏,对称同名 hdlin_unresolved_modules=black_box)**:
  13 个已证绿 305 子(sinkA/sinkC/grantBuf/txreq/txdat/txrsp/rxdat/rxrsp/reqArb/
  mainPipe/mshrCtl)+ **Directory_N**(green-AUX,native SUCCEEDED,自身残余 L2Directory_N
  在 agent/l2dir-n 已 PASS)+ **L2Slice_N**(mbistPl,已 PASS)+ 厂商 SRAM 宏 `array_18_ext`
  ×8。声明见 `verif/signoff/allow/Slice_{N}.json`。
- **本层证的 = Slice_N 中层互联 glue**:MBIST bore 改名布线、error/perf 二级打拍流水
  (perf_<k>_value_s1→s2,fm_pins.tcl 按名钉拍)、24 条顶层 io assign、探针死端。

### 结果(native FM,assembly + vmucp/matched-unread)
| 变体 | passing | failing | unmatched | 无 vmucp passing | +vmucp 双射 |
|---|---|---|---|---|---|
| Slice_1 | 46127 | 0 | 0(0) | 45368 | +759 |
| Slice_2 | 46131 | 0 | 0(0) | 45372 | +759 |
| Slice_3 | 46131 | 0 | 0(0) | 45372 | +759 |

759 对称死 DFF = 两侧 elaborate 的非 305 子(MSHRBuffer refillBuf/releaseBuf、
DataStorage_N、RequestBuffer、RXSNP)内的 cone-dead 寄存器,本 bank 配置下无观测路径,
名字双射 `r:/WORK/Slice_N/<child>/X_reg` ↔ `i:/WORK/Slice_N/u_core/<child>/X_reg`
(impl 例化同款 golden 子,完美同名)。`verify_matched_unread=true` 让 FM **实际逐位比对**
这 759 点(passing 45368/45372 → 46127/46131,+759 全 passing/0 fail)= 证明真等价、
非 vacuous。与绿基线 Slice(同 759 对称死 vmucp)完全一致。9 个 Constant reg Not-Compared
= 常数驱动死位,不参与比对无害。

### UT
双例化 golden `Slice_N` vs impl `Slice_N_xs`,seed 1/7/42 各 200000 checks errors=0。

## main 需应用(AUX→signoff 台账整合)
1. `verif/signoff/assembly_depends.tsv`:加 `Slice_1/2/3 → {13绿305子, Directory_N,
   L2Slice_N, DataStorage_N, RequestBuffer, RXSNP, MSHRBuffer[_1]}`。
2. `scripts/fm_eq.tcl` + `scripts/sidecar/run_signoff_target.sh` 的 verify_matched_unread
   白名单:把 `Slice_1 Slice_2 Slice_3` 加入(同绿基线 Slice standing rule)。
3. Directory_N(black-boxed)当前 PASS_PENDING_WHITELIST → conditionally green,依赖其
   自身残余 L2Directory_N(agent/l2dir-n 已 PASS)promote;L2Directory_N 落 main 后
   Directory_N 转 PASS,Slice_N 依赖闭包全绿。
