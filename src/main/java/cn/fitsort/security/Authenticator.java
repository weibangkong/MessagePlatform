package cn.fitsort.security;

public interface Authenticator {
    void authenticate(AuthContext context);
}
