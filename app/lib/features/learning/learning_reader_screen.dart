import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/learning_item.dart';
import '../../providers/providers.dart';

/// FR-7.3–7.5: full-screen summary reader with scroll-based progress
/// tracking, persisted so it resumes on any device (Supabase is the shared
/// store, not local-only state).
class LearningReaderScreen extends ConsumerStatefulWidget {
  const LearningReaderScreen({super.key, required this.item});
  final LearningItem item;

  @override
  ConsumerState<LearningReaderScreen> createState() =>
      _LearningReaderScreenState();
}

class _LearningReaderScreenState extends ConsumerState<LearningReaderScreen> {
  final _scrollController = ScrollController();
  Timer? _debounce;
  double _lastSaved = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.item.progressPct > 0 && widget.item.progressPct < 100) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target =
            _scrollController.position.maxScrollExtent *
            (widget.item.progressPct / 100);
        _scrollController.jumpTo(target);
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final pct = max <= 0
        ? 100.0
        : (_scrollController.offset / max * 100).clamp(0, 100);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if ((pct - _lastSaved).abs() < 2 && pct < 100) return;
      _lastSaved = pct.toDouble();
      ref
          .read(learningRepositoryProvider)
          .updateProgress(
            learningItemId: widget.item.id,
            progressPct: pct.toDouble(),
          )
          .then((_) {
            if (pct >= 100) ref.invalidate(learningItemsProvider);
          });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.title)),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
        children: [
          Text(
            widget.item.author,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            widget.item.summaryText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
          ),
        ],
      ),
    );
  }
}
