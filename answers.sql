-- =============================================
-- Assignment: Database Design and Normalization
-- File: answers.sql
-- =============================================

-- =============================================
-- Question 1: Achieving 1NF (First Normal Form)
-- =============================================

-- Task: Transform the ProductDetail table into 1NF.
-- Original Data (Conceptual):
-- OrderID | CustomerName | Products
-- --------|--------------|-------------------------
-- 101     | John Doe     | Laptop, Mouse
-- 102     | Jane Smith   | Tablet, Keyboard, Mouse
-- 103     | Emily Clark  | Phone

-- Problem: The 'Products' column contains multiple values (a list), violating 1NF.
-- 1NF Rule: Each column of a table must hold only atomic (indivisible/single) values.
--           Each row must be unique.

-- Approach: Create a new structure where each row represents a single product
--           associated with an order. The OrderID and CustomerName will be
--           repeated for each product within the same order.

-- SQL Query to represent the data in 1NF format:
-- This query simulates selecting the data into a 1NF structure.
-- In a real scenario, you might create a new table and insert these rows,
-- possibly using application logic or database-specific string splitting functions
-- to parse the original 'Products' column.

-- Demonstrating the 1NF structure using SELECT with UNION ALL:
SELECT 101 AS OrderID, 'John Doe' AS CustomerName, 'Laptop' AS Product
UNION ALL
SELECT 101, 'John Doe', 'Mouse'
UNION ALL
SELECT 102, 'Jane Smith', 'Tablet'
UNION ALL
SELECT 102, 'Jane Smith', 'Keyboard'
UNION ALL
SELECT 102, 'Jane Smith', 'Mouse'
UNION ALL
SELECT 103, 'Emily Clark', 'Phone';

/*
Explanation for 1NF Transformation:
The original 'Products' column held multiple product names in a single field.
The query above transforms this by creating separate rows for each product,
ensuring that the 'Product' column now contains only one value per row (atomic).
The OrderID and CustomerName are repeated as necessary to associate each
product with its respective order and customer. This structure adheres to 1NF.

A potential table structure for this 1NF data could be:
CREATE TABLE OrderItems_1NF (
    OrderItemID INT AUTO_INCREMENT PRIMARY KEY, -- A surrogate key is often useful
    OrderID INT NOT NULL,
    CustomerName VARCHAR(255) NOT NULL, -- Still here for now, addressed in 2NF
    Product VARCHAR(255) NOT NULL
    -- Could add FOREIGN KEY (OrderID) if an Orders table exists
);
*/


-- =============================================
-- Question 2: Achieving 2NF (Second Normal Form)
-- =============================================

-- Task: Transform the OrderDetails table (already in 1NF) into 2NF.
-- Original Data (Conceptual - Assumed from the description, now in 1NF):
-- OrderID | CustomerName | Product   | Quantity
-- --------|--------------|-----------|----------
-- 101     | John Doe     | Laptop    | 2
-- 101     | John Doe     | Mouse     | 1
-- 102     | Jane Smith   | Tablet    | 3
-- 102     | Jane Smith   | Keyboard  | 1
-- 102     | Jane Smith   | Mouse     | 2
-- 103     | Emily Clark  | Phone     | 1

-- Assumed Primary Key: Composite key (OrderID, Product)
-- Problem: The table is in 1NF, but 'CustomerName' depends only on 'OrderID',
--          which is only *part* of the composite primary key. This is a partial dependency.
-- 2NF Rule: The table must be in 1NF, AND all non-key attributes must be fully
--           functionally dependent on the *entire* primary key. Partial dependencies
--           (where a non-key attribute depends on only part of the composite key)
--           are not allowed.

-- Approach: Remove the partial dependency by splitting the table into two:
--           1. An 'Orders' table: Contains information dependent only on OrderID.
--              (OrderID as PK, CustomerName)
--           2. An 'OrderItems' table: Contains information dependent on the full
--              composite key (OrderID, Product).
--              (OrderID + Product as composite PK, Quantity)
--              OrderID in OrderItems will be a Foreign Key referencing Orders.

