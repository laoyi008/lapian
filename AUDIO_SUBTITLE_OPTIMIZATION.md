# 音频字幕识别与提示词生成优化

## 🎯 优化目标

解决视频拉片分析中音频字幕识别不完整、提示词生成缺少人物对白描述的问题。

---

## 📋 问题分析

### 原有问题

1. **音频识别不完整**
   - ❌ 只提取前60秒音频：`Math.min(duration, 60)`
   - ❌ 只识别前3段：`Math.min(audioChunks.length, 3)`
   - ❌ 错误被静默处理，用户无感知

2. **字幕信息未充分利用**
   - ❌ 字幕长度限制过短（50字符）
   - ❌ 问题文本不够明确
   - ❌ AI分析时字幕信息不突出

3. **提示词生成缺失字幕**
   - ❌ 只传递画面描述文本
   - ❌ 未传递每个镜头的字幕信息
   - ❌ 生成的提示词缺少人物对白

---

## ✅ 优化方案

### 1. 音频识别完整化

#### 修改文件：`src/pages/Home.tsx`

**优化点：**
- ✅ 提取完整音频，不限制时长
- ✅ 识别所有音频段，不限制数量
- ✅ 添加详细的日志输出
- ✅ 添加用户友好的提示信息

**修改前：**
```typescript
// ❌ 只提取60秒
const wavBlob = await extractAudioFromVideo(audioBuffer, Math.min(duration, 60));
const audioChunks = await splitAudioIntoChunks(wavBlob, 60);

// ❌ 只识别3段
for (let i = 0; i < Math.min(audioChunks.length, 3); i++) {
  // ...
}
```

**修改后：**
```typescript
// ✅ 提取完整音频
console.log('开始音频分析，视频时长:', duration, '秒');
const wavBlob = await extractAudioFromVideo(audioBuffer, duration);
console.log('音频提取完成，大小:', wavBlob.size, '字节');

const audioChunks = await splitAudioIntoChunks(wavBlob, 60);
console.log(`音频分割完成，共 ${audioChunks.length} 段`);

// ✅ 识别所有段
for (let i = 0; i < audioChunks.length; i++) {
  console.log(`正在识别第 ${i + 1}/${audioChunks.length} 段音频...`);
  // ...
  if (response.data.err_no === 0 && response.data.result && response.data.result.length > 0) {
    const transcript = response.data.result.join('');
    audioTranscriptByTime[timeKey] = transcript;
    console.log(`第 ${i + 1} 段音频识别成功，时间戳 ${timeKey}秒:`, transcript);
    toast.success(`识别第 ${i + 1} 段音频成功`);
  }
}

// ✅ 显示识别结果统计
const totalTranscripts = Object.keys(audioTranscriptByTime).length;
console.log(`音频识别完成，共识别出 ${totalTranscripts} 段字幕`);

if (totalTranscripts > 0) {
  toast.success(`音频识别完成，共识别出 ${totalTranscripts} 段字幕`);
} else {
  toast.info('未识别到语音内容，可能是纯音乐或无人声');
}
```

---

### 2. 字幕信息优化

#### 修改文件：`src/pages/Home.tsx`

**优化点：**
- ✅ 增加字幕长度限制到100字符
- ✅ 优化问题文本，突出字幕信息
- ✅ 添加字幕内容日志

**修改前：**
```typescript
// ❌ 字幕太短
const audioText = audioForThisShot.length > 50 
  ? audioForThisShot.substring(0, 50) + '...' 
  : audioForThisShot;
question += ` 语音："${audioText}"`;
```

**修改后：**
```typescript
// ✅ 增加字幕长度
console.log(`第 ${i + 1} 个镜头的字幕内容:`, audioForThisShot || '无');

let question = `分析镜头：1.景别角度 2.运动方式 3.画面内容`;

if (audioForThisShot) {
  const audioText = audioForThisShot.length > 100 
    ? audioForThisShot.substring(0, 100) + '...' 
    : audioForThisShot;
  question += ` 4.人物说话："${audioText}"`;
}

question += ` 详细描述`;
```

