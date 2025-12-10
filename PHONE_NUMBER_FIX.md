# 手机号显示修复说明

## 问题描述

个人资料页面中的手机号字段没有显示用户注册时填写的手机号，导致用户需要重新输入手机号。

## 问题原因

1. **注册函数未传递手机号**
   - `signUpWithUsername` 函数只接收用户名和密码
   - 注册时没有将手机号传递给 Supabase Auth

2. **触发器未获取手机号**
   - `handle_new_user` 触发器函数尝试从 `NEW.phone` 获取手机号
   - 但 auth.users 表中没有 phone 字段
   - 手机号应该从 `raw_user_meta_data` 中获取

## 解决方案

### 1. 修改注册 API 函数

在 `src/db/api.ts` 中修改 `signUpWithUsername` 函数：

**修改前**：
```typescript
export async function signUpWithUsername(username: string, password: string) {
  const email = `${username}@miaoda.com`;

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        username
      }
    }
  });

  return { data, error };
}
```

**修改后**：
```typescript
export async function signUpWithUsername(username: string, password: string, phone?: string) {
  const email = `${username}@miaoda.com`;

  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        username,
        phone: phone || null  // 添加手机号到 metadata
      }
    }
  });

  return { data, error };
}
```

**变更说明**：
- 添加可选的 `phone` 参数
- 将手机号保存到用户的 `raw_user_meta_data` 中
- 如果没有提供手机号，则保存为 null

### 2. 修改注册页面调用

在 `src/pages/Login.tsx` 中修改注册函数调用：

**修改前**：
```typescript
const { data, error } = await signUpWithUsername(signupUsername, signupPassword);
```

**修改后**：
```typescript
const { data, error } = await signUpWithUsername(signupUsername, signupPassword, signupPhone);
```

**变更说明**：
- 注册时传递用户填写的手机号
- 手机号将保存到用户的 metadata 中

### 3. 更新数据库触发器

创建迁移文件 `supabase/migrations/00004_update_user_trigger_for_phone.sql`：

**修改前**：
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  user_count int;
  user_name text;
BEGIN
  -- 统计已有用户数
  SELECT COUNT(*) INTO user_count FROM profiles;
  
  -- 从 email 中提取用户名
  user_name := REPLACE(NEW.email, '@miaoda.com', '');
  
  -- 插入新用户
  INSERT INTO profiles (id, username, phone, email, role, points)
  VALUES (
    NEW.id,
    user_name,
    NEW.phone,  -- ❌ auth.users 表中没有 phone 字段
    NEW.email,
    CASE WHEN user_count = 0 THEN 'admin'::user_role ELSE 'user'::user_role END,
    100
  );
  
  RETURN NEW;
END;
$$;
```

**修改后**：
```sql
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  user_count int;
  user_name text;
  user_phone text;  -- ✅ 添加手机号变量
BEGIN
  -- 统计已有用户数
  SELECT COUNT(*) INTO user_count FROM profiles;
  
  -- 从 email 中提取用户名
  user_name := REPLACE(NEW.email, '@miaoda.com', '');
  
  -- 从 raw_user_meta_data 中获取手机号
  user_phone := NEW.raw_user_meta_data->>'phone';  -- ✅ 从 metadata 获取
  
  -- 插入新用户
  INSERT INTO profiles (id, username, phone, email, role, points)
  VALUES (
    NEW.id,
    user_name,
    user_phone,  -- ✅ 使用从 metadata 获取的手机号
    NEW.email,
    CASE WHEN user_count = 0 THEN 'admin'::user_role ELSE 'user'::user_role END,
    100
  );
  
  RETURN NEW;
END;
$$;
```

**变更说明**：
- 添加 `user_phone` 变量
- 使用 `NEW.raw_user_meta_data->>'phone'` 从用户 metadata 中获取手机号
- 将获取到的手机号保存到 profiles 表

## 数据流程

### 注册流程

```
用户填写注册表单
    ↓
