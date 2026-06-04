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
});
