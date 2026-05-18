import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/claim_account_screen.dart';
import 'package:mini_golf_tracker/database_connection.dart';
import 'package:mini_golf_tracker/player.dart';
import 'package:mini_golf_tracker/userprovider.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late UserProvider userProvider;

  setUp(() async {
    fakeFirestore = FakeFirebaseFirestore();
    DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore);
    SharedPreferences.setMockInitialValues({});
    userProvider = UserProvider();
    userProvider.resetForTesting();
    mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(
        uid: 'auth-user',
        email: 'claim@example.com',
        isEmailVerified: false,
      ),
    );
    userProvider.setAuthInstanceForTesting(mockAuth);
    await fakeFirestore.collection('players').doc('player-1').set(
          Player(
            id: 'player-1',
            playerName: 'Existing Player',
            nickname: 'Existing',
            ownerId: 'creator-1',
            totalScore: 0,
            email: 'claim@example.com',
            normalizedEmail: 'claim@example.com',
          ).toJson(),
        );
    await userProvider.initialize();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });

  Widget buildScreen() {
    return MaterialApp(home: ClaimAccountScreen(key: UniqueKey()));
  }

  testWidgets('shows pending contact verification status', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Claim Existing'), findsOneWidget);
    expect(find.text('claim@example.com'), findsOneWidget);
    expect(find.text('Unverified'), findsOneWidget);
    expect(find.text('Resend verification email'), findsOneWidget);
  });

  testWidgets('resends email verification and shows confirmation',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();

    expect(find.text('Verification email sent.'), findsOneWidget);
  });

  testWidgets('refresh claims player after verified email is available',
      (tester) async {
    mockAuth.mockUser = MockUser(
      uid: 'auth-user',
      email: 'claim@example.com',
      isEmailVerified: true,
    );

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('I verified my contact'));
    await tester.pumpAndSettle();

    expect(userProvider.loggedInUser?.id, 'player-1');
    expect(find.text('Player history claimed.'), findsOneWidget);
  });

  testWidgets('refresh keeps pending state when contact is still unverified',
      (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('I verified my contact'));
    await tester.pumpAndSettle();

    expect(userProvider.pendingClaimPlayer?.id, 'player-1');
    expect(
        find.text('No verified matching contact found yet.'), findsOneWidget);
  });

  testWidgets('shows email resend failures', (tester) async {
    whenCalling(Invocation.method(#sendEmailVerification, [null]))
        .on(mockAuth.currentUser!)
        .thenThrow(FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Email failed.',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Resend verification email'));
    await tester.pumpAndSettle();

    expect(find.text('Email failed.'), findsOneWidget);
  });

  testWidgets('shows refresh failures', (tester) async {
    whenCalling(Invocation.method(#reload, []))
        .on(mockAuth.currentUser!)
        .thenThrow(FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Refresh failed.',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('I verified my contact'));
    await tester.pumpAndSettle();

    expect(find.text('Refresh failed.'), findsOneWidget);
  });

  testWidgets('shows linked phone contact as verified', (tester) async {
    mockAuth.mockUser = MockUser(
      uid: 'auth-user',
      email: 'claim@example.com',
      phoneNumber: '+15551234567',
      isEmailVerified: false,
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('+15551234567'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
  });

  testWidgets('phone-only player can request and confirm SMS verification',
      (tester) async {
    await fakeFirestore.collection('players').doc('player-1').set(
          Player(
            id: 'player-1',
            playerName: 'Existing Player',
            nickname: 'Existing',
            ownerId: 'creator-1',
            totalScore: 0,
            phoneNumber: '+15551234567',
            normalizedPhoneNumber: '+15551234567',
          ).toJson(),
        );
    userProvider.beginPendingClaim(
      Player(
        id: 'player-1',
        playerName: 'Existing Player',
        nickname: 'Existing',
        ownerId: 'creator-1',
        totalScore: 0,
        phoneNumber: '+15551234567',
        normalizedPhoneNumber: '+15551234567',
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Send phone verification code'));
    await tester.pumpAndSettle();

    expect(find.text('Verification code sent.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    mockAuth.mockUser = MockUser(
      uid: 'auth-user',
      email: 'claim@example.com',
      phoneNumber: '+15551234567',
      isEmailVerified: false,
    );
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify phone number'));
    await tester.pumpAndSettle();

    expect(userProvider.loggedInUser?.id, 'player-1');
    expect(find.text('Player history claimed.'), findsOneWidget);
  });

  testWidgets('shows phone verification send failures', (tester) async {
    await fakeFirestore.collection('players').doc('player-1').set(
          Player(
            id: 'player-1',
            playerName: 'Existing Player',
            nickname: 'Existing',
            ownerId: 'creator-1',
            totalScore: 0,
            phoneNumber: '+15551234567',
            normalizedPhoneNumber: '+15551234567',
          ).toJson(),
        );
    userProvider.beginPendingClaim(
      Player(
        id: 'player-1',
        playerName: 'Existing Player',
        nickname: 'Existing',
        ownerId: 'creator-1',
        totalScore: 0,
        phoneNumber: '+15551234567',
        normalizedPhoneNumber: '+15551234567',
      ),
    );
    whenCalling(Invocation.method(#verifyPhoneNumber, null))
        .on(mockAuth)
        .thenThrow(FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Bad phone.',
        ));

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Send phone verification code'));
    await tester.pumpAndSettle();

    expect(find.text('Bad phone.'), findsOneWidget);
  });

  testWidgets('shows callback phone verification failures', (tester) async {
    await fakeFirestore.collection('players').doc('player-1').set(
          Player(
            id: 'player-1',
            playerName: 'Existing Player',
            nickname: 'Existing',
            ownerId: 'creator-1',
            totalScore: 0,
            phoneNumber: '+15551234567',
            normalizedPhoneNumber: '+15551234567',
          ).toJson(),
        );
    mockAuth = _CallbackFirebaseAuth.failure(
      mockUser: MockUser(
        uid: 'auth-user',
        email: 'claim@example.com',
        isEmailVerified: false,
      ),
    );
    userProvider.setAuthInstanceForTesting(mockAuth);
    userProvider.beginPendingClaim(
      Player(
        id: 'player-1',
        playerName: 'Existing Player',
        nickname: 'Existing',
        ownerId: 'creator-1',
        totalScore: 0,
        phoneNumber: '+15551234567',
        normalizedPhoneNumber: '+15551234567',
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Send phone verification code'));
    await tester.pumpAndSettle();

    expect(find.text('Callback failed.'), findsOneWidget);
  });

  testWidgets('handles phone code auto retrieval timeout', (tester) async {
    await fakeFirestore.collection('players').doc('player-1').set(
          Player(
            id: 'player-1',
            playerName: 'Existing Player',
            nickname: 'Existing',
            ownerId: 'creator-1',
            totalScore: 0,
            phoneNumber: '+15551234567',
            normalizedPhoneNumber: '+15551234567',
          ).toJson(),
        );
    mockAuth = _CallbackFirebaseAuth.timeout(
      mockUser: MockUser(
        uid: 'auth-user',
        email: 'claim@example.com',
        isEmailVerified: false,
      ),
    );
    userProvider.setAuthInstanceForTesting(mockAuth);
    userProvider.beginPendingClaim(
      Player(
        id: 'player-1',
        playerName: 'Existing Player',
        nickname: 'Existing',
        ownerId: 'creator-1',
        totalScore: 0,
        phoneNumber: '+15551234567',
        normalizedPhoneNumber: '+15551234567',
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Send phone verification code'));
    await tester.pumpAndSettle();

    expect(find.text('Send phone verification code'), findsOneWidget);
  });

  testWidgets('handles automatic phone verification callback', (tester) async {
    await fakeFirestore.collection('players').doc('player-1').set(
          Player(
            id: 'player-1',
            playerName: 'Existing Player',
            nickname: 'Existing',
            ownerId: 'creator-1',
            totalScore: 0,
            phoneNumber: '+15551234567',
            normalizedPhoneNumber: '+15551234567',
          ).toJson(),
        );
    mockAuth = _CallbackFirebaseAuth.completed(
      mockUser: MockUser(
        uid: 'auth-user',
        email: 'claim@example.com',
        isEmailVerified: false,
      ),
    );
    userProvider.setAuthInstanceForTesting(mockAuth);
    userProvider.beginPendingClaim(
      Player(
        id: 'player-1',
        playerName: 'Existing Player',
        nickname: 'Existing',
        ownerId: 'creator-1',
        totalScore: 0,
        phoneNumber: '+15551234567',
        normalizedPhoneNumber: '+15551234567',
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Send phone verification code'));
    await tester.pumpAndSettle();

    expect(find.text('Send phone verification code'), findsOneWidget);
  });

  testWidgets('shows phone confirmation failures', (tester) async {
    await fakeFirestore.collection('players').doc('player-1').set(
          Player(
            id: 'player-1',
            playerName: 'Existing Player',
            nickname: 'Existing',
            ownerId: 'creator-1',
            totalScore: 0,
            phoneNumber: '+15551234567',
            normalizedPhoneNumber: '+15551234567',
          ).toJson(),
        );
    userProvider.beginPendingClaim(
      Player(
        id: 'player-1',
        playerName: 'Existing Player',
        nickname: 'Existing',
        ownerId: 'creator-1',
        totalScore: 0,
        phoneNumber: '+15551234567',
        normalizedPhoneNumber: '+15551234567',
      ),
    );

    await tester.pumpWidget(buildScreen());
    await tester.tap(find.text('Send phone verification code'));
    await tester.pumpAndSettle();
    whenCalling(Invocation.method(#linkWithCredential, null))
        .on(mockAuth.currentUser!)
        .thenThrow(FirebaseAuthException(
          code: 'credential-already-in-use',
          message: 'Phone failed.',
        ));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Verify phone number'));
    await tester.pumpAndSettle();

    expect(find.text('Phone failed.'), findsOneWidget);
  });
}

class _CallbackFirebaseAuth extends MockFirebaseAuth {
  _CallbackFirebaseAuth.failure({required MockUser mockUser})
      : _mode = _PhoneCallbackMode.failure,
        super(signedIn: true, mockUser: mockUser);

  _CallbackFirebaseAuth.timeout({required MockUser mockUser})
      : _mode = _PhoneCallbackMode.timeout,
        super(signedIn: true, mockUser: mockUser);

  _CallbackFirebaseAuth.completed({required MockUser mockUser})
      : _mode = _PhoneCallbackMode.completed,
        super(signedIn: true, mockUser: mockUser);

  final _PhoneCallbackMode _mode;

  @override
  Future<void> verifyPhoneNumber({
    String? phoneNumber,
    PhoneMultiFactorInfo? multiFactorInfo,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    String? autoRetrievedSmsCodeForTesting,
    Duration timeout = const Duration(seconds: 30),
    int? forceResendingToken,
    Object? multiFactorSession,
  }) async {
    switch (_mode) {
      case _PhoneCallbackMode.failure:
        verificationFailed(FirebaseAuthException(
          code: 'invalid-phone-number',
          message: 'Callback failed.',
        ));
        return;
      case _PhoneCallbackMode.timeout:
        codeAutoRetrievalTimeout('verification-id');
        return;
      case _PhoneCallbackMode.completed:
        verificationCompleted(
          PhoneAuthProvider.credential(
            verificationId: 'verification-id',
            smsCode: '123456',
          ),
        );
        return;
    }
  }
}

enum _PhoneCallbackMode { failure, timeout, completed }
