-- Table for HU-011 Create Discussion

CREATE TABLE discussions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    user_id BIGINT NOT NULL,

    technology_id BIGINT NOT NULL,

    title VARCHAR(150) NOT NULL,

    content TEXT NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',

    created_at TIMESTAMP WITH TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_discussion_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_discussion_technology
        FOREIGN KEY (technology_id)
        REFERENCES technologies(id)
        ON DELETE RESTRICT,

    CONSTRAINT chk_discussion_title
        CHECK (btrim(title) <> ''),

    CONSTRAINT chk_discussion_content
        CHECK (btrim(content) <> ''),

    CONSTRAINT chk_discussion_status
        CHECK (status IN ('OPEN', 'RESOLVED'))
);

CREATE INDEX idx_discussions_user_created
    ON discussions (user_id, created_at DESC);

CREATE INDEX idx_discussions_technology
    ON discussions (technology_id, created_at DESC);