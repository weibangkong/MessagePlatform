package cn.fitsort.entity;

/**
 * 发送人
 *
 * @author: weibang kong
 * @date: 2025-04-24 11:35:18
 */
public class Sender {
    /**
     * title
     */
    private String title;
    /**
     * 客户端标识
     */
    private String appId;
    /**
     * Unix 时间戳（秒）
     */
    private Long timestamp;
    /**
     * 随机串
     */
    private String nonce;
    /**
     * 签名
     */
    private String signature;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getAppId() {
        return appId;
    }

    public void setAppId(String appId) {
        this.appId = appId;
    }

    public Long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Long timestamp) {
        this.timestamp = timestamp;
    }

    public String getNonce() {
        return nonce;
    }

    public void setNonce(String nonce) {
        this.nonce = nonce;
    }

    public String getSignature() {
        return signature;
    }

    public void setSignature(String signature) {
        this.signature = signature;
    }
}
