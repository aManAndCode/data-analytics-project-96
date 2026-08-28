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
),

attributed AS (
    SELECT
        CAST(lc.visit_date AS date) AS visit_date,
        lc.utm_source,
        lc.utm_medium,
        lc.utm_campaign,
        l.lead_id,
        l.amount,
        l.closing_reason,
        l.status_id
    FROM last_click AS lc
    LEFT JOIN leads AS l
        ON
            lc.visitor_id = l.visitor_id
            AND lc.visit_date <= l.created_at
    WHERE lc.rn = 1
),

visits_agg AS (
    SELECT
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        COUNT(*) AS visitors_count,
        COUNT(lead_id) AS leads_count,
        COUNT(*) FILTER (
            WHERE
            closing_reason = 'Успешная продажа'
            OR status_id = 142
        ) AS purchases_count,
        SUM(amount) FILTER (
            WHERE
            closing_reason = 'Успешная продажа'
            OR status_id = 142
        ) AS revenue
    FROM attributed
    GROUP BY
        visit_date,
        utm_source,
        utm_medium,
        utm_campaign
),

costs_agg AS (
    SELECT
        CAST(campaign_date AS date) AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign

    UNION ALL

    SELECT
        CAST(campaign_date AS date) AS visit_date,
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY
        campaign_date,
        utm_source,
        utm_medium,
        utm_campaign
),

result AS (
    SELECT
        c.total_cost,
        v.revenue,
        COALESCE(v.visit_date, c.visit_date) AS visit_date,
        COALESCE(v.visitors_count, 0) AS visitors_count,
        COALESCE(v.utm_source, c.utm_source) AS utm_source,
        COALESCE(v.utm_medium, c.utm_medium) AS utm_medium,
        COALESCE(v.utm_campaign, c.utm_campaign) AS utm_campaign,
        COALESCE(v.leads_count, 0) AS leads_count,
        COALESCE(v.purchases_count, 0) AS purchases_count
    FROM visits_agg AS v
    FULL JOIN costs_agg AS c
        ON
            v.visit_date = c.visit_date
            AND v.utm_source = c.utm_source
            AND v.utm_medium = c.utm_medium
            AND v.utm_campaign = c.utm_campaign
)

SELECT
    visit_date,
    visitors_count,
    utm_source,
    utm_medium,
    utm_campaign,
    total_cost,
    leads_count,
    purchases_count,
    revenue
FROM result
ORDER BY
    revenue DESC NULLS LAST,
    visit_date ASC,
    visitors_count DESC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC
LIMIT 15;
