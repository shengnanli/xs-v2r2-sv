// WritebackEntry.sv —— DCache WritebackQueue 的单个写回表项（TileLink C 通道发送方）
//
// 位置：WritebackQueue 里有 nReleaseEntries = 18 个本家族表项，表项 i 的 id = 17+i（0x11..0x22，
//   给 TileLink C 通道做 source）。id 宽度随常数而变：表项 0..14 用本变体 WritebackEntry（io_id 5 位），
//   表项 15..17 用 WritebackEntry_15（io_id 6 位，见该文件）。
//   主流水把"要写回的一行"（替换出的脏行 Release，或回应 L2 probe 的 ProbeAck）分给一个空闲表项，
//   表项负责在 C 通道上把它发出去：带数据时 64B 行分 2 拍（每拍 256 位），Release 还要再等
//   D 通道的 ReleaseAck。对应 Chisel：cache/dcache/mainpipe/WritebackQueue.scala class WritebackEntry。
//
// 状态机（state 异步复位到 S_INVALID）：
//   S_INVALID      空闲，req_ready=1；alloc（req.valid & primary_valid & 空闲）锁存请求 → S_RELEASE_REQ
//   S_RELEASE_REQ  在 C 通道发 ProbeAck[Data] / Release[Data]；最后一拍发出（release_done）后：
//                  Release → S_RELEASE_RESP，ProbeAck → S_INVALID
//   S_RELEASE_RESP 拉 grant.ready 等 ReleaseAck，收到 → S_INVALID
//
// 拍计数的两套记账（都照 golden 保留）：
//   * remain（2 位，每位一拍）：alloc 时置 hasData ? 2'b11 : 2'b01，每 fire 清掉最低的那个 1；
//     busy = |remain & s_data_override —— 还有拍要发，且行数据已写好。
//     remain 有 3 份完全相同的复制（remain / remain_dup_0 / remain_dup_1，Chisel 为扇出时序而复制）：
//     remain 定 busy，remain_dup_0 选这一拍发哪半行，remain_dup_1 算本拍要清的位。三份一份不少。
//   * beat_cnt（1 位，edge.count 的计数器）：只用于判"这是不是最后一拍"（release_done）。
//
// 行数据写入晚一拍：alloc 那拍 s_data_override 清 0（"有写入在路上"），下一拍 req_data 才到。
//   写入条件 = ~s_data_override & (req.hasData | 上一拍 alloc)（Scala 原式，照搬）。
//
// paddr 两份复制：ProbeAck 的地址取 paddr_dup_1，Release 取 paddr_dup_2（golden 同，值总相同）。
// req_dirty 只被一条 `ifndef SYNTHESIS 断言读（assert(!dirty || hasData)），综合视图里无扇出；
//   照 golden 保留这个寄存器（断言本身不写进本重写）。
// 本模块无子模块；golden 275 行 / 25 端口。非复位寄存器：data / paddr_dup_* / req_* / alloc_q（golden 同）。

