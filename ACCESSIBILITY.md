# Accessibility statement — NHS Waitlist Validation (DRAFT)

> **DRAFT — built to align with WCAG 2.2 AA, pending a formal independent audit and
> Trust sign-off.** This statement follows the GOV.UK / Public Sector Bodies
> (Websites and Mobile Applications) Accessibility Regulations 2018 model. It must
> NOT be published as final until an external WCAG 2.2 AA audit and screen-reader
> testing are complete. Do not describe the service as "fully compliant" before then.

## Scope
This statement covers the patient-facing waitlist validation page (`frontend/`):
the single-question response screen, the confirmation step, and the outcome message.

## How accessible this service is
We have designed and built this service to aim for **WCAG 2.2 level AA**. The following
are **in place and self-tested** (developer testing, not yet an independent audit):

- **Keyboard operable** — all controls are reachable and operable by keyboard;
  visible focus indicators via `:focus-visible`.
- **Skip link** to the main question (WCAG 2.4.1).
- **Status messaging** — outcomes use `role="status"` / `aria-live`; errors use
  `role="alert"`; focus moves to the outcome after submission.
- **Confirmation step** for the irreversible "no longer need it" choice, with the
  safe option presented first and focused (also a clinical-safety mitigation).
- **Reduced motion** honoured via `prefers-reduced-motion`.
- **Colour contrast (developer-measured against AA 4.5:1 normal text):**
  - Light theme — secondary text `#5a6473` on white ≈ **6.0:1**; green accent
    `#006a4e` ≈ **6.6:1**; alert text `#b8421f` ≈ **5.5:1**.
  - Dark theme — secondary text `#9aa4b2` on `#12161e` ≈ **7.2:1**.
  - *These are computed values and must be confirmed by the formal audit, including
    non-text/UI-component contrast (3:1) and focus-indicator contrast.*
- **Resize / reflow** — layout is fluid to 320 px with no horizontal scrolling and
  supports 200% zoom (viewport allows user scaling).
- **Language** of the page is set (`lang="en-GB"`).

## Known gaps / not yet done (before this statement can be finalised)
- ❌ **Formal independent WCAG 2.2 AA audit** and remediation.
- ❌ **Assistive-technology testing** with NVDA, JAWS and VoiceOver, plus mobile
  screen readers (TalkBack / VoiceOver iOS).
- ❌ **Accessible Information Standard (DCB1605)** — how communication-needs flags
  (easy-read, large-print, BSL, alternative formats) are honoured for the SMS link
  and this page. Owned with the Trust's communications team.
- ❌ **NHS.UK design system alignment** review — current UI is bespoke; reconcile
  against NHS.UK frontend patterns / service manual.
- ⚠️ Reading order, headings and labels to be verified with AT (h1 present in the
  question state; outcome state uses h2).

## Feedback and contact
*(To be completed by the Trust before publication.)* Provide an email/phone for
reporting accessibility problems and requesting information in an alternative format,
and the expected response time.

## Enforcement procedure
If you contact us with a complaint and are not happy with our response, contact the
Equality Advisory and Support Service (EASS). *(Confirm wording at publication.)*

## Preparation of this statement
- Statement drafted: 2026-05-29 (DRAFT — engineering self-assessment).
- Last self-tested: 2026-05-29.
- Formal audit date: **not yet scheduled.**
