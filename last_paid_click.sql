WITH tab AS (
    SELECT
        se.visitor_id,
        se.visit_date,
        se.source AS utm_source,
        se.medium AS utm_medium,
        se.campaign AS utm_campaign,
        le.lead_id,
        le.created_at,
        le.amount,
        le.closing_reason,
        le.status_id,
        ROW_NUMBER() OVER (
            PARTITION BY se.visitor_id ORDER BY se.visit_date DESC
        ) AS rn
    FROM sessions AS se
    LEFT JOIN leads AS le ON se.visitor_id = le.visitor_id
    WHERE se.medium != 'organic' AND le.created_at >= se.visit_date
)

SELECT
    t.visitor_id,
    t.lead_id,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    t.visit_date,
    t.created_at,
    t.amount,
    t.closing_reason,
    t.status_id
FROM tab AS t
WHERE t.rn = 1
ORDER BY
    t.amount DESC NULLS LAST,
    t.visit_date ASC,
    t.utm_source ASC,
    t.utm_medium ASC,
    t.utm_campaign ASC
LIMIT 10;
