// =============================================================================
// xs_PlruReplacer —— 树形伪 LRU 替换器
//
// 对应 Chisel: utility.ReplacementPolicy.fromString("plru", n)（rocket-chip
// PseudoLRU），状态编码与其完全一致（等价性验证依赖这一点）：
//   - 状态共 NUM_WAYS-1 位，按二叉树布局：段 state[offset +: m-1] 描述一棵覆盖
//     m 路的子树，段最高位 state[offset+m-2] 是该子树的根；
//   - 根为 1 表示下次应从"编号较高的半边"替换，其高半边子树占据段的高半段
//     （offset+m/2-1 起），低半边子树从 offset 起；
//   - 访问（touch）某路时，沿该路对应的树路径，把每个节点写成"指向另一半边"。
// 例：NUM_WAYS=8 时 state[6] 为根，state[5:3] 为高半树，state[2:0] 为低半树。
//
// 仅支持 NUM_WAYS 为 2 的幂（香山前端的全部用例均满足）。
// =============================================================================
module xs_PlruReplacer #(
  parameter int unsigned NUM_WAYS = 8,
  localparam int unsigned WAY_W  = (NUM_WAYS > 1) ? $clog2(NUM_WAYS) : 1,
  localparam int unsigned LEVELS = $clog2(NUM_WAYS)
)(
  input  logic             clock,
  input  logic             reset,        // 异步复位，状态清零
  input  logic             touch_valid,  // 本拍访问有效
  input  logic [WAY_W-1:0] touch_way,    // 被访问的路
  output logic [WAY_W-1:0] replace_way   // 当前建议替换的路（组合输出）
);

  initial begin
    if (NUM_WAYS < 2 || (1 << LEVELS) != NUM_WAYS)
      $fatal(1, "xs_PlruReplacer: NUM_WAYS=%0d 必须是不小于 2 的 2 的幂", NUM_WAYS);
  end

  logic [NUM_WAYS-2:0] state_reg;

  // 选路：从根开始，沿置位指示的半边逐级下行
  always_comb begin
    automatic int unsigned offset = 0;
    automatic int unsigned m      = NUM_WAYS;
    replace_way = '0;
    for (int unsigned l = 0; l < LEVELS; l++) begin
      automatic logic b = state_reg[offset + m - 2];
      replace_way = WAY_W'((replace_way << 1) | WAY_W'(b));
      if (b) offset += m / 2 - 1;
      m /= 2;
    end
  end

  // 更新：沿 touch_way 的树路径，各节点翻转为指向另一半边
  function automatic logic [NUM_WAYS-2:0] next_state(
    input logic [NUM_WAYS-2:0] s,
    input logic [WAY_W-1:0]    way
  );
    int unsigned offset, m;
    logic b;
    next_state = s;
    offset = 0;
    m      = NUM_WAYS;
    for (int unsigned l = 0; l < LEVELS; l++) begin
      b = way[WAY_W - 1 - l];
      next_state[offset + m - 2] = ~b;
      if (b) offset += m / 2 - 1;
      m /= 2;
    end
  endfunction

  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      state_reg <= '0;
    else if (touch_valid)
      state_reg <= next_state(state_reg, touch_way);
  end

endmodule
