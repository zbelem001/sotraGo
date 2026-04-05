import sys

with open('lib/screens/home_screen.dart', 'r') as f:
    content = f.read()

old_block_1 = """                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );"""

new_block_1 = """                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Section Déroulante : Lignes Populaires / Favoris
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Lignes très demandées",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildPopularLineCard(context, "Ligne 1", "Marché ↔ Nagrin", isDark),
                    _buildPopularLineCard(context, "Ligne 3", "Gare ↔ Tampouy", isDark),
                    _buildPopularLineCard(context, "Ligne 10", "Dapoya ↔ Ouaga2000", isDark),
                    _buildPopularLineCard(context, "Ligne 5", "Zaghtouli ↔ SIAO", isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );"""

old_block_2 = """            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
"""

new_block_2 = """            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularLineCard(BuildContext context, String lineName, String stations, bool isDark) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Aller vers la carte avec cette ligne préréglée
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainScreen(initialIndex: 1, initialMapLine: lineName),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lineName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  stations,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
"""

if old_block_1 in content:
    content = content.replace(old_block_1, new_block_1)
if old_block_2 in content:
    content = content.replace(old_block_2, new_block_2)

with open('lib/screens/home_screen.dart', 'w') as f:
    f.write(content)
print("done")
