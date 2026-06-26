import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_store/core/navigation/keyboard_navigation_manager.dart';
import 'package:game_store/features/games/presentation/pages/games_page.dart';
import 'package:game_store/features/games/presentation/pages/library_page.dart';
import 'package:game_store/features/games/presentation/pages/updates_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const GamesPage(),
    const LibraryPage(),
    const UpdatesPage(),
  ];

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedIndex == index;

    return Focus(
      onKey: (node, event) {
        if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          setState(() {
            _selectedIndex = index;
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedIndex = index;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFocused
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : isSelected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFocused ? theme.colorScheme.primary : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isSelected || isFocused
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color?.withOpacity(0.7),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected || isFocused
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardNavigationManager.withArrowNavigation(
      onArrowKey: (key) {
        if (key == LogicalKeyboardKey.escape) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            // Left Sidebar
            Container(
              width: 240,
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'GAME STORE',
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontSize: 20,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSidebarItem(
                    icon: Icons.store,
                    label: 'Browse Store',
                    index: 0,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarItem(
                    icon: Icons.library_books,
                    label: 'My Library',
                    index: 1,
                    theme: theme,
                  ),
                  const SizedBox(height: 8),
                  _buildSidebarItem(
                    icon: Icons.update,
                    label: 'Updates',
                    index: 2,
                    theme: theme,
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'v1.0.0',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            VerticalDivider(width: 1, color: Colors.grey.withOpacity(0.2)),
            // Right Main Content
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    _selectedIndex == 0
                        ? 'Storefront'
                        : _selectedIndex == 1
                            ? 'Library'
                            : 'Available Updates',
                  ),
                ),
                body: IndexedStack(
                  index: _selectedIndex,
                  children: _pages,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
