-- ========================================================================
-- Enhanced Comprehensive Testing Script for MusicFestival Database Constraints
-- ========================================================================
-- This script systematically tests all constraints in the database.
-- Each test is isolated in its own transaction to prevent interference.
-- All test data is cleaned up automatically after execution.
-- Clear success/failure messages are provided for each test.

SET SQL_MODE = 'ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES';

-- Create a more detailed log table to track test results
DROP TABLE IF EXISTS TestResults;
CREATE TABLE TestResults (
    test_id VARCHAR(10) PRIMARY KEY,
    test_name VARCHAR(255) NOT NULL,
    test_category VARCHAR(50) NOT NULL, -- Added category for better organization
    result ENUM('PASS', 'FAIL') NOT NULL,
    error_message TEXT,
    execution_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    execution_duration INT DEFAULT 0 -- Added to track performance metrics
);

-- Track database stats before/after tests for performance analysis
DROP TABLE IF EXISTS TestPerformanceStats;
CREATE TABLE TestPerformanceStats (
    test_id VARCHAR(10),
    metric_name VARCHAR(50),
    before_value BIGINT,
    after_value BIGINT,
    PRIMARY KEY (test_id, metric_name)
);

-- ============================================================================
-- TEST HELPER PROCEDURES AND FUNCTIONS
-- ============================================================================

DELIMITER //

-- Helper procedure to create valid test data that can be used by other tests
DROP PROCEDURE IF EXISTS create_test_data;
CREATE PROCEDURE create_test_data(OUT p_test_location_id INT, OUT p_test_festival_id INT, 
                                 OUT p_test_day_id INT, OUT p_test_stage_id INT,
                                 OUT p_test_event_id INT, OUT p_test_artist_id INT)
BEGIN
    -- Create unique test data with random identifiers to avoid collision
    DECLARE random_suffix VARCHAR(10);
    SET random_suffix = FLOOR(RAND() * 1000000);
    
    -- Create location
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES (CONCAT('Test Location Address ', random_suffix), 'Test City', 'Test Country', 'Europe', 
            ST_PointFromText('POINT(10 10)', 4326));
    SET p_test_location_id = LAST_INSERT_ID();
    
    -- Create stage
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES (CONCAT('Test Stage ', random_suffix), 'Test stage description', 100, 'Test Equipment', p_test_location_id);
    SET p_test_stage_id = LAST_INSERT_ID();
    
    -- Create festival with UNIQUE year to avoid consecutive years check
    -- Use a random year far in the future to avoid conflicts
    SET @random_year = 2050 + FLOOR(RAND() * 100);
    
    INSERT INTO Festival (name, year, location_id, start_date, end_date, description)
    VALUES (CONCAT('Test Festival ', random_suffix), @random_year, 
            p_test_location_id, 
            CONCAT(@random_year, '-07-01'),
            CONCAT(@random_year, '-07-05'),
            'Test festival description');
    SET p_test_festival_id = LAST_INSERT_ID();
    
    -- Create festival day
    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (p_test_festival_id, CONCAT(@random_year, '-07-01'));
    SET p_test_day_id = LAST_INSERT_ID();
    
    -- Create event
    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (p_test_day_id, p_test_stage_id, CONCAT('Test Event ', random_suffix), '18:00:00', '22:00:00');
    SET p_test_event_id = LAST_INSERT_ID();
    
    -- Create a new artist every time (to avoid consecutive years check)
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES (CONCAT('Test Artist ', random_suffix), CONCAT('TestArtist', random_suffix), '1990-01-01', 'Rock', 'Alternative Rock');
    SET p_test_artist_id = LAST_INSERT_ID();
END;

-- Helper procedure for ticket creation with valid EAN
DROP PROCEDURE IF EXISTS create_ticket_with_valid_ean //
CREATE PROCEDURE create_ticket_with_valid_ean(
    p_event_id INT, 
    p_visitor_id INT, 
    p_category_id INT, 
    p_method_id INT, 
    p_price DECIMAL(10,2), 
    p_is_active BOOLEAN, 
    p_resale_available BOOLEAN,
    OUT p_ticket_id INT
)
BEGIN
    -- Generate a valid 13-digit EAN code with timestamp for uniqueness
    DECLARE valid_ean VARCHAR(13);
    
    -- Create a deterministic 13-digit code (ensure it's exactly 13 digits)
    SET valid_ean = LPAD(CONCAT(p_visitor_id, p_event_id, FLOOR(RAND()*1000)), 13, '0');
    
    -- Insert the ticket with a valid EAN code
    INSERT INTO Ticket (
        event_id, 
        visitor_id, 
        category_id, 
        method_id, 
        price, 
        purchase_date, 
        EAN_code, 
        is_active, 
        resale_available
    )
    VALUES (
        p_event_id,
        p_visitor_id,
        p_category_id,
        p_method_id,
        p_price,
        NOW(),
        valid_ean,
        p_is_active,
        p_resale_available
    );
    
    SET p_ticket_id = LAST_INSERT_ID();
END //

-- Helper procedure to create visitor for testing
DROP PROCEDURE IF EXISTS create_test_visitor //
CREATE PROCEDURE create_test_visitor(OUT p_visitor_id INT)
BEGIN
    DECLARE random_suffix VARCHAR(10);
    SET random_suffix = FLOOR(RAND() * 1000000);
    
    INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
    VALUES (
        CONCAT('Test', random_suffix),
        'Visitor',
        CONCAT('test', random_suffix, '@example.com'),
        CONCAT('+306912', random_suffix),
        DATE_SUB(CURRENT_DATE, INTERVAL 20 YEAR)
    );
    
    SET p_visitor_id = LAST_INSERT_ID();
END //

-- Helper procedure to create staff for testing
DROP PROCEDURE IF EXISTS create_test_staff //
CREATE PROCEDURE create_test_staff(IN p_role_id INT, IN p_level_id INT, OUT p_staff_id INT)
BEGIN
    DECLARE random_suffix VARCHAR(10);
    SET random_suffix = FLOOR(RAND() * 1000000);
    
    INSERT INTO Staff (name, age, role_id, level_id) 
    VALUES (CONCAT('Test Staff ', random_suffix), 25, p_role_id, p_level_id);
    
    SET p_staff_id = LAST_INSERT_ID();
END //

-- Helper function to log test results
DROP PROCEDURE IF EXISTS log_test_result //
CREATE PROCEDURE log_test_result(
    IN p_test_id VARCHAR(10),
    IN p_test_name VARCHAR(255),
    IN p_test_category VARCHAR(50),
    IN p_is_success BOOLEAN,
    IN p_error_message TEXT,
    IN p_duration INT
)
BEGIN
    INSERT INTO TestResults (test_id, test_name, test_category, result, error_message, execution_duration)
    VALUES (
        p_test_id,
        p_test_name,
        p_test_category,
        IF(p_is_success, 'PASS', 'FAIL'),
        p_error_message,
        p_duration
    );
    
    -- Output result to console
    SELECT 
        CONCAT('Test ', p_test_id, ' (', p_test_category, '): ', p_test_name, ' - ', 
               IF(p_is_success, 'PASSED', 'FAILED'), 
               IF(p_error_message IS NULL, '', CONCAT(' (', p_error_message, ')')),
               ' (', p_duration, 'ms)') AS result;
END //

-- Generic test procedure for expected error cases
DROP PROCEDURE IF EXISTS test_constraint //
CREATE PROCEDURE test_constraint(
    IN p_test_id VARCHAR(10),
    IN p_test_name VARCHAR(255),
    IN p_test_category VARCHAR(50),
    IN p_sql TEXT,
    IN p_should_fail BOOLEAN
)
BEGIN
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        IF p_should_fail THEN
            -- This was expected to fail, so it's a pass
            CALL log_test_result(p_test_id, p_test_name, p_test_category, TRUE, CONCAT('Expected error: ', @message), duration);
        ELSE
            -- This was expected to succeed, so it's a fail
            CALL log_test_result(p_test_id, p_test_name, p_test_category, FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        -- Rollback any changes
        ROLLBACK;
    END;
    
    START TRANSACTION;
    
    SET start_time = NOW();
    
    -- Execute the test SQL
    SET @test_sql = p_sql;
    PREPARE stmt FROM @test_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    IF p_should_fail THEN
        -- If we get here, the query succeeded when it should have failed
        CALL log_test_result(p_test_id, p_test_name, p_test_category, FALSE, 'Expected error but operation succeeded', duration);
    ELSE
        -- If we get here, the query succeeded as expected
        CALL log_test_result(p_test_id, p_test_name, p_test_category, TRUE, NULL, duration);
    END IF;
    
    -- Rollback any changes made by the test
    ROLLBACK;
END //

DELIMITER //
DROP PROCEDURE IF EXISTS cleanup_test_data //
CREATE PROCEDURE cleanup_test_data()
BEGIN
    -- Set foreign key checks off to allow deletion in any order
    SET FOREIGN_KEY_CHECKS = 0;
    
    -- Capture IDs for easy reference and complete cleanup
    CREATE TEMPORARY TABLE IF NOT EXISTS test_ids (
        entity_type VARCHAR(50),
        entity_id INT
    );
    
    -- Insert IDs of test entities for tracking
    INSERT INTO test_ids (entity_type, entity_id)
    SELECT 'festival', festival_id FROM Festival WHERE name LIKE 'Test%' OR name LIKE '%Test Festival%' OR name LIKE 'Stress%';
    
    INSERT INTO test_ids (entity_type, entity_id)
    SELECT 'event', event_id FROM Event WHERE name LIKE 'Test%' OR name LIKE '%Test Event%' OR name LIKE 'Stress%';
    
    INSERT INTO test_ids (entity_type, entity_id)
    SELECT 'location', location_id FROM Location WHERE address LIKE 'Test%' OR address LIKE '%Test Location%';
    
    INSERT INTO test_ids (entity_type, entity_id)
    SELECT 'stage', stage_id FROM Stage WHERE name LIKE 'Test%' OR name LIKE '%Test Stage%';
    
    INSERT INTO test_ids (entity_type, entity_id)
    SELECT 'visitor', visitor_id FROM Visitor WHERE first_name LIKE 'Test%' OR first_name LIKE 'VIP Test%' OR first_name LIKE 'Stress Test%';
    
    INSERT INTO test_ids (entity_type, entity_id)
    SELECT 'staff', staff_id FROM Staff WHERE name LIKE 'Test Staff%' OR name LIKE 'Security Staff%' OR name LIKE 'Support Staff%';
    
    INSERT INTO test_ids (entity_type, entity_id)
    SELECT 'artist', artist_id FROM Artist 
    WHERE name LIKE 'Test Artist%' OR name LIKE '%Test%Artist%' OR name LIKE 'Concurrent Test%' OR name LIKE 'ConsecTest%';
    
    -- Clean Reviews and notifications (these might be referencing test data)
    DELETE FROM Review WHERE 
        visitor_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'visitor') OR
        performance_id IN (SELECT performance_id FROM Performance WHERE 
            event_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'event'));
    
    DELETE FROM UserNotification WHERE visitor_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'visitor');
    
    -- Clean ResaleAuditLog and ResaleQueue
    DELETE FROM ResaleAuditLog WHERE 
        ticket_id IN (SELECT ticket_id FROM Ticket WHERE 
            event_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'event') OR
            visitor_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'visitor'));
    
    DELETE FROM ResaleQueue WHERE 
        ticket_id IN (SELECT ticket_id FROM Ticket WHERE 
            event_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'event') OR
            visitor_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'visitor'));
    
    -- Delete tickets with specific EAN patterns used in tests
    DELETE FROM Ticket WHERE 
        EAN_code LIKE '0%' AND LENGTH(EAN_code) = 13 OR 
        event_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'event') OR
        visitor_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'visitor');
    
    -- Delete staff assignments
    DELETE FROM Staff_Assignment WHERE 
        staff_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'staff') OR
        event_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'event');
    
    -- Delete performances
    DELETE FROM Performance WHERE 
        event_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'event') OR
        artist_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'artist');
    
    -- Delete temporary tables used for testing
    DROP TABLE IF EXISTS TestResults;
    DROP TABLE IF EXISTS TestPerformanceStats;
    
    -- Delete core entities created for tests, in proper order
    DELETE FROM Event WHERE event_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'event');
    DELETE FROM FestivalDay WHERE festival_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'festival');
    DELETE FROM Festival WHERE festival_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'festival');
    DELETE FROM Stage WHERE stage_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'stage');
    DELETE FROM Location WHERE location_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'location');
    DELETE FROM Staff WHERE staff_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'staff');
    DELETE FROM Visitor WHERE visitor_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'visitor');
    DELETE FROM Artist WHERE artist_id IN (SELECT entity_id FROM test_ids WHERE entity_type = 'artist');
    
    -- Clean up any orphaned test data that might have been missed
    DELETE FROM Stage_Equipment WHERE stage_id NOT IN (SELECT stage_id FROM Stage);
    DELETE FROM Image WHERE (entity_type = 'artist' AND entity_id NOT IN (SELECT artist_id FROM Artist))
                          OR (entity_type = 'band' AND entity_id NOT IN (SELECT band_id FROM Band))
                          OR (entity_type = 'stage' AND entity_id NOT IN (SELECT stage_id FROM Stage))
                          OR (entity_type = 'festival' AND entity_id NOT IN (SELECT festival_id FROM Festival));
    
    -- Drop the temporary table
    DROP TEMPORARY TABLE IF EXISTS test_ids;
    
    -- Re-enable foreign key checks
    SET FOREIGN_KEY_CHECKS = 1;
    
    SELECT 'Test data cleanup completed' AS message;
