import re

filepath = 'pubspec.yaml'
with open(filepath, 'r') as f:
    content = f.read()

splash_config = """
flutter_native_splash:
  color: "#008542"
  image: assets/images/logo.png
  android_12:
    color: "#008542"
    image: assets/images/logo.png
"""

if "flutter_native_splash:" not in content:
    with open(filepath, 'a') as f:
        f.write("\n" + splash_config)
