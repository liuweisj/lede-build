# LEDE/OpenWrt build

这个项目支持两种构建方式：

- GitHub Actions：见 `.github/workflows/build-openwrt.yml`
- M 系列 Mac 本地构建：使用 OrbStack 提供的原生 ARM64 Docker 环境

本地方案只要求 Mac 已安装并启动 OrbStack。LEDE 的 Ubuntu 编译依赖全部保留在容器镜像中，不会安装到 macOS。

镜像内同时包含 ARM64 Go bootstrap。LEDE 上游在 Apple Silicon 原生构建时会使用主机 Go；这里使用容器内 Go 达到同样目的，绕过旧版 Go 1.4 bootstrap 不支持 `linux/arm64` 的限制。

## 本地构建

检查 ARM64 容器环境：

```bash
./scripts/local-build.sh check
```

开始构建：

```bash
./scripts/local-build.sh build
```

默认使用 8 个下载任务和 8 个编译任务，可以覆盖：

```bash
BUILD_JOBS=6 DOWNLOAD_JOBS=8 ./scripts/local-build.sh build
```

如需固定 LEDE commit、tag 或其他 Git ref：

```bash
LEDE_REF=<commit-or-tag> ./scripts/local-build.sh build
```

未设置 `LEDE_REF` 时跟随 `master` 分支。

构建产物按时间和源码 revision 保存到：

```text
output/YYYYMMDD-HHMMSS-<revision>/
├── firmware/
├── packages/
└── buildinfo/
```

## 存储布局

为了避免 macOS 文件共享成为大量小文件编译的瓶颈：

- LEDE 源码、`build_dir` 和 `staging_dir` 使用 `lede-local_lede-work` Docker volume
- 下载缓存使用 `lede-local_lede-downloads` Docker volume
- `files/.config` 以只读方式挂载
- 只有最终产物写入 `output/`

进入交互式编译容器：

```bash
./scripts/local-build.sh shell
```

停止并移除临时容器、网络（保留编译缓存）：

```bash
docker compose down
```

如果以后不再需要本地构建，可删除源码和下载缓存卷，再删除镜像：

```bash
docker compose down --volumes
docker image rm lede-builder:ubuntu-22.04-arm64
```

以上清理不会删除 `output/` 中已经导出的固件。
