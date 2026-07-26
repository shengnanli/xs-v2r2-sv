// PrefetchReqBuffer 包装层(golden 同名扁平端口 ↔ xs_PrefetchReqBuffer_core)。
// golden 顶层端口本身已是扁平标量(无 packed struct 边界), 故 wrapper 仅做
// 顶层改名 + 逐端口直连, 供 FM 对比与 ST 替换。两个 RRArbiterInit 由 core
// 内部例化, FM 两侧同读同一 golden 子模块定义(确定性仲裁逻辑, 非厂商宏)。
module PrefetchReqBuffer (
  input         clock,
  input         reset,
  input         io_in_req_valid,
  input  [49:0] io_in_req_bits_full_vaddr,
  input  [43:0] io_in_req_bits_base_vaddr,
  input         io_in_req_bits_needT,
  input  [6:0]  io_in_req_bits_source,
  output        io_tlb_req_req_valid,
  output [49:0] io_tlb_req_req_bits_vaddr,
  output [2:0]  io_tlb_req_req_bits_cmd,
  output        io_tlb_req_req_bits_kill,
  output        io_tlb_req_req_bits_no_translate,
  input         io_tlb_req_resp_valid,
  input  [47:0] io_tlb_req_resp_bits_paddr_0,
  input  [1:0]  io_tlb_req_resp_bits_pbmt,
  input         io_tlb_req_resp_bits_miss,
  input         io_tlb_req_resp_bits_excp_0_gpf_ld,
  input         io_tlb_req_resp_bits_excp_0_pf_ld,
  input         io_tlb_req_resp_bits_excp_0_af_ld,
  input         io_tlb_req_pmp_resp_ld,
  input         io_tlb_req_pmp_resp_mmio,
  input         io_out_req_ready,
  output        io_out_req_valid,
  output [32:0] io_out_req_bits_tag,
  output [8:0]  io_out_req_bits_set,
  output [43:0] io_out_req_bits_vaddr,
  output        io_out_req_bits_needT,
  output [6:0]  io_out_req_bits_source
);

  xs_PrefetchReqBuffer_core u_core (
    .clock                              (clock),
    .reset                              (reset),
    .io_in_req_valid                    (io_in_req_valid),
    .io_in_req_bits_full_vaddr          (io_in_req_bits_full_vaddr),
    .io_in_req_bits_base_vaddr          (io_in_req_bits_base_vaddr),
    .io_in_req_bits_needT               (io_in_req_bits_needT),
    .io_in_req_bits_source              (io_in_req_bits_source),
    .io_tlb_req_req_valid               (io_tlb_req_req_valid),
    .io_tlb_req_req_bits_vaddr          (io_tlb_req_req_bits_vaddr),
    .io_tlb_req_req_bits_cmd            (io_tlb_req_req_bits_cmd),
    .io_tlb_req_req_bits_kill           (io_tlb_req_req_bits_kill),
    .io_tlb_req_req_bits_no_translate   (io_tlb_req_req_bits_no_translate),
    .io_tlb_req_resp_valid              (io_tlb_req_resp_valid),
    .io_tlb_req_resp_bits_paddr_0       (io_tlb_req_resp_bits_paddr_0),
    .io_tlb_req_resp_bits_pbmt          (io_tlb_req_resp_bits_pbmt),
    .io_tlb_req_resp_bits_miss          (io_tlb_req_resp_bits_miss),
    .io_tlb_req_resp_bits_excp_0_gpf_ld (io_tlb_req_resp_bits_excp_0_gpf_ld),
    .io_tlb_req_resp_bits_excp_0_pf_ld  (io_tlb_req_resp_bits_excp_0_pf_ld),
    .io_tlb_req_resp_bits_excp_0_af_ld  (io_tlb_req_resp_bits_excp_0_af_ld),
    .io_tlb_req_pmp_resp_ld             (io_tlb_req_pmp_resp_ld),
    .io_tlb_req_pmp_resp_mmio           (io_tlb_req_pmp_resp_mmio),
    .io_out_req_ready                   (io_out_req_ready),
    .io_out_req_valid                   (io_out_req_valid),
    .io_out_req_bits_tag                (io_out_req_bits_tag),
    .io_out_req_bits_set                (io_out_req_bits_set),
    .io_out_req_bits_vaddr              (io_out_req_bits_vaddr),
    .io_out_req_bits_needT              (io_out_req_bits_needT),
    .io_out_req_bits_source             (io_out_req_bits_source)
  );

endmodule
