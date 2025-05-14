-- Query 8: unscheduled_support_staff

-- Parameters: date=2019-08-11


    SELECT 
        s.staff_id,
        s.name,
        s.age,
        el.name AS experience_level
    FROM 
        Staff s
    JOIN 
        ExperienceLevel el ON s.level_id = el.level_id
    JOIN 
        StaffRole sr ON s.role_id = sr.role_id
    WHERE 
        sr.name = 'Support'
        AND s.staff_id NOT IN (
            SELECT 
                sa.staff_id
            FROM 
                Staff_Assignment sa
            JOIN 
                Event e ON sa.event_id = e.event_id
            JOIN 
                FestivalDay fd ON e.day_id = fd.day_id
            WHERE 
                fd.festival_date = %s
        )
    ORDER BY 
        s.name;
    