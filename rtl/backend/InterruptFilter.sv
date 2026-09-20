// =============================================================================
// InterruptFilter.sv —— RISC-V AIA 中断优先级过滤器（NewCSR 的中断裁决单元）
//
// 位置：后端 CSR 单元 NewCSR 内部。上游把 M/HS/VS 三级的中断挂起(xip)、使能(xie)、
//   委托(xideleg) 位向量、AIA 的 iprio 优先级数组、hvictl 虚拟中断注入寄存器、
//   debug/NMI 状态送进来；本模块选出**当前特权态下该取的那一个中断**，产出
//   mtopi/stopi/vstopi 三个只读 CSR 的值，以及送给 Rob 的 8 位中断向量 + 若干标志。
//
// 核心机制（RISC-V 特权规范 + AIA 扩展）：
//   1) gather：某一级"可取"的中断集合 = 挂起 & 使能 & 未委托给更低特权级。
//   2) 默认优先级：规范把本实现支持的 61 个中断号排成一张固定顺序表
//      （IRQ_AT_SLOT），槽位号越小优先级越高；SEI(9) 所在的槽位是比较基准。
//   3) 可编程优先级：AIA 给每个中断一个 8 位 iprio 数值，**数值小者优先**；
//      数值 0 表示"回退到默认优先级"；外部中断(EI) 的 iprio 来自 xtopei，
//      可能超过 255（greaterThan255），那种情况一律排在最后。
//   4) 裁决 = 在 61 个候选里做一次最小值规约（Chisel 的 minSelect 二叉树）。
//      为了切时序，香山把它拆成两拍：先 8 组组内选优 -> 打一拍 -> 组间再选一次。
//   5) VS 级另有 hvictl 虚拟中断注入通路：C1..C5 五个候选，两两组合决定 vstopi。
//   6) 结果再打 1+5 拍送出（注释原话：保证 sret/mret 的原子性）。
//
// golden（firtool 产物）13141 行里约 11000 行是把第 4 步那棵树完全展平的结果：
//   3 族 × (8 组 × 7 + 7) = 189 个两路比较节点，每个节点展平成约 60 行。
//   这里用一个 iprios_min2 函数 + 一次规约把它讲回原形。行数大 ≠ 逻辑大。
//
// 与 golden 逐位等价（bug-for-bug）。几处"看着像 bug、但必须照抄"的点都就地标了★。
// =============================================================================
// 本文件导航（共 1648 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L49    interrupt_filter_pkg —— 本模块私有的优先级表与比较规约
//   L74    一个候选中断在排序网络里的全部信息
//   L85    默认优先级表：槽位 -> 中断号
//   L133   两路比较：在两个候选里挑"优先级更高"的那个
//   L169   8 路规约：平衡二叉树，形状与 Chisel 的递归完全一致
//   L188   hviprio 字节查表：VS 级的可编程优先级只对一部分中断号存在
//   L217   xs_InterruptFilter_core —— 可读核
//   L295   §1】gather：每一级"现在可以取"的中断集合
//   L318   §2】外部中断(EI) 的特殊来源
//   L334   §3】把 61 个中断号摆成排序网络的输入条目
//   L408   §4】第一级规约：每组 8 条目里选一个
//   L421   §5】流水寄存器
//   L521   §6】mtopi / stopi 输出
//   L559   §7】VS 级的五个候选
//   L598   §8】VS 级各组合的 (IID, IPRIO)
//   L736   §9】按当前特权态决定"往哪一级投递"，并合成 8 位中断向量
//   L842   §10】输出寄存器
//   L900   §11】再延迟 5 拍送出
//

// -----------------------------------------------------------------------------
// interrupt_filter_pkg —— 本模块私有的优先级表与比较规约
// -----------------------------------------------------------------------------
package interrupt_filter_pkg;

  // 本实现支持的中断号个数（= Chisel 的 InterruptNO.interruptDefaultPrio.size）。
  // 注意不是 64：规范里 64 个中断号有 3 个本实现没排进优先级表。
  localparam int unsigned PRIO_SLOTS = 61;
  // 规约树按 8 组 × 8 条目做，末组用全零条目补齐到 64（Chisel: sliceIpriosSort）。
  localparam int unsigned PADDED_SLOTS = 64;
  localparam int unsigned GROUPS       = 8;

  // 中断号常量（RISC-V 特权规范 / AIA）
  localparam logic [5:0] IRQ_SSI  = 6'd1;    // supervisor software
  localparam logic [5:0] IRQ_STI  = 6'd5;    // supervisor timer
  localparam logic [5:0] IRQ_SEI  = 6'd9;    // supervisor external
  localparam logic [5:0] IRQ_MEI  = 6'd11;   // machine external

  // 外部中断在默认优先级表里的槽位（Chisel: getPrioIdxInGroup(_.MEI/_.SEI)）。
  // M 级用 MEI 的槽位当基准，HS/VS 级用 SEI 的槽位。两者同在第 3 组（24/8 = 27/8 = 3），
  // 这一点决定了下面"只有第 3 组需要 greaterThan255 寄存器"。
  localparam logic [5:0] MEI_SLOT = 6'd24;
  localparam logic [5:0] SEI_SLOT = 6'd27;
  localparam int unsigned EI_GROUP = 3;

  // ---------------------------------------------------------------------------
  // 一个候选中断在排序网络里的全部信息（Chisel: class IpriosSort）
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [5:0] idx;             // 它在默认优先级表里的槽位号（小 = 默认优先级高）
    logic       enable;          // 这一级真的能取它吗（挂起 & 使能 & 未委托）
    logic       isZero;          // 它的 iprio 数值是 0 —— 即"回退到默认优先级"
    logic       greaterThan255;  // 它的 iprio 数值 > 255（只可能来自 xtopei）
    logic [7:0] prioNum;         // iprio 数值本身（小者优先）
  } iprios_sort_t;

  // ---------------------------------------------------------------------------
  // 默认优先级表：槽位 -> 中断号（Chisel: InterruptNO.interruptDefaultPrio）
  // 顺序来自规范 + 香山自定义局部中断的分组，从高优先级到低优先级依次是：
  //   customHighest -> localHigh -> customMiddleHigh -> privArch
  //   -> customMiddleLow -> localLow -> customLowest
  // ---------------------------------------------------------------------------
  function automatic logic [5:0] irq_at_slot(input logic [5:0] slot);
    case (slot)
      // customHighestGroup
      0:  irq_at_slot = 6'd63;   1:  irq_at_slot = 6'd31;   2:  irq_at_slot = 6'd62;
      3:  irq_at_slot = 6'd61;   4:  irq_at_slot = 6'd30;   5:  irq_at_slot = 6'd60;
      // localHighGroup
      6:  irq_at_slot = 6'd47;   7:  irq_at_slot = 6'd23;   8:  irq_at_slot = 6'd46;
      9:  irq_at_slot = 6'd45;   10: irq_at_slot = 6'd22;   11: irq_at_slot = 6'd44;
      12: irq_at_slot = 6'd43;   13: irq_at_slot = 6'd21;   14: irq_at_slot = 6'd42;
      15: irq_at_slot = 6'd41;   16: irq_at_slot = 6'd20;   17: irq_at_slot = 6'd40;
      // customMiddleHighGroup
      18: irq_at_slot = 6'd59;   19: irq_at_slot = 6'd29;   20: irq_at_slot = 6'd58;
      21: irq_at_slot = 6'd57;   22: irq_at_slot = 6'd28;   23: irq_at_slot = 6'd56;
      // privArchGroup：规范定义的体系结构中断，M > S > VS，外部 > 软件 > 定时
      24: irq_at_slot = 6'd11;   // MEI  ← MEI_SLOT
      25: irq_at_slot = 6'd3;    // MSI
      26: irq_at_slot = 6'd7;    // MTI
      27: irq_at_slot = 6'd9;    // SEI  ← SEI_SLOT
      28: irq_at_slot = 6'd1;    // SSI
      29: irq_at_slot = 6'd5;    // STI
      30: irq_at_slot = 6'd12;   // SGEI
      31: irq_at_slot = 6'd10;   // VSEI
      32: irq_at_slot = 6'd2;    // VSSI
      33: irq_at_slot = 6'd6;    // VSTI
      34: irq_at_slot = 6'd13;   // LCOFI(COI)
      35: irq_at_slot = 6'd14;
      36: irq_at_slot = 6'd15;
      // customMiddleLowGroup
      37: irq_at_slot = 6'd55;   38: irq_at_slot = 6'd27;   39: irq_at_slot = 6'd54;
      40: irq_at_slot = 6'd53;   41: irq_at_slot = 6'd26;   42: irq_at_slot = 6'd52;
      // localLowGroup
      43: irq_at_slot = 6'd39;   44: irq_at_slot = 6'd19;   45: irq_at_slot = 6'd38;
      46: irq_at_slot = 6'd37;   47: irq_at_slot = 6'd18;   48: irq_at_slot = 6'd36;
      49: irq_at_slot = 6'd35;   50: irq_at_slot = 6'd17;   51: irq_at_slot = 6'd34;
      52: irq_at_slot = 6'd33;   53: irq_at_slot = 6'd16;   54: irq_at_slot = 6'd32;
      // customLowestGroup
      55: irq_at_slot = 6'd51;   56: irq_at_slot = 6'd25;   57: irq_at_slot = 6'd50;
      58: irq_at_slot = 6'd49;   59: irq_at_slot = 6'd24;   60: irq_at_slot = 6'd48;
      default: irq_at_slot = 6'd0;   // 补位槽（61..63）与越界：Mux1H 无选中项 -> 0
    endcase
  endfunction

  // ---------------------------------------------------------------------------
  // 两路比较：在两个候选里挑"优先级更高"的那个（Chisel: minSelect 的 size==2 分支）
  //
  // 三层嵌套 Mux1H，从外到内：
  //   ① enable：只有一边能取就取那边；都不能取 -> ★全零★（Mux1H 无选中项）
  //   ② isZero：iprio 为 0 的一方回退到默认优先级 —— 与"外部中断槽位"(eiSlot)
  //      比槽位号：槽位 <= eiSlot 说明它的默认优先级不低于外部中断，赢。
  //   ③ 数值比较：都非零时先看 greaterThan255（>255 的一律输），再比数值，小者赢。
  //
  // ★bug-for-bug：第 ③ 层两边 greaterThan255 都为 1 时，Chisel 的 Mux1H 没有任何
  //   选中项，结果是**全零结构体**（enable/idx/prioNum 全被抹掉），而不是"任选一个"。
  //   实现上这一路只可能出现在 xtopei 两侧同时 >255 —— 照抄，不许"顺手修好"。★
  // ---------------------------------------------------------------------------
  function automatic iprios_sort_t iprios_min2(input iprios_sort_t lhs,
                                               input iprios_sort_t rhs,
                                               input logic [5:0]   eiSlot);
    iprios_sort_t byNum;    // ③ 两边 iprio 都非零时的结果
    iprios_sort_t byZero;   // ② 两边都可取时的结果
    begin
      if      ( lhs.greaterThan255 && !rhs.greaterThan255) byNum = rhs;
      else if (!lhs.greaterThan255 &&  rhs.greaterThan255) byNum = lhs;
      else if (!lhs.greaterThan255 && !rhs.greaterThan255) byNum = (lhs.prioNum <= rhs.prioNum) ? lhs : rhs;
      else                                                 byNum = '0;   // ★见上

      if      ( lhs.isZero &&  rhs.isZero) byZero = lhs;                                // 都回退默认：表里靠前的就是 lhs
      else if ( lhs.isZero && !rhs.isZero) byZero = (lhs.idx <= eiSlot) ? lhs : rhs;
      else if (!lhs.isZero &&  rhs.isZero) byZero = (rhs.idx <= eiSlot) ? rhs : lhs;
      else                                 byZero = byNum;

      if      ( lhs.enable && !rhs.enable) iprios_min2 = lhs;
      else if (!lhs.enable &&  rhs.enable) iprios_min2 = rhs;
      else if ( lhs.enable &&  rhs.enable) iprios_min2 = byZero;
      else                                 iprios_min2 = '0;   // 都不可取 -> 全零
    end
  endfunction

  // ---------------------------------------------------------------------------
  // 8 路规约：平衡二叉树，形状与 Chisel 的递归完全一致
  //   minSelect(8) = min2( minSelect(前 4), minSelect(后 4) )
  //   minSelect(4) = min2( min2(a,b), min2(c,d) )
  // 形状必须一致才能 bug-for-bug —— 第 ③ 层那条"全零"路径会把中间结果抹成 0，
  // 换一种结合顺序结果就不同了。
  // ---------------------------------------------------------------------------
  function automatic iprios_sort_t iprios_min8(input iprios_sort_t [7:0] grp,
                                               input logic [5:0]         eiSlot);
    iprios_sort_t lo, hi;
    begin
      lo = iprios_min2(iprios_min2(grp[0], grp[1], eiSlot),
                       iprios_min2(grp[2], grp[3], eiSlot), eiSlot);
      hi = iprios_min2(iprios_min2(grp[4], grp[5], eiSlot),
                       iprios_min2(grp[6], grp[7], eiSlot), eiSlot);
      iprios_min8 = iprios_min2(lo, hi, eiSlot);
    end
  endfunction

  // ---------------------------------------------------------------------------
  // hviprio 字节查表：VS 级的可编程优先级只对一部分中断号存在
  //   hviprio1（hviprios[63:0]）：PrioSSI=byte1, PrioSTI=byte3,
  //                               PrioCOI=byte5, Prio14=byte6, Prio15=byte7
  //   hviprio2（hviprios[127:64]）：中断 16..23 的优先级，byte8..byte15
  // 其它中断号在 VS 级没有可编程优先级，返回 0（= "回退默认优先级"，isZero=1）。
  // ---------------------------------------------------------------------------
  function automatic logic [7:0] hviprio_byte(input logic [5:0]   irq,
                                              input logic [127:0] hviprios);
    case (irq)
      6'd1:  hviprio_byte = hviprios[15:8];     // hviprio1.PrioSSI
      6'd5:  hviprio_byte = hviprios[31:24];    // hviprio1.PrioSTI
      6'd13: hviprio_byte = hviprios[47:40];    // hviprio1.PrioCOI
      6'd14: hviprio_byte = hviprios[55:48];    // hviprio1.Prio14
      6'd15: hviprio_byte = hviprios[63:56];    // hviprio1.Prio15
      6'd16: hviprio_byte = hviprios[71:64];    // hviprio2 byte0
      6'd17: hviprio_byte = hviprios[79:72];
      6'd18: hviprio_byte = hviprios[87:80];
      6'd19: hviprio_byte = hviprios[95:88];
      6'd20: hviprio_byte = hviprios[103:96];
      6'd21: hviprio_byte = hviprios[111:104];
      6'd22: hviprio_byte = hviprios[119:112];
      6'd23: hviprio_byte = hviprios[127:120];  // hviprio2 byte7
      default: hviprio_byte = 8'h0;
    endcase
  endfunction

