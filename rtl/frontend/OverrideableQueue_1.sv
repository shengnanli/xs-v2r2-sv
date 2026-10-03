// Four-entry circular overrideable queue.
// Pipeline/control leaf: producer-valid writes are recorded in the next slot;
// reads advance only on output handshake and payload stays stable while stalled.
module OverrideableQueue_1(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [4:0] io_in_bits_pht_index,
  input  [12:0] io_in_bits_pht_tag,
  input  [15:0] io_in_bits_region_bits,
  input  [15:0] io_in_bits_region_bit_single,
  input  [3:0] io_in_bits_region_offset,
  input  [3:0] io_in_bits_access_cnt,
  input         io_in_bits_decr_mode,
  input         io_in_bits_single_update,
  input         io_in_bits_has_been_signal_updated,
  input         io_out_ready,
  output        io_out_valid,
  output [4:0] io_out_bits_pht_index,
  output [12:0] io_out_bits_pht_tag,
  output [15:0] io_out_bits_region_bits,
  output [15:0] io_out_bits_region_bit_single,
  output [3:0] io_out_bits_region_offset,
  output [3:0] io_out_bits_access_cnt,
  output        io_out_bits_decr_mode,
  output        io_out_bits_single_update,
  output        io_out_bits_has_been_signal_updated
);
  logic [4:0] entries_pht_index [0:3];
  logic [12:0] entries_pht_tag [0:3];
  logic [15:0] entries_region_bits [0:3];
  logic [15:0] entries_region_bit_single [0:3];
  logic [3:0] entries_region_offset [0:3];
  logic [3:0] entries_access_cnt [0:3];
  logic        entries_decr_mode [0:3];
  logic        entries_single_update [0:3];
  logic        entries_has_been_signal_updated [0:3];
  logic [3:0] valid_slots;
  logic [1:0] read_ptr;
  logic [1:0] write_ptr;
  wire read_valid = valid_slots[read_ptr];
  wire dequeue = io_out_ready & read_valid;
  assign io_out_valid = read_valid;
  assign io_out_bits_pht_index = entries_pht_index[read_ptr];
  assign io_out_bits_pht_tag = entries_pht_tag[read_ptr];
  assign io_out_bits_region_bits = entries_region_bits[read_ptr];
  assign io_out_bits_region_bit_single = entries_region_bit_single[read_ptr];
  assign io_out_bits_region_offset = entries_region_offset[read_ptr];
  assign io_out_bits_access_cnt = entries_access_cnt[read_ptr];
  assign io_out_bits_decr_mode = entries_decr_mode[read_ptr];
  assign io_out_bits_single_update = entries_single_update[read_ptr];
  assign io_out_bits_has_been_signal_updated = entries_has_been_signal_updated[read_ptr];
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_slots <= 4'b0;
      read_ptr <= 2'b0;
      write_ptr <= 2'b0;
    end else begin
      if (io_in_valid) begin
        entries_pht_index[write_ptr] <= io_in_bits_pht_index;
        entries_pht_tag[write_ptr] <= io_in_bits_pht_tag;
        entries_region_bits[write_ptr] <= io_in_bits_region_bits;
        entries_region_bit_single[write_ptr] <= io_in_bits_region_bit_single;
        entries_region_offset[write_ptr] <= io_in_bits_region_offset;
        entries_access_cnt[write_ptr] <= io_in_bits_access_cnt;
        entries_decr_mode[write_ptr] <= io_in_bits_decr_mode;
        entries_single_update[write_ptr] <= io_in_bits_single_update;
        entries_has_been_signal_updated[write_ptr] <= io_in_bits_has_been_signal_updated;
        valid_slots[write_ptr] <= 1'b1;
        write_ptr <= write_ptr + 2'd1;
      end
      if (dequeue) begin
        valid_slots[read_ptr] <= io_in_valid && (write_ptr == read_ptr);
        read_ptr <= read_ptr + 2'd1;
      end
    end
  end
endmodule
