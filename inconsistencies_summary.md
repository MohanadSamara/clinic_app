# Database Alignment Audit - Inconsistencies Found

## Overview
The application is migrating from legacy systems (Local DB/Firestore) to Supabase. Supabase uses **UUID-based Strings** for IDs and **snake_case** for database keys. Many models still use `int` for IDs or mixed casing.

## Models to Fix

| Model | Field(s) to Change | Current Type | Target Type |
|-------|--------------------|--------------|-------------|
| **Appointment** | `id`, `serviceRequestId` | `int?` | `String?` |
| **Service** | `id` | `int?` | `String?` |
| **InventoryItem** | `id` | `int?` | `String?` |
| **Notification** | `id`, `userId` | `int?`, `int` | `String?`, `String` |
| **DoctorVerificationDocument** | `id`, `doctorId`, `verifiedBy` | `int?`, `int`, `int?` | `String?`, `String`, `String?` |
| **AuditLog** | `id`, `documentId`, `userId` | `int?`, `int`, `int` | `String?`, `String`, `String` |
| **DriverVerificationDocument** | `id`, `driverId`, `reviewerId` | `int?`, `int`, `int?` | `String?`, `String`, `String?` |
| **DriverVerificationStatus** | `driverId` | `int` | `String` |
| **DriverVerificationAuditLog** | `id`, `documentId`, `userId` | `int?`, `int`, `int` | `String?`, `String`, `String` |

## General Issues
- Some models have `toMapForLocal()` or Firestore-specific logic that should be unified into a single `toMap()` and `fromMap()` compatible with Supabase.
- Ensure all `fromMap` factories handle nulls safely and convert dynamic types to the correct target types (especially for IDs).
- Ensure `hashCode` and `operator ==` use the new ID types.
