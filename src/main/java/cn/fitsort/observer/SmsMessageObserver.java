package cn.fitsort.observer;

import cn.fitsort.entity.Message;

/**
 * 短信消息观察者
 *
 * @author: weibang kong
 * @date: 2025-04-24 11:39:08
 */
public class SmsMessageObserver implements IMessageObserver {
    @Override
    public void messageFormat(Message event) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("[ ").append(event.getSender().getTitle()).append(" ]").append("通过 [短信] 发送给[ ").append(event.getReceiver().getWxuser()).append(" ]");
        stringBuilder.append("消息内容如下：[");
        stringBuilder.append(event.getContent().getContent());
        stringBuilder.append(" ]");
    }

    @Override
    public void send(Message event) {
        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append("[ ").append(event.getSender().getTitle()).append(" ]").append("通过 [短信] 发送给[ ").append(event.getReceiver().getWxuser()).append(" ]");
        stringBuilder.append("消息内容如下：[");
        stringBuilder.append(event.getContent().getContent());
        stringBuilder.append(" ]");
        System.out.println(stringBuilder.toString());
    }

    @Override
    public void doLog() {

    }
}
