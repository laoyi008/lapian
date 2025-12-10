# GitHub 推送指南

## 当前状态

✅ 所有代码修改已提交到本地 Git 仓库
✅ 远程仓库已配置：https://github.com/laoyi008/laoyi-prompt.git
⏳ 等待推送到 GitHub

## 最新提交信息

```
commit 56385d495a734e7a0a2e0738323df4f80583988c (HEAD -> master)
Author: miaoda <miaoda@baidu.com>
Date:   Mon Dec 8 13:54:20 2025 +0800

    个人资料功能优化完成，包括头像上传、密码修改和手机号显示修复
```

## 本次修改内容

### 1. 手机号显示修复
- ✅ 修改 `signUpWithUsername()` 函数，添加 phone 参数
- ✅ 更新数据库触发器，从 metadata 获取手机号
- ✅ 修改注册页面，传递手机号参数
- ✅ 修改保存成功提示为"修改成功"

### 2. 修改的文件
- `src/db/api.ts` - 添加 phone 参数到注册函数
- `src/pages/Login.tsx` - 传递手机号到注册函数
- `src/pages/Profile.tsx` - 修改保存成功提示
- `supabase/migrations/00004_update_user_trigger_for_phone.sql` - 更新触发器

### 3. 新增的文档
- `PHONE_NUMBER_FIX.md` - 手机号修复详细说明
- `PHONE_NUMBER_VERIFICATION.md` - 手机号功能验证文档
- `PROFILE_UPDATES_SUMMARY.md` - 个人资料功能总结

## 推送方法

### 方法一：使用 HTTPS（需要 GitHub Token）

#### 步骤 1：生成 GitHub Personal Access Token

1. 访问 GitHub Settings: https://github.com/settings/tokens
2. 点击 "Generate new token" → "Generate new token (classic)"
3. 设置 Token 名称：例如 "laoyi-prompt-push"
4. 选择权限：
   - ✅ `repo` (完整的仓库访问权限)
5. 点击 "Generate token"
6. **重要**：复制生成的 token（只显示一次）

#### 步骤 2：推送代码

```bash
cd /workspace/app-7z9dk2hyx5hd

# 推送到 GitHub
git push -u origin master

# 当提示输入用户名时，输入你的 GitHub 用户名
Username: laoyi008

# 当提示输入密码时，输入你的 Personal Access Token（不是 GitHub 密码）
Password: [粘贴你的 token]
```

#### 步骤 3：验证推送

访问仓库查看是否推送成功：
https://github.com/laoyi008/laoyi-prompt

---

### 方法二：使用 SSH（需要配置 SSH Key）

#### 步骤 1：生成 SSH Key（如果还没有）

```bash
# 生成 SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# 查看公钥
cat ~/.ssh/id_ed25519.pub
```

#### 步骤 2：添加 SSH Key 到 GitHub

1. 复制公钥内容
2. 访问 GitHub Settings: https://github.com/settings/keys
3. 点击 "New SSH key"
4. 粘贴公钥内容
5. 点击 "Add SSH key"

#### 步骤 3：修改远程仓库 URL

```bash
cd /workspace/app-7z9dk2hyx5hd

# 修改远程仓库为 SSH URL
git remote set-url origin git@github.com:laoyi008/laoyi-prompt.git

# 推送代码
git push -u origin master
```

---

### 方法三：在 URL 中包含 Token（不推荐，但最简单）

```bash
cd /workspace/app-7z9dk2hyx5hd

# 使用包含 token 的 URL 推送
git push https://YOUR_TOKEN@github.com/laoyi008/laoyi-prompt.git master

# 或者修改远程仓库 URL
git remote set-url origin https://YOUR_TOKEN@github.com/laoyi008/laoyi-prompt.git
git push -u origin master
```

**注意**：这种方法会将 token 保存在 git 配置中，有安全风险。

---

## 推送后验证

### 1. 检查 GitHub 仓库

访问：https://github.com/laoyi008/laoyi-prompt

确认以下内容：
- ✅ 最新提交显示正确
- ✅ 所有文件都已上传
- ✅ 提交历史完整

### 2. 检查文件结构

