import tkinter as tk
from tkinter import messagebox
import psycopg2

def insert_book():
    book_id = entry_book_id.get()
    book_name = entry_book_name.get()
    age_group_id = entry_age_group_id.get()
    publisher_id = entry_publisher_id.get()
    publication_year = int(entry_publication_year.get())
    available = int(entry_available.get())
    quantity = int(entry_quantity.get())
    price = int(entry_price.get())

    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        cursor.execute("INSERT INTO Books VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                       (book_id, book_name, age_group_id, publisher_id, publication_year, available, quantity, price))
        
        conn.commit()
        messagebox.showinfo("Success", "Book inserted successfully!")
        
    except (Exception, psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL", error)
        messagebox.showerror("Error", "Failed to insert book!")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Create GUI
root = tk.Tk()
root.title("Insert New Book")

# Labels
labels = ["Book ID:", "Book Name:", "Age Group ID:", "Publisher ID:", "Publication Year:", "Available:", "Quantity:", "Price:"]
for i, label_text in enumerate(labels):
    label = tk.Label(root, text=label_text)
    label.grid(row=i, column=0, sticky="e")

# Entry fields
entry_book_id = tk.Entry(root)
entry_book_id.grid(row=0, column=1)
entry_book_name = tk.Entry(root)
entry_book_name.grid(row=1, column=1)
entry_age_group_id = tk.Entry(root)
entry_age_group_id.grid(row=2, column=1)
entry_publisher_id = tk.Entry(root)
entry_publisher_id.grid(row=3, column=1)
entry_publication_year = tk.Entry(root)
entry_publication_year.grid(row=4, column=1)
entry_available = tk.Entry(root)
entry_available.grid(row=5, column=1)
entry_quantity = tk.Entry(root)
entry_quantity.grid(row=6, column=1)
entry_price = tk.Entry(root)
entry_price.grid(row=7, column=1)

# Button
btn_insert = tk.Button(root, text="Insert Book", command=insert_book)
btn_insert.grid(row=8, column=1, pady=10)

root.mainloop()
