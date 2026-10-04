// perfEventsModule.sv —— 一个 mhpmevent CSR 的影子副本（PFEvent 里 29 个之一）
//
// 位置：NewCSR 旁边的 PFEvent（backend/fu/NewCSR/PFEvent.scala）。每个 hpm 计数器（mhpmcounter3..31）
//   有一个事件选择 CSR mhpmevent<n>；PFEvent 用 29 个本模块在 CSR 外面**再存一份**，监听 CSR 写总线
//   （distribute_csr.w：addr 命中 mhpmevent3+n 时 w_wen=1），把内容直接送给各单元的性能计数选择逻辑，
//   免得从 NewCSR 深处长线引出。Chisel：`Module(new CSRModule("perfEvents", new MhpmeventBundle))`。
//
// 寄存器布局（MhpmeventBundle，backend/fu/NewCSR/MachineLevel.scala:772，全部异步复位到 0）：
//   [63] OF  [62] MINH [61] SINH [60] UINH [59] VSINH [58] VUINH   —— 溢出锁存 / 各特权级禁计数，可读可写
//   [57:55]  保留，读 0
//   [54:50] OPTYPE2  [49:45] OPTYPE1  [44:40] OPTYPE0              —— 事件组合算子，★WARL★
//   [39:30] EVENT3   [29:20] EVENT2   [19:10] EVENT1   [9:0] EVENT0 —— 4 个 10 位事件号，可读可写
//
// ★OPTYPE 是 WARL（写任意、读合法）★：合法值只有 OR=0 / AND=1 / XOR=2 / ADD=4（OPTYPE.legalValues）。
//   写入非法值时该字段**保持原值**（不是清零、也不是改成某个默认值）—— 三个 OPTYPE 各自独立判断，
//   同一次写里合法的字段照样更新。其余字段写什么存什么。
// 本模块无子模块；golden 214 行 / 5 端口。

module xs_perfEvents_core (
  input  logic        clock,
  input  logic        reset,
  input  logic        wen,
  input  logic [63:0] wdata,
  output logic [63:0] rdata
);

  // 组合算子（OPTYPE 枚举）
  typedef enum logic [4:0] {
    OP_OR  = 5'd0,
    OP_AND = 5'd1,
    OP_XOR = 5'd2,
    OP_ADD = 5'd4
  } optype_e;

  // MhpmeventBundle，按位布局从高到低
  typedef struct packed {
    logic       of;        // [63]
    logic       minh;      // [62]
    logic       sinh;      // [61]
    logic       uinh;      // [60]
    logic       vsinh;     // [59]
    logic       vuinh;     // [58]
    logic [2:0] rsvd;      // [57:55] 恒 0
    logic [4:0] optype2;   // [54:50]
    logic [4:0] optype1;   // [49:45]
    logic [4:0] optype0;   // [44:40]
    logic [9:0] event3;    // [39:30]
    logic [9:0] event2;    // [29:20]
    logic [9:0] event1;    // [19:10]
    logic [9:0] event0;    // [9:0]
  } mhpmevent_t;

  function automatic logic optype_legal(input logic [4:0] v);
    return (v == OP_OR) | (v == OP_AND) | (v == OP_XOR) | (v == OP_ADD);
  endfunction

  mhpmevent_t w;
  assign w = wdata;

  // 各字段寄存器（保留位不存）
  logic       of, minh, sinh, uinh, vsinh, vuinh;
  logic [4:0] optype2, optype1, optype0;
  logic [9:0] event3, event2, event1, event0;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      of      <= 1'b0;
      minh    <= 1'b0;
      sinh    <= 1'b0;
      uinh    <= 1'b0;
      vsinh   <= 1'b0;
      vuinh   <= 1'b0;
      optype2 <= OP_OR;
      optype1 <= OP_OR;
      optype0 <= OP_OR;
      event3  <= 10'h0;
      event2  <= 10'h0;
      event1  <= 10'h0;
      event0  <= 10'h0;
    end else if (wen) begin
      // 普通 RW 字段：写什么存什么
      of     <= w.of;
      minh   <= w.minh;
      sinh   <= w.sinh;
      uinh   <= w.uinh;
      vsinh  <= w.vsinh;
      vuinh  <= w.vuinh;
      event3 <= w.event3;
      event2 <= w.event2;
      event1 <= w.event1;
      event0 <= w.event0;
      // WARL 字段：只接受合法值，非法写保持原值
      if (optype_legal(w.optype2)) optype2 <= w.optype2;
      if (optype_legal(w.optype1)) optype1 <= w.optype1;
      if (optype_legal(w.optype0)) optype0 <= w.optype0;
    end
  end

  mhpmevent_t r;
  always_comb begin
    r         = '0;
    r.of      = of;
    r.minh    = minh;
    r.sinh    = sinh;
    r.uinh    = uinh;
    r.vsinh   = vsinh;
    r.vuinh   = vuinh;
    r.optype2 = optype2;
    r.optype1 = optype1;
    r.optype0 = optype0;
    r.event3  = event3;
    r.event2  = event2;
    r.event1  = event1;
    r.event0  = event0;
  end
  assign rdata = r;

endmodule

module perfEventsModule (
  input  logic        clock,
  input  logic        reset,
  input  logic        w_wen,
  input  logic [63:0] w_wdata,
  output logic [63:0] rdata
);

  xs_perfEvents_core u_core (
    .clock (clock),
    .reset (reset),
    .wen   (w_wen),
    .wdata (w_wdata),
    .rdata (rdata)
  );

endmodule
