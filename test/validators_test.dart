import 'package:flutter_test/flutter_test.dart';
import 'package:ranger/utils/validators.dart';

void main() {
  test('email validator', () {
    expect(Validators.email(''), isNotNull);
    expect(Validators.email('a@b.c'), isNull);
    expect(Validators.email('bad'), isNotNull);
  });

  test('password validator', () {
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
  });
}
