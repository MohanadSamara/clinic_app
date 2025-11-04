import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../models/pet.dart';
import '../models/medical_record.dart';
import '../models/vaccination_record.dart';

/// Service for generating PDF documents from medical records
/// Note: This is a placeholder implementation. For full PDF generation,
/// you would need to add the 'pdf' package and implement actual PDF creation.
class PdfService {
  /// Generate a PDF report of medical history for a pet
  Future<String> generateMedicalHistoryPdf({
    required Pet pet,
    required List<MedicalRecord> medicalRecords,
    required List<VaccinationRecord> vaccinationRecords,
  }) async {
    try {
      // For web, we would use a different approach
      if (kIsWeb) {
        return await _generateWebPdf(pet, medicalRecords, vaccinationRecords);
      }

      // For mobile/desktop
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'medical_history_${pet.name}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      // TODO: Implement actual PDF generation using 'pdf' package
      // For now, we'll create a text file as placeholder
      final content = _generateTextContent(
        pet,
        medicalRecords,
        vaccinationRecords,
      );

      final file = File(filePath);
      await file.writeAsString(content);

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  Future<String> _generateWebPdf(
    Pet pet,
    List<MedicalRecord> medicalRecords,
    List<VaccinationRecord> vaccinationRecords,
  ) async {
    // For web, we would generate a downloadable blob
    // This is a placeholder implementation
    final content = _generateTextContent(
      pet,
      medicalRecords,
      vaccinationRecords,
    );
    return content;
  }

  String _generateTextContent(
    Pet pet,
    List<MedicalRecord> medicalRecords,
    List<VaccinationRecord> vaccinationRecords,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('MEDICAL HISTORY REPORT');
    buffer.writeln('=' * 50);
    buffer.writeln();

    // Pet Information
    buffer.writeln('PET INFORMATION');
    buffer.writeln('-' * 50);
    buffer.writeln('Name: ${pet.name}');
    buffer.writeln('Species: ${pet.species}');
    if (pet.breed != null) buffer.writeln('Breed: ${pet.breed}');
    if (pet.dob != null) buffer.writeln('Date of Birth: ${pet.dob}');
    buffer.writeln();

    // Medical History Summary
    if (pet.medicalHistorySummary != null) {
      buffer.writeln('MEDICAL HISTORY SUMMARY');
      buffer.writeln('-' * 50);
      buffer.writeln(pet.medicalHistorySummary);
      buffer.writeln();
    }

    // Vaccination Records
    if (vaccinationRecords.isNotEmpty) {
      buffer.writeln('VACCINATION RECORDS');
      buffer.writeln('-' * 50);
      for (final record in vaccinationRecords) {
        buffer.writeln('Vaccine: ${record.vaccineName}');
        buffer.writeln(
          'Date: ${record.vaccinationDate.toString().split(' ')[0]}',
        );
        if (record.nextDueDate != null) {
          buffer.writeln(
            'Next Due: ${record.nextDueDate.toString().split(' ')[0]}',
          );
        }
        if (record.veterinarianName != null) {
          buffer.writeln('Veterinarian: ${record.veterinarianName}');
        }
        if (record.notes != null) {
          buffer.writeln('Notes: ${record.notes}');
        }
        buffer.writeln();
      }
    }

    // Medical Records
    if (medicalRecords.isNotEmpty) {
      buffer.writeln('MEDICAL RECORDS');
      buffer.writeln('-' * 50);
      for (final record in medicalRecords) {
        buffer.writeln('Date: ${record.date}');
        buffer.writeln('Diagnosis: ${record.diagnosis}');
        buffer.writeln('Treatment: ${record.treatment}');
        if (record.prescription != null) {
          buffer.writeln('Prescription: ${record.prescription}');
        }
        if (record.notes != null) {
          buffer.writeln('Notes: ${record.notes}');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('=' * 50);
    buffer.writeln('Generated on: ${DateTime.now()}');

    return buffer.toString();
  }

  /// Generate an invoice PDF for a payment
  Future<String> generateInvoicePdf({
    required String ownerName,
    required String serviceName,
    required double amount,
    required String transactionId,
    required DateTime date,
  }) async {
    try {
      if (kIsWeb) {
        return await _generateWebInvoice(
          ownerName,
          serviceName,
          amount,
          transactionId,
          date,
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'invoice_${transactionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = '${directory.path}/$fileName';

      final content = _generateInvoiceContent(
        ownerName,
        serviceName,
        amount,
        transactionId,
        date,
      );

      final file = File(filePath);
      await file.writeAsString(content);

      return filePath;
    } catch (e) {
      throw Exception('Failed to generate invoice: $e');
    }
  }

  Future<String> _generateWebInvoice(
    String ownerName,
    String serviceName,
    double amount,
    String transactionId,
    DateTime date,
  ) async {
    return _generateInvoiceContent(
      ownerName,
      serviceName,
      amount,
      transactionId,
      date,
    );
  }

  String _generateInvoiceContent(
    String ownerName,
    String serviceName,
    double amount,
    String transactionId,
    DateTime date,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('INVOICE');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Vet2U Mobile Veterinary Clinic');
    buffer.writeln();
    buffer.writeln('Date: ${date.toString().split(' ')[0]}');
    buffer.writeln('Transaction ID: $transactionId');
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln('Bill To: $ownerName');
    buffer.writeln();
    buffer.writeln('Service: $serviceName');
    buffer.writeln('Amount: \$${amount.toStringAsFixed(2)}');
    buffer.writeln();
    buffer.writeln('-' * 50);
    buffer.writeln('Total: \$${amount.toStringAsFixed(2)}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Thank you for choosing Vet2U!');

    return buffer.toString();
  }
}
