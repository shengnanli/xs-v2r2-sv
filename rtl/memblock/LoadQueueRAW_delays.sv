// =============================================================================
//  LoadQueueRAW 违例输出流水延迟子模块（可读重写，镜像 golden 同名叶子）
// -----------------------------------------------------------------------------
//  golden LoadQueueRAW 顶层为每个 store 端口例化：
//    DelayN_298        rollbackLqWb_p_valid_delay —— store fire(=valid&!miss) 延迟 3 拍
//    DelayNWithValid_148 stFtqIdx_p_pipMod        —— store ftqIdx.value(6b) valid 门控延迟 3 拍
//    DelayNWithValid_149 stFtqOffset_p_pipMod     —— store ftqOffset(4b)    valid 门控延迟 3 拍
//  三者与违例检测流水（3 拍）对齐，使 rollback 输出携带的 store ftq 信息与最终违例同拍。
//  DelayN 无 reset（RegNext 链）；DelayNWithValid 的 valid_REG 链有 reset，data 链无 reset。
// =============================================================================

// store fire 3 拍延迟（无 reset）
module DelayN_298(
  input  clock,
  input  io_in,
  output io_out
);
  reg REG, REG_1, REG_2;
  always_ff @(posedge clock) begin
    REG   <= io_in;
    REG_1 <= REG;
    REG_2 <= REG_1;
  end
  assign io_out = REG_2;
endmodule

// store ftqIdx.value(6b) valid 门控 3 拍延迟
module DelayNWithValid_148(
  input        clock,
  input        reset,
  input  [5:0] io_in_bits_value,
  input        io_in_valid,
  output [5:0] io_out_bits_value
);
  reg       valid_REG, valid_REG_1;
  reg [5:0] data_value, data_1_value, res_bits_value;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_REG   <= 1'b0;
      valid_REG_1 <= 1'b0;
    end else begin
      valid_REG   <= io_in_valid;
      valid_REG_1 <= valid_REG;
    end
  end
  always_ff @(posedge clock) begin
    if (io_in_valid) data_value     <= io_in_bits_value;
    if (valid_REG)   data_1_value   <= data_value;
    if (valid_REG_1) res_bits_value <= data_1_value;
  end
  assign io_out_bits_value = res_bits_value;
endmodule

// store ftqOffset(4b) valid 门控 3 拍延迟
module DelayNWithValid_149(
  input        clock,
  input        reset,
  input  [3:0] io_in_bits,
  input        io_in_valid,
  output [3:0] io_out_bits
);
  reg       valid_REG, valid_REG_1;
  reg [3:0] data, data_1, res_bits;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_REG   <= 1'b0;
      valid_REG_1 <= 1'b0;
    end else begin
      valid_REG   <= io_in_valid;
      valid_REG_1 <= valid_REG;
    end
  end
  always_ff @(posedge clock) begin
    if (io_in_valid) data     <= io_in_bits;
    if (valid_REG)   data_1   <= data;
    if (valid_REG_1) res_bits <= data_1;
  end
  assign io_out_bits = res_bits;
endmodule
