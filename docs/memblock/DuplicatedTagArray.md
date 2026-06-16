# DuplicatedTagArray —— DCache 多副本 Tag 阵列

## 1. 架构定位

`DuplicatedTagArray` 是香山 V2R2 L1 DCache 的**标签（tag）存储体**。DCache 是 4 路组相联、
256 组。判断一次访问是否命中，需要把访问地址的物理标签（tag）与该组 4 路里存的 tag 逐路比较。

问题在于 DCache 同一拍要被**多条流水**查 tag：

- 多条 LoadPipe（load 通道）各自要读 tag 判命中；
- MainPipe 的 replace / probe / store 等也要读 tag。

单口 tag SRAM 一拍只能服务一个读地址。香山的解法是把**整张 tag 表复制 `readPorts` 份**
（本配置 `readPorts = 4`），每份是一个 `TagArray`、自带一套独立读口。于是 4 条流水可以
**并行、互不冲突**地读 tag。4 份副本存的是**同一张** 256 组 × 4 路的 tag 表。

```mermaid
flowchart LR
    subgraph DUP["DuplicatedTagArray（本模块）"]
      direction TB
      ECC["写入: Tag-ECC 编码<br/>(SECDED 7bit)"]
      A0["TagArray 副本0"]
      A1["TagArray 副本1"]
      A2["TagArray 副本2"]
      A3["TagArray 副本3"]
    end
    R0["read[0]"] --> A0
    R1["read[1]"] --> A1
    R2["read[2]"] --> A2
    R3["read[3]"] --> A3
    W["write (refill 新 tag)"] --> ECC
    ECC -->|广播 encTag| A0 & A1 & A2 & A3
    A0 -->|resp[0]| O0["命中比较 (上层)"]
    A1 -->|resp[1]| O1
    A2 -->|resp[2]| O2
    A3 -->|resp[3]| O3
```

## 2. 数据流

- **读**：第 `i` 条流水的请求 `read[i]`（valid + 组索引 idx）只送进副本 `i`。SRAM 同步读，
  下一拍副本 `i` 吐出该组 4 路的 `encTag`（43bit = 36bit tag + 7bit ecc），原样作为 `resp[i]`
  透传给上层（真正的“tag 比较 + ECC 纠错判定”在 MetaArray 顶层做，本模块只负责存取）。
- **写（refill）**：当 DCache 取回一条新 cacheline 要装入某组某路时，写请求给出
  `idx / way_en / tag`。本模块在顶层**算一次 7bit Tag-ECC**，把 `{ecc, tag}` **同时写进全部 4 份副本**，
  保证副本一致。
- **ready**：只有副本 3 的读 ready 被引出（`io_read_3_ready`），写口 ready 恒 true（端口被 firtool 裁掉）。

## 3. Tag ECC（SECDED 单纠错双检错）

物理 tag 宽 36bit，校验码 7bit，合成 43bit。编码与 rocket-chip `SECDEDCode.encode` 一致：

- `ecc[5:0]`：6 个奇偶校验位，第 k 位 = `tag` 与某固定生成掩码按位与后再 XOR 归约；
- `ecc[6]`：整体奇偶位 = 对 `{ecc[5:0], tag}` 全体再 XOR（提供“双比特错可检出”能力）。

实现见 `dtagarray_pkg::tag_ecc_encode`。这些掩码是码字生成矩阵常量，与 golden 一致：

| 校验位 | 生成掩码（over 36bit tag） |
|---|---|
| ecc[0] | `36'h556AAAD5B` |
| ecc[1] | `36'h99B33366D` |
| ecc[2] | `36'h1E3C3C78E` |
| ecc[3] | `36'hE03FC07F0` |
| ecc[4] | `36'h003FFF800` |
| ecc[5] | `36'hFFC000000` |
| ecc[6] | 整体奇偶 `^{ecc[5:0], tag}` |

> 注意：本模块只在**写入时编码** ECC。读出时把存好的 43bit 原样吐出，**解码/判错在上层**完成。

## 4. 层次结构与黑盒

```
DuplicatedTagArray
 ├─ xs_DuplicatedTagArray_core   ← 本工程可读核（副本路由 + 写 ECC 编码 + 写广播）
 ├─ TagArray ×4 (golden 黑盒)
 │    └─ TagSRAMBank ×2 (DCacheWayDiv=2 路/bank)
 │         └─ SRAMTemplate_114 → sram_array_…_dcsh_tag → array_9 (厂商存储宏)
 └─ MbistPipeDcacheTag (golden 黑盒，DFT/MBIST)
```

可读核只产出/接收各副本 `TagArray` 的读/写/resp 接口；`TagArray` 内部的 SRAM 体、上电逐组清零
（rst_cnt）、MBIST bore 链均为 golden 黑盒，由 wrapper 例化并按 golden 拓扑互联
（8 条 childBd bore 链对应 4 副本 × 2 TagSRAMBank；`sigFromSrams_bore_N` 旁带映射 array_k ← [2k, 2k+1]）。

## 5. 接口要点

| 端口 | 含义 |
|---|---|
| `io_read_{0..3}_valid/idx` | 4 个独立读端口（valid + 8bit 组索引） |
| `io_read_3_ready` | 仅副本 3 的读 ready 引出 |
| `io_resp_{p}_{w}` (43bit) | 端口 p、way w 的 encTag 读结果（晚 1 拍） |
| `io_write_valid/idx/way_en/tag` | refill 写：组索引、写哪几路、36bit tag |
| `boreChildrenBd_* / sigFromSrams_*` | MBIST bore + SRAM DFT 旁带（黑盒透传） |

## 6. 验证结果

- **结构闸门**：`function automatic`=1（ECC 编码）、`genvar/for`=2（副本路由）、
  展平名/生成痕迹=0；核+pkg 共 140 行 vs golden 651 行（4.6×）。
  本模块本质是“多副本 + 透传路由”，无状态机/离散量，故无 enum；多路读结果用 `io_resp[p][w]`
  二维数组端口取代 golden 的扁平 `io_resp_N_M`。
- **UT**（`verif/ut/DuplicatedTagArray/`，golden vs `_xs` 双例化，共用 golden TagArray/SRAM/Mbist 黑盒）：
  seed 1/7/42 各 **checks=199700 errors=0**（WARMUP=300 跳过上电逐组清零窗口；
  `!$isunknown(golden)` 跳过 don't-care）。逐拍比对全部 `io_resp_*` + `io_read_3_ready`。
- **FM**（SRAM/Mbist 两侧黑盒）：**SUCCEEDED**（0 failing）。
