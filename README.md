# Music Festival Database System - "Pulse University"

## Project Overview

This database system is designed to manage and organize the international music festival "Pulse University". The system handles everything from festival planning, artist and band management, stage scheduling, ticket sales and resales, to staff assignments and visitor reviews.

## Technical Requirements

- MySQL 8.0+ or MariaDB 10.5+ (Required for optimizer trace functionality)
- Python 3.8+ (For the GUI application)
- Required Python packages:
  - tkinter
  - pandas
  - matplotlib
  - mysql-connector-python
- Minimum 500MB disk space for database and sample data
- Screen resolution of at least 1280x800 for optimal GUI experience

## Database Design

The database is structured around the core entities of festivals, locations, stages, events, performances, artists/bands, visitors, tickets, staff, and equipment. Complex relationships and business rules are implemented through careful schema design, constraints, triggers, and stored procedures.

### Core Entities Overview

- **Festival**: Annual music events at specific locations spanning multiple days
- **Location**: Physical places where festivals are held with geographic coordinates
- **Stage**: Performance venues with specific equipment and capacity
- **Event**: Scheduled shows that take place at specific stages
- **Performance**: Individual artist/band appearances within events
- **Artist/Band**: Performers (solo or groups) with associated music genres
- **Visitor**: Festival attendees who purchase tickets and leave reviews
- **Ticket**: Access permissions to specific events with categories and prices
- **Staff**: Personnel categorized as technical, security, or support staff
- **Equipment**: Technical resources required for performances

### Relationships and Constraints

The database implements complex relationships including:
- Many-to-many connections between artists and bands
- Time-constrained event scheduling for stages
- Capacity management for venues and tickets
- Staff-to-visitor ratio requirements
- Historical tracking of performances across festivals

## Application Overview

The Music Festival Database is accessible through a Python-based GUI application that provides:

1. **Query Execution Interface**: Simple interface to select and execute all 15 required queries
2. **Parameter Input**: Dynamic form generation for queries requiring parameters
3. **Results Visualization**: Interactive charts and graphs for applicable query results
4. **Performance Analysis**: Tools to compare regular and optimized query execution
5. **Export Functionality**: Options to export query results and SQL statements

### Screenshots
- Main Interface: See [docs/images/main_interface.png](docs/images/main_interface.png)
- Query Results Visualization: See [docs/images/visualization.png](docs/images/visualization.png)
- Performance Analysis: See [docs/images/performance_comparison.png](docs/images/performance_comparison.pn)

## Design Decisions and Assumptions

### Implementation Assumptions

We've made the following implementation decisions based on the assignment requirements:

**Festival Management**
- **Festival Cancellation**: Festivals cannot be canceled once scheduled, as specified in the requirements.
- **Festival Duration**: Each festival spans multiple consecutive days at a single location, implementing the multi-day event structure.
- **Performances**: We implement soft deletion (using an `is_deleted` flag) to maintain historical performance data while allowing logical removal.

**Locations and Venues**
- **Geographic Identification**: Locations are uniquely identified by their geographical coordinates using MySQL's POINT datatype for precise positioning.
- **Stage Scheduling**: We enforce that no stage can host multiple events simultaneously through time-based constraints.

**Artists and Performances**
- **Band Membership**: Artists can participate in multiple bands, implemented as a many-to-many relationship through join tables.
- **Performance Conflicts**: Artists/bands cannot perform at multiple venues simultaneously, enforced via triggers that check for time conflicts.
- **Participation Limits**: No artist or band can participate in more than 3 consecutive festival years, validated through historical participation checks.
- **Performance Timing**: A mandatory 5-30 minute gap between performances is enforced by timing constraint triggers.

**Staff Management**
- **Staff Categorization**: Staff are divided into Technical, Security, and Support roles with 5 experience levels from Intern to Expert.
- **Security Coverage**: Security staff must cover at least 5% of the total number of attendees, enforced through triggers when allocating staff.
- **Support Coverage**: Support staff must cover at least 2% of the total number of attendees, similarly enforced via triggers.

**Ticketing System**
- **Ticket Identification**: Each ticket has a unique EAN-13 formatted code validated through regex constraints.
- **VIP Limitations**: VIP tickets are limited to 10% of each stage's capacity through trigger-based validation.
- **Ticket Uniqueness**: One visitor can have only one ticket per day and performance, enforced through uniqueness constraints.
- **Resale Process**: Ticket resales follow a FIFO queue-based system with timestamp-ordered processing.

**Visitor Interaction**
- **Review Eligibility**: Only visitors with used tickets can submit performance reviews, validated during review creation.
- **Equipment Management**: Equipment is categorized by types and associated with stages through a many-to-many relationship.
- **Multimedia Support**: All entities can have associated images through a generalized image table with entity references.

### Genre Representation

