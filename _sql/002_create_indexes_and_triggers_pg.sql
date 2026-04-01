BEGIN;

-- ============================================================================
-- Indexes and triggers (production baseline)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 常用查询索引
-- ----------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_mp_user_auth_status_deleted
    ON mp_user_auth (auth_status, is_deleted);

CREATE INDEX IF NOT EXISTS idx_mp_user_auth_last_login_at
    ON mp_user_auth (last_login_at DESC);

CREATE INDEX IF NOT EXISTS idx_mp_user_channel_user_type_enabled
    ON mp_user_channel (user_id, channel_type, is_enabled)
    WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_mp_delivery_user_created
    ON mp_message_delivery_record (user_id, created_at DESC)
    WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_mp_delivery_status_created
    ON mp_message_delivery_record (delivery_status, created_at DESC)
    WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_mp_delivery_channel_status
    ON mp_message_delivery_record (channel_type, delivery_status, created_at DESC)
    WHERE is_deleted = FALSE;

CREATE INDEX IF NOT EXISTS idx_mp_delivery_provider_msg_id
    ON mp_message_delivery_record (provider_message_id);

-- jsonb 索引，适用于扩展检索
CREATE INDEX IF NOT EXISTS idx_mp_user_channel_ext_config_gin
    ON mp_user_channel USING GIN (ext_config);

CREATE INDEX IF NOT EXISTS idx_mp_delivery_ext_metadata_gin
    ON mp_message_delivery_record USING GIN (ext_metadata);

-- ----------------------------------------------------------------------------
-- 统一更新时间触发器
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_updated_at_mp_user_auth ON mp_user_auth;
CREATE TRIGGER trg_set_updated_at_mp_user_auth
BEFORE UPDATE ON mp_user_auth
FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at_mp_user_channel ON mp_user_channel;
CREATE TRIGGER trg_set_updated_at_mp_user_channel
BEFORE UPDATE ON mp_user_channel
FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_set_updated_at_mp_message_delivery_record ON mp_message_delivery_record;
CREATE TRIGGER trg_set_updated_at_mp_message_delivery_record
BEFORE UPDATE ON mp_message_delivery_record
FOR EACH ROW
EXECUTE FUNCTION fn_set_updated_at();

COMMIT;
