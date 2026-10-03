// =============================================================================
// xs_CsrEpcTvec_core.sv —— CSR trap 返回地址/向量寄存器族的共享核（无 wrapper）。
// 使用者：Mepc/Sepc/VSepc/Mnepc（epc 亚族，trap 返回地址）与 Mtvec/Stvec/
// VStvec（tvec 亚族，trap 向量）共 7 个 golden 变体的薄文件，父模块是 NewCSR。
// 两亚族共骨架（异步复位到 0 的状态寄存器 + 软件写口），差异由 IS_TVEC 参数
// 在 generate 里区分，核体只有这一份：
//   IS_TVEC=0（epc）：63 位返回地址寄存器，读出的 bit0 恒 0。软件写或 trap
//     装载任一成立即更新；同拍竞争时两路按位或合并（golden 原文即 OR，
//     不是优先级选择，照搬）。
//   IS_TVEC=1（tvec）：base[63:2] 软件写直通；mode[1:0] 是 WARL 字段，只接受
//     Direct(0)/Vectored(1)，非法编码（2/3）的写丢弃 mode、保持旧值，base 照写。
//     tvec 无 trap 装载口，薄文件把 trap_valid/trap_epc 绑常量。
// 复位域：全部寄存器异步高有效清 0（对齐 golden posedge clock or posedge reset）。
// =============================================================================

module xs_CsrEpcTvec_core #(
  parameter bit IS_TVEC = 1'b0  // 0: epc 亚族（trap 返回地址）；1: tvec 亚族（trap 向量 base/mode）
) (
  input  logic        clock,
  input  logic        reset,       // 异步、高有效
  input  logic        wen,         // 软件写使能（CSR 写口，golden 名 w_wen）
  input  logic [63:0] wdata,       // 软件写数据：epc 取 [63:1]；tvec base 取 [63:2]、mode 取 [1:0]
  input  logic        trap_valid,  // trap 装载使能（仅 epc 亚族用；tvec 薄文件绑 1'b0）
  input  logic [62:0] trap_epc,    // trap 装载的返回地址（仅 epc 亚族用；tvec 薄文件绑 0）
  output logic [63:0] rdata,       // CSR 整字读：epc={epc_q,1'b0}；tvec={addr_q,mode_q}
  output logic [62:0] epc,         // regOut_epc（仅 epc 亚族；tvec 时绑 0、薄文件不连）
  output logic [1:0]  mode,        // regOut_mode（仅 tvec 亚族；epc 时绑 0、薄文件不连）
  output logic [61:0] addr         // regOut_addr（仅 tvec 亚族；epc 时绑 0、薄文件不连）
);

  if (!IS_TVEC) begin : g_epc
    // epc 亚族：trap 返回地址寄存器（mepc/sepc/vsepc/mnepc）。
    // golden 只存 [63:1] 这 63 位，读出的 bit0 恒 0（{reg_epc, 1'h0}）。
    logic [62:0] epc_q;
    always_ff @(posedge clock or posedge reset) begin
      if (reset)
        epc_q <= 63'h0;
      else if (wen | trap_valid)
        // 写使能 = 「软件写 或 trap 装载」；同拍竞争时两路按位或合并
        // （golden 原文即 (trap ? bits : 0) | (wen ? wdata[63:1] : 0)）。
        epc_q <= (trap_valid ? trap_epc    : 63'h0)
               | (wen        ? wdata[63:1] : 63'h0);
    end
    assign rdata = {epc_q, 1'b0};
    assign epc   = epc_q;
    assign mode  = 2'h0;   // 本亚族无此字段，薄文件不连这个口
    assign addr  = 62'h0;  // 本亚族无此字段，薄文件不连这个口
  end
  else begin : g_tvec
    // tvec 亚族：trap 向量 = {base[63:2], mode[1:0]}（mtvec/stvec/vstvec）。
    logic [1:0]  mode_q;   // WARL：仅 Direct(0)/Vectored(1) 合法
    logic [61:0] addr_q;   // base；读出的 [1:0] 是 mode，不是地址低位
    always_ff @(posedge clock or posedge reset) begin
      if (reset) begin
        mode_q <= 2'h0;
        addr_q <= 62'h0;
      end
      else begin
        // mode 与 base 是两条并列更新门（golden 原文即两个独立 if，非 else-if）：
        // 非法 mode 编码只丢 mode 那一路，base 同拍照写。
        if (wen & (wdata[1:0] == 2'h0 | wdata[1:0] == 2'h1))
          mode_q <= wdata[1:0];
        if (wen)
          addr_q <= wdata[63:2];
      end
    end
    assign rdata = {addr_q, mode_q};
    assign epc   = 63'h0;  // 本亚族无此字段，薄文件不连这个口
    assign mode  = mode_q;
    assign addr  = addr_q;
  end

endmodule
