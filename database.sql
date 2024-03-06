CREATE DATABASE elevatesocials;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE
    company_funds (
        id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
        company_name TEXT NOT NULL,
        available_balance NUMERIC(17, 2) NOT NULL DEFAULT 0.00,
        currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE
    users (
        id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
        first_name VARCHAR(255) NOT NULL,
        last_name VARCHAR(255) NOT NULL,
        user_name VARCHAR(255) UNIQUE,
        email VARCHAR(255) UNIQUE NOT NULL,
        balance NUMERIC(17, 2) NOT NULL DEFAULT 0.00,
        password VARCHAR(255) NOT NULL,
        nationality VARCHAR(255) DEFAULT 'Nigerian' NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE
    withdrawals (
        id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id TEXT NOT NULL REFERENCES users (id),
        payment_amount NUMERIC(17, 2) NOT NULL DEFAULT 0.00,
        currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
        transaction_reference TEXT NOT NULL,
        payment_gateway TEXT NOT NULL DEFAULT 'Paystack',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE
    tasks (
        id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id TEXT NOT NULL REFERENCES users (id),
        task_description TEXT NOT NULL,
        social_media VARCHAR(255) NOT NULL,
        payment_amount NUMERIC(17, 2) NOT NULL DEFAULT 0.00,
        currency VARCHAR(3) NOT NULL DEFAULT 'NGN',
        transaction_reference TEXT NOT NULL,
        payment_gateway TEXT NOT NULL DEFAULT 'Paystack',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE
    task_performances (
        id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
        task_id TEXT NOT NULL REFERENCES tasks (id),
        performer_id TEXT NOT NULL REFERENCES users (id),
        completion_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT fk_task_performances_task_id FOREIGN KEY (task_id) REFERENCES tasks (id),
        CONSTRAINT fk_task_performances_performer_id FOREIGN KEY (performer_id) REFERENCES users (id),
        CONSTRAINT uc_task_performances_unique_task_performer UNIQUE (task_id, performer_id)
    );

CREATE TABLE
    task_rewards (
        id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
        task_performance_id TEXT NOT NULL REFERENCES task_performances (id),
        performer_id TEXT NOT NULL REFERENCES users (id),
        reward_received NUMERIC(17, 2) NOT NULL DEFAULT 0.00,
        reversal BOOLEAN DEFAULT FALSE,
        modification_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE
    access_tokens (
        id TEXT PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id TEXT NOT NULL REFERENCES users (id),
        access_token TEXT NOT NULL,
        media_type TEXT NOT NULL,
        expires_in_sec INT CHECK (expires_in_sec >= 0) DEFAULT NULL,
        expires_in_days INT CHECK (expires_in_days >= 0) DEFAULT NULL,
        media_user_id TEXT,
        modified_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT unique_user_media UNIQUE (user_id, media_type)
    );


-- Indexes
CREATE INDEX idx_user_id_users ON users (id);

CREATE INDEX idx_user_id_withdrawals ON withdrawals (user_id);

CREATE INDEX idx_user_id_tasks ON tasks (user_id);

CREATE INDEX idx_task_id_task_performance ON task_performances (task_id);

-- Functions

-- get_total_performers begins
CREATE OR REPLACE FUNCTION get_total_performers(task_id TEXT)
RETURNS INTEGER AS $$
DECLARE
    total_performers INTEGER;
BEGIN
    SELECT COUNT(DISTINCT performer_id)
    INTO total_performers
    FROM task_performances tp
    JOIN tasks t ON tp.task_id = t.id
    WHERE t.id = get_total_performers.task_id
        AND t.status = 'in progress';

    RETURN total_performers;
END;
$$ LANGUAGE plpgsql;

SELECT get_total_performers('your_task_id_here');
-- get_total_performers end

-- get_users_performed_in_tasks begins
CREATE OR REPLACE FUNCTION get_users_performed_in_tasks(task_id TEXT)
RETURNS TABLE (
    user_name VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255)
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT u.user_name, u.first_name, u.last_name
    FROM users u
    JOIN task_performances tp ON u.id = tp.performer_id
    WHERE tp.task_id = get_users_performed_in_tasks.task_id;
END;
$$ LANGUAGE plpgsql;

-- get_users_performed_in_tasks ends

-- get_tasks_in_progress_for_user begins
CREATE OR REPLACE FUNCTION get_tasks_in_progress_for_user(user_id TEXT)
RETURNS TABLE (
    task_id TEXT,
    task_description TEXT,
    social_media VARCHAR(255),
    payment_amount NUMERIC(17, 2),
    currency VARCHAR(3),
    transaction_reference TEXT,
    payment_gateway TEXT,
    created_at TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT t.id AS task_id,
           t.task_description,
           t.social_media,
           t.payment_amount,
           t.currency,
           t.transaction_reference,
           t.payment_gateway,
           t.created_at
    FROM tasks t
    JOIN users u ON t.user_id = u.id
    WHERE u.id = get_tasks_in_progress_for_user.user_id
      AND t.status = 'in progress';
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_tasks_in_progress_for_user('your_user_id_here');
-- get_tasks_in_progress_for_user ends

-- Stored Procedures
-- subtract_and_distribute begins
CREATE OR REPLACE PROCEDURE subtract_and_distribute(
    IN currency_to_subtract VARCHAR(3),
    INOUT payment_amount NUMERIC(17, 2),
    IN task_description TEXT,
    IN social_media VARCHAR(255),
    IN payment_gateway TEXT,
    IN transaction_reference TEXT,
    IN user_id TEXT,
    OUT new_task_id TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    company_fund_id TEXT;
    company_fund_amount NUMERIC(17, 2);
    task_payment_amount NUMERIC(17, 2);
BEGIN
    -- Get the ID of the company fund row that matches the currency
    SELECT id, available_balance INTO company_fund_id, company_fund_amount
    FROM company_funds
    WHERE currency = currency_to_subtract
    FOR UPDATE;

    -- Calculate the amount to subtract (20%)
    task_payment_amount := payment_amount * 0.8;
    payment_amount := payment_amount * 0.2;

    -- Update the company funds with the subtracted amount
    UPDATE company_funds
    SET available_balance = available_balance + payment_amount
    WHERE id = company_fund_id;

    -- Insert a record into the tasks table to track the task payment
    INSERT INTO tasks (id, task_description, social_media, payment_amount, currency, transaction_reference, payment_gateway, user_id)
    VALUES (uuid_generate_v4(), task_description, social_media, task_payment_amount, currency_to_subtract, transaction_reference, payment_gateway)
    RETURNING id INTO new_task_id;

    -- Insert a record into another table to track the task payment
    -- INSERT INTO task_payments (task_id, payment_amount, payment_date)
    -- VALUES (new_task_id, task_payment_amount, CURRENT_TIMESTAMP);

END;
$$;

CALL subtract_and_distribute('NGN', 100.00, 'Task description', 'Social media platform', 'Payment gateway', new_task_id);
-- subtract_and_distribute ends