use target;

-- load geolocation data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\geolocation.csv" 
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from geolocation;

-- load customers data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\customers.csv" 
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from customers;

-- load sellers data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\sellers.csv" 
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from sellers;

-- load products data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\products.csv" 
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from products;

-- load orders data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\orders.csv" 
INTO TABLE orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from orders;

-- load order_items data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\order_items.csv" 
INTO TABLE order_items
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from order_items;

-- load order_payment data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\payments.csv" 
INTO TABLE order_payment
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from order_payment;

-- load order_reviews data
LOAD DATA local INFILE "C:\\Users\\chins\\OneDrive\\source\\scaler_business_casestudies\\10_target_case\\Target- SQL Business Case\\order_reviews.csv" 
INTO TABLE order_reviews
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
;

select count(*) from order_reviews;


