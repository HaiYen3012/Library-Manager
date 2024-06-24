import tkinter as tk
from tkinter import messagebox
import psycopg2
import tempCodeRunnerFile

def create_borrowed_book_record():
    receipt_id = entry_receipt_id.get()
    book_id = entry_book_id.get()
    quantity = entry_quantity.get()
    status = entry_status.get()

    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        # Truy vấn SQL để chèn bản ghi vào bảng Borrowed_Books
        cursor.execute(
            """
            INSERT INTO Borrowed_Books (receipt_id, book_id, quantity, status)
            VALUES (%s, %s, %s, %s)
            """,
            (receipt_id, book_id, quantity, status)
        )
        
        conn.commit()
        messagebox.showinfo("Success", "Borrowed book record created successfully.")

    except (Exception, psycopg2.Error) as error:
        messagebox.showerror("Error", f"Error while creating borrowed book record: {error}")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Tạo cửa sổ
root = tk.Tk()
root.title("Create Borrowed Book Record")

# Nhãn và ô nhập liệu cho receipt_id
label_receipt_id = tk.Label(root, text="Receipt ID:")
label_receipt_id.grid(row=0, column=0, sticky="e")
entry_receipt_id = tk.Entry(root)
entry_receipt_id.grid(row=0, column=1)

# Nhãn và ô nhập liệu cho book_id
label_book_id = tk.Label(root, text="Book ID:")
label_book_id.grid(row=1, column=0, sticky="e")
entry_book_id = tk.Entry(root)
entry_book_id.grid(row=1, column=1)

# Nhãn và ô nhập liệu cho quantity
label_quantity = tk.Label(root, text="Quantity:")
label_quantity.grid(row=2, column=0, sticky="e")
entry_quantity = tk.Entry(root)
entry_quantity.grid(row=2, column=1)

# Nhãn và ô nhập liệu cho status
label_status = tk.Label(root, text="Status:")
label_status.grid(row=3, column=0, sticky="e")
entry_status = tk.Entry(root)
entry_status.grid(row=3, column=1)

# Nút tạo bản ghi mượn sách
btn_create_record = tk.Button(root, text="Create Borrowed Book Record", command=create_borrowed_book_record)
btn_create_record.grid(row=4, column=1, pady=10)

root.mainloop()
