# transcript-exporter

给豆包加一个整理抖音视频的小助手：把视频标题、文案、逐字稿和互动数据整理成可保存、可回看的资料。

**元元 Leah 整理分享 · 豆包工作专用 · 个人学习与研究**

[快速开始](#快速开始) · [完整使用指南](USAGE_GUIDE.md) · [下载最新版 ZIP](https://github.com/yuanyuanleah/transcript-exporter/archive/refs/heads/main.zip) · [反馈问题](https://github.com/yuanyuanleah/transcript-exporter/issues)

## 能帮你做什么

- **整理内容**：接收抖音博主主页、单条视频或分享短链，提取标题、文案和逐字稿。
- **保存数据**：整理点赞、评论、转发、发布日期和视频链接；保存为本地 Markdown + JSON，或写入你的飞书多维表格。
- **分析已采集的内容**：比较主题表现、评论与点赞的比例、发布时间分布，并整理主题分组。
- **接着上次继续**：保留采集进度，中断后恢复，避免重复新增已经保存的记录。

逐字稿获取失败时会保留基础数据并注明原因，不用占位文字冒充正文。

## 快速开始

### 手机入口

1. 复制本仓库链接：
   ```text
   https://github.com/yuanyuanleah/transcript-exporter
   ```
2. 手机打开豆包设置，选择「工作任务 Turbo」。
3. 切换后，在对话框中发送链接，并说：
   > 请读取这个仓库中的 skills/transcript-exporter/SKILL.md 和 references，帮我安装这个 Skill。

如果豆包提示无法读取仓库或安装，请按[完整使用指南](USAGE_GUIDE.md#3-安装)安装整个 Skill 文件夹，不要只复制 SKILL.md。

### 先试一条视频

安装后发送下面的指令，把链接换成你的目标视频：

> 用 transcript-exporter 整理这条抖音视频的标题、完整逐字稿和互动数据，保存到本地，不写飞书表格。视频链接：你的抖音视频链接。

确认这条视频的输出后，再尝试博主主页、分批采集或飞书写入。更多示例见[使用指南](USAGE_GUIDE.md#5-日常使用示例)。

## 获取最新版

- [下载完整仓库 ZIP](https://github.com/yuanyuanleah/transcript-exporter/archive/refs/heads/main.zip)：解压后，安装整个 `skills/transcript-exporter/` 文件夹，包含 `references/`。
- [查看 Skill 主文件](skills/transcript-exporter/SKILL.md)：用于了解当前执行规则。
- [阅读使用指南](USAGE_GUIDE.md)：安装、飞书配置、分批采集和常见问题。

<details>
<summary>详细配置：飞书写入与逐字稿回退</summary>

### 飞书写入

只保存本地时不需要飞书表格。选择写入飞书时，需要可用的 `lark-cli` 和你本人的飞书授权；可提供已有表格，也可按默认模板建表。具体步骤见[使用指南](USAGE_GUIDE.md#4-第一次使用关键)。

### 下载与妙记转写回退

网页逐字稿获取失败时，可以启用「下载音频并上传本人飞书妙记转写」：

- 使用者先明确启用；本任务整批待回退视频 ≤3 条时，在授权内直接执行，>3 条时先确认整批范围。
- 额外依赖 `doubao-video-extract` Skill 和本人飞书妙记授权；该依赖不随本仓库分发。
- 即使结果只保存本地，这条回退路径仍会上传音频到飞书妙记。可以要求「只用网页获取，禁止下载和上传」来关闭回退。
- 依赖缺失或回退失败时，保留基础数据并报告原因。

具体规则以 [SKILL.md](skills/transcript-exporter/SKILL.md) 为准。

</details>

## 使用范围与验证

本项目免费获取，采用 [CC BY-NC-SA 4.0](LICENSE) 许可，供个人学习与研究使用。请遵守平台规则，使用建议见 [USAGE_NOTES.md](USAGE_NOTES.md)。

发布前已检查文件结构、文档引用、上传脚本语法，并对照本机 lark-cli 帮助核对主要示例命令。手机安装、豆包采集及妙记回退的完整流程尚未实测；建议先用 1 条视频验证。

遇到问题或有改进建议，欢迎在 [Issues](https://github.com/yuanyuanleah/transcript-exporter/issues) 留言。

—— 元元 Leah｜AI × 内容 × 新机会
