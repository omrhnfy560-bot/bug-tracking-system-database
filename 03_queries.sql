-- ============================================================================
-- Bug Tracker — SQL Q&A Set
-- COMP2004 Database Management Systems | Fenerbahçe University
-- All 20 queries verified against sample data (200 rows).
-- ============================================================================

USE bug_tracker;

-- ============================================================================
-- PART 1 — DML (10 queries): INSERT / UPDATE / DELETE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- DML-1. Business: A new tester named Defne Yurt joins the company.
-- ----------------------------------------------------------------------------
INSERT INTO User (email, full_name, password_hash, role_id)
VALUES ('defne.yurt@fbu.edu.tr', 'Defne Yurt', 'HASH_021_$2y$10$abc', 4);


-- ----------------------------------------------------------------------------
-- DML-2. Business: Add Defne Yurt as a Tester to the Online Exam Platform project.
-- ----------------------------------------------------------------------------
INSERT INTO ProjectMember (project_id, user_id, project_role)
VALUES (3, (SELECT user_id FROM User WHERE email = 'defne.yurt@fbu.edu.tr'), 'Tester');


-- ----------------------------------------------------------------------------
-- DML-3. Business: Defne reports a new critical bug in Online Exam Platform.
-- ----------------------------------------------------------------------------
INSERT INTO Bug (project_id, title, description, severity, priority, reported_by)
VALUES (3, 'Exam auto-submit fires 30 sec early',
        'Timer drift causes premature submission when many students online',
        'Critical', 5,
        (SELECT user_id FROM User WHERE email = 'defne.yurt@fbu.edu.tr'));


-- ----------------------------------------------------------------------------
-- DML-4. Business: Manager assigns the new bug to developer Zeynep Celik (user_id=4).
-- ----------------------------------------------------------------------------
UPDATE Bug
SET current_assignee_id = 4, status = 'InProgress'
WHERE title = 'Exam auto-submit fires 30 sec early';


-- ----------------------------------------------------------------------------
-- DML-5. Business: Escalate priority of all Open Critical bugs to 5.
-- ----------------------------------------------------------------------------
UPDATE Bug
SET priority = 5
WHERE status = 'Open' AND severity = 'Critical' AND priority < 5;


-- ----------------------------------------------------------------------------
-- DML-6. Business: Mark all bugs in archived projects as Closed and set
--                  their resolved_at to now (cleanup of legacy projects).
-- ----------------------------------------------------------------------------
UPDATE Bug b
JOIN Project p ON b.project_id = p.project_id
SET b.status = 'Closed', b.resolved_at = NOW()
WHERE p.status = 'Archived' AND b.status <> 'Closed';


-- ----------------------------------------------------------------------------
-- DML-7. Business: Manager Elif Demir adds a comment to bug #1.
-- ----------------------------------------------------------------------------
INSERT INTO Comment (bug_id, user_id, content)
VALUES (1, 2, 'Please prioritize this; affects all Safari users.');


-- ----------------------------------------------------------------------------
-- DML-8. Business: Log a status change in BugHistory for bug #1
--                  (Open -> InProgress) by Elif Demir.
-- ----------------------------------------------------------------------------
INSERT INTO BugHistory (bug_id, changed_by, field_name, old_value, new_value)
VALUES (1, 2, 'status', 'Open', 'InProgress');


-- ----------------------------------------------------------------------------
-- DML-9. Business: A spam comment was posted on bug #5 by user 17 — delete it.
-- ----------------------------------------------------------------------------
DELETE FROM Comment
WHERE bug_id = 5 AND user_id = 17
LIMIT 1;


-- ----------------------------------------------------------------------------
-- DML-10. Business: Remove the archived 'Legacy Grade Portal' project entirely.
--                   ON DELETE CASCADE will clean its bugs / comments / history.
-- ----------------------------------------------------------------------------
DELETE FROM Project WHERE name = 'Legacy Grade Portal';


-- ============================================================================
-- PART 2 — SIMPLE QUERIES (5): filter, sort, basic SELECT
-- ============================================================================

-- ----------------------------------------------------------------------------
-- S-1. Business: List all Critical bugs that are still Open, newest first.
-- ----------------------------------------------------------------------------
SELECT bug_id, title, priority, created_at
FROM Bug
WHERE severity = 'Critical' AND status = 'Open'
ORDER BY created_at DESC;


-- ----------------------------------------------------------------------------
-- S-2. Business: Show all developers with their email, sorted alphabetically.
-- ----------------------------------------------------------------------------
SELECT u.full_name, u.email
FROM User u
JOIN Role r ON u.role_id = r.role_id
WHERE r.role_name = 'Developer'
ORDER BY u.full_name ASC;


-- ----------------------------------------------------------------------------
-- S-3. Business: List all bugs in 'Campus Mobile App' (project_id=2)
--                that took longer than 7 days to resolve.
-- ----------------------------------------------------------------------------
SELECT bug_id, title, created_at, resolved_at,
       DATEDIFF(resolved_at, created_at) AS days_to_resolve
