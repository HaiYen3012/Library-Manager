import tkinter as tk
from tkinter import messagebox
import psycopg2
import tempCodeRunnerFile

def update_member():
    member_id = entry_member_id.get()
    new_first_name = entry_first_name.get()
    new_last_name = entry_last_name.get()
    new_address = entry_address.get()
    new_date_of_birth = entry_date_of_birth.get()
    new_phone = entry_phone.get()
    new_email = entry_email.get()
    new_expire_date = entry_expire_date.get()
    
    try:
        conn = tempCodeRunnerFile._conn
        cursor = conn.cursor()

        cursor.execute("UPDATE Members SET first_name = %s, last_name = %s, address = %s, date_of_birth = %s, phone = %s, email = %s, expire_date = %s WHERE account_id = %s",
                       (new_first_name, new_last_name, new_address, new_date_of_birth, new_phone, new_email, new_expire_date, member_id))
        
        conn.commit()
        messagebox.showinfo("Success", "Member information updated successfully.")

    except (Exception, psycopg2.Error) as error:
        messagebox.showerror("Error", f"Error while updating member: {error}")

    finally:
        if conn:
            cursor.close()
            conn.close()

# Tạo cửa sổ
root = tk.Tk()
root.title("Update Member Information")

# Tạo các nhãn và ô nhập liệu cho thông tin thành viên
labels = ["Member ID:", "First Name:", "Last Name:", "Address:", "Date of Birth (YYYY-MM-DD):", "Phone:", "Email:", "Expire Date (YYYY-MM-DD):"]
for i, label_text in enumerate(labels):
    label = tk.Label(root, text=label_text)
    label.grid(row=i, column=0, sticky="e")

entry_member_id = tk.Entry(root)
entry_member_id.grid(row=0, column=1)
entry_first_name = tk.Entry(root)
entry_first_name.grid(row=1, column=1)
entry_last_name = tk.Entry(root)
entry_last_name.grid(row=2, column=1)
entry_address = tk.Entry(root)
entry_address.grid(row=3, column=1)
entry_date_of_birth = tk.Entry(root)
entry_date_of_birth.grid(row=4, column=1)
entry_phone = tk.Entry(root)
entry_phone.grid(row=5, column=1)
entry_email = tk.Entry(root)
entry_email.grid(row=6, column=1)
entry_expire_date = tk.Entry(root)
entry_expire_date.grid(row=7, column=1)

# Tạo nút cập nhật
btn_update_member = tk.Button(root, text="Update Member", command=update_member)
btn_update_member.grid(row=8, column=1, pady=10)

root.mainloop()
