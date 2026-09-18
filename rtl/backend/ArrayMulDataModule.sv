// =============================================================================
// ArrayMulDataModule.sv —— 整数乘法阵列（Radix-4 Booth 编码 + Wallace 压缩树）
//
// 在哪一层：后端整数执行单元 MulUnit 的数据通路（rtl/backend/MulUnit.sv 例化本
//   模块）。MulUnit 负责把两个 64 位源按 mul/mulh/mulhsu/mulhu 的语义扩成 65 位、
//   把 {isW,isHi} 随延迟打两拍、末级选高/低半字；**乘法本身全在这里**。
//
// 它算什么：io_result = io_a * io_b，两个操作数当作 **65 位带符号数**，积 130 位。
//   两级流水：io_regEnables_0 打第 1 拍（Booth 部分积），io_regEnables_1 打第 2 拍
//   （压缩到第 5 层之后的结果）。所以 s0 给 a/b，s2 拿 io_result。
//
// 核心机制（三段）：
//   1) Radix-4 Booth：把 65 位乘数 a 按 3 位重叠窗口切成 33 行，每行从
//      {0, ±b, ±2b} 里选一个"部分积"，行权重 2^(2k)。33 行而不是 65 行，
//      压缩树因此矮一半。负倍数用 ~b 表示，欠的那个 +1 作为 2 位修正量 t
//      挂在**下一行**部分积的最低两位上（见 §2）。
//   2) Wallace 压缩：把 33 行部分积按权重堆成 130 个"列"，列高最高 33。
//      每一层把每列按 4 个一组切块，满 4 的块用 C53（5:3，第 5 个输入取低一列
//      的进位），尾块按剩 1/2/3 分别直通 / C22 / C32。5 层之后每列最多剩 2 位。
//      本仓实测算子用量：C22×293 / C32×84 / C53×989（与 golden 逐个对上）。
//   3) 收尾：最后一层每列至多 2 位，低位拼成 sum、高位拼成 carry，
//      一次 130 位进位传播加法得到乘积。
//
// ★复位域：本模块 2562 个寄存器**一个都不复位**★。golden ArrayMulDataModule.sv
//   里只有 **1 个** always 块，且是 `always @(posedge clock)`（没有 reset 敏感项），
//   模块端口表里也**没有 reset 端口**（只有 clock / io_a / io_b / io_regEnables_0
//   / io_regEnables_1 / io_result 六个）。Chisel 侧对应 `RegEnable(x, en)`——
//   无初值。照抄成带复位就是真 bug，elaborate 和 lint 都不会报。
//   寄存器构成：2307 个（层 0 部分积，enable=io_regEnables_0）
//             + 255 个（第 5 层压缩结果，enable=io_regEnables_1）= 2562。
//
// ★更新优先级★：本模块没有"多源写同一状态"的情形——每个寄存器只有一个数据源，
//   只有使能与否（enable 低时保持）。所以没有优先级可言，这一点与 golden 一致：
//   golden 的 always 块是 `if (io_regEnables_0) begin ... end if (io_regEnables_1)
//   begin ... end` 两个互不重叠的寄存器集合。
//
// ★与 Chisel 字面的两处出入，一律以 golden 为准★
//   (1) 部分积里的常数 1（`Cat(1.U(1.W), ~s, pp_temp, t)` 的最高位）也是一个
//       RegEnable，firtool 把它折成 `r <= io_regEnables_0 | r`（使能时置 1、否则
//       保持）。本文件写成"常数 1 进 pp_comb，整条 pp_reg 统一使能"，行为完全相同
//       （使能时写 1、否则保持），寄存器个数也相同。
//   (2) 最后一行（k=32）的 Booth 修正量没有"下一行"可挂，于是被丢掉。对
//       MulUnit 实际会给的操作数（a[64] 要么等于 a[63]，要么是 0——见 MulUnit 的
//       符号扩展）这个修正量恒为 0，所以不影响结果；但若强行喂 a[64]=1 且
//       a[63]=0 的"非法"操作数，本阵列的输出会比真值少 2^64。这是 golden 的行为，
//       本仓照搬。（用 Python 逐位模型实测 5000 组随机 65 位输入：按 (a[64],a[63])
//       分四类，(0,0)/(0,1)/(1,1) 三类与真值 130 位逐位相等，只有 (1,0) 那一类
//       偏差**恒为** -2^64；MulUnit 的三种合法操作数形态各 3000 组，低 128 位零失配。）
//
// 子实例：C22 / C32 / C53 —— 本仓已全部重写（rtl/backend/{C22,C32,C53,CSA3_2}.sv），
//   不做黑盒。可读核直接例化它们的参数化核 xs_CSA2_2_core / xs_CSA3_2_core /
//   xs_CSA5_3_core（C53 的核里再例化两份 3:2，与 golden 的两个 CSA3_2 实例一一对应）。
//
// 设计源：src/main/scala/xiangshan/backend/fu/Multiplier.scala (class ArrayMulDataModule)
// golden 对照：G1-canonical/golden-rtl/ArrayMulDataModule.sv（24372 行）
// =============================================================================