For Query 10 ("Top-3 genre pairs that appeared in festivals"), we made the following design decision:
- Instead of using separate genre and subgenre fields as strictly distinct categories, we implemented a more flexible approach where artists can have combined genres (e.g., "Rock/Pop", "Folk/Jazz").
- This approach better reflects the reality of modern music where artists often span multiple primary genres rather than fitting into a strict genre/subgenre hierarchy.
- Artists in our database have a primary `genre` field that may contain combined values separated by a slash (e.g., "Rock/Pop"), and we parse these combinations to identify the most common genre pairings.
- This design choice allows us to identify truly hybrid artists and analyze which genre combinations are most prevalent in festival performances.

The query extracts and analyzes the component genres from these combined fields to determine which pairs of musical styles most frequently appear together at festivals.

## Business Rules Implementation

The database enforces numerous business rules through carefully designed triggers, constraints, and stored procedures:

1. **Artist/Band Performance Constraints**:
   - No artist/band can perform at two stages simultaneously
   - Limited to 3 consecutive years of participation
   - Performances require 5-30 minute gaps between them

2. **Ticket Management**:
   - Total tickets cannot exceed stage capacity
   - VIP tickets limited to 10% of capacity
   - Tickets can be resold if not used
   - One visitor can only have one ticket per day/performance

3. **Staff Requirements**:
   - Security staff must cover at least 5% of audience
   - Support staff must cover at least 2% of audience
   - Staff assigned based on expertise levels

4. **Review System**:
   - Only visitors with used tickets can leave reviews
   - Ratings follow Likert scale (1-5) across multiple criteria

## Test Parameters for Queries

When testing the application, use these parameters for best results:

### Query #2: Artists by Genre with Festival Participation
- Year: 2025 or 2023
- Genre: "Pop" or "Folk"

### Query #4: Artist Average Ratings
- Artist ID: 28 (Mariza Rizou, 12 reviews)
- Artist ID: 32 (Sokratis Malamas, 9 reviews)
- Artist ID: 9 (Vasilis Papakonstantinou, 9 reviews)
- Artist ID: 2 (Anna Vissi, 8 reviews)

### Query #6: Visitor Attended Performances and Ratings
- Visitor ID: 2, 11, 23, 34, or 55 (These visitors have submitted multiple reviews)

### Query #8: Unscheduled Support Staff for a Date
- Date: "2019-08-11" (Rio Beach Party)
- Date: "2026-09-06" (Rio Summer Sounds)
- Date: "2023-05-23" (Thessaloniki Jazz Festival)
- Date: "2022-08-25" (Sydney Opera Sounds)

### Query #15: Top Visitors by Ratings for an Artist
- Artist ID: 28 (Mariza Rizou)
- Artist ID: 2 (Anna Vissi)
- Artist ID: 32 (Sokratis Malamas)

## Features

### Core Functionality
- Complete festival, event, and performance management
- Artist and band tracking with genre classification
- Stage management with equipment specification
- Visitor registration and ticket purchasing
- Staff assignment and management
- Performance reviews and ratings

### Advanced Features
- Ticket resale queue system with automated processing
- User notifications for ticket-related actions
- Audit logging for resale transactions
- Flexible image storage for all entities
- Spatial data handling for locations
- Performance caching for frequent statistics
- Historical data archiving

## Installation and Setup

### Prerequisites
- MySQL (MariaDB) or PostgreSQL
- Python 3.8+ with required packages
- Sufficient storage for database and images

### Installation Steps

1. Clone this repository

2. Configure MySQL event scheduler by adding the following to the `[mysqld]` section in the MySQL configuration file:
   ```
   event_scheduler=ON
   ```
   For XAMPP users, this file is typically located at: `C:\xampp\mysql\bin\my.ini`

   This ensures that the event scheduler is automatically enabled on server startup, which is required for the ticket resale queue and other scheduled tasks in the database.

3. Execute the setup scripts in the following order:
   ```
   mysql -u username -p < sql/install.sql
   mysql -u username -p < sql/load.sql
   ```

4. Verify installation by running a test query:
   ```
   mysql -u username -p -e "SELECT * FROM Festival LIMIT 5;" MusicFestival
   ```

5. Launch the GUI application:
   ```
   python app.py
   ```

## Schema Overview

The database consists of the following principal tables:

- **Reference Tables**: PaymentMethod, ExperienceLevel, PerformanceType, StaffRole, ResaleStatus, TicketCategory
- **Core Tables**: Location, Festival, Stage, FestivalDay, Event, Artist, Band, Artist_Band, Visitor, Staff, Staff_Assignment, Performance, Review, Ticket
- **Support Tables**: ResaleQueue, Image, Equipment_Type, Stage_Equipment, UserNotification, ResaleAuditLog

### Key Indexes and Optimizations

- Spatial index on Location.coordinates
- FULLTEXT index on Artist for search functionality
- Composite indexes on frequently joined fields
- Specialized indexes for ticket searches and performance filtering

## Query Examples

The database supports complex analytics including:

1. Festival revenue analysis by year and payment method
2. Artist participation tracking across festivals
3. Performance rating analysis and trending
4. Staff requirement calculations
5. Genre popularity analysis across years
6. Cross-continent artist performance tracking

