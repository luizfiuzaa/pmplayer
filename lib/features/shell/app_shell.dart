import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../favorites/favorites_view.dart';
import '../library/library_view.dart';
import '../navigation/navigation_controller.dart';
import '../player/mini_player.dart';
import '../player/now_playing_view.dart';
import '../player/player_view_model.dart';
import '../playlists/create_playlist_sheet.dart';
import '../playlists/playlist_detail_view.dart';
import '../playlists/playlists_view.dart';

/// Casca do app: área de conteúdo por aba, mini-player e menu inferior, com o
/// player e o sheet de criação como overlays. Reproduz o empilhamento do design.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationController>();
    final hasCurrent = context.select<PlayerViewModel, bool>(
      (p) => p.hasCurrent,
    );
    final activeTab = navigation.screen == AppScreen.nowPlaying
        ? navigation.prevTab
        : navigation.screen;

    return PopScope(
      canPop:
          navigation.screen == AppScreen.library && !navigation.createSheetOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (navigation.createSheetOpen) {
          navigation.closeCreateSheet();
        } else if (navigation.screen == AppScreen.nowPlaying) {
          navigation.go(AppScreen.library);
        } else if (navigation.screen == AppScreen.detail) {
          navigation.backToPlaylists();
        } else if (navigation.screen != AppScreen.library) {
          navigation.go(AppScreen.library);
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.bg,
        body: Stack(
          children: [
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    fit: StackFit.expand,
                    children: [...previousChildren, ?currentChild],
                  ),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(activeTab),
                    child: _tab(activeTab),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasCurrent)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: MiniPlayer(),
                    ),
                  if (hasCurrent) const SizedBox(height: 8),
                  const _BottomNav(),
                ],
              ),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
                child: (navigation.screen == AppScreen.nowPlaying && hasCurrent)
                    ? const NowPlayingView(key: ValueKey('now_playing'))
                    : const SizedBox.shrink(key: ValueKey('empty_np')),
              ),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  );
                },
                child: navigation.createSheetOpen
                    ? const CreatePlaylistSheet(key: ValueKey('create_sheet'))
                    : const SizedBox.shrink(key: ValueKey('empty_cs')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tab(AppScreen tab) {
    switch (tab) {
      case AppScreen.playlists:
        return const PlaylistsView();
      case AppScreen.favorites:
        return const FavoritesView();
      case AppScreen.detail:
        return const PlaylistDetailView();
      case AppScreen.library:
      case AppScreen.nowPlaying:
        return const LibraryView();
    }
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final navigation = context.watch<NavigationController>();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.alpha(context.colors.bg, 0.88),
            border: Border(top: BorderSide(color: context.colors.divider)),
          ),
          padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.subject,
                  label: 'Biblioteca',
                  active: navigation.isLibraryTab,
                  onTap: () => navigation.go(AppScreen.library),
                ),
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Playlists',
                  active: navigation.isPlaylistsTab,
                  onTap: () => navigation.go(AppScreen.playlists),
                ),
                _NavItem(
                  icon: Icons.favorite_border,
                  label: 'Favoritas',
                  active: navigation.isFavoritesTab,
                  onTap: () => navigation.go(AppScreen.favorites),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? context.colors.accent2_700
        : context.colors.neutral600;
    return Expanded(
      child: InkResponse(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.bodyStyle(
                  size: 10.5,
                  weight: FontWeight.w700,
                  height: 1.2,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
