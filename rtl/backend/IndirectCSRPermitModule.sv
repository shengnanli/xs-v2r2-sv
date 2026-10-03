// IndirectCSRPermitModule — privilege checks for the AIA indirect CSR windows.
// The core names the selector classes and privilege cases; the wrapper preserves
// the exact flattened ports emitted by the G1 canonical design.
module xs_IndirectCSRPermitModule_core (
  input  logic [11:0] csr_addr,
  input  logic [1:0]  privilege_mode,
  input  logic        virtual_mode,
  input  logic [63:0] machine_iselect,
  input  logic [63:0] supervisor_iselect,
  input  logic [63:0] virtual_supervisor_iselect,
  input  logic        machine_vien_seie,
  input  logic        machine_stateen_aia,
  input  logic        machine_stateen_imsic,
  input  logic        hypervisor_stateen_imsic,
  output logic        indirect_exception_host,
  output logic        indirect_exception_virtual
);
  localparam logic [11:0] MIREG_ADDR = 12'h351;
  localparam logic [11:0] SIREG_ADDR = 12'h151;
  localparam logic [11:0] VSIREG_ADDR = 12'h251;

  // The selector encoding has three relevant classes.  The open-ended
  // "other" class intentionally includes every value outside AIA and IMSIC.
  logic machine_selector_aia;
  logic machine_selector_imsic;
  logic machine_selector_other;
  logic supervisor_selector_aia;
  logic supervisor_selector_imsic;
  logic supervisor_selector_other;
  logic virtual_selector_aia;
  logic virtual_selector_imsic;
  logic virtual_selector_other;

  assign machine_selector_aia =
    machine_iselect >= 64'h30 && machine_iselect <= 64'h3f;
  assign machine_selector_imsic =
    machine_iselect >= 64'h70 && machine_iselect <= 64'hff;
  assign machine_selector_other =
    !(machine_selector_aia || machine_selector_imsic);

  assign supervisor_selector_aia =
    supervisor_iselect >= 64'h30 && supervisor_iselect <= 64'h3f;
  assign supervisor_selector_imsic =
    supervisor_iselect >= 64'h70 && supervisor_iselect <= 64'hff;
  assign supervisor_selector_other =
    !(supervisor_selector_aia || supervisor_selector_imsic);

  assign virtual_selector_aia =
    virtual_supervisor_iselect >= 64'h30 && virtual_supervisor_iselect <= 64'h3f;
  assign virtual_selector_imsic =
    virtual_supervisor_iselect >= 64'h70 && virtual_supervisor_iselect <= 64'hff;
  assign virtual_selector_other =
    !(virtual_selector_aia || virtual_selector_imsic);

  logic machine_data_access_denied;
  logic machine_indirect_data_access;
  logic supervisor_data_access_denied;
  logic supervisor_indirect_data_access;
  logic virtual_supervisor_data_access;
  logic virtual_supervisor_data_access_virtual;
  logic virtual_supervisor_data_access_host;
  logic sireg2_to_6_address;
  logic vsireg2_to_6_address;
  logic mireg2_to_6_address;
  logic machine_mode;
  logic host_supervisor_mode;

  assign machine_data_access_denied =
    (machine_selector_aia && machine_iselect[0]) || machine_selector_other;
  assign machine_indirect_data_access =
    (csr_addr == MIREG_ADDR) && machine_data_access_denied;

  assign mireg2_to_6_address =
    (csr_addr > MIREG_ADDR) && (csr_addr < 12'h358) &&
    (csr_addr != 12'h354);

  assign host_supervisor_mode =
    !virtual_mode && (privilege_mode == 2'b01);

  // SIREG is checked against the active selector.  In host supervisor mode,
  // AIA/IMSIC accesses are additionally gated by the M-state enables and by
  // mvien.SEIE for the IMSIC class.
  assign supervisor_data_access_denied =
    (!virtual_mode &&
      ((supervisor_selector_aia && supervisor_iselect[0]) ||
       supervisor_selector_other)) ||
    (host_supervisor_mode &&
      ((machine_vien_seie && supervisor_selector_imsic) ||
       (!machine_stateen_aia && supervisor_selector_aia) ||
       (!machine_stateen_imsic && supervisor_selector_imsic))) ||
    (virtual_mode &&
      (virtual_selector_other ||
       (!machine_stateen_imsic && virtual_selector_imsic)));
  assign supervisor_indirect_data_access =
    (csr_addr == SIREG_ADDR) && supervisor_data_access_denied;

  assign virtual_supervisor_data_access_virtual =
    virtual_mode && (virtual_selector_aia || virtual_selector_imsic) &&
    sireg2_to_6_address;
  assign sireg2_to_6_address =
    (csr_addr > SIREG_ADDR) && (csr_addr < 12'h158) &&
    (csr_addr != 12'h154);
  assign virtual_supervisor_data_access_host =
    sireg2_to_6_address && !virtual_supervisor_data_access_virtual;

  assign machine_mode = &privilege_mode;
  assign virtual_supervisor_data_access =
    (!virtual_selector_imsic ||
     (!machine_mode && !machine_stateen_imsic)) &&
    (csr_addr == VSIREG_ADDR);
  assign vsireg2_to_6_address =
    (csr_addr > VSIREG_ADDR) && (csr_addr < 12'h258) &&
    (csr_addr != 12'h254);

  // II covers machine, supervisor, and virtual-supervisor indirect windows;
  // VI is the virtualized SIREG path and the virtual SIREG2..6 AIA/IMSIC path.
  assign indirect_exception_host =
    machine_indirect_data_access ||
    mireg2_to_6_address ||
    supervisor_indirect_data_access ||
    virtual_supervisor_data_access_host ||
    virtual_supervisor_data_access ||
    vsireg2_to_6_address;

  assign indirect_exception_virtual =
    virtual_mode &&
    (virtual_selector_aia ||
     (virtual_selector_imsic && !hypervisor_stateen_imsic)) &&
    (csr_addr == SIREG_ADDR) ||
    virtual_supervisor_data_access_virtual;
endmodule

module IndirectCSRPermitModule (
  input  logic [11:0] io_in_csrAccess_addr,
  input  logic [1:0]  io_in_privState_PRVM,
  input  logic        io_in_privState_V,
  input  logic [63:0] io_in_aia_miselect,
  input  logic [63:0] io_in_aia_siselect,
  input  logic [63:0] io_in_aia_vsiselect,
  input  logic        io_in_aia_mvienSEIE,
  input  logic        io_in_xstateen_mstateen0_AIA,
  input  logic        io_in_xstateen_mstateen0_IMSIC,
  input  logic        io_in_xstateen_hstateen0_IMSIC,
  output logic        io_out_indirectCSR_EX_II,
  output logic        io_out_indirectCSR_EX_VI
);
  xs_IndirectCSRPermitModule_core u_core (
    .csr_addr(io_in_csrAccess_addr),
    .privilege_mode(io_in_privState_PRVM),
    .virtual_mode(io_in_privState_V),
    .machine_iselect(io_in_aia_miselect),
    .supervisor_iselect(io_in_aia_siselect),
    .virtual_supervisor_iselect(io_in_aia_vsiselect),
    .machine_vien_seie(io_in_aia_mvienSEIE),
    .machine_stateen_aia(io_in_xstateen_mstateen0_AIA),
    .machine_stateen_imsic(io_in_xstateen_mstateen0_IMSIC),
    .hypervisor_stateen_imsic(io_in_xstateen_hstateen0_IMSIC),
    .indirect_exception_host(io_out_indirectCSR_EX_II),
    .indirect_exception_virtual(io_out_indirectCSR_EX_VI)
  );
endmodule
