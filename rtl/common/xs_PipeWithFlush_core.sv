// =============================================================================
// xs_PipeWithFlush_core —— 带冲刷的 N 级发射流水（PipeWithFlush 家族的核）
//
// 对应 Chisel `PipeWithFlush`。香山后端把一条发射请求（uop 的若干字段 + 一个
// valid）沿发射流水打 N 拍；这 N 拍里如果发生重定向（分支预测失败 / 异常）或者
// 上一级发射失败，队伍里已经作废的条目要被就地冲掉，而不是让它继续走完。
//
//   valids[1] <= enq_valid                      ← ★第 1 级不冲刷★
//   valids[k] <= valids[k-1] & ~flush[k]   (k>=2)
//   bits[1]   <= enq_bits         当 enq_valid
//   bits[k]   <= age(bits[k-1])   当 valids[k-1]
//
// ★为什么第 1 级不冲刷★
// 冲刷判据要读「这一拍正待前移的那个条目的 robIdx」。对第 1 级来说那个条目还在
// 组合输入 enq_bits 上，没有落进任何寄存器，这一层拿不到；该挡的由上游发射级挡。
// 所以 golden 的 N=1 变体（PipeWithFlush_6 / _10）**一个 flush 端口都没有** ——
// 不是被裁剪掉了，是家族公式里本来就用不到。N=0 变体更是连 clock / reset 都没有。
//
// ★flush[k] 的三项★（都从 golden 读出来，缺一不可）
//   1) redirect：`redirect.valid & (level & robIdx == redirRobIdx | isAfter)`
//      isAfter = `flag ^ redirFlag ^ (value > redirValue)` —— 香山的**环形**
//      robIdx 比较：flag 是回绕位，两边回绕位不同就说明跨了一圈，比较要反过来。
//      golden 把它写成一串裸 `^`，靠 Verilog 里 `>` 紧于 `^` 的优先级断句。
//   2) ldCancel：`ldCancel[j] & loadDependency[j] 的最高位`，逐路或。
//      只有带 loadDependency 字段的变体才有（本家族里只有 PipeWithFlush_1）。
//   3) ogFail：第 k 级专属的一根「上一级发射失败」输入，取 flush_ogfail[k-2]。
//
// ★loadDependency 级间要老化一位★
// 它是「这个条目还欠第 j 路 load 几拍」的移位计数器：每前移一级左移一位，
// 最高位移出去就表示这一路的依赖已经过期。**第 1 级不移** —— 入口那份已经是
// 当前拍的值。其余字段一律原样搬。
//
// ★载荷布局约定★（薄文件按这个顺序拼包，核按这个顺序拆）
//   enq_bits = { 普通字段（golden 端口顺序）, robIdx[8:0]={flag,value}, loadDependency 块 }
// loadDependency 块里第 j 路占 [j*LD_W +: LD_W]，j=0 在最低位。
// 把这两类"有语义"的字段固定放在低位，核就不必再要一串位置参数 ——
// 位置由约定确定，薄文件与核只在这一处对齐。
//
// elaborate 期不变式（见下面 initial）：
//   STAGES*(1+WIDTH) == GOLDEN_REG_BITS —— 右边是从 golden reg 声明数出来的位数，
//   每级 1 个 valid 位 + WIDTH 个载荷位。级数或载荷位宽抄错，等式立刻不成立。
//   PORT_BITS_IN/OUT 由薄文件用 $bits(golden 端口拼接) 传进来，必须等于 WIDTH。
//   STAGES>=2 必须 HAS_ROBIDX：没有 robIdx 就写不出冲刷判据。
// =============================================================================
module xs_PipeWithFlush_core #(
  parameter int unsigned WIDTH           = 1,   // 载荷总位数（含 robIdx 与 loadDependency）
  parameter int unsigned STAGES          = 0,   // 流水级数 N
  parameter int unsigned HAS_ROBIDX      = 0,   // 载荷里有没有 robIdx（有冲刷就必须有）
  parameter int unsigned LD_CNT          = 0,   // loadDependency 路数（没有就是 0）
  parameter int unsigned LD_W            = 2,   // 每路 loadDependency 的位宽
  parameter int unsigned GOLDEN_REG_BITS = STAGES * (1 + WIDTH),
  parameter int unsigned PORT_BITS_IN    = WIDTH,   // = $bits({golden io_enq_bits_*})
  parameter int unsigned PORT_BITS_OUT   = WIDTH    // = $bits({golden io_deq_bits_*})
)(
  input  logic clock,      // STAGES==0 时不被使用（golden 也没有这个口）
  input  logic reset,      // 异步高有效，只作用于 valid 链（照搬 golden）

  // 冲刷输入。STAGES<2 时一概不被使用 —— golden 那几个变体连端口都没有。
  // 两个向量的宽度用 `?:` 兜到至少 1 位：SV 不允许零宽端口，而 LD_CNT=0 /
  // STAGES<2 时它们本来就不该被读。占位宽度不代表有这么多路。
  input  logic                                     flush_redirect_valid,
  input  logic                                     flush_redirect_level,
  input  logic [8:0]                               flush_redirect_robidx, // {flag,value}
  input  logic [(LD_CNT    > 0 ? LD_CNT     : 1)-1:0] flush_ldcancel,
  input  logic [(STAGES    > 1 ? STAGES - 1 : 1)-1:0] flush_ogfail,       // 位 k-2 给第 k 级

  input  logic             enq_valid,
  input  logic [WIDTH-1:0] enq_bits,
  output logic             deq_valid,
  output logic [WIDTH-1:0] deq_bits
);

  localparam int unsigned LD_BITS    = LD_CNT * LD_W;   // loadDependency 块总位数
  localparam int unsigned ROBIDX_LSB = LD_BITS;         // robIdx 紧挨在它上面

  initial begin
    if (WIDTH == 0)
      $fatal(1, "xs_PipeWithFlush_core: WIDTH=0 不合法");
    if (STAGES * (1 + WIDTH) != GOLDEN_REG_BITS)
      $fatal(1, "xs_PipeWithFlush_core: %0d 级 × (1 valid + %0d 载荷) = %0d != golden reg 位数 %0d（参数抄错）",
             STAGES, WIDTH, STAGES * (1 + WIDTH), GOLDEN_REG_BITS);
    if (PORT_BITS_IN != WIDTH)
      $fatal(1, "xs_PipeWithFlush_core: golden io_enq_bits_* 共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_IN, WIDTH);
    if (PORT_BITS_OUT != WIDTH)
      $fatal(1, "xs_PipeWithFlush_core: golden io_deq_bits_* 共 %0d 位 != WIDTH=%0d（端口位宽抄错）",
             PORT_BITS_OUT, WIDTH);
    if (STAGES >= 2 && HAS_ROBIDX == 0)
      $fatal(1, "xs_PipeWithFlush_core: STAGES=%0d 要写冲刷判据，但载荷里没有 robIdx", STAGES);
    if (HAS_ROBIDX != 0 && ROBIDX_LSB + 9 > WIDTH)
      $fatal(1, "xs_PipeWithFlush_core: robIdx 放在 [%0d +: 9] 越过了载荷宽度 %0d",
             ROBIDX_LSB, WIDTH);
    if (LD_CNT > 0 && LD_W < 2)
      $fatal(1, "xs_PipeWithFlush_core: LD_W=%0d < 2 —— 老化左移需要至少 2 位", LD_W);
    if (LD_BITS > WIDTH)
      $fatal(1, "xs_PipeWithFlush_core: loadDependency 块 %0d 位放不进载荷 %0d 位", LD_BITS, WIDTH);
  end

  // 级间搬运：loadDependency 每路左移一位（老化），其余字段原样。
  function automatic logic [WIDTH-1:0] age(input logic [WIDTH-1:0] v);
    age = v;
    for (int unsigned j = 0; j < LD_CNT; j++)
      age[j*LD_W +: LD_W] = {v[j*LD_W +: LD_W-1], 1'b0};
  endfunction

  generate
    if (STAGES == 0) begin : g_wire
      // N=0 的退化情形（PipeWithFlush / PipeWithFlush_8）：enq 直通 deq。
      // golden 连 clock / reset / 任何 flush 端口都没有。
      assign deq_valid = enq_valid;
      assign deq_bits  = enq_bits;
    end else begin : g_pipe
      logic [STAGES:1]  valids_q;
      logic [WIDTH-1:0] bits_q [1:STAGES];

      // ---------------- valid 链 ----------------
      if (STAGES == 1) begin : g_valid1
        // 只有一级，而第 1 级不冲刷（见文件头）—— golden 的 N=1 变体连 flush
        // 端口都没有，这里也就一根 flush 信号都不生成。
        always_ff @(posedge clock or posedge reset) begin
          if (reset) valids_q[1] <= 1'b0;
          else       valids_q[1] <= enq_valid;
        end
      end else begin : g_validn
        logic [STAGES:2] flush;      // 只有第 2 级起才有冲刷

        for (genvar k = 2; k <= STAGES; k++) begin : g_flush
          // 判据读的是**第 k-1 级**寄存器里的条目：它正要前移到第 k 级。
          wire [8:0] prev_robidx = bits_q[k-1][ROBIDX_LSB +: 9];

          // level=1 的重定向连"就是它自己"那一条也要冲掉
          wire hit_self = flush_redirect_level & (prev_robidx == flush_redirect_robidx);
          // 环形 robIdx 比较：flag 是回绕位，回绕位不同就把大小关系反过来
          wire is_after = prev_robidx[8] ^ flush_redirect_robidx[8]
                        ^ (prev_robidx[7:0] > flush_redirect_robidx[7:0]);

          // 这一路 load 已被取消，且本条目还欠着它（计数器最高位还是 1）
          logic ld_hit;
          always_comb begin
            ld_hit = 1'b0;
            for (int unsigned j = 0; j < LD_CNT; j++)
              ld_hit |= flush_ldcancel[j] & bits_q[k-1][j*LD_W + (LD_W-1)];
          end

          assign flush[k] = flush_redirect_valid & (hit_self | is_after)
                          | ld_hit
                          | flush_ogfail[k-2];
        end

        always_ff @(posedge clock or posedge reset) begin
          if (reset)
            valids_q <= '0;
          else begin
            valids_q[1] <= enq_valid;      // 第 1 级不冲刷
            for (int unsigned k = 2; k <= STAGES; k++)
              valids_q[k] <= valids_q[k-1] & ~flush[k];
          end
        end
      end

      // ---------------- 数据链 ----------------
      // 无复位（golden 的数据 always 块里就没有 reset 分支），上电为 X，
      // 要等各自的使能拉过一次才有定值。
      always_ff @(posedge clock) begin
        if (enq_valid) bits_q[1] <= enq_bits;          // 第 1 级从组合输入收，不老化
        for (int unsigned k = 2; k <= STAGES; k++)
          if (valids_q[k-1]) bits_q[k] <= age(bits_q[k-1]);
      end

      assign deq_valid = valids_q[STAGES];
      assign deq_bits  = bits_q[STAGES];
    end
  endgenerate

endmodule
