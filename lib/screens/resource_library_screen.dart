import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// 1. The Model
class Resource {
  final String title;
  final String category;
  final String description;
  final String link;
  final String type;

  Resource({required this.title, required this.category, required this.description, required this.link, required this.type});

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      title: json['title'] ?? 'No Title',
      category: json['category'] ?? 'General',
      description: json['description'] ?? '',
      link: json['link'] ?? '',
      type: json['type'] ?? 'Link',
    );
  }
}

class ResourceLibraryScreen extends StatefulWidget {
  const ResourceLibraryScreen({super.key});

  @override
  State<ResourceLibraryScreen> createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen> {
  String selectedCategory = 'All';
  late Future<List<Resource>> _resourceFuture;

  final List<String> categories = [
    'All', 'Programming', 'Networking', 'OS', 'Theory', 'Database'
  ];

  @override
  void initState() {
    super.initState();
    // Load once to avoid reloading on every build
    _resourceFuture = _loadResources();
  }

  // --- FIX 1: Defined _loadResources ---
  Future<List<Resource>> _loadResources() async {
    try {
      final String response = await rootBundle.loadString('assets/data/resources.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Resource.fromJson(json)).toList();
    } catch (e) {
      debugPrint("Error loading resources: $e");
      return [];
    }
  }

  // --- FIX 3: Defined _launchURL ---
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
    }
  }

  // --- FIX 2: Defined _buildResourceCard ---
  Widget _buildResourceCard(Resource item) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: InkWell(
      onTap: () => _launchURL(item.link),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(item.type == "Video" ? Icons.play_circle : Icons.article, color: Colors.deepPurple),
            const SizedBox(width: 12),
            // Use Expanded to prevent the horizontal/vertical overflow
            Expanded( 
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centers text vertically
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1, // Forces title to stay on one line
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2, // Forces description to max 2 lines
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(title: const Text("Study Resources")),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: selectedCategory == cat,
                  onSelected: (val) => setState(() => selectedCategory = cat),
                ),
              )).toList(),
            ),
          ),
          
          Expanded(
            child: FutureBuilder<List<Resource>>(
              future: _resourceFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final allResources = snapshot.data ?? [];
                final filtered = selectedCategory == 'All' 
                    ? allResources 
                    : allResources.where((r) => r.category == selectedCategory).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No resources found."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWeb ? 3 : 1,
                    childAspectRatio: isWeb ? 3.5 : 2.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildResourceCard(filtered[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}