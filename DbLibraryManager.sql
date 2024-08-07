PGDMP      +                |            dbrQuanLyThuVien    16.3    16.3 v    l           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            m           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            n           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            o           1262    25473    dbrQuanLyThuVien    DATABASE     �   CREATE DATABASE "dbrQuanLyThuVien" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_Australia.1252';
 "   DROP DATABASE "dbrQuanLyThuVien";
                postgres    false            �            1255    34113 C   add_author(character varying, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.add_author(IN p_first_name character varying, IN p_last_name character varying, IN p_nationality character varying)
    LANGUAGE plpgsql
    AS $$DECLARE
    v_author_id VARCHAR;
BEGIN
    -- Generate author_id in the format ATxxxx
    SELECT 'AT' || to_char(nextval('author_id_seq'), 'FM0000') INTO v_author_id;

    -- Insert into Authors table
    INSERT INTO Authors (author_id, first_name, last_name, nationality)
    VALUES (v_author_id, p_first_name, p_last_name, p_nationality);

    -- Print a notice message upon successful insertion
    RAISE NOTICE 'Author added successfully with author_id: %', v_author_id;
END;$$;
 �   DROP PROCEDURE public.add_author(IN p_first_name character varying, IN p_last_name character varying, IN p_nationality character varying);
       public          postgres    false            �            1255    34121 \   add_book(character varying, character varying, character varying, integer, integer, integer) 	   PROCEDURE     '  CREATE PROCEDURE public.add_book(IN p_book_name character varying, IN p_age_group_id character varying, IN p_publisher_id character varying, IN p_publication_year integer, IN p_quantity integer, IN p_price integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_id VARCHAR;
BEGIN
    -- Generate book_id from sequence book_id_seq
    SELECT 'BK' || to_char(nextval('book_id_seq'), 'FM0000') INTO new_id;

    -- Insert new book into Books table
    INSERT INTO Books (book_id, book_name, age_group_id, publisher_id, publication_year, available, quantity, price)
    VALUES (new_id, p_book_name, p_age_group_id, p_publisher_id, p_publication_year, p_quantity, p_quantity, p_price);

    -- Print success message
    RAISE NOTICE 'Book % has been added successfully with ID %.', p_book_name, new_id;
END;
$$;
 �   DROP PROCEDURE public.add_book(IN p_book_name character varying, IN p_age_group_id character varying, IN p_publisher_id character varying, IN p_publication_year integer, IN p_quantity integer, IN p_price integer);
       public          postgres    false            �            1255    34120    add_genre(character varying) 	   PROCEDURE       CREATE PROCEDURE public.add_genre(IN p_genre_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    new_id VARCHAR;
BEGIN
    -- Sinh mã genre_id từ SEQUENCE genre_id_seq
    SELECT 'G' || to_char(nextval('genre_id_seq'), 'FM0000') INTO new_id;

    -- Thêm thể loại mới vào bảng Genres
    INSERT INTO Genres (genre_id, genre_name)
    VALUES (new_id, p_genre_name);

    -- In ra thông báo thành công
    RAISE NOTICE 'Genre % has been successfully added with ID %.', p_genre_name, new_id;
END;
$$;
 D   DROP PROCEDURE public.add_genre(IN p_genre_name character varying);
       public          postgres    false            �            1255    34122 F   add_publisher(character varying, character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE public.add_publisher(IN p_publisher_name character varying, IN p_publisher_address character varying, IN p_publisher_phone character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_publisher_id VARCHAR;
BEGIN
    -- Generate publisher_id in the format PUBxxxx
    SELECT 'PUB' || to_char(nextval('publisher_id_seq'), 'FM0000') INTO v_publisher_id;

    -- Insert into Publishers table
    INSERT INTO Publishers (publisher_id, publisher_name, publisher_address, publisher_phone)
    VALUES (v_publisher_id, p_publisher_name, p_publisher_address, p_publisher_phone);

    -- Print a notice message upon successful insertion
    RAISE NOTICE 'Publisher added successfully with publisher_id: %', v_publisher_id;
END;
$$;
 �   DROP PROCEDURE public.add_publisher(IN p_publisher_name character varying, IN p_publisher_address character varying, IN p_publisher_phone character varying);
       public          postgres    false                       1255    25857    calculate_lost_book_fees()    FUNCTION     �  CREATE FUNCTION public.calculate_lost_book_fees() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 1   DROP FUNCTION public.calculate_lost_book_fees();
       public          postgres    false            p           0    0 #   FUNCTION calculate_lost_book_fees()    ACL     �   GRANT ALL ON FUNCTION public.calculate_lost_book_fees() TO admin;
GRANT ALL ON FUNCTION public.calculate_lost_book_fees() TO employee;
          public          postgres    false    261                       1255    25855    calculate_overdue_fees()    FUNCTION     �  CREATE FUNCTION public.calculate_overdue_fees() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 /   DROP FUNCTION public.calculate_overdue_fees();
       public          postgres    false            q           0    0 !   FUNCTION calculate_overdue_fees()    ACL     �   GRANT ALL ON FUNCTION public.calculate_overdue_fees() TO admin;
GRANT ALL ON FUNCTION public.calculate_overdue_fees() TO employee;
          public          postgres    false    260                       1255    34185    check_borrowing_limit()    FUNCTION     �  CREATE FUNCTION public.check_borrowing_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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

$$;
 .   DROP FUNCTION public.check_borrowing_limit();
       public          postgres    false                       1255    34187 8   delete_books_on_receipt_cancel_and_update_availability()    FUNCTION       CREATE FUNCTION public.delete_books_on_receipt_cancel_and_update_availability() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    r RECORD;
BEGIN
    -- Check if the status is changed to 'Canceled'
    IF NEW.status = 'Canceled' THEN
        -- Loop through each book in the canceled receipt
        FOR r IN (SELECT book_id, quantity FROM Borrowed_Books WHERE receipt_id = NEW.receipt_id) LOOP
            -- Update the available quantity of the book
            UPDATE Books
            SET available = available + r.quantity
            WHERE book_id = r.book_id;
        END LOOP;

        -- Delete all books associated with the canceled receipt
        DELETE FROM Borrowed_Books
        WHERE receipt_id = NEW.receipt_id;
    END IF;
    RETURN NEW;
END;
$$;
 O   DROP FUNCTION public.delete_books_on_receipt_cancel_and_update_availability();
       public          postgres    false            �            1255    25868    delete_inactive_members_proc() 	   PROCEDURE     �   CREATE PROCEDURE public.delete_inactive_members_proc()
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM Members
    WHERE is_active = FALSE;
END;
$$;
 6   DROP PROCEDURE public.delete_inactive_members_proc();
       public          postgres    false                       1255    34102 ,   find_books_by_author_name(character varying)    FUNCTION     �  CREATE FUNCTION public.find_books_by_author_name(aname character varying) RETURNS TABLE(book_id character varying, book_name character varying, author_name character varying, publication_year integer, available integer)
    LANGUAGE plpgsql
    AS $$
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
$$;
 I   DROP FUNCTION public.find_books_by_author_name(aname character varying);
       public          postgres    false            r           0    0 ;   FUNCTION find_books_by_author_name(aname character varying)    ACL     Z   GRANT ALL ON FUNCTION public.find_books_by_author_name(aname character varying) TO admin;
          public          postgres    false    257            �            1255    25863    get_age_group(date)    FUNCTION     �  CREATE FUNCTION public.get_age_group(birth_date date) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    age INT;
    age_group_names VARCHAR(50);
BEGIN
    -- Tính tuổi từ ngày sinh
    SELECT EXTRACT(YEAR FROM age(current_date, birth_date)) INTO age;

    -- Kiểm tra tuổi thuộc nhóm tuổi nào
    SELECT age_group_name INTO age_group_names
    FROM Age_groups
    WHERE age BETWEEN min_age AND max_age;

    RETURN age_group_names;
END;
$$;
 5   DROP FUNCTION public.get_age_group(birth_date date);
       public          postgres    false            s           0    0 '   FUNCTION get_age_group(birth_date date)    ACL     F   GRANT ALL ON FUNCTION public.get_age_group(birth_date date) TO admin;
          public          postgres    false    249            �            1255    25864    get_author_with_most_books()    FUNCTION     h  CREATE FUNCTION public.get_author_with_most_books() RETURNS TABLE(author_id character varying, first_name character varying, last_name character varying, nationality character varying, book_count bigint)
    LANGUAGE plpgsql
    AS $$
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
$$;
 3   DROP FUNCTION public.get_author_with_most_books();
       public          postgres    false            t           0    0 %   FUNCTION get_author_with_most_books()    ACL     D   GRANT ALL ON FUNCTION public.get_author_with_most_books() TO admin;
          public          postgres    false    250                       1255    34112 #   get_monthly_borrowed_books(integer)    FUNCTION       CREATE FUNCTION public.get_monthly_borrowed_books(year_input integer) RETURNS TABLE(month integer, total_borrowed_books bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    month_counter INTEGER := 1;
BEGIN
    FOR month_counter IN 1..12 LOOP
        RETURN QUERY
        SELECT
            month_counter,
            COUNT(*)
        FROM
            Borrowing_Receipts BR
        WHERE
            EXTRACT(MONTH FROM BR.borrow_date) = month_counter
            AND EXTRACT(YEAR FROM BR.borrow_date) = year_input;
    END LOOP;
END;
$$;
 E   DROP FUNCTION public.get_monthly_borrowed_books(year_input integer);
       public          postgres    false            u           0    0 7   FUNCTION get_monthly_borrowed_books(year_input integer)    ACL     V   GRANT ALL ON FUNCTION public.get_monthly_borrowed_books(year_input integer) TO admin;
          public          postgres    false    259                       1255    34106 *   search_books_by_keyword(character varying)    FUNCTION     �  CREATE FUNCTION public.search_books_by_keyword(keyword character varying) RETURNS TABLE(book_id character varying, book_name character varying, author_name character varying, publication_year integer, available integer, genre_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (b.book_id)
        b.book_id,
        b.book_name,
        CAST(CONCAT(a.first_name, ' ', a.last_name) AS VARCHAR) AS author_name,
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
$$;
 I   DROP FUNCTION public.search_books_by_keyword(keyword character varying);
       public          postgres    false            v           0    0 ;   FUNCTION search_books_by_keyword(keyword character varying)    ACL     Z   GRANT ALL ON FUNCTION public.search_books_by_keyword(keyword character varying) TO admin;
          public          postgres    false    258            �            1255    25853    update_account_active_status()    FUNCTION     �  CREATE FUNCTION public.update_account_active_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 5   DROP FUNCTION public.update_account_active_status();
       public          postgres    false            w           0    0 '   FUNCTION update_account_active_status()    ACL     �   GRANT ALL ON FUNCTION public.update_account_active_status() TO admin;
GRANT ALL ON FUNCTION public.update_account_active_status() TO employee;
          public          postgres    false    251                       1255    34180    update_available_books()    FUNCTION     s  CREATE FUNCTION public.update_available_books() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 /   DROP FUNCTION public.update_available_books();
       public          postgres    false                        1255    34128    update_receipt_status()    FUNCTION       CREATE FUNCTION public.update_receipt_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_returned_books INTEGER;
    total_borrowed_books INTEGER;
BEGIN
    -- Đếm tổng số sách trong phiếu mượn
    SELECT COUNT(DISTINCT book_id) INTO total_borrowed_books
    FROM borrowed_books
    WHERE receipt_id = NEW.receipt_id;

    -- Đếm số sách đã được trả lại trong phiếu mượn
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
$$;
 .   DROP FUNCTION public.update_receipt_status();
       public          postgres    false            x           0    0     FUNCTION update_receipt_status()    ACL     ?   GRANT ALL ON FUNCTION public.update_receipt_status() TO admin;
          public          postgres    false    256            	           1255    34189    update_status_to_returned()    FUNCTION     6  CREATE FUNCTION public.update_status_to_returned() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if return_date is updated and not null
    IF NEW.return_date IS NOT NULL THEN
        -- Update the status to 'Returned'
        NEW.status := 'Returned';
    END IF;
    RETURN NEW;
END;
$$;
 2   DROP FUNCTION public.update_status_to_returned();
       public          postgres    false            �            1259    25620    accounts    TABLE     �   CREATE TABLE public.accounts (
    account_id character varying(50) NOT NULL,
    username character varying(50) NOT NULL,
    password_id character varying(50) NOT NULL,
    is_active boolean NOT NULL
);
    DROP TABLE public.accounts;
       public         heap    postgres    false            y           0    0    TABLE accounts    ACL     -   GRANT ALL ON TABLE public.accounts TO admin;
          public          postgres    false    217            �            1259    25631 
   age_groups    TABLE     �   CREATE TABLE public.age_groups (
    age_group_id character varying(50) NOT NULL,
    age_group_name character varying(50) NOT NULL,
    min_age integer NOT NULL,
    max_age integer NOT NULL
);
    DROP TABLE public.age_groups;
       public         heap    postgres    false            z           0    0    TABLE age_groups    ACL     /   GRANT ALL ON TABLE public.age_groups TO admin;
          public          postgres    false    220            �            1259    34115    author_id_seq    SEQUENCE     x   CREATE SEQUENCE public.author_id_seq
    START WITH 301
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.author_id_seq;
       public          postgres    false            {           0    0    SEQUENCE author_id_seq    ACL     5   GRANT ALL ON SEQUENCE public.author_id_seq TO admin;
          public          postgres    false    230            �            1259    25636    authors    TABLE     �   CREATE TABLE public.authors (
    author_id character varying(50) NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(255) NOT NULL,
    nationality character varying(255) NOT NULL
);
    DROP TABLE public.authors;
       public         heap    postgres    false            |           0    0    TABLE authors    ACL     �   GRANT ALL ON TABLE public.authors TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.authors TO employee;
GRANT SELECT ON TABLE public.authors TO member;
          public          postgres    false    221            �            1259    25658    book_author    TABLE     ~   CREATE TABLE public.book_author (
    book_id character varying(50) NOT NULL,
    author_id character varying(50) NOT NULL
);
    DROP TABLE public.book_author;
       public         heap    postgres    false            }           0    0    TABLE book_author    ACL     {   GRANT ALL ON TABLE public.book_author TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.book_author TO employee;
          public          postgres    false    225            �            1259    34146    book_borrowing_summary    VIEW     �   CREATE VIEW public.book_borrowing_summary AS
SELECT
    NULL::character varying(50) AS receipt_id,
    NULL::bigint AS total_books_borrowed,
    NULL::text AS status,
    NULL::bigint AS total_price,
    NULL::integer AS fee;
 )   DROP VIEW public.book_borrowing_summary;
       public          postgres    false            ~           0    0    TABLE book_borrowing_summary    ACL     ;   GRANT ALL ON TABLE public.book_borrowing_summary TO admin;
          public          postgres    false    235            �            1259    25673 
   book_genre    TABLE     |   CREATE TABLE public.book_genre (
    book_id character varying(50) NOT NULL,
    genre_id character varying(50) NOT NULL
);
    DROP TABLE public.book_genre;
       public         heap    postgres    false                       0    0    TABLE book_genre    ACL     y   GRANT ALL ON TABLE public.book_genre TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.book_genre TO employee;
          public          postgres    false    226            �            1259    34116    book_id_seq    SEQUENCE     v   CREATE SEQUENCE public.book_id_seq
    START WITH 380
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 "   DROP SEQUENCE public.book_id_seq;
       public          postgres    false            �           0    0    SEQUENCE book_id_seq    ACL     3   GRANT ALL ON SEQUENCE public.book_id_seq TO admin;
          public          postgres    false    231            �            1259    25653    books    TABLE     ]  CREATE TABLE public.books (
    book_id character varying(50) NOT NULL,
    book_name character varying(256) NOT NULL,
    age_group_id character varying(50) NOT NULL,
    publisher_id character varying(50) NOT NULL,
    publication_year integer NOT NULL,
    available integer NOT NULL,
    quantity integer NOT NULL,
    price integer NOT NULL
);
    DROP TABLE public.books;
       public         heap    postgres    false            �           0    0    TABLE books    ACL     �   GRANT ALL ON TABLE public.books TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.books TO employee;
GRANT SELECT ON TABLE public.books TO member;
          public          postgres    false    224            �            1259    25703    borrowed_books    TABLE     �   CREATE TABLE public.borrowed_books (
    receipt_id character varying(50) NOT NULL,
    book_id character varying(50) NOT NULL,
    quantity integer NOT NULL,
    status character varying(50) NOT NULL
);
 "   DROP TABLE public.borrowed_books;
       public         heap    postgres    false            �           0    0    TABLE borrowed_books    ACL     x   GRANT ALL ON TABLE public.borrowed_books TO admin;
GRANT SELECT,INSERT,UPDATE ON TABLE public.borrowed_books TO member;
          public          postgres    false    228            �            1259    34152    book_inventory_summary    VIEW     �  CREATE VIEW public.book_inventory_summary AS
 SELECT count(b.book_id) AS total_books,
    sum(b.quantity) AS total_quantity,
    sum(b.available) AS total_available,
    sum(
        CASE
            WHEN ((bb.status)::text = 'Lost'::text) THEN bb.quantity
            ELSE 0
        END) AS total_lost,
    sum((b.price * b.quantity)) AS total_value
   FROM (public.books b
     LEFT JOIN public.borrowed_books bb ON (((b.book_id)::text = (bb.book_id)::text)));
 )   DROP VIEW public.book_inventory_summary;
       public          postgres    false    224    224    224    224    228    228    228            �           0    0    TABLE book_inventory_summary    ACL     ;   GRANT ALL ON TABLE public.book_inventory_summary TO admin;
          public          postgres    false    236            �            1259    25688    borrowing_receipts    TABLE     C  CREATE TABLE public.borrowing_receipts (
    receipt_id character varying(50) NOT NULL,
    employee_account_id character varying(50) NOT NULL,
    member_account_id character varying(50) NOT NULL,
    borrow_date date,
    due_date date,
    return_date date,
    status character varying(50) NOT NULL,
    fee integer
);
 &   DROP TABLE public.borrowing_receipts;
       public         heap    postgres    false            �           0    0    TABLE borrowing_receipts    ACL     �   GRANT ALL ON TABLE public.borrowing_receipts TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.borrowing_receipts TO employee;
GRANT SELECT,INSERT,UPDATE ON TABLE public.borrowing_receipts TO member;
          public          postgres    false    227            �            1259    25625 	   employees    TABLE     ;  CREATE TABLE public.employees (
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    date_of_birth date NOT NULL,
    phone character varying(50) NOT NULL,
    address character varying(50) NOT NULL,
    email character varying(50) NOT NULL
)
INHERITS (public.accounts);
    DROP TABLE public.employees;
       public         heap    postgres    false    217            �           0    0    TABLE employees    ACL     .   GRANT ALL ON TABLE public.employees TO admin;
          public          postgres    false    218            �            1259    34117    genre_id_seq    SEQUENCE     v   CREATE SEQUENCE public.genre_id_seq
    START WITH 43
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.genre_id_seq;
       public          postgres    false            �           0    0    SEQUENCE genre_id_seq    ACL     4   GRANT ALL ON SEQUENCE public.genre_id_seq TO admin;
          public          postgres    false    232            �            1259    25648    genres    TABLE     {   CREATE TABLE public.genres (
    genre_id character varying(50) NOT NULL,
    genre_name character varying(50) NOT NULL
);
    DROP TABLE public.genres;
       public         heap    postgres    false            �           0    0    TABLE genres    ACL     �   GRANT ALL ON TABLE public.genres TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.genres TO employee;
GRANT SELECT ON TABLE public.genres TO member;
          public          postgres    false    223            �            1259    25628    members    TABLE     O  CREATE TABLE public.members (
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    address character varying(50) NOT NULL,
    date_of_birth date NOT NULL,
    phone character varying(50) NOT NULL,
    email character varying(50) NOT NULL,
    expire_date date
)
INHERITS (public.accounts);
    DROP TABLE public.members;
       public         heap    postgres    false    217            �           0    0    TABLE members    ACL     s   GRANT ALL ON TABLE public.members TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.members TO employee;
          public          postgres    false    219            �            1259    25913    members_count_by_age_group    VIEW     �  CREATE VIEW public.members_count_by_age_group AS
 SELECT ag.age_group_id,
    ag.age_group_name,
    count(m.account_id) AS total_members
   FROM (public.age_groups ag
     LEFT JOIN public.members m ON (((m.date_of_birth >= (CURRENT_DATE - ('1 year'::interval * (ag.max_age)::double precision))) AND (m.date_of_birth <= (CURRENT_DATE - ('1 year'::interval * (ag.min_age)::double precision))))))
  GROUP BY ag.age_group_id, ag.age_group_name;
 -   DROP VIEW public.members_count_by_age_group;
       public          postgres    false    219    220    220    220    220    219            �           0    0     TABLE members_count_by_age_group    ACL     ?   GRANT ALL ON TABLE public.members_count_by_age_group TO admin;
          public          postgres    false    229            �            1259    34119    publisher_id_seq    SEQUENCE     {   CREATE SEQUENCE public.publisher_id_seq
    START WITH 190
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.publisher_id_seq;
       public          postgres    false            �           0    0    SEQUENCE publisher_id_seq    ACL     8   GRANT ALL ON SEQUENCE public.publisher_id_seq TO admin;
          public          postgres    false    234            �            1259    25643 
   publishers    TABLE     �   CREATE TABLE public.publishers (
    publisher_id character varying(50) NOT NULL,
    publisher_name character varying(50) NOT NULL,
    publisher_address character varying(50) NOT NULL,
    publisher_phone character varying(50) NOT NULL
);
    DROP TABLE public.publishers;
       public         heap    postgres    false            �           0    0    TABLE publishers    ACL     �   GRANT ALL ON TABLE public.publishers TO admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.publishers TO employee;
GRANT SELECT ON TABLE public.publishers TO member;
          public          postgres    false    222            �            1259    34118    receipt_id_seq    SEQUENCE     y   CREATE SEQUENCE public.receipt_id_seq
    START WITH 300
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.receipt_id_seq;
       public          postgres    false            �           0    0    SEQUENCE receipt_id_seq    ACL     6   GRANT ALL ON SEQUENCE public.receipt_id_seq TO admin;
          public          postgres    false    233            Y          0    25620    accounts 
   TABLE DATA           P   COPY public.accounts (account_id, username, password_id, is_active) FROM stdin;
    public          postgres    false    217   ��       \          0    25631 
   age_groups 
   TABLE DATA           T   COPY public.age_groups (age_group_id, age_group_name, min_age, max_age) FROM stdin;
    public          postgres    false    220   ��       ]          0    25636    authors 
   TABLE DATA           P   COPY public.authors (author_id, first_name, last_name, nationality) FROM stdin;
    public          postgres    false    221   �       a          0    25658    book_author 
   TABLE DATA           9   COPY public.book_author (book_id, author_id) FROM stdin;
    public          postgres    false    225   ��       b          0    25673 
   book_genre 
   TABLE DATA           7   COPY public.book_genre (book_id, genre_id) FROM stdin;
    public          postgres    false    226   %�       `          0    25653    books 
   TABLE DATA           }   COPY public.books (book_id, book_name, age_group_id, publisher_id, publication_year, available, quantity, price) FROM stdin;
    public          postgres    false    224   �       d          0    25703    borrowed_books 
   TABLE DATA           O   COPY public.borrowed_books (receipt_id, book_id, quantity, status) FROM stdin;
    public          postgres    false    228   c(      c          0    25688    borrowing_receipts 
   TABLE DATA           �   COPY public.borrowing_receipts (receipt_id, employee_account_id, member_account_id, borrow_date, due_date, return_date, status, fee) FROM stdin;
    public          postgres    false    227   �0      Z          0    25625 	   employees 
   TABLE DATA           �   COPY public.employees (account_id, username, password_id, is_active, first_name, last_name, date_of_birth, phone, address, email) FROM stdin;
    public          postgres    false    218   �>      _          0    25648    genres 
   TABLE DATA           6   COPY public.genres (genre_id, genre_name) FROM stdin;
    public          postgres    false    223   2R      [          0    25628    members 
   TABLE DATA           �   COPY public.members (account_id, username, password_id, is_active, first_name, last_name, address, date_of_birth, phone, email, expire_date) FROM stdin;
    public          postgres    false    219   �S      ^          0    25643 
   publishers 
   TABLE DATA           f   COPY public.publishers (publisher_id, publisher_name, publisher_address, publisher_phone) FROM stdin;
    public          postgres    false    222   �      �           0    0    author_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.author_id_seq', 304, true);
          public          postgres    false    230            �           0    0    book_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.book_id_seq', 380, true);
          public          postgres    false    231            �           0    0    genre_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.genre_id_seq', 45, true);
          public          postgres    false    232            �           0    0    publisher_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.publisher_id_seq', 190, true);
          public          postgres    false    234            �           0    0    receipt_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.receipt_id_seq', 300, false);
          public          postgres    false    233            �           2606    25624    accounts accounts_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);
 @   ALTER TABLE ONLY public.accounts DROP CONSTRAINT accounts_pkey;
       public            postgres    false    217            �           2606    25635    age_groups age_groups_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.age_groups
    ADD CONSTRAINT age_groups_pkey PRIMARY KEY (age_group_id);
 D   ALTER TABLE ONLY public.age_groups DROP CONSTRAINT age_groups_pkey;
       public            postgres    false    220            �           2606    25642    authors authors_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);
 >   ALTER TABLE ONLY public.authors DROP CONSTRAINT authors_pkey;
       public            postgres    false    221            �           2606    25662    book_author book_author_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public.book_author
    ADD CONSTRAINT book_author_pkey PRIMARY KEY (book_id, author_id);
 F   ALTER TABLE ONLY public.book_author DROP CONSTRAINT book_author_pkey;
       public            postgres    false    225    225            �           2606    25677    book_genre book_genre_pkey 
   CONSTRAINT     g   ALTER TABLE ONLY public.book_genre
    ADD CONSTRAINT book_genre_pkey PRIMARY KEY (book_id, genre_id);
 D   ALTER TABLE ONLY public.book_genre DROP CONSTRAINT book_genre_pkey;
       public            postgres    false    226    226            �           2606    25657    books books_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);
 :   ALTER TABLE ONLY public.books DROP CONSTRAINT books_pkey;
       public            postgres    false    224            �           2606    25707 "   borrowed_books borrowed_books_pkey 
   CONSTRAINT     q   ALTER TABLE ONLY public.borrowed_books
    ADD CONSTRAINT borrowed_books_pkey PRIMARY KEY (receipt_id, book_id);
 L   ALTER TABLE ONLY public.borrowed_books DROP CONSTRAINT borrowed_books_pkey;
       public            postgres    false    228    228            �           2606    25692 *   borrowing_receipts borrowing_receipts_pkey 
   CONSTRAINT     p   ALTER TABLE ONLY public.borrowing_receipts
    ADD CONSTRAINT borrowing_receipts_pkey PRIMARY KEY (receipt_id);
 T   ALTER TABLE ONLY public.borrowing_receipts DROP CONSTRAINT borrowing_receipts_pkey;
       public            postgres    false    227            �           2606    25652    genres genres_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);
 <   ALTER TABLE ONLY public.genres DROP CONSTRAINT genres_pkey;
       public            postgres    false    223            �           2606    25647    publishers publishers_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (publisher_id);
 D   ALTER TABLE ONLY public.publishers DROP CONSTRAINT publishers_pkey;
       public            postgres    false    222            W           2618    34149    book_borrowing_summary _RETURN    RULE     �  CREATE OR REPLACE VIEW public.book_borrowing_summary AS
 SELECT br.receipt_id,
    count(DISTINCT bb.book_id) AS total_books_borrowed,
    max((bb.status)::text) AS status,
    sum(b.price) AS total_price,
    br.fee
   FROM ((public.borrowing_receipts br
     JOIN public.borrowed_books bb ON (((br.receipt_id)::text = (bb.receipt_id)::text)))
     JOIN public.books b ON (((bb.book_id)::text = (b.book_id)::text)))
  GROUP BY br.receipt_id;
 �   CREATE OR REPLACE VIEW public.book_borrowing_summary AS
SELECT
    NULL::character varying(50) AS receipt_id,
    NULL::bigint AS total_books_borrowed,
    NULL::text AS status,
    NULL::bigint AS total_price,
    NULL::integer AS fee;
       public          postgres    false    227    228    228    228    4785    227    224    224    235            �           2620    25858 /   borrowed_books calculate_lost_book_fees_trigger    TRIGGER     �   CREATE TRIGGER calculate_lost_book_fees_trigger AFTER UPDATE OF status, quantity ON public.borrowed_books FOR EACH ROW WHEN (((new.status)::text = 'Lost'::text)) EXECUTE FUNCTION public.calculate_lost_book_fees();
 H   DROP TRIGGER calculate_lost_book_fees_trigger ON public.borrowed_books;
       public          postgres    false    228    228    228    228    261            �           2620    34186 ,   borrowed_books check_borrowing_limit_trigger    TRIGGER     �   CREATE TRIGGER check_borrowing_limit_trigger BEFORE INSERT OR UPDATE ON public.borrowed_books FOR EACH ROW EXECUTE FUNCTION public.check_borrowing_limit();
 E   DROP TRIGGER check_borrowing_limit_trigger ON public.borrowed_books;
       public          postgres    false    263    228            �           2620    25854    members member_expire_trigger    TRIGGER     �   CREATE TRIGGER member_expire_trigger AFTER INSERT OR UPDATE OF expire_date ON public.members FOR EACH ROW EXECUTE FUNCTION public.update_account_active_status();
 6   DROP TRIGGER member_expire_trigger ON public.members;
       public          postgres    false    251    219    219            �           2620    34129 (   borrowed_books trg_update_receipt_status    TRIGGER     �   CREATE TRIGGER trg_update_receipt_status AFTER UPDATE OF status ON public.borrowed_books FOR EACH ROW EXECUTE FUNCTION public.update_receipt_status();
 A   DROP TRIGGER trg_update_receipt_status ON public.borrowed_books;
       public          postgres    false    228    228    256            �           2620    34188 Q   borrowing_receipts trigger_delete_books_on_receipt_cancel_and_update_availability    TRIGGER       CREATE TRIGGER trigger_delete_books_on_receipt_cancel_and_update_availability BEFORE UPDATE ON public.borrowing_receipts FOR EACH ROW WHEN (((new.status)::text = 'Canceled'::text)) EXECUTE FUNCTION public.delete_books_on_receipt_cancel_and_update_availability();
 j   DROP TRIGGER trigger_delete_books_on_receipt_cancel_and_update_availability ON public.borrowing_receipts;
       public          postgres    false    227    227    264            �           2620    34181 -   borrowed_books trigger_update_available_books    TRIGGER     �   CREATE TRIGGER trigger_update_available_books BEFORE INSERT OR UPDATE ON public.borrowed_books FOR EACH ROW EXECUTE FUNCTION public.update_available_books();
 F   DROP TRIGGER trigger_update_available_books ON public.borrowed_books;
       public          postgres    false    228    262            �           2620    34190 4   borrowing_receipts trigger_update_status_to_returned    TRIGGER     �   CREATE TRIGGER trigger_update_status_to_returned BEFORE UPDATE ON public.borrowing_receipts FOR EACH ROW WHEN ((old.return_date IS DISTINCT FROM new.return_date)) EXECUTE FUNCTION public.update_status_to_returned();
 M   DROP TRIGGER trigger_update_status_to_returned ON public.borrowing_receipts;
       public          postgres    false    227    265    227            �           2620    25856 "   borrowing_receipts update_late_fee    TRIGGER     �   CREATE TRIGGER update_late_fee AFTER INSERT OR UPDATE OF return_date, due_date, status ON public.borrowing_receipts FOR EACH ROW EXECUTE FUNCTION public.calculate_overdue_fees();
 ;   DROP TRIGGER update_late_fee ON public.borrowing_receipts;
       public          postgres    false    260    227    227    227    227            �           2606    25668 &   book_author book_author_author_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.book_author
    ADD CONSTRAINT book_author_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(author_id);
 P   ALTER TABLE ONLY public.book_author DROP CONSTRAINT book_author_author_id_fkey;
       public          postgres    false    4773    225    221            �           2606    25663 $   book_author book_author_book_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.book_author
    ADD CONSTRAINT book_author_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);
 N   ALTER TABLE ONLY public.book_author DROP CONSTRAINT book_author_book_id_fkey;
       public          postgres    false    224    4779    225            �           2606    25678 "   book_genre book_genre_book_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.book_genre
    ADD CONSTRAINT book_genre_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);
 L   ALTER TABLE ONLY public.book_genre DROP CONSTRAINT book_genre_book_id_fkey;
       public          postgres    false    4779    226    224            �           2606    25683 #   book_genre book_genre_genre_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.book_genre
    ADD CONSTRAINT book_genre_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id);
 M   ALTER TABLE ONLY public.book_genre DROP CONSTRAINT book_genre_genre_id_fkey;
       public          postgres    false    223    4777    226            �           2606    25718     books books_age_group_id_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_age_group_id_foreign FOREIGN KEY (age_group_id) REFERENCES public.age_groups(age_group_id);
 J   ALTER TABLE ONLY public.books DROP CONSTRAINT books_age_group_id_foreign;
       public          postgres    false    220    224    4771            �           2606    25723     books books_publisher_id_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_publisher_id_foreign FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id);
 J   ALTER TABLE ONLY public.books DROP CONSTRAINT books_publisher_id_foreign;
       public          postgres    false    4775    222    224            �           2606    25713 *   borrowed_books borrowed_books_book_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.borrowed_books
    ADD CONSTRAINT borrowed_books_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id);
 T   ALTER TABLE ONLY public.borrowed_books DROP CONSTRAINT borrowed_books_book_id_fkey;
       public          postgres    false    224    228    4779            �           2606    25708 -   borrowed_books borrowed_books_receipt_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.borrowed_books
    ADD CONSTRAINT borrowed_books_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES public.borrowing_receipts(receipt_id);
 W   ALTER TABLE ONLY public.borrowed_books DROP CONSTRAINT borrowed_books_receipt_id_fkey;
       public          postgres    false    227    228    4785            �           2606    25693 >   borrowing_receipts borrowing_receipts_employee_account_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.borrowing_receipts
    ADD CONSTRAINT borrowing_receipts_employee_account_id_fkey FOREIGN KEY (employee_account_id) REFERENCES public.accounts(account_id);
 h   ALTER TABLE ONLY public.borrowing_receipts DROP CONSTRAINT borrowing_receipts_employee_account_id_fkey;
       public          postgres    false    217    4769    227            �           2606    25698 <   borrowing_receipts borrowing_receipts_member_account_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.borrowing_receipts
    ADD CONSTRAINT borrowing_receipts_member_account_id_fkey FOREIGN KEY (member_account_id) REFERENCES public.accounts(account_id);
 f   ALTER TABLE ONLY public.borrowing_receipts DROP CONSTRAINT borrowing_receipts_member_account_id_fkey;
       public          postgres    false    217    4769    227            �           2606    34173 /   borrowed_books fk_borrowing_receipts_receipt_id    FK CONSTRAINT     �   ALTER TABLE ONLY public.borrowed_books
    ADD CONSTRAINT fk_borrowing_receipts_receipt_id FOREIGN KEY (receipt_id) REFERENCES public.borrowing_receipts(receipt_id) ON DELETE CASCADE;
 Y   ALTER TABLE ONLY public.borrowed_books DROP CONSTRAINT fk_borrowing_receipts_receipt_id;
       public          postgres    false    4785    228    227            Y      x�e�;�&�R�a��c��%2�<$�#a���7q���.s"�̯'�ꉷ�x�j��7?~�����?����?��?���?��O�����������᏿��%�J�ʏ�G�G�G�#��<=?��-�N�Ώ�G�=~��<�r����>�<���.�x����C_<�x���]<|��⡋�/\<t��Ń��.�xp����.��x����SO_<�x���'O]<}��⩋�/�\<u��œ��.��xr����O.��x����SO_<.�%��A�~������,�Y�YJ��g)f)�R���E���=�����Yʳ��f)�R�R��<K1Ki��,�,�Yʳ��f)�R��кx����[o_��x���7o]�}��⭋�/�\�u��ś��.޾xs����o.޺x����[o_��8tq������ዃ�C�/.]�8�8tq������ዃ�C�/.]�8�8tq������ዃ��.>��p����.>������G_|�����]||��⣋�/>\|t��Ň��.>��p����.�������W__|�����/_]|}��⫋�/�\|u��ŗ��.���r����_.�������W__|�����?]�|��⧋�/~\�t��ŏ��.~��q����?.~������O?_������?]�|���.���t������?����]���.���/�p�G|�?���?\���_���.���t��~.?d��>��o���R�ҏ�G�G�Gţ֣����~���V�֏�G�G�GǣG�?��
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�a
�p�aj�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps�j�ps͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&͙j�ts&�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs�Yj�rs��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs6��j�vs����O]���4g�9���4g�9���4g+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��d+'�9��$��pN���r�I��PN�9	r�I8'ANB9	�$�I('�9	�$�� '���s�$��pN���r�I��PN�9	r�I8'ANB9	�$�I('�9	�$�� '���s�$��pN���r�I��PN�9	r�I8'ANB9	�$�I('�9	�$�� '���s�$��pN���r�I��PN�9	r�I8'ANB9	�$�I('�9	�$�� '���s�$��pN���>?�aB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN�9AsB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN�9AsB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN�9AsB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN�9AsB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN�9AsB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN� �  9AsB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN�9AsB�	7'hN�9���	5'ܜ�9�愛4'Ԝps�愚nNМPs��	�jN�9AsB�	7'hN�9���9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs�9j�qs͹
�uH,!1
�q�a:
�q�a:
�q�a:
�q�a:
�q�a:
�q�����i����0����0����0����0����0����0����0����0����?O�?O���Ia:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LGa:�!LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa��%LWa���S5�9��\5�9��\5�9��\5�9��\5�9��\5�9��\5�9��\5�9��\5�9��\5�9w�*@ws.͹j�us.͹j�us.͹j�us.͹j�us.͹��uN.9���uN.9���uN.9���uN.9���uN.9���uN.9���uN.9���uN.9���uN.9�*�u).��*�u).��*�u).��*�u).��*�u).��*�u).��*�u).��*�u).��*�u).��*�u).��*�u).�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x*�s)�x�t�������)'�9y��)'�9y��)'�9y��)'�9y��)'�9y��)'�9y��)'�9y��)'�9y��)'�9y������ǧ���<7�ќ��<7�ќ��<7�ќ��<7�ќ��<7�ќ��<7��nο��?De�o�����χ����8���=N�������~�������1�����{<<���~����>�����y?��������Ą��K?���[0X0��[0X0��[0X0��[0X0��[0X0��[0X0��[0X0��[0X0��[0X0��[0Y0��[0Y0��[0Y0��[0Y0��[0Y0��[0Y0��[0Y0��[0Y0��[0Y0��[0Y���[�X���[�X���[�X���[�X���[�X���[�X���[�X���[�X���[�X���[�X���[�Y���[�Y���[�Y���[�Y���[�Y���[�Y���[�Y���[�Y���[�Y���[�Y���]߂`A��[,�wA|��.�oA� ��-Ļ ���xķ X���]߂`�y�o�a�y�o�a�y�o�a�y�o�a�y�o�a�y�o�a�y�o�a�y�o�a�y�o�a�y�o�a�}�o�e�}�o�e�}�o�e�}�o�e�}�o�e�}�o�e�}�o�e�}�o�e�}�o�e�}�o�e�{�o�c�{�o�c�{�o�c�{�o�c�{�o�c�{�o�c�{�o�c�{�o�c�{�o�c�{�o�c��]��|X�y|�|��o���w��[�a��]����[��]��|X�y|�|��o���w��[�a��]��|~�����S0~=)�� ��8�p���{ �� N�8����{ ���8}��=��{ ����{ ϯ7���n�t���y��_���_d���      \   \   x�st70�t���I�4�44�rt70�IM��44�44�9#�K��SJsJ8-8�LA�&�#3N3��)gpj^f~��)�$�=... H�      ]   �	  x�u�]wڸ���_ѻ�;�sI�WI3!�]�a��,qd+����_�`9�\tڱdYz?�~��u0p��N��e��9Q�J�F�_�4:d/v#]�^de�N� �4�#�`�(�OQ*l�)#���=�?*WZ	î�+����	��f�%٫w�-K��˅���	{�����{�E�ڥ��^����7�2;���}3fOjo5vu%EYV���oΰ�"W���,�Z:�_�J�~]b��6G��S�w��i��MZ���E3��y��`�[��b�B�6_�CvmsiTb�;�(t�s_�N�v+|��*��I��:qR��ص@:pFW"�=�?X���R�0�����)�Q�<�� �P�%������)�>ְ�p{
��e�u�uH^3#f[!_>߈$c7��P6#�NP�DpD�g�PM���=&w�2煗��f�!gkaR�0�E�I��sm���m-�I��P{�$t8b7NQX��)���s=#v�F��y�@�fBi|���N��������	�C�3
�7�9C��b����Ԋ�~�i
�Q���u�n�Ⱥn�O�̤�o�+P�y���(o�9�R�oJm4���K)7���Q��f�fG���պ�sR�4��מ��Z�-{���;��hĮe����@���\���G�f�wm�G���>;f-K_�[���uG�dd�*�(,}�\K�����)=Gu�]o�J�ح2��1-�$te�=�� ����c���[U ����o).S�A=]��uq�I��E�F���Ʊ���2�M&{{d���kN!��t���t/�Qd"��H˽d/��J���:W��N��1ҩ) �pzM��v�H�=����V�'
%�ڱ	%/��yt���C���p4gkQ�<��1�,�j��)<Ę:r���=4�>8�x�^�����n�5���Gl�vT�۲w�q�pH�B�<)i��c�~���z��oeev�g�I�պ�N(wD��#�i��`���s����[�
C������e2���u!�ㄣI� qW()�pA�'Cv�z����HPZ��LH��s�~�.�ˣ�<	���'�2�UCa6Ss�LH�Zg)<)�;_�L�q�*$�o6��t�2��kE�\*�dF�few^����s3�x���.4Z/�ϔ���_< a[�W�$Mk���
lG���4M�j{!�v�i���:�X�[��'jJe�T�������uY�R1���K�t�m*͖��4�ϝ/��>��t�]Ձ\ɝ�E��x�v҇L��>ٓ+��sv��c�p�X$�P<$��kG'Op�#XA��q0�� �^(d�hҞ��c$���>"Dx�����������S:a���6G���q�Z�n-o�����g�z{0&������l�R"�RP�q�fȵ^ �o��!"a?�������T���%{0���f��h�=�Pg�D��f�r
0`�B��ڬ�0G������4= ��@�0��}Ȫ 0���@�)�u���ʶ m����7J��|o�L���	�E�[dzU�^����z�` ��s��w� �y�������r���tkN(�
t'���00}> 4%{�Y�B҅���s�=������=߯������w���9�~��:��P�}���{��3C^č���FU�ً��5�o��<����6�_�30��A򯙧��XW'm��d%k��p)�����j�&'U%\(�s�q�`�2(FU������B�B�Bg� �����W��1Ŀ��e��(�`�@�����0*X���z��sP��hl�Ϝ����n��sY|b>�E*Cq��QO�s���Qͦ���zb́�w`< s�D�-�C�sim�Nv1����ۛEO�9��I��PV%�`w���q��-c�A�9(�=��ll�>Y�#��� ��©Se|��ߊ�s�����f	�(��(1M�#W��~'����e��dѓa>�u�B���f���A쿚���D�D�G$��6|�^�2[��aX�K�RmP�s��=�� cG�JV_�yT[�4�Vhذ�@�Ϣ�|O@�7��E�W� l8Ƚf�#,���}�jL��=��!q���ǁ���D�.7��5�}NW��RG���	ľ���-�O�	��2�Y�����IS�<:���l<�) ���~�yL�����
��.m������Ugr�	O�/�l�o'��E���8��5X~-�[|���@�����:�F�C�-S�ិ�"GC?u���+��\�wx����՚��iB?q��O�h�5�(���=�ݺ��~C5$��/7�P��~6PN�3�n˯3	SF- W����4�[!e� �<l%����� ����hx���"t�i���!Ռ����[AY�͞D;0�z(�%�{<bO;A�R?�zy��=\����?_�|�?=ԇM      a   W  x�m�=��8��}�� H�"�w�1����~�/ɉ1U]"�H$��������w��~��Wk5?��ާ6������跾Y���~�z�9/==zZ��x?��ߧ�����͵?�]�������5���+U�����gS��Y�޷��tj�p��Q�����F�zޡ�}���m�삕����u�!K\�C�g�;���������ߧ6u[�z���&[뛲`��~C^�����s^�=��Pz�xs�F<��C��G���~����~��Jc>i롓�Mo(ݶq�(���1|��[�Щ�ؓ���X�v���	Y�'t����+w�ӈ7�v�cP����W�n=��1uwn�l��>���.E��Þ��]n���9�͟�Svȷ=od�6�Kp��#�q2�����R�}�r�|Ӎz˘��w+�N���;ss�QPU�]QNn֮�b�a/�Z^i�2^���S�3l���]�Z����/�8k[�ݲY��K�w C{����.KT���'��s>�@�u�)y�_:�0�HD��,���g̒�:o���da��YJX ^O� ����4z���	?T�B�Ky{����[ {�·`q}d1��%ڥs�7^��]׾��y���b��ov�"�N�&�^�!���?[��U��$�g��d1X^�.��o�ʿuG�_@LY��~����ޑ�s>-���b�'��27+�8��� Ր^��D+����w�[�dA���UMw����u��NF��f�lq�;*B[z߁�l%o��~�vq���E��o?�����X����=k� ��85�L��Hh�Q���gQ;�"Sj@��z�w�"�Q����Rs��P��(E�%���[�GVD�h|S$�����?�yq�>z�϶�`ȝ���7�I(��bH%Ą=ub�]���8XWk=j�pv�@��ó&�-k@�t𭫯2�(�p��mῙ�"�������FƑ�N����q�"t�yȺT�N��֕5N,�h�[r%��u�>���h��ͨ2���p�qD2�"�h����q[��Q���%ԧ6���R=?�-���g�v��!��;mF����1����Q�8'�Y��y����4ו؊Ǻ�����w2��K?!��C���"��.�R^YtxZ�l����a�q���b�`�-��GO��WS�e���{Ev��ڙU }U���(�9�.��Yi3G��s*ߛ����NJ11�ȎN��$^T;]9� ,���;�(�qN��P����u���a��j1I��T��^S}AZ8;7"&���舸ue);�|���Qe��Osa���ch	3s�5�)ⳅa���E����2��Y��1ovO-��@� :�d�5�W����d���ʨv�Â��u�6( G�nV2g|�	�H�O�y�)�GMEC�S�B����FOV©����۵�g>l���Ȃ��e�D��X����~�5X�^q�@����vt!T������:C�x_*�B_��R����S9K�-*e��{G|_`��xO�n>0��f����D�i��[ځ/�%��wj1O��z<�&'d=�So�}F��M�V�$�/�Cz̽�y��K��\�K�*����ӎ�:�N{������vH5Ă��+E�ݑ��Y@�xft� ��k�:��Ba�m[� �ZX��CƑ�ֳF�ϹbN�D��ӯ�{fz���]�I>�G#?���k<OV �ؓ
r�V~����J��;"���Vw�b�{4qT�%����Y��#��/։�ö��f�ȝ)��y��o��m�Zo�CW�)�0�/�w��0�<z�yq�2����0�	���3�HD��w%ߡg��DD��_�p49`�n��6,�N����<O0���#�
�>��'��+B�~�|t�fy��$���ߓ63�u=3�5{�o�����S���1�
x/��h9�B��"��GI4�D����r�`Ύ�f�{V�gG���=+NfΰFzS:X�Z���DE@Ϣ�ZY?�Nt��sd8��C!Gi㜞�)��$D7#&L55������PG����5l�.9'�Z�q2�����#�Le�S��O5ׇC*#���@0+g/ߴ�+a�T�ʓ��؃����8uj�_g*{�,���xc�D\;&�P6���qE��X��o�x�:8S��hڮ�nғ���`�;������:7T�cF�m����͓;&~V�P���԰Q*3�c����g�C�XY��u������?w�l�a��Qc�ͤw����d�LQWT�����~o���u���	������/�&L����wz��`���#�y2T��cT<4U�n�x�W�[f��	=�C�c�9��+#��������+����R_R�1O�ZV�/�R�7�8t�bި����c`����|e�	N��~�YI��13��霖�O�먾;��=�:ڣ�PaQ�\���5,���6��V#S!�=~��l����1�weA2ܓz,Q�iv�͖J�ⱖ���a���gn(C�,o�}N�[�E��Ǥp�� �R��:ʓOt!w���,�v�^��m�֌��tמ��(D�+�Ȁ��� }��\`d�t��'�w�
XN%�r҄n�����j=qM����FW�1#��dN�Suf���� �/t��#=%Ee��nd�@Ź�ݘ��f�wV�NK�����J��>�?����{��:��E���{� ��ʚC�ӏ��G�<�7�&ʩ�T�����~������oox���G��Y��|�~�݊��GL�[D9=ɷQG����f�օW�58�������.jܓI׊^>��{@/:s/�;Q �k�#8�3��A|K���zC����_��=��p�+2�{dVӎټ�A���%�ʌ���lu&�|�=���7
�7#Dq]�	8��w��P�(�|Bű�F��3�o��L#�w6�gxe寠���R��T��yA���5bfc�n���,&���r�j}�ޅ���O���VOwF$v���b��!�����v��[����	�|�2�RR�� ����Ӥ����{��ck�8�t`�qON�3�o�["�wƒ�;���ʵ2��}L�f������tl��0j�����W�}�Ϩ��5��:&Z,5ܚ?(�m�'P���TAS����/�1��w@m��W�L���#;������Y�S��-�Ԃ<ͽ����O���V��j�/y�孹�#��D�Gh�2;�&�K߉��v�N�lQ����x��w�[��x�j�N�YO�YS����1��N��M�:6�P�=��y�<�9�6w���h��w���:J?�y���~�k���^y�	����4�Be��%���r30��
S�덳Tq���G�#�-̚ٸ�]8�"���c�D$�c7�hZ��-�}UV�O5Z�np>�[T��������z����n��'f΄�1h����q�	��V�#{TO;�������<Ҳ�s��I�<�`j��-(0��wϔ��2�:O�vF���Y�1;��37*ޕ]��9�M�/Z����-�Is�Q�0�dr��^�cd*��9��-���S+*�5x���R�?�H��o2ۥ޲�r;�c�TL*�.�w�4ɟy�˩�%>��<z��|�;��n�u���49Wf:0��8��P�TG�O4��)�:��y��\��L׷������������      b   �
  x�e�K��6D�y�Iɒ�a�I�B����ҭ�ސ��O���b�����~��O�z~.��s1J�sQW��cc��b�\�s�\D���~W�c�.�����s��;9������~t�����������}���;����hK}7��@���U�E�:�{g��b<�KF�:�߉c��y�3�}.j�Y�r����]'���t��Ί��GKO��b�n>O���7<�[�{��t���T֑��w��SU�q�x���Ld�u�3�\Rk�%�x)b'�w���nmG�T7�ѱm���<�L�T��Gq}�����e�"�1�,�G����&}��eQ���㔙H� Gg�?rpVp�7��b�8y:�Yށ<��A�T�L�g8F��:v���υ 7�cg��b�s�s:��LI��N�1�E�u���N��3���a#/,m[��°�/؁<7#1
9�]�����<�ERf9`b'7�|(K�򶽠;%���t�I�8�U1�agMX4���u݈�'��d�P��:��R{s)�d�T��}�f�8K��a�g�����rۻ��A��ρ����S��R�G�F�j����E��Tb�Fb(���c��e$_�މ�����N�,_�s�P�{�ڛ�ǸQ�S��;�*���j5
�x06O*3V=�q)0�̓��	knU�:��8+���Ի~#.^����5?��i&%ڵ<�<�\9��j��x�q�|h��I�3���s�J���c�.���pV$V�w�K����;C8�R]@$�]��$�E¢��*%Fjo�l��u�c�a=Y����^̟,��1��y���I���ɂ"Q�:/D�1�%���k �X�_�lt��I����i@q��u:(i�ݬ�F
�M��`b<�!b��� K�Hs�1#�@�k������B���l=���<5l��u�3^�k�m-�|`�Q@�D��Ha�ll|K�6��Z�3U��}�����}8���ٍ6H��4WV�_��!
ꥅ;��ގX��]��;�Qe�7>M�����@ u���U�y���87Y`O{��y-���;
7Cj��P6*m�E�Mh7  6��r�U�	v��:��ʧ̈́�Y����R�,
t�Y�)�fɲ���������>��a�0?��5��1|W't�d�5��� Rl��b�p�=@�d�n����g�8�����\%cT���ӽO�C�6}�S4�n냣��݃n��U�T�\$`�#ްq�m4��'���baI�]C�B��h���.�9߃N�e �2���;�]�q�%�&��i��Xe�-
�Gp��E��P��AmC
S7�ą,�ތwA�5۰��;�焋A����w��������TB-](m�?������U�)Z ZrQ:�KN���Q�;(�-@��"O���e-=?"&����`/����e"c�+(U:�������k��a���)��x؁0�������8�)$(v�f�s7�}�K;)|��L��d�&�&?�x3|W3�,��8��o=�ω�?D&�]�(�ޞx'��5�X�"�hN�� 	$�`l@��Z�v�J����D�ܲZ\t�o^u�t�zlJ��ET;��=�S�I��Vd :�S���M�����ZS��Q�=�q�;�^38԰v��4G��E�y�Н.���h��O��#��y�Ҡ+7�Y��DY�z�<��iE��3�Z�=���OamR�ZPh�U���=�/��r�<�پ����Q\ ��1��!�Aݲ���3>��$���_��d'nI��0-r��1@*D �p��8�a|&jA�2酢]�X�|-�a�kHSX&	`a��30�2�$F\(S��(9p�����-2�:�kwF��t��('��D���C ѝ���Ws�hDA�q�C���?%�S�!�E/�CRS���YWnm<�z|Q	�U�5��U�PҼNtT����3.�c9�h����,�9����̢9���&�谼8�V�K�I0����.�����cw��֢��<�R^�M�X�+��s8G�G�� i|x��r{;�<��jq�H��K�~�u�E'ueKa=j^�u�	�Zd��΍l�6z��1�0h ���֫<#	�?v`Uw�B>33o���2g���F��� ov ��;�`G���m�Bx���r8?^0��z�u&�ӃQ���t�� ڈ� ,�Ω.(f���ļ��K{\�A����I�1J���Mפ0H�;�:��7@5
ր�NFMݽ�DS�V�0���a�����w���n�V�W-$z���il��)l��'��c�x�w_8B���2߁���9��������a0?���,�m�51�?���EѼ��%�?��ć���;�� ���(-�0�+�����FE��0h�.$Ӄ�Z�c��bO=�u������V�m2F-?{z.@=�U��쏬���<��up*2!tG
�u�SIJ�����y�(���{���6����H���@��[��,������3|��7����oQ��W��b����_�}<��Zw��b�+Z�B�������f`�� %S�D Y�����3��ק��<>�8���Y7���0�}�ݔ@�I$�a�c�?�)�H�4���}����M��3(�;�������      `      x��|Ys�Ȓ�3���]"lV.�F���]Q݊�1/%�Db,��_��\�*�r��;�m�Q�%��ɓY8��a:�l�O��)��ż��E�*���u]>��a2���x6����(��4��=>�ئ�M[�=��T6��mg+z0��(E�Y��!?��E�\�Mӭ=xf���*��m-=�I�G'�Q�_i"�Fx/h�C�4����ֶ^֍�[���2�t�`�t:��+�� �hQW��~uYod�wuU�5Flk�{$�N�|�R����|2��eЭmp�ضXڪ�G\Z�*��T�bQ����ؽ��W���Eg�[[�`�����pL����]�'��xtg�o��e�T�[���˕i��"��A�4u�Z��,b�b*��d2�l��ü+��C�`+L)c����X����l��BD3Jc^M$��<Ν�0��(��;u����㠩��HQ:#�e_�8�HFZ7��}�d;+�!J��TK:�~c�}C�NYX,��2LS~�Ic�o���dv��d��ķM���;/��C�7�tySD�L�$�M��E�\��Ci"?y�cڝ9Fr��LS|(�}�\�}���/uC'��	�dϧ��ԅi��.�u���o�� OlUl�9�z�$Oh2	�+I�Ҵ���a�[�����ξ� X�M�4�b2���N/��nl��i6jQ�������S8�l<�g39�d�3��;�09��qpVT���ߙ<����ݬa��fX�5��Hs�͂�_X��Wg�i$�'C��d�X/E�]4��|n뇢j��59�y.���kۺѦ4�,���Mß�cH 182܈_�rƿWOU�Rd-�F�(��x(1!��=K���{pQ�OE��xZ��7��bm���w�f)`�Q��讱��aG�-�]�a���X�l+EO(d�������a����eed5�Ĺ�:ό	0�/�*�������F0�d[�	�C(/�����\
:��
 ''��������p&���p�ro���;�U������f!����b��ю9��2�/ͦug7���Gx��u�YX�{3�᢮���
(�_}�:�.,L��9����}�p����g�	?��!=�����:���9+ܓ�Lf;G�@���L`P5�8�FC��ȟ`��sX��źތ�(���n��V,�J���u�J�le[�iє	��^'�"��4堫�y����T yf7p w�d�S�+1�D�2ز~��w�A���)���AO|��_˶� dW�jM� ��0�!""�l���<�vkM㨎�n��x�t����Mטb���6�f�Y���KS9�Gɽ�*���iʣ�C�J1�F�{��â+$�s^&)J�S���\sN>Է��mi�%�j�K������`2`���~�d��J���N��n��A�
�R�0�i���F�Y"�Q^8Z�ﾰث����Q��� b��a�c5d�;ҩ��q�R��z�K��E�0���1��E����_8�C���T��zޘ��e3�S�6�q/�L���k�|����<[���)��x08뿖��Y1q��L|HPl�񦯛~�'��;p��#��0z��M�_z��]8��\�)��!�����wkA�/�8��T?�L8�˱aGAh+�P�z�`]Q�*��?y�������<l���﫢]o����+�@sB��>�b8
�H����}z�i�p�������u������fX걒�ci�/L�&R �����G��� .�v|���֭}�M�}�1�?jlݪ�^�촙�Qzؓ�)����nmޙ)�_�=�N�]O|::���b�sڮ�X��,ݚ�Q�����p�]���ރg�/���jJ0(w��!�Qp�S���Ҙ'���J;9�W��Lʐ̐Y��f��|��l$��)q�ǀ#\Ք#ށY?<��wRi� ��m!�"[��������Ÿo8<�%���Cg���K�u%nF� ~Ӫ��5���N_�n,^�ao�" Ts["%��w���#�+AǨ�%���l��ϐ��� w=������C'��@�BW"!�V����U�%ٔ��Bb�o�W<H#4"ǒ)#h{�%��5cR�LR�z�(��{j5~�y��3���	��>��1������o4��w���.��1jS�T��}l��^!�Z�`����q�I���a,�~^="����V \�}!)�0�āEs@��/�
��5���-eդ8�n0�jE[}�<�w�x80���d6�5��B�;�8�D��O�"��d]�P�8L�hQ�uǒ�������ࠀÀ��r��3��O�}=���_#+Lq5I%W]"���h���4�}�b)�Dl�o	=��7�<_�!<4睈�r���<�r�5��Ĳ�#�z߽�_���f��b�X���'4����J�;ұ�V��ΟM��y�ECvJa���Ӡ���PX�bq<��@�2a�Gp
 ���hA��*K��ǛI�"�%��׋�#���90�p�5@�#�|܁�&��h� u�B#��t�*;�),��&/h\b��ܠⓉd�H�-��l $��1�/j����@�l/6U.!z ����RA2i�k$r��rL�ؐ���� C�^۷)��c��!Ӻ��bwk�ғm�]�pO�b�O}�\��1)�m���o�f��G��Y"M��ž�Ag�?��<���O�,$�O�-h,�=�?��!�� n�xn���{؁����F�c�R<�\�=Q$ÔT��!R�	����anz�3�[p)Y ��x(ʢ{�(��MH<S5N�#���"�X1@��(���z�	�7��I����Ϋ��m%�w�A�I�Ҥ3�D	��m��)x�&pcz�am�u��I�OW?� k�l�	��3��h8�r�>�(Isy��}�*���ÔQ/7��ԩ�	��1y_�d|]��=��2;ї�JJ��M�l%� r�ş�8*M~y�J&�|/��%i��!�,��p'N���Q(A�yU��� i���W�~��$�35�	��5]�/�G!x47�t�h8_85]���{2�듢��0���[�D���0f+��QU�GI�D�,ۑ�(K<þmL��e-D(���w/u������KuI�Qz&��,�tMQ�+����5:y���N�T�hEb���3�����o���ũ��G��7EN��3��!� �ē�ns8�8�R� ����@$� �`�da@*R��=93/O~��nк��)a8�+;��
[��zZ+S��׋�¥�Cĺ9?>4�ޓ�H��iK���O6���>����òp$���:ߙ ���)sEFN,[(�$��n]�q �F����BE���Z)�t�_�̞
�%����ظf�&��W'���!� 9�+7o�3	%A�C��E���]�!��<("C���E_��a��?Qx�D<��^�oW�c��߾j�VD�b\���͏�+2����xd����9�G1�~I�ɫ���Vv�ڋ�^�MI���Q��E������>zFR�e�L��tt�٘w��Ҵ��]�Q��ovE�E��W�`�����%�a�0��C��Ƨq�����/j�����4jPZμ'I�O�
bL�F�TV�,�F��`S�?~�%�ۆ�����%U�F�Ob|e	J����|�|F����¨�Y�ICX�	R(	��k�C��^���ݡ6�CD4׵H�<ƾ߿��*�DS9UJN��o�
)�pJ�qٮ�&�$	��#<�l 	;1�3�+�r��nmry��-�߳H-E<�to
��#�v�f�� �Y�&�^�"��0�z	"���Y#�1uA�E�/S�%U��fd���S�#D�{޻?�3�t��ټ��p�Ʌ��L�S��(���{�eW��L}̕RW�W�d�ԩHl��+��k�����b)b�I�~���(7��C�єj!�u�h�����A��m�c_,���@H�<M�+���G)UD�
�lHLصQ���! ��kQ���Uv%�0�k�D�D��C�5ϩV�buX|��˰A���m�h#8�)    �zލ��W1o�;�D@�W:Y�Y�BY��ʳ�h�F9S��g�c�c�vR��v��wT��gƱ$3�I�j�xt�c��kj��1�YWE�(`�*z���w���ZE��>.a��[̑��44	�
�t
�Ѽ�22l�"L�]�f�W��*Z�5�P��.O&�@*E�?�
D���&)g`��%�h��y/[	E�r�H���mp\���^��#��\E��x"F�d��>R��9̇�1�۱}����߯�F�2��AM8�xt��>��;�.@s;O��J%��8�%������������H�+KD���5��C<x���4?���	vrP����T�ew$��xu+Q��S�"̀�V�][$�����]����A����[r8q=DJt�Ɉ����1ux�6���4`�%C�k::�p	J�^}�y�h�h�̕�2 9��"R���_bsH�Di����S���D�n6&.�Cj��8"�,���T�v>��,Lx��zYPFS��g)�Ng����˺_R�|�;.��e�S,�ؓ���ߙ\�W��[���hW�gc�ύЖrhD8��sٯ�/|���ԗ�l=v�I�C�t$-U�8C�m�il�]�,`�`��G$Ԯ�~��,K���W�x7�C<^��Q��#T�2y�콍���C/1OF�ղo��X����j�
��0�d�h<�� �g>e��`���x��-u���q�?'8�&>�%>�Fr<-�O����ג�uĩ{ Om�덭�V�9?���M�S�*_�"�b�q��̔�r�Z��P����x��t��%oC)�OEQ6Au�QPZ0m�{�鮓�>�Be�R�+*] ��Z�6q
W8�Zi^����0�]��?ԖL��}i�
�(DjT6�u6D��`NĻ4���������7���p@RU�-��y��aܯ_���{వ����|5�`+��LL��~ݕ���Y��nr0�E�,����f^�Z܏�Ք�Q����C+<4H_��HDV�>TPmfם��B���quӗ��%gJl%6M��y�C�N_k��&#N��_�i7��@svֱWҏbX��xԨ���\�:%J%������S���9�,�U�-�e�=��yA
��༈=��[/����J�����.��m���,�R�+�P?��ޓ�<���n��>)�w����w=�mg�Ӎ��.�%���4�ڣ�eQw�4�b�f�/z�
�'j�:BD/���YA#�7D72�۾]/�c�3�I�;2��e�������$�\���F\�Q<+���]�1wzž����E�O5�k������x��g;�Ej�;hF�}e�Y��-��/�[_SV���v^���6!�V�G���,� K ��ƒ�I"Jg��J��ꦄ��fv��+
��
2�8]�2�X�N=]W��/��	�j��E�������iȭ��x�p��u�Q�r/La���3���E���bQX�2B��詾{�d1��%�I��X I�+|�[dSϱb�?uE&�m�U<cZ�Yj�]Z�+�Տ��+l���Ec�U,��w*7��L��f�o�QZ�h�
����1���4L�4,'3i�b��d���.���HX`&��0.��v
p@��E@nQּP8h�F���0�R���z/�I]U�P\2��G��)�k�X���7�>u������<'^mF�'���E͊�K@l��zS7�6��ǯ��ڬS�'^I4�{G�pJ�~��u#�K���$�]����C �E��<�{.FV�]\�5�����{�O$+V�^�r�E?yB:�H��C�IK�)���͹9N�,���~ <[�Q�B�t���Z������M=5.�J���}p��؁ahy�p��ܓd���SP���V�x�j��00�0�_pd��Q\�u���_��%���ޗcc���C
���KO@uM]zOE�F�ke����{�i#�w�O��"�d�$>.i�FRcBj�G���q�z�Z�G�z��3�u=m���9d�f�$�R����v� u��g�3��?ok�>KM�$,k�9�f��yLG�,��k�e�«]�0h�m۷Ji<���q�����.�,��ݥ��m���|^-�f�-M�c�lX������?'E���i���S�X�Ц&�}Фas���nj?��r��3c�A�[S>wk�
@�vx�K���^�;e՛��A�^�����bɮ��_r��!�W�W(%{����=�Q'~�IL��>�K����葛TRCzt8��5R˫]�/���R���=Z��d���J���ENg����c��{�M\���V��&H\:V��*�~��=�=�q1Lo	���ݑy���G*X�������#���&���<[���ྻ3t�{dY������u���"/��D��;��R䣪o<l�1�=�R�ٶnvS8��d�;��\d�casR�����o! -��)��;PmdCm�M�\1F�~�v��2},�����4�)�*!ko�{������9NvMRN�����/�`�V ����otHVm��2l�_�wo�3bI��}�8&@W[�5#��2\�jf�����jI�AmN6� �$f/���L�L����G�ѩ��&�Y�E�|N���B��b����Q
�򤡊(e��и�%��Ĥ�=�x���= %<�j���9\�^����SAJ1qP�����VS}�2�O�i:ѕ��7'��r
Z��^���u<�$�8�;G�-@���}�%�pzZ�?]7Ū�������T㽬!��*�J�,��\�+[Q��y{�Dt�ᰧ���2UN׆���U��&ٕLo�1h�d�9��[!<{�\�
�N�I� �ٵK�?�6m�X��u����:/l�ɥ�4�$�a���0L����"��i(/�%��]�x����K���y��e0S���]Y���dt	�U/knУc���'+�	{Sw�"�ƭ���2d���-0Ə�G�R�����.u������,Eכ��<��CcF�Oe<!#���Ǝ��3E�I�G��e
p���,��O�a�?شA/��}y#�~��󞢘��储����N5���kG=��ȷ�Fhg*\X�[��a��w�0s}�r5�U�'���wi^�6�	�\y����m�/ .`���\���٘[�C�:�$z�����`o���t"�N�?�.���,\�"�T�5��@Up�t�rK��.+��S,��}N�S�XE��v�Qԃ�D���N�+^_���_-��8��w��Ip|uz1�:�
�3)ݸ�`�$s��(��x�����l6vY�O���E-��Ũ̻�O�I�/����������ޒ���50��ܝXp��pC߇�r'���Xbb��Oc�rC��O�h���PC��`���F�"�܍���i!�E���S���R��0��70{�>�VC�ZNB:���2{ �Ҭ̷�� �;c�3�1�waK���N�*���.r���`$q��h�\ +���C� ����-Ř+�̪1���#��Mk�h��>��m�o�(.�qO�K(8B�f,�~�f�X�t6:��׼�����V՞gƜ���s����^�`��}G����)���,]��{i�k�]4���aX x�("W$��{3�`6ra���'�A$�g�OIf�k�.��U�>/8>�l�Oѧ��6H�+"�;���ҵ:���_=�w����*�:��z�w��f�V���Ꙫ^��*��?��F1^G{���Z�$8��3��]�%֋&7%u�C�۵���N\�В��;	���y�Q�S���-���$T�M�a��
''%���Y����S]��J���^A#�n �6U�f%x��*�K~�T��K��ϣ��$�z��I�
����^W�j��e%�3U�sJ�.-�N"�=w6_Wdd���՚�N�Л��;
���X�׽���~�7o�
�$#)�O��	B٩���I�LѾ�Un"��(�2������:*ߧ�����sui_��^�?	I��4c�
�C�E��_
Jr�L�ٜyr;h���9$ �7[��� [  �Tz\]>�嗼�hҁwRO�MT���7�ջu��I��w�#$oS�#�S.�C�x�HǛm�x��RlI�&�~w���ǋ��Ix�~9�����=;�.'�`_RH��%Gf�K���5O��?8}�-�K����I"R�K�u5Ъ��dMٹv��,�Z��ucWu�'r{������~�Z{�ﮈC㩛uQ�t'�u�oY�o����*.uO���=��otBF�����핰	���/����4pP�UoV�qs_�7�&Z�x3�-�8�G�h���Ѥ�~�V��[�T�:��(�W��ϯ��=OE���B�~].?k��)���	U4���'�L��� �}��x�۵�An)$z����#�tdj�~���tA�#I� ,�^�/��ew�Z-�}Ϡ[S	ه��z������81���P�iO(4�_�/_���>�멩��{0���#B�!ʃ@�ve��'^R��`�����m��ػ�� �7͇�I�m����c�>�w)�P1�v��*,��g��A�?�7ۛw��%q5�Xv�]�Im	7��R/���	��Hy�;L�$'�ep���d��;��z��mc�BR7���¼��1�T�U����:��Q��skjj8$Ccu�m����k;O�����XY'PA�#�'��%ZJ8�ل�]��
l�0���D|�Eo�Ύ(A�\����U�N�G»%2N��S,˽�z�X����m�O�����e��7��pJr?rWS_�9�޾�D��_$�ˋ˦���1@elﮠk�{���I*�Y�\[���E�=�<o��'�$�ߛY�Q��>B��"�v]#qE�?�_��-7g�`y:�����g�i�]9K�3-�
�"�Z�}�O�U�7tM��b?֑�;�֢H��&I��V��CIv%������{ɗ���� G���Q>@���<���! ��>���P���ׄ�W�do�� ���x$X�/u�u�~0x���5�/dt�ϩ���^"�OA4���|��Dz�̕��jR���]3Ј��(P�޸�r�%�Ҽ��M+��:�`�6!�.���ל����Ū{R�:��y`�k+�~�U�tk����L��&ⴟC���T�Iw�AJ`��+�Z��W�ESW���͖.I��G^�1��j�$ӏ�֠ՎTT;1a�$Ҷ��wb�[�D���*�I�WeS��l �>�v�ϗ���Ovƚ�Nɢ��B��?���-s��a*��%!�pW``}M�₮�5���|�ٲ�I���R���5�������*�N�� ��kH�����&�:��4N�ovq����y�8��/|_l8�ߓ�d�v��)��b�!}�
�vk�MQu���X�u=f ��6���~�p����W���젹�J(`�q�@�Ā���rK{��x���/_JI}!b<���}��Z赽��g��u;Ћ����V�1fYæ?nA?t�����M�'�~@x��qI���f�Y#��p�Q8�$��c엱�̳�@��<�;!��#[os3^����-��'u&�̃�����6�}OD��v�ѧ�U�BF��Ͳ�k�A����/R$8�!���Ԃ�q��b�K�c��z��g�.��W�� ������7��Z��Ю�(��cdɳ�������2����>`�%'�D�����m���Q�q;S���62������f�������}d�N�/^�Ĥ-ۋ��ptd���n�ݙ��3�|������ �]�K`�z`�+�;G?�~e���F�l��"�~�N���y�|��55�o�il�]-2�o;M��H��%��яa�s�1r))&���U����|%�<]�j���V)5x��x<�zi��s�j�v��o���o���3�y�      d   (  x�u���7E��	DJ3#�n��u�Ap���;����9R��#��HR����o�-���x����|��ǧ�OA>�nԧ ;�hOA��v����P�5���Z�S��'��ǩG��Q�yl+��GN~��V 8���M�E�Ŗ�`~Q5�S���yꑴGJ���M��d��P���ǧ8
��N�,�cKjՁ�)�M�C�*V�ڂʚC�*���s4����䃴yK	8��.�ۤy�)iҼq(k�mo��6o�9�+�;&�N�k`�M6?���Լ��M�=9ԩy��m�>Wuj����@6(�u .W�,w��;N��sXp���v����W��]~>��~��R��48������=<�*F�c[���x�v�J�쑈����]>8�B�8�`_��.�w(طE�髸�e�'�m	�EAGt(A65V5�?6
K��Cl0�P,a�c�R�(M ��� ���%����=���C��obX�y)XH��C$���(�s�'�8�X�6�8�p!ġ�����B�S�!�In{����'|!��p�H9�mU$�=|i>8�5�#E�
�
�]��pQ����is�HK!("~��h�8�"Ē�
=�рzk9���+(�QA�3r����#(� ����7&z�D���9LK<>�% N������+��Q4�h��G��
�s���-e�@`@s�Re�-M�hi��nB������Dӊ�
2g�� Zz��]�쌺6.�¶�9�s���n�U1��8��CD����M<JD���=��.�͙�$|PD�D��@D���DdO�rN2a"�&v�>e��^���&2�`w������D���j��d䜩C��BW�p�v1\0���&�z���c�sT��@�Y���L�Wx���M�4xM��IDN}N.�bV�0~`�˾ۃW�w?O���5H�WN&�sf�sHM�W��eZ���������áTM Ȥ���.�*(���(d�xrm
���H�W
b ��2�/
��9�Zs�a����&�u7
�f�BI�/�L������u7
��4x S��ܥ���k����@��\`A�B)�"Y��*�)�b"�W2�+?)�b� �W�������F�0�E�_=��] �;N��ӊ��!C|Uy��W�|wiIA_���@�y��C��*����R|Ŵ��x��J�]�/`m����I��$��sh�����C���٠��9��	��|��^����Wș�+T�)�b]�n�?��v�|�s5\Gq�6G�_�����L|�K�_M\M|4m8���lZX�N:^�l���co�\���|�P�G��A߫b/�:Ԭ�E}$}3C�0q�,lʺ����|5	�|ፉ �n�8�
�m89�*�q�c���/_(pϒ�gw�@	���-y5�VͳI��0��R�����3��9�qw7o;� �3'.@�Iܫ]�0j���;��h���/�7��7X�������i���{�lf�KKf�ȃ�η�" ҫ�}QW��:�|EX��2��d�����y�� n��nx'}��jM�K2L>V�m��}|cB�v���K�^�jwy���W[���{��1:�'����Yr�k����{�.�x��h��+¶�9�{ lM�*�́����igO<|�9,����}N}��e�s���}c�.Ļ7�	�W����OU h~r���|��C]��1�# �� 2��ݵ`�
i�\��ቻQpw����ـ���'���;�Z�w,�p�����L��m�QjS�\���Ǐ�����Oa��F��~yI�/f�����7��k���Y�o���G+�?������h���"�ןf��������@X���He�ן�ݻ������C����~秢��jvH�̏�K�z�7��>���Pe�E-~_��u��G:V�?xlB�fA{��x+��4/I_J%Z�ٟ�I|�����d,���Ņ_��XJr)�KI[J���:�>BK�K�����|4O_LsEsV}p�R�pfH^/��b�M����щWG�����yt_�������>�      c   <  x��\M�%��]?�_:X�-���&�E/��MH�=Г����%U��J���&<V���ב�|�b���%�@��������A>�����篿||��Ǐ����������N�p��'�Ə?���߾�����N������).���p�����X���&���3%�g�<^��������q���;^�wȫoFj�:��d3o�OV*�7�;/��/�ǋ�����𮶊j����q�jcS�v�M�l/:�0�B���y71��Bb�.$��.��MN!��95�ϩ��<nr��������Q�)�% ����������.$�B*�O���:O�T � ��n.]H�B��TTvG��9��	�]H�n�h�� ���bW�zH������
1���t�2u����u���jb�ϑu�d���%�DxNw>�7q�����THqq���-H��:��󵮓w~cI���W����F�W7 [)�f��}n��Cv�H�a �ĳ[PͻN$��i'l��hh�����$9Ȗ�6lB�?c���uB
6�qOnBjħ�
Q�r
	]=�'B��R�B�g��+�b-YV�=��(�B�&�QB9���}��nm7qQ�Q�:���trEl�z��Ŋ+pb�~�NI`�� �)�Y�4�~���Fn(`El�ڭ[��s�^�f����T;N�;���"�Hu��C�N�u��Ժb�{L� ĒW����D �7�� bc�B<�#�Ԭ��]�r��|�"�hPjɽ	<Ǎ�� 'D�Ԃz�}�鰏��S����>��IT��=<��w�@n�cld��J^��Q�����D�	=*bc�r+z7���9�ز�������u\/�b87�X [uq�aoŰVJ�t�����N������~���M۟��žb���ZQ�����&El�� b�M����+��r}Nn�31j׋S��Q�R�nLc��gb�2P�	P�6��c;`�!��U�"U��G���@~�	(P1r�(B�F��\䛀�o(nz`0
