# 技术栈说明

## 🎯 项目概述

短视频拉片分析工具 - 基于百度智能云AI技术的专业视频分析平台

## 🔧 核心技术栈

### 前端框架
- **React 18** - 现代化的UI框架
- **TypeScript** - 类型安全的开发体验
- **Vite** - 快速的构建工具
- **Tailwind CSS** - 实用优先的CSS框架
- **shadcn/ui** - 高质量的React组件库

### 百度智能云AI服务

#### 1. 图像内容理解API
**用途：** 视频画面分析

**功能：**
- 自动识别视频关键帧
- 分析镜头内容（场景、人物、动作）
- 识别拍摄手法（景别、角度、运动方式）
- 提取视觉元素（色彩、光线、构图）

**API端点：**
- 提交请求：`/rest/2.0/image-classify/v1/image-understanding/request`
- 获取结果：`/rest/2.0/image-classify/v1/image-understanding/get-result`

**实现文件：**
- `src/services/imageAnalysis.ts`
- `src/pages/Home.tsx`

#### 2. 短语音识别API
**用途：** 视频音频分析

**功能：**
- 提取视频音频轨道
- 识别语音内容
- 转换为文字
- 整合到画面分析中

**API端点：**
- `/rest/2.0/speech/v1/asr`

**实现文件：**
- `src/services/speechRecognition.ts`
- `src/utils/audioProcessor.ts`

#### 3. 自然语言处理NLP API
**用途：** AI提示词生成

**功能：**
- 基于视频分析结果
- 智能生成AI视频提示词
- 流式输出，实时显示
- 支持重新生成和优化

**API端点：**
- `/v2/chat/completions`

**实现文件：**
- `src/components/video/PromptGenerator.tsx`
- `src/services/chatStream.ts`

## 🎨 设计系统

### 配色方案
**主题：** 科技感深蓝色系

**颜色定义：**
```css
--primary: 220 85% 45%        /* 深蓝色 */
--primary-glow: 195 85% 55%   /* 青色光晕 */
--secondary: 195 75% 50%      /* 青色 */
--accent: 195 85% 55%         /* 强调色 */
```

### 视觉特效
- **渐变文字** - `.gradient-text`
- **发光效果** - `.tech-glow`
- **科技边框** - `.tech-border`
- **脉冲动画** - `.pulse-glow`
- **网格背景** - `.tech-bg`
- **流光动画** - `shimmer`

### 组件样式
- 卡片式布局
- 8px圆角设计
- 渐变背景
- 悬停动画
- 响应式设计

## 📁 项目结构

```
src/
├── components/
│   ├── ui/                    # shadcn/ui组件
│   ├── video/                 # 视频相关组件
│   │   ├── VideoUploader.tsx  # 视频上传
│   │   ├── ShotAnalysisDisplay.tsx  # 分析结果展示
│   │   └── PromptGenerator.tsx      # 提示词生成
│   └── common/                # 通用组件
├── services/
│   ├── imageAnalysis.ts       # 图像分析API
│   ├── speechRecognition.ts   # 语音识别API
│   └── chatStream.ts          # NLP流式API
├── utils/
│   ├── videoProcessor.ts      # 视频处理工具
│   └── audioProcessor.ts      # 音频处理工具
├── pages/
│   └── Home.tsx               # 主页面
├── types/
│   └── video.ts               # 类型定义
└── index.css                  # 全局样式和设计系统
```

## 🔄 工作流程

### 1. 视频上传
```
用户选择视频 → 验证格式 → 加载到内存
```

### 2. 关键帧提取（0-10%）
```
解析视频 → 提取关键帧 → 转换为Base64
```

### 3. 音频分析（10-30%）
```
提取音频 → 转换格式 → 分段识别 → 整合结果
```

### 4. 画面分析（30-80%）
```
for each 关键帧:
  提交图像分析请求 → 轮询结果 → 解析描述 → 更新进度
```

### 5. 生成总结（80-100%）
```
整合所有分析 → 生成整体描述 → 显示结果
```

### 6. 提示词生成
```
用户点击生成 → 调用NLP API → 流式输出 → 显示结果
```

## 🚀 性能优化

### 视频处理
- 限制视频时长（建议60秒内）
- 智能提取关键帧（避免冗余）
- 异步处理，不阻塞UI

### 音频处理
- 采样率转换（16000Hz）
- 分段处理（60秒/段）
- 错误容错（无音频也能继续）

### API调用
- 轮询机制（2秒间隔）
- 超时控制（60秒）
- 错误重试
- 详细日志

### UI渲染
- 流式输出（实时显示）
- 虚拟滚动（大量数据）
- 懒加载图片
- CSS动画（GPU加速）

## 🛡️ 错误处理

### 网络错误
- HTTP状态检查
- 超时处理
- 友好提示

### API错误
- 状态码判断
- 错误消息解析
- 用户提示

### 数据错误
- 类型验证
- 空值保护
- 默认值处理

## 📊 监控和调试

### 控制台日志
- 每个关键步骤都有日志
- 详细的错误信息
- 进度跟踪
- 性能指标

### 用户反馈
- Toast通知
- 进度条
- 加载状态
- 错误提示

## 🔐 安全性

### API密钥
- 环境变量管理
- 不暴露在客户端
- 通过代理服务器调用

### 数据处理
- 客户端处理
- 不上传原始视频
- 只传输必要数据

## 📱 响应式设计

### 断点
- 移动端：< 768px
- 平板：768px - 1024px
- 桌面：> 1024px

### 适配
- 弹性布局
- 响应式网格
- 自适应字体
- 触摸优化

## 🎯 浏览器支持

### 推荐
- Chrome 90+
- Edge 90+
- Firefox 88+
- Safari 14+

### 必需特性
- ES6+
- Web Audio API
- Canvas API
- Fetch API
- Async/Await

## 📦 依赖管理

### 核心依赖
```json
{
  "react": "^18.x",
  "typescript": "^5.x",
  "tailwindcss": "^3.x",
  "lucide-react": "图标库",
  "streamdown": "Markdown流式渲染",
  "sonner": "Toast通知"
}
```

### 开发依赖
```json
{
  "vite": "构建工具",
  "eslint": "代码检查",
  "@typescript-eslint": "TS检查"
}
```

## 🔧 环境变量

```env
VITE_APP_ID=应用ID
VITE_API_ENV=环境标识
```

## 📈 未来优化

### 功能增强
- [ ] 批量视频分析
- [ ] 分析历史记录
- [ ] 导出分析报告
- [ ] 自定义提示词模板
- [ ] 视频预览播放

### 性能优化
- [ ] WebWorker处理
- [ ] IndexedDB缓存
- [ ] CDN加速
- [ ] 懒加载优化
- [ ] 代码分割

### 用户体验
- [ ] 拖拽上传
- [ ] 进度详情
- [ ] 取消分析
- [ ] 快捷键支持
- [ ] 暗色模式切换

---

**技术栈版本：** v2.0  
**最后更新：** 2025-12-03  
**维护状态：** ✅ 活跃开发中
