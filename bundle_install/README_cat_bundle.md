# CAT 离线源码安装包

这组脚本用于生成并使用一个不依赖 `git clone` 的 CAT 安装包目标机仍然可以通过 conda/pip 镜像安装 PyTorch、torchaudio、tensorboard 等普通包；容易被原始安装脚本从 GitHub 或源码站拉取的源码依赖会放进 bundle。本脚本同时修复了一些安装过程中遇到的依赖错误。

## 1. 在联网机器上构建安装包

如果脚本目录、CAT 仓库目录、bundle 输出目录不在同一个位置，可以显式指定：

```bash
CAT_REPO_ROOT=/path/to/CAT \
OUT_DIR=/path/to/bundles \
bash /path/to/scripts/build_cat_install_bundle.sh
```

如果脚本就在 CAT 仓库内，或当前工作目录是 CAT 仓库，`CAT_REPO_ROOT` 通常可以自动推断；`OUT_DIR` 默认是当前工作目录。
如果 `build_cat_install_bundle.sh`、`install_cat_bundle.sh`、`README_cat_bundle.md` 不在同一个目录，可以额外指定 `INSTALL_SCRIPT=/path/to/install_cat_bundle.sh` 和 `BUNDLE_README=/path/to/README_cat_bundle.md`。

生成结果类似：

```text
/path/to/bundles/cat-install-bundle-20260622-120000.tar.gz
```

可选项：

```bash
# 同时下载普通 Python wheel 到 wheelhouse，适合同 Python/平台复用
DOWNLOAD_PY_WHEELS=1 bash /path/to/scripts/build_cat_install_bundle.sh

# 如果需要缩小包体积，可以剥离依赖源码里的 .git 元数据
STRIP_GIT_METADATA=1 bash /path/to/scripts/build_cat_install_bundle.sh

# 换 pip 下载镜像
PIP_INDEX_URL=https://pypi.tuna.tsinghua.edu.cn/simple bash /path/to/scripts/build_cat_install_bundle.sh
```

## 2. 目标服务器要求

目标服务器不需要能访问 GitHub，也不会执行 `git clone`；但默认安装仍需要访问 conda/pip 镜像来安装 PyTorch、tensorboard 等普通包。安装前建议确认：

- Linux x86_64 服务器，具备 `bash`、`tar`、`gzip`、`sed`、`awk` 等常见基础命令。
- 能访问配置的 conda/pip 镜像；如果设置 `PIP_OFFLINE=1`，需要 bundle 内已经准备好对应 Python/平台可用的 wheelhouse。
- 有可用的 NVIDIA GPU，且 `nvidia-smi` 能正常看到显卡和驱动。默认安装会构建 `ctc-crf` 等 CUDA 扩展，CPU-only 目标机需要显式跳过相关模块。
- 有 CUDA 编译器 `nvcc`。可以使用系统 CUDA，例如 `/usr/local/cuda/bin/nvcc`；如果目标机没有系统 `nvcc`，可尝试设置 `INSTALL_CUDA_BUILD_TOOLKIT=1` 让脚本从 conda 安装 CUDA 编译工具。
- 有可用且与 CUDA 版本兼容的系统 C/C++ 编译器，例如 `gcc`/`g++`。脚本会通过 conda 安装 CMake、Make、Boost、Eigen 等构建依赖，但不会替代系统编译器。
- `CONDA_HOME` 和 `CAT_INSTALL_ROOT` 对当前用户可写。默认分别为 `~/miniconda3` 和 `~/CAT`。
- 建议至少预留 10GB 可用磁盘空间；PyTorch/CUDA conda 环境和 native 编译中间产物会占用较多空间。
- 如果安装 `fst-decoder` 或 `all`，需要额外提供可用的 Kaldi，并设置 `KALDI_ROOT=/path/to/kaldi`。

可用下面的命令做快速自检：

```bash
uname -m
nvidia-smi
which gcc g++ || true
nvcc --version || true
df -h "$HOME"
```

## 3. 在目标机上安装

```bash
tar -xzf cat-install-bundle-*.tar.gz
cd cat-install-bundle-*
bash install_cat_bundle.sh
```

模块化安装保持原 `install.sh` 的语义：

```bash
# 默认等价于原来的 install.sh cat
bash install_cat_bundle.sh

# 只安装指定模块
bash install_cat_bundle.sh ctcdecode
bash install_cat_bundle.sh kenlm
bash install_cat_bundle.sh ctc-crf

# 安装 CAT 主体模块：ctcdecode + kenlm + ctc-crf + requirements + CAT
bash install_cat_bundle.sh cat

# 全部模块：cat + fst-decoder + g2p-tool
KALDI_ROOT=/opt/kaldi bash install_cat_bundle.sh all
```

