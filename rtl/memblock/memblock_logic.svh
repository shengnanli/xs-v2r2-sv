// 自动生成：scripts/gen_memblock.py —— 勿手改
// 顶层组合/时序 glue：assign（端口路由 / 仲裁 / 异常聚合 / 互联）+ always
// （CSR/触发器分发寄存、prefetch enable 打拍、redirect/perf 寄存等）。
// 按 golden 原样保留，不搬运逻辑；阅读时配合 docs/memblock/MemBlock.md 的分节讲解。

  assign inner_ =
    _inner_otherStoutConnect_io_out_valid & ~_inner_StoreUnit_0_io_stout_valid;
  assign inner__probe_1 = inner__11;
  assign inner__probe_2 = inner__11;
  assign inner__probe_3 = inner__11;
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      inner_redirect_next_valid_last_REG <= 1'h0;
      inner_dcache_io_l2_pf_store_only_REG <= 1'h0;
      inner_l1D_pf_enable_next_r <= 1'h0;
      inner_l1D_pf_enable_next_r_1 <= 1'h0;
      inner_sms_io_enable_next_r <= 1'h0;
      inner_sms_io_enable_next_r_1 <= 1'h0;
      inner_sms_io_agt_en_next_r <= 1'h0;
      inner_sms_io_agt_en_next_r_1 <= 1'h0;
      inner_sms_io_pht_en_next_r <= 1'h0;
      inner_sms_io_pht_en_next_r_1 <= 1'h0;
      inner_sms_io_act_threshold_next_r <= 4'hC;
      inner_sms_io_act_threshold_next_r_1 <= 4'hC;
      inner_sms_io_act_stride_next_r <= 6'h1E;
      inner_sms_io_act_stride_next_r_1 <= 6'h1E;
      inner_l1Prefetcher_io_enable_next_r <= 1'h0;
      inner_l1Prefetcher_io_enable_next_r_1 <= 1'h0;
      inner_pf_train_on_hit_REG <= 1'h1;
      inner_pf_train_on_hit <= 1'h1;
      inner_ptw_resp_v <= 1'h0;
      inner_tlbreplay_reg_r_0 <= 1'h0;
      inner_tlbreplay_reg_r_1 <= 1'h0;
      inner_tlbreplay_reg_r_2 <= 1'h0;
      inner_dtlb_ld0_tlbreplay_reg_r_0 <= 1'h0;
      inner_dtlb_ld0_tlbreplay_reg_r_1 <= 1'h0;
      inner_dtlb_ld0_tlbreplay_reg_r_2 <= 1'h0;
      inner_dtlb_ld0_tlbreplay_reg_r_3 <= 1'h0;
      inner_tdata_0_matchType <= 2'h0;
      inner_tdata_0_select <= 1'h0;
      inner_tdata_0_timing <= 1'h0;
      inner_tdata_0_action <= 4'h0;
      inner_tdata_0_chain <= 1'h0;
      inner_tdata_0_store <= 1'h0;
      inner_tdata_0_load <= 1'h0;
      inner_tdata_0_tdata2 <= 64'h0;
      inner_tdata_1_matchType <= 2'h0;
      inner_tdata_1_select <= 1'h0;
      inner_tdata_1_timing <= 1'h0;
      inner_tdata_1_action <= 4'h0;
      inner_tdata_1_chain <= 1'h0;
      inner_tdata_1_store <= 1'h0;
      inner_tdata_1_load <= 1'h0;
      inner_tdata_1_tdata2 <= 64'h0;
      inner_tdata_2_matchType <= 2'h0;
      inner_tdata_2_select <= 1'h0;
      inner_tdata_2_timing <= 1'h0;
      inner_tdata_2_action <= 4'h0;
      inner_tdata_2_chain <= 1'h0;
      inner_tdata_2_store <= 1'h0;
      inner_tdata_2_load <= 1'h0;
      inner_tdata_2_tdata2 <= 64'h0;
      inner_tdata_3_matchType <= 2'h0;
      inner_tdata_3_select <= 1'h0;
      inner_tdata_3_timing <= 1'h0;
      inner_tdata_3_action <= 4'h0;
      inner_tdata_3_chain <= 1'h0;
      inner_tdata_3_store <= 1'h0;
      inner_tdata_3_load <= 1'h0;
      inner_tdata_3_tdata2 <= 64'h0;
      inner_tEnable_0 <= 1'h0;
      inner_tEnable_1 <= 1'h0;
      inner_tEnable_2 <= 1'h0;
      inner_tEnable_3 <= 1'h0;
      inner_vSegmentFlag <= 1'h0;
      inner_last_REG <= 1'h0;
      inner_last_REG_1 <= 1'h0;
      inner_misalign_allow_spec <= 1'h1;
      inner_uncacheState <= 2'h0;
      inner_state <= 2'h0;
      inner_atomicsException <= 1'h0;
      inner_vSegmentException <= 1'h0;
    end
    else begin
      inner_redirect_next_valid_last_REG <= io_redirect_valid;
      inner_dcache_io_l2_pf_store_only_REG <=
        io_ooo_to_mem_csrCtrl_pf_ctrl_l2_pf_store_only;
      if (~(io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable == inner_l1D_pf_enable_next_r))
        inner_l1D_pf_enable_next_r <= io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable;
      if (~(inner_l1D_pf_enable_next_r == inner_l1D_pf_enable_next_r_1))
        inner_l1D_pf_enable_next_r_1 <= inner_l1D_pf_enable_next_r;
      if (~(io_ooo_to_mem_csrCtrl_pf_ctrl_l2_pf_recv_enable == inner_sms_io_enable_next_r))
        inner_sms_io_enable_next_r <= io_ooo_to_mem_csrCtrl_pf_ctrl_l2_pf_recv_enable;
      if (~(inner_sms_io_enable_next_r == inner_sms_io_enable_next_r_1))
        inner_sms_io_enable_next_r_1 <= inner_sms_io_enable_next_r;
      if (~(io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable_agt == inner_sms_io_agt_en_next_r))
        inner_sms_io_agt_en_next_r <= io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable_agt;
      if (~(inner_sms_io_agt_en_next_r == inner_sms_io_agt_en_next_r_1))
        inner_sms_io_agt_en_next_r_1 <= inner_sms_io_agt_en_next_r;
      if (~(io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable_pht == inner_sms_io_pht_en_next_r))
        inner_sms_io_pht_en_next_r <= io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable_pht;
      if (~(inner_sms_io_pht_en_next_r == inner_sms_io_pht_en_next_r_1))
        inner_sms_io_pht_en_next_r_1 <= inner_sms_io_pht_en_next_r;
      if (~(io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_active_threshold == inner_sms_io_act_threshold_next_r))
        inner_sms_io_act_threshold_next_r <=
          io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_active_threshold;
      if (~(inner_sms_io_act_threshold_next_r == inner_sms_io_act_threshold_next_r_1))
        inner_sms_io_act_threshold_next_r_1 <= inner_sms_io_act_threshold_next_r;
      if (~(io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_active_stride == inner_sms_io_act_stride_next_r))
        inner_sms_io_act_stride_next_r <=
          io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_active_stride;
      if (~(inner_sms_io_act_stride_next_r == inner_sms_io_act_stride_next_r_1))
        inner_sms_io_act_stride_next_r_1 <= inner_sms_io_act_stride_next_r;
      if (~(io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable_stride == inner_l1Prefetcher_io_enable_next_r))
        inner_l1Prefetcher_io_enable_next_r <=
          io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_enable_stride;
      if (~(inner_l1Prefetcher_io_enable_next_r == inner_l1Prefetcher_io_enable_next_r_1))
        inner_l1Prefetcher_io_enable_next_r_1 <= inner_l1Prefetcher_io_enable_next_r;
      inner_pf_train_on_hit_REG <= io_ooo_to_mem_csrCtrl_pf_ctrl_l1D_pf_train_on_hit;
      inner_pf_train_on_hit <= inner_pf_train_on_hit_REG;
      inner_ptw_resp_v <=
        _inner_dtlbRepeater_io_tlb_resp_valid
        & ~(inner_sfence_valid & inner_tlbcsr_satp_changed & inner_tlbcsr_vsatp_changed
            & inner_tlbcsr_hgatp_changed);
      if (~({inner_tlbreplay_2,
             inner_tlbreplay_1,
             inner_tlbreplay_0} == {inner_tlbreplay_reg_r_2,
                                    inner_tlbreplay_reg_r_1,
                                    inner_tlbreplay_reg_r_0})) begin
        inner_tlbreplay_reg_r_0 <= inner_tlbreplay_0;
        inner_tlbreplay_reg_r_1 <= inner_tlbreplay_1;
        inner_tlbreplay_reg_r_2 <= inner_tlbreplay_2;
      end
      if (~({_inner_dtlb_ld_tlb_ld_io_tlbreplay_3,
             _inner_dtlb_ld_tlb_ld_io_tlbreplay_2,
             _inner_dtlb_ld_tlb_ld_io_tlbreplay_1,
             _inner_dtlb_ld_tlb_ld_io_tlbreplay_0} == {inner_dtlb_ld0_tlbreplay_reg_r_3,
                                                       inner_dtlb_ld0_tlbreplay_reg_r_2,
                                                       inner_dtlb_ld0_tlbreplay_reg_r_1,
                                                       inner_dtlb_ld0_tlbreplay_reg_r_0})) begin
        inner_dtlb_ld0_tlbreplay_reg_r_0 <= _inner_dtlb_ld_tlb_ld_io_tlbreplay_0;
        inner_dtlb_ld0_tlbreplay_reg_r_1 <= _inner_dtlb_ld_tlb_ld_io_tlbreplay_1;
        inner_dtlb_ld0_tlbreplay_reg_r_2 <= _inner_dtlb_ld_tlb_ld_io_tlbreplay_2;
        inner_dtlb_ld0_tlbreplay_reg_r_3 <= _inner_dtlb_ld_tlb_ld_io_tlbreplay_3;
      end
      if (_GEN_8) begin
        inner_tdata_0_matchType <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_matchType;
        inner_tdata_0_select <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_select;
        inner_tdata_0_action <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_action;
        inner_tdata_0_chain <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_chain;
        inner_tdata_0_store <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_store;
        inner_tdata_0_load <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_load;
        inner_tdata_0_tdata2 <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_tdata2;
      end
      inner_tdata_0_timing <= ~_GEN_8 & inner_tdata_0_timing;
      if (_GEN_9) begin
        inner_tdata_1_matchType <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_matchType;
        inner_tdata_1_select <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_select;
        inner_tdata_1_action <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_action;
        inner_tdata_1_chain <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_chain;
        inner_tdata_1_store <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_store;
        inner_tdata_1_load <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_load;
        inner_tdata_1_tdata2 <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_tdata2;
      end
      inner_tdata_1_timing <= ~_GEN_9 & inner_tdata_1_timing;
      if (_GEN_10) begin
        inner_tdata_2_matchType <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_matchType;
        inner_tdata_2_select <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_select;
        inner_tdata_2_action <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_action;
        inner_tdata_2_chain <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_chain;
        inner_tdata_2_store <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_store;
        inner_tdata_2_load <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_load;
        inner_tdata_2_tdata2 <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_tdata2;
      end
      inner_tdata_2_timing <= ~_GEN_10 & inner_tdata_2_timing;
      if (_GEN_11) begin
        inner_tdata_3_matchType <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_matchType;
        inner_tdata_3_select <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_select;
        inner_tdata_3_action <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_action;
        inner_tdata_3_chain <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_chain;
        inner_tdata_3_store <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_store;
        inner_tdata_3_load <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_load;
        inner_tdata_3_tdata2 <=
          _inner_csrCtrl_delay_io_out_mem_trigger_tUpdate_bits_tdata_tdata2;
      end
      inner_tdata_3_timing <= ~_GEN_11 & inner_tdata_3_timing;
      inner_tEnable_0 <= _inner_csrCtrl_delay_io_out_mem_trigger_tEnableVec_0;
      inner_tEnable_1 <= _inner_csrCtrl_delay_io_out_mem_trigger_tEnableVec_1;
      inner_tEnable_2 <= _inner_csrCtrl_delay_io_out_mem_trigger_tEnableVec_2;
      inner_tEnable_3 <= _inner_csrCtrl_delay_io_out_mem_trigger_tEnableVec_3;
      inner_vSegmentFlag <= inner_last_REG | ~inner_last_REG_1 & inner_vSegmentFlag;
      inner_last_REG <= inner__14;
      inner_last_REG_1 <= _inner_vSegmentUnit_io_uopwriteback_valid;
      inner_misalign_allow_spec <=
        ~(_inner_LoadUnit_0_io_lsq_ldin_bits_isFrmMisAlignBuf
          & _inner_LoadUnit_0_io_lsq_ldin_bits_rep_info_cause_7
          & _inner_LoadUnit_0_io_rollback_valid
          | _inner_LoadUnit_1_io_lsq_ldin_bits_isFrmMisAlignBuf
          & _inner_LoadUnit_1_io_lsq_ldin_bits_rep_info_cause_7
          & _inner_LoadUnit_1_io_rollback_valid
          | _inner_LoadUnit_2_io_lsq_ldin_bits_isFrmMisAlignBuf
          & _inner_LoadUnit_2_io_lsq_ldin_bits_rep_info_cause_7
          & _inner_LoadUnit_2_io_rollback_valid)
        & (_inner_lsq_io_rarValidCount < 7'h44 | inner_misalign_allow_spec);
      if (inner_uncacheState == 2'h0) begin
        if (_inner_pipelineReg_io_in_ready & _inner_lsq_io_uncache_req_valid) begin
          if (_inner_lsq_io_uncache_req_valid) begin
            if (_inner_lsq_io_uncache_req_bits_nc
                & io_ooo_to_mem_csrCtrl_uncache_write_outstanding_enable) begin
            end
            else
              inner_uncacheState <= 2'h1;
          end
          else if (io_ooo_to_mem_csrCtrl_uncache_write_outstanding_enable) begin
          end
          else
            inner_uncacheState <= 2'h2;
        end
      end
      else if ((inner__7 | inner_uncacheState == 2'h2) & inner__8
               & _inner_pipelineReg_1_io_out_valid)
        inner_uncacheState <= 2'h0;
      if (_inner_atomicsUnit_io_out_valid)
        inner_state <= 2'h0;
      else if (inner_st_atomics_1)
        inner_state <= 2'h2;
      else if (inner_st_atomics_0)
        inner_state <= 2'h1;
      inner_atomicsException <=
        ~(_inner_delay_io_out & inner_atomicsException)
        & (_inner_atomicsUnit_io_exceptionInfo_valid | inner_atomicsException);
      inner_vSegmentException <=
        ~(_inner_delay_1_io_out & inner_vSegmentException)
        & (_inner_vSegmentUnit_io_exceptionInfo_valid | inner_vSegmentException);
    end
  end // always @(posedge, posedge)
  always @(posedge clock) begin
    if (io_redirect_valid) begin
      inner_redirect_next_bits_r_robIdx_flag <= io_redirect_bits_robIdx_flag;
      inner_redirect_next_bits_r_robIdx_value <= io_redirect_bits_robIdx_value;
      inner_redirect_next_bits_r_level <= io_redirect_bits_level;
    end
    inner_loadPc <= io_ooo_to_mem_issueLda_0_bits_uop_pc;
    if (_inner_LoadUnit_0_io_s2_prefetch_spec) begin
      inner_l1Prefetcher_stride_train_0_bits_uop_pc_r <= inner_loadPc;
      inner_l1Prefetcher_stride_train_0_bits_uop_pc_r_2 <=
        inner_l1Prefetcher_stride_train_0_bits_uop_pc_r_1;
      inner_prefetcherOpt_io_ld_in_0_bits_uop_pc_r <= inner_loadPc_3;
      inner_prefetcherOpt_io_ld_in_0_bits_uop_pc_r_2 <=
        inner_prefetcherOpt_io_ld_in_0_bits_uop_pc_r_1;
    end
    if (_inner_LoadUnit_0_io_s1_prefetch_spec) begin
      inner_l1Prefetcher_stride_train_0_bits_uop_pc_r_1 <= inner_loadPc;
      inner_prefetcherOpt_io_ld_in_0_bits_uop_pc_r_1 <= inner_loadPc_3;
    end
    inner_loadPc_1 <= io_ooo_to_mem_issueLda_1_bits_uop_pc;
    if (_inner_LoadUnit_1_io_s2_prefetch_spec) begin
      inner_l1Prefetcher_stride_train_1_bits_uop_pc_r <= inner_loadPc_1;
      inner_l1Prefetcher_stride_train_1_bits_uop_pc_r_2 <=
        inner_l1Prefetcher_stride_train_1_bits_uop_pc_r_1;
      inner_prefetcherOpt_io_ld_in_1_bits_uop_pc_r <= inner_loadPc_4;
      inner_prefetcherOpt_io_ld_in_1_bits_uop_pc_r_2 <=
        inner_prefetcherOpt_io_ld_in_1_bits_uop_pc_r_1;
    end
    if (_inner_LoadUnit_1_io_s1_prefetch_spec) begin
      inner_l1Prefetcher_stride_train_1_bits_uop_pc_r_1 <= inner_loadPc_1;
      inner_prefetcherOpt_io_ld_in_1_bits_uop_pc_r_1 <= inner_loadPc_4;
    end
    inner_loadPc_2 <= io_ooo_to_mem_issueLda_2_bits_uop_pc;
    if (_inner_LoadUnit_2_io_s2_prefetch_spec) begin
      inner_l1Prefetcher_stride_train_2_bits_uop_pc_r <= inner_loadPc_2;
      inner_l1Prefetcher_stride_train_2_bits_uop_pc_r_2 <=
        inner_l1Prefetcher_stride_train_2_bits_uop_pc_r_1;
      inner_prefetcherOpt_io_ld_in_2_bits_uop_pc_r <= inner_loadPc_5;
      inner_prefetcherOpt_io_ld_in_2_bits_uop_pc_r_2 <=
        inner_prefetcherOpt_io_ld_in_2_bits_uop_pc_r_1;
    end
    if (_inner_LoadUnit_2_io_s1_prefetch_spec) begin
      inner_l1Prefetcher_stride_train_2_bits_uop_pc_r_1 <= inner_loadPc_2;
      inner_prefetcherOpt_io_ld_in_2_bits_uop_pc_r_1 <= inner_loadPc_5;
    end
    inner_sfence_REG_valid <= io_ooo_to_mem_sfence_valid;
    inner_sfence_REG_bits_rs1 <= io_ooo_to_mem_sfence_bits_rs1;
    inner_sfence_REG_bits_rs2 <= io_ooo_to_mem_sfence_bits_rs2;
    inner_sfence_REG_bits_addr <= io_ooo_to_mem_sfence_bits_addr;
    inner_sfence_REG_bits_id <= io_ooo_to_mem_sfence_bits_id;
    inner_sfence_REG_bits_flushPipe <= io_ooo_to_mem_sfence_bits_flushPipe;
    inner_sfence_REG_bits_hv <= io_ooo_to_mem_sfence_bits_hv;
    inner_sfence_REG_bits_hg <= io_ooo_to_mem_sfence_bits_hg;
    inner_sfence_valid <= inner_sfence_REG_valid;
    inner_sfence_bits_rs1 <= inner_sfence_REG_bits_rs1;
    inner_sfence_bits_rs2 <= inner_sfence_REG_bits_rs2;
    inner_sfence_bits_addr <= inner_sfence_REG_bits_addr;
    inner_sfence_bits_id <= inner_sfence_REG_bits_id;
    inner_sfence_bits_flushPipe <= inner_sfence_REG_bits_flushPipe;
    inner_sfence_bits_hv <= inner_sfence_REG_bits_hv;
    inner_sfence_bits_hg <= inner_sfence_REG_bits_hg;
    inner_tlbcsr_REG_satp_mode <= io_ooo_to_mem_tlbCsr_satp_mode;
    inner_tlbcsr_REG_satp_asid <= io_ooo_to_mem_tlbCsr_satp_asid;
    inner_tlbcsr_REG_satp_ppn <= io_ooo_to_mem_tlbCsr_satp_ppn;
    inner_tlbcsr_REG_satp_changed <= io_ooo_to_mem_tlbCsr_satp_changed;
    inner_tlbcsr_REG_vsatp_mode <= io_ooo_to_mem_tlbCsr_vsatp_mode;
    inner_tlbcsr_REG_vsatp_asid <= io_ooo_to_mem_tlbCsr_vsatp_asid;
    inner_tlbcsr_REG_vsatp_ppn <= io_ooo_to_mem_tlbCsr_vsatp_ppn;
    inner_tlbcsr_REG_vsatp_changed <= io_ooo_to_mem_tlbCsr_vsatp_changed;
    inner_tlbcsr_REG_hgatp_mode <= io_ooo_to_mem_tlbCsr_hgatp_mode;
    inner_tlbcsr_REG_hgatp_vmid <= io_ooo_to_mem_tlbCsr_hgatp_vmid;
    inner_tlbcsr_REG_hgatp_ppn <= io_ooo_to_mem_tlbCsr_hgatp_ppn;
    inner_tlbcsr_REG_hgatp_changed <= io_ooo_to_mem_tlbCsr_hgatp_changed;
    inner_tlbcsr_REG_priv_mxr <= io_ooo_to_mem_tlbCsr_priv_mxr;
    inner_tlbcsr_REG_priv_sum <= io_ooo_to_mem_tlbCsr_priv_sum;
    inner_tlbcsr_REG_priv_vmxr <= io_ooo_to_mem_tlbCsr_priv_vmxr;
    inner_tlbcsr_REG_priv_vsum <= io_ooo_to_mem_tlbCsr_priv_vsum;
    inner_tlbcsr_REG_priv_virt <= io_ooo_to_mem_tlbCsr_priv_virt;
    inner_tlbcsr_REG_priv_spvp <= io_ooo_to_mem_tlbCsr_priv_spvp;
    inner_tlbcsr_REG_priv_imode <= io_ooo_to_mem_tlbCsr_priv_imode;
    inner_tlbcsr_REG_priv_dmode <= io_ooo_to_mem_tlbCsr_priv_dmode;
    inner_tlbcsr_REG_mPBMTE <= io_ooo_to_mem_tlbCsr_mPBMTE;
    inner_tlbcsr_REG_hPBMTE <= io_ooo_to_mem_tlbCsr_hPBMTE;
    inner_tlbcsr_REG_pmm_mseccfg <= io_ooo_to_mem_tlbCsr_pmm_mseccfg;
    inner_tlbcsr_REG_pmm_menvcfg <= io_ooo_to_mem_tlbCsr_pmm_menvcfg;
    inner_tlbcsr_REG_pmm_henvcfg <= io_ooo_to_mem_tlbCsr_pmm_henvcfg;
    inner_tlbcsr_REG_pmm_hstatus <= io_ooo_to_mem_tlbCsr_pmm_hstatus;
    inner_tlbcsr_REG_pmm_senvcfg <= io_ooo_to_mem_tlbCsr_pmm_senvcfg;
    inner_tlbcsr_satp_mode <= inner_tlbcsr_REG_satp_mode;
    inner_tlbcsr_satp_asid <= inner_tlbcsr_REG_satp_asid;
    inner_tlbcsr_satp_ppn <= inner_tlbcsr_REG_satp_ppn;
    inner_tlbcsr_satp_changed <= inner_tlbcsr_REG_satp_changed;
    inner_tlbcsr_vsatp_mode <= inner_tlbcsr_REG_vsatp_mode;
    inner_tlbcsr_vsatp_asid <= inner_tlbcsr_REG_vsatp_asid;
    inner_tlbcsr_vsatp_ppn <= inner_tlbcsr_REG_vsatp_ppn;
    inner_tlbcsr_vsatp_changed <= inner_tlbcsr_REG_vsatp_changed;
    inner_tlbcsr_hgatp_mode <= inner_tlbcsr_REG_hgatp_mode;
    inner_tlbcsr_hgatp_vmid <= inner_tlbcsr_REG_hgatp_vmid;
    inner_tlbcsr_hgatp_ppn <= inner_tlbcsr_REG_hgatp_ppn;
    inner_tlbcsr_hgatp_changed <= inner_tlbcsr_REG_hgatp_changed;
    inner_tlbcsr_priv_mxr <= inner_tlbcsr_REG_priv_mxr;
    inner_tlbcsr_priv_sum <= inner_tlbcsr_REG_priv_sum;
    inner_tlbcsr_priv_vmxr <= inner_tlbcsr_REG_priv_vmxr;
    inner_tlbcsr_priv_vsum <= inner_tlbcsr_REG_priv_vsum;
    inner_tlbcsr_priv_virt <= inner_tlbcsr_REG_priv_virt;
    inner_tlbcsr_priv_spvp <= inner_tlbcsr_REG_priv_spvp;
    inner_tlbcsr_priv_imode <= inner_tlbcsr_REG_priv_imode;
    inner_tlbcsr_priv_dmode <= inner_tlbcsr_REG_priv_dmode;
    inner_tlbcsr_mPBMTE <= inner_tlbcsr_REG_mPBMTE;
    inner_tlbcsr_hPBMTE <= inner_tlbcsr_REG_hPBMTE;
    inner_tlbcsr_pmm_mseccfg <= inner_tlbcsr_REG_pmm_mseccfg;
    inner_tlbcsr_pmm_menvcfg <= inner_tlbcsr_REG_pmm_menvcfg;
    inner_tlbcsr_pmm_henvcfg <= inner_tlbcsr_REG_pmm_henvcfg;
    inner_tlbcsr_pmm_hstatus <= inner_tlbcsr_REG_pmm_hstatus;
    inner_tlbcsr_pmm_senvcfg <= inner_tlbcsr_REG_pmm_senvcfg;
    if (_inner_dtlbRepeater_io_tlb_resp_valid) begin
      inner_ptw_resp_next_data_s2xlate <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2xlate;
      inner_ptw_resp_next_data_s1_entry_tag <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_tag;
      inner_ptw_resp_next_data_s1_entry_asid <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_asid;
      inner_ptw_resp_next_data_s1_entry_vmid <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_vmid;
      inner__tlbreplay_0_allStage_n_T <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_n;
      inner_ptw_resp_next_data_s1_entry_pbmt <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_pbmt;
      inner_ptw_resp_next_data_s1_entry_perm_d <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_perm_d;
      inner_ptw_resp_next_data_s1_entry_perm_a <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_perm_a;
      inner_ptw_resp_next_data_s1_entry_perm_g <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_perm_g;
      inner_ptw_resp_next_data_s1_entry_perm_u <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_perm_u;
      inner_ptw_resp_next_data_s1_entry_perm_x <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_perm_x;
      inner_ptw_resp_next_data_s1_entry_perm_w <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_perm_w;
      inner_ptw_resp_next_data_s1_entry_perm_r <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_perm_r;
      inner_ptw_resp_next_data_s1_entry_level <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_level;
      inner_ptw_resp_next_data_s1_entry_v <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_v;
      inner_ptw_resp_next_data_s1_entry_ppn <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_entry_ppn;
      inner_ptw_resp_next_data_s1_addr_low <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_addr_low;
      inner_ptw_resp_next_data_s1_ppn_low_0 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_0;
      inner_ptw_resp_next_data_s1_ppn_low_1 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_1;
      inner_ptw_resp_next_data_s1_ppn_low_2 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_2;
      inner_ptw_resp_next_data_s1_ppn_low_3 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_3;
      inner_ptw_resp_next_data_s1_ppn_low_4 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_4;
      inner_ptw_resp_next_data_s1_ppn_low_5 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_5;
      inner_ptw_resp_next_data_s1_ppn_low_6 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_6;
      inner_ptw_resp_next_data_s1_ppn_low_7 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_ppn_low_7;
      inner_ptw_resp_next_data_s1_valididx_0 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_0;
      inner_ptw_resp_next_data_s1_valididx_1 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_1;
      inner_ptw_resp_next_data_s1_valididx_2 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_2;
      inner_ptw_resp_next_data_s1_valididx_3 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_3;
      inner_ptw_resp_next_data_s1_valididx_4 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_4;
      inner_ptw_resp_next_data_s1_valididx_5 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_5;
      inner_ptw_resp_next_data_s1_valididx_6 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_6;
      inner_ptw_resp_next_data_s1_valididx_7 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_valididx_7;
      inner_ptw_resp_next_data_s1_pteidx_0 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_0;
      inner_ptw_resp_next_data_s1_pteidx_1 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_1;
      inner_ptw_resp_next_data_s1_pteidx_2 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_2;
      inner_ptw_resp_next_data_s1_pteidx_3 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_3;
      inner_ptw_resp_next_data_s1_pteidx_4 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_4;
      inner_ptw_resp_next_data_s1_pteidx_5 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_5;
      inner_ptw_resp_next_data_s1_pteidx_6 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_6;
      inner_ptw_resp_next_data_s1_pteidx_7 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pteidx_7;
      inner_ptw_resp_next_data_s1_pf <= _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_pf;
      inner_ptw_resp_next_data_s1_af <= _inner_dtlbRepeater_io_tlb_resp_bits_data_s1_af;
      inner_ptw_resp_next_data_s2_entry_tag <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_tag;
      inner_ptw_resp_next_data_s2_entry_vmid <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_vmid;
      inner__tlbreplay_0_allStage_n_T_3 <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_n;
      inner_ptw_resp_next_data_s2_entry_pbmt <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_pbmt;
      inner_ptw_resp_next_data_s2_entry_ppn <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_ppn;
      inner_ptw_resp_next_data_s2_entry_perm_d <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_perm_d;
      inner_ptw_resp_next_data_s2_entry_perm_a <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_perm_a;
      inner_ptw_resp_next_data_s2_entry_perm_g <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_perm_g;
      inner_ptw_resp_next_data_s2_entry_perm_u <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_perm_u;
      inner_ptw_resp_next_data_s2_entry_perm_x <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_perm_x;
      inner_ptw_resp_next_data_s2_entry_perm_w <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_perm_w;
      inner_ptw_resp_next_data_s2_entry_perm_r <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_perm_r;
      inner_ptw_resp_next_data_s2_entry_level <=
        _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_entry_level;
      inner_ptw_resp_next_data_s2_gpf <= _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_gpf;
      inner_ptw_resp_next_data_s2_gaf <= _inner_dtlbRepeater_io_tlb_resp_bits_data_s2_gaf;
      inner_ptw_resp_next_vector_0 <= _inner_dtlbRepeater_io_tlb_resp_bits_vector_0;
      inner_ptw_resp_next_vector_4 <= _inner_dtlbRepeater_io_tlb_resp_bits_vector_4;
      inner_ptw_resp_next_vector_6 <= _inner_dtlbRepeater_io_tlb_resp_bits_vector_6;
      inner_ptw_resp_next_getGpa_0 <= _inner_dtlbRepeater_io_tlb_resp_bits_getGpa_0;
      inner_ptw_resp_next_getGpa_4 <= _inner_dtlbRepeater_io_tlb_resp_bits_getGpa_4;
      inner_ptw_resp_next_getGpa_6 <= _inner_dtlbRepeater_io_tlb_resp_bits_getGpa_6;
    end
    inner_dtlb_ld_tlb_ld_io_requestor_0_req_valid_REG <=
      _inner_vSegmentUnit_io_dtlb_req_valid;
    inner_dtlb_ld_tlb_ld_io_requestor_0_req_bits_REG <=
      _inner_vSegmentUnit_io_dtlb_req_valid;
    if (_inner_vSegmentUnit_io_dtlb_req_valid) begin
      inner_dtlb_ld_tlb_ld_io_requestor_0_req_bits_r_vaddr <=
        _inner_vSegmentUnit_io_dtlb_req_bits_vaddr;
      inner_dtlb_ld_tlb_ld_io_requestor_0_req_bits_r_fullva <=
        _inner_vSegmentUnit_io_dtlb_req_bits_fullva;
      inner_dtlb_ld_tlb_ld_io_requestor_0_req_bits_r_cmd <=
        _inner_vSegmentUnit_io_dtlb_req_bits_cmd;
      inner_dtlb_ld_tlb_ld_io_requestor_0_req_bits_r_debug_robIdx_flag <=
        _inner_vSegmentUnit_io_dtlb_req_bits_debug_robIdx_flag;
      inner_dtlb_ld_tlb_ld_io_requestor_0_req_bits_r_debug_robIdx_value <=
        _inner_vSegmentUnit_io_dtlb_req_bits_debug_robIdx_value;
    end
    inner_loadPc_3 <= io_ooo_to_mem_issueLda_0_bits_uop_pc;
    inner_loadPc_4 <= io_ooo_to_mem_issueLda_1_bits_uop_pc;
    inner_loadPc_5 <= io_ooo_to_mem_issueLda_2_bits_uop_pc;
    inner_l2_hint_2_valid <= io_l2_hint_valid;
    inner_l2_hint_2_bits_sourceId <= io_l2_hint_bits_sourceId;
    inner_l2_hint_2_bits_isKeyword <= io_l2_hint_bits_isKeyword;
    inner_io_mem_to_ooo_sbIsEmpty_REG <= inner__9;
    inner_sbuffer_io_flush_valid_REG <=
      io_ooo_to_mem_flushSb | inner_atomicsFlush | _inner_lsq_io_flushSbuffer_valid;
    if (_inner_atomicsUnit_io_exceptionInfo_valid) begin
      inner_atomicsExceptionAddress <= _inner_atomicsUnit_io_exceptionInfo_bits_vaddr;
      inner_atomicsExceptionGPAddress <= _inner_atomicsUnit_io_exceptionInfo_bits_gpaddr;
      inner_atomicsExceptionIsForVSnonLeafPTE <=
        _inner_atomicsUnit_io_exceptionInfo_bits_isForVSnonLeafPTE;
    end
    if (_inner_vSegmentUnit_io_exceptionInfo_valid) begin
      inner_vSegmentExceptionAddress <= _inner_vSegmentUnit_io_exceptionInfo_bits_vaddr;
      inner_vSegmentExceptionGPAddress <=
        _inner_vSegmentUnit_io_exceptionInfo_bits_gpaddr;
      inner_vSegmentExceptionIsForVSnonLeafPTE <=
        _inner_vSegmentUnit_io_exceptionInfo_bits_isForVSnonLeafPTE;
    end
    inner_io_mem_to_ooo_lsqio_vaddr_REG <=
      ~inner_atomicsException & ~inner_vSegmentException
      & _inner_lsq_io_exceptionAddr_vaNeedExt
        ? (inner__io_mem_to_ooo_lsqio_vaddr_useBareAddr_T
           & inner_tlbcsr_hgatp_mode == 4'h0 | ~inner__io_mem_to_ooo_lsqio_vaddr_T
           & (&inner_tlbcsr_priv_dmode) | ~inner__io_mem_to_ooo_lsqio_vaddr_T
           & inner__io_mem_to_ooo_lsqio_vaddr_useBareAddr_T_7
           & inner_tlbcsr_satp_mode == 4'h0
             ? {16'h0, inner_exceptionVaddr[47:0]}
             : 64'h0)
          | (inner__io_mem_to_ooo_lsqio_vaddr_T & inner_tlbcsr_vsatp_mode == 4'h8
             | ~inner__io_mem_to_ooo_lsqio_vaddr_T
             & inner__io_mem_to_ooo_lsqio_vaddr_useBareAddr_T_7
             & inner_tlbcsr_satp_mode == 4'h8
               ? {{25{inner_exceptionVaddr[38]}}, inner_exceptionVaddr[38:0]}
               : 64'h0)
          | (inner__io_mem_to_ooo_lsqio_vaddr_T & inner_tlbcsr_vsatp_mode == 4'h9
             | ~inner__io_mem_to_ooo_lsqio_vaddr_T
             & inner__io_mem_to_ooo_lsqio_vaddr_useBareAddr_T_7
             & inner_tlbcsr_satp_mode == 4'h9
               ? {{16{inner_exceptionVaddr[47]}}, inner_exceptionVaddr[47:0]}
               : 64'h0)
          | (inner__io_mem_to_ooo_lsqio_vaddr_useBareAddr_T
             & inner_tlbcsr_hgatp_mode == 4'h8
               ? {23'h0, inner_exceptionVaddr[40:0]}
               : 64'h0)
          | (inner__io_mem_to_ooo_lsqio_vaddr_useBareAddr_T
             & inner_tlbcsr_hgatp_mode == 4'h9
               ? {14'h0, inner_exceptionVaddr[49:0]}
               : 64'h0)
        : inner_exceptionVaddr;
    inner_io_mem_to_ooo_lsqio_gpaddr_REG <=
      inner_atomicsException
        ? inner_atomicsExceptionGPAddress
        : inner_vSegmentException
            ? {14'h0, inner_vSegmentExceptionGPAddress}
            : _inner_lsq_io_exceptionAddr_gpaddr;
    inner_io_mem_to_ooo_lsqio_isForVSnonLeafPTE_REG <=
      inner_atomicsException
        ? inner_atomicsExceptionIsForVSnonLeafPTE
        : inner_vSegmentException
            ? inner_vSegmentExceptionIsForVSnonLeafPTE
            : _inner_lsq_io_exceptionAddr_isForVSnonLeafPTE;
    inner_io_mem_to_ooo_topToBackendBypass_l2FlushDone_REG <= io_l2_flush_done;
    inner_io_inner_reset_vector_REG <= inner_io_outer_reset_vector;
    inner_io_outer_beu_errors_icache_REG_ecc_error_valid <=
      inner_io_inner_beu_errors_icache_ecc_error_valid;
    inner_io_outer_beu_errors_icache_REG_ecc_error_bits <=
      inner_io_inner_beu_errors_icache_ecc_error_bits;
    inner_REG_0_value <= inner_io_outer_hc_perfEvents_0_value;
    inner_REG_1_value <= inner_io_outer_hc_perfEvents_1_value;
    inner_REG_2_value <= inner_io_outer_hc_perfEvents_2_value;
    inner_REG_3_value <= inner_io_outer_hc_perfEvents_3_value;
    inner_REG_4_value <= inner_io_outer_hc_perfEvents_4_value;
    inner_REG_5_value <= inner_io_outer_hc_perfEvents_5_value;
    inner_REG_6_value <= inner_io_outer_hc_perfEvents_6_value;
    inner_REG_7_value <= inner_io_outer_hc_perfEvents_7_value;
    inner_REG_8_value <= inner_io_outer_hc_perfEvents_8_value;
    inner_REG_9_value <= inner_io_outer_hc_perfEvents_9_value;
    inner_REG_10_value <= inner_io_outer_hc_perfEvents_10_value;
    inner_REG_11_value <= inner_io_outer_hc_perfEvents_11_value;
    inner_REG_12_value <= inner_io_outer_hc_perfEvents_12_value;
    inner_REG_13_value <= inner_io_outer_hc_perfEvents_13_value;
    inner_REG_14_value <= inner_io_outer_hc_perfEvents_14_value;
    inner_REG_15_value <= inner_io_outer_hc_perfEvents_15_value;
    inner_REG_16_value <= inner_io_outer_hc_perfEvents_16_value;
    inner_REG_17_value <= inner_io_outer_hc_perfEvents_17_value;
    inner_REG_18_value <= inner_io_outer_hc_perfEvents_18_value;
    inner_REG_19_value <= inner_io_outer_hc_perfEvents_19_value;
    inner_REG_20_value <= inner_io_outer_hc_perfEvents_20_value;
    inner_REG_21_value <= inner_io_outer_hc_perfEvents_21_value;
    inner_REG_22_value <= inner_io_outer_hc_perfEvents_22_value;
    inner_REG_23_value <= inner_io_outer_hc_perfEvents_23_value;
    inner_REG_24_value <= inner_io_outer_hc_perfEvents_24_value;
    inner_REG_25_value <= inner_io_outer_hc_perfEvents_25_value;
    inner_REG_26_value <= inner_io_outer_hc_perfEvents_26_value;
    inner_REG_27_value <= inner_io_outer_hc_perfEvents_27_value;
    inner_REG_28_value <= inner_io_outer_hc_perfEvents_28_value;
    inner_REG_29_value <= inner_io_outer_hc_perfEvents_29_value;
    inner_REG_30_value <= inner_io_outer_hc_perfEvents_30_value;
    inner_REG_31_value <= inner_io_outer_hc_perfEvents_31_value;
    inner_REG_32_value <= inner_io_outer_hc_perfEvents_32_value;
    inner_REG_33_value <= inner_io_outer_hc_perfEvents_33_value;
    inner_REG_34_value <= inner_io_outer_hc_perfEvents_34_value;
    inner_REG_35_value <= inner_io_outer_hc_perfEvents_35_value;
    inner_REG_36_value <= inner_io_outer_hc_perfEvents_36_value;
    inner_REG_37_value <= inner_io_outer_hc_perfEvents_37_value;
    inner_REG_38_value <= inner_io_outer_hc_perfEvents_38_value;
    inner_REG_39_value <= inner_io_outer_hc_perfEvents_39_value;
    inner_REG_40_value <= inner_io_outer_hc_perfEvents_40_value;
    inner_REG_41_value <= inner_io_outer_hc_perfEvents_41_value;
    inner_REG_42_value <= inner_io_outer_hc_perfEvents_42_value;
    inner_REG_43_value <= inner_io_outer_hc_perfEvents_43_value;
    inner_REG_44_value <= inner_io_outer_hc_perfEvents_44_value;
    inner_REG_45_value <= inner_io_outer_hc_perfEvents_45_value;
    inner_REG_46_value <= inner_io_outer_hc_perfEvents_46_value;
    inner_REG_47_value <= inner_io_outer_hc_perfEvents_47_value;
    inner_REG_48_value <= inner_io_outer_hc_perfEvents_48_value;
    inner_io_traceCoreInterfaceBypass_fromBackend_fromEncoder_REG_enable <=
      io_traceCoreInterfaceBypass_toL2Top_fromEncoder_enable;
    inner_io_traceCoreInterfaceBypass_fromBackend_fromEncoder_REG_stall <=
      io_traceCoreInterfaceBypass_toL2Top_fromEncoder_stall;
    if (io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_valid
        & (io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_bits_itype == 4'h1
           | io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_bits_itype == 4'h2)) begin
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_r_cause <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_trap_cause;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_r_tval <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_trap_tval;
    end
    if (io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_valid) begin
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_priv_r <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_priv;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_ilastsize_r <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_bits_ilastsize;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iaddr_r <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_bits_iaddr;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iaddr_r_1 <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_bits_ftqOffset;
    end
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_valid_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_valid;
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iretire_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_bits_iretire;
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_itype_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_0_bits_itype;
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_valid_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_1_valid;
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iretire_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_1_bits_iretire;
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_itype_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_1_bits_itype;
    if (io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_1_valid) begin
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_ilastsize_r <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_1_bits_ilastsize;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iaddr_r <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_1_bits_iaddr;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iaddr_r_1 <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_1_bits_ftqOffset;
    end
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_valid_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_2_valid;
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iretire_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_2_bits_iretire;
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_itype_REG <=
      io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_2_bits_itype;
    if (io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_2_valid) begin
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_ilastsize_r <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_2_bits_ilastsize;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iaddr_r <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_2_bits_iaddr;
      inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iaddr_r_1 <=
        io_traceCoreInterfaceBypass_fromBackend_toEncoder_groups_2_bits_ftqOffset;
    end
    inner_io_topDownInfo_toBackend_l2TopMiss_l2Miss_REG <=
      io_topDownInfo_fromL2Top_l2Miss;
    inner_io_topDownInfo_toBackend_l2TopMiss_l3Miss_REG <=
      io_topDownInfo_fromL2Top_l3Miss;
  end // always @(posedge)
  assign inner__probe_6 = _inner_dcache_io_lsu_store_main_pipe_hit_resp_valid;
  assign inner__probe_7 = _inner_dcache_io_lsu_store_replay_resp_valid;
  assign inner__probe_8 = _inner_LoadUnit_0_io_rollback_valid;
  assign inner__probe_9 = _inner_LoadUnit_1_io_rollback_valid;
  assign inner__probe_10 = _inner_LoadUnit_2_io_rollback_valid;
  assign inner__probe_11 = _inner_prefetcherOpt_io_l2_req_valid;
  assign inner__probe_12 = _inner_sbuffer_io_dcache_req_valid;
  assign inner_l1_pf_to_l2_valid_probe = _inner_l1_pf_to_l2_pipMod_io_out_valid;
  assign inner__probe_13 = _inner_VlSplitConnectLdu_io_out_valid;
  assign inner__probe_14 = _inner_VlSplitConnectLdu_1_io_out_valid;
  assign inner_bd_1_ack = _inner_mbistPl_mbist_ack;
  assign inner_bd_1_outdata = _inner_mbistPl_mbist_outdata;
  assign auto_inner_l2_pf_sender_out_addr =
    {16'h0,
     _inner_l1_pf_to_l2_pipMod_io_out_valid
       ? _inner_l1_pf_to_l2_pipMod_io_out_bits_addr
       : _inner_sms_pf_to_l2_pipMod_io_out_bits_addr};
  assign auto_inner_l2_pf_sender_out_pf_source =
    _inner_l1_pf_to_l2_pipMod_io_out_valid
      ? _inner_l1_pf_to_l2_pipMod_io_out_bits_source
      : _inner_sms_pf_to_l2_pipMod_io_out_bits_source;
  assign auto_inner_l2_pf_sender_out_addr_valid =
    inner_l2_pf_sender_optOut_addr_valid_probe;
  assign io_ooo_to_mem_issueSta_1_ready =
    inner_st_atomics_1
      ? _inner_atomicsUnit_io_in_ready
      : _inner_StoreUnit_1_io_stin_ready;
  assign io_ooo_to_mem_issueSta_0_ready =
    inner_st_atomics_0
      ? _inner_atomicsUnit_io_in_ready
      : _inner_StoreUnit_0_io_stin_ready;
  assign io_ooo_to_mem_issueVldu_1_ready =
    inner_vLoadCanAccept_1 | inner_vStoreCanAccept_1;
  assign io_ooo_to_mem_issueVldu_0_ready =
    inner_vLoadCanAccept_0 | inner_vStoreCanAccept_0;
  assign io_mem_to_ooo_topToBackendBypass_hartId = io_hartId;
  assign io_mem_to_ooo_topToBackendBypass_externalInterrupt_mtip =
    auto_inner_clint_int_sink_in_1;
  assign io_mem_to_ooo_topToBackendBypass_externalInterrupt_msip =
    auto_inner_clint_int_sink_in_0;
  assign io_mem_to_ooo_topToBackendBypass_externalInterrupt_meip =
    auto_inner_plic_int_sink_in_0_0;
  assign io_mem_to_ooo_topToBackendBypass_externalInterrupt_seip =
    auto_inner_plic_int_sink_in_1_0;
  assign io_mem_to_ooo_topToBackendBypass_externalInterrupt_debug =
    auto_inner_debug_int_sink_in_0;
  assign io_mem_to_ooo_topToBackendBypass_externalInterrupt_nmi_nmi_31 =
    auto_inner_nmi_int_sink_in_0 | auto_inner_beu_local_int_sink_in_0;
  assign io_mem_to_ooo_topToBackendBypass_externalInterrupt_nmi_nmi_43 =
    auto_inner_nmi_int_sink_in_1;
  assign io_mem_to_ooo_topToBackendBypass_l2FlushDone =
    inner_io_mem_to_ooo_topToBackendBypass_l2FlushDone_REG;
  assign io_mem_to_ooo_lqDeqPtr_flag = _inner_lsq_io_lqDeqPtr_flag;
  assign io_mem_to_ooo_lqDeqPtr_value = _inner_lsq_io_lqDeqPtr_value;
  assign io_mem_to_ooo_memoryViolation_valid =
    (&inner__oldestOneHot_resultOnehot_T_15) & _inner_LoadUnit_0_io_rollback_valid
    | (&inner__oldestOneHot_resultOnehot_T_31) & _inner_LoadUnit_1_io_rollback_valid
    | (&inner__oldestOneHot_resultOnehot_T_46) & _inner_LoadUnit_2_io_rollback_valid
    | (&inner__oldestOneHot_resultOnehot_T_60) & _inner_lsq_io_nack_rollback_0_valid
    | (&inner__oldestOneHot_resultOnehot_T_73) & _inner_lsq_io_nuke_rollback_0_valid
    | (&inner__oldestOneHot_resultOnehot_T_85) & _inner_lsq_io_nuke_rollback_1_valid;
  assign io_mem_to_ooo_memoryViolation_bits_isRVC =
    (&inner__oldestOneHot_resultOnehot_T_15) & _inner_LoadUnit_0_io_rollback_bits_isRVC
    | (&inner__oldestOneHot_resultOnehot_T_31) & _inner_LoadUnit_1_io_rollback_bits_isRVC
    | (&inner__oldestOneHot_resultOnehot_T_46) & _inner_LoadUnit_2_io_rollback_bits_isRVC
    | (&inner__oldestOneHot_resultOnehot_T_60) & _inner_lsq_io_nack_rollback_0_bits_isRVC
    | (&inner__oldestOneHot_resultOnehot_T_73) & _inner_lsq_io_nuke_rollback_0_bits_isRVC
    | (&inner__oldestOneHot_resultOnehot_T_85) & _inner_lsq_io_nuke_rollback_1_bits_isRVC;
  assign io_mem_to_ooo_memoryViolation_bits_robIdx_flag =
    (&inner__oldestOneHot_resultOnehot_T_15)
    & _inner_LoadUnit_0_io_rollback_bits_robIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_31)
    & _inner_LoadUnit_1_io_rollback_bits_robIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_46)
    & _inner_LoadUnit_2_io_rollback_bits_robIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_60)
    & _inner_lsq_io_nack_rollback_0_bits_robIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_73)
    & _inner_lsq_io_nuke_rollback_0_bits_robIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_85)
    & _inner_lsq_io_nuke_rollback_1_bits_robIdx_flag;
  assign io_mem_to_ooo_memoryViolation_bits_robIdx_value =
    ((&inner__oldestOneHot_resultOnehot_T_15)
       ? _inner_LoadUnit_0_io_rollback_bits_robIdx_value
       : 8'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_31)
         ? _inner_LoadUnit_1_io_rollback_bits_robIdx_value
         : 8'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_46)
         ? _inner_LoadUnit_2_io_rollback_bits_robIdx_value
         : 8'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_60)
         ? _inner_lsq_io_nack_rollback_0_bits_robIdx_value
         : 8'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_73)
         ? _inner_lsq_io_nuke_rollback_0_bits_robIdx_value
         : 8'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_85)
         ? _inner_lsq_io_nuke_rollback_1_bits_robIdx_value
         : 8'h0);
  assign io_mem_to_ooo_memoryViolation_bits_ftqIdx_flag =
    (&inner__oldestOneHot_resultOnehot_T_15)
    & _inner_LoadUnit_0_io_rollback_bits_ftqIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_31)
    & _inner_LoadUnit_1_io_rollback_bits_ftqIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_46)
    & _inner_LoadUnit_2_io_rollback_bits_ftqIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_60)
    & _inner_lsq_io_nack_rollback_0_bits_ftqIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_73)
    & _inner_lsq_io_nuke_rollback_0_bits_ftqIdx_flag
    | (&inner__oldestOneHot_resultOnehot_T_85)
    & _inner_lsq_io_nuke_rollback_1_bits_ftqIdx_flag;
  assign io_mem_to_ooo_memoryViolation_bits_ftqIdx_value =
    ((&inner__oldestOneHot_resultOnehot_T_15)
       ? _inner_LoadUnit_0_io_rollback_bits_ftqIdx_value
       : 6'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_31)
         ? _inner_LoadUnit_1_io_rollback_bits_ftqIdx_value
         : 6'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_46)
         ? _inner_LoadUnit_2_io_rollback_bits_ftqIdx_value
         : 6'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_60)
         ? _inner_lsq_io_nack_rollback_0_bits_ftqIdx_value
         : 6'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_73)
         ? _inner_lsq_io_nuke_rollback_0_bits_ftqIdx_value
         : 6'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_85)
         ? _inner_lsq_io_nuke_rollback_1_bits_ftqIdx_value
         : 6'h0);
  assign io_mem_to_ooo_memoryViolation_bits_ftqOffset =
    ((&inner__oldestOneHot_resultOnehot_T_15)
       ? _inner_LoadUnit_0_io_rollback_bits_ftqOffset
       : 4'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_31)
         ? _inner_LoadUnit_1_io_rollback_bits_ftqOffset
         : 4'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_46)
         ? _inner_LoadUnit_2_io_rollback_bits_ftqOffset
         : 4'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_60)
         ? _inner_lsq_io_nack_rollback_0_bits_ftqOffset
         : 4'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_73)
         ? _inner_lsq_io_nuke_rollback_0_bits_ftqOffset
         : 4'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_85)
         ? _inner_lsq_io_nuke_rollback_1_bits_ftqOffset
         : 4'h0);
  assign io_mem_to_ooo_memoryViolation_bits_level =
    (&inner__oldestOneHot_resultOnehot_T_15) & _inner_LoadUnit_0_io_rollback_bits_level
    | (&inner__oldestOneHot_resultOnehot_T_31) & _inner_LoadUnit_1_io_rollback_bits_level
    | (&inner__oldestOneHot_resultOnehot_T_46) & _inner_LoadUnit_2_io_rollback_bits_level
    | (&inner__oldestOneHot_resultOnehot_T_60) & _inner_lsq_io_nack_rollback_0_bits_level
    | (&inner__oldestOneHot_resultOnehot_T_73) | (&inner__oldestOneHot_resultOnehot_T_85);
  assign io_mem_to_ooo_memoryViolation_bits_stFtqIdx_value =
    ((&inner__oldestOneHot_resultOnehot_T_73)
       ? _inner_lsq_io_nuke_rollback_0_bits_stFtqIdx_value
       : 6'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_85)
         ? _inner_lsq_io_nuke_rollback_1_bits_stFtqIdx_value
         : 6'h0);
  assign io_mem_to_ooo_memoryViolation_bits_stFtqOffset =
    ((&inner__oldestOneHot_resultOnehot_T_73)
       ? _inner_lsq_io_nuke_rollback_0_bits_stFtqOffset
       : 4'h0)
    | ((&inner__oldestOneHot_resultOnehot_T_85)
         ? _inner_lsq_io_nuke_rollback_1_bits_stFtqOffset
         : 4'h0);
  assign io_mem_to_ooo_sbIsEmpty = inner_io_mem_to_ooo_sbIsEmpty_REG;
  assign io_mem_to_ooo_lsqio_vaddr = inner_io_mem_to_ooo_lsqio_vaddr_REG;
  assign io_mem_to_ooo_lsqio_gpaddr = inner_io_mem_to_ooo_lsqio_gpaddr_REG;
  assign io_mem_to_ooo_lsqio_isForVSnonLeafPTE =
    inner_io_mem_to_ooo_lsqio_isForVSnonLeafPTE_REG;
  assign io_mem_to_ooo_writebackLda_0_valid =
    _inner_atomicsUnit_io_out_valid | _inner_LoadUnit_0_io_ldout_valid;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_3 =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_exceptionVec_3
      : _inner_LoadUnit_0_io_ldout_bits_uop_exceptionVec_3;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_4 =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_exceptionVec_4
      : _inner_LoadUnit_0_io_ldout_bits_uop_exceptionVec_4;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_5 =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_exceptionVec_5
      : _inner_LoadUnit_0_io_ldout_bits_uop_exceptionVec_5;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_6 =
    _inner_atomicsUnit_io_out_valid & _inner_atomicsUnit_io_out_bits_uop_exceptionVec_6;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_7 =
    _inner_atomicsUnit_io_out_valid & _inner_atomicsUnit_io_out_bits_uop_exceptionVec_7;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_13 =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_exceptionVec_13
      : _inner_LoadUnit_0_io_ldout_bits_uop_exceptionVec_13;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_15 =
    _inner_atomicsUnit_io_out_valid & _inner_atomicsUnit_io_out_bits_uop_exceptionVec_15;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_19 =
    ~_inner_atomicsUnit_io_out_valid
    & _inner_LoadUnit_0_io_ldout_bits_uop_exceptionVec_19;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_21 =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_exceptionVec_21
      : _inner_LoadUnit_0_io_ldout_bits_uop_exceptionVec_21;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_exceptionVec_23 =
    _inner_atomicsUnit_io_out_valid & _inner_atomicsUnit_io_out_bits_uop_exceptionVec_23;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_trigger =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_trigger
      : _inner_LoadUnit_0_io_ldout_bits_uop_trigger;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_rfWen =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_rfWen
      : _inner_LoadUnit_0_io_ldout_bits_uop_rfWen;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_fpWen =
    ~_inner_atomicsUnit_io_out_valid & _inner_LoadUnit_0_io_ldout_bits_uop_fpWen;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_flushPipe =
    ~_inner_atomicsUnit_io_out_valid & _inner_LoadUnit_0_io_ldout_bits_uop_flushPipe;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_pdest =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_pdest
      : _inner_LoadUnit_0_io_ldout_bits_uop_pdest;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_robIdx_flag =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_robIdx_flag
      : _inner_LoadUnit_0_io_ldout_bits_uop_robIdx_flag;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_robIdx_value =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_robIdx_value
      : _inner_LoadUnit_0_io_ldout_bits_uop_robIdx_value;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_debugInfo_enqRsTime =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_debugInfo_enqRsTime
      : _inner_LoadUnit_0_io_ldout_bits_uop_debugInfo_enqRsTime;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_debugInfo_selectTime =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_debugInfo_selectTime
      : _inner_LoadUnit_0_io_ldout_bits_uop_debugInfo_selectTime;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_debugInfo_issueTime =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_uop_debugInfo_issueTime
      : _inner_LoadUnit_0_io_ldout_bits_uop_debugInfo_issueTime;
  assign io_mem_to_ooo_writebackLda_0_bits_uop_replayInst =
    ~_inner_atomicsUnit_io_out_valid & _inner_LoadUnit_0_io_ldout_bits_uop_replayInst;
  assign io_mem_to_ooo_writebackLda_0_bits_data =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_data
      : _inner_LoadUnit_0_io_ldout_bits_data;
  assign io_mem_to_ooo_writebackLda_0_bits_isFromLoadUnit =
    ~_inner_atomicsUnit_io_out_valid;
  assign io_mem_to_ooo_writebackLda_0_bits_debug_isMMIO =
    _inner_atomicsUnit_io_out_valid
      ? _inner_atomicsUnit_io_out_bits_debug_isMMIO
      : _inner_LoadUnit_0_io_ldout_bits_debug_isMMIO;
  assign io_mem_to_ooo_writebackLda_0_bits_debug_isNCIO =
    ~_inner_atomicsUnit_io_out_valid & _inner_LoadUnit_0_io_ldout_bits_debug_isNCIO;
  assign io_mem_to_ooo_writebackLda_0_bits_debug_isPerfCnt =
    ~_inner_atomicsUnit_io_out_valid & _inner_LoadUnit_0_io_ldout_bits_debug_isPerfCnt;
  assign io_mem_to_ooo_writebackLda_1_valid =
    _inner_loadMisalignBuffer_io_writeBack_valid | _inner_LoadUnit_1_io_ldout_valid;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_exceptionVec_3 =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_exceptionVec_3
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_exceptionVec_3;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_exceptionVec_4 =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_exceptionVec_4
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_exceptionVec_4;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_exceptionVec_5 =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_exceptionVec_5
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_exceptionVec_5;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_exceptionVec_13 =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_exceptionVec_13
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_exceptionVec_13;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_exceptionVec_19 =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_exceptionVec_19
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_exceptionVec_19;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_exceptionVec_21 =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_exceptionVec_21
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_exceptionVec_21;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_trigger =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_trigger
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_trigger;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_rfWen =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_rfWen
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_rfWen;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_fpWen =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_fpWen
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_fpWen;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_flushPipe =
    _inner_LoadUnit_1_io_ldout_valid & _inner_LoadUnit_1_io_ldout_bits_uop_flushPipe;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_pdest =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_pdest
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_pdest;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_robIdx_flag =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_robIdx_flag
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_robIdx_flag;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_robIdx_value =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_robIdx_value
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_robIdx_value;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_debugInfo_enqRsTime =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_debugInfo_enqRsTime
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_debugInfo_enqRsTime;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_debugInfo_selectTime =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_debugInfo_selectTime
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_debugInfo_selectTime;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_debugInfo_issueTime =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_uop_debugInfo_issueTime
      : _inner_loadMisalignBuffer_io_writeBack_bits_uop_debugInfo_issueTime;
  assign io_mem_to_ooo_writebackLda_1_bits_uop_replayInst =
    _inner_LoadUnit_1_io_ldout_valid & _inner_LoadUnit_1_io_ldout_bits_uop_replayInst;
  assign io_mem_to_ooo_writebackLda_1_bits_data =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_data
      : _inner_loadMisalignBuffer_io_writeBack_bits_data;
  assign io_mem_to_ooo_writebackLda_1_bits_debug_isMMIO =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_debug_isMMIO
      : _inner_loadMisalignBuffer_io_writeBack_bits_debug_isMMIO;
  assign io_mem_to_ooo_writebackLda_1_bits_debug_isNCIO =
    _inner_LoadUnit_1_io_ldout_valid
      ? _inner_LoadUnit_1_io_ldout_bits_debug_isNCIO
      : _inner_loadMisalignBuffer_io_writeBack_bits_debug_isNCIO;
  assign io_mem_to_ooo_writebackLda_1_bits_debug_isPerfCnt =
    _inner_LoadUnit_1_io_ldout_valid & _inner_LoadUnit_1_io_ldout_bits_debug_isPerfCnt;
  assign io_mem_to_ooo_writebackSta_0_valid =
    inner__6 | inner_ | _inner_StoreUnit_0_io_stout_valid;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_0 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_0;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_1 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_1;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_2 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_2;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_3 =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_exceptionVec_3
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_3
          : _inner_StoreUnit_0_io_stout_bits_uop_exceptionVec_3;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_4 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_4;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_5 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_5;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_6 =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_exceptionVec_6
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_6
          : _inner_StoreUnit_0_io_stout_bits_uop_exceptionVec_6;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_7 =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_exceptionVec_7
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_7
          : _inner_StoreUnit_0_io_stout_bits_uop_exceptionVec_7;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_8 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_8;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_9 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_9;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_10 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_10;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_11 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_11;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_12 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_12;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_13 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_13;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_14 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_14;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_15 =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_exceptionVec_15
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_15
          : _inner_StoreUnit_0_io_stout_bits_uop_exceptionVec_15;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_16 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_16;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_17 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_17;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_18 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_18;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_19 =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_exceptionVec_19
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_19
          : _inner_StoreUnit_0_io_stout_bits_uop_exceptionVec_19;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_20 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_20;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_21 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_21;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_22 =
    ~inner__6 & inner_ & _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_22;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_exceptionVec_23 =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_exceptionVec_23
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_exceptionVec_23
          : _inner_StoreUnit_0_io_stout_bits_uop_exceptionVec_23;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_trigger =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_trigger
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_trigger
          : _inner_StoreUnit_0_io_stout_bits_uop_trigger;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_flushPipe =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_flushPipe
      : inner_ & _inner_otherStoutConnect_io_out_bits_uop_flushPipe;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_robIdx_flag =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_robIdx_flag
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_robIdx_flag
          : _inner_StoreUnit_0_io_stout_bits_uop_robIdx_flag;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_robIdx_value =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_robIdx_value
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_robIdx_value
          : _inner_StoreUnit_0_io_stout_bits_uop_robIdx_value;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_debugInfo_enqRsTime =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_debugInfo_enqRsTime
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_debugInfo_enqRsTime
          : _inner_StoreUnit_0_io_stout_bits_uop_debugInfo_enqRsTime;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_debugInfo_selectTime =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_debugInfo_selectTime
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_debugInfo_selectTime
          : _inner_StoreUnit_0_io_stout_bits_uop_debugInfo_selectTime;
  assign io_mem_to_ooo_writebackSta_0_bits_uop_debugInfo_issueTime =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_uop_debugInfo_issueTime
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_uop_debugInfo_issueTime
          : _inner_StoreUnit_0_io_stout_bits_uop_debugInfo_issueTime;
  assign io_mem_to_ooo_writebackSta_0_bits_debug_isMMIO =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_debug_isMMIO
      : inner_
          ? _inner_otherStoutConnect_io_out_bits_debug_isMMIO
          : _inner_StoreUnit_0_io_stout_bits_debug_isMMIO;
  assign io_mem_to_ooo_writebackSta_0_bits_debug_isNCIO =
    inner__6
      ? _inner_storeMisalignBuffer_io_writeBack_bits_debug_isNCIO
      : ~inner_ & _inner_StoreUnit_0_io_stout_bits_debug_isNCIO;
  assign io_mem_to_ooo_writebackStd_0_valid =
    ~_inner_vsSplit_0_io_vstd_valid & _inner_stdExeUnits_0_io_out_valid
    & ~(_inner_stdExeUnits_0_io_out_bits_uop_fuType[17]);
  assign io_mem_to_ooo_writebackStd_1_valid =
    ~_inner_vsSplit_1_io_vstd_valid & _inner_stdExeUnits_1_io_out_valid
    & ~(_inner_stdExeUnits_1_io_out_bits_uop_fuType[17]);
  assign io_mem_to_ooo_writebackVldu_0_valid =
    _inner_vlMergeBuffer_io_uopWriteback_0_valid
    | _inner_vsMergeBuffer_0_io_uopWriteback_0_valid
    | _inner_vSegmentUnit_io_uopwriteback_valid;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_3 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_3
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_exceptionVec_3
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_exceptionVec_3;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_4 =
    ~_inner_vSegmentUnit_io_uopwriteback_valid
    & _inner_vlMergeBuffer_io_uopWriteback_0_valid
    & _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_exceptionVec_4;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_5 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_5
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
        & _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_exceptionVec_5;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_6 =
    ~_inner_vSegmentUnit_io_uopwriteback_valid
    & ~_inner_vlMergeBuffer_io_uopWriteback_0_valid
    & _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_exceptionVec_6;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_7 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_7
      : ~_inner_vlMergeBuffer_io_uopWriteback_0_valid
        & _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_exceptionVec_7;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_13 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_13
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
        & _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_exceptionVec_13;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_15 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_15
      : ~_inner_vlMergeBuffer_io_uopWriteback_0_valid
        & _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_exceptionVec_15;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_19 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_19
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_exceptionVec_19
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_exceptionVec_19;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_21 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_21
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
        & _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_exceptionVec_21;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_exceptionVec_23 =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_exceptionVec_23
      : ~_inner_vlMergeBuffer_io_uopWriteback_0_valid
        & _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_exceptionVec_23;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_trigger =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_trigger
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_trigger
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_trigger;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_fuOpType =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_fuOpType
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_fuOpType
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_fuOpType;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vecWen =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vecWen
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vecWen
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vecWen;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_v0Wen =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_v0Wen
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_v0Wen
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_v0Wen;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vlWen =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vlWen
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vlWen
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vlWen;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_flushPipe =
    ~_inner_vSegmentUnit_io_uopwriteback_valid
    & (_inner_vlMergeBuffer_io_uopWriteback_0_valid
         ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_flushPipe
         : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_flushPipe);
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vma =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vma
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vma
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vma;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vta =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vta
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vta
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vta;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vsew =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vsew
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vsew
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vsew;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vlmul =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vlmul
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vlmul
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vlmul;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vm =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vm
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vm
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vm;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vstart =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vstart
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vstart
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vstart;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vuopIdx =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vuopIdx
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vuopIdx
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vmask =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vmask
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vmask
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vmask;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_vl =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_vl
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_vl
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_vl;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_nf =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_nf
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_nf
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_nf;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_vpu_veew =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_vpu_veew
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_vpu_veew
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_vpu_veew;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_pdest =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_pdest
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_pdest
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_pdest;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_robIdx_flag =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_robIdx_flag
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_robIdx_flag
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_robIdx_flag;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_robIdx_value =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_robIdx_value
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_robIdx_value
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_robIdx_value;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_debugInfo_enqRsTime =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_debugInfo_enqRsTime
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_debugInfo_selectTime =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_debugInfo_selectTime
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_debugInfo_selectTime
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_debugInfo_issueTime =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_uop_debugInfo_issueTime
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_debugInfo_issueTime
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  assign io_mem_to_ooo_writebackVldu_0_bits_uop_replayInst =
    ~_inner_vSegmentUnit_io_uopwriteback_valid
    & (_inner_vlMergeBuffer_io_uopWriteback_0_valid
         ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_uop_replayInst
         : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_uop_replayInst);
  assign io_mem_to_ooo_writebackVldu_0_bits_data =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_data
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_data
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_data;
  assign io_mem_to_ooo_writebackVldu_0_bits_vdIdx =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_vdIdx
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_vdIdx
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_vdIdx;
  assign io_mem_to_ooo_writebackVldu_0_bits_vdIdxInField =
    _inner_vSegmentUnit_io_uopwriteback_valid
      ? _inner_vSegmentUnit_io_uopwriteback_bits_vdIdxInField
      : _inner_vlMergeBuffer_io_uopWriteback_0_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_0_bits_vdIdxInField
          : _inner_vsMergeBuffer_0_io_uopWriteback_0_bits_vdIdxInField;
  assign io_mem_to_ooo_writebackVldu_0_bits_debug_isMMIO =
    _inner_vSegmentUnit_io_uopwriteback_valid
    & _inner_vSegmentUnit_io_uopwriteback_bits_debug_isMMIO;
  assign io_mem_to_ooo_writebackVldu_0_bits_debug_isNCIO =
    _inner_vSegmentUnit_io_uopwriteback_valid
    & _inner_vSegmentUnit_io_uopwriteback_bits_debug_isNCIO;
  assign io_mem_to_ooo_writebackVldu_0_bits_debug_isPerfCnt =
    _inner_vSegmentUnit_io_uopwriteback_valid
    & _inner_vSegmentUnit_io_uopwriteback_bits_debug_isPerfCnt;
  assign io_mem_to_ooo_writebackVldu_1_valid =
    _inner_vlMergeBuffer_io_uopWriteback_1_valid
    | _inner_vsMergeBuffer_1_io_uopWriteback_0_valid
    | _inner_vfofBuffer_io_uopWriteback_valid;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_3 =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & (_inner_vlMergeBuffer_io_uopWriteback_1_valid
         ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_exceptionVec_3
         : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_exceptionVec_3);
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_4 =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_exceptionVec_4;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_5 =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_exceptionVec_5;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_6 =
    ~_GEN_6 & _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_exceptionVec_6;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_7 =
    ~_GEN_6 & _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_exceptionVec_7;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_13 =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_exceptionVec_13;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_15 =
    ~_GEN_6 & _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_exceptionVec_15;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_19 =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & (_inner_vlMergeBuffer_io_uopWriteback_1_valid
         ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_exceptionVec_19
         : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_exceptionVec_19);
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_21 =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_valid
    & _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_exceptionVec_21;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_exceptionVec_23 =
    ~_GEN_6 & _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_exceptionVec_23;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_trigger =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? 4'h0
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_trigger
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_trigger;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_fuOpType =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_fuOpType
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_fuOpType
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_fuOpType;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vecWen =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vecWen
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vecWen
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vecWen;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_v0Wen =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_v0Wen
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_v0Wen
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_v0Wen;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vlWen =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vlWen
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vlWen
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vlWen;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_flushPipe =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & (_inner_vlMergeBuffer_io_uopWriteback_1_valid
         ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_flushPipe
         : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_flushPipe);
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vma =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vma
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vma
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vma;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vta =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vta
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vta
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vta;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vsew =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vsew
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vsew
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vsew;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vlmul =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vlmul
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vlmul
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vlmul;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vm =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vm
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vm
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vm;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vstart =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vstart
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vstart
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vstart;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vuopIdx =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vuopIdx
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vuopIdx
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vuopIdx;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vmask =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vmask
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vmask;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_vl =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_vl
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_vl
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_vl;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_nf =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_nf
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_nf
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_nf;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_vpu_veew =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_vpu_veew
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_vpu_veew
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_vpu_veew;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_pdest =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_pdest
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_pdest
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_pdest;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_robIdx_flag =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_robIdx_flag
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_robIdx_flag
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_robIdx_flag;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_robIdx_value =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_robIdx_value
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_robIdx_value
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_robIdx_value;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_debugInfo_enqRsTime =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_debugInfo_enqRsTime
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_debugInfo_enqRsTime
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_debugInfo_enqRsTime;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_debugInfo_selectTime =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_debugInfo_selectTime
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_debugInfo_selectTime
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_debugInfo_selectTime;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_debugInfo_issueTime =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_uop_debugInfo_issueTime
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_debugInfo_issueTime
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_debugInfo_issueTime;
  assign io_mem_to_ooo_writebackVldu_1_bits_uop_replayInst =
    ~_inner_vfofBuffer_io_uopWriteback_valid
    & (_inner_vlMergeBuffer_io_uopWriteback_1_valid
         ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_uop_replayInst
         : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_uop_replayInst);
  assign io_mem_to_ooo_writebackVldu_1_bits_data =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? _inner_vfofBuffer_io_uopWriteback_bits_data
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_data
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_data;
  assign io_mem_to_ooo_writebackVldu_1_bits_vdIdx =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? 3'h0
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_vdIdx
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_vdIdx;
  assign io_mem_to_ooo_writebackVldu_1_bits_vdIdxInField =
    _inner_vfofBuffer_io_uopWriteback_valid
      ? 3'h0
      : _inner_vlMergeBuffer_io_uopWriteback_1_valid
          ? _inner_vlMergeBuffer_io_uopWriteback_1_bits_vdIdxInField
          : _inner_vsMergeBuffer_1_io_uopWriteback_0_bits_vdIdxInField;
  assign io_mem_to_ooo_staIqFeedback_0_feedbackSlow_valid =
    inner__12
      ? _inner_atomicsUnit_io_feedbackSlow_valid
      : _inner_StoreUnit_0_io_feedback_slow_valid;
  assign io_mem_to_ooo_staIqFeedback_0_feedbackSlow_bits_hit =
    inner__12 | _inner_StoreUnit_0_io_feedback_slow_bits_hit;
  assign io_mem_to_ooo_staIqFeedback_0_feedbackSlow_bits_sqIdx_flag =
    inner__12
      ? _inner_atomicsUnit_io_feedbackSlow_bits_sqIdx_flag
      : _inner_StoreUnit_0_io_feedback_slow_bits_sqIdx_flag;
  assign io_mem_to_ooo_staIqFeedback_0_feedbackSlow_bits_sqIdx_value =
    inner__12
      ? _inner_atomicsUnit_io_feedbackSlow_bits_sqIdx_value
      : _inner_StoreUnit_0_io_feedback_slow_bits_sqIdx_value;
  assign io_mem_to_ooo_staIqFeedback_1_feedbackSlow_valid =
    inner__13
      ? _inner_atomicsUnit_io_feedbackSlow_valid
      : _inner_StoreUnit_1_io_feedback_slow_valid;
  assign io_mem_to_ooo_staIqFeedback_1_feedbackSlow_bits_hit =
    inner__13 | _inner_StoreUnit_1_io_feedback_slow_bits_hit;
  assign io_mem_to_ooo_staIqFeedback_1_feedbackSlow_bits_sqIdx_flag =
    inner__13
      ? _inner_atomicsUnit_io_feedbackSlow_bits_sqIdx_flag
      : _inner_StoreUnit_1_io_feedback_slow_bits_sqIdx_flag;
  assign io_mem_to_ooo_staIqFeedback_1_feedbackSlow_bits_sqIdx_value =
    inner__13
      ? _inner_atomicsUnit_io_feedbackSlow_bits_sqIdx_value
      : _inner_StoreUnit_1_io_feedback_slow_bits_sqIdx_value;
  assign io_mem_to_ooo_vstuIqFeedback_0_feedbackSlow_valid =
    _inner_vsMergeBuffer_0_io_feedback_0_valid | _inner_vSegmentUnit_io_feedback_valid;
  assign io_mem_to_ooo_vstuIqFeedback_0_feedbackSlow_bits_hit =
    _inner_vSegmentUnit_io_feedback_valid | _inner_vsMergeBuffer_0_io_feedback_0_valid
    & _inner_vsMergeBuffer_0_io_feedback_0_bits_hit;
  assign io_mem_to_ooo_vstuIqFeedback_0_feedbackSlow_bits_sqIdx_flag =
    _inner_vSegmentUnit_io_feedback_valid
    & _inner_vSegmentUnit_io_feedback_bits_sqIdx_flag
    | _inner_vsMergeBuffer_0_io_feedback_0_valid
    & _inner_vsMergeBuffer_0_io_feedback_0_bits_sqIdx_flag;
  assign io_mem_to_ooo_vstuIqFeedback_0_feedbackSlow_bits_sqIdx_value =
    (_inner_vSegmentUnit_io_feedback_valid
       ? _inner_vSegmentUnit_io_feedback_bits_sqIdx_value
       : 6'h0)
    | (_inner_vsMergeBuffer_0_io_feedback_0_valid
         ? _inner_vsMergeBuffer_0_io_feedback_0_bits_sqIdx_value
         : 6'h0);
  assign io_mem_to_ooo_vstuIqFeedback_0_feedbackSlow_bits_lqIdx_flag =
    _inner_vSegmentUnit_io_feedback_valid
    & _inner_vSegmentUnit_io_feedback_bits_lqIdx_flag
    | _inner_vsMergeBuffer_0_io_feedback_0_valid
    & _inner_vsMergeBuffer_0_io_feedback_0_bits_lqIdx_flag;
  assign io_mem_to_ooo_vstuIqFeedback_0_feedbackSlow_bits_lqIdx_value =
    (_inner_vSegmentUnit_io_feedback_valid
       ? _inner_vSegmentUnit_io_feedback_bits_lqIdx_value
       : 7'h0)
    | (_inner_vsMergeBuffer_0_io_feedback_0_valid
         ? _inner_vsMergeBuffer_0_io_feedback_0_bits_lqIdx_value
         : 7'h0);
  assign io_dcacheError_valid =
    _inner_csrCtrl_delay_io_out_cache_error_enable
    & _inner_io_dcacheError_pipMod_io_out_valid;
  assign io_dcacheError_bits_report_to_beu =
    _inner_csrCtrl_delay_io_out_cache_error_enable
    & _inner_io_dcacheError_pipMod_io_out_bits_report_to_beu;
  assign io_uncacheError_ecc_error_valid =
    _inner_csrCtrl_delay_io_out_cache_error_enable
    & _inner_io_uncacheError_ecc_error_pipMod_io_out_valid;
  assign io_inner_reset_vector = inner_io_inner_reset_vector;
  assign io_outer_cpu_halt = inner_io_outer_cpu_halt;
  assign io_outer_l2_flush_en = inner_io_outer_l2_flush_en;
  assign io_outer_power_down_en = inner_io_outer_power_down_en;
  assign io_outer_cpu_critical_error = inner_io_outer_cpu_critical_error;
  assign io_outer_beu_errors_icache_ecc_error_valid =
    inner_io_outer_beu_errors_icache_ecc_error_valid;
  assign io_outer_beu_errors_icache_ecc_error_bits =
    inner_io_outer_beu_errors_icache_ecc_error_bits;
  assign io_inner_hc_perfEvents_0_value = inner_io_inner_hc_perfEvents_0_value;
  assign io_inner_hc_perfEvents_1_value = inner_io_inner_hc_perfEvents_1_value;
  assign io_inner_hc_perfEvents_2_value = inner_io_inner_hc_perfEvents_2_value;
  assign io_inner_hc_perfEvents_3_value = inner_io_inner_hc_perfEvents_3_value;
  assign io_inner_hc_perfEvents_4_value = inner_io_inner_hc_perfEvents_4_value;
  assign io_inner_hc_perfEvents_5_value = inner_io_inner_hc_perfEvents_5_value;
  assign io_inner_hc_perfEvents_6_value = inner_io_inner_hc_perfEvents_6_value;
  assign io_inner_hc_perfEvents_7_value = inner_io_inner_hc_perfEvents_7_value;
  assign io_inner_hc_perfEvents_8_value = inner_io_inner_hc_perfEvents_8_value;
  assign io_inner_hc_perfEvents_9_value = inner_io_inner_hc_perfEvents_9_value;
  assign io_inner_hc_perfEvents_10_value = inner_io_inner_hc_perfEvents_10_value;
  assign io_inner_hc_perfEvents_11_value = inner_io_inner_hc_perfEvents_11_value;
  assign io_inner_hc_perfEvents_12_value = inner_io_inner_hc_perfEvents_12_value;
  assign io_inner_hc_perfEvents_13_value = inner_io_inner_hc_perfEvents_13_value;
  assign io_inner_hc_perfEvents_14_value = inner_io_inner_hc_perfEvents_14_value;
  assign io_inner_hc_perfEvents_15_value = inner_io_inner_hc_perfEvents_15_value;
  assign io_inner_hc_perfEvents_16_value = inner_io_inner_hc_perfEvents_16_value;
  assign io_inner_hc_perfEvents_17_value = inner_io_inner_hc_perfEvents_17_value;
  assign io_inner_hc_perfEvents_18_value = inner_io_inner_hc_perfEvents_18_value;
  assign io_inner_hc_perfEvents_19_value = inner_io_inner_hc_perfEvents_19_value;
  assign io_inner_hc_perfEvents_20_value = inner_io_inner_hc_perfEvents_20_value;
  assign io_inner_hc_perfEvents_21_value = inner_io_inner_hc_perfEvents_21_value;
  assign io_inner_hc_perfEvents_22_value = inner_io_inner_hc_perfEvents_22_value;
  assign io_inner_hc_perfEvents_23_value = inner_io_inner_hc_perfEvents_23_value;
  assign io_inner_hc_perfEvents_24_value = inner_io_inner_hc_perfEvents_24_value;
  assign io_inner_hc_perfEvents_25_value = inner_io_inner_hc_perfEvents_25_value;
  assign io_inner_hc_perfEvents_26_value = inner_io_inner_hc_perfEvents_26_value;
  assign io_inner_hc_perfEvents_27_value = inner_io_inner_hc_perfEvents_27_value;
  assign io_inner_hc_perfEvents_28_value = inner_io_inner_hc_perfEvents_28_value;
  assign io_inner_hc_perfEvents_29_value = inner_io_inner_hc_perfEvents_29_value;
  assign io_inner_hc_perfEvents_30_value = inner_io_inner_hc_perfEvents_30_value;
  assign io_inner_hc_perfEvents_31_value = inner_io_inner_hc_perfEvents_31_value;
  assign io_inner_hc_perfEvents_32_value = inner_io_inner_hc_perfEvents_32_value;
  assign io_inner_hc_perfEvents_33_value = inner_io_inner_hc_perfEvents_33_value;
  assign io_inner_hc_perfEvents_34_value = inner_io_inner_hc_perfEvents_34_value;
  assign io_inner_hc_perfEvents_35_value = inner_io_inner_hc_perfEvents_35_value;
  assign io_inner_hc_perfEvents_36_value = inner_io_inner_hc_perfEvents_36_value;
  assign io_inner_hc_perfEvents_37_value = inner_io_inner_hc_perfEvents_37_value;
  assign io_inner_hc_perfEvents_38_value = inner_io_inner_hc_perfEvents_38_value;
  assign io_inner_hc_perfEvents_39_value = inner_io_inner_hc_perfEvents_39_value;
  assign io_inner_hc_perfEvents_40_value = inner_io_inner_hc_perfEvents_40_value;
  assign io_inner_hc_perfEvents_41_value = inner_io_inner_hc_perfEvents_41_value;
  assign io_inner_hc_perfEvents_42_value = inner_io_inner_hc_perfEvents_42_value;
  assign io_inner_hc_perfEvents_43_value = inner_io_inner_hc_perfEvents_43_value;
  assign io_inner_hc_perfEvents_44_value = inner_io_inner_hc_perfEvents_44_value;
  assign io_inner_hc_perfEvents_45_value = inner_io_inner_hc_perfEvents_45_value;
  assign io_inner_hc_perfEvents_46_value = inner_io_inner_hc_perfEvents_46_value;
  assign io_inner_hc_perfEvents_47_value = inner_io_inner_hc_perfEvents_47_value;
  assign io_resetInFrontendBypass_toL2Top = io_resetInFrontendBypass_fromFrontend;
  assign io_traceCoreInterfaceBypass_fromBackend_fromEncoder_enable =
    inner_io_traceCoreInterfaceBypass_fromBackend_fromEncoder_REG_enable;
  assign io_traceCoreInterfaceBypass_fromBackend_fromEncoder_stall =
    inner_io_traceCoreInterfaceBypass_fromBackend_fromEncoder_REG_stall;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_priv =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_priv_r;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_cause =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_r_cause;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_tval =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_trap_r_tval;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_valid =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_valid_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iaddr =
    50'(inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iaddr_r
        + {45'h0,
           inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iaddr_r_1,
           1'h0});
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_itype =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_itype_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iretire =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_iretire_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_ilastsize =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_0_bits_ilastsize_r;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_valid =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_valid_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iaddr =
    50'(inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iaddr_r
        + {45'h0,
           inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iaddr_r_1,
           1'h0});
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_itype =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_itype_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iretire =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_iretire_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_ilastsize =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_1_bits_ilastsize_r;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_valid =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_valid_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iaddr =
    50'(inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iaddr_r
        + {45'h0,
           inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iaddr_r_1,
           1'h0});
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_itype =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_itype_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iretire =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_iretire_REG;
  assign io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_ilastsize =
    inner_io_traceCoreInterfaceBypass_toL2Top_toEncoder_groups_2_bits_ilastsize_r;
  assign io_wfi_wfiSafe =
    _inner_dcache_io_wfi_wfiSafe & _inner_uncache_io_wfi_wfiSafe
    & _inner_lsq_io_wfi_wfiSafe & _inner_ptw_io_wfi_wfiSafe;
  assign io_topDownInfo_toBackend_lqEmpty = _inner_lsq_io_lqEmpty;
  assign io_topDownInfo_toBackend_sqEmpty = _inner_lsq_io_sqEmpty;
  assign io_topDownInfo_toBackend_l2TopMiss_l2Miss =
    inner_io_topDownInfo_toBackend_l2TopMiss_l2Miss_REG;
  assign io_topDownInfo_toBackend_l2TopMiss_l3Miss =
    inner_io_topDownInfo_toBackend_l2TopMiss_l3Miss_REG;
  assign io_dft_frnt_ram_hold = io_dft_ram_hold;
  assign io_dft_frnt_ram_bypass = io_dft_ram_bypass;
  assign io_dft_frnt_ram_bp_clken = io_dft_ram_bp_clken;
  assign io_dft_frnt_ram_aux_clk = io_dft_ram_aux_clk;
  assign io_dft_frnt_ram_aux_ckbp = io_dft_ram_aux_ckbp;
  assign io_dft_frnt_ram_mcp_hold = io_dft_ram_mcp_hold;
  assign io_dft_frnt_cgen = io_dft_cgen;
  assign io_dft_bcknd_cgen = io_dft_cgen;
