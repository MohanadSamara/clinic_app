import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/page_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/page.dart' as page_model;
import '../../../translations.dart';

class PageManagementScreen extends StatefulWidget {
  const PageManagementScreen({super.key});

  @override
  State<PageManagementScreen> createState() => _PageManagementScreenState();
}

class _PageManagementScreenState extends State<PageManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PageProvider>().loadPages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Check if user is admin
    if (auth.user?.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('accessDenied'))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                context.tr('accessDenied'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(context.tr('noPermissionToAccessPage')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('pageManagement')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPageDialog(context),
            tooltip: context.tr('addPage'),
          ),
        ],
      ),
      body: Consumer<PageProvider>(
        builder: (context, pageProvider, child) {
          if (pageProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pageProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${pageProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => pageProvider.loadPages(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final pages = pageProvider.pages;

          if (pages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('noPagesFound'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('createFirstPage'),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showPageDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(context.tr('addPage')),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    page.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Slug: ${page.slug}'),
                      Text(
                        page.isPublished
                            ? context.tr('published')
                            : context.tr('draft'),
                        style: TextStyle(
                          color: page.isPublished
                              ? Colors.green
                              : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handleMenuAction(context, page, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: const Icon(Icons.edit),
                          title: Text(context.tr('edit')),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_publish',
                        child: ListTile(
                          leading: Icon(
                            page.isPublished
                                ? Icons.unpublished
                                : Icons.publish,
                          ),
                          title: Text(
                            page.isPublished
                                ? context.tr('unpublish')
                                : context.tr('publish'),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            context.tr('delete'),
                            style: const TextStyle(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showPageDialog(context, page: page),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    page_model.Page page,
    String action,
  ) {
    switch (action) {
      case 'edit':
        _showPageDialog(context, page: page);
        break;
      case 'toggle_publish':
        _togglePublishStatus(context, page);
        break;
      case 'delete':
        _deletePage(context, page);
        break;
    }
  }

  void _showPageDialog(BuildContext context, {page_model.Page? page}) {
    showDialog(
      context: context,
      builder: (context) => PageDialog(page: page),
    );
  }

  void _togglePublishStatus(BuildContext context, page_model.Page page) async {
    final pageProvider = context.read<PageProvider>();
    final success = await pageProvider.togglePublishStatus(page);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (page.isPublished
                      ? context.tr('pageUnpublished')
                      : context.tr('pagePublished'))
                : context.tr('errorUpdatingPage'),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _deletePage(BuildContext context, page_model.Page page) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('deletePage')),
        content: Text(
          context.tr('confirmDeletePage', args: {'title': page.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final pageProvider = context.read<PageProvider>();
              final success = await pageProvider.deletePage(page);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? context.tr('pageDeleted')
                          : context.tr('errorDeletingPage'),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
  }
}

class PageDialog extends StatefulWidget {
  final page_model.Page? page;

  const PageDialog({super.key, this.page});

  @override
  State<PageDialog> createState() => _PageDialogState();
}

class _PageDialogState extends State<PageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isPublished = true;

  @override
  void initState() {
    super.initState();
    if (widget.page != null) {
      _titleController.text = widget.page!.title;
      _slugController.text = widget.page!.slug;
      _contentController.text = widget.page!.content;
      _isPublished = widget.page!.isPublished;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.page != null;

    return AlertDialog(
      title: Text(isEditing ? context.tr('editPage') : context.tr('addPage')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.tr('pageTitle'),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('titleRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _slugController,
                decoration: InputDecoration(
                  labelText: context.tr('pageSlug'),
                  hintText: 'about-us, terms-of-service, etc.',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('slugRequired');
                  }
                  // Check for valid slug format (lowercase, hyphens, no spaces)
                  final slugRegex = RegExp(r'^[a-z0-9-]+$');
                  if (!slugRegex.hasMatch(value)) {
                    return context.tr('invalidSlugFormat');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: context.tr('pageContent'),
                  border: const OutlineInputBorder(),
                  hintText: context.tr('enterPageContent'),
                ),
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('contentRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(context.tr('publishPage')),
                subtitle: Text(context.tr('publishedPagesVisible')),
                value: _isPublished,
                onChanged: (value) => setState(() => _isPublished = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _savePage,
          child: Text(isEditing ? context.tr('update') : context.tr('create')),
        ),
      ],
    );
  }

  void _savePage() async {
    if (!_formKey.currentState!.validate()) return;

    final pageProvider = context.read<PageProvider>();
    final page = page_model.Page(
      id: widget.page?.id,
      title: _titleController.text.trim(),
      slug: _slugController.text.trim(),
      content: _contentController.text.trim(),
      isPublished: _isPublished,
      createdAt: widget.page?.createdAt,
      updatedAt: DateTime.now(),
    );

    bool success;
    if (widget.page != null) {
      success = await pageProvider.updatePage(page);
    } else {
      success = await pageProvider.createPage(page);
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.page != null
                  ? context.tr('pageUpdated')
                  : context.tr('pageCreated'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.page != null
                  ? context.tr('errorUpdatingPage')
                  : context.tr('errorCreatingPage'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
