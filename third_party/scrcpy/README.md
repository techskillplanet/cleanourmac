# scrcpy（开盒捆绑）

目标：用户安装「Mobile 开发助手」后，**不必**自行 `brew install scrcpy` 即可点「屏幕镜像」。

## 生成本地捆绑包

在已安装 Homebrew scrcpy 的构建机上执行：

```bash
./tool/bundle_scrcpy.sh
```

会生成可重定位目录（约 36MB）：

```text
third_party/scrcpy/scrcpy
third_party/scrcpy/scrcpy-server
third_party/scrcpy/lib/*.dylib
```

macOS 构建阶段会把该目录复制进 `.app/Contents/Resources/scrcpy/`。  
运行时优先使用捆绑件，并设置 `SCRCPY_SERVER_PATH`。

## 回退

若捆绑缺失，仍尝试系统 `/opt/homebrew/bin/scrcpy` 与 `PATH`。

## 许可证

scrcpy 及依赖遵循各自许可证（scrcpy 为 Apache-2.0）。分发时请保留上游版权声明。
