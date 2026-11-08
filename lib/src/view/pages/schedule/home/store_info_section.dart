import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../domain/domain.dart';
import '../../../../shared/shared.dart';
import '../../../view.dart';
import 'home_section.dart';

/// Endereço (com "Como chegar"), horários e contatos da loja.
class StoreInfoSection extends StatelessWidget {
  final SchedulePageController controller;

  const StoreInfoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final company = controller.company;
      if (company == null) return const SizedBox.shrink();

      final hasHours = company.configuration.openingHours.isNotEmpty &&
          company.configuration.closingTime.isNotEmpty;
      final hasAddress = !company.address.isEmpty;
      if (!hasHours && !hasAddress && !controller.hasContacts) {
        return const SizedBox.shrink();
      }

      return HomeSection(
        title: "Informações",
        child: Column(
          spacing: 12,
          children: [
            if (hasAddress) _AddressCard(company: company),
            if (hasHours) _HoursCard(configuration: company.configuration),
            if (controller.hasContacts) _ContactsCard(social: company.social),
          ],
        ),
      );
    });
  }
}

Future<void> _open(Uri? uri) async {
  if (uri == null || !await openLink(uri)) {
    showSnk("Não foi possível abrir o link");
  }
}

class _AddressCard extends StatelessWidget {
  final Company company;

  const _AddressCard({required this.company});

  @override
  Widget build(BuildContext context) {
    final address = company.address;
    final directions = StoreLinks.directions(company);

    return HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Icon(MdiIcons.mapMarkerOutline),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (address.streetLine.isNotEmpty)
                      Text(
                        address.streetLine,
                        style: const TextStyle(color: Colors.white),
                      ),
                    if (address.cityLine.isNotEmpty) Text(address.cityLine),
                  ],
                ),
              ),
            ],
          ),
          if (directions != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _open(directions),
                icon: Icon(MdiIcons.directions),
                label: const Text("Como chegar"),
              ),
            ),
        ],
      ),
    );
  }
}

class _HoursCard extends StatelessWidget {
  final CompanyConfiguration configuration;

  const _HoursCard({required this.configuration});

  static String _short(String value) =>
      value.length >= 5 ? value.substring(0, 5) : value;

  @override
  Widget build(BuildContext context) {
    final groups = WeeklyHours.of(configuration);
    final today = DateTime.now();

    return HomeCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Icon(MdiIcons.clockOutline),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                for (final group in groups)
                  _HoursRow(group: group, isToday: group.contains(today)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final WeeklyHours group;
  final bool isToday;

  const _HoursRow({required this.group, required this.isToday});

  @override
  Widget build(BuildContext context) {
    final hours = group.hours;
    final lunch = hours?.lunchBreak;
    final style = TextStyle(
      color: isToday ? Colors.white : null,
      fontWeight: isToday ? FontWeight.bold : null,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        SizedBox(width: 96, child: Text(group.label, style: style)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hours == null
                    ? "Fechado"
                    : "${_HoursCard._short(hours.openingHours)} às "
                          "${_HoursCard._short(hours.closingTime)}",
                style: style,
              ),
              if (lunch != null)
                Text(
                  "Almoço: ${_HoursCard._short(lunch.start)} às "
                  "${_HoursCard._short(lunch.end)}",
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactsCard extends StatelessWidget {
  final Social social;

  const _ContactsCard({required this.social});

  @override
  Widget build(BuildContext context) {
    final contacts = <(IconData, String, Uri?)>[
      (Icons.chat_outlined, "WhatsApp", StoreLinks.whatsapp(social.whatsapp)),
      (MdiIcons.phoneOutline, "Ligar", StoreLinks.phone(social.phone)),
      (Icons.photo_camera_outlined, "Instagram", StoreLinks.instagram(social.instagram)),
      (Icons.facebook, "Facebook", StoreLinks.facebook(social.facebook)),
      (MdiIcons.emailOutline, "E-mail", StoreLinks.email(social.email)),
    ].where((e) => e.$3 != null);

    return HomeCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (icon, label, uri) in contacts)
            ActionChip(
              avatar: Icon(icon, size: 18),
              label: Text(label),
              side: BorderSide(color: golden),
              onPressed: () => _open(uri),
            ),
        ],
      ),
    );
  }
}
