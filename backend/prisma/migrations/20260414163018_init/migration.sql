-- CreateTable
CREATE TABLE `users` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `role` ENUM('USER', 'ADMIN') NOT NULL DEFAULT 'USER',

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_local_auth` (
    `user_id` BIGINT NOT NULL,
    `email` VARCHAR(255) NOT NULL,
    `password_hash` VARCHAR(255) NOT NULL,

    UNIQUE INDEX `user_local_auth_email_key`(`email`),
    PRIMARY KEY (`user_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `user_social_auth` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `provider` ENUM('KAKAO', 'NAVER', 'GOOGLE') NOT NULL,
    `provider_id` VARCHAR(255) NOT NULL,

    INDEX `idx_user_social_auth_user_id`(`user_id`),
    UNIQUE INDEX `provider_provider_id_unique`(`provider`, `provider_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `devices` (
    `device_id` VARCHAR(255) NOT NULL,
    `user_id` BIGINT NULL,
    `guest_usage_count` INTEGER NOT NULL DEFAULT 0,

    INDEX `idx_devices_user_id`(`user_id`),
    PRIMARY KEY (`device_id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `message_logs` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NULL,
    `device_id` VARCHAR(255) NOT NULL,
    `source_app` VARCHAR(50) NULL,
    `sender` VARCHAR(100) NULL,
    `content` TEXT NULL,
    `has_url` BOOLEAN NOT NULL DEFAULT false,
    `collected_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_message_logs_user_id`(`user_id`),
    INDEX `idx_message_logs_device_id`(`device_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `detection_results` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `log_id` BIGINT NOT NULL,
    `extracted_urls` TEXT NULL,
    `step1_safebrowsing` ENUM('CLEAN', 'MALICIOUS') NULL,
    `step2_xgboost_score` DOUBLE NULL,
    `step3_kcelectra_intent` VARCHAR(50) NULL,
    `final_risk_score` INTEGER NULL,
    `final_risk_grade` ENUM('SAFE', 'SUSPICIOUS', 'DANGER') NOT NULL,
    `llm_response_guide` TEXT NULL,
    `analyzed_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `detection_results_log_id_key`(`log_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `alerts` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `user_id` BIGINT NOT NULL,
    `result_id` BIGINT NULL,
    `is_read` BOOLEAN NOT NULL DEFAULT false,
    `created_at` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `idx_alerts_user_id`(`user_id`),
    INDEX `idx_alerts_result_id`(`result_id`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `daily_statistics` (
    `target_date` DATE NOT NULL,
    `total_scans` INTEGER NOT NULL DEFAULT 0,
    `safe_count` INTEGER NOT NULL DEFAULT 0,
    `suspicious_count` INTEGER NOT NULL DEFAULT 0,
    `danger_count` INTEGER NOT NULL DEFAULT 0,

    PRIMARY KEY (`target_date`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `user_local_auth` ADD CONSTRAINT `user_local_auth_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `user_social_auth` ADD CONSTRAINT `user_social_auth_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `devices` ADD CONSTRAINT `devices_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `message_logs` ADD CONSTRAINT `message_logs_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `message_logs` ADD CONSTRAINT `message_logs_device_id_fkey` FOREIGN KEY (`device_id`) REFERENCES `devices`(`device_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `detection_results` ADD CONSTRAINT `detection_results_log_id_fkey` FOREIGN KEY (`log_id`) REFERENCES `message_logs`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `alerts` ADD CONSTRAINT `alerts_user_id_fkey` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `alerts` ADD CONSTRAINT `alerts_result_id_fkey` FOREIGN KEY (`result_id`) REFERENCES `detection_results`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