_X_��'dty�b^�*@�4A%7�c»������z�/�	`�x0	J��J�t��U%�N���H�hj�\�w%Z��N
����^�$��r�����r&����9>����x��F�q��d��vyu^p��`/�F��~�9�4�'T�'��[�ʮ�x�">�����`��V�B�<pqS�+S��''��M�1���H�3f�H�:T�'�B%�*41.�"��+$u�Y���Wl����x��ԷNQŊf�ڃ �,A��ת8�T��J�zB4ʗ8f��x*�Y��U��?�}��$�{c����)ī_Lm�	5�$D
̫_F��F������q��j�oG,'����А�IP,����fў>2m��
�*c���H~����Oť!�Wjw��|Q�N�{B����yY���YgH�$3�4 �V�YlՎ*Ce�M^��@�M�6�cq@ 0�. 8l��A"�JLxy�W����P4ߋ<�/
��GZ�����/� ��H���@��Q�W���[%�kuK�ʷ�@���[�#�Ơ��7��}+tK�(&�Ш�p�Zp�XJ��g�.��/\Zb�8v_W	J�^3��+X���~N��@��Eb��&�\O�'3*��+� @JO7� �F�P��d�Ԍ`�>a���ZYT5[qw���i(M ^M�yHZ�`F+��V��K���X#&���3��B}��Sv^\�Z���R\Liu��
L2�SRy��j(k��?~���ZI_��43S�	���X�}X�0� +�?\*�FI� �`���F�Up�r$<<	nq���ר ��[\��O���R�q� �U�i�OLJˀ�
^���+��r�A =ђ�8:��I<4�
�T���O�fþ�*�O��`C�F���0L�1	ȍnƌM�	Jy����lGAm��x��t!gza�NdCg�����������&up?���S�_��5�x�M8~F~E��qrΞ�6���Wl���m�/�N?ޠyc`"Pq�q�|h�d0,^����6�֜�{z�������l��- ��TP���4Ryf���d���}�!i��jSY]�#�� O���-����O�}�a�l��Z�j�f��Θ�Y�K�i;�1N����;���h	��KSG�y�X��D�z��v�%��^���	x��K�#=!;J�[)ѩ�lj�3+��!R�{V��YT�����X���fJ�ƮɦW�Q����r�[|���4Q�k���R'�/�W�<���$Oq�+NO����tzJIF"i��0/��hz�hE�z�z���ըPQ��N]�h�1pu��9�8�'��,�J�u�����yV0��آhw�<yZ��Η<�z�QO)@����Lm�0�er��cO�����spl�tu�!48V�2NL���AP�D�V��8�T��}r���6G�mF"��-�X^7�����v�`�%3Y���u@��'�2IN��Pu���Fa4��|�6NrCeOk��;&`1�{���e���-+��V���	Ɠ�lx����KH��nv� ���c�2?�PCpO��Z�lx�������߭Xӥ������m��~l�s$.��l���` �!���7�k�$àa��t^��o���c�P���-�6�th�'��Z����p#j�iT<���C�37|�9"Ƶao`v:C�ș?E&[=�9E*�m��I(�(S�~ֶ��?a���h8�����V��Χy��Y�0��+e6�B��:����#0�Y��Ō��j-�[��`��f"�ݝq{av�}���k��La�^�{>�*����ځ1��`-��Tn~��N����e��˛Ѳ�s[��v��]]й������i\3����f7��q��zv����f�o�Z��_�z?�y�w�IA���i�%s��4�f�c+�?�
��m)"ۖ��<�K7���W���)R��`��^[����1��{%�ؖ'_�!���c-��]�JK��R������v�g� cW3���F�ذ�<;M0�-X;L�m\��c¾Ŧ�\G������lMI�g}ί�ߝ�Kލ�����`I~�"�h.#�`{ Y�����U�V�y�b�5�%G �f��82e�7�ꂽ��$�7h-,��d�H���Ov�ư��b����7������2�I��/I���e��Ƙ:?=̺��DS��a���żv��#��#�9�璊?�=�Ϋ�c[��D�������P�Lqn��vsW�Vz�:�7N"��i����qH��y�#]����i[�H�ز�ZT̡Ҡ�]�k�W��-��[�7��"�y�^��ɖ���g݋U�m5�y˰��>"7�<
xI\њ� ��Fś/�;�D��^[��R���Km���O�%��G[9�94B�����A��!�.�<#�����	��}�����=7{'� ��P��(Y�?�d���X!c�;���{U�?�yD����Q��E�����l�N?�6�)��p~tu$P�zd��^�����'�~���>}����d      Z      x�m�[s��ş�O���Ӱ��[t��辖U����9��v.R�O��AJ�W��b�	����4p�WY��MC�[�_��M���������z�����[߮:�5���q�L�ˢ�΋�]��v��*��}i���a��*�����}�7]7[v��n)t�����B��>�[��Z��*JWT�#D�����N��i�v����?��ۺiҠ"*�Ao|��}G�.|���C�K
^Ҳ���ʔE)+ή�Kh�A�a�CSU����n�Ǖi\�Ǖ�{�U_/_����](���LYU�j]p+Kvֽ������-�|�:̯�׍o�H�4���+��2��i��vz�w<.�0[:YHr!�3t,c������v:�c=�����M7�\��u\ggu�Z�(J]��im�Bs�
a+��C;�e�x���7������GmҨ&�j��o}�n��ͮ�3�8cCA���;D���ێj�]y�]�;l�p6g�	7�7����j��Xi�X�(�Xfe�dO��\����o�7��U�4���:��f۱�Yw��K��:.��e���R�Z��Ү]����e_VJdG��$,~��ŏ���<��7���4�b�[�iQ�w����rֵ��?�w�|3e�Y�#�ŧ]?n��X��:dR%5���a�R�<��n`u@l������9�8q�υo@H�P_��T��JK�,e)�*�RT���l�D��a�\���};��q�	W�@]��|�ԡY�ґ�S�D���!����@��VS�_��ηN�S^�W\ƴ����
^��
�;Z��
v��a�<��_͞����JJ����9�8��x~�t�W:n�,�il���Ja
d�`O����-����G�G��/O!�sHq��o���~�"�!��3]YS��R���b����o`ٶkWG��Ԏ;lY�S.�c�Ҋ��D��n��b��v܄z�� b)�%mB
�����=���nv���w6[z�.���۸���gM�)��m��s�5J����(W��{����n�4x
0���X��밥�8\�Y
t䶪�N�5�j,̮w�r�%���Uʯ*�WE���}�w�^~(Z38�B#ɵ*��]���	�1�¿�J�J�U���_���FT3�G,��	��Ҭ�h����=N}ӡC��t4��n�lo�ҫ��U� ��_?�7�2��4�:(��ЅՈ����IO�Zط��t �3i�^UN������m����ԾPdG��C�AyTҀ#V�Gj�~�LX����O�5�V�c��QS����ϱ�bO(P�yTUBhq�����0��a	y7$���LiU崪ԾB�v�x�T��Y1U"�ǁrk$����+v7,}?��K��"�RZU9�*�U�X�cJ��*��[G����]�%��1�L;?�e�.5�T�C�"H]y	�����f�3����"^*��*�P��r;���y�R4U9�*�Y�jv���b��D�����$nN�	,��q���]��Iʦ4�rU��\��j�D*�R�Aqn`H4w��HaȊ��G��!VC�m�9H�)R�G�p�Xo�;2'�ЬF��x�h�8JQX��P�%��2���	;��� sI%R&��I����B]�7/{Ŋ�Z�	�@�Wt��ۈ�1h�l�HY$r��U�`�/hEJ
ص��YF�,�)�V��<��*_b
!�CH���F�M~�b�H9��� �,���#���x�s�pj�B)�D�!�!��G�G�V��j�nq��5`�ƣ{��}�];�j�B��DJ#��H�7��K|�aU4=�_ǩ��X�$G�����//��~�P�RS��D�Ht�v�p��0�塋��X����֜��u��O�|���ũ�$9�D$i��*bIY�*�qC~�ܰ(
�R�PG�V�/�wh�tsS��F"����##���z���-�hA�\�tP����`��Qi)�DN$AD��7!l�y"� E�FP��S��x���{�nuE�6����JË7)e�%�sI�N�~�>�?$����d
ZR�q�#h�����s�4f�$�3I��8��J�\�Q�=P_h�c&���?��V��Բ�U�אLd;~�d��I�x�q �R��D	����($i��D�����Erc)S2ɜL����a��˟vpy-�;�3�	�EXE��딃�ޱ#��g��'o<��N2��$:�OkVP��n�E?�@đ�����[�H�`цۊ]P&G�'�%P���ߣkM�)�d�+��b�
��^k�HE���=��9�e�M;�|籛�� ��v$Srɜ\��u���	��8>�ס�l���.�/����> ^{��/����[n�L�AJ1�SLŠ�v?�3���ı�����
9���-��*3��*�L� �6��"�.�˴دx�"Ђ%���մ4A{������1�1����o��KQ&s�I�[�5L�Y�k�g��a#�u!�H����P���+?<O��*ŗ���S��>��Vܮ�asV�-F���qM:��Jc �s�mMs�4�UJ0�LE�׵� ���VqjÙ�pAFK�q�s��(�[�
������Q�(S9���z8`��M��"+ĸ%�� q]a��a�軗ptOSvBi���O]��yJ5�SMվ�j��m-���E&Z"V����@�@?#�׈|C#�g?;;3�S)�T�6Eh��V����q�����$M���!����x!Ѝ$�&h�ѦPU)�TN2E$�3N�`�F�2j��c�BS;aQ��A�L���_�z����S���c*���9т6���ZvE�V�B�d@�1d�k������ؓ:�yS)�T�/e�%���p� ���1�d�A�I�����:tU�U
/��K��SU����,�0C5-��a��f��N �j���z���/�:ŗ��_w�~��ǡF~c�?S��1D���	w�~���a:E���	a'p-��+t��a6GcA(0�c�0/ڔ	z=Ӑ�<�� ���>�c:��q~�
�:.�����2^Io�oA���`_] ���h�=����#���9�4��	��%a�2Bq�ԯ���8���^��gݴ�]O�n����<v
0�L�8X��.<CE=n���8#ơE�u!�_sz	Æ��m���]�	�t
/��K������;2�&�?m�#�i�|�#Z�ptJ}����W��W���9�4!�֯���nZ���[�xEf��A;~�ܖ�A;R�nN�?��t�)�t�,�?������=�(����2�� ,���q���	�NI�sRio۽�7m	��V��!�	熈���������~�N`���}��D��gT
.��K����x�c���D��P<J��i��^����k�~~���)�tN,/���8��XG}gNs,]фҒ3��?:G��B\t�?�S~q�dRr��\&zG�oC�����o�5c����BZA�Ct��x����4���'�?xz��iD�d&ŗ��exT"a�c���C���1��l��:֠=]tȍ��5k��*Dz�nRt�]������G�f?@��4a��K�/��a�U�y�Xj�4.ow.�}&E���eġC����I��XZ��i+�p�x�O�vʽ�M� LJ,����s�%JG���Rn�'14/�T��&?���{Z��K3ԡJ�!&e�əe�w�oh�!^��Q��'F%@�d�UU�s`�d��r���ր <�M&��ye���}�����,�cJ@�HR�R���"�7h��y�)fO�H�٤ׂ&���e\cx���L�/'��4 0�@�>A�<�M���� 陔W&�!^ŗ'=�T�&�x�#ţэ�E��T/�P�z���.|���)�L,/�w������j}_*Y��*�A��x���x��G����9���צ��9�l������_���A/�P.��+Rvz㡛p��Ly�}�K(-x�w�|
bSRٜT�Hu�aG��u���P�J�4��al�mx?�c�� W��#X���o����S`�X6N���}�N���%@�$m���C�آu��7Ȭ ������ 6  UJK���Ĳ"�(�ͮ�1��s�y�kd77-����BZ��c���z;3�v��M�esj�=���//L��1Pg"�t8N�<�p�85�T�u3���L�eshY���Z�QK�mQ���8��@HzЀ�<t=6�V�<�RZٜV�h�-L0�^~�%�8�*H���4ӠzG_��]��}�D�rH�צ��9���X��r?e!$��)G3,�!�|.r�3şl�<)�l�)�\y�hw���0�%�˰�$�q�B�H��~�?{��!O�Q6G��7���eg�����$Av�U�u��j�U�ӝ������g�t��RP�T���4h�K�;��/����������Bm�M==����9K_M��O.��דW���eM>A���\�M,:>�mXb���hn��K��r$����w��=�ό;�n�Z���C�c�Pk[�zړ�^���KY�r9��.p�����K�Dz�U�7@
�7?�����O~��R��D�Ht���U�f���Hf��JK�(�Eu~��Ǣ�zcR/�R�F.��{�N)-��I$f�+P�V�驕��d��#@�m|}:.76��H.�# Ł.�U����@����,!׾�a<��b���K�Ü*]m
%�Cə8$C��~��|�G���L.r
��ֺ/TR�"Չ.%�ˉ��w��o�u���/X�8RV�
uR���n�'CT�7uC͛gǙ���<rq*�ǜ�fA�Wc�^�X���m� I������fW]x}M���D�$,�h<<���MR�8N�5��k3GWt~#-��������I�?����~������)�      _   �  x�eS�n�0<�_�[O-l�y�l�.�)��ǽ����@� ��ʒӪ�͜!�9�TUU�3��*6ề?�I��,c�`���(b��+�\��M`��\J�U���=���ve�-?0葎�^剌�T��]��:2��+XzG�H�O]�j�^��cFOd�65��ndZX��R;o�z=��(�w�c��b/�#E�T1�'��=b

������rG�5.�5�I��/���5�cJ����M���H}go96H��a}"��pX�Tx@�*&�h-O���4=LvB���������^����<��a�ȭ�"�S@����J\�$�:[̛�yX�u��s��ba�Y�#*��Lg�G��I�.���4����Qc�s�=^�������X~�G}FC�{��ʹ����6��Z"�9n�m���{x]�(��$I
�      [      x��}�v�H��3�+�V3� n���n�Ӓl�����+D�"R �I;鯟�O���bT�Z�mU9�[Ďs�{��5�_�������8���T�.��~Xf7��e_�f��n2��z��3i2!s����+�]���z�ض�/�=�gBΤ�_7���~ی��4���m�߆qծ��]�`�ݰ�>�~;���h��Lԅ��~O&��g��5�`Dveǡ��?��:��0D�T9_��5����.��4��Vٽݽ4�mۯ���Y�Y^�D�բ*g�53ڔ�հi�vi�yLw�"Wo���%��.�;�=]��cv;�ϛ���5]���*U-gZ�L�������q?.������y��!�,~�e_��l��{��{3f���9�����u>��L�LѵgJ*A���������v�~�{~n_��Z�O��2�߂�[8����f�f�l����Z� �2�E)f��7ь��]\t����ă��*�*���]���g_�am�/���n�5�Z�J63Yf�Uյ�����_zj��QU�uxi_Zӥ/�c����˗��n,�i\��U�!˜��,�k%t��ޏ�/>����%��&����k�_;�j7툗��Њ[�����>�]�Ş�y}Ya$=���Y)L�]��We��t^��/�M|c�]���Î�rv�l^���=���Ri3S�9���r�N�</����J����x�W<�w�{z�m?`� ��:�gJi�����:��ٯ;��"�y���U|튮}��m���uiK}�����Ӗ҄Z��U��YUU��w�u�ux�:�lM����E(D_u��Ov��w=?�H?���i_�>��5V�Z���E�����5��a��c-�~�"n�~o�~�1Ln�!�m6�7Aל�ڗ_���ׄc�4���k��\;�/��"D0#��S�ھ�EM/���?n�znp���`.k3ӵQ
:C���"��E�Z"F-�P�ov�����ҷ=�_���S�Wݚ���*+ft��Ú������]&.B���K �>��r�n�?lG���nwg�~���pYa��B�Y������>�ڮ����e�G��K��% _���葿|��Ռ[�������
�-ct��tb���U�*��:[։��K��% _���{��kh�_����q~��%�=+=u]�jS�t[���_�~x��u�C�Ð�Ð�{z{�����G�G.�ݺk��OLe͸��+EwP���[r~k�x���!���D�^:h�ݭ��o�/���vw��¢Cl0��@Ur_��/!D l� &��CT1����'��a��N�uv����v@�½�� M

PdA�VUҡa�$^y�h"F4Q�9i���M�ψ�*Łf���.]i��Ω;<l?����aee2�2�P6t-����{
�����,�P ,kM�Z�K��V�97vey��e�f2F3	4�K�5/��W��k>�	DT�+�����9�����Y�VL-1"��M��5�fl�!�n���~�����ӂʳ�2i��%�:"�x��d�d�D���<��R@�?|S����.�E�hQ�z�њ�x��������L>lb21	��?�UF�^��w^;<k!y9S�'����`�P�]w?�f~�� 5���C�8&c��-�Qd�~8зk��a�[���;�,:s	��%}eDE��wm� l��MG�*q!���$��k;>���B���W=۳w������5m4�
��=�����i���~%?@h24Yr����ؾ��-���C`�N]����� �W�U��Y�)K8F�%��!���$��z��5E��匇�[1<8erf��v
�	XW����k��&cH���k$������8%[t�g��%cxI�s�h�+:<i�g�vOۣ1���jl4�\?R�N�Z�،����'��%�n��#Z�H�*]���]ܴ#��&e*Q���R��dߚ5��]k7--���3���׳B"� ^4}X����W*U!��F`�#���-��OZd��a�x-���3SiA+LK
��� l�P78}�BU�
zozջ_[ʬ(��6g˚�J�q�C���3Z����*�x�!��6�{N�cӵXL���:z���n�s,� ��J҃��ME�e�;_��F��6V!��Gp�Ӂ2�fOL1�%��θ��3-�,z�tdJ�z�M�$�v����S1xvͦ�9�X�����q�D4JWu�ʢ��,���KE�(m��7��&�4U�
�yI�(&��wݰ^g߆a�c^
7�Y)J:�r�:� �v�����W"���R)q���@��~{���G���6����~.u��k�7v�˱!�M<x�*LUq�N�tK����K�͟;�B��
9UVV��K�I*�=F�@���uC�T1X*�処kh9ѡ�m:��6����D�Mg�DY�^mP��8W�G*��u_:�/�?�M���}�0k�4����Q�̔Px��"����l�N/n���QKJ6�cPJ< ,�lO9�c�uR�]aa�)fZM�����B��������C��1ti_���S���־���o����:��"!ZU�X5�N���um�:����t�_���֮������HP�r�w˂a�MYl��}( ��aK���_�=�ުJ<q]:�.��p�'�@��DLˮ卌qFi6!5]W��kQ���i�������{ڇ�g1L�����/���[.m���u&���ta謢�E���Z%QL�(��b�]��t\4�'���vW��2S�S%�B�ػl��.�!|��tɹT�k�	�h��O[��igo}�@�rA`];i��7����W8�h��t�]��"�8�!ڻo)�@�Kܮ ��
��E)�Ě�v�`3��B��1~i��7���m�%�ۭ~����%n<,�_�R� ��QS�r�o_�Ѝl�|v"���0�ّ��̗V(:�Z��9YJʤuE)�B���Q�^���+�@fb 3 ��u3����#�f�'�n�
T��L:?(�,�Ш5�"ו�w��(;�&D3���|�rl��ott�!�k��ܷ�`!$*y��^e��ߗZ'���� �:hO7�F]�O����i�kTHLM�P��)�uk�J&/�a̸L���K�(�5c� \I�Tu9ӒV����HQq��`קϊ� ?�ď �}��T�)_o��ڭ+`v�UhUɺ��J�P»mw�2uWu^��/
�z��F.���׮9{?R"���2+�
u�<�IS��������-�+����]�!��\��W���)|Ѳ�ah�o��KK1�v���|�*�x_�r�Jǽ���tH@�%��MF@]��A�]OO�-�mK����x^��/^��:B*(�����b�v�3�^�T�.d	�%�s�O�5gSu�N�]p���~��j��G���	k�>�m�ʅ*3,)�8�d7�n��C��o�&>�V�=y{L�_�l4n��D�
A�U��+\����ɚ�	�fͦ��_�l\���6��=��66e
��pճ Ӕ�\�Wʱ��Թ	�i��w�(=.r�ھ;�G.�1)2!+�n$�|E�9�t���d���)m�S�T܅�|����Ek�'���׺\��W�O�c��a�h��k���ΖfL�&<�M|V��âf�}�MG�%�}���7D�j�$�����������:��1]��t�%~�i:�����/�K3�*�sDⅢew�'`yh���y��E|F8�/##)�ۭ������\*�a����&TUMw<�i��2��6+£����G5���lrI@K��2[N酡p�Iir�J�0�pN���H��Exf�]��v�@Y�_�6�B"s��e��^�NxX��Ԛ�����E|~���G��y�3����[��2�	sJCG�����f~���x�!�1�����V��W���P�?���^�Y�y�*Ur�P�j����*B]C]��d�M�=l���n��)����\#�٠�)���d�7�?�/�b�'?xuE    uE�9�����}�.�[�T"�DT\S��Ӊz7l�M[�ފ�
��],������>�0<�}�.�yLBSX��<��N���bw��hm�.�Z�Z�g0��]��w��ή��=��0�:�����0���l7��N!�����ܝg����[
`^�O��W�3��[W�B�Lg�h��5�;C:X\8��1y]]	�C^A�h!%���a�<�Up�d5Ex7�+���~���?4�����Jɧ
��vd�ں9�
��c��[^RRU��ר�������Ű]��X�Z�Z�܉F���EW]@Ixw�F
��GD؜�:GI�~�V����2Ϯ��LS����Jͯ� �q]�������+� ��gE.Q֢7��k�H^5��2��������4]�&qk).�b:�jIy��tM _�@۲��I�����J�Y��#��@j���}��y��	�*EAA.�x�l�(8�!��1�� 6l�l�HBU$iA YJ0K,}]	�g��Ϡ���NT�����J&�KT�B8se��DM��o���F[]q��Hے���5�O���D��������9O� � v�����@��X��Jz�T�*��g;6�]ޫ��*����R~Ju�]w�I��-ZW�P-\i(~dd�	�I,������Լ���F������j�-�2�J�j%�
�(���7=e��6QܩBX�bX��O
�Q4�?�����D瀉�jf*�q.>�n�x?��f�|�!�U1�UlO8�n���;���ƞQ��Bٸ��*�.�m�!Yȫƪ�*͝�*��+4�McWI��gC.l�>�8���Ȫ�* �C�[St�:�+h�D��B���������V�������8V�8V.+ۢ���=�h?7�����@h,A�(t^�7���u~E	ԶM>�*�*��d%gEǂ{����p߿;(C�V�#�9�6z���Ujo�0V�0VUS�%�&�c��o�J^�� Z?���2P�D��$��*��*��
���<]6����6{�{���I�O�C8Z�إ5��]6��Vzry�!x�1x� /zL\�]Q����5;�R܆�-��Qg�A��rI��a��Î��T��a��a�v\�=%^�(��s-{�T&.�KCD�iC���)�E�/-����.O'�:������j��W$`l^�Hߌ?���Kν��qQ��V��t]��侮C�c�����}M�t���bbD
��%���U��,��b
-�o�A�*{��r�C0�c0�9&kV����͆��ٕ+6O���ߕ�rf��SS",����w ���.+�y\Aι�|۠<3�j(�!����tiT�g��*
�	o�D�', �q9��ǡپ��i|]|8L���Y��xoS֫��g
	�T�/����K��
��y\Eι�|��_ �#i���g� �)jt"�kEq�'J��谀�����6t�0
��x�!��10\�
��F�=�q���ơ�E�+����s.3]��u�}@21}cJ�s.�j��u�(F�����9���",��d,�d��߭Q˴�T��`�|��A�;<ˬ,2t�R�Ƚ~r��6EɴG��+k+k\�p }c�]��^��9�bZn��^/K0݌!t�A�.�*�'?��5"����\Q�����=�5��cO�(��3����PH��l%W=��?�s�tV�RKmKm-ŝ��2���n�IN�u�JWh��T���R�JlD,�Nb�E�.��k��h9����9D F��Aa�J�${��	kN�A^����]�և�������t%�h��i���(�sJ� ��ec�TN"B���7�7���=�o\�b2<8���C�B_��.c_���P��M"ވXx#Xx�H�-�-r`�3JR^�\qi�LE��q���t��W^�W��+���.�f�>��r�{���2�U�7�	�Ը��8��l3�q�l�ky��)B	��%8�%8���l��~�oY����J�UZ��)Z���i�Ҋ\6s'}ӉK���o�on��^e���L�ڷn��1�:�đw�+�i&eQ+�+(4Lvw�c�Y�X�r�rD����9qu��c�bQ���G��3W��:hӖ��Ԏ��/�2t�kS�fC�P�#bQ�`Q��H���~�l^�-|���k +q�i�_X( �.}�k�W̡8]�0G����=�}��Jy��qe�3B��QfS�T�MΩ����h�6�{�"T�X�#X��2��~�o"�RNR%A%%������C󜤎�P�#ba�`aS�WR��|�=��Ю�:��ݺ��5�<��~�"U��&GĚ���� ��~s)9Xc�"��,�9�$�PH�(�گ��Tɣ=�X�#X��nlV��Wt)��I���,�]ч�Z�66��}ΐ�y�P�#b�.����>���
����jv��Ѻ�ѫ��%T��N�L�w���5�	�	�-���� {�M�"O��6��t�%p�*io�[k;:T�X�#X��9I]Ƈ���(&�5P!=V�d+��c�P�5�o �8���G�:�:��.?�r�c��T�A��U���(k��pD����y��Ȋ�g.7���sm+sQъ6�~�`�?S�;+��T�D��kr���v8pVN�����E�����Л��@����9}v�8 ����jsD���͹=lYiG�S��ĒٷfK���d#�: �+�;�p���C@��6��}��=7�L"L���VG�V�r�.�N�)�v6��uFG��������)�n�.7N^3D�X�#X���@I1�
%�˱]�%lU+.J����Ej��`qqnhϰ���7�j���B����iEW�����iї�7"�����4��(��7����<A�y��]_@�9+�錮%��D��_��4Չ�� pp=�%�/LMt�b�B�YCQ�G!�2�D�SCN_9�ÈX#Xs~@���]7"����bYָ�Kp1%����w�AOoH�^�F�B�BB��;W�4��QH>�� [�K�brۘS��g�B4�%1�%1,S�.�f��.���ڃ��8/.Ȓ�Z�}��BM��51�51�����yyi���yJhT�4]�oC{�[�q��C�����P#bE�`E-�%T�_�yv�_Ԇ�M4��!��v@q	~��oRRJcD,�,�y�,�y�+��!���sD�(�YQЧq����D�jbD��������{T�(��8�`���Jg����R��_�Hc�ϫf����3Ua%2"����P�����^���8-�-��+����uŊ2�YA��̀b�pX���3Q��?ĵX&#�cj�P��En�07Z)���B�I@L!�@�q`K0p�����bŌ`��M�;��� �Z��Z8\2�ؔ���2���H�E(��LF�L���cӃe�]vtvL .��"�g%
�t�N�)�~�.N��P-#b��`�̔v��"q��^8�K9��Q"�()�u�Pc��� ��!�Ţ�����L�}��_B5BU��'�����(F��ZzW��V�E3"��<�\�:҂]�ʸ*��>/�=(u��o�T�J��ff� G7�����;�鲆>}�)^���gjs�g��-����\�v����l�ʝ�`�	�eYp�Z!�ُ��SyG(��LF�L�z��85Ǝ�$4�k��*t�(�C:P��~�S;�*N���VFh��]Ӱn���PB�}u
��B	�ȁ_t� ���pҭ��C���2��2�л���4����[3��r�3V�\`��[8�Gr7���e�eX����J8��~5�ַA��-'��ڍ�݀=�,n�t��z�e�e��
�+����p9��/E�YM�if*
�o�J�O�P9#b�`���=l�.�}����qX�L�t��B{���{�߹�s%�>ĲX2#X2sy�!G�g����ru�J	�3�`�,r��Űj��w�fD,�,�9���
�w�;�.r�    �-}w#+��@t���W�����W�%�"ЈX@#���pI����"�8p+��E���]P�X!z�K�oNw�D(0��@���������t�S�������bR�VZ�Dա�л�N�zZ�/B�����87���|�O�4���sGy �l ?�|�5�_tڝ��uVC�8�B���E�E����ø����}�}"i	>4�V��&�8Y2s����W�-��\⇷�
I����脈���:3��f�@b ���V��]C��!q��bu�`u�זPb�<?��}��m@]	�V��Sz���s8��W��@���҂�;�8�����<���#�m��@��}-Z&����@����:8+:�x}e���=$a(4xR����m/N�[�PB b	�`	�?�m���|��x�M'_�/��q(0�U����y�;K�G�YC���x��M[�B��r��&�&Y�c�����\���7ד��P9 b�(�/�B���Ճ=�>���˼B�K�Z"J�4�a~�R����E
D, �+�o�bGCJ�xp=F�.��T���ciՅ,�wMG��΢�E�^��C ������M�Mwvގg�c��"L����5:J=λ6E1�n@ĺ����sX�8"^�-U©���RJrYSPD�B�I�`
e"��<��Q��b}���a �Q�����:�=�D�6P�n@ĺ��>^�i��n�;���*��10��i�9�]ܴ	i�5"������uMk�@�q�2S�%��.�ډN�+�^%�R��:@�:��R�����4�p�^����&&���(��KR|��tz�T�x�D���ea��=6�fI��9g[&BSL��jdMQ7s(�Q�2Q��.@��=�?~�;B����׶��#�CI	#	G ���v��.���G"�X JO� �5"�E.�ΓIq���(�uQ%���~���p��7�J +D��b�
&c-�;p��έ�xn5?��̑�R���@J�?�.��B%��� �� G�{��_�;�S����6&tL�3S*�MͶI(
E��@�����ξc�|����%�F������H�/���B�GW&N�P b1�`1�u�6��4��&��8Z����,l��n� ��j���q+��\1d�<#�y�9~�S+�v!��*kgM{�YOGau�
D,�<!��b��~�s�FiW�Y���zXM�����-�l�P b=�`=���K�9sn~��!����n�r㰀M!�������?���DH �l�P bI�`I�o����낭]rsCTt>Q�k 6�"��L�h{5#��D�x�!�ł �� �%f��3�/z�=2ۤ��C���\T�B��|�9E(	�$@�$����H(P��3:���p�07.[�����:����h�ݯ��+��X XpN�vh�^�a���lW��n#�A��`{;���?�)cjD�	�	���uӬ����fe���uF�{_��9EM���Y�����$^�D�
�
�j��<���Q���i���J��5�	J��Q5 h{����P bI�`I�y����ԬH�4>��ݪp����Dv3�ֲ�D} ��X X��c��@v�K�gx|��p��x�J@�/h�t�]���Bo��:X�� ���aW�h#��y��IG����N�̾�6A?j�=�̟lʡR�� kk�p�on�O�=��EY���Aa���0�|�E(� @� �.͡n��7Mk��§]#>,m��.�[H#�k�-qC��6@�Μ��j�m޼���7s�#H4�r
?2t�5�P舚�6�:�HU"V	�:`�r��|i"N[��zA؎�L�S`�b��J$�S�:@�� �� n�O^d�Q��#�h��:�8k�'����HK��D��V@�~��h6���k�?��l˔}'q���<��B��C(�D@�D����r͑pRq5��8P���h��g��\D2n
U"V	��:�	�~�e�����eN�^YB��L9+J�N��ݢ�Kn��b��`���v�AJ���G�c��+���h3�X��İ߻]@=C�Ð0���R@�J�J��a\R��i������z?`iu׈\�ȵ�����М�e�
��*@�*`2�@���c����r�"�AW�*XS\w+V�&�#e(��@�.ͤ]��)�橳�m��1��V��^+�y������U�閝i�2��K��_�䍝:�f` �3�݇��3���*��1��%������A����7�?�;Z��?l��A8�]���Σ�8�ѐ� @� �{�������<\�����(�,GS!�u�y���.>���4pɐ�/c޿t������(���(i�y�o���e�Z��[1�����[}�a%C¿�	��	�����u�=<�����<|�=vѱGa���*Y2$�˘�/sǷX��h�0k���2�+
�訂�E��Z�����&y�:�|_�9k�8�:�����`�Cf{R����SL��3~��fq1<��2�eL��L�_�����|g��uU��k�J�!��`/ �#�N���?u��1�_2��fO!�6���`��@{��cxꪠ%^�t��*�����@��~3�%3���AL�����kU`�h�m
�zh?م�RN'2��˘�/�Ÿ|�u{���d��F.�LK������.��@�%����
	�2&�K&��L�󹎝p��`bf^���� U�iʍ���9�٪�2�e�������s�B:}1�=\�=�8O,��,5�ې��C��2��eL���,fL���_!�rG����B�E�a��� �arz���2��K��?����x��e�c�c�`�K;��zPNj����R�eL�L���
�P�g֏�$�a�mnT����4Gd������
a,f�Kf�߳I��Ă��-�OV��
%6��QWL��eH�1�_2��n��'���){7t�a�MC�J��鑔M"�{~n���ԅԕC��)�Rz�	�4�\���G6�3�x�SwW��`-J�DuMh��m�� �3"�FBh����������"�B[l����Q�R�\��^���^���������e��n|R�7�o���}�`�:�%���:w���t�&)�2��˘�/�썟|n#~�wۉ=&����{'�ȅ*���
��F��H<q�i1�_2�����%̕���g�]��K2�� ��b�*��K2��˘�/���A�u,��4��c�XN�<᮪P̐��ֵ��ErE�0+Cr�������#�T)��X��{��w tA�\���_Xh�NK�e��1�_2��#�c}6��~���V�����5	uX�	w��G�̙7�|��b��d�?�l�dQ<H�	X:l�Y�����|l1��Col/Rb2�e����dI?<__�1.����%�Z����J�.�Ȑ�/cn�dn�M;r.9i����`�l����(.A�24���P���HR�eL�L駤j�{��&�Om�Vq�(��ì	pJn1w�"������1��e�뗞׏�z�3��2I��DM��~Pk$�RqO�;s�A+��K��3�S��7���N18H��i(����q?ޓ'��B�)��)����3Pg=����,�f��� O�2J�!�@���/�H%��˘�/��ώ�CƖ�ٗ��c���-��Y)I^�R;��n�ML>v�b1�_2��|O�K�.,gY�0eE���2ԥ0|M�44�<I����D���e���꿃��W>�f<��
O�5�'@ D�_��j~�,׻�V�9M�!�_�d~�����{��Lԣ���I0�@�dTaFex�A߸N�鞹Y�2f�Kf�^�,%P���,��_��$=5���ˁ����ʐ�/c>�d>?ʞH��_����;l<�� C�Q�)��-�[��5�M����!�_�d~�d~L3�&Ӑsv�z�m+ ��K��,xfhA�ʳ�4{ɕz��bV�dV�9w�[�t����ͦ�gr�?MU�(�pU¡O=w�l1�_2���mX���V��m�I�Y�*�    �a�]R���Uӟ��ʐ�/c�t�/�ܳ��頒�h���O�w�0nLÙ#/K=E������&%Ȑ�/cN���_�����[����vG�!�B�~Uj����a�K����_7İ��/����?:5��ɱ�q��V�Ƙe]�'.1P�zu�av�ԯ��@��%���P���a��ͤ1byR�h�B+*B2s� $�Y����w��)��71/�,�Qbf�����7?P��#�eH�1�_2��z����mÃBr�Fi_�X�%sS�����'G��=�T~S�%S�)���K�e!쏉L�L�+UB�)�kZ��I&!{_��}��}ڼ=��i"x�](�`�@A��h�(� g�+��K�����ଊ_���ٗqr�3ӤU��._P�w�6{�K��&� Į��/��7P���o�d�U�fR���KS�p��p�C���1o*���2��K��t.��λ�5��k��-�`bh��o�̝�x��!���}���sT���R�3(>��-2�ѕ��kf���6Ω?�!�_�~i<�	0��bSS\Lv)���n0��,�Q��͍h��w��%��!��~i#h�KP,y��v�F%
%�6pi����i�D�.d�˘�/��9��4ʔ���)�v�[g��~2
VJy� A9?�BV'�B!s_��}���;��73�I/^��+%����m�\��4:[�/o��ˆ���D���.m�h8��,�b]��u2Kh��㊐��k��2f�Kf�_{�Ns@�[It�/�Һ���@gne�&���Ȑ�/cھd���퓉`GU�T!$Q�5�����P��}S�%S�����ͦ�/��~���iQ���	0
.@9Xܦ�Rʐ�/c��d��76b�����#���'�C�F"!���#͏=��ӆ8��%����s?��n���3�Ou�@'T�=�PfL�4RQ�L8G�7α~%�?Ĭ��/������]�Uc�>s;�KP��+��*�v�=�k'�c��n*�L~3�%3����y�._��GV�1ްXC(Q�s������~��b�d���=���{��ʏ��]f�V�Q��Y�Y7[X��}�C"�������������h�~�W<չ2�c.T.��Ha�����]8Mv���CB��	��	���A}��9�܈Nʟ�ASX�h�o����'�Dɐ�/c2�,�Ti��?=Q �/sD��_M�f�>Fu��p}ck%�x�h1�_2�����=\,����&��TW�e��izr��|~��%���Qz�2�kH�/-��<�~e�D?8$�˘�/�ԏ�2��<��f3M�tT)���0�bf�������~;wgU����eL�L���݁�6�¡<�]{�����ˠ�k�R�nJLL�!�_Ɯ~��]�]�]#&A�|
v]͏���y֢�/5w��:�kV���=�#*C:�������Ωُ��+���S#"��lJtn��������A��~S�%S�9s�	L2�ߝуo��OF'�4��PWd����������c�|~��e��a��do�]X�����MY�R�nb�o��3�j:��!�_Ƥ~ɤ���y$���`�����b2M`F)�֦.1�o`'K�X��)�2��K��{�3R����T2�;Q�b5+j�1lﺣU�<�d��1�_2����8(8:QU�x���T��!(F���Q����vE�k�h��%�����!�$��3L'�$ӳ�VP�Hߙ���X�eL䗕�����#��,ǂ���j��� o�Zg��]�?X���8,C:�������ta���b�r�]R&9���$�$��P��PiF�C������
�,&�K&�{�K<��o��gw-^,�+��%��*��X���x��bJ�dJ?򪶙�.��pZ;��*�L^�*1S5��]��n�ήS����/cV�dV���ٍ��vR�R�<M�c@1C
VM`��5/�v�����T��~��%��?�rpZ5(�"���,�� ��Z�F��Xb��1-f�Kf�����ͱ\���\Õ�` ��A����+��)�Lm���/cZ�dZ�#��੅R��pR�a��ZZ�ט>��C��I��I��=�`��/�yN	�0�(ka���^�m��[!c_ƌ}Ɍ�[
��W�|1���EB��Ij���) ��vk��z�!��d}�d}7~�pt��F,s�	�s�騵��)���%a�#C���9����7Lq7,�D�B���yaP�4z��S�����9�2��K��_w�X�_|�5��Ѩ`�,���P�)�<��s��4ٖ!Y_�d}�����Ӭ&�\5۳��{(֮'j2�4`w�������L�=C¾�	��	��쟈9�nl:H��dڈ ��@Ϥђ���f�}�:�V!Q_�D}�D���'n;{���\~�Ok$��(���:/��m�<�-!Wrk����b�r~���#��W�6B�W)2Zlx��ұh��`�;�*d��rogM�߸�Ǩ�cϤ��T�Zү� ��c��>��Q!o_ż}ż}�g^�(�'� ��4�y<a���ӊ'�UL�W���K��14�t���9�1Ӭ�� ���s7�*��&���/�n��2�bĻ1,F�(�5�n1a␘��B��������L���a��_�W�����9�@T7�c��V
r���.�k��Q�f>�ˇY:�䲥���b���vV��|e�^���tA��}����a����F#���v����/�I�as\��=�{��%����u|��q����r��HM�u���
ؐ\V��pG~�NW|U��W1__1_�����+n��W��t�0AZb�p����<������b��b��'p�'���D��?�n�A�D*!*�T.�v��6AN\;D�������?76s�w�N�-��]��� 5<I�Ia�R_3$竘����暴��F�>wv9�8����dW����n��l���Q>��D!C_�}%��N������Xr#'�
��X�Ri:�~��t;J��|����� �h�ԉo���i.o�k�(�?�!I��Е).�
��*f�+f�������um��j�3jq��V�"�@JU�o�&T�϶_�i4���GL�W�I~H �li��R���	w>�@&�Bq�O?I�b�m���qȕW1W^1W��嚈�n�)�����U(�Z �F�����4K�dy��'�c0SJ� C�`�Xr!r��~|��+8��:8��}U"��*��+�ˣ0~�v���p3��􀒲��~~�3 R��
��*��+���7�����s�/� �Zۍ;"���Q��cѪܹ��Q��紧wYH�W11^11���ۮl�EK}듨��.� E���.$��4�J�tx��tE{�����m�7Jg�<yd�������5�?�$����$>t,13^I�e�=%�>-��ܪ������+�����I�%&�v�d��ÇAPL�WL�w�x�c�f�#5�#��l$�J� ���@��Zn!���x�����?�:j	�)2`�?�\dE�Qo��Z��o?,��5s�R�,��+��c�fs�� E�?w�	�|w���������J������㎶�<�)S!S^�Ly%�x68>�1��|$��;�3�ƨ¼��,rh�k;�LZ���
)�*��+��s��fw�[�^w<�s�r4�S^�W�(��D�����Q���oZ�4�iv�
)�*��+��ӳ�a�Ӱ*�_���<(Ν�,��G�!Tg�r����x�~��b�R�SS�q��p`��-X�L��)Ɓ�o��;��.O��UH�W1�^)2��=X��N.��\->@�R*9�`jP ����Z&���<�b�b���H��v�k���yGx��1�A���`K���s�v�ӵFr�U̕W̕����޷��e�W׸�y\< ��u����	�<�B�����W�%ug����i�4gw����.�.r������*�yUȑW1G^)o�f7{: ���w�pKJU�J�A�P8G��|��t��!��y�l��ծZz��'��Vfx�rY���
نTU1S���|>Y    -'�xc1O^1O�r�?9m���=���Ϋ�jN}*
�K
O	�.V�p�ě��*��+���g�������P���$V��-4��R�.S���˅�CR��t*�ͫ�7��7�R��SwݝA��O+���5��PpZ�}>ͦuN��;��.��.�u��4;�Ֆ^PW!���zQTQɖ�spq�DcV�TyS�S�ot��ݯ�	X�����(�
S�!�����X:��C,�����Vd��Ӗ� ?���P�JS�{f ���r�w��DI��А8�b�r�y�� {�Hx�v�*Y8�������_�~�h{}�I�B޼�y�y��a�㡂�U/^�P�����-��������ӗ�-f�+f�_b�֎ś}묠6C�G��M�S�(�3��<��0��<�̫�3��k�������g���D\Ie�&(�X&Q���Lc��5��`^�x��b�b����L�q�1��:cv�<[�z�V"b��~ ��t����i���yS�S��Zk�?:����΍q���rP�V�(P��S�|�gW���!q^��y�����nlW���#���0I�J�@��U��X�,�*����(dЫ�A��A��>�^�LO1ڻƾ��Z��{����z3�qf�/�����sKo��%+��H�ur�|�)�x�!���y�\��=Cŏ|��yt�7��b\��7l&P:��9��9��9��vc	LX;�����A�F�Hb[�Y�Q¸��l�8��7��7���Ӱ�֤�lH�������[�0���ԏv��4e!��z�����y����� ��WXތ$(�P�-���>�b��2���A��� ��8Ѧ�%�b�}P��X:�.����}:��L�J!�^ŔzŔ�G:���ؤ�/��1�zHߡ��~mY�:�d�\zs�s�ߵ]˃��q͖Zٗfpi�.��\Aq4m8�AI��rc�T�6�ҫ�K�
7Br�#"�E3|���O�P�t���a��l�XJ<w�h1�^1����}b���z�o�|�����(�.��Tb(��P�lSC�UȮW1�^1�r��8l������&��=��a���-��+��Ã�e� ��u����"*�������܉���-f�+f�?���3��C�oP1���m��t��L��̠`�H��C���i�ʹ���ؠK������<sN��-$mj� .P��K;D��R��R�}~v�N�2�7ԮYK1i�����ӡ#�������JD�!�^Ťz�I����\���� �B)E2��"����g��x��bN�bN�e�lF����x-O���N�Fv�a{+1�༣������iOR��U̦W̦wT�7ŗS��X���~愑>6RA^c�e���Ղ���w�UL�W��3h�߆���H��Ko/�5%?��!�3f�@���6�BH�Y��Y�l/;5%.�-?��}�p�A��?�5
���'�	!�^żzU��x��y�dQ�,��� (�JкG�Vk��}��&E"S!�^�{�{��i5��?�k�v����9{�Ո�h�#,]��?L�\�?|k1�^1��m�M��������u��}:�`�����cn��}��p�b½b�=��e����(�7���M\��ҡ��'�b\L�WL�G}c�	��-��}��V��H�]b�Q��F�Τ���ii�
	�*&ܫ�9�����ޫ��6�5ݛ!�q�Efrĩ�����+�/|w i�B⽊�����<'��ĞA�vz��4�+��P��z���5�T�0��UL�WL�w��?�Z����x_�i���i��3i��xyx�ձ�j{��w��oyv���v׬�߲�R���H}1�@�d0l1��ݶI�"��U�~W�~�~z���~ݱ\7�7
