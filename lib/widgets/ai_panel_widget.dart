// lib/widgets/ai_panel_widget.dart
//
// Reusable AI integration panel — drop this into any card/screen that has
// the three AI columns:  aiDescription, aiComment, aiProcessed.
//
// Usage (read-only display):
//   AiInfoPanel(
//     aiDescription: entity.aiDescription,
//     aiComment:     entity.aiComment,
//     aiProcessed:   entity.aiProcessed,
//   )
//
// Usage (editable, for save/update forms):
//   AiInfoPanel(
//     aiDescription:    entity.aiDescription,
//     aiComment:        entity.aiComment,
//     aiProcessed:      entity.aiProcessed,
//     descController:   _aiDescController,   // provide TextEditingController
//     isEditable:       true,
//   )
//
// For Post only — pass the extra aiWillEditPost toggle:
//   AiInfoPanel(
//     ...
//     showEditPostToggle: true,
//     aiWillEditPost:     entity.aiWillEditPost,
//     onAiWillEditPostChanged: (val) => setState(() => entity.aiWillEditPost = val),
//   )

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class AiInfoPanel extends StatelessWidget {
  // ── display values ─────────────────────────────────────
  final String? aiDescription;
  final String? aiComment;
  final bool? aiProcessed;

  // ── editable mode ──────────────────────────────────────
  final bool isEditable;
  final TextEditingController? descController;

  // ── Post-only extra toggle ─────────────────────────────
  final bool showEditPostToggle;
  final bool? aiWillEditPost;
  final ValueChanged<bool>? onAiWillEditPostChanged;

  const AiInfoPanel({
    super.key,
    this.aiDescription,
    this.aiComment,
    this.aiProcessed,
    this.isEditable = false,
    this.descController,
    this.showEditPostToggle = false,
    this.aiWillEditPost,
    this.onAiWillEditPostChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool processed = aiProcessed == true;
    final bool hasComment =
        aiComment != null && aiComment!.trim().isNotEmpty;
    final bool hasDescription =
        aiDescription != null && aiDescription!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppTokens.isDark
            ? const Color(0xFF0D1117).withOpacity(0.6)
            : const Color(0xFFF0FFF4).withOpacity(0.8),
        border: Border.all(
          color: processed
              ? AppRawColors.neonGreen.withOpacity(0.45)
              : AppRawColors.cyan.withOpacity(0.25),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header bar ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: processed
                  ? AppRawColors.neonGreen.withOpacity(0.12)
                  : AppRawColors.cyan.withOpacity(0.08),
              child: Row(
                children: [
                  Icon(
                    processed
                        ? Icons.smart_toy_rounded
                        : Icons.smart_toy_outlined,
                    size: 16,
                    color: processed
                        ? AppRawColors.neonGreen
                        : AppRawColors.cyan,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    processed ? 'AI Analizi Tamamlandı' : 'AI Entegrasyonu',
                    style: AppTextStyles.bodySm.copyWith(
                      color: processed
                          ? AppRawColors.neonGreen
                          : AppTokens.accentReadable,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(processed: processed),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // aiDescription — editable in form mode
                  if (isEditable && descController != null) ...[
                    Text(
                      'AI Açıklaması (AI\'ya verilecek bağlam):',
                      style: AppTextStyles.labelKey,
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: descController,
                      maxLines: 3,
                      maxLength: 512,
                      style: AppTextStyles.bodyMd,
                      decoration: const InputDecoration(
                        hintText:
                        'AI\'nın bu kaydı analiz ederken kullanması için ek bağlam girin…',
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ] else if (hasDescription) ...[
                    Text('AI Bağlamı:', style: AppTextStyles.labelKey),
                    const SizedBox(height: 4),
                    Text(
                      aiDescription!,
                      style: AppTextStyles.bodyMd.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // aiComment — always read-only (written by backend AI)
                  if (hasComment) ...[
                    const _Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.comment_rounded,
                            size: 13,
                            color: AppTokens.accentReadable),
                        const SizedBox(width: 5),
                        Text('AI Yorumu:', style: AppTextStyles.labelKey),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTokens.isDark
                            ? AppRawColors.darkSurface
                            : AppRawColors.lightSurface,
                        borderRadius:
                        BorderRadius.circular(AppDimens.radiusSm),
                      ),
                      child: Text(
                        aiComment!,
                        style: AppTextStyles.bodyMd.copyWith(height: 1.55),
                      ),
                    ),
                  ],

                  // Post-only: aiWillEditPost toggle
                  if (showEditPostToggle) ...[
                    if (hasComment || hasDescription || isEditable)
                      const SizedBox(height: 12),
                    const _Divider(),
                    const SizedBox(height: 10),
                    _EditPostToggle(
                      value: aiWillEditPost ?? false,
                      onChanged: onAiWillEditPostChanged,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Post-only: AI Edit toggle with explanation
// ─────────────────────────────────────────────────────────────
class _EditPostToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _EditPostToggle({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: value
                ? AppRawColors.violet.withOpacity(0.15)
                : AppTokens.isDark
                ? AppRawColors.darkSurfaceRaised
                : AppRawColors.lightSurfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            value ? Icons.auto_fix_high_rounded : Icons.manage_search_rounded,
            size: 16,
            color: value ? AppRawColors.violet : AppTokens.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        // Text + switch
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'AI İçeriği Düzenlesin',
                      style: AppTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                        color: value
                            ? AppRawColors.violet
                            : AppTokens.textPrimary,
                      ),
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: AppRawColors.violet,
                    trackOutlineColor: WidgetStateProperty.all(
                      AppRawColors.violet.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              Text(
                value
                    ? 'AI başlığı, meta açıklamayı ve içeriği SEO kurallarına göre YENİDEN YAZACAK.'
                    : 'AI yalnızca kısa bir SEO meta-açıklaması ve tavsiye yorumu üretecek.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppTokens.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Small helpers
// ─────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final bool processed;
  const _StatusChip({required this.processed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: processed
            ? AppRawColors.neonGreen.withOpacity(0.15)
            : AppRawColors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: processed
              ? AppRawColors.neonGreen.withOpacity(0.4)
              : AppRawColors.amber.withOpacity(0.4),
        ),
      ),
      child: Text(
        processed ? 'İşlendi' : 'Bekliyor',
        style: AppTextStyles.bodySm.copyWith(
          color: processed ? AppRawColors.neonGreen : AppRawColors.amber,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppTokens.isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.06),
    );
  }
}