// =============================================================================
//  PLICFanIn —— PLIC 优先级仲裁树 (可读重写核 xs_PLICFanIn_core)
// -----------------------------------------------------------------------------
//  功能 (源自 rocket-chip devices/tilelink/Plic.scala，class PLICFanIn)：
//    在 nDevices(=65) 路外设中断里，按"有效优先级 = {挂起位, 优先级}"选出最大者，
//    输出胜出设备号 io_dev (0=无中断) 与其优先级 io_max。详见 plic_pkg.sv 注释。
//
//  实现方式：把 (nDevices+1) 个有效优先级条目放进一个打包数组 ep[]，
//    ep[0]            = 占位常量 (1<<prioBits)，对应设备号 0 (无中断)；
//    ep[1+d]          = {io_ip[d], io_prio[d]}，对应设备号 1+d；
//  然后用与 Chisel findMax 完全一致的分治 (half = 1<<(clog2(len)-1)，平局取左)
//  递归求最大，沿途在右子树侧把 half 拼进设备号。
//
//  关键对照点 (与 golden 严格一致)：
//    * 平局判据用 ">=" (左优先)，确保设备号小者在同优先级下胜出；
//    * 设备号编码：findMax 右半返回值 = half | right_dev，即沿"取右"的路径累积；
//    * io_max 取胜出有效优先级低 prioBits 位 (高位是恒定的占位/挂起标志)。
//
//  本核为纯组合叶子，无寄存器、无子模块、无 SRAM。
// =============================================================================
module xs_PLICFanIn_core
  import plic_pkg::*;
(
  // 65 路设备优先级 (每路 prioBits=3 位)。打包成数组便于树式归约。
  input  logic [PLIC_N_DEVICES-1:0][PLIC_PRIO_BITS-1:0] io_prio,
  // 65 位挂起向量 (已与 enable 按位与过)，io_ip[d] = 设备 d 是否挂起
  input  logic [PLIC_N_DEVICES-1:0]                     io_ip,
  // 胜出设备号 (7 位)；0 表示无中断
  output logic [PLIC_DEV_BITS-1:0]                      io_dev,
  // 胜出设备优先级 (3 位)
  output logic [PLIC_PRIO_BITS-1:0]                     io_max
);

  // ===========================================================================
  //  findMax 返回类型：一对 (有效优先级, 设备号)
  // ===========================================================================
  typedef struct packed {
    logic [PLIC_EP_BITS-1:0]  pri;  // 有效优先级 = {挂起位, 优先级}
    logic [PLIC_DEV_BITS-1:0] dev;  // 设备号
  } maxpair_t;

  // ===========================================================================
  //  有效优先级数组 ep[0..LEAVES-1]
  //    ep[0]   = 占位常量 (1<<prioBits)，设备 0 (无中断)
  //    ep[1+d] = {io_ip[d], io_prio[d]}，设备 1+d
  // ===========================================================================
  logic [PLIC_LEAVES-1:0][PLIC_EP_BITS-1:0] ep;
  always_comb begin
    ep[0] = PLIC_PLACEHOLDER_EP;
    for (int d = 0; d < PLIC_N_DEVICES; d++)
      ep[d+1] = {io_ip[d], io_prio[d]};
  end

  // ===========================================================================
  //  find_max(arr, lo, len)：对 arr[lo +: len] 求 (最大有效优先级, 相对 0 的设备号)
  // ---------------------------------------------------------------------------
  //  与 Chisel findMax 完全同构：
  //    len==1 时 (head, 0)；
  //    否则 half = 1<<(clog2(len)-1)，
  //         left  = find_max(lo,        half)，
  //         right = find_max(lo+half,   len-half)，
  //         平局(left.pri>=right.pri)取左，否则取右且设备号 OR 上 half。
  //  设备号在递归回溯中沿"取右"路径累积二进制位，根调用返回的即全局设备号。
  //  注意：整个 ep 数组作为入参显式传入 (纯函数、不读非局部信号)，以便综合/形式
  //  工具把递归当组合逻辑展开，避免 RTL 解释告警。
  // ===========================================================================
  function automatic maxpair_t find_max(
      input logic [PLIC_LEAVES-1:0][PLIC_EP_BITS-1:0] arr,
      input int lo, input int len);
    maxpair_t res, left, right;
    int half;
    if (len <= 1) begin
      res.pri = arr[lo];
      res.dev = '0;
    end else begin
      half  = 1 << ($clog2(len) - 1);
      left  = find_max(arr, lo,        half);
      right = find_max(arr, lo + half, len - half);
      if (left.pri >= right.pri) begin
        res = left;
      end else begin
        res.pri = right.pri;
        res.dev = PLIC_DEV_BITS'(half) | right.dev;  // 取右：拼入 half 位
      end
    end
    return res;
  endfunction

  // ===========================================================================
  //  输出：对全部 LEAVES 个条目求最大
  // ===========================================================================
  maxpair_t winner;
  always_comb winner = find_max(ep, 0, PLIC_LEAVES);

  assign io_dev = winner.dev;
  assign io_max = winner.pri[PLIC_PRIO_BITS-1:0];  // 剥掉高位挂起/占位标志

endmodule
