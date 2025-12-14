# QA Checklist for PDF Converter App

Use this checklist to verify the stability and functionality of the application before release.

## 1. Onboarding & First Launch
- [ ] **Fresh Install**: Install the app on a fresh device/simulator. Verify Onboarding screens appear.
- [ ] **Onboarding Completion**: Complete the onboarding flow. Verify user lands on the Dashboard.
- [ ] **Persistence**: Kill and relaunch the app. Verify Onboarding does NOT appear again.
- [ ] **Reset Onboarding**: In Settings, tapping "Reset Onboarding" and relaunching should show Onboarding again.

## 2. Dashboard & Navigation
- [ ] **UI Elements**: Verify "My Scans" title, Settings gear icon, and Quick Actions are visible.
- [ ] **Empty State**: On a fresh install, verify "No Scans Yet" empty state is shown.
- [ ] **Settings Navigation**: Tap the gear icon. Verify Settings screen opens.
- [ ] **Quick Actions**: Verify buttons for "Scan", "Photos", and "Files" are responsive.

## 3. Scanning & Importing
- [ ] **Camera Scan**:
  - [ ] Tap "Scan". Verify Camera opens.
  - [ ] Scan a document.
  - [ ] Verify automatic edge detection (if applicable) or manual capture.
  - [ ] Save the scan. Verify it appears in "Recent" list.
- [ ] **Photo Import**:
  - [ ] Tap "Photos". Allow permission.
  - [ ] Select an image.
  - [ ] Verify functionality triggers document creation.
- [ ] **File Import**:
  - [ ] Tap "Files". Select a PDF or Image.
  - [ ] Verify it imports correctly.

## 4. Document Management
- [ ] **List View**: Verify all created documents appear in the list with correct Title, Page Count, and Date.
- [ ] **Renaming**:
  - [ ] Tap 3-dot menu -> "Rename".
  - [ ] Change title and Save.
  - [ ] Verify title updates in the list immediately.
- [ ] **Deleting**:
  - [ ] Tap 3-dot menu -> "Delete".
  - [ ] Confirm deletion in the alert.
  - [ ] Verify document is removed from the list.
- [ ] **Persistence**: Close app and relaunch. Verify documents and changes remain.

## 5. Document Detail & Actions
- [ ] **Open Document**: Tap a document row. Verify Detail view opens.
- [ ] **Review Pages**: Swipe through pages (if multi-page).
- [ ] **Print**:
  - [ ] Tap 3-dot menu -> "Print".
  - [ ] Verify native Printer Options appear.
- [ ] **Export/Share**:
  - [ ] Tap 3-dot menu -> "Export PDF" or Share button.
  - [ ] Verify Share Sheet appears.
  - [ ] Test saving to Files or sending via Message/Mail.
  - [ ] Verify the exported file is a valid PDF.

## 6. Settings & Rating Logic
- [ ] **Support Links**:
  - [ ] "Contact Us": Verify Mail composer opens with correct email.
  - [ ] "Share App": Verify Share Sheet opens with App Store link.
- [ ] **Legal**:
  - [ ] "Terms of Service": Verify Safari View opens correct URL.
  - [ ] "Privacy Policy": Verify Safari View opens correct URL.
- [ ] **Rate Us (Manual)**: Tap "Rate Us". Verify review prompt or App Store page opens.
- [ ] **Automatic Rating Prompt (New Feature)**:
  - [ ] **Pre-requisite**: App installed > 3 days ago & Not yet rated.
  - [ ] *Test Method*: Change device date forward by 4 days OR temporarily modify code `firstLaunchDate` logic for testing.
  - [ ] Verify native Rating Modal appears on Dashboard launch.
  - [ ] Verify it does NOT appear again immediately after being shown/dismissed (handled by OS/flag).

## 7. Permissions & Edge Cases
- [ ] **Permission Denied**:
  - [ ] Deny Camera access. Verify app handles it gracefully (e.g., alert or placeholder).
  - [ ] Deny Photo Library access. Verify graceful handling.
- [ ] **Large Files**: Import a large PDF or many images. Verify app does not crash/UI remains responsive.
- [ ] **Dark Mode**: Toggle system Dark Mode. Verify UI colors/text remain readable (App seems forced to `.light` scheme in `pdfconverterApp.swift`, verify this behavior is consistent).
