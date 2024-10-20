WITH tab AS (
    SELECT
        se.visit_date,
        se.source AS utm_source,
        se.medium AS utm_medium,
        se.campaign AS utm_campaign,
        COUNT(DISTINCT se.visitor_id) AS visitors_count,
        (
            SELECT SUM(inner_ads.daily_spent)
            FROM (
                SELECT
                    ya.utm_source,
                    ya.utm_medium,
                    ya.utm_campaign,
                    ya.utm_content,
                    ya.daily_spent
                FROM ya_ads AS ya
                UNION ALL
                SELECT
                    vk.utm_source,
                    vk.utm_medium,
                    vk.utm_campaign,
                    vk.utm_content,
                    vk.daily_spent
                FROM vk_ads AS vk
            ) AS inner_ads
            WHERE
                inner_ads.utm_source = se.source
                AND inner_ads.utm_medium = se.medium
                AND inner_ads.utm_campaign = se.campaign
        ) AS total_cost,
        COUNT(le.lead_id) AS lead_count,
        COUNT(le.closing_reason) AS purchases_count,
        SUM(le.amount) AS revenue,
        ROW_NUMBER() OVER (
            PARTITION BY se.visitor_id
            ORDER BY se.visit_date DESC
        ) AS rn
    FROM sessions AS se
    LEFT JOIN leads AS le ON se.visitor_id = le.visitor_id
    WHERE le.closing_reason = 'Успешно реализовано' OR le.status_id = 142
    GROUP BY
        se.visitor_id,
        se.visit_date,
        se.source,
        se.medium,
        se.campaign
)
SELECT * FROM tab
WHERE rn = 1
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC
LIMIT 15;
