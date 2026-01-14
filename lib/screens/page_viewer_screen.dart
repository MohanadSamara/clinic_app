import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/page_provider.dart';
import '../models/page.dart' as page_model;
import '../../../translations.dart';

class PageViewerScreen extends StatefulWidget {
  final String slug;

  const PageViewerScreen({super.key, required this.slug});

  @override
  State<PageViewerScreen> createState() => _PageViewerScreenState();
}

class _PageViewerScreenState extends State<PageViewerScreen> {
  page_model.Page? _page;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final pageProvider = context.read<PageProvider>();
      final page = await pageProvider.getPageBySlug(widget.slug);

      if (mounted) {
        setState(() {
          _page = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _page == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('pageNotFound'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error ?? context.tr('pageNotFound'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadPage,
                child: Text(context.tr('retry')),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_page!.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Text(
              _page!.title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Page content
            Text(
              _page!.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.6, // Line height for better readability
              ),
            ),

            const SizedBox(height: 32),

            // Page metadata (optional, for debugging/admin purposes)
            if (context.read<PageProvider>().pages.any(
              (p) => p.id == _page!.id,
            )) ...[
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '${context.tr('lastUpdated')}: ${_formatDate(_page!.updatedAt ?? _page!.createdAt)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return context.tr('unknown');

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return context.tr('today');
    } else if (difference.inDays == 1) {
      return context.tr('yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${context.tr('daysAgo')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
