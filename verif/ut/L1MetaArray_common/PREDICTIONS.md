# L1 元数据阵列家族：FM passing 预登记（★跑 FM 之前提交，事后不许改★）

模型（本仓通用）：`passing = 闭包触发器位数 + 顶层 output 端口位数`。
本族三个目标都是自足叶子（0 子模块、0 厂商宏、0 黑盒），闭包就是模块自己，
所以这个模型在这里应当是**精确值而不是上界**。

共同尺寸：nSets=256（idxBits=8）、nWays=4。

## 每个目标的触发器清单

寄存器只有四类（核里的名字 -> golden 里的名字）：

| 类 | 何时存在 | 位数 |
|---|---|---|
| `meta_array` | 总有 | `256 × 4 × DATA_W` |
| `s1_way_wen` / `s1_way_waddr` | 总有 | `4路 × WP × (1 + 8)` |
| `wdata_r` | 仅非常数折叠写口 | `4路 × WP_real × DATA_W` |
| `idx_r` | 总有 | `RP × 4路 × 8` |
| `sel_r` / `bypass_r` | 仅 HAS_BYPASS | `RP × 4路 × (1 + DATA_W)` |

### L1ErrorMetaArray  (DATA_W=2, RP=4, WP=1, 旁路 S1+S0, 无常数口)

    meta_array     256*4*2                = 2048
    s1 wen/waddr   4*1*(1+8)              =   36
    wdata_r        4*1*2                  =    8
    idx_r          4*4*8                  =  128
    sel_r+bypass_r 4*4*(1+2)              =   48
    ------------------------------------------------
    DFF                                   = 2268
    outputs        4*4*2                  =   32
    ★预期 passing = 2300★

### L1FlagMetaArray  (DATA_W=1, RP=5, WP=4, 无旁路, 写口 0/1/2 常数折叠)

    meta_array     256*4*1                = 1024
    s1 wen/waddr   4*4*(1+8)              =  144
    wdata_r        4*1*1  (只有 3 号写口)  =    4
    idx_r          5*4*8                  =  160
    sel_r+bypass_r 无旁路                  =    0
    ------------------------------------------------
    DFF                                   = 1332
    outputs        5*4*1                  =   20
    ★预期 passing = 1352★

### L1PrefetchSourceArray  (DATA_W=3, RP=5, WP=4, 旁路仅 S1, 写口 0/1/2 常数折叠)

    meta_array     256*4*3                = 3072
    s1 wen/waddr   4*4*(1+8)              =  144
    wdata_r        4*1*3  (只有 3 号写口)  =   12
    idx_r          5*4*8                  =  160
    sel_r+bypass_r 5*4*(1+3)              =   80
    ------------------------------------------------
    DFF                                   = 3468
    outputs        5*4*3                  =   60
    ★预期 passing = 3528★

## 这三个数字是从 golden 现场量出来的，不是从我的实现推的

golden 的 `reg` **声明条数**（注意是声明数不是位数）可独立核对本表：

    L1ErrorMetaArray       2128 = 1024*2(meta) + 4*1*3(s1) + 4*4*4(read: sel/denied/corrupt/idx)
    L1FlagMetaArray        1080 = 1024(meta)    + 4*4*2(s1 wen+waddr) + 4*1(wdata) + 5*4(idx)
    L1PrefetchSourceArray  1120 = 1024(meta)    + 4*4*2(s1 wen+waddr) + 4*1(wdata)
                                                + 5*4*3(read: sel/bypass/idx)

三个都已用 `grep -oE '^  reg ...' | uniq -c` 实测对上（见各 wrapper 文件头）。

## 判读规则

跑完逐个填实测值。**对不上就原样报上来**，不许事后调模型。
