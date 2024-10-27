CREATE TABLE Users (
                       user_id SERIAL PRIMARY KEY,
                       username VARCHAR(100),
                       total_spending DECIMAL(10, 2) DEFAULT 0
);

CREATE TABLE Orders (
                        order_id SERIAL PRIMARY KEY,
                        user_id INT,
                        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Order_Items (
                             item_id SERIAL PRIMARY KEY,
                             order_id INT,
                             product_name VARCHAR(100),
                             price DECIMAL(10, 2),
                             quantity INT,
                             FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);


-- 사용자 데이터 삽입
DO $$
DECLARE
i INT := 1;
BEGIN
    WHILE i <= 10000 LOOP
        EXECUTE format('INSERT INTO Users (username) VALUES (''User%s'')', i);
        i := i + 1;
END LOOP;
END $$;


-- 주문 데이터 삽입 77 ms
INSERT INTO Orders (user_id)
SELECT user_id FROM Users ORDER BY RANDOM() LIMIT 10000;

-- 주문 항목 데이터 삽입
INSERT INTO Order_Items (order_id, product_name, price, quantity)
SELECT o.order_id,
       CONCAT('Product', FLOOR(RANDOM() * 100)),
       ROUND((RANDOM() * 100)::numeric, 2),
       FLOOR(RANDOM() * 10 + 1)
FROM Orders o;

-- Query 1: 총 지출이 500 이상인 사용자를 조회하고 지출 내림차순으로 정렬 41ms, 29ms, 30ms
SELECT u.user_id, SUM(oi.price * oi.quantity) AS total_spending
FROM Users u
         JOIN Orders o ON u.user_id = o.user_id
         JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY u.user_id
HAVING total_spending > 500
ORDER BY total_spending DESC;

-- Query 2: Orders 테이블에 10,000개의 주문 데이터 삽입 77ms
-- (위에서 이미 제공됨)

-- Query 3: 사용자의 총 지출 금액 및 주문 개수 조회 65ms,44ms,46ms
SELECT u.user_id, COUNT(o.order_id) AS order_count, SUM(oi.price * oi.quantity) AS total_spending
FROM Users u
         LEFT JOIN Orders o ON u.user_id = o.user_id
         LEFT JOIN Order_Items oi ON o.order_id = oi.order_id
GROUP BY u.user_id;

-- Query 4: 사용자의 총 지출이 1000 이상인 경우 주문 가격을 10% 할인 16ms, 15ms, 15ms
UPDATE Order_Items oi
SET price = price * 0.9
WHERE oi.order_id IN (
    SELECT o.order_id
    FROM Orders o
             JOIN Users u ON o.user_id = u.user_id
    WHERE u.total_spending > 1000
);

