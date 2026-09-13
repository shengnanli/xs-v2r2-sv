// =============================================================================
// xs_SyncDataModule —— 分 bank 的同步读数据模块
//
// 对应 Chisel: utility.SyncDataModuleTemplate（FTQ 的 PC / 重定向信息等存储）
// 结构（与生成 RTL 一致，FM 等价依赖此结构）：
//   - 按容量分 bank：条目数 ≥128 时每 bank 64 项，否则 16 项；
//   - 每个 bank 复制一整套输入寄存器（降扇出）：
//       raddr_dup : 读地址，HAS_REN 时 RegEnable(ren)，否则 RegNext
//       wen_dup   : 写使能 RegNext，异步复位为 0（对应 GatedValidRegNext）
//       waddr_dup / wdata_dup : RegEnable(wen)，无复位
//   - bank 写使能 = wen_dup 且写地址高位命中本 bank；
//   - 输出级：每读口再复制一份读地址寄存器，用其高位选择 bank 读出。
// 读延迟 1 拍（地址打一拍，bank 内组合读）。bank 内可选写旁路使先写后读
// （同拍写入、下拍读出同地址能读到新值——注意旁路比较的是打拍后的地址）。
// =============================================================================
module xs_SyncDataModule #(
  parameter int unsigned NUM_ENTRIES = 64,
  parameter int unsigned NUM_READ    = 1,
  parameter int unsigned NUM_WRITE   = 1,
  parameter int unsigned DATA_WIDTH  = 8,
  parameter bit          HAS_REN     = 1'b1,  // 0 时 io_ren 接 '1，地址恒采样
  parameter logic [NUM_READ-1:0] BYPASS_EN = '1,
  // G1 锚点（fail-closed，无可用默认值）：golden 对应的 SyncDataModuleTemplate_*
  // 里例化了几个 DataModule* 子模块。分 bank 是本核唯一的“数组深度派生算术”
  // （MAX_BANK_ENTRIES 随 NUM_ENTRIES 跳变 64/16，NUM_BANKS 再向上取整），
  // 条目数抄错时逻辑照跑、UT 未必打得到边界，只有 FM 才炸。
  parameter int unsigned G1_NUM_BANKS = 0,
  localparam int unsigned ADDR_W           = (NUM_ENTRIES > 1) ? $clog2(NUM_ENTRIES) : 1,
  localparam int unsigned MAX_BANK_ENTRIES = (NUM_ENTRIES >= 128) ? 64 : 16,
  localparam int unsigned NUM_BANKS        = (NUM_ENTRIES + MAX_BANK_ENTRIES - 1) / MAX_BANK_ENTRIES,
  localparam int unsigned OFF_W            = (NUM_BANKS > 1) ? $clog2(MAX_BANK_ENTRIES) : ADDR_W,
  localparam int unsigned BANK_W           = (NUM_BANKS > 1) ? ADDR_W - OFF_W : 1
)(
  input  logic                                 clock,
  input  logic                                 reset,   // 异步，仅复位 wen_dup
  input  logic [NUM_READ-1:0]                  io_ren,
  input  logic [NUM_READ-1:0][ADDR_W-1:0]      io_raddr,
  output logic [NUM_READ-1:0][DATA_WIDTH-1:0]  io_rdata,
  input  logic [NUM_WRITE-1:0]                 io_wen,
  input  logic [NUM_WRITE-1:0][ADDR_W-1:0]     io_waddr,
  input  logic [NUM_WRITE-1:0][DATA_WIDTH-1:0] io_wdata
);

  // ---------------------------------------------------------------------------
  // §参数自检（elaboration-time system task）
  //
  // 写法：$fatal 直接写在模块体里，不写在 initial 里 —— 模块体形式是 IEEE 1800
  // §20.11 的 elaboration system task，VCS 在 elaborate 阶段就报
  // `Error-[FEST] $fatal elaboration system task` 并 rc=255 退出，纯 elaborate /
  // 综合流程也拦得住；initial 形式只有仿真启动 time 0 才炸。Formality
  // （V-2023.12-SP3）两种都读得进，条件为真时打印同一条消息并把本模块降级成黑盒，
  // 被 fm_verdict 的 bbox 闸拦下，仍是 fail-closed。
  // 消息里避开 UTF-8 含 0xAE 字节的汉字（宏/位宽/实/定/段/算…）：VCS 在
  // elaboration 消息里会把该字节打成 '.'，好好一句话变乱码（运行期 $fatal 正常）。
  //
  // G1_NUM_BANKS 是**从 golden 现读**的锚点：golden 对应的
  // SyncDataModuleTemplate_* 里例化了几个 DataModule* 子模块，这里就该分出几个
  // bank。它是 fail-closed 的（默认 0 = 没传就炸），别指望"不传即免检"。
  // ---------------------------------------------------------------------------
  if (G1_NUM_BANKS == 0)
    $fatal(1, "xs_SyncDataModule: 调用方必须传 G1_NUM_BANKS(= golden 对应 SyncDataModuleTemplate_* 里 DataModule* 子模块的个数), 不传不给过 -- 当前 NUM_ENTRIES=%0d 会分出 %0d 个 bank",
           NUM_ENTRIES, NUM_BANKS);
  if (NUM_BANKS != G1_NUM_BANKS)
    $fatal(1, "xs_SyncDataModule: NUM_ENTRIES=%0d 分出 %0d 个 bank, 但 golden 里是 %0d 个 -- entry 数或分 bank 规则对不上",
           NUM_ENTRIES, NUM_BANKS, G1_NUM_BANKS);
  if (NUM_BANKS > 1 && (NUM_ENTRIES % MAX_BANK_ENTRIES) != 0)
    $fatal(1, "xs_SyncDataModule: NUM_ENTRIES=%0d 不是 bank 大小 %0d 的整数倍 -- 最后一个 bank 会不满, 与 golden 的等分结构不符",
           NUM_ENTRIES, MAX_BANK_ENTRIES);
  // bank_index() 取地址高 BANK_W 位当下标去索引 bank_rdata[NUM_BANKS]。只要
  // 2**BANK_W != NUM_BANKS, 高位就能取出 >= NUM_BANKS 的值 -> 数组越界(chisel Vec
  // 越界是回绕, SV 里是 X), 这条挡的正是这种静默越界。
  if (NUM_BANKS > 1 && (32'd1 << BANK_W) != NUM_BANKS)
    $fatal(1, "xs_SyncDataModule: bank 下标 %0d 位能表示 %0d 个 bank, 但只有 %0d 个 -- bank_index() 会越界",
           BANK_W, 32'd1 << BANK_W, NUM_BANKS);

  function automatic logic [BANK_W-1:0] bank_index(input logic [ADDR_W-1:0] addr);
    if (NUM_BANKS > 1) bank_index = addr[ADDR_W-1:OFF_W];
    else               bank_index = '0;
  endfunction

  logic [NUM_BANKS-1:0][NUM_READ-1:0][DATA_WIDTH-1:0] bank_rdata;

  for (genvar b = 0; b < NUM_BANKS; b++) begin : g_bank
    // 本 bank 的输入寄存器复制
    logic [NUM_READ-1:0][ADDR_W-1:0]      raddr_dup;
    logic [NUM_WRITE-1:0]                 wen_dup;
    logic [NUM_WRITE-1:0][ADDR_W-1:0]     waddr_dup;
    logic [NUM_WRITE-1:0][DATA_WIDTH-1:0] wdata_dup;

    always_ff @(posedge clock) begin
      for (int unsigned p = 0; p < NUM_READ; p++)
        if (!HAS_REN || io_ren[p])
          raddr_dup[p] <= io_raddr[p];
      for (int unsigned w = 0; w < NUM_WRITE; w++)
        if (io_wen[w]) begin
          waddr_dup[w] <= io_waddr[w];
          wdata_dup[w] <= io_wdata[w];
        end
    end

    always_ff @(posedge clock or posedge reset) begin
      if (reset) wen_dup <= '0;
      else       wen_dup <= io_wen;
    end

    logic [NUM_READ-1:0][OFF_W-1:0]  bank_raddr;
    logic [NUM_WRITE-1:0]            bank_wen;
    logic [NUM_WRITE-1:0][OFF_W-1:0] bank_waddr;

    always_comb begin
      for (int unsigned p = 0; p < NUM_READ; p++)
        bank_raddr[p] = raddr_dup[p][OFF_W-1:0];
      for (int unsigned w = 0; w < NUM_WRITE; w++) begin
        bank_wen[w]   = wen_dup[w] && (bank_index(waddr_dup[w]) == BANK_W'(b));
        bank_waddr[w] = waddr_dup[w][OFF_W-1:0];
      end
    end

    xs_DataModule #(
      .NUM_ENTRIES ((b < NUM_BANKS-1) ? MAX_BANK_ENTRIES : NUM_ENTRIES - b*MAX_BANK_ENTRIES),
      .NUM_READ    (NUM_READ),
      .NUM_WRITE   (NUM_WRITE),
      .DATA_WIDTH  (DATA_WIDTH),
      .BYPASS_EN   (BYPASS_EN)
    ) dataBank (
      .clock    (clock),
      .io_raddr (bank_raddr),
      .io_rdata (bank_rdata[b]),
      .io_wen   (bank_wen),
      .io_waddr (bank_waddr),
      .io_wdata (wdata_dup)
    );
  end

  // 输出级：每读口独立的地址寄存器副本，用高位选 bank
  for (genvar p = 0; p < NUM_READ; p++) begin : g_rport
    logic [ADDR_W-1:0] raddr_q;
    always_ff @(posedge clock) begin
      if (!HAS_REN || io_ren[p])
        raddr_q <= io_raddr[p];
    end
    assign io_rdata[p] = bank_rdata[bank_index(raddr_q)][p];
  end

endmodule
