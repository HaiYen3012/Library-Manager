import tkinter as tk
from tkinter import messagebox
import psycopg2
import tempCodeRunnerFile

def create_member_account():
    # Retrieve member information from entry fields
    first_name = entry_first_name.get()
    last_name = entry_last_name.get()
    address = entry_address.get()
    date_of_birth = entry_date_of_birth.get()
    phone = entry_phone.get()
    email = entry_email.get()
    expire_date = entry_expire_date.get()

    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        # Insert member information into Members table
        cursor.execute("INSERT INTO Members (first_name, last_name, address, date_of_birth, phone, email, expire_date) VALUES (%s, %s, %s, %s, %s, %s, %s)", 
                       (first_name, last_name, address, date_of_birth, phone, email, expire_date))
        conn.commit()

        messagebox.showinfo("Success", "Member account created successfully.")

    except (Exception, psycopg2.Error) as error:
        messagebox.showerror("Error", f"Error while creating member account: {error}")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Create GUI window
root = tk.Tk()
root.title("Create Member Account")

# Label and entry fields for member information
label_first_name = tk.Label(root, text="First Name:")
label_first_name.grid(row=0, column=0, padx=5, pady=5, sticky="e")
entry_first_name = tk.Entry(root)
entry_first_name.grid(row=0, column=1, padx=5, pady=5)

label_last_name = tk.Label(root, text="Last Name:")
label_last_name.grid(row=1, column=0, padx=5, pady=5, sticky="e")
entry_last_name = tk.Entry(root)
entry_last_name.grid(row=1, column=1, padx=5, pady=5)

label_address = tk.Label(root, text="Address:")
label_address.grid(row=2, column=0, padx=5, pady=5, sticky="e")
entry_address = tk.Entry(root)
entry_address.grid(row=2, column=1, padx=5, pady=5)

label_date_of_birth = tk.Label(root, text="Date of Birth:")
label_date_of_birth.grid(row=3, column=0, padx=5, pady=5, sticky="e")
entry_date_of_birth = tk.Entry(root)
entry_date_of_birth.grid(row=3, column=1, padx=5, pady=5)

label_phone = tk.Label(root, text="Phone:")
label_phone.grid(row=4, column=0, padx=5, pady=5, sticky="e")
entry_phone = tk.Entry(root)
entry_phone.grid(row=4, column=1, padx=5, pady=5)

label_email = tk.Label(root, text="Email:")
label_email.grid(row=5, column=0, padx=5, pady=5, sticky="e")
entry_email = tk.Entry(root)
entry_email.grid(row=5, column=1, padx=5, pady=5)

label_expire_date = tk.Label(root, text="Expire Date:")
label_expire_date.grid(row=6, column=0, padx=5, pady=5, sticky="e")
entry_expire_date = tk.Entry(root)
entry_expire_date.grid(row=6, column=1, padx=5, pady=5)

# Button to create member account
btn_create_account = tk.Button(root, text="Create Account", command=create_member_account)
btn_create_account.grid(row=7, column=1, padx=5, pady=10)

root.mainloop()
