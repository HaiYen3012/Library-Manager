import tkinter as tk
from tkinter import messagebox
import psycopg2

def delete_genre():
    genre_id = entry_genre_id.get()
    
    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        # Truy vấn SQL để xóa các liên kết từ bảng Book_Genre dựa trên genre_id
        cursor.execute("DELETE FROM Book_Genre WHERE genre_id = %s", (genre_id,))
        
        # Tiếp theo, xóa thể loại từ bảng Genres dựa trên genre_id
        cursor.execute("DELETE FROM Genres WHERE genre_id = %s", (genre_id,))
        
        conn.commit()
        messagebox.showinfo("Success", "Genre and its associations deleted successfully.")

    except (Exception, psycopg2.Error) as error:
        messagebox.showerror("Error", f"Error while deleting genre: {error}")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Tạo cửa sổ
root = tk.Tk()
root.title("Delete Genre")

# Nhãn và ô nhập liệu cho genre_id
label_genre_id = tk.Label(root, text="Genre ID:")
label_genre_id.grid(row=0, column=0, sticky="e")

entry_genre_id = tk.Entry(root)
entry_genre_id.grid(row=0, column=1)

# Nút xóa
btn_delete_genre = tk.Button(root, text="Delete Genre", command=delete_genre)
btn_delete_genre.grid(row=1, column=1, pady=10)

root.mainloop()
