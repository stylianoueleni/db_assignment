-- Query 5: young_artists_participation


    SELECT 
        a.artist_id,
        a.name,
        TIMESTAMPDIFF(YEAR, a.birthdate, CURDATE()) AS age,
        COUNT(DISTINCT f.festival_id) AS festival_count
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
    WHERE 
        TIMESTAMPDIFF(YEAR, a.birthdate, CURDATE()) < 30
    GROUP BY 
        a.artist_id, a.name, a.birthdate
    ORDER BY 
        festival_count DESC, age ASC;
    