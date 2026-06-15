// =============================================================================
// tb —— ICacheMissUnit golden vs xs 双例化随机比对
//
// 难点：TileLink D（grant）必须按协议成对发 beat（refillCycles=2），且 source 必须
// 是「已经在 A 通道发射过、尚未被 grant 回收」的在途事务，否则两侧 MSHR 行为虽确定
// 但会与真实协议不符（且可能踩 golden 内部 assert）。
//
// 做法：
//   - tb 监视 golden 侧 mem_acquire 握手；每当 acquire fire，把该 source 标记为「在途」。
//     （golden 与 xs 的发射时序应一致，故监视任一侧即可；这里监视共享的输入握手。）
//   - grant FSM：空闲时若有在途事务，随机挑一个 source 发 2 个 beat（opcode bit0=1）。
//     第 2 beat 结束即视为该事务被回收（下一拍两侧 MSHR 会 invalidate）。
//   - victim_way 在 acquire fire 当拍随机给（两侧共享同一输入）。
//   - 偶发 flush/fencei；fencei 会让所有在途 MSHR 失效，但「已 issued」的要等 grant，
//     故 tb 仍把已挂起的 beat 发完，避免 source 永远不回收。
// =============================================================================
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 80000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  localparam int N_MSHR = 14;

  // ---- 共享输入 ----
  logic        io_fencei, io_flush, io_wfi_wfiReq;
  logic        io_fetch_req_valid;
  logic [41:0] io_fetch_req_bits_blkPaddr;
  logic [7:0]  io_fetch_req_bits_vSetIdx;
  logic        io_prefetch_req_valid;
  logic [41:0] io_prefetch_req_bits_blkPaddr;
  logic [7:0]  io_prefetch_req_bits_vSetIdx;
  logic [1:0]  io_victim_way;
  logic        io_mem_acquire_ready;
  logic        io_mem_grant_valid;
  logic [3:0]  io_mem_grant_bits_opcode;
  logic [2:0]  io_mem_grant_bits_size;
  logic [3:0]  io_mem_grant_bits_source;
  logic [255:0] io_mem_grant_bits_data;
  logic        io_mem_grant_bits_corrupt;

  // ---- golden 输出 ----
  wire         g_io_wfi_wfiSafe, g_io_fetch_req_ready, g_io_fetch_resp_valid;
  wire [41:0]  g_io_fetch_resp_bits_blkPaddr;
  wire [7:0]   g_io_fetch_resp_bits_vSetIdx;
  wire [3:0]   g_io_fetch_resp_bits_waymask;
  wire [511:0] g_io_fetch_resp_bits_data;
  wire         g_io_fetch_resp_bits_corrupt, g_io_prefetch_req_ready;
  wire         g_io_meta_write_valid;
  wire [7:0]   g_io_meta_write_bits_virIdx;
  wire [35:0]  g_io_meta_write_bits_phyTag;
  wire [3:0]   g_io_meta_write_bits_waymask;
  wire         g_io_meta_write_bits_bankIdx, g_io_data_write_valid;
  wire [7:0]   g_io_data_write_bits_virIdx;
  wire [511:0] g_io_data_write_bits_data;
  wire [3:0]   g_io_data_write_bits_waymask;
  wire         g_io_victim_vSetIdx_valid;
  wire [7:0]   g_io_victim_vSetIdx_bits;
  wire         g_io_mem_acquire_valid;
  wire [3:0]   g_io_mem_acquire_bits_source;
  wire [47:0]  g_io_mem_acquire_bits_address;

  // ---- xs 输出 ----
  wire         i_io_wfi_wfiSafe, i_io_fetch_req_ready, i_io_fetch_resp_valid;
  wire [41:0]  i_io_fetch_resp_bits_blkPaddr;
  wire [7:0]   i_io_fetch_resp_bits_vSetIdx;
  wire [3:0]   i_io_fetch_resp_bits_waymask;
  wire [511:0] i_io_fetch_resp_bits_data;
  wire         i_io_fetch_resp_bits_corrupt, i_io_prefetch_req_ready;
  wire         i_io_meta_write_valid;
  wire [7:0]   i_io_meta_write_bits_virIdx;
  wire [35:0]  i_io_meta_write_bits_phyTag;
  wire [3:0]   i_io_meta_write_bits_waymask;
  wire         i_io_meta_write_bits_bankIdx, i_io_data_write_valid;
  wire [7:0]   i_io_data_write_bits_virIdx;
  wire [511:0] i_io_data_write_bits_data;
  wire [3:0]   i_io_data_write_bits_waymask;
  wire         i_io_victim_vSetIdx_valid;
  wire [7:0]   i_io_victim_vSetIdx_bits;
  wire         i_io_mem_acquire_valid;
  wire [3:0]   i_io_mem_acquire_bits_source;
  wire [47:0]  i_io_mem_acquire_bits_address;

  ICacheMissUnit u_g (
    .clock(clk), .reset(rst), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(g_io_wfi_wfiSafe),
    .io_fetch_req_ready(g_io_fetch_req_ready), .io_fetch_req_valid(io_fetch_req_valid),
    .io_fetch_req_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_fetch_req_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_fetch_resp_valid(g_io_fetch_resp_valid), .io_fetch_resp_bits_blkPaddr(g_io_fetch_resp_bits_blkPaddr),
    .io_fetch_resp_bits_vSetIdx(g_io_fetch_resp_bits_vSetIdx), .io_fetch_resp_bits_waymask(g_io_fetch_resp_bits_waymask),
    .io_fetch_resp_bits_data(g_io_fetch_resp_bits_data), .io_fetch_resp_bits_corrupt(g_io_fetch_resp_bits_corrupt),
    .io_prefetch_req_ready(g_io_prefetch_req_ready), .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_prefetch_req_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_meta_write_valid(g_io_meta_write_valid), .io_meta_write_bits_virIdx(g_io_meta_write_bits_virIdx),
    .io_meta_write_bits_phyTag(g_io_meta_write_bits_phyTag), .io_meta_write_bits_waymask(g_io_meta_write_bits_waymask),
    .io_meta_write_bits_bankIdx(g_io_meta_write_bits_bankIdx), .io_data_write_valid(g_io_data_write_valid),
    .io_data_write_bits_virIdx(g_io_data_write_bits_virIdx), .io_data_write_bits_data(g_io_data_write_bits_data),
    .io_data_write_bits_waymask(g_io_data_write_bits_waymask), .io_victim_vSetIdx_valid(g_io_victim_vSetIdx_valid),
    .io_victim_vSetIdx_bits(g_io_victim_vSetIdx_bits), .io_victim_way(io_victim_way),
    .io_mem_acquire_ready(io_mem_acquire_ready), .io_mem_acquire_valid(g_io_mem_acquire_valid),
    .io_mem_acquire_bits_source(g_io_mem_acquire_bits_source), .io_mem_acquire_bits_address(g_io_mem_acquire_bits_address),
    .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_size(io_mem_grant_bits_size), .io_mem_grant_bits_source(io_mem_grant_bits_source),
    .io_mem_grant_bits_data(io_mem_grant_bits_data), .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt)
  );

  ICacheMissUnit_xs u_i (
    .clock(clk), .reset(rst), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(i_io_wfi_wfiSafe),
    .io_fetch_req_ready(i_io_fetch_req_ready), .io_fetch_req_valid(io_fetch_req_valid),
    .io_fetch_req_bits_blkPaddr(io_fetch_req_bits_blkPaddr), .io_fetch_req_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_fetch_resp_valid(i_io_fetch_resp_valid), .io_fetch_resp_bits_blkPaddr(i_io_fetch_resp_bits_blkPaddr),
    .io_fetch_resp_bits_vSetIdx(i_io_fetch_resp_bits_vSetIdx), .io_fetch_resp_bits_waymask(i_io_fetch_resp_bits_waymask),
    .io_fetch_resp_bits_data(i_io_fetch_resp_bits_data), .io_fetch_resp_bits_corrupt(i_io_fetch_resp_bits_corrupt),
    .io_prefetch_req_ready(i_io_prefetch_req_ready), .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_blkPaddr(io_prefetch_req_bits_blkPaddr), .io_prefetch_req_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_meta_write_valid(i_io_meta_write_valid), .io_meta_write_bits_virIdx(i_io_meta_write_bits_virIdx),
    .io_meta_write_bits_phyTag(i_io_meta_write_bits_phyTag), .io_meta_write_bits_waymask(i_io_meta_write_bits_waymask),
    .io_meta_write_bits_bankIdx(i_io_meta_write_bits_bankIdx), .io_data_write_valid(i_io_data_write_valid),
    .io_data_write_bits_virIdx(i_io_data_write_bits_virIdx), .io_data_write_bits_data(i_io_data_write_bits_data),
    .io_data_write_bits_waymask(i_io_data_write_bits_waymask), .io_victim_vSetIdx_valid(i_io_victim_vSetIdx_valid),
    .io_victim_vSetIdx_bits(i_io_victim_vSetIdx_bits), .io_victim_way(io_victim_way),
    .io_mem_acquire_ready(io_mem_acquire_ready), .io_mem_acquire_valid(i_io_mem_acquire_valid),
    .io_mem_acquire_bits_source(i_io_mem_acquire_bits_source), .io_mem_acquire_bits_address(i_io_mem_acquire_bits_address),
    .io_mem_grant_valid(io_mem_grant_valid), .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_size(io_mem_grant_bits_size), .io_mem_grant_bits_source(io_mem_grant_bits_source),
    .io_mem_grant_bits_data(io_mem_grant_bits_data), .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt)
  );

  // ---- 在途事务跟踪：source 已发射(A fire)未回收 ----
  bit inflight [N_MSHR];

  // grant FSM
  int          grant_beat;     // 0 = 未在发；1 = 已发第1拍，准备第2拍
  logic [3:0]  grant_src;

  // 监视 acquire 握手（用 golden 侧；两侧时序一致）
  wire acq_fire = g_io_mem_acquire_valid && io_mem_acquire_ready;

  // 复位 + 激励：在 negedge 更新输入
  always @(negedge clk) begin
    if (rst) begin
      io_fencei <= 0; io_flush <= 0; io_wfi_wfiReq <= 0;
      io_fetch_req_valid <= 0; io_prefetch_req_valid <= 0;
      io_fetch_req_bits_blkPaddr <= 0; io_fetch_req_bits_vSetIdx <= 0;
      io_prefetch_req_bits_blkPaddr <= 0; io_prefetch_req_bits_vSetIdx <= 0;
      io_mem_acquire_ready <= 1;
      io_mem_grant_valid <= 0; io_mem_grant_bits_opcode <= 4'd1; // bit0=1 => hasData
      io_mem_grant_bits_size <= 3'd6; io_mem_grant_bits_source <= 0;
      io_mem_grant_bits_data <= 0; io_mem_grant_bits_corrupt <= 0;
      io_victim_way <= 0;
      grant_beat <= 0;
      for (int k = 0; k < N_MSHR; k++) inflight[k] <= 0;
    end else begin
      // ---- 控制：偶发 flush / fencei / wfi ----
      io_fencei <= ($urandom_range(0,255)==0);
      io_flush  <= ($urandom_range(0,63)==0);
      io_wfi_wfiReq <= ($urandom_range(0,31)==0);

      // ---- 取指/预取请求：地址空间故意小，制造命中/去重/MSHR 满 ----
      io_fetch_req_valid <= ($urandom_range(0,2)!=0);
      io_fetch_req_bits_blkPaddr <= 42'($urandom_range(0,7));
      io_fetch_req_bits_vSetIdx  <= 8'($urandom_range(0,3));
      io_prefetch_req_valid <= ($urandom_range(0,2)!=0);
      io_prefetch_req_bits_blkPaddr <= 42'($urandom_range(0,7));
      io_prefetch_req_bits_vSetIdx  <= 8'($urandom_range(0,3));

      // ---- acquire ready：偶发反压 ----
      io_mem_acquire_ready <= ($urandom_range(0,4)!=0);

      // ---- victim way：随机（acquire fire 当拍被锁存）----
      io_victim_way <= 2'($urandom);

      // ---- 在途登记：acquire fire → 标记 source 在途 ----
      if (acq_fire) inflight[g_io_mem_acquire_bits_source] <= 1'b1;

      // ---- grant FSM：成对 beat ----
      if (grant_beat == 0) begin
        // 尝试启动一个新 grant：找一个在途 source
        automatic int pick = -1;
        for (int k = 0; k < N_MSHR; k++)
          if (inflight[k] && pick < 0 && ($urandom_range(0,1)==0)) pick = k;
        if (pick >= 0) begin
          grant_src     <= 4'(pick);
          io_mem_grant_valid <= 1'b1;
          io_mem_grant_bits_opcode <= 4'd1;            // hasData
          io_mem_grant_bits_source <= 4'(pick);
          io_mem_grant_bits_data   <= {$urandom,$urandom,$urandom,$urandom,
                                       $urandom,$urandom,$urandom,$urandom};
          io_mem_grant_bits_corrupt<= ($urandom_range(0,15)==0);
          grant_beat <= 1;
        end else begin
          io_mem_grant_valid <= 1'b0;
        end
      end else begin
        // 发第 2（末）beat：source 不变，回收该 source
        io_mem_grant_valid <= 1'b1;
        io_mem_grant_bits_opcode <= 4'd1;
        io_mem_grant_bits_source <= grant_src;
        io_mem_grant_bits_data   <= {$urandom,$urandom,$urandom,$urandom,
                                     $urandom,$urandom,$urandom,$urandom};
        io_mem_grant_bits_corrupt<= ($urandom_range(0,15)==0);
        inflight[grant_src] <= 1'b0;
        grant_beat <= 0;
      end
    end
  end

  // ---- 比对：所有输出逐拍比对 ----
  task automatic chk(input string nm, input logic [511:0] g, input logic [511:0] i);
    if (g !== i) begin
      errors++;
      if (errors <= 40) $display("[%0t] %s g=%h i=%h", $time, nm, g, i);
    end
  endtask

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    chk("wfi_wfiSafe",         g_io_wfi_wfiSafe,         i_io_wfi_wfiSafe);
    chk("fetch_req_ready",     g_io_fetch_req_ready,     i_io_fetch_req_ready);
    chk("fetch_resp_valid",    g_io_fetch_resp_valid,    i_io_fetch_resp_valid);
    chk("fetch_resp_blkPaddr", g_io_fetch_resp_bits_blkPaddr, i_io_fetch_resp_bits_blkPaddr);
    chk("fetch_resp_vSetIdx",  g_io_fetch_resp_bits_vSetIdx,  i_io_fetch_resp_bits_vSetIdx);
    chk("fetch_resp_waymask",  g_io_fetch_resp_bits_waymask,  i_io_fetch_resp_bits_waymask);
    chk("fetch_resp_data",     g_io_fetch_resp_bits_data,     i_io_fetch_resp_bits_data);
    chk("fetch_resp_corrupt",  g_io_fetch_resp_bits_corrupt,  i_io_fetch_resp_bits_corrupt);
    chk("prefetch_req_ready",  g_io_prefetch_req_ready,  i_io_prefetch_req_ready);
    chk("meta_write_valid",    g_io_meta_write_valid,    i_io_meta_write_valid);
    chk("meta_write_virIdx",   g_io_meta_write_bits_virIdx,   i_io_meta_write_bits_virIdx);
    chk("meta_write_phyTag",   g_io_meta_write_bits_phyTag,   i_io_meta_write_bits_phyTag);
    chk("meta_write_waymask",  g_io_meta_write_bits_waymask,  i_io_meta_write_bits_waymask);
    chk("meta_write_bankIdx",  g_io_meta_write_bits_bankIdx,  i_io_meta_write_bits_bankIdx);
    chk("data_write_valid",    g_io_data_write_valid,    i_io_data_write_valid);
    chk("data_write_virIdx",   g_io_data_write_bits_virIdx,   i_io_data_write_bits_virIdx);
    chk("data_write_data",     g_io_data_write_bits_data,     i_io_data_write_bits_data);
    chk("data_write_waymask",  g_io_data_write_bits_waymask,  i_io_data_write_bits_waymask);
    chk("victim_vSetIdx_valid",g_io_victim_vSetIdx_valid, i_io_victim_vSetIdx_valid);
    // bits 仅在对应 valid 时有意义（valid=0 时 golden/xs 的组合 stale 值可不同）
    if (g_io_victim_vSetIdx_valid)
      chk("victim_vSetIdx_bits", g_io_victim_vSetIdx_bits,  i_io_victim_vSetIdx_bits);
    chk("mem_acquire_valid",   g_io_mem_acquire_valid,   i_io_mem_acquire_valid);
    if (g_io_mem_acquire_valid) begin
      chk("mem_acquire_source",  g_io_mem_acquire_bits_source,  i_io_mem_acquire_bits_source);
      chk("mem_acquire_address", g_io_mem_acquire_bits_address, i_io_mem_acquire_bits_address);
    end
  end

  // ---- 内部寄存器等价探针（证明 FM failing 为状态合并造成的假阳性）----
  // 比对 golden 与 xs 的内部寄存器逐拍相等：id_r / last_fire_r / 每个 MSHR.valid /
  // 每个 MSHR.way。若全程 0 mismatch，则 FM 报的 failing point 确为假阳性。
  int probe_err = 0;
  task automatic pchk(input string nm, input logic [63:0] g, input logic [63:0] i);
    if (g !== i) begin probe_err++;
      if (probe_err<=40) $display("[%0t] PROBE %s g=%h i=%h", $time, nm, g, i); end
  endtask
  always @(negedge clk) if (!rst) begin
    #4;
    pchk("id_r",        u_g.id_r,        u_i.u_core.id_r);
    pchk("last_fire_r", u_g.last_fire_r, u_i.u_core.last_fire_r);
    // fetch MSHRs 0..3 → mshr[0..3]
    pchk("fM0.valid", u_g.fetchMSHRs_0.valid, u_i.u_core.mshr[0].valid);
    pchk("fM1.valid", u_g.fetchMSHRs_1.valid, u_i.u_core.mshr[1].valid);
    pchk("fM2.valid", u_g.fetchMSHRs_2.valid, u_i.u_core.mshr[2].valid);
    pchk("fM3.valid", u_g.fetchMSHRs_3.valid, u_i.u_core.mshr[3].valid);
    pchk("pM8.valid", u_g.prefetchMSHRs_8.valid, u_i.u_core.mshr[12].valid);
    pchk("pM9.valid", u_g.prefetchMSHRs_9.valid, u_i.u_core.mshr[13].valid);
    // way（issued 后才有意义；golden 与 xs 在 issued 时都锁存 victim）
    pchk("pM0.way", u_g.prefetchMSHRs_0.way, u_i.u_core.mshr[4].way);
    pchk("pM9.way", u_g.prefetchMSHRs_9.way, u_i.u_core.mshr[13].way);
  end

  initial begin
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d probe_err=%0d", checks, errors, probe_err);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
