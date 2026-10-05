// sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt.sv —— L2 预取 RecentRequestTable 的 SRAM 宏接口层
//
// 名字解码（香山 SRAM 宏命名规则）：1p = 单口，256x13 = 256 项 × 13 位，m13 = 13 位一组掩码粒度
// （本宏不带掩码端口），s1 = 1 个子阵列，h0/l1b = 无高位拆分、1 个 bank；l2_pftch_rrt = 用途
// （L2 prefetch recent-request table）。
//
// 结构位置：SRAMTemplate_146 → **本模块** → array_13 → array_13_ext（厂商叶子）
//
// 唯一的逻辑：写模式只在访问使能有效时才成立 —— 送给下一层的 wmode = RW0_wmode & RW0_en。
// 于是"en=0 时 wmode 随便是什么"都不会被下一层当成写；en=1 时与上层给的读/写意图一致。
// 两个 MBIST/DFT 旁路输入（mbist_dft_ram_bypass / mbist_dft_ram_bp_clken）在 golden 里就没有
// 接到任何地方，这里同样只声明不使用（bug-for-bug，端口集合与 golden 完全一致）。
//
// codex 0219 §2：final RTL 不再依赖 golden 的这层包装文件，impl 侧读本文件，ref 侧仍读 G1；
// FM 两侧都只把精确的 array_13_ext 当 vendor 边界，本层的 wmode & en 逻辑正式受比较。

module sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt (
  input  logic        mbist_dft_ram_bypass,   // DFT 旁路（golden 未使用）
  input  logic        mbist_dft_ram_bp_clken, // DFT 旁路时钟使能（golden 未使用）
  input  logic        RW0_clk,
  input  logic [7:0]  RW0_addr,
  input  logic        RW0_en,
  input  logic        RW0_wmode,
  input  logic [12:0] RW0_wdata,
  output logic [12:0] RW0_rdata
);

  // 写只在使能有效的拍成立
  logic write_this_cycle;
  assign write_this_cycle = RW0_wmode & RW0_en;

  array_13 array (
    .RW0_addr  (RW0_addr),
    .RW0_en    (RW0_en),
    .RW0_clk   (RW0_clk),
    .RW0_wmode (write_this_cycle),
    .RW0_wdata (RW0_wdata),
    .RW0_rdata (RW0_rdata)
  );

endmodule
