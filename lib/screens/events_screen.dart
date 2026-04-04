import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// Modèle de données pour préparer l'intégration avec la Base de Données (Admin Panel)
class Event {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String category;
  final IconData icon;
  final Color color;
  final String time;
  final String imageUrl;

  Event({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.category,
    required this.icon,
    required this.color,
    required this.time,
    required this.imageUrl,
  });
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  String _selectedCategory = "Tous";

  // Catégories pour le filtre (dynamique via BD plus tard)
  final List<String> _categories = [
    "Tous",
    "Concerts",
    "Gastronomie",
    "Sport",
    "Bons plans",
  ];

  // Simulation BDD d'événements
  final List<Event> _allEvents = [
    Event(
      id: "1",
      title: "Concert SIAO",
      shortDescription: "Jusqu'au bout de la nuit avec les artistes locaux.",
      fullDescription:
          "Venez vibrer au rythme de la musique burkinabè ! Un grand concert organisé dans le cadre du SIAO avec les plus grands artistes nationaux. Sécurité garantie et restauration sur place.\n\nPrix d'entrée : 2000 FCFA.\nLieu : Plateau SIAO.",
      category: "Concerts",
      icon: Icons.music_note,
      color: Colors.purple,
      time: "Ven. 20h - 23h",
      imageUrl: "https://picsum.photos/600/300?concert",
    ),
    Event(
      id: "2",
      title: "Foire Gastronomique",
      shortDescription:
          "Découvrez les saveurs de nos régions à la place de la Nation.",
      fullDescription:
          "La foire gastronomique annuelle est de retour ! Venez déguster les meilleurs plats de nos régions. Au programme : dégustations gratuites, concours du meilleur cuisinier et animations pour enfants.\n\nLieu : Place de la Nation.",
      category: "Gastronomie",
      icon: Icons.restaurant,
      color: Colors.orange,
      time: "Ce Week-end",
      imageUrl: "https://picsum.photos/600/300?food",
    ),
    Event(
      id: "3",
      title: "Match : Étalons vs Éléphants",
      shortDescription:
          "Projection sur écran géant au Stade municipal. Entrée libre.",
      fullDescription:
          "Ne manquez pas le choc des titans ! Projection en direct sur écran géant du match qualificatif. Ambiance garantie avec animations autour du stade.\n\nEntrée : Libre, consommation obligatoire.",
      category: "Sport",
      icon: Icons.sports_soccer,
      color: Colors.green,
      time: "Sam. 16h",
      imageUrl: "https://picsum.photos/600/300?soccer",
    ),
    Event(
      id: "4",
      title: "Promo McDo local",
      shortDescription: "Un menu acheté = un menu offert.",
      fullDescription:
          "Votre fast-food local lance une offre spéciale : présentez l'application à la caisse et profitez d'un menu offert pour chaque menu acheté. Valable uniquement ce jeudi !",
      category: "Bons plans",
      icon: Icons.fastfood,
      color: Colors.red,
      time: "Jeu. 12h - 15h",
      imageUrl: "https://picsum.photos/600/300?burger",
    ),
  ];

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark
                : AppColors.backgroundLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: event.color.withValues(alpha: 0.2),
                    child: Icon(event.icon, color: event.color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.time,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "À propos de l'événement",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                event.fullDescription,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Fermer",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filtrage dynamique
    final filteredEvents = _selectedCategory == "Tous"
        ? _allEvents
        : _allEvents.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Pubs & Événements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          top: 16.0,
          bottom: 100.0, // Espace pour ne pas être caché par le menu
        ),
        children: [
          // Bannière Pub principale
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [AppColors.primary, Colors.blueAccent],
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      'https://picsum.photos/600/300?business',
                      fit: BoxFit.cover,
                      color: Colors.black.withValues(alpha: 0.4),
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "SPONSORISÉ",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Offre étudiante : -50% sur votre abonnement internet",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Filtres (Catégories)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark
                        ? AppColors.darkSlate
                        : Colors.grey.shade200,
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory == "Tous" ? "À proximité" : _selectedCategory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${filteredEvents.length} résultat(s)",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste dynamique des événements filtrés
          if (filteredEvents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text("Aucun événement dans cette catégorie."),
              ),
            )
          else
            ...filteredEvents.map(
              (event) => _buildEventCard(context, isDark, event),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, bool isDark, Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: isDark ? AppColors.darkSlate : Colors.white,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              event.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: event.color.withValues(alpha: 0.2),
                child: Icon(event.icon, color: event.color),
              ),
              title: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.shortDescription),
                    const SizedBox(height: 6),
                    Text(
                      event.time,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
