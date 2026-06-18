// =============================================================================
// bypassnetwork_pkg —— 香山 V2R2(昆明湖) 旁路网络公共类型/参数 (可读重写)
// -----------------------------------------------------------------------------
// 设计源:src/main/scala/xiangshan/backend/datapath/{BypassNetwork,DataSource}.scala
//
// 旁路网络(BypassNetwork)位于后端「读寄存器(DataPath)」与「执行单元(ExuBlock)」
// 之间。发射队列(IssueQueue)在唤醒阶段已经决定:某条 uop 的某个源操作数将来自
// 哪个执行单元(EXU)的在飞结果,以及该结果应取「本拍直出(forward)」还是「下一拍
// 寄存后(bypass)」。DataPath 把这一决策编码进每个源操作数的 dataSources.value
// (本包的 data_source_e)与 exuSources.value(产出该操作数的旁路源 EXU 在唤醒源
// 组内的序号)。BypassNetwork 据此把对应 EXU 的结果路由到该源操作数,省去一次写回
// 物理寄存器堆再读回的往返,缩短 RAW 关键路径。
//
// 本包定义:
//   1. data_source_e —— 源操作数的 8 种数据来源编码(与 Scala object DataSource 对齐)。
//   2. 旁路源(forward source)拓扑参数 —— 本配置下哪些 EXU 是旁路源、各自的全局位号。
//   3. 立即数类型常量(与 ImmExtractor 黑盒里的 immType 比较常量对齐)。
// =============================================================================
package bypassnetwork_pkg;

  // ---------------------------------------------------------------------------
  // 1. 数据来源编码 data_source_e (4 bit, 见 Scala object DataSource)
  // ---------------------------------------------------------------------------
  // IssueQueue 唤醒/选择时为每个源操作数定下唯一来源,DataPath 透传给本网络。
  //   ZERO     : 读 int 0 号物理寄存器,恒 0(整数零寄存器优化)。
  //   FORWARD  : 取旁路源 EXU 本拍直出的结果(同拍前递,延迟最低)。
  //   BYPASS   : 取旁路源 EXU 上一拍结果(寄存一拍后),用于晚一拍才需要的源。
  //   BYPASS2  : 二级旁路(VF/Load 向量域),本配置未接通,见模块注释。
  //   IMM      : 取立即数(经 ImmExtractor 按 immType 扩展)。
  //   V0       : 取向量 v0 掩码寄存器(向量源专用)。
  //   REGCACHE : 取寄存器缓存(RegCache)读出的数据。
  //   REG      : 取物理寄存器堆正常读出的数据(value 的最高位为 1 即「读寄存器」)。
  typedef enum logic [3:0] {
    DS_ZERO     = 4'b0000,
    DS_FORWARD  = 4'b0001,
    DS_BYPASS   = 4'b0010,
    DS_BYPASS2  = 4'b0011,
    DS_IMM      = 4'b0100,
    DS_V0       = 4'b0101,
    DS_REGCACHE = 4'b0110,
    DS_REG      = 4'b1000
  } data_source_e;

  // ---------------------------------------------------------------------------
  // 2. 旁路源拓扑(本 BackendParams 配置固定推导而来)
  // ---------------------------------------------------------------------------
  // 全 27 个 EXU 里,只有「整数 4 路 + 浮点 3 路 + 访存 3 路(mem2/3/4)」共 10 路是
  // IQ 唤醒旁路源(会把结果旁路出去)。它们在 27 位全局 one-hot 空间里的位号固定。
  //
  // 但消费侧分两组、各自只监听其中一个子集:
  //   * 整数/访存 消费者 → 监听「整数 4 + 访存 3」共 7 路 (INT_FWD_SRC)。
  //   * 浮点     消费者 → 监听「浮点 3」共 3 路 (FP_FWD_SRC)。
  // exuSources.value 就是「该源操作数的旁路源在本组内的序号(从 1 起;0 表示无效)」,
  // 于是「旁路匹配」退化为一次按 exuSources.value 的选择(见 core 的 sel_fwd/sel_byp)。
  localparam int INT_FWD_NUM = 7;  // int0..3 + mem2..4
  localparam int FP_FWD_NUM  = 3;  // fp0..2

  localparam int XLEN  = 64;    // 标量数据位宽
  localparam int VLEN  = 128;   // 向量数据位宽(vf 源)

  // ---------------------------------------------------------------------------
  // 旁路源在飞结果 bundle(对应 Scala ExuBypassBundle 里本网络关心的字段)
  // ---------------------------------------------------------------------------
  // 每个旁路源 EXU 每拍给出:是否有效(valid)、结果数据(data)、是否写整数寄存器
  // (int_wen,决定该结果是否需要回写 RegCache)。把三者聚合成结构体,数组化后
  // 便于按 exuSources 序号统一索引,也作为「bypass 寄存一拍」的载体。
  typedef struct packed {
    logic            valid;
    logic            int_wen;
    logic [XLEN-1:0] data;
  } bypass_src_t;

  // ---------------------------------------------------------------------------
  // 3. 立即数类型常量(与 ImmExtractor 黑盒内部 immType 比较一致,仅供文档参考)
  // ---------------------------------------------------------------------------
  // ImmExtractor 作黑盒,这里不做立即数扩展;列出常量便于阅读源旁的 immType 语义。
  localparam logic [3:0] IMM_U   = 4'h2;  // U 型(高 20 位)
  localparam logic [3:0] IMM_I   = 4'h4;  // I 型(12 位符号扩展)
  localparam logic [3:0] IMM_LUI = 4'hB;  // LUI32

endpackage