-- SQL Queries to represent the data in 2NF format:
-- We'll show the creation of the two new tables and how data would be selected/inserted.

-- Table 1: Orders (Depends only on OrderID)
CREATE TABLE Orders_2NF (
    OrderID INT PRIMARY KEY,
    CustomerName VARCHAR(255) NOT NULL
);

-- Populate Orders_2NF using DISTINCT on the relevant columns from the original data:
-- (Simulating INSERT from the conceptual original table)
INSERT INTO Orders_2NF (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName
FROM (
    SELECT 101 AS OrderID, 'John Doe' AS CustomerName UNION ALL
    SELECT 101, 'John Doe' UNION ALL
    SELECT 102, 'Jane Smith' UNION ALL
    SELECT 102, 'Jane Smith' UNION ALL
    SELECT 102, 'Jane Smith' UNION ALL
    SELECT 103, 'Emily Clark'
) AS OriginalOrderDetailsSubset; -- Only need OrderID and CustomerName for this step

-- Display the Orders_2NF table content:
SELECT * FROM Orders_2NF;
-- Expected Output:
-- OrderID | CustomerName
-- --------|--------------
-- 101     | John Doe
-- 102     | Jane Smith
-- 103     | Emily Clark


-- Table 2: OrderItems (Depends on the full composite key: OrderID, Product)
CREATE TABLE OrderItems_2NF (
    OrderID INT NOT NULL,
    Product VARCHAR(255) NOT NULL,
    Quantity INT NOT NULL,
    PRIMARY KEY (OrderID, Product), -- Composite Primary Key
    FOREIGN KEY (OrderID) REFERENCES Orders_2NF(OrderID) -- Foreign Key link
);

-- Populate OrderItems_2NF with the remaining data:
-- (Simulating INSERT from the conceptual original table)
INSERT INTO OrderItems_2NF (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity
FROM (
    SELECT 101 AS OrderID, 'Laptop' AS Product, 2 AS Quantity UNION ALL
    SELECT 101, 'Mouse', 1 UNION ALL
    SELECT 102, 'Tablet', 3 UNION ALL
    SELECT 102, 'Keyboard', 1 UNION ALL
    SELECT 102, 'Mouse', 2 UNION ALL
    SELECT 103, 'Phone', 1
) AS OriginalOrderDetails;

-- Display the OrderItems_2NF table content:
SELECT * FROM OrderItems_2NF;
-- Expected Output:
-- OrderID | Product  | Quantity
-- --------|----------|----------
-- 101     | Laptop   | 2
-- 101     | Mouse    | 1
-- 102     | Keyboard | 1
-- 102     | Mouse    | 2
-- 102     | Tablet   | 3
-- 103     | Phone    | 1


/*
Explanation for 2NF Transformation:
The original 'OrderDetails' table suffered from a partial dependency: 'CustomerName'
depended only on 'OrderID', not the full composite key ('OrderID', 'Product').

To achieve 2NF, we split the table:
1. `Orders_2NF`: Stores `OrderID` (PK) and `CustomerName`. CustomerName is now fully
   dependent on the primary key of this table (`OrderID`).
2. `OrderItems_2NF`: Stores `OrderID` and `Product` (composite PK) and `Quantity`.
   `Quantity` is fully dependent on the entire primary key (`OrderID`, `Product`) -
   it tells us how many of a specific product are in a specific order.

This eliminates the partial dependency, reduces data redundancy (CustomerName is stored
only once per order), and makes the database structure more robust and easier to maintain.
The `FOREIGN KEY` constraint ensures referential integrity between the two tables.
*/

-- Cleanup (Optional: Drop the created tables if running this script multiple times)
-- DROP TABLE IF EXISTS OrderItems_2NF;
-- DROP TABLE IF EXISTS Orders_2NF;
