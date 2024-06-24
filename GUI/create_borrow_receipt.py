import tkinter as tk
from tkinter import messagebox
import psycopg2
import tempCodeRunnerFile

def create_borrowing_receipt():
    receipt_id = entry_receipt_id.get()
    employee_account_id = entry_employee_account_id.get()
    member_account_id = entry_member_account_id.get()
    borrow_date = entry_borrow_date.get()
    due_date = entry_due_date.get()

    # Đặt giá trị mặc định cho fee, return_date và status
    fee = None
    return_date = None
    status = 'borrowed'

    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        cursor.execute("""
            INSERT INTO Borrowing_Receipts (receipt_id, employee_account_id, member_account_id, fee, borrow_date, due_date, return_date, status)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (receipt_id, employee_account_id, member_account_id, fee, borrow_date, due_date, return_date, status))
        
        conn.commit()
        messagebox.showinfo("Success", "Borrowing receipt created successfully!")
        
    except (Exception, psycopg2.Error) as error:
        print("Error while connecting to PostgreSQL", error)
        messagebox.showerror("Error", "Failed to create borrowing receipt!")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Create GUI
root = tk.Tk()
root.title("Create Borrowing Receipt")

# Labels
labels = ["Receipt ID:", "Employee Account ID:", "Member Account ID:", "Borrow Date:", "Due Date:"]
for i, label_text in enumerate(labels):
    label = tk.Label(root, text=label_text)
    label.grid(row=i, column=0, sticky="e")

# Entry fields
entry_receipt_id = tk.Entry(root)
entry_receipt_id.grid(row=0, column=1)
entry_employee_account_id = tk.Entry(root)
entry_employee_account_id.grid(row=1, column=1)
entry_member_account_id = tk.Entry(root)
entry_member_account_id.grid(row=2, column=1)
entry_borrow_date = tk.Entry(root)
entry_borrow_date.grid(row=3, column=1)
entry_due_date = tk.Entry(root)
entry_due_date.grid(row=4, column=1)

# Button
btn_create_receipt = tk.Button(root, text="Create Borrowing Receipt", command=create_borrowing_receipt)
btn_create_receipt.grid(row=5, column=1, pady=10)

root.mainloop()
