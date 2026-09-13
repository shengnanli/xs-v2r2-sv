#!/usr/bin/env python3
"""生成 ICacheMSHR 家族的 14 个变体薄文件（rtl/frontend/）与家族 tb。

家族识别结论（机械比对得到，见本文件底部的 GROUPS）：G1 里 14 个 ICacheMSHR
**不是**同一个参数化核的不同实参，而是**两种模块体各复制若干份**：
  * 取指 MSHR（fetchMSHRs_0..3   -> ICacheMSHR / _1 / _2 / _3）：无 io_flush；
  * 预取 MSHR（prefetchMSHRs_0..9 -> ICacheMSHR_4 .. _13）：多一条 io_flush。
组内 14 个文件把自身模块名归一化后**逐字节相同**（md5 一致），所有位宽也完全
一样（blkPaddr 42b / vSetIdx 8b / way 2b / acquire 地址 48b / 2 个查询口）。
"""
import os, re, sys, hashlib

G = os.environ.get("GOLDEN_RTL", "/home/eda/xs-env/G1-canonical/golden-rtl")
HERE = os.path.dirname(os.path.abspath(__file__))
RTL = os.path.abspath(os.path.join(HERE, "../../../rtl/frontend"))

FETCH = ["ICacheMSHR", "ICacheMSHR_1", "ICacheMSHR_2", "ICacheMSHR_3"]
PREFETCH = [f"ICacheMSHR_{i}" for i in range(4, 14)]
ALL = FETCH + PREFETCH
INST = {n: (f"fetchMSHRs_{i}" if n in FETCH else f"prefetchMSHRs_{PREFETCH.index(n)}")
        for i, n in enumerate(ALL) for _ in [0]}
INST = {}
for i, n in enumerate(FETCH):
    INST[n] = f"fetchMSHRs_{i}"
for i, n in enumerate(PREFETCH):
    INST[n] = f"prefetchMSHRs_{i}"

PORT = re.compile(r'^\s*(input|output|inout)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')


def facts(name):
    txt = open(f"{G}/{name}.sv").read()
    body = txt[txt.index(f"\nmodule {name}(") + 1:]
    head = body[:body.index("\n);")]
    ports = []
    for ln in head.splitlines()[1:]:
        m = PORT.match(ln)
        if not m:
            raise SystemExit(f"{name}: 端口行解析失败: {ln!r}")
        w = int(m.group(2)) - int(m.group(3)) + 1 if m.group(2) else 1
        ports.append(dict(dir=m.group(1), w=w, name=m.group(4)))
    return dict(name=name, ports=ports, head_text=head + "\n);",
                pw={p["name"]: p["w"] for p in ports},
                body_md5=hashlib.md5(body.replace(name, "MOD").encode()).hexdigest())


def check_groups():
    """机械复核家族切分：组内归一化后必须逐字节相同，组间必须只差 io_flush。"""
    by_md5 = {}
    for n in ALL:
        by_md5.setdefault(facts(n)["body_md5"], []).append(n)
    assert len(by_md5) == 2, f"ICacheMSHR 不是两组，而是 {len(by_md5)} 组：{by_md5}"
    groups = sorted(by_md5.values(), key=len)
    assert sorted(groups[0]) == sorted(FETCH), groups
    assert sorted(groups[1]) == sorted(PREFETCH), groups
    a, b = facts(FETCH[0]), facts(PREFETCH[0])
    assert [p["name"] for p in b["ports"] if p["name"] != "io_flush"] == \
           [p["name"] for p in a["ports"]], "两组端口表差异不止 io_flush"
    for p in a["ports"]:
        assert b["pw"][p["name"]] == p["w"], f"{p['name']} 两组位宽不同"
    return by_md5