输入：用户名、密码、手机号、验证码
    ↓
前端验证通过
    ↓
调用 signUpWithUsername(username, password, phone)
    ↓
Supabase Auth 创建用户
    ↓
用户数据保存到 auth.users 表
    ├─ email: username@miaoda.com
    ├─ encrypted_password: ******
    └─ raw_user_meta_data: { username, phone }
    ↓
触发 on_auth_user_confirmed 触发器
    ↓
执行 handle_new_user() 函数
    ├─ 提取用户名：从 email 中去掉 @miaoda.com
    ├─ 提取手机号：从 raw_user_meta_data->>'phone'
    └─ 插入 profiles 表
    ↓
profiles 表记录
    ├─ id: user_id
    ├─ username: 用户名
    ├─ phone: 手机号 ✅
    ├─ email: username@miaoda.com
    ├─ role: user/admin
    └─ points: 100
```

### 个人资料加载流程

```
用户访问个人中心
    ↓
调用 getCurrentUser()
    ↓
从 profiles 表查询用户信息
    ↓
返回用户数据（包含手机号）
    ↓
显示在个人资料表单中
    ├─ 用户名：只读显示
    ├─ 手机号：显示注册时的手机号 ✅
    └─ 头像：显示用户头像
```

## 技术细节

### Supabase Auth Metadata

Supabase Auth 提供了两个字段用于存储用户自定义数据：

1. **user_metadata**
   - 用户可以自己修改
   - 通过 `updateUser()` 更新
   - 存储用户偏好设置

2. **raw_user_meta_data**
   - 注册时设置
   - 只能通过管理员 API 修改
   - 存储注册时的初始数据

我们使用 `raw_user_meta_data` 存储手机号，因为：
- 注册时设置，不会丢失
- 可以在触发器中访问
- 保持数据一致性

### PostgreSQL JSON 操作符

```sql
-- 获取 JSON 对象中的字段值（返回 text）
NEW.raw_user_meta_data->>'phone'

-- 示例数据
raw_user_meta_data = {
  "username": "testuser",
  "phone": "13800138000"
}

-- 结果
NEW.raw_user_meta_data->>'phone' = '13800138000'
```

### 触发器执行时机

```sql
CREATE TRIGGER on_auth_user_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  WHEN (OLD.confirmed_at IS NULL AND NEW.confirmed_at IS NOT NULL)
  EXECUTE FUNCTION handle_new_user();
```

**触发条件**：
- 在 auth.users 表更新后触发
- 仅当 confirmed_at 从 NULL 变为非 NULL 时
- 即用户确认邮箱（或自动确认）时

**为什么不用 INSERT 触发器**：
- Supabase 默认需要邮箱确认
- 用户创建时 confirmed_at 为 NULL
- 确认后才应该创建 profile 记录

## 测试验证

### 测试步骤

1. **新用户注册**
   ```
   1. 访问登录页面
   2. 切换到"注册"标签
   3. 填写用户名：testuser
   4. 填写密码：test123456
   5. 填写手机号：13800138000
   6. 获取验证码
   7. 输入验证码
   8. 点击注册
   ```

2. **验证手机号保存**
   ```
   1. 注册成功后自动登录
   2. 进入个人中心
   3. 查看个人资料标签页
   4. 确认手机号显示为：13800138000 ✅
   ```

3. **验证数据库记录**
   ```sql
   -- 查询 profiles 表
   SELECT id, username, phone, email, role, points
   FROM profiles
   WHERE username = 'testuser';
   
   -- 预期结果
   id: [uuid]
   username: testuser
   phone: 13800138000  ✅
   email: testuser@miaoda.com
   role: user
   points: 100
   ```

### 测试场景

#### 场景 1：正常注册（提供手机号）
- **输入**：用户名、密码、手机号、验证码
- **预期**：profiles 表中 phone 字段有值
- **结果**：✅ 通过

#### 场景 2：修改手机号
- **操作**：在个人资料中修改手机号
- **预期**：可以成功修改并保存
- **结果**：✅ 通过

#### 场景 3：已有用户（无手机号）
- **情况**：迁移前注册的用户
- **预期**：phone 字段为 NULL，可以手动填写
- **结果**：✅ 通过

## 影响范围

### 新用户
- ✅ 注册时填写的手机号会自动保存
- ✅ 个人资料页面会显示注册时的手机号
- ✅ 可以在个人资料中修改手机号

### 已有用户
- ⚠️ 迁移前注册的用户手机号为空
- ✅ 可以在个人资料中填写手机号
- ✅ 填写后会正常保存和显示

### 数据库
- ✅ 触发器函数已更新
- ✅ 新注册用户会正确保存手机号
- ✅ 不影响已有数据

## 后续优化建议

### 1. 数据迁移脚本

为已有用户提供手机号迁移功能：

```sql
-- 如果 auth.users 的 metadata 中有手机号，但 profiles 中没有
UPDATE profiles p
SET phone = (
  SELECT au.raw_user_meta_data->>'phone'
  FROM auth.users au
  WHERE au.id = p.id
)
WHERE p.phone IS NULL
  AND EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = p.id
      AND au.raw_user_meta_data->>'phone' IS NOT NULL
  );
