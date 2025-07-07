package cn.fitsort.observer;

import cn.fitsort.entity.Message;

/**
 * 消息观察者顶级抽象
 *
 * @author: weibang kong
 * @date: 2025-04-24 11:36:00
 */
public interface IMessageObserver {
    void messageFormat(Message event);

    void send(Message event);

    void doLog();
}
