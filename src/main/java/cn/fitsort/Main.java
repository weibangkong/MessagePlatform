package cn.fitsort;

import cn.fitsort.entity.*;

import java.lang.reflect.InvocationTargetException;
import java.util.HashSet;
import java.util.Set;

public class Main {
    public static void main(String[] args) {
        System.out.println("Hello world!");
        MessageContent content = new MessageContent();
        Receiver receiver = new Receiver();
        content.setContent("我想找个好玩的游戏，你能陪我一起玩么");
        receiver.setTelphone("1234567689");
        Sender sender = new Sender();
        sender.setTitle("who");
        Message message = new Message();
        message.setContent(content);
        message.setReceiver(receiver);
        message.setSender(sender);
        Set<MessagePushChannelEnum> pushChannelEnums = new HashSet<>();
        pushChannelEnums.add(MessagePushChannelEnum.SMS);
        message.getPushChannels().add(MessagePushChannelEnum.SMS);

        try {
            MessageEvent event = MessageEvent.creatEvent(message);
            event.handle();
        } catch (InvocationTargetException e) {
            throw new RuntimeException(e);
        } catch (NoSuchMethodException e) {
            throw new RuntimeException(e);
        } catch (InstantiationException e) {
            throw new RuntimeException(e);
        } catch (IllegalAccessException e) {
            throw new RuntimeException(e);
        }
    }
}