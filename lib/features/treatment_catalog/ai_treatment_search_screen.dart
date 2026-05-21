import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/ai/ai_treatment_search_service.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:mega_panel_ai/features/treatment_catalog/treatment_detail_screen.dart';
import 'package:provider/provider.dart';

class AiTreatmentSearchScreen extends StatefulWidget {
  const AiTreatmentSearchScreen({super.key});

  @override
  State<AiTreatmentSearchScreen> createState() => _AiTreatmentSearchScreenState();
}

class _AiTreatmentSearchScreenState extends State<AiTreatmentSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  AiTreatmentSearchResult? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.aiSearchTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BlueprintTheme.heroGradient(
              primary: BlueprintTheme.coral,
              secondary: BlueprintTheme.gold,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.aiSearchTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  strings.aiSearchBody,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (!controller.aiSearchAvailable)
            _InfoCard(
              title: strings.aiSearchUnavailable,
              body: strings.aiSearchHelper,
              icon: Icons.info_outline,
            )
          else ...[
            _InfoCard(
              title: strings.aiDraftReviewTitle,
              body: strings.aiDraftReviewBody,
              icon: Icons.fact_check_outlined,
              accent: BlueprintTheme.gold,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: strings.aiSearchHint,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 32),
                  child: Icon(Icons.auto_awesome_outlined),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              strings.aiSearchHelper,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _loading ? null : () => _runSearch(context),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_loading ? strings.aiSearching : strings.aiSearchRun),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            _InfoCard(
              title: 'AI',
              body: _error!,
              icon: Icons.error_outline,
              accent: BlueprintTheme.coral,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 18),
            _InfoCard(
              title: strings.aiSearchSummaryTitle,
              body: strings.isSpanish ? _result!.summaryEs : _result!.summaryEn,
              icon: Icons.psychology_alt_outlined,
            ),
            const SizedBox(height: 16),
            _SectionTitle(strings.aiRecommendedExisting),
            const SizedBox(height: 10),
            ..._buildExistingRecommendations(context, _result!, controller),
            const SizedBox(height: 18),
            _SectionTitle(strings.aiProposedDrafts),
            const SizedBox(height: 10),
            ..._buildDraftRecommendations(context, _result!, controller),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildExistingRecommendations(
    BuildContext context,
    AiTreatmentSearchResult result,
    BlueprintController controller,
  ) {
    final strings = BlueprintStrings(controller.language);
    final widgets = <Widget>[];
    for (final id in result.recommendedExistingIds) {
      final treatment = controller.treatmentById(id);
      if (treatment == null) continue;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CompactTreatmentCard(treatment: treatment),
        ),
      );
    }
    if (widgets.isEmpty) {
      return [Text(strings.aiNoRecommendations)];
    }
    return widgets;
  }

  List<Widget> _buildDraftRecommendations(
    BuildContext context,
    AiTreatmentSearchResult result,
    BlueprintController controller,
  ) {
    final strings = BlueprintStrings(controller.language);
    if (result.proposedTreatments.isEmpty) {
      return [Text(strings.aiNoRecommendations)];
    }
    return result.proposedTreatments
        .map(
          (treatment) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BlueprintTheme.softPanel(),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(strings.originLabel(treatment.origin))),
                        Chip(
                          label: Text(
                            strings.evidenceLabel(treatment.evidenceLevel),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      treatment.title(strings.isSpanish),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(treatment.summary(strings.isSpanish)),
                    if (treatment.originSearchQuery?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${strings.aiDraftSearchQueryLabel}: ${treatment.originSearchQuery!.trim()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (treatment.sourceReferences(strings.isSpanish).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        strings.aiDraftSourcePreviewTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        strings.aiDraftSourceCount(
                          treatment.sourceReferences(strings.isSpanish).length,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      ...treatment
                          .sourceReferences(strings.isSpanish)
                          .take(2)
                          .map(
                            (reference) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• $reference',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TreatmentDetailScreen(treatment: treatment),
                              ),
                            );
                          },
                          icon: const Icon(Icons.open_in_new_outlined),
                          label: Text(strings.viewTreatmentDetail),
                        ),
                        const SizedBox(width: 10),
                        FilledButton.icon(
                          onPressed: () async {
                            final shouldSave =
                                await _confirmAddDraftToMyTreatments(
                              context,
                              treatment,
                            );
                            if (!shouldSave) return;
                            await controller.addDraftToMyTreatments(treatment.id);
                            if (!mounted) return;
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(strings.addedToMyTreatments),
                              ),
                            );
                          },
                          icon: const Icon(Icons.bookmark_add_outlined),
                          label: Text(strings.addToMyTreatments),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<void> _runSearch(BuildContext context) async {
    final controller = context.read<BlueprintController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await controller.searchTreatmentsWithAi(
        _queryController.text,
      );
      if (!mounted) return;
      setState(() => _result = result);
    } on AiTreatmentSearchException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _confirmAddDraftToMyTreatments(
    BuildContext context,
    WellnessTreatment treatment,
  ) async {
    final strings =
        BlueprintStrings(context.read<BlueprintController>().language);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.confirmAddAiDraftTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.confirmAddAiDraftBody),
            const SizedBox(height: 12),
            if (treatment.sourceReferences(strings.isSpanish).isNotEmpty)
              Text(
                strings.aiDraftSourceCount(
                  treatment.sourceReferences(strings.isSpanish).length,
                ),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.confirmAddAiDraftAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.icon,
    this.accent = BlueprintTheme.seafoam,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BlueprintTheme.softPanel(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTreatmentCard extends StatelessWidget {
  const _CompactTreatmentCard({required this.treatment});

  final WellnessTreatment treatment;

  @override
  Widget build(BuildContext context) {
    final strings =
        BlueprintStrings(context.watch<BlueprintController>().language);
    return DecoratedBox(
      decoration: BlueprintTheme.softPanel(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        title: Text(treatment.title(strings.isSpanish)),
        subtitle: Text(
          treatment.summary(strings.isSpanish),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TreatmentDetailScreen(treatment: treatment),
            ),
          );
        },
      ),
    );
  }
}
