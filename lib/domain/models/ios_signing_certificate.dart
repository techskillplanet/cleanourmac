enum IosSigningCertificateKind { development, distribution }

enum IosSigningCertificateStatus {
  ready,
  expiringSoon,
  expired,
  notYetValid,
  missingPrivateKey,
}

class IosSigningCertificate {
  final String commonName;
  final String? teamId;
  final String? organization;
  final String issuer;
  final String serialNumber;
  final String sha1;
  final DateTime notBefore;
  final DateTime notAfter;
  final String keychainPath;
  final IosSigningCertificateKind kind;
  final bool hasPrivateKey;
  final bool isUsableForSigning;

  const IosSigningCertificate({
    required this.commonName,
    required this.teamId,
    required this.organization,
    required this.issuer,
    required this.serialNumber,
    required this.sha1,
    required this.notBefore,
    required this.notAfter,
    required this.keychainPath,
    required this.kind,
    required this.hasPrivateKey,
    required this.isUsableForSigning,
  });

  IosSigningCertificateStatus statusAt(
    DateTime now, {
    Duration expiringWindow = const Duration(days: 30),
  }) {
    final instant = now.toUtc();
    if (instant.isAfter(notAfter)) {
      return IosSigningCertificateStatus.expired;
    }
    if (instant.isBefore(notBefore)) {
      return IosSigningCertificateStatus.notYetValid;
    }
    if (!hasPrivateKey || !isUsableForSigning) {
      return IosSigningCertificateStatus.missingPrivateKey;
    }
    if (notAfter.difference(instant) <= expiringWindow) {
      return IosSigningCertificateStatus.expiringSoon;
    }
    return IosSigningCertificateStatus.ready;
  }

  bool isExpiredAt(DateTime now) => now.toUtc().isAfter(notAfter);

  int daysRemainingAt(DateTime now) => notAfter.difference(now.toUtc()).inDays;
}
