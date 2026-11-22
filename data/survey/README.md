# Household survey data

Structured questionnaire survey of 150 adult small-scale fishers on Hatiya Island, Noakhali,
Bangladesh, conducted face to face in Bengali between August and November 2025.

| File | Description |
|---|---|
| `hatiya_fishers_survey_2025.sav` | Original SPSS file with variable and value labels |
| `hatiya_fishers_survey_2025.csv` | Same data as plain CSV (numeric codes) |
| `codebook.csv` | Variable names, questionnaire wording and value codes (UTF-8 with BOM, so it opens correctly in Excel) |

The questionnaire is in `docs/questionnaire_english.pdf`. Interviews were conducted in Bengali
using a translation of this English version.

The study protocol was reviewed and approved by the Noakhali Science and Technology University Ethical Committee (NSTUEC; Ref. NSTU/SCI/EC/2025/478(A), 23 November 2025). Because the survey was conducted before approval was granted, the approval was retrospective.

## Anonymization

No names, phone numbers, addresses, GPS positions or photographs were recorded. The paper
forms also carry the village or landing site (ghat), the interview date and the interviewer's
name; none of these is included in this dataset. `questionnaire_id` is a serial number only,
and all socio-demographic variables are coarse categories (for example, age in 10-year bands).

## Structure

- 150 rows (one per respondent), 48 columns, no missing values
- Section A (A2–A9): socio-demographic profile
- Section B (B1–B10): local ecological knowledge, 1 = strongly disagree … 5 = strongly agree
- Section C (C1–C10): perceived change over the last 20–30 years, 1 = strongly disagree … 5 = strongly agree
- Section D (D1–D10): adaptation practices, 1 = never … 5 = always
- Section E (E1–E9): barriers to adaptation, 0 = not selected, 1 = selected