FROM Bug
WHERE project_id = 2
  AND resolved_at IS NOT NULL
  AND DATEDIFF(resolved_at, created_at) > 7
ORDER BY days_to_resolve DESC;


-- ----------------------------------------------------------------------------
-- S-4. Business: Show all unassigned Open bugs, highest priority first.
-- ----------------------------------------------------------------------------
SELECT bug_id, title, priority, severity, created_at
FROM Bug
WHERE current_assignee_id IS NULL AND status = 'Open'
ORDER BY priority DESC, created_at ASC;


-- ----------------------------------------------------------------------------
-- S-5. Business: Show all comments made in the last 60 days, latest first.
-- ----------------------------------------------------------------------------
SELECT comment_id, bug_id, user_id, created_at, LEFT(content, 50) AS preview
FROM Comment
WHERE created_at >= DATE_SUB(CURDATE(), INTERVAL 60 DAY)
ORDER BY created_at DESC;


-- ============================================================================
-- PART 3 — COMPLEX QUERIES (5): GROUP BY, HAVING, JOINs, subqueries
-- ============================================================================

-- ----------------------------------------------------------------------------
-- C-1. Business: For each project, count bugs by severity.
--                Show only projects that have at least one Critical bug.
-- Techniques: JOIN, GROUP BY (multi-column), HAVING, subquery, FIELD() ordering
-- ----------------------------------------------------------------------------
SELECT p.name AS project, b.severity, COUNT(*) AS bug_count
FROM Project p
JOIN Bug b ON p.project_id = b.project_id
GROUP BY p.project_id, p.name, b.severity
HAVING p.project_id IN (
    SELECT project_id FROM Bug WHERE severity = 'Critical'
)
ORDER BY p.name, FIELD(b.severity, 'Critical','High','Medium','Low');


-- ----------------------------------------------------------------------------
-- C-2. Business: Top 5 developers by number of bugs currently in progress.
-- Techniques: JOIN, GROUP BY, ORDER BY DESC, LIMIT
-- ----------------------------------------------------------------------------
SELECT u.full_name, COUNT(*) AS active_bugs
FROM User u
JOIN Bug b ON u.user_id = b.current_assignee_id
WHERE b.status = 'InProgress'
GROUP BY u.user_id, u.full_name
ORDER BY active_bugs DESC
LIMIT 5;


-- ----------------------------------------------------------------------------
-- C-3. Business: For each project, average resolution time (days) for
--                Closed/Resolved bugs. Show only projects above the
--                global average resolution time.
-- Techniques: AVG, DATEDIFF, GROUP BY, HAVING with correlated subquery
-- ----------------------------------------------------------------------------
SELECT p.name AS project,
       ROUND(AVG(DATEDIFF(b.resolved_at, b.created_at)), 2) AS avg_days
FROM Project p
JOIN Bug b ON p.project_id = b.project_id
WHERE b.resolved_at IS NOT NULL
GROUP BY p.project_id, p.name
HAVING avg_days > (
    SELECT AVG(DATEDIFF(resolved_at, created_at))
    FROM Bug
    WHERE resolved_at IS NOT NULL
)
ORDER BY avg_days DESC;


-- ----------------------------------------------------------------------------
-- C-4. Business: Find engaged contributors — users who reported a bug AND
--                also commented on someone else's bug.
-- Techniques: IN with subquery (twice), nested join in subquery
-- ----------------------------------------------------------------------------
SELECT DISTINCT u.user_id, u.full_name
FROM User u
WHERE u.user_id IN (SELECT reported_by FROM Bug)
  AND u.user_id IN (
      SELECT c.user_id
      FROM Comment c
      JOIN Bug b ON c.bug_id = b.bug_id
      WHERE c.user_id <> b.reported_by
  )
ORDER BY u.full_name;


-- ----------------------------------------------------------------------------
-- C-5. Business: Bug aging report. For every Open bug, show days open,
--                project, reporter, assignee (or 'Unassigned').
--                Only show bugs older than 14 days.
-- Techniques: multi-table JOIN, LEFT JOIN, COALESCE, DATEDIFF, derived column
-- ----------------------------------------------------------------------------
SELECT b.bug_id,
       p.name AS project,
       u_rep.full_name AS reporter,
       COALESCE(u_asg.full_name, 'Unassigned') AS assignee,
       DATEDIFF(CURDATE(), b.created_at) AS days_open,
       b.severity, b.priority
FROM Bug b
JOIN Project p ON b.project_id = p.project_id
JOIN User u_rep ON b.reported_by = u_rep.user_id
LEFT JOIN User u_asg ON b.current_assignee_id = u_asg.user_id
WHERE b.status = 'Open'
  AND DATEDIFF(CURDATE(), b.created_at) > 14
ORDER BY days_open DESC;
