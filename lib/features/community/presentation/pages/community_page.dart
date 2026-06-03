import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/di/injection_container.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';
import 'package:rafiq_metrro/features/chat/presentation/pages/groups_screen.dart';

import '../cubits/community_cubit.dart';
import '../cubits/community_state.dart';

import '../widgets/leaderboard_view.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommunityCubit>()..loadCommunityData(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.locale.languageCode == 'ar' ? 'مجتمع المترو' : 'Metro Community',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<CommunityCubit, CommunityState>(
          builder: (context, state) {
            if (state is CommunityLoading) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (ctx, i) => Shimmer.fromColors(
                  baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 100,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            } else if (state is CommunityLoaded) {
              return const MetroGroupsScreen();
            } else if (state is CommunityError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
