# 初始化验证记录

日期：2026-09-29。本机 CPU，TorchLean native binary32，typed-graph 执行。

- Lean：`v4.34.0`。
- TorchLean：`de3192df4779877ceb65cfe470a4d4ce9d480a5b`。
- `lake build`：通过。
- `lake build NeuralSpec`：通过。
- 一步训练与 checkpoint 保存：通过。
- 1000 步、种子 7 的训练完成；均方误差从约 `0.421570` 降至 `0.009356`。
- 重新加载该 checkpoint 后，`xor check` 返回 0，四个区域的数值检查全部通过。
- 仅训练一步的 checkpoint 返回 2，只有一个区域达到目标余量，验证路径没有把所有运行都当成成功。
- `xor train 0` 返回 1，拒绝无效步数。

## 1000 步 checkpoint 的候选余量

| 区域 | 整块 IBP | 最终采用的方法 | 最终候选下界 |
| --- | ---: | --- | ---: |
| low-low | -0.399112 | 8×8 完整覆盖，每块 IBP | 0.675489 |
| low-high | 0.501937 | 整块 IBP | 0.501937 |
| high-low | 0.088900 | 8×8 完整覆盖，每块 IBP | 0.552727 |
| high-high | 0.796917 | 整块 IBP | 0.796917 |

整块 CROWN 在本次运行中未改善两个未确认区域的结论；完整细分后四个区域均达到 `1/4` 的数值目标。没有缩小输入范围或降低 margin。

本地文件：`artifacts/xor.state`（被 Git 忽略）。SHA-256：

```text
5b2c2f4adf6f09626e0c1de16bb256b62b9c92b9d653c2b6c565e5954a1c4536
```

以上是本次运行的观察，不承诺所有平台生成相同 checkpoint。仓库包含训练与复查命令。

## Lean 定理的范围

`NeuralSpec.Xor.XorSpec.correct_label` 已通过 Lean 检查，其公理依赖为标准的 `propext`、`Classical.choice`、`Quot.sound`，没有 `sorryAx`。

这个定理证明“若网络满足 `XorSpec`，则四个区域内严格分类正确”。**本次尚未证明上面这个 checkpoint 满足 `XorSpec`。** 数值报告到具体网络语义的可靠性连接是下一个里程碑。