默认行为：

- 安装或复用 conda；优先检查 `CONDA_HOME`，再检查 PATH 里的已有 conda。
- 创建或复用 `cat` conda 环境。
- 使用清华 conda/pip 镜像。
- conda 安装 `pytorch==2.1.0`、`torchaudio==2.1.0`、`pytorch-cuda=12.1`。
- 从本地源码安装 `ctcdecode`、`kenlm`、`ctc_crf`、`torch-gather`、`warp-rnnt`、`webdataset`、`warp-ctct`、`ctc-align-cuda`。
- `torch-gather`、`warp-rnnt`、`webdataset`、`warp-ctct`、`ctc-align-cuda` 会先复制到 `CAT/src/` 下，再从该位置安装；editable 安装后的源码路径不会指向解压包的 `payload/`。
- `jiwer` 约束为 `>=2.2.0,<3.0`，以兼容 CAT 附带脚本使用的 `jiwer.compute_measures(...)` 老接口。
- 安装 CAT 到 `~/CAT`。
- 写入 shell rc，使新终端能自动初始化 conda、设置 `CAT_ROOT` 和 `PATH`。

## 4. 常用参数

```bash
# 指定安装目录和环境名
CAT_INSTALL_ROOT=/data/CAT CONDA_ENV_NAME=cat310 bash install_cat_bundle.sh

# conda 不在 ~/miniconda3 时可显式指定
CONDA_HOME=/opt/miniconda3 bash install_cat_bundle.sh

# 如果 cat 环境存在但不完整，显式允许删除重建
RECREATE_CONDA_ENV=1 bash install_cat_bundle.sh

# 指定 CUDA/PyTorch 版本
CUDA_VERSION=12.1 TORCH_VERSION=2.1.0 TORCHAUDIO_VERSION=2.1.0 TORCHVISION_VERSION=0.16.0 bash install_cat_bundle.sh

# ctc-crf 会默认用 PyTorch 自动探测当前 GPU 架构；也可以显式指定。
# 这里的 80/89/90 是 GPU compute capability，不是 CUDA toolkit 版本。
CTC_CRF_CUDA_ARCH_LIST="80 90" bash install_cat_bundle.sh ctc-crf

# ctc-crf 会自动移除旧 setup.py 写死的 -std=c++14，
# 让 PyTorch BuildExtension 按当前版本管理 C++ extension 标准。

# 如果镜像没有 nvidia channel，默认会用官方 NVIDIA channel；也可以显式指定
NVIDIA_CONDA_CHANNEL=https://conda.anaconda.org/nvidia bash install_cat_bundle.sh

# 只使用 wheelhouse，不访问 pip 镜像
PIP_OFFLINE=1 bash install_cat_bundle.sh

# 目标机没有系统 nvcc 时，尝试从 conda 安装 CUDA 编译工具
INSTALL_CUDA_BUILD_TOOLKIT=1 bash install_cat_bundle.sh

# 只做 CAT Python 包的轻量安装时，可跳过本地 CUDA 源码依赖
INSTALL_LOCAL_SOURCE_DEPS=0 BUILD_CTC_CRF=0 bash install_cat_bundle.sh

# 默认保持原脚本语义，以 editable 方式安装本地第三方源码依赖。
# 如果 pip 25+ 因 legacy editable 行为变化导致失败，可切换为非 editable。
EDITABLE_LOCAL_SOURCE_DEPS=0 bash install_cat_bundle.sh cat

# 不写 shell 启动文件
WRITE_SHELL_RC=0 bash install_cat_bundle.sh

# 只构建 g2p 工具
bash install_cat_bundle.sh g2p-tool

# 只构建 fst-decoder，需要已有 Kaldi
KALDI_ROOT=/opt/kaldi bash install_cat_bundle.sh fst-decoder
```

## 5. Bundle 内容

```text
payload/source/CAT
payload/third_party/repos/ctcdecode
payload/third_party/repos/kenlm
payload/third_party/repos/Phonetisaurus
payload/third_party/repos/torch-gather
payload/third_party/repos/warp-rnnt
payload/third_party/repos/webdataset
payload/third_party/repos/warp-ctct
payload/third_party/repos/ctc-align-cuda
payload/third_party/tarballs/openfst-1.6.7.tar.gz
payload/third_party/tarballs/openfst-1.7.2.tar.gz
payload/third_party/tarballs/boost_1_67_0.tar.gz
payload/requirements/requirements.runtime.txt
```

目标机安装脚本不会运行 `git clone`。如果安装失败后重跑，它会复用已有 conda、环境和源码目录，但 native 编译步骤仍可能重新执行。
