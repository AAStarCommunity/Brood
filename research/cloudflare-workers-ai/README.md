# Cloudflare Workers AI 开源模型可用性调研

> 调研日期:2026-08-05 · 数据来源:Cloudflare 官方文档、blog、changelog(链接见文末)
> 调研问题:Cloudflare 能不能直接提供最新的开源模型 API(GLM / DeepSeek / Kimi / MiniMax / Qwen 等),
> 从而让「应用」和「AI」在同一个运行时里有机结合?

## 结论先行

**能,而且比预期好。** 你点名的模型**几乎全部可用**,并且**全部通过同一个 `env.AI.run()` 调用、
只需 Cloudflare 自己的 token**——不需要去各家申请 API key、不需要管各家的计费。

但有一条**关键分界线**必须先讲清楚,它决定了成本可预测性和数据边界:

| | **Cloudflare 自托管** | **第三方(合作方托管)** |
|:---|:---|:---|
| 跑在哪 | Cloudflare 自己的 GPU 上 | 合作方基础设施(如 DeepSeek V4 Pro 走 Fireworks) |
| 调用方式 | `env.AI.run('@cf/...')` | `env.AI.run('deepseek/deepseek-v4-pro')` —— **完全一样** |
| 要不要自带 key | 否 | **否**,仍用 Cloudflare token,Cloudflare 统一计费 |
| 价格 | **公开**,文档里有每百万 token 单价 | **只在 dashboard 可见**,文档不公布 |
| 免费额度 | 计入每天 10,000 Neurons | 需自行确认(文档未明确) |
| 数据边界 | 不出 Cloudflare | 出网到合作方(MiniMax 标注 zero data retention) |

**对你的判断影响**:自托管那批可以直接按公开价做成本模型;第三方那批**必须先去 dashboard 查价再决定**,
不要假设它和自托管一个量级。

## 你点名的模型:逐个对照

| 你问的 | 实际情况 | 模型 ID | 托管 |
|:---|:---|:---|:---|
| **GLM 5.2** | ✅ **有**,2026-06-16 上线 | `glm-5.2` | Cloudflare |
| GLM 5.3 | ❌ 没有(目录最高到 5.2) | — | — |
| **DeepSeek V4** | ✅ **有 V4 Pro**(非 flash) | `deepseek/deepseek-v4-pro` | 第三方(Fireworks) |
| DeepSeek V4 Flash | ❌ 没有 flash 变体 | — | — |
| **Kimi 3** | ✅ **有**,**1M 上下文** | `moonshotai/kimi-k3` | 第三方 |
| **MiniMax** | ✅ **有 M3**(还有 M2.7) | `minimax/m3` | 第三方 |
| "h3" | ⚠️ 未找到对应模型,疑为口误 | — | — |

**另外还有几个你没问但值得注意的**,而且都是 Cloudflare 自托管(价格公开、延迟低):

- `glm-4.7-flash` —— 131K 上下文,**$0.06/M 输入**,便宜到可以当默认档
- `kimi-k2.7-code` —— 1T 参数 MoE / 32B 激活,262K 上下文,代码专用
- `gpt-oss-120b` / `gpt-oss-20b` —— OpenAI 开源权重
- `llama-4-scout-17b-16e-instruct` —— Llama 4 MoE
- `qwen3-30b-a3b-fp8` —— **$0.051/M 输入**,全目录最便宜的能打模型
- `gemma-4-26b-a4b-it` —— 256K 上下文 + 视觉 + thinking
- `nemotron-3-120b-a12b` —— NVIDIA,面向多 agent 场景

## 价格(Cloudflare 自托管,公开数据)

免费额度:**每天 10,000 Neurons**;超出后 **$0.011 / 1,000 Neurons**。

| 模型 | 输入 $/M | 输出 $/M | 备注 |
|:---|---:|---:|:---|
| `qwen3-30b-a3b-fp8` | 0.051 | 0.335 | 最便宜 |
| `glm-4.7-flash` | 0.060 | 0.400 | 131K 上下文,工具调用强 |
| `gpt-oss-20b` | 0.200 | 0.300 | 输出便宜 |
| `llama-4-scout-17b` | 0.270 | 0.850 | |
| `gpt-oss-120b` | 0.350 | 0.750 | |
| `nemotron-3-120b` | 0.500 | 1.500 | |
| `kimi-k2.6` / `k2.7-code` | 0.950 | 4.000 | **需 Workers Paid 计划** |
| `glm-5.2` | 1.400 | 4.400 | **需 Workers Paid 计划** |

> 对比参考:同档次商用 API 里,`qwen3-30b` 的 $0.051/M 属于第一梯队的便宜;
> `glm-5.2` 的 $1.4/$4.4 与主流闭源中端模型接近,但你换来的是**开源权重 + 同运行时**。

## 为什么这对「应用 + AI 有机结合」是实质利好

1. **零网络跳数**。模型推理和你的 Worker 在**同一个边缘节点**,不是「Worker 去调远端 API」。
   对话式、流式、多轮工具调用的首字延迟差别很大。
