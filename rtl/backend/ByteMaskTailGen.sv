// =============================================================================
// ByteMaskTailGen.sv —— 向量寄存器一次写回里，哪些字节「真写」、哪些字节「写全 1」
//
// 在哪一层：向量 load 合并单元 VldMergeUnit → VldMgu（按字节拼新旧 vd）→ 本件。
//   一条向量 load 的一个 uop 只写一个 128 位 vd（16 字节）。RVV 语义把每个字节归入
//   三段之一，再按 mask 细分：
//     prestart  元素号 <  vstart          保持旧值
//     body      vstart <= 元素号 < vl     mask 位为 1 → 真写（active）
//                                          mask 位为 0 → vma=1 时写全 1（agnostic），否则保持旧值
//     tail      元素号 >= vl              vta=1 时写全 1（agnostic），否则保持旧值
//   本件输出两张 16 位字节使能：activeEn（取新数据）、agnosticEn（写 0xFF）；
//   两者都为 0 的字节保持旧值（由上层 VldMgu 选择）。
//
// 做法（与 Scala fu/vector/ByteMaskTailGen.scala 逐句对应）：
//   1. 元素号 → 字节号：startBytes = vstart << vsew，vlBytes = vl << vsew（截 8 位）。
//   2. 在整组寄存器（最多 8 个 vd × 16 字节 = 128 字节）上用温度计码画出三段：
//        prestart = [0, startBytes)            = UIntToContLow1s(startBytes)
//        body     = [startBytes, vlBytes)      = UIntToContLow0s(startBytes) & UIntToContLow1s(vlBytes)
//        tail     = [vlBytes, ...)             = UIntToContLow0s(vlBytes)
//      再按 vdIdx（本 uop 是组里第几个 vd）切出本 vd 的 16 字节。
//   3. mask 按元素宽度展成字节掩码（MaskExtractor）。
//   4. vstart >= vl 时整条指令什么都不写：两张使能强制全 0。
//
// ★prestart 段只算不用★：Scala 为调试（dontTouch）把 prestartEnInVd 保留成 golden 里的
//   一根内部线，但没有任何输出读它；本件不画这一段（非比较点，不影响等价）。
//   golden 因此多出一个 UIntToContLow1s 实例（prestartEn_*），其输出无读者。
//
// 子模块：MaskExtractor（已签，rtl/backend/MaskExtractor.sv）、UIntToContLow0s ×2、
//   UIntToContLow1s ×1（本 lane 重写，同名白盒）。
// golden 对照：G1-canonical/golden-rtl/ByteMaskTailGen.sv
// =============================================================================
module xs_ByteMaskTailGen_core (
  input  logic [7:0]  vstart,       // 起始元素号（Scala io.in.begin）
  input  logic [7:0]  vl,           // 结束元素号（不含，Scala io.in.end）
  input  logic        vma,          // mask agnostic
  input  logic        vta,          // tail agnostic
  input  logic [1:0]  vsew,         // 元素宽度：0/1/2/3 = 1/2/4/8 字节
  input  logic [15:0] mask_used,    // 本 vd 对应的那 16 个元素 mask 位
  input  logic [2:0]  vd_idx,       // 本 uop 写的是寄存器组里第几个 vd
  output logic [15:0] active_en,    // 字节取新数据
  output logic [15:0] agnostic_en   // 字节写全 1
);
  localparam int VD_BYTES = 16;     // 一个 vd 的字节数（VLEN=128）

  // ---- 1. 元素号 → 字节号 ------------------------------------------------------
  logic [7:0] start_bytes, vl_bytes;
  assign start_bytes = 8'(vstart << vsew);
  assign vl_bytes    = 8'(vl << vsew);

  // ---- 2. 在整组 128 字节上画 body / tail，再切出本 vd ---------------------------
  logic [254:0] at_or_after_start;   // 字节号 >= startBytes
  logic [254:0] before_vl;           // 字节号 <  vlBytes
  logic [254:0] at_or_after_vl;      // 字节号 >= vlBytes

  UIntToContLow0s u_body_lo (.io_dataIn(start_bytes), .io_dataOut(at_or_after_start));
  UIntToContLow1s u_body_hi (.io_dataIn(vl_bytes),    .io_dataOut(before_vl));
  UIntToContLow0s u_tail    (.io_dataIn(vl_bytes),    .io_dataOut(at_or_after_vl));

  logic [127:0]          body_group, tail_group;
  logic [VD_BYTES-1:0]   body_in_vd, tail_in_vd;
  assign body_group = at_or_after_start[127:0] & before_vl[127:0];
  assign tail_group = at_or_after_vl[127:0];
  assign body_in_vd = body_group[vd_idx * VD_BYTES +: VD_BYTES];
  assign tail_in_vd = tail_group[vd_idx * VD_BYTES +: VD_BYTES];

  // ---- 3. mask 展成字节掩码 ------------------------------------------------------
  logic [VD_BYTES-1:0] mask_en;
  MaskExtractor u_mask (
    .io_in_mask  (mask_used),
    .io_in_vsew  (vsew),
    .io_out_mask (mask_en)
  );

  // ---- 4. 合成两张使能；vstart >= vl 时什么都不写 --------------------------------
  logic                empty_range;
  logic [VD_BYTES-1:0] mask_agnostic, tail_agnostic;
  assign empty_range   = (vstart >= vl);
  assign mask_agnostic = (vma ? ~mask_en : '0) & body_in_vd;
  assign tail_agnostic = vta ? tail_in_vd : '0;
  assign active_en     = empty_range ? '0 : (body_in_vd & mask_en);
  assign agnostic_en   = empty_range ? '0 : (mask_agnostic | tail_agnostic);
endmodule

module ByteMaskTailGen (
  input  [7:0]  io_in_begin,
  input  [7:0]  io_in_end,
  input         io_in_vma,
  input         io_in_vta,
  input  [1:0]  io_in_vsew,
  input  [15:0] io_in_maskUsed,
  input  [2:0]  io_in_vdIdx,
  output [15:0] io_out_activeEn,
  output [15:0] io_out_agnosticEn
);
  xs_ByteMaskTailGen_core u_core (
    .vstart      (io_in_begin),
    .vl          (io_in_end),
    .vma         (io_in_vma),
    .vta         (io_in_vta),
    .vsew        (io_in_vsew),
    .mask_used   (io_in_maskUsed),
    .vd_idx      (io_in_vdIdx),
    .active_en   (io_out_activeEn),
    .agnostic_en (io_out_agnosticEn)
  );
endmodule
