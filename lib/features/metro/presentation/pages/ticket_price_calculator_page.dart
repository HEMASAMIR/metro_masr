import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/utils/ad_service.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import 'package:rafiq_metrro/core/utils/metro_data.dart';
import 'package:rafiq_metrro/features/metro/domain/entities/station.dart'; // Assuming this path
import 'dart:collection'; // For Queue

class TicketPriceCalculatorPage extends StatefulWidget {
  const TicketPriceCalculatorPage({super.key});

  @override
  State<TicketPriceCalculatorPage> createState() =>
      _TicketPriceCalculatorPageState();
}

class _TicketPriceCalculatorPageState extends State<TicketPriceCalculatorPage> {
  // Counter to control interstitial ad frequency
  int _calculateButtonPressCount = 0;

  // Selected station IDs and names
  String? _startStationId;
  String? _destinationStationId;
  String? _startStationName;
  String? _destinationStationName;

  int _numberOfPassengers = 1;

  // Calculation results
  String _calculatedPrice = '';
  String _journeyTime = '';
  int _stationsCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize station names based on IDs if they were pre-selected (not in this case, but good practice)
    _updateStationNames();
  }

  void _updateStationNames() {
    final isAr = context.locale.languageCode == 'ar';
    setState(() {
      _startStationName = _startStationId != null
          ? (isAr
                ? MetroData.stations[_startStationId!]?.nameAr
                : MetroData.stations[_startStationId!]?.nameEn)
          : null;
      _destinationStationName = _destinationStationId != null
          ? (isAr
                ? MetroData.stations[_destinationStationId!]?.nameAr
                : MetroData.stations[_destinationStationId!]?.nameEn)
          : null;
    });
  }

  // --- Station Picker Logic ---
  Future<void> _showStationPicker(bool isStartStation) async {
    final isAr = context.locale.languageCode == 'ar';
    final selectedStationId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StationPickerBottomSheet(
        isAr: isAr,
        allStations: MetroData.stations.values.toList(),
      ),
    );

    if (selectedStationId != null) {
      setState(() {
        if (isStartStation) {
          _startStationId = selectedStationId;
        } else {
          _destinationStationId = selectedStationId;
        }
        _updateStationNames();
        // Clear previous calculation results if stations change
        _calculatedPrice = '';
        _journeyTime = '';
        _stationsCount = 0;
      });
    }
  }

  // --- Pathfinding and Calculation Logic ---
  // Simple BFS to find shortest path and station count
  int _findShortestPathStationCount(String startId, String endId) {
    if (startId == endId) return 0;

    final Queue<String> queue = Queue();
    final Map<String, int> distance = {};
    final Map<String, String> parent = {};

    queue.add(startId);
    distance[startId] = 0;

    while (queue.isNotEmpty) {
      final currentStationId = queue.removeFirst();
      final currentStation = MetroData.stations[currentStationId];

      if (currentStation == null) continue;

      if (currentStationId == endId) {
        // Path found, reconstruct and return count
        int count = 0;
        String? temp = endId;
        while (temp != null && temp != startId) {
          count++;
          temp = parent[temp];
        }
        return count;
      }

      for (final connectedStationId in currentStation.connectedTo) {
        if (!distance.containsKey(connectedStationId)) {
          distance[connectedStationId] = distance[currentStationId]! + 1;
          parent[connectedStationId] = currentStationId;
          queue.add(connectedStationId);
        }
      }
    }
    return -1; // No path found
  }

  void _performCalculation() {
    if (_startStationId == null || _destinationStationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select both stations first".tr())),
      );
      return;
    }
    if (_startStationId == _destinationStationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Choose a different destination!".tr())),
      );
      return;
    }

    final count = _findShortestPathStationCount(
      _startStationId!,
      _destinationStationId!,
    );

    if (count == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not find a route between these stations.".tr()),
        ),
      );
      setState(() {
        _calculatedPrice = '';
        _journeyTime = '';
        _stationsCount = 0;
      });
      return;
    }

    final pricePerPerson = MetroData.calculateTicketPrice(count);
    final totalPrice = pricePerPerson * _numberOfPassengers;
    final estimatedTime =
        count * 2 +
        (count ~/
            10 *
            5); // ~2 min per station, +5 min per 10 stations for transfers/wait

    setState(() {
      _stationsCount = count;
      _journeyTime = "$estimatedTime ${"Minutes".tr()}";
      _calculatedPrice = "$totalPrice ${"EGP".tr()}";
    });

    debugPrint(
      "Calculating ticket cost for $_numberOfPassengers passengers from $_startStationName to $_destinationStationName. Stations: $count, Price: $totalPrice",
    );
  }

  void _onCalculateButtonPressed() {
    _calculateButtonPressCount++;

    // Show interstitial ad every 3 clicks to avoid annoying the user
    if (_calculateButtonPressCount % 3 == 0) {
      AdService.showInterstitialAd(() {
        // This callback runs AFTER the ad is dismissed or fails to load
        _performCalculation();
      });
    } else {
      // If not showing an ad, just perform the calculation directly
      _performCalculation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text("Ticket Price Calculator".tr())),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Start Station Selection
            Text(
              "Start Station".tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildStationSelectionField(
              label: "Select Start Station".tr(),
              selectedName: _startStationName,
              onTap: () => _showStationPicker(true),
            ),
            const SizedBox(height: 16),

            // Destination Station Selection
            Text(
              "Destination Station".tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildStationSelectionField(
              label: "Select Destination Station".tr(),
              selectedName: _destinationStationName,
              onTap: () => _showStationPicker(false),
            ),
            const SizedBox(height: 16),

            // Number of Passengers
            Text(
              "Number of Passengers".tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildPassengerSelector(),
            const SizedBox(height: 24),

            // Calculate Button
            ElevatedButton(
              onPressed: _onCalculateButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Calculate".tr()),
            ),
            const SizedBox(height: 20),

            // Display results
            if (_calculatedPrice.isNotEmpty)
              Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Amount to Pay".tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculatedPrice,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${"Stations".tr()}: $_stationsCount, ${"Minutes".tr()}: $_journeyTime",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              "These are single-trip prices. Monthly subscription cards differ."
                  .tr(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSelectionField({
    required String label,
    String? selectedName,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.train_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedName ?? label,
                style: TextStyle(
                  color: selectedName != null
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Text("People".tr(), style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                if (_numberOfPassengers > 1) _numberOfPassengers--;
              });
            },
          ),
          Text(
            _numberOfPassengers.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            onPressed: () {
              setState(() {
                _numberOfPassengers++;
              });
            },
          ),
        ],
      ),
    );
  }
}

// --- Station Picker Bottom Sheet ---
class _StationPickerBottomSheet extends StatefulWidget {
  final bool isAr;
  final List<Station> allStations;

  const _StationPickerBottomSheet({
    required this.isAr,
    required this.allStations,
  });

  @override
  State<_StationPickerBottomSheet> createState() =>
      _StationPickerBottomSheetState();
}

class _StationPickerBottomSheetState extends State<_StationPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Station> _filteredStations = [];

  @override
  void initState() {
    super.initState();
    _filteredStations = widget.allStations;
    _searchController.addListener(_filterStations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStations = widget.allStations.where((station) {
        return station.nameEn.toLowerCase().contains(query) ||
            station.nameAr.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Text(
            widget.isAr ? '🚇 اختر محطة' : "🚇 Select a Station",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search...".tr(),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Station List
          Expanded(
            child: ListView.builder(
              itemCount: _filteredStations.length,
              itemBuilder: (context, index) {
                final station = _filteredStations[index];
                return ListTile(
                  leading: Icon(Icons.train_rounded, color: AppColors.primary),
                  title: Text(
                    widget.isAr ? station.nameAr : station.nameEn,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context, station.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
