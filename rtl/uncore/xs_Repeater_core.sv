// xs_Repeater_core.sv —— TileLink 握手 repeat 缓冲（repeat 期间 deq 侧 bits 保持不变）
//
// 共享族核（不对应任何 golden 模块）：TLFragmenter{,_1} 的 Repeater_1 与
// TLWidthWidget_1 的 Repeater_2 共用它。各变体的薄文件（同目录 <名>.sv，由
// scripts/gen_busbuffer_leaves5.py 生成）只负责把各自的 payload 字段拼成整字 /
// 拆回来；Repeater_1 多一个 io_full 观测口，Repeater_2 不引出（薄文件里悬空）。
//
// 语义（照 golden 逐拍）：
//   * 直通优先：deq_valid = enq_valid | full；不满时 deq_payload 直接来自 enq。
//   * 本拍 enq 被接受且 repeat_req=1 时，把 enq payload 存进 saved 并置 full：
//     之后 deq 侧反复发同一份 bits，直到某拍 deq 接走且 repeat_req=0 才清 full。
//   * enq_ready = deq_ready & ~full：满时只有 deq 接走的拍才能再收新拍。
//   * full 异步复位清 0；saved payload 寄存器**不复位**（golden 如此）。
module xs_Repeater_core #(
  parameter int unsigned W = 1
)(
  input  logic         clock,
  input  logic         reset,
  input  logic         repeat_req,
  output logic         full,
  output logic         enq_ready,
  input  logic         enq_valid,
  input  logic [W-1:0] enq_payload,
  input  logic         deq_ready,
  output logic         deq_valid,
  output logic [W-1:0] deq_payload
);

  logic [W-1:0] saved_payload;

  assign deq_valid = enq_valid | full;
  assign enq_ready = deq_ready & ~full;

  // 本拍收下的是"需要重复发"的请求：存起来（对应 golden 里名为 _GEN 的组合线）。
  logic save_beat;
  assign save_beat = enq_ready & enq_valid & repeat_req;

  // full：deq 接走一份且不再 repeat 时清 0；收下需重复的拍时置 1，否则保持。
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      full <= 1'b0;
    else
      full <= ~(deq_ready & deq_valid & ~repeat_req) & (save_beat | full);
  end

  // saved payload：照 golden 无复位（只在收需重复的拍时写）。
  always_ff @(posedge clock) begin
    if (save_beat)
      saved_payload <= enq_payload;
  end

  assign deq_payload = full ? saved_payload : enq_payload;

endmodule
