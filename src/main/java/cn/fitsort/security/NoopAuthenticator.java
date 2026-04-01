package cn.fitsort.security;

/**
 * 默认鉴权实现：不启用鉴权。
 */
public class NoopAuthenticator implements Authenticator {
    @Override
    public void authenticate(AuthContext context) {
        // default no-op
    }
}
