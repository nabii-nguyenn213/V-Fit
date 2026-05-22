// VFIT uses MongoDB, so there are no SQL foreign keys to remove.
// This migration is idempotent and safely drops all legacy meal collections.

const legacyMealCollections = [
  "meals",
  "meal_details",
  "meal_ingredients",
  "meal_plans",
  "meal_logs",
];

legacyMealCollections.forEach((name) => {
  if (db.getCollectionNames().includes(name)) {
    db.getCollection(name).drop();
    print(`Dropped ${name}`);
  } else {
    print(`Skipped ${name}: not found`);
  }
});