endpackage

// =============================================================================
// xs_InterruptFilter_core —— 可读核
//
// 接口是"总线视图"：xip/xie/xideleg 一律收成 64 位向量（位号 = 中断号），
// golden 那 296 个按 CSR 字段名拆开的扁平端口由下面的 wrapper 负责拼装。
// =============================================================================
module xs_InterruptFilter_core
  import interrupt_filter_pkg::*;
(
  input  logic         clock,
  input  logic         reset,

  // ---- 当前特权态 ------------------------------------------------------------
  input  logic [1:0]   privState_PRVM,     // PrivMode: U=0, S=1, M=3
  input  logic         privState_V,        // 处于虚拟化（VS/VU）态
  input  logic         mstatusMIE,
  input  logic         sstatusSIE,
  input  logic         vsstatusSIE,

  // ---- 三级中断挂起/使能/委托向量（位号 = 中断号）-----------------------------
  input  logic [63:0]  mip,
  input  logic [63:0]  mie,
  input  logic [63:0]  mideleg,
  input  logic [63:0]  sip,
  input  logic [63:0]  sie,
  input  logic [63:0]  hip,
  input  logic [63:0]  hie,
  input  logic [63:0]  hideleg,
  input  logic [63:0]  vsip,
  input  logic [63:0]  vsie,

  // ---- AIA 优先级数组与 xtopei ------------------------------------------------
  input  logic [511:0] miprios,            // M 级 iprio 数组：byte n = 中断 n 的优先级
  input  logic [511:0] hsiprios,           // HS 级同上
  input  logic [127:0] hviprios,           // VS 级：{hviprio2, hviprio1}，见 hviprio_byte
  input  logic [10:0]  mtopei_IPRIO,
  input  logic [10:0]  stopei_IPRIO,
  input  logic [10:0]  vstopei_IID,
  input  logic [10:0]  vstopei_IPRIO,

  // ---- 虚拟中断注入与 hstatus -------------------------------------------------
  input  logic         hvictl_VTI,
  input  logic [11:0]  hvictl_IID,
  input  logic         hvictl_DPR,
  input  logic         hvictl_IPRIOM,
  input  logic [7:0]   hvictl_IPRIO,
  input  logic [5:0]   hstatus_VGEIN,

  // ---- debug / NMI / 外部中断控制器 -------------------------------------------
  input  logic         debugIntr,
  input  logic         debugMode,
  input  logic         dcsr_STEP,
  input  logic         dcsr_STEPIE,
  input  logic         nmi,
  input  logic [63:0]  nmiVec,
  input  logic         mnstatusNMIE,
  input  logic         platform_meip,
  input  logic         platform_seip,
  input  logic         fromAIA_seip,
  input  logic         mvienSEIE,
  input  logic         mvipSEIP,

  // ---- 输出 -------------------------------------------------------------------
  output logic         out_debug,
  output logic         out_nmi,
  output logic         out_interruptVec_valid,
  output logic [7:0]   out_interruptVec_bits,
  output logic [11:0]  out_mtopi_IID,
  output logic [7:0]   out_mtopi_IPRIO,
  output logic [11:0]  out_stopi_IID,
  output logic [7:0]   out_stopi_IPRIO,
  output logic [11:0]  out_vstopi_IID,
  output logic [7:0]   out_vstopi_IPRIO,
  output logic         out_virtualInterruptIsHvictlInject,
  output logic         out_irToHS,
  output logic         out_irToVS
);

  // ---------------------------------------------------------------------------
  // 【§1】gather：每一级"现在可以取"的中断集合
  //
  //   M  级： mip & mie & ~mideleg                （没委托给 S 的才归 M）
  //   HS 级：(hip|sip) & (hie|sie) & ~hideleg     （hip/sip 字段不重叠，或起来就是全景）
  //   VS 级： vsip & vsie，且**屏蔽掉 SEI(9)**    —— VS 的外部中断走 Candidate1/2/3
  //                                                 那条独立通路，不进优先级树
  // ---------------------------------------------------------------------------
  logic [63:0] hsip, hsie;
  logic [63:0] mtopigather, hstopigather, vstopigather;

  assign hsip = hip | sip;
  assign hsie = hie | sie;

  assign mtopigather  = mip  & mie  & ~mideleg;
  assign hstopigather = hsip & hsie & ~hideleg;
  assign vstopigather = vsip & vsie & ~(64'h1 << IRQ_SEI);

  // mtopi/stopi 的"非零"判据打一拍后才用（见 §6）。
  logic mtopiIsNotZero, stopiIsNotZero;
  assign mtopiIsNotZero = |mtopigather;
  assign stopiIsNotZero = |hstopigather;

  // ---------------------------------------------------------------------------
  // 【§2】外部中断(EI) 的特殊来源
  //
  // 平台中断控制器（PLIC/IMSIC）直接给 meip/seip；AIA 的 stopei 还可能被
  // mvien/mvip 这条"虚拟化 S 级外部中断"的路子影响：
  //   injectSEI  —— mideleg.SEI 与 mvien.SEIE 不一致且 mvip.SEIP 置位，
  //                 说明这个 SEI 是 M 级注入出来的虚拟中断；
  //   SEIfromEIC —— SEI 真的来自中断控制器。
  // 注入且不是来自控制器时，把它的优先级当作 >255（排最后）。
  // ---------------------------------------------------------------------------
  logic platformValid, injectSEI, SEIfromEIC;

  assign platformValid = platform_meip | platform_seip;
  assign injectSEI     = (mideleg[IRQ_SEI] != mvienSEIE) & mvipSEIP;
  assign SEIfromEIC    = platform_seip | fromAIA_seip;

  // ---------------------------------------------------------------------------
  // 【§3】把 61 个中断号摆成排序网络的输入条目
  //
  // 三族各一张表（M / HS / VS），每族 8 组 × 8 条目 —— 第 8 组只有 5 个真条目，
  // 其余 3 个补全零（Chisel: sliceIpriosSort 的 paddingSlice）。
  // 全零条目的 enable=0，在 §4 的比较里永远输，不影响结果。
  // ---------------------------------------------------------------------------
  iprios_sort_t [GROUPS-1:0][7:0] mipriosSort;
  iprios_sort_t [GROUPS-1:0][7:0] hsipriosSort;
  iprios_sort_t [GROUPS-1:0][7:0] hvipriosSort;

  always_comb begin
    logic [5:0] slot;   // 优先级槽位号 = g*8 + j
    logic [5:0] irq;    // 该槽位对应的中断号
    logic [7:0] hvb;    // 该中断号在 VS 级的可编程优先级字节（无来源时为 0）
    for (int g = 0; g < GROUPS; g++) begin
      for (int j = 0; j < 8; j++) begin
        slot = 6'(g * 8 + j);
        irq  = irq_at_slot(slot);
        hvb  = hviprio_byte(irq, hviprios);

        // --- M 级 ---
        mipriosSort[g][j] = '0;
        if (slot < PRIO_SLOTS) begin
          mipriosSort[g][j].idx = slot;
          if (mtopigather[irq]) begin
            mipriosSort[g][j].enable = 1'b1;
            if (irq == IRQ_MEI) begin
              // MEI 的优先级来自 mtopei，可能 >255；isZero 由平台是否有挂起决定
              mipriosSort[g][j].isZero         = platformValid;
              mipriosSort[g][j].greaterThan255 = |mtopei_IPRIO[10:8];
              mipriosSort[g][j].prioNum        = mtopei_IPRIO[7:0];
            end else begin
              mipriosSort[g][j].isZero  = ~|miprios[{irq, 3'b000} +: 8];
              mipriosSort[g][j].prioNum =   miprios[{irq, 3'b000} +: 8];
            end
          end
        end

        // --- HS 级 ---
        hsipriosSort[g][j] = '0;
        if (slot < PRIO_SLOTS) begin
          hsipriosSort[g][j].idx = slot;
          if (hstopigather[irq]) begin
            hsipriosSort[g][j].enable = 1'b1;
            if (irq == IRQ_SEI) begin
              hsipriosSort[g][j].isZero         = platformValid;
              hsipriosSort[g][j].greaterThan255 = (injectSEI & ~SEIfromEIC) | (|stopei_IPRIO[10:8]);
              hsipriosSort[g][j].prioNum        = stopei_IPRIO[7:0];
            end else begin
              hsipriosSort[g][j].isZero  = ~|hsiprios[{irq, 3'b000} +: 8];
              hsipriosSort[g][j].prioNum =   hsiprios[{irq, 3'b000} +: 8];
            end
          end
        end

        // --- VS 级 ---
        // VS 的可编程优先级只对 SSI/STI/13..23 存在（hviprio1/hviprio2），
        // 其余中断号 hviprio_byte 返回 0 —— 正好等于"回退默认优先级"(isZero=1)，
        // 与 Chisel 里"先全置 isZero:=true，再按号覆盖"的两段写法逐位一致。
        // greaterThan255 在 VS 级没有来源，恒 0（golden 里这一列寄存器已被常折掉）。
        hvipriosSort[g][j] = '0;
        if (slot < PRIO_SLOTS) begin
          hvipriosSort[g][j].idx = slot;
          if (vstopigather[irq]) begin
            hvipriosSort[g][j].enable  = 1'b1;
            hvipriosSort[g][j].isZero  = ~|hvb;
            hvipriosSort[g][j].prioNum =   hvb;
          end
        end
      end
    end
  end

  // ---------------------------------------------------------------------------
  // 【§4】第一级规约：每组 8 条目里选一个（组合），然后打一拍
  // ---------------------------------------------------------------------------
  iprios_sort_t [GROUPS-1:0] mipriosTmp, hsipriosTmp, hvipriosTmp;

  always_comb begin
    for (int g = 0; g < GROUPS; g++) begin
      mipriosTmp[g]  = iprios_min8(mipriosSort[g],  MEI_SLOT);
      hsipriosTmp[g] = iprios_min8(hsipriosSort[g], SEI_SLOT);
      hvipriosTmp[g] = iprios_min8(hvipriosSort[g], SEI_SLOT);
    end
  end

  // ---------------------------------------------------------------------------
  // 【§5】流水寄存器（无复位，与 golden 的 `always @(posedge clock)` 一致）
  //
  // ★寄存器**字段集合**照搬 golden，多一位少一位都不行★：
  //   · greaterThan255 在 Chisel 源里除了 EI 那一条全是字面常量 false，
  //     firtool 把整列常折掉 —— M/HS 只留第 EI_GROUP(=3) 组一位，VS 一位不留；
  //   · VS 的第 7 组（槽位 56..60 = 中断 51/25/50/49/24/48）没有任何 hviprio 字节，
  //     prioNum 恒 0，同样被折掉 —— 所以 hviprios 这一族只有 0..6 组有 prioNum。
  // 这不是"省资源"，是等价性要求：多出来的常零寄存器在 FM 里会成为无法配对的比较点。
  // 按 per-field 数组（SoA）存，不用 packed struct 数组 —— 见 CONVENTIONS。
  // ---------------------------------------------------------------------------
  logic [5:0] mipriosReg_idx     [GROUPS];
  logic       mipriosReg_enable  [GROUPS];
  logic       mipriosReg_isZero  [GROUPS];
  logic [7:0] mipriosReg_prioNum [GROUPS];
  logic       mipriosReg_greaterThan255;            // 只有第 EI_GROUP 组

  logic [5:0] hsipriosReg_idx     [GROUPS];
  logic       hsipriosReg_enable  [GROUPS];
  logic       hsipriosReg_isZero  [GROUPS];
  logic [7:0] hsipriosReg_prioNum [GROUPS];
  logic       hsipriosReg_greaterThan255;           // 只有第 EI_GROUP 组

  logic [5:0] hvipriosReg_idx     [GROUPS];
  logic       hvipriosReg_enable  [GROUPS];
  logic       hvipriosReg_isZero  [GROUPS];
  logic [7:0] hvipriosReg_prioNum [GROUPS-1];       // 第 7 组无来源，不开寄存器

  // hvictl / vstopei 的打拍拷贝。golden 只留下真正被用到的字段：
  // hvictl.VTI 与 vstopei.IID 的**寄存器**没有读者（Candidate4/5 用的是未打拍的
  // hvictl.VTI），firtool 删掉了，这里照搬。
  logic [11:0] hvictlReg_IID;
  logic        hvictlReg_DPR;
  logic        hvictlReg_IPRIOM;
  logic [7:0]  hvictlReg_IPRIO;
  logic [10:0] vstopeiReg_IPRIO;

  always_ff @(posedge clock) begin
    for (int g = 0; g < GROUPS; g++) begin
      mipriosReg_idx[g]      <= mipriosTmp[g].idx;
      mipriosReg_enable[g]   <= mipriosTmp[g].enable;
      mipriosReg_isZero[g]   <= mipriosTmp[g].isZero;
      mipriosReg_prioNum[g]  <= mipriosTmp[g].prioNum;

      hsipriosReg_idx[g]     <= hsipriosTmp[g].idx;
      hsipriosReg_enable[g]  <= hsipriosTmp[g].enable;
      hsipriosReg_isZero[g]  <= hsipriosTmp[g].isZero;
      hsipriosReg_prioNum[g] <= hsipriosTmp[g].prioNum;

      hvipriosReg_idx[g]     <= hvipriosTmp[g].idx;
      hvipriosReg_enable[g]  <= hvipriosTmp[g].enable;
      hvipriosReg_isZero[g]  <= hvipriosTmp[g].isZero;
    end
    for (int g = 0; g < GROUPS - 1; g++)
      hvipriosReg_prioNum[g] <= hvipriosTmp[g].prioNum;

    mipriosReg_greaterThan255  <= mipriosTmp[EI_GROUP].greaterThan255;
    hsipriosReg_greaterThan255 <= hsipriosTmp[EI_GROUP].greaterThan255;

    hvictlReg_IID    <= hvictl_IID;
    hvictlReg_DPR    <= hvictl_DPR;
    hvictlReg_IPRIOM <= hvictl_IPRIOM;
    hvictlReg_IPRIO  <= hvictl_IPRIO;
    vstopeiReg_IPRIO <= vstopei_IPRIO;
  end

  // 把 SoA 寄存器还原成条目结构，喂给第二级规约（被折掉的列在这里补常量）。
  iprios_sort_t [GROUPS-1:0] mipriosRegQ, hsipriosRegQ, hvipriosRegQ;

  always_comb begin
    for (int g = 0; g < GROUPS; g++) begin
      mipriosRegQ[g].idx            = mipriosReg_idx[g];
      mipriosRegQ[g].enable         = mipriosReg_enable[g];
      mipriosRegQ[g].isZero         = mipriosReg_isZero[g];
      mipriosRegQ[g].greaterThan255 = (g == EI_GROUP) ? mipriosReg_greaterThan255 : 1'b0;
      mipriosRegQ[g].prioNum        = mipriosReg_prioNum[g];

      hsipriosRegQ[g].idx            = hsipriosReg_idx[g];
      hsipriosRegQ[g].enable         = hsipriosReg_enable[g];
      hsipriosRegQ[g].isZero         = hsipriosReg_isZero[g];
      hsipriosRegQ[g].greaterThan255 = (g == EI_GROUP) ? hsipriosReg_greaterThan255 : 1'b0;
      hsipriosRegQ[g].prioNum        = hsipriosReg_prioNum[g];

      hvipriosRegQ[g].idx            = hvipriosReg_idx[g];
      hvipriosRegQ[g].enable         = hvipriosReg_enable[g];
      hvipriosRegQ[g].isZero         = hvipriosReg_isZero[g];
      hvipriosRegQ[g].greaterThan255 = 1'b0;
      hvipriosRegQ[g].prioNum        = 8'h0;
    end
    for (int g = 0; g < GROUPS - 1; g++)
      hvipriosRegQ[g].prioNum = hvipriosReg_prioNum[g];
  end

  // 第二级规约：8 个组代表里再选一个 —— 这就是本级的最高优先级中断。
  iprios_sort_t mipriosRegTmp, hsipriosRegTmp, hvipriosRegTmp;

  assign mipriosRegTmp  = iprios_min8(mipriosRegQ,  MEI_SLOT);
  assign hsipriosRegTmp = iprios_min8(hsipriosRegQ, SEI_SLOT);
  assign hvipriosRegTmp = iprios_min8(hvipriosRegQ, SEI_SLOT);

  // ---------------------------------------------------------------------------
  // 【§6】mtopi / stopi 输出
  //
  // xtopi.IPRIO 的三选一（Chisel Mux1H，条件不互斥，语义是"按位或"，照搬）：
  //   · iprio 非零且不 >255            -> 就用这个数值
  //   · iprio >255，或 iprio=0 且默认优先级**低于**外部中断 -> 255（最低）
  //   · iprio=0 且默认优先级**高于**外部中断                -> 0（最高）
  // 三条都不成立（iprio=0 且槽位恰好就是外部中断自己）时 Mux1H 无选中项 -> 0。
  //
  // 下面这两个寄存器名字里的 `_last_REG` 是 Chisel `GatedValidRegNext` 展开后的
  // 叶名，本文件所有**标量**寄存器都照抄 golden 的叶名，让 FM 靠名字就能配对
  // （少一个钉点就少一处出错的地方）。数组寄存器见 §5。
  // ---------------------------------------------------------------------------
  logic mtopiIsNotZeroReg_last_REG;
  logic stopiIsNotZeroReg_last_REG;

  function automatic logic [7:0] topi_iprio(input iprios_sort_t sel,
                                            input logic [5:0]   eiSlot);
    begin
      topi_iprio = ({8{~sel.isZero & ~sel.greaterThan255}} & sel.prioNum)
                 | ({8{ sel.greaterThan255 | (sel.isZero & (sel.idx > eiSlot))}} & 8'hFF);
      // 第三条分支的取值是 8'h0，按位或上去不改变结果，故不再写出。
    end
  endfunction

  logic [11:0] mtopi_IID, stopi_IID;
  logic [7:0]  mtopi_IPRIO, stopi_IPRIO;

  assign mtopi_IID   = mtopiIsNotZeroReg_last_REG ? {6'h0, irq_at_slot(mipriosRegTmp.idx)}  : 12'h0;
  assign mtopi_IPRIO = mtopiIsNotZeroReg_last_REG ? topi_iprio(mipriosRegTmp,  MEI_SLOT)    : 8'h0;
  assign stopi_IID   = stopiIsNotZeroReg_last_REG ? {6'h0, irq_at_slot(hsipriosRegTmp.idx)} : 12'h0;
  assign stopi_IPRIO = stopiIsNotZeroReg_last_REG ? topi_iprio(hsipriosRegTmp, SEI_SLOT)    : 8'h0;

  assign out_mtopi_IID   = mtopi_IID;
  assign out_mtopi_IPRIO = mtopi_IPRIO;
  assign out_stopi_IID   = stopi_IID;
  assign out_stopi_IPRIO = stopi_IPRIO;

  // ---------------------------------------------------------------------------
  // 【§7】VS 级的五个候选（Chisel 原注释：refactor this code & has some problem）
  //
  //   C1：vsip.SEIP 有效 + hstatus.VGEIN 选了一个 guest 中断文件 + vstopei 非零
  //       -> 外部中断来自 IMSIC 的 guest interrupt file
  //   C2：vsip.SEIP 有效 + 没选 guest 文件 + hvictl 注入的就是 SEI(9) 且优先级非零
  //   C3：vsip.SEIP 有效但 C1/C2 都不成立（兜底，优先级视为最低 255）
  //   C4：hvictl.VTI=0 时，VS 的普通中断（走 §3~§5 那棵树选出来的 hvipriosRegTmp）
  //   C5：hvictl.VTI=1 且注入的中断号不是 SEI -> 直接注入 hvictl.IID
  //
  // C1/C2/C3 互斥（都描述 SEI 这一条），C4/C5 互斥（都描述"非 SEI"那一条），
  // 于是最终只可能是 {无} / {C1|C2|C3} / {C4|C5} / {C1..C3}×{C4,C5} 这几种组合。
  // 组合要比优先级，所以下面为每种组合各算一份 (IID, IPRIO)。
  // ---------------------------------------------------------------------------
  logic Candidate1, Candidate2, Candidate3, Candidate4, Candidate5;
  logic Candidate123, Candidate45, CandidateNoValid;

  assign Candidate1 = vsip[IRQ_SEI] & vsie[IRQ_SEI] & (|hstatus_VGEIN)
                      & (|{vstopei_IID, vstopei_IPRIO});
  assign Candidate2 = vsip[IRQ_SEI] & vsie[IRQ_SEI] & (hstatus_VGEIN == 6'h0)
                      & (hvictl_IID == 12'h9) & (|hvictl_IPRIO);
  assign Candidate3 = vsip[IRQ_SEI] & vsie[IRQ_SEI] & ~Candidate1 & ~Candidate2;
  assign Candidate4 = ~hvictl_VTI & (|vstopigather);
  assign Candidate5 =  hvictl_VTI & (hvictl_IID != 12'h9);

  assign Candidate123     = Candidate1 | Candidate2 | Candidate3;
  assign Candidate45      = Candidate4 | Candidate5;
  assign CandidateNoValid = ~Candidate1 & ~Candidate2 & ~Candidate3
                          & ~Candidate4 & ~Candidate5;

  // 组合标志打一拍（与 hvictlReg/vstopeiReg 同一拍，保证下面比优先级时口径一致）
  logic CandidateNoValidReg_last_REG;
  logic Candidate123Reg_last_REG;
  logic NoCandidate45Reg_last_REG;
  logic onlyC1EnableReg_last_REG, onlyC2EnableReg_last_REG, onlyC3EnableReg_last_REG;
  logic onlyC4EnableReg_last_REG, onlyC5EnableReg_last_REG;
  logic C1C4EnableReg_last_REG, C1C5EnableReg_last_REG, C2C4EnableReg_last_REG;
  logic C3C4EnableReg_last_REG, C3C5EnableReg_last_REG;

  // ---------------------------------------------------------------------------
  // 【§8】VS 级各组合的 (IID, IPRIO)
  //
  // 比较口径统一成 11 位（vstopei.IPRIO 有 11 位，hvictl.IPRIO / hviprio 只有 8 位，
  // 零扩展后再比），与 Chisel 里 Wire(UInt(11.W)) 的声明一致。
  // ---------------------------------------------------------------------------
  logic [11:0] iidOnlyC1, iidOnlyC4, iidOnlyC5;
  logic [11:0] iidC4Idx;
  logic [7:0]  iprioOnlyC1, iprioOnlyC2, iprioOnlyC3, iprioOnlyC4, iprioOnlyC5;
  logic [11:0] iidC1C4, iidC1C5, iidC2C4, iidC3C4, iidC3C5;
  logic [7:0]  iprioC1C4, iprioC1C5, iprioC2C4, iprioC3C4, iprioC3C5;

  logic [10:0] iprioC1, iprioC2C5, iprioC4;
  logic [7:0]  iprioC1Tmp, iprioC4Tmp, iprioC3C5Tmp, iprioC1GreaterThan255;
  logic [7:0]  hvictlDPR;
  logic        C1GreaterThan255, C4IsZero, C2C5IsZero, C4HighVSEI, SEIHighC4;

  assign iidOnlyC1 = {6'h0, IRQ_SEI};                          // C1/C2 报的都是 SEI(9)
  assign iidOnlyC4 = {6'h0, irq_at_slot(hvipriosRegTmp.idx)};  // 树里选出来的中断号
  assign iidOnlyC5 = hvictlReg_IID;                            // hvictl 直接注入的号
  assign iidC4Idx  = {6'h0, hvipriosRegTmp.idx};

  assign iprioC1   = vstopeiReg_IPRIO;
  assign iprioC2C5 = {3'h0, hvictlReg_IPRIO};
  assign iprioC4   = {3'h0, hvipriosRegTmp.prioNum};

  assign C1GreaterThan255 = |vstopeiReg_IPRIO[10:8];
  assign C4IsZero         = ~|hvipriosRegTmp.prioNum;
  assign C2C5IsZero       = ~|hvictlReg_IPRIO;
  assign C4HighVSEI       = iidC4Idx < {6'h0, SEI_SLOT};   // C4 的默认优先级高于 VS 外部中断
  assign SEIHighC4        = {6'h0, SEI_SLOT} < iidC4Idx;   // 反之

  assign hvictlDPR             = hvictlReg_DPR ? 8'hFF : 8'h0;
  assign iprioC1Tmp            = iprioC1[7:0];
  assign iprioC1GreaterThan255 = C1GreaterThan255 ? 8'hFF : iprioC1Tmp;
  assign iprioC4Tmp            = C4IsZero ? (C4HighVSEI ? 8'h0 : 8'hFF) : iprioC4[7:0];
  assign iprioC3C5Tmp          = C2C5IsZero ? hvictlDPR : iprioC2C5[7:0];

  assign iprioOnlyC1 = iprioC1GreaterThan255;
  assign iprioOnlyC2 = iprioC2C5[7:0];
  assign iprioOnlyC3 = 8'hFF;     // C3 是兜底，优先级最低
  assign iprioOnlyC4 = iprioC4Tmp;
  assign iprioOnlyC5 = iprioC3C5Tmp;

  // C1 与 C4 同时成立：谁的 iprio 小谁赢，平手时看默认优先级（SEI 与 C4 的槽位）
  always_comb begin
    if (C4IsZero) begin                       // C4 回退默认优先级
      iidC1C4   = C4HighVSEI ? iidOnlyC4 : iidOnlyC1;
      iprioC1C4 = C4HighVSEI ? 8'h0      : iprioC1GreaterThan255;
    end else if (iprioC1 < iprioC4) begin
      iidC1C4   = iidOnlyC1;
      iprioC1C4 = iprioC1Tmp;
    end else if (iprioC1 == iprioC4) begin
      iidC1C4   = SEIHighC4 ? iidOnlyC1  : iidOnlyC4;
      iprioC1C4 = SEIHighC4 ? iprioC1Tmp : iprioC4[7:0];
    end else begin
      iidC1C4   = iidOnlyC4;
      iprioC1C4 = iprioC4[7:0];
    end
  end

  // C1 与 C5（hvictl 注入）同时成立：平手时由 hvictl.DPR 决定谁在前
  // ★注意 Chisel 里 iidC1C5 先有一条无条件默认连接，when 链只覆盖其中两支★
  always_comb begin
    iidC1C5 = hvictlReg_DPR ? iidOnlyC1 : iidOnlyC5;   // 默认连接
    if (C2C5IsZero) begin
      iprioC1C5 = hvictlReg_DPR ? iprioC1GreaterThan255 : 8'h0;
    end else if (iprioC1 < iprioC2C5) begin
      iidC1C5   = iidOnlyC1;
      iprioC1C5 = iprioC1Tmp;
    end else if (iprioC1 == iprioC2C5) begin
      iprioC1C5 = hvictlReg_DPR ? iprioC1Tmp : iprioC2C5[7:0];
    end else begin
      iidC1C5   = iidOnlyC5;
      iprioC1C5 = iprioC3C5Tmp;
    end
  end

  // C2 与 C4 同时成立：与 C1C4 同形，只是 C2 的优先级取自 hvictl.IPRIO
  always_comb begin
    if (C4IsZero) begin
      iidC2C4   = C4HighVSEI ? iidOnlyC4 : iidOnlyC1;
      iprioC2C4 = C4HighVSEI ? 8'h0      : iprioC2C5[7:0];
    end else if (iprioC2C5 < iprioC4) begin
      iidC2C4   = iidOnlyC1;
      iprioC2C4 = iprioC2C5[7:0];
    end else if (iprioC2C5 == iprioC4) begin
      iidC2C4   = SEIHighC4 ? iidOnlyC1      : iidOnlyC4;
      iprioC2C4 = SEIHighC4 ? iprioC2C5[7:0] : iprioC4[7:0];
    end else begin
      iidC2C4   = iidOnlyC4;
      iprioC2C4 = iprioC4[7:0];
    end
  end

  // C3（兜底 SEI）与 C4 / C5 同时成立
  assign iidC3C4   = C4IsZero ? (C4HighVSEI ? iidOnlyC4 : iidOnlyC1) : iidOnlyC4;
  assign iprioC3C4 = iprioC4Tmp;
  assign iidC3C5   = C2C5IsZero ? (hvictlReg_DPR ? iidOnlyC1 : iidOnlyC5) : iidOnlyC5;
  assign iprioC3C5 = iprioC3C5Tmp;

  // vstopi：按打拍后的组合标志做 Mux1H（各组合互斥，无选中项时为 0）
  logic [11:0] vstopi_IID;
  logic [7:0]  vstopi_IPRIO, vstopi_IPRIO_sel;

  always_comb begin
    vstopi_IID = 12'h0;
    if (~CandidateNoValidReg_last_REG) begin
      vstopi_IID = ({12{Candidate123Reg_last_REG & NoCandidate45Reg_last_REG}} & iidOnlyC1)
                 | ({12{onlyC4EnableReg_last_REG}} & iidOnlyC4)
                 | ({12{onlyC5EnableReg_last_REG}} & iidOnlyC5)
                 | ({12{C1C4EnableReg_last_REG}}   & iidC1C4)
                 | ({12{C1C5EnableReg_last_REG}}   & iidC1C5)
                 | ({12{C2C4EnableReg_last_REG}}   & iidC2C4)
                 | ({12{C3C4EnableReg_last_REG}}   & iidC3C4)
                 | ({12{C3C5EnableReg_last_REG}}   & iidC3C5);
    end
  end

  assign vstopi_IPRIO_sel =
      ({8{onlyC1EnableReg_last_REG}} & iprioOnlyC1)
    | ({8{onlyC2EnableReg_last_REG}} & iprioOnlyC2)
    | ({8{onlyC3EnableReg_last_REG}} & iprioOnlyC3)
    | ({8{onlyC4EnableReg_last_REG}} & iprioOnlyC4)
    | ({8{onlyC5EnableReg_last_REG}} & iprioOnlyC5)
    | ({8{C1C4EnableReg_last_REG}}   & iprioC1C4)
    | ({8{C1C5EnableReg_last_REG}}   & iprioC1C5)
    | ({8{C2C4EnableReg_last_REG}}   & iprioC2C4)
    | ({8{C3C4EnableReg_last_REG}}   & iprioC3C4)
    | ({8{C3C5EnableReg_last_REG}}   & iprioC3C5);

  // hvictl.IPRIOM=0 时 VS 不支持机器定义优先级，vstopi.IPRIO 恒为 1（规范要求）
  assign vstopi_IPRIO = CandidateNoValidReg_last_REG ? 8'h0
                      : (~hvictlReg_IPRIOM ? 8'h1 : vstopi_IPRIO_sel);

  assign out_vstopi_IID   = vstopi_IID;
  assign out_vstopi_IPRIO = vstopi_IPRIO;

  // ---------------------------------------------------------------------------
  // 【§9】按当前特权态决定"往哪一级投递"，并合成 8 位中断向量
  //
  // 规范：一个中断只有在"目标特权级 == 当前级且该级全局使能"或"目标特权级高于
  // 当前级"时才能取。特权级序：VU < VS < HS < M，HU < HS < M（V 位把两条链分开）。
  // 三级同时有候选时 M > HS > VS。
  // ---------------------------------------------------------------------------
  logic isModeM, isModeHS, isModeVS;
  logic ltModeM, ltModeHS, ltModeVS;

  assign isModeM  =                  (privState_PRVM == 2'd3);
  assign isModeHS = ~privState_V   & (privState_PRVM == 2'd1);
  assign isModeVS =  privState_V   & (privState_PRVM == 2'd1);
  // privState < ModeX 的展开（Chisel: PrivState.< ）
  assign ltModeM  =  privState_V | (~privState_V & (privState_PRVM != 2'd3));
  assign ltModeHS =  privState_V | (~privState_V & (privState_PRVM == 2'd0));
  assign ltModeVS =  privState_V &                 (privState_PRVM == 2'd0);

  logic        mModeCond, hsModeCond, vsIRModeCond;
  logic [11:0] mIRVecTmp, hsIRVecTmp, vsIRVecTmp;
  logic        mIRNotZero, hsIRNotZero, vsIRNotZero;
  logic        irToHS, irToVS;
  logic [11:0] mIRVec, hsIRVec;
  logic [63:0] vsIRVec;

  assign mModeCond    = (isModeM  & mstatusMIE)  | ltModeM;
  assign hsModeCond   = (isModeHS & sstatusSIE)  | ltModeHS;
  assign vsIRModeCond = (isModeVS & vsstatusSIE) | ltModeVS;

  assign mIRVecTmp  = mModeCond    ? mtopi_IID  : 12'h0;
  assign hsIRVecTmp = hsModeCond   ? stopi_IID  : 12'h0;
  assign vsIRVecTmp = vsIRModeCond ? vstopi_IID : 12'h0;

  assign mIRNotZero  = |mIRVecTmp;
  assign hsIRNotZero = |hsIRVecTmp;
  assign vsIRNotZero = |vsIRVecTmp;

  assign irToHS = ~mIRNotZero & hsIRNotZero;
  assign irToVS = ~mIRNotZero & ~hsIRNotZero & vsIRNotZero;

  assign mIRVec  = mIRVecTmp;
  assign hsIRVec = irToHS ? hsIRVecTmp : 12'h0;
  assign vsIRVec = irToVS ? (64'h1 << vsIRVecTmp[5:0]) : 64'h0;

  // VS 报的中断号是 **S 级编号**（SSI=1/STI=5/SEI=9），投给宿主时要换成
  // VS 级编号（VSSI=2/VSTI=6/VSEI=10），同时把 S 级那三位清掉。
  logic [63:0] vsMapHostIRVecTmp;
  logic [5:0]  vsMapHostIRVec;

  always_comb begin
    for (int n = 0; n < 64; n++) begin
      if (n == 2 || n == 6 || n == 10)      vsMapHostIRVecTmp[n] = vsIRVec[n-1];  // VSxI ← SxI
      else if (n == 1 || n == 5 || n == 9)  vsMapHostIRVecTmp[n] = 1'b0;          // 清掉 S 级位
      else                                  vsMapHostIRVecTmp[n] = vsIRVec[n];
    end
  end

  // OHToUInt：把 one-hot 还原成编号（Chisel 语义 = 把置位下标按位或起来）
  always_comb begin
    vsMapHostIRVec = 6'h0;
    for (int n = 0; n < 64; n++)
      vsMapHostIRVec = vsMapHostIRVec | (vsMapHostIRVecTmp[n] ? 6'(n) : 6'h0);
  end

  // ---- NMI：不可屏蔽中断只有两个来源，43 优先于 31 --------------------------
  logic [63:0] nmiVecTmp;
  logic [5:0]  nmiVecIdx;

  always_comb begin
    nmiVecTmp = 64'h0;
    nmiVecTmp[43] =  nmiVec[43];
    nmiVecTmp[31] = ~nmiVec[43] & nmiVec[31];   // 43 更高优先级，压住 31
  end

  always_comb begin
    nmiVecIdx = 6'h0;
    for (int n = 0; n < 64; n++)
      nmiVecIdx = nmiVecIdx | (nmiVecTmp[n] ? 6'(n) : 6'h0);
  end

  // ---- debug / smrnmi 的总闸 ------------------------------------------------
  // dcsr.STEP 单步且 STEPIE=0 时屏蔽普通中断；mnstatus.NMIE=0（smrnmi）时全屏蔽。
  logic disableDebugIntr, enableDebugIntr, disableAllIntr;

  assign disableDebugIntr = debugMode | (dcsr_STEP & ~dcsr_STEPIE);
  assign enableDebugIntr  = debugIntr & ~disableDebugIntr;
  assign disableAllIntr   = disableDebugIntr | ~mnstatusNMIE;

  logic [11:0] normalIntrVec;
  logic [11:0] intrVec;

  assign normalIntrVec = mIRVec | hsIRVec | {6'h0, vsMapHostIRVec};
  assign intrVec       = disableAllIntr ? 12'h0
                       : (nmi ? {6'h0, nmiVecIdx} : normalIntrVec);

  // ---- hvictl 注入判据（供 NewCSR 决定 vscause 的写法）----------------------
  // 只有"最终选中的是 C5 那一支"时才算注入。C1C5 / C3C5 的平手规则与 §8 一致。
  logic SelectCandidate5;

  assign SelectCandidate5 =
      onlyC5EnableReg_last_REG
    | (C1C5EnableReg_last_REG
       & ( (~C2C5IsZero & ((iprioC1 > iprioC2C5) | ((iprioC1 == iprioC2C5) & ~hvictlReg_DPR)))
         | ( C2C5IsZero & ~hvictlReg_DPR) ))
    | (C3C5EnableReg_last_REG & (~C2C5IsZero | ~hvictlReg_DPR));

  // ---------------------------------------------------------------------------
  // 【§10】输出寄存器（异步复位，与 golden 的 posedge clock or posedge reset 一致）
  // ---------------------------------------------------------------------------
  logic [7:0] intrVecReg;
  logic       debugIntrReg;
  logic       nmiReg;
  logic       viIsHvictlInjectReg;
  logic       irToHSReg;
  logic       irToVSReg;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      mtopiIsNotZeroReg_last_REG   <= 1'b0;
      stopiIsNotZeroReg_last_REG   <= 1'b0;
      CandidateNoValidReg_last_REG <= 1'b0;
      Candidate123Reg_last_REG     <= 1'b0;
      NoCandidate45Reg_last_REG    <= 1'b0;
      onlyC1EnableReg_last_REG     <= 1'b0;
      onlyC2EnableReg_last_REG     <= 1'b0;
      onlyC3EnableReg_last_REG     <= 1'b0;
      onlyC4EnableReg_last_REG     <= 1'b0;
      onlyC5EnableReg_last_REG     <= 1'b0;
      C1C4EnableReg_last_REG       <= 1'b0;
      C1C5EnableReg_last_REG       <= 1'b0;
      C2C4EnableReg_last_REG       <= 1'b0;
      C3C4EnableReg_last_REG       <= 1'b0;
      C3C5EnableReg_last_REG       <= 1'b0;
      intrVecReg                   <= 8'h0;
      debugIntrReg                 <= 1'b0;
      nmiReg                       <= 1'b0;
      viIsHvictlInjectReg          <= 1'b0;
      irToHSReg                    <= 1'b0;
      irToVSReg                    <= 1'b0;
    end else begin
      mtopiIsNotZeroReg_last_REG   <= mtopiIsNotZero;
      stopiIsNotZeroReg_last_REG   <= stopiIsNotZero;
      CandidateNoValidReg_last_REG <= CandidateNoValid;
      Candidate123Reg_last_REG     <= Candidate123;
      NoCandidate45Reg_last_REG    <= ~Candidate45;
      onlyC1EnableReg_last_REG     <= Candidate1 & ~Candidate45;
      onlyC2EnableReg_last_REG     <= Candidate2 & ~Candidate45;
      onlyC3EnableReg_last_REG     <= Candidate3 & ~Candidate45;
      onlyC4EnableReg_last_REG     <= Candidate4 & ~Candidate123;
      onlyC5EnableReg_last_REG     <= Candidate5 & ~Candidate123;
      C1C4EnableReg_last_REG       <= Candidate1 & Candidate4;
      C1C5EnableReg_last_REG       <= Candidate1 & Candidate5;
      C2C4EnableReg_last_REG       <= Candidate2 & Candidate4;
      C3C4EnableReg_last_REG       <= Candidate3 & Candidate4;
      C3C5EnableReg_last_REG       <= Candidate3 & Candidate5;
      intrVecReg                   <= intrVec[7:0];
      debugIntrReg                 <= enableDebugIntr;
      nmiReg                       <= nmi;
      viIsHvictlInjectReg          <= vsIRModeCond & SelectCandidate5 & mnstatusNMIE;
      irToHSReg                    <= irToHS;
      irToVSReg                    <= irToVS;
    end
  end

  // ---------------------------------------------------------------------------
  // 【§11】再延迟 5 拍送出
  //
  // Chisel 原注释：delay at least 6 cycles to maintain the atomic of sret/mret。
  // 1 拍来自 §10 的寄存器，5 拍来自这里的 DelayN。DelayN_17（1 位）/ DelayN_208
  // （8 位）都是 5 级无复位移位链，属 rtl/common 的 DelayN 家族（本目标不重写它们，
  // 见本文件对应的 FM 预登记）。
  // ---------------------------------------------------------------------------
  logic [7:0] delayedIntrVec;
  logic       delayedDebugIntr, delayedNMI, delayedVIIsHvictlInject;
  logic       delayedIRToHS, delayedIRToVS;

  DelayN_208 delayedIntrVec_delay (
    .clock (clock), .io_in (intrVecReg),          .io_out (delayedIntrVec));
  DelayN_17  delayedDebugIntr_delay (
    .clock (clock), .io_in (debugIntrReg),        .io_out (delayedDebugIntr));
  DelayN_17  delayedNMI_delay (
    .clock (clock), .io_in (nmiReg),              .io_out (delayedNMI));
  DelayN_17  delayedVIIsHvictlInjectReg_delay (
    .clock (clock), .io_in (viIsHvictlInjectReg), .io_out (delayedVIIsHvictlInject));
  DelayN_17  delayedIRToHS_delay (
    .clock (clock), .io_in (irToHSReg),           .io_out (delayedIRToHS));
  DelayN_17  delayedIRToVS_delay (
    .clock (clock), .io_in (irToVSReg),           .io_out (delayedIRToVS));

  // NMI 在途时压住普通中断的三个标志（NMI 自己走 io_out_nmi 这一路）
  assign out_interruptVec_valid = (|delayedIntrVec) | delayedDebugIntr;
  assign out_interruptVec_bits  = delayedIntrVec;
  assign out_debug              = delayedDebugIntr;
  assign out_nmi                = delayedNMI;
  assign out_virtualInterruptIsHvictlInject = delayedVIIsHvictlInject & ~delayedNMI;
  assign out_irToHS             = delayedIRToHS & ~delayedNMI;
  assign out_irToVS             = delayedIRToVS & ~delayedNMI;

endmodule

// BEGIN GENERATED(wrapper)
// 本段由 verif/ut/InterruptFilter/gen.py 从 G1 golden 端口表现读现生成，勿手改。
//
// golden 同名 wrapper：端口表与 golden 逐字一致（名字/方向/位宽/顺序），
// 体内只做一件事 —— 把按 CSR 字段名拆开的标量端口重新收成"位号 = 中断号"的
// 64 位中断向量，再交给可读核。
module InterruptFilter(
  input           clock,
  input           reset,
  input  [1:0]    io_in_privState_PRVM,
  input           io_in_privState_V,
  input           io_in_mstatusMIE,
  input           io_in_sstatusSIE,
  input           io_in_vsstatusSIE,
  input           io_in_mip_SSIP,
  input           io_in_mip_VSSIP,
  input           io_in_mip_MSIP,
  input           io_in_mip_STIP,
  input           io_in_mip_VSTIP,
  input           io_in_mip_MTIP,
  input           io_in_mip_SEIP,
  input           io_in_mip_VSEIP,
  input           io_in_mip_MEIP,
  input           io_in_mip_SGEIP,
  input           io_in_mip_LCOFIP,
  input           io_in_mie_SSIE,
  input           io_in_mie_VSSIE,
  input           io_in_mie_MSIE,
  input           io_in_mie_STIE,
  input           io_in_mie_VSTIE,
  input           io_in_mie_MTIE,
  input           io_in_mie_SEIE,
  input           io_in_mie_VSEIE,
  input           io_in_mie_MEIE,
  input           io_in_mie_SGEIE,
  input           io_in_mie_LCOFIE,
  input           io_in_mideleg_SSI,
  input           io_in_mideleg_STI,
  input           io_in_mideleg_SEI,
  input           io_in_mideleg_LCOFI,
  input           io_in_sip_SSIP,
  input           io_in_sip_STIP,
  input           io_in_sip_SEIP,
  input           io_in_sip_LCOFIP,
  input           io_in_sip_LC14IP,
  input           io_in_sip_LC15IP,
  input           io_in_sip_LC16IP,
  input           io_in_sip_LC17IP,
  input           io_in_sip_LC18IP,
  input           io_in_sip_LC19IP,
  input           io_in_sip_LC20IP,
  input           io_in_sip_LC21IP,
  input           io_in_sip_LC22IP,
  input           io_in_sip_LC23IP,
  input           io_in_sip_LC24IP,
  input           io_in_sip_LC25IP,
  input           io_in_sip_LC26IP,
  input           io_in_sip_LC27IP,
  input           io_in_sip_LC28IP,
  input           io_in_sip_LC29IP,
  input           io_in_sip_LC30IP,
  input           io_in_sip_LC31IP,
  input           io_in_sip_LC32IP,
  input           io_in_sip_LC33IP,
  input           io_in_sip_LC34IP,
  input           io_in_sip_LPRASEIP,
  input           io_in_sip_LC36IP,
  input           io_in_sip_LC37IP,
  input           io_in_sip_LC38IP,
  input           io_in_sip_LC39IP,
  input           io_in_sip_LC40IP,
  input           io_in_sip_LC41IP,
  input           io_in_sip_LC42IP,
  input           io_in_sip_HPRASEIP,
  input           io_in_sip_LC44IP,
  input           io_in_sip_LC45IP,
  input           io_in_sip_LC46IP,
  input           io_in_sip_LC47IP,
  input           io_in_sip_LC48IP,
  input           io_in_sip_LC49IP,
  input           io_in_sip_LC50IP,
  input           io_in_sip_LC51IP,
  input           io_in_sip_LC52IP,
  input           io_in_sip_LC53IP,
  input           io_in_sip_LC54IP,
  input           io_in_sip_LC55IP,
  input           io_in_sip_LC56IP,
  input           io_in_sip_LC57IP,
  input           io_in_sip_LC58IP,
  input           io_in_sip_LC59IP,
  input           io_in_sip_LC60IP,
  input           io_in_sip_LC61IP,
  input           io_in_sip_LC62IP,
  input           io_in_sip_LC63IP,
  input           io_in_sie_SSIE,
  input           io_in_sie_STIE,
  input           io_in_sie_SEIE,
  input           io_in_sie_LCOFIE,
  input           io_in_sie_LC14IE,
  input           io_in_sie_LC15IE,
  input           io_in_sie_LC16IE,
  input           io_in_sie_LC17IE,
  input           io_in_sie_LC18IE,
  input           io_in_sie_LC19IE,
  input           io_in_sie_LC20IE,
  input           io_in_sie_LC21IE,
  input           io_in_sie_LC22IE,
  input           io_in_sie_LC23IE,
  input           io_in_sie_LC24IE,
  input           io_in_sie_LC25IE,
  input           io_in_sie_LC26IE,
  input           io_in_sie_LC27IE,
  input           io_in_sie_LC28IE,
  input           io_in_sie_LC29IE,
  input           io_in_sie_LC30IE,
  input           io_in_sie_LC31IE,
  input           io_in_sie_LC32IE,
  input           io_in_sie_LC33IE,
  input           io_in_sie_LC34IE,
  input           io_in_sie_LPRASEIE,
  input           io_in_sie_LC36IE,
  input           io_in_sie_LC37IE,
  input           io_in_sie_LC38IE,
  input           io_in_sie_LC39IE,
  input           io_in_sie_LC40IE,
  input           io_in_sie_LC41IE,
  input           io_in_sie_LC42IE,
  input           io_in_sie_HPRASEIE,
  input           io_in_sie_LC44IE,
  input           io_in_sie_LC45IE,
  input           io_in_sie_LC46IE,
  input           io_in_sie_LC47IE,
  input           io_in_sie_LC48IE,
  input           io_in_sie_LC49IE,
  input           io_in_sie_LC50IE,
  input           io_in_sie_LC51IE,
  input           io_in_sie_LC52IE,
  input           io_in_sie_LC53IE,
  input           io_in_sie_LC54IE,
  input           io_in_sie_LC55IE,
  input           io_in_sie_LC56IE,
  input           io_in_sie_LC57IE,
  input           io_in_sie_LC58IE,
  input           io_in_sie_LC59IE,
  input           io_in_sie_LC60IE,
  input           io_in_sie_LC61IE,
  input           io_in_sie_LC62IE,
  input           io_in_sie_LC63IE,
  input           io_in_hip_VSSIP,
  input           io_in_hip_VSTIP,
  input           io_in_hip_VSEIP,
  input           io_in_hip_SGEIP,
  input           io_in_hie_VSSIE,
  input           io_in_hie_VSTIE,
  input           io_in_hie_VSEIE,
  input           io_in_hie_SGEIE,
  input           io_in_hideleg_SSI,
  input           io_in_hideleg_VSSI,
  input           io_in_hideleg_MSI,
  input           io_in_hideleg_STI,
  input           io_in_hideleg_VSTI,
  input           io_in_hideleg_MTI,
  input           io_in_hideleg_SEI,
  input           io_in_hideleg_VSEI,
  input           io_in_hideleg_MEI,
  input           io_in_hideleg_SGEI,
  input           io_in_hideleg_LCOFI,
  input           io_in_vsip_SSIP,
  input           io_in_vsip_STIP,
  input           io_in_vsip_SEIP,
  input           io_in_vsip_LCOFIP,
  input           io_in_vsip_LC14IP,
  input           io_in_vsip_LC15IP,
  input           io_in_vsip_LC16IP,
  input           io_in_vsip_LC17IP,
  input           io_in_vsip_LC18IP,
  input           io_in_vsip_LC19IP,
  input           io_in_vsip_LC20IP,
  input           io_in_vsip_LC21IP,
  input           io_in_vsip_LC22IP,
  input           io_in_vsip_LC23IP,
  input           io_in_vsip_LC24IP,
  input           io_in_vsip_LC25IP,
  input           io_in_vsip_LC26IP,
  input           io_in_vsip_LC27IP,
  input           io_in_vsip_LC28IP,
  input           io_in_vsip_LC29IP,
  input           io_in_vsip_LC30IP,
  input           io_in_vsip_LC31IP,
  input           io_in_vsip_LC32IP,
  input           io_in_vsip_LC33IP,
  input           io_in_vsip_LC34IP,
  input           io_in_vsip_LPRASEIP,
  input           io_in_vsip_LC36IP,
  input           io_in_vsip_LC37IP,
  input           io_in_vsip_LC38IP,
  input           io_in_vsip_LC39IP,
  input           io_in_vsip_LC40IP,
  input           io_in_vsip_LC41IP,
  input           io_in_vsip_LC42IP,
  input           io_in_vsip_HPRASEIP,
  input           io_in_vsip_LC44IP,
  input           io_in_vsip_LC45IP,
  input           io_in_vsip_LC46IP,
  input           io_in_vsip_LC47IP,
  input           io_in_vsip_LC48IP,
  input           io_in_vsip_LC49IP,
  input           io_in_vsip_LC50IP,
  input           io_in_vsip_LC51IP,
  input           io_in_vsip_LC52IP,
  input           io_in_vsip_LC53IP,
  input           io_in_vsip_LC54IP,
  input           io_in_vsip_LC55IP,
  input           io_in_vsip_LC56IP,
  input           io_in_vsip_LC57IP,
  input           io_in_vsip_LC58IP,
  input           io_in_vsip_LC59IP,
  input           io_in_vsip_LC60IP,
  input           io_in_vsip_LC61IP,
  input           io_in_vsip_LC62IP,
  input           io_in_vsip_LC63IP,
  input           io_in_vsie_SSIE,
  input           io_in_vsie_STIE,
  input           io_in_vsie_SEIE,
  input           io_in_vsie_LCOFIE,
  input           io_in_vsie_LC14IE,
  input           io_in_vsie_LC15IE,
  input           io_in_vsie_LC16IE,
  input           io_in_vsie_LC17IE,
  input           io_in_vsie_LC18IE,
  input           io_in_vsie_LC19IE,
  input           io_in_vsie_LC20IE,
  input           io_in_vsie_LC21IE,
  input           io_in_vsie_LC22IE,
  input           io_in_vsie_LC23IE,
  input           io_in_vsie_LC24IE,
  input           io_in_vsie_LC25IE,
  input           io_in_vsie_LC26IE,
  input           io_in_vsie_LC27IE,
  input           io_in_vsie_LC28IE,
  input           io_in_vsie_LC29IE,
  input           io_in_vsie_LC30IE,
  input           io_in_vsie_LC31IE,
  input           io_in_vsie_LC32IE,
  input           io_in_vsie_LC33IE,
  input           io_in_vsie_LC34IE,
  input           io_in_vsie_LPRASEIE,
  input           io_in_vsie_LC36IE,
  input           io_in_vsie_LC37IE,
  input           io_in_vsie_LC38IE,
  input           io_in_vsie_LC39IE,
  input           io_in_vsie_LC40IE,
  input           io_in_vsie_LC41IE,
  input           io_in_vsie_LC42IE,
  input           io_in_vsie_HPRASEIE,
  input           io_in_vsie_LC44IE,
  input           io_in_vsie_LC45IE,
  input           io_in_vsie_LC46IE,
  input           io_in_vsie_LC47IE,
  input           io_in_vsie_LC48IE,
  input           io_in_vsie_LC49IE,
  input           io_in_vsie_LC50IE,
  input           io_in_vsie_LC51IE,
  input           io_in_vsie_LC52IE,
  input           io_in_vsie_LC53IE,
  input           io_in_vsie_LC54IE,
  input           io_in_vsie_LC55IE,
  input           io_in_vsie_LC56IE,
  input           io_in_vsie_LC57IE,
  input           io_in_vsie_LC58IE,
  input           io_in_vsie_LC59IE,
  input           io_in_vsie_LC60IE,
  input           io_in_vsie_LC61IE,
  input           io_in_vsie_LC62IE,
  input           io_in_vsie_LC63IE,
  input           io_in_hvictl_VTI,
  input  [11:0]   io_in_hvictl_IID,
  input           io_in_hvictl_DPR,
  input           io_in_hvictl_IPRIOM,
  input  [7:0]    io_in_hvictl_IPRIO,
  input  [5:0]    io_in_hstatus_VGEIN,
  input  [10:0]   io_in_mtopei_IPRIO,
  input  [10:0]   io_in_stopei_IPRIO,
  input  [10:0]   io_in_vstopei_IID,
  input  [10:0]   io_in_vstopei_IPRIO,
  input  [7:0]    io_in_hviprio1_PrioSSI,
  input  [7:0]    io_in_hviprio1_PrioSTI,
  input  [7:0]    io_in_hviprio1_PrioCOI,
  input  [7:0]    io_in_hviprio1_Prio14,
  input  [7:0]    io_in_hviprio1_Prio15,
  input  [63:0]   io_in_hviprio2_ALL,
  input           io_in_debugIntr,
  input           io_in_debugMode,
  input           io_in_dcsr_STEPIE,
  input           io_in_dcsr_STEP,
  input  [511:0]  io_in_miprios,
  input  [511:0]  io_in_hsiprios,
  input           io_in_nmi,
  input  [63:0]   io_in_nmiVec,
  input           io_in_mnstatusNMIE,
  input           io_in_platform_meip,
  input           io_in_platform_seip,
  input           io_in_fromAIA_seip,
  input           io_in_mvienSEIE,
  input           io_in_mvipSEIP,
  output          io_out_debug,
  output          io_out_nmi,
  output          io_out_interruptVec_valid,
  output [7:0]    io_out_interruptVec_bits,
  output [11:0]   io_out_mtopi_IID,
  output [7:0]    io_out_mtopi_IPRIO,
  output [11:0]   io_out_stopi_IID,
  output [7:0]    io_out_stopi_IPRIO,
  output [11:0]   io_out_vstopi_IID,
  output [7:0]    io_out_vstopi_IPRIO,
  output          io_out_virtualInterruptIsHvictlInject,
  output          io_out_irToHS,
  output          io_out_irToVS
);

  // ---- 十个中断位域 bundle 还原成 64 位向量（位号 = 中断号）----------------
  logic [63:0] mip_bits;
  logic [63:0] mie_bits;
  logic [63:0] mideleg_bits;
  logic [63:0] sip_bits;
  logic [63:0] sie_bits;
  logic [63:0] hip_bits;
  logic [63:0] hie_bits;
  logic [63:0] hideleg_bits;
  logic [63:0] vsip_bits;
  logic [63:0] vsie_bits;
  // ---- AIA 的 hviprio1/hviprio2 拼成 128 位优先级数组 ---------------------
  logic [127:0] hviprios_bits;

  always_comb begin
    mip_bits = 64'h0;
    mip_bits[1 ] = io_in_mip_SSIP;
    mip_bits[2 ] = io_in_mip_VSSIP;
    mip_bits[3 ] = io_in_mip_MSIP;
    mip_bits[5 ] = io_in_mip_STIP;
    mip_bits[6 ] = io_in_mip_VSTIP;
    mip_bits[7 ] = io_in_mip_MTIP;
    mip_bits[9 ] = io_in_mip_SEIP;
    mip_bits[10] = io_in_mip_VSEIP;
    mip_bits[11] = io_in_mip_MEIP;
    mip_bits[12] = io_in_mip_SGEIP;
    mip_bits[13] = io_in_mip_LCOFIP;
  end

  always_comb begin
    mie_bits = 64'h0;
    mie_bits[1 ] = io_in_mie_SSIE;
    mie_bits[2 ] = io_in_mie_VSSIE;
    mie_bits[3 ] = io_in_mie_MSIE;
    mie_bits[5 ] = io_in_mie_STIE;
    mie_bits[6 ] = io_in_mie_VSTIE;
    mie_bits[7 ] = io_in_mie_MTIE;
    mie_bits[9 ] = io_in_mie_SEIE;
    mie_bits[10] = io_in_mie_VSEIE;
    mie_bits[11] = io_in_mie_MEIE;
    mie_bits[12] = io_in_mie_SGEIE;
    mie_bits[13] = io_in_mie_LCOFIE;
  end

  always_comb begin
    mideleg_bits = 64'h0;
    // 端口没给出的位：VS 级三个 + SGEI 恒为 1（永远委托），
    // M 级三个恒为 0（永远不委托）—— 见 gen.py 的 HARDWIRED_MIDELEG。
    mideleg_bits[2] = 1'b1;
    mideleg_bits[3] = 1'b0;
    mideleg_bits[6] = 1'b1;
    mideleg_bits[7] = 1'b0;
    mideleg_bits[10] = 1'b1;
    mideleg_bits[11] = 1'b0;
    mideleg_bits[12] = 1'b1;
    mideleg_bits[1 ] = io_in_mideleg_SSI;
    mideleg_bits[5 ] = io_in_mideleg_STI;
    mideleg_bits[9 ] = io_in_mideleg_SEI;
    mideleg_bits[13] = io_in_mideleg_LCOFI;
  end

  always_comb begin
    sip_bits = 64'h0;
    sip_bits[1 ] = io_in_sip_SSIP;
    sip_bits[5 ] = io_in_sip_STIP;
    sip_bits[9 ] = io_in_sip_SEIP;
    sip_bits[13] = io_in_sip_LCOFIP;
    sip_bits[14] = io_in_sip_LC14IP;
    sip_bits[15] = io_in_sip_LC15IP;
    sip_bits[16] = io_in_sip_LC16IP;
    sip_bits[17] = io_in_sip_LC17IP;
    sip_bits[18] = io_in_sip_LC18IP;
    sip_bits[19] = io_in_sip_LC19IP;
    sip_bits[20] = io_in_sip_LC20IP;
    sip_bits[21] = io_in_sip_LC21IP;
    sip_bits[22] = io_in_sip_LC22IP;
    sip_bits[23] = io_in_sip_LC23IP;
    sip_bits[24] = io_in_sip_LC24IP;
    sip_bits[25] = io_in_sip_LC25IP;
    sip_bits[26] = io_in_sip_LC26IP;
    sip_bits[27] = io_in_sip_LC27IP;
    sip_bits[28] = io_in_sip_LC28IP;
    sip_bits[29] = io_in_sip_LC29IP;
    sip_bits[30] = io_in_sip_LC30IP;
    sip_bits[31] = io_in_sip_LC31IP;
    sip_bits[32] = io_in_sip_LC32IP;
    sip_bits[33] = io_in_sip_LC33IP;
    sip_bits[34] = io_in_sip_LC34IP;
    sip_bits[35] = io_in_sip_LPRASEIP;
    sip_bits[36] = io_in_sip_LC36IP;
    sip_bits[37] = io_in_sip_LC37IP;
    sip_bits[38] = io_in_sip_LC38IP;
    sip_bits[39] = io_in_sip_LC39IP;
    sip_bits[40] = io_in_sip_LC40IP;
    sip_bits[41] = io_in_sip_LC41IP;
    sip_bits[42] = io_in_sip_LC42IP;
    sip_bits[43] = io_in_sip_HPRASEIP;
    sip_bits[44] = io_in_sip_LC44IP;
    sip_bits[45] = io_in_sip_LC45IP;
    sip_bits[46] = io_in_sip_LC46IP;
    sip_bits[47] = io_in_sip_LC47IP;
    sip_bits[48] = io_in_sip_LC48IP;
    sip_bits[49] = io_in_sip_LC49IP;
    sip_bits[50] = io_in_sip_LC50IP;
    sip_bits[51] = io_in_sip_LC51IP;
    sip_bits[52] = io_in_sip_LC52IP;
    sip_bits[53] = io_in_sip_LC53IP;
    sip_bits[54] = io_in_sip_LC54IP;
    sip_bits[55] = io_in_sip_LC55IP;
    sip_bits[56] = io_in_sip_LC56IP;
    sip_bits[57] = io_in_sip_LC57IP;
    sip_bits[58] = io_in_sip_LC58IP;
    sip_bits[59] = io_in_sip_LC59IP;
    sip_bits[60] = io_in_sip_LC60IP;
    sip_bits[61] = io_in_sip_LC61IP;
    sip_bits[62] = io_in_sip_LC62IP;
    sip_bits[63] = io_in_sip_LC63IP;
  end

  always_comb begin
    sie_bits = 64'h0;
    sie_bits[1 ] = io_in_sie_SSIE;
    sie_bits[5 ] = io_in_sie_STIE;
    sie_bits[9 ] = io_in_sie_SEIE;
    sie_bits[13] = io_in_sie_LCOFIE;
    sie_bits[14] = io_in_sie_LC14IE;
    sie_bits[15] = io_in_sie_LC15IE;
    sie_bits[16] = io_in_sie_LC16IE;
    sie_bits[17] = io_in_sie_LC17IE;
    sie_bits[18] = io_in_sie_LC18IE;
    sie_bits[19] = io_in_sie_LC19IE;
    sie_bits[20] = io_in_sie_LC20IE;
    sie_bits[21] = io_in_sie_LC21IE;
    sie_bits[22] = io_in_sie_LC22IE;
    sie_bits[23] = io_in_sie_LC23IE;
    sie_bits[24] = io_in_sie_LC24IE;
    sie_bits[25] = io_in_sie_LC25IE;
    sie_bits[26] = io_in_sie_LC26IE;
    sie_bits[27] = io_in_sie_LC27IE;
    sie_bits[28] = io_in_sie_LC28IE;
    sie_bits[29] = io_in_sie_LC29IE;
    sie_bits[30] = io_in_sie_LC30IE;
    sie_bits[31] = io_in_sie_LC31IE;
    sie_bits[32] = io_in_sie_LC32IE;
    sie_bits[33] = io_in_sie_LC33IE;
    sie_bits[34] = io_in_sie_LC34IE;
    sie_bits[35] = io_in_sie_LPRASEIE;
    sie_bits[36] = io_in_sie_LC36IE;
    sie_bits[37] = io_in_sie_LC37IE;
    sie_bits[38] = io_in_sie_LC38IE;
    sie_bits[39] = io_in_sie_LC39IE;
    sie_bits[40] = io_in_sie_LC40IE;
    sie_bits[41] = io_in_sie_LC41IE;
    sie_bits[42] = io_in_sie_LC42IE;
    sie_bits[43] = io_in_sie_HPRASEIE;
    sie_bits[44] = io_in_sie_LC44IE;
    sie_bits[45] = io_in_sie_LC45IE;
    sie_bits[46] = io_in_sie_LC46IE;
    sie_bits[47] = io_in_sie_LC47IE;
    sie_bits[48] = io_in_sie_LC48IE;
    sie_bits[49] = io_in_sie_LC49IE;
    sie_bits[50] = io_in_sie_LC50IE;
    sie_bits[51] = io_in_sie_LC51IE;
    sie_bits[52] = io_in_sie_LC52IE;
    sie_bits[53] = io_in_sie_LC53IE;
    sie_bits[54] = io_in_sie_LC54IE;
    sie_bits[55] = io_in_sie_LC55IE;
    sie_bits[56] = io_in_sie_LC56IE;
    sie_bits[57] = io_in_sie_LC57IE;
    sie_bits[58] = io_in_sie_LC58IE;
    sie_bits[59] = io_in_sie_LC59IE;
    sie_bits[60] = io_in_sie_LC60IE;
    sie_bits[61] = io_in_sie_LC61IE;
    sie_bits[62] = io_in_sie_LC62IE;
    sie_bits[63] = io_in_sie_LC63IE;
  end

  always_comb begin
    hip_bits = 64'h0;
    hip_bits[2 ] = io_in_hip_VSSIP;
    hip_bits[6 ] = io_in_hip_VSTIP;
    hip_bits[10] = io_in_hip_VSEIP;
    hip_bits[12] = io_in_hip_SGEIP;
  end

  always_comb begin
    hie_bits = 64'h0;
    hie_bits[2 ] = io_in_hie_VSSIE;
    hie_bits[6 ] = io_in_hie_VSTIE;
    hie_bits[10] = io_in_hie_VSEIE;
    hie_bits[12] = io_in_hie_SGEIE;
  end

  always_comb begin
    hideleg_bits = 64'h0;
    hideleg_bits[1 ] = io_in_hideleg_SSI;
    hideleg_bits[2 ] = io_in_hideleg_VSSI;
    hideleg_bits[3 ] = io_in_hideleg_MSI;
    hideleg_bits[5 ] = io_in_hideleg_STI;
    hideleg_bits[6 ] = io_in_hideleg_VSTI;
    hideleg_bits[7 ] = io_in_hideleg_MTI;
    hideleg_bits[9 ] = io_in_hideleg_SEI;
    hideleg_bits[10] = io_in_hideleg_VSEI;
    hideleg_bits[11] = io_in_hideleg_MEI;
    hideleg_bits[12] = io_in_hideleg_SGEI;
    hideleg_bits[13] = io_in_hideleg_LCOFI;
  end

  always_comb begin
    vsip_bits = 64'h0;
    vsip_bits[1 ] = io_in_vsip_SSIP;
    vsip_bits[5 ] = io_in_vsip_STIP;
    vsip_bits[9 ] = io_in_vsip_SEIP;
    vsip_bits[13] = io_in_vsip_LCOFIP;
    vsip_bits[14] = io_in_vsip_LC14IP;
    vsip_bits[15] = io_in_vsip_LC15IP;
    vsip_bits[16] = io_in_vsip_LC16IP;
    vsip_bits[17] = io_in_vsip_LC17IP;
    vsip_bits[18] = io_in_vsip_LC18IP;
    vsip_bits[19] = io_in_vsip_LC19IP;
    vsip_bits[20] = io_in_vsip_LC20IP;
    vsip_bits[21] = io_in_vsip_LC21IP;
    vsip_bits[22] = io_in_vsip_LC22IP;
    vsip_bits[23] = io_in_vsip_LC23IP;
    vsip_bits[24] = io_in_vsip_LC24IP;
    vsip_bits[25] = io_in_vsip_LC25IP;
    vsip_bits[26] = io_in_vsip_LC26IP;
    vsip_bits[27] = io_in_vsip_LC27IP;
    vsip_bits[28] = io_in_vsip_LC28IP;
    vsip_bits[29] = io_in_vsip_LC29IP;
    vsip_bits[30] = io_in_vsip_LC30IP;
    vsip_bits[31] = io_in_vsip_LC31IP;
    vsip_bits[32] = io_in_vsip_LC32IP;
    vsip_bits[33] = io_in_vsip_LC33IP;
    vsip_bits[34] = io_in_vsip_LC34IP;
    vsip_bits[35] = io_in_vsip_LPRASEIP;
    vsip_bits[36] = io_in_vsip_LC36IP;
    vsip_bits[37] = io_in_vsip_LC37IP;
    vsip_bits[38] = io_in_vsip_LC38IP;
    vsip_bits[39] = io_in_vsip_LC39IP;
    vsip_bits[40] = io_in_vsip_LC40IP;
    vsip_bits[41] = io_in_vsip_LC41IP;
    vsip_bits[42] = io_in_vsip_LC42IP;
    vsip_bits[43] = io_in_vsip_HPRASEIP;
    vsip_bits[44] = io_in_vsip_LC44IP;
    vsip_bits[45] = io_in_vsip_LC45IP;
    vsip_bits[46] = io_in_vsip_LC46IP;
    vsip_bits[47] = io_in_vsip_LC47IP;
    vsip_bits[48] = io_in_vsip_LC48IP;
    vsip_bits[49] = io_in_vsip_LC49IP;
    vsip_bits[50] = io_in_vsip_LC50IP;
    vsip_bits[51] = io_in_vsip_LC51IP;
    vsip_bits[52] = io_in_vsip_LC52IP;
    vsip_bits[53] = io_in_vsip_LC53IP;
    vsip_bits[54] = io_in_vsip_LC54IP;
    vsip_bits[55] = io_in_vsip_LC55IP;
    vsip_bits[56] = io_in_vsip_LC56IP;
    vsip_bits[57] = io_in_vsip_LC57IP;
    vsip_bits[58] = io_in_vsip_LC58IP;
    vsip_bits[59] = io_in_vsip_LC59IP;
    vsip_bits[60] = io_in_vsip_LC60IP;
    vsip_bits[61] = io_in_vsip_LC61IP;
    vsip_bits[62] = io_in_vsip_LC62IP;
    vsip_bits[63] = io_in_vsip_LC63IP;
  end

  always_comb begin
    vsie_bits = 64'h0;
    vsie_bits[1 ] = io_in_vsie_SSIE;
    vsie_bits[5 ] = io_in_vsie_STIE;
    vsie_bits[9 ] = io_in_vsie_SEIE;
    vsie_bits[13] = io_in_vsie_LCOFIE;
    vsie_bits[14] = io_in_vsie_LC14IE;
    vsie_bits[15] = io_in_vsie_LC15IE;
    vsie_bits[16] = io_in_vsie_LC16IE;
    vsie_bits[17] = io_in_vsie_LC17IE;
    vsie_bits[18] = io_in_vsie_LC18IE;
    vsie_bits[19] = io_in_vsie_LC19IE;
    vsie_bits[20] = io_in_vsie_LC20IE;
    vsie_bits[21] = io_in_vsie_LC21IE;
    vsie_bits[22] = io_in_vsie_LC22IE;
    vsie_bits[23] = io_in_vsie_LC23IE;
    vsie_bits[24] = io_in_vsie_LC24IE;
    vsie_bits[25] = io_in_vsie_LC25IE;
    vsie_bits[26] = io_in_vsie_LC26IE;
    vsie_bits[27] = io_in_vsie_LC27IE;
    vsie_bits[28] = io_in_vsie_LC28IE;
    vsie_bits[29] = io_in_vsie_LC29IE;
    vsie_bits[30] = io_in_vsie_LC30IE;
    vsie_bits[31] = io_in_vsie_LC31IE;
    vsie_bits[32] = io_in_vsie_LC32IE;
    vsie_bits[33] = io_in_vsie_LC33IE;
    vsie_bits[34] = io_in_vsie_LC34IE;
    vsie_bits[35] = io_in_vsie_LPRASEIE;
    vsie_bits[36] = io_in_vsie_LC36IE;
    vsie_bits[37] = io_in_vsie_LC37IE;
    vsie_bits[38] = io_in_vsie_LC38IE;
    vsie_bits[39] = io_in_vsie_LC39IE;
    vsie_bits[40] = io_in_vsie_LC40IE;
    vsie_bits[41] = io_in_vsie_LC41IE;
    vsie_bits[42] = io_in_vsie_LC42IE;
    vsie_bits[43] = io_in_vsie_HPRASEIE;
    vsie_bits[44] = io_in_vsie_LC44IE;
    vsie_bits[45] = io_in_vsie_LC45IE;
    vsie_bits[46] = io_in_vsie_LC46IE;
    vsie_bits[47] = io_in_vsie_LC47IE;
    vsie_bits[48] = io_in_vsie_LC48IE;
    vsie_bits[49] = io_in_vsie_LC49IE;
    vsie_bits[50] = io_in_vsie_LC50IE;
    vsie_bits[51] = io_in_vsie_LC51IE;
    vsie_bits[52] = io_in_vsie_LC52IE;
    vsie_bits[53] = io_in_vsie_LC53IE;
    vsie_bits[54] = io_in_vsie_LC54IE;
    vsie_bits[55] = io_in_vsie_LC55IE;
    vsie_bits[56] = io_in_vsie_LC56IE;
    vsie_bits[57] = io_in_vsie_LC57IE;
    vsie_bits[58] = io_in_vsie_LC58IE;
    vsie_bits[59] = io_in_vsie_LC59IE;
    vsie_bits[60] = io_in_vsie_LC60IE;
    vsie_bits[61] = io_in_vsie_LC61IE;
    vsie_bits[62] = io_in_vsie_LC62IE;
    vsie_bits[63] = io_in_vsie_LC63IE;
  end

  always_comb begin
    hviprios_bits = 128'h0;
    hviprios_bits[15:8] = io_in_hviprio1_PrioSSI;
    hviprios_bits[31:24] = io_in_hviprio1_PrioSTI;
    hviprios_bits[47:40] = io_in_hviprio1_PrioCOI;
    hviprios_bits[55:48] = io_in_hviprio1_Prio14;
    hviprios_bits[63:56] = io_in_hviprio1_Prio15;
    hviprios_bits[127:64] = io_in_hviprio2_ALL;
  end

  xs_InterruptFilter_core u_core (
    .clock                              (clock),
    .reset                              (reset),
    .mip                                (mip_bits),
    .mie                                (mie_bits),
    .mideleg                            (mideleg_bits),
    .sip                                (sip_bits),
    .sie                                (sie_bits),
    .hip                                (hip_bits),
    .hie                                (hie_bits),
    .hideleg                            (hideleg_bits),
    .vsip                               (vsip_bits),
    .vsie                               (vsie_bits),
    .hviprios                           (hviprios_bits),
    .privState_PRVM                     (io_in_privState_PRVM),
    .privState_V                        (io_in_privState_V),
    .mstatusMIE                         (io_in_mstatusMIE),
    .sstatusSIE                         (io_in_sstatusSIE),
    .vsstatusSIE                        (io_in_vsstatusSIE),
    .hvictl_VTI                         (io_in_hvictl_VTI),
    .hvictl_IID                         (io_in_hvictl_IID),
    .hvictl_DPR                         (io_in_hvictl_DPR),
    .hvictl_IPRIOM                      (io_in_hvictl_IPRIOM),
    .hvictl_IPRIO                       (io_in_hvictl_IPRIO),
    .hstatus_VGEIN                      (io_in_hstatus_VGEIN),
    .mtopei_IPRIO                       (io_in_mtopei_IPRIO),
    .stopei_IPRIO                       (io_in_stopei_IPRIO),
    .vstopei_IID                        (io_in_vstopei_IID),
    .vstopei_IPRIO                      (io_in_vstopei_IPRIO),
    .debugIntr                          (io_in_debugIntr),
    .debugMode                          (io_in_debugMode),
    .dcsr_STEPIE                        (io_in_dcsr_STEPIE),
    .dcsr_STEP                          (io_in_dcsr_STEP),
    .miprios                            (io_in_miprios),
    .hsiprios                           (io_in_hsiprios),
    .nmi                                (io_in_nmi),
    .nmiVec                             (io_in_nmiVec),
    .mnstatusNMIE                       (io_in_mnstatusNMIE),
    .platform_meip                      (io_in_platform_meip),
    .platform_seip                      (io_in_platform_seip),
    .fromAIA_seip                       (io_in_fromAIA_seip),
    .mvienSEIE                          (io_in_mvienSEIE),
    .mvipSEIP                           (io_in_mvipSEIP),
    .out_debug                          (io_out_debug),
    .out_nmi                            (io_out_nmi),
    .out_interruptVec_valid             (io_out_interruptVec_valid),
    .out_interruptVec_bits              (io_out_interruptVec_bits),
    .out_mtopi_IID                      (io_out_mtopi_IID),
    .out_mtopi_IPRIO                    (io_out_mtopi_IPRIO),
    .out_stopi_IID                      (io_out_stopi_IID),
    .out_stopi_IPRIO                    (io_out_stopi_IPRIO),
    .out_vstopi_IID                     (io_out_vstopi_IID),
    .out_vstopi_IPRIO                   (io_out_vstopi_IPRIO),
    .out_virtualInterruptIsHvictlInject (io_out_virtualInterruptIsHvictlInject),
    .out_irToHS                         (io_out_irToHS),
    .out_irToVS                         (io_out_irToVS)
  );

endmodule
// END GENERATED
