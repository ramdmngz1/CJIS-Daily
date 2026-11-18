# CJIS Daily — App Store release prep (build 2)

Status: DRAFT. Nothing here has been submitted or published.

## Confirm before submitting
- The Xcode project says `MARKETING_VERSION = 1.1`, build `2` (was build 1).
  If version 1.1 is ALREADY live or in review on the App Store, bump the
  marketing version (for example 1.1.1) in Xcode before archiving. App Store
  Connect will reject a build for a version that is already released.
- Contact email: the live privacy page hides it behind an email-protection
  script. Confirm the same address is used in the privacy policy, the Support URL
  page, and App Store Connect.

## What's New (draft, only things in this build)
Easier to read, and better on iPad.

- Text now follows your device's text-size setting, including larger accessibility sizes.
- On iPad, the header and navigation buttons now line up with your tip card.
- Cleaner screen edges behind the status bar and home indicator.

## Review notes (draft)
CJIS Daily needs no login, account, server or special setup.
To test: open the app, allow or deny the notification prompt, tap Next through
the five daily tips, tap "Start Daily Check", and answer the five questions.
A results screen follows. Settings (gear icon, top right) has the daily
reminder time, the Light/Dark theme and a link to the privacy policy.
The app stores progress only on the device. It has no ads, analytics, tracking
or user-generated content. It is an independent training aid and is not
affiliated with the FBI or DOJ.

## Answers to expect in App Store Connect
- App Privacy: Data Not Collected. This matches `PrivacyInfo.xcprivacy`
  (no collected data types, no tracking, UserDefaults reason CA92.1) and the
  live privacy policy. Confirm against the Xcode privacy report after archiving.
- Tracking / IDFA / ATT: No. There is no ad SDK.
- Export compliance: the app uses no encryption of its own, so answer "No"
  to non-exempt encryption. Consider adding `ITSAppUsesNonExemptEncryption = NO`
  (INFOPLIST_KEY) so the question is not asked on every upload. That is a
  project change I have NOT made.
- Age rating: no user-generated content, no web browsing inside the app, no
  gambling. Expect a low rating. The privacy link opens in Safari.

## Screenshots (in ./../Screenshots)
- iPhone-6.9/: 6 images at 1320x2868 (tip, tip detail, daily check, answer reveal, results, settings)
- iPad-13/: 6 images at 2064x2752 (same screens)
- Known caveats: on iPad the content sits in the top third of a large canvas,
  and the Settings sheet is clipped (the About card scrolls off the bottom).
  Answer rows show a faint square fill behind their rounded corners.
  Dark mode and the launch image were not captured.

## Submission checklist (you do the clicking)
1. Review and commit (or discard) the uncommitted changes in git.
2. If 1.1 is already released, bump MARKETING_VERSION first.
3. Xcode: select "Any iOS Device", Product > Archive.
4. Organizer: right-click the archive > Generate Privacy Report. Compare it to
   `PrivacyInfo.xcprivacy`, the privacy policy page and your App Privacy answers.
5. Distribute App > App Store Connect > Upload.
6. Wait for processing, then attach build 2 to the version.
7. Upload the iPhone 6.9" and iPad 13" screenshots.
8. Paste What's New and the review notes. Check subtitle, keywords and description
   still match the app. Confirm the Privacy Policy URL and Support URL load.
9. Answer App Privacy, export compliance and age rating as above.
10. Submit for Review.
