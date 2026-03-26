import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/general_provider.dart';
import '../providers/auth_provider.dart';
import '../models/payment.dart';
import '../models/taxe.dart';
import '../utils/constants.dart';
import 'ticket_screen.dart';
import 'ticketsScreen.dart';


class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final provider = Provider.of<GeneralProvider>(context, listen: false);
      provider.fetchPayments();
      provider.fetchTaxes();
      provider.fetchCommunes();
    });
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddPaymentForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('Historique Paiements'),
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
      ),

      body: provider.isLoading && provider.payments.isEmpty
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchPayments(),
              child: ListView.builder(
                padding: EdgeInsets.all(15),
                itemCount: provider.payments.length,
                itemBuilder: (context, index) {
                  final item = provider.payments[index];
                  return _buildPaymentCard(item);
                },
              ),
            ),

      // ✅ bouton historique tickets bien placé
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ticketsScreen()),
            );
          },
          icon: Icon(Icons.history, color: Colors.white),
          label: Text(
            'Historique Tickets',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.secondaryColor,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppConstants.primaryColor,
        child: Icon(Icons.payment, color: Colors.white),
      ),
    );
  }

  Widget _buildPaymentCard(Payment item) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        title: Text(
          'Paiement #${item.id ?? 'N/A'}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text('Contribuable: ${item.contribuableNom ?? 'Inconnu'}'),
            Text('Taxe: ${item.taxeType ?? 'Inconnue'}'),
            Text('Date: ${formatter.format(item.datePayement)}'),
            SizedBox(height: 5),
            Text(
              '${item.montant} FCFA',
              style: TextStyle(
                color: AppConstants.successColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.print, color: AppConstants.primaryColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketScreen(payment: item),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AddPaymentForm extends StatefulWidget {
  @override
  _AddPaymentFormState createState() => _AddPaymentFormState();
}

class _AddPaymentFormState extends State<AddPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();

  Taxe? _selectedTaxe;
  int? _selectedCommune;
  int? _selectedQuartier;
  String _modePayement = 'Espèces';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    final unpaidTaxes = provider.taxes
        .where((t) =>
            t.statut.toLowerCase() != 'payee' &&
            t.statut.toLowerCase() != 'payé')
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Effectuer un paiement',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              DropdownButtonFormField<int>(
                value: _selectedCommune,
                decoration: InputDecoration(
                  labelText: 'Commune',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                isExpanded: true,
                items: provider.communes
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nom, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCommune = val;
                    _selectedQuartier = null;
                  });
                  if (val != null) {
                    provider.fetchQuartiers(val);
                  }
                },
                validator: (val) => val == null ? 'Champ obligatoire' : null,
              ),

              SizedBox(height: 15),

              DropdownButtonFormField<int>(
                value: _selectedQuartier,
                decoration: InputDecoration(
                  labelText: 'Quartier',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                isExpanded: true,
                items: provider.quartiers
                    .map((q) => DropdownMenuItem(
                          value: q.id,
                          child: Text(q.nom, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedQuartier = val),
                validator: (val) => val == null ? 'Champ obligatoire' : null,
              ),

              SizedBox(height: 15),

              DropdownButtonFormField<Taxe>(
                value: _selectedTaxe,
                decoration: InputDecoration(
                  labelText: 'Choisir la Taxe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
                isExpanded: true,
                items: unpaidTaxes
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(
                            '${t.contribuableNom} - ${t.typeTaxeNom} (${t.montant} F)',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTaxe = val),
                validator: (val) => val == null ? 'Champ obligatoire' : null,
              ),

              SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: _modePayement,
                decoration: InputDecoration(
                  labelText: 'Mode de paiement',
                  border: OutlineInputBorder(),
                ),
                items: ['Espèces', 'Mobile Money', 'Carte']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) => setState(() => _modePayement = val!),
              ),

              SizedBox(height: 15),

              TextFormField(
                controller: _refController,
                decoration: InputDecoration(
                  labelText: 'Référence Transaction (Optionnel)',
                  border: OutlineInputBorder(),
                ),
              ),

              SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            if (_selectedTaxe?.id == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text("Veuillez choisir une taxe")),
                              );
                              return;
                            }

                            final payment = Payment(
                              taxeId: _selectedTaxe!.id!,
                              communeId: _selectedCommune!,
                              contribuableId: _selectedTaxe!.contribuableId,
                              quartierId: _selectedQuartier!,
                              montant: _selectedTaxe!.montant,
                              modePayement: _modePayement,
                              datePayement: DateTime.now(),
                              referenceTransaction:
                                  _refController.text.trim().isEmpty
                                      ? null
                                      : _refController.text.trim(),
                            );

                            final result =
                                await provider.createPayment(payment);

                            if (result != null) {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TicketScreen(payment: result),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(provider.error ??
                                        'Erreur lors du paiement')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                  ),
                  child: provider.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Confirmer le Paiement',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}