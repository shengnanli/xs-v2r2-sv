// =============================================================================
// xs_ftb_pkg —— FTB（Fetch Target Buffer，取指目标缓冲）共享类型与编解码
//
// 对应 Chisel: xiangshan.frontend.FtbSlot / FTBEntry（FTB.scala）
// 供 FTBEntryGen / FTB / FTBBank / FTQ 复用。
//
// 【FTB 条目的核心思想】
// 一个 FTB 条目描述「一个取指块（fetch block，最多 PredictWidth=16 条指令）里的
// 控制流指令（CFI）及其跳转目标」。一个块最多记录 numBr=2 个分支：
//   - brSlots[0]：第 1 个条件分支（offset 在块内的位置）
//   - tailSlot  ：块尾的跳转/最后一个分支（可被「共享」为第 2 个条件分支）
// 外加：pftAddr/carry（fall-through 地址，即顺序执行落到的下一块起点）、
// isCall/isRet/isJalr、strong_bias（强偏置，预测置信度）等。
//
// 【目标地址的压缩存储】slot 不存完整 50-bit 目标，只存：
//   - lower：目标地址的低 offsetLen 位（br=12b，tail=20b）
//   - tarStat：目标高位相对「当前 PC 高位」的状态（FIT 相等 / OVF 高位+1 / UDF 高位-1）
// 取出时由 getTarget(pc) 用 PC 的高位 ± tarStat 重建完整目标，省存储。
// =============================================================================
package xs_ftb_pkg;

  localparam int unsigned VADDR_BITS    = 50;
  localparam int unsigned INST_OFF_BITS = 1;          // 指令地址对齐位（RVC 2 字节 → 1）
  localparam int unsigned PREDICT_WIDTH = 16;
  localparam int unsigned LOG2_PW       = 4;          // log2(PredictWidth)
  localparam int unsigned CARRY_POS     = LOG2_PW + INST_OFF_BITS;  // =5
  localparam int unsigned BR_OFF_LEN    = 12;         // brSlot 目标低位宽
  localparam int unsigned JMP_OFF_LEN   = 20;         // tailSlot 目标低位宽
  localparam int unsigned OFFSET_W      = LOG2_PW;    // 块内 offset 位宽 =4

  // 目标高位状态（target_higher 相对 pc_higher）
  localparam logic [1:0] TAR_FIT = 2'd0;  // 相等
  localparam logic [1:0] TAR_OVF = 2'd1;  // 高位 +1（目标在更高块）
  localparam logic [1:0] TAR_UDF = 2'd2;  // 高位 -1（目标在更低块）

  // ---- slot：一个 CFI 的位置与（压缩的）目标 ----
  // lower 用最大宽度 JMP_OFF_LEN 存放；br slot 只用低 BR_OFF_LEN 位（高位 0）。
  typedef struct packed {
    logic [OFFSET_W-1:0]    offset;   // CFI 在块内的指令 offset
    logic                   sharing;  // tailSlot 是否被「共享」作条件分支
    logic                   valid;
    logic [JMP_OFF_LEN-1:0] lower;    // 目标低位（br 仅低 12 位有效）
    logic [1:0]             tarStat;  // 目标高位状态
  } ftb_slot_t;

  typedef struct packed {
    logic                   valid;
    ftb_slot_t              brSlot;   // numBrSlot=1：第 1 个条件分支
    ftb_slot_t              tailSlot; // 块尾跳转 / 可共享的第 2 分支
    logic [OFFSET_W-1:0]    pftAddr;  // fall-through 地址低位
    logic                   carry;    // fall-through 进位
    logic                   isCall;
    logic                   isRet;
    logic                   isJalr;
    logic                   last_may_be_rvi_call;
    logic [1:0]             strong_bias;  // [0]=br0, [1]=tail
  } ftb_entry_t;

  // 「有效低位宽」：共享 slot 按 br 低位宽，否则按本 slot 低位宽
  function automatic int unsigned eff_len(input bit is_share, input int unsigned off_len);
    return is_share ? BR_OFF_LEN : off_len;
  endfunction

  // 由目标地址反算 tarStat（目标高位相对 PC 高位）
  function automatic logic [1:0] calc_tarstat(
      input logic [VADDR_BITS-1:0] pc, input logic [VADDR_BITS-1:0] target, input int unsigned eff);
    logic [VADDR_BITS-1:0] pc_hi  = pc     >> (eff + 1);
    logic [VADDR_BITS-1:0] tgt_hi = target >> (eff + 1);
    return (tgt_hi > pc_hi) ? TAR_OVF : (tgt_hi < pc_hi) ? TAR_UDF : TAR_FIT;
  endfunction

  // 由目标地址取低位 target[eff:1]，零扩展到 lower 宽
  function automatic logic [JMP_OFF_LEN-1:0] calc_lower(
      input logic [VADDR_BITS-1:0] target, input int unsigned eff);
    return (target >> 1) & ((1 << eff) - 1);
  endfunction

  // 由 (pc, lower, tarStat) 重建完整目标地址；off_len 同上
  function automatic logic [VADDR_BITS-1:0] get_target(
      input logic [VADDR_BITS-1:0] pc,
      input logic [JMP_OFF_LEN-1:0] lower,
      input logic [1:0]            tarStat,
      input int unsigned           off_len
  );
    logic [VADDR_BITS-1:0] h = pc >> (off_len + 1);   // PC 高位
    logic [VADDR_BITS-1:0] higher;
    // 与 Chisel Mux1H 一致：三项 one-hot 选择，tarStat 为非法值(如 2'b11)时全不选 → higher=0
    higher = ({VADDR_BITS{tarStat == TAR_OVF}} & (h + 1))
           | ({VADDR_BITS{tarStat == TAR_UDF}} & (h - 1))
           | ({VADDR_BITS{tarStat == TAR_FIT}} & h);
    // {higher, lower[off_len-1:0], 1'b0}
    return (higher << (off_len + 1)) | ((lower & ((1 << off_len) - 1)) << 1);
  endfunction

endpackage
