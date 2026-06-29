// =============================================================================
//  axi4xbar_pkg —— AXI4Xbar (2 主 × 2 从 大 AXI4 交叉开关) 常量与工具函数
// -----------------------------------------------------------------------------
//  对应 rocket-chip 的 AXI4Xbar (src/main/scala/amba/axi4/Xbar.scala)。本变体是香山
//  SoC 顶层把"两个上游 AXI 主口"(L3/外设侧) 路由到"两个下游从口"的交叉开关:
//
//    主口 in_0 (master 0): id 6 位 (64 个 ID, 编号空间 [0,64)),  地址 49 位, 无 cache
//    主口 in_1 (master 1): id 5 位 (32 个 ID, 编号空间 [64,96)), 地址 49 位, 有 cache
//    从口 out_0 (MEM,  内存):  地址 48 位, 含 burst/qos/cache/prot, 命中 [2GB, 256TB)
//    从口 out_1 (MMIO, 外设):  地址 49 位, 含 cache/prot, 无 burst/qos, 命中 [0,2GB) ∪ 高位别名
//
//  相对单主 AXI4Xbar_1 (1×5) 的关键增量 —— 多主交叉开关三件套:
//    [A] ID indexer / yanker (重映射 + 还原): 上行请求把"主口号"前缀进 AXI ID 以区分两个
//        主口 —— in_0 的 7 位宽 ID = {1'b0, id6} (落 [0,64)), in_1 = {2'b10, id5} (落 [64,96))。
//        下行响应据 ID 高位还原目标主口 (id[6]==0 → in_0; id[6:5]==2'b10 → in_1), 并把 7 位
//        ID 裁回各主口原宽 (yanker: [5:0] / [4:0])。
//    [B] 每从口对 2 主口做 round-robin 仲裁 (AW/AR 各一把), 每主口对 2 从口的响应做
//        round-robin 仲裁 (R/B 各一把) —— 共 8 把 2 路仲裁器。
//    [C] per-ID 顺序保持 (FIFO map): 同一主口同一 ID 维护 count(在飞)/last(锁定从口),
//        新请求仅当 count==0(可任选) 或目标从口与在飞相同(last==tag) 且 count 未满(=7) 时放行,
//        防止同 ID 响应在两从口间交错而破坏 AXI 顺序保证。
//    [D] AW/W 同步: 每主口一条 awIn 路由队列记录 AW 命中从口供 W 跟随; 每从口一条 awOut 队列
//        记录该从口 AW 仲裁胜出的主口供 W 反向选择 (黑盒 Queue2_UInt2, 深度 2, flow=true)。
//
//  注: 交织拆分 (Deinterleaver) 是总线链上独立的 AXI4Deinterleaver 适配器, 不在本交叉开关
//  本体内 —— 故本核不含 Deinterleaver 逻辑。
//
//  验证: golden 同名 AXI4Xbar 例化本核 (端口透传) + 黑盒 Queue2_UInt2/ram_2x2。
// =============================================================================
package axi4xbar_pkg;

  localparam int NID0   = 64;  // 主口 0 的 ID 数 (id 宽 6 位)
  localparam int NID1   = 32;  // 主口 1 的 ID 数 (id 宽 5 位)
  localparam int FLIGHT = 7;   // 每 ID 最大在飞数 (count 3 位, 满=7 后拒新请求)
  localparam int NARB   = 8;   // round-robin 仲裁器总数

  // 仲裁器编号 (语义命名)。每把都是 2 路 (source0 / source1)。
  //   AW_O0/AR_O0: 从口 0 的 AW/AR 仲裁 (源 = 主口 0 / 主口 1)
  //   AW_O1/AR_O1: 从口 1 的 AW/AR 仲裁 (源 = 主口 0 / 主口 1)
  //   R_I0/B_I0:   主口 0 的 R/B 仲裁  (源 = 从口 0 / 从口 1)
  //   R_I1/B_I1:   主口 1 的 R/B 仲裁  (源 = 从口 0 / 从口 1)
  localparam int AW_O0 = 0;
  localparam int AR_O0 = 1;
  localparam int AW_O1 = 2;
  localparam int AR_O1 = 3;
  localparam int R_I0  = 4;
  localparam int B_I0  = 5;
  localparam int R_I1  = 6;
  localparam int B_I1  = 7;

  // ---------------------------------------------------------------------------
  //  地址译码 (49 位地址 ⇒ 命中哪个从口)。两从口对地址空间互补 (恒有且仅有一个命中):
  //    out_0 (MEM):  ~addr[48] & |addr[47:31]            ⇔ addr ∈ [2^31, 2^48)
  //    out_1 (MMIO): ~|addr[48:31] | addr[48]            ⇔ addr ∈ [0, 2^31) ∪ [2^48, 2^49)
  //  (golden 把 MEM 展开成 17 项 masked-AddressSet OR; 此处用等价闭式, FM 逐位证等价。)
  // ---------------------------------------------------------------------------
  function automatic logic dec_mem(input logic [48:0] a);
    return ~a[48] & (|a[47:31]);
  endfunction

  function automatic logic dec_mmio(input logic [48:0] a);
    return (~(|a[48:31])) | a[48];
  endfunction

  // ---------------------------------------------------------------------------
  //  2 路 round-robin 授权 (rocket-chip TLArbiter.roundRobin 的 N=2 特化, 前缀 OR 算法)。
  //    valid : 两源的请求位 {src1, src0}
  //    mask  : 优先级掩码 (RegInit 全 1; 已服务者下一轮降到最低优先级)
  //    返回  : 两源各自的"被授权"位 (one-hot 或全 0)。
  //  展开式与 golden 的 _readys_readys 逐位一致。
  // ---------------------------------------------------------------------------
  function automatic logic [1:0] rr2(input logic [1:0] valid, input logic [1:0] mask);
    logic [1:0] filt;
    filt    = valid & ~mask;
    rr2[0]  = ~((filt[1] | mask[0]) & (valid[1] | filt[0]));
    rr2[1]  = ~(mask[1] & (filt[1] | filt[0]));
  endfunction

  // 掩码更新: 把"本轮胜者及其右侧"全部置 1 (leftOR), 使胜者下一轮优先级最低。
  function automatic logic [1:0] leftor2(input logic [1:0] w);
    return w | {w[0], 1'b0};
  endfunction

endpackage
