import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> property;

  const PropertyDetailsScreen({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> roomImages = [];

    try {
      if (property['room_images'] is String) {
        roomImages = List<String>.from(jsonDecode(property['room_images']));
      } else if (property['room_images'] is List) {
        roomImages = List<String>.from(property['room_images']);
      }
    } catch (_) {
      // JSON mal formé ou null
      roomImages = [];
    }

    return Scaffold(
      appBar: AppBar(title: Text(property['title'] ?? "Property Details")),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ✅ Image principale
            property['image_url'] != null
                ? Image.network(property['image_url'], height: 300, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: Center(child: Text("No Image Available")),
                  ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ✅ Titre
                  Text(property['title'] ?? "No Title",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                  SizedBox(height: 10),

                  /// ✅ Localisation
                  Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: const Color.fromARGB(255, 255, 0, 0)),
                        SizedBox(width: 5),
                        Text(property['location'], style: TextStyle(color: Colors.grey)),
                      ],
                    ),

                  SizedBox(height: 10),

                  /// ✅ Infos rapides
                  Row(
                  children: [
                      Icon(Icons.king_bed, size: 16, color: Colors.grey),
                      SizedBox(width: 5),
                      Text("${property['rooms']} rooms"),
                      SizedBox(width: 10),
                      Icon(Icons.bathtub, size: 16, color: Colors.grey),
                      SizedBox(width: 5),
                      Text("${property['bathrooms']} bathrooms"),
                      SizedBox(width: 10),
                      Icon(Icons.square_foot, size: 16, color: Colors.grey),
                      SizedBox(width: 5),
                      Text("${property['area']} m²"),
                    ],
                  ),

                  SizedBox(height: 20),

                  /// ✅ Description
                  Text("Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 5),
                  Text(property['description'] ?? "No description available", style: TextStyle(fontSize: 16)),

                  SizedBox(height: 20),


                  /// ✅ Bouton pour ouvrir Google Maps
                  ElevatedButton.icon(
                    onPressed: () {
                      String? mapLink = property['map_link'];
                      if (mapLink != null && Uri.tryParse(mapLink)?.isAbsolute == true) {
                        launchUrl(Uri.parse(mapLink));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lien Google Maps invalide")),
                        );
                      }
                    },
                    icon: Icon(Icons.map, color: Colors.white),
                    label: Text("Voir sur Google Maps"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),

                  SizedBox(height: 20),
                  /// ✅ Galerie
                  if (roomImages.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Rooms", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullImageGalleryScreen(images: roomImages),
                              ),
                            );
                          },
                          child: Text("View All Rooms", style: TextStyle(color: Colors.blue)),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: roomImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showFullScreenImage(context, roomImages[index]),
                            child: Container(
                              width: 150,
                              margin: EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(roomImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 20),
                  ],

                  /// ✅ Prix + Appel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${property['price']}",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _callNumber(context, property['phone']),
                        icon: Icon(Icons.phone),
                        label: Text("Call Us"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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

  /// 📞 Ouvre le composeur d’appel
  void _callNumber(BuildContext context, dynamic phone) async {
    final phoneNumber = phone?.toString() ?? '';
    if (phoneNumber.isEmpty || phoneNumber == "null") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No phone number available")),
      );
      return;
    }

    final Uri phoneUri = Uri.parse("tel:$phoneNumber");

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unable to call $phoneNumber")),
      );
    }
  }

  /// 🔍 Affiche l’image en plein écran
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(child: Image.network(imageUrl, fit: BoxFit.cover)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 📸 Écran galerie complète
class FullImageGalleryScreen extends StatelessWidget {
  final List<String> images;

  const FullImageGalleryScreen({Key? key, required this.images}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("All Rooms")),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _showFullScreenImage(context, images[index]),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(images[index], fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(child: Image.network(imageUrl, fit: BoxFit.cover)),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
