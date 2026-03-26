import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/payment.dart';
import '../utils/constants.dart';
import '../services/api_service.dart'; // Assure-toi d'avoir un ApiService pour tes requêtes HTTP

class TicketScreen extends StatelessWidget {
  final Payment payment;
  final ApiService _apiService = ApiService();

  TicketScreen({required this.payment});

  Future<void> _printTicket(BuildContext context) async {
    try {
      // 1️⃣ Appel API pour créer le ticket
      final response = await _apiService.post(
        'tickets',
         {
          'commune_id': payment.communeId,
          'contribuable_id': payment.contribuableId,
          'taxe_id': payment.taxeId,
          'date_expiration': DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'statut': 'payé',
        },
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final ticketId = data['data']['id'];
      

        // 2️⃣ Génération du PDF
        final pdf = pw.Document();
        final formatter = DateFormat('dd/MM/yyyy HH:mm');

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.roll80,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('REPUBLIQUE DU TOGO',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text('Travail - Liberté - Patrie',
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8)),
                  pw.SizedBox(height: 10),
                  pw.Text('MAIRIE GOLF 7',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Divider(),
                  pw.Text('RECU DE PAIEMENT',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Ticket #: ${payment.id ?? 'N/A'}'),
                        pw.Text('Date: ${formatter.format(payment.datePayement)}'),
                        pw.Text('Contribuable: ${payment.contribuableNom ?? 'Inconnu'}'),
                        pw.Text('Taxe: ${payment.taxeType ?? 'Inconnue'}'),
                        pw.Text('Mode: ${payment.modePayement}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text('MONTANT PAYE: ${payment.montant} FCFA',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.SizedBox(height: 15),
                  pw.Text('Merci pour votre contribution !', style: pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 20),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'Ticket:${payment.id}|Contrib:${payment.contribuableNom}|Montant:${payment.montant}',
                    width: 80,
                    height: 80,
                  ),
                ],
              );
            },
          ),
        );

        // 3️⃣ Impression
        await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur création ticket: ${data['message']}')),
        );
      }
    } catch (e) {
      print('Erreur création ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création du ticket')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Ticket de Paiement'),
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(30),
        child: Center(
          child: Column(
            children: [
              Text(
                'MAIRIE GOLF 7',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Divider(),
              SizedBox(height: 20),
              _buildInfoRow('Ticket ID', '#${payment.id ?? 'N/A'}'),
              _buildInfoRow('Date', formatter.format(payment.datePayement)),
              _buildInfoRow('Contribuable', payment.contribuableNom ?? 'Inconnu'),
              _buildInfoRow('Taxe', payment.taxeType ?? 'Inconnue'),
              _buildInfoRow('Mode de Paiement', payment.modePayement),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('MONTANT TOTAL', style: TextStyle(color: AppConstants.textSecondary)),
                    SizedBox(height: 5),
                    Text(
                      '${payment.montant} FCFA',
                      style: GoogleFonts.poppins(
                          fontSize: 28, fontWeight: FontWeight.bold, color: AppConstants.successColor),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              QrImageView(
                data: 'Ticket:${payment.id}|Contrib:${payment.contribuableNom}|Montant:${payment.montant}',
                version: QrVersions.auto,
                size: 150.0,
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () => _printTicket(context),
                  icon: Icon(Icons.print, color: Colors.white),
                  label: Text('IMPRIMER LE TICKET',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: AppConstants.textSecondary, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}