// TLFIFOFixer 双例化逐拍比对 tb —— golden TLFIFOFixer vs 可读 TLFIFOFixer_xs。
//
// 为什么激励不能纯随机: stall 是本模块唯一的输出效应, 它要求"同一 master 组 (source[13:7])
// 有请求在飞, 且本拍 A 的地址译出的 FIFO 域与该组上次的域不同"。14 位随机 source +
// 49 位随机 address 几乎永远凑不出这个条件 —— 那样的 errors=0 是没有意义的。
// 故激励做三件事:
//   1. source 绝大多数落在少数几个组里 (组内 128 个 id 随机), 保证同组反复命中;
//   2. address 从"域边界地址表"里取 (每个 FIFO 域的首/尾页 + 洞 + 随机偏移), 保证域切换;
//   3. D 通道的 source 有一半从"最近真的发射过的 A source"里取, 保证 flight 真能被清掉。
// tb 自带覆盖计数 (stall/域切换/多拍消息/ReleaseAck/越界 source), 任何一项为 0 即判 FAILED,
// 免得"跑了 20 万拍其实什么都没验"。
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  bit reset;
  int errors = 0;
  int checks = 0;
  // 覆盖计数 (见文件头): 全部必须 > 0
  int cov_stall = 0, cov_domain_switch = 0, cov_multibeat_a = 0;
  int cov_multibeat_d = 0, cov_release_ack = 0, cov_src_oob = 0, cov_a_fire = 0, cov_d_clear = 0;
  int cov_set_clear_race = 0;   // 同拍对同一 source 既置又清 (flight 优先级唯一的观察窗)
  always #5 clock = ~clock;

  logic auto_in_a_valid;
  logic [3:0] auto_in_a_bits_opcode;
  logic [2:0] auto_in_a_bits_size;
  logic [13:0] auto_in_a_bits_source;
  logic [48:0] auto_in_a_bits_address;
  logic auto_in_a_bits_user_amba_prot_bufferable;
  logic auto_in_a_bits_user_amba_prot_modifiable;
  logic auto_in_a_bits_user_amba_prot_readalloc;
  logic auto_in_a_bits_user_amba_prot_writealloc;
  logic auto_in_a_bits_user_amba_prot_privileged;
  logic auto_in_a_bits_user_amba_prot_secure;
  logic auto_in_a_bits_user_amba_prot_fetch;
  logic [7:0] auto_in_a_bits_mask;
  logic [63:0] auto_in_a_bits_data;
  logic auto_in_d_ready;
  logic auto_out_a_ready;
  logic auto_out_d_valid;
  logic [3:0] auto_out_d_bits_opcode;
  logic [2:0] auto_out_d_bits_size;
  logic [13:0] auto_out_d_bits_source;
  logic auto_out_d_bits_denied;
  logic [63:0] auto_out_d_bits_data;
  logic auto_out_d_bits_corrupt;
  wire g_auto_in_a_ready;
  wire i_auto_in_a_ready;
  wire g_auto_in_d_valid;
  wire i_auto_in_d_valid;
  wire [3:0] g_auto_in_d_bits_opcode;
  wire [3:0] i_auto_in_d_bits_opcode;
  wire [2:0] g_auto_in_d_bits_size;
  wire [2:0] i_auto_in_d_bits_size;
  wire [13:0] g_auto_in_d_bits_source;
  wire [13:0] i_auto_in_d_bits_source;
  wire g_auto_in_d_bits_denied;
  wire i_auto_in_d_bits_denied;
  wire [63:0] g_auto_in_d_bits_data;
  wire [63:0] i_auto_in_d_bits_data;
  wire g_auto_in_d_bits_corrupt;
  wire i_auto_in_d_bits_corrupt;
  wire g_auto_out_a_valid;
  wire i_auto_out_a_valid;
  wire [3:0] g_auto_out_a_bits_opcode;
  wire [3:0] i_auto_out_a_bits_opcode;
  wire [2:0] g_auto_out_a_bits_size;
  wire [2:0] i_auto_out_a_bits_size;
  wire [13:0] g_auto_out_a_bits_source;
  wire [13:0] i_auto_out_a_bits_source;
  wire [48:0] g_auto_out_a_bits_address;
  wire [48:0] i_auto_out_a_bits_address;
  wire g_auto_out_a_bits_user_amba_prot_bufferable;
  wire i_auto_out_a_bits_user_amba_prot_bufferable;
  wire g_auto_out_a_bits_user_amba_prot_modifiable;
  wire i_auto_out_a_bits_user_amba_prot_modifiable;
  wire g_auto_out_a_bits_user_amba_prot_readalloc;
  wire i_auto_out_a_bits_user_amba_prot_readalloc;
  wire g_auto_out_a_bits_user_amba_prot_writealloc;
  wire i_auto_out_a_bits_user_amba_prot_writealloc;
  wire g_auto_out_a_bits_user_amba_prot_privileged;
  wire i_auto_out_a_bits_user_amba_prot_privileged;
  wire g_auto_out_a_bits_user_amba_prot_secure;
  wire i_auto_out_a_bits_user_amba_prot_secure;
  wire g_auto_out_a_bits_user_amba_prot_fetch;
  wire i_auto_out_a_bits_user_amba_prot_fetch;
  wire [7:0] g_auto_out_a_bits_mask;
  wire [7:0] i_auto_out_a_bits_mask;
  wire [63:0] g_auto_out_a_bits_data;
  wire [63:0] i_auto_out_a_bits_data;
  wire g_auto_out_d_ready;
  wire i_auto_out_d_ready;

  TLFIFOFixer u_g (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(g_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_amba_prot_bufferable(auto_in_a_bits_user_amba_prot_bufferable),
    .auto_in_a_bits_user_amba_prot_modifiable(auto_in_a_bits_user_amba_prot_modifiable),
    .auto_in_a_bits_user_amba_prot_readalloc(auto_in_a_bits_user_amba_prot_readalloc),
    .auto_in_a_bits_user_amba_prot_writealloc(auto_in_a_bits_user_amba_prot_writealloc),
    .auto_in_a_bits_user_amba_prot_privileged(auto_in_a_bits_user_amba_prot_privileged),
    .auto_in_a_bits_user_amba_prot_secure(auto_in_a_bits_user_amba_prot_secure),
    .auto_in_a_bits_user_amba_prot_fetch(auto_in_a_bits_user_amba_prot_fetch),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(g_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(g_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_auto_in_d_bits_source),
    .auto_in_d_bits_denied(g_auto_in_d_bits_denied),
    .auto_in_d_bits_data(g_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(g_auto_in_d_bits_corrupt),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(g_auto_out_a_valid),
    .auto_out_a_bits_opcode(g_auto_out_a_bits_opcode),
    .auto_out_a_bits_size(g_auto_out_a_bits_size),
    .auto_out_a_bits_source(g_auto_out_a_bits_source),
    .auto_out_a_bits_address(g_auto_out_a_bits_address),
    .auto_out_a_bits_user_amba_prot_bufferable(g_auto_out_a_bits_user_amba_prot_bufferable),
    .auto_out_a_bits_user_amba_prot_modifiable(g_auto_out_a_bits_user_amba_prot_modifiable),
    .auto_out_a_bits_user_amba_prot_readalloc(g_auto_out_a_bits_user_amba_prot_readalloc),
    .auto_out_a_bits_user_amba_prot_writealloc(g_auto_out_a_bits_user_amba_prot_writealloc),
    .auto_out_a_bits_user_amba_prot_privileged(g_auto_out_a_bits_user_amba_prot_privileged),
    .auto_out_a_bits_user_amba_prot_secure(g_auto_out_a_bits_user_amba_prot_secure),
    .auto_out_a_bits_user_amba_prot_fetch(g_auto_out_a_bits_user_amba_prot_fetch),
    .auto_out_a_bits_mask(g_auto_out_a_bits_mask),
    .auto_out_a_bits_data(g_auto_out_a_bits_data),
    .auto_out_d_ready(g_auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt)
  );

  TLFIFOFixer_xs u_i (
    .clock(clock),
    .reset(reset),
    .auto_in_a_ready(i_auto_in_a_ready),
    .auto_in_a_valid(auto_in_a_valid),
    .auto_in_a_bits_opcode(auto_in_a_bits_opcode),
    .auto_in_a_bits_size(auto_in_a_bits_size),
    .auto_in_a_bits_source(auto_in_a_bits_source),
    .auto_in_a_bits_address(auto_in_a_bits_address),
    .auto_in_a_bits_user_amba_prot_bufferable(auto_in_a_bits_user_amba_prot_bufferable),
    .auto_in_a_bits_user_amba_prot_modifiable(auto_in_a_bits_user_amba_prot_modifiable),
    .auto_in_a_bits_user_amba_prot_readalloc(auto_in_a_bits_user_amba_prot_readalloc),
    .auto_in_a_bits_user_amba_prot_writealloc(auto_in_a_bits_user_amba_prot_writealloc),
    .auto_in_a_bits_user_amba_prot_privileged(auto_in_a_bits_user_amba_prot_privileged),
    .auto_in_a_bits_user_amba_prot_secure(auto_in_a_bits_user_amba_prot_secure),
    .auto_in_a_bits_user_amba_prot_fetch(auto_in_a_bits_user_amba_prot_fetch),
    .auto_in_a_bits_mask(auto_in_a_bits_mask),
    .auto_in_a_bits_data(auto_in_a_bits_data),
    .auto_in_d_ready(auto_in_d_ready),
    .auto_in_d_valid(i_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_auto_in_d_bits_opcode),
    .auto_in_d_bits_size(i_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_auto_in_d_bits_source),
    .auto_in_d_bits_denied(i_auto_in_d_bits_denied),
    .auto_in_d_bits_data(i_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(i_auto_in_d_bits_corrupt),
    .auto_out_a_ready(auto_out_a_ready),
    .auto_out_a_valid(i_auto_out_a_valid),
    .auto_out_a_bits_opcode(i_auto_out_a_bits_opcode),
    .auto_out_a_bits_size(i_auto_out_a_bits_size),
    .auto_out_a_bits_source(i_auto_out_a_bits_source),
    .auto_out_a_bits_address(i_auto_out_a_bits_address),
    .auto_out_a_bits_user_amba_prot_bufferable(i_auto_out_a_bits_user_amba_prot_bufferable),
    .auto_out_a_bits_user_amba_prot_modifiable(i_auto_out_a_bits_user_amba_prot_modifiable),
    .auto_out_a_bits_user_amba_prot_readalloc(i_auto_out_a_bits_user_amba_prot_readalloc),
    .auto_out_a_bits_user_amba_prot_writealloc(i_auto_out_a_bits_user_amba_prot_writealloc),
    .auto_out_a_bits_user_amba_prot_privileged(i_auto_out_a_bits_user_amba_prot_privileged),
    .auto_out_a_bits_user_amba_prot_secure(i_auto_out_a_bits_user_amba_prot_secure),
    .auto_out_a_bits_user_amba_prot_fetch(i_auto_out_a_bits_user_amba_prot_fetch),
    .auto_out_a_bits_mask(i_auto_out_a_bits_mask),
    .auto_out_a_bits_data(i_auto_out_a_bits_data),
    .auto_out_d_ready(i_auto_out_d_ready),
    .auto_out_d_valid(auto_out_d_valid),
    .auto_out_d_bits_opcode(auto_out_d_bits_opcode),
    .auto_out_d_bits_size(auto_out_d_bits_size),
    .auto_out_d_bits_source(auto_out_d_bits_source),
    .auto_out_d_bits_denied(auto_out_d_bits_denied),
    .auto_out_d_bits_data(auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(auto_out_d_bits_corrupt)
  );


  // ---- 地址池: 每个 FIFO 域的代表地址 + 洞 + 边界 ----------------------------
  // 与 rtl/uncore/TLFIFOFixer.sv 里 REGION_MAP 一一对应, 外加两条边界外地址。
  localparam int NADDR = 24;
  logic [48:0] addr_pool [NADDR] = '{
    49'h1_0000_0000_0000,  // addr[48]=1          → 域 1
    49'h1_8765_4321_0000,  // addr[48]=1 (高位随意)→ 域 1
    49'h0_0000_3110_0000,  // APLIC M domain      → 域 10
    49'h0_0000_3110_7000,  // APLIC M domain 末页  → 域 10
    49'h0_0000_3110_8000,  // APLIC 保留洞         → 域 0 (无域)
    49'h0_0000_3111_F000,  // APLIC 保留洞末页     → 域 0
    49'h0_0000_3112_0000,  // APLIC S domain      → 域 10
    49'h0_0000_3113_F000,  // APLIC 保留洞         → 域 0
    49'h0_0000_3800_0000,  // TIMER/CLINT         → 域 7
    49'h0_0000_3800_F000,  // TIMER 末页          → 域 7
    49'h0_0000_3801_0000,  // BEU                 → 域 0 (无域)
    49'h0_0000_3802_0000,  // DebugModule 页0     → 域 4
    49'h0_0000_3802_1000,  // DebugModule 页1     → 域 9
    49'h0_0000_3802_2000,  // DM 之后 (默认域)     → 域 3
    49'h0_0000_3804_0000,  // SYSCNT              → 域 6
    49'h0_0000_3804_F000,  // SYSCNT 末页         → 域 6
    49'h0_0000_3A00_0000,  // PLL                 → 域 2
    49'h0_0000_3A80_0000,  // IMSIC m             → 域 5
    49'h0_0000_3B00_0000,  // IMSIC sg            → 域 5
    49'h0_0000_3B00_7000,  // IMSIC sg 末页       → 域 5
    49'h0_0000_3C00_0000,  // PLIC                → 域 8
    49'h0_0000_3FFF_F000,  // PLIC 末页           → 域 8
    49'h0_0000_8000_0000,  // 默认域              → 域 3
    49'h0_0000_0000_0000   // 默认域              → 域 3
  };

  // 最近真正发射过的 A source (用来给 D 通道挑能清掉 flight 的 source)
  localparam int NRECENT = 64;
  logic [13:0] recent_src [NRECENT];
  int          recent_wp = 0;

  // 上一拍观察到的域 (只为覆盖统计, 不参与激励)
  logic [3:0] prev_domain = 4'hF;
  // 本拍 D 的 source 是否被强制与 A 的 source 相同 (制造 set/clear 同拍冲突)
  bit force_same_src = 0;

  function automatic logic [13:0] rand_source();
    case ($urandom_range(0, 9))
      0, 1, 2, 3:  return {7'($urandom_range(0, 3)),  7'($urandom)};  // 前 4 组: 高碰撞
      4, 5, 6:     return {7'($urandom_range(0, 7)),  7'($urandom_range(0, 7))}; // 更窄
      7, 8:        return {7'($urandom_range(0, 95)), 7'($urandom)};  // 全部 96 组
      default:     return 14'($urandom);                             // 含 >=12288 越界
    endcase
  endfunction

  function automatic logic [48:0] rand_addr();
    logic [48:0] a;
    case ($urandom_range(0, 9))
      0, 1, 2, 3, 4, 5: begin
        a = addr_pool[$urandom_range(0, NADDR-1)];
        // 页内偏移随机 (address[11:0] 不参与译码, 借此确认这一点)
        a[11:0] = 12'($urandom);
        return a;
      end
      6, 7: begin
        // 在池子地址上再叠一个随机页偏移, 打到相邻页/相邻域
        a = addr_pool[$urandom_range(0, NADDR-1)];
        a = a + 49'($urandom_range(0, 'h20000));
        return a;
      end
      default: return {17'($urandom), 32'($urandom)};  // 纯随机
    endcase
  endfunction

  task automatic drive_random_inputs();
    logic [13:0] s;
    s = rand_source();
    // 本拍是否刻意让 D 的 source 与 A 的 source **同拍相撞** —— 这是 flight 更新
    // 唯一有优先级的地方 (golden: 清赢), 靠自然随机几乎撞不上, 必须直接构造。
    force_same_src = ($urandom_range(0, 3) == 0);
    auto_in_a_valid <= $urandom_range(0, 3) != 0;        // 3/4 有效: 尽量把 flight 堆起来
    auto_in_a_bits_opcode <= 4'($urandom);
    auto_in_a_bits_size <= ($urandom_range(0,1) ? 3'($urandom_range(0,3)) : 3'($urandom_range(4,6)));
    auto_in_a_bits_source <= s;
    auto_in_a_bits_address <= rand_addr();
    auto_in_a_bits_user_amba_prot_bufferable <= $urandom_range(0, 1);
    auto_in_a_bits_user_amba_prot_modifiable <= $urandom_range(0, 1);
    auto_in_a_bits_user_amba_prot_readalloc <= $urandom_range(0, 1);
    auto_in_a_bits_user_amba_prot_writealloc <= $urandom_range(0, 1);
    auto_in_a_bits_user_amba_prot_privileged <= $urandom_range(0, 1);
    auto_in_a_bits_user_amba_prot_secure <= $urandom_range(0, 1);
    auto_in_a_bits_user_amba_prot_fetch <= $urandom_range(0, 1);
    auto_in_a_bits_mask <= 8'($urandom);
    auto_in_a_bits_data <= 64'({$urandom, $urandom});
    auto_in_d_ready <= $urandom_range(0, 3) != 0;
    auto_out_a_ready <= $urandom_range(0, 3) != 0;
    auto_out_d_valid <= $urandom_range(0, 2) != 0;
    // D 的 source 一半取最近发射过的 (真能清 flight), 一半随机
    auto_out_d_bits_source <= force_same_src ? s
                            : ($urandom_range(0, 1) && recent_wp > 0)
                              ? recent_src[$urandom_range(0, NRECENT-1)]
                              : rand_source();
    // opcode 6 = ReleaseAck, 特意加权以覆盖"不清 flight"的分支
    auto_out_d_bits_opcode <= ($urandom_range(0, 4) == 0) ? 4'h6 : 4'($urandom);
    auto_out_d_bits_size <= ($urandom_range(0,1) ? 3'($urandom_range(0,3)) : 3'($urandom_range(4,6)));
    auto_out_d_bits_denied <= $urandom_range(0, 1);
    auto_out_d_bits_data <= 64'({$urandom, $urandom});
    auto_out_d_bits_corrupt <= $urandom_range(0, 1);
  endtask

  // 采样覆盖点 + 记录真实发射过的 source。判据只看 golden 侧, 避免重写件出错时
  // 反过来把覆盖点也拉低而掩盖问题。
  task automatic sample_coverage();
    if (g_auto_in_a_ready !== auto_out_a_ready) cov_stall++;       // stall 拉低了 ready
    if (auto_in_a_valid && g_auto_in_a_ready) begin
      cov_a_fire++;
      recent_src[recent_wp % NRECENT] = auto_in_a_bits_source;
      recent_wp++;
      if (auto_in_a_bits_source >= 14'd12288) cov_src_oob++;
      if (!auto_in_a_bits_opcode[2] && auto_in_a_bits_size > 3'd3) cov_multibeat_a++;
      if (u_g.a_id !== prev_domain) cov_domain_switch++;
      prev_domain = u_g.a_id;
    end
    if (auto_in_a_valid && g_auto_in_a_ready && auto_in_d_ready && auto_out_d_valid
        && auto_out_d_bits_opcode != 4'h6
        && auto_in_a_bits_source == auto_out_d_bits_source
        && auto_in_a_bits_source < 14'd12288)
      cov_set_clear_race++;
    if (auto_in_d_ready && auto_out_d_valid) begin
      if (auto_out_d_bits_opcode == 4'h6) cov_release_ack++;
      else cov_d_clear++;
      if (auto_out_d_bits_opcode[0] && auto_out_d_bits_size > 3'd3) cov_multibeat_d++;
    end
  endtask
  task automatic check_outputs();
    `CHECK(auto_in_a_ready)
    `CHECK(auto_in_d_valid)
    `CHECK(auto_in_d_bits_opcode)
    `CHECK(auto_in_d_bits_size)
    `CHECK(auto_in_d_bits_source)
    `CHECK(auto_in_d_bits_denied)
    `CHECK(auto_in_d_bits_data)
    `CHECK(auto_in_d_bits_corrupt)
    `CHECK(auto_out_a_valid)
    `CHECK(auto_out_a_bits_opcode)
    `CHECK(auto_out_a_bits_size)
    `CHECK(auto_out_a_bits_source)
    `CHECK(auto_out_a_bits_address)
    `CHECK(auto_out_a_bits_user_amba_prot_bufferable)
    `CHECK(auto_out_a_bits_user_amba_prot_modifiable)
    `CHECK(auto_out_a_bits_user_amba_prot_readalloc)
    `CHECK(auto_out_a_bits_user_amba_prot_writealloc)
    `CHECK(auto_out_a_bits_user_amba_prot_privileged)
    `CHECK(auto_out_a_bits_user_amba_prot_secure)
    `CHECK(auto_out_a_bits_user_amba_prot_fetch)
    `CHECK(auto_out_a_bits_mask)
    `CHECK(auto_out_a_bits_data)
    `CHECK(auto_out_d_ready)
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    for (int i = 0; i < NRECENT; i++) recent_src[i] = '0;
    auto_in_a_valid = '0;
    auto_in_a_bits_opcode = '0;
    auto_in_a_bits_size = '0;
    auto_in_a_bits_source = '0;
    auto_in_a_bits_address = '0;
    auto_in_a_bits_user_amba_prot_bufferable = '0;
    auto_in_a_bits_user_amba_prot_modifiable = '0;
    auto_in_a_bits_user_amba_prot_readalloc = '0;
    auto_in_a_bits_user_amba_prot_writealloc = '0;
    auto_in_a_bits_user_amba_prot_privileged = '0;
    auto_in_a_bits_user_amba_prot_secure = '0;
    auto_in_a_bits_user_amba_prot_fetch = '0;
    auto_in_a_bits_mask = '0;
    auto_in_a_bits_data = '0;
    auto_in_d_ready = '0;
    auto_out_a_ready = '0;
    auto_out_d_valid = '0;
    auto_out_d_bits_opcode = '0;
    auto_out_d_bits_size = '0;
    auto_out_d_bits_source = '0;
    auto_out_d_bits_denied = '0;
    auto_out_d_bits_data = '0;
    auto_out_d_bits_corrupt = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
      sample_coverage();
    end
    $display("TLFIFOFixer checks=%0d errors=%0d", checks, errors);
    $display("  cov: stall=%0d a_fire=%0d domain_switch=%0d d_clear=%0d release_ack=%0d multibeat_a=%0d multibeat_d=%0d src_oob=%0d set_clear_race=%0d",
             cov_stall, cov_a_fire, cov_domain_switch, cov_d_clear, cov_release_ack,
             cov_multibeat_a, cov_multibeat_d, cov_src_oob, cov_set_clear_race);
    if (errors == 0 && checks > 1000
        && cov_stall > 0 && cov_a_fire > 0 && cov_domain_switch > 0 && cov_d_clear > 0
        && cov_release_ack > 0 && cov_multibeat_a > 0 && cov_multibeat_d > 0
        && cov_src_oob > 0 && cov_set_clear_race > 0) begin
      $display("TEST PASSED");
      $finish;
    end
    if (errors == 0) $display("COVERAGE HOLE: 某个覆盖点为 0, 这一轮 errors=0 不作数");
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
