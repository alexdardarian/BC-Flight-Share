import { onSchedule } from "firebase-functions/v2/scheduler";
import { beforeUserCreated } from "firebase-functions/v2/identity";
import { HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

initializeApp();

// Enforce @bc.edu at Firebase Auth creation — blocks REST API abuse too.
export const enforceBC = beforeUserCreated((event) => {
  const email = event.data.email ?? "";
  if (!email.toLowerCase().endsWith("@bc.edu")) {
    throw new HttpsError(
      "invalid-argument",
      "Only Boston College (@bc.edu) email addresses are allowed."
    );
  }
});

// Delete rides whose departure window + 2-hour buffer has passed.
export const cleanupExpiredRides = onSchedule("every 1 hours", async () => {
  const db = getFirestore();
  const now = new Date();

  // Fetch all rides whose earliest departure is already in the past.
  // We then compute the real expiry per-doc using departureWindowMinutes.
  const snapshot = await db
    .collection("rides")
    .where("earliestDepartureFromCampus", "<", Timestamp.fromDate(now))
    .get();

  const batch = db.batch();
  let count = 0;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const earliest = (data.earliestDepartureFromCampus as Timestamp).toDate();
    const windowMs = (data.departureWindowMinutes as number) * 60 * 1000;
    const expiry = new Date(earliest.getTime() + windowMs + 2 * 60 * 60 * 1000);

    if (expiry < now) {
      batch.delete(doc.ref);
      count++;
    }
  }

  if (count > 0) {
    await batch.commit();
    console.log(`Deleted ${count} expired ride(s).`);
  }
});
