class JwtDefaults {
  static const headerJson = '''{
  "alg": "RS256",
  "typ": "JWT"
}''';

  static const payloadJson = '''{
  "iss": "MYXL_APP",
  "user_dimension": "SUBS",
  "subs_id": 3012011036,
  "acc_nbr": "2200010552",
  "brand": "XL_PREPAID",
  "iat": 1784252995,
  "exp": 1853053769,
  "jti": "201432488"
}''';

  static const privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQCrBN0MaiEtSiNGMz+m+Dc6oQEqBoSbooF3AQ3S10VVuu3Je38A
CXmZodfgoOtzLQH5tKIPkJwZPp4Qo516M3Ar74/7QvKbz9w1PcLBSJ5LXrD18e/S
WqD4afQgl1o4b928x3r0NRIPxMDuPEzri6cfBtftaqo6wBGKgWaI8H+gTwIDAQAB
AoGBAKWNVbb43hkLlc4VOl8WFdDJn2jhWmmXDKD5AjrCbbop9JqA1FZi1bYld+dZ
n9OlFC538BIFOTcu6LDO0llDhidL6DS1y+PejusfHT5R34LitCOeuMJpRoP1y2yU
FaM8n5h4bhIZvr/+Ss//QSAVQoAn/MAk6dNkFvyWq0pZBRtRAkEA4JRllQQjMCyw
ijU/DVkY4LnkNFiec38ofevEa5Np0T5VDCVCP+o1Yj1jueYTotYZUhr1kGUvC7AL
DNcW9zq4UwJBAMLyH6yvr2Mv3udYza9WxXwa0+j5smv7j89N/VihfAKktgnVPr7x
kJXQWoXRrGibvGzV69RB5aUmiod8Xu85SJUCQFVZsJ2InAL0CQgNom/lO6I0o7kN
MPL+EZqBnv2vYZjnUpUyF9KIpU83u43sFexd5/OfUVJWUiHj/t8bY5wEEgcCQGRB
cNi2YVR5QgFoQh9yWI3CnkiqYX/3F7ZdPXVfVw9k9dmIuYQpZ1oklOlNM4V40iaG
vYmjeh68+3FCHPCaXSECPxmG3NAzDZZpfqVpEvu0/mi29ODZN9KaihwvTdl24pFZ
VgYYmMByxIDEJzVGbQiIW8MFmez9Aq1MKHn4oth9CA==
-----END RSA PRIVATE KEY-----''';

  static const publicKey = '''-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCrBN0MaiEtSiNGMz+m+Dc6oQEq
BoSbooF3AQ3S10VVuu3Je38ACXmZodfgoOtzLQH5tKIPkJwZPp4Qo516M3Ar74/7
QvKbz9w1PcLBSJ5LXrD18e/SWqD4afQgl1o4b928x3r0NRIPxMDuPEzri6cfBtft
aqo6wBGKgWaI8H+gTwIDAQAB
-----END PUBLIC KEY-----''';
}
