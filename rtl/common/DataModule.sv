// =============================================================================
// xs_DataModule —— 多读多写寄存器堆（组合读，可选每读口写旁路）
//
// 对应 Chisel: utility.DataModuleTemplate（SyncDataModuleTemplate 的 bank 内核）
// 行为：
//   - 读（组合）：BYPASS_EN[p] 时，若有写口正写同地址则直通该写数据（写旁路），
//     否则读寄存器堆；
//   - 写（同步）：按条目聚合各写口，多写口同拍写同条目时按 Mux1H-or 语义合并
//     （上层设计保证互斥，Chisel 侧有对应断言）；
//   - 无复位：上电内容未定义，由上层保证先写后读。
// =============================================================================
module xs_DataModule #(
  parameter int unsigned NUM_ENTRIES = 16,
  parameter int unsigned NUM_READ    = 1,
  parameter int unsigned NUM_WRITE   = 1,
  parameter int unsigned DATA_WIDTH  = 8,
  parameter logic [NUM_READ-1:0] BYPASS_EN = '1,  // 每读口的写旁路使能
  localparam int unsigned ADDR_W = (NUM_ENTRIES > 1) ? $clog2(NUM_ENTRIES) : 1
)(
  input  logic                                     clock,
  input  logic [NUM_READ-1:0][ADDR_W-1:0]          io_raddr,
  output logic [NUM_READ-1:0][DATA_WIDTH-1:0]      io_rdata,
  input  logic [NUM_WRITE-1:0]                     io_wen,
  input  logic [NUM_WRITE-1:0][ADDR_W-1:0]         io_waddr,
  input  logic [NUM_WRITE-1:0][DATA_WIDTH-1:0]     io_wdata
);

  logic [NUM_ENTRIES-1:0][DATA_WIDTH-1:0] data;

  // 读口：写旁路优先，否则读寄存器堆
  always_comb begin
    for (int unsigned p = 0; p < NUM_READ; p++) begin
      logic                  byp_hit;
      logic [DATA_WIDTH-1:0] byp_data;
      byp_hit  = 1'b0;
      byp_data = '0;
      for (int unsigned w = 0; w < NUM_WRITE; w++) begin
        if (BYPASS_EN[p] && io_wen[w] && (io_waddr[w] == io_raddr[p])) begin
          byp_hit  = 1'b1;
          byp_data |= io_wdata[w];
        end
      end
      io_rdata[p] = byp_hit ? byp_data : data[io_raddr[p]];
    end
  end

  // 写口：按条目聚合
  logic [NUM_ENTRIES-1:0]                 wr_en;
  logic [NUM_ENTRIES-1:0][DATA_WIDTH-1:0] wr_data;

  always_comb begin
    for (int unsigned e = 0; e < NUM_ENTRIES; e++) begin
      wr_en[e]   = 1'b0;
      wr_data[e] = '0;
      for (int unsigned w = 0; w < NUM_WRITE; w++) begin
        if (io_wen[w] && (io_waddr[w] == ADDR_W'(e))) begin
          wr_en[e]   = 1'b1;
          wr_data[e] |= io_wdata[w];
        end
      end
    end
  end

  always_ff @(posedge clock) begin
    for (int unsigned e = 0; e < NUM_ENTRIES; e++)
      if (wr_en[e])
        data[e] <= wr_data[e];
  end

endmodule
