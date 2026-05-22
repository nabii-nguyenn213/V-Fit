const databaseName = process.env.MONGO_INITDB_DATABASE || "vfit";
const appUsername = process.env.MONGO_APP_USERNAME || "vfit_app";
const appPassword = process.env.MONGO_APP_PASSWORD || "vfit_app_password_change_me";

db = db.getSiblingDB(databaseName);

db.createUser({
  user: appUsername,
  pwd: appPassword,
  roles: [
    {
      role: "readWrite",
      db: databaseName
    }
  ]
});

const collections = [
  "users",
  "refresh_tokens",
  "password_reset_tokens",
  "workout_programs",
  "workout_histories",
  "exercises",
  "form_check_results",
  "body_analysis_results",
  "badges",
  "challenges",
  "subscriptions",
  "payment_transactions",
  "posts",
  "comments",
  "reports",
  "notifications",
  "app_configs"
];

collections.forEach((collectionName) => {
  if (!db.getCollectionNames().includes(collectionName)) {
    db.createCollection(collectionName);
  }
});

db.users.createIndex({ email: 1 }, { unique: true, name: "email" });
db.refresh_tokens.createIndex({ token: 1 }, { unique: true, name: "token" });
db.refresh_tokens.createIndex({ userId: 1 }, { name: "userId" });
db.password_reset_tokens.createIndex({ token: 1 }, { unique: true, name: "token" });
db.password_reset_tokens.createIndex({ userId: 1 }, { name: "userId" });
db.app_configs.createIndex({ configKey: 1 }, { unique: true, name: "configKey" });
