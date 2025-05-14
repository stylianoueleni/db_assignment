/*
 * Music Festival Database "Pulse University" - Installation Script
 * Created: May 2025
 * 
 * This script creates the database schema for the "Pulse University" music festival
 * management system. It includes tables, constraints, triggers, stored procedures,
 * views, and indexes necessary for the system's operation.
 * 
 * Key Business Rules Implemented:
 *  - Festivals occur annually at different locations
 *  - Security staff must cover at least 5% of the total number of visitors
 *  - Support staff must cover at least 2% of the total number of visitors
 *  - Artists/bands cannot perform at multiple venues simultaneously
 *  - Artists/bands cannot participate for more than 3 consecutive festival years
 *  - VIP tickets are limited to 10% of stage capacity
 *  - Performances have a maximum duration of 3 hours
 *  - Performances require 5-30 minute breaks between them
 *  - Visitors must be at least 16 years old
 *  - Only visitors with used tickets can leave reviews
 *  - Ticket resales follow a FIFO queue system
 * 
 * USAGE:
 *   1. Make sure you have appropriate MySQL/MariaDB permissions
 *   2. Run this script with: mysql -u root -p < install.sql
 * 
 * Note: This script will drop any existing MusicFestival database!
 */

cd "C:\xampp\MySQL\bin"
mysql -u root -p

-- Drop existing database if it exists to ensure clean installation
DROP DATABASE IF EXISTS MusicFestival;
CREATE DATABASE MusicFestival;
USE MusicFestival;

/*==============================================================*/
/* REFERENCE TABLES                                             */
/*==============================================================*/

-- Reference tables containing lookup values and categorization data
/*
 * PaymentMethod Table
 * Stores different methods visitors can use to pay for tickets
 * Examples: Credit Card, Debit Card, Bank Transfer
 * Used by the Ticket table to record payment methods for ticket purchases
 */
