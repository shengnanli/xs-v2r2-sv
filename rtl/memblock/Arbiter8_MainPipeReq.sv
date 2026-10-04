// Arbiter8_MainPipeReq.sv —— ProbeQueue 的 8 选 1 probe 请求仲裁器
//                            （xs_FixedPriorityArbiter_core 家族的一个变体）
//
// 位置：DCache ProbeQueue 内部 pipe_req_arb（Probe.scala:137
//   `Module(new Arbiter(new MainPipeReq, cfg.nProbeEntries))`）。8 个 ProbeEntry 各自想把自己的
//   probe 送进主流水，本仲裁器按固定优先级（下标小的赢）挑一个；ProbeQueue 再把胜者打一拍送 MainPipe。
// 语义：chisel3 Arbiter，lowest-index-wins、无锁定、纯组合（见 rtl/frontend/xs_FixedPriorityArbiter_core.sv）：
//   in_ready[k] = 前面没人请求 && out_ready；一路都没请求时出口给最后一路（第 7 路）的载荷。
//
// 本变体的参数与规模（按 G1 golden 现读）：
//   入口数 NUM_IN = 8；载荷 WIDTH = 107 位 = MainPipeReq 在本仲裁器上保留下来的 5 个 probe 字段
//   （probe_param 2 + probe_need_data 1 + vaddr 50 + addr 48 + id 6）。8 路字段集合完全相同，
//   没有常量字段要填（ProbeEntry 写成常量的 probe=1/miss=0 等字段已被 firtool 推到下游，不经过这里）。
//   golden 243 行 / 63 端口；纯组合，无寄存器、无子模块。

