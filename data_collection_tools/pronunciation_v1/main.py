import customtkinter as ctk
import tkinter as tk
import pyaudio
import wave
import threading
import time
import os
import numpy as np
from scipy.io import wavfile
import math
import datetime
import ctypes 
from PIL import Image, ImageTk

# --- Configuration ---
SAMPLE_RATE = 16000
CHANNELS = 1
CHUNK = 1024
FORMAT = pyaudio.paInt16
OUTPUT_FOLDER = "dataset_audio"

# --- Premium Color Palette with Gradients ---
COLOR_PRIMARY = "#6366f1"
COLOR_PRIMARY_DARK = "#4f46e5"
COLOR_PRIMARY_LIGHT = "#818cf8"
COLOR_ACCENT = "#ec4899"
COLOR_BG = "#f8fafc"
COLOR_CARD = "#ffffff"
COLOR_TEXT = "#0f172a"
COLOR_TEXT_SECONDARY = "#64748b"
COLOR_RECORDING = "#ef4444"
COLOR_SAVING = "#f59e0b"
COLOR_SUCCESS = "#10b981"
COLOR_DELETE = "#ef4444"
COLOR_HOVER_RED = "#fee2e2"
COLOR_GLASS_BG = "#ffffff"

ctk.set_appearance_mode("Light")
ctk.set_default_color_theme("blue")


# ====================================================
# 🎨 Toast Notification System
# ====================================================
class Toast(ctk.CTkFrame):
    def __init__(self, parent, message, type="info"):
        super().__init__(parent, fg_color=COLOR_CARD, corner_radius=12, 
                        border_width=2, border_color="#e2e8f0")
        
        colors = {
            "success": ("✓", COLOR_SUCCESS),
            "error": ("✕", COLOR_RECORDING),
            "info": ("ⓘ", COLOR_PRIMARY)
        }
        icon, color = colors.get(type, colors["info"])
        
        ctk.CTkLabel(self, text=icon, font=("Arial", 20, "bold"), 
                    text_color=color, width=30).pack(side="left", padx=(15, 5))
        ctk.CTkLabel(self, text=message, font=("Segoe UI", 12), 
                    text_color=COLOR_TEXT).pack(side="left", padx=(0, 15), pady=12)
        
        self.place(relx=0.5, y=-100, anchor="n")
        self.animate_in()
    
    def animate_in(self):
        self.lift()
        for i in range(20):
            y = -100 + (i/20) * 130
            self.place(relx=0.5, y=y, anchor="n")
            self.update()
            time.sleep(0.015)
        self.after(2500, self.animate_out)
    
    def animate_out(self):
        for i in range(20):
            y = 30 - (i/20) * 130
            self.place(relx=0.5, y=y, anchor="n")
            self.update()
            time.sleep(0.015)
        self.destroy()


# ====================================================
# 🎨 Enhanced Circular Play Button with Glow
# ====================================================
class CircularPlayButton(tk.Canvas):
    def __init__(self, master, command, size=44, **kwargs):
        super().__init__(master, width=size, height=size, bg=COLOR_CARD, 
                         highlightthickness=0, cursor="hand2", **kwargs)
        self.command = command
        self.size = size
        self.is_playing = False
        self.progress = 0.0
        self.hover = False
        
        self.bind("<Button-1>", self.on_click)
        self.bind("<Enter>", self.on_enter)
        self.bind("<Leave>", self.on_leave)
        
        self.draw()

    def draw(self):
        self.delete("all")
        center = self.size / 2
        
        if self.hover:
            for r in range(3):
                alpha = 50 - r*15
                self.create_oval(2-r, 2-r, self.size-2+r, self.size-2+r, 
                               outline=f"#{hex(int(99+alpha))[2:]:0>2}{hex(int(102+alpha))[2:]:0>2}f1", 
                               width=1)
        
        grad_color = "#eef2ff" if self.hover else "#f1f5f9"
        self.create_oval(4, 4, self.size-4, self.size-4, 
                        outline="#e0e7ff", fill=grad_color, width=1)

        if self.progress > 0:
            extent = -360 * self.progress
            self.create_arc(3, 3, self.size-3, self.size-3, 
                          start=90, extent=extent, 
                          style="arc", outline=COLOR_PRIMARY, width=3.5)

        icon_size = self.size / 3.2
        icon_color = COLOR_PRIMARY if self.hover else "#475569"
        
        if self.is_playing:
            bar_width = icon_size / 2.8
            gap = icon_size / 4
            self.create_rectangle(center - bar_width - gap/2, center - icon_size/2,
                                center - gap/2, center + icon_size/2,
                                fill=icon_color, outline="")
            self.create_rectangle(center + gap/2, center - icon_size/2,
                                center + bar_width + gap/2, center + icon_size/2,
                                fill=icon_color, outline="")
        else:
            points = [
                center - icon_size/3 + 2, center - icon_size/2,
                center - icon_size/3 + 2, center + icon_size/2,
                center + icon_size/1.8 + 2, center
            ]
            self.create_polygon(points, fill=icon_color, outline="")

    def set_progress(self, value):
        self.progress = value
        self.draw()

    def set_state(self, playing):
        self.is_playing = playing
        if not playing:
            self.progress = 0.0
        self.draw()

    def on_enter(self, event):
        self.hover = True
        self.draw()

    def on_leave(self, event):
        self.hover = False
        self.draw()

    def on_click(self, event):
        if self.command:
            self.command()


