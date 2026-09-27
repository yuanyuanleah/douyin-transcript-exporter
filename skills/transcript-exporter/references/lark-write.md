# 飞书多维表格写入细节

## lark-cli 身份与路径

### 身份检测
运行以下命令确认当前 lark-cli 登录的用户：
```bash
lark-cli api GET /open-apis/authen/v1/user_info --as user
```
- 返回 `name` 字段即为当前登录用户。
- 沙箱环境的 lark-cli 可能登录的是测试账号（如"来点羊蝎子"），无用户文档权限。

### 路径优先级
1. **优先使用系统 lark-cli**：Mac 默认 `/opt/homebrew/bin/lark-cli`，Windows 用 `where lark-cli` 查找。
2. **沙箱 lark-cli 作为备选**：系统 lark-cli 不存在时使用沙箱版本。
3. 两种身份都无目标表格权限时，告知用户需要在飞书文档中添加协作者或切换 lark-cli 登录账号。

### 版本要求
- 使用支持本文 base shortcut 命令的 lark-cli；运行前通过对应命令的 `--help` 确认参数（发布时已对照本机 1.0.87 核对主要示例）。
- 查看版本：`lark-cli --version`

## 表格链接解析

### 支持的链接格式
- Wiki 链接：`https://my.feishu.cn/wiki/xxxxx?table=tblxxxxx&view=vewxxxxx`
- Base 直链：`https://my.feishu.cn/base/xxxxx?table=tblxxxxx`
- 两种都可直接用 `+url-resolve` 解析。

### 解析命令
```bash
lark-cli base +url-resolve --url "<表格URL>" --as user
```
返回字段：
- `base_token`：Base 的唯一标识，后续所有操作都需要
- `table_id`：数据表 ID（`tbl` 开头）
- `view_id`：视图 ID（`vew` 开头）
- `wiki_node_token`：如果是 wiki 链接，返回 wiki 节点 token

### 常见错误
| 错误码 | 原因 | 处理 |
|--------|------|------|
| 131006 | 当前用户无权限访问该文档 | 切换 lark-cli 身份，或在飞书中添加协作者 |
| invalid url | URL 格式不正确 | 检查是否为有效的飞书 wiki/base 链接 |

## 字段管理

### 查看现有字段
```bash
lark-cli base +field-list --base-token <token> --table-id <id> --as user
```
返回每个字段的 `id`、`name`、`type`。

### 字段定义（基础9字段 + AI扩展2字段）

**基础采集字段（9个，从抖音页面直接采集）：**

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 账号名称 | text | 博主昵称，如"孟湄"；用文本类型避免 select 选项管理，支持任意博主名直接写入 |
| 标题 | text | 视频标题 |
| 介绍 | text | 视频文案/描述 |
| 逐字稿 | text | 完整口播逐字稿 |
| 点赞 | number | 点赞数（整数） |
| 评论 | number | 评论数（整数） |
| 转发 | number | 转发数（整数） |
| 发表日期 | datetime | 发布时间 |
| 视频链接 | text | 视频 URL |

**AI扩展字段（2个，基于逐字稿由AI生成，目标表格存在时才写入）：**

| 字段名 | 类型 | 说明 |
|--------|------|------|
| 选题方向 | select（多选） | 从目标表格已有选项中选择1-3个标签，禁止自行新增选项 |
| 主题总结 | text | 一句话（30-80字）概括视频核心观点，提炼本质不重复标题 |

### 创建字段

#### 单个创建
```bash
lark-cli base +field-create --base-token <token> --table-id <id> \
  --json '{"name":"标题","type":"text"}' --as user
```

#### 批量创建（推荐）
```bash
lark-cli base +field-create --base-token <token> --table-id <id> \
  --json '[{"name":"账号名称","type":"text"},{"name":"标题","type":"text"},...]' \
  --as user
```

#### 字段类型 JSON 格式
- **text**：`{"name":"xxx","type":"text"}`
- **number**：`{"name":"xxx","type":"number"}`
- **datetime**：`{"name":"xxx","type":"datetime"}`
- **select（单选）**：`{"name":"xxx","type":"select","multiple":false,"options":[{"name":"选项A"},{"name":"选项B"}]}`
- **multiselect（多选）**：`{"name":"xxx","type":"select","multiple":true,"options":[...]}`