// -----------------------------------------------------------------------------
// §1 arraymul_pkg —— 规模常量与"压缩树形状"的纯 elaboration 期计算
//
// 压缩树的形状（每层每列有多少位、哪一位接到哪个压缩器）在 Chisel 里是由
// 一段**递归的 Scala 程序**在展开期算出来的，不是规则阵列。本包把那段程序
// 翻译成纯常量函数：所有函数只吃入参、不读任何模块信号，结果全部在
// elaborate 期折成常量表，generate 里用到的下标因此都是编译期常数。
// -----------------------------------------------------------------------------
package arraymul_pkg;

  // 乘法阵列位宽。MulUnit 用 XLEN+1=65 位做"统一带符号"乘法。
  localparam int LEN    = 65;
  localparam int NCOL   = 2 * LEN;        // 130 列（= 积的位数）
  localparam int NROW   = (LEN + 1) / 2;  // 33 行 Booth 部分积
  localparam int NLAYER = 5;              // 压缩层数（第 5 层后每列 ≤ 2 位）
  localparam int MAXH   = 33;             // 单列最大高度（层 0 的中间列）
  localparam int MAXC   = (MAXH + 3) / 4; // 单列最多 8 个满 4 的 C53 块
  localparam int PPW    = 70;             // 单行部分积最大位宽

  // 高度 ≤ 33 用 6 位存；层内偏移 ≤ 2307 用 12 位存。用 packed 数组是为了
  // 能写成 localparam 常量表（unpacked 的 localparam 数组在各工具里支持不一）。
  typedef logic [NLAYER:0][NCOL-1:0][5:0]  height_tbl_t;
  typedef logic [NLAYER:0][NCOL:0][11:0]   offset_tbl_t;   // 末项 [NCOL] = 该层总位数

  // ---- 压缩一列时的分块规则（addOneColumn 的闭式形式）----
  // 一列 h 位，从低到高每 4 个一块：满 4 的块用 C53，最后剩 r=h%4 位是尾块。
  // 每个 C53 块额外吃一位来自**低一列**的 cout1（不够就接常数 0）。
  function automatic int n_c53(input int h);   return h / 4;                       endfunction
  function automatic int tail_n(input int h);  return h % 4;                       endfunction
  // 尾块剩 2 位用 C22、剩 3 位用 C32，都产出 1 个和位 + 1 个进位；剩 1 位直通。
  function automatic int tail_has_comp(input int h);
    return ((h % 4) == 2 || (h % 4) == 3) ? 1 : 0;
  endfunction
  function automatic int tail_has_pass(input int h);
    return ((h % 4) == 1) ? 1 : 0;
  endfunction
  // 本列产出的 cout2 条数（每个 C53 一条 + 尾块压缩器一条）。cout2 挂到**下一层**
  // 高一列的列尾；cout1 只有 C53 才有，作为**同层**下一列各 C53 的第 5 个输入。
  function automatic int n_cout2(input int h); return h / 4 + tail_has_comp(h);    endfunction

  // ---- 层 0：某一列被多少行部分积覆盖 ----
  // 行 k 的部分积占 [pp_lo(k), pp_lo(k)+pp_width(k)) 这一段列，超出 130 列的丢弃。
  function automatic int pp_lo(input int k);
    return (k == 0) ? 0 : (2 * k - 2);
  endfunction
  function automatic int pp_width(input int k);
    // k=0    : {~s, s, s, pp}   —— 三位符号扩展，没有前一行的修正量
    // 2k=LEN-1: {~s, pp, t}     —— 最后一行，符号扩展只用一位
    // 其余    : {1, ~s, pp, t}
    if (k == 0)                                   return 3 + (LEN + 1);
    else if (2 * k == LEN - 1 || 2 * k == LEN - 2) return 1 + (LEN + 1) + 2;
    else                                          return 2 + (LEN + 1) + 2;
  endfunction
  function automatic bit pp_covers(input int k, input int col);
    return (col >= pp_lo(k)) && (col < pp_lo(k) + pp_width(k));
  endfunction
  function automatic int height0(input int col);
    int c = 0;
    for (int k = 0; k < NROW; k++) if (pp_covers(k, col)) c++;
    return c;
  endfunction
  // 第 col 列自下而上第 idx 位来自哪一行（行号随列内位置单调递增）。
  function automatic int row_at(input int col, input int idx);
    int c = 0;
    for (int k = 0; k < NROW; k++) begin
      if (pp_covers(k, col)) begin
        if (c == idx) return k;
        c++;
      end
    end
    return 0;   // 不可达：调用点保证 idx < height0(col)
  endfunction

  // ---- 各层各列的高度 ----
  // 下一层第 i 列 = 本列的和位们 ++ 低一列多出来的 cin ++ 低一列的 cout2 们。
  function automatic height_tbl_t calc_heights();
    height_tbl_t t;
    for (int i = 0; i < NCOL; i++) t[0][i] = 6'(height0(i));
    for (int L = 1; L <= NLAYER; L++) begin
      for (int i = 0; i < NCOL; i++) begin
        int h  = int'(t[L-1][i]);
        int hp = (i == 0) ? 0 : int'(t[L-1][i-1]);   // 低一列
        // n_c53(h) 个 C53 和位 + 尾块的 1 位（若有）
        // + 低一列送来但本列 C53 用不完的 cin（每个 C53 只吃一条）
        // + 低一列的 cout2
        t[L][i] = 6'(n_c53(h) + tail_has_comp(h) + tail_has_pass(h)
                     + ((n_c53(hp) > n_c53(h)) ? (n_c53(hp) - n_c53(h)) : 0)
                     + n_cout2(hp));
      end
    end
    return t;
  endfunction

  // ---- 把每层的列首尾相接打平成一根向量，记下每列的起始位 ----
  function automatic offset_tbl_t calc_offsets();
    height_tbl_t t = calc_heights();
    offset_tbl_t o;
    int acc;
    for (int L = 0; L <= NLAYER; L++) begin
      acc = 0;
      for (int i = 0; i < NCOL; i++) begin
        o[L][i] = 12'(acc);
        acc += int'(t[L][i]);
      end
      o[L][NCOL] = 12'(acc);   // 该层总位数
    end
    return o;
  endfunction

  localparam height_tbl_t HEIGHT = calc_heights();
  localparam offset_tbl_t OFFSET = calc_offsets();

  // 取"低一列"的高度。第 0 列没有低一列，按高度 0 处理。
  // ★下标必须先夹住再取★：写成 `(col==0) ? 0 : HEIGHT[L][col-1]` 时，即使条件恒假，
  // HEIGHT[L][-1] 这个下标仍会被 elaborate，VCS 报 Warning-[SIOB]（实测 4 条）。
  function automatic int prev_height(input int L, input int col);
    int idx = (col > 0) ? (col - 1) : 0;
    return (col > 0) ? int'(HEIGHT[L][idx]) : 0;
  endfunction

  // 层 L 打平后的总位数。层 0 = 2307（部分积寄存器数），层 5 = 255。
  function automatic int layer_bits(input int L); return int'(OFFSET[L][NCOL]); endfunction

  // 最后一层前几列只有 1 位（没有 carry），carry 向量从第一根 2 位的列开始。
  function automatic int carry_start();
    for (int i = 0; i < NCOL; i++) if (int'(HEIGHT[NLAYER][i]) >= 2) return i;
    return NCOL;
  endfunction

endpackage : arraymul_pkg

// =============================================================================
// §2 xs_ArrayMulDataModule_core —— 可读核
// =============================================================================
module xs_ArrayMulDataModule_core
  import arraymul_pkg::*;
(
  input  logic             clock,
  input  logic [LEN-1:0]   a,
  input  logic [LEN-1:0]   b,
  input  logic             reg_en_pp,    // 第 1 级流水使能（锁存 Booth 部分积）
  input  logic             reg_en_mid,   // 第 2 级流水使能（锁存第 5 层压缩结果）
  output logic [NCOL-1:0]  result
);

  localparam int TOT_PP  = layer_bits(0);        // 2307
  localparam int TOT_MID = layer_bits(NLAYER);   // 255
  localparam int MAXTOT  = TOT_PP;               // 层 0 最宽，各层共用这个宽度

  // ---------------------------------------------------------------------------
  // §2.1 Booth 编码：从乘数 b 预先算好四个可能的倍数
  // 只需要 0 / ±b / ±2b。负倍数先用按位取反表示，欠的 +1 由下一行的修正量 t 补。
  // ---------------------------------------------------------------------------
  logic [LEN:0] b_pos1, b_pos2, b_neg1, b_neg2;   // 66 位，多出的一位放符号
  assign b_pos1 = {b[LEN-1], b};                  // +b，符号扩展到 66 位
  assign b_pos2 = {b, 1'b0};                      // +2b（= b_pos1<<1 截到 66 位）
  assign b_neg1 = ~b_pos1;                        // ≈ -b（差一个 +1，见 t）
  assign b_neg2 = {b_neg1[LEN-1:0], 1'b0};        // ≈ -2b

  // ---------------------------------------------------------------------------
  // §2.2 33 行部分积
  //   window[k] : 第 k 行的 3 位重叠窗口（取自乘数 a）
  //   mult[k]   : 该窗口选中的倍数
  //   sign[k]   : 该倍数的符号位（用于行内的符号扩展）
  //   corr[k]   : **上一行**负倍数欠的 +1，2 位，挂在本行部分积的最低两位
  //   pp_row[k] : 完整的一行部分积（含符号扩展前缀与 corr）
  // ---------------------------------------------------------------------------
  logic [2:0]     window [0:NROW-1];
  logic [LEN:0]   mult   [0:NROW-1];
  logic           sign   [0:NROW-1];
  logic [1:0]     corr   [0:NROW-1];
  logic [PPW-1:0] pp_row [0:NROW-1];

  for (genvar k = 0; k < NROW; k++) begin : g_booth_row
    localparam int I = 2 * k;   // 本行的权重指数（部分积乘 2^I）

    // 窗口 = a[I+1:I-1]。第 0 行下面没有 a[-1]，补 0；最后一行上面没有 a[65]，
    // 用符号位顶上（这正是"65 位带符号"的 Booth 收尾）。
    if (k == 0) begin : g_win_first
      assign window[k] = {a[1:0], 1'b0};
    end else if (I == LEN - 1) begin : g_win_last
      assign window[k] = {a[LEN-1], a[LEN-1:LEN-2]};
    end else begin : g_win_mid
      assign window[k] = a[I+1 -: 3];
    end

    // Radix-4 Booth 选择表：000/111→0，001/010→+b，011→+2b，100→-2b，101/110→-b
    always_comb begin
      case (window[k])
        3'd1, 3'd2: mult[k] = b_pos1;
        3'd3:       mult[k] = b_pos2;
        3'd4:       mult[k] = b_neg2;
        3'd5, 3'd6: mult[k] = b_neg1;
        default:    mult[k] = '0;
      endcase
    end
    assign sign[k] = mult[k][LEN];

    // 上一行取了负倍数就欠一个 +1：-b 欠在权重 2^(I-2)（corr 的第 0 位），
    // -2b 欠在权重 2^(I-1)（corr 的第 1 位）。第 0 行没有"上一行"，恒 0。
    if (k == 0) begin : g_corr_first
      assign corr[k] = 2'b00;
    end else begin : g_corr_rest
      always_comb begin
        case (window[k-1])
          3'd4:       corr[k] = 2'b10;   // 上一行是 -2b
          3'd5, 3'd6: corr[k] = 2'b01;   // 上一行是 -b
          default:    corr[k] = 2'b00;
        endcase
      end
    end

    // 符号扩展前缀。把每行都扩到积的全宽太浪费，Booth 阵列的标准做法是
    // 只在行首放 {1, ~s}（其余高位恒 1 的部分已提前折成常数），第 0 行例外
    // 地放 {~s, s, s}，最后一行没有更高的行压着所以只放 {~s}。
    if (k == 0) begin : g_pp_first
      assign pp_row[k] = {1'b0, ~sign[k], sign[k], sign[k], mult[k]};
    end else if (I == LEN - 1) begin : g_pp_last
      assign pp_row[k] = {1'b0, ~sign[k], mult[k], corr[k]};
    end else begin : g_pp_mid
      assign pp_row[k] = {1'b1, ~sign[k], mult[k], corr[k]};
    end
  end

  // ---------------------------------------------------------------------------
  // §2.3 按权重堆列 + 第 1 级流水寄存器
  // 列 i 的第 p 位来自第 row_at(i,p) 行。整层打平成一根 TOT_PP 位的向量，
  // 第 i 列占 OFFSET[0][i] 起的 HEIGHT[0][i] 位。
  // ---------------------------------------------------------------------------
  logic [TOT_PP-1:0] pp_flat;
  logic [TOT_PP-1:0] pp_reg;

  for (genvar i = 0; i < NCOL; i++) begin : g_pp_col
    for (genvar p = 0; p < int'(HEIGHT[0][i]); p++) begin : g_pp_bit
      localparam int K   = row_at(i, p);
      localparam int POS = int'(OFFSET[0][i]) + p;
      assign pp_flat[POS] = pp_row[K][i - pp_lo(K)];
    end
  end

  // ★不复位★：golden 只有 `always @(posedge clock)`，无 reset 端口。
  always_ff @(posedge clock) begin
    if (reg_en_pp) pp_reg <= pp_flat;
  end

  // ---------------------------------------------------------------------------
  // §2.4 Wallace 压缩层
  //
  // layer_in[L]  = 进入第 L 层压缩的位向量（L=0 取 pp_reg，L=NLAYER 取 mid_reg）
  // layer_out[L] = 第 L 层压缩的组合结果
  //
  // 每列 i 的处理（h = 本列高度，hp = 低一列高度）：
  //   · 满 4 的块 j：C53(本列 4 位, cin=低一列的 cout1[j])
  //                 → 和位 c53_sum[j]、cout1[j]（给**同层下一列**）、cout2[j]
  //   · 尾块 r=h%4：r=1 直通、r=2 用 C22、r=3 用 C32
  //   · 下一层本列 = [各 C53 和位] ++ [尾块结果] ++ [低一列没被吃掉的 cin]
  //                  ++ [低一列的 cout2 们]
  //   位的先后次序必须与 golden 一致（同一组位换个顺序进压缩器，结果一样但
  //   结构不一样 —— FM 会当场失配）。
  // ---------------------------------------------------------------------------
  wire [MAXTOT-1:0] layer_in  [0:NLAYER];
  wire [MAXTOT-1:0] layer_out [0:NLAYER-1];
  wire [MAXC-1:0]   c53_sum   [0:NLAYER-1][0:NCOL-1];
  wire [MAXC-1:0]   c53_cout1 [0:NLAYER-1][0:NCOL-1];
  wire [MAXC-1:0]   c53_cout2 [0:NLAYER-1][0:NCOL-1];
  wire              tail_sum  [0:NLAYER-1][0:NCOL-1];
  wire              tail_cout [0:NLAYER-1][0:NCOL-1];

  logic [TOT_MID-1:0] mid_reg;

  assign layer_in[0]      = MAXTOT'(pp_reg);
  assign layer_in[NLAYER] = MAXTOT'(mid_reg);

  for (genvar L = 0; L < NLAYER; L++) begin : g_layer
    localparam int TOT_NEXT = layer_bits(L + 1);

    // 中间层直接串下去；最后一层的结果进第 2 级流水寄存器。
    if (L + 1 < NLAYER) begin : g_comb_link
      assign layer_in[L+1] = layer_out[L];
    end
    // 本层用不到的高位钉 0（各层位数不同，共用 MAXTOT 宽的向量）。
    if (TOT_NEXT < MAXTOT) begin : g_pad
      assign layer_out[L][MAXTOT-1:TOT_NEXT] = '0;
    end

    for (genvar i = 0; i < NCOL; i++) begin : g_col
      localparam int H     = int'(HEIGHT[L][i]);
      localparam int HP    = prev_height(L, i);
      localparam int NC    = n_c53(H);              // 本列 C53 个数
      localparam int R     = tail_n(H);             // 尾块位数（0 表示没尾块）
      localparam int CINL  = n_c53(HP);             // 低一列送来的 cin 条数
      localparam int LEFT  = (CINL > NC) ? (CINL - NC) : 0;   // 本列吃不下的 cin
      localparam int NCO2  = n_cout2(HP);           // 低一列的 cout2 条数
      localparam int BASE  = int'(OFFSET[L][i]);    // 本列在 layer_in[L] 里的起点
      localparam int NBASE = int'(OFFSET[L+1][i]);  // 本列结果在 layer_out[L] 里的起点

      // ---- 满 4 的块：C53 ----
      for (genvar j = 0; j < NC; j++) begin : g_c53
        // 第 5 个输入取低一列第 j 个 C53 的 cout1；低一列没这么多就接常数 0
        // （golden 里这类实例的 io_in_4 就是字面量 1'h0）。
        // ★用 generate-if 而不是三目★：i==0 时根本没有"低一列"，三目表达式里的
        // c53_cout1[L][i-1][j] 即使条件恒假也要被 elaborate，下标 -1 当场非法。
        wire cin;
        if (j < CINL) begin : g_cin_from_prev
          assign cin = c53_cout1[L][i-1][j];
        end else begin : g_cin_zero
          assign cin = 1'b0;
        end
        xs_CSA5_3_core #(.WIDTH(1)) u_c53 (
          .in_0  (layer_in[L][BASE + 4*j + 0]),
          .in_1  (layer_in[L][BASE + 4*j + 1]),
          .in_2  (layer_in[L][BASE + 4*j + 2]),
          .in_3  (layer_in[L][BASE + 4*j + 3]),
          .in_4  (cin),
          .out_0 (c53_sum  [L][i][j]),
          .out_1 (c53_cout1[L][i][j]),
          .out_2 (c53_cout2[L][i][j])
        );
        assign layer_out[L][NBASE + j] = c53_sum[L][i][j];
      end
      if (NC < MAXC) begin : g_c53_unused
        assign c53_sum  [L][i][MAXC-1:NC] = '0;
        assign c53_cout1[L][i][MAXC-1:NC] = '0;
        assign c53_cout2[L][i][MAXC-1:NC] = '0;
      end

      // ---- 尾块 ----
      if (R == 1) begin : g_tail_pass
        assign tail_sum [L][i] = layer_in[L][BASE + 4*NC];   // 单独一位，原样下传
        assign tail_cout[L][i] = 1'b0;
      end else if (R == 2) begin : g_tail_c22
        xs_CSA2_2_core #(.WIDTH(1)) u_c22 (
          .in_0  (layer_in[L][BASE + 4*NC + 0]),
          .in_1  (layer_in[L][BASE + 4*NC + 1]),
          .out_0 (tail_sum [L][i]),
          .out_1 (tail_cout[L][i])
        );
      end else if (R == 3) begin : g_tail_c32
        xs_CSA3_2_core #(.WIDTH(1)) u_c32 (
          .in_0  (layer_in[L][BASE + 4*NC + 0]),
          .in_1  (layer_in[L][BASE + 4*NC + 1]),
          .in_2  (layer_in[L][BASE + 4*NC + 2]),
          .out_0 (tail_sum [L][i]),
          .out_1 (tail_cout[L][i])
        );
      end else begin : g_tail_none
        assign tail_sum [L][i] = 1'b0;
        assign tail_cout[L][i] = 1'b0;
      end
      if (R != 0) begin : g_tail_to_next
        assign layer_out[L][NBASE + NC] = tail_sum[L][i];
      end

      // ---- 低一列没被吃掉的 cin，原样并进本列 ----
      localparam int B1 = NC + ((R != 0) ? 1 : 0);
      for (genvar q = 0; q < LEFT; q++) begin : g_spill_cin
        assign layer_out[L][NBASE + B1 + q] = c53_cout1[L][i-1][NC + q];
      end

      // ---- 低一列的 cout2 们（权重高一位，正好落在本列）----
      localparam int B2 = B1 + LEFT;
      for (genvar m = 0; m < NCO2; m++) begin : g_prev_cout2
        if (m < n_c53(HP)) begin : g_from_c53
          assign layer_out[L][NBASE + B2 + m] = c53_cout2[L][i-1][m];
        end else begin : g_from_tail
          assign layer_out[L][NBASE + B2 + m] = tail_cout[L][i-1];
        end
      end
    end
  end

  // ★不复位★：与第 1 级同一个 always 块语义（golden 里两级就在同一个
  // `always @(posedge clock)` 里，两个互不重叠的 if 使能段）。
  always_ff @(posedge clock) begin
    if (reg_en_mid) mid_reg <= layer_out[NLAYER-1][TOT_MID-1:0];
  end

  // ---------------------------------------------------------------------------
  // §2.5 收尾：最后一层每列 ≤2 位 → 一次 130 位进位传播加法
  // 低位拼 sum、高位拼 carry；最低的几列只剩 1 位（没有 carry），那几位 carry 恒 0。
  // ---------------------------------------------------------------------------
  logic [NCOL-1:0] tree_sum, tree_carry;

  // golden 把 carry 向量的低 CARRY_START 位钉成常数 0（末尾那个字面量 `5'h0`）。
  // 下面的 generate 用"本列高度是否 ≥2"表达同一件事——两者等价的前提是最后一层的
  // 高度剖面单调（前 CARRY_START 列各 1 位、其后全 2 位）。这个前提在 elaborate 期
  // 直接验，不靠人记住：剖面一旦变了，这里当场报错而不是悄悄生成另一个电路。
  localparam int CARRY_START = carry_start();
  for (genvar i = 0; i < NCOL; i++) begin : g_carry_profile_check
    if ((i < CARRY_START) != (int'(HEIGHT[NLAYER][i]) < 2))
      $error("ArrayMulDataModule: 末层高度剖面不单调（列 %0d 高度 %0d，CARRY_START=%0d）",
             i, int'(HEIGHT[NLAYER][i]), CARRY_START);
  end

  for (genvar i = 0; i < NCOL; i++) begin : g_final
    localparam int OB = int'(OFFSET[NLAYER][i]);
    assign tree_sum[i] = layer_in[NLAYER][OB];
    if (int'(HEIGHT[NLAYER][i]) >= 2) begin : g_has_carry
      assign tree_carry[i] = layer_in[NLAYER][OB + 1];
    end else begin : g_no_carry
      assign tree_carry[i] = 1'b0;
    end
  end

  assign result = tree_sum + tree_carry;   // 130 位，进位溢出丢弃

endmodule : xs_ArrayMulDataModule_core

// =============================================================================
// §3 ArrayMulDataModule —— golden 同名 wrapper
// 端口与 golden 逐位同名同序；★没有 reset★（本模块所有寄存器都不复位）。
// =============================================================================
module ArrayMulDataModule(
  input          clock,
  input  [64:0]  io_a,
  input  [64:0]  io_b,
  input          io_regEnables_0,
  input          io_regEnables_1,
  output [129:0] io_result
);
  xs_ArrayMulDataModule_core u_core (
    .clock      (clock),
    .a          (io_a),
    .b          (io_b),
    .reg_en_pp  (io_regEnables_0),
    .reg_en_mid (io_regEnables_1),
    .result     (io_result)
  );
endmodule
