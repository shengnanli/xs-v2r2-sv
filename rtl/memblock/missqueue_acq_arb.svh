// =============================================================================
//  missqueue_acq_arb.svh —— mem_acquire（A 通道）payload Mux1H（被 xs_MissQueue_core 内联）
// -----------------------------------------------------------------------------
//  选中源 = acq_mux = beatsLeft ? acq_state : acq_winner（golden muxState，突发锁定）。
//    idx0 = CMOUnit（CBO 操作）：opcode/address 来自 cmo，source 固定 17，无 alias/vaddr/...
//    idx1 = acquire_from_pipereg（pipereg 直发）：opcode/param/source/address/alias/vaddr/
//           reqSource/needHint/isKeyword 由 C 节 get_acquire 推导出的 pr_acq_* 提供
//    idx2+i = entry i：各字段取 entry 的 mem_acquire bits
//  size 固定 = 6（lgSize=log2(blockBytes)）当有任一 winner；mask 当有 winner 全 1（但 cmo
//  那一项不贡献 mask——golden mask 仅对 idx1..17 置全 1，cmo 项不置；这里照此）。
//  各字段用「OR 归约 of (winner[k] ? src_k : 0)」实现 Mux1H。
// =============================================================================
always_comb begin
  io_mem_acquire_bits_opcode       = '0;
  io_mem_acquire_bits_param        = '0;
  io_mem_acquire_bits_source       = '0;
  io_mem_acquire_bits_address      = '0;
  io_mem_acquire_bits_user_alias   = '0;
  io_mem_acquire_bits_user_vaddr   = '0;
  io_mem_acquire_bits_user_reqSource = '0;
  io_mem_acquire_bits_user_needHint  = 1'b0;
  io_mem_acquire_bits_echo_isKeyword = 1'b0;

  // idx0：CMOUnit（仅 opcode/address/source）
  if (acq_mux[0]) begin
    io_mem_acquire_bits_opcode  |= cmo_acq_opcode;
    io_mem_acquire_bits_address |= cmo_acq_address;
    io_mem_acquire_bits_source  |= SRC_BITS'(ACQ_SRC_ID);   // 6'h11
  end
  // idx1：pipereg 直发
  if (acq_mux[1]) begin
    io_mem_acquire_bits_opcode       |= pr_acq_opcode;
    io_mem_acquire_bits_param        |= pr_acq_param;
    io_mem_acquire_bits_source       |= pr_acq_source;
    io_mem_acquire_bits_address      |= pr_acq_address;
    io_mem_acquire_bits_user_alias   |= pr_acq_alias;
    io_mem_acquire_bits_user_vaddr   |= pr_acq_vaddr;
    io_mem_acquire_bits_user_reqSource |= pr_acq_reqsrc;
    io_mem_acquire_bits_user_needHint   = io_mem_acquire_bits_user_needHint  | pr_acq_needhint;
    io_mem_acquire_bits_echo_isKeyword  = io_mem_acquire_bits_echo_isKeyword | pr_acq_iskeyword;
  end
  // idx2+i：entry i
  for (int i = 0; i < N_ENTRY; i++) begin
    if (acq_mux[2+i]) begin
      io_mem_acquire_bits_opcode       |= e_acq_opcode[i];
      io_mem_acquire_bits_param        |= e_acq_param[i];
      io_mem_acquire_bits_source       |= e_acq_source[i];
      io_mem_acquire_bits_address      |= e_acq_address[i];
      io_mem_acquire_bits_user_alias   |= e_acq_alias[i];
      io_mem_acquire_bits_user_vaddr   |= e_acq_vaddr[i];
      io_mem_acquire_bits_user_reqSource |= e_acq_reqsrc[i];
      io_mem_acquire_bits_user_needHint   = io_mem_acquire_bits_user_needHint  | e_acq_needhint[i];
      io_mem_acquire_bits_echo_isKeyword  = io_mem_acquire_bits_echo_isKeyword | e_acq_iskeyword[i];
    end
  end
end

// size：有任一 winner → 6（整行），否则 0
wire acq_any = |acq_mux;
assign io_mem_acquire_bits_size = acq_any ? 3'h6 : 3'h0;
// mask：golden 仅 idx1..17 winner 时置全 1（cmo 项不贡献 mask）
wire acq_mask_any = |acq_mux[N_ACQ_SRC-1:1];
assign io_mem_acquire_bits_mask = {32{acq_mask_any}};
