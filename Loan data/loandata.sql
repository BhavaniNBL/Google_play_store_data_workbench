use loandata;

CREATE TABLE loan_data (
    credit_policy INT,
    purpose VARCHAR(50),
    int_rate DECIMAL(6,4),
    installment DECIMAL(10,2),
    log_annual_inc DECIMAL(10,8),
    dti DECIMAL(6,2),
    fico INT,
    days_with_cr_line DECIMAL(10,4),
    revol_bal INT,
    revol_util DECIMAL(6,2),
    inq_last_6mths INT,
    delinq_2yrs INT,
    pub_rec INT,
    not_fully_paid INT
);


-- calculate_new_rate function 

DELIMITER $$

CREATE FUNCTION calculate_new_rate(
    fico INT,
    int_rate DECIMAL(10,4)
) RETURNS DECIMAL(10,4)
DETERMINISTIC
BEGIN
    DECLARE updated_rate DECIMAL(10,4);

    IF fico >= 750 THEN
        SET updated_rate = int_rate;
    ELSEIF fico >= 700 THEN
        SET updated_rate = int_rate + 0.005;
    ELSEIF fico >= 600 THEN
        SET updated_rate = int_rate + 0.008;
    ELSE
        SET updated_rate = int_rate + 0.013;
    END IF;

    RETURN ROUND(updated_rate, 4);
END$$

DELIMITER ;



-- calculate_total_payment function

DELIMITER $$

CREATE FUNCTION calculate_total_payment(
    fico INT,
    int_rate DECIMAL(10,4),
    installment DECIMAL(10,2),
    term_period INT,        
    period_type VARCHAR(10)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE updated_rate DECIMAL(10,4);
    DECLARE loan_amount DECIMAL(10,2);
    DECLARE total_interest DECIMAL(10,2);
    DECLARE total_payment DECIMAL(10,2);
    SET updated_rate = calculate_new_rate(fico, int_rate);

    IF period_type = 'monthly' THEN
        SET loan_amount = installment * term_period;
        SET total_interest = loan_amount * updated_rate * (term_period / 12);
        SET total_payment = loan_amount + total_interest;
        RETURN ROUND(total_payment / term_period, 2);

    ELSEIF period_type = 'yearly' THEN
        SET loan_amount = installment * 12 * term_period;
        SET total_interest = loan_amount * updated_rate * term_period;
        SET total_payment = loan_amount + total_interest;
        RETURN ROUND(total_payment / term_period, 2);

    ELSE
        RETURN NULL; -- Invalid period_type
    END IF;
END$$

DELIMITER ;



-- get_installment_updates procedure

DELIMITER $$

CREATE PROCEDURE get_installment_updates()
BEGIN
    SELECT 
        fico,
        int_rate,
        calculate_new_rate(fico, int_rate) AS new_int_rate,
        installment AS original_installment,
        -- calculate_yearly_installment(fico, int_rate, installment, 1) AS yearly_installment,
        calculate_total_payment(fico, int_rate, installment, 12, 'monthly') AS monthly_installment,
        calculate_total_payment(fico, int_rate, installment, 1, 'yearly') AS yearly_installment
    FROM loan_data;
END$$

DELIMITER ;



SELECT 
    fico,
    int_rate,
    calculate_new_rate(fico, int_rate) AS new_int_rate,
    installment AS original_installment,
    -- calculate_new_installment(fico, int_rate, installment, 1) AS new_installment,
    calculate_total_payment(fico, int_rate, installment, 12, 'monthly') AS monthly_installment,
	calculate_total_payment(fico, int_rate, installment, 1, 'yearly') AS yearly_installment
FROM loan_data;



call get_installment_updates();


ALTER TABLE loan_data
ADD COLUMN id INT NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;


desc loan_data;
select * from loan_data;


-- partitioning 

CREATE TABLE loan_data_partitioned (
    id INT,
    credit_policy INT,
    purpose VARCHAR(50),
    int_rate DECIMAL(6,4),
    installment DECIMAL(10,2),
    log_annual_inc DECIMAL(10,8),
    dti DECIMAL(6,2),
    fico INT,
    days_with_cr_line DECIMAL(10,4),
    revol_bal INT,
    revol_util DECIMAL(6,2),
    inq_last_6mths INT,
    delinq_2yrs INT,
    pub_rec INT,
    not_fully_paid INT,
    INDEX(fico)
)
PARTITION BY RANGE (fico) (
    PARTITION p1 VALUES LESS THAN (650),
    PARTITION p2 VALUES LESS THAN (700),
    PARTITION p3 VALUES LESS THAN (750),
    PARTITION p4 VALUES LESS THAN MAXVALUE
);



INSERT INTO loan_data_partitioned 
(credit_policy, purpose, int_rate, installment, log_annual_inc, dti, fico, days_with_cr_line, revol_bal, revol_util, inq_last_6mths, delinq_2yrs, pub_rec, not_fully_paid)
SELECT
credit_policy, purpose, int_rate, installment, log_annual_inc, dti, fico, days_with_cr_line, revol_bal, revol_util, inq_last_6mths, delinq_2yrs, pub_rec, not_fully_paid
FROM loan_data;

SELECT COUNT(*) FROM loan_data_partitioned PARTITION(p1);
SELECT COUNT(*) FROM loan_data_partitioned PARTITION(p2);
SELECT COUNT(*) FROM loan_data_partitioned PARTITION(p3);
SELECT COUNT(*) FROM loan_data_partitioned PARTITION(p4);

