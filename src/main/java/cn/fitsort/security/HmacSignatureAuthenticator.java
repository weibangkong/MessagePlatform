package cn.fitsort.security;

import cn.fitsort.entity.Sender;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;

/**
 * 基于 HMAC-SHA256 的签名鉴权。
 */
public class HmacSignatureAuthenticator implements Authenticator {
    private static final String HMAC_ALGO = "HmacSHA256";
    private final String secret;
    private final long maxSkewSeconds;

    public HmacSignatureAuthenticator(String secret, long maxSkewSeconds) {
        this.secret = secret;
        this.maxSkewSeconds = maxSkewSeconds;
    }

    @Override
    public void authenticate(AuthContext context) {
        Sender sender = (Sender) context.getMessage().getSender();
        if (sender == null) {
            throw new AuthenticationException("鉴权失败: sender 不能为空");
        }
        if (isBlank(sender.getAppId()) || isBlank(sender.getTitle())) {
            throw new AuthenticationException("鉴权失败: appId/title 不能为空");
        }
        if (sender.getTimestamp() == null || isBlank(sender.getNonce()) || isBlank(sender.getSignature())) {
            throw new AuthenticationException("鉴权失败: timestamp/nonce/signature 缺失");
        }

        long now = context.getRequestTimeSeconds();
        long requestTs = sender.getTimestamp();
        if (Math.abs(now - requestTs) > maxSkewSeconds) {
            throw new AuthenticationException("鉴权失败: 请求已过期");
        }

        String plain = buildPlainText(sender);
        String expected = hmacHex(plain, secret);
        if (!expected.equalsIgnoreCase(sender.getSignature())) {
            throw new AuthenticationException("鉴权失败: signature 非法");
        }
    }

    private static String buildPlainText(Sender sender) {
        return sender.getAppId() + "|" + sender.getTitle() + "|" + sender.getTimestamp() + "|" + sender.getNonce();
    }

    private static String hmacHex(String text, String secret) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGO);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), HMAC_ALGO));
            byte[] bytes = mac.doFinal(text.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(bytes);
        } catch (Exception e) {
            throw new AuthenticationException("鉴权失败: 签名计算异常");
        }
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
