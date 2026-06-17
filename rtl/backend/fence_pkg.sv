// =============================================================================
// fence_pkg —— Fence 功能单元（栅栏单元）的类型与常量定义
//
// 对应 Chisel: xiangshan.backend.fu.Fence / FenceOpType（package.scala）
//
// Fence FU 处理三类“屏障/同步”指令，它们都不产生数据结果，而是通过
// 一个小状态机，在流水排空（store buffer 清空）后向外部各部件发出 flush 脉冲：
//   - fence        ：内存屏障（RVI），实际只需排空 sbuffer，不发额外 flush
//   - fence.i      ：取指屏障，需 flush icache（fencei 信号）
//   - sfence.vma   ：刷新 TLB（sfence.valid 信号），supervisor 地址翻译屏障
//   - hfence.vvma  ：刷新 VS 级 TLB（hv），H 扩展
//   - hfence.gvma  ：刷新 G 级 TLB（hg），H 扩展
//   - nofence      ：占位（Svinval 扩展用），什么都不做
//
// 设计要点：所有 flush（sbuffer/tlb/icache）信号都是“某个状态下拉高一拍”的脉冲，
// 下游部件必须随时能接收 flush。状态机走完后回到 idle 并在出口握手写回 ROB。
// =============================================================================
package fence_pkg;

  // ---------------------------------------------------------------------------
  // FenceOpType —— fuOpType 编码（9 位端口，但有效编码仅低 5 位）
  // 与 Scala object FenceOpType 完全一致：
  //   fence  = 5'b10000  sfence = 5'b10001  fencei = 5'b10010
  //   hfence_v=5'b10011  hfence_g=5'b10100  nofence= 5'b00000
  // ---------------------------------------------------------------------------
  localparam int unsigned FUOPTYPE_W = 9;

  typedef enum logic [FUOPTYPE_W-1:0] {
    OP_NOFENCE  = 9'h00,
    OP_FENCE    = 9'h10,
    OP_SFENCE   = 9'h11,
    OP_FENCEI   = 9'h12,
    OP_HFENCE_V = 9'h13,
    OP_HFENCE_G = 9'h14
  } fence_op_e;

  // ---------------------------------------------------------------------------
  // 状态机状态 —— 与 Scala 的 Enum(6) 同序同义：
  //   s_idle    : 初始态，可纳新请求；in.ready 仅此态为 1
  //   s_wait    : 拉高 sbuffer flush，等 store buffer 排空（sbIsEmpty）
  //   s_tlb     : 发 sfence（刷 TLB），停留一拍
  //   s_icache  : 发 fencei（刷 icache），停留一拍
  //   s_fence   : 普通 fence 的占位态（仅为时序，不发额外 flush），停留一拍
  //   s_nofence : Svinval 占位态，停留一拍
  // 注意编码必须与 golden 完全一致（FM/Ut 双例化按值比对状态相关输出）：
  //   idle=0 wait=1 tlb=2 icache=3 fence=4 nofence=5
  // ---------------------------------------------------------------------------
  typedef enum logic [2:0] {
    S_IDLE    = 3'h0,
    S_WAIT    = 3'h1,
    S_TLB     = 3'h2,
    S_ICACHE  = 3'h3,
    S_FENCE   = 3'h4,
    S_NOFENCE = 3'h5
  } fence_state_e;

  // ---------------------------------------------------------------------------
  // 入口 uop 中需要在 fire 拍锁存、供状态机及写回使用的字段。
  // （golden 把这些字段散成一堆 uop_ctrl_* / uop_data_imm 标量寄存器，这里聚合成
  //  一个 struct，语义更清晰：它就是“当前正在处理的这条 fence 指令”。）
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [FUOPTYPE_W-1:0] fuOpType;     // 决定走哪条 flush 分支
    logic                  robIdx_flag;  // ROB 指针（写回定位）
    logic [7:0]            robIdx_value;
    logic [7:0]            pdest;        // 物理目的寄存器（fence 无结果，仍透传）
    logic                  flushPipe;    // 是否需要 flush 流水（透传到 sfence/out）
    logic [63:0]           imm;          // 立即数：低 10 位用于 sfence rs1/rs2 判定
  } fence_uop_t;

endpackage
