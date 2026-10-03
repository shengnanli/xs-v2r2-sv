// AddrAddModule —— 分支执行单元的下一取指地址生成器。
// taken 时把低 15 位分支立即数符号扩展后加到 51 位虚拟 PC；
// 未 taken 时按半字节地址单位把 nextPcOffset 左移一位再相加。
// 51 位加法自然截断，最终按虚拟地址最高位符号扩展到 64 位。

module xs_AddrAddModule_core (
  input  logic [50:0] pc_extend,
  input  logic        taken,
  input  logic [31:0] immediate,
  input  logic [4:0]  next_pc_offset,
  output logic [63:0] target
);
  logic [50:0] branch_offset;
  logic [50:0] sequential_offset;
  logic [50:0] target_vaddr;

  assign branch_offset = {{36{immediate[14]}}, immediate[14:0]};
  assign sequential_offset = {45'b0, next_pc_offset, 1'b0};
  assign target_vaddr = pc_extend + (taken ? branch_offset : sequential_offset);
  assign target = {{13{target_vaddr[50]}}, target_vaddr};
endmodule


module AddrAddModule (
  input  logic [50:0] io_pcExtend,
  input  logic        io_taken,
  input  logic [31:0] io_imm,
  output logic [63:0] io_target,
  input  logic [4:0]  io_nextPcOffset
);
  xs_AddrAddModule_core u_core (
    .pc_extend     (io_pcExtend),
    .taken         (io_taken),
    .immediate     (io_imm),
    .next_pc_offset(io_nextPcOffset),
    .target        (io_target)
  );
endmodule
