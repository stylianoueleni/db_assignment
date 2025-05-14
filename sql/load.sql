-- =================================================================
-- PULSE UNIVERSITY MUSIC FESTIVAL DATABASE - DATA LOADING SCRIPT
-- =================================================================
-- This script populates the database with sample data for testing and development
-- It includes reference data, festivals across multiple years/continents, artists, bands,
-- venues, performances, visitors, staff, tickets, and reviews
-- All data is structured to support the business rules established in install.sql

-- =================================================================
-- REFERENCE DATA TABLES
-- =================================================================
-- Populate lookup tables with fixed values used throughout the database

-- Ticket categories (General, VIP, Backstage)
-- VIP tickets are limited to 10% of stage capacity per business rule
INSERT INTO TicketCategory (name) VALUES ('General'), ('VIP'), ('Backstage');

-- Payment methods available for ticket purchases
INSERT INTO PaymentMethod (name) VALUES ('Credit Card'), ('Debit Card'), ('Bank Transfer');

-- Experience levels for staff classification (five levels from Intern to Expert)
-- Used to track expertise distribution across festival events
INSERT INTO ExperienceLevel (name) VALUES ('Intern'), ('Beginner'), ('Intermediate'), ('Experienced'), ('Expert');

-- Performance types representing the role of performances in festival schedule
-- Determines the sequence of artists at events
INSERT INTO PerformanceType (name) VALUES ('Warm Up'), ('Headline'), ('Special Guest');

-- Staff roles with specific staffing requirement ratios
-- Security: Must cover 5% of total visitors
-- Support: Must cover 2% of total visitors
INSERT INTO StaffRole (name) VALUES ('Technician'), ('Security'), ('Support');

-- Resale status for ticket resale queue system
-- Implements the FIFO queuing mechanism for ticket transfers
INSERT INTO ResaleStatus (name) VALUES ('Available'), ('Sold'), ('Pending');

-- =================================================================
-- GEOGRAPHIC LOCATIONS
-- =================================================================
-- Festival locations across 6 continents with geographic coordinates
-- Each festival takes place at a different location per year
INSERT INTO Location (location_id, address, city, country, continent, coordinates) 
VALUES 
    (1, 'Main Stage', 'Athens', 'Greece', 'Europe', ST_PointFromText('POINT(23.7275 37.9838)', 4326)),
    (2, 'Central Park', 'New York', 'USA', 'North America', ST_PointFromText('POINT(-73.9654 40.7829)', 4326)),
    (3, 'Ipanema Beach', 'Rio de Janeiro', 'Brazil', 'South America', ST_PointFromText('POINT(-43.2026 -22.9837)', 4326)),
    (4, 'Georgiou Street 15', 'Patras', 'Greece', 'Europe', ST_PointFromText('POINT(21.7346 38.2466)', 4326)),
    (5, 'Victoria Park', 'London', 'United Kingdom', 'Europe', ST_PointFromText('POINT(-0.0379 51.5362)', 4326)),
    (6, 'Sydney Opera House', 'Sydney', 'Australia', 'Australia', ST_PointFromText('POINT(151.2153 -33.8568)', 4326)),
    (7, 'Aristotelous Square', 'Thessaloniki', 'Greece', 'Europe', ST_PointFromText('POINT(22.9444 40.6403)', 4326));    

-- =================================================================
-- FESTIVALS SPANNING MULTIPLE YEARS
-- =================================================================
-- 10 annual festivals (2017-2026) with 8 past and 2 future events
-- Each festival spans multiple consecutive days at different global locations
INSERT INTO Festival (name, year, location_id, start_date, end_date, description)
VALUES 
    -- Past festivals (2017-2024)
    ('Athens Main Stage Music Festival', 2017, 1, '2017-07-01', '2017-07-05', 'A spectacular 5-day celebration at Athens Main Stage featuring top Greek rock and folk artists including Vasilis Papakonstantinou, Pyx Lax, and Sokratis Malamas'),
    
    ('New York Sound Experience', 2018, 2, '2018-06-15', '2018-06-20', 'A diverse festival in Central Park featuring Michalis Hatzigiannis, Elena Paparizou, and Onirama blending pop and rock sounds in the heart of Manhattan'),
    
    ('Rio Beach Party', 2019, 3, '2019-08-10', '2019-08-15', 'A vibrant electronic music experience at Ipanema Beach with dance-pop icons like Eleni Foureira, Sakis Rouvas, and Anna Vissi transforming the beach into a dance paradise'),
    
    ('London Park Festival', 2020, 5, '2020-07-01', '2020-07-10', 'An eclectic cultural festival at Victoria Park featuring Giorgos Dalaras, Haris Alexiou, and various art performances celebrating Greek musical heritage'),
    
    ('Patras Nights', 2021, 4, '2021-09-01', '2021-09-05', 'An enchanting series of performances at Georgiou Street, Patras featuring traditional artists along with dramatic interpretations'),
    
    ('Sydney Opera Sounds', 2022, 6, '2022-08-20', '2022-08-25', 'A vibrant music gathering at Sydney Opera House with performances by Locomondo, Panos Kiamos, and Ypogeia Revmata featuring diverse musical genres under the Australian sky'),
    
    ('Thessaloniki Jazz Festival', 2023, 7, '2023-05-20', '2023-05-25', 'A sophisticated jazz festival at Aristotelous Square featuring Mariza Rizou, Xylina Spathia, and international jazz artists creating melodic dialogues in Thessaloniki'),
    
    ('Athens Reunion Festival', 2024, 1, '2024-07-10', '2024-07-20', 'An innovative festival at Athens Main Stage featuring modern Greek artists like Christos Mastoras, Melisses, and WNCfam alongside international dance performances'),
    
    -- Future festivals (2025-2026) for prospective planning and ticket sales
    ('New York World Music Heritage', 2025, 2, '2025-08-01', '2025-08-10', 'An immersive cultural experience at Central Park celebrating Greek musical heritage with Thanos Mikroutsikos, Pantelis Thalassinos, and authentic Cretan music ensembles'),
    
    ('Rio Summer Sounds', 2026, 3, '2026-09-05', '2026-09-10', 'A magical setting at Ipanema Beach hosting artists like Foivos Delivorias, Kitrina Podilata, and Eleonora Zouganeli against the breathtaking backdrop of Rio');

-- =================================================================
-- VENUE STAGES WITH EQUIPMENT SPECIFICATIONS
-- =================================================================
-- 30 stages across all festival locations with varying capacities and technical equipment
-- Each stage has specific details necessary for artist requirements and performance planning
INSERT INTO Stage (stage_id, name, description, capacity, equipment, location_id)
VALUES
-- Athens, Greece (location_id 1)
(1, 'Main Stage Athens', 'The central stage with full lighting and sound setup', 1500, 'Full PA, LED Wall, Moving Lights', 1),
(2, 'Acropolis View Arena', 'Electronic and dance music arena with Acropolis views', 800, 'DJ Booth, Light Show, CO2 Cannons', 1),
(3, 'Odeon of Herodes Atticus', 'Historic stone amphitheater near Acropolis', 5000, 'Custom PA System, Ambient Lighting, Acoustic Enhancement', 1),
(4, 'Technopolis Gazi Stage', 'Industrial venue in former gasworks', 1000, 'Full Digital Mixing, Projection Mapping, LED Lighting', 1),

-- New York, USA (location_id 2)
(5, 'Central Park Main', 'Stage in the heart of Central Park', 500, 'PA System, DJ Booth, Park Lighting', 2),
(6, 'Great Lawn Pavilion', 'Large open-air venue in Central Park', 5000, 'Full Concert Sound System, LED Video Walls, Moving Lights', 2),
(7, 'Bethesda Fountain Plaza', 'Iconic Central Park location for acoustic performances', 300, 'Acoustic-focused PA, Natural Acoustics, Minimal Lighting', 2),
(8, 'Sheep Meadow Soundstage', 'Open field venue for major productions', 8000, 'Line Array Speakers, Digital Mixing, Festival Lighting Rig', 2),

-- Rio de Janeiro, Brazil (location_id 3)
(9, 'Ipanema Sands Stage', 'Dedicated to rock bands on Ipanema Beach', 300, 'Marshall Amps, Drum Kit, PA System', 3),
(10, 'Bossa Nova Corner', 'Cozy stage for jazz and bossa nova ensembles', 80, 'Acoustic PA, Jazz Lighting', 3),
(11, 'Copacabana Beach Main Stage', 'Massive beachfront stage for headliners', 10000, 'Full Concert System, LED Screens, Pyrotechnics', 3),
(12, 'Maracanã Stadium Stage', 'Special stage setup in iconic football stadium', 30000, 'Stadium Sound System, Multiple Video Screens, Full Production', 3),

-- Patras, Greece (location_id 4)
(13, 'Georgiou Square', 'Central square performances in Patras', 600, 'PA, Moving Heads, Video Screen', 4),
(14, 'Rio-Antirio Bridge View', 'Main stage with bridge views', 600, 'Full PA, Light Rig, LED Wall', 4),
(15, 'Roman Odeum of Patras', 'Ancient Roman odeum with natural acoustics', 400, 'Minimal PA, Historic Lighting Design, Acoustic Enhancement', 4),

-- London, UK (location_id 5)
(16, 'Victoria Park Central', 'Main open-air stage in Victoria Park', 700, 'Full PA, Video Wall, Lights', 5),
(17, 'Thames View Platform', 'Unique elevated performances', 400, 'PA, LED Screens', 5),
(18, 'East London Bowl', 'Large-scale amphitheater in Victoria Park', 5000, 'Full Concert System, Lighting Towers, LED Screens', 5),
(19, 'Hackney Meadow', 'Open field stage for major headliners', 10000, 'Festival Sound System, Delay Towers, Full Production Rig', 5),

-- Sydney, Australia (location_id 6)
(20, 'Sydney Opera Steps', 'Main festival stage at the Opera House steps', 1000, 'Full PA, LED Wall, Stage Effects', 6),
(21, 'Harbour Bridge View', 'Stage with Harbour Bridge views', 200, 'PA System, Light Show', 6),
(22, 'Opera House Forecourt', 'Large open space in front of Opera House', 5000, 'Line Array PA, Automated Lighting, Video Walls', 6),
(23, 'Sydney Cove Floating Stage', 'Floating platform in Sydney Harbour', 300, 'Marine-grade PA, Waterproof Lighting, Projection', 6),

-- Thessaloniki, Greece (location_id 7)
(24, 'Aristotelous Plaza', 'Main stage at Aristotelous Square', 400, 'PA, Light Show, LED Screen', 7),
(25, 'White Tower Arena', 'Open-air venue near iconic White Tower', 1200, 'Full Concert PA, Lighting Rig, LED Screens', 7),
(26, 'Rotunda Ancient Stage', 'Performance space at historical monument', 300, 'Heritage-approved Sound System, Architectural Lighting', 7),
(27, 'Ladadika District Stage', 'Intimate venue in historic quarter', 150, 'Small Format PA, Ambient Lighting, Street Performance Setup', 7),
(28, 'Nea Paralia Boardwalk', 'Waterfront stage along renovated seafront', 800, 'Weather-resistant Sound System, Waterfront Lighting', 7),
(29, 'ANO POLI Terrace', 'Elevated stage in Upper Town with city views', 250, 'Compact PA System, Mood Lighting, Acoustic Treatments', 7),
(30, 'Syntagma Square Stage', 'Central Athens stage for major performances', 2000, 'Full PA, LED Screens, Computer-controlled Lighting', 1);

-- =================================================================
-- ARTISTS TABLE POPULATION
-- =================================================================
-- 39 solo artists from diverse musical genres, ages, and backgrounds
-- Each artist has a complete profile including birthdate, genre classification, and online presence
INSERT INTO Artist (name, pseudonym, birthdate, genre, subgenre, website, instagram) 
VALUES
    ('Giannis Varthakouris', 'Parios', '1946-03-08', 'Folk', 'Laiko', NULL, NULL),
    ('Anna Vissi', NULL, '1957-12-20', 'Pop', 'Dance Pop', 'https://www.annavissilive.com', 'https://instagram.com/annavissiofficial'),
    ('Miltos Paschalidis', NULL, '1969-07-31', 'Rock', 'Greek Rock', NULL, 'https://instagram.com/miltosofficial'),
    ('Haris Alexiou', NULL, '1950-12-27', 'Art/Popular', 'Entekhno', NULL, NULL),
    ('Nikos Vertis', NULL, '1976-08-21', 'Folk', 'Modern Laiko', 'https://www.nikosvertis.com', 'https://instagram.com/nikosvertis'),
    ('Eleonora Zouganeli', NULL, '1983-02-10', 'Art/Popular', 'Entekhno', 'https://www.eleonorazouganeli.gr', 'https://instagram.com/eleonorazouganeli'),
    ('Giorgos Mazonakis', 'Mazo', '1972-03-04', 'Folk', 'Modern Laiko', 'https://www.georgemazonakis.gr', 'https://instagram.com/georgemazonakis'),
    ('Alexis Lanaras', 'Lex', '1984-09-25', 'Hip Hop/Rap', 'Greek Rap', 'https://www.lextgk.gr', 'https://instagram.com/lextgk'),
    ('Vasilis Papakonstantinou', 'Papakonstantinou', '1950-06-21', 'Rock', 'Greek Rock', 'https://www.vasilisp.com', NULL),
    ('Dionysis Savvopoulos', NULL, '1944-12-02', 'Art/Popular', 'Entekhno', NULL, NULL),
    ('Kaiti Garbi', NULL, '1961-06-08', 'Pop', 'Laiko Pop', 'https://www.kaitigarbi.net', 'https://instagram.com/kaitigarbi'),
    ('Michalis Hatzigiannis', NULL, '1978-11-05', 'Pop', 'Soft Pop', 'https://www.michalishatzigiannis.com', 'https://instagram.com/mhatzigiannis'),
    ('Evridiki Theokleous','Evridiki', '1968-05-25', 'Pop', 'Rock Pop', 'https://www.evridiki.gr', 'https://instagram.com/evridikiofficial'),
    ('Despina Malea', 'Vandi', '1969-07-22', 'Pop', 'Dance Laiko', 'https://www.despinavandi.gr', 'https://instagram.com/desp1navandi'),
    ('Pantelis Thalassinos', NULL, '1958-06-11', 'Art/Popular', 'Folk Rock', NULL, NULL),
    ('Lefteris Pantazis', 'Lepa', '1955-03-27', 'Folk', 'Laiko', NULL, 'https://instagram.com/lepa_official'),
    ('Panos Kiamos', NULL, '1975-10-04', 'Folk', 'Modern Laiko', 'https://www.panoskiamos.gr', 'https://instagram.com/panoskiamos_official'),
    ('Natasa Theodoridou', NULL, '1970-10-24', 'Folk', 'Modern Laiko', 'https://www.natasatheodoridou.gr', 'https://instagram.com/natasatheodoridou'),
    ('Antonis Paschalidi', 'Remos', '1970-06-19', 'Folk', 'Modern Laiko', 'https://www.remosmusic.com', 'https://instagram.com/aremovic'),
    ('Stelios Rokkos', NULL, '1965-02-11', 'Rock', 'Folk Rock', NULL, 'https://instagram.com/steliosrokkos'),
    ('Paschalis Terzis', NULL, '1949-04-24', 'Folk', 'Laiko', NULL, NULL),
    ('Foivos Delivorias', NULL, '1973-09-29', 'Art/Popular', 'Entekhno', NULL, NULL),
    ('Thodoris Ferris', 'Ferris', '1982-11-24', 'Pop', 'Pop Rock', NULL, 'https://instagram.com/thodorisferris'),
    ('Anastasios Rouvas', 'Saksi', '1972-01-05', 'Rock/Pop', 'Dance Rock', NULL, 'https://instagram.com/sakisrouvas'),
    ('Elena Paparizou', 'Paparizou', '1982-01-31', 'Pop', 'Dance Pop', NULL, 'https://instagram.com/helenapaparizouofficial'),
    ('Giorgos Dalaras', NULL, '1949-09-29', 'Art/Popular', 'Entekhno', NULL, 'https://instagram.com/dalaras_george_official'),
    ('Entela Fureraj', 'Eleni Foureira', '1987-03-07', 'Pop', 'Dance Pop', NULL, 'https://instagram.com/foureira'),
    ('Mariza Rizou', NULL, '1986-01-01', 'Jazz', 'Indie Jazz', 'https://www.marizarizou.com', 'https://instagram.com/marizarizou'),
    ('Thodoris Marantinis', NULL, '1978-06-16', 'Pop', 'Pop Rock', NULL, 'https://instagram.com/thodorismarantinis_official'),
    ('Thanos Mikroutsikos', NULL, '1947-04-13', 'Art/Popular', 'Political Song', NULL, NULL),
    ('Babis Stokas', NULL, '1968-03-08', 'Entekhno/Rock', 'Greek Rock', NULL, 'https://instagram.com/bstokas'),
    ('Sokratis Malamas', NULL, '1957-09-29', 'Art/Popular', 'Folk Rock', NULL, 'https://instagram.com/sokratismalamas'),
    ('Christos Thivaios', NULL, '1963-06-07', 'Art/Popular', 'Entekhno', NULL, 'https://instagram.com/christos.thivaios'),
    ('Christos Mastoras', 'Mastoras', '1986-11-14', 'Pop', 'Pop Rock', NULL, 'https://instagram.com/xmastoras'),
    ('Nikos Portokaloglou', NULL, '1967-01-01', 'Alternative Rock', 'Entekhno Rock', NULL, 'https://instagram.com/nikosportokaglou'),
    ('Markos Koumaris', NULL, '1977-03-07', 'Hip Hop/Rap', 'Ska/Reggae Fusion', NULL, NULL),
    ('Maria-Sophia', 'Marseaux', '2001-05-09', 'Pop', 'Synthpop/Electropop', NULL, 'https://instagram.com/marseaux.wnc'),
    ('Giorgos Kakossaios', NULL, '2000-02-19', 'Pop', 'Laiko', NULL, 'https://instagram.com/giorgos_kakossaios'),
    ('Anastasia-Dimitra', 'Anastasia', '2003-05-018', 'Pop', 'Dance Pop', NULL, 'https://instagram.com/imanastasia_official');

-- =================================================================
-- BANDS TABLE POPULATION
-- =================================================================
-- 14 bands of various genres and formation dates
-- Each band has unique identifier, name, formation date, genre, and website if available
INSERT INTO Band (name, formation_date, genre, website)
VALUES 
    ('Pyx Lax', '1989-01-01', 'Alternative Rock', 'https://www.pyxlax.gr'),
    ('Onirama', '2000-01-01', 'Alternative Rock', 'https://www.onirama.gr'),
    ('Melisses', '2008-01-01', 'Pop Rock', 'https://instagram.com/melisses_official'),
    ('Trypes', '1983-01-01', 'Rock', NULL),
    ('Ble', '1996-01-01', 'Rock', 'https://instagram.com/mpleofficial'),
    ('Ypogeia Revmata', '1992-01-01', 'Rock', 'https://instagram.com/ypogeia.revmata'),
    ('Termites', '1980-01-01', 'Rock', NULL),
    ('Magic De Spell', '1980-01-01', 'New Wave', NULL),
    ('Xylina Spathia', '1993-01-01', 'Jazz Fusion', NULL),
    ('Kitrina Podilata', '2000-01-01', 'Rock', 'https://www.kitrinapodilata.gr'),
    ('Active Member', '1992-01-01', 'Hip Hop', 'https://instagram.com/active_member_official'),
    ('Locomondo', '2004-01-01', 'Reggae/Ska', 'https://www.locomondo.gr'),
    ('Antique', '1999-01-01', 'Pop', NULL),
    ('WNCfam', '2011-01-01', 'Hip Hop/Rap', 'www.greekwaves.com');

-- =================================================================
-- ARTIST-BAND RELATIONSHIPS
-- =================================================================
-- Mapping between artists and the bands they belong to
-- Demonstrates many-to-many relationship between artists and bands
INSERT INTO Artist_Band (artist_id, band_id, join_date)
VALUES
    -- Key artists and their band associations with join dates
    -- Pyx Lax
    ((SELECT artist_id FROM Artist WHERE name = 'Babis Stokas'), 
     (SELECT band_id FROM Band WHERE name = 'Pyx Lax'), '1989-01-01'),
    
    -- Antique
    ((SELECT artist_id FROM Artist WHERE name = 'Elena Paparizou'), 
     (SELECT band_id FROM Band WHERE name = 'Antique'), '1999-01-01'),

    -- Locomondo
    ((SELECT artist_id FROM Artist WHERE name = 'Markos Koumaris'), 
     (SELECT band_id FROM Band WHERE name = 'Locomondo'), '2004-01-01'),

    -- Melisses
    ((SELECT artist_id FROM Artist WHERE name = 'Christos Mastoras'), 
     (SELECT band_id FROM Band WHERE name = 'Melisses'), '2008-01-01'),

    -- Onirama
    ((SELECT artist_id FROM Artist WHERE name = 'Thodoris Marantinis'), 
     (SELECT band_id FROM Band WHERE name = 'Onirama'), '2000-01-01'),

     -- WNCfam
    ((SELECT artist_id FROM Artist WHERE name = 'Maria-Sophia'), 
     (SELECT band_id FROM Band WHERE name = 'WNCfam'), '2011-01-01');

