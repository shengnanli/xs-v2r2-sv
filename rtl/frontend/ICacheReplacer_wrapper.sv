// 自动生成：scripts/gen_icachereplacer.py —— 勿手改
// golden 同名包装层：模块名 ICacheReplacer，端口与 golden 完全一致；
// 内部例化可读核 xs_ICacheReplacer_core（端口本就是 golden 扁平名）。
module ICacheReplacer(
  input        clock,
  input        reset,
  input  io_touch_0_valid,
  input  [7:0] io_touch_0_bits_vSetIdx,
  input  [1:0] io_touch_0_bits_way,
  input  io_touch_1_valid,
  input  [7:0] io_touch_1_bits_vSetIdx,
  input  [1:0] io_touch_1_bits_way,
  input  io_victim_vSetIdx_valid,
  input  [7:0] io_victim_vSetIdx_bits,
  output [1:0] io_victim_way
);
  xs_ICacheReplacer_core #(.NUM_SETS(256), .NUM_WAYS(4)) u_core (
    .clock(clock),
    .reset(reset),
    .io_touch_0_valid(io_touch_0_valid),
    .io_touch_0_bits_vSetIdx(io_touch_0_bits_vSetIdx),
    .io_touch_0_bits_way(io_touch_0_bits_way),
    .io_touch_1_valid(io_touch_1_valid),
    .io_touch_1_bits_vSetIdx(io_touch_1_bits_vSetIdx),
    .io_touch_1_bits_way(io_touch_1_bits_way),
    .io_victim_vSetIdx_valid(io_victim_vSetIdx_valid),
    .io_victim_vSetIdx_bits(io_victim_vSetIdx_bits),
    .io_victim_way(io_victim_way)
  );
endmodule
