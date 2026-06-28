// 自动生成 scripts/gen_subdirectory1.py —— 勿手改
module SubDirectory_1_xs(
  input clock,
  input reset,
  output io_read_ready,
  input io_read_valid,
  input [27:0] io_read_bits_tag,
  input [11:0] io_read_bits_set,
  input [6:0] io_read_bits_replacerInfo_opcode,
  input io_read_bits_replacerInfo_refill,
  output io_resp_valid,
  output io_resp_bits_hit,
  output [27:0] io_resp_bits_tag,
  output [11:0] io_resp_bits_set,
  output [3:0] io_resp_bits_way,
  output io_resp_bits_meta_valid,
  output io_resp_bits_meta_dirty,
  output io_resp_bits_error,
  input io_tagWReq_valid,
  input [11:0] io_tagWReq_bits_set,
  input [3:0] io_tagWReq_bits_way,
  input [27:0] io_tagWReq_bits_wtag,
  input io_metaWReq_valid,
  input [11:0] io_metaWReq_bits_set,
  input [15:0] io_metaWReq_bits_wayOH,
  input io_metaWReq_bits_wmeta_valid,
  input io_metaWReq_bits_wmeta_dirty
);

  wire [14:0]       _replacer_sram_opt_io_r_resp_data_0;
  wire              _metaArray_io_r_resp_data_0_valid;
  wire              _metaArray_io_r_resp_data_0_dirty;
  wire              _metaArray_io_r_resp_data_1_valid;
  wire              _metaArray_io_r_resp_data_1_dirty;
  wire              _metaArray_io_r_resp_data_2_valid;
  wire              _metaArray_io_r_resp_data_2_dirty;
  wire              _metaArray_io_r_resp_data_3_valid;
  wire              _metaArray_io_r_resp_data_3_dirty;
  wire              _metaArray_io_r_resp_data_4_valid;
  wire              _metaArray_io_r_resp_data_4_dirty;
  wire              _metaArray_io_r_resp_data_5_valid;
  wire              _metaArray_io_r_resp_data_5_dirty;
  wire              _metaArray_io_r_resp_data_6_valid;
  wire              _metaArray_io_r_resp_data_6_dirty;
  wire              _metaArray_io_r_resp_data_7_valid;
  wire              _metaArray_io_r_resp_data_7_dirty;
  wire              _metaArray_io_r_resp_data_8_valid;
  wire              _metaArray_io_r_resp_data_8_dirty;
  wire              _metaArray_io_r_resp_data_9_valid;
  wire              _metaArray_io_r_resp_data_9_dirty;
  wire              _metaArray_io_r_resp_data_10_valid;
  wire              _metaArray_io_r_resp_data_10_dirty;
  wire              _metaArray_io_r_resp_data_11_valid;
  wire              _metaArray_io_r_resp_data_11_dirty;
  wire              _metaArray_io_r_resp_data_12_valid;
  wire              _metaArray_io_r_resp_data_12_dirty;
  wire              _metaArray_io_r_resp_data_13_valid;
  wire              _metaArray_io_r_resp_data_13_dirty;
  wire              _metaArray_io_r_resp_data_14_valid;
  wire              _metaArray_io_r_resp_data_14_dirty;
  wire              _metaArray_io_r_resp_data_15_valid;
  wire              _metaArray_io_r_resp_data_15_dirty;
  wire [27:0]       _tagArray_io_r_resp_data_0;
  wire [27:0]       _tagArray_io_r_resp_data_1;
  wire [27:0]       _tagArray_io_r_resp_data_2;
  wire [27:0]       _tagArray_io_r_resp_data_3;
  wire [27:0]       _tagArray_io_r_resp_data_4;
  wire [27:0]       _tagArray_io_r_resp_data_5;
  wire [27:0]       _tagArray_io_r_resp_data_6;
  wire [27:0]       _tagArray_io_r_resp_data_7;
  wire [27:0]       _tagArray_io_r_resp_data_8;
  wire [27:0]       _tagArray_io_r_resp_data_9;
  wire [27:0]       _tagArray_io_r_resp_data_10;
  wire [27:0]       _tagArray_io_r_resp_data_11;
  wire [27:0]       _tagArray_io_r_resp_data_12;
  wire [27:0]       _tagArray_io_r_resp_data_13;
  wire [27:0]       _tagArray_io_r_resp_data_14;
  wire [27:0]       _tagArray_io_r_resp_data_15;

  // ---- 核与 SRAM 黑盒的边界 wire (核的 o_* 输出) ----
  wire        o_ren;
  wire        o_metaWen;
  wire [11:0] o_metaWset;
  wire        o_metaWvalid;
  wire        o_metaWdirty;
  wire [15:0] o_metaWaymask;
  wire        o_replWen;
  wire [11:0] o_replWset;
  wire [14:0] o_replWdata;

  xs_SubDirectory_1_core u_core (
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
    .io_resp_bits_meta_valid(io_resp_bits_meta_valid),
    .io_resp_bits_meta_dirty(io_resp_bits_meta_dirty),
    .io_resp_bits_error(io_resp_bits_error),
    .io_tagWReq_valid(io_tagWReq_valid),
    .io_tagWReq_bits_set(io_tagWReq_bits_set),
    .io_tagWReq_bits_way(io_tagWReq_bits_way),
    .io_tagWReq_bits_wtag(io_tagWReq_bits_wtag),
    .io_metaWReq_valid(io_metaWReq_valid),
    .io_metaWReq_bits_set(io_metaWReq_bits_set),
    .io_metaWReq_bits_wayOH(io_metaWReq_bits_wayOH),
    .io_metaWReq_bits_wmeta_valid(io_metaWReq_bits_wmeta_valid),
    .io_metaWReq_bits_wmeta_dirty(io_metaWReq_bits_wmeta_dirty),
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
    .i_tagRead_10(_tagArray_io_r_resp_data_10),
    .i_tagRead_11(_tagArray_io_r_resp_data_11),
    .i_tagRead_12(_tagArray_io_r_resp_data_12),
    .i_tagRead_13(_tagArray_io_r_resp_data_13),
    .i_tagRead_14(_tagArray_io_r_resp_data_14),
    .i_tagRead_15(_tagArray_io_r_resp_data_15),
    .i_metaValid_0(_metaArray_io_r_resp_data_0_valid),
    .i_metaValid_1(_metaArray_io_r_resp_data_1_valid),
    .i_metaValid_2(_metaArray_io_r_resp_data_2_valid),
    .i_metaValid_3(_metaArray_io_r_resp_data_3_valid),
    .i_metaValid_4(_metaArray_io_r_resp_data_4_valid),
    .i_metaValid_5(_metaArray_io_r_resp_data_5_valid),
    .i_metaValid_6(_metaArray_io_r_resp_data_6_valid),
    .i_metaValid_7(_metaArray_io_r_resp_data_7_valid),
    .i_metaValid_8(_metaArray_io_r_resp_data_8_valid),
    .i_metaValid_9(_metaArray_io_r_resp_data_9_valid),
    .i_metaValid_10(_metaArray_io_r_resp_data_10_valid),
    .i_metaValid_11(_metaArray_io_r_resp_data_11_valid),
    .i_metaValid_12(_metaArray_io_r_resp_data_12_valid),
    .i_metaValid_13(_metaArray_io_r_resp_data_13_valid),
    .i_metaValid_14(_metaArray_io_r_resp_data_14_valid),
    .i_metaValid_15(_metaArray_io_r_resp_data_15_valid),
    .i_metaDirty_0(_metaArray_io_r_resp_data_0_dirty),
    .i_metaDirty_1(_metaArray_io_r_resp_data_1_dirty),
    .i_metaDirty_2(_metaArray_io_r_resp_data_2_dirty),
    .i_metaDirty_3(_metaArray_io_r_resp_data_3_dirty),
    .i_metaDirty_4(_metaArray_io_r_resp_data_4_dirty),
    .i_metaDirty_5(_metaArray_io_r_resp_data_5_dirty),
    .i_metaDirty_6(_metaArray_io_r_resp_data_6_dirty),
    .i_metaDirty_7(_metaArray_io_r_resp_data_7_dirty),
    .i_metaDirty_8(_metaArray_io_r_resp_data_8_dirty),
    .i_metaDirty_9(_metaArray_io_r_resp_data_9_dirty),
    .i_metaDirty_10(_metaArray_io_r_resp_data_10_dirty),
    .i_metaDirty_11(_metaArray_io_r_resp_data_11_dirty),
    .i_metaDirty_12(_metaArray_io_r_resp_data_12_dirty),
    .i_metaDirty_13(_metaArray_io_r_resp_data_13_dirty),
    .i_metaDirty_14(_metaArray_io_r_resp_data_14_dirty),
    .i_metaDirty_15(_metaArray_io_r_resp_data_15_dirty),
    .i_replState(_replacer_sram_opt_io_r_resp_data_0),
    .o_ren(o_ren),
    .o_metaWen(o_metaWen),
    .o_metaWset(o_metaWset),
    .o_metaWvalid(o_metaWvalid),
    .o_metaWdirty(o_metaWdirty),
    .o_metaWaymask(o_metaWaymask),
    .o_replWen(o_replWen),
    .o_replWset(o_replWset),
    .o_replWdata(o_replWdata)
  );

  SRAMTemplate_199 tagArray (
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
    .io_r_resp_data_10     (_tagArray_io_r_resp_data_10),
    .io_r_resp_data_11     (_tagArray_io_r_resp_data_11),
    .io_r_resp_data_12     (_tagArray_io_r_resp_data_12),
    .io_r_resp_data_13     (_tagArray_io_r_resp_data_13),
    .io_r_resp_data_14     (_tagArray_io_r_resp_data_14),
    .io_r_resp_data_15     (_tagArray_io_r_resp_data_15),
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
    .io_w_req_bits_data_10 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_11 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_12 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_13 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_14 (io_tagWReq_bits_wtag),
    .io_w_req_bits_data_15 (io_tagWReq_bits_wtag),
    .io_w_req_bits_waymask (16'h1 << io_tagWReq_bits_way)
  );
  SRAMTemplate_200 metaArray (
    .clock                       (clock),
    .io_r_req_ready              (/* unused */),
    .io_r_req_valid              (o_ren),
    .io_r_req_bits_setIdx        (io_read_bits_set),
    .io_r_resp_data_0_valid      (_metaArray_io_r_resp_data_0_valid),
    .io_r_resp_data_0_dirty      (_metaArray_io_r_resp_data_0_dirty),
    .io_r_resp_data_1_valid      (_metaArray_io_r_resp_data_1_valid),
    .io_r_resp_data_1_dirty      (_metaArray_io_r_resp_data_1_dirty),
    .io_r_resp_data_2_valid      (_metaArray_io_r_resp_data_2_valid),
    .io_r_resp_data_2_dirty      (_metaArray_io_r_resp_data_2_dirty),
    .io_r_resp_data_3_valid      (_metaArray_io_r_resp_data_3_valid),
    .io_r_resp_data_3_dirty      (_metaArray_io_r_resp_data_3_dirty),
    .io_r_resp_data_4_valid      (_metaArray_io_r_resp_data_4_valid),
    .io_r_resp_data_4_dirty      (_metaArray_io_r_resp_data_4_dirty),
    .io_r_resp_data_5_valid      (_metaArray_io_r_resp_data_5_valid),
    .io_r_resp_data_5_dirty      (_metaArray_io_r_resp_data_5_dirty),
    .io_r_resp_data_6_valid      (_metaArray_io_r_resp_data_6_valid),
    .io_r_resp_data_6_dirty      (_metaArray_io_r_resp_data_6_dirty),
    .io_r_resp_data_7_valid      (_metaArray_io_r_resp_data_7_valid),
    .io_r_resp_data_7_dirty      (_metaArray_io_r_resp_data_7_dirty),
    .io_r_resp_data_8_valid      (_metaArray_io_r_resp_data_8_valid),
    .io_r_resp_data_8_dirty      (_metaArray_io_r_resp_data_8_dirty),
    .io_r_resp_data_9_valid      (_metaArray_io_r_resp_data_9_valid),
    .io_r_resp_data_9_dirty      (_metaArray_io_r_resp_data_9_dirty),
    .io_r_resp_data_10_valid     (_metaArray_io_r_resp_data_10_valid),
    .io_r_resp_data_10_dirty     (_metaArray_io_r_resp_data_10_dirty),
    .io_r_resp_data_11_valid     (_metaArray_io_r_resp_data_11_valid),
    .io_r_resp_data_11_dirty     (_metaArray_io_r_resp_data_11_dirty),
    .io_r_resp_data_12_valid     (_metaArray_io_r_resp_data_12_valid),
    .io_r_resp_data_12_dirty     (_metaArray_io_r_resp_data_12_dirty),
    .io_r_resp_data_13_valid     (_metaArray_io_r_resp_data_13_valid),
    .io_r_resp_data_13_dirty     (_metaArray_io_r_resp_data_13_dirty),
    .io_r_resp_data_14_valid     (_metaArray_io_r_resp_data_14_valid),
    .io_r_resp_data_14_dirty     (_metaArray_io_r_resp_data_14_dirty),
    .io_r_resp_data_15_valid     (_metaArray_io_r_resp_data_15_valid),
    .io_r_resp_data_15_dirty     (_metaArray_io_r_resp_data_15_dirty),
    .io_w_req_ready              (/* unused */),
    .io_w_req_valid              (o_metaWen),
    .io_w_req_bits_setIdx        (o_metaWset),
    .io_w_req_bits_data_0_valid  (o_metaWvalid),
    .io_w_req_bits_data_0_dirty  (o_metaWdirty),
    .io_w_req_bits_data_1_valid  (o_metaWvalid),
    .io_w_req_bits_data_1_dirty  (o_metaWdirty),
    .io_w_req_bits_data_2_valid  (o_metaWvalid),
    .io_w_req_bits_data_2_dirty  (o_metaWdirty),
    .io_w_req_bits_data_3_valid  (o_metaWvalid),
    .io_w_req_bits_data_3_dirty  (o_metaWdirty),
    .io_w_req_bits_data_4_valid  (o_metaWvalid),
    .io_w_req_bits_data_4_dirty  (o_metaWdirty),
    .io_w_req_bits_data_5_valid  (o_metaWvalid),
    .io_w_req_bits_data_5_dirty  (o_metaWdirty),
    .io_w_req_bits_data_6_valid  (o_metaWvalid),
    .io_w_req_bits_data_6_dirty  (o_metaWdirty),
    .io_w_req_bits_data_7_valid  (o_metaWvalid),
    .io_w_req_bits_data_7_dirty  (o_metaWdirty),
    .io_w_req_bits_data_8_valid  (o_metaWvalid),
    .io_w_req_bits_data_8_dirty  (o_metaWdirty),
    .io_w_req_bits_data_9_valid  (o_metaWvalid),
    .io_w_req_bits_data_9_dirty  (o_metaWdirty),
    .io_w_req_bits_data_10_valid (o_metaWvalid),
    .io_w_req_bits_data_10_dirty (o_metaWdirty),
    .io_w_req_bits_data_11_valid (o_metaWvalid),
    .io_w_req_bits_data_11_dirty (o_metaWdirty),
    .io_w_req_bits_data_12_valid (o_metaWvalid),
    .io_w_req_bits_data_12_dirty (o_metaWdirty),
    .io_w_req_bits_data_13_valid (o_metaWvalid),
    .io_w_req_bits_data_13_dirty (o_metaWdirty),
    .io_w_req_bits_data_14_valid (o_metaWvalid),
    .io_w_req_bits_data_14_dirty (o_metaWdirty),
    .io_w_req_bits_data_15_valid (o_metaWvalid),
    .io_w_req_bits_data_15_dirty (o_metaWdirty),
    .io_w_req_bits_waymask       (o_metaWaymask)
  );
  SRAMTemplate_201 replacer_sram_opt (
    .clock                (clock),
    .reset                (reset),
    .io_r_req_valid       (o_ren),
    .io_r_req_bits_setIdx (io_read_bits_set),
    .io_r_resp_data_0     (_replacer_sram_opt_io_r_resp_data_0),
    .io_w_req_valid       (o_replWen),
    .io_w_req_bits_setIdx (o_replWset),
    .io_w_req_bits_data_0 (o_replWdata)
  );
endmodule
