-- Query 2: artists_by_genre_participation

-- Parameters: year=2025, genre=pop


    SELECT 
        a.artist_id,
        a.name, 
        a.pseudonym,
        a.genre,
        a.subgenre,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM Performance p
                JOIN Event e ON p.event_id = e.event_id
                JOIN FestivalDay fd ON e.day_id = fd.day_id
                JOIN Festival f ON fd.festival_id = f.festival_id
                WHERE p.artist_id = a.artist_id AND f.year = %s
            ) THEN 'Yes' 
            ELSE 'No' 
        END AS participated
    FROM 
        Artist a
    WHERE 
        a.genre = %s
    ORDER BY 
        a.name;
    