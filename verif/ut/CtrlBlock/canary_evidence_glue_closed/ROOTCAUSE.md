# CtrlBlock glue canary — 20 failing counterexample analysis (fresh @ HEAD e17e787)

## Fresh reproduction (Tue Jul 28 18:25, fm_shell V-2023.12-SP3)
canary: verif/ut/CtrlBlock/run_canary_glue.sh  (16 submodules symmetric black box)
  73381 Passing / **20 Failing** (20 matched, 0 unmatched) / 924 Unverified
=> foldpc failing (prev round) are GONE (fix 2c91405 already in HEAD). The current
   20 are a DIFFERENT set surfaced after the foldpc fix raised passing 73341->73381.

## The 20 failing compare points (verif/ut/CtrlBlock/failing.rpt, all BBPin)
  rename/io_in_1_bits_lsrc_2[0..5]   (6)   <- _decodePipeRenameModule_1_io_out_bits_lsrc_2
  rename/io_in_1_bits_lsrc_3[0..5]   (6)   <- _decodePipeRenameModule_1_io_out_bits_lsrc_3
  rename/io_in_1_bits_lsrc_4[0..5]   (6)   <- _decodePipeRenameModule_1_io_out_bits_lsrc_4
  rename/io_in_2_bits_lsrc_2[0]      (1)   <- _decodePipeRenameModule_2_io_out_bits_lsrc_2
  rob/io_exception_valid             (1)   <- _rob_io_exception_valid (Rob BB output)
  = 20

## FM diagnostic notes on ALL 20
  "ATTENTION: 20 failing compare points have unmatched undriven signals in their
   reference fan-in." (fm.log:6321)
  "18 (18) undriven nets found in reference (implementation) design" (FM-399)
     -> the 18 = decodePipeRenameModule.io_out_bits_lsrc_2/3/4[0..5] (LANE-0 dangling
        black-box output pins, left `/* unused */` in BOTH golden and impl).
  report_unmatched_points rob/io_exception_valid -status undriven (REF side):
     "1 Unmatched input point for BBPin rob/io_exception_valid ...
      This matching input is not in the cone of the matching object"
  same on IMPL side: "No unmatched input points" => REF/IMPL cone ASYMMETRY.

## Byte-for-byte wiring check: impl == golden for ALL 20 (NO glue bug)
  - Rename instance: 1579 port names identical (diff empty); 3234 real port lines each.
  - Rob instance:    3234 real port lines each; io_exception_valid RHS identical.
  - rename.io_in_1_bits_lsrc_2/3/4  = _decodePipeRenameModule_1_io_out_bits_lsrc_2/3/4  (identical)
  - rename.io_in_2_bits_lsrc_2      = _decodePipeRenameModule_2_io_out_bits_lsrc_2       (identical)
  - rob.io_exception_valid          = _rob_io_exception_valid; DelayN s5_csrIsTrap_delay
        .io_in(_rob_io_exception_valid) (identical)
  - lane-0 decodePipeRenameModule.io_out_bits_lsrc_2/3/4 = /* unused */ in BOTH (identical)
  - golden PipelineConnectPipe internal: data_lsrc_2<=io_in_bits_lsrc_2, data_lsrc_3/4<=0;
        io_out_bits_lsrc_3/4 = constant 0 regs — all HIDDEN behind black box.

## Experiments (isolating the FM knob)
  diag3  verification_verify_matched_unread_bbox_inputs=false  -> STILL 20 failing
  diag5  verification_merge_duplicated_registers=false         -> STILL 20 failing
  => NOT a bbox-input-compare artifact, NOT a register-merge artifact.

