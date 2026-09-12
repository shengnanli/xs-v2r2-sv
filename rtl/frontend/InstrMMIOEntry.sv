// =============================================================================
//  InstrMMIOEntry —— MMIO 取指的单条 miss 条目（前端 uncache 取指通路的心脏）
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel）：
//      src/main/scala/xiangshan/frontend/icache/InstrUncache.scala（class InstrMMIOEntry）
//      src/main/scala/xiangshan/frontend/IFU.scala（mmio_state 状态机，本模块的唯一用户）
//
//  ## 为什么 MMIO 取指要单独走一条路
//  正常取指走 ICache：一次取一整条 cacheline，可以预取、可以投机、可以缓存。
//  但当 PMP 判定该地址是 mmio 区、或 iTLB 的 pbmt 页属性说这一页 uncacheable 时，
//  这三件事一件都不能做：
//    * 不能缓存    —— 设备寄存器的值随时会变，缓存下来就是读到陈旧值；
//    * 不能预取    —— 读设备寄存器往往有副作用（读清标志位），多读一个字节都是 bug；
//    * 不能投机    —— 同理，错误路径上的一次 MMIO 读就已经把副作用做掉了。
//  所以 IFU 在 f3 级发现 f3_req_is_mmio 之后，绕开 ICache，改成"一次只问总线要一个
//  8 字节总线字"的保守方式：请求经本模块变成一笔 TileLink Get 打到 L2/总线上，
//  拿回来的 64 位里按 pc 切出 32 位指令。IFU 那边还会一直等到前一条指令在 ROB 里
//  commit（m_waitCommit）才让这条 MMIO 指令进 Ibuffer —— 即"非投机"。
//
//  ## 怎么和正常取指汇合
//  本模块只负责"把一个物理地址换成 32 位指令字"，不认识取指块。返回的数据被 IFU 存进
//  f3_mmio_data，再和 ICache 取回的指令走同一个 io.toIbuffer 出口进 Ibuffer——
//  对后端来说 MMIO 指令和普通指令没有区别。若 pc[2:1]==2'b11 且取回的是 32 位 RVI 指令，
//  这个总线字里只有低半条，IFU 会重新过一遍 TLB/PMP 再发第二笔请求（m_resendReq）。
//
//  ## 4 态状态机（本文件的主体）
//      S_INVALID     空闲：req.ready=1，收到请求就锁存 {addr, memBackTypeMM, memPageTypeNC}
//      S_REFILL_REQ  发请求：往 TileLink A 通道发 Get（地址按 8B 对齐）；
//                    若此刻有 wfi 请求在等，就压住不发（别在准备睡觉时给总线添新事务）
//      S_REFILL_RESP 等回包：等 D 通道 grant，锁存 64 位数据与 corrupt
//      S_SEND_RESP   回响应：把切好的 32 位送回 IFU，一拍后回 S_INVALID
//  wfiSafe = 状态不是 S_REFILL_RESP —— 只有"总线上有一笔已发出、还没回来的读"时
//  才不能进 wfi；其余状态随时可睡。
//
//  ## KunminghuV2 固化掉的三件事（读 golden 时会觉得"少了点什么"，就是这三件）
//    1. nMMIOs=1 → entry id 宽度为 0，TileLink A 通道的 source 恒 0，端口都不存在；
//    2. resp.ready 在 IFU 侧恒 1（fromUncache.ready := true.B）→ 被 firtool 消掉，
//       所以 golden 没有 io_resp_ready 端口，"响应必被收下"是硬约束；
//    3. grant.ready 在 InstrUncache 顶层被恒置 1（防 X 传播）→ 同样没有端口。
//  A 通道也只剩 address 与两个 user 位：opcode(Get)/param/size(lgSize=3)/mask/source
//  在本配置下都是常量，被 firtool 折叠掉了。
//
//  ## G0 → G1 这一轮加了什么（本文件的全部改动来源）
//  新增 5 个端口，对应 InsUncacheReq 多出来的三个字段与 A 通道多出来的两个 user 域：
//    io_req_bits_memBackTypeMM / io_req_bits_memPageTypeNC —— 页属性，随请求锁存后
//      原样挂到 A 通道 user 域（MemBackTypeMMField / MemPageTypeNCField），
//      告诉 CoupledL2"这笔 uncache 读打的其实是主存(!pmp.mmio)"/"这一页是 pbmt.nc"，
//      L2 要据此决定怎么处理，不能当成普通 mmio 一路透传出去；
//    io_req_bits_flush —— 后端重定向/FTQ 冲刷把这次取指作废（见下面 need_flush）。
// =============================================================================
package instr_mmio_entry_pkg;

  // ---- 固化参数（KunminghuV2Config；见 IFU.scala HasIFUConst 与 ICacheParameters）----
  localparam int PADDR_BITS      = 48;  // PAddrBits
  localparam int MMIO_BUS_WIDTH  = 64;  // mmioBusWidth：一次 MMIO 取指从总线拿回的位数
  localparam int MMIO_BUS_BYTES  = 8;   // mmioBusBytes = mmioBusWidth/8 → 地址按 3 位对齐
  localparam int MAX_INSTR_LEN   = 32;  // maxInstrLen：一条 RISC-V 指令最长 32 位

  // ---- IFU → 本模块的请求（Chisel class InsUncacheReq）----
  typedef struct packed {
    logic [PADDR_BITS-1:0] addr;           // 物理地址（IFU 的 f3_paddrs(0) 或重发地址）
    logic                  memBackTypeMM;  // !pmp.mmio：地址其实落在主存区，只是页属性 nc/io
    logic                  memPageTypeNC;  // pbmt == nc
    logic                  flush;          // 这次取指已被冲刷，结果不要了
  } ins_uncache_req_t;

  // ---- 本模块 → IFU 的响应（Chisel class InsUncacheResp）----
  typedef struct packed {
    logic [MAX_INSTR_LEN-1:0] data;
    logic                     corrupt;     // 含 TileLink denied（TL spec 规定 denied 蕴含 corrupt）
  } ins_uncache_resp_t;

  // ---- TileLink A 通道上真正存在的字段（其余被常量折叠，见文件头）----
  typedef struct packed {
    logic [PADDR_BITS-1:0] address;
    logic                  user_memPageType_NC;
    logic                  user_memBackType_MM;
  } tl_a_get_t;

  // ---- TileLink D 通道上真正被本模块读的字段 ----
  typedef struct packed {
    logic [MMIO_BUS_WIDTH-1:0] data;
    logic                      corrupt;
  } tl_d_grant_t;

  // ---- 条目状态（Chisel: s_invalid :: s_refill_req :: s_refill_resp :: s_send_resp）----
  typedef enum logic [1:0] {
    S_INVALID     = 2'd0,
    S_REFILL_REQ  = 2'd1,
    S_REFILL_RESP = 2'd2,
    S_SEND_RESP   = 2'd3
  } entry_state_e;

