// =====================================================================
// mefreelist_pkg —— 重命名「Move-Elimination 空闲列表」(MEFreeList) 的类型与参数
// ---------------------------------------------------------------------
// MEFreeList 管理【整数】物理寄存器的空闲池。它和 StdFreeList 一样是一个
// 支持「投机执行 + 回滚」的循环队列空闲表，但服务于支持 move-elimination
// 的整数寄存器：
//   - headPtr     指向下一个可【分配】的空闲物理寄存器(出队端，投机态)；
//   - archHeadPtr 是【体系结构态】的 head，仅在 commit 时推进；
//   - tailPtr     指向下一个【回收】物理寄存器的写入位置(入队端)；
//   - freeList[]  数组存放当前空闲的物理寄存器号。
//
// 与 StdFreeList 的关键差异(都继承同一 BaseFreeList，分配/回退主逻辑相同)：
//   1. freeList 初值：x0..x31 都映射到物理寄存器 0；因此初始时物理寄存器
//      {1,2,...,size-1} 都空闲，0 号被占用(给 x0)。golden 初值为
//      freeList[i] = i+1 (i < size-1)，freeList[size-1] = 0。
//   2. tailPtr 初值 = FreeListPtr(flag=0, value=size-1)：尾指针落在最后一格
//      (此处存的就是 0 号)，因此初始空闲数 = distance(tailPtr, headPtr) = size-1。
//   3. archHeadPtr 推进条件用 rfWen && !isMove(move-elimination：被消除的
//      move 指令不真正占用新物理寄存器，故不推进体系结构 head)。
//   4. 本核直接用 tailPtr(组合算 tailPtrNext)，回收写入用【当前】tailPtr，
//      空闲计数 freeRegCnt 用【下一拍】tailPtrNext —— 这点与 StdFreeList
//      的 lastTailPtr 写法不同(MEFreeList golden 即如此)。
//
// 文档见 docs/backend/MEFreeList.md。
// =====================================================================
package mefreelist_pkg;

  // ---- MEFreeList 例化对应整数物理寄存器空闲池 ----
  // IntPhyRegs = 224 → size = 224(注意：整数池 size 直接给 224，不减逻辑寄存器；
  // 0 号被 x0 永久占用，靠 freeList 初值把 0 放到尾格表达"已用"语义)。
  localparam int SIZE          = 224;  // 空闲池容量(循环队列条目数, 非 2 的幂)
  localparam int PHYREG_W      = 8;    // 物理寄存器号位宽 PhyRegIdxWidth
  localparam int RENAME_WIDTH  = 6;    // 每拍重命名(分配)口数
  localparam int COMMIT_WIDTH  = 6;    // 每拍提交/回滚(回收)口数 RabCommitWidth
  localparam int SNAPSHOT_NUM  = 4;    // 快照个数 RenameSnapshotNum

  localparam int PTR_W   = $clog2(SIZE);      // 指针 value 位宽 = 8
  localparam int CNT_W   = $clog2(SIZE + 1);  // 空闲计数位宽 = 8

  // ---- 循环队列指针：flag 区分"绕过几圈"，value 是池内下标 ----
  // 由于 SIZE 非 2 的幂，加法需要手动检测越界回绕(见 ptr_add 函数)。
  typedef struct packed {
    logic               flag;
    logic [PTR_W-1:0]   value;
  } fl_ptr_t;

  // 指针 + 偏移(循环加)。对应 CircularQueuePtr.`+`(非 2 幂分支)：
  //   new_value = value + v；若 new_value >= SIZE 则回绕并翻转 flag。
  function automatic fl_ptr_t ptr_add(input fl_ptr_t p, input logic [PTR_W:0] v);
    logic [PTR_W:0]   new_value;  // value +& v，多 1 bit 防溢出
    logic signed [PTR_W+2:0] diff;
    fl_ptr_t          r;
    begin
      new_value = {1'b0, p.value} + v;
      diff      = $signed({1'b0, new_value}) - $signed((PTR_W+3)'(SIZE));
      if (diff >= 0) begin           // 越过池尾 → 回绕，翻转 flag
        r.flag  = ~p.flag;
        r.value = diff[PTR_W-1:0];
      end else begin
        r.flag  = p.flag;
        r.value = new_value[PTR_W-1:0];
      end
      return r;
    end
  endfunction

  // 两指针距离：enq 与 deq 之间的有效条目数(circular)。
  function automatic logic [CNT_W-1:0] distance(input fl_ptr_t enq, input fl_ptr_t deq);
    begin
      if (enq.flag == deq.flag)
        return CNT_W'(enq.value - deq.value);
      else
        return CNT_W'((PTR_W+1)'(SIZE) + enq.value - deq.value);
    end
  endfunction

endpackage