-- =================================================================
-- VISITOR PROFILES
-- =================================================================
-- 200 distinct visitors with complete profile information
-- All visitors are at least 16 years old (as per business rule)
-- Email addresses are unique and valid format
INSERT INTO Visitor (first_name, last_name, email, phone, birthdate)
VALUES 
    ('Maria', 'Papadopoulos', 'maria.papadopoulos@gmail.com', '+306912345679', '1990-05-15'),
    ('Dimitris', 'Ioannidis', 'dimitris.ioan@gmail.com', '+306957345672', '1988-11-22'),
    ('Eleni', 'Georgiou', 'eleni.georgiou@gmail.com', '+306912365673', '2000-03-10'),
    ('Nikos', 'Kostas', 'nikos.kostas@gmail.com', '+306912565674', '1995-07-19'),
    ('Sophia', 'Antoniou', 'sophia.antoniou@gmail.com', '+306919045675', '1987-09-30'),
    ('Eleni', 'Stylianou', 'elenistylianou@gmail.com', '+306917845675', '2003-10-09'),
    ('Maria', 'Antoniou', 'maria.antoniou@gmail.com', '+306942345675', '1989-12-28'),
    ('Giannis', 'Papadakis', 'giannis.papadakis@gmail.com', '+306914145676', '1999-04-12'),
    ('Katerina', 'Vasileiou', 'katerina.vas@gmail.com', '+306912945677', '2001-08-25'),
    ('Panagiotis', 'Nikolaou', 'panagiotis.nikol@gmail.com', '+306952345678', '1993-12-05'),
    ('Christina', 'Petrou', 'christina.p@gmail.com', '+306952344510', '1985-02-18'),
    ('Stavros', 'Dimitriou', 'stavros.dimi@gmail.com', '+306976345680', '2002-06-03'),
    ('Maria', 'Papadopoulos', 'maria.papadopoulos1@gmail.com', '+306912345671', '1990-05-15'),
    ('Dimitris', 'Ioannidis', 'dimitris.ioannidis2@gmail.com', '+306900000001', '1988-11-22'),
    ('Eleni', 'Georgiou', 'eleni.georgiou3@gmail.com', '+306901234567', '2000-03-10'),
    ('Nikos', 'Kostas', 'nikos.kostas4@gmail.com', '+306902468135', '1995-07-19'),
    ('Sophia', 'Antoniou', 'sophia.antoniou5@gmail.com', '+306903579246', '1987-09-30'),
    ('Giannis', 'Papadakis', 'giannis.papadakis6@gmail.com', '+306904444444', '1999-04-12'),
    ('Katerina', 'Vasileiou', 'katerina.vasileiou7@gmail.com', '+306905678901', '2001-08-25'),
    ('Panagiotis', 'Nikolaou', 'panagiotis.nikolaou8@gmail.com', '+306912345682', '1993-12-05'),
    ('Christina', 'Petrou', 'christina.petrou9@gmail.com', '+306906969696', '1985-02-18'),
    ('Stavros', 'Dimitriou', 'stavros.dimitriou10@gmail.com', '+306912345681', '2002-06-30'),
    ('Christina', 'Triantafyllou', 'christina.triantafyllou11@gmail.com', '+306929644546', '2000-08-04'),
    ('Theodoros', 'Triantafyllou', 'theodoros.triantafyllou12@gmail.com', '+306955504436', '1999-02-23'),
    ('Sophia', 'Savvidis', 'sophia.savvidis13@gmail.com', '+306910702778', '1963-09-30'),
    ('George', 'Savvidis', 'george.savvidis14@gmail.com', '+306963810802', '1987-05-30'),
    ('George', 'Alexopoulos', 'george.alexopoulos15@gmail.com', '+306978213164', '1997-03-26'),
    ('Dimitris', 'Vasileiou', 'dimitris.vasileiou16@gmail.com', '+306963593673', '2005-06-27'),
    ('Maria', 'Nikolaou', 'maria.nikolaou17@gmail.com', '+306991577831', '1962-01-18'),
    ('Alexandros', 'Triantafyllou', 'alexandros.triantafyllou18@gmail.com', '+306946180348', '1978-03-17'),
    ('Dimitris', 'Vasileiou', 'dimitris.vasileiou19@gmail.com', '+306932391052', '1993-08-05'),
    ('Nikos', 'Savvidis', 'nikos.savvidis20@gmail.com', '+306937520296', '1973-05-29'),
    ('Georgia', 'Kostas', 'georgia.kostas21@gmail.com', '+306916922341', '1960-06-24'),
    ('Athina', 'Ioannidis', 'athina.ioannidis22@gmail.com', '+306965121405', '1969-08-12'),
    ('Andreas', 'Ioannidis', 'aandreas.ioannidis@gmail.com', '+306965122405', '2000-08-02'),
    ('George', 'Papadopoulos', 'george.papadopoulos23@gmail.com', '+306949587790', '2004-09-21'),
    ('Christina', 'Vasileiou', 'christina.vasileiou24@gmail.com', '+306946562444', '1988-12-18'),
    ('Theodoros', 'Michailidis', 'theodoros.michailidis25@gmail.com', '+306967832094', '2003-04-11'),
    ('Eva', 'Michailidis', 'eva.michailidis26@gmail.com', '+306972105772', '1984-12-19'),
    ('Stavros', 'Nikolaou', 'stavros.nikolaou27@gmail.com', '+306941720360', '1978-08-12'),
    ('Panagiotis', 'Georgiou', 'panagiotis.georgiou28@gmail.com', '+306942824325', '1980-01-14'),
    ('Maria', 'Alexopoulos', 'maria.alexopoulos29@gmail.com', '+306941220214', '2004-08-31'),
    ('Theodoros', 'Antoniou', 'theodoros.antoniou30@gmail.com', '+306977767288', '1984-11-26'),
    ('Anna', 'Dimitriou', 'anna.dimitriou31@gmail.com', '+306925709228', '1980-12-09'),
    ('Ioannis', 'Makris', 'ioannis.makris32@gmail.com', '+306986961560', '1966-08-06'),
    ('Athina', 'Papageorgiou', 'athina.papageorgiou33@gmail.com', '+306983324546', '1960-02-15'),
    ('Giannis', 'Nikolaou', 'giannis.nikolaou34@gmail.com', '+306999933630', '1990-07-03'),
    ('Giannis', 'Kara', 'giannis.kara35@gmail.com', '+306970644200', '1972-09-10'),
    ('Sophia', 'Georgiou', 'sophia.georgiou36@gmail.com', '+306994675186', '1974-11-02'),
    ('Eleni', 'Papageorgiou', 'eleni.papageorgiou37@gmail.com', '+306960662815', '2006-04-29'),
    ('Panagiotis', 'Michailidis', 'panagiotis.michailidis38@gmail.com', '+306933815511', '1976-04-19'),
    ('Sophia', 'Ioannidis', 'sophia.ioannidis39@gmail.com', '+306945912536', '1991-02-06'),
    ('Eva', 'Nikolaou', 'eva.nikolaou40@gmail.com', '+306987587253', '1988-09-02'),
    ('Maria', 'Kostas', 'maria.kostas41@gmail.com', '+306912283351', '2008-01-02'),
    ('Alexandros', 'Angelopoulos', 'alexandros.angelopoulos42@gmail.com', '+306945457450', '1966-03-14'),
    ('Anna', 'Savvidis', 'anna.savvidis43@gmail.com', '+306966783215', '1965-04-12'),
    ('Sophia', 'Kara', 'sophia.kara44@gmail.com', '+306948332573', '2004-04-10'),
    ('Georgia', 'Kara', 'georgia.kara45@gmail.com', '+306945803293', '1997-07-14'),
    ('Nikos', 'Papadakis', 'nikos.papadakis46@gmail.com', '+306951816322', '1962-12-05'),
    ('Nikos', 'Papadakis', 'nikos.papadakis47@gmail.com', '+306931055227', '1979-01-21'),
    ('Dimitris', 'Papadopoulos', 'dimitris.papadopoulos48@gmail.com', '+306995210067', '1965-08-06'),
    ('Nikos', 'Pappas', 'nikos.pappas49@gmail.com', '+306936891918', '1982-10-07'),
    ('Dora', 'Ioannidis', 'dora.ioannidis50@gmail.com', '+306991888679', '1965-09-01'),
    ('Eleni', 'Spanou', 'eleni.spanou51@gmail.com', '+306911223311', '1992-04-17'),
    ('Giorgos', 'Kapsalis', 'giorgos.kapsalis52@gmail.com', '+306917843211', '1986-11-05'),
    ('Ioanna', 'Lazarou', 'ioanna.lazarou53@gmail.com', '+306914889022', '1990-07-21'),
    ('Kostas', 'Diamantis', 'kostas.diamantis54@gmail.com', '+306913008944', '1981-12-13'),
    ('Maria', 'Xaralampidou', 'maria.xaralampidou55@gmail.com', '+306919335599', '2003-02-03'),
    ('Dimitra', 'Tsoukalas', 'dimitra.tsoukalas56@gmail.com', '+306912202345', '1997-09-09'),
    ('Nikos', 'Kalliris', 'nikos.kalliris57@gmail.com', '+306916778812', '1985-06-30'),
    ('Eirini', 'Makropoulos', 'eirini.makropoulos58@gmail.com', '+306910223344', '1978-10-01'),
    ('Alexandros', 'Galanis', 'alexandros.galanis59@gmail.com', '+306918112211', '1999-08-15'),
    ('Anna', 'Voulgaris', 'anna.voulgaris60@gmail.com', '+306911112233', '1968-03-28'),
    ('Stelios', 'Petridis', 'stelios.petridis61@gmail.com', '+306915678912', '1991-05-12'),
    ('Vasiliki', 'Kourtis', 'vasiliki.kourtis62@gmail.com', '+306916443322', '2002-01-06'),
    ('Giannis', 'Zacharopoulos', 'giannis.zacharopoulos63@gmail.com', '+306914556633', '1989-10-20'),
    ('Sofia', 'Tzortzis', 'sofia.tzortzis64@gmail.com', '+306913399991', '1993-11-30'),
    ('Christos', 'Andreou', 'christos.andreou65@gmail.com', '+306917844221', '2000-04-05'),
    ('Foteini', 'Laskari', 'foteini.laskari66@gmail.com', '+306919876543', '1987-12-17'),
    ('Panagiotis', 'Verginis', 'panagiotis.verginis67@gmail.com', '+306914003322', '1975-02-24'),
    ('Dionysis', 'Markakis', 'dionysis.markakis68@gmail.com', '+306912334455', '1996-09-11'),
    ('Areti', 'Manousaki', 'areti.manousaki69@gmail.com', '+306916009988', '1982-06-01'),
    ('Manolis', 'Papathanasiou', 'manolis.papathanasiou70@gmail.com', '+306917777666', '1973-07-29'),
    ('Zoi', 'Daskalaki', 'zoi.daskalaki71@gmail.com', '+306919919919', '1995-11-04'),
    ('Theodora', 'Kefalogianni', 'theodora.kefalogianni72@gmail.com', '+306915556644', '2004-12-25'),
    ('Lefteris', 'Raptis', 'lefteris.raptis73@gmail.com', '+306918765432', '1980-05-18'),
    ('Chara', 'Nikou', 'chara.nikou74@gmail.com', '+306912300400', '1994-10-10'),
    ('Petros', 'Triantafyllidis', 'petros.triantafyllidis75@gmail.com', '+306911414141', '1988-04-22'),
    ('Aggeliki', 'Katsarou', 'aggeliki.katsarou76@gmail.com', '+306917223344', '1970-06-06'),
    ('Spyros', 'Deligiannis', 'spyros.deligiannis77@gmail.com', '+306910001122', '1998-08-03'),
    ('Vaggelis', 'Karapanos', 'vaggelis.karapanos78@gmail.com', '+306916121212', '1965-01-19'),
    ('Despina', 'Mavrommati', 'despina.mavrommati79@gmail.com', '+306919999000', '1979-02-27'),
    ('Antonis', 'Grigoriadis', 'antonis.grigoriadis80@gmail.com', '+306912888777', '1990-06-06'),
    ('Artemis', 'Karaoli', 'artemis.karaoli81@gmail.com', '+306914545454', '1992-12-12'),
    ('Christos', 'Manetas', 'christos.manetas82@gmail.com', '+306918181818', '2001-11-07'),
    ('Ioanna', 'Giannakopoulou', 'ioanna.giannakopoulou83@gmail.com', '+306910987654', '1976-03-13'),
    ('Michalis', 'Sarris', 'michalis.sarris84@gmail.com', '+306912222333', '1983-01-31'),
    ('Eleni', 'Koutouki', 'eleni.koutouki85@gmail.com', '+306916654321', '1997-07-07'),
    ('Kostas', 'Papamichail', 'kostas.papamichail86@gmail.com', '+306915121212', '1984-08-09'),
    ('Maria', 'Tsekeridou', 'maria.tsekeridou87@gmail.com', '+306911232323', '1991-09-14'),
    ('Niki', 'Anastasiou', 'niki.anastasiou88@gmail.com', '+306913432112', '2005-10-02'),
    ('Stratos', 'Kanelopoulos', 'stratos.kanelopoulos89@gmail.com', '+306917001122', '1977-01-01'),
    ('Iro', 'Vrettou', 'iro.vrettou90@gmail.com', '+306919191919', '1986-12-03'),
    ('Lydia', 'Alexiou', 'lydia.alexiou91@gmail.com', '+306912121212', '1999-03-08'),
    ('Filippos', 'Tzemos', 'filippos.tzemos92@gmail.com', '+306913443322', '1981-02-21'),
    ('Melina', 'Katsigiannis', 'melina.katsigiannis93@gmail.com', '+306918888777', '1972-05-16'),
    ('Apostolos', 'Dimou', 'apostolos.dimou94@gmail.com', '+306914747474', '1993-06-02'),
    ('Zacharias', 'Ninou', 'zacharias.ninou95@gmail.com', '+306910505050', '1969-09-23'),
    ('Olga', 'Marinou', 'olga.marinou96@gmail.com', '+306919393939', '2002-02-22'),
    ('Kyriakos', 'Savvas', 'kyriakos.savvas97@gmail.com', '+306917676767', '1985-11-16'),
    ('Thaleia', 'Oikonomou', 'thaleia.oikonomou98@gmail.com', '+306911111222', '1971-12-30'),
    ('Iasonas', 'Lykourgos', 'iasonas.lykourgos99@gmail.com', '+306915555444', '1996-01-27'),
    ('Angeliki', 'Kritikou', 'angeliki.kritikou100@gmail.com', '+306916969696', '1989-03-05'),
    ('Nektarios', 'Samaras', 'nektarios.samaras101@gmail.com', '+306911123456', '1980-10-11'),
    ('Vasiliki', 'Tsiara', 'vasiliki.tsiara102@gmail.com', '+306917882345', '1992-03-25'),
    ('Fotis', 'Kapsalis', 'fotis.kapsalis103@gmail.com', '+306916442233', '1979-05-06'),
    ('Anastasia', 'Koutra', 'anastasia.koutra104@gmail.com', '+306912667788', '1987-09-12'),
    ('Katerina', 'Douka', 'katerina.douka105@gmail.com', '+306919999123', '1993-01-18'),
    ('Giorgos', 'Tsatsakis', 'giorgos.tsatsakis106@gmail.com', '+306918118811', '1986-12-04'),
    ('Thodoris', 'Polyzos', 'thodoris.polyzos107@gmail.com', '+306915884422', '1990-07-02'),
    ('Evi', 'Karypidou', 'evi.karypidou108@gmail.com', '+306911345678', '1972-08-30'),
    ('Andreas', 'Skarlatos', 'andreas.skarlatos109@gmail.com', '+306917777222', '1985-06-24'),
    ('Eleni', 'Avgeri', 'eleni.avgeri110@gmail.com', '+306910889900', '1996-04-11'),
    ('Giannis', 'Loukas', 'giannis.loukas111@gmail.com', '+306913134343', '2001-11-28'),
    ('Sofia', 'Drakou', 'sofia.drakou112@gmail.com', '+306914565656', '1994-03-08'),
    ('Christina', 'Magda', 'christina.magda113@gmail.com', '+306915909090', '2000-10-16'),
    ('Panagiotis', 'Vergos', 'panagiotis.vergos114@gmail.com', '+306918787878', '1970-12-09'),
    ('Maria', 'Karagianni', 'maria.karagianni115@gmail.com', '+306911919191', '1982-07-07'),
    ('Stefanos', 'Fasoulas', 'stefanos.fasoulas116@gmail.com', '+306919101010', '1995-08-13'),
    ('Alexia', 'Nikou', 'alexia.nikou117@gmail.com', '+306913434343', '2002-05-04'),
    ('Giorgos', 'Dimas', 'giorgos.dimas118@gmail.com', '+306912111111', '1976-09-17'),
    ('Ifigeneia', 'Tzani', 'ifigeneia.tzani119@gmail.com', '+306916343434', '1989-01-03'),
    ('Lefteris', 'Siagas', 'lefteris.siagas120@gmail.com', '+306918232323', '1997-04-21'),
    ('Margarita', 'Xenou', 'margarita.xenou121@gmail.com', '+306910567567', '1981-06-30'),
    ('Aris', 'Poulos', 'aris.poulos122@gmail.com', '+306915112233', '2004-02-14'),
    ('Natalia', 'Chatzis', 'natalia.chatzis123@gmail.com', '+306914000001', '1999-03-29'),
    ('Michalis', 'Gavrilis', 'michalis.gavrilis124@gmail.com', '+306911777666', '1968-11-23'),
    ('Niki', 'Deligianni', 'niki.deligianni125@gmail.com', '+306917727272', '1991-12-27'),
    ('Petros', 'Sakellarios', 'petros.sakellarios126@gmail.com', '+306910333444', '2005-09-06'),
    ('Eleni', 'Stogianni', 'eleni.stogianni127@gmail.com', '+306912445566', '1983-10-02'),
    ('Antonis', 'Skourtis', 'antonis.skourtis128@gmail.com', '+306918554433', '1971-07-19'),
    ('Dafni', 'Karra', 'dafni.karra129@gmail.com', '+306911888777', '1998-06-11'),
    ('Christos', 'Ntinos', 'christos.ntinos130@gmail.com', '+306919292929', '1974-03-05'),
    ('Andriana', 'Papadima', 'andriana.papadima131@gmail.com', '+306910191919', '1988-02-02'),
    ('Stathis', 'Maltezos', 'stathis.maltezos132@gmail.com', '+306914949494', '1993-05-15'),
    ('Evelina', 'Rizou', 'evelina.rizou133@gmail.com', '+306916000111', '1977-12-21'),
    ('Spyros', 'Kyriazis', 'spyros.kyriazis134@gmail.com', '+306917898989', '1984-08-07'),
    ('Nefeli', 'Skourtanioti', 'nefeli.skourtanioti135@gmail.com', '+306911112222', '2003-01-09'),
    ('Dionysis', 'Kalogeropoulos', 'dionysis.kalogeropoulos136@gmail.com', '+306912323232', '1965-04-04'),
    ('Christina', 'Panagopoulou', 'christina.panagopoulou137@gmail.com', '+306918181717', '1992-11-20'),
    ('Stelios', 'Voutsinas', 'stelios.voutsinas138@gmail.com', '+306914474747', '1973-10-31'),
    ('Katerina', 'Zafeiriou', 'katerina.zafeiriou139@gmail.com', '+306917454545', '1994-07-26'),
    ('Aggelos', 'Vasiliou', 'aggelos.vasiliou140@gmail.com', '+306915565656', '1980-06-22'),
    ('Smaragda', 'Lambrou', 'smaragda.lambrou141@gmail.com', '+306912909090', '2000-11-19'),
    ('Ilias', 'Vrettos', 'ilias.vrettos142@gmail.com', '+306919494949', '1987-01-25'),
    ('Melina', 'Zarifi', 'melina.zarifi143@gmail.com', '+306910121212', '1996-08-05'),
    ('Charalampos', 'Tzavaras', 'charalampos.tzavaras144@gmail.com', '+306916343433', '1979-02-28'),
    ('Eleni', 'Theodoridou', 'eleni.theodoridou145@gmail.com', '+306911232323', '1990-03-15'),
    ('Alexis', 'Roumeliotis', 'alexis.roumeliotis146@gmail.com', '+306917111111', '1986-05-10'),
    ('Zoi', 'Papadogianni', 'zoi.papadogianni147@gmail.com', '+306912888000', '1975-09-01'),
    ('Stratos', 'Filippou', 'stratos.filippou148@gmail.com', '+306918484848', '2002-10-23'),
    ('Vivi', 'Andreadou', 'vivi.andreadou149@gmail.com', '+306910909090', '1995-12-14'),
    ('Kostas', 'Marinos', 'kostas.marinos150@gmail.com', '+306914141414', '1982-04-26'),
    ('Eleni', 'Kalogirou', 'eleni.kalogirou151@gmail.com', '+306910101515', '1984-09-14'),
    ('Giannis', 'Sotiropoulos', 'giannis.sotiropoulos152@gmail.com', '+306913456789', '1991-03-22'),
    ('Maria', 'Vogiatzis', 'maria.vogiatzis153@gmail.com', '+306918765432', '1973-07-18'),
    ('Andreas', 'Maniatis', 'andreas.maniatis154@gmail.com', '+306914567890', '1985-12-11'),
    ('Katerina', 'Argyriou', 'katerina.argyriou155@gmail.com', '+306919876543', '1997-02-08'),
    ('Petros', 'Mitropoulos', 'petros.mitropoulos156@gmail.com', '+306915432198', '1982-10-30'),
    ('Sofia', 'Galanopoulou', 'sofia.galanopoulou157@gmail.com', '+306912389012', '2001-11-03'),
    ('Christos', 'Tzimas', 'christos.tzimas158@gmail.com', '+306917654321', '1969-04-14'),
    ('Ioanna', 'Ntoufa', 'ioanna.ntoufa159@gmail.com', '+306916712390', '1993-08-25'),
    ('Dimitra', 'Vougiouka', 'dimitra.vougiouka160@gmail.com', '+306911231231', '1990-06-07'),
    ('Nikos', 'Xenos', 'nikos.xenos161@gmail.com', '+306918888123', '1987-05-19'),
    ('Eirini', 'Lazarou', 'eirini.lazarou162@gmail.com', '+306912444555', '2000-09-01'),
    ('Kostas', 'Delis', 'kostas.delis163@gmail.com', '+306910676767', '1978-01-20'),
    ('Vasiliki', 'Manta', 'vasiliki.manta164@gmail.com', '+306917171717', '1995-03-29'),
    ('Theodoros', 'Palaiologos', 'theodoros.palaiologos165@gmail.com', '+306914343434', '1983-11-11'),
    ('Georgia', 'Kostopoulou', 'georgia.kostopoulou166@gmail.com', '+306916565656', '1992-12-17'),
    ('Michalis', 'Kouris', 'michalis.kouris167@gmail.com', '+306913636363', '1975-06-30'),
    ('Dora', 'Markou', 'dora.markou168@gmail.com', '+306912020202', '1986-08-24'),
    ('Stratos', 'Loukopoulos', 'stratos.loukopoulos169@gmail.com', '+306917373737', '1994-07-02'),
    ('Evangelia', 'Petroula', 'evangelia.petroula170@gmail.com', '+306918181818', '2003-10-10'),
    ('Ilias', 'Varkas', 'ilias.varkas171@gmail.com', '+306910909101', '1990-02-26'),
    ('Despina', 'Touloupa', 'despina.touloupa172@gmail.com', '+306919494949', '1988-12-13'),
    ('Stavros', 'Verginis', 'stavros.verginis173@gmail.com', '+306914848484', '1965-05-05'),
    ('Zoe', 'Argyropoulou', 'zoe.argyropoulou174@gmail.com', '+306913939393', '1998-04-01'),
    ('Antonis', 'Vrettos', 'antonis.vrettos175@gmail.com', '+306912111222', '1972-09-27'),
    ('Eftychia', 'Roka', 'eftychia.roka176@gmail.com', '+306916262626', '1996-06-06'),
    ('Charis', 'Xanthopoulos', 'charis.xanthopoulos177@gmail.com', '+306911717171', '1989-01-01'),
    ('Artemis', 'Skondra', 'artemis.skondra178@gmail.com', '+306915151515', '1991-05-21'),
    ('Lefteris', 'Pavlides', 'lefteris.pavlides179@gmail.com', '+306918989898', '1976-11-30'),
    ('Aggeliki', 'Tzanou', 'aggeliki.tzanou180@gmail.com', '+306910101010', '2005-03-15'),
    ('Apostolos', 'Karidas', 'apostolos.karidas181@gmail.com', '+306919292929', '1981-07-28'),
    ('Eleni', 'Maneta', 'eleni.maneta182@gmail.com', '+306912787878', '1997-12-09'),
    ('Dionysis', 'Mantzouranis', 'dionysis.mantzouranis183@gmail.com', '+306917727272', '1984-02-16'),
    ('Kleoniki', 'Pliatsika', 'kleoniki.pliatsika184@gmail.com', '+306913232323', '1970-01-13'),
    ('Spyros', 'Glezos', 'spyros.glezos185@gmail.com', '+306918181717', '2002-06-26'),
    ('Nantia', 'Kyriakopoulou', 'nantia.kyriakopoulou186@gmail.com', '+306910505050', '1993-09-12'),
    ('Leonidas', 'Zikos', 'leonidas.zikos187@gmail.com', '+306919090909', '1986-10-22'),
    ('Eleni', 'Sarantou', 'eleni.sarantou188@gmail.com', '+306912454545', '2000-11-06'),
    ('Giannis', 'Laskos', 'giannis.laskos189@gmail.com', '+306917070707', '1979-02-18'),
    ('Maria', 'Nikolopoulou', 'maria.nikolopoulou190@gmail.com', '+306916323232', '1992-07-05'),
    ('Vassilis', 'Tselios', 'vassilis.tselios191@gmail.com', '+306911414141', '1985-04-04'),
    ('Niki', 'Pnevmatiki', 'niki.pnevmatiki192@gmail.com', '+306914666666', '1978-08-08'),
    ('Fotis', 'Alexiou', 'fotis.alexiou193@gmail.com', '+306913858585', '1982-03-03'),
    ('Alexandra', 'Moschou', 'alexandra.moschou194@gmail.com', '+306918181313', '1995-01-25'),
    ('Kostas', 'Miliotis', 'kostas.miliotis195@gmail.com', '+306910707070', '1974-12-14'),
    ('Vivi', 'Kondou', 'vivi.kondou196@gmail.com', '+306916464646', '2001-02-02'),
    ('Themis', 'Stergiou', 'themis.stergiou197@gmail.com', '+306911818181', '1983-05-17'),
    ('Eirini', 'Lentza', 'eirini.lentza198@gmail.com', '+306913333333', '1999-08-30'),
    ('Alexandros', 'Trakas', 'alexandros.trakas199@gmail.com', '+306919797979', '1987-09-19'),
    ('Christina', 'Filou', 'christina.filou200@gmail.com', '+306910969696', '1994-06-10');


