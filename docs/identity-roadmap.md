# Identity Roadmap

## Follow-up TODO

- Preserve nickname-only players as a first-class quick-play path. A creator
  may add no contact data at all and still use the player in games.
- Allow creators to edit an unclaimed player later to add email or phone so the
  existing history can become claimable without creating a new player.
- Prevent double-claiming an already claimed player. A second auth account must
  not be able to take over a canonical player that already has a different
  `claimed_by_uid`.
- Reject split-identity claims when an email resolves to one player and a phone
  number resolves to another player.
- Store contact verification independently. If both email and phone exist, one
  verified contact is enough to claim the player; the other may remain
  unverified until the user chooses to verify it later.
- Add multi-contact support so one canonical player can own multiple verified
  emails and multiple verified phone numbers.
- Add account merge support. When a user adds a contact already attached to a
  different player, send a clickable verification link and merge the player
  records only after the challenged contact owner approves the merge through
  that link.
- Add a migration and repair path for legacy duplicate players, including
  rewriting `friends`, `player_game_info`, and embedded `games.players`.
- Decide whether local guest-game adoption should be automatic on shared
  devices or require an import prompt after login.
- Decide the product rule for a guest creator who never adds themselves as a
  game participant.
- Harden Firestore rules for verified claims, contact visibility, friend-edge
  mutation, and game mutation.
- Add the full end-to-end regression scenario:
  1. another user already has a remote game with a canonical player,
  2. a guest creates a local game with the same contact,
  3. that guest signs up and claims the contact,
  4. historical remote games and newly adopted local games converge on the same
     canonical player without creating duplicates.

## Implemented Foundation

- Normalize emails before lookup and persistence.
- Normalize phone numbers before lookup and persistence.
- Reserve normalized contacts in `player_contacts` so a contact maps to only one
  canonical player at a time.
- Allow an unclaimed player to be claimed by either a verified Firebase Auth
  email or a linked Firebase Auth phone number that matches a reserved contact.
- Allow a creator to add contact data later to an unclaimed player and create
  the missing contact reservations.
- Preserve a pending-claim state for an authenticated user whose matching
  player exists but whose contact is not verified yet.
- Provide an in-app pending-claim screen with email resend and refresh actions.
- Provide an in-app phone OTP linking flow for phone-only pending claims.

## Agreed Product Rules

- Players may be created with nickname only for quick play.
- Email and phone are optional.
- If one contact exists, verifying that one contact is enough to claim the
  player.
- If both contacts exist, they can be verified independently; the player becomes
  claimable after the first verified contact, and the second contact can remain
  unverified until later.
- A game creator may later add email or phone to an existing unclaimed player so
  historical games can be claimed in the future.
