WITH tab AS (
    SELECT
        se.visit_date,
        se.source AS utm_source,
        se.medium AS utm_medium,
        se.campaign AS utm_campaign,
        COUNT(DISTINCT se.visitor_id) AS visitors_count,
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
),

ya_vk_spent AS (
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
),

ads_costs AS (
    SELECT
        ya_vk_spent.utm_source,
        ya_vk_spent.utm_medium,
        ya_vk_spent.utm_campaign,
        SUM(ya_vk_spent.daily_spent) AS total_cost
    FROM ya_vk_spent
    GROUP BY
        ya_vk_spent.utm_source,
        ya_vk_spent.utm_medium,
        ya_vk_spent.utm_campaign
)

SELECT
    tab.visit_date,
    tab.utm_source,
    tab.utm_medium,
    tab.utm_campaign,
    tab.visitors_count,
    ac.total_cost,
    tab.lead_count,
    tab.purchases_count,
    tab.revenue
FROM ads_costs AS ac
LEFT JOIN tab
    ON ac.utm_source = tab.utm_source
    AND ac.utm_medium = tab.utm_medium
    AND ac.utm_campaign = tab.utm_campaign
WHERE tab.rn = 1
ORDER BY
    tab.revenue DESC NULLS LAST,
    ac.total_cost DESC NULLS LAST,
    tab.visit_date ASC,
    tab.visitors_count DESC,
    tab.utm_source ASC,
    tab.utm_medium ASC,
    tab.utm_campaign ASC
LIMIT 15;