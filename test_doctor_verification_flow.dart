import 'package:flutter_test/flutter_test.dart';
import 'package:clinic_app/models/doctor.dart';
import 'package:clinic_app/models/document.dart';
import 'package:clinic_app/providers/document_provider.dart';
import 'package:clinic_app/services/document_service.dart';

void main() {
  group('Doctor Verification Flow', () {
    late DocumentProvider documentProvider;
    late DocumentService documentService;

    setUp(() {
      documentProvider = DocumentProvider();
      documentService = DocumentService();
    });

    test('Doctor document upload and verification', () async {
      // Create a mock doctor
      final doctor = Doctor(
        id: 'test_doctor_id',
        name: 'Dr. Test Vet',
        email: 'test@vet.com',
        phone: '+1234567890',
        specialization: 'Veterinary Medicine',
        licenseNumber: 'VET123456',
        isVerified: false,
      );

      // Create a mock document
      final document = Document(
        id: 'test_doc_id',
        doctorId: doctor.id,
        type: DocumentType.license,
        fileName: 'vet_license.pdf',
        fileUrl: 'https://example.com/vet_license.pdf',
        uploadDate: DateTime.now(),
        status: DocumentStatus.pending,
      );

      // Test document upload
      await documentProvider.uploadDocument(document);

      // Verify document is uploaded
      expect(documentProvider.documents.contains(document), true);

      // Test document verification
      await documentService.verifyDocument(document.id);

      // Verify document status is updated
      final updatedDocument = documentProvider.documents.firstWhere(
        (doc) => doc.id == document.id,
      );
      expect(updatedDocument.status, DocumentStatus.verified);

      // Verify doctor is marked as verified
      expect(doctor.isVerified, true);
    });

    test('Document rejection flow', () async {
      // Create a mock document
      final document = Document(
        id: 'test_doc_id_2',
        doctorId: 'test_doctor_id',
        type: DocumentType.license,
        fileName: 'invalid_license.pdf',
        fileUrl: 'https://example.com/invalid_license.pdf',
        uploadDate: DateTime.now(),
        status: DocumentStatus.pending,
      );

      // Test document upload
      await documentProvider.uploadDocument(document);

      // Test document rejection
      await documentService.rejectDocument(document.id, 'Invalid document');

      // Verify document status is updated
      final updatedDocument = documentProvider.documents.firstWhere(
        (doc) => doc.id == document.id,
      );
      expect(updatedDocument.status, DocumentStatus.rejected);
      expect(updatedDocument.rejectionReason, 'Invalid document');
    });
  });
}
