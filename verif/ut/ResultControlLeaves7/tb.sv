`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;
  int oracle_checks = 0;

  logic [2:0] alu_func;
  logic [63:0] add_res, shift_res, misc_res, compare_res, word_res, cond_res;
  wire [63:0] alu_g, alu_i;
  AluResSel g_alu (alu_func, add_res, shift_res, misc_res, compare_res,
                   word_res, cond_res, alu_g);
  AluResSel_xs i_alu (alu_func, add_res, shift_res, misc_res, compare_res,
                      word_res, cond_res, alu_i);

  logic [3:0] shift_func;
  logic [63:0] sll, srl, sra, rol, ror_v, bclr, bset, binv, bext;
  wire [63:0] shift_g, shift_i;
  ShiftResultSelect g_shift (shift_func, sll, srl, sra, rol, ror_v,
                             bclr, bset, binv, bext, shift_g);
  ShiftResultSelect_xs i_shift (shift_func, sll, srl, sra, rol, ror_v,
                                bclr, bset, binv, bext, shift_i);

  logic [8:0] word_func;
  logic [31:0] sllw, srlw, sraw, rolw, rorw, addw, subw;
  wire [63:0] word_g, word_i;
  WordResultSelect g_word (word_func, sllw, srlw, sraw, rolw, rorw,
                           addw, subw, word_g);
  WordResultSelect_xs i_word (word_func, sllw, srlw, sraw, rolw, rorw,
                              addw, subw, word_i);

  logic [5:0] misc_func;
  logic [63:0] and_v, or_v, xor_v, orcb, orh48, sextb, packh, sexth;
  logic [63:0] packw, revb, rev8, pack, misc_src;
  wire [63:0] misc_g, misc_i;
  MiscResultSelect g_misc (misc_func, and_v, or_v, xor_v, orcb, orh48,
                           sextb, packh, sexth, packw, revb, rev8, pack,
                           misc_src, misc_g);
  MiscResultSelect_xs i_misc (misc_func, and_v, or_v, xor_v, orcb, orh48,
                              sextb, packh, sexth, packw, revb, rev8, pack,
                              misc_src, misc_i);

  logic [63:0] jump_src, pc;
  logic [32:0] imm;
  logic [4:0] next_pc_offset;
  logic [8:0] jump_func;
  wire [63:0] jump_result_g, jump_target_g, jump_result_i, jump_target_i;
  wire jump_auipc_g, jump_auipc_i;
  JumpDataModule g_jump (jump_src, pc, imm, next_pc_offset, jump_func,
                         jump_result_g, jump_target_g, jump_auipc_g);
  JumpDataModule_xs i_jump (jump_src, pc, imm, next_pc_offset, jump_func,
                            jump_result_i, jump_target_i, jump_auipc_i);

  logic [63:0] branch_lhs, branch_rhs;
  logic [8:0] branch_func;
  logic predicted_taken;
  wire taken_g, mispredict_g, taken_i, mispredict_i;
  BranchModule g_branch (branch_lhs, branch_rhs, branch_func,
                         predicted_taken, taken_g, mispredict_g);
  BranchModule_xs i_branch (branch_lhs, branch_rhs, branch_func,
                            predicted_taken, taken_i, mispredict_i);

  logic [5:0] hart_id;
  CommitIDModule g_commit (hart_id);
  CommitIDModule_xs i_commit (hart_id);

  function automatic [63:0] random64;
    random64 = {$urandom, $urandom};
  endfunction

  function automatic [63:0] oracle_alu;
    case (alu_func)
      3'd0: oracle_alu = shift_res;
      3'd1: oracle_alu = word_res;
      3'd2: oracle_alu = add_res;
      3'd3: oracle_alu = compare_res;
      3'd7: oracle_alu = cond_res;
      default: oracle_alu = misc_res;
    endcase
  endfunction

  function automatic [63:0] oracle_shift;
    if (shift_func[3])
      oracle_shift = shift_func[1] ? ror_v : rol;
    else begin
      case (shift_func[2:0])
        3'd0, 3'd1: oracle_shift = sll;
        3'd2: oracle_shift = bclr;
        3'd3: oracle_shift = bset;
        3'd4: oracle_shift = binv;
        3'd5: oracle_shift = srl;
        3'd6: oracle_shift = bext;
        default: oracle_shift = sra;
      endcase
    end
  endfunction

  function automatic [63:0] oracle_word;
    logic [31:0] value;
    begin
      if (!word_func[3])
        value = (word_func[2:0] == 3'b010) ? subw : addw;
      else if (word_func[2])
        value = word_func[0] ? rorw : rolw;
      else if (word_func[1])
        value = sraw;
      else
        value = word_func[0] ? srlw : sllw;
      oracle_word = {{32{value[31]}}, value};
    end
  endfunction

  function automatic [63:0] oracle_misc;
    logic [63:0] logical;
    begin
      case (misc_func[2:1])
        2'd0: logical = and_v;
        2'd1: logical = or_v;
        2'd2: logical = xor_v;
        default: logical = orcb;
      endcase
      if (misc_func[5])
        oracle_misc = {48'b0, logical[15:1] & {15{misc_func[0]}}, logical[0]};
      else if (misc_func[4] && misc_func[3]) begin
        case (misc_func[1:0])
          2'd0: oracle_misc = {31'b0, misc_src[31:0], 1'b0};
          2'd1: oracle_misc = {30'b0, misc_src[31:0], 2'b0};
          2'd2: oracle_misc = {29'b0, misc_src[31:0], 3'b0};
          default: oracle_misc = {56'b0, misc_src[15:8]};
        endcase
      end else if (misc_func[4]) begin
        case (misc_func[1:0])
          2'd0: oracle_misc = revb;
          2'd1: oracle_misc = rev8;
          2'd2: oracle_misc = pack;
          default: oracle_misc = orh48;
        endcase
      end else if (misc_func[3]) begin
        case (misc_func[1:0])
          2'd0: oracle_misc = sextb;
          2'd1: oracle_misc = packh;
          2'd2: oracle_misc = sexth;
          default: oracle_misc = packw;
        endcase
      end else
        oracle_misc = logical;
    end
  endfunction

  task automatic oracle_jump(
    output logic [63:0] expected_result,
    output logic [63:0] expected_target,
    output logic expected_auipc
  );
    logic [63:0] extended_imm;
    logic [63:0] raw_target;
    begin
      extended_imm = {{31{imm[32]}}, imm};
      raw_target = (jump_func[0] ? jump_src : pc) + extended_imm;
      expected_auipc = jump_func[1];
      expected_result = expected_auipc
        ? raw_target : pc + {58'b0, next_pc_offset, 1'b0};
      expected_target = {raw_target[63:1], 1'b0};
    end
  endtask

  function automatic logic oracle_taken;
    logic condition;
    begin
      case (branch_func[3:1])
        3'd0: condition = (branch_lhs == branch_rhs);
        3'd2: condition = ($signed(branch_lhs) < $signed(branch_rhs));
        3'd4: condition = (branch_lhs < branch_rhs);
        default: condition = 1'b0;
      endcase
      oracle_taken = condition ^ branch_func[0];
    end
  endfunction

  task automatic check_value(input logic good, input string label);
    begin
      oracle_checks++;
      if (!good) begin
        errors++;
        if (errors <= 12)
          $display("mismatch vector=%0d check=%s", vectors, label);
      end
    end
  endtask

  task automatic compare_now;
    logic [63:0] expected_jump_result, expected_jump_target;
    logic expected_jump_auipc, expected_taken;
    begin
      #1;
      vectors++;
      oracle_jump(expected_jump_result, expected_jump_target, expected_jump_auipc);
      expected_taken = oracle_taken();

      check_value(alu_g === oracle_alu(), "golden AluResSel vs oracle");
      check_value(alu_i === oracle_alu(), "impl AluResSel vs oracle");
      check_value(shift_g === oracle_shift(), "golden ShiftResultSelect vs oracle");
      check_value(shift_i === oracle_shift(), "impl ShiftResultSelect vs oracle");
      check_value(word_g === oracle_word(), "golden WordResultSelect vs oracle");
      check_value(word_i === oracle_word(), "impl WordResultSelect vs oracle");
      check_value(misc_g === oracle_misc(), "golden MiscResultSelect vs oracle");
      check_value(misc_i === oracle_misc(), "impl MiscResultSelect vs oracle");
      check_value({jump_result_g, jump_target_g, jump_auipc_g} ===
                  {expected_jump_result, expected_jump_target, expected_jump_auipc},
                  "golden JumpDataModule vs oracle");
      check_value({jump_result_i, jump_target_i, jump_auipc_i} ===
                  {expected_jump_result, expected_jump_target, expected_jump_auipc},
                  "impl JumpDataModule vs oracle");
      check_value({taken_g, mispredict_g} ===
                  {expected_taken, predicted_taken ^ expected_taken},
                  "golden BranchModule vs oracle");
      check_value({taken_i, mispredict_i} ===
                  {expected_taken, predicted_taken ^ expected_taken},
                  "impl BranchModule vs oracle");
      check_value({g_commit.printCommitIDMod.hartID,
                   g_commit.printCommitIDMod.commitID,
                   g_commit.printCommitIDMod.dirty} ===
                  {hart_id, 40'hB36A1A2A57, 1'b1},
                  "golden CommitIDModule vs oracle");
      check_value({i_commit.printCommitIDMod.hartID,
                   i_commit.printCommitIDMod.commitID,
                   i_commit.printCommitIDMod.dirty} ===
                  {hart_id, 40'hB36A1A2A57, 1'b1},
                  "impl CommitIDModule vs oracle");
    end
  endtask

  task automatic randomize_inputs;
    begin
      alu_func = $urandom;
      add_res = random64(); shift_res = random64(); misc_res = random64();
      compare_res = random64(); word_res = random64(); cond_res = random64();
      shift_func = $urandom;
      sll = random64(); srl = random64(); sra = random64();
      rol = random64(); ror_v = random64(); bclr = random64();
      bset = random64(); binv = random64(); bext = random64();
      word_func = $urandom;
      sllw = $urandom; srlw = $urandom; sraw = $urandom;
      rolw = $urandom; rorw = $urandom; addw = $urandom; subw = $urandom;
      misc_func = $urandom;
      and_v = random64(); or_v = random64(); xor_v = random64();
      orcb = random64(); orh48 = random64(); sextb = random64();
      packh = random64(); sexth = random64(); packw = random64();
      revb = random64(); rev8 = random64(); pack = random64(); misc_src = random64();
      jump_src = random64(); pc = random64(); imm = {$urandom, $urandom};
      next_pc_offset = $urandom; jump_func = $urandom;
      branch_lhs = random64(); branch_rhs = random64();
      branch_func = $urandom; predicted_taken = $urandom; hart_id = $urandom;
    end
  endtask

  task automatic fill_distinct_candidates;
    begin
      add_res = 64'h0101_0101_0101_0101;
      shift_res = 64'h0202_0202_0202_0202;
      misc_res = 64'h0303_0303_0303_0303;
      compare_res = 64'h0404_0404_0404_0404;
      word_res = 64'h0505_0505_0505_0505;
      cond_res = 64'h0606_0606_0606_0606;
      sll = 64'h10; srl = 64'h11; sra = 64'h12; rol = 64'h13;
      ror_v = 64'h14; bclr = 64'h15; bset = 64'h16;
      binv = 64'h17; bext = 64'h18;
      sllw = 32'h8000_0010; srlw = 32'h0000_0011;
      sraw = 32'h8000_0012; rolw = 32'h0000_0013;
      rorw = 32'h8000_0014; addw = 32'h0000_0015; subw = 32'h8000_0016;
      and_v = 64'h20; or_v = 64'h21; xor_v = 64'h22; orcb = 64'h23;
      orh48 = 64'h24; sextb = 64'h25; packh = 64'h26; sexth = 64'h27;
      packw = 64'h28; revb = 64'h29; rev8 = 64'h2a; pack = 64'h2b;
      misc_src = 64'hFEDC_BA98_8765_4321;
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    // All-zero and all-one controls/data catch masks and default paths.
    {alu_func, add_res, shift_res, misc_res, compare_res, word_res, cond_res,
     shift_func, sll, srl, sra, rol, ror_v, bclr, bset, binv, bext,
     word_func, sllw, srlw, sraw, rolw, rorw, addw, subw,
     misc_func, and_v, or_v, xor_v, orcb, orh48, sextb, packh, sexth,
     packw, revb, rev8, pack, misc_src, jump_src, pc, imm,
     next_pc_offset, jump_func, branch_lhs, branch_rhs, branch_func,
     predicted_taken, hart_id} = '0;
    compare_now();
    {alu_func, add_res, shift_res, misc_res, compare_res, word_res, cond_res,
     shift_func, sll, srl, sra, rol, ror_v, bclr, bset, binv, bext,
     word_func, sllw, srlw, sraw, rolw, rorw, addw, subw,
     misc_func, and_v, or_v, xor_v, orcb, orh48, sextb, packh, sexth,
     packw, revb, rev8, pack, misc_src, jump_src, pc, imm,
     next_pc_offset, jump_func, branch_lhs, branch_rhs, branch_func,
     predicted_taken, hart_id} = '1;
    compare_now();

    // Exhaust every control encoding while every candidate carries a unique tag.
    fill_distinct_candidates();
    jump_src = 64'h8000_0000_0000_0000;
    pc = 64'h7fff_ffff_ffff_ffff;
    imm = 33'h1_0000_0000;
    next_pc_offset = 5'h1f;
    branch_lhs = 64'h8000_0000_0000_0000;
    branch_rhs = 64'h7fff_ffff_ffff_ffff;
    for (int control = 0; control < 512; control++) begin
      alu_func = control;
      shift_func = control;
      word_func = control;
      misc_func = control;
      jump_func = control;
      branch_func = control;
      predicted_taken = control[8];
      hart_id = control;
      compare_now();
    end

    // Signed and unsigned comparison boundaries, both predicted outcomes.
    for (int lhs_case = 0; lhs_case < 5; lhs_case++) begin
      case (lhs_case)
        0: branch_lhs = 64'h0;
        1: branch_lhs = 64'h1;
        2: branch_lhs = 64'h7fff_ffff_ffff_ffff;
        3: branch_lhs = 64'h8000_0000_0000_0000;
        default: branch_lhs = 64'hffff_ffff_ffff_ffff;
      endcase
      for (int rhs_case = 0; rhs_case < 5; rhs_case++) begin
        case (rhs_case)
          0: branch_rhs = 64'h0;
          1: branch_rhs = 64'h1;
          2: branch_rhs = 64'h7fff_ffff_ffff_ffff;
          3: branch_rhs = 64'h8000_0000_0000_0000;
          default: branch_rhs = 64'hffff_ffff_ffff_ffff;
        endcase
        for (int branch_control = 0; branch_control < 16; branch_control++) begin
          branch_func = branch_control;
          predicted_taken = branch_control[0];
          compare_now();
        end
      end
    end

    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end

    $display("ResultControlLeaves7 UT: vectors=%0d oracle_checks=%0d errors=%0d",
             vectors, oracle_checks, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule
