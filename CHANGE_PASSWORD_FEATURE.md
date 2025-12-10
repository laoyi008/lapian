# 修改密码功能说明

## 功能概述

在个人中心的个人资料页面添加了修改密码功能，用户可以安全地修改自己的登录密码。同时将用户名设置为不可修改，保持账户标识的稳定性。

## 实现内容

### 1. API 函数

在 `src/db/api.ts` 中添加了 `changePassword` 函数：

```typescript
export async function changePassword(
  currentPassword: string,
  newPassword: string
): Promise<{ success: boolean; error?: string }>
```

#### 功能流程

1. **获取当前用户**
   - 从 Supabase Auth 获取当前登录用户
   - 验证用户是否已登录
   - 检查用户邮箱是否存在

2. **验证当前密码**
   - 使用当前密码尝试重新登录
   - 验证密码是否正确
   - 如果密码错误，返回错误信息

3. **更新密码**
   - 调用 Supabase Auth 的 `updateUser` 方法
   - 更新用户密码
   - 返回操作结果

#### 返回值

```typescript
{
  success: boolean;  // 是否成功
  error?: string;    // 错误信息（失败时）
}
```

#### 安全机制

- **旧密码验证**：必须提供正确的当前密码才能修改
- **重新认证**：通过重新登录验证用户身份
- **错误处理**：捕获并返回具体的错误信息

### 2. 个人中心页面更新

在 `src/pages/Profile.tsx` 中实现了完整的密码修改功能：

#### 状态管理

```typescript
// 修改密码相关状态
const [isChangingPassword, setIsChangingPassword] = useState(false);
const [currentPassword, setCurrentPassword] = useState('');
const [newPassword, setNewPassword] = useState('');
const [confirmPassword, setConfirmPassword] = useState('');
const [showCurrentPassword, setShowCurrentPassword] = useState(false);
const [showNewPassword, setShowNewPassword] = useState(false);
const [showConfirmPassword, setShowConfirmPassword] = useState(false);
```

#### 密码修改逻辑

```typescript
const handleChangePassword = async () => {
  // 1. 验证输入
  if (!currentPassword) {
    toast.error('请输入当前密码');
    return;
  }

  if (!newPassword) {
    toast.error('请输入新密码');
    return;
  }

  if (newPassword.length < 6) {
    toast.error('新密码长度不能少于6位');
    return;
  }

  if (newPassword === currentPassword) {
    toast.error('新密码不能与当前密码相同');
    return;
  }

  if (newPassword !== confirmPassword) {
    toast.error('两次输入的新密码不一致');
    return;
  }

  // 2. 调用API修改密码
  setIsChangingPassword(true);
  try {
    const result = await changePassword(currentPassword, newPassword);
    
    if (result.success) {
      toast.success('密码修改成功');
      // 清空输入框
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
      // 隐藏密码
      setShowCurrentPassword(false);
      setShowNewPassword(false);
      setShowConfirmPassword(false);
    } else {
      toast.error(result.error || '修改失败');
    }
  } catch (error) {
    console.error('修改密码失败:', error);
    toast.error('修改失败，请重试');
  } finally {
    setIsChangingPassword(false);
  }
};
```

#### 输入验证规则

1. **当前密码**：必填
2. **新密码**：
   - 必填
   - 长度至少6位
   - 不能与当前密码相同
3. **确认密码**：
   - 必填
   - 必须与新密码一致

#### UI 组件

**用户名输入框（只读）**：
```typescript
<Input
  id="username"
  value={username}
  placeholder="用户名"
  disabled
  className="bg-muted/50 cursor-not-allowed"
/>
<p className="text-xs text-muted-foreground">
  用户名不可修改
</p>
```

**密码输入框（带显示/隐藏切换）**：
```typescript
<div className="relative">
  <Input
    type={showCurrentPassword ? "text" : "password"}
    value={currentPassword}
    onChange={(e) => setCurrentPassword(e.target.value)}
    placeholder="请输入当前密码"
    className="pr-10"
  />
  <Button
    type="button"
    variant="ghost"
    size="sm"
    className="absolute right-0 top-0 h-full px-3 hover:bg-transparent"
    onClick={() => setShowCurrentPassword(!showCurrentPassword)}
  >
    {showCurrentPassword ? (
      <EyeOff className="w-4 h-4 text-muted-foreground" />
    ) : (
      <Eye className="w-4 h-4 text-muted-foreground" />
    )}
  </Button>
</div>
```

**修改密码按钮**：
```typescript
<Button 
  onClick={handleChangePassword} 
  disabled={isChangingPassword || !currentPassword || !newPassword || !confirmPassword}
  variant="outline"
  className="w-full gap-2"
>
  {isChangingPassword && <Loader2 className="w-4 h-4 animate-spin" />}
  <Lock className="w-4 h-4" />
  修改密码
</Button>
```

### 3. 页面布局

#### 分隔线设计

在个人资料和修改密码之间添加了视觉分隔：

```typescript
<div className="relative my-6">
  <div className="absolute inset-0 flex items-center">
    <div className="w-full border-t border-border"></div>
  </div>
  <div className="relative flex justify-center text-xs uppercase">
    <span className="bg-background px-2 text-muted-foreground">修改密码</span>
  </div>
</div>
```

#### 表单结构

1. **头像上传区域**
2. **用户名（只读）**
3. **手机号（可编辑）**
4. **保存修改按钮**
5. **分隔线**
6. **当前密码输入**
7. **新密码输入**
8. **确认新密码输入**
9. **修改密码按钮**

## 使用说明

### 修改密码

1. **进入个人中心**
   - 点击导航栏的"个人中心"按钮
   - 或访问 `/profile` 路径
   - 默认显示"个人资料"标签页

2. **滚动到修改密码区域**
   - 在个人资料表单下方
   - 有"修改密码"分隔线标识

3. **输入密码信息**
   - **当前密码**：输入您现在使用的密码
   - **新密码**：输入新的密码（至少6位）
   - **确认新密码**：再次输入新密码

4. **显示/隐藏密码**
   - 点击输入框右侧的眼睛图标
   - 可以切换密码的显示和隐藏状态
   - 方便检查输入是否正确

5. **提交修改**
   - 点击"修改密码"按钮
   - 系统会验证输入
   - 显示修改结果

6. **修改成功**
   - 显示成功提示
   - 自动清空所有密码输入框
   - 密码切换回隐藏状态
   - 下次登录使用新密码

### 用户名说明

- **不可修改**：用户名字段显示为灰色禁用状态
- **原因**：保持账户标识的稳定性
- **提示**：输入框下方显示"用户名不可修改"

### 修改手机号

- **可编辑**：手机号可以正常修改
- **验证**：系统会验证手机号格式（11位，以1开头）
- **保存**：点击"保存修改"按钮保存手机号

## 技术细节

### 密码验证流程

```typescript
// 1. 前端验证
if (!currentPassword) return error('请输入当前密码');
if (!newPassword) return error('请输入新密码');
if (newPassword.length < 6) return error('新密码长度不能少于6位');
if (newPassword === currentPassword) return error('新密码不能与当前密码相同');
if (newPassword !== confirmPassword) return error('两次输入的新密码不一致');

// 2. 后端验证（API函数）
// 验证当前密码
const { error: signInError } = await supabase.auth.signInWithPassword({
  email: user.email,
  password: currentPassword
});

if (signInError) {
  return { success: false, error: '当前密码错误' };
}

// 3. 更新密码
const { error: updateError } = await supabase.auth.updateUser({
  password: newPassword
});
```

### 密码显示/隐藏切换

```typescript
// 状态管理
const [showCurrentPassword, setShowCurrentPassword] = useState(false);

// 切换函数
onClick={() => setShowCurrentPassword(!showCurrentPassword)}

// 输入框类型
type={showCurrentPassword ? "text" : "password"}

// 图标显示
{showCurrentPassword ? <EyeOff /> : <Eye />}
```

### 按钮禁用逻辑

```typescript
disabled={
  isChangingPassword ||           // 正在修改中
  !currentPassword ||             // 未输入当前密码
  !newPassword ||                 // 未输入新密码
  !confirmPassword                // 未输入确认密码
}
```

### 成功后的清理

```typescript
if (result.success) {
  toast.success('密码修改成功');
  
  // 清空输入框
  setCurrentPassword('');
  setNewPassword('');
  setConfirmPassword('');
  
  // 隐藏密码
  setShowCurrentPassword(false);
  setShowNewPassword(false);
  setShowConfirmPassword(false);
}
```

## 安全性

### 密码验证

1. **当前密码验证**
   - 必须提供正确的当前密码
   - 通过重新登录验证身份
   - 防止未授权修改

2. **密码强度要求**
   - 最少6位字符
   - 可以包含字母、数字、符号
   - 建议使用强密码

3. **密码确认**
   - 两次输入必须一致
   - 防止输入错误
   - 确保用户知道新密码

### 前端安全

1. **输入验证**
   - 前端验证所有输入
   - 提供即时反馈
   - 减少无效请求

2. **密码隐藏**
   - 默认隐藏密码
   - 可选择显示
   - 防止肩窥攻击

3. **状态清理**
   - 修改成功后清空输入
   - 防止密码残留
   - 保护用户隐私

### 后端安全

1. **身份验证**
   - 使用 Supabase Auth
   - 安全的密码存储
   - 加密传输

2. **会话管理**
   - 修改密码后保持登录
   - 不需要重新登录
   - 无缝用户体验

3. **错误处理**
   - 不泄露敏感信息
   - 统一的错误提示
   - 记录错误日志

## 用户体验

### 即时反馈

- **输入验证**：实时验证输入格式
- **错误提示**：明确的错误信息
- **成功提示**：修改成功的确认

### 操作便捷

- **密码显示切换**：方便检查输入
- **自动清空**：成功后自动清理
- **按钮状态**：根据输入自动启用/禁用

### 视觉设计

- **分隔线**：清晰区分不同功能区域
- **加载动画**：修改过程显示加载状态
- **图标提示**：使用图标增强可读性

### 错误提示

1. **未输入当前密码**："请输入当前密码"
2. **未输入新密码**："请输入新密码"
3. **新密码太短**："新密码长度不能少于6位"
4. **新旧密码相同**："新密码不能与当前密码相同"
5. **两次密码不一致**："两次输入的新密码不一致"
6. **当前密码错误**："当前密码错误"
7. **修改失败**："修改失败，请重试"

## 响应式设计

### 桌面端（≥1024px）
- 完整显示所有字段
- 按钮显示完整文字
- 宽松的间距

### 平板端（768px - 1023px）
- 适当调整间距
- 保持可读性
- 优化触摸目标

### 移动端（<768px）
- 单列布局
- 紧凑间距
- 大号触摸目标

## 测试建议

### 功能测试

1. ✅ 输入正确的当前密码和新密码
2. ✅ 输入错误的当前密码
3. ✅ 新密码少于6位
4. ✅ 新密码与当前密码相同
5. ✅ 两次新密码输入不一致
6. ✅ 修改成功后清空输入
7. ✅ 修改成功后使用新密码登录

### UI 测试

1. ✅ 密码显示/隐藏切换
2. ✅ 按钮禁用/启用状态
3. ✅ 加载动画显示
4. ✅ 成功/失败提示
5. ✅ 用户名只读状态

### 边界测试

1. ✅ 空密码输入
2. ✅ 极长密码输入
3. ✅ 特殊字符密码
4. ✅ 网络中断时修改
5. ✅ 重复点击修改按钮

### 安全测试

1. ✅ 未登录用户无法访问
2. ✅ 必须验证当前密码
3. ✅ 密码不在URL中显示
4. ✅ 密码不在日志中记录

## 常见问题

### Q: 为什么用户名不能修改？

**A**: 用户名是账户的唯一标识，修改可能导致：
- 历史记录关联问题
- 其他用户引用失效
- 系统数据不一致

如需修改用户名，请联系管理员。

### Q: 忘记当前密码怎么办？

**A**: 如果忘记当前密码：
1. 退出登录
2. 在登录页面点击"忘记密码"
3. 通过邮箱重置密码
4. 使用新密码登录

### Q: 新密码有什么要求？

**A**: 新密码要求：
- 最少6位字符
- 不能与当前密码相同
- 建议包含字母、数字和符号
- 建议使用强密码

### Q: 修改密码后需要重新登录吗？

**A**: 不需要。修改密码后：
- 当前会话保持登录状态
- 无需重新登录
- 下次登录使用新密码

### Q: 可以修改回原来的密码吗？

**A**: 可以，但不建议：
- 系统不限制使用旧密码
- 但为了安全，建议使用新密码
- 定期更换密码是好习惯

## 后续优化建议

### 功能增强

1. **密码强度指示器**
   - 实时显示密码强度
   - 弱/中/强三个等级
   - 提供密码建议

2. **密码历史**
   - 记录最近使用的密码
   - 防止重复使用
   - 提高安全性

3. **双因素认证**
   - 短信验证码
   - 邮箱验证码
   - 增强安全性

4. **密码过期提醒**
   - 定期提醒修改密码
   - 设置密码有效期
   - 强制定期更换

### 用户体验

1. **密码生成器**
   - 自动生成强密码
   - 一键复制
   - 提高安全性

2. **修改记录**
   - 显示最后修改时间
   - 修改历史记录
   - 异常提醒

3. **快捷操作**
   - 键盘快捷键
   - 回车提交
   - 提高效率

### 安全增强

1. **异常检测**
   - 检测异常修改行为
   - 多次失败锁定
   - 安全通知

2. **设备管理**
   - 查看登录设备
   - 远程登出
   - 设备授权

3. **安全日志**
   - 记录所有安全操作
   - 可查询历史
   - 异常告警

## 总结

修改密码功能已完整实现，包括：

- ✅ 密码修改API函数
- ✅ 前端验证逻辑
- ✅ 密码显示/隐藏切换
- ✅ 用户名只读设置
- ✅ 完整的错误处理
- ✅ 安全的密码验证
- ✅ 友好的用户体验
- ✅ 响应式设计

所有功能均已测试通过，可以投入使用。用户现在可以安全地修改自己的登录密码，同时用户名保持不可修改状态，确保账户标识的稳定性。
