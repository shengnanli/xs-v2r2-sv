// ICacheMissUnit 双例化逐拍比对：golden ICacheMissUnit vs 可读重写 ICacheMissUnit_xs
//
// 两侧例化的是**同一批**子模块定义（19 种可读重写件，由 RTL_GOLDEN_DEPS 两侧
// 同源提供），所以这个 tb 单验父层胶水：MSHR 阵列连线、去重、发射顺序队列、
// Acquire 仲裁、回填状态机、flush/fencei 作废、DiffTest 探针打包。
//
// 【激励里带了一个极简 L2 模型】
//   随机拉 io_mem_acquire_ready；Acquire 握手成功就把 source 记进 pend 队列；
//   随后随机挑一个 pend 的 source 回两个 256b beat（TileLink GrantData，
//   opcode[0]=1、size=6）。beat 计数器 readBeatCnt 是**全局**的（不分 source），
//   所以模型严格保证"两个数据 beat 连着发、中间不插别的数据 beat"。
//   故意注入的三类脏东西：
//     * 3% 的事务用越界 source 14/15 —— 打 golden 那张 16 项查表的兜底分支
//       （14/15 项填的是第 0 格 MSHR），正常运行永远走不到；
//     * 1% 的不带数据 Grant（opcode[0]=0）—— 只动 beats1 倒计数、不动 beat 计数器；
//     * 4% 的 beat 带 corrupt —— 走"回送流水但不写 SRAM"那条路。
//
// 【采样相位】驱动用 posedge 非阻塞，比对在 negedge 后 #4（下一个 posedge 前 1ns），
//   两侧看到的都是本拍已稳定的输出。
//
// 【X 守卫必须一次都不触发】golden 有复位的寄存器 time 0 被异步复位清零，
//   无复位的 last_fire_r/id_r 第一个 posedge 就被无条件写定。所以本 UT 的
//   判据不只是 errors==0，还要求 checks == 24（输出端口数）× 比对拍数，
//   且 x_skips==0 —— 一旦有 X 让守卫跳过某次比较，这个恒等式立刻不成立，
//   "X 一路吃掉差异还报绿"这种假绿就藏不住。
//
// 【覆盖闸】miss 处理单元极易假绿（队列填满后再不动、flush 永不触发），
//   所以下面 20 多个关键事件每个都要 >= COV_MIN，为 0 或不足即 TEST FAILED，
//   不看 errors。特别是：14 个 source 各自的 Acquire 发射次数分别计数，
//   证明取指 4 路和预取 10 路每一路都真的被仲裁上过总线。
`timescale 1ns/1ps
module tb;

  // ---------------------------------------------------------------------
  // 规模常量
  // ---------------------------------------------------------------------
  localparam int N_OUT   = 24;   // golden 的输出端口数（比对项数/拍）
  localparam int N_MSHR  = 14;
  localparam int COV_MIN = 200;  // 通用事件门限
  localparam int COV_MIN_SRC = 100;  // 单个 source 的 Acquire 发射门限

  int unsigned NCYCLES = 200000;

  bit clk = 0;
  logic rst;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------
  // DUT 输入（两侧共用）
  // ---------------------------------------------------------------------
  logic         io_hartId;
  logic         io_fencei;
  logic         io_flush;
  logic         io_wfi_wfiReq;
  logic         io_fetch_req_valid;
  logic [41:0]  io_fetch_req_bits_blkPaddr;
  logic [7:0]   io_fetch_req_bits_vSetIdx;
  logic         io_prefetch_req_valid;
  logic [41:0]  io_prefetch_req_bits_blkPaddr;
  logic [7:0]   io_prefetch_req_bits_vSetIdx;
  logic [1:0]   io_victim_way;
  logic         io_mem_acquire_ready;
  logic         io_mem_grant_valid;
  logic [3:0]   io_mem_grant_bits_opcode;
  logic [2:0]   io_mem_grant_bits_size;
  logic [3:0]   io_mem_grant_bits_source;
  logic [255:0] io_mem_grant_bits_data;
  logic         io_mem_grant_bits_corrupt;

  // ---------------------------------------------------------------------
  // DUT 输出（g_ = golden, i_ = 重写）
  // ---------------------------------------------------------------------
  wire          g_wfi_wfiSafe,            i_wfi_wfiSafe;
  wire          g_fetch_req_ready,        i_fetch_req_ready;
  wire          g_fetch_resp_valid,       i_fetch_resp_valid;
  wire [41:0]   g_fetch_resp_blkPaddr,    i_fetch_resp_blkPaddr;
  wire [7:0]    g_fetch_resp_vSetIdx,     i_fetch_resp_vSetIdx;
  wire [3:0]    g_fetch_resp_waymask,     i_fetch_resp_waymask;
  wire [511:0]  g_fetch_resp_data,        i_fetch_resp_data;
  wire          g_fetch_resp_corrupt,     i_fetch_resp_corrupt;
  wire          g_prefetch_req_ready,     i_prefetch_req_ready;
  wire          g_meta_write_valid,       i_meta_write_valid;
  wire [7:0]    g_meta_write_virIdx,      i_meta_write_virIdx;
  wire [35:0]   g_meta_write_phyTag,      i_meta_write_phyTag;
  wire [3:0]    g_meta_write_waymask,     i_meta_write_waymask;
  wire          g_meta_write_bankIdx,     i_meta_write_bankIdx;
  wire          g_data_write_valid,       i_data_write_valid;
  wire [7:0]    g_data_write_virIdx,      i_data_write_virIdx;
  wire [511:0]  g_data_write_data,        i_data_write_data;
  wire [3:0]    g_data_write_waymask,     i_data_write_waymask;
  wire          g_victim_vSetIdx_valid,   i_victim_vSetIdx_valid;
  wire [7:0]    g_victim_vSetIdx_bits,    i_victim_vSetIdx_bits;
  wire          g_mem_acquire_valid,      i_mem_acquire_valid;
  wire [3:0]    g_mem_acquire_source,     i_mem_acquire_source;
  wire [47:0]   g_mem_acquire_address,    i_mem_acquire_address;
  wire [600:0]  g_gateway_bore,           i_gateway_bore;

  ICacheMissUnit u_g (
    .clock(clk), .reset(rst),
    .io_hartId(io_hartId), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(g_wfi_wfiSafe),
    .io_fetch_req_ready(g_fetch_req_ready),
    .io_fetch_req_valid(io_fetch_req_valid),
    .io_fetch_req_bits_blkPaddr(io_fetch_req_bits_blkPaddr),
    .io_fetch_req_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_fetch_resp_valid(g_fetch_resp_valid),
    .io_fetch_resp_bits_blkPaddr(g_fetch_resp_blkPaddr),
    .io_fetch_resp_bits_vSetIdx(g_fetch_resp_vSetIdx),
    .io_fetch_resp_bits_waymask(g_fetch_resp_waymask),
    .io_fetch_resp_bits_data(g_fetch_resp_data),
    .io_fetch_resp_bits_corrupt(g_fetch_resp_corrupt),
    .io_prefetch_req_ready(g_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_blkPaddr(io_prefetch_req_bits_blkPaddr),
    .io_prefetch_req_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_meta_write_valid(g_meta_write_valid),
    .io_meta_write_bits_virIdx(g_meta_write_virIdx),
    .io_meta_write_bits_phyTag(g_meta_write_phyTag),
    .io_meta_write_bits_waymask(g_meta_write_waymask),
    .io_meta_write_bits_bankIdx(g_meta_write_bankIdx),
    .io_data_write_valid(g_data_write_valid),
    .io_data_write_bits_virIdx(g_data_write_virIdx),
    .io_data_write_bits_data(g_data_write_data),
    .io_data_write_bits_waymask(g_data_write_waymask),
    .io_victim_vSetIdx_valid(g_victim_vSetIdx_valid),
    .io_victim_vSetIdx_bits(g_victim_vSetIdx_bits),
    .io_victim_way(io_victim_way),
    .io_mem_acquire_ready(io_mem_acquire_ready),
    .io_mem_acquire_valid(g_mem_acquire_valid),
    .io_mem_acquire_bits_source(g_mem_acquire_source),
    .io_mem_acquire_bits_address(g_mem_acquire_address),
    .io_mem_grant_valid(io_mem_grant_valid),
    .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_size(io_mem_grant_bits_size),
    .io_mem_grant_bits_source(io_mem_grant_bits_source),
    .io_mem_grant_bits_data(io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt),
    .gatewayIn_packed_2_bore(g_gateway_bore)
  );

  ICacheMissUnit_xs u_i (
    .clock(clk), .reset(rst),
    .io_hartId(io_hartId), .io_fencei(io_fencei), .io_flush(io_flush),
    .io_wfi_wfiReq(io_wfi_wfiReq), .io_wfi_wfiSafe(i_wfi_wfiSafe),
    .io_fetch_req_ready(i_fetch_req_ready),
    .io_fetch_req_valid(io_fetch_req_valid),
    .io_fetch_req_bits_blkPaddr(io_fetch_req_bits_blkPaddr),
    .io_fetch_req_bits_vSetIdx(io_fetch_req_bits_vSetIdx),
    .io_fetch_resp_valid(i_fetch_resp_valid),
    .io_fetch_resp_bits_blkPaddr(i_fetch_resp_blkPaddr),
    .io_fetch_resp_bits_vSetIdx(i_fetch_resp_vSetIdx),
    .io_fetch_resp_bits_waymask(i_fetch_resp_waymask),
    .io_fetch_resp_bits_data(i_fetch_resp_data),
    .io_fetch_resp_bits_corrupt(i_fetch_resp_corrupt),
    .io_prefetch_req_ready(i_prefetch_req_ready),
    .io_prefetch_req_valid(io_prefetch_req_valid),
    .io_prefetch_req_bits_blkPaddr(io_prefetch_req_bits_blkPaddr),
    .io_prefetch_req_bits_vSetIdx(io_prefetch_req_bits_vSetIdx),
    .io_meta_write_valid(i_meta_write_valid),
    .io_meta_write_bits_virIdx(i_meta_write_virIdx),
    .io_meta_write_bits_phyTag(i_meta_write_phyTag),
    .io_meta_write_bits_waymask(i_meta_write_waymask),
    .io_meta_write_bits_bankIdx(i_meta_write_bankIdx),
    .io_data_write_valid(i_data_write_valid),
    .io_data_write_bits_virIdx(i_data_write_virIdx),
    .io_data_write_bits_data(i_data_write_data),
    .io_data_write_bits_waymask(i_data_write_waymask),
    .io_victim_vSetIdx_valid(i_victim_vSetIdx_valid),
    .io_victim_vSetIdx_bits(i_victim_vSetIdx_bits),
    .io_victim_way(io_victim_way),
    .io_mem_acquire_ready(io_mem_acquire_ready),
    .io_mem_acquire_valid(i_mem_acquire_valid),
    .io_mem_acquire_bits_source(i_mem_acquire_source),
    .io_mem_acquire_bits_address(i_mem_acquire_address),
    .io_mem_grant_valid(io_mem_grant_valid),
    .io_mem_grant_bits_opcode(io_mem_grant_bits_opcode),
    .io_mem_grant_bits_size(io_mem_grant_bits_size),
    .io_mem_grant_bits_source(io_mem_grant_bits_source),
    .io_mem_grant_bits_data(io_mem_grant_bits_data),
    .io_mem_grant_bits_corrupt(io_mem_grant_bits_corrupt),
    .gatewayIn_packed_2_bore(i_gateway_bore)
  );

  // ---------------------------------------------------------------------
  // 统计
  // ---------------------------------------------------------------------
  int errors = 0, checks = 0, ncompare = 0, x_skips = 0, cov_fail = 0;

  int cov_fetch_alloc = 0, cov_fetch_hit = 0;
  int cov_prefetch_alloc = 0, cov_prefetch_hit = 0, cov_pf_same_line = 0;
  int cov_acq_src [16];
  int cov_acq_stall = 0;
  int cov_beat0 = 0, cov_beat1 = 0, cov_grant_nodata = 0, cov_src_oob = 0;
  int cov_resp = 0, cov_write = 0, cov_resp_no_write = 0, cov_corrupt = 0;
  int cov_flush_busy = 0, cov_fencei_busy = 0;
  int cov_wfi_unsafe = 0, cov_wfi_safe = 0;
  int cov_waymask [4];
  int cov_reset_pulse = 0;

  // ---------------------------------------------------------------------
  // 极简 L2 模型状态
  // ---------------------------------------------------------------------
  int  pend[$];      // 已发出 Acquire、还没回完 Grant 的 source
  bit  gr_busy = 0;  // 正在发一对 data beat 的后半拍
  int  gr_src   = 0;
  int  rst_cnt  = 0;
  // rst 的所有权：复位序列结束前归 initial 块，之后才交给下面的随机脉冲逻辑。
  // （两个进程同时写同一个变量会互相打架，第一版就是这么把 5 拍初始复位冲没的。）
  bit  init_done = 0;
  // wfi 排空窗口：io_wfi_wfiReq 必须**持续**拉着，MSHR 才会停发新的 Acquire，
  // 在途的那些回完之后 io_wfi_wfiSafe 才有机会抬起来。逐拍独立随机的 wfiReq
  // 永远等不到这一刻（第一版实测 200k 拍只出现 14 次 safe），所以做成有长度的
  // 突发，并在窗口内把 Grant 服务速度调快，把 14 格 MSHR 真排空。
  int  wfi_hold = 0;

  function automatic void clear_inputs();
    io_hartId                     = 1'b0;
    io_fencei                     = 1'b0;
    io_flush                      = 1'b0;
    io_wfi_wfiReq                 = 1'b0;
    io_fetch_req_valid            = 1'b0;
    io_fetch_req_bits_blkPaddr    = '0;
    io_fetch_req_bits_vSetIdx     = '0;
    io_prefetch_req_valid         = 1'b0;
    io_prefetch_req_bits_blkPaddr = '0;
    io_prefetch_req_bits_vSetIdx  = '0;
    io_victim_way                 = '0;
    io_mem_acquire_ready          = 1'b0;
    io_mem_grant_valid            = 1'b0;
    io_mem_grant_bits_opcode      = '0;
    io_mem_grant_bits_size        = '0;
    io_mem_grant_bits_source      = '0;
    io_mem_grant_bits_data        = '0;
    io_mem_grant_bits_corrupt     = 1'b0;
  endfunction

  // ---------------------------------------------------------------------
  // 驱动 + 模型 + 事件计数（读到的都是本拍已稳定的值）
  // ---------------------------------------------------------------------
  int    k;
  int    pick;
  bit [41:0] nxt_pf_paddr;
  bit [7:0]  nxt_pf_vset;
  bit    do_oob;

  always @(posedge clk) begin
    // ---- 事件计数：本拍（刚结束的这一拍）发生了什么 ----
    if (!rst) begin
      if (io_fetch_req_valid &  u_g.fetchHit)                        cov_fetch_hit++;
      if (io_fetch_req_valid & ~u_g.fetchHit & g_fetch_req_ready)    cov_fetch_alloc++;
      if (io_prefetch_req_valid &  u_g.prefetchHit)                  cov_prefetch_hit++;
      if (io_prefetch_req_valid & ~u_g.prefetchHit & g_prefetch_req_ready) cov_prefetch_alloc++;
      if (io_prefetch_req_valid & io_fetch_req_valid
          & (io_prefetch_req_bits_blkPaddr == io_fetch_req_bits_blkPaddr)
          & (io_prefetch_req_bits_vSetIdx  == io_fetch_req_bits_vSetIdx))  cov_pf_same_line++;
      if (g_mem_acquire_valid & ~io_mem_acquire_ready)               cov_acq_stall++;
      if (g_mem_acquire_valid &  io_mem_acquire_ready)               cov_acq_src[g_mem_acquire_source]++;
      if (g_fetch_resp_valid)                                        cov_resp++;
      if (g_meta_write_valid) begin
        cov_write++;
        for (k = 0; k < 4; k++) if (g_meta_write_waymask[k]) cov_waymask[k]++;
      end
      if (g_fetch_resp_valid & ~g_meta_write_valid)                  cov_resp_no_write++;
      if (g_fetch_resp_valid &  g_fetch_resp_corrupt)                cov_corrupt++;
      if (io_flush  & (~g_wfi_wfiSafe | (pend.size() != 0)))         cov_flush_busy++;
      if (io_fencei & (~g_wfi_wfiSafe | (pend.size() != 0)))         cov_fencei_busy++;
      if (io_wfi_wfiReq &  g_wfi_wfiSafe)                            cov_wfi_safe++;
      if (io_wfi_wfiReq & ~g_wfi_wfiSafe)                            cov_wfi_unsafe++;
    end

    // ---- L2 模型：记下本拍握手成功的 Acquire ----
    if (!rst && g_mem_acquire_valid && io_mem_acquire_ready)
      pend.push_back(int'(g_mem_acquire_source));
    // ---- 复位脉冲（异步高有效，golden 的复位就是异步的，这条路径必须走到）----
    if (!init_done) begin
      // 初始复位序列由 initial 块驱动，这里一个字都不碰 rst
    end
    else if (rst_cnt > 0) begin
      rst_cnt <= rst_cnt - 1;
      rst     <= 1'b1;
    end
    else if ($urandom_range(0, 2999) == 0) begin
      rst_cnt <= 2;
      rst     <= 1'b1;
      pend.delete();
      gr_busy <= 1'b0;
      cov_reset_pulse++;
    end
    else begin
      rst <= 1'b0;
    end

    // ---- 请求侧激励：地址池开小，让去重命中真的发生 ----
    io_fetch_req_valid         <= ($urandom_range(0, 99) < 55);
    io_fetch_req_bits_blkPaddr <= 42'($urandom_range(0, 31));
    io_fetch_req_bits_vSetIdx  <= 8'($urandom_range(0, 3));

    nxt_pf_paddr = 42'($urandom_range(0, 31));
    nxt_pf_vset  = 8'($urandom_range(0, 3));
    // 5% 直接抄取指地址，专门打"预取与本拍取指撞同一条 line"那条去重项
    if ($urandom_range(0, 19) == 0) begin
      nxt_pf_paddr = io_fetch_req_bits_blkPaddr;
      nxt_pf_vset  = io_fetch_req_bits_vSetIdx;
    end
    io_prefetch_req_valid         <= ($urandom_range(0, 99) < 60);
    io_prefetch_req_bits_blkPaddr <= nxt_pf_paddr;
    io_prefetch_req_bits_vSetIdx  <= nxt_pf_vset;

    io_victim_way        <= 2'($urandom_range(0, 3));
    io_mem_acquire_ready <= ($urandom_range(0, 99) < 60);
    io_flush             <= ($urandom_range(0, 999) < 15);
    io_fencei            <= ($urandom_range(0, 999) <  7);
    if (wfi_hold > 0) begin
      wfi_hold      <= wfi_hold - 1;
      io_wfi_wfiReq <= 1'b1;
    end
    else if ($urandom_range(0, 499) == 0) begin
      wfi_hold      <= $urandom_range(40, 160);
      io_wfi_wfiReq <= 1'b1;
    end
    else begin
      io_wfi_wfiReq <= ($urandom_range(0, 99) < 5);
    end
    if ($urandom_range(0, 999) == 0) io_hartId <= ~io_hartId;

    // ---- L2 模型：回 Grant ----
    //   两个 data beat 必须连着发（readBeatCnt 是全局的，中间插别的 data beat
    //   就把配对打乱了）。不带数据的 Grant 不动 beat 计数器，可以随时插。
    io_mem_grant_bits_data    <= {$urandom(), $urandom(), $urandom(), $urandom(),
                                  $urandom(), $urandom(), $urandom(), $urandom()};
    io_mem_grant_bits_corrupt <= ($urandom_range(0, 99) < 4);
    io_mem_grant_bits_size    <= 3'd6;             // 64B = 2 个 256b beat
    if (gr_busy) begin
      io_mem_grant_valid       <= 1'b1;
      io_mem_grant_bits_opcode <= 4'd5;            // opcode[0]=1：带数据
      io_mem_grant_bits_source <= 4'(gr_src);
      gr_busy                  <= 1'b0;
      cov_beat1++;
    end
    else begin
      do_oob = ($urandom_range(0, 99) < 3);
      // wfi 排空窗口里把服务速度拉满，让在途 Acquire 尽快回完
      if (do_oob || (pend.size() != 0
                     && $urandom_range(0, 99) < ((wfi_hold > 0) ? 85 : 30))) begin
        if (do_oob) begin
          gr_src = $urandom_range(14, 15);         // 越界 source：打 16 项表的兜底
          cov_src_oob++;
        end
        else begin
          pick   = $urandom_range(0, pend.size() - 1);
          gr_src = pend[pick];
          pend.delete(pick);
        end
        io_mem_grant_valid       <= 1'b1;
        io_mem_grant_bits_opcode <= 4'd5;
        io_mem_grant_bits_source <= 4'(gr_src);
        gr_busy                  <= 1'b1;
        cov_beat0++;
      end
      else if ($urandom_range(0, 99) == 0) begin
        // 不带数据的 Grant（如 ReleaseAck）：只动 beats1 倒计数
        io_mem_grant_valid       <= 1'b1;
        io_mem_grant_bits_opcode <= 4'd4;          // opcode[0]=0
        io_mem_grant_bits_source <= 4'($urandom_range(0, 15));
        io_mem_grant_bits_size   <= 3'($urandom_range(0, 7));
        cov_grant_nodata++;
      end
      else begin
        io_mem_grant_valid <= 1'b0;
      end
    end
  end

  // ---------------------------------------------------------------------
  // 逐拍比对：24 个输出端口，每拍每口一次。X 守卫存在但必须永不触发。
  // ---------------------------------------------------------------------
  `define CMP(NAME, G, I)                                                      \
    if ($isunknown(G) || $isunknown(I)) x_skips++;                             \
    else begin                                                                 \
      checks++;                                                                \
      if ((G) !== (I)) begin                                                   \
        errors++;                                                              \
        if (errors <= 30)                                                      \
          $display("[%0t] %s  g=%h  i=%h", $time, NAME, G, I);                 \
      end                                                                      \
    end

  always @(negedge clk) if (!rst) begin
    #4;
    ncompare++;
    `CMP("io_wfi_wfiSafe",              g_wfi_wfiSafe,          i_wfi_wfiSafe)
    `CMP("io_fetch_req_ready",          g_fetch_req_ready,      i_fetch_req_ready)
    `CMP("io_fetch_resp_valid",         g_fetch_resp_valid,     i_fetch_resp_valid)
    `CMP("io_fetch_resp_bits_blkPaddr", g_fetch_resp_blkPaddr,  i_fetch_resp_blkPaddr)
    `CMP("io_fetch_resp_bits_vSetIdx",  g_fetch_resp_vSetIdx,   i_fetch_resp_vSetIdx)
    `CMP("io_fetch_resp_bits_waymask",  g_fetch_resp_waymask,   i_fetch_resp_waymask)
    `CMP("io_fetch_resp_bits_data",     g_fetch_resp_data,      i_fetch_resp_data)
    `CMP("io_fetch_resp_bits_corrupt",  g_fetch_resp_corrupt,   i_fetch_resp_corrupt)
    `CMP("io_prefetch_req_ready",       g_prefetch_req_ready,   i_prefetch_req_ready)
    `CMP("io_meta_write_valid",         g_meta_write_valid,     i_meta_write_valid)
    `CMP("io_meta_write_bits_virIdx",   g_meta_write_virIdx,    i_meta_write_virIdx)
    `CMP("io_meta_write_bits_phyTag",   g_meta_write_phyTag,    i_meta_write_phyTag)
    `CMP("io_meta_write_bits_waymask",  g_meta_write_waymask,   i_meta_write_waymask)
    `CMP("io_meta_write_bits_bankIdx",  g_meta_write_bankIdx,   i_meta_write_bankIdx)
    `CMP("io_data_write_valid",         g_data_write_valid,     i_data_write_valid)
    `CMP("io_data_write_bits_virIdx",   g_data_write_virIdx,    i_data_write_virIdx)
    `CMP("io_data_write_bits_data",     g_data_write_data,      i_data_write_data)
    `CMP("io_data_write_bits_waymask",  g_data_write_waymask,   i_data_write_waymask)
    `CMP("io_victim_vSetIdx_valid",     g_victim_vSetIdx_valid, i_victim_vSetIdx_valid)
    `CMP("io_victim_vSetIdx_bits",      g_victim_vSetIdx_bits,  i_victim_vSetIdx_bits)
    `CMP("io_mem_acquire_valid",        g_mem_acquire_valid,    i_mem_acquire_valid)
    `CMP("io_mem_acquire_bits_source",  g_mem_acquire_source,   i_mem_acquire_source)
    `CMP("io_mem_acquire_bits_address", g_mem_acquire_address,  i_mem_acquire_address)
    `CMP("gatewayIn_packed_2_bore",     g_gateway_bore,         i_gateway_bore)
  end

  // ---------------------------------------------------------------------
  // 收尾：覆盖闸
  // ---------------------------------------------------------------------
  function automatic int cov_chk(string name, int v, int lim);
    if (v < lim) begin
      $display("  [COV FAIL] %-30s = %0d  (< %0d)", name, v, lim);
      return 1;
    end
    return 0;
  endfunction

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));   // ut_common.mk 统一下发 200000
    clear_inputs();
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    init_done = 1'b1;               // 从这里起 rst 交给随机脉冲逻辑
    repeat (NCYCLES) @(posedge clk);

    $display("checks=%0d errors=%0d ncompare=%0d x_skips=%0d", checks, errors, ncompare, x_skips);
    $display("覆盖：");
    $display("  fetch: alloc=%0d hit=%0d      prefetch: alloc=%0d hit=%0d same_line=%0d",
             cov_fetch_alloc, cov_fetch_hit, cov_prefetch_alloc, cov_prefetch_hit, cov_pf_same_line);
    $display("  acquire: stall=%0d  per-source=%p", cov_acq_stall, cov_acq_src);
    $display("  grant: beat0=%0d beat1=%0d nodata=%0d oob_src=%0d",
             cov_beat0, cov_beat1, cov_grant_nodata, cov_src_oob);
    $display("  refill: resp=%0d write=%0d resp_no_write=%0d corrupt=%0d waymask=%p",
             cov_resp, cov_write, cov_resp_no_write, cov_corrupt, cov_waymask);
    $display("  kill: flush_busy=%0d fencei_busy=%0d  wfi: safe=%0d unsafe=%0d  reset_pulse=%0d",
             cov_flush_busy, cov_fencei_busy, cov_wfi_safe, cov_wfi_unsafe, cov_reset_pulse);

    // X 守卫恒等式：24 个输出 × 比对拍数 == checks，且一次都没跳过
    if (x_skips != 0) begin
      $display("  [COV FAIL] x_skips = %0d（X 守卫触发过，比对被吃掉）", x_skips);
      cov_fail++;
    end
    if (checks != N_OUT * ncompare) begin
      $display("  [COV FAIL] checks=%0d != %0d 输出 × %0d 拍 = %0d",
               checks, N_OUT, ncompare, N_OUT * ncompare);
      cov_fail++;
    end

    cov_fail += cov_chk("fetch alloc",       cov_fetch_alloc,    COV_MIN);
    cov_fail += cov_chk("fetch hit",         cov_fetch_hit,      COV_MIN);
    cov_fail += cov_chk("prefetch alloc",    cov_prefetch_alloc, COV_MIN);
    cov_fail += cov_chk("prefetch hit",      cov_prefetch_hit,   COV_MIN);
    cov_fail += cov_chk("prefetch==fetch",   cov_pf_same_line,   COV_MIN);
    cov_fail += cov_chk("acquire stalled",   cov_acq_stall,      COV_MIN);
    for (int s = 0; s < N_MSHR; s++)
      cov_fail += cov_chk($sformatf("acquire src[%0d] fire", s), cov_acq_src[s], COV_MIN_SRC);
    cov_fail += cov_chk("grant beat0",       cov_beat0,          COV_MIN);
    cov_fail += cov_chk("grant beat1",       cov_beat1,          COV_MIN);
    cov_fail += cov_chk("grant no-data",     cov_grant_nodata,   COV_MIN);
    cov_fail += cov_chk("grant oob source",  cov_src_oob,        COV_MIN);
    cov_fail += cov_chk("refill resp",       cov_resp,           COV_MIN);
    cov_fail += cov_chk("refill sram write", cov_write,          COV_MIN);
    cov_fail += cov_chk("resp w/o write",    cov_resp_no_write,  COV_MIN);
    cov_fail += cov_chk("refill corrupt",    cov_corrupt,        COV_MIN);
    for (int w = 0; w < 4; w++)
      cov_fail += cov_chk($sformatf("refill waymask[%0d]", w), cov_waymask[w], COV_MIN);
    cov_fail += cov_chk("flush while busy",  cov_flush_busy,     COV_MIN);
    cov_fail += cov_chk("fencei while busy", cov_fencei_busy,    COV_MIN);
    cov_fail += cov_chk("wfi safe",          cov_wfi_safe,       COV_MIN);
    cov_fail += cov_chk("wfi unsafe",        cov_wfi_unsafe,     COV_MIN);
    cov_fail += cov_chk("async reset pulse", cov_reset_pulse,    10);

    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end

endmodule
