"""
SQL queries for the Music Festival Database App.

This module contains the 15 SQL queries required by the assignment, organized as dictionaries.
Each query addresses a specific analytical question about the music festival data.
The module also includes special query variants optimized for performance testing
and join strategy comparison, particularly for queries 4 and 6.
"""

"""
Main query dictionary containing the 15 required SQL queries.
Each query is stored with a descriptive key that indicates its purpose.
"""
QUERIES = {
    # 1. Festival revenue by year and payment method
    "revenue_by_year_payment": """
    SELECT 
        f.year, 
        pm.name AS payment_method, 
        SUM(t.price) AS total_revenue,
        COUNT(t.ticket_id) AS tickets_sold
    FROM 
        Ticket t
    JOIN 
        Event e ON t.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    JOIN 
        Festival f ON fd.festival_id = f.festival_id
    JOIN 
        PaymentMethod pm ON t.method_id = pm.method_id
    GROUP BY 
        f.year, pm.name
    ORDER BY 
        f.year DESC, total_revenue DESC;
    """,
    
    # 2. Artists belonging to a specific genre with indication of festival participation for a given year
    "artists_by_genre_participation": """
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
    """,
    
    # 3. Artists who performed as warm-up more than 2 times in the same festival
    "frequent_warmup_artists": """
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
    """,
    
    # 4. Average ratings for an artist (performance and overall impression)
    "artist_average_ratings": """
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
    """,
    
    # 5. Young artists (under 30) with most festival participations
    "young_artists_participation": """
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
    """,
    
    # 6. Performances attended by a specific visitor and their average ratings
    "visitor_performances_ratings": """
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
    """,
    
    # 7. Festival with lowest average experience level of technical staff
    "festival_lowest_tech_experience": """
    SELECT 
        f.festival_id,
        f.name AS festival_name,
        f.year,
        AVG(el.level_id) AS avg_experience_level
    FROM 
        Festival f
    JOIN 
        FestivalDay fd ON f.festival_id = fd.festival_id
    JOIN 
        Event e ON fd.day_id = e.day_id
    JOIN 
        Staff_Assignment sa ON e.event_id = sa.event_id
    JOIN 
        Staff s ON sa.staff_id = s.staff_id
    JOIN 
        ExperienceLevel el ON s.level_id = el.level_id
    JOIN 
        StaffRole sr ON s.role_id = sr.role_id
    WHERE 
        sr.name = 'Technician'
    GROUP BY 
        f.festival_id, f.name, f.year
    ORDER BY 
        avg_experience_level ASC
    LIMIT 1;
    """,
    
    # 8. Support staff not scheduled for a specific date
    "unscheduled_support_staff": """
    SELECT 
        s.staff_id,
        s.name,
        s.age,
        el.name AS experience_level
    FROM 
        Staff s
    JOIN 
        ExperienceLevel el ON s.level_id = el.level_id
    JOIN 
        StaffRole sr ON s.role_id = sr.role_id
    WHERE 
        sr.name = 'Support'
        AND s.staff_id NOT IN (
            SELECT 
                sa.staff_id
            FROM 
                Staff_Assignment sa
            JOIN 
                Event e ON sa.event_id = e.event_id
            JOIN 
                FestivalDay fd ON e.day_id = fd.day_id
            WHERE 
                fd.festival_date = %s
        )
    ORDER BY 
        s.name;
    """,
    
    # 9. Visitors who attended the same number of performances in a year (with more than 3 attendances)
    "visitors_same_attendance_count": """
    SELECT 
    v.visitor_id,
    CONCAT(v.first_name, ' ', v.last_name) AS visitor_name,
    attendance.year,
    attendance.attendance_count,
    GROUP_CONCAT(DISTINCT f.name) AS festivals_attended
    FROM 
      Visitor v
    JOIN (
    -- Get attendance counts by visitor and year
    SELECT 
        visitor_id,
        YEAR(fd.festival_date) AS year,
        COUNT(DISTINCT t.ticket_id) AS attendance_count
    FROM 
        Ticket t
    JOIN 
        Event e ON t.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    WHERE 
        t.is_active = FALSE
    GROUP BY 
        visitor_id, year
    HAVING 
        attendance_count > 3
    ) AS attendance ON v.visitor_id = attendance.visitor_id
    JOIN (
    -- Find shared attendance counts
    SELECT 
        year,
        attendance_count
    FROM (
        SELECT 
            YEAR(fd.festival_date) AS year,
            t.visitor_id,
            COUNT(DISTINCT t.ticket_id) AS attendance_count
        FROM 
            Ticket t
        JOIN 
            Event e ON t.event_id = e.event_id
        JOIN 
            FestivalDay fd ON e.day_id = fd.day_id
        WHERE 
            t.is_active = FALSE
        GROUP BY 
            year, t.visitor_id
        HAVING 
            attendance_count > 3
    ) AS visitor_counts
    GROUP BY 
        year, attendance_count
    HAVING 
        COUNT(*) > 1
    ) AS shared_counts 
        ON attendance.year = shared_counts.year 
        AND attendance.attendance_count = shared_counts.attendance_count
    -- Get festival information
    JOIN 
        Ticket t ON v.visitor_id = t.visitor_id
    JOIN 
        Event e ON t.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    JOIN 
        Festival f ON fd.festival_id = f.festival_id
    WHERE 
        t.is_active = FALSE
        AND YEAR(fd.festival_date) = attendance.year
    GROUP BY 
        v.visitor_id, visitor_name, attendance.year, attendance.attendance_count
    ORDER BY 
        attendance.year DESC, attendance.attendance_count DESC;
    """,
    
    # 10. Top 3 pairs of genres that appear together in artists who performed at festivals
    "top_genre_pairs": """
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
    """,
    
    # 11. Artists who performed less frequently than the most active artist
    "less_frequent_artists": """
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
    """,
    
    # 12. Staff required for each festival day by category
    "festival_staff_by_category": """
    SELECT 
        fd.festival_date,
        f.name AS festival_name,
        sr.name AS staff_role,
        COUNT(DISTINCT sa.staff_id) AS assigned_staff,
        COUNT(DISTINCT t.ticket_id) AS tickets_sold,
        -- Maximum staff needed at any single venue
        MAX(CASE 
            WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
            WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
            ELSE 1
        END) AS max_staff_per_venue,
        -- Average staff needed per venue
        ROUND(AVG(CASE 
            WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
            WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
            ELSE 1
        END)) AS avg_staff_per_venue,
        -- Total venues operating that day
        COUNT(DISTINCT s.stage_id) AS operating_venues,
        -- Total concurrent staff if all venues operated at once (renamed from theoretical)
        SUM(CASE 
            WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
            WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
            ELSE 1
        END) AS total_concurrent_staff,
        -- Calculate staffing ratio (percentage of required staff that has been assigned)
        CASE 
            WHEN MAX(CASE 
                WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
                WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
                ELSE 1
            END) = 0 THEN 0
            ELSE ROUND(COUNT(DISTINCT sa.staff_id) / MAX(CASE 
                WHEN sr.name = 'Security' THEN GREATEST(CEIL(s.capacity * 0.05), 1)
                WHEN sr.name = 'Support' THEN GREATEST(CEIL(s.capacity * 0.02), 1)
                ELSE 1
            END) * 100)
        END AS staffing_ratio
    FROM 
        Festival f
    JOIN 
        FestivalDay fd ON f.festival_id = fd.festival_id
    JOIN 
        Event e ON fd.day_id = e.day_id
    JOIN 
        Stage s ON e.stage_id = s.stage_id
    LEFT JOIN 
        Staff_Assignment sa ON e.event_id = sa.event_id
    LEFT JOIN 
        StaffRole sr ON sa.role_id = sr.role_id
    LEFT JOIN 
        Ticket t ON e.event_id = t.event_id
    WHERE
        sr.name IS NOT NULL
    GROUP BY 
        fd.festival_date, f.name, sr.name
    ORDER BY 
        fd.festival_date DESC, sr.name;
    """,
    
    # 13. Artists who performed in festivals on at least 3 different continents
    "artists_multiple_continents": """
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
    """,
    
    # 14. Music genres with the same number of performances in consecutive years (at least 3 per year)
    "genres_consistent_performances": """
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
    """,
    
    # 15. Top 5 visitors with highest overall ratings for a specific artist
    "top_visitors_ratings_for_artist": """
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
    """
}

