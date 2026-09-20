#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""predict.py —— DelayN 家族 FM passing 的预登记模型（跑前算，跑后对账）。

## 模型

Formality 的 compare point 在本族里只有两类（这 6 个已签核变体的 fm.log
逐个确认过：BBPin/Loop/BBNet/Cut/LAT 五列全 0）：

    Port 列 = golden 顶层 **输出端口的位数**
    DFF  列 = 闭包里 **触发器的位数**

DelayN 变体 = 无复位定长移位链，故

    passing = payload + STAGES * payload = payload * (1 + STAGES)

payload 与 STAGES 由 `gen_facts.py` 从 G1 golden 现读（不是从名字猜）。

## 为什么这里是**精确等式**而不是上界

Entries* 那一档模型要留带宽，是因为 golden 里有 Constant 寄存器被 FM 归并掉。
本族的 golden 模块体经 gen_facts.verify() 逐条核过：只有一个无复位无使能的
always 块、reg 表 = 级数 × 字段、输出取最后一级 —— **没有常量寄存器可归并**。
已签核的 6 个实测正好落在等式上（657/216/10/3/822/2 全部 +0），
所以本族登记的是等式，不设带宽：**差任何一个都按 fail 上报，不事后调带**。

用法: python3 predict.py            # 打印预测表
      python3 predict.py --tsv      # 机器可读
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_facts import facts          # noqa: E402
from gen import VARIANTS             # noqa: E402


def predict(name):
    f = facts(name)
    payload, stages = f["payload"], f["stages"]
    return dict(name=name, payload=payload, stages=stages,
                port_bits=payload, dff_bits=stages * payload,
                passing=payload * (1 + stages))


def main():
    rows = [predict(n) for n in VARIANTS]
    if '--tsv' in sys.argv:
        print("top\tpayload\tstages\tport_bits\tdff_bits\tpassing_model")
        for r in rows:
            print("%s\t%d\t%d\t%d\t%d\t%d" % (r["name"], r["payload"], r["stages"],
                                              r["port_bits"], r["dff_bits"], r["passing"]))
        return 0
    print("%-12s %8s %7s %10s %9s %14s" %
          ("top", "payload", "stages", "port_bits", "dff_bits", "passing(模型)"))
    for r in rows:
        print("%-12s %8d %7d %10d %9d %14d" %
              (r["name"], r["payload"], r["stages"], r["port_bits"], r["dff_bits"], r["passing"]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
