BEGIN;

-- ============================================================================
-- Baseline seed DML
-- 注意：生产环境请替换默认密码哈希、联系方式等示例值
-- ============================================================================

-- 默认系统账号（幂等插入）
INSERT INTO mp_user_auth (
    user_id,
    username,
    email,
    mobile,
    password_hash,
    password_algo,
    auth_status,
    created_by,
    updated_by
)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'system_admin',
    'admin@message.local',
    '13800000000',
    '$2a$12$replace_with_real_bcrypt_hash',
    'bcrypt',
    1,
    'seed',
    'seed'
)
ON CONFLICT (username) DO NOTHING;

-- 默认渠道配置（幂等）
INSERT INTO mp_user_channel (
    user_id,
    channel_type,
    channel_account,
    provider_code,
    priority,
    is_enabled,
    verify_status,
    verified_at,
    ext_config,
    created_by,
    updated_by
)
VALUES
(
    '00000000-0000-0000-0000-000000000001',
    'SMS',
    '13800000000',
    'aliyun_sms',
    10,
    TRUE,
    1,
    NOW(),
    '{"signName":"MessagePlatform","templateCode":"SMS_0000001"}'::jsonb,
    'seed',
    'seed'
),
(
    '00000000-0000-0000-0000-000000000001',
    'EMAIL',
    'admin@message.local',
    'smtp_default',
    20,
    TRUE,
    1,
    NOW(),
    '{"from":"noreply@message.local"}'::jsonb,
    'seed',
    'seed'
)
ON CONFLICT (user_id, channel_type, channel_account) DO NOTHING;

COMMIT;
