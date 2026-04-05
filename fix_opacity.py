with open("lib/screens/home_screen.dart", "r") as f:
    content = f.read()

content = content.replace(".withValues(alpha: (", ".withValues(alpha: ")

with open("lib/screens/home_screen.dart", "w") as f:
    f.write(content)
