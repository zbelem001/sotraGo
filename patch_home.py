with open('lib/screens/home_screen.dart', 'r+') as f:
    c = f.read()
    old = """Row(
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 40,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "SotraGO",
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),"""
    new = """const Text(
                              "SotraGO",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),"""
    c = c.replace(old, new)
    f.seek(0)
    f.write(c)
    f.truncate()
