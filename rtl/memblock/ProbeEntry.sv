// ProbeEntry.sv —— DCache ProbeQueue 的单个 probe 表项（3 态状态机）
//
// 位置：ProbeQueue 里有 nProbeEntries = 8 个本模块。L2 发来的一致性 probe（TileLink B 通道，
//   "把某条 cacheline 降权/无效掉"）被 ProbeQueue 翻译成 ProbeReq 后分给一个空闲表项；表项把它
//   变成一条 MainPipeReq 送进 DCache 主流水（经 Arbiter8_MainPipeReq 八选一），主流水做完降权后
//   回一个 pipe_resp，表项按 id 认领并释放。对应 Chisel：cache/dcache/mainpipe/Probe.scala
//   class ProbeEntry。
//
// 状态机（state 异步复位到 S_INVALID）：
//   S_INVALID   空闲，io_req_ready=1；req 握手当拍锁存 ProbeReq，转 S_PIPE_REQ
//   S_PIPE_REQ  向主流水发 pipe_req；被下游接走（fire）转 S_WAIT_RESP
//   S_WAIT_RESP 等主流水回 pipe_resp 且 resp.id == 本表项 io_id，回 S_INVALID
//   block_addr.valid = 非空闲：ProbeQueue 拿它挡住同一行上的其它请求。
//
// ★LR/SC 阻塞打一拍（照 golden，时序优化）★：若某条 LR 正锁着同一 cacheline（lrsc_locked_block），
//   probe 必须等它释放。Scala 为了时序先算 lrsc_blocked、再 RegNext 一拍才用来屏蔽 pipe_req.valid：
//     lrsc_blocked = req.fire ? (锁住的块 == 入队这条的块) : (锁住的块 == 已存的 req.addr 的块)
//   入队那拍用的是 io_req_bits_addr（req 寄存器还没写进去）。这个寄存器不复位（golden 同）。
//
// 本模块无子模块；golden 189 行 / 22 端口。req 字段寄存器不复位，只在入队时写（golden 同）。

module xs_ProbeEntry_core #(
  parameter int unsigned PADDR_W  = 48,
  parameter int unsigned VADDR_W  = 50,
  parameter int unsigned ID_W     = 3,   // log2(nProbeEntries)
  parameter int unsigned BLK_OFF  = 6    // cacheline 64B：比块地址时去掉低 6 位
)(
  input  logic               clock,
  input  logic               reset,
  // 来自 ProbeQueue 的分配请求（已翻译好的 ProbeReq）
  output logic               req_ready,
  input  logic               req_valid,
  input  logic [PADDR_W-1:0] req_addr_in,
  input  logic [VADDR_W-1:0] req_vaddr_in,
  input  logic [1:0]         req_param_in,
  input  logic               req_need_data_in,
  // 送主流水的 MainPipeReq（probe 子集）
  input  logic               pipe_req_ready,
  output logic               pipe_req_valid,
  output logic [1:0]         pipe_req_probe_param,
  output logic               pipe_req_probe_need_data,
  output logic [VADDR_W-1:0] pipe_req_vaddr,
  output logic [PADDR_W-1:0] pipe_req_addr,
  // 主流水的完成回执
  input  logic               pipe_resp_valid,
  input  logic [ID_W-1:0]    pipe_resp_id,
  // LR/SC 正锁着的 cacheline
  input  logic               lrsc_locked_valid,
  input  logic [PADDR_W-1:0] lrsc_locked_addr,
  // 本表项在队列里的编号
  input  logic [ID_W-1:0]    entry_id,
  // 正在处理的块地址（给 ProbeQueue 做冲突阻塞）
  output logic               block_addr_valid,
  output logic [PADDR_W-1:0] block_addr
);

  typedef enum logic [1:0] {
    S_INVALID   = 2'd0,
    S_PIPE_REQ  = 2'd1,
    S_WAIT_RESP = 2'd2
  } probe_state_e;

  probe_state_e state;

  // 锁存的 ProbeReq（不复位，入队时写）
  logic [PADDR_W-1:0] req_addr;
  logic [VADDR_W-1:0] req_vaddr;
  logic [1:0]         req_param;
  logic               req_need_data;

  // 两个 PADDR 是否落在同一条 cacheline
  function automatic logic same_block(input logic [PADDR_W-1:0] a, input logic [PADDR_W-1:0] b);
    return a[PADDR_W-1:BLK_OFF] == b[PADDR_W-1:BLK_OFF];
  endfunction

  // ---------------------------------------------------------------------------
  // 握手
  // ---------------------------------------------------------------------------
  logic req_fire, pipe_req_fire, resp_hit;
  logic lrsc_blocked;        // 本拍算出的"被 LR/SC 锁住"
  logic lrsc_blocked_q;      // 打一拍后的版本（golden: io_pipe_req_valid_REG）

  assign req_ready      = (state == S_INVALID);
  assign req_fire       = req_ready & req_valid;
  assign pipe_req_valid = (state == S_PIPE_REQ) & ~lrsc_blocked_q;
  assign pipe_req_fire  = pipe_req_valid & pipe_req_ready;
  assign resp_hit       = pipe_resp_valid & (pipe_resp_id == entry_id);

  // 入队那拍 req 寄存器还没更新，比的是入口地址；其余时候比已存的地址
  assign lrsc_blocked = lrsc_locked_valid &
                        (req_fire ? same_block(lrsc_locked_addr, req_addr_in)
                                  : same_block(lrsc_locked_addr, req_addr));

  // ---------------------------------------------------------------------------
  // 状态机
  // ---------------------------------------------------------------------------
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      state <= S_INVALID;
    else begin
      case (state)
        S_INVALID:   if (req_fire)      state <= S_PIPE_REQ;
        S_PIPE_REQ:  if (pipe_req_fire) state <= S_WAIT_RESP;
        S_WAIT_RESP: if (resp_hit)      state <= S_INVALID;
        default:     ;                  // 2'd3 不可达，保持（golden 同：三条转移都不命中）
      endcase
    end
  end

  always_ff @(posedge clock) begin
    if (req_fire) begin
      req_addr      <= req_addr_in;
      req_vaddr     <= req_vaddr_in;
      req_param     <= req_param_in;
      req_need_data <= req_need_data_in;
    end
    lrsc_blocked_q <= lrsc_blocked;
  end

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign pipe_req_probe_param     = req_param;
  assign pipe_req_probe_need_data = req_need_data;
  assign pipe_req_vaddr           = req_vaddr;
  assign pipe_req_addr            = req_addr;
  assign block_addr_valid         = (state != S_INVALID);
  assign block_addr               = req_addr;

