// =====================================================================
// stdfreelist_pkg —— 重命名「标准空闲列表」(StdFreeList) 的类型与参数
// ---------------------------------------------------------------------
// StdFreeList 管理一类物理寄存器(浮点/向量)的空闲池。它本质是一个
// 「循环队列」：
//   - headPtr 指向下一个可【分配】的空闲物理寄存器(出队端)；
//   - tailPtr 指向下一个【回收】物理寄存器的写入位置(入队端)；
//   - freeList[] 数组存放当前空闲的物理寄存器号。
// 与普通队列不同处在于它要支持「投机执行 + 回滚(walk/redirect)」：
//   - archHeadPtr 是【体系结构态】的 head，仅在 commit 时推进，
//     代表"真正用掉、不会再回退"的分配进度；
//   - 当分支预测错误(redirect)发生时，head 需要回退到某个快照(snapshot)
//     或回退到 archHeadPtr，再按 walk 重新分配。
// 文档见 docs/backend/StdFreeList.md。
// =====================================================================
package stdfreelist_pkg;

  // ---- 该 golden 例化对应「浮点 StdFreeList」(regType = Reg_F) ----
  // FpPhyRegs=192, FpLogicRegs=34 → freeListSize = 192-34 = 158。
  localparam int SIZE          = 158;  // 空闲池容量(循环队列条目数, 非 2 的幂)
  localparam int NUM_LOGIC_REGS= 34;   // 逻辑寄存器数：freeList 初值 = i + NUM_LOGIC_REGS
  localparam int PHYREG_W      = 8;    // 物理寄存器号位宽 PhyRegIdxWidth
  localparam int RENAME_WIDTH  = 6;    // 每拍重命名(分配)口数
  localparam int COMMIT_WIDTH  = 6;    // 每拍提交/回滚(回收)口数 RabCommitWidth
  localparam int SNAPSHOT_NUM  = 4;    // 快照个数 RenameSnapshotNum

  localparam int PTR_W   = $clog2(SIZE);      // 指针 value 位宽 = 8
  localparam int CNT_W   = $clog2(SIZE + 1);  // 空闲计数位宽

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
