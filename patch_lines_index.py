import sys

with open('lib/screens/lines_screen.dart', 'r') as f:
    content = f.read()

content = content.replace("initialIndex: 0,", "initialIndex: 1,")

with open('lib/screens/lines_screen.dart', 'w') as f:
    f.write(content)
