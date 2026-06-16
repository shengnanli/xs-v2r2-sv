// =============================================================================
//  loadunit_pkg —— LoadUnit 可读重写所用的类型 / 常量 / 纯函数
// -----------------------------------------------------------------------------
//  本包集中表达 LoadUnit 的「设计词汇」：
//    * typedef enum  ：S0 的 8 个数据来源、11 个 replay cause（与 Scala 的
//                       LoadReplayCauses 编号一一对应）。
//    * typedef struct：load uop 公共字段、各级流水寄存器（S0/S1/S2/S3）、
//                       forward 查询/结果。
//    * function automatic：vaddr 生成、对齐/错位、byte-mask、数据 byte-mux/扩展、
//                       forward 逐字节合并、异常与冲刷判定。
//  设计意图来源：src/main/scala/xiangshan/mem/pipeline/LoadUnit.scala
//                src/main/scala/xiangshan/mem/lsqueue/LoadQueue.scala (HasLoadHelper)
//                src/main/scala/xiangshan/mem/lsqueue/LoadQueueReplay.scala (LoadReplayCauses)
// =============================================================================
package loadunit_pkg;

  // ---- 关键位宽（与香山 KunmingHu V2R2 配置一致）-----------------------------
  localparam int VADDR_BITS  = 50;  // 虚地址位宽
  localparam int PADDR_BITS  = 48;  // 物理地址位宽
  localparam int XLEN        = 64;  // 标量寄存器位宽
  localparam int VLEN        = 128; // 向量寄存器位宽
  localparam int MASK_BITS   = 16;  // 字节 mask = VLEN/8
  localparam int FWD_BYTES   = 16;  // forward 逐字节合并宽度 = VLEN/8

  // ---- 异常向量编号（ExceptionVec 中本单元关心的位）--------------------------
  localparam int EXC_LAM  = 4;   // load addr misaligned
  localparam int EXC_LAF  = 5;   // load access fault
  localparam int EXC_BP   = 3;   // breakpoint（trigger 产生）
  localparam int EXC_LPF  = 13;  // load page fault
  localparam int EXC_HWE  = 19;  // hardware error（ecc/bus）
  localparam int EXC_LGPF = 21;  // load guest page fault

  // ---- 对齐类型（alignType / fuOpType[1:0]）---------------------------------
  localparam logic [1:0] SZ_BYTE  = 2'h0;
  localparam logic [1:0] SZ_HALF  = 2'h1;
  localparam logic [1:0] SZ_WORD  = 2'h2;
  localparam logic [1:0] SZ_DWORD = 2'h3;

  // ---- pbmt（page-based memory type）编码 -----------------------------------
  localparam logic [1:0] PBMT_NONE = 2'h0;
  localparam logic [1:0] PBMT_NC   = 2'h1; // non-cacheable
  localparam logic [1:0] PBMT_IO   = 2'h2; // strong-order IO（mmio）

  // ---- DCache / TLB 命令编码 ------------------------------------------------
  localparam logic [4:0] M_XRD = 5'h0;  // load
  localparam logic [4:0] M_PFR = 5'h13; // prefetch read
  localparam logic [4:0] M_PFW = 5'h14; // prefetch write
  localparam logic [2:0] TLB_READ = 3'h0;
  localparam logic [3:0] DCACHE_LOAD_SOURCE = 4'h0;
  localparam logic [3:0] DCACHE_PF_SOURCE   = 4'h2;

  // ---------------------------------------------------------------------------
  //  S0 数据来源（8 个真实来源 + prefetch/l2l）。
  //  优先级 高->低（与 Scala 的 s0_src_select_vec 固定优先级独热一致）：
  //    misalign 重发 > super-replay(tlD) > fast-replay > mmio > nc >
  //    lsq-replay > high-conf-prefetch > vec-issue > int-issue >
  //    l2l-fwd > low-conf-prefetch
  //  注：本配置 EnableLoadToLoadForward=false，l2l 源恒无效（golden 已裁剪相关端口）。
  // ---------------------------------------------------------------------------
  typedef enum logic [3:0] {
    SRC_MISALIGN  = 4'd0,  // io_misalign_ldin —— misalignBuffer 拆分重发
    SRC_SUPER_REP = 4'd1,  // io_replay (forward_tlDchannel) —— cache-miss 超级重放
    SRC_FAST_REP  = 4'd2,  // io_fast_rep_in —— 快速重放
    SRC_MMIO      = 4'd3,  // io_lsq_uncache —— mmio 回灌
    SRC_NC        = 4'd4,  // io_lsq_nc_ldin —— non-cacheable（带数据）
    SRC_LSQ_REP   = 4'd5,  // io_replay (普通) —— LSQ 重放
    SRC_HIGH_PF   = 4'd6,  // io_prefetch_req (confidence>0) —— 高置信硬件预取
    SRC_VEC_ISS   = 4'd7,  // io_vecldin —— 向量发射
    SRC_INT_ISS   = 4'd8,  // io_ldin —— 标量发射 / 软件预取（首发，自己算地址）
    SRC_L2L_FWD   = 4'd9,  // io_l2l_fwd_in —— load-to-load 前递（本配置禁用）
    SRC_LOW_PF    = 4'd10  // io_prefetch_req (confidence==0) —— 低置信硬件预取
  } ld_src_e;
  localparam int SRC_NUM = 11;

  // ---------------------------------------------------------------------------
  //  Replay cause（11 个，与 LoadReplayCauses 的 C_* 编号严格一致）。
  //  S3 用优先级编码器从中选出唯一原因回灌 LoadQueueReplay。
  // ---------------------------------------------------------------------------
  localparam int C_MA  = 0;   // memory ambiguous（store-set 命中但地址未定）
  localparam int C_TM  = 1;   // tlb miss
  localparam int C_FF  = 2;   // forward fail（forward 数据未定）
  localparam int C_DR  = 3;   // dcache replay（missQueue nack）
  localparam int C_DM  = 4;   // dcache miss
  localparam int C_WF  = 5;   // way-predictor fail
  localparam int C_BC  = 6;   // bank conflict
  localparam int C_RAR = 7;   // read-after-read nack（LQRAR 满）
  localparam int C_RAW = 8;   // read-after-write nack（LQRAW 满）
  localparam int C_NK  = 9;   // nuke（store->load 违例）
  localparam int C_MF  = 10;  // misalign buffer nack
  localparam int CAUSE_NUM = 11;

  // ===========================================================================
  //  纯函数区
  // ===========================================================================

  // ---- 环形 RobIdx 冲刷判定（与 StoreUnit 同源）----------------------------
  //   level=1（异常型冲刷）：只冲刷与 redirect 同一条；
  //   否则（分支误预测型）：冲刷排在 redirect 之后的所有条（环形大小比较）。
  function automatic logic rob_need_flush(
      input logic       redir_valid,
      input logic       redir_level,
      input logic       self_flag,
      input logic [7:0] self_value,
      input logic       redir_flag,
      input logic [7:0] redir_value);
    logic flush_itself, flush_after;
    flush_itself = redir_level & (self_flag == redir_flag) & (self_value == redir_value);
    flush_after  = self_flag ^ redir_flag ^ (self_value > redir_value);
    return redir_valid & (flush_itself | flush_after);
  endfunction

  // 是否“self 比 other 更年轻”（isAfter）：环形比较，self 在 other 之后。
  function automatic logic rob_is_after(
      input logic self_flag, input logic [7:0] self_value,
      input logic other_flag, input logic [7:0] other_value);
    return self_flag ^ other_flag ^ (self_value > other_value);
  endfunction

  function automatic logic lq_is_after(
      input logic self_flag, input logic [6:0] self_value,
      input logic other_flag, input logic [6:0] other_value);
    return self_flag ^ other_flag ^ (self_value > other_value);
  endfunction

  // ---- 标量地址生成：saddr = src0[49:0] + sext(imm12) ----------------------
  function automatic logic [VADDR_BITS-1:0] gen_vaddr(
      input logic [63:0] src0, input logic [11:0] imm12);
    return VADDR_BITS'(src0[VADDR_BITS-1:0] + {{(VADDR_BITS-12){imm12[11]}}, imm12});
  endfunction

  // ---- 对齐判定：byte 恒对齐；half 看 bit0；word 看[1:0]；dword 看[2:0] -----
  function automatic logic addr_aligned(input logic [1:0] sz, input logic [VADDR_BITS-1:0] va);
    unique case (sz)
      SZ_BYTE:  return 1'b1;
      SZ_HALF:  return (va[0]    == 1'b0);
      SZ_WORD:  return (va[1:0]  == 2'h0);
      SZ_DWORD: return (va[2:0]  == 3'h0);
      default:  return 1'b1;
    endcase
  endfunction

  // ---- 字节 mask 生成：按 fuOpType[1:0] size 生成 1/2/4/8 字节连续 mask，
  //      再左移到 vaddr[3:0] 字节偏移（genVWmask 语义）。----------------------
  function automatic logic [MASK_BITS-1:0] gen_vwmask(
      input logic [VADDR_BITS-1:0] va, input logic [1:0] sz);
    logic [MASK_BITS-1:0] base;
    unique case (sz)
      SZ_BYTE:  base = 16'h0001;
      SZ_HALF:  base = 16'h0003;
      SZ_WORD:  base = 16'h000F;
      SZ_DWORD: base = 16'h00FF;
      default:  base = 16'h0001;
    endcase
    return MASK_BITS'(base << va[3:0]);
  endfunction

  // ---- genRdataOH：按 fuOpType/fpWen 生成 9 位数据扩展选择独热 -------------
  //   位序与 newRdataHelper 的 selData 对齐：
  //   [0]=zext8 [1]=zext16 [2]=zext32 [3]=raw64 [4]=sext8 [5]=sext16
  //   [6]=sext32 [7]=fp-box-H [8]=fp-box-S
  //   fuOpType 取低 4 位即可区分 lb/lh/lw/ld/lbu/lhu/lwu（与 LSUOpType 对齐）。
  function automatic logic [8:0] gen_rdata_oh(input logic [8:0] fuOpType, input logic fpWen);
    logic is_lb, is_lh, is_lw, is_ld, is_lbu, is_lhu, is_lwu;
    logic is_hlvb, is_hlvh, is_hlvw, is_hlvd, is_hlvbu, is_hlvhu, is_hlvwu;
    logic is_hlvxhu, is_hlvxwu;
    // LSUOpType 全 9 位精确比对（与 golden `fuOpType == 9'hN` 一致）。
    //   ld 系 = 9'h0..9'h6；hlv 系 = 9'h10..9'h16/9'h1D/9'h1E
    is_lb  = (fuOpType == 9'h0);
    is_lh  = (fuOpType == 9'h1);
    is_lw  = (fuOpType == 9'h2);
    is_ld  = (fuOpType == 9'h3);
    is_lbu = (fuOpType == 9'h4);
    is_lhu = (fuOpType == 9'h5);
    is_lwu = (fuOpType == 9'h6);
    is_hlvb  = (fuOpType == 9'h10);
    is_hlvh  = (fuOpType == 9'h11);
    is_hlvw  = (fuOpType == 9'h12);
    is_hlvd  = (fuOpType == 9'h13);
    is_hlvbu = (fuOpType == 9'h14);
    is_hlvhu = (fuOpType == 9'h15);
    is_hlvwu = (fuOpType == 9'h16);
    is_hlvxhu = (fuOpType == 9'h1D);
    is_hlvxwu = (fuOpType == 9'h1E);
    return {
      (is_lw & fpWen),                              // [8] fp-box S
      (is_lh & fpWen),                              // [7] fp-box H
      (is_lw & ~fpWen) | is_hlvw,                   // [6] sext32
      (is_lh & ~fpWen) | is_hlvh,                   // [5] sext16
      is_lb | is_hlvb,                              // [4] sext8
      is_ld | is_hlvd,                              // [3] raw64
      is_lwu | is_hlvwu | is_hlvxwu,                // [2] zext32
      is_lhu | is_hlvhu | is_hlvxhu,                // [1] zext16
      is_lbu | is_hlvbu                             // [0] zext8
    };
  endfunction

  // ---- newRdataHelper：按 9 位独热把选中的 picked 数据扩展到 64 位 ---------
  function automatic logic [XLEN-1:0] new_rdata(input logic [8:0] sel, input logic [63:0] rdata);
    logic [XLEN-1:0] r;
    r = '0;
    if (sel[0]) r |= {56'h0, rdata[7:0]};                       // zext8
    if (sel[1]) r |= {48'h0, rdata[15:0]};                      // zext16
    if (sel[2]) r |= {32'h0, rdata[31:0]};                      // zext32
    if (sel[3]) r |= rdata[63:0];                               // raw64
    if (sel[4]) r |= {{56{rdata[7]}},  rdata[7:0]};             // sext8
    if (sel[5]) r |= {{48{rdata[15]}}, rdata[15:0]};            // sext16
    if (sel[6]) r |= {{32{rdata[31]}}, rdata[31:0]};            // sext32
    if (sel[7]) r |= {{48{1'b1}}, rdata[15:0]};                 // fp-box H（高位补 1）
    if (sel[8]) r |= {{32{1'b1}}, rdata[31:0]};                 // fp-box S（高位补 1）
    return r;
  endfunction

  // ---- rdataHelper：mmio 路径按 fuOpType 直接 LookupTree 扩展（无 fp-box H）-
  function automatic logic [XLEN-1:0] rdata_helper(
      input logic [8:0] fuOpType, input logic fpWen, input logic [63:0] rdata);
    unique case (fuOpType[3:0])
      4'h0: return {{56{rdata[7]}},  rdata[7:0]};                       // lb
      4'h1: return {{48{rdata[15]}}, rdata[15:0]};                      // lh
      4'h2: return fpWen ? {{32{1'b1}}, rdata[31:0]} : {{32{rdata[31]}}, rdata[31:0]}; // lw
      4'h3: return rdata[63:0];                                          // ld
      4'h4: return {56'h0, rdata[7:0]};                                 // lbu
      4'h5: return {48'h0, rdata[15:0]};                                // lhu
      4'h6: return {32'h0, rdata[31:0]};                                // lwu
      default: return rdata[63:0];
    endcase
  endfunction

  // ---- genDataSelectByOffset：paddr[3:0] -> 16 位独热（选择数据窗口起始字节）---
  function automatic logic [FWD_BYTES-1:0] gen_data_select_by_offset(input logic [3:0] off);
    logic [FWD_BYTES-1:0] oh;
    oh = '0;
    oh[off] = 1'b1;
    return oh;
  endfunction

  // ---- pick_data_window：从 128 位合并数据按字节偏移 off 取 64 位窗口 ---------
  //   与 golden s3_data_frm_pipe + Mux1H(s3_data_select_by_offset) 等价：
  //   窗口 [off*8 +: 64]，超出 127 位的高位用 bit127 截断（即取 merged[127:off*8]）。
  //   off<=8 时是完整 64 位；off>8 时高位自然只剩 (128-off*8) 位（高位补 0，与
  //   golden 的 s3_merged_data_frm_pipe(127, off*8) 行为一致——上层 newRdata 只取
  //   低位有效字节，故高位补 0 不影响最终结果）。
  function automatic logic [63:0] pick_data_window(
      input logic [127:0] merged, input logic [3:0] off);
    logic [127:0] sh;
    sh = merged >> ({3'h0, off} << 3);  // 右移 off 字节
    return sh[63:0];
  endfunction

  // ---- mmio 数据按 addrOffset(3 位字节偏移) 右移取 64 位 -------------------
  //   与 golden s3_picked_data_frm_mmio 一致：lqData >> (addrOffset*8)，高位补 0。
  function automatic logic [63:0] pick_mmio_window(
      input logic [63:0] lqData, input logic [2:0] off);
    return lqData >> ({3'h0, off} << 3);
  endfunction

  // ---- mmio 路径数据扩展（与 golden io_ldout_bits_data 的 mmio 分支精确一致）---
  //   覆盖 ld 系 9'h0..6 与 hlv 系 9'h10..16 / 9'h1D(hlvxhu) / 9'h1E(hlvxwu)。
  //   hlvxhu/hlvxwu 为零扩展（区别于 rdata_helper 的 default raw64），故单列。
  function automatic logic [XLEN-1:0] mmio_rdata(
      input logic [8:0] fuOpType, input logic fpWen, input logic [63:0] picked);
    unique case (fuOpType)
      9'h0, 9'h10: return {{56{picked[7]}},  picked[7:0]};                       // lb / hlvb
      9'h1, 9'h11: return {{48{picked[15]}}, picked[15:0]};                      // lh / hlvh
      9'h2:        return fpWen ? {32'hFFFFFFFF, picked[31:0]} : {{32{picked[31]}}, picked[31:0]}; // lw
      9'h12:       return {{32{picked[31]}}, picked[31:0]};                      // hlvw
      9'h3, 9'h13: return picked[63:0];                                          // ld / hlvd
      9'h4, 9'h14: return {56'h0, picked[7:0]};                                  // lbu / hlvbu
      9'h5, 9'h15, 9'h1D: return {48'h0, picked[15:0]};                          // lhu / hlvhu / hlvxhu
      9'h6, 9'h16, 9'h1E: return {32'h0, picked[31:0]};                          // lwu / hlvwu / hlvxwu
      default:     return 64'h0;
    endcase
  endfunction

  // ---- rdataVecHelper：向量按 alignedType[1:0] 零扩展到 VLEN ----------------
  function automatic logic [VLEN-1:0] rdata_vec(input logic [1:0] at, input logic [63:0] rdata);
    unique case (at)
      SZ_BYTE:  return {120'h0, rdata[7:0]};
      SZ_HALF:  return {112'h0, rdata[15:0]};
      SZ_WORD:  return {96'h0,  rdata[31:0]};
      SZ_DWORD: return {64'h0,  rdata[63:0]};
      default:  return {64'h0,  rdata[63:0]};
    endcase
  endfunction

endpackage
