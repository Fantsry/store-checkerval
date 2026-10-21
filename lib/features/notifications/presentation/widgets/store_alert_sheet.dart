import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:valorant_store_tracker/ui/theme/app_colors.dart';
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
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // ─── Drag Handle ─────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ─── Sheet Header ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 32,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ATURAN NOTIFIKASI SKIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Notifikasi otomatis untuk senjata & tier tertentu',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // ─── Rules List ──────────────────────────────────────────
          Expanded(
            child: BlocBuilder<StoreAlertCubit, StoreAlertState>(
              builder: (context, state) {
                if (state is StoreAlertLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (state is StoreAlertError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AppColors.accent),
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
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada aturan notifikasi aktif',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tambahkan aturan untuk Melee, Vandal, atau Ghost.',
                          style: TextStyle(
                            color: AppColors.textMuted.withValues(alpha: 0.8),
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
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
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
    final tierText = rule.tiers.isEmpty ? 'Semua Tier' : rule.tiers.join(', ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rule.isEnabled
              ? AppColors.accent.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: rule.isEnabled
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (rule.isEnabled ? AppColors.accent : AppColors.border),
              ),
            ),
            child: Icon(
              _getWeaponIcon(rule.weapon),
              size: 20,
              color: rule.isEnabled
                  ? AppColors.accent
                  : AppColors.textSecondary,
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
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Senjata: ${rule.weapon == "Any" ? "Semua" : rule.weapon} • Tier: $tierText',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: rule.isEnabled,
            activeColor: AppColors.accent,
            activeTrackColor: AppColors.accent.withValues(alpha: 0.3),
            onChanged: (val) {
              context.read<StoreAlertCubit>().toggleRule(rule.id, val);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
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
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.border),
      ),
      title: const Row(
        children: [
          Icon(Icons.add_alert_rounded, color: AppColors.accent),
          SizedBox(width: 8),
          Text(
            'Tambah Aturan Alert',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
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
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedWeapon,
                  isExpanded: true,
                  dropdownColor: AppColors.card,
                  items: _weapons.map((w) {
                    final String label;
                    switch (w) {
                      case 'Any':
                        label = 'Semua Senjata (All Weapons)';
                        break;
                      case 'Melee':
                        label = 'Melee / Pisau / Karambit';
                        break;
                      case 'Vandal':
                        label = 'Vandal (Rifle)';
                        break;
                      case 'Phantom':
                        label = 'Phantom (Rifle)';
                        break;
                      case 'Ghost':
                        label = 'Ghost (Sidearm)';
                        break;
                      case 'Sheriff':
                        label = 'Sheriff (Sidearm)';
                        break;
                      case 'Operator':
                        label = 'Operator (Sniper)';
                        break;
                      case 'Classic':
                        label = 'Classic (Sidearm)';
                        break;
                      case 'Spectre':
                        label = 'Spectre (SMG)';
                        break;
                      case 'Guardian':
                        label = 'Guardian (Rifle)';
                        break;
                      case 'Bulldog':
                        label = 'Bulldog (Rifle)';
                        break;
                      case 'Marshal':
                        label = 'Marshal (Sniper)';
                        break;
                      case 'Outlaw':
                        label = 'Outlaw (Sniper)';
                        break;
                      case 'Judge':
                        label = 'Judge (Shotgun)';
                        break;
                      case 'Bucky':
                        label = 'Bucky (Shotgun)';
                        break;
                      case 'Odin':
                        label = 'Odin (Heavy)';
                        break;
                      case 'Ares':
                        label = 'Ares (Heavy)';
                        break;
                      case 'Stinger':
                        label = 'Stinger (SMG)';
                        break;
                      case 'Frenzy':
                        label = 'Frenzy (Sidearm)';
                        break;
                      case 'Shorty':
                        label = 'Shorty (Sidearm)';
                        break;
                      default:
                        label = w;
                    }
                    return DropdownMenuItem(value: w, child: Text(label));
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
                color: AppColors.textSecondary,
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
                  selectedColor: AppColors.accent.withValues(alpha: 0.25),
                  checkmarkColor: AppColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                    side: BorderSide(
                      color: _selectedTiers.isEmpty
                          ? AppColors.accent.withValues(alpha: 0.5)
                          : AppColors.border,
                    ),
                  ),
                  onSelected: (_) {
                    setState(() => _selectedTiers.clear());
                  },
                ),
                ..._availableTiers.map((tier) {
                  final isSelected = _selectedTiers.contains(tier);
                  return FilterChip(
                    label: Text(tier),
                    selected: isSelected,
                    selectedColor: AppColors.accent.withValues(alpha: 0.25),
                    checkmarkColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.5)
                            : AppColors.border,
                      ),
                    ),
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
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _customNameController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.card,
                hintText: _selectedWeapon == 'Melee'
                    ? 'Setiap Melee'
                    : '$_selectedWeapon ${_selectedTiers.isEmpty ? "Semua Tier" : _selectedTiers.join("/")}',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'BATAL',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
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
