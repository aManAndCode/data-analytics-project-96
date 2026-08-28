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
        COALESCE(v.visit_date, c.visit_date) AS visit_date,
        COALESCE(v.utm_source, c.utm_source) AS utm_source,
        COALESCE(v.utm_medium, c.utm_medium) AS utm_medium,
        COALESCE(v.utm_campaign, c.utm_campaign) AS utm_campaign,
        COALESCE(v.visitors_count, 0) AS visitors_count,
        COALESCE(v.leads_count, 0) AS leads_count,
        COALESCE(v.purchases_count, 0) AS purchases_count,
        v.revenue,
        c.total_cost
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
    utm_source,
    utm_medium,
    utm_campaign,
    visitors_count,
    leads_count,
    purchases_count,
    revenue,
    total_cost
FROM result
ORDER BY
    visit_date ASC,
    utm_source ASC,
    utm_medium ASC,
    utm_campaign ASC;

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
        utm_source,
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
    GROUP BY utm_source
),

costs_agg AS (
    SELECT
        utm_source,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY utm_source

    UNION ALL

    SELECT
        utm_source,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY utm_source
),

result AS (
    SELECT
        v.utm_source,
        v.visitors_count,
        v.leads_count,
        v.purchases_count,
        v.revenue,
        c.total_cost
    FROM visits_agg AS v
    LEFT JOIN costs_agg AS c
        ON v.utm_source = c.utm_source
)

SELECT
    utm_source,
    visitors_count,
    leads_count,
    purchases_count,
    revenue,
    total_cost,
    ROUND(
        total_cost::numeric / NULLIF(visitors_count, 0), 2
    ) AS cpu,
    ROUND(
        total_cost::numeric / NULLIF(leads_count, 0), 2
    ) AS cpl,
    ROUND(
        total_cost::numeric / NULLIF(purchases_count, 0), 2
    ) AS cppu,
    ROUND(
        (
            (COALESCE(revenue, 0) - total_cost)::numeric
            / NULLIF(total_cost, 0)
        ) * 100, 1
    ) AS roi_percent
FROM result
ORDER BY visitors_count DESC;

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
        utm_source,
        utm_medium,
        utm_campaign
),

costs_agg AS (
    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM vk_ads
    GROUP BY
        utm_source,
        utm_medium,
        utm_campaign

    UNION ALL

    SELECT
        utm_source,
        utm_medium,
        utm_campaign,
        SUM(daily_spent) AS total_cost
    FROM ya_ads
    GROUP BY
        utm_source,
        utm_medium,
        utm_campaign
),

result AS (
    SELECT
        v.utm_source,
        v.utm_medium,
        v.utm_campaign,
        v.visitors_count,
        v.leads_count,
        v.purchases_count,
        v.revenue,
        c.total_cost
    FROM visits_agg AS v
    LEFT JOIN costs_agg AS c
        ON
            v.utm_source = c.utm_source
            AND v.utm_medium = c.utm_medium
            AND v.utm_campaign = c.utm_campaign
)

SELECT
    utm_source,
    utm_medium,
    utm_campaign,
    visitors_count,
    leads_count,
    purchases_count,
    revenue,
    total_cost,
    ROUND(
        total_cost::numeric / NULLIF(visitors_count, 0), 2
    ) AS cpu,
    ROUND(
        total_cost::numeric / NULLIF(leads_count, 0), 2
    ) AS cpl,
    ROUND(
        total_cost::numeric / NULLIF(purchases_count, 0), 2
    ) AS cppu,
    ROUND(
        (
            (COALESCE(revenue, 0) - total_cost)::numeric
            / NULLIF(total_cost, 0)
        ) * 100, 1
    ) AS roi_percent
FROM result
ORDER BY visitors_count DESC NULLS LAST;

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

attributed_leads AS (
    SELECT
        l.lead_id,
        EXTRACT(
            EPOCH FROM (l.created_at - lc.visit_date)
        ) / 86400.0 AS lead_delay_days
    FROM last_click AS lc
    JOIN leads AS l
        ON
            lc.visitor_id = l.visitor_id
            AND lc.visit_date <= l.created_at
    WHERE lc.rn = 1
)

SELECT
    PERCENTILE_CONT(0.9) WITHIN GROUP (
        ORDER BY lead_delay_days
    ) AS lead_delay_p90_days
FROM attributed_leads;

WITH daily_organic AS (
    SELECT
        CAST(visit_date AS date) AS visit_date,
        COUNT(*) AS organic_visitors
    FROM sessions
    WHERE medium = 'organic'
    GROUP BY CAST(visit_date AS date)
),

daily_cost AS (
    SELECT
        CAST(campaign_date AS date) AS visit_date,
        daily_spent
    FROM vk_ads

    UNION ALL

    SELECT
        CAST(campaign_date AS date) AS visit_date,
        daily_spent
    FROM ya_ads
),

daily_cost_agg AS (
    SELECT
        visit_date,
        SUM(daily_spent) AS total_cost
    FROM daily_cost
    GROUP BY visit_date
),

daily AS (
    SELECT
        o.visit_date,
        o.organic_visitors,
        c.total_cost
    FROM daily_organic AS o
    JOIN daily_cost_agg AS c
        ON o.visit_date = c.visit_date
)

SELECT
    CORR(total_cost, organic_visitors) AS spend_organic_correlation
FROM daily;