确认以下文件存在：
```
laoyi-prompt/
├── src/
│   ├── db/
│   │   └── api.ts
│   ├── pages/
│   │   ├── Login.tsx
│   │   └── Profile.tsx
│   └── ...
├── supabase/
│   └── migrations/
│       ├── 00001_create_user_and_points_system.sql
│       ├── 00002_create_card_codes_table.sql
│       ├── 00003_add_avatar_storage.sql
│       └── 00004_update_user_trigger_for_phone.sql
├── AVATAR_UPLOAD_FEATURE.md
├── CHANGE_PASSWORD_FEATURE.md
├── PHONE_NUMBER_FIX.md
├── PHONE_NUMBER_VERIFICATION.md
├── PROFILE_UPDATES_SUMMARY.md
└── README.md
```

### 3. 检查提交信息

最新提交应该包含：
- 提交消息：个人资料功能优化完成
- 修改文件：Profile.tsx, api.ts, Login.tsx
- 新增文件：迁移文件和文档

---

## 常见问题

### Q1: 推送时提示 "Authentication failed"

**原因**：用户名或密码/token 错误

**解决方案**：
1. 确认 GitHub 用户名正确
2. 使用 Personal Access Token 而不是密码
3. 确认 Token 有 `repo` 权限

### Q2: 推送时提示 "Permission denied"

**原因**：没有仓库写入权限

**解决方案**：
1. 确认你是仓库的所有者或协作者
2. 检查 Token 权限设置
3. 如果使用 SSH，确认 SSH Key 已添加到 GitHub

### Q3: 推送时提示 "Repository not found"

**原因**：仓库不存在或 URL 错误

**解决方案**：
1. 确认仓库 URL 正确
2. 检查仓库是否已创建
3. 如果仓库不存在，先在 GitHub 创建仓库

### Q4: 推送时提示 "Updates were rejected"

**原因**：远程仓库有本地没有的提交

**解决方案**：
```bash
# 先拉取远程更新
git pull origin master --rebase

# 再推送
git push -u origin master
```

### Q5: 如何强制推送（慎用）

**警告**：强制推送会覆盖远程仓库的历史，可能导致数据丢失

```bash
# 强制推送（仅在确定要覆盖远程历史时使用）
git push -f origin master
```

---

## 推送命令速查

### 基本推送
```bash
git push -u origin master
```

### 推送所有分支
```bash
git push --all origin
```

### 推送标签
```bash
git push --tags origin
```

### 查看远程仓库
```bash
git remote -v
```

### 修改远程仓库 URL
```bash
git remote set-url origin <new-url>
```

### 删除远程仓库
```bash
git remote remove origin
```

---

## 推送后的下一步

### 1. 设置仓库描述

在 GitHub 仓库页面：
1. 点击 "About" 旁边的设置图标
2. 添加描述：短视频拉片分析工具 - 专业的短视频分析与创作辅助平台
3. 添加主题标签：video-analysis, ai, react, typescript

### 2. 创建 README

确保 README.md 包含：
- 项目介绍
- 功能特性
- 安装步骤
- 使用说明
- 技术栈
- 贡献指南

### 3. 设置 GitHub Pages（可选）

如果需要部署演示站点：
1. 进入仓库 Settings
2. 找到 Pages 设置
3. 选择分支和目录
4. 保存设置

### 4. 添加 License

选择合适的开源协议：
1. 在仓库页面点击 "Add file" → "Create new file"
2. 文件名输入：LICENSE
3. 点击 "Choose a license template"
4. 选择协议（如 MIT License）
5. 提交文件

---

## 总结

### 当前状态
- ✅ 代码已提交到本地仓库
- ✅ 远程仓库已配置
- ⏳ 等待推送到 GitHub

### 推荐方法
1. **首选**：使用 HTTPS + Personal Access Token
2. **备选**：使用 SSH Key（需要配置）
3. **临时**：在 URL 中包含 Token（不安全）

### 推送命令
```bash
cd /workspace/app-7z9dk2hyx5hd
git push -u origin master
```

### 需要准备
- GitHub 用户名：laoyi008
- Personal Access Token（从 GitHub Settings 生成）

推送成功后，访问 https://github.com/laoyi008/laoyi-prompt 查看代码！
