// =============================================================================
// IBuffer.sv —— 前端取指缓冲(instruction buffer):IFU 与 Decode 之间的解耦队列
// 设计源:XiangShan src/main/scala/xiangshan/frontend/IBuffer.scala(class IBuffer)
// golden 对照:G1-canonical/golden-rtl/IBuffer.sv(23766 行,441 端口,真叶子)
// 配置:KunminghuV2Config —— IBufSize=48 / IBufNBank=6 / DecodeWidth=6 /
//      PredictWidth=16(全部从 golden 实测,见 §1 每个常量的实测出处)
//
// ★ 它是什么 ★
// 上游 IFU 一次最多送 16 条指令(一个取指块),下游 Decode 一次最多收 6 条。
// IBuffer 把这两个不同宽度的节奏解耦:48 项的循环队列,一拍最多入 16 条、
// 出 6 条,再挂一级**输出寄存器**(outputEntries)给 Decode 看。
//
// ★ 三个不显然的机制 ★
//  1. 「分 bank 的读口」(§6):48 项按 6 个 bank 交错存放(entry e 属于 bank e%6)。
//     出队每拍最多从每个 bank 取 1 项,于是读口从「48 选 1 × 6 组」降成
//     「8 选 1 × 6 组 + 6 选 1 × 6 组」两级,面积小得多。代价是多了三组指针:
//     deqPtr(全局)、deqBankPtrVec(当前 6 个出口各看哪个 bank)、
//     deqInBankPtr(每个 bank 内部读到第几项)。三者必须同步推进(§7)。
//  2. 「旁路(bypass)」(§5):队列空且 Decode 能收时,入队数据**不进队列**,
//     直接写进输出寄存器,省一拍延迟。这条路上 ibuf 的写选择也要跟着改
//     (bypass 掉的前 6 条不占队列表项,见 §4 的 useBypassMatch)。
//  3. 「输出寄存器的部分填充」(§8):Decode 不收但输出寄存器没满时,把已有的
//     有效项压在低位、新出队的项接在后面 —— 这就是 outputEntriesValidNum 与
//     「i - validNum」那个移位读。**移位索引会越界**,golden 的越界语义是
//     「读第 0 项」而不是 0,也不是回绕(§8 有实测证据),照「没查到就是 0」写就是真 bug。
//
// ★ 复位域(golden 实测,两个 always 块逐个分类)★
//   golden 9142-21464:always @(posedge clock or posedge reset) —— **异步复位**,
//     ibuf 48 项 × 17 字段 / outputEntries 6 项 / 全部指针 / allowEnq / afterInit /
//     headBubble / topdown_stage 38 位,复位值见 §9(指针是 0,1,2,... 不是全 0)。
//   golden 21465-21484:always @(posedge clock) —— **完全不复位**,只有 9 个
//     perf 计数信号的两级打拍寄存器(§10)。
//
// ★ 三处「多份 vs 一份」,照 golden 不照 Chisel(★本轮最容易翻车的一条★)★
//   Chisel 写的是 `enqPtrVec = RegInit(VecInit.tabulate(16)(...))`,每个元素都是
//   完整的 CircularQueuePtr(flag + value)。golden 实测:
//     - enqPtrVec:16 个 value,**只有 1 个 flag**(enqPtrVec_0_flag)。
//       因为只有 enqPtr(0).flag 被读(useBypass / numValid),其余 15 个 flag
//       没有读者、被 firtool 消掉。多生成 15 个 = impl 侧凭空多 15 个寄存器,FM 立刻失配。
//     - deqBankPtrVec:6 个 value,**一个 flag 都没有**(同理,bank 指针的 flag 没人读)。
//     - deqInBankPtr :6 个 value **加 6 个 flag**。这 6 个 flag 唯一的读者是它
//       自己的次态(flag_next = 进位位),自环死寄存器 —— firtool 没消它,所以
//       本核也**必须保留**,否则 FM 少 6 个比对点。它们在 FM 里会是 unread 点。
//   这三处如果按 Chisel 字面「每个指针都有 flag」写,前两处会多 21 个寄存器。
//
// ★ 两处 golden 里「有声明没读者」的悬空线,本核**故意不生成** ★
//   (a) empty_probe / exHalf_probe / ibuffer_IDWidth_hvButNotFull_probe
//       (golden 8443-8447):对应 Chisel 的 XSPerfAccumulate,perf 端口在本配置下
//       被裁掉,只剩悬空 wire。纯组合不产生 FM 比对点。
//   (b) golden 8080 的 _GEN_140 与 8089-8094 的两个判据:只被 `ifndef SYNTHESIS
//       里的 XSError 读。FM 两侧与 UT 都带 -define SYNTHESIS,整块不参与判定。
//       它表达的两条不变量写在 §7 与 §11 的注释里。
//
// ★ debug_seqNum:golden 里是 6 组「恒写 0」的寄存器 ★
//   Chisel 的 IBufEntry 有 debug_seqNum 字段,但 FetchToIBuffer 侧没有对应输入
//   (golden 端口表里一个 io_in_bits_debug_seqNum_* 都没有)。于是:
//     - ibuf 的 48 项**不存** debug_seqNum(golden 的 ibuf_N_* 里没有这两个字段);
//     - outputEntries 的 6 项**存**,但写进去的永远是常数 0(带使能,见 §8)。
//   照抄:out_seqnum/out_uopidx 是真寄存器(FM 比对点),值恒 0。
//
// =============================================================================
// 本文件导航（共 1718 行；按"一个 golden 模块一个文件"的规范不拆分，用下面的分节定位）：
//   L128   xs_IBuffer_core —— 可读核
//   L192   §1 队列状态寄存器
//   L223   §2 队列占用量与基本流控
//   L225   distanceBetween(enqPtr, deqPtr):同 flag 直接相减,异 flag 加一圈(48)
//   L288   §3 入队数据成形(16 条 lane 各一份)
//   L290   enqOffset(i) = 本块中排在 i 前面的**有效**槽数 —— 即第 i 条指令是本块的第几条
//   L332   §4 入队写选择(48 项 × 16 lane 的 one-hot)
//   L341   每条 lane 先算出「查 enqPtrVec 的哪一格」与「这拍算不算数」,再与 48 项逐项比
//   L373   §5 旁路(队列空 + Decode 能收):入队数据直接送输出寄存器
//   L394   §6 出队读口:两级 Mux(bank 内 8 选 1,再 bank 间 6 选 1)
//   L424   §7 出队数量掩码与指针推进量
//   L426   下一拍输出寄存器里会有几条有效
//   L493   §8 输出寄存器的下一拍值
//   L531   §9 主时序块 —— 异步复位域(golden 唯一的 posedge reset 块)
//   L631   §10 perf —— ★ 无复位域 ★(golden 第二个 always 块没有 reset 臂)
//   L693   §11 输出:异常向量译码与 topdown 停顿归因
//   L695   exceptionType 的 3 位编码(IBufferExceptionType):
//   L743   §12 设计不变量(与 golden 的 XSError 同义,仅仿真)
//

package ibuffer_pkg;

  // ---- 规模常量。全部从 G1 golden 实测,右侧注明实测出处 ----
  localparam int IBUF_SIZE  = 48;  // golden 的 ibuf_0..ibuf_47 共 48 组寄存器
  localparam int IBUF_NBANK = 6;   // golden readStage1_0 取 ibuf_{0,6,12,..,42} ⇒ 步长 6
  localparam int BANK_SIZE  = IBUF_SIZE / IBUF_NBANK;  // 8
  localparam int DECODE_W   = 6;   // golden 的 io_out_0..5
  localparam int PREDICT_W  = 16;  // golden 的 io_in_bits_instrs_0..15
  localparam int NREASON    = 38;  // golden 的 topdown_stage_reasons_0..37

  // 指针位宽。CircularQueuePtr 的 value 宽 = log2Ceil(entries)。
  localparam int PTR_W     = 6;  // log2Ceil(48) —— golden 的 reg [5:0] deqPtr_value
  localparam int BANKPTR_W = 3;  // log2Ceil(6)  —— golden 的 reg [2:0] deqBankPtrVec_0_value
  localparam int INBANK_W  = 3;  // log2Ceil(8)  —— golden 的 reg [2:0] deqInBankPtr_0_value
  localparam int OFF_W     = 4;  // enqOffset —— golden 的 wire [3:0] enqOffset_1
  localparam int CNT_W     = 3;  // log2Ceil(DecodeWidth) —— golden 的 wire [2:0] numOut
  localparam int FETCH_W   = 5;  // PopCount(16 位) —— golden 的 wire [4:0] numFromFetch
  localparam int REASON_W  = 6;  // log2Up(38) —— golden 的 output [5:0] io_stallReason_reason_0

  // 队列表项。字段顺序与 golden 的 ibuf_N_* 声明顺序一致,便于与 golden 对读。
  // ★ 没有 debug_seqNum ★ —— 见文件头说明。
  typedef struct packed {
    logic [31:0] inst;
    logic [49:0] pc;
    logic [9:0]  foldpc;
    logic        pd_valid;
    logic        pd_isRVC;
    logic [1:0]  pd_brType;
    logic        pd_isCall;
    logic        pd_isRet;
    logic        pred_taken;
    logic        ftqPtr_flag;
    logic [5:0]  ftqPtr_value;
    logic [3:0]  ftqOffset;
    // 3 位编码:{crossPage 或 rvcIll, fetchExcp[1:0]}。译码见 §11。
    logic [2:0]  exceptionType;
    logic        backendException;
    logic        satpFlushFirstFetchFault;
    logic [3:0]  triggered;
    logic        isLastInFtqEntry;
  } ibuf_entry_t;

endpackage : ibuffer_pkg

// =============================================================================
// xs_IBuffer_core —— 可读核
// =============================================================================
module xs_IBuffer_core
  import ibuffer_pkg::*;
