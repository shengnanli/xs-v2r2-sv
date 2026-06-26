// =============================================================================
//  xs_mbist_pipe_ctrl —— MBIST 流水节点的公共"输入寄存级 + 门控"
// -----------------------------------------------------------------------------
//  L2Slice / L2Directory / L2DataStorage 共用的输入打拍逻辑 (见 mbist_pipe_pkg
//  的总说明)。把上游 MBIST 总线请求按 activated / dataValid 门控寄存一拍，
//  对外给出寄存后的控制/数据信号供各变体做 per-child 铺开。
//
//  纯寄存器叶子，无子模块、无 SRAM。参数为各字段位宽，arrayHit 由调用方按
//  本节点认领的 array 编号集合在外部算好后传入 (各变体 array 集合不同)。
// =============================================================================
module xs_mbist_pipe_ctrl
  import mbist_pipe_pkg::*;
#(
  parameter int ARRAY_W = 5,   // mbist_array 位宽
  parameter int BE_W    = 8,   // 字节选通位宽
  parameter int ADDR_W  = 13,  // 地址位宽
  parameter int DATA_W  = 104, // 数据位宽
  parameter bit HAS_HOLD = 0   // 是否生成读/写使能展宽寄存器 (extraHold SRAM)
)(
  input  logic               clock,
  input  logic               reset,

  // 上游 MBIST 请求 (组合输入)
  input  logic               mbist_all,
  input  logic               mbist_req,
  input  logic               mbist_writeen,
  input  logic               mbist_readen,
  input  logic [ARRAY_W-1:0] mbist_array,
  input  logic [BE_W-1:0]    mbist_be,
  input  logic [ADDR_W-1:0]  mbist_addr,
  input  logic [DATA_W-1:0]  mbist_indata,
  input  logic [ADDR_W-1:0]  mbist_addr_rd,

  // 本节点是否认领该 array 编号 (由调用方按 array 集合算出)
  input  logic               array_hit,

  // 寄存后的控制/数据 (供 per-child 铺开)
  output logic [ARRAY_W-1:0] arrayReg,
  output logic               reqReg,
  output logic               allReg,
  output logic               wenReg,
  output logic               renReg,
  output logic [BE_W-1:0]    beReg,
  output logic [ADDR_W-1:0]  addrReg,
  output logic [DATA_W-1:0]  dataInReg,
  output logic [ADDR_W-1:0]  addrRdReg,

  // extraHold 展宽使能 (HAS_HOLD=0 时恒 0)
  output logic [MBIST_HOLD_W-1:0] wenStretched,
  output logic [MBIST_HOLD_W-1:0] renStretched
);

  // 是否吃下本请求：广播位，或 (请求有效 & 命中本节点 array 集合)
  wire activated = mbist_all | (mbist_req & array_hit);
  // 是否锁存地址/数据 (只有读或写才需要)
  wire dataValid = activated & (mbist_readen | mbist_writeen);

  // ---- 带异步复位的寄存器组 (golden: posedge clock or posedge reset) ----
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      arrayReg  <= '0;
      reqReg    <= 1'b0;
      allReg    <= 1'b0;
      wenReg    <= 1'b0;
      renReg    <= 1'b0;
      beReg     <= '0;
      addrReg   <= '0;
      dataInReg <= '0;
      addrRdReg <= '0;
    end else begin
      // activated 才更新目标 array / 广播 / 读写使能
      if (activated) begin
        arrayReg <= mbist_array;
        allReg   <= mbist_all;
        wenReg   <= mbist_writeen;
        renReg   <= mbist_readen;
      end
      // req 每拍都寄存 (RegNext)
      reqReg <= mbist_req;
      // dataValid 才锁存数据/地址/字节选通
      if (dataValid) begin
        beReg     <= mbist_be;
        addrReg   <= mbist_addr;
        dataInReg <= mbist_indata;
        addrRdReg <= mbist_addr_rd;
      end
    end
  end

  // ---- extraHold：读/写使能展宽寄存器 (维持 MBIST_HOLD_W 拍) ----
  generate
    if (HAS_HOLD) begin : g_hold
      always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
          wenStretched <= '0;
          renStretched <= '0;
        end else begin
          // activated&writeen 时置全 1，否则每拍右移补 0
          if (activated & mbist_writeen)
            wenStretched <= {MBIST_HOLD_W{1'b1}};
          else if (|wenStretched)
            wenStretched <= {1'b0, wenStretched[MBIST_HOLD_W-1:1]};

          if (activated & mbist_readen)
            renStretched <= {MBIST_HOLD_W{1'b1}};
          else if (|renStretched)
            renStretched <= {1'b0, renStretched[MBIST_HOLD_W-1:1]};
        end
      end
    end else begin : g_nohold
      assign wenStretched = '0;
      assign renStretched = '0;
    end
  endgenerate

endmodule
