import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_cubit.dart';
import 'package:valorant_store_tracker/features/career/presentation/cubit/career_state.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_cubit.dart';
import 'package:valorant_store_tracker/features/daily_store/presentation/bloc/store_state.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:valorant_store_tracker/features/inventory/presentation/cubit/inventory_state.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:valorant_store_tracker/features/profile/presentation/cubit/profile_state.dart';
import 'package:valorant_store_tracker/l10n/l10n.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _EsportsBottomNav(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/store')) return 1;
    if (location.startsWith('/tracker') || location.startsWith('/career')) {
      return 2;
    }
    if (location.startsWith('/collection') ||
        location.startsWith('/inventory')) {
      return 3;
    }
    if (location.startsWith('/profile') || location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('home');
        if (context.read<ProfileCubit>().state is ProfileInitial) {
          context.read<ProfileCubit>().loadProfile();
        }
      case 1:
        context.goNamed('store');
        final storeState = context.read<StoreCubit>().state;
        if (storeState is StoreInitial ||
            (storeState is StoreLoaded &&
                storeState.store.remainingDurationSeconds <= 0)) {
          context.read<StoreCubit>().fetchStore();
        }
      case 2:
        context.goNamed('tracker');
        if (context.read<CareerCubit>().state is CareerInitial) {
          context.read<CareerCubit>().loadCareer();
        } else {
          context.read<CareerCubit>().loadCareer(forceRefresh: true);
        }
      case 3:
        context.goNamed('collection');
        if (context.read<InventoryCubit>().state is InventoryInitial) {
          context.read<InventoryCubit>().loadInventory();
        }
      case 4:
        context.goNamed('profile');
        if (context.read<ProfileCubit>().state is ProfileInitial) {
          context.read<ProfileCubit>().loadProfile();
        }
    }
  }
}

class _EsportsBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _EsportsBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              index: 0,
              label: context.l10n.navHome,
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard_rounded,
            ),
            _buildNavItem(
              index: 1,
              label: context.l10n.navStore,
              icon: Icons.storefront_outlined,
              activeIcon: Icons.storefront_rounded,
            ),
            _buildNavItem(
              index: 2,
              label: context.l10n.navTracker,
              icon: Icons.analytics_outlined,
              activeIcon: Icons.analytics_rounded,
            ),
            _buildNavItem(
              index: 3,
              label: context.l10n.navCollection,
              icon: Icons.shield_outlined,
              activeIcon: Icons.shield_rounded,
            ),
            _buildNavItem(
              index: 4,
              label: context.l10n.navProfile,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: AppColors.accent.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: SizedBox(
            height: 58,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  height: 2,
                  color: isSelected
                      ? AppColors.accent
                      : Colors.transparent,
                ),
                const Spacer(),
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label(
                    color: isSelected
                        ? AppColors.accent
                        : AppColors.textMuted,
                  ).copyWith(
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
