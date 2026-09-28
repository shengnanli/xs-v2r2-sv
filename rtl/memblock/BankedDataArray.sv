// =============================================================================
// BankedDataArray —— DCache 数据阵列（8 bank × 4 路 × 256 组 × 72 位 {SECDED 8 位, 数据 64 位}）
//
// 对应 Chisel：xiangshan.cache.BankedDataArray（src/main/scala/xiangshan/cache/dcache/data/BankedDataArray.scala）
//
// 【组织】一行 64B 按 8B 切成 8 个 bank（bank 号 = 地址 [5:3]），每个 bank 是一个 DataSRAMBank
//   （4 路各一个单口 SRAM）。本配置 DCacheSetDiv = 1，所以 Chisel 里所有"div"比较恒成立，firtool 已删。
// 【三类访问】
//   · load 读（io.read × 3，LoadPipe s1 发）：每个口按 bankMask 只读 1 个 bank（128 位向量 load 读相邻 2 个）；
//     下一拍 bank 数据出来，按打一拍的 bank/路号选出 io.read_resp；再下一拍出 ECC 检错结果 read_error_delayed。
//   · 整行读（io.readline，MainPipe 发，用于写回/替换/probe）：8 个 bank 一起读，结果经 readline_can_go /
//     readline_stall / readline_can_resp 三级握手寄存后给 io.readline_resp，并对寄存后的结果做 ECC 检错。
//   · 写（io.write + io.write_dup × 8，MainPipe 发）：写数据先打一拍（同时算 SECDED），第二拍写进 bank；
//     地址与路使能走 8 份复制的 write_dup（每 bank 一份，减扇出）。
// 【冲突】
//   · 读-读：两个 load 口访问同一 bank 的不同 set（单口 SRAM 一拍只能读一个 set）→ 按 lqIdx 选最老的放行，
//     其余口本拍的读作废，下一拍报 bank_conflict_slow 让 LoadUnit 重发。
//   · 读-写：上一拍有写、写的 bank 与本拍 load 读的 bank 重叠 → 该 load 口 ready=0（写优先）。
//   · 读-整行读：整行读占全部 bank，同拍所有 load 读都算冲突（readline 优先）。
// 【伪错误注入】CtrlUnit 的数据通道（io.pseudo_error，每 bank 一个 64 位翻转掩码）直接异或进读出的数据
//   （ECC 位不动 → ECC 必报错）；MBIST 正在访问该 SRAM 时不翻。pseudo_error.ready = 打一拍的"真的读到了
//   被注入的 bank"。
// 【MBIST】MbistPipeDCacheData 把 32 个 SRAM（8 bank × 4 路）挂在一条 MBIST 总线上；MBIST 回读数据借用
//   整行读的输出寄存器（readline_resp），所以 MBIST ack 时整行读那几级寄存器也要跟着走。
// 【复位】只有 8 份 wen_reg_REG（写使能打拍，RegNext(_, false.B)）异步复位；其余寄存器都不复位，照搬 golden。
//
// 下方 GENERATED 区（端口表、8 个 DataSRAMBank_* 与 MbistPipeDCacheData 的例化和 MBIST 穿线）由
// scripts/gen_bankeddataarray.py 从 golden 机械生成；手写区是全部功能逻辑。
// =============================================================================
// 本文件导航（共 2272 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L25    组织】一行 64B 按 8B 切成 8 个 bank
//   L27    三类访问
//   L39    伪错误注入】CtrlUnit 的数据通道
//   L42    MBIST】MbistPipeDCacheData 把 32 个 SRAM
//   L44    复位】只有 8 份 wen_reg_REG
//   L542   §1 load 读口地址：bank 号
//   L559   §2 冲突判定
//   L561   写数据打一拍
//   L648   §3 每个 bank 的读使能与读地址
//   L650   bank b 被 load 口 i 读 = 口有效、访问的
//   L679   §4 bank 读结果：注入伪错误、ECC 延迟一拍检错
//   L709   §5 load 读响应：按打一拍的 bank/路号选数据，打两拍的选 ECC 结果
//   L746   §6 整行读：路号打一拍 → 8 个 bank 选同一路 → can_go / stall / can_resp 三级寄存 → 
//   L748   MBIST ack 时这条通路被 MBIST 借用：路号取 MBIST 正在读的那一路，各级寄存无条件前进
//   L806   §7 伪错误注入"已生效"：真的读到了被注入的 bank
//   L826   §8 写：第一拍锁存数据并算 SECDED，第二拍写进 bank
//   L865   §9 仿真检查寄存器：assert(!(RegNext(read.fire && PopCount(way_en) > 1)))
//

package bankeddataarray_pkg;

  localparam int N_BANKS = 8;    // DCacheBanks
  localparam int N_WAYS  = 4;
  localparam int N_PORTS = 3;    // LoadPipelineWidth
  localparam int ROW_W   = 64;   // DCacheSRAMRowBits
  localparam int ECC_W   = 8;
  localparam int ENC_W   = ROW_W + ECC_W;
  localparam int SET_W   = 8;

  typedef struct packed {
    logic       flag;
    logic [6:0] value;
  } lq_ptr_t;

  // SECDED(72,64)：校验位 k（k = 0..6）覆盖数据中 H[k] 置 1 的位；第 7 位是整体奇偶
  localparam logic [ROW_W-1:0] H [7] = '{
    64'hAB55555556AAAD5B, 64'hCD9999999B33366D, 64'hF1E1E1E1E3C3C78E, 64'h01FE01FE03FC07F0,
    64'h01FFFE0003FFF800, 64'h01FFFFFFFC000000, 64'hFE00000000000000};

  function automatic logic [ECC_W-1:0] data_ecc_encode(input logic [ROW_W-1:0] data);
    logic [6:0] p;
    for (int k = 0; k < 7; k++)
      p[k] = ^(data & H[k]);
    data_ecc_encode = {^{p, data}, p};
  endfunction

  // 检错：整体奇偶为 1（单比特错）或校验子非 0（双比特错）即报错
  function automatic logic data_ecc_error(input logic [ENC_W-1:0] enc);
    logic [6:0] syndrome;
    for (int k = 0; k < 7; k++)
      syndrome[k] = enc[ROW_W+k] ^ ^(enc[ROW_W-1:0] & H[k]);
    data_ecc_error = (^enc) | (|syndrome);
  endfunction

  function automatic logic [1:0] oh_to_way(input logic [N_WAYS-1:0] oh);
    oh_to_way = {oh[3] | oh[2], oh[3] | oh[1]};
  endfunction

  function automatic logic [2:0] popcount4(input logic [3:0] v);
    popcount4 = 3'(v[0]) + 3'(v[1]) + 3'(v[2]) + 3'(v[3]);
  endfunction

  // LqPtr "a 比 b 年轻"（a > b）：flag 不同则 value 比较结果取反
  function automatic logic lq_younger(input lq_ptr_t a, input lq_ptr_t b);
    lq_younger = a.flag ^ b.flag ^ (a.value > b.value);
  endfunction

endpackage

// BEGIN GENERATED(bda_ports)
// 由 scripts/gen_bankeddataarray.py 从 golden 生成 —— 勿手改
module BankedDataArray
  import bankeddataarray_pkg::*;
