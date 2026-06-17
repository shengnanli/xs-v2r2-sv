// =============================================================================
// regcache_pkg —— 香山 V2R2(昆明湖) 寄存器缓存 RegCache 的参数与类型定义
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/regcache/RegCache.scala 及其子模块
//   (RegCacheDataModule / RegCacheAgeTimer / RegCacheAgeDetector)。
//
// 背景(RegCache 是什么、为什么要它):
//   超标量乱序处理器每拍要为多条指令读多个源操作数,物理寄存器堆(PRF)读口
//   是面积/时序大头。香山观察到「刚写回的值很快又被后续指令读用」,于是在 PRF
//   之外加一个小容量、多读口的「寄存器缓存」RegCache,缓存最近写回的物理寄存器值。
//   发射时若操作数命中 RegCache,就从这里读,省掉一次 PRF 读口占用。
//
//   RegCache 分成两个对称半区:IntRegCache(整数域)与 MemRegCache(访存域),
//   各 16 条目。读地址(RegCacheIdx)是 5 位,最高位选半区、低 4 位选条目。
//   写入采用「年龄替换」:AgeTimer 记录各条目的相对新旧,AgeDetector 挑出最旧
//   条目作为下次写入的替换目标(其下标经 3 拍流水回送给唤醒队列与写口)。
// =============================================================================
package regcache_pkg;

  // ---- 规模参数(由 BackendParams 推导,这里取昆明湖实例值)----
  //   注意 Int/Mem 两半区条目数不同:整数域 16,访存域 12(访存 RC 命中需求较少)。
  localparam int INT_SIZE  = 16;  // Int 半区条目数(IntRegCacheSize)
  localparam int MEM_SIZE  = 12;  // Mem 半区条目数(MemRegCacheSize)
  localparam int ADDR_W    = 4;   // 半区内条目地址位宽(两半区都用 4 位,Mem 高位不用满)
  localparam int IDX_W     = 5;   // 完整 RegCacheIdx:最高位选半区 + 低 4 位选条目
  localparam int DATA_W    = 64;  // 寄存器数据位宽(rfDataWidth)

  localparam int N_READ    = 23;  // 读口数(IntExu + MemExu 的 RC 读口之和)
  localparam int INT_WR    = 4;   // Int 半区写口数(getIntExuRCWriteSize)
  localparam int MEM_WR    = 3;   // Mem 半区写口数(getMemExuRCWriteSize)
  localparam int N_WRITE   = INT_WR + MEM_WR;  // 总写口/唤醒回送数 = 7

  // 读流水深度:RegEnable(addr)/GatedValidRegNext(ren) 各打 1 拍 -> 子模块。
  localparam int READ_DELAY  = 1;
  // 替换下标回送写口的流水深度:RegNextN(toWakeupRCIdx, 3)。
  localparam int RCIDX_DELAY = 3;

  // AgeTimer 输出的年龄信息:N 条目两两配对的上三角矩阵 C(N,2) 条。
  localparam int INT_AGE_PAIRS = (INT_SIZE * (INT_SIZE - 1)) / 2;  // = 120
  localparam int MEM_AGE_PAIRS = (MEM_SIZE * (MEM_SIZE - 1)) / 2;  // = 66

endpackage : regcache_pkg
