xiaozibao - 小字报
=========
## Pick posts as good as possible, as relevant as possible

### Remove posts of low quality
- [Too short] over 900 words for English, 800 for Chinese
- [Too lengthy] less than 3000 characters for English, 10000 for Chinese

### Adjust score based on users view history

### Caculate the relevancy among posts

## Data Structure
| Num | Name                                                                 | Comment                                                    |
|:----|----------------------------------------------------------------------|------------------------------------------------------------|
|   1 | #.data头部，每一行代表则一个k:v的元数据属性                            | 该行第一个:为键值对的分隔符                                |
|   2 | #.data中meta data与data是以一行特殊的字符串来分隔                      | --text follows this line--                                 |
|   3 | 文件夹中含有_webcrawler_字符串的，表示该文件夹数据为网络爬虫抓取来的    |                                                            |
|   4 | 文件夹中含有_done_字符串的，表示该文件夹数据为已投放                   |                                                            |
|   5 | 文件夹中含有_raw_字符串的，表示该文件夹数据为未确认数据                | 调用xzb_update_category.sh,该数据的meta data不会被自动更新 |

## 数据规范
- 标题: 5字 < 长度 < 10个汉字字 (如果是英文的话，则是限额为原有基础的三倍)
- 摘要: 15字 < 长度 < 34个汉字字 (如果是英文的话，则是限额为原有基础的三倍)
- 文章: 200字 < 长度 < 2000 字
