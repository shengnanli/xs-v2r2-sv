// =============================================================================
// xs_IBuffer_core —— 指令缓冲（Instruction Buffer），前端取指与后端译码之间的解耦队列
//
// 对应 Chisel: xiangshan.frontend.IBuffer（KunMingHu V2R2 参数）
//
// 【在前端中的位置】
//   IFU(取指) → IBuffer → Decode(译码)
//   IFU 一次最多送来 PredictWidth(=16) 条预测窗口里的（半）指令，但能否入队由
//   enqEnable 掩码决定；Decode 一次最多取 DecodeWidth(=6) 条。两侧节奏不一致，
//   IBuffer 用一个环形 FIFO 把它们解耦：取指快时把指令暂存，译码快时连续供给。
//
// 【为什么用裸寄存器而不是 SRAM】
//   IBuffer 是一个很大的队列（IBufSize=48 项），但读写端口数量多且时序敏感：
//   一拍最多写入 16 条、读出 6 条。若用 SRAM 难以提供这么多端口，故用裸寄存器
//   阵列 ibuf[48]，再通过精心设计的读写选择逻辑控制端口。
//
//   入队：每个 ibuf 项前面挂一个 PredictWidth→1 的 Mux（哪条 fetch 指令写进来）。
//   出队：把 48 项按 IBufNBank(=6) 个 bank 交织编址（项 idx 属于 bank idx%6），
//         读端口组织成「分 bank 的 FIFO」——每拍每个 bank 顺序读出不超过 1 项，
//         先在 bank 内 bankSize(=8)→1 选出候选，再在 6 个 bank 间 6→1 选出，
//         两级 Mux 比 48→1 单级省面积且延迟相近。
//
// 【三组出队指针】（都是循环队列指针 CircularQueuePtr：{flag, value}）
//   - deqPtr        : 全局出队指针（0..47，flag 区分绕回），用于 distanceBetween。
//   - deqBankPtrVec : DecodeWidth 个 bank 指针，第 i 个译码槽从第 (deqBankPtr0+i) 个
//                     bank 读；整体每拍前进 numDeq。
//   - deqInBankPtr  : 每个 bank 内部的偏移指针（0..bankSize-1）；某 bank 这拍被读到
//                     才 +1。三者满足 deqPtr == bank + inBank*IBufNBank 的一致性。
//
// 【bypass 空缓冲直通】
//   当队列为空(enqPtr==deqPtr) 且 Decode 可接收时，新到的 fetch 指令不必先写进
//   ibuf 再读出，而是直接旁路送进输出寄存器，省一拍延迟。超过 DecodeWidth 的部分
//   仍照常入队。
//
// 【输出寄存器 outputEntries】
//   出队结果先打入 DecodeWidth 个输出寄存器再送给 Decode。当 Decode 不接收但输出
//   寄存器尚未填满时，可以继续从队列补齐（把新读出的拼接到已有有效项之后）。
// =============================================================================
module xs_IBuffer_core #(
  parameter int IBufSize     = 48,  // 队列总深度
  parameter int IBufNBank    = 6,   // bank 数（出队交织）
  parameter int DecodeWidth  = 6,   // 每拍最多出队 / 输出寄存器数
  parameter int PredictWidth = 16,  // 每拍最多入队（预测窗口宽度）
  parameter int VAddrBits    = 50,  // 虚地址位宽
  parameter int FoldPCBits   = 10,  // 折叠 PC 位宽（MemPredPCWidth）
  parameter int FtqPtrBits   = 6    // FtqPtr.value 位宽
) (
  input  logic clock,
  input  logic reset,

  // ---- flush / redirect 控制 ----
  input  logic flush,                 // 冲刷整个 IBuffer（重定向时）
  input  logic ControlRedirect,       // 以下信号仅用于 TopDown 性能归因
  input  logic ControlBTBMissBubble,
  input  logic TAGEMissBubble,
  input  logic SCMissBubble,
  input  logic ITTAGEMissBubble,
  input  logic RASMissBubble,
  input  logic MemVioRedirect,

  // ---- 入队侧（来自 IFU，DecoupledIO<FetchToIBuffer>）----
  output logic                          in_ready,
  input  logic                          in_valid,
  input  logic [PredictWidth-1:0][31:0] in_instrs,
  input  logic [PredictWidth-1:0]       in_valid_mask,   // 各槽是否为有效指令
  input  logic [PredictWidth-1:0]       in_enqEnable,    // 各槽是否允许入队
  input  logic [PredictWidth-1:0]       in_pd_isRVC,
  input  logic [PredictWidth-1:0][1:0]  in_pd_brType,
  input  logic [PredictWidth-1:0][FoldPCBits-1:0] in_foldpc,
  input  logic [PredictWidth-1:0]       in_ftqOffset_valid, // 即 pred_taken
  input  logic                          in_backendException0,// 仅槽0有该字段
  input  logic [PredictWidth-1:0][1:0]  in_exceptionType,
  input  logic [PredictWidth-1:0]       in_crossPageIPFFix,
  input  logic [PredictWidth-1:0]       in_illegalInstr,
  input  logic [PredictWidth-1:0][3:0]  in_triggered,
  input  logic [PredictWidth-1:0]       in_isLastInFtqEntry,
  input  logic [PredictWidth-1:0][VAddrBits-1:0] in_pc,
  input  logic                          in_ftqPtr_flag,
  input  logic [FtqPtrBits-1:0]         in_ftqPtr_value,

  // ---- 出队侧（送往 Decode，Vec<DecodeWidth, DecoupledIO<CtrlFlow>>）----
  // 注：out 无独立 ready；Decode 用 decodeCanAccept 统一表示是否接收。
  output logic [DecodeWidth-1:0]                 out_valid,
  output logic [DecodeWidth-1:0][31:0]           out_instr,
  output logic [DecodeWidth-1:0][VAddrBits-1:0]  out_pc,
  output logic [DecodeWidth-1:0][FoldPCBits-1:0] out_foldpc,
  output logic [DecodeWidth-1:0]                 out_exceptionVec_instrPageFault,      // EX_1
  output logic [DecodeWidth-1:0]                 out_exceptionVec_instrAccessFault,    // EX_2
  output logic [DecodeWidth-1:0]                 out_exceptionVec_instrGuestPageFault, // EX_12
  output logic [DecodeWidth-1:0]                 out_exceptionVec_EX_II,               // EX_20
  output logic [DecodeWidth-1:0]                 out_backendException,
  output logic [DecodeWidth-1:0][3:0]            out_trigger,
  output logic [DecodeWidth-1:0]                 out_pd_isRVC,
  output logic [DecodeWidth-1:0][1:0]            out_pd_brType,
  output logic [DecodeWidth-1:0]                 out_pred_taken,
  output logic [DecodeWidth-1:0]                 out_crossPageIPFFix,
  output logic [DecodeWidth-1:0]                 out_ftqPtr_flag,
  output logic [DecodeWidth-1:0][FtqPtrBits-1:0] out_ftqPtr_value,
  output logic [DecodeWidth-1:0][3:0]            out_ftqOffset,
  output logic [DecodeWidth-1:0]                 out_isLastInFtqEntry,

  input  logic                          decodeCanAccept, // Decode 是否接收本拍输出
  output logic                          full,            // 队列将满（!allowEnq）

  // ---- 性能/阻塞归因 ----
  output logic [DecodeWidth-1:0][5:0]   stallReason_reason,
  input  logic                          stallReason_backReason_valid,
  input  logic [5:0]                    stallReason_backReason_bits,
  input  logic [37:0]                   topdown_info_reasons, // FrontendTopDownBundle
  output logic [8:0][5:0]               perf_value
);

  // ---------------------------------------------------------------------------
  // 派生参数
  // ---------------------------------------------------------------------------
  localparam int BankSize     = IBufSize / IBufNBank;          // 每 bank 项数 = 8
  localparam int PtrW         = $clog2(IBufSize);              // value 位宽 = 6
  localparam int BankPtrW     = $clog2(IBufNBank);             // bank value 位宽 = 3
  localparam int InBankPtrW   = $clog2(BankSize);              // bank 内 value 位宽 = 3
  localparam int CntW         = $clog2(DecodeWidth);           // 出队计数位宽 = 3
  localparam int EnqW         = $clog2(PredictWidth + 1);      // 入队计数位宽 = 5（0..16）
  localparam int ExcW         = 3;                             // IBufferExceptionType 宽
  // TopDown 计数器枚举里的几个 id（与 Chisel TopDownCounters 对齐）
  localparam int NUM_STALL_REASONS = 38;
  // 位号取自 golden 的 flush 置位表：reasons_12=BTBMiss，reasons_3..8=TAGE/SC/ITTAGE/
  // RAS/MemVio/Other（TopDownCounters 枚举序，BTBMissBubble 在枚举后段）
  localparam int ID_BTBMiss        = 12;
  localparam int ID_TAGEMiss       = 3;
  localparam int ID_SCMiss         = 4;
  localparam int ID_ITTAGEMiss     = 5;
  localparam int ID_RASMiss        = 6;
  localparam int ID_MemVioRedirect = 7;
  localparam int ID_OtherRedirect  = 8;
  localparam int ID_FetchFragBubble= 13;  // 对齐 golden 浪费槽原因值 6'hD

  genvar gi;

  // ---------------------------------------------------------------------------
  // 队列项类型：IBufEntry（与 Chisel 同字段，exceptionType 已是合并编码）
  // ---------------------------------------------------------------------------
  typedef struct packed {
    logic [31:0]            inst;
    logic [VAddrBits-1:0]   pc;
    logic [FoldPCBits-1:0]  foldpc;
    logic                   pd_isRVC;
    logic [1:0]             pd_brType;
    logic                   pred_taken;
    logic                   ftqPtr_flag;
    logic [FtqPtrBits-1:0]  ftqPtr_value;
    logic [3:0]             ftqOffset;
    logic [ExcW-1:0]        exceptionType;
    logic                   backendException;
    logic [3:0]             triggered;
    logic                   isLastInFtqEntry;
  } ibuf_entry_t;

  // ===========================================================================
  // fromFetch：把 IFU 第 i 槽组装成一个队列项
  // exceptionType 编码（cvtFromFetchExcpAndCrossPageAndRVCII）：
  //   crossPage     → {1, fetchExcp}（跨页：高位置 1）
  //   fetchExcp!=0  → {0, fetchExcp}
  //   illegalInstr  → 100（rvcII，非法指令）
  //   否则           → 000
  // ===========================================================================
  // 纯函数：异常类型编码（只用入参，不读非局部信号，FM 友好）
  function automatic logic [ExcW-1:0] cvt_exc(
      input logic [1:0] fetchExcp, input logic crossPage, input logic rvcIll);
    if (crossPage)        cvt_exc = {1'b1, fetchExcp};
    else if (|fetchExcp)  cvt_exc = {1'b0, fetchExcp};
    else                  cvt_exc = {rvcIll, 2'b00};
  endfunction

  // enqData[i]：第 i 槽的待入队项（组合）。直接在 generate 里按字段装配，
  // 不用读端口的 function（避免 FMR_VLOG-091）。
  // ftqOffset.bits 直接取槽下标 i（CtrlFlow.ftqOffset），与 pred_taken 无关。
  ibuf_entry_t [PredictWidth-1:0] enqData;
  generate
    for (gi = 0; gi < PredictWidth; gi++) begin : g_enqdata
      always_comb begin
        enqData[gi].inst             = in_instrs[gi];
        enqData[gi].pc               = in_pc[gi];
        enqData[gi].foldpc           = in_foldpc[gi];
        enqData[gi].pd_isRVC         = in_pd_isRVC[gi];
        enqData[gi].pd_brType        = in_pd_brType[gi];
        enqData[gi].pred_taken       = in_ftqOffset_valid[gi];
        enqData[gi].ftqPtr_flag      = in_ftqPtr_flag;
        enqData[gi].ftqPtr_value     = in_ftqPtr_value;
        enqData[gi].ftqOffset        = 4'(gi);
        enqData[gi].exceptionType    = cvt_exc(in_exceptionType[gi],
                                               in_crossPageIPFFix[gi], in_illegalInstr[gi]);
        // 仅槽 0 暴露 backendException 端口（其余槽恒 0，与 golden DCE 一致）
        enqData[gi].backendException = (gi == 0) ? in_backendException0 : 1'b0;
        enqData[gi].triggered        = in_triggered[gi];
        enqData[gi].isLastInFtqEntry = in_isLastInFtqEntry[gi];
      end
    end
  endgenerate

  // ===========================================================================
  // 存储与指针
  // ===========================================================================
  ibuf_entry_t [IBufSize-1:0] ibuf;   // 裸寄存器队列

  // bank 交织视图：bankedIBufView[b][o] = ibuf[b + o*IBufNBank]
  // 仅用于读出选择，不额外占存储。

  ibuf_entry_t [DecodeWidth-1:0] bypassEntries; // bypass 直通项（组合）
  logic [DecodeWidth-1:0] bypassValid;
  ibuf_entry_t [DecodeWidth-1:0] deqEntries; // 正常读出项（组合）
  logic [DecodeWidth-1:0] deqValid;

  ibuf_entry_t [DecodeWidth-1:0] outputEntries; // 输出寄存器
  logic [DecodeWidth-1:0] outputEntriesValid;

  // 三组出队指针
  logic [PtrW-1:0]       deqPtr_value;
  logic                  deqPtr_flag;
  logic [BankPtrW-1:0]   deqBankPtrVec_value [DecodeWidth];
  logic [InBankPtrW-1:0] deqInBankPtr_value  [IBufNBank];
  logic                  deqInBankPtr_flag   [IBufNBank];

  // 入队指针向量：enqPtrVec[k] = enqPtr + k（共 PredictWidth 个，便于一拍写多条）
  logic [PtrW-1:0]       enqPtrVec_value [PredictWidth];
  logic                  enqPtrVec_flag  [PredictWidth];

  logic                  allowEnq;

  // ===========================================================================
  // 数量统计（组合）
  // ===========================================================================
  // 当前队列有效项数 = distanceBetween(enqPtr, deqPtr)。
  // CircularQueuePtr 用 PtrW 位 value + 1 位 flag；value 在到达 IBufSize 时回绕、flag 翻转。
  // 同 flag：enq-deq；异 flag：enq + IBufSize - deq。注意 value 是 PtrW 位模 2^PtrW 运算，
  // 故 +IBufSize 等价于 -(2^PtrW - IBufSize)（golden 即写成 enq - 16 - deq）。
  // 取 6 位与 golden numValid_probe 完全一致（含 don't-care 高位编码），利于 FM 签名分析。
  logic [PtrW-1:0] numValid;
  always_comb begin
    if (enqPtrVec_flag[0] == deqPtr_flag)
      numValid = enqPtrVec_value[0] - deqPtr_value;
    else
      numValid = (enqPtrVec_value[0] - PtrW'(1 << PtrW) + IBufSize) - deqPtr_value;
  end

  // 本拍 IFU 想入队的条数 = PopCount(enqEnable)（in_valid 时）
  logic [CntW+2:0] numFromFetch;
  always_comb begin
    numFromFetch = '0;
    if (in_valid)
      for (int i = 0; i < PredictWidth; i++)
        numFromFetch += {{(CntW+2){1'b0}}, in_enqEnable[i]};
  end

  // 空缓冲且 Decode 可收 → 走 bypass 直通
  logic useBypass;
  assign useBypass = ({deqPtr_flag, deqPtr_value} == {enqPtrVec_flag[0], enqPtrVec_value[0]})
                     && decodeCanAccept;

  // 输出寄存器中已有的有效项数（高位优先编码：找最高有效槽 +1）。
  // 注意：对齐 Chisel 的 PriorityMuxDefault(zip(range(1,DecodeWidth)))——只把 valid[i]
  //   (i=0..DecodeWidth-2) 映射到 i+1，最高槽 valid[DecodeWidth-1] 不参与，故结果上限
  //   是 DecodeWidth-1（全满时也返回 DecodeWidth-1，而非 DecodeWidth）。
  logic [CntW-1:0] outputEntriesValidNum;
  always_comb begin
    outputEntriesValidNum = '0;
    for (int i = 0; i < DecodeWidth - 1; i++)
      if (outputEntriesValid[i]) outputEntriesValidNum = CntW'(i + 1);
  end
  logic outputEntriesIsNotFull;
  assign outputEntriesIsNotFull = !outputEntriesValid[DecodeWidth-1];

  // 本拍计划出队条数 numOut / numDeq
  // - Decode 接收：尽量出 DecodeWidth 条（受 numValid 限制）
  // - Decode 不收但输出寄存器没满：补齐到 DecodeWidth（受 numValid 限制）
  // - 否则不出
  logic [CntW-1:0] numOut, numDeq;
  always_comb begin
    if (decodeCanAccept)
      numOut = (numValid >= DecodeWidth) ? CntW'(DecodeWidth) : numValid[CntW-1:0];
    else if (outputEntriesIsNotFull) begin
      logic [CntW:0] room;
      room = (CntW+1)'(DecodeWidth) - {1'b0, outputEntriesValidNum};
      numOut = (numValid >= room) ? room[CntW-1:0] : numValid[CntW-1:0];
    end else
      numOut = '0;
  end
  assign numDeq = numOut;

  // 本拍真正入队条数：bypass 时前 DecodeWidth 条走旁路不入队
  // 注意：numTryEnq 最大可达 PredictWidth(16)，需 EnqW=5 位，不能用 CntW(3) 截断。
  logic [EnqW-1:0]  numTryEnq;
  logic [CntW-1:0]  numBypass;
  always_comb begin
    if (useBypass) begin
      if (numFromFetch >= DecodeWidth) begin
        numTryEnq = EnqW'(numFromFetch - DecodeWidth);
        numBypass = CntW'(DecodeWidth);
      end else begin
        numTryEnq = '0;
        numBypass = numFromFetch[CntW-1:0];
      end
    end else begin
      numTryEnq = numFromFetch[EnqW-1:0];
      numBypass = '0;
    end
  end
  // io.in.fire = in_valid && in_ready
  logic in_fire;
  assign in_fire  = in_valid && allowEnq;
  assign in_ready = allowEnq;

  // numValidNext 用于 allowEnq（almost-full 判据）。
  // 取 PtrW(6) 位模运算，与 golden 6'(numValid + numEnq - numOut) 逐位一致。
  logic [EnqW-1:0]  numEnq;       // 实际入队（fire 时 = numTryEnq）
  assign numEnq = in_fire ? numTryEnq : '0;
  logic [PtrW-1:0] numValidNext;
  assign numValidNext = numValid
                      + {{(PtrW-EnqW){1'b0}}, numEnq}
                      - {{(PtrW-CntW){1'b0}}, numDeq};

  // enqOffset[i] = PopCount(valid[0..i-1])：第 i 槽相对本批入队基址的偏移
  logic [CntW:0] enqOffset [PredictWidth];
  always_comb begin
    for (int i = 0; i < PredictWidth; i++) begin
      logic [CntW:0] acc;
      acc = '0;
      for (int j = 0; j < i; j++) acc += {{CntW{1'b0}}, in_valid_mask[j]};
      enqOffset[i] = acc;
    end
  end

  // ===========================================================================
  // Bypass 选择：第 idx 个旁路项 = 唯一满足 (valid & enqEnable & enqOffset==idx)
  //              的那条 fetch 指令（OneHot 选择）
  // ===========================================================================
  generate
    for (gi = 0; gi < DecodeWidth; gi++) begin : g_bypass
      always_comb begin
        ibuf_entry_t sel;
        logic        any;
        sel = '0;
        any = 1'b0;
        for (int i = 0; i < PredictWidth; i++) begin
          if (in_valid_mask[i] && in_enqEnable[i] && (enqOffset[i] == (CntW+1)'(gi))) begin
            sel = enqData[i];
            any = 1'b1;
          end
        end
        bypassEntries[gi] = sel;
        bypassValid[gi]   = any && in_fire && !flush;
      end
    end
  endgenerate

  // ===========================================================================
  // 入队（Enqueue）
  // 每个 ibuf[idx] 前挂一个 PredictWidth→1 Mux：哪条 fetch 指令写到本项。
  //   normalMatch : enqPtrVec[enqOffset(i)].value == idx
  //   useBypassMatch : enqOffset(i) >= DecodeWidth 且
  //                    enqPtrVec[enqOffset(i)-DecodeWidth].value == idx
  // bypass 模式下前 DecodeWidth 条走旁路，故入队基址相应后移 DecodeWidth。
  // ===========================================================================
  generate
    for (gi = 0; gi < IBufSize; gi++) begin : g_enq
      // 写选择组合前置（FM 异步复位块体只允许 if(reset)…else…）
      ibuf_entry_t wdata;
      logic        wen;
      always_comb begin
        wdata = '0;
        wen   = 1'b0;
        for (int i = 0; i < PredictWidth; i++) begin
          logic match;
          logic [CntW:0] off;       // enqOffset[i]，0..PredictWidth-1
          logic [CntW:0] bypIdx;    // bypass 入队基址：off-DecodeWidth（保持 4 位，落在 0..15）
          off    = enqOffset[i];
          bypIdx = off - (CntW+1)'(DecodeWidth);  // 仅在 off>=DecodeWidth 时有效
          if (useBypass)
            match = (off >= (CntW+1)'(DecodeWidth)) &&
                    (enqPtrVec_value[bypIdx] == PtrW'(gi));
          else
            match = (enqPtrVec_value[off] == PtrW'(gi));
          // golden 是 Mux1H(并行 OR)非优先链：多热时各 lane 数据按位 OR(bug-for-bug 对齐)
          if (in_valid_mask[i] && in_enqEnable[i] && match) begin
            wdata |= enqData[i];
            wen    = 1'b1;
          end
        end
      end
      // golden ibuf_N_* 全部在异步复位块内 RegInit(0)——对齐
      always_ff @(posedge clock or posedge reset) begin
        if (reset)
          ibuf[gi] <= '0;
        else if (wen && in_fire && !flush)
          ibuf[gi] <= wdata;
      end
    end
  endgenerate

  // ===========================================================================
  // 出队（Dequeue）—— 两级读：bank 内 BankSize→1，再 bank 间 IBufNBank→1
  // ===========================================================================
  // 下一拍输出寄存器里将有的有效项数（决定 deqEntries 的 valid 掩码 validVec）
  logic [CntW-1:0] outputEntriesValidNumNext;
  always_comb begin
    if (decodeCanAccept)
      outputEntriesValidNumNext = useBypass ? numBypass : numDeq;
    else if (outputEntriesIsNotFull)
      outputEntriesValidNumNext = (outputEntriesValidNum + numDeq);
    else
      outputEntriesValidNumNext = outputEntriesValidNum;
  end
  // validVec = UIntToMask：低 outputEntriesValidNumNext 位为 1
  logic [DecodeWidth-1:0] validVec;
  always_comb begin
    for (int i = 0; i < DecodeWidth; i++)
      validVec[i] = (i < outputEntriesValidNumNext);
  end

  // 第一级：每个 bank 用其 deqInBankPtr 选出本 bank 当前队头项。
  // readStage1 槽数补到 2 的幂(=2^BankPtrW)，避免 3-bit bank 指针索引 6 项数组时
  // 触发 FMR_ELAB-147（非 2 幂数组宽索引越界）。多出的槽(6,7)不会被有效指针选到。
  localparam int NBankPow2 = 1 << BankPtrW;       // = 8
  ibuf_entry_t [NBankPow2-1:0] readStage1;
  generate
    for (gi = 0; gi < NBankPow2; gi++) begin : g_readstage1
      if (gi < IBufNBank) begin : g_real
        always_comb readStage1[gi] = ibuf[gi + deqInBankPtr_value[gi] * IBufNBank];
      end else begin : g_pad
        always_comb readStage1[gi] = '0;          // 占位，永不被选中
      end
    end
  endgenerate

  // 第二级：第 i 个译码槽用 deqBankPtrVec[i] 从 bank 头里选 1
  generate
    for (gi = 0; gi < DecodeWidth; gi++) begin : g_deq
      always_comb begin
        deqValid[gi]   = validVec[gi];
        deqEntries[gi] = readStage1[deqBankPtrVec_value[gi]];
      end
    end
  endgenerate

  // ===========================================================================
  // 输出寄存器更新
  // - Decode 接收：bypass 时填旁路项，否则填正常读出项。
  // - Decode 不收但没满：在已有有效项之后拼接新读出项（保留前 valid 个不动）。
  // ===========================================================================
  // 先在组合逻辑里算好整组下一态，再统一寄存（FM 异步复位块体只允许 if(reset)…else…）。
  ibuf_entry_t            nextEntries [DecodeWidth];
  logic [DecodeWidth-1:0] nextValid;
  always_comb begin
    for (int i = 0; i < DecodeWidth; i++) begin
      nextEntries[i] = outputEntries[i];   // 默认保留旧 bits
      nextValid[i]   = outputEntriesValid[i];
      if (decodeCanAccept) begin
        if (useBypass && in_valid) begin
          nextValid[i]   = bypassValid[i];
          nextEntries[i] = bypassEntries[i];
        end else begin
          nextValid[i]   = deqValid[i];
          nextEntries[i] = deqEntries[i];
        end
      end else if (outputEntriesIsNotFull) begin
        // valid 永远更新；bits 在 i<validNum 时保留，否则拼接新读出项
        nextValid[i] = deqValid[i];
        if (i >= outputEntriesValidNum)
          nextEntries[i] = deqEntries[i - outputEntriesValidNum];
      end
      if (flush) nextValid[i] = 1'b0;       // flush 只清 valid，bits 保留（同 golden）
    end
  end
  // golden 复位寄存器统一异步复位块——对齐
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (int i = 0; i < DecodeWidth; i++) begin
        outputEntriesValid[i] <= 1'b0;
        outputEntries[i]      <= '0;
      end
    end else begin
      for (int i = 0; i < DecodeWidth; i++) begin
        outputEntriesValid[i] <= nextValid[i];
        outputEntries[i]      <= nextEntries[i];
      end
    end
  end

  // ===========================================================================
  // 指针维护（always_ff）
  // ===========================================================================
  // 入队指针：fire 且非 flush 时整体 + numTryEnq；flush 时复位成 0,1,2,...
  generate
    for (gi = 0; gi < PredictWidth; gi++) begin : g_enqptr
      // 循环加 numTryEnq：value 越过 IBufSize 则翻转 flag（组合前置）
      logic [PtrW+1:0] nv;
      always_comb nv = {2'b0, enqPtrVec_value[gi]} + {{(PtrW+2-EnqW){1'b0}}, numTryEnq};
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          {enqPtrVec_flag[gi], enqPtrVec_value[gi]} <= (PtrW+1)'(gi);
        end else if (flush) begin
          {enqPtrVec_flag[gi], enqPtrVec_value[gi]} <= (PtrW+1)'(gi);
        end else if (in_fire) begin
          if (nv >= IBufSize) begin
            enqPtrVec_value[gi] <= PtrW'(nv - IBufSize);
            enqPtrVec_flag[gi]  <= ~enqPtrVec_flag[gi];
          end else begin
            enqPtrVec_value[gi] <= PtrW'(nv);
          end
        end
      end
    end
  endgenerate

  // bank 指针向量：每拍整体 + numDeq（mod IBufNBank）；flush 复位成 0,1,2,...
  // 回绕用 golden 的 signed-diff 形式 (newv - NBank >= 0 ? newv-NBank : newv)，
  // 与 golden 逐位一致（含 value 取 6/7 等 don't-care 输入时的行为），利于 FM 签名分析。
  generate
    for (gi = 0; gi < DecodeWidth; gi++) begin : g_bankptr
      logic [BankPtrW:0]   bnewv;   // value + numDeq（4 位）
      logic signed [BankPtrW+1:0] bdiff;
      always_comb begin
        bnewv = {1'b0, deqBankPtrVec_value[gi]} + {{(BankPtrW+1-CntW){1'b0}}, numDeq};
        bdiff = $signed({1'b0, bnewv}) - $signed((BankPtrW+2)'(IBufNBank));
      end
      always_ff @(posedge clock or posedge reset) begin
        if (reset)
          deqBankPtrVec_value[gi] <= BankPtrW'(gi % IBufNBank);
        else if (flush)
          deqBankPtrVec_value[gi] <= BankPtrW'(gi % IBufNBank);
        else
          deqBankPtrVec_value[gi] <= (bdiff > -1) ? bdiff[BankPtrW-1:0] : bnewv[BankPtrW-1:0];
      end
    end
  endgenerate

  // 全局出队指针：每拍 + numDeq（循环）；flush 复位 0。同样用 signed-diff 回绕。
  logic [PtrW:0]          dnewv;   // value + numDeq（7 位）
  logic signed [PtrW+1:0] ddiff;
  logic                   dwrap;
  always_comb begin
    dnewv = {1'b0, deqPtr_value} + {{(PtrW+1-CntW){1'b0}}, numDeq};
    ddiff = $signed({1'b0, dnewv}) - $signed((PtrW+2)'(IBufSize));
    dwrap = (ddiff > -1);
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      deqPtr_value <= '0;
      deqPtr_flag  <= 1'b0;
    end else if (flush) begin
      deqPtr_value <= '0;
      deqPtr_flag  <= 1'b0;
    end else begin
      deqPtr_value <= dwrap ? ddiff[PtrW-1:0] : dnewv[PtrW-1:0];
      deqPtr_flag  <= dwrap ^ deqPtr_flag;
    end
  end

  // bank 内偏移指针：某 bank 这拍被读到（numOut > 该 bank 相对队头的位序）才 +1。
  // validIdx[b] = (b - deqBankPtr0) mod IBufNBank，即 bank b 是本拍第几个被读的。
  logic [BankPtrW-1:0] deqBankPtr0_value;
  assign deqBankPtr0_value = deqBankPtrVec_value[0];
  generate
    for (gi = 0; gi < IBufNBank; gi++) begin : g_inbankptr
      logic [BankPtrW-1:0] validIdx;
      logic                advance;
      always_comb begin
        if (gi >= deqBankPtr0_value)
          validIdx = BankPtrW'(gi - deqBankPtr0_value);
        else
          validIdx = BankPtrW'((gi + IBufNBank) - deqBankPtr0_value);
        advance = (numOut > validIdx);
      end
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          deqInBankPtr_value[gi] <= '0;
          deqInBankPtr_flag[gi]  <= 1'b0;
        end else if (flush) begin
          deqInBankPtr_value[gi] <= '0;
          deqInBankPtr_flag[gi]  <= 1'b0;
        end else if (advance) begin
          if (deqInBankPtr_value[gi] + 1 >= BankSize) begin
            deqInBankPtr_value[gi] <= '0;
            deqInBankPtr_flag[gi]  <= ~deqInBankPtr_flag[gi];
          end else
            deqInBankPtr_value[gi] <= InBankPtrW'(deqInBankPtr_value[gi] + 1);
        end
      end
    end
  endgenerate

  // allowEnq：almost-full 判据（留 PredictWidth 余量防溢出）。
  // (IBufSize-PredictWidth) >= numValidNext ⟺ numValidNext < IBufSize-PredictWidth+1。
  // flush 时直接置 1（与 golden `io_flush | (...)` 同义）。
  localparam logic [PtrW-1:0] ALMOST_FULL_THR = PtrW'(IBufSize - PredictWidth + 1); // = 33
  always_ff @(posedge clock or posedge reset) begin
    if (reset)      allowEnq <= 1'b1;
    else            allowEnq <= flush | (numValidNext < ALMOST_FULL_THR);
  end
  assign full = !allowEnq;

  // ===========================================================================
  // 输出端口映射（outputEntries → CtrlFlow）
  // exceptionVec 由 3-bit exceptionType 解码：
  //   instrPageFault(EX_1)      : type[1:0]==01
  //   instrAccessFault(EX_2)    : type[1:0]==11
  //   instrGuestPageFault(EX_12): type[1:0]==10
  //   EX_II(EX_20)              : type==100（isRVCII）
  //   crossPageIPFFix           : type[2] & type[1:0]!=0
  // ===========================================================================
  generate
    for (gi = 0; gi < DecodeWidth; gi++) begin : g_outmap
      assign out_valid[gi]            = outputEntriesValid[gi];
      assign out_instr[gi]            = outputEntries[gi].inst;
      assign out_pc[gi]               = outputEntries[gi].pc;
      assign out_foldpc[gi]           = outputEntries[gi].foldpc;
      assign out_exceptionVec_instrPageFault[gi]      = (outputEntries[gi].exceptionType[1:0] == 2'b01);
      assign out_exceptionVec_instrAccessFault[gi]    = (&outputEntries[gi].exceptionType[1:0]);
      assign out_exceptionVec_instrGuestPageFault[gi] = (outputEntries[gi].exceptionType[1:0] == 2'b10);
      assign out_exceptionVec_EX_II[gi]   = outputEntries[gi].exceptionType[2]
                                          & (outputEntries[gi].exceptionType[1:0] == 2'b00);
      assign out_backendException[gi]     = outputEntries[gi].backendException;
      assign out_trigger[gi]              = outputEntries[gi].triggered;
      assign out_pd_isRVC[gi]             = outputEntries[gi].pd_isRVC;
      assign out_pd_brType[gi]            = outputEntries[gi].pd_brType;
      assign out_pred_taken[gi]           = outputEntries[gi].pred_taken;
      assign out_crossPageIPFFix[gi]      = outputEntries[gi].exceptionType[2]
                                          & (|outputEntries[gi].exceptionType[1:0]);
      assign out_ftqPtr_flag[gi]          = outputEntries[gi].ftqPtr_flag;
      assign out_ftqPtr_value[gi]         = outputEntries[gi].ftqPtr_value;
      assign out_ftqOffset[gi]            = outputEntries[gi].ftqOffset;
      assign out_isLastInFtqEntry[gi]     = outputEntries[gi].isLastInFtqEntry;
    end
  endgenerate

  // ===========================================================================
  // TopDown：把本拍 fetch 的 topdown 信息打一拍；flush 时按重定向类型置归因位
  // ===========================================================================
  logic [37:0] topdown_stage;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)
      topdown_stage <= '0;
    else begin
      topdown_stage <= topdown_info_reasons;
      if (flush) begin
        if (ControlRedirect) begin
          if (ControlBTBMissBubble)      topdown_stage[ID_BTBMiss]    <= 1'b1;
          else if (TAGEMissBubble)       topdown_stage[ID_TAGEMiss]   <= 1'b1;
          else if (SCMissBubble)         topdown_stage[ID_SCMiss]     <= 1'b1;
          else if (ITTAGEMissBubble)     topdown_stage[ID_ITTAGEMiss] <= 1'b1;
          else if (RASMissBubble)        topdown_stage[ID_RASMiss]    <= 1'b1;
        end else if (MemVioRedirect)     topdown_stage[ID_MemVioRedirect] <= 1'b1;
        else                             topdown_stage[ID_OtherRedirect]  <= 1'b1;
      end
    end
  end

  // stallReason：把出队浪费槽（deqWasteCount = DecodeWidth - 有效出队数）标记原因
  logic [CntW:0] deqValidCount, deqWasteCount;
  always_comb begin
    deqValidCount = '0;
    for (int i = 0; i < DecodeWidth; i++) deqValidCount += {{CntW{1'b0}}, validVec[i]};
    deqWasteCount = (CntW+1)'(DecodeWidth) - deqValidCount;
  end

  // matchBubble = (NumStallReasons-1) - PriorityEncoder(reasons.reverse)
  //             = 最高被置位的 topdown 原因下标（无原因时此值无意义，见下方门控）。
  logic [5:0] matchBubble;
  always_comb begin
    matchBubble = '0;
    for (int i = 0; i < NUM_STALL_REASONS; i++)
      if (topdown_stage[i]) matchBubble = 6'(i);
  end

  logic topdown_any;
  assign topdown_any = |topdown_stage;

  // 每个浪费槽要写入的原因值（对齐 golden 浪费槽原因值逻辑）：
  //   全浪费(deqWaste==DecodeWidth) 或 有 topdown 原因 → matchBubble
  //   否则 → FetchFragBubble.id (=13)，表示取指碎片化阻塞
  logic [5:0] wasteReason;
  assign wasteReason = ((deqWasteCount == (CntW+1)'(DecodeWidth)) || topdown_any)
                       ? matchBubble : 6'(ID_FetchFragBubble);

  always_comb begin
    for (int i = 0; i < DecodeWidth; i++) stallReason_reason[i] = '0;
    // 末尾 deqWasteCount 个槽（从最高下标往回数）填 wasteReason
    for (int i = 0; i < DecodeWidth; i++)
      if (i < deqWasteCount)
        stallReason_reason[DecodeWidth-1-i] = wasteReason;
    // 后端给出的阻塞原因覆盖一切
    if (stallReason_backReason_valid)
      for (int i = 0; i < DecodeWidth; i++)
        stallReason_reason[i] = stallReason_backReason_bits;
  end

  // ===========================================================================
  // 性能事件计数（HasPerfEvents：9 个事件，本核仅输出本拍 value）
  // ===========================================================================
  logic afterInit, headBubble, instrHungry;
  always_ff @(posedge clock or posedge reset) begin
    if (reset)            afterInit <= 1'b0;
    else if (in_fire)     afterInit <= 1'b1;
  end
  always_ff @(posedge clock or posedge reset) begin
    if (reset)              headBubble <= 1'b0;
    else if (flush)         headBubble <= 1'b1;
    else if (numValid != 0) headBubble <= 1'b0;
  end
  assign instrHungry = afterInit && (numValid == 0) && !headBubble;

  logic [2:0] frontBubble;   // DecodeWidth-numOut，最大 6 → 3 位（对齐 golden）
  assign frontBubble = (decodeCanAccept && !headBubble) ? 3'(DecodeWidth - numOut) : 3'd0;
  logic fetchLatency;
  assign fetchLatency = decodeCanAccept && !headBubble && (numOut == 0);

  // 本拍的 9 个事件原始值
  localparam int Q = IBufSize / 4;
  logic [8:0] perf_raw;
  logic [2:0] perf7_raw;
  // numValid 比较只取低 PtrW 位（与 golden 6-bit distanceBetween 对齐）
  logic [PtrW-1:0] nv6;
  assign nv6 = numValid[PtrW-1:0];
  always_comb begin
    perf_raw[0] = flush;
    perf_raw[1] = instrHungry;
    perf_raw[2] = (nv6 > 0)        && (nv6 < 1*Q);
    perf_raw[3] = (nv6 >= 1*Q)     && (nv6 < 2*Q);
    perf_raw[4] = (nv6 >= 2*Q)     && (nv6 < 3*Q);
    perf_raw[5] = (nv6 >= 3*Q)     && (nv6 < 4*Q);
    perf_raw[6] = &nv6;
    perf_raw[7] = 1'b0;        // perf_7 用 perf7_raw（多位），此位不用
    perf_raw[8] = fetchLatency;
    perf7_raw   = frontBubble;
  end

  // HasPerfEvents 把事件值寄存两拍后输出（与 golden _REG/_REG_1 一致）。
  logic [8:0] perf_s1, perf_s2;
  logic [2:0] perf7_s1, perf7_s2;
  always_ff @(posedge clock) begin
    perf_s1  <= perf_raw;   perf_s2  <= perf_s1;
    perf7_s1 <= perf7_raw;  perf7_s2 <= perf7_s1;
  end
  always_comb begin
    for (int i = 0; i < 9; i++) perf_value[i] = {5'd0, perf_s2[i]};
    perf_value[7] = {3'd0, perf7_s2};
  end

endmodule