(
  input  logic clock,
  input  logic reset,                 // 异步高有效

  // ---- 冲刷与 topdown 归因 ----
  input  logic flush,
  input  logic ctrl_redirect,
  input  logic ctrl_btb_miss,
  input  logic tage_miss,
  input  logic sc_miss,
  input  logic ittage_miss,
  input  logic ras_miss,
  input  logic memvio_redirect,

  // ---- 入队(来自 IFU 的一个取指块,最多 16 条)----
  output logic                                in_ready,
  input  logic                                in_valid,
  input  logic [PREDICT_W-1:0]                in_instr_valid,   // 该槽有指令
  input  logic [PREDICT_W-1:0]                in_enq_enable,    // 该槽允许入队
  input  logic [PREDICT_W-1:0][31:0]          in_instr,
  input  logic [PREDICT_W-1:0][49:0]          in_pc,
  input  logic [PREDICT_W-1:0][9:0]           in_foldpc,
  input  logic [PREDICT_W-1:0]                in_pd_valid,
  input  logic [PREDICT_W-1:0]                in_pd_isRVC,
  input  logic [PREDICT_W-1:0][1:0]           in_pd_brType,
  input  logic [PREDICT_W-1:0]                in_pd_isCall,
  input  logic [PREDICT_W-1:0]                in_pd_isRet,
  input  logic [PREDICT_W-1:0]                in_ftqOffset_valid, // = pred_taken
  input  logic                                in_ftqPtr_flag,     // 整块共用一个 FTQ 指针
  input  logic [5:0]                          in_ftqPtr_value,
  input  logic [PREDICT_W-1:0][1:0]           in_excp_type,       // frontend.ExceptionType
  input  logic [PREDICT_W-1:0]                in_crosspage,
  input  logic [PREDICT_W-1:0]                in_illegal_instr,
  input  logic [PREDICT_W-1:0]                in_backend_excp,
  input  logic [PREDICT_W-1:0]                in_satp_flush_first,
  input  logic [PREDICT_W-1:0][3:0]           in_triggered,
  input  logic [PREDICT_W-1:0]                in_last_in_ftq,
  input  logic [NREASON-1:0]                  in_topdown_reasons,

  // ---- 出队(给 Decode,最多 6 条)----
  input  logic                                decode_can_accept,
  output logic [DECODE_W-1:0]                 out_valid,
  output ibuf_entry_t [DECODE_W-1:0]          out_bits,
  // exceptionType 的译码结果(纯组合,见 §11)
  output logic [DECODE_W-1:0]                 out_excp_af,   // exceptionVec(1)  取指访问错
  output logic [DECODE_W-1:0]                 out_excp_ii,   // exceptionVec(2)  非法 RVC 指令
  output logic [DECODE_W-1:0]                 out_excp_pf,   // exceptionVec(12) 取指缺页
  output logic [DECODE_W-1:0]                 out_excp_gpf,  // exceptionVec(20) 客户机取指缺页
  output logic [DECODE_W-1:0]                 out_crosspage,
  output logic [DECODE_W-1:0][55:0]           out_seqnum,    // 恒 0,见文件头
  output logic [DECODE_W-1:0][7:0]            out_uopidx,    // 恒 0

  // ---- topdown 停顿归因 / perf ----
  output logic [DECODE_W-1:0][REASON_W-1:0]   stall_reason,
  input  logic                                back_reason_valid,
  input  logic [REASON_W-1:0]                 back_reason_bits,
  output logic [8:0][REASON_W-1:0]            perf_value
);

  // ===========================================================================
  // §1 队列状态寄存器
  //
  // ★ 每组「有几份 flag」都是照 golden 实测的,不是照 Chisel 字面 ★(见文件头)
  // ===========================================================================
  ibuf_entry_t [IBUF_SIZE-1:0]              ibuf_q;

  // 输出寄存器组:Decode 直接看它。valid 与 bits 分开,因为 flush 只清 valid。
  logic        [DECODE_W-1:0]               out_valid_q;
  ibuf_entry_t [DECODE_W-1:0]               out_bits_q;
  logic        [DECODE_W-1:0][55:0]         out_seqnum_q;
  logic        [DECODE_W-1:0][7:0]          out_uopidx_q;

  // 入队指针:16 条并行指针(第 i 条指向「本块第 i 条指令该写哪一项」),
  // 但只有 0 号带 flag —— 其余 15 个 flag 在 golden 里不存在。
  logic [PREDICT_W-1:0][PTR_W-1:0]          enq_value_q;
  logic                                     enq_flag_q;

  // 出队指针:全局 deqPtr(带 flag)+ 每个出口的 bank 号(无 flag)+ 每个 bank 的
  // 组内偏移(带 flag,但那 6 个 flag 是自环死位,见文件头)。
  logic [PTR_W-1:0]                         deq_value_q;
  logic                                     deq_flag_q;
  logic [DECODE_W-1:0][BANKPTR_W-1:0]       deq_bank_q;
  logic [IBUF_NBANK-1:0][INBANK_W-1:0]      deq_inbank_value_q;
  logic [IBUF_NBANK-1:0]                    deq_inbank_flag_q;

  logic                                     allow_enq_q;
  logic [NREASON-1:0]                       topdown_reasons_q;
  logic                                     after_init_q;   // 上电后是否 fire 过
  logic                                     head_bubble_q;  // 刚 flush、队头还是气泡

  // ===========================================================================
  // §2 队列占用量与基本流控
  // ===========================================================================
  // distanceBetween(enqPtr, deqPtr):同 flag 直接相减,异 flag 加一圈(48)。
  // golden 写的是 (enq - 6'h10) - deq —— 6 位下 -16 与 +48 同值,这里写成 +48
  // 因为它才是「加一圈」的意思。
  logic [PTR_W-1:0] num_valid;
  always_comb begin
    if (enq_flag_q == deq_flag_q) num_valid = PTR_W'(enq_value_q[0] - deq_value_q);
    else                          num_valid = PTR_W'(enq_value_q[0] - deq_value_q
                                                     + PTR_W'(IBUF_SIZE));
  end

  // 队列空且 Decode 这拍能收 ⇒ 走旁路(§5)
  wire use_bypass = ({enq_flag_q, enq_value_q[0]} == {deq_flag_q, deq_value_q})
                    & decode_can_accept;

  wire enq_fire = allow_enq_q & in_valid;     // io.in.fire
  wire enq_take = enq_fire & ~flush;          // 真正写队列/推指针的条件

  // 本块打算入队的条数 = PopCount(enqEnable)(in_valid 无效时为 0)
  logic [FETCH_W-1:0] num_from_fetch;
  always_comb begin
    num_from_fetch = '0;
    if (in_valid)
      for (int i = 0; i < PREDICT_W; i++)
        num_from_fetch = num_from_fetch + FETCH_W'(in_enq_enable[i]);
  end

  // 输出寄存器里已经压了几条有效。
  // ★ 只看第 0..4 条,**不看第 5 条** ★ —— Chisel 的
  //   PriorityMuxDefault(valid.zip(Seq.range(1, DecodeWidth)).reverse, 0.U)
  // 里 zip 会按短的那边截断,valid(5) 配不到值。第 5 条满是另一条分支(out_full)。
  // 升序写、后写者胜 = 取最高位有效项,与优先级编码同义(不用 break,FM 前端更稳)。
  logic [CNT_W-1:0] out_valid_num;
  always_comb begin
    out_valid_num = '0;
    for (int i = 0; i < DECODE_W - 1; i++)
      if (out_valid_q[i]) out_valid_num = CNT_W'(i + 1);
  end
  wire out_full = out_valid_q[DECODE_W-1];   // !outputEntriesIsNotFull

  // 这拍要出队几条。三种情形:Decode 收 / Decode 不收但输出寄存器没满 / 满。
  wire [CNT_W-1:0] room_in_out = CNT_W'(DECODE_W) - out_valid_num;
  logic [CNT_W-1:0] num_out;
  always_comb begin
    if (decode_can_accept)
      num_out = (num_valid > PTR_W'(DECODE_W - 1)) ? CNT_W'(DECODE_W)
                                                   : num_valid[CNT_W-1:0];
    else if (out_full)
      num_out = '0;
    else
      num_out = (num_valid >= PTR_W'(room_in_out)) ? room_in_out : num_valid[CNT_W-1:0];
  end

  // 旁路时前 DECODE_W 条直接进输出寄存器,不占队列表项
  wire              fetch_gt_dec = num_from_fetch > FETCH_W'(DECODE_W - 1);
  wire [FETCH_W-1:0] num_try_enq = use_bypass
                                   ? (fetch_gt_dec ? FETCH_W'(num_from_fetch - FETCH_W'(DECODE_W))
                                                   : FETCH_W'(0))
                                   : num_from_fetch;
  wire [CNT_W-1:0]   num_bypass  = fetch_gt_dec ? CNT_W'(DECODE_W) : num_from_fetch[CNT_W-1:0];

  assign in_ready = allow_enq_q;

  // ===========================================================================
  // §3 入队数据成形(16 条 lane 各一份)
  // ===========================================================================
  // enqOffset(i) = 本块中排在 i 前面的**有效**槽数 —— 即第 i 条指令是本块的第几条。
  logic [PREDICT_W-1:0][OFF_W-1:0] enq_offset;
  always_comb begin
    for (int i = 0; i < PREDICT_W; i++) begin
      enq_offset[i] = '0;
      for (int j = 0; j < i; j++)
        enq_offset[i] = enq_offset[i] + OFF_W'(in_instr_valid[j]);
    end
  end

  ibuf_entry_t [PREDICT_W-1:0] enq_data;
  always_comb begin
    for (int i = 0; i < PREDICT_W; i++) begin
      enq_data[i].inst         = in_instr[i];
      enq_data[i].pc           = in_pc[i];
      enq_data[i].foldpc       = in_foldpc[i];
      enq_data[i].pd_valid     = in_pd_valid[i];
      enq_data[i].pd_isRVC     = in_pd_isRVC[i];
      enq_data[i].pd_brType    = in_pd_brType[i];
      enq_data[i].pd_isCall    = in_pd_isCall[i];
      enq_data[i].pd_isRet     = in_pd_isRet[i];
      enq_data[i].pred_taken   = in_ftqOffset_valid[i];
      enq_data[i].ftqPtr_flag  = in_ftqPtr_flag;
      enq_data[i].ftqPtr_value = in_ftqPtr_value;
      // ★ ftqOffset 是**槽号常数**,不是端口 ★:FetchToIBuffer.ftqOffset(i).bits
      // 恒等于 i(取指块内偏移),firtool 折成常数,golden 端口表里因此只有
      // io_in_bits_ftqOffset_<i>_valid 没有 _bits。
      enq_data[i].ftqOffset    = 4'(i);
      // IBufferExceptionType.cvtFromFetchExcpAndCrossPageAndRVCII:
      //   跨页 → {1, fetchExcp};否则有取指异常 → {0, fetchExcp};
      //   否则非法 RVC → {illegal, 00}(即 rvcII=100)。优先级即此顺序。
      enq_data[i].exceptionType = in_crosspage[i]      ? {1'b1, in_excp_type[i]}
                                : (|in_excp_type[i])   ? {1'b0, in_excp_type[i]}
                                                       : {in_illegal_instr[i], 2'b00};
      enq_data[i].backendException         = in_backend_excp[i];
      enq_data[i].satpFlushFirstFetchFault = in_satp_flush_first[i];
      enq_data[i].triggered                = in_triggered[i];
      enq_data[i].isLastInFtqEntry         = in_last_in_ftq[i];
    end
  end

  // ===========================================================================
  // §4 入队写选择(48 项 × 16 lane 的 one-hot)
  //
  // 第 i 条指令该写进哪一项:
  //   正常     —— enqPtrVec[enqOffset(i)].value
  //   旁路中   —— 前 DECODE_W 条不进队列,于是第 i 条落到
  //               enqPtrVec[enqOffset(i) - DECODE_W].value,且要求 enqOffset(i) >= DECODE_W
  // enqOffset 是 OFF_W=4 位、enqPtrVec 恰好 16 项 ⇒ 索引不越界(减法按 4 位回绕,
  // 但被 `>= DECODE_W` 的判据罩住,回绕值不会被采信)。
  // ===========================================================================
  // 每条 lane 先算出「查 enqPtrVec 的哪一格」与「这拍算不算数」,再与 48 项逐项比。
  logic [PREDICT_W-1:0][OFF_W-1:0] enq_ptr_idx;
  logic [PREDICT_W-1:0]            enq_slot_ok;
  logic [PREDICT_W-1:0][PTR_W-1:0] enq_target;
  always_comb begin
    for (int i = 0; i < PREDICT_W; i++) begin
      enq_ptr_idx[i] = use_bypass ? OFF_W'(enq_offset[i] - OFF_W'(DECODE_W))
                                  : enq_offset[i];
      enq_slot_ok[i] = use_bypass ? (enq_offset[i] >= OFF_W'(DECODE_W)) : 1'b1;
      enq_target[i]  = enq_value_q[enq_ptr_idx[i]];
    end
  end

  logic [IBUF_SIZE-1:0][PREDICT_W-1:0] ibuf_sel;
  always_comb
    for (int e = 0; e < IBUF_SIZE; e++)
      for (int i = 0; i < PREDICT_W; i++)
        ibuf_sel[e][i] = in_instr_valid[i] & in_enq_enable[i] & enq_slot_ok[i]
                         & (enq_target[i] == PTR_W'(e));

  // 命中项的写数据(Mux1H)。写使能见 §9。
  logic        [IBUF_SIZE-1:0] ibuf_wen;
  ibuf_entry_t [IBUF_SIZE-1:0] ibuf_wdata;
  always_comb
    for (int e = 0; e < IBUF_SIZE; e++) begin
      ibuf_wen[e]   = (|ibuf_sel[e]) & enq_take;
      ibuf_wdata[e] = '0;
      for (int i = 0; i < PREDICT_W; i++)
        if (ibuf_sel[e][i]) ibuf_wdata[e] = ibuf_wdata[e] | enq_data[i];
    end

  // ===========================================================================
  // §5 旁路(队列空 + Decode 能收):入队数据直接送输出寄存器
  // bypassEntries(j) 取「本块第 j 条」指令。
  // ===========================================================================
  logic [DECODE_W-1:0][PREDICT_W-1:0] bypass_sel;
  logic [DECODE_W-1:0]                bypass_valid;
  ibuf_entry_t [DECODE_W-1:0]         bypass_bits;
  always_comb begin
    for (int j = 0; j < DECODE_W; j++) begin
      for (int i = 0; i < PREDICT_W; i++)
        bypass_sel[j][i] = in_instr_valid[i] & in_enq_enable[i]
                           & (enq_offset[i] == OFF_W'(j));
      bypass_valid[j] = (|bypass_sel[j]) & enq_take;
      bypass_bits[j]  = '0;
      for (int i = 0; i < PREDICT_W; i++)
        if (bypass_sel[j][i]) bypass_bits[j] = bypass_bits[j] | enq_data[i];
    end
  end
  // 这拍输出寄存器是否走旁路来源(golden 的 _GEN_212)
  wire bypass_active = use_bypass & in_valid;

  // ===========================================================================
  // §6 出队读口:两级 Mux(bank 内 8 选 1,再 bank 间 6 选 1)
  //
  // 表项 e 属于 bank (e % IBUF_NBANK),bank 内第 (e / IBUF_NBANK) 项。
  // 第一级:每个 bank 用自己的 deqInBankPtr 选出 1 项(8 选 1,索引恰好 3 位,不越界)。
  // 第二级:第 i 个出口用 deqBankPtrVec[i] 选 bank(6 选 1)。
  // ★ 第二级是 6 项的 Mux1H 而不是数组索引 ★:deqBankPtrVec 是 3 位,取值 6/7 时
  // golden 给出全 0(所有比较项都不命中),不是回绕到第 0 个 bank。正常运行中
  // 指针恒在 0..5,但结构要照抄。
  // ===========================================================================
  ibuf_entry_t [IBUF_NBANK-1:0] read_stage1;
  always_comb begin
    for (int b = 0; b < IBUF_NBANK; b++) begin
      read_stage1[b] = '0;
      for (int k = 0; k < BANK_SIZE; k++)
        if (deq_inbank_value_q[b] == INBANK_W'(k))
          read_stage1[b] = read_stage1[b] | ibuf_q[b + k * IBUF_NBANK];
    end
  end

  ibuf_entry_t [DECODE_W-1:0] deq_bits;
  always_comb begin
    for (int i = 0; i < DECODE_W; i++) begin
      deq_bits[i] = '0;
      for (int b = 0; b < IBUF_NBANK; b++)
        if (deq_bank_q[i] == BANKPTR_W'(b))
          deq_bits[i] = deq_bits[i] | read_stage1[b];
    end
  end

  // ===========================================================================
  // §7 出队数量掩码与指针推进量
  // ===========================================================================
  // 下一拍输出寄存器里会有几条有效
  logic [CNT_W-1:0] out_valid_num_next;
  always_comb begin
    if (decode_can_accept)      out_valid_num_next = use_bypass ? num_bypass : num_out;
    else if (out_full)          out_valid_num_next = out_valid_num;
    else                        out_valid_num_next = CNT_W'(out_valid_num + num_out);
  end
  // UIntToMask(n, 6):低 n 位为 1。照 golden 用 8 位移位再取低 6 位 —— n=6 时
  // (1<<6)[5:0] = 0,减 1 得全 1,正是想要的「6 条全有效」。
  wire [7:0]           valid_mask_raw = 8'h1 << out_valid_num_next;
  wire [DECODE_W-1:0]  valid_vec      = DECODE_W'(valid_mask_raw[DECODE_W-1:0]
                                                  - DECODE_W'(1));

  // --- 指针推进(CircularQueuePtr 的 "+"):先加,再试着减一圈,减得动就是绕回了 ---
  // 全局 deqPtr(48 项)
  wire [PTR_W:0]   deq_sum      = {1'b0, deq_value_q} + (PTR_W+1)'(num_out);
  wire [PTR_W+1:0] deq_diff     = {1'b0, deq_sum} - (PTR_W+2)'(IBUF_SIZE);
  wire             deq_wrap     = ~deq_diff[PTR_W+1];           // $signed(diff) >= 0
  wire [PTR_W-1:0] deq_value_nx = deq_wrap ? deq_diff[PTR_W-1:0] : deq_sum[PTR_W-1:0];

  // 16 条入队指针(48 项),每条各自 +numTryEnq
  logic [PREDICT_W-1:0][PTR_W:0]   enq_sum;
  logic [PREDICT_W-1:0][PTR_W+1:0] enq_diff;
  logic [PREDICT_W-1:0][PTR_W-1:0] enq_value_nx;
  logic [PREDICT_W-1:0]            enq_wrap;
  always_comb
    for (int i = 0; i < PREDICT_W; i++) begin
      enq_sum[i]      = {1'b0, enq_value_q[i]} + (PTR_W+1)'(num_try_enq);
      enq_diff[i]     = {1'b0, enq_sum[i]} - (PTR_W+2)'(IBUF_SIZE);
      enq_wrap[i]     = ~enq_diff[i][PTR_W+1];
      enq_value_nx[i] = enq_wrap[i] ? enq_diff[i][PTR_W-1:0] : enq_sum[i][PTR_W-1:0];
    end

  // 6 条 bank 指针(6 项一圈),各自 +numOut
  logic [DECODE_W-1:0][BANKPTR_W:0]   deq_bank_sum;
  logic [DECODE_W-1:0][BANKPTR_W+1:0] deq_bank_diff;
  logic [DECODE_W-1:0][BANKPTR_W-1:0] deq_bank_nx;
  always_comb
    for (int i = 0; i < DECODE_W; i++) begin
      deq_bank_sum[i]  = {1'b0, deq_bank_q[i]} + (BANKPTR_W+1)'(num_out);
      deq_bank_diff[i] = {1'b0, deq_bank_sum[i]} - (BANKPTR_W+2)'(IBUF_NBANK);
      deq_bank_nx[i]   = (~deq_bank_diff[i][BANKPTR_W+1]) ? deq_bank_diff[i][BANKPTR_W-1:0]
                                                          : deq_bank_sum[i][BANKPTR_W-1:0];
    end

  // 每个 bank 的组内指针:这拍是否被读到(bankAdvance)⇒ +1。
  //   validIdx = 该 bank 相对 deqBankPtr 的距离(模 IBUF_NBANK,再截到 CNT_W 位)
  //   bankAdvance = numOut > validIdx
  // 「距离」用 deqBankPtrVec[0] 作基准 —— 6 个出口的 bank 指针是同步推进的,
  // 差值恒为 i,所以只用 0 号即可(这也是 golden 的形状)。
  logic [IBUF_NBANK-1:0][CNT_W-1:0] bank_valid_idx;
  logic [IBUF_NBANK-1:0]            bank_advance;
  always_comb
    for (int b = 0; b < IBUF_NBANK; b++) begin
      bank_valid_idx[b] =
          (BANKPTR_W'(b) >= deq_bank_q[0])
            ? CNT_W'(BANKPTR_W'(BANKPTR_W'(b) - deq_bank_q[0]))
            : CNT_W'(BANKPTR_W'(BANKPTR_W'(b) + BANKPTR_W'(IBUF_NBANK) - deq_bank_q[0]));
      bank_advance[b] = num_out > bank_valid_idx[b];
    end
  // 组内指针是 8 项一圈(2 的幂),所以 {flag,value} 直接 +1,进位自然落到 flag。
  logic [IBUF_NBANK-1:0][INBANK_W:0] inbank_inc;
  always_comb
    for (int b = 0; b < IBUF_NBANK; b++)
      inbank_inc[b] = {deq_inbank_flag_q[b], deq_inbank_value_q[b]} + (INBANK_W+1)'(1);

  // ===========================================================================
  // §8 输出寄存器的下一拍值
  //
  // 三种情形:
  //   (a) Decode 收:整条换新 —— 旁路来源或正常出队来源;
  //   (b) Decode 不收、输出寄存器没满:把新出队的项**接在已有有效项后面**,
  //       即第 i 个位置取 deqEntries[i - out_valid_num];i < out_valid_num 的位置保持;
  //   (c) 输出寄存器满:整组保持。
  //
  // ★ (b) 的移位索引会越界,golden 的越界语义是「读第 0 项」★
  // Chisel 是 `VecInit(deqEntries.take(i+1).map(_.bits))(i.U - outputEntriesValidNum)`,
  // 即一个 i+1 项的 Vec 被一个 ceil(log2(i+1)) 位的索引读。firtool 把 Vec 补齐到
  // 2^位宽 项,**补位全填第 0 项**。golden 实测(_GEN_143/_GEN_177/_GEN_194):
  //   i=2:{d0, d2, d1, d0}                 —— 3 号位填 d0
  //   i=4:{d0, d0, d0, d4, d3, d2, d1, d0} —— 5/6/7 号位全填 d0(不是回绕的 0/1/2)
  //   i=5:{d0, d0, d5, d4, d3, d2, d1, d0} —— 6/7 号位填 d0(不是回绕的 0/1)
  // 所以既不是「越界得 0」也不是「模回绕」,而是「越界得第 0 项」。i=4 那行是
  // 唯一能把三种猜测区分开的证据:回绕会给 d1/d2,补零会给 0。
  // 越界只发生在 i < out_valid_num 时,而那时写使能正好是关的 —— 但结构照抄。
  // ===========================================================================
  ibuf_entry_t [DECODE_W-1:0] deq_shifted;
  for (genvar i = 0; i < DECODE_W; i++) begin : g_out_shift
    // ceil(log2(i+1)):0→1(golden 把 i=0 折成常数第 0 项,同值)
    localparam int SHW  = (i <= 1) ? 1 : (i <= 3) ? 2 : 3;
    localparam int NPAD = 1 << SHW;
    wire [SHW-1:0] shift_idx = SHW'(i) - SHW'(out_valid_num);
    ibuf_entry_t [NPAD-1:0] pad;
    always_comb
      for (int k = 0; k < NPAD; k++) pad[k] = deq_bits[(k <= i) ? k : 0];
    assign deq_shifted[i] = pad[shift_idx];
  end

  // 第 i 个输出位置这拍保持不动(Decode 不收且它在「已有有效项」范围内,或整组满)
  logic [DECODE_W-1:0] out_hold;
  always_comb
    for (int i = 0; i < DECODE_W; i++)
      out_hold[i] = out_full | (out_valid_num > CNT_W'(i));

  // ===========================================================================
  // §9 主时序块 —— 异步复位域(golden 唯一的 posedge reset 块)
  // ===========================================================================
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      // ibuf / 输出寄存器全 0;指针按 0,1,2,... 初始化(不是全 0!)
      ibuf_q            <= '0;
      out_valid_q       <= '0;
      out_bits_q        <= '0;
      out_seqnum_q      <= '0;
      out_uopidx_q      <= '0;
      for (int i = 0; i < DECODE_W; i++)   deq_bank_q[i]   <= BANKPTR_W'(i);
      deq_inbank_value_q <= '0;
      deq_inbank_flag_q  <= '0;
      deq_value_q        <= '0;
      deq_flag_q         <= 1'b0;
      for (int i = 0; i < PREDICT_W; i++)  enq_value_q[i]  <= PTR_W'(i);
      enq_flag_q         <= 1'b0;
      allow_enq_q        <= 1'b1;          // ★ 复位值是 1,不是 0
      topdown_reasons_q  <= '0;
      after_init_q       <= 1'b0;
      head_bubble_q      <= 1'b0;
    end else begin
      // ---- 队列表项:命中写选择且本拍真的入队 ----
      for (int e = 0; e < IBUF_SIZE; e++)
        if (ibuf_wen[e]) ibuf_q[e] <= ibuf_wdata[e];

      // ---- 输出寄存器 ----
      for (int i = 0; i < DECODE_W; i++) begin
        out_valid_q[i] <= ~flush
                          & (decode_can_accept
                               ? (bypass_active ? bypass_valid[i] : valid_vec[i])
                               : (out_full ? out_valid_q[i] : valid_vec[i]));
        if (decode_can_accept)
          out_bits_q[i] <= bypass_active ? bypass_bits[i] : deq_bits[i];
        else if (!out_hold[i])
          out_bits_q[i] <= deq_shifted[i];
        // debug_seqNum 无输入来源,写使能与 bits 同,写进去的永远是 0
        if (decode_can_accept || !out_hold[i]) begin
          out_seqnum_q[i] <= '0;
          out_uopidx_q[i] <= '0;
        end
      end

      // ---- 指针 ----
      if (flush) begin
        for (int i = 0; i < DECODE_W; i++)  deq_bank_q[i]  <= BANKPTR_W'(i);
        deq_inbank_value_q <= '0;
        deq_value_q        <= '0;
        for (int i = 0; i < PREDICT_W; i++) enq_value_q[i] <= PTR_W'(i);
      end else begin
        deq_bank_q  <= deq_bank_nx;
        for (int b = 0; b < IBUF_NBANK; b++)
          if (bank_advance[b]) deq_inbank_value_q[b] <= inbank_inc[b][INBANK_W-1:0];
        deq_value_q <= deq_value_nx;
        // 入队指针只在真的入队时推进
        if (enq_take) enq_value_q <= enq_value_nx;
      end
      // 三组 flag 都写在 flush 分支**之外**(flush 时直接归 0),与 golden 一致
      for (int b = 0; b < IBUF_NBANK; b++)
        deq_inbank_flag_q[b] <= ~flush & (bank_advance[b] ? inbank_inc[b][INBANK_W]
                                                          : deq_inbank_flag_q[b]);
      deq_flag_q <= ~flush & (deq_wrap ^ deq_flag_q);
      enq_flag_q <= ~flush & ((enq_take & enq_wrap[0]) ^ enq_flag_q);

      // ---- 反压:下一拍占用量 <= IBufSize - PredictWidth(=32)才继续收 ----
      // flush 压过一切(Chisel 里 when(io.flush){allowEnq := true.B} 写在后面)
      allow_enq_q <= flush
                     | (PTR_W'(PTR_W'(num_valid + PTR_W'(enq_fire ? num_try_enq
                                                                  : FETCH_W'(0)))
                               - PTR_W'(num_out))
                        < PTR_W'(IBUF_SIZE - PREDICT_W + 1));

      // ---- topdown 归因:先整拍吃上游的 reasons,再按本拍 flush 的原因置位 ----
      // 优先级(Chisel 的 when/elsewhen 链):BTBMiss > TAGEMiss > SCMiss >
      // ITTAGEMiss > RASMiss;非 ControlRedirect 时 MemVioRedirect > 其它重定向。
      topdown_reasons_q <= in_topdown_reasons;
      if (flush) begin
        if (ctrl_redirect) begin
          if      (ctrl_btb_miss) topdown_reasons_q[12] <= 1'b1;  // BTBMissBubble
          else if (tage_miss)     topdown_reasons_q[ 3] <= 1'b1;  // TAGEMissBubble
          else if (sc_miss)       topdown_reasons_q[ 4] <= 1'b1;  // SCMissBubble
          else if (ittage_miss)   topdown_reasons_q[ 5] <= 1'b1;  // ITTAGEMissBubble
          else if (ras_miss)      topdown_reasons_q[ 6] <= 1'b1;  // RASMissBubble
        end else if (memvio_redirect)
          topdown_reasons_q[7] <= 1'b1;                           // MemVioRedirectBubble
        else
          topdown_reasons_q[8] <= 1'b1;                           // OtherRedirectBubble
      end

      after_init_q  <= enq_fire | after_init_q;
      head_bubble_q <= flush | (~(|num_valid) & head_bubble_q);
    end
  end

  assign out_valid  = out_valid_q;
  assign out_bits   = out_bits_q;
  assign out_seqnum = out_seqnum_q;
  assign out_uopidx = out_uopidx_q;

  // ===========================================================================
  // §10 perf —— ★ 无复位域 ★(golden 第二个 always 块没有 reset 臂)
  // 9 路事件各打两拍再送出。这里的 probe 表达式与 Chisel 的 perfEvents 一一对应。
  // ===========================================================================
  wire instr_hungry  = after_init_q & ~(|num_valid) & ~head_bubble_q;
  wire [CNT_W-1:0] front_bubble = (decode_can_accept & ~head_bubble_q)
                                  ? CNT_W'(CNT_W'(DECODE_W) - num_out) : CNT_W'(0);
  wire fetch_latency = decode_can_accept & ~head_bubble_q & (num_out == CNT_W'(0));

  // 9 路事件各一对打拍寄存器,与 golden 的 io_perf_<N>_value_REG / _REG_1 一一对应。
  // 第 7 路(FrontBubble)是 3 位计数,其余 8 路是 1 位事件 —— 位宽照 golden,
  // 统一成 3 位会凭空多出 36 个死位比对点。
  logic       perf_flush_s1,   perf_flush_s2;    // 0 IBuffer_Flushed
  logic       perf_hungry_s1,  perf_hungry_s2;   // 1 IBuffer_hungry
  logic       perf_q1of4_s1,   perf_q1of4_s2;    // 2 占用量 (0, 12)
  logic       perf_q2of4_s1,   perf_q2of4_s2;    // 3 占用量 [12, 24)
  logic       perf_q3of4_s1,   perf_q3of4_s2;    // 4 占用量 [24, 36)
  logic       perf_q4of4_s1,   perf_q4of4_s2;    // 5 占用量 [36, 48)
  logic       perf_qfull_s1,   perf_qfull_s2;    // 6 IBuffer_full
  logic [2:0] perf_bubble_s1,  perf_bubble_s2;   // 7 Front_Bubble(3 位计数)
  logic       perf_latency_s1, perf_latency_s2;  // 8 Fetch_Latency_Bound

  always_ff @(posedge clock) begin
    perf_flush_s1   <= flush;
    perf_hungry_s1  <= instr_hungry;
    perf_q1of4_s1   <= (|num_valid) & (num_valid < PTR_W'(IBUF_SIZE / 4));
    perf_q2of4_s1   <= (num_valid >= PTR_W'(IBUF_SIZE / 4))
                       & (num_valid < PTR_W'(2 * (IBUF_SIZE / 4)));
    perf_q3of4_s1   <= (num_valid >= PTR_W'(2 * (IBUF_SIZE / 4)))
                       & (num_valid < PTR_W'(3 * (IBUF_SIZE / 4)));
    perf_q4of4_s1   <= (num_valid >= PTR_W'(3 * (IBUF_SIZE / 4)))
                       & (num_valid < PTR_W'(4 * (IBUF_SIZE / 4)));
    // ★ 照 Chisel 的 numValid.andR ★ —— 6 位全 1 = 63,而队列只有 48 项,
    // 所以这个"队列满"事件在真实运行中永远不会触发。golden 同样是
    // &numValid_probe —— 看起来像 bug,但它就是 golden 的行为,照抄。
    perf_qfull_s1   <= &num_valid;
    perf_bubble_s1  <= front_bubble;
    perf_latency_s1 <= fetch_latency;

    perf_flush_s2   <= perf_flush_s1;
    perf_hungry_s2  <= perf_hungry_s1;
    perf_q1of4_s2   <= perf_q1of4_s1;
    perf_q2of4_s2   <= perf_q2of4_s1;
    perf_q3of4_s2   <= perf_q3of4_s1;
    perf_q4of4_s2   <= perf_q4of4_s1;
    perf_qfull_s2   <= perf_qfull_s1;
    perf_bubble_s2  <= perf_bubble_s1;
    perf_latency_s2 <= perf_latency_s1;
  end

  always_comb begin
    perf_value[0] = REASON_W'(perf_flush_s2);
    perf_value[1] = REASON_W'(perf_hungry_s2);
    perf_value[2] = REASON_W'(perf_q1of4_s2);
    perf_value[3] = REASON_W'(perf_q2of4_s2);
    perf_value[4] = REASON_W'(perf_q3of4_s2);
    perf_value[5] = REASON_W'(perf_q4of4_s2);
    perf_value[6] = REASON_W'(perf_qfull_s2);
    perf_value[7] = REASON_W'(perf_bubble_s2);
    perf_value[8] = REASON_W'(perf_latency_s2);
  end

  // ===========================================================================
  // §11 输出:异常向量译码与 topdown 停顿归因
  // ===========================================================================
  // exceptionType 的 3 位编码(IBufferExceptionType):
  //   000 无 / 001 缺页 / 010 客户机缺页 / 011 访问错 / 100 非法 RVC /
  //   101,110,111 = 跨页的缺页/客户机缺页/访问错
  // 低 2 位给出异常种类,最高位区分「跨页」(低 2 位非 0)与「非法 RVC」(低 2 位为 0)。
  always_comb
    for (int i = 0; i < DECODE_W; i++) begin
      out_excp_af[i]   = &out_bits_q[i].exceptionType[1:0];
      out_excp_ii[i]   = out_bits_q[i].exceptionType[2]
                         & (out_bits_q[i].exceptionType[1:0] == 2'h0);
      out_excp_pf[i]   = out_bits_q[i].exceptionType[1:0] == 2'h1;
      out_excp_gpf[i]  = out_bits_q[i].exceptionType[1:0] == 2'h2;
      out_crosspage[i] = out_bits_q[i].exceptionType[2]
                         & (|out_bits_q[i].exceptionType[1:0]);
    end

  // 本拍有几个出口是空的(Decode 想收 6 条但只给得出 deqValidCount 条)
  logic [CNT_W-1:0] deq_valid_count;
  always_comb begin
    deq_valid_count = '0;
    for (int i = 0; i < DECODE_W; i++)
      deq_valid_count = deq_valid_count + CNT_W'(valid_vec[i]);
  end
  wire [CNT_W-1:0] deq_waste_count = CNT_W'(CNT_W'(DECODE_W) - deq_valid_count);

  // matchBubble = **最高**位被置起的 reason 编号(Chisel 用 reasons.reverse 的
  // PriorityEncoder 实现,等价于从高位往低位找第一个 1)。
  logic [REASON_W-1:0] match_bubble;
  always_comb begin
    match_bubble = '0;
    for (int r = 0; r < NREASON; r++)
      if (topdown_reasons_q[r]) match_bubble = REASON_W'(r);
  end

  // 归因:队列这拍完全没给出指令(waste 满 6)或 topdown 已有归因 ⇒ 用 matchBubble;
  // 否则算作「取指碎片化」FetchFragBubble(id = 13)。
  localparam int FETCH_FRAG_BUBBLE = 13;
  wire [REASON_W-1:0] stall_pick =
      ((deq_waste_count == CNT_W'(DECODE_W)) | (|topdown_reasons_q))
        ? match_bubble : REASON_W'(FETCH_FRAG_BUBBLE);

  // reason(DecodeWidth-1-k) 在 k < deqWasteCount 时被归因;后端给了 backReason 则整组覆盖。
  always_comb
    for (int k = 0; k < DECODE_W; k++)
      stall_reason[DECODE_W - 1 - k] =
          back_reason_valid ? back_reason_bits
                            : ((deq_waste_count > CNT_W'(k)) ? stall_pick : REASON_W'(0));

  // ===========================================================================
  // §12 设计不变量(与 golden 的 XSError 同义,仅仿真)
  // golden 把它们放在 `ifndef SYNTHESIS 里,FM 两侧与 UT 都带 -define SYNTHESIS,
  // 因此这一块不参与任何判定,纯粹是给读者与波形调试用。
  // ===========================================================================
`ifndef SYNTHESIS
  always @(posedge clock) begin
    if (!reset) begin
      // 三组出队指针必须同步:deqPtr == deqBankPtr + deqInBankPtr[deqBankPtr] * NBANK
      assert (deq_value_q == PTR_W'(deq_bank_q[0]
                                    + BANKPTR_W'(deq_inbank_value_q[deq_bank_q[0]])
                                      * BANKPTR_W'(IBUF_NBANK)))
        else $error("IBuffer: dequeue PTR mismatch");
      // 出队指针不能越过入队指针
      assert (!((enq_flag_q ^ deq_flag_q ^ (enq_value_q[0] < deq_value_q))
                & ~((enq_flag_q != deq_flag_q) & (enq_value_q[0] == deq_value_q))))
        else $error("IBuffer: deqPtr is older than enqPtr");
    end
  end
`endif

endmodule : xs_IBuffer_core

// BEGIN GENERATED(wrapper)
// 本段由 tools/gen_ibuffer_wrapper.py 从 G1 golden 端口表生成，勿手改。
module IBuffer (
  input         clock,
  input         reset,
  input         io_flush,
  input         io_ControlRedirect,
  input         io_ControlBTBMissBubble,
  input         io_TAGEMissBubble,
  input         io_SCMissBubble,
  input         io_ITTAGEMissBubble,
  input         io_RASMissBubble,
  input         io_MemVioRedirect,
  output        io_in_ready,
  input         io_in_valid,
  input  [31:0] io_in_bits_instrs_0,
  input  [31:0] io_in_bits_instrs_1,
  input  [31:0] io_in_bits_instrs_2,
  input  [31:0] io_in_bits_instrs_3,
  input  [31:0] io_in_bits_instrs_4,
  input  [31:0] io_in_bits_instrs_5,
  input  [31:0] io_in_bits_instrs_6,
  input  [31:0] io_in_bits_instrs_7,
  input  [31:0] io_in_bits_instrs_8,
  input  [31:0] io_in_bits_instrs_9,
  input  [31:0] io_in_bits_instrs_10,
  input  [31:0] io_in_bits_instrs_11,
  input  [31:0] io_in_bits_instrs_12,
  input  [31:0] io_in_bits_instrs_13,
  input  [31:0] io_in_bits_instrs_14,
  input  [31:0] io_in_bits_instrs_15,
  input  [15:0] io_in_bits_valid,
  input  [15:0] io_in_bits_enqEnable,
  input         io_in_bits_pd_0_isRVC,
  input  [1:0]  io_in_bits_pd_0_brType,
  input         io_in_bits_pd_0_isCall,
  input         io_in_bits_pd_0_isRet,
  input         io_in_bits_pd_1_valid,
  input         io_in_bits_pd_1_isRVC,
  input  [1:0]  io_in_bits_pd_1_brType,
  input         io_in_bits_pd_1_isCall,
  input         io_in_bits_pd_1_isRet,
  input         io_in_bits_pd_2_valid,
  input         io_in_bits_pd_2_isRVC,
  input  [1:0]  io_in_bits_pd_2_brType,
  input         io_in_bits_pd_2_isCall,
  input         io_in_bits_pd_2_isRet,
  input         io_in_bits_pd_3_valid,
  input         io_in_bits_pd_3_isRVC,
  input  [1:0]  io_in_bits_pd_3_brType,
  input         io_in_bits_pd_3_isCall,
  input         io_in_bits_pd_3_isRet,
  input         io_in_bits_pd_4_valid,
  input         io_in_bits_pd_4_isRVC,
  input  [1:0]  io_in_bits_pd_4_brType,
  input         io_in_bits_pd_4_isCall,
  input         io_in_bits_pd_4_isRet,
  input         io_in_bits_pd_5_valid,
  input         io_in_bits_pd_5_isRVC,
  input  [1:0]  io_in_bits_pd_5_brType,
  input         io_in_bits_pd_5_isCall,
  input         io_in_bits_pd_5_isRet,
  input         io_in_bits_pd_6_valid,
  input         io_in_bits_pd_6_isRVC,
  input  [1:0]  io_in_bits_pd_6_brType,
  input         io_in_bits_pd_6_isCall,
  input         io_in_bits_pd_6_isRet,
  input         io_in_bits_pd_7_valid,
  input         io_in_bits_pd_7_isRVC,
  input  [1:0]  io_in_bits_pd_7_brType,
  input         io_in_bits_pd_7_isCall,
  input         io_in_bits_pd_7_isRet,
  input         io_in_bits_pd_8_valid,
  input         io_in_bits_pd_8_isRVC,
  input  [1:0]  io_in_bits_pd_8_brType,
  input         io_in_bits_pd_8_isCall,
  input         io_in_bits_pd_8_isRet,
  input         io_in_bits_pd_9_valid,
  input         io_in_bits_pd_9_isRVC,
  input  [1:0]  io_in_bits_pd_9_brType,
  input         io_in_bits_pd_9_isCall,
  input         io_in_bits_pd_9_isRet,
  input         io_in_bits_pd_10_valid,
  input         io_in_bits_pd_10_isRVC,
  input  [1:0]  io_in_bits_pd_10_brType,
  input         io_in_bits_pd_10_isCall,
  input         io_in_bits_pd_10_isRet,
  input         io_in_bits_pd_11_valid,
  input         io_in_bits_pd_11_isRVC,
  input  [1:0]  io_in_bits_pd_11_brType,
  input         io_in_bits_pd_11_isCall,
  input         io_in_bits_pd_11_isRet,
  input         io_in_bits_pd_12_valid,
  input         io_in_bits_pd_12_isRVC,
  input  [1:0]  io_in_bits_pd_12_brType,
  input         io_in_bits_pd_12_isCall,
  input         io_in_bits_pd_12_isRet,
  input         io_in_bits_pd_13_valid,
  input         io_in_bits_pd_13_isRVC,
  input  [1:0]  io_in_bits_pd_13_brType,
  input         io_in_bits_pd_13_isCall,
  input         io_in_bits_pd_13_isRet,
  input         io_in_bits_pd_14_valid,
  input         io_in_bits_pd_14_isRVC,
  input  [1:0]  io_in_bits_pd_14_brType,
  input         io_in_bits_pd_14_isCall,
  input         io_in_bits_pd_14_isRet,
  input         io_in_bits_pd_15_valid,
  input         io_in_bits_pd_15_isRVC,
  input  [1:0]  io_in_bits_pd_15_brType,
  input         io_in_bits_pd_15_isCall,
  input         io_in_bits_pd_15_isRet,
  input  [9:0]  io_in_bits_foldpc_0,
  input  [9:0]  io_in_bits_foldpc_1,
  input  [9:0]  io_in_bits_foldpc_2,
  input  [9:0]  io_in_bits_foldpc_3,
  input  [9:0]  io_in_bits_foldpc_4,
  input  [9:0]  io_in_bits_foldpc_5,
  input  [9:0]  io_in_bits_foldpc_6,
  input  [9:0]  io_in_bits_foldpc_7,
  input  [9:0]  io_in_bits_foldpc_8,
  input  [9:0]  io_in_bits_foldpc_9,
  input  [9:0]  io_in_bits_foldpc_10,
  input  [9:0]  io_in_bits_foldpc_11,
  input  [9:0]  io_in_bits_foldpc_12,
  input  [9:0]  io_in_bits_foldpc_13,
  input  [9:0]  io_in_bits_foldpc_14,
  input  [9:0]  io_in_bits_foldpc_15,
  input         io_in_bits_ftqOffset_0_valid,
  input         io_in_bits_ftqOffset_1_valid,
  input         io_in_bits_ftqOffset_2_valid,
  input         io_in_bits_ftqOffset_3_valid,
  input         io_in_bits_ftqOffset_4_valid,
  input         io_in_bits_ftqOffset_5_valid,
  input         io_in_bits_ftqOffset_6_valid,
  input         io_in_bits_ftqOffset_7_valid,
  input         io_in_bits_ftqOffset_8_valid,
  input         io_in_bits_ftqOffset_9_valid,
  input         io_in_bits_ftqOffset_10_valid,
  input         io_in_bits_ftqOffset_11_valid,
  input         io_in_bits_ftqOffset_12_valid,
  input         io_in_bits_ftqOffset_13_valid,
  input         io_in_bits_ftqOffset_14_valid,
  input         io_in_bits_ftqOffset_15_valid,
  input         io_in_bits_backendException_0,
  input         io_in_bits_satpFlushFirstFetchFault_0,
  input  [1:0]  io_in_bits_exceptionType_0,
  input  [1:0]  io_in_bits_exceptionType_1,
  input  [1:0]  io_in_bits_exceptionType_2,
  input  [1:0]  io_in_bits_exceptionType_3,
  input  [1:0]  io_in_bits_exceptionType_4,
  input  [1:0]  io_in_bits_exceptionType_5,
  input  [1:0]  io_in_bits_exceptionType_6,
  input  [1:0]  io_in_bits_exceptionType_7,
  input  [1:0]  io_in_bits_exceptionType_8,
  input  [1:0]  io_in_bits_exceptionType_9,
  input  [1:0]  io_in_bits_exceptionType_10,
  input  [1:0]  io_in_bits_exceptionType_11,
  input  [1:0]  io_in_bits_exceptionType_12,
  input  [1:0]  io_in_bits_exceptionType_13,
  input  [1:0]  io_in_bits_exceptionType_14,
  input  [1:0]  io_in_bits_exceptionType_15,
  input         io_in_bits_crossPageIPFFix_0,
  input         io_in_bits_crossPageIPFFix_1,
  input         io_in_bits_crossPageIPFFix_2,
  input         io_in_bits_crossPageIPFFix_3,
  input         io_in_bits_crossPageIPFFix_4,
  input         io_in_bits_crossPageIPFFix_5,
  input         io_in_bits_crossPageIPFFix_6,
  input         io_in_bits_crossPageIPFFix_7,
  input         io_in_bits_crossPageIPFFix_8,
  input         io_in_bits_crossPageIPFFix_9,
  input         io_in_bits_crossPageIPFFix_10,
  input         io_in_bits_crossPageIPFFix_11,
  input         io_in_bits_crossPageIPFFix_12,
  input         io_in_bits_crossPageIPFFix_13,
  input         io_in_bits_crossPageIPFFix_14,
  input         io_in_bits_crossPageIPFFix_15,
  input         io_in_bits_illegalInstr_0,
  input         io_in_bits_illegalInstr_1,
  input         io_in_bits_illegalInstr_2,
  input         io_in_bits_illegalInstr_3,
  input         io_in_bits_illegalInstr_4,
  input         io_in_bits_illegalInstr_5,
  input         io_in_bits_illegalInstr_6,
  input         io_in_bits_illegalInstr_7,
  input         io_in_bits_illegalInstr_8,
  input         io_in_bits_illegalInstr_9,
  input         io_in_bits_illegalInstr_10,
  input         io_in_bits_illegalInstr_11,
  input         io_in_bits_illegalInstr_12,
  input         io_in_bits_illegalInstr_13,
  input         io_in_bits_illegalInstr_14,
  input         io_in_bits_illegalInstr_15,
  input  [3:0]  io_in_bits_triggered_0,
  input  [3:0]  io_in_bits_triggered_1,
  input  [3:0]  io_in_bits_triggered_2,
  input  [3:0]  io_in_bits_triggered_3,
  input  [3:0]  io_in_bits_triggered_4,
  input  [3:0]  io_in_bits_triggered_5,
  input  [3:0]  io_in_bits_triggered_6,
  input  [3:0]  io_in_bits_triggered_7,
  input  [3:0]  io_in_bits_triggered_8,
  input  [3:0]  io_in_bits_triggered_9,
  input  [3:0]  io_in_bits_triggered_10,
  input  [3:0]  io_in_bits_triggered_11,
  input  [3:0]  io_in_bits_triggered_12,
  input  [3:0]  io_in_bits_triggered_13,
  input  [3:0]  io_in_bits_triggered_14,
  input  [3:0]  io_in_bits_triggered_15,
  input         io_in_bits_isLastInFtqEntry_0,
  input         io_in_bits_isLastInFtqEntry_1,
  input         io_in_bits_isLastInFtqEntry_2,
  input         io_in_bits_isLastInFtqEntry_3,
  input         io_in_bits_isLastInFtqEntry_4,
  input         io_in_bits_isLastInFtqEntry_5,
  input         io_in_bits_isLastInFtqEntry_6,
  input         io_in_bits_isLastInFtqEntry_7,
  input         io_in_bits_isLastInFtqEntry_8,
  input         io_in_bits_isLastInFtqEntry_9,
  input         io_in_bits_isLastInFtqEntry_10,
  input         io_in_bits_isLastInFtqEntry_11,
  input         io_in_bits_isLastInFtqEntry_12,
  input         io_in_bits_isLastInFtqEntry_13,
  input         io_in_bits_isLastInFtqEntry_14,
  input         io_in_bits_isLastInFtqEntry_15,
  input  [49:0] io_in_bits_pc_0,
  input  [49:0] io_in_bits_pc_1,
  input  [49:0] io_in_bits_pc_2,
  input  [49:0] io_in_bits_pc_3,
  input  [49:0] io_in_bits_pc_4,
  input  [49:0] io_in_bits_pc_5,
  input  [49:0] io_in_bits_pc_6,
  input  [49:0] io_in_bits_pc_7,
  input  [49:0] io_in_bits_pc_8,
  input  [49:0] io_in_bits_pc_9,
  input  [49:0] io_in_bits_pc_10,
  input  [49:0] io_in_bits_pc_11,
  input  [49:0] io_in_bits_pc_12,
  input  [49:0] io_in_bits_pc_13,
  input  [49:0] io_in_bits_pc_14,
  input  [49:0] io_in_bits_pc_15,
  input         io_in_bits_ftqPtr_flag,
  input  [5:0]  io_in_bits_ftqPtr_value,
  input         io_in_bits_topdown_info_reasons_0,
  input         io_in_bits_topdown_info_reasons_1,
  input         io_in_bits_topdown_info_reasons_2,
  input         io_in_bits_topdown_info_reasons_3,
  input         io_in_bits_topdown_info_reasons_4,
  input         io_in_bits_topdown_info_reasons_5,
  input         io_in_bits_topdown_info_reasons_6,
  input         io_in_bits_topdown_info_reasons_7,
  input         io_in_bits_topdown_info_reasons_8,
  input         io_in_bits_topdown_info_reasons_9,
  input         io_in_bits_topdown_info_reasons_10,
  input         io_in_bits_topdown_info_reasons_11,
  input         io_in_bits_topdown_info_reasons_12,
  input         io_in_bits_topdown_info_reasons_13,
  input         io_in_bits_topdown_info_reasons_14,
  input         io_in_bits_topdown_info_reasons_15,
  input         io_in_bits_topdown_info_reasons_16,
  input         io_in_bits_topdown_info_reasons_17,
  input         io_in_bits_topdown_info_reasons_18,
  input         io_in_bits_topdown_info_reasons_19,
  input         io_in_bits_topdown_info_reasons_20,
  input         io_in_bits_topdown_info_reasons_21,
  input         io_in_bits_topdown_info_reasons_22,
  input         io_in_bits_topdown_info_reasons_23,
  input         io_in_bits_topdown_info_reasons_24,
  input         io_in_bits_topdown_info_reasons_25,
  input         io_in_bits_topdown_info_reasons_26,
  input         io_in_bits_topdown_info_reasons_27,
  input         io_in_bits_topdown_info_reasons_28,
  input         io_in_bits_topdown_info_reasons_29,
  input         io_in_bits_topdown_info_reasons_30,
  input         io_in_bits_topdown_info_reasons_31,
  input         io_in_bits_topdown_info_reasons_32,
  input         io_in_bits_topdown_info_reasons_33,
  input         io_in_bits_topdown_info_reasons_34,
  input         io_in_bits_topdown_info_reasons_35,
  input         io_in_bits_topdown_info_reasons_36,
  input         io_in_bits_topdown_info_reasons_37,
  output        io_out_0_valid,
  output [31:0] io_out_0_bits_instr,
  output [49:0] io_out_0_bits_pc,
  output [9:0]  io_out_0_bits_foldpc,
  output        io_out_0_bits_exceptionVec_1,
  output        io_out_0_bits_exceptionVec_2,
  output        io_out_0_bits_exceptionVec_12,
  output        io_out_0_bits_exceptionVec_20,
  output        io_out_0_bits_backendException,
  output        io_out_0_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_0_bits_trigger,
  output        io_out_0_bits_pd_valid,
  output        io_out_0_bits_pd_isRVC,
  output [1:0]  io_out_0_bits_pd_brType,
  output        io_out_0_bits_pd_isCall,
  output        io_out_0_bits_pd_isRet,
  output        io_out_0_bits_pred_taken,
  output        io_out_0_bits_crossPageIPFFix,
  output        io_out_0_bits_ftqPtr_flag,
  output [5:0]  io_out_0_bits_ftqPtr_value,
  output [3:0]  io_out_0_bits_ftqOffset,
  output        io_out_0_bits_isLastInFtqEntry,
  output [55:0] io_out_0_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_0_bits_debug_seqNum_uopIdx,
  output        io_out_1_valid,
  output [31:0] io_out_1_bits_instr,
  output [49:0] io_out_1_bits_pc,
  output [9:0]  io_out_1_bits_foldpc,
  output        io_out_1_bits_exceptionVec_1,
  output        io_out_1_bits_exceptionVec_2,
  output        io_out_1_bits_exceptionVec_12,
  output        io_out_1_bits_exceptionVec_20,
  output        io_out_1_bits_backendException,
  output        io_out_1_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_1_bits_trigger,
  output        io_out_1_bits_pd_valid,
  output        io_out_1_bits_pd_isRVC,
  output [1:0]  io_out_1_bits_pd_brType,
  output        io_out_1_bits_pd_isCall,
  output        io_out_1_bits_pd_isRet,
  output        io_out_1_bits_pred_taken,
  output        io_out_1_bits_crossPageIPFFix,
  output        io_out_1_bits_ftqPtr_flag,
  output [5:0]  io_out_1_bits_ftqPtr_value,
  output [3:0]  io_out_1_bits_ftqOffset,
  output        io_out_1_bits_isLastInFtqEntry,
  output [55:0] io_out_1_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_1_bits_debug_seqNum_uopIdx,
  output        io_out_2_valid,
  output [31:0] io_out_2_bits_instr,
  output [49:0] io_out_2_bits_pc,
  output [9:0]  io_out_2_bits_foldpc,
  output        io_out_2_bits_exceptionVec_1,
  output        io_out_2_bits_exceptionVec_2,
  output        io_out_2_bits_exceptionVec_12,
  output        io_out_2_bits_exceptionVec_20,
  output        io_out_2_bits_backendException,
  output        io_out_2_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_2_bits_trigger,
  output        io_out_2_bits_pd_valid,
  output        io_out_2_bits_pd_isRVC,
  output [1:0]  io_out_2_bits_pd_brType,
  output        io_out_2_bits_pd_isCall,
  output        io_out_2_bits_pd_isRet,
  output        io_out_2_bits_pred_taken,
  output        io_out_2_bits_crossPageIPFFix,
  output        io_out_2_bits_ftqPtr_flag,
  output [5:0]  io_out_2_bits_ftqPtr_value,
  output [3:0]  io_out_2_bits_ftqOffset,
  output        io_out_2_bits_isLastInFtqEntry,
  output [55:0] io_out_2_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_2_bits_debug_seqNum_uopIdx,
  output        io_out_3_valid,
  output [31:0] io_out_3_bits_instr,
  output [49:0] io_out_3_bits_pc,
  output [9:0]  io_out_3_bits_foldpc,
  output        io_out_3_bits_exceptionVec_1,
  output        io_out_3_bits_exceptionVec_2,
  output        io_out_3_bits_exceptionVec_12,
  output        io_out_3_bits_exceptionVec_20,
  output        io_out_3_bits_backendException,
  output        io_out_3_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_3_bits_trigger,
  output        io_out_3_bits_pd_valid,
  output        io_out_3_bits_pd_isRVC,
  output [1:0]  io_out_3_bits_pd_brType,
  output        io_out_3_bits_pd_isCall,
  output        io_out_3_bits_pd_isRet,
  output        io_out_3_bits_pred_taken,
  output        io_out_3_bits_crossPageIPFFix,
  output        io_out_3_bits_ftqPtr_flag,
  output [5:0]  io_out_3_bits_ftqPtr_value,
  output [3:0]  io_out_3_bits_ftqOffset,
  output        io_out_3_bits_isLastInFtqEntry,
  output [55:0] io_out_3_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_3_bits_debug_seqNum_uopIdx,
  output        io_out_4_valid,
  output [31:0] io_out_4_bits_instr,
  output [49:0] io_out_4_bits_pc,
  output [9:0]  io_out_4_bits_foldpc,
  output        io_out_4_bits_exceptionVec_1,
  output        io_out_4_bits_exceptionVec_2,
  output        io_out_4_bits_exceptionVec_12,
  output        io_out_4_bits_exceptionVec_20,
  output        io_out_4_bits_backendException,
  output        io_out_4_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_4_bits_trigger,
  output        io_out_4_bits_pd_valid,
  output        io_out_4_bits_pd_isRVC,
  output [1:0]  io_out_4_bits_pd_brType,
  output        io_out_4_bits_pd_isCall,
  output        io_out_4_bits_pd_isRet,
  output        io_out_4_bits_pred_taken,
  output        io_out_4_bits_crossPageIPFFix,
  output        io_out_4_bits_ftqPtr_flag,
  output [5:0]  io_out_4_bits_ftqPtr_value,
  output [3:0]  io_out_4_bits_ftqOffset,
  output        io_out_4_bits_isLastInFtqEntry,
  output [55:0] io_out_4_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_4_bits_debug_seqNum_uopIdx,
  output        io_out_5_valid,
  output [31:0] io_out_5_bits_instr,
  output [49:0] io_out_5_bits_pc,
  output [9:0]  io_out_5_bits_foldpc,
  output        io_out_5_bits_exceptionVec_1,
  output        io_out_5_bits_exceptionVec_2,
  output        io_out_5_bits_exceptionVec_12,
  output        io_out_5_bits_exceptionVec_20,
  output        io_out_5_bits_backendException,
  output        io_out_5_bits_satpFlushFirstFetchFault,
  output [3:0]  io_out_5_bits_trigger,
  output        io_out_5_bits_pd_valid,
  output        io_out_5_bits_pd_isRVC,
  output [1:0]  io_out_5_bits_pd_brType,
  output        io_out_5_bits_pd_isCall,
  output        io_out_5_bits_pd_isRet,
  output        io_out_5_bits_pred_taken,
  output        io_out_5_bits_crossPageIPFFix,
  output        io_out_5_bits_ftqPtr_flag,
  output [5:0]  io_out_5_bits_ftqPtr_value,
  output [3:0]  io_out_5_bits_ftqOffset,
  output        io_out_5_bits_isLastInFtqEntry,
  output [55:0] io_out_5_bits_debug_seqNum_seqNum,
  output [7:0]  io_out_5_bits_debug_seqNum_uopIdx,
  input         io_decodeCanAccept,
  output [5:0]  io_stallReason_reason_0,
  output [5:0]  io_stallReason_reason_1,
  output [5:0]  io_stallReason_reason_2,
  output [5:0]  io_stallReason_reason_3,
  output [5:0]  io_stallReason_reason_4,
  output [5:0]  io_stallReason_reason_5,
  input         io_stallReason_backReason_valid,
  input  [5:0]  io_stallReason_backReason_bits,
  output [5:0]  io_perf_0_value,
  output [5:0]  io_perf_1_value,
  output [5:0]  io_perf_2_value,
  output [5:0]  io_perf_3_value,
  output [5:0]  io_perf_4_value,
  output [5:0]  io_perf_5_value,
  output [5:0]  io_perf_6_value,
  output [5:0]  io_perf_7_value,
  output [5:0]  io_perf_8_value
);

  // ---- 入队侧：16 条 lane 的扁平端口打包成数组 ----
  wire [15:0][31:0] core_in_instr =
      {io_in_bits_instrs_15,
       io_in_bits_instrs_14,
       io_in_bits_instrs_13,
       io_in_bits_instrs_12,
       io_in_bits_instrs_11,
       io_in_bits_instrs_10,
       io_in_bits_instrs_9,
       io_in_bits_instrs_8,
       io_in_bits_instrs_7,
       io_in_bits_instrs_6,
       io_in_bits_instrs_5,
       io_in_bits_instrs_4,
       io_in_bits_instrs_3,
       io_in_bits_instrs_2,
       io_in_bits_instrs_1,
       io_in_bits_instrs_0};
  wire [15:0][49:0] core_in_pc =
      {io_in_bits_pc_15,
       io_in_bits_pc_14,
       io_in_bits_pc_13,
       io_in_bits_pc_12,
       io_in_bits_pc_11,
       io_in_bits_pc_10,
       io_in_bits_pc_9,
       io_in_bits_pc_8,
       io_in_bits_pc_7,
       io_in_bits_pc_6,
       io_in_bits_pc_5,
       io_in_bits_pc_4,
       io_in_bits_pc_3,
       io_in_bits_pc_2,
       io_in_bits_pc_1,
       io_in_bits_pc_0};
  wire [15:0][9:0]  core_in_foldpc =
      {io_in_bits_foldpc_15,
       io_in_bits_foldpc_14,
       io_in_bits_foldpc_13,
       io_in_bits_foldpc_12,
       io_in_bits_foldpc_11,
       io_in_bits_foldpc_10,
       io_in_bits_foldpc_9,
       io_in_bits_foldpc_8,
       io_in_bits_foldpc_7,
       io_in_bits_foldpc_6,
       io_in_bits_foldpc_5,
       io_in_bits_foldpc_4,
       io_in_bits_foldpc_3,
       io_in_bits_foldpc_2,
       io_in_bits_foldpc_1,
       io_in_bits_foldpc_0};
  wire [15:0]       core_in_pd_isRVC =
      {io_in_bits_pd_15_isRVC,
       io_in_bits_pd_14_isRVC,
       io_in_bits_pd_13_isRVC,
       io_in_bits_pd_12_isRVC,
       io_in_bits_pd_11_isRVC,
       io_in_bits_pd_10_isRVC,
       io_in_bits_pd_9_isRVC,
       io_in_bits_pd_8_isRVC,
       io_in_bits_pd_7_isRVC,
       io_in_bits_pd_6_isRVC,
       io_in_bits_pd_5_isRVC,
       io_in_bits_pd_4_isRVC,
       io_in_bits_pd_3_isRVC,
       io_in_bits_pd_2_isRVC,
       io_in_bits_pd_1_isRVC,
       io_in_bits_pd_0_isRVC};
  wire [15:0][1:0]  core_in_pd_brType =
      {io_in_bits_pd_15_brType,
       io_in_bits_pd_14_brType,
       io_in_bits_pd_13_brType,
       io_in_bits_pd_12_brType,
       io_in_bits_pd_11_brType,
       io_in_bits_pd_10_brType,
       io_in_bits_pd_9_brType,
       io_in_bits_pd_8_brType,
       io_in_bits_pd_7_brType,
       io_in_bits_pd_6_brType,
       io_in_bits_pd_5_brType,
       io_in_bits_pd_4_brType,
       io_in_bits_pd_3_brType,
       io_in_bits_pd_2_brType,
       io_in_bits_pd_1_brType,
       io_in_bits_pd_0_brType};
  wire [15:0]       core_in_pd_isCall =
      {io_in_bits_pd_15_isCall,
       io_in_bits_pd_14_isCall,
       io_in_bits_pd_13_isCall,
       io_in_bits_pd_12_isCall,
       io_in_bits_pd_11_isCall,
       io_in_bits_pd_10_isCall,
       io_in_bits_pd_9_isCall,
       io_in_bits_pd_8_isCall,
       io_in_bits_pd_7_isCall,
       io_in_bits_pd_6_isCall,
       io_in_bits_pd_5_isCall,
       io_in_bits_pd_4_isCall,
       io_in_bits_pd_3_isCall,
       io_in_bits_pd_2_isCall,
       io_in_bits_pd_1_isCall,
       io_in_bits_pd_0_isCall};
  wire [15:0]       core_in_pd_isRet =
      {io_in_bits_pd_15_isRet,
       io_in_bits_pd_14_isRet,
       io_in_bits_pd_13_isRet,
       io_in_bits_pd_12_isRet,
       io_in_bits_pd_11_isRet,
       io_in_bits_pd_10_isRet,
       io_in_bits_pd_9_isRet,
       io_in_bits_pd_8_isRet,
       io_in_bits_pd_7_isRet,
       io_in_bits_pd_6_isRet,
       io_in_bits_pd_5_isRet,
       io_in_bits_pd_4_isRet,
       io_in_bits_pd_3_isRet,
       io_in_bits_pd_2_isRet,
       io_in_bits_pd_1_isRet,
       io_in_bits_pd_0_isRet};
  wire [15:0]       core_in_ftqOff_v =
      {io_in_bits_ftqOffset_15_valid,
       io_in_bits_ftqOffset_14_valid,
       io_in_bits_ftqOffset_13_valid,
       io_in_bits_ftqOffset_12_valid,
       io_in_bits_ftqOffset_11_valid,
       io_in_bits_ftqOffset_10_valid,
       io_in_bits_ftqOffset_9_valid,
       io_in_bits_ftqOffset_8_valid,
       io_in_bits_ftqOffset_7_valid,
       io_in_bits_ftqOffset_6_valid,
       io_in_bits_ftqOffset_5_valid,
       io_in_bits_ftqOffset_4_valid,
       io_in_bits_ftqOffset_3_valid,
       io_in_bits_ftqOffset_2_valid,
       io_in_bits_ftqOffset_1_valid,
       io_in_bits_ftqOffset_0_valid};
  wire [15:0][1:0]  core_in_excp_type =
      {io_in_bits_exceptionType_15,
       io_in_bits_exceptionType_14,
       io_in_bits_exceptionType_13,
       io_in_bits_exceptionType_12,
       io_in_bits_exceptionType_11,
       io_in_bits_exceptionType_10,
       io_in_bits_exceptionType_9,
       io_in_bits_exceptionType_8,
       io_in_bits_exceptionType_7,
       io_in_bits_exceptionType_6,
       io_in_bits_exceptionType_5,
       io_in_bits_exceptionType_4,
       io_in_bits_exceptionType_3,
       io_in_bits_exceptionType_2,
       io_in_bits_exceptionType_1,
       io_in_bits_exceptionType_0};
  wire [15:0]       core_in_crosspage =
      {io_in_bits_crossPageIPFFix_15,
       io_in_bits_crossPageIPFFix_14,
       io_in_bits_crossPageIPFFix_13,
       io_in_bits_crossPageIPFFix_12,
       io_in_bits_crossPageIPFFix_11,
       io_in_bits_crossPageIPFFix_10,
       io_in_bits_crossPageIPFFix_9,
       io_in_bits_crossPageIPFFix_8,
       io_in_bits_crossPageIPFFix_7,
       io_in_bits_crossPageIPFFix_6,
       io_in_bits_crossPageIPFFix_5,
       io_in_bits_crossPageIPFFix_4,
       io_in_bits_crossPageIPFFix_3,
       io_in_bits_crossPageIPFFix_2,
       io_in_bits_crossPageIPFFix_1,
       io_in_bits_crossPageIPFFix_0};
  wire [15:0]       core_in_illegal =
      {io_in_bits_illegalInstr_15,
       io_in_bits_illegalInstr_14,
       io_in_bits_illegalInstr_13,
       io_in_bits_illegalInstr_12,
       io_in_bits_illegalInstr_11,
       io_in_bits_illegalInstr_10,
       io_in_bits_illegalInstr_9,
       io_in_bits_illegalInstr_8,
       io_in_bits_illegalInstr_7,
       io_in_bits_illegalInstr_6,
       io_in_bits_illegalInstr_5,
       io_in_bits_illegalInstr_4,
       io_in_bits_illegalInstr_3,
       io_in_bits_illegalInstr_2,
       io_in_bits_illegalInstr_1,
       io_in_bits_illegalInstr_0};
  wire [15:0][3:0]  core_in_triggered =
      {io_in_bits_triggered_15,
       io_in_bits_triggered_14,
       io_in_bits_triggered_13,
       io_in_bits_triggered_12,
       io_in_bits_triggered_11,
       io_in_bits_triggered_10,
       io_in_bits_triggered_9,
       io_in_bits_triggered_8,
       io_in_bits_triggered_7,
       io_in_bits_triggered_6,
       io_in_bits_triggered_5,
       io_in_bits_triggered_4,
       io_in_bits_triggered_3,
       io_in_bits_triggered_2,
       io_in_bits_triggered_1,
       io_in_bits_triggered_0};
  wire [15:0]       core_in_lastftq =
      {io_in_bits_isLastInFtqEntry_15,
       io_in_bits_isLastInFtqEntry_14,
       io_in_bits_isLastInFtqEntry_13,
       io_in_bits_isLastInFtqEntry_12,
       io_in_bits_isLastInFtqEntry_11,
       io_in_bits_isLastInFtqEntry_10,
       io_in_bits_isLastInFtqEntry_9,
       io_in_bits_isLastInFtqEntry_8,
       io_in_bits_isLastInFtqEntry_7,
       io_in_bits_isLastInFtqEntry_6,
       io_in_bits_isLastInFtqEntry_5,
       io_in_bits_isLastInFtqEntry_4,
       io_in_bits_isLastInFtqEntry_3,
       io_in_bits_isLastInFtqEntry_2,
       io_in_bits_isLastInFtqEntry_1,
       io_in_bits_isLastInFtqEntry_0};
  wire [37:0]       core_in_topdown =
      {io_in_bits_topdown_info_reasons_37,
       io_in_bits_topdown_info_reasons_36,
       io_in_bits_topdown_info_reasons_35,
       io_in_bits_topdown_info_reasons_34,
       io_in_bits_topdown_info_reasons_33,
       io_in_bits_topdown_info_reasons_32,
       io_in_bits_topdown_info_reasons_31,
       io_in_bits_topdown_info_reasons_30,
       io_in_bits_topdown_info_reasons_29,
       io_in_bits_topdown_info_reasons_28,
       io_in_bits_topdown_info_reasons_27,
       io_in_bits_topdown_info_reasons_26,
       io_in_bits_topdown_info_reasons_25,
       io_in_bits_topdown_info_reasons_24,
       io_in_bits_topdown_info_reasons_23,
       io_in_bits_topdown_info_reasons_22,
       io_in_bits_topdown_info_reasons_21,
       io_in_bits_topdown_info_reasons_20,
       io_in_bits_topdown_info_reasons_19,
       io_in_bits_topdown_info_reasons_18,
       io_in_bits_topdown_info_reasons_17,
       io_in_bits_topdown_info_reasons_16,
       io_in_bits_topdown_info_reasons_15,
       io_in_bits_topdown_info_reasons_14,
       io_in_bits_topdown_info_reasons_13,
       io_in_bits_topdown_info_reasons_12,
       io_in_bits_topdown_info_reasons_11,
       io_in_bits_topdown_info_reasons_10,
       io_in_bits_topdown_info_reasons_9,
       io_in_bits_topdown_info_reasons_8,
       io_in_bits_topdown_info_reasons_7,
       io_in_bits_topdown_info_reasons_6,
       io_in_bits_topdown_info_reasons_5,
       io_in_bits_topdown_info_reasons_4,
       io_in_bits_topdown_info_reasons_3,
       io_in_bits_topdown_info_reasons_2,
       io_in_bits_topdown_info_reasons_1,
       io_in_bits_topdown_info_reasons_0};
  // ★ lane0 的 pd.valid 在 golden 里被折成常数 1，端口表里没有这根线 ★
  wire [15:0]       core_in_pd_valid =
      {io_in_bits_pd_15_valid,
       io_in_bits_pd_14_valid,
       io_in_bits_pd_13_valid,
       io_in_bits_pd_12_valid,
       io_in_bits_pd_11_valid,
       io_in_bits_pd_10_valid,
       io_in_bits_pd_9_valid,
       io_in_bits_pd_8_valid,
       io_in_bits_pd_7_valid,
       io_in_bits_pd_6_valid,
       io_in_bits_pd_5_valid,
       io_in_bits_pd_4_valid,
       io_in_bits_pd_3_valid,
       io_in_bits_pd_2_valid,
       io_in_bits_pd_1_valid,
       1'b1};
  // ★ backendException / satpFlushFirstFetchFault 只有 lane0 有端口，其余 15 路 golden 恒 0 ★
  wire [15:0]       core_in_backexcp  = {15'h0, io_in_bits_backendException_0};
  wire [15:0]       core_in_satpflush = {15'h0, io_in_bits_satpFlushFirstFetchFault_0};

  // ---- 出队侧：核的数组输出 ----
  wire [5:0]              core_out_valid;
  ibuffer_pkg::ibuf_entry_t [5:0] core_out_bits;
  wire [5:0]              core_out_af, core_out_ii, core_out_pf,
                          core_out_gpf, core_out_crosspage;
  wire [5:0][55:0]        core_out_seqnum;
  wire [5:0][7:0]         core_out_uopidx;
  wire [5:0][5:0]         core_stall_reason;
  wire [8:0][5:0]         core_perf;

  xs_IBuffer_core u_core (
    .clock               (clock),
    .reset               (reset),
    .flush               (io_flush),
    .ctrl_redirect       (io_ControlRedirect),
    .ctrl_btb_miss       (io_ControlBTBMissBubble),
    .tage_miss           (io_TAGEMissBubble),
    .sc_miss             (io_SCMissBubble),
    .ittage_miss         (io_ITTAGEMissBubble),
    .ras_miss            (io_RASMissBubble),
    .memvio_redirect     (io_MemVioRedirect),
    .in_ready            (io_in_ready),
    .in_valid            (io_in_valid),
    .in_instr_valid      (io_in_bits_valid),
    .in_enq_enable       (io_in_bits_enqEnable),
    .in_instr            (core_in_instr),
    .in_pc               (core_in_pc),
    .in_foldpc           (core_in_foldpc),
    .in_pd_valid         (core_in_pd_valid),
    .in_pd_isRVC         (core_in_pd_isRVC),
    .in_pd_brType        (core_in_pd_brType),
    .in_pd_isCall        (core_in_pd_isCall),
    .in_pd_isRet         (core_in_pd_isRet),
    .in_ftqOffset_valid  (core_in_ftqOff_v),
    .in_ftqPtr_flag      (io_in_bits_ftqPtr_flag),
    .in_ftqPtr_value     (io_in_bits_ftqPtr_value),
    .in_excp_type        (core_in_excp_type),
    .in_crosspage        (core_in_crosspage),
    .in_illegal_instr    (core_in_illegal),
    .in_backend_excp     (core_in_backexcp),
    .in_satp_flush_first (core_in_satpflush),
    .in_triggered        (core_in_triggered),
    .in_last_in_ftq      (core_in_lastftq),
    .in_topdown_reasons  (core_in_topdown),
    .decode_can_accept   (io_decodeCanAccept),
    .out_valid           (core_out_valid),
    .out_bits            (core_out_bits),
    .out_excp_af         (core_out_af),
    .out_excp_ii         (core_out_ii),
    .out_excp_pf         (core_out_pf),
    .out_excp_gpf        (core_out_gpf),
    .out_crosspage       (core_out_crosspage),
    .out_seqnum          (core_out_seqnum),
    .out_uopidx          (core_out_uopidx),
    .stall_reason        (core_stall_reason),
    .back_reason_valid   (io_stallReason_backReason_valid),
    .back_reason_bits    (io_stallReason_backReason_bits),
    .perf_value          (core_perf)
  );

  // ---- 出队侧：数组拆回扁平 io_out_* ----
  assign io_out_0_valid = core_out_valid[0];
  assign io_out_0_bits_instr = core_out_bits[0].inst;
  assign io_out_0_bits_pc = core_out_bits[0].pc;
  assign io_out_0_bits_foldpc = core_out_bits[0].foldpc;
  assign io_out_0_bits_exceptionVec_1 = core_out_af[0];
  assign io_out_0_bits_exceptionVec_2 = core_out_ii[0];
  assign io_out_0_bits_exceptionVec_12 = core_out_pf[0];
  assign io_out_0_bits_exceptionVec_20 = core_out_gpf[0];
  assign io_out_0_bits_backendException = core_out_bits[0].backendException;
  assign io_out_0_bits_satpFlushFirstFetchFault = core_out_bits[0].satpFlushFirstFetchFault;
  assign io_out_0_bits_trigger = core_out_bits[0].triggered;
  assign io_out_0_bits_pd_valid = core_out_bits[0].pd_valid;
  assign io_out_0_bits_pd_isRVC = core_out_bits[0].pd_isRVC;
  assign io_out_0_bits_pd_brType = core_out_bits[0].pd_brType;
  assign io_out_0_bits_pd_isCall = core_out_bits[0].pd_isCall;
  assign io_out_0_bits_pd_isRet = core_out_bits[0].pd_isRet;
  assign io_out_0_bits_pred_taken = core_out_bits[0].pred_taken;
  assign io_out_0_bits_crossPageIPFFix = core_out_crosspage[0];
  assign io_out_0_bits_ftqPtr_flag = core_out_bits[0].ftqPtr_flag;
  assign io_out_0_bits_ftqPtr_value = core_out_bits[0].ftqPtr_value;
  assign io_out_0_bits_ftqOffset = core_out_bits[0].ftqOffset;
  assign io_out_0_bits_isLastInFtqEntry = core_out_bits[0].isLastInFtqEntry;
  assign io_out_0_bits_debug_seqNum_seqNum = core_out_seqnum[0];
  assign io_out_0_bits_debug_seqNum_uopIdx = core_out_uopidx[0];
  assign io_out_1_valid = core_out_valid[1];
  assign io_out_1_bits_instr = core_out_bits[1].inst;
  assign io_out_1_bits_pc = core_out_bits[1].pc;
  assign io_out_1_bits_foldpc = core_out_bits[1].foldpc;
  assign io_out_1_bits_exceptionVec_1 = core_out_af[1];
  assign io_out_1_bits_exceptionVec_2 = core_out_ii[1];
  assign io_out_1_bits_exceptionVec_12 = core_out_pf[1];
  assign io_out_1_bits_exceptionVec_20 = core_out_gpf[1];
  assign io_out_1_bits_backendException = core_out_bits[1].backendException;
  assign io_out_1_bits_satpFlushFirstFetchFault = core_out_bits[1].satpFlushFirstFetchFault;
  assign io_out_1_bits_trigger = core_out_bits[1].triggered;
  assign io_out_1_bits_pd_valid = core_out_bits[1].pd_valid;
  assign io_out_1_bits_pd_isRVC = core_out_bits[1].pd_isRVC;
  assign io_out_1_bits_pd_brType = core_out_bits[1].pd_brType;
  assign io_out_1_bits_pd_isCall = core_out_bits[1].pd_isCall;
  assign io_out_1_bits_pd_isRet = core_out_bits[1].pd_isRet;
  assign io_out_1_bits_pred_taken = core_out_bits[1].pred_taken;
  assign io_out_1_bits_crossPageIPFFix = core_out_crosspage[1];
  assign io_out_1_bits_ftqPtr_flag = core_out_bits[1].ftqPtr_flag;
  assign io_out_1_bits_ftqPtr_value = core_out_bits[1].ftqPtr_value;
  assign io_out_1_bits_ftqOffset = core_out_bits[1].ftqOffset;
  assign io_out_1_bits_isLastInFtqEntry = core_out_bits[1].isLastInFtqEntry;
  assign io_out_1_bits_debug_seqNum_seqNum = core_out_seqnum[1];
  assign io_out_1_bits_debug_seqNum_uopIdx = core_out_uopidx[1];
  assign io_out_2_valid = core_out_valid[2];
  assign io_out_2_bits_instr = core_out_bits[2].inst;
  assign io_out_2_bits_pc = core_out_bits[2].pc;
  assign io_out_2_bits_foldpc = core_out_bits[2].foldpc;
  assign io_out_2_bits_exceptionVec_1 = core_out_af[2];
  assign io_out_2_bits_exceptionVec_2 = core_out_ii[2];
  assign io_out_2_bits_exceptionVec_12 = core_out_pf[2];
  assign io_out_2_bits_exceptionVec_20 = core_out_gpf[2];
  assign io_out_2_bits_backendException = core_out_bits[2].backendException;
  assign io_out_2_bits_satpFlushFirstFetchFault = core_out_bits[2].satpFlushFirstFetchFault;
  assign io_out_2_bits_trigger = core_out_bits[2].triggered;
  assign io_out_2_bits_pd_valid = core_out_bits[2].pd_valid;
  assign io_out_2_bits_pd_isRVC = core_out_bits[2].pd_isRVC;
  assign io_out_2_bits_pd_brType = core_out_bits[2].pd_brType;
  assign io_out_2_bits_pd_isCall = core_out_bits[2].pd_isCall;
  assign io_out_2_bits_pd_isRet = core_out_bits[2].pd_isRet;
  assign io_out_2_bits_pred_taken = core_out_bits[2].pred_taken;
  assign io_out_2_bits_crossPageIPFFix = core_out_crosspage[2];
  assign io_out_2_bits_ftqPtr_flag = core_out_bits[2].ftqPtr_flag;
  assign io_out_2_bits_ftqPtr_value = core_out_bits[2].ftqPtr_value;
  assign io_out_2_bits_ftqOffset = core_out_bits[2].ftqOffset;
  assign io_out_2_bits_isLastInFtqEntry = core_out_bits[2].isLastInFtqEntry;
  assign io_out_2_bits_debug_seqNum_seqNum = core_out_seqnum[2];
  assign io_out_2_bits_debug_seqNum_uopIdx = core_out_uopidx[2];
  assign io_out_3_valid = core_out_valid[3];
  assign io_out_3_bits_instr = core_out_bits[3].inst;
  assign io_out_3_bits_pc = core_out_bits[3].pc;
  assign io_out_3_bits_foldpc = core_out_bits[3].foldpc;
  assign io_out_3_bits_exceptionVec_1 = core_out_af[3];
  assign io_out_3_bits_exceptionVec_2 = core_out_ii[3];
  assign io_out_3_bits_exceptionVec_12 = core_out_pf[3];
  assign io_out_3_bits_exceptionVec_20 = core_out_gpf[3];
  assign io_out_3_bits_backendException = core_out_bits[3].backendException;
  assign io_out_3_bits_satpFlushFirstFetchFault = core_out_bits[3].satpFlushFirstFetchFault;
  assign io_out_3_bits_trigger = core_out_bits[3].triggered;
  assign io_out_3_bits_pd_valid = core_out_bits[3].pd_valid;
  assign io_out_3_bits_pd_isRVC = core_out_bits[3].pd_isRVC;
  assign io_out_3_bits_pd_brType = core_out_bits[3].pd_brType;
  assign io_out_3_bits_pd_isCall = core_out_bits[3].pd_isCall;
  assign io_out_3_bits_pd_isRet = core_out_bits[3].pd_isRet;
  assign io_out_3_bits_pred_taken = core_out_bits[3].pred_taken;
  assign io_out_3_bits_crossPageIPFFix = core_out_crosspage[3];
  assign io_out_3_bits_ftqPtr_flag = core_out_bits[3].ftqPtr_flag;
  assign io_out_3_bits_ftqPtr_value = core_out_bits[3].ftqPtr_value;
  assign io_out_3_bits_ftqOffset = core_out_bits[3].ftqOffset;
  assign io_out_3_bits_isLastInFtqEntry = core_out_bits[3].isLastInFtqEntry;
  assign io_out_3_bits_debug_seqNum_seqNum = core_out_seqnum[3];
  assign io_out_3_bits_debug_seqNum_uopIdx = core_out_uopidx[3];
  assign io_out_4_valid = core_out_valid[4];
  assign io_out_4_bits_instr = core_out_bits[4].inst;
  assign io_out_4_bits_pc = core_out_bits[4].pc;
  assign io_out_4_bits_foldpc = core_out_bits[4].foldpc;
  assign io_out_4_bits_exceptionVec_1 = core_out_af[4];
  assign io_out_4_bits_exceptionVec_2 = core_out_ii[4];
  assign io_out_4_bits_exceptionVec_12 = core_out_pf[4];
  assign io_out_4_bits_exceptionVec_20 = core_out_gpf[4];
  assign io_out_4_bits_backendException = core_out_bits[4].backendException;
  assign io_out_4_bits_satpFlushFirstFetchFault = core_out_bits[4].satpFlushFirstFetchFault;
  assign io_out_4_bits_trigger = core_out_bits[4].triggered;
  assign io_out_4_bits_pd_valid = core_out_bits[4].pd_valid;
  assign io_out_4_bits_pd_isRVC = core_out_bits[4].pd_isRVC;
  assign io_out_4_bits_pd_brType = core_out_bits[4].pd_brType;
  assign io_out_4_bits_pd_isCall = core_out_bits[4].pd_isCall;
  assign io_out_4_bits_pd_isRet = core_out_bits[4].pd_isRet;
  assign io_out_4_bits_pred_taken = core_out_bits[4].pred_taken;
  assign io_out_4_bits_crossPageIPFFix = core_out_crosspage[4];
  assign io_out_4_bits_ftqPtr_flag = core_out_bits[4].ftqPtr_flag;
  assign io_out_4_bits_ftqPtr_value = core_out_bits[4].ftqPtr_value;
  assign io_out_4_bits_ftqOffset = core_out_bits[4].ftqOffset;
  assign io_out_4_bits_isLastInFtqEntry = core_out_bits[4].isLastInFtqEntry;
  assign io_out_4_bits_debug_seqNum_seqNum = core_out_seqnum[4];
  assign io_out_4_bits_debug_seqNum_uopIdx = core_out_uopidx[4];
  assign io_out_5_valid = core_out_valid[5];
  assign io_out_5_bits_instr = core_out_bits[5].inst;
  assign io_out_5_bits_pc = core_out_bits[5].pc;
  assign io_out_5_bits_foldpc = core_out_bits[5].foldpc;
  assign io_out_5_bits_exceptionVec_1 = core_out_af[5];
  assign io_out_5_bits_exceptionVec_2 = core_out_ii[5];
  assign io_out_5_bits_exceptionVec_12 = core_out_pf[5];
  assign io_out_5_bits_exceptionVec_20 = core_out_gpf[5];
  assign io_out_5_bits_backendException = core_out_bits[5].backendException;
  assign io_out_5_bits_satpFlushFirstFetchFault = core_out_bits[5].satpFlushFirstFetchFault;
  assign io_out_5_bits_trigger = core_out_bits[5].triggered;
  assign io_out_5_bits_pd_valid = core_out_bits[5].pd_valid;
  assign io_out_5_bits_pd_isRVC = core_out_bits[5].pd_isRVC;
  assign io_out_5_bits_pd_brType = core_out_bits[5].pd_brType;
  assign io_out_5_bits_pd_isCall = core_out_bits[5].pd_isCall;
  assign io_out_5_bits_pd_isRet = core_out_bits[5].pd_isRet;
  assign io_out_5_bits_pred_taken = core_out_bits[5].pred_taken;
  assign io_out_5_bits_crossPageIPFFix = core_out_crosspage[5];
  assign io_out_5_bits_ftqPtr_flag = core_out_bits[5].ftqPtr_flag;
  assign io_out_5_bits_ftqPtr_value = core_out_bits[5].ftqPtr_value;
  assign io_out_5_bits_ftqOffset = core_out_bits[5].ftqOffset;
  assign io_out_5_bits_isLastInFtqEntry = core_out_bits[5].isLastInFtqEntry;
  assign io_out_5_bits_debug_seqNum_seqNum = core_out_seqnum[5];
  assign io_out_5_bits_debug_seqNum_uopIdx = core_out_uopidx[5];
  assign io_stallReason_reason_0 = core_stall_reason[0];
  assign io_stallReason_reason_1 = core_stall_reason[1];
  assign io_stallReason_reason_2 = core_stall_reason[2];
  assign io_stallReason_reason_3 = core_stall_reason[3];
  assign io_stallReason_reason_4 = core_stall_reason[4];
  assign io_stallReason_reason_5 = core_stall_reason[5];
  assign io_perf_0_value = core_perf[0];
  assign io_perf_1_value = core_perf[1];
  assign io_perf_2_value = core_perf[2];
  assign io_perf_3_value = core_perf[3];
  assign io_perf_4_value = core_perf[4];
  assign io_perf_5_value = core_perf[5];
  assign io_perf_6_value = core_perf[6];
  assign io_perf_7_value = core_perf[7];
  assign io_perf_8_value = core_perf[8];

endmodule : IBuffer
// END GENERATED


