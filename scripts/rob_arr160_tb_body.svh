
  // ===================================================================
  // 边界定向验证: ROB_SIZE=160 + index_in_range() guard
  //   合法下标 158/159 → 读出正确 entry(功能 bit-exact)
  //   越界下标 160/255 → guard 使输出为 X(不 clamp/wrap/取 entry-0)
  // ===================================================================
  task automatic zero_inputs();
    reset = 1'b1;
    io_redirect_valid = 0; io_redirect_bits_robIdx_flag = 0;
    io_redirect_bits_robIdx_value = 0; io_redirect_bits_level = 0;
    enq_valid = 0; enq_first_uop = 0; enq_need_write_rf = 0; enq_write_std = 0;
    enq_block_backward = 0; enq_wait_forward = 0; enq_is_wfi = 0;
    enq_has_exception = 0; enq_trigger_dmode = 0; enq_allow_interrupt = '1;
    wb_valid = 0; wb_is_std = 0; wb_fflags_valid = 0; wb_vxsat_valid = 0;
    wb_vxsat = 0; wb_branch_taken = 0; excp_wb_valid = 0; excp_wb_need_flush = 0;
    eg_valid = 0; eg_robidx_flag = 0; eg_robidx_value = 0; eg_is_exception = 0;
    eg_flush_pipe = 0; eg_replay_inst = 0; eg_is_vls = 0; eg_is_enq_excp = 0; eg_is_vset = 0;
    io_eg_vstartEn = 0; io_eg_vstart = 0;
    eg_state_vstart = 0; eg_state_vsew = 0; eg_state_veew = 0; eg_state_vlmul = 0;
    eg_state_nf = 0; eg_state_isStrided = 0; eg_state_isIndexed = 0; eg_state_isWhole = 0;
    eg_state_isVlm = 0; eg_state_vstartEn = 0; eg_state_isVecLoad = 0; eg_state_isEnqExcp = 0;
    io_csr_intrBitSet = 0; io_csr_wfiEvent = 0; io_csr_criticalErrorState = 0;
    io_snpt_useSnpt = 0; io_wfi_enable = 1; io_wfi_safeFromMem = 1; io_wfi_safeFromFrontend = 1;
    io_fromVecExcpMod_busy = 0; io_trace_blockCommit = 0;
    rab_can_enq = 1; rab_status_commit_end = 1; rab_status_walk_end = 1; vtype_status_walk_end = 1;
    io_misPredWb = 0; io_wb1_redir = 0; io_wb3_redir = 0; io_wb5_redir = 0;
    io_debugHeadLsIssue = 0;
    io_vstartIsZero = 0;
    io_lsTopdown_s1_valid = 0; io_lsTopdown_s2_valid = 0;
    for (int i=0;i<3;i++) begin
      io_lsTopdown_s1_robIdx[i]=0; io_lsTopdown_s1_bits[i]=0;
      io_lsTopdown_s2_robIdx[i]=0; io_lsTopdown_s2_bits[i]=0;
    end
    for (int i=0;i<RENAME_WIDTH;i++) begin
      enq_num_wb[i]=1; enq_robidx_value[i]=0; enq_info[i]='0; enq_fuType[i]=0;
    end
    for (int i=0;i<NUM_EXU_WB;i++) begin wb_robidx[i]=0; wb_num[i]=1; wb_fflags[i]=0; end
    for (int i=0;i<NUM_WB;i++) excp_wb_robidx[i]=0;
    for (int i=0;i<COMMIT_WIDTH;i++) deq_ptr_vec[i]='{flag:0, value:PTR_W'(i)};
    deq_ptr_next0 = '{flag:0, value:0};
    for (int i=0;i<RENAME_WIDTH;i++) enq_ptr_vec[i]='{flag:0, value:PTR_W'(i)};
    snap_ptr0 = '{flag:0, value:0};
    // debug head-issue arrays are difftest sinks; leave defaults
  endtask

  task automatic chk(input string nm, input logic got, input logic exp);
    checks++;
    if (got !== exp) begin
      errors++;
      $display("  [MISMATCH] %s got=%b exp=%b @%0t", nm, got, exp, $time);
    end
  endtask

  task automatic chk_x(input string nm, input logic got);
    checks++;
    if (!$isunknown(got)) begin
      errors++;
      $display("  [NOT-X] %s expected X(unreachable idx) got=%b @%0t", nm, got, $time);
    end
  endtask

  // 驱动一条 enqueue: 口 slot 在 robIdx=idx 处置入 vls=vls_v
  task automatic do_enq(input int slot, input logic [PTR_W-1:0] idx, input logic vls_v);
    enq_ptr_vec[slot] = '{flag:0, value:idx};
    enq_valid[slot] = 1'b1;
    enq_first_uop[slot] = 1'b1;
    enq_num_wb[slot] = 1;
    enq_write_std[slot] = 1'b1;  // std → std_writebacked=~1=0 → not committable, stays valid
    enq_info[slot] = '0;
    enq_info[slot].vls = vls_v;
  endtask

  initial begin
    zero_inputs();
    // reset 3 cycles
    repeat (3) @(posedge clk);
    #1 reset = 1'b0;
    @(posedge clk); #1;

    // ---- 入队 robIdx=158 (vls=1) 和 159 (vls=0) ----
    zero_inputs(); reset = 1'b0;
    do_enq(0, PTR_W'(158), 1'b1);
    do_enq(1, PTR_W'(159), 1'b0);
    @(posedge clk);   // 采样入队
    #1;
    // 停止入队, 保持条目
    enq_valid = 0; enq_first_uop = 0;
    @(posedge clk); #1;   // 条目已落 rob_entries[158]/[159]

    // ---- 合法下标读: deqPtr=158 → valid=1, vls=1 ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(158)};
    #1;
    chk("valid@158", o_deq_entry_valid_0, 1'b1);
    chk("vls@158",   o_deq_entry_vls[0],  1'b1);

    // ---- 合法下标读: deqPtr=159 → valid=1, vls=0 ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(159)};
    #1;
    chk("valid@159", o_deq_entry_valid_0, 1'b1);
    chk("vls@159",   o_deq_entry_vls[0],  1'b0);

    // ---- 空条目下标(0, 未入队) → valid=0 ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(0)};
    #1;
    chk("valid@0-empty", o_deq_entry_valid_0, 1'b0);

    // ---- 越界下标 160 → guard → X (不 clamp 到 159, 不 wrap 到 0, 不取 entry-0) ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(160)};
    #1;
    chk_x("valid@160-oob", o_deq_entry_valid_0);
    chk_x("vls@160-oob",   o_deq_entry_vls[0]);
    chk_x("mmio@160-oob",  o_deq_entry_mmio_0);

    // ---- 越界下标 255 → guard → X ----
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(255)};
    #1;
    chk_x("valid@255-oob", o_deq_entry_valid_0);
    chk_x("vls@255-oob",   o_deq_entry_vls[0]);
    chk_x("mmio@255-oob",  o_deq_entry_mmio_0);

    // ---- 关键反例: 越界读出的 X 必须 ≠ entry-0 数据(entry0 未入队 valid=0)。
    //      若实现是 clamp→0 或 wrap→0 则会读出 valid=0(非 X); chk_x 已覆盖(要求 X)。
    //      再显式确认 158(vls=1) 处的合法读 ≠ 越界读(X), 证明无「返回正常 entry 数据」。
    deq_ptr_vec[0] = '{flag:0, value:PTR_W'(160)};
    #1;
    if (o_deq_entry_vls[0] === 1'b1) begin
      errors++; $display("  [GAP] oob idx 160 returned entry-158 data(vls=1)! not undefined");
    end

    if (errors == 0)
      $display("=== boundary UT PASSED: checks=%0d errors=0 ===", checks);
    else
      $display("=== boundary UT FAILED: checks=%0d errors=%0d ===", checks, errors);
    // TEST PASSED sentinel for ut_common.mk grep
    if (errors == 0) $display("TEST PASSED");
    else             $display("TEST FAILED");
    $finish;
  end
