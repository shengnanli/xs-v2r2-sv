// xs_SpillRegister_core.sv —— 两级 skid buffer（免反压寄存的 valid/ready 缓冲）
//
// 共享族核（不对应任何 golden 模块）：uncore 里 NCBDownstream{AW,AR,W}{,_1} 的
// SpillRegister / SpillRegister_2 / SpillRegister_6 三个变体共用它。各变体的薄文件
// （同目录 <名>.sv，由 scripts/gen_busbuffer_leaves5.py 生成）只负责把各自的
// payload 字段拼成整字 / 拆回来；payload 在本核里是不透明整字，位宽由参数 W 给。
//
// 语义（照 golden 逐拍）：
//   * 主槽 main 收新拍的条件 = in_ready & in_valid，而 in_ready = ~spill_valid
//     （与 out_ready 无关：spill 槽一空就能收，不是 pipe）。
//   * 收新拍的当拍出方不接（out_ready=0）时，主槽旧内容溢出进 spill 槽；
//     出方永远先出 spill（较旧）再出 main，保序。
//   * out_valid = main_valid | spill_valid；out_payload 取 spill 优先于 main。
//   * 两个 valid 异步复位清 0；两级 payload 寄存器都**不复位**（golden 如此，
//     空缓冲时 out_payload 读的是上电值——合法，契约是只看 valid）。
module xs_SpillRegister_core #(
  parameter int unsigned W = 1
)(
  input  logic         clock,
  input  logic         reset,
  output logic         in_ready,
  input  logic         in_valid,
  input  logic [W-1:0] in_payload,
  input  logic         out_ready,
  output logic         out_valid,
  output logic [W-1:0] out_payload
);

  logic         main_valid;
  logic [W-1:0] main_payload;
  logic         spill_valid;
  logic [W-1:0] spill_payload;

  // load_main：本拍收新拍进主槽；spill_over：收新拍且出方不接，主槽旧内容溢出。
  // （对应 golden 里名为 _GEN / _GEN_0 的两根组合线）
  logic load_main;
  logic spill_over;
  assign load_main  = ~spill_valid & in_valid;
  assign spill_over = load_main & ~out_ready;

  // valid 寄存器：异步复位（golden 的 always @(posedge clock or posedge reset)）。
  // main_valid：收新拍置 1；出方接走且 spill 空（主槽内容就是出方看到的）时清 0。
  // spill_valid：溢出时接过 main_valid；否则出方接走时清 0。
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      main_valid  <= 1'b0;
      spill_valid <= 1'b0;
    end
    else begin
      main_valid <= load_main | ~(out_ready & ~spill_valid) & main_valid;
      if (spill_over)
        spill_valid <= main_valid;
      else
        spill_valid <= ~out_ready & spill_valid;
    end
  end

  // payload 寄存器：照 golden 无复位（always @(posedge clock)，写使能同上）。
  always_ff @(posedge clock) begin
    if (load_main)
      main_payload <= in_payload;
    if (spill_over)
      spill_payload <= main_payload;
  end

  assign in_ready    = ~spill_valid;
  assign out_valid   = main_valid | spill_valid;
  assign out_payload = spill_valid ? spill_payload : main_payload;

endmodule