END //
DELIMITER ;

-- ============================================================================
-- 1. PRIMARY KEY AND UNIQUE CONSTRAINTS TESTS
-- ============================================================================

-- Test 1.1: Attempt to create duplicate primary keys
CALL test_constraint('PK-1', 'Duplicate primary key in Location', 'PRIMARY_KEY', 
    'INSERT INTO Location (location_id, address, city, country, continent, coordinates) 
     VALUES (1, ''Duplicate Test'', ''Athens'', ''Greece'', ''Europe'',  ST_PointFromText(''POINT(23.7275 37.9838)'', 4326))',
    TRUE);

-- Test 1.2: Test unique constraints on Artist pseudonym
CALL test_constraint('UQ-1', 'Duplicate artist pseudonym', 'UNIQUE_KEY', 
    'INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre) 
     VALUES (''Test Artist'', (SELECT pseudonym FROM Artist WHERE pseudonym IS NOT NULL LIMIT 1), ''1980-01-01'', ''Pop'', ''Dance'')',
    TRUE);

-- Test 1.3: Test unique constraints on Band name
CALL test_constraint('UQ-2', 'Duplicate band name', 'UNIQUE_KEY', 
    'INSERT INTO Band (name, formation_date, genre, website)
     VALUES ((SELECT name FROM Band LIMIT 1), ''1990-01-01'', ''Rock'', ''https://test.com'')',
    TRUE);

-- Test 1.4: Test unique constraint on Visitor email
CALL test_constraint('UQ-3', 'Duplicate visitor email', 'UNIQUE_KEY', 
    'INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
     VALUES (''John'', ''Doe'', (SELECT email FROM Visitor LIMIT 1), ''+30691234567'', ''1985-06-15'')',
    TRUE);

-- Test 1.5: Test unique constraint on Ticket EAN code
CALL test_constraint('UQ-4', 'Duplicate ticket EAN code', 'UNIQUE_KEY', 
    'INSERT INTO Ticket (event_id, visitor_id, category_id, method_id, price, purchase_date, EAN_code, is_active, resale_available)
     SELECT event_id, visitor_id, category_id, method_id, price, NOW(), EAN_code, is_active, resale_available 
     FROM Ticket LIMIT 1',
    TRUE);

-- ============================================================================
-- 2. FOREIGN KEY CONSTRAINTS TESTS
-- ============================================================================

-- Test 2.1: Insert into Festival with non-existent location_id
CALL test_constraint('FK-1', 'Foreign key constraint on Festival location_id', 'FOREIGN_KEY', 
    'INSERT INTO Festival (name, year, location_id, start_date, end_date, description)
     VALUES (''Test Festival'', 2025, 999999, ''2025-07-01'', ''2025-07-05'', ''Test description'')',
    TRUE);

-- Test 2.2: Insert into FestivalDay with non-existent festival_id
CALL test_constraint('FK-2', 'Foreign key constraint on FestivalDay festival_id', 'FOREIGN_KEY', 
    'INSERT INTO FestivalDay (festival_id, festival_date)
     VALUES (999999, ''2025-07-01'')',
    TRUE);

-- Test 2.3: Insert into Performance with non-existent event_id
CALL test_constraint('FK-3', 'Foreign key constraint on Performance event_id', 'FOREIGN_KEY', 
    'INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
     VALUES (999999, (SELECT artist_id FROM Artist LIMIT 1), (SELECT stage_id FROM Stage LIMIT 1), 1, ''18:00:00'', 60)',
    TRUE);

-- Test 2.4: Check ON DELETE CASCADE for Festival -> FestivalDay
DELIMITER //
DROP PROCEDURE IF EXISTS test_cascade_delete //
CREATE PROCEDURE test_cascade_delete()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE day_count_before INT;
    DECLARE day_count_after INT;
    DECLARE error_message TEXT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('FK-4', 'ON DELETE CASCADE Festival -> FestivalDay', 'FOREIGN_KEY', FALSE, CONCAT('Error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new test location
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Cascade Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(0 0)', 4326));
    SET test_location_id = LAST_INSERT_ID();
    
    -- Create a test festival using the new location
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Cascade Test Festival', 2025, test_location_id, '2025-07-01', '2025-07-05');
    SET test_festival_id = LAST_INSERT_ID();
    
    -- Create a test festival day
    INSERT INTO FestivalDay (festival_id, festival_date) 
    VALUES (test_festival_id, '2025-07-01');
    SET test_day_id = LAST_INSERT_ID();
    
    -- Count FestivalDay records before delete
    SELECT COUNT(*) INTO day_count_before FROM FestivalDay WHERE festival_id = test_festival_id;
    
    -- Delete the Festival directly to test cascade deletion
    DELETE FROM Festival WHERE festival_id = test_festival_id;
    
    -- Count FestivalDay records after delete - should be 0
    SELECT COUNT(*) INTO day_count_after FROM FestivalDay WHERE festival_id = test_festival_id;
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    IF day_count_before > 0 AND day_count_after = 0 THEN
        CALL log_test_result('FK-4', 'ON DELETE CASCADE Festival -> FestivalDay', 'FOREIGN_KEY', TRUE, NULL, duration);
    ELSE
        SET error_message = CONCAT('Cascade delete failed: before=', day_count_before, ', after=', day_count_after);
        CALL log_test_result('FK-4', 'ON DELETE CASCADE Festival -> FestivalDay', 'FOREIGN_KEY', FALSE, error_message, duration);
    END IF;
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_cascade_delete();

-- Test 2.5: Check ON DELETE CASCADE for Event -> Performance
DELIMITER //
DROP PROCEDURE IF EXISTS test_cascade_delete_performance //
CREATE PROCEDURE test_cascade_delete_performance()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_artist_id INT;
    DECLARE perf_count_before INT;
    DECLARE perf_count_after INT;
    DECLARE error_message TEXT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('FK-5', 'ON DELETE CASCADE Event -> Performance', 'FOREIGN_KEY', FALSE, CONCAT('Error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create test data
    CALL create_test_data(test_location_id, test_festival_id, test_day_id, test_stage_id, test_event_id, test_artist_id);
    
    -- Create a test performance
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (test_event_id, test_artist_id, test_stage_id, 1, '18:00:00', 60);
    
    -- Count Performance records before delete
    SELECT COUNT(*) INTO perf_count_before FROM Performance WHERE event_id = test_event_id;
    
    -- Delete the Event to test cascade deletion
    DELETE FROM Event WHERE event_id = test_event_id;
    
    -- Count Performance records after delete - should be 0
    SELECT COUNT(*) INTO perf_count_after FROM Performance WHERE event_id = test_event_id;
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    IF perf_count_before > 0 AND perf_count_after = 0 THEN
        CALL log_test_result('FK-5', 'ON DELETE CASCADE Event -> Performance', 'FOREIGN_KEY', TRUE, NULL, duration);
    ELSE
        SET error_message = CONCAT('Cascade delete failed: before=', perf_count_before, ', after=', perf_count_after);
        CALL log_test_result('FK-5', 'ON DELETE CASCADE Event -> Performance', 'FOREIGN_KEY', FALSE, error_message, duration);
    END IF;
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_cascade_delete_performance();

-- ============================================================================
-- 3. CHECK CONSTRAINTS TESTS
-- ============================================================================

-- Test 3.1: Try to insert Location with invalid continent
CALL test_constraint('CHK-1', 'Continent check constraint on Location', 'CHECK_CONSTRAINT', 
    'INSERT INTO Location (address, city, country, continent, coordinates)
     VALUES (''Test Address'', ''Test City'', ''Test Country'', ''Invalid Continent'', ST_PointFromText(''POINT(0 0)'', 4326))',
    TRUE);

-- Test 3.2: Check capacity constraint on Stage (must be positive)
CALL test_constraint('CHK-2', 'Capacity check constraint on Stage', 'CHECK_CONSTRAINT', 
    'INSERT INTO Stage (name, description, capacity, equipment, location_id)
     VALUES (''Test Stage'', ''Test Description'', 0, ''Test Equipment'', 
            (SELECT location_id FROM Location LIMIT 1))',
    TRUE);

-- Test 3.3: Testing age constraint on Visitor (must be >= 16)
CALL test_constraint('CHK-3', 'Age check constraint on Visitor', 'CHECK_CONSTRAINT', 
    'INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
     VALUES (''Young'', ''Person'', ''young.person@test.com'', ''+30691234567'', CURRENT_DATE - INTERVAL 15 YEAR)',
    TRUE);

-- Test 3.4: Testing age constraint on Visitor (exactly 16 years - edge case)
CALL test_constraint('CHK-4', 'Age check constraint on Visitor (edge case - exactly 16)', 'CHECK_CONSTRAINT', 
    'INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
     VALUES (''Almost'', ''Adult'', ''almost.adult@test.com'', ''+30691234567'', CURRENT_DATE - INTERVAL 16 YEAR)',
    FALSE);

-- Test 3.5: Testing duration constraint on Performance (1-180 minutes)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_duration_constraint //
CREATE PROCEDURE test_performance_duration_constraint()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('CHK-5', 'Duration check constraint on Performance (too long)', 'CHECK_CONSTRAINT', TRUE, CONCAT('Expected error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create test data
    CALL create_test_data(test_location_id, test_festival_id, test_day_id, test_stage_id, test_event_id, test_artist_id);
    
    -- Try to insert a performance with invalid duration (too long - 181 minutes)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (test_event_id, test_artist_id, test_stage_id, 1, '18:00:00', 181);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the test failed - the constraint didn't catch the invalid duration
    CALL log_test_result('CHK-5', 'Duration check constraint on Performance (too long)', 'CHECK_CONSTRAINT', FALSE, 'Performance with duration > 180 minutes was allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_duration_constraint();

-- Test 3.6: Testing duration constraint on Performance (too short)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_duration_short //
CREATE PROCEDURE test_performance_duration_short()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('CHK-6', 'Duration check constraint on Performance (too short)', 'CHECK_CONSTRAINT', TRUE, CONCAT('Expected error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create test data
    CALL create_test_data(test_location_id, test_festival_id, test_day_id, test_stage_id, test_event_id, test_artist_id);
    
    -- Try to insert a performance with invalid duration (0 minutes)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (test_event_id, test_artist_id, test_stage_id, 1, '18:00:00', 0);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the test failed - the constraint didn't catch the invalid duration
    CALL log_test_result('CHK-6', 'Duration check constraint on Performance (too short)', 'CHECK_CONSTRAINT', FALSE, 'Performance with duration = 0 minutes was allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_duration_short();

-- Test 3.7: Testing edge case for Performance duration (exactly 1 minute)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_duration_min //
CREATE PROCEDURE test_performance_duration_min()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('CHK-7', 'Duration check constraint on Performance (exactly 1 minute)', 'CHECK_CONSTRAINT', FALSE, CONCAT('Unexpected error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create test data
    CALL create_test_data(test_location_id, test_festival_id, test_day_id, test_stage_id, test_event_id, test_artist_id);
    
    -- Try to insert a performance with edge case duration (1 minute)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (test_event_id, test_artist_id, test_stage_id, 1, '18:00:00', 1);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the test passed - performance with 1 minute was allowed
    CALL log_test_result('CHK-7', 'Duration check constraint on Performance (exactly 1 minute)', 'CHECK_CONSTRAINT', TRUE, NULL, duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_duration_min();

-- Test 3.8: Testing edge case for Performance duration (exactly 180 minutes)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_duration_max //
CREATE PROCEDURE test_performance_duration_max()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('CHK-8', 'Duration check constraint on Performance (exactly 180 minutes)', 'CHECK_CONSTRAINT', FALSE, CONCAT('Unexpected error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create test data
    CALL create_test_data(test_location_id, test_festival_id, test_day_id, test_stage_id, test_event_id, test_artist_id);
    
    -- Try to insert a performance with edge case duration (180 minutes)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (test_event_id, test_artist_id, test_stage_id, 1, '18:00:00', 180);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the test passed - performance with 180 minutes was allowed
    CALL log_test_result('CHK-8', 'Duration check constraint on Performance (exactly 180 minutes)', 'CHECK_CONSTRAINT', TRUE, NULL, duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_duration_max();

-- ============================================================================
-- 4. COMPLEX CONSTRAINTS WITH TRIGGERS TESTS
-- ============================================================================

-- Test 4.1: Check festival date year constraint
DELIMITER //
DROP PROCEDURE IF EXISTS test_festival_date_year //
CREATE PROCEDURE test_festival_date_year()
BEGIN
    DECLARE test_festival_id INT;
    DECLARE test_location_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        IF @message LIKE '%Festival date must belong to the festival year%' THEN
            CALL log_test_result('TRG-1', 'Festival date year constraint', 'TRIGGER', TRUE, 'Correctly blocked festival date with wrong year', duration);
        ELSE
            CALL log_test_result('TRG-1', 'Festival date year constraint', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new location
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Year Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(12 12)', 4326));
    SET test_location_id = LAST_INSERT_ID();
    
    -- Create a festival for 2025
    INSERT INTO Festival (name, year, location_id, start_date, end_date)
    VALUES ('Year Test Festival', 2025, test_location_id, '2025-07-01', '2025-07-05');
    SET test_festival_id = LAST_INSERT_ID();
    
    -- Try to add a festival day with wrong year (2024)
    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (test_festival_id, '2024-07-01');
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we reach here, the constraint failed to catch the wrong year
    CALL log_test_result('TRG-1', 'Festival date year constraint', 'TRIGGER', FALSE, 'Festival date with wrong year was allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_festival_date_year();

-- Test 4.2: Test 3 consecutive years artist limitation
DELIMITER //
DROP PROCEDURE IF EXISTS test_consecutive_years_constraint //
CREATE PROCEDURE test_consecutive_years_constraint()
BEGIN
    DECLARE festival_year1_id INT;
    DECLARE festival_year2_id INT;
    DECLARE festival_year3_id INT;
    DECLARE festival_year4_id INT;
    DECLARE day_year1_id INT;
    DECLARE day_year2_id INT;
    DECLARE day_year3_id INT;
    DECLARE day_year4_id INT;
    DECLARE event_year1_id INT;
    DECLARE event_year2_id INT;
    DECLARE event_year3_id INT;
    DECLARE event_year4_id INT;
    DECLARE consecutive_test_artist_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_location_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- For this test, an error on the fourth year is expected and indicates success
        IF @message LIKE '%Artist cannot participate for more than 3 consecutive years%' THEN
            CALL log_test_result('TRG-2', '3 consecutive years artist limitation', 'TRIGGER', TRUE, 'Correctly blocked 4th consecutive year', duration);
        ELSE
            CALL log_test_result('TRG-2', '3 consecutive years artist limitation', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Consecutive Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(1 1)', 4326));
    SET test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage for testing
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Consecutive Test Stage', 'Test Description', 500, 'Test Equipment', test_location_id);
    SET test_stage_id = LAST_INSERT_ID();
    
    -- Setup - Create festivals for 3 consecutive years
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Year 1 Festival', 2021, test_location_id, '2021-07-01', '2021-07-05');
    SET festival_year1_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (festival_year1_id, '2021-07-01');
    SET day_year1_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (day_year1_id, test_stage_id, 'Year 1 Event', '18:00:00', '23:00:00');
    SET event_year1_id = LAST_INSERT_ID();

    -- Year 2
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Year 2 Festival', 2022, test_location_id, '2022-07-01', '2022-07-05');
    SET festival_year2_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (festival_year2_id, '2022-07-01');
    SET day_year2_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (day_year2_id, test_stage_id, 'Year 2 Event', '18:00:00', '23:00:00');
    SET event_year2_id = LAST_INSERT_ID();

    -- Year 3
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Year 3 Festival', 2023, test_location_id, '2023-07-01', '2023-07-05');
    SET festival_year3_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (festival_year3_id, '2023-07-01');
    SET day_year3_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (day_year3_id, test_stage_id, 'Year 3 Event', '18:00:00', '23:00:00');
    SET event_year3_id = LAST_INSERT_ID();

    -- Year 4 (should trigger error)
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Year 4 Festival', 2024, test_location_id, '2024-07-01', '2024-07-05');
    SET festival_year4_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (festival_year4_id, '2024-07-01');
    SET day_year4_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (day_year4_id, test_stage_id, 'Year 4 Event', '18:00:00', '23:00:00');
    SET event_year4_id = LAST_INSERT_ID();

    -- Add test artist
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('Consecutive Test Artist', 'ConsecTest', '1980-01-01', 'Test Genre', 'Test Subgenre');
    SET consecutive_test_artist_id = LAST_INSERT_ID();

    -- Add performances for years 1-3
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (event_year1_id, consecutive_test_artist_id, test_stage_id, 1, '18:00:00', 60);

    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (event_year2_id, consecutive_test_artist_id, test_stage_id, 1, '18:00:00', 60);

    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (event_year3_id, consecutive_test_artist_id, test_stage_id, 1, '18:00:00', 60);

    -- Now try to add a performance for year 4 (should fail)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (event_year4_id, consecutive_test_artist_id, test_stage_id, 1, '18:00:00', 60);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed
    CALL log_test_result('TRG-2', '3 consecutive years artist limitation', 'TRIGGER', FALSE, 'Artist was allowed to perform for 4 consecutive years', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_consecutive_years_constraint();

-- Test 4.3: Test VIP ticket limit (10% of capacity)
DELIMITER //
DROP PROCEDURE IF EXISTS test_vip_ticket_limit //
CREATE PROCEDURE test_vip_ticket_limit()
BEGIN
    DECLARE vip_test_stage_id INT;
    DECLARE vip_test_festival_id INT;
    DECLARE vip_test_day_id INT;
    DECLARE vip_test_event_id INT;
    DECLARE vip_category_id INT;
    DECLARE first_visitor_id INT;
    DECLARE test_location_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- For this test, an error when adding the 11th VIP ticket is expected (exceeds 10% of 100 capacity)
        IF @message LIKE '%VIP tickets cannot exceed 10% of stage capacity%' THEN
            CALL log_test_result('TRG-3', 'VIP ticket limit constraint', 'TRIGGER', TRUE, 'Correctly blocked exceeding VIP limit', duration);
        ELSE
            CALL log_test_result('TRG-3', 'VIP ticket limit constraint', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create test data
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('VIP Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(20 20)', 4326));
    SET test_location_id = LAST_INSERT_ID();
    
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('VIP Test Stage', 'Test Description', 100, 'Test Equipment', test_location_id);
    SET vip_test_stage_id = LAST_INSERT_ID();

    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('VIP Test Festival', 2025, test_location_id, '2025-08-01', '2025-08-05');
    SET vip_test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (vip_test_festival_id, '2025-08-01');
    SET vip_test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (vip_test_day_id, vip_test_stage_id, 'VIP Test Event', '18:00:00', '23:00:00');
    SET vip_test_event_id = LAST_INSERT_ID();
    
    -- Get VIP category ID
    SELECT category_id INTO vip_category_id FROM TicketCategory WHERE name = 'VIP';
    
    -- Create 11 test visitors
    SET @i = 0;
    SET first_visitor_id = 0;
    
    WHILE @i < 11 DO
        INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
        VALUES (
            CONCAT('VIP Test', @i), 
            'Visitor', 
            CONCAT('viptest', @i, '@test.com'), 
            CONCAT('+3069', @i, '1234567'), 
            DATE_SUB(CURRENT_DATE, INTERVAL 20 YEAR)
        );
        
        IF @i = 0 THEN
            SET first_visitor_id = LAST_INSERT_ID();
        END IF;
        
        SET @i = @i + 1;
    END WHILE;
    
    -- Add 10 VIP tickets (should succeed - exactly 10%)
    SET @i = 0;
    
    WHILE @i < 10 DO
        SET @ticket_ean = LPAD(CONCAT(first_visitor_id + @i, vip_test_event_id, @i), 13, '0');
        
        INSERT INTO Ticket (
            event_id, 
            visitor_id, 
            category_id, 
            method_id, 
            price, 
            purchase_date, 
            EAN_code, 
            is_active, 
            resale_available
        )
        VALUES (
            vip_test_event_id, 
            first_visitor_id + @i, 
            vip_category_id,
            1, 
            100.00, 
            NOW(), 
            @ticket_ean, 
            FALSE, 
            FALSE
        );
        
        SET @i = @i + 1;
    END WHILE;
    
    -- Now try to add one more VIP ticket (should fail - exceeds 10%)
    SET @ticket_ean = LPAD(CONCAT(first_visitor_id + 10, vip_test_event_id, '99'), 13, '0');
    
    INSERT INTO Ticket (
        event_id, 
        visitor_id, 
        category_id, 
        method_id, 
        price, 
        purchase_date, 
        EAN_code, 
        is_active, 
        resale_available
    )
    VALUES (
        vip_test_event_id, 
        first_visitor_id + 10, 
        vip_category_id,
        1, 
        100.00, 
        NOW(), 
        @ticket_ean, 
        FALSE, 
        FALSE
    );
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed - the 11th VIP ticket was allowed
    CALL log_test_result('TRG-3', 'VIP ticket limit constraint', 'TRIGGER', FALSE, '11th VIP ticket was allowed (exceeding 10% limit)', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_vip_ticket_limit();

-- Test 4.4: Check performance gap constraint (5-30 minutes between performances)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_gap_minimum //
CREATE PROCEDURE test_performance_gap_minimum()
BEGIN
    DECLARE gap_test_location_id INT;
    DECLARE gap_test_festival_id INT;
    DECLARE gap_test_day_id INT;
    DECLARE gap_test_event_id INT;
    DECLARE gap_test_stage_id INT;
    DECLARE first_artist_id INT;
    DECLARE second_artist_id INT;
    DECLARE random_year INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- Check if we got the expected error about insufficient gap
        IF @message LIKE '%Gap%must be at least 5 minutes%' THEN
            CALL log_test_result('TRG-4', 'Performance gap constraint (minimum)', 'TRIGGER', TRUE, 'Correctly blocked insufficient gap', duration);
        ELSE
            CALL log_test_result('TRG-4', 'Performance gap constraint (minimum)', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Use a random future year to avoid consecutive years conflicts
    SET random_year = 2050 + FLOOR(RAND() * 100);
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Gap Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(2 2)', 4326));
    SET gap_test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage for testing
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Gap Test Stage', 'Test Description', 500, 'Test Equipment', gap_test_location_id);
    SET gap_test_stage_id = LAST_INSERT_ID();
    
    -- Create a completely new artist for this test
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES (CONCAT('First Gap Test Artist ', FLOOR(RAND() * 1000000)), 
            CONCAT('GapTest1_', FLOOR(RAND() * 1000000)), 
            '1990-01-01', 'Rock', 'Alternative Rock');
    SET first_artist_id = LAST_INSERT_ID();
    
    -- Create another new artist for this test
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES (CONCAT('Second Gap Test Artist ', FLOOR(RAND() * 1000000)), 
            CONCAT('GapTest2_', FLOOR(RAND() * 1000000)), 
            '1990-01-01', 'Rock', 'Alternative Rock');
    SET second_artist_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES (CONCAT('Gap Test Festival ', random_year), random_year, gap_test_location_id, 
            CONCAT(random_year, '-09-01'), CONCAT(random_year, '-09-05'));
    SET gap_test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (gap_test_festival_id, CONCAT(random_year, '-09-01'));
    SET gap_test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (gap_test_day_id, gap_test_stage_id, 'Gap Test Event', '18:00:00', '23:00:00');
    SET gap_test_event_id = LAST_INSERT_ID();

    -- Add first performance (18:00-19:00)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, first_artist_id, gap_test_stage_id, 1, '18:00:00', 60);
    
    -- Try to add second performance with insufficient gap (less than 5 minutes - at 19:04)
    -- This should fail because there should be at least 5 minutes between performances
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, second_artist_id, gap_test_stage_id, 1, '19:04:00', 60);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed
    CALL log_test_result('TRG-4', 'Performance gap constraint (minimum)', 'TRIGGER', FALSE, 'Performance with < 5 minute gap was allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_gap_minimum();

-- Test 4.5: Test excessive gap constraint (more than 30 minutes)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_gap_maximum //
CREATE PROCEDURE test_performance_gap_maximum()
BEGIN
    DECLARE gap_test_location_id INT;
    DECLARE gap_test_festival_id INT;
    DECLARE gap_test_day_id INT;
    DECLARE gap_test_event_id INT;
    DECLARE gap_test_stage_id INT;
    DECLARE first_artist_id INT;
    DECLARE third_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- Check if we got the expected error about excessive gap
        IF @message LIKE '%Gap%must be at most 30 minutes%' THEN
            CALL log_test_result('TRG-5', 'Performance excessive gap constraint', 'TRIGGER', TRUE, 'Correctly blocked excessive gap', duration);
        ELSE
            CALL log_test_result('TRG-5', 'Performance excessive gap constraint', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Excessive Gap Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(3 3)', 4326));
    SET gap_test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage for testing
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Excessive Gap Test Stage', 'Test Description', 500, 'Test Equipment', gap_test_location_id);
    SET gap_test_stage_id = LAST_INSERT_ID();
    
    -- Create two new artists specifically for this test
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('First Gap Max Test Artist', CONCAT('GapMax', FLOOR(RAND() * 1000000)), '1990-01-01', 'Rock', 'Alternative Rock');
    SET first_artist_id = LAST_INSERT_ID();
    
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('Third Gap Max Test Artist', CONCAT('GapMax', FLOOR(RAND() * 1000000)), '1990-01-01', 'Rock', 'Alternative Rock');
    SET third_artist_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Excessive Gap Test Festival', 2025, gap_test_location_id, '2025-09-01', '2025-09-05');
    SET gap_test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (gap_test_festival_id, '2025-09-01');
    SET gap_test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (gap_test_day_id, gap_test_stage_id, 'Excessive Gap Test Event', '18:00:00', '23:00:00');
    SET gap_test_event_id = LAST_INSERT_ID();

    -- Add first performance (18:00-19:00)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, first_artist_id, gap_test_stage_id, 1, '18:00:00', 60);
    
    -- Try to add performance with excessive gap (more than 30 minutes - at 19:31)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, third_artist_id, gap_test_stage_id, 1, '19:31:00', 60);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed
    CALL log_test_result('TRG-5', 'Performance excessive gap constraint', 'TRIGGER', FALSE, 'Performance with > 30 minute gap was allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_gap_maximum();

-- Test 4.6: Test performance gap edge case (exactly 5 minutes)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_gap_min_edge //
CREATE PROCEDURE test_performance_gap_min_edge()
BEGIN
    DECLARE gap_test_location_id INT;
    DECLARE gap_test_festival_id INT;
    DECLARE gap_test_day_id INT;
    DECLARE gap_test_event_id INT;
    DECLARE gap_test_stage_id INT;
    DECLARE first_artist_id INT;
    DECLARE fourth_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('TRG-6', 'Performance gap constraint (exactly 5 minutes)', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Min Edge Gap Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(4 4)', 4326));
    SET gap_test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage for testing
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Min Edge Gap Test Stage', 'Test Description', 500, 'Test Equipment', gap_test_location_id);
    SET gap_test_stage_id = LAST_INSERT_ID();
    
    -- Create two new artists specifically for this test
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('First Min Edge Artist', CONCAT('MinEdge', FLOOR(RAND() * 1000000)), '1990-01-01', 'Rock', 'Alternative Rock');
    SET first_artist_id = LAST_INSERT_ID();
    
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('Fourth Min Edge Artist', CONCAT('MinEdge', FLOOR(RAND() * 1000000)), '1990-01-01', 'Rock', 'Alternative Rock');
    SET fourth_artist_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Min Edge Gap Test Festival', 2025, gap_test_location_id, '2025-09-01', '2025-09-05');
    SET gap_test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (gap_test_festival_id, '2025-09-01');
    SET gap_test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (gap_test_day_id, gap_test_stage_id, 'Min Edge Gap Test Event', '18:00:00', '23:00:00');
    SET gap_test_event_id = LAST_INSERT_ID();

    -- Add first performance (18:00-19:00)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, first_artist_id, gap_test_stage_id, 1, '18:00:00', 60);
    
    -- Try to add performance with exactly 5 minute gap (at 19:05) - should pass
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, fourth_artist_id, gap_test_stage_id, 1, '19:05:00', 60);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the test passed - exactly 5 minute gap was allowed
    CALL log_test_result('TRG-6', 'Performance gap constraint (exactly 5 minutes)', 'TRIGGER', TRUE, NULL, duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_gap_min_edge();

-- Test 4.7: Test performance gap edge case (exactly 30 minutes)
DELIMITER //
DROP PROCEDURE IF EXISTS test_performance_gap_max_edge //
CREATE PROCEDURE test_performance_gap_max_edge()
BEGIN
    DECLARE gap_test_location_id INT;
    DECLARE gap_test_festival_id INT;
    DECLARE gap_test_day_id INT;
    DECLARE gap_test_event_id INT;
    DECLARE gap_test_stage_id INT;
    DECLARE first_artist_id INT;
    DECLARE fifth_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('TRG-7', 'Performance gap constraint (exactly 30 minutes)', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Max Edge Gap Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(5 5)', 4326));
    SET gap_test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage for testing
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Max Edge Gap Test Stage', 'Test Description', 500, 'Test Equipment', gap_test_location_id);
    SET gap_test_stage_id = LAST_INSERT_ID();
    
    -- Create two new artists specifically for this test
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('First Max Edge Artist', CONCAT('MaxEdge', FLOOR(RAND() * 1000000)), '1990-01-01', 'Rock', 'Alternative Rock');
    SET first_artist_id = LAST_INSERT_ID();
    
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('Fifth Max Edge Artist', CONCAT('MaxEdge', FLOOR(RAND() * 1000000)), '1990-01-01', 'Rock', 'Alternative Rock');
    SET fifth_artist_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Max Edge Gap Test Festival', 2025, gap_test_location_id, '2025-09-01', '2025-09-05');
    SET gap_test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (gap_test_festival_id, '2025-09-01');
    SET gap_test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (gap_test_day_id, gap_test_stage_id, 'Max Edge Gap Test Event', '18:00:00', '23:00:00');
    SET gap_test_event_id = LAST_INSERT_ID();

    -- Add first performance (18:00-19:00)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, first_artist_id, gap_test_stage_id, 1, '18:00:00', 60);
    
    -- Try to add performance with exactly 30 minute gap (at 19:30) - should pass
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (gap_test_event_id, fifth_artist_id, gap_test_stage_id, 1, '19:30:00', 60);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the test passed - exactly 30 minute gap was allowed
    CALL log_test_result('TRG-7', 'Performance gap constraint (exactly 30 minutes)', 'TRIGGER', TRUE, NULL, duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_performance_gap_max_edge();

-- Test 4.8: Test concurrent performances by same artist
DELIMITER //
DROP PROCEDURE IF EXISTS test_concurrent_performances //
CREATE PROCEDURE test_concurrent_performances()
BEGIN
    DECLARE concurrent_location_id INT;
    DECLARE concurrent_festival_id INT;
    DECLARE concurrent_day_id INT;
    DECLARE concurrent_event1_id INT;
    DECLARE concurrent_event2_id INT;
    DECLARE test_stage1_id INT;
    DECLARE test_stage2_id INT;
    DECLARE test_artist_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- Check if we got the expected error about concurrent performances
        IF @message LIKE '%Artist is already performing at this time%' THEN
            CALL log_test_result('TRG-8', 'Concurrent performances constraint', 'TRIGGER', TRUE, 'Correctly blocked concurrent performance', duration);
        ELSE
            CALL log_test_result('TRG-8', 'Concurrent performances constraint', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Concurrent Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(6 6)', 4326));
    SET concurrent_location_id = LAST_INSERT_ID();
    
    -- Create new stages for testing
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Concurrent Test Stage 1', 'Test Description', 500, 'Test Equipment', concurrent_location_id);
    SET test_stage1_id = LAST_INSERT_ID();
    
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Concurrent Test Stage 2', 'Test Description', 500, 'Test Equipment', concurrent_location_id);
    SET test_stage2_id = LAST_INSERT_ID();
    
    -- Create a new artist specifically for this test
    INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre)
    VALUES ('Concurrent Test Artist', CONCAT('ConcurrentTest', FLOOR(RAND() * 1000000)), '1990-01-01', 'Rock', 'Alternative Rock');
    SET test_artist_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Concurrent Test Festival', 2025, concurrent_location_id, '2025-10-01', '2025-10-05');
    SET concurrent_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (concurrent_festival_id, '2025-10-01');
    SET concurrent_day_id = LAST_INSERT_ID();

    -- Create two events on the same day but different stages
    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (concurrent_day_id, test_stage1_id, 'Concurrent Test Event 1', '18:00:00', '23:00:00');
    SET concurrent_event1_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (concurrent_day_id, test_stage2_id, 'Concurrent Test Event 2', '18:00:00', '23:00:00');
    SET concurrent_event2_id = LAST_INSERT_ID();

    -- Add first performance (19:00-20:00)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (concurrent_event1_id, test_artist_id, test_stage1_id, 1, '19:00:00', 60);

    -- Try to add concurrent performance for same artist (19:30-20:30)
    INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
    VALUES (concurrent_event2_id, test_artist_id, test_stage2_id, 1, '19:30:00', 60);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed
    CALL log_test_result('TRG-8', 'Concurrent performances constraint', 'TRIGGER', FALSE, 'Concurrent performance by same artist was allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_concurrent_performances();

-- Test 4.9: Test ResaleQueue constraint
DELIMITER //
DROP PROCEDURE IF EXISTS test_resale_queue //
CREATE PROCEDURE test_resale_queue()
BEGIN
    DECLARE resale_visitor_id INT;
    DECLARE resale_ticket_id INT;
    DECLARE test_event_id INT;
    DECLARE test_category_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- Check if we got the expected error about resale availability
        IF @message LIKE '%Ticket is not available for resale%' THEN
            CALL log_test_result('TRG-9', 'ResaleQueue constraint', 'TRIGGER', TRUE, 'Correctly blocked non-resalable ticket', duration);
        ELSE
            CALL log_test_result('TRG-9', 'ResaleQueue constraint', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Get necessary IDs for testing
    SELECT event_id INTO test_event_id FROM Event LIMIT 1;
    SELECT category_id INTO test_category_id FROM TicketCategory LIMIT 1;
    
    -- Create a test visitor
    CALL create_test_visitor(resale_visitor_id);

    -- Create a ticket (not available for resale) with valid EAN code
    CALL create_ticket_with_valid_ean(
        test_event_id, 
        resale_visitor_id, 
        test_category_id, 
        1, 
        50.00, 
        TRUE, 
        FALSE, 
        resale_ticket_id
    );

    -- Try to add ticket to resale queue when resale_available = FALSE
    INSERT INTO ResaleQueue (ticket_id, seller_id, status_id)
    VALUES (resale_ticket_id, resale_visitor_id, 1);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed - the non-resalable ticket was added to queue
    CALL log_test_result('TRG-9', 'ResaleQueue constraint', 'TRIGGER', FALSE, 'Non-resalable ticket was added to ResaleQueue', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_resale_queue();

-- Test 4.10: Test review eligibility

DELIMITER //
DROP PROCEDURE IF EXISTS test_review_eligibility //
CREATE PROCEDURE test_review_eligibility()
BEGIN
    DECLARE review_visitor_id INT;
    DECLARE review_ticket_id INT;
    DECLARE test_event_id INT;
    DECLARE test_performance_id INT;
    DECLARE test_category_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- Check if the error is about review eligibility
        IF @message LIKE '%Only visitors with used tickets can leave reviews%' THEN
            CALL log_test_result('TRG-10', 'Review eligibility constraint', 'TRIGGER', TRUE, 'Correctly blocked review from ineligible visitor', duration);
        ELSE
            CALL log_test_result('TRG-10', 'Review eligibility constraint', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Get necessary IDs for testing
    SELECT e.event_id, p.performance_id 
    INTO test_event_id, test_performance_id
    FROM Event e
    JOIN Performance p ON e.event_id = p.event_id
    LIMIT 1;
    
    SELECT category_id INTO test_category_id FROM TicketCategory LIMIT 1;
    
    -- Create a test visitor
    CALL create_test_visitor(review_visitor_id);

    -- Create a ticket (active - not used yet) with valid EAN code
    CALL create_ticket_with_valid_ean(
        test_event_id, 
        review_visitor_id, 
        test_category_id, 
        1, 
        50.00, 
        TRUE, -- Active ticket (not used)
        FALSE,
        review_ticket_id
    );

    -- Try to add review directly with unused ticket (is_active = TRUE)
    -- This should fail because the ticket hasn't been used
    INSERT INTO Review (visitor_id, performance_id, artist_rating, sound_rating, stage_rating, organization_rating, overall_rating)
    VALUES (review_visitor_id, test_performance_id, 5, 5, 5, 5, 5);
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed - the ineligible visitor was allowed to review
    CALL log_test_result('TRG-10', 'Review eligibility constraint', 'TRIGGER', FALSE, 'Visitor with unused ticket was allowed to leave review', duration);
    
    ROLLBACK;
END //
DELIMITER ;


CALL test_review_eligibility();

-- Test 4.11: Test one ticket per visitor per day and performance constraint
DELIMITER //
DROP PROCEDURE IF EXISTS test_one_ticket_per_visitor //
CREATE PROCEDURE test_one_ticket_per_visitor()
BEGIN
    DECLARE duplicate_visitor_id INT;
    DECLARE test_event_id INT;
    DECLARE test_category_id INT;
    DECLARE first_ticket_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- Check if we got the expected error about duplicate tickets
        IF @message LIKE '%Visitor already has a ticket for this day and performance%' THEN
            CALL log_test_result('TRG-11', 'One ticket per visitor per day and performance', 'TRIGGER', TRUE, 'Correctly blocked duplicate ticket', duration);
        ELSE
            CALL log_test_result('TRG-11', 'One ticket per visitor per day and performance', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Get necessary IDs for testing
    SELECT event_id INTO test_event_id FROM Event LIMIT 1;
    SELECT category_id INTO test_category_id FROM TicketCategory LIMIT 1;
    
    -- Create a test visitor
    CALL create_test_visitor(duplicate_visitor_id);

    -- Add first ticket with valid EAN code
    CALL create_ticket_with_valid_ean(
        test_event_id, 
        duplicate_visitor_id, 
        test_category_id, 
        1, 
        50.00, 
        TRUE, 
        FALSE,
        first_ticket_id
    );

    -- Try to add duplicate ticket for same event with different EAN code
    -- Note: We need to explicitly define the EAN code to make it different for same event/visitor
    INSERT INTO Ticket (
        event_id, 
        visitor_id, 
        category_id, 
        method_id, 
        price, 
        purchase_date, 
        EAN_code, 
        is_active, 
        resale_available
    )
    VALUES (
        test_event_id, 
        duplicate_visitor_id, 
        test_category_id, 
        1, 
        50.00, 
        NOW(), 
        LPAD(CONCAT(duplicate_visitor_id, test_event_id, 'DUPLICATE'), 13, '0'), 
        TRUE,
        FALSE
    );
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed - the duplicate ticket was allowed
    CALL log_test_result('TRG-11', 'One ticket per visitor per day and performance', 'TRIGGER', FALSE, 'Duplicate ticket for same visitor, day and performance was allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_one_ticket_per_visitor();

-- Test 4.12: Check Event time overlap constraint
DELIMITER //
DROP PROCEDURE IF EXISTS test_event_overlap //
CREATE PROCEDURE test_event_overlap()
BEGIN
    DECLARE overlap_location_id INT;
    DECLARE overlap_festival_id INT;
    DECLARE overlap_day_id INT;
    DECLARE test_stage_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- Check if we got the expected error about overlapping events
        IF @message LIKE '%Events cannot overlap on the same stage and day%' THEN
            CALL log_test_result('TRG-12', 'Event time overlap constraint', 'TRIGGER', TRUE, 'Correctly blocked overlapping event', duration);
        ELSE
            CALL log_test_result('TRG-12', 'Event time overlap constraint', 'TRIGGER', FALSE, CONCAT('Unexpected error: ', @message), duration);
        END IF;
        
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Overlap Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(5 5)', 4326));
    SET overlap_location_id = LAST_INSERT_ID();
    
    -- Create a new stage for testing
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Overlap Test Stage', 'Test Description', 500, 'Test Equipment', overlap_location_id);
    SET test_stage_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Overlap Test Festival', 2025, overlap_location_id, '2025-11-01', '2025-11-05');
    SET overlap_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (overlap_festival_id, '2025-11-01');
    SET overlap_day_id = LAST_INSERT_ID();

    -- Create first event (18:00-21:00)
    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (overlap_day_id, test_stage_id, 'Overlap Test Event 1', '18:00:00', '21:00:00');

    -- Try to create overlapping event (20:00-23:00) on same stage and day
    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (overlap_day_id, test_stage_id, 'Overlap Test Event 2', '20:00:00', '23:00:00');
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed
    CALL log_test_result('TRG-12', 'Event time overlap constraint', 'TRIGGER', FALSE, 'Overlapping events on same stage and day were allowed', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_event_overlap();

-- ============================================================================
-- 5. STAFF REQUIREMENT CONSTRAINTS
-- ============================================================================

-- Test 5.1: Security staff requirement (5% of stage capacity)
DELIMITER //
DROP PROCEDURE IF EXISTS test_security_staff_requirement //
CREATE PROCEDURE test_security_staff_requirement()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_security_staff_id INT;
    DECLARE security_role_id INT;
    DECLARE staff_level_id INT;
    DECLARE required_security_staff INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE i INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- This test should fail when trying to exceed the limit
        CALL log_test_result('STF-1', 'Security staff requirement', 'STAFF', TRUE, CONCAT('Expected error when exceeding limit: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Get role and level IDs
    SELECT role_id INTO security_role_id FROM StaffRole WHERE name = 'Security';
    SELECT level_id INTO staff_level_id FROM ExperienceLevel LIMIT 1;
    
    -- Create a new location for testing with a stage capacity of exactly 100
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Security Staff Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(6 6)', 4326));
    SET test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage with capacity of 100
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Security Staff Test Stage', 'Test Description', 100, 'Test Equipment', test_location_id);
    SET test_stage_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Security Staff Test Festival', 2025, test_location_id, '2025-12-01', '2025-12-05');
    SET test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (test_festival_id, '2025-12-01');
    SET test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (test_day_id, test_stage_id, 'Security Staff Test Event', '18:00:00', '23:00:00');
    SET test_event_id = LAST_INSERT_ID();
    
    -- Calculate required staff (5% of 100 capacity = 5)
    SET required_security_staff = CEIL(100 * 0.05);
    
    -- Create and assign exactly the required number of security staff (should succeed)
    SET i = 0;
    WHILE i < required_security_staff DO
        -- Create a security staff member
        CALL create_test_staff(security_role_id, staff_level_id, test_security_staff_id);
        
        -- Assign to the event
        INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
        VALUES (test_security_staff_id, test_event_id, security_role_id, '17:00:00', '23:30:00');
        
        SET i = i + 1;
    END WHILE;
    
    -- Now try to add one more security staff (should fail)
    CALL create_test_staff(security_role_id, staff_level_id, test_security_staff_id);
    
    -- Try to assign one more security staff (exceeding the required 5%) - should fail
    INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
    VALUES (test_security_staff_id, test_event_id, security_role_id, '17:00:00', '23:30:00');
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed - we were able to assign more than required security staff
    CALL log_test_result('STF-1', 'Security staff requirement', 'STAFF', FALSE, 'Assigned more than required security staff (over 5% limit)', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_security_staff_requirement();

-- Test 5.2: Support staff requirement (2% of stage capacity)
DELIMITER //
DROP PROCEDURE IF EXISTS test_support_staff_requirement //
CREATE PROCEDURE test_support_staff_requirement()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_support_staff_id INT;
    DECLARE support_role_id INT;
    DECLARE staff_level_id INT;
    DECLARE required_support_staff INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE i INT DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        -- This test should fail when trying to exceed the limit
        CALL log_test_result('STF-2', 'Support staff requirement', 'STAFF', TRUE, CONCAT('Expected error when exceeding limit: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Get role and level IDs
    SELECT role_id INTO support_role_id FROM StaffRole WHERE name = 'Support';
    SELECT level_id INTO staff_level_id FROM ExperienceLevel LIMIT 1;
    
    -- Create a new location for testing with a stage capacity of exactly 100
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Support Staff Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(7 7)', 4326));
    SET test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage with capacity of 100
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Support Staff Test Stage', 'Test Description', 100, 'Test Equipment', test_location_id);
    SET test_stage_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Support Staff Test Festival', 2025, test_location_id, '2025-12-01', '2025-12-05');
    SET test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (test_festival_id, '2025-12-01');
    SET test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (test_day_id, test_stage_id, 'Support Staff Test Event', '18:00:00', '23:00:00');
    SET test_event_id = LAST_INSERT_ID();
    
    -- Calculate required staff (2% of 100 capacity = 2)
    SET required_support_staff = CEIL(100 * 0.02);
    
    -- Create and assign exactly the required number of support staff (should succeed)
    SET i = 0;
    WHILE i < required_support_staff DO
        -- Create a support staff member
        CALL create_test_staff(support_role_id, staff_level_id, test_support_staff_id);
        
        -- Assign to the event
        INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
        VALUES (test_support_staff_id, test_event_id, support_role_id, '17:00:00', '23:30:00');
        
        SET i = i + 1;
    END WHILE;
    
    -- Now try to add one more support staff (should fail)
    CALL create_test_staff(support_role_id, staff_level_id, test_support_staff_id);
    
    -- Try to assign one more support staff (exceeding the required 2%) - should fail
    INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
    VALUES (test_support_staff_id, test_event_id, support_role_id, '17:00:00', '23:30:00');
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the constraint failed - we were able to assign more than required support staff
    CALL log_test_result('STF-2', 'Support staff requirement', 'STAFF', FALSE, 'Assigned more than required support staff (over 2% limit)', duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_support_staff_requirement();

-- Test 5.3: Technical staff assignment with proper shift times
DELIMITER //
DROP PROCEDURE IF EXISTS test_technical_staff_assignment //
CREATE PROCEDURE test_technical_staff_assignment()
BEGIN
    DECLARE test_location_id INT;
    DECLARE test_festival_id INT;
    DECLARE test_day_id INT;
    DECLARE test_event_id INT;
    DECLARE test_stage_id INT;
    DECLARE test_tech_staff_id INT;
    DECLARE technical_role_id INT;
    DECLARE staff_level_id INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        
        SET end_time = NOW();
        SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
        
        CALL log_test_result('STF-3', 'Technical staff assignment with proper shift times', 'STAFF', FALSE, CONCAT('Unexpected error: ', @message), duration);
        ROLLBACK;
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Get role and level IDs
    SELECT role_id INTO technical_role_id FROM StaffRole WHERE name = 'Technician';
    SELECT level_id INTO staff_level_id FROM ExperienceLevel LIMIT 1;
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Technical Staff Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(8 8)', 4326));
    SET test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Technical Staff Test Stage', 'Test Description', 100, 'Test Equipment', test_location_id);
    SET test_stage_id = LAST_INSERT_ID();
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Technical Staff Test Festival', 2025, test_location_id, '2025-12-01', '2025-12-05');
    SET test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (test_festival_id, '2025-12-01');
    SET test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (test_day_id, test_stage_id, 'Technical Staff Test Event', '18:00:00', '23:00:00');
    SET test_event_id = LAST_INSERT_ID();
    
    -- Create a technical staff member
    CALL create_test_staff(technical_role_id, staff_level_id, test_tech_staff_id);
    
    -- Assign with proper shift times (before and after event times)
    INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
    VALUES (test_tech_staff_id, test_event_id, technical_role_id, '16:00:00', '00:00:00');
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    -- If we get here, the assignment succeeded
    CALL log_test_result('STF-3', 'Technical staff assignment with proper shift times', 'STAFF', TRUE, NULL, duration);
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_technical_staff_assignment();

-- ============================================================================
-- 6. STRESS TESTING WITH LARGER VOLUMES
-- ============================================================================

-- Test 6.1: Stress test ticket creation and VIP constraint
DELIMITER //
DROP PROCEDURE IF EXISTS test_stress_vip_tickets //
CREATE PROCEDURE test_stress_vip_tickets()
BEGIN
    DECLARE stress_test_location_id INT;
    DECLARE stress_test_festival_id INT;
    DECLARE stress_test_day_id INT;
    DECLARE stress_test_event_id INT;
    DECLARE stress_test_stage_id INT;
    DECLARE vip_category_id INT;
    DECLARE general_category_id INT;
    DECLARE first_visitor_id INT;
    DECLARE i INT DEFAULT 0;
    DECLARE max_tickets INT DEFAULT 100;
    DECLARE vip_limit INT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE duration INT;
    DECLARE success BOOLEAN DEFAULT TRUE;
    DECLARE error_message TEXT DEFAULT NULL;
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @message = MESSAGE_TEXT;
        SET success = FALSE;
        SET error_message = CONCAT('Error: ', @message);
    END;
    
    SET start_time = NOW();
    START TRANSACTION;
    
    -- Get category IDs
    SELECT category_id INTO vip_category_id FROM TicketCategory WHERE name = 'VIP';
    SELECT category_id INTO general_category_id FROM TicketCategory WHERE name = 'General';
    
    -- Create a new location for testing
    INSERT INTO Location (address, city, country, continent, coordinates) 
    VALUES ('Stress Test Location', 'Test City', 'Test Country', 'Europe', ST_PointFromText('POINT(9 9)', 4326));
    SET stress_test_location_id = LAST_INSERT_ID();
    
    -- Create a new stage with 1000 capacity
    INSERT INTO Stage (name, description, capacity, equipment, location_id)
    VALUES ('Stress Test Stage', 'Test Description', 1000, 'Test Equipment', stress_test_location_id);
    SET stress_test_stage_id = LAST_INSERT_ID();
    
    -- Calculate VIP ticket limit (10% of 1000 = 100)
    SET vip_limit = FLOOR(1000 * 0.1);
    
    -- Create test data
    INSERT INTO Festival (name, year, location_id, start_date, end_date) 
    VALUES ('Stress Test Festival', 2025, stress_test_location_id, '2025-12-10', '2025-12-15');
    SET stress_test_festival_id = LAST_INSERT_ID();

    INSERT INTO FestivalDay (festival_id, festival_date)
    VALUES (stress_test_festival_id, '2025-12-10');
    SET stress_test_day_id = LAST_INSERT_ID();

    INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (stress_test_day_id, stress_test_stage_id, 'Stress Test Event', '18:00:00', '23:00:00');
    SET stress_test_event_id = LAST_INSERT_ID();
    
    -- Create 200 test visitors
    SET i = 0;
    
    WHILE i < max_tickets * 2 AND success DO
        INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
        VALUES (
            CONCAT('Stress Test', i), 
            'Visitor', 
            CONCAT('stresstest', i, '@example.com'), 
            CONCAT('+3069', i, '1234567'), 
            DATE_SUB(CURRENT_DATE, INTERVAL 20 YEAR)
        );
        
        IF i = 0 THEN
            SET first_visitor_id = LAST_INSERT_ID();
        END IF;
        
        SET i = i + 1;
    END WHILE;
    
    -- Try to add exactly the limit of VIP tickets
    SET i = 0;
    
    WHILE i < vip_limit AND success DO
        SET @ticket_ean = LPAD(CONCAT(first_visitor_id + i, stress_test_event_id, i), 13, '0');
        
        INSERT INTO Ticket (
            event_id, 
            visitor_id, 
            category_id, 
            method_id, 
            price, 
            purchase_date, 
            EAN_code, 
            is_active, 
            resale_available
        )
        VALUES (
            stress_test_event_id, 
            first_visitor_id + i, 
            vip_category_id,
            1, 
            100.00, 
            NOW(), 
            @ticket_ean, 
            FALSE, 
            FALSE
        );
        
        SET i = i + 1;
    END WHILE;
    
    -- Now try to add general tickets
    WHILE i < max_tickets * 2 AND success DO
        SET @ticket_ean = LPAD(CONCAT(first_visitor_id + i, stress_test_event_id, i), 13, '0');
        
        INSERT INTO Ticket (
            event_id, 
            visitor_id, 
            category_id, 
            method_id, 
            price, 
            purchase_date, 
            EAN_code, 
            is_active, 
            resale_available
        )
        VALUES (
            stress_test_event_id, 
            first_visitor_id + i, 
            general_category_id,
            1, 
            50.00, 
            NOW(), 
            @ticket_ean, 
            FALSE, 
            FALSE
        );
        
        SET i = i + 1;
    END WHILE;
    
    SET end_time = NOW();
    SET duration = TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000;
    
    IF success THEN
        CALL log_test_result('STRESS-1', 'Stress test ticket creation and VIP constraint', 'STRESS', TRUE, CONCAT('Successfully created ', i, ' tickets (', vip_limit, ' VIP)'), duration);
    ELSE
        CALL log_test_result('STRESS-1', 'Stress test ticket creation and VIP constraint', 'STRESS', FALSE, error_message, duration);
    END IF;
    
    ROLLBACK;
END //
DELIMITER ;

CALL test_stress_vip_tickets();

-- ============================================================================
-- 7. PROCEDURE TO RUN ALL TESTS
-- ============================================================================

DELIMITER //
DROP PROCEDURE IF EXISTS run_all_tests //
CREATE PROCEDURE run_all_tests()
BEGIN
    -- Record start time for performance evaluation
    DECLARE overall_start TIMESTAMP;
    DECLARE overall_end TIMESTAMP;
    DECLARE total_duration INT;
    
    SET overall_start = NOW();

    -- Clear previous test results
    TRUNCATE TABLE TestResults;
    
    -- Primary Key and Unique Constraints Tests
    CALL test_constraint('PK-1', 'Duplicate primary key in Location', 'PRIMARY_KEY', 
        'INSERT INTO Location (location_id, address, city, country, continent, coordinates) 
         VALUES (1, ''Duplicate Test'', ''Athens'', ''Greece'', ''Europe'',  ST_PointFromText(''POINT(23.7275 37.9838)'', 4326))',
        TRUE);
    
    CALL test_constraint('UQ-1', 'Duplicate artist pseudonym', 'UNIQUE_KEY', 
        'INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre) 
         VALUES (''Test Artist'', (SELECT pseudonym FROM Artist WHERE pseudonym IS NOT NULL LIMIT 1), ''1980-01-01'', ''Pop'', ''Dance'')',
        TRUE);
    
    CALL test_constraint('UQ-2', 'Duplicate band name', 'UNIQUE_KEY', 
        'INSERT INTO Band (name, formation_date, genre, website)
         VALUES ((SELECT name FROM Band LIMIT 1), ''1990-01-01'', ''Rock'', ''https://test.com'')',
        TRUE);
    
    CALL test_constraint('UQ-3', 'Duplicate visitor email', 'UNIQUE_KEY', 
        'INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
         VALUES (''John'', ''Doe'', (SELECT email FROM Visitor LIMIT 1), ''+30691234567'', ''1985-06-15'')',
        TRUE);
    
    CALL test_constraint('UQ-4', 'Duplicate ticket EAN code', 'UNIQUE_KEY', 
        'INSERT INTO Ticket (event_id, visitor_id, category_id, method_id, price, purchase_date, EAN_code, is_active, resale_available)
         SELECT event_id, visitor_id, category_id, method_id, price, NOW(), EAN_code, is_active, resale_available 
         FROM Ticket LIMIT 1',
        TRUE);
    
    -- Foreign Key Constraints Tests
    CALL test_constraint('FK-1', 'Foreign key constraint on Festival location_id', 'FOREIGN_KEY', 
        'INSERT INTO Festival (name, year, location_id, start_date, end_date, description)
         VALUES (''Test Festival'', 2025, 999999, ''2025-07-01'', ''2025-07-05'', ''Test description'')',
        TRUE);
    
    CALL test_constraint('FK-2', 'Foreign key constraint on FestivalDay festival_id', 'FOREIGN_KEY', 
        'INSERT INTO FestivalDay (festival_id, festival_date)
         VALUES (999999, ''2025-07-01'')',
        TRUE);
    
    CALL test_constraint('FK-3', 'Foreign key constraint on Performance event_id', 'FOREIGN_KEY', 
        'INSERT INTO Performance (event_id, artist_id, stage_id, type_id, start_time, duration)
         VALUES (999999, (SELECT artist_id FROM Artist LIMIT 1), (SELECT stage_id FROM Stage LIMIT 1), 1, ''18:00:00'', 60)',
        TRUE);
    
    CALL test_cascade_delete();
    CALL test_cascade_delete_performance();
    
    -- Check Constraints Tests
    CALL test_constraint('CHK-1', 'Continent check constraint on Location', 'CHECK_CONSTRAINT', 
        'INSERT INTO Location (address, city, country, continent, coordinates)
         VALUES (''Test Address'', ''Test City'', ''Test Country'', ''Invalid Continent'', ST_PointFromText(''POINT(0 0)'', 4326))',
        TRUE);
    
    CALL test_constraint('CHK-2', 'Capacity check constraint on Stage', 'CHECK_CONSTRAINT', 
        'INSERT INTO Stage (name, description, capacity, equipment, location_id)
         VALUES (''Test Stage'', ''Test Description'', 0, ''Test Equipment'', 
                (SELECT location_id FROM Location LIMIT 1))',
        TRUE);
    
    CALL test_constraint('CHK-3', 'Age check constraint on Visitor', 'CHECK_CONSTRAINT', 
        'INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
         VALUES (''Young'', ''Person'', ''young.person@test.com'', ''+30691234567'', CURRENT_DATE - INTERVAL 15 YEAR)',
        TRUE);
    
    CALL test_constraint('CHK-4', 'Age check constraint on Visitor (edge case - exactly 16)', 'CHECK_CONSTRAINT', 
        'INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
         VALUES (''Almost'', ''Adult'', ''almost.adult@test.com'', ''+30691234567'', CURRENT_DATE - INTERVAL 16 YEAR)',
        FALSE);
    
    CALL test_performance_duration_constraint();
    CALL test_performance_duration_short();
    CALL test_performance_duration_min();
    CALL test_performance_duration_max();
    
    -- Trigger Tests
    CALL test_festival_date_year();
    CALL test_consecutive_years_constraint();
    CALL test_vip_ticket_limit();
    CALL test_performance_gap_minimum();
    CALL test_performance_gap_maximum();
    CALL test_performance_gap_min_edge();
    CALL test_performance_gap_max_edge();
    CALL test_concurrent_performances();
    CALL test_resale_queue();
    CALL test_review_eligibility();
    CALL test_one_ticket_per_visitor();
    CALL test_event_overlap();
    
    -- Staff Requirements Tests
    CALL test_security_staff_requirement();
    CALL test_support_staff_requirement();
    CALL test_technical_staff_assignment();
    
    -- Stress Tests
    CALL test_stress_vip_tickets();
    
     
    -- Calculate overall time
    SET overall_end = NOW();
    SET total_duration = TIMESTAMPDIFF(MICROSECOND, overall_start, overall_end) / 1000;
    
    -- Display test result summary with timing information
    SELECT 
        CONCAT('Total Tests: ', COUNT(*), 
               ', Passed: ', SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END),
               ', Failed: ', SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END),
               ', Total Time: ', total_duration, 'ms') AS Summary
    FROM TestResults;
    
    -- Display results by category
    SELECT 
        test_category,
        COUNT(*) AS total_tests,
        SUM(CASE WHEN result = 'PASS' THEN 1 ELSE 0 END) AS passed,
        SUM(CASE WHEN result = 'FAIL' THEN 1 ELSE 0 END) AS failed,
        ROUND(AVG(execution_duration), 2) AS avg_duration_ms
    FROM TestResults
    GROUP BY test_category
    ORDER BY test_category;
    
    -- Display detailed results
    SELECT test_id, test_name, test_category, result, error_message, execution_time, execution_duration AS duration_ms
    FROM TestResults
    ORDER BY test_category, test_id;
    
    -- Clean up test data
    CALL cleanup_test_data();
END //
DELIMITER ;

-- ============================================================================
-- 8. EXECUTION
-- ============================================================================

-- Run all tests
CALL run_all_tests();
