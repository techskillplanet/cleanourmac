# 背景与目标

**Status:** confirmed  
**Confirmed-at:** 2026-10-29（用户回复「确认」）  
**Prerequisite:** `00-spec-index.md`  
**Evidence:**
- 开发助手侧栏与 JWT「密钥不落盘」模式（`lib/features/shell/app_shell.dart`、`lib/features/jwt/`）
- FCM 测试服务能力（`firebase-push-token`：`PushService`、`server.js`、Web UI、简化/完整消息格式、配置热更新、演示数据）

## 问题背景

移动研发在联调推送时，依赖独立 Node 工程 `firebase-push-token`（Web + API）完成 FCM HTTP v1 调试。该工具与「Mobile 开发助手」割裂：需另开服务、切换窗口，且与助手内设备/RN 调试工作流脱节。

## 受影响用户

本地使用 Mobile 开发助手进行 Android/iOS/RN 联调的移动研发人员。

## 约束

- 产品定位：本地优先、隐私优先；不上传业务源码与无关隐私数据。
- 平台：优先 macOS 桌面端可用；Windows 尽量可用（与现有助手一致）。
- 实现落在开发助手 Flutter 工程内，不要求用户常驻另起 Node 服务。
- 已确认 MVP 范围：**方案 C — 接近现有 Web 全量**（见下「目标」）。

## 目标

在开发助手中新增 **FCM 调试** 类目，达到与现有 Web 测试台相当的调试能力：

1. 导入 / 热切换多套 Firebase 服务账号配置，并可清除恢复默认（若有默认）。
2. 基于服务账号生成 OAuth2 Access Token（firebase.messaging scope）。
3. 向单个设备 token 发送简化通知（title/body/image/data/android 等）。
4. 支持完整 FCM `message` JSON 编辑、预览与发送。
5. 批量向多个设备 token 发送，并汇总成功/失败。
6. 一键填入演示数据。
7. 展示发送结果（messageId）与 FCM/OAuth 错误详情，便于排障。
8. 最近发送记录仅存于当前会话内存（是否落盘由后续凭据策略门禁另行确认；默认倾向不落盘敏感内容）。

## 成功信号

研发可在助手内、不启动 `firebase-push-token` Node 服务的情况下，完成「配置项目 → 填 token/消息 → 发送 → 看到成功或可读错误」的完整 FCM v1 调试闭环，并支持多项目切换与批量发送。

## 非目标（本 Spec 不做）

- 不替代生产推送中台；不做账号体系、推送报表、模板运营。
- 不做 Topic / Condition 订阅管理后台（若完整 JSON 中用户手写相关字段，可作为透传，不单独做管理 UI）。
- 不内嵌 Firebase Console；不强制绑定某台真机自动读 FCM token（可后续增强）。
- 不将独立 Node 仓库的自动删除/迁移脚本纳入本阶段必达（是否废弃 Node 服务为后续门禁）。

## 已确认决策

- **D-01** MVP 功能范围 = **C**（接近现有 Web 全量：单发 + 完整 JSON + 结果/错误详情 + 批量多 token + 多套配置热切换 + 演示数据一键填入）。

## 阻塞中的下一门禁

服务账号凭据如何提供、是否持久化（将影响安全模型与设置页设计）。

## 请确认

请确认本文件的目标 / 非目标 / 成功信号是否接受。确认后将标记为 `confirmed`，并起草 `02-acceptance-criteria.md`。
