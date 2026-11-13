CREATE TABLE IF NOT EXISTS events (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_time TIMESTAMPTZ NOT NULL,
    event_type TEXT NOT NULL CHECK (event_type IN ('view','cart','purchase')),
    product_id BIGINT NOT NULL,
    category_id NUMERIC(20,0),
    category_code TEXT,
    brand TEXT,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    user_id BIGINT NOT NULL,
    user_session TEXT
);
CREATE INDEX IF NOT EXISTS idx_events_time ON events (event_time);
CREATE INDEX IF NOT EXISTS idx_events_user_time ON events (user_id, event_time);
CREATE INDEX IF NOT EXISTS idx_events_session_time ON events (user_session, event_time) WHERE user_session IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_events_type_time ON events (event_type, event_time);
CREATE INDEX IF NOT EXISTS idx_events_product_type ON events (product_id, event_type);
