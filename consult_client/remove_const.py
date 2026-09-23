import os
import glob
import re

files = glob.glob('lib/**/*.dart', recursive=True)
for file in files:
    if 'app_colors.dart' in file or 'app_theme.dart' in file or 'app.dart' in file:
        continue
    with open(file, 'r') as f:
        content = f.read()
    
    if 'context.colors' in content:
        content = re.sub(r'\bconst\s+', '', content)
        with open(file, 'w') as f:
            f.write(content)
