CREATE TABLE Accounts
(
    account_id character varying(50) NOT NULL,
    username character varying(50) COLLATE pg_catalog."default" NOT NULL,
    password_id character varying(50) COLLATE pg_catalog."default" NOT NULL,
    is_active boolean NOT NULL,
    PRIMARY KEY (account_id)
);

CREATE TABLE Employees
(
    first_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
	last_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    date_of_birth date NOT NULL,
    phone character varying(50) COLLATE pg_catalog."default" NOT NULL,
    address character varying(50) COLLATE pg_catalog."default" NOT NULL,
    email character varying(50) COLLATE pg_catalog."default" NOT NULL
) INHERITS (Accounts);

ALTER TABLE Employees
ADD PRIMARY KEY (account_id);


CREATE TABLE Members
(
    first_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
	last_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    address character varying(50) COLLATE pg_catalog."default" NOT NULL,
    date_of_birth date NOT NULL,
    phone character varying(50) COLLATE pg_catalog."default" NOT NULL,
    email character varying(50) COLLATE pg_catalog."default" NOT NULL,
    expire_date date NOT NULL
) INHERITS (Accounts);

ALTER TABLE Members
ADD PRIMARY KEY (account_id);

CREATE TABLE Age_groups
(
    age_group_id character varying(50) NOT NULL,
    age_group_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    min_age integer NOT NULL,
    max_age integer NOT NULL,
    PRIMARY KEY (age_group_id)
);

CREATE TABLE Authors
(
    author_id character varying(50) NOT NULL,
    first_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    last_name character varying(255) COLLATE pg_catalog."default" NOT NULL,
    nationality character varying(255) COLLATE pg_catalog."default" NOT NULL,
    PRIMARY KEY (author_id)
);

CREATE TABLE Genres
(
    genre_id character varying(50) NOT NULL,
    genre_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    PRIMARY KEY (genre_id)
);

CREATE TABLE Publishers
(
    publisher_id character varying(50) NOT NULL,
    publisher_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    publisher_address character varying(50) COLLATE pg_catalog."default" NOT NULL,
    publisher_phone character varying(50) COLLATE pg_catalog."default" NOT NULL,
    PRIMARY KEY (publisher_id)
);

CREATE TABLE Books
(
    book_id character varying(50) NOT NULL,
    book_name character varying(50) COLLATE pg_catalog."default" NOT NULL,
    age_group_id character varying(50) NOT NULL,
    publisher_id character varying(50) NOT NULL,
    publication_year integer NOT NULL,
    available integer NOT NULL,
    quantity integer NOT NULL,
    price integer NOT NULL,
    PRIMARY KEY (book_id)
);

CREATE TABLE Book_Author
(
	book_id character varying(50) NOT NULL,
	author_id character varying(50) NOT NULL,
	PRIMARY KEY (book_id, author_id),
	FOREIGN KEY (book_id) REFERENCES Books(book_id),
	FOREIGN KEY (author_id) REFERENCES Authors(author_id)
);

CREATE TABLE Book_Genre
(
	book_id character varying(50) NOT NULL,
	genre_id character varying(50) NOT NULL,
	PRIMARY KEY (book_id, genre_id),
	FOREIGN KEY (book_id) REFERENCES Books(book_id),
	FOREIGN KEY (genre_id) REFERENCES Genres(genre_id)
);

CREATE TABLE Borrowing_Receipts
(
    receipt_id character varying(50) NOT NULL,
    employee_account_id character varying(50) COLLATE pg_catalog."default" NOT NULL,
    member_account_id character varying(50) COLLATE pg_catalog."default" NOT NULL,
    fee integer NOT NULL,
    borrow_date date NOT NULL,
    due_date date NOT NULL,
    return_date date,
    status character varying(50) COLLATE pg_catalog."default" NOT NULL,
    PRIMARY KEY (receipt_id),
    FOREIGN KEY (employee_account_id) REFERENCES Employees(account_id),
    FOREIGN KEY (member_account_id) REFERENCES Members(account_id)
);

CREATE TABLE Borrowed_Books
(
    receipt_id character varying(50) NOT NULL,
    book_id character varying(50) NOT NULL,
    quantity integer NOT NULL,
    status character varying(50) COLLATE pg_catalog."default" NOT NULL,
	PRIMARY KEY (receipt_id, book_id),
	FOREIGN KEY (receipt_id) REFERENCES Borrowing_Receipts(receipt_id),
	FOREIGN KEY (book_id) REFERENCES Books(book_id)
);