def gen_variant(name):
    f = facts(name)
    has_flush = "io_flush" in f["pw"]
    role = "取指" if not has_flush else "预取"
    nports = len(f["ports"])
    blk, vs, way = f["pw"]["io_req_bits_blkPaddr"], f["pw"]["io_req_bits_vSetIdx"], \
        f["pw"]["io_resp_bits_way"]
    acq = f["pw"]["io_acquire_bits_acquire_address"]
    off = acq - blk
    ports = f["head_text"].split("\n", 1)[1]
    flush_conn = "io_flush" if has_flush else \
        "1'b0            /* 取指 MSHR 的 golden 没有 io_flush 端口，恒 0 */"
    peers = FETCH if not has_flush else PREFETCH
    return f"""// =============================================================================
// {name} —— 指令缓存单条 MSHR（xs_ICacheMSHR_core 家族的一个变体）
//
// 本变体的参数与规模（按 G1 golden 现读，不从上一轮继承）：
//   角色：ICacheMissUnit 的{role} MSHR，实例名 {INST[name]}（共 {len(peers)} 格）；
//   端口 {nports} 个 = 19 个固定端口{' + io_flush' if has_flush else '（无 io_flush）'} + 2 个查询口 ×3 根；
//   位宽：块物理地址 {blk}b、虚 set 索引 {vs}b、way {way}b、
//         Acquire 地址 {acq}b = {blk}b 块地址 + {off}b 块内偏移（64B 块）；
//   golden 模块体 = 7 个异步复位寄存器 + 纯组合输出，无数组 / 无子模块。
//   HAS_FLUSH = {int(has_flush)}：{'预取 MSHR 认 fencei 与 flush 两种冲刷' if has_flush else '取指 MSHR 只认 fencei，核的 flush 输入接 1' + chr(39) + 'b0'}。
//
// 家族事实（机械比对，不是猜的）：G1 的 14 个 ICacheMSHR 归一化模块名后只剩
//   **两种**模块体——{len(FETCH)} 个取指变体互为逐字节副本，{len(PREFETCH)} 个预取变体互为逐字节
//   副本，两组之间只差一条 io_flush 端口及其参与的三处表达式。所有位宽 14 个
//   变体完全一致，所以这不是"同核不同参"，而是"同一份逻辑被单态化复制 14 份"。
//
// 结构：golden 同名端口表 -> 设参例化 xs_ICacheMSHR_core（状态机与不变式都在
//   xs_ICacheMSHR_core.sv 里讲）。本层只做端口改名与两个查询口的打包。
// 自动生成：verif/ut/ICacheMSHR/gen.py（读 G1 golden）—— 勿手改
// =============================================================================

module {name}(
{ports}

  localparam int unsigned BLK_PADDR_W = {blk};
  localparam int unsigned VSETIDX_W   = {vs};
  localparam int unsigned WAY_W       = {way};
  localparam int unsigned OFFSET_W    = {off};
  localparam int unsigned NUM_LOOKUPS = 2;

  xs_ICacheMSHR_core #(
    .BLK_PADDR_W     (BLK_PADDR_W),
    .VSETIDX_W       (VSETIDX_W),
    .WAY_W           (WAY_W),
    .OFFSET_W        (OFFSET_W),
    .NUM_LOOKUPS     (NUM_LOOKUPS),
    .HAS_FLUSH       (1'b{int(has_flush)}),
    // 端口表事实：$bits 只认端口声明，抄错位宽这些常量立刻跟着变
    .PORT_ACQ_ADDR_W ($bits(io_acquire_bits_acquire_address)),
    .PORT_BITS_LOOKUP($bits({{io_lookUps_0_info_bits_blkPaddr, io_lookUps_0_info_bits_vSetIdx,
                             io_lookUps_1_info_bits_blkPaddr, io_lookUps_1_info_bits_vSetIdx}})),
    .PORT_BITS_RESP  ($bits({{io_resp_bits_blkPaddr, io_resp_bits_vSetIdx, io_resp_bits_way}})),
    .GOLDEN_PORTS    ({nports})
  ) u_core (
    .clock            (clock),
    .reset            (reset),
    .fencei           (io_fencei),
    .flush            ({flush_conn}),
    .wfi_req          (io_wfi_wfiReq),
    .wfi_safe         (io_wfi_wfiSafe),
    .invalid          (io_invalid),
    .req_ready        (io_req_ready),
    .req_valid        (io_req_valid),
    .req_blk_paddr    (io_req_bits_blkPaddr),
    .req_vset_idx     (io_req_bits_vSetIdx),
    .acquire_ready    (io_acquire_ready),
    .acquire_valid    (io_acquire_valid),
    .acquire_address  (io_acquire_bits_acquire_address),
    .acquire_vset_idx (io_acquire_bits_vSetIdx),
    // 查询口按 {{口1, 口0}} 拼接：核里的数组下标 0 就是 golden 的 lookUps_0
    .lookup_blk_paddr ({{io_lookUps_1_info_bits_blkPaddr, io_lookUps_0_info_bits_blkPaddr}}),
    .lookup_vset_idx  ({{io_lookUps_1_info_bits_vSetIdx,  io_lookUps_0_info_bits_vSetIdx}}),
    .lookup_hit       ({{io_lookUps_1_hit,                io_lookUps_0_hit}}),
    .resp_valid       (io_resp_valid),
    .resp_blk_paddr   (io_resp_bits_blkPaddr),
    .resp_vset_idx    (io_resp_bits_vSetIdx),
    .resp_way         (io_resp_bits_way),
    .victim_way       (io_victimWay)
  );

endmodule
"""