module xs_WritebackEntry_core #(
  parameter int unsigned ID_W     = 5,    // io_id 位宽（变体参数）
  parameter int unsigned SOURCE_W = 6,    // TileLink C 通道 source 位宽（io_id 零扩展到此宽）
  parameter int unsigned PADDR_W  = 48,
  parameter int unsigned BEAT_W   = 256   // 一拍数据宽；一行 = 2 拍
)(
  input  logic                  clock,
  input  logic                  reset,
  input  logic [ID_W-1:0]       entry_id,
  // 分配请求（WritebackReqWodata）+ 晚一拍到的行数据
  input  logic                  req_valid,
  input  logic [2:0]            req_param_in,
  input  logic                  req_voluntary_in,
  input  logic                  req_has_data_in,
  input  logic                  req_corrupt_in,
  input  logic                  req_dirty_in,
  input  logic [PADDR_W-1:0]    req_addr_in,
  input  logic [2*BEAT_W-1:0]   req_line_data,
  // C 通道（release / probeAck）
  input  logic                  release_ready,
  output logic                  release_valid,
  output logic [2:0]            release_opcode,
  output logic [2:0]            release_param,
  output logic [SOURCE_W-1:0]   release_source,
  output logic [PADDR_W-1:0]    release_address,
  output logic [BEAT_W-1:0]     release_data,
  output logic                  release_corrupt,
  // D 通道 ReleaseAck
  input  logic                  grant_valid,
  // 队列级分配握手
  input  logic                  primary_valid,
  output logic                  primary_ready,
  // 正在写回的块地址（给 WritebackQueue 做冲突检查）
  output logic                  block_addr_valid,
  output logic [PADDR_W-1:0]    block_addr
);

  typedef enum logic [1:0] {
    S_INVALID      = 2'd0,
    S_RELEASE_REQ  = 2'd1,
    S_RELEASE_RESP = 2'd2
  } wb_state_e;

  wb_state_e state;

  // 拍记账（异步复位）
  logic [1:0] remain, remain_dup_0, remain_dup_1;
  logic       s_data_override;   // 1 = 没有在途的行数据写入
  logic       beat_cnt;          // edge.count：0 = 下一拍是第一拍

  // 锁存的请求（不复位）
  logic [2*BEAT_W-1:0] line_data;
  logic [PADDR_W-1:0]  paddr_dup_1, paddr_dup_2;
  logic [2:0]          req_param;
  logic                req_voluntary, req_has_data, req_corrupt, req_dirty;
  logic [PADDR_W-1:0]  req_addr;
  logic                alloc_q;          // golden: REG（RegNext(alloc)）

  // ---------------------------------------------------------------------------
  // 分配与发送握手
  // ---------------------------------------------------------------------------
  logic       alloc, busy, release_fire, release_done, grant_fire;
  logic [1:0] remain_set, remain_clr;

  assign primary_ready = (state == S_INVALID);
  assign alloc         = req_valid & primary_valid & primary_ready;
  assign busy          = (|remain) & s_data_override;
  assign release_valid = busy;
  assign release_fire  = release_ready & busy;
  // 最后一拍：带数据时第 2 拍（beat_cnt==1），不带数据时唯一那拍
  assign release_done  = (state == S_RELEASE_REQ) & release_fire & (beat_cnt | ~req_has_data);
  assign grant_fire    = (state == S_RELEASE_RESP) & grant_valid;

  assign remain_set = alloc ? {req_has_data_in, 1'b1} : 2'b00;
  // PriorityEncoderOH(remain_dup_1)：清掉最低的那个 1
  assign remain_clr = release_fire ? (remain_dup_1[0] ? 2'b01 : {remain_dup_1[1], 1'b0}) : 2'b00;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      state           <= S_INVALID;
      remain          <= 2'b00;
      remain_dup_0    <= 2'b00;
      remain_dup_1    <= 2'b00;
      s_data_override <= 1'b1;
      beat_cnt        <= 1'b0;
    end else begin
      // 三个来源互斥（分别要求 state 为 RESP / REQ / INVALID），写成优先级链与 Scala 后写覆盖一致
      if (grant_fire)
        state <= S_INVALID;
      else if (release_done)
        state <= req_voluntary ? S_RELEASE_RESP : S_INVALID;
      else if (alloc)
        state <= S_RELEASE_REQ;
      remain          <= (remain       | remain_set) & ~remain_clr;
      remain_dup_0    <= (remain_dup_0 | remain_set) & ~remain_clr;
      remain_dup_1    <= (remain_dup_1 | remain_set) & ~remain_clr;
      s_data_override <= ~alloc;                 // 写入只占 alloc 后那一拍
      if (release_fire)
        beat_cnt <= beat_cnt ? 1'b0 : req_has_data;
    end
  end

  always_ff @(posedge clock) begin
    if (~s_data_override & (req_has_data | alloc_q))
      line_data <= req_line_data;
    if (alloc) begin
      paddr_dup_1   <= req_addr_in;
      paddr_dup_2   <= req_addr_in;
      req_param     <= req_param_in;
      req_voluntary <= req_voluntary_in;
      req_has_data  <= req_has_data_in;
      req_corrupt   <= req_corrupt_in;
      req_dirty     <= req_dirty_in;
      req_addr      <= req_addr_in;
    end
    alloc_q <= alloc;
  end

  // ---------------------------------------------------------------------------
  // C 通道报文：opcode = {1, voluntary, hasData}
  //   ProbeAck=4 / ProbeAckData=5 / Release=6 / ReleaseData=7
  // ---------------------------------------------------------------------------
  assign release_opcode  = {1'b1, req_voluntary, req_has_data};
  assign release_param   = req_param;
  assign release_source  = SOURCE_W'(entry_id);
  assign release_address = req_voluntary ? paddr_dup_2 : paddr_dup_1;
  // 本拍发哪半行：remain_dup_0 最低的 1（bit0 → 低半行，否则高半行）；不带数据的报文数据为 0
  assign release_data    = req_has_data ? (remain_dup_0[0] ? line_data[BEAT_W-1:0]
                                                           : line_data[2*BEAT_W-1:BEAT_W])
                                        : '0;
  assign release_corrupt = req_corrupt;

  assign block_addr_valid = (state != S_INVALID);
  assign block_addr       = req_addr;

endmodule

module WritebackEntry (
  input  logic         clock,
  input  logic         reset,
  input  logic [4:0]   io_id,
  input  logic         io_req_valid,
  input  logic [2:0]   io_req_bits_param,
  input  logic         io_req_bits_voluntary,
  input  logic         io_req_bits_hasData,
  input  logic         io_req_bits_corrupt,
  input  logic         io_req_bits_dirty,
  input  logic [47:0]  io_req_bits_addr,
  input  logic [511:0] io_req_data_data,
  input  logic         io_mem_release_ready,
  output logic         io_mem_release_valid,
  output logic [2:0]   io_mem_release_bits_opcode,
  output logic [2:0]   io_mem_release_bits_param,
  output logic [5:0]   io_mem_release_bits_source,
  output logic [47:0]  io_mem_release_bits_address,
  output logic [255:0] io_mem_release_bits_data,
  output logic         io_mem_release_bits_corrupt,
  input  logic         io_mem_grant_valid,
  input  logic         io_primary_valid,
  output logic         io_primary_ready,
  output logic         io_block_addr_valid,
  output logic [47:0]  io_block_addr_bits
);

  xs_WritebackEntry_core #(.ID_W(5)) u_core (
    .clock            (clock),
    .reset            (reset),
    .entry_id         (io_id),
    .req_valid        (io_req_valid),
    .req_param_in     (io_req_bits_param),
    .req_voluntary_in (io_req_bits_voluntary),
    .req_has_data_in  (io_req_bits_hasData),
    .req_corrupt_in   (io_req_bits_corrupt),
    .req_dirty_in     (io_req_bits_dirty),
    .req_addr_in      (io_req_bits_addr),
    .req_line_data    (io_req_data_data),
    .release_ready    (io_mem_release_ready),
    .release_valid    (io_mem_release_valid),
    .release_opcode   (io_mem_release_bits_opcode),
    .release_param    (io_mem_release_bits_param),
    .release_source   (io_mem_release_bits_source),
    .release_address  (io_mem_release_bits_address),
    .release_data     (io_mem_release_bits_data),
    .release_corrupt  (io_mem_release_bits_corrupt),
    .grant_valid      (io_mem_grant_valid),
    .primary_valid    (io_primary_valid),
    .primary_ready    (io_primary_ready),
    .block_addr_valid (io_block_addr_valid),
    .block_addr       (io_block_addr_bits)
  );

endmodule
