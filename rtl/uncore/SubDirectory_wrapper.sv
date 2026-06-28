// 自动生成 scripts/gen_subdirectory.py —— 勿手改
module SubDirectory(
  input clock,
  input reset,
  output io_read_ready,
  input io_read_valid,
  input [29:0] io_read_bits_tag,
  input [9:0] io_read_bits_set,
  input [6:0] io_read_bits_replacerInfo_opcode,
  input io_read_bits_replacerInfo_refill,
  output io_resp_valid,
  output io_resp_bits_hit,
  output [29:0] io_resp_bits_tag,
  output [9:0] io_resp_bits_set,
  output [3:0] io_resp_bits_way,
  output io_resp_bits_meta_0_valid,
  output io_resp_bits_error,
  input io_tagWReq_valid,
  input [9:0] io_tagWReq_bits_set,
  input [3:0] io_tagWReq_bits_way,
  input [29:0] io_tagWReq_bits_wtag,
  input io_metaWReq_valid,
  input [9:0] io_metaWReq_bits_set,
  input [9:0] io_metaWReq_bits_wayOH,
  input io_metaWReq_bits_wmeta_0_valid
);

  wire              _lfsr_prng_io_out_0;
  wire              _lfsr_prng_io_out_1;
  wire              _lfsr_prng_io_out_2;
  wire              _lfsr_prng_io_out_3;
  wire              _lfsr_prng_io_out_4;
  wire              _lfsr_prng_io_out_5;
  wire              _lfsr_prng_io_out_6;
  wire              _metaArray_io_r_resp_data_0_0_valid;
  wire              _metaArray_io_r_resp_data_1_0_valid;
  wire              _metaArray_io_r_resp_data_2_0_valid;
  wire              _metaArray_io_r_resp_data_3_0_valid;
  wire              _metaArray_io_r_resp_data_4_0_valid;
  wire              _metaArray_io_r_resp_data_5_0_valid;
  wire              _metaArray_io_r_resp_data_6_0_valid;
  wire              _metaArray_io_r_resp_data_7_0_valid;
  wire              _metaArray_io_r_resp_data_8_0_valid;
  wire              _metaArray_io_r_resp_data_9_0_valid;
  wire [29:0]       _tagArray_io_r_resp_data_0;
  wire [29:0]       _tagArray_io_r_resp_data_1;
  wire [29:0]       _tagArray_io_r_resp_data_2;
  wire [29:0]       _tagArray_io_r_resp_data_3;
  wire [29:0]       _tagArray_io_r_resp_data_4;
  wire [29:0]       _tagArray_io_r_resp_data_5;
  wire [29:0]       _tagArray_io_r_resp_data_6;
  wire [29:0]       _tagArray_io_r_resp_data_7;
  wire [29:0]       _tagArray_io_r_resp_data_8;
  wire [29:0]       _tagArray_io_r_resp_data_9;

  // ---- 核与 SRAM/LFSR 黑盒的边界 wire (核的 o_* 输出) ----
  wire        o_ren;
  wire [9:0]  o_tagWaymask;
  wire        o_metaWen;
  wire [9:0]  o_metaWset;
  wire        o_metaWdata;
  wire [9:0]  o_metaWaymask;

  xs_SubDirectory_core u_core (
    .clock(clock),
    .reset(reset),
    .io_read_ready(io_read_ready),
    .io_read_valid(io_read_valid),
    .io_read_bits_tag(io_read_bits_tag),
    .io_read_bits_set(io_read_bits_set),
    .io_read_bits_replacerInfo_opcode(io_read_bits_replacerInfo_opcode),
    .io_read_bits_replacerInfo_refill(io_read_bits_replacerInfo_refill),
    .io_resp_valid(io_resp_valid),
    .io_resp_bits_hit(io_resp_bits_hit),
    .io_resp_bits_tag(io_resp_bits_tag),
    .io_resp_bits_set(io_resp_bits_set),
    .io_resp_bits_way(io_resp_bits_way),
    .io_resp_bits_meta_0_valid(io_resp_bits_meta_0_valid),
    .io_resp_bits_error(io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_0_valid(io_metaWReq_bits_wmeta_0_valid),
    .i_tagRead_0(_tagArray_io_r_resp_data_0),
    .i_tagRead_1(_tagArray_io_r_resp_data_1),
    .i_tagRead_2(_tagArray_io_r_resp_data_2),
    .i_tagRead_3(_tagArray_io_r_resp_data_3),
    .i_tagRead_4(_tagArray_io_r_resp_data_4),
    .i_tagRead_5(_tagArray_io_r_resp_data_5),
    .i_tagRead_6(_tagArray_io_r_resp_data_6),
    .i_tagRead_7(_tagArray_io_r_resp_data_7),
    .i_tagRead_8(_tagArray_io_r_resp_data_8),
    .i_tagRead_9(_tagArray_io_r_resp_data_9),
    .i_metaValid_0(_metaArray_io_r_resp_data_0_0_valid),
    .i_metaValid_1(_metaArray_io_r_resp_data_1_0_valid),
    .i_metaValid_2(_metaArray_io_r_resp_data_2_0_valid),
    .i_metaValid_3(_metaArray_io_r_resp_data_3_0_valid),
    .i_metaValid_4(_metaArray_io_r_resp_data_4_0_valid),
    .i_metaValid_5(_metaArray_io_r_resp_data_5_0_valid),
    .i_metaValid_6(_metaArray_io_r_resp_data_6_0_valid),
    .i_metaValid_7(_metaArray_io_r_resp_data_7_0_valid),
    .i_metaValid_8(_metaArray_io_r_resp_data_8_0_valid),
    .i_metaValid_9(_metaArray_io_r_resp_data_9_0_valid),
    .i_lfsr_0(_lfsr_prng_io_out_0),
    .i_lfsr_1(_lfsr_prng_io_out_1),
    .i_lfsr_2(_lfsr_prng_io_out_2),
    .i_lfsr_3(_lfsr_prng_io_out_3),
    .i_lfsr_4(_lfsr_prng_io_out_4),
    .i_lfsr_5(_lfsr_prng_io_out_5),
    .i_lfsr_6(_lfsr_prng_io_out_6),
    .o_ren(o_ren),
    .o_tagWaymask(o_tagWaymask),
    .o_metaWen(o_metaWen),
    .o_metaWset(o_metaWset),
    .o_metaWdata(o_metaWdata),
    .o_metaWaymask(o_metaWaymask)
  );

  SRAMTemplate_197 tagArray (
    .clock                 (clock),
    .io_r_req_ready        (/* unused */),
    .io_r_req_valid        (o_ren),
    .io_r_req_bits_setIdx  (io_read_bits_set),
    .io_r_resp_data_0      (_tagArray_io_r_resp_data_0),
    .io_r_resp_data_1      (_tagArray_io_r_resp_data_1),
    .io_r_resp_data_2      (_tagArray_io_r_resp_data_2),
    .io_r_resp_data_3      (_tagArray_io_r_resp_data_3),
    .io_r_resp_data_4      (_tagArray_io_r_resp_data_4),
    .io_r_resp_data_5      (_tagArray_io_r_resp_data_5),
    .io_r_resp_data_6      (_tagArray_io_r_resp_data_6),
    .io_r_resp_data_7      (_tagArray_io_r_resp_data_7),
    .io_r_resp_data_8      (_tagArray_io_r_resp_data_8),
    .io_r_resp_data_9      (_tagArray_io_r_resp_data_9),
    .io_w_req_ready        (/* unused */),
    .io_w_req_valid        (io_tagWReq_valid),
    .io_w_req_bits_setIdx  (io_tagWReq_bits_set),
    .io_w_req_bits_data_0  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_1  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_2  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_3  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_4  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_5  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_6  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_7  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_8  (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_9  (io_tagWReq_bits_wtag),
    .io_w_req_bits_waymask (o_tagWaymask)
  );
  SRAMTemplate_198 metaArray (
    .clock                        (clock),
    .io_r_req_ready               (/* unused */),
    .io_r_req_valid               (o_ren),
    .io_r_req_bits_setIdx         (io_read_bits_set),
    .io_r_resp_data_0_0_valid     (_metaArray_io_r_resp_data_0_0_valid),
    .io_r_resp_data_1_0_valid     (_metaArray_io_r_resp_data_1_0_valid),
    .io_r_resp_data_2_0_valid     (_metaArray_io_r_resp_data_2_0_valid),
    .io_r_resp_data_3_0_valid     (_metaArray_io_r_resp_data_3_0_valid),
    .io_r_resp_data_4_0_valid     (_metaArray_io_r_resp_data_4_0_valid),
    .io_r_resp_data_5_0_valid     (_metaArray_io_r_resp_data_5_0_valid),
    .io_r_resp_data_6_0_valid     (_metaArray_io_r_resp_data_6_0_valid),
    .io_r_resp_data_7_0_valid     (_metaArray_io_r_resp_data_7_0_valid),
    .io_r_resp_data_8_0_valid     (_metaArray_io_r_resp_data_8_0_valid),
    .io_r_resp_data_9_0_valid     (_metaArray_io_r_resp_data_9_0_valid),
    .io_w_req_ready               (/* unused */),
    .io_w_req_valid               (o_metaWen),
    .io_w_req_bits_setIdx         (o_metaWset),
    .io_w_req_bits_data_0_0_valid (o_metaWdata),
    .io_w_req_bits_data_1_0_valid (o_metaWdata),
    .io_w_req_bits_data_2_0_valid (o_metaWdata),
    .io_w_req_bits_data_3_0_valid (o_metaWdata),
    .io_w_req_bits_data_4_0_valid (o_metaWdata),
    .io_w_req_bits_data_5_0_valid (o_metaWdata),
    .io_w_req_bits_data_6_0_valid (o_metaWdata),
    .io_w_req_bits_data_7_0_valid (o_metaWdata),
    .io_w_req_bits_data_8_0_valid (o_metaWdata),
    .io_w_req_bits_data_9_0_valid (o_metaWdata),
    .io_w_req_bits_waymask        (o_metaWaymask)
  );
  MaxPeriodFibonacciLFSR_3 lfsr_prng (
    .clock     (clock),
    .reset     (reset),
    .io_out_0  (_lfsr_prng_io_out_0),
    .io_out_1  (_lfsr_prng_io_out_1),
    .io_out_2  (_lfsr_prng_io_out_2),
    .io_out_3  (_lfsr_prng_io_out_3),
    .io_out_4  (_lfsr_prng_io_out_4),
    .io_out_5  (_lfsr_prng_io_out_5),
    .io_out_6  (_lfsr_prng_io_out_6),
    .io_out_7  (/* unused */),
    .io_out_8  (/* unused */),
    .io_out_9  (/* unused */),
    .io_out_10 (/* unused */),
    .io_out_11 (/* unused */),
    .io_out_12 (/* unused */),
    .io_out_13 (/* unused */),
    .io_out_14 (/* unused */),
    .io_out_15 (/* unused */)
  );
endmodule
