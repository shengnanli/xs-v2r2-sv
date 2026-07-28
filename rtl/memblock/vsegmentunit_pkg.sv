// xs_vsegmentunit_pkg —— VSegmentUnit 可读核参数/状态编码。
// 手写重写, bug-for-bug 对齐 golden VSegmentUnit.sv(firtool-1.62.1)。
package xs_vsegmentunit_pkg;
  // 状态机编码(golden state[3:0])。golden 用裸 4'hN, 这里给可读名。
  localparam logic [3:0] S_IDLE      = 4'h0; // 空闲
  localparam logic [3:0] S_FLUSH     = 4'h1; // 冲刷 sbuffer
  localparam logic [3:0] S_FIRST     = 4'h2; // 首次准备
  localparam logic [3:0] S_TLB_REQ   = 4'h3; // 发 dtlb 请求
  localparam logic [3:0] S_TLB_RESP  = 4'h4; // 等 dtlb 响应
  localparam logic [3:0] S_PMP       = 4'h5; // pmp/异常检查
  localparam logic [3:0] S_CACHE_REQ = 4'h6; // 发 dcache 读请求(load)
  localparam logic [3:0] S_CACHE_RESP= 4'h7; // 等 dcache 响应
  localparam logic [3:0] S_MISALIGN  = 4'h8; // 非对齐第二拍合并
  localparam logic [3:0] S_LD_FINISH = 4'h9; // load 段完成
  localparam logic [3:0] S_ST_FINISH = 4'hA; // store 段完成(发 sbuffer)
  localparam logic [3:0] S_LAT       = 4'hB; // 等 pipeline 尾
  localparam logic [3:0] S_WB        = 4'hC; // 写回/异常上报
  localparam logic [3:0] S_FOF       = 4'hD; // fof fixVl
endpackage
