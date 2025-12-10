# 🎨 短视频拉片分析工具 - 设计指南

## 📐 设计理念

### 整体风格
**深色科技感 + 扁平化设计**

- 主背景色：`#182337` (深蓝灰色)
- 设计风格：现代、简洁、专业
- 视觉特点：扁平化、高对比度、科技感

---

## 🎨 色彩系统

### 主色调
```css
/* 主背景色 */
--background: #182337 (HSL: 215 38% 16%)

/* 卡片背景 */
--card: HSL: 215 35% 20%

/* 主色 - 科技蓝 */
--primary: HSL: 200 95% 55%
示例：#0BB5FF

/* 次要色 - 青色 */
--secondary: HSL: 180 85% 50%
示例：#13D9D9

/* 强调色 */
--accent: HSL: 195 100% 60%
示例：#33E0FF
```

### 文字颜色
```css
/* 主文字 */
--foreground: HSL: 210 20% 95%
浅灰白色，高可读性

/* 次要文字 */
--muted-foreground: HSL: 210 15% 65%
中灰色，用于辅助信息
```

### 边框颜色
```css
--border: HSL: 215 30% 28%
深灰蓝色，低调不突兀
```

---

## ✨ 视觉效果

### 1. 渐变文字
```css
.gradient-text {
  background: linear-gradient(135deg, 
    hsl(200 95% 55%), 
    hsl(180 100% 60%)
  );
  -webkit-background-clip: text;
  background-clip: text;
  -webkit-text-fill-color: transparent;
}
```
**使用场景：**
- 页面标题
- 重要标语
- Logo文字

### 2. 发光效果
```css
.tech-glow {
  box-shadow: 
    0 0 20px hsl(200 95% 55% / 0.3),
    0 0 40px hsl(200 95% 55% / 0.3);
}

.tech-glow:hover {
  box-shadow: 
    0 0 30px hsl(200 95% 55% / 0.3),
    0 0 60px hsl(200 95% 55% / 0.4);
  transform: translateY(-2px);
}
```
**使用场景：**
- 重要卡片
- 积分显示
- 特殊按钮

### 3. 科技边框
```css
.tech-border {
  border: 1px solid hsl(200 95% 55% / 0.2);
  background: hsl(215 35% 20%);
  transition: all 0.3s ease;
}

.tech-border:hover {
  border-color: hsl(200 95% 55% / 0.4);
  box-shadow: 0 4px 20px hsl(200 95% 55% / 0.15);
}
```
**使用场景：**
- 所有卡片
- 表单容器
- 内容区域

### 4. 网格背景
```css
.tech-bg::before {
  background-image: 
    linear-gradient(hsl(200 95% 55% / 0.02) 1px, transparent 1px),
    linear-gradient(90deg, hsl(200 95% 55% / 0.02) 1px, transparent 1px);
  background-size: 40px 40px;
}
```
**使用场景：**
- 页面主背景
- 大区域背景

### 5. 脉冲动画
```css
.pulse-glow {
  animation: pulse-glow 2s ease-in-out infinite;
}

@keyframes pulse-glow {
  0%, 100% {
    box-shadow: 0 0 15px hsl(200 95% 55% / 0.3);
  }
  50% {
    box-shadow: 0 0 30px hsl(200 95% 55% / 0.5);
  }
}
```
**使用场景：**
- Logo图标
- 重要提示
- 吸引注意力的元素

---

## 🧩 组件设计规范

### 1. 卡片 (Card)
```tsx
<Card className="tech-border shadow-lg">
  <CardHeader>
    <CardTitle>标题</CardTitle>
    <CardDescription>描述</CardDescription>
  </CardHeader>
  <CardContent>
    内容
  </CardContent>
</Card>
```

**设计特点：**
- 扁平化设计，无过度阴影
- 细边框，颜色为 `primary/20`
- 悬停时边框变亮，添加轻微阴影
- 背景色为 `card`

### 2. 按钮 (Button)
```tsx
{/* 主按钮 */}
<Button variant="default">
  主要操作
</Button>

{/* 次要按钮 */}
<Button variant="outline">
  次要操作
</Button>

{/* 幽灵按钮 */}
<Button variant="ghost">
  辅助操作
</Button>
```

**设计特点：**
- 扁平化，无渐变
- 主按钮使用 `primary` 色
- 边框按钮透明背景，悬停时填充
- 过渡动画流畅

### 3. 图标容器
```tsx
{/* 圆形图标 */}
<div className="w-12 h-12 rounded-full bg-primary/10 border border-primary/30 flex items-center justify-center">
  <Icon className="w-6 h-6 text-primary" />
</div>

{/* 方形图标 */}
<div className="w-12 h-12 rounded-lg bg-primary/10 border border-primary/30 flex items-center justify-center">
  <Icon className="w-6 h-6 text-primary" />
</div>
```

**设计特点：**
- 半透明背景 `primary/10`
- 细边框 `primary/30`
- 图标颜色为 `primary`
- 可添加 `pulse-glow` 动画

### 4. 输入框 (Input)
```tsx
<Input 
  type="text" 
  placeholder="请输入..."
  className="bg-card border-border"
/>
```

**设计特点：**
- 深色背景
- 细边框
- 聚焦时边框变为 `primary`
- 占位符文字为 `muted-foreground`

### 5. 标签 (Badge)
```tsx
<Badge variant="default">
  推荐
</Badge>

<Badge variant="outline">
  标签
</Badge>
```

