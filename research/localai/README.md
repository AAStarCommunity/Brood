# M1 Max 64GB 本地 AI 内存预算与场景切换方案

> 维护者：jason | 创建日期：2026-05-05
> 硬件：Apple M1 Max · 64GB 统一内存 · 32 核 GPU
> 在线表格：[Google Sheets](https://docs.google.com/spreadsheets/d/1W6PKAqBc27Z46zzz5Ln8UmMK2_9OOP2MKvaEX81_S9U/edit)
> 参考：[M1 Max 64GB 本地 AI 模型选择指南](https://blog.mushroom.cv/blog/m1-max-64gb-local-ai-model-selection-memory-guide/)

---

## 1. 内存预算总览

```
┌─────────────────────────────────────────────────────────┐
│                    64GB 统一内存                          │
├──────────────┬──────────────────────────────────────────┤
│  系统 + 软件  │          AI 可用空间                      │
│    16GB      │           48GB                           │
│  (常驻固定)   │  ┌──────────┬──────────┬──────────┐     │
│              │  │ 常驻服务  │ 主力模型  │ 场景工具  │     │
│              │  │  3-4GB   │ 32-41GB  │ 按需加载  │     │
│              │  └──────────┴──────────┴──────────┘     │
└──────────────┴──────────────────────────────────────────┘
```

| 层 | 预算 | 内容 | 管理方式 |
|:---|:---:|:---|:---|
| **系统层** | 16GB | macOS + 浏览器 + 编辑器 + 终端 | 固定占用 |
| **常驻服务层** | 3-4GB | Ollama(BGE 嵌入) + oMLX 守护进程 | 开机自启 |
| **主力模型层** | 32-41GB | Qwen3 系列 LLM（同一时间仅一个） | oMLX 自动切换 |
| **场景工具层** | 可变 | 图/音/视频生成、OCR 等 | 独立脚本，用完即卸 |

---

## 2. 运行时架构

```
oMLX (localhost:11434, OpenAI 兼容)
├── Qwen3-30B-A3B    32GB  ← 日常默认（MoE，激活仅 3.3B）
├── Qwen3.6-27B      35GB  ← 代码开发
└── Qwen3-32B        41GB  ← 深度推理/高质量创作
    ⚙️ 同一时间仅加载一个，切换自动卸载，闲置 10min 自动释放

apfel (独立进程)
└── Apple Intelligence 3B  ~2GB  ← 轻量预处理

Ollama (独立进程)
├── bge-m3           ~1.5GB ← 嵌入向量/RAG
└── 小模型 (7-8B)    ~5GB   ← 辅助工具调用

独立脚本 (用完即卸)
├── ComfyUI + FLUX/SDXL     ← 图片生成
├── CosyVoice2 / ChatTTS    ← 语音合成
├── Wan2.1-1.3B              ← 短视频生成
└── GOT-OCR2 / Marker        ← 文档 OCR
```

---

## 3. 全模型清单

### 3.1 主力 LLM（oMLX 管理，互斥加载）

| 模型 | 参数量 | 量化 | 内存 | 类型 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---:|:---|:---|:---|
| **Qwen3-30B-A3B** | 30.5B (激活 3.3B) | 8bit | 32GB | MoE 稀疏 | 日常全能·128K 上下文 | **默认常驻** |
| **Qwen3.6-27B** | 27B | 8bit | 35GB | Dense | 代码开发·结构化输出 | 场景切换 |
| **Qwen3-32B** | 32.8B | 8bit | 41GB | Dense 旗舰 | 深度推理·高质量创作 | 场景切换 |

### 3.2 轻量预处理（apfel，独立进程）

| 模型 | 参数量 | 内存 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---|:---|
| **Apple Intelligence 3B** | 3B | ~2GB | 笔记摘要·关键词·CSV 解析·格式预处理 | 按需启动 |

### 3.3 嵌入与工具模型（Ollama）

| 模型 | 参数量 | 内存 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---|:---|
| **bge-m3** | 568M | ~1.5GB | 文档嵌入·RAG 检索 | 常驻 |
| **qwen3:8b** | 8B | ~5GB | 轻量工具调用·函数执行 | 按需 |

### 3.4 图片生成（mflux / ComfyUI / Draw Things）

| 模型 | 参数量 | 内存 | 运行时 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---|:---|:---|
| **FLUX.1-schnell** | 12B | ~16GB (8bit) | mflux (MLX 原生) | 快速文生图（~20s/张） | 用完即卸 |
| **FLUX.1-dev** | 12B | ~16GB (8bit) | mflux (MLX 原生) | 高质量文生图（25+ steps） | 用完即卸 |
| **SDXL** | 3.5B | ~6-8GB | Draw Things / ComfyUI (MPS) | 轻量文生图·LoRA·ControlNet | 用完即卸 |
| **SD 1.5** | 0.9B | ~4GB | MochiDiffusion (CoreML) | 最快出图·成熟生态 | 用完即卸 |

### 3.5 语音合成 TTS（PyTorch MPS）

| 模型 | 参数量 | 内存 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---|:---|
| **F5-TTS** | 155M | ~2-3GB | 快速 TTS·RTF 0.15·最轻量 | 用完即卸 |
| **CosyVoice2-0.5B** | 500M | ~3GB | 中文语音克隆·多语种·口播音频 | 用完即卸 |
| **ChatTTS** | ~300M | ~4GB | 对话式中文/英文 TTS | 用完即卸 |
| **Bark (small)** | ~300M | ~2.3GB | 多语种 + 音效·表情丰富 | 用完即卸 |

### 3.6 视频生成（MLX 原生）

| 模型 | 参数量 | 内存 | 运行时 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---|:---|:---|
| **LTX-2.3 Distilled Q4** | ~2B | ~19GB | ltx-video-mac (MLX) | 短视频生成·64GB 最佳选择 | 用完即卸 |
| **LTX-2 Unified** | ~2B | ~42GB | ltx-video-mac (MLX) | 高质量视频·占满预算 | 用完即卸 |
| **Wan2.1-T2V-1.3B** | 1.3B | ~24GB | Wan2.2-mlx (MLX) | 文生视频·较慢 | 用完即卸 |

> **重要**：视频生成必须独占运行，启动前卸载 oMLX 中的 LLM。14B+ 模型不适合 64GB。

### 3.7 文档处理（独立脚本）

| 模型 | 参数量 | 内存 | 运行时 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---|:---|:---|
| **GOT-OCR2** | 580M | ~3-4GB | transformers (MPS) | 图片/PDF 端到端 OCR | 用完即卸 |
| **Marker (Surya)** | ~150M | ~2-3GB | pip install marker-pdf | PDF → Markdown 转换 | 用完即卸 |
| **Surya** | ~150M | ~2-3GB | pip install surya-ocr | 90+ 语种 OCR·表格识别 | 用完即卸 |

### 3.8 翻译

Qwen3 系列原生支持 100+ 语言，日常翻译无需额外模型。批量/专业翻译可用专用模型。

| 模型 | 参数量 | 内存 | 场景 | 驻留策略 |
|:---|:---:|:---:|:---|:---|
| *(复用 Qwen3-30B-A3B)* | — | 0 额外 | 日常中英/日/韩翻译 | 跟随主力 |
| **NLLB-200-distilled-600M** | 600M | ~3GB | 200 语种批量翻译 | 用完即卸 |
| **NLLB-200-1.3B** | 1.3B | ~5-6GB | 高质量多语种翻译 | 用完即卸 |
| **Helsinki-NLP OPUS-MT** | 50-80M/对 | <1GB | 特定语对·极速翻译 | 用完即卸 |

---

## 4. 场景切换方案

### 场景 A：日常（信息收集·文档·博客·社媒发布）

```
总占用 ≈ 16 + 32 + 1.5 = 49.5GB    余量 14.5GB ✅
┌──────────────────────────────────────────┐
│ oMLX: Qwen3-30B-A3B (32GB) ← 默认常驻   │
│ Ollama: bge-m3 (1.5GB)     ← 常驻       │
│ apfel: Apple 3B (按需)      ← 预处理     │
└──────────────────────────────────────────┘
```

**能力覆盖**：
- 信息收集 + 摘要过滤 → Qwen3-30B-A3B（128K 上下文）
- 文件分析 + 格式转换 → Qwen3-30B-A3B + Apple 3B 预处理
- 博客撰写 + 社媒文案 → Qwen3-30B-A3B
- RAG 检索 → bge-m3

### 场景 B：创作（全媒体发布 + 短视频制作）

**B-1: 文案 + 口播阶段**（LLM 主导）
```
总占用 ≈ 16 + 32 + 3 = 51GB    余量 13GB ✅
┌──────────────────────────────────────────┐
│ oMLX: Qwen3-30B-A3B (32GB)  ← 脚本创作  │
│ 脚本: CosyVoice2 (3GB)      ← 口播生成  │
└──────────────────────────────────────────┘
```

**B-2: 图片素材阶段**（图片生成主导）
```
方案 1 ≈ 16 + 6 = 22GB     余量 42GB ✅ (SDXL 轻量)
方案 2 ≈ 16 + 16 = 32GB    余量 32GB ✅ (FLUX 高质量)
┌──────────────────────────────────────────┐
│ Draw Things: SDXL (6-8GB)  ← 快速批量   │
│ 或 mflux: FLUX-schnell (16GB) ← 高质量  │
│ oMLX: 建议先卸载 LLM 腾出空间           │
│ （SDXL 可与 30B LLM 共存，FLUX 不建议） │
└──────────────────────────────────────────┘
```

**B-3: 视频合成阶段**（视频生成 + 剪辑）⚠️ 必须独占
```
方案 1 ≈ 16 + 19 = 35GB    余量 29GB ✅ (LTX-2.3 最佳)
方案 2 ≈ 16 + 24 = 40GB    余量 24GB ✅ (Wan2.1)
┌──────────────────────────────────────────┐
│ ltx-video-mac: LTX-2.3 Q4 (19GB) ← 推荐│
│ 或 Wan2.2-mlx: Wan2.1-1.3B (24GB)      │
│ Final Cut / DaVinci         ← 剪辑合成  │
│ oMLX: 必须卸载！视频生成独占 AI 内存     │
└──────────────────────────────────────────┘
```

### 场景 C：代码开发

```
总占用 ≈ 16 + 35 + 1.5 = 52.5GB    余量 11.5GB ✅
┌──────────────────────────────────────────┐
│ oMLX: Qwen3.6-27B (35GB)    ← 代码生成  │
│ Ollama: bge-m3 (1.5GB)      ← 代码检索  │
└──────────────────────────────────────────┘
```

### 场景 D：深度推理 / 长文创作

```
总占用 ≈ 16 + 41 = 57GB    余量 7GB ⚠️ (刚好够)
┌──────────────────────────────────────────┐
│ oMLX: Qwen3-32B (41GB)      ← 深度推理  │
│ 其他服务建议全部卸载                      │
└──────────────────────────────────────────┘
```

### 场景 E：特定任务

| 子场景 | 配置 | 总占用 | 余量 |
|:---|:---|:---:|:---:|
| **翻译** | Qwen3-30B-A3B (32GB) | ~48GB | 16GB |
| **PDF→MD 转换** | Marker (2-3GB) + Qwen3-30B-A3B (32GB) | ~51GB | 13GB |
| **OCR 识别** | GOT-OCR2 (3-4GB) + Qwen3-30B-A3B (32GB) | ~52GB | 12GB |
| **游戏原型** | Qwen3.6-27B (35GB) + Unity/Godot | ~55GB | 9GB |

---

## 5. 切换操作速查

| 操作 | 命令 / 方法 |
|:---|:---|
| **查看当前加载模型** | oMLX 菜单栏查看 |
| **切换主力 LLM** | oMLX 界面选择模型（自动卸载前序） |
| **手动释放全部** | oMLX 菜单栏 Stop 按钮 |
| **启动图片生成** | `python -m comfyui` 或 ComfyUI 桌面版 |
| **启动 TTS** | `python run_cosyvoice.py` |
| **启动视频生成** | `python run_wan21.py` |
| **释放非 oMLX 模型** | 终止对应 Python 进程 |

---

## 6. 内存安全规则

1. **一个大模型原则**：oMLX 同一时间只加载一个 27B+ 模型
2. **创作前先卸载**：启动 ComfyUI/视频生成前，先 Stop oMLX 中的 LLM
3. **闲置自动释放**：oMLX 10 分钟无请求自动卸载
4. **视频编辑排他**：Final Cut / DaVinci Resolve 工作时，不跑 AI 大模型
5. **浏览器控制**：限制 Chrome/Arc 标签数 ≤ 20，避免内存膨胀
6. **Swap 告警**：如果 Activity Monitor 显示内存压力为黄色/红色，立即卸载多余模型

---

## 7. 模型获取

```bash
# ═══ 主力 LLM（oMLX 内置下载）═══
# 在 oMLX 界面搜索 Qwen3-30B-A3B / Qwen3.6-27B / Qwen3-32B

# ═══ 嵌入模型 ═══
ollama pull bge-m3

# ═══ 图片生成 ═══
# mflux: MLX 原生 FLUX 推理（推荐）
pip install mflux
# 模型首次运行自动下载

# Draw Things: macOS 原生 SDXL 应用（App Store 免费）
# 或 ComfyUI + MPS 后端

# ═══ TTS ═══
pip install f5-tts          # 最轻量
pip install cosyvoice       # 中文语音克隆
pip install ChatTTS         # 对话式

# ═══ 视频生成 ═══
# LTX-2.3: MLX 原生，64GB 最佳选择
# 下载 ltx-video-mac: https://github.com/james-see/ltx-video-mac

# Wan2.1 MLX 版
pip install wan2-mlx

# ═══ 文档处理 ═══
pip install marker-pdf      # PDF → Markdown
pip install surya-ocr       # 多语种 OCR

# ═══ 翻译 ═══
pip install transformers    # NLLB / OPUS-MT
```

## 8. 参考资源

| 工具 | 链接 |
|:---|:---|
| oMLX | oMLX 官方 (Apple Silicon MLX 优化推理) |
| mflux | [github.com/filipstrand/mflux](https://github.com/filipstrand/mflux) |
| ltx-video-mac | [github.com/james-see/ltx-video-mac](https://github.com/james-see/ltx-video-mac) |
| Wan2.2-mlx | [github.com/osama-ata/Wan2.2-mlx](https://github.com/osama-ata/Wan2.2-mlx) |
| F5-TTS | [github.com/SWivid/F5-TTS](https://github.com/SWivid/F5-TTS) |
| CosyVoice | [github.com/FunAudioLLM/CosyVoice](https://github.com/FunAudioLLM/CosyVoice) |
| GOT-OCR2 | [huggingface.co/stepfun-ai/GOT-OCR2_0](https://huggingface.co/stepfun-ai/GOT-OCR2_0) |
| Marker | [pypi.org/project/marker-pdf](https://pypi.org/project/marker-pdf/) |
| Draw Things | macOS App Store 免费 |
