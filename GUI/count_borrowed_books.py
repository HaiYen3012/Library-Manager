import tkinter as tk
from tkinter import messagebox
import psycopg2
import tempCodeRunnerFile

# Function to count total borrowed quantity of books for a member
def count_borrowed_quantity():
    member_account_id = entry_member_account_id.get()

    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        # SQL query to count total borrowed quantity of books for the member with given member_account_id
        cursor.execute("""
            SELECT SUM(b.quantity) AS total_quantity
            FROM Borrowing_Receipts r
            JOIN Borrowed_Books b ON r.receipt_id = b.receipt_id
            WHERE r.member_account_id = %s AND r.status = 'borrowed'
        """, (member_account_id,))
        
        total_quantity = cursor.fetchone()[0]
        if total_quantity is None:
            total_quantity = 0
        
        messagebox.showinfo("Result", f"Total borrowed quantity: {total_quantity}")

    except (Exception, psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL", error)
        messagebox.showerror("Error", "Failed to count borrowed quantity!")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Create GUI
root = tk.Tk()
root.title("Count Borrowed Quantity")

# Labels and Entry fields
label_member_account_id = tk.Label(root, text="Member Account ID:")
label_member_account_id.grid(row=0, column=0, padx=10, pady=10)

entry_member_account_id = tk.Entry(root)
entry_member_account_id.grid(row=0, column=1, padx=10, pady=10)

# Button to count total borrowed quantity
btn_count_quantity = tk.Button(root, text="Count Borrowed Quantity", command=count_borrowed_quantity)
btn_count_quantity.grid(row=1, column=1, padx=10, pady=10)

root.mainloop()
