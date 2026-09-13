// 负测台：证明 xs_ICacheMSHR_core 的块地址拼接等式真会拦下"块大小抄错"。
// 下面是 ICacheMSHR_4 薄文件的复制品，唯一改动：OFFSET_W 从 6（64B 块）抄成 5。
// 端口表、连线一字未改，逻辑也"看起来对"——只是 Acquire 地址低位少填一个 0，
// 单看重写件永远发现不了。期望：PORT_ACQ_ADDR_W(48) != 42+5，time 0 $fatal。
module neg_mshr_wrong_blocksize(
  input         clock,
  input         reset,
  input         io_fencei,
  input         io_flush,
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
  localparam int unsigned OFFSET_W    = 5;   // <-- 抄错：块是 64B，偏移应为 6 位
  localparam int unsigned NUM_LOOKUPS = 2;

  xs_ICacheMSHR_core #(
    .BLK_PADDR_W     (BLK_PADDR_W),
    .VSETIDX_W       (VSETIDX_W),
    .WAY_W           (WAY_W),
    .OFFSET_W        (OFFSET_W),
    .NUM_LOOKUPS     (NUM_LOOKUPS),
    .HAS_FLUSH       (1'b1),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_ACQ_ADDR_W ($bits(io_acquire_bits_acquire_address)),
    .PORT_BITS_LOOKUP($bits({io_lookUps_0_info_bits_blkPaddr, io_lookUps_0_info_bits_vSetIdx,
                             io_lookUps_1_info_bits_blkPaddr, io_lookUps_1_info_bits_vSetIdx})),
    .PORT_BITS_RESP  ($bits({io_resp_bits_blkPaddr, io_resp_bits_vSetIdx, io_resp_bits_way})),
    .GOLDEN_PORTS    (26)
  ) u_core (
    .clock            (clock),
    .reset            (reset),
    .fencei           (io_fencei),
    .flush            (io_flush),
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

module neg_tb;
  bit clock = 0;
  wire w_safe, w_rdy, w_avalid, w_h0, w_h1, w_rvalid;
  wire [47:0] w_aaddr;
  wire [7:0]  w_avset, w_rvset;
  wire [41:0] w_rpaddr;
  wire [1:0]  w_rway;
  neg_mshr_wrong_blocksize u_dut (
    .clock(clock), .reset(1'b1), .io_fencei(1'b0), .io_flush(1'b0),
    .io_wfi_wfiReq(1'b0), .io_wfi_wfiSafe(w_safe), .io_invalid(1'b0),
    .io_req_ready(w_rdy), .io_req_valid(1'b0), .io_req_bits_blkPaddr(42'h0),
    .io_req_bits_vSetIdx(8'h0), .io_acquire_ready(1'b0), .io_acquire_valid(w_avalid),
    .io_acquire_bits_acquire_address(w_aaddr), .io_acquire_bits_vSetIdx(w_avset),
    .io_lookUps_0_info_bits_blkPaddr(42'h0), .io_lookUps_0_info_bits_vSetIdx(8'h0),
    .io_lookUps_0_hit(w_h0),
    .io_lookUps_1_info_bits_blkPaddr(42'h0), .io_lookUps_1_info_bits_vSetIdx(8'h0),
    .io_lookUps_1_hit(w_h1),
    .io_resp_valid(w_rvalid), .io_resp_bits_blkPaddr(w_rpaddr),
    .io_resp_bits_vSetIdx(w_rvset), .io_resp_bits_way(w_rway), .io_victimWay(2'h0)
  );
  initial begin
    #10;
    $display("NEGTEST_UNREACHED: 不变式没有拦下块大小抄错");
    $finish;
  end
endmodule
