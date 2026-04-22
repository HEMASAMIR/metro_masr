import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/station.dart';

class IndoorMapWidget extends StatelessWidget {
  final Station station;

  const IndoorMapWidget({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        image: DecorationImage(
          image: const NetworkImage('https://i.imgur.com/vHq4CZe.png'), // A generic subtle grid pattern or clean background
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.white.withValues(alpha: 0.8), BlendMode.lighten),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.0,
          child: Stack(
            children: [
              // Central Platform
              Positioned(
                top: 100,
                bottom: 100,
                left: 60,
                right: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 4),
                  ),
                  child: Center(
                    child: Text(
                      'platform'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 2),
                    ),
                  ),
                ),
              ),
              
              // Train Tracks (Top and Bottom)
              Positioned(
                top: 70, left: 10, right: 10,
                child: Container(height: 10, color: AppColors.textSecondary.withValues(alpha: 0.3)),
              ),
              Positioned(
                bottom: 70, left: 10, right: 10,
                child: Container(height: 10, color: AppColors.textSecondary.withValues(alpha: 0.3)),
              ),

              // Facilities Mapping
              if (station.facilities.contains('atm'))
                _buildMapIcon(top: 20, right: 20, icon: Icons.atm, label: 'ATM', color: Colors.green),
                
              if (station.facilities.contains('ticket_office'))
                _buildMapIcon(top: 20, left: 20, icon: Icons.confirmation_number, label: 'TVM', color: Colors.orange),

              if (station.facilities.contains('wc'))
                _buildMapIcon(bottom: 20, right: 20, icon: Icons.wc, label: 'WC', color: Colors.blue),

              if (station.facilities.contains('elevator'))
                _buildMapIcon(bottom: 20, left: 80, icon: Icons.elevator, label: 'Elevator', color: AppColors.accent),

              // Exits
              ...station.exits.asMap().entries.map((entry) {
                int index = entry.key;
                double offset = 40.0 + (index * 60);
                return _buildMapIcon(
                  bottom: index % 2 == 0 ? 120 : null,
                  top: index % 2 != 0 ? 120 : null,
                  left: offset,
                  icon: Icons.exit_to_app,
                  label: 'Exit ${index + 1}',
                  color: AppColors.error,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapIcon({double? top, double? bottom, double? left, double? right, required IconData icon, required String label, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