endmodule

module ProbeEntry (
  input  logic        clock,
  input  logic        reset,
  output logic        io_req_ready,
  input  logic        io_req_valid,
  input  logic [47:0] io_req_bits_addr,
  input  logic [49:0] io_req_bits_vaddr,
  input  logic [1:0]  io_req_bits_param,
  input  logic        io_req_bits_needData,
  input  logic        io_pipe_req_ready,
  output logic        io_pipe_req_valid,
  output logic [1:0]  io_pipe_req_bits_probe_param,
  output logic        io_pipe_req_bits_probe_need_data,
  output logic [49:0] io_pipe_req_bits_vaddr,
  output logic [47:0] io_pipe_req_bits_addr,
  output logic [5:0]  io_pipe_req_bits_id,
  input  logic        io_pipe_resp_valid,
  input  logic [2:0]  io_pipe_resp_bits_id,
  input  logic        io_lrsc_locked_block_valid,
  input  logic [47:0] io_lrsc_locked_block_bits,
  input  logic [2:0]  io_id,
  output logic        io_block_addr_valid,
  output logic [47:0] io_block_addr_bits
);

  xs_ProbeEntry_core u_core (
    .clock                    (clock),
    .reset                    (reset),
    .req_ready                (io_req_ready),
    .req_valid                (io_req_valid),
    .req_addr_in              (io_req_bits_addr),
    .req_vaddr_in             (io_req_bits_vaddr),
    .req_param_in             (io_req_bits_param),
    .req_need_data_in         (io_req_bits_needData),
    .pipe_req_ready           (io_pipe_req_ready),
    .pipe_req_valid           (io_pipe_req_valid),
    .pipe_req_probe_param     (io_pipe_req_bits_probe_param),
    .pipe_req_probe_need_data (io_pipe_req_bits_probe_need_data),
    .pipe_req_vaddr           (io_pipe_req_bits_vaddr),
    .pipe_req_addr            (io_pipe_req_bits_addr),
    .pipe_resp_valid          (io_pipe_resp_valid),
    .pipe_resp_id             (io_pipe_resp_bits_id),
    .lrsc_locked_valid        (io_lrsc_locked_block_valid),
    .lrsc_locked_addr         (io_lrsc_locked_block_bits),
    .entry_id                 (io_id),
    .block_addr_valid         (io_block_addr_valid),
    .block_addr               (io_block_addr_bits)
  );

  // MainPipeReq.id 宽 6 位，probe 表项编号只占低 3 位（Probe.scala: pipe_req.id := io.id）
  assign io_pipe_req_bits_id = {3'h0, io_id};

endmodule
