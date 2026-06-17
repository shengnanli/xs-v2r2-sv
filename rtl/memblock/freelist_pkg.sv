// =====================================================================
// freelist_pkg —— 访存(MemBlock)队列「空闲槽位表」FreeList 的参数/类型
// ---------------------------------------------------------------------
// 该 FreeList 给 Load/Store 队列(如 LoadQueueRAW)分配【条目槽位号】(slot)，
// 而非物理寄存器。它是一个循环队列：
//   - headPtr 出队端：分配时给出 allocateSlot；
//   - tailPtr 入队端：释放(free)时把槽位号压回；
//   - freeList[] 存放当前空闲的槽位号。
// 释放接口是一个 size 位的位图 io_free(每位代表某条目本拍被释放)，
// 内部用「bank 优先编码」每拍最多回收 freeWidth 个，并打一拍写回 freeList。
// 文档见 docs/memblock/FreeList.md。
// =====================================================================
package freelist_pkg;

  // 本 golden 例化参数(对应 LoadQueueRAW 用法：size=16, 双口分配/释放)
  localparam int SIZE        = 16;          // 队列容量(槽位数)
  localparam int ALLOC_WIDTH = 2;           // 每拍分配口数
  localparam int FREE_WIDTH  = 2;           // 每拍最多回收槽位数(bank 数)
  localparam int IDX_W       = $clog2(SIZE);// 槽位号位宽 = 4
  localparam int CNT_W       = $clog2(SIZE+1); // 计数位宽 = 5

  // 循环队列指针：flag 区分绕圈，value 是池内下标。SIZE=16 为 2 的幂，
  // 直接用 {flag,value} 自然溢出即可回绕(无需手动判界)。
  typedef struct packed {
    logic             flag;
    logic [IDX_W-1:0] value;
  } fl_ptr_t;

  // 指针 + 偏移(SIZE 为 2 幂，拼接后加法自然回绕)
  function automatic fl_ptr_t ptr_add(input fl_ptr_t p, input logic [IDX_W:0] v);
    logic [IDX_W:0] sum;
    fl_ptr_t        r;
    begin
      sum = {p.flag, p.value} + v;
      r.flag  = sum[IDX_W];
      r.value = sum[IDX_W-1:0];
      return r;
    end
  endfunction

endpackage
