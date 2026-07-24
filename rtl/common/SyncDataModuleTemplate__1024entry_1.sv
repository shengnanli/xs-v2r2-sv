// =============================================================================
// xs_SyncDataModule_1024e1 —— SyncDataModuleTemplate__1024entry_1 专用同步读核
//
// 为什么单独一个核（而非复用通用 xs_SyncDataModule）：
//   本变体是 XiangShan SSIT/等待表用的 {ssid[5], strict[1]} 存储，1024 项、2 读 2 写。
//   其两个写口是**非对称**的：
//     - 写口 0 写全部 6 位（ssid + strict）；
//     - 写口 1 只写 ssid（5 位），strict 位从不由写口 1 写入。
//   golden（firtool 产物）据此只为写口 1 保留 5 位写数据寄存器（r_1_ssid），
//   不生成写口 1 的 strict 寄存器。通用核对所有写口按同一 DATA_WIDTH 复制写数据
//   寄存器，会给写口 1 多存一个恒 0 的 strict 位 → 与 golden 不等价的 impl-only
//   常量死寄存器（wdata_dup[1][5]）。这里按 golden 结构把写口 1 的写数据寄存器
//   收窄到 5 位（ssid），消除该死位，结构与 golden 一一对应。
//
// 结构（与 golden SyncDataModuleTemplate__1024entry_1 一致）：
//   - 1024 项分 16 个 bank，每 bank 64 项（addr[9:6] 选 bank，addr[5:0] 选项内偏移）；
//   - 每个 bank 复制一整套输入寄存器（降扇出）：
//       raddr_dup[p] : 读地址，RegEnable(io_ren[p])；
//       waddr_dup[w] : 写地址，RegEnable(io_wen[w])；
//       wdata0_dup   : 写口 0 数据 {strict, ssid} 6 位，RegEnable(io_wen_0)；
//       wdata1_ssid_dup : 写口 1 数据 ssid 5 位，RegEnable(io_wen_1)；
//       wen_dup[w]   : 写使能 RegNext，异步复位为 0（GatedValidRegNext）；
//   - bank 内 DataModule：6 位存储；写口 0 写全 6 位、写口 1 仅贡献 ssid（strict=0）；
//     组合读，两读口写旁路；读口 1 只输出 ssid（strict 不读）。
//   读延迟 1 拍。
// =============================================================================
module xs_SyncDataModule_1024e1 (
  input  logic        clock,
  input  logic        reset,   // 异步，仅复位 wen_dup
  input  logic [1:0]  io_ren,
  input  logic [1:0][9:0] io_raddr,
  // 读数据打包：{strict, ssid[4:0]}，读口 1 的 strict 位不被使用
  output logic [1:0][5:0] io_rdata,
  input  logic [1:0]  io_wen,
  input  logic [1:0][9:0] io_waddr,
  input  logic [4:0]  io_wdata_0_ssid,
  input  logic        io_wdata_0_strict,
  input  logic [4:0]  io_wdata_1_ssid
);

  localparam int unsigned NUM_BANKS = 16;

  logic [NUM_BANKS-1:0][1:0][5:0] bank_rdata;

  for (genvar b = 0; b < NUM_BANKS; b++) begin : g_bank
    // 本 bank 的输入寄存器复制
    logic [1:0][9:0] raddr_dup;
    logic [1:0]      wen_dup;
    logic [1:0][9:0] waddr_dup;
    logic [5:0]      wdata0_dup;      // 写口 0：{strict, ssid}，6 位
    logic [4:0]      wdata1_ssid_dup; // 写口 1：仅 ssid，5 位（无 strict）

    always_ff @(posedge clock) begin
      for (int unsigned p = 0; p < 2; p++)
        if (io_ren[p]) raddr_dup[p] <= io_raddr[p];
      if (io_wen[0]) begin
        waddr_dup[0] <= io_waddr[0];
        wdata0_dup   <= {io_wdata_0_strict, io_wdata_0_ssid};
      end
      if (io_wen[1]) begin
        waddr_dup[1]    <= io_waddr[1];
        wdata1_ssid_dup <= io_wdata_1_ssid;
      end
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) wen_dup <= '0;
      else       wen_dup <= io_wen;
    end

    logic [1:0][5:0] bank_raddr;
    logic [1:0]      bank_wen;
    logic [1:0][5:0] bank_waddr;

    always_comb begin
      for (int unsigned p = 0; p < 2; p++)
        bank_raddr[p] = raddr_dup[p][5:0];
      for (int unsigned w = 0; w < 2; w++) begin
        bank_wen[w]   = wen_dup[w] && (waddr_dup[w][9:6] == 4'(b));
        bank_waddr[w] = waddr_dup[w][5:0];
      end
    end

    // 写口 1 的 strict 恒 0（golden 语义：写口 1 不写 strict）
    xs_DataModule #(
      .NUM_ENTRIES (64),
      .NUM_READ    (2),
      .NUM_WRITE   (2),
      .DATA_WIDTH  (6),
      .BYPASS_EN   (2'b11)
    ) dataBank (
      .clock    (clock),
      .io_raddr (bank_raddr),
      .io_rdata (bank_rdata[b]),
      .io_wen   (bank_wen),
      .io_waddr (bank_waddr),
      .io_wdata ({{1'h0, wdata1_ssid_dup}, wdata0_dup})
    );
  end

  // 输出级：每读口独立的地址寄存器副本，用高位选 bank
  for (genvar p = 0; p < 2; p++) begin : g_rport
    logic [9:0] raddr_q;
    always_ff @(posedge clock) begin
      if (io_ren[p]) raddr_q <= io_raddr[p];
    end
    assign io_rdata[p] = bank_rdata[raddr_q[9:6]][p];
  end

endmodule