CREATE TABLE PaymentMethod (
    method_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

/*
 * ExperienceLevel Table
 * Stores five classification levels for staff experience/expertise
 * Values: Intern, Beginner, Intermediate, Experienced, Expert
 * Used for staff classification and appropriate assignment allocation
 * Helps ensure appropriate skill distribution across festival events
 */
CREATE TABLE ExperienceLevel (
    level_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

/*
 * PerformanceType Table
 * Categorizes the role of performances within a festival event
 * Values: Warm Up, Headline, Special Guest
 * Determines the sequence and importance of artists/bands in the event schedule
 * Used by the Performance table to classify each artist/band appearance
 */
CREATE TABLE PerformanceType (
    type_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

/*
 * StaffRole Table
 * Defines specific job categories for festival personnel
 * Values: Technician, Security, Support
 * Each role has different staffing requirements:
 *  - Security: Must cover at least 5% of total visitors
 *  - Support: Must cover at least 2% of total visitors
 * Used by Staff and Staff_Assignment tables
 */
CREATE TABLE StaffRole (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

/*
 * ResaleStatus Table
 * Tracks the current state of tickets in the resale queue system
 * Values: Available, Sold, Pending, Cancelled
 * Manages the FIFO ticket resale process from listing to purchase completion
 * Used by the ResaleQueue table to track ticket resale status
 */
CREATE TABLE ResaleStatus (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

/*
 * TicketCategory Table
 * Defines different ticket types available for purchase
 * Values: General, VIP, Backstage
 * VIP tickets are limited to 10% of stage capacity (enforced by trigger)
 * Used by the Ticket table to classify ticket types
 */
CREATE TABLE TicketCategory (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);


/*==============================================================*/
/* MAIN ENTITY TABLES                                           */
/*==============================================================*/

-- Core tables containing the primary business entities and relationships

/*
 * Location Table
 * Stores geographic information about festival and stage locations
 * Includes address details and geographic coordinates for mapping
 * Each festival takes place at one location, but locations can host multiple stages
 * Coordinates field uses MySQL spatial data type for geographic mapping
 * Continent field is constrained to valid continent names
 */
CREATE TABLE Location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    country VARCHAR(100) NOT NULL,
    continent VARCHAR(50) NOT NULL,
    coordinates POINT NOT NULL,
    CHECK (continent IN ('Europe', 'Asia', 'Africa', 'North America', 'South America', 'Australia', 'Antarctica'))
);

/*
 * Festival Table
 * Stores information about each annual festival event
 * Key business rules:
 * - Festivals take place in different locations each year
 * - Each festival spans multiple consecutive days (stored in FestivalDay)
 * - Festivals cannot be canceled once scheduled
 * - All dates must be within the declared festival year (enforced by CHECK constraint)
 * - Start date must be before or equal to end date (enforced by CHECK constraint)
 */
CREATE TABLE Festival (
    festival_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    year INT NOT NULL,
    location_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (location_id) REFERENCES Location(location_id) ON DELETE CASCADE,
    CHECK (start_date <= end_date),   -- Ensures start_date is before or equal to end_date
    CHECK (YEAR(start_date) = year AND YEAR(end_date) = year)  -- Ensures dates are within festival year
);

/*
 * Stage Table
 * Stores information about venue stages where performances occur
 * Each stage has a specified capacity that cannot be exceeded for ticket sales
 * Stages are associated with specific locations
 * Contains equipment information for technical specifications
 * Capacity must be positive (enforced by CHECK constraint)
 */
CREATE TABLE Stage (
    stage_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    capacity INT NOT NULL CHECK (capacity > 0),
    equipment TEXT,
    location_id INT NOT NULL,
    FOREIGN KEY (location_id) REFERENCES Location(location_id) ON DELETE CASCADE
);

/*
 * FestivalDay Table
 * Maps individual days to festivals
 * A single festival spans multiple consecutive days
 * Each day can host multiple events across different stages
 * All days must belong to the festival's declared year (enforced by CheckFestivalYear trigger)
 * Includes a unique constraint to prevent duplicate festival days
 */
CREATE TABLE FestivalDay (
    day_id INT AUTO_INCREMENT PRIMARY KEY,
    festival_id INT NOT NULL,
    festival_date DATE NOT NULL,
    FOREIGN KEY (festival_id) REFERENCES Festival(festival_id) ON DELETE CASCADE,
    UNIQUE (festival_id, festival_date)
);

/*
 * Event Table
 * Stores scheduled performances during festival days
 * Each event takes place on a specific festival day at a specific stage
 * Events cannot overlap on the same stage (enforced by check_overlapping_events trigger)
 * Events store time boundaries within which performances are scheduled
 * Start time must be before end time (enforced by CHECK constraint)
 * Unique constraint prevents multiple events on same day/stage/start time
 */
CREATE TABLE Event (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    day_id INT NOT NULL,
    stage_id INT NOT NULL,
    name VARCHAR(100),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (day_id) REFERENCES FestivalDay(day_id) ON DELETE CASCADE,
    FOREIGN KEY (stage_id) REFERENCES Stage(stage_id) ON DELETE CASCADE,
    CHECK (start_time < end_time),
    UNIQUE (day_id, stage_id, start_time)
);

/*
 * Artist Table
 * Stores information about individual performers
 * Tracks personal details, music genre, online presence, and contact information
 * Artists can perform solo or as members of bands through the Artist_Band junction table
 * Business rule: Artists cannot perform at multiple venues simultaneously (enforced by trigger)
 * Business rule: Artists cannot participate for more than 3 consecutive years (enforced by trigger)
 * Pseudonym is optional but must be unique when provided
 */
CREATE TABLE Artist (
    artist_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    pseudonym VARCHAR(100),
    birthdate DATE,
    genre VARCHAR(100) NOT NULL,
    subgenre VARCHAR(100),
    website VARCHAR(255),
    instagram VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_artist_pseudonym UNIQUE (pseudonym)
);

/*
 * Band Table
 * Records information about musical groups/ensembles
 * Contains band name, formation date, genre, and online presence
 * Related to individual artists through the Artist_Band junction table
 * Business rule: Bands cannot perform at multiple venues simultaneously (enforced by trigger)
 * Business rule: Bands cannot participate for more than 3 consecutive years (enforced by trigger)
 * Band names must be unique
 */
CREATE TABLE Band (
    band_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    formation_date DATE NOT NULL,
    genre VARCHAR(100),
    website VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

/*
 * Artist_Band Table
 * Junction table implementing many-to-many relationship between artists and bands
 * Tracks which artists belong to which bands with joining dates
 * Allows artists to be members of multiple bands simultaneously
 * Important for tracking band membership history and current composition
 * Composite primary key prevents duplicate artist-band relationships
 */
CREATE TABLE Artist_Band (
    artist_id INT NOT NULL,
    band_id INT NOT NULL,
    join_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (artist_id, band_id),
    FOREIGN KEY (artist_id) REFERENCES Artist(artist_id) ON DELETE CASCADE,
    FOREIGN KEY (band_id) REFERENCES Band(band_id) ON DELETE CASCADE
);

/*
 * Visitor Table
 * Stores information about festival attendees/ticket holders
 * Contains personal identification, contact details, and age verification
 * Minimum age requirement of 16 years enforced through triggers
 * Connected to tickets, reviews, and the resale queue system
 * Email must be unique and follow a valid format (enforced by CHECK constraint)
 */
CREATE TABLE Visitor (
    visitor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(20),
    birthdate DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT check_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$')
);

/*
 * Staff Table
 * Stores information about personnel working at the festival
 * Each staff member has a specific role (technical, security, support)
 * Staff are categorized by experience level (intern to expert)
 * Includes age verification (must be at least 18 years old)
 * Used with Staff_Assignment to track who works at which events
 */
CREATE TABLE Staff (
    staff_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    age INT NOT NULL CHECK (age >= 18),
    role_id INT NOT NULL,
    level_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES StaffRole(role_id),
    FOREIGN KEY (level_id) REFERENCES ExperienceLevel(level_id)
);

/*
 * Staff_Assignment Table
 * Links staff members to specific events they are working
 * Tracks shift times and specific roles during events
 * Used to ensure adequate staffing for each event
 * Triggers check staff coverage ratios based on ticket sales:
 *  - Security staff must cover at least 5% of total visitors
 *  - Support staff must cover at least 2% of total visitors
 */
CREATE TABLE Staff_Assignment (
    assignment_id INT AUTO_INCREMENT PRIMARY KEY,
    staff_id INT NOT NULL,
    event_id INT NOT NULL,
    role_id INT NOT NULL,
    shift_start TIME,
    shift_end TIME,
    FOREIGN KEY (staff_id) REFERENCES Staff(staff_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES Event(event_id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES StaffRole(role_id)
);

/*
 * Performance Table
 * Central table tracking artist/band appearances at events
 * Key business rules:
 * - Either artist_id OR band_id must be non-null (but not both)
 * - Maximum duration is 180 minutes (3 hours)
 * - Performances must have 5-30 minute breaks between them (enforced by CheckPerformanceGap trigger)
 * - Artists/bands cannot perform at multiple venues simultaneously (enforced by CheckConcurrentPerformances trigger)
 * - Artists/bands cannot participate for more than 3 consecutive years (enforced by CheckConsecutiveYears trigger)
 * - Soft deletion is implemented via is_deleted flag
 * - end_time is calculated automatically using start_time and duration
 */
CREATE TABLE Performance (
    performance_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    artist_id INT,
    band_id INT,
    stage_id INT NOT NULL,
    type_id INT NOT NULL,
    start_time TIME NOT NULL,
    duration INT NOT NULL CHECK (duration BETWEEN 1 AND 180),  -- Μέγιστη διάρκεια 3 ώρες (180 λεπτά)
    end_time TIME AS (ADDTIME(start_time, SEC_TO_TIME(duration * 60))) PERSISTENT,
    is_deleted BOOLEAN DEFAULT FALSE,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (event_id) REFERENCES Event(event_id) ON DELETE CASCADE,
    FOREIGN KEY (artist_id) REFERENCES Artist(artist_id) ON DELETE SET NULL,
    FOREIGN KEY (band_id) REFERENCES Band(band_id) ON DELETE SET NULL,
    FOREIGN KEY (stage_id) REFERENCES Stage(stage_id) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES PerformanceType(type_id),
    CHECK (artist_id IS NOT NULL OR band_id IS NOT NULL)
);

/*
 * Review Table
 * Stores visitor feedback for performances they've attended
 * Uses 5-point Likert scale (1-5) across multiple rating dimensions
 * Only visitors with used (activated) tickets can leave reviews (enforced by InsertReview procedure)
 * Rating dimensions: artist, sound, stage, organization, overall impression
 * Provides valuable data for artist/venue quality assessment
 * All ratings must be between 1 and 5 (enforced by CHECK constraints)
 */
CREATE TABLE Review (
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    visitor_id INT NOT NULL,
    performance_id INT NOT NULL,
    artist_rating INT CHECK (artist_rating BETWEEN 1 AND 5),
    sound_rating INT CHECK (sound_rating BETWEEN 1 AND 5),
    stage_rating INT CHECK (stage_rating BETWEEN 1 AND 5),
    organization_rating INT CHECK (organization_rating BETWEEN 1 AND 5),
    overall_rating INT CHECK (overall_rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (visitor_id) REFERENCES Visitor(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (performance_id) REFERENCES Performance(performance_id) ON DELETE CASCADE
);

/*
 * Ticket Table
 * Records all purchased festival admission tickets
 * Links visitors to specific events with pricing and payment information
 * Tracks ticket status (active/used) and availability for resale
 * Enforces business rules:
 * - VIP ticket limits (max 10% of stage capacity, enforced by CheckVIPTicketLimit trigger)
 * - One ticket per visitor per day/performance (enforced by CheckOneTicketPerVisitorPerDayAndPerformance trigger)
 * - Minimum visitor age (enforced by CheckVisitorAgeForTicketPurchase trigger)
 * - Valid EAN code format (enforced by CheckEANFormat trigger)
 */
CREATE TABLE Ticket (
    ticket_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    visitor_id INT NOT NULL,
    category_id INT NOT NULL,
    method_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    purchase_date DATETIME NOT NULL,
    EAN_code VARCHAR(13) UNIQUE NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    resale_available BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (event_id) REFERENCES Event(event_id) ON DELETE CASCADE,
    FOREIGN KEY (visitor_id) REFERENCES Visitor(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES TicketCategory(category_id),
    FOREIGN KEY (method_id) REFERENCES PaymentMethod(method_id)
);

/*
 * ResaleQueue Table
 * Implements a FIFO queue system for ticket resales
 * Tracks ticket listings, buyer requests, and transaction statuses
 * Prevents ticket scalping through price controls and transparent process
 * Automatically manages the complete resale lifecycle from listing to purchase
 * Status_id references ResaleStatus table (Available, Sold, Pending, Cancelled)
 * Used for implementing ticket marketplace functionality
 */
CREATE TABLE ResaleQueue (
    resale_id INT AUTO_INCREMENT PRIMARY KEY,
    ticket_id INT NOT NULL,
    seller_id INT NOT NULL,
    buyer_id INT,
    request_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id) ON DELETE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES Visitor(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (buyer_id) REFERENCES Visitor(visitor_id) ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES ResaleStatus(status_id)
);

/*
 * Image Table
 * Stores visual assets associated with festival entities
 * Links images to artists, bands and festivals
 * Contains image URLs and descriptive text
 * Supports the festival's website and promotional materials
 * Entity_type is constrained to valid entity types (enforced by CHECK constraint)
 */
CREATE TABLE Image (
    image_id INT AUTO_INCREMENT PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,  -- 'artist', 'band', 'stage', 'festival'
    entity_id INT NOT NULL,  -- ID της οντότητας (π.χ. artist_id)
    image_url VARCHAR(255) NOT NULL,
    description TEXT,
    CHECK (entity_type IN ('artist', 'band', 'stage', 'festival'))
);

/*==============================================================*/
/* TRIGGERS AND PROCEDURES                                          */
/*==============================================================*/

/*
 * Trigger: CheckFestivalYear
 * Purpose: Ensures all festival days belong to the same year as the festival itself
 * Fires: Before inserting a new FestivalDay record
 * Prevents: Scheduling festival days outside of the declared festival year
 */
DELIMITER //
CREATE TRIGGER CheckFestivalYear
BEFORE INSERT ON FestivalDay
FOR EACH ROW
BEGIN
    DECLARE festival_year INT;
    
    SELECT year INTO festival_year
    FROM Festival
    WHERE festival_id = NEW.festival_id;
    
    IF YEAR(NEW.festival_date) != festival_year THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Festival date must belong to the festival year';
    END IF;
END //
DELIMITER ;

/*
 * Trigger: check_overlapping_events
 * Purpose: Prevents scheduling conflicts by ensuring events don't overlap on the same stage
 * Fires: Before inserting a new event record
 * Checks: If the new event's time window overlaps with any existing event on the same stage/day
 * Prevents: Double-booking stages and scheduling conflicts
 */
DELIMITER //
CREATE TRIGGER check_overlapping_events
BEFORE INSERT ON Event
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1 FROM Event e2
        WHERE e2.stage_id = NEW.stage_id
        AND e2.day_id = NEW.day_id
        AND ((NEW.start_time BETWEEN e2.start_time AND e2.end_time) OR
             (NEW.end_time BETWEEN e2.start_time AND e2.end_time) OR
             (e2.start_time BETWEEN NEW.start_time AND NEW.end_time))
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Events cannot overlap on the same stage and day';
    END IF;
END //
DELIMITER ;

/*
 * Trigger: check_visitor_age_insert
 * Purpose: Enforces minimum age requirement (16 years) for festival visitors
 * Fires: Before inserting a new visitor record
 * Checks: If the visitor's age is at least 16 years at current date
 * Prevents: Registration of underage visitors
 */
DELIMITER //
CREATE TRIGGER check_visitor_age_insert
BEFORE INSERT ON Visitor
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.birthdate, CURDATE()) < 16 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Visitor must be at least 16 years old';
    END IF;
END //

/*
 * Trigger: check_visitor_age_update
 * Purpose: Enforces minimum age requirement during visitor data updates
 * Fires: Before updating a visitor record
 * Checks: If the updated birthdate maintains the minimum age requirement
 * Prevents: Circumventing age restrictions through updates
 */
CREATE TRIGGER check_visitor_age_update
BEFORE UPDATE ON Visitor
FOR EACH ROW
BEGIN
    IF TIMESTAMPDIFF(YEAR, NEW.birthdate, CURDATE()) < 16 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Visitor must be at least 16 years old';
    END IF;
END //
DELIMITER ;

/*
 * Procedure: soft_delete_performance
 * Purpose: Implements soft deletion for performance records
 * Instead of permanently removing performances, marks them as deleted
 * Maintains data integrity while removing performances from active use
 * Sets is_deleted flag to TRUE and records deletion timestamp
 */
DELIMITER //
CREATE PROCEDURE soft_delete_performance(IN perf_id INT)
BEGIN
    UPDATE Performance SET is_deleted = TRUE, deleted_at = NOW() WHERE performance_id = perf_id;
END //
DELIMITER ;

/*
 * Trigger: CheckResaleAvailability
 * Purpose: Ensures tickets are actually available for resale before listing
 * Fires: Before inserting a ticket into ResaleQueue
 * Checks: If the ticket's resale_available flag is set to TRUE
 * Prevents: Listing unavailable tickets for resale
 */
DELIMITER //
CREATE TRIGGER CheckResaleAvailability
BEFORE INSERT ON ResaleQueue
FOR EACH ROW
BEGIN
    DECLARE is_available BOOLEAN;
    
    SELECT resale_available INTO is_available
    FROM Ticket
    WHERE ticket_id = NEW.ticket_id;
    
    IF (is_available = FALSE) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Ticket is not available for resale';
    END IF;
END //
DELIMITER ;

/*
 * Trigger: CheckSecurityStaff
 * Purpose: Enforces the business rule requiring security staff to cover at least 5% of stage capacity
 * Fires: Before inserting a staff assignment record
 * Checks: If the new assignment maintains the required security staff ratio
 * Calculation: Based on stage capacity (not ticket sales)
 * Ensures: Adequate security coverage for visitor safety based on the maximum possible attendance
 */
DELIMITER //
DROP TRIGGER IF EXISTS CheckSecurityStaff //
CREATE TRIGGER CheckSecurityStaff
BEFORE INSERT ON Staff_Assignment
FOR EACH ROW
BEGIN
    DECLARE stage_capacity INT DEFAULT 0;
    DECLARE required_staff INT DEFAULT 1; -- Ensure at least 1 security staff
    DECLARE current_staff INT DEFAULT 0;
    DECLARE role_name VARCHAR(50);
    DECLARE total_staff INT DEFAULT 0;

    -- Get the role name for the new assignment
    SELECT name INTO role_name 
    FROM StaffRole 
    WHERE role_id = NEW.role_id;

    -- Only enforce the rule for security staff
    IF (role_name = 'Security') THEN
        -- Get the stage capacity for this event
        SELECT s.capacity INTO stage_capacity
        FROM Event e
        JOIN Stage s ON e.stage_id = s.stage_id
        WHERE e.event_id = NEW.event_id;

        -- Calculate the required number of security staff (5% of capacity, minimum 1)
        SET required_staff = GREATEST(CEIL(stage_capacity * 0.05), 1);

        -- Check the current number of security staff assigned to the event
        SELECT COUNT(*) INTO current_staff 
        FROM Staff_Assignment sa 
        JOIN Staff st ON sa.staff_id = st.staff_id
        WHERE sa.event_id = NEW.event_id 
          AND st.role_id = 2;
        
        -- Add one for the current staff being inserted
        SET total_staff = current_staff + 1;
        
        -- MODIFIED CONDITION: Now we only check if we've exceeded the required staff
        -- This allows incremental additions up to the requirement
        IF (total_staff > required_staff) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Exceeding maximum security staff allocation for this event';
        END IF;
    END IF;
END //
DELIMITER ;

/*
 * Trigger: CheckSupportStaff
 * Purpose: Enforces the business rule requiring support staff to cover at least 2% of stage capacity
 * Fires: Before inserting a staff assignment record
 * Checks: If the new assignment maintains the required support staff ratio
 * Calculation: Based on stage capacity (not ticket sales)
 * Ensures: Adequate support staff for visitor assistance based on the maximum possible attendance
 */
DELIMITER //
DROP TRIGGER IF EXISTS CheckSupportStaff //
CREATE TRIGGER CheckSupportStaff
BEFORE INSERT ON Staff_Assignment
FOR EACH ROW
BEGIN
    DECLARE stage_capacity INT DEFAULT 0;
    DECLARE required_staff INT DEFAULT 1; -- Ensure at least 1 support staff
    DECLARE current_staff INT DEFAULT 0;
    DECLARE role_name VARCHAR(50);
    DECLARE total_staff INT DEFAULT 0;

    -- Get the role name for the new assignment
    SELECT name INTO role_name 
    FROM StaffRole 
    WHERE role_id = NEW.role_id;

    -- Only enforce the rule for support staff
    IF (role_name = 'Support') THEN
        -- Get the stage capacity for this event
        SELECT s.capacity INTO stage_capacity
        FROM Event e
        JOIN Stage s ON e.stage_id = s.stage_id
        WHERE e.event_id = NEW.event_id;

        -- Calculate the required number of support staff (2% of capacity, minimum 1)
        SET required_staff = GREATEST(CEIL(stage_capacity * 0.02), 1);

        -- Check the current number of support staff assigned to the event
        SELECT COUNT(*) INTO current_staff 
        FROM Staff_Assignment sa 
        JOIN Staff st ON sa.staff_id = st.staff_id
        WHERE sa.event_id = NEW.event_id 
          AND st.role_id = 3;
          
        -- Add one for the current staff being inserted
        SET total_staff = current_staff + 1;
        
        -- MODIFIED CONDITION: Now we only check if we've exceeded the required staff
        -- This allows incremental additions up to the requirement
        IF (total_staff > required_staff) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Exceeding maximum support staff allocation for this event';
        END IF;
    END IF;
END //
DELIMITER ;

/*
 * Trigger: CheckConsecutiveYears
 * Purpose: Enforces the business rule that artists/bands cannot
 *          participate in more than 3 consecutive festival years
 * Fires: Before inserting a new performance record
 * Checks: If the artist/band has already performed in the two preceding years
 *         and blocks the insertion if they would exceed the 3-year limit
 * Prevents: Over-saturation of the same performers across consecutive festivals
 */
DELIMITER //
DROP TRIGGER IF EXISTS CheckConsecutiveYears //
CREATE TRIGGER CheckConsecutiveYears
BEFORE INSERT ON Performance
FOR EACH ROW
BEGIN
    DECLARE festival_year INT;
    DECLARE year_minus_one INT;
    DECLARE year_minus_two INT;
    DECLARE consecutive_years INT DEFAULT 0;
    
    -- Get the festival year for this performance
    SELECT f.year INTO festival_year
    FROM Festival f
    JOIN FestivalDay fd ON f.festival_id = fd.festival_id
    JOIN Event e ON fd.day_id = e.day_id
    WHERE e.event_id = NEW.event_id;
    
    -- Check for artists
    IF NEW.artist_id IS NOT NULL THEN
        -- Count how many consecutive years this artist has already performed
        -- in the two years immediately preceding the current year
        SELECT COUNT(DISTINCT f.year) INTO consecutive_years
        FROM Performance p
        JOIN Event e ON p.event_id = e.event_id
        JOIN FestivalDay fd ON e.day_id = fd.day_id
        JOIN Festival f ON fd.festival_id = f.festival_id
        WHERE p.artist_id = NEW.artist_id
        AND f.year IN (festival_year - 2, festival_year - 1);
        
        -- If artist has already performed in the previous 2 consecutive years
        -- AND is now trying to perform in the 4th consecutive year, block it
        IF consecutive_years = 2 THEN
            -- Check if the artist has performed in year - 2
            SELECT COUNT(*) INTO @performed_year_minus_two
            FROM Performance p
            JOIN Event e ON p.event_id = e.event_id
            JOIN FestivalDay fd ON e.day_id = fd.day_id
            JOIN Festival f ON fd.festival_id = f.festival_id
            WHERE p.artist_id = NEW.artist_id
            AND f.year = (festival_year - 2);
            
            -- Check if the artist has performed in year - 1
            SELECT COUNT(*) INTO @performed_year_minus_one
            FROM Performance p
            JOIN Event e ON p.event_id = e.event_id
            JOIN FestivalDay fd ON e.day_id = fd.day_id
            JOIN Festival f ON fd.festival_id = f.festival_id
            WHERE p.artist_id = NEW.artist_id
            AND f.year = (festival_year - 1);
            
            -- Only block if the artist performed in BOTH of the last 2 years
            IF @performed_year_minus_two > 0 AND @performed_year_minus_one > 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Artist cannot participate for more than 3 consecutive years';
            END IF;
        END IF;
    END IF;

    -- Similarly for bands
    IF NEW.band_id IS NOT NULL THEN
        -- Count how many consecutive years this band has already performed
        -- in the two years immediately preceding the current year
        SELECT COUNT(DISTINCT f.year) INTO consecutive_years
        FROM Performance p
        JOIN Event e ON p.event_id = e.event_id
        JOIN FestivalDay fd ON e.day_id = fd.day_id
        JOIN Festival f ON fd.festival_id = f.festival_id
        WHERE p.band_id = NEW.band_id
        AND f.year IN (festival_year - 2, festival_year - 1);
        
        -- If band has already performed in the previous 2 consecutive years
        -- AND is now trying to perform in the 4th consecutive year, block it
        IF consecutive_years = 2 THEN
            -- Check if the band has performed in year - 2
            SELECT COUNT(*) INTO @performed_year_minus_two
            FROM Performance p
            JOIN Event e ON p.event_id = e.event_id
            JOIN FestivalDay fd ON e.day_id = fd.day_id
            JOIN Festival f ON fd.festival_id = f.festival_id
            WHERE p.band_id = NEW.band_id
            AND f.year = (festival_year - 2);
            
            -- Check if the band has performed in year - 1
            SELECT COUNT(*) INTO @performed_year_minus_one
            FROM Performance p
            JOIN Event e ON p.event_id = e.event_id
            JOIN FestivalDay fd ON e.day_id = fd.day_id
            JOIN Festival f ON fd.festival_id = f.festival_id
            WHERE p.band_id = NEW.band_id
            AND f.year = (festival_year - 1);
            
            -- Only block if the band performed in BOTH of the last 2 years
            IF @performed_year_minus_two > 0 AND @performed_year_minus_one > 0 THEN
                SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Band cannot participate for more than 3 consecutive years';
            END IF;
        END IF;
    END IF;
END //
DELIMITER ;

/*
 * Trigger: CheckVIPTicketLimit
 * Purpose: Enforces the business rule that VIP tickets cannot exceed 10% 
 *          of the total capacity of any stage
 * Fires: Before inserting a new ticket record
 * Checks: If selling this VIP ticket would exceed the 10% capacity limit
 * Prevents: Overselling premium tickets and ensures proper venue balance
 */
CREATE TRIGGER CheckVIPTicketLimit
BEFORE INSERT ON Ticket
FOR EACH ROW
BEGIN
    DECLARE vip_category_id INT;
    DECLARE total_capacity INT;
    DECLARE vip_tickets_sold INT;
    
    -- Find the category_id for VIP tickets
    SELECT category_id INTO vip_category_id 
    FROM TicketCategory 
    WHERE name = 'VIP';

    -- Only check for VIP tickets
    IF NEW.category_id = vip_category_id THEN
        -- Get stage capacity via the event_id
        SELECT s.capacity INTO total_capacity
        FROM Stage s
        JOIN Event e ON s.stage_id = e.stage_id
        WHERE e.event_id = NEW.event_id;

        -- Count VIP tickets already sold
        SELECT COUNT(*) INTO vip_tickets_sold
        FROM Ticket
        WHERE event_id = NEW.event_id 
          AND category_id = vip_category_id;

        -- 10% limit check
        IF (vip_tickets_sold + 1) > (total_capacity * 0.10) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'VIP tickets cannot exceed 10% of stage capacity';
        END IF;
    END IF;
END //

/*
 * Trigger: CheckPerformanceGap
 * Purpose: Ensures there is a suitable break between consecutive performances
 * Fires: Before inserting a new performance record
 * Requirements:
 * - Minimum 5 minutes break between performances
 * - Maximum 30 minutes break between performances
 * Prevents: Scheduling conflicts and allows for stage preparation
 */
CREATE TRIGGER CheckPerformanceGap
BEFORE INSERT ON Performance
FOR EACH ROW
BEGIN
    DECLARE prev_end TIME;
    DECLARE next_start TIME;
    DECLARE time_gap_before INT;
    DECLARE time_gap_after INT;
    DECLARE event_date DATE;
    DECLARE current_stage_id INT;
    
    -- Get the stage_id and event date
    SELECT e.stage_id, fd.festival_date INTO current_stage_id, event_date
    FROM Event e
    JOIN FestivalDay fd ON e.day_id = fd.day_id
    WHERE e.event_id = NEW.event_id;

    -- Find the previous performance at the same stage on the same day
    SELECT MAX(p.end_time) INTO prev_end
    FROM Performance p
    JOIN Event e ON p.event_id = e.event_id
    JOIN FestivalDay fd ON e.day_id = fd.day_id
    WHERE e.stage_id = current_stage_id 
      AND fd.festival_date = event_date
      AND p.end_time <= NEW.start_time;
    
    -- Find the next performance at the same stage on the same day
    SELECT MIN(p.start_time) INTO next_start
    FROM Performance p
    JOIN Event e ON p.event_id = e.event_id
    JOIN FestivalDay fd ON e.day_id = fd.day_id
    WHERE e.stage_id = current_stage_id 
      AND fd.festival_date = event_date
      AND p.start_time >= NEW.end_time;
    
    -- Check gap before this performance
    IF prev_end IS NOT NULL THEN
        SET time_gap_before = TIMESTAMPDIFF(MINUTE, prev_end, NEW.start_time);
        
        IF time_gap_before < 5 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Gap before performance must be at least 5 minutes';
        ELSEIF time_gap_before > 30 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Gap before performance must be at most 30 minutes';
        END IF;
    END IF;
    
    -- Check gap after this performance
    IF next_start IS NOT NULL THEN
        SET time_gap_after = TIMESTAMPDIFF(MINUTE, NEW.end_time, next_start);
        
        IF time_gap_after < 5 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Gap after performance must be at least 5 minutes';
        ELSEIF time_gap_after > 30 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Gap after performance must be at most 30 minutes';
        END IF;
    END IF;
END //

/*
 * Trigger: ProcessResaleQueue
 * Purpose: Automates ticket resale process following FIFO (First In, First Out) queue
 * Fires: After inserting a new record in the ResaleQueue
 * Functionality:
 * - When a ticket is listed for resale, find the first interested buyer
 * - If a buyer exists, update the resale status to 'Sold' and transfer ownership
 * - Implements the automatic ticket resale marketplace for sold-out events
 */
CREATE TRIGGER ProcessResaleQueue
AFTER INSERT ON ResaleQueue
FOR EACH ROW
BEGIN
    DECLARE next_buyer INT;
    
    IF (NEW.status_id = (SELECT status_id FROM ResaleStatus WHERE name = 'Available')) THEN
        -- Find the first buyer in the queue (FIFO)
        SELECT buyer_id INTO next_buyer 
        FROM ResaleQueue 
        WHERE ticket_id = NEW.ticket_id 
          AND status_id = (SELECT status_id FROM ResaleStatus WHERE name = 'Pending')
        ORDER BY request_date 
        LIMIT 1;
        
        IF (next_buyer IS NOT NULL) THEN
            -- Update the queue for completed sale
            UPDATE ResaleQueue 
            SET buyer_id = next_buyer, 
                status_id = (SELECT status_id FROM ResaleStatus WHERE name = 'Sold')
            WHERE resale_id = NEW.resale_id;
            
            -- Disable resale for the ticket and transfer ownership
            UPDATE Ticket
            SET resale_available = FALSE,
                visitor_id = next_buyer
            WHERE ticket_id = NEW.ticket_id;
        END IF;
    END IF;
END //

/*
 * Trigger: DeactivateUsedTicket
 * Purpose: Prevents resale of used (activated) tickets
 * Fires: After updating a ticket record
 * Functionality:
 * - When a ticket is marked as used (is_active = FALSE), disable resale
 * - Enforces the business rule that used tickets cannot be resold
 */
CREATE TRIGGER DeactivateUsedTicket
AFTER UPDATE ON Ticket
FOR EACH ROW
BEGIN
    IF NEW.is_active = FALSE THEN
        UPDATE Ticket
        SET resale_available = FALSE
        WHERE ticket_id = NEW.ticket_id;
    END IF;
END //
DELIMITER ;

/*
 * Procedure: process_ticket_resale
 * 
 * Purpose: Manages the ticket resale process including:
 *   - Validating the ticket is available for resale
 *   - Transferring ownership from seller to buyer
 *   - Updating the resale queue status
 *   - Recording the transaction for audit purposes
 * 
 * Parameters:
 *   - IN ticket_id INT: The ID of the ticket being resold
 *   - IN buyer_id INT: The ID of the visitor buying the ticket
 * 
 * Returns: Success/failure message
 * 
 * Used for: Manual processing of resale transactions when required
 */
DELIMITER //
CREATE PROCEDURE process_ticket_resale(IN ticket_id INT, IN buyer_id INT)
BEGIN
    DECLARE seller_id INT;
    DECLARE ticket_price DECIMAL(10,2);
    
    START TRANSACTION;
    
    -- Get seller information
    SELECT visitor_id, price INTO seller_id, ticket_price
    FROM Ticket
    WHERE ticket_id = ticket_id AND resale_available = TRUE;
    
    IF seller_id IS NOT NULL THEN
        -- Update ticket
        UPDATE Ticket
        SET visitor_id = buyer_id, 
            resale_available = FALSE
        WHERE ticket_id = ticket_id;
        
        -- Update resale queue status
        INSERT INTO ResaleQueue (ticket_id, seller_id, buyer_id, status_id, request_date)
        VALUES (ticket_id, seller_id, buyer_id, 
               (SELECT status_id FROM ResaleStatus WHERE name = 'Sold'), 
               NOW());
        
        COMMIT;
    ELSE
        ROLLBACK;
    END IF;
END //
DELIMITER ;

-- Make sure we have 'Cancelled' status in your ResaleStatus table
INSERT INTO ResaleStatus (name)
SELECT 'Cancelled' 
WHERE NOT EXISTS (SELECT 1 FROM ResaleStatus WHERE name = 'Cancelled');

/*
 * Function: has_ticket_for_event
 * Purpose: Checks if a visitor already has a ticket for a specific event
 * Returns: Boolean (TRUE if visitor has a ticket, FALSE otherwise)
 * Parameters:
 *   - p_visitor_id: ID of the visitor to check
 *   - p_event_id: ID of the event to check
 * Used to enforce the business rule: One ticket per visitor per event
 */
DELIMITER //
CREATE FUNCTION has_ticket_for_event(p_visitor_id INT, p_event_id INT) 
RETURNS BOOLEAN
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE has_ticket BOOLEAN;
    
    SELECT EXISTS (
        SELECT 1 
        FROM Ticket 
        WHERE visitor_id = p_visitor_id 
        AND event_id = p_event_id
        AND is_active = TRUE
    ) INTO has_ticket;
    
    RETURN has_ticket;
END //
DELIMITER ;

/*
 * UserNotification Table
 * Manages visitor communication within the system
 * Sends automatic updates for ticket resales and other events
 * Tracks read/unread status of messages
 * Improves user experience through timely updates
 * Used to notify users about important ticket and event changes
 */
CREATE TABLE IF NOT EXISTS UserNotification (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    visitor_id INT NOT NULL,
    title VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visitor_id) REFERENCES Visitor(visitor_id) ON DELETE CASCADE
);

/*
 * ResaleAuditLog Table
 * Maintains a comprehensive audit trail of all ticket resale activities
 * Records actions, involved parties, status changes, and timestamps
 * Essential for troubleshooting, dispute resolution, and security
 * Supports the anti-scalping and fair resale policies
 * Used for tracking and accountability of resale transactions
 */
CREATE TABLE IF NOT EXISTS ResaleAuditLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    action_type VARCHAR(50) NOT NULL,
    ticket_id INT NOT NULL,
    performer_id INT NOT NULL,  -- The visitor who performed the action
    target_id INT,              -- Another visitor affected by the action (if applicable)
    old_status_id INT,
    new_status_id INT,
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES Ticket(ticket_id),
    FOREIGN KEY (performer_id) REFERENCES Visitor(visitor_id),
    FOREIGN KEY (target_id) REFERENCES Visitor(visitor_id)
);

/*
 * Procedure: list_ticket_for_resale
 * 
 * Purpose: Lists a ticket for resale with anti-scalping controls
 * Parameters:
 *   - p_ticket_id: ID of the ticket to list for resale
 *   - p_price: Resale price (limited to max 10% above original price)
 * 
 * Anti-Scalping Measures:
 * - Validates that the ticket is active and not used
 * - Limits resale price to maximum 10% above original price
 * - Records transaction in audit log for transparency
 * - Creates notification for potential buyers
 */
DELIMITER //
CREATE PROCEDURE list_ticket_for_resale(IN p_ticket_id INT, IN p_price DECIMAL(10,2))
BEGIN
    DECLARE v_original_price DECIMAL(10,2);
    DECLARE v_seller_id INT;
    DECLARE v_is_active BOOLEAN;
    DECLARE v_max_price DECIMAL(10,2);
    DECLARE v_price_limit DECIMAL(10,2);
    DECLARE v_message VARCHAR(255); -- Add a variable for the message
    
    -- Get ticket information
    SELECT price, visitor_id, is_active 
    INTO v_original_price, v_seller_id, v_is_active
    FROM Ticket
    WHERE ticket_id = p_ticket_id;
    
    -- Check if ticket exists and is active
    IF v_is_active IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid ticket ID';
    END IF;
    
    IF v_is_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This ticket has already been used and cannot be resold';
    END IF;
    
    -- Calculate maximum allowed price (e.g., 10% above original)
    SET v_price_limit = 1.10;  -- 10% markup limit
    SET v_max_price = v_original_price * v_price_limit;
    
    -- Check if resale price is within limits
    IF p_price > v_max_price THEN
        -- Create the message with CONCAT
        SET v_message = CONCAT('Resale price cannot exceed ', 
                              CAST((v_price_limit * 100) AS CHAR), 
                              '% of original price');
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = v_message;
    END IF;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Update ticket to be available for resale
    UPDATE Ticket
    SET resale_available = TRUE,
        price = p_price  -- Update to the new price
    WHERE ticket_id = p_ticket_id;
    
    -- Add entry to ResaleQueue
    INSERT INTO ResaleQueue (ticket_id, seller_id, status_id, request_date)
    VALUES (p_ticket_id, v_seller_id, 1, NOW());
    
    -- Log the action
    INSERT INTO ResaleAuditLog (action_type, ticket_id, performer_id, old_status_id, new_status_id, details)
    VALUES ('TICKET_LISTED', p_ticket_id, v_seller_id, NULL, 1,
            CONCAT('Ticket listed for resale at price ', CAST(p_price AS CHAR)));
    
    COMMIT;
    
    SELECT 'Ticket successfully listed for resale' AS Result;
END //
DELIMITER ;

/*
 * Procedure: request_to_buy_ticket
 * 
 * Purpose: Handles buyer requests for tickets listed for resale
 * Parameters:
 *   - p_ticket_id: ID of the ticket the buyer wants to purchase
 *   - p_buyer_id: ID of the visitor making the purchase request
 * 
 * Functionality:
 * - Validates buyer, ticket, and resale availability
 * - Ensures buyer doesn't already have a ticket for the same event
 * - Creates a pending purchase request in the resale queue
 * - Notifies the seller about the purchase request
 * - Records the transaction in the audit log
 */
DELIMITER //
CREATE PROCEDURE request_to_buy_ticket(IN p_ticket_id INT, IN p_buyer_id INT)
BEGIN
    DECLARE v_current_status INT;
    DECLARE v_seller_id INT;
    DECLARE v_is_available BOOLEAN;
    DECLARE v_is_active BOOLEAN;
    DECLARE v_event_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Roll back any changes that were made
        ROLLBACK;
        -- Signal the error to the caller
        RESIGNAL;
    END;
    
    -- Check if the buyer exists
    IF NOT EXISTS (SELECT 1 FROM Visitor WHERE visitor_id = p_buyer_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid buyer ID';
    END IF;
    
    -- Check if the ticket exists
    IF NOT EXISTS (SELECT 1 FROM Ticket WHERE ticket_id = p_ticket_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid ticket ID';
    END IF;
    
    -- Check if the ticket exists and is available for resale
    SELECT resale_available, is_active, visitor_id, event_id
    INTO v_is_available, v_is_active, v_seller_id, v_event_id
    FROM Ticket 
    WHERE ticket_id = p_ticket_id;
    
    -- Check if buyer already has a ticket for this event
    IF has_ticket_for_event(p_buyer_id, v_event_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You already have a ticket for this event';
    END IF;
    
    -- Make sure the buyer is not the same as the seller
    IF v_seller_id = p_buyer_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'You cannot buy your own ticket';
    END IF;
    
    -- Make sure the ticket is still active and available for resale
    IF v_is_active = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This ticket has already been used and cannot be resold';
    END IF;
    
    IF v_is_available = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This ticket is not available for resale';
    END IF;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Check the current status of the ticket in ResaleQueue
    SELECT status_id 
    INTO v_current_status
    FROM ResaleQueue 
    WHERE ticket_id = p_ticket_id
    ORDER BY request_date DESC
    LIMIT 1;
    
    -- Make sure the ticket is available for purchase (status = 1)
    IF v_current_status = 1 THEN
        -- Add the buyer to the ResaleQueue with Pending status
        INSERT INTO ResaleQueue (ticket_id, seller_id, buyer_id, status_id, request_date)
        VALUES (p_ticket_id, v_seller_id, p_buyer_id, 3, NOW()); -- 3 = Pending
        
        -- Add notification for the seller
        INSERT INTO UserNotification (visitor_id, title, message)
        VALUES (v_seller_id, 'New Purchase Request', 
                CONCAT('You have a new purchase request for ticket #', p_ticket_id));
        
        -- Log the action
        INSERT INTO ResaleAuditLog (action_type, ticket_id, performer_id, target_id, old_status_id, new_status_id, details)
        VALUES ('PURCHASE_REQUESTED', p_ticket_id, p_buyer_id, v_seller_id, 1, 3, 'Purchase requested');
        
        COMMIT;
        SELECT 'Purchase request submitted and pending seller approval' AS Result;
    ELSE
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'This ticket is not available for purchase';
    END IF;
END //
DELIMITER ;

/*
 * Procedure: view_pending_requests
 * 
 * Purpose: Displays pending purchase requests for tickets listed by a seller
 * Parameters:
 *   - p_seller_id: ID of the visitor who is selling tickets
 * 
 * Returns: List of pending purchase requests with buyer information
 * Used by sellers to manage and respond to ticket purchase requests
 */
DELIMITER //
CREATE PROCEDURE view_pending_requests(IN p_seller_id INT)
BEGIN
    SELECT 
        rq.resale_id,
        rq.ticket_id,
        t.price,
        tc.name AS ticket_category,
        e.name AS event_name,
        fd.festival_date,
        v.first_name AS buyer_first_name,
        v.last_name AS buyer_last_name,
        v.email AS buyer_email,
        rq.request_date,
        TIMESTAMPDIFF(HOUR, rq.request_date, NOW()) AS hours_pending
    FROM ResaleQueue rq
    JOIN Ticket t ON rq.ticket_id = t.ticket_id
    JOIN TicketCategory tc ON t.category_id = tc.category_id
    JOIN Event e ON t.event_id = e.event_id
    JOIN FestivalDay fd ON e.day_id = fd.day_id
    JOIN Visitor v ON rq.buyer_id = v.visitor_id
    WHERE rq.seller_id = p_seller_id
    AND rq.status_id = 3; -- Pending status
END //
DELIMITER ;

/*
 * Procedure: approve_purchase_request
 * 
 * Purpose: Approves a pending ticket purchase request
 * Parameters:
 *   - p_resale_id: ID of the resale record to approve
 * 
 * Functionality:
 * - Updates ResaleQueue status to Sold
 * - Transfers ticket ownership to the buyer
 * - Disables resale availability for the ticket
 * - Notifies the buyer about the approved purchase
 * - Cancels other pending requests for the same ticket
 * - Notifies rejected buyers
 * - Records all actions in the audit log
 */
DELIMITER //
CREATE PROCEDURE approve_purchase_request(IN p_resale_id INT)
BEGIN
    DECLARE v_ticket_id INT;
    DECLARE v_buyer_id INT;
    DECLARE v_seller_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Roll back any changes that were made
        ROLLBACK;
        -- Signal the error to the caller
        RESIGNAL;
    END;
    
    -- Get ticket and buyer information
    SELECT ticket_id, buyer_id, seller_id
    INTO v_ticket_id, v_buyer_id, v_seller_id
    FROM ResaleQueue
    WHERE resale_id = p_resale_id
    AND status_id = 3; -- Only approve if status is Pending
    
    IF v_ticket_id IS NULL OR v_buyer_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid resale ID or request is not in Pending status';
    END IF;
    
    -- Start transaction for data consistency
    START TRANSACTION;
    
    -- Update ResaleQueue status to Sold
    UPDATE ResaleQueue
    SET status_id = 2, -- Sold
        updated_at = NOW()
    WHERE resale_id = p_resale_id
    AND status_id = 3;
    
    -- Update Ticket record with new owner
    UPDATE Ticket
    SET visitor_id = v_buyer_id,
        resale_available = FALSE,
        updated_at = NOW()
    WHERE ticket_id = v_ticket_id;
    
    -- Add notification for the buyer
    INSERT INTO UserNotification (visitor_id, title, message)
    VALUES (v_buyer_id, 'Purchase Request Approved', 
            CONCAT('Your request to purchase ticket #', v_ticket_id, ' has been approved!'));
    
    -- Log the action
    INSERT INTO ResaleAuditLog (action_type, ticket_id, performer_id, target_id, old_status_id, new_status_id, details)
    VALUES ('PURCHASE_APPROVED', v_ticket_id, v_seller_id, v_buyer_id, 3, 2, 'Purchase request approved');
    
    -- Update other pending requests for this ticket to Cancelled (status_id = 4)
    UPDATE ResaleQueue
    SET status_id = 4, -- Cancelled
        updated_at = NOW()
    WHERE ticket_id = v_ticket_id
    AND status_id = 3
    AND resale_id != p_resale_id;
    
    -- Add notifications for other buyers whose requests were cancelled
    INSERT INTO UserNotification (visitor_id, title, message)
    SELECT buyer_id, 'Purchase Request Cancelled', 
           CONCAT('Your request to purchase ticket #', v_ticket_id, ' has been cancelled because the ticket was sold to another buyer.')
    FROM ResaleQueue
    WHERE ticket_id = v_ticket_id
    AND status_id = 4
    AND updated_at = NOW();
    
    COMMIT;
    
    SELECT 'Purchase request approved successfully' AS Result;
END //
DELIMITER ;

/*
 * Procedure: reject_purchase_request
 * 
 * Purpose: Rejects a pending ticket purchase request
 * Parameters:
 *   - p_resale_id: ID of the resale record to reject
 * 
 * Functionality:
 * - Updates ResaleQueue status to Cancelled
 * - Notifies the buyer about the rejected purchase
 * - Keeps the ticket available for other potential buyers
 * - Records action in the audit log
 * - Re-lists the ticket if there are no other pending requests
 */
DELIMITER //
CREATE PROCEDURE reject_purchase_request(IN p_resale_id INT)
BEGIN
    DECLARE v_ticket_id INT;
    DECLARE v_seller_id INT;
    DECLARE v_buyer_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Roll back any changes that were made
        ROLLBACK;
        -- Signal the error to the caller
        RESIGNAL;
    END;
    
    -- Get ticket information
    SELECT ticket_id, seller_id, buyer_id
    INTO v_ticket_id, v_seller_id, v_buyer_id
    FROM ResaleQueue
    WHERE resale_id = p_resale_id
    AND status_id = 3; -- Only reject if status is Pending
    
    IF v_ticket_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid resale ID or request is not in Pending status';
    END IF;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Update the status to Cancelled instead of deleting
    UPDATE ResaleQueue
    SET status_id = 4, -- Cancelled
        updated_at = NOW()
    WHERE resale_id = p_resale_id
    AND status_id = 3;
    
    -- Add notification for the buyer
    INSERT INTO UserNotification (visitor_id, title, message)
    VALUES (v_buyer_id, 'Purchase Request Rejected', 
            CONCAT('Your request to purchase ticket #', v_ticket_id, ' has been rejected.'));
    
    -- Log the action
    INSERT INTO ResaleAuditLog (action_type, ticket_id, performer_id, target_id, old_status_id, new_status_id, details)
    VALUES ('PURCHASE_REJECTED', v_ticket_id, v_seller_id, v_buyer_id, 3, 4, 'Purchase request rejected');
    
    -- Check if there are any other pending requests in the queue
    IF NOT EXISTS (
        SELECT 1 FROM ResaleQueue
        WHERE ticket_id = v_ticket_id
        AND status_id = 3
    ) THEN
        -- If no more pending requests, make sure the ticket is still marked as available for resale
        IF NOT EXISTS (
            SELECT 1 FROM ResaleQueue
            WHERE ticket_id = v_ticket_id
            AND status_id = 1 -- Available
        ) THEN
            -- Insert a new 'Available' entry
            INSERT INTO ResaleQueue (ticket_id, seller_id, status_id, request_date)
            VALUES (v_ticket_id, v_seller_id, 1, NOW());
            
            -- Log the action
            INSERT INTO ResaleAuditLog (action_type, ticket_id, performer_id, old_status_id, new_status_id, details)
            VALUES ('TICKET_RELISTED', v_ticket_id, v_seller_id, 4, 1, 'Ticket relisted for resale after rejected request');
        END IF;
    END IF;
    
    COMMIT;
    
    SELECT 'Purchase request rejected successfully' AS Result;
END //
DELIMITER ;

/*
 * Procedure: cancel_expired_requests
 * 
 * Purpose: Automatically cancels purchase requests that have been pending too long
 * No parameters - runs as a scheduled event
 * 
 * Functionality:
 * - Identifies pending requests older than the configured timeout period (24 hours)
 * - Updates their status to Cancelled
 * - Notifies buyers about their expired requests
 * - Re-lists tickets for sale if no other pending requests exist
 * - Records all actions in the audit log
 */
DELIMITER //
CREATE PROCEDURE cancel_expired_requests()
BEGIN
    DECLARE expire_hours INT DEFAULT 24; -- Configure timeout period
    DECLARE affected_rows INT;
    
    START TRANSACTION;
    
    -- Find and update expired pending requests
    UPDATE ResaleQueue rq
    JOIN Ticket t ON rq.ticket_id = t.ticket_id
    SET rq.status_id = 4, -- Cancelled
        rq.updated_at = NOW()
    WHERE rq.status_id = 3 -- Pending
    AND rq.request_date < DATE_SUB(NOW(), INTERVAL expire_hours HOUR);
    
    -- Get number of updated rows
    SET affected_rows = ROW_COUNT();
    
    -- Add notifications for buyers whose requests expired
    INSERT INTO UserNotification (visitor_id, title, message)
    SELECT rq.buyer_id, 'Purchase Request Expired', 
           CONCAT('Your request to purchase ticket #', rq.ticket_id, ' has expired.')
    FROM ResaleQueue rq
    WHERE rq.status_id = 4 -- Cancelled
    AND rq.updated_at = NOW();
    
    -- Log the actions
    INSERT INTO ResaleAuditLog (action_type, ticket_id, performer_id, target_id, old_status_id, new_status_id, details)
    SELECT 'REQUEST_EXPIRED', rq.ticket_id, rq.seller_id, rq.buyer_id, 3, 4, 
           CONCAT('Purchase request expired after ', expire_hours, ' hours')
    FROM ResaleQueue rq
    WHERE rq.status_id = 4 -- Cancelled
    AND rq.updated_at = NOW();
    
    -- For each cancelled request, ensure the ticket is still available for resale
    -- This ensures tickets with expired requests go back into the available pool
    INSERT INTO ResaleQueue (ticket_id, seller_id, status_id, request_date)
    SELECT DISTINCT t.ticket_id, t.visitor_id, 1, NOW()
    FROM Ticket t
    JOIN ResaleQueue rq ON t.ticket_id = rq.ticket_id
    WHERE rq.status_id = 4 -- Just cancelled
    AND rq.updated_at = NOW()
    AND t.resale_available = TRUE
    AND NOT EXISTS (
        SELECT 1 
        FROM ResaleQueue rq2 
        WHERE rq2.ticket_id = t.ticket_id 
        AND rq2.status_id = 1 -- Available
    );
    
    -- Log the relisting actions
    INSERT INTO ResaleAuditLog (action_type, ticket_id, performer_id, old_status_id, new_status_id, details)
    SELECT 'TICKET_RELISTED', rq.ticket_id, rq.seller_id, 4, 1, 
           'Ticket relisted after expired request'
    FROM ResaleQueue rq
    WHERE rq.status_id = 1 -- Available
    AND rq.request_date = NOW();
    
    COMMIT;
    
    SELECT CONCAT(affected_rows, ' expired requests cancelled successfully') AS Result;
END //
DELIMITER ;

/*
 * Procedure: mark_notification_read
 * 
 * Purpose: Marks a notification as read for a specific visitor
 * Parameters:
 *   - p_notification_id: ID of the notification to mark as read
 *   - p_visitor_id: ID of the visitor who owns the notification
 * 
 * Validation: Ensures the notification belongs to the specified visitor
 * Used for: Maintaining notification read status in the user interface
 */
DELIMITER //
CREATE PROCEDURE mark_notification_read(IN p_notification_id INT, IN p_visitor_id INT)
BEGIN
    UPDATE UserNotification
    SET is_read = TRUE
    WHERE notification_id = p_notification_id
    AND visitor_id = p_visitor_id;
    
    SELECT 'Notification marked as read' AS Result;
END //
DELIMITER ;

/*
 * Procedure: get_visitor_notifications
 * 
 * Purpose: Retrieves notifications for a specific visitor
 * Parameters:
 *   - p_visitor_id: ID of the visitor to get notifications for
 *   - p_include_read: Boolean flag to include/exclude already read notifications
 * 
 * Returns: List of notifications with their read status
 * Used for: Displaying user notifications in the interface
 */
DELIMITER //
CREATE PROCEDURE get_visitor_notifications(IN p_visitor_id INT, IN p_include_read BOOLEAN)
BEGIN
    SELECT 
        notification_id,
        title,
        message,
        is_read,
        created_at
    FROM UserNotification
    WHERE visitor_id = p_visitor_id
    AND (p_include_read = TRUE OR is_read = FALSE)
    ORDER BY created_at DESC;
END //
DELIMITER ;

/*
 * Procedure: get_ticket_audit_log
 * 
 * Purpose: Retrieves the complete audit trail for a specific ticket
 * Parameters:
 *   - p_ticket_id: ID of the ticket to get the audit log for
 * 
 * Returns: Chronological list of all actions performed on the ticket
 * Used for: Ticket history tracking, dispute resolution, and transparency
 */
DELIMITER //
CREATE PROCEDURE get_ticket_audit_log(IN p_ticket_id INT)
BEGIN
    SELECT 
        ral.log_id,
        ral.action_type,
        ral.performer_id,
        CONCAT(v_perf.first_name, ' ', v_perf.last_name) AS performer_name,
        ral.target_id,
        CASE 
            WHEN ral.target_id IS NOT NULL THEN CONCAT(v_target.first_name, ' ', v_target.last_name)
            ELSE NULL
        END AS target_name,
        rs_old.name AS old_status,
        rs_new.name AS new_status,
        ral.details,
        ral.created_at
    FROM ResaleAuditLog ral
    JOIN Visitor v_perf ON ral.performer_id = v_perf.visitor_id
    LEFT JOIN Visitor v_target ON ral.target_id = v_target.visitor_id
    LEFT JOIN ResaleStatus rs_old ON ral.old_status_id = rs_old.status_id
    LEFT JOIN ResaleStatus rs_new ON ral.new_status_id = rs_new.status_id
    WHERE ral.ticket_id = p_ticket_id
    ORDER BY ral.created_at DESC;
END //
DELIMITER ;

/*
 * Event: cleanup_expired_requests
 * 
 * Purpose: Scheduled task to automatically cancel expired purchase requests
 * Frequency: Runs every 1 hour
 * Action: Calls the cancel_expired_requests procedure
 * Used for: Maintaining a clean and current resale queue system
 */
DELIMITER //
CREATE EVENT IF NOT EXISTS cleanup_expired_requests
ON SCHEDULE EVERY 1 HOUR
DO
BEGIN
    CALL cancel_expired_requests();
END //
DELIMITER ;

-- Enable the event scheduler to allow automatic execution of events
SET GLOBAL event_scheduler = ON;

/*
 * Trigger: CheckConcurrentPerformances
 * Purpose: Enforces the business rule that artists/bands cannot perform
 *          in two different places at the same time
 * Fires: Before inserting a new performance record
 * Checks: If the artist/band is already scheduled to perform at the same time on the same day
 * Prevents: Double-booking artists/bands which would be physically impossible
 */
DELIMITER //
CREATE TRIGGER CheckConcurrentPerformances
BEFORE INSERT ON Performance
FOR EACH ROW
BEGIN
    DECLARE performance_stage_id INT;
    
    -- Get the stage_id for this specific event
    SELECT stage_id INTO performance_stage_id
    FROM Event
    WHERE event_id = NEW.event_id;

    -- Check for artists
    IF NEW.artist_id IS NOT NULL THEN
        -- Check for concurrent performances
        IF EXISTS (
            SELECT 1 FROM Performance p
            JOIN Event e1 ON p.event_id = e1.event_id
            JOIN FestivalDay fd1 ON e1.day_id = fd1.day_id
            JOIN Event e2 ON NEW.event_id = e2.event_id
            JOIN FestivalDay fd2 ON e2.day_id = fd2.day_id
            WHERE p.artist_id = NEW.artist_id
            AND fd1.festival_date = fd2.festival_date
            AND ((NEW.start_time BETWEEN p.start_time AND p.end_time) OR
                 (NEW.end_time BETWEEN p.start_time AND p.end_time) OR
                 (p.start_time BETWEEN NEW.start_time AND NEW.end_time))
        ) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Artist is already performing at this time';
        END IF;
    END IF;
    
    -- Check for bands
	IF NEW.band_id IS NOT NULL THEN
    		IF EXISTS (
        		SELECT 1 FROM Performance p
        		JOIN Event e1 ON p.event_id = e1.event_id
        		JOIN FestivalDay fd1 ON e1.day_id = fd1.day_id
        		JOIN Event e2 ON NEW.event_id = e2.event_id
        		JOIN FestivalDay fd2 ON e2.day_id = fd2.day_id
        		WHERE p.band_id = NEW.band_id
        		AND fd1.festival_date = fd2.festival_date
        		AND ((NEW.start_time BETWEEN p.start_time AND p.end_time) OR
             			(NEW.end_time BETWEEN p.start_time AND p.end_time) OR
             			(p.start_time BETWEEN NEW.start_time AND NEW.end_time))
   	 	) THEN
        		SIGNAL SQLSTATE '45000'
        		SET MESSAGE_TEXT = 'Band is already performing at this time';
    		END IF;
	END IF;
END //
DELIMITER ;

/*
 * Procedure: InsertReview
 * 
 * Purpose: Validates and inserts a new review from a visitor
 * Parameters:
 *   - p_visitor_id: ID of the visitor submitting the review
 *   - p_performance_id: ID of the performance being reviewed
 *   - p_artist_rating, p_sound_rating, p_stage_rating, p_organization_rating, p_overall_rating: 
 *     Rating values (1-5) for different aspects of the performance
 * 
 * Business Rule: Only visitors with used tickets can leave reviews
 * Validation: Checks if the visitor has a used (activated) ticket for the performance
 * Used for: Collecting visitor feedback on performances
 */
DELIMITER //
CREATE PROCEDURE InsertReview(
    IN p_visitor_id INT,
    IN p_performance_id INT,
    IN p_artist_rating INT,
    IN p_sound_rating INT,
    IN p_stage_rating INT,
    IN p_organization_rating INT,
    IN p_overall_rating INT
)
BEGIN
    DECLARE has_used_ticket BOOLEAN DEFAULT FALSE;

    -- Check if the visitor has a used ticket
    SELECT EXISTS (
        SELECT 1 FROM Ticket t
        JOIN Event e ON t.event_id = e.event_id
        JOIN Performance p ON e.event_id = p.event_id
        WHERE t.visitor_id = p_visitor_id
        AND p.performance_id = p_performance_id
        AND t.is_active = FALSE
    ) INTO has_used_ticket;

    IF NOT has_used_ticket THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Only visitors with used tickets can leave reviews';
    ELSE
        -- Insert the review
        INSERT INTO Review (
            visitor_id, performance_id, artist_rating, sound_rating, stage_rating, organization_rating, overall_rating
        ) VALUES (
            p_visitor_id, p_performance_id, p_artist_rating, p_sound_rating, p_stage_rating, p_organization_rating, p_overall_rating
        );
    END IF;
END //
DELIMITER ;

/*
 * Trigger: CheckOneTicketPerVisitorPerDayAndPerformance
 * Purpose: Prevents duplicate ticket purchases by enforcing the rule that
 *          a visitor can only have one ticket per day and performance
 * Fires: Before inserting a new ticket record
 * Checks: If the visitor already has a ticket for the same artist/band on the same day
 * Prevents: Multiple ticket purchases for the same performance/day
 */
DELIMITER //
CREATE TRIGGER CheckOneTicketPerVisitorPerDayAndPerformance
BEFORE INSERT ON Ticket
FOR EACH ROW
BEGIN
    DECLARE festival_date DATE;
    
    -- Find the festival date for this specific event
    SELECT fd.festival_date INTO festival_date
    FROM Event e
    JOIN FestivalDay fd ON e.day_id = fd.day_id
    WHERE e.event_id = NEW.event_id;
    
    -- Check if visitor already has a ticket for the same day and performance
    IF EXISTS (
        SELECT 1 
        FROM Ticket t
        JOIN Event e1 ON t.event_id = e1.event_id
        JOIN FestivalDay fd1 ON e1.day_id = fd1.day_id
        JOIN Performance p1 ON e1.event_id = p1.event_id
        JOIN Event e2 ON NEW.event_id = e2.event_id
        JOIN FestivalDay fd2 ON e2.day_id = fd2.day_id
        JOIN Performance p2 ON e2.event_id = p2.event_id
        WHERE t.visitor_id = NEW.visitor_id
          AND fd1.festival_date = fd2.festival_date
          AND (
              -- Check for same performance (same artist or band)
              (p1.artist_id IS NOT NULL AND p1.artist_id = p2.artist_id) OR
              (p1.band_id IS NOT NULL AND p1.band_id = p2.band_id)
          )
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Visitor already has a ticket for this day and performance';
    END IF;
END //
DELIMITER ;

/*
 * Trigger: CheckVisitorAgeForTicketPurchase
 * Purpose: Reinforces the minimum age requirement for ticket purchases
 * Fires: Before inserting a new ticket record
 * Checks: If the visitor is at least 16 years old (calculated dynamically)
 * Note: Complements the visitor age check triggers on the Visitor table
 * Prevents: Ticket sales to underage visitors
 */
DELIMITER //
CREATE TRIGGER CheckVisitorAgeForTicketPurchase
BEFORE INSERT ON Ticket
FOR EACH ROW
BEGIN
    DECLARE visitor_age INT;
    
    -- Calculate the visitor's age dynamically
    SELECT TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) INTO visitor_age
    FROM Visitor
    WHERE visitor_id = NEW.visitor_id;
    
    -- Check if the visitor is at least 16 years old
    IF (visitor_age < 16) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Visitor must be at least 16 years old to purchase a ticket';
    END IF;
END //
DELIMITER ;

/*
 * Trigger: CheckEANFormat
 * Purpose: Validates the EAN-13 code format for tickets
 * Fires: Before inserting a new ticket record
 * Checks: If the EAN code is exactly 13 digits
 * Ensures: Standardized and valid ticket identification codes
 */
DELIMITER //
CREATE TRIGGER CheckEANFormat
BEFORE INSERT ON Ticket
FOR EACH ROW
BEGIN
    IF NEW.EAN_code NOT REGEXP '^[0-9]{13}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'EAN code must be exactly 13 digits';
    END IF;
END //
DELIMITER ;


/*==============================================================*/
/* INDEXES                                                      */
/*==============================================================*/

-- Indexes to optimize query performance
/*
 * Index: idx_artist_genre
 * Type: B-Tree
 * Purpose: Optimizes queries that filter artists by genre
 * Used for: Finding artists within specific music genres (Query #2)
 */
CREATE INDEX idx_artist_genre ON Artist(genre);

/*
 * Index: idx_review_performance
 * Type: B-Tree
 * Purpose: Optimizes queries that filter reviews by performance
 * Used for: Calculating average ratings for performances (Query #4)
 */
CREATE INDEX idx_review_performance ON Review(performance_id);

/*
 * Index: idx_performance_artist
 * Type: B-Tree
 * Purpose: Optimizes queries that filter or join on the artist_id column
 *          in the Performance table, particularly for queries #3, #4, and #13
 */
CREATE INDEX idx_performance_artist ON Performance(artist_id);

/*
 * Index: idx_performance_band
 * Type: B-Tree
 * Purpose: Optimizes queries that filter performances by band
 * Used for: Finding band performances and checking concurrent performances
 */
CREATE INDEX idx_performance_band ON Performance(band_id);

/*
 * Index: idx_resale_ticket
 * Type: B-Tree
 * Purpose: Optimizes queries that filter resale records by ticket
 * Used for: Ticket resale system queries and procedures
 */
CREATE INDEX idx_resale_ticket ON ResaleQueue(ticket_id);

/*
 * Index: idx_location_coordinates
 * Type: Spatial
 * Purpose: Optimizes geospatial queries on location coordinates
 * Used for: Finding nearby venues or mapping festival locations
 */
CREATE SPATIAL INDEX idx_location_coordinates ON Location(coordinates);

/*
 * Index: idx_staff_role
 * Type: B-Tree
 * Purpose: Optimizes queries that filter staff by role
 * Used for: Staffing requirement checks and allocation (Queries #7, #8, #12)
 */
CREATE INDEX idx_staff_role ON Staff(role_id);

/*
 * Index: idx_staff_assignment_role
 * Type: B-Tree
 * Purpose: Optimizes queries that filter staff assignments by role
 * Used for: Staff coverage analysis and planning
 */
CREATE INDEX idx_staff_assignment_role ON Staff_Assignment(role_id);

/*
 * Index: idx_review_visitor
 * Type: B-Tree
 * Purpose: Optimizes queries that filter reviews by visitor
 * Used for: Finding reviews submitted by specific visitors (Query #6)
 */
CREATE INDEX idx_review_visitor ON Review(visitor_id);

/*
 * Index: idx_artist_birthdate
 * Type: B-Tree
 * Purpose: Optimizes queries that filter artists by age
 * Used for: Finding young artists (Query #5)
 */
CREATE INDEX idx_artist_birthdate ON Artist(birthdate);

/*
 * Index: ft_artist_search
 * Type: FULLTEXT
 * Purpose: Enables text search across artist name, pseudonym, and genres
 * Used for: Artist search functionality and genre analysis (Query #10)
 */
CREATE FULLTEXT INDEX ft_artist_search ON Artist(name, pseudonym, genre, subgenre);

/*
 * Index: idx_ticket_event
 * Type: B-Tree
 * Purpose: Optimizes queries that filter tickets by event
 * Used for: Ticket sales analysis and event capacity management
 */
CREATE INDEX idx_ticket_event ON Ticket(event_id);

/*
 * Index: idx_ticket_visitor
 * Type: B-Tree
 * Purpose: Optimizes queries that filter tickets by visitor
 * Used for: Finding tickets purchased by specific visitors (Query #9)
 */
CREATE INDEX idx_ticket_visitor ON Ticket(visitor_id);

/*
 * Index: idx_resale_status
 * Type: B-Tree
 * Purpose: Optimizes queries that filter resale records by status
 * Used for: Resale queue management and status tracking
 */
CREATE INDEX idx_resale_status ON ResaleQueue(status_id);

/*
 * Index: idx_performance_start
 * Type: B-Tree
 * Purpose: Optimizes queries that filter performances by start time
 * Used for: Schedule management and overlap prevention
 */
CREATE INDEX idx_performance_start ON Performance(start_time);

/*==============================================================*/
/* PROCEDURES AND FUNCTIONS                                     */
/*==============================================================*/

/*
 * Procedure: search_artists
 * 
 * Purpose: Performs full-text search on artists table
 * Parameters:
 *   - search_term: Text to search for in artist name, pseudonym, and genres
 * 
 * Returns: Ranked list of matching artists with relevance scores
 * Uses the ft_artist_search FULLTEXT index for efficient text search
 */
DELIMITER //
CREATE PROCEDURE search_artists(IN search_term VARCHAR(255))
BEGIN
    SELECT artist_id, name, pseudonym, genre, subgenre
    FROM Artist
    WHERE MATCH(name, pseudonym, genre, subgenre) AGAINST (search_term IN NATURAL LANGUAGE MODE)
    ORDER BY MATCH(name, pseudonym, genre, subgenre) AGAINST (search_term IN NATURAL LANGUAGE MODE) DESC;
END //
DELIMITER ;

/*==============================================================*/
/* VIEWS                                                        */
/*==============================================================*/

/*
 * View: artist_with_age
 * 
 * Purpose: Extends Artist table with dynamically calculated age
 * Calculates age based on birthdate and current date
 * Used for age-related queries without recalculating age each time
 * Particularly useful for Query #5 (finding young artists)
 */
CREATE VIEW artist_with_age AS
SELECT *, 
       TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) AS age
FROM Artist;

/*
 * View: active_performances
 * 
 * Purpose: Provides a filtered view of performances that haven't been
 *          soft-deleted, simplifying queries that need only active data
 * Excludes performances marked as deleted through the soft_delete_performance procedure
 */
CREATE VIEW active_performances AS
SELECT * FROM Performance WHERE is_deleted = FALSE;

/*
 * View: active_events
 * 
 * Purpose: Provides a consolidated view of upcoming events with relevant information
 * Includes: Festival details, event timing, stage information, and ticket availability
 * Filters: Only shows future events (festival_date >= current date)
 * Useful for: Ticket sales dashboards, event promotion, and capacity planning
 */
CREATE VIEW active_events AS
SELECT 
    e.event_id, e.name, s.name AS stage_name, 
    fd.festival_date, f.name AS festival_name,
    e.start_time, e.end_time,
    COUNT(t.ticket_id) AS tickets_sold,
    s.capacity - COUNT(t.ticket_id) AS available_seats
FROM 
    Event e
JOIN 
    Stage s ON e.stage_id = s.stage_id
JOIN 
    FestivalDay fd ON e.day_id = fd.day_id
JOIN 
    Festival f ON fd.festival_id = f.festival_id
LEFT JOIN 
    Ticket t ON e.event_id = t.event_id
WHERE 
    fd.festival_date >= CURDATE()
GROUP BY 
    e.event_id, e.name, s.name, fd.festival_date, f.name, e.start_time, e.end_time
ORDER BY 
    fd.festival_date, e.start_time;

DELIMITER //

/*
 * Function: get_artist_rating_stats
 * 
 * Purpose: Retrieves comprehensive rating statistics for a specific artist
 * Parameter: artist_id_param - The ID of the artist to analyze
 * Returns: JSON object containing all rating metrics
 * Used for: Advanced artist performance analysis and reporting
 */
CREATE FUNCTION get_artist_rating_stats(artist_id_param INT) 
RETURNS JSON
READS SQL DATA
BEGIN
    DECLARE result JSON;
    
    SELECT JSON_OBJECT(
        'artist_id', a.artist_id,
        'name', a.name,
        'avg_artist_rating', AVG(r.artist_rating),
        'avg_sound_rating', AVG(r.sound_rating),
        'avg_stage_rating', AVG(r.stage_rating),
        'avg_organization_rating', AVG(r.organization_rating),
        'avg_overall_rating', AVG(r.overall_rating),
        'total_reviews', COUNT(r.review_id),
        'last_performance', MAX(fd.festival_date)
    ) INTO result
    FROM Artist a
    LEFT JOIN Performance p ON a.artist_id = p.artist_id
    LEFT JOIN Event e ON p.event_id = e.event_id
    LEFT JOIN FestivalDay fd ON e.day_id = fd.day_id
    LEFT JOIN Review r ON p.performance_id = r.performance_id
    WHERE a.artist_id = artist_id_param
    GROUP BY a.artist_id, a.name;
    
    RETURN result;
END //
DELIMITER ;

/*==============================================================*/
/* ARCHIVING FUNCTIONALITY                                      */
/*==============================================================*/

/*
 * ArchivedFestival Table
 * Stores historical festival data older than five years
 * Maintains the same structure as the active Festival table with an additional timestamp
 * Supports data retention policies while optimizing active database performance
 * Accessible for historical reporting and analysis
 */
CREATE TABLE ArchivedFestival LIKE Festival;
ALTER TABLE ArchivedFestival ADD COLUMN archived_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

/*
 * Procedure: archive_old_festivals
 * 
 * Purpose: Moves old festival data to the archive table
 * Archives festivals older than 5 years to optimize active database performance
 * Note: Actual implementation would require additional handling for related records
 */
DELIMITER //
CREATE PROCEDURE archive_old_festivals()
BEGIN
    DECLARE cutoff_year INT;
    SET cutoff_year = YEAR(CURRENT_DATE) - 5;
    
    -- Archive festivals older than 5 years
    INSERT INTO ArchivedFestival 
    SELECT f.*, NOW() FROM Festival f
    WHERE f.year < cutoff_year;
    
    -- Not actually deleting the data, just moving it to archive
    -- Actual deletion would require handling foreign key constraints
END //
DELIMITER ;

/*==============================================================*/
/* CACHING FUNCTIONALITY                                        */
/*==============================================================*/

/*
 * QueryCache Table
 * Provides performance optimization through data caching
 * Stores pre-calculated statistics and frequently accessed data
 * Implements time-based expiration to ensure data freshness
 * Reduces database load for complex reporting queries
 */
CREATE TABLE QueryCache (
    cache_key VARCHAR(255) PRIMARY KEY,
    cache_value JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL
);

/*
 * Procedure: update_festival_statistics_cache
 * 
 * Purpose: Generates and caches comprehensive festival statistics for faster reporting
 * Parameters:
 *   - festival_id_param: ID of the festival to generate statistics for
 * 
 * Calculates: Event counts, ticket sales, revenue metrics, and average ratings
 * Caching: Stores results in QueryCache table with 24-hour expiration
 * Benefits: Reduces database load for frequently accessed reporting data
 */
DELIMITER //
CREATE PROCEDURE update_festival_statistics_cache(IN festival_id_param INT)
BEGIN
    DECLARE cache_result JSON;
    DECLARE cache_key VARCHAR(255);
    
    SET cache_key = CONCAT('festival_stats_', festival_id_param);
    
    -- Generate statistics JSON
    SELECT JSON_OBJECT(
        'festival_id', f.festival_id,
        'name', f.name,
        'year', f.year,
        'total_events', COUNT(DISTINCT e.event_id),
        'total_performances', COUNT(DISTINCT p.performance_id),
        'total_tickets_sold', (SELECT COUNT(*) FROM Ticket t JOIN Event e2 ON t.event_id = e2.event_id JOIN FestivalDay fd2 ON e2.day_id = fd2.day_id WHERE fd2.festival_id = f.festival_id),
        'total_revenue', (SELECT SUM(t.price) FROM Ticket t JOIN Event e2 ON t.event_id = e2.event_id JOIN FestivalDay fd2 ON e2.day_id = fd2.day_id WHERE fd2.festival_id = f.festival_id),
        'avg_ticket_price', (SELECT AVG(t.price) FROM Ticket t JOIN Event e2 ON t.event_id = e2.event_id JOIN FestivalDay fd2 ON e2.day_id = fd2.day_id WHERE fd2.festival_id = f.festival_id),
        'avg_rating', (SELECT AVG(r.overall_rating) FROM Review r JOIN Performance p2 ON r.performance_id = p2.performance_id JOIN Event e2 ON p2.event_id = e2.event_id JOIN FestivalDay fd2 ON e2.day_id = fd2.day_id WHERE fd2.festival_id = f.festival_id)
    ) INTO cache_result
    FROM Festival f
    LEFT JOIN FestivalDay fd ON f.festival_id = fd.festival_id
    LEFT JOIN Event e ON fd.day_id = e.day_id
    LEFT JOIN Performance p ON e.event_id = p.event_id
    WHERE f.festival_id = festival_id_param
    GROUP BY f.festival_id;
    
    -- Update cache
    INSERT INTO QueryCache (cache_key, cache_value, expires_at) 
    VALUES (cache_key, cache_result, DATE_ADD(NOW(), INTERVAL 1 DAY))
    ON DUPLICATE KEY UPDATE 
        cache_value = cache_result,
        created_at = NOW(),
        expires_at = DATE_ADD(NOW(), INTERVAL 1 DAY);
END //
DELIMITER ;

/*==============================================================*/
/* EQUIPMENT MANAGEMENT SYSTEM                                  */
/*==============================================================*/

/*
 * Equipment_Type Table
 * Stores information about different types of technical equipment
 * Includes name, description, and image URL for visual reference
 * Used to categorize and track specialized equipment available for stages
 * Serves as reference data for the Stage_Equipment junction table
 */
CREATE TABLE Equipment_Type (
    type_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    image_url VARCHAR(255)
);

/*
 * Stage_Equipment Table
 * Junction table linking stages to equipment types with quantities
 * Contains inventory of technical equipment available at each stage
 * Supports technical requirements planning for performances
 * Each stage can have multiple equipment types and each equipment type
 * can be used at multiple stages, in varying quantities
 * Used by technical staff to ensure stages meet artist requirements
 * Quantities can be adjusted based on event needs
 * Notes field allows for special instructions or considerations
 */
CREATE TABLE Stage_Equipment (
    stage_equipment_id INT PRIMARY KEY AUTO_INCREMENT,
    stage_id INT NOT NULL,
    equipment_type_id INT NOT NULL,
    quantity INT DEFAULT 1,
    notes TEXT,
    FOREIGN KEY (stage_id) REFERENCES Stage(stage_id),
    FOREIGN KEY (equipment_type_id) REFERENCES Equipment_Type(type_id)
);

/*==============================================================*/
/* AUTO-INCREMENT RESET SYSTEM                                  */
/*==============================================================*/


/*
 * Auto-Increment Reset System
 * It includes a central log table and triggers for all database tables to maintain consistent ID sequences.
 * The system consists of:
 * 1. A ResetLog table to track tables that need AUTO_INCREMENT reset
 * 2. Triggers for each table to detect when they become empty
 * 3. A stored procedure to process the log and perform the resets
 * 4. A scheduled event to run the procedure automatically
 */


/*
 * ResetLog Table
 * Tracks tables that have been completely emptied
 * Used by the auto-increment reset system to maintain consistent ID sequences
 * Contains table names, actions, and timestamps
 * Supports database maintenance and integrity
 */
CREATE TABLE IF NOT EXISTS ResetLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    action VARCHAR(255) NOT NULL,
    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/*
 * The following triggers monitor when tables become empty and log them for reset
 * When a table has all its records deleted, its AUTO_INCREMENT value should be reset
 * Each trigger inserts a record into ResetLog when its respective table is emptied
 * The process_reset_log procedure later processes these logs to reset the sequences
 */

-- Payment Method Trigger - Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_payment_method_id //
CREATE TRIGGER reset_payment_method_id
AFTER DELETE ON PaymentMethod
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM PaymentMethod) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('PaymentMethod', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Experience Level Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_experience_level_id //
CREATE TRIGGER reset_experience_level_id
AFTER DELETE ON ExperienceLevel
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM ExperienceLevel) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('ExperienceLevel', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Performance Type Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_performance_type_id //
CREATE TRIGGER reset_performance_type_id
AFTER DELETE ON PerformanceType
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM PerformanceType) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('PerformanceType', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Staff Role Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_staff_role_id //
CREATE TRIGGER reset_staff_role_id
AFTER DELETE ON StaffRole
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM StaffRole) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('StaffRole', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Resale Status Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_resale_status_id //
CREATE TRIGGER reset_resale_status_id
AFTER DELETE ON ResaleStatus
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM ResaleStatus) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('ResaleStatus', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Ticket Category Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_ticket_category_id //
CREATE TRIGGER reset_ticket_category_id
AFTER DELETE ON TicketCategory
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM TicketCategory) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('TicketCategory', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Location Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_location_id //
CREATE TRIGGER reset_location_id
AFTER DELETE ON Location
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Location) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Location', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Festival Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_festival_id //
CREATE TRIGGER reset_festival_id
AFTER DELETE ON Festival
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Festival) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Festival', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Stage Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_stage_id //
CREATE TRIGGER reset_stage_id
AFTER DELETE ON Stage
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Stage) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Stage', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Festival Day Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_festival_day_id //
CREATE TRIGGER reset_festival_day_id
AFTER DELETE ON FestivalDay
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM FestivalDay) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('FestivalDay', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Event Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_event_id //
CREATE TRIGGER reset_event_id
AFTER DELETE ON Event
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Event) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Event', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Artist Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_artist_id //
CREATE TRIGGER reset_artist_id
AFTER DELETE ON Artist
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Artist) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Artist', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Band Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_band_id //
CREATE TRIGGER reset_band_id
AFTER DELETE ON Band
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Band) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Band', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Visitor Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_visitor_id //
CREATE TRIGGER reset_visitor_id
AFTER DELETE ON Visitor
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Visitor) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Visitor', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Staff Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_staff_id //
CREATE TRIGGER reset_staff_id
AFTER DELETE ON Staff
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Staff) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Staff', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Staff Assignment Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_staff_assignment_id //
CREATE TRIGGER reset_staff_assignment_id
AFTER DELETE ON Staff_Assignment
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Staff_Assignment) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Staff_Assignment', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Performance Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_performance_id //
CREATE TRIGGER reset_performance_id
AFTER DELETE ON Performance
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Performance WHERE is_deleted = FALSE) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Performance', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Review Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_review_id //
CREATE TRIGGER reset_review_id
AFTER DELETE ON Review
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Review) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Review', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Ticket Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_ticket_id //
CREATE TRIGGER reset_ticket_id
AFTER DELETE ON Ticket
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Ticket) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Ticket', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Resale Queue Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_resale_queue_id //
CREATE TRIGGER reset_resale_queue_id
AFTER DELETE ON ResaleQueue
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM ResaleQueue) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('ResaleQueue', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

-- Image Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_image_id //
CREATE TRIGGER reset_image_id
AFTER DELETE ON Image
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Image) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Image', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

