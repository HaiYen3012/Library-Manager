import tkinter as tk
from tkinter import messagebox
import psycopg2

def insert_author():
    author_id = entry_author_id.get()
    first_name = entry_first_name.get()
    last_name = entry_last_name.get()
    nationality = entry_nationality.get()

    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        cursor.execute("INSERT INTO Authors VALUES (%s, %s, %s, %s)",
                       (author_id, first_name, last_name, nationality))
        
        conn.commit()
        messagebox.showinfo("Success", "Author inserted successfully!")
        
    except (Exception, psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL", error)
        messagebox.showerror("Error", "Failed to insert author!")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Create GUI
root = tk.Tk()
root.title("Insert New Author")

# Labels
labels = ["Author ID:", "First Name:", "Last Name:", "Nationality:"]
for i, label_text in enumerate(labels):
    label = tk.Label(root, text=label_text)
    label.grid(row=i, column=0, sticky="e")

# Entry fields
entry_author_id = tk.Entry(root)
entry_author_id.grid(row=0, column=1)
entry_first_name = tk.Entry(root)
entry_first_name.grid(row=1, column=1)
entry_last_name = tk.Entry(root)
entry_last_name.grid(row=2, column=1)
entry_nationality = tk.Entry(root)
entry_nationality.grid(row=3, column=1)

# Button
btn_insert = tk.Button(root, text="Insert Author", command=insert_author)
btn_insert.grid(row=4, column=1, pady=10)

root.mainloop()
