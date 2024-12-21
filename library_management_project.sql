CREATE schema library_management;

SELECT *
FROM books;
SELECT *
FROM branch;
SELECT *
FROM employees;
SELECT *
FROM issued_status;
SELECT *
FROM return_status;
SELECT*
FROM members;


-- Task 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');


-- 2. Task 2: Update an Existing Member's Address
UPDATE members
SET member_address = '125 Main St'
WHERE member_id = 'C101';

 SELECT*
FROM members;

-- Task 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101';


-- Task 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT issued_member_id, COUNT(issued_id) as total_book_issued
FROM issued_status
GROUP BY issued_member_id
HAVING COUNT(issued_id) > 1;

-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**
CREATE TABLE book_counts
AS 
SELECT b.isbn,
b.book_title,
COUNT(i.issued_book_isbn) count_books_issued
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY 1,2;

SELECT*
FROM book_counts;


-- 4. Data Analysis & Findings
-- The following SQL queries were used to address specific questions:

-- Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Classic';


-- Task 8: Find Total Rental Income by Category:

SELECT
b.category, 
SUM(rental_price) as rent_pri,
COUNT(*)
FROM books b
JOIN issued_status i
ON b.isbn = i.issued_book_isbn
GROUP BY 1;

-- Task 9. List Members Who Registered in the Last 180 Days:

SELECT * FROM members;



SELECT *
FROM members
WHERE reg_date >= CUR_DATE() - INTERVAL 180 day;


-- Task 10. List Employees with Their Branch Manager's Name and their branch details:
-- employees , branch manager, branch details 

SELECT e.emp_name as employee, e2.emp_name as manager, b.branch_address, b.branch_id
FROM employees e
JOIN branch b
ON e.branch_id = b.branch_id
JOIN employees e2
ON e2.emp_id = b.manager_id
ORDER BY b.branch_id;

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold 7$:

CREATE TABLE books_prce_greater_than_7$
AS 
SELECT *
FROM books
WHERE rental_price > 7;

select *
from books_prce_greater_than_7$
;


-- Task 12: Retrieve the List of Books Not Yet Returned

SELECT *
FROM issued_status i
 LEFT JOIN return_status r
ON i.issued_id = r.issued_id
WHERE r.issued_id IS NULL;

/*
Advanced SQL Operations
Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). 
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

-- issued_status, members, books, issued_status, return_status
-- filter books which have been returened
-- overdue >30 days

SELECT ist.issued_member_id, 
m.member_id, 
b.book_title, 
ist.issued_date,
CURDATE() - ist.issued_date as overdue_days
FROM issued_status as ist
JOIN members as m
	ON m.member_id = ist.issued_member_id
JOIN books b 
	ON b.isbn = ist.issued_book_isbn
LEFT JOIN return_status rs
	ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
AND CURDATE() - ist.issued_date > 30
ORDER BY 1;


/* Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned 
(based on entries in the return_status table).
*/

SELECT *
FROM issued_status
WHERE issued_book_isbn = '978-0-553-29698-2';

SELECT *
FROM books
WHERE isbn = '978-0-553-29698-2'
;

UPDATE books
SET status = 'no'
WHERE isbn = '978-0-553-29698-2';

SELECT *
FROM return_status
WHERE issued_id = 'ISI137';


INSERT INTO return_status(return_id, issued_id, return_date)
VALUES('RS137','IS137', current_date);
SELECT *
FROM return_status;

UPDATE books
SET status = 'yes'
WHERE isbn = '978-0-553-29698-2';


-- stored procedure

DELIMITER $$

DROP PROCEDURE IF EXISTS add_return_records$$

CREATE PROCEDURE add_return_records(
    p_return_id VARCHAR(10), 
    p_issued_id VARCHAR(10)
)
BEGIN
    -- Declare variables
    DECLARE v_isbn VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    -- Insert into return_status table
    INSERT INTO return_status(return_id, issued_id, return_date)
    VALUES (p_return_id, p_issued_id, NOW());

    -- Retrieve book details based on issued_id
    SELECT issued_book_isbn, issued_book_name
    INTO v_isbn, v_book_name
    FROM issued_status
    WHERE issued_id = p_issued_id;

    -- Update book status to 'yes'
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Output a message
    SELECT CONCAT('Thank you for returning the book: ', v_book_name) AS Message;
END$$

DELIMITER ;

    SELECT* FROM issued_status
    WHERE issued_id = 'IS135';

  SELECT* FROM return_status
    WHERE issued_id = 'IS135';
    
    
    CALL add_return_records('RS138','IS135');
    
 /* Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, 
showing the number of books issued, the number of books returned, and the total revenue generated from book rentals. 
  */
  CREATE TABLE branch_reports
