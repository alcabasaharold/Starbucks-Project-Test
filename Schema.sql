-- Starbucks SCHEMAS

-- Drop tables if they exist
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS stores;

-- Import Order:
-- 1st: stores
-- 2nd: products
-- 3rd: customers
-- 4th: sales

-- Stores Table (instead of city, since Starbucks tracks stores)
CREATE TABLE stores
(
    store_id INT PRIMARY KEY,
    store_name VARCHAR(50),         -- e.g., "Starbucks Mumbai Central"
    city VARCHAR(30),               -- city of the store
    population BIGINT,              -- city population (optional, if we want analytics)
    avg_rent FLOAT,                 -- estimated rent in city
    store_rank INT                  -- hypothetical ranking by performance
);

-- Customers Table
CREATE TABLE customers
(
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    city VARCHAR(30),               -- customer city
    signup_date DATE                 -- when customer first bought Starbucks
);

-- Products Table
CREATE TABLE products
(
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),       -- e.g., "Caffe Latte", "Espresso"
    category VARCHAR(20),           -- Coffee, Tea, Pastry, Merchandise
    price FLOAT
);

-- Sales Table
CREATE TABLE sales
(
    sale_id INT PRIMARY KEY,
    sale_date DATE,
    product_id INT,
    customer_id INT,
    store_id INT,
    quantity INT,
    total FLOAT,                    -- total = price * quantity
    rating INT,                     -- optional: customer rating 1–5
    CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
    CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_stores FOREIGN KEY (store_id) REFERENCES stores(store_id)
);
