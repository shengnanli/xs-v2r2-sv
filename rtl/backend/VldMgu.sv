// =============================================================================
// VldMgu.sv —— 向量 load 写回的按字节合并：新数据 / 全 1 / 旧值 三选一
//
// 在哪一层：写回数据通路 WbDataPath → VldMergeUnit（向量 load 口各一个）→ 本件。
//   向量 load 的一个 uop 写回一个 128 位 vd。按 RVV 语义，vd 的每个字节要么取 load
//   回来的新数据（active），要么在 agnostic 策略下写全 1，要么保持旧值（undisturbed）。
//   哪个字节属于哪类由 ByteMaskTailGen 按 vstart / vl / mask / vta / vma 算出。
//
// 设计源：Scala fu/vector/Mgu.scala，class VldMgu extends Mgu（只覆写 maskUsed = mask[15:0]）。
//   golden 里只剩被 VldMergeUnit 用到的那部分：
//   * narrow / dstMask 两个开关在 VldMergeUnit 里恒 0（向量 load 不做窄化、不产 mask 结果），
//     firtool 把它们连同「mask 结果按位拼接」那一大块整体删掉，vdIdx 直接用原值；
//   * 元素宽度：索引访存（isIndexedVls）的数据元素宽取 vsew，其余取 eew。
//   * ★oldVd 与 vd 在 VldMergeUnit 里接的是同一根线★（load 单元已把旧值合进数据），
//     本件仍按 Mgu 的通用接口分开收，保持与 golden 端口一致。
//
// 子模块：ByteMaskTailGen（本 lane 重写，同名白盒）。
// golden 对照：G1-canonical/golden-rtl/VldMgu.sv
// =============================================================================
module xs_VldMgu_core (
  input  logic [127:0] new_vd,        // 新数据
  input  logic [127:0] old_vd,        // 旧值
  input  logic [127:0] mask,          // v0 掩码（只用低 16 位：本 vd 的 16 个元素）
  input  logic         ta,
  input  logic         ma,
  input  logic [7:0]   vl,
  input  logic [7:0]   vstart,
  input  logic [1:0]   eew,           // 访存元素宽
  input  logic [1:0]   vsew,          // 数据元素宽（索引访存用它）
  input  logic [2:0]   vd_idx,
  input  logic         is_indexed,
  output logic [127:0] out_vd
);
  localparam int VD_BYTES = 16;

  logic [VD_BYTES-1:0] active_en, agnostic_en;
  ByteMaskTailGen u_mask_tail (
    .io_in_begin       (vstart),
    .io_in_end         (vl),
    .io_in_vma         (ma),
    .io_in_vta         (ta),
    .io_in_vsew        (is_indexed ? vsew : eew),
    .io_in_maskUsed    (mask[15:0]),
    .io_in_vdIdx       (vd_idx),
    .io_out_activeEn   (active_en),
    .io_out_agnosticEn (agnostic_en)
  );

  // 每个字节：active 取新数据，否则 agnostic 写 0xFF，否则保持旧值
  for (genvar b = 0; b < VD_BYTES; b++) begin : g_byte
    assign out_vd[b*8 +: 8] = active_en[b]   ? new_vd[b*8 +: 8] :
                              agnostic_en[b] ? 8'hFF            :
                                               old_vd[b*8 +: 8];
  end
endmodule

module VldMgu (
  input  [127:0] io_in_vd,
  input  [127:0] io_in_oldVd,
  input  [127:0] io_in_mask,
  input          io_in_info_ta,
  input          io_in_info_ma,
  input  [7:0]   io_in_info_vl,
  input  [7:0]   io_in_info_vstart,
  input  [1:0]   io_in_info_eew,
  input  [1:0]   io_in_info_vsew,
  input  [2:0]   io_in_info_vdIdx,
  input          io_in_isIndexedVls,
  output [127:0] io_out_vd
);
  xs_VldMgu_core u_core (
    .new_vd     (io_in_vd),
    .old_vd     (io_in_oldVd),
    .mask       (io_in_mask),
    .ta         (io_in_info_ta),
    .ma         (io_in_info_ma),
    .vl         (io_in_info_vl),
    .vstart     (io_in_info_vstart),
    .eew        (io_in_info_eew),
    .vsew       (io_in_info_vsew),
    .vd_idx     (io_in_info_vdIdx),
    .is_indexed (io_in_isIndexedVls),
    .out_vd     (io_out_vd)
  );
endmodule
