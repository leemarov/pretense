import os

with open('pretense_compiled.lua', 'r') as f:
    lines = f.readlines()
    current_filename = ''
    file_lines = []
    for line in lines:
        if '-----------------[[' in line:
            if 'END OF' in line:
                if os.path.dirname(current_filename):
                    os.makedirs(os.path.dirname(current_filename), exist_ok=True)
                with open(current_filename, 'w') as f_write:
                    f_write.writelines(file_lines)
                    current_filename = ''
                    file_lines = []
            else:
                current_filename = line.strip().strip('-[]').rstrip(']-').strip()
                print(f"{current_filename}")
        elif current_filename:
            file_lines.append(line)
