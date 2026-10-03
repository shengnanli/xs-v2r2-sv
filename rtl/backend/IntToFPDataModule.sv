// =============================================================================
// IntToFPDataModule —— 整数转浮点（fcvt.{s,d,h}.{w,wu,l,lu}）与整数搬入浮点寄存器（fmv.*.x）
//                       的两级流水数据通路（IntToFP 执行单元的数据模块）
//
// 设计源：src/main/scala/xiangshan/backend/fu/fpu/IntToFP.scala（class IntToFPDataModule，latency=2）。
//
// 流水（regEnables[k] 由外层 FPUPipelineModule 按"第 k+1 级有效且不被冲刷"给出）：
//   §1 第 1 级（regEnables[0]）：锁存整数操作数 intValue、控制 ctrlReg、舍入模式 rmReg。
//        wflags=1（真转换）且 typ[1]=0（32 位源 w/wu）时，先把 src[31:0] 按 typ[0]
//        （1=无符号 wu）零扩展或符号扩展到 64 位；其余情况（64 位源，或 wflags=0 的 fmv）原样。
//        rm：指令 rm==111（DYN）时取动态舍入模式 io_rm（fcsr.frm）。
//   §2 第 2 级（组合）：三个转换器 IntToFP / _1 / _2 并行算 f32 / f64 / f16 结果；
//        wflags=1 时按目标类型 typeTagOut 选结果与 fflags；wflags=0（fmv）时数据就是
//        intValue、fflags=0。
//        typeTagOut：0=f32、1=f64、2=f16；3 越界，Chisel 动态下标越界时 firtool 取第 0 项（f32）。
//   §3 第 3 级（regEnables[1]）：锁存 s3_out（data/exc）与 s3_tag。
//   §4 输出：按 s3_tag 做 NaN-boxing（FPU.box）——f32 高 32 位全 1，f16 高 48 位全 1，
//        f64 原样；tag==3 输出 0（golden 三路或，无命中项）。
//
// 子模块：IntToFP / IntToFP_1 / IntToFP_2（实例名与 golden 同），两侧白盒（PROVEN_DIRECT 重写件）。
// 寄存器都不复位（RegEnable）。
// =============================================================================
module xs_IntToFPDataModule_core (
  input  logic        clock,
  input  logic [63:0] src,
  input  logic [1:0]  ctrl_type_tag_out,
  input  logic        ctrl_wflags,
  input  logic [1:0]  ctrl_typ,
  input  logic [2:0]  ctrl_rm,
  input  logic [2:0]  dyn_rm,
  input  logic        stage1_en,
  input  logic        stage2_en,
  output logic [63:0] out_data,
  output logic [4:0]  out_fflags
);

  // ---------------------------------------------------------------------------
  // §1 第 1 级：操作数扩展、控制与舍入模式锁存
  // ---------------------------------------------------------------------------
  logic [63:0] intValue;
  logic [1:0]  ctrlReg_typeTagOut;
  logic        ctrlReg_wflags;
  logic [1:0]  ctrlReg_typ;
  logic [2:0]  rmReg;

  logic [63:0] src_extended;
  always_comb begin
    if (ctrl_wflags && !ctrl_typ[1])        // 32 位整数源：先扩成 64 位
      src_extended = {ctrl_typ[0] ? 32'd0 : {32{src[31]}}, src[31:0]};
    else                                    // 64 位源，或 fmv 原样搬运
      src_extended = src;
  end

  always_ff @(posedge clock) begin
    if (stage1_en) begin
      intValue           <= src_extended;
      ctrlReg_typeTagOut <= ctrl_type_tag_out;
      ctrlReg_wflags     <= ctrl_wflags;
      ctrlReg_typ        <= ctrl_typ;
      rmReg              <= (ctrl_rm == 3'b111) ? dyn_rm : ctrl_rm;   // DYN ⇒ 取 frm
    end
  end

  // ---------------------------------------------------------------------------
  // §2 第 2 级：三种目标精度并行转换，按 typeTagOut 选
  // ---------------------------------------------------------------------------
  logic [31:0] f32_result;
  logic [4:0]  f32_fflags;
  logic [63:0] f64_result;
  logic [4:0]  f64_fflags;
  logic [15:0] f16_result;
  logic [4:0]  f16_fflags;

  IntToFP i2fResults_i2f (                  // → f32
    .io_int    (intValue),
    .io_sign   (~ctrlReg_typ[0]),
    .io_long   (ctrlReg_typ[1]),
    .io_rm     (rmReg),
    .io_result (f32_result),
    .io_fflags (f32_fflags)
  );
  IntToFP_1 i2fResults_i2f_1 (              // → f64
    .io_int    (intValue),
    .io_sign   (~ctrlReg_typ[0]),
    .io_long   (ctrlReg_typ[1]),
    .io_rm     (rmReg),
    .io_result (f64_result),
    .io_fflags (f64_fflags)
  );
  IntToFP_2 i2fResults_i2f_2 (              // → f16
    .io_int    (intValue),
    .io_sign   (~ctrlReg_typ[0]),
    .io_long   (ctrlReg_typ[1]),
    .io_rm     (rmReg),
    .io_result (f16_result),
    .io_fflags (f16_fflags)
  );

  logic [63:0] s2_data;
  logic [4:0]  s2_exc;
  always_comb begin
    if (!ctrlReg_wflags) begin              // fmv：不转换
      s2_data = intValue;
      s2_exc  = 5'd0;
    end else begin
      case (ctrlReg_typeTagOut)
        2'd1:    begin s2_data = f64_result;           s2_exc = f64_fflags; end
        2'd2:    begin s2_data = {48'd0, f16_result};  s2_exc = f16_fflags; end
        default: begin s2_data = {32'd0, f32_result};  s2_exc = f32_fflags; end   // 0 与越界的 3
      endcase
    end
  end

  // ---------------------------------------------------------------------------
  // §3 第 3 级：结果锁存
  // ---------------------------------------------------------------------------
  logic [63:0] s3_out_data;
  logic [4:0]  s3_out_exc;
  logic [1:0]  s3_tag;

  always_ff @(posedge clock) begin
    if (stage2_en) begin
      s3_out_data <= s2_data;
      s3_out_exc  <= s2_exc;
      s3_tag      <= ctrlReg_typeTagOut;
    end
  end

  // ---------------------------------------------------------------------------
  // §4 输出：NaN-boxing
  // ---------------------------------------------------------------------------
  always_comb begin
    case (s3_tag)
      2'd0:    out_data = {32'hFFFF_FFFF, s3_out_data[31:0]};      // f32
      2'd1:    out_data = s3_out_data;                             // f64
      2'd2:    out_data = {48'hFFFF_FFFF_FFFF, s3_out_data[15:0]}; // f16
      default: out_data = 64'd0;
    endcase
  end
  assign out_fflags = s3_out_exc;

