# API使用文档

## 📋 概述

本项目使用百度智能云的三个核心API服务：
1. **图像内容理解API** - 视频画面分析
2. **短语音识别API** - 音频内容识别
3. **自然语言处理NLP API** - 提示词生成

---

## 🖼️ 1. 图像内容理解API

### 功能说明
对视频关键帧进行深度分析，识别场景、人物、动作、拍摄手法等视觉元素。

### API端点

#### 提交分析请求
```
POST /rest/2.0/image-classify/v1/image-understanding/request
```

**请求参数：**
```typescript
{
  image: string;        // Base64编码的图片
  access_token: string; // 百度API访问令牌
}
```

**响应示例：**
```json
{
  "log_id": "1234567890",
  "data": {
    "task_id": "task_abc123"
  }
}
```

#### 获取分析结果
```
POST /rest/2.0/image-classify/v1/image-understanding/get-result
```

**请求参数：**
```typescript
{
  task_id: string;      // 任务ID
  access_token: string; // 百度API访问令牌
}
```

**响应示例：**
```json
{
  "log_id": "1234567890",
  "data": {
    "result": {
      "ret_code": 0,  // 0=成功, 1=处理中, 2=失败
      "ret_msg": "success",
      "result": "这是一个室内场景，画面中有一位女性正在使用笔记本电脑..."
    }
  }
}
```

### 实现代码

**文件：** `src/services/imageAnalysis.ts`

```typescript
// 提交图像分析请求
export async function submitImageUnderstanding(
  imageBase64: string,
  accessToken: string
): Promise<string> {
  console.log('提交图像分析请求...');
  
  const response = await fetch(
    `https://aip.baidubce.com/rest/2.0/image-classify/v1/image-understanding/request?access_token=${accessToken}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: `image=${encodeURIComponent(imageBase64)}`
    }
  );

  if (!response.ok) {
    console.error('图像分析请求失败:', response.status);
    throw new Error(`HTTP错误: ${response.status}`);
  }

  const data = await response.json();
  console.log('图像分析响应:', data);
  
  return data.data.task_id;
}

// 轮询获取分析结果
export async function pollImageUnderstandingResult(
  taskId: string,
  accessToken: string,
  maxAttempts = 30,
  interval = 2000
): Promise<string> {
  console.log(`开始轮询任务结果，任务ID: ${taskId}`);
  
  for (let i = 0; i < maxAttempts; i++) {
    console.log(`轮询尝试 ${i + 1}/${maxAttempts}`);
    
    const response = await fetch(
      `https://aip.baidubce.com/rest/2.0/image-classify/v1/image-understanding/get-result?access_token=${accessToken}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: `task_id=${taskId}`
      }
    );

    const result = await response.json();
    console.log(`任务状态码: ${result.data.result.ret_code}`);

    if (result.data.result.ret_code === 0) {
      console.log('任务完成');
      return result.data.result.result;
    } else if (result.data.result.ret_code === 2) {
      throw new Error('图像分析失败');
    }

    console.log(`任务处理中，等待 ${interval}ms 后重试...`);
    await new Promise(resolve => setTimeout(resolve, interval));
  }

  throw new Error('图像分析超时');
}
```

### 使用示例

```typescript
// 在Home.tsx中使用
const analyzeFrame = async (frameBase64: string) => {
  try {
    // 1. 提交分析请求
    const taskId = await submitImageUnderstanding(
      frameBase64,
      accessToken
    );
    
    // 2. 轮询获取结果
    const description = await pollImageUnderstandingResult(
      taskId,
      accessToken
    );
    
    console.log('分析结果:', description);
    return description;
  } catch (error) {
    console.error('分析失败:', error);
    throw error;
  }
};
```

---

## 🎤 2. 短语音识别API

### 功能说明
将视频中的音频转换为文字，支持中文普通话识别。

### API端点

```
POST /rest/2.0/speech/v1/asr
```

### 请求参数

```typescript
{
  format: 'pcm',        // 音频格式
  rate: 16000,          // 采样率
  channel: 1,           // 声道数
  cuid: string,         // 用户唯一标识
  token: string,        // 访问令牌
  dev_pid: 1537,        // 语言模型（1537=普通话）
  speech: string,       // Base64编码的音频数据
  len: number           // 音频数据长度
}
```

### 响应示例

```json
{
  "err_no": 0,
  "err_msg": "success",
  "corpus_no": "1234567890",
  "sn": "123456789",
  "result": ["这是识别出的文字内容"]
}
```

### 实现代码

**文件：** `src/services/speechRecognition.ts`

```typescript
export async function recognizeSpeech(
  audioBase64: string,
  accessToken: string
): Promise<string> {
  const audioData = atob(audioBase64);
  const audioLength = audioData.length;

  const response = await fetch(
    `https://vop.baidu.com/rest/2.0/speech/v1/asr?cuid=${Date.now()}&token=${accessToken}&dev_pid=1537`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        format: 'pcm',
        rate: 16000,
        channel: 1,
        cuid: `user_${Date.now()}`,
        token: accessToken,
        dev_pid: 1537,
        speech: audioBase64,
        len: audioLength
      })
    }
  );

  const data = await response.json();

  if (data.err_no === 0 && data.result && data.result.length > 0) {
    return data.result[0];
  }

  throw new Error(data.err_msg || '语音识别失败');
}
```

### 音频处理

**文件：** `src/utils/audioProcessor.ts`

```typescript
// 提取视频音频
export async function extractAudioFromVideo(
  videoFile: File
): Promise<AudioBuffer | null> {
  const audioContext = new AudioContext({ sampleRate: 16000 });
  
  try {
    const arrayBuffer = await videoFile.arrayBuffer();
    const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
    return audioBuffer;
  } catch (error) {
    console.error('音频提取失败:', error);
    return null;
  }
}