-- =================================================================
-- STAFF MEMBERS BY CATEGORY
-- =================================================================
-- Three categories of staff based on roles with varied experience levels
-- Each staff member is at least 18 years old with specific expertise classification

-- Technical Staff (sound engineers, lighting technicians, etc.)
INSERT INTO Staff (name, age, role_id, level_id) VALUES
('Giorgos Papadopoulos', 35, 1, 4),  -- Experienced Technical Staff
('Dimitris Antoniou', 29, 1, 3),     -- Intermediate Technical Staff
('Stavros Chatzis', 41, 1, 5),       -- Expert Technical Staff
('Michalis Lazaridis', 32, 1, 4),
('Nikos Alexiou', 27, 1, 2),
('Antonis Petridis', 30, 1, 3),
('Thanasis Vasiliou', 36, 1, 5),
('Christos Georgiou', 28, 1, 2),
('Giannis Theodorou', 26, 1, 1),
('Spyros Konstantinou', 34, 1, 3),
('Lefteris Kalogeropoulos', 30, 1, 2),
('Marios Stathopoulos', 33, 1, 4),
('Petros Nikolaou', 38, 1, 5),
('Vasilis Tsakonas', 31, 1, 3),
('Kostas Zisis', 40, 1, 5),
('Alexandros Xiros', 29, 1, 3),
('Sotiris Floros', 37, 1, 4),
('Nektarios Kosmas', 36, 1, 4),
('Dionysis Pappas', 39, 1, 5),
('Efthymis Karalis', 25, 1, 2),
('Thodoris Chalampidis', 24, 1, 1),
('Nikos Mylonas', 28, 1, 2),
('Sakis Oikonomou', 35, 1, 4),
('Manolis Karatzas', 41, 1, 5),
('Stamatis Lamprou', 32, 1, 3),
('Achilleas Kritikos', 27, 1, 2),
('Vlassis Markopoulos', 38, 1, 4),
('Tasos Dimitriou', 29, 1, 3),
('Christos Drougas', 33, 1, 4),
('Andreas Politis', 30, 1, 3),
('Grigoris Kapsalis', 40, 1, 5),
('Makis Tsironis', 34, 1, 4),
('Aristeidis Lagios', 28, 1, 2),
('Ilias Adamopoulos', 36, 1, 4),
('Dimitris Roidis', 26, 1, 1),
('Pantelis Soulis', 39, 1, 5),
('Kyriakos Melas', 31, 1, 3),
('Stratis Heimonas', 29, 1, 3),
('Lambros Kavvadias', 35, 1, 4),
('Charis Tselentis', 27, 1, 2),
('Iakovos Mitropoulos', 38, 1, 5),
('Anestis Zafiriou', 33, 1, 3),
('Stefanos Vlachos', 24, 1, 1),
('Periklis Tsiodras', 30, 1, 3),
('Ioannis Mantouvalas', 36, 1, 4),
('Rigas Sarris', 37, 1, 4),
('Errikos Pavlidis', 42, 1, 5),
('Orestis Vouros', 34, 1, 3),
('Christos Koulouris', 25, 1, 1),
('Giannis Foteinos', 32, 1, 3),
('Lazaros Maris', 35, 1, 4),
('Napoleon Xynos', 41, 1, 5),
('Nino Kallergis', 27, 1, 2),
('Konstantinos Rigas', 39, 1, 5),
('Antonis Liakos', 30, 1, 3),
('Charis Limperis', 28, 1, 2),
('Theofilos Roussos', 29, 1, 2),
('Angelos Stefos', 31, 1, 3),
('Vangelis Triantafillou', 38, 1, 5),
('Apostolos Stamelos', 26, 1, 1),
('Anastasis Nakos', 36, 1, 4),
('Panos Christodoulou', 34, 1, 4),
('Christos Venetis', 32, 1, 3);

-- Security Staff (ensuring the 5% coverage requirement)
INSERT INTO Staff (name, age, role_id, level_id) VALUES
('Eleni Papadaki', 25, 2, 2),        -- Beginner Security Staff
('Maria Nikolaou', 29, 2, 3),        -- Intermediate Security Staff
('Ioanna Konstantinou', 33, 2, 4),   -- Experienced Security Staff
('Angeliki Stamati', 22, 2, 1),
('Sofia Deligianni', 26, 2, 2),
('Katerina Petrou', 30, 2, 3),
('Christina Zerva', 35, 2, 4),
('Anastasia Panagopoulou', 27, 2, 2),
('Natalia Alexandrou', 24, 2, 1),
('Ioulia Georgiou', 28, 2, 2),
('Efi Lambraki', 31, 2, 3),
('Aliki Karali', 33, 2, 3),
('Stella Barka', 26, 2, 2),
('Anna Makri', 25, 2, 2),
('Danae Papazisi', 29, 2, 3),
('Margarita Chatzi', 34, 2, 4),
('Anthi Kosma', 22, 2, 1),
('Lina Mparmara', 30, 2, 3),
('Georgia Ntouma', 28, 2, 2),
('Antonia Zachariou', 32, 2, 3),
('Konstantina Karra', 27, 2, 2),
('Ismini Kalogirou', 36, 2, 4),
('Anastasia Filippidou', 25, 2, 2),
('Eirini Theodorou', 29, 2, 3),
('Chara Roussou', 31, 2, 3),
('Marianna Charitou', 24, 2, 1),
('Theodora Panou', 35, 2, 4),
('Anastasia Kontou', 27, 2, 2),
('Artemis Tzani', 33, 2, 4),
('Sotiria Foka', 30, 2, 3),
('Loukia Sarantopoulou', 26, 2, 2),
('Despina Papadatou', 34, 2, 4),
('Myrto Manolaki', 23, 2, 1),
('Christina Kapsali', 29, 2, 3),
('Ioulia Balomenou', 31, 2, 3),
('Kalliopi Dimitriou', 25, 2, 2),
('Foteini Nikolaidou', 32, 2, 3),
('Nikoleta Asimakopoulou', 36, 2, 4),
('Rania Xanthopoulou', 26, 2, 2),
('Maria Tsaknaki', 28, 2, 2),
('Niki Kalatzi', 33, 2, 4),
('Thaleia Barka', 30, 2, 3);

-- SUPPORT STAFF
-- Support Staff (ensuring the 2% coverage requirement)
INSERT INTO Staff (name, age, role_id, level_id) VALUES
('Maria Papadopoulou', 28, 3, 3),    -- Intermediate Support Staff
('Georgios Antoniou', 24, 3, 2),     -- Beginner Support Staff
('Elena Dimitriou', 31, 3, 4),       -- Experienced Support Staff
('Nikos Vasileiou', 26, 3, 2),
('Sofia Ioannou', 29, 3, 3),
('Andreas Georgiou', 33, 3, 4),
('Christina Karamanli', 25, 3, 2),
('Dimitris Papathanasiou', 30, 3, 3),
('Athina Nikolaou', 27, 3, 2),
('Kostas Alexiou', 32, 3, 4),
('Eleni Vasileiadou', 29, 3, 3),
('Stavros Papadakis', 26, 3, 2),
('Ioanna Konstantinou', 31, 3, 4),
('Panagiotis Kouris', 28, 3, 3),
('Alexandra Michailidou', 25, 3, 2),
('Thanos Andreou', 34, 3, 4),
('Zoe Karahalios', 27, 3, 3),
('Vassilis Karagiannis', 29, 3, 3),
('Irene Thomou', 26, 3, 2),
('Spiros Markopoulos', 32, 3, 4);

-- =================================================================
-- FESTIVAL DAYS DEFINITION
-- =================================================================
-- Links specific calendar dates to festivals
-- Each festival spans multiple consecutive days as specified in the requirements
INSERT INTO FestivalDay (festival_id, festival_date)
VALUES 
    -- Festival 1: Athens Main Stage Music Festival (2017) - 5 days
    (1, '2017-07-01'),
    (1, '2017-07-02'),
    (1, '2017-07-03'),
    (1, '2017-07-04'),
    (1, '2017-07-05'),

    -- Festival 2: New York Sound Experience (2018) - 6 days
    (2, '2018-06-15'),
    (2, '2018-06-16'),
    (2, '2018-06-17'),
    (2, '2018-06-18'),
    (2, '2018-06-19'),
    (2, '2018-06-20'),

    -- Festival 3: Rio Beach Party (2019) - 6 days
    (3, '2019-08-10'),
    (3, '2019-08-11'),
    (3, '2019-08-12'),
    (3, '2019-08-13'),
    (3, '2019-08-14'),
    (3, '2019-08-15'),

    -- Festival 4: London Park Festival (2020) - 10 days
    (4, '2020-07-01'),
    (4, '2020-07-02'),
    (4, '2020-07-03'),
    (4, '2020-07-04'),
    (4, '2020-07-05'),
    (4, '2020-07-06'),
    (4, '2020-07-07'),
    (4, '2020-07-08'),
    (4, '2020-07-09'),
    (4, '2020-07-10'),

    -- Festival 5: Patras Nights (2021) - 5 days
    (5, '2021-09-01'),
    (5, '2021-09-02'),
    (5, '2021-09-03'),
    (5, '2021-09-04'),
    (5, '2021-09-05'),

    -- Festival 6: Sydney Opera Sounds (2022) - 6 days
    (6, '2022-08-20'),
    (6, '2022-08-21'),
    (6, '2022-08-22'),
    (6, '2022-08-23'),
    (6, '2022-08-24'),
    (6, '2022-08-25'),

    -- Festival 7: Thessaloniki Jazz Festival (2023) - 6 days
    (7, '2023-05-20'),
    (7, '2023-05-21'),
    (7, '2023-05-22'),
    (7, '2023-05-23'),
    (7, '2023-05-24'),
    (7, '2023-05-25'),

    -- Festival 8: Athens Reunion Festival (2024) - 11 days
    (8, '2024-07-10'),
    (8, '2024-07-11'),
    (8, '2024-07-12'),
    (8, '2024-07-13'),
    (8, '2024-07-14'),
    (8, '2024-07-15'),
    (8, '2024-07-16'),
    (8, '2024-07-17'),
    (8, '2024-07-18'),
    (8, '2024-07-19'),

    -- Festival 9: New York World Music Heritage (2025) - 10 days (FUTURE)
    (9, '2025-08-01'),
    (9, '2025-08-02'),
    (9, '2025-08-03'),
    (9, '2025-08-04'),
    (9, '2025-08-05'),
    (9, '2025-08-06'),
    (9, '2025-08-07'),
    (9, '2025-08-08'),
    (9, '2025-08-09'),
    (9, '2025-08-10'),

    -- Festival 10: Rio Summer Sounds (2026) - 6 days (FUTURE)
    (10, '2026-09-05'),
    (10, '2026-09-06'),
    (10, '2026-09-07'),
    (10, '2026-09-08'),
    (10, '2026-09-09'),
    (10, '2026-09-10');

-- =================================================================
-- EVENTS SCHEDULING
-- =================================================================
-- Events are specific scheduled performances taking place at festival stages
-- Each event has a specific day, location, time window, and name
-- Events cannot overlap on the same stage (enforced by check_overlapping_events trigger)
-- For Festival 1 (Athens 2017)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (1, 1, 'Rock Opening Night', '18:00:00', '23:00:00'),
    (2, 2, 'Folk Experience Day 2', '17:30:00', '23:30:00'),
    (3, 3, 'Dance Night Special', '19:00:00', '23:59:00'),
    (4, 1, 'Sunset Acoustics', '18:30:00', '23:00:00'),
    (5, 2, 'Grand Finale', '17:00:00', '23:59:00');

-- For Festival 2 (New York 2018)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (6, 5, 'Pop Night', '19:00:00', '23:00:00'),
    (7, 6, 'Rock Fusion', '18:30:00', '23:30:00'),
    (8, 7, 'Acoustic Sessions', '17:00:00', '22:00:00'),
    (9, 5, 'Live Band Night', '19:30:00', '23:59:00'),
    (10, 6, 'Greek Music Night', '18:00:00', '23:00:00'),
    (11, 7, 'Final Show', '18:00:00', '23:59:00');

-- For Festival 3 (Rio 2019)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
     (12, 9, 'Beach Opening Party', '16:00:00', '22:00:00'),
    (13, 10, 'Sunset DJ Sets', '17:00:00', '23:00:00'),
    (14, 11, 'Dance Pop Night', '18:00:00', '23:59:00'),
    (15, 9, 'Electronic Vibes', '17:30:00', '23:30:00'),
    (16, 10, 'Beach Party Special', '16:30:00', '23:00:00'),
    (17, 11, 'Closing Night', '18:00:00', '23:59:00');

-- For Festival 4 (London 2020)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (18, 16, 'London Opening Night', '19:00:00', '23:00:00'),
    (19, 17, 'British Jazz Corner Night', '20:00:00', '23:30:00'),
    (20, 18, 'Greek Night in London', '18:30:00', '22:30:00'),
    (21, 16, 'Classical Evening', '19:30:00', '23:00:00'),
    (22, 17, 'Folk and Traditional Day', '19:00:00', '23:00:00'),
    (23, 18, 'London Jazz Night', '19:00:00', '23:30:00'),
    (24, 16, 'British Folk Revival', '18:30:00', '22:30:00'),
    (25, 17, 'Electronic London', '19:00:00', '23:59:00'),
    (26, 18, 'Modern British Music', '18:00:00', '23:00:00'),
    (27, 16, 'London Closing Ceremony', '19:00:00', '23:59:00');

-- For Festival 5 (Patras 2021)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (28, 13, 'Patras Jazz Opening', '19:00:00', '23:00:00'),
    (29, 14, 'Fusion Night', '19:30:00', '23:30:00'),
    (30, 13, 'Greek Street Music', '18:00:00', '22:00:00'),
    (31, 14, 'Local Artists Showcase', '19:00:00', '23:00:00'),
    (32, 13, 'Closing Night Celebration', '18:30:00', '23:59:00');

-- For Festival 6 (Sydney 2022)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (33, 20, 'Opera House Opening', '18:00:00', '23:00:00'),
    (34, 21, 'Harbor Views Night', '19:00:00', '23:00:00'),
    (35, 20, 'Australian-Greek Fusion', '18:30:00', '23:30:00'),
    (36, 21, 'Classical Evening', '17:00:00', '23:00:00'),
    (37, 20, 'Pacific Rhythms', '16:00:00', '21:00:00'),
    (38, 21, 'Sydney Closing Celebration', '17:30:00', '23:59:00');

