-- ============================================================
-- Royal Star Boys — Private Community Fund Management System
-- Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS royal_star_boys CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE royal_star_boys;

-- -----------------------------------------------------------
-- group_config (single-row table)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS group_config (
  id                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  group_name            VARCHAR(100)   NOT NULL DEFAULT 'Royal Star Boys',
  monthly_subscription  DECIMAL(12,2)  NOT NULL DEFAULT 500.00,
  interest_rate         DECIMAL(5,2)   NOT NULL DEFAULT 5.00,  -- percent per month
  total_fund            DECIMAL(15,2)  NOT NULL DEFAULT 0.00,
  announcement          TEXT           NULL,
  created_at            DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Seed the single config row
INSERT IGNORE INTO group_config (id, group_name, monthly_subscription, interest_rate, total_fund)
VALUES (1, 'Royal Star Boys', 500.00, 5.00, 0.00);

-- -----------------------------------------------------------
-- users
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(100)  NOT NULL,
  email         VARCHAR(150)  NOT NULL UNIQUE,
  password_hash VARCHAR(255)  NOT NULL,
  role          ENUM('admin','member') NOT NULL DEFAULT 'member',
  phone         VARCHAR(20)   NULL,
  credit_score  SMALLINT      NOT NULL DEFAULT 500,
  is_active     TINYINT(1)    NOT NULL DEFAULT 1,
  joined_date   DATE          NULL,
  created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_users_email (email),
  INDEX idx_users_role  (role)
) ENGINE=InnoDB;

-- -----------------------------------------------------------
-- contributions
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS contributions (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id     INT UNSIGNED  NOT NULL,
  month_year  VARCHAR(7)    NOT NULL,  -- e.g. '2025-01'
  amount      DECIMAL(12,2) NOT NULL,
  status      ENUM('paid','pending','missed') NOT NULL DEFAULT 'paid',
  paid_at     DATETIME      NULL,
  notes       VARCHAR(255)  NULL,
  created_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY ux_contribution_user_month (user_id, month_year),
  INDEX idx_contributions_user   (user_id),
  INDEX idx_contributions_month  (month_year),
  CONSTRAINT fk_contributions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------------
-- loans
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS loans (
  id                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id           INT UNSIGNED  NOT NULL,
  principal         DECIMAL(12,2) NOT NULL,
  interest_rate     DECIMAL(5,2)  NOT NULL,  -- rate at time of approval
  duration_months   TINYINT UNSIGNED NOT NULL DEFAULT 1,
  interest_amount   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  total_payable     DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  remaining_balance DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  purpose           VARCHAR(255)  NULL,
  status            ENUM('pending','active','closed','rejected') NOT NULL DEFAULT 'pending',
  approved_by       INT UNSIGNED  NULL,
  approved_at       DATETIME      NULL,
  due_date          DATE          NULL,
  created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_loans_user   (user_id),
  INDEX idx_loans_status (status),
  CONSTRAINT fk_loans_user     FOREIGN KEY (user_id)     REFERENCES users(id) ON DELETE RESTRICT,
  CONSTRAINT fk_loans_approver FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- -----------------------------------------------------------
-- repayments
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS repayments (
  id                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  loan_id            INT UNSIGNED  NOT NULL,
  user_id            INT UNSIGNED  NOT NULL,
  amount             DECIMAL(12,2) NOT NULL,
  principal_portion  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  interest_portion   DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  notes              VARCHAR(255)  NULL,
  created_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_repayments_loan (loan_id),
  INDEX idx_repayments_user (user_id),
  CONSTRAINT fk_repayments_loan FOREIGN KEY (loan_id)  REFERENCES loans(id)  ON DELETE RESTRICT,
  CONSTRAINT fk_repayments_user FOREIGN KEY (user_id)  REFERENCES users(id)  ON DELETE RESTRICT
) ENGINE=InnoDB;

-- -----------------------------------------------------------
-- transactions (immutable ledger)
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS transactions (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id          INT UNSIGNED  NULL,
  type             ENUM('contribution','loan_disbursement','repayment','adjustment') NOT NULL,
  amount           DECIMAL(12,2) NOT NULL,
  description      VARCHAR(255)  NOT NULL,
  group_fund_after DECIMAL(15,2) NOT NULL,
  reference_id     INT UNSIGNED  NULL,  -- FK to contribution/loan/repayment id
  created_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_transactions_user (user_id),
  INDEX idx_transactions_type (type),
  INDEX idx_transactions_date (created_at),
  CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;
