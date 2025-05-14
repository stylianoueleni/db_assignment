-- Query 6: visitor_performances_ratings

-- Parameters: visitor_id=2


    SELECT 
        e.name AS event_name,
        fd.festival_date,
        CASE 
            WHEN p.artist_id IS NOT NULL THEN a.name
            WHEN p.band_id IS NOT NULL THEN b.name
            ELSE 'Unknown'
        END AS performer,
        pt.name AS performance_type,
        AVG(r.overall_rating) AS avg_rating,
        COUNT(r.review_id) AS review_count
    FROM 
        Ticket t
    JOIN 
        Event e ON t.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    JOIN 
        Performance p ON e.event_id = p.event_id
    LEFT JOIN 
        Artist a ON p.artist_id = a.artist_id
    LEFT JOIN 
        Band b ON p.band_id = b.band_id
    JOIN 
        PerformanceType pt ON p.type_id = pt.type_id
    LEFT JOIN 
        Review r ON p.performance_id = r.performance_id AND r.visitor_id = t.visitor_id
    WHERE 
        t.visitor_id = %s
        AND t.is_active = FALSE  -- Only count attended performances
    GROUP BY 
        e.name, fd.festival_date, performer, pt.name
    ORDER BY 
        fd.festival_date DESC;
    