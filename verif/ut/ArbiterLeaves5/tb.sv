`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 100000;
  int errors = 0;
  int vectors = 0;

  logic [1:0] valid2;
  logic ready;

  logic [1:0]  h_source0, h_source1;
  logic [2:0]  h_id1;
  logic [37:0] h_gvpn0, h_gvpn1;
  wire h_ready0_g, h_ready1_g, h_valid_g;
  wire [2:0] h_id_g;
  wire [1:0] h_source_g;
  wire [37:0] h_gvpn_g;
  wire h_ready0_i, h_ready1_i, h_valid_i;
  wire [2:0] h_id_i;
  wire [1:0] h_source_i;
  wire [37:0] h_gvpn_i;

  logic [37:0] p_vpn0, p_vpn1;
  logic [1:0] p_s2xlate0, p_s2xlate1;
  wire p_ready0_g, p_ready1_g, p_valid_g, p_chosen_g;
  wire [37:0] p_vpn_g;
  wire [1:0] p_s2xlate_g;
  wire p_ready0_i, p_ready1_i, p_valid_i, p_chosen_i;
  wire [37:0] p_vpn_i;
  wire [1:0] p_s2xlate_i;

  logic [1:0]  l_source0, l_source1;
  logic [2:0]  l_id0, l_id1;
  logic [43:0] l_ppn0, l_ppn1;
  wire l_ready0_g, l_ready1_g, l_valid_g;
  wire [1:0] l_source_g;
  wire [2:0] l_id_g;
  wire [43:0] l_ppn_g;
  wire l_ready0_i, l_ready1_i, l_valid_i;
  wire [1:0] l_source_i;
  wire [2:0] l_id_i;
  wire [43:0] l_ppn_i;

  logic [37:0] m_vpn0, m_vpn1;
  logic [1:0] m_s2xlate0, m_s2xlate1;
  logic [1:0] m_source0, m_source1;
  logic m_is_llptw0;
  wire m_ready0_g, m_ready1_g, m_valid_g;
  wire [37:0] m_vpn_g;
  wire [1:0] m_s2xlate_g, m_source_g;
  wire m_is_llptw_g;
  wire m_ready0_i, m_ready1_i, m_valid_i;
  wire [37:0] m_vpn_i;
  wire [1:0] m_s2xlate_i, m_source_i;
  wire m_is_llptw_i;

  logic [3:0] error_valid;
  logic [3:0] error_bits_valid;
  logic [45:0] error_address [0:3];
  wire error_out_valid_g, error_out_bits_valid_g;
  wire [45:0] error_out_address_g;
  wire error_out_valid_i, error_out_bits_valid_i;
  wire [45:0] error_out_address_i;

  Arbiter2_L2TLBImp_Anon golden_h (
    .io_in_0_ready(h_ready0_g), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_source(h_source0), .io_in_0_bits_gvpn(h_gvpn0),
    .io_in_1_ready(h_ready1_g), .io_in_1_valid(valid2[1]),
    .io_in_1_bits_id(h_id1), .io_in_1_bits_source(h_source1),
    .io_in_1_bits_gvpn(h_gvpn1), .io_out_ready(ready),
    .io_out_valid(h_valid_g), .io_out_bits_id(h_id_g),
    .io_out_bits_source(h_source_g), .io_out_bits_gvpn(h_gvpn_g)
  );
  Arbiter2_L2TLBImp_Anon_xs impl_h (
    .io_in_0_ready(h_ready0_i), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_source(h_source0), .io_in_0_bits_gvpn(h_gvpn0),
    .io_in_1_ready(h_ready1_i), .io_in_1_valid(valid2[1]),
    .io_in_1_bits_id(h_id1), .io_in_1_bits_source(h_source1),
    .io_in_1_bits_gvpn(h_gvpn1), .io_out_ready(ready),
    .io_out_valid(h_valid_i), .io_out_bits_id(h_id_i),
    .io_out_bits_source(h_source_i), .io_out_bits_gvpn(h_gvpn_i)
  );

  Arbiter2_PtwReq golden_p (
    .io_in_0_ready(p_ready0_g), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_vpn(p_vpn0), .io_in_0_bits_s2xlate(p_s2xlate0),
    .io_in_1_ready(p_ready1_g), .io_in_1_valid(valid2[1]),
    .io_in_1_bits_vpn(p_vpn1), .io_in_1_bits_s2xlate(p_s2xlate1),
    .io_out_ready(ready), .io_out_valid(p_valid_g), .io_out_bits_vpn(p_vpn_g),
    .io_out_bits_s2xlate(p_s2xlate_g), .io_chosen(p_chosen_g)
  );
  Arbiter2_PtwReq_xs impl_p (
    .io_in_0_ready(p_ready0_i), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_vpn(p_vpn0), .io_in_0_bits_s2xlate(p_s2xlate0),
    .io_in_1_ready(p_ready1_i), .io_in_1_valid(valid2[1]),
    .io_in_1_bits_vpn(p_vpn1), .io_in_1_bits_s2xlate(p_s2xlate1),
    .io_out_ready(ready), .io_out_valid(p_valid_i), .io_out_bits_vpn(p_vpn_i),
    .io_out_bits_s2xlate(p_s2xlate_i), .io_chosen(p_chosen_i)
  );

  Arbiter2_LLPTW_Anon golden_l (
    .io_in_0_ready(l_ready0_g), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_source(l_source0), .io_in_0_bits_id(l_id0),
    .io_in_0_bits_ppn(l_ppn0), .io_in_1_ready(l_ready1_g),
    .io_in_1_valid(valid2[1]), .io_in_1_bits_source(l_source1),
    .io_in_1_bits_id(l_id1), .io_in_1_bits_ppn(l_ppn1),
    .io_out_ready(ready), .io_out_valid(l_valid_g),
    .io_out_bits_source(l_source_g), .io_out_bits_id(l_id_g),
    .io_out_bits_ppn(l_ppn_g)
  );
  Arbiter2_LLPTW_Anon_xs impl_l (
    .io_in_0_ready(l_ready0_i), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_source(l_source0), .io_in_0_bits_id(l_id0),
    .io_in_0_bits_ppn(l_ppn0), .io_in_1_ready(l_ready1_i),
    .io_in_1_valid(valid2[1]), .io_in_1_bits_source(l_source1),
    .io_in_1_bits_id(l_id1), .io_in_1_bits_ppn(l_ppn1),
    .io_out_ready(ready), .io_out_valid(l_valid_i),
    .io_out_bits_source(l_source_i), .io_out_bits_id(l_id_i),
    .io_out_bits_ppn(l_ppn_i)
  );

  Arbiter2_L2TlbWithHptwIdBundle golden_m (
    .io_in_0_ready(m_ready0_g), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_req_info_vpn(m_vpn0),
    .io_in_0_bits_req_info_s2xlate(m_s2xlate0),
    .io_in_0_bits_req_info_source(m_source0),
    .io_in_0_bits_isLLptw(m_is_llptw0),
    .io_in_1_ready(m_ready1_g), .io_in_1_valid(valid2[1]),
    .io_in_1_bits_req_info_vpn(m_vpn1),
    .io_in_1_bits_req_info_s2xlate(m_s2xlate1),
    .io_in_1_bits_req_info_source(m_source1),
    .io_out_ready(ready), .io_out_valid(m_valid_g),
    .io_out_bits_req_info_vpn(m_vpn_g),
    .io_out_bits_req_info_s2xlate(m_s2xlate_g),
    .io_out_bits_req_info_source(m_source_g),
    .io_out_bits_isLLptw(m_is_llptw_g)
  );
  Arbiter2_L2TlbWithHptwIdBundle_xs impl_m (
    .io_in_0_ready(m_ready0_i), .io_in_0_valid(valid2[0]),
    .io_in_0_bits_req_info_vpn(m_vpn0),
    .io_in_0_bits_req_info_s2xlate(m_s2xlate0),
    .io_in_0_bits_req_info_source(m_source0),
    .io_in_0_bits_isLLptw(m_is_llptw0),
    .io_in_1_ready(m_ready1_i), .io_in_1_valid(valid2[1]),
    .io_in_1_bits_req_info_vpn(m_vpn1),
    .io_in_1_bits_req_info_s2xlate(m_s2xlate1),
    .io_in_1_bits_req_info_source(m_source1),
    .io_out_ready(ready), .io_out_valid(m_valid_i),
    .io_out_bits_req_info_vpn(m_vpn_i),
    .io_out_bits_req_info_s2xlate(m_s2xlate_i),
    .io_out_bits_req_info_source(m_source_i),
    .io_out_bits_isLLptw(m_is_llptw_i)
  );

  Arbiter4_L2CacheErrorInfo golden_e (
    .io_in_0_valid(error_valid[0]), .io_in_0_bits_valid(error_bits_valid[0]),
    .io_in_0_bits_address(error_address[0]), .io_in_1_valid(error_valid[1]),
    .io_in_1_bits_valid(error_bits_valid[1]), .io_in_1_bits_address(error_address[1]),
    .io_in_2_valid(error_valid[2]), .io_in_2_bits_valid(error_bits_valid[2]),
    .io_in_2_bits_address(error_address[2]), .io_in_3_valid(error_valid[3]),
    .io_in_3_bits_valid(error_bits_valid[3]), .io_in_3_bits_address(error_address[3]),
    .io_out_valid(error_out_valid_g), .io_out_bits_valid(error_out_bits_valid_g),
    .io_out_bits_address(error_out_address_g)
  );
  Arbiter4_L2CacheErrorInfo_xs impl_e (
    .io_in_0_valid(error_valid[0]), .io_in_0_bits_valid(error_bits_valid[0]),
    .io_in_0_bits_address(error_address[0]), .io_in_1_valid(error_valid[1]),
    .io_in_1_bits_valid(error_bits_valid[1]), .io_in_1_bits_address(error_address[1]),
    .io_in_2_valid(error_valid[2]), .io_in_2_bits_valid(error_bits_valid[2]),
    .io_in_2_bits_address(error_address[2]), .io_in_3_valid(error_valid[3]),
    .io_in_3_bits_valid(error_bits_valid[3]), .io_in_3_bits_address(error_address[3]),
    .io_out_valid(error_out_valid_i), .io_out_bits_valid(error_out_bits_valid_i),
    .io_out_bits_address(error_out_address_i)
  );

  task automatic check(input logic pass, input string tag);
    if (!pass) begin
      errors++;
      if (errors <= 20)
        $display("mismatch vector=%0d tag=%s valid2=%b ready=%b error_valid=%b",
                 vectors, tag, valid2, ready, error_valid);
    end
  endtask

  task automatic check_outputs;
    logic choose0;
    logic expected_valid;
    logic [1:0] selected_source;
    logic [2:0] selected_id;
    logic [43:0] selected_ppn;
    logic [37:0] selected_vpn;
    logic [1:0] selected_s2xlate;
    logic selected_is_llptw;
    logic expected_error_valid;
    logic expected_error_bits_valid;
    logic [45:0] expected_error_address;
    begin
      #1;
      vectors++;
      choose0 = valid2[0];
      expected_valid = |valid2;

      check(h_ready0_g === ready && h_ready0_i === ready, "H input0 backpressure");
      check(h_ready1_g === (!choose0 && ready) && h_ready1_i === (!choose0 && ready),
            "H input1 backpressure/priority");
      check(h_valid_g === expected_valid && h_valid_i === expected_valid, "H output valid");
      selected_id = choose0 ? 3'd6 : h_id1;
      selected_source = choose0 ? h_source0 : h_source1;
      selected_vpn = choose0 ? h_gvpn0 : h_gvpn1;
      check(h_id_g === selected_id && h_id_i === selected_id, "H selected/fixed ID");
      check(h_source_g === selected_source && h_source_i === selected_source, "H selected source");
      check(h_gvpn_g === selected_vpn && h_gvpn_i === selected_vpn, "H selected gvpn");

      check(p_ready0_g === ready && p_ready0_i === ready, "P input0 backpressure");
      check(p_ready1_g === (!choose0 && ready) && p_ready1_i === (!choose0 && ready),
            "P input1 backpressure/priority");
      check(p_valid_g === expected_valid && p_valid_i === expected_valid, "P output valid");
      selected_vpn = choose0 ? p_vpn0 : p_vpn1;
      selected_s2xlate = choose0 ? p_s2xlate0 : p_s2xlate1;
      check(p_vpn_g === selected_vpn && p_vpn_i === selected_vpn, "P selected vpn");
      check(p_s2xlate_g === selected_s2xlate && p_s2xlate_i === selected_s2xlate,
            "P selected s2xlate");
      check(p_chosen_g === !choose0 && p_chosen_i === !choose0, "P chosen encoding");

      check(l_ready0_g === ready && l_ready0_i === ready, "L input0 backpressure");
      check(l_ready1_g === (!choose0 && ready) && l_ready1_i === (!choose0 && ready),
            "L input1 backpressure/priority");
      check(l_valid_g === expected_valid && l_valid_i === expected_valid, "L output valid");
      selected_source = choose0 ? l_source0 : l_source1;
      selected_id = choose0 ? l_id0 : l_id1;
      selected_ppn = choose0 ? l_ppn0 : l_ppn1;
      check(l_source_g === selected_source && l_source_i === selected_source, "L selected source");
      check(l_id_g === selected_id && l_id_i === selected_id, "L selected ID");
      check(l_ppn_g === selected_ppn && l_ppn_i === selected_ppn, "L selected PPN");

      check(m_ready0_g === ready && m_ready0_i === ready, "M input0 backpressure");
      check(m_ready1_g === (!choose0 && ready) && m_ready1_i === (!choose0 && ready),
            "M input1 backpressure/priority");
      check(m_valid_g === expected_valid && m_valid_i === expected_valid, "M output valid");
      selected_vpn = choose0 ? m_vpn0 : m_vpn1;
      selected_s2xlate = choose0 ? m_s2xlate0 : m_s2xlate1;
      selected_source = choose0 ? m_source0 : m_source1;
      selected_is_llptw = choose0 && m_is_llptw0;
      check(m_vpn_g === selected_vpn && m_vpn_i === selected_vpn, "M selected vpn");
      check(m_s2xlate_g === selected_s2xlate && m_s2xlate_i === selected_s2xlate,
            "M selected s2xlate");
      check(m_source_g === selected_source && m_source_i === selected_source,
            "M selected source");
      check(m_is_llptw_g === selected_is_llptw && m_is_llptw_i === selected_is_llptw,
            "M isLLptw source semantics");

      expected_error_valid = |error_valid;
      if (error_valid[0]) begin
        expected_error_bits_valid = error_bits_valid[0];
        expected_error_address = error_address[0];
      end else if (error_valid[1]) begin
        expected_error_bits_valid = error_bits_valid[1];
        expected_error_address = error_address[1];
      end else if (error_valid[2]) begin
        expected_error_bits_valid = error_bits_valid[2];
        expected_error_address = error_address[2];
      end else begin
        expected_error_bits_valid = error_bits_valid[3];
        expected_error_address = error_address[3];
      end
      check(error_out_valid_g === expected_error_valid &&
            error_out_valid_i === expected_error_valid, "E output valid");
      check(error_out_bits_valid_g === expected_error_bits_valid &&
            error_out_bits_valid_i === expected_error_bits_valid, "E selected payload valid");
      check(error_out_address_g === expected_error_address &&
            error_out_address_i === expected_error_address, "E selected address/priority");

      // Direct golden/implementation checks make failures obvious even if an oracle changes.
      check({h_ready0_g,h_ready1_g,h_valid_g,h_id_g,h_source_g,h_gvpn_g} ===
            {h_ready0_i,h_ready1_i,h_valid_i,h_id_i,h_source_i,h_gvpn_i}, "H golden vs impl");
      check({p_ready0_g,p_ready1_g,p_valid_g,p_vpn_g,p_s2xlate_g,p_chosen_g} ===
            {p_ready0_i,p_ready1_i,p_valid_i,p_vpn_i,p_s2xlate_i,p_chosen_i}, "P golden vs impl");
      check({l_ready0_g,l_ready1_g,l_valid_g,l_source_g,l_id_g,l_ppn_g} ===
            {l_ready0_i,l_ready1_i,l_valid_i,l_source_i,l_id_i,l_ppn_i}, "L golden vs impl");
      check({m_ready0_g,m_ready1_g,m_valid_g,m_vpn_g,m_s2xlate_g,m_source_g,m_is_llptw_g} ===
            {m_ready0_i,m_ready1_i,m_valid_i,m_vpn_i,m_s2xlate_i,m_source_i,m_is_llptw_i},
            "M golden vs impl");
      check({error_out_valid_g,error_out_bits_valid_g,error_out_address_g} ===
            {error_out_valid_i,error_out_bits_valid_i,error_out_address_i}, "E golden vs impl");
    end
  endtask

  task automatic randomize_payloads;
    begin
      h_source0 = $urandom; h_source1 = $urandom; h_id1 = $urandom;
      h_gvpn0 = {$urandom, $urandom}; h_gvpn1 = {$urandom, $urandom};
      p_vpn0 = {$urandom, $urandom}; p_vpn1 = {$urandom, $urandom};
      p_s2xlate0 = $urandom; p_s2xlate1 = $urandom;
      l_source0 = $urandom; l_source1 = $urandom;
      l_id0 = $urandom; l_id1 = $urandom;
      l_ppn0 = {$urandom, $urandom}; l_ppn1 = {$urandom, $urandom};
      m_vpn0 = {$urandom, $urandom}; m_vpn1 = {$urandom, $urandom};
      m_s2xlate0 = $urandom; m_s2xlate1 = $urandom;
      m_source0 = $urandom; m_source1 = $urandom; m_is_llptw0 = $urandom;
      error_bits_valid = $urandom;
      error_address[0] = {$urandom, $urandom};
      error_address[1] = {$urandom, $urandom};
      error_address[2] = {$urandom, $urandom};
      error_address[3] = {$urandom, $urandom};
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    // Exhaust all request-valid combinations, both ready states, every 4-way
    // valid mask, and both values of the payload-valid bits before random stress.
    for (int v = 0; v < 4; v++) begin
      for (int r = 0; r < 2; r++) begin
        for (int ev = 0; ev < 16; ev++) begin
          for (int bv = 0; bv < 2; bv++) begin
            valid2 = v[1:0];
            ready = r[0];
            error_valid = ev[3:0];
            randomize_payloads();
            error_bits_valid = bv ? 4'b1010 : 4'b0101;
            check_outputs();
          end
        end
      end
    end

    repeat (NCYCLES) begin
      randomize_payloads();
      valid2 = $urandom;
      ready = $urandom;
      error_valid = $urandom;
      check_outputs();
    end

    $display("ArbiterLeaves5 UT: vectors=%0d checks=%0d errors=%0d",
             vectors, vectors * 35, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