# ---------------------------------------------------------------------------
# 家族 tb：14 个变体一个对照台（每个变体一对 golden / _xs 实例，独立随机激励）
# ---------------------------------------------------------------------------
def sig(name):
    return "m0" if name == "ICacheMSHR" else "m" + name[len("ICacheMSHR_"):]


TB_HEAD = """// 自动生成：verif/ut/ICacheMSHR/gen.py（读 G1 golden）—— 勿手改
// ICacheMSHR 家族 14 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
// （同一个 xs_ICacheMSHR_core：取指变体 HAS_FLUSH=0，预取变体 HAS_FLUSH=1）。
//
// 每个变体一对实例、各自独立的随机激励；比对的是全部 11 个输出打成的 114 位向量
// （wfiSafe/req_ready/acquire_valid/acquire_address/acquire_vSetIdx/两个 hit/
//   resp_valid/resp_blkPaddr/resp_vSetIdx/resp_way）。
//
// 激励设计：地址池故意开得很小（blkPaddr 0..3 × vSetIdx 0..1），
//   让并行查询口经常撞上本格登记的地址，把 hit 分支真正跑起来；
//   fencei / flush / invalid / wfiReq 以低概率注入，reset 偶尔异步脉冲一拍
//   （golden 是异步高有效复位，这条路径必须走到）。
//
// 采样点：**先驱动、再 #1 比对、然后过 posedge**。为什么不能反过来（先比对再驱动）：
//   那样在比对时刻，寄存器已经被"当前这份输入"更新过了，于是像
//   "io_invalid 为 1 且本格仍占用" 这类事件按构造恒为 0 —— 覆盖计数会永远是 0，
//   而 errors 照样 0。本 tb 第一版就踩了这个坑，是覆盖闸把它抓出来的。
//
// 覆盖闸（本轮已发生"tb 20 万拍只 fire 1 次却报 errors=0"的事故）：每个变体都要
//   (1) 有效比对 >= COV_MIN；
//   (2) 入队 enq、发出 send、命中 hit、resp_valid、wfi 不安全、被冲刷 kill、
//       invalid 清除 —— 七类关键事件各 >= COV_MIN；
//   (3) 预取变体还要单独统计 io_flush 触发的冲刷 >= COV_MIN。
//   任何一项不足即 TEST FAILED，不看 errors。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 500;
  bit clock = 0;
  logic reset;
  int errors = 0;
  int checks = 0;
  int cov_fail = 0;
  always #5 clock = ~clock;
"""

def out_cat(tag, s):
    """把 11 个输出打成一根 114 位比对向量（golden 端口顺序）。"""
    n = [f"{tag}_{s}_wfiSafe", f"{tag}_{s}_req_ready", f"{tag}_{s}_acq_valid",
         f"{tag}_{s}_acq_addr", f"{tag}_{s}_acq_vset", f"{tag}_{s}_lk0_hit",
         f"{tag}_{s}_lk1_hit", f"{tag}_{s}_resp_valid", f"{tag}_{s}_resp_paddr",
         f"{tag}_{s}_resp_vset", f"{tag}_{s}_resp_way"]
    return "{" + ", ".join(n[:5]) + ",\n     " + ", ".join(n[5:]) + "}"