-- For Festival 7 (Thessaloniki 2023)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (39, 24, 'Thessaloniki Jazz Opening', '19:00:00', '23:00:00'),
    (40, 27, 'Fusion Night', '19:30:00', '23:30:00'),
    (41, 24, 'Greek Traditional', '18:00:00', '22:00:00'),
    (42, 27, 'Local Artists Showcase', '19:00:00', '23:00:00'),
    (43, 24, 'Experimental Night', '18:30:00', '22:30:00'),
    (44, 27, 'Closing Celebration', '19:00:00', '23:59:00');

-- For Festival 8 (Athens 2024)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (45, 1, 'Athens Opening Night', '19:00:00', '23:59:00'),
    (46, 2, 'DJ Night', '21:00:00', '23:59:00'),
    (47, 3, 'Asian-European Fusion', '19:30:00', '23:30:00'),
    (48, 4, 'Electronic Showcase', '21:30:00', '23:59:00'), 
    (49, 30, 'Live Band Special', '18:00:00', '23:00:00'),
    (50, 4, 'Summer Vibes', '21:00:00', '23:59:00'),
    (51, 3, 'Athens Pop Night', '19:00:00', '23:00:00'),
    (52, 30, 'Athens Rock Night', '19:30:00', '23:59:00'),
    (53, 4, 'Athens Traditional', '18:00:00', '22:00:00'),
    (54, 2, 'Athens Dance', '20:00:00', '23:59:00');

-- For Festival 9 (New York 2025 - Future)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (55, 5, 'Future Opening Night', '18:00:00', '23:00:00'),
    (56, 6, 'Heritage Night', '19:00:00', '23:00:00'),
    (57, 7, 'Cross-Cultural Exchange', '18:30:00', '23:30:00'),
    (58, 8, 'Traditional Music Night', '19:30:00', '23:30:00'),
    (59, 8, 'World Music Showcase', '18:00:00', '22:00:00'),
    (60, 8, 'NY Cultural Mix', '18:00:00', '22:00:00'), 
    (61, 6, 'NY Rock Experience', '19:00:00', '23:00:00'),
    (62, 5, 'NY Folk Night', '18:30:00', '22:30:00'), 
    (63, 6, 'NY Jazz Fusion', '19:30:00', '23:30:00'),
    (64, 7, 'NY Independent Artists', '18:00:00', '22:00:00');


-- For Festival 10 (Rio 2026 - Future)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
VALUES 
    (65, 9, 'Beach Opening Ceremony', '19:00:00', '22:00:00'),
    (66, 10, 'Acoustic Night', '20:00:00', '23:00:00'),
    (67, 11, 'Brazilian-Greek Fusion', '19:30:00', '22:30:00'),
    (68, 12, 'Beach Dance Night', '20:30:00', '23:30:00'),
    (69, 12, 'Band Night', '19:00:00', '22:00:00'),
    (70, 12, 'Closing Celebration', '20:00:00', '23:59:00');



-- =================================================================
-- PERFORMANCE SCHEDULING
-- =================================================================
-- Individual artist/band performances within events
-- Enforces business rules:
-- 1. 5-30 minute breaks between performances
-- 2. Maximum performance duration of 3 hours
-- 3. Artists/bands cannot perform at multiple venues simultaneously
-- 4. Artists/bands cannot participate for more than 3 consecutive festival years

-- Performance inserts for Festival 1: Athens Main Stage Music Festival (2017)
-- Event 1: Rock Opening Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (1, 9, NULL, 1, 1, '18:00:00', 60),   -- Vasilis Papakonstantinou (Warm Up)
    (1, NULL, 1, 1, 2, '19:15:00', 90),   -- Pyx Lax (Headline)
    (1, 32, NULL, 1, 3, '21:00:00', 60);  -- Sokratis Malamas (Special Guest)

-- Event 2: Folk Experience Day 2
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (2, 4, NULL, 2, 1, '17:30:00', 60),   -- Haris Alexiou (Warm Up)
    (2, 26, NULL, 2, 2, '18:45:00', 90),  -- Giorgos Dalaras (Headline)
    (2, 10, NULL, 2, 3, '20:30:00', 75);  -- Dionysis Savvopoulos (Special Guest)

-- Event 3: Dance Night Special
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (3, 2, NULL, 3, 1, '19:00:00', 60),   -- Anna Vissi (Warm Up)
    (3, 24, NULL, 3, 2, '20:15:00', 75),  -- Anastasios Rouvas (Sakis) (Headline)
    (3, 27, NULL, 3, 3, '21:45:00', 60);  -- Entela Fureraj (Eleni Foureira) (Special Guest)

-- Event 4: Sunset Acoustics
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (4, 3, NULL, 1, 1, '18:30:00', 60),   -- Miltos Paschalidis (Warm Up)
    (4, 15, NULL, 1, 2, '19:45:00', 75),  -- Pantelis Thalassinos (Headline)
    (4, 22, NULL, 1, 3, '21:15:00', 60);  -- Foivos Delivorias (Special Guest)

-- Event 5: Grand Finale
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (5, 35, NULL, 2, 1, '17:00:00', 60),   -- Nikos Portokaloglou (Warm Up)
    (5, NULL, 10, 2, 2, '18:15:00', 75),   -- Kitrina Podilata (Headline)
    (5, 7, NULL, 2, 3, '19:45:00', 60),    -- Giorgos Mazonakis (Special Guest)
    (5, 5, NULL, 2, 3, '21:00:00', 75);    -- Nikos Vertis (Special Guest)

-- Performance inserts for Festival 2: New York Sound Experience (2018)
-- Event 6: Pop Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (6, 12, NULL, 5, 1, '19:00:00', 60),   -- Michalis Hatzigiannis (Warm Up)
    (6, 25, NULL, 5, 2, '20:15:00', 75),   -- Elena Paparizou (Headline)
    (6, NULL, 2, 5, 3, '21:45:00', 60);    -- Onirama (Special Guest)

-- Event 7: Rock Fusion
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (7, 31, NULL, 6, 1, '18:30:00', 60),   -- Babis Stokas (Warm Up)
    (7, NULL, 4, 6, 2, '19:45:00', 75),    -- Trypes (Headline)
    (7, 20, NULL, 6, 3, '21:15:00', 75);   -- Stelios Rokkos (Special Guest)

-- Event 8: Acoustic Sessions
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (8, 6, NULL, 7, 1, '17:00:00', 60),    -- Eleonora Zouganeli (Warm Up)
    (8, 33, NULL, 7, 2, '18:15:00', 75),   -- Christos Thivaios (Headline)
    (8, 3, NULL, 7, 3, '19:45:00', 60);    -- Miltos Paschalidis (Special Guest)

-- Performance inserts for Festival 3: Rio Beach Party (2019)
-- Event 12: Beach Opening Party
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (12, 27, NULL, 9, 1, '16:00:00', 60),   -- Eleni Foureira (Warm Up)
    (12, 24, NULL, 9, 2, '17:15:00', 90),   -- Sakis Rouvas (Headline)
    (12, 2, NULL, 9, 3, '19:00:00', 60);    -- Anna Vissi (Special Guest)

-- Event 13: Sunset DJ Sets
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (13, 37, NULL, 10, 1, '17:00:00', 60),   -- Maria-Sophia (Marseaux) (Warm Up)
    (13, 39, NULL, 10, 2, '18:15:00', 75),   -- Anastasia-Dimitra (Headline)
    (13, 23, NULL, 10, 3, '19:45:00', 90);   -- Thodoris Ferris (Special Guest)

-- Performance inserts for Festival 4: London Park Festival (2020)
-- Event 18: London Opening Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (18, 33, NULL, 16, 1, '19:00:00', 60),   -- Christos Thivaios (Warm Up)
    (18, 26, NULL, 16, 2, '20:15:00', 75),   -- Giorgos Dalaras (Headline)
    (18, 4, NULL, 16, 3, '21:45:00', 60);    -- Haris Alexiou (Special Guest)

-- Event 19: British Jazz Corner Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (19, 28, NULL, 17, 1, '20:00:00', 60),   -- Mariza Rizou (Warm Up)
    (19, NULL, 9, 17, 2, '21:15:00', 75),    -- Xylina Spathia (Headline)
    (19, 5, NULL, 17, 3, '22:45:00', 30);    -- Nikos Vertis (Special Guest)

-- Performance inserts for Festival 5: Patras Nights (2021)
-- Event 28: Patras Jazz Opening
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (28, 28, NULL, 13, 1, '19:00:00', 60),   -- Mariza Rizou (Warm Up)
    (28, NULL, 9, 13, 2, '20:15:00', 75),    -- Xylina Spathia (Headline)
    (28, 35, NULL, 13, 3, '21:45:00', 60);   -- Nikos Portokaloglou (Special Guest)

-- Event 29: Fusion Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (29, 8, NULL, 14, 1, '19:30:00', 60),    -- Alexis Lanaras (Lex) (Warm Up)
    (29, NULL, 11, 14, 2, '20:45:00', 75),   -- Active Member (Headline)
    (29, 22, NULL, 14, 3, '22:15:00', 60);   -- Foivos Delivorias (Special Guest)

-- Performance inserts for Festival 6: Sydney Opera Sounds (2022)
-- Event 33: Opera House Opening
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (33, NULL, 12, 20, 1, '18:00:00', 60),   -- Locomondo (Warm Up)
    (33, 17, NULL, 20, 2, '19:15:00', 75),   -- Panos Kiamos (Headline)
    (33, NULL, 6, 20, 3, '20:45:00', 90);    -- Ypogeia Revmata (Special Guest)

-- Event 34: Harbor Views Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (34, 32, NULL, 21, 1, '19:00:00', 60),   -- Sokratis Malamas (Warm Up)
    (34, 33, NULL, 21, 2, '20:15:00', 75),   -- Christos Thivaios (Headline)
    (34, 21, NULL, 21, 3, '21:45:00', 60);   -- Paschalis Terzis (Special Guest)

-- Performance inserts for Festival 7: Thessaloniki Jazz Festival (2023)
-- Event 39: Thessaloniki Jazz Opening
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (39, 28, NULL, 24, 1, '19:00:00', 60),   -- Mariza Rizou (Warm Up)
    (39, NULL, 9, 24, 2, '20:15:00', 75),    -- Xylina Spathia (Headline)
    (39, 30, NULL, 24, 3, '21:45:00', 60);   -- Thanos Mikroutsikos (Special Guest)

-- Event 40: Fusion Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (40, 36, NULL, 27, 1, '19:30:00', 60),   -- Markos Koumaris (Warm Up)
    (40, NULL, 12, 27, 2, '20:45:00', 75),   -- Locomondo (Headline)
    (40, 34, NULL, 27, 3, '22:15:00', 60);   -- Christos Mastoras (Special Guest)

-- Performance inserts for Festival 8: Athens Reunion Festival (2024)
-- Event 45: Athens Opening Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (45, 34, NULL, 1, 1, '19:00:00', 60),   -- Christos Mastoras (Warm Up)
    (45, NULL, 3, 1, 2, '20:15:00', 90),    -- Melisses (Headline)
    (45, NULL, 14, 1, 3, '22:00:00', 60);   -- WNCfam (Special Guest)

-- Event 46: DJ Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (46, 38, NULL, 2, 1, '21:00:00', 60),   -- Giorgos Kakossaios (Warm Up)
    (46, 37, NULL, 2, 2, '22:15:00', 90),   -- Maria-Sophia (Marseaux) (Headline)
    (46, 39, NULL, 2, 3, '23:59:00', 60);   -- Anastasia-Dimitra (Special Guest)

-- Performance inserts for Festival 9: New York World Music Heritage (2025, future)
-- Event 55: Future Opening Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (55, 30, NULL, 5, 1, '18:00:00', 60),   -- Thanos Mikroutsikos (Warm Up)
    (55, 15, NULL, 5, 2, '19:15:00', 90),   -- Pantelis Thalassinos (Headline)
    (55, 1, NULL, 5, 3, '21:00:00', 60);    -- Giannis Varthakouris (Parios) (Special Guest)

-- Event 56: Heritage Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (56, 16, NULL, 6, 1, '19:00:00', 60),   -- Lefteris Pantazis (Warm Up)
    (56, 21, NULL, 6, 2, '20:15:00', 75),   -- Paschalis Terzis (Headline)
    (56, 11, NULL, 6, 3, '21:45:00', 60);   -- Kaiti Garbi (Special Guest)

-- Performance inserts for Festival 10: Rio Summer Sounds (2026, future)
-- Event 65: Beach Opening Ceremony
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (65, 22, NULL, 9, 1, '19:00:00', 60),    -- Foivos Delivorias (Warm Up)
    (65, NULL, 10, 9, 2, '20:15:00', 75),    -- Kitrina Podilata (Headline)
    (65, 6, NULL, 9, 3, '21:45:00', 60);     -- Eleonora Zouganeli (Special Guest)

-- Event 66: Acoustic Night
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (66, 14, NULL, 10, 1, '20:00:00', 60),   -- Despina Vandi (Warm Up)
    (66, 19, NULL, 10, 2, '21:15:00', 75),   -- Antonis Remos (Headline)
    (66, 18, NULL, 10, 3, '22:45:00', 60);   -- Natasa Theodoridou (Special Guest)

-- Add more performances for later events
-- Event 47: Asian-European Fusion
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (47, 25, NULL, 3, 1, '19:30:00', 60),   -- Elena Paparizou (Warm Up)
    (47, 2, NULL, 3, 2, '20:45:00', 75),    -- Anna Vissi (Headline)
    (47, 12, NULL, 3, 3, '22:15:00', 60);   -- Michalis Hatzigiannis (Special Guest)

-- Event 67: Brazilian-Greek Fusion
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    (67, 13, NULL, 11, 1, '19:30:00', 60),   -- Evridiki (Warm Up)
    (67, 20, NULL, 11, 2, '20:45:00', 90),   -- Stelios Rokkos (Headline)
    (67, 27, NULL, 11, 3, '22:30:00', 60);   -- Eleni Foureira (Special Guest)

-- More performances for Festival 2 (New York, 2018) to increase continent coverage
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES 
    -- Event 9 (which should be Live Band Night)
    (9, 28, NULL, 5, 1, '19:30:00', 60),   -- Mariza Rizou (Warm Up, North America)
    (9, 19, NULL, 5, 2, '20:45:00', 75),   -- Antonis Remos (Headline)
    (9, 11, NULL, 5, 3, '22:15:00', 60),   -- Kaiti Garbi (Special Guest)
    
    -- Event 10 (Greek Music Night)
    (10, 1, NULL, 6, 1, '18:00:00', 60),   -- Giannis Parios (Warm Up)
    (10, 4, NULL, 6, 2, '19:15:00', 75),   -- Haris Alexiou (Headline)
    (10, 14, NULL, 6, 3, '20:45:00', 60);  -- Despina Vandi (Special Guest)

-- Additional performances for Festival 3 (Rio, 2019, South America)
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES
    -- Event 14 (Dance Pop Night)
    (14, 28, NULL, 11, 1, '18:00:00', 60),  -- Mariza Rizou (Warm Up, South America)
    (14, 11, NULL, 11, 2, '19:15:00', 75),  -- Kaiti Garbi (Headline)
    (14, 14, NULL, 11, 3, '20:45:00', 60),  -- Despina Vandi (Special Guest)
    
    -- Event 15 (Electronic Vibes)
    (15, 37, NULL, 9, 1, '17:30:00', 60),   -- Maria-Sophia (Warm Up)
    (15, 25, NULL, 9, 2, '18:45:00', 75),   -- Elena Paparizou (Headline)
    (15, 27, NULL, 9, 3, '20:15:00', 60);   -- Eleni Foureira (Special Guest)

-- Additional performances for consecutive year genre comparison
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES
    -- Rock genre in Festival 7 (2023)
    (41, 3, NULL, 24, 1, '18:00:00', 60),   -- Miltos Paschalidis (Rock, Warm Up)
    (41, 9, NULL, 24, 2, '19:15:00', 75),   -- Vasilis Papakonstantinou (Rock, Headline)
    (41, 20, NULL, 24, 3, '20:45:00', 60),  -- Stelios Rokkos (Rock, Special Guest)
    
    -- Rock genre in Festival 8 (2024) - similar count to previous year
    (48, NULL, 4, 4, 1, '21:30:00', 60),    -- Trypes (Rock, Warm Up)
    (48, NULL, 5, 4, 2, '22:45:00', 75),    -- Ble (Rock, Headline)
    
    -- Pop genre in Festival 7 (2023)
    (42, 25, NULL, 27, 1, '19:00:00', 60),  -- Elena Paparizou (Pop, Warm Up)
    (42, 12, NULL, 27, 2, '20:15:00', 75),  -- Michalis Hatzigiannis (Pop, Headline)
    (42, 29, NULL, 27, 3, '21:45:00', 60),  -- Thodoris Marantinis (Pop, Special Guest)
    
    -- Pop genre in Festival 8 (2024) - similar count to previous year
    (49, 34, NULL, 30, 1, '18:00:00', 60),  -- Christos Mastoras (Pop, Warm Up)
    (49, 37, NULL, 30, 2, '19:15:00', 75),  -- Maria-Sophia (Pop, Headline)
    (49, 39, NULL, 30, 3, '20:45:00', 60);  -- Anastasia-Dimitra (Pop, Special Guest)

-- Add more performances for other events to reach 100+ total
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES
    -- More events in Festival 4 (London 2020)
    (20, 16, NULL, 18, 1, '18:30:00', 60),  -- Lefteris Pantazis (Warm Up)
    (20, 17, NULL, 18, 2, '19:45:00', 75),  -- Panos Kiamos (Headline)
    (20, 18, NULL, 18, 3, '21:15:00', 60),  -- Natasa Theodoridou (Special Guest)
         
    -- Events in Festival 5 (Patras 2021)
    (30, 13, NULL, 15, 1, '18:00:00', 60),  -- Evridiki (Warm Up)
    (30, 23, NULL, 15, 2, '19:15:00', 75),  -- Thodoris Ferris (Headline)
    (30, 29, NULL, 15, 3, '20:45:00', 60),  -- Thodoris Marantinis (Special Guest)
    
    -- More events for Festival 9 (New York 2025, future)
    (57, 8, NULL, 7, 1, '18:30:00', 60),    -- Alexis Lanaras (Warm Up)
    (57, NULL, 11, 7, 2, '19:45:00', 75),   -- Active Member (Headline)
    (57, 6, NULL, 7, 3, '21:15:00', 60),    -- Eleonora Zouganeli (Special Guest)
    
    -- Additional performances for Festival 10 (Rio 2026, future)
    (68, 17, NULL, 12, 1, '20:30:00', 60),  -- Panos Kiamos (Warm Up)
    (68, 32, NULL, 12, 2, '21:45:00', 75),  -- Sokratis Malamas (Headline)
    (68, 33, NULL, 12, 3, '23:15:00', 60);  -- Christos Thivaios (Special Guest)

