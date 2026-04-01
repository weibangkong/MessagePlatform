-- ============================================================================
-- MessagePlatform - PostgreSQL Query Templates
-- 用途：运维排障、重试作业、统计看板的常用 SQL 模板
-- 注意：请按你的业务参数替换 :placeholder
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) 拉取待重试任务（失败且未超过最大重试次数）
-- ----------------------------------------------------------------------------
SELECT
    id,
    msg_id,
    request_id,
    user_id,
    channel_type,
    receiver_account,
    retry_count,
    max_retry,
    error_code,
    error_message,
    created_at,
    updated_at
FROM mp_message_delivery_record
WHERE is_deleted = FALSE
  AND delivery_status = 3
  AND retry_count < max_retry
ORDER BY updated_at ASC
LIMIT 500;

-- ----------------------------------------------------------------------------
-- 2) 重试任务状态推进（示例：挑选一批后置为 sending）
-- ----------------------------------------------------------------------------
-- 建议在应用层配合 FOR UPDATE SKIP LOCKED 做并发安全拉取
UPDATE mp_message_delivery_record
SET
    delivery_status = 1,
    updated_by = 'retry-worker'
WHERE id = ANY(:id_array);

-- ----------------------------------------------------------------------------
-- 3) 单请求链路追踪（按 request_id）
-- ----------------------------------------------------------------------------
SELECT
    id,
    request_id,
    msg_id,
    biz_id,
    channel_type,
    delivery_status,
    retry_count,
    provider_code,
    provider_message_id,
    error_code,
    error_message,
    sent_at,
    delivered_at,
    created_at,
    updated_at
FROM mp_message_delivery_record
WHERE request_id = :request_id
ORDER BY id ASC;

-- ----------------------------------------------------------------------------
-- 4) 最近 24 小时各渠道投递成功率
-- ----------------------------------------------------------------------------
SELECT
    channel_type,
    COUNT(*) AS total_cnt,
    SUM(CASE WHEN delivery_status = 2 THEN 1 ELSE 0 END) AS success_cnt,
    ROUND(
        100.0 * SUM(CASE WHEN delivery_status = 2 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0),
        2
    ) AS success_rate_pct
FROM mp_message_delivery_record
WHERE is_deleted = FALSE
  AND created_at >= NOW() - INTERVAL '24 hours'
GROUP BY channel_type
ORDER BY total_cnt DESC;

-- ----------------------------------------------------------------------------
-- 5) 最近 24 小时失败 Top N（按错误码）
-- ----------------------------------------------------------------------------
SELECT
    channel_type,
    COALESCE(error_code, 'UNKNOWN') AS error_code,
    COUNT(*) AS fail_cnt
FROM mp_message_delivery_record
WHERE is_deleted = FALSE
  AND created_at >= NOW() - INTERVAL '24 hours'
  AND delivery_status = 3
GROUP BY channel_type, COALESCE(error_code, 'UNKNOWN')
ORDER BY fail_cnt DESC
LIMIT 20;

-- ----------------------------------------------------------------------------
-- 6) 用户维度发送统计（时间窗）
-- ----------------------------------------------------------------------------
SELECT
    user_id,
    COUNT(*) AS total_cnt,
    SUM(CASE WHEN delivery_status = 2 THEN 1 ELSE 0 END) AS success_cnt,
    SUM(CASE WHEN delivery_status = 3 THEN 1 ELSE 0 END) AS fail_cnt
FROM mp_message_delivery_record
WHERE is_deleted = FALSE
  AND created_at >= :start_time
  AND created_at < :end_time
GROUP BY user_id
ORDER BY total_cnt DESC
LIMIT 100;

-- ----------------------------------------------------------------------------
-- 7) 渠道可用配置巡检（启用但未验证）
-- ----------------------------------------------------------------------------
SELECT
    id,
    user_id,
    channel_type,
    channel_account,
    provider_code,
    verify_status,
    is_enabled,
    updated_at
FROM mp_user_channel
WHERE is_deleted = FALSE
  AND is_enabled = TRUE
  AND verify_status = 0
ORDER BY updated_at DESC
LIMIT 500;

-- ----------------------------------------------------------------------------
-- 8) 近 7 天日消息量趋势
-- ----------------------------------------------------------------------------
SELECT
    DATE_TRUNC('day', created_at) AS day_bucket,
    channel_type,
    COUNT(*) AS total_cnt,
    SUM(CASE WHEN delivery_status = 2 THEN 1 ELSE 0 END) AS success_cnt,
    SUM(CASE WHEN delivery_status = 3 THEN 1 ELSE 0 END) AS fail_cnt
FROM mp_message_delivery_record
WHERE is_deleted = FALSE
  AND created_at >= NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('day', created_at), channel_type
ORDER BY day_bucket ASC, channel_type ASC;
