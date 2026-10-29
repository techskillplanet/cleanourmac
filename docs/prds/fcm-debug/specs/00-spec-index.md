# FCM 调试接入开发助手 — Spec 索引

**Status:** confirmed  
**Confirmed-at:** 2026-10-29（整套 Spec：01～04 + D-01～D-04）  
**prd-name:** `fcm-debug`  
**目标仓库:** `/Volumes/SSD-APFS/workplace/rn/cleanourmac`  
**能力来源:** `/Volumes/SSD-APFS/workplace/firebase-test/firebase-push-token`

## 范围

在 Mobile 开发助手中新增侧栏类目，用于本地调试 Firebase Cloud Messaging（FCM HTTP v1）推送；能力从现有 Node 测试服务迁移/重实现，保持「本地优先 · 隐私优先」。

**已确认 MVP = C**：接近现有 Web 全量（单发、完整 JSON、结果/错误、批量多 token、多套配置热切换、演示数据）。

## 文档地图

| 序号 | 文档 | 状态 | 依赖 |
|------|------|------|------|
| 00 | `00-spec-index.md` | confirmed | — |
| 01 | `01-background-and-goal.md` | confirmed | D-01 |
| 02 | `02-acceptance-criteria.md` | confirmed | 01 confirmed |
| 03 | `03-as-is.md` | confirmed | 02 confirmed |
| 04 | `04-to-be.md` | confirmed | 03 + D-01～D-04 |
| — | `plans/01-fcm-debug-feature.md` | done | Spec confirmed；代码已落地 |

## Evidence（已收集）

- 开发助手：Flutter macOS/Windows 桌面端；侧栏 `AppShell` + Riverpod；JWT 页明确「密钥不落盘」。
- FCM 测试服务：Node `PushService` → OAuth JWT → `fcm.googleapis.com/v1/projects/{id}/messages:send`；支持简化/完整消息格式；Web UI + `/api/send-notification`。

## 未决门禁（按顺序一次一个）

1. ~~MVP 功能范围~~ → **D-01 = C**
2. ~~确认 `01-background-and-goal.md`~~
3. ~~确认 `02-acceptance-criteria.md`~~
4. ~~确认 `03-as-is.md`~~
5. ~~**D-02 服务账号凭据策略**~~ → **A**
6. ~~**D-03 侧栏命名与位置**~~ → **A**
7. ~~**D-04 独立 Node 服务去留**~~ → **A**
8. ~~确认 `04-to-be.md`~~ → Spec 收口
9. 实施计划 `plans/`（进行中）

## 确认记录

- **D-01**（2026-10-29）：MVP = C（用户确认）
- **01**（2026-10-29）：背景与目标 confirmed（用户回复「确认」）
- **02**（2026-10-29）：验收标准 confirmed（用户回复「确认」）
- **03**（2026-10-29）：As-Is confirmed（用户回复「确认」）
- **D-02**（2026-10-29）：凭据 = A 仅内存不落盘（用户确认）
- **D-03**（2026-10-29）：侧栏「FCM 推送」，JWT 之后（用户确认）
- **D-04**（2026-10-29）：保留 Node 仓库，日常用助手（用户确认）
- **04**（2026-10-29）：To-Be confirmed；授权进入 Plan
