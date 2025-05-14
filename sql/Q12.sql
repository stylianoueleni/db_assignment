-- Query 12: festival_staff_by_category


    SELECT 
        fd.festival_date,
        f.name AS festival_name,
        sr.name AS staff_role,
        COUNT(DISTINCT sa.staff_id) AS assigned_staff,
        COUNT(DISTINCT t.ticket_id) AS tickets_sold,
        -- Maximum staff needed at any single venue
        MAX(CASE 
            WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
            WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
            ELSE 1
        END) AS max_staff_per_venue,
        -- Average staff needed per venue
        ROUND(AVG(CASE 
            WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
            WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
            ELSE 1
        END)) AS avg_staff_per_venue,
        -- Total venues operating that day
        COUNT(DISTINCT s.stage_id) AS operating_venues,
        -- Total concurrent staff if all venues operated at once (renamed from theoretical)
        SUM(CASE 
            WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
            WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
            ELSE 1
        END) AS total_concurrent_staff,
        -- Calculate staffing ratio (percentage of required staff that has been assigned)
        CASE 
            WHEN MAX(CASE 
                WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
                WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
                ELSE 1
            END) = 0 THEN 0
            ELSE ROUND(COUNT(DISTINCT sa.staff_id) / MAX(CASE 
                WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
                WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
                ELSE 1
            END) * 100)
        END AS staffing_ratio
    FROM 
        Festival f
    JOIN 
        FestivalDay fd ON f.festival_id = fd.festival_id
    JOIN 
        Event e ON fd.day_id = e.day_id
    JOIN 
        Stage s ON e.stage_id = s.stage_id
    LEFT JOIN 
        Staff_Assignment sa ON e.event_id = sa.event_id
    LEFT JOIN 
        StaffRole sr ON sa.role_id = sr.role_id
    LEFT JOIN 
        Ticket t ON e.event_id = t.event_id
    WHERE
        sr.name IS NOT NULL
    GROUP BY 
        fd.festival_date, f.name, sr.name
    ORDER BY 
        fd.festival_date DESC, sr.name;
    