// VirtualLevelPermitModule.sv — privilege and virtualization CSR access gate.
// The outputs distinguish illegal-instruction access from virtual-instruction traps.
// Address windows, counteren, envcfg, stateen, and IMSIC checks mirror G1.
module VirtualLevelPermitModule(
  input         io_in_csrAccess_wen,
  input  [11:0] io_in_csrAccess_addr,
  input  [1:0]  io_in_privState_PRVM,
  input         io_in_privState_V,
  input         io_in_status_vtvm,
  input  [5:0]  io_in_status_vgein,
  input  [31:0] io_in_xcounteren_hcounteren,
  input  [31:0] io_in_xcounteren_scounteren,
  input  [63:0] io_in_xenvcfg_henvcfg,
  input         io_in_xstateen_hstateen0_C,
  input         io_in_xstateen_hstateen0_SE0,
  input         io_in_xstateen_hstateen0_ENVCFG,
  input         io_in_xstateen_hstateen0_CSRIND,
  input         io_in_xstateen_hstateen0_AIA,
  input         io_in_xstateen_hstateen0_IMSIC,
  input         io_in_xstateen_hstateen0_CONTEXT,
  input         io_in_xstateen_hstateen1_SE,
  input         io_in_xstateen_hstateen2_SE,
  input         io_in_xstateen_hstateen3_SE,
  input         io_in_xstateen_sstateen0_C,
  input         io_in_aia_hvictlVTI,
  output        io_out_virtualLevelPermit_EX_II,
  output        io_out_virtualLevelPermit_EX_VI
);

  wire        priv_is_supervisor = io_in_privState_PRVM == 2'h1;
  wire        mode_virtual_supervisor = io_in_privState_V & priv_is_supervisor;
  wire        priv_is_machine = &io_in_privState_PRVM;
  wire        mode_machine = priv_is_machine;
  wire        mode_hypervisor_supervisor = ~io_in_privState_V & priv_is_supervisor;
  wire        vgein_is_zero = io_in_status_vgein == 6'h0;
  wire        is_stopei = io_in_csrAccess_addr == 12'h15C;
  wire [31:0] csr_index = {27'h0, io_in_csrAccess_addr[4:0]};
  wire [31:0] hpm_enabled_h = io_in_xcounteren_hcounteren >> csr_index;
  wire        priv_is_user = io_in_privState_PRVM == 2'h0;
  wire        mode_virtual_user = io_in_privState_V & priv_is_user;
  wire [31:0] hpm_enabled_s = io_in_xcounteren_scounteren >> csr_index;
  wire        is_user_custom_csr =
    io_in_csrAccess_addr[11:8] == 4'h8 | io_in_csrAccess_addr[11:6] == 6'h33;
  assign io_out_virtualLevelPermit_EX_II =
    (mode_machine | mode_hypervisor_supervisor) & io_in_csrAccess_addr == 12'h25C
    & (vgein_is_zero | (|(io_in_status_vgein[5:3])));
  assign io_out_virtualLevelPermit_EX_VI =
    mode_virtual_supervisor & io_in_status_vtvm & io_in_csrAccess_addr == 12'h180
    | mode_virtual_supervisor & is_stopei
    & (vgein_is_zero | (|(io_in_status_vgein[5:3]))) | mode_virtual_supervisor
    & io_in_aia_hvictlVTI
    & (io_in_csrAccess_addr == 12'h144 | io_in_csrAccess_addr == 12'h104)
    | mode_virtual_supervisor & io_in_csrAccess_addr == 12'h14D
    & (~(io_in_xcounteren_hcounteren[1]) | ~(io_in_xenvcfg_henvcfg[63])
       | io_in_csrAccess_wen & io_in_aia_hvictlVTI) | io_in_csrAccess_addr > 12'hBFF
    & io_in_csrAccess_addr < 12'hC20
    & (mode_virtual_supervisor & ~(hpm_enabled_h[0]) | mode_virtual_user
       & (~(hpm_enabled_h[0]) | ~(hpm_enabled_s[0])))
    | io_in_csrAccess_addr == 12'h10C & io_in_privState_V & ~io_in_xstateen_hstateen0_SE0
    | io_in_csrAccess_addr == 12'h10D & io_in_privState_V & ~io_in_xstateen_hstateen1_SE
    | io_in_csrAccess_addr == 12'h10E & io_in_privState_V & ~io_in_xstateen_hstateen2_SE
    | io_in_csrAccess_addr == 12'h10F & io_in_privState_V & ~io_in_xstateen_hstateen3_SE
    | io_in_csrAccess_addr == 12'h10A & io_in_privState_V
    & ~io_in_xstateen_hstateen0_ENVCFG | io_in_csrAccess_addr > 12'h14F
    & io_in_csrAccess_addr < 12'h158 & io_in_csrAccess_addr != 12'h154 & io_in_privState_V
    & ~io_in_xstateen_hstateen0_CSRIND | io_in_csrAccess_addr == 12'hDB0
    & io_in_privState_V & ~io_in_xstateen_hstateen0_AIA | is_stopei & io_in_privState_V
    & ~io_in_xstateen_hstateen0_IMSIC | io_in_csrAccess_addr == 12'h5A8
    & io_in_privState_V & ~io_in_xstateen_hstateen0_CONTEXT
    | ((|(io_in_csrAccess_addr[11:10])) & io_in_csrAccess_addr[9:8] == 2'h1
       & (&(io_in_csrAccess_addr[7:6])) | is_user_custom_csr) & io_in_privState_V
    & ~io_in_xstateen_hstateen0_C | is_user_custom_csr & mode_virtual_user
    & io_in_xstateen_hstateen0_C & ~io_in_xstateen_sstateen0_C;
endmodule
