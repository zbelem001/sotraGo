import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_screen.dart';
import '../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: FloatingActionButton(
          heroTag: 'info_fab',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "À propos de MoovFaso",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Bienvenue sur MoovFaso ! Trouver le bon chemin n'a jamais été aussi facile.",
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.6,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildInfoBlock(
                              "Fonctionnement",
                              "Consultez les prix, les arrêts, et surtout la position des bus en temps réel pour vos trajets.",
                            ),
                            const SizedBox(height: 12),
                            _buildInfoBlock(
                              "Mode Éclaireur",
                              "L'accès à la carte nécessite le Mode Éclaireur. En l'activant, vous acceptez de partager anonymement votre position pendant vos trajets pour aider la communauté à repérer les bus.",
                            ),
                            const SizedBox(height: 12),
                            _buildInfoBlock(
                              "Confidentialité",
                              "L'application ne vous suit plus du tout après que vous l'ayez quittée (en arrière-plan ou fermée).",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.08,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "J'ai compris",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          elevation: 0,
          backgroundColor: AppColors.primary,
          child: const Icon(
            Icons.question_mark_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero Header ──────────────────────────────────────────
                    _buildHeroHeader(isDark),

                    const SizedBox(height: 28),

                    // ── CTA Card ─────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildCtaCard(context),
                    ),

                    const SizedBox(height: 28),

                    // ── Stats Section ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("Activité en temps réel"),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  "Bus en ligne",
                                  "42",
                                  Icons.directions_bus_rounded,
                                  Colors.blue,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  "Éclaireurs",
                                  "128",
                                  Icons.people_alt_rounded,
                                  Colors.green,
                                  isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Shortcuts ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel("Raccourcis"),
                          const SizedBox(height: 14),
                          _buildShortcutItem(
                            context,
                            "Toutes les Lignes",
                            "Consultez les tracés et arrêts",
                            Icons.format_list_bulleted_rounded,
                            () {
                              if (!LocationService().isScoutModeEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Veuillez d'abord activer le Mode Éclaireur (en haut à droite)",
                                    ),
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
                            },
                            isDark,
                          ),
                          const SizedBox(height: 10),
                          _buildShortcutItem(
                            context,
                            "Bons Plans",
                            "Événements et pubs sponsorisées",
                            Icons.local_offer_rounded,
                            () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const MainScreen(initialIndex: 3),
                                ),
                              );
                            },
                            isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Popular Lines ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionLabel("Lignes très demandées"),
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 148,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildPopularLineCard(
                            context,
                            "Ligne 1",
                            "Marché ↔ Nagrin",
                            "200 F",
                            "32 arrêts",
                            isDark,
                          ),
                          _buildPopularLineCard(
                            context,
                            "Ligne 3",
                            "Gare ↔ Tampouy",
                            "200 F",
                            "28 arrêts",
                            isDark,
                          ),
                          _buildPopularLineCard(
                            context,
                            "Ligne 10",
                            "Dapoya ↔ Ouaga2000",
                            "200 F",
                            "35 arrêts",
                            isDark,
                          ),
                          _buildPopularLineCard(
                            context,
                            "Ligne 5",
                            "Zaghtouli ↔ SIAO",
                            "200 F",
                            "40 arrêts",
                            isDark,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Hero Header ────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Stack(
        children: [
          // Background gradient
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
          ),

          // Decorative circle
          Positioned(
            right: -60,
            top: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),

          // Subtle bus icon
          Positioned(
            right: -30,
            top: -20,
            child: Opacity(
              opacity: 0.08,
              child: const Icon(
                Icons.directions_bus_rounded,
                size: 220,
                color: Colors.white,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo / App name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "MoovFaso",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    // Scout mode toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.my_location_rounded,
                            color: LocationService().isScoutModeEnabled
                                ? Colors.greenAccent
                                : Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "Éclaireur",
                            style: TextStyle(
                              color: LocationService().isScoutModeEnabled
                                  ? Colors.greenAccent
                                  : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: LocationService().isScoutModeEnabled,
                              onChanged: (val) async {
                                await LocationService().toggleScoutMode(val);
                                setState(() {});
                              },
                              activeColor: Colors.white,
                              activeTrackColor: Colors.greenAccent,
                              inactiveThumbColor: Colors.white70,
                              inactiveTrackColor: Colors.grey.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // Headline
                const Text(
                  "Votre ville,\nvotre chemin.",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Suivi en temps réel du réseau SOTRACO.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA Card ───────────────────────────────────────────────────────────────
  Widget _buildCtaCard(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!LocationService().isScoutModeEnabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Veuillez d'abord activer le Mode Éclaireur (en haut à droite)",
              ),
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
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Voir les bus en direct",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    "Trouvez votre Itinéraire",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section Label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.2,
      ),
    );
  }

  // ── Stat Card ──────────────────────────────────────────────────────────────
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shortcut Item ──────────────────────────────────────────────────────────
  Widget _buildShortcutItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSlate : Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Popular Line Card ──────────────────────────────────────────────────────
  Widget _buildPopularLineCard(
    BuildContext context,
    String lineName,
    String stations,
    String price,
    String stopsCount,
    bool isDark,
  ) {
    return Container(
      width: 162,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSlate : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            if (!LocationService().isScoutModeEnabled) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Veuillez d'abord activer le Mode Éclaireur (en haut à droite)",
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MainScreen(initialIndex: 1, initialMapLine: lineName),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: line badge + price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lineName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        price,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                // Station info
                Text(
                  stations,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Stop count
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      stopsCount,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Info Block for Dialog ──────────────────────────────────────────────────
  Widget _buildInfoBlock(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
