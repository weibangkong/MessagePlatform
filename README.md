# MessagePlatform

#### 介绍
这是一个集中式统一消息发送平台，用以集成多种消息推送渠道，避免多次开发

#### 软件架构
当前实现为轻量的“事件分发 + 观察者发送”架构：

- `Main`：组装消息并触发事件
- `MessageEvent`：根据消息中的渠道构建发送器并执行发送
- `MessageListenerFactory`：按渠道创建具体发送观察者
- `IMessageObserver`：各渠道发送行为抽象（短信、微信、邮件、飞书、站内）


##### 技术架构
web接入:
消息队列: RabbitMQ



主流程：

1. 组装 `Message`（内容、发送者、接收者、渠道）
2. `MessageEvent.creatEvent(message)` 根据渠道构建对应观察者
3. `event.handle()` 依次调用观察者 `send(...)`

#### 安全认证
已新增可插拔认证模块，默认不启用，不影响原有发送逻辑。

认证接入点：

- 在 `MessageEvent.handle()` 前置调用统一鉴权
- 鉴权通过后，保持原发送链路不变

可用模式：

- `NONE`（默认）：不鉴权
- `HMAC_SHA256`：对发送者签名进行校验

启用 HMAC 模式示例（JVM 参数）：

```bash
-Dmessage.auth.mode=HMAC_SHA256
-Dmessage.auth.secret=your_secret
-Dmessage.auth.maxSkewSeconds=300
```

签名明文格式：

`appId|title|timestamp|nonce`

然后用 `HmacSHA256(secret, 明文)` 得到十六进制小写字符串，填入 `Sender.signature`。


#### 安装教程

1.  xxxx
2.  xxxx
3.  xxxx

#### 使用说明

1.  构建 `Message` 并设置渠道集合
2.  调用 `MessageEvent.creatEvent(message)` 创建事件
3.  调用 `event.handle()` 触发消息发送

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md




#### TODO
- 消息接收：http api接入，并负责将消息推入队列
- 消息堆积：引入MQ，每种渠道一个消息队列，
- 消息发送： 每个渠道持有一个线程池，线程池中每个线程持有一个httpClient实例，负责从MQ队列中拿去消息，先进先出，并执行发送(尝试epool多路复用实现)
- 消息的格式化是由消息接收实现还是消息发送实现
- 投递失败的补偿处理应该是什么
- 