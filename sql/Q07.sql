-- Query 7: festival_lowest_tech_experience


    SELECT 
        f.festival_id,
        f.name AS festival_name,
        f.year,
        AVG(el.level_id) AS avg_experience_level
    FROM 
        Festival f
    JOIN 
        FestivalDay fd ON f.festival_id = fd.festival_id
    JOIN 
        Event e ON fd.day_id = e.day_id
    JOIN 
        Staff_Assignment sa ON e.event_id = sa.event_id
    JOIN 
        Staff s ON sa.staff_id = s.staff_id
    JOIN 
        ExperienceLevel el ON s.level_id = el.level_id
    JOIN 
        StaffRole sr ON s.role_id = sr.role_id
    WHERE 
        sr.name = 'Technician'
    GROUP BY 
        f.festival_id, f.name, f.year
    ORDER BY 
        avg_experience_level ASC
    LIMIT 1;
    