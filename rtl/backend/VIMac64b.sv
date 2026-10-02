// =============================================================================
// VIMac64b.sv —— 64 位向量整数乘加单元（VIMacU 里每 64 位数据一个，三拍出结果）
//
// 位置：向量乘法功能单元 VIMacU 把 128 位向量切成两半，各交给一个 VIMac64b。
//   Scala：yunsuan/src/main/scala/yunsuan/vector/vectorIMAC/VIMac64b.scala。
// 支持：vmul / vmulh[u|su] / vwmul[u|su] / vmacc / vnmsac / vmadd / vnmsub / vwmacc[u|su|us] / vsmul。
//   一个 64 位数据块里按元素宽度 sew 并排放 8/4/2/1 个元素，**同一棵** 128 位宽的压缩树
//   同时算出所有元素的 2*sew 位乘积 —— 做法是在元素边界处把进位掐断。
//
// 输入约定（由 VIMacU 准备好）：
//   srcType_0 = vs2 类型 {x, signed, sew[1:0]}；srcType_1 = vs1 类型（只用 signed 位）。
//   isMacc    乘积要加上（isSub 时是"被减去"）oldVd；vmadd/vnmsub 由父模块预先交换 vs2 与 oldVd。
//   widen     加宽运算：结果 2*sew 位；本块算出的 128 位里，按 uopIdx[0] 取低/高 64 位。
//   highHalf  取每个元素乘积的高 sew 位（vmulh*）。
//   isFixP    vsmul：乘积右移 sew-1 位、按 vxrm 舍入、饱和。
//
// 三级流水（fire 是第 0 拍的有效；第 1 拍的有效 fire_s1 是 fire 打一拍）：
//   §S0  Booth-4 编码 vs1 -> 32 个部分积 + 1 个"补 1 / 无符号修正"加数 + 1 个 oldVd 加数 = 34 个
//        128 位加数；Wallace 3:2 压缩 5 层（34 -> 23 -> 16 -> 11 -> 8 -> 6），6 个中间结果打拍。
//   §S1  再压 3 层（6 -> 4 -> 3 -> 2），然后 8 段 16 位加法器串成 128 位加法（段间进位在元素
//        边界处掐断），和打拍。
//   §S2  按 sew / highHalf / widen 从 128 位和里挑出 64 位结果；vsmul 的舍入与饱和；
//        vnmsac/vnmsub 的取负（见怪癖 3）。
//
// 怪癖（照 golden，不"修"）：
//   1. 负的 Booth 项用"取反"表示，欠的 +1 统一塞进第 33 个加数的偶数位（每个 Booth 位一个）；
//      同一个加数的高半还兼做"vs1 无符号且最高位为 1"时的修正（加上 vs2 << sew）。
//   2. 压缩树的进位掩码 0x7fff... 把每个 2*sew 位乘积块的最高位进位丢掉，使各元素互不串扰。
//   3. isSub（vnmsac/vnmsub）：树里算的是 vs1*vs2 + ~oldVd + 1 = vs1*vs2 - oldVd，
//      最后一级再整体取负（~x + 1，借用舍入加法链）得到 oldVd - vs1*vs2。
//   4. widen 时 oldVd 加数是 {oldVd, oldVd}（父模块按 uopIdx 只取其中一半，另一半是无用值）。
//   5. uopIdx 6 位全部跟着流水打两拍，但只有 bit0 被用到（[5:1] 是 golden 同样存在的死位）。
//   6. 只有 fire_s1 带异步复位；所有数据/控制寄存器不复位，由 fire / fire_s1 使能。
// =============================================================================

