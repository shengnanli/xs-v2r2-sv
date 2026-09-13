// =============================================================================
// xs_PipelineConnect —— 带握手的单级流水线寄存器（buffer stage）
//
// 对应 Chisel: xiangshan.backend.datapath.NewPipelineConnectPipe / NewPipelineConnect
// 语义（与 Scala 完全一致）：
//   in_ready = out_ready | ~valid           // 空或下游可收时可纳新数据
//   fire     = in_valid & in_ready          // 左侧握手成功
//   valid 寄存器：isFlush 清零（最高优先级）；否则 fire 置 1；否则 rightOutFire 清零；
//                 否则保持 → valid' = ~isFlush & (fire | ~rightOutFire & valid)
//   data = RegEnable(in_bits, fire)          // 数据在 fire 拍锁存
//   out_valid = valid，out_bits = data
// 注意：rightOutFire 是“下游本拍是否取走”的外部信号（通常 = out_valid & out_ready，
// 但由调用方提供，可能与 out_ready 不同步），用于决定何时清空本级。
//
// payload 用打包总线 io_in_bits/io_out_bits 表示，字段由外层包装层拼接/拆分。
// =============================================================================
module xs_PipelineConnect #(
  parameter int unsigned DATA_WIDTH = 1,
  // G1 锚点（fail-closed，没有可用默认值）：调用方（变体薄文件）把「G1 golden 该
  // 变体所有 io_in_bits_* 端口位数之和」原样传进来，本核校验它 == 实际 payload
  // 位数。薄文件用 packed struct 打包、DATA_WIDTH 取 $bits(payload_t) —— 两者对
  // 不上就说明 struct 字段表和 G1 端口表脱节（这一族历史上正是集体照抄了 G0 端口
  // 表才全体配错，13 个变体缺 18~71 个端口躺在仓库里没人发现）。
  //
  // ★曾经的 fail-open 已封★：本参数原先默认 = DATA_WIDTH，于是「薄文件不传」
  // 等于「不校验」——正好把最需要校验的那种文件（随手写的、没对过 golden 的）
  // 放过去。现在默认 0 = 没传，直接 $fatal。
  // 权威闸仍是 scripts/port_contract_lint.py；本自检把同一类错误提前到 elaborate。
  parameter int unsigned PAYLOAD_W_G1 = 0
)(
  input  logic                    clock,
  input  logic                    reset,          // 异步高有效，仅复位 valid
  output logic                    io_in_ready,
  input  logic                    io_in_valid,
  input  logic [DATA_WIDTH-1:0]   io_in_bits,
  input  logic                    io_out_ready,
  output logic                    io_out_valid,
  output logic [DATA_WIDTH-1:0]   io_out_bits,
  input  logic                    io_rightOutFire,
  input  logic                    io_isFlush
);

  // ---------------------------------------------------------------------------
  // 参数自检：位数等式对不上就立刻炸，别让错位的 payload 悄悄跑完 20 万拍。
  //
  // 这里用的是 **elaboration-time system task**（$fatal 直接写在模块体里，不是
  // 写在 initial 里）。实测差别：模块体形式 VCS 在 elaborate 阶段就报
  // `Error-[FEST] $fatal elaboration system task` 并以 rc=255 退出，不跑仿真的
  // 纯 elaborate / 综合流程也拦得住；initial 形式只有仿真启动 time 0 才炸。
  // Formality（V-2023.12-SP3）两种写法都读得进；条件为真时它打印同一条消息并把
  // 本模块降级成黑盒，会被 fm_verdict 的 bbox 闸拦下，仍是 fail-closed。
  // 注意：消息里不要用 UTF-8 含 0xAE 字节的汉字（宏/位宽/实/定/段/算…），VCS 在
  // elaboration 消息里会把那个字节打成 '.'，好好一句话变乱码（运行期 $fatal 正常）。
  // ---------------------------------------------------------------------------
  if (PAYLOAD_W_G1 == 0)
    $fatal(1, "xs_PipelineConnect: 薄文件必须传 PAYLOAD_W_G1(= G1 golden 该变体 io_in_bits_* 端口位数之和), 不传不给过 -- 当前 DATA_WIDTH=%0d",
           DATA_WIDTH);
  if (DATA_WIDTH < 1)
    $fatal(1, "xs_PipelineConnect: DATA_WIDTH=%0d 不合法(payload 至少 1 位)", DATA_WIDTH);
  if (DATA_WIDTH != PAYLOAD_W_G1)
    $fatal(1, "xs_PipelineConnect: payload 打包出来 %0d 位 != G1 golden 逐项位数之和 %0d 位 -- 打包清单和 G1 端口表脱节了",
           DATA_WIDTH, PAYLOAD_W_G1);

  logic                  valid;
  logic [DATA_WIDTH-1:0] data;
  logic                  fire;

  assign io_in_ready = io_out_ready | ~valid;
  assign fire        = io_in_valid & io_in_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) valid <= 1'b0;
    else       valid <= ~io_isFlush & (fire | (~io_rightOutFire & valid));
  end

  always_ff @(posedge clock) begin
    if (fire) data <= io_in_bits;
  end

  assign io_out_valid = valid;
  assign io_out_bits  = data;

endmodule
