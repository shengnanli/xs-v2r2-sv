// =============================================================================
//  loadmisalignbuffer_pkg —— LoadMisalignBuffer 可读核的类型/常量/纯函数包
// -----------------------------------------------------------------------------
//  设计意图来源：src/main/scala/xiangshan/mem/lsqueue/LoadMisalignBuffer.scala
//
//  LoadMisalignBuffer 处理「跨 16B 边界的非对齐 load」：当 LoadUnit 发现一条 load
//  的访问区间 [vaddr, vaddr+size-1] 跨越 16 字节边界时，把它丢进本缓冲；本缓冲把它
//  拆成两次「不跨界的对齐子 load」(low/high)，依次发往 LoadUnit 的 misalign 重发口，
//  收齐两次结果后按字节掩码拼成原始数据、做符号/零扩展，再写回 ROB(标量) 或
//  VecMergeBuffer(向量)。
//
//  本包集中：
//    - enum  fsm_state_e : 6 态拆分状态机（idle/split/req/resp/comb/wb）
//    - enum  size_e      : load 访问宽度编码（LB/LH/LW/LD = 0/1/2/3，对应 1/2/4/8B）
//    - function getMask        : size → 字节使能掩码（lb=1,lh=3,lw=f,ld=ff）
//    - function shiftAndTruncate: 把某次子 load 的 64b 数据右移 shift 字节、再截
//                                 truncate 字节（用于从对齐读回的数据里抠出有效段）
//  逐字节拼接(catResult)、合并(combinedData)在核里用 for 循环表达，见 core 文件。
// =============================================================================
package loadmisalignbuffer_pkg;

  // ---- 体系结构参数（本配置固定值，注明物理含义）----
  localparam int XLEN      = 64;   // 标量通用寄存器/标量 load 数据位宽
  localparam int VLEN      = 128;  // 向量寄存器位宽
  localparam int VADDR     = 50;   // 虚地址位宽（io_*_vaddr）
  localparam int MASKW     = 16;   // 字节掩码位宽（覆盖 16B 对齐窗口）
  localparam int MAX_SPLIT = 2;    // 一条非对齐 load 最多拆成 2 次对齐子 load

  // ---- 拆分状态机 ----
  //  s_idle           : 空闲，等待 enq 锁存一条非对齐 load
  //  s_split          : 依 size 与低位地址，把请求拆成 low/high 两次对齐子 load
  //  s_req            : 把当前 curPtr 指向的子 load 发往 splitLoadReq
  //  s_resp           : 等子 load 回应；异常/uncache 直接收尾，need_rep/未发完则回 s_req
  //  s_comb_wakeup_rep: 合并两次数据；标量还需再发一次「唤醒(wakeup) load」
  //  s_wb             : 写回 ROB / VecMergeBuffer
  typedef enum logic [2:0] {
    S_IDLE            = 3'd0,
    S_SPLIT           = 3'd1,
    S_REQ             = 3'd2,
    S_RESP            = 3'd3,
    S_COMB_WAKEUP_REP = 3'd4,
    S_WB              = 3'd5
  } fsm_state_e;

  // ---- load 访问宽度编码（fuOpType[1:0] / alignedType[1:0]）----
  typedef enum logic [1:0] {
    SZ_B = 2'b00,  // byte    1B
    SZ_H = 2'b01,  // half    2B
    SZ_W = 2'b10,  // word    4B
    SZ_D = 2'b11   // double  8B
  } size_e;

  // 字节移位/截断量编码：0..7 字节，直接用数值，无需 enum。

  // ---- size → 字节使能掩码（对齐到地址低位前的「基」掩码长度）----
  function automatic logic [7:0] getMask(input size_e sz);
    case (sz)
      SZ_B: getMask = 8'h01;
      SZ_H: getMask = 8'h03;
      SZ_W: getMask = 8'h0f;
      SZ_D: getMask = 8'hff;
    endcase
  endfunction

  // ---- 子 load 数据抽取：先右移 shift 字节，再截取 trunc 字节、零填高位 ----
  //  对齐子 load 读回的是某个 8B 对齐字内的数据；原始非对齐访问只用其中一段，
  //  shift 给出该段在 8B 字内的字节起点，trunc 给出该段长度（字节）。
  //  trunc=0 表示「不取」（该侧不贡献字节），返回 0。
  function automatic logic [XLEN-1:0] shiftAndTruncate(
      input logic [2:0]      shift,
      input logic [2:0]      trunc,
      input logic [XLEN-1:0] data);
    logic [XLEN-1:0] shifted;
    shifted = data >> (8 * shift);   // 右移 shift 个字节
    case (trunc)
      3'd0: shiftAndTruncate = '0;                       // 0 字节宽，不取
      3'd1: shiftAndTruncate = {{(XLEN-8){1'b0}},  shifted[7:0]};
      3'd2: shiftAndTruncate = {{(XLEN-16){1'b0}}, shifted[15:0]};
      3'd3: shiftAndTruncate = {{(XLEN-24){1'b0}}, shifted[23:0]};
      3'd4: shiftAndTruncate = {{(XLEN-32){1'b0}}, shifted[31:0]};
      3'd5: shiftAndTruncate = {{(XLEN-40){1'b0}}, shifted[39:0]};
      3'd6: shiftAndTruncate = {{(XLEN-48){1'b0}}, shifted[47:0]};
      3'd7: shiftAndTruncate = {{(XLEN-56){1'b0}}, shifted[55:0]};
    endcase
  endfunction

  // ---- 环形指针冲刷判定（robIdx 是否被 redirect 命中）----
  //  level=1：冲刷自身及之后；level=0：仅冲刷严格之后者。
  function automatic logic robNeedFlush(
      input logic       v_flag,  input logic [7:0] v_value,
      input logic       r_flag,  input logic [7:0] r_value,
      input logic       redirect_valid, input logic redirect_level);
    logic flushItself, isAfter;
    flushItself = redirect_level & (v_flag == r_flag) & (v_value == r_value);
    // isAfter: v 在环形序上严格晚于 r
    isAfter = (v_flag ^ r_flag) ^ (v_value > r_value);
    robNeedFlush = redirect_valid & (isAfter | flushItself);
  endfunction

endpackage
