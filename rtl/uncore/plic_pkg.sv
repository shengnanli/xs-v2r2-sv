// =============================================================================
//  PLIC 类型/常量包 (plic_pkg)
// -----------------------------------------------------------------------------
//  PLIC (Platform-Level Interrupt Controller) 是 RISC-V 的平台级中断控制器，
//  挂在 TileLink 总线上，把众多外设中断按优先级仲裁后投递给各 hart。
//  本包目前服务于 PLICFanIn —— PLIC 内部的"优先级最大值/胜出设备"仲裁树。
//
//  PLICFanIn 语义 (源自 rocket-chip devices/tilelink/Plic.scala, class PLICFanIn)：
//    输入  io_prio[d]  : 设备 d 的可编程优先级 (prioBits 位)，d ∈ [0, nDevices)
//          io_ip[d]    : 设备 d 当前是否挂起 (pending & enable 后的 1 位)
//    输出  io_dev      : 胜出的设备号 (log2Ceil(nDevices+1) 位)；0 表示"无中断"
//          io_max      : 胜出设备的有效优先级低 prioBits 位 (= 真实优先级)
//
//  仲裁算法 (findMax 二叉锦标赛树)：
//    1) 每个设备的"有效优先级" effectivePriority[d] = {io_ip[d], io_prio[d]}
//       —— 把挂起位拼成最高位：任何已挂起设备(MSB=1)恒高于任何未挂起设备(MSB=0)。
//    2) 在设备序列最前面再插入一个常量 (1 << prioBits)，作为 0 号"占位设备"。
//       该常量 = 2^prioBits，恒大于所有未挂起设备(<2^prioBits)、恒小于任何已挂起
//       设备(≥2^prioBits)。于是当没有任何设备挂起时，占位设备胜出 ⇒ io_dev=0。
//    3) 对这 (nDevices+1) 个条目做分治求最大：findMax 取 half=1<<(log2Ceil(len)-1)，
//       左子树 = 前 half 个，右子树 = 其余；平局 (left>=right) 取左。胜出设备号在
//       右子树侧 OR 上 half，从而沿树路径拼出二进制设备号。
//    4) io_max 取胜出有效优先级低 prioBits 位 (剥掉恒为占位/挂起标志的高位)。
//
//  本实例参数 (对照 golden PLICFanIn.sv 端口)：
//    nDevices  = 65   (io_prio_0..io_prio_64 共 65 路，io_ip 为 65 位)
//    prioBits  = 3    (io_prio_* 为 3 位，io_max 为 3 位)
//    占位设备   : 条目 0，有效优先级 = 1<<3 = 4'h8
//    条目总数   = nDevices+1 = 66
//    io_dev 位宽 = log2Ceil(66) = 7
//  本核为纯组合叶子，无寄存器、无子模块、无 SRAM。
// =============================================================================
package plic_pkg;
  // ---- PLICFanIn 实例参数 ----
  localparam int PLIC_N_DEVICES = 65;                       // 真实设备数
  localparam int PLIC_PRIO_BITS = 3;                        // 优先级位宽
  localparam int PLIC_DEV_BITS   = 7;                       // = log2Ceil(nDevices+1)
  localparam int PLIC_LEAVES    = PLIC_N_DEVICES + 1;       // 含占位设备的条目数 = 66

  // 有效优先级位宽 = 挂起位(1) + 优先级位宽。占位常量 = 1<<prioBits 恰好需要这么多位。
  localparam int PLIC_EP_BITS   = PLIC_PRIO_BITS + 1;       // = 4

  // 0 号占位设备的有效优先级常量 = 1 << prioBits
  localparam logic [PLIC_EP_BITS-1:0] PLIC_PLACEHOLDER_EP =
    (PLIC_EP_BITS'(1) << PLIC_PRIO_BITS);
endpackage
