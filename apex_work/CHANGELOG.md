# National Ambulance Management System APEX Export Changelog

Updated export: `apex_work/f140128.sql`

## Landing Page

- Updated application Home URL to use Page 15 with `&APP_SESSION.`.
- Updated the navigation Home item to open Page 15.
- Added a Page 1 before-header redirect branch to Page 15 so Page 1 no longer renders as the post-login landing page.

## Authorization Reset

- Removed the application-level authorization scheme reference to `Reader Rights`.
- Removed all custom authorization scheme definitions:
  - Reader Rights
  - Administration Rights
  - Contribution Rights
- Removed page-level `p_required_role` references.
- Removed navigation/report-detail authorization references.
- Left authentication as Oracle APEX Accounts.
- Result: pages use default authenticated-user access instead of custom authorization checks.

## Dashboard Rendering Fix

- Corrected the Page 15 Ambulance Status pie chart series metadata for APEX 26.1.
- Removed the duplicate series-name mapping that could raise `ORA-01403` in the JET chart renderer.
- Added data-existence conditions to all Dashboard charts so empty tables do not cause page rendering failures.
- Added the required series type and X/Y axis metadata to both Page 15 bar charts.
- Added `f140128_stable_no_jet.sql` as a recovery export; its Page 15 chart regions are unconditionally excluded from rendering to avoid APEX 26.1 JET renderer failures while retaining the rest of the dashboard.
- Added Page 15 scoped visual styling based on the supplied dashboard reference: navy navigation, light workspace, eight distinct KPI accents, stronger KPI typography, colored quick actions, and styled report/alert regions.
- Embedded the supplied Ghana National Ambulance Service logo as the application static file `AmbulanceLogo.png` and displayed it in the Page 15 navigation header.
- Added Ghana red, gold, and green header accents alongside the emergency-blue dashboard palette.

## Page 15 - Dashboard

- Reworked the existing KPI Cards region to query base tables directly instead of missing `nambs_dashboard_cards`.
- Added KPI cards for:
  - Total Emergency Calls
  - Total Ambulances
  - Available Ambulances
  - Total Staff
  - Total Patients
  - Total Dispatches
  - Dispatches In Progress
  - Completed Dispatches
- Reworked the Ambulance Status chart to query `AMBULANCE` directly instead of missing `nambs_ambulance_status_overview`.
- Added native JET bar chart for Dispatch Status Overview.
- Added native JET bar chart for Calls by Region, derived from `EMERGENCY_CALL.CALLER_LOCATION`.
- Added Recent Dispatches native Interactive Report with Dispatch ID, Call ID, Ambulance, Status, and Time.
- Added Quick Actions region with native buttons:
  - New Emergency Call
  - New Dispatch
  - Add Patient
  - Add Staff
- Added System Alerts and Notifications native SQL report.

## Page 9 - Emergency Calls

- Added native KPI Cards for Today's Calls, Pending Calls, Dispatched, and Cancelled.
- Renamed the main report region to Recent Emergency Calls.
- Made Call ID visible in the Emergency Calls Interactive Report.
- Sorted Emergency Calls by Call Time descending.
- Added a native Call Location placeholder report showing the latest recorded location with latitude/longitude placeholders.
- Normalized Emergency Call page button links to `&APP_SESSION.`.

## Page 10 - Emergency Call Form

- Added native non-DML page items for the required demo fields that are not present as columns in the exported schema:
  - Phone Number
  - Alternative Number
  - Emergency Type
  - Region
  - Landmark / Nearby Place
  - Description / Remarks
  - Priority
  - Call Source
- Preserved existing table-backed DML for Caller Name, Caller Location, and Call Time.

## Remaining Tasks

- The export does not include supporting-object DDL for adding missing `EMERGENCY_CALL` columns such as phone number, emergency type, priority, source, latitude, and longitude. Those new Page 10 fields are UI/session-only until matching table columns are added.
- A real map integration still needs latitude/longitude columns or geocoding support. The current export includes a safe native placeholder.
- Cancelled call counts are shown as `0` because the exported `EMERGENCY_CALL` structure has no status/cancelled column.
- For a complete production build, add schema migrations/supporting objects for the extra Emergency Call fields, then bind the new form items to real columns.
