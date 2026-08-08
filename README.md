# Bug Tracking System Database

A relational database project built with MySQL for managing software bugs across multiple projects, including bug reporting, assignment, comments, status tracking, and audit history.

## Technologies

- MySQL 8
- SQL
- Relational Database Design
- Database Normalization (3NF)
- ER Diagram

## Project Overview

This project implements a relational database for a multi-project software bug tracking system.

The system supports the complete bug lifecycle from reporting and assignment to resolution and closure, while maintaining assignment history and an audit trail of important changes.

The database was designed using an Entity-Relationship model and normalized to Third Normal Form (3NF).

## Database Schema

The database contains 8 relational tables:

| Table | Purpose |
|---|---|
| Role | Defines user roles |
| User | Stores system users and their roles |
| Project | Stores projects and project owners |
| ProjectMember | Manages users assigned to projects |
| Bug | Stores reported software bugs |
| Comment | Stores comments associated with bugs |
| BugAssignment | Maintains bug assignment history |
| BugHistory | Maintains an audit trail of bug changes |

### Key Relationships

- User → Role
- Project → User
- Project ↔ User through ProjectMember
- Project → Bug
- Bug → User through reporter and assignee relationships
- Bug → Comment
- Bug → BugAssignment
- Bug → BugHistory

## Database Design

The database follows Third Normal Form (3NF) and uses:

- Primary Keys
- Foreign Keys
- Composite Primary Keys
- Unique Constraints
- ENUM constraints
- Referential Integrity
- Many-to-Many relationships
- Audit history

The `ProjectMember` table resolves the many-to-many relationship between users and projects.

The `BugAssignment` and `BugHistory` tables preserve historical information instead of overwriting previous records.

## Sample Data

The project includes a seeded dataset containing approximately 200 records across the database tables.

The sample data is used to test SQL queries and demonstrate reporting capabilities.

## SQL Queries

The project includes simple and complex SQL queries for analyzing the bug tracking system.

Examples include:

- Bugs by severity
- Open and critical bugs
- Developer workload
- Bug activity ranking
- Stale open bugs
- Bug aging reports
- Resolution rate by severity
- Average resolution time
- Project bug dashboards

### SQL Techniques Used

- SELECT
- INSERT
- UPDATE
- JOIN
- LEFT JOIN
- GROUP BY
- HAVING
- ORDER BY
- CASE
- COUNT
- SUM
- AVG
- COUNT(DISTINCT)
- Subqueries
- COALESCE
- DATEDIFF
- Conditional aggregation

## Project Structure

```text
bug-tracking-system-database/
│
├── 01_schema.sql
├── 02_sample_data.sql
├── 03_queries.sql
├── BugTracker-Report.pdf
├── 05_presentation.pdf
├── LICENSE
└── README.md