## Performance Considerations

The database includes:

1. **Optimized Indexes** for common query patterns
2. **Cache Tables** for expensive statistics
3. **Efficient Joins** through careful index selection
4. **Stored Procedures** for complex operations
5. **Controlled Data Growth** through archiving mechanisms

## Database Statistics

The current database contains:
- 39+ artists and 14+ bands
- 30+ stages across multiple locations 
- 10 festivals (8 past, 2 future events)
- 100+ performances
- 200+ tickets with various statuses
- Comprehensive staff assignments
- Equipment types with stage associations
- Sample reviews, resale transactions, and images

This sample data structure supports all query requirements specified in the assignment.

## Database Constraints and Testing

### Test Framework Overview

We developed a comprehensive automated testing framework to validate all database constraints and business rules. The framework (`test.sql`) systematically tests all aspects of database integrity through 30+ test cases, ensuring the robustness of our implementation.

### Testing Methodology

Our testing approach includes:

- **Isolated Test Cases**: Each test executes within its own transaction to prevent interference between tests
- **Automatic Cleanup**: All test data is automatically removed after test execution
- **Performance Monitoring**: Tests measure execution time to identify potential bottlenecks
- **Detailed Logging**: Success/failure status and error messages are captured for each test

### Constraint Categories Tested

Our test suite validates the following types of constraints:

1. **Primary Key and Unique Constraints** (Tests PK-1 to UQ-4)
   - Duplicate detection for primary keys and unique fields (artist pseudonyms, band names, etc.)
   
2. **Foreign Key Constraints** (Tests FK-1 to FK-5)
   - Validation of referential integrity and cascading operations
   
3. **Check Constraints** (Tests CHK-1 to CHK-8)
   - Domain validation for fields like continents, capacity, age limits, and performance durations
   
4. **Complex Business Rules via Triggers** (Tests TRG-1 to TRG-12)
   - Festival date year validation
   - 3 consecutive years artist participation limitation
   - VIP ticket 10% capacity restriction
   - 5-30 minute mandatory performance gap
   - Concurrent performance prevention for the same artist
   - Resale queue eligibility
   - Review submission validation
   - One ticket per visitor per day/performance
   - Event time overlap prevention
   
5. **Staff Requirement Constraints** (Tests STF-1 to STF-3)
   - Security staff 5% coverage requirement
   - Support staff 2% coverage requirement
   - Technical staff shift timing validation
   
6. **Stress Tests** (Tests STRESS-1)
   - System behavior under high volume ticket creation with VIP constraints

### Test Results

In our final test run, all 30+ tests completed successfully, demonstrating the integrity of our implementation. Details of the test results can be found in the [test_results.md](./test_results.md) file. Key statistics:

- Total Tests: 30+
- Successful Tests: 100%
- Average Execution Time: XX ms per test
- Stress Test Maximum Volume: 100+ concurrent ticket creations

### Running the Tests

To execute the test suite:

```sql
SOURCE sql/test.sql;
```

## Troubleshooting

### Database Connection Issues
- Verify XAMPP is running and MySQL service is started
- Check the database credentials in `config.py`
- Ensure the MusicFestival database exists and is populated

### Missing Required Indexes
If you encounter performance issues with the Compare Query Plans feature:
```sql
-- Create indexes required for optimization queries
CREATE INDEX idx_performance_artist ON Performance(artist_id);
CREATE INDEX idx_review_performance ON Review(performance_id);
CREATE INDEX idx_ticket_visitor ON Ticket(visitor_id);
CREATE INDEX idx_review_visitor ON Review(visitor_id);
```

### Python Package Issues
If you encounter errors related to missing packages:
```bash
pip install --upgrade mysql-connector-python pandas matplotlib
```

## Assignment Context

This database was developed for the Databases course (6th semester) at the National Technical University of Athens, School of Electrical and Computer Engineering. It implements all 15 required queries for the Music Festival Database assignment, with special focus on:

- Query optimization techniques
- Performance analysis of database operations
- Data visualization
- User interface design

The application meets all requirements specified in the assignment, with additional features to enhance usability and analytical capabilities.

## Notes on Special Queries

For optimization analysis on queries #4 and #6, see the `docs/report.pdf` which includes:
- Alternative query plans using force index
- Performance comparison of different join strategies
- Execution trace analysis
- Optimization recommendations

## Future Enhancements

Potential improvements for future versions:
- Integration with ticket payment gateways
- Mobile application for real-time festival management
- Machine learning for artist recommendation
- Integration with streaming platforms for preview functionality
- Real-time analytics dashboard for festival organizers
- Enhanced security features for ticket verification

## References

- [MariaDB Documentation](https://mariadb.com/kb/en/)
- [MySQL Optimization Guide](https://dev.mysql.com/doc/refman/8.0/en/optimization.html)
- [Tkinter Documentation](https://docs.python.org/3/library/tkinter.html)
- [Matplotlib Documentation](https://matplotlib.org/stable/contents.html)