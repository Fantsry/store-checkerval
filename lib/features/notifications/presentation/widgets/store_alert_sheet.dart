import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/app/theme.dart';
import 'package:valorant_store_tracker/features/notifications/domain/entities/store_alert_rule.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/cubit/store_alert_cubit.dart';
import 'package:valorant_store_tracker/features/notifications/presentation/cubit/store_alert_state.dart';

class StoreAlertSheet extends StatelessWidget {
  const StoreAlertSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<StoreAlertCubit>(),
        child: const StoreAlertSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppTheme.valorantRed, width: 2),
        ),
      ),
      child: Column(
        children: [
          // ─── Drag Handle ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ─── Sheet Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATURAN NOTIFIKASI SKIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Notifikasi otomatis untuk senjata & tier tertentu',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.surfaceLight, height: 1),

          // ─── Rules List ──────────────────────────────────────────
          Expanded(
            child: BlocBuilder<StoreAlertCubit, StoreAlertState>(
              builder: (context, state) {
                if (state is StoreAlertLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.valorantRed,
                    ),
                  );
                }

                if (state is StoreAlertError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AppTheme.valorantRed),
                    ),
                  );
                }

                final rules = state is StoreAlertLoaded ? state.rules : [];

                if (rules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          size: 48,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada aturan notifikasi aktif',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tambahkan aturan untuk Melee, Vandal, atau Ghost.',
                          style: TextStyle(
                            color: AppTheme.textMuted.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: rules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final rule = rules[index];
                    return _RuleCard(rule: rule);
                  },
                );
              },
            ),
          ),

          // ─── Add Rule Button ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.valorantRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'TAMBAH ATURAN NOTIFIKASI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                onPressed: () => _showAddRuleDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<StoreAlertCubit>(),
        child: const _AddRuleDialog(),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final StoreAlertRule rule;

  const _RuleCard({required this.rule});

  IconData _getWeaponIcon(String weapon) {
    final w = weapon.toLowerCase();
    if (w.contains('melee') ||
        w.contains('knife') ||
        w.contains('blade') ||
        w.contains('sword') ||
        w.contains('karambit') ||
        w.contains('axe')) {
      return Icons.hardware_rounded;
    } else if (w.contains('operator') ||
        w.contains('marshal') ||
        w.contains('outlaw')) {
      return Icons.track_changes_rounded;
    } else if (w.contains('vandal') || w.contains('phantom')) {
      return Icons.military_tech_rounded;
    } else if (w.contains('ghost') ||
        w.contains('sheriff') ||
        w.contains('classic') ||
        w.contains('frenzy') ||
        w.contains('shorty')) {
      return Icons.gps_fixed_rounded;
    } else if (w.contains('odin') || w.contains('ares')) {
      return Icons.local_fire_department_rounded;
    }
    return Icons.shield_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final tierText =
        rule.tiers.isEmpty ? 'Semua Tier' : rule.tiers.join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rule.isEnabled
              ? AppTheme.valorantRed.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rule.isEnabled
                  ? AppTheme.valorantRed.withValues(alpha: 0.15)
                  : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getWeaponIcon(rule.weapon),
              size: 20,
              color: rule.isEnabled
                  ? AppTheme.valorantRed
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: rule.isEnabled
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Senjata: ${rule.weapon == "Any" ? "Semua" : rule.weapon} • Tier: $tierText',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: rule.isEnabled,
            activeColor: AppTheme.valorantRed,
            onChanged: (val) {
              context.read<StoreAlertCubit>().toggleRule(rule.id, val);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: AppTheme.textMuted),
            onPressed: () {
              context.read<StoreAlertCubit>().deleteRule(rule.id);
            },
          ),
        ],
      ),
    );
  }
}

class _AddRuleDialog extends StatefulWidget {
  const _AddRuleDialog();

  @override
  State<_AddRuleDialog> createState() => _AddRuleDialogState();
}

class _AddRuleDialogState extends State<_AddRuleDialog> {
  String _selectedWeapon = 'Melee';
  final Set<String> _selectedTiers = {};
  final TextEditingController _customNameController = TextEditingController();

  static const List<String> _weapons = [
    'Melee',
    'Vandal',
    'Phantom',
    'Ghost',
    'Sheriff',
    'Operator',
    'Classic',
    'Spectre',
    'Guardian',
    'Marshal',
    'Outlaw',
    'Odin',
    'Ares',
    'Bulldog',
    'Judge',
    'Bucky',
    'Frenzy',
    'Shorty',
    'Stinger',
    'Any',
  ];

