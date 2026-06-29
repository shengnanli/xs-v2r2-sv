// =============================================================================
//  fastarbiter_pkg —— CHI FastArbiter 族 (RNXbar/SNXbar 通道仲裁器) 公共算法
// -----------------------------------------------------------------------------
//  对应 OpenLLC / CoupledL2 的 FastArbiter (Chisel `utility.FastArbiter`):
//  对 N 个输入做 "带挂起记忆的 round-robin" 仲裁, 选中后把胜者 payload 用 one-hot
//  OR 归约多路选择到唯一输出口。香山 V2R2 里 RNXbar/SNXbar 的 CHI TX/RX 通道仲裁
//  全部例化它, 固定 N=4 (4 主口 / 4 bank); 单输入变体 (_30/_31/_36) 退化为纯透传,
//  不依赖本包。
//
//  ---------------------------------------------------------------------------
//  round-robin 算法 (本族 4 输入变体 _27/_44/_46/_47 完全一致, 只是 payload 不同):
//    两个 4 位状态寄存器 (复位皆 0):
//      pendingMask : 上一拍 "valid 但未被选中" 的输入集合 (本轮欠服务者)。
//      rrGrantMask : 优先区掩码 = "上次胜者下标之后" 的所有下标 (下一轮从这里起选)。
//    组合选胜 (rr_choose):
//      rrSelOH = lowest_oh(rrGrantMask & pendingMask)
//                —— 在 "欠服务且落在优先区" 的输入里取下标最小者 (公平轮转的核心)。
//      chosenOH = (rrSelOH 命中当前 valid) ? rrSelOH : lowest_oh(valids)
//                —— 否则退化为对当前 valids 取固定优先级最低位 (冷启动/无欠服务时)。
//    胜者更新 (仅当下游 ready 且本拍有请求时):
//      pendingMask <= valids & ~chosenOH      // 没被选中的 valid 转入欠服务
//      rrGrantMask <= gt_mask(chosenOH)       // 优先区推进到本次胜者之后
//
//  ---------------------------------------------------------------------------
//  验证: 各 FastArbiter_NN 由 golden 同名 wrapper 例化本族核; UT 双例化逐拍比对全部
//  输出 (随机 valids + 随机 io_out_ready 自然遍历轮转相位); FM 证组合/时序等价。
// =============================================================================
package fastarbiter_pkg;

  // 多输入 CHI FastArbiter 在香山里恒为 4 路 (RNXbar 的 4 bank / SNXbar 的 4 主口)。
  localparam int unsigned NUM  = 4;
  localparam int unsigned IDXW = $clog2(NUM);   // = 2, io_chosen 的位宽

  // ---------------------------------------------------------------------------
  //  lowest_oh(x) —— 隔离最低置位 (x & -x): 取向量里下标最小的 1 单独输出。
  //  即对 x 做 "固定优先级 (低下标优先) 的 one-hot 选择"。x=0 ⇒ 输出 0。
  // ---------------------------------------------------------------------------
  function automatic logic [NUM-1:0] lowest_oh(input logic [NUM-1:0] x);
    lowest_oh = x & (~x + 1'b1);   // ~x+1 = 二进制补码取负, 与 x 相与得最低置位
  endfunction

  // ---------------------------------------------------------------------------
  //  gt_mask(oh) —— 严格大于掩码: one-hot oh 的置位下标记为 p, 返回所有下标 > p 的位。
  //    bit[i] = OR(oh[i-1:0])  ⇒ bit0 恒 0, 高位逐级把 "比 p 大" 的位置 1。
  //  用作下一轮 rrGrantMask: 让优先级轮转到刚服务过的输入之后, 实现公平。
  // ---------------------------------------------------------------------------
  function automatic logic [NUM-1:0] gt_mask(input logic [NUM-1:0] oh);
    gt_mask = '0;
    for (int i = 0; i < NUM; i++)
      gt_mask[i] = |(oh & (NUM'(NUM'(1) << i) - NUM'(1)));   // oh 的低 i 位是否有置位
  endfunction

  // ---------------------------------------------------------------------------
  //  encode_oh(oh) —— one-hot → 二进制下标 (至多一位置位; 全 0 返回 0)。即 io_chosen。
  // ---------------------------------------------------------------------------
  function automatic logic [IDXW-1:0] encode_oh(input logic [NUM-1:0] oh);
    encode_oh = '0;
    for (int i = 0; i < NUM; i++)
      if (oh[i]) encode_oh = IDXW'(i);
  endfunction

  // ---------------------------------------------------------------------------
  //  rr_choose —— 组合选胜逻辑 (见文件头算法): 给定当前 valids 与两个状态寄存器,
  //  返回本拍胜者的 one-hot。
  // ---------------------------------------------------------------------------
  function automatic logic [NUM-1:0] rr_choose(input logic [NUM-1:0] valids,
                                               input logic [NUM-1:0] pendingMask,
                                               input logic [NUM-1:0] rrGrantMask);
    logic [NUM-1:0] rrSelOH;
    rrSelOH   = lowest_oh(rrGrantMask & pendingMask);
    rr_choose = (|(rrSelOH & valids)) ? rrSelOH : lowest_oh(valids);
  endfunction

endpackage
