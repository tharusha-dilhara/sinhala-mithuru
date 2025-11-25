import threading
import webview
import sys
import os
from time import sleep
from app import app 

# Flask Server
def start_server():
    app.run(host='127.0.0.1', port=54321, debug=False, use_reloader=False)

# JavaScript API
class Api:
    def close_app(self):
        os._exit(0)

# Icon Path එක සොයා ගැනීම (EXE සහ Normal Run දෙකේදීම වැඩ කිරීමට)
def get_icon_path():
    if getattr(sys, 'frozen', False):
        return os.path.join(sys._MEIPASS, 'logo.ico')
    else:
        return os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logo.ico')

if __name__ == '__main__':
    t = threading.Thread(target=start_server)
    t.daemon = True
    t.start()
    sleep(1)

    api = Api()
    icon_file = get_icon_path() # අයිකන් එකේ පාත් එක
    
    window = webview.create_window(
        title='Sinhala Mithuru Collector', 
        url='http://127.0.0.1:54321',
        js_api=api,
        width=1200, 
        height=800,
        resizable=True,
        frameless=False,  
        background_color='#f4f7f6'
    )
    
    # මෙන්න මෙතනින් Icon එක සෙට් කරන්න පුලුවන් (PyWebview අනුවාදය මත රඳා පවතී)
    # නමුත් EXE එක හදද්දී --icon දැම්මාම වින්ඩෝස් වල නිකම්ම මේක වැටෙනවා.
    
    webview.start(icon=icon_file)