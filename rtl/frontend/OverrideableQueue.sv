// Four-entry circular overrideable queue.
// Pipeline/control leaf: producer-valid writes are recorded in the next slot;
// reads advance only on output handshake and payload stays stable while stalled.
module OverrideableQueue(
  input         clock,
  input         reset,
  input         io_in_valid,
  input  [4:0] io_in_bits_pht_index,
  input  [12:0] io_in_bits_pht_tag,
  input  [39:0] io_in_bits_region_paddr,
  input  [39:0] io_in_bits_region_vaddr,
  input  [3:0] io_in_bits_region_offset,
  input         io_out_ready,
  output        io_out_valid,
  output [4:0] io_out_bits_pht_index,
  output [12:0] io_out_bits_pht_tag,
  output [39:0] io_out_bits_region_paddr,
  output [39:0] io_out_bits_region_vaddr,
  output [3:0] io_out_bits_region_offset
);
  logic [4:0] entries_pht_index [0:3];
  logic [12:0] entries_pht_tag [0:3];
  logic [39:0] entries_region_paddr [0:3];
  logic [39:0] entries_region_vaddr [0:3];
  logic [3:0] entries_region_offset [0:3];
  logic [3:0] valid_slots;
  logic [1:0] read_ptr;
  logic [1:0] write_ptr;
  wire read_valid = valid_slots[read_ptr];
  wire dequeue = io_out_ready & read_valid;
  assign io_out_valid = read_valid;
  assign io_out_bits_pht_index = entries_pht_index[read_ptr];
  assign io_out_bits_pht_tag = entries_pht_tag[read_ptr];
  assign io_out_bits_region_paddr = entries_region_paddr[read_ptr];
  assign io_out_bits_region_vaddr = entries_region_vaddr[read_ptr];
  assign io_out_bits_region_offset = entries_region_offset[read_ptr];
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      valid_slots <= 4'b0;
      read_ptr <= 2'b0;
      write_ptr <= 2'b0;
    end else begin
      if (io_in_valid) begin
        entries_pht_index[write_ptr] <= io_in_bits_pht_index;
        entries_pht_tag[write_ptr] <= io_in_bits_pht_tag;
        entries_region_paddr[write_ptr] <= io_in_bits_region_paddr;
        entries_region_vaddr[write_ptr] <= io_in_bits_region_vaddr;
        entries_region_offset[write_ptr] <= io_in_bits_region_offset;
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
