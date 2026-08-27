import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/user_blog.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class UserBlogsScreen extends StatelessWidget {
  const UserBlogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final blogs = context.watch<UserProvider>().userBlogs;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My stories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/write-blog'),
        backgroundColor: AppColors.primaryAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Write story'),
      ),
      body: blogs.isEmpty
          ? const _EmptyStories()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: blogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _BlogCard(blog: blogs[index]),
            ),
    );
  }
}

class _EmptyStories extends StatelessWidget {
  const _EmptyStories();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.auto_stories_outlined, size: 56, color: AppColors.highlight),
            SizedBox(height: 16),
            Text('Your stories live here', style: TextStyle(color: AppColors.primaryText, fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'Write a thought, a reading note, or a short editorial. Stories stay private on this device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondaryText, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final UserBlog blog;

  const _BlogCard({required this.blog});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/write-blog', extra: blog),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete story',
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.mutedText),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                blog.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.secondaryText, height: 1.4),
              ),
              const SizedBox(height: 14),
              Text(
                'Updated ${_formatDate(blog.updatedAt)}',
                style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete story?'),
        content: const Text('This private story will be removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      await context.read<UserProvider>().deleteBlog(blog.id);
    }
  }
}

class UserBlogEditorScreen extends StatefulWidget {
  final UserBlog? blog;

  const UserBlogEditorScreen({super.key, this.blog});

  @override
  State<UserBlogEditorScreen> createState() => _UserBlogEditorScreenState();
}

class _UserBlogEditorScreenState extends State<UserBlogEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.blog?.title ?? '');
    _bodyController = TextEditingController(text: widget.blog?.body ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.blog != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit story' : 'Write story'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(color: AppColors.highlight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 24, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none, counterText: ''),
              ),
              const Divider(color: AppColors.divider),
              Expanded(
                child: TextField(
                  controller: _bodyController,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(color: AppColors.primaryText, fontSize: 16, height: 1.55),
                  decoration: const InputDecoration(hintText: 'Write your story…', border: InputBorder.none),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isEditing ? 'Save changes' : 'Save story'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title and story before saving.')));
      return;
    }
    await context.read<UserProvider>().saveBlog(existing: widget.blog, title: title, body: body);
    if (mounted) context.pop();
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  if (target == today) return 'today';
  if (target == today.subtract(const Duration(days: 1))) return 'yesterday';
  return '${date.day}/${date.month}/${date.year}';
}
