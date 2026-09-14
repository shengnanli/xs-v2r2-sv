// =============================================================================
//  PLICFanIn —— PLIC 优先级仲裁树 (可读重写核 xs_PLICFanIn_core)
// -----------------------------------------------------------------------------
//  功能 (源自 rocket-chip devices/tilelink/Plic.scala，class PLICFanIn)：
//    在 nDevices(=65) 路外设中断里，按"有效优先级 = {挂起位, 优先级}"选出最大者，
//    输出胜出设备号 io_dev (0=无中断) 与其优先级 io_max。详见 rtl/uncore/uncore_common_pkg.sv
//    里的 plic_pkg 注释（TLPLIC 也用该包，故住在 uncore 公共包文件）。
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
  import plic_pkg::*;   // 共享包，见 rtl/uncore/uncore_common_pkg.sv
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

// 自动生成：xs-v2r2-sv/scripts/gen_plicfanin.py —— 该脚本未移植到本轮(它按上一轮规范产出独立 _wrapper.sv)，本文件手工维护

// ---------------------------------------------------------------------------
// golden 同名 wrapper
// ---------------------------------------------------------------------------

module PLICFanIn(
  input [2:0] io_prio_0,
  input [2:0] io_prio_1,
  input [2:0] io_prio_2,
  input [2:0] io_prio_3,
  input [2:0] io_prio_4,
  input [2:0] io_prio_5,
  input [2:0] io_prio_6,
  input [2:0] io_prio_7,
  input [2:0] io_prio_8,
  input [2:0] io_prio_9,
  input [2:0] io_prio_10,
  input [2:0] io_prio_11,
  input [2:0] io_prio_12,
  input [2:0] io_prio_13,
  input [2:0] io_prio_14,
  input [2:0] io_prio_15,
  input [2:0] io_prio_16,
  input [2:0] io_prio_17,
  input [2:0] io_prio_18,
  input [2:0] io_prio_19,
  input [2:0] io_prio_20,
  input [2:0] io_prio_21,
  input [2:0] io_prio_22,
  input [2:0] io_prio_23,
  input [2:0] io_prio_24,
  input [2:0] io_prio_25,
  input [2:0] io_prio_26,
  input [2:0] io_prio_27,
  input [2:0] io_prio_28,
  input [2:0] io_prio_29,
  input [2:0] io_prio_30,
  input [2:0] io_prio_31,
  input [2:0] io_prio_32,
  input [2:0] io_prio_33,
  input [2:0] io_prio_34,
  input [2:0] io_prio_35,
  input [2:0] io_prio_36,
  input [2:0] io_prio_37,
  input [2:0] io_prio_38,
  input [2:0] io_prio_39,
  input [2:0] io_prio_40,
  input [2:0] io_prio_41,
  input [2:0] io_prio_42,
  input [2:0] io_prio_43,
  input [2:0] io_prio_44,
  input [2:0] io_prio_45,
  input [2:0] io_prio_46,
  input [2:0] io_prio_47,
  input [2:0] io_prio_48,
  input [2:0] io_prio_49,
  input [2:0] io_prio_50,
  input [2:0] io_prio_51,
  input [2:0] io_prio_52,
  input [2:0] io_prio_53,
  input [2:0] io_prio_54,
  input [2:0] io_prio_55,
  input [2:0] io_prio_56,
  input [2:0] io_prio_57,
  input [2:0] io_prio_58,
  input [2:0] io_prio_59,
  input [2:0] io_prio_60,
  input [2:0] io_prio_61,
  input [2:0] io_prio_62,
  input [2:0] io_prio_63,
  input [2:0] io_prio_64,
  input [64:0] io_ip,
  output [6:0] io_dev,
  output [2:0] io_max
);
  // 把 65 路扁平 io_prio_d 拼成打包数组 (高索引在前)，喂给可读核
  logic [64:0][2:0] prio_packed;
  assign prio_packed = {io_prio_64, io_prio_63, io_prio_62, io_prio_61, io_prio_60, io_prio_59, io_prio_58, io_prio_57, io_prio_56, io_prio_55, io_prio_54, io_prio_53, io_prio_52, io_prio_51, io_prio_50, io_prio_49, io_prio_48, io_prio_47, io_prio_46, io_prio_45, io_prio_44, io_prio_43, io_prio_42, io_prio_41, io_prio_40, io_prio_39, io_prio_38, io_prio_37, io_prio_36, io_prio_35, io_prio_34, io_prio_33, io_prio_32, io_prio_31, io_prio_30, io_prio_29, io_prio_28, io_prio_27, io_prio_26, io_prio_25, io_prio_24, io_prio_23, io_prio_22, io_prio_21, io_prio_20, io_prio_19, io_prio_18, io_prio_17, io_prio_16, io_prio_15, io_prio_14, io_prio_13, io_prio_12, io_prio_11, io_prio_10, io_prio_9, io_prio_8, io_prio_7, io_prio_6, io_prio_5, io_prio_4, io_prio_3, io_prio_2, io_prio_1, io_prio_0};

  xs_PLICFanIn_core u_core (
    .io_prio (prio_packed),
    .io_ip   (io_ip),
    .io_dev  (io_dev),
    .io_max  (io_max)
  );
endmodule
