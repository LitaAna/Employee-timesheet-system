# Employee Timesheet System

A Microsoft SQL Server database project for managing employee timesheets, working hours, absences, departments, offices, and projects.

## Overview

The system allows organizations to manage employee information and track the time employees spend working on different projects.

The database stores weekly timesheets, daily work records, absences, project activities, approval statuses, and employee contract details.

## Features

* Manage offices and departments
* Manage employees and managers
* Store employee contact and contract information
* Manage projects and clients
* Create weekly employee timesheets
* Record daily working hours
* Register employee absences
* Track activities by project
* Automatically calculate daily and weekly working hours
* Validate data using constraints and triggers
* Generate reports using database views
* Store contract and activity details as JSON
* Improve query performance using indexes

## Database Schemas

The database contains two schemas:

* `app` – application tables, constraints, indexes, and triggers
* `report` – views and reports

## Main Tables

| Table               | Description                                |
| ------------------- | ------------------------------------------ |
| `app.Sediu`         | Stores office information                  |
| `app.Departament`   | Stores department information              |
| `app.Angajat`       | Stores employee and manager information    |
| `app.TipAbsenta`    | Stores absence types                       |
| `app.Proiect`       | Stores project and client information      |
| `app.Pontaj`        | Stores weekly employee timesheets          |
| `app.PontajZi`      | Stores daily timesheet records             |
| `app.DetaliuPontaj` | Stores project activities and worked hours |

## Database Relationships

* Each department belongs to an office.
* Each employee belongs to a department.
* An employee can have a manager.
* Each project belongs to an office.
* Each weekly timesheet belongs to an employee.
* Each daily timesheet record belongs to a weekly timesheet.
* Each activity belongs to a daily timesheet record and a project.

## Validation Rules

The database validates the following rules:

* Employee email addresses must be unique.
* Employee personal identification numbers must be unique.
* Salaries must be greater than zero.
* Timesheet dates must belong to the selected week.
* A working day cannot contain an absence type.
* An absence day must contain an absence type.
* Absence days must have zero working hours.
* Daily working hours must be between 0 and 24.
* Activity hours must be greater than 0 and no more than 24.
* Timesheet statuses can be:

  * `Draft`
  * `Trimis`
  * `Aprobat`
  * `Respins`

## Triggers

The project includes triggers that:

* Check whether a timesheet date belongs to the corresponding week.
* Recalculate the total hours worked for each day.
* Recalculate the total hours worked for each weekly timesheet after an activity is inserted, updated, or deleted.

## Reports and Views

The following reports are available:

* Weekly timesheet summary
* Daily timesheet details
* Total hours worked per project
* Employee absence information
* Average daily working hours per employee
* Contract information extracted from JSON data
* Project activities and worked hours

## Technologies

* Microsoft SQL Server
* T-SQL
* SQL Server Management Studio
* JSON functions
* Database views
* Indexed views
* Triggers
* Non-clustered indexes
* Foreign keys and constraints

## Requirements

To run this project, you need:

* Microsoft SQL Server
* SQL Server Management Studio or another SQL Server client

## Installation

1. Open the SQL script in SQL Server Management Studio.
2. Make sure the database name is consistent throughout the script.
3. Use `Pontaj2` for all database references.
4. Execute the database creation section.
5. Execute the schema and table creation sections.
6. Execute the indexes, triggers, and views sections.
7. Insert the test data.
8. Run the verification queries and reports.

## Important Note

Before running the complete script, check that the database name is consistent:

```sql
CREATE DATABASE Pontaj2;
```

All later references should also use:

```sql
ALTER DATABASE Pontaj2;
```

The SQL script may need small formatting adjustments if it was copied from a document, especially for dates and JSON values.

## Example Query

The following query displays the total hours worked by each employee:

```sql
SELECT
    p.AngajatId,
    SUM(p.OreLucrateTotal) AS TotalOreLucrate
FROM app.Pontaj p
GROUP BY p.AngajatId
ORDER BY p.AngajatId;
```

## Project Status

This project is intended for educational and demonstration purposes. It includes database structure, sample data, validation rules, triggers, reports, and test queries for an employee timesheet management system.
