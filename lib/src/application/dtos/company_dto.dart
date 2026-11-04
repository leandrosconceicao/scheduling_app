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
      if (instagram?.isNotEmpty ?? false) 'instagram': instagram,
      if (facebook?.isNotEmpty ?? false) 'facebook': facebook,
      if (whatsapp?.isNotEmpty ?? false) 'whatsapp': whatsapp,
      if (email?.isNotEmpty ?? false) 'email': email,
      if (phone?.isNotEmpty ?? false) 'phone': phone,
    };
  }
}

final class CompanyConfigurationDto {
  final String? primaryColor;
  final String? secondaryColor;
  final String? timezone;
  final String? language;
  final String? currency;
  final bool? appointmentConfirmationRequired;

  CompanyConfigurationDto({
    this.primaryColor,
    this.secondaryColor,
    this.timezone,
    this.language,
    this.currency,
    this.appointmentConfirmationRequired,
  });

  Map<String, dynamic> toJson() {
    return {
      if (primaryColor?.isNotEmpty ?? false) 'primaryColor': primaryColor,
      if (secondaryColor?.isNotEmpty ?? false) 'secondaryColor': secondaryColor,
      if (timezone?.isNotEmpty ?? false) 'timezone': timezone,
      if (language?.isNotEmpty ?? false) 'language': language,
      if (currency?.isNotEmpty ?? false) 'currency': currency,
      if (appointmentConfirmationRequired != null)
        'appointmentConfirmationRequired': appointmentConfirmationRequired,
    };
  }
}

final class AddressDto {
  final String? zipCode;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;

  AddressDto({
    this.zipCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      if (zipCode?.isNotEmpty ?? false) 'zipCode': zipCode,
      if (street?.isNotEmpty ?? false) 'street': street,
      if (number?.isNotEmpty ?? false) 'number': number,
      if (complement?.isNotEmpty ?? false) 'complement': complement,
      if (neighborhood?.isNotEmpty ?? false) 'neighborhood': neighborhood,
      if (city?.isNotEmpty ?? false) 'city': city,
      if (state?.isNotEmpty ?? false) 'state': state,
    };
  }
}
