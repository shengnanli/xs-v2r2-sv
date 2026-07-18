// 本文件由 scripts/gen_loadunit.py 拼接进 LoadUnit.sv（位于端口表之后），勿单独编译。
// =============================================================================
//  可读核 xs_LoadUnit_core 主体 —— 从 LoadUnit.scala 设计意图重写
// -----------------------------------------------------------------------------
//  四级流水（与 Scala 一致）：
//    S0  源仲裁（8 源固定优先级独热）+ 地址生成 vaddr=src0+sext(imm) + 对齐/mask
//        + 并发发起 DTLB / DCache 请求 + load 唤醒（wakeup）
//    S1  收 TLB paddr/异常 + 发 forward 查询（SBuffer/StoreQueue/MSHR/tlD）
//        + 例化 MemTrigger 断点匹配 + 第一次 nuke 探测 + 写 ldld/stld nuke 查询准备
//    S2  收 DCache resp + 合并 16 路 forward + nuke（store->load 违例）+ 算 11 位
//        replay cause + uncache/mmio 判定 + 合并异常 + 选数据扩展独热
//    S3  数据按 16-way offset 选字节 + 按 9 路独热扩展 + 写回 ldout/vecldout
//        + 回灌 LoadQueue（replay）+ rollback + feedback
//
//  本配置 EnableLoadToLoadForward=false：l2l 前递源恒无效，golden 已裁剪相关端口，
//  故 s2_ptr_chasing / l2l_fwd_out / fast_uop 等不存在。
// =============================================================================
  import loadunit_pkg::*;

  // 三级流水握手（s1/s2/s3 是否可接收上一级）。s2_ready/s3_ready 见 S2/S3 段实现。
  logic s1_ready, s2_ready, s3_ready;

  // ===========================================================================
  //  S0 —— 源仲裁 + 地址生成 + mask + 对齐 + DTLB/DCache 请求
  // ===========================================================================
  // 11 个来源的 valid（与 ld_src_e 编号一致）。l2l(9) 本配置恒 0。
  logic [SRC_NUM-1:0] s0_src_valid;
  assign s0_src_valid[SRC_MISALIGN ] = io_misalign_ldin_valid;
  assign s0_src_valid[SRC_SUPER_REP] = io_replay_valid & io_replay_bits_forward_tlDchannel;
  assign s0_src_valid[SRC_FAST_REP ] = io_fast_rep_in_valid;
  assign s0_src_valid[SRC_MMIO     ] = io_lsq_uncache_valid;
  assign s0_src_valid[SRC_NC       ] = io_lsq_nc_ldin_valid;
  // lsq 普通重放：非 tlD 通道，且未被 rep_stall（更年轻的发射存在时让位）
  // s0_rep_stall：int/vec 发射的 lqIdx 比 replay 更老时，replay 让位
  logic s0_rep_stall;
  assign s0_rep_stall =
      (io_ldin_valid    & lq_is_after(io_replay_bits_uop_lqIdx_flag, io_replay_bits_uop_lqIdx_value,
                                      io_ldin_bits_uop_lqIdx_flag,   io_ldin_bits_uop_lqIdx_value)) |
      (io_vecldin_valid & lq_is_after(io_replay_bits_uop_lqIdx_flag, io_replay_bits_uop_lqIdx_value,
                                      io_vecldin_bits_uop_lqIdx_flag, io_vecldin_bits_uop_lqIdx_value));
  assign s0_src_valid[SRC_LSQ_REP  ] = io_replay_valid & ~io_replay_bits_forward_tlDchannel & ~s0_rep_stall;
  assign s0_src_valid[SRC_HIGH_PF  ] = io_prefetch_req_valid & io_prefetch_req_bits_confidence;
  assign s0_src_valid[SRC_VEC_ISS  ] = io_vecldin_valid;
  assign s0_src_valid[SRC_INT_ISS  ] = io_ldin_valid;
  assign s0_src_valid[SRC_L2L_FWD  ] = 1'b0;
  assign s0_src_valid[SRC_LOW_PF   ] = io_prefetch_req_valid & ~io_prefetch_req_bits_confidence;

  // 固定优先级独热：src i 被选中 = valid[i] 且更高优先级全无效。
  // ready[i] = 高优先级都没有；select[i] = valid[i] & ready[i]。用 for 表达。
  logic [SRC_NUM-1:0] s0_src_ready, s0_src_select;
  always_comb begin
    logic higher;
    higher = 1'b0;
    for (int i = 0; i < SRC_NUM; i++) begin
      s0_src_ready[i]  = ~higher;
      s0_src_select[i] = s0_src_valid[i] & ~higher;
      higher = higher | s0_src_valid[i];
    end
  end

  logic s0_hw_prf_select;
  assign s0_hw_prf_select = s0_src_select[SRC_HIGH_PF] | s0_src_select[SRC_LOW_PF];

  // 选择条件别名（对应 golden _s0_sel_src_T / _T_6 / _T_10 / selector_5/6）
  //   T   = misalign | super_rep；T6 = T | fast | uncache | nc；
  //   s5  = lsq_rep(普通重放，含 ~rep_stall)；s6 = high_pf；T10 = s5 | s6 | vec
  logic s0_x_T, s0_x_T6, s0_x_T10, s0_x_s5, s0_x_s6;
  assign s0_x_T   = io_misalign_ldin_valid | s0_src_valid[SRC_SUPER_REP];
  assign s0_x_T6  = s0_x_T | io_fast_rep_in_valid | io_lsq_uncache_valid | io_lsq_nc_ldin_valid;
  assign s0_x_s5  = s0_src_valid[SRC_LSQ_REP];
  assign s0_x_s6  = s0_src_valid[SRC_HIGH_PF];
  assign s0_x_T10 = s0_x_s5 | s0_x_s6 | io_vecldin_valid;

  // ---- 合流后的 FlowSource（按优先级 mux 选出本拍 uop / 控制位）------------
  // 各来源的 prf 相关标志：只有 fast_rep / lsq_rep / int_iss 来源可能是 prefetch。
  logic s0_sel_prf, s0_sel_prf_rd, s0_sel_prf_wr, s0_sel_prf_i;
  logic s0_sel_isvec, s0_sel_is128bit, s0_sel_frm_mabuf, s0_sel_isnc;
  logic s0_sel_fast_rep, s0_sel_ld_rep, s0_sel_has_rob, s0_sel_first_issue, s0_sel_vecActive;

  // fuOpType（合流）：misalign>fast>mmio>nc>replay>vec>int>prefetch(=ld)
  logic [8:0] s0_sel_fuOpType;
  always_comb begin
    priority case (1'b1)
      s0_src_select[SRC_MISALIGN ]: s0_sel_fuOpType = io_misalign_ldin_bits_uop_fuOpType;
      s0_src_select[SRC_FAST_REP ]: s0_sel_fuOpType = io_fast_rep_in_bits_uop_fuOpType;
      s0_src_select[SRC_MMIO     ]: s0_sel_fuOpType = io_lsq_uncache_bits_uop_fuOpType;
      s0_src_select[SRC_NC       ]: s0_sel_fuOpType = io_lsq_nc_ldin_bits_uop_fuOpType;
      s0_src_select[SRC_SUPER_REP],
      s0_src_select[SRC_LSQ_REP  ]: s0_sel_fuOpType = io_replay_bits_uop_fuOpType;
      s0_src_select[SRC_VEC_ISS  ]: s0_sel_fuOpType = io_vecldin_bits_uop_fuOpType;
      s0_src_select[SRC_INT_ISS  ]: s0_sel_fuOpType = io_ldin_bits_uop_fuOpType;
      default:                      s0_sel_fuOpType = 9'h0;  // prefetch 流当作 ld(0)
    endcase
  end

  // prefetch 判定：fast_rep / lsq_rep / int 来源依 fuOpType 判 prefetch；硬件预取来源恒 prf。
  // isPrefetch(op) = op[3] & op[5:4]==00 & op[8:7]==00
  function automatic logic is_prefetch_op(input logic [8:0] op);
    return op[3] & (op[5:4] == 2'h0) & (op[8:7] == 2'h0);
  endfunction
  // prf / prf_rd / prf_wr / prf_i：完全按 golden 的原始 valid 嵌套优先 mux。
  //   注意末端 fallback（无 T6/T10 源时）：低置信硬件预取走 io_prefetch_req_bits_is_store。
  logic s0_rep_prf_rd, s0_rep_prf_wr;  // replay 来源预取读/写（fuOpType==9/A）
  assign s0_rep_prf_rd = (io_replay_bits_uop_fuOpType == 9'h9);
  assign s0_rep_prf_wr = (io_replay_bits_uop_fuOpType == 9'hA);
  assign s0_sel_prf =
      s0_x_T6 ? (s0_x_T ? (~io_misalign_ldin_valid & is_prefetch_op(io_replay_bits_uop_fuOpType) & ~io_replay_bits_isvec)
                 : (io_fast_rep_in_valid & is_prefetch_op(io_fast_rep_in_bits_uop_fuOpType) & ~io_fast_rep_in_bits_isvec))
              : s0_x_T10 ? (s0_x_s5 ? (is_prefetch_op(io_replay_bits_uop_fuOpType) & ~io_replay_bits_isvec) : s0_x_s6)
                         : (~io_ldin_valid | is_prefetch_op(io_ldin_bits_uop_fuOpType));
  assign s0_sel_prf_rd =
      s0_x_T6 ? (s0_x_T ? (~io_misalign_ldin_valid & s0_rep_prf_rd)
                 : (io_fast_rep_in_valid & (io_fast_rep_in_bits_uop_fuOpType == 9'h9)))
              : s0_x_T10 ? (s0_x_s5 ? s0_rep_prf_rd : (s0_x_s6 & ~io_prefetch_req_bits_is_store))
                         : (io_ldin_valid ? (io_ldin_bits_uop_fuOpType == 9'h9) : ~io_prefetch_req_bits_is_store);
  assign s0_sel_prf_wr =
      s0_x_T6 ? (s0_x_T ? (~io_misalign_ldin_valid & s0_rep_prf_wr)
                 : (io_fast_rep_in_valid & (io_fast_rep_in_bits_uop_fuOpType == 9'hA)))
              : s0_x_T10 ? (s0_x_s5 ? s0_rep_prf_wr : (s0_x_s6 & io_prefetch_req_bits_is_store))
                         : (io_ldin_valid ? (io_ldin_bits_uop_fuOpType == 9'hA) : io_prefetch_req_bits_is_store);
  assign s0_sel_prf_i = ~(s0_x_T6 | s0_x_T10) & io_ldin_valid & (io_ldin_bits_uop_fuOpType == 9'h8);

  // isvec / is128bit / frm_mabuf / isnc / 其它合流控制
  assign s0_sel_isvec =
      (s0_src_select[SRC_MISALIGN] & io_misalign_ldin_bits_isvec) |
      (s0_src_select[SRC_FAST_REP] & io_fast_rep_in_bits_isvec)   |
      ((s0_src_select[SRC_SUPER_REP] | s0_src_select[SRC_LSQ_REP]) & io_replay_bits_isvec) |
      (s0_src_select[SRC_NC]      & io_lsq_nc_ldin_bits_isvec)     |
      s0_src_select[SRC_VEC_ISS];
  // frm_mabuf：misalign 来源；或 fast-replay 来源且其本身来自 misalignBuffer
  //   (与 golden s0_sel_src_frm_mabuf = T6 & (T? mis_v : fast_v & fast.isFrmMisAlignBuf) 一致)
  assign s0_sel_frm_mabuf =
      s0_x_T6 & (s0_x_T ? io_misalign_ldin_valid
                        : (io_fast_rep_in_valid & io_fast_rep_in_bits_isFrmMisAlignBuf));
  assign s0_sel_isnc =
      (s0_src_select[SRC_FAST_REP] & io_fast_rep_in_bits_nc) | s0_src_select[SRC_NC];
  assign s0_sel_fast_rep = s0_src_select[SRC_FAST_REP];
  assign s0_sel_ld_rep   = (s0_src_select[SRC_SUPER_REP] | s0_src_select[SRC_LSQ_REP]) |
                           (s0_src_select[SRC_FAST_REP] & io_fast_rep_in_bits_isLoadReplay);
  assign s0_sel_has_rob  = s0_src_select[SRC_SUPER_REP] | s0_src_select[SRC_LSQ_REP] |
                           s0_src_select[SRC_NC] | s0_src_select[SRC_VEC_ISS] |
                           s0_src_select[SRC_INT_ISS] |
                           (s0_src_select[SRC_FAST_REP] & io_fast_rep_in_bits_hasROBEntry);
  assign s0_sel_first_issue = s0_src_select[SRC_INT_ISS];
  // 合流 vecActive（与 golden s0_sel_src_vecActive 一致，含末端 fallback=io_ldin_valid）：
  //   T6?(T?(mis_v|R.vecAct):fast?F:(unc_v|N.vecAct)):(T10?(s5?R:~s6 & V):io_ldin_valid)
  assign s0_sel_vecActive =
      s0_x_T6 ? (s0_x_T ? (io_misalign_ldin_valid | io_replay_bits_vecActive)
                 : io_fast_rep_in_valid ? io_fast_rep_in_bits_vecActive
                   : (io_lsq_uncache_valid | io_lsq_nc_ldin_bits_vecActive))
              : s0_x_T10 ? (s0_x_s5 ? io_replay_bits_vecActive : (~s0_x_s6 & io_vecldin_bits_vecActive))
                         : io_ldin_valid;

  // ---- 地址 / 对齐 ----------------------------------------------------------
  // int 发射地址自己算；vec 取 vaddr 低 50 位
  logic [VADDR_BITS-1:0] s0_int_vaddr, s0_tlb_vaddr, s0_dcache_vaddr;
  assign s0_int_vaddr = gen_vaddr(io_ldin_bits_src_0, io_ldin_bits_uop_imm[11:0]);
  // s0_tlb_vaddr：misalign>replay>vec/int
  always_comb begin
    if (s0_src_valid[SRC_MISALIGN])       s0_tlb_vaddr = io_misalign_ldin_bits_vaddr;
    else if (s0_src_valid[SRC_SUPER_REP] | s0_src_valid[SRC_LSQ_REP])
                                          s0_tlb_vaddr = io_replay_bits_vaddr;
    else if (s0_src_valid[SRC_VEC_ISS])   s0_tlb_vaddr = io_vecldin_bits_vaddr[VADDR_BITS-1:0];
    else                                  s0_tlb_vaddr = s0_int_vaddr;
  end
  // s0_dcache_vaddr：fast_rep>prefetch>nc>tlb_vaddr
  // 硬件预取的 getVaddr = {36'h0, alias[1:0], paddr[11:0]}（仅低 14 位有效）
  always_comb begin
    if (s0_src_select[SRC_FAST_REP])      s0_dcache_vaddr = io_fast_rep_in_bits_vaddr;
    else if (s0_hw_prf_select)            s0_dcache_vaddr = {36'h0, io_prefetch_req_bits_alias, io_prefetch_req_bits_paddr[11:0]};
    else if (s0_src_select[SRC_NC])       s0_dcache_vaddr = io_lsq_nc_ldin_bits_vaddr;
    else                                  s0_dcache_vaddr = s0_tlb_vaddr;
  end

  // alignType：vec 取 alignedType[1:0]，否则 fuOpType[1:0]
  logic [2:0] s0_alignedType;
  assign s0_alignedType =
      s0_src_select[SRC_MISALIGN] ? 3'h0 :
      s0_src_select[SRC_FAST_REP] ? io_fast_rep_in_bits_alignedType :
      (s0_src_select[SRC_SUPER_REP] | s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_alignedType :
      s0_src_select[SRC_VEC_ISS]  ? io_vecldin_bits_alignedType : 3'h0;
  logic [1:0] s0_alignType;
  assign s0_alignType = s0_sel_isvec ? s0_alignedType[1:0] : s0_sel_fuOpType[1:0];

  logic s0_addr_aligned;
  assign s0_addr_aligned = addr_aligned(s0_alignType, s0_dcache_vaddr);

  // 跨 16B 判定：vaddr[4:0] + (size-1) 看 bit4 是否翻转
  logic [4:0] s0_check_lo, s0_check_up;
  logic [2:0] s0_size_m1;
  always_comb begin
    priority case (s0_alignType)
      SZ_BYTE:  s0_size_m1 = 3'h0;
      SZ_HALF:  s0_size_m1 = 3'h1;
      SZ_WORD:  s0_size_m1 = 3'h3;
      SZ_DWORD: s0_size_m1 = 3'h7;
      default:  s0_size_m1 = 3'h0;
    endcase
  end
  assign s0_check_lo = s0_dcache_vaddr[4:0];
  assign s0_check_up = 5'(s0_check_lo + {2'h0, s0_size_m1});
  logic s0_cross16, s0_misalignWith16Byte, s0_is128bit;
  assign s0_cross16 = (s0_check_up[4] != s0_check_lo[4]);
  assign s0_misalignWith16Byte = ~s0_cross16 & ~s0_addr_aligned & ~s0_hw_prf_select;
  assign s0_is128bit =
      (s0_src_select[SRC_MISALIGN] & io_misalign_ldin_bits_is128bit) |
      (s0_src_select[SRC_FAST_REP] & io_fast_rep_in_bits_is128bit)   |
      ((s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) & io_replay_bits_is128bit) |
      (s0_src_select[SRC_NC]       & io_lsq_nc_ldin_bits_is128bit)   |
      (s0_src_select[SRC_VEC_ISS]  & is128_alignedtype(io_vecldin_bits_alignedType)) |
      s0_misalignWith16Byte;

  function automatic logic is128_alignedtype(input logic [2:0] at);
    return at[2]; // unit-stride 128bit
  endfunction

  // ---- mask ----------------------------------------------------------------
  // misalign/nc/replay(vec) 来源 mask 已给；否则按 vaddr+size 生成
  logic [MASK_BITS-1:0] s0_sel_mask;
  always_comb begin
    if (s0_src_select[SRC_MISALIGN])           s0_sel_mask = io_misalign_ldin_bits_mask;
    else if (s0_src_select[SRC_VEC_ISS])       s0_sel_mask = io_vecldin_bits_mask;
    else if (s0_src_select[SRC_NC])            s0_sel_mask = gen_vwmask(io_lsq_nc_ldin_bits_vaddr, io_lsq_nc_ldin_bits_uop_fuOpType[1:0]);
    else if (s0_src_select[SRC_SUPER_REP] | s0_src_select[SRC_LSQ_REP])
      s0_sel_mask = io_replay_bits_isvec ? io_replay_bits_mask : gen_vwmask(io_replay_bits_vaddr, io_replay_bits_uop_fuOpType[1:0]);
    else if (s0_src_select[SRC_FAST_REP])      s0_sel_mask = io_fast_rep_in_bits_mask;
    else if (s0_src_select[SRC_INT_ISS])       s0_sel_mask = gen_vwmask(s0_int_vaddr, io_ldin_bits_uop_fuOpType[1:0]);
    else                                       s0_sel_mask = 16'h0;
  end

  // ---- nc-with-data / kill / fire ------------------------------------------
  logic s0_kill, s0_can_go, s0_valid, s0_fire, s0_mmio_select, s0_nc_select;
  logic s0_mmio_fire, s0_nc_fire, s0_misalign_select, s0_misalign_wakeup_fire, s0_nc_with_data;
  assign s0_kill = 1'b0;                     // l2l 关闭：无 ptr_chasing cancel
  assign s0_can_go = s1_ready;
  // tlb 不查询：硬件预取 / prefetch.i / fast_rep / mmio / nc
  logic s0_tlb_no_query;
  assign s0_tlb_no_query = s0_hw_prf_select | s0_sel_prf_i |
                           s0_src_select[SRC_FAST_REP] | s0_src_select[SRC_MMIO] | s0_src_select[SRC_NC];
  assign s0_misalign_wakeup_fire = s0_misalign_select & s0_can_go & io_dcache_req_ready &
                                   io_misalign_ldin_bits_misalignNeedWakeUp;
  // s0_valid：nc 选中恒可（自带数据无需 dcache）；否则需 dcache_req_ready 且非 mmio 且非 misalign 唤醒
  assign s0_valid = ~s0_kill & (s0_src_select[SRC_NC] | ((
      s0_src_valid[SRC_MISALIGN] | s0_src_valid[SRC_SUPER_REP] | s0_src_valid[SRC_FAST_REP] |
      s0_src_valid[SRC_LSQ_REP]  | s0_src_valid[SRC_HIGH_PF]   | s0_src_valid[SRC_VEC_ISS] |
      s0_src_valid[SRC_INT_ISS]  | s0_src_valid[SRC_LOW_PF]
    ) & ~s0_src_select[SRC_MMIO] & io_dcache_req_ready &
      ~((io_misalign_ldin_valid & io_misalign_ldin_ready) & io_misalign_ldin_bits_misalignNeedWakeUp)));
  assign s0_mmio_select = s0_src_select[SRC_MMIO] & ~s0_kill;
  assign s0_nc_select   = s0_src_select[SRC_NC] & ~s0_kill;
  assign s0_misalign_select = s0_src_select[SRC_MISALIGN] & ~s0_kill;
  assign s0_nc_with_data = s0_sel_isnc & ~s0_kill;
  assign s0_fire      = s0_valid & s0_can_go;
  assign s0_mmio_fire = s0_mmio_select & s0_can_go;
  assign s0_nc_fire   = s0_nc_select & s0_can_go;

  // tlb_valid：misalign/super_rep/lsq_rep/vec/int/l2l 来源且 dcache ready
  logic s0_tlb_valid;
  assign s0_tlb_valid = (s0_src_valid[SRC_MISALIGN] | s0_src_valid[SRC_SUPER_REP] |
                         s0_src_valid[SRC_LSQ_REP]  | s0_src_valid[SRC_VEC_ISS]   |
                         s0_src_valid[SRC_INT_ISS]) & io_dcache_req_ready;

  // ---- s0 fullva / hlv / hlvx ----------------------------------------------
  logic [63:0] s0_tlb_fullva;
  always_comb begin
    if (s0_src_valid[SRC_MISALIGN])      s0_tlb_fullva = io_misalign_ldin_bits_fullva;
    else if (s0_src_select[SRC_VEC_ISS]) s0_tlb_fullva = io_vecldin_bits_vaddr;
    else if (s0_src_select[SRC_INT_ISS]) s0_tlb_fullva = io_ldin_bits_src_0 + {{52{io_ldin_bits_uop_imm[11]}}, io_ldin_bits_uop_imm[11:0]};
    else                                 s0_tlb_fullva = {14'h0, s0_dcache_vaddr};
  end
  // hlv/hlvx：仅 misalign/replay/int 来源按 fuOpType 判（hypervisor load）。
  //   isHlv(op)  = op[4] & ~op[5] & op[8:7]==0
  //   isHlvx(op) = op[4] & op[3] & ~op[5] & op[8:7]==0
  function automatic logic is_hlv(input logic [8:0] op);
    return op[4] & ~op[5] & (op[8:7] == 2'h0);
  endfunction
  function automatic logic is_hlvx(input logic [8:0] op);
    return op[4] & op[3] & ~op[5] & (op[8:7] == 2'h0);
  endfunction
  logic s0_tlb_hlv, s0_tlb_hlvx;
  assign s0_tlb_hlv =
      s0_src_valid[SRC_MISALIGN] ? is_hlv(io_misalign_ldin_bits_uop_fuOpType) :
      (s0_src_valid[SRC_SUPER_REP]|s0_src_valid[SRC_LSQ_REP]) ? is_hlv(io_replay_bits_uop_fuOpType) :
      s0_src_valid[SRC_INT_ISS]  ? is_hlv(io_ldin_bits_uop_fuOpType) : 1'b0;
  assign s0_tlb_hlvx =
      s0_src_valid[SRC_MISALIGN] ? is_hlvx(io_misalign_ldin_bits_uop_fuOpType) :
      (s0_src_valid[SRC_SUPER_REP]|s0_src_valid[SRC_LSQ_REP]) ? is_hlvx(io_replay_bits_uop_fuOpType) :
      s0_src_valid[SRC_INT_ISS]  ? is_hlvx(io_ldin_bits_uop_fuOpType) : 1'b0;

  // ---- s0_out（进 s1 的流水内容）------------------------------------------
  logic [VADDR_BITS-1:0] s0_out_vaddr;
  logic [63:0]           s0_out_fullva;
  logic [PADDR_BITS-1:0] s0_out_paddr;
  // s0_out_vaddr：nc-with-data 时取原始来源 vaddr（misalign/fast/nc，mmio→0），否则 dcache_vaddr
  always_comb begin
    if (~s0_nc_with_data)                 s0_out_vaddr = s0_dcache_vaddr;
    else if (s0_src_select[SRC_MISALIGN]) s0_out_vaddr = io_misalign_ldin_bits_vaddr;
    else if (s0_src_select[SRC_FAST_REP]) s0_out_vaddr = io_fast_rep_in_bits_vaddr;
    else if (s0_src_select[SRC_MMIO])     s0_out_vaddr = {VADDR_BITS{1'b0}};
    else                                  s0_out_vaddr = io_lsq_nc_ldin_bits_vaddr;
  end
  assign s0_out_fullva = s0_sel_frm_mabuf ? {14'h0, s0_out_vaddr} : s0_tlb_fullva;
  always_comb begin
    if (s0_src_select[SRC_NC])            s0_out_paddr = io_lsq_nc_ldin_bits_paddr;
    else if (s0_src_select[SRC_FAST_REP]) s0_out_paddr = io_fast_rep_in_bits_paddr;
    else if (s0_src_select[SRC_INT_ISS] & s0_sel_prf_i) s0_out_paddr = 48'h0;
    else                                  s0_out_paddr = io_prefetch_req_bits_paddr;
  end
  // s0 算出的 misalign 异常（地址未对齐且 vecActive 且非 16B 跨界）
  logic s0_exc_lam, s0_isMisalign;
  // 合流 exceptionVec[4]（与 golden s0_sel_src_uop_exceptionVec_4 一致）：
  //   T6?(T?(mis_v & mis.vec4):fast?F:unc?U:NC):(T10 & ~(s5|s6) & vec.vec4)
  //   注意 T 分支只有 misalign 贡献（replay/super_rep 无 vec4 端口→0）。
  logic s0_sel_exc_lam_in;
  assign s0_sel_exc_lam_in =
      s0_x_T6 ? (s0_x_T ? (io_misalign_ldin_valid & io_misalign_ldin_bits_uop_exceptionVec_4)
                 : io_fast_rep_in_valid ? io_fast_rep_in_bits_uop_exceptionVec_4
                   : io_lsq_uncache_valid ? io_lsq_uncache_bits_uop_exceptionVec_4 : io_lsq_nc_ldin_bits_uop_exceptionVec_4)
              : (s0_x_T10 & ~(s0_x_s5 | s0_x_s6) & io_vecldin_bits_uop_exceptionVec_4);
  assign s0_exc_lam    = (~s0_addr_aligned | s0_sel_exc_lam_in) & s0_sel_vecActive & ~s0_misalignWith16Byte;
  assign s0_isMisalign = (~s0_addr_aligned | s0_sel_exc_lam_in) & s0_sel_vecActive;
  logic s0_forward_tlD;
  assign s0_forward_tlD = s0_src_select[SRC_SUPER_REP];

  // 合流 uop 关键字段前置声明（在 DTLB/DCache 请求中即被使用，赋值见后文）
  logic       s0_uop_robIdx_flag, s0_uop_lqIdx_flag, s0_uop_sqIdx_flag;
  logic [7:0] s0_uop_robIdx_value;
  logic [6:0] s0_uop_lqIdx_value;
  logic [5:0] s0_uop_sqIdx_value;
  logic [7:0] s0_uop_pdest;
  logic       s0_uop_rfWen, s0_uop_fpWen;

  // ---- DTLB 请求 ------------------------------------------------------------
  assign io_tlb_req_valid              = s0_tlb_valid;
  assign io_tlb_req_bits_cmd           = {2'h0, s0_sel_prf & s0_sel_prf_wr}; // bit0=写预取
  assign io_tlb_req_bits_isPrefetch    = s0_sel_prf;
  assign io_tlb_req_bits_vaddr         = s0_tlb_vaddr;
  assign io_tlb_req_bits_fullva        = s0_tlb_fullva;
  assign io_tlb_req_bits_checkfullva   = s0_src_select[SRC_VEC_ISS] | s0_src_select[SRC_INT_ISS];
  assign io_tlb_req_bits_hyperinst     = s0_tlb_hlv;
  assign io_tlb_req_bits_hlvx          = s0_tlb_hlvx;
  assign io_tlb_req_bits_kill          = s0_kill | s0_tlb_no_query;
  assign io_tlb_req_bits_no_translate  = s0_tlb_no_query;
  assign io_tlb_req_bits_debug_robIdx_flag  = s0_uop_robIdx_flag;
  assign io_tlb_req_bits_debug_robIdx_value = s0_uop_robIdx_value;
  assign io_tlb_req_bits_debug_isFirstIssue = s0_sel_first_issue;

  // ---- DCache 请求 ----------------------------------------------------------
  assign io_dcache_req_valid           = s0_valid & ~s0_sel_prf_i & ~s0_nc_with_data;
  // golden DCache cmd 为 5 位 {3'h0, prf_rd?2'h2:{2{prf_wr}}}：load=0 / PFR=2 / PFW=3
  assign io_dcache_req_bits_cmd        = {3'h0, s0_sel_prf_rd ? 2'h2 : {2{s0_sel_prf_wr}}};
  assign io_dcache_req_bits_vaddr      = s0_dcache_vaddr;
  assign io_dcache_req_bits_vaddr_dup  = s0_dcache_vaddr;
  // instrtype 4 位 {2'h0,{2{prf}}}：load=0 / prefetch=3
  assign io_dcache_req_bits_instrtype  = {2'h0, {2{s0_sel_prf}}};
  assign io_dcache_req_bits_isFirstIssue = s0_sel_first_issue;
  assign io_dcache_req_bits_lqIdx_flag  = s0_uop_lqIdx_flag;
  assign io_dcache_req_bits_lqIdx_value = s0_uop_lqIdx_value;
  assign io_dcache_is128Req            = s0_is128bit;
  assign io_dcache_pf_source           = s0_hw_prf_select ? io_prefetch_req_bits_pf_source_value : 3'h0;

  // ---- 合流 uop 关键字段（robIdx / lqIdx / sqIdx / pdest / rfWen / fpWen）---
  `define LU_S0_UOP_SEL(field, dflt) \
      s0_src_select[SRC_MISALIGN ] ? io_misalign_ldin_bits_uop_``field : \
      s0_src_select[SRC_FAST_REP ] ? io_fast_rep_in_bits_uop_``field : \
      s0_src_select[SRC_MMIO     ] ? io_lsq_uncache_bits_uop_``field : \
      s0_src_select[SRC_NC       ] ? io_lsq_nc_ldin_bits_uop_``field : \
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_uop_``field : \
      s0_src_select[SRC_VEC_ISS  ] ? io_vecldin_bits_uop_``field : \
      s0_src_select[SRC_INT_ISS  ] ? io_ldin_bits_uop_``field : dflt
  assign s0_uop_robIdx_flag  = `LU_S0_UOP_SEL(robIdx_flag, 1'b0);
  assign s0_uop_robIdx_value = `LU_S0_UOP_SEL(robIdx_value, 8'h0);
  assign s0_uop_lqIdx_flag   = `LU_S0_UOP_SEL(lqIdx_flag, 1'b0);
  assign s0_uop_lqIdx_value  = `LU_S0_UOP_SEL(lqIdx_value, 7'h0);
  assign s0_uop_sqIdx_flag   = `LU_S0_UOP_SEL(sqIdx_flag, 1'b0);
  assign s0_uop_sqIdx_value  = `LU_S0_UOP_SEL(sqIdx_value, 6'h0);
  assign s0_uop_pdest        = `LU_S0_UOP_SEL(pdest, 8'h0);
  assign s0_uop_rfWen        = `LU_S0_UOP_SEL(rfWen, 1'b0);
  assign s0_uop_fpWen        = `LU_S0_UOP_SEL(fpWen, 1'b0);

  // ---- 输入源 ready / 握手 --------------------------------------------------
  assign io_lsq_uncache_ready  = s0_mmio_fire;
  assign io_lsq_nc_ldin_ready  = s0_src_ready[SRC_NC] & s0_can_go;
  assign io_replay_ready       = s0_can_go & io_dcache_req_ready &
                                 ((s0_src_ready[SRC_LSQ_REP] & ~s0_rep_stall) | s0_src_select[SRC_SUPER_REP]);
  assign io_vecldin_ready      = s0_can_go & io_dcache_req_ready & s0_src_ready[SRC_VEC_ISS];
  assign io_ldin_ready         = s0_can_go & io_dcache_req_ready & s0_src_ready[SRC_INT_ISS];
  assign io_misalign_ldin_ready= s0_can_go & io_dcache_req_ready & s0_src_ready[SRC_MISALIGN];
  assign io_canAcceptLowConfPrefetch  = s0_src_ready[SRC_LOW_PF]  & io_dcache_req_ready;
  assign io_canAcceptHighConfPrefetch = s0_src_ready[SRC_HIGH_PF] & io_dcache_req_ready;

  // ---- load 唤醒（s0 wakeup）-----------------------------------------------
  // 选出唤醒 uop（misalign-wakeup>super>fast>mmio>nc>lsq>int）
  logic s0_wakeup_valid;
  assign s0_wakeup_valid = (s0_fire & ~s0_sel_isvec & ~s0_sel_frm_mabuf & (
        s0_src_valid[SRC_SUPER_REP] | s0_src_valid[SRC_FAST_REP] | s0_src_valid[SRC_LSQ_REP] |
        (s0_src_valid[SRC_INT_ISS] & ~s0_sel_prf & ~s0_src_valid[SRC_VEC_ISS] & ~s0_src_valid[SRC_HIGH_PF])
      )) | s0_mmio_fire | s0_nc_fire | s0_misalign_wakeup_fire;
  logic       s0_wakeup_rfWen, s0_wakeup_fpWen;
  logic [7:0] s0_wakeup_pdest;
  always_comb begin
    priority case (1'b1)
      s0_misalign_wakeup_fire:        {s0_wakeup_rfWen,s0_wakeup_fpWen,s0_wakeup_pdest} = {io_misalign_ldin_bits_uop_rfWen,io_misalign_ldin_bits_uop_fpWen,io_misalign_ldin_bits_uop_pdest};
      s0_src_valid[SRC_SUPER_REP]:    {s0_wakeup_rfWen,s0_wakeup_fpWen,s0_wakeup_pdest} = {io_replay_bits_uop_rfWen,io_replay_bits_uop_fpWen,io_replay_bits_uop_pdest};
      s0_src_valid[SRC_FAST_REP]:     {s0_wakeup_rfWen,s0_wakeup_fpWen,s0_wakeup_pdest} = {io_fast_rep_in_bits_uop_rfWen,io_fast_rep_in_bits_uop_fpWen,io_fast_rep_in_bits_uop_pdest};
      s0_mmio_fire:                   {s0_wakeup_rfWen,s0_wakeup_fpWen,s0_wakeup_pdest} = {io_lsq_uncache_bits_uop_rfWen,io_lsq_uncache_bits_uop_fpWen,io_lsq_uncache_bits_uop_pdest};
      s0_nc_fire:                     {s0_wakeup_rfWen,s0_wakeup_fpWen,s0_wakeup_pdest} = {io_lsq_nc_ldin_bits_uop_rfWen,io_lsq_nc_ldin_bits_uop_fpWen,io_lsq_nc_ldin_bits_uop_pdest};
      s0_src_valid[SRC_LSQ_REP]:      {s0_wakeup_rfWen,s0_wakeup_fpWen,s0_wakeup_pdest} = {io_replay_bits_uop_rfWen,io_replay_bits_uop_fpWen,io_replay_bits_uop_pdest};
      default:                        {s0_wakeup_rfWen,s0_wakeup_fpWen,s0_wakeup_pdest} = {io_ldin_bits_uop_rfWen,io_ldin_bits_uop_fpWen,io_ldin_bits_uop_pdest};
    endcase
  end
  assign io_wakeup_valid     = s0_wakeup_valid;
  assign io_wakeup_bits_rfWen= s0_wakeup_rfWen;
  assign io_wakeup_bits_fpWen= s0_wakeup_fpWen;
  assign io_wakeup_bits_pdest= s0_wakeup_pdest;

  // prefetch.i（Zicbop）：int 来源且 prf_i 时，打一拍发 ifetchPrefetch
  logic       s0_ifetch_pf;
  assign s0_ifetch_pf = s0_src_select[SRC_INT_ISS] & s0_sel_prf_i;
  logic       reg_ifetch_pf_valid;
  logic [VADDR_BITS-1:0] reg_ifetch_pf_vaddr;
  always_ff @(posedge clock) reg_ifetch_pf_valid <= s0_ifetch_pf;
  // golden 复位寄存器统一在 always @(posedge clock or posedge reset) 异步复位块——对齐
  always_ff @(posedge clock or posedge reset) begin
    if (reset)             reg_ifetch_pf_vaddr <= {VADDR_BITS{1'b0}};  // golden 复位 vaddr_r=0
    else if (s0_ifetch_pf) reg_ifetch_pf_vaddr <= s0_out_vaddr;
  end
  assign io_ifetchPrefetch_valid      = reg_ifetch_pf_valid;
  assign io_ifetchPrefetch_bits_vaddr = reg_ifetch_pf_vaddr;

  // ---- 其余合流 uop / FlowSource 字段（S0 选择，喂入 S1 寄存器）------------
  logic [3:0] s0_sel_mshrid;
  logic [6:0] s0_sel_schedIndex;
  logic [7:0] s0_sel_elemIdx, s0_sel_elemIdxInsideVd;
  logic [3:0] s0_sel_mbIndex, s0_sel_reg_offset;
  logic [VADDR_BITS-1:0] s0_sel_vecBaseVaddr;
  assign s0_sel_mshrid =
      s0_src_select[SRC_MISALIGN] ? io_misalign_ldin_bits_mshrid :
      s0_src_select[SRC_FAST_REP] ? io_fast_rep_in_bits_rep_info_mshr_id :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_mshrid : 4'h0;
  assign s0_sel_schedIndex =
      s0_src_select[SRC_MISALIGN] ? io_misalign_ldin_bits_schedIndex :
      s0_src_select[SRC_FAST_REP] ? io_fast_rep_in_bits_schedIndex :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_schedIndex :
      s0_src_select[SRC_NC]       ? io_lsq_nc_ldin_bits_schedIndex : 7'h0;
  assign s0_sel_elemIdx =
      s0_src_select[SRC_FAST_REP] ? io_fast_rep_in_bits_elemIdx :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_elemIdx :
      s0_src_select[SRC_VEC_ISS]  ? io_vecldin_bits_elemIdx : 8'h0;
  assign s0_sel_elemIdxInsideVd =
      s0_src_select[SRC_FAST_REP] ? io_fast_rep_in_bits_elemIdxInsideVd :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_elemIdxInsideVd :
      s0_src_select[SRC_VEC_ISS]  ? io_vecldin_bits_elemIdxInsideVd : 8'h0;
  assign s0_sel_mbIndex =
      s0_src_select[SRC_FAST_REP] ? io_fast_rep_in_bits_mbIndex :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_mbIndex :
      s0_src_select[SRC_VEC_ISS]  ? io_vecldin_bits_mBIndex : 4'h0;
  assign s0_sel_reg_offset =
      s0_src_select[SRC_FAST_REP] ? io_fast_rep_in_bits_reg_offset :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_reg_offset :
      s0_src_select[SRC_VEC_ISS]  ? io_vecldin_bits_reg_offset : 4'h0;
  assign s0_sel_vecBaseVaddr =
      s0_src_select[SRC_VEC_ISS]  ? io_vecldin_bits_basevaddr : {VADDR_BITS{1'b0}};

  // 合流 uop 的其余标量字段（vstart/veew/storeSetHit/loadWait*/waitForRobIdx/
  // preDecode/ftq*/debugInfo），同样固定优先级选择。
  logic [7:0] s0_uop_vstart;  logic [1:0] s0_uop_veew;
  logic       s0_uop_storeSetHit, s0_uop_loadWaitBit, s0_uop_loadWaitStrict;
  logic       s0_uop_waitForRobIdx_flag; logic [7:0] s0_uop_waitForRobIdx_value;
  logic       s0_uop_preDecode_isRVC, s0_uop_ftqPtr_flag; logic [5:0] s0_uop_ftqPtr_value;
  logic [3:0] s0_uop_ftqOffset;
  logic [63:0] s0_uop_enqRsTime, s0_uop_selectTime, s0_uop_issueTime;
  // uopIdx：int 发射来源（io_ldin）无此字段，缺省 0；其余按优先级选。
  logic [6:0] s0_uop_uopIdx;
  assign s0_uop_uopIdx =
      s0_src_select[SRC_MISALIGN ] ? io_misalign_ldin_bits_uop_uopIdx :
      s0_src_select[SRC_FAST_REP ] ? io_fast_rep_in_bits_uop_uopIdx :
      s0_src_select[SRC_MMIO     ] ? io_lsq_uncache_bits_uop_uopIdx :
      s0_src_select[SRC_NC       ] ? io_lsq_nc_ldin_bits_uop_uopIdx :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_uop_uopIdx :
      s0_src_select[SRC_VEC_ISS  ] ? io_vecldin_bits_uop_uopIdx : 7'h0;
  // s0_out.data（129 位，进 s1/s2 流水）：仅 fast_rep / nc 来源带数据；misalign/super_rep
  //   优先级更高时清零（与 golden s1_in_r_data 选择一致：misalign|super_rep 命中 → 0）。
  logic [128:0] s0_out_data;
  always_comb begin
    if (s0_src_valid[SRC_MISALIGN] | s0_src_valid[SRC_SUPER_REP]) s0_out_data = 129'h0;
    else if (io_fast_rep_in_valid)                                s0_out_data = io_fast_rep_in_bits_data;
    else if (io_lsq_uncache_valid)                                s0_out_data = 129'h0;
    else if (io_lsq_nc_ldin_valid)                                s0_out_data = io_lsq_nc_ldin_bits_data;
    else                                                          s0_out_data = 129'h0;
  end
  // vpu_vstart/veew：int 发射来源（io_ldin）是标量、无此字段，单独选择（缺省 0）
  assign s0_uop_vstart =
      s0_src_select[SRC_MISALIGN ] ? io_misalign_ldin_bits_uop_vpu_vstart :
      s0_src_select[SRC_FAST_REP ] ? io_fast_rep_in_bits_uop_vpu_vstart :
      s0_src_select[SRC_MMIO     ] ? io_lsq_uncache_bits_uop_vpu_vstart :
      s0_src_select[SRC_NC       ] ? io_lsq_nc_ldin_bits_uop_vpu_vstart :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_uop_vpu_vstart :
      s0_src_select[SRC_VEC_ISS  ] ? io_vecldin_bits_uop_vpu_vstart : 8'h0;
  assign s0_uop_veew =
      s0_src_select[SRC_MISALIGN ] ? io_misalign_ldin_bits_uop_vpu_veew :
      s0_src_select[SRC_FAST_REP ] ? io_fast_rep_in_bits_uop_vpu_veew :
      s0_src_select[SRC_MMIO     ] ? io_lsq_uncache_bits_uop_vpu_veew :
      s0_src_select[SRC_NC       ] ? io_lsq_nc_ldin_bits_uop_vpu_veew :
      (s0_src_select[SRC_SUPER_REP]|s0_src_select[SRC_LSQ_REP]) ? io_replay_bits_uop_vpu_veew :
      s0_src_select[SRC_VEC_ISS  ] ? io_vecldin_bits_uop_vpu_veew : 2'h0;
  assign s0_uop_preDecode_isRVC   = `LU_S0_UOP_SEL(preDecodeInfo_isRVC, 1'b0);
  assign s0_uop_ftqPtr_flag       = `LU_S0_UOP_SEL(ftqPtr_flag, 1'b0);
  assign s0_uop_ftqPtr_value      = `LU_S0_UOP_SEL(ftqPtr_value, 6'h0);
  assign s0_uop_ftqOffset         = `LU_S0_UOP_SEL(ftqOffset, 4'h0);
  assign s0_uop_enqRsTime         = `LU_S0_UOP_SEL(debugInfo_enqRsTime, 64'h0);
  assign s0_uop_selectTime        = `LU_S0_UOP_SEL(debugInfo_selectTime, 64'h0);
  assign s0_uop_issueTime         = `LU_S0_UOP_SEL(debugInfo_issueTime, 64'h0);
  // storeSetHit/loadWait*/waitForRobIdx 用 golden 的“原始 valid 嵌套优先 mux”表达
  //   （与 s0_out_excVec 同一套别名）。这些字段 nc 来源也透传，故缺 nc 会出错。
  // 通用字段（vec 来源贡献 vecldin；replay 在 super/lsq 两处）：
  //   T6?(T?(mis?M:R):fast?F:unc?U:NC):(T10?(s5?R:~s6 & V):io_ldin_v & I)
  `define LU_S0_UOPF(M,R,F,U,N,V,I,Z) \
      s0_x_T6 ? (s0_x_T ? (io_misalign_ldin_valid ? (M) : (R)) \
                 : io_fast_rep_in_valid ? (F) : io_lsq_uncache_valid ? (U) : (N)) \
              : s0_x_T10 ? (s0_x_s5 ? (R) : (~s0_x_s6 ? (V) : (Z))) \
                         : (io_ldin_valid ? (I) : (Z))
  assign s0_uop_storeSetHit = `LU_S0_UOPF(io_misalign_ldin_bits_uop_storeSetHit, io_replay_bits_uop_storeSetHit,
      io_fast_rep_in_bits_uop_storeSetHit, io_lsq_uncache_bits_uop_storeSetHit, io_lsq_nc_ldin_bits_uop_storeSetHit,
      io_vecldin_bits_uop_storeSetHit, io_ldin_bits_uop_storeSetHit, 1'b0);
  assign s0_uop_loadWaitBit = `LU_S0_UOPF(io_misalign_ldin_bits_uop_loadWaitBit, io_replay_bits_uop_loadWaitBit,
      io_fast_rep_in_bits_uop_loadWaitBit, io_lsq_uncache_bits_uop_loadWaitBit, io_lsq_nc_ldin_bits_uop_loadWaitBit,
      io_vecldin_bits_uop_loadWaitBit, io_ldin_bits_uop_loadWaitBit, 1'b0);
  assign s0_uop_waitForRobIdx_flag = `LU_S0_UOPF(io_misalign_ldin_bits_uop_waitForRobIdx_flag, io_replay_bits_uop_waitForRobIdx_flag,
      io_fast_rep_in_bits_uop_waitForRobIdx_flag, io_lsq_uncache_bits_uop_waitForRobIdx_flag, io_lsq_nc_ldin_bits_uop_waitForRobIdx_flag,
      io_vecldin_bits_uop_waitForRobIdx_flag, io_ldin_bits_uop_waitForRobIdx_flag, 1'b0);
  assign s0_uop_waitForRobIdx_value = `LU_S0_UOPF(io_misalign_ldin_bits_uop_waitForRobIdx_value, io_replay_bits_uop_waitForRobIdx_value,
      io_fast_rep_in_bits_uop_waitForRobIdx_value, io_lsq_uncache_bits_uop_waitForRobIdx_value, io_lsq_nc_ldin_bits_uop_waitForRobIdx_value,
      io_vecldin_bits_uop_waitForRobIdx_value, io_ldin_bits_uop_waitForRobIdx_value, 8'h0);
  // loadWaitStrict：misalign 分支特殊（mis_v & strict），vec 分支 ~(s5|s6)&V，无 super_rep
  assign s0_uop_loadWaitStrict =
      s0_x_T6 ? (s0_x_T ? (io_misalign_ldin_valid & io_misalign_ldin_bits_uop_loadWaitStrict)
                 : io_fast_rep_in_valid ? io_fast_rep_in_bits_uop_loadWaitStrict
                   : io_lsq_uncache_valid ? io_lsq_uncache_bits_uop_loadWaitStrict : io_lsq_nc_ldin_bits_uop_loadWaitStrict)
              : s0_x_T10 ? (~(s0_x_s5 | s0_x_s6) & io_vecldin_bits_uop_loadWaitStrict)
                         : (io_ldin_valid & io_ldin_bits_uop_loadWaitStrict);
  `undef LU_S0_UOPF

  // ===========================================================================
  //  S0 -> S1 流水寄存器（s0_out 在 s0_fire 时打入 s1_in_*）
  // ===========================================================================
  // S1 保存 S0 的全部控制/地址/uop。这里用平铺寄存器组（按字段命名，分组注释），
  // 等价于 Scala 的 `s1_in := RegEnable(s0_out, s0_fire)`。
  logic                  s1_valid;
  logic [VADDR_BITS-1:0] s1_in_vaddr;
  logic [63:0]           s1_in_fullva;
  logic [PADDR_BITS-1:0] s1_in_paddr;
  logic [MASK_BITS-1:0]  s1_in_mask;
  logic [8:0]            s1_in_fuOpType;
  logic                  s1_in_robIdx_flag;  logic [7:0] s1_in_robIdx_value;
  logic                  s1_in_lqIdx_flag;   logic [6:0] s1_in_lqIdx_value;
  logic                  s1_in_sqIdx_flag;   logic [5:0] s1_in_sqIdx_value;
  logic [7:0]            s1_in_pdest;
  logic                  s1_in_rfWen, s1_in_fpWen;
  logic                  s1_in_isvec, s1_in_is128bit, s1_in_vecActive;
  logic                  s1_in_isPrefetch, s1_in_isHWPrefetch, s1_in_isFastReplay, s1_in_isLoadReplay;
  logic                  s1_in_frm_mabuf, s1_in_isnc, s1_in_isMisalign, s1_in_misalignWith16Byte;
  logic                  s1_in_first_issue, s1_in_has_rob, s1_in_forward_tlD, s1_in_tlbNoQuery;
  logic                  s1_in_misalignNeedWakeUp, s1_in_isFinalSplit;
  logic [3:0]            s1_in_mshrid;
  logic [6:0]            s1_in_schedIndex;
  logic [2:0]            s1_in_alignedType;
  logic [7:0]            s1_in_elemIdx, s1_in_elemIdxInsideVd;
  logic [3:0]            s1_in_mbIndex, s1_in_reg_offset;
  logic [VADDR_BITS-1:0] s1_in_vecBaseVaddr;
  logic [7:0]            s1_in_vstart;
  logic [1:0]            s1_in_veew;
  logic                  s1_in_storeSetHit, s1_in_loadWaitBit, s1_in_loadWaitStrict;
  logic                  s1_in_waitForRobIdx_flag; logic [7:0] s1_in_waitForRobIdx_value;
  logic                  s1_in_preDecode_isRVC, s1_in_ftqPtr_flag; logic [5:0] s1_in_ftqPtr_value;
  logic [3:0]            s1_in_ftqOffset;
  logic [63:0]           s1_in_enqRsTime, s1_in_selectTime, s1_in_issueTime;
  logic [23:0]           s1_in_excVec;  // 透传的 exceptionVec（位 0..23）
  logic                  s1_nc_with_data;
  logic [128:0]          s1_in_data;    // fast_rep / nc 来源携带的数据（s2 NC 路径用）
  logic [6:0]            s1_in_uopIdx;

  // s0_out 的 exceptionVec：仅 misalign 来源透传完整 vec，其余来源相关位由 s0/s1 计算。
  // 这里把 s0 选中来源的 exceptionVec 合流为 24 位（misalign/nc/replay/fast_rep/vec 各有部分位）。
  // 合流 exceptionVec（与 golden s1_in_r_uop_exceptionVec_* 的 s0->s1 加载逐位一致）。
  //   优先级（按原始 valid，非 select）：misalign>super_rep>fast>uncache>nc>lsq_rep>(high_pf)>vec
  //   int 发射(io_ldin)无 exceptionVec 端口 → 贡献 0。
  //   位 3/5/13/21 在 s1->s2 由 TLB 重算，s0->s1 不锁存（这里置 0 不影响）。
  //   位 4(LAM) 由 s0 公式 s0_exc_lam 给出（见下）。
  //   位 6/7/15/19 vec 发射来源也贡献（其余位 vec 不贡献）。
  // 通用位（无 vec 贡献）：T6?(T?(mis?M:R):fast?F:unc?U:NC):(T10 & s5 & R)
  `define LU_EXC_GEN(M,R,F,U,N) \
      s0_x_T6 ? (s0_x_T ? (io_misalign_ldin_valid ? (M) : (R)) \
                 : io_fast_rep_in_valid ? (F) : io_lsq_uncache_valid ? (U) : (N)) \
              : (s0_x_T10 & s0_x_s5 & (R))
  // vec 贡献位：T6?(...同上...):(T10 & (s5?R:~s6 & V))
  `define LU_EXC_VEC(M,R,F,U,N,V) \
      s0_x_T6 ? (s0_x_T ? (io_misalign_ldin_valid ? (M) : (R)) \
                 : io_fast_rep_in_valid ? (F) : io_lsq_uncache_valid ? (U) : (N)) \
              : (s0_x_T10 & (s0_x_s5 ? (R) : ~s0_x_s6 & (V)))
  logic [23:0] s0_out_excVec;
  always_comb begin
    s0_out_excVec = 24'h0;
    s0_out_excVec[0]  = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_0, io_replay_bits_uop_exceptionVec_0, io_fast_rep_in_bits_uop_exceptionVec_0, io_lsq_uncache_bits_uop_exceptionVec_0, io_lsq_nc_ldin_bits_uop_exceptionVec_0);
    s0_out_excVec[1]  = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_1, io_replay_bits_uop_exceptionVec_1, io_fast_rep_in_bits_uop_exceptionVec_1, io_lsq_uncache_bits_uop_exceptionVec_1, io_lsq_nc_ldin_bits_uop_exceptionVec_1);
    s0_out_excVec[2]  = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_2, io_replay_bits_uop_exceptionVec_2, io_fast_rep_in_bits_uop_exceptionVec_2, io_lsq_uncache_bits_uop_exceptionVec_2, io_lsq_nc_ldin_bits_uop_exceptionVec_2);
    s0_out_excVec[6]  = `LU_EXC_VEC(io_misalign_ldin_bits_uop_exceptionVec_6, io_replay_bits_uop_exceptionVec_6, io_fast_rep_in_bits_uop_exceptionVec_6, io_lsq_uncache_bits_uop_exceptionVec_6, io_lsq_nc_ldin_bits_uop_exceptionVec_6, io_vecldin_bits_uop_exceptionVec_6);
    s0_out_excVec[7]  = `LU_EXC_VEC(io_misalign_ldin_bits_uop_exceptionVec_7, io_replay_bits_uop_exceptionVec_7, io_fast_rep_in_bits_uop_exceptionVec_7, io_lsq_uncache_bits_uop_exceptionVec_7, io_lsq_nc_ldin_bits_uop_exceptionVec_7, io_vecldin_bits_uop_exceptionVec_7);
    s0_out_excVec[8]  = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_8, io_replay_bits_uop_exceptionVec_8, io_fast_rep_in_bits_uop_exceptionVec_8, io_lsq_uncache_bits_uop_exceptionVec_8, io_lsq_nc_ldin_bits_uop_exceptionVec_8);
    s0_out_excVec[9]  = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_9, io_replay_bits_uop_exceptionVec_9, io_fast_rep_in_bits_uop_exceptionVec_9, io_lsq_uncache_bits_uop_exceptionVec_9, io_lsq_nc_ldin_bits_uop_exceptionVec_9);
    s0_out_excVec[10] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_10, io_replay_bits_uop_exceptionVec_10, io_fast_rep_in_bits_uop_exceptionVec_10, io_lsq_uncache_bits_uop_exceptionVec_10, io_lsq_nc_ldin_bits_uop_exceptionVec_10);
    s0_out_excVec[11] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_11, io_replay_bits_uop_exceptionVec_11, io_fast_rep_in_bits_uop_exceptionVec_11, io_lsq_uncache_bits_uop_exceptionVec_11, io_lsq_nc_ldin_bits_uop_exceptionVec_11);
    s0_out_excVec[12] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_12, io_replay_bits_uop_exceptionVec_12, io_fast_rep_in_bits_uop_exceptionVec_12, io_lsq_uncache_bits_uop_exceptionVec_12, io_lsq_nc_ldin_bits_uop_exceptionVec_12);
    s0_out_excVec[14] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_14, io_replay_bits_uop_exceptionVec_14, io_fast_rep_in_bits_uop_exceptionVec_14, io_lsq_uncache_bits_uop_exceptionVec_14, io_lsq_nc_ldin_bits_uop_exceptionVec_14);
    s0_out_excVec[15] = `LU_EXC_VEC(io_misalign_ldin_bits_uop_exceptionVec_15, io_replay_bits_uop_exceptionVec_15, io_fast_rep_in_bits_uop_exceptionVec_15, io_lsq_uncache_bits_uop_exceptionVec_15, io_lsq_nc_ldin_bits_uop_exceptionVec_15, io_vecldin_bits_uop_exceptionVec_15);
    s0_out_excVec[16] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_16, io_replay_bits_uop_exceptionVec_16, io_fast_rep_in_bits_uop_exceptionVec_16, io_lsq_uncache_bits_uop_exceptionVec_16, io_lsq_nc_ldin_bits_uop_exceptionVec_16);
    s0_out_excVec[17] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_17, io_replay_bits_uop_exceptionVec_17, io_fast_rep_in_bits_uop_exceptionVec_17, io_lsq_uncache_bits_uop_exceptionVec_17, io_lsq_nc_ldin_bits_uop_exceptionVec_17);
    s0_out_excVec[18] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_18, io_replay_bits_uop_exceptionVec_18, io_fast_rep_in_bits_uop_exceptionVec_18, io_lsq_uncache_bits_uop_exceptionVec_18, io_lsq_nc_ldin_bits_uop_exceptionVec_18);
    s0_out_excVec[19] = `LU_EXC_VEC(io_misalign_ldin_bits_uop_exceptionVec_19, io_replay_bits_uop_exceptionVec_19, io_fast_rep_in_bits_uop_exceptionVec_19, io_lsq_uncache_bits_uop_exceptionVec_19, io_lsq_nc_ldin_bits_uop_exceptionVec_19, io_vecldin_bits_uop_exceptionVec_19);
    s0_out_excVec[20] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_20, io_replay_bits_uop_exceptionVec_20, io_fast_rep_in_bits_uop_exceptionVec_20, io_lsq_uncache_bits_uop_exceptionVec_20, io_lsq_nc_ldin_bits_uop_exceptionVec_20);
    s0_out_excVec[22] = `LU_EXC_GEN(io_misalign_ldin_bits_uop_exceptionVec_22, io_replay_bits_uop_exceptionVec_22, io_fast_rep_in_bits_uop_exceptionVec_22, io_lsq_uncache_bits_uop_exceptionVec_22, io_lsq_nc_ldin_bits_uop_exceptionVec_22);
    s0_out_excVec[23] = `LU_EXC_VEC(io_misalign_ldin_bits_uop_exceptionVec_23, io_replay_bits_uop_exceptionVec_23, io_fast_rep_in_bits_uop_exceptionVec_23, io_lsq_uncache_bits_uop_exceptionVec_23, io_lsq_nc_ldin_bits_uop_exceptionVec_23, io_vecldin_bits_uop_exceptionVec_23);
    // 位 4(LAM)：s0 公式
    s0_out_excVec[EXC_LAM] = s0_exc_lam;
  end
  `undef LU_EXC_GEN
  `undef LU_EXC_VEC

  // 流水推进：s0_fire 写入，s1_fire/s1_kill 清 valid
  logic s1_kill, s1_can_go, s1_fire;
  assign s1_ready  = ~s1_valid | s1_kill | s2_ready;
  assign s1_can_go = s2_ready;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)              s1_valid <= 1'b0;
    else if (s0_fire)       s1_valid <= 1'b1;
    else if (s1_fire | s1_kill) s1_valid <= 1'b0;
  end
  // golden 有两份 vecActive：s1_vecActive(异步复位=1, 仅供 s1 异常重算 lpf/laf/hwe)
  // 与 s1_in_r_vecActive(无复位, 流水 payload)。bug-for-bug 对齐：impl 同样拆两份。
  logic s1_vecActive;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)        s1_vecActive <= 1'b1;
    else if (s0_fire) s1_vecActive <= s0_sel_vecActive;
  end
  always_ff @(posedge clock) begin
    s1_nc_with_data <= s0_nc_with_data;
    if (s0_fire) s1_in_vecActive <= s0_sel_vecActive;  // payload 份：golden 无复位
    if (s0_fire) begin
      s1_in_vaddr        <= s0_out_vaddr;
      s1_in_fullva       <= s0_out_fullva;
      s1_in_paddr        <= s0_out_paddr;
      s1_in_mask         <= s0_sel_mask;
      s1_in_fuOpType     <= s0_sel_fuOpType;
      s1_in_robIdx_flag  <= s0_uop_robIdx_flag;  s1_in_robIdx_value <= s0_uop_robIdx_value;
      s1_in_lqIdx_flag   <= s0_uop_lqIdx_flag;   s1_in_lqIdx_value  <= s0_uop_lqIdx_value;
      s1_in_sqIdx_flag   <= s0_uop_sqIdx_flag;   s1_in_sqIdx_value  <= s0_uop_sqIdx_value;
      s1_in_pdest        <= s0_uop_pdest;
      s1_in_rfWen        <= s0_uop_rfWen;        s1_in_fpWen <= s0_uop_fpWen;
      s1_in_isvec        <= s0_sel_isvec;        s1_in_is128bit <= s0_is128bit;
      s1_in_isPrefetch   <= s0_sel_prf;          s1_in_isHWPrefetch <= s0_hw_prf_select;
      s1_in_isFastReplay <= s0_sel_fast_rep;     s1_in_isLoadReplay <= s0_sel_ld_rep;
      s1_in_frm_mabuf    <= s0_sel_frm_mabuf;    s1_in_isnc <= s0_sel_isnc;
      s1_in_isMisalign   <= s0_isMisalign;       s1_in_misalignWith16Byte <= s0_misalignWith16Byte;
      s1_in_first_issue  <= s0_sel_first_issue;  s1_in_has_rob <= s0_sel_has_rob;
      s1_in_forward_tlD  <= s0_forward_tlD;      s1_in_tlbNoQuery <= s0_tlb_no_query;
      s1_in_misalignNeedWakeUp <= s0_sel_frm_mabuf & io_misalign_ldin_bits_misalignNeedWakeUp;
      s1_in_isFinalSplit <= s0_sel_frm_mabuf & io_misalign_ldin_bits_isFinalSplit;
      s1_in_mshrid       <= s0_sel_mshrid;       s1_in_schedIndex <= s0_sel_schedIndex;
      s1_in_alignedType  <= s0_alignedType;
      s1_in_elemIdx      <= s0_sel_elemIdx;      s1_in_elemIdxInsideVd <= s0_sel_elemIdxInsideVd;
      s1_in_mbIndex      <= s0_sel_mbIndex;      s1_in_reg_offset <= s0_sel_reg_offset;
      s1_in_vecBaseVaddr <= s0_sel_vecBaseVaddr;
      s1_in_vstart       <= s0_uop_vstart;       s1_in_veew <= s0_uop_veew;
      s1_in_storeSetHit  <= s0_uop_storeSetHit;
      s1_in_loadWaitBit  <= s0_uop_loadWaitBit;  s1_in_loadWaitStrict <= s0_uop_loadWaitStrict;
      s1_in_waitForRobIdx_flag <= s0_uop_waitForRobIdx_flag; s1_in_waitForRobIdx_value <= s0_uop_waitForRobIdx_value;
      s1_in_preDecode_isRVC <= s0_uop_preDecode_isRVC;
      s1_in_ftqPtr_flag  <= s0_uop_ftqPtr_flag;  s1_in_ftqPtr_value <= s0_uop_ftqPtr_value;
      s1_in_ftqOffset    <= s0_uop_ftqOffset;
      s1_in_enqRsTime    <= s0_uop_enqRsTime;    s1_in_selectTime <= s0_uop_selectTime; s1_in_issueTime <= s0_uop_issueTime;
      s1_in_excVec       <= s0_out_excVec;
      s1_in_data         <= s0_out_data;         s1_in_uopIdx <= s0_uop_uopIdx;
    end
  end

  // sqIdxMask：(1<<sqIdx)-1（56 位），s0_fire 时按合流 sqIdx 锁存（forward 查询用）
  logic [55:0] s1_sqIdx_mask;
  always_ff @(posedge clock) if (s0_fire)
    s1_sqIdx_mask <= 56'((64'h1 << s0_uop_sqIdx_value) - 64'h1);

  // ===========================================================================
  //  S1 —— TLB 响应 + forward 查询 + MemTrigger 断点匹配
  // ===========================================================================
  // s1 vaddr 复原（hi||lo）、paddr 选择（tlbNoQuery 用透传 paddr，否则 TLB 回的）
  logic [VADDR_BITS-1:0] s1_vaddr;
  logic [PADDR_BITS-1:0] s1_paddr_dup_lsu, s1_paddr_dup_dcache;
  logic [63:0]           s1_gpaddr_dup_lsu;
  assign s1_vaddr            = s1_in_vaddr;
  assign s1_paddr_dup_lsu    = s1_in_tlbNoQuery ? s1_in_paddr : io_tlb_resp_bits_paddr_0;
  assign s1_paddr_dup_dcache = s1_in_tlbNoQuery ? s1_in_paddr : io_tlb_resp_bits_paddr_1;
  assign s1_gpaddr_dup_lsu   = s1_in_isFastReplay ? {16'h0, s1_in_paddr} : io_tlb_resp_bits_gpaddr_0;

  logic s1_tlb_miss, s1_tlb_hit;
  logic [1:0] s1_pbmt;
  assign s1_tlb_miss = io_tlb_resp_bits_miss & io_tlb_resp_valid & s1_valid;
  assign s1_tlb_hit  = ~io_tlb_resp_bits_miss & io_tlb_resp_valid & s1_valid;
  assign s1_pbmt     = s1_tlb_hit ? io_tlb_resp_bits_pbmt_0 : PBMT_NONE;
  logic s1_prf, s1_hw_prf, s1_sw_prf;
  assign s1_prf    = s1_in_isPrefetch;
  assign s1_hw_prf = s1_in_isHWPrefetch;
  assign s1_sw_prf = s1_prf & ~s1_hw_prf;

  // ---- fast-replay 延迟错误 / 延迟 kill（fast_rep 来源在 s0 捕获，s1 用）------
  logic s1_dly_err_r, s1_dly_kill_r;
  always_ff @(posedge clock) begin
    if (io_fast_rep_in_valid) begin
      s1_dly_err_r  <= io_fast_rep_in_bits_delayedLoadError;
      s1_dly_kill_r <= io_fast_rep_in_bits_lateKill;
    end
  end
  logic s1_dly_err, s1_dly_kill;
  assign s1_dly_err  = s1_dly_err_r  & s1_in_isFastReplay;
  assign s1_dly_kill = s1_dly_kill_r & s1_in_isFastReplay;

  // ---- redirect 打一拍（s1_kill 需同时比较当拍 redirect 与上一拍 redirect）-----
  logic       s1_redir_v_d, s1_redir_level_d, s1_redir_flag_d;
  logic [7:0] s1_redir_value_d;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s1_redir_v_d <= 1'b0;
    else       s1_redir_v_d <= io_redirect_valid;
  end
  always_ff @(posedge clock) begin
    if (io_redirect_valid) begin
      s1_redir_level_d <= io_redirect_bits_level;
      s1_redir_flag_d  <= io_redirect_bits_robIdx_flag;
      s1_redir_value_d <= io_redirect_bits_robIdx_value;
    end
  end

  // s1 是否被冲刷：当拍 redirect 命中 或 上一拍 redirect 命中 或 fast-replay 延迟 kill
  assign s1_kill = (s1_dly_kill) |
      rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                     s1_in_robIdx_flag, s1_in_robIdx_value,
                     io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value) |
      rob_need_flush(s1_redir_v_d, s1_redir_level_d,
                     s1_in_robIdx_flag, s1_in_robIdx_value,
                     s1_redir_flag_d, s1_redir_value_d);
  assign s1_fire   = s1_valid & ~s1_kill & s1_can_go;

  // ---- s1 重算异常（从 TLB resp 重建 LPF/LAF/LGPF；LAM 由 s0 给且可被高优先级清除）--
  logic s1_checkfullva_d;  // RegNext(io_tlb_req_bits_checkfullva)
  always_ff @(posedge clock) s1_checkfullva_d <= io_tlb_req_bits_checkfullva;
  logic s1_exc_lpf, s1_exc_lgpf, s1_exc_laf, s1_exc_lam, s1_exc_hwe;
  assign s1_exc_lpf  = ~s1_dly_err & io_tlb_resp_bits_excp_0_pf_ld  & s1_vecActive & ~s1_tlb_miss & ~s1_in_tlbNoQuery;
  assign s1_exc_lgpf = ~s1_dly_err & io_tlb_resp_bits_excp_0_gpf_ld &                    ~s1_tlb_miss & ~s1_in_tlbNoQuery;
  assign s1_exc_laf  = ~s1_dly_err & io_tlb_resp_bits_excp_0_af_ld  & s1_vecActive & ~s1_tlb_miss & ~s1_in_tlbNoQuery;
  // checkfullva 命中且产生 pf/gpf/af 时，清除 LAM（误对齐让位真异常）
  logic s1_lam_clear;
  assign s1_lam_clear = s1_checkfullva_d & (s1_exc_lpf | s1_exc_lgpf | s1_exc_laf);
  assign s1_exc_lam  = ~s1_dly_err & ~s1_lam_clear & s1_in_excVec[EXC_LAM];
  assign s1_exc_hwe  = s1_dly_err ? (s1_dly_err & s1_vecActive) : s1_in_excVec[EXC_HWE];

  // s1 trigger：action==0 表示断点异常(breakpoint)，action==1 表示进入 debug mode
  // （与 golden s1_trigger_breakpoint/s1_trigger_debug_mode 一致）
  logic [3:0] s1_trigger_action;  // 前置声明，赋值见 MemTrigger 例化
  logic s1_trigger_bp, s1_trigger_dmode;
  assign s1_trigger_bp    = (s1_trigger_action == 4'h0);
  assign s1_trigger_dmode = (s1_trigger_action == 4'h1);

  // s1 是否有异常（LduCfg 关心位：LAM/LAF/LPF/LGPF/breakpoint）
  logic s1_has_exc;
  // 与 golden _GEN_1 一致：含 hwe(vec19)。dcache_s1_kill / forward 查询 valid 用它。
  assign s1_has_exc = s1_exc_lam | s1_exc_laf | s1_exc_lpf | s1_exc_lgpf | s1_exc_hwe | s1_trigger_bp;

  // forward 查询有效（命中、非异常、非 tlb_miss、非 kill、非延迟错误、非 prefetch）
  logic s1_fwd_query_valid;
  assign s1_fwd_query_valid = s1_valid & ~(s1_has_exc | s1_tlb_miss | s1_kill | s1_dly_err | s1_prf);

  // ---- MemTrigger 子模块（叶子黑盒，断点匹配）------------------------------
  logic [VADDR_BITS-1:0] s1_trigger_vaddr;
  logic [MASK_BITS-1:0]  s1_trigger_mask;
  MemTrigger loadTrigger (
    .tdataVec_io_fromCsrTrigger_tdataVec_0_matchType (io_fromCsrTrigger_tdataVec_0_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_select    (io_fromCsrTrigger_tdataVec_0_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_timing    (io_fromCsrTrigger_tdataVec_0_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_action    (io_fromCsrTrigger_tdataVec_0_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_chain     (io_fromCsrTrigger_tdataVec_0_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_load      (io_fromCsrTrigger_tdataVec_0_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_0_tdata2    (io_fromCsrTrigger_tdataVec_0_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_matchType (io_fromCsrTrigger_tdataVec_1_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_select    (io_fromCsrTrigger_tdataVec_1_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_timing    (io_fromCsrTrigger_tdataVec_1_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_action    (io_fromCsrTrigger_tdataVec_1_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_chain     (io_fromCsrTrigger_tdataVec_1_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_load      (io_fromCsrTrigger_tdataVec_1_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_1_tdata2    (io_fromCsrTrigger_tdataVec_1_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_matchType (io_fromCsrTrigger_tdataVec_2_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_select    (io_fromCsrTrigger_tdataVec_2_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_timing    (io_fromCsrTrigger_tdataVec_2_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_action    (io_fromCsrTrigger_tdataVec_2_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_chain     (io_fromCsrTrigger_tdataVec_2_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_load      (io_fromCsrTrigger_tdataVec_2_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_2_tdata2    (io_fromCsrTrigger_tdataVec_2_tdata2),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_matchType (io_fromCsrTrigger_tdataVec_3_matchType),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_select    (io_fromCsrTrigger_tdataVec_3_select),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_timing    (io_fromCsrTrigger_tdataVec_3_timing),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_action    (io_fromCsrTrigger_tdataVec_3_action),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_chain     (io_fromCsrTrigger_tdataVec_3_chain),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_load      (io_fromCsrTrigger_tdataVec_3_load),
    .tdataVec_io_fromCsrTrigger_tdataVec_3_tdata2    (io_fromCsrTrigger_tdataVec_3_tdata2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_0         (io_fromCsrTrigger_tEnableVec_0),
    .tdataVec_io_fromCsrTrigger_tEnableVec_1         (io_fromCsrTrigger_tEnableVec_1),
    .tdataVec_io_fromCsrTrigger_tEnableVec_2         (io_fromCsrTrigger_tEnableVec_2),
    .tdataVec_io_fromCsrTrigger_tEnableVec_3         (io_fromCsrTrigger_tEnableVec_3),
    .tdataVec_io_fromCsrTrigger_debugMode            (io_fromCsrTrigger_debugMode),
    .tdataVec_io_fromCsrTrigger_triggerCanRaiseBpExp (io_fromCsrTrigger_triggerCanRaiseBpExp),
    .tdataVec_io_fromLoadStore_vaddr                 (s1_vaddr),
    .tdataVec_io_fromLoadStore_isVectorUnitStride    (s1_in_isvec & s1_in_is128bit),
    .tdataVec_io_fromLoadStore_mask                  (s1_in_mask),
    .tdataVec_io_toLoadStore_triggerAction           (s1_trigger_action),
    .tdataVec_io_toLoadStore_triggerVaddr            (s1_trigger_vaddr),
    .tdataVec_io_toLoadStore_triggerMask             (s1_trigger_mask)
  );

  // ---- DTLB / DCache s1 控制 + forward 查询输出 ----------------------------
  assign io_tlb_req_kill            = s1_kill | s1_dly_err;
  assign io_tlb_req_bits_pmp_addr   = s1_in_paddr;
  assign io_dcache_s1_paddr_dup_lsu    = s1_paddr_dup_lsu;
  assign io_dcache_s1_paddr_dup_dcache = s1_paddr_dup_dcache;
  // golden: io_dcache_s1_kill = (s1_kill|s1_dly_err) | s1_tlb_miss | (s1 重算异常 orR)
  assign io_dcache_s1_kill          = s1_kill | s1_dly_err | s1_tlb_miss | s1_has_exc;
  assign io_s1_prefetch_spec        = s1_fire;

  assign io_sbuffer_valid = s1_fwd_query_valid;
  assign io_sbuffer_vaddr = s1_vaddr;
  assign io_sbuffer_paddr = s1_paddr_dup_lsu;
  assign io_ubuffer_valid = s1_fwd_query_valid & s1_nc_with_data;
  assign io_ubuffer_vaddr = s1_vaddr;
  assign io_ubuffer_paddr = s1_paddr_dup_lsu;
  assign io_lsq_forward_valid = s1_fwd_query_valid;
  assign io_lsq_forward_vaddr = s1_vaddr;
  assign io_lsq_forward_paddr = s1_paddr_dup_lsu;
  assign io_lsq_forward_mask  = s1_in_mask;
  assign io_lsq_forward_uop_sqIdx_flag  = s1_in_sqIdx_flag;
  assign io_lsq_forward_uop_sqIdx_value = s1_in_sqIdx_value;
  assign io_lsq_forward_sqIdx_flag      = s1_in_sqIdx_flag;
  assign io_lsq_forward_uop_waitForRobIdx_flag  = s1_in_waitForRobIdx_flag;
  assign io_lsq_forward_uop_waitForRobIdx_value = s1_in_waitForRobIdx_value;
  assign io_lsq_forward_uop_loadWaitBit    = s1_in_loadWaitBit;
  assign io_lsq_forward_uop_loadWaitStrict = s1_in_loadWaitStrict;
  assign io_forward_mshr_valid  = s1_valid & s1_in_forward_tlD;
  assign io_forward_mshr_mshrid = s1_in_mshrid;
  assign io_forward_mshr_paddr  = s1_paddr_dup_lsu;

  // ===========================================================================
  //  store->load nuke 探测（s1 算匹配，s2 用）—— typedef struct + genvar/for
  // ===========================================================================
  // 一条 store 的 nuke 查询：物理地址 + 字节 mask + robIdx + 匹配粒度。
  //   matchType: 1=cacheLine(行) 2=quadWord(128b) 其它=normal(64b)
  typedef struct packed {
    logic                  valid;
    logic                  robIdx_flag;
    logic [7:0]            robIdx_value;
    logic [PADDR_BITS-1:0] paddr;
    logic [MASK_BITS-1:0]  mask;
    logic [1:0]            matchType;
  } nuke_query_t;
  localparam int ST_PIPE_W = 2;  // StorePipelineWidth = 2 条 store 流水
  nuke_query_t [ST_PIPE_W-1:0] s1_stld_q;
  assign s1_stld_q[0] = '{io_stld_nuke_query_0_valid, io_stld_nuke_query_0_bits_robIdx_flag,
                          io_stld_nuke_query_0_bits_robIdx_value, io_stld_nuke_query_0_bits_paddr,
                          io_stld_nuke_query_0_bits_mask, io_stld_nuke_query_0_bits_matchType};
  assign s1_stld_q[1] = '{io_stld_nuke_query_1_valid, io_stld_nuke_query_1_bits_robIdx_flag,
                          io_stld_nuke_query_1_bits_robIdx_value, io_stld_nuke_query_1_bits_paddr,
                          io_stld_nuke_query_1_bits_mask, io_stld_nuke_query_1_bits_matchType};

  // 每条 store 是否与本 load nuke：query 有效 & store 更老 & paddr 按粒度匹配 & mask 交叠。
  logic [ST_PIPE_W-1:0] s1_nuke_hit;
  logic s1_is_match128;
  assign s1_is_match128 = (s1_in_isvec | s1_in_misalignWith16Byte) & s1_in_is128bit;
  genvar gi;
  generate
    for (gi = 0; gi < ST_PIPE_W; gi++) begin : g_stld_nuke
      // 按匹配粒度选 paddr 比较位段。matchType 编码（见 Bundles.StLdNukeMatchType）：
      //   Normal=2'b00→[47:3] / QuadWord=2'b01→[47:4](128b) / CacheLine=2'b10→[47:6](行)
      // 优先级与 Scala PriorityMux 一致：先 CacheLine，再 128b（QuadWord 或 vec/misalign&128），否则 Normal。
      logic pa_match;
      assign pa_match =
          (s1_stld_q[gi].matchType == 2'h2) ? (s1_paddr_dup_lsu[PADDR_BITS-1:6] == s1_stld_q[gi].paddr[PADDR_BITS-1:6]) :
          ((s1_stld_q[gi].matchType == 2'h1) | s1_is_match128) ? (s1_paddr_dup_lsu[PADDR_BITS-1:4] == s1_stld_q[gi].paddr[PADDR_BITS-1:4]) :
                                               (s1_paddr_dup_lsu[PADDR_BITS-1:3] == s1_stld_q[gi].paddr[PADDR_BITS-1:3]);
      assign s1_nuke_hit[gi] =
          s1_stld_q[gi].valid &
          rob_is_after(s1_in_robIdx_flag, s1_in_robIdx_value, s1_stld_q[gi].robIdx_flag, s1_stld_q[gi].robIdx_value) &
          pa_match &
          (|(s1_in_mask & s1_stld_q[gi].mask));
    end
  endgenerate
  // s1 级 nuke：任一 store 命中且非 tlb_miss、非软件预取（与 golden s2_in.rep_info.nuke 一致）
  logic s1_nuke;
  assign s1_nuke = (|s1_nuke_hit) & ~s1_tlb_miss & ~(s1_in_isPrefetch & ~s1_in_isHWPrefetch);

  // ===========================================================================
  //  S1 -> S2 流水寄存器（s2_in，在 s1_fire 时打入）+ S2 控制
  // ---------------------------------------------------------------------------
  //  S2 收 DCache resp、合并 16 路 forward、探测 nuke、算 11 位 replay cause、
  //  判定 uncache/mmio/nc、合并异常，并把结果打入 S3。
  // ===========================================================================
  // S2 流水寄存器（与 golden s2_in_r_* 对应；exceptionVec 用 24 位打包）
  logic                  s2_valid;
  logic [23:0]           s2_in_excVec;
  logic [3:0]            s2_in_trigger;
  logic                  s2_in_preDecode_isRVC, s2_in_ftqPtr_flag;
  logic [5:0]            s2_in_ftqPtr_value;
  logic [3:0]            s2_in_ftqOffset;
  logic [8:0]            s2_in_fuOpType;
  logic                  s2_in_rfWen, s2_in_fpWen;
  logic [7:0]            s2_in_vstart;  logic [1:0] s2_in_veew;
  logic [6:0]            s2_in_uopIdx;
  logic [7:0]            s2_in_pdest;
  logic                  s2_in_robIdx_flag; logic [7:0] s2_in_robIdx_value;
  logic [63:0]           s2_in_enqRsTime, s2_in_selectTime, s2_in_issueTime;
  logic                  s2_in_storeSetHit, s2_in_waitForRobIdx_flag;
  logic [7:0]            s2_in_waitForRobIdx_value;
  logic                  s2_in_loadWaitBit, s2_in_loadWaitStrict;
  logic                  s2_in_lqIdx_flag; logic [6:0] s2_in_lqIdx_value;
  logic                  s2_in_sqIdx_flag; logic [5:0] s2_in_sqIdx_value;
  logic [VADDR_BITS-1:0] s2_in_vaddr;
  logic [63:0]           s2_in_fullva;
  logic                  s2_in_vaNeedExt;
  logic [PADDR_BITS-1:0] s2_in_paddr;
  logic [63:0]           s2_in_gpaddr;
  logic [MASK_BITS-1:0]  s2_in_mask;
  logic [128:0]          s2_in_data;
  logic                  s2_in_tlbMiss, s2_in_nc, s2_in_mmio, s2_in_isHyper, s2_in_isForVSnonLeafPTE;
  logic                  s2_in_isPrefetch, s2_in_isHWPrefetch, s2_in_isvec, s2_in_is128bit;
  logic [7:0]            s2_in_elemIdx;
  logic [2:0]            s2_in_alignedType;
  logic [3:0]            s2_in_mbIndex, s2_in_reg_offset;
  logic [7:0]            s2_in_elemIdxInsideVd;
  logic [VADDR_BITS-1:0] s2_in_vecVaddrOffset;
  logic [MASK_BITS-1:0]  s2_in_vecTriggerMask;
  logic                  s2_in_vecActive, s2_in_isLoadReplay, s2_in_isFastReplay, s2_in_isFirstIssue;
  logic                  s2_in_hasROBEntry, s2_in_forward_tlD, s2_in_delayedLoadError;
  logic [6:0]            s2_in_schedIndex;
  logic                  s2_in_frm_mabuf, s2_in_isMisalign, s2_in_isFinalSplit;
  logic                  s2_in_misalignWith16Byte, s2_in_misalignNeedWakeUp;
  logic                  s2_in_rep_info_cause_9;  // s1 级算出的 nuke（store->load 违例）
  // S2 独立的小型流水态（vec/trigger）
  logic                  s2_vecActive, s2_isvec, s2_trigger_dmode;
  logic [1:0]            s2_pbmt;
  logic                  s2_nc_with_data;
  logic                  s2_mis_align_REG;  // RegNext(io_csrCtrl_hd_misalign_ld_enable)

  // ---- redirect 打一拍（s1 已有，s2/s3 复用 s1_redir_*_d 当拍+上拍）-----------
  // s2_kill / s3_ready 只看当拍 redirect（与 golden 一致，不含上一拍）
  logic s2_kill, s2_can_go, s2_fire;
  assign s2_kill   = rob_need_flush(io_redirect_valid, io_redirect_bits_level,
                       s2_in_robIdx_flag, s2_in_robIdx_value,
                       io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
  assign s2_ready  = ~s2_valid | s2_kill | s3_ready;
  assign s2_can_go = s3_ready;
  assign s2_fire   = s2_valid & ~s2_kill & s3_ready;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_valid <= 1'b0; s2_vecActive <= 1'b1; s2_isvec <= 1'b0; s2_trigger_dmode <= 1'b0;
    end else begin
      s2_valid <= s1_fire | ~(s2_fire | s2_kill) & s2_valid;
      if (s1_fire) begin
        s2_vecActive <= s1_in_vecActive; s2_isvec <= s1_in_isvec; s2_trigger_dmode <= s1_trigger_dmode;
      end
    end
  end
  // ---- s1 侧为 s2 预备的量（vecVaddrOffset / 进 s2 的 exceptionVec） -----------
  logic s1_vecTrig;  // RegEnable 触发掩码源（trigger 命中）
  assign s1_vecTrig = s1_trigger_dmode | s1_trigger_bp;
  // vecVaddrOffset：trigger 命中时取 triggerVaddr-baseVaddr，否则 vaddr+mask首字节偏移-baseVaddr
  // 找 mask 最低有效字节偏移（与 golden s2_in_r_vecVaddrOffset 内的优先编码一致）
  logic [3:0] s1_mask_lsb_off;
  always_comb begin
    s1_mask_lsb_off = 4'h0;
    for (int b = 0; b < MASK_BITS; b++)
      if (s1_in_mask[b]) begin s1_mask_lsb_off = 4'(b); break; end
  end
  logic [VADDR_BITS-1:0] s1_vecVaddrOffset;
  assign s1_vecVaddrOffset = s1_vecTrig
      ? VADDR_BITS'(s1_trigger_vaddr - s1_in_vecBaseVaddr)
      : VADDR_BITS'((s1_in_vaddr + {{(VADDR_BITS-4){1'b0}}, s1_mask_lsb_off}) - s1_in_vecBaseVaddr);
  // 进 s2 的 24 位 exceptionVec：位 3/4/5/13/19/21 在 s1->s2 边界用 s1 重算的异常覆盖，
  // 其余位从 s1_in_excVec 透传（与 golden s2_in_r_uop_exceptionVec_* 加载一致）。
  logic [23:0] s1_excVec_s2in;
  always_comb begin
    s1_excVec_s2in            = s1_in_excVec;
    s1_excVec_s2in[EXC_BP]    = s1_trigger_bp;   // vec3 breakpoint
    s1_excVec_s2in[EXC_LAM]   = s1_exc_lam;      // vec4 load addr misaligned
    s1_excVec_s2in[EXC_LAF]   = s1_exc_laf;      // vec5 load access fault
    s1_excVec_s2in[EXC_LPF]   = s1_exc_lpf;      // vec13 load page fault
    s1_excVec_s2in[EXC_HWE]   = s1_exc_hwe;      // vec19 hardware error
    s1_excVec_s2in[EXC_LGPF]  = s1_exc_lgpf;     // vec21 load guest page fault
  end

  // s1->s2 寄存器内容（s1_fire 时锁存）
  always_ff @(posedge clock) if (s1_fire) begin
    s2_in_excVec       <= s1_excVec_s2in;
    s2_in_trigger      <= s1_trigger_action;
    s2_in_preDecode_isRVC <= s1_in_preDecode_isRVC;
    s2_in_ftqPtr_flag  <= s1_in_ftqPtr_flag;  s2_in_ftqPtr_value <= s1_in_ftqPtr_value;
    s2_in_ftqOffset    <= s1_in_ftqOffset;
    s2_in_fuOpType     <= s1_in_fuOpType;
    s2_in_rfWen        <= s1_in_rfWen;        s2_in_fpWen <= s1_in_fpWen;
    s2_in_vstart       <= s1_in_vstart;       s2_in_veew <= s1_in_veew;
    s2_in_uopIdx       <= s1_in_uopIdx;       s2_in_pdest <= s1_in_pdest;
    s2_in_robIdx_flag  <= s1_in_robIdx_flag;  s2_in_robIdx_value <= s1_in_robIdx_value;
    s2_in_enqRsTime    <= s1_in_enqRsTime;    s2_in_selectTime <= s1_in_selectTime; s2_in_issueTime <= s1_in_issueTime;
    s2_in_storeSetHit  <= s1_in_storeSetHit;
    s2_in_waitForRobIdx_flag <= s1_in_waitForRobIdx_flag; s2_in_waitForRobIdx_value <= s1_in_waitForRobIdx_value;
    s2_in_loadWaitBit  <= s1_in_loadWaitBit;  s2_in_loadWaitStrict <= s1_in_loadWaitStrict;
    s2_in_lqIdx_flag   <= s1_in_lqIdx_flag;   s2_in_lqIdx_value <= s1_in_lqIdx_value;
    s2_in_sqIdx_flag   <= s1_in_sqIdx_flag;   s2_in_sqIdx_value <= s1_in_sqIdx_value;
    s2_in_vaddr        <= s1_in_vaddr;
    s2_in_fullva       <= s1_in_frm_mabuf ? {14'h0, s1_in_vaddr} : io_tlb_resp_bits_fullva;
    s2_in_vaNeedExt    <= io_tlb_resp_bits_excp_0_vaNeedExt;
    s2_in_paddr        <= s1_paddr_dup_lsu;
    s2_in_gpaddr       <= s1_in_isFastReplay ? {16'h0, s1_in_paddr} : io_tlb_resp_bits_gpaddr_0;
    s2_in_mask         <= s1_in_mask;
    s2_in_data         <= s1_in_data;
    s2_in_tlbMiss      <= s1_tlb_miss;
    s2_in_nc           <= (s1_in_isnc | s1_pbmt == PBMT_NC) & ~s1_in_isPrefetch;
    s2_in_mmio         <= s1_pbmt == PBMT_IO;
    s2_in_isHyper      <= io_tlb_resp_bits_excp_0_isHyper;
    s2_in_isForVSnonLeafPTE <= io_tlb_resp_bits_isForVSnonLeafPTE;
    s2_in_isPrefetch   <= s1_in_isPrefetch;   s2_in_isHWPrefetch <= s1_in_isHWPrefetch;
    s2_in_isvec        <= s1_in_isvec;        s2_in_is128bit <= s1_in_is128bit;
    s2_in_elemIdx      <= s1_in_elemIdx;
    s2_in_alignedType  <= s1_in_alignedType;
    s2_in_mbIndex      <= s1_in_mbIndex;      s2_in_reg_offset <= s1_in_reg_offset;
    s2_in_elemIdxInsideVd <= s1_in_elemIdxInsideVd;
    s2_in_vecVaddrOffset  <= s1_vecVaddrOffset;
    s2_in_vecTriggerMask  <= s1_vecTrig ? s1_trigger_mask : 16'h0;
    s2_in_vecActive    <= s1_in_vecActive;
    s2_in_isLoadReplay <= s1_in_isLoadReplay; s2_in_isFastReplay <= s1_in_isFastReplay;
    s2_in_isFirstIssue <= s1_in_first_issue;  s2_in_hasROBEntry <= s1_in_has_rob;
    s2_in_forward_tlD  <= s1_in_forward_tlD;  s2_in_delayedLoadError <= s1_dly_err;
    s2_in_schedIndex   <= s1_in_schedIndex;
    s2_in_frm_mabuf    <= s1_in_frm_mabuf;
    s2_in_isMisalign   <= ~s1_dly_err & ~s1_lam_clear & s1_in_isMisalign;
    s2_in_isFinalSplit <= s1_in_isFinalSplit;
    s2_in_misalignWith16Byte <= s1_in_misalignWith16Byte;
    s2_in_misalignNeedWakeUp <= s1_in_misalignNeedWakeUp;
    s2_in_rep_info_cause_9   <= s1_nuke;
  end

  // ---- S2 异常合并（_GEN_3 抑制：prefetch/tlbMiss 路径清除大多数异常）---------
  logic s2_supress;  // golden _GEN_3
  assign s2_supress = ~s2_in_delayedLoadError &
                      (s2_in_isPrefetch | (s2_in_tlbMiss & ~s2_in_excVec[EXC_BP]));
  logic s2_exc_vec3, s2_exc_vec5, s2_exc_vec13, s2_exc_vec19, s2_exc_vec21;
  assign s2_exc_vec3  = ~s2_supress & s2_in_excVec[EXC_BP];
  // uncache / mmio 判定（先于 vec5 异常使用）
  logic s2_actually_uncache, s2_uncache, s2_tlb_hit, s2_mmio;
  assign s2_actually_uncache =
      (~s2_in_tlbMiss & ~(s2_vecActive & (s2_in_excVec[EXC_LAF] | s2_in_excVec[EXC_LPF] | s2_in_excVec[EXC_LGPF]))
        & (s2_pbmt == PBMT_NONE) & io_pmp_mmio) | s2_in_nc | s2_in_mmio;
  assign s2_uncache = ~s2_in_isPrefetch & s2_actually_uncache;
  assign s2_exc_vec5  = ~s2_supress &
      (s2_in_delayedLoadError ? s2_in_excVec[EXC_LAF]
       : s2_vecActive & (s2_in_excVec[EXC_LAF] | io_pmp_ld | (s2_isvec & s2_uncache)));
  assign s2_exc_vec13 = ~s2_supress & s2_in_excVec[EXC_LPF];
  assign s2_exc_vec19 = ~s2_supress & s2_in_excVec[EXC_HWE];
  assign s2_exc_vec21 = ~s2_supress & s2_in_excVec[EXC_LGPF];
  logic s2_exception;
  assign s2_exception = s2_vecActive &
      (s2_trigger_dmode | s2_exc_vec21 | s2_exc_vec19 | s2_exc_vec13 | s2_exc_vec5 |
       (~s2_supress & s2_in_excVec[EXC_LAM]) | s2_exc_vec3);

  // ---- S2 forward 合并：16 路逐字节（lsq | sbuffer | ubuffer 掩码或）----------
  logic [MASK_BITS-1:0] s2_fwd_mask;
  logic [MASK_BITS-1:0] s2_lsq_fwd_mask, s2_sb_fwd_mask, s2_ub_fwd_mask;
  assign s2_lsq_fwd_mask = {io_lsq_forward_forwardMask_15, io_lsq_forward_forwardMask_14,
      io_lsq_forward_forwardMask_13, io_lsq_forward_forwardMask_12, io_lsq_forward_forwardMask_11,
      io_lsq_forward_forwardMask_10, io_lsq_forward_forwardMask_9, io_lsq_forward_forwardMask_8,
      io_lsq_forward_forwardMask_7, io_lsq_forward_forwardMask_6, io_lsq_forward_forwardMask_5,
      io_lsq_forward_forwardMask_4, io_lsq_forward_forwardMask_3, io_lsq_forward_forwardMask_2,
      io_lsq_forward_forwardMask_1, io_lsq_forward_forwardMask_0};
  assign s2_sb_fwd_mask = {io_sbuffer_forwardMask_15, io_sbuffer_forwardMask_14,
      io_sbuffer_forwardMask_13, io_sbuffer_forwardMask_12, io_sbuffer_forwardMask_11,
      io_sbuffer_forwardMask_10, io_sbuffer_forwardMask_9, io_sbuffer_forwardMask_8,
      io_sbuffer_forwardMask_7, io_sbuffer_forwardMask_6, io_sbuffer_forwardMask_5,
      io_sbuffer_forwardMask_4, io_sbuffer_forwardMask_3, io_sbuffer_forwardMask_2,
      io_sbuffer_forwardMask_1, io_sbuffer_forwardMask_0};
  assign s2_ub_fwd_mask = {io_ubuffer_forwardMask_15, io_ubuffer_forwardMask_14,
      io_ubuffer_forwardMask_13, io_ubuffer_forwardMask_12, io_ubuffer_forwardMask_11,
      io_ubuffer_forwardMask_10, io_ubuffer_forwardMask_9, io_ubuffer_forwardMask_8,
      io_ubuffer_forwardMask_7, io_ubuffer_forwardMask_6, io_ubuffer_forwardMask_5,
      io_ubuffer_forwardMask_4, io_ubuffer_forwardMask_3, io_ubuffer_forwardMask_2,
      io_ubuffer_forwardMask_1, io_ubuffer_forwardMask_0};
  assign s2_fwd_mask = s2_lsq_fwd_mask | s2_sb_fwd_mask | s2_ub_fwd_mask;

  // d-channel / mshr forward（在 S1 锁存 d-chan 数据，S2 用）
  logic s2_fwd_frm_d_chan;
  logic [7:0] s2_fwd_data_frm_d_chan [MASK_BITS];
  logic s2_fwd_frm_d_chan_or_mshr;
  assign s2_fwd_frm_d_chan_or_mshr = io_forward_mshr_forward_result_valid &
      (s2_fwd_frm_d_chan | io_forward_mshr_forward_mshr);

  // full forward：被覆盖的字节全部由 forward 提供，且 lsq 未报 dataInvalid
  logic s2_full_fwd;
  assign s2_full_fwd = ((~s2_fwd_mask & s2_in_mask) == 16'h0) & ~io_lsq_forward_dataInvalid;

  // ---- S2 dcache 结果 / replay cause 来源量 --------------------------------
  logic s2_mem_amb_REG, s2_fwd_fail_REG, s2_tlb_hit_REG;
  logic s2_mem_amb, s2_fwd_fail, s2_dcache_miss, s2_mq_nack, s2_bank_conflict;
  assign s2_mem_amb = s2_in_storeSetHit & io_lsq_forward_addrInvalid & s2_mem_amb_REG;
  assign s2_fwd_fail = io_lsq_forward_dataInvalid & s2_fwd_fail_REG;
  assign s2_dcache_miss   = io_dcache_resp_bits_miss   & ~s2_fwd_frm_d_chan_or_mshr & ~s2_full_fwd & ~s2_in_nc;
  assign s2_mq_nack       = io_dcache_s2_mq_nack       & ~s2_fwd_frm_d_chan_or_mshr & ~s2_full_fwd & ~s2_in_nc;
  assign s2_bank_conflict = io_dcache_s2_bank_conflict & ~s2_fwd_frm_d_chan_or_mshr & ~s2_full_fwd & ~s2_in_nc;
  assign s2_tlb_hit = s2_tlb_hit_REG;
  assign s2_mmio = ~s2_in_isPrefetch & ~s2_exception & ~s2_in_tlbMiss &
      ((s2_pbmt == PBMT_NC | s2_pbmt == PBMT_IO) ? s2_in_mmio : (s2_tlb_hit & io_pmp_mmio));

  // ---- S2 nuke 探测（2 路 store；与 golden 同构）---------------------------
  //  注意：golden 在 S2 用「当拍 live 的 store 查询输入」(io_stld_nuke_query_*)
  //  与「S2 锁存的 load 信息」(s2_in_*) 比较，而非 S1 锁存的 store 查询副本。
  //  这里用 s2_stld_q[gi] 直接绑当拍 io 输入，避免一拍陈旧导致 s2_nuke 发散。
  logic s2_is_match128;
  assign s2_is_match128 = (s2_in_isvec | s2_in_misalignWith16Byte) & s2_in_is128bit;
  nuke_query_t [ST_PIPE_W-1:0] s2_stld_q;
  assign s2_stld_q[0] = '{io_stld_nuke_query_0_valid, io_stld_nuke_query_0_bits_robIdx_flag,
                          io_stld_nuke_query_0_bits_robIdx_value, io_stld_nuke_query_0_bits_paddr,
                          io_stld_nuke_query_0_bits_mask, io_stld_nuke_query_0_bits_matchType};
  assign s2_stld_q[1] = '{io_stld_nuke_query_1_valid, io_stld_nuke_query_1_bits_robIdx_flag,
                          io_stld_nuke_query_1_bits_robIdx_value, io_stld_nuke_query_1_bits_paddr,
                          io_stld_nuke_query_1_bits_mask, io_stld_nuke_query_1_bits_matchType};
  logic [ST_PIPE_W-1:0] s2_nuke_hit;
  generate
    for (gi = 0; gi < ST_PIPE_W; gi++) begin : g_s2_nuke
      logic [1:0] mt; logic pa_match;
      assign mt = s2_stld_q[gi].matchType;
      // matchType: CacheLine=2'b10→[47:6] / QuadWord=2'b01→[47:4] / Normal=2'b00→[47:3]
      assign pa_match =
          (mt == 2'h2) ? (s2_in_paddr[PADDR_BITS-1:6] == s2_stld_q[gi].paddr[PADDR_BITS-1:6]) :
          ((mt == 2'h1) | s2_is_match128) ? (s2_in_paddr[PADDR_BITS-1:4] == s2_stld_q[gi].paddr[PADDR_BITS-1:4]) :
                                            (s2_in_paddr[PADDR_BITS-1:3] == s2_stld_q[gi].paddr[PADDR_BITS-1:3]);
      assign s2_nuke_hit[gi] = s2_stld_q[gi].valid &
          rob_is_after(s2_in_robIdx_flag, s2_in_robIdx_value, s2_stld_q[gi].robIdx_flag, s2_stld_q[gi].robIdx_value) &
          pa_match & (|(s2_in_mask & s2_stld_q[gi].mask));
    end
  endgenerate
  logic s2_nuke;
  assign s2_nuke = ((|s2_nuke_hit) & ~s2_in_tlbMiss) | s2_in_rep_info_cause_9;

  // ---- S2 troublem（需要后续处理：非异常/非uncache/非prefetch/非延迟错误）------
  logic s2_troublem, s2_dcache_fast_rep, s2_fwd_vp_match_invalid;
  assign s2_troublem = ~s2_exception & (~s2_uncache | s2_nc_with_data) &
                       ~s2_in_isPrefetch & ~s2_in_delayedLoadError;
  assign s2_dcache_fast_rep = s2_mq_nack | (~s2_dcache_miss & s2_bank_conflict);
  assign s2_fwd_vp_match_invalid = io_lsq_forward_matchInvalid | io_sbuffer_matchInvalid | io_ubuffer_matchInvalid;

  // ---- S2 replay cause（11 位中 s2 产生 9 位；C_WF/C_MF 在 s3 产生）----------
  logic s2_cause [CAUSE_NUM];
  assign s2_cause[C_MA]  = s2_mem_amb       & s2_troublem;
  assign s2_cause[C_TM]  = s2_in_tlbMiss    & s2_troublem;
  assign s2_cause[C_FF]  = s2_fwd_fail      & s2_troublem;
  assign s2_cause[C_DR]  = s2_mq_nack       & s2_troublem;
  assign s2_cause[C_DM]  = s2_dcache_miss   & s2_troublem;
  assign s2_cause[C_WF]  = 1'b0;
  assign s2_cause[C_BC]  = s2_bank_conflict & s2_troublem;
  assign s2_cause[C_RAR] = io_lsq_ldld_nuke_query_req_valid & ~io_lsq_ldld_nuke_query_req_ready & s2_troublem;
  assign s2_cause[C_RAW] = io_lsq_stld_nuke_query_req_valid & ~io_lsq_stld_nuke_query_req_ready & s2_troublem;
  assign s2_cause[C_NK]  = s2_nuke          & s2_troublem;
  assign s2_cause[C_MF]  = 1'b0;

  // ---- S2 stld/ldld nuke 查询输出 ------------------------------------------
  logic s2_data_valid_for_nuke;
  assign s2_data_valid_for_nuke = (s2_full_fwd | io_forward_mshr_forward_result_valid) | s2_nc_with_data | ~s2_dcache_miss;
  assign io_lsq_ldld_nuke_query_req_valid = s2_valid & ~s2_in_isPrefetch;
  assign io_lsq_stld_nuke_query_req_valid = s2_valid & ~(s2_dcache_fast_rep | s2_nuke) & s2_troublem;

  // ---- S2 实异常（用于 s3_exception / safe_writeback；含 d-chan/mshr corrupt）--
  logic s2_isMisalign, s2_mis_align, s2_real_exc_vec4, s2_real_exc_vec5, s2_real_exception, s2_safe_wakeup;
  assign s2_isMisalign = ~s2_supress & s2_in_isMisalign;
  assign s2_mis_align  = s2_valid & s2_mis_align_REG & s2_isMisalign & ~s2_in_misalignWith16Byte &
                         ~s2_exc_vec3 & ~s2_trigger_dmode & ~s2_uncache;
  assign s2_real_exc_vec4 = (s2_isMisalign | s2_in_frm_mabuf) & s2_uncache & ~s2_isvec;
  assign s2_real_exc_vec5 = s2_exc_vec5 |
      (s2_fwd_frm_d_chan & io_tl_d_channel_corrupt) |
      (io_forward_mshr_forward_result_valid & io_forward_mshr_forward_mshr & io_forward_mshr_corrupt);
  assign s2_real_exception = s2_vecActive &
      (s2_trigger_dmode | s2_exc_vec21 | s2_exc_vec19 | s2_exc_vec13 | s2_real_exc_vec5 | s2_real_exc_vec4 | s2_exc_vec3);
  logic s2_cause_orr9;
  assign s2_cause_orr9 = s2_cause[C_NK] | s2_cause[C_RAW] | s2_cause[C_RAR] | s2_cause[C_BC] |
                         s2_cause[C_DM] | s2_cause[C_DR] | s2_cause[C_FF] | s2_cause[C_TM] | s2_cause[C_MA];
  assign s2_safe_wakeup = ~s2_cause_orr9 & ~s2_mmio & (~s2_in_nc | s2_nc_with_data) &
                          ~s2_mis_align & ~s2_real_exception;

  // ---- S2 forward 合并数据（128 位 merged，进 s3）---------------------------
  // tlD/mshr raw data 选择（与 golden s2_ld_raw_data_frm_tlD 一致）
  logic s2_use_dchan;
  assign s2_use_dchan = s2_fwd_frm_d_chan & ~s2_nc_with_data & io_forward_mshr_forward_result_valid;
  logic [127:0] s2_dchan_data, s2_mshr_data, s2_raw_data;
  assign s2_dchan_data = {s2_fwd_data_frm_d_chan[15], s2_fwd_data_frm_d_chan[14], s2_fwd_data_frm_d_chan[13],
      s2_fwd_data_frm_d_chan[12], s2_fwd_data_frm_d_chan[11], s2_fwd_data_frm_d_chan[10], s2_fwd_data_frm_d_chan[9],
      s2_fwd_data_frm_d_chan[8], s2_fwd_data_frm_d_chan[7], s2_fwd_data_frm_d_chan[6], s2_fwd_data_frm_d_chan[5],
      s2_fwd_data_frm_d_chan[4], s2_fwd_data_frm_d_chan[3], s2_fwd_data_frm_d_chan[2], s2_fwd_data_frm_d_chan[1],
      s2_fwd_data_frm_d_chan[0]};
  assign s2_mshr_data = {io_forward_mshr_forwardData_15, io_forward_mshr_forwardData_14, io_forward_mshr_forwardData_13,
      io_forward_mshr_forwardData_12, io_forward_mshr_forwardData_11, io_forward_mshr_forwardData_10, io_forward_mshr_forwardData_9,
      io_forward_mshr_forwardData_8, io_forward_mshr_forwardData_7, io_forward_mshr_forwardData_6, io_forward_mshr_forwardData_5,
      io_forward_mshr_forwardData_4, io_forward_mshr_forwardData_3, io_forward_mshr_forwardData_2, io_forward_mshr_forwardData_1,
      io_forward_mshr_forwardData_0};
  always_comb begin
    if (s2_use_dchan | (io_forward_mshr_forward_mshr & ~s2_nc_with_data & io_forward_mshr_forward_result_valid))
      s2_raw_data = s2_use_dchan ? s2_dchan_data : s2_mshr_data;
    else if (s2_nc_with_data)
      s2_raw_data = s2_in_paddr[3] ? {s2_in_data[63:0], 64'h0} : s2_in_data[127:0];
    else
      s2_raw_data = io_dcache_resp_bits_data;
  end
  // 16 路逐字节 merged：每字节优先 lsq>（nc?ubuffer:sbuffer）>raw
  logic [7:0] s2_sb_fwd_data [MASK_BITS], s2_ub_fwd_data [MASK_BITS], s2_lsq_fwd_data [MASK_BITS];
  assign s2_lsq_fwd_data = '{io_lsq_forward_forwardData_0, io_lsq_forward_forwardData_1, io_lsq_forward_forwardData_2,
      io_lsq_forward_forwardData_3, io_lsq_forward_forwardData_4, io_lsq_forward_forwardData_5, io_lsq_forward_forwardData_6,
      io_lsq_forward_forwardData_7, io_lsq_forward_forwardData_8, io_lsq_forward_forwardData_9, io_lsq_forward_forwardData_10,
      io_lsq_forward_forwardData_11, io_lsq_forward_forwardData_12, io_lsq_forward_forwardData_13, io_lsq_forward_forwardData_14,
      io_lsq_forward_forwardData_15};
  assign s2_sb_fwd_data = '{io_sbuffer_forwardData_0, io_sbuffer_forwardData_1, io_sbuffer_forwardData_2,
      io_sbuffer_forwardData_3, io_sbuffer_forwardData_4, io_sbuffer_forwardData_5, io_sbuffer_forwardData_6,
      io_sbuffer_forwardData_7, io_sbuffer_forwardData_8, io_sbuffer_forwardData_9, io_sbuffer_forwardData_10,
      io_sbuffer_forwardData_11, io_sbuffer_forwardData_12, io_sbuffer_forwardData_13, io_sbuffer_forwardData_14,
      io_sbuffer_forwardData_15};
  assign s2_ub_fwd_data = '{io_ubuffer_forwardData_0, io_ubuffer_forwardData_1, io_ubuffer_forwardData_2,
      io_ubuffer_forwardData_3, io_ubuffer_forwardData_4, io_ubuffer_forwardData_5, io_ubuffer_forwardData_6,
      io_ubuffer_forwardData_7, io_ubuffer_forwardData_8, io_ubuffer_forwardData_9, io_ubuffer_forwardData_10,
      io_ubuffer_forwardData_11, io_ubuffer_forwardData_12, io_ubuffer_forwardData_13, io_ubuffer_forwardData_14,
      io_ubuffer_forwardData_15};
  logic [7:0] s2_merged_byte [MASK_BITS];
  generate
    for (gi = 0; gi < MASK_BITS; gi++) begin : g_merge_byte
      assign s2_merged_byte[gi] = s2_fwd_mask[gi]
          ? (s2_lsq_fwd_mask[gi] ? s2_lsq_fwd_data[gi]
             : (s2_nc_with_data ? s2_ub_fwd_data[gi] : s2_sb_fwd_data[gi]))
          : s2_raw_data[gi*8 +: 8];
    end
  endgenerate
  logic [127:0] s2_merged_data;
  assign s2_merged_data = {s2_merged_byte[15], s2_merged_byte[14], s2_merged_byte[13], s2_merged_byte[12],
      s2_merged_byte[11], s2_merged_byte[10], s2_merged_byte[9], s2_merged_byte[8], s2_merged_byte[7],
      s2_merged_byte[6], s2_merged_byte[5], s2_merged_byte[4], s2_merged_byte[3], s2_merged_byte[2],
      s2_merged_byte[1], s2_merged_byte[0]};

  // ---- S2 vstart 输出（vec 非 replay 路径用 vecVaddrOffset>>veew）------------
  logic [VADDR_BITS-1:0] s2_vstart_shift;
  assign s2_vstart_shift = s2_in_vecVaddrOffset >> s2_in_veew;
  logic [7:0] s2_out_vstart;
  assign s2_out_vstart = (s2_in_isLoadReplay | s2_in_isFastReplay) ? s2_in_vstart : s2_vstart_shift[7:0];

  // ---- S2 forward d-chan 锁存（s1 paddr 选 256 位 tlD 数据窗口）-------------
  logic s1_all_match;
  assign s1_all_match = io_forward_mshr_valid & io_tl_d_channel_valid &
      (s1_in_mshrid == io_tl_d_channel_mshrid) & (s1_paddr_dup_lsu[5] == io_tl_d_channel_last);
  logic [63:0] s1_tlD_lo, s1_tlD_hi;
  logic [1:0]  s1_tlD_sel;
  assign s1_tlD_sel = s1_paddr_dup_lsu[4:3];
  always_comb begin
    priority case (s1_tlD_sel)
      2'h0: s1_tlD_lo = io_tl_d_channel_data[63:0];
      2'h1: s1_tlD_lo = io_tl_d_channel_data[127:64];
      2'h2: s1_tlD_lo = io_tl_d_channel_data[191:128];
      default: s1_tlD_lo = io_tl_d_channel_data[255:192];
    endcase
    priority case (2'(s1_tlD_sel + 2'h1))
      2'h0: s1_tlD_hi = io_tl_d_channel_data[63:0];
      2'h1: s1_tlD_hi = io_tl_d_channel_data[127:64];
      2'h2: s1_tlD_hi = io_tl_d_channel_data[191:128];
      default: s1_tlD_hi = io_tl_d_channel_data[255:192];
    endcase
  end
  logic [63:0] s1_tlD_use_hi;  // golden _GEN_81
  assign s1_tlD_use_hi = s1_paddr_dup_lsu[3] ? s1_tlD_lo : s1_tlD_hi;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s2_fwd_frm_d_chan <= 1'b0;
      for (int b = 0; b < MASK_BITS; b++) s2_fwd_data_frm_d_chan[b] <= 8'h0;
    end else begin
      s2_fwd_frm_d_chan <= s1_all_match;
      if (s1_all_match) begin
        s2_fwd_data_frm_d_chan[0] <= s1_tlD_lo[7:0];    s2_fwd_data_frm_d_chan[1] <= s1_tlD_lo[15:8];
        s2_fwd_data_frm_d_chan[2] <= s1_tlD_lo[23:16];  s2_fwd_data_frm_d_chan[3] <= s1_tlD_lo[31:24];
        s2_fwd_data_frm_d_chan[4] <= s1_tlD_lo[39:32];  s2_fwd_data_frm_d_chan[5] <= s1_tlD_lo[47:40];
        s2_fwd_data_frm_d_chan[6] <= s1_tlD_lo[55:48];  s2_fwd_data_frm_d_chan[7] <= s1_tlD_lo[63:56];
        s2_fwd_data_frm_d_chan[8] <= s1_tlD_use_hi[7:0];    s2_fwd_data_frm_d_chan[9]  <= s1_tlD_use_hi[15:8];
        s2_fwd_data_frm_d_chan[10] <= s1_tlD_use_hi[23:16]; s2_fwd_data_frm_d_chan[11] <= s1_tlD_use_hi[31:24];
        s2_fwd_data_frm_d_chan[12] <= s1_tlD_use_hi[39:32]; s2_fwd_data_frm_d_chan[13] <= s1_tlD_use_hi[47:40];
        s2_fwd_data_frm_d_chan[14] <= s1_tlD_use_hi[55:48]; s2_fwd_data_frm_d_chan[15] <= s1_tlD_use_hi[63:56];
      end
    end
  end
  // S2 小型流水寄存器（mem_amb/fwd_fail/tlb_hit/mis_align enable / pbmt）
  always_ff @(posedge clock) begin
    s2_mem_amb_REG  <= io_lsq_forward_valid;
    s2_fwd_fail_REG <= io_lsq_forward_valid;
    s2_tlb_hit_REG  <= s1_tlb_hit;
    s2_nc_with_data <= s1_nc_with_data;
    if (s1_fire) s2_pbmt <= s1_pbmt;
  end
  // golden s2_mis_align_last_REG 在异步复位块内(复位=0)——对齐
  always_ff @(posedge clock or posedge reset) begin
    if (reset) s2_mis_align_REG <= 1'b0;
    else       s2_mis_align_REG <= io_csrCtrl_hd_misalign_ld_enable;
  end

  // ---- S2 prefetch train（valid 打一拍 + inputReg 锁存）----------------------
  logic s2_prefetch_train_valid, s2_prefetch_train_l1_valid;
  assign s2_prefetch_train_valid    = s2_valid & ~s2_actually_uncache & (~s2_in_tlbMiss | s2_in_isHWPrefetch);
  assign s2_prefetch_train_l1_valid = s2_valid & ~s2_actually_uncache;
  logic                  pf_tr_valid_d, pf_tr_l1_valid_d;
  logic                  pf_tr_robIdx_flag; logic [7:0] pf_tr_robIdx_value;
  logic [VADDR_BITS-1:0] pf_tr_vaddr;       logic [PADDR_BITS-1:0] pf_tr_paddr;
  logic                  pf_tr_isFirstIssue, pf_tr_miss; logic [2:0] pf_tr_meta;
  logic                  pf_tr1_robIdx_flag; logic [7:0] pf_tr1_robIdx_value;
  logic [VADDR_BITS-1:0] pf_tr1_vaddr;       logic pf_tr1_isFirstIssue, pf_tr1_miss; logic [2:0] pf_tr1_meta;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin pf_tr_valid_d <= 1'b0; pf_tr_l1_valid_d <= 1'b0; end
    else begin pf_tr_valid_d <= s2_prefetch_train_valid; pf_tr_l1_valid_d <= s2_prefetch_train_l1_valid; end
  end
  always_ff @(posedge clock) begin
    if (s2_prefetch_train_valid) begin
      pf_tr_robIdx_flag <= s2_in_robIdx_flag; pf_tr_robIdx_value <= s2_in_robIdx_value;
      pf_tr_vaddr <= s2_in_vaddr; pf_tr_paddr <= s2_in_paddr; pf_tr_isFirstIssue <= s2_in_isFirstIssue;
      pf_tr_miss <= io_dcache_resp_bits_miss; pf_tr_meta <= io_dcache_resp_bits_meta_prefetch;
    end
    if (s2_prefetch_train_l1_valid) begin
      pf_tr1_robIdx_flag <= s2_in_robIdx_flag; pf_tr1_robIdx_value <= s2_in_robIdx_value;
      pf_tr1_vaddr <= s2_in_vaddr; pf_tr1_isFirstIssue <= s2_in_isFirstIssue;
      pf_tr1_miss <= io_dcache_resp_bits_miss; pf_tr1_meta <= io_dcache_resp_bits_meta_prefetch;
    end
  end

  // ---- S2 mmio writeback 影子链（uncache 来源在 s0 即进，s2/s3 各打一拍）------
  logic s2_mmio_req_valid_d, s2_mmio_req_valid_d2;
  logic s2_mmio_v3, s2_mmio_v4, s2_mmio_v5, s2_mmio_v13, s2_mmio_v19, s2_mmio_v21;
  logic [3:0] s2_mmio_trigger; logic s2_mmio_rfWen, s2_mmio_fpWen, s2_mmio_flushPipe;
  logic [7:0] s2_mmio_pdest, s2_mmio_robIdx_value; logic s2_mmio_robIdx_flag;
  logic [63:0] s2_mmio_enqRsTime, s2_mmio_selectTime, s2_mmio_issueTime;
  logic s2_mmio_replayInst, s2_mmio_isMMIO, s2_mmio_isNCIO, s2_mmio_isPerfCnt;
  logic s2_mmio_v3_1, s2_mmio_v4_1, s2_mmio_v5_1, s2_mmio_v13_1, s2_mmio_v19_1, s2_mmio_v21_1;
  logic [3:0] s2_mmio_trigger_1; logic s2_mmio_rfWen_1, s2_mmio_fpWen_1, s2_mmio_flushPipe_1;
  logic [7:0] s2_mmio_pdest_1, s2_mmio_robIdx_value_1; logic s2_mmio_robIdx_flag_1;
  logic [63:0] s2_mmio_enqRsTime_1, s2_mmio_selectTime_1, s2_mmio_issueTime_1;
  logic s2_mmio_replayInst_1, s2_mmio_isMMIO_1, s2_mmio_isNCIO_1, s2_mmio_isPerfCnt_1;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin s2_mmio_req_valid_d <= 1'b0; s2_mmio_req_valid_d2 <= 1'b0; end
    else begin
      s2_mmio_req_valid_d   <= s0_mmio_fire & io_lsq_uncache_valid;
      s2_mmio_req_valid_d2 <= s2_mmio_req_valid_d;
    end
  end
  always_ff @(posedge clock) begin
    s2_mmio_v3  <= io_lsq_uncache_bits_uop_exceptionVec_3;  s2_mmio_v4 <= io_lsq_uncache_bits_uop_exceptionVec_4;
    s2_mmio_v5  <= io_lsq_uncache_bits_uop_exceptionVec_5;  s2_mmio_v13 <= io_lsq_uncache_bits_uop_exceptionVec_13;
    s2_mmio_v19 <= io_lsq_uncache_bits_uop_exceptionVec_19; s2_mmio_v21 <= io_lsq_uncache_bits_uop_exceptionVec_21;
    s2_mmio_trigger <= io_lsq_uncache_bits_uop_trigger; s2_mmio_rfWen <= io_lsq_uncache_bits_uop_rfWen;
    s2_mmio_fpWen <= io_lsq_uncache_bits_uop_fpWen; s2_mmio_flushPipe <= io_lsq_uncache_bits_uop_flushPipe;
    s2_mmio_pdest <= io_lsq_uncache_bits_uop_pdest; s2_mmio_robIdx_flag <= io_lsq_uncache_bits_uop_robIdx_flag;
    s2_mmio_robIdx_value <= io_lsq_uncache_bits_uop_robIdx_value;
    s2_mmio_enqRsTime <= io_lsq_uncache_bits_uop_debugInfo_enqRsTime;
    s2_mmio_selectTime <= io_lsq_uncache_bits_uop_debugInfo_selectTime;
    s2_mmio_issueTime <= io_lsq_uncache_bits_uop_debugInfo_issueTime;
    s2_mmio_replayInst <= io_lsq_uncache_bits_uop_replayInst; s2_mmio_isMMIO <= io_lsq_uncache_bits_debug_isMMIO;
    s2_mmio_isNCIO <= 1'b0; s2_mmio_isPerfCnt <= 1'b0;
    s2_mmio_v3_1 <= s2_mmio_v3; s2_mmio_v4_1 <= s2_mmio_v4; s2_mmio_v5_1 <= s2_mmio_v5;
    s2_mmio_v13_1 <= s2_mmio_v13; s2_mmio_v19_1 <= s2_mmio_v19; s2_mmio_v21_1 <= s2_mmio_v21;
    s2_mmio_trigger_1 <= s2_mmio_trigger; s2_mmio_rfWen_1 <= s2_mmio_rfWen; s2_mmio_fpWen_1 <= s2_mmio_fpWen;
    s2_mmio_flushPipe_1 <= s2_mmio_flushPipe; s2_mmio_pdest_1 <= s2_mmio_pdest;
    s2_mmio_robIdx_flag_1 <= s2_mmio_robIdx_flag; s2_mmio_robIdx_value_1 <= s2_mmio_robIdx_value;
    s2_mmio_enqRsTime_1 <= s2_mmio_enqRsTime; s2_mmio_selectTime_1 <= s2_mmio_selectTime; s2_mmio_issueTime_1 <= s2_mmio_issueTime;
    s2_mmio_replayInst_1 <= s2_mmio_replayInst; s2_mmio_isMMIO_1 <= s2_mmio_isMMIO;
    s2_mmio_isNCIO_1 <= s2_mmio_isNCIO; s2_mmio_isPerfCnt_1 <= s2_mmio_isPerfCnt;
  end

  // ===========================================================================
  //  S2 -> S3 流水寄存器 + S3 数据扩展 / 写回 / 回灌 / rollback / feedback
  // ===========================================================================
  logic                  s3_valid_REG;          // golden s3_valid_last_REG
  logic                  s3_troublem_REG;
  logic                  s3_vecActive, s3_isvec;
  logic [2:0]            s3_vec_alignedType;
  logic [3:0]            s3_vec_mBIndex;
  logic [8:0]            s3_data_select;
  logic [MASK_BITS-1:0]  s3_data_select_by_offset;
  // s3_in 流水内容
  logic [23:0]           s3_in_excVec;
  logic [3:0]            s3_in_trigger;
  logic                  s3_in_preDecode_isRVC, s3_in_ftqPtr_flag; logic [5:0] s3_in_ftqPtr_value;
  logic [3:0]            s3_in_ftqOffset;
  logic [8:0]            s3_in_fuOpType;
  logic                  s3_in_rfWen, s3_in_fpWen;
  logic [7:0]            s3_in_vstart; logic [1:0] s3_in_veew; logic [6:0] s3_in_uopIdx;
  logic [7:0]            s3_in_pdest; logic s3_in_robIdx_flag; logic [7:0] s3_in_robIdx_value;
  logic [63:0]           s3_in_enqRsTime, s3_in_selectTime, s3_in_issueTime;
  logic                  s3_in_storeSetHit, s3_in_waitForRobIdx_flag; logic [7:0] s3_in_waitForRobIdx_value;
  logic                  s3_in_loadWaitBit, s3_in_loadWaitStrict;
  logic                  s3_in_lqIdx_flag; logic [6:0] s3_in_lqIdx_value;
  logic                  s3_in_sqIdx_flag; logic [5:0] s3_in_sqIdx_value;
  logic [VADDR_BITS-1:0] s3_in_vaddr; logic [63:0] s3_in_fullva; logic s3_in_vaNeedExt;
  logic [PADDR_BITS-1:0] s3_in_paddr; logic [63:0] s3_in_gpaddr; logic [MASK_BITS-1:0] s3_in_mask;
  logic [128:0]          s3_in_data;
  logic                  s3_in_tlbMiss, s3_in_nc, s3_in_mmio, s3_in_memBackTypeMM, s3_in_isHyper, s3_in_isForVSnonLeafPTE;
  logic                  s3_in_isvec, s3_in_is128bit; logic [7:0] s3_in_elemIdx;
  logic [2:0]            s3_in_alignedType; logic [3:0] s3_in_mbIndex, s3_in_reg_offset; logic [7:0] s3_in_elemIdxInsideVd;
  logic [MASK_BITS-1:0]  s3_in_vecTriggerMask;
  logic                  s3_in_vecActive, s3_in_isLoadReplay, s3_in_hasROBEntry, s3_in_handledByMSHR;
  logic [6:0]            s3_in_schedIndex;
  logic                  s3_in_frm_mabuf, s3_in_isFinalSplit, s3_in_misalignWith16Byte, s3_in_misalignNeedWakeUp;
  logic [3:0]            s3_in_rep_info_mshr_id;
  logic                  s3_in_rep_info_full_fwd;
  logic                  s3_in_rep_info_data_inv_sq_idx_flag; logic [5:0] s3_in_rep_info_data_inv_sq_idx_value;
  logic                  s3_in_rep_info_addr_inv_sq_idx_flag; logic [5:0] s3_in_rep_info_addr_inv_sq_idx_value;
  logic                  s3_in_rep_info_last_beat;
  logic                  s3_in_cause [CAUSE_NUM];
  logic [3:0]            s3_in_rep_info_tlb_id; logic s3_in_rep_info_tlb_full;
  logic                  s3_nc_with_data;
  logic [127:0]          s3_merged_data;
  logic                  s3_safe_wakeup, s3_safe_writeback, s3_exception, s3_mis_align_r, s3_misalign_can_go;
  logic                  s3_fast_rep_REG, s3_hw_err_REG, s3_vp_match_fail_REG, s3_ldld_rep_inst_REG;
  // mmio 影子（s3 级）
  logic s3_mmio_req_valid, s3_mmio_v3, s3_mmio_v4, s3_mmio_v5, s3_mmio_v13, s3_mmio_v19, s3_mmio_v21;
  logic [3:0] s3_mmio_trigger; logic s3_mmio_flushPipe, s3_mmio_robIdx_flag; logic [7:0] s3_mmio_robIdx_value;
  logic [63:0] s3_mmio_enqRsTime, s3_mmio_selectTime, s3_mmio_issueTime;
  logic s3_mmio_replayInst, s3_mmio_isMMIO, s3_mmio_isNCIO, s3_mmio_isPerfCnt;
  logic [7:0] s3_pdest; logic s3_rfWen, s3_fpWen;
  // mmio 数据影子链
  logic [63:0] s3_mmio_lqData_r0, s3_mmio_lqData_r1, s3_mmio_lqData;
  logic [8:0]  s3_mmio_fuOpType_r0, s3_mmio_fuOpType_r1, s3_mmio_fuOpType;
  logic        s3_mmio_fpWen_r0, s3_mmio_fpWen_r1, s3_mmio_dfpWen;
  logic [2:0]  s3_mmio_addrOff_r0, s3_mmio_addrOff_r1, s3_mmio_addrOff;
  // misalign wakeup 影子（3 拍）
  logic s3_mwk_v0, s3_mwk_v1, s3_mwk_v2;
  logic s3_mwk_v3_0, s3_mwk_v4_0, s3_mwk_v5_0, s3_mwk_v13_0, s3_mwk_v19_0, s3_mwk_v21_0;
  logic [3:0] s3_mwk_trig_0; logic s3_mwk_nc_0, s3_mwk_mmio_0, s3_mwk_mm_0, s3_mwk_vecAct_0, s3_mwk_needWk_0;
  logic s3_mwk_v3_1, s3_mwk_v4_1, s3_mwk_v5_1, s3_mwk_v13_1, s3_mwk_v19_1, s3_mwk_v21_1;
  logic [3:0] s3_mwk_trig_1; logic s3_mwk_nc_1, s3_mwk_mmio_1, s3_mwk_mm_1, s3_mwk_vecAct_1, s3_mwk_needWk_1;
  logic s3_mwk_v3_2, s3_mwk_v4_2, s3_mwk_v5_2, s3_mwk_v13_2, s3_mwk_v19_2, s3_mwk_v21_2;
  logic [3:0] s3_mwk_trig_2; logic s3_mwk_nc_2, s3_mwk_mmio_2, s3_mwk_mm_2, s3_mwk_vecAct_2, s3_mwk_needWk_2;
  logic s3_misalign_wakeup_T;
  assign s3_misalign_wakeup_T = io_misalign_ldin_ready & io_misalign_ldin_valid;

  // s3_ready：只看当拍 redirect + ldout_ready（与 golden s3_ready 一致）
  assign s3_ready = ~s3_valid_REG |
      rob_need_flush(io_redirect_valid, io_redirect_bits_level,
        s3_in_robIdx_flag, s3_in_robIdx_value, io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value) |
      io_ldout_ready;

  // S2->S3 寄存器加载
  logic [8:0] s2_data_select_oh;
  assign s2_data_select_oh = gen_rdata_oh(s2_in_fuOpType, s2_in_fpWen);
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s3_vecActive <= 1'b1; s3_isvec <= 1'b0; s3_data_select <= 9'h0; s3_data_select_by_offset <= 16'h0;
    end else if (s2_fire) begin
      s3_vecActive <= s2_in_vecActive; s3_isvec <= s2_in_isvec;
      s3_data_select <= s2_data_select_oh;
      s3_data_select_by_offset <= gen_data_select_by_offset(s2_in_paddr[3:0]);
    end
  end
  always_ff @(posedge clock) begin
    if (s2_fire) begin
      s3_in_excVec[0]  <= ~s2_supress & s2_in_excVec[0];
      s3_in_excVec[1]  <= ~s2_supress & s2_in_excVec[1];
      s3_in_excVec[2]  <= ~s2_supress & s2_in_excVec[2];
      s3_in_excVec[3]  <= s2_exc_vec3;
      s3_in_excVec[4]  <= s2_real_exc_vec4;
      s3_in_excVec[5]  <= s2_real_exc_vec5;
      s3_in_excVec[6]  <= ~s2_supress & s2_in_excVec[6];
      s3_in_excVec[7]  <= ~s2_supress & s2_in_excVec[7];
      s3_in_excVec[8]  <= ~s2_supress & s2_in_excVec[8];
      s3_in_excVec[9]  <= ~s2_supress & s2_in_excVec[9];
      s3_in_excVec[10] <= ~s2_supress & s2_in_excVec[10];
      s3_in_excVec[11] <= ~s2_supress & s2_in_excVec[11];
      s3_in_excVec[12] <= ~s2_supress & s2_in_excVec[12];
      s3_in_excVec[13] <= s2_exc_vec13;
      s3_in_excVec[14] <= ~s2_supress & s2_in_excVec[14];
      s3_in_excVec[15] <= ~s2_supress & s2_in_excVec[15];
      s3_in_excVec[16] <= ~s2_supress & s2_in_excVec[16];
      s3_in_excVec[17] <= ~s2_supress & s2_in_excVec[17];
      s3_in_excVec[18] <= ~s2_supress & s2_in_excVec[18];
      s3_in_excVec[19] <= s2_exc_vec19;
      s3_in_excVec[20] <= ~s2_supress & s2_in_excVec[20];
      s3_in_excVec[21] <= s2_exc_vec21;
      s3_in_excVec[22] <= ~s2_supress & s2_in_excVec[22];
      s3_in_excVec[23] <= ~s2_supress & s2_in_excVec[23];
      s3_in_trigger <= s2_in_trigger;
      s3_in_preDecode_isRVC <= s2_in_preDecode_isRVC;
      s3_in_ftqPtr_flag <= s2_in_ftqPtr_flag; s3_in_ftqPtr_value <= s2_in_ftqPtr_value; s3_in_ftqOffset <= s2_in_ftqOffset;
      s3_in_fuOpType <= s2_in_fuOpType; s3_in_rfWen <= s2_in_rfWen; s3_in_fpWen <= s2_in_fpWen;
      s3_in_vstart <= s2_out_vstart; s3_in_veew <= s2_in_veew; s3_in_uopIdx <= s2_in_uopIdx; s3_in_pdest <= s2_in_pdest;
      s3_in_robIdx_flag <= s2_in_robIdx_flag; s3_in_robIdx_value <= s2_in_robIdx_value;
      s3_in_enqRsTime <= s2_in_enqRsTime; s3_in_selectTime <= s2_in_selectTime; s3_in_issueTime <= s2_in_issueTime;
      s3_in_storeSetHit <= s2_in_storeSetHit;
      s3_in_waitForRobIdx_flag <= s2_in_waitForRobIdx_flag; s3_in_waitForRobIdx_value <= s2_in_waitForRobIdx_value;
      s3_in_loadWaitBit <= s2_in_loadWaitBit; s3_in_loadWaitStrict <= s2_in_loadWaitStrict;
      s3_in_lqIdx_flag <= s2_in_lqIdx_flag; s3_in_lqIdx_value <= s2_in_lqIdx_value;
      s3_in_sqIdx_flag <= s2_in_sqIdx_flag; s3_in_sqIdx_value <= s2_in_sqIdx_value;
      s3_in_vaddr <= s2_in_vaddr; s3_in_fullva <= s2_in_fullva; s3_in_vaNeedExt <= s2_in_vaNeedExt;
      s3_in_paddr <= s2_in_paddr; s3_in_gpaddr <= s2_in_gpaddr; s3_in_mask <= s2_in_mask; s3_in_data <= s2_in_data;
      s3_in_tlbMiss <= s2_in_tlbMiss; s3_in_nc <= s2_in_nc; s3_in_mmio <= s2_mmio; s3_in_memBackTypeMM <= ~io_pmp_mmio;
      s3_in_isHyper <= s2_in_isHyper; s3_in_isForVSnonLeafPTE <= s2_in_isForVSnonLeafPTE;
      s3_in_isvec <= s2_in_isvec; s3_in_is128bit <= s2_in_is128bit; s3_in_elemIdx <= s2_in_elemIdx;
      s3_in_alignedType <= s2_in_alignedType; s3_in_mbIndex <= s2_in_mbIndex; s3_in_reg_offset <= s2_in_reg_offset;
      s3_in_elemIdxInsideVd <= s2_in_elemIdxInsideVd; s3_in_vecTriggerMask <= s2_in_vecTriggerMask;
      s3_in_vecActive <= s2_in_vecActive; s3_in_isLoadReplay <= s2_in_isLoadReplay; s3_in_hasROBEntry <= s2_in_hasROBEntry;
      s3_in_handledByMSHR <= io_dcache_resp_bits_handled; s3_in_schedIndex <= s2_in_schedIndex;
      s3_in_frm_mabuf <= s2_in_frm_mabuf; s3_in_isFinalSplit <= s2_in_isFinalSplit;
      s3_in_misalignWith16Byte <= s2_in_misalignWith16Byte; s3_in_misalignNeedWakeUp <= s2_in_misalignNeedWakeUp;
      s3_in_rep_info_mshr_id <= io_dcache_resp_bits_mshr_id; s3_in_rep_info_full_fwd <= s2_dcache_miss & s2_full_fwd;
      s3_in_rep_info_data_inv_sq_idx_flag <= io_lsq_forward_dataInvalidSqIdx_flag;
      s3_in_rep_info_data_inv_sq_idx_value <= io_lsq_forward_dataInvalidSqIdx_value;
      s3_in_rep_info_addr_inv_sq_idx_flag <= io_lsq_forward_addrInvalidSqIdx_flag;
      s3_in_rep_info_addr_inv_sq_idx_value <= io_lsq_forward_addrInvalidSqIdx_value;
      s3_in_rep_info_last_beat <= s2_in_paddr[5];
      s3_in_cause[C_MA] <= s2_cause[C_MA]; s3_in_cause[C_TM] <= s2_cause[C_TM]; s3_in_cause[C_FF] <= s2_cause[C_FF];
      s3_in_cause[C_DR] <= s2_cause[C_DR]; s3_in_cause[C_DM] <= s2_cause[C_DM]; s3_in_cause[C_BC] <= s2_cause[C_BC];
      s3_in_cause[C_RAR] <= s2_cause[C_RAR]; s3_in_cause[C_RAW] <= s2_cause[C_RAW]; s3_in_cause[C_NK] <= s2_cause[C_NK];
      s3_in_cause[C_WF] <= 1'b0; s3_in_cause[C_MF] <= 1'b0;
      s3_in_rep_info_tlb_id <= io_tlb_hint_id; s3_in_rep_info_tlb_full <= io_tlb_hint_full;
      s3_vec_alignedType <= s2_in_alignedType; s3_vec_mBIndex <= s2_in_mbIndex;
      s3_safe_wakeup <= s2_safe_wakeup;
      s3_safe_writeback <= s2_real_exception | s2_safe_wakeup | (s2_fwd_vp_match_invalid & s2_troublem);
      s3_exception <= s2_real_exception; s3_mis_align_r <= s2_mis_align;
      s3_misalign_can_go <= (s2_in_lqIdx_flag ^ io_lsq_lqDeqPtr_flag ^ (s2_in_lqIdx_value <= io_lsq_lqDeqPtr_value)) | io_misalign_allow_spec;
      s3_merged_data <= s2_merged_data;
    end
    // 非 s2_fire 门控的 S3 寄存器
    s3_nc_with_data <= s2_nc_with_data;
    s3_pdest <= s2_valid ? s2_in_pdest : s2_mmio_pdest_1;
    if (s2_valid | s2_mmio_req_valid_d2) begin
      s3_rfWen <= s2_valid ? s2_in_rfWen : s2_mmio_rfWen_1;
      s3_fpWen <= s2_valid ? s2_in_fpWen : s2_mmio_fpWen_1;
    end
    s3_fast_rep_REG <= ~s2_in_isFastReplay & ~s2_mem_amb & ~s2_in_tlbMiss & ~s2_fwd_fail &
        (s2_dcache_fast_rep | (~s2_mq_nack & ~s2_dcache_miss & ~s2_bank_conflict & s2_nuke)) & s2_troublem;
    // mmio writeback 影子 s3 级
    s3_mmio_req_valid <= s2_mmio_req_valid_d2;
    s3_mmio_v3 <= s2_mmio_v3_1; s3_mmio_v4 <= s2_mmio_v4_1; s3_mmio_v5 <= s2_mmio_v5_1;
    s3_mmio_v13 <= s2_mmio_v13_1; s3_mmio_v19 <= s2_mmio_v19_1; s3_mmio_v21 <= s2_mmio_v21_1;
    s3_mmio_trigger <= s2_mmio_trigger_1; s3_mmio_flushPipe <= s2_mmio_flushPipe_1;
    s3_mmio_robIdx_flag <= s2_mmio_robIdx_flag_1; s3_mmio_robIdx_value <= s2_mmio_robIdx_value_1;
    s3_mmio_enqRsTime <= s2_mmio_enqRsTime_1; s3_mmio_selectTime <= s2_mmio_selectTime_1; s3_mmio_issueTime <= s2_mmio_issueTime_1;
    s3_mmio_replayInst <= s2_mmio_replayInst_1; s3_mmio_isMMIO <= s2_mmio_isMMIO_1;
    s3_mmio_isNCIO <= s2_mmio_isNCIO_1; s3_mmio_isPerfCnt <= s2_mmio_isPerfCnt_1;
    // mmio raw 数据三拍影子
    s3_mmio_lqData_r0 <= io_lsq_ld_raw_data_lqData; s3_mmio_fuOpType_r0 <= io_lsq_ld_raw_data_uop_fuOpType;
    s3_mmio_fpWen_r0 <= io_lsq_ld_raw_data_uop_fpWen; s3_mmio_addrOff_r0 <= io_lsq_ld_raw_data_addrOffset;
    s3_mmio_lqData_r1 <= s3_mmio_lqData_r0; s3_mmio_fuOpType_r1 <= s3_mmio_fuOpType_r0;
    s3_mmio_fpWen_r1 <= s3_mmio_fpWen_r0; s3_mmio_addrOff_r1 <= s3_mmio_addrOff_r0;
    s3_mmio_lqData <= s3_mmio_lqData_r1; s3_mmio_fuOpType <= s3_mmio_fuOpType_r1;
    s3_mmio_dfpWen <= s3_mmio_fpWen_r1; s3_mmio_addrOff <= s3_mmio_addrOff_r1;
    // misalign wakeup 影子
    s3_mwk_v3_0 <= io_misalign_ldin_bits_uop_exceptionVec_3; s3_mwk_v4_0 <= io_misalign_ldin_bits_uop_exceptionVec_4;
    s3_mwk_v5_0 <= io_misalign_ldin_bits_uop_exceptionVec_5; s3_mwk_v13_0 <= io_misalign_ldin_bits_uop_exceptionVec_13;
    s3_mwk_v19_0 <= io_misalign_ldin_bits_uop_exceptionVec_19; s3_mwk_v21_0 <= io_misalign_ldin_bits_uop_exceptionVec_21;
    s3_mwk_trig_0 <= io_misalign_ldin_bits_uop_trigger; s3_mwk_nc_0 <= io_misalign_ldin_bits_nc;
    s3_mwk_mmio_0 <= io_misalign_ldin_bits_mmio; s3_mwk_mm_0 <= io_misalign_ldin_bits_memBackTypeMM;
    s3_mwk_vecAct_0 <= io_misalign_ldin_bits_vecActive; s3_mwk_needWk_0 <= io_misalign_ldin_bits_misalignNeedWakeUp;
    s3_mwk_v3_1 <= s3_mwk_v3_0; s3_mwk_v4_1 <= s3_mwk_v4_0; s3_mwk_v5_1 <= s3_mwk_v5_0;
    s3_mwk_v13_1 <= s3_mwk_v13_0; s3_mwk_v19_1 <= s3_mwk_v19_0; s3_mwk_v21_1 <= s3_mwk_v21_0;
    s3_mwk_trig_1 <= s3_mwk_trig_0; s3_mwk_nc_1 <= s3_mwk_nc_0; s3_mwk_mmio_1 <= s3_mwk_mmio_0;
    s3_mwk_mm_1 <= s3_mwk_mm_0; s3_mwk_vecAct_1 <= s3_mwk_vecAct_0; s3_mwk_needWk_1 <= s3_mwk_needWk_0;
    s3_mwk_v3_2 <= s3_mwk_v3_1; s3_mwk_v4_2 <= s3_mwk_v4_1; s3_mwk_v5_2 <= s3_mwk_v5_1;
    s3_mwk_v13_2 <= s3_mwk_v13_1; s3_mwk_v19_2 <= s3_mwk_v19_1; s3_mwk_v21_2 <= s3_mwk_v21_1;
    s3_mwk_trig_2 <= s3_mwk_trig_1; s3_mwk_nc_2 <= s3_mwk_nc_1; s3_mwk_mmio_2 <= s3_mwk_mmio_1;
    s3_mwk_mm_2 <= s3_mwk_mm_1; s3_mwk_vecAct_2 <= s3_mwk_vecAct_1; s3_mwk_needWk_2 <= s3_mwk_needWk_1;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      s3_valid_REG <= 1'b0; s3_troublem_REG <= 1'b0; s3_hw_err_REG <= 1'b0;
      s3_vp_match_fail_REG <= 1'b0; s3_ldld_rep_inst_REG <= 1'b0;
      s3_mwk_v0 <= 1'b0; s3_mwk_v1 <= 1'b0; s3_mwk_v2 <= 1'b0;
    end else begin
      s3_valid_REG <= s2_valid & ~s2_in_isHWPrefetch &
          ~rob_need_flush(io_redirect_valid, io_redirect_bits_level,
             s2_in_robIdx_flag, s2_in_robIdx_value, io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value);
      s3_troublem_REG <= s2_troublem;
      s3_hw_err_REG <= io_csrCtrl_cache_error_enable;
      s3_vp_match_fail_REG <= s2_fwd_vp_match_invalid;
      s3_ldld_rep_inst_REG <= io_csrCtrl_ldld_vio_check_enable;
      s3_mwk_v0 <= io_misalign_ldin_bits_misalignNeedWakeUp & s3_misalign_wakeup_T;
      s3_mwk_v1 <= s3_mwk_v0; s3_mwk_v2 <= s3_mwk_v1;
    end
  end
  // s3_ldout_valid_REG（~isvec & ~frm_mabuf 打一拍）
  logic s3_ldout_valid_REG;
  always_ff @(posedge clock) s3_ldout_valid_REG <= ~s2_in_isvec & ~s2_in_frm_mabuf;

  // ---- S3 组合：hw_err / mis_align / exception 合并 / replay cause 选择 ------
  logic s3_hw_err, s3_mis_align;
  assign s3_hw_err = io_dcache_resp_bits_error_delayed & s3_hw_err_REG & s3_troublem_REG;
  assign s3_mis_align = s3_mis_align_r & ~s3_exception;
  logic s3_vp_match_fail, s3_ldld_rep_inst;
  assign s3_vp_match_fail = s3_vp_match_fail_REG & s3_troublem_REG;
  assign s3_ldld_rep_inst = io_lsq_ldld_nuke_query_resp_valid & io_lsq_ldld_nuke_query_resp_bits_rep_frm_fetch & s3_ldld_rep_inst_REG;

  // misalign buffer 入队条件
  logic io_lsq_ldin_valid_0, toMisalignBufferValid, s3_fast_rep_canceled;
  assign s3_fast_rep_canceled = s0_src_select[SRC_SUPER_REP] | io_misalign_ldin_valid | ~io_dcache_req_ready;
  assign io_lsq_ldin_valid_0 = s3_valid_REG & (~s3_fast_rep_REG | s3_fast_rep_canceled);
  assign toMisalignBufferValid = io_lsq_ldin_valid_0 & s3_mis_align & ~s3_in_frm_mabuf;

  // 11 位 replay cause 优先编码（lrq 选择：含 misalign 入队失败位 C_MF）
  logic [CAUSE_NUM-1:0] s3_lrq_sel, s3_mab_sel;
  always_comb begin
    s3_lrq_sel = '0;
    if      (s3_in_cause[C_MA])  s3_lrq_sel = 11'h1;
    else if (s3_in_cause[C_TM])  s3_lrq_sel = 11'h2;
    else if (s3_in_cause[C_FF])  s3_lrq_sel = 11'h4;
    else if (s3_in_cause[C_DR])  s3_lrq_sel = 11'h8;
    else if (s3_in_cause[C_DM])  s3_lrq_sel = 11'h10;
    else if (s3_in_cause[C_BC])  s3_lrq_sel = 11'h40;
    else if (s3_in_cause[C_RAR]) s3_lrq_sel = 11'h80;
    else if (s3_in_cause[C_RAW]) s3_lrq_sel = 11'h100;
    else if (s3_in_cause[C_NK])  s3_lrq_sel = 11'h200;
    else                         s3_lrq_sel = {(toMisalignBufferValid & ~(io_misalign_enq_req_ready & s3_misalign_can_go)), 10'h0};
  end
  always_comb begin
    s3_mab_sel = '0;
    if      (s3_in_cause[C_MA])  s3_mab_sel = 11'h1;
    else if (s3_in_cause[C_TM])  s3_mab_sel = 11'h2;
    else if (s3_in_cause[C_FF])  s3_mab_sel = 11'h4;
    else if (s3_in_cause[C_DR])  s3_mab_sel = 11'h8;
    else if (s3_in_cause[C_DM])  s3_mab_sel = 11'h10;
    else if (s3_in_cause[C_BC])  s3_mab_sel = 11'h40;
    else if (s3_in_cause[C_RAR]) s3_mab_sel = 11'h80;
    else if (s3_in_cause[C_RAW]) s3_mab_sel = 11'h100;
    else                         s3_mab_sel = {1'b0, s3_in_cause[C_NK], 9'h0};
  end
  // misalign ldout 的 cause（用 mab 选择，且 misalign-wakeup 拍清零）
  logic [CAUSE_NUM-1:0] s3_mab_cause;
  generate
    for (gi = 0; gi < CAUSE_NUM; gi++) begin : g_mab_cause
      assign s3_mab_cause[gi] = ~s3_mwk_v2 & s3_mab_sel[gi];
    end
  endgenerate
  // lrq replay cause（被异常/hw_err/vp_match/frm_mabuf 抑制）
  logic s3_lrq_supress;
  assign s3_lrq_supress = s3_exception | s3_hw_err | s3_vp_match_fail | s3_in_frm_mabuf;
  logic [CAUSE_NUM-1:0] s3_replay_cause;
  generate
    for (gi = 0; gi < CAUSE_NUM; gi++) begin : g_replay_cause
      assign s3_replay_cause[gi] = ~s3_lrq_supress & s3_lrq_sel[gi];
    end
  endgenerate

  // s3 frm_mis_flush（misalign 来源的回灌 flush）/ rollback / revoke
  logic s3_frm_mis_flush;
  assign s3_frm_mis_flush = s3_in_frm_mabuf &
      (s3_mab_cause[C_FF] | s3_mab_cause[C_MA] | s3_mab_cause[C_NK] | s3_mab_cause[C_RAR] | s3_mab_cause[C_RAW]);
  logic io_rollback_valid_0;
  assign io_rollback_valid_0 = s3_valid_REG & (s3_vp_match_fail | s3_ldld_rep_inst | s3_frm_mis_flush) & ~s3_exception;
  logic s3_revoke;
  assign s3_revoke = s3_exception | (|s3_replay_cause) | s3_mis_align |
      (s3_in_frm_mabuf & (|s3_mab_cause));

  // s3 写回 valid / vec exc 合并
  logic s3_out_valid;
  assign s3_out_valid = s3_valid_REG & (s3_safe_writeback | s3_hw_err) & ~toMisalignBufferValid;
  logic new_vec_5, new_vec_19;
  assign new_vec_5  = s3_in_excVec[5] & s3_vecActive;
  assign new_vec_19 = (s3_in_excVec[19] | s3_hw_err) & s3_vecActive;

  // ---- S3 数据：按 16-way offset 选 64 位窗口，再按 9 路独热扩展 -------------
  logic [63:0] s3_picked_pipe;
  always_comb begin
    s3_picked_pipe = 64'h0;
    // golden 是 Mux1H(并行 OR)非优先链：多热时各窗口按位 OR(bug-for-bug 对齐)
    for (int o = 0; o < MASK_BITS; o++)
      if (s3_data_select_by_offset[o]) s3_picked_pipe |= pick_data_window(s3_merged_data, 4'(o));
  end
  logic [63:0] s3_data_frm_pipe;
  assign s3_data_frm_pipe = new_rdata(s3_data_select, s3_picked_pipe);

  // mmio 数据扩展
  logic [63:0] s3_picked_mmio, s3_data_frm_mmio;
  assign s3_picked_mmio   = pick_mmio_window(s3_mmio_lqData, s3_mmio_addrOff);
  assign s3_data_frm_mmio = mmio_rdata(s3_mmio_fuOpType, s3_mmio_dfpWen, s3_picked_mmio);

  // ===========================================================================
  //  S2/S3 输出接线
  // ===========================================================================
  // ---- DCache s2 kill ----
  assign io_dcache_s2_kill = io_pmp_ld | io_pmp_st | s2_actually_uncache | s2_kill;

  // ---- 标量写回 io_ldout ----
  assign io_ldout_valid = s3_mmio_req_valid | (s3_out_valid & s3_ldout_valid_REG);
  assign io_ldout_bits_uop_exceptionVec_3  = s3_valid_REG ? s3_in_excVec[3]  : s3_mmio_v3;
  assign io_ldout_bits_uop_exceptionVec_4  = s3_valid_REG ? s3_in_excVec[4]  : s3_mmio_v4;
  assign io_ldout_bits_uop_exceptionVec_5  = s3_valid_REG ? new_vec_5        : s3_mmio_v5;
  assign io_ldout_bits_uop_exceptionVec_13 = s3_valid_REG ? s3_in_excVec[13] : s3_mmio_v13;
  assign io_ldout_bits_uop_exceptionVec_19 = s3_valid_REG ? new_vec_19       : s3_mmio_v19;
  assign io_ldout_bits_uop_exceptionVec_21 = s3_valid_REG ? s3_in_excVec[21] : s3_mmio_v21;
  assign io_ldout_bits_uop_trigger    = s3_valid_REG ? s3_in_trigger : s3_mmio_trigger;
  assign io_ldout_bits_uop_rfWen      = s3_rfWen;
  assign io_ldout_bits_uop_fpWen      = s3_fpWen;
  assign io_ldout_bits_uop_flushPipe  = ~s3_valid_REG & s3_mmio_flushPipe;
  assign io_ldout_bits_uop_pdest      = s3_pdest;
  assign io_ldout_bits_uop_robIdx_flag  = s3_valid_REG ? s3_in_robIdx_flag  : s3_mmio_robIdx_flag;
  assign io_ldout_bits_uop_robIdx_value = s3_valid_REG ? s3_in_robIdx_value : s3_mmio_robIdx_value;
  assign io_ldout_bits_uop_debugInfo_enqRsTime  = s3_valid_REG ? s3_in_enqRsTime  : s3_mmio_enqRsTime;
  assign io_ldout_bits_uop_debugInfo_selectTime = s3_valid_REG ? s3_in_selectTime : s3_mmio_selectTime;
  assign io_ldout_bits_uop_debugInfo_issueTime  = s3_valid_REG ? s3_in_issueTime  : s3_mmio_issueTime;
  assign io_ldout_bits_uop_replayInst = ~s3_valid_REG & s3_mmio_replayInst;
  assign io_ldout_bits_data           = s3_valid_REG ? s3_data_frm_pipe : s3_data_frm_mmio;
  assign io_ldout_bits_debug_isMMIO   = s3_valid_REG ? s3_in_mmio : s3_mmio_isMMIO;
  assign io_ldout_bits_debug_isNCIO   = s3_valid_REG ? (s3_in_nc & ~s3_in_memBackTypeMM) : s3_mmio_isNCIO;
  assign io_ldout_bits_debug_isPerfCnt= ~s3_valid_REG & s3_mmio_isPerfCnt;

  // ---- 向量写回 io_vecldout ----
  assign io_vecldout_valid = s3_out_valid &
      ~rob_need_flush(io_redirect_valid, io_redirect_bits_level,
         s3_in_robIdx_flag, s3_in_robIdx_value, io_redirect_bits_robIdx_flag, io_redirect_bits_robIdx_value) &
      s3_isvec & ~s3_mis_align & ~s3_in_frm_mabuf;
  assign io_vecldout_bits_mBIndex = s3_vec_mBIndex;
  assign io_vecldout_bits_trigger = s3_in_trigger;
  assign io_vecldout_bits_exceptionVec_3  = s3_in_excVec[3];
  assign io_vecldout_bits_exceptionVec_4  = s3_in_excVec[4];
  assign io_vecldout_bits_exceptionVec_5  = new_vec_5;
  assign io_vecldout_bits_exceptionVec_13 = s3_in_excVec[13];
  assign io_vecldout_bits_exceptionVec_19 = new_vec_19;
  assign io_vecldout_bits_exceptionVec_21 = s3_in_excVec[21];
  assign io_vecldout_bits_hasException = s3_exception;
  assign io_vecldout_bits_vaddr = s3_in_fullva;
  assign io_vecldout_bits_vaNeedExt = s3_in_vaNeedExt;
  assign io_vecldout_bits_gpaddr = s3_in_gpaddr;
  assign io_vecldout_bits_vstart = s3_in_vstart;
  assign io_vecldout_bits_vecTriggerMask = s3_in_vecTriggerMask;
  assign io_vecldout_bits_elemIdx = s3_in_elemIdx;
  assign io_vecldout_bits_mask = s3_in_mask;
  assign io_vecldout_bits_alignedType = s3_vec_alignedType;
  assign io_vecldout_bits_reg_offset = s3_in_reg_offset;
  assign io_vecldout_bits_elemIdxInsideVd = s3_in_elemIdxInsideVd;
  // vecdata：misalignWith16Byte 取 64 位窗口；128bit 直接 merged；否则按 alignedType 零扩展
  logic [63:0] s3_picked_pipe_vec;  // 与 s3_picked_pipe 同算（golden s3_picked_data_frm_pipe_1）
  assign s3_picked_pipe_vec = s3_picked_pipe;
  assign io_vecldout_bits_vecdata =
      s3_in_misalignWith16Byte ? {64'h0, s3_picked_pipe_vec} :
      s3_in_is128bit           ? s3_merged_data :
                                 rdata_vec(s3_vec_alignedType[1:0], s3_picked_pipe_vec);

  // ---- misalign 写回 io_misalign_ldout ----
  assign io_misalign_ldout_valid =
      (s3_valid_REG & (~s3_fast_rep_REG | s3_fast_rep_canceled) & s3_in_frm_mabuf) | s3_mwk_v2;
  assign io_misalign_ldout_bits_uop_exceptionVec_3  = s3_mwk_v2 ? s3_mwk_v3_2  : s3_in_excVec[3];
  assign io_misalign_ldout_bits_uop_exceptionVec_4  = s3_mwk_v2 ? s3_mwk_v4_2  : s3_in_excVec[4];
  assign io_misalign_ldout_bits_uop_exceptionVec_5  = s3_mwk_v2 ? s3_mwk_v5_2  : new_vec_5;
  assign io_misalign_ldout_bits_uop_exceptionVec_13 = s3_mwk_v2 ? s3_mwk_v13_2 : s3_in_excVec[13];
  assign io_misalign_ldout_bits_uop_exceptionVec_19 = s3_mwk_v2 ? s3_mwk_v19_2 : new_vec_19;
  assign io_misalign_ldout_bits_uop_exceptionVec_21 = s3_mwk_v2 ? s3_mwk_v21_2 : s3_in_excVec[21];
  assign io_misalign_ldout_bits_uop_trigger = s3_mwk_v2 ? s3_mwk_trig_2 : s3_in_trigger;
  // misalign 数据：按 offset 选窗口（不扩展，低 64 位有效，与 golden 一致）
  assign io_misalign_ldout_bits_data = {65'h0, s3_picked_pipe};
  assign io_misalign_ldout_bits_nc            = s3_mwk_v2 ? s3_mwk_nc_2     : s3_in_nc;
  assign io_misalign_ldout_bits_mmio          = s3_mwk_v2 ? s3_mwk_mmio_2   : s3_in_mmio;
  assign io_misalign_ldout_bits_memBackTypeMM = s3_mwk_v2 ? s3_mwk_mm_2     : s3_in_memBackTypeMM;
  assign io_misalign_ldout_bits_vecActive     = s3_mwk_v2 ? s3_mwk_vecAct_2 : s3_in_vecActive;
  assign io_misalign_ldout_bits_misalignNeedWakeUp = s3_mwk_v2 ? s3_mwk_needWk_2 : s3_in_misalignNeedWakeUp;
  assign io_misalign_ldout_bits_rep_info_cause_0  = s3_mab_cause[0];
  assign io_misalign_ldout_bits_rep_info_cause_1  = s3_mab_cause[1];
  assign io_misalign_ldout_bits_rep_info_cause_2  = s3_mab_cause[2];
  assign io_misalign_ldout_bits_rep_info_cause_3  = s3_mab_cause[3];
  assign io_misalign_ldout_bits_rep_info_cause_4  = s3_mab_cause[4];
  assign io_misalign_ldout_bits_rep_info_cause_5  = s3_mab_cause[5];
  assign io_misalign_ldout_bits_rep_info_cause_6  = s3_mab_cause[6];
  assign io_misalign_ldout_bits_rep_info_cause_7  = s3_mab_cause[7];
  assign io_misalign_ldout_bits_rep_info_cause_8  = s3_mab_cause[8];
  assign io_misalign_ldout_bits_rep_info_cause_9  = s3_mab_cause[9];
  assign io_misalign_ldout_bits_rep_info_cause_10 = s3_mab_cause[10];

  // ---- 回灌 LoadQueue io_lsq_ldin ----
  assign io_lsq_ldin_valid = io_lsq_ldin_valid_0;
  assign io_lsq_ldin_bits_uop_exceptionVec_0  = s3_in_excVec[0];
  assign io_lsq_ldin_bits_uop_exceptionVec_1  = s3_in_excVec[1];
  assign io_lsq_ldin_bits_uop_exceptionVec_2  = s3_in_excVec[2];
  assign io_lsq_ldin_bits_uop_exceptionVec_3  = s3_in_excVec[3];
  assign io_lsq_ldin_bits_uop_exceptionVec_4  = s3_in_excVec[4];
  assign io_lsq_ldin_bits_uop_exceptionVec_5  = new_vec_5;
  assign io_lsq_ldin_bits_uop_exceptionVec_6  = s3_in_excVec[6];
  assign io_lsq_ldin_bits_uop_exceptionVec_7  = s3_in_excVec[7];
  assign io_lsq_ldin_bits_uop_exceptionVec_8  = s3_in_excVec[8];
  assign io_lsq_ldin_bits_uop_exceptionVec_9  = s3_in_excVec[9];
  assign io_lsq_ldin_bits_uop_exceptionVec_10 = s3_in_excVec[10];
  assign io_lsq_ldin_bits_uop_exceptionVec_11 = s3_in_excVec[11];
  assign io_lsq_ldin_bits_uop_exceptionVec_12 = s3_in_excVec[12];
  assign io_lsq_ldin_bits_uop_exceptionVec_13 = s3_in_excVec[13];
  assign io_lsq_ldin_bits_uop_exceptionVec_14 = s3_in_excVec[14];
  assign io_lsq_ldin_bits_uop_exceptionVec_15 = s3_in_excVec[15];
  assign io_lsq_ldin_bits_uop_exceptionVec_16 = s3_in_excVec[16];
  assign io_lsq_ldin_bits_uop_exceptionVec_17 = s3_in_excVec[17];
  assign io_lsq_ldin_bits_uop_exceptionVec_18 = s3_in_excVec[18];
  assign io_lsq_ldin_bits_uop_exceptionVec_19 = new_vec_19;
  assign io_lsq_ldin_bits_uop_exceptionVec_20 = s3_in_excVec[20];
  assign io_lsq_ldin_bits_uop_exceptionVec_21 = s3_in_excVec[21];
  assign io_lsq_ldin_bits_uop_exceptionVec_22 = s3_in_excVec[22];
  assign io_lsq_ldin_bits_uop_exceptionVec_23 = s3_in_excVec[23];
  assign io_lsq_ldin_bits_uop_trigger = s3_in_trigger;
  assign io_lsq_ldin_bits_uop_preDecodeInfo_isRVC = s3_in_preDecode_isRVC;
  assign io_lsq_ldin_bits_uop_ftqPtr_flag = s3_in_ftqPtr_flag;
  assign io_lsq_ldin_bits_uop_ftqPtr_value = s3_in_ftqPtr_value;
  assign io_lsq_ldin_bits_uop_ftqOffset = s3_in_ftqOffset;
  assign io_lsq_ldin_bits_uop_fuOpType = s3_in_fuOpType;
  assign io_lsq_ldin_bits_uop_rfWen = s3_in_rfWen;
  assign io_lsq_ldin_bits_uop_fpWen = s3_in_fpWen;
  assign io_lsq_ldin_bits_uop_vpu_vstart = s3_in_vstart;
  assign io_lsq_ldin_bits_uop_vpu_veew = s3_in_veew;
  assign io_lsq_ldin_bits_uop_uopIdx = s3_in_uopIdx;
  assign io_lsq_ldin_bits_uop_pdest = s3_in_pdest;
  assign io_lsq_ldin_bits_uop_robIdx_flag = s3_in_robIdx_flag;
  assign io_lsq_ldin_bits_uop_robIdx_value = s3_in_robIdx_value;
  assign io_lsq_ldin_bits_uop_debugInfo_enqRsTime = s3_in_enqRsTime;
  assign io_lsq_ldin_bits_uop_debugInfo_selectTime = s3_in_selectTime;
  assign io_lsq_ldin_bits_uop_debugInfo_issueTime = s3_in_issueTime;
  assign io_lsq_ldin_bits_uop_storeSetHit = s3_in_storeSetHit;
  assign io_lsq_ldin_bits_uop_waitForRobIdx_flag = s3_in_waitForRobIdx_flag;
  assign io_lsq_ldin_bits_uop_waitForRobIdx_value = s3_in_waitForRobIdx_value;
  assign io_lsq_ldin_bits_uop_loadWaitBit = s3_in_loadWaitBit;
  assign io_lsq_ldin_bits_uop_loadWaitStrict = s3_in_loadWaitStrict;
  assign io_lsq_ldin_bits_uop_lqIdx_flag = s3_in_lqIdx_flag;
  assign io_lsq_ldin_bits_uop_lqIdx_value = s3_in_lqIdx_value;
  assign io_lsq_ldin_bits_uop_sqIdx_flag = s3_in_sqIdx_flag;
  assign io_lsq_ldin_bits_uop_sqIdx_value = s3_in_sqIdx_value;
  assign io_lsq_ldin_bits_vaddr = s3_in_vaddr;
  assign io_lsq_ldin_bits_fullva = s3_in_fullva;
  assign io_lsq_ldin_bits_vaNeedExt = s3_in_vaNeedExt;
  assign io_lsq_ldin_bits_paddr = s3_in_paddr;
  assign io_lsq_ldin_bits_gpaddr = s3_in_gpaddr;
  assign io_lsq_ldin_bits_mask = s3_in_mask;
  assign io_lsq_ldin_bits_tlbMiss = s3_in_tlbMiss;
  assign io_lsq_ldin_bits_nc = s3_in_nc;
  assign io_lsq_ldin_bits_mmio = s3_in_mmio;
  assign io_lsq_ldin_bits_memBackTypeMM = s3_in_memBackTypeMM;
  assign io_lsq_ldin_bits_isHyper = s3_in_isHyper;
  assign io_lsq_ldin_bits_isForVSnonLeafPTE = s3_in_isForVSnonLeafPTE;
  assign io_lsq_ldin_bits_isvec = s3_in_isvec;
  assign io_lsq_ldin_bits_is128bit = s3_in_is128bit;
  assign io_lsq_ldin_bits_elemIdx = s3_in_elemIdx;
  assign io_lsq_ldin_bits_alignedType = s3_in_alignedType;
  assign io_lsq_ldin_bits_mbIndex = s3_in_mbIndex;
  assign io_lsq_ldin_bits_reg_offset = s3_in_reg_offset;
  assign io_lsq_ldin_bits_elemIdxInsideVd = s3_in_elemIdxInsideVd;
  assign io_lsq_ldin_bits_vecActive = s3_in_vecActive;
  assign io_lsq_ldin_bits_isLoadReplay = s3_in_isLoadReplay;
  assign io_lsq_ldin_bits_handledByMSHR = s3_in_handledByMSHR;
  assign io_lsq_ldin_bits_schedIndex = s3_in_schedIndex;
  assign io_lsq_ldin_bits_isFrmMisAlignBuf = s3_in_frm_mabuf;
  assign io_lsq_ldin_bits_updateAddrValid =
      (~s3_mis_align & (~s3_in_frm_mabuf | s3_in_isFinalSplit)) | s3_exception;
  assign io_lsq_ldin_bits_rep_info_mshr_id = s3_in_rep_info_mshr_id;
  assign io_lsq_ldin_bits_rep_info_full_fwd = s3_in_rep_info_full_fwd;
  assign io_lsq_ldin_bits_rep_info_data_inv_sq_idx_flag = s3_in_rep_info_data_inv_sq_idx_flag;
  assign io_lsq_ldin_bits_rep_info_data_inv_sq_idx_value = s3_in_rep_info_data_inv_sq_idx_value;
  assign io_lsq_ldin_bits_rep_info_addr_inv_sq_idx_flag = s3_in_rep_info_addr_inv_sq_idx_flag;
  assign io_lsq_ldin_bits_rep_info_addr_inv_sq_idx_value = s3_in_rep_info_addr_inv_sq_idx_value;
  assign io_lsq_ldin_bits_rep_info_last_beat = s3_in_rep_info_last_beat;
  assign io_lsq_ldin_bits_rep_info_cause_0  = s3_replay_cause[0];
  assign io_lsq_ldin_bits_rep_info_cause_1  = s3_replay_cause[1];
  assign io_lsq_ldin_bits_rep_info_cause_2  = s3_replay_cause[2];
  assign io_lsq_ldin_bits_rep_info_cause_3  = s3_replay_cause[3];
  assign io_lsq_ldin_bits_rep_info_cause_4  = s3_replay_cause[4];
  assign io_lsq_ldin_bits_rep_info_cause_5  = s3_replay_cause[5];
  assign io_lsq_ldin_bits_rep_info_cause_6  = s3_replay_cause[6];
  assign io_lsq_ldin_bits_rep_info_cause_7  = s3_replay_cause[7];
  assign io_lsq_ldin_bits_rep_info_cause_8  = s3_replay_cause[8];
  assign io_lsq_ldin_bits_rep_info_cause_9  = s3_replay_cause[9];
  assign io_lsq_ldin_bits_rep_info_cause_10 = s3_replay_cause[10];
  assign io_lsq_ldin_bits_rep_info_tlb_id = s3_in_rep_info_tlb_id;
  assign io_lsq_ldin_bits_rep_info_tlb_full = s3_in_rep_info_tlb_full;
  assign io_lsq_ldin_bits_nc_with_data = s3_nc_with_data;

  assign io_lsq_forward_sqIdxMask = s1_sqIdx_mask;

  // ---- nuke 查询请求（S2 产生）----
  assign io_lsq_stld_nuke_query_req_bits_uop_preDecodeInfo_isRVC = s2_in_preDecode_isRVC;
  assign io_lsq_stld_nuke_query_req_bits_uop_ftqPtr_flag = s2_in_ftqPtr_flag;
  assign io_lsq_stld_nuke_query_req_bits_uop_ftqPtr_value = s2_in_ftqPtr_value;
  assign io_lsq_stld_nuke_query_req_bits_uop_ftqOffset = s2_in_ftqOffset;
  assign io_lsq_stld_nuke_query_req_bits_uop_robIdx_flag = s2_in_robIdx_flag;
  assign io_lsq_stld_nuke_query_req_bits_uop_robIdx_value = s2_in_robIdx_value;
  assign io_lsq_stld_nuke_query_req_bits_uop_sqIdx_flag = s2_in_sqIdx_flag;
  assign io_lsq_stld_nuke_query_req_bits_uop_sqIdx_value = s2_in_sqIdx_value;
  assign io_lsq_stld_nuke_query_req_bits_mask = s2_in_mask;
  assign io_lsq_stld_nuke_query_req_bits_paddr = s2_in_paddr;
  assign io_lsq_stld_nuke_query_req_bits_data_valid = s2_data_valid_for_nuke;
  assign io_lsq_stld_nuke_query_revoke = s3_revoke;
  assign io_lsq_ldld_nuke_query_req_bits_uop_robIdx_flag = s2_in_robIdx_flag;
  assign io_lsq_ldld_nuke_query_req_bits_uop_robIdx_value = s2_in_robIdx_value;
  assign io_lsq_ldld_nuke_query_req_bits_uop_lqIdx_flag = s2_in_lqIdx_flag;
  assign io_lsq_ldld_nuke_query_req_bits_uop_lqIdx_value = s2_in_lqIdx_value;
  assign io_lsq_ldld_nuke_query_req_bits_paddr = s2_in_paddr;
  assign io_lsq_ldld_nuke_query_req_bits_data_valid = s2_data_valid_for_nuke;
  assign io_lsq_ldld_nuke_query_req_bits_is_nc = s2_nc_with_data;
  assign io_lsq_ldld_nuke_query_revoke = s3_revoke;

  // ---- prefetch train（S2 打一拍）----
  assign io_prefetch_train_valid = pf_tr_valid_d;
  assign io_prefetch_train_bits_uop_robIdx_flag = pf_tr_robIdx_flag;
  assign io_prefetch_train_bits_uop_robIdx_value = pf_tr_robIdx_value;
  assign io_prefetch_train_bits_vaddr = pf_tr_vaddr;
  assign io_prefetch_train_bits_paddr = pf_tr_paddr;
  assign io_prefetch_train_bits_miss = pf_tr_miss;
  assign io_prefetch_train_bits_isFirstIssue = pf_tr_isFirstIssue;
  assign io_prefetch_train_bits_meta_prefetch = pf_tr_meta;
  assign io_prefetch_train_l1_valid = pf_tr_l1_valid_d;
  assign io_prefetch_train_l1_bits_uop_robIdx_flag = pf_tr1_robIdx_flag;
  assign io_prefetch_train_l1_bits_uop_robIdx_value = pf_tr1_robIdx_value;
  assign io_prefetch_train_l1_bits_vaddr = pf_tr1_vaddr;
  assign io_prefetch_train_l1_bits_miss = pf_tr1_miss;
  assign io_prefetch_train_l1_bits_isFirstIssue = pf_tr1_isFirstIssue;
  assign io_prefetch_train_l1_bits_meta_prefetch = pf_tr1_meta;
  assign io_s2_prefetch_spec = s2_prefetch_train_valid;
  assign io_s2_ptr_chasing = 1'b0;  // l2l 关闭：恒 0

  // ---- ldCancel（s3 不安全唤醒且非 vec）----
  assign io_ldCancel_ld2Cancel = s3_valid_REG & ~s3_safe_wakeup & ~s3_isvec;

  // ---- fast replay 回灌 io_fast_rep_out ----
  assign io_fast_rep_out_valid = s3_valid_REG & s3_fast_rep_REG;
  assign io_fast_rep_out_bits_uop_exceptionVec_0  = s3_in_excVec[0];
  assign io_fast_rep_out_bits_uop_exceptionVec_1  = s3_in_excVec[1];
  assign io_fast_rep_out_bits_uop_exceptionVec_2  = s3_in_excVec[2];
  assign io_fast_rep_out_bits_uop_exceptionVec_4  = s3_in_excVec[4];
  assign io_fast_rep_out_bits_uop_exceptionVec_6  = s3_in_excVec[6];
  assign io_fast_rep_out_bits_uop_exceptionVec_7  = s3_in_excVec[7];
  assign io_fast_rep_out_bits_uop_exceptionVec_8  = s3_in_excVec[8];
  assign io_fast_rep_out_bits_uop_exceptionVec_9  = s3_in_excVec[9];
  assign io_fast_rep_out_bits_uop_exceptionVec_10 = s3_in_excVec[10];
  assign io_fast_rep_out_bits_uop_exceptionVec_11 = s3_in_excVec[11];
  assign io_fast_rep_out_bits_uop_exceptionVec_12 = s3_in_excVec[12];
  assign io_fast_rep_out_bits_uop_exceptionVec_14 = s3_in_excVec[14];
  assign io_fast_rep_out_bits_uop_exceptionVec_15 = s3_in_excVec[15];
  assign io_fast_rep_out_bits_uop_exceptionVec_16 = s3_in_excVec[16];
  assign io_fast_rep_out_bits_uop_exceptionVec_17 = s3_in_excVec[17];
  assign io_fast_rep_out_bits_uop_exceptionVec_18 = s3_in_excVec[18];
  assign io_fast_rep_out_bits_uop_exceptionVec_19 = s3_in_excVec[19];
  assign io_fast_rep_out_bits_uop_exceptionVec_20 = s3_in_excVec[20];
  assign io_fast_rep_out_bits_uop_exceptionVec_22 = s3_in_excVec[22];
  assign io_fast_rep_out_bits_uop_exceptionVec_23 = s3_in_excVec[23];
  assign io_fast_rep_out_bits_uop_preDecodeInfo_isRVC = s3_in_preDecode_isRVC;
  assign io_fast_rep_out_bits_uop_ftqPtr_flag = s3_in_ftqPtr_flag;
  assign io_fast_rep_out_bits_uop_ftqPtr_value = s3_in_ftqPtr_value;
  assign io_fast_rep_out_bits_uop_ftqOffset = s3_in_ftqOffset;
  assign io_fast_rep_out_bits_uop_fuOpType = s3_in_fuOpType;
  assign io_fast_rep_out_bits_uop_rfWen = s3_in_rfWen;
  assign io_fast_rep_out_bits_uop_fpWen = s3_in_fpWen;
  assign io_fast_rep_out_bits_uop_vpu_vstart = s3_in_vstart;
  assign io_fast_rep_out_bits_uop_vpu_veew = s3_in_veew;
  assign io_fast_rep_out_bits_uop_uopIdx = s3_in_uopIdx;
  assign io_fast_rep_out_bits_uop_pdest = s3_in_pdest;
  assign io_fast_rep_out_bits_uop_robIdx_flag = s3_in_robIdx_flag;
  assign io_fast_rep_out_bits_uop_robIdx_value = s3_in_robIdx_value;
  assign io_fast_rep_out_bits_uop_debugInfo_enqRsTime = s3_in_enqRsTime;
  assign io_fast_rep_out_bits_uop_debugInfo_selectTime = s3_in_selectTime;
  assign io_fast_rep_out_bits_uop_debugInfo_issueTime = s3_in_issueTime;
  assign io_fast_rep_out_bits_uop_storeSetHit = s3_in_storeSetHit;
  assign io_fast_rep_out_bits_uop_waitForRobIdx_flag = s3_in_waitForRobIdx_flag;
  assign io_fast_rep_out_bits_uop_waitForRobIdx_value = s3_in_waitForRobIdx_value;
  assign io_fast_rep_out_bits_uop_loadWaitBit = s3_in_loadWaitBit;
  assign io_fast_rep_out_bits_uop_loadWaitStrict = s3_in_loadWaitStrict;
  assign io_fast_rep_out_bits_uop_lqIdx_flag = s3_in_lqIdx_flag;
  assign io_fast_rep_out_bits_uop_lqIdx_value = s3_in_lqIdx_value;
  assign io_fast_rep_out_bits_uop_sqIdx_flag = s3_in_sqIdx_flag;
  assign io_fast_rep_out_bits_uop_sqIdx_value = s3_in_sqIdx_value;
  assign io_fast_rep_out_bits_vaddr = s3_in_vaddr;
  assign io_fast_rep_out_bits_paddr = s3_in_paddr;
  assign io_fast_rep_out_bits_mask = s3_in_mask;
  assign io_fast_rep_out_bits_data = s3_in_data;
  assign io_fast_rep_out_bits_nc = s3_in_nc;
  assign io_fast_rep_out_bits_isvec = s3_in_isvec;
  assign io_fast_rep_out_bits_is128bit = s3_in_is128bit;
  assign io_fast_rep_out_bits_elemIdx = s3_in_elemIdx;
  assign io_fast_rep_out_bits_alignedType = s3_in_alignedType;
  assign io_fast_rep_out_bits_mbIndex = s3_in_mbIndex;
  assign io_fast_rep_out_bits_reg_offset = s3_in_reg_offset;
  assign io_fast_rep_out_bits_elemIdxInsideVd = s3_in_elemIdxInsideVd;
  assign io_fast_rep_out_bits_vecActive = s3_in_vecActive;
  assign io_fast_rep_out_bits_isLoadReplay = s3_in_isLoadReplay;
  assign io_fast_rep_out_bits_hasROBEntry = s3_in_hasROBEntry;
  assign io_fast_rep_out_bits_delayedLoadError = s3_hw_err;
  assign io_fast_rep_out_bits_lateKill = s3_vp_match_fail;
  assign io_fast_rep_out_bits_schedIndex = s3_in_schedIndex;
  assign io_fast_rep_out_bits_isFrmMisAlignBuf = s3_in_frm_mabuf;
  assign io_fast_rep_out_bits_rep_info_mshr_id = s3_in_rep_info_mshr_id;

  // ---- misalign 入队 io_misalign_enq ----
  assign io_misalign_enq_req_valid = toMisalignBufferValid & s3_misalign_can_go;
  assign io_misalign_enq_req_bits_uop_exceptionVec_0  = s3_in_excVec[0];
  assign io_misalign_enq_req_bits_uop_exceptionVec_1  = s3_in_excVec[1];
  assign io_misalign_enq_req_bits_uop_exceptionVec_2  = s3_in_excVec[2];
  assign io_misalign_enq_req_bits_uop_exceptionVec_3  = s3_in_excVec[3];
  assign io_misalign_enq_req_bits_uop_exceptionVec_5  = s3_in_excVec[5];
  assign io_misalign_enq_req_bits_uop_exceptionVec_6  = s3_in_excVec[6];
  assign io_misalign_enq_req_bits_uop_exceptionVec_7  = s3_in_excVec[7];
  assign io_misalign_enq_req_bits_uop_exceptionVec_8  = s3_in_excVec[8];
  assign io_misalign_enq_req_bits_uop_exceptionVec_9  = s3_in_excVec[9];
  assign io_misalign_enq_req_bits_uop_exceptionVec_10 = s3_in_excVec[10];
  assign io_misalign_enq_req_bits_uop_exceptionVec_11 = s3_in_excVec[11];
  assign io_misalign_enq_req_bits_uop_exceptionVec_12 = s3_in_excVec[12];
  assign io_misalign_enq_req_bits_uop_exceptionVec_13 = s3_in_excVec[13];
  assign io_misalign_enq_req_bits_uop_exceptionVec_14 = s3_in_excVec[14];
  assign io_misalign_enq_req_bits_uop_exceptionVec_15 = s3_in_excVec[15];
  assign io_misalign_enq_req_bits_uop_exceptionVec_16 = s3_in_excVec[16];
  assign io_misalign_enq_req_bits_uop_exceptionVec_17 = s3_in_excVec[17];
  assign io_misalign_enq_req_bits_uop_exceptionVec_18 = s3_in_excVec[18];
  assign io_misalign_enq_req_bits_uop_exceptionVec_19 = s3_in_excVec[19];
  assign io_misalign_enq_req_bits_uop_exceptionVec_20 = s3_in_excVec[20];
  assign io_misalign_enq_req_bits_uop_exceptionVec_21 = s3_in_excVec[21];
  assign io_misalign_enq_req_bits_uop_exceptionVec_22 = s3_in_excVec[22];
  assign io_misalign_enq_req_bits_uop_exceptionVec_23 = s3_in_excVec[23];
  assign io_misalign_enq_req_bits_uop_trigger = s3_in_trigger;
  assign io_misalign_enq_req_bits_uop_preDecodeInfo_isRVC = s3_in_preDecode_isRVC;
  assign io_misalign_enq_req_bits_uop_ftqPtr_flag = s3_in_ftqPtr_flag;
  assign io_misalign_enq_req_bits_uop_ftqPtr_value = s3_in_ftqPtr_value;
  assign io_misalign_enq_req_bits_uop_ftqOffset = s3_in_ftqOffset;
  assign io_misalign_enq_req_bits_uop_fuOpType = s3_in_fuOpType;
  assign io_misalign_enq_req_bits_uop_rfWen = s3_in_rfWen;
  assign io_misalign_enq_req_bits_uop_fpWen = s3_in_fpWen;
  assign io_misalign_enq_req_bits_uop_vpu_vstart = s3_in_vstart;
  assign io_misalign_enq_req_bits_uop_vpu_veew = s3_in_veew;
  assign io_misalign_enq_req_bits_uop_uopIdx = s3_in_uopIdx;
  assign io_misalign_enq_req_bits_uop_pdest = s3_in_pdest;
  assign io_misalign_enq_req_bits_uop_robIdx_flag = s3_in_robIdx_flag;
  assign io_misalign_enq_req_bits_uop_robIdx_value = s3_in_robIdx_value;
  assign io_misalign_enq_req_bits_uop_debugInfo_enqRsTime = s3_in_enqRsTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_selectTime = s3_in_selectTime;
  assign io_misalign_enq_req_bits_uop_debugInfo_issueTime = s3_in_issueTime;
  assign io_misalign_enq_req_bits_uop_storeSetHit = s3_in_storeSetHit;
  assign io_misalign_enq_req_bits_uop_waitForRobIdx_flag = s3_in_waitForRobIdx_flag;
  assign io_misalign_enq_req_bits_uop_waitForRobIdx_value = s3_in_waitForRobIdx_value;
  assign io_misalign_enq_req_bits_uop_loadWaitBit = s3_in_loadWaitBit;
  assign io_misalign_enq_req_bits_uop_loadWaitStrict = s3_in_loadWaitStrict;
  assign io_misalign_enq_req_bits_uop_lqIdx_flag = s3_in_lqIdx_flag;
  assign io_misalign_enq_req_bits_uop_lqIdx_value = s3_in_lqIdx_value;
  assign io_misalign_enq_req_bits_uop_sqIdx_flag = s3_in_sqIdx_flag;
  assign io_misalign_enq_req_bits_uop_sqIdx_value = s3_in_sqIdx_value;
  assign io_misalign_enq_req_bits_vaddr = s3_in_vaddr;
  assign io_misalign_enq_req_bits_fullva = s3_in_fullva;
  assign io_misalign_enq_req_bits_vaNeedExt = s3_in_vaNeedExt;
  assign io_misalign_enq_req_bits_gpaddr = s3_in_gpaddr;
  assign io_misalign_enq_req_bits_mask = s3_in_mask;
  assign io_misalign_enq_req_bits_isvec = s3_in_isvec;
  assign io_misalign_enq_req_bits_elemIdx = s3_in_elemIdx;
  assign io_misalign_enq_req_bits_alignedType = s3_in_alignedType;
  assign io_misalign_enq_req_bits_mbIndex = s3_in_mbIndex;
  assign io_misalign_enq_req_bits_elemIdxInsideVd = s3_in_elemIdxInsideVd;
  assign io_misalign_enq_req_bits_vecTriggerMask = s3_in_vecTriggerMask;

  // ---- rollback ----
  assign io_rollback_valid = io_rollback_valid_0;
  assign io_rollback_bits_isRVC = s3_in_preDecode_isRVC;
  assign io_rollback_bits_robIdx_flag = s3_in_robIdx_flag;
  assign io_rollback_bits_robIdx_value = s3_in_robIdx_value;
  assign io_rollback_bits_ftqIdx_flag = s3_in_ftqPtr_flag;
  assign io_rollback_bits_ftqIdx_value = s3_in_ftqPtr_value;
  assign io_rollback_bits_ftqOffset = s3_in_ftqOffset;
  assign io_rollback_bits_level = s3_vp_match_fail | s3_frm_mis_flush;

  // ---- topdown 调试信息 ----
  assign io_lsTopdownInfo_s1_robIdx = s1_in_robIdx_value;
  assign io_lsTopdownInfo_s1_vaddr_valid = s1_valid & s1_in_has_rob;
  assign io_lsTopdownInfo_s1_vaddr_bits = s1_in_vaddr;
  assign io_lsTopdownInfo_s2_robIdx = s2_in_robIdx_value;
  assign io_lsTopdownInfo_s2_paddr_valid = s2_fire & s2_in_hasROBEntry & ~s2_in_tlbMiss;
  assign io_lsTopdownInfo_s2_paddr_bits = s2_in_paddr;

  // ---- perf 计数（每路事件打两拍再零扩展到 6 位）----
  // golden 每路 perf 各自独立打拍链：perf1 为常量 0 链、perf3 为 s0_fire 的重复链，
  // 与 perf0 各自独立（bug-for-bug 保留重复寄存器）。
  logic perf0_d, perf0_dd, perf1_d, perf1_dd, perf2_d, perf2_dd, perf3_d, perf3_dd,
        perf4_d, perf4_dd, perf5_d, perf5_dd, perf6_d, perf6_dd;
  always_ff @(posedge clock) begin
    perf0_d <= s0_fire;                            perf0_dd <= perf0_d;
    perf1_d <= 1'b0;                               perf1_dd <= perf1_d;
    perf2_d <= s0_fire & ~io_dcache_req_ready;     perf2_dd <= perf2_d;
    perf3_d <= s0_fire;                            perf3_dd <= perf3_d;
    perf4_d <= s1_fire & io_tlb_resp_bits_miss;    perf4_dd <= perf4_d;
    perf5_d <= s1_fire;                            perf5_dd <= perf5_d;
    perf6_d <= s2_fire & io_dcache_resp_bits_miss; perf6_dd <= perf6_d;
  end
  assign io_perf_0_value = {5'h0, perf0_dd};
  assign io_perf_1_value = {5'h0, perf1_dd};
  assign io_perf_2_value = {5'h0, perf2_dd};
  assign io_perf_3_value = {5'h0, perf3_dd};
  assign io_perf_4_value = {5'h0, perf4_dd};
  assign io_perf_5_value = {5'h0, perf5_dd};
  assign io_perf_6_value = {5'h0, perf6_dd};
