-- Query 11: less_frequent_artists


    WITH ArtistParticipations AS (
        SELECT
            a.artist_id,
            a.name,
            COUNT(DISTINCT f.festival_id) AS festival_count
        FROM
            Artist a
        LEFT JOIN
            Performance p ON a.artist_id = p.artist_id
        LEFT JOIN
            Event e ON p.event_id = e.event_id
        LEFT JOIN
            FestivalDay fd ON e.day_id = fd.day_id
        LEFT JOIN
            Festival f ON fd.festival_id = f.festival_id
        GROUP BY
            a.artist_id, a.name
    ),
    MaxParticipation AS (
        SELECT
            MAX(festival_count) AS max_count
        FROM
            ArtistParticipations
    )
    SELECT
        ap.artist_id,
        ap.name,
        ap.festival_count,
        mp.max_count AS top_artist_count,
        (mp.max_count - ap.festival_count) AS difference
    FROM
        ArtistParticipations ap
    CROSS JOIN
        MaxParticipation mp
    WHERE
        ap.festival_count <= (mp.max_count - 5)
    ORDER BY
        ap.festival_count DESC;
    