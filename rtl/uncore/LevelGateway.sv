// =============================================================================
//  LevelGateway —— PLIC 电平型中断网关 (可读重写核 xs_LevelGateway_core)
// -----------------------------------------------------------------------------
//  功能 (源自 rocket-chip devices/tilelink/Plic.scala，class LevelGateway)：
//    PLIC 为每个外设中断源例化一个 LevelGateway，把"电平有效"的外设中断转成对
//    PLIC 核心的一次性挂起请求，并用 inFlight 锁存防止同一中断在被 claim 后、
//    complete 之前重复挂起 (避免一个电平中断被反复计入)。
//
//  行为：
//    inFlight 置位：interrupt & plic_ready (PLIC 接受了这次挂起)
//    inFlight 清零：plic_complete           (软件完成处理，complete 优先)
//    plic_valid  ：interrupt & ~inFlight     (尚未在途时才对 PLIC 报挂起)
//
//  golden 把两个 when 合并为一条 (complete 清零优先于 set)：
//    inFlight <= ~complete & (interrupt & ready | inFlight)
//  本核保持同一布尔式，语义、复位值、异步复位时序逐一对应。
//
//  本核为单寄存器叶子，无子模块、无 SRAM。
// =============================================================================
module xs_LevelGateway_core (
  input  logic clock,
  input  logic reset,

  input  logic io_interrupt,      // 外设电平中断输入
  output logic io_plic_valid,     // 向 PLIC 报挂起
  input  logic io_plic_ready,     // PLIC 接受挂起 (gateway 端口固定为可挂起)
  input  logic io_plic_complete   // 软件完成处理，释放在途标志
);

  // 在途标志：本中断已被 PLIC 接受、等待软件 complete
  logic inFlight;

  // complete 优先清零；否则 (本拍被接受 或 已在途) 保持/置位在途
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      inFlight <= 1'b0;
    else
      inFlight <= ~io_plic_complete & ((io_interrupt & io_plic_ready) | inFlight);
  end

  // 未在途时才对 PLIC 报挂起
  assign io_plic_valid = io_interrupt & ~inFlight;

endmodule