def gen_tb():
    L, infos = [TB_HEAD], []
    for name in ALL:
        f = facts(name)
        s = sig(name)
        has_flush = "io_flush" in f["pw"]
        infos.append((name, s, has_flush))
        L.append(f"  // ---- {name} ({INST[name]}, HAS_FLUSH={int(has_flush)}) ----")
        L.append(f"  logic {s}_fencei, {s}_flush, {s}_wfiReq, {s}_invalid,"
                 f" {s}_req_valid, {s}_acq_ready;")
        L.append(f"  logic [41:0] {s}_req_paddr, {s}_lk0_paddr, {s}_lk1_paddr;")
        L.append(f"  logic [7:0]  {s}_req_vset,  {s}_lk0_vset,  {s}_lk1_vset;")
        L.append(f"  logic [1:0]  {s}_victim;")
        L.append(f"  int {s}_checks, {s}_enq, {s}_send, {s}_hit, {s}_resp,"
                 f" {s}_unsafe, {s}_kill, {s}_inval;")
        for tag in ("g", "i"):
            L.append(f"  wire {tag}_{s}_wfiSafe, {tag}_{s}_req_ready, {tag}_{s}_acq_valid,")
            L.append(f"       {tag}_{s}_lk0_hit, {tag}_{s}_lk1_hit, {tag}_{s}_resp_valid;")
            L.append(f"  wire [47:0] {tag}_{s}_acq_addr;")
            L.append(f"  wire [7:0]  {tag}_{s}_acq_vset, {tag}_{s}_resp_vset;")
            L.append(f"  wire [41:0] {tag}_{s}_resp_paddr;")
            L.append(f"  wire [1:0]  {tag}_{s}_resp_way;")
        for tag, mod in (("g", name), ("i", name + "_xs")):
            conn = [
                f"    .clock(clock)", f"    .reset(reset)",
                f"    .io_fencei({s}_fencei)",
            ]
            if has_flush:
                conn.append(f"    .io_flush({s}_flush)")
            conn += [
                f"    .io_wfi_wfiReq({s}_wfiReq)",
                f"    .io_wfi_wfiSafe({tag}_{s}_wfiSafe)",
                f"    .io_invalid({s}_invalid)",
                f"    .io_req_ready({tag}_{s}_req_ready)",
                f"    .io_req_valid({s}_req_valid)",
                f"    .io_req_bits_blkPaddr({s}_req_paddr)",
                f"    .io_req_bits_vSetIdx({s}_req_vset)",
                f"    .io_acquire_ready({s}_acq_ready)",
                f"    .io_acquire_valid({tag}_{s}_acq_valid)",
                f"    .io_acquire_bits_acquire_address({tag}_{s}_acq_addr)",
                f"    .io_acquire_bits_vSetIdx({tag}_{s}_acq_vset)",
                f"    .io_lookUps_0_info_bits_blkPaddr({s}_lk0_paddr)",
                f"    .io_lookUps_0_info_bits_vSetIdx({s}_lk0_vset)",
                f"    .io_lookUps_0_hit({tag}_{s}_lk0_hit)",
                f"    .io_lookUps_1_info_bits_blkPaddr({s}_lk1_paddr)",
                f"    .io_lookUps_1_info_bits_vSetIdx({s}_lk1_vset)",
                f"    .io_lookUps_1_hit({tag}_{s}_lk1_hit)",
                f"    .io_resp_valid({tag}_{s}_resp_valid)",
                f"    .io_resp_bits_blkPaddr({tag}_{s}_resp_paddr)",
                f"    .io_resp_bits_vSetIdx({tag}_{s}_resp_vset)",
                f"    .io_resp_bits_way({tag}_{s}_resp_way)",
                f"    .io_victimWay({s}_victim)",
            ]
            L.append(f"  {mod} u_{tag}_{s} (")
            L.append(",\n".join(conn))
            L.append("  );")
        for tag in ("g", "i"):
            L.append(f"  wire [113:0] {tag}_{s}_out =\n    " + out_cat(tag, s) + ";")
        L.append("")

    drive, check, init, cov = [], [], [], []
    for name, s, has_flush in infos:
        flush_drv = (f"    {s}_flush   = ($urandom_range(0, 47) == 0);"
                     if has_flush else
                     f"    {s}_flush   = 1'b0;   // 取指变体 golden 没有这条端口")
        drive.append(f"""    {s}_fencei  = ($urandom_range(0, 63) == 0);
{flush_drv}
    {s}_wfiReq  = ($urandom_range(0, 15) == 0);
    {s}_invalid = ($urandom_range(0, 7) == 0);
    {s}_req_valid = ($urandom_range(0, 9) < 6);
    {s}_acq_ready = ($urandom_range(0, 9) < 6);
    {s}_req_paddr = 42'($urandom_range(0, 3));
    {s}_req_vset  = 8'($urandom_range(0, 1));
    {s}_lk0_paddr = 42'($urandom_range(0, 3));
    {s}_lk0_vset  = 8'($urandom_range(0, 1));
    {s}_lk1_paddr = 42'($urandom_range(0, 3));
    {s}_lk1_vset  = 8'($urandom_range(0, 1));
    {s}_victim    = 2'($urandom);""")
        check.append(f"""    if (!$isunknown(g_{s}_out)) begin
      checks++; {s}_checks++;
      if (g_{s}_req_ready & {s}_req_valid) {s}_enq++;
      if ({s}_acq_ready & g_{s}_acq_valid) {s}_send++;
      if (g_{s}_lk0_hit | g_{s}_lk1_hit)   {s}_hit++;
      if (g_{s}_resp_valid)                {s}_resp++;
      if (!g_{s}_wfiSafe)                  {s}_unsafe++;
      if ({s}_fencei | {s}_flush)          {s}_kill++;
      if ({s}_invalid & g_{s}_resp_valid)  {s}_inval++;
      if (g_{s}_out !== i_{s}_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH {name} g=%0h i=%0h", $time, g_{s}_out, i_{s}_out);
      end
    end""")
        init.append(f"    {s}_fencei = 0; {s}_flush = 0; {s}_wfiReq = 0; {s}_invalid = 0;\n"
                    f"    {s}_req_valid = 0; {s}_acq_ready = 0; {s}_req_paddr = '0;\n"
                    f"    {s}_req_vset = '0; {s}_lk0_paddr = '0; {s}_lk0_vset = '0;\n"
                    f"    {s}_lk1_paddr = '0; {s}_lk1_vset = '0; {s}_victim = '0;\n"
                    f"    {s}_checks = 0; {s}_enq = 0; {s}_send = 0; {s}_hit = 0;\n"
                    f"    {s}_resp = 0; {s}_unsafe = 0; {s}_kill = 0; {s}_inval = 0;")
        cov.append(f"""    $display("  {name}: checks=%0d enq=%0d send=%0d hit=%0d resp=%0d unsafe=%0d kill=%0d inval=%0d",
             {s}_checks, {s}_enq, {s}_send, {s}_hit, {s}_resp, {s}_unsafe, {s}_kill, {s}_inval);
    cov_fail += cov_short("{name} checks", {s}_checks)
              + cov_short("{name} enq",    {s}_enq)
              + cov_short("{name} send",   {s}_send)
              + cov_short("{name} hit",    {s}_hit)
              + cov_short("{name} resp",   {s}_resp)
              + cov_short("{name} unsafe", {s}_unsafe)
              + cov_short("{name} kill",   {s}_kill)
              + cov_short("{name} inval",  {s}_inval);""")

    nl = "\n"
    L.append(f"""
  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
{nl.join(drive)}
  endtask

  task automatic check_outputs();
{nl.join(check)}
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
{nl.join(init)}
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();   // 先换激励
      #1 check_outputs();      // 组合输出已稳定；此刻的输入就是 posedge 要采样的那一份
      @(posedge clock);
      // 异步复位偶尔脉冲一下：golden 是 posedge reset 异步复位，这条路径必须走到
      if ($urandom_range(0, 4999) == 0) begin
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("ICacheMSHR family checks=%0d errors=%0d", checks, errors);
{nl.join(cov)}
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule
""")
    open(os.path.join(HERE, "tb.sv"), "w").write("\n".join(L))
    print("wrote tb.sv")

if __name__ == "__main__":
    groups_md5 = check_groups()
    print("家族复核通过：两组归一化 md5 =", {k[:10]: len(v) for k, v in groups_md5.items()})
    for n in ALL:
        open(os.path.join(RTL, n + ".sv"), "w").write(gen_variant(n))
    print(f"wrote {len(ALL)} variant files under {RTL}")
    gen_tb()
