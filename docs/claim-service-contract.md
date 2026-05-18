# Firebase-Native Claim Contract

## Product Rules

- Players may exist with nickname only.
- Email and phone are optional.
- If one contact exists, verifying that one contact is enough to claim the
  canonical player.
- If both contacts exist, they are verified independently. The first verified
  contact may claim the player; the second may remain unverified until later.
- A game creator may add contact data to an unclaimed player later so old game
  history can become claimable.

## Claim Preconditions

A signed-in Firebase Auth user may claim an unclaimed canonical player when at
least one of these is true:

- `request.auth.token.email_verified == true` and the player's
  `normalized_email` equals `request.auth.token.email`
- `request.auth.token.phone_number` is present and the player's
  `normalized_phone_number` equals that token phone number

The player must not already have a different `claimed_by_uid`.

## Firebase-Native Verification

### Email

Use Firebase Auth email verification:

1. create the Firebase Auth user,
2. call `sendEmailVerification()`,
3. after the user clicks the Firebase email link, call `reload()`,
4. use `user.emailVerified` to decide whether email can claim the player.

### Phone

Use Firebase Phone Auth:

1. ask the user for their phone number,
2. call `verifyPhoneNumber()` on native platforms,
3. build a `PhoneAuthCredential` from the verification result,
4. link it to the signed-in user with `linkWithCredential()`,
5. use `user.phoneNumber` to decide whether phone can claim the player.

## App-Level Claim

Once one verified contact matches the canonical player:

1. set `claimed_by_uid` on the player,
2. leave any other provided contact unverified until the user verifies it later,
3. load the player's historical games by canonical player ID.

## Current Implementation Status

Implemented:

- normalized email and phone matching,
- contact reservations,
- rules-only canonical-player claiming through a verified Firebase email or
  linked Firebase phone,
- later contact addition for unclaimed players,
- an authenticated pending-claim state,
- an in-app pending-claim screen with email resend and refresh actions,
- an in-app phone OTP flow that links the verified phone credential to the
  current Firebase Auth user.

## Storage

- `players/{playerId}` stores the canonical player record.
- `player_contacts/{kind}_{normalized_value}` reserves each normalized contact
  for one canonical player.
- A contact reservation may exist before the user verifies that contact.

## Later Work

- Multi-email and multi-phone support.
- Merge approval when a new contact is already reserved by another player.
- Optional backend finalization if rules-only claiming becomes too limiting for
  future merge and audit requirements.
