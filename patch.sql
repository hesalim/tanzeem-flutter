CREATE DATABASE nazzem;
USE nazzem;

CREATE TABLE businesses (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    email VARCHAR(150),
    business_type VARCHAR(50),
    is_team_business BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    business_id BIGINT,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),

    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(30),

    password_hash VARCHAR(255) NOT NULL,

    role ENUM(
        'SUPER_ADMIN',
        'OWNER',
        'STAFF'
    ) NOT NULL,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_users_business
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
);

CREATE TABLE staff (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    business_id BIGINT NOT NULL,

    user_id BIGINT,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),

    phone VARCHAR(30),
    email VARCHAR(150),

    is_owner BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_staff_business
        FOREIGN KEY (business_id)
        REFERENCES businesses(id),

    CONSTRAINT fk_staff_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
);

CREATE TABLE services (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    business_id BIGINT NOT NULL,

    name VARCHAR(150) NOT NULL,

    description TEXT,

    duration_minutes INT NOT NULL,

    price DECIMAL(10,2) NOT NULL,

    booking_type ENUM(
        'INDIVIDUAL',
        'GROUP'
    ) NOT NULL DEFAULT 'INDIVIDUAL',

    max_participants INT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_services_business
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
);


CREATE TABLE staff_services (
    staff_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,

    PRIMARY KEY (staff_id, service_id),

    CONSTRAINT fk_staff_services_staff
        FOREIGN KEY (staff_id)
        REFERENCES staff(id),

    CONSTRAINT fk_staff_services_service
        FOREIGN KEY (service_id)
        REFERENCES services(id)
);

CREATE TABLE customers (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    business_id BIGINT NOT NULL,

    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100),

    phone VARCHAR(30) NOT NULL,
    email VARCHAR(150),

    notes TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_customers_business
        FOREIGN KEY (business_id)
        REFERENCES businesses(id)
);

CREATE INDEX idx_customers_business_phone
ON customers(business_id, phone);

CREATE INDEX idx_customers_business_name
ON customers(business_id, first_name, last_name);

CREATE TABLE appointments (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    business_id BIGINT NOT NULL,

    customer_id BIGINT NOT NULL,

    staff_id BIGINT NOT NULL,

    start_at DATETIME NOT NULL,
    end_at DATETIME NOT NULL,

    status ENUM(
        'CONFIRMED',
        'COMPLETED',
        'CANCELLED'
    ) NOT NULL DEFAULT 'CONFIRMED',

    total_price DECIMAL(10,2) NOT NULL DEFAULT 0,

    notes TEXT,

    created_by_user_id BIGINT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_appointments_business
        FOREIGN KEY (business_id)
        REFERENCES businesses(id),

    CONSTRAINT fk_appointments_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(id),

    CONSTRAINT fk_appointments_staff
        FOREIGN KEY (staff_id)
        REFERENCES staff(id),

    CONSTRAINT fk_appointments_created_by
        FOREIGN KEY (created_by_user_id)
        REFERENCES users(id)
);

CREATE INDEX idx_appointments_business_start
ON appointments(business_id, start_at);

CREATE INDEX idx_appointments_staff_start
ON appointments(staff_id, start_at);

CREATE TABLE appointment_services (
    appointment_id BIGINT NOT NULL,

    service_id BIGINT NOT NULL,

    price DECIMAL(10,2) NOT NULL,

    duration_minutes INT NOT NULL,

    PRIMARY KEY (
        appointment_id,
        service_id
    ),

    CONSTRAINT fk_appointment_services_appointment
        FOREIGN KEY (appointment_id)
        REFERENCES appointments(id),

    CONSTRAINT fk_appointment_services_service
        FOREIGN KEY (service_id)
        REFERENCES services(id)
);
CREATE TABLE group_sessions (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    business_id BIGINT NOT NULL,
    service_id BIGINT NOT NULL,
    staff_id BIGINT NOT NULL,

    start_at DATETIME NOT NULL,
    end_at DATETIME NOT NULL,

    capacity INT NOT NULL,

    status ENUM(
        'CONFIRMED',
        'CANCELLED',
        'COMPLETED'
    ) NOT NULL DEFAULT 'CONFIRMED',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (business_id)
        REFERENCES businesses(id),

    FOREIGN KEY (service_id)
        REFERENCES services(id),

    FOREIGN KEY (staff_id)
        REFERENCES staff(id)
);

CREATE TABLE group_session_bookings (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,

    group_session_id BIGINT NOT NULL,
    customer_id BIGINT NOT NULL,

    spots_booked INT NOT NULL,

    price_per_spot DECIMAL(10,2) NOT NULL,

    status ENUM(
        'CONFIRMED',
        'CANCELLED'
    ) NOT NULL DEFAULT 'CONFIRMED',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (group_session_id)
        REFERENCES group_sessions(id),

    FOREIGN KEY (customer_id)
        REFERENCES customers(id)
);