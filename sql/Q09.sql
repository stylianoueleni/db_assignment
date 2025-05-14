-- Query 9: visitors_same_attendance_count


    SELECT 
    v.visitor_id,
    CONCAT(v.first_name, ' ', v.last_name) AS visitor_name,
    attendance.year,
    attendance.attendance_count,
    GROUP_CONCAT(DISTINCT f.name) AS festivals_attended
    FROM 
      Visitor v
    JOIN (
    -- Get attendance counts by visitor and year
    SELECT 
        visitor_id,
        YEAR(fd.festival_date) AS year,
        COUNT(DISTINCT t.ticket_id) AS attendance_count
    FROM 
        Ticket t
    JOIN 
        Event e ON t.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    WHERE 
        t.is_active = FALSE
    GROUP BY 
        visitor_id, year
    HAVING 
        attendance_count > 3
    ) AS attendance ON v.visitor_id = attendance.visitor_id
    JOIN (
    -- Find shared attendance counts
    SELECT 
        year,
        attendance_count
    FROM (
        SELECT 
            YEAR(fd.festival_date) AS year,
            t.visitor_id,
            COUNT(DISTINCT t.ticket_id) AS attendance_count
        FROM 
            Ticket t
        JOIN 
            Event e ON t.event_id = e.event_id
        JOIN 
            FestivalDay fd ON e.day_id = fd.day_id
        WHERE 
            t.is_active = FALSE
        GROUP BY 
            year, t.visitor_id
        HAVING 
            attendance_count > 3
    ) AS visitor_counts
    GROUP BY 
        year, attendance_count
    HAVING 
        COUNT(*) > 1
    ) AS shared_counts 
        ON attendance.year = shared_counts.year 
        AND attendance.attendance_count = shared_counts.attendance_count
    -- Get festival information
    JOIN 
        Ticket t ON v.visitor_id = t.visitor_id
    JOIN 
        Event e ON t.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    JOIN 
        Festival f ON fd.festival_id = f.festival_id
    WHERE 
        t.is_active = FALSE
        AND YEAR(fd.festival_date) = attendance.year
    GROUP BY 
        v.visitor_id, visitor_name, attendance.year, attendance.attendance_count
    ORDER BY 
        attendance.year DESC, attendance.attendance_count DESC;
    