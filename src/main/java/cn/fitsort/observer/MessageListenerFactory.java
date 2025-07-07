package cn.fitsort.observer;

import cn.fitsort.entity.MessagePushChannelEnum;
import cn.fitsort.observer.*;

import java.lang.reflect.InvocationTargetException;
import java.util.HashMap;
import java.util.Map;

/**
 * 消息监听器工厂
 *
 * @author: weibang kong
 * @date: 2025-04-24 11:44:19
 */
public class MessageListenerFactory {

    private static final Map<MessagePushChannelEnum, Class<? extends IMessageObserver>> MAPPING = new HashMap<MessagePushChannelEnum, Class<? extends IMessageObserver>>() {{
        put(MessagePushChannelEnum.FEISHU, FeishuMessageObserver.class);
        put(MessagePushChannelEnum.SMS, SmsMessageObserver.class);
        put(MessagePushChannelEnum.WX, WxMessageObserver.class);
        put(MessagePushChannelEnum.EMAIL, EmailMessageObserver.class);
        put(MessagePushChannelEnum.WEB, WebNotifyMessageObserver.class);
    }};

    public static IMessageObserver createMessageObserver(MessagePushChannelEnum messagePushChanel) throws NoSuchMethodException, InvocationTargetException, InstantiationException, IllegalAccessException {
        Class<? extends IMessageObserver> obseverClass = MAPPING.get(messagePushChanel);
        return obseverClass.getDeclaredConstructor().newInstance();
    }
}
