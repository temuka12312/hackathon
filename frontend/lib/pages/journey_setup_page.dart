import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class JourneySetupPage extends StatefulWidget {
  const JourneySetupPage({
    super.key,
    required this.initialProfile,
    required this.directDistanceKm,
  });

  final String initialProfile;
  final double directDistanceKm;

  @override
  State<JourneySetupPage> createState() => _JourneySetupPageState();
}

class _JourneySetupPageState extends State<JourneySetupPage> {
  late String _selectedProfile = widget.initialProfile;

  static const _options = [
    _JourneyOption(
      label: 'Машин',
      shortStat: 'Car',
      profile: 'driving-car',
      icon: Icons.directions_car_filled_rounded,
      description: 'Ердийн автомашины тэнцвэртэй маршрут.',
    ),
    _JourneyOption(
      label: 'Явган',
      shortStat: 'Walk',
      profile: 'foot-walking',
      icon: Icons.directions_walk_rounded,
      description: 'Явган хүний зам, гарц ашигласан маршрут.',
    ),
    _JourneyOption(
      label: 'Wheelchair',
      shortStat: 'Access',
      profile: 'wheelchair',
      icon: Icons.accessible_forward_rounded,
      description: 'Шатгүй, илүү хүртээмжтэй хэсгийг давуу үзнэ.',
    ),
    _JourneyOption(
      label: 'Том машин',
      shortStat: 'HGV',
      profile: 'heavy-vehicle',
      icon: Icons.local_shipping_rounded,
      description: 'Том оврын автомашинд тохирсон зам.',
    ),
    _JourneyOption(
      label: 'Хурдан зам',
      shortStat: 'Fast',
      profile: 'taxi-fast',
      icon: Icons.local_taxi_rounded,
      description: 'Төв болон гол урсгалаар хурдан хүрэх маршрут.',
    ),
    _JourneyOption(
      label: 'Дөт зам',
      shortStat: 'Short',
      profile: 'driving-shortest',
      icon: Icons.alt_route_rounded,
      description: 'Жижиг замыг давуу үзсэн богино маршрут.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _options.firstWhere(
      (option) => option.profile == _selectedProfile,
      orElse: () => _options.first,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Аяллын төрөл',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.stroke),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(selected.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.directDistanceKm.toStringAsFixed(1)} км',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Явах төрлөө сонго',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final isSelected = option.profile == _selectedProfile;
                    return _JourneyOptionTile(
                      option: option,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedProfile = option.profile;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedProfile);
                  },
                  child: const Text('Энэ төрлөөр эхлүүлэх'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyOption {
  const _JourneyOption({
    required this.label,
    required this.shortStat,
    required this.profile,
    required this.icon,
    required this.description,
  });

  final String label;
  final String shortStat;
  final String profile;
  final IconData icon;
  final String description;
}

class _JourneyOptionTile extends StatelessWidget {
  const _JourneyOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _JourneyOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.stroke,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.16)
                    : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                option.icon,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        option.shortStat,
                        style: TextStyle(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.76)
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: TextStyle(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.82)
                          : AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}