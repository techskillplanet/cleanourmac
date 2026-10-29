# 验收标准

**Status:** confirmed  
**Confirmed-at:** 2026-10-29（用户回复「确认」）  
**Prerequisite:** `01-background-and-goal.md`（confirmed）  
**Evidence:** 目标 D-01=C；现有 `firebase-push-token` 行为对照

## 验收条目

### AC-01 入口可达

开发助手侧栏出现独立 **FCM 调试** 类目；进入后可完成配置与发送，无需启动 `firebase-push-token` Node 服务。

### AC-02 服务账号配置

用户可导入至少一套 Firebase 服务账号（JSON）；可切换多套已导入配置；可清除当前/全部运行时配置。无效 JSON 或缺少必需字段时，界面给出明确错误，不发起 OAuth/FCM 请求。

### AC-03 Access Token

在有效服务账号下，用户可触发生成 `firebase.messaging` 范围的 OAuth2 Access Token，并看到成功或失败原因（不含完整私钥）。

### AC-04 单设备简化发送

用户填写设备 token + notification（至少 title、body），可选 image/data/android；发送后：

- 成功：展示 FCM 返回的 message 名称/ID；
- 失败：展示可读错误（优先 FCM/OAuth 返回信息）。

### AC-05 完整 FCM JSON

用户可编辑并发送完整 `{ "message": { ... } }`（或等价完整 message 体）；发送前可预览将提交的 JSON；校验失败时不发送并提示缺失字段（如 token、notification.title/body，与现网校验语义对齐）。

### AC-06 批量发送

用户可提供多个设备 token，对同一套消息内容批量发送；结束后展示总数、成功数、失败数，并能查看失败 token 与原因摘要。

### AC-07 演示数据

提供一键填入演示消息（token/标题/正文/data 等可替换占位）；填入后用户仍可编辑再发送。

### AC-08 会话内发送记录

当前应用会话内保留最近发送记录（时间、项目、成功/失败、messageId 或错误摘要）。**默认不将私钥、完整 Access Token 写入磁盘**；凭据是否持久化由后续门禁确认后，可增补本条。

### AC-09 本地与隐私

FCM 调试不将业务源码或与推送无关的剪贴板/项目内容上传到非 Google FCM/OAuth 端点；网络请求仅面向 Google OAuth 与 FCM HTTP v1（及用户消息内自填的图片 URL 等）。

### AC-10 平台

在 macOS 桌面目标上，上述 AC-01～AC-09 可完成验证。Windows 尽力可用；若有明确不支持项须在 To-Be 标明。

## 验证方式（证据要求）

| AC | 验证方式 |
|----|----------|
| AC-01 | 手工：侧栏进入页面截图或步骤记录 |
| AC-02～AC-07 | 手工：对接真实或测试 Firebase 项目各走通一次；失败路径用错误配置/错误 token 各测一次 |
| AC-08 | 手工：发送两次后杀进程重启，确认记录与敏感凭据策略符合最终 To-Be |
| AC-09 | 代码/抓包抽查：仅 OAuth + FCM（及消息内 URL） |
| AC-10 | macOS `flutter run -d macos` 实机验证清单 |

## 护栏

- 不把服务账号私钥打印到完整日志或提交进 git。
- 批量发送失败不中断整批统计（单项失败记入 failures，继续其余）。
- 不引入「默认自动对任意设备群发」而无确认的危险操作。

## 请确认

请确认以上验收标准是否可接受。确认后标记 `confirmed`，并起草 `03-as-is.md`。