module Arbiter8_MainPipeReq (
  output logic        io_in_0_ready,
  input  logic        io_in_0_valid,
  input  logic [1:0]  io_in_0_bits_probe_param,
  input  logic        io_in_0_bits_probe_need_data,
  input  logic [49:0] io_in_0_bits_vaddr,
  input  logic [47:0] io_in_0_bits_addr,
  input  logic [5:0]  io_in_0_bits_id,
  output logic        io_in_1_ready,
  input  logic        io_in_1_valid,
  input  logic [1:0]  io_in_1_bits_probe_param,
  input  logic        io_in_1_bits_probe_need_data,
  input  logic [49:0] io_in_1_bits_vaddr,
  input  logic [47:0] io_in_1_bits_addr,
  input  logic [5:0]  io_in_1_bits_id,
  output logic        io_in_2_ready,
  input  logic        io_in_2_valid,
  input  logic [1:0]  io_in_2_bits_probe_param,
  input  logic        io_in_2_bits_probe_need_data,
  input  logic [49:0] io_in_2_bits_vaddr,
  input  logic [47:0] io_in_2_bits_addr,
  input  logic [5:0]  io_in_2_bits_id,
  output logic        io_in_3_ready,
  input  logic        io_in_3_valid,
  input  logic [1:0]  io_in_3_bits_probe_param,
  input  logic        io_in_3_bits_probe_need_data,
  input  logic [49:0] io_in_3_bits_vaddr,
  input  logic [47:0] io_in_3_bits_addr,
  input  logic [5:0]  io_in_3_bits_id,
  output logic        io_in_4_ready,
  input  logic        io_in_4_valid,
  input  logic [1:0]  io_in_4_bits_probe_param,
  input  logic        io_in_4_bits_probe_need_data,
  input  logic [49:0] io_in_4_bits_vaddr,
  input  logic [47:0] io_in_4_bits_addr,
  input  logic [5:0]  io_in_4_bits_id,
  output logic        io_in_5_ready,
  input  logic        io_in_5_valid,
  input  logic [1:0]  io_in_5_bits_probe_param,
  input  logic        io_in_5_bits_probe_need_data,
  input  logic [49:0] io_in_5_bits_vaddr,
  input  logic [47:0] io_in_5_bits_addr,
  input  logic [5:0]  io_in_5_bits_id,
  output logic        io_in_6_ready,
  input  logic        io_in_6_valid,
  input  logic [1:0]  io_in_6_bits_probe_param,
  input  logic        io_in_6_bits_probe_need_data,
  input  logic [49:0] io_in_6_bits_vaddr,
  input  logic [47:0] io_in_6_bits_addr,
  input  logic [5:0]  io_in_6_bits_id,
  output logic        io_in_7_ready,
  input  logic        io_in_7_valid,
  input  logic [1:0]  io_in_7_bits_probe_param,
  input  logic        io_in_7_bits_probe_need_data,
  input  logic [49:0] io_in_7_bits_vaddr,
  input  logic [47:0] io_in_7_bits_addr,
  input  logic [5:0]  io_in_7_bits_id,
  input  logic        io_out_ready,
  output logic        io_out_valid,
  output logic [1:0]  io_out_bits_probe_param,
  output logic        io_out_bits_probe_need_data,
  output logic [49:0] io_out_bits_vaddr,
  output logic [47:0] io_out_bits_addr,
  output logic [5:0]  io_out_bits_id
);

  // MainPipeReq 在本仲裁器上保留下来的字段（顺序 = golden 输出端口顺序）
  typedef struct packed {
    logic [1:0]  probe_param;      // TileLink probe 目标权限
    logic        probe_need_data;  // probe 是否要回数据
    logic [49:0] vaddr;            // 虚地址（取 DCache set 下标用）
    logic [47:0] addr;             // 物理地址
    logic [5:0]  id;               // ProbeEntry 编号（零扩展到 6 位）
  } probe_req_t;

  localparam int unsigned NUM_IN = 8;
  localparam int unsigned WIDTH  = $bits(probe_req_t);   // 107

  probe_req_t [NUM_IN-1:0] lane;     // lane[k] = 第 k 路载荷
  logic       [NUM_IN-1:0] lane_valid;
  logic       [NUM_IN-1:0] lane_ready;

  assign lane[0] = {io_in_0_bits_probe_param, io_in_0_bits_probe_need_data,
                    io_in_0_bits_vaddr, io_in_0_bits_addr, io_in_0_bits_id};
  assign lane[1] = {io_in_1_bits_probe_param, io_in_1_bits_probe_need_data,
                    io_in_1_bits_vaddr, io_in_1_bits_addr, io_in_1_bits_id};
  assign lane[2] = {io_in_2_bits_probe_param, io_in_2_bits_probe_need_data,
                    io_in_2_bits_vaddr, io_in_2_bits_addr, io_in_2_bits_id};
  assign lane[3] = {io_in_3_bits_probe_param, io_in_3_bits_probe_need_data,
                    io_in_3_bits_vaddr, io_in_3_bits_addr, io_in_3_bits_id};
  assign lane[4] = {io_in_4_bits_probe_param, io_in_4_bits_probe_need_data,
                    io_in_4_bits_vaddr, io_in_4_bits_addr, io_in_4_bits_id};
  assign lane[5] = {io_in_5_bits_probe_param, io_in_5_bits_probe_need_data,
                    io_in_5_bits_vaddr, io_in_5_bits_addr, io_in_5_bits_id};
  assign lane[6] = {io_in_6_bits_probe_param, io_in_6_bits_probe_need_data,
                    io_in_6_bits_vaddr, io_in_6_bits_addr, io_in_6_bits_id};
  assign lane[7] = {io_in_7_bits_probe_param, io_in_7_bits_probe_need_data,
                    io_in_7_bits_vaddr, io_in_7_bits_addr, io_in_7_bits_id};

  assign lane_valid = {io_in_7_valid, io_in_6_valid, io_in_5_valid, io_in_4_valid,
                       io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};

  assign {io_in_7_ready, io_in_6_ready, io_in_5_ready, io_in_4_ready,
          io_in_3_ready, io_in_2_ready, io_in_1_ready, io_in_0_ready} = lane_ready;

  // ---- 核的约定：位 NUM_IN-1（最高段）= 第 0 路（优先级最高）----
  logic [NUM_IN-1:0]       core_valid, core_ready;
  logic [NUM_IN*WIDTH-1:0] core_bits;
  probe_req_t              out_req;

  for (genvar k = 0; k < NUM_IN; k++) begin : g_lane
    assign core_valid[NUM_IN-1-k]                  = lane_valid[k];
    assign core_bits[(NUM_IN-1-k)*WIDTH +: WIDTH]  = lane[k];
    assign lane_ready[k]                           = core_ready[NUM_IN-1-k];
  end

  xs_FixedPriorityArbiter_core #(
    .WIDTH            (WIDTH),
    .NUM_IN           (NUM_IN),
    .PORT_BITS_OUT    ($bits({io_out_bits_probe_param, io_out_bits_probe_need_data,
                              io_out_bits_vaddr, io_out_bits_addr, io_out_bits_id})),
    .PORT_BITS_LAST_IN($bits({io_in_7_bits_probe_param, io_in_7_bits_probe_need_data,
                              io_in_7_bits_vaddr, io_in_7_bits_addr, io_in_7_bits_id})),
    .GOLDEN_PORTS     (63),   // 8 路 × (ready+valid+5 字段) + out_ready/out_valid + 5 字段
    .GOLDEN_BITS_PORTS(45)    // 8×5 入口字段 + 5 出口字段
  ) u_core (
    .in_valid (core_valid),
    .in_ready (core_ready),
    .in_bits  (core_bits),
    .out_ready(io_out_ready),
    .out_valid(io_out_valid),
    .out_bits (out_req)
  );

  assign io_out_bits_probe_param     = out_req.probe_param;
  assign io_out_bits_probe_need_data = out_req.probe_need_data;
  assign io_out_bits_vaddr           = out_req.vaddr;
  assign io_out_bits_addr            = out_req.addr;
  assign io_out_bits_id              = out_req.id;

endmodule
