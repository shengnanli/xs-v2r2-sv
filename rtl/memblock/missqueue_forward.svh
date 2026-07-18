// =============================================================================
//  missqueue_forward.svh —— 3 路 load forward（被 xs_MissQueue_core 内联）
// -----------------------------------------------------------------------------
//  Load 命中某在途 MSHR（mshrid）时，可直接从该 MSHR 已 refill 回的 raw_data 前递 128bit，
//  不必等整行写回 DCache。每路 forward 给 (mshrid, paddr)，本队列：
//    forward_result_valid = RegNext( valid & inflight[mshrid] & paddr.block==entry[mshrid].paddr.block )
//    forward_mshr        = RegNext( paddr[5] ? lastbeat_valid[mshrid] : firstbeat_valid[mshrid] )
//    forwardData[16B]    = RegNext( 取 raw_data[mshrid] 里 paddr[5:3] 起的 2 个 64bit 字 )
//                          低 64bit = beat[paddr[5:3]]；高 64bit = paddr[3]? 同字 : beat[paddr[5:3]+1]
//    corrupt             = RegNext( corrupt[mshrid] )
//  全部输出打一拍（与 golden 的 *_REG 一致）。用 function 抽取「按 mshrid 选 entry 字段」。
//  paddr 用窄位（block = paddr[47:6]），mshrid 4 位（0..15）。
// =============================================================================

// per-port「下一拍」组合值
logic [LD_WIDTH-1:0]   fwd_valid_n;
logic [LD_WIDTH-1:0]   fwd_mshr_n;
logic [127:0]          fwd_data_n  [LD_WIDTH];
logic [LD_WIDTH-1:0]   fwd_corr_n;

// 端口聚合
logic [3:0]            fwd_mshrid [LD_WIDTH];
logic [PADDR_BITS-1:0] fwd_pa     [LD_WIDTH];
logic [LD_WIDTH-1:0]   fwd_in_valid;
always_comb begin
  fwd_mshrid[0]=io_forward_0_mshrid; fwd_pa[0]=io_forward_0_paddr; fwd_in_valid[0]=io_forward_0_valid;
  fwd_mshrid[1]=io_forward_1_mshrid; fwd_pa[1]=io_forward_1_paddr; fwd_in_valid[1]=io_forward_1_valid;
  fwd_mshrid[2]=io_forward_2_mshrid; fwd_pa[2]=io_forward_2_paddr; fwd_in_valid[2]=io_forward_2_valid;
end

// ⚠ 坑：直接在 always_comb 里索引模块级 forwardInfo 数组（不要封进读模块信号的 function——
//   那样敏感表抓不到数组变化）。取 mshrid 的 inflight/first/last/corrupt/paddr，并拼 128bit
//   前递数据：低 64bit = beat[paddr[5:3]]；高 64bit = paddr[3]?同字:下一 beat。
always_comb
  for (int k = 0; k < LD_WIDTH; k++) begin
    automatic logic [3:0] m   = fwd_mshrid[k];
    automatic logic [2:0] off = fwd_pa[k][5:3];
    automatic logic [63:0] lo = e_fwd_raw[m][off];
    automatic logic [63:0] hi = fwd_pa[k][3] ? lo : e_fwd_raw[m][3'(off + 3'h1)];
    fwd_valid_n[k] = fwd_in_valid[k] & e_fwd_inflight[m]
                   & (fwd_pa[k][PADDR_BITS-1:6] == e_fwd_paddr[m][PADDR_BITS-1:6]);
    fwd_mshr_n[k]  = fwd_pa[k][5] ? e_fwd_lastbeat[m] : e_fwd_firstbeat[m];
    fwd_data_n[k]  = {hi, lo};
    fwd_corr_n[k]  = e_fwd_corrupt[m];
  end

// 打一拍寄存。复位风格严格对齐 golden：
//   forwardData_* / forward_mshr_* 在 golden 异步复位块内（reset 清 0）；
//   io_forward_N_forward_result_valid_REG / corrupt_REG 在无复位 always @(posedge clock) 块。
logic [LD_WIDTH-1:0] fwd_valid_q, fwd_mshr_q, fwd_corr_q;
logic [127:0]        fwd_data_q [LD_WIDTH];
always_ff @(posedge clock or posedge reset) begin
  if (reset) begin
    fwd_mshr_q <= '0;
    for (int k = 0; k < LD_WIDTH; k++) fwd_data_q[k] <= '0;
  end else begin
    fwd_mshr_q  <= fwd_mshr_n;
    for (int k = 0; k < LD_WIDTH; k++) fwd_data_q[k] <= fwd_data_n[k];
  end
end
always_ff @(posedge clock) begin   // golden 无复位
  fwd_valid_q <= fwd_valid_n;
  fwd_corr_q  <= fwd_corr_n;
end

// 拆回扁平输出（forwardData 16 字节）
assign io_forward_0_forward_result_valid = fwd_valid_q[0];
assign io_forward_0_forward_mshr         = fwd_mshr_q[0];
assign io_forward_0_corrupt              = fwd_corr_q[0];
assign io_forward_1_forward_result_valid = fwd_valid_q[1];
assign io_forward_1_forward_mshr         = fwd_mshr_q[1];
assign io_forward_1_corrupt              = fwd_corr_q[1];
assign io_forward_2_forward_result_valid = fwd_valid_q[2];
assign io_forward_2_forward_mshr         = fwd_mshr_q[2];
assign io_forward_2_corrupt              = fwd_corr_q[2];

// forwardData：16 字节逐字节拆到扁平端口（端口名扁平，无法用 generate 下标，故显式列出）。
assign {io_forward_0_forwardData_15, io_forward_0_forwardData_14, io_forward_0_forwardData_13,
        io_forward_0_forwardData_12, io_forward_0_forwardData_11, io_forward_0_forwardData_10,
        io_forward_0_forwardData_9,  io_forward_0_forwardData_8,  io_forward_0_forwardData_7,
        io_forward_0_forwardData_6,  io_forward_0_forwardData_5,  io_forward_0_forwardData_4,
        io_forward_0_forwardData_3,  io_forward_0_forwardData_2,  io_forward_0_forwardData_1,
        io_forward_0_forwardData_0} = fwd_data_q[0];
assign {io_forward_1_forwardData_15, io_forward_1_forwardData_14, io_forward_1_forwardData_13,
        io_forward_1_forwardData_12, io_forward_1_forwardData_11, io_forward_1_forwardData_10,
        io_forward_1_forwardData_9,  io_forward_1_forwardData_8,  io_forward_1_forwardData_7,
        io_forward_1_forwardData_6,  io_forward_1_forwardData_5,  io_forward_1_forwardData_4,
        io_forward_1_forwardData_3,  io_forward_1_forwardData_2,  io_forward_1_forwardData_1,
        io_forward_1_forwardData_0} = fwd_data_q[1];
assign {io_forward_2_forwardData_15, io_forward_2_forwardData_14, io_forward_2_forwardData_13,
        io_forward_2_forwardData_12, io_forward_2_forwardData_11, io_forward_2_forwardData_10,
        io_forward_2_forwardData_9,  io_forward_2_forwardData_8,  io_forward_2_forwardData_7,
        io_forward_2_forwardData_6,  io_forward_2_forwardData_5,  io_forward_2_forwardData_4,
        io_forward_2_forwardData_3,  io_forward_2_forwardData_2,  io_forward_2_forwardData_1,
        io_forward_2_forwardData_0} = fwd_data_q[2];