endmodule

// ---------------------------------------------------------------------------
// golden 同名 wrapper：端口与 G1 golden IntToFPDataModule.sv 逐位一致
// ---------------------------------------------------------------------------
module IntToFPDataModule (
  input         clock,
  input  [63:0] io_in_src_0,
  input  [1:0]  io_in_fpCtrl_typeTagOut,
  input         io_in_fpCtrl_wflags,
  input  [1:0]  io_in_fpCtrl_typ,
  input  [2:0]  io_in_fpCtrl_rm,
  input  [2:0]  io_in_rm,
  output [63:0] io_out_data,
  output [4:0]  io_out_fflags,
  input         regEnables_0,
  input         regEnables_1
);

  xs_IntToFPDataModule_core u_core (
    .clock             (clock),
    .src               (io_in_src_0),
    .ctrl_type_tag_out (io_in_fpCtrl_typeTagOut),
    .ctrl_wflags       (io_in_fpCtrl_wflags),
    .ctrl_typ          (io_in_fpCtrl_typ),
    .ctrl_rm           (io_in_fpCtrl_rm),
    .dyn_rm            (io_in_rm),
    .stage1_en         (regEnables_0),
    .stage2_en         (regEnables_1),
    .out_data          (io_out_data),
    .out_fflags        (io_out_fflags)
  );

endmodule
