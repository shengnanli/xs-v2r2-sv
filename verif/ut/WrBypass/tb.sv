// =============================================================================
// WrBypass UT：手写 xs_WrBypass 与 Chisel 生成 golden 的双例化随机比对
//
// 5 个 V2R2 单态化变体各一对 DUT，共享时钟/复位，独立随机激励。
// 比对规则（输出均为组合逻辑，在时钟低电平中段采样）：
//   - io_hit 恒比对；
//   - 命中时比对各路 valid（golden 保留该端口的变体）；
//   - 路 valid 有效（或单路变体命中）时比对该路数据。
// 索引激励压缩在小值域内以制造足够的 CAM 命中率；中途打一次异步复位。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 50000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;

  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // 变体激励/比对生成器：用宏避免 5 份重复代码
  //   GOLD   golden 模块名    IDXW 索引位宽   POOL 索引值域
  //   WAYS/DATW 路数与数据宽   HASVLD golden 是否保留 valid 输出
  // ---------------------------------------------------------------------------
  `define WRBYP_PAIR_2W(GOLD, IDXW, DATW, ENTRIES, POOL) \
    logic              GOLD``_wen; \
    logic [IDXW-1:0]   GOLD``_idx; \
    logic [DATW-1:0]   GOLD``_d0, GOLD``_d1; \
    logic              GOLD``_m0, GOLD``_m1; \
    wire               GOLD``_g_hit,  GOLD``_i_hit; \
    wire               GOLD``_g_v0, GOLD``_g_v1, GOLD``_i_v0, GOLD``_i_v1; \
    wire  [DATW-1:0]   GOLD``_g_b0, GOLD``_g_b1, GOLD``_i_b0, GOLD``_i_b1; \
    int                GOLD``_hits = 0; \
    GOLD u_g_``GOLD ( \
      .clock(clk), .reset(rst), .io_wen(GOLD``_wen), .io_write_idx(GOLD``_idx), \
      .io_write_data_0(GOLD``_d0), .io_write_data_1(GOLD``_d1), \
      .io_write_way_mask_0(GOLD``_m0), .io_write_way_mask_1(GOLD``_m1), \
      .io_hit(GOLD``_g_hit), \
      .io_hit_data_0_valid(GOLD``_g_v0), .io_hit_data_0_bits(GOLD``_g_b0), \
      .io_hit_data_1_valid(GOLD``_g_v1), .io_hit_data_1_bits(GOLD``_g_b1)); \
    xs_WrBypass #(.NUM_ENTRIES(ENTRIES), .IDX_WIDTH(IDXW), .NUM_WAYS(2), \
                  .TAG_WIDTH(0), .DATA_WIDTH(DATW)) u_i_``GOLD ( \
      .clock(clk), .reset(rst), .io_wen(GOLD``_wen), .io_write_idx(GOLD``_idx), \
      .io_write_tag(1'b0), \
      .io_write_data({GOLD``_d1, GOLD``_d0}), \
      .io_write_way_mask({GOLD``_m1, GOLD``_m0}), \
      .io_hit(GOLD``_i_hit), \
      .io_hit_data_valid({GOLD``_i_v1, GOLD``_i_v0}), \
      .io_hit_data_bits({GOLD``_i_b1, GOLD``_i_b0})); \
    always @(negedge clk) begin \
      if (rst) begin \
        GOLD``_wen <= 1'b0; \
      end else begin \
        GOLD``_wen <= ($urandom_range(0, 9) < 8); \
        GOLD``_idx <= IDXW'($urandom_range(0, POOL)); \
        GOLD``_d0  <= DATW'($urandom); \
        GOLD``_d1  <= DATW'($urandom); \
        {GOLD``_m1, GOLD``_m0} <= 2'($urandom); \
      end \
    end \
    always @(negedge clk) if (!rst) begin \
      #4; \
      checks++; \
      if (GOLD``_g_hit !== GOLD``_i_hit) begin \
        errors++; $display("[%0t] %s hit mismatch: g=%b i=%b idx=%h", $time, `"GOLD`", GOLD``_g_hit, GOLD``_i_hit, GOLD``_idx); \
      end else if (GOLD``_g_hit === 1'b1) begin \
        GOLD``_hits++; \
        if (GOLD``_g_v0 !== GOLD``_i_v0 || GOLD``_g_v1 !== GOLD``_i_v1) begin \
          errors++; $display("[%0t] %s valid mismatch: g={%b,%b} i={%b,%b}", $time, `"GOLD`", GOLD``_g_v1, GOLD``_g_v0, GOLD``_i_v1, GOLD``_i_v0); \
        end \
        if (GOLD``_g_v0 === 1'b1 && GOLD``_g_b0 !== GOLD``_i_b0) begin \
          errors++; $display("[%0t] %s way0 data mismatch: g=%h i=%h", $time, `"GOLD`", GOLD``_g_b0, GOLD``_i_b0); \
        end \
        if (GOLD``_g_v1 === 1'b1 && GOLD``_g_b1 !== GOLD``_i_b1) begin \
          errors++; $display("[%0t] %s way1 data mismatch: g=%h i=%h", $time, `"GOLD`", GOLD``_g_b1, GOLD``_i_b1); \
        end \
      end \
    end

  `define WRBYP_PAIR_1W(GOLD, IDXW, DATW, ENTRIES, POOL, HASVLD) \
    logic              GOLD``_wen; \
    logic [IDXW-1:0]   GOLD``_idx; \
    logic [DATW-1:0]   GOLD``_d0; \
    wire               GOLD``_g_hit, GOLD``_i_hit; \
    wire               GOLD``_g_v0,  GOLD``_i_v0; \
    wire  [DATW-1:0]   GOLD``_g_b0,  GOLD``_i_b0; \
    int                GOLD``_hits = 0; \
    generate if (HASVLD) begin : g_``GOLD \
      GOLD u_g ( \
        .clock(clk), .reset(rst), .io_wen(GOLD``_wen), .io_write_idx(GOLD``_idx), \
        .io_write_data_0(GOLD``_d0), .io_hit(GOLD``_g_hit), \
        .io_hit_data_0_valid(GOLD``_g_v0), .io_hit_data_0_bits(GOLD``_g_b0)); \
    end else begin : g_``GOLD \
      GOLD u_g ( \
        .clock(clk), .reset(rst), .io_wen(GOLD``_wen), .io_write_idx(GOLD``_idx), \
        .io_write_data_0(GOLD``_d0), .io_hit(GOLD``_g_hit), \
        .io_hit_data_0_bits(GOLD``_g_b0)); \
      assign GOLD``_g_v0 = 1'b1; \
    end endgenerate \
    xs_WrBypass #(.NUM_ENTRIES(ENTRIES), .IDX_WIDTH(IDXW), .NUM_WAYS(1), \
                  .TAG_WIDTH(0), .DATA_WIDTH(DATW)) u_i_``GOLD ( \
      .clock(clk), .reset(rst), .io_wen(GOLD``_wen), .io_write_idx(GOLD``_idx), \
      .io_write_tag(1'b0), .io_write_data(GOLD``_d0), .io_write_way_mask(1'b1), \
      .io_hit(GOLD``_i_hit), .io_hit_data_valid(GOLD``_i_v0), \
      .io_hit_data_bits(GOLD``_i_b0)); \
    always @(negedge clk) begin \
      if (rst) begin \
        GOLD``_wen <= 1'b0; \
      end else begin \
        GOLD``_wen <= ($urandom_range(0, 9) < 8); \
        GOLD``_idx <= IDXW'($urandom_range(0, POOL)); \
        GOLD``_d0  <= DATW'($urandom); \
      end \
    end \
    always @(negedge clk) if (!rst) begin \
      #4; \
      checks++; \
      if (GOLD``_g_hit !== GOLD``_i_hit) begin \
        errors++; $display("[%0t] %s hit mismatch: g=%b i=%b idx=%h", $time, `"GOLD`", GOLD``_g_hit, GOLD``_i_hit, GOLD``_idx); \
      end else if (GOLD``_g_hit === 1'b1) begin \
        GOLD``_hits++; \
        if (HASVLD && GOLD``_g_v0 !== GOLD``_i_v0) begin \
          errors++; $display("[%0t] %s valid mismatch: g=%b i=%b", $time, `"GOLD`", GOLD``_g_v0, GOLD``_i_v0); \
        end \
        if (GOLD``_g_v0 === 1'b1 && GOLD``_g_b0 !== GOLD``_i_b0) begin \
          errors++; $display("[%0t] %s data mismatch: g=%h i=%h", $time, `"GOLD`", GOLD``_g_b0, GOLD``_i_b0); \
        end \
      end \
    end

  // 变体例化：索引值域取 4×条目数，保证足够命中率
  `WRBYP_PAIR_1W(WrBypass,    9,  3,  8, 31, 1)
  `WRBYP_PAIR_2W(WrBypass_32, 11, 2,  8, 31)
  `WRBYP_PAIR_2W(WrBypass_33, 8,  6, 16, 63)
  `WRBYP_PAIR_1W(WrBypass_41, 8,  2,  4, 15, 0)
  `WRBYP_PAIR_1W(WrBypass_43, 9,  2,  4, 15, 0)

  // ---------------------------------------------------------------------------
  // 主控：复位、中途复位、收尾
  // ---------------------------------------------------------------------------
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 50000;

    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb);

    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // 前半程
    repeat (NCYCLES / 2) @(posedge clk);

    // 中途异步复位（验证复位行为一致）
    @(negedge clk);
    rst = 1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // 后半程
    repeat (NCYCLES / 2) @(posedge clk);

    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    $display("hits: base=%0d _32=%0d _33=%0d _41=%0d _43=%0d",
             WrBypass_hits, WrBypass_32_hits, WrBypass_33_hits,
             WrBypass_41_hits, WrBypass_43_hits);
    if (errors == 0 && checks > 1000 &&
        WrBypass_hits > 100 && WrBypass_32_hits > 100 && WrBypass_33_hits > 100 &&
        WrBypass_41_hits > 100 && WrBypass_43_hits > 100)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end

endmodule
