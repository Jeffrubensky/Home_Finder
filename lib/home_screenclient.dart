import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'property_details_screen.dart';

class HomeScreenClient extends StatefulWidget {
  const HomeScreenClient({super.key});

  @override
  HomeScreenClientState createState() => HomeScreenClientState();
}

class HomeScreenClientState extends State<HomeScreenClient> {
  final supabase = Supabase.instance.client;
  List<dynamic> properties = [];
  String searchQuery = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    try {
      final response = await supabase.from('properties').select('*');
      if (mounted) {
        setState(() {
          properties = response;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildFeatureIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final propertyType = property['property_type'] ?? 'À Vendre';
    final badgeColor = propertyType == 'À Vendre' ? Colors.orange : Colors.blue;
    final priceFormatted = '${property['price']?.toStringAsFixed(0) ?? '0'}\$';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyDetailsScreen(property: property),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    property['image_url']?.toString() ?? '',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[200],
                      child: const Icon(Icons.home, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      propertyType,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['title']?.toString() ?? 'Sans titre',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.red[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property['location']?.toString() ?? 'Localisation inconnue',
                          style: TextStyle(color: Colors.grey[600]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildFeatureIcon(Icons.king_bed, '${property['rooms'] ?? '0'}'),
                          const SizedBox(width: 12),
                          _buildFeatureIcon(Icons.bathtub, '${property['bathrooms'] ?? '0'}'),
                          const SizedBox(width: 12),
                          _buildFeatureIcon(Icons.square_foot, '${property['area'] ?? '0'} m²'),
                        ],
                      ),
                      Text(
                        priceFormatted,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher une propriété...',
              prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RefreshIndicator(
                onRefresh: _fetchProperties,
                child: properties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune propriété trouvée',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _fetchProperties,
                              child: const Text('Actualiser'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: properties.length,
                        itemBuilder: (context, index) {
                          final property = properties[index];

                          if (searchQuery.isNotEmpty &&
                              !(property['title']?.toString().toLowerCase().contains(searchQuery) ?? false) &&
                              !(property['location']?.toString().toLowerCase().contains(searchQuery) ?? false)) {
                            return const SizedBox.shrink();
                          }

                          return _buildPropertyCard(property);
                        },
                      ),
              ),
            ),
    );
  }
}
