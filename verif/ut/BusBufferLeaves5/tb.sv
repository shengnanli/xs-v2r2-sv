// BusBufferLeaves5 tb —— 族 G（5 个总线缓冲叶）双例化逐拍比对。
// golden <M>（u_g_*）vs 重写 <M>_xs（u_i_*，由 derive_ut_impl.py 从 rtl/ 派生改名）。
// 五个变体共用 clock/reset、各自独立随机激励，逐拍 4 态比全部输出（共 52 个）。
// 激励形态：enq_valid / deq_ready 每 2000 拍换相（50%↔87.5%、75%↔25%），
// 覆盖满 / 空 / 同拍入出 / 背靠背 / bits 保持（repeat 压住时入侧 bits 每拍仍在变）
// 与 bits 变化；Repeater 的 io_repeat 全程 50% 随机；中途再复位一次覆盖复位路径。
//
// 覆盖闸（防"DUT 根本没动也全绿"，下限随 NCYCLES 缩放）：
//   checks  比对总次数，必须 == NCYCLES*52（少一次都说明有输出没被比到）；
//   xskip   因任一侧为 X 而跳过的比对，必须 == 0（initreg+0 下不该有 X）；
//   toggled 每变体全部输出都必须翻转过（缺一判 FAIL 并点名）；
//   n10/n01/n11 只进不出 / 只出不进 / 同拍入出 的握手次数（n10 对 Repeater 结构性
//           为 0——enq fire 蕴含同拍 deq fire——反向闸：它必须恒 0）；
//   b2b     背靠背：连续两拍 enq fire；
//   full/empty 拍数（rp2 无 io_full 端口，用 deq_ready & ~enq_ready 推断满）；
//   hibit   每变体最宽字段的最高位被真实打入过（位宽写错时该计数恒 0）；
//   saves   （仅 Repeater）enq fire 且 io_repeat=1 的次数——repeat 路径必须真被打到；
//   repdeq  （仅 Repeater）满时 deq fire 的次数——重复发送的拍必须真被接走过。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int unsigned N_OUT = 52;   // 8+5+9+15+15，五变体输出总数

  bit clock = 0;
  always #5 clock = ~clock;
  bit reset;
  longint cyc = 0;
  longint checks = 0, errors = 0, xskip = 0, fires = 0;

  // 宽随机：$urandom 一次给 32 位，拼够位宽。
  function automatic logic [511:0] rnd(input int bw);
    logic [511:0] v;
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

  // ======================= SpillRegister（AW/AR，6 位 id，8 输出） =======================
  logic        sr0__io_in_valid;
  logic [5:0]  sr0__io_in_bits_id;
  logic [48:0] sr0__io_in_bits_addr;
  logic [7:0]  sr0__io_in_bits_len;
  logic [2:0]  sr0__io_in_bits_size;
  logic [1:0]  sr0__io_in_bits_burst;
  logic [3:0]  sr0__io_in_bits_qos;
  logic        sr0__io_out_ready;

  wire        g_sr0__io_in_ready, i_sr0__io_in_ready;
  wire        g_sr0__io_out_valid, i_sr0__io_out_valid;
  wire [5:0]  g_sr0__io_out_bits_id, i_sr0__io_out_bits_id;
  wire [48:0] g_sr0__io_out_bits_addr, i_sr0__io_out_bits_addr;
  wire [7:0]  g_sr0__io_out_bits_len, i_sr0__io_out_bits_len;
  wire [2:0]  g_sr0__io_out_bits_size, i_sr0__io_out_bits_size;
  wire [1:0]  g_sr0__io_out_bits_burst, i_sr0__io_out_bits_burst;
  wire [3:0]  g_sr0__io_out_bits_qos, i_sr0__io_out_bits_qos;

  SpillRegister u_g_sr0 (
    .clock(clock), .reset(reset),
    .io_in_ready(g_sr0__io_in_ready), .io_in_valid(sr0__io_in_valid),
    .io_in_bits_id(sr0__io_in_bits_id), .io_in_bits_addr(sr0__io_in_bits_addr),
    .io_in_bits_len(sr0__io_in_bits_len), .io_in_bits_size(sr0__io_in_bits_size),
    .io_in_bits_burst(sr0__io_in_bits_burst), .io_in_bits_qos(sr0__io_in_bits_qos),
    .io_out_ready(sr0__io_out_ready), .io_out_valid(g_sr0__io_out_valid),
    .io_out_bits_id(g_sr0__io_out_bits_id), .io_out_bits_addr(g_sr0__io_out_bits_addr),
    .io_out_bits_len(g_sr0__io_out_bits_len), .io_out_bits_size(g_sr0__io_out_bits_size),
    .io_out_bits_burst(g_sr0__io_out_bits_burst), .io_out_bits_qos(g_sr0__io_out_bits_qos)
  );
  SpillRegister_xs u_i_sr0 (
    .clock(clock), .reset(reset),
    .io_in_ready(i_sr0__io_in_ready), .io_in_valid(sr0__io_in_valid),
    .io_in_bits_id(sr0__io_in_bits_id), .io_in_bits_addr(sr0__io_in_bits_addr),
    .io_in_bits_len(sr0__io_in_bits_len), .io_in_bits_size(sr0__io_in_bits_size),
    .io_in_bits_burst(sr0__io_in_bits_burst), .io_in_bits_qos(sr0__io_in_bits_qos),
    .io_out_ready(sr0__io_out_ready), .io_out_valid(i_sr0__io_out_valid),
    .io_out_bits_id(i_sr0__io_out_bits_id), .io_out_bits_addr(i_sr0__io_out_bits_addr),
    .io_out_bits_len(i_sr0__io_out_bits_len), .io_out_bits_size(i_sr0__io_out_bits_size),
    .io_out_bits_burst(i_sr0__io_out_bits_burst), .io_out_bits_qos(i_sr0__io_out_bits_qos)
  );

  // ======================= SpillRegister_2（W，256 位 data，5 输出） =======================
  logic         sr2__io_in_valid;
  logic [255:0] sr2__io_in_bits_data;
  logic [31:0]  sr2__io_in_bits_strb;
  logic         sr2__io_in_bits_last;
  logic         sr2__io_out_ready;

  wire         g_sr2__io_in_ready, i_sr2__io_in_ready;
  wire         g_sr2__io_out_valid, i_sr2__io_out_valid;
  wire [255:0] g_sr2__io_out_bits_data, i_sr2__io_out_bits_data;
  wire [31:0]  g_sr2__io_out_bits_strb, i_sr2__io_out_bits_strb;
  wire         g_sr2__io_out_bits_last, i_sr2__io_out_bits_last;

  SpillRegister_2 u_g_sr2 (
    .clock(clock), .reset(reset),
    .io_in_ready(g_sr2__io_in_ready), .io_in_valid(sr2__io_in_valid),
    .io_in_bits_data(sr2__io_in_bits_data), .io_in_bits_strb(sr2__io_in_bits_strb),
    .io_in_bits_last(sr2__io_in_bits_last),
    .io_out_ready(sr2__io_out_ready), .io_out_valid(g_sr2__io_out_valid),
    .io_out_bits_data(g_sr2__io_out_bits_data), .io_out_bits_strb(g_sr2__io_out_bits_strb),
    .io_out_bits_last(g_sr2__io_out_bits_last)
  );
  SpillRegister_2_xs u_i_sr2 (
    .clock(clock), .reset(reset),
    .io_in_ready(i_sr2__io_in_ready), .io_in_valid(sr2__io_in_valid),
    .io_in_bits_data(sr2__io_in_bits_data), .io_in_bits_strb(sr2__io_in_bits_strb),
    .io_in_bits_last(sr2__io_in_bits_last),
    .io_out_ready(sr2__io_out_ready), .io_out_valid(i_sr2__io_out_valid),
    .io_out_bits_data(i_sr2__io_out_bits_data), .io_out_bits_strb(i_sr2__io_out_bits_strb),
    .io_out_bits_last(i_sr2__io_out_bits_last)
  );

  // ======================= SpillRegister_6（AW/AR，5 位 id 带 cache，9 输出） =======================
  logic        sr6__io_in_valid;
  logic [4:0]  sr6__io_in_bits_id;
  logic [48:0] sr6__io_in_bits_addr;
  logic [7:0]  sr6__io_in_bits_len;
  logic [2:0]  sr6__io_in_bits_size;
  logic [1:0]  sr6__io_in_bits_burst;
  logic [3:0]  sr6__io_in_bits_cache;
  logic [3:0]  sr6__io_in_bits_qos;
  logic        sr6__io_out_ready;

  wire        g_sr6__io_in_ready, i_sr6__io_in_ready;
  wire        g_sr6__io_out_valid, i_sr6__io_out_valid;
  wire [4:0]  g_sr6__io_out_bits_id, i_sr6__io_out_bits_id;
  wire [48:0] g_sr6__io_out_bits_addr, i_sr6__io_out_bits_addr;
  wire [7:0]  g_sr6__io_out_bits_len, i_sr6__io_out_bits_len;
  wire [2:0]  g_sr6__io_out_bits_size, i_sr6__io_out_bits_size;
  wire [1:0]  g_sr6__io_out_bits_burst, i_sr6__io_out_bits_burst;
  wire [3:0]  g_sr6__io_out_bits_cache, i_sr6__io_out_bits_cache;
  wire [3:0]  g_sr6__io_out_bits_qos, i_sr6__io_out_bits_qos;

  SpillRegister_6 u_g_sr6 (
    .clock(clock), .reset(reset),
    .io_in_ready(g_sr6__io_in_ready), .io_in_valid(sr6__io_in_valid),
    .io_in_bits_id(sr6__io_in_bits_id), .io_in_bits_addr(sr6__io_in_bits_addr),
    .io_in_bits_len(sr6__io_in_bits_len), .io_in_bits_size(sr6__io_in_bits_size),
    .io_in_bits_burst(sr6__io_in_bits_burst), .io_in_bits_cache(sr6__io_in_bits_cache),
    .io_in_bits_qos(sr6__io_in_bits_qos),
    .io_out_ready(sr6__io_out_ready), .io_out_valid(g_sr6__io_out_valid),
    .io_out_bits_id(g_sr6__io_out_bits_id), .io_out_bits_addr(g_sr6__io_out_bits_addr),
    .io_out_bits_len(g_sr6__io_out_bits_len), .io_out_bits_size(g_sr6__io_out_bits_size),
    .io_out_bits_burst(g_sr6__io_out_bits_burst), .io_out_bits_cache(g_sr6__io_out_bits_cache),
    .io_out_bits_qos(g_sr6__io_out_bits_qos)
  );
  SpillRegister_6_xs u_i_sr6 (
    .clock(clock), .reset(reset),
    .io_in_ready(i_sr6__io_in_ready), .io_in_valid(sr6__io_in_valid),
    .io_in_bits_id(sr6__io_in_bits_id), .io_in_bits_addr(sr6__io_in_bits_addr),
    .io_in_bits_len(sr6__io_in_bits_len), .io_in_bits_size(sr6__io_in_bits_size),
    .io_in_bits_burst(sr6__io_in_bits_burst), .io_in_bits_cache(sr6__io_in_bits_cache),
    .io_in_bits_qos(sr6__io_in_bits_qos),
    .io_out_ready(sr6__io_out_ready), .io_out_valid(i_sr6__io_out_valid),
    .io_out_bits_id(i_sr6__io_out_bits_id), .io_out_bits_addr(i_sr6__io_out_bits_addr),
    .io_out_bits_len(i_sr6__io_out_bits_len), .io_out_bits_size(i_sr6__io_out_bits_size),
    .io_out_bits_burst(i_sr6__io_out_bits_burst), .io_out_bits_cache(i_sr6__io_out_bits_cache),
    .io_out_bits_qos(i_sr6__io_out_bits_qos)
  );

  // ======================= Repeater_1（TLFragmenter，带 io_full，15 输出） =======================
  logic        rp1__io_repeat;
  logic        rp1__io_enq_valid;
  logic [3:0]  rp1__io_enq_bits_opcode;
  logic [1:0]  rp1__io_enq_bits_size;
  logic [14:0] rp1__io_enq_bits_source;
  logic [29:0] rp1__io_enq_bits_address;
  logic        rp1__io_enq_bits_user_amba_prot_bufferable;
  logic        rp1__io_enq_bits_user_amba_prot_modifiable;
  logic        rp1__io_enq_bits_user_amba_prot_readalloc;
  logic        rp1__io_enq_bits_user_amba_prot_writealloc;
  logic        rp1__io_enq_bits_user_amba_prot_privileged;
  logic        rp1__io_enq_bits_user_amba_prot_secure;
  logic        rp1__io_enq_bits_user_amba_prot_fetch;
  logic [3:0]  rp1__io_enq_bits_mask;
  logic        rp1__io_deq_ready;

  wire        g_rp1__io_full, i_rp1__io_full;
  wire        g_rp1__io_enq_ready, i_rp1__io_enq_ready;
  wire        g_rp1__io_deq_valid, i_rp1__io_deq_valid;
  wire [3:0]  g_rp1__io_deq_bits_opcode, i_rp1__io_deq_bits_opcode;
  wire [1:0]  g_rp1__io_deq_bits_size, i_rp1__io_deq_bits_size;
  wire [14:0] g_rp1__io_deq_bits_source, i_rp1__io_deq_bits_source;
  wire [29:0] g_rp1__io_deq_bits_address, i_rp1__io_deq_bits_address;
  wire g_rp1__io_deq_bits_user_amba_prot_bufferable, i_rp1__io_deq_bits_user_amba_prot_bufferable;
  wire g_rp1__io_deq_bits_user_amba_prot_modifiable, i_rp1__io_deq_bits_user_amba_prot_modifiable;
  wire g_rp1__io_deq_bits_user_amba_prot_readalloc, i_rp1__io_deq_bits_user_amba_prot_readalloc;
  wire g_rp1__io_deq_bits_user_amba_prot_writealloc, i_rp1__io_deq_bits_user_amba_prot_writealloc;
  wire g_rp1__io_deq_bits_user_amba_prot_privileged, i_rp1__io_deq_bits_user_amba_prot_privileged;
  wire g_rp1__io_deq_bits_user_amba_prot_secure, i_rp1__io_deq_bits_user_amba_prot_secure;
  wire g_rp1__io_deq_bits_user_amba_prot_fetch, i_rp1__io_deq_bits_user_amba_prot_fetch;
  wire [3:0]  g_rp1__io_deq_bits_mask, i_rp1__io_deq_bits_mask;

  Repeater_1 u_g_rp1 (
    .clock(clock), .reset(reset), .io_repeat(rp1__io_repeat),
    .io_full(g_rp1__io_full),
    .io_enq_ready(g_rp1__io_enq_ready), .io_enq_valid(rp1__io_enq_valid),
    .io_enq_bits_opcode(rp1__io_enq_bits_opcode), .io_enq_bits_size(rp1__io_enq_bits_size),
    .io_enq_bits_source(rp1__io_enq_bits_source), .io_enq_bits_address(rp1__io_enq_bits_address),
    .io_enq_bits_user_amba_prot_bufferable(rp1__io_enq_bits_user_amba_prot_bufferable),
    .io_enq_bits_user_amba_prot_modifiable(rp1__io_enq_bits_user_amba_prot_modifiable),
    .io_enq_bits_user_amba_prot_readalloc(rp1__io_enq_bits_user_amba_prot_readalloc),
    .io_enq_bits_user_amba_prot_writealloc(rp1__io_enq_bits_user_amba_prot_writealloc),
    .io_enq_bits_user_amba_prot_privileged(rp1__io_enq_bits_user_amba_prot_privileged),
    .io_enq_bits_user_amba_prot_secure(rp1__io_enq_bits_user_amba_prot_secure),
    .io_enq_bits_user_amba_prot_fetch(rp1__io_enq_bits_user_amba_prot_fetch),
    .io_enq_bits_mask(rp1__io_enq_bits_mask),
    .io_deq_ready(rp1__io_deq_ready), .io_deq_valid(g_rp1__io_deq_valid),
    .io_deq_bits_opcode(g_rp1__io_deq_bits_opcode), .io_deq_bits_size(g_rp1__io_deq_bits_size),
    .io_deq_bits_source(g_rp1__io_deq_bits_source), .io_deq_bits_address(g_rp1__io_deq_bits_address),
    .io_deq_bits_user_amba_prot_bufferable(g_rp1__io_deq_bits_user_amba_prot_bufferable),
    .io_deq_bits_user_amba_prot_modifiable(g_rp1__io_deq_bits_user_amba_prot_modifiable),
    .io_deq_bits_user_amba_prot_readalloc(g_rp1__io_deq_bits_user_amba_prot_readalloc),
    .io_deq_bits_user_amba_prot_writealloc(g_rp1__io_deq_bits_user_amba_prot_writealloc),
    .io_deq_bits_user_amba_prot_privileged(g_rp1__io_deq_bits_user_amba_prot_privileged),
    .io_deq_bits_user_amba_prot_secure(g_rp1__io_deq_bits_user_amba_prot_secure),
    .io_deq_bits_user_amba_prot_fetch(g_rp1__io_deq_bits_user_amba_prot_fetch),
    .io_deq_bits_mask(g_rp1__io_deq_bits_mask)
  );
  Repeater_1_xs u_i_rp1 (
    .clock(clock), .reset(reset), .io_repeat(rp1__io_repeat),
    .io_full(i_rp1__io_full),
    .io_enq_ready(i_rp1__io_enq_ready), .io_enq_valid(rp1__io_enq_valid),
    .io_enq_bits_opcode(rp1__io_enq_bits_opcode), .io_enq_bits_size(rp1__io_enq_bits_size),
    .io_enq_bits_source(rp1__io_enq_bits_source), .io_enq_bits_address(rp1__io_enq_bits_address),
    .io_enq_bits_user_amba_prot_bufferable(rp1__io_enq_bits_user_amba_prot_bufferable),
    .io_enq_bits_user_amba_prot_modifiable(rp1__io_enq_bits_user_amba_prot_modifiable),
    .io_enq_bits_user_amba_prot_readalloc(rp1__io_enq_bits_user_amba_prot_readalloc),
    .io_enq_bits_user_amba_prot_writealloc(rp1__io_enq_bits_user_amba_prot_writealloc),
    .io_enq_bits_user_amba_prot_privileged(rp1__io_enq_bits_user_amba_prot_privileged),
    .io_enq_bits_user_amba_prot_secure(rp1__io_enq_bits_user_amba_prot_secure),
    .io_enq_bits_user_amba_prot_fetch(rp1__io_enq_bits_user_amba_prot_fetch),
    .io_enq_bits_mask(rp1__io_enq_bits_mask),
    .io_deq_ready(rp1__io_deq_ready), .io_deq_valid(i_rp1__io_deq_valid),
    .io_deq_bits_opcode(i_rp1__io_deq_bits_opcode), .io_deq_bits_size(i_rp1__io_deq_bits_size),
    .io_deq_bits_source(i_rp1__io_deq_bits_source), .io_deq_bits_address(i_rp1__io_deq_bits_address),
    .io_deq_bits_user_amba_prot_bufferable(i_rp1__io_deq_bits_user_amba_prot_bufferable),
    .io_deq_bits_user_amba_prot_modifiable(i_rp1__io_deq_bits_user_amba_prot_modifiable),
    .io_deq_bits_user_amba_prot_readalloc(i_rp1__io_deq_bits_user_amba_prot_readalloc),
    .io_deq_bits_user_amba_prot_writealloc(i_rp1__io_deq_bits_user_amba_prot_writealloc),
    .io_deq_bits_user_amba_prot_privileged(i_rp1__io_deq_bits_user_amba_prot_privileged),
    .io_deq_bits_user_amba_prot_secure(i_rp1__io_deq_bits_user_amba_prot_secure),
    .io_deq_bits_user_amba_prot_fetch(i_rp1__io_deq_bits_user_amba_prot_fetch),
    .io_deq_bits_mask(i_rp1__io_deq_bits_mask)
  );

  // ======================= Repeater_2（TLWidthWidget_1，无 io_full，15 输出） =======================
  logic        rp2__io_repeat;
  logic        rp2__io_enq_valid;
  logic [3:0]  rp2__io_enq_bits_opcode;
  logic [1:0]  rp2__io_enq_bits_size;
  logic [14:0] rp2__io_enq_bits_source;
  logic [29:0] rp2__io_enq_bits_address;
  logic        rp2__io_enq_bits_user_amba_prot_bufferable;
  logic        rp2__io_enq_bits_user_amba_prot_modifiable;
  logic        rp2__io_enq_bits_user_amba_prot_readalloc;
  logic        rp2__io_enq_bits_user_amba_prot_writealloc;
  logic        rp2__io_enq_bits_user_amba_prot_privileged;
  logic        rp2__io_enq_bits_user_amba_prot_secure;
  logic        rp2__io_enq_bits_user_amba_prot_fetch;
  logic [7:0]  rp2__io_enq_bits_mask;
  logic [63:0] rp2__io_enq_bits_data;
  logic        rp2__io_deq_ready;

  wire        g_rp2__io_enq_ready, i_rp2__io_enq_ready;
  wire        g_rp2__io_deq_valid, i_rp2__io_deq_valid;
  wire [3:0]  g_rp2__io_deq_bits_opcode, i_rp2__io_deq_bits_opcode;
  wire [1:0]  g_rp2__io_deq_bits_size, i_rp2__io_deq_bits_size;
  wire [14:0] g_rp2__io_deq_bits_source, i_rp2__io_deq_bits_source;
  wire [29:0] g_rp2__io_deq_bits_address, i_rp2__io_deq_bits_address;
  wire g_rp2__io_deq_bits_user_amba_prot_bufferable, i_rp2__io_deq_bits_user_amba_prot_bufferable;
  wire g_rp2__io_deq_bits_user_amba_prot_modifiable, i_rp2__io_deq_bits_user_amba_prot_modifiable;
  wire g_rp2__io_deq_bits_user_amba_prot_readalloc, i_rp2__io_deq_bits_user_amba_prot_readalloc;
  wire g_rp2__io_deq_bits_user_amba_prot_writealloc, i_rp2__io_deq_bits_user_amba_prot_writealloc;
  wire g_rp2__io_deq_bits_user_amba_prot_privileged, i_rp2__io_deq_bits_user_amba_prot_privileged;
  wire g_rp2__io_deq_bits_user_amba_prot_secure, i_rp2__io_deq_bits_user_amba_prot_secure;
  wire g_rp2__io_deq_bits_user_amba_prot_fetch, i_rp2__io_deq_bits_user_amba_prot_fetch;
  wire [7:0]  g_rp2__io_deq_bits_mask, i_rp2__io_deq_bits_mask;
  wire [63:0] g_rp2__io_deq_bits_data, i_rp2__io_deq_bits_data;

  Repeater_2 u_g_rp2 (
    .clock(clock), .reset(reset), .io_repeat(rp2__io_repeat),
    .io_enq_ready(g_rp2__io_enq_ready), .io_enq_valid(rp2__io_enq_valid),
    .io_enq_bits_opcode(rp2__io_enq_bits_opcode), .io_enq_bits_size(rp2__io_enq_bits_size),
    .io_enq_bits_source(rp2__io_enq_bits_source), .io_enq_bits_address(rp2__io_enq_bits_address),
    .io_enq_bits_user_amba_prot_bufferable(rp2__io_enq_bits_user_amba_prot_bufferable),
    .io_enq_bits_user_amba_prot_modifiable(rp2__io_enq_bits_user_amba_prot_modifiable),
    .io_enq_bits_user_amba_prot_readalloc(rp2__io_enq_bits_user_amba_prot_readalloc),
    .io_enq_bits_user_amba_prot_writealloc(rp2__io_enq_bits_user_amba_prot_writealloc),
    .io_enq_bits_user_amba_prot_privileged(rp2__io_enq_bits_user_amba_prot_privileged),
    .io_enq_bits_user_amba_prot_secure(rp2__io_enq_bits_user_amba_prot_secure),
    .io_enq_bits_user_amba_prot_fetch(rp2__io_enq_bits_user_amba_prot_fetch),
    .io_enq_bits_mask(rp2__io_enq_bits_mask), .io_enq_bits_data(rp2__io_enq_bits_data),
    .io_deq_ready(rp2__io_deq_ready), .io_deq_valid(g_rp2__io_deq_valid),
    .io_deq_bits_opcode(g_rp2__io_deq_bits_opcode), .io_deq_bits_size(g_rp2__io_deq_bits_size),
    .io_deq_bits_source(g_rp2__io_deq_bits_source), .io_deq_bits_address(g_rp2__io_deq_bits_address),
    .io_deq_bits_user_amba_prot_bufferable(g_rp2__io_deq_bits_user_amba_prot_bufferable),
    .io_deq_bits_user_amba_prot_modifiable(g_rp2__io_deq_bits_user_amba_prot_modifiable),
    .io_deq_bits_user_amba_prot_readalloc(g_rp2__io_deq_bits_user_amba_prot_readalloc),
    .io_deq_bits_user_amba_prot_writealloc(g_rp2__io_deq_bits_user_amba_prot_writealloc),
    .io_deq_bits_user_amba_prot_privileged(g_rp2__io_deq_bits_user_amba_prot_privileged),
    .io_deq_bits_user_amba_prot_secure(g_rp2__io_deq_bits_user_amba_prot_secure),
    .io_deq_bits_user_amba_prot_fetch(g_rp2__io_deq_bits_user_amba_prot_fetch),
    .io_deq_bits_mask(g_rp2__io_deq_bits_mask), .io_deq_bits_data(g_rp2__io_deq_bits_data)
  );
  Repeater_2_xs u_i_rp2 (
    .clock(clock), .reset(reset), .io_repeat(rp2__io_repeat),
    .io_enq_ready(i_rp2__io_enq_ready), .io_enq_valid(rp2__io_enq_valid),
    .io_enq_bits_opcode(rp2__io_enq_bits_opcode), .io_enq_bits_size(rp2__io_enq_bits_size),
    .io_enq_bits_source(rp2__io_enq_bits_source), .io_enq_bits_address(rp2__io_enq_bits_address),
    .io_enq_bits_user_amba_prot_bufferable(rp2__io_enq_bits_user_amba_prot_bufferable),
    .io_enq_bits_user_amba_prot_modifiable(rp2__io_enq_bits_user_amba_prot_modifiable),
    .io_enq_bits_user_amba_prot_readalloc(rp2__io_enq_bits_user_amba_prot_readalloc),
    .io_enq_bits_user_amba_prot_writealloc(rp2__io_enq_bits_user_amba_prot_writealloc),
    .io_enq_bits_user_amba_prot_privileged(rp2__io_enq_bits_user_amba_prot_privileged),
    .io_enq_bits_user_amba_prot_secure(rp2__io_enq_bits_user_amba_prot_secure),
    .io_enq_bits_user_amba_prot_fetch(rp2__io_enq_bits_user_amba_prot_fetch),
    .io_enq_bits_mask(rp2__io_enq_bits_mask), .io_enq_bits_data(rp2__io_enq_bits_data),
    .io_deq_ready(rp2__io_deq_ready), .io_deq_valid(i_rp2__io_deq_valid),
    .io_deq_bits_opcode(i_rp2__io_deq_bits_opcode), .io_deq_bits_size(i_rp2__io_deq_bits_size),
    .io_deq_bits_source(i_rp2__io_deq_bits_source), .io_deq_bits_address(i_rp2__io_deq_bits_address),
    .io_deq_bits_user_amba_prot_bufferable(i_rp2__io_deq_bits_user_amba_prot_bufferable),
    .io_deq_bits_user_amba_prot_modifiable(i_rp2__io_deq_bits_user_amba_prot_modifiable),
    .io_deq_bits_user_amba_prot_readalloc(i_rp2__io_deq_bits_user_amba_prot_readalloc),
    .io_deq_bits_user_amba_prot_writealloc(i_rp2__io_deq_bits_user_amba_prot_writealloc),
    .io_deq_bits_user_amba_prot_privileged(i_rp2__io_deq_bits_user_amba_prot_privileged),
    .io_deq_bits_user_amba_prot_secure(i_rp2__io_deq_bits_user_amba_prot_secure),
    .io_deq_bits_user_amba_prot_fetch(i_rp2__io_deq_bits_user_amba_prot_fetch),
    .io_deq_bits_mask(i_rp2__io_deq_bits_mask), .io_deq_bits_data(i_rp2__io_deq_bits_data)
  );

  // ---------------- 激励（每 2000 拍换相，造满/空/同拍入出/背靠背） ----------------
  // ph=1: enq 50% / deq 75%（多空，drain 密集）；ph=0: enq 87.5% / deq 25%（常满，反压密集）。
  task automatic drive_all();
    bit ph;
    ph = ((cyc / 2000) % 2) != 0;

    sr0__io_in_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    sr0__io_in_bits_id = rnd(6);
    sr0__io_in_bits_addr = rnd(49);
    sr0__io_in_bits_len = rnd(8);
    sr0__io_in_bits_size = rnd(3);
    sr0__io_in_bits_burst = rnd(2);
    sr0__io_in_bits_qos = rnd(4);
    sr0__io_out_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);

    sr2__io_in_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    sr2__io_in_bits_data = rnd(256);
    sr2__io_in_bits_strb = rnd(32);
    sr2__io_in_bits_last = $urandom % 2;
    sr2__io_out_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);

    sr6__io_in_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    sr6__io_in_bits_id = rnd(5);
    sr6__io_in_bits_addr = rnd(49);
    sr6__io_in_bits_len = rnd(8);
    sr6__io_in_bits_size = rnd(3);
    sr6__io_in_bits_burst = rnd(2);
    sr6__io_in_bits_cache = rnd(4);
    sr6__io_in_bits_qos = rnd(4);
    sr6__io_out_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);

    rp1__io_repeat = $urandom % 2;
    rp1__io_enq_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    rp1__io_enq_bits_opcode = rnd(4);
    rp1__io_enq_bits_size = rnd(2);
    rp1__io_enq_bits_source = rnd(15);
    rp1__io_enq_bits_address = rnd(30);
    rp1__io_enq_bits_user_amba_prot_bufferable = $urandom % 2;
    rp1__io_enq_bits_user_amba_prot_modifiable = $urandom % 2;
    rp1__io_enq_bits_user_amba_prot_readalloc = $urandom % 2;
    rp1__io_enq_bits_user_amba_prot_writealloc = $urandom % 2;
    rp1__io_enq_bits_user_amba_prot_privileged = $urandom % 2;
    rp1__io_enq_bits_user_amba_prot_secure = $urandom % 2;
    rp1__io_enq_bits_user_amba_prot_fetch = $urandom % 2;
    rp1__io_enq_bits_mask = rnd(4);
    rp1__io_deq_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);

    rp2__io_repeat = $urandom % 2;
    rp2__io_enq_valid = ph ? ($urandom % 2 != 0) : ($urandom % 8 != 0);
    rp2__io_enq_bits_opcode = rnd(4);
    rp2__io_enq_bits_size = rnd(2);
    rp2__io_enq_bits_source = rnd(15);
    rp2__io_enq_bits_address = rnd(30);
    rp2__io_enq_bits_user_amba_prot_bufferable = $urandom % 2;
    rp2__io_enq_bits_user_amba_prot_modifiable = $urandom % 2;
    rp2__io_enq_bits_user_amba_prot_readalloc = $urandom % 2;
    rp2__io_enq_bits_user_amba_prot_writealloc = $urandom % 2;
    rp2__io_enq_bits_user_amba_prot_privileged = $urandom % 2;
    rp2__io_enq_bits_user_amba_prot_secure = $urandom % 2;
    rp2__io_enq_bits_user_amba_prot_fetch = $urandom % 2;
    rp2__io_enq_bits_mask = rnd(8);
    rp2__io_enq_bits_data = rnd(64);
    rp2__io_deq_ready = ph ? (($urandom % 4) != 0) : (($urandom % 4) == 0);
  endtask

  // ---------------- 逐拍比对（全部 52 路输出） ----------------
  task automatic check_all();
    `CMP(sr0__io_in_ready)
    `CMP(sr0__io_out_valid)
    `CMP(sr0__io_out_bits_id)
    `CMP(sr0__io_out_bits_addr)
    `CMP(sr0__io_out_bits_len)
    `CMP(sr0__io_out_bits_size)
    `CMP(sr0__io_out_bits_burst)
    `CMP(sr0__io_out_bits_qos)
    `CMP(sr2__io_in_ready)
    `CMP(sr2__io_out_valid)
    `CMP(sr2__io_out_bits_data)
    `CMP(sr2__io_out_bits_strb)
    `CMP(sr2__io_out_bits_last)
    `CMP(sr6__io_in_ready)
    `CMP(sr6__io_out_valid)
    `CMP(sr6__io_out_bits_id)
    `CMP(sr6__io_out_bits_addr)
    `CMP(sr6__io_out_bits_len)
    `CMP(sr6__io_out_bits_size)
    `CMP(sr6__io_out_bits_burst)
    `CMP(sr6__io_out_bits_cache)
    `CMP(sr6__io_out_bits_qos)
    `CMP(rp1__io_full)
    `CMP(rp1__io_enq_ready)
    `CMP(rp1__io_deq_valid)
    `CMP(rp1__io_deq_bits_opcode)
    `CMP(rp1__io_deq_bits_size)
    `CMP(rp1__io_deq_bits_source)
    `CMP(rp1__io_deq_bits_address)
    `CMP(rp1__io_deq_bits_user_amba_prot_bufferable)
    `CMP(rp1__io_deq_bits_user_amba_prot_modifiable)
    `CMP(rp1__io_deq_bits_user_amba_prot_readalloc)
    `CMP(rp1__io_deq_bits_user_amba_prot_writealloc)
    `CMP(rp1__io_deq_bits_user_amba_prot_privileged)
    `CMP(rp1__io_deq_bits_user_amba_prot_secure)
    `CMP(rp1__io_deq_bits_user_amba_prot_fetch)
    `CMP(rp1__io_deq_bits_mask)
    `CMP(rp2__io_enq_ready)
    `CMP(rp2__io_deq_valid)
    `CMP(rp2__io_deq_bits_opcode)
    `CMP(rp2__io_deq_bits_size)
    `CMP(rp2__io_deq_bits_source)
    `CMP(rp2__io_deq_bits_address)
    `CMP(rp2__io_deq_bits_user_amba_prot_bufferable)
    `CMP(rp2__io_deq_bits_user_amba_prot_modifiable)
    `CMP(rp2__io_deq_bits_user_amba_prot_readalloc)
    `CMP(rp2__io_deq_bits_user_amba_prot_writealloc)
    `CMP(rp2__io_deq_bits_user_amba_prot_privileged)
    `CMP(rp2__io_deq_bits_user_amba_prot_secure)
    `CMP(rp2__io_deq_bits_user_amba_prot_fetch)
    `CMP(rp2__io_deq_bits_mask)
    `CMP(rp2__io_deq_bits_data)
  endtask

  // ---------------- 覆盖：翻转 + 握手分类 + 满/空 + 高位 + repeat 路径 ----------------
  logic        p_sr0__io_in_ready;   bit t_sr0__io_in_ready;
  logic        p_sr0__io_out_valid;   bit t_sr0__io_out_valid;
  logic [5:0]  p_sr0__io_out_bits_id;   bit t_sr0__io_out_bits_id;
  logic [48:0] p_sr0__io_out_bits_addr;   bit t_sr0__io_out_bits_addr;
  logic [7:0]  p_sr0__io_out_bits_len;   bit t_sr0__io_out_bits_len;
  logic [2:0]  p_sr0__io_out_bits_size;   bit t_sr0__io_out_bits_size;
  logic [1:0]  p_sr0__io_out_bits_burst;   bit t_sr0__io_out_bits_burst;
  logic [3:0]  p_sr0__io_out_bits_qos;   bit t_sr0__io_out_bits_qos;
  logic         p_sr2__io_in_ready;   bit t_sr2__io_in_ready;
  logic         p_sr2__io_out_valid;   bit t_sr2__io_out_valid;
  logic [255:0] p_sr2__io_out_bits_data;   bit t_sr2__io_out_bits_data;
  logic [31:0]  p_sr2__io_out_bits_strb;   bit t_sr2__io_out_bits_strb;
  logic         p_sr2__io_out_bits_last;   bit t_sr2__io_out_bits_last;
  logic        p_sr6__io_in_ready;   bit t_sr6__io_in_ready;
  logic        p_sr6__io_out_valid;   bit t_sr6__io_out_valid;
  logic [4:0]  p_sr6__io_out_bits_id;   bit t_sr6__io_out_bits_id;
  logic [48:0] p_sr6__io_out_bits_addr;   bit t_sr6__io_out_bits_addr;
  logic [7:0]  p_sr6__io_out_bits_len;   bit t_sr6__io_out_bits_len;
  logic [2:0]  p_sr6__io_out_bits_size;   bit t_sr6__io_out_bits_size;
  logic [1:0]  p_sr6__io_out_bits_burst;   bit t_sr6__io_out_bits_burst;
  logic [3:0]  p_sr6__io_out_bits_cache;   bit t_sr6__io_out_bits_cache;
  logic [3:0]  p_sr6__io_out_bits_qos;   bit t_sr6__io_out_bits_qos;
  logic        p_rp1__io_full;   bit t_rp1__io_full;
  logic        p_rp1__io_enq_ready;   bit t_rp1__io_enq_ready;
  logic        p_rp1__io_deq_valid;   bit t_rp1__io_deq_valid;
  logic [3:0]  p_rp1__io_deq_bits_opcode;   bit t_rp1__io_deq_bits_opcode;
  logic [1:0]  p_rp1__io_deq_bits_size;   bit t_rp1__io_deq_bits_size;
  logic [14:0] p_rp1__io_deq_bits_source;   bit t_rp1__io_deq_bits_source;
  logic [29:0] p_rp1__io_deq_bits_address;   bit t_rp1__io_deq_bits_address;
  logic p_rp1__io_deq_bits_user_amba_prot_bufferable;   bit t_rp1__io_deq_bits_user_amba_prot_bufferable;
  logic p_rp1__io_deq_bits_user_amba_prot_modifiable;   bit t_rp1__io_deq_bits_user_amba_prot_modifiable;
  logic p_rp1__io_deq_bits_user_amba_prot_readalloc;   bit t_rp1__io_deq_bits_user_amba_prot_readalloc;
  logic p_rp1__io_deq_bits_user_amba_prot_writealloc;   bit t_rp1__io_deq_bits_user_amba_prot_writealloc;
  logic p_rp1__io_deq_bits_user_amba_prot_privileged;   bit t_rp1__io_deq_bits_user_amba_prot_privileged;
  logic p_rp1__io_deq_bits_user_amba_prot_secure;   bit t_rp1__io_deq_bits_user_amba_prot_secure;
  logic p_rp1__io_deq_bits_user_amba_prot_fetch;   bit t_rp1__io_deq_bits_user_amba_prot_fetch;
  logic [3:0]  p_rp1__io_deq_bits_mask;   bit t_rp1__io_deq_bits_mask;
  logic        p_rp2__io_enq_ready;   bit t_rp2__io_enq_ready;
  logic        p_rp2__io_deq_valid;   bit t_rp2__io_deq_valid;
  logic [3:0]  p_rp2__io_deq_bits_opcode;   bit t_rp2__io_deq_bits_opcode;
  logic [1:0]  p_rp2__io_deq_bits_size;   bit t_rp2__io_deq_bits_size;
  logic [14:0] p_rp2__io_deq_bits_source;   bit t_rp2__io_deq_bits_source;
  logic [29:0] p_rp2__io_deq_bits_address;   bit t_rp2__io_deq_bits_address;
  logic p_rp2__io_deq_bits_user_amba_prot_bufferable;   bit t_rp2__io_deq_bits_user_amba_prot_bufferable;
  logic p_rp2__io_deq_bits_user_amba_prot_modifiable;   bit t_rp2__io_deq_bits_user_amba_prot_modifiable;
  logic p_rp2__io_deq_bits_user_amba_prot_readalloc;   bit t_rp2__io_deq_bits_user_amba_prot_readalloc;
  logic p_rp2__io_deq_bits_user_amba_prot_writealloc;   bit t_rp2__io_deq_bits_user_amba_prot_writealloc;
  logic p_rp2__io_deq_bits_user_amba_prot_privileged;   bit t_rp2__io_deq_bits_user_amba_prot_privileged;
  logic p_rp2__io_deq_bits_user_amba_prot_secure;   bit t_rp2__io_deq_bits_user_amba_prot_secure;
  logic p_rp2__io_deq_bits_user_amba_prot_fetch;   bit t_rp2__io_deq_bits_user_amba_prot_fetch;
  logic [7:0]  p_rp2__io_deq_bits_mask;   bit t_rp2__io_deq_bits_mask;
  logic [63:0] p_rp2__io_deq_bits_data;   bit t_rp2__io_deq_bits_data;

  // 每变体：n10 只进不出 / n01 只出不进 / n11 同拍入出 / b2b 背靠背 /
  //         full/empty 拍数 / hibit 最宽字段最高位入队次数 / 上一拍 enq fire
  longint n10_sr0 = 0, n01_sr0 = 0, n11_sr0 = 0, b2b_sr0 = 0, full_sr0 = 0, empty_sr0 = 0, hibit_sr0 = 0;
  longint n10_sr2 = 0, n01_sr2 = 0, n11_sr2 = 0, b2b_sr2 = 0, full_sr2 = 0, empty_sr2 = 0, hibit_sr2 = 0;
  longint n10_sr6 = 0, n01_sr6 = 0, n11_sr6 = 0, b2b_sr6 = 0, full_sr6 = 0, empty_sr6 = 0, hibit_sr6 = 0;
  longint n10_rp1 = 0, n01_rp1 = 0, n11_rp1 = 0, b2b_rp1 = 0, full_rp1 = 0, empty_rp1 = 0, hibit_rp1 = 0;
  longint n10_rp2 = 0, n01_rp2 = 0, n11_rp2 = 0, b2b_rp2 = 0, full_rp2 = 0, empty_rp2 = 0, hibit_rp2 = 0;
  // 仅 Repeater：saves = enq fire 且 repeat；repdeq = 满时 deq fire（重复拍被接走）
  longint saves_rp1 = 0, repdeq_rp1 = 0, saves_rp2 = 0, repdeq_rp2 = 0;
  bit prev_enq_sr0 = 0, prev_enq_sr2 = 0, prev_enq_sr6 = 0, prev_enq_rp1 = 0, prev_enq_rp2 = 0;

  // 一路变体的覆盖采样：enq/deq fire 分类、背靠背、最高位；满/空拍数在 cover_all 里直接计。
  task automatic cover_one(input bit enq_fire, input bit deq_fire, input bit hibit,
                           inout longint n10, n01, n11, b2b, nhibit,
                           inout bit prev_enq);
    if (enq_fire && !deq_fire) n10++;
    if (!enq_fire && deq_fire) n01++;
    if (enq_fire && deq_fire)  n11++;
    if (prev_enq && enq_fire) b2b++;
    if (enq_fire && hibit) nhibit++;
    prev_enq = enq_fire;
    fires += (enq_fire ? 1 : 0) + (deq_fire ? 1 : 0);
  endtask

  task automatic cover_all();
    `TOG(sr0__io_in_ready)
    `TOG(sr0__io_out_valid)
    `TOG(sr0__io_out_bits_id)
    `TOG(sr0__io_out_bits_addr)
    `TOG(sr0__io_out_bits_len)
    `TOG(sr0__io_out_bits_size)
    `TOG(sr0__io_out_bits_burst)
    `TOG(sr0__io_out_bits_qos)
    `TOG(sr2__io_in_ready)
    `TOG(sr2__io_out_valid)
    `TOG(sr2__io_out_bits_data)
    `TOG(sr2__io_out_bits_strb)
    `TOG(sr2__io_out_bits_last)
    `TOG(sr6__io_in_ready)
    `TOG(sr6__io_out_valid)
    `TOG(sr6__io_out_bits_id)
    `TOG(sr6__io_out_bits_addr)
    `TOG(sr6__io_out_bits_len)
    `TOG(sr6__io_out_bits_size)
    `TOG(sr6__io_out_bits_burst)
    `TOG(sr6__io_out_bits_cache)
    `TOG(sr6__io_out_bits_qos)
    `TOG(rp1__io_full)
    `TOG(rp1__io_enq_ready)
    `TOG(rp1__io_deq_valid)
    `TOG(rp1__io_deq_bits_opcode)
    `TOG(rp1__io_deq_bits_size)
    `TOG(rp1__io_deq_bits_source)
    `TOG(rp1__io_deq_bits_address)
    `TOG(rp1__io_deq_bits_user_amba_prot_bufferable)
    `TOG(rp1__io_deq_bits_user_amba_prot_modifiable)
    `TOG(rp1__io_deq_bits_user_amba_prot_readalloc)
    `TOG(rp1__io_deq_bits_user_amba_prot_writealloc)
    `TOG(rp1__io_deq_bits_user_amba_prot_privileged)
    `TOG(rp1__io_deq_bits_user_amba_prot_secure)
    `TOG(rp1__io_deq_bits_user_amba_prot_fetch)
    `TOG(rp1__io_deq_bits_mask)
    `TOG(rp2__io_enq_ready)
    `TOG(rp2__io_deq_valid)
    `TOG(rp2__io_deq_bits_opcode)
    `TOG(rp2__io_deq_bits_size)
    `TOG(rp2__io_deq_bits_source)
    `TOG(rp2__io_deq_bits_address)
    `TOG(rp2__io_deq_bits_user_amba_prot_bufferable)
    `TOG(rp2__io_deq_bits_user_amba_prot_modifiable)
    `TOG(rp2__io_deq_bits_user_amba_prot_readalloc)
    `TOG(rp2__io_deq_bits_user_amba_prot_writealloc)
    `TOG(rp2__io_deq_bits_user_amba_prot_privileged)
    `TOG(rp2__io_deq_bits_user_amba_prot_secure)
    `TOG(rp2__io_deq_bits_user_amba_prot_fetch)
    `TOG(rp2__io_deq_bits_mask)
    `TOG(rp2__io_deq_bits_data)

    // SpillRegister 系列：满 = spill 槽被占（in_ready 拉 0），空 = 出侧无有效拍
    // （两者不互补：主槽占用而 spill 空时两者都不是，故分开计）
    if (!g_sr0__io_in_ready) full_sr0++;
    if (!g_sr0__io_out_valid) empty_sr0++;
    cover_one(sr0__io_in_valid && g_sr0__io_in_ready, g_sr0__io_out_valid && sr0__io_out_ready,
              sr0__io_in_bits_addr[48],
              n10_sr0, n01_sr0, n11_sr0, b2b_sr0, hibit_sr0, prev_enq_sr0);
    if (!g_sr2__io_in_ready) full_sr2++;
    if (!g_sr2__io_out_valid) empty_sr2++;
    cover_one(sr2__io_in_valid && g_sr2__io_in_ready, g_sr2__io_out_valid && sr2__io_out_ready,
              sr2__io_in_bits_data[255],
              n10_sr2, n01_sr2, n11_sr2, b2b_sr2, hibit_sr2, prev_enq_sr2);
    if (!g_sr6__io_in_ready) full_sr6++;
    if (!g_sr6__io_out_valid) empty_sr6++;
    cover_one(sr6__io_in_valid && g_sr6__io_in_ready, g_sr6__io_out_valid && sr6__io_out_ready,
              sr6__io_in_bits_addr[48],
              n10_sr6, n01_sr6, n11_sr6, b2b_sr6, hibit_sr6, prev_enq_sr6);
    // Repeater_1：满有 io_full 直读；空 = deq_valid 拉 0（不互补，分开计）
    if (g_rp1__io_full) full_rp1++;
    if (!g_rp1__io_deq_valid) empty_rp1++;
    cover_one(rp1__io_enq_valid && g_rp1__io_enq_ready, g_rp1__io_deq_valid && rp1__io_deq_ready,
              rp1__io_enq_bits_address[29],
              n10_rp1, n01_rp1, n11_rp1, b2b_rp1, hibit_rp1, prev_enq_rp1);
    if (rp1__io_enq_valid && g_rp1__io_enq_ready && rp1__io_repeat) saves_rp1++;
    if (g_rp1__io_full && g_rp1__io_deq_valid && rp1__io_deq_ready) repdeq_rp1++;
    // Repeater_2 无 io_full 端口：满用 deq_ready & ~enq_ready 推断（enq_ready = deq_ready & ~full）
    if (rp2__io_deq_ready && !g_rp2__io_enq_ready) full_rp2++;
    if (!g_rp2__io_deq_valid) empty_rp2++;
    cover_one(rp2__io_enq_valid && g_rp2__io_enq_ready, g_rp2__io_deq_valid && rp2__io_deq_ready,
              rp2__io_enq_bits_data[63],
              n10_rp2, n01_rp2, n11_rp2, b2b_rp2, hibit_rp2, prev_enq_rp2);
    if (rp2__io_enq_valid && g_rp2__io_enq_ready && rp2__io_repeat) saves_rp2++;
    if (rp2__io_deq_ready && !g_rp2__io_enq_ready && g_rp2__io_deq_valid) repdeq_rp2++;
  endtask

  // ---------------- 收尾闸 ----------------
  // rep=1（Repeater）：enq_ready = deq_ready & ~full 且 deq_valid = enq_valid | full，
  // 所以 enq fire 必然同拍 deq fire —— n10(enq-only) 结构性为 0，反向闸：必须恒 0。
  task automatic gate_variant(input string nm, input int n_out,
                              input int toggled,
                              input longint n10, n01, n11, b2b, nfull, nempty, nhibit,
                              input bit rep);
    bit bad;
    bad = 0;
    if (toggled != n_out) begin
      bad = 1; $display("COV FAIL %s: toggled=%0d/%0d", nm, toggled, n_out);
    end
    if (rep) begin
      if (n10 != 0) begin bad = 1; $display("COV FAIL %s: n10=%0d, Repeater 结构性不可能只进不出", nm, n10); end
    end else if (n10 < NCYCLES/20) begin
      bad = 1; $display("COV FAIL %s: n10(enq-only)=%0d < %0d", nm, n10, NCYCLES/20);
    end
    if (n01 < NCYCLES/20)  begin bad = 1; $display("COV FAIL %s: n01(deq-only)=%0d < %0d", nm, n01, NCYCLES/20); end
    if (n11 < NCYCLES/40)  begin bad = 1; $display("COV FAIL %s: n11(same-cycle)=%0d < %0d", nm, n11, NCYCLES/40); end
    if (b2b < NCYCLES/40)    begin bad = 1; $display("COV FAIL %s: b2b=%0d < %0d", nm, b2b, NCYCLES/40); end
    if (nfull < NCYCLES/20)  begin bad = 1; $display("COV FAIL %s: full cycles=%0d < %0d", nm, nfull, NCYCLES/20); end
    if (nempty < NCYCLES/20) begin bad = 1; $display("COV FAIL %s: empty cycles=%0d < %0d", nm, nempty, NCYCLES/20); end
    if (nhibit < NCYCLES/200) begin bad = 1; $display("COV FAIL %s: hibit enq=%0d < %0d", nm, nhibit, NCYCLES/200); end
    $display("COV %s: n10=%0d n01=%0d n11=%0d b2b=%0d full=%0d empty=%0d hibit=%0d toggled=%0d/%0d",
             nm, n10, n01, n11, b2b, nfull, nempty, nhibit, toggled, n_out);
    if (bad) begin $display("TEST FAILED (coverage: %s)", nm); $fatal(1); end
  endtask

  task automatic gate_repeater(input string nm, input longint saves, repdeq);
    bit bad;
    bad = 0;
    if (saves < NCYCLES/40)  begin bad = 1; $display("COV FAIL %s: saves(repeat enq)=%0d < %0d", nm, saves, NCYCLES/40); end
    if (repdeq < NCYCLES/40) begin bad = 1; $display("COV FAIL %s: repdeq(repeated deq)=%0d < %0d", nm, repdeq, NCYCLES/40); end
    $display("COV %s: saves=%0d repdeq=%0d", nm, saves, repdeq);
    if (bad) begin $display("TEST FAILED (coverage: %s repeat path)", nm); $fatal(1); end
  endtask

  function automatic int sum_tog_sr0();
    return t_sr0__io_in_ready + t_sr0__io_out_valid + t_sr0__io_out_bits_id +
           t_sr0__io_out_bits_addr + t_sr0__io_out_bits_len + t_sr0__io_out_bits_size +
           t_sr0__io_out_bits_burst + t_sr0__io_out_bits_qos;
  endfunction
  function automatic int sum_tog_sr2();
    return t_sr2__io_in_ready + t_sr2__io_out_valid + t_sr2__io_out_bits_data +
           t_sr2__io_out_bits_strb + t_sr2__io_out_bits_last;
  endfunction
  function automatic int sum_tog_sr6();
    return t_sr6__io_in_ready + t_sr6__io_out_valid + t_sr6__io_out_bits_id +
           t_sr6__io_out_bits_addr + t_sr6__io_out_bits_len + t_sr6__io_out_bits_size +
           t_sr6__io_out_bits_burst + t_sr6__io_out_bits_cache + t_sr6__io_out_bits_qos;
  endfunction
  function automatic int sum_tog_rp1();
    return t_rp1__io_full + t_rp1__io_enq_ready + t_rp1__io_deq_valid +
           t_rp1__io_deq_bits_opcode + t_rp1__io_deq_bits_size +
           t_rp1__io_deq_bits_source + t_rp1__io_deq_bits_address +
           t_rp1__io_deq_bits_user_amba_prot_bufferable +
           t_rp1__io_deq_bits_user_amba_prot_modifiable +
           t_rp1__io_deq_bits_user_amba_prot_readalloc +
           t_rp1__io_deq_bits_user_amba_prot_writealloc +
           t_rp1__io_deq_bits_user_amba_prot_privileged +
           t_rp1__io_deq_bits_user_amba_prot_secure +
           t_rp1__io_deq_bits_user_amba_prot_fetch + t_rp1__io_deq_bits_mask;
  endfunction
  function automatic int sum_tog_rp2();
    return t_rp2__io_enq_ready + t_rp2__io_deq_valid +
           t_rp2__io_deq_bits_opcode + t_rp2__io_deq_bits_size +
           t_rp2__io_deq_bits_source + t_rp2__io_deq_bits_address +
           t_rp2__io_deq_bits_user_amba_prot_bufferable +
           t_rp2__io_deq_bits_user_amba_prot_modifiable +
           t_rp2__io_deq_bits_user_amba_prot_readalloc +
           t_rp2__io_deq_bits_user_amba_prot_writealloc +
           t_rp2__io_deq_bits_user_amba_prot_privileged +
           t_rp2__io_deq_bits_user_amba_prot_secure +
           t_rp2__io_deq_bits_user_amba_prot_fetch + t_rp2__io_deq_bits_mask +
           t_rp2__io_deq_bits_data;
  endfunction

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    // 输入与 toggle 采样初值
    sr0__io_in_valid = '0; sr0__io_in_bits_id = '0; sr0__io_in_bits_addr = '0;
    sr0__io_in_bits_len = '0; sr0__io_in_bits_size = '0; sr0__io_in_bits_burst = '0;
    sr0__io_in_bits_qos = '0; sr0__io_out_ready = '0;
    sr2__io_in_valid = '0; sr2__io_in_bits_data = '0; sr2__io_in_bits_strb = '0;
    sr2__io_in_bits_last = '0; sr2__io_out_ready = '0;
    sr6__io_in_valid = '0; sr6__io_in_bits_id = '0; sr6__io_in_bits_addr = '0;
    sr6__io_in_bits_len = '0; sr6__io_in_bits_size = '0; sr6__io_in_bits_burst = '0;
    sr6__io_in_bits_cache = '0; sr6__io_in_bits_qos = '0; sr6__io_out_ready = '0;
    rp1__io_repeat = '0; rp1__io_enq_valid = '0; rp1__io_enq_bits_opcode = '0;
    rp1__io_enq_bits_size = '0; rp1__io_enq_bits_source = '0; rp1__io_enq_bits_address = '0;
    rp1__io_enq_bits_user_amba_prot_bufferable = '0; rp1__io_enq_bits_user_amba_prot_modifiable = '0;
    rp1__io_enq_bits_user_amba_prot_readalloc = '0; rp1__io_enq_bits_user_amba_prot_writealloc = '0;
    rp1__io_enq_bits_user_amba_prot_privileged = '0; rp1__io_enq_bits_user_amba_prot_secure = '0;
    rp1__io_enq_bits_user_amba_prot_fetch = '0; rp1__io_enq_bits_mask = '0; rp1__io_deq_ready = '0;
    rp2__io_repeat = '0; rp2__io_enq_valid = '0; rp2__io_enq_bits_opcode = '0;
    rp2__io_enq_bits_size = '0; rp2__io_enq_bits_source = '0; rp2__io_enq_bits_address = '0;
    rp2__io_enq_bits_user_amba_prot_bufferable = '0; rp2__io_enq_bits_user_amba_prot_modifiable = '0;
    rp2__io_enq_bits_user_amba_prot_readalloc = '0; rp2__io_enq_bits_user_amba_prot_writealloc = '0;
    rp2__io_enq_bits_user_amba_prot_privileged = '0; rp2__io_enq_bits_user_amba_prot_secure = '0;
    rp2__io_enq_bits_user_amba_prot_fetch = '0; rp2__io_enq_bits_mask = '0;
    rp2__io_enq_bits_data = '0; rp2__io_deq_ready = '0;
    p_sr0__io_in_ready = '0; p_sr0__io_out_valid = '0; p_sr0__io_out_bits_id = '0;
    p_sr0__io_out_bits_addr = '0; p_sr0__io_out_bits_len = '0; p_sr0__io_out_bits_size = '0;
    p_sr0__io_out_bits_burst = '0; p_sr0__io_out_bits_qos = '0;
    p_sr2__io_in_ready = '0; p_sr2__io_out_valid = '0; p_sr2__io_out_bits_data = '0;
    p_sr2__io_out_bits_strb = '0; p_sr2__io_out_bits_last = '0;
    p_sr6__io_in_ready = '0; p_sr6__io_out_valid = '0; p_sr6__io_out_bits_id = '0;
    p_sr6__io_out_bits_addr = '0; p_sr6__io_out_bits_len = '0; p_sr6__io_out_bits_size = '0;
    p_sr6__io_out_bits_burst = '0; p_sr6__io_out_bits_cache = '0; p_sr6__io_out_bits_qos = '0;
    p_rp1__io_full = '0; p_rp1__io_enq_ready = '0; p_rp1__io_deq_valid = '0;
    p_rp1__io_deq_bits_opcode = '0; p_rp1__io_deq_bits_size = '0;
    p_rp1__io_deq_bits_source = '0; p_rp1__io_deq_bits_address = '0;
    p_rp1__io_deq_bits_user_amba_prot_bufferable = '0; p_rp1__io_deq_bits_user_amba_prot_modifiable = '0;
    p_rp1__io_deq_bits_user_amba_prot_readalloc = '0; p_rp1__io_deq_bits_user_amba_prot_writealloc = '0;
    p_rp1__io_deq_bits_user_amba_prot_privileged = '0; p_rp1__io_deq_bits_user_amba_prot_secure = '0;
    p_rp1__io_deq_bits_user_amba_prot_fetch = '0; p_rp1__io_deq_bits_mask = '0;
    p_rp2__io_enq_ready = '0; p_rp2__io_deq_valid = '0;
    p_rp2__io_deq_bits_opcode = '0; p_rp2__io_deq_bits_size = '0;
    p_rp2__io_deq_bits_source = '0; p_rp2__io_deq_bits_address = '0;
    p_rp2__io_deq_bits_user_amba_prot_bufferable = '0; p_rp2__io_deq_bits_user_amba_prot_modifiable = '0;
    p_rp2__io_deq_bits_user_amba_prot_readalloc = '0; p_rp2__io_deq_bits_user_amba_prot_writealloc = '0;
    p_rp2__io_deq_bits_user_amba_prot_privileged = '0; p_rp2__io_deq_bits_user_amba_prot_secure = '0;
    p_rp2__io_deq_bits_user_amba_prot_fetch = '0; p_rp2__io_deq_bits_mask = '0;
    p_rp2__io_deq_bits_data = '0;

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

    $display("BusBufferLeaves5 checks=%0d errors=%0d xskip=%0d fires=%0d",
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
    gate_variant("SpillRegister", 8, sum_tog_sr0(),
                 n10_sr0, n01_sr0, n11_sr0, b2b_sr0, full_sr0, empty_sr0, hibit_sr0, 1'b0);
    gate_variant("SpillRegister_2", 5, sum_tog_sr2(),
                 n10_sr2, n01_sr2, n11_sr2, b2b_sr2, full_sr2, empty_sr2, hibit_sr2, 1'b0);
    gate_variant("SpillRegister_6", 9, sum_tog_sr6(),
                 n10_sr6, n01_sr6, n11_sr6, b2b_sr6, full_sr6, empty_sr6, hibit_sr6, 1'b0);
    gate_variant("Repeater_1", 15, sum_tog_rp1(),
                 n10_rp1, n01_rp1, n11_rp1, b2b_rp1, full_rp1, empty_rp1, hibit_rp1, 1'b1);
    gate_variant("Repeater_2", 15, sum_tog_rp2(),
                 n10_rp2, n01_rp2, n11_rp2, b2b_rp2, full_rp2, empty_rp2, hibit_rp2, 1'b1);
    gate_repeater("Repeater_1", saves_rp1, repdeq_rp1);
    gate_repeater("Repeater_2", saves_rp2, repdeq_rp2);
    $display("TEST PASSED");
    $finish;
  end
endmodule
