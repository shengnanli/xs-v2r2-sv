// SplittedSRAM_ptw_core.sv —— PtwCache（L2 TLB 页表缓存）两级 SRAM 阵列的共享参数化核。
//
// 位置：xiangshan.cache.mmu.PageTableCache 里的 l1 / l0 两个 coupledL2.utils.SplittedSRAM，
//       firtool 单态化成 golden 的 SplittedSRAM_1（l1，非叶 PTE）与 SplittedSRAM_2（l0，叶 PTE）。
//       这一层**不含任何寄存器**：它只做「一条 PtwEntries 打包成位向量 → 按 way / data 两个
//       维度切成若干块 → 交给内层 SRAMTemplate → 读回再拼回 struct」。真正的存储与时序
//       （地址寄存、读延迟、MBIST bore）都在内层 SRAMTemplate 及其下的厂商 SRAM 宏里。
//
// 为什么能一个核吃下两个变体：两级用的是**同一个** PtwEntries bundle 模板
//   （MMUBundle.scala:989 class PtwEntries(num, tagLen, level, hasPerm, ReservedBits)），
//   只是 tagLen / hasPerm / ReservedBits / set / way / waySplit / dataSplit 取值不同。
//   Chisel 的 `asUInt` 按字段声明顺序从低位往高位铺，于是打包偏移可以由参数算出来
//   （见下面 OFF_* 一串 localparam）。实测：把 golden 两个模块的写拼接与读位选
//   全部逐位重算，5184 个 bit-assignment 与本公式 0 处不符。
//
// 切分语义照搬 coupledL2/src/main/scala/coupledL2/utils/SplittedSRAM.scala：
//   - waySplit  把 way 均分成 WAY_SPLIT 组，每组 WAY_PER 路共用一块 SRAM；
//     第 g 组拿 waymask[WAY_PER*(g+1)-1 : WAY_PER*g]。
//   - dataSplit 把一条 entry 的 ENTRY_W 位均分成 DATA_SPLIT 段，第 k 段是低位起第 k 块。
//   - setSplit 本工程两个变体都是 1，因此 Chisel 里的 bank 选择 / ren_vec 寄存器
//     被 firtool 常量折叠掉了——golden 两个模块里一个寄存器都没有，这里也不能加。
//   阵列编号 n = g*DATA_SPLIT + k，与 golden 实例名 array_0_<g>_<k>、
//   以及 boreChildrenBd_bore_<n> / sigFromSrams_bore_<n> 的编号一一对应。