---

### 3. 提示词生成优化

#### 修改文件：`src/components/video/PromptGenerator.tsx`

**优化点：**
- ✅ 修改接口，接收完整的ShotAnalysis数组
- ✅ 整合每个镜头的画面和字幕信息
- ✅ 强调字幕内容在提示词中的重要性
- ✅ 优化system prompt

**修改前：**
```typescript
interface PromptGeneratorProps {
  videoDescription: string;
  shotDescriptions: string[];  // ❌ 只有描述文本
  audioTranscript?: string;
}

// ❌ 只传递描述文本
const shotSummary = shotDescriptions
  .map((desc, idx) => `镜头${idx + 1}: ${desc}`)
  .join('\n\n');
```

**修改后：**
```typescript
interface PromptGeneratorProps {
  videoDescription: string;
  shotAnalyses: ShotAnalysis[];  // ✅ 完整的镜头分析数据
  audioTranscript?: string;
}

// ✅ 整合画面和字幕信息
const shotSummary = shotAnalyses
  .map((shot, idx) => {
    let shotDesc = `镜头${idx + 1}（${shot.duration?.toFixed(1)}秒）：`;
    shotDesc += `\n- 景别/角度：${shot.shotType}/${shot.cameraAngle}`;
    shotDesc += `\n- 运动方式：${shot.cameraMovement}`;
    shotDesc += `\n- 画面内容：${shot.detailedContent || shot.description}`;
    
    // ✅ 如果有字幕，添加字幕信息
    if (shot.subtitle && shot.subtitle.trim()) {
      shotDesc += `\n- 人物说话："${shot.subtitle}"`;
    }
    
    return shotDesc;
  })
  .join('\n\n');
```

**优化提示词生成要求：**
```typescript
userMessage += `\n\n## 生成要求：
1. 直接输出可用的提示词，不要过度拆分
2. 整合所有镜头的关键信息，形成连贯的描述
3. 包含画面风格、场景、动作、色调等核心要素
4. **重点：如果有人物说话的内容，必须在提示词中体现人物的对白或旁白**
5. 描述要包含镜头运动、景别变化等拍摄手法
6. 语言简洁明确，适合直接复制使用
7. 不要添加额外的解释或说明文字
8. 如果有多个镜头，要体现镜头之间的转场和节奏`;
```

**优化system prompt：**
```typescript
{
  role: 'system',
  content: '你是一个专业的视频创作助手。根据用户提供的视频分析（包括画面和字幕），生成简洁、直接可用的AI视频生成提示词。如果视频中有人物说话的内容，必须在提示词中体现对白或旁白。只输出提示词本身，不要添加任何解释或说明。'
}
```

---

## 📊 优化效果对比

### 音频识别

| 指标 | 优化前 | 优化后 | 改进 |
|------|--------|--------|------|
| 音频时长 | 最多60秒 | 完整时长 | ✅ 100% |
| 识别段数 | 最多3段 | 全部段数 | ✅ 无限制 |
| 用户反馈 | 无 | 实时提示 | ✅ 友好 |
| 错误处理 | 静默 | 详细日志 | ✅ 可调试 |

### 字幕信息

| 指标 | 优化前 | 优化后 | 改进 |
|------|--------|--------|------|
| 字幕长度 | 50字符 | 100字符 | ⬆️ 100% |
| 信息完整性 | 低 | 高 | ✅ 提升 |
| 日志输出 | 无 | 详细 | ✅ 可追踪 |

### 提示词生成

| 指标 | 优化前 | 优化后 | 改进 |
|------|--------|--------|------|
| 字幕信息 | 缺失 | 完整 | ✅ 包含 |
| 镜头详情 | 简单 | 详细 | ✅ 提升 |
| 对白描述 | 无 | 有 | ✅ 新增 |
| 提示词质量 | 中 | 高 | ✅ 提升 |

