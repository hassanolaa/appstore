import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/game_model.dart';

class GameCard extends StatefulWidget {
  final GameModel game;
  final bool isInstalled;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.game,
    required this.isInstalled,
    required this.onTap,
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: widget.onTap,
      onFocusChange: (focused) {
        setState(() {
          _isFocused = focused;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isFocused ? theme.colorScheme.primary.withOpacity(0.2) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isFocused ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: _isFocused
              ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]
              : [],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: widget.game.icon128 != null && widget.game.icon128!.isNotEmpty
                    ? Image.file(
                        File(widget.game.icon128!),
                        errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, size: 64),
                      )
                    : widget.game.icon64 != null && widget.game.icon64!.isNotEmpty
                        ? Image.file(
                            File(widget.game.icon64!),
                            errorBuilder: (_, __, ___) => const Icon(Icons.videogame_asset, size: 64),
                          )
                        : const Icon(Icons.videogame_asset, size: 64),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.game.name ?? 'Unknown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.game.developer ?? 'Unknown Developer',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isInstalled)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
