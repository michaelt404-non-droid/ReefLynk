import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/models/livestock.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/screens/livestock_form_screen.dart';
import 'package:reeflynk/theme/app_theme.dart';

class LivestockScreen extends StatelessWidget {
  const LivestockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Livestock'),
      ),
      body: StreamBuilder<List<Livestock>>(
        stream: db.getLivestockStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets_outlined, size: 64, color: AppColors.mutedFg),
                  const SizedBox(height: 16),
                  Text(
                    'No livestock yet',
                    style: theme.textTheme.titleMedium?.copyWith(color: AppColors.mutedFg),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first animal',
                    style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.mutedFg),
                  ),
                ],
              ),
            );
          }

          // Group by species type
          final grouped = <String, List<Livestock>>{};
          for (final type in Livestock.speciesTypes) {
            final group = items.where((i) => i.speciesType == type).toList();
            if (group.isNotEmpty) {
              grouped[type] = group;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final entry in grouped.entries) ...[
                _SectionHeader(title: entry.key, count: entry.value.fold(0, (sum, i) => sum + i.quantity)),
                ...entry.value.map((item) => _LivestockCard(item: item)),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LivestockFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, top: 4),
      child: Row(
        children: [
          Icon(_iconForType(title), size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Fish':
        return Icons.set_meal;
      case 'Coral':
        return Icons.park;
      case 'Invertebrate':
        return Icons.bug_report;
      case 'Cleanup Crew':
        return Icons.cleaning_services;
      default:
        return Icons.pets;
    }
  }
}

class _LivestockCard extends StatelessWidget {
  final Livestock item;

  const _LivestockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LivestockFormScreen(existingItem: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (item.imagePath != null && item.imagePath!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FutureBuilder<String>(
                      future: Provider.of<DatabaseService>(context, listen: false)
                          .createSignedUrl(item.imagePath!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: AppColors.card,
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: AppColors.card,
                            child: const Icon(Icons.error),
                          );
                        }
                        return Image.network(
                          snapshot.data!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Icon(Icons.pets, size: 30, color: AppColors.mutedFg),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(item.commonName, style: theme.textTheme.titleMedium),
                        if (item.quantity > 1) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'x${item.quantity}',
                              style: const TextStyle(fontSize: 12, color: AppColors.mutedFg),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.source != null && item.source!.isNotEmpty) ...[
                          Text(item.source!, style: theme.textTheme.bodySmall),
                          const SizedBox(width: 12),
                        ],
                        if (item.cost != null)
                          Text('\$${item.cost!.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Added ${dateFormatter.format(item.dateAdded)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: AppColors.destructive, size: 20),
                onPressed: () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Livestock'),
        content: Text('Remove ${item.commonName} from your inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await Provider.of<DatabaseService>(context, listen: false).deleteLivestock(item.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.commonName} removed')),
        );
      }
    }
  }
}