注意：飞书 API 中多选字段的 type 也是 `select`，通过 `multiple: true` 区分，不是 `multiselect`。

### 重命名字段
```bash
lark-cli base +field-update --base-token <token> --table-id <id> \
  --field-id <field_id> --json '{"name":"新名称","type":"text"}' --yes --as user
```
- `+field-update` 是完整 PUT 语义，必须传入完整的字段定义（name + type），不能只传 name。
- 主字段（第一个字段）不能删除，只能重命名。如果目标表格的主字段是默认的"文本"且为空，应将其重命名为"标题"。

### 转换字段类型
- text → select：直接用 `+field-update` 传入新类型，原有文本值会自动映射为选项（如果匹配）。
- select → text：同样可直接转换；本项目「账号名称」字段已统一为 text，新采集写入无需选项管理。
- 转换后建议用 `+record-get` 抽样验证数据是否正确保留。

### 删除字段
```bash
lark-cli base +field-delete --base-token <token> --table-id <id> \
  --field-id <field_id> --yes --as user
```
- 主字段不能删除，会返回 `unsafe_operation_blocked` 错误。
- 删除前确认字段中没有需要保留的数据。

## 记录写入

### CellValue 格式

| 字段类型 | 写入格式 | 示例 |
|----------|----------|------|
| text | 字符串 | `"你越强势，AI可能越蠢"` |
| number | 数字 | `3091` |
| datetime | 字符串或毫秒时间戳 | `"2026-07-27 20:02"` 或 `1785153720000` |
| select（单选） | 数组（含1个元素） | `["孟湄"]` |
| multiselect（多选） | 数组（含多个元素） | `["AI协作方法","认知思维"]` |
| url/phone | 字符串 | `"https://www.douyin.com/video/xxx"` |

### 批量创建记录
```bash
lark-cli base +record-batch-create --base-token <token> --table-id <id> \
  --json '{"create_records":[{"标题":"xxx","点赞":3091,"账号名称":"孟湄",...},...]}' \
  --as user
```
- 单批最多 200 条记录。
- 超过 200 条时分批写入，批次间短暂等待（避免 1254291 并发冲突）。
- 返回 `record_id_list`，可用于后续验证。

### 逐条更新记录（upsert）
```bash
lark-cli base +record-upsert --base-token <token> --table-id <id> \
  --record-id <record_id> \
  --json '{"标题":"新标题","点赞":9999}' --as user
```
- 带 `--record-id` 时为更新，不带时为创建。
- 适合增量更新单条记录的部分字段。

### 从 JSON 文件读取
当记录数据较大时（如含长逐字稿），建议写入文件后用 `@file` 引用：
```bash
# 写入 records.json
lark-cli base +record-batch-create ... --json @./records.json --as user
```
- `@file` 路径必须是相对于当前工作目录的相对路径，不能用绝对路径。
- JSON 文件需 UTF-8 编码。

## 增量去重逻辑

### 获取已有记录
```bash
lark-cli base +record-list --base-token <token> --table-id <id> \
  --limit 200 --offset 0 --format json --as user
```
- 返回 `data.data`（二维数组）和 `data.fields`（字段名列表）。
- 找到"视频链接"字段的索引，提取已有视频链接。必须逐页读取直到 `has_more` 为 false；按已读取条数推进 `--offset`，不能只查第一页。分析时同时按账号名称筛选当前博主；多个账号共用表格时不得混算。

### 去重判断
```python
existing_urls = set(已有视频链接列表)
new_records = [v for v in 采集结果 if v['url'] not in existing_urls]
```
- 按完整视频 URL 去重（`https://www.douyin.com/video/<video_id>`）。
- 也可按 video_id 去重（从 URL 中提取数字部分）。

### 全量覆盖模式
用户明确要求"全量覆盖"或"重新导入"时：
1. 逐页读取当前账号已有记录，建立视频链接 → record_id 映射。
2. 已有链接用 `+record-batch-update` 更新同一记录；新链接用 `+record-batch-create` 新增。
3. 保留本次未采到的旧记录，不删除、不重复追加；若用户另行要求删除，需要明确列出记录范围并确认。

## 常见错误与恢复

