// =============================================================================
//  CLINT —— RISC-V 核内中断控制器 (可读重写核 xs_CLINT_core)
// -----------------------------------------------------------------------------
//  功能 (源自 rocket-chip devices/tilelink/CLINT.scala，单 hart、intStages=0)：
//    1) mtime  : 64 位实时计数器，io_rtcTick 每个有效拍 +1；TileLink 可写覆盖
//    2) mtimecmp: 64 位定时比较值；time >= mtimecmp 时拉高 mtip (int_out_1)
//    3) msip/ipi: 1 位软件中断挂起位，软件写 1 触发软件中断 (int_out_0)
//
//  TileLink 行为 (本设备由 RegisterRouter 综合得到的简化模型)：
//    * 本设备无背压，A 一进即同拍出 D：a_ready = d_ready，d_valid = a_valid
//    * D 的 opcode/size/source 直接回传请求；读时 opcode=AccessAckData(=1)，
//      写时 opcode=AccessAck(=0)
//    * 写按字节选通 (mask) 生效；本核不解析 size/burst
//
//  本核为纯组合+寄存器叶子，无子模块、无 SRAM。寄存器：
//    mtime / mtimecmp / ipi  —— 状态；  time_valid_q —— rtcTick 打一拍
// =============================================================================
module xs_CLINT_core
  import clint_pkg::*;
