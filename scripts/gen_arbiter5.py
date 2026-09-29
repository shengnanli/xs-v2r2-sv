#!/usr/bin/env python3
"""Generate five readable fixed-priority arbiter leaves."""

import argparse
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


SOURCES = {
    ROOT / "rtl/mmu/Arbiter2_L2TLBImp_Anon.sv": '''// HPTW request arbitration at the L2 TLB boundary.
// Input 0 has fixed priority; ready follows that priority and downstream readiness.
// Input 0 has no ID field, so the architectural HPTW ID (6) is inserted.
module Arbiter2_L2TLBImp_Anon (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [1:0]  io_in_0_bits_source,
  input  logic [37:0] io_in_0_bits_gvpn,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [2:0]  io_in_1_bits_id,
  input  logic [1:0]  io_in_1_bits_source,
  input  logic [37:0] io_in_1_bits_gvpn,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [2:0]  io_out_bits_id,
  output logic [1:0]  io_out_bits_source,
  output logic [37:0] io_out_bits_gvpn
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;

    if (select_input_0) begin
      io_out_bits_id = 3'd6;
      io_out_bits_source = io_in_0_bits_source;
      io_out_bits_gvpn = io_in_0_bits_gvpn;
    end else begin
      io_out_bits_id = io_in_1_bits_id;
      io_out_bits_source = io_in_1_bits_source;
      io_out_bits_gvpn = io_in_1_bits_gvpn;
    end
  end
endmodule
''',
    ROOT / "rtl/mmu/Arbiter2_PtwReq.sv": '''// PTW request arbitration at the L2 TLB input.
// Input 0 has fixed priority and alone receives ready when both inputs are valid.
// The chosen output uses the original Chisel convention: 0 for input 0, 1 otherwise.
module Arbiter2_PtwReq (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [37:0] io_in_0_bits_vpn,
  input  logic [1:0]  io_in_0_bits_s2xlate,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [37:0] io_in_1_bits_vpn,
  input  logic [1:0]  io_in_1_bits_s2xlate,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [37:0] io_out_bits_vpn,
  output logic [1:0]  io_out_bits_s2xlate,
  output logic        io_chosen
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;
    io_chosen = !select_input_0;

    if (select_input_0) begin
      io_out_bits_vpn = io_in_0_bits_vpn;
      io_out_bits_s2xlate = io_in_0_bits_s2xlate;
    end else begin
      io_out_bits_vpn = io_in_1_bits_vpn;
      io_out_bits_s2xlate = io_in_1_bits_s2xlate;
    end
  end
endmodule
''',
    ROOT / "rtl/mmu/Arbiter2_LLPTW_Anon.sv": '''// HPTW request arbitration inside the last-level page-table walker.
// Input 0 has fixed priority; input 1 receives ready only when input 0 is invalid.
// The selected source, ID, and PPN remain combinational through the arbiter.
module Arbiter2_LLPTW_Anon (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [1:0]  io_in_0_bits_source,
  input  logic [2:0]  io_in_0_bits_id,
  input  logic [43:0] io_in_0_bits_ppn,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [1:0]  io_in_1_bits_source,
  input  logic [2:0]  io_in_1_bits_id,
  input  logic [43:0] io_in_1_bits_ppn,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [1:0]  io_out_bits_source,
  output logic [2:0]  io_out_bits_id,
  output logic [43:0] io_out_bits_ppn
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;

    if (select_input_0) begin
      io_out_bits_source = io_in_0_bits_source;
      io_out_bits_id = io_in_0_bits_id;
      io_out_bits_ppn = io_in_0_bits_ppn;
    end else begin
      io_out_bits_source = io_in_1_bits_source;
      io_out_bits_id = io_in_1_bits_id;
      io_out_bits_ppn = io_in_1_bits_ppn;
    end
  end
endmodule
''',
    ROOT / "rtl/mmu/Arbiter2_L2TlbWithHptwIdBundle.sv": '''// Merge the LLPTW and normal request streams before the L2 TLB miss queue.
// Input 0 has fixed priority and controls ready propagation while it is valid.
// Only input 0 carries isLLptw; selecting input 1 therefore clears that field.
module Arbiter2_L2TlbWithHptwIdBundle (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [37:0] io_in_0_bits_req_info_vpn,
  input  logic [1:0]  io_in_0_bits_req_info_s2xlate,
  input  logic [1:0]  io_in_0_bits_req_info_source,
  input  logic        io_in_0_bits_isLLptw,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [37:0] io_in_1_bits_req_info_vpn,
  input  logic [1:0]  io_in_1_bits_req_info_s2xlate,
  input  logic [1:0]  io_in_1_bits_req_info_source,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [37:0] io_out_bits_req_info_vpn,
  output logic [1:0]  io_out_bits_req_info_s2xlate,
  output logic [1:0]  io_out_bits_req_info_source,
  output logic        io_out_bits_isLLptw
);
  logic select_input_0;

  always_comb begin
    select_input_0 = io_in_0_valid;

    io_in_0_ready = io_out_ready;
    io_in_1_ready = !select_input_0 && io_out_ready;
    io_out_valid = io_in_0_valid || io_in_1_valid;

    if (select_input_0) begin
      io_out_bits_req_info_vpn = io_in_0_bits_req_info_vpn;
      io_out_bits_req_info_s2xlate = io_in_0_bits_req_info_s2xlate;
      io_out_bits_req_info_source = io_in_0_bits_req_info_source;
      io_out_bits_isLLptw = io_in_0_bits_isLLptw;
    end else begin
      io_out_bits_req_info_vpn = io_in_1_bits_req_info_vpn;
      io_out_bits_req_info_s2xlate = io_in_1_bits_req_info_s2xlate;
      io_out_bits_req_info_source = io_in_1_bits_req_info_source;
      io_out_bits_isLLptw = 1'b0;
    end
  end
endmodule
''',
    ROOT / "rtl/l2/Arbiter4_L2CacheErrorInfo.sv": '''// Combine four L2 cache error-reporting lanes into one report.
// Lower input number has fixed priority, with payload selected from the winning lane.
// This observation path has no ready signal, so selection depends only on valid.
module Arbiter4_L2CacheErrorInfo (
  input  logic        io_in_0_valid,
  input  logic        io_in_0_bits_valid,
  input  logic [45:0] io_in_0_bits_address,
  input  logic        io_in_1_valid,
  input  logic        io_in_1_bits_valid,
  input  logic [45:0] io_in_1_bits_address,
  input  logic        io_in_2_valid,
  input  logic        io_in_2_bits_valid,
  input  logic [45:0] io_in_2_bits_address,
  input  logic        io_in_3_valid,
  input  logic        io_in_3_bits_valid,
  input  logic [45:0] io_in_3_bits_address,
  output logic        io_out_valid,
  output logic        io_out_bits_valid,
  output logic [45:0] io_out_bits_address
);
  always_comb begin
    io_out_valid = io_in_0_valid || io_in_1_valid ||
                   io_in_2_valid || io_in_3_valid;

    if (io_in_0_valid) begin
      io_out_bits_valid = io_in_0_bits_valid;
      io_out_bits_address = io_in_0_bits_address;
    end else if (io_in_1_valid) begin
      io_out_bits_valid = io_in_1_bits_valid;
      io_out_bits_address = io_in_1_bits_address;
    end else if (io_in_2_valid) begin
      io_out_bits_valid = io_in_2_bits_valid;
      io_out_bits_address = io_in_2_bits_address;
    end else begin
      io_out_bits_valid = io_in_3_bits_valid;
      io_out_bits_address = io_in_3_bits_address;
    end
  end
endmodule
''',
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    drift = []
    for path, source in SOURCES.items():
      if args.check:
        if not path.exists() or path.read_text() != source:
          drift.append(str(path.relative_to(ROOT)))
      else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source)

    if drift:
      print("gen_arbiter5 --check: DRIFT: " + " ".join(drift))
      raise SystemExit(1)
    if args.check:
      print("gen_arbiter5 --check: OK (5 files)")


if __name__ == "__main__":
    main()