AS
SELECT b.branch_id,
b.manager_id,
COUNT(ist.issued_id) as no_of_books_issued,
COUNT(rs.return_id) as no_of_books_returned,
SUM(bk.rental_price) as total_revenue

 FROM issued_status as ist
JOIN employees e
ON e.emp_id = ist.issued_emp_id
JOIN branch b
ON e.branch_id = b.branch_id
JOIN return_status rs
ON rs.issued_id = ist.issued_id
JOIN books bk
ON bk.isbn = ist.issued_book_isbn
  
GROUP BY b.branch_id,
b.manager_id;
  
  
  SELECT* FROM branch_reports;
  
  /* Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
who have issued at least one book in the last 2 months. */

DROP TABLE IF EXISTS active_members;
CREATE TABLE active_members
AS 
SELECT * FROM members
WHERE member_id IN (
SELECT DISTINCT(issued_member_id)
FROM issued_status
WHERE issued_date >= current_date() - interval  2 month);
  
  SELECT *FROM active_members;
  
  
  -- Task 17: Find Employees with the Most Book Issues Processed
-- Write a query to find the top 3 employees who have processed the most book issues. 
-- Display the employee name, number of books processed, and their branch.

SELECT 
    e.emp_name,
    ist.issued_emp_id,
    e.branch_id,
    COUNT(issued_book_isbn) AS count_books_issued
FROM
    issued_status ist
        LEFT JOIN
    employees e ON ist.issued_emp_id = e.emp_id
GROUP BY 1 , 2 , 3;
    
-- Task 18: Identify Members Issuing High-Risk Books
-- Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. 
-- Display the member name, book title, and the number of times they've issued damaged books.


SELECT 
    m.member_name,
    b.book_title,
    COUNT(*) AS times_damaged
FROM 
    members m
JOIN 
    books b ON m.member_id = b.issued_to
WHERE 
    b.status = 'damaged'
GROUP BY 
    m.member_name, b.book_title
HAVING 
    COUNT(*) > 2;













/*Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. 
Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 
The procedure should function as follows: The stored procedure should take the book_id as an input parameter. 
The procedure should first check if the book is available (status = 'yes'). 
If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
If the book is not available (status = 'no'), the procedure should return an error message indicating that the book is currently not available.
*/



SELECT * FROM books;
SELECT * FROM issued_status;

DELIMITER $$
DROP PROCEDURE IF EXISTS issue_book$$
CREATE PROCEDURE issue_book(
p_issued_id VARCHAR(10), 
p_issued_member_id VARCHAR(10), 
p_issued_book_isbn VARCHAR(30) , 
p_issued_emp_id VARCHAR(10))

BEGIN
	-- all the variable
	DECLARE
	v_status VARCHAR(10);
	-- all the code
	-- checking if booking is availbale

		SELECT status 
        INTO v_status 
        FROM books WHERE isbn = p_issued_book_isbn;

		IF v_status = 'yes' THEN 
                -- insert the issue record
				INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
				VALUES(p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);
				-- update the books status to 'no'
				UPDATE books
                SET status = 'no'
                WHERE isbn = p_issued_book_isbn;
                -- output success message
				SELECT CONCAT ('Book records added succesfully for isbn: ' ,  p_issued_book_isbn);
        
        ELSE
				-- output not sucess message
				SELECT CONCAT( ' Sorry the book you requested is unavilable: ' , p_issued_book_isbn);
        
        END IF ;
END;

$$

CALL issue_book('IS155', 'C107', '978-0-553-29698-2', 'E104');
CALL issue_book('IS155', 'C107', '978-0-375-41398-8', 'E104');

    /* Task 20: Create Table As Select (CTAS) Objective: 
    Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.
Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
The table should include: The number of overdue books. The total fines, with each day's fine calculated at $0.50. 
The number of books issued by each member. 
The resulting table should show: Member ID Number of overdue books Total fines
*/


-- each member and books they issued that have not been returned within 30days
-- 

CREATE TABLE overdue_books_summary AS
SELECT 
    m.member_id,
    COUNT(CASE WHEN DATEDIFF(CURRENT_DATE, b.issue_date) > 30 THEN 1 END) AS number_of_overdue_books,
    SUM(CASE 
        WHEN DATEDIFF(CURRENT_DATE, b.issue_date) > 30 THEN 
            (DATEDIFF(CURRENT_DATE, b.issue_date) - 30) * 0.50 
        ELSE 0 
    END) AS total_fines,
    COUNT(b.book_id) AS total_books_issued
FROM 
    members m
JOIN 
    books b ON m.member_id = b.issued_to
WHERE 
    b.return_date IS NULL
GROUP BY 
    m.member_id;









    