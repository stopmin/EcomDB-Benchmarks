CREATE TABLE Users (
                       user_id INT PRIMARY KEY AUTO_INCREMENT,
                       username VARCHAR(100),
                       total_spending DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE Orders (
                        order_id INT PRIMARY KEY AUTO_INCREMENT,
                        user_id INT,
                        order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Order_Items (
                             item_id INT PRIMARY KEY AUTO_INCREMENT,
                             order_id INT,
                             product_name VARCHAR(100),
                             price DECIMAL(10, 2),
                             quantity INT,
                             FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);


-- 사용자 데이터 삽입

DELIMITER //

CREATE PROCEDURE InsertUsers()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 10000 DO
        INSERT INTO Users (username) VALUES (CONCAT('User', i));
        SET i = i + 1;
END WHILE;
END //

DELIMITER ;

CALL InsertUsers();

-- 주문 데이터 삽입
INSERT INTO Orders (user_id)
SELECT user_id FROM Users ORDER BY RAND() LIMIT 10000;

-- 주문 항목 데이터 삽입
INSERT INTO Order_Items (order_id, product_name, price, quantity)
SELECT o.order_id, CONCAT('Product', FLOOR(RAND() * 100)), ROUND(RAND() * 100, 2), FLOOR(RAND() * 10 + 1)
FROM Orders o;


-- Query 1: 총 지출이 500 이상인 사용자를 조회하고 지출 내림차순으로 정렬 - 58ms, 65ms, 54ms
SELECT u.user_id, SUM(oi.price * oi.quantity) AS total_spending
FROM Users u
         JOIN Orders o ON u.user_id = o.user_id
         JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY u.user_id
HAVING total_spending > 500
ORDER BY total_spending DESC;

-- Query 2: Orders 테이블에 10,000개의 주문 데이터 삽입 - 99 ms
-- (위에서 이미 제공됨)

-- Query 3: 사용자의 총 지출 금액 및 주문 개수 조회 - 65 ms, 70 ms, 62 ms,
SELECT u.user_id, COUNT(o.order_id) AS order_count, SUM(oi.price * oi.quantity) AS total_spending
FROM Users u
         LEFT JOIN Orders o ON u.user_id = o.user_id
         LEFT JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY u.user_id;

-- Query 4: 사용자의 총 지출이 1000 이상인 경우 주문 가격을 10% 할인 - 40ms, 42ms, 40ms
UPDATE Order_Items oi
SET price = price * 0.9
WHERE oi.order_id IN (
    SELECT o.order_id
    FROM Orders o
             JOIN Users u ON o.user_id = u.user_id
    WHERE u.total_spending > 1000
);
