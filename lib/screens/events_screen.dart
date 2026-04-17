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

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = "Tous";

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<String> _categories = [
    "Tous",
    "Concerts",
    "Gastronomie",
    "Sport",
    "Bons plans",
  ];

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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.zero,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Hero image
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      event.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category + time row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: event.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(event.icon, size: 13, color: event.color),
                                const SizedBox(width: 5),
                                Text(
                                  event.category,
                                  style: TextStyle(
                                    color: event.color,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  event.time,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Title
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider
                      Divider(
                        color: isDark ? Colors.white12 : Colors.grey.shade100,
                        thickness: 1,
                      ),

                      const SizedBox(height: 16),

                      // Description header
                      Text(
                        "À propos de l'événement",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        event.fullDescription,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.65,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Close button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Fermer",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredEvents = _selectedCategory == "Tous"
        ? _allEvents
        : _allEvents.where((e) => e.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pubs & Événements",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Découvrez ce qui se passe près de vous",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Sponsored banner ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _buildSponsoredBanner(),
                ),
              ),

              // ── Category filters ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 0),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.darkSlate
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.grey.shade200),
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.25,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.grey.shade700),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Section label ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategory == "Tous"
                            ? "À proximité"
                            : _selectedCategory,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${filteredEvents.length} résultat${filteredEvents.length > 1 ? 's' : ''}",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Events list ───────────────────────────────────────────
              filteredEvents.isEmpty
                  ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == filteredEvents.length) {
                          return const SizedBox(height: 100);
                        }
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: _buildEventCard(
                            context,
                            isDark,
                            filteredEvents[index],
                          ),
                        );
                      }, childCount: filteredEvents.length + 1),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sponsored Banner ───────────────────────────────────────────────────────
  Widget _buildSponsoredBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 175,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Image.network(
              'https://picsum.photos/600/300?business',
              fit: BoxFit.cover,
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            // Content
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "SPONSORISÉ",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Offre étudiante : -50% sur votre abonnement internet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Event Card ─────────────────────────────────────────────────────────────
  Widget _buildEventCard(BuildContext context, bool isDark, Event event) {
    return GestureDetector(
      onTap: () => _showEventDetails(event),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSlate : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.shade100,
            width: 1.2,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Image.network(
                  event.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                // Category badge on image
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: event.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(event.icon, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          event.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + arrow
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Text(
                    event.shortDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Time badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          event.time,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun événement",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Revenez bientôt pour découvrir les nouveautés",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
