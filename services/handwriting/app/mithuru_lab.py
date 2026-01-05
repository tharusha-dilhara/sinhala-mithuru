import tkinter as tk
from tkinter import messagebox
import requests
import json

class SinhalaMithuruLab:
    def __init__(self, root):
        self.root = root
        self.root.title("🔬 Sinhala Mithuru - Research Grade Tester")
        self.root.geometry("650x900")
        self.root.configure(bg="#f4f7f6")

        # --- පර්යේෂණාත්මක පරාමිතීන් (Based on index.html) ---
        self.API_URL = "http://localhost:8000/evaluate"
        self.canvas_size = 600
        self.strokes = []
        self.current_stroke = []
        self.last_x, self.last_y = None, None

        # --- UI ව්‍යුහය ---
        tk.Label(root, text="Level එකට අදාළ අකුර (e.g. Aa, G):", bg="#f4f7f6", font=("Arial", 12)).pack(pady=5)
        self.char_input = tk.Entry(root, font=("Arial", 14), justify='center', width=10)
        self.char_input.insert(0, "Aa") 
        self.char_input.pack(pady=5)

        # 600x600 Drawing Canvas
        self.canvas = tk.Canvas(root, width=self.canvas_size, height=self.canvas_size, 
                                bg="white", highlightthickness=2, highlightbackground="#2d3436")
        self.canvas.pack(pady=10)

        # Event Binding (Drawing)
        self.canvas.bind("<Button-1>", self.start_stroke)
        self.canvas.bind("<B1-Motion>", self.draw_stroke)
        self.canvas.bind("<ButtonRelease-1>", self.end_stroke)

        # Controls
        self.btn_frame = tk.Frame(root, bg="#f4f7f6")
        self.btn_frame.pack(pady=10)

        self.clear_btn = tk.Button(self.btn_frame, text="Clear Canvas", command=self.clear_canvas, 
                                    font=("Arial", 12), bg="#ff512f", fg="white", width=12)
        self.clear_btn.grid(row=0, column=0, padx=10)

        self.test_btn = tk.Button(self.btn_frame, text="Analyze (API)", command=self.send_to_backend, 
                                 font=("Arial", 12, "bold"), bg="#27ae60", fg="white", width=15)
        self.test_btn.grid(row=0, column=1, padx=10)

        # Result Display
        self.result_var = tk.StringVar(value="අකුරක් ඇඳ Analyze බොත්තම ඔබන්න.")
        self.result_label = tk.Label(root, textvariable=self.result_var, font=("Arial", 13), 
                                     bg="#f4f7f6", justify="left", wraplength=550)
        self.result_label.pack(pady=20)

    # --- drawing Logic (Replicating index.html Exactly) ---
    def start_stroke(self, event):
        self.last_x, self.last_y = event.x, event.y
        # p=0 (Pen down/moving)
        self.current_stroke = [{'x': event.x, 'y': event.y, 'dx': 0, 'dy': 0, 'p': 0}]

    def draw_stroke(self, event):
        if self.last_x is not None and self.last_y is not None:
            # dx, dy ගණනය කිරීම (Exactly matching collection tool)
            dx = event.x - self.last_x
            dy = event.y - self.last_y
            
            # Canvas එකේ ඇඳීම
            self.canvas.create_line(self.last_x, self.last_y, event.x, event.y, 
                                    width=5, fill="black", capstyle=tk.ROUND, smooth=tk.TRUE)
            
            self.current_stroke.append({'x': event.x, 'y': event.y, 'dx': dx, 'dy': dy, 'p': 0})
            self.last_x, self.last_y = event.x, event.y

    def end_stroke(self, event):
        if self.current_stroke:
            self.strokes.append(self.current_stroke)
        self.last_x, self.last_y = None, None

    def clear_canvas(self):
        self.canvas.delete("all")
        self.strokes = []
        self.result_var.set("කැන්වසය පිරිසිදු කරන ලදී. අකුර අඳින්න.")

    # --- API Communication ---
    def send_to_backend(self):
        if not self.strokes:
            messagebox.showwarning("Warning", "කරුණාකර අකුරක් අඳින්න!")
            return

        expected = self.char_input.get().strip()
        
        # දත්ත JSON ව්‍යුහය
        payload = {
            "expected_char": expected,
            "strokes": self.strokes
        }

        try:
            self.result_var.set("⏳ Backend එක හරහා විශ්ලේෂණය වෙමින් පවතී...")
            self.root.update()
            
            response = requests.post(self.API_URL, json=payload, timeout=10)
            
            if response.status_code == 200:
                res = response.json()['analysis']
                is_correct = res['is_correct_letter']
                identified = res['identified_letter_symbol']
                quality = res['quality_percentage']
                
                # --- තරු ගණනය කිරීම (1 - 5) ---
                # මෙහිදී ප්‍රතිශතය 20න් බෙදා ආසන්නතම පූර්ණ සංඛ්‍යාව ලබා ගනී
                star_count = max(1, min(5, round(quality / 20)))
                stars = "⭐" * star_count
                
                if is_correct:
                    output = f"විශිෂ්ටයි! ✅ ඔබ ' {identified} ' අකුර නිවැරදිව ලිව්වා.\n"
                else:
                    output = f"වැරදියි! ❌ ඔබ ලියා ඇත්තේ ' {identified} ' අකුරයි.\n"
                    output += f"(බලාපොරොත්තු වූයේ: {self.char_input.get()} )\n"
                
                # තරු සහ ප්‍රතිශතය එක් කිරීම
                output += f"✨ ගුණාත්මකභාවය: {quality}% ({stars})\n"
                
                self.result_var.set(output)
            else:
                self.result_var.set(f"❌ API දෝෂයකි: {response.text}")

        except Exception as e:
            self.result_var.set(f"❌ Backend එක සමඟ සම්බන්ධ විය නොහැක: {str(e)}")

if __name__ == "__main__":
    root = tk.Tk()
    app = SinhalaMithuruLab(root)
    root.mainloop()