module xs_SplittedSRAM_ptw_core #(
  parameter int  NUM        = 8,      // 一条 entry 里的扇区条目数（PtwEntries.num）
  parameter int  TAG_W      = 24,     // PtwEntries.tag 宽（l1=24, l0=29）
  parameter int  ASID_W     = 16,
  parameter int  VMID_W     = 14,
  parameter int  PBMT_W     = 2,
  parameter int  PPN_W      = 38,     // gvpnLen
  parameter int  PERM_W     = 7,      // PtePermBundle：{d,a,g,u,x,w,r}，r 在最低位
  parameter bit  HAS_PERM   = 1'b0,   // 叶子级（l0）才带 perms
  parameter int  RSVD_W     = 2,      // PtwEntries.reservedBits 宽（l1=2, l0=4）
  parameter int  WAY        = 2,
  parameter int  WAY_SPLIT  = 1,
  parameter int  DATA_SPLIT = 1,
  // ---- 以下为派生参数，由上面的形参算出，**例化时不要传**（写在参数表里只是
  //      为了让端口宽度能直接引用它们；SV 允许参数默认值引用前面的参数）----
  parameter int  PERMS_W    = HAS_PERM ? NUM*PERM_W : 0,
  parameter int  ENTRY_W    = TAG_W + ASID_W + VMID_W + NUM*PBMT_W + NUM*PPN_W
                              + NUM /*vs*/ + NUM /*onlypf*/ + PERMS_W + 1 /*prefetch*/
                              + RSVD_W,
  parameter int  WAY_PER    = WAY / WAY_SPLIT,          // 每块 SRAM 承载的路数
  parameter int  SLICE_W    = ENTRY_W / DATA_SPLIT,     // 每块 SRAM 的数据位宽
  parameter int  NARR       = WAY_SPLIT * DATA_SPLIT    // SRAM 块总数
) (
  // ---- 写侧：每路一条 PtwEntries（Vec 字段已在位向量里按下标从低到高排列）----
  input  logic [WAY-1:0][TAG_W-1:0]         w_tag,
  input  logic [WAY-1:0][ASID_W-1:0]        w_asid,
  input  logic [WAY-1:0][VMID_W-1:0]        w_vmid,
  input  logic [WAY-1:0][NUM*PBMT_W-1:0]    w_pbmts,
  input  logic [WAY-1:0][NUM*PPN_W-1:0]     w_ppns,
  input  logic [WAY-1:0][NUM-1:0]           w_vs,
  input  logic [WAY-1:0][NUM-1:0]           w_onlypf,
  input  logic [WAY-1:0][NUM*PERM_W-1:0]    w_perms,   // HAS_PERM=0 时本口不进布局
  input  logic [WAY-1:0]                    w_prefetch,
  input  logic [WAY-1:0]                    w_waymask,
  // ---- 读侧：同样每路一条 ----
  output logic [WAY-1:0][TAG_W-1:0]         r_tag,
  output logic [WAY-1:0][ASID_W-1:0]        r_asid,
  output logic [WAY-1:0][VMID_W-1:0]        r_vmid,
  output logic [WAY-1:0][NUM*PBMT_W-1:0]    r_pbmts,
  output logic [WAY-1:0][NUM*PPN_W-1:0]     r_ppns,
  output logic [WAY-1:0][NUM-1:0]           r_vs,
  output logic [WAY-1:0][NUM-1:0]           r_onlypf,
  output logic [WAY-1:0][NUM*PERM_W-1:0]    r_perms,
  output logic [WAY-1:0]                    r_prefetch,
  // ---- 阵列侧：n = g*DATA_SPLIT + k ----
  output logic [NARR-1:0][WAY_PER-1:0]              arr_waymask,
  output logic [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_wdata,
  input  logic [NARR-1:0][WAY_PER-1:0][SLICE_W-1:0] arr_rdata
);

  // ---- 打包偏移：Chisel asUInt 从**最后声明**的字段占最低位开始往上铺 ----
  // PtwEntries 字段声明序为 tag, asid, vmid, pbmts, ppns, vs, onlypf, perms?, prefetch,
  // reservedBits?，故位向量自低到高正好是倒序。
  localparam int OFF_RSVD     = 0;
  localparam int OFF_PREFETCH = OFF_RSVD     + RSVD_W;
  localparam int OFF_PERMS    = OFF_PREFETCH + 1;
  localparam int OFF_ONLYPF   = OFF_PERMS    + PERMS_W;
  localparam int OFF_VS       = OFF_ONLYPF   + NUM;
  localparam int OFF_PPNS     = OFF_VS       + NUM;
  localparam int OFF_PBMTS    = OFF_PPNS     + NUM*PPN_W;
  localparam int OFF_VMID     = OFF_PBMTS    + NUM*PBMT_W;
  localparam int OFF_ASID     = OFF_VMID     + VMID_W;
  localparam int OFF_TAG      = OFF_ASID     + ASID_W;
  // 注：OFF_TAG + TAG_W 必然等于参数表里派生的 ENTRY_W（两者是同一串加法的两种写法）。
  // 不在这里放 elaboration $error —— FM 的 read_sverilog 对 generate 内的
  // elaboration 系统任务不稳定；这条自洽性由 UT 的「逐位走 1」用例覆盖。

  logic [WAY-1:0][ENTRY_W-1:0] w_entry;  // 打包后待写的整条 entry
  logic [WAY-1:0][ENTRY_W-1:0] r_entry;  // 由各块读回拼起来的整条 entry

  genvar wy, g, k, ww;

  // ---- 打包 / 解包（每路各一份，不共用中间量）----
  generate
    for (wy = 0; wy < WAY; wy++) begin : g_entry
      // reservedBits：Chisel 写 `reservedBits.map(_ := true.B)`，Bool 赋给多位 UInt
      // 是零扩展，所以恒为整数 1（golden 里就是 2'h1 / 4'h1）。读侧无人取用。
      assign w_entry[wy][OFF_RSVD     +: RSVD_W]      = {{(RSVD_W-1){1'b0}}, 1'b1};
      assign w_entry[wy][OFF_PREFETCH]                = w_prefetch[wy];
      assign w_entry[wy][OFF_ONLYPF   +: NUM]         = w_onlypf[wy];
      assign w_entry[wy][OFF_VS       +: NUM]         = w_vs[wy];
      assign w_entry[wy][OFF_PPNS     +: NUM*PPN_W]   = w_ppns[wy];
      assign w_entry[wy][OFF_PBMTS    +: NUM*PBMT_W]  = w_pbmts[wy];
      assign w_entry[wy][OFF_VMID     +: VMID_W]      = w_vmid[wy];
      assign w_entry[wy][OFF_ASID     +: ASID_W]      = w_asid[wy];
      assign w_entry[wy][OFF_TAG      +: TAG_W]       = w_tag[wy];

      assign r_prefetch[wy]  = r_entry[wy][OFF_PREFETCH];
      assign r_onlypf[wy]    = r_entry[wy][OFF_ONLYPF   +: NUM];
      assign r_vs[wy]        = r_entry[wy][OFF_VS       +: NUM];
      assign r_ppns[wy]      = r_entry[wy][OFF_PPNS     +: NUM*PPN_W];
      assign r_pbmts[wy]     = r_entry[wy][OFF_PBMTS    +: NUM*PBMT_W];
      assign r_vmid[wy]      = r_entry[wy][OFF_VMID     +: VMID_W];
      assign r_asid[wy]      = r_entry[wy][OFF_ASID     +: ASID_W];
      assign r_tag[wy]       = r_entry[wy][OFF_TAG      +: TAG_W];

      if (HAS_PERM) begin : g_perm
        assign w_entry[wy][OFF_PERMS +: NUM*PERM_W] = w_perms[wy];
        assign r_perms[wy] = r_entry[wy][OFF_PERMS +: NUM*PERM_W];
      end else begin : g_no_perm
        // 非叶子级（l1）没有 perms 字段：写侧这段位置根本不存在，读侧恒 0。
        assign r_perms[wy] = '0;
      end
    end
  endgenerate

  // ---- 切分 / 归并：way 维 × data 维，编号 n = g*DATA_SPLIT + k ----
  generate
    for (g = 0; g < WAY_SPLIT; g++) begin : g_wsplit
      for (k = 0; k < DATA_SPLIT; k++) begin : g_dsplit
        for (ww = 0; ww < WAY_PER; ww++) begin : g_way
          localparam int N  = g*DATA_SPLIT + k;
          localparam int WY = g*WAY_PER + ww;
          assign arr_waymask[N][ww] = w_waymask[WY];
          assign arr_wdata[N][ww]   = w_entry[WY][k*SLICE_W +: SLICE_W];
          assign r_entry[WY][k*SLICE_W +: SLICE_W] = arr_rdata[N][ww];
        end
      end
    end
  endgenerate

endmodule
