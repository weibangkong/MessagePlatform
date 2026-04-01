BEGIN;

-- ============================================================================
-- MessagePlatform PostgreSQL schema (production baseline)
-- ============================================================================

-- Optional extension for UUID generation
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- 1) 用户认证信息表
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mp_user_auth (
    id                      BIGSERIAL PRIMARY KEY,
    user_id                 UUID NOT NULL DEFAULT gen_random_uuid(),
    username                VARCHAR(64) NOT NULL,
    email                   VARCHAR(128),
    mobile                  VARCHAR(32),
    password_hash           VARCHAR(255) NOT NULL,
    password_algo           VARCHAR(32) NOT NULL DEFAULT 'bcrypt',
    password_salt           VARCHAR(128),
    mfa_enabled             BOOLEAN NOT NULL DEFAULT FALSE,
    mfa_secret_encrypted    TEXT,
    auth_status             SMALLINT NOT NULL DEFAULT 1, -- 1 active, 0 disabled, 2 locked
    failed_login_count      INTEGER NOT NULL DEFAULT 0,
    locked_until            TIMESTAMPTZ,
    last_login_at           TIMESTAMPTZ,
    password_changed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    remark                  VARCHAR(500),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by              VARCHAR(64) NOT NULL DEFAULT 'system',
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by              VARCHAR(64) NOT NULL DEFAULT 'system',
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              TIMESTAMPTZ,
    version                 INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT uk_mp_user_auth_user_id UNIQUE (user_id),
    CONSTRAINT uk_mp_user_auth_username UNIQUE (username),
    CONSTRAINT uk_mp_user_auth_email UNIQUE (email),
    CONSTRAINT uk_mp_user_auth_mobile UNIQUE (mobile),
    CONSTRAINT ck_mp_user_auth_status CHECK (auth_status IN (0, 1, 2)),
    CONSTRAINT ck_mp_user_auth_failed_cnt CHECK (failed_login_count >= 0)
);

COMMENT ON TABLE mp_user_auth IS '用户认证信息表';
COMMENT ON COLUMN mp_user_auth.password_hash IS '密码哈希值，禁止存储明文';
COMMENT ON COLUMN mp_user_auth.mfa_secret_encrypted IS 'MFA密钥密文';

-- ----------------------------------------------------------------------------
-- 2) 用户渠道表（每个用户可配置多个渠道）
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mp_user_channel (
    id                      BIGSERIAL PRIMARY KEY,
    user_id                 UUID NOT NULL,
    channel_type            VARCHAR(32) NOT NULL, -- SMS/EMAIL/WX/FEISHU/WEB
    channel_account         VARCHAR(256) NOT NULL, -- 手机号/邮箱/open_id...
    provider_code           VARCHAR(64),           -- 渠道服务商标识
    priority                SMALLINT NOT NULL DEFAULT 100,
    is_enabled              BOOLEAN NOT NULL DEFAULT TRUE,
    verify_status           SMALLINT NOT NULL DEFAULT 0, -- 0 unverified, 1 verified
    verified_at             TIMESTAMPTZ,
    ext_config              JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by              VARCHAR(64) NOT NULL DEFAULT 'system',
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by              VARCHAR(64) NOT NULL DEFAULT 'system',
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              TIMESTAMPTZ,
    version                 INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT fk_mp_user_channel_user_id FOREIGN KEY (user_id)
        REFERENCES mp_user_auth (user_id),
    CONSTRAINT uk_mp_user_channel_unique_account UNIQUE (user_id, channel_type, channel_account),
    CONSTRAINT ck_mp_user_channel_type CHECK (channel_type IN ('SMS', 'EMAIL', 'WX', 'FEISHU', 'WEB')),
    CONSTRAINT ck_mp_user_channel_priority CHECK (priority BETWEEN 1 AND 9999),
    CONSTRAINT ck_mp_user_channel_verify_status CHECK (verify_status IN (0, 1))
);

COMMENT ON TABLE mp_user_channel IS '用户渠道配置表';
COMMENT ON COLUMN mp_user_channel.ext_config IS '渠道扩展配置，JSON结构';

-- ----------------------------------------------------------------------------
-- 3) 消息投递记录表（核心事实表）
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mp_message_delivery_record (
    id                      BIGSERIAL PRIMARY KEY,
    msg_id                  UUID NOT NULL DEFAULT gen_random_uuid(),
    request_id              VARCHAR(64) NOT NULL,  -- 幂等/链路追踪请求ID
    biz_id                  VARCHAR(128),          -- 业务单据ID
    user_id                 UUID NOT NULL,
    channel_type            VARCHAR(32) NOT NULL,
    sender_account          VARCHAR(256),
    receiver_account        VARCHAR(256) NOT NULL,
    message_title           VARCHAR(255),
    message_content         TEXT NOT NULL,
    content_hash            VARCHAR(128),          -- 内容哈希，用于审计/去重
    delivery_status         SMALLINT NOT NULL DEFAULT 0, -- 0 queued,1 sending,2 success,3 failed,4 canceled
    error_code              VARCHAR(64),
    error_message           VARCHAR(1000),
    retry_count             INTEGER NOT NULL DEFAULT 0,
    max_retry               INTEGER NOT NULL DEFAULT 3,
    provider_code           VARCHAR(64),
    provider_message_id     VARCHAR(128),
    callback_payload        JSONB,
    ext_metadata            JSONB NOT NULL DEFAULT '{}'::jsonb,
    sent_at                 TIMESTAMPTZ,
    delivered_at            TIMESTAMPTZ,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by              VARCHAR(64) NOT NULL DEFAULT 'system',
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by              VARCHAR(64) NOT NULL DEFAULT 'system',
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at              TIMESTAMPTZ,
    version                 INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT fk_mp_delivery_user_id FOREIGN KEY (user_id)
        REFERENCES mp_user_auth (user_id),
    CONSTRAINT uk_mp_delivery_request_channel UNIQUE (request_id, channel_type),
    CONSTRAINT uk_mp_delivery_msg_id UNIQUE (msg_id),
    CONSTRAINT ck_mp_delivery_channel_type CHECK (channel_type IN ('SMS', 'EMAIL', 'WX', 'FEISHU', 'WEB')),
    CONSTRAINT ck_mp_delivery_status CHECK (delivery_status IN (0, 1, 2, 3, 4)),
    CONSTRAINT ck_mp_delivery_retry_count CHECK (retry_count >= 0),
    CONSTRAINT ck_mp_delivery_max_retry CHECK (max_retry >= 0)
);

COMMENT ON TABLE mp_message_delivery_record IS '消息投递记录表';
COMMENT ON COLUMN mp_message_delivery_record.request_id IS '请求幂等键/链路追踪键';
COMMENT ON COLUMN mp_message_delivery_record.ext_metadata IS '扩展元数据';

COMMIT;
