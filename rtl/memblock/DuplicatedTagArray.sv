// =============================================================================
// xs_DuplicatedTagArray_core —— DCache 多副本 Tag 阵列（可读重写核）
// -----------------------------------------------------------------------------
// 对应 Chisel: xiangshan.cache.TagArray.scala  class DuplicatedTagArray(readPorts)
//
// 在 DCache 中的位置：
//   DCache 需要同时被多条流水查 tag——LoadPipe 有多条 load 通道、MainPipe 有
//   replace/probe/store 等通道，它们在同一拍都要读 tag 判命中。单口 tag SRAM 无法
//   多读，于是把整张 tag 表**复制 readPorts 份**（本配置 4 份），每份 = 一个 TagArray，
//   各自带一套读口，从而 readPorts 条流水可并行无冲突地读 tag。
//
//   · 读：第 i 条流水的读请求 read[i] 只送到第 i 份副本 array[i]，其 resp 即第 i 路结果。
//   · 写（refill 填入新 tag）：必须**同时写进全部 4 份副本**，保证多份内容一致。
//   · 4 份副本存的是**同一张 256 组 × 4 路的 tag 表**，差异仅在“谁来读”。
//
// 本核负责的“设计逻辑”（其余存储体/ DFT 为 golden 黑盒）：
//   1) 写入时计算 Tag 的 SECDED 校验码（7bit），与 36bit tag 拼成 43bit encTag；
//   2) 把写请求（idx/way_en/encTag）扇出到全部副本；
//   3) 把每个读端口路由到对应副本，并把副本的 resp 透传回对应输出口；
//   4) 暴露 readPorts 份 TagArray 黑盒接口（wrapper 例化 golden TagArray 后回连）。
//
// TagArray 黑盒内部（仅作背景，不在本核实现）：
//   每个 TagArray = nWays/DCacheWayDiv = 2 个 TagSRAMBank，每 bank 管 DCacheWayDiv=2 路；
//   bank 内是单口 SRAMTemplate（深 256、宽 43），上电有逐组清零（rst_cnt）。
//   读延迟 1 拍：本核给出 read_valid/idx，下一拍 resp 出现在 tarr_resp。
//
// 注意端口裁剪（firtool 死代码消除的结果，需对齐）：
//   · 只有读端口 3 的 ready 被引出为 io_read_3_ready（其余副本 ready 上层不用）。
//   · 写口的 ready 恒 true，golden 顶层未引出端口（被裁掉）。
// =============================================================================
module xs_DuplicatedTagArray_core import dtagarray_pkg::*; (
  input  logic                       clock,
  input  logic                       reset,

  // ---- 读端口：READ_PORTS 条流水，各自一套 valid/idx ----
  input  logic                       io_read_valid [READ_PORTS],
  input  logic [IDX_W-1:0]           io_read_idx   [READ_PORTS],
  output logic                       io_read3_ready,              // 仅副本 3 的 ready 引出

  // ---- 读结果：每端口 N_WAYS 路 encTag（43bit），SRAM 同步读、晚 1 拍 ----
  output logic [ENC_TAG_W-1:0]       io_resp [READ_PORTS][N_WAYS],

  // ---- 写口（refill）：写一组的某些 way ----
  input  logic                       io_write_valid,
  input  logic [IDX_W-1:0]           io_write_idx,
  input  logic [N_WAYS-1:0]          io_write_way_en,
  input  logic [TAG_W-1:0]           io_write_tag,

  // ---- 与 READ_PORTS 份 TagArray 黑盒的接口（wrapper 例化后回连）----
  // 读
  output logic                       tarr_read_valid [READ_PORTS],
  output logic [IDX_W-1:0]           tarr_read_idx   [READ_PORTS],
  input  logic                       tarr_read_ready [READ_PORTS],
  input  logic [ENC_TAG_W-1:0]       tarr_resp       [READ_PORTS][N_WAYS],
  // 写（全副本同写）
  output logic                       tarr_write_valid  [READ_PORTS],
  output logic [IDX_W-1:0]           tarr_write_idx    [READ_PORTS],
  output logic [N_WAYS-1:0]          tarr_write_way_en [READ_PORTS],
  output logic [TAG_W-1:0]           tarr_write_tag    [READ_PORTS],
  output logic [ECC_W-1:0]           tarr_write_ecc    [READ_PORTS]
);

  // ---------------------------------------------------------------------------
  // 写入：在顶层统一算一次 Tag ECC，再扇出给全部副本（保证各副本一致）
  // ---------------------------------------------------------------------------
  logic [ECC_W-1:0] write_ecc;
  always_comb write_ecc = tag_ecc_encode(io_write_tag);

  // ---------------------------------------------------------------------------
  // 副本路由：读各走各的副本；写广播到全部副本；resp 透传回对应端口
  // ---------------------------------------------------------------------------
  for (genvar p = 0; p < READ_PORTS; p++) begin : g_copy
    always_comb begin
      // 读：端口 p → 副本 p
      tarr_read_valid[p] = io_read_valid[p];
      tarr_read_idx[p]   = io_read_idx[p];
      // 写：广播（idx/way_en/tag/ecc 各副本相同）
      tarr_write_valid[p]  = io_write_valid;
      tarr_write_idx[p]    = io_write_idx;
      tarr_write_way_en[p] = io_write_way_en;
      tarr_write_tag[p]    = io_write_tag;
      tarr_write_ecc[p]    = write_ecc;
      // 读结果透传
      for (int w = 0; w < N_WAYS; w++)
        io_resp[p][w] = tarr_resp[p][w];
    end
  end

  // 只有副本 3 的读 ready 对外引出
  always_comb io_read3_ready = tarr_read_ready[READ_PORTS-1];

endmodule