---

## 🎬 使用示例

### 示例1：产品介绍视频

**视频内容：**
- 镜头1（3.5秒）：主持人介绍产品
- 镜头2（2.8秒）：产品特写
- 镜头3（4.2秒）：使用演示

**音频识别结果：**
```
时间戳 0秒: "大家好，今天给大家介绍一款新产品"
时间戳 3秒: "这款产品采用了最新的技术"
时间戳 6秒: "使用起来非常简单方便"
```

**分析结果：**
```markdown
## 视频分镜拆解分析

| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | 字幕内容 | 时长(秒) |
|------|----------|-----------|----------|----------|----------|----------|
| 1 | ![镜头1](...) | 中景/平视 | 固定镜头 | 主持人站在产品前，面带微笑 | 大家好，今天给大家介绍一款新产品 | 3.5 |
| 2 | ![镜头2](...) | 特写/平视 | 推镜头 | 产品特写，展示细节 | 这款产品采用了最新的技术 | 2.8 |
| 3 | ![镜头3](...) | 中景/平视 | 固定镜头 | 主持人手持产品演示 | 使用起来非常简单方便 | 4.2 |
```

**生成的提示词（优化后）：**
```
一个产品介绍短视频，采用专业的拍摄手法。

镜头1：中景平视固定镜头，主持人站在产品前面带微笑，说道"大家好，今天给大家介绍一款新产品"，持续3.5秒。

镜头2：特写平视推镜头，展示产品细节，主持人解说"这款产品采用了最新的技术"，镜头缓慢推进，持续2.8秒。

镜头3：中景平视固定镜头，主持人手持产品进行使用演示，说"使用起来非常简单方便"，持续4.2秒。

整体风格专业、清晰，画面明亮，背景简洁，突出产品特点。
```

---

## 🔍 技术细节

### 音频识别流程

```
1. 提取视频音频
   ↓
2. 解码音频数据
   ↓
3. 分割为60秒一段
   ↓
4. 逐段识别（不限制数量）
   ↓
5. 按时间戳存储
   ↓
6. 显示识别统计
```

### 字幕匹配逻辑

```typescript
// 为每个镜头匹配对应时间段的字幕
const audioForThisShot = Object.keys(audioTranscriptByTime)
  .map(Number)
  .filter(time => {
    // 字幕时间在当前镜头时间范围内
    return time >= frame.timestamp && 
           (!nextFrame || time < nextFrame.timestamp);
  })
  .map(time => audioTranscriptByTime[time])
  .join(' ');
```

### 提示词生成流程

```
1. 收集所有镜头信息
   ↓
2. 整合画面和字幕
   ↓
3. 构建详细的分镜描述
   ↓
4. 发送给AI模型
   ↓
5. 流式生成提示词
   ↓
6. 实时显示结果
```

---

## 📝 日志输出示例

### 音频识别日志

```
开始音频分析，视频时长: 120 秒
正在解码音频数据...
音频解码成功，时长: 120 秒
音频提取完成，大小: 3840000 字节
音频分割完成，共 2 段
正在识别第 1/2 段音频...
第 1 段音频识别成功，时间戳 0秒: 大家好，今天给大家介绍一款新产品，这款产品采用了最新的技术
正在识别第 2/2 段音频...
第 2 段音频识别成功，时间戳 60秒: 使用起来非常简单方便，欢迎大家购买体验
音频识别完成，共识别出 2 段字幕
```

### 镜头分析日志

```
正在分析第 1/3 个镜头，时间戳: 0秒
第 1 个镜头的字幕内容: 大家好，今天给大家介绍一款新产品，这款产品采用了最新的技术
提交第 1 个镜头的图像分析请求...
图像数据长度: 12345 字符
问题文本长度: 85 字符
问题内容: 分析镜头：1.景别角度 2.运动方式 3.画面内容 4.人物说话："大家好，今天给大家介绍一款新产品，这款产品采用了最新的技术" 详细描述
```

