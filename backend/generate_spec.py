import re

# Path to your requirements.txt file
requirements_path = 'requirements.txt'

# Path to your spec file
spec_template_path = 'main.spec.template'
spec_output_path = 'main.spec'

# Read the requirements.txt file with fallback encodings
def read_requirements(file_path):
    encodings = ['utf-8', 'utf-16', 'latin1']
    for encoding in encodings:
        try:
            with open(file_path, 'r', encoding=encoding) as file:
                return file.readlines()
        except UnicodeDecodeError:
            continue
    raise UnicodeDecodeError(f"Could not decode the file {file_path} with tried encodings.")

# Read the requirements.txt file
requirements = read_requirements(requirements_path)

# Extract package names without version numbers
packages = [re.split('[>=<]', req.strip())[0] for req in requirements if req.strip() and not req.startswith('#')]

# Adjust known package names to their import names
adjustments = {
    'beautifulsoup4': 'bs4',
    'Flask': 'flask',
    'Pillow': 'PIL'
}

packages = [adjustments.get(pkg, pkg) for pkg in packages]

# Remove any potential empty strings from the list
packages = [pkg for pkg in packages if pkg]

# Read the spec template
with open(spec_template_path, 'r', encoding='utf-8') as file:
    spec_template = file.read()

# Generate the hiddenimports string
hiddenimports = ', '.join(f"'{package}'" for package in packages)

# Replace the placeholder in the spec template with the actual hiddenimports
spec_content = spec_template.replace('HIDDENIMPORTS_PLACEHOLDER', hiddenimports)

# Write the final spec file
with open(spec_output_path, 'w', encoding='utf-8') as file:
    file.write(spec_content)

# For debugging purposes, print the hiddenimports list
print(f"Hidden imports: {hiddenimports}")
