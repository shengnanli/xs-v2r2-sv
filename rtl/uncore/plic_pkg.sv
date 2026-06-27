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

  // ===========================================================================
  //  TLPLIC 顶层实例参数 (对照 golden TLPLIC.sv 端口)
  // ---------------------------------------------------------------------------
  //  本实例: nDevices=65, nHarts=2, nPriorities=7 (prioBits=3)。
  //  设备号 1..65 对应中断源, 0 号保留(无中断)。device d (0-based, 0..64) 的
  //  挂起/优先级寄存器对应中断号 d+1。
  //
  //  TileLink 寄存器地址映射 (字节地址, 每寄存器 32 位, PLIC 标准布局):
  //    priorityBase 0x0000 : 中断源优先级, 源 i 在 0x4*i (源 0 保留 ⇒ 从 0x4 起)
  //    pendingBase  0x1000 : 挂起位数组 (只读), 1 bit/源
  //    enableBase   0x2000 : 每 hart 一组使能位; hart i 基址 0x2000 + i*0x80
  //    hartBase     0x200000: 每 hart 的 {threshold, claim/complete}; hart i 基址
  //                          0x200000 + i*0x1000
  //  firtool 把字节地址压成 8 字节字索引 index=addr[25:3] (23 位), 再压成 9 位
  //  oindex = {index[18], index[10:9], index[5:0]} 做寄存器选择 (见 TLPLIC.sv)。
  // ===========================================================================
  localparam int PLIC_N_HARTS = 2;                          // hart 数

  // 使能寄存器分块: firstEnable = min(nDevices,7)=7, 之后每 8 个一块。
  //   65 = 7 + 8*7 + 2 ⇒ 9 块: [7,8,8,8,8,8,8,8,2] (每 hart)
  localparam int PLIC_EN_CHUNKS  = 9;
endpackage