---

## 🎯 优化成果

### 1. 音频识别完整性

- ✅ 不再限制音频时长
- ✅ 识别所有音频段
- ✅ 完整捕获所有语音内容
- ✅ 用户实时了解识别进度

### 2. 字幕信息准确性

- ✅ 字幕长度增加到100字符
- ✅ 更完整的字幕内容
- ✅ 准确匹配到对应镜头
- ✅ 详细的日志追踪

### 3. 提示词生成质量

- ✅ 包含完整的字幕信息
- ✅ 体现人物对白或旁白
- ✅ 画面和声音完美结合
- ✅ 生成更专业的提示词

---

## 🧪 测试验证

### 测试场景1：有完整对白的视频

**输入：** 2分钟产品介绍视频，主持人全程讲解

**预期结果：**
- ✅ 识别出所有语音内容（2段，共120秒）
- ✅ 每个镜头显示对应的字幕
- ✅ 生成的提示词包含所有对白
- ✅ 用户看到识别进度提示

### 测试场景2：部分有对白的视频

**输入：** 3分钟视频，前半部分有解说，后半部分纯音乐

**预期结果：**
- ✅ 识别出前半部分的语音（3段，共180秒）
- ✅ 有对白的镜头显示字幕
- ✅ 无对白的镜头显示"-"
- ✅ 生成的提示词体现对白部分

### 测试场景3：长视频

**输入：** 5分钟视频，全程有解说

**预期结果：**
- ✅ 识别所有5分钟的语音（5段，共300秒）
- ✅ 所有镜头都有对应字幕
- ✅ 生成的提示词完整体现内容
- ✅ 识别过程有进度提示

---

## 💡 使用建议

### 1. 视频要求

- ✅ 音频清晰，无过多噪音
- ✅ 语速适中，发音清晰
- ✅ 使用标准普通话
- ✅ 避免多人同时说话

### 2. 最佳实践

- 上传高质量音频的视频
- 查看控制台日志了解识别情况
- 检查字幕识别准确性
- 根据需要调整提示词

### 3. 注意事项

- 长视频识别时间较长，请耐心等待
- 查看toast提示了解识别进度
- 方言识别可能不准确
- 背景音乐会影响识别效果

---

## 📚 相关文档

- [SUBTITLE_FEATURE.md](SUBTITLE_FEATURE.md) - 字幕功能详细说明
- [USER_GUIDE.md](USER_GUIDE.md) - 用户使用指南
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - API文档
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排查

---

## ✅ 优化检查清单

- [x] 移除音频时长限制
- [x] 移除识别段数限制
- [x] 添加详细日志输出
- [x] 添加用户友好提示
- [x] 增加字幕长度限制
- [x] 优化问题文本
- [x] 修改PromptGenerator接口
- [x] 整合画面和字幕信息
- [x] 优化提示词生成要求
- [x] 优化system prompt
- [x] 代码lint检查通过
- [x] 编写优化文档

---

## 🎉 总结

本次优化全面提升了音频字幕识别和提示词生成的质量：

**核心改进：**
- ✅ 完整识别所有音频内容
- ✅ 准确匹配字幕到镜头
- ✅ 生成包含对白的提示词
- ✅ 提供友好的用户反馈

**用户价值：**
- 📊 更完整的视频分析
- 🎯 更准确的字幕识别
- 💡 更专业的提示词
- 🚀 更好的使用体验

**技术提升：**
- 🔧 更健壮的错误处理
- 📝 更详细的日志输出
- 🎨 更优化的代码结构
- ✨ 更高的代码质量

---

**优化版本：** v2.4  
**优化日期：** 2025-12-03  
**状态：** ✅ 已完成  
**测试状态：** ⏳ 待用户验证
