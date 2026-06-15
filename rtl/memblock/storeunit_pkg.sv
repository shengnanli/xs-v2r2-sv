// =============================================================================
//  storeunit_pkg —— StoreUnit（store 地址流水单元）可读重写用的类型/常量/纯函数
// -----------------------------------------------------------------------------
//  设计意图来源（人写 Chisel 源，非 firtool golden）：
//      src/main/scala/xiangshan/mem/pipeline/StoreUnit.scala
//
//  StoreUnit 是标量/向量 store 的「地址流水线」（不搬运 store 数据，数据走 sq）。
//  它把一条 store 从发射拆成 5 级：
//      s0  三源固定优先级仲裁 + 生成虚地址 saddr + 字节 mask + 对齐/跨16B/cbo 判定，
//          并向 DTLB / DCache(读 meta 探命中) 发请求；
//      s1  收 TLB paddr/异常 + MemTrigger 断点匹配 + 写 StoreQueue 地址(io_lsq)
//          + st→ld nuke 查询 + misalignBuffer 入队；
//      s2  PMP/PMA + 异常合并 + uncache(mmio/nc) 判定 + lsq_replenish；
//      s3  打一拍 + 计算 vstart；
//      sx  写回（标量→ROB io_stout / 向量→mergeBuffer io_vecstout）。
//
//  ── 本工程当前 KunmingHu V2R2 配置的两个关键裁剪（golden 已固化，须对齐）──
//   (1) EnableStorePrefetchSMS = false：硬件预取源在本配置下完全失效，故
//       s0_valid 只由 {标量发射 stin, 向量发射 vecstin, misalign 重发} 三源驱动；
//       prefetch_train / s1_s2_prefetch_spec / io.issue 等端口被裁剪。
//   (2) 下游 issue-queue/RS 在本顶层例化里恒 ready，故 s1/s2/s3 各级 ready 退化为
//       常量 1（流水不会因下游 back-pressure 而 stall），RAWTotalDelayCycles = 1
//       （即 s3 之后只有一级 sx 延迟寄存器 sx[1]）。
//   本包/核显式用 localparam 表达这两点，便于阅读者理解“为什么端口少了一截”。
// =============================================================================
package storeunit_pkg;

  // ---- 关键位宽（与香山 KunmingHu V2R2 配置一致）-----------------------------
  localparam int VADDR_BITS = 50;  // 虚地址位宽（VAddrBits）
  localparam int PADDR_BITS = 48;  // 物理地址位宽
  localparam int XLEN       = 64;  // 标量寄存器/fullva 位宽
  localparam int VLEN       = 128; // 向量寄存器位宽
  localparam int MASK_BITS  = 16;  // 字节 mask = VLEN/8
  localparam int ROB_W      = 8;   // robIdx.value 位宽
  localparam int SQ_W       = 6;   // sqIdx.value 位宽

  // ---- 本配置裁剪开关（见文件头说明）-----------------------------------------
  localparam bit ENABLE_STORE_PREFETCH = 1'b0; // EnableStorePrefetchSMS
  localparam int RAW_DELAY_CYCLES      = 1;     // RAWTotalDelayCycles

  // ---- store 单元关心的异常向量编号（ExceptionNO）----------------------------
  //   3  breakPoint（trigger 产生）
  //   6  storeAddrMisaligned
  //   7  storeAccessFault
  //   15 storePageFault
  //   19 (load/store) hardware-error 占位（本单元仅透传 misalign 来的 19）
  //   23 storeGuestPageFault
  localparam int EXC_BP   = 3;
  localparam int EXC_SAM  = 6;
  localparam int EXC_SAF  = 7;
  localparam int EXC_SPF  = 15;
  localparam int EXC_SGPF = 23;

  // ---- 对齐/size 类型（alignType = fuOpType[1:0] 或 vec alignedType[1:0]）-----
  typedef enum logic [1:0] {
    SZ_BYTE  = 2'h0,   // b
    SZ_HALF  = 2'h1,   // h
    SZ_WORD  = 2'h2,   // w
    SZ_DWORD = 2'h3    // d
  } align_e;

  // ---- s0 数据来源：固定优先级 misalign > 标量发射 > 向量发射（> prefetch）----
  //   prefetch 在本配置失效（见文件头）；保留枚举项以表达设计全貌。
  //   优先级独热由 valid 串行屏蔽实现：
  //     use_ma  = misalign.valid
  //     use_rs  = stin.valid    & ~vec & ~ma
  //     use_vec = vecstin.valid & ~ma
  //     use_prf = prefetch.valid & ~rs & ~vec & ~ma   （本配置恒 0）
  typedef enum logic [1:0] {
    SRC_MISALIGN = 2'd0,  // io_misalign_stin —— misalignBuffer 拆分重发（最高优先级）
    SRC_SCALAR   = 2'd1,  // io_stin          —— 标量发射（自算 saddr）
    SRC_VECTOR   = 2'd2,  // io_vecstin       —— 向量发射
    SRC_PREFETCH = 2'd3   // io_prefetch_req  —— 硬件预取（本配置失效）
  } st_src_e;

  // ---- pbmt（page-based memory type）编码 -----------------------------------
  localparam logic [1:0] PBMT_NONE = 2'h0; // 走 PMA，再看 PMP.mmio
  localparam logic [1:0] PBMT_NC   = 2'h1; // non-cacheable
  localparam logic [1:0] PBMT_IO   = 2'h2; // strong-order IO（mmio）

  // ---- TLB 命令 / st→ld nuke matchType -------------------------------------
  localparam logic [2:0] TLB_READ  = 3'h0; // cbo（非 zero）用读权限
  localparam logic [2:0] TLB_WRITE = 3'h1; // 普通 store 用写权限
  localparam logic [1:0] NUKE_NORMAL    = 2'h0;
  localparam logic [1:0] NUKE_QUADWORD  = 2'h1; // 128bit
  localparam logic [1:0] NUKE_CACHELINE = 2'h2; // cbo

  // ---- trigger action（与 TriggerAction 一致）-------------------------------
  //   0 = None；1 = DebugMode（进 debug）；F(=4'hF) = BreakpointExp（断点异常）。
  localparam logic [3:0] TRIG_NONE  = 4'h0;
  localparam logic [3:0] TRIG_DMODE = 4'h1;

  // ===========================================================================
  //  指针类型：robIdx/sqIdx/ftqPtr 用 {flag, value} struct 表达环形指针
  // ===========================================================================
  typedef struct packed {
    logic              flag;            // 环形 wrap 标志
    logic [ROB_W-1:0]  value;
  } rob_ptr_t;

  typedef struct packed {
    logic              flag;
    logic [SQ_W-1:0]   value;
  } sq_ptr_t;

  // ===========================================================================
  //  纯函数区
  // ===========================================================================

  // ---- 环形 RobIdx 冲刷判定（uop.robIdx.needFlush(redirect)）----------------
  //   level=1（异常型冲刷）：冲刷与 redirect 同一条（含自己）；
  //   分支误预测型：冲刷排在 redirect 之后（更年轻）的所有条。
  function automatic logic rob_need_flush(
      input logic     redir_valid,
      input logic     redir_level,
      input rob_ptr_t self,
      input rob_ptr_t redir);
    logic flush_itself, flush_after;
    flush_itself = redir_level & (self.flag == redir.flag) & (self.value == redir.value);
    flush_after  = self.flag ^ redir.flag ^ (self.value > redir.value);
    return redir_valid & (flush_itself | flush_after);
  endfunction

  // ---- 标量地址生成：saddr = src0[VADDR-1:0] + sext(imm12) ------------------
  function automatic logic [VADDR_BITS-1:0] gen_saddr(
      input logic [63:0] src0, input logic [11:0] imm12);
    return VADDR_BITS'(src0[VADDR_BITS-1:0] + {{(VADDR_BITS-12){imm12[11]}}, imm12});
  endfunction

  // ---- fullva（用于跨页/越界检查的完整 64 位地址）= src0 + sext64(imm12) ----
  function automatic logic [XLEN-1:0] gen_fullva_scalar(
      input logic [63:0] src0, input logic [11:0] imm12);
    return XLEN'(src0 + {{(XLEN-12){imm12[11]}}, imm12});
  endfunction

  // ---- 对齐判定：byte 恒对齐；half 看 bit0；word 看[1:0]；dword 看[2:0]------
  function automatic logic addr_aligned(input align_e sz, input logic [VADDR_BITS-1:0] va);
    unique case (sz)
      SZ_BYTE:  return 1'b1;
      SZ_HALF:  return (va[0]   == 1'b0);
      SZ_WORD:  return (va[1:0] == 2'h0);
      SZ_DWORD: return (va[2:0] == 3'h0);
      default:  return 1'b1;
    endcase
  endfunction

  // ---- 跨 16Byte 判定：访问末字节是否落到与首字节不同的 16B 块 --------------
  //   up_low = addr_low + (size-1)；比较两者 bit[4]（16B 块号）。
  function automatic logic cross16(input align_e sz, input logic [VADDR_BITS-1:0] va);
    logic [4:0] addr_low, span, up_low;
    addr_low = va[4:0];
    unique case (sz)
      SZ_BYTE:  span = 5'd0;
      SZ_HALF:  span = 5'd1;
      SZ_WORD:  span = 5'd3;
      SZ_DWORD: span = 5'd7;
      default:  span = 5'd0;
    endcase
    up_low = 5'(addr_low + span);
    return up_low[4] != addr_low[4];
  endfunction

  // ---- cbo 判定（与 LSUOpType.isCboAll / isCbo 一致）-----------------------
  //   isCboAll：fuOpType[3:2]==2'b11 且 fuOpType[6:4]==0（clean/flush/inval/zero）
  //             或 fuOpType[3:0]==4'h7（zero 的别名编码）。
  //   isCbo   ：isCboAll 去掉 zero —— 即仅 [3:2]==11 && [6:4]==0 那支。
  function automatic logic is_cbo_all(input logic [8:0] fuOpType);
    return ((&fuOpType[3:2]) & ~(|fuOpType[6:4])) | (fuOpType[3:0] == 4'h7);
  endfunction
  function automatic logic is_cbo_nozero(input logic [8:0] fuOpType);
    return (&fuOpType[3:2]) & (fuOpType[6:4] == 3'h0);
  endfunction
  // hyperinst（HSV store）：fuOpType[4] & ~[5] & [8:7]==0
  function automatic logic is_hsv(input logic [8:0] fuOpType);
    return fuOpType[4] & ~fuOpType[5] & (fuOpType[8:7] == 2'h0);
  endfunction

  // ---- 字节 mask：按 size 生成 1/2/4/8 字节连续 mask 后左移到 va[3:0] -------
  //   （genVWmask128：基址取 saddr 低 4 位作字节偏移）。
  function automatic logic [MASK_BITS-1:0] gen_vwmask(
      input logic [VADDR_BITS-1:0] base_va, input logic [2:0] size3);
    logic [MASK_BITS-1:0] base;
    // 注：与 golden genVWmask128 的 LookupTree 一致——只有 size∈{0,1,2,3,4,7}
    //     有定义；size∈{5,6} 落空，基 mask 为 0（fuOpType 低 3 位不会编出 5/6 的
    //     合法 store，但组合逻辑须与 golden 逐位等价）。
    unique case (size3)
      3'h0:    base = 16'h0001;          // b
      3'h1:    base = 16'h0003;          // h
      3'h2:    base = 16'h000F;          // w
      3'h3:    base = 16'h00FF;          // d
      3'h4:    base = 16'hFFFF;          // q（128bit）
      3'h7:    base = 16'hFFFF;          // (&size3) 分支
      default: base = 16'h0000;          // size 5/6：无定义 → 0
    endcase
    return MASK_BITS'(base << base_va[3:0]);
  endfunction

  // ---- 跨 16B 错位 store 的 base-aligned mask（genBasemask）-----------------
  //   跨 16B 且不对齐时，sq 需要一个“按 size 长度的对齐基 mask”再做移位拆分。
  function automatic logic [MASK_BITS-1:0] gen_basemask(input align_e sz);
    unique case (sz)
      SZ_BYTE:  return 16'h0001;
      SZ_HALF:  return 16'h0003;
      SZ_WORD:  return 16'h000F;
      SZ_DWORD: return 16'h00FF;
      default:  return 16'h0001;
    endcase
  endfunction

  // ---- genVFirstUnmask：mask 中最低有效字节的索引（向量 trigger vaddr 偏移）-
  function automatic logic [3:0] first_unmask(input logic [MASK_BITS-1:0] mask);
    for (int i = 0; i < MASK_BITS; i++)
      if (mask[i]) return 4'(i);
    return 4'h0;
  endfunction

endpackage
