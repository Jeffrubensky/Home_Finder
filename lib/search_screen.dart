import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'property_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _properties = [];
  String? _locationFilter;

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    var query = supabase.from('properties').select();
    
    if (_locationFilter != null && _locationFilter!.isNotEmpty) {
      query = query.ilike('location', '%$_locationFilter%');
    }
    
    final response = await query;
    
    if (!mounted) return;
    setState(() {
      _properties = response;
    });
  }

  Widget _buildPropertyCard(Map<String, dynamic> property) {
    final propertyType = property['property_type'] ?? 'For Sale';
    final badgeColor = propertyType == 'For Sale' ? Colors.orange : Colors.blue;
    final priceFormatted = '\$${property['price'].toStringAsFixed(0)}';

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
            // Image avec badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    property['image_url'] ?? '',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    // errorBuilder: (context, error, stackTrace) {
                    //   return Container(
                    //     height: 180,
                    //     color: Colors.grey[200],
                    //     child: const Icon(Icons.home, size: 60, color: Colors.grey),
                    //   );
                    // },
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

            // Détails de la propriété
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property['title'] ?? 'No Title',
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
                          property['location'] ?? 'Location unknown',
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
                      // Icônes caractéristiques
                      Row(
                        children: [
                          _buildFeatureIcon(Icons.king_bed, '${property['rooms']}'),
                          const SizedBox(width: 12),
                          _buildFeatureIcon(Icons.bathtub, '${property['bathrooms']}'),
                          const SizedBox(width: 12),
                          _buildFeatureIcon(Icons.square_foot, '${property['area']} m²'),
                        ],
                      ),
                      // Prix
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

  Widget _buildFeatureIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Properties', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 📍 Filtre par localisation (conservé du code original)
            TextField(
              decoration: InputDecoration(
                labelText: "Filter by Location",
                prefixIcon: Icon(Icons.location_on, color: const Color.fromARGB(255, 255, 0, 0)),
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _locationFilter = value;
                });
                _fetchProperties();
              },
            ),

            const SizedBox(height: 20),

            /// 🏡 Affichage des annonces avec le nouveau style de cartes
            Expanded(
              child: _properties.isEmpty
                  ? const Center(child: Text("No results found"))
                  : ListView.builder(
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        return _buildPropertyCard(_properties[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}