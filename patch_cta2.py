import sys

with open('lib/screens/home_screen.dart', 'r') as f:
    lines = f.readlines()

new_lines = []
in_cta = False

for line in lines:
    if "// CTA Section" in line:
        in_cta = True
        
        new_lines.append("""              // CTA Section
              Padding(
                padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0, bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 1)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.my_location, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Voir les bus en direct",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Trouvez votre Itinéraire",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
              ),\n""")
        continue
        
    if in_cta and "// Stats / Community" in line:
        in_cta = False
        new_lines.append(line)
        continue
        
    if not in_cta:
        new_lines.append(line)

with open('lib/screens/home_screen.dart', 'w') as f:
    f.writelines(new_lines)
