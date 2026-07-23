// =============================================================================
//  xs_LoadQueueRAR_core —— Load-Load (RAR) 违例检测队列（可读重写，合成层次）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel，非 firtool golden）：
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueRAR.scala
//      src/main/scala/xiangshan/mem/lsqueue/FreeList.scala
//      src/main/scala/xiangshan/mem/lsqueue/LoadQueueData.scala（LqPAddrModule CAM）
//
//  ── 本核的层次（与 golden 顶层镜像，供 FM 合成证明）──────────────────────────────
//  golden 顶层 LoadQueueRAR 恰好只例化两个子模块 + 一小段顶层 glue：
//      FreeList_3   freeList     —— 空闲槽循环队列（分配 headPtr / 回收 tailPtr）
//      LqPAddrModule paddrModule —— 每条目 16-bit 哈希 paddr 的 CAM 存储 + 相等匹配
//  加上顶层 glue：72 个 entry 的 {allocated, robIdx, lqIdx, released} 平寄存器、
//  release 两拍流水、matchMask 打拍、freeMaskVec 计算、revoke、perf。
//
//  本核**例化同名的两个已证子模块**（rtl/memblock/FreeList_3.sv +
//  rtl/memblock/LqPAddrModule.sv，均 native SUCCEEDED），使 impl 层次与 golden 一致：
//    · freelist 全部状态（freeList/headPtr/tailPtr/freeSlotCnt/freeMask/回收流水）
//      移入 FreeList_3 实例；
//    · 每条目 ppaddr 存储 + camHit/releaseHit 相等比较移入 LqPAddrModule 实例；
//    · 顶层 entry[] 只剩 {allocated, robIdx, lqIdx, released} 控制位。
//  这样 packed-vs-展平的爆炸源（顶层 entry[128] 打包 ppaddr/freelist）被消除，
//  monolithic FM 得以收敛；两子模块两侧 elaborate（可读非 vendor 逻辑）逐点比对。
//  见 verif/signoff/loadqueuerar_partition_plan.md 与两块证明文档。
//
//  ── 顶层时序总览（3 个 load 流水口并行，编号 w=0/1/2）─────────────────────────
//     拍 T   (query.req)：判 needEnqueue → freelist 分配 entry → 写 paddr 哈希/uop/released；
//                         同拍对 query.req 做 CAM（paddrModule）算 matchMaskReg。
//     拍 T+1 (query.resp)：resp.valid = RegNext(req.valid)；rep_frm_fetch = |matchMask（打 1 拍）。
//     release：release1Cycle = 当拍 io.release；release2Cycle = 延（1~2）拍。
//     出队：条目的 lqIdx 已“不晚于 ldWbPtr”（已写回）或被 redirect 冲刷 → 释放 entry。
//     revoke：若某 load 在 query 后一拍需要 replay，撤销它上一拍占的 entry。
// =============================================================================
module xs_LoadQueueRAR_core
  import loadqueuerar_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,

  // ---- 控制：重定向（冲刷比其更年轻的条目）----
  input  logic                          redirect_valid,
  input  rob_ptr_t                      redirect_robIdx,
  input  logic                          redirect_level,

  // ---- 违例查询口（每个 load 流水一个）----
  input  logic       [LD_WIDTH-1:0]     q_req_valid,
  input  rob_ptr_t   [LD_WIDTH-1:0]     q_req_robIdx,
  input  lq_ptr_t    [LD_WIDTH-1:0]     q_req_lqIdx,
  input  logic [LD_WIDTH-1:0][PADDR_BITS-1:0] q_req_paddr,
  input  logic       [LD_WIDTH-1:0]     q_req_data_valid,
  input  logic       [LD_WIDTH-1:0]     q_req_is_nc,
  input  logic       [LD_WIDTH-1:0]     q_revoke,
  output logic       [LD_WIDTH-1:0]     q_req_ready,
  output logic       [LD_WIDTH-1:0]     q_resp_valid,
  output logic       [LD_WIDTH-1:0]     q_resp_rep_frm_fetch,

  // ---- release：L2 对某 cacheline 的 invalidate 通知 ----
  input  logic                          release_valid,
  input  logic [PADDR_BITS-1:0]         release_paddr,

  // ---- 来自 VirtualLoadQueue 的写回指针（判出队）----
  input  lq_ptr_t                       ldWbPtr,

  // ---- 全局输出 ----
  output logic                          lqFull,
  output logic [CNT_W-1:0]              validCount,
  output logic [1:0]                    perf_enq,           // 本拍入队数（perf event）
  output logic [1:0]                    perf_ldld_violation // 本拍违例数（perf event）
);

  // ===========================================================================
  //  0. 条目控制存储：72 个 entry 的 {allocated, robIdx, lqIdx, released}
  //     （ppaddr 存储已移入 paddrModule 实例；freelist 状态已移入 freeList 实例）
  // ===========================================================================
  logic     [RAR_SIZE-1:0] entry_allocated;
  logic     [RAR_SIZE-1:0] entry_released;
  rob_ptr_t                entry_robIdx [RAR_SIZE];
  lq_ptr_t                 entry_lqIdx  [RAR_SIZE];

  // ===========================================================================
  //  1. release 的两拍版本
  //     paddr 写进 paddrModule 需 1 拍才可见，故 release 要保留一份延迟版
  //     release2Cycle，让“本拍刚入队、还看不到自己 paddr”的条目也能在下一拍补判失效。
  //     （golden 实测：release2_valid 是两级 RegNext；bits 是单级 RegEnable。）
  // ===========================================================================
  logic                  release2_valid_q1, release2_valid;
  //  release2_paddr 只需 **cacheline 对齐位 [47:6]**（enq_released 只比较 [47:6]，
  //  golden 也只读 release2Cycle_bits_paddr[47:6]）。故只存 [47:6]，不存死位 [5:0]——
  //  impl clean；golden 存满 48 位、[5:0] 恒不读 = golden-only cone-dead 冗余。
  //  bit 下标保留 47..6（与 golden 同位）便于 FM 签名配对。
  logic [PADDR_BITS-1:DCACHE_LINE_OFF] release2_paddr;
  //  注意：golden release2Cycle_valid/_REG/bits **无 reset**（posedge clock 无 if(reset)），
  //  照搬无 reset（reset 后为 X/自由，与 golden 一致；FM 才判等价）。
  always_ff @(posedge clock) begin
    release2_valid_q1 <= release_valid;            // 第 1 级 RegNext（无 reset）
    release2_valid    <= release2_valid_q1;         // 第 2 级 RegNext（无 reset）
    if (release_valid) release2_paddr <= release_paddr[PADDR_BITS-1:DCACHE_LINE_OFF];
  end

  // ===========================================================================
  //  2. needEnqueue：该 load 是否真的要入队 ----
  //     req.valid 且 该 load 比 ldWbPtr 更年轻（尚未写回）且 未被 redirect 冲刷。
  // ===========================================================================
  logic [LD_WIDTH-1:0] needEnqueue;
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++) begin
      logic not_writebacked, cancel;
      not_writebacked = lqAfter(q_req_lqIdx[w], ldWbPtr);
      cancel          = rob_need_flush(redirect_valid, redirect_level, q_req_robIdx[w], redirect_robIdx);
      needEnqueue[w]  = q_req_valid[w] & not_writebacked & ~cancel;
    end
  end

  // ===========================================================================
  //  3. freelist 子模块（FreeList_3 实例）
  //     子模块对第 w 个分配口**固定**呈现 headPtr+w（w=0/1/2）处的空闲槽 / 可分标志；
  //     顶层把 needEnqueue 按 PopCount 映射到连续偏移，从这 3 个固定口里选。
  //       offset(0) = 0
  //       offset(1) = PopCount(needEnqueue.take(1)) = needEnqueue[0]
  //       offset(2) = PopCount(needEnqueue.take(2)) = needEnqueue[0]+needEnqueue[1]
  //     （与 golden 顶层的 PopCount 索引 + 固定口查表逻辑一致。）
  // ===========================================================================
  logic [IDX_W-1:0] fl_allocateSlot [LD_WIDTH];  // 固定 offset 0/1/2 的空闲槽
  logic             fl_canAllocate  [LD_WIDTH];  // 固定 offset 0/1/2 的可分标志
  logic [CNT_W-1:0] fl_validCount;
  logic             fl_empty;

  // 顶层回收掩码（喂 freelist.io_free）：见第 6 节 freeMaskVec
  logic [RAR_SIZE-1:0] freeMaskVec;

  // 本拍实际接收并分配的口（needEnqueue & ready）
  logic [LD_WIDTH-1:0] acceptedVec;

  FreeList_3 freeList (
    .clock             (clock),
    .reset             (reset),
    .io_allocateSlot_0 (fl_allocateSlot[0]),
    .io_allocateSlot_1 (fl_allocateSlot[1]),
    .io_allocateSlot_2 (fl_allocateSlot[2]),
    .io_canAllocate_0  (fl_canAllocate[0]),
    .io_canAllocate_1  (fl_canAllocate[1]),
    .io_canAllocate_2  (fl_canAllocate[2]),
    .io_doAllocate_0   (acceptedVec[0]),
    .io_doAllocate_1   (acceptedVec[1]),
    .io_doAllocate_2   (acceptedVec[2]),
    .io_free           (freeMaskVec),
    .io_validCount     (fl_validCount),
    .io_empty          (fl_empty)
  );

  // ---- PopCount 偏移映射（顶层块外逻辑，从 3 个固定口里选每口的 slot/ready）----
  //   镜像 golden 顶层：4 项查表 {slot0, slot2, slot1, slot0}（index 0/1/2/3），按 2-bit
  //   偏移取。用 4 元表使索引静态在界（2-bit index → 4-deep），消 FMR_ELAB-147；
  //   第 3 项（index 3）复用 slot0，因 max PopCount(take(w)) ≤ w ≤ 2 从不取到。
  logic [IDX_W-1:0] slotLut [4];   // {slot0, slot1, slot2, slot0}（index 3 = slot0，从不取）
  logic             canLut  [4];   // {can0,  can1,  can2,  can0 }
  always_comb begin
    slotLut[0] = fl_allocateSlot[0]; slotLut[1] = fl_allocateSlot[1];
    slotLut[2] = fl_allocateSlot[2]; slotLut[3] = fl_allocateSlot[0];
    canLut[0]  = fl_canAllocate[0];  canLut[1]  = fl_canAllocate[1];
    canLut[2]  = fl_canAllocate[2];  canLut[3]  = fl_canAllocate[0];
  end

  logic [1:0]       alloc_off  [LD_WIDTH];   // 每口 PopCount 偏移
  logic [IDX_W-1:0] alloc_slot [LD_WIDTH];   // 每口拿到的 entry 编号
  logic             alloc_can  [LD_WIDTH];   // 每口是否有空闲槽可分
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++) begin
      logic [1:0] off;
      off = '0;
      for (int k = 0; k < LD_WIDTH; k++)
        if (k < w) off += {1'b0, needEnqueue[k]};   // PopCount(needEnqueue.take(w))
      alloc_off[w]  = off;
      alloc_slot[w] = slotLut[off];   // 2-bit index，静态在界
      alloc_can[w]  = canLut[off];
      q_req_ready[w] = needEnqueue[w] ? alloc_can[w] : 1'b1;
      acceptedVec[w] = needEnqueue[w] & q_req_ready[w];
    end
  end

  // ===========================================================================
  //  4. CAM 子模块（LqPAddrModule 实例）
  //     每条目存 16-bit 哈希 ppaddr（写入拍 = 入队拍，waddr = alloc_slot、
  //     wdata = 查询 paddr 哈希、wen = acceptedVec）；对 4 个读口做纯相等 CAM 比较。
  //       io_releaseViolationMmask_w_i = (hash(q_req_paddr[w]) == data[i])   —— camHit
  //       io_releaseMmask_2_i          = (hash(release_paddr)  == data[i])   —— releaseHit 基础
  // ===========================================================================
  logic [LD_WIDTH-1:0][PP_BITS-1:0] q_ppaddr;         // 查询口 paddr 哈希（喂读口 mdata）
  logic [PP_BITS-1:0]               release1_ppaddr;   // release paddr 哈希（喂 releaseMdata_2）
  logic [PP_BITS-1:0]               wr_ppaddr [LD_WIDTH]; // 各写口写入的哈希 = 该口 paddr 哈希
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++) begin
      q_ppaddr[w]  = gen_partial_paddr(q_req_paddr[w]);
      wr_ppaddr[w] = q_ppaddr[w];   // golden：io_wdata_w = io_releaseViolationMdata_w（同哈希）
    end
    release1_ppaddr = gen_partial_paddr(release_paddr);
  end

  // 子模块读口输出（camHit：每口 × 72；releaseHit 基础：72）
  logic [LD_WIDTH-1:0][RAR_SIZE-1:0] camHit;
  logic [RAR_SIZE-1:0]               relCamHit;

  LqPAddrModule paddrModule (
    .clock                        (clock),
    .reset                        (reset),
    .io_wen_0                     (acceptedVec[0]),
    .io_wen_1                     (acceptedVec[1]),
    .io_wen_2                     (acceptedVec[2]),
    .io_waddr_0                   (alloc_slot[0]),
    .io_waddr_1                   (alloc_slot[1]),
    .io_waddr_2                   (alloc_slot[2]),
    .io_wdata_0                   (wr_ppaddr[0]),
    .io_wdata_1                   (wr_ppaddr[1]),
    .io_wdata_2                   (wr_ppaddr[2]),
    // ---- release1Cycle CAM 口：mdata = release paddr 哈希 → relCamHit ----
    .io_releaseMdata_2            (release1_ppaddr),
    .io_releaseMmask_2_0           (relCamHit[0]),
    .io_releaseMmask_2_1           (relCamHit[1]),
    .io_releaseMmask_2_2           (relCamHit[2]),
    .io_releaseMmask_2_3           (relCamHit[3]),
    .io_releaseMmask_2_4           (relCamHit[4]),
    .io_releaseMmask_2_5           (relCamHit[5]),
    .io_releaseMmask_2_6           (relCamHit[6]),
    .io_releaseMmask_2_7           (relCamHit[7]),
    .io_releaseMmask_2_8           (relCamHit[8]),
    .io_releaseMmask_2_9           (relCamHit[9]),
    .io_releaseMmask_2_10          (relCamHit[10]),
    .io_releaseMmask_2_11          (relCamHit[11]),
    .io_releaseMmask_2_12          (relCamHit[12]),
    .io_releaseMmask_2_13          (relCamHit[13]),
    .io_releaseMmask_2_14          (relCamHit[14]),
    .io_releaseMmask_2_15          (relCamHit[15]),
    .io_releaseMmask_2_16          (relCamHit[16]),
    .io_releaseMmask_2_17          (relCamHit[17]),
    .io_releaseMmask_2_18          (relCamHit[18]),
    .io_releaseMmask_2_19          (relCamHit[19]),
    .io_releaseMmask_2_20          (relCamHit[20]),
    .io_releaseMmask_2_21          (relCamHit[21]),
    .io_releaseMmask_2_22          (relCamHit[22]),
    .io_releaseMmask_2_23          (relCamHit[23]),
    .io_releaseMmask_2_24          (relCamHit[24]),
    .io_releaseMmask_2_25          (relCamHit[25]),
    .io_releaseMmask_2_26          (relCamHit[26]),
    .io_releaseMmask_2_27          (relCamHit[27]),
    .io_releaseMmask_2_28          (relCamHit[28]),
    .io_releaseMmask_2_29          (relCamHit[29]),
    .io_releaseMmask_2_30          (relCamHit[30]),
    .io_releaseMmask_2_31          (relCamHit[31]),
    .io_releaseMmask_2_32          (relCamHit[32]),
    .io_releaseMmask_2_33          (relCamHit[33]),
    .io_releaseMmask_2_34          (relCamHit[34]),
    .io_releaseMmask_2_35          (relCamHit[35]),
    .io_releaseMmask_2_36          (relCamHit[36]),
    .io_releaseMmask_2_37          (relCamHit[37]),
    .io_releaseMmask_2_38          (relCamHit[38]),
    .io_releaseMmask_2_39          (relCamHit[39]),
    .io_releaseMmask_2_40          (relCamHit[40]),
    .io_releaseMmask_2_41          (relCamHit[41]),
    .io_releaseMmask_2_42          (relCamHit[42]),
    .io_releaseMmask_2_43          (relCamHit[43]),
    .io_releaseMmask_2_44          (relCamHit[44]),
    .io_releaseMmask_2_45          (relCamHit[45]),
    .io_releaseMmask_2_46          (relCamHit[46]),
    .io_releaseMmask_2_47          (relCamHit[47]),
    .io_releaseMmask_2_48          (relCamHit[48]),
    .io_releaseMmask_2_49          (relCamHit[49]),
    .io_releaseMmask_2_50          (relCamHit[50]),
    .io_releaseMmask_2_51          (relCamHit[51]),
    .io_releaseMmask_2_52          (relCamHit[52]),
    .io_releaseMmask_2_53          (relCamHit[53]),
    .io_releaseMmask_2_54          (relCamHit[54]),
    .io_releaseMmask_2_55          (relCamHit[55]),
    .io_releaseMmask_2_56          (relCamHit[56]),
    .io_releaseMmask_2_57          (relCamHit[57]),
    .io_releaseMmask_2_58          (relCamHit[58]),
    .io_releaseMmask_2_59          (relCamHit[59]),
    .io_releaseMmask_2_60          (relCamHit[60]),
    .io_releaseMmask_2_61          (relCamHit[61]),
    .io_releaseMmask_2_62          (relCamHit[62]),
    .io_releaseMmask_2_63          (relCamHit[63]),
    .io_releaseMmask_2_64          (relCamHit[64]),
    .io_releaseMmask_2_65          (relCamHit[65]),
    .io_releaseMmask_2_66          (relCamHit[66]),
    .io_releaseMmask_2_67          (relCamHit[67]),
    .io_releaseMmask_2_68          (relCamHit[68]),
    .io_releaseMmask_2_69          (relCamHit[69]),
    .io_releaseMmask_2_70          (relCamHit[70]),
    .io_releaseMmask_2_71          (relCamHit[71]),
    // ---- 3 个 load 查询口：mdata = 查询 paddr 哈希 → camHit[w] ----
    .io_releaseViolationMdata_0   (q_ppaddr[0]),
    .io_releaseViolationMdata_1   (q_ppaddr[1]),
    .io_releaseViolationMdata_2   (q_ppaddr[2]),
    .io_releaseViolationMmask_0_0  (camHit[0][0]),
    .io_releaseViolationMmask_0_1  (camHit[0][1]),
    .io_releaseViolationMmask_0_2  (camHit[0][2]),
    .io_releaseViolationMmask_0_3  (camHit[0][3]),
    .io_releaseViolationMmask_0_4  (camHit[0][4]),
    .io_releaseViolationMmask_0_5  (camHit[0][5]),
    .io_releaseViolationMmask_0_6  (camHit[0][6]),
    .io_releaseViolationMmask_0_7  (camHit[0][7]),
    .io_releaseViolationMmask_0_8  (camHit[0][8]),
    .io_releaseViolationMmask_0_9  (camHit[0][9]),
    .io_releaseViolationMmask_0_10 (camHit[0][10]),
    .io_releaseViolationMmask_0_11 (camHit[0][11]),
    .io_releaseViolationMmask_0_12 (camHit[0][12]),
    .io_releaseViolationMmask_0_13 (camHit[0][13]),
    .io_releaseViolationMmask_0_14 (camHit[0][14]),
    .io_releaseViolationMmask_0_15 (camHit[0][15]),
    .io_releaseViolationMmask_0_16 (camHit[0][16]),
    .io_releaseViolationMmask_0_17 (camHit[0][17]),
    .io_releaseViolationMmask_0_18 (camHit[0][18]),
    .io_releaseViolationMmask_0_19 (camHit[0][19]),
    .io_releaseViolationMmask_0_20 (camHit[0][20]),
    .io_releaseViolationMmask_0_21 (camHit[0][21]),
    .io_releaseViolationMmask_0_22 (camHit[0][22]),
    .io_releaseViolationMmask_0_23 (camHit[0][23]),
    .io_releaseViolationMmask_0_24 (camHit[0][24]),
    .io_releaseViolationMmask_0_25 (camHit[0][25]),
    .io_releaseViolationMmask_0_26 (camHit[0][26]),
    .io_releaseViolationMmask_0_27 (camHit[0][27]),
    .io_releaseViolationMmask_0_28 (camHit[0][28]),
    .io_releaseViolationMmask_0_29 (camHit[0][29]),
    .io_releaseViolationMmask_0_30 (camHit[0][30]),
    .io_releaseViolationMmask_0_31 (camHit[0][31]),
    .io_releaseViolationMmask_0_32 (camHit[0][32]),
    .io_releaseViolationMmask_0_33 (camHit[0][33]),
    .io_releaseViolationMmask_0_34 (camHit[0][34]),
    .io_releaseViolationMmask_0_35 (camHit[0][35]),
    .io_releaseViolationMmask_0_36 (camHit[0][36]),
    .io_releaseViolationMmask_0_37 (camHit[0][37]),
    .io_releaseViolationMmask_0_38 (camHit[0][38]),
    .io_releaseViolationMmask_0_39 (camHit[0][39]),
    .io_releaseViolationMmask_0_40 (camHit[0][40]),
    .io_releaseViolationMmask_0_41 (camHit[0][41]),
    .io_releaseViolationMmask_0_42 (camHit[0][42]),
    .io_releaseViolationMmask_0_43 (camHit[0][43]),
    .io_releaseViolationMmask_0_44 (camHit[0][44]),
    .io_releaseViolationMmask_0_45 (camHit[0][45]),
    .io_releaseViolationMmask_0_46 (camHit[0][46]),
    .io_releaseViolationMmask_0_47 (camHit[0][47]),
    .io_releaseViolationMmask_0_48 (camHit[0][48]),
    .io_releaseViolationMmask_0_49 (camHit[0][49]),
    .io_releaseViolationMmask_0_50 (camHit[0][50]),
    .io_releaseViolationMmask_0_51 (camHit[0][51]),
    .io_releaseViolationMmask_0_52 (camHit[0][52]),
    .io_releaseViolationMmask_0_53 (camHit[0][53]),
    .io_releaseViolationMmask_0_54 (camHit[0][54]),
    .io_releaseViolationMmask_0_55 (camHit[0][55]),
    .io_releaseViolationMmask_0_56 (camHit[0][56]),
    .io_releaseViolationMmask_0_57 (camHit[0][57]),
    .io_releaseViolationMmask_0_58 (camHit[0][58]),
    .io_releaseViolationMmask_0_59 (camHit[0][59]),
    .io_releaseViolationMmask_0_60 (camHit[0][60]),
    .io_releaseViolationMmask_0_61 (camHit[0][61]),
    .io_releaseViolationMmask_0_62 (camHit[0][62]),
    .io_releaseViolationMmask_0_63 (camHit[0][63]),
    .io_releaseViolationMmask_0_64 (camHit[0][64]),
    .io_releaseViolationMmask_0_65 (camHit[0][65]),
    .io_releaseViolationMmask_0_66 (camHit[0][66]),
    .io_releaseViolationMmask_0_67 (camHit[0][67]),
    .io_releaseViolationMmask_0_68 (camHit[0][68]),
    .io_releaseViolationMmask_0_69 (camHit[0][69]),
    .io_releaseViolationMmask_0_70 (camHit[0][70]),
    .io_releaseViolationMmask_0_71 (camHit[0][71]),
    .io_releaseViolationMmask_1_0  (camHit[1][0]),
    .io_releaseViolationMmask_1_1  (camHit[1][1]),
    .io_releaseViolationMmask_1_2  (camHit[1][2]),
    .io_releaseViolationMmask_1_3  (camHit[1][3]),
    .io_releaseViolationMmask_1_4  (camHit[1][4]),
    .io_releaseViolationMmask_1_5  (camHit[1][5]),
    .io_releaseViolationMmask_1_6  (camHit[1][6]),
    .io_releaseViolationMmask_1_7  (camHit[1][7]),
    .io_releaseViolationMmask_1_8  (camHit[1][8]),
    .io_releaseViolationMmask_1_9  (camHit[1][9]),
    .io_releaseViolationMmask_1_10 (camHit[1][10]),
    .io_releaseViolationMmask_1_11 (camHit[1][11]),
    .io_releaseViolationMmask_1_12 (camHit[1][12]),
    .io_releaseViolationMmask_1_13 (camHit[1][13]),
    .io_releaseViolationMmask_1_14 (camHit[1][14]),
    .io_releaseViolationMmask_1_15 (camHit[1][15]),
    .io_releaseViolationMmask_1_16 (camHit[1][16]),
    .io_releaseViolationMmask_1_17 (camHit[1][17]),
    .io_releaseViolationMmask_1_18 (camHit[1][18]),
    .io_releaseViolationMmask_1_19 (camHit[1][19]),
    .io_releaseViolationMmask_1_20 (camHit[1][20]),
    .io_releaseViolationMmask_1_21 (camHit[1][21]),
    .io_releaseViolationMmask_1_22 (camHit[1][22]),
    .io_releaseViolationMmask_1_23 (camHit[1][23]),
    .io_releaseViolationMmask_1_24 (camHit[1][24]),
    .io_releaseViolationMmask_1_25 (camHit[1][25]),
    .io_releaseViolationMmask_1_26 (camHit[1][26]),
    .io_releaseViolationMmask_1_27 (camHit[1][27]),
    .io_releaseViolationMmask_1_28 (camHit[1][28]),
    .io_releaseViolationMmask_1_29 (camHit[1][29]),
    .io_releaseViolationMmask_1_30 (camHit[1][30]),
    .io_releaseViolationMmask_1_31 (camHit[1][31]),
    .io_releaseViolationMmask_1_32 (camHit[1][32]),
    .io_releaseViolationMmask_1_33 (camHit[1][33]),
    .io_releaseViolationMmask_1_34 (camHit[1][34]),
    .io_releaseViolationMmask_1_35 (camHit[1][35]),
    .io_releaseViolationMmask_1_36 (camHit[1][36]),
    .io_releaseViolationMmask_1_37 (camHit[1][37]),
    .io_releaseViolationMmask_1_38 (camHit[1][38]),
    .io_releaseViolationMmask_1_39 (camHit[1][39]),
    .io_releaseViolationMmask_1_40 (camHit[1][40]),
    .io_releaseViolationMmask_1_41 (camHit[1][41]),
    .io_releaseViolationMmask_1_42 (camHit[1][42]),
    .io_releaseViolationMmask_1_43 (camHit[1][43]),
    .io_releaseViolationMmask_1_44 (camHit[1][44]),
    .io_releaseViolationMmask_1_45 (camHit[1][45]),
    .io_releaseViolationMmask_1_46 (camHit[1][46]),
    .io_releaseViolationMmask_1_47 (camHit[1][47]),
    .io_releaseViolationMmask_1_48 (camHit[1][48]),
    .io_releaseViolationMmask_1_49 (camHit[1][49]),
    .io_releaseViolationMmask_1_50 (camHit[1][50]),
    .io_releaseViolationMmask_1_51 (camHit[1][51]),
    .io_releaseViolationMmask_1_52 (camHit[1][52]),
    .io_releaseViolationMmask_1_53 (camHit[1][53]),
    .io_releaseViolationMmask_1_54 (camHit[1][54]),
    .io_releaseViolationMmask_1_55 (camHit[1][55]),
    .io_releaseViolationMmask_1_56 (camHit[1][56]),
    .io_releaseViolationMmask_1_57 (camHit[1][57]),
    .io_releaseViolationMmask_1_58 (camHit[1][58]),
    .io_releaseViolationMmask_1_59 (camHit[1][59]),
    .io_releaseViolationMmask_1_60 (camHit[1][60]),
    .io_releaseViolationMmask_1_61 (camHit[1][61]),
    .io_releaseViolationMmask_1_62 (camHit[1][62]),
    .io_releaseViolationMmask_1_63 (camHit[1][63]),
    .io_releaseViolationMmask_1_64 (camHit[1][64]),
    .io_releaseViolationMmask_1_65 (camHit[1][65]),
    .io_releaseViolationMmask_1_66 (camHit[1][66]),
    .io_releaseViolationMmask_1_67 (camHit[1][67]),
    .io_releaseViolationMmask_1_68 (camHit[1][68]),
    .io_releaseViolationMmask_1_69 (camHit[1][69]),
    .io_releaseViolationMmask_1_70 (camHit[1][70]),
    .io_releaseViolationMmask_1_71 (camHit[1][71]),
    .io_releaseViolationMmask_2_0  (camHit[2][0]),
    .io_releaseViolationMmask_2_1  (camHit[2][1]),
    .io_releaseViolationMmask_2_2  (camHit[2][2]),
    .io_releaseViolationMmask_2_3  (camHit[2][3]),
    .io_releaseViolationMmask_2_4  (camHit[2][4]),
    .io_releaseViolationMmask_2_5  (camHit[2][5]),
    .io_releaseViolationMmask_2_6  (camHit[2][6]),
    .io_releaseViolationMmask_2_7  (camHit[2][7]),
    .io_releaseViolationMmask_2_8  (camHit[2][8]),
    .io_releaseViolationMmask_2_9  (camHit[2][9]),
    .io_releaseViolationMmask_2_10 (camHit[2][10]),
    .io_releaseViolationMmask_2_11 (camHit[2][11]),
    .io_releaseViolationMmask_2_12 (camHit[2][12]),
    .io_releaseViolationMmask_2_13 (camHit[2][13]),
    .io_releaseViolationMmask_2_14 (camHit[2][14]),
    .io_releaseViolationMmask_2_15 (camHit[2][15]),
    .io_releaseViolationMmask_2_16 (camHit[2][16]),
    .io_releaseViolationMmask_2_17 (camHit[2][17]),
    .io_releaseViolationMmask_2_18 (camHit[2][18]),
    .io_releaseViolationMmask_2_19 (camHit[2][19]),
    .io_releaseViolationMmask_2_20 (camHit[2][20]),
    .io_releaseViolationMmask_2_21 (camHit[2][21]),
    .io_releaseViolationMmask_2_22 (camHit[2][22]),
    .io_releaseViolationMmask_2_23 (camHit[2][23]),
    .io_releaseViolationMmask_2_24 (camHit[2][24]),
    .io_releaseViolationMmask_2_25 (camHit[2][25]),
    .io_releaseViolationMmask_2_26 (camHit[2][26]),
    .io_releaseViolationMmask_2_27 (camHit[2][27]),
    .io_releaseViolationMmask_2_28 (camHit[2][28]),
    .io_releaseViolationMmask_2_29 (camHit[2][29]),
    .io_releaseViolationMmask_2_30 (camHit[2][30]),
    .io_releaseViolationMmask_2_31 (camHit[2][31]),
    .io_releaseViolationMmask_2_32 (camHit[2][32]),
    .io_releaseViolationMmask_2_33 (camHit[2][33]),
    .io_releaseViolationMmask_2_34 (camHit[2][34]),
    .io_releaseViolationMmask_2_35 (camHit[2][35]),
    .io_releaseViolationMmask_2_36 (camHit[2][36]),
    .io_releaseViolationMmask_2_37 (camHit[2][37]),
    .io_releaseViolationMmask_2_38 (camHit[2][38]),
    .io_releaseViolationMmask_2_39 (camHit[2][39]),
    .io_releaseViolationMmask_2_40 (camHit[2][40]),
    .io_releaseViolationMmask_2_41 (camHit[2][41]),
    .io_releaseViolationMmask_2_42 (camHit[2][42]),
    .io_releaseViolationMmask_2_43 (camHit[2][43]),
    .io_releaseViolationMmask_2_44 (camHit[2][44]),
    .io_releaseViolationMmask_2_45 (camHit[2][45]),
    .io_releaseViolationMmask_2_46 (camHit[2][46]),
    .io_releaseViolationMmask_2_47 (camHit[2][47]),
    .io_releaseViolationMmask_2_48 (camHit[2][48]),
    .io_releaseViolationMmask_2_49 (camHit[2][49]),
    .io_releaseViolationMmask_2_50 (camHit[2][50]),
    .io_releaseViolationMmask_2_51 (camHit[2][51]),
    .io_releaseViolationMmask_2_52 (camHit[2][52]),
    .io_releaseViolationMmask_2_53 (camHit[2][53]),
    .io_releaseViolationMmask_2_54 (camHit[2][54]),
    .io_releaseViolationMmask_2_55 (camHit[2][55]),
    .io_releaseViolationMmask_2_56 (camHit[2][56]),
    .io_releaseViolationMmask_2_57 (camHit[2][57]),
    .io_releaseViolationMmask_2_58 (camHit[2][58]),
    .io_releaseViolationMmask_2_59 (camHit[2][59]),
    .io_releaseViolationMmask_2_60 (camHit[2][60]),
    .io_releaseViolationMmask_2_61 (camHit[2][61]),
    .io_releaseViolationMmask_2_62 (camHit[2][62]),
    .io_releaseViolationMmask_2_63 (camHit[2][63]),
    .io_releaseViolationMmask_2_64 (camHit[2][64]),
    .io_releaseViolationMmask_2_65 (camHit[2][65]),
    .io_releaseViolationMmask_2_66 (camHit[2][66]),
    .io_releaseViolationMmask_2_67 (camHit[2][67]),
    .io_releaseViolationMmask_2_68 (camHit[2][68]),
    .io_releaseViolationMmask_2_69 (camHit[2][69]),
    .io_releaseViolationMmask_2_70 (camHit[2][70]),
    .io_releaseViolationMmask_2_71 (camHit[2][71])
  );

  // ===========================================================================
  //  5. 违例匹配掩码（组合算，下一拍寄存）
  //     matchMaskReg(i) = allocated(i) & camHit(i) & robIdxMask(i) & released(i)
  // ===========================================================================
  logic [LD_WIDTH-1:0][RAR_SIZE-1:0] matchMaskReg;
  logic [LD_WIDTH-1:0][RAR_SIZE-1:0] matchMask;       // 打 1 拍
  always_comb begin
    for (int w = 0; w < LD_WIDTH; w++)
      for (int i = 0; i < RAR_SIZE; i++)
        matchMaskReg[w][i] = entry_allocated[i]
                           & camHit[w][i]
                           & ptr_is_after_rob(entry_robIdx[i], q_req_robIdx[w])
                           & entry_released[i];
  end

  // matchMask 用**异步 reset**（镜像 golden matchMask_r 的 posedge clock or posedge reset）
  always_ff @(posedge clock or posedge reset) begin
    if (reset) matchMask <= '0;
    else       matchMask <= matchMaskReg;      // GatedValidRegNext
  end
  // q_resp_valid **无 reset**（镜像 golden io_query_*_resp_valid_REG：posedge clock 无 if(reset)）
  always_ff @(posedge clock) begin
    q_resp_valid <= q_req_valid;               // RegNext(req.valid)，无 reset
  end

  for (genvar w = 0; w < LD_WIDTH; w++)
    assign q_resp_rep_frm_fetch[w] = |matchMask[w];   // ParallelORR

  // ===========================================================================
  //  6. release 失效更新口 + 出队 / 回收 freeMaskVec
  // ===========================================================================
  //  release1Cycle 那拍：占用且哈希命中（relCamHit）的条目，延 1 拍把 released 置 1。
  logic [RAR_SIZE-1:0] releaseHit;
  always_comb begin
    for (int i = 0; i < RAR_SIZE; i++)
      releaseHit[i] = relCamHit[i] & entry_allocated[i] & release_valid;
  end
  logic [RAR_SIZE-1:0] releaseHit_d;     // 延 1 拍写回 released
  //  golden REG/REG_N **无 reset**（posedge clock 无 if(reset)）——照搬无 reset。
  always_ff @(posedge clock) begin
    releaseHit_d <= releaseHit;
  end

  // revoke：上一拍的 acceptedVec / alloc_slot 打拍保留
  //   用**异步 reset**（镜像 golden lastCanAccept_*/lastAllocIndex_* 的 posedge clock or posedge reset）
  logic [LD_WIDTH-1:0]            lastCanAccept;
  logic [LD_WIDTH-1:0][IDX_W-1:0] lastAllocIndex;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      lastCanAccept  <= '0;
      lastAllocIndex <= '0;
    end else begin
      lastCanAccept  <= acceptedVec;
      for (int w = 0; w < LD_WIDTH; w++) lastAllocIndex[w] <= alloc_slot[w];
    end
  end

  // 出队释放：lqIdx 已“不晚于 ldWbPtr”（已写回出队）或 被 redirect 冲刷；加 revoke。
  //   revoke 用 **逐条目比较** `lastAllocIndex[w]==i`（镜像 golden per-index 结构），
  //   避免用 7-bit 动态下标写 72-深数组（消 FMR_ELAB-147）。命中且该槽仍占用 → 置回收。
  always_comb begin
    for (int i = 0; i < RAR_SIZE; i++) begin
      logic deqNotBlock, needFlush, revokeHit;
      deqNotBlock = ~ptr_is_before_lq(ldWbPtr, entry_lqIdx[i]);
      needFlush   = rob_need_flush(redirect_valid, redirect_level, entry_robIdx[i], redirect_robIdx);
      revokeHit   = 1'b0;
      for (int w = 0; w < LD_WIDTH; w++)
        if (q_revoke[w] & lastCanAccept[w] & (lastAllocIndex[w] == IDX_W'(i)))
          revokeHit = 1'b1;
      freeMaskVec[i] = entry_allocated[i] & (deqNotBlock | needFlush | revokeHit);
    end
  end

  // ===========================================================================
  //  7. 条目控制寄存器更新（逐 entry，genvar 铺开）
  //     每个 entry 的 allocated/robIdx/lqIdx/released 由 3 个 load 口可能写入
  //     （freelist 保证三口分到的 index 互不相同），以及 release 失效、出队释放。
  //     ppaddr 由 paddrModule 存储（按同一 acceptedVec/alloc_slot 门控），不在此。
  // ===========================================================================
  logic [RAR_SIZE-1:0][LD_WIDTH-1:0] entryWrBy;  // entryWrBy[i][w]：口 w 写 entry i
  always_comb begin
    for (int i = 0; i < RAR_SIZE; i++)
      for (int w = 0; w < LD_WIDTH; w++)
        entryWrBy[i][w] = acceptedVec[w] & (alloc_slot[w] == IDX_W'(i));
  end

  for (genvar i = 0; i < RAR_SIZE; i++) begin : g_entry
    logic                  wr_en;
    rob_ptr_t              wr_robIdx;
    lq_ptr_t               wr_lqIdx;
    logic [PADDR_BITS-1:0] wr_paddr;
    logic                  wr_is_nc, wr_data_valid;
    always_comb begin
      wr_en         = |entryWrBy[i];
      wr_robIdx     = q_req_robIdx[0];
      wr_lqIdx      = q_req_lqIdx[0];
      wr_paddr      = q_req_paddr[0];
      wr_is_nc      = q_req_is_nc[0];
      wr_data_valid = q_req_data_valid[0];
      for (int w = 0; w < LD_WIDTH; w++) begin
        if (entryWrBy[i][w]) begin
          wr_robIdx     = q_req_robIdx[w];
          wr_lqIdx      = q_req_lqIdx[w];
          wr_paddr      = q_req_paddr[w];
          wr_is_nc      = q_req_is_nc[w];
          wr_data_valid = q_req_data_valid[w];
        end
      end
    end

    // 入队 released 初值：NC 恒失效；否则 data 有效且本 cacheline 已被 release1/2Cycle 命中
    // （用**整 cacheline 地址 [47:6]** 比较）也立刻失效。优先级：NC > cycle1 > cycle2 > none。
    released_cause_e enq_rel_cause;
    logic            enq_released;
    always_comb begin
      logic hit2, hit1;
      hit2 = release2_valid & (wr_paddr[PADDR_BITS-1:DCACHE_LINE_OFF]
                               == release2_paddr);   // release2_paddr 已只含 [47:6]
      hit1 = release_valid  & (wr_paddr[PADDR_BITS-1:DCACHE_LINE_OFF]
                               == release_paddr[PADDR_BITS-1:DCACHE_LINE_OFF]);
      if      (wr_is_nc)                  enq_rel_cause = REL_NC;
      else if (wr_data_valid & hit1)      enq_rel_cause = REL_HIT_CYCLE1;
      else if (wr_data_valid & hit2)      enq_rel_cause = REL_HIT_CYCLE2;
      else                               enq_rel_cause = REL_NONE;
      enq_released = (enq_rel_cause != REL_NONE);
    end

    // allocated / released 用**异步 reset**（镜像 golden allocated_N/released_N 的
    // posedge clock or posedge reset）。uop(robIdx/lqIdx) golden 无 reset(enable-only,
    // posedge clock)，单独一个同步块。async/sync 混一块非法，故拆两块。
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        entry_allocated[i] <= 1'b0;
        entry_released[i]  <= 1'b0;
      end else begin
        if (freeMaskVec[i])      entry_allocated[i] <= 1'b0;
        else if (wr_en)          entry_allocated[i] <= 1'b1;
        if (wr_en) entry_released[i] <= enq_released | releaseHit_d[i];
        else       entry_released[i] <= entry_released[i] | releaseHit_d[i];
      end
    end
    // uop：仅入队那拍写（无 reset，靠 allocated 门控读出）——镜像 golden uop_* 同步无 reset
    always_ff @(posedge clock) begin
      if (wr_en) begin
        entry_robIdx[i] <= wr_robIdx;
        entry_lqIdx[i]  <= wr_lqIdx;
      end
    end
  end

  // ===========================================================================
  //  8. 全局输出（validCount / lqFull 由 freelist 子模块给出）
  // ===========================================================================
  assign lqFull     = fl_empty;
  assign validCount = fl_validCount;

  // ===========================================================================
  //  9. perf events（2 路：本拍入队数 / 本拍违例数；各打 2 拍对齐）
  // ===========================================================================
  logic [1:0] enq_cnt, viol_cnt;
  always_comb begin
    enq_cnt  = '0;
    viol_cnt = '0;
    for (int w = 0; w < LD_WIDTH; w++) begin
      enq_cnt  += {1'b0, (q_req_valid[w] & q_req_ready[w])};
      viol_cnt += {1'b0, (q_resp_valid[w] & q_resp_rep_frm_fetch[w])};
    end
  end
  logic [1:0] perf_enq_d, perf_viol_d;
  //  golden io_perf_*_value_REG/_REG_1 **无 reset**（posedge clock 无 if(reset)）——照搬无 reset。
  always_ff @(posedge clock) begin
    perf_enq_d <= enq_cnt;    perf_enq <= perf_enq_d;             // 两级，无 reset
    perf_viol_d <= viol_cnt;  perf_ldld_violation <= perf_viol_d;  // 两级，无 reset
  end

  // ===========================================================================
  //  局部纯函数 / 辅助（放近使用处）
  // ===========================================================================
  // lqIdx isAfter：a 比 b 更年轻（needEnqueue 用）
  function automatic logic lqAfter(input lq_ptr_t a, input lq_ptr_t b);
    return a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

endmodule
