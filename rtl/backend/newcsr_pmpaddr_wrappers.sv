// 自动生成: scripts/gen_newcsr_pmpaddr.py —— 勿手改
// NewCSR Pmpaddr family thin wrappers (N=0..15).
// Each wrapper instantiates the readable primitive xs_pmpaddr (see
// rtl/backend/newcsr_pmpaddr.sv) and binds the golden per-instance read-mux
// source port name addrRData_{N} to the primitive's generic addr_rdata port.
// FM-verified against golden PmpaddrNModule.sv in signoff-strict mode.

module Pmpaddr0Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_0
);
  xs_pmpaddr #(.IDX(0)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_0)
  );
endmodule

module Pmpaddr1Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_1
);
  xs_pmpaddr #(.IDX(1)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_1)
  );
endmodule

module Pmpaddr2Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_2
);
  xs_pmpaddr #(.IDX(2)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_2)
  );
endmodule

module Pmpaddr3Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_3
);
  xs_pmpaddr #(.IDX(3)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_3)
  );
endmodule

module Pmpaddr4Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_4
);
  xs_pmpaddr #(.IDX(4)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_4)
  );
endmodule

module Pmpaddr5Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_5
);
  xs_pmpaddr #(.IDX(5)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_5)
  );
endmodule

module Pmpaddr6Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_6
);
  xs_pmpaddr #(.IDX(6)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_6)
  );
endmodule

module Pmpaddr7Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_7
);
  xs_pmpaddr #(.IDX(7)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_7)
  );
endmodule

module Pmpaddr8Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_8
);
  xs_pmpaddr #(.IDX(8)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_8)
  );
endmodule

module Pmpaddr9Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_9
);
  xs_pmpaddr #(.IDX(9)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_9)
  );
endmodule

module Pmpaddr10Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_10
);
  xs_pmpaddr #(.IDX(10)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_10)
  );
endmodule

module Pmpaddr11Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_11
);
  xs_pmpaddr #(.IDX(11)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_11)
  );
endmodule

module Pmpaddr12Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_12
);
  xs_pmpaddr #(.IDX(12)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_12)
  );
endmodule

module Pmpaddr13Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_13
);
  xs_pmpaddr #(.IDX(13)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_13)
  );
endmodule

module Pmpaddr14Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_14
);
  xs_pmpaddr #(.IDX(14)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_14)
  );
endmodule

module Pmpaddr15Module(
  input         clock,
  input         reset,
  input         w_wen,
  input  [63:0] w_wdata,
  output [63:0] rdata,
  output [45:0] regOut_ADDRESS,
  input  [63:0] addrRData_15
);
  xs_pmpaddr #(.IDX(15)) u_core (
    .clock          (clock),
    .reset          (reset),
    .w_wen          (w_wen),
    .w_wdata        (w_wdata),
    .rdata          (rdata),
    .regOut_ADDRESS (regOut_ADDRESS),
    .addr_rdata     (addrRData_15)
  );
endmodule