-- Create performances specifically to address query #3 (artist with multiple warm-ups in same festival)
-- Using Thodoris Marantinis (ID 29) in Athens Reunion Festival (2024, ID 8) at different events
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    -- Different events in Festival 8 (Athens 2024)
    (50, 29, NULL, 3, 1, '19:00:00', 45),  -- Thodoris Marantinis (Warm Up #1)
    (51, 29, NULL, 1, 1, '18:00:00', 45),  -- Thodoris Marantinis (Warm Up #2)
    (52, 29, NULL, 4, 1, '18:30:00', 45);  -- Thodoris Marantinis (Warm Up #3)

-- Additional performances for Festival 9 (New York 2025, future)
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    -- Event 58 (Traditional Music Night)
    (58, 7, NULL, 8, 1, '19:30:00', 60),   -- Giorgos Mazonakis (Warm Up)
    (58, 18, NULL, 8, 2, '20:45:00', 75),  -- Natasa Theodoridou (Headline)
    (58, 19, NULL, 8, 3, '22:15:00', 60),  -- Antonis Remos (Special Guest)
    
    -- Event 59 (World Music Showcase)
    (59, 13, NULL, 8, 1, '18:00:00', 60),  -- Evridiki (Warm Up)
    (59, 19, NULL, 8, 2, '19:15:00', 75),  -- Antonis Remos (Headline)
    (59, 39, NULL, 8, 3, '20:45:00', 60);  -- Anastasia-Dimitra (Special Guest)

-- Additional performances for Festival 10 (Rio 2026, future)
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    -- Event 69 (Band Night)
    (69, NULL, 3, 12, 1, '19:00:00', 60),   -- Melisses (Warm Up)
    (69, NULL, 5, 12, 2, '20:15:00', 75),   -- Ble (Headline)
    (69, NULL, 2, 12, 3, '21:45:00', 60),   -- Onirama (Special Guest)
    
    -- Event 70 (Closing Celebration)
    (70, 34, NULL, 12, 1, '20:00:00', 60),  -- Christos Mastoras (Warm Up)
    (70, 23, NULL, 12, 2, '21:15:00', 75),  -- Thodoris Ferris (Headline)
    (70, 37, NULL, 12, 3, '22:45:00', 60);  -- Maria-Sophia (Special Guest)

-- Try creating another example for query #3 with a different artist in Festival 9
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    -- Multiple warm-ups by Anastasia-Dimitra (ID 39) in Festival 9
    (60, 39, NULL, 7, 1, '18:00:00', 45),   -- Anastasia-Dimitra (Warm Up #1)
    (61, 39, NULL, 5, 1, '19:00:00', 45),   -- Anastasia-Dimitra (Warm Up #2)
    (62, 39, NULL, 6, 1, '18:30:00', 45);   -- Anastasia-Dimitra (Warm Up #3)

-- More performances for Festival 7 (Thessaloniki 2023)
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    -- Events in Festival 7 (Thessaloniki Jazz 2023)
    (43, 10, NULL, 25, 1, '18:30:00', 60),   -- Dionysis Savvopoulos (Warm Up)
    (43, 22, NULL, 25, 2, '19:45:00', 75),   -- Foivos Delivorias (Headline)
    (43, 35, NULL, 25, 3, '21:15:00', 60),   -- Nikos Portokaloglou (Special Guest)
    
    -- Event 44 (Closing Celebration)
    (44, 8, NULL, 27, 1, '19:00:00', 60),   -- Alexis Lanaras (Warm Up)
    (44, 6, NULL, 27, 2, '20:15:00', 75),   -- Eleonora Zouganeli (Headline)
    (44, 13, NULL, 27, 3, '21:45:00', 60);  -- Evridiki (Special Guest)

-- =================================================================
-- TICKET SALES DATA
-- =================================================================
-- 200+ tickets across all festivals with varied categories
-- For past festivals: mix of used/unused tickets
-- For future festivals: all tickets active (unused)
-- VIP tickets are limited to 10% of stage capacity (enforced by CheckVIPTicketLimit trigger)
INSERT INTO Ticket (event_id, visitor_id, category_id, method_id, price, purchase_date, EAN_code, is_active, resale_available)
VALUES 
    -- Event 1: Rock Opening Night (2017 - Past event, most tickets used)
    (1, 1, 1, 1, 50.00, '2017-05-01 10:00:00', '1234567890001', FALSE, FALSE),  -- General ticket, Credit Card
    (1, 2, 1, 1, 50.00, '2017-05-01 10:05:00', '1234567890002', FALSE, FALSE),  -- General ticket, Credit Card
    (1, 3, 2, 2, 100.00, '2017-05-01 10:10:00', '1234567890003', FALSE, FALSE), -- VIP ticket, Debit Card
    (1, 4, 1, 1, 50.00, '2017-05-01 10:15:00', '1234567890004', FALSE, FALSE),  -- General ticket, Credit Card
    (1, 5, 1, 2, 50.00, '2017-05-01 10:20:00', '1234567890005', FALSE, FALSE),  -- General ticket, Debit Card
    (1, 6, 1, 1, 50.00, '2017-05-02 11:00:00', '1234567890006', FALSE, FALSE),  -- General ticket, Credit Card
    (1, 7, 2, 2, 100.00, '2017-05-02 11:05:00', '1234567890007', FALSE, FALSE), -- VIP ticket, Debit Card
    (1, 8, 1, 3, 50.00, '2017-05-02 11:10:00', '1234567890008', FALSE, FALSE),  -- General ticket, Bank Transfer
    (1, 9, 1, 1, 50.00, '2017-05-02 11:15:00', '1234567890009', FALSE, FALSE),  -- General ticket, Credit Card
    (1, 10, 1, 2, 50.00, '2017-05-02 11:20:00', '1234567890010', TRUE, FALSE),  -- General ticket, Debit Card (no-show)

    -- Event 2: Folk Experience Day 2 (2017 - Past event, most tickets used)
    (2, 11, 1, 1, 55.00, '2017-05-15 10:00:00', '1234567890011', FALSE, FALSE),  -- General ticket, Credit Card
    (2, 12, 2, 2, 110.00, '2017-05-15 10:05:00', '1234567890012', FALSE, FALSE), -- VIP ticket, Debit Card
    (2, 13, 1, 1, 55.00, '2017-05-15 10:10:00', '1234567890013', FALSE, FALSE),  -- General ticket, Credit Card
    (2, 14, 1, 3, 55.00, '2017-05-15 10:15:00', '1234567890014', FALSE, FALSE),  -- General ticket, Bank Transfer
    (2, 15, 1, 1, 55.00, '2017-05-15 10:20:00', '1234567890015', FALSE, FALSE),  -- General ticket, Credit Card
    (2, 16, 1, 2, 55.00, '2017-05-16 11:00:00', '1234567890016', FALSE, FALSE),  -- General ticket, Debit Card
    (2, 17, 2, 1, 110.00, '2017-05-16 11:05:00', '1234567890017', FALSE, FALSE), -- VIP ticket, Credit Card
    (2, 18, 1, 3, 55.00, '2017-05-16 11:10:00', '1234567890018', FALSE, FALSE),  -- General ticket, Bank Transfer
    (2, 19, 1, 1, 55.00, '2017-05-16 11:15:00', '1234567890019', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (2, 20, 1, 2, 55.00, '2017-05-16 11:20:00', '1234567890020', TRUE, FALSE),   -- General ticket, Debit Card (no-show)

    -- Festival 2: New York Sound Experience 2018 - Event 6: Pop Night (2018 - Past event, most tickets used)
    (6, 21, 1, 1, 60.00, '2018-04-01 09:30:00', '1234567890021', FALSE, FALSE),  -- General ticket, Credit Card
    (6, 22, 2, 2, 120.00, '2018-04-01 10:15:00', '1234567890022', FALSE, FALSE), -- VIP ticket, Debit Card
    (6, 23, 1, 1, 60.00, '2018-04-02 11:20:00', '1234567890023', FALSE, FALSE),  -- General ticket, Credit Card
    (6, 24, 1, 3, 60.00, '2018-04-02 14:00:00', '1234567890024', FALSE, FALSE),  -- General ticket, Bank Transfer
    (6, 25, 1, 1, 60.00, '2018-04-03 09:45:00', '1234567890025', FALSE, FALSE),  -- General ticket, Credit Card
    (6, 26, 1, 2, 60.00, '2018-04-03 10:30:00', '1234567890026', FALSE, FALSE),  -- General ticket, Debit Card
    (6, 27, 2, 1, 120.00, '2018-04-04 11:00:00', '1234567890027', FALSE, FALSE), -- VIP ticket, Credit Card
    (6, 28, 1, 3, 60.00, '2018-04-04 12:15:00', '1234567890028', FALSE, FALSE),  -- General ticket, Bank Transfer
    (6, 29, 1, 1, 60.00, '2018-04-05 09:00:00', '1234567890029', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (6, 30, 1, 2, 60.00, '2018-04-05 10:45:00', '1234567890030', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Festival 3: Rio Beach Party 2019 - Event 12: Beach Opening Party (2019 - Past event, most tickets used)
    (12, 31, 1, 1, 70.00, '2019-06-01 09:15:00', '1234567890031', FALSE, FALSE),  -- General ticket, Credit Card
    (12, 32, 2, 2, 140.00, '2019-06-01 10:30:00', '1234567890032', FALSE, FALSE), -- VIP ticket, Debit Card
    (12, 33, 1, 1, 70.00, '2019-06-02 11:45:00', '1234567890033', FALSE, FALSE),  -- General ticket, Credit Card
    (12, 34, 1, 3, 70.00, '2019-06-02 13:00:00', '1234567890034', FALSE, FALSE),  -- General ticket, Bank Transfer
    (12, 35, 3, 1, 200.00, '2019-06-03 09:30:00', '1234567890035', FALSE, FALSE), -- Backstage ticket, Credit Card
    (12, 36, 1, 2, 70.00, '2019-06-03 11:15:00', '1234567890036', FALSE, FALSE),  -- General ticket, Debit Card
    (12, 37, 2, 1, 140.00, '2019-06-04 10:15:00', '1234567890037', FALSE, FALSE), -- VIP ticket, Credit Card
    (12, 38, 1, 3, 70.00, '2019-06-04 12:30:00', '1234567890038', FALSE, FALSE),  -- General ticket, Bank Transfer
    (12, 39, 1, 1, 70.00, '2019-06-05 09:45:00', '1234567890039', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (12, 40, 1, 2, 70.00, '2019-06-05 11:30:00', '1234567890040', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Festival 4: London Park Festival 2020 - Event 18: London Opening Night (2020 - Past event, most tickets used)
    (18, 41, 1, 1, 65.00, '2020-05-01 09:00:00', '1234567890041', FALSE, FALSE),  -- General ticket, Credit Card
    (18, 42, 2, 2, 130.00, '2020-05-01 10:30:00', '1234567890042', FALSE, FALSE), -- VIP ticket, Debit Card
    (18, 43, 1, 1, 65.00, '2020-05-02 11:15:00', '1234567890043', FALSE, FALSE),  -- General ticket, Credit Card
    (18, 44, 1, 3, 65.00, '2020-05-02 13:30:00', '1234567890044', FALSE, FALSE),  -- General ticket, Bank Transfer
    (18, 45, 1, 1, 65.00, '2020-05-03 09:30:00', '1234567890045', FALSE, FALSE),  -- General ticket, Credit Card
    (18, 46, 1, 2, 65.00, '2020-05-03 11:00:00', '1234567890046', FALSE, FALSE),  -- General ticket, Debit Card
    (18, 47, 2, 1, 130.00, '2020-05-04 10:15:00', '1234567890047', FALSE, FALSE), -- VIP ticket, Credit Card
    (18, 48, 1, 3, 65.00, '2020-05-04 12:45:00', '1234567890048', FALSE, FALSE),  -- General ticket, Bank Transfer
    (18, 49, 1, 1, 65.00, '2020-05-05 09:15:00', '1234567890049', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (18, 50, 1, 2, 65.00, '2020-05-05 11:30:00', '1234567890050', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Festival 5: Patras Nights 2021 - Event 28: Patras Jazz Opening (2021 - Past event, most tickets used)
    (28, 51, 1, 1, 55.00, '2021-07-01 09:30:00', '1234567890051', FALSE, FALSE),  -- General ticket, Credit Card
    (28, 52, 2, 2, 110.00, '2021-07-01 10:45:00', '1234567890052', FALSE, FALSE), -- VIP ticket, Debit Card
    (28, 53, 1, 1, 55.00, '2021-07-02 11:15:00', '1234567890053', FALSE, FALSE),  -- General ticket, Credit Card
    (28, 54, 1, 3, 55.00, '2021-07-02 13:00:00', '1234567890054', FALSE, FALSE),  -- General ticket, Bank Transfer
    (28, 55, 1, 1, 55.00, '2021-07-03 09:15:00', '1234567890055', FALSE, FALSE),  -- General ticket, Credit Card
    (28, 56, 1, 2, 55.00, '2021-07-03 10:30:00', '1234567890056', FALSE, FALSE),  -- General ticket, Debit Card
    (28, 57, 2, 1, 110.00, '2021-07-04 11:00:00', '1234567890057', FALSE, FALSE), -- VIP ticket, Credit Card
    (28, 58, 1, 3, 55.00, '2021-07-04 12:15:00', '1234567890058', TRUE, FALSE),   -- General ticket, Bank Transfer (no-show)
    (28, 59, 1, 1, 55.00, '2021-07-05 09:30:00', '1234567890059', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (28, 60, 1, 2, 55.00, '2021-07-05 10:45:00', '1234567890060', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Festival 6: Sydney Opera Sounds 2022 - Event 33: Opera House Opening (2022 - Past event, most tickets used)
    (33, 61, 1, 1, 80.00, '2022-06-01 09:00:00', '1234567890061', FALSE, FALSE),  -- General ticket, Credit Card
    (33, 62, 2, 2, 160.00, '2022-06-01 10:15:00', '1234567890062', FALSE, FALSE), -- VIP ticket, Debit Card
    (33, 63, 1, 1, 80.00, '2022-06-02 11:30:00', '1234567890063', FALSE, FALSE),  -- General ticket, Credit Card
    (33, 64, 1, 3, 80.00, '2022-06-02 13:45:00', '1234567890064', FALSE, FALSE),  -- General ticket, Bank Transfer
    (33, 65, 3, 1, 220.00, '2022-06-03 09:15:00', '1234567890065', FALSE, FALSE), -- Backstage ticket, Credit Card
    (33, 66, 1, 2, 80.00, '2022-06-03 10:30:00', '1234567890066', FALSE, FALSE),  -- General ticket, Debit Card
    (33, 67, 2, 1, 160.00, '2022-06-04 11:45:00', '1234567890067', TRUE, FALSE),  -- VIP ticket, Credit Card (no-show)
    (33, 68, 1, 3, 80.00, '2022-06-04 14:00:00', '1234567890068', TRUE, FALSE),   -- General ticket, Bank Transfer (no-show)
    (33, 69, 1, 1, 80.00, '2022-06-05 09:30:00', '1234567890069', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (33, 70, 1, 2, 80.00, '2022-06-05 10:45:00', '1234567890070', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Festival 7: Thessaloniki Jazz Festival 2023 - Event 39: Thessaloniki Jazz Opening (2023 - Past event, some tickets used)
    (39, 71, 1, 1, 60.00, '2023-03-01 09:15:00', '1234567890071', FALSE, FALSE),  -- General ticket, Credit Card
    (39, 72, 2, 2, 120.00, '2023-03-01 10:30:00', '1234567890072', FALSE, FALSE), -- VIP ticket, Debit Card
    (39, 73, 1, 1, 60.00, '2023-03-02 11:45:00', '1234567890073', FALSE, FALSE),  -- General ticket, Credit Card
    (39, 74, 1, 3, 60.00, '2023-03-02 13:00:00', '1234567890074', FALSE, FALSE),  -- General ticket, Bank Transfer
    (39, 75, 3, 1, 180.00, '2023-03-03 09:30:00', '1234567890075', FALSE, FALSE), -- Backstage ticket, Credit Card
    (39, 76, 1, 2, 60.00, '2023-03-03 10:45:00', '1234567890076', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    (39, 77, 2, 1, 120.00, '2023-03-04 11:00:00', '1234567890077', TRUE, FALSE),  -- VIP ticket, Credit Card (no-show)
    (39, 78, 1, 3, 60.00, '2023-03-04 12:15:00', '1234567890078', TRUE, FALSE),   -- General ticket, Bank Transfer (no-show)
    (39, 79, 1, 1, 60.00, '2023-03-05 09:30:00', '1234567890079', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (39, 80, 1, 2, 60.00, '2023-03-05 10:45:00', '1234567890080', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Festival 8: Athens Reunion Festival 2024 - Event 45: Athens Opening Night 2024 (2024 - More recent past event, more unused tickets)
    (45, 81, 1, 1, 75.00, '2024-04-01 09:00:00', '1234567890081', FALSE, FALSE),  -- General ticket, Credit Card
    (45, 82, 2, 2, 150.00, '2024-04-01 10:15:00', '1234567890082', FALSE, FALSE), -- VIP ticket, Debit Card
    (45, 83, 1, 1, 75.00, '2024-04-02 11:30:00', '1234567890083', FALSE, FALSE),  -- General ticket, Credit Card
    (45, 84, 1, 3, 75.00, '2024-04-02 13:45:00', '1234567890084', FALSE, FALSE),  -- General ticket, Bank Transfer
    (45, 85, 3, 1, 210.00, '2024-04-03 09:15:00', '1234567890085', FALSE, FALSE), -- Backstage ticket, Credit Card
    (45, 86, 1, 2, 75.00, '2024-04-03 10:30:00', '1234567890086', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    (45, 87, 2, 1, 150.00, '2024-04-04 11:45:00', '1234567890087', TRUE, FALSE),  -- VIP ticket, Credit Card (no-show)
    (45, 88, 1, 3, 75.00, '2024-04-04 14:00:00', '1234567890088', TRUE, FALSE),   -- General ticket, Bank Transfer (no-show)
    (45, 89, 1, 1, 75.00, '2024-04-05 09:30:00', '1234567890089', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (45, 90, 1, 2, 75.00, '2024-04-05 10:45:00', '1234567890090', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Festival 9: New York World Music Heritage 2025 - Event 55: Future Opening Night (2025 - FUTURE EVENT, all tickets active)
    (55, 91, 1, 1, 85.00, '2025-01-15 09:00:00', '1234567890091', TRUE, FALSE),  -- General ticket, Credit Card
    (55, 92, 2, 2, 170.00, '2025-01-15 10:15:00', '1234567890092', TRUE, FALSE), -- VIP ticket, Debit Card
    (55, 93, 1, 1, 85.00, '2025-01-16 11:30:00', '1234567890093', TRUE, FALSE),  -- General ticket, Credit Card
    (55, 94, 1, 3, 85.00, '2025-01-16 13:45:00', '1234567890094', TRUE, FALSE),  -- General ticket, Bank Transfer
    (55, 95, 3, 1, 230.00, '2025-01-17 09:15:00', '1234567890095', TRUE, FALSE), -- Backstage ticket, Credit Card
    (55, 96, 1, 2, 85.00, '2025-01-17 10:30:00', '1234567890096', TRUE, FALSE),  -- General ticket, Debit Card
    (55, 97, 2, 1, 170.00, '2025-01-18 11:45:00', '1234567890097', TRUE, FALSE), -- VIP ticket, Credit Card
    (55, 98, 1, 3, 85.00, '2025-01-18 14:00:00', '1234567890098', TRUE, FALSE),  -- General ticket, Bank Transfer
    (55, 99, 1, 1, 85.00, '2025-01-19 09:30:00', '1234567890099', TRUE, FALSE),  -- General ticket, Credit Card
    (55, 100, 1, 2, 85.00, '2025-01-19 10:45:00', '1234567890100', TRUE, FALSE), -- General ticket, Debit Card
    
    -- Festival 10: Rio Summer Sounds 2026 - Event 65: Beach Opening Ceremony (2026 - FUTURE EVENT, all tickets active)
    (65, 101, 1, 1, 90.00, '2026-01-20 09:00:00', '1234567890101', TRUE, FALSE),  -- General ticket, Credit Card
    (65, 102, 2, 2, 180.00, '2026-01-20 10:15:00', '1234567890102', TRUE, FALSE), -- VIP ticket, Debit Card
    (65, 103, 1, 1, 90.00, '2026-01-21 11:30:00', '1234567890103', TRUE, FALSE),  -- General ticket, Credit Card
    (65, 104, 1, 3, 90.00, '2026-01-21 13:45:00', '1234567890104', TRUE, FALSE),  -- General ticket, Bank Transfer
    (65, 105, 3, 1, 250.00, '2026-01-22 09:15:00', '1234567890105', TRUE, FALSE), -- Backstage ticket, Credit Card
    (65, 106, 1, 2, 90.00, '2026-01-22 10:30:00', '1234567890106', TRUE, FALSE),  -- General ticket, Debit Card
    (65, 107, 2, 1, 180.00, '2026-01-23 11:45:00', '1234567890107', TRUE, FALSE), -- VIP ticket, Credit Card
    (65, 108, 1, 3, 90.00, '2026-01-23 14:00:00', '1234567890108', TRUE, FALSE),  -- General ticket, Bank Transfer
    (65, 109, 1, 1, 90.00, '2026-01-24 09:30:00', '1234567890109', TRUE, FALSE),  -- General ticket, Credit Card
    (65, 110, 1, 2, 90.00, '2026-01-24 10:45:00', '1234567890110', TRUE, FALSE);  -- General ticket, Debit Card

-- Adding more tickets to meet the 200 ticket requirement with realistic is_active values
INSERT INTO Ticket (event_id, visitor_id, category_id, method_id, price, purchase_date, EAN_code, is_active, resale_available)
VALUES
    -- More tickets for Festival 1 - Event 3: Dance Night Special (2017 - Past event)
    (3, 111, 1, 1, 55.00, '2017-06-01 09:00:00', '1234567890111', FALSE, FALSE),  -- General ticket, Credit Card
    (3, 112, 2, 2, 110.00, '2017-06-01 10:15:00', '1234567890112', FALSE, FALSE), -- VIP ticket, Debit Card
    (3, 113, 1, 1, 55.00, '2017-06-02 11:30:00', '1234567890113', FALSE, FALSE),  -- General ticket, Credit Card
    (3, 114, 1, 3, 55.00, '2017-06-02 13:45:00', '1234567890114', FALSE, FALSE),  -- General ticket, Bank Transfer
    (3, 115, 1, 1, 55.00, '2017-06-03 09:15:00', '1234567890115', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    
    -- More tickets for Festival 2 - Event 7: Rock Fusion (2018 - Past event)
    (7, 116, 1, 2, 60.00, '2018-05-01 10:30:00', '1234567890116', FALSE, FALSE),  -- General ticket, Debit Card
    (7, 117, 2, 1, 120.00, '2018-05-01 11:45:00', '1234567890117', FALSE, FALSE), -- VIP ticket, Credit Card
    (7, 118, 1, 3, 60.00, '2018-05-02 14:00:00', '1234567890118', FALSE, FALSE),  -- General ticket, Bank Transfer
    (7, 119, 1, 1, 60.00, '2018-05-02 09:30:00', '1234567890119', FALSE, FALSE),  -- General ticket, Credit Card
    (7, 120, 1, 2, 60.00, '2018-05-03 10:45:00', '1234567890120', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- More tickets for Festival 3 - Event 13: Sunset DJ Sets (2019 - Past event)
    (13, 121, 1, 1, 70.00, '2019-07-01 09:00:00', '1234567890121', FALSE, FALSE),  -- General ticket, Credit Card
    (13, 122, 2, 2, 140.00, '2019-07-01 10:15:00', '1234567890122', FALSE, FALSE), -- VIP ticket, Debit Card
    (13, 123, 1, 1, 70.00, '2019-07-02 11:30:00', '1234567890123', FALSE, FALSE),  -- General ticket, Credit Card
    (13, 124, 1, 3, 70.00, '2019-07-02 13:45:00', '1234567890124', FALSE, FALSE),  -- General ticket, Bank Transfer
    (13, 125, 3, 1, 200.00, '2019-07-03 09:15:00', '1234567890125', TRUE, FALSE),  -- Backstage ticket, Credit Card (no-show)
    
    -- More tickets for Festival 4 - Event 19: British Jazz Corner Night (2020 - Past event)
    (19, 126, 1, 2, 65.00, '2020-06-01 10:30:00', '1234567890126', FALSE, FALSE),  -- General ticket, Debit Card
    (19, 127, 2, 1, 130.00, '2020-06-01 11:45:00', '1234567890127', FALSE, FALSE), -- VIP ticket, Credit Card
    (19, 128, 1, 3, 65.00, '2020-06-02 14:00:00', '1234567890128', FALSE, FALSE),  -- General ticket, Bank Transfer
    (19, 129, 1, 1, 65.00, '2020-06-02 09:30:00', '1234567890129', FALSE, FALSE),  -- General ticket, Credit Card
    (19, 130, 1, 2, 65.00, '2020-06-03 10:45:00', '1234567890130', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- More tickets for Festival 5 - Event 29: Fusion Night (2021 - Past event)
    (29, 131, 1, 1, 55.00, '2021-08-01 09:00:00', '1234567890131', FALSE, FALSE),  -- General ticket, Credit Card
    (29, 132, 2, 2, 110.00, '2021-08-01 10:15:00', '1234567890132', FALSE, FALSE), -- VIP ticket, Debit Card
    (29, 133, 1, 1, 55.00, '2021-08-02 11:30:00', '1234567890133', FALSE, FALSE),  -- General ticket, Credit Card
    (29, 134, 1, 3, 55.00, '2021-08-02 13:45:00', '1234567890134', FALSE, FALSE),  -- General ticket, Bank Transfer
    (29, 135, 1, 1, 55.00, '2021-08-03 09:15:00', '1234567890135', TRUE, FALSE),   -- General ticket, Credit Card (no-show)

    -- More tickets for Festival 6 - Event 34: Harbor Views Night (2022 - Past event)
    (34, 136, 1, 2, 80.00, '2022-07-01 10:30:00', '1234567890136', FALSE, FALSE),  -- General ticket, Debit Card
    (34, 137, 2, 1, 160.00, '2022-07-01 11:45:00', '1234567890137', FALSE, FALSE), -- VIP ticket, Credit Card
    (34, 138, 1, 3, 80.00, '2022-07-02 14:00:00', '1234567890138', FALSE, FALSE),  -- General ticket, Bank Transfer
    (34, 139, 1, 1, 80.00, '2022-07-02 09:30:00', '1234567890139', FALSE, FALSE),  -- General ticket, Credit Card
    (34, 140, 1, 2, 80.00, '2022-07-03 10:45:00', '1234567890140', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- More tickets for Festival 7 - Event 40: Fusion Night (2023 - Past event, more recent so more no-shows)
    (40, 141, 1, 1, 60.00, '2023-04-01 09:00:00', '1234567890141', FALSE, FALSE),  -- General ticket, Credit Card
    (40, 142, 2, 2, 120.00, '2023-04-01 10:15:00', '1234567890142', FALSE, FALSE), -- VIP ticket, Debit Card
    (40, 143, 1, 1, 60.00, '2023-04-02 11:30:00', '1234567890143', FALSE, FALSE),  -- General ticket, Credit Card
    (40, 144, 1, 3, 60.00, '2023-04-02 13:45:00', '1234567890144', TRUE, FALSE),   -- General ticket, Bank Transfer (no-show)
    (40, 145, 1, 1, 60.00, '2023-04-03 09:15:00', '1234567890145', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    
    -- More tickets for Festival 8 - Event 46: DJ Night (2024 - Most recent past event, more no-shows)
    (46, 146, 1, 2, 75.00, '2024-05-01 10:30:00', '1234567890146', FALSE, FALSE),  -- General ticket, Debit Card
    (46, 147, 2, 1, 150.00, '2024-05-01 11:45:00', '1234567890147', FALSE, FALSE), -- VIP ticket, Credit Card
    (46, 148, 1, 3, 75.00, '2024-05-02 14:00:00', '1234567890148', TRUE, FALSE),   -- General ticket, Bank Transfer (no-show)
    (46, 149, 1, 1, 75.00, '2024-05-02 09:30:00', '1234567890149', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (46, 150, 1, 2, 75.00, '2024-05-03 10:45:00', '1234567890150', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- More tickets for Festival 9 - Event 56: Heritage Night (2025 - FUTURE EVENT, all tickets active)
    (56, 151, 1, 1, 85.00, '2025-02-01 09:00:00', '1234567890151', TRUE, FALSE),  -- General ticket, Credit Card
    (56, 152, 2, 2, 170.00, '2025-02-01 10:15:00', '1234567890152', TRUE, FALSE), -- VIP ticket, Debit Card
    (56, 153, 1, 1, 85.00, '2025-02-02 11:30:00', '1234567890153', TRUE, FALSE),  -- General ticket, Credit Card
    (56, 154, 1, 3, 85.00, '2025-02-02 13:45:00', '1234567890154', TRUE, FALSE),  -- General ticket, Bank Transfer
    (56, 155, 1, 1, 85.00, '2025-02-03 09:15:00', '1234567890155', TRUE, FALSE),  -- General ticket, Credit Card
    
    -- More tickets for Festival 10 - Event 66: Acoustic Night (2026 - FUTURE EVENT, all tickets active)
    (66, 156, 1, 2, 90.00, '2026-02-01 10:30:00', '1234567890156', TRUE, FALSE),  -- General ticket, Debit Card
    (66, 157, 2, 1, 180.00, '2026-02-01 11:45:00', '1234567890157', TRUE, FALSE), -- VIP ticket, Credit Card
    (66, 158, 1, 3, 90.00, '2026-02-02 14:00:00', '1234567890158', TRUE, FALSE),  -- General ticket, Bank Transfer
    (66, 159, 1, 1, 90.00, '2026-02-02 09:30:00', '1234567890159', TRUE, FALSE),  -- General ticket, Credit Card
    (66, 160, 1, 2, 90.00, '2026-02-03 10:45:00', '1234567890160', TRUE, FALSE),  -- General ticket, Debit Card
    
    -- Add tickets for Event 4: Sunset Acoustics (2017 - Past event)
    (4, 161, 1, 1, 55.00, '2017-06-15 09:00:00', '1234567890161', FALSE, FALSE),  -- General ticket, Credit Card
    (4, 162, 2, 2, 110.00, '2017-06-15 10:15:00', '1234567890162', FALSE, FALSE), -- VIP ticket, Debit Card
    (4, 163, 1, 1, 55.00, '2017-06-16 11:30:00', '1234567890163', FALSE, FALSE),  -- General ticket, Credit Card
    (4, 164, 1, 3, 55.00, '2017-06-16 13:45:00', '1234567890164', FALSE, FALSE),  -- General ticket, Bank Transfer
    (4, 165, 1, 1, 55.00, '2017-06-17 09:15:00', '1234567890165', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    
    -- Add tickets for Event 5: Grand Finale (2017 - Past event)
    (5, 166, 1, 2, 60.00, '2017-06-20 10:30:00', '1234567890166', FALSE, FALSE),  -- General ticket, Debit Card
    (5, 167, 2, 1, 120.00, '2017-06-20 11:45:00', '1234567890167', FALSE, FALSE), -- VIP ticket, Credit Card
    (5, 168, 1, 3, 60.00, '2017-06-21 14:00:00', '1234567890168', FALSE, FALSE),  -- General ticket, Bank Transfer
    (5, 169, 1, 1, 60.00, '2017-06-21 09:30:00', '1234567890169', FALSE, FALSE),  -- General ticket, Credit Card
    (5, 170, 1, 2, 60.00, '2017-06-22 10:45:00', '1234567890170', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Add tickets for Event 8: Acoustic Sessions (2018 - Past event)
    (8, 171, 1, 1, 60.00, '2018-05-10 09:00:00', '1234567890171', FALSE, FALSE),  -- General ticket, Credit Card
    (8, 172, 2, 2, 120.00, '2018-05-10 10:15:00', '1234567890172', FALSE, FALSE), -- VIP ticket, Debit Card
    (8, 173, 1, 1, 60.00, '2018-05-11 11:30:00', '1234567890173', FALSE, FALSE),  -- General ticket, Credit Card
    (8, 174, 1, 3, 60.00, '2018-05-11 13:45:00', '1234567890174', FALSE, FALSE),  -- General ticket, Bank Transfer
    (8, 175, 1, 1, 60.00, '2018-05-12 09:15:00', '1234567890175', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    
    -- Add tickets for Event 14: Dance Pop Night (2019 - Past event)
    (14, 176, 1, 2, 70.00, '2019-07-10 10:30:00', '1234567890176', FALSE, FALSE),  -- General ticket, Debit Card
    (14, 177, 2, 1, 140.00, '2019-07-10 11:45:00', '1234567890177', FALSE, FALSE), -- VIP ticket, Credit Card
    (14, 178, 1, 3, 70.00, '2019-07-11 14:00:00', '1234567890178', FALSE, FALSE),  -- General ticket, Bank Transfer
    (14, 179, 1, 1, 70.00, '2019-07-11 09:30:00', '1234567890179', FALSE, FALSE),  -- General ticket, Credit Card
    (14, 180, 1, 2, 70.00, '2019-07-12 10:45:00', '1234567890180', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Add tickets for Event 20: Greek Night in London (2020 - Past event)
    (20, 181, 1, 1, 65.00, '2020-06-15 09:00:00', '1234567890181', FALSE, FALSE),  -- General ticket, Credit Card
    (20, 182, 2, 2, 130.00, '2020-06-15 10:15:00', '1234567890182', FALSE, FALSE), -- VIP ticket, Debit Card
    (20, 183, 1, 1, 65.00, '2020-06-16 11:30:00', '1234567890183', FALSE, FALSE),  -- General ticket, Credit Card
    (20, 184, 1, 3, 65.00, '2020-06-16 13:45:00', '1234567890184', FALSE, FALSE),  -- General ticket, Bank Transfer
    (20, 185, 1, 1, 65.00, '2020-06-17 09:15:00', '1234567890185', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    
    -- Add tickets for Event 30: Greek Street Music (2021 - Past event)
    (30, 186, 1, 2, 55.00, '2021-08-10 10:30:00', '1234567890186', FALSE, FALSE),  -- General ticket, Debit Card
    (30, 187, 2, 1, 110.00, '2021-08-10 11:45:00', '1234567890187', FALSE, FALSE), -- VIP ticket, Credit Card
    (30, 188, 1, 3, 55.00, '2021-08-11 14:00:00', '1234567890188', FALSE, FALSE),  -- General ticket, Bank Transfer
    (30, 189, 1, 1, 55.00, '2021-08-11 09:30:00', '1234567890189', FALSE, FALSE),  -- General ticket, Credit Card
    (30, 190, 1, 2, 55.00, '2021-08-12 10:45:00', '1234567890190', TRUE, FALSE),   -- General ticket, Debit Card (no-show)
    
    -- Add tickets for Event 35: Australian-Greek Fusion (2022 - Past event)
    (35, 191, 1, 1, 80.00, '2022-07-10 09:00:00', '1234567890191', FALSE, FALSE),  -- General ticket, Credit Card
    (35, 192, 2, 2, 160.00, '2022-07-10 10:15:00', '1234567890192', FALSE, FALSE), -- VIP ticket, Debit Card
    (35, 193, 1, 1, 80.00, '2022-07-11 11:30:00', '1234567890193', FALSE, FALSE),  -- General ticket, Credit Card
    (35, 194, 1, 3, 80.00, '2022-07-11 13:45:00', '1234567890194', FALSE, FALSE),  -- General ticket, Bank Transfer
    (35, 195, 1, 1, 80.00, '2022-07-12 09:15:00', '1234567890195', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    
    -- Add tickets for Event 41: Greek Traditional (2023 - Past event, more recent so more no-shows)
    (41, 196, 1, 2, 60.00, '2023-04-10 10:30:00', '1234567890196', FALSE, FALSE),  -- General ticket, Debit Card
    (41, 197, 2, 1, 120.00, '2023-04-10 11:45:00', '1234567890197', FALSE, FALSE), -- VIP ticket, Credit Card
    (41, 198, 1, 3, 60.00, '2023-04-11 14:00:00', '1234567890198', TRUE, FALSE),   -- General ticket, Bank Transfer (no-show)
    (41, 199, 1, 1, 60.00, '2023-04-11 09:30:00', '1234567890199', TRUE, FALSE),   -- General ticket, Credit Card (no-show)
    (41, 200, 1, 2, 60.00, '2023-04-12 10:45:00', '1234567890200', TRUE, FALSE);   -- General ticket, Debit Card (no-show)


-- Add more tickets for specific visitors to create matching attendance patterns
-- First group: 4 attendances each in 2023
INSERT INTO Ticket (event_id, visitor_id, category_id, method_id, price, purchase_date, EAN_code, is_active, resale_available)
VALUES 
    -- Visitor 31: 4 attendances in 2023
    (39, 31, 1, 1, 60.00, '2023-01-15 10:00:00', '2023000000301', FALSE, FALSE),
    (40, 31, 1, 1, 60.00, '2023-02-15 10:00:00', '2023000000302', FALSE, FALSE),
    (41, 31, 1, 1, 60.00, '2023-03-15 10:00:00', '2023000000303', FALSE, FALSE),
    (42, 31, 1, 1, 60.00, '2023-04-15 10:00:00', '2023000000304', FALSE, FALSE),
    
    -- Visitor 32: 4 attendances in 2023
    (39, 32, 1, 1, 60.00, '2023-01-20 11:00:00', '2023000000321', FALSE, FALSE),
    (40, 32, 1, 1, 60.00, '2023-02-20 11:00:00', '2023000000322', FALSE, FALSE),
    (41, 32, 1, 1, 60.00, '2023-03-20 11:00:00', '2023000000323', FALSE, FALSE),
    (42, 32, 1, 1, 60.00, '2023-04-20 11:00:00', '2023000000324', FALSE, FALSE),
    
    -- Second group: 5 attendances each in 2022
    -- Visitor 33: 5 attendances in 2022
    (33, 33, 1, 1, 75.00, '2022-06-10 10:00:00', '2022000000331', FALSE, FALSE),
    (34, 33, 1, 1, 75.00, '2022-06-10 10:00:00', '2022000000332', FALSE, FALSE),
    (35, 33, 1, 1, 75.00, '2022-06-10 10:00:00', '2022000000333', FALSE, FALSE),
    (36, 33, 1, 1, 75.00, '2022-06-10 10:00:00', '2022000000334', FALSE, FALSE),
    (37, 33, 1, 1, 75.00, '2022-06-10 10:00:00', '2022000000335', FALSE, FALSE),
    
    -- Visitor 34: 5 attendances in 2022
    (33, 34, 1, 1, 75.00, '2022-06-12 14:00:00', '2022000000341', FALSE, FALSE),
    (34, 34, 1, 1, 75.00, '2022-06-12 14:00:00', '2022000000342', FALSE, FALSE),
    (35, 34, 1, 1, 75.00, '2022-06-12 14:00:00', '2022000000343', FALSE, FALSE),
    (36, 34, 1, 1, 75.00, '2022-06-12 14:00:00', '2022000000344', FALSE, FALSE),
    (37, 34, 1, 1, 75.00, '2022-06-12 14:00:00', '2022000000345', FALSE, FALSE),
    
    -- Visitor 35: 5 attendances in 2022
    (33, 35, 1, 1, 75.00, '2022-06-15 09:00:00', '2022000000351', FALSE, FALSE),
    (34, 35, 1, 1, 75.00, '2022-06-15 09:00:00', '2022000000352', FALSE, FALSE),
    (35, 35, 1, 1, 75.00, '2022-06-15 09:00:00', '2022000000353', FALSE, FALSE),
    (36, 35, 1, 1, 75.00, '2022-06-15 09:00:00', '2022000000354', FALSE, FALSE),
    (37, 35, 1, 1, 75.00, '2022-06-15 09:00:00', '2022000000355', FALSE, FALSE);

-- Set some tickets to be available for resale
UPDATE Ticket
SET resale_available = TRUE
WHERE ticket_id IN (93, 94, 95, 96, 97)
AND is_active = TRUE;

-- =================================================================
-- TICKET RESALE QUEUE
-- =================================================================
-- Implements the ticket resale FIFO queue system 
-- Allows tickets to be transferred between visitors
-- Status values: Available(1), Sold(2), Pending(3), Cancelled(4)
INSERT INTO ResaleQueue (ticket_id, seller_id, status_id, request_date)
SELECT 
    ticket_id, 
    visitor_id, 
    1, -- Status ID 1 corresponds to 'Available' in the ResaleStatus table
    NOW() -- Current timestamp for request_date
FROM Ticket
WHERE ticket_id IN (93, 94, 95, 96, 97)
AND resale_available = TRUE;

-- Example: Ticket #97 is being purchased by visitor #150
UPDATE ResaleQueue
SET 
    buyer_id = 150,
    status_id = 2, -- Status ID 2 corresponds to 'Sold' in the ResaleStatus table
    updated_at = NOW()
WHERE ticket_id = 97
AND status_id = 1; -- Only update if currently available

-- Add a visitor to the ResaleQueue table with status_id=3 (Pending)
INSERT INTO ResaleQueue (ticket_id, seller_id, buyer_id, status_id, request_date)
SELECT 
    t.ticket_id,                -- The ticket being requested
    t.visitor_id AS seller_id,  -- Current owner (seller)
    95 AS buyer_id,             -- ID of the visitor who wants to buy the ticket (replace with actual ID)
    3 AS status_id,             -- Status 3 = "Pending" based on your schema
    NOW() AS request_date       -- Current timestamp
FROM Ticket t
WHERE t.ticket_id = 94          -- The specific ticket ID (replace with actual ticket ID)
  AND t.resale_available = TRUE -- Only if the ticket is available for resale
  AND t.is_active = TRUE;       -- Only if the ticket is still active

--Additional ResaleQueue entries for better test coverage
INSERT INTO ResaleQueue (ticket_id, seller_id, buyer_id, status_id, request_date)
VALUES
    -- Add more pending purchase requests
    (95, 95, 160, 3, NOW() - INTERVAL 1 DAY), -- Earlier request (higher priority in FIFO)
    (95, 95, 161, 3, NOW() - INTERVAL 2 DAY); -- Earliest request (highest priority in FIFO)

-- Make some more tickets available for resale
UPDATE Ticket
SET resale_available = TRUE
WHERE ticket_id IN (151, 152, 157, 159)
AND is_active = TRUE;

-- Add corresponding ResaleQueue entries for newly available tickets
INSERT INTO ResaleQueue (ticket_id, seller_id, status_id, request_date)
SELECT 
    ticket_id, 
    visitor_id, 
    1, -- Available status
    NOW() 
FROM Ticket
WHERE ticket_id IN (151, 152, 157, 159)
AND resale_available = TRUE;

  -- To request to buy a ticket
CALL request_to_buy_ticket(93, 150);

-- For a seller to view pending requests
CALL view_pending_requests(93);

-- For a seller to approve a request
CALL approve_purchase_request(9);

CALL request_to_buy_ticket(96, 151);
CALL view_pending_requests(96);
-- For a seller to reject a request
CALL reject_purchase_request(10);

-- To view notifications
CALL get_visitor_notifications(150, FALSE);

-- To mark a notification as read
CALL mark_notification_read(1, 150);

-- To view audit log for a ticket
CALL get_ticket_audit_log(93);


SELECT event_id, CEIL(COUNT(*) * 0.05) AS required_security_staff
FROM Ticket
WHERE is_active = TRUE
GROUP BY event_id;

-- =================================================================
-- STAFF ASSIGNMENTS FOR EVENTS
-- =================================================================
-- Assigns staff to events based on required roles and experience levels
-- Ensures adequate security coverage (5% of visitors) and support coverage (2% of visitors)

/*
 * Stage capacity adjustment: To maintain realistic staffing requirements, the 
 * capacity values have been capped at reasonable levels:
 * - Small venues: <= 800 (unchanged)
 * - Medium venues: 1,000
 * - Large venues: 2,000
 * - Very large venues: 3,000
 * 
 * This ensures the 5% security and 2% support staff requirements can be met 
 * with a realistic number of staff members.
 */
 -- Cap extremely large capacities (30,000+) to 3,000
UPDATE Stage 
SET capacity = 3000 
WHERE capacity > 10000;

-- Cap large capacities (5,000-10,000) to 2,000
UPDATE Stage 
SET capacity = 2000 
WHERE capacity BETWEEN 5000 AND 10000;

-- Cap medium capacities (1,000-5,000) to 1,000
UPDATE Stage 
SET capacity = 1000 
WHERE capacity BETWEEN 1000 AND 4999;

--Check Staffing Requirements
SELECT 
    e.event_id,
    e.name AS event_name,
    s.capacity AS stage_capacity,
    GREATEST(CEIL(s.capacity * 0.05), 1) AS required_security,
    (SELECT COUNT(*) FROM Staff_Assignment sa 
     JOIN Staff st ON sa.staff_id = st.staff_id 
     WHERE sa.event_id = e.event_id AND st.role_id = 2) AS actual_security,
    CEIL(s.capacity * 0.02) AS required_support,
    (SELECT COUNT(*) FROM Staff_Assignment sa 
     JOIN Staff st ON sa.staff_id = st.staff_id 
     WHERE sa.event_id = e.event_id AND st.role_id = 3) AS actual_support
FROM 
    Event e
JOIN 
    Stage s ON e.stage_id = s.stage_id
ORDER BY 
    e.event_id;

-- Add more security staff
INSERT INTO Staff (name, age, role_id, level_id)
WITH staff_numbers AS (
    SELECT ROW_NUMBER() OVER () as i 
    FROM information_schema.columns 
    LIMIT 400
)
SELECT 
    CONCAT('Security Staff ', i), 
    25 + (i % 20), -- Age between 25 and 44
    2, -- Security role
    1 + (i % 5) -- Random experience level 1-5
FROM staff_numbers
WHERE CONCAT('Security Staff ', i) NOT IN (
    SELECT name FROM Staff WHERE role_id = 2
);

-- Add more support staff
INSERT INTO Staff (name, age, role_id, level_id)
WITH staff_numbers AS (
    SELECT ROW_NUMBER() OVER () as i 
    FROM information_schema.columns 
    LIMIT 50
)
SELECT 
    CONCAT('Support Staff ', i), 
    22 + (i % 25), -- Age between 22 and 46
    3, -- Support role
    1 + (i % 5) -- Random experience level 1-5
FROM staff_numbers
WHERE CONCAT('Support Staff ', i) NOT IN (
    SELECT name FROM Staff WHERE role_id = 3
);

--Assigns staff to all events based on the required staffing levels:
-- - Security staff: 5% of stage capacity (minimum 1)
-- - Support staff: 2% of stage capacity (minimum 1)
-- - Technical staff: Fixed at 3 per event

DELIMITER //
CREATE PROCEDURE assign_all_event_staff()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE curr_event_id INT;
    DECLARE curr_event_name VARCHAR(100);
    DECLARE curr_capacity INT;
    DECLARE required_security INT;
    DECLARE required_support INT;
    DECLARE event_start TIME;
    DECLARE event_end TIME;
    
    -- Count how many staff we have
    DECLARE total_security_staff INT;
    DECLARE total_support_staff INT;
    DECLARE total_technical_staff INT;
    
    -- Cursor for events
    DECLARE event_cursor CURSOR FOR
        SELECT e.event_id, e.name, s.capacity, e.start_time, e.end_time
        FROM Event e
        JOIN Stage s ON e.stage_id = s.stage_id
        ORDER BY e.event_id;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Count available staff by role
    SELECT COUNT(*) INTO total_security_staff FROM Staff WHERE role_id = 2;
    SELECT COUNT(*) INTO total_support_staff FROM Staff WHERE role_id = 3;
    SELECT COUNT(*) INTO total_technical_staff FROM Staff WHERE role_id = 1;
    
    -- Output staff counts for debugging
    SELECT 
        CONCAT('Available staff: ', 
               total_security_staff, ' security, ', 
               total_support_staff, ' support, ', 
               total_technical_staff, ' technical') AS staff_count;
    
    OPEN event_cursor;
    
    event_loop: LOOP
        FETCH event_cursor INTO curr_event_id, curr_event_name, curr_capacity, event_start, event_end;
        
        IF done THEN
            LEAVE event_loop;
        END IF;
        
        -- Calculate required staff numbers
        SET required_security = GREATEST(CEILING(curr_capacity * 0.05), 1);
        SET required_support = GREATEST(CEILING(curr_capacity * 0.02), 1);
        
        -- Add security staff (role_id = 2)
        -- Use direct insert with MOD to ensure we cycle through available staff
        INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
        SELECT 
            staff_id,
            curr_event_id,
            2, -- Security role
            SUBTIME(event_start, '01:30:00'),
            ADDTIME(event_end, '00:30:00')
        FROM (
            SELECT 
                staff_id,
                ROW_NUMBER() OVER (ORDER BY staff_id) AS row_num
            FROM Staff
            WHERE role_id = 2
        ) AS security_staff
        WHERE row_num <= required_security;
        
        -- Add support staff (role_id = 3)
        INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
        SELECT 
            staff_id,
            curr_event_id,
            3, -- Support role
            SUBTIME(event_start, '01:00:00'),
            ADDTIME(event_end, '00:30:00')
        FROM (
            SELECT 
                staff_id,
                ROW_NUMBER() OVER (ORDER BY staff_id) AS row_num
            FROM Staff
            WHERE role_id = 3
        ) AS support_staff
        WHERE row_num <= required_support;
        
        -- Add technical staff (role_id = 1)
        INSERT INTO Staff_Assignment (staff_id, event_id, role_id, shift_start, shift_end)
        SELECT 
            staff_id,
            curr_event_id,
            1, -- Technical role
            SUBTIME(event_start, '02:00:00'),
            ADDTIME(event_end, '01:00:00')
        FROM (
            SELECT 
                staff_id,
                ROW_NUMBER() OVER (ORDER BY staff_id) AS row_num
            FROM Staff
            WHERE role_id = 1
        ) AS technical_staff
        WHERE row_num <= 3; -- We always want 3 technical staff
        
        -- Log progress
        SELECT CONCAT('Added staff for event ID ', curr_event_id, ': ', curr_event_name) AS progress;
    END LOOP;
    
    CLOSE event_cursor;
    
    -- Final count of assignments
    SELECT 
        COUNT(DISTINCT event_id) AS total_events_staffed,
        SUM(CASE WHEN role_id = 2 THEN 1 ELSE 0 END) AS total_security_assignments,
        SUM(CASE WHEN role_id = 3 THEN 1 ELSE 0 END) AS total_support_assignments,
        SUM(CASE WHEN role_id = 1 THEN 1 ELSE 0 END) AS total_technical_assignments
    FROM Staff_Assignment;
END //
DELIMITER ;

CALL assign_all_event_staff();

-- Check again the staffing requirements
SELECT 
    e.event_id,
    e.name AS event_name,
    s.capacity AS stage_capacity,
    GREATEST(CEIL(s.capacity * 0.05), 1) AS required_security,
    (SELECT COUNT(*) FROM Staff_Assignment sa 
     JOIN Staff st ON sa.staff_id = st.staff_id 
     WHERE sa.event_id = e.event_id AND st.role_id = 2) AS actual_security,
    CEIL(s.capacity * 0.02) AS required_support,
    (SELECT COUNT(*) FROM Staff_Assignment sa
     JOIN Staff st ON sa.staff_id = st.staff_id 
     WHERE sa.event_id = e.event_id AND st.role_id = 3) AS actual_support,
    (SELECT COUNT(*) FROM Staff_Assignment sa
     JOIN Staff st ON sa.staff_id = st.staff_id 
     WHERE sa.event_id = e.event_id AND st.role_id = 1) AS actual_technical
FROM
    Event e
JOIN
    Stage s ON e.stage_id = s.stage_id
ORDER BY
    e.event_id;

-- Optional: Drop the procedure after use
DROP PROCEDURE IF EXISTS assign_all_event_staff;

-- =================================================================
-- PERFORMANCE REVIEWS BY VISITORS
-- =================================================================
-- Reviews submitted by visitors who attended performances (used tickets)
-- Rating scale 1-5 for each category (Likert scale)
-- Only visitors with used tickets can submit reviews (enforced by business rule)
CREATE TEMPORARY TABLE valid_review_combinations AS
SELECT DISTINCT
    t.visitor_id,
    p.performance_id
FROM 
    Ticket t
JOIN 
    Event e ON t.event_id = e.event_id
JOIN 
    Performance p ON e.event_id = p.event_id
WHERE 
    t.is_active = FALSE -- Only used tickets
    AND NOT EXISTS (
        SELECT 1 FROM Review r
        WHERE r.visitor_id = t.visitor_id
        AND r.performance_id = p.performance_id
    );

-- See how many combinations we found
SELECT COUNT(*) AS valid_combinations FROM valid_review_combinations;

-- Verify we have some data to work with
SELECT * FROM valid_review_combinations LIMIT 20;

-- Insert reviews directly using these valid combinations
INSERT INTO Review (visitor_id, performance_id, artist_rating, sound_rating, stage_rating, organization_rating, overall_rating)
SELECT 
    visitor_id,
    performance_id,
    3 + (RAND() * 2) AS artist_rating,        -- Random rating 3-5
    3 + (RAND() * 2) AS sound_rating,         -- Random rating 3-5
    3 + (RAND() * 2) AS stage_rating,         -- Random rating 3-5
    3 + (RAND() * 2) AS organization_rating,  -- Random rating 3-5
    3 + (RAND() * 2) AS overall_rating        -- Random rating 3-5
FROM 
    valid_review_combinations
LIMIT 60; -- Add up to 60 reviews

-- Add some high ratings for specific artists to support Query #15
-- First identify valid combinations for specific artists/bands
INSERT INTO Review (visitor_id, performance_id, artist_rating, sound_rating, stage_rating, organization_rating, overall_rating)
SELECT 
    vrc.visitor_id,
    vrc.performance_id,
    5 AS artist_rating,
    5 AS sound_rating,
    5 AS stage_rating,
    5 AS organization_rating,
    5 AS overall_rating
FROM 
    valid_review_combinations vrc
JOIN 
    Performance p ON vrc.performance_id = p.performance_id
WHERE 
    (p.artist_id IN (9, 2, 6, 34, 28) OR p.band_id IN (1, 2, 3)) -- Popular artists/bands
    AND NOT EXISTS (
        SELECT 1 FROM Review r
        WHERE r.visitor_id = vrc.visitor_id
        AND r.performance_id = vrc.performance_id
    )
LIMIT 25; -- Add up to 25 high-rated reviews for popular artists

-- Check how many reviews we've added
SELECT COUNT(*) FROM Review;

-- Ensure we have at least 5 visitors who have multiple reviews (for Query #6)
WITH ReviewCounts AS (
    SELECT 
        visitor_id,
        COUNT(*) AS review_count
    FROM 
        Review
    GROUP BY 
        visitor_id
    HAVING 
        COUNT(*) >= 2
)
SELECT COUNT(*) AS visitors_with_multiple_reviews FROM ReviewCounts;


-- Drop the temporary table
DROP TEMPORARY TABLE IF EXISTS valid_review_combinations;

-- =================================================================
-- MULTIMEDIA CONTENT (IMAGES)
-- =================================================================
-- Images linked to entities (artists, bands, stages, festivals) with descriptions
-- Supports website development with visual content
INSERT INTO Image (entity_type, entity_id, image_url, description)
VALUES 
    -- Artist images
    ('artist', 1, 'https://www.in.gr/wp-content/uploads/2024/10/jOHN.jpg', 'Giannis Parios (Parios) official photo'),
    ('artist', 2, 'https://www.tlife.gr/wp-content/uploads/2024/10/vissi-3.jpg', 'Anna Vissi official portrait'),
    ('artist', 3, 'https://www.tovima.gr/wp-content/uploads/2021/01/23/thumbnail_MILTOS-PASXALIDIS-e1611408779693.jpg', 'Miltos Paschalidis portrait'),
    ('artist', 4, 'https://upload.wikimedia.org/wikipedia/commons/d/d1/Haris_Alexiou_2080202_%28cropped%29.JPG', 'Haris Alexiou official photo'),
    ('artist', 5, 'https://outnow.gr/wp-content/uploads/2019/10/nikos-vertis-1024x535.jpg.webp', 'Nikos Vertis performing'),
    ('artist', 6, 'https://www.tovima.gr/wp-content/uploads/2021/03/05/thumbnail_%CE%96ouganeli-NIKOS-PALIOPOULOS-e1614945534789.jpg', 'Eleonora Zouganeli portrait'),
    ('artist', 7, 'https://www.in.gr/wp-content/uploads/2023/06/giorgos-mazonakis21.jpg', 'Giorgos Mazonakis performing'),
    ('artist', 8, 'https://i1.prth.gr/images/640x640/jpg/files/2025-04-24/xrwma-lex.jpg', 'Alexis Lanaras (Lex) portrait'),
    ('artist', 9, 'https://i1.prth.gr/images/1168x656/jpg/files/2024-02-22/papkonstantinoy-26.jpg', 'Vasilis Papakonstantinou on stage'),
    ('artist', 10, 'https://www.tovima.gr/wp-content/uploads/2023/04/24/%CE%A3%CE%91%CE%92%CE%92%CE%9F%CE%A0%CE%9F%CE%A5%CE%9B%CE%9F%CE%A3-e1684915670939.jpg', 'Dionysis Savvopoulos portrait'),
    ('artist', 11, 'https://m.media-amazon.com/images/M/MV5BODg3NTY2N2YtYzlmNy00NjA4LWFjMmMtMDg1ODg1OTk0ZGIyXkEyXkFqcGc@._V1_FMjpg_UX1000_.jpg', 'Kaiti Garbi official photo'),
    ('artist', 12, 'https://m.media-amazon.com/images/M/MV5BODVhMTA3ZDAtMDNjZS00MDgwLWE5NjItMjEwYTZmN2NlY2RiXkEyXkFqcGc@._V1_.jpg', 'Michalis Hatzigiannis portrait'),
    ('artist', 13, 'https://mikrofwno.gr/wp-content/uploads/2019/02/evridiki-afierwma-mikrofwno.jpg', 'Evridiki Theokleous performing'),
    ('artist', 14, 'https://www.lifo.gr/sites/default/files/styles/max_1920x1920/public/articles/2023-04-09/despoina-vandi.png?itok=uXm7C-wY', 'Despina Malea (Vandi) portrait'),
    ('artist', 15, 'https://www.news247.gr/wp-content/uploads/2020/08/6215_pantelis_thalasinos_24062019-640x380.jpg', 'Pantelis Thalassinos official photo'),
    ('artist', 16, 'https://metrosportgr.cachefly.net/portal-img/post-large/399/lepa.jpg', 'Lefteris Pantazis (Lepa) portrait'),
    ('artist', 17, 'https://www.kratisinow.gr/wp-content/uploads/2022/11/club22-kiamos-2023-2024.jpg', 'Panos Kiamos performing'),
    ('artist', 18, 'https://i1.prth.gr/images/1168x656/jpg/files/2020-05-27/Natasa-Theodoridou_2.jpg', 'Natasa Theodoridou portrait'),
    ('artist', 19, 'https://i1.prth.gr/images/1168x656/2/jpg/files/2024-07-05/antonis-remos-xr.jpg', 'Antonis Paschalidi (Remos) on stage'),
    ('artist', 20, 'https://outnow.gr/wp-content/uploads/2019/10/stelios-rokkos.jpg', 'Stelios Rokkos performing'),
    ('artist', 21, 'https://www.tanea.gr/wp-content/uploads/2025/01/pasxalis-terzis.jpg', 'Paschalis Terzis portrait'),
    ('artist', 22, 'https://upload.wikimedia.org/wikipedia/commons/d/db/Foivos_Delivorias.JPG', 'Foivos Delivorias official photo'),
    ('artist', 23, 'https://www.athens24.gr/media/cache/large_article_image/custom/domain_1/image_files/thodoris-ferris-nikos-apergis-sto-posidonio-music-hall_photo_33715.jpg', 'Thodoris Ferris (Ferris) portrait'),
    ('artist', 24, 'https://framerusercontent.com/images/UmskVonXYHOArK9AjfD5lWBa54.jpeg', 'Anastasios Rouvas (Saksi) performing'),
    ('artist', 25, 'https://ekefalonia.gr/wp-content/uploads/2024/04/9e5bd963-Elena-Paparizou-cover.jpg', 'Elena Paparizou official portrait'),
    ('artist', 26, 'https://upload.wikimedia.org/wikipedia/commons/9/99/Dalaras_live.jpg', 'Giorgos Dalaras performing live'),
    ('artist', 27, 'https://www.tlife.gr/wp-content/uploads/2022/07/foureira-1-1-large.jpg', 'Entela Fureraj (Eleni Foureira) portrait'),
    ('artist', 28, 'https://media.ladylike.gr/ldl-images/mariza-rizou-4.jpg', 'Mariza Rizou on stage'),
    ('artist', 29, 'https://www.in.gr/wp-content/uploads/2024/03/thodoris-marantinis.jpg', 'Thodoris Marantinis portrait'),
    ('artist', 30, 'https://www.greece2021.gr/images/27.-%CE%98%CE%AC%CE%BD%CE%BF%CF%82-%CE%9C%CE%B9%CE%BA%CF%81%CE%BF%CF%8D%CF%84%CF%83%CE%B9%CE%BA%CE%BF%CF%82-min.jpg', 'Thanos Mikroutsikos official photo'),
    ('artist', 31, 'https://musichunter.gr/wp-content/uploads/2024/02/babis-stokas-pix-lax-interview.jpg', 'Babis Stokas portrait'),
    ('artist', 32, 'https://i1.prth.gr/images/1168x656/jpg/files/2025-03-21/malamas.jpg', 'Sokratis Malamas performing'),
    ('artist', 33, 'https://www.ticketservices.gr/pictures/original/b_20527_or_Untitled-1.jpg', 'Christos Thivaios portrait'),
    ('artist', 34, 'https://i.ytimg.com/vi/7MGvimxssMc/hqdefault.jpg', 'Christos Mastoras (Mastoras) official photo'),
    ('artist', 35, 'https://upload.wikimedia.org/wikipedia/commons/6/68/Nikos_Portokaloglou_III.JPG', 'Nikos Portokaloglou on stage'),
    ('artist', 36, 'https://images.loaded.gr/img/path/5380a3da-b073-46b9-93c8-03ce3fd41119_ee79d33c-6185-460a-9f3c-90ddb28b32fc_%CE%9C%CE%BF%CF%85%CF%83%CE%B9%CE%BA%CE%AE_%CE%A4%CE%B5%CF%87%CE%BD%CF%8C%CF%80%CE%BF%CE%BB%CE%B7_2023_Locomondo.jpg', 'Markos Koumaris with Locomondo'),
    ('artist', 37, 'https://i.scdn.co/image/ab6761610000e5eb446e469d23ef077c426b1b1a', 'Marseaux portait'),
    ('artist', 38, 'https://www.glentzes.gr/wp-content/uploads/2024/03/kakosaios_giorgos.jpg', 'Giorgos Kakosaios performing'),
    ('artist', 39, 'https://www.intronews.gr/wp-content/uploads/2022/06/anastasia.jpg', 'Anastasia official photo');

INSERT INTO Image (entity_type, entity_id, image_url, description)
VALUES 
    -- Band images
    ('band', 1, 'https://sohosfm.gr/images/news/pyxlax.jpg', 'Pyx Lax band official photo'),
    ('band', 2, 'https://outnow.gr/wp-content/uploads/2019/10/onirama.jpg.webp', 'Onirama band performing'),
    ('band', 3, 'https://visitkassandra.com/wp-content/uploads/2024/07/melisses.jpg', 'Melisses on stage'),
    ('band', 4, 'https://upload.wikimedia.org/wikipedia/en/6/6d/Trypes.jpg', 'Trypes band portrait'),
    ('band', 5, 'https://mikrofwno.gr/wp-content/uploads/2019/04/mple-drama-mikrofwno.jpg', 'Ble band performing'),
    ('band', 6, 'https://www.boemradio.gr/media/uploads_image/2022/05/25/p1g3t2ek1m1p6u9tb1rgl121t1lq4h_1170x600.jpg', 'Ypogeia Revmata band photo'),
    ('band', 7, 'https://www.athinorama.gr/Content/ImagesDatabase/fbc/1280x672/crop/both/lmnts/articles/2501455/TERMITES.jpg', 'Termites band members'),
    ('band', 8, 'https://influencemag.gr/wp-content/uploads/2022/05/magic-de-spell-optimized.jpg', 'Magic De Spell performing'),
    ('band', 9, 'https://i.discogs.com/75JdVIV5Rt-5JfXNh17AEqZZKZkVGFjqFOZSLht2RSc/rs:fit/g:sm/q:40/h:300/w:300/czM6Ly9kaXNjb2dz/LWRhdGFiYXNlLWlt/YWdlcy9BLTE0MzUw/MjktMTMwNjMxODQw/OS5qcGVn.jpeg', 'Xylina Spathia album cover'),
    ('band', 10, 'https://www.news247.gr/wp-content/uploads/2022/11/kitrina.jpg', 'Kitrina Podilata on stage'),
    ('band', 11, 'https://www.news247.gr/wp-content/uploads/2015/11/lowbap-640x367.jpg', 'Active Member group photo'),
    ('band', 12, 'https://www.ticketservices.gr/pictures/original/b_41947_or_loco2landscape.jpg', 'Locomondo in concert'),
    ('band', 13, 'https://i.ytimg.com/vi/vk0z2G2UNSc/sddefault.jpg', 'Antique with Elena Paparizou'),
    ('band', 14, 'https://parallaximag.gr/wp-content/uploads/2021/09/DSC_0670.jpg', 'WNCfam group performing');


INSERT INTO Image (entity_type, entity_id, image_url, description)
VALUES 
    ('festival', 1, 'C:\\Users\\user\\Pictures\\festivals\\athens_2017.jpg', 'Athens Main Stage Music Festival 2017'),
    ('festival', 2, 'C:\\Users\\user\\Pictures\\festivals\\newyork_2018.jpg', 'New York Sound Experience 2018'),
    ('festival', 3, 'C:\\Users\\user\\Pictures\\festivals\\rio_2019.jpg', 'Rio Beach Party 2019'),
    ('festival', 4, 'C:\\Users\\user\\Pictures\\festivals\\london_2020.jpg', 'London Park Festival 2020'),
    ('festival', 5, 'C:\\Users\\user\\Pictures\\festivals\\patras_2021.jpg', 'Patras Nights 2021'),
    ('festival', 6, 'C:\\Users\\user\\Pictures\\festivals\\sydney_2022.jpg', 'Sydney Opera Sounds 2022'),
    ('festival', 7, 'C:\\Users\\user\\Pictures\\festivals\\thessaloniki_2023.jpg', 'Thessaloniki Jazz Festival 2023'),
    ('festival', 8, 'C:\\Users\\user\\Pictures\\festivals\\athens_2024.jpg', 'Athens Reunion Festival 2024'),
    ('festival', 9, 'C:\\Users\\user\\Pictures\\festivals\\newyork_2025.jpg', 'New York World Music Heritage 2025'),
    ('festival', 10, 'C:\\Users\\user\\Pictures\\festivals\\rio_2026.jpg', 'Rio Summer Sounds 2026');


-- =================================================================
-- STAGE EQUIPMENT DETAILS
-- =================================================================
-- Technical equipment types with images and descriptions
-- Detailed technical specifications needed for performance planning
INSERT INTO Equipment_Type (name, description, image_url) VALUES
('PA System', 'Professional audio systems for amplifying sound to large audiences', 'https://www.musicalinstrumentstore.co.uk/images/bose-f1-model-812-flexible-array-loudspeaker-with-subwoofer-p2041-5580_image.jpg'),

('LED Wall', 'Video displays using LED panels for visual effects and imagery', 'https://www.prolytes.com/wp-content/uploads/2019/09/led-wall-led-screen-outdoor-video-wall-digital-screen-electronic-billboard-advertising-display-4.jpg'),

('Moving Lights', 'Motorized lighting fixtures that can change position, color, and beam shape', 'https://www.stagelights.shop/media/catalog/product/cache/2/image/9df78eab33525d08d6e5fb8d27136e95/m/o/moving-head-beam-7r-230w_2.jpg'),

('DJ Booth', 'Performance setup for DJs including mixers, controllers, and monitoring', 'https://www.disco-designer.fr/2312-large_default/facade-platines-dj-design-logo-dj.jpg'),

('CO2 Cannons', 'Special effects equipment that shoots bursts of CO2 gas', 'https://magicfx.eu/wp-content/uploads/MAGICFX-CO2-JET-I-001.jpg'),

('Light Show', 'Coordinated lighting effects including lasers, strobes, and color washes', 'https://www.intelligentlighting.co.uk/wp-content/uploads/2017/10/IMG_8576-scaled.jpg'),

('Natural Acoustics', 'Venues with excellent sound propagation without amplification', 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Odeon_of_Herodes_Atticus_2012.jpg/1200px-Odeon_of_Herodes_Atticus_2012.jpg'),

('Mood Lighting', 'Ambient lighting designed to create atmosphere', 'https://www.7prosound.com/wp-content/uploads/2018/07/mood-lighting.jpg'),

('Full Digital Mixing', 'Advanced digital sound consoles for precise audio control', 'https://dt7v1i9vyp3mf.cloudfront.net/styles/news_large/s3/imagelibrary/A/Allen_Heath_dLive_02-Ii-tNyT1XPl9jIJtY.SdcARKmM_.PvBiR.jpg'),

('Projection Mapping', 'Technology to project images onto irregularly shaped surfaces', 'https://www.projectionfreak.com/wp-content/uploads/2017/08/barcelona_mapping.jpg'),

('LED Lighting', 'Energy-efficient lighting fixtures using Light Emitting Diodes', 'https://m.media-amazon.com/images/I/71JWFfPK-hL.jpg'),

('Wireless PA System', 'Portable sound systems without extensive cabling requirements', 'https://cdn.shopify.com/s/files/1/0079/7263/3306/products/portable-pa-system-with-wireless-microphone-6-5-party-speaker-remote-control-bluetooth-function-863_1024x1024.jpg'),

('Garden Lighting', 'Outdoor illumination for landscaped environments', 'https://www.thespruce.com/thmb/QmAhgbALlVKVJXHKQRALJmcWkyo=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/string-light-ideas-4775880-01_preview-6e9d6696d00a4fd294079c5c68e1a291.jpg'),

('Ambient Sound', 'Background audio designed to enhance atmosphere', 'https://img.freepik.com/free-vector/music-design_24877-38424.jpg'),

('Marshall Amps', 'Iconic guitar amplifiers known for their rock sound', 'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f1/Marshall_JCM_800_amplifier_stack.jpg/1200px-Marshall_JCM_800_amplifier_stack.jpg'),

('Drum Kit', 'Complete percussion instrument set for bands', 'https://www.long-mcquade.com/files/11358/lg_V52134.JPG'),

('Acoustic PA', 'Sound systems optimized for acoustic performances', 'https://images.reverb.com/image/upload/s--lhGQt19o--/f_auto,t_large/v1560536374/v5itbz0xf4lptcmgovua.jpg'),

('Spotlights', 'Focused lighting fixtures to highlight specific performers or areas', 'https://m.media-amazon.com/images/I/61GuyS+QTWL.jpg'),

('City Lighting', 'Integration with existing urban illumination', 'https://www.tripsavvy.com/thmb/hZV7UM4-B8Ug-gdOCuMrY8NhElg=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/TimesSquareNewYorkCity-5c292bac46e0fb000172d0b5.jpg'),

('Full Concert System', 'Complete audio setup for large-scale performances', 'https://www.audiovisualprojects.co.uk/wp-content/uploads/2018/01/Concert-Systems-header-1600x900.jpg'),

('LED Video Walls', 'High-resolution video displays for large venues', 'https://www.hdled.us/uploads/images/20170628/led-video-wall.jpg'),

('Computer-controlled Lighting', 'Automated lighting systems managed by software', 'https://usa.lighting.philips.com/b-dam/b2b-li/en_AA/support/tools/Dynalite-System-overview.png'),

('Ambient Lighting', 'Subtle illumination to enhance mood', 'https://www.thespruce.com/thmb/O2lNfdwuXi1-z1H2vip4aYFpRBM=/1500x0/filters:no_upscale():max_bytes(150000):strip_icc()/ambient-lighting-4177053-hero-c987aad1d36a495ca2faaa1fc2d952f1.jpg'),

('Acoustic Enhancement', 'Technology to improve natural sound qualities', 'https://www.meyersound.com/wp-content/uploads/2021/07/constellation-products-hero@2x.jpg'),

('Festival Lighting Rig', 'Comprehensive lighting setup for outdoor festivals', 'https://www.stagelightsandmore.co.uk/wp-content/uploads/2017/06/Festival-Lighting-2-1200x675.jpg'),

('Delay Towers', 'Secondary speaker systems placed at intervals in large venues', 'https://www.sweetwater.com/insync/media/2018/03/Delay-Speakers.jpg'),

('Full Production Rig', 'Complete technical production setup for major events', 'https://i.pinimg.com/originals/c1/f1/36/c1f136f02d73366266cf0c2c21f88b73.jpg'),

('Marine-grade PA', 'Weather-resistant sound systems for waterfront locations', 'https://www.pss-store.com/wp-content/uploads/2021/04/fusion_panel_stereo_2.jpg'),

('Waterproof Lighting', 'Lighting fixtures designed for wet environments', 'https://www.claypaky.it/media/documents/spl3web-5.jpg'),

('Waterfront Lighting', 'Illumination systems designed for coastal or riverside venues', 'https://media-cdn.tripadvisor.com/media/photo-s/11/18/71/c5/sentosa-crane-dance.jpg'),

('Heritage-approved Sound System', 'Audio equipment suitable for historical sites', 'https://www.prosoundnetwork.com/wp-content/uploads/2020/10/K-array_Anakonda_Speaker_setup-980x551.jpg'),

('Architectural Lighting', 'Lighting designed to enhance building features', 'https://www.archlighting.com/wp-content/uploads/2018/05/1805al-projectinfocus-2.jpg'),

('Street Performance Setup', 'Portable technical equipment for outdoor performances', 'https://previews.123rf.com/images/kadmy/kadmy1608/kadmy160800086/63614900-street-muscians-performing-songs-on-summer-city-street.jpg'),

('Video Mapping', 'Projection technology that transforms surfaces into dynamic displays', 'https://www.xsens.com/hubfs/projection%20mapping.jpg');

-- Link equipment to specific stages with quantities
INSERT INTO Stage_Equipment (stage_id, equipment_type_id, quantity)
VALUES
-- Main Stage Athens
(1, 1, 1), -- PA System
(1, 2, 1), -- LED Wall
(1, 3, 8), -- Moving Lights

-- Acropolis View Arena
(2, 4, 1), -- DJ Booth
(2, 6, 1), -- Light Show
(2, 5, 4), -- CO2 Cannons

-- Odeon of Herodes Atticus
(3, 1, 1), -- Custom PA System
(3, 21, 1), -- Ambient Lighting
(3, 23, 1), -- Acoustic Enhancement

-- Technopolis Gazi Stage
(4, 9, 1), -- Full Digital Mixing
(4, 10, 1), -- Projection Mapping
(4, 11, 12), -- LED Lighting

-- Central Park Main
(5, 1, 1), -- PA System
(5, 4, 1), -- DJ Booth
(5, 18, 1), -- Park Lighting

-- Great Lawn Pavilion
(6, 20, 1), -- Full Concert Sound System
(6, 21, 2), -- LED Video Walls
(6, 3, 12), -- Moving Lights

-- Bethesda Fountain Plaza
(7, 17, 1), -- Acoustic-focused PA
(7, 7, 1), -- Natural Acoustics
(7, 8, 1), -- Minimal Lighting

-- Sheep Meadow Soundstage
(8, 1, 1), -- Line Array Speakers
(8, 9, 1), -- Digital Mixing
(8, 25, 1), -- Festival Lighting Rig

-- Ipanema Sands Stage
(9, 15, 4), -- Marshall Amps
(9, 16, 1), -- Drum Kit
(9, 1, 1), -- PA System

-- Bossa Nova Corner
(10, 17, 1), -- Acoustic PA
(10, 21, 1), -- Jazz Lighting

-- Copacabana Beach Main Stage
(11, 20, 1), -- Full Concert System
(11, 21, 4), -- LED Screens
(11, 5, 8), -- Pyrotechnics

-- Maracanã Stadium Stage
(12, 20, 1), -- Stadium Sound System
(12, 21, 6), -- Multiple Video Screens
(12, 26, 1), -- Full Production

-- Georgiou Square
(13, 1, 1), -- PA
(13, 3, 6), -- Moving Heads
(13, 21, 1), -- Video Screen

-- Rio-Antirio Bridge View
(14, 1, 1), -- Full PA
(14, 6, 1), -- Light Rig
(14, 2, 1), -- LED Wall

-- Roman Odeum of Patras
(15, 1, 1), -- Minimal PA
(15, 22, 1), -- Historic Lighting Design
(15, 23, 1), -- Acoustic Enhancement

-- Victoria Park Central
(16, 1, 1), -- Full PA
(16, 2, 1), -- Video Wall
(16, 11, 8), -- Lights

-- Thames View Platform
(17, 1, 1), -- PA
(17, 21, 2), -- LED Screens

-- East London Bowl
(18, 20, 1), -- Full Concert System
(18, 28, 1), -- Lighting Towers
(18, 21, 2), -- LED Screens

-- Hackney Meadow
(19, 20, 1), -- Festival Sound System
(19, 24, 4), -- Delay Towers
(19, 26, 1), -- Full Production Rig

-- Sydney Opera Steps
(20, 1, 1), -- Full PA
(20, 2, 1), -- LED Wall
(20, 29, 1), -- Stage Effects

-- Harbour Bridge View
(21, 1, 1), -- PA System
(21, 6, 1), -- Light Show

-- Opera House Forecourt
(22, 1, 1), -- Line Array PA
(22, 3, 12), -- Automated Lighting
(22, 21, 3), -- Video Walls

-- Sydney Cove Floating Stage
(23, 30, 1), -- Marine-grade PA
(23, 31, 1), -- Waterproof Lighting
(23, 10, 1), -- Projection

-- Aristotelous Plaza
(24, 1, 1), -- PA
(24, 6, 1), -- Light Show
(24, 21, 1), -- LED Screen

-- White Tower Arena
(25, 20, 1), -- Full Concert PA
(25, 6, 1), -- Lighting Rig
(25, 21, 2), -- LED Screens

-- Rotunda Ancient Stage
(26, 32, 1), -- Heritage-approved Sound System
(26, 33, 1), -- Architectural Lighting

-- Ladadika District Stage
(27, 1, 1), -- Small Format PA
(27, 21, 1), -- Ambient Lighting
(27, 34, 1), -- Street Performance Setup

-- Nea Paralia Boardwalk
(28, 30, 1), -- Weather-resistant Sound System
(28, 31, 1), -- Waterfront Lighting (changed from 35 to 31)

-- ANO POLI Terrace
(29, 1, 1), -- Compact PA System
(29, 8, 1), -- Mood Lighting
(29, 23, 1), -- Acoustic Treatments

-- Syntagma Square Stage
(30, 1, 1), -- Full PA
(30, 21, 2), -- LED Screens
(30, 22, 1); -- Computer-controlled Lighting

-- =================================================================
-- GENRE ADJUSTMENTS FOR ANALYSIS
-- =================================================================
-- Update artist genres to create more hybrid/crossover genres for analysis
-- These updates support genre-related queries like #10 (top genre pairs)
UPDATE Artist SET genre = 'Rock/Pop' WHERE name = 'Michalis Hatzigiannis';
UPDATE Artist SET genre = 'Folk/Pop' WHERE name = 'Nikos Vertis';
UPDATE Artist SET genre = 'Jazz/Folk' WHERE name = 'Mariza Rizou';
UPDATE Artist SET genre = 'Pop/Electronic' WHERE name = 'Eleni Foureira';
UPDATE Artist SET genre = 'Rock/Folk' WHERE name = 'Stelios Rokkos';
UPDATE Artist SET genre = 'Rock/Pop' WHERE name= 'Christos Thivaios';
UPDATE Artist SET genre = 'Rock/Pop' WHERE name= 'Vasilis Papakonstantinou';
UPDATE Artist SET genre = 'Folk/Jazz' = 'Sokratis Malamas';
UPDATE Artist SET genre = 'Pantelis Thalassinos';
UPDATE Artist SET genre = 'Pop/Electronic'='Anastasia-Dimitra';
UPDATE Artist SET genre = 'Maria-Sophia';

--For Query #11
-- Add more performances for a few selected artists to create a clear "max participation" artist
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES (9, 10, NULL, 5, 2, '21:00:00', 45);  -- Year 2018

-- Create a new event for Festival 10 (2026)
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (69, 11, 'Legends Concert', '18:00:00', '23:00:00');

SET @legends_event = (SELECT MAX(event_id) FROM Event);

INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES (@legends_event, 10, NULL, 11, 1, '18:00:00', 60);  -- Year 2026

INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES (59, 10, NULL, 8, 2, '18:00:00', 60);  -- Year 2025

SET @greek_stars = (SELECT MAX(event_id) FROM Event);

-- Let's try to add a performance in 2021 (which is not consecutive with his other years)
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES (31, 10, NULL, 14, 2, '20:00:00', 60);  -- Year 2021

-- Add Dionysis Savvopoulos to this event
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES (@greek_music, 10, NULL, 16, 2, '19:30:00', 60);  -- Year 2020

-- Add one more performance in 2024
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES (53, 10, NULL, 4, 2, '19:00:00', 60);  -- Year 2024

-- Let's create one more event for more performances by other artists
INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (55, 7, 'Greek Stars Evening', '19:00:00', '23:30:00');

-- Get this event ID
SET @greek_stars = (SELECT MAX(event_id) FROM Event);

-- Add more artists with 1-2 performances each
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
    VALUES (@greek_stars, 11, NULL, 7, 2, '19:15:00', 45),  -- Kaiti Garbi
           (@greek_stars, 17, NULL, 7, 1, '20:15:00', 45),  -- Panos Kiamos
           (@greek_stars, 7, NULL, 7, 3, '21:15:00', 45);   -- Giorgos Mazonakis

INSERT INTO Event (day_id, stage_id, name, start_time, end_time)
    VALUES (56, 8, 'Greek Stars Evening', '19:00:00', '23:30:00');  -- Using Festival 9, day 56, stage 8

-- Add some performances for other artists
INSERT INTO Performance (event_id, artist_id, band_id, stage_id, type_id, start_time, duration)
VALUES 
    -- Artist ID 2 (Anna Vissi) with moderate participation
    (25, 2, NULL, 17, 1, '19:00:00', 60),   -- London Electronic
    (26, 2, NULL, 18, 1, '18:00:00', 60),   -- Modern British Music
    (27, 2, NULL, 16, 1, '19:00:00', 60),   -- London Closing
    
    -- Artist ID 34 (Christos Mastoras) with moderate participation
    (32, 34, NULL, 13, 1, '18:30:00', 60),  -- Patras Closing Night
    (37, 34, NULL, 20, 1, '16:00:00', 60),  -- Pacific Rhythms
    (38, 34, NULL, 21, 1, '17:30:00', 60);  -- Sydney Closing

-- =================================================================
-- DATA DIAGNOSTICS
-- =================================================================
-- Confirm that all required data is properly loaded
-- Used to verify system completeness
SELECT COUNT(*) as total_events FROM Event;
SELECT COUNT(*) as total_tickets FROM Ticket;
SELECT COUNT(*) as total_performances FROM Performance;
SELECT COUNT(*) as total_reviews FROM Review;
SELECT COUNT(*) as total_images FROM Image;
SELECT COUNT(*) as total_stages FROM Stage;
SELECT COUNT(*) as total_equipment_types FROM Equipment_Type;
SELECT COUNT(*) as total_stage_equipment FROM Stage_Equipment;
SELECT COUNT(*) as total_artists FROM Artist;
SELECT COUNT(*) as total_bands FROM Band;
SELECT COUNT(*) as total_festivals FROM Festival;


-- Find artists who have reviews
SELECT DISTINCT 
    p.artist_id,
    a.name AS artist_name,
    COUNT(r.review_id) AS review_count,
    AVG(r.artist_rating) AS avg_artist_rating,
    AVG(r.overall_rating) AS avg_overall_rating
FROM 
    Performance p
JOIN 
    Review r ON p.performance_id = r.performance_id
JOIN 
    Artist a ON p.artist_id = a.artist_id
WHERE 
    p.artist_id IS NOT NULL
GROUP BY 
    p.artist_id, a.name
ORDER BY 
    review_count DESC, avg_overall_rating DESC;

--Query to calculate ages
SELECT 
    artist_id,
    name,
    pseudonym,
    birthdate,
    TIMESTAMPDIFF(YEAR, birthdate, CURDATE()) AS age,
    genre,
    subgenre
FROM 
    Artist
ORDER BY 
    age ASC;