module xs_VIMac64b_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        fire,
  input  logic [5:0]  uop_idx,
  input  logic [1:0]  vxrm,
  input  logic [1:0]  vsew,        // 元素宽度编码：0/1/2/3 = 8/16/32/64 位
  input  logic        vs2_signed,
  input  logic        vs1_signed,
  input  logic [63:0] vs1,
  input  logic [63:0] vs2,
  input  logic [63:0] old_vd,
  input  logic        high_half,
  input  logic        is_macc,
  input  logic        is_sub,
  input  logic        widen,
  input  logic        is_fixp,
  output logic [63:0] vd,
  output logic [7:0]  vxsat
);

  localparam int unsigned XLEN       = 64;
  localparam int unsigned PROD_W     = 128;  // 压缩树宽度 = 2 * XLEN
  localparam int unsigned NUM_BOOTH  = 32;   // Booth-4：每 2 位 vs1 一个部分积
  localparam int unsigned NUM_ADDEND = 34;   // 32 部分积 + 补 1 加数 + oldVd 加数
  localparam int unsigned NUM_STAGE  = 8;    // 3:2 压缩总层数：34 -> ... -> 2
  localparam int unsigned STAGES_S0  = 5;    // 其中前 5 层在 S0，后 3 层在 S1
  localparam int unsigned NUM_MID    = 6;    // S0/S1 之间打拍的加数个数

  // 压了 stages 层之后还剩几个加数：每 3 个变 2 个，余下的原样传下去
  function automatic int unsigned addends_after(input int unsigned stages);
    int unsigned n;
    n = NUM_ADDEND;
    for (int unsigned s = 0; s < stages; s++) n = (n / 3) * 2 + n % 3;
    return n;
  endfunction

  // 进位掩码：每个 2*sew 位乘积块的最高位进位不许传到相邻块（怪癖 2）
  function automatic logic [PROD_W-1:0] carry_mask(input logic [3:0] sew_oh);
    return ({PROD_W{sew_oh[0]}} & 128'h7fff_7fff_7fff_7fff_7fff_7fff_7fff_7fff)
         | ({PROD_W{sew_oh[1]}} & 128'h7fff_ffff_7fff_ffff_7fff_ffff_7fff_ffff)
         | ({PROD_W{sew_oh[2]}} & 128'h7fff_ffff_ffff_ffff_7fff_ffff_ffff_ffff)
         |  {PROD_W{sew_oh[3]}};
  endfunction

  // ===========================================================================
  // §S0-a  Booth-4 编码
  // ===========================================================================
  logic [3:0] sew_oh;                       // [0]=8 [1]=16 [2]=32 [3]=64
  assign sew_oh = 4'b0001 << vsew;

  // 第 i 组看 vs1[2i+1 : 2i-1]；若第 2i 位正好是一个元素的最低位，则 2i-1 那一位属于
  // 前一个元素，要换成 0。
  logic [NUM_BOOTH-1:0] booth_pos, booth_neg, booth_one, booth_double;

  always_comb begin
    for (int i = 0; i < NUM_BOOTH; i++) begin
      logic       elem_start;
      logic [2:0] d;
      elem_start = (sew_oh[0] && (2 * i) % 8  == 0) || (sew_oh[1] && (2 * i) % 16 == 0)
                || (sew_oh[2] && (2 * i) % 32 == 0) || (sew_oh[3] && (2 * i) % 64 == 0);
      d[2:1] = vs1[2*i +: 2];
      d[0]   = (i == 0 || elem_start) ? 1'b0 : vs1[(i == 0) ? 0 : 2*i - 1];
      booth_pos[i]    = !d[2] && d[1:0] != 2'b00;      // +1 或 +2 倍
      booth_neg[i]    =  d[2] && d[1:0] != 2'b11;      // -1 或 -2 倍
      booth_one[i]    = d[1] != d[0];                  // 1 倍
      booth_double[i] = d[2] != d[1] && d[1] == d[0];  // 2 倍
    end
  end

  // ===========================================================================
  // §S0-b  34 个加数。每种 sew 各生成一份，最后按 sew_oh 选（golden 同样是 Mux1H）
  // ===========================================================================
  logic [PROD_W-1:0] pp_by_sew       [4][NUM_BOOTH];  // Booth 部分积
  logic [PROD_W-1:0] plus1_by_sew    [4];             // 补 1 / 无符号修正加数
  logic [PROD_W-1:0] old_vd_by_sew   [4];             // oldVd 的每个元素零扩展到 2*sew
  logic [PROD_W-1:0] addend          [NUM_ADDEND];

  for (genvar k = 0; k < 4; k++) begin : g_sew
    localparam int unsigned SEW   = 8 << k;
    localparam int unsigned N_BLK = XLEN / SEW;       // 一个 64 位块里的元素个数

    // 第 i 个部分积属于第 BLK 个元素，在该元素的 2*SEW 位乘积块内左移 SH 位
    for (genvar i = 0; i < NUM_BOOTH; i++) begin : g_pp
      localparam int unsigned BLK = (2 * i) / SEW;
      localparam int unsigned SH  = 2 * i - SEW * BLK;
      logic [SEW-1:0]   elem;
      logic [2*SEW-1:0] elem_ext, multiple, booth_term, shifted;
      assign elem       = vs2[BLK*SEW +: SEW];
      assign elem_ext   = {{SEW{vs2_signed && elem[SEW-1]}}, elem};
      assign multiple   = ({2*SEW{booth_one[i]}}    & elem_ext)
                        | ({2*SEW{booth_double[i]}} & (elem_ext << 1));
      assign booth_term = ({2*SEW{booth_pos[i]}} &  multiple)
                        | ({2*SEW{booth_neg[i]}} & ~multiple);   // 负项取反，+1 在补 1 加数里
      assign shifted    = booth_term << SH;
      assign pp_by_sew[k][i] = PROD_W'(shifted) << (BLK * 2 * SEW);
    end

    // 补 1 加数：每个元素一块 {hi, lo}
    //   lo（SEW 位）：偶数位 2j 放该元素第 j 个 Booth 项的 negative；最低两位再加 is_sub（怪癖 3 的 +1）
    //   hi（SEW 位）：vs1 无符号且最高位为 1 时放 vs2 元素（Booth 把 vs1 当有符号数，少算了 vs2 << SEW）
    for (genvar b = 0; b < N_BLK; b++) begin : g_blk
      logic [SEW-1:0] hi, lo;
      logic [1:0]     lo_low;
      assign hi = (vs1[b*SEW + SEW-1] && !vs1_signed) ? vs2[b*SEW +: SEW] : '0;
      for (genvar j = 0; j < SEW / 2; j++) begin : g_neg
        assign lo[2*j]   = booth_neg[b*SEW/2 + j];
        assign lo[2*j+1] = 1'b0;
      end
      assign lo_low = lo[1:0] + 2'(is_sub);
      assign plus1_by_sew[k][b*2*SEW +: 2*SEW]  = {hi, lo[SEW-1:2], lo_low};
      assign old_vd_by_sew[k][b*2*SEW +: 2*SEW] = {{SEW{1'b0}}, old_vd[b*SEW +: SEW]};
    end
  end

  logic [PROD_W-1:0] old_vd_reorg;

  always_comb begin
    for (int i = 0; i < NUM_BOOTH; i++) begin
      addend[i] = '0;
      for (int k = 0; k < 4; k++) addend[i] |= {PROD_W{sew_oh[k]}} & pp_by_sew[k][i];
    end
    addend[NUM_BOOTH] = '0;
    old_vd_reorg      = '0;
    for (int k = 0; k < 4; k++) begin
      addend[NUM_BOOTH] |= {PROD_W{sew_oh[k]}} & plus1_by_sew[k];
      old_vd_reorg      |= {PROD_W{sew_oh[k]}} & old_vd_by_sew[k];
    end
    // oldVd 加数：非乘加为 0；加宽乘加直接用 {oldVd, oldVd}（怪癖 4）；isSub 时取反
    if (!is_macc)    addend[NUM_BOOTH+1] = '0;
    else if (widen)  addend[NUM_BOOTH+1] = {old_vd, old_vd};
    else if (is_sub) addend[NUM_BOOTH+1] = ~old_vd_reorg;
    else             addend[NUM_BOOTH+1] = old_vd_reorg;
  end

  // ===========================================================================
  // Wallace 3:2 压缩树（8 层；第 5 层之后插一级寄存器，前 5 层属 S0、后 3 层属 S1）
  //   每层：第 g 组三个加数 (3g, 3g+1, 3g+2) -> 和放到第 g 位、进位（左移 1）放到第 N_GRP+g 位，
  //   凑不满 3 个的加数原样排在最后。次序与 Scala 的 `sum ++ cin ++ data.drop(...)` 一致。
  // ===========================================================================
  logic              fire_s1;
  logic [3:0]        sew_oh_s1;
  logic [PROD_W-1:0] wal_in  [NUM_STAGE][NUM_ADDEND];
  logic [PROD_W-1:0] wal_out [NUM_STAGE][NUM_ADDEND];
  logic [PROD_W-1:0] wallace_mid_q [NUM_MID];        // S0 -> S1 寄存器

  for (genvar j = 0; j < NUM_ADDEND; j++) begin : g_wal_first
    assign wal_in[0][j] = addend[j];
  end

  for (genvar s = 0; s < NUM_STAGE; s++) begin : g_wal
    localparam int unsigned N_IN  = addends_after(s);
    localparam int unsigned N_GRP = N_IN / 3;
    localparam int unsigned N_OUT = N_GRP * 2 + N_IN % 3;
    logic [PROD_W-1:0] mask;
    assign mask = carry_mask((s < STAGES_S0) ? sew_oh : sew_oh_s1);

    for (genvar g = 0; g < N_GRP; g++) begin : g_csa
      logic [PROD_W-1:0] a, b, c, carry;
      assign a     = wal_in[s][3*g];
      assign b     = wal_in[s][3*g+1];
      assign c     = wal_in[s][3*g+2];
      assign carry = ((a & b) | (b & c) | (a & c)) & mask;
      assign wal_out[s][g]         = a ^ b ^ c;
      assign wal_out[s][N_GRP + g] = {carry[PROD_W-2:0], 1'b0};
    end
    for (genvar r = 0; r < N_IN % 3; r++) begin : g_pass
      assign wal_out[s][2*N_GRP + r] = wal_in[s][3*N_GRP + r];
    end
    for (genvar u = N_OUT; u < NUM_ADDEND; u++) begin : g_unused
      assign wal_out[s][u] = '0;
    end

    // 接到下一层：S0 的最后一层输出经寄存器，其余直连
    if (s + 1 < NUM_STAGE) begin : g_next
      for (genvar j = 0; j < NUM_ADDEND; j++) begin : g_conn
        if (s + 1 == STAGES_S0 && j < NUM_MID) begin : g_reg
          assign wal_in[s+1][j] = wallace_mid_q[j];
        end else if (s + 1 == STAGES_S0) begin : g_zero
          assign wal_in[s+1][j] = '0;
        end else begin : g_wire
          assign wal_in[s+1][j] = wal_out[s][j];
        end
      end
    end
  end

  // ===========================================================================
  // S0 -> S1 寄存器（fire 使能，不复位）；fire_s1 = fire 打一拍（异步复位）
  // ===========================================================================
  logic       high_half_s1, widen_s1;
  logic [5:0] uop_idx_s1;
  logic [1:0] vxrm_s1;
  logic       is_sub_s1, is_fixp_s1;

  // 门控写法照 golden（GatedValidRegNext）：只有 fire 或自己为 1 时才翻转
  always_ff @(posedge clock or posedge reset) begin
    if (reset)                 fire_s1 <= 1'b0;
    else if (fire || fire_s1)  fire_s1 <= fire;
  end

  always_ff @(posedge clock) begin
    if (fire) begin
      for (int j = 0; j < NUM_MID; j++) wallace_mid_q[j] <= wal_out[STAGES_S0-1][j];
      sew_oh_s1    <= sew_oh;
      high_half_s1 <= high_half;
      widen_s1     <= widen;
      uop_idx_s1   <= uop_idx;
      vxrm_s1      <= vxrm;
      is_sub_s1    <= is_sub;
      is_fixp_s1   <= is_fixp;
    end
  end

  // ===========================================================================
  // §S1  最后两个加数相加：8 段 16 位加法器，段间进位在乘积块（2*sew 位）边界处掐断
  // ===========================================================================
  logic [PROD_W-1:0] final_a, final_b, product_sum;

  assign final_a = wal_out[NUM_STAGE-1][0];
  assign final_b = wal_out[NUM_STAGE-1][1];

  always_comb begin
    logic carry;
    carry = 1'b0;
    for (int i = 0; i < 8; i++) begin
      logic        crosses;   // 第 i 段的最低位不是乘积块的起点 -> 接上一段的进位
      logic [16:0] seg;
      crosses = (i == 0)     ? 1'b0
              : (i == 4)     ? sew_oh_s1[3]
              : (i % 2 == 0) ? (sew_oh_s1[3] || sew_oh_s1[2])
              :                !sew_oh_s1[0];
      seg = {1'b0, final_a[16*i +: 16]} + {1'b0, final_b[16*i +: 16]} + 17'(crosses && carry);
      product_sum[16*i +: 16] = seg[15:0];
      carry                   = seg[16];
    end
  end

  // ===========================================================================
  // S1 -> S2 寄存器（fire_s1 使能，不复位）
  // ===========================================================================
  logic [PROD_W-1:0] product_q;
  logic [3:0]        sew_oh_s2;
  logic              high_half_s2, widen_s2;
  logic [5:0]        uop_idx_s2;
  logic [1:0]        vxrm_s2;
  logic              is_sub_s2, is_fixp_s2;

  always_ff @(posedge clock) begin
    if (fire_s1) begin
      product_q    <= product_sum;
      sew_oh_s2    <= sew_oh_s1;
      high_half_s2 <= high_half_s1;
      widen_s2     <= widen_s1;
      uop_idx_s2   <= uop_idx_s1;
      vxrm_s2      <= vxrm_s1;
      is_sub_s2    <= is_sub_s1;
      is_fixp_s2   <= is_fixp_s1;
    end
  end

  // ===========================================================================
  // §S2-a  从 128 位乘积里挑 64 位结果
  //   sew=64 或加宽：整半边（sew=64 按 highHalf、加宽按 uopIdx[0] 选高/低 64 位）；
  //   其余：每个元素从自己的 2*sew 位乘积块里取低半或高半。
  // ===========================================================================
  logic [XLEN-1:0] vd_plain;

  always_comb begin
    vd_plain = '0;
    if (sew_oh_s2[3] || widen_s2) begin
      vd_plain = ((sew_oh_s2[3] && high_half_s2) || (widen_s2 && uop_idx_s2[0]))
               ? product_q[127:64] : product_q[63:0];
    end else if (sew_oh_s2[2]) begin
      for (int e = 0; e < 2; e++)
        vd_plain[32*e +: 32] = high_half_s2 ? product_q[64*e + 32 +: 32] : product_q[64*e +: 32];
    end else if (sew_oh_s2[1]) begin
      for (int e = 0; e < 4; e++)
        vd_plain[16*e +: 16] = high_half_s2 ? product_q[32*e + 16 +: 16] : product_q[32*e +: 16];
    end else begin
      for (int e = 0; e < 8; e++)
        vd_plain[8*e +: 8] = high_half_s2 ? product_q[16*e + 8 +: 8] : product_q[16*e +: 8];
    end
  end

  // ===========================================================================
  // §S2-b  vsmul：结果 = (乘积 >> (sew-1)) 舍入；唯一会溢出的是 (-2^(sew-1))^2，
  //        此时乘积块最高两位为 01，饱和成最大正数。
  //   下面一律以"字节"为单位（8 个）：vxsat / 舍入进位 都是每字节一位，
  //   宽元素的标志复制到它占的每个字节（饱和）或只放在最低字节（舍入进位）。
  // ===========================================================================
  // 每个 16 位段的最高两位是否为 01：sew 位元素的饱和看它那个乘积块的最高 16 位段
  logic [7:0] seg_top_is_01;
  logic [7:0] sat_byte;

  always_comb begin
    for (int i = 0; i < 8; i++) seg_top_is_01[i] = product_q[16*i + 14 +: 2] == 2'b01;
    for (int i = 0; i < 8; i++) begin
      sat_byte[i] = (sew_oh_s2[0] && seg_top_is_01[i])
                 || (sew_oh_s2[1] && seg_top_is_01[(i / 2) * 2 + 1])
                 || (sew_oh_s2[2] && seg_top_is_01[(i / 4) * 4 + 3])
                 || (sew_oh_s2[3] && seg_top_is_01[7]);
    end
  end

  // 舍入增量（RVV vxrm）：v_d 是保留的最低位，v_d1 是丢掉的最高位，tail_nz 是其余丢掉位非零
  function automatic logic round_inc(input logic [1:0] rm, input logic v_d, input logic v_d1,
                                     input logic tail_nz);
    case (rm)
      2'd0:    return v_d1;                         // rnu：四舍五入
      2'd1:    return v_d1 && (tail_nz || v_d);     // rne：向偶数舍入
      2'd2:    return 1'b0;                         // rdn：截断
      default: return !v_d && (v_d1 || tail_nz);    // rod：舍入到奇数
    endcase
  endfunction

  logic [XLEN-1:0] product_shifted;   // 每个元素：乘积块 >> (sew-1) 的低 sew 位
  logic [7:0]      rnd_inc_byte;      // 舍入进位，放在每个元素的最低字节

  always_comb begin
    product_shifted = '0;
    rnd_inc_byte    = '0;
    if (sew_oh_s2[0]) begin
      for (int e = 0; e < 8; e++) begin
        product_shifted[8*e +: 8] = product_q[16*e + 7 +: 8];
        rnd_inc_byte[e] = round_inc(vxrm_s2, product_q[16*e + 7], product_q[16*e + 6],
                                    product_q[16*e +: 6] != '0);
      end
    end
    if (sew_oh_s2[1]) begin
      for (int e = 0; e < 4; e++) begin
        product_shifted[16*e +: 16] = product_q[32*e + 15 +: 16];
        rnd_inc_byte[2*e] = round_inc(vxrm_s2, product_q[32*e + 15], product_q[32*e + 14],
                                      product_q[32*e +: 14] != '0);
      end
    end
    if (sew_oh_s2[2]) begin
      for (int e = 0; e < 2; e++) begin
        product_shifted[32*e +: 32] = product_q[64*e + 31 +: 32];
        rnd_inc_byte[4*e] = round_inc(vxrm_s2, product_q[64*e + 31], product_q[64*e + 30],
                                      product_q[64*e +: 30] != '0);
      end
    end
    if (sew_oh_s2[3]) begin
      product_shifted = product_q[126:63];
      rnd_inc_byte[0] = round_inc(vxrm_s2, product_q[63], product_q[62], product_q[61:0] != '0);
    end
  end

  // ===========================================================================
  // §S2-c  8 个 8 位"加进位"加法器串成的链，一物两用：
  //          vsmul：        product_shifted + 舍入进位
  //          vnmsac/vnmsub：~vd_plain + 1（每个元素最低字节进 1，怪癖 3）
  //        链在元素边界处断开：边界字节的进位输入取自 chain_cin，其余取上一字节的进位。
  // ===========================================================================
  logic [XLEN-1:0] chain_data, chain_out;
  logic [7:0]      chain_cin;

  assign chain_data = is_sub_s2 ? ~vd_plain : product_shifted;
  assign chain_cin  = is_sub_s2 ? 8'hff : rnd_inc_byte;

  always_comb begin
    logic carry;
    carry = 1'b0;
    for (int i = 0; i < 8; i++) begin
      logic       crosses;   // 第 i 字节不是元素的最低字节 -> 接上一字节的进位
      logic       cin;
      logic [7:0] in_byte;
      crosses = (i == 0)     ? 1'b0
              : (i == 4)     ? sew_oh_s2[3]
              : (i % 2 == 0) ? (sew_oh_s2[3] || sew_oh_s2[2])
              :                !sew_oh_s2[0];
      cin     = crosses ? carry : chain_cin[i];
      in_byte = chain_data[8*i +: 8];
      chain_out[8*i +: 8] = in_byte + 8'(cin);
      carry               = (in_byte == 8'hff) && cin;
    end
  end

  // vsmul 饱和：该元素的每个字节填 0xff，最高字节填 0x7f
  logic [XLEN-1:0] vd_fixp;

  always_comb begin
    for (int i = 0; i < 8; i++) begin
      logic top_byte;   // 第 i 字节是所在元素的最高字节
      top_byte = sew_oh_s2[0]
              || (sew_oh_s2[1] && i % 2 == 1)
              || (sew_oh_s2[2] && i % 4 == 3)
              || (sew_oh_s2[3] && i == 7);
      vd_fixp[8*i +: 8] = sat_byte[i] ? {!top_byte, 7'h7f} : chain_out[8*i +: 8];
    end
  end

  assign vd    = is_fixp_s2 ? vd_fixp : (is_sub_s2 ? chain_out : vd_plain);
  assign vxsat = is_fixp_s2 ? sat_byte : 8'h00;

endmodule

// -----------------------------------------------------------------------------
// golden 同名 wrapper：端口逐位同 golden。srcType 只用到 {vs2 的 signed、sew} 与 vs1 的 signed。
// -----------------------------------------------------------------------------
module VIMac64b(
  input         clock,
  input         reset,
  input         io_fire,
  input  [5:0]  io_info_uopIdx,
  input  [1:0]  io_info_vxrm,
  input  [3:0]  io_srcType_0,
  input  [3:0]  io_srcType_1,
  input  [63:0] io_vs1,
  input  [63:0] io_vs2,
  input  [63:0] io_oldVd,
  input         io_highHalf,
  input         io_isMacc,
  input         io_isSub,
  input         io_widen,
  input         io_isFixP,
  output [63:0] io_vd,
  output [7:0]  io_vxsat
);

  xs_VIMac64b_core u_core (
    .clock      (clock),
    .reset      (reset),
    .fire       (io_fire),
    .uop_idx    (io_info_uopIdx),
    .vxrm       (io_info_vxrm),
    .vsew       (io_srcType_0[1:0]),
    .vs2_signed (io_srcType_0[2]),
    .vs1_signed (io_srcType_1[2]),
    .vs1        (io_vs1),
    .vs2        (io_vs2),
    .old_vd     (io_oldVd),
    .high_half  (io_highHalf),
    .is_macc    (io_isMacc),
    .is_sub     (io_isSub),
    .widen      (io_widen),
    .is_fixp    (io_isFixP),
    .vd         (io_vd),
    .vxsat      (io_vxsat)
  );

endmodule
