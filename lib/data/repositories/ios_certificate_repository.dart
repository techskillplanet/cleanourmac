import '../../domain/models/ios_signing_certificate.dart';
import '../shell/ios_certificate_client.dart';

class IosCertificateRepository {
  final IosCertificateClient _client;

  IosCertificateRepository(this._client);

  Future<List<IosSigningCertificate>> list() => _client.listCertificates();

  Future<void> openKeychainAccess() => _client.openKeychainAccess();

  Future<void> importCertificate(String prompt) =>
      _client.importCertificate(prompt);

  Future<void> deleteExpiredCertificate(IosSigningCertificate certificate) =>
      _client.deleteExpiredCertificate(certificate);
}