"""
Special query variants for performance testing and optimization.
These queries include index hints and join strategy directives
for comparing different execution plans, particularly for queries 4 and 6.
"""
SPECIAL_QUERIES = {
    # Query 4 - Artist average ratings with alternative execution plan
    "artist_average_ratings_with_index": """
    /* Using force index hint for performance analysis */
    SELECT 
        a.artist_id,
        a.name,
        AVG(r.artist_rating) AS avg_artist_rating,
        AVG(r.overall_rating) AS avg_overall_rating,
        COUNT(r.review_id) AS total_reviews
    FROM 
        Artist a FORCE INDEX (PRIMARY)
    JOIN 
        Performance p FORCE INDEX (idx_performance_artist) ON a.artist_id = p.artist_id
    JOIN 
        Review r FORCE INDEX (idx_review_performance) ON p.performance_id = r.performance_id
    WHERE 
        a.artist_id = %s
    GROUP BY 
        a.artist_id, a.name;
    """,
    
    # Query 6 - Visitor performances with alternative execution plan
    "visitor_performances_ratings_with_index": """
    /* Using force index hint for performance analysis */
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
        Ticket t FORCE INDEX (idx_ticket_visitor)
    JOIN 
        Event e FORCE INDEX (PRIMARY) ON t.event_id = e.event_id
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
        Review r FORCE INDEX (idx_review_visitor) ON p.performance_id = r.performance_id AND r.visitor_id = t.visitor_id
    WHERE 
        t.visitor_id = %s
        AND t.is_active = FALSE
    GROUP BY 
        e.name, fd.festival_date, performer, pt.name
    ORDER BY 
        fd.festival_date DESC;
    """,

     # Query 4 - Trying to encourage Nested Loop Join
    "artist_average_ratings_nested_loop": """
    /* Query optimized for Nested Loop Join */
    SELECT /*+ JOIN_ORDER(a, p, r) */
        a.artist_id,
        a.name,
        AVG(r.artist_rating) AS avg_artist_rating,
        AVG(r.overall_rating) AS avg_overall_rating,
        COUNT(r.review_id) AS total_reviews
    FROM 
        Artist a
    JOIN 
        Performance p FORCE INDEX (idx_performance_artist) ON a.artist_id = p.artist_id
    JOIN 
        Review r FORCE INDEX (idx_review_performance) ON p.performance_id = r.performance_id
    WHERE 
        a.artist_id = %s
    GROUP BY 
        a.artist_id, a.name;
    """,
    
    # Query 4 - Trying to encourage Hash Join
    "artist_average_ratings_hash": """
    /* Query optimized for Hash Join */
    SELECT /*+ JOIN_ORDER(p, r, a) */
        a.artist_id,
        a.name,
        AVG(r.artist_rating) AS avg_artist_rating,
        AVG(r.overall_rating) AS avg_overall_rating,
        COUNT(r.review_id) AS total_reviews
    FROM 
        Performance p
    JOIN 
        Review r ON p.performance_id = r.performance_id
    JOIN 
        Artist a ON p.artist_id = a.artist_id
    WHERE 
        a.artist_id = %s
    GROUP BY 
        a.artist_id, a.name;
    """,
    
    # Query 4 - Trying to encourage Merge Join
    "artist_average_ratings_merge": """
    /* Query optimized for Merge Join */
    SELECT /*+ JOIN_ORDER(r, p, a) */
        a.artist_id,
        a.name,
        AVG(r.artist_rating) AS avg_artist_rating,
        AVG(r.overall_rating) AS avg_overall_rating,
        COUNT(r.review_id) AS total_reviews
    FROM 
        Review r 
    JOIN 
        Performance p ON r.performance_id = p.performance_id
    JOIN 
        Artist a ON p.artist_id = a.artist_id
    WHERE 
        a.artist_id = %s
    GROUP BY 
        a.artist_id, a.name;
    """,
    
    # Similar variants for Query 6
    "visitor_performances_ratings_nested_loop": """
    /* Query optimized for Nested Loop Join */
    SELECT /*+ JOIN_ORDER(t, e, fd, p, a, b, pt, r) */
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
        Ticket t FORCE INDEX (idx_ticket_visitor)
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
        AND t.is_active = FALSE
    GROUP BY 
        e.name, fd.festival_date, performer, pt.name
    ORDER BY 
        fd.festival_date DESC;
    """,
    
    "visitor_performances_ratings_hash": """
    /* Query optimized for Hash Join */
    SELECT /*+ JOIN_ORDER(p, e, fd, t, r, a, b, pt) */
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
        Performance p
    JOIN 
        Event e ON p.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    JOIN 
        Ticket t ON e.event_id = t.event_id
    LEFT JOIN 
        Review r ON p.performance_id = r.performance_id AND r.visitor_id = t.visitor_id
    LEFT JOIN 
        Artist a ON p.artist_id = a.artist_id
    LEFT JOIN 
        Band b ON p.band_id = b.band_id
    JOIN 
        PerformanceType pt ON p.type_id = pt.type_id
    WHERE 
        t.visitor_id = %s
        AND t.is_active = FALSE
    GROUP BY 
        e.name, fd.festival_date, performer, pt.name
    ORDER BY 
        fd.festival_date DESC;
    """,
    
    "visitor_performances_ratings_merge": """
    /* Query optimized for Merge Join */
    SELECT /*+ JOIN_ORDER(r, p, e, fd, t, a, b, pt) */
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
        Review r
    JOIN 
        Performance p ON r.performance_id = p.performance_id
    JOIN 
        Event e ON p.event_id = e.event_id
    JOIN 
        FestivalDay fd ON e.day_id = fd.day_id
    JOIN 
        Ticket t ON e.event_id = t.event_id AND r.visitor_id = t.visitor_id
    LEFT JOIN 
        Artist a ON p.artist_id = a.artist_id
    LEFT JOIN 
        Band b ON p.band_id = b.band_id
    JOIN 
        PerformanceType pt ON p.type_id = pt.type_id
    WHERE 
        t.visitor_id = %s
        AND t.is_active = FALSE
    GROUP BY 
        e.name, fd.festival_date, performer, pt.name
    ORDER BY 
        fd.festival_date DESC;
    """
}

