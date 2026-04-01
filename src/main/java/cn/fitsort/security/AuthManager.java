package cn.fitsort.security;

/**
 * 鉴权管理器。
 *
 * 通过 JVM 参数控制:
 * -Dmessage.auth.mode=NONE|HMAC_SHA256
 * -Dmessage.auth.secret=your_secret
 * -Dmessage.auth.maxSkewSeconds=300
 */
public class AuthManager {
    private static final String MODE_KEY = "message.auth.mode";
    private static final String SECRET_KEY = "message.auth.secret";
    private static final String MAX_SKEW_KEY = "message.auth.maxSkewSeconds";

    private static final Authenticator AUTHENTICATOR = buildAuthenticator();

    private AuthManager() {
    }

    public static Authenticator getAuthenticator() {
        return AUTHENTICATOR;
    }

    private static Authenticator buildAuthenticator() {
        String mode = System.getProperty(MODE_KEY, "NONE").trim().toUpperCase();
        if ("HMAC_SHA256".equals(mode)) {
            String secret = System.getProperty(SECRET_KEY, "");
            if (secret.isBlank()) {
                throw new IllegalStateException("启用 HMAC_SHA256 鉴权时必须配置 -D" + SECRET_KEY);
            }
            long maxSkew = Long.parseLong(System.getProperty(MAX_SKEW_KEY, "300"));
            return new HmacSignatureAuthenticator(secret, maxSkew);
        }
        return new NoopAuthenticator();
    }
}
