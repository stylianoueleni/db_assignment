-- Query 14: genres_consistent_performances


    WITH GenreYearCounts AS (
        SELECT 
            a.genre,
            f.year,
            COUNT(DISTINCT p.performance_id) AS performance_count
        FROM 
            Artist a
        JOIN 
            Performance p ON a.artist_id = p.artist_id
        JOIN 
            Event e ON p.event_id = e.event_id
        JOIN 
            FestivalDay fd ON e.day_id = fd.day_id
        JOIN 
            Festival f ON fd.festival_id = f.festival_id
        GROUP BY 
            a.genre, f.year
        HAVING 
            COUNT(DISTINCT p.performance_id) >= 3
    )
    SELECT 
        g1.genre,
        g1.year AS year1,
        g2.year AS year2,
        g1.performance_count
    FROM 
        GenreYearCounts g1
    JOIN 
        GenreYearCounts g2 ON g1.genre = g2.genre 
                           AND g1.performance_count = g2.performance_count 
                           AND g2.year = g1.year + 1
    ORDER BY 
        g1.performance_count DESC, g1.genre;
    