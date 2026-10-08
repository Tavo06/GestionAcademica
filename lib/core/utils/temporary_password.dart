import 'dart:math';

const _lower = 'abcdefghijkmnopqrstuvwxyz';
const _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const _digits = '23456789';
const _symbols = '!@#%*-_=+?';

/// Random throwaway password used only to satisfy
/// `createUserWithEmailAndPassword` during self-registration. It is never
/// shown, persisted or emailed: it lives in memory until the user sets their
/// real password. Always contains every character class so it passes any
/// password policy configured in Firebase Authentication.
String generateTemporaryPassword({int length = 32}) {
  final random = Random.secure();
  const all = _lower + _upper + _digits + _symbols;
  String pick(String chars) => chars[random.nextInt(chars.length)];

  final chars = [
    pick(_lower),
    pick(_upper),
    pick(_digits),
    pick(_symbols),
    for (var i = 4; i < length; i++) pick(all),
  ]..shuffle(random);
  return chars.join();
}
