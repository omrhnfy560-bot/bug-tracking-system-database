DROP DATABASE IF EXISTS bug_tracker;
CREATE DATABASE bug_tracker;
USE bug_tracker;

CREATE TABLE Role (
    role_id      INT PRIMARY KEY AUTO_INCREMENT,
    role_name    VARCHAR(30) NOT NULL UNIQUE,
    description  VARCHAR(150)
);

CREATE TABLE User (
    user_id        INT PRIMARY KEY AUTO_INCREMENT,
    email          VARCHAR(100) NOT NULL UNIQUE,
    full_name      VARCHAR(80)  NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    role_id        INT NOT NULL,
    created_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES Role(role_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Project (
    project_id    INT PRIMARY KEY AUTO_INCREMENT,
    name          VARCHAR(100) NOT NULL UNIQUE,
    description   TEXT,
    status        ENUM('Active','Archived') NOT NULL DEFAULT 'Active',
    start_date    DATE NOT NULL,
    created_by    INT NOT NULL,
    FOREIGN KEY (created_by) REFERENCES User(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE ProjectMember (
    project_id    INT NOT NULL,
    user_id       INT NOT NULL,
    project_role  ENUM('Manager','Developer','Tester','Reporter') NOT NULL,
    joined_at     DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, user_id),
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Bug (
    bug_id              INT PRIMARY KEY AUTO_INCREMENT,
    project_id          INT NOT NULL,
    title               VARCHAR(150) NOT NULL,
    description         TEXT,
    severity            ENUM('Low','Medium','High','Critical') NOT NULL,
    priority            TINYINT NOT NULL CHECK (priority BETWEEN 1 AND 5),
    status              ENUM('Open','InProgress','Resolved','Closed','Reopened') 
                        NOT NULL DEFAULT 'Open',
    reported_by         INT NOT NULL,
    current_assignee_id INT NULL,
    created_at          DATETIME DEFAULT CURRENT_TIMESTAMP,
    resolved_at         DATETIME NULL,
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (reported_by) REFERENCES User(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (current_assignee_id) REFERENCES User(user_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CHECK (resolved_at IS NULL OR resolved_at >= created_at)
);

CREATE TABLE BugAssignment (
    assignment_id  INT PRIMARY KEY AUTO_INCREMENT,
    bug_id         INT NOT NULL,
    assigned_to    INT NOT NULL,
    assigned_by    INT NOT NULL,
    assigned_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
    unassigned_at  DATETIME NULL,
    FOREIGN KEY (bug_id) REFERENCES Bug(bug_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES User(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (assigned_by) REFERENCES User(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (unassigned_at IS NULL OR unassigned_at >= assigned_at)
);

CREATE TABLE Comment (
    comment_id  INT PRIMARY KEY AUTO_INCREMENT,
    bug_id      INT NOT NULL,
    user_id     INT NOT NULL,
    content     TEXT NOT NULL,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bug_id) REFERENCES Bug(bug_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE BugHistory (
    history_id  INT PRIMARY KEY AUTO_INCREMENT,
    bug_id      INT NOT NULL,
    changed_by  INT NOT NULL,
    field_name  ENUM('status','priority','severity','assignee') NOT NULL,
    old_value   VARCHAR(100),
    new_value   VARCHAR(100),
    changed_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bug_id) REFERENCES Bug(bug_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES User(user_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
);
