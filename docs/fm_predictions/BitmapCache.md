# BitmapCache —— FM passing 跑前登记的对账说明

登记（`docs/fm_predictions/BitmapCache.json`，commit b48b26b9）：`expected=1925`（regs 1415 + outs 110）。

## 第一次跑（commit b48b26b9，vmucp 未开）的实测与对账

    passing 13027（Port 110 + DFF 12916 + LAT 1）/ failing 0 / unread 42
    fm_predict.py check：实测高于模型 11102 —— 模型算漏了

漏在哪（与 docs/fm_predictions/PtwCache.md 记的是同一条模型局限）：`fm_passing_model.py`
的实例扫描正则要求模块名首字母大写，而 SRAM 一路的实例是
`sram_array_1p32x90m45s1h0l1b_bitmap array (` / `array_9 array (` / `array_9_ext array_9_ext (`，
全小写，一个都没数到。手工按 golden 闭包逐文件数 `reg` 声明位（剥掉 ENABLE_INITIAL_REG_ 段）：

    BitmapCache.sv 936 + MbistBitmapCache.sv 114 + ClockGate.sv 1 + SRAMTemplate_124.sv 91×4 = 1415   ← 模型的 regs
    array_9_ext.v (reg_RW0_ren 1 + reg_RW0_addr 5 + ram 32×90=2880) = 2886 × 4 = 11544                ← 模型漏的
    合计 regs 12959 + outs 110 = 13069 = passing 13027 + unread 42                                    ← 逐位对上

（`RW0_random` 在 `RANDOMIZE_GARBAGE_ASSIGN` 之下，`+define+SYNTHESIS` 时不存在，不计。）
`fm_predict.py check` 报的差额 11102 = 13027 − 1925，其中 11544 是漏数的 SRAM，
−442 是 42 个 unread（未开 vmucp 时不计进 passing）与模型已含的 SRAMTemplate_124 之外
的口径差；逐位守恒的那条等式是 **12959 + 110 = 13027 + 42**，一位不差。

## 第二次跑（vmucp 打开）的跑前承诺

  P1 native SUCCEEDED；P2 failing 0；P3 unmatched 两侧 0；
  P4 unread 0（42 个 matched-unread 全部转成比较点）；
  P5 passing = 13069（= 第一次的 13027 + 42），黑盒边界仍为空。
