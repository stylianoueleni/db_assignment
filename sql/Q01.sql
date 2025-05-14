-- Query 1: revenue_by_year_payment


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
    