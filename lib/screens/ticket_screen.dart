import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';

class TicketScreen extends StatefulWidget {
  final Payment payment;

  TicketScreen({required this.payment});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final ApiService _apiService = ApiService();

  bool _isPrinting = false;
  bool _alreadyPrinted = false;

  DateTime? _dateExpiration; // ✅ Date + Heure expiration

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyPrinted();
  }

  Future<void> _checkIfAlreadyPrinted() async {
    final prefs = await SharedPreferences.getInstance();
    final printedTickets = prefs.getStringList("printed_tickets") ?? [];

    final paymentId = widget.payment.id;

    if (paymentId != null && printedTickets.contains(paymentId.toString())) {
      setState(() {
        _alreadyPrinted = true;
      });
    }
  }

  Future<void> _savePrintedTicket(int paymentId) async {
    final prefs = await SharedPreferences.getInstance();
    final printedTickets = prefs.getStringList("printed_tickets") ?? [];

    if (!printedTickets.contains(paymentId.toString())) {
      printedTickets.add(paymentId.toString());
      await prefs.setStringList("printed_tickets", printedTickets);
    }
  }

  // ✅ Choix date + heure
  Future<void> _pickExpirationDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 23, minute: 59),
    );

    if (pickedTime == null) return;

    setState(() {
      _dateExpiration = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _printTicket(BuildContext context) async {
    if (_isPrinting || _alreadyPrinted) return;

    final paymentId = widget.payment.id;

    if (paymentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: paiement invalide")),
      );
      return;
    }

    // ✅ Obliger à choisir la date expiration
    if (_dateExpiration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez choisir une date et une heure d'expiration")),
      );
      return;
    }

    // ✅ Désactiver immédiatement pour éviter double clic
    setState(() {
      _isPrinting = true;
      _alreadyPrinted = true;
    });

    // ✅ Sauvegarder immédiatement pour bloquer même si app crash
    await _savePrintedTicket(paymentId);

    try {
      // 1️⃣ Appel API pour créer le ticket
      final response = await _apiService.post(
        'tickets',
        {
          'commune_id': widget.payment.communeId,
          'contribuable_id': widget.payment.contribuableId,
          'taxe_id': widget.payment.taxeId,
          'date_expiration': _dateExpiration!.toIso8601String(),
          'statut': 'payé',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final ticketId = data['data']?['id'];

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
                  pw.Text(
                    'REPUBLIQUE DU TOGO',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                  pw.Text(
                    'Travail - Liberté - Patrie',
                    style: pw.TextStyle(
                        fontStyle: pw.FontStyle.italic, fontSize: 8),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'MAIRIE GOLFE 7',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                  pw.Divider(),
                  pw.Text(
                    'RECU DE PAIEMENT',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Ticket ID: ${ticketId ?? 'N/A'}'),
                        pw.Text('Date Paiement: ${formatter.format(widget.payment.datePayement)}'),
                        pw.Text('Expiration: ${formatter.format(_dateExpiration!)}'),
                        pw.Text('Contribuable: ${widget.payment.contribuableNom ?? 'Inconnu'}'),
                        pw.Text('Taxe: ${widget.payment.taxeType ?? 'Inconnue'}'),
                        pw.Text('Mode: ${widget.payment.modePayement}'),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'MONTANT PAYE: ${widget.payment.montant} FCFA',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'Merci pour votre contribution !',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 20),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data:
                        'Ticket:$ticketId|Paiement:$paymentId|Expiration:${_dateExpiration!.toIso8601String()}|Contrib:${widget.payment.contribuableNom}|Montant:${widget.payment.montant}',
                    width: 80,
                    height: 80,
                  ),
                ],
              );
            },
          ),
        );

        // 3️⃣ Impression
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save(),
        );
      } else {
        final data = jsonDecode(response.body);

        // ❌ Si API échoue
        if (mounted) {
          setState(() {
            _alreadyPrinted = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur création ticket: ${data['message'] ?? 'Erreur inconnue'}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Erreur création ticket: $e');

      if (mounted) {
        setState(() {
          _alreadyPrinted = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création du ticket')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
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
                'MAIRIE GOLFE 7',
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Divider(),
              SizedBox(height: 20),

              _buildInfoRow('Date', formatter.format(widget.payment.datePayement)),
              _buildInfoRow('Contribuable', widget.payment.contribuableNom ?? 'Inconnu'),
              _buildInfoRow('Taxe', widget.payment.taxeType ?? 'Inconnue'),
              _buildInfoRow('Mode de Paiement', widget.payment.modePayement),

              SizedBox(height: 20),

              // ✅ Sélection Date + Heure expiration
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Date & Heure d'expiration",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _dateExpiration == null
                                ? "Non définie"
                                : formatter.format(_dateExpiration!),
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _pickExpirationDateTime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.secondaryColor,
                          ),
                          child: Text(
                            "Choisir",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text('MONTANT TOTAL',
                        style: TextStyle(color: AppConstants.textSecondary)),
                    SizedBox(height: 5),
                    Text(
                      '${widget.payment.montant} FCFA',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40),

              QrImageView(
                data:
                    'Paiement:${widget.payment.id}|Contrib:${widget.payment.contribuableNom}|Montant:${widget.payment.montant}',
                version: QrVersions.auto,
                size: 150.0,
              ),

              SizedBox(height: 40),

              // ✅ bouton imprimer bloqué définitivement
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: (_alreadyPrinted || _isPrinting)
                      ? null
                      : () => _printTicket(context),
                  icon: Icon(Icons.print, color: Colors.white),
                  label: Text(
                    _alreadyPrinted
                        ? 'TICKET DEJA IMPRIME'
                        : (_isPrinting ? 'IMPRESSION...' : 'IMPRIMER LE TICKET'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _alreadyPrinted
                        ? Colors.grey
                        : AppConstants.secondaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
          Text(
            label,
            style: TextStyle(
              color: AppConstants.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}