| 错误码/现象 | 原因 | 处理 |
|-------------|------|------|
| 1254015 字段值类型不匹配 | CellValue 格式错误 | 检查字段类型，单选/多选必须用数组 |
| 1254045 字段名不存在 | 字段名拼写错误或字段未创建 | 先 `+field-list` 确认真实字段名 |
| 1254104 批量超过200 | 单批记录数超限 | 分批写入，每批≤200 |
| 1254291 并发写冲突 | 短时间内多次写入 | 串行写入，批次间 sleep 1-2秒 |
| 91403 无权限 | 当前用户无表格编辑权限 | 切换 lark-cli 身份或添加协作者 |
| 800080207 主字段不能删除 | 尝试删除第一个字段 | 改为重命名主字段 |
| 日期字段格式错误 | 日期字符串格式不对 | 用 `"YYYY-MM-DD HH:MM"` 或毫秒时间戳 |
| `--json @file` 路径错误 | 用了绝对路径 | 改为相对于当前目录的相对路径 |

## 验证写入结果

写入完成后，必须执行数据质量验证（不只是抽样1-2条）：

### 1. 全量占位符检查
用 `+record-list` 读取本次新写入的所有记录，检查逐字稿字段：
```python
# 只检测整段占位说明，正常口播中出现相同词语不构成失败
placeholders = {"完整内容已通过web.fetch获取", "完整内容已获取", "内容已获取", "已获取完整内容"}
for record in new_records:
    transcript = str(record.get("逐字稿") or "").strip().rstrip("。.!！")
    if transcript in placeholders:
        print(f"需要重新获取逐字稿：{record['标题']}")
```
- 质量校验失败最多重试 1 次。逐字稿确实失败时纳入主 Skill Step 3 第4项的整批回退列表，启用后 ≤3 条在授权内直接执行、>3 条先确认整批。不得在校验循环中单独下载、重复回退或拆批绕过确认；回退仍失败时保留基础数据与原因并交付。

### 2. 长度与空值检查
- 短正文或末尾无标点只需复核，不能单独判定为缺失。
- 无口播、用户不要逐字稿或获取失败且有原因时，允许逐字稿为空；原视频未提供介绍或日期时如实留空。
- 视频链接、账号名称必须正确；互动数保存为整数，未知值留空，不能将缺失值假称为 0。

### 3. 抽样详细验证
抽样1-2条记录用 `+record-get` 详细检查：
```bash
lark-cli base +record-get --base-token <token> --table-id <id> \
  --record-id <record_id> --as user
```
- 检查各字段值是否正确（尤其是单选字段、日期字段、长文本字段）。
- 确认记录总数与预期一致。

### 4. 验证不通过的处理
- 占位符问题：重新获取完整逐字稿 → 更新记录 → 再次验证。
- 长度过短：检查是否为纯音乐视频，否则重新获取。
- 关键字段为空：重新采集该条数据的对应字段。
- 每条最多重试 1 次；仍失败时明确报告并继续交付已有数据，不无限循环。

---

## 本地保存分支（用户明确不用表格时）

用户在前置检查中明确表示不用飞书表格时，将采集结果保存为本地文件，采用**每批单独目录 + 每个视频单独 Markdown 文件**的结构。

### 目录结构

```
douyin_data/
└── {博主昵称}_{日期}_{数量}条/
    ├── 01_{video_id}.md
    ├── 02_{video_id}.md
    ├── 03_{video_id}.md
    ├── ...
    └── _all.json          （必需，汇总所有数据与状态的 JSON 文件）
```

### 批次目录命名

- **根目录**：当前工作目录下的 `douyin_data/` 文件夹。
- **批次子目录**：`{博主昵称}_{采集日期YYYYMMDD}_{视频数量}条/`
  - 示例：`瑶瑶_20260827_50条/`
- 博主昵称含特殊字符时，替换为下划线或去掉特殊字符。
- 每批采集单独建目录，不同批次互不干扰。

### 每个视频的 Markdown 文件

- **文件命名**：`{序号}_{video_id}.md`
  - 序号按本轮目标顺序（最新模式按日期、Top N 模式按点赞排名）从 01 开始，至少补齐2位，超过99条用3位。
  - 示例：`01_7655189977860862854.md`、`02_7654993145986808761.md`

