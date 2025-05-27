import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditPropertyScreen extends StatefulWidget {
  final Map<String, dynamic>? property;
  final VoidCallback onSave;

  const EditPropertyScreen({
    super.key,
    required this.property,
    required this.onSave,
  });

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final List<TextEditingController> _controllers = List.generate(9, (_) => TextEditingController());
  final supabase = Supabase.instance.client;
  List<File> selectedImages = [];
  List<String> uploadedImageUrls = [];
  List<String> existingImageUrls = [];
  bool isLoading = false;
  String propertyType = "For Sale";

  final List<String> _labels = [
    'Title', 'Price', 'Location', 'Rooms', 
    'Bathrooms', 'Area (m²)', 'Description', 
    'Phone Number', 'Google Maps Link'
  ];

  @override
  void initState() {
    super.initState();
    final propertyData = widget.property ?? {};
    
    _controllers[0].text = propertyData['title']?.toString() ?? '';
    _controllers[1].text = propertyData['price']?.toString() ?? '';
    _controllers[2].text = propertyData['location']?.toString() ?? '';
    _controllers[3].text = propertyData['rooms']?.toString() ?? '';
    _controllers[4].text = propertyData['bathrooms']?.toString() ?? '';
    _controllers[5].text = propertyData['area']?.toString() ?? '';
    _controllers[6].text = propertyData['description']?.toString() ?? '';
    _controllers[7].text = propertyData['phone']?.toString() ?? '';
    _controllers[8].text = propertyData['map_link']?.toString() ?? '';
    propertyType = propertyData['property_type']?.toString() ?? 'For Sale';

    if (propertyData['room_images'] != null) {
      if (propertyData['room_images'] is List) {
        existingImageUrls = List<String>.from(
          (propertyData['room_images'] as List).map((url) => url.toString())
        );
      } else if (propertyData['room_images'] is String) {
        existingImageUrls = [propertyData['room_images'].toString()];
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImages() async {
    final pickedFiles = await ImagePicker().pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages = pickedFiles.map((file) => File(file.path)).take(4).toList();
      });
    }
  }

  Future<File> compressImage(File imageFile) async {
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 1024,
      minHeight: 1024,
      quality: 70,
    );
    
    if (result == null) return imageFile;
    
    final compressedBytes = result.toList();
    return File('${imageFile.path}_compressed.jpg')..writeAsBytesSync(compressedBytes);
  }

  Future<void> _uploadImages() async {
    if (selectedImages.isEmpty) return;
    
    setState(() => isLoading = true);
    uploadedImageUrls.clear();

    try {
      for (File image in selectedImages) {
        final compressedImage = await compressImage(image);
        final fileBytes = await compressedImage.readAsBytes();
        if (compressedImage.path != image.path) await compressedImage.delete();
        
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('property-images').uploadBinary(fileName, fileBytes);
        uploadedImageUrls.add(supabase.storage.from('property-images').getPublicUrl(fileName));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${uploadedImageUrls.length} images uploaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveProperty() async {
    setState(() => isLoading = true);

    final values = _controllers.map((c) => c.text).toList();
    if (values.any((v) => v.isEmpty) || (uploadedImageUrls.isEmpty && existingImageUrls.isEmpty)) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields and have at least one image')),
        );
      }
      return;
    }

    try {
      final allImageUrls = [...uploadedImageUrls, ...existingImageUrls];
      final propertyData = {
        'title': values[0],
        'price': double.tryParse(values[1]) ?? 0.0,
        'location': values[2],
        'rooms': int.tryParse(values[3]) ?? 0,
        'bathrooms': int.tryParse(values[4]) ?? 0,
        'area': int.tryParse(values[5]) ?? 0,
        'description': values[6],
        'phone': values[7],
        'map_link': values[8],
        'property_type': propertyType,
        'image_url': allImageUrls.isNotEmpty ? allImageUrls[0] : '',
        'room_images': allImageUrls,
        'user_id': Supabase.instance.client.auth.currentUser?.id,
        
      };

      if (widget.property != null && widget.property!['id'] != null) {
        await supabase.from('properties')
          .update(propertyData)
          .eq('id', widget.property!['id']);
      } else {
        await supabase.from('properties').insert(propertyData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.property != null 
              ? 'Property updated successfully' 
              : 'Property created successfully')),
        );
        widget.onSave();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildInputField(int index, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: _controllers[index],
        decoration: InputDecoration(
          labelText: _labels[index],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        keyboardType: keyboardType,
        maxLines: index == 6 ? 4 : 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property != null 
            ? 'Edit Property' 
            : 'Add Property'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Property Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(0),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(1, keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInputField(5, keyboardType: TextInputType.number)),
                          ],
                        ),
                        _buildInputField(2),
                        Row(
                          children: [
                            Expanded(child: _buildInputField(3, keyboardType: TextInputType.number)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildInputField(4, keyboardType: TextInputType.number)),
                          ],
                        ),
                        DropdownButtonFormField<String>(
                          value: propertyType,
                          items: ['For Sale', 'For Rent'].map((type) => 
                            DropdownMenuItem(value: type, child: Text(type))).toList(),
                          onChanged: (value) => setState(() => propertyType = value!),
                          decoration: InputDecoration(
                            labelText: 'Property Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(6),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(7, keyboardType: TextInputType.phone),
                        _buildInputField(8, keyboardType: TextInputType.url),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Property Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 16),
                        if (selectedImages.isEmpty && existingImageUrls.isEmpty)
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10)),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.image, size: 40, color: Colors.grey[400]),
                                  const SizedBox(height: 8),
                                  Text('No images selected', style: TextStyle(color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length + existingImageUrls.length,
                              itemBuilder: (context, index) {
                                if (index < selectedImages.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        selectedImages[index],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                } else {
                                  final urlIndex = index - selectedImages.length;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        existingImageUrls[urlIndex],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Select Images'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _pickImages,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                icon: const Icon(Icons.cloud_upload),
                                label: const Text('Upload'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _uploadImages,
                              ),
                            ),
                          ],
                        ),
                        if (uploadedImageUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${uploadedImageUrls.length} new image(s) uploaded',
                              style: TextStyle(color: Colors.green[700]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton(
                  onPressed: isLoading ? null : _saveProperty,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(widget.property != null 
                      ? 'Update Property' 
                      : 'Create Property', 
                    style: const TextStyle(fontSize: 16)),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}