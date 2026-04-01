package cn.fitsort.security;

import cn.fitsort.entity.Message;

/**
 * 鉴权上下文
 */
public class AuthContext {
    private final Message message;
    private final long requestTimeSeconds;

    public AuthContext(Message message) {
        this.message = message;
        this.requestTimeSeconds = System.currentTimeMillis() / 1000;
    }

    public Message getMessage() {
        return message;
    }

    public long getRequestTimeSeconds() {
        return requestTimeSeconds;
    }
}