(
  input         clock,
  input         reset,
  output        io_read_0_ready,
  input         io_read_0_valid,
  input  [3:0]  io_read_0_bits_way_en,
  input  [47:0] io_read_0_bits_addr,
  input  [47:0] io_read_0_bits_addr_dup,
  input  [7:0]  io_read_0_bits_bankMask,
  input         io_read_0_bits_lqIdx_flag,
  input  [6:0]  io_read_0_bits_lqIdx_value,
  output        io_read_1_ready,
  input         io_read_1_valid,
  input  [3:0]  io_read_1_bits_way_en,
  input  [47:0] io_read_1_bits_addr,
  input  [47:0] io_read_1_bits_addr_dup,
  input  [7:0]  io_read_1_bits_bankMask,
  input         io_read_1_bits_lqIdx_flag,
  input  [6:0]  io_read_1_bits_lqIdx_value,
  output        io_read_2_ready,
  input         io_read_2_valid,
  input  [3:0]  io_read_2_bits_way_en,
  input  [47:0] io_read_2_bits_addr,
  input  [47:0] io_read_2_bits_addr_dup,
  input  [7:0]  io_read_2_bits_bankMask,
  input         io_read_2_bits_lqIdx_flag,
  input  [6:0]  io_read_2_bits_lqIdx_value,
  input         io_is128Req_0,
  input         io_is128Req_1,
  input         io_is128Req_2,
  input         io_readline_intend,
  output        io_readline_ready,
  input         io_readline_valid,
  input  [3:0]  io_readline_bits_way_en,
  input  [47:0] io_readline_bits_addr,
  input  [7:0]  io_readline_bits_rmask,
  input         io_readline_can_go,
  input         io_readline_stall,
  input         io_readline_can_resp,
  input         io_write_valid,
  input  [7:0]  io_write_bits_wmask,
  input  [63:0] io_write_bits_data_0,
  input  [63:0] io_write_bits_data_1,
  input  [63:0] io_write_bits_data_2,
  input  [63:0] io_write_bits_data_3,
  input  [63:0] io_write_bits_data_4,
  input  [63:0] io_write_bits_data_5,
  input  [63:0] io_write_bits_data_6,
  input  [63:0] io_write_bits_data_7,
  input         io_write_dup_0_valid,
  input  [3:0]  io_write_dup_0_bits_way_en,
  input  [47:0] io_write_dup_0_bits_addr,
  input         io_write_dup_1_valid,
  input  [3:0]  io_write_dup_1_bits_way_en,
  input  [47:0] io_write_dup_1_bits_addr,
  input         io_write_dup_2_valid,
  input  [3:0]  io_write_dup_2_bits_way_en,
  input  [47:0] io_write_dup_2_bits_addr,
  input         io_write_dup_3_valid,
  input  [3:0]  io_write_dup_3_bits_way_en,
  input  [47:0] io_write_dup_3_bits_addr,
  input         io_write_dup_4_valid,
  input  [3:0]  io_write_dup_4_bits_way_en,
  input  [47:0] io_write_dup_4_bits_addr,
  input         io_write_dup_5_valid,
  input  [3:0]  io_write_dup_5_bits_way_en,
  input  [47:0] io_write_dup_5_bits_addr,
  input         io_write_dup_6_valid,
  input  [3:0]  io_write_dup_6_bits_way_en,
  input  [47:0] io_write_dup_6_bits_addr,
  input         io_write_dup_7_valid,
  input  [3:0]  io_write_dup_7_bits_way_en,
  input  [47:0] io_write_dup_7_bits_addr,
  output [63:0] io_readline_resp_0_raw_data,
  output [63:0] io_readline_resp_1_raw_data,
  output [63:0] io_readline_resp_2_raw_data,
  output [63:0] io_readline_resp_3_raw_data,
  output [63:0] io_readline_resp_4_raw_data,
  output [63:0] io_readline_resp_5_raw_data,
  output [63:0] io_readline_resp_6_raw_data,
  output [63:0] io_readline_resp_7_raw_data,
  output        io_readline_error_delayed,
  output [63:0] io_read_resp_0_0_raw_data,
  output [63:0] io_read_resp_0_1_raw_data,
  output [63:0] io_read_resp_1_0_raw_data,
  output [63:0] io_read_resp_1_1_raw_data,
  output [63:0] io_read_resp_2_0_raw_data,
  output [63:0] io_read_resp_2_1_raw_data,
  output        io_read_error_delayed_0_0,
  output        io_read_error_delayed_0_1,
  output        io_read_error_delayed_1_0,
  output        io_read_error_delayed_1_1,
  output        io_read_error_delayed_2_0,
  output        io_read_error_delayed_2_1,
  output        io_bank_conflict_slow_0,
  output        io_bank_conflict_slow_1,
  output        io_bank_conflict_slow_2,
  output        io_disable_ld_fast_wakeup_0,
  output        io_disable_ld_fast_wakeup_1,
  output        io_disable_ld_fast_wakeup_2,
  output        io_pseudo_error_ready,
  input         io_pseudo_error_valid,
  input         io_pseudo_error_bits_0_valid,
  input  [63:0] io_pseudo_error_bits_0_mask,
  input         io_pseudo_error_bits_1_valid,
  input  [63:0] io_pseudo_error_bits_1_mask,
  input         io_pseudo_error_bits_2_valid,
  input  [63:0] io_pseudo_error_bits_2_mask,
  input         io_pseudo_error_bits_3_valid,
  input  [63:0] io_pseudo_error_bits_3_mask,
  input         io_pseudo_error_bits_4_valid,
  input  [63:0] io_pseudo_error_bits_4_mask,
  input         io_pseudo_error_bits_5_valid,
  input  [63:0] io_pseudo_error_bits_5_mask,
  input         io_pseudo_error_bits_6_valid,
  input  [63:0] io_pseudo_error_bits_6_mask,
  input         io_pseudo_error_bits_7_valid,
  input  [63:0] io_pseudo_error_bits_7_mask,
  input  [4:0]  boreChildrenBd_bore_array,
  input         boreChildrenBd_bore_all,
  input         boreChildrenBd_bore_req,
  output        boreChildrenBd_bore_ack,
  input         boreChildrenBd_bore_writeen,
  input         boreChildrenBd_bore_be,
  input  [8:0]  boreChildrenBd_bore_addr,
  input  [71:0] boreChildrenBd_bore_indata,
  input         boreChildrenBd_bore_readen,
  input  [8:0]  boreChildrenBd_bore_addr_rd,
  output [71:0] boreChildrenBd_bore_outdata,
  input         sigFromSrams_bore_ram_hold,
  input         sigFromSrams_bore_ram_bypass,
  input         sigFromSrams_bore_ram_bp_clken,
  input         sigFromSrams_bore_ram_aux_clk,
  input         sigFromSrams_bore_ram_aux_ckbp,
  input         sigFromSrams_bore_ram_mcp_hold,
  input         sigFromSrams_bore_cgen,
  input         sigFromSrams_bore_1_ram_hold,
  input         sigFromSrams_bore_1_ram_bypass,
  input         sigFromSrams_bore_1_ram_bp_clken,
  input         sigFromSrams_bore_1_ram_aux_clk,
  input         sigFromSrams_bore_1_ram_aux_ckbp,
  input         sigFromSrams_bore_1_ram_mcp_hold,
  input         sigFromSrams_bore_1_cgen,
  input         sigFromSrams_bore_2_ram_hold,
  input         sigFromSrams_bore_2_ram_bypass,
  input         sigFromSrams_bore_2_ram_bp_clken,
  input         sigFromSrams_bore_2_ram_aux_clk,
  input         sigFromSrams_bore_2_ram_aux_ckbp,
  input         sigFromSrams_bore_2_ram_mcp_hold,
  input         sigFromSrams_bore_2_cgen,
  input         sigFromSrams_bore_3_ram_hold,
  input         sigFromSrams_bore_3_ram_bypass,
  input         sigFromSrams_bore_3_ram_bp_clken,
  input         sigFromSrams_bore_3_ram_aux_clk,
  input         sigFromSrams_bore_3_ram_aux_ckbp,
  input         sigFromSrams_bore_3_ram_mcp_hold,
  input         sigFromSrams_bore_3_cgen,
  input         sigFromSrams_bore_4_ram_hold,
  input         sigFromSrams_bore_4_ram_bypass,
  input         sigFromSrams_bore_4_ram_bp_clken,
  input         sigFromSrams_bore_4_ram_aux_clk,
  input         sigFromSrams_bore_4_ram_aux_ckbp,
  input         sigFromSrams_bore_4_ram_mcp_hold,
  input         sigFromSrams_bore_4_cgen,
  input         sigFromSrams_bore_5_ram_hold,
  input         sigFromSrams_bore_5_ram_bypass,
  input         sigFromSrams_bore_5_ram_bp_clken,
  input         sigFromSrams_bore_5_ram_aux_clk,
  input         sigFromSrams_bore_5_ram_aux_ckbp,
  input         sigFromSrams_bore_5_ram_mcp_hold,
  input         sigFromSrams_bore_5_cgen,
  input         sigFromSrams_bore_6_ram_hold,
  input         sigFromSrams_bore_6_ram_bypass,
  input         sigFromSrams_bore_6_ram_bp_clken,
  input         sigFromSrams_bore_6_ram_aux_clk,
  input         sigFromSrams_bore_6_ram_aux_ckbp,
  input         sigFromSrams_bore_6_ram_mcp_hold,
  input         sigFromSrams_bore_6_cgen,
  input         sigFromSrams_bore_7_ram_hold,
  input         sigFromSrams_bore_7_ram_bypass,
  input         sigFromSrams_bore_7_ram_bp_clken,
  input         sigFromSrams_bore_7_ram_aux_clk,
  input         sigFromSrams_bore_7_ram_aux_ckbp,
  input         sigFromSrams_bore_7_ram_mcp_hold,
  input         sigFromSrams_bore_7_cgen,
  input         sigFromSrams_bore_8_ram_hold,
  input         sigFromSrams_bore_8_ram_bypass,
  input         sigFromSrams_bore_8_ram_bp_clken,
  input         sigFromSrams_bore_8_ram_aux_clk,
  input         sigFromSrams_bore_8_ram_aux_ckbp,
  input         sigFromSrams_bore_8_ram_mcp_hold,
  input         sigFromSrams_bore_8_cgen,
  input         sigFromSrams_bore_9_ram_hold,
  input         sigFromSrams_bore_9_ram_bypass,
  input         sigFromSrams_bore_9_ram_bp_clken,
  input         sigFromSrams_bore_9_ram_aux_clk,
  input         sigFromSrams_bore_9_ram_aux_ckbp,
  input         sigFromSrams_bore_9_ram_mcp_hold,
  input         sigFromSrams_bore_9_cgen,
  input         sigFromSrams_bore_10_ram_hold,
  input         sigFromSrams_bore_10_ram_bypass,
  input         sigFromSrams_bore_10_ram_bp_clken,
  input         sigFromSrams_bore_10_ram_aux_clk,
  input         sigFromSrams_bore_10_ram_aux_ckbp,
  input         sigFromSrams_bore_10_ram_mcp_hold,
  input         sigFromSrams_bore_10_cgen,
  input         sigFromSrams_bore_11_ram_hold,
  input         sigFromSrams_bore_11_ram_bypass,
  input         sigFromSrams_bore_11_ram_bp_clken,
  input         sigFromSrams_bore_11_ram_aux_clk,
  input         sigFromSrams_bore_11_ram_aux_ckbp,
  input         sigFromSrams_bore_11_ram_mcp_hold,
  input         sigFromSrams_bore_11_cgen,
  input         sigFromSrams_bore_12_ram_hold,
  input         sigFromSrams_bore_12_ram_bypass,
  input         sigFromSrams_bore_12_ram_bp_clken,
  input         sigFromSrams_bore_12_ram_aux_clk,
  input         sigFromSrams_bore_12_ram_aux_ckbp,
  input         sigFromSrams_bore_12_ram_mcp_hold,
  input         sigFromSrams_bore_12_cgen,
  input         sigFromSrams_bore_13_ram_hold,
  input         sigFromSrams_bore_13_ram_bypass,
  input         sigFromSrams_bore_13_ram_bp_clken,
  input         sigFromSrams_bore_13_ram_aux_clk,
  input         sigFromSrams_bore_13_ram_aux_ckbp,
  input         sigFromSrams_bore_13_ram_mcp_hold,
  input         sigFromSrams_bore_13_cgen,
  input         sigFromSrams_bore_14_ram_hold,
  input         sigFromSrams_bore_14_ram_bypass,
  input         sigFromSrams_bore_14_ram_bp_clken,
  input         sigFromSrams_bore_14_ram_aux_clk,
  input         sigFromSrams_bore_14_ram_aux_ckbp,
  input         sigFromSrams_bore_14_ram_mcp_hold,
  input         sigFromSrams_bore_14_cgen,
  input         sigFromSrams_bore_15_ram_hold,
  input         sigFromSrams_bore_15_ram_bypass,
  input         sigFromSrams_bore_15_ram_bp_clken,
  input         sigFromSrams_bore_15_ram_aux_clk,
  input         sigFromSrams_bore_15_ram_aux_ckbp,
  input         sigFromSrams_bore_15_ram_mcp_hold,
  input         sigFromSrams_bore_15_cgen,
  input         sigFromSrams_bore_16_ram_hold,
  input         sigFromSrams_bore_16_ram_bypass,
  input         sigFromSrams_bore_16_ram_bp_clken,
  input         sigFromSrams_bore_16_ram_aux_clk,
  input         sigFromSrams_bore_16_ram_aux_ckbp,
  input         sigFromSrams_bore_16_ram_mcp_hold,
  input         sigFromSrams_bore_16_cgen,
  input         sigFromSrams_bore_17_ram_hold,
  input         sigFromSrams_bore_17_ram_bypass,
  input         sigFromSrams_bore_17_ram_bp_clken,
  input         sigFromSrams_bore_17_ram_aux_clk,
  input         sigFromSrams_bore_17_ram_aux_ckbp,
  input         sigFromSrams_bore_17_ram_mcp_hold,
  input         sigFromSrams_bore_17_cgen,
  input         sigFromSrams_bore_18_ram_hold,
  input         sigFromSrams_bore_18_ram_bypass,
  input         sigFromSrams_bore_18_ram_bp_clken,
  input         sigFromSrams_bore_18_ram_aux_clk,
  input         sigFromSrams_bore_18_ram_aux_ckbp,
  input         sigFromSrams_bore_18_ram_mcp_hold,
  input         sigFromSrams_bore_18_cgen,
  input         sigFromSrams_bore_19_ram_hold,
  input         sigFromSrams_bore_19_ram_bypass,
  input         sigFromSrams_bore_19_ram_bp_clken,
  input         sigFromSrams_bore_19_ram_aux_clk,
  input         sigFromSrams_bore_19_ram_aux_ckbp,
  input         sigFromSrams_bore_19_ram_mcp_hold,
  input         sigFromSrams_bore_19_cgen,
  input         sigFromSrams_bore_20_ram_hold,
  input         sigFromSrams_bore_20_ram_bypass,
  input         sigFromSrams_bore_20_ram_bp_clken,
  input         sigFromSrams_bore_20_ram_aux_clk,
  input         sigFromSrams_bore_20_ram_aux_ckbp,
  input         sigFromSrams_bore_20_ram_mcp_hold,
  input         sigFromSrams_bore_20_cgen,
  input         sigFromSrams_bore_21_ram_hold,
  input         sigFromSrams_bore_21_ram_bypass,
  input         sigFromSrams_bore_21_ram_bp_clken,
  input         sigFromSrams_bore_21_ram_aux_clk,
  input         sigFromSrams_bore_21_ram_aux_ckbp,
  input         sigFromSrams_bore_21_ram_mcp_hold,
  input         sigFromSrams_bore_21_cgen,
  input         sigFromSrams_bore_22_ram_hold,
  input         sigFromSrams_bore_22_ram_bypass,
  input         sigFromSrams_bore_22_ram_bp_clken,
  input         sigFromSrams_bore_22_ram_aux_clk,
  input         sigFromSrams_bore_22_ram_aux_ckbp,
  input         sigFromSrams_bore_22_ram_mcp_hold,
  input         sigFromSrams_bore_22_cgen,
  input         sigFromSrams_bore_23_ram_hold,
  input         sigFromSrams_bore_23_ram_bypass,
  input         sigFromSrams_bore_23_ram_bp_clken,
  input         sigFromSrams_bore_23_ram_aux_clk,
  input         sigFromSrams_bore_23_ram_aux_ckbp,
  input         sigFromSrams_bore_23_ram_mcp_hold,
  input         sigFromSrams_bore_23_cgen,
  input         sigFromSrams_bore_24_ram_hold,
  input         sigFromSrams_bore_24_ram_bypass,
  input         sigFromSrams_bore_24_ram_bp_clken,
  input         sigFromSrams_bore_24_ram_aux_clk,
  input         sigFromSrams_bore_24_ram_aux_ckbp,
  input         sigFromSrams_bore_24_ram_mcp_hold,
  input         sigFromSrams_bore_24_cgen,
  input         sigFromSrams_bore_25_ram_hold,
  input         sigFromSrams_bore_25_ram_bypass,
  input         sigFromSrams_bore_25_ram_bp_clken,
  input         sigFromSrams_bore_25_ram_aux_clk,
  input         sigFromSrams_bore_25_ram_aux_ckbp,
  input         sigFromSrams_bore_25_ram_mcp_hold,
  input         sigFromSrams_bore_25_cgen,
  input         sigFromSrams_bore_26_ram_hold,
  input         sigFromSrams_bore_26_ram_bypass,
  input         sigFromSrams_bore_26_ram_bp_clken,
  input         sigFromSrams_bore_26_ram_aux_clk,
  input         sigFromSrams_bore_26_ram_aux_ckbp,
  input         sigFromSrams_bore_26_ram_mcp_hold,
  input         sigFromSrams_bore_26_cgen,
  input         sigFromSrams_bore_27_ram_hold,
  input         sigFromSrams_bore_27_ram_bypass,
  input         sigFromSrams_bore_27_ram_bp_clken,
  input         sigFromSrams_bore_27_ram_aux_clk,
  input         sigFromSrams_bore_27_ram_aux_ckbp,
  input         sigFromSrams_bore_27_ram_mcp_hold,
  input         sigFromSrams_bore_27_cgen,
  input         sigFromSrams_bore_28_ram_hold,
  input         sigFromSrams_bore_28_ram_bypass,
  input         sigFromSrams_bore_28_ram_bp_clken,
  input         sigFromSrams_bore_28_ram_aux_clk,
  input         sigFromSrams_bore_28_ram_aux_ckbp,
  input         sigFromSrams_bore_28_ram_mcp_hold,
  input         sigFromSrams_bore_28_cgen,
  input         sigFromSrams_bore_29_ram_hold,
  input         sigFromSrams_bore_29_ram_bypass,
  input         sigFromSrams_bore_29_ram_bp_clken,
  input         sigFromSrams_bore_29_ram_aux_clk,
  input         sigFromSrams_bore_29_ram_aux_ckbp,
  input         sigFromSrams_bore_29_ram_mcp_hold,
  input         sigFromSrams_bore_29_cgen,
  input         sigFromSrams_bore_30_ram_hold,
  input         sigFromSrams_bore_30_ram_bypass,
  input         sigFromSrams_bore_30_ram_bp_clken,
  input         sigFromSrams_bore_30_ram_aux_clk,
  input         sigFromSrams_bore_30_ram_aux_ckbp,
  input         sigFromSrams_bore_30_ram_mcp_hold,
  input         sigFromSrams_bore_30_cgen,
  input         sigFromSrams_bore_31_ram_hold,
  input         sigFromSrams_bore_31_ram_bypass,
  input         sigFromSrams_bore_31_ram_bp_clken,
  input         sigFromSrams_bore_31_ram_aux_clk,
  input         sigFromSrams_bore_31_ram_aux_ckbp,
  input         sigFromSrams_bore_31_ram_mcp_hold,
  input         sigFromSrams_bore_31_cgen
);
// END GENERATED

  // ---- 与 GENERATED 区（8 个 bank、MBIST 分发）之间的连线 ----
  logic               bank_r_en     [N_BANKS];
  logic [SET_W-1:0]   bank_r_addr   [N_BANKS];
  logic [ENC_W-1:0]   bank_r_data   [N_BANKS][N_WAYS];
  logic               bank_w_en     [N_BANKS];
  logic [SET_W-1:0]   bank_w_addr   [N_BANKS];
  logic [N_WAYS-1:0]  bank_w_way_en [N_BANKS];
  logic [ENC_W-1:0]   bank_w_data   [N_BANKS];
  logic               mbist_ack;                          // MBIST 正在进行
  logic               mbist_sram_ack [N_BANKS*N_WAYS];    // 第 4b+w 个 SRAM 被 MBIST 选中
  logic               mbist_sram_re  [N_BANKS*N_WAYS];    // 第 4b+w 个 SRAM 的 MBIST 读
  logic [ENC_W-1:0]   mbist_rdata    [N_BANKS];           // bank b 的 MBIST 回读 = 整行读输出寄存器

  // ---- 端口打包 ----
  logic              rd_valid     [N_PORTS];
  logic [3:0]        rd_way_en    [N_PORTS];
  logic [47:0]       rd_addr      [N_PORTS];
  logic [47:0]       rd_addr_dup  [N_PORTS];
  logic [7:0]        rd_bank_mask [N_PORTS];
  lq_ptr_t           rd_lq        [N_PORTS];
  logic              rd_is128     [N_PORTS];
  logic              rd_ready     [N_PORTS];
  logic [ROW_W-1:0]  rd_resp      [N_PORTS][2];
  logic              rd_error_delayed [N_PORTS][2];
  logic              bank_conflict_slow [N_PORTS];
  logic              disable_fast_wakeup [N_PORTS];
  logic [ROW_W-1:0]  wr_data      [N_BANKS];
  logic              wr_dup_valid [N_BANKS];
  logic [3:0]        wr_dup_way_en [N_BANKS];
  logic [47:0]       wr_dup_addr  [N_BANKS];
  logic              pe_bank_valid [N_BANKS];
  logic [ROW_W-1:0]  pe_bank_mask  [N_BANKS];

  assign rd_valid     = '{io_read_0_valid, io_read_1_valid, io_read_2_valid};
  assign rd_way_en    = '{io_read_0_bits_way_en, io_read_1_bits_way_en, io_read_2_bits_way_en};
  assign rd_addr      = '{io_read_0_bits_addr, io_read_1_bits_addr, io_read_2_bits_addr};
  assign rd_addr_dup  = '{io_read_0_bits_addr_dup, io_read_1_bits_addr_dup, io_read_2_bits_addr_dup};
  assign rd_bank_mask = '{io_read_0_bits_bankMask, io_read_1_bits_bankMask, io_read_2_bits_bankMask};
  assign rd_lq        = '{'{io_read_0_bits_lqIdx_flag, io_read_0_bits_lqIdx_value},
                          '{io_read_1_bits_lqIdx_flag, io_read_1_bits_lqIdx_value},
                          '{io_read_2_bits_lqIdx_flag, io_read_2_bits_lqIdx_value}};
  assign rd_is128     = '{io_is128Req_0, io_is128Req_1, io_is128Req_2};
  assign wr_data      = '{io_write_bits_data_0, io_write_bits_data_1, io_write_bits_data_2, io_write_bits_data_3,
                          io_write_bits_data_4, io_write_bits_data_5, io_write_bits_data_6, io_write_bits_data_7};
  assign wr_dup_valid = '{io_write_dup_0_valid, io_write_dup_1_valid, io_write_dup_2_valid, io_write_dup_3_valid,
                          io_write_dup_4_valid, io_write_dup_5_valid, io_write_dup_6_valid, io_write_dup_7_valid};
  assign wr_dup_way_en = '{io_write_dup_0_bits_way_en, io_write_dup_1_bits_way_en, io_write_dup_2_bits_way_en,
                           io_write_dup_3_bits_way_en, io_write_dup_4_bits_way_en, io_write_dup_5_bits_way_en,
                           io_write_dup_6_bits_way_en, io_write_dup_7_bits_way_en};
  assign wr_dup_addr  = '{io_write_dup_0_bits_addr, io_write_dup_1_bits_addr, io_write_dup_2_bits_addr,
                          io_write_dup_3_bits_addr, io_write_dup_4_bits_addr, io_write_dup_5_bits_addr,
                          io_write_dup_6_bits_addr, io_write_dup_7_bits_addr};
  assign pe_bank_valid = '{io_pseudo_error_bits_0_valid, io_pseudo_error_bits_1_valid, io_pseudo_error_bits_2_valid,
                           io_pseudo_error_bits_3_valid, io_pseudo_error_bits_4_valid, io_pseudo_error_bits_5_valid,
                           io_pseudo_error_bits_6_valid, io_pseudo_error_bits_7_valid};
  assign pe_bank_mask  = '{io_pseudo_error_bits_0_mask, io_pseudo_error_bits_1_mask, io_pseudo_error_bits_2_mask,
                           io_pseudo_error_bits_3_mask, io_pseudo_error_bits_4_mask, io_pseudo_error_bits_5_mask,
                           io_pseudo_error_bits_6_mask, io_pseudo_error_bits_7_mask};

  assign io_read_0_ready = rd_ready[0];
  assign io_read_1_ready = rd_ready[1];
  assign io_read_2_ready = rd_ready[2];
  assign io_read_resp_0_0_raw_data = rd_resp[0][0];
  assign io_read_resp_0_1_raw_data = rd_resp[0][1];
  assign io_read_resp_1_0_raw_data = rd_resp[1][0];
  assign io_read_resp_1_1_raw_data = rd_resp[1][1];
  assign io_read_resp_2_0_raw_data = rd_resp[2][0];
  assign io_read_resp_2_1_raw_data = rd_resp[2][1];
  assign io_read_error_delayed_0_0 = rd_error_delayed[0][0];
  assign io_read_error_delayed_0_1 = rd_error_delayed[0][1];
  assign io_read_error_delayed_1_0 = rd_error_delayed[1][0];
  assign io_read_error_delayed_1_1 = rd_error_delayed[1][1];
  assign io_read_error_delayed_2_0 = rd_error_delayed[2][0];
  assign io_read_error_delayed_2_1 = rd_error_delayed[2][1];
  assign io_bank_conflict_slow_0 = bank_conflict_slow[0];
  assign io_bank_conflict_slow_1 = bank_conflict_slow[1];
  assign io_bank_conflict_slow_2 = bank_conflict_slow[2];
  assign io_disable_ld_fast_wakeup_0 = disable_fast_wakeup[0];
  assign io_disable_ld_fast_wakeup_1 = disable_fast_wakeup[1];
  assign io_disable_ld_fast_wakeup_2 = disable_fast_wakeup[2];

  // ===========================================================================
  //  §1 load 读口地址：bank 号（第 2 个 bank 给 128 位 load 用）、set 下标
  // ===========================================================================
  logic [2:0]       bank_addr     [N_PORTS][2];   // [口][0]=本 bank，[1]=128 位时的下一个 bank
  logic [2:0]       bank_addr_dup [N_PORTS][2];   // 用 addr_dup 算的同一份（只驱动 bank 0..3 的读地址）
  logic [SET_W-1:0] set_addr      [N_PORTS];
  logic [SET_W-1:0] set_addr_dup  [N_PORTS];
  always_comb
    for (int i = 0; i < N_PORTS; i++) begin
      bank_addr[i][0]     = rd_addr[i][5:3];
      bank_addr[i][1]     = rd_is128[i] ? 3'(rd_addr[i][5:3] + 3'd1) : rd_addr[i][5:3];
      bank_addr_dup[i][0] = rd_addr_dup[i][5:3];
      bank_addr_dup[i][1] = rd_is128[i] ? 3'(rd_addr_dup[i][5:3] + 3'd1) : rd_addr_dup[i][5:3];
      set_addr[i]         = rd_addr[i][13:6];
      set_addr_dup[i]     = rd_addr_dup[i][13:6];
    end

  // ===========================================================================
  //  §2 冲突判定
  // ===========================================================================
  // 写数据打一拍（§8），这里只用它的"上一拍有写、写了哪些 bank"
  logic             write_valid_reg;
  logic [7:0]       write_bank_mask_reg;

  // 读-读：两口都有效、bank 掩码重叠、set 不同
  logic rr_bank_conflict [N_PORTS][N_PORTS];
  always_comb
    for (int x = 0; x < N_PORTS; x++)
      for (int y = 0; y < N_PORTS; y++)
        rr_bank_conflict[x][y] = (x != y) & rd_valid[x] & rd_valid[y] &
                                 (|(rd_bank_mask[x] & rd_bank_mask[y])) & (set_addr[x] != set_addr[y]);

  logic load_req_with_bank_conflict [N_PORTS];
  always_comb
    for (int i = 0; i < N_PORTS; i++) begin
      load_req_with_bank_conflict[i] = 1'b0;
      for (int y = 0; y < N_PORTS; y++)
        load_req_with_bank_conflict[i] |= rr_bank_conflict[i][y];
    end

  // 在"有读-读冲突"的口里选最老的（lqIdx 最小）放行。Chisel 用 ParallelOperation 两两归并：
  // 先比口 1 与口 2，再拿胜者与口 0 比；两边都有效时选老的（a 比 b 年轻就选 b），只有一边有效选它，
  // 都无效时取右边那个的下标（这个"兜底下标"也要照抄——它决定了哪个口不被判冲突）。
  typedef struct packed {
    logic       valid;
    lq_ptr_t    lq;
    logic [1:0] idx;
  } oldest_t;
  function automatic oldest_t pick_oldest(input oldest_t a, input oldest_t b);
    logic take_b;
    take_b = (a.valid & b.valid) ? lq_younger(a.lq, b.lq) : ~(a.valid & ~b.valid);
    pick_oldest       = take_b ? b : a;
    pick_oldest.valid = a.valid | b.valid;
  endfunction

  oldest_t cand [N_PORTS];
  oldest_t oldest_12, oldest_all;
  always_comb begin
    for (int i = 0; i < N_PORTS; i++)
      cand[i] = '{valid: load_req_with_bank_conflict[i], lq: rd_lq[i], idx: 2'(i)};
    oldest_12  = pick_oldest(cand[1], cand[2]);
    oldest_all = pick_oldest(cand[0], oldest_12);
  end

  // 有冲突且不是被选中的那个 → 本拍这个口的读作废
  logic rr_bank_conflict_oldest [N_PORTS];
  always_comb
    for (int i = 0; i < N_PORTS; i++)
      rr_bank_conflict_oldest[i] = (oldest_all.idx != 2'(i)) & load_req_with_bank_conflict[i];

  // 读-整行读、读-写
  logic rrl_bank_conflict        [N_PORTS];
  logic rrl_bank_conflict_intend [N_PORTS];
  logic wr_bank_conflict         [N_PORTS];
  logic read_fire                [N_PORTS];
  always_comb
    for (int i = 0; i < N_PORTS; i++) begin
      rrl_bank_conflict[i]        = rd_valid[i] & io_readline_valid;
      rrl_bank_conflict_intend[i] = rd_valid[i] & io_readline_intend;
      wr_bank_conflict[i]         = rd_valid[i] & write_valid_reg &
                                    (write_bank_mask_reg[bank_addr[i][0]] |
                                     write_bank_mask_reg[bank_addr[i][1]] & rd_is128[i]);
      rd_ready[i]                 = ~wr_bank_conflict[i];
      read_fire[i]                = rd_valid[i] & rd_ready[i];
    end
  wire readline_ready = ~(io_readline_valid & write_valid_reg);
  wire readline_fire  = io_readline_valid & readline_ready;
  assign io_readline_ready = readline_ready;

  // 冲突结果打一拍报给 LoadPipe（s2 用）
  logic real_other_bank_conflict_reg [N_PORTS];
  logic real_rr_bank_conflict_reg    [N_PORTS];
  always_ff @(posedge clock)
    for (int i = 0; i < N_PORTS; i++) begin
      real_other_bank_conflict_reg[i] <= wr_bank_conflict[i] | rrl_bank_conflict[i];
      real_rr_bank_conflict_reg[i]    <= rr_bank_conflict_oldest[i];
    end
  always_comb
    for (int i = 0; i < N_PORTS; i++) begin
      bank_conflict_slow[i] = real_other_bank_conflict_reg[i] | real_rr_bank_conflict_reg[i];
      // 快速唤醒禁用：本拍就知道可能冲突（写冲突、整行读意图、被更低编号的口冲突）
      disable_fast_wakeup[i] = wr_bank_conflict[i] | rrl_bank_conflict_intend[i];
      for (int j = 0; j < i; j++)
        disable_fast_wakeup[i] |= rr_bank_conflict[j][i];
    end

  // ===========================================================================
  //  §3 每个 bank 的读使能与读地址
  // ===========================================================================
  //  bank b 被 load 口 i 读 = 口有效、访问的（两个之一）bank 是 b、且没被读-读冲突作废。
  //  读地址：整行读优先；否则按口号优先选第一个命中的口的 set。bank 0..3 用 addr_dup 那份（扇出分担）。
  always_comb
    for (int b = 0; b < N_BANKS; b++) begin : g_bank_read
      logic match     [N_PORTS];
      logic match_dup [N_PORTS];
      logic any_match;
      logic [SET_W-1:0] load_set, load_set_dup;
      any_match = 1'b0;
      for (int i = 0; i < N_PORTS; i++) begin
        match[i]     = rd_valid[i] & (bank_addr[i][0] == 3'(b) | bank_addr[i][1] == 3'(b) & rd_is128[i]) &
                       ~rr_bank_conflict_oldest[i];
        match_dup[i] = rd_valid[i] & (bank_addr_dup[i][0] == 3'(b) | bank_addr_dup[i][1] == 3'(b) & rd_is128[i]) &
                       ~rr_bank_conflict_oldest[i];
        any_match   |= match[i];
      end
      // PriorityMux：从最后一口往前覆盖，最后留下编号最小的命中口；都不命中取最后一口
      load_set     = set_addr[N_PORTS-1];
      load_set_dup = set_addr_dup[N_PORTS-1];
      for (int i = N_PORTS - 2; i >= 0; i--) begin
        if (match[i])     load_set     = set_addr[i];
        if (match_dup[i]) load_set_dup = set_addr_dup[i];
      end
      bank_r_en[b]   = any_match | io_readline_valid;
      bank_r_addr[b] = io_readline_valid ? io_readline_bits_addr[13:6] :
                       (b < 4)           ? load_set_dup : load_set;
    end

  // ===========================================================================
  //  §4 bank 读结果：注入伪错误、ECC 延迟一拍检错
  // ===========================================================================
  logic [ROW_W-1:0] bank_raw [N_BANKS][N_WAYS];
  logic [ECC_W-1:0] bank_ecc [N_BANKS][N_WAYS];
  always_comb
    for (int b = 0; b < N_BANKS; b++)
      for (int w = 0; w < N_WAYS; w++) begin
        bank_ecc[b][w] = bank_r_data[b][w][ENC_W-1:ROW_W];
        bank_raw[b][w] = bank_r_data[b][w][ROW_W-1:0] ^
                         ((mbist_sram_ack[b*N_WAYS+w] | ~(io_pseudo_error_valid & pe_bank_valid[b]))
                            ? '0 : pe_bank_mask[b]);
      end

  // 读出数据下一拍才做 SECDED 检错（时序）：每路一份"上一拍读过"的打拍和一份数据寄存器
  logic             ecc_data_delayed_REG [N_BANKS][N_WAYS];
  logic [ENC_W-1:0] ecc_data_delayed     [N_BANKS][N_WAYS];
  logic             bank_error_delayed   [N_BANKS][N_WAYS];
  always_ff @(posedge clock)
    for (int b = 0; b < N_BANKS; b++)
      for (int w = 0; w < N_WAYS; w++) begin
        ecc_data_delayed_REG[b][w] <= bank_r_en[b];
        if (ecc_data_delayed_REG[b][w])
          ecc_data_delayed[b][w] <= {bank_ecc[b][w], bank_raw[b][w]};
      end
  always_comb
    for (int b = 0; b < N_BANKS; b++)
      for (int w = 0; w < N_WAYS; w++)
        bank_error_delayed[b][w] = data_ecc_error(ecc_data_delayed[b][w]);

  // ===========================================================================
  //  §5 load 读响应：按打一拍的 bank/路号选数据，打两拍的选 ECC 结果
  // ===========================================================================
  logic       r_read_fire     [N_PORTS];
  logic [2:0] r_bank_addr     [N_PORTS][2];
  logic [1:0] r_way_addr      [N_PORTS];
  logic       rr_read_fire    [N_PORTS];
  logic [2:0] rr_bank_addr_r  [N_PORTS][2];   // Chisel 里 rr_* 是 RegEnable(RegEnable(..))：内层单独一份
  logic [1:0] rr_way_addr_r   [N_PORTS];
  logic [2:0] rr_bank_addr    [N_PORTS][2];
  logic [1:0] rr_way_addr     [N_PORTS];
  logic       io_read_error_delayed_REG [N_PORTS][2];   // RegNext(bank_conflict_slow)，每个结果各一份
  always_ff @(posedge clock)
    for (int i = 0; i < N_PORTS; i++) begin
      r_read_fire[i] <= read_fire[i];
      if (read_fire[i]) begin
        r_bank_addr[i]    <= bank_addr[i];
        r_way_addr[i]     <= oh_to_way(rd_way_en[i]);
        rr_bank_addr_r[i] <= bank_addr[i];
        rr_way_addr_r[i]  <= oh_to_way(rd_way_en[i]);
      end
      rr_read_fire[i] <= r_read_fire[i];
      if (r_read_fire[i]) begin
        rr_bank_addr[i] <= rr_bank_addr_r[i];
        rr_way_addr[i]  <= rr_way_addr_r[i];
      end
      for (int j = 0; j < 2; j++)
        io_read_error_delayed_REG[i][j] <= bank_conflict_slow[i];
    end
  always_comb
    for (int i = 0; i < N_PORTS; i++)
      for (int j = 0; j < 2; j++) begin
        rd_resp[i][j]          = bank_raw[r_bank_addr[i][j]][r_way_addr[i]];
        rd_error_delayed[i][j] = rr_read_fire[i] & bank_error_delayed[rr_bank_addr[i][j]][rr_way_addr[i]] &
                                 ~io_read_error_delayed_REG[i][j];
      end

  // ===========================================================================
  //  §6 整行读：路号打一拍 → 8 个 bank 选同一路 → can_go / stall / can_resp 三级寄存 → ECC 检错
  // ===========================================================================
  //  MBIST ack 时这条通路被 MBIST 借用：路号取 MBIST 正在读的那一路，各级寄存无条件前进。
  logic [N_WAYS-1:0] mbist_re_way;   // 各 bank 同一路的 MBIST 读或起来
  always_comb begin
    mbist_re_way = '0;
    for (int b = 0; b < N_BANKS; b++)
      for (int w = 0; w < N_WAYS; w++)
        mbist_re_way[w] |= mbist_sram_re[b*N_WAYS+w];
  end

  logic [1:0]       readline_r_way_addr;
  logic [ECC_W-1:0] readline_resp_r_ecc      [N_BANKS];   // stall 时保持的那一份
  logic [ROW_W-1:0] readline_resp_r_raw_data [N_BANKS];
  logic [ECC_W-1:0] readline_out_ecc         [N_BANKS];   // io.readline_resp 输出寄存器
  logic [ROW_W-1:0] readline_out_raw_data    [N_BANKS];
  wire readline_go = io_readline_can_go | mbist_ack;
  logic [ECC_W-1:0] readline_cur_ecc [N_BANKS];
  logic [ROW_W-1:0] readline_cur_raw [N_BANKS];
  always_comb
    for (int b = 0; b < N_BANKS; b++) begin
      readline_cur_ecc[b] = readline_go ? bank_ecc[b][readline_r_way_addr] : readline_resp_r_ecc[b];
      readline_cur_raw[b] = readline_go ? bank_raw[b][readline_r_way_addr] : readline_resp_r_raw_data[b];
    end

  always_ff @(posedge clock) begin
    if (readline_fire | mbist_ack)
      readline_r_way_addr <= mbist_ack ? oh_to_way(mbist_re_way) : oh_to_way(io_readline_bits_way_en);
    for (int b = 0; b < N_BANKS; b++) begin
      if (io_readline_stall | mbist_ack) begin
        readline_resp_r_ecc[b]      <= readline_cur_ecc[b];
        readline_resp_r_raw_data[b] <= readline_cur_raw[b];
      end
      if (io_readline_can_resp | mbist_ack) begin
        readline_out_ecc[b]      <= readline_cur_ecc[b];
        readline_out_raw_data[b] <= readline_cur_raw[b];
      end
    end
  end

  assign io_readline_resp_0_raw_data = readline_out_raw_data[0];
  assign io_readline_resp_1_raw_data = readline_out_raw_data[1];
  assign io_readline_resp_2_raw_data = readline_out_raw_data[2];
  assign io_readline_resp_3_raw_data = readline_out_raw_data[3];
  assign io_readline_resp_4_raw_data = readline_out_raw_data[4];
  assign io_readline_resp_5_raw_data = readline_out_raw_data[5];
  assign io_readline_resp_6_raw_data = readline_out_raw_data[6];
  assign io_readline_resp_7_raw_data = readline_out_raw_data[7];

  logic readline_error_delayed;
  always_comb begin
    readline_error_delayed = 1'b0;
    for (int b = 0; b < N_BANKS; b++) begin
      readline_error_delayed |= data_ecc_error({readline_out_ecc[b], readline_out_raw_data[b]});
      mbist_rdata[b] = {readline_out_ecc[b], readline_out_raw_data[b]};
    end
  end
  assign io_readline_error_delayed = readline_error_delayed;

  // ===========================================================================
  //  §7 伪错误注入"已生效"：真的读到了被注入的 bank（整行读看 rmask，load 读看自己的 bank）
  // ===========================================================================
  logic io_pseudo_error_ready_REG;
  logic readline_hit, readbank_hit;
  always_comb begin
    readline_hit = 1'b0;
    for (int b = 0; b < N_BANKS; b++)
      readline_hit |= io_readline_bits_rmask[b] & pe_bank_valid[b];
    readline_hit &= readline_fire;
    readbank_hit = 1'b0;
    for (int i = 0; i < N_PORTS; i++)
      readbank_hit |= read_fire[i] &
                      (pe_bank_valid[bank_addr[i][0]] | pe_bank_valid[bank_addr[i][1]] & rd_is128[i]) &
                      ~bank_conflict_slow[i];
  end
  always_ff @(posedge clock)
    io_pseudo_error_ready_REG <= readline_hit | readbank_hit;
  assign io_pseudo_error_ready = io_pseudo_error_ready_REG;

  // ===========================================================================
  //  §8 写：第一拍锁存数据并算 SECDED，第二拍写进 bank
  // ===========================================================================
  logic [ROW_W-1:0] write_data_reg         [N_BANKS];
  logic [ECC_W-1:0] write_ecc_reg          [N_BANKS];
  logic             write_valid_dup_reg    [N_BANKS];
  logic [3:0]       write_wayen_dup_reg    [N_BANKS];
  logic [SET_W-1:0] write_set_addr_dup_reg [N_BANKS];
  logic             wen_reg_REG            [N_BANKS];   // RegNext(io.write.valid, false.B)，每 bank 一份
  always_ff @(posedge clock) begin
    if (io_write_valid) begin
      write_bank_mask_reg <= io_write_bits_wmask;
      for (int b = 0; b < N_BANKS; b++) begin
        write_data_reg[b] <= wr_data[b];
        write_ecc_reg[b]  <= data_ecc_encode(wr_data[b]);
      end
    end
    write_valid_reg <= io_write_valid;
    for (int b = 0; b < N_BANKS; b++) begin
      write_valid_dup_reg[b] <= wr_dup_valid[b];
      if (wr_dup_valid[b]) begin
        write_wayen_dup_reg[b]    <= wr_dup_way_en[b];
        write_set_addr_dup_reg[b] <= wr_dup_addr[b][13:6];
      end
    end
  end
  always_ff @(posedge clock or posedge reset)
    if (reset)
      for (int b = 0; b < N_BANKS; b++) wen_reg_REG[b] <= 1'b0;
    else
      for (int b = 0; b < N_BANKS; b++) wen_reg_REG[b] <= io_write_valid;
  always_comb
    for (int b = 0; b < N_BANKS; b++) begin
      bank_w_en[b]     = write_bank_mask_reg[b] & write_valid_dup_reg[b] & wen_reg_REG[b];
      bank_w_addr[b]   = write_set_addr_dup_reg[b];
      bank_w_way_en[b] = write_wayen_dup_reg[b];
      bank_w_data[b]   = {write_ecc_reg[b], write_data_reg[b]};
    end

  // ===========================================================================
  //  §9 仿真检查寄存器：assert(!(RegNext(read.fire && PopCount(way_en) > 1)))，名同 golden
  // ===========================================================================
  logic REG_8, REG_9, REG_10;
  always_ff @(posedge clock) begin
    REG_8  <= read_fire[0] & (popcount4(rd_way_en[0]) > 3'd1);
    REG_9  <= read_fire[1] & (popcount4(rd_way_en[1]) > 3'd1);
    REG_10 <= read_fire[2] & (popcount4(rd_way_en[2]) > 3'd1);
  end
`ifndef SYNTHESIS
  always @(posedge clock)
    if (!reset && (REG_8 || REG_9 || REG_10))
      $error("BankedDataArray: load read way_en is not one-hot");
`endif

// BEGIN GENERATED(bda_insts)
// 由 scripts/gen_bankeddataarray.py 从 golden 生成 —— 勿手改
  // ---- MBIST 穿线：MbistPipeDCacheData 的 32 个 toSRAM 口 ↔ 8 bank × 4 路 SRAM 的 bore 口 ----
  wire [8:0] childBd_0_addr;
  wire [8:0] childBd_0_addr_rd;
  wire [71:0] childBd_0_wdata;
  wire childBd_0_wmask;
  wire childBd_0_re;
  wire childBd_0_we;
  wire [71:0] childBd_0_rdata;
  wire childBd_0_ack;
  wire childBd_0_selectedOH;
  wire childBd_0_array;
  wire [8:0] childBd_1_addr;
  wire [8:0] childBd_1_addr_rd;
  wire [71:0] childBd_1_wdata;
  wire childBd_1_wmask;
  wire childBd_1_re;
  wire childBd_1_we;
  wire [71:0] childBd_1_rdata;
  wire childBd_1_ack;
  wire childBd_1_selectedOH;
  wire childBd_1_array;
  wire [8:0] childBd_2_addr;
  wire [8:0] childBd_2_addr_rd;
  wire [71:0] childBd_2_wdata;
  wire childBd_2_wmask;
  wire childBd_2_re;
  wire childBd_2_we;
  wire [71:0] childBd_2_rdata;
  wire childBd_2_ack;
  wire childBd_2_selectedOH;
  wire [1:0] childBd_2_array;
  wire [8:0] childBd_3_addr;
  wire [8:0] childBd_3_addr_rd;
  wire [71:0] childBd_3_wdata;
  wire childBd_3_wmask;
  wire childBd_3_re;
  wire childBd_3_we;
  wire [71:0] childBd_3_rdata;
  wire childBd_3_ack;
  wire childBd_3_selectedOH;
  wire [1:0] childBd_3_array;
  wire [8:0] childBd_4_addr;
  wire [8:0] childBd_4_addr_rd;
  wire [71:0] childBd_4_wdata;
  wire childBd_4_wmask;
  wire childBd_4_re;
  wire childBd_4_we;
  wire [71:0] childBd_4_rdata;
  wire childBd_4_ack;
  wire childBd_4_selectedOH;
  wire [2:0] childBd_4_array;
  wire [8:0] childBd_5_addr;
  wire [8:0] childBd_5_addr_rd;
  wire [71:0] childBd_5_wdata;
  wire childBd_5_wmask;
  wire childBd_5_re;
  wire childBd_5_we;
  wire [71:0] childBd_5_rdata;
  wire childBd_5_ack;
  wire childBd_5_selectedOH;
  wire [2:0] childBd_5_array;
  wire [8:0] childBd_6_addr;
  wire [8:0] childBd_6_addr_rd;
  wire [71:0] childBd_6_wdata;
  wire childBd_6_wmask;
  wire childBd_6_re;
  wire childBd_6_we;
  wire [71:0] childBd_6_rdata;
  wire childBd_6_ack;
  wire childBd_6_selectedOH;
  wire [2:0] childBd_6_array;
  wire [8:0] childBd_7_addr;
  wire [8:0] childBd_7_addr_rd;
  wire [71:0] childBd_7_wdata;
  wire childBd_7_wmask;
  wire childBd_7_re;
  wire childBd_7_we;
  wire [71:0] childBd_7_rdata;
  wire childBd_7_ack;
  wire childBd_7_selectedOH;
  wire [2:0] childBd_7_array;
  wire [8:0] childBd_8_addr;
  wire [8:0] childBd_8_addr_rd;
  wire [71:0] childBd_8_wdata;
  wire childBd_8_wmask;
  wire childBd_8_re;
  wire childBd_8_we;
  wire [71:0] childBd_8_rdata;
  wire childBd_8_ack;
  wire childBd_8_selectedOH;
  wire [3:0] childBd_8_array;
  wire [8:0] childBd_9_addr;
  wire [8:0] childBd_9_addr_rd;
  wire [71:0] childBd_9_wdata;
  wire childBd_9_wmask;
  wire childBd_9_re;
  wire childBd_9_we;
  wire [71:0] childBd_9_rdata;
  wire childBd_9_ack;
  wire childBd_9_selectedOH;
  wire [3:0] childBd_9_array;
  wire [8:0] childBd_10_addr;
  wire [8:0] childBd_10_addr_rd;
  wire [71:0] childBd_10_wdata;
  wire childBd_10_wmask;
  wire childBd_10_re;
  wire childBd_10_we;
  wire [71:0] childBd_10_rdata;
  wire childBd_10_ack;
  wire childBd_10_selectedOH;
  wire [3:0] childBd_10_array;
  wire [8:0] childBd_11_addr;
  wire [8:0] childBd_11_addr_rd;
  wire [71:0] childBd_11_wdata;
  wire childBd_11_wmask;
  wire childBd_11_re;
  wire childBd_11_we;
  wire [71:0] childBd_11_rdata;
  wire childBd_11_ack;
  wire childBd_11_selectedOH;
  wire [3:0] childBd_11_array;
  wire [8:0] childBd_12_addr;
  wire [8:0] childBd_12_addr_rd;
  wire [71:0] childBd_12_wdata;
  wire childBd_12_wmask;
  wire childBd_12_re;
  wire childBd_12_we;
  wire [71:0] childBd_12_rdata;
  wire childBd_12_ack;
  wire childBd_12_selectedOH;
  wire [3:0] childBd_12_array;
  wire [8:0] childBd_13_addr;
  wire [8:0] childBd_13_addr_rd;
  wire [71:0] childBd_13_wdata;
  wire childBd_13_wmask;
  wire childBd_13_re;
  wire childBd_13_we;
  wire [71:0] childBd_13_rdata;
  wire childBd_13_ack;
  wire childBd_13_selectedOH;
  wire [3:0] childBd_13_array;
  wire [8:0] childBd_14_addr;
  wire [8:0] childBd_14_addr_rd;
  wire [71:0] childBd_14_wdata;
  wire childBd_14_wmask;
  wire childBd_14_re;
  wire childBd_14_we;
  wire [71:0] childBd_14_rdata;
  wire childBd_14_ack;
  wire childBd_14_selectedOH;
  wire [3:0] childBd_14_array;
  wire [8:0] childBd_15_addr;
  wire [8:0] childBd_15_addr_rd;
  wire [71:0] childBd_15_wdata;
  wire childBd_15_wmask;
  wire childBd_15_re;
  wire childBd_15_we;
  wire [71:0] childBd_15_rdata;
  wire childBd_15_ack;
  wire childBd_15_selectedOH;
  wire [3:0] childBd_15_array;
  wire [8:0] childBd_16_addr;
  wire [8:0] childBd_16_addr_rd;
  wire [71:0] childBd_16_wdata;
  wire childBd_16_wmask;
  wire childBd_16_re;
  wire childBd_16_we;
  wire [71:0] childBd_16_rdata;
  wire childBd_16_ack;
  wire childBd_16_selectedOH;
  wire [4:0] childBd_16_array;
  wire [8:0] childBd_17_addr;
  wire [8:0] childBd_17_addr_rd;
  wire [71:0] childBd_17_wdata;
  wire childBd_17_wmask;
  wire childBd_17_re;
  wire childBd_17_we;
  wire [71:0] childBd_17_rdata;
  wire childBd_17_ack;
  wire childBd_17_selectedOH;
  wire [4:0] childBd_17_array;
  wire [8:0] childBd_18_addr;
  wire [8:0] childBd_18_addr_rd;
  wire [71:0] childBd_18_wdata;
  wire childBd_18_wmask;
  wire childBd_18_re;
  wire childBd_18_we;
  wire [71:0] childBd_18_rdata;
  wire childBd_18_ack;
  wire childBd_18_selectedOH;
  wire [4:0] childBd_18_array;
  wire [8:0] childBd_19_addr;
  wire [8:0] childBd_19_addr_rd;
  wire [71:0] childBd_19_wdata;
  wire childBd_19_wmask;
  wire childBd_19_re;
  wire childBd_19_we;
  wire [71:0] childBd_19_rdata;
  wire childBd_19_ack;
  wire childBd_19_selectedOH;
  wire [4:0] childBd_19_array;
  wire [8:0] childBd_20_addr;
  wire [8:0] childBd_20_addr_rd;
  wire [71:0] childBd_20_wdata;
  wire childBd_20_wmask;
  wire childBd_20_re;
  wire childBd_20_we;
  wire [71:0] childBd_20_rdata;
  wire childBd_20_ack;
  wire childBd_20_selectedOH;
  wire [4:0] childBd_20_array;
  wire [8:0] childBd_21_addr;
  wire [8:0] childBd_21_addr_rd;
  wire [71:0] childBd_21_wdata;
  wire childBd_21_wmask;
  wire childBd_21_re;
  wire childBd_21_we;
  wire [71:0] childBd_21_rdata;
  wire childBd_21_ack;
  wire childBd_21_selectedOH;
  wire [4:0] childBd_21_array;
  wire [8:0] childBd_22_addr;
  wire [8:0] childBd_22_addr_rd;
  wire [71:0] childBd_22_wdata;
  wire childBd_22_wmask;
  wire childBd_22_re;
  wire childBd_22_we;
  wire [71:0] childBd_22_rdata;
  wire childBd_22_ack;
  wire childBd_22_selectedOH;
  wire [4:0] childBd_22_array;
  wire [8:0] childBd_23_addr;
  wire [8:0] childBd_23_addr_rd;
  wire [71:0] childBd_23_wdata;
  wire childBd_23_wmask;
  wire childBd_23_re;
  wire childBd_23_we;
  wire [71:0] childBd_23_rdata;
  wire childBd_23_ack;
  wire childBd_23_selectedOH;
  wire [4:0] childBd_23_array;
  wire [8:0] childBd_24_addr;
  wire [8:0] childBd_24_addr_rd;
  wire [71:0] childBd_24_wdata;
  wire childBd_24_wmask;
  wire childBd_24_re;
  wire childBd_24_we;
  wire [71:0] childBd_24_rdata;
  wire childBd_24_ack;
  wire childBd_24_selectedOH;
  wire [4:0] childBd_24_array;
  wire [8:0] childBd_25_addr;
  wire [8:0] childBd_25_addr_rd;
  wire [71:0] childBd_25_wdata;
  wire childBd_25_wmask;
  wire childBd_25_re;
  wire childBd_25_we;
  wire [71:0] childBd_25_rdata;
  wire childBd_25_ack;
  wire childBd_25_selectedOH;
  wire [4:0] childBd_25_array;
  wire [8:0] childBd_26_addr;
  wire [8:0] childBd_26_addr_rd;
  wire [71:0] childBd_26_wdata;
  wire childBd_26_wmask;
  wire childBd_26_re;
  wire childBd_26_we;
  wire [71:0] childBd_26_rdata;
  wire childBd_26_ack;
  wire childBd_26_selectedOH;
  wire [4:0] childBd_26_array;
  wire [8:0] childBd_27_addr;
  wire [8:0] childBd_27_addr_rd;
  wire [71:0] childBd_27_wdata;
  wire childBd_27_wmask;
  wire childBd_27_re;
  wire childBd_27_we;
  wire [71:0] childBd_27_rdata;
  wire childBd_27_ack;
  wire childBd_27_selectedOH;
  wire [4:0] childBd_27_array;
  wire [8:0] childBd_28_addr;
  wire [8:0] childBd_28_addr_rd;
  wire [71:0] childBd_28_wdata;
  wire childBd_28_wmask;
  wire childBd_28_re;
  wire childBd_28_we;
  wire [71:0] childBd_28_rdata;
  wire childBd_28_ack;
  wire childBd_28_selectedOH;
  wire [4:0] childBd_28_array;
  wire [8:0] childBd_29_addr;
  wire [8:0] childBd_29_addr_rd;
  wire [71:0] childBd_29_wdata;
  wire childBd_29_wmask;
  wire childBd_29_re;
  wire childBd_29_we;
  wire [71:0] childBd_29_rdata;
  wire childBd_29_ack;
  wire childBd_29_selectedOH;
  wire [4:0] childBd_29_array;
  wire [8:0] childBd_30_addr;
  wire [8:0] childBd_30_addr_rd;
  wire [71:0] childBd_30_wdata;
  wire childBd_30_wmask;
  wire childBd_30_re;
  wire childBd_30_we;
  wire [71:0] childBd_30_rdata;
  wire childBd_30_ack;
  wire childBd_30_selectedOH;
  wire [4:0] childBd_30_array;
  wire [8:0] childBd_31_addr;
  wire [8:0] childBd_31_addr_rd;
  wire [71:0] childBd_31_wdata;
  wire childBd_31_wmask;
  wire childBd_31_re;
  wire childBd_31_we;
  wire [71:0] childBd_31_rdata;
  wire childBd_31_ack;
  wire childBd_31_selectedOH;
  wire [4:0] childBd_31_array;

  // MBIST 回读：toSRAM_n_rdata 借用 bank n/4 的整行读输出寄存器（§6）；ack / re 回到手写区
  assign mbist_sram_ack[0] = childBd_0_ack;
  assign mbist_sram_re[0]  = childBd_0_re;
  assign mbist_sram_ack[1] = childBd_1_ack;
  assign mbist_sram_re[1]  = childBd_1_re;
  assign mbist_sram_ack[2] = childBd_2_ack;
  assign mbist_sram_re[2]  = childBd_2_re;
  assign mbist_sram_ack[3] = childBd_3_ack;
  assign mbist_sram_re[3]  = childBd_3_re;
  assign mbist_sram_ack[4] = childBd_4_ack;
  assign mbist_sram_re[4]  = childBd_4_re;
  assign mbist_sram_ack[5] = childBd_5_ack;
  assign mbist_sram_re[5]  = childBd_5_re;
  assign mbist_sram_ack[6] = childBd_6_ack;
  assign mbist_sram_re[6]  = childBd_6_re;
  assign mbist_sram_ack[7] = childBd_7_ack;
  assign mbist_sram_re[7]  = childBd_7_re;
  assign mbist_sram_ack[8] = childBd_8_ack;
  assign mbist_sram_re[8]  = childBd_8_re;
  assign mbist_sram_ack[9] = childBd_9_ack;
  assign mbist_sram_re[9]  = childBd_9_re;
  assign mbist_sram_ack[10] = childBd_10_ack;
  assign mbist_sram_re[10]  = childBd_10_re;
  assign mbist_sram_ack[11] = childBd_11_ack;
  assign mbist_sram_re[11]  = childBd_11_re;
  assign mbist_sram_ack[12] = childBd_12_ack;
  assign mbist_sram_re[12]  = childBd_12_re;
  assign mbist_sram_ack[13] = childBd_13_ack;
  assign mbist_sram_re[13]  = childBd_13_re;
  assign mbist_sram_ack[14] = childBd_14_ack;
  assign mbist_sram_re[14]  = childBd_14_re;
  assign mbist_sram_ack[15] = childBd_15_ack;
  assign mbist_sram_re[15]  = childBd_15_re;
  assign mbist_sram_ack[16] = childBd_16_ack;
  assign mbist_sram_re[16]  = childBd_16_re;
  assign mbist_sram_ack[17] = childBd_17_ack;
  assign mbist_sram_re[17]  = childBd_17_re;
  assign mbist_sram_ack[18] = childBd_18_ack;
  assign mbist_sram_re[18]  = childBd_18_re;
  assign mbist_sram_ack[19] = childBd_19_ack;
  assign mbist_sram_re[19]  = childBd_19_re;
  assign mbist_sram_ack[20] = childBd_20_ack;
  assign mbist_sram_re[20]  = childBd_20_re;
  assign mbist_sram_ack[21] = childBd_21_ack;
  assign mbist_sram_re[21]  = childBd_21_re;
  assign mbist_sram_ack[22] = childBd_22_ack;
  assign mbist_sram_re[22]  = childBd_22_re;
  assign mbist_sram_ack[23] = childBd_23_ack;
  assign mbist_sram_re[23]  = childBd_23_re;
  assign mbist_sram_ack[24] = childBd_24_ack;
  assign mbist_sram_re[24]  = childBd_24_re;
  assign mbist_sram_ack[25] = childBd_25_ack;
  assign mbist_sram_re[25]  = childBd_25_re;
  assign mbist_sram_ack[26] = childBd_26_ack;
  assign mbist_sram_re[26]  = childBd_26_re;
  assign mbist_sram_ack[27] = childBd_27_ack;
  assign mbist_sram_re[27]  = childBd_27_re;
  assign mbist_sram_ack[28] = childBd_28_ack;
  assign mbist_sram_re[28]  = childBd_28_re;
  assign mbist_sram_ack[29] = childBd_29_ack;
  assign mbist_sram_re[29]  = childBd_29_re;
  assign mbist_sram_ack[30] = childBd_30_ack;
  assign mbist_sram_re[30]  = childBd_30_re;
  assign mbist_sram_ack[31] = childBd_31_ack;
  assign mbist_sram_re[31]  = childBd_31_re;

  MbistPipeDCacheData mbistPl (
    .clock                (clock),
    .reset                (reset),
    .mbist_array          (boreChildrenBd_bore_array),
    .mbist_all            (boreChildrenBd_bore_all),
    .mbist_req            (boreChildrenBd_bore_req),
    .mbist_ack            (mbist_ack),
    .mbist_writeen        (boreChildrenBd_bore_writeen),
    .mbist_be             (boreChildrenBd_bore_be),
    .mbist_addr           (boreChildrenBd_bore_addr),
    .mbist_indata         (boreChildrenBd_bore_indata),
    .mbist_readen         (boreChildrenBd_bore_readen),
    .mbist_addr_rd        (boreChildrenBd_bore_addr_rd),
    .mbist_outdata        (boreChildrenBd_bore_outdata),
    .toSRAM_0_addr        (childBd_0_addr),
    .toSRAM_0_addr_rd     (childBd_0_addr_rd),
    .toSRAM_0_wdata       (childBd_0_wdata),
    .toSRAM_0_wmask       (childBd_0_wmask),
    .toSRAM_0_re          (childBd_0_re),
    .toSRAM_0_we          (childBd_0_we),
    .toSRAM_0_rdata       (mbist_rdata[0]),
    .toSRAM_0_ack         (childBd_0_ack),
    .toSRAM_0_selectedOH  (childBd_0_selectedOH),
    .toSRAM_0_array       (childBd_0_array),
    .toSRAM_1_addr        (childBd_1_addr),
    .toSRAM_1_addr_rd     (childBd_1_addr_rd),
    .toSRAM_1_wdata       (childBd_1_wdata),
    .toSRAM_1_wmask       (childBd_1_wmask),
    .toSRAM_1_re          (childBd_1_re),
    .toSRAM_1_we          (childBd_1_we),
    .toSRAM_1_rdata       (mbist_rdata[0]),
    .toSRAM_1_ack         (childBd_1_ack),
    .toSRAM_1_selectedOH  (childBd_1_selectedOH),
    .toSRAM_1_array       (childBd_1_array),
    .toSRAM_2_addr        (childBd_2_addr),
    .toSRAM_2_addr_rd     (childBd_2_addr_rd),
    .toSRAM_2_wdata       (childBd_2_wdata),
    .toSRAM_2_wmask       (childBd_2_wmask),
    .toSRAM_2_re          (childBd_2_re),
    .toSRAM_2_we          (childBd_2_we),
    .toSRAM_2_rdata       (mbist_rdata[0]),
    .toSRAM_2_ack         (childBd_2_ack),
    .toSRAM_2_selectedOH  (childBd_2_selectedOH),
    .toSRAM_2_array       (childBd_2_array),
    .toSRAM_3_addr        (childBd_3_addr),
    .toSRAM_3_addr_rd     (childBd_3_addr_rd),
    .toSRAM_3_wdata       (childBd_3_wdata),
    .toSRAM_3_wmask       (childBd_3_wmask),
    .toSRAM_3_re          (childBd_3_re),
    .toSRAM_3_we          (childBd_3_we),
    .toSRAM_3_rdata       (mbist_rdata[0]),
    .toSRAM_3_ack         (childBd_3_ack),
    .toSRAM_3_selectedOH  (childBd_3_selectedOH),
    .toSRAM_3_array       (childBd_3_array),
    .toSRAM_4_addr        (childBd_4_addr),
    .toSRAM_4_addr_rd     (childBd_4_addr_rd),
    .toSRAM_4_wdata       (childBd_4_wdata),
    .toSRAM_4_wmask       (childBd_4_wmask),
    .toSRAM_4_re          (childBd_4_re),
    .toSRAM_4_we          (childBd_4_we),
    .toSRAM_4_rdata       (mbist_rdata[1]),
    .toSRAM_4_ack         (childBd_4_ack),
    .toSRAM_4_selectedOH  (childBd_4_selectedOH),
    .toSRAM_4_array       (childBd_4_array),
    .toSRAM_5_addr        (childBd_5_addr),
    .toSRAM_5_addr_rd     (childBd_5_addr_rd),
    .toSRAM_5_wdata       (childBd_5_wdata),
    .toSRAM_5_wmask       (childBd_5_wmask),
    .toSRAM_5_re          (childBd_5_re),
    .toSRAM_5_we          (childBd_5_we),
    .toSRAM_5_rdata       (mbist_rdata[1]),
    .toSRAM_5_ack         (childBd_5_ack),
    .toSRAM_5_selectedOH  (childBd_5_selectedOH),
    .toSRAM_5_array       (childBd_5_array),
    .toSRAM_6_addr        (childBd_6_addr),
    .toSRAM_6_addr_rd     (childBd_6_addr_rd),
    .toSRAM_6_wdata       (childBd_6_wdata),
    .toSRAM_6_wmask       (childBd_6_wmask),
    .toSRAM_6_re          (childBd_6_re),
    .toSRAM_6_we          (childBd_6_we),
    .toSRAM_6_rdata       (mbist_rdata[1]),
    .toSRAM_6_ack         (childBd_6_ack),
    .toSRAM_6_selectedOH  (childBd_6_selectedOH),
    .toSRAM_6_array       (childBd_6_array),
    .toSRAM_7_addr        (childBd_7_addr),
    .toSRAM_7_addr_rd     (childBd_7_addr_rd),
    .toSRAM_7_wdata       (childBd_7_wdata),
    .toSRAM_7_wmask       (childBd_7_wmask),
    .toSRAM_7_re          (childBd_7_re),
    .toSRAM_7_we          (childBd_7_we),
    .toSRAM_7_rdata       (mbist_rdata[1]),
    .toSRAM_7_ack         (childBd_7_ack),
    .toSRAM_7_selectedOH  (childBd_7_selectedOH),
    .toSRAM_7_array       (childBd_7_array),
    .toSRAM_8_addr        (childBd_8_addr),
    .toSRAM_8_addr_rd     (childBd_8_addr_rd),
    .toSRAM_8_wdata       (childBd_8_wdata),
    .toSRAM_8_wmask       (childBd_8_wmask),
    .toSRAM_8_re          (childBd_8_re),
    .toSRAM_8_we          (childBd_8_we),
    .toSRAM_8_rdata       (mbist_rdata[2]),
    .toSRAM_8_ack         (childBd_8_ack),
    .toSRAM_8_selectedOH  (childBd_8_selectedOH),
    .toSRAM_8_array       (childBd_8_array),
    .toSRAM_9_addr        (childBd_9_addr),
    .toSRAM_9_addr_rd     (childBd_9_addr_rd),
    .toSRAM_9_wdata       (childBd_9_wdata),
    .toSRAM_9_wmask       (childBd_9_wmask),
    .toSRAM_9_re          (childBd_9_re),
    .toSRAM_9_we          (childBd_9_we),
    .toSRAM_9_rdata       (mbist_rdata[2]),
    .toSRAM_9_ack         (childBd_9_ack),
    .toSRAM_9_selectedOH  (childBd_9_selectedOH),
    .toSRAM_9_array       (childBd_9_array),
    .toSRAM_10_addr       (childBd_10_addr),
    .toSRAM_10_addr_rd    (childBd_10_addr_rd),
    .toSRAM_10_wdata      (childBd_10_wdata),
    .toSRAM_10_wmask      (childBd_10_wmask),
    .toSRAM_10_re         (childBd_10_re),
    .toSRAM_10_we         (childBd_10_we),
    .toSRAM_10_rdata      (mbist_rdata[2]),
    .toSRAM_10_ack        (childBd_10_ack),
    .toSRAM_10_selectedOH (childBd_10_selectedOH),
    .toSRAM_10_array      (childBd_10_array),
    .toSRAM_11_addr       (childBd_11_addr),
    .toSRAM_11_addr_rd    (childBd_11_addr_rd),
    .toSRAM_11_wdata      (childBd_11_wdata),
    .toSRAM_11_wmask      (childBd_11_wmask),
    .toSRAM_11_re         (childBd_11_re),
    .toSRAM_11_we         (childBd_11_we),
    .toSRAM_11_rdata      (mbist_rdata[2]),
    .toSRAM_11_ack        (childBd_11_ack),
    .toSRAM_11_selectedOH (childBd_11_selectedOH),
    .toSRAM_11_array      (childBd_11_array),
    .toSRAM_12_addr       (childBd_12_addr),
    .toSRAM_12_addr_rd    (childBd_12_addr_rd),
    .toSRAM_12_wdata      (childBd_12_wdata),
    .toSRAM_12_wmask      (childBd_12_wmask),
    .toSRAM_12_re         (childBd_12_re),
    .toSRAM_12_we         (childBd_12_we),
    .toSRAM_12_rdata      (mbist_rdata[3]),
    .toSRAM_12_ack        (childBd_12_ack),
    .toSRAM_12_selectedOH (childBd_12_selectedOH),
    .toSRAM_12_array      (childBd_12_array),
    .toSRAM_13_addr       (childBd_13_addr),
    .toSRAM_13_addr_rd    (childBd_13_addr_rd),
    .toSRAM_13_wdata      (childBd_13_wdata),
    .toSRAM_13_wmask      (childBd_13_wmask),
    .toSRAM_13_re         (childBd_13_re),
    .toSRAM_13_we         (childBd_13_we),
    .toSRAM_13_rdata      (mbist_rdata[3]),
    .toSRAM_13_ack        (childBd_13_ack),
    .toSRAM_13_selectedOH (childBd_13_selectedOH),
    .toSRAM_13_array      (childBd_13_array),
    .toSRAM_14_addr       (childBd_14_addr),
    .toSRAM_14_addr_rd    (childBd_14_addr_rd),
    .toSRAM_14_wdata      (childBd_14_wdata),
    .toSRAM_14_wmask      (childBd_14_wmask),
    .toSRAM_14_re         (childBd_14_re),
    .toSRAM_14_we         (childBd_14_we),
    .toSRAM_14_rdata      (mbist_rdata[3]),
    .toSRAM_14_ack        (childBd_14_ack),
    .toSRAM_14_selectedOH (childBd_14_selectedOH),
    .toSRAM_14_array      (childBd_14_array),
    .toSRAM_15_addr       (childBd_15_addr),
    .toSRAM_15_addr_rd    (childBd_15_addr_rd),
    .toSRAM_15_wdata      (childBd_15_wdata),
    .toSRAM_15_wmask      (childBd_15_wmask),
    .toSRAM_15_re         (childBd_15_re),
    .toSRAM_15_we         (childBd_15_we),
    .toSRAM_15_rdata      (mbist_rdata[3]),
    .toSRAM_15_ack        (childBd_15_ack),
    .toSRAM_15_selectedOH (childBd_15_selectedOH),
    .toSRAM_15_array      (childBd_15_array),
    .toSRAM_16_addr       (childBd_16_addr),
    .toSRAM_16_addr_rd    (childBd_16_addr_rd),
    .toSRAM_16_wdata      (childBd_16_wdata),
    .toSRAM_16_wmask      (childBd_16_wmask),
    .toSRAM_16_re         (childBd_16_re),
    .toSRAM_16_we         (childBd_16_we),
    .toSRAM_16_rdata      (mbist_rdata[4]),
    .toSRAM_16_ack        (childBd_16_ack),
    .toSRAM_16_selectedOH (childBd_16_selectedOH),
    .toSRAM_16_array      (childBd_16_array),
    .toSRAM_17_addr       (childBd_17_addr),
    .toSRAM_17_addr_rd    (childBd_17_addr_rd),
    .toSRAM_17_wdata      (childBd_17_wdata),
    .toSRAM_17_wmask      (childBd_17_wmask),
    .toSRAM_17_re         (childBd_17_re),
    .toSRAM_17_we         (childBd_17_we),
    .toSRAM_17_rdata      (mbist_rdata[4]),
    .toSRAM_17_ack        (childBd_17_ack),
    .toSRAM_17_selectedOH (childBd_17_selectedOH),
    .toSRAM_17_array      (childBd_17_array),
    .toSRAM_18_addr       (childBd_18_addr),
    .toSRAM_18_addr_rd    (childBd_18_addr_rd),
    .toSRAM_18_wdata      (childBd_18_wdata),
    .toSRAM_18_wmask      (childBd_18_wmask),
    .toSRAM_18_re         (childBd_18_re),
    .toSRAM_18_we         (childBd_18_we),
    .toSRAM_18_rdata      (mbist_rdata[4]),
    .toSRAM_18_ack        (childBd_18_ack),
    .toSRAM_18_selectedOH (childBd_18_selectedOH),
    .toSRAM_18_array      (childBd_18_array),
    .toSRAM_19_addr       (childBd_19_addr),
    .toSRAM_19_addr_rd    (childBd_19_addr_rd),
    .toSRAM_19_wdata      (childBd_19_wdata),
    .toSRAM_19_wmask      (childBd_19_wmask),
    .toSRAM_19_re         (childBd_19_re),
    .toSRAM_19_we         (childBd_19_we),
    .toSRAM_19_rdata      (mbist_rdata[4]),
    .toSRAM_19_ack        (childBd_19_ack),
    .toSRAM_19_selectedOH (childBd_19_selectedOH),
    .toSRAM_19_array      (childBd_19_array),
    .toSRAM_20_addr       (childBd_20_addr),
    .toSRAM_20_addr_rd    (childBd_20_addr_rd),
    .toSRAM_20_wdata      (childBd_20_wdata),
    .toSRAM_20_wmask      (childBd_20_wmask),
    .toSRAM_20_re         (childBd_20_re),
    .toSRAM_20_we         (childBd_20_we),
    .toSRAM_20_rdata      (mbist_rdata[5]),
    .toSRAM_20_ack        (childBd_20_ack),
    .toSRAM_20_selectedOH (childBd_20_selectedOH),
    .toSRAM_20_array      (childBd_20_array),
    .toSRAM_21_addr       (childBd_21_addr),
    .toSRAM_21_addr_rd    (childBd_21_addr_rd),
    .toSRAM_21_wdata      (childBd_21_wdata),
    .toSRAM_21_wmask      (childBd_21_wmask),
    .toSRAM_21_re         (childBd_21_re),
    .toSRAM_21_we         (childBd_21_we),
    .toSRAM_21_rdata      (mbist_rdata[5]),
    .toSRAM_21_ack        (childBd_21_ack),
    .toSRAM_21_selectedOH (childBd_21_selectedOH),
    .toSRAM_21_array      (childBd_21_array),
    .toSRAM_22_addr       (childBd_22_addr),
    .toSRAM_22_addr_rd    (childBd_22_addr_rd),
    .toSRAM_22_wdata      (childBd_22_wdata),
    .toSRAM_22_wmask      (childBd_22_wmask),
    .toSRAM_22_re         (childBd_22_re),
    .toSRAM_22_we         (childBd_22_we),
    .toSRAM_22_rdata      (mbist_rdata[5]),
    .toSRAM_22_ack        (childBd_22_ack),
    .toSRAM_22_selectedOH (childBd_22_selectedOH),
    .toSRAM_22_array      (childBd_22_array),
    .toSRAM_23_addr       (childBd_23_addr),
    .toSRAM_23_addr_rd    (childBd_23_addr_rd),
    .toSRAM_23_wdata      (childBd_23_wdata),
    .toSRAM_23_wmask      (childBd_23_wmask),
    .toSRAM_23_re         (childBd_23_re),
    .toSRAM_23_we         (childBd_23_we),
    .toSRAM_23_rdata      (mbist_rdata[5]),
    .toSRAM_23_ack        (childBd_23_ack),
    .toSRAM_23_selectedOH (childBd_23_selectedOH),
    .toSRAM_23_array      (childBd_23_array),
    .toSRAM_24_addr       (childBd_24_addr),
    .toSRAM_24_addr_rd    (childBd_24_addr_rd),
    .toSRAM_24_wdata      (childBd_24_wdata),
    .toSRAM_24_wmask      (childBd_24_wmask),
    .toSRAM_24_re         (childBd_24_re),
    .toSRAM_24_we         (childBd_24_we),
    .toSRAM_24_rdata      (mbist_rdata[6]),
    .toSRAM_24_ack        (childBd_24_ack),
    .toSRAM_24_selectedOH (childBd_24_selectedOH),
    .toSRAM_24_array      (childBd_24_array),
    .toSRAM_25_addr       (childBd_25_addr),
    .toSRAM_25_addr_rd    (childBd_25_addr_rd),
    .toSRAM_25_wdata      (childBd_25_wdata),
    .toSRAM_25_wmask      (childBd_25_wmask),
    .toSRAM_25_re         (childBd_25_re),
    .toSRAM_25_we         (childBd_25_we),
    .toSRAM_25_rdata      (mbist_rdata[6]),
    .toSRAM_25_ack        (childBd_25_ack),
    .toSRAM_25_selectedOH (childBd_25_selectedOH),
    .toSRAM_25_array      (childBd_25_array),
    .toSRAM_26_addr       (childBd_26_addr),
    .toSRAM_26_addr_rd    (childBd_26_addr_rd),
    .toSRAM_26_wdata      (childBd_26_wdata),
    .toSRAM_26_wmask      (childBd_26_wmask),
    .toSRAM_26_re         (childBd_26_re),
    .toSRAM_26_we         (childBd_26_we),
    .toSRAM_26_rdata      (mbist_rdata[6]),
    .toSRAM_26_ack        (childBd_26_ack),
    .toSRAM_26_selectedOH (childBd_26_selectedOH),
    .toSRAM_26_array      (childBd_26_array),
    .toSRAM_27_addr       (childBd_27_addr),
    .toSRAM_27_addr_rd    (childBd_27_addr_rd),
    .toSRAM_27_wdata      (childBd_27_wdata),
    .toSRAM_27_wmask      (childBd_27_wmask),
    .toSRAM_27_re         (childBd_27_re),
    .toSRAM_27_we         (childBd_27_we),
    .toSRAM_27_rdata      (mbist_rdata[6]),
    .toSRAM_27_ack        (childBd_27_ack),
    .toSRAM_27_selectedOH (childBd_27_selectedOH),
    .toSRAM_27_array      (childBd_27_array),
    .toSRAM_28_addr       (childBd_28_addr),
    .toSRAM_28_addr_rd    (childBd_28_addr_rd),
    .toSRAM_28_wdata      (childBd_28_wdata),
    .toSRAM_28_wmask      (childBd_28_wmask),
    .toSRAM_28_re         (childBd_28_re),
    .toSRAM_28_we         (childBd_28_we),
    .toSRAM_28_rdata      (mbist_rdata[7]),
    .toSRAM_28_ack        (childBd_28_ack),
    .toSRAM_28_selectedOH (childBd_28_selectedOH),
    .toSRAM_28_array      (childBd_28_array),
    .toSRAM_29_addr       (childBd_29_addr),
    .toSRAM_29_addr_rd    (childBd_29_addr_rd),
    .toSRAM_29_wdata      (childBd_29_wdata),
    .toSRAM_29_wmask      (childBd_29_wmask),
    .toSRAM_29_re         (childBd_29_re),
    .toSRAM_29_we         (childBd_29_we),
    .toSRAM_29_rdata      (mbist_rdata[7]),
    .toSRAM_29_ack        (childBd_29_ack),
    .toSRAM_29_selectedOH (childBd_29_selectedOH),
    .toSRAM_29_array      (childBd_29_array),
    .toSRAM_30_addr       (childBd_30_addr),
    .toSRAM_30_addr_rd    (childBd_30_addr_rd),
    .toSRAM_30_wdata      (childBd_30_wdata),
    .toSRAM_30_wmask      (childBd_30_wmask),
    .toSRAM_30_re         (childBd_30_re),
    .toSRAM_30_we         (childBd_30_we),
    .toSRAM_30_rdata      (mbist_rdata[7]),
    .toSRAM_30_ack        (childBd_30_ack),
    .toSRAM_30_selectedOH (childBd_30_selectedOH),
    .toSRAM_30_array      (childBd_30_array),
    .toSRAM_31_addr       (childBd_31_addr),
    .toSRAM_31_addr_rd    (childBd_31_addr_rd),
    .toSRAM_31_wdata      (childBd_31_wdata),
    .toSRAM_31_wmask      (childBd_31_wmask),
    .toSRAM_31_re         (childBd_31_re),
    .toSRAM_31_we         (childBd_31_we),
    .toSRAM_31_rdata      (mbist_rdata[7]),
    .toSRAM_31_ack        (childBd_31_ack),
    .toSRAM_31_selectedOH (childBd_31_selectedOH),
    .toSRAM_31_array      (childBd_31_array)
  );
  assign boreChildrenBd_bore_ack = mbist_ack;

  // bank 0
  DataSRAMBank data_banks_0_0 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[0]),
    .io_w_addr                        (bank_w_addr[0]),
    .io_w_way_en                      (bank_w_way_en[0]),
    .io_w_data                        (bank_w_data[0]),
    .io_r_en                          (bank_r_en[0]),
    .io_r_addr                        (bank_r_addr[0]),
    .io_r_data_0                      (bank_r_data[0][0]),
    .io_r_data_1                      (bank_r_data[0][1]),
    .io_r_data_2                      (bank_r_data[0][2]),
    .io_r_data_3                      (bank_r_data[0][3]),
    .boreChildrenBd_bore_addr         (childBd_0_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_0_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_0_wdata),
    .boreChildrenBd_bore_wmask        (childBd_0_wmask),
    .boreChildrenBd_bore_re           (childBd_0_re),
    .boreChildrenBd_bore_we           (childBd_0_we),
    .boreChildrenBd_bore_rdata        (childBd_0_rdata),
    .boreChildrenBd_bore_ack          (childBd_0_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_0_selectedOH),
    .boreChildrenBd_bore_array        (childBd_0_array),
    .boreChildrenBd_bore_1_addr       (childBd_1_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_1_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_1_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_1_wmask),
    .boreChildrenBd_bore_1_re         (childBd_1_re),
    .boreChildrenBd_bore_1_we         (childBd_1_we),
    .boreChildrenBd_bore_1_rdata      (childBd_1_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_1_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_1_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_1_array),
    .boreChildrenBd_bore_2_addr       (childBd_2_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_2_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_2_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_2_wmask),
    .boreChildrenBd_bore_2_re         (childBd_2_re),
    .boreChildrenBd_bore_2_we         (childBd_2_we),
    .boreChildrenBd_bore_2_rdata      (childBd_2_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_2_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_2_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_2_array),
    .boreChildrenBd_bore_3_addr       (childBd_3_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_3_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_3_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_3_wmask),
    .boreChildrenBd_bore_3_re         (childBd_3_re),
    .boreChildrenBd_bore_3_we         (childBd_3_we),
    .boreChildrenBd_bore_3_rdata      (childBd_3_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_3_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_3_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_3_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_1_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_1_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_1_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_1_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_1_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_1_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_1_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_2_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_2_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_2_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_2_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_2_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_2_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_2_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_3_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_3_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_3_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_3_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_3_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_3_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_3_cgen)
  );
  // bank 1
  DataSRAMBank_1 data_banks_0_1 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[1]),
    .io_w_addr                        (bank_w_addr[1]),
    .io_w_way_en                      (bank_w_way_en[1]),
    .io_w_data                        (bank_w_data[1]),
    .io_r_en                          (bank_r_en[1]),
    .io_r_addr                        (bank_r_addr[1]),
    .io_r_data_0                      (bank_r_data[1][0]),
    .io_r_data_1                      (bank_r_data[1][1]),
    .io_r_data_2                      (bank_r_data[1][2]),
    .io_r_data_3                      (bank_r_data[1][3]),
    .boreChildrenBd_bore_addr         (childBd_4_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_4_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_4_wdata),
    .boreChildrenBd_bore_wmask        (childBd_4_wmask),
    .boreChildrenBd_bore_re           (childBd_4_re),
    .boreChildrenBd_bore_we           (childBd_4_we),
    .boreChildrenBd_bore_rdata        (childBd_4_rdata),
    .boreChildrenBd_bore_ack          (childBd_4_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_4_selectedOH),
    .boreChildrenBd_bore_array        (childBd_4_array),
    .boreChildrenBd_bore_1_addr       (childBd_5_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_5_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_5_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_5_wmask),
    .boreChildrenBd_bore_1_re         (childBd_5_re),
    .boreChildrenBd_bore_1_we         (childBd_5_we),
    .boreChildrenBd_bore_1_rdata      (childBd_5_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_5_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_5_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_5_array),
    .boreChildrenBd_bore_2_addr       (childBd_6_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_6_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_6_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_6_wmask),
    .boreChildrenBd_bore_2_re         (childBd_6_re),
    .boreChildrenBd_bore_2_we         (childBd_6_we),
    .boreChildrenBd_bore_2_rdata      (childBd_6_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_6_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_6_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_6_array),
    .boreChildrenBd_bore_3_addr       (childBd_7_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_7_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_7_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_7_wmask),
    .boreChildrenBd_bore_3_re         (childBd_7_re),
    .boreChildrenBd_bore_3_we         (childBd_7_we),
    .boreChildrenBd_bore_3_rdata      (childBd_7_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_7_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_7_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_7_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_4_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_4_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_4_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_4_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_4_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_4_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_4_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_5_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_5_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_5_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_5_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_5_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_5_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_5_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_6_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_6_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_6_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_6_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_6_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_6_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_6_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_7_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_7_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_7_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_7_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_7_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_7_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_7_cgen)
  );
  // bank 2
  DataSRAMBank_2 data_banks_0_2 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[2]),
    .io_w_addr                        (bank_w_addr[2]),
    .io_w_way_en                      (bank_w_way_en[2]),
    .io_w_data                        (bank_w_data[2]),
    .io_r_en                          (bank_r_en[2]),
    .io_r_addr                        (bank_r_addr[2]),
    .io_r_data_0                      (bank_r_data[2][0]),
    .io_r_data_1                      (bank_r_data[2][1]),
    .io_r_data_2                      (bank_r_data[2][2]),
    .io_r_data_3                      (bank_r_data[2][3]),
    .boreChildrenBd_bore_addr         (childBd_8_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_8_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_8_wdata),
    .boreChildrenBd_bore_wmask        (childBd_8_wmask),
    .boreChildrenBd_bore_re           (childBd_8_re),
    .boreChildrenBd_bore_we           (childBd_8_we),
    .boreChildrenBd_bore_rdata        (childBd_8_rdata),
    .boreChildrenBd_bore_ack          (childBd_8_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_8_selectedOH),
    .boreChildrenBd_bore_array        (childBd_8_array),
    .boreChildrenBd_bore_1_addr       (childBd_9_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_9_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_9_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_9_wmask),
    .boreChildrenBd_bore_1_re         (childBd_9_re),
    .boreChildrenBd_bore_1_we         (childBd_9_we),
    .boreChildrenBd_bore_1_rdata      (childBd_9_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_9_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_9_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_9_array),
    .boreChildrenBd_bore_2_addr       (childBd_10_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_10_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_10_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_10_wmask),
    .boreChildrenBd_bore_2_re         (childBd_10_re),
    .boreChildrenBd_bore_2_we         (childBd_10_we),
    .boreChildrenBd_bore_2_rdata      (childBd_10_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_10_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_10_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_10_array),
    .boreChildrenBd_bore_3_addr       (childBd_11_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_11_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_11_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_11_wmask),
    .boreChildrenBd_bore_3_re         (childBd_11_re),
    .boreChildrenBd_bore_3_we         (childBd_11_we),
    .boreChildrenBd_bore_3_rdata      (childBd_11_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_11_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_11_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_11_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_8_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_8_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_8_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_8_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_8_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_8_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_8_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_9_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_9_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_9_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_9_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_9_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_9_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_9_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_10_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_10_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_10_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_10_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_10_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_10_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_10_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_11_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_11_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_11_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_11_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_11_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_11_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_11_cgen)
  );
  // bank 3
  DataSRAMBank_2 data_banks_0_3 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[3]),
    .io_w_addr                        (bank_w_addr[3]),
    .io_w_way_en                      (bank_w_way_en[3]),
    .io_w_data                        (bank_w_data[3]),
    .io_r_en                          (bank_r_en[3]),
    .io_r_addr                        (bank_r_addr[3]),
    .io_r_data_0                      (bank_r_data[3][0]),
    .io_r_data_1                      (bank_r_data[3][1]),
    .io_r_data_2                      (bank_r_data[3][2]),
    .io_r_data_3                      (bank_r_data[3][3]),
    .boreChildrenBd_bore_addr         (childBd_12_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_12_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_12_wdata),
    .boreChildrenBd_bore_wmask        (childBd_12_wmask),
    .boreChildrenBd_bore_re           (childBd_12_re),
    .boreChildrenBd_bore_we           (childBd_12_we),
    .boreChildrenBd_bore_rdata        (childBd_12_rdata),
    .boreChildrenBd_bore_ack          (childBd_12_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_12_selectedOH),
    .boreChildrenBd_bore_array        (childBd_12_array),
    .boreChildrenBd_bore_1_addr       (childBd_13_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_13_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_13_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_13_wmask),
    .boreChildrenBd_bore_1_re         (childBd_13_re),
    .boreChildrenBd_bore_1_we         (childBd_13_we),
    .boreChildrenBd_bore_1_rdata      (childBd_13_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_13_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_13_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_13_array),
    .boreChildrenBd_bore_2_addr       (childBd_14_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_14_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_14_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_14_wmask),
    .boreChildrenBd_bore_2_re         (childBd_14_re),
    .boreChildrenBd_bore_2_we         (childBd_14_we),
    .boreChildrenBd_bore_2_rdata      (childBd_14_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_14_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_14_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_14_array),
    .boreChildrenBd_bore_3_addr       (childBd_15_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_15_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_15_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_15_wmask),
    .boreChildrenBd_bore_3_re         (childBd_15_re),
    .boreChildrenBd_bore_3_we         (childBd_15_we),
    .boreChildrenBd_bore_3_rdata      (childBd_15_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_15_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_15_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_15_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_12_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_12_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_12_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_12_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_12_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_12_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_12_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_13_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_13_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_13_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_13_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_13_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_13_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_13_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_14_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_14_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_14_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_14_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_14_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_14_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_14_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_15_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_15_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_15_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_15_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_15_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_15_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_15_cgen)
  );
  // bank 4
  DataSRAMBank_4 data_banks_0_4 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[4]),
    .io_w_addr                        (bank_w_addr[4]),
    .io_w_way_en                      (bank_w_way_en[4]),
    .io_w_data                        (bank_w_data[4]),
    .io_r_en                          (bank_r_en[4]),
    .io_r_addr                        (bank_r_addr[4]),
    .io_r_data_0                      (bank_r_data[4][0]),
    .io_r_data_1                      (bank_r_data[4][1]),
    .io_r_data_2                      (bank_r_data[4][2]),
    .io_r_data_3                      (bank_r_data[4][3]),
    .boreChildrenBd_bore_addr         (childBd_16_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_16_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_16_wdata),
    .boreChildrenBd_bore_wmask        (childBd_16_wmask),
    .boreChildrenBd_bore_re           (childBd_16_re),
    .boreChildrenBd_bore_we           (childBd_16_we),
    .boreChildrenBd_bore_rdata        (childBd_16_rdata),
    .boreChildrenBd_bore_ack          (childBd_16_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_16_selectedOH),
    .boreChildrenBd_bore_array        (childBd_16_array),
    .boreChildrenBd_bore_1_addr       (childBd_17_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_17_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_17_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_17_wmask),
    .boreChildrenBd_bore_1_re         (childBd_17_re),
    .boreChildrenBd_bore_1_we         (childBd_17_we),
    .boreChildrenBd_bore_1_rdata      (childBd_17_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_17_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_17_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_17_array),
    .boreChildrenBd_bore_2_addr       (childBd_18_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_18_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_18_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_18_wmask),
    .boreChildrenBd_bore_2_re         (childBd_18_re),
    .boreChildrenBd_bore_2_we         (childBd_18_we),
    .boreChildrenBd_bore_2_rdata      (childBd_18_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_18_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_18_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_18_array),
    .boreChildrenBd_bore_3_addr       (childBd_19_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_19_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_19_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_19_wmask),
    .boreChildrenBd_bore_3_re         (childBd_19_re),
    .boreChildrenBd_bore_3_we         (childBd_19_we),
    .boreChildrenBd_bore_3_rdata      (childBd_19_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_19_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_19_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_19_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_16_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_16_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_16_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_16_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_16_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_16_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_16_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_17_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_17_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_17_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_17_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_17_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_17_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_17_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_18_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_18_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_18_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_18_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_18_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_18_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_18_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_19_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_19_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_19_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_19_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_19_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_19_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_19_cgen)
  );
  // bank 5
  DataSRAMBank_4 data_banks_0_5 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[5]),
    .io_w_addr                        (bank_w_addr[5]),
    .io_w_way_en                      (bank_w_way_en[5]),
    .io_w_data                        (bank_w_data[5]),
    .io_r_en                          (bank_r_en[5]),
    .io_r_addr                        (bank_r_addr[5]),
    .io_r_data_0                      (bank_r_data[5][0]),
    .io_r_data_1                      (bank_r_data[5][1]),
    .io_r_data_2                      (bank_r_data[5][2]),
    .io_r_data_3                      (bank_r_data[5][3]),
    .boreChildrenBd_bore_addr         (childBd_20_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_20_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_20_wdata),
    .boreChildrenBd_bore_wmask        (childBd_20_wmask),
    .boreChildrenBd_bore_re           (childBd_20_re),
    .boreChildrenBd_bore_we           (childBd_20_we),
    .boreChildrenBd_bore_rdata        (childBd_20_rdata),
    .boreChildrenBd_bore_ack          (childBd_20_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_20_selectedOH),
    .boreChildrenBd_bore_array        (childBd_20_array),
    .boreChildrenBd_bore_1_addr       (childBd_21_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_21_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_21_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_21_wmask),
    .boreChildrenBd_bore_1_re         (childBd_21_re),
    .boreChildrenBd_bore_1_we         (childBd_21_we),
    .boreChildrenBd_bore_1_rdata      (childBd_21_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_21_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_21_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_21_array),
    .boreChildrenBd_bore_2_addr       (childBd_22_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_22_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_22_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_22_wmask),
    .boreChildrenBd_bore_2_re         (childBd_22_re),
    .boreChildrenBd_bore_2_we         (childBd_22_we),
    .boreChildrenBd_bore_2_rdata      (childBd_22_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_22_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_22_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_22_array),
    .boreChildrenBd_bore_3_addr       (childBd_23_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_23_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_23_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_23_wmask),
    .boreChildrenBd_bore_3_re         (childBd_23_re),
    .boreChildrenBd_bore_3_we         (childBd_23_we),
    .boreChildrenBd_bore_3_rdata      (childBd_23_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_23_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_23_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_23_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_20_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_20_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_20_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_20_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_20_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_20_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_20_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_21_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_21_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_21_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_21_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_21_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_21_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_21_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_22_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_22_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_22_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_22_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_22_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_22_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_22_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_23_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_23_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_23_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_23_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_23_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_23_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_23_cgen)
  );
  // bank 6
  DataSRAMBank_4 data_banks_0_6 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[6]),
    .io_w_addr                        (bank_w_addr[6]),
    .io_w_way_en                      (bank_w_way_en[6]),
    .io_w_data                        (bank_w_data[6]),
    .io_r_en                          (bank_r_en[6]),
    .io_r_addr                        (bank_r_addr[6]),
    .io_r_data_0                      (bank_r_data[6][0]),
    .io_r_data_1                      (bank_r_data[6][1]),
    .io_r_data_2                      (bank_r_data[6][2]),
    .io_r_data_3                      (bank_r_data[6][3]),
    .boreChildrenBd_bore_addr         (childBd_24_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_24_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_24_wdata),
    .boreChildrenBd_bore_wmask        (childBd_24_wmask),
    .boreChildrenBd_bore_re           (childBd_24_re),
    .boreChildrenBd_bore_we           (childBd_24_we),
    .boreChildrenBd_bore_rdata        (childBd_24_rdata),
    .boreChildrenBd_bore_ack          (childBd_24_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_24_selectedOH),
    .boreChildrenBd_bore_array        (childBd_24_array),
    .boreChildrenBd_bore_1_addr       (childBd_25_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_25_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_25_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_25_wmask),
    .boreChildrenBd_bore_1_re         (childBd_25_re),
    .boreChildrenBd_bore_1_we         (childBd_25_we),
    .boreChildrenBd_bore_1_rdata      (childBd_25_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_25_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_25_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_25_array),
    .boreChildrenBd_bore_2_addr       (childBd_26_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_26_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_26_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_26_wmask),
    .boreChildrenBd_bore_2_re         (childBd_26_re),
    .boreChildrenBd_bore_2_we         (childBd_26_we),
    .boreChildrenBd_bore_2_rdata      (childBd_26_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_26_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_26_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_26_array),
    .boreChildrenBd_bore_3_addr       (childBd_27_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_27_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_27_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_27_wmask),
    .boreChildrenBd_bore_3_re         (childBd_27_re),
    .boreChildrenBd_bore_3_we         (childBd_27_we),
    .boreChildrenBd_bore_3_rdata      (childBd_27_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_27_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_27_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_27_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_24_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_24_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_24_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_24_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_24_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_24_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_24_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_25_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_25_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_25_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_25_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_25_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_25_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_25_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_26_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_26_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_26_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_26_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_26_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_26_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_26_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_27_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_27_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_27_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_27_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_27_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_27_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_27_cgen)
  );
  // bank 7
  DataSRAMBank_4 data_banks_0_7 (
    .clock                            (clock),
    .reset                            (reset),
    .io_w_en                          (bank_w_en[7]),
    .io_w_addr                        (bank_w_addr[7]),
    .io_w_way_en                      (bank_w_way_en[7]),
    .io_w_data                        (bank_w_data[7]),
    .io_r_en                          (bank_r_en[7]),
    .io_r_addr                        (bank_r_addr[7]),
    .io_r_data_0                      (bank_r_data[7][0]),
    .io_r_data_1                      (bank_r_data[7][1]),
    .io_r_data_2                      (bank_r_data[7][2]),
    .io_r_data_3                      (bank_r_data[7][3]),
    .boreChildrenBd_bore_addr         (childBd_28_addr),
    .boreChildrenBd_bore_addr_rd      (childBd_28_addr_rd),
    .boreChildrenBd_bore_wdata        (childBd_28_wdata),
    .boreChildrenBd_bore_wmask        (childBd_28_wmask),
    .boreChildrenBd_bore_re           (childBd_28_re),
    .boreChildrenBd_bore_we           (childBd_28_we),
    .boreChildrenBd_bore_rdata        (childBd_28_rdata),
    .boreChildrenBd_bore_ack          (childBd_28_ack),
    .boreChildrenBd_bore_selectedOH   (childBd_28_selectedOH),
    .boreChildrenBd_bore_array        (childBd_28_array),
    .boreChildrenBd_bore_1_addr       (childBd_29_addr),
    .boreChildrenBd_bore_1_addr_rd    (childBd_29_addr_rd),
    .boreChildrenBd_bore_1_wdata      (childBd_29_wdata),
    .boreChildrenBd_bore_1_wmask      (childBd_29_wmask),
    .boreChildrenBd_bore_1_re         (childBd_29_re),
    .boreChildrenBd_bore_1_we         (childBd_29_we),
    .boreChildrenBd_bore_1_rdata      (childBd_29_rdata),
    .boreChildrenBd_bore_1_ack        (childBd_29_ack),
    .boreChildrenBd_bore_1_selectedOH (childBd_29_selectedOH),
    .boreChildrenBd_bore_1_array      (childBd_29_array),
    .boreChildrenBd_bore_2_addr       (childBd_30_addr),
    .boreChildrenBd_bore_2_addr_rd    (childBd_30_addr_rd),
    .boreChildrenBd_bore_2_wdata      (childBd_30_wdata),
    .boreChildrenBd_bore_2_wmask      (childBd_30_wmask),
    .boreChildrenBd_bore_2_re         (childBd_30_re),
    .boreChildrenBd_bore_2_we         (childBd_30_we),
    .boreChildrenBd_bore_2_rdata      (childBd_30_rdata),
    .boreChildrenBd_bore_2_ack        (childBd_30_ack),
    .boreChildrenBd_bore_2_selectedOH (childBd_30_selectedOH),
    .boreChildrenBd_bore_2_array      (childBd_30_array),
    .boreChildrenBd_bore_3_addr       (childBd_31_addr),
    .boreChildrenBd_bore_3_addr_rd    (childBd_31_addr_rd),
    .boreChildrenBd_bore_3_wdata      (childBd_31_wdata),
    .boreChildrenBd_bore_3_wmask      (childBd_31_wmask),
    .boreChildrenBd_bore_3_re         (childBd_31_re),
    .boreChildrenBd_bore_3_we         (childBd_31_we),
    .boreChildrenBd_bore_3_rdata      (childBd_31_rdata),
    .boreChildrenBd_bore_3_ack        (childBd_31_ack),
    .boreChildrenBd_bore_3_selectedOH (childBd_31_selectedOH),
    .boreChildrenBd_bore_3_array      (childBd_31_array),
    .sigFromSrams_bore_ram_hold       (sigFromSrams_bore_28_ram_hold),
    .sigFromSrams_bore_ram_bypass     (sigFromSrams_bore_28_ram_bypass),
    .sigFromSrams_bore_ram_bp_clken   (sigFromSrams_bore_28_ram_bp_clken),
    .sigFromSrams_bore_ram_aux_clk    (sigFromSrams_bore_28_ram_aux_clk),
    .sigFromSrams_bore_ram_aux_ckbp   (sigFromSrams_bore_28_ram_aux_ckbp),
    .sigFromSrams_bore_ram_mcp_hold   (sigFromSrams_bore_28_ram_mcp_hold),
    .sigFromSrams_bore_cgen           (sigFromSrams_bore_28_cgen),
    .sigFromSrams_bore_1_ram_hold     (sigFromSrams_bore_29_ram_hold),
    .sigFromSrams_bore_1_ram_bypass   (sigFromSrams_bore_29_ram_bypass),
    .sigFromSrams_bore_1_ram_bp_clken (sigFromSrams_bore_29_ram_bp_clken),
    .sigFromSrams_bore_1_ram_aux_clk  (sigFromSrams_bore_29_ram_aux_clk),
    .sigFromSrams_bore_1_ram_aux_ckbp (sigFromSrams_bore_29_ram_aux_ckbp),
    .sigFromSrams_bore_1_ram_mcp_hold (sigFromSrams_bore_29_ram_mcp_hold),
    .sigFromSrams_bore_1_cgen         (sigFromSrams_bore_29_cgen),
    .sigFromSrams_bore_2_ram_hold     (sigFromSrams_bore_30_ram_hold),
    .sigFromSrams_bore_2_ram_bypass   (sigFromSrams_bore_30_ram_bypass),
    .sigFromSrams_bore_2_ram_bp_clken (sigFromSrams_bore_30_ram_bp_clken),
    .sigFromSrams_bore_2_ram_aux_clk  (sigFromSrams_bore_30_ram_aux_clk),
    .sigFromSrams_bore_2_ram_aux_ckbp (sigFromSrams_bore_30_ram_aux_ckbp),
    .sigFromSrams_bore_2_ram_mcp_hold (sigFromSrams_bore_30_ram_mcp_hold),
    .sigFromSrams_bore_2_cgen         (sigFromSrams_bore_30_cgen),
    .sigFromSrams_bore_3_ram_hold     (sigFromSrams_bore_31_ram_hold),
    .sigFromSrams_bore_3_ram_bypass   (sigFromSrams_bore_31_ram_bypass),
    .sigFromSrams_bore_3_ram_bp_clken (sigFromSrams_bore_31_ram_bp_clken),
    .sigFromSrams_bore_3_ram_aux_clk  (sigFromSrams_bore_31_ram_aux_clk),
    .sigFromSrams_bore_3_ram_aux_ckbp (sigFromSrams_bore_31_ram_aux_ckbp),
    .sigFromSrams_bore_3_ram_mcp_hold (sigFromSrams_bore_31_ram_mcp_hold),
    .sigFromSrams_bore_3_cgen         (sigFromSrams_bore_31_cgen)
  );

endmodule
// END GENERATED