# ====================================================
# 🎨 Premium Recording Button with Logo
# ====================================================
class RecordingButton(tk.Canvas):
    def __init__(self, master, size=130, **kwargs):
        super().__init__(master, width=size, height=size, 
                         bg=COLOR_CARD, highlightthickness=0, cursor="hand2", **kwargs)
        self.size = size
        self.is_recording = False
        self.pulse_phase = 0
        self.animation_running = False
        self.hover = False
        
        try:
            pil_image = Image.open("logo.ico").resize((60, 60), Image.Resampling.LANCZOS)
            self.logo_icon = ImageTk.PhotoImage(pil_image)
        except Exception as e:
            self.logo_icon = None

        self.bind("<Enter>", lambda e: self.set_hover(True))
        self.bind("<Leave>", lambda e: self.set_hover(False))
        self.draw()

    def set_hover(self, state):
        self.hover = state
        self.draw()

    def draw(self):
        self.delete("all")
        center = self.size / 2
        
        if self.is_recording:
            for i in range(3):
                phase_offset = i * math.pi / 3
                radius = 45 + math.sin(self.pulse_phase + phase_offset) * 8
                self.create_oval(center - radius, center - radius,
                               center + radius, center + radius,
                               outline=COLOR_RECORDING, width=2, 
                               dash=(6, 6))
            
            self.create_oval(center-35, center-35, center+35, center+35,
                           outline=COLOR_RECORDING, fill="#fee2e2", width=0)
            
            size = 28
            self.create_rectangle(center - size/2, center - size/2,
                                center + size/2, center + size/2,
                                fill=COLOR_RECORDING, outline="")
        else:
            if self.logo_icon:
                self.create_image(center, center, image=self.logo_icon)
            else:
                self.create_text(center, center, text="MIC", fill=COLOR_PRIMARY, font=("Arial", 12, "bold"))

    def set_recording(self, state):
        self.is_recording = state
        if state and not self.animation_running:
            self.animation_running = True
            self.animate()
        elif not state:
            self.animation_running = False
        self.draw()

    def animate(self):
        if self.animation_running and self.is_recording:
            self.pulse_phase += 0.12
            self.draw()
            self.after(30, self.animate)


