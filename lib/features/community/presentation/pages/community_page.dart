import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:rafiq_metrro/core/di/injection_container.dart';
import 'package:rafiq_metrro/core/theme/app_colors.dart';

import '../cubits/community_cubit.dart';
import '../cubits/community_state.dart';

import '../widgets/chat_view.dart';
import '../widgets/leaderboard_view.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CommunityCubit>()..loadCommunityData(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('community'.tr()),
            bottom: const TabBar(
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.chat), text: 'شات قطار'),
                Tab(icon: Icon(Icons.leaderboard), text: 'ترتيب 🏆'),
              ],
            ),
          ),
          body: BlocBuilder<CommunityCubit, CommunityState>(
            builder: (context, state) {
              if (state is CommunityLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CommunityLoaded) {
                return TabBarView(
                  children: [
                    ChatView(messages: state.messages),
                    LeaderboardView(reward: state.reward),
                  ],
                );
              } else if (state is CommunityError) {
                return Center(child: Text(state.message));
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}