  static const List<String> _availableTiers = [
    'Select',
    'Deluxe',
    'Premium',
    'Exclusive',
    'Ultra',
  ];

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.valorantRed.withValues(alpha: 0.3),
        ),
      ),
      title: const Row(
        children: [
          Icon(Icons.add_alert_rounded, color: AppTheme.valorantRed),
          SizedBox(width: 8),
          Text(
            'Tambah Aturan Alert',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Weapon Selector ──────────────────────────────
            const Text(
              'PILIH SENJATA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedWeapon,
                  isExpanded: true,
                  dropdownColor: AppTheme.surfaceDark,
                  items: _weapons.map((w) {
                    final String label;
                    switch (w) {
                      case 'Any':
                        label = '🌟 Semua Senjata (All Weapons)';
                        break;
                      case 'Melee':
                        label = '🗡️ Melee / Pisau / Karambit';
                        break;
                      case 'Vandal':
                        label = '🎯 Vandal (Rifle)';
                        break;
                      case 'Phantom':
                        label = '👻 Phantom (Rifle)';
                        break;
                      case 'Ghost':
                        label = '🔫 Ghost (Sidearm)';
                        break;
                      case 'Sheriff':
                        label = '🔫 Sheriff (Sidearm)';
                        break;
                      case 'Operator':
                        label = '🔭 Operator (Sniper)';
                        break;
                      case 'Classic':
                        label = '🔫 Classic (Sidearm)';
                        break;
                      case 'Spectre':
                        label = '⚡ Spectre (SMG)';
                        break;
                      case 'Guardian':
                        label = '🛡️ Guardian (Rifle)';
                        break;
                      case 'Bulldog':
                        label = '🛡️ Bulldog (Rifle)';
                        break;
                      case 'Marshal':
                        label = '🔭 Marshal (Sniper)';
                        break;
                      case 'Outlaw':
                        label = '🔭 Outlaw (Sniper)';
                        break;
                      case 'Judge':
                        label = '💥 Judge (Shotgun)';
                        break;
                      case 'Bucky':
                        label = '💥 Bucky (Shotgun)';
                        break;
                      case 'Odin':
                        label = '🔥 Odin (Heavy)';
                        break;
                      case 'Ares':
                        label = '🔥 Ares (Heavy)';
                        break;
                      case 'Stinger':
                        label = '⚡ Stinger (SMG)';
                        break;
                      case 'Frenzy':
                        label = '🔫 Frenzy (Sidearm)';
                        break;
                      case 'Shorty':
                        label = '🔫 Shorty (Sidearm)';
                        break;
                      default:
                        label = w;
                    }
                    return DropdownMenuItem(
                      value: w,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedWeapon = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ─── Tier Filter ──────────────────────────────────
            const Text(
              'FILTER TIER KONTEN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: const Text('Semua Tier'),
                  selected: _selectedTiers.isEmpty,
                  selectedColor:
                      AppTheme.valorantRed.withValues(alpha: 0.25),
                  checkmarkColor: AppTheme.valorantRed,
                  onSelected: (_) {
                    setState(() => _selectedTiers.clear());
                  },
                ),
                ..._availableTiers.map((tier) {
                  final isSelected = _selectedTiers.contains(tier);
                  return FilterChip(
                    label: Text(tier),
                    selected: isSelected,
                    selectedColor:
                        AppTheme.valorantRed.withValues(alpha: 0.25),
                    checkmarkColor: AppTheme.valorantRed,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTiers.add(tier);
                        } else {
                          _selectedTiers.remove(tier);
                        }
                      });
                    },
                  );
                }),
              ],
            ),

            const SizedBox(height: 16),

            // ─── Label Custom (Optional) ──────────────────────
            const Text(
              'NAMA ATURAN (OPSIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customNameController,
              decoration: InputDecoration(
                hintText: _selectedWeapon == 'Melee'
                    ? '🗡️ Setiap Melee'
                    : '$_selectedWeapon ${_selectedTiers.isEmpty ? "Semua Tier" : _selectedTiers.join("/")}',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('BATAL',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.valorantRed,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            final customName = _customNameController.text.trim();
            final rule = StoreAlertRule(
              id: id,
              weapon: _selectedWeapon,
              tiers: _selectedTiers.toList(),
              isEnabled: true,
              customName: customName.isNotEmpty ? customName : null,
            );

            context.read<StoreAlertCubit>().addRule(rule);
            Navigator.of(context).pop();
          },
          child: const Text('SIMPAN'),
        ),
      ],
    );
  }
}
