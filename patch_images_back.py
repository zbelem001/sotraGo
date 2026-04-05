import sys

with open('lib/screens/events_screen.dart', 'r') as f:
    content = f.read()

# 1. Event Model
content = content.replace(
"""  final String time;
  

  Event({""",
"""  final String time;
  final String imageUrl;

  Event({"""
)

content = content.replace(
"""    required this.time,
    
  });""",
"""    required this.time,
    required this.imageUrl,
  });""")

# 2. Dummy Data
content = content.replace(
"""      time: "Ven. 20h - 23h",
          ),""",
"""      time: "Ven. 20h - 23h",
      imageUrl: "https://picsum.photos/600/300?concert",
    ),""")

content = content.replace(
"""      time: "Ce Week-end",
          ),""",
"""      time: "Ce Week-end",
      imageUrl: "https://picsum.photos/600/300?food",
    ),""")

content = content.replace(
"""      time: "Sam. 16h",
          ),""",
"""      time: "Sam. 16h",
      imageUrl: "https://picsum.photos/600/300?soccer",
    ),""")

content = content.replace(
"""      time: "Jeu. 12h - 15h",
          ),""",
"""      time: "Jeu. 12h - 15h",
      imageUrl: "https://picsum.photos/600/300?burger",
    ),""")

# 3. Bottom Sheet
content = content.replace(
"""              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(""",
"""              Center(
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
                  CircleAvatar(""")

# 4. Event Card
old_card = """  Widget _buildEventCard(BuildContext context, bool isDark, Event event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: isDark ? AppColors.darkSlate : Colors.white,
      child: InkWell(
        onTap: () => _showEventDetails(event),
        child: ListTile(
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
      ),
    );
  }"""

new_card = """  Widget _buildEventCard(BuildContext context, bool isDark, Event event) {
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
  }"""

content = content.replace(old_card, new_card)

with open('lib/screens/events_screen.dart', 'w') as f:
    f.write(content)