闻���+4q��Y8���C����r��6���:d97����a��;I�ƈ�e����UH�W1^9
�0�G�ݭ'C\�<Y[[J���6���]a��&9�O��w��U�| ,k��ނ�ڬ���b2���S�X'�Ƚi���@���CX�y�r>,��B^(*��4S�ك~�^����{��F�+�R!�]ŌwŌ��,�h��%�:��Z�X���O��7���4�K���v$1�]U�*.h���]���N�I<���J��QN}�K�B}n/���!�]ŌwUO�\X���������Taʽ+JF(vp��n�)Q�
I�*&�+&���W�=� ���W�6~0r��!eEhi  _q�|��O�N�����bһ����c��^�=��/v;EM��	�s�a���q��7ݪ�)/4��UL~WL~�د(X�i�n�3��M	�A�#�9�����]�~�h�k����߯���2{hx�A8t�1��=��(8�����F��9�`5H�m�PSᕣ��y����gZic�:1I�ΎRI6:,�5O�(N�����b"�b"�Ms�,'���h_y[�{J�-58I$��Ʊ�UJB
��)��)�_��G0o%� .�y	���kI煆�7����H�R!�]��w��|Xx�9��nx�fUns�G��0=�"�uˎ��6y:��w3�3�������� _�fM���]1\b$�b3i����@��w��5����K�ކfr!o7��}�ލ���]AJ^R�H�҈jJ��-�שϭC⻎���Y�7��e���e�A���{�X�� �T����SA�qe����k�W�����cB�fB�=
�}6M-�W;�rX�P2V��c�A��FG`vfB�{P�=���f�;��G[��`��	
!(��sľ[�MoN��uȐ�1C^3C�/&'�&pʇ%����x��қ��CN��9�9�׫g;�Yw����ǜ��a	�
v�B���X�D#F��x��5��'e`Cx:>[6��3��&���Ɠ�������	3�G�ǲ=m0�CV��Y�Y�MQ������9@(*�_5F�A���UL+�԰=-E�EW�e������-O���ڗcU�4��L+s�VS��?��$bA��uL��L���_۩�x��W�a���'��9�D&�:�����O� �7�����۵/�2,{0Y�
E��UsX�->ے�A,&�k&Ɵ;���y��x.`�����#b)���S2�)�`,�N��$&{��cz�fz���i-S�.��)��$_H1��m��\�g�_�g�|!r�ly�l���@/�q6�(�>��c�����B�7Q�&(��k�5�|��C����u9�	��<�_���:�,/K4��(��-r��? ZȠ�1�^_������)*�f�?��)��z�Z��2��~t�в��/
\������:v���Y�t�QB+��7oG=M�A�6302UQM�I�7��W������5��?c�M^L�=Cr�o�{�9w�0;M�L)7����@��O�[�����~<��l���v���X��PPU����v��=��u��C���������t:g`Y�B�e�Ig�/���X�jC�G�*���. 鐴�cҾf����he�����*>�a������uM{?�([Y|�RJ�M�	t���1g_;�{VZЉB��N4zf2�+j6Q��TL�����):���:��k��;򗟢�8�ֳG�֕O���I�`4���Z'�)�7�[L��L܇P��oJ+�>��=�ơ��J�=إ%�萹�c�f��J7N��	iב��tEw A!`�aG������L��ꐳ�cξf�>�B�Ң�4ND4�ֳ�������v�;���k�.�Cƾ��Z���;�@�햎�a�HH�0zH�i#+�t��&�{ꐤ�c����غj"[��l2N�YnT1

Mm�[��y_%�r�]1G_;+{>�Q{cV�w@A������f~#�t	�A3�@�pHp�tH��15_35�X������p�±�a��K�t^�8�B*��������[��(���L�<4v�I=��Jч���-��Is�O�C
��)��)�n��}[ ��fJo�RVb�ep���/�4����
i�:    ��k�2� 2���dц��O��5�\̑/+�2^s�p�1%^3%����/;Z1T_P��Q.p����?������y�i�>sE��Q�H�tH��1U^+W�ǡ�Q)t�;� )N��O��^�U7D.r�%n��
��J̘�̘�k��`y �4˖siVtX�s[a�(��S�Y&k*![^�ly�l��a���{�?v���f�4������(�2<�u��*��BD�����m�!�8@Z�
��F�9O�*Q�BƧK�@��6ɼ+$��$��$���
��F�:��p��|=aغۥ"��cN��n��I��q�9-����*T5&��W�?r����ԧ�:������s��ቂlJt�QQ���\P_C�T��޻[^v��Ie�!!^Ǆx���P3�� O�B�v�Q�O�<�sI��~����	���:��k��3���ƓU�RE-+��1M����M	��u���7
�[_��
�9��~�_�W�Ĭ*J]��V�v�J����6�����ũ��(빠��!�[;�;F�¾ ��J��]"���S��!V�Tx�T�+Tϻ.s�Z/n}��V]�X��5
��̨ŭ_�_��}���C.�����|\�qp��y�p��d�@�V�ͯ�s3u�Wc��!z�|x�C
�Q�u9,�~�;���x�`��1h*a�L������oI,��bB�fB��'�T���n��ky`J�Jd���D\ЊMiuH��1^3S0Ҽ�8�l�`��&�WFK/rL|���tP����cR�fR<��u�m|t�u�%�3oJvT�����SuJ`��F��x��5���;T'=+c������ ���
�x����	i�y�:��k��_�n�/�����3���/�;����C���� ����Q.��k�F_o�ú9���+2o��ɂ��tqhr1.�֨}S@�>5Œ��XH��1=^3=��ZB����w�:J(�|�M�c�i�=�"��C��9�9�7����� 	�i]�1A�(�XRSHX�~q����*��C��	�	�W��|��{��KN��.a��r%��9��#�J&"!?^��x������09�> 1�ȉ =B�����6�g���vΎ�U"�Y�:f�kS���������s]y�#�i;�i�> \I<pȋ�1/^.H;,�0�R���̍��)U�<�N!K%�9��c�a�C�N>rH��19^39�����5�E8O��ȗ'�B�Ko�+���U���:������gv�9t�(/�3�����ZB�	+DC+�D^�b]Ԑ�cF�fF���c;m�JΎ���-�-F(PB:� ���*�dx��5���[���v�퇷AR��9@�wV�c�ZF�z�!��tx�t�����]�+�|��*�g_1�f�=8�jȱ+H�n�#�j�b��N�Ij1C^3C�E�<��'f����Y^r�.�>�nJ�����e;�ؓ:���#�gpjW���j���y���W,��)JW�@E���$[�!+^Ǭx]TG�T�gG���>pR��� I�plG����$����Y����~�e1E^;��������k�ڨ����8�h\܀L^���;\. k�{��A���^wr�u̕׎+ol�x��v\�A��`���i-.�V˂B���N�!E^�y�y���ٌ��'�ܗ��د�UV�nf���PTwɑ!:������q���ش�L����7��	��0�OUB���L�i����>s!Y^�dy]�q٫=�wֹ$�L1?��4�J�2�nN��c�_��rr��dy��5����Oc�nxŲU'��i�a�O��kWd�)�Y\���KS���!�c��f��o?�~�sD/׍'������Uk�|7�!f��ʊD>2�ǔ�̌����e�'HnY�k�ڱ���M�i�`�E
�C���Y�Y�������k);���ܩ��?8��J�q`�ٛ1iy�Cz����z��/q�I����O����O��6�ץ ��e����uL�׎�5�M���`0���Az�����W����}b���:��k�G����}���/q�m������F�N�-s��s����2H�n�:v�ו3�p$��(�/n���
(`�6$�ruk�82Y-��!�Ŕ|͔���GNQ�L�X�<A�����@��� ��C?��(���|s�5s��1�����k����-�6K1cA�Ǝ�>��C1_&O򐑯cF�fF��Y;�ԧ��z��%ǀ�-K���r���+d�똑����u�7���f�z<@XgU
Zoe�0�����fs0�k�Hs�u�8��4��ɲi�*F��1�E=�'�ߍc�-�]%��!'_ǜ|͜�s7wtR�M^ݥs��2�J"�f:@7�@��N�B6����ڱ���ۿ�⻖�!wM��L�0����Kc��赴��VL�׎���l���=��צ��r�ᓨ�jhCkt�n�?���Q�|��!_�<|�<|L��&�Ot���R�d�t�3Q@�ntAA�/�d����u̿�̿�lq��A8&���.}�HP"��)�4?䴈I��{��5���)���]�[�"�e۝]t�OŔ��::�(��L�:��s�iw�D-��똆�k7�����8/�솻>��nH��`3b��lz!�Q�<��!_�,|];?Cdև���ܲ]+�;ؔ�x!�9A�-rK�e���WL��ޏL�#�2�"�F���rJ�	AUMύI�����$<İ���k�+B����b��M%Yq�G�P��"է������H�CN��9��9�w�(37�|cG�}�%MFὛ�l���r���B6�����vc��'~�ۗ�C�I[�0�Hd1 �%�	�#.JO<rh1!_3!���S�':$���!��n��י�ah�wSW��ބl|��M��OL�rf�`��Y��5Y��� �礗,/�{m�*�♐�ob*�q����e	�FPٲ�W�*����+��ř6�Dט�و��lBֽ�Y�&w���QO:xb���ѢЄ���{/���[b~�	��&&�&�_w�E�S��?��vR�j��)���UE)�IѪLH�71��0��}gW(��۟9�c0�.�(�7�
ӱM�r���v~��_�[a�	��&&�&�{.�=d���n�S�9�R�Aa>���&��K���q$&����ob
�a
����삋�[L�v��cBa~�rAx-}x抦>@^�����H:��\y��1ܪ�al����y�)�}��}H�L��71�0Í&}Ib
L`�i���t��E�A+�J,�r��w��Y�ML�7���Z�B����o�_b��r�����P���G�1��+���CV��Y��Y�G˰�5�uG��v��!CKQ�T
�0U����b�O\=D���o����Қ��w5gZp��G����������w��钝	i�&���}X�@ྴ������R����z ������ӄt|��P����W_z(��1�Z��`�'m4�������P%�.�㛘�o���&���8�)K�=Ά�v�L�� TR�EwC�m`C&/�[��7�¿i��SZa�[� ��l߈\�,+h��5^�+j�(ܘvn`���[L�7L�w�����i�9Ay� lG�'�$P�s�X�	~ڏք|3��p�o�A%��o�	��\#`�h1jA��y�kq����)wIvLH�71�0�+�=O\��������vW����h���H�x�t�����5��5!#�Č|Ì|f�xxes�{?��y���JTTh�k��*�iݍ	��&��G�Ǆ$����&��;�Tnd���a@��w��\��6!��l|��Qŀ��qblR/����8#x����:~]sX�����������y���"�n1μ��tL�	�EQ���Kj7�|��6��������o��a��37A�`���`R$�@�%�����N6q�4	I�&&�&�_�Q�]��Y �o+�U�|�Q�S��[ü�FG�͍0@�O�LH�711�H�f��s�iǉ    �W���v54N���*e��!�Ŝ|#��! j�ș�iW��όW轘���
�d穧n"���o�sc��3#e��z�yD�w�\�%�1K2��PS�EËLDm!K��,}�,�;�z~��cN�Q���S��h���\`�(�@�A�t}؄D}��	�P��2� d�jϖ)Jԇ�U�1�m�����2�M��7���
+�&s����~����Sq;��3��$�(a���\�-o���~�obھ����O���W���+V:A���y=oW��ɣ,d훘�o�a���F�d�uίЮW��+��DJ�)iHvɺ���D��&��$ ��_��G&<T�����6�����s���H�ʈ�����]]���ըJ-�b�y5esCC����	��h�|��Jx��Q�Jٸ�*	��:t�Kiu���Y��Y���'�v-0�p��p�X��ho���Lp
b)P	2����G����=���U�L�0����;���n����0���ěg^l��J�B��2�~6�֫\,0,��7�l>��.���~�%f@�:�E��5Ԣ]rR�M���0�j��}���9���D�{A��u]��몤���~��r�q�nm��%.����8��9OUoh3硗�`Z�p@Rþ�
ZT��]�a�;�n����
S�Jw���ۏ.#��	*��#Dt�!ZW/֫al�K���XG`XG λ�+<#'];�#���h�g^�7��@橔�����h������g�î¼g��Q��������G9�. W����XF`XF�	1��kz�b�X���#�}K7i�N�F�L,#0,#x;�n({?�;B��ٚg^���y�CGn�c�/�n/��XH`j�O��P+�x���)�Y�+����b��zp�"vL�J\�^�b!�a!ՉLJ���	����b(�5@�wc�.�=l����2)��h��U�U���ꐾ�C���!��t����뭚�������:q�����.���m>���P% 1Ir��D�B%�mx��ͫ{��3��$/\/c�~���>�����&qyF�u�JP�%F�/L�P��M<�r����ʁ�	d���ZRa!�uk����ق��3�v����SH��&VV\?҇�E�Tz�wP�,���מ�Rn����i�;��k݀�u�u����[6�R�PU��m�r���	oF���1��j�n�ĺc���A�ISȑ�%o����oV�G&41d	Z�D�h��������?x@c�J�M7�r��@�F49U���]w߲In2�h퀉�ƈ,9�۝��o��Ս>l$�SEζ�� 3��z=��Ƙ�:
�LX�?�(<¦7�JB����;x�wc�T-0�l��l��}�^�}螿owp�J�!�t�;�z��B'�G��&���
�&*k�z܈�:�j�vlSc%�0�Z��Z�lEw��]���z-��kQ���普�~�S{��>��_K]�^�b��a��;�D�����/"'��w��r7EA�����[o��Í��+ײ��>�OO} \y�����Z�N�~�I����u�e�z�J�eZ5`bՀa������4���e
��&�k48��DV�\ww}�-���X7`X7p����Y��-�6�qV(s�uy.�j�S����I�D��&;7��T��W�bC�,�>�:�������	I��^�bрa��ź���u�c�[ݭ�Q��)9 B˦�n�a�/=�D��E&+=����%�� �.Ȟ�<�+��{�l�<r��L�L,0,������j�������̲��֔�^3̒���LC���3�F?&ݗ���X?`��� �C�D��l\O�y� 8������V�J�@C����MD��%0������M��r��wGM� YU]W5��U�3a�!à!����ܚт

