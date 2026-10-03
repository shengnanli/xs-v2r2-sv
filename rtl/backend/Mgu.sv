// =============================================================================
// Mgu.sv —— 向量算术写回的 Mask/tail 合并单元（Mask Generate Unit，纯组合）
//
// 在哪一层：向量执行单元（VIAlu / VFAlu 等）算完一个 128 位 vd 之后，由本件按 RVV 的
//   vstart / vl / 掩码 / vta / vma 语义决定 vd 的每个字节最终写回什么。
// 设计源：Scala fu/vector/Mgu.scala class Mgu（VldMgu 是它的子类，本仓已另有重写）。
//
// 两条结果通路（由 info.dstMask 二选一）：
//   A. 普通指令（dstMask=0）：ByteMaskTailGen 把 16 个字节分成 active / agnostic / 其他三类，
//      每字节分别取 新值 / 全 1 / 旧值。
//   B. 产生掩码的指令（dstMask=1，如 vmseq）：结果是一个按元素一位的掩码，一个 vd 组
//      只占 oldVd 的 16>>eew 位（SEW8 占 16 位、SEW16 占 8 位 …），落在
//      [n*(vdIdx+1)-1 : n*vdIdx]。该段每一位：
//        元素被掩码选中（maskBits[i]）→ 取 vd[i]；否则 ma ? 1 : oldVd 对应位。
//      段外的位保持 oldVd。
// 关键细节：
//   - vdIdx：窄化指令（narrow）两个 vd 组合成一个结果组，所以用 vdIdx>>1。
//   - 本 vd 组用到的 16 位掩码（maskUsed）：按 eew 从 128 位 v0 里取第 vdIdx 组：
//       eew=8 取 mask[16*vdIdx +: 16]，eew=16 取 8 位（高位补 0），eew=32 取 4 位，eew=64 取 2 位。
//     通路 B 对 mask 与 oldVd 做同样的切分（Scala 里是两个函数 VecDataToMaskDataVec /
//     splitVdMask，算法一样）。
//   - golden 里 isIndexedVls / vsew / vlmul / valid / illegal / debugOnly 全部被 firtool 消掉
//     （父级没接，或恒 false），端口表只剩本文件 wrapper 列出的 13 个。
// 子模块：ByteMaskTailGen（本仓已签核的重写件，内含 UIntToContLow1s/0s + MaskExtractor）。
// golden 对照：G1-canonical/golden-rtl/Mgu.sv
// =============================================================================
module xs_Mgu_core (
  input  logic [127:0] new_vd,        // 执行单元算出的新值
  input  logic [127:0] old_vd,        // vd 旧值
  input  logic [127:0] mask,          // v0 掩码（整个 128 位）
  input  logic         ta,
  input  logic         ma,
  input  logic [7:0]   vl,
  input  logic [7:0]   vstart,
  input  logic [1:0]   eew,           // 元素宽：0=8b 1=16b 2=32b 3=64b
  input  logic [2:0]   vd_idx_in,     // 本 uop 是第几个 vd 组（0~7）
  input  logic         narrow,
  input  logic         dst_mask,      // 结果是掩码（通路 B）
  output logic [127:0] out_vd,
  output logic [15:0]  out_active
);
  localparam int VD_BYTES = 16;

  // ---- §1 vd 组号与本组用到的掩码位 ----
  logic [2:0]  vd_idx;
  assign vd_idx = narrow ? {1'b0, vd_idx_in[2:1]} : vd_idx_in;

  // 按 eew 把 128 位切成 8 组，每组取本组元素对应的 16>>eew 位（高位补 0）
  function automatic logic [15:0] group_bits(input logic [127:0] v, input logic [1:0] ew,
                                             input logic [2:0] g);
    case (ew)
      2'd0:    group_bits = v[g*16 +: 16];
      2'd1:    group_bits = {8'b0,  v[g*8 +: 8]};
      2'd2:    group_bits = {12'b0, v[g*4 +: 4]};
      default: group_bits = {14'b0, v[g*2 +: 2]};
    endcase
  endfunction

  logic [15:0] mask_used;     // 本组元素的掩码位
  logic [15:0] old_mask_bits; // 通路 B：oldVd 里本组那一段
  assign mask_used     = group_bits(mask,   eew, vd_idx);
  assign old_mask_bits = group_bits(old_vd, eew, vd_idx);

  // ---- §2 通路 A：按字节 active / agnostic / 保留 ----
  logic [VD_BYTES-1:0] active_en, agnostic_en;
  ByteMaskTailGen maskTailGen (
    .io_in_begin       (vstart),
    .io_in_end         (vl),
    .io_in_vma         (ma),
    .io_in_vta         (ta),
    .io_in_vsew        (eew),
    .io_in_maskUsed    (mask_used),
    .io_in_vdIdx       (vd_idx),
    .io_out_activeEn   (active_en),
    .io_out_agnosticEn (agnostic_en)
  );

  logic [127:0] byte_result;
  for (genvar b = 0; b < VD_BYTES; b++) begin : g_byte
    assign byte_result[b*8 +: 8] = active_en[b]   ? new_vd[b*8 +: 8] :
                                   agnostic_en[b] ? 8'hFF            :
                                                    old_vd[b*8 +: 8];
  end

  // ---- §3 通路 B：掩码结果嵌进 oldVd 的本组段 ----
  logic [15:0]  mask_vd;      // 本组 16 位掩码结果（只有低 16>>eew 位有意义）
  for (genvar i = 0; i < VD_BYTES; i++) begin : g_mask_bit
    assign mask_vd[i] = mask_used[i] ? new_vd[i] : (ma | old_mask_bits[i]);
  end

  logic [127:0] mask_result;
  always_comb begin
    mask_result = old_vd;
    case (eew)
      2'd0:    mask_result[vd_idx*16 +: 16] = mask_vd[15:0];
      2'd1:    mask_result[vd_idx*8  +: 8]  = mask_vd[7:0];
      2'd2:    mask_result[vd_idx*4  +: 4]  = mask_vd[3:0];
      default: mask_result[vd_idx*2  +: 2]  = mask_vd[1:0];
    endcase
  end

  // ---- §4 输出 ----
  assign out_vd     = dst_mask ? mask_result : byte_result;
  assign out_active = active_en;
endmodule

module Mgu (
  input  logic [127:0] io_in_vd,
  input  logic [127:0] io_in_oldVd,
  input  logic [127:0] io_in_mask,
  input  logic         io_in_info_ta,
  input  logic         io_in_info_ma,
  input  logic [7:0]   io_in_info_vl,
  input  logic [7:0]   io_in_info_vstart,
  input  logic [1:0]   io_in_info_eew,
  input  logic [2:0]   io_in_info_vdIdx,
  input  logic         io_in_info_narrow,
  input  logic         io_in_info_dstMask,
  output logic [127:0] io_out_vd,
  output logic [15:0]  io_out_active
);
  xs_Mgu_core u_core (
    .new_vd     (io_in_vd),
    .old_vd     (io_in_oldVd),
    .mask       (io_in_mask),
    .ta         (io_in_info_ta),
    .ma         (io_in_info_ma),
    .vl         (io_in_info_vl),
    .vstart     (io_in_info_vstart),
    .eew        (io_in_info_eew),
    .vd_idx_in  (io_in_info_vdIdx),
    .narrow     (io_in_info_narrow),
    .dst_mask   (io_in_info_dstMask),
    .out_vd     (io_out_vd),
    .out_active (io_out_active)
  );
endmodule
