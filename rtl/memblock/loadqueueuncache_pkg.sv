// =============================================================================
//  loadqueueuncache_pkg —— LoadQueueUncache 可读重写用类型/常量/纯函数
// -----------------------------------------------------------------------------
//  设计意图来源：xiangshan/mem/lsqueue/LoadQueueUncache.scala。
//
//  LoadQueueUncache 是 LoadQueue 里处理不可缓存 load 的小型入口队列。顶层负责：
//    1. 将 LoadUnit S3 的 3 路 mmio/nc load 按 ROB 年龄排序；
//    2. 通过 4 项 freelist 分配 UncacheEntry 槽；
//    3. 在 4 个槽和外部 Uncache 单元之间做 MMIO 优先 / NC RR 仲裁；
//    4. 如果槽满导致请求无法入队，选择最老 load 触发 rollback 重执行。
//
//  每个槽内部的 s_idle/s_req/s_resp/s_wait 状态机保留为 golden UncacheEntry 黑盒，
//  本包只描述顶层控制/路由需要的扁平 bundle 子集。
// =============================================================================
package loadqueueuncache_pkg;

  localparam int LOAD_PIPE_W = 3;
  localparam int ENTRY_NUM   = 4;
  localparam int ENTRY_IDX_W = 2;
  localparam int ROB_IDX_W   = 8;
  localparam int FTQ_IDX_W   = 6;
  localparam int PADDR_W     = 48;
  localparam int VADDR_W     = 50;
  localparam int XLEN        = 64;

`include "loadqueueuncache_structs.svh"

  typedef struct packed {
    logic flag;
    logic [ROB_IDX_W-1:0] value;
  } lqu_robidx_t;

  typedef struct packed {
    logic valid;
    logic isRVC;
    lqu_robidx_t robIdx;
    logic ftq_flag;
    logic [FTQ_IDX_W-1:0] ftq_value;
    logic [3:0] ftqOffset;
    logic level;
  } lqu_redirect_t;

  typedef enum logic [1:0] {
    REQ_FROM_NONE = 2'd0,
    REQ_FROM_MMIO = 2'd1,
    REQ_FROM_NC   = 2'd2
  } lqu_req_source_e;

  // robIdx.needFlush(redirect) 的 SV 版本。香山 ROB 指针是 {flag,value} 环形指针：
  // 同圈 value 大者更新，异圈 value 小者更新；当 value 相等且 flag 不同时，golden 的
  // differentFlag ^ (value > red.value) 判作 after，这一点对 rollback 过滤很关键。
  function automatic logic rob_need_flush(input logic rf, input logic [ROB_IDX_W-1:0] rv,
                                          input logic red_valid, input logic red_flag,
                                          input logic [ROB_IDX_W-1:0] red_value,
                                          input logic red_level);
    logic different_flag;
    logic is_after;
    logic same_entry;
    different_flag = rf ^ red_flag;
    is_after       = different_flag ^ (rv > red_value);
    same_entry     = (rf == red_flag) & (rv == red_value);
    return red_valid & ((red_level & same_entry) | is_after);
  endfunction

  function automatic logic rob_is_after(input lqu_robidx_t a, input lqu_robidx_t b);
    return (a.flag ^ b.flag) ^ (a.value > b.value);
  endfunction

  function automatic logic rob_is_before(input lqu_robidx_t a, input lqu_robidx_t b);
    return (a.flag ^ b.flag) ^ (a.value < b.value);
  endfunction

  function automatic lqu_robidx_t req_robidx(input lqu_req_t r);
    lqu_robidx_t p;
    p.flag  = r.uop_robIdx_flag;
    p.value = r.uop_robIdx_value;
    return p;
  endfunction

  function automatic logic has_load_exception(input lqu_req_t r);
    return r.uop_exceptionVec_21 | r.uop_exceptionVec_19 | r.uop_exceptionVec_13
         | r.uop_exceptionVec_5  | r.uop_exceptionVec_4  | r.uop_exceptionVec_3;
  endfunction

  function automatic logic need_replay(input lqu_req_t r);
    return r.rep_info_cause_10 | r.rep_info_cause_9 | r.rep_info_cause_8
         | r.rep_info_cause_7  | r.rep_info_cause_6 | r.rep_info_cause_5
         | r.rep_info_cause_4  | r.rep_info_cause_3 | r.rep_info_cause_2
         | r.rep_info_cause_1  | r.rep_info_cause_0;
  endfunction

  function automatic logic known_one(input logic v);
    return v;
  endfunction

  function automatic logic alloc_can_by_offset(input logic [2:0] can_vec,
                                               input logic [1:0] offset);
    // golden 构造的是 {can0, can2, can1, can0}[offset]。用三元 mux 而不是
    // case/数组索引，保留 offset 为 X 时的按位收敛语义。
    return offset[1]
      ? (offset[0] ? can_vec[0] : can_vec[2])
      : (offset[0] ? can_vec[1] : can_vec[0]);
  endfunction

  function automatic logic [ENTRY_IDX_W-1:0] alloc_slot_by_offset(
      input logic [ENTRY_IDX_W-1:0] slot0,
      input logic [ENTRY_IDX_W-1:0] slot1,
      input logic [ENTRY_IDX_W-1:0] slot2,
      input logic [1:0] offset);
    // golden 构造的是 {slot0, slot2, slot1, slot0}[offset]。
    return offset[1]
      ? (offset[0] ? slot0 : slot2)
      : (offset[0] ? slot1 : slot0);
  endfunction

  function automatic lqu_unc_req_t zero_unc_req();
    lqu_unc_req_t r;
    r = '0;
    return r;
  endfunction

  function automatic lqu_mmio_out_t zero_mmio_out();
    lqu_mmio_out_t r;
    r = '0;
    return r;
  endfunction

  function automatic lqu_nc_out_t zero_nc_out();
    lqu_nc_out_t r;
    r = '0;
    return r;
  endfunction

  function automatic lqu_exception_t zero_exception();
    lqu_exception_t r;
    r = '0;
    return r;
  endfunction

endpackage