(
  input  logic                          clock,
  input  logic                          reset,

  // 对外中断输出 (intStages=0，组合直出)
  output logic                          auto_int_out_0,  // msip  (软件中断)
  output logic                          auto_int_out_1,  // mtip  (定时中断)

  // TileLink slave A 通道 (请求)
  output logic                          auto_in_a_ready,
  input  logic                          auto_in_a_valid,
  input  logic [3:0]                    auto_in_a_bits_opcode,
  input  logic [1:0]                    auto_in_a_bits_size,
  input  logic [CLINT_SOURCE_BITS-1:0]  auto_in_a_bits_source,
  input  logic [CLINT_ADDR_BITS-1:0]    auto_in_a_bits_address,
  input  logic [CLINT_MASK_BITS-1:0]    auto_in_a_bits_mask,
  input  logic [CLINT_DATA_BITS-1:0]    auto_in_a_bits_data,

  // TileLink slave D 通道 (响应)
  input  logic                          auto_in_d_ready,
  output logic                          auto_in_d_valid,
  output logic [3:0]                    auto_in_d_bits_opcode,
  output logic [1:0]                    auto_in_d_bits_size,
  output logic [CLINT_SOURCE_BITS-1:0]  auto_in_d_bits_source,
  output logic [CLINT_DATA_BITS-1:0]    auto_in_d_bits_data,

  // 实时时钟节拍输入 + mtime 旁路输出
  input  logic                          io_rtcTick,
  output logic                          io_time_valid,
  output logic [CLINT_TIME_BITS-1:0]    io_time_bits
);

  // ===========================================================================
  //  状态寄存器
  // ===========================================================================
  logic [CLINT_TIME_BITS-1:0] mtime;        // golden: time_0
  logic [CLINT_TIME_BITS-1:0] mtimecmp;     // golden: pad
  logic                       ipi;          // golden: ipi_0 (msip bit0)
  logic                       time_valid_q; // golden: io_time_valid_REG

  // ===========================================================================
  //  请求解码
  // ===========================================================================
  // 是否为读 (Get)；其余 opcode 视为写
  wire is_read = (auto_in_a_bits_opcode == TL_A_GET);
  // 一次写事务真正落地的公共条件：A 有效、D 可收、且不是读
  wire write_fire = auto_in_a_valid & auto_in_d_ready & ~is_read;

  // 区内 8 字节槽 0 (offset 低 14 位的 [13:3] 全 0)
  wire slot_zero = (auto_in_a_bits_address[13:3] == 11'h0);
  // mtime 槽：0xbff8 的 [13:3] 为 11 位全 1
  wire slot_time = (&auto_in_a_bits_address[13:3]);

  // 各寄存器写命中 (region 解码)
  wire wr_timecmp = write_fire & (auto_in_a_bits_address[15:14] == REGION_TIMECMP) & slot_zero;
  wire wr_time    = write_fire & (auto_in_a_bits_address[15:14] == REGION_TIME)    & slot_time;
  wire wr_msip    = write_fire & (auto_in_a_bits_address[15:14] == REGION_MSIP)    & slot_zero;

  // 按字节选通：第 b 字节是否本拍要写
  wire [CLINT_MASK_BITS-1:0] timecmp_byte_we = {CLINT_MASK_BITS{wr_timecmp}} & auto_in_a_bits_mask;
  wire [CLINT_MASK_BITS-1:0] time_byte_we    = {CLINT_MASK_BITS{wr_time}}    & auto_in_a_bits_mask;

  // ===========================================================================
  //  逐字节写入辅助函数：对 64 位寄存器按 8 个字节选通做 RMW
  // ===========================================================================
  function automatic logic [CLINT_TIME_BITS-1:0] byte_write(
      input logic [CLINT_TIME_BITS-1:0] old_val,
      input logic [CLINT_DATA_BITS-1:0] new_val,
      input logic [CLINT_MASK_BITS-1:0] byte_we);
    logic [CLINT_TIME_BITS-1:0] r;
    for (int b = 0; b < CLINT_MASK_BITS; b++)
      r[b*8 +: 8] = byte_we[b] ? new_val[b*8 +: 8] : old_val[b*8 +: 8];
    return r;
  endfunction

  // ===========================================================================
  //  时序：mtime / mtimecmp / ipi / time_valid
  // ===========================================================================
  // mtime 与 ipi 带异步复位 (golden 用 posedge reset)
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      mtime <= '0;
      ipi   <= 1'b0;
    end else begin
      // 写优先于 rtcTick：本拍有字节写则 RMW，否则 rtcTick 时自增
      if (|time_byte_we)
        mtime <= byte_write(mtime, auto_in_a_bits_data, time_byte_we);
      else if (io_rtcTick)
        mtime <= mtime + 64'h1;

      if (wr_msip & auto_in_a_bits_mask[0])
        ipi <= auto_in_a_bits_data[0];
    end
  end

  // mtimecmp 与 time_valid 无复位 (golden 仅 posedge clock)
  always_ff @(posedge clock) begin
    if (|timecmp_byte_we)
      mtimecmp <= byte_write(mtimecmp, auto_in_a_bits_data, timecmp_byte_we);
    time_valid_q <= io_rtcTick;
  end

  // ===========================================================================
  //  读数据多路选择
  // -----------------------------------------------------------------------------
  //  read_hit[region] 表示该区域当前地址是否落在合法读槽上 (region 3 恒 1，
  //  与 golden _GEN 完全一致)；read_data 给出各区域返回值。未命中返回 0。
  // ===========================================================================
  logic [3:0]                    read_hit;
  logic [3:0][CLINT_DATA_BITS-1:0] read_data;
  always_comb begin
    read_hit[REGION_MSIP]    = slot_zero;   // msip 区：槽 0 命中
    read_hit[REGION_TIMECMP] = slot_zero;   // mtimecmp 区：槽 0 命中
    read_hit[REGION_TIME]    = slot_time;   // mtime 区：全 1 槽命中
    read_hit[3]              = 1'b1;         // 保留区：恒命中 (返回 0)

    read_data[REGION_MSIP]    = {{(CLINT_DATA_BITS-1){1'b0}}, ipi};
    read_data[REGION_TIMECMP] = mtimecmp;
    read_data[REGION_TIME]    = mtime;
    read_data[3]              = '0;
  end

  wire [1:0] rd_region = auto_in_a_bits_address[15:14];

  // ===========================================================================
  //  输出
  // ===========================================================================
  assign auto_int_out_0      = ipi;                  // msip
  assign auto_int_out_1      = (mtime >= mtimecmp);  // mtip

  assign auto_in_a_ready     = auto_in_d_ready;      // 无内部背压
  assign auto_in_d_valid     = auto_in_a_valid;
  assign auto_in_d_bits_opcode = {3'h0, is_read};    // 读=AccessAckData(1)，写=AccessAck(0)
  assign auto_in_d_bits_size   = auto_in_a_bits_size;
  assign auto_in_d_bits_source = auto_in_a_bits_source;
  assign auto_in_d_bits_data   = read_hit[rd_region] ? read_data[rd_region] : '0;

  assign io_time_valid       = time_valid_q;
  assign io_time_bits        = mtime;

endmodule
