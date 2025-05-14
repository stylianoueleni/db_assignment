-- Query 4: artist_average_ratings

-- Parameters: artist_id=28


    SELECT 
        a.artist_id,
        a.name,
        AVG(r.artist_rating) AS avg_artist_rating,
        AVG(r.overall_rating) AS avg_overall_rating,
        COUNT(r.review_id) AS total_reviews
    FROM 
        Artist a
    JOIN 
        Performance p ON a.artist_id = p.artist_id
    JOIN 
        Review r ON p.performance_id = r.performance_id
    WHERE 
        a.artist_id = %s
    GROUP BY 
        a.artist_id, a.name;
    