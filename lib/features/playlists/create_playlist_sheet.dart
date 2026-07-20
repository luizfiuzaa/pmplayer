import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/song.dart';
import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/song_cover.dart';
import '../navigation/navigation_controller.dart';
import 'create_playlist_view_model.dart';

/// Sheet "Nova playlist": nome + seleção de faixas. Fiel ao bloco CREATE
/// PLAYLIST SHEET do design (surge de baixo sobre um backdrop escuro).
class CreatePlaylistSheet extends StatefulWidget {
  const CreatePlaylistSheet({super.key});

  @override
  State<CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends State<CreatePlaylistSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  )..forward();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: context.read<CreatePlaylistViewModel>().name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navigation = context.read<NavigationController>();
    final curve = CurvedAnimation(
      parent: _controller,
      curve: const Cubic(0.22, 1, 0.36, 1),
    );

    return GestureDetector(
      onTap: navigation.closeCreateSheet,
      child: ColoredBox(
        color: AppColors.alpha(AppColors.neutral900, 0.45),
        child: FadeTransition(
          opacity: _controller,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curve),
              child: GestureDetector(
                onTap: () {}, // impede o toque de fechar ao interagir no sheet
                child: _SheetBody(nameController: _nameController),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.nameController});

  final TextEditingController nameController;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CreatePlaylistViewModel>();
    final library = context.read<LibraryStore>();
    final songs = library.songs;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x38000000), blurRadius: 32)],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18, top: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neutral400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Nova playlist',
                style: AppTypography.headingStyle(size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                'Nome da playlist',
                style: AppTypography.bodyStyle(
                  size: 12,
                  color: AppColors.alpha(AppColors.text, 0.7),
                ),
              ),
              const SizedBox(height: 5),
              _NameField(controller: nameController, onChanged: vm.setName),
              const SizedBox(height: 20),
              Text(
                'ADICIONAR MÚSICAS · ${vm.pickCount} SELECIONADAS',
                style: AppTypography.bodyStyle(
                  size: 12,
                  weight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: 1.2,
                  color: AppColors.neutral600,
                ),
              ),
              const SizedBox(height: 10),
              for (final song in songs)
                _PickRow(
                  song: song,
                  picked: vm.isPicked(song.id),
                  onToggle: () => vm.toggle(song.id),
                ),
              const SizedBox(height: 22),
              _CreateButton(enabled: vm.canCreate, onPressed: vm.submit),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      cursorColor: AppColors.accent,
      style: AppTypography.bodyStyle(size: 16),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Ex: Domingo devagar',
        hintStyle: AppTypography.bodyStyle(
          size: 16,
          color: AppColors.neutral500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.song,
    required this.picked,
    required this.onToggle,
  });

  final Song song;
  final bool picked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SongCover(song: song, size: 44, radius: 11, glyphSize: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStyle(
                      size: 14,
                      weight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStyle(
                      size: 12,
                      height: 1.3,
                      color: AppColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Checkbox(picked: picked),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.picked});

  final bool picked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: picked ? AppColors.accent2_500 : Colors.transparent,
        border: Border.all(
          color: picked ? AppColors.accent2_500 : AppColors.neutral400,
          width: 2,
        ),
      ),
      child: picked
          ? const Icon(Icons.check, size: 15, color: AppColors.bg)
          : null,
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: AppColors.accent2_500,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 52,
            child: Center(
              child: Text(
                'Criar playlist',
                style: AppTypography.headingStyle(
                  size: 17,
                  color: AppColors.bg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
