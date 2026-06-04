/**
 * Firestore Security Rules Unit Tests
 *
 * Tests the project's firestore.rules against the Firebase Local Emulator Suite
 * using @firebase/rules-unit-testing.
 *
 * Run with: npm test
 * Prerequisite: Firebase Emulators must be running on the configured ports
 *   OR the initializeTestEnvironment call loads rules directly (no emulator needed).
 */

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const { doc, getDoc, setDoc, updateDoc, deleteDoc, collection, getDocs } = require('firebase/firestore');
const fs = require('fs');
const path = require('path');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Minimal valid player document that satisfies firestore.rules create rules. */
function validPlayer(playerId) {
  return {
    id: playerId,
    player_name: 'Test Player',
    nickname: 'Tester',
    total_score: 0,
  };
}

// ---------------------------------------------------------------------------
// Test suite
// ---------------------------------------------------------------------------

describe('Firestore Security Rules', () => {
  let testEnv;

  beforeAll(async () => {
    const rulesPath = path.resolve(__dirname, '..', 'firestore.rules');
    testEnv = await initializeTestEnvironment({
      projectId: 'demo-mini-golf-tracker',
      firestore: {
        rules: fs.readFileSync(rulesPath, 'utf8'),
        // Point at the Firestore emulator port defined in firebase.json.
        host: 'localhost',
        port: 8080,
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // -------------------------------------------------------------------------
  // players collection — READ rules
  // -------------------------------------------------------------------------

  describe('players collection — reads', () => {
    beforeEach(async () => {
      // Seed a player document via the admin context so rules don't block setup.
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'players', 'player-1'), validPlayer('player-1'));
      });
    });

    it('allows an UNAUTHENTICATED user to read a player document (allow read: if true)', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playerRef = doc(unauthedCtx.firestore(), 'players', 'player-1');
      await assertSucceeds(getDoc(playerRef));
    });

    it('allows an AUTHENTICATED user to read a player document', async () => {
      const authedCtx = testEnv.authenticatedContext('uid-alice');
      const playerRef = doc(authedCtx.firestore(), 'players', 'player-1');
      await assertSucceeds(getDoc(playerRef));
    });

    it('allows an UNAUTHENTICATED user to list the players collection (allow read: if true)', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playersRef = collection(unauthedCtx.firestore(), 'players');
      await assertSucceeds(getDocs(playersRef));
    });
  });

  // -------------------------------------------------------------------------
  // players collection — CREATE rules
  // -------------------------------------------------------------------------

  describe('players collection — creates', () => {
    it('DENIES an unauthenticated user from creating a player with an invalid schema', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      // Missing required fields — total_score is non-zero.
      const badPlayer = { id: 'new-player', player_name: 'Bad', nickname: 'Bad', total_score: 99 };
      const playerRef = doc(unauthedCtx.firestore(), 'players', 'new-player');
      await assertFails(setDoc(playerRef, badPlayer));
    });

    it('ALLOWS any user to create a player with a valid schema (guest-friendly)', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playerId = 'brand-new-player';
      const playerRef = doc(unauthedCtx.firestore(), 'players', playerId);
      await assertSucceeds(setDoc(playerRef, validPlayer(playerId)));
    });

    it('DENIES creation when the document id does not match the id field', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      // document id is 'doc-id' but the payload says 'wrong-id'
      const playerRef = doc(unauthedCtx.firestore(), 'players', 'doc-id');
      await assertFails(setDoc(playerRef, { ...validPlayer('wrong-id') }));
    });

    it('DENIES creation when player_name is empty', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playerId = 'empty-name-player';
      const playerRef = doc(unauthedCtx.firestore(), 'players', playerId);
      await assertFails(setDoc(playerRef, { ...validPlayer(playerId), player_name: '' }));
    });
  });

  // -------------------------------------------------------------------------
  // players collection — UPDATE rules (score-only path)
  // -------------------------------------------------------------------------

  describe('players collection — updates', () => {
    const EXISTING_PLAYER_ID = 'existing-player';

    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(
          doc(ctx.firestore(), 'players', EXISTING_PLAYER_ID),
          validPlayer(EXISTING_PLAYER_ID),
        );
      });
    });

    it('ALLOWS any user to update only the total_score field (peer scoring rule)', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playerRef = doc(unauthedCtx.firestore(), 'players', EXISTING_PLAYER_ID);
      // Case 2 in firestore.rules: score-only update, any user allowed.
      await assertSucceeds(
        updateDoc(playerRef, {
          id: EXISTING_PLAYER_ID,
          player_name: 'Test Player',
          nickname: 'Tester',
          total_score: 10,
        }),
      );
    });

    it('ALLOWS an authenticated user to claim an unclaimed player via claimed_by_uid (verified email path)', async () => {
      // Seed an unclaimed player with a normalized_email that matches the auth token.
      const claimablePlayerId = 'claimable-player';
      const claimableEmail = 'alice@example.com';

      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'players', claimablePlayerId), {
          ...validPlayer(claimablePlayerId),
          normalized_email: claimableEmail,
          claimed_by_uid: null,
        });
      });

      // Authenticated user with a verified email matching the player's normalized_email.
      const authedCtx = testEnv.authenticatedContext('uid-alice', {
        email: claimableEmail,
        email_verified: true,
      });
      const playerRef = doc(authedCtx.firestore(), 'players', claimablePlayerId);

      await assertSucceeds(
        updateDoc(playerRef, { claimed_by_uid: 'uid-alice' }),
      );
    });
  });

  // -------------------------------------------------------------------------
  // players collection — DELETE rules
  // -------------------------------------------------------------------------

  describe('players collection — deletes', () => {
    const OWNED_PLAYER_ID = 'owned-player';
    const OWNER_UID = 'uid-owner';

    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'players', OWNED_PLAYER_ID), {
          ...validPlayer(OWNED_PLAYER_ID),
          owner_id: OWNER_UID,
        });
      });
    });

    it('DENIES an unauthenticated user from deleting a player', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playerRef = doc(unauthedCtx.firestore(), 'players', OWNED_PLAYER_ID);
      await assertFails(deleteDoc(playerRef));
    });

    it('DENIES a different authenticated user from deleting a player they do not own', async () => {
      const otherCtx = testEnv.authenticatedContext('uid-other');
      const playerRef = doc(otherCtx.firestore(), 'players', OWNED_PLAYER_ID);
      await assertFails(deleteDoc(playerRef));
    });

    it('ALLOWS the owner to delete their own player document', async () => {
      const ownerCtx = testEnv.authenticatedContext(OWNER_UID);
      const playerRef = doc(ownerCtx.firestore(), 'players', OWNED_PLAYER_ID);
      await assertSucceeds(deleteDoc(playerRef));
    });
  });

  // -------------------------------------------------------------------------
  // player_game_info collection — auth-gated reads
  // -------------------------------------------------------------------------

  describe('player_game_info collection — reads', () => {
    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'player_game_info', 'game1_player1'), {
          game_id: 'game1',
          player_id: 'player1',
          place: '1st',
          play_order_position: 0,
          scores: [],
          total_score: 0,
        });
      });
    });

    it('DENIES an unauthenticated user from reading player_game_info (allow read: if isLoggedIn())', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const infoRef = doc(unauthedCtx.firestore(), 'player_game_info', 'game1_player1');
      await assertFails(getDoc(infoRef));
    });

    it('ALLOWS an authenticated user to read player_game_info', async () => {
      const authedCtx = testEnv.authenticatedContext('uid-alice');
      const infoRef = doc(authedCtx.firestore(), 'player_game_info', 'game1_player1');
      await assertSucceeds(getDoc(infoRef));
    });
  });

  // -------------------------------------------------------------------------
  // games collection — MUTATION rules
  // -------------------------------------------------------------------------

  describe('games collection — mutations', () => {
    const GAME_ID = 'game-1';
    const CREATOR_UID = 'uid-creator';
    const PARTICIPANT_UID = 'uid-participant';
    const OTHER_UID = 'uid-other';

    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'games', GAME_ID), {
          id: GAME_ID,
          name: 'Fun Golf Game',
          status: 'started',
          creator_id: CREATOR_UID,
          participant_ids: [CREATOR_UID, PARTICIPANT_UID],
          players: [],
          course: {},
        });
      });
    });

    it('DENIES unauthenticated user from updating any game', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const gameRef = doc(unauthedCtx.firestore(), 'games', GAME_ID);
      await assertFails(
        updateDoc(gameRef, {
          name: 'Updated Game Name',
        })
      );
    });

    it('DENIES a non-creator, non-participant authenticated user from updating the game', async () => {
      const otherCtx = testEnv.authenticatedContext(OTHER_UID);
      const gameRef = doc(otherCtx.firestore(), 'games', GAME_ID);
      await assertFails(
        updateDoc(gameRef, {
          name: 'Hack Game Name',
        })
      );
    });

    it('ALLOWS the creator to update the game', async () => {
      const creatorCtx = testEnv.authenticatedContext(CREATOR_UID);
      const gameRef = doc(creatorCtx.firestore(), 'games', GAME_ID);
      await assertSucceeds(
        updateDoc(gameRef, {
          name: 'Creator Updated Game Name',
          status: 'started',
          course: {},
          players: [],
          participant_ids: [CREATOR_UID, PARTICIPANT_UID],
        })
      );
    });

    it('ALLOWS a participant to update the game', async () => {
      const participantCtx = testEnv.authenticatedContext(PARTICIPANT_UID);
      const gameRef = doc(participantCtx.firestore(), 'games', GAME_ID);
      await assertSucceeds(
        updateDoc(gameRef, {
          name: 'Participant Updated Game Name',
          status: 'started',
          course: {},
          players: [],
          participant_ids: [CREATOR_UID, PARTICIPANT_UID],
        })
      );
    });

    it('DENIES unauthenticated user from deleting a game', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const gameRef = doc(unauthedCtx.firestore(), 'games', GAME_ID);
      await assertFails(deleteDoc(gameRef));
    });

    it('DENIES a participant from deleting a game', async () => {
      const participantCtx = testEnv.authenticatedContext(PARTICIPANT_UID);
      const gameRef = doc(participantCtx.firestore(), 'games', GAME_ID);
      await assertFails(deleteDoc(gameRef));
    });

    it('ALLOWS the creator to delete the game', async () => {
      const creatorCtx = testEnv.authenticatedContext(CREATOR_UID);
      const gameRef = doc(creatorCtx.firestore(), 'games', GAME_ID);
      await assertSucceeds(deleteDoc(gameRef));
    });
  });

  // -------------------------------------------------------------------------
  // players collection — Verified Claim & Mutation Restrictions
  // -------------------------------------------------------------------------

  describe('players collection — claim and mutation restrictions', () => {
    const CLAIMED_PLAYER_ID = 'claimed-player';
    const OWNER_UID = 'uid-owner';
    const OTHER_UID = 'uid-other';
    const OWNER_EMAIL = 'owner@example.com';

    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'players', CLAIMED_PLAYER_ID), {
          ...validPlayer(CLAIMED_PLAYER_ID),
          normalized_email: OWNER_EMAIL,
          claimed_by_uid: OWNER_UID,
        });
      });
    });

    it('DENIES another authenticated user from claiming an already claimed player', async () => {
      const otherCtx = testEnv.authenticatedContext(OTHER_UID, {
        email: OWNER_EMAIL,
        email_verified: true,
      });
      const playerRef = doc(otherCtx.firestore(), 'players', CLAIMED_PLAYER_ID);
      await assertFails(
        updateDoc(playerRef, {
          claimed_by_uid: OTHER_UID,
        })
      );
    });

    it('DENIES another authenticated user from mutating profile fields of a claimed player', async () => {
      const otherCtx = testEnv.authenticatedContext(OTHER_UID);
      const playerRef = doc(otherCtx.firestore(), 'players', CLAIMED_PLAYER_ID);
      await assertFails(
        updateDoc(playerRef, {
          nickname: 'Stolen Nickname',
        })
      );
    });

    it('ALLOWS the owner of a claimed player to mutate their own profile fields', async () => {
      const ownerCtx = testEnv.authenticatedContext(OWNER_UID);
      const playerRef = doc(ownerCtx.firestore(), 'players', CLAIMED_PLAYER_ID);
      await assertSucceeds(
        updateDoc(playerRef, {
          id: CLAIMED_PLAYER_ID,
          player_name: 'Test Player',
          nickname: 'Owner New Nickname',
          total_score: 0,
        })
      );
    });
  });

  // -------------------------------------------------------------------------
  // players & player_contacts collections — Contact Visibility / PII Restrictions
  // -------------------------------------------------------------------------

  describe('Contact Visibility / PII Restrictions', () => {
    const PII_PLAYER_ID = 'pii-player';
    const PUBLIC_PLAYER_ID = 'public-player';
    const ALICE_UID = 'uid-alice';

    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        const db = ctx.firestore();
        // Player with PII
        await setDoc(doc(db, 'players', PII_PLAYER_ID), {
          ...validPlayer(PII_PLAYER_ID),
          normalized_email: 'alice@example.com',
          normalized_phone_number: '+1234567890',
        });
        // Player without PII (nickname only / guest)
        await setDoc(doc(db, 'players', PUBLIC_PLAYER_ID), {
          ...validPlayer(PUBLIC_PLAYER_ID),
        });
        // Contact reservations
        await setDoc(doc(db, 'player_contacts', 'email_alice@example.com'), {
          player_id: PII_PLAYER_ID,
          created_by_uid: ALICE_UID,
          kind: 'email',
          normalized_value: 'alice@example.com',
        });
      });
    });

    it('DENIES unauthenticated user from reading a player document with PII', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playerRef = doc(unauthedCtx.firestore(), 'players', PII_PLAYER_ID);
      await assertFails(getDoc(playerRef));
    });

    it('ALLOWS unauthenticated user to read a player document without PII', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const playerRef = doc(unauthedCtx.firestore(), 'players', PUBLIC_PLAYER_ID);
      await assertSucceeds(getDoc(playerRef));
    });

    it('ALLOWS authenticated user to read a player document with PII', async () => {
      const authedCtx = testEnv.authenticatedContext(ALICE_UID);
      const playerRef = doc(authedCtx.firestore(), 'players', PII_PLAYER_ID);
      await assertSucceeds(getDoc(playerRef));
    });

    it('DENIES unauthenticated user from reading a contact reservation', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const contactRef = doc(unauthedCtx.firestore(), 'player_contacts', 'email_alice@example.com');
      await assertFails(getDoc(contactRef));
    });

    it('ALLOWS authenticated user to get a specific contact reservation', async () => {
      const authedCtx = testEnv.authenticatedContext(ALICE_UID);
      const contactRef = doc(authedCtx.firestore(), 'player_contacts', 'email_alice@example.com');
      await assertSucceeds(getDoc(contactRef));
    });

    it('DENIES authenticated user from listing all contact reservations (prevents email harvesting)', async () => {
      const authedCtx = testEnv.authenticatedContext(ALICE_UID);
      const contactsRef = collection(authedCtx.firestore(), 'player_contacts');
      await assertFails(getDocs(contactsRef));
    });
  });

  // -------------------------------------------------------------------------
  // friends collection — Friend-Edge Mutation Rules
  // -------------------------------------------------------------------------

  describe('friends collection — mutation rules', () => {
    const ALICE_UID = 'uid-alice';
    const BOB_UID = 'uid-bob';
    const CHARLIE_UID = 'uid-charlie';

    it('DENIES unauthenticated user from creating a friend edge', async () => {
      const unauthedCtx = testEnv.unauthenticatedContext();
      const friendRef = doc(unauthedCtx.firestore(), 'friends', `${ALICE_UID}_${BOB_UID}`);
      await assertFails(
        setDoc(friendRef, {
          player_id: ALICE_UID,
          friend_id: BOB_UID,
        })
      );
    });

    it('DENIES a user from creating a friend edge between two other users (not owner)', async () => {
      const charlieCtx = testEnv.authenticatedContext(CHARLIE_UID);
      const friendRef = doc(charlieCtx.firestore(), 'friends', `${ALICE_UID}_${BOB_UID}`);
      await assertFails(
        setDoc(friendRef, {
          player_id: ALICE_UID,
          friend_id: BOB_UID,
        })
      );
    });

    it('ALLOWS a user to create a friend edge where they are the player_id (owner)', async () => {
      const aliceCtx = testEnv.authenticatedContext(ALICE_UID);
      const friendRef = doc(aliceCtx.firestore(), 'friends', `${ALICE_UID}_${BOB_UID}`);
      await assertSucceeds(
        setDoc(friendRef, {
          player_id: ALICE_UID,
          friend_id: BOB_UID,
        })
      );
    });

    it('ALLOWS a user to create a friend edge where they are the friend_id', async () => {
      const bobCtx = testEnv.authenticatedContext(BOB_UID);
      const friendRef = doc(bobCtx.firestore(), 'friends', `${ALICE_UID}_${BOB_UID}`);
      await assertSucceeds(
        setDoc(friendRef, {
          player_id: ALICE_UID,
          friend_id: BOB_UID,
        })
      );
    });
  });

  // -------------------------------------------------------------------------
  // courses collection — security rules tests
  // -------------------------------------------------------------------------

  describe('courses collection', () => {
    const COURSE_ID = 'test-course-1';

    /** Minimal valid course document that satisfies firestore.rules rules. */
    function validCourse() {
      return {
        name: 'Sunset Mini Golf',
        number_of_holes: 18,
        par_strokes: {
          '1': 3,
          '2': 2,
          '3': 4,
        },
      };
    }

    beforeEach(async () => {
      // Seed a course document via admin context
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await setDoc(doc(ctx.firestore(), 'courses', COURSE_ID), validCourse());
      });
    });

    describe('reads', () => {
      it('allows an UNAUTHENTICATED user to read a course document (allow read: if true)', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', COURSE_ID);
        await assertSucceeds(getDoc(courseRef));
      });

      it('allows an AUTHENTICATED user to read a course document', async () => {
        const authedCtx = testEnv.authenticatedContext('uid-alice');
        const courseRef = doc(authedCtx.firestore(), 'courses', COURSE_ID);
        await assertSucceeds(getDoc(courseRef));
      });

      it('allows an UNAUTHENTICATED user to list the courses collection', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const coursesRef = collection(unauthedCtx.firestore(), 'courses');
        await assertSucceeds(getDocs(coursesRef));
      });
    });

    describe('creates', () => {
      it('allows any guest user to create a course with a valid schema', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertSucceeds(setDoc(courseRef, validCourse()));
      });

      it('DENIES creation if name is missing', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        const { name, ...invalidPayload } = validCourse();
        await assertFails(setDoc(courseRef, invalidPayload));
      });

      it('DENIES creation if name is not a string', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertFails(setDoc(courseRef, { ...validCourse(), name: 123 }));
      });

      it('DENIES creation if name is empty', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertFails(setDoc(courseRef, { ...validCourse(), name: '' }));
      });

      it('DENIES creation if name exceeds 100 characters', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertFails(setDoc(courseRef, { ...validCourse(), name: 'a'.repeat(101) }));
      });

      it('DENIES creation if number_of_holes is missing', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        const { number_of_holes, ...invalidPayload } = validCourse();
        await assertFails(setDoc(courseRef, invalidPayload));
      });

      it('DENIES creation if number_of_holes is not an integer', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertFails(setDoc(courseRef, { ...validCourse(), number_of_holes: 18.5 }));
        await assertFails(setDoc(courseRef, { ...validCourse(), number_of_holes: '18' }));
      });

      it('DENIES creation if number_of_holes is less than 1', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertFails(setDoc(courseRef, { ...validCourse(), number_of_holes: 0 }));
      });

      it('DENIES creation if number_of_holes is greater than 36', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertFails(setDoc(courseRef, { ...validCourse(), number_of_holes: 37 }));
      });

      it('DENIES creation if par_strokes is missing', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        const { par_strokes, ...invalidPayload } = validCourse();
        await assertFails(setDoc(courseRef, invalidPayload));
      });

      it('DENIES creation if par_strokes is not a map', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', 'new-course');
        await assertFails(setDoc(courseRef, { ...validCourse(), par_strokes: [3, 4, 2] }));
      });
    });

    describe('updates', () => {
      it('allows any guest user to update a course with a valid schema', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', COURSE_ID);
        await assertSucceeds(
          updateDoc(courseRef, {
            name: 'Updated Sunset Mini Golf',
            number_of_holes: 9,
            par_strokes: { '1': 3 },
          })
        );
      });

      it('DENIES update if schema rules are violated', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', COURSE_ID);
        await assertFails(
          updateDoc(courseRef, {
            number_of_holes: 0,
          })
        );
      });
    });

    describe('deletes', () => {
      it('DENIES deleting a course for any user (allow delete: if false)', async () => {
        const unauthedCtx = testEnv.unauthenticatedContext();
        const courseRef = doc(unauthedCtx.firestore(), 'courses', COURSE_ID);
        await assertFails(deleteDoc(courseRef));

        const authedCtx = testEnv.authenticatedContext('uid-alice');
        const courseRefAuthed = doc(authedCtx.firestore(), 'courses', COURSE_ID);
        await assertFails(deleteDoc(courseRefAuthed));
      });
    });
  });
});
