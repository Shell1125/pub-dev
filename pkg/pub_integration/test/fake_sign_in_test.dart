// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_integration/src/fake_pub_server_process.dart';
import 'package:pub_integration/src/headless_env.dart';
import 'package:test/test.dart';

void main() {
  group('fake sign in', () {
    late FakePubServerProcess fakePubServerProcess;
    late final HeadlessEnv headlessEnv;

    setUpAll(() async {
      fakePubServerProcess = await FakePubServerProcess.start();
      await fakePubServerProcess.started;
    });

    tearDownAll(() async {
      await headlessEnv.close();
      await fakePubServerProcess.kill();
    });

    test('bulk tests', () async {
      // start browser
      final origin = 'http://localhost:${fakePubServerProcess.port}';
      headlessEnv = HeadlessEnv(
        testName: 'fake_sign_in',
        origin: origin,
      );
      await headlessEnv.startBrowser();

      // sign-in page
      await headlessEnv.withPage(
        fn: (page) async {
          await page.gotoOrigin('/experimental?signin=1');
          final rs = await page.gotoOrigin('/sign-in?fake-email=user@pub.dev');
          final cookies = (await page.cookies()).map((e) => e.name).toSet();
          expect(cookies, contains('PUB_SID_INSECURE'));
          expect(cookies, contains('PUB_SSID_INSECURE'));
          expect(page.url, startsWith('$origin/sign-in/callback?'));
          expect(rs.status, 200);
          final content = await page.content;
          expect(content, contains('user@pub.dev'));
        },
      );

      // sign-in with redirect
      await headlessEnv.withPage(
        fn: (page) async {
          await page.gotoOrigin('/sign-in?fake-email=user@pub.dev&go=/help');
          final cookies = (await page.cookies()).map((e) => e.name).toSet();
          expect(cookies, contains('PUB_SID_INSECURE'));
          expect(cookies, contains('PUB_SSID_INSECURE'));
          expect(page.url, '$origin/help');
        },
      );
    });
  });
}