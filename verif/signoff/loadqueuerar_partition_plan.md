# LoadQueueRAR 分区证明 plan(LOADQUEUERAR_MAP_CANARY = NO-GO 后的替代)

## 根因(为何 map 不可行)
impl 用 `rar_entry_t [127:0] entry` **packed struct 数组**(整个 entry 阵列 = 单个打包寄存器,
72 逻辑条目 × {allocated, robIdx{flag,value}, lqIdx{flag,value}, released} 打包成位向量);
golden 是 firtool 展平的 **72 组独立寄存器**(`allocated_0..71`, `uop_N_robIdx_flag/value`,
`released_N` ...)。register 级 set_user_match 无法在"72 平寄存器 ↔ 1 打包向量位切片"间形成合规
双射,故转分区。matching 组合爆炸(1421M/8005 3%)正源于此结构级失配。

## 分区证明结构(三块;每块的 cutpoint 假设都须独立证明,禁 dont_verify)

### 抽象关系 R(reset 建立 + 每次更新保持 + 推出输出一致)
定义状态对应关系 R,把 golden 的平寄存器组与 impl 的 packed entry 位切片绑定:
```
R:  ∀i∈[0,72):  golden.allocated_i        ≡ impl.entry[i].allocated
                golden.uop_i_robIdx_flag   ≡ impl.entry[i].robIdx.flag
                golden.uop_i_robIdx_value  ≡ impl.entry[i].robIdx.value
                golden.uop_i_lqIdx_flag    ≡ impl.entry[i].lqIdx.flag
                golden.uop_i_lqIdx_value   ≡ impl.entry[i].lqIdx.value
                golden.released_i          ≡ impl.entry[i].released
    freelist:   golden._freeList_* 循环队列状态 ≡ impl freelist headPtr/tailPtr/validCount
    release:    golden.release2Cycle_{valid,bits_paddr,valid_REG}
                                        ≡ impl.release2_{valid,paddr,valid_q1}
```
证明义务:(1) reset 后 R 成立;(2) 每拍更新后 R 保持(归纳);(3) R ⟹ 所有输出端口一致。

### 块 1: allocation / freeList
- 覆盖: needEnqueue/acceptedVec 计算、freelist 分配(headPtr 出队)、entry 写入(allocated 置位)。
- cutpoint: freelist 子模块输出(allocateSlot/canAllocate)——须**独立证明** golden FreeList_N ≡
  impl freelist(两侧同一循环队列语义), 非 dont_verify。
- 义务: 给定 R 与相同输入, 分配后 entry.allocated / freelist 指针的更新两侧保持 R。

### 块 2: entry 状态更新(CAM 匹配 / released 判定 / revoke)
- 覆盖: paddr 哈希 CAM 匹配(matchMask)、release1Cycle 现场置 released、redirect 冲刷、revoke 撤销。
- cutpoint: paddr CAM 存储(entry.ppaddr, golden 无独立 reg 名)——须证明两侧哈希+比较等价。
- 义务: 给定 R, 每种更新事件(入队置 released / release 命中 / 冲刷 / revoke)后 entry 状态保持 R。
- **matchMask 位宽(1 vs 3)歧义**在此块内解决: 证明 golden `matchMask_r_i` 与 impl
  `matchMask[w][i]` 的对应(按 load 口 w 分解), 而非在顶层 set_user_match 硬配。

### 块 3: release / output
- 覆盖: release2Cycle 两级流水(release2_valid_q1→release2_valid + release2_paddr RegEnable)、
  query 响应(io_query_w_resp_valid / rep_frm_fetch)、violation 判定输出。
- 义务: R ⟹ 所有 `io_query_*` / `auto_*` 输出逐 bit 一致。

## 执行(先 plan, 不急跑长证明)
1. 本 plan 评审通过后, 按块拆 FM proof(每块单独 elaborate + 局部 compare-point 集)。
2. 块间 cutpoint(freelist 输出 / CAM 存储)用独立子证明闭合, 结果作为上层假设(有证据链, 非 dont_verify)。
3. 每块限时 canary 评估收敛; 收敛后合并为完整 LoadQueueRAR 结论。
4. 所有假设/cutpoint 进 provenance(hash 绑定), 禁 dont_verify / 删点 / 放宽 appvar。

## 状态
LOADQUEUERAR_MAP_CANARY = NO-GO(结构不可双射)。本 plan 待评审; 通过后进入分块证明工程。
