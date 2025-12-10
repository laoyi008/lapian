# Bug 修复记录

## 问题描述
上传视频后点击"开始分析"，进度条进行到30%后返回初始状态，无法正常使用。

## 问题原因
在 `Home.tsx` 中调用了 `extractAudioFromVideo` 函数，但该函数：
1. 未在 `audioProcessor.ts` 中定义
2. 未在 `Home.tsx` 中导入
3. 在 `Home.tsx` 中有重复的本地定义（未被使用）

这导致代码在执行到音频处理阶段时抛出异常，触发错误处理逻辑，重置了所有状态。

## 解决方案

### 1. 添加 `extractAudioFromVideo` 函数
在 `src/utils/audioProcessor.ts` 中添加了音频提取函数：

```typescript
export const extractAudioFromVideo = async (audioBuffer: AudioBuffer, maxDuration: number): Promise<Blob> => {
  const duration = Math.min(audioBuffer.duration, maxDuration);
  const sampleRate = 16000;
  const samples = Math.floor(duration * sampleRate);
  
  const offlineContext = new OfflineAudioContext(1, samples, sampleRate);
  const source = offlineContext.createBufferSource();
  source.buffer = audioBuffer;
  source.connect(offlineContext.destination);
  source.start(0);
  
  const renderedBuffer = await offlineContext.startRendering();
  return audioBufferToWav(renderedBuffer);
};
```

**功能说明：**
- 从视频的 AudioBuffer 中提取音频数据
- 限制最大时长（避免处理过长的音频）
- 转换采样率为 16000Hz（语音识别API要求）
- 输出为 WAV 格式的 Blob

### 2. 更新导入语句
在 `src/pages/Home.tsx` 中添加函数导入：

```typescript
import { blobToBase64, splitAudioIntoChunks, extractAudioFromVideo } from '@/utils/audioProcessor';
```

### 3. 清理重复代码
删除了 `Home.tsx` 中重复定义的 `extractAudioFromVideo` 和 `audioBufferToWav` 函数，统一使用 `audioProcessor.ts` 中的实现。

## 技术细节

### 音频处理流程
1. **提取音频**：使用 `extractAudioFromVideo` 从视频中提取音频
2. **分割音频**：使用 `splitAudioIntoChunks` 将长音频分割为60秒的片段
3. **转换格式**：使用 `blobToBase64` 转换为 Base64 格式
4. **语音识别**：调用百度语音识别API识别每个片段
5. **时间匹配**：将识别结果按时间轴匹配到对应镜头

### 采样率转换
- 原始视频音频可能是 44100Hz 或 48000Hz
- 使用 `OfflineAudioContext` 重采样为 16000Hz
- 16000Hz 是语音识别的标准采样率，可以：
  - 减小文件大小
  - 提高识别速度
  - 满足API要求

### 错误处理
代码中已包含完善的错误处理：
```typescript
try {
  // 音频处理逻辑
} catch (audioError) {
  console.log('视频没有音频轨道或音频解析失败');
}
```

即使视频没有音频或音频处理失败，也不会影响画面分析的正常进行。

## 测试建议

### 测试场景
1. **有音频的视频**：验证音频识别和整合功能
2. **无音频的视频**：验证纯画面分析功能
3. **长视频**：验证音频分割和限时处理
4. **短视频**：验证完整流程

### 预期结果
- 进度条正常推进：10% → 30% → 80% → 85% → 100%
- 有音频时：语音内容整合到画面描述中
- 无音频时：仅显示画面分析结果
- 错误时：显示友好的错误提示，不会卡死

## 验证状态
✅ 代码 lint 检查通过
✅ TypeScript 类型检查通过
✅ 函数导入导出正确
✅ 错误处理完善
✅ 清理了重复代码

## 相关文件
- `src/utils/audioProcessor.ts` - 添加音频提取函数
- `src/pages/Home.tsx` - 更新导入语句，清理重复代码
