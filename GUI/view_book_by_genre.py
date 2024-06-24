import tkinter as tk
from tkinter import ttk
import psycopg2
import tempCodeRunnerFile

def connect_to_db():
    try:
        conn = tempCodeRunnerFile._conn    
        return conn   
    except Exception as error:
        print("Error while connecting to PostgreSQL", error)
        return None

def search_books_by_genre():
    # Xóa tất cả các hàng trong cây trước khi thêm kết quả tìm kiếm mới
    for row in tree.get_children():
        tree.delete(row)

    # Lấy thể loại sách từ ô nhập liệu
    genre_name = entry_genre.get()

    conn = connect_to_db()
    if conn is None:
        return

    try:
        cursor = conn.cursor()

        # Tìm kiếm sách theo thể loại
        cursor.execute("SELECT * FROM books b JOIN book_Genre bg ON b.book_id = bg.book_id JOIN genres g ON bg.genre_id = g.genre_id WHERE g.genre_name = %s", (genre_name,))
        books = cursor.fetchall()

        # Hiển thị kết quả tìm kiếm trên cây
        for book in books:
            tree.insert('', 'end', values=book)
            
    except (Exception, psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL", error)

    finally:
        if conn:
            cursor.close()
            conn.close()

# Tạo cửa sổ giao diện
root = tk.Tk()
root.title("Search Books by Genre")

# Nhãn và ô nhập liệu cho thể loại sách
label_genre = tk.Label(root, text="Genre:")
label_genre.grid(row=0, column=0, padx=2, pady=2, sticky="e")
entry_genre = tk.Entry(root)
entry_genre.grid(row=0, column=1, padx=2, pady=2)
entry_genre.focus()  # Đặt con trỏ vào ô nhập liệu thể loại sách mặc định

# Nút tìm kiếm
btn_search = tk.Button(root, text="Search", command=search_books_by_genre)
btn_search.grid(row=0, column=2, padx=2, pady=2)

# Tạo cây để hiển thị kết quả tìm kiếm
tree = ttk.Treeview(root, columns=("Book ID", "Book Name", "Publisher", "Publication Year", "Available", "Quantity", "Price"), show='headings')
tree.heading("Book ID", text="Book ID")
tree.heading("Book Name", text="Book Name")
tree.heading("Publisher", text="Publisher")
tree.heading("Publication Year", text="Publication Year")
tree.heading("Available", text="Available")
tree.heading("Quantity", text="Quantity")
tree.heading("Price", text="Price")

# Độ rộng của các cột
tree.column("Book ID", width=100)
tree.column("Book Name", width=150)
tree.column("Publisher", width=150)
tree.column("Publication Year", width=130)
tree.column("Available", width=100)
tree.column("Quantity", width=100)
tree.column("Price", width=100)

tree.grid(row=1, column=0, columnspan=3, padx=2, pady=2, sticky='nsew')

# Scrollbar
scrollbar = ttk.Scrollbar(root, orient=tk.VERTICAL, command=tree.yview)
tree.configure(yscroll=scrollbar.set)
scrollbar.grid(row=1, column=3, sticky='ns')

root.mainloop()
