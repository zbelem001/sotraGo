import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:convert';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  _LeaderboardScreenState createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final data = await ApiService().fetchLeaderboard();
      setState(() {
        _users = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de charger le classement')),
      );
    }
  }

  IconData _getIconForRole(String? role) {
    if (role == 'admin') return Icons.admin_panel_settings;
    if (role == 'eclaireur_maitre') return Icons.workspace_premium;
    return Icons.directions_bus;
  }

  Color _getColorForRank(int index) {
    if (index == 0) return Colors.amber; // Or
    if (index == 1) return Colors.grey.shade400; // Argent
    if (index == 2) return Colors.brown.shade300; // Bronze
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Éclaireurs 🏆'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _users.isEmpty
          ? const Center(
              child: Text(
                "Aucun éclaireur trouvé pour le moment. Soyez le premier !",
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                final rankColor = _getColorForRank(index);
                return Card(
                  elevation: index < 3 ? 4 : 1,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: index < 3
                        ? BorderSide(color: rankColor, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: index < 3
                          ? rankColor.withOpacity(0.2)
                          : Colors.green.shade50,
                      child: Text(
                        "#${index + 1}",
                        style: TextStyle(
                          color: index < 3 ? rankColor : Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      "Éclaireur Anonyme",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          _getIconForRole(user['role']),
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user['role'] == 'eclaireur_maitre'
                              ? 'Maître'
                              : 'Novice',
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 2),
                        Text("${user['consecutiveDays'] ?? 1}j"),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${user['score'] ?? 0}",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Text(
                          "pts",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
