// =============================================================================
// ICacheMSHR_1 —— 指令缓存单条 MSHR（xs_ICacheMSHR_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   角色：ICacheMissUnit 的取指 MSHR，实例名 fetchMSHRs_1（共 4 格）；
//   端口 25 个 = 19 个固定端口（无 io_flush） + 2 个查询口 ×3 根；
//   位宽：块物理地址 42b、虚 set 索引 8b、way 2b、
//         Acquire 地址 48b = 42b 块地址 + 6b 块内偏移（64B 块）；
//   golden 模块体 = 7 个异步复位寄存器 + 纯组合输出，无数组 / 无子模块。
//   HAS_FLUSH = 0：取指 MSHR 只认 fencei，核的 flush 输入接 1'b0。
//
// 家族事实（机械比对，不是猜的）：G1 的 14 个 ICacheMSHR 归一化模块名后只剩
//   **两种**模块体——4 个取指变体互为逐字节副本，10 个预取变体互为逐字节
//   副本，两组之间只差一条 io_flush 端口及其参与的三处表达式。所有位宽 14 个
//   变体完全一致，所以这不是"同核不同参"，而是"同一份逻辑被单态化复制 14 份"。
//
// 结构：golden 同名端口表 -> 设参例化 xs_ICacheMSHR_core（状态机与不变式都在
//   xs_ICacheMSHR_core.sv 里讲）。本层只做端口改名与两个查询口的打包。
// 自动生成：verif/ut/ICacheMSHR/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module ICacheMSHR_1(
  input         clock,
  input         reset,
  input         io_fencei,
  input         io_wfi_wfiReq,
  output        io_wfi_wfiSafe,
  input         io_invalid,
  output        io_req_ready,
  input         io_req_valid,
  input  [41:0] io_req_bits_blkPaddr,
  input  [7:0]  io_req_bits_vSetIdx,
  input         io_acquire_ready,
  output        io_acquire_valid,
  output [47:0] io_acquire_bits_acquire_address,
  output [7:0]  io_acquire_bits_vSetIdx,
  input  [41:0] io_lookUps_0_info_bits_blkPaddr,
  input  [7:0]  io_lookUps_0_info_bits_vSetIdx,
  output        io_lookUps_0_hit,
  input  [41:0] io_lookUps_1_info_bits_blkPaddr,
  input  [7:0]  io_lookUps_1_info_bits_vSetIdx,
  output        io_lookUps_1_hit,
  output        io_resp_valid,
  output [41:0] io_resp_bits_blkPaddr,
  output [7:0]  io_resp_bits_vSetIdx,
  output [1:0]  io_resp_bits_way,
  input  [1:0]  io_victimWay
);

  localparam int unsigned BLK_PADDR_W = 42;
  localparam int unsigned VSETIDX_W   = 8;
  localparam int unsigned WAY_W       = 2;
  localparam int unsigned OFFSET_W    = 6;
  localparam int unsigned NUM_LOOKUPS = 2;

  xs_ICacheMSHR_core #(
    .BLK_PADDR_W     (BLK_PADDR_W),
    .VSETIDX_W       (VSETIDX_W),
    .WAY_W           (WAY_W),
    .OFFSET_W        (OFFSET_W),
    .NUM_LOOKUPS     (NUM_LOOKUPS),
    .HAS_FLUSH       (1'b0),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_ACQ_ADDR_W ($bits(io_acquire_bits_acquire_address)),
    .PORT_BITS_LOOKUP($bits({io_lookUps_0_info_bits_blkPaddr, io_lookUps_0_info_bits_vSetIdx,
                             io_lookUps_1_info_bits_blkPaddr, io_lookUps_1_info_bits_vSetIdx})),
    .PORT_BITS_RESP  ($bits({io_resp_bits_blkPaddr, io_resp_bits_vSetIdx, io_resp_bits_way})),
    .GOLDEN_PORTS    (25)
  ) u_core (
    .clock            (clock),
    .reset            (reset),
    .fencei           (io_fencei),
    .flush            (1'b0            /* 取指 MSHR 的 golden 没有 io_flush 端口，恒 0 */),
    .wfi_req          (io_wfi_wfiReq),
    .wfi_safe         (io_wfi_wfiSafe),
    .invalid          (io_invalid),
    .req_ready        (io_req_ready),
    .req_valid        (io_req_valid),
    .req_blk_paddr    (io_req_bits_blkPaddr),
    .req_vset_idx     (io_req_bits_vSetIdx),
    .acquire_ready    (io_acquire_ready),
    .acquire_valid    (io_acquire_valid),
    .acquire_address  (io_acquire_bits_acquire_address),
    .acquire_vset_idx (io_acquire_bits_vSetIdx),
    // 查询口按 {口1, 口0} 拼接：核里的数组下标 0 就是 golden 的 lookUps_0
    .lookup_blk_paddr ({io_lookUps_1_info_bits_blkPaddr, io_lookUps_0_info_bits_blkPaddr}),
    .lookup_vset_idx  ({io_lookUps_1_info_bits_vSetIdx,  io_lookUps_0_info_bits_vSetIdx}),
    .lookup_hit       ({io_lookUps_1_hit,                io_lookUps_0_hit}),
    .resp_valid       (io_resp_valid),
    .resp_blk_paddr   (io_resp_bits_blkPaddr),
    .resp_vset_idx    (io_resp_bits_vSetIdx),
    .resp_way         (io_resp_bits_way),
    .victim_way       (io_victimWay)
  );

endmodule
