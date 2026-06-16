// 子模块例化（黑盒，与 golden 共用同一份定义；UT/FM 两侧相同）
//  - LqVAddrModule : 72 entry 虚地址存储（3 读 3 写，写延迟 2 拍）。存外部省寄存器。
//  - FreeList_5    : 空闲槽分配器（72 槽，3 路分配 / 4 路释放，预分配）。
//  - AgeDetector_38: 入队先后年龄矩阵（24 entry，3 enq 口）。本队列 3 路重放各一个，
//                    每个负责「rem = port」的 24 个 entry（entry i 属于 rem i%3）。
//
//  端口宽度（golden）：AgeDetector io_enq/deq/ready/out = 24 位；FreeList io_free=72,
//  allocateSlot=7 位；LqVAddrModule raddr/waddr=7 位, rdata/wdata=50 位。

  // ---- 虚地址存储 ----
  LqVAddrModule vaddrModule (
    .clock      (clock),
    .reset      (reset),
    .io_ren_0   (va_ren[0]),
    .io_ren_1   (va_ren[1]),
    .io_ren_2   (va_ren[2]),
    .io_raddr_0 (va_raddr[0]),
    .io_raddr_1 (va_raddr[1]),
    .io_raddr_2 (va_raddr[2]),
    .io_rdata_0 (va_rdata[0]),
    .io_rdata_1 (va_rdata[1]),
    .io_rdata_2 (va_rdata[2]),
    .io_wen_0   (va_wen[0]),
    .io_wen_1   (va_wen[1]),
    .io_wen_2   (va_wen[2]),
    .io_waddr_0 (va_waddr[0]),
    .io_waddr_1 (va_waddr[1]),
    .io_waddr_2 (va_waddr[2]),
    .io_wdata_0 (va_wdata[0]),
    .io_wdata_1 (va_wdata[1]),
    .io_wdata_2 (va_wdata[2])
  );

  // ---- 空闲槽分配器 ----
  FreeList_5 freeList (
    .clock             (clock),
    .reset             (reset),
    .io_allocateSlot_0 (freeAllocSlot[0]),
    .io_allocateSlot_1 (freeAllocSlot[1]),
    .io_allocateSlot_2 (freeAllocSlot[2]),
    .io_canAllocate_0  (freeCanAllocate[0]),
    .io_canAllocate_1  (freeCanAllocate[1]),
    .io_canAllocate_2  (freeCanAllocate[2]),
    .io_doAllocate_0   (freeDoAllocate[0]),
    .io_doAllocate_1   (freeDoAllocate[1]),
    .io_doAllocate_2   (freeDoAllocate[2]),
    .io_free           (freeMaskVec),
    .io_empty          (freeEmpty)
  );

  // ---- 3 个年龄检测器（每路一个，处理 rem=port 的 24 个 entry）----
  AgeDetector_38 ageOldest_age (
    .clock    (clock), .reset (reset),
    .io_enq_0 (age_enq[0][0]), .io_enq_1 (age_enq[0][1]), .io_enq_2 (age_enq[0][2]),
    .io_deq   (age_deq[0]),    .io_ready (age_ready[0]),  .io_out   (age_out[0])
  );
  AgeDetector_38 ageOldest_age_1 (
    .clock    (clock), .reset (reset),
    .io_enq_0 (age_enq[1][0]), .io_enq_1 (age_enq[1][1]), .io_enq_2 (age_enq[1][2]),
    .io_deq   (age_deq[1]),    .io_ready (age_ready[1]),  .io_out   (age_out[1])
  );
  AgeDetector_38 ageOldest_age_2 (
    .clock    (clock), .reset (reset),
    .io_enq_0 (age_enq[2][0]), .io_enq_1 (age_enq[2][1]), .io_enq_2 (age_enq[2][2]),
    .io_deq   (age_deq[2]),    .io_ready (age_ready[2]),  .io_out   (age_out[2])
  );
