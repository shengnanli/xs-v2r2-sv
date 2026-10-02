// Depth1QueueLeaves5 tb —— 族 D（5 个深度 1 队列叶）双例化逐拍比对。
// golden <M>（u_g_*）vs 重写 <M>_xs（u_i_*，由 derive_ut_impl.py 从 rtl/ 派生改名）。
// 五个变体共用 clock/reset、各自独立随机激励，逐拍 4 态比全部输出（共 25 个）。
// 激励形态：deq_ready / enq_valid 每 2000 拍换相（75%↔25%、50%↔87.5%），
// 覆盖满 / 空 / 同拍入出（PIPE=1 变体）/ 背靠背；中途再复位一次覆盖复位路径。
//
// 覆盖闸（防"DUT 根本没动也全绿"，下限随 NCYCLES 缩放）：
//   checks  比对总次数，必须 == NCYCLES*25（少一次都说明有输出没被比到）；
//   xskip   因任一侧为 X 而跳过的比对，必须 == 0（initreg+0 下不该有 X）；
//   toggled 每变体全部输出都必须翻转过（缺一判 FAIL 并点名）；
//   n10/n01/n11 只进不出 / 只出不进 / 同拍入出 的握手次数（n11 对 PIPE=0 的
//           Queue1_BundleMap 结构性为 0 —— 反向闸：它必须恒 0）；
//   b2b     背靠背：pipe 变体 = 连续两拍 enq fire；bmap = 入队次拍即出队；
//   hibit   每变体最宽字段的最高位被真实打入过（位宽写错时该计数恒 0）。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int unsigned N_OUT = 25;   // 8+3+8+2+4，五变体输出总数

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint cyc = 0;
  longint checks = 0, errors = 0, xskip = 0, fires = 0;

  // 宽随机：$urandom 一次给 32 位，拼够位宽。
  function automatic logic [2047:0] rnd(input int bw);
    logic [2047:0] v;
    v = '0;
    for (int i = 0; i < bw; i += 32) v[i+:32] = $urandom;
    return v;
  endfunction

  // 比一路输出：任一侧 X 记 xskip（不比），否则 4 态 !==。
  `define CMP(S) \
    checks++; \
    if ($isunknown(g_``S) || $isunknown(i_``S)) begin xskip++; end \
    else if (g_``S !== i_``S) begin \
      errors++; \
      if (errors <= 40) $display("[cyc %0d] MISMATCH %s g=%h i=%h", cyc, `"S`", g_``S, i_``S); \
    end

  // 记录一路输出的翻转（对 p_ 上一拍采样值）。
  `define TOG(S) \
    if (g_``S !== p_``S) t_``S = 1'b1; \
    p_``S = g_``S;

  // ======================= Queue1_PrefetchReq（PIPE=1，8 输出） =======================
  logic        req__io_enq_valid;
  logic [32:0] req__io_enq_bits_tag;
  logic [8:0]  req__io_enq_bits_set;
  logic [43:0] req__io_enq_bits_vaddr;
  logic        req__io_enq_bits_needT;
  logic [6:0]  req__io_enq_bits_source;
  logic [4:0]  req__io_enq_bits_pfSource;
  logic        req__io_deq_ready;

  wire        g_req__io_enq_ready, i_req__io_enq_ready;
  wire        g_req__io_deq_valid, i_req__io_deq_valid;
  wire [32:0] g_req__io_deq_bits_tag, i_req__io_deq_bits_tag;
  wire [8:0]  g_req__io_deq_bits_set, i_req__io_deq_bits_set;
  wire [43:0] g_req__io_deq_bits_vaddr, i_req__io_deq_bits_vaddr;
  wire        g_req__io_deq_bits_needT, i_req__io_deq_bits_needT;
  wire [6:0]  g_req__io_deq_bits_source, i_req__io_deq_bits_source;
  wire [4:0]  g_req__io_deq_bits_pfSource, i_req__io_deq_bits_pfSource;

  Queue1_PrefetchReq u_g_req (
    .clock(clock), .reset(reset),
    .io_enq_ready(g_req__io_enq_ready), .io_enq_valid(req__io_enq_valid),
    .io_enq_bits_tag(req__io_enq_bits_tag), .io_enq_bits_set(req__io_enq_bits_set),
    .io_enq_bits_vaddr(req__io_enq_bits_vaddr), .io_enq_bits_needT(req__io_enq_bits_needT),
    .io_enq_bits_source(req__io_enq_bits_source), .io_enq_bits_pfSource(req__io_enq_bits_pfSource),
    .io_deq_ready(req__io_deq_ready), .io_deq_valid(g_req__io_deq_valid),
    .io_deq_bits_tag(g_req__io_deq_bits_tag), .io_deq_bits_set(g_req__io_deq_bits_set),
    .io_deq_bits_vaddr(g_req__io_deq_bits_vaddr), .io_deq_bits_needT(g_req__io_deq_bits_needT),
    .io_deq_bits_source(g_req__io_deq_bits_source), .io_deq_bits_pfSource(g_req__io_deq_bits_pfSource)
  );
  Queue1_PrefetchReq_xs u_i_req (
    .clock(clock), .reset(reset),
    .io_enq_ready(i_req__io_enq_ready), .io_enq_valid(req__io_enq_valid),
    .io_enq_bits_tag(req__io_enq_bits_tag), .io_enq_bits_set(req__io_enq_bits_set),
    .io_enq_bits_vaddr(req__io_enq_bits_vaddr), .io_enq_bits_needT(req__io_enq_bits_needT),
    .io_enq_bits_source(req__io_enq_bits_source), .io_enq_bits_pfSource(req__io_enq_bits_pfSource),
    .io_deq_ready(req__io_deq_ready), .io_deq_valid(i_req__io_deq_valid),
    .io_deq_bits_tag(i_req__io_deq_bits_tag), .io_deq_bits_set(i_req__io_deq_bits_set),
    .io_deq_bits_vaddr(i_req__io_deq_bits_vaddr), .io_deq_bits_needT(i_req__io_deq_bits_needT),
    .io_deq_bits_source(i_req__io_deq_bits_source), .io_deq_bits_pfSource(i_req__io_deq_bits_pfSource)
  );

  // ======================= Queue1_PrefetchResp（PIPE=1，3 输出） =======================
  logic        resp__io_enq_valid;
  logic [32:0] resp__io_enq_bits_tag;
  logic [8:0]  resp__io_enq_bits_set;
  logic [43:0] resp__io_enq_bits_vaddr;
  logic [4:0]  resp__io_enq_bits_pfSource;
  logic        resp__io_deq_ready;

  wire       g_resp__io_enq_ready, i_resp__io_enq_ready;
  wire       g_resp__io_deq_valid, i_resp__io_deq_valid;
  wire [4:0] g_resp__io_deq_bits_pfSource, i_resp__io_deq_bits_pfSource;

  Queue1_PrefetchResp u_g_resp (
    .clock(clock), .reset(reset),
    .io_enq_ready(g_resp__io_enq_ready), .io_enq_valid(resp__io_enq_valid),
    .io_enq_bits_tag(resp__io_enq_bits_tag), .io_enq_bits_set(resp__io_enq_bits_set),
    .io_enq_bits_vaddr(resp__io_enq_bits_vaddr), .io_enq_bits_pfSource(resp__io_enq_bits_pfSource),
    .io_deq_ready(resp__io_deq_ready), .io_deq_valid(g_resp__io_deq_valid),
    .io_deq_bits_pfSource(g_resp__io_deq_bits_pfSource)
  );
  Queue1_PrefetchResp_xs u_i_resp (
    .clock(clock), .reset(reset),
    .io_enq_ready(i_resp__io_enq_ready), .io_enq_valid(resp__io_enq_valid),
    .io_enq_bits_tag(resp__io_enq_bits_tag), .io_enq_bits_set(resp__io_enq_bits_set),
    .io_enq_bits_vaddr(resp__io_enq_bits_vaddr), .io_enq_bits_pfSource(resp__io_enq_bits_pfSource),
    .io_deq_ready(resp__io_deq_ready), .io_deq_valid(i_resp__io_deq_valid),
    .io_deq_bits_pfSource(i_resp__io_deq_bits_pfSource)
  );

  // ======================= Queue1_PrefetchTrain（PIPE=1，8 输出） =======================
  logic        train__io_enq_valid;
  logic [32:0] train__io_enq_bits_tag;
  logic [8:0]  train__io_enq_bits_set;
  logic        train__io_enq_bits_needT;
  logic [6:0]  train__io_enq_bits_source;
  logic [43:0] train__io_enq_bits_vaddr;
  logic        train__io_enq_bits_hit;
  logic        train__io_enq_bits_prefetched;
  logic [2:0]  train__io_enq_bits_pfsource;
  logic [4:0]  train__io_enq_bits_reqsource;
  logic        train__io_deq_ready;

  wire        g_train__io_enq_ready, i_train__io_enq_ready;
  wire        g_train__io_deq_valid, i_train__io_deq_valid;
  wire [32:0] g_train__io_deq_bits_tag, i_train__io_deq_bits_tag;
  wire [8:0]  g_train__io_deq_bits_set, i_train__io_deq_bits_set;
  wire        g_train__io_deq_bits_needT, i_train__io_deq_bits_needT;
  wire [6:0]  g_train__io_deq_bits_source, i_train__io_deq_bits_source;
  wire [43:0] g_train__io_deq_bits_vaddr, i_train__io_deq_bits_vaddr;
  wire [4:0]  g_train__io_deq_bits_reqsource, i_train__io_deq_bits_reqsource;

  Queue1_PrefetchTrain u_g_train (
    .clock(clock), .reset(reset),
    .io_enq_ready(g_train__io_enq_ready), .io_enq_valid(train__io_enq_valid),
    .io_enq_bits_tag(train__io_enq_bits_tag), .io_enq_bits_set(train__io_enq_bits_set),
    .io_enq_bits_needT(train__io_enq_bits_needT), .io_enq_bits_source(train__io_enq_bits_source),
    .io_enq_bits_vaddr(train__io_enq_bits_vaddr), .io_enq_bits_hit(train__io_enq_bits_hit),
    .io_enq_bits_prefetched(train__io_enq_bits_prefetched),
    .io_enq_bits_pfsource(train__io_enq_bits_pfsource),
    .io_enq_bits_reqsource(train__io_enq_bits_reqsource),
    .io_deq_ready(train__io_deq_ready), .io_deq_valid(g_train__io_deq_valid),
    .io_deq_bits_tag(g_train__io_deq_bits_tag), .io_deq_bits_set(g_train__io_deq_bits_set),
    .io_deq_bits_needT(g_train__io_deq_bits_needT), .io_deq_bits_source(g_train__io_deq_bits_source),
    .io_deq_bits_vaddr(g_train__io_deq_bits_vaddr), .io_deq_bits_reqsource(g_train__io_deq_bits_reqsource)
  );
  Queue1_PrefetchTrain_xs u_i_train (
    .clock(clock), .reset(reset),
    .io_enq_ready(i_train__io_enq_ready), .io_enq_valid(train__io_enq_valid),
    .io_enq_bits_tag(train__io_enq_bits_tag), .io_enq_bits_set(train__io_enq_bits_set),
    .io_enq_bits_needT(train__io_enq_bits_needT), .io_enq_bits_source(train__io_enq_bits_source),
    .io_enq_bits_vaddr(train__io_enq_bits_vaddr), .io_enq_bits_hit(train__io_enq_bits_hit),
    .io_enq_bits_prefetched(train__io_enq_bits_prefetched),
    .io_enq_bits_pfsource(train__io_enq_bits_pfsource),
    .io_enq_bits_reqsource(train__io_enq_bits_reqsource),
    .io_deq_ready(train__io_deq_ready), .io_deq_valid(i_train__io_deq_valid),
    .io_deq_bits_tag(i_train__io_deq_bits_tag), .io_deq_bits_set(i_train__io_deq_bits_set),
    .io_deq_bits_needT(i_train__io_deq_bits_needT), .io_deq_bits_source(i_train__io_deq_bits_source),
    .io_deq_bits_vaddr(i_train__io_deq_bits_vaddr), .io_deq_bits_reqsource(i_train__io_deq_bits_reqsource)
  );

  // ======================= Queue1_UInt32（无 ready，2 输出） =======================
  logic        u32__io_enq_valid;
  logic [31:0] u32__io_enq_bits;

  wire        g_u32__io_deq_valid, i_u32__io_deq_valid;
  wire [31:0] g_u32__io_deq_bits, i_u32__io_deq_bits;

  Queue1_UInt32 u_g_u32 (
    .clock(clock), .reset(reset),
    .io_enq_valid(u32__io_enq_valid), .io_enq_bits(u32__io_enq_bits),
    .io_deq_valid(g_u32__io_deq_valid), .io_deq_bits(g_u32__io_deq_bits)
  );
  Queue1_UInt32_xs u_i_u32 (
    .clock(clock), .reset(reset),
    .io_enq_valid(u32__io_enq_valid), .io_enq_bits(u32__io_enq_bits),
    .io_deq_valid(i_u32__io_deq_valid), .io_deq_bits(i_u32__io_deq_bits)
  );

  // ======================= Queue1_BundleMap（PIPE=0，4 输出） =======================
  logic        bmap__io_enq_valid;
  logic [3:0]  bmap__io_enq_bits_tl_state_size;
  logic [14:0] bmap__io_enq_bits_tl_state_source;
  logic        bmap__io_deq_ready;

  wire        g_bmap__io_enq_ready, i_bmap__io_enq_ready;
  wire        g_bmap__io_deq_valid, i_bmap__io_deq_valid;
  wire [3:0]  g_bmap__io_deq_bits_tl_state_size, i_bmap__io_deq_bits_tl_state_size;
  wire [14:0] g_bmap__io_deq_bits_tl_state_source, i_bmap__io_deq_bits_tl_state_source;

  Queue1_BundleMap u_g_bmap (
    .clock(clock), .reset(reset),
    .io_enq_ready(g_bmap__io_enq_ready), .io_enq_valid(bmap__io_enq_valid),
    .io_enq_bits_tl_state_size(bmap__io_enq_bits_tl_state_size),
    .io_enq_bits_tl_state_source(bmap__io_enq_bits_tl_state_source),
    .io_deq_ready(bmap__io_deq_ready), .io_deq_valid(g_bmap__io_deq_valid),
    .io_deq_bits_tl_state_size(g_bmap__io_deq_bits_tl_state_size),
    .io_deq_bits_tl_state_source(g_bmap__io_deq_bits_tl_state_source)
  );
  Queue1_BundleMap_xs u_i_bmap (
    .clock(clock), .reset(reset),
    .io_enq_ready(i_bmap__io_enq_ready), .io_enq_valid(bmap__io_enq_valid),
    .io_enq_bits_tl_state_size(bmap__io_enq_bits_tl_state_size),
    .io_enq_bits_tl_state_source(bmap__io_enq_bits_tl_state_source),
    .io_deq_ready(bmap__io_deq_ready), .io_deq_valid(i_bmap__io_deq_valid),
    .io_deq_bits_tl_state_size(i_bmap__io_deq_bits_tl_state_size),
    .io_deq_bits_tl_state_source(i_bmap__io_deq_bits_tl_state_source)
  );

  // ---------------- 激励（每 2000 拍换相，造满/空/同拍入出/背靠背） ----------------
  task automatic drive_all();
    // ph=1: enq 50% / deq 75%（队列多空，fill/drain 交替密集）
    // ph=0: enq 87.5% / deq 25%（队列常满，enq_ready 长压 0，同拍入出密集）
    bit ph;
    ph = ((cyc / 2000) % 2) != 0;
    req__io_enq_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    req__io_enq_bits_tag = rnd(33);
    req__io_enq_bits_set = rnd(9);
    req__io_enq_bits_vaddr = rnd(44);
    req__io_enq_bits_needT = $urandom % 2;
    req__io_enq_bits_source = rnd(7);
    req__io_enq_bits_pfSource = rnd(5);
    req__io_deq_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);

    resp__io_enq_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    resp__io_enq_bits_tag = rnd(33);
    resp__io_enq_bits_set = rnd(9);
    resp__io_enq_bits_vaddr = rnd(44);
    resp__io_enq_bits_pfSource = rnd(5);
    resp__io_deq_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);

    train__io_enq_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    train__io_enq_bits_tag = rnd(33);
    train__io_enq_bits_set = rnd(9);
    train__io_enq_bits_needT = $urandom % 2;
    train__io_enq_bits_source = rnd(7);
    train__io_enq_bits_vaddr = rnd(44);
    train__io_enq_bits_hit = $urandom % 2;
    train__io_enq_bits_prefetched = $urandom % 2;
    train__io_enq_bits_pfsource = rnd(3);
    train__io_enq_bits_reqsource = rnd(5);
    train__io_deq_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);

    u32__io_enq_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    u32__io_enq_bits = rnd(32);

    bmap__io_enq_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    bmap__io_enq_bits_tl_state_size = rnd(4);
    bmap__io_enq_bits_tl_state_source = rnd(15);
    bmap__io_deq_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask

  // ---------------- 逐拍比对（全部 25 路输出） ----------------
  task automatic check_all();
    `CMP(req__io_enq_ready)
    `CMP(req__io_deq_valid)
    `CMP(req__io_deq_bits_tag)
    `CMP(req__io_deq_bits_set)
    `CMP(req__io_deq_bits_vaddr)
    `CMP(req__io_deq_bits_needT)
    `CMP(req__io_deq_bits_source)
    `CMP(req__io_deq_bits_pfSource)
    `CMP(resp__io_enq_ready)
    `CMP(resp__io_deq_valid)
    `CMP(resp__io_deq_bits_pfSource)
    `CMP(train__io_enq_ready)
    `CMP(train__io_deq_valid)
    `CMP(train__io_deq_bits_tag)
    `CMP(train__io_deq_bits_set)
    `CMP(train__io_deq_bits_needT)
    `CMP(train__io_deq_bits_source)
    `CMP(train__io_deq_bits_vaddr)
    `CMP(train__io_deq_bits_reqsource)
    `CMP(u32__io_deq_valid)
    `CMP(u32__io_deq_bits)
    `CMP(bmap__io_enq_ready)
    `CMP(bmap__io_deq_valid)
    `CMP(bmap__io_deq_bits_tl_state_size)
    `CMP(bmap__io_deq_bits_tl_state_source)
  endtask

  // ---------------- 覆盖：翻转 + 握手分类 + 满/空 + 高位 ----------------
  logic        p_req__io_enq_ready;   bit t_req__io_enq_ready;
  logic        p_req__io_deq_valid;   bit t_req__io_deq_valid;
  logic [32:0] p_req__io_deq_bits_tag;   bit t_req__io_deq_bits_tag;
  logic [8:0]  p_req__io_deq_bits_set;   bit t_req__io_deq_bits_set;
  logic [43:0] p_req__io_deq_bits_vaddr;   bit t_req__io_deq_bits_vaddr;
  logic        p_req__io_deq_bits_needT;   bit t_req__io_deq_bits_needT;
  logic [6:0]  p_req__io_deq_bits_source;   bit t_req__io_deq_bits_source;
  logic [4:0]  p_req__io_deq_bits_pfSource;   bit t_req__io_deq_bits_pfSource;
  logic        p_resp__io_enq_ready;   bit t_resp__io_enq_ready;
  logic        p_resp__io_deq_valid;   bit t_resp__io_deq_valid;
  logic [4:0]  p_resp__io_deq_bits_pfSource;   bit t_resp__io_deq_bits_pfSource;
  logic        p_train__io_enq_ready;   bit t_train__io_enq_ready;
  logic        p_train__io_deq_valid;   bit t_train__io_deq_valid;
  logic [32:0] p_train__io_deq_bits_tag;   bit t_train__io_deq_bits_tag;
  logic [8:0]  p_train__io_deq_bits_set;   bit t_train__io_deq_bits_set;
  logic        p_train__io_deq_bits_needT;   bit t_train__io_deq_bits_needT;
  logic [6:0]  p_train__io_deq_bits_source;   bit t_train__io_deq_bits_source;
  logic [43:0] p_train__io_deq_bits_vaddr;   bit t_train__io_deq_bits_vaddr;
  logic [4:0]  p_train__io_deq_bits_reqsource;   bit t_train__io_deq_bits_reqsource;
  logic        p_u32__io_deq_valid;   bit t_u32__io_deq_valid;
  logic [31:0] p_u32__io_deq_bits;   bit t_u32__io_deq_bits;
  logic        p_bmap__io_enq_ready;   bit t_bmap__io_enq_ready;
  logic        p_bmap__io_deq_valid;   bit t_bmap__io_deq_valid;
  logic [3:0]  p_bmap__io_deq_bits_tl_state_size;   bit t_bmap__io_deq_bits_tl_state_size;
  logic [14:0] p_bmap__io_deq_bits_tl_state_source;   bit t_bmap__io_deq_bits_tl_state_source;

  // 每变体：n10 只进不出 / n01 只出不进 / n11 同拍入出 / b2b 背靠背 /
  //         full/empty 拍数 / hibit 最宽字段最高位入队次数 / 上一拍 enq fire
  longint n10_req = 0, n01_req = 0, n11_req = 0, b2b_req = 0, full_req = 0, empty_req = 0, hibit_req = 0;
  longint n10_resp = 0, n01_resp = 0, n11_resp = 0, b2b_resp = 0, full_resp = 0, empty_resp = 0, hibit_resp = 0;
  longint n10_train = 0, n01_train = 0, n11_train = 0, b2b_train = 0, full_train = 0, empty_train = 0, hibit_train = 0;
  longint n10_u32 = 0, n01_u32 = 0, n11_u32 = 0, b2b_u32 = 0, full_u32 = 0, empty_u32 = 0, hibit_u32 = 0;
  longint n10_bmap = 0, n01_bmap = 0, n11_bmap = 0, b2b_bmap = 0, full_bmap = 0, empty_bmap = 0, hibit_bmap = 0;
  bit prev_enq_req = 0, prev_enq_resp = 0, prev_enq_train = 0, prev_enq_u32 = 0, prev_enq_bmap = 0;

  // 一路变体的覆盖采样：enq/deq fire 分类、背靠背、最高位；满/空拍数在 cover_all 里直接计。
  // pipe0=1 时 b2b 定义为"入队次拍即出队"（PIPE=0 不存在连续两拍入队）。
  task automatic cover_one(input bit enq_fire, input bit deq_fire, input bit hibit,
                           input bit pipe0,
                           inout longint n10, n01, n11, b2b, nhibit,
                           inout bit prev_enq);
    if (enq_fire && !deq_fire) n10++;
    if (!enq_fire && deq_fire) n01++;
    if (enq_fire && deq_fire)  n11++;
    if (pipe0 ? (prev_enq && deq_fire) : (prev_enq && enq_fire)) b2b++;
    if (enq_fire && hibit) nhibit++;
    prev_enq = enq_fire;
    fires += (enq_fire ? 1 : 0) + (deq_fire ? 1 : 0);
  endtask

  task automatic cover_all();
    `TOG(req__io_enq_ready)
    `TOG(req__io_deq_valid)
    `TOG(req__io_deq_bits_tag)
    `TOG(req__io_deq_bits_set)
    `TOG(req__io_deq_bits_vaddr)
    `TOG(req__io_deq_bits_needT)
    `TOG(req__io_deq_bits_source)
    `TOG(req__io_deq_bits_pfSource)
    `TOG(resp__io_enq_ready)
    `TOG(resp__io_deq_valid)
    `TOG(resp__io_deq_bits_pfSource)
    `TOG(train__io_enq_ready)
    `TOG(train__io_deq_valid)
    `TOG(train__io_deq_bits_tag)
    `TOG(train__io_deq_bits_set)
    `TOG(train__io_deq_bits_needT)
    `TOG(train__io_deq_bits_source)
    `TOG(train__io_deq_bits_vaddr)
    `TOG(train__io_deq_bits_reqsource)
    `TOG(u32__io_deq_valid)
    `TOG(u32__io_deq_bits)
    `TOG(bmap__io_enq_ready)
    `TOG(bmap__io_deq_valid)
    `TOG(bmap__io_deq_bits_tl_state_size)
    `TOG(bmap__io_deq_bits_tl_state_source)

    if (g_req__io_deq_valid) full_req++; else empty_req++;
    cover_one(req__io_enq_valid && g_req__io_enq_ready, g_req__io_deq_valid && req__io_deq_ready,
              req__io_enq_bits_vaddr[43], 1'b0,
              n10_req, n01_req, n11_req, b2b_req, hibit_req, prev_enq_req);
    if (g_resp__io_deq_valid) full_resp++; else empty_resp++;
    cover_one(resp__io_enq_valid && g_resp__io_enq_ready, g_resp__io_deq_valid && resp__io_deq_ready,
              resp__io_enq_bits_vaddr[43], 1'b0,
              n10_resp, n01_resp, n11_resp, b2b_resp, hibit_resp, prev_enq_resp);
    if (g_train__io_deq_valid) full_train++; else empty_train++;
    cover_one(train__io_enq_valid && g_train__io_enq_ready, g_train__io_deq_valid && train__io_deq_ready,
              train__io_enq_bits_vaddr[43], 1'b0,
              n10_train, n01_train, n11_train, b2b_train, hibit_train, prev_enq_train);
    // u32 无 ready：enq 恒被收（enq_ready 恒 1）、deq 恒被接走（deq_ready 恒 1）
    if (g_u32__io_deq_valid) full_u32++; else empty_u32++;
    cover_one(u32__io_enq_valid, g_u32__io_deq_valid,
              u32__io_enq_bits[31], 1'b0,
              n10_u32, n01_u32, n11_u32, b2b_u32, hibit_u32, prev_enq_u32);
    // bmap 是 PIPE=0：同拍入出结构性不存在；背靠背 = 入队次拍即出队
    if (g_bmap__io_deq_valid) full_bmap++; else empty_bmap++;
    cover_one(bmap__io_enq_valid && g_bmap__io_enq_ready, g_bmap__io_deq_valid && bmap__io_deq_ready,
              bmap__io_enq_bits_tl_state_source[14], 1'b1,
              n10_bmap, n01_bmap, n11_bmap, b2b_bmap, hibit_bmap, prev_enq_bmap);
  endtask

  // ---------------- 收尾闸 ----------------
  task automatic gate_variant(input string nm, input int n_out,
                              input int toggled,
                              input longint n10, n01, n11, b2b, nfull, nempty, nhibit,
                              input bit pipe0);
    bit bad;
    bad = 0;
    if (toggled != n_out) begin
      bad = 1; $display("COV FAIL %s: toggled=%0d/%0d", nm, toggled, n_out);
    end
    if (n10 < NCYCLES/20)  begin bad = 1; $display("COV FAIL %s: n10(enq-only)=%0d < %0d", nm, n10, NCYCLES/20); end
    if (n01 < NCYCLES/20)  begin bad = 1; $display("COV FAIL %s: n01(deq-only)=%0d < %0d", nm, n01, NCYCLES/20); end
    if (pipe0) begin
      if (n11 != 0) begin bad = 1; $display("COV FAIL %s: n11=%0d, PIPE=0 结构性不可能同拍入出", nm, n11); end
    end else if (n11 < NCYCLES/40) begin
      bad = 1; $display("COV FAIL %s: n11(same-cycle)=%0d < %0d", nm, n11, NCYCLES/40);
    end
    if (b2b < NCYCLES/40)    begin bad = 1; $display("COV FAIL %s: b2b=%0d < %0d", nm, b2b, NCYCLES/40); end
    if (nfull < NCYCLES/20)  begin bad = 1; $display("COV FAIL %s: full cycles=%0d < %0d", nm, nfull, NCYCLES/20); end
    if (nempty < NCYCLES/20) begin bad = 1; $display("COV FAIL %s: empty cycles=%0d < %0d", nm, nempty, NCYCLES/20); end
    if (nhibit < NCYCLES/200) begin bad = 1; $display("COV FAIL %s: hibit enq=%0d < %0d", nm, nhibit, NCYCLES/200); end
    $display("COV %s: n10=%0d n01=%0d n11=%0d b2b=%0d full=%0d empty=%0d hibit=%0d toggled=%0d/%0d",
             nm, n10, n01, n11, b2b, nfull, nempty, nhibit, toggled, n_out);
    if (bad) begin $display("TEST FAILED (coverage: %s)", nm); $fatal(1); end
  endtask

  function automatic int sum_tog_req();
    return t_req__io_enq_ready + t_req__io_deq_valid + t_req__io_deq_bits_tag +
           t_req__io_deq_bits_set + t_req__io_deq_bits_vaddr + t_req__io_deq_bits_needT +
           t_req__io_deq_bits_source + t_req__io_deq_bits_pfSource;
  endfunction
  function automatic int sum_tog_resp();
    return t_resp__io_enq_ready + t_resp__io_deq_valid + t_resp__io_deq_bits_pfSource;
  endfunction
  function automatic int sum_tog_train();
    return t_train__io_enq_ready + t_train__io_deq_valid + t_train__io_deq_bits_tag +
           t_train__io_deq_bits_set + t_train__io_deq_bits_needT + t_train__io_deq_bits_source +
           t_train__io_deq_bits_vaddr + t_train__io_deq_bits_reqsource;
  endfunction
  function automatic int sum_tog_u32();
    return t_u32__io_deq_valid + t_u32__io_deq_bits;
  endfunction
  function automatic int sum_tog_bmap();
    return t_bmap__io_enq_ready + t_bmap__io_deq_valid +
           t_bmap__io_deq_bits_tl_state_size + t_bmap__io_deq_bits_tl_state_source;
  endfunction

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    // 输入与 toggle 采样初值
    req__io_enq_valid = '0; req__io_enq_bits_tag = '0; req__io_enq_bits_set = '0;
    req__io_enq_bits_vaddr = '0; req__io_enq_bits_needT = '0; req__io_enq_bits_source = '0;
    req__io_enq_bits_pfSource = '0; req__io_deq_ready = '0;
    resp__io_enq_valid = '0; resp__io_enq_bits_tag = '0; resp__io_enq_bits_set = '0;
    resp__io_enq_bits_vaddr = '0; resp__io_enq_bits_pfSource = '0; resp__io_deq_ready = '0;
    train__io_enq_valid = '0; train__io_enq_bits_tag = '0; train__io_enq_bits_set = '0;
    train__io_enq_bits_needT = '0; train__io_enq_bits_source = '0; train__io_enq_bits_vaddr = '0;
    train__io_enq_bits_hit = '0; train__io_enq_bits_prefetched = '0;
    train__io_enq_bits_pfsource = '0; train__io_enq_bits_reqsource = '0; train__io_deq_ready = '0;
    u32__io_enq_valid = '0; u32__io_enq_bits = '0;
    bmap__io_enq_valid = '0; bmap__io_enq_bits_tl_state_size = '0;
    bmap__io_enq_bits_tl_state_source = '0; bmap__io_deq_ready = '0;
    p_req__io_enq_ready = '0; p_req__io_deq_valid = '0; p_req__io_deq_bits_tag = '0;
    p_req__io_deq_bits_set = '0; p_req__io_deq_bits_vaddr = '0; p_req__io_deq_bits_needT = '0;
    p_req__io_deq_bits_source = '0; p_req__io_deq_bits_pfSource = '0;
    p_resp__io_enq_ready = '0; p_resp__io_deq_valid = '0; p_resp__io_deq_bits_pfSource = '0;
    p_train__io_enq_ready = '0; p_train__io_deq_valid = '0; p_train__io_deq_bits_tag = '0;
    p_train__io_deq_bits_set = '0; p_train__io_deq_bits_needT = '0; p_train__io_deq_bits_source = '0;
    p_train__io_deq_bits_vaddr = '0; p_train__io_deq_bits_reqsource = '0;
    p_u32__io_deq_valid = '0; p_u32__io_deq_bits = '0;
    p_bmap__io_enq_ready = '0; p_bmap__io_deq_valid = '0;
    p_bmap__io_deq_bits_tl_state_size = '0; p_bmap__io_deq_bits_tl_state_source = '0;

    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;
    for (int unsigned c = 0; c < NCYCLES; c++) begin
      cyc = c;
      // 中途再复位一次，覆盖复位路径（两侧同拍同源）。
      if (c == NCYCLES/2) begin
        @(negedge clock); reset = 1'b1;
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 1'b0;
      end
      @(negedge clock);
      drive_all();
      #1 check_all();
      cover_all();
      @(posedge clock);
    end

    $display("Depth1QueueLeaves5 checks=%0d errors=%0d xskip=%0d fires=%0d",
             checks, errors, xskip, fires);
    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end
    if (checks != longint'(NCYCLES) * N_OUT) begin
      $display("TEST FAILED (coverage: checks=%0d != NCYCLES*%0d=%0d)",
               checks, N_OUT, longint'(NCYCLES) * N_OUT);
      $fatal(1);
    end
    if (xskip != 0) begin
      $display("TEST FAILED (coverage: %0d comparisons skipped on X)", xskip); $fatal(1);
    end
    if (fires < NCYCLES) begin
      $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)", fires, NCYCLES);
      $fatal(1);
    end
    gate_variant("Queue1_PrefetchReq", 8, sum_tog_req(),
                 n10_req, n01_req, n11_req, b2b_req, full_req, empty_req, hibit_req, 1'b0);
    gate_variant("Queue1_PrefetchResp", 3, sum_tog_resp(),
                 n10_resp, n01_resp, n11_resp, b2b_resp, full_resp, empty_resp, hibit_resp, 1'b0);
    gate_variant("Queue1_PrefetchTrain", 8, sum_tog_train(),
                 n10_train, n01_train, n11_train, b2b_train, full_train, empty_train, hibit_train, 1'b0);
    gate_variant("Queue1_UInt32", 2, sum_tog_u32(),
                 n10_u32, n01_u32, n11_u32, b2b_u32, full_u32, empty_u32, hibit_u32, 1'b0);
    gate_variant("Queue1_BundleMap", 4, sum_tog_bmap(),
                 n10_bmap, n01_bmap, n11_bmap, b2b_bmap, full_bmap, empty_bmap, hibit_bmap, 1'b1);
    $display("TEST PASSED");
    $finish;
  end
endmodule
