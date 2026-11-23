import test from 'node:test';
import assert from 'node:assert/strict';
import * as rules from '../src/domain/gameRules';

test('a correct guess wins and scores more for a faster hunt', () => {
  const level = rules.levelById(1);
  assert.ok(level);
  const fast = rules.newHunt(level, 7);
  assert.equal(rules.applyGuess(fast, 7).error, null);
  assert.equal(fast.status, 'won');
  const fastScore = rules.scoreFor(level, fast.guesses.length);

  const slow = rules.newHunt(level, 7);
  rules.applyGuess(slow, 1);
  rules.applyGuess(slow, 2);
  rules.applyGuess(slow, 3);
  rules.applyGuess(slow, 7);
  assert.ok(fastScore > rules.scoreFor(level, slow.guesses.length));
});

test('the secret stays hidden until the hunt is over', () => {
  const level = rules.levelById(2);
  assert.ok(level);
  const hunt = rules.newHunt(level, 40);
  hunt._id = 'game-1';
  rules.applyGuess(hunt, 20);
  const hidden = rules.toPublicGame(hunt);
  assert.equal(hidden.secretNumber, null);
  assert.equal(hidden.lowBound, 21);
  assert.equal(hidden.guesses[0].direction, 'tooLow');

  const lost = rules.newHunt(level, 40);
  lost._id = 'game-2';
  for (let value = 1; value <= 12; value += 1) {
    rules.applyGuess(lost, value);
  }
  assert.equal(lost.status, 'lost');
  assert.equal(rules.toPublicGame(lost).secretNumber, 40);
});

test('three misses unlock the first hint', () => {
  const level = rules.levelById(2);
  assert.ok(level);
  const hunt = rules.newHunt(level, 55);
  rules.applyGuess(hunt, 1);
  rules.applyGuess(hunt, 2);
  assert.deepEqual(rules.hintsFor(hunt), []);
  rules.applyGuess(hunt, 3);
  assert.equal(rules.hintsFor(hunt)[0], 'The number is odd.');
});

test('points unlock the next level once', () => {
  assert.deepEqual(rules.unlockedByPoints(0, 70), [2]);
  assert.deepEqual(rules.unlockedByPoints(70, 90), []);
});
