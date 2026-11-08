import '../../domain/domain.dart';

final class CompanyDto {
  final String? cnpj;
  final String? name;
  final String? logoUrl;
  final SocialDto? social;
  final CompanyConfigurationDto? configuration;
  final AddressDto? address;

  CompanyDto({
    this.cnpj,
    this.name,
    this.logoUrl,
    this.social,
    this.configuration,
    this.address
  });

  Map<String, dynamic> toJson() {
    return {
      if (cnpj?.isNotEmpty ?? false) 'cnpj': cnpj,
      if (name?.isNotEmpty ?? false) 'name': name,
      if (logoUrl?.isNotEmpty ?? false) 'logoUrl': logoUrl,
      if (social != null) 'social': social!.toJson(),
      if (configuration != null) 'configuration': configuration!.toJson(),
      if (address != null) 'address': address!.toJson(),
    };
  }
}

/// Atualização parcial: só os campos não nulos são enviados e `""` limpa o
/// campo na API.
final class SocialDto {
  final String? instagram;
  final String? facebook;
  final String? whatsapp;
  final String? email;
  final String? phone;

  SocialDto({
    this.instagram,
    this.facebook,
    this.whatsapp,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      if (instagram != null) 'instagram': instagram,
      if (facebook != null) 'facebook': facebook,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };
  }
}

/// Configuração parcial do `PATCH /company/:id`: só os campos enviados são
/// alterados. [workingDays], se enviado, substitui a lista inteira.
final class CompanyConfigurationDto {
  final int? defaultPeriodInMinutes;
  final String? openingHours;
  final String? closingTime;
  final LunchBreak? lunchBreak;
  final int? lockSchedulePeriodInMinutes;
  final List<WorkingDay>? workingDays;

  CompanyConfigurationDto({
    this.defaultPeriodInMinutes,
    this.openingHours,
    this.closingTime,
    this.lunchBreak,
    this.lockSchedulePeriodInMinutes,
    this.workingDays,
  });

  Map<String, dynamic> toJson() {
    return {
      if (defaultPeriodInMinutes != null)
        'defaultPeriodInMinutes': defaultPeriodInMinutes,
      if (openingHours?.isNotEmpty ?? false) 'openingHours': openingHours,
      if (closingTime?.isNotEmpty ?? false) 'closingTime': closingTime,
      if (lunchBreak != null) 'lunchBreak': lunchBreak!.toJson(),
      if (lockSchedulePeriodInMinutes != null)
        'lockSchedulePeriodInMinutes': lockSchedulePeriodInMinutes,
      if (workingDays != null)
        'workingDays': workingDays!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Atualização parcial: só os campos não nulos são enviados e `""` limpa o
/// campo na API.
final class AddressDto {
  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? cityCode;
  final String? state;
  final String? countryCode;

  AddressDto({
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.cityCode,
    this.state,
    this.countryCode,
  });

  Map<String, dynamic> toJson() {
    return {
      if (zipCode != null) 'zipCode': zipCode,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (city != null) 'city': city,
      if (cityCode != null) 'cityCode': cityCode,
      if (state != null) 'state': state,
      if (countryCode != null) 'countryCode': countryCode,
    };
  }
}
