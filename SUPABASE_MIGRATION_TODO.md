# Supabase Migration TODO

## Phase 1: Configuration & Dependencies ✅ COMPLETED
- [x] 1. Update pubspec.yaml with Supabase dependencies
- [x] 2. Create lib/supabase_options.dart - Supabase configuration
- [ ] 3. Update lib/main.dart to initialize Supabase

## Phase 2: Supabase Service Layer ✅ COMPLETED
- [x] 4. Create lib/services/supabase_service.dart - Main Supabase client
- [x] 5. Create lib/services/supabase_complete_service.dart - Complete database service

## Phase 3: Delete Unused Files ✅ COMPLETED
- [x] 7. Delete lib/services/firestore_service.dart
- [x] 8. Delete lib/services/firestore_crud_service.dart
- [x] 9. Delete lib/services/firestore_complete_service.dart
- [x] 10. Delete lib/services/firestore_global_service.dart
- [x] 11. Delete lib/services/sync_service.dart
- [x] 12. Delete lib/db/db_helper.dart
- [x] 13. Delete lib/providers/sync_provider.dart
- [x] 14. Delete lib/models/sync_tracker.dart
- [x] 15. Delete lib/services/firestore_crud (file without .dart extension)

## Phase 4: Remaining Steps (Manual)
- [ ] 16. Configure Supabase project (see SUPABASE_SETUP_GUIDE.md)
- [ ] 17. Run SQL scripts to create database tables
- [ ] 18. Update lib/main.dart to initialize Supabase
- [ ] 19. Update providers to use SupabaseCompleteService
- [ ] 20. Update screens that use Firestore directly
- [ ] 21. Run flutter pub get
- [ ] 22. Test compilation

## Notes:
- Keep firebase_options.dart for Google Sign-In
- Keep firebase_auth for authentication
- Removed: cloud_firestore, firebase_storage, sqflite packages
- Added: supabase_flutter

## Files Created:
- lib/supabase_options.dart
- lib/services/supabase_service.dart
- lib/services/supabase_complete_service.dart
- SUPABASE_SETUP_GUIDE.md (detailed setup instructions)
- SUPABASE_MIGRATION_TODO.md (this file)

## Next Steps:
1. Open SUPABASE_SETUP_GUIDE.md
2. Create Supabase account and project
3. Run SQL scripts in Supabase dashboard
4. Update supabase_options.dart with your credentials
5. Continue with Phase 4 updates

