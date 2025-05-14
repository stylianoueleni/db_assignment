-- Query 3: frequent_warmup_artists


    SELECT 
        a.artist_id,
        a.name, 
        f.name AS festival_name,
        f.year,
        COUNT(*) AS warmup_count
    FROM 
        Performance p
    JOIN 
        Artist a ON p.artist_id = a.artist_id
    JOIN 
        Event e ON p.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    JOIN 
        Festival f ON fd.festival_id = f.festival_id
    JOIN 
        PerformanceType pt ON p.type_id = pt.type_id
    WHERE 
        pt.name = 'Warm Up'
    GROUP BY 
        a.artist_id, f.festival_id
    HAVING 
        COUNT(*) > 2
    ORDER BY 
        warmup_count DESC, f.year DESC;
    