2. **一套凭证、一套计费**。不用为 GLM/Kimi/MiniMax/DeepSeek 各开一个账号、各管一套 key 和额度。
3. **和 Cloudflare 其余原语天然组合**:Durable Objects 存会话、KV/R2 存产物、Queues 做异步、
   Workflows 编排、Vectorize 做 RAG、AI Gateway 做缓存与限流——都在同一账号同一运行时里。
4. **换模型是改一个字符串**。`env.AI.run()` 的第一个参数就是模型 ID,自托管和第三方**调用形状完全一致**,
   意味着可以按成本/质量在模型间灰度切换而不改架构。

## 上新速度(决定「最新模型多久能用上」)

从 changelog 看,2026 年的节奏是**每月 6–20 个模型变更**:

| 日期 | 事件 |
|:---|:---|
| 2026-06-16 | GLM-5.2 上线(262K 上下文、函数调用、reasoning) |
| 2026-06-12 | Kimi K2.7 Code 上线(**4 天内两个大模型**) |
| 2026-05-08 | 一次性弃用 19 个老模型(Llama 3/3.1、Mistral 7B、Gemma 7B、Phi-2…) |
| 2026-04-20 | Kimi K2.6 |
| 2026-04-04 | Gemma 4 26B |
| 2026-03-19 | Kimi K2.5 + Prompt caching + 异步批处理 API 重构 |
| 2026-03-11 | NVIDIA Nemotron 3 Super |
| 2026-02-13 | GLM-4.7-Flash |

**判断:上新很快**(开源模型发布后通常数周内),但**弃用也快** —— 5 月一次砍掉 19 个。
所以生产代码**不要硬编码具体模型 ID**,要留一层映射,并关注 changelog 的 deprecation 公告。

## 技术底子(说明这不是简单转发)

Cloudflare 为跑大模型做了实打实的工程,见 [smaller-faster-safer-models](https://blog.cloudflare.com/smaller-faster-safer-models/):

- **KV Cache 量化** BF16→FP8:缓存减半,Kimi K2.6 上下文容量 686K→**1.37M tokens**,峰值并发吞吐 **+41%**
- **权重压缩** INT8→INT4:GLM 体积 705GB→**421GB**(-40%),同硬件可放 1.18M tokens KV cache;
  低并发解码吞吐 **+55%**(60→92 tokens/s)
- **prefill/decode 池分离**:解码用 INT4、预填用 FP8,各取所长
- **缓存完整性校验**:防止请求读到别人的 cache page,开销 <1%

这说明大模型是**真自托管**并做了针对性优化,不是贴牌代理。

## 风险与待确认项

| 项 | 说明 | 怎么办 |
|:---|:---|:---|
| **第三方模型价格不透明** | DeepSeek V4 Pro / Kimi K3 / MiniMax M3 的价格**只在 dashboard** | 决策前必须登 dashboard 实测查价 |
| **第三方数据出网** | 推理发生在合作方(Fireworks 等)基础设施 | 敏感数据只用自托管那批;MiniMax 标了 zero-retention 但需自行核实合同 |
| **弃用节奏快** | 单次砍 19 个模型有先例 | 模型 ID 收敛到一处配置;订阅 changelog |
| **贵模型需付费计划** | `glm-5.2` / `kimi-k2.*` 要 Workers Paid | 免费额度只够验证,不够生产 |
| **免费额度对第三方是否适用未明确** | 文档没说 | 同样要 dashboard 确认 |

## 建议的落地路径

1. **先用自托管的便宜档验证形态**:`qwen3-30b-a3b-fp8`($0.051/M)或 `glm-4.7-flash`($0.06/M),
   免费额度就能跑通端到端。
2. **需要强推理/长上下文再上 `glm-5.2` 或 `kimi-k2.7-code`**,此时价格与闭源中端持平,但权重开源。
3. **1M 上下文场景**(整仓代码、长文档)才考虑 `moonshotai/kimi-k3` —— **先查价**。
4. **架构上留模型映射层**,避免硬编码;配合 AI Gateway 做缓存/限流/可观测。

---

## 数据来源

- [Workers AI Models 目录](https://developers.cloudflare.com/workers-ai/models/) —— 自托管模型清单
- [Cloudflare AI Models 全目录(214 个)](https://developers.cloudflare.com/ai/models/) —— 含第三方
- [Workers AI 定价](https://developers.cloudflare.com/workers-ai/platform/pricing/)
- [Workers AI Changelog](https://developers.cloudflare.com/workers-ai/changelog/)
- [Blog: Smaller, faster, safer — running Kimi and GLM at scale](https://blog.cloudflare.com/smaller-faster-safer-models/)
- [Blog: Powering the agents — Workers AI now runs large models](https://blog.cloudflare.com/workers-ai-large-models/)
- [DeepSeek V4 Pro 模型页](https://developers.cloudflare.com/ai/models/deepseek/deepseek-v4-pro/)
- [Kimi K3 模型页](https://developers.cloudflare.com/ai/models/moonshotai/kimi-k3/)
- [kimi-k2.7-code 模型页](https://developers.cloudflare.com/workers-ai/models/kimi-k2.7-code/)
- [计划弃用公告(2026-05-08)](https://developers.cloudflare.com/changelog/post/2026-05-08-planned-model-deprecations/)
