# neural-spec

Small neural networks with explicit specifications and Lean proofs, built with TorchLean.

第一个实验：用 TorchLean 训练一个 **2 → 4 ReLU → 2** 的 XOR 分类器，为四个连续输入区域写出精确的 Lean 规格，再逐步连接训练得到的权重与规格证明。

## 当前状态

- 有固定初始化种子的 TorchLean CPU 训练入口，共 22 个可训练参数。
- 有覆盖四个区域的 36 个确定性训练样本、checkpoint 保存与重新加载。
- 有四个区域的数值界检查：依次尝试 IBP、CROWN，仍未确认时检查完整的 8×8 子区域覆盖，要求每块的正确类别分数余量至少为 `1/4`。
- 有实数语义下的 `XorSpec` 定义，以及“满足 margin 规格就严格分类正确”的通用 Lean 定理。
- **尚未证明某个训练完成的 checkpoint 满足 `XorSpec`。** 数值检查通过不能替代这个定理。

本机已完成构建、训练和 checkpoint 重新加载。默认种子 `7`、`1000` 步训练得到的网络通过四个区域的数值检查；最小报告余量约 `0.502`。[实测记录](docs/VALIDATION.md)

## 输入区域与规格

| x₁ | x₂ | 正确类别 |
| --- | --- | --- |
| [0, 1/5] | [0, 1/5] | 0 |
| [0, 1/5] | [4/5, 1] | 1 |
| [4/5, 1] | [0, 1/5] | 1 |
| [4/5, 1] | [4/5, 1] | 0 |

对每个区域中的**所有实数输入**，最终要证明：

```text
correct_logit(x) - other_logit(x) ≥ 1/4
```

不对四个区域之外的输入作承诺。两个输出是分类分数，不要求经过 softmax。

## 运行

需要 [elan / Lean](https://lean-lang.org/install/) 和本机 C 编译器。默认 CPU 路径不需要 Python、PyTorch 或 CUDA。

```sh
git clone https://github.com/Varifold-Lab/neural-spec.git
cd neural-spec
lake update
lake exe cache get
lake build
lake exe xor --help
```

Lean 固定为 `v4.34.0`；TorchLean 固定为 `de3192df4779877ceb65cfe470a4d4ce9d480a5b`；`lake-manifest.json` 固定传递依赖。首次构建还会编译 TorchLean / FloatLib，时间与依赖缓存情况有关。

先跑一次训练更新，检查训练、保存和数值验证路径能否执行：

```sh
lake exe xor smoke
```

训练并查看四个区域的数值结果：

```sh
lake exe xor train 1000 7 artifacts/xor.state
lake exe xor check artifacts/xor.state
```

参数顺序为 `steps seed checkpoint`，可省略，默认值如上。训练采用均方误差、one-hot 目标、Adam（学习率 0.03）、每次更新 36 个样本。随机种子用于初始化；训练数据固定，便于复现。

`train` / `smoke` 返回 0 表示流程执行成功，并不代表区域检查全部通过。`check` 返回 0 表示四个**数值** margin 检查通过，返回 2 表示至少一个检查未通过或界不够紧；无效参数、加载失败等错误返回 1。不同初始化可能学到不同结果，不预先承诺默认种子能通过全部检查。

checkpoint 写入被 Git 忽略的 `artifacts/`。用 `check` 重新加载时使用保存的参数，初始化种子不会替换 checkpoint 中的权重。

只构建精确规格和通用推论：

```sh
lake build NeuralSpec
```

## 文件

| 文件 | 用途 |
| --- | --- |
| `NeuralSpec/Xor/Model.lean` | TorchLean 模型、优化器与 CPU 配置 |
| `NeuralSpec/Xor/Data.lean` | 四个区域、中心点及训练样本 |
| `NeuralSpec/Xor/Run.lean` | 训练、checkpoint、数值 IBP/CROWN 报告 |
| `NeuralSpec/Xor/Spec.lean` | 精确实数规格与分类推论 |
| `Main.lean` | 命令行入口 |
| `docs/ROADMAP.md` | 连接具体网络证明及神经元消融实验 |
| `docs/VALIDATION.md` | 构建、试跑结果与 checkpoint 哈希 |

## 证明范围

训练的 `.native` 路径采用 binary32，公开输入、checkpoint 和报告通过 `Float` 传递。运行时数值检查使用中心 `(0.1/0.9, 0.1/0.9)` 与略微放大的半径 `0.100001`，避免把浮点端点误当成精确有理数端点。这个处理本身不构成从数值报告到实数规格的证明。

细分路径使用宽度 `0.025` 的 8×8 网格与略微放大的半径 `0.012501`，每个小块都必须通过检查。它不缩小原始输入域；小块覆盖与舍入的精确语义仍需要在正式证明中建立。

当前报告是计算出的候选输出界。后续需要将**具体权重、计算图、输入域和运算语义**连接到 TorchLean 的可靠性定理，并生成 Lean 内核可以检查的证据。我们不把 `certified=true` 日志、测试集准确率或直接假设最终性质当作网络证明。

GPU 执行、训练过程保持性质、任意网络的安全性，均不是当前实验已经建立的结论。

参考：[TorchLean](https://github.com/lean-dojo/TorchLean)、[验证示例](https://lean-dojo.github.io/TorchLean/examples/verification/)、[证明与运行时边界](https://github.com/lean-dojo/TorchLean/blob/de3192df4779877ceb65cfe470a4d4ce9d480a5b/docs/TRUST_BOUNDARIES.md)。