--Equipment Type Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS reset_type_id //
CREATE TRIGGER reset_type_id
AFTER DELETE ON Equipment_Type
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Equipment_Type) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Equipment_Type', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

--Stage Equipment Trigger-Resets AUTO_INCREMENT when table is empty
DELIMITER //
DROP TRIGGER IF EXISTS stage_equipment_id //
CREATE TRIGGER stage_equipment_id
AFTER DELETE ON Stage_Equipment
FOR EACH ROW
BEGIN
    IF (SELECT COUNT(*) FROM Stage_Equipment) = 0 THEN
        INSERT INTO ResetLog (table_name, action) VALUES ('Stage_Equipment', 'Reset AUTO_INCREMENT');
    END IF;
END //
DELIMITER ;

/*
 * Procedure: process_reset_log
 * 
 * Purpose: Processes the ResetLog table and resets AUTO_INCREMENT values
 * Functionality:
 *   - Reads entries from ResetLog for tables that need AUTO_INCREMENT reset
 *   - Dynamically constructs and executes ALTER TABLE statements
 *   - Removes processed log entries
 *   - Reports success status
 * 
 * Used for: Maintaining consistent ID sequences in tables after mass deletions
 * Execution: Called by scheduled event auto_process_reset_log
 */
DELIMITER //
DROP PROCEDURE IF EXISTS process_reset_log //
CREATE PROCEDURE process_reset_log()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE table_to_reset VARCHAR(100);
    DECLARE cur CURSOR FOR SELECT DISTINCT table_name FROM ResetLog WHERE action = 'Reset AUTO_INCREMENT';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO table_to_reset;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @sql = CONCAT('ALTER TABLE ', table_to_reset, ' AUTO_INCREMENT = 1');
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Mark as processed
        DELETE FROM ResetLog WHERE table_name = table_to_reset AND action = 'Reset AUTO_INCREMENT';
    END LOOP;
    
    CLOSE cur;
    
    SELECT 'AUTO_INCREMENT values reset successfully' AS Result;
END //
DELIMITER ;

/*
 * Event: auto_process_reset_log
 * 
 * Purpose: Scheduled task to automatically process the reset log
 * Frequency: Runs every 1 second
 * Action: Calls the process_reset_log procedure
 * 
 * This high-frequency check ensures that AUTO_INCREMENT values are
 * reset promptly after tables are emptied, maintaining consistent ID sequences
 */
DROP EVENT IF EXISTS auto_process_reset_log;

DELIMITER //
CREATE EVENT auto_process_reset_log
ON SCHEDULE EVERY 1 SECOND
DO
BEGIN
    CALL process_reset_log();
END //
DELIMITER ;

-- Make sure the event scheduler is enabled
SET GLOBAL event_scheduler = ON;

-- Verify the event was created
SHOW EVENTS;

-- You can check if the event scheduler is running with
SHOW VARIABLES LIKE 'event_scheduler';

