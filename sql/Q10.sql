-- Query 10: top_genre_pairs


    WITH SplitGenres AS (
        SELECT 
            p.performance_id,
            a.artist_id,
            a.name AS artist_name,
            CASE 
                WHEN a.genre LIKE '%/%' THEN SUBSTRING_INDEX(a.genre, '/', 1)
                ELSE a.genre
            END AS genre1,
            CASE 
                WHEN a.genre LIKE '%/%' THEN SUBSTRING_INDEX(a.genre, '/', -1)
                ELSE NULL
            END AS genre2
        FROM 
            Performance p
        JOIN 
            Artist a ON p.artist_id = a.artist_id
        WHERE 
            a.genre LIKE '%/%'
    ),
    GenrePairs AS (
        SELECT
            genre1,
            genre2,
            COUNT(DISTINCT artist_id) AS artist_count
        FROM
            SplitGenres
        WHERE
            genre2 IS NOT NULL
        GROUP BY
            genre1, genre2
    )
    SELECT
        genre1,
        genre2,
        artist_count
    FROM
        GenrePairs
    ORDER BY
        artist_count DESC, genre1, genre2
    LIMIT 3;
    