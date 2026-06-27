import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_store/core/navigation/keyboard_navigation_manager.dart';
import 'package:game_store/features/games/presentation/cubit/games_cubit.dart';
import 'package:game_store/features/games/presentation/pages/apps_page.dart';
import 'package:game_store/features/games/presentation/pages/games_page.dart';
import 'package:game_store/features/games/presentation/pages/library_page.dart';
import 'package:game_store/features/games/presentation/pages/updates_page.dart';
import 'package:game_store/service_locator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    BlocProvider(create: (_) => sl<GamesCubit>(), child: const AppsPage()),
    BlocProvider(create: (_) => sl<GamesCubit>(), child: const GamesPage()),
    BlocProvider(create: (_) => sl<GamesCubit>(), child: const LibraryPage()),
    BlocProvider(create: (_) => sl<GamesCubit>(), child: const UpdatesPage()),
  ];

  // ── Exact same logic as original, only decoration changed ──
  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedIndex == index;

    return Focus(
      onKey: (node, event) {
        if (event is RawKeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          setState(() => _selectedIndex = index);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return InkWell(
            onTap: () => setState(() => _selectedIndex = index),
            borderRadius: BorderRadius.circular(14),
            splashColor: theme.colorScheme.primary.withOpacity(0.12),
            highlightColor: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                // Glass tint: stronger when focused, lighter when selected
                color:
                    isFocused
                        ? theme.colorScheme.primary.withOpacity(0.22)
                        : isSelected
                        ? theme.colorScheme.primary.withOpacity(0.13)
                        : Colors.white.withOpacity(0.03),
                border: Border.all(
                  color:
                      isFocused
                          ? theme.colorScheme.primary.withOpacity(0.7)
                          : isSelected
                          ? theme.colorScheme.primary.withOpacity(0.35)
                          : Colors.white.withOpacity(0.07),
                  width: 1,
                ),
                boxShadow:
                    isSelected || isFocused
                        ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                children: [
                  // Icon with subtle background pill when active
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color:
                          isSelected || isFocused
                              ? theme.colorScheme.primary.withOpacity(0.18)
                              : Colors.transparent,
                    ),
                    child: Icon(
                      icon,
                      size: 19,
                      color:
                          isSelected || isFocused
                              ? theme.colorScheme.primary
                              : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            isSelected || isFocused
                                ? Colors.white
                                : Colors.white.withOpacity(0.55),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Active dot indicator
                  if (isSelected)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
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
    final scheme = theme.colorScheme;

    return KeyboardNavigationManager.withArrowNavigation(
      // ── Exact same callback as original ──
      onArrowKey: (key) {
        if (key == LogicalKeyboardKey.escape) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1020),
        body: Container(
          // Page background gradient
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1020), Color(0xFF11182B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // ── Left Sidebar — glass panel ────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),

                              // Brand logo + name
                              Row(
                                children: [
                                  Container(
                                    height: 44,
                                    width: 44,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      gradient: LinearGradient(
                                        colors: [
                                          scheme.primary,
                                          scheme.primary.withOpacity(0.65),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scheme.primary.withOpacity(
                                            0.35,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.sports_esports_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Text(
                                        'GAME STORE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Next-gen desktop hub',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),
                              const SizedBox(height: 16),

                              // ── Nav items ──
                              _buildSidebarItem(
                                icon: Icons.apps_rounded,
                                label: 'Apps',
                                index: 0,
                                theme: theme,
                              ),
                              const SizedBox(height: 8),
                              _buildSidebarItem(
                                icon: Icons.sports_esports_rounded,
                                label: 'Games',
                                index: 1,
                                theme: theme,
                              ),
                              const SizedBox(height: 8),
                              _buildSidebarItem(
                                icon: Icons.video_library_outlined,
                                label: 'My Library',
                                index: 2,
                                theme: theme,
                              ),
                              const SizedBox(height: 8),
                              _buildSidebarItem(
                                icon: Icons.system_update_alt_outlined,
                                label: 'Updates',
                                index: 3,
                                theme: theme,
                              ),

                              const Spacer(),

                              // Footer
                              Divider(
                                height: 1,
                                color: Colors.white.withOpacity(0.08),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'v1.0.0',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 13,
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
                  ),

                  const SizedBox(width: 16),

                  // ── Right Main Content — glass shell ──────────────
                  Expanded(
                    child: Column(
                      children: [
                        // Top header bar
                        Container(
                          height: 72,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Page icon
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: scheme.primary.withOpacity(0.14),
                                ),
                                child: Icon(
                                  _selectedIndex == 0
                                      ? Icons.apps_rounded
                                      : _selectedIndex == 1
                                      ? Icons.sports_esports_rounded
                                      : _selectedIndex == 2
                                      ? Icons.video_library_rounded
                                      : Icons.system_update_alt_rounded,
                                  color: scheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Title
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedIndex == 0
                                          ? 'Apps'
                                          : _selectedIndex == 1
                                          ? 'Games'
                                          : _selectedIndex == 2
                                          ? 'Library'
                                          : 'Available Updates',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _selectedIndex == 0
                                          ? 'Discover desktop applications'
                                          : _selectedIndex == 1
                                          ? 'Discover new games'
                                          : _selectedIndex == 2
                                          ? 'Owned and installed'
                                          : 'Manage patches',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.45),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // // Updates badge
                              // Container(
                              //   padding: const EdgeInsets.symmetric(
                              //     horizontal: 14,
                              //     vertical: 9,
                              //   ),
                              //   decoration: BoxDecoration(
                              //     borderRadius: BorderRadius.circular(14),
                              //     color: Colors.white.withOpacity(0.05),
                              //     border: Border.all(
                              //       color: Colors.white.withOpacity(0.08),
                              //     ),
                              //   ),
                              //   child: Row(
                              //     children: [
                              //       Icon(
                              //         Icons.download_done_rounded,
                              //         color: scheme.primary,
                              //         size: 16,
                              //       ),
                              //       const SizedBox(width: 8),
                              //       const Text(
                              //         '3 updates ready',
                              //         style: TextStyle(
                              //           color: Colors.white,
                              //           fontWeight: FontWeight.w600,
                              //           fontSize: 13,
                              //         ),
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Content shell
                        Expanded(
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              color: Colors.white.withOpacity(0.06),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.22),
                                  blurRadius: 24,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            // ── Exact same IndexedStack as original ──
                            child: IndexedStack(
                              index: _selectedIndex,
                              children:
                                  _pages.asMap().entries.map((entry) {
                                    return ExcludeFocus(
                                      excluding: _selectedIndex != entry.key,
                                      child: _LazyLoadWrapper(
                                        isActive: _selectedIndex == entry.key,
                                        child: entry.value,
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveTab extends InheritedWidget {
  final bool isActive;

  const ActiveTab({super.key, required this.isActive, required super.child});

  static bool of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ActiveTab>()?.isActive ??
        false;
  }

  @override
  bool updateShouldNotify(ActiveTab oldWidget) =>
      isActive != oldWidget.isActive;
}

class _LazyLoadWrapper extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const _LazyLoadWrapper({required this.child, required this.isActive});

  @override
  State<_LazyLoadWrapper> createState() => _LazyLoadWrapperState();
}

class _LazyLoadWrapperState extends State<_LazyLoadWrapper> {
  bool _hasLoaded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isActive && !_hasLoaded) {
      _hasLoaded = true;
    }
    if (!_hasLoaded) {
      return const SizedBox.shrink(); // Don't build the child at all until active!
    }
    return ActiveTab(isActive: widget.isActive, child: widget.child);
  }
}