// 转换为PCM格式
export function audioBufferToPCM(audioBuffer: AudioBuffer): ArrayBuffer {
  const channelData = audioBuffer.getChannelData(0);
  const pcmData = new Int16Array(channelData.length);
  
  for (let i = 0; i < channelData.length; i++) {
    const s = Math.max(-1, Math.min(1, channelData[i]));
    pcmData[i] = s < 0 ? s * 0x8000 : s * 0x7FFF;
  }
  
  return pcmData.buffer;
}

// 转换为Base64
export function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}
```

### 使用示例

```typescript
// 在Home.tsx中使用
const analyzeAudio = async (videoFile: File) => {
  try {
    // 1. 提取音频
    const audioBuffer = await extractAudioFromVideo(videoFile);
    if (!audioBuffer) {
      console.log('视频无音频轨道');
      return null;
    }
    
    // 2. 转换格式
    const pcmData = audioBufferToPCM(audioBuffer);
    const audioBase64 = arrayBufferToBase64(pcmData);
    
    // 3. 识别语音
    const transcript = await recognizeSpeech(audioBase64, accessToken);
    
    console.log('识别结果:', transcript);
    return transcript;
  } catch (error) {
    console.error('音频分析失败:', error);
    return null;
  }
};
```

---

## 💬 3. 自然语言处理NLP API

### 功能说明
基于视频分析结果，使用大语言模型生成专业的AI视频提示词。

### API端点

```
POST /v2/chat/completions
```

### 请求参数

```typescript
{
  messages: [
    {
      role: 'system',
      content: '系统提示词'
    },
    {
      role: 'user',
      content: '用户输入'
    }
  ],
  stream: true  // 启用流式输出
}
```

### 响应格式

**流式响应（SSE）：**
```
data: {"choices":[{"delta":{"content":"生成"}}]}
data: {"choices":[{"delta":{"content":"的"}}]}
data: {"choices":[{"delta":{"content":"内容"}}]}
data: [DONE]
```

### 实现代码

**文件：** `src/services/chatStream.ts`

```typescript
export async function sendChatStream({
  endpoint,
  apiId,
  messages,
  onUpdate,
  onComplete,
  onError
}: ChatStreamParams): Promise<void> {
  try {
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-App-Id': apiId
      },
      body: JSON.stringify({
        messages,
        stream: true
      })
    });

    if (!response.ok) {
      throw new Error(`HTTP错误: ${response.status}`);
    }

    const reader = response.body?.getReader();
    const decoder = new TextDecoder();
    let fullContent = '';

    while (true) {
      const { done, value } = await reader!.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') continue;

          try {
            const json = JSON.parse(data);
            const content = json.choices?.[0]?.delta?.content;
            
            if (content) {
              fullContent += content;
              onUpdate(fullContent);
            }
          } catch (e) {
            // 忽略解析错误
          }
        }
      }
    }

    onComplete();
  } catch (error) {
    onError(error as Error);
  }
}
```

### 使用示例

**文件：** `src/components/video/PromptGenerator.tsx`

```typescript
const handleGeneratePrompt = async () => {
  setIsGenerating(true);
  setGeneratedPrompt('');

  const userMessage = `请根据以下短视频拉片分析结果，生成AI视频生成提示词。

分镜描述：
${shotDescriptions.join('\n\n')}

语音内容：
${audioTranscript}

要求：
1. 直接输出可用的提示词
2. 整合所有镜头的关键信息
3. 包含画面风格、场景、动作、色调等要素
4. 语言简洁明确`;

  try {
    await sendChatStream({
      endpoint: CHAT_ENDPOINT,
      apiId: APP_ID,
      messages: [
        {
          role: 'system',
          content: '你是专业的视频创作助手，生成简洁可用的AI视频提示词。'
        },
        {
          role: 'user',
          content: userMessage
        }
      ],
      onUpdate: (content) => {
        setGeneratedPrompt(content);
      },
      onComplete: () => {
        setIsGenerating(false);
        toast.success('提示词生成完成');
      },
      onError: (error) => {
        setIsGenerating(false);
        toast.error(`生成失败: ${error.message}`);
      }
    });
  } catch (error) {
    setIsGenerating(false);
    toast.error('生成提示词时发生错误');
  }
};
```

---

## 🔄 完整工作流程

### 1. 初始化
```typescript
// 获取访问令牌
const accessToken = await getAccessToken();
```

### 2. 视频上传
```typescript
// 用户选择视频文件
const handleVideoSelect = (file: File) => {
  setVideoFile(file);
};
```

### 3. 提取关键帧
```typescript
// 从视频中提取关键帧
const frames = await extractKeyFrames(videoFile, 8);
// 返回: Array<{ timestamp: number, imageData: string }>
```

### 4. 音频分析
```typescript
// 提取并识别音频
const audioBuffer = await extractAudioFromVideo(videoFile);
const pcmData = audioBufferToPCM(audioBuffer);
const audioBase64 = arrayBufferToBase64(pcmData);
const transcript = await recognizeSpeech(audioBase64, accessToken);
```

### 5. 画面分析
```typescript
// 分析每个关键帧
for (const frame of frames) {
  // 提交分析请求
  const taskId = await submitImageUnderstanding(
    frame.imageData,
    accessToken
  );
  
  // 获取分析结果
  const description = await pollImageUnderstandingResult(
    taskId,
    accessToken
  );
  
  shotAnalyses.push({
    timestamp: frame.timestamp,
    description: description
  });
}
```

### 6. 生成提示词
```typescript
// 基于分析结果生成提示词
await sendChatStream({
  endpoint: CHAT_ENDPOINT,
  apiId: APP_ID,
  messages: [
    { role: 'system', content: '系统提示' },
    { role: 'user', content: `分析结果：${shotAnalyses}` }
  ],
  onUpdate: (content) => setGeneratedPrompt(content),
  onComplete: () => toast.success('完成'),
  onError: (error) => toast.error(error.message)
});
```

---

## ⚠️ 注意事项

### 1. API限制
- **图像分析：** 单次请求图片大小 < 4MB
- **语音识别：** 音频时长 < 60秒
- **NLP生成：** 输入文本 < 10000字符

### 2. 错误处理
- 所有API调用都应包含try-catch
- 网络错误需要友好提示
- 超时需要合理设置

### 3. 性能优化
- 图像分析使用轮询，间隔2秒
- 音频分段处理，每段60秒
- NLP使用流式输出，提升体验

### 4. 安全性
- API密钥不暴露在客户端
- 使用环境变量管理
- 通过代理服务器调用

---

## 📊 调试技巧

### 查看API请求
```typescript
console.log('请求参数:', { image, accessToken });
console.log('响应数据:', data);
```

### 监控进度
```typescript
console.log(`分析进度: ${current}/${total}`);
console.log(`当前进度: ${progress}%`);
```

### 错误追踪
```typescript
console.error('API错误:', error);
console.error('错误详情:', error.message);
```

---

## 🔗 相关资源

- [百度智能云官网](https://cloud.baidu.com/)
- [图像内容理解API文档](https://cloud.baidu.com/doc/IMAGERECOGNITION/index.html)
- [短语音识别API文档](https://cloud.baidu.com/doc/SPEECH/index.html)
- [千帆大模型平台](https://cloud.baidu.com/doc/WENXINWORKSHOP/index.html)

---

**文档版本：** v1.0  
**最后更新：** 2025-12-03  
**维护状态：** ✅ 持续更新