- **文件内容格式**：
  ```markdown
  # {视频标题}

  ## 基本信息
  - **账号名称**：{博主昵称}
  - **发表日期**：{YYYY-MM-DD HH:MM}
  - **视频链接**：{url}
  - **点赞**：{点赞数}
  - **评论**：{评论数}
  - **转发**：{转发数}

  ## 介绍/文案
  {视频介绍或文案全文}

  ## 选题方向
  {标签1}、{标签2}、{标签3}

  ## 主题总结
  {一句话主题总结，30-80字}

  ## 逐字稿
  {完整口播逐字稿全文，禁止写占位符}
  ```

- 章节顺序固定：标题 → 基本信息 → 介绍/文案 → 选题方向 → 主题总结 → 逐字稿。
- 逐字稿为空时（纯音乐/无口播视频），写"无逐字稿（视频无口播内容）"。

### 汇总 JSON 文件（必需）

在批次目录下同时保存 `_all.json`，包含所有视频的结构化数据，便于后续程序处理：

```json
[
  {
    "video_id": "7655189977860862854",
    "url": "https://www.douyin.com/video/7655189977860862854",
    "序号": "01",
    "账号名称": "瑶瑶",
    "标题": "你越强势，AI可能越蠢",
    "介绍": "很多人以为把要求说清楚AI就能做好...",
    "逐字稿": "你越强势，AI效果就越蠢。你一定听过一个观点...",
    "点赞": 3091,
    "评论": 78,
    "转发": 543,
    "发表日期": "2026-07-27 20:02",
    "选题方向": ["AI协作方法", "认知思维"],
    "主题总结": "探讨强势指令对AI效果的负面影响，建议用引导式提问替代命令式要求。"
  }
]
```

### Python 保存示例

```python
import json
import os

# 数据列表（每条包含所有字段）
data = [...]

# 批次目录
author = "瑶瑶"
date = "20260827"
count = len(data)
batch_dir = f"douyin_data/{author}_{date}_{count}条"
os.makedirs(batch_dir, exist_ok=True)

# 序号位数
pad = len(str(count)) if count > 9 else 2

# 为每个视频生成 Markdown 文件
for i, item in enumerate(data, 1):
    seq = str(i).zfill(pad)
    video_id = item["video_id"]
    md_path = os.path.join(batch_dir, f"{seq}_{video_id}.md")

    # 选题方向转为顿号分隔
    topics = item.get("选题方向", [])
    topics_str = "、".join(topics) if topics else "无"

    md_content = f"""# {item['标题']}

## 基本信息
- **账号名称**：{item['账号名称']}
- **发表日期**：{item['发表日期']}
- **视频链接**：{item['url']}
- **点赞**：{item['点赞']}
- **评论**：{item['评论']}
- **转发**：{item['转发']}

## 介绍/文案
{item.get('介绍', '无')}

## 选题方向
{topics_str}

## 主题总结
{item.get('主题总结', '无')}

## 逐字稿
{item.get('逐字稿', '无逐字稿（视频无口播内容）')}
"""
    with open(md_path, "w", encoding="utf-8") as f:
        f.write(md_content)

# 保存汇总 JSON（必需，供恢复与分析使用）
json_path = os.path.join(batch_dir, "_all.json")
with open(json_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
```

### 本地保存的数据质量验证

保存后必须执行验证：

1. **目录与文件数量检查**：批次目录已创建，Markdown 文件数量 = 预期采集数量。
2. **文件命名检查**：文件名符合 `{序号}_{video_id}.md` 格式，序号连续无重复。
3. **Markdown 结构检查**：抽样读取2-3个文件，确认包含所有章节（基本信息、介绍/文案、选题方向、主题总结、逐字稿）。
4. **占位符检查**：逐字稿不能仅为占位说明，正常正文包含同名词语时不判失败。
5. **长度检查**：短正文复核；有记录的无口播、失败或原始信息缺失允许留空，不能反复重试真实缺失值。
6. **格式检查**：点赞、评论、转发为整数；发表日期格式为 `YYYY-MM-DD HH:MM`；选题方向为1-3个标签。

可恢复错误最多重试 1 次，更新同一 Markdown 文件；仍失败则缓存原因并在交付中报告。

### 交付文件

验证通过后，用 `present_files` 工具将批次目录交付给用户：
- 说明批次目录路径、视频数量、文件结构（每个视频一个 Markdown 文件，含基本信息、介绍、选题方向、主题总结、逐字稿）。
- 如有逐字稿获取失败的记录，在交付说明中标注对应文件名。
- 如有汇总 JSON 文件，一并说明。
