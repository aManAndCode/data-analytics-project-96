WITH paid_sessions AS (
    SELECT
        visitor_id,
        visit_date,
        source AS utm_source,
        medium AS utm_medium,
        campaign AS utm_campaign
    FROM sessions
    WHERE medium IN (
        'cpc',
        'cpm',
        'cpa',
        'youtube',
        'cpp',
        'tg',
        'social'
    )
),

last_click AS (
    SELECT
        visitor_id,
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        ROW_NUMBER() OVER (
            PARTITION BY visitor_id
            ORDER BY visit_date DESC
        ) AS rn
    FROM paid_sessions
)

SELECT
    lc.visitor_id,
    lc.visit_date,
    lc.utm_source,
    lc.utm_medium,
    lc.utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
FROM last_click AS lc
LEFT JOIN leads AS l
    ON
        lc.visitor_id = l.visitor_id
        AND lc.visit_date <= l.created_at
WHERE lc.rn = 1
ORDER BY
    l.amount DESC NULLS LAST,
    lc.visit_date ASC,
    lc.utm_source ASC,
    lc.utm_medium ASC,
    lc.utm_campaign ASC
LIMIT 10;
