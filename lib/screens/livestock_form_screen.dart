import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reeflynk/models/livestock.dart';
import 'package:reeflynk/services/database_service.dart';
import 'package:reeflynk/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class LivestockFormScreen extends StatefulWidget {
  final Livestock? existingItem;

  const LivestockFormScreen({super.key, this.existingItem});

  @override
  State<LivestockFormScreen> createState() => _LivestockFormScreenState();
}

class _LivestockFormScreenState extends State<LivestockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _sourceController;
  late TextEditingController _costController;
  late String _speciesType;
  late DateTime _dateAdded;
  Uint8List? _pickedImageBytes;
  String? _imagePath;
  bool _isLoading = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.commonName ?? '');
    _quantityController = TextEditingController(text: (item?.quantity ?? 1).toString());
    _sourceController = TextEditingController(text: item?.source ?? '');
    _costController = TextEditingController(
      text: item?.cost != null ? item!.cost!.toStringAsFixed(2) : '',
    );
    _speciesType = item?.speciesType ?? 'Fish';
    _dateAdded = item?.dateAdded ?? DateTime.now();
    _imagePath = item?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _sourceController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);

    if (pickedFile != null) {
      final imageBytes = await pickedFile.readAsBytes();
      setState(() {
        _pickedImageBytes = imageBytes;
        // When a new image is picked, we nullify the existing image path
        // so the new image preview is shown.
        _imagePath = null;
      });
    }
  }

  Future<void> _save() async {
    print('DEBUG: _isEditing is $_isEditing'); // Add this line
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? finalImagePath = _imagePath;

    try {
      final db = Provider.of<DatabaseService>(context, listen: false);

      if (_pickedImageBytes != null) {
        final fileName = '${DateTime.now().toIso8601String()}.jpeg';
        finalImagePath = await db.uploadLivestockImage(_pickedImageBytes!, fileName);
      }

      final costText = _costController.text.trim();
      final item = Livestock(
        id: widget.existingItem?.id,
        commonName: _nameController.text.trim(),
        speciesType: _speciesType,
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        source: _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
        cost: costText.isEmpty ? null : double.tryParse(costText),
        dateAdded: _dateAdded,
        imagePath: finalImagePath,
      );

      if (_isEditing) {
        await db.updateLivestock(widget.existingItem!.id!, item);
      } else {
        await db.addLivestock(item);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Livestock updated' : 'Livestock added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving livestock: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateAdded,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateAdded = picked);
    }
  }

  Widget _buildImage() {
    // Show newly picked image
    if (_pickedImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(_pickedImageBytes!, fit: BoxFit.cover, width: 120, height: 120),
      );
    }
    // Show existing image from database
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      return FutureBuilder<String>(
        future: Provider.of<DatabaseService>(context, listen: false).createSignedUrl(_imagePath!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Icon(Icons.error, size: 50, color: AppColors.destructive);
          }
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(snapshot.data!, fit: BoxFit.cover, width: 120, height: 120),
          );
        },
      );
    }
    // Placeholder
    return Icon(Icons.photo_camera, size: 50, color: AppColors.mutedFg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Livestock' : 'Add Livestock'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Details', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: _buildImage(),
                            ),
                            TextButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.add_a_photo),
                              label: Text(_pickedImageBytes != null || (_imagePath != null && _imagePath!.isNotEmpty) ? 'Change Image' : 'Add Image'),
                            ),
                            if ((_imagePath != null && _imagePath!.isNotEmpty) || _pickedImageBytes != null)
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _imagePath = null;
                                    _pickedImageBytes = null;
                                  });
                                },
                                icon: const Icon(Icons.delete_forever, color: AppColors.destructive),
                                label: const Text('Remove Image', style: TextStyle(color: AppColors.destructive)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Common Name'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _speciesType,
                        decoration: const InputDecoration(labelText: 'Species Type'),
                        items: Livestock.speciesTypes.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t));
                        }).toList(),
                        onChanged: (v) => setState(() => _speciesType = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final n = int.tryParse(v.trim());
                          if (n == null || n < 1) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _sourceController,
                        decoration: const InputDecoration(
                          labelText: 'Source (optional)',
                          hintText: 'e.g., Local fish store',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _costController,
                        decoration: const InputDecoration(
                          labelText: 'Cost (optional)',
                          prefixText: '\$ ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Date Added'),
                        trailing: Text(
                          dateFormatter.format(_dateAdded),
                          style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.primary),
                        ),
                        onTap: _pickDate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'Update' : 'Add Livestock'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
