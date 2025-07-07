package cn.fitsort.entity;

/**
 * 接收人
 *
 * @author: weibang kong
 * @date: 2025-04-24 11:35:34
 */
public class Receiver {
    private String wxuser;
    private String email;
    private String feishuid;
    private String telphone;

    public String getWxuser() {
        return wxuser;
    }

    public void setWxuser(String wxuser) {
        this.wxuser = wxuser;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFeishuid() {
        return feishuid;
    }

    public void setFeishuid(String feishuid) {
        this.feishuid = feishuid;
    }

    public String getTelphone() {
        return telphone;
    }

    public void setTelphone(String telphone) {
        this.telphone = telphone;
    }
}