# ====================================================
# 🎨 Enhanced Level Meter
# ====================================================
class LevelMeter(tk.Canvas):
    def __init__(self, master, width=700, height=50, **kwargs):
        super().__init__(master, width=width, height=height, 
                         bg=COLOR_CARD, highlightthickness=0, **kwargs)
        self.width = width
        self.height = height
        self.bars = 50
        self.levels = [0] * self.bars
        
    def update_levels(self, audio_data):
        chunk_size = max(1, len(audio_data) // self.bars)
        for i in range(self.bars):
            chunk = audio_data[i * chunk_size:(i + 1) * chunk_size]
            if len(chunk) > 0:
                level = np.abs(chunk).mean() / 32768.0
                self.levels[i] = level * 0.7 + self.levels[i] * 0.3
        self.draw()
    
    def draw(self):
        self.delete("all")
        bar_w = (self.width / self.bars) - 3
        max_h = self.height - 10
        
        for i, level in enumerate(self.levels):
            h = level * max_h * 1.8
            h = min(h, max_h)
            x = i * (self.width / self.bars)
            y = self.height - h - 5
            
            if level > 0.7: color = COLOR_RECORDING
            elif level > 0.4: color = COLOR_ACCENT
            elif level > 0.2: color = COLOR_PRIMARY_LIGHT
            else: color = COLOR_PRIMARY
            
            self.create_rectangle(x + 2, y + 1, x + bar_w, self.height - 4,
                                fill="#f0f0f0", outline="")
            self.create_rectangle(x + 2, y, x + bar_w, self.height - 5,
                                fill=color, outline="")


# ====================================================
# 🚀 MAIN APP
# ====================================================
class ModernRecorderApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        try:
            myappid = 'sinhala.mithuru.recorder.v1'
            ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID(myappid)
        except:
            pass

        try:
            self.iconbitmap("logo.ico")
        except:
            pass

        self.title("සිංහල මිතුරු")
        self.geometry("1300x850")
        self.configure(fg_color=COLOR_BG)
        self.after(0, lambda: self.state('zoomed'))

        os.makedirs(OUTPUT_FOLDER, exist_ok=True)

        # Audio Init
        self.audio = pyaudio.PyAudio()
        self.is_recording = False
        self.frames = []
        self.stream = None
        self.file_counter = 1
        self.mic_options = self.get_input_devices()
        self.recording_start_time = None
        
        self.stop_playback_flag = False
        self.active_play_btn = None
        
        self.grid_columnconfigure(0, weight=0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        self.setup_sidebar()
        self.setup_main_area()

        # --- SMART KEY BINDINGS ---
        # Space bar only records if we are NOT in an entry
        self.bind("<KeyPress-space>", self.start_recording)
        self.bind("<KeyRelease-space>", self.stop_recording)
        self.bind("<Control-h>", lambda e: self.show_shortcuts())
        
        # Smart Click Handler: Clicking background removes focus from Entries
        self.bind("<Button-1>", self.on_global_click)

    def on_global_click(self, event):
        """
        Detects clicks on the window. If the user clicks outside of an Entry widget,
        it removes focus from the Entry, allowing Space bar to record again.
        """
        # If the clicked widget is NOT an input field, reset focus to main window
        if not isinstance(event.widget, (ctk.CTkEntry, tk.Entry, ctk.CTkComboBox)):
            self.focus_set()

    def show_toast(self, message, type="info"):
        Toast(self, message, type)

    def setup_sidebar(self):
        self.sidebar = ctk.CTkFrame(self, fg_color=COLOR_CARD, width=380, corner_radius=0)
        self.sidebar.grid(row=0, column=0, sticky="nsew", padx=(0, 2))
        self.sidebar.grid_propagate(False)
        self.sidebar.grid_rowconfigure(4, weight=1)
        self.sidebar.grid_columnconfigure(0, weight=1)

        header = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        header.grid(row=0, column=0, sticky="ew", padx=24, pady=(24, 8))
        
        ctk.CTkLabel(header, text="🎵 Recordings", font=("Segoe UI", 24, "bold"), 
                     text_color=COLOR_TEXT).pack(anchor="w")
        ctk.CTkLabel(header, text="Your audio collection", font=("Arial", 11), 
                     text_color=COLOR_TEXT_SECONDARY).pack(anchor="w", pady=(2, 0))

        stats = ctk.CTkFrame(self.sidebar, fg_color="#f8fafc", corner_radius=12, 
                            border_width=1, border_color="#e2e8f0", height=70)
        stats.grid(row=1, column=0, sticky="ew", padx=20, pady=12)
        
        stats_inner = ctk.CTkFrame(stats, fg_color="transparent")
        stats_inner.pack(expand=True)
        
        self.lbl_file_count = ctk.CTkLabel(stats_inner, text="0", 
                                          font=("Segoe UI", 32, "bold"), 
                                          text_color=COLOR_PRIMARY)
        self.lbl_file_count.pack()
        ctk.CTkLabel(stats_inner, text="Files Collected", font=("Arial", 11), 
                    text_color=COLOR_TEXT_SECONDARY).pack()

        # Search Bar
        search_frame = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        search_frame.grid(row=2, column=0, sticky="ew", padx=20, pady=(0, 10))
        
        self.search_entry = ctk.CTkEntry(search_frame, placeholder_text="🔍 Search recordings...",
                                        height=38, font=("Segoe UI", 12),
                                        border_color="#e2e8f0", fg_color="#f8fafc")
        self.search_entry.pack(fill="x")
        self.search_entry.bind("<KeyRelease>", self.on_search)

        actions = ctk.CTkFrame(self.sidebar, fg_color="transparent")
        actions.grid(row=3, column=0, sticky="ew", padx=20, pady=(0, 10))
        
        self.btn_delete_all = ctk.CTkButton(actions, text="🗑️ Clear All", height=32,
                                           fg_color=COLOR_DELETE, hover_color="#dc2626",
                                           font=("Segoe UI", 11, "bold"),
                                           command=self.delete_all_files)
        self.btn_delete_all.pack(side="left", fill="x", expand=True, padx=(0, 5))
        
        btn_shortcuts = ctk.CTkButton(actions, text="⌨️ Shortcuts", height=32,
                                     fg_color=COLOR_PRIMARY, hover_color=COLOR_PRIMARY_DARK,
                                     font=("Segoe UI", 11, "bold"),
                                     command=self.show_shortcuts)
        btn_shortcuts.pack(side="left", fill="x", expand=True, padx=(5, 0))

        self.file_list_frame = ctk.CTkScrollableFrame(self.sidebar, fg_color="transparent")
        self.file_list_frame.grid(row=4, column=0, sticky="nsew", padx=10, pady=(0, 10))
        
        self.empty_state = ctk.CTkFrame(self.file_list_frame, fg_color="transparent")
        self.empty_state.pack(expand=True, pady=50)
        ctk.CTkLabel(self.empty_state, text="📂", font=("Arial", 48)).pack()
        ctk.CTkLabel(self.empty_state, text="No recordings yet", 
                    font=("Segoe UI", 14, "bold"), text_color=COLOR_TEXT).pack(pady=(10, 5))
        ctk.CTkLabel(self.empty_state, text="Hold SPACE to start", 
                    font=("Arial", 11), text_color=COLOR_TEXT_SECONDARY).pack()
        
        self.update_file_list_initial()

    def setup_main_area(self):
        self.main_area = ctk.CTkFrame(self, fg_color="transparent")
        self.main_area.grid(row=0, column=1, sticky="nsew", padx=30, pady=30)
        self.main_area.grid_rowconfigure(2, weight=1)
        self.main_area.grid_columnconfigure(0, weight=1)

        self.setup_settings_bar()
        self.setup_control_area()
        self.setup_visualizer()

    def setup_settings_bar(self):
        bar = ctk.CTkFrame(self.main_area, fg_color=COLOR_CARD, corner_radius=16, height=100)
        bar.grid(row=0, column=0, sticky="ew", pady=(0, 20))
        
        left = ctk.CTkFrame(bar, fg_color="transparent")
        left.pack(side="left", padx=30, pady=20)
        
        ctk.CTkLabel(left, text="🎤 INPUT SOURCE", font=("Arial", 9, "bold"), 
                     text_color=COLOR_TEXT_SECONDARY).pack(anchor="w")
        
        self.mic_combo = ctk.CTkComboBox(left, values=list(self.mic_options.keys()),
                                        width=320, height=36, font=("Segoe UI", 13),
                                        border_color="#e2e8f0", button_color=COLOR_PRIMARY,
                                        dropdown_fg_color=COLOR_CARD)
        self.mic_combo.pack(anchor="w", pady=(5, 0))
        if self.mic_options: self.mic_combo.set(list(self.mic_options.keys())[0])
        # REMOVED the faulty FocusIn binding here

        right = ctk.CTkFrame(bar, fg_color="transparent")
        right.pack(side="right", padx=30, pady=20)
        
        ctk.CTkLabel(right, text="📝 FILE LABEL", font=("Arial", 9, "bold"), 
                     text_color=COLOR_TEXT_SECONDARY).pack(anchor="w")
        
        self.entry_filename = ctk.CTkEntry(right, width=320, height=36, 
                                         placeholder_text="lha_anchor",
                                         font=("Segoe UI", 14), border_color="#e2e8f0",
                                         fg_color="#f8fafc")
        self.entry_filename.pack(anchor="w", pady=(5, 0))
        self.entry_filename.insert(0, "lha_anchor")
        
        # When pressing Enter in the box, we remove focus (Stop typing)
        self.entry_filename.bind("<Return>", lambda e: self.focus_set())
        # Removed the specific Space binding, so Space now types normally in the box

    def setup_control_area(self):
        control = ctk.CTkFrame(self.main_area, fg_color=COLOR_CARD, corner_radius=20, height=280)
        control.grid(row=1, column=0, sticky="ew", pady=(0, 20))
        
        inner = ctk.CTkFrame(control, fg_color="transparent")
        inner.pack(expand=True, pady=30)
        
        self.rec_button = RecordingButton(inner, size=140)
        self.rec_button.pack()
        
        self.lbl_status = ctk.CTkLabel(inner, text="Ready to Record", 
                                      font=("Segoe UI", 32, "bold"), text_color=COLOR_PRIMARY)
        self.lbl_status.pack(pady=(20, 0))
        
        self.lbl_duration = ctk.CTkLabel(inner, text="00:00", 
                                        font=("Courier New", 20, "bold"), text_color="#94a3b8")
        self.lbl_duration.pack(pady=(5, 0))
        
        self.lbl_instruction = ctk.CTkLabel(inner, text="⌨️ Hold SPACEBAR to record • Ctrl+H for shortcuts", 
                                           font=("Arial", 11), text_color="#cbd5e1")
        self.lbl_instruction.pack(pady=(15, 0))

    def setup_visualizer(self):
        vis = ctk.CTkFrame(self.main_area, fg_color=COLOR_CARD, corner_radius=20)
        vis.grid(row=2, column=0, sticky="nsew")
        
        title_frame = ctk.CTkFrame(vis, fg_color="transparent")
        title_frame.pack(fill="x", padx=25, pady=(20, 10))
        
        ctk.CTkLabel(title_frame, text="📊 Live Audio Visualization", 
                    font=("Segoe UI", 12, "bold"), 
                    text_color=COLOR_TEXT).pack(side="left")
        
        self.lbl_quality = ctk.CTkLabel(title_frame, text="● Excellent", 
                                       font=("Arial", 10, "bold"), 
                                       text_color=COLOR_SUCCESS)
        self.lbl_quality.pack(side="right")
        
        self.level_meter = LevelMeter(vis, width=1000, height=50)
        self.level_meter.pack(fill="x", padx=25, pady=(5, 15))
        
        self.canvas_height = 220
        self.vis_canvas = tk.Canvas(vis, height=self.canvas_height, bg="#fcfcfc", 
                                    highlightthickness=0, bd=0)
        self.vis_canvas.pack(fill="both", expand=True, padx=25, pady=(0, 25))
        
        for i in range(5):
            y = (i+1) * self.canvas_height / 6
            self.vis_canvas.create_line(0, y, 3000, y, fill="#f1f5f9", width=1)
        
        self.vis_canvas.create_line(0, self.canvas_height/2, 3000, self.canvas_height/2, 
                                    fill="#e2e8f0", dash=(10, 5), width=2)

    def get_input_devices(self):
        devices = {}
        try:
            info = self.audio.get_host_api_info_by_index(0)
            for i in range(info.get('deviceCount')):
                dev = self.audio.get_device_info_by_host_api_device_index(0, i)
                if dev.get('maxInputChannels') > 0:
                    devices[dev.get('name')] = i
        except: pass
        return devices

    def start_recording(self, event):
        # CRITICAL FIX: If user is typing in an Entry/Combobox, Space should NOT record
        if isinstance(event.widget, (tk.Entry, ctk.CTkEntry, ctk.CTkComboBox)):
            return

        if not self.is_recording:
            self.is_recording = True
            self.frames = []
            self.recording_start_time = time.time()
            
            self.rec_button.set_recording(True)
            self.lbl_status.configure(text="● Recording...", text_color=COLOR_RECORDING)
            self.vis_canvas.configure(bg="#fff5f5")
            self.update_duration()
            
            idx = self.mic_options.get(self.mic_combo.get())
            threading.Thread(target=self._record_loop, args=(idx,), daemon=True).start()
            self.update_visualizer()

    def stop_recording(self, event):
        # CRITICAL FIX: If user is typing in an Entry, releasing Space should do nothing to recording
        if isinstance(event.widget, (tk.Entry, ctk.CTkEntry, ctk.CTkComboBox)):
            return

        if self.is_recording:
            self.is_recording = False
            self.rec_button.set_recording(False)
            self.lbl_status.configure(text="💾 Saving...", text_color=COLOR_SAVING)
            self.vis_canvas.configure(bg="#fcfcfc")
            
            threading.Thread(target=self._save_audio, daemon=True).start()

    def _record_loop(self, idx):
        try:
            self.stream = self.audio.open(format=FORMAT, channels=CHANNELS, rate=SAMPLE_RATE, 
                                        input=True, input_device_index=idx, frames_per_buffer=CHUNK)
            while self.is_recording:
                self.frames.append(self.stream.read(CHUNK, exception_on_overflow=False))
            self.stream.stop_stream()
            self.stream.close()
        except Exception as e: 
            self.after(0, lambda: self.show_toast("Recording error occurred", "error"))

    def _save_audio(self):
        if not self.frames: return
        base = self.entry_filename.get().strip() or "untitled"
        while os.path.exists(os.path.join(OUTPUT_FOLDER, f"{base}_{self.file_counter}.wav")):
            self.file_counter += 1
        
        fname = f"{base}_{self.file_counter}.wav"
        path = os.path.join(OUTPUT_FOLDER, fname)
        
        raw = b''.join(self.frames)
        arr = np.frombuffer(raw, dtype=np.int16)
        
        mask = np.abs(arr) > 500
        if np.any(mask):
            start, end = np.argmax(mask), len(mask) - np.argmax(mask[::-1])
            arr = arr[max(0, start-1000):min(len(arr), end+1000)]
            
        wavfile.write(path, SAMPLE_RATE, arr)
        
        self.after(0, lambda: self.add_list_item(fname))
        self.after(0, lambda: self.lbl_status.configure(text="✓ Saved!", text_color=COLOR_SUCCESS))
        self.after(0, lambda: self.show_toast(f"Saved: {fname}", "success"))
        self.after(2000, lambda: self.lbl_status.configure(text="Ready to Record", text_color=COLOR_PRIMARY))
        self.after(0, lambda: self.lbl_duration.configure(text="00:00"))

    def update_duration(self):
        if self.is_recording:
            elapsed = time.time() - self.recording_start_time
            self.lbl_duration.configure(text=f"{int(elapsed//60):02d}:{int(elapsed%60):02d}")
            self.after(100, self.update_duration)

    def update_visualizer(self):
        if self.is_recording and self.frames:
            raw = np.frombuffer(self.frames[-1], dtype=np.int16)
            self.level_meter.update_levels(raw[::5])
            
            avg_level = np.abs(raw).mean() / 32768.0
            if avg_level > 0.6:
                self.lbl_quality.configure(text="● Too Loud!", text_color=COLOR_RECORDING)
            elif avg_level > 0.15:
                self.lbl_quality.configure(text="● Excellent", text_color=COLOR_SUCCESS)
            elif avg_level > 0.05:
                self.lbl_quality.configure(text="● Good", text_color=COLOR_PRIMARY)
            else:
                self.lbl_quality.configure(text="● Too Quiet", text_color=COLOR_SAVING)
            
            w, h = self.vis_canvas.winfo_width(), self.canvas_height
            self.vis_canvas.delete("wave")
            
            ds = raw[::12]
            x_step = w / len(ds)
            points = []
            for i, val in enumerate(ds):
                points.extend([i * x_step, (h/2) - (val/32768)*(h/2)*0.85])
            
            if len(points) > 4:
                self.vis_canvas.create_line(points, fill="#c7d2fe", width=3, smooth=True, tags="wave")
                self.vis_canvas.create_line(points, fill=COLOR_PRIMARY, width=2, smooth=True, tags="wave")
                
        if self.is_recording: 
            self.after(30, self.update_visualizer)
        else:
            self.vis_canvas.delete("wave")
            self.level_meter.update_levels(np.zeros(100))
            self.lbl_quality.configure(text="● Standby", text_color="#cbd5e1")

    def add_list_item(self, filename):
        self.empty_state.pack_forget()
        card = ctk.CTkFrame(self.file_list_frame, fg_color="white", 
                           corner_radius=10, border_width=1, border_color="#e2e8f0",
                           height=70)
        card.pack(fill="x", pady=5, padx=5)
        card.grid_columnconfigure(1, weight=1)
        
        play_btn = CircularPlayButton(card, command=lambda: self.toggle_playback(filename, play_btn), size=42)
        play_btn.grid(row=0, column=0, padx=(15, 12), pady=15)

        text_frame = ctk.CTkFrame(card, fg_color="transparent")
        text_frame.grid(row=0, column=1, sticky="ew", pady=15)
        
        ctk.CTkLabel(text_frame, text=filename, font=("Segoe UI", 13, "bold"), 
                     text_color=COLOR_TEXT, anchor="w").pack(fill="x")
        
        time_str = datetime.datetime.now().strftime("%I:%M %p • %b %d")
        ctk.CTkLabel(text_frame, text=f"🕐 {time_str}", font=("Arial", 10), 
                     text_color=COLOR_TEXT_SECONDARY, anchor="w").pack(fill="x")

        del_btn = ctk.CTkButton(card, text="×", width=36, height=36,
                               corner_radius=8, fg_color="transparent", 
                               hover_color=COLOR_HOVER_RED,
                               text_color=COLOR_DELETE, font=("Arial", 22, "bold"),
                               command=lambda: self.delete_file(filename, card))
        del_btn.grid(row=0, column=2, padx=(0, 12))
        
        self.update_file_count()

    def delete_file(self, filename, card):
        try:
            os.remove(os.path.join(OUTPUT_FOLDER, filename))
            card.destroy()
            self.update_file_count()
            self.show_toast(f"Deleted: {filename}", "info")
            self.check_empty_state()
        except: 
            self.show_toast("Delete failed", "error")

    def delete_all_files(self):
        if not os.listdir(OUTPUT_FOLDER):
            self.show_toast("No files to delete", "info")
            return
            
        popup = ctk.CTkToplevel(self)
        popup.title("Confirm Delete")
        popup.geometry("400x200")
        popup.configure(fg_color=COLOR_CARD)
        popup.transient(self)
        popup.grab_set()
        
        ctk.CTkLabel(popup, text="⚠️ Delete All Recordings?", 
                    font=("Segoe UI", 18, "bold"), text_color=COLOR_TEXT).pack(pady=(30, 10))
        ctk.CTkLabel(popup, text="This action cannot be undone.", 
                    font=("Arial", 11), text_color=COLOR_TEXT_SECONDARY).pack()
        
        btn_frame = ctk.CTkFrame(popup, fg_color="transparent")
        btn_frame.pack(pady=30)
        
        ctk.CTkButton(btn_frame, text="Cancel", width=120, height=36,
                     fg_color="#e2e8f0", hover_color="#cbd5e1", 
                     text_color=COLOR_TEXT,
                     command=popup.destroy).pack(side="left", padx=5)
        
        def confirm_delete():
            try:
                for f in os.listdir(OUTPUT_FOLDER):
                    if f.endswith('.wav'):
                        os.remove(os.path.join(OUTPUT_FOLDER, f))
                for widget in self.file_list_frame.winfo_children():
                    if isinstance(widget, ctk.CTkFrame) and widget != self.empty_state:
                        widget.destroy()
                self.update_file_count()
                self.check_empty_state()
                self.show_toast("All files deleted", "success")
            except:
                self.show_toast("Delete failed", "error")
            popup.destroy()
        
        ctk.CTkButton(btn_frame, text="Delete All", width=120, height=36,
                     fg_color=COLOR_DELETE, hover_color="#dc2626",
                     command=confirm_delete).pack(side="left", padx=5)

    def check_empty_state(self):
        files = [f for f in os.listdir(OUTPUT_FOLDER) if f.endswith('.wav')]
        if not files:
            self.empty_state.pack(expand=True, pady=50)

    def update_file_count(self):
        try:
            cnt = len([f for f in os.listdir(OUTPUT_FOLDER) if f.endswith('.wav')])
            self.lbl_file_count.configure(text=str(cnt))
        except: pass

    def on_search(self, event):
        search = self.search_entry.get().lower()
        for widget in self.file_list_frame.winfo_children():
            if isinstance(widget, ctk.CTkFrame) and widget != self.empty_state:
                for child in widget.winfo_children():
                    if isinstance(child, ctk.CTkFrame):
                        for label in child.winfo_children():
                            if isinstance(label, ctk.CTkLabel):
                                text = label.cget("text").lower()
                                if search in text:
                                    widget.pack(fill="x", pady=5, padx=5)
                                else:
                                    widget.pack_forget()
                                break
                        break

    def toggle_playback(self, filename, btn):
        if self.active_play_btn and self.active_play_btn != btn:
            self.stop_playback_flag = True
            time.sleep(0.05)
            self.active_play_btn.set_state(False)

        if btn.is_playing:
            self.stop_playback_flag = True
            btn.set_state(False)
            self.active_play_btn = None
        else:
            self.stop_playback_flag = False
            self.active_play_btn = btn
            btn.set_state(True)
            threading.Thread(target=self._play_thread, args=(filename, btn), daemon=True).start()

    def _play_thread(self, filename, btn):
        try:
            wf = wave.open(os.path.join(OUTPUT_FOLDER, filename), 'rb')
            p = pyaudio.PyAudio()
            stream = p.open(format=p.get_format_from_width(wf.getsampwidth()),
                          channels=wf.getnchannels(), rate=wf.getframerate(), output=True)
            total = wf.getnframes()
            chunk = 1024
            data = wf.readframes(chunk)
            processed = 0
            
            while data and not self.stop_playback_flag:
                stream.write(data)
                processed += chunk
                self.after(0, lambda p=processed/total: btn.set_progress(p))
                data = wf.readframes(chunk)
            
            stream.stop_stream()
            stream.close()
            p.terminate()
            self.after(0, lambda: btn.set_state(False))
            self.active_play_btn = None
        except: 
            self.after(0, lambda: btn.set_state(False))
            self.show_toast("Playback error", "error")

    def update_file_list_initial(self):
        try:
            files = sorted([f for f in os.listdir(OUTPUT_FOLDER) if f.endswith('.wav')],
                         key=lambda x: os.path.getmtime(os.path.join(OUTPUT_FOLDER, x)),
                         reverse=True)
            if files:
                self.empty_state.pack_forget()
            for f in files: 
                self.add_list_item(f)
            self.update_file_count()
        except: pass

    def show_shortcuts(self):
        popup = ctk.CTkToplevel(self)
        popup.title("⌨️ Keyboard Shortcuts")
        popup.geometry("500x400")
        popup.configure(fg_color=COLOR_BG)
        popup.transient(self)
        popup.grab_set()
        
        header = ctk.CTkFrame(popup, fg_color=COLOR_CARD, corner_radius=0)
        header.pack(fill="x")
        ctk.CTkLabel(header, text="⌨️ Keyboard Shortcuts", 
                    font=("Segoe UI", 22, "bold"), text_color=COLOR_TEXT).pack(pady=20)
        
        content = ctk.CTkScrollableFrame(popup, fg_color="transparent")
        content.pack(fill="both", expand=True, padx=20, pady=20)
        
        shortcuts = [
            ("SPACE", "Hold to record (if not typing)"),
            ("Ctrl + H", "Show this shortcuts panel"),
            ("Click Away", "Unfocus text boxes"),
            ("Enter", "Confirm filename & Unfocus"),
        ]
        
        for key, desc in shortcuts:
            card = ctk.CTkFrame(content, fg_color=COLOR_CARD, corner_radius=8, 
                               border_width=1, border_color="#e2e8f0")
            card.pack(fill="x", pady=6)
            
            ctk.CTkLabel(card, text=key, font=("Courier New", 13, "bold"), 
                        text_color=COLOR_PRIMARY, width=120).pack(side="left", padx=20, pady=15)
            ctk.CTkLabel(card, text=desc, font=("Arial", 11), 
                        text_color=COLOR_TEXT, anchor="w").pack(side="left", padx=(0, 20), fill="x", expand=True)
        
        ctk.CTkButton(popup, text="Got it!", height=40, width=140,
                     fg_color=COLOR_PRIMARY, hover_color=COLOR_PRIMARY_DARK,
                     font=("Segoe UI", 13, "bold"),
                     command=popup.destroy).pack(pady=(0, 20))


if __name__ == "__main__":
    app = ModernRecorderApp()
    app.mainloop()