���8t*]n���p��UpS�'3L"m��k��\ʻC&��v4��å�An�����A�]��K�Q����"�"�לk�y��p/$^�iQ���A�!����;q��k��U�UlP��?2��Kgb8'7Y��ٿįW(ۿ�m�eV+L�0�R�)���ZR0��z�rG� P�����b��%��V�X5`X5p=��	��.	�9PN��n16Q��B�̑"�IN~���R��P��s>������߅a5+L��mK�z(Z�k\��ϡѲ��������g�w�\1��I(I*x���+~��.���zm�U�Iц��Yz��a��t�<�m?��B\��'�:�d��5&�'y�8L�,��u��_m����C�9zh�^٨�N�"9O�t��ŲòD|��ωV�H*��y�/��)1�i?'��2AQì�5�5_z�{���hl%ҷ��p5@���x���w�6�i�b�Ċ�e��m�l��Á!�XF<v�r��8+�FT�"�u�:��ᒖ�X2`X2 �R2.#�6Mq���V�&����iw�g�m��5Z,`b��a����^�߿������w�LN)�+� EڣBy�E&		|�&�~�~E�{�j�s������_n�"�-G_�f!��)\M�L,0, ��ݯ�Гk�7���m^��0�4vL�cn�j���evu�%�[�����A��X<`����˦&��qjz-�F��=6���}\��/������Z�~�E3��_FMCخ�8�y�j���t`L��D��K��_��~Ko��7��Oa���xt���Y`n�=fQe���:���V�ɛ�K�����7���ZXg�!��q�|���f��&V�FN`B�ğ���9���u��g7���R$o{���+Y, 0, ���*��8iĪ�.�
/�����b"��dëu&��F�h�%���A5���t���gh
z��A�n���c��+L#ɔ����x�/;PXC� sVT�!��5�X���]��MBp����Z,"0,"�G��^��L	�3�N��Q�o٬�3s�%�v��cr�B		.�+�� ]�3��Y��`PV�wxHh�O�͌�X@`1�e�*c����c�F����~r�-��:A�b�4�-���M�l����*�*����!"�D��J�Qn3b��Q]d��"X|iڔp�h1�����7P�x��n���n�T�o�%m���
3��i�D�E&�\%u���� {W�D
4�bP{��äa�N(�ZO`c=�e={������f�r@H�^5�A6�P�����۴���ZO`c=�e=Aȳc{���8o�%�h�i�+����Ԉ�jI��%�%�9r��~a>o�?.�Q���h�����p���K��Z	D�2k\��r�d}�?���25S��1�o�ë ��]ρ�FN�|�K����8�A�M��� ��A~� �u�0H��,E��Sù���y�gL�K���/�&�,�)~S�V��ف��M�W�U����wEX�i�*�C�ק߻�n!r�����}�㼐�`fɖ��;�������3�j�:5<����5קvk�1~c��1�`�ڃ@c���&5[8���F��������	����!~�?�8�T�7���i՝���c�#��`�ۇΜ�Z���߷��_#M�yV�)���	r�ڀ���݂���TO����I��[����g��8a'(V��ڤ�B����ax�6�Z�[k�~�����՞>����u����6���l��6��/ms���Syz���۷1�o��?��=L>�7�!��~��q�&�o��8O<�ԡ�Z��&�p��ۘݷ�ѻ�D��E�&0w������Z�?�n9g�$.\�d1�o��ׯ�� �S�P�>bD���~�%<:d$U8���j����4I+�r�V���'�Py��h����~`V��6&�-���-Ձ�*�`A��3�34�a�����^��#h�    �^�bL�a�?����ٻa�z�ڿ�l�B�fVM��V��e�Z�\��l�ՁF�m���Rj�q�t�؎��l���l�� v��/�de��=>ӛ��֭&�mL�[&���3�	�~�����&N�pԀ&����%�թ�kY�[��/�+�__{Ԟ�z?��W:X ���ނ�s�=��m"�8��5�oc\�2���d�S�t�v��S$�nO�P��{ﰬ�HT�G[U��}3�V�}�C��wOG�崲@rȩ�U��$�dk��<�Z�Ԥ��V��6�-��g#�t���C)����k0��]�^=h����zxhU���m��[��e����ut��yW�~��0)\�e�obyK[�!�tZ��Ծ��}[���f�X��;Y�q�㰅9p�?�'�;״��uXVc�6��-c��&��?���mQG�_r"�0�]�l��c�$*T��ۘ۷����������3�ъw�N4�G75���} |�N�����m��[����!�iS�J×
����p���6[���f����մ��i}˴>�O�!}���C;a��z��F,p�h/��C�՜��9}[�w���"��#�o�$�א���nj�Eɽ`-��'�A}���A�߇��H����0��@�]�zl 5x0��f�]�������ɱ�x���|�x>΋D��>�jcn��)h�J�	�?���?��G�p������η��/Y�x�@���~�����7�M׌s��Î�;���O��X��ۘϷ�XǾ���_�_�c�q]���E}�JZ��y0�a5�oc(�2�����V�Z>��A�qN��椨أ��ف�/ �J�cz	��|[�f�3����r+X��}�43;wh�d6��ȷ1�o�?�����%�A�ݠ-�_F�:K��[��ۘǷ���� �R$LƊ��q!�m�����m?�K�a��VM�ۘȷL䃩�[1a���0EqS�jalN۔A�#��g��J�{�U�=�\���|�\>fߛ)ǗEksSoʀ��c�`[��,0��n������,f�-����>�����1��P��QAj]��] ���_'���ۘϷ�矷��a�`����2F��m�'W=�w�U������+��`� o$������gA����Fx�XL}&��/}�Ȳ�ŷ1�o�Ow�% 9��0�P�m���	�.J��j�#���ٰ�?oM���\���|\�!�\GH5h�ܯ�B,K��q����E��촲a�Ի0T�̷1�o̿@غ�Iظb�����P��N�~�����a��<R6T�%^4���h�e4<[���Ǚ��s�)��u]�}�P���Z6T3����|S�V��V�����O�E���M�!f+j4H��\f�y�l85�oc<�2��渖������=�*��mx�u]� }6�N\�^�b:�2��?�GT	�Cv�|7
�(���ɡ����FˣjY��|c�������#ܣ��u�b�^9q�8��`OX7a0:è�h� td5�oc2�2�֯q�{�}�i^��ZΊsM8�ȥ)<����s$H�[�E��̷1�o�̿�x��`�}B��`�H�e��l��TKA?�� �j����ʷ1�oM8O�%��;�\�1�4��N�����[�1Q�h.��\�e.��/��q�˧aԂ��E�.�p&�GM�;Zw�y�ӗ��˷��_B�(5m"�þ��M6�C�p~�Y�
Bu�?<.��5�Ve5�oc$ߊ�?�/W���]���~/N2bX���)�^� qz{Xm��0y{�&p�&�mL�[&�ZDFlU29Ϊ��2��8,��m���_��ꁋ밌��v���˷������V���I�/������2J�.���o�,��-��?���cnP*�勌�8}#��(�hp����t(t1P�Ąx��3��@��](����ʱ>c��Bk�!����O��~�fRuк���w�y���+B�[&��v!�s��J�l,
�,
��g���2fc'�";����9ڡڐ���PiE���0��o�N����v�B��c�b�,�:�����i���p���b �b���ُ��^��{~é20�3k��l�.v����f7<u[�8��: � �V�;L޴���|�%B���@i@^�n`6��"��h����2��-6�]q0��n�6���		���n��G����&yR����
`6N��=��l�OsY�P�x�ڛ��[�gH�NV��6F�-����.�8oh��o=@-A��w�@[���y�M���5�oc��
���G��$�yY�@�lʕ���2/�FU��N��6���d�k�2!�ǁ���_)�,���%h���]
�*?�o���mL�[���뚱xZ`�`�n��3��X�L [�&����П����f�m��[f�o��.��<�
//k(jæ�t툼>��5�H=Q�V�H�e��R�x����':��9iE
��g��]�ы�h{
6Ho�>�d��t���~�t?�w�v���#�*�?�� Y �A���W��������[hQ��'[ZM�ۘ�L����<G26��r���aR����	sQ|'�^������<7�-��e2��F�l(�0<<�w�KG��"Dh��Ƥ�e��C�P�J;����.������A������ě�9s��90��l��{��;R�B���7+�&��&�L�ǒ�ɒ�V��6����S|gE�����wd�O�^a3�N�0�D�}�v�΃���1�o����5À1;���p^���K��Yd���t�X��6F�-�������@��=D�/�%�L�X��!%�#(��UZroԸ��q+� �8lfC��&��?-0�G(���\_�6�-�l�D��N5��5�pchQ���_���1OY�ݘ޴4�oc��2��۶]alN�TԺ�_�vνG
`	���thX\���l5�oc��2�����=���i�vP��52��߮���	�@g瓚�1�o���*GБ��S�w'�7X h�d���7�����&����1�o��ꡊ:�'Wp���5&R�ӮQ69�d9i�BtO_��m�[�	�U��W�_�{���@�D]L �%�wM�V��6��-��0ʒ�.r(�\�UU]��tQQz��~���g���1�o�O��G6�iGk+��`xD}ԒCQ�>@�����i��Ƹ�e���Nr{@����@>��n���m�&Qy�$����m��f�iD_1�2|~0\�L!�c �=m�������uG��&��i���l�e�?�CN��ݏ����z˱=����J N�&�a5�oc��N|?��'|���m��[� +���G,};4�!�&��z1��~�t?���qt������cw�dla����a0��D�*99'���qd�'iTi5�oc��6r`z����~Rg?G���@*
a�F�[��AʵX�ԭ�kZ��[��?x�7��˗qxA�s*$�]���Cc����Vf�j�i��Ő�c����c���<��S������h-a�)����"����l��.���Fh�� �Tԁx�	Mfp��4�B.ptY�:�)S��)�s�����Y���LT[r�R����_E�7NJ�T��ө.Np!5��t�]��Y�� � ��d"�y�^��t�鴬�ŲǲL\�l2]������7Ψ*�IM��fN/j�ӓ1�5.���)��"�Ժ�B�i6Y��O Lv�Q  �d�]���iU��U�U7=wV:�=��:���B艬`�ӟs�Ǜ]J�贮�źǺ�KvAlC9Bqt;-�R�E7Ԉ�cEU�u�=v�\�9�o�-py�al�/�v�_��I�v�G �U³�
:p��epM�J;�2p������|���F�׃�&�>�*�ұߪcmE!�D���������ꂯ�|��T��e�
r!_�� ͈�1�;'�(�V�X]�$������-}�7����\r0?�Y���%��æ[��u����\!��#m�j޲���y��)XK�;O�dEͽ-�4    �Uy��vZb�b��c���A5�t&��W�����vw�!�����y����5LP��t�u.����h�,�8��}����s�*;<5p������0|���?�״Xa�$ {�!��߉P	K�'/k �u�����h�-S���J++�	�/��~V������Crp�����)<:���*�o[��Ns�N�\,7p,78�ƇQ\&�x����Z�A�,e\n�L �}�����W�WlP�-(����p��r^Ғ[cѣŶ�	I�D:�?p����� ,/-"���?t��!^ �.3|���ȃ^�KZ���^O(p�V�Xy�J����=�,-��Q���������Q�QB�������ڃ�p�B�ñq�����z[�V�*k*O�6�E�9ķ�ژ��Z~�b��c��o\����Y%h섾��+Kˍ������]�*˟n|�V�X}�X}pю���5�CLok��v�ܭD�)u�5
t<v䋾�A���:��.V�R�P6����&ֿHX��rؼ�:p��ٳ������Xy�Xy�'���wl�����hw�vJ����m�W��߹2�W,/�RI	N�\�:p�:�͍:�7�ۄ���t�emP~PW _��|uɚ*����>y�z���.H�zRֹ��o~�s&����EӠx���b�b7@�u���!���{�w��N��pW��ST�ٟԟ,P�'~V�n�������ǆ�B�017>�_�©� &�9�Oa���}�:���ۿ�����]��x<ɥw8L�^72�`�����B��G�.V 8V P�|��X��p=���m`��`�t�ς���5.<��j��u.��}��<
�9�x�8���x��I:]��,��V��.�8�����[p�ѫG1�`�{h�<c�T9xP$�9�Cp�����~�M��n=���WWT6N=i͖j$vD�`�f�_r����������U��di�zj�f�
�K������pB�k�F'���V�Xy�Xypq�5&�XC/���~ڕ� R�� ��<�X��f�6�5,V�J��CH�8&O&n|ͨԨH��r�^�- �{���&�j�u+��Jj4����L�����o��%"U�lW�D��2��VX��*q�����)����_���a�W�י��
� �Q#X3�(�ZN+\�<p�,Zk�f��[|���P�L�V�|��c���S+\�<p�<���Cؖd�n3nN �а�����Y�Ls-6p������������ʢg�T}�?H{�a{��c������:����e+8P���qF܍��۰X:~�A�3Fh|���b{z<����Z�Zz+�n����	�h�@%E]�f�Q��Kp!�?��Xp�Xp���������C���ٵ-��b?e�R?#�SK�����.�ZB�!��-��aQNr��O[Sѽ��v0�\�Cߝ�s���Xs�Xsp�����|����"���Ek1��@�5�1NK\,5p�D��r�{���X�=<����c*NK�{�S��зx��i�������`r��l({�ұ�k��J���RS��,*�Q�-g����j��(��������0ȃ��s�$�.o�����K������Xt�8-	�k9�l�O8���1���ٔ��i����Nb ��|T���'�+�v�|@��0�L>�%`���.������:�:�w�����Ǚ�C�m�n^Pj�Jz��<���]|�w?i�L�����:':�MK��=`±�c��@0�ƙ�'BER!@��c9�%~[�g����vG0�_���% � �x]�}AT�Ǫ�*��j́�5������e�[�!JKe��郦��Ŷ���\,���A�\�6p�6`�`����~lt���E� g���Q+�_��~�-�M�í�5�5h��l���ur�Y�/�qDO��[s��6������z�z���>N8t���>�vd�˚/�+L��˂��OCW'�m-2p���������Q�~~��b���u0�G��gC�'�Slw6ѽiy�����!����Cv�����fp�i��B1�oh��@��nڤ��V�Xa�0��*���j|.Y�5��9-�����
�O�`5��b��1����/����?�D<	��T[��9V/O��xY�6�t��w1���o�N�D����fZ9��y��2���]���&�]L�;+�Lr*����z"׶�|��.���c�d�C�X=4��b��1���Q`�I�s���B̲�*gRCo�����������������t�|�x�e0l��#<�,�3��zXLQ���wY/W1���m��~U�uU�km0tuw7�r}�$vJ�K��k���t�;�����TϾߟZ������d5�JO�Go@ኁ[J����wNt�a��^��*�C�7�Qk����CUrڰI���]L�;���Ԣo'�I�\��=��yS����"�
����W�.&��!4z�g9�[�h�ϊJ^('�Q�]�m�cɻ�׭�w���LL�����Kr���5 ���X_��˷Rg7��w1������������=��b�@C[����S�J��F�]��;F�ϱ��|P�>H�|P�;����fq��R����Y�W1���e�9����?Hh-/U8�m�h![�$`�i~���i~�������1=�m .xxkʪ��qM[0�G> o�kN3�.f�3��c�̆T׭�[�7c���J�t����IO}9;HՉ�\��.f����P}���i���V���]���Ѱ�����Y6��o���f�]��;f��\U;���q�����MA�N��7�*�!c�H�=��w1OK�a���$`2������-�j��^uK>yw��L#�.F�#��[	gt�n��'	�����S]��[�9��&e��w1R�|�����ew�{�U��4U��:Rq��[3�	Ϲ21��p���z秼�M˼CK�v�����+���F�����DNP\�&ԺNV��w1X����o��>lQe���v�?�b�vE�Ϟs�1��t��w1_��[{Ͼϳ��d7X ���8�(+_ v�/Ï�?e�;�ۻ�w��SsDo����A��.�%��M�"=��s�E��~�c
ڻ�w���c:pGh��4W��"���ݱ�����B<�{#�N� y��]`A6>�O�N�K�y���r[�.�4u��w1Ug㠯�O~�'��l��<����kZ
��B]-$\:�}�4W�b��1W-�2m�s�ZN��Cc�H�(���m���@	s\��zs��������"���}��d����
*�Q�ҳ�@_d�XP4X�b��1X����oaֈ�jX�qx$������zZQn��?��'y�z!��z�H�'���/����֙�wd���j
K7��j�4���z�����kj����|�?�f�z��	L]{����x��e�������w����K�X?�oT�w�>	�5抴i�� v"ue\���~qI_}�i�[���]L�;�̇��-�Ǽk��)%.D�6��ѽ��N-$��!�nq�%����t�c���J̖�m���k������Q	>�2.��Fu���Ȟ��-ζ}��(��_�5a�c��3ay�@�F�4{�o�N�ɗ��а�"��vxn�����z��>����C'0���.$A
g��	\pB���[�����Ֆ���������U�S��}c���<���q��N.f�t����Rkx���J�t�4Ϧ�������tg�#�f�<�����^���ա[��h��N� ��&�}L�{&�{D���k�l����'�^�,��8W(`�_�Ԛ����R��V�f�}��{f�?q?�e�V�Ul6�?�<�_���_��}O��a��J���1}��^�O�X|��ΛU��tbw�G�%%�"_Su	V��Xr$x�9|s��9|5V�l��4y��9���/jkOwe^��>f�=��g� �  [�M�K�s�Ֆ����ohc{���g*T���;��	
�k���̽g�:��l�>o����=�К컂� !�8<���CI��k�����g�>XQ��0�J(���n:9B�<����h)��xě�Iu�^��>&�=����F��\붥f�K�����*hȄB`��Tc�5v�c��3v����L���/�D���w�j����OJg����2�&�?���}�{��N8�}���U�
6.�=�--�-�sW!%��K�"%�����1q���.rl��B��'+��UA;�o�v����4(�5p�c��Sn������n>��LO�K�ryg�����������ט��1{Ϙ=�b�^���T'��u�ʨ���sN0&��x�n�ĥ�W�]1^��?����o�8��:2�N��Z�'_g���7��(4[�c�ދ�?���|�d��隦�n&NY�g���k���`q���~� }��[�W����՟��-�����V�u��LaMM���"��`�>y���1P�ˀ<<3ڲ��H�E+��Mn�W��%�7 ��u<[����i��Iz���I�K�Ϸ���=����I�f�_5Y��� $�f;�v������}J��^�b�ޗB�~6?���]7ލ{^�0�=���8��$�����<�o��b"��k���(�g�d؎��S��Q�dD�'��U�\�X�ȶ�l�k��� �g�s����u}��ng�,�W��H��	Mﺧ�t�Js�^s�>��})�אC~�5�7����i3/*6�=�_`[r9��]���zM�����Lџ��S��M��o�A5���ʢur/m���Ж�}Yc�>��=c��vK8F \�-S��_���s8*�mB��5%�cJ�3%���헾{��k�����lr�E��S��uk�~OXz�������ʟA	ubQ�ݙXU,�􈛡���ބZ��鱤ׄ��	yτ��*��6"�uS�S*�jD���[ٴ��F�}��{F�?b �GE�g�!��.�вa����C�'cϜyr�R�������ޤ�(��~�}��+ޤyV��͙~��:���Z��.&]w"��kN�ǜ�gN5�����u��r`Q�Bcz�UH�f=k���u%@4Ej<�5(�cP�3(z����}�o]l0�᩼� &�����Y��k�&�}L�{&�ςq�4�����BG۸�u��P���t�8�=}����y>�oC�gk��!�#n���p�����Zhz=m��м��y����n�v
}v�`���ᘓ&amT��WP57؅�Y�/�kZL�{&�oؙ]�W�C��
?�so��.
tV�ވ�jrJ�58�cp�38��G'�Y�ϿF�L!�&�!�A�m�+ja�P��ok|����g|^<}�b����*����.����R�M	�s�46�X=���%�v���������D�f��v��*t�~9�u�/w���۶N,m��1D�kY�^x8F4o�~�7�v��8�K�uUS�����9^�*1*� ��z� ��5�����׶��>�Ž�y0���ks�-�/�&u��5<�cx��2�%4�o��m8 �&��a��1p�s�l���<R�َU�O�켏�y���� �5薶�����*��v����7S��+I4��y�����-r�0�K�2��cѠ]�y89��>�PХ^f�r�Լgj�v`7Vv'B�	oiđ��X-�hӔ�._���@�̨���5<�cx�ע��;���<yٞ��T
	\K5�k��=�j�� 0�OI/]16�Ţ��� �?v8 e��,��C`���6-�`{ف�[~���J3�>f�=3�8�x{BC!�U�SS�M+WN7|�.Y]p����15�m;ܱA�X��|^���, ��X%�\���`>U�i`����g`�����7�������e�.x�����&!�����_��{Xо{X$]M���4[Z�Kj�qXZjv������|�N+����}�{������x69�J�'��C�2��X2Q�Mkz��N��xM�����L�K��v=���� z��hu��	"��I�4�c:�3�f��Nöy�4����� g@���o'4f��>���'^��>��=��􊞐p��L�hՆ�����#��U{���ҍ��&��y���L��&+�7�n����"^jܦ��� �����9[�����,F�}@�y
�=ui v�J�!�G��ؒ���vJ,.���1K�C��g�:� B41���e��k�tk��.�di����g��-�o��e�s�2��s�8%
ڸ�
ZN�S��z���y�N�7߇'z�G�7��
bzW���m����ː޶4H�c��[���f!�J7��Z���ق�������:k�8���T��@���zo�.;lZ5	؜��+-���.�� pk�-�{�y�Y�^C�>��=C�g��C�yխ��r9�3MU�08_8��mp8vKN���[��}�{�/���m�����;.���=���A�V��9���}�J(d���}��{���A����WG|h�GCZ0N�p��]PnV�8��&� ��Š���A���YpHA_ ��d%�H��sJWM��O����1b���V�I7*�s���J����͆���d��k��ǔ�g��|/歘ݠ�xQ��`��/�+�jiJ>>�w�%�ɰ��)��k��Ǵ�gڞJҟ���#��d 6�M_v����TV��TDC@ҭ6�pM��1u��Y��]�c|�el���&��޾B����[Z^?���@k���Խg��C��~�kپbi���r_4����5��%���K�+[��{���{��������R��a<�Ax�����!���}��{��0�q�7�A���R,�<��\]��5��T:�K�2l�y���^���нg�>8;|꟨!��+�6o���I7��Aq^@�����"�į��,&�r�u��O4R�����D�ٰ����r�	rk�}�������g;}��~.��o���ĕ�'fԒ�
G�9���U��*�N�Z+�^�b�g�W��_���c������jP}E�{���=�IgK�����K��_L1^v�M\Φ��iUc*L˺*!|�
zXrZ:��t˫u >�x��a F�|ei�+��0 �����%��h8�;�zM�����L��ج���}+��(�K�-��Ŷ�r�Ș�>PY�3���5��c��{�˚�����G��*��aӿ�Q�����]���W��1����"*��7OP��,eb�@}Rc�(1�)Zpߧ�1M�����^�&��ȿz����1\�� ��9�|�^���Ӻ%��C���Yd9P?��,:_m{UJ��O�L�4?��i��״��i�#X_
�=��y���.������bߘ�b���������	��	��;1��38^����k�?49}ۮAH1����%]k��ǔ�g��O�ž��G�2S��L��o��Mm�`&7-�)���`C3�>f�=3�̀��9KZgbi�Dڷ�Y"|�ތp����"Y�i��Ǹ�o�8�_2Ƀ��3k6�l��T �"��"�J�@.��D\#�>F�=#��i��?���Վ�ѿ�p[��*�qK��z3�g��1����������>��#�|�5~�p��%U�\�0����KG���|h=H�lZ�c	�g	������@���:`ͱ�sf�y��c]%����'�[�o�?��?�o�      ^      x�UY�v9�\���v��O�,-ɲ�m�����s7	�5,t�a5��7 mϢ��� 
Ȍ��L<ܵm�ٿ�2l�9��<�]h�J}��+����ざ
v�w�̾v�}�<�aG��J��]�UY&�E���4���4�����q�q���v�+e�,�{�ֻC6�������������+a�YY!�b�����^�������*�c71oV^I�j�l�Z��iJ��5��|d�M7��*�=6�j���+Ϲ.�-����a�;6w�M�l5��|Y��U�Ct�ݤxl�a���<>�m�[�gg���=��na�|Ni���"�y�[���}��8��~�>4�����)�\ڕ�y�R��w�-��U�����9_-�-�j�,��rk�r���k8b������w	'�?�pdV��~�:Q��%{ӑ}F��e����#{L!
�w��/1�*ǸKC��I����E:��aGk�_i��94�8@�˯b����+���Xo�41�b�F��,��=͸�{�������ݱ9]�LK�F�+�l=�ő�~=Ƹg�i86�i�#�:��J:S���}��8$��#=��pB%�g�J(S��Q"�>�ο�u���Mid�!1ڙrCѲ�0���u��? ˶�	��`Z��ѹh8/?�����Б}=n�<vs���5|Ž�������Ad�a��1�Y�]7����RB�k���C��<ѿ��i���aV��B�����l\��U�>,DwT2��d
,���=�a�K���(�-�Pp��||�v�G|����k(���7L�����g��.�Q���U[HEXpOzGh��Vv9����̅V��B���8ܴ_/(҇��q����,%(b%�ײ�炧�YP ߐD����q�S����Ʒe�l��w0��'�o�04�i|.v�q�!�
J���6���>�S��R(T���T
����& OqܢR/�	$��C�8[�(��0n�5��r����N/�P�8�gżT`��>N�q@սLI6-p���[UR$5� �	�^��D9�f�l@F�z�����ȲF��̺�S@����QZJK���6��L�ER�Ҷ�(�8���,�SO��C<�eޱ'Dln�n�� ށ9��5A�D"4�G�(�g�**�Й�+���d9��d���	�s�nLPK��#�~���+Ӫ�F��/^��@����8��&缜V	`n@l!�k�	�b�{�ůx�U��}#!

� �/%�=�Q�֖�)�-�?7`˷���s8@��)\���jc��T���s�J��=X6[f9��U\�k�����;��&;5w{��%A+HV��aM�:��1SyK"�N:��+��oJy���(�G������gO���O�TB�<v�n��u˾�}�Ǿ��>A3��H�֪
I�YA�k{,B�x$OcA %���`�+�bzIc*s�ۡ��H����Kv�4)C��Ȍ'+��$A+�-�"PO$��v>愼��98b�����e<����l��8(Ӑ(1Ç��o��%���Y���2	f4/O;[�����zNc��4e�da��V�v�z�����G�p#}�+���.�֞�&+�O����O�^Ɇ���k�6�̿	���+��u"�G�%���p��>��C�"	�f�GbD!Z�5�F�Oa��y��� M�l�K��R�dw@#�<'c�\�H�V��KQ+���k��0�s���C7�q���S�-M��������O��"k�Jh� �.6�H���=!��[3�*'*�lu��|�杨8����8�ղ!��i����P8�7T�e�m�I�\Iak}[��q1�i1!��Hd��k��)�Z	MX)aJ��6�������;���OM
!\�L�aBp�г�U#��jl��m+�E5$�Y�"촷y�'���238�$eEh��4�C\����"������Ǉ�A��dV٠�=�e5J(��6�X�f��]m[uɚ��w�~-���XYM���i��n�\�\�#��55b���Rl]����p����+�n��me4�����yU�j��W����0��]�?�.=s���Dj^��X��<�?�N9���y�=��8��ԿX�{Y���@���dg�<����偆@�,8u��lt2�q��X�8��q� m+�~U���1.�},�n��R�4�?�Ì��>lᥨ�ъ�a�S��z�bC�|xK��^	�!�-�F?�avώ�N[J�9��;�$�"R��ZC�:����B��¸��&5G�S��z�)=R�%�+�3<D���B�u�.�z^�0�].���L��#2��	٘�14�hϘ%3�)�ʴ/��&��Ko�����Q�h��j$,q�st���k�~�ڻ�x��B󜌚c�ؗi�OӮ�����l<I� ^)M=	���f*Dt=�60x��Z!�Ut���`����>�$��˸N��B�,R��YF]:z��Y��!�4�GG,x5�ޡc}=���#:A��8�*���>�k�u|�c?e�`�E[�۶V5����پ�e�IOfj�`9�Y�~aq`�v�����PZ|��ш�p��x+~�cX�y$���:o�*��z�QR�e�n����{�ťW筂%�^�m3W�o��ԉ�؉�<�V��0M�[����<�C��/Wu1�oL�x;"S���!�gܐ����6[�/�W&�(S�E@�A���-j����Lz}X�O���*0� �]&AMg@�������[�]ly��$�Z?2��JR|�(��fӦ+�:ji�\��9�n��	N;��l(�H�X�����	� A�_�|��	M�)�J �d�r#��G���ʻ�#]�JO�9��JQE����)�;ք�"�*��]��șH��ӕs#Zlqid.#��f�@�imL�����~<��5_i��0
%�U�uZF#� k��VG��Q��U\�ȀJa<�B3�]G 鿧��~K��J� yvۍ�A�����~"��� 9+6-<����Q��k�E���XW.$��-s�3�_�,W��[�j�	�.@$ �(=��Q���L=2��@�}�e�#rD_��A 6מ�w�P0\\j���C8�����P��0B�,�'#G��V%�u���qP��qa~��}"�����Wz��?Ք[�Ba!w0k����≠���O�y��s4�ݺ;4yl�0���&LӜ�g��c���da��g~
K�8	P!T��8.[�>�g)��Ө	�GO�Ǜ�� Z�]%%ɉ��Nץzy۰�RQy����p)п`�*w1�Ʊt�ǘ��8�W\�R�R�kŰ-cU����H|�V��U�K�׺�֩p$�h��l�\�}��}9d��-�G���]�_���E��e����pf�ޓƐAu���ΐMr�^��w�����!�aȧ�1|(��,M`�����p8��o!sŒԛ"�1���E���`���s���Nb�'Gq��:ܾ?R-:��1e"��_/% ���]X�;2�*��8y�R�J�h1�.�-?�/�e��M� >���"UI@�?�����wJ�~�g��i@�.iQ
���� MT�yKԽu�ײ��,���oC��1�ۈ�E�:�A���U��a�������4-"��2*/KA�s ����q��:�"�@�zh��s��f�� w�g4 Ƀbjz���Шv�j���k��AU�� �V*�eU�%�.8�w��'MN�s�\��Y:��*�jN����n��V9��P�d��\b��C�P�d6���ʩI|���.��
uV���	�=P�������K顂feE��JQ�}�v�HPog��idn����)��s$E'���j�4зʦ78���y2��(4.�^��j��D�y�v;X��� ���� �Ե˳b*�����RΕ^~{(�u~�(?�@��f�%�?��*��	��{]1�v��f�O�l[�w�f`�����4%G_W֟������^L�F7��zβ���%�F ��P �  ͩ�!$BN��d���e\
�
jt�c^�֠��i��W�O�C�u��!�M�F����<��6�NHk+ip��Q�6�>؂쭈�������J���%GVoH�v��a�TAp��p��@g85��`�X@�ʍ1h����H��k��UWhHӝ���0 �<Ė����D�����l|�$���D���жp��7fR�~�k�7�:=AXa~�܏[�k��H�i��%z44x����`��a�6�+�6a��˗?+K��J�it���$e �奩v6�i�OC8���S�ZE�Gq�����4O���C�<��%i5�$^�tWG��	65�h���i)�B㟀'���d���<j�,;pU�����[��`�G8bt���U(���e�����^�I�����������>%�V;�Z1�%��%�hNCm��eG�K@����8!�W�bQ����_�墎�k�D��4a,s���%�c�
� � ۗ��r	P�� >�q�xQ���9��#'���-i�፤��ÿ�����4�����������֣��Գ[�Ù2^��Đ�
����%IYc�1=�V�9��Q� �I�~�h�S8���2C���F��B�o� �Q?�\G�uwϮ�5�m�t��=Xr����o�� [�Vh��Y�}��f=%
�O;������?����hj�     