**设计特点：**
- 扁平化设计
- 主标签使用 `primary` 背景
- 边框标签透明背景

---

## 📱 响应式设计

### 断点
```css
/* 移动端 */
@media (max-width: 768px) {
  /* 单列布局 */
}

/* 平板 */
@media (min-width: 768px) and (max-width: 1024px) {
  /* 两列布局 */
}

/* 桌面端 */
@media (min-width: 1024px) {
  /* 三列或多列布局 */
}
```

### 适配原则
1. **移动优先**：从小屏幕开始设计
2. **弹性布局**：使用 Flexbox 和 Grid
3. **相对单位**：使用 rem、em、%
4. **触摸友好**：按钮至少 44x44px

---

## 🎯 页面布局

### 1. Header (顶部导航)
- 高度：64px (h-16)
- 背景：半透明卡片色 + 毛玻璃效果
- 边框：底部细边框
- 阴影：轻微阴影
- 固定定位：sticky top-0

### 2. 主内容区
- 最大宽度：7xl (1280px)
- 内边距：px-4 py-8
- 背景：tech-bg (网格背景)

### 3. 卡片间距
- 卡片之间：gap-6 (24px)
- 卡片内边距：p-6 (24px)
- 小间距：gap-4 (16px)

---

## 🔤 字体系统

### 字号
```css
/* 超大标题 */
text-5xl: 3rem (48px)

/* 大标题 */
text-3xl: 1.875rem (30px)

/* 中标题 */
text-2xl: 1.5rem (24px)

/* 小标题 */
text-xl: 1.25rem (20px)

/* 正文 */
text-base: 1rem (16px)

/* 小字 */
text-sm: 0.875rem (14px)

/* 超小字 */
text-xs: 0.75rem (12px)
```

### 字重
```css
font-bold: 700
font-semibold: 600
font-medium: 500
font-normal: 400
```

---

## 🎭 动画效果

### 过渡时间
```css
/* 快速 */
transition: all 0.2s ease;

/* 标准 */
transition: all 0.3s ease;

/* 慢速 */
transition: all 0.5s ease;
```

### 常用动画
```css
/* 悬停上移 */
hover:transform: translateY(-2px);

/* 悬停放大 */
hover:scale: 1.05;

/* 淡入淡出 */
opacity: 0 → 1;
```

---

## 📐 间距系统

### Tailwind 间距
```css
gap-2: 8px
gap-3: 12px
gap-4: 16px
gap-6: 24px
gap-8: 32px

p-2: 8px
p-4: 16px
p-6: 24px
p-8: 32px

m-2: 8px
m-4: 16px
m-6: 24px
m-8: 32px
```

---

## 🎨 特殊场景

### 1. 推荐套餐高亮
```tsx
<Card className="tech-border border-primary/50 shadow-xl scale-105 ring-2 ring-primary/20">
  {/* 内容 */}
</Card>
```

### 2. 管理员标识
```tsx
<Badge variant="default" className="gap-1">
  <Shield className="w-3 h-3" />
  管理员
</Badge>
```

### 3. 积分显示
```tsx
<div className="text-2xl font-bold text-primary">
  {points}
</div>
```

### 4. 数据表格
```tsx
<Table>
  <TableHeader>
    <TableRow>
      <TableHead>列名</TableHead>
    </TableRow>
  </TableHeader>
  <TableBody>
    <TableRow>
      <TableCell>数据</TableCell>
    </TableRow>
  </TableBody>
</Table>
```

---

## ✅ 设计检查清单

### 视觉一致性
- [ ] 所有卡片使用 `tech-border`
- [ ] 图标容器使用统一样式
- [ ] 按钮使用标准变体
- [ ] 颜色使用语义化 token

### 交互反馈
- [ ] 悬停状态明显
- [ ] 点击有反馈
- [ ] 加载有提示
- [ ] 错误有提示

### 响应式
- [ ] 移动端可用
- [ ] 平板端优化
- [ ] 桌面端完整

### 可访问性
- [ ] 对比度足够
- [ ] 可键盘操作
- [ ] 有语义化标签
- [ ] 有错误提示

---

## 🚀 最佳实践

### 1. 使用语义化颜色
```tsx
// ✅ 正确
<div className="bg-primary text-primary-foreground">

// ❌ 错误
<div className="bg-blue-500 text-white">
```

### 2. 使用工具类
```tsx
// ✅ 正确
<Card className="tech-border">

// ❌ 错误
<Card style={{ border: '1px solid rgba(11, 181, 255, 0.2)' }}>
```

### 3. 保持一致性
```tsx
// ✅ 正确 - 所有图标容器样式一致
<div className="w-12 h-12 rounded-lg bg-primary/10 border border-primary/30">

// ❌ 错误 - 样式不一致
<div className="w-10 h-10 rounded bg-blue-100">
```

### 4. 合理使用动画
```tsx
// ✅ 正确 - 重要元素使用动画
<div className="pulse-glow">

// ❌ 错误 - 过度使用动画
<div className="animate-bounce animate-spin animate-pulse">
```

---

## 📚 参考资源

### 设计系统
- Tailwind CSS: https://tailwindcss.com
- shadcn/ui: https://ui.shadcn.com

### 颜色工具
- HSL 转换器: https://www.w3schools.com/colors/colors_hsl.asp
- 对比度检查: https://webaim.org/resources/contrastchecker/

### 图标库
- Lucide React: https://lucide.dev

---

**设计版本：** v1.0  
**更新日期：** 2025-12-03  
**设计师：** 秒哒AI助手