ALTER TABLE Books
    ADD CONSTRAINT books_age_group_id_foreign FOREIGN KEY (age_group_id)
    REFERENCES Age_groups (age_group_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

ALTER TABLE Books
    ADD CONSTRAINT books_publisher_id_foreign FOREIGN KEY (publisher_id)
    REFERENCES Publishers (publisher_id) MATCH SIMPLE
    ON UPDATE NO ACTION
    ON DELETE NO ACTION;

ALTER TABLE Members
ADD CONSTRAINT fk_members_accounts
FOREIGN KEY (account_id) REFERENCES Accounts (account_id);

ALTER TABLE Employees
ADD CONSTRAINT fk_members_accounts
FOREIGN KEY (account_id) REFERENCES Accounts (account_id);

ALTER TABLE Members
    ADD CONSTRAINT members_account_id_foreign FOREIGN KEY (account_id)
    REFERENCES Accounts (account_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;

ALTER TABLE Employees
    ADD CONSTRAINT employees_account_id_foreign FOREIGN KEY (account_id)
    REFERENCES Accounts (account_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE;


----------------------------------------TRIGGER-----------------------------------------

---------------------Kiểm tra giới hạn đơn mượn của mỗi người dùng----------------------
-- Tạo trigger
CREATE OR REPLACE FUNCTION check_borrowed_books_limit()
RETURNS TRIGGER AS $$
DECLARE
    total_books_member INT;
BEGIN
    -- Tính tổng số lượng sách mượn của thành viên qua tất cả các phiếu mượn
    SELECT SUM(bb.quantity)
    INTO total_books_member
    FROM Borrowed_Books bb
    JOIN Borrowing_Receipts br ON bb.receipt_id = br.receipt_id
    WHERE br.member_account_id = (SELECT member_account_id FROM Borrowing_Receipts WHERE receipt_id = NEW.receipt_id)
    AND bb.status = 'Borrowing';

    -- Nếu tổng vượt quá giới hạn 10 cuốn, cập nhật trạng thái phiếu mượn thành 'Canceled' và ném ra ngoại lệ
    IF total_books_member + NEW.quantity > 10 THEN
        -- Ném ra ngoại lệ với thông điệp chứa giá trị của total_books_member
        RAISE EXCEPTION 'The total number of borrowed books for the member exceeds the limit of 10. Current total: %', total_books_member;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger để kích hoạt khi có bản ghi mới được chèn vào Borrowed_Books
CREATE TRIGGER check_borrowed_books_trigger
BEFORE INSERT ON Borrowed_Books
FOR EACH ROW
EXECUTE FUNCTION check_borrowed_books_limit();

--------------------Cập nhật trạng thái tài khoản khi biết expire_date---------------

-- Tạo trigger
CREATE OR REPLACE FUNCTION update_account_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Kiểm tra xem có hết hạn chưa và ngày hết hạn chưa đến
    IF NEW.expire_date > CURRENT_DATE THEN
        -- Cập nhật trạng thái is_active thành true
        UPDATE Accounts
        SET is_active = TRUE
        WHERE account_id = NEW.account_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger để kích hoạt khi có bản ghi mới được chèn vào Accounts
CREATE TRIGGER account_expire_trigger
BEFORE INSERT OR UPDATE ON Accounts
FOR EACH ROW
EXECUTE FUNCTION update_account_status();

------------Cập nhật avaible và trạng thái đơn khi mượn, trả sách--------------------
-- Tạo trigger
CREATE OR REPLACE FUNCTION update_book_availability()
RETURNS TRIGGER AS $$
BEGIN
    -- Khi mượn sách (INSERT), giảm số lượng available của sách đó
    IF TG_OP = 'INSERT' AND NEW.status = 'Borrowing' THEN
        -- Kiểm tra nếu số lượng mượn vượt quá số lượng available
        IF (SELECT available FROM books WHERE book_id = NEW.book_id) < NEW.quantity THEN
            -- Cập nhật status của phiếu mượn thành 'Canceled'
            UPDATE borrowing_receipts
            SET status = 'Canceled'
            WHERE receipt_id = NEW.receipt_id;
        ELSE
            -- Giảm số lượng available của sách
            UPDATE books
            SET available = available - NEW.quantity
            WHERE book_id = NEW.book_id;
        END IF;
    
    -- Khi trả sách (UPDATE), tăng số lượng available của sách đó
    ELSIF TG_OP = 'UPDATE' AND NEW.status = 'Returned' AND OLD.status = 'Borrowing' THEN
        UPDATE books
        SET available = available + NEW.quantity
        WHERE book_id = NEW.book_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger để kích hoạt khi có bản ghi mới được chèn hoặc cập nhật trong Borrowed_Books
CREATE TRIGGER update_book_availability_trigger
AFTER INSERT OR UPDATE ON Borrowed_Books
FOR EACH ROW
EXECUTE FUNCTION update_book_availability();


-------------------Cập nhật trạng thái đơn mượn khi trả sách ----------------------
-- Tạo trigger
CREATE OR REPLACE FUNCTION update_borrowing_receipt_status()
RETURNS TRIGGER AS $$
DECLARE
    total_returned_books INTEGER;
    total_borrowed_books INTEGER;
BEGIN
    -- Đếm tổng số sách trong phiếu mượn
    SELECT COUNT(DISTINCT book_id) INTO total_borrowed_books
    FROM borrowed_books
    WHERE receipt_id = NEW.receipt_id;

    -- Đếm số sách đã được trả lại hoặc bị mất trong phiếu mượn
    SELECT COUNT(DISTINCT book_id) INTO total_returned_books
    FROM borrowed_books
    WHERE receipt_id = NEW.receipt_id AND (status = 'Returned' OR status = 'Lost');

    -- Kiểm tra và cập nhật trạng thái của phiếu mượn
    IF total_returned_books = total_borrowed_books THEN
        UPDATE borrowing_receipts
        SET status = 'Returned', return_date = CURRENT_DATE
        WHERE receipt_id = NEW.receipt_id;
    ELSE
        UPDATE borrowing_receipts
        SET status = 'Borrowing', return_date = NULL
        WHERE receipt_id = NEW.receipt_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger để kích hoạt khi có bản ghi mới được chèn hoặc cập nhật trong Borrowed_Books
CREATE TRIGGER update_borrowing_receipt_status_trigger
AFTER INSERT OR UPDATE ON borrowed_books
FOR EACH ROW
EXECUTE FUNCTION update_borrowing_receipt_status();

----------------------cập nhật trạng thái đơn mượn khi update ngày trả ----------------
-- Tạo trigger
CREATE OR REPLACE FUNCTION update_borrowing_receipt_status()
RETURNS TRIGGER AS $$
BEGIN
    -- Kiểm tra nếu return_date được cập nhật và không phải là NULL
    IF NEW.return_date IS NOT NULL THEN
        -- Cập nhật trạng thái thành 'Returned'
        NEW.status := 'Returned';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Tạo trigger để kích hoạt khi có bản ghi mới được cập nhật trong Borrowing_Receipts
CREATE TRIGGER update_borrowing_receipt_status_trigger
BEFORE UPDATE ON borrowing_receipts
FOR EACH ROW
EXECUTE FUNCTION update_borrowing_receipt_status();

----------------------------------Phí muộn-------------------------------------------
CREATE OR REPLACE FUNCTION calculate_overdue_fees()
RETURNS TRIGGER AS $$
DECLARE
    days_overdue INT;
    fee_amount INT;
    total_book_price INT;
    account_ids INT;
BEGIN
    -- Tính số ngày quá hạn
    IF NEW.return_date IS NOT NULL THEN
        days_overdue := NEW.return_date - NEW.due_date;
    ELSE
        days_overdue := CURRENT_DATE - NEW.due_date;
    END IF;

    -- Xác định mức phí phạt dựa trên số ngày quá hạn
    IF days_overdue > 5 AND days_overdue <= 10 THEN
        fee_amount := 10000;
    ELSIF days_overdue > 10 AND days_overdue <= 30 THEN
        fee_amount := 20000;
    ELSIF days_overdue > 30 AND days_overdue <= 60 THEN
        fee_amount := 30000;
    ELSIF days_overdue > 60 THEN
		fee_amount := 200000;
    ELSE
        fee_amount := 0;
    END IF;

    UPDATE Borrowing_Receipts
	SET fee = fee_amount
	WHERE receipt_id = NEW.receipt_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_late_fee
AFTER INSERT OR UPDATE OF return_date, due_date, status ON Borrowing_Receipts
FOR EACH ROW
EXECUTE FUNCTION calculate_overdue_fees();

---------------------------------Phí mất sách--------------------------------------
CREATE OR REPLACE FUNCTION calculate_lost_book_fees()
RETURNS TRIGGER AS $$
DECLARE
    lost_fee INT := 0;
    book_price INT;
    quantity_lost INT;
BEGIN
    -- Kiểm tra nếu trạng thái là 'Lost'
    IF NEW.status = 'Lost' THEN
        -- Lấy giá gốc của sách và số lượng sách bị mất
        SELECT price INTO book_price
        FROM Books
        WHERE book_id = NEW.book_id;

        quantity_lost := NEW.quantity;

        -- Tính phí làm mất sách
        lost_fee := book_price * quantity_lost;

    UPDATE Borrowing_Receipts
	SET fee = lost_fee + fee
	WHERE receipt_id = NEW.receipt_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger để kích hoạt hàm tính phí làm mất sách khi có thay đổi trong bảng Borrowed_Books
CREATE TRIGGER calculate_lost_book_fees_trigger
AFTER UPDATE OF status, quantity ON Borrowed_Books
FOR EACH ROW
WHEN (NEW.status = 'Lost')
EXECUTE FUNCTION calculate_lost_book_fees();



--------------- Kiểm tra ngày sinh và ngày hạn tài khoản của member khi nhập vào-----------------------
CREATE OR REPLACE FUNCTION check_member_dob_expire_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.date_of_birth > CURRENT_DATE - INTERVAL '3 years' THEN
        RAISE EXCEPTION 'Date of birth must be at least 3 years ago';
    END IF;

    IF NEW.expire_date < NEW.date_of_birth + INTERVAL '6 years' THEN
        RAISE EXCEPTION 'Expire date must be at least 6 years after date of birth';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER check_member_dob_expire_date_trigger
BEFORE INSERT OR UPDATE OF expire_date ON public.members
FOR EACH ROW
EXECUTE FUNCTION check_member_dob_expire_date();


----------------Cập nhật available sách khi cập nhật quantity------------------------
CREATE OR REPLACE FUNCTION update_available_on_quantity_update()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.quantity > OLD.quantity THEN
        UPDATE public.books
        SET available = available + (NEW.quantity - OLD.quantity)
        WHERE book_id = NEW.book_id;
    ELSIF NEW.quantity < OLD.quantity THEN
        RAISE EXCEPTION 'New quantity cannot be less than the old quantity';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER update_available_trigger
AFTER UPDATE OF quantity ON public.books
FOR EACH ROW
EXECUTE FUNCTION update_available_on_quantity_update();

---------------------------------FUNCTION-------------------------------------
-----------------------------Tìm kiếm sách theo tên tác giả--------------------
-- Tạo function
CREATE OR REPLACE FUNCTION find_books_by_author(Aname VARCHAR)
RETURNS TABLE (
    book_id INT,
    book_name VARCHAR,
    author_name VARCHAR,
    publication_year INT,
    available INT
) AS $$
DECLARE
    v_first_name VARCHAR;
    v_last_name VARCHAR;
BEGIN
    -- Tách tên tác giả thành first_name và last_name
    v_first_name := split_part(Aname, ' ', 1);
    v_last_name := split_part(Aname, ' ', 2);

    -- Truy vấn để tìm sách của tác giả
    RETURN QUERY
    SELECT
        b.book_id,
        b.book_name,
        CAST(CONCAT(a.first_name, ' ', a.last_name) AS VARCHAR) AS author_name,
        b.publication_year,
        b.available
    FROM
        Books b
        JOIN Book_Author ba ON b.book_id = ba.book_id
        JOIN Authors a ON ba.author_id = a.author_id
    WHERE
        a.first_name ILIKE '%' || v_first_name || '%'
        AND a.last_name ILIKE '%' || v_last_name || '%';
END;
$$ LANGUAGE plpgsql;

----------- đưa ra nhóm tuổi với ngày tháng năm sinh -------------------------
-- Tạo function
CREATE OR REPLACE FUNCTION get_age_group(birth_date DATE)
RETURNS VARCHAR(50) AS $$
DECLARE
    age INT;
    age_group_name VARCHAR(50);
BEGIN
    -- Tính tuổi từ ngày sinh
    SELECT EXTRACT(YEAR FROM age(current_date, birth_date)) INTO age;

    -- Kiểm tra tuổi thuộc nhóm tuổi nào
    SELECT age_group_name INTO age_group_name
    FROM Age_groups
    WHERE age BETWEEN min_age AND max_age;

    RETURN age_group_name;
END;
$$ LANGUAGE plpgsql;

------------------Đưa ra tác giả có nhiểu sách nhất ----------------------
-- Tạo function
CREATE OR REPLACE FUNCTION get_author_with_most_books()
RETURNS TABLE (
    author_id INT,
    first_name VARCHAR,
    last_name VARCHAR,
    nationality VARCHAR,
    book_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        A.author_id,
        A.first_name,
        A.last_name,
        A.nationality,
        COUNT(*) AS book_count
    FROM
        Authors A
    INNER JOIN
        Book_Author BA ON A.author_id = BA.author_id
    GROUP BY
        A.author_id, A.first_name, A.last_name, A.nationality
    ORDER BY
        book_count DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

---------------Đưa ra bảng thống kê số sách được mượn trong 12 tháng của 1 năm cho trước -------------------
-- Create the function
CREATE OR REPLACE FUNCTION get_borrowing_receipts_per_month(year_input INTEGER)
RETURNS TABLE (month_number INTEGER, receipt_count INTEGER) AS $$
DECLARE
    month_counter INTEGER;
BEGIN
    FOR month_counter IN 1..12 LOOP
        RETURN QUERY
        SELECT
            month_counter AS month_number,
            COUNT(*) AS receipt_count
        FROM
            Borrowing_Receipts BR
        WHERE
            EXTRACT(MONTH FROM BR.borrow_date) = month_counter
            AND EXTRACT(YEAR FROM BR.borrow_date) = year_input;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-----------Tìm kiếm sách theo từ khóa (name, author,...)--------------------------------
-- Tạo hàm
CREATE OR REPLACE FUNCTION tim_kiem_sach_theo_tu_khoa(keyword VARCHAR)
RETURNS TABLE (
    book_id INT,
    book_name VARCHAR,
    author_name VARCHAR,
    publication_year INT,
    available INT,
    genre_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (b.book_id)
        b.book_id,
        b.book_name,
        CONCAT(a.first_name, ' ', a.last_name) AS author_name,
        b.publication_year,
        b.available,
        g.genre_name
    FROM
        Books b
        LEFT JOIN Book_Author ba ON b.book_id = ba.book_id
        LEFT JOIN Authors a ON ba.author_id = a.author_id
        LEFT JOIN Book_Genre bg ON b.book_id = bg.book_id
        LEFT JOIN Genres g ON bg.genre_id = g.genre_id
    WHERE
        b.book_name ILIKE '%' || keyword || '%'
        OR (a.first_name ILIKE '%' || keyword || '%' AND a.last_name ILIKE '%' || keyword || '%')
        OR g.genre_name ILIKE '%' || keyword || '%';
END;
$$ LANGUAGE plpgsql;

--------------------Đưa ra số sách người đọc đang mượn và hạn phải trả------------------
-- Tạo hàm để trả về bảng với thông tin sách đang mượn của người dùng cụ thể
CREATE OR REPLACE FUNCTION get_borrowed_books_by_account(p_account_id VARCHAR)
RETURNS TABLE (
    book_name VARCHAR,
    quantity INT,
    due_date DATE
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.book_name,
        bb.quantity,
        br.due_date
    FROM
        Borrowed_Books bb
        JOIN Books b ON bb.book_id = b.book_id
        JOIN Borrowing_Receipts br ON bb.receipt_id = br.receipt_id
    WHERE
        bb.status = 'Borrowing'
        AND br.member_account_id = p_account_id; 
END;
$$ LANGUAGE plpgsql;
-----------------------Hàm trả về sách đang được mượn và số lượng------------------------------
CREATE OR REPLACE FUNCTION get_books_currently_borrowed()
RETURNS TABLE (
    book_id VARCHAR(50),
    book_name VARCHAR(50),
    total_borrowed_quantity INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.book_id,
        b.book_name,
        COALESCE(SUM(bb.quantity), 0)::INT AS total_borrowed_quantity
    FROM
        Books b
    JOIN
        Borrowed_Books bb ON b.book_id = bb.book_id
    JOIN
        Borrowing_Receipts br ON bb.receipt_id = br.receipt_id
    WHERE
        br.return_date IS NULL
    GROUP BY
        b.book_id, b.book_name
    ORDER BY
        total_borrowed_quantity DESC;
END;
$$ LANGUAGE plpgsql;

-----------------------Hàm trả về số lượng sách mượn của người dùng theo tháng sắp xếp giảm dần-------------------
CREATE OR REPLACE FUNCTION get_borrowers_by_month(year_param integer, month_param integer)
RETURNS TABLE(
    member_account_id character varying(50),
    first_name character varying(50),
    last_name character varying(50),
    total_books_borrowed integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        m.account_id AS member_account_id,
        m.first_name,
        m.last_name,
        COALESCE(SUM(bb.quantity), 0)::integer AS total_books_borrowed
    FROM
        Members m
    JOIN
        Borrowing_Receipts br ON m.account_id = br.member_account_id
    JOIN
        Borrowed_Books bb ON br.receipt_id = bb.receipt_id
    WHERE
        EXTRACT(YEAR FROM br.borrow_date) = year_param
        AND EXTRACT(MONTH FROM br.borrow_date) = month_param
    GROUP BY
        m.account_id, m.first_name, m.last_name
    ORDER BY
        total_books_borrowed DESC;
END;
$$ LANGUAGE plpgsql;

-----------------------------PROCEDURE-----------------------------------------
--- Xóa các tài khoản k được active------------------------------------------
-- Tạo procedure
CREATE OR REPLACE PROCEDURE delete_inactive_members()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM Members
    WHERE is_active = FALSE;
END;
$$;

--------------add_author----------------------------------------------------
--tạo  sequence--
CREATE SEQUENCE author_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Tạo procedure
CREATE OR REPLACE PROCEDURE add_author(
    p_first_name VARCHAR,
    p_last_name VARCHAR,
    p_nationality VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_author_id VARCHAR;
BEGIN
    -- Sinh author_id trong định dạng ATxxxx
    SELECT 'AT' || to_char(nextval('author_id_seq'), 'FM0000') INTO v_author_id;

    -- Chèn vào bảng Authors
    INSERT INTO Authors (author_id, first_name, last_name, nationality)
    VALUES (v_author_id, p_first_name, p_last_name, p_nationality);

    -- In thông báo thông báo khi chèn thành công
    RAISE NOTICE 'Author added successfully with author_id: %', v_author_id;
END;
$$;


--------------add_book----------------------------------------------------
CREATE SEQUENCE book_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Tạo procedure
CREATE OR REPLACE PROCEDURE add_book(
    p_book_name VARCHAR,
    p_age_group_id INT,
    p_publisher_id INT,
    p_publication_year INT,
    p_quantity INT,
    p_price NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_id VARCHAR;
BEGIN
    -- Sinh book_id từ sequence book_id_seq
    SELECT 'BK' || to_char(nextval('book_id_seq'), 'FM0000') INTO new_id;

    -- Chèn sách mới vào bảng Books
    INSERT INTO Books (book_id, book_name, age_group_id, publisher_id, publication_year, available, quantity, price)
    VALUES (new_id, p_book_name, p_age_group_id, p_publisher_id, p_publication_year, p_quantity, p_quantity, p_price);

    -- In thông báo khi chèn thành công
    RAISE NOTICE 'Book % has been added successfully with ID %.', p_book_name, new_id;
END;
$$;


--------------------------------add_genre----------------------------------------
-- Tạo sequence
CREATE SEQUENCE genre_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Tạo procedure
CREATE OR REPLACE PROCEDURE add_genre(
    p_genre_name VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    new_id VARCHAR;
BEGIN
    -- Sinh genre_id từ sequence genre_id_seq
    SELECT 'G' || to_char(nextval('genre_id_seq'), 'FM0000') INTO new_id;

    -- Thêm thể loại mới vào bảng Genres
    INSERT INTO Genres (genre_id, genre_name)
    VALUES (new_id, p_genre_name);

    -- In thông báo khi thêm thành công
    RAISE NOTICE 'Genre % has been successfully added with ID %.', p_genre_name, new_id;
END;
$$;

-----------------------add_publisher----------------------------------------------
-- Tạo sequence
CREATE SEQUENCE publisher_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
-- Tạo procedure
CREATE OR REPLACE PROCEDURE add_publisher(
    p_publisher_name VARCHAR,
    p_publisher_address VARCHAR,
    p_publisher_phone VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_publisher_id VARCHAR;
BEGIN
    -- Sinh publisher_id từ sequence publisher_id_seq
    SELECT 'PB' || to_char(nextval('publisher_id_seq'), 'FM0000') INTO v_publisher_id;

    -- Thêm nhà xuất bản mới vào bảng Publishers
    INSERT INTO Publishers (publisher_id, publisher_name, publisher_address, publisher_phone)
    VALUES (v_publisher_id, p_publisher_name, p_publisher_address, p_publisher_phone);

    -- In thông báo khi thêm thành công
    RAISE NOTICE 'Publisher % has been successfully added with ID %.', p_publisher_name, v_publisher_id;
END;
$$;


--------------------------------TẠO VIEW------------------------------------------
CREATE VIEW Borrowed_Books_View AS
SELECT
    br.receipt_id,
    b.book_id,
    b.book_name,
    a.first_name AS author_first_name,
    a.last_name AS author_last_name,
    bb.quantity,
    bb.status
FROM
    Borrowed_Books bb
JOIN
    Books b ON bb.book_id = b.book_id
JOIN
    Book_Author ba ON b.book_id = ba.book_id
JOIN
    Authors a ON ba.author_id = a.author_id
JOIN
    Borrowing_Receipts br ON bb.receipt_id = br.receipt_id;
----
CREATE VIEW Book_Inventory_Summary AS
SELECT
    COUNT(book_id) AS total_books,
    SUM(quantity) AS total_quantity,
    SUM(available) AS total_available,
    SUM(price * quantity) AS total_value
FROM
    Books;
----
CREATE VIEW Members_Count_By_Age_Group AS
SELECT
    ag.age_group_id,
    ag.age_group_name,
    COUNT(m.account_id) AS total_members
FROM
    Age_groups ag
LEFT JOIN
    Members m ON m.date_of_birth BETWEEN CURRENT_DATE - INTERVAL '1 year' * ag.max_age AND CURRENT_DATE - INTERVAL '1 year' * ag.min_age
GROUP BY
    ag.age_group_id, ag.age_group_name;

--------------------------------PHÂN QUYỀN----------------------------------------
CREATE ROLE admin WITH LOGIN;
CREATE ROLE employee WITH LOGIN;
CREATE ROLE member WITH LOGIN;

REVOKE ALL ON TABLE Accounts FROM PUBLIC;
REVOKE ALL ON TABLE Accounts FROM member;

-- Cấp quyền cho admin
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO admin;

-- Cấp quyền cho employee
GRANT SELECT, INSERT, UPDATE, DELETE ON Borrowing_Receipts TO employee;
GRANT SELECT, INSERT, UPDATE, DELETE ON Books TO employee;
GRANT SELECT, INSERT, UPDATE, DELETE ON Publishers TO employee;
GRANT SELECT, INSERT, UPDATE, DELETE ON Authors TO employee;
GRANT SELECT, INSERT, UPDATE, DELETE ON Members TO employee;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Genres TO librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Book_Author TO librarian;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE Book_Genre TO librarian;

-- Cấp quyền cho member
GRANT SELECT ON TABLE Books TO member;
GRANT SELECT ON TABLE Authors TO member;
GRANT SELECT ON TABLE Genres TO member;
GRANT SELECT ON TABLE Publishers TO member;
GRANT SELECT, INSERT, UPDATE ON TABLE Borrowing_Receipts TO members;
GRANT SELECT, INSERT, UPDATE ON TABLE Borrowed_Books TO members;

-- Tạo người dùng và phân vai trò
CREATE USER admin_user WITH PASSWORD 'admin_password';
GRANT admin TO admin_user;

CREATE USER employee_user WITH PASSWORD 'employee_password';
GRANT employee TO employee_user;

CREATE USER member_user WITH PASSWORD 'member_password';
GRANT member TO member_user;

GRANT EXECUTE ON FUNCTION update_book_availability_on_borrow() TO employee;
GRANT EXECUTE ON FUNCTION update_account_active_status() TO employee;
GRANT EXECUTE ON FUNCTION calculate_overdue_fees() TO employee;
GRANT EXECUTE ON FUNCTION calculate_lost_book_fees() TO employee;
GRANT EXECUTE ON FUNCTION check_quantity_limit() TO employee;
GRANT EXECUTE ON FUNCTION update_return_date() TO employee;

---------------------------------QUERY--------------------------------------

--Tìm ra top 5 cuốn sách phổ biến nhất trong tháng trước, với số lượt mượn cao nhất
WITH PopularBooks AS (
    SELECT bb.book_id, COUNT(*) AS borrow_count
    FROM Borrowing_Receipts br
    JOIN Borrowed_Books bb ON br.receipt_id = bb.receipt_id
    WHERE br.borrow_date >= date_trunc('month', CURRENT_DATE - INTERVAL '1 month')
    AND br.borrow_date < date_trunc('month', CURRENT_DATE)
    GROUP BY bb.book_id
    ORDER BY COUNT(*) DESC
    LIMIT 5
),
Top5Books AS (
    SELECT pb.book_id, pb.borrow_count, b.book_name, b.publication_year, g.genre_name, a.first_name, a.last_name
    FROM PopularBooks pb
    JOIN Books b ON pb.book_id = b.book_id
    JOIN Book_Genre bg ON b.book_id = bg.book_id
    JOIN Genres g ON bg.genre_id = g.genre_id
    JOIN Book_Author ba ON b.book_id = ba.book_id
    JOIN Authors a ON ba.author_id = a.author_id
)
SELECT * FROM Top5Books;

--Tìm ra top 3 người mượn sách có số lượt mượn cao nhất trong mỗi nhóm tuổi (dựa trên các khoảng tuổi được xác định trước), trong 3 tháng trước.
WITH AgeGroups AS (
    SELECT 
        age_group_id, 
        age_group_name, 
        min_age, 
        max_age 
    FROM Age_groups
),
MemberBorrowCounts AS (
    SELECT 
        m.account_id,
        m.username,
        EXTRACT(YEAR FROM AGE(bd.date_of_birth)) AS age,
        COUNT(*) AS borrow_count,
        ROW_NUMBER() OVER (PARTITION BY a.age_group_id ORDER BY COUNT(*) DESC) AS rank
    FROM Borrowing_Receipts br
    JOIN Members m ON br.member_account_id = m.account_id
    JOIN AgeGroups a ON AGE(m.date_of_birth) BETWEEN a.min_age AND a.max_age
    WHERE br.borrow_date >= date_trunc('month', CURRENT_DATE - INTERVAL '3 month')
    AND br.borrow_date < date_trunc('month', CURRENT_DATE)
    GROUP BY m.account_id, m.username, age, a.age_group_id
)
SELECT 
    account_id,
    username,
    age,
    borrow_count
FROM MemberBorrowCounts
WHERE rank <= 3;

--
UPDATE Members
SET is_active = FALSE
WHERE account_id IN (
    SELECT br.member_account_id
    FROM Borrowing_Receipts br
    WHERE br.return_date > br.due_date -- Ngày trả muộn
    GROUP BY br.member_account_id
    HAVING COUNT(*) > 15
);

UPDATE Members
SET is_active = TRUE
WHERE account_id IN (
    SELECT account_id
    FROM Members
    WHERE is_active = FALSE
    AND DATE_PART('month', NOW() - INTERVAL '1 month') > DATE_PART('month', inactive_date)
);


-----------Truy vấn Query----------------------------------------------
--Trả về top 10 đầu sách thỏa mãn có số lượng người mượn nhiều nhất trong 1 tháng kể từ thời gian gần nhất
WITH RecentMonthBorrowers AS (
SELECT DISTINCT br . receipt_id
FROM Borrowing_Receipts br
WHERE br . borrow_date < DATE_TRUNC (’month ’, CURRENT_DATE )
AND br . borrow_date >= DATE_TRUNC (’month ’, CURRENT_DATE -
INTERVAL ’1 month ’)
) ,
BooksBorrowed AS (
SELECT bb . book_id , COUNT ( DISTINCT br . receipt_id ) AS
borrower_count
FROM Borrowed_Books bb
INNER JOIN Borrowing_Receipts br ON bb . receipt_id =
br . receipt_id
WHERE br . receipt_id IN ( SELECT receipt_id FROM
RecentMonthBorrowers )
GROUP BY bb . book_id
)
SELECT b . book_name , bb . borrower_count
FROM Books b
INNER JOIN BooksBorrowed bb ON b . book_id = bb . book_id
ORDER BY bb . borrower_count DESC
LIMIT 10

--Tìm ra top 3 người mượn sách có số lượt mượn cao nhất trong mỗi nhóm tuổi (dựa trên các khoảng tuổi được xác định trước), trong 3 tháng trước:
WITH MemberAgeGroup AS (
SELECT
m . account_id ,
m . first_name ,
m . last_name ,
m . date_of_birth ,
ag . age_group_id ,
ag . age_group_name ,
EXTRACT ( YEAR FROM AGE ( CURRENT_DATE , m . date_of_birth ) ) AS age
FROM
Members m
JOIN Age_groups ag ON (
EXTRACT ( YEAR FROM AGE ( CURRENT_DATE , m . date_of_birth ) )
BETWEEN ag . min_age AND ag . max_age
)
) ,
MemberBorrowCount AS (
SELECT
m . account_id ,
m . first_name ,
m . last_name ,
mag . age_group_id ,
mag . age_group_name ,
COUNT ( br . receipt_id ) AS borrow_count
FROM
Borrowing_Receipts br
JOIN Members m ON br . member_account_id = m . account_id
JOIN MemberAgeGroup mag ON m . account_id = mag . account_id
WHERE
br . borrow_date >= date_trunc (’month ’, CURRENT_DATE ) -
INTERVAL ’3 months ’
AND br . borrow_date < date_trunc (’month ’, CURRENT_DATE )
GROUP BY
m . account_id ,
m . first_name ,
m . last_name ,
mag . age_group_id ,
mag . age_group_name
) ,
RankedMembers AS (
SELECT
mbc .* ,
ROW_NUMBER () OVER ( PARTITION BY mbc . age_group_id ORDER BY
mbc . borrow_count DESC ) AS rank
FROM
MemberBorrowCount mbc
)
SELECT
age_group_id ,
age_group_name ,
account_id ,
first_name ,
last_name ,
borrow_count
FROM
RankedMembers
WHERE
rank <= 3
ORDER BY
age_group_id ,
rank ;

--Đưa ra nhóm tuổi có số lượng người nhiều nhất--
WITH MemberAges AS (
SELECT
m . account_id ,
EXTRACT ( YEAR FROM AGE ( CURRENT_DATE , m . date_of_birth ) ) AS age
FROM Members m
) ,
AgeGroupCounts AS (
SELECT
ag . age_group_name ,
COUNT ( ma . account_id ) AS member_count
FROM MemberAges ma
JOIN Age_groups ag ON ma . age BETWEEN ag . min_age AND ag . max_age
GROUP BY ag . age_group_name
)
SELECT age_group_name , member_count
FROM AgeGroupCounts
ORDER BY member_count DESC
LIMIT 1;



--Tính số phần trăm đơn mượn sách trả đúng hạn
SELECT
ROUND (( COUNT ( CASE WHEN return_date <= due_date THEN 1
END ) :: numeric / COUNT (*) * 100) , 2) AS percent_on_time
FROM
Borrowing_Receipts
WHERE
return_date IS NOT NULL ;

--Tính số phần trăm của các member mà tài khoản còn hoạt động trong từng nhóm tuổi:
WITH TotalMembers AS (
SELECT
AG . age_group_id ,
AG . age_group_name ,
COUNT ( M . date_of_birth ) AS total_members
FROM
Age_groups AG
LEFT JOIN
Members M ON EXTRACT ( YEAR FROM AGE ( M . date_of_birth ) )
BETWEEN AG . min_age AND AG . max_age
GROUP BY
AG . age_group_id , AG . age_group_name
) ,
ActiveMembers AS (
SELECT
AG . age_group_id ,
AG . age_group_name ,
COUNT ( M . date_of_birth ) AS active_members
FROM
Age_groups AG
LEFT JOIN
Members M ON EXTRACT ( YEAR FROM AGE ( M . date_of_birth ) )
BETWEEN AG . min_age AND AG . max_age
WHERE
M . is_active = true
GROUP BY
AG . age_group_id , AG . age_group_name
)
SELECT
TM . age_group_id ,
TM . age_group_name ,
TM . total_members ,
COALESCE ( AM . active_members , 0) AS active_members ,
CASE
WHEN TM . total_members > 0 THEN ( AM . active_members :: numeric
/ TM . total_members :: numeric ) * 100
ELSE 0
END AS active_percentage
FROM
TotalMembers TM
LEFT JOIN
ActiveMembers AM ON TM . age_group_id = AM . age_group_id
ORDER BY
TM . age_group_id ;


--Đưa ra 5 đầu sách mà lứa tuổi già (senior) ưa thích nhất trong 1 năm vừa qua
WITH SeniorMembers AS (
SELECT m . account_id
FROM Members m
JOIN Age_groups ag ON EXTRACT ( YEAR FROM AGE ( CURRENT_DATE ,
m . date_of_birth ) ) BETWEEN ag . min_age AND ag . max_age
) ,
RecentSeniorBorrowings AS (
SELECT bb . book_id , COUNT ( DISTINCT bb . receipt_id ) AS borrow_count
FROM SeniorMembers sm
JOIN Borrowing_Receipts br ON sm . account_id =
br . member_account_id
JOIN Borrowed_Books bb ON br . receipt_id = bb . receipt_id
WHERE br . borrow_date >= DATE_TRUNC (’year ’, CURRENT_DATE ) -
INTERVAL ’1 year ’
GROUP BY bb . book_id
)
SELECT b . book_name , rsb . borrow_count
FROM RecentSeniorBorrowings rsb
JOIN Books b ON rsb . book_id = b. book_id
ORDER BY rsb . borrow_count DESC
LIMIT 5;

--Thêm tác giả cho sách
INSERT INTO Book_Author ( book_id , author_id )
VALUES (’BK0016 ’, ’AT0001 ’) ;

--In ra danh sách sách mượn trong 1 đơn:
SELECT
b . book_id ,
b . book_name ,
bb . quantity ,
b . price
FROM
Borrowed_Books bb
JOIN Books b ON bb . book_id = b . book_id
WHERE
bb . receipt_id = ’BR0003 ’;

--In ra danh sách tên các sách cho độ tuổi child:
SELECT
b . book_id ,
b . book_name ,
b . publisher_id ,
b . publication_year ,
b . available ,
b . quantity ,
b . price
FROM
Books b
JOIN Age_groups ag ON b . age_group_id = ag . age_group_id
WHERE
ag . age_group_name = ’Child ’;

--Cập nhật giá sách:
UPDATE Books SET price = 100
WHERE book_id = ’BK0001 ’;
