package cn.fitsort.entity;

import java.util.HashSet;
import java.util.Set;

/**
 * 消息事件
 *
 * @author: weibang kong
 * @date: 2025-04-24 11:36:59
 */
public class Message<M extends MessageContent, R extends Receiver, S extends Sender> {

    /**
     * 消息内容
     */
    private M content;

    /**
     * 接收人信息
     */
    private R receiver;

    /**
     * 发送人信息
     */
    private S sender;

    /**
     * 推送渠道
     */
    private Set<String> pushChannels;

    public Message() {
        this.pushChannels = new HashSet<>();
    }

    public Message(M content, R receiver, S sender) {
        this.content = content;
        this.receiver = receiver;
        this.sender = sender;
        this.pushChannels = new HashSet<>();
    }

    public M getContent() {
        return content;
    }

    public void setContent(M content) {
        this.content = content;
    }

    public R getReceiver() {
        return receiver;
    }

    public void setReceiver(R receiver) {
        this.receiver = receiver;
    }

    public S getSender() {
        return sender;
    }

    public void setSender(S sender) {
        this.sender = sender;
    }

    public Set<String> getPushChannels() {
        return pushChannels;
    }

    public void setPushChannels(Set<String> pushChannels) {
        this.pushChannels = pushChannels;
    }
}
