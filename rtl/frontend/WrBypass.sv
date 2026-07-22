// =============================================================================
// xs_WrBypass —— 写旁路缓冲
//
// 对应 Chisel: xiangshan.frontend.WrBypass
// 用途：分支预测器各表（TAGE/SC/ITTAGE/FTB 等）的 SRAM 写延迟旁路。缓存最近写
// 入的若干 (idx[,tag]) → data 映射；同一索引短时间内再次写入时可直接命中本缓冲，
// 读出上次写入的数据用于本次更新合并，避免读 SRAM 的延迟与读写冲突。
//
// 结构：
//   - idx_tag_cam : 以 {idx[, tag]} 为键的全相联 CAM，给出逐条目命中位图
//   - data_mem    : NUM_ENTRIES × NUM_WAYS × DATA_WIDTH 的数据阵列（组合读）
//   - valids      : 逐条目逐路的数据有效位
//   - ever_written: 条目是否写过（CAM 不复位，用它屏蔽上电假命中）
//   - replacer    : 条目级树形 PLRU（所有路共用——data_mem 一次只写一个条目，
//                   按路独立替换没有意义）
//
// 行为（每个 io_wen 拍）：
//   命中：写 data_mem[hit_idx]（按 way 掩码），置对应 valids；
//   未命中：占用 PLRU 给出的 enq_idx，写入 CAM 键与数据，整条目 valids 按掩码
//           重置（掩码外的路置无效），ever_written 置位；
//   两种情况均 touch PLRU。
// 读出（组合）：io_hit 表示 CAM 命中已写条目；hit_data 为命中条目各路数据及有效位。
// =============================================================================
module xs_WrBypass #(
  parameter int unsigned NUM_ENTRIES = 8,   // 缓冲条目数（须为 2 的幂）
  parameter int unsigned IDX_WIDTH   = 9,   // 索引位宽
  parameter int unsigned NUM_WAYS    = 1,   // 每条目路数
  parameter int unsigned TAG_WIDTH   = 0,   // tag 位宽，0 表示无 tag
  parameter int unsigned DATA_WIDTH  = 3,   // 每路数据位宽
  // 上层是否消费 io_hit_data_valid。0 时(如 WrBypass_41/43: golden firtool 已裁剪该输出)
  // 不建逐路 valids 寄存器(否则悬空成死寄存器), io_hit_data_valid 直接 '0。
  parameter bit          TRACK_HIT_VALID = 1'b1,
  localparam int unsigned ENTRY_IDX_W = (NUM_ENTRIES > 1) ? $clog2(NUM_ENTRIES) : 1,
  localparam int unsigned TAG_W_SAFE  = (TAG_WIDTH > 0) ? TAG_WIDTH : 1
)(
  input  logic                                    clock,
  input  logic                                    reset,           // 异步复位
  // 写请求（同时也是旁路查询）
  input  logic                                    io_wen,
  input  logic [IDX_WIDTH-1:0]                    io_write_idx,
  input  logic [TAG_W_SAFE-1:0]                   io_write_tag,    // TAG_WIDTH=0 时接 '0
  input  logic [NUM_WAYS-1:0][DATA_WIDTH-1:0]     io_write_data,
  input  logic [NUM_WAYS-1:0]                     io_write_way_mask, // 单路时接 1'b1
  // 旁路命中结果（组合输出，对 io_write_idx/tag 查询）
  output logic                                    io_hit,
  output logic [NUM_WAYS-1:0]                     io_hit_data_valid,
  output logic [NUM_WAYS-1:0][DATA_WIDTH-1:0]     io_hit_data_bits
);

  // ---------------------------------------------------------------------------
  // CAM 查询键：{idx, tag}（无 tag 时仅 idx）
  // ---------------------------------------------------------------------------
  localparam int unsigned CAM_W = IDX_WIDTH + TAG_WIDTH;

  logic [CAM_W-1:0] cam_key;
  if (TAG_WIDTH > 0) begin : g_key_tag
    assign cam_key = {io_write_idx, io_write_tag[TAG_WIDTH-1:0]};
  end else begin : g_key_notag
    assign cam_key = io_write_idx;
  end

  logic [NUM_ENTRIES-1:0] cam_match;
  logic                   enq_en;
  logic [ENTRY_IDX_W-1:0] enq_idx;

  xs_IndexableCAM #(
    .ENTRY_WIDTH (CAM_W),
    .NUM_ENTRIES (NUM_ENTRIES)
  ) idx_tag_cam (
    .clock          (clock),
    .io_r_req_idx   (cam_key),
    .io_r_resp      (cam_match),
    .io_w_valid     (enq_en),
    .io_w_bits_data (cam_key),
    .io_w_bits_index(enq_idx)
  );

  // ---------------------------------------------------------------------------
  // 命中检测：CAM 命中且条目写过
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRIES-1:0]              ever_written;
  // 逐路 valids 仅在 TRACK_HIT_VALID 时建(见下 generate); 否则不建, 避免悬空死寄存器。

  logic [NUM_ENTRIES-1:0] hits_oh;
  logic [ENTRY_IDX_W-1:0] hit_idx;
  logic                   hit;

  assign hits_oh = cam_match & ever_written;
  assign hit     = |hits_oh;

  // one-hot 编码为条目号（hits_oh 至多一位有效：CAM 键唯一占用一个条目）
  always_comb begin
    hit_idx = '0;
    for (int unsigned i = 0; i < NUM_ENTRIES; i++)
      if (hits_oh[i]) hit_idx |= ENTRY_IDX_W'(i);
  end

  // ---------------------------------------------------------------------------
  // 条目级 PLRU 替换器：每次写访问 touch 实际使用的条目
  // ---------------------------------------------------------------------------
  logic [ENTRY_IDX_W-1:0] touch_idx;
  assign touch_idx = hit ? hit_idx : enq_idx;
  assign enq_en    = io_wen && !hit;

  xs_PlruReplacer #(
    .NUM_WAYS (NUM_ENTRIES)
  ) replacer (
    .clock       (clock),
    .reset       (reset),
    .touch_valid (io_wen),
    .touch_way   (touch_idx),
    .replace_way (enq_idx)
  );

  // ---------------------------------------------------------------------------
  // 数据阵列：写到命中条目或新占用条目，按 way 掩码
  // ---------------------------------------------------------------------------
  logic [NUM_ENTRIES-1:0][NUM_WAYS-1:0][DATA_WIDTH-1:0] data_mem;

  always_ff @(posedge clock) begin
    if (io_wen) begin
      for (int unsigned w = 0; w < NUM_WAYS; w++)
        if (io_write_way_mask[w])
          data_mem[touch_idx][w] <= io_write_data[w];
    end
  end

  // ---------------------------------------------------------------------------
  // valids / ever_written 维护
  // ---------------------------------------------------------------------------
  // ever_written 恒需维护(io_hit 用它屏蔽上电假命中)。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                         ever_written <= '0;
    else if (io_wen && !hit)           ever_written[enq_idx] <= 1'b1;
  end

  // ---------------------------------------------------------------------------
  // 输出
  // ---------------------------------------------------------------------------
  assign io_hit = hit;

  always_comb begin
    for (int unsigned w = 0; w < NUM_WAYS; w++)
      io_hit_data_bits[w] = data_mem[hit_idx][w];
  end

  // 逐路有效位: 仅上层消费时(TRACK_HIT_VALID)才建 valids 寄存器并驱动 io_hit_data_valid;
  // 否则(如 WrBypass_41/43 golden 裁剪了该输出)不建寄存器, 输出直接 '0(悬空/不比较)。
  if (TRACK_HIT_VALID) begin : g_hit_valid
    logic [NUM_ENTRIES-1:0][NUM_WAYS-1:0] valids;
    always_ff @(posedge clock or posedge reset) begin
      if (reset) valids <= '0;
      else if (io_wen) begin
        if (hit) begin
          for (int unsigned w = 0; w < NUM_WAYS; w++)
            if (io_write_way_mask[w]) valids[hit_idx][w] <= 1'b1;   // 命中: 仅置本次写入的路
        end else begin
          for (int unsigned w = 0; w < NUM_WAYS; w++)
            valids[enq_idx][w] <= io_write_way_mask[w];             // 新占用: 按掩码重置整条目
        end
      end
    end
    always_comb begin
      for (int unsigned w = 0; w < NUM_WAYS; w++) begin
        io_hit_data_valid[w] = 1'b0;
        for (int unsigned i = 0; i < NUM_ENTRIES; i++)
          if (hits_oh[i] && valids[i][w]) io_hit_data_valid[w] = 1'b1;
      end
    end
  end else begin : g_no_hit_valid
    assign io_hit_data_valid = '0;
  end

endmodule
