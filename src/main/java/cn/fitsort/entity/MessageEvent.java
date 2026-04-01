package cn.fitsort.entity;

import cn.fitsort.observer.MessageListenerFactory;
import cn.fitsort.observer.IMessageObserver;
import cn.fitsort.security.AuthContext;
import cn.fitsort.security.AuthManager;

import java.lang.reflect.InvocationTargetException;
import java.util.HashSet;
import java.util.Set;

/**
 * 消息事件
 *
 * @author: weibang kong
 * @date: 2025-04-24 16:58:08
 */
public class MessageEvent {
    Message message;
    Set<MessagePushChannelEnum> pushChannels;
    Set<IMessageObserver> senderHandlers;


    public void handle() {
        // 统一前置鉴权，不影响后续发送器分发逻辑
        AuthManager.getAuthenticator().authenticate(new AuthContext(message));
        for (IMessageObserver senderHandler : senderHandlers) {
            senderHandler.send(message);
        }
    }

    private void doLog() {
        // TODO 添加实现，做消息发送记录，这里其实由各个发送器执行更好

    }

    public static MessageEvent creatEvent(Message message) throws InvocationTargetException, NoSuchMethodException, InstantiationException, IllegalAccessException {
        MessageEvent event = new MessageEvent();
        event.message = message;
        event.pushChannels = message.getPushChannels();

        // 依据pushChannels创建所需的发送器
        for (MessagePushChannelEnum pushChannel : event.pushChannels) {
            IMessageObserver messageObserver = MessageListenerFactory.createMessageObserver(pushChannel);
            event.senderHandlers.add(messageObserver);
        }

        return event;
    }

    public MessageEvent() {
        this.pushChannels = new HashSet<>();
        this.senderHandlers = new HashSet<>();
    }
}
