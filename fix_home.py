import sys

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/home_screen.dart', 'r') as f:
    text = f.read()

# 1. Remplacer l'encart statique "Eclaireur" par un Switch activable
static_eclaireur = """                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Éclaireur",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),"""
dynamic_switch = """                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "Mode Éclaireur",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Switch(
                                    value: LocationService().isScoutModeEnabled,
                                    onChanged: (val) async {
                                      await LocationService().toggleScoutMode(val);
                                      setState(() {});
                                    },
                                    activeColor: Colors.white,
                                    activeTrackColor: Colors.greenAccent,
                                    inactiveThumbColor: Colors.white70,
                                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.5),
                                  ),
                                ],
                              ),
                            ),"""
text = text.replace(static_eclaireur, dynamic_switch)

# 2. Bloquer l'accès CTA (Voir les bus)
cta_old = """                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(initialIndex: 1),
                      ),
                    );
                  },"""
cta_new = """                  onTap: () {
                    if (!LocationService().isScoutModeEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Veuillez d'abord activer le Mode Éclaireur (en haut à droite)"),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(initialIndex: 1),
                      ),
                    );
                  },"""
text = text.replace(cta_old, cta_new)

# 3. Bloquer l'accès aux Lignes
lines_old = """                      () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MainScreen(initialIndex: 2),
                          ),
                        );
                      },"""
lines_new = """                      () {
                        if (!LocationService().isScoutModeEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Veuillez d'abord activer le Mode Éclaireur (en haut à droite)"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const MainScreen(initialIndex: 2),
                          ),
                        );
                      },"""
text = text.replace(lines_old, lines_new)

# 4. Bloquer l'accès aux Lignes populaires (Carte presélectionnée)
pop_old = """          onTap: () {
            // Aller vers la carte avec cette ligne préréglée
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MainScreen(initialIndex: 1, initialMapLine: lineName),
              ),
            );
          },"""
pop_new = """          onTap: () {
            if (!LocationService().isScoutModeEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Veuillez d'abord activer le Mode Éclaireur (en haut à droite)"),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            // Aller vers la carte avec cette ligne préréglée
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MainScreen(initialIndex: 1, initialMapLine: lineName),
              ),
            );
          },"""
text = text.replace(pop_old, pop_new)

with open('/home/zia/Documents/MOI/MES PROJETS DEV/sorré/succes/lib/screens/home_screen.dart', 'w') as f:
    f.write(text)

