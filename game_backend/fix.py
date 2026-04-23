import re

filepath = r'c:\Users\TD Jayadeera\Downloads\sinhala-mithuru\game_backend\app\services\teacher_service.py'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

target = "        return {\n            \"student_name\": student_info_res.data.get('name', 'Unknown') if student_info_res.data else 'Unknown',\n"
replacement = """        student_data = student_info_res.data if student_info_res.data else {}
        classes_data = student_data.get('classes') or {}
        if isinstance(classes_data, list) and len(classes_data) > 0:
            classes_data = classes_data[0]
        schools_data = classes_data.get('schools') or {}
        if isinstance(schools_data, list) and len(schools_data) > 0:
            schools_data = schools_data[0]
        teachers_data = classes_data.get('teachers') or {}
        if isinstance(teachers_data, list) and len(teachers_data) > 0:
            teachers_data = teachers_data[0]
        game_state_data = game_state_res.data or {}

        profile = {
            "name": student_data.get('name', 'Unknown'),
            "class_name": classes_data.get('class_name', 'Unknown'),
            "school_name": schools_data.get('name', 'Unknown'),
            "teacher_name": teachers_data.get('name', 'Unknown'),
            "game_state": {
                "total_score": game_state_data.get('total_score', 0)
            }
        }

        return {
            "student_name": student_info_res.data.get('name', 'Unknown') if student_info_res.data else 'Unknown',
            "profile": profile,
"""

if target in content:
    content = content.replace(target, replacement)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced successfully")
else:
    print("Target not found. Doing regex replace.")
    content = re.sub(
        r"        return \{\s+\"student_name\": student_info_res\.data\.get\('name', 'Unknown'\) if student_info_res\.data else 'Unknown',",
        replacement.strip(),
        content
    )
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced with regex.")
