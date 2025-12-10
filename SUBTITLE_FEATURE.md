# 字幕内容显示功能

## 🎯 功能说明

在视频分镜拆解分析结果中，现在会显示每个镜头对应的字幕内容（人物说话的内容）。

---

## ✨ 功能特点

### 1. 自动识别字幕

- ✅ 自动提取视频音频
- ✅ 使用百度语音识别API转换为文字
- ✅ 按时间轴匹配到对应镜头
- ✅ 在分析结果中显示

### 2. 智能匹配

- ✅ 根据镜头时间戳匹配字幕
- ✅ 每个镜头显示对应时间段的字幕
- ✅ 无字幕时显示"-"
- ✅ 自动处理特殊字符

### 3. 清晰展示

- ✅ 在分析表格中单独一列显示
- ✅ Markdown格式渲染
- ✅ 支持复制和导出
- ✅ 便于阅读和使用

---

## 📊 表格结构

### 修改前

| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | 时长(秒) |
|------|----------|-----------|----------|----------|----------|
| 1 | ![镜头1](...) | 中景/平视 | 固定镜头 | 画面描述... | 3.5 |

### 修改后

| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | **字幕内容** | 时长(秒) |
|------|----------|-----------|----------|----------|------------|----------|
| 1 | ![镜头1](...) | 中景/平视 | 固定镜头 | 画面描述... | **欢迎来到我们的频道** | 3.5 |
| 2 | ![镜头2](...) | 特写/平视 | 推镜头 | 产品特写... | **这是我们的新产品** | 2.8 |
| 3 | ![镜头3](...) | 全景/俯视 | 摇镜头 | 环境展示... | - | 4.2 |

---

## 🔧 技术实现

### 1. 类型定义

**文件：** `src/types/video.ts`

```typescript
export interface ShotAnalysis {
  frameIndex: number;
  timestamp: number;
  imageUrl: string;
  description: string;
  shotType?: string;
  cameraAngle?: string;
  cameraMovement?: string;
  detailedContent?: string;
  duration?: number;
  subtitle?: string; // 新增：该镜头的字幕/语音内容
}
```

### 2. 数据采集

**文件：** `src/pages/Home.tsx`

```typescript
// 音频识别（已有功能）
const audioTranscriptByTime: { [key: number]: string } = {};

// 提取音频并识别
const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
const wavBlob = await extractAudioFromVideo(audioBuffer, duration);
const audioChunks = await splitAudioIntoChunks(wavBlob, 60);

// 识别每段音频
for (let i = 0; i < audioChunks.length; i++) {
  const base64Audio = await blobToBase64(audioChunks[i]);
  const response = await recognizeSpeech(base64Audio, audioChunks[i].size);
  
  if (response.data.err_no === 0) {
    const transcript = response.data.result.join('');
    const timeKey = i * 60;
    audioTranscriptByTime[timeKey] = transcript;
  }
}
```

### 3. 字幕匹配

```typescript
// 为每个镜头匹配对应的字幕
const audioForThisShot = Object.keys(audioTranscriptByTime)
  .map(Number)
  .filter(time => time >= frame.timestamp && (!nextFrame || time < nextFrame.timestamp))
  .map(time => audioTranscriptByTime[time])
  .join(' ');
```

### 4. 保存字幕

```typescript
const analysis: ShotAnalysis = {
  frameIndex: i,
  timestamp: frame.timestamp,
  imageUrl: `data:image/jpeg;base64,${frame.imageData}`,
  description: description,
  shotType: shotType || '中景',
  cameraAngle: cameraAngle || '平视',
  cameraMovement: cameraMovement || '固定镜头',
  detailedContent: detailedContent,
  duration: Math.round(shotDuration * 10) / 10,
  subtitle: audioForThisShot || '' // 保存字幕内容
};
```

### 5. 表格展示

```typescript
// 生成Markdown表格
let overallDescription = `## 视频分镜拆解分析\n\n`;
overallDescription += `| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | 字幕内容 | 时长(秒) |\n`;
overallDescription += `|------|----------|-----------|----------|----------|----------|----------|\n`;

