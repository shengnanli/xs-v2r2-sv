// =============================================================================
// sctable_pkg.sv —— SCTable 家族（SCTable / _1 / _2 / _3）共用的包
//
// 核 xs_SCTable_core（rtl/frontend/SCTable.sv）与四个变体 wrapper 共用：计数器/行号/bank 参数、
// MBIST 测试口与 SRAM 广播控制位的打包结构体、6 位有符号饱和 ±1 函数。
// 独立成文件而不并进 frontend_common_pkg.sv：只被这一个家族使用，并进公共包会让无关的已签目标
// 因闭包字节变化而 STALE（CONVENTIONS「独立包文件」例外，先例 alu_pkg.sv）。
// =============================================================================
package sctable_pkg;

  localparam int unsigned CTR_W   = 6;     // SC 计数器位宽（有符号）
  localparam int unsigned IDX_W   = 8;     // 行号位宽：256 行
  localparam int unsigned SET_W   = 7;     // bank 内 set 号：128 set
  localparam int unsigned NUM_BR  = 2;     // 每个取指块的分支槽数
  localparam int unsigned NUM_BANK = 2;

  // MBIST 流水送到一个 SRAM 的测试口（MbistPipeSc_N.toSRAM_k_* 方向）
  typedef struct packed {
    logic [7:0]  addr;
    logic [7:0]  addr_rd;
    logic [23:0] wdata;
    logic [3:0]  wmask;
    logic        re;
    logic        we;
    logic        ack;
    logic        selectedOH;
    logic [6:0]  array;
  } sc_mbist_req_t;

  // SRAM 宏的广播控制位（sigFromSrams_bore_*）
  typedef struct packed {
    logic ram_hold;
    logic ram_bypass;
    logic ram_bp_clken;
    logic ram_aux_clk;
    logic ram_aux_ckbp;
    logic ram_mcp_hold;
    logic cgen;
  } sc_sram_bcast_t;

  // 6 位有符号饱和计数器 ±1（BPU.scala signedSatUpdate）：
  // 已在 +31 且跳 -> 停在 +31；已在 -32 且不跳 -> 停在 -32；否则跳 +1 / 不跳 -1。
  function automatic logic [CTR_W-1:0] sat_update(input logic [CTR_W-1:0] old, input logic taken);
    if (old == 6'h1F && taken)       return 6'h1F;
    else if (old == 6'h20 && !taken) return 6'h20;
    else if (taken)                  return old + 6'd1;
    else                             return old - 6'd1;
  endfunction

endpackage
