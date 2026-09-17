# a_id 地址译码表的来源与复跑方式

`rtl/uncore/TLFIFOFixer.sv` 里 `tlfifofixer_pkg::REGION_MAP` 那 16 条区间
**不是从 Chisel 推的**，是对 golden 的 `a_id` 做 2^20 全枚举反解出来的。
原因：golden 的 `a_id` 是 firtool 把 rocket-chip `findFifoIdFast` 展开后的
~210 行位级异或/比较网络（`_a_id_T_351` / `_a_id_T_355` 链），
手读极易错一位，而且 Chisel 侧拿不到 `KunminghuV2Config` 实际的 manager 列表。

## 为什么 2^20 就是穷举

对 golden `TLFIFOFixer.sv` 第 139–347 行（`a_id` 的全部定义）grep 所有
`auto_in_a_bits_address[...]` 位选，结果只有：

    16:15 29:12 29:13 29:14 29:15 29:16 29:17 29:18 29:19 29:20 29:21
    29:22 29:23 29:24 29:25 29:26 29:28 30 30:29 48

即 `a_id` 只依赖 `address[48]` 和 `address[30:12]`（`[16:15]` 已含在 `[29:12]` 里）。
`address[47:31]` 与 `address[11:0]` **完全不参与**。所以 20 位输入 = 1,048,576 种，
可以真正穷举，不是抽样。

## 复跑

    bash sweep.sh          # 需要 VCS（VCS_ARCH_OVERRIDE=linux + -full64）

`sweep.sh` 会：

1. 从 golden `TLFIFOFixer.sv` 原样截取第 139–347 行，套一个只有
   `input [48:0] address / output [3:0] id` 的壳（不改一个字符）；
2. 枚举全部 2^20 种 `{address[48], address[30:12]}`，导出 `aid_table.txt`；
3. 用 `check_table.py` 把 `REGION_MAP` 的 16 条区间 + 默认域 3 逐点比对，
   并检查 16 条区间两两不相交（所以「先命中先赢」与「全匹配求或」等价）。

预期输出：

    disjoint: OK
    mismatches: 0 / 1048576  -> table is EXACT

输入 commit：golden `TLFIFOFixer.sv`
sha256 `e9c9e2b505805a50896362d9db6d17e079076fcaf0085a41c260cbcc3c92c6d7`
（`/home/eda/xs-env/G1-canonical/golden-rtl/TLFIFOFixer.sv`）。