endpackage

// -----------------------------------------------------------------------------
//  可读核：状态机本体。接口按 Chisel 的 bundle 分组，展平留给下面的 wrapper。
// -----------------------------------------------------------------------------
module xs_InstrMMIOEntry_core
  import instr_mmio_entry_pkg::*;
(
  input  logic              clock,
  input  logic              reset,

  // IFU 侧请求（Decoupled）
  output logic              req_ready,
  input  logic              req_valid,
  input  ins_uncache_req_t  req_bits,

  // IFU 侧响应（Decoupled；ready 恒 1 已被消掉，故无 resp_ready）
  output logic              resp_valid,
  output ins_uncache_resp_t resp_bits,

  // TileLink A 通道：发 Get
  input  logic              acquire_ready,
  output logic              acquire_valid,
  output tl_a_get_t         acquire_bits,

  // TileLink D 通道：收 AccessAckData（ready 被上层钉死为 1，故无 grant_ready）
  input  logic              grant_valid,
  input  tl_d_grant_t       grant_bits,

  // WFI 握手：核要睡觉之前先问一句"你手上还有在途总线事务吗"
  input  logic              wfi_req,
  output logic              wfi_safe
);

  // 锁存的请求。只存 3 个字段：Chisel 写的是 `req := io.req.bits`（4 个字段全锁），
  // 但锁下来的 flush 那一位没有任何人读——下游读的是**当拍**的 io.req.bits.flush——
  // 于是 firtool 把 req_flush 寄存器 DCE 掉了，golden 里根本没有它。这里跟着 golden
  // 不生成：留一个没人读的寄存器既误导读者，也会在 FM 里变成一个对不上的比较点。
  typedef struct packed {
    logic [PADDR_BITS-1:0] addr;
    logic                  memBackTypeMM;
    logic                  memPageTypeNC;
  } latched_req_t;

  entry_state_e                    state;
  latched_req_t                    req;              // 无复位（golden 用 Reg 而非 RegInit）
  logic [MMIO_BUS_WIDTH-1:0]       resp_data_reg;    // 复位清零（RegInit）
  logic                            resp_corrupt_reg; // 复位清零（RegInit）
  logic                            need_flush;       // 复位清零（RegInit）

  // ---------------------------------------------------------------------------
  // 三个握手点。注意只有 acquire 是真双向握手，另外两个的 ready 都被固定成 1 了。
  // ---------------------------------------------------------------------------
  assign req_ready     = (state == S_INVALID);
  assign acquire_valid = (state == S_REFILL_REQ) && !wfi_req;
  // resp 在 S_SEND_RESP 拉高；若这次取指已被冲刷，就只把 valid 压掉，条目照常释放。
  assign resp_valid    = (state == S_SEND_RESP) && !need_flush;

  wire req_fire     = req_ready     && req_valid;
  wire acquire_fire = acquire_valid && acquire_ready;
  wire grant_fire   = (state == S_REFILL_RESP) && grant_valid;  // grant.ready 恒 1

  // ---------------------------------------------------------------------------
  // 发往 L2 的 Get：地址按 8 字节总线字对齐，两个页属性位原样带上。
  // ---------------------------------------------------------------------------
  localparam int MMIO_BUS_OFFSET = $clog2(MMIO_BUS_BYTES);   // = 3
  assign acquire_bits = '{
    address             : {req.addr[PADDR_BITS-1:MMIO_BUS_OFFSET], {MMIO_BUS_OFFSET{1'b0}}},
    user_memPageType_NC : req.memPageTypeNC,
    user_memBackType_MM : req.memBackTypeMM
  };

  // ---------------------------------------------------------------------------
  // 从 64 位总线字里按 pc[2:1] 切出 32 位指令。
  //   pc[2:1]==0/1/2 时低半条和高半条都在这个总线字里，直接切；
  //   pc[2:1]==3 时这条指令的起始半字是总线字的最后 2 字节，只有 16 位有效，
  //   高 16 位补 0 —— 若它是 32 位的 RVI 指令，IFU 会看到 f3_paddrs(0)[2:1]==3 且
  //   !isRVC，走 needResend 再发一笔请求去拿后半条（IFU.scala m_sendTLB→m_resendReq）。
  // ---------------------------------------------------------------------------
  //
  // 与 golden 的一处 X 行为差异（诚实记一笔，不是等价性问题）：req 是无复位寄存器，
  // 复位后到第一次收下请求之前 req.addr 是 X。golden 那边是 4 选 1 packed 数组
  // 按 X 下标取值 → 结果 X；这里 case 落到 default → 结果 0。两者都只在 resp_valid
  // 拉高时才有意义，而进 S_SEND_RESP 必然已经锁过 req.addr，所以真实行为无差别；
  // FM 不建模 X 也看不到。UT 里这几拍（每次运行 4~8 拍）按"golden 为 X 则跳过比较"
  // 处理，日志的 skipped_x 就是它。
  logic [MAX_INSTR_LEN-1:0] resp_data;
  always_comb begin
    case (req.addr[2:1])
      2'b00:   resp_data = resp_data_reg[31:0];
      2'b01:   resp_data = resp_data_reg[47:16];
      2'b10:   resp_data = resp_data_reg[63:32];
      default: resp_data = {16'b0, resp_data_reg[63:48]};  // 2'b11：只剩最后一个半字
    endcase
  end
  assign resp_bits = '{data: resp_data, corrupt: resp_corrupt_reg};

  // 只要总线上没有"已发出、还没回来"的读，就可以安全进 wfi。
  assign wfi_safe = (state != S_REFILL_RESP);

  // ---------------------------------------------------------------------------
  // need_flush：请求已经上路之后才收到冲刷
  //
  // 后端重定向/FTQ 冲刷会把这次取指作废（IFU: toUncache.bits.flush）。但此时 Get
  // 可能已经打到总线上了，TileLink 不允许赖账——D 通道那一拍 grant 必须收下，否则
  // 总线上会留下一个永远没人认领的响应。所以做法不是"立刻回 S_INVALID"，而是打一个
  // 「回来了也别往外送」的标记：照常走完 S_REFILL_RESP → S_SEND_RESP，只在最后那拍
  // 把 io_resp_valid 压掉，然后正常释放条目。
  //
  // 标记只在"请求在途"（S_REFILL_REQ / S_REFILL_RESP）时才立：S_INVALID 下的 flush
  // 与本条目无关（还没收请求），S_SEND_RESP 下这一拍就要结束了、立了也来不及用。
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      need_flush <= 1'b0;
    else if (state == S_SEND_RESP)                        // 本次请求就此了结，标记清掉
      need_flush <= 1'b0;
    else if (req_bits.flush && (state != S_INVALID))      // 在途时被冲刷 → 记下来
      need_flush <= 1'b1;
  end

  // ---------------------------------------------------------------------------
  // 锁存请求：无复位，只在收下请求那拍更新（golden 用的是不带 init 的 Reg）
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock) begin
    if (req_fire) begin
      req.addr          <= req_bits.addr;
      req.memBackTypeMM <= req_bits.memBackTypeMM;
      req.memPageTypeNC <= req_bits.memPageTypeNC;
    end
  end

  // ---------------------------------------------------------------------------
  // 锁存回包数据：复位清零
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      resp_data_reg    <= '0;
      resp_corrupt_reg <= 1'b0;
    end
    else if (grant_fire) begin
      resp_data_reg    <= grant_bits.data;
      resp_corrupt_reg <= grant_bits.corrupt;
    end
  end

  // ---------------------------------------------------------------------------
  // 状态机
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      state <= S_INVALID;
    else begin
      case (state)
        S_INVALID:     if (req_fire)     state <= S_REFILL_REQ;
        S_REFILL_REQ:  if (acquire_fire) state <= S_REFILL_RESP;
        S_REFILL_RESP: if (grant_fire)   state <= S_SEND_RESP;
        // Chisel 写的是 when(io.resp.fire || needFlush)，但本配置下 resp.ready 恒 1、
        // resp.valid = !needFlush，于是 fire||needFlush ≡ !needFlush||needFlush ≡ 1：
        // 进了 S_SEND_RESP 就只待一拍，响应送出去也好、被冲刷压掉也好，都回空闲。
        // （golden 里那个恒真表达式原样生成着，没被 firtool 化简。）
        default:       state <= S_INVALID;
      endcase
    end
  end

endmodule

// -----------------------------------------------------------------------------
//  golden 同名 wrapper：端口与 G1 golden 逐位同名同宽（21 个：14 输入 / 7 输出），
//  只做 bundle 打包/拆包，不含逻辑。
// -----------------------------------------------------------------------------
module InstrMMIOEntry
  import instr_mmio_entry_pkg::*;
(
  input  logic        clock,
  input  logic        reset,
  output logic        io_req_ready,
  input  logic        io_req_valid,
  input  logic [47:0] io_req_bits_addr,
  input  logic        io_req_bits_memBackTypeMM,
  input  logic        io_req_bits_memPageTypeNC,
  input  logic        io_req_bits_flush,
  output logic        io_resp_valid,
  output logic [31:0] io_resp_bits_data,
  output logic        io_resp_bits_corrupt,
  input  logic        io_mmio_acquire_ready,
  output logic        io_mmio_acquire_valid,
  output logic [47:0] io_mmio_acquire_bits_address,
  output logic        io_mmio_acquire_bits_user_memPageType_NC,
  output logic        io_mmio_acquire_bits_user_memBackType_MM,
  input  logic        io_mmio_grant_valid,
  input  logic [63:0] io_mmio_grant_bits_data,
  input  logic        io_mmio_grant_bits_corrupt,
  input  logic        io_wfi_wfiReq,
  output logic        io_wfi_wfiSafe
);

  ins_uncache_req_t  req_bits;
  ins_uncache_resp_t resp_bits;
  tl_a_get_t         acquire_bits;
  tl_d_grant_t       grant_bits;

  assign req_bits = '{
    addr          : io_req_bits_addr,
    memBackTypeMM : io_req_bits_memBackTypeMM,
    memPageTypeNC : io_req_bits_memPageTypeNC,
    flush         : io_req_bits_flush
  };

  assign grant_bits = '{
    data    : io_mmio_grant_bits_data,
    corrupt : io_mmio_grant_bits_corrupt
  };

  assign io_resp_bits_data    = resp_bits.data;
  assign io_resp_bits_corrupt = resp_bits.corrupt;

  assign io_mmio_acquire_bits_address             = acquire_bits.address;
  assign io_mmio_acquire_bits_user_memPageType_NC = acquire_bits.user_memPageType_NC;
  assign io_mmio_acquire_bits_user_memBackType_MM = acquire_bits.user_memBackType_MM;

  xs_InstrMMIOEntry_core u_core (
    .clock         (clock),
    .reset         (reset),
    .req_ready     (io_req_ready),
    .req_valid     (io_req_valid),
    .req_bits      (req_bits),
    .resp_valid    (io_resp_valid),
    .resp_bits     (resp_bits),
    .acquire_ready (io_mmio_acquire_ready),
    .acquire_valid (io_mmio_acquire_valid),
    .acquire_bits  (acquire_bits),
    .grant_valid   (io_mmio_grant_valid),
    .grant_bits    (grant_bits),
    .wfi_req       (io_wfi_wfiReq),
    .wfi_safe      (io_wfi_wfiSafe)
  );

endmodule
