"""
@File: utils.py
@Description: Preprocessing utilities for Sinhala Mithuru Handwriting Engine.
"""

import numpy as np

def preprocess_data(strokes, max_seq_length=150, canvas_size=600):
    """
    පර්යේෂණාත්මක පූර්ව සැකසුම් පද්ධතිය: අමු දත්ත මොඩලයට ගැළපෙන ලෙස සකසයි.
    """
    pts = []
    # 1. Stroke දත්ත වලින් ලක්ෂ්‍ය වෙන් කර ගැනීම
    for s in strokes:
        for p_val in s:
            pts.append([
                p_val.get('x', 0), p_val.get('y', 0),
                p_val.get('dx', 0), p_val.get('dy', 0),
                p_val.get('p', 0)
            ])
            
    # අවම ලක්ෂ්‍ය ප්‍රමාණය පරීක්ෂා කිරීම
    if len(pts) < 5: 
        return None, strokes
        
    path = np.array(pts, dtype='float32')

    # 2. Linear Interpolation (ලක්ෂ්‍ය 150කට සැකසීම)
    # Rationale: කාලීන විචල්‍යතාවය (Temporal variance) පාලනය කිරීම.
    dist = np.sqrt(np.sum(np.diff(path[:, :2], axis=0)**2, axis=1))
    cum_dist = np.insert(np.cumsum(dist), 0, 0)
    
    if cum_dist[-1] == 0: 
        return None, strokes

    interp_d = np.linspace(0, cum_dist[-1], max_seq_length)
    
    # ඛණ්ඩාංක Normalization (0 සිට 1 දක්වා)
    nx = np.interp(interp_d, cum_dist, path[:, 0]) / canvas_size
    ny = np.interp(interp_d, cum_dist, path[:, 1]) / canvas_size
    ndx = np.interp(interp_d, cum_dist, path[:, 2])
    ndy = np.interp(interp_d, cum_dist, path[:, 3])
    np_state = np.round(np.interp(interp_d, cum_dist, path[:, 4]))

    # විශේෂාංග 5 ක් සහිත NumPy Array එක සෑදීම
    processed_sample = np.stack([nx, ny, ndx, ndy, np_state], axis=1)
    
    return processed_sample, strokes