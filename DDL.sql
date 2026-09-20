CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE technologies (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL,

    CONSTRAINT chk_technology_type
        CHECK (type IN ('LANGUAGE', 'FRAMEWORK', 'ROLE')),

    CONSTRAINT chk_technology_name
        CHECK (btrim(name) <> '')
);

CREATE TABLE projects (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    user_id BIGINT NOT NULL,

    title VARCHAR(50) NOT NULL,

    description VARCHAR(250) NOT NULL,

    repository_url TEXT,

    created_at TIMESTAMP WITH TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_project_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_project_title
        CHECK (btrim(title) <> ''),

    CONSTRAINT chk_project_description
        CHECK (btrim(description) <> '')
);

CREATE TABLE project_technologies (
    project_id BIGINT NOT NULL,
    technology_id BIGINT NOT NULL,

    PRIMARY KEY (project_id, technology_id),

    CONSTRAINT fk_project_technology_project
        FOREIGN KEY (project_id)
        REFERENCES projects(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_project_technology_technology
        FOREIGN KEY (technology_id)
        REFERENCES technologies(id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_projects_user_created
    ON projects (user_id, created_at DESC);

CREATE INDEX idx_project_technologies_technology
    ON project_technologies (technology_id, project_id);