analyses.forEach((a, idx) => {
  const shotNum = idx + 1;
  const imageRef = `![镜头${shotNum}](${a.imageUrl})`;
  const shotTypeAngle = `${a.shotType}/${a.cameraAngle}`;
  const movement = a.cameraMovement;
  const content = (a.detailedContent || a.description).replace(/\n/g, ' ').replace(/\|/g, '\\|');
  const subtitle = a.subtitle ? a.subtitle.replace(/\|/g, '\\|') : '-'; // 显示字幕或"-"
  const dur = a.duration?.toFixed(1);
  
  overallDescription += `| ${shotNum} | ${imageRef} | ${shotTypeAngle} | ${movement} | ${content} | ${subtitle} | ${dur} |\n`;
});
```

---

## 🎬 使用示例

### 示例1：有字幕的视频

**视频内容：** 产品介绍视频，主持人讲解产品特点

**分析结果：**

| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | 字幕内容 | 时长(秒) |
|------|----------|-----------|----------|----------|----------|----------|
| 1 | ![镜头1](...) | 中景/平视 | 固定镜头 | 主持人站在产品前，面带微笑 | 大家好，今天给大家介绍一款新产品 | 3.5 |
| 2 | ![镜头2](...) | 特写/平视 | 推镜头 | 产品特写，展示细节 | 这款产品采用了最新的技术 | 2.8 |
| 3 | ![镜头3](...) | 中景/平视 | 固定镜头 | 主持人手持产品演示 | 使用起来非常简单方便 | 4.2 |

### 示例2：部分有字幕的视频

**视频内容：** 风景视频，配有解说

**分析结果：**

| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | 字幕内容 | 时长(秒) |
|------|----------|-----------|----------|----------|----------|----------|
| 1 | ![镜头1](...) | 全景/平视 | 摇镜头 | 山峦起伏，云雾缭绕 | 这里是著名的黄山风景区 | 5.0 |
| 2 | ![镜头2](...) | 中景/平视 | 移镜头 | 松树挺拔，造型独特 | - | 3.5 |
| 3 | ![镜头3](...) | 特写/俯视 | 固定镜头 | 岩石纹理清晰可见 | - | 2.0 |
| 4 | ![镜头4](...) | 全景/仰视 | 拉镜头 | 山峰高耸入云 | 黄山以奇松怪石云海著称 | 4.5 |

### 示例3：无字幕的视频

**视频内容：** 纯音乐MV，无人声

**分析结果：**

| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | 字幕内容 | 时长(秒) |
|------|----------|-----------|----------|----------|----------|----------|
| 1 | ![镜头1](...) | 全景/平视 | 固定镜头 | 夕阳下的海滩 | - | 4.0 |
| 2 | ![镜头2](...) | 中景/平视 | 跟镜头 | 人物在海边漫步 | - | 3.5 |
| 3 | ![镜头3](...) | 特写/平视 | 固定镜头 | 海浪拍打礁石 | - | 2.5 |

---

## 💡 使用场景

### 1. 视频脚本分析

- 分析视频的叙事结构
- 研究画面与台词的配合
- 学习视频制作技巧

### 2. 内容创作参考

- 了解优秀视频的字幕节奏
- 学习台词与画面的呼应
- 优化自己的视频脚本

### 3. 视频转录

- 快速获取视频字幕
- 整理视频内容文字版
- 制作视频文案

### 4. 教学分析

- 分析教学视频的讲解内容
- 研究知识点的呈现方式
- 优化教学视频制作

---

## 🎯 功能优势

### 1. 完整性

- ✅ 画面 + 字幕完整记录
- ✅ 视觉 + 听觉信息齐全
- ✅ 便于全面分析视频

### 2. 准确性

- ✅ 基于百度语音识别API
- ✅ 识别准确率高
- ✅ 支持中文普通话

### 3. 便捷性

- ✅ 自动识别，无需手动输入
- ✅ 按时间轴自动匹配
- ✅ 一键生成完整报告

### 4. 实用性

- ✅ Markdown格式，易于复制
- ✅ 表格清晰，便于阅读
- ✅ 支持导出和分享

---

## 📝 注意事项

### 1. 音频质量

- 清晰的音频识别率更高
- 背景噪音会影响识别
- 建议使用高质量音频

### 2. 语言支持

- 当前支持中文普通话
- 方言识别可能不准确
- 外语需要对应的识别服务

### 3. 字幕长度

- 长字幕会在表格中自动换行
- 建议视频字幕简洁明了
- 过长字幕可能影响阅读

### 4. 无音频视频

- 纯画面视频字幕显示"-"
- 不影响其他分析功能
- 仍可正常生成分析报告

---

## 🔄 工作流程

```
1. 上传视频
   ↓