```

### 2. 手机号验证

在修改手机号时添加验证码验证：

```typescript
// 修改手机号流程
1. 用户输入新手机号
2. 发送验证码到新手机号
3. 用户输入验证码
4. 验证通过后更新手机号
```

### 3. 手机号唯一性

添加唯一性约束，防止重复：

```sql
-- 添加唯一约束
ALTER TABLE profiles
ADD CONSTRAINT profiles_phone_unique
UNIQUE (phone);

-- 创建部分索引（忽略 NULL）
CREATE UNIQUE INDEX profiles_phone_unique_idx
ON profiles (phone)
WHERE phone IS NOT NULL;
```

### 4. 手机号格式验证

在数据库层面添加格式验证：

```sql
-- 添加检查约束
ALTER TABLE profiles
ADD CONSTRAINT profiles_phone_format_check
CHECK (phone IS NULL OR phone ~ '^1[3-9]\d{9}$');
```

## 常见问题

### Q: 为什么已有用户的手机号是空的？

**A**: 因为：
1. 迁移前的注册流程没有保存手机号
2. 触发器函数没有正确获取手机号
3. 现在已经修复，新注册用户会正常保存

**解决方案**：
- 已有用户可以在个人资料中手动填写手机号
- 或者运行数据迁移脚本（如果 metadata 中有）

### Q: 修改手机号需要验证吗？

**A**: 当前版本不需要验证：
- 用户可以直接修改手机号
- 建议后续添加验证码验证
- 提高安全性

### Q: 手机号可以重复吗？

**A**: 当前版本可以重复：
- 数据库没有唯一性约束
- 建议后续添加唯一约束
- 防止手机号被多个账号使用

### Q: 注册时必须填写手机号吗？

**A**: 是的：
- 前端表单验证要求必填
- 需要通过短信验证码验证
- 确保手机号真实有效

## 总结

### 修改内容

1. ✅ 修改 `signUpWithUsername` 函数，添加 phone 参数
2. ✅ 修改注册页面，传递手机号参数
3. ✅ 更新数据库触发器，从 metadata 获取手机号
4. ✅ 应用数据库迁移

### 解决的问题

1. ✅ 注册时手机号未保存
2. ✅ 个人资料页面手机号为空
3. ✅ 用户需要重新输入手机号

### 验证结果

1. ✅ 新用户注册时手机号正确保存
2. ✅ 个人资料页面显示注册时的手机号
3. ✅ 用户可以修改手机号
4. ✅ 代码通过 lint 检查
5. ✅ 数据库迁移成功应用

现在用户注册时填写的手机号会正确保存到数据库，并在个人资料页面中显示，无需重新输入。
