import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/utils/tourism_data.dart';
import '../../../../core/utils/wikipedia_image_service.dart';

class PlaceImageWidget extends StatefulWidget {
  final TouristAttraction place;
  final double height;
  final double width;
  final BorderRadiusGeometry? borderRadius;

  const PlaceImageWidget({
    super.key,
    required this.place,
    this.height = 180,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  State<PlaceImageWidget> createState() => _PlaceImageWidgetState();
}

class _PlaceImageWidgetState extends State<PlaceImageWidget> {
  String? _realImageUrl;

  static const Map<AttractionCategory, String> categoryDefaultImages = {
    AttractionCategory.restaurant: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=600",
    AttractionCategory.cafe: "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?q=80&w=600",
    AttractionCategory.museum: "https://images.unsplash.com/photo-1582555172866-f73bb12a2ab3?q=80&w=600",
    AttractionCategory.park: "https://images.unsplash.com/photo-1502082553048-f009c37129b9?q=80&w=600",
    AttractionCategory.sport: "https://images.unsplash.com/photo-1517649763962-0c623066013b?q=80&w=600",
    AttractionCategory.entertainment: "https://images.unsplash.com/photo-1513151233558-d860c5398176?q=80&w=600",
    AttractionCategory.landmark: "https://images.unsplash.com/photo-1539650116574-8efeb43e2750?q=80&w=600",
    AttractionCategory.mosque: "https://images.unsplash.com/photo-1564507592333-c60657eea523?q=80&w=600",
    AttractionCategory.church: "https://images.unsplash.com/photo-1478147427282-58a87a120781?q=80&w=600",
    AttractionCategory.market: "https://images.unsplash.com/photo-1555529669-e69e7aa0ba9a?q=80&w=600",
    AttractionCategory.palace: "https://images.unsplash.com/photo-1599946347371-68eb71b16afc?q=80&w=600",
    AttractionCategory.monument: "https://images.unsplash.com/photo-1600577916048-804c9191e36c?q=80&w=600",
    AttractionCategory.university: "https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=600",
    AttractionCategory.transitHub: "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?q=80&w=600",
    AttractionCategory.localHub: "https://images.unsplash.com/photo-1519501025264-65ba15a82390?q=80&w=600",
  };

  @override
  void initState() {
    super.initState();
    _loadRealImage();
  }

  @override
  void didUpdateWidget(PlaceImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place.id != widget.place.id) {
      _loadRealImage();
    }
  }

  Future<void> _loadRealImage() async {
    final name = widget.place.name['en'] ?? widget.place.name['ar'] ?? '';
    if (name.isEmpty) return;

    if (widget.place.id.startsWith('osm_')) {
      if (mounted) {
        setState(() {
          _realImageUrl = null;
        });
      }
      final img = await WikipediaImageService.getRealImage(name);
      if (mounted) {
        setState(() {
          _realImageUrl = img;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _realImageUrl = widget.place.imageUrl;
        });
      }
    }
  }

  Widget _buildPlaceholderWidget(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
      ),
      child: Stack(
        children: [
          // Background metro image with opacity
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/metro.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                ),
              ),
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Theme.of(context).primaryColor.withOpacity(0.08),
                  ],
                ),
              ),
            ),
          ),
          // Category Emoji & Icon overlay
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.place.emoji.isNotEmpty ? widget.place.emoji : "📍",
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fallbackUrl = categoryDefaultImages[widget.place.category] ?? 
        TouristAttraction.defaultImage;
    final url = _realImageUrl ?? widget.place.imageUrl ?? fallbackUrl;

    final imageWidget = CachedNetworkImage(
      imageUrl: url,
      height: widget.height,
      width: widget.width,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 500),
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Theme.of(context).cardColor.withOpacity(0.5),
        highlightColor: Theme.of(context).cardColor.withOpacity(0.2),
        child: Container(
          height: widget.height,
          width: widget.width,
          color: Colors.white,
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholderWidget(context),
    );

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
