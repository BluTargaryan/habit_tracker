# Play Console Data Safety & Content Rating — Answer Mapping

Reference notes for filling out Play Console's Data Safety and Content Rating questionnaires. These aren't submitted as-is — they're what to click/type into Play Console's own forms.

## ⚠️ Open item before submitting

Play Console's Data Safety form asks whether your app lets users **request account deletion**. Habit Tracker currently has no in-app "delete my account" action — a user's account row simply sits in the local SQLite database until the app is uninstalled. For a purely local-only account (no server), "uninstalling the app deletes everything" is a defensible answer, but Play's reviewers increasingly expect an in-app deletion path even for local accounts. **Decide before submitting**: either (a) declare deletion happens via app uninstall (simplest, likely fine given there's no server), or (b) ask me to add an in-app "Delete Account" action to the Profile screen first. Not resolved automatically — this is a product decision.

## Data Safety form

### Does your app collect or share any required user data types?
**Yes.**

### Data types to declare

| Data type | Collected? | Shared with third parties? | Processed ephemerally? | Purpose |
|---|---|---|---|---|
| Location (approximate/precise) | Yes | No | Yes — sent to Open-Meteo per-request to fetch a forecast, never stored server-side by us | App functionality |
| Personal info — Name | Yes (on-device only) | No | No — persists locally until edited/deleted or the app is uninstalled | App functionality (account) |
| Personal info — User IDs (username) | Yes (on-device only) | No | No | App functionality (account) |

Notes for the form:
- Answer **"Data is encrypted in transit"** = Yes for the location request (Open-Meteo and ZenQuotes are both accessed over HTTPS).
- Age, country, and password are also entered by the user but stored **only on-device** and never transmitted anywhere — Play's own guidance is that data which never leaves the device generally doesn't require declaration, but if you'd rather over-disclose for safety, list them under "Personal info" the same way as Name/Username above.
- Answer **"No"** to data being used for advertising or sold to third parties — none of that happens in this app.

## Content Rating Questionnaire (IARC)

| Question | Answer |
|---|---|
| Violence | None |
| Sexual content / nudity | None |
| Profanity / crude humor | None |
| Controlled substances (alcohol/drugs/tobacco references) | None |
| Gambling (real or simulated) | None |
| User-generated content shared with/visible to other users | No — habits and data are private to each account, no social features |
| Does the app share the user's location with other users | No |
| Does the app allow users to interact/communicate with each other | No |
| Does the app collect personal information (name, age, etc.) | Yes |
| Target age group | Not designed for children — registration requires a minimum age of 16 |

Expected outcome: rating should land at the lowest tier (e.g. "Everyone" / "3+" on IARC's actual scale), since there's no objectionable content — the age-16 registration gate is a product rule, not a content-rating restriction, so don't select a "designed for children" or teen-only content flag.

## Target Audience section

- Select an age range that reflects actual users (registration enforces 16+, so do **not** mark this app as directed at or appealing to children — this also exempts it from Play Families policies).
