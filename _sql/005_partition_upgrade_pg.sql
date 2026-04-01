BEGIN;

-- ============================================================================
-- MessagePlatform - mp_message_delivery_record 月分区升级脚本（PostgreSQL）
-- 目标：将投递记录从单表升级为按 created_at 的 RANGE 月分区
--
-- 执行建议：
-- 1) 在业务低峰执行，并先做全量备份
-- 2) 先在预发验证迁移耗时与锁影响
-- 3) 大表迁移建议分批 INSERT ... SELECT
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0) 保护性检查（可选）：确认原表存在
-- ----------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'mp_message_delivery_record'
    ) THEN
        RAISE EXCEPTION 'table mp_message_delivery_record does not exist';
    END IF;
END
$$;

-- ----------------------------------------------------------------------------
-- 1) 重命名旧表
-- ----------------------------------------------------------------------------
ALTER TABLE mp_message_delivery_record RENAME TO mp_message_delivery_record_old;

-- ----------------------------------------------------------------------------
-- 2) 新建分区父表
--    注意：分区表上的唯一约束必须包含分区键 created_at
-- ----------------------------------------------------------------------------
CREATE TABLE mp_message_delivery_record (
    id                      BIGINT NOT NULL DEFAULT nextval('mp_message_delivery_record_id_seq'),
    msg_id                  UUID NOT NULL,
    request_id              VARCHAR(64) NOT NULL,
    biz_id                  VARCHAR(128),
    user_id                 UUID NOT NULL,
    channel_type            VARCHAR(32) NOT NULL,
    sender_account          VARCHAR(256),
    receiver_account        VARCHAR(256) NOT NULL,
    message_title           VARCHAR(255),
    message_content         TEXT NOT NULL,
    content_hash            VARCHAR(128),
    delivery_status         SMALLINT NOT NULL DEFAULT 0,
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
    CONSTRAINT pk_mp_delivery_partitioned PRIMARY KEY (id, created_at),
    CONSTRAINT fk_mp_delivery_user_id FOREIGN KEY (user_id)
        REFERENCES mp_user_auth (user_id),
    CONSTRAINT ck_mp_delivery_channel_type CHECK (channel_type IN ('SMS', 'EMAIL', 'WX', 'FEISHU', 'WEB')),
    CONSTRAINT ck_mp_delivery_status CHECK (delivery_status IN (0, 1, 2, 3, 4)),
    CONSTRAINT ck_mp_delivery_retry_count CHECK (retry_count >= 0),
    CONSTRAINT ck_mp_delivery_max_retry CHECK (max_retry >= 0)
) PARTITION BY RANGE (created_at);

COMMENT ON TABLE mp_message_delivery_record IS '消息投递记录表（月分区）';

-- ----------------------------------------------------------------------------
-- 3) 创建默认分区，避免未建月分区时写入失败
-- ----------------------------------------------------------------------------
CREATE TABLE mp_message_delivery_record_default
    PARTITION OF mp_message_delivery_record DEFAULT;

-- ----------------------------------------------------------------------------
-- 4) 创建示例月分区（请按实际月份扩展）
-- ----------------------------------------------------------------------------
CREATE TABLE mp_message_delivery_record_2026_01
    PARTITION OF mp_message_delivery_record
    FOR VALUES FROM ('2026-01-01 00:00:00+00') TO ('2026-02-01 00:00:00+00');

CREATE TABLE mp_message_delivery_record_2026_02
    PARTITION OF mp_message_delivery_record
    FOR VALUES FROM ('2026-02-01 00:00:00+00') TO ('2026-03-01 00:00:00+00');

CREATE TABLE mp_message_delivery_record_2026_03
    PARTITION OF mp_message_delivery_record
    FOR VALUES FROM ('2026-03-01 00:00:00+00') TO ('2026-04-01 00:00:00+00');

-- ----------------------------------------------------------------------------
-- 5) 在父表创建分区索引模板（会自动作用于分区）
-- ----------------------------------------------------------------------------
CREATE INDEX idx_mp_delivery_part_user_created
    ON mp_message_delivery_record (user_id, created_at DESC);

CREATE INDEX idx_mp_delivery_part_status_created
    ON mp_message_delivery_record (delivery_status, created_at DESC);

CREATE INDEX idx_mp_delivery_part_channel_status
    ON mp_message_delivery_record (channel_type, delivery_status, created_at DESC);

CREATE INDEX idx_mp_delivery_part_provider_msg_id
    ON mp_message_delivery_record (provider_message_id);

CREATE INDEX idx_mp_delivery_part_ext_metadata_gin
    ON mp_message_delivery_record USING GIN (ext_metadata);

-- ----------------------------------------------------------------------------
-- 6) 分区表下的唯一性策略
--    由于分区限制，唯一键必须包含 created_at
-- ----------------------------------------------------------------------------
ALTER TABLE mp_message_delivery_record
    ADD CONSTRAINT uk_mp_delivery_msg_id_created UNIQUE (msg_id, created_at);

ALTER TABLE mp_message_delivery_record
    ADD CONSTRAINT uk_mp_delivery_req_channel_created UNIQUE (request_id, channel_type, created_at);

-- ----------------------------------------------------------------------------
-- 7) 迁移历史数据
-- ----------------------------------------------------------------------------
INSERT INTO mp_message_delivery_record (
    id, msg_id, request_id, biz_id, user_id, channel_type, sender_account, receiver_account,
    message_title, message_content, content_hash, delivery_status, error_code, error_message,
    retry_count, max_retry, provider_code, provider_message_id, callback_payload, ext_metadata,
    sent_at, delivered_at, created_at, created_by, updated_at, updated_by, is_deleted, deleted_at, version
)
SELECT
    id, msg_id, request_id, biz_id, user_id, channel_type, sender_account, receiver_account,
    message_title, message_content, content_hash, delivery_status, error_code, error_message,
    retry_count, max_retry, provider_code, provider_message_id, callback_payload, ext_metadata,
    sent_at, delivered_at, created_at, created_by, updated_at, updated_by, is_deleted, deleted_at, version
FROM mp_message_delivery_record_old;

-- ----------------------------------------------------------------------------
-- 8) 序列对齐（若 id 使用 old 序列）
-- ----------------------------------------------------------------------------
SELECT setval(
    'mp_message_delivery_record_id_seq',
    GREATEST((SELECT COALESCE(MAX(id), 1) FROM mp_message_delivery_record), 1),
    TRUE
);

-- ----------------------------------------------------------------------------
-- 9) 兼容触发器（updated_at 自动更新时间）
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_updated_at_mp_message_delivery_record ON mp_message_delivery_record;
CREATE TRIGGER trg_set_updated_at_mp_message_delivery_record
BEFORE UPDATE ON mp_message_delivery_record
FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();

COMMIT;

-- ============================================================================
-- 可选收尾步骤（确认无误后人工执行）
-- DROP TABLE mp_message_delivery_record_old;
-- ============================================================================