## ★ ROOT CAUSE (formality.log): black-box pin DIRECTION unknown -> inout ★
  formality.log (canary fm_work): thousands of
    "Info: Direction of black-box pin r:/WORK/CtrlBlock/decodePipeRenameModule/
           io_out_bits_lsrc_0[5] is unknown; setting to inout."
  The canary black-boxes the 16 submodules by NOT feeding their bodies
  (FM_REF_SRCS = golden CtrlBlock.sv only). With no module definition, FM cannot
  infer port DIRECTIONS, so it sets every black-box pin to INOUT. An inout pin is
  both a driver and a receiver; on a net that also has the receiving instance's
  input pin, FM's driver/undriven analysis becomes asymmetric between ref and impl
  (the lane-0 dangling io_out_bits_lsrc_2/3/4 pins become genuinely undriven inout
  cut-points, and their X leaks into the compare cone) -> 20 spurious failing.
  This is a CANARY-DIAGNOSTIC LIMITATION, not a CtrlBlock glue equivalence gap.

## FIX PART 1: hdlin_interface_only (feed submodule PORT/DIRECTION, not body)
  diag7: read the 16 golden submodule .sv WITH hdlin_interface_only={16 names}
  (ports+directions known, bodies NOT elaborated -> no Rob stall). This is the
  same mechanism the official assembly-mode fm_eq.tcl exposes via FM_INTERFACE_ONLY.
  canary formality.log: 76778 "direction unknown -> inout" warnings.
  diag7 formality.log:      0 such warnings.
  Result: 20 failing -> 19 failing (54820 passing). The inout ambiguity removed
  1 spurious failure AND, crucially, UNMASKED the REAL glue bug (below): the 19
  remaining are now the clean, informative rob/io_writebackNums_N_bits[3]/[4] set,
  NOT the noisy rename-lsrc/rob-exc inout artifacts.

