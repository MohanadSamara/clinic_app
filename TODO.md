# TODO: Fix DropdownButton Assertion Error in Document Upload Screen

## Issue
- Assertion failed in DropdownButton: "There should be exactly one item with [DropdownButton]'s value: Instance of 'MedicalRecord'. Either zero or 2 or more [DropdownMenuItem]s were detected with the same value"

## Root Cause
- MedicalRecord equality based on id, but hashCode could fail if id is null.
- Selected medical record might not be in the available records list after pet change.

## Changes Made
- [x] Fixed hashCode in MedicalRecord model to handle null id: `id?.hashCode ?? 0`
- [x] Added logic to reset _selectedMedicalRecord to null if it's not in availableRecords list.

## Testing
- [ ] Run the app and navigate to document upload screen.
- [ ] Select a pet and verify medical records dropdown works without error.
- [ ] Change pet selection and ensure dropdown resets properly.
- [ ] Upload a document with and without selecting a medical record.
