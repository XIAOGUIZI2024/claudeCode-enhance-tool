# Claude Code Enhancement Toolkit 🚀

> Windows 专用的 Claude Code 增强工具包，为你的 Claude Code 添加状态栏和智能通知功能。

## ✨ 功能特性

### 📊 StatusLine 状态栏

在 Claude Code 终端底部实时显示：

- 📁 当前工作目录
- 🤖 当前使用的模型名称
- 📈 上下文窗口使用进度条（带颜色标签）

```
my-project | opus-4.8 | ████████░░ 78% LOW
```

- **OK** — 上下文剩余 ≥ 50%（正常）
- **LOW** — 上下文剩余 20%~49%（注意）
- **CRIT** — 上下文剩余 < 20%（危险）

### 🔔 智能通知

当 Claude Code 需要你关注时（任务完成、权限请求、提问等），自动弹出 Windows 通知提醒。

**智能之处**：当你正在看终端时，通知会自动抑制，不会打扰你；只有当你离开电脑时才会弹出通知。

支持的通知场景：

| 事件 | 通知内容 |
|------|----------|
| Stop | 任务完成，请查看 |
| PermissionRequest | 需要权限确认 |
| Elicitation | 有问题需要你回答 |
| Notification | 需要你的关注 |

## 📋 系统要求

| 依赖 | 用途 | 必需？ |
|------|------|--------|
| Windows 10/11 | 运行环境 | ✅ 是 |
| Python | 状态栏 JSON 解析 | 建议安装 |
| Git for Windows | 提供 Bash 环境 | 建议安装 |
| BurntToast 模块 | Toast 通知样式 | 自动安装 |

> 缺少 Python 或 Git 时，安装脚本会自动跳过对应功能，仅安装可用的部分。

## 🚀 安装

### 方式一：通过 Claude Code 安装（推荐）

1. 克隆本仓库
```bash
git clone https://github.com/XIAOGUIZI2024/claudeCode-enhance-tool.git
cd claudeCode-enhance-tool/claude-features-setup
```

2. 打开 Claude Code
```bash
claude
```

3. 输入以下命令
```
请执行当前目录下的 install.ps1 脚本来安装 Claude Code 增强功能
```

4. 重启 Claude Code 即可生效

### 方式二：手动安装

在 PowerShell 中运行：
```powershell
cd claude-features-setup
powershell -ExecutionPolicy Bypass -File install.ps1
```

## 🔧 工作原理

### 安装流程

```
install.ps1
  ├── Step 0: 检测环境（Python / Bash / PowerShell）
  ├── Step 1: 安装 BurntToast 模块
  ├── Step 2: 复制 notify.ps1 → ~/.claude/notify.ps1
  ├── Step 3: 复制 statusline.sh → ~/.claude/statusline.sh
  ├── Step 4: 更新 ~/.claude/settings.json（添加 statusLine + hooks 配置）
  └── Step 5: 验证安装 + 发送测试通知
```

### 智能通知逻辑

```
notify.ps1
  ├── 检测前台窗口进程（Win32 API）
  ├── 前台是终端？→ 静默退出（用户在看，不需要通知）
  ├── 前台不是终端？
  │   ├── 尝试 BurntToast 发送通知
  │   └── 失败？→ 控制台蜂鸣声回退
  └── 结束
```

### 状态栏渲染

```
Claude Code → (JSON) → statusline.sh → python 解析 → 格式化输出
                                                    ↓
                              my-project | opus-4.8 | ████████░░ 78% LOW
```

## 📁 项目结构

```
claude-features-setup/
├── install.ps1      # 主安装脚本
├── notify.ps1       # 智能通知脚本
├── statusline.sh    # 状态栏渲染脚本
└── README.md        # 说明文档
```

## ❓ 常见问题

**Q: 安装后没有看到状态栏？**

确保已安装 Python 和 Git for Windows，然后重启 Claude Code。

**Q: 没有收到通知？**

1. 确认 Windows 通知权限已开启
2. 检查 BurntToast 是否安装成功（安装脚本会自动尝试安装）
3. 如果你在看终端，通知会被智能抑制，这是正常行为

**Q: 如何卸载？**

删除以下文件并重启 Claude Code：
```powershell
Remove-Item ~/.claude/notify.ps1
Remove-Item ~/.claude/statusline.sh
```
然后手动编辑 `~/.claude/settings.json`，移除 `statusLine` 和 `hooks` 配置项。

## 📄 许可证

MIT License