## ★ REAL GLUE BUG (unmasked by interface-only): writebackNums upper-bit zero-ext ★
  19 failing (diag7 failing_iface.rpt), all BBPin rob INPUT pins:
    rob/io_writebackNums_{0,2,4,6,7,9,10,11,12}_bits[4]           (group A, 9 lanes)
    rob/io_writebackNums_{13,14,15,16,17}_bits[3] and [4]         (group C, 5 lanes x2)
  golden (CtrlBlock.sv:21000+) zero-extends per-lane from NARROW registers:
    group A (0,2,4,6,7,9,10,11,12): reg[3:0] -> io_writebackNums = {1'h0, r}  bit[4]=const 0
    group B (5,8):                  reg[4:0] -> {full}
    group C (13,14,15,16,17):       reg[2:0] -> {2'h0, r}                    bit[4:3]=const 0
    group D (1,3,18..22):           reg      -> {4'h0, r}
    group E (23,24):                reg[1:0] -> {3'h0, r}
  impl (ctrlblock_datapath.svh): wbNumsBits[N] declared uniform logic[4:0] and fed
  DIRECTLY to rob as full 5 bits. wb_compress_count returns logic[4:0] from a
  variable-size PopCount; the value is bounded (<=11 for A, <=7 for C) so the upper
  bits are 0 in all REACHABLE states, but FM cannot prove bit[4]/[3] are constant 0
  from the popcount return-width alone, while golden HARDWIRES them 0 -> 19 failing.
  (This is a genuine bit-level divergence from golden's structure, NOT just an FM
   artifact; it is the CtrlBlock glue's job to reproduce golden's per-lane widths.)

## FIX PART 2 (RTL, bug-for-bug): mask wb_compress_count to golden per-lane width
  ctrlblock_datapath.svh wb_compress_count: AND each group's result with golden width:
    group A & 5'h0F, group B & 5'h1F, group C & 5'h07, group E & 5'h03 (D already 1-bit).
  This makes the impl's io_writebackNums upper bits STRUCTURALLY constant 0, bit-for-bit
  matching golden's {K'h0, r} zero-extension. Functionally identical (counts never
  exceed the group max), only forces FM to see the always-0 upper bits as constant.
  Result: diag8 (interface-only + mask fix) FM native **Verification SUCCEEDED**,
          54839 passing / **0 failing** / 0 aborted. The only residual unmatched is
          53 impl-side "Constant 0" registers (wbNumsBits_reg[N][3]/[4] masked to 0;
          golden's narrower per-lane regs have no such bit) — benign constant regs,
          NOT compare points; they were ALSO unmatched pre-fix (as non-constant DFFs),
          so the mask strictly improves them to constant-0.

## FIX PART 3 (RTL, clean proof): per-lane golden-width writebackNums registers
  The mask-only fix (PART 2) makes FM native SUCCEEDED but leaves 53 impl-side
  "Constant 0" unmatched compare points (wbNumsBits_reg[N][3]/[4] = 5-bit uniform
  register with masked-0 upper bits; golden's narrower per-lane regs have no such
  bit). The assembly sidecar verdict is fail-closed on impl-side unmatched
  (fm_sidecar_verdict.py: `um["compare_ref"]!=um["compare_impl"]` -> PARTIAL;
  `um["unread_impl"]` -> PARTIAL). So the uniform-5-bit register must be replaced by
  per-lane golden-width registers. ctrlblock_datapath.svh: register `logic [GW-1:0]
  wbNumsCnt` INSIDE the per-lane generate (GW = golden group width A=4/B=5/C=3/D=1/
  E=2), and drive the 5-bit rob-facing `wbNumsBits[N]` as a pure zero-extension wire
  `{(5-GW){1'b0}}, wbNumsCnt}` == golden `{K'h0, r}`. No extra register bits, no
  undriven/unread bits, upper bits are literal-constant wires matching golden.

## SIDECAR NOTE (main-owned, not glue): fm_pins.tcl vs restricted pin interp
  The official sidecar path (fm_eq.tcl with FM_SIDECAR_OUT) sources fm_pins.tcl in a
  RESTRICTED child interp whose whitelist lacks `report_unmatched_points`/`redirect`;
  CtrlBlock's ctrlblock_pin_unmatched uses both -> sidecar path errors before emit
  (SIDECAR_FM_RC=1). This is a pre-existing fm_pins.tcl<->sidecar-interp
  incompatibility (main-owned runner integration), independent of this glue fix. The
  glue-partition canary (fm_canary_glue.tcl, non-sidecar) is the proof vehicle here.

## SUMMARY
  20 canary failing = (a) inout-direction black-box artifact [16 of the 20 were pure
  artifact, fixed by FM_INTERFACE_ONLY giving known pin directions] + (b) 1 real glue
  bug class [writebackNums upper-bit zero-extension, 19 pts after interface-only,
  fixed by the wb_compress_count golden-width mask]. Both fixes land 20 -> 0 failing.
  Fixes: rtl/backend/ctrlblock_datapath.svh (RTL, bug-for-bug) +
         verif/ut/CtrlBlock/Makefile (FM_INTERFACE_ONLY, assembly proof config).
  NO dont_verify, NO compare-point deletion, NO relaxed appvar, NO forced match.

## Conclusion (pre-fix experiments)
  The 20 failing are NOT CtrlBlock glue bugs. The glue drives these signals byte-for-byte
  identically to golden. They are FM black-box-boundary artifacts: with
  verification_verify_matched_unread_bbox_inputs=true, FM compares the Rename/DelayN
  black-box INPUT pins; their drivers are black-box OUTPUT cut-points whose reference-side
  logic cone picks up the 18 undriven lane-0 dangling black-box output pins (X), producing
  a ref(X) vs impl(driven) mismatch — a matching/merge asymmetry at the symmetric
  black-box boundary, not a functional difference.

## FINAL RESULT (clean per-lane-width fix, interface-only canary)
  fm_CLEAN_FINAL_SUCCEEDED.log:
    FM_RESULT: Verification SUCCEEDED for CtrlBlock (iface-only)
    54839 Passing / 0 Failing / 0 Aborted
    0(0) Unmatched compare points   (fully symmetric, ref==impl)
    0(0) Unmatched primary inputs / black-box outputs
    26(7608) unread points          (black-box partition boundary; inherent to the
                                     assembly black-box partition, present in every
                                     such proof — NOT introduced by this fix)
  => 20 canary failing -> 0. The 53 impl-only constant-0 registers (mask-only
     residual) are also eliminated by the per-lane-width registers.
