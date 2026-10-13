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
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
import 'package:valorant_store_tracker/ui/theme/app_radius.dart';
import 'package:valorant_store_tracker/ui/theme/app_spacing.dart';
import 'package:valorant_store_tracker/ui/theme/app_text_styles.dart';

class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _AscendBottomNav(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/store')) return 1;
    if (location.startsWith('/tracker') || location.startsWith('/career')) return 2;
    if (location.startsWith('/collection') || location.startsWith('/inventory')) return 3;
    if (location.startsWith('/profile') || location.startsWith('/settings')) return 4;
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
        if (context.read<StoreCubit>().state is StoreInitial) {
          context.read<StoreCubit>().fetchStore();
        }
      case 2:
        context.goNamed('tracker');
        if (context.read<CareerCubit>().state is CareerInitial) {
          context.read<CareerCubit>().loadCareer();
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

class _AscendBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AscendBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'HOME',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'STORE',
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'TRACKER',
                icon: Icons.analytics_outlined,
                activeIcon: Icons.analytics_rounded,
              ),
              _buildNavItem(
                index: 3,
                label: 'COLLECTION',
                icon: Icons.shield_outlined,
                activeIcon: Icons.shield_rounded,
              ),
              _buildNavItem(
                index: 4,
                label: 'PROFILE',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
            ],
          ),
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

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.red.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: AppRadius.roundedPill,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? AppColors.red : AppColors.textSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTextStyles.badge(
                color: isSelected ? AppColors.red : AppColors.textSecondary,
              ).copyWith(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
