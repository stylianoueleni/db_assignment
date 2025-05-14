-- Query 13: artists_multiple_continents


    SELECT 
        a.artist_id,
        a.name,
        COUNT(DISTINCT l.continent) AS continent_count,
        GROUP_CONCAT(DISTINCT l.continent) AS continents
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
    JOIN 
        Location l ON f.location_id = l.location_id
    GROUP BY 
        a.artist_id, a.name
    HAVING 
        COUNT(DISTINCT l.continent) >= 3
    ORDER BY 
        continent_count DESC, a.name;
    