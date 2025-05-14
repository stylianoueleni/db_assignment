-- Query 15: top_visitors_ratings_for_artist

-- Parameters: artist_id=28


    SELECT 
        v.visitor_id,
        CONCAT(v.first_name, ' ', v.last_name) AS visitor_name,
        a.name AS artist_name,
        SUM(r.artist_rating + r.sound_rating + r.stage_rating + r.organization_rating + r.overall_rating) AS total_score,
        COUNT(r.review_id) AS review_count,
        AVG(r.overall_rating) AS avg_overall_rating
    FROM 
        Visitor v
    JOIN 
        Review r ON v.visitor_id = r.visitor_id
    JOIN 
        Performance p ON r.performance_id = p.performance_id
    JOIN 
        Artist a ON p.artist_id = a.artist_id
    WHERE 
        a.artist_id = %s
    GROUP BY 
        v.visitor_id, visitor_name, artist_name
    ORDER BY 
        total_score DESC
    LIMIT 5;
    