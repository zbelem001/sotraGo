import sys

with open('lib/screens/home_screen.dart', 'r') as f:
    content = f.read()

old_block = """              // CTA Section
              Transform.translate(
                offset: const Offset(0, -10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),"""

new_block = """              // CTA Section
              Padding(
                padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0, bottom: 8.0),"""

content = content.replace(old_block, new_block)

old_block_end = """                          const Icon(Icons.arrow_forward_ios, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Stats / Community"""

new_block_end = """                          const Icon(Icons.arrow_forward_ios, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
              ),

              // Stats / Community"""

content = content.replace(old_block_end, new_block_end)

with open('lib/screens/home_screen.dart', 'w') as f:
    f.write(content)
