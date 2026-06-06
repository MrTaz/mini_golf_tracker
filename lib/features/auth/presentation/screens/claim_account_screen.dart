import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mini_golf_tracker/core/config/assets.dart';
import 'package:mini_golf_tracker/core/providers/userprovider.dart';
import 'package:mini_golf_tracker/core/utils/utilities.dart';

class ClaimAccountScreen extends StatefulWidget {
  const ClaimAccountScreen({super.key});

  @override
  State<ClaimAccountScreen> createState() => _ClaimAccountScreenState();
}

class _ClaimAccountScreenState extends State<ClaimAccountScreen> {
  final TextEditingController _smsCodeController = TextEditingController();
  bool _isBusy = false;
  bool _smsCodeRequested = false;
  String? _message;
  String? _verificationId;

  @override
  void dispose() {
    _smsCodeController.dispose();
    super.dispose();
  }

  Future<void> _resendEmailVerification() async {
    final user = UserProvider().auth.currentUser;
    final isEffectivelyVerified = user?.emailVerified == true ||
        Utilities.isTestAccountBypass(user?.email);
    if (user == null || user.email == null || isEffectivelyVerified) {
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await user.sendEmailVerification();
      if (mounted) {
        setState(() {
          _message = 'Verification email sent.';
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message ?? 'Unable to send verification email.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _refreshClaim() async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      final claimedPlayer = await UserProvider().refreshPendingClaim();
      if (!mounted) {
        return;
      }
      setState(() {
        _message = claimedPlayer == null
            ? 'No verified matching contact found yet.'
            : 'Player history claimed.';
      });
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message ?? 'Unable to refresh verification status.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Database or network error. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _sendPhoneVerificationCode(String phoneNumber) async {
    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      await UserProvider().auth.verifyPhoneNumber(
            phoneNumber: phoneNumber,
            verificationCompleted: (_) {},
            verificationFailed: (error) {
              if (mounted) {
                setState(() {
                  _message = error.message ??
                      'Unable to send phone verification code.';
                  _isBusy = false;
                });
              }
            },
            codeSent: (verificationId, _) {
              if (mounted) {
                setState(() {
                  _verificationId = verificationId;
                  _smsCodeRequested = true;
                  _message = 'Verification code sent.';
                  _isBusy = false;
                });
              }
            },
            codeAutoRetrievalTimeout: (_) {
              if (mounted) {
                setState(() {
                  _isBusy = false;
                });
              }
            },
          );
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message ?? 'Unable to send phone verification code.';
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _confirmPhoneCode() async {
    final verificationId = _verificationId;
    final smsCode = _smsCodeController.text.trim();
    final user = UserProvider().auth.currentUser;
    if (verificationId == null || smsCode.isEmpty || user == null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _message = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await user.linkWithCredential(credential);
      await _refreshClaim();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() {
          _message = error.message ?? 'Unable to verify phone number.';
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = UserProvider().auth.currentUser;
    final pendingPlayer = UserProvider().pendingClaimPlayer;
    final claimablePhoneNumber =
        authUser?.phoneNumber == null ? pendingPlayer?.phoneNumber : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Claim Player History')),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AppImages.backgroundMainScreens,
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Card(
              margin: const EdgeInsets.all(20),
              color: Colors.white.withAlpha(235),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      pendingPlayer == null
                          ? 'Finish verifying your account'
                          : 'Claim ${pendingPlayer.nickname}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (authUser?.email != null)
                      _ClaimStatusRow(
                        label: authUser!.email!,
                        isVerified: authUser.emailVerified ||
                            Utilities.isTestAccountBypass(authUser.email),
                      ),
                    if (authUser?.phoneNumber != null)
                      _ClaimStatusRow(
                        label: authUser!.phoneNumber!,
                        isVerified: true,
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Verify one matching email or phone number to connect this account to past games.',
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!),
                    ],
                    const SizedBox(height: 20),
                    if (authUser?.email != null &&
                        !(authUser?.emailVerified == true ||
                            Utilities.isTestAccountBypass(authUser?.email)))
                      ElevatedButton(
                        onPressed:
                            _isBusy ? null : () => _resendEmailVerification(),
                        child: const Text('Resend verification email'),
                      ),
                    const SizedBox(height: 8),
                    if (claimablePhoneNumber != null) ...[
                      ElevatedButton(
                        onPressed: _isBusy
                            ? null
                            : () => _sendPhoneVerificationCode(
                                  claimablePhoneNumber,
                                ),
                        child: const Text('Send phone verification code'),
                      ),
                      if (_smsCodeRequested) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: _smsCodeController,
                          decoration:
                              const InputDecoration(labelText: 'SMS code'),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isBusy ? null : () => _confirmPhoneCode(),
                          child: const Text('Verify phone number'),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                    ElevatedButton(
                      onPressed: _isBusy ? null : () => _refreshClaim(),
                      child: const Text('I verified my contact'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isBusy ? null : () => UserProvider().logout(),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimStatusRow extends StatelessWidget {
  const _ClaimStatusRow({
    required this.label,
    required this.isVerified,
  });

  final String label;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.mark_email_unread,
            color: isVerified ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(isVerified ? 'Verified' : 'Unverified'),
        ],
      ),
    );
  }
}