"""
List of query metadata for the UI, including query descriptions and parameter definitions.
This structure is used to populate the query selection interface and parameter forms.
"""
QUERY_LIST = [
    {
        "id": "revenue_by_year_payment",
        "name": "1. Festival Revenue by Year and Payment Method",
        "description": "Shows the total revenue from ticket sales by year and payment method.",
        "params": []
    },
    {
        "id": "artists_by_genre_participation",
        "name": "2. Artists by Genre with Festival Participation",
        "description": "Lists artists belonging to a specific genre with indication of festival participation for a given year.",
        "params": [
            {"name": "year", "type": "int", "description": "Festival year (e.g., 2024)"},
            {"name": "genre", "type": "str", "description": "Music genre (e.g., Rock, Pop, Jazz)"}
        ]
    },
    {
        "id": "frequent_warmup_artists",
        "name": "3. Artists with Multiple Warm-up Performances",
        "description": "Finds artists who performed as warm-up more than 2 times in the same festival.",
        "params": []
    },
    {
        "id": "artist_average_ratings",
        "name": "4. Artist Average Ratings",
        "description": "Shows the average ratings for an artist (performance and overall impression).",
        "params": [
            {"name": "artist_id", "type": "int", "description": "Artist ID"}
        ],
        "special": True,
        "join_comparison": True 
    },
    {
        "id": "young_artists_participation",
        "name": "5. Young Artists with Most Festival Participations",
        "description": "Lists young artists (under 30) with the most festival participations.",
        "params": []
    },
    {
        "id": "visitor_performances_ratings",
        "name": "6. Visitor Attended Performances and Ratings",
        "description": "Shows performances attended by a specific visitor and their average ratings.",
        "params": [
            {"name": "visitor_id", "type": "int", "description": "Visitor ID"}
        ],
        "special": True,
        "join_comparison": True 
    },
    {
        "id": "festival_lowest_tech_experience",
        "name": "7. Festival with Lowest Technical Staff Experience",
        "description": "Finds the festival with the lowest average experience level of technical staff.",
        "params": []
    },
    {
        "id": "unscheduled_support_staff",
        "name": "8. Unscheduled Support Staff for a Date",
        "description": "Lists support staff not scheduled for a specific date.",
        "params": [
            {"name": "date", "type": "date", "description": "Date (YYYY-MM-DD)"}
        ]
    },
    {
        "id": "visitors_same_attendance_count",
        "name": "9. Visitors with Same Performance Attendance Count",
        "description": "Finds visitors who attended the same number of performances in a year (with more than 3 attendances).",
        "params": []
    },
    {
        "id": "top_genre_pairs",
        "name": "10. Top 3 Genre Pairs in Artists",
        "description": "Lists the top 3 pairs of genres that appear together in artists who performed at festivals.",
        "params": []
    },
    {
        "id": "less_frequent_artists",
        "name": "11. Artists with Fewer Performances Than Top Artist",
        "description": "Shows artists who performed at least 5 fewer times than the most active artist.",
        "params": []
    },
    {
        "id": "festival_staff_by_category",
        "name": "12. Staff Required for Each Festival Day",
        "description": "Lists the staff required for each festival day by category.",
        "params": []
    },
    {
        "id": "artists_multiple_continents",
        "name": "13. Artists Who Performed on Multiple Continents",
        "description": "Finds artists who performed in festivals on at least 3 different continents.",
        "params": []
    },
    {
        "id": "genres_consistent_performances",
        "name": "14. Genres with Consistent Performance Counts",
        "description": "Shows music genres with the same number of performances in consecutive years (at least 3 per year).",
        "params": []
    },
    {
        "id":     "top_visitors_ratings_for_artist",
        "name": "15. Top Visitors by Ratings for an Artist",
        "description": "Lists the top 5 visitors with highest overall ratings for a specific artist.",
        "params": [
            {"name": "artist_id", "type": "int", "description": "Artist ID"}
        ]
    }
]