2. 提取音频
   ↓
3. 音频分段（每60秒一段）
   ↓
4. 语音识别（转文字）
   ↓
5. 提取关键帧
   ↓
6. 分析每个镜头
   ↓
7. 匹配字幕到镜头
   ↓
8. 生成分析报告
   ↓
9. 显示完整结果（画面+字幕）
```

---

## 📊 数据结构

### 音频时间轴数据

```typescript
audioTranscriptByTime = {
  0: "大家好，今天给大家介绍一款新产品",
  60: "这款产品采用了最新的技术",
  120: "使用起来非常简单方便"
}
```

### 镜头分析数据

```typescript
shotAnalysis = {
  frameIndex: 0,
  timestamp: 0,
  imageUrl: "data:image/jpeg;base64,...",
  description: "主持人站在产品前，面带微笑",
  shotType: "中景",
  cameraAngle: "平视",
  cameraMovement: "固定镜头",
  detailedContent: "主持人站在产品前，面带微笑，背景是白色展示墙",
  duration: 3.5,
  subtitle: "大家好，今天给大家介绍一款新产品" // 字幕内容
}
```

---

## 🎨 界面展示

### 分析结果页面

```markdown
## 视频分镜拆解分析

| 镜号 | 画面截图 | 景别/角度 | 运动方式 | 画面内容 | 字幕内容 | 时长(秒) |
|------|----------|-----------|----------|----------|----------|----------|
| 1 | ![镜头1](...) | 中景/平视 | 固定镜头 | 主持人介绍产品 | 大家好，欢迎观看 | 3.5 |
| 2 | ![镜头2](...) | 特写/平视 | 推镜头 | 产品细节展示 | 这是我们的新品 | 2.8 |

## 视频总结

**创意构思**：该视频通过2个精心设计的镜头，结合画面与语音解说，展现了完整的视觉叙事。

**表现手法**：运用了中景、特写等景别，以及固定镜头、推镜头等拍摄手法，使画面富有层次感和节奏感。

**信息传达**：视频通过视觉元素和语音内容的有机结合，有效地传达了核心信息，引导观众的注意力，达到了良好的传播效果。
```

---

## 🚀 未来优化

### 1. 字幕时间精确度

- 精确到毫秒级别
- 显示字幕起止时间
- 支持字幕时间轴编辑

### 2. 多语言支持

- 支持英文识别
- 支持多种方言
- 自动检测语言

### 3. 字幕样式

- 支持字幕高亮
- 支持关键词标注
- 支持情感分析

### 4. 导出功能

- 导出SRT字幕文件
- 导出Word文档
- 导出Excel表格

---

## 📚 相关文档

- [USER_GUIDE.md](USER_GUIDE.md) - 用户使用指南
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - API文档
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 故障排查

---

## ✅ 功能检查清单

- [x] 音频提取功能
- [x] 语音识别功能
- [x] 字幕时间匹配
- [x] 字幕数据保存
- [x] 表格显示字幕
- [x] 特殊字符处理
- [x] 无字幕显示"-"
- [x] Markdown渲染
- [x] 代码lint检查

---

**功能版本：** v1.0  
**创建日期：** 2025-12-03  
**状态：** ✅ 已完成  
**测试状态：** ⏳ 待用户验证
