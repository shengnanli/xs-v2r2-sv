// NewPipelineConnectPipe_33 —— VSegmentUnit 的段访存请求缓冲级（本家族的一个单态化变体）
// 例化点（G1 golden）：VSegmentUnit.VSegmentUnitPipelineConnect，全设计仅此一处。
// 本变体参数：payload = {vaddr[49:0], data[127:0], mask[15:0], addr[47:0], vecValid}
//   共 243 位；**无 io_isFlush 端口**（Chisel 侧该处没接 flush，firtool 把常量 0
//   折进去了），故核体的 io_isFlush 在这里恒接 1'b0。
// 端口规模：10 输入 / 7 输出，共 17 端口。握手/寄存语义见核体 rtl/common/PipelineConnect.sv。
//
// ★名字警告★：G0(v2r2) 里叫 NewPipelineConnectPipe_33 的是另一个模块（96 端口，
// MemBlock 的 4 个向量拆分连接），那个在 G1 里叫 NewPipelineConnectPipe_35。
// 本文件的内容在 G0 里的名字是 NewPipelineConnectPipe_31。
// 判据：例化点 + 模块体归一化后逐字相等，见 scripts/check_name_collisions.py。

module NewPipelineConnectPipe_33(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [49:0] io_in_bits_vaddr,
  input  [127:0] io_in_bits_data,
  input  [15:0] io_in_bits_mask,
  input  [47:0] io_in_bits_addr,
  input  io_in_bits_vecValid,
  input  io_out_ready,
  output io_out_valid,
  output [49:0] io_out_bits_vaddr,
  output [127:0] io_out_bits_data,
  output [15:0] io_out_bits_mask,
  output [47:0] io_out_bits_addr,
  output io_out_bits_vecValid,
  input  io_rightOutFire
);
  // payload 布局：字段宽度 + 各字段在打包总线里的低位偏移。切片一律由这里推出来，
  // 不写字面范围——写死的 [242:193] 这类范围改错一个数就是一处静默错线。
  localparam int unsigned W_VADDR    = 50;
  localparam int unsigned W_DATA     = 128;
  localparam int unsigned W_MASK     = 16;
  localparam int unsigned W_ADDR     = 48;
  localparam int unsigned W_VECVALID = 1;
  localparam int unsigned PAYLOAD_W  = W_VADDR + W_DATA + W_MASK + W_ADDR + W_VECVALID;

  localparam int unsigned O_VECVALID = 0;
  localparam int unsigned O_ADDR     = O_VECVALID + W_VECVALID;
  localparam int unsigned O_MASK     = O_ADDR     + W_ADDR;
  localparam int unsigned O_DATA     = O_MASK     + W_MASK;
  localparam int unsigned O_VADDR    = O_DATA     + W_DATA;

  // 位宽自检（elaborate/time 0）：端口位宽必须与上面的布局一致。
  // 这一轮反复出事的形态是「逻辑全对、只有某个字段位宽停在旧值」——随机激励未必
  // 打得到高位，UT 照样 errors=0，要等 FM 才炸。这里让它在 time 0 就炸。
  initial begin
    if ($bits(io_in_bits_vaddr) != W_VADDR)
      $fatal(1, "NewPipelineConnectPipe_33: vaddr %0d 位 != 布局的 %0d",
             $bits(io_in_bits_vaddr), W_VADDR);
    if ($bits(io_in_bits_data) != W_DATA)
      $fatal(1, "NewPipelineConnectPipe_33: data %0d 位 != 布局的 %0d",
             $bits(io_in_bits_data), W_DATA);
    if ($bits(io_in_bits_mask) != W_MASK)
      $fatal(1, "NewPipelineConnectPipe_33: mask %0d 位 != 布局的 %0d",
             $bits(io_in_bits_mask), W_MASK);
    if ($bits(io_in_bits_addr) != W_ADDR)
      $fatal(1, "NewPipelineConnectPipe_33: addr %0d 位 != 布局的 %0d",
             $bits(io_in_bits_addr), W_ADDR);
    if ($bits({io_in_bits_vaddr, io_in_bits_data, io_in_bits_mask,
               io_in_bits_addr, io_in_bits_vecValid}) != PAYLOAD_W)
      $fatal(1, "NewPipelineConnectPipe_33: 入口打包 %0d 位 != PAYLOAD_W %0d",
             $bits({io_in_bits_vaddr, io_in_bits_data, io_in_bits_mask,
                    io_in_bits_addr, io_in_bits_vecValid}), PAYLOAD_W);
  end

  wire [PAYLOAD_W-1:0] out_bus;
  assign io_out_bits_vaddr    = out_bus[O_VADDR    +: W_VADDR];
  assign io_out_bits_data     = out_bus[O_DATA     +: W_DATA];
  assign io_out_bits_mask     = out_bus[O_MASK     +: W_MASK];
  assign io_out_bits_addr     = out_bus[O_ADDR     +: W_ADDR];
  assign io_out_bits_vecValid = out_bus[O_VECVALID +: W_VECVALID];

  xs_PipelineConnect #(.DATA_WIDTH(PAYLOAD_W)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_vaddr, io_in_bits_data, io_in_bits_mask, io_in_bits_addr, io_in_bits_vecValid}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(1'b0)
  );
endmodule
