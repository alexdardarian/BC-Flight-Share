---
layout: page
title: Privacy Policy — BC Flight Share
---

# Privacy Policy

**Effective Date: May 28, 2026**

BC Flight Share ("the App", "we", "us") is an independent app that helps Boston College students find ride-share partners to and from local airports. This Privacy Policy explains what information we collect, how we use it, and your choices.

---

## 1. Information We Collect

**Account information**
When you create an account, you provide your full name, a Boston College email address (@bc.edu), a password, your gender, your academic year, and your dorm or housing. Your password is managed entirely by Firebase Authentication and is never stored by us in readable form.

**Ride information**
When you post or join a ride, we store the destination, terminal, meeting location, departure window, flight time, maximum riders, and any optional notes you enter.

**Rider profile data**
Your name and gender are stored alongside ride records so that other participants in the same ride can identify you.

**Chat messages**
Messages you send in a ride's group chat are stored in Firestore and are visible to all participants of that ride.

**Block and report data**
If you block another user or report a message, a record is created that includes the relevant user IDs and any report text you submit.

**Device and usage data**
We do not use analytics SDKs. No device identifiers, crash logs, or behavioral telemetry are collected beyond what Firebase Authentication requires to operate.

---

## 2. How We Use Your Information

- To authenticate your identity and enforce the @bc.edu requirement
- To display your name and gender to other riders on rides you have joined or created
- To match you with other BC students traveling on the same day
- To enable group chat between confirmed ride participants
- To investigate reports of harmful behavior

---

## 3. Who Can See Your Information

**Other BC Flight Share users (before joining a ride)**
Users who have not joined your ride see only your first name, last initial, and the ride details you posted. Your full last name and gender are hidden until another user joins the same ride.

**Other BC Flight Share users (after joining a ride)**
Confirmed participants of a ride can see the full name and gender of every other participant, the group chat, and the Uber deep-link for the shared destination.

**Firebase / Google**
The App is built on Google Firebase (Authentication and Firestore). Your data is stored on Firebase infrastructure subject to [Google's Privacy Policy](https://policies.google.com/privacy). We use Firebase only for data storage and authentication — no Firebase Analytics or Crashlytics is installed.

**No sale of data**
We do not sell, rent, or trade your personal information to any third party.

---

## 4. Third-Party Services

**Uber**
Tapping "Open in Uber" launches the Uber app (or Uber's mobile website) pre-filled with the ride destination. At that point you are subject to [Uber's Privacy Policy](https://www.uber.com/legal/en/document/?name=privacy-notice). We do not share your personal information with Uber; the deep-link only passes the destination address.

---

## 5. Data Retention

Ride records are automatically deleted by a scheduled background process approximately two hours after the ride's departure window closes. Chat messages associated with a ride are deleted at the same time. Account data (your profile, block list, and reports you filed) is retained until you request deletion.

---

## 6. Your Rights and Choices

**Access and correction:** You can view and edit your name, gender, year, and dorm at any time from the Profile screen.

**Account deletion:** To delete your account and all associated data, email [alexdardarian@gmail.com](mailto:alexdardarian@gmail.com) with the subject line "Account Deletion Request" from your @bc.edu address. We will process the request within 30 days.

**Data export:** To request a copy of the data we hold about you, email the address above.

---

## 7. Security

- All data is transmitted over HTTPS.
- Firestore Security Rules enforce that only authenticated @bc.edu users can read or write data, and that users can only modify their own records.
- A Firebase Authentication blocking function rejects account creation for any email that does not end in @bc.edu before the account is ever created.

Despite these measures, no system is perfectly secure. Use the App's reporting feature to flag any suspicious behavior.

---

## 8. Children's Privacy

The App is not intended for anyone under 18 years of age. We do not knowingly collect information from minors. If you believe a minor has created an account, please contact us so we can remove it.

---

## 9. Changes to This Policy

We may update this Privacy Policy from time to time. When we do, we will update the Effective Date above. Continued use of the App after any change constitutes acceptance of the revised policy.

---

## 10. Contact

Questions about this Privacy Policy? Email [alexdardarian@gmail.com](mailto:alexdardarian@gmail.com).
