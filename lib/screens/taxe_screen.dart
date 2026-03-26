import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/general_provider.dart';
import '../providers/auth_provider.dart';
import '../models/taxe.dart';
import '../utils/constants.dart';

class TaxeScreen extends StatefulWidget {
  @override
  _TaxeScreenState createState() => _TaxeScreenState();
}

class _TaxeScreenState extends State<TaxeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<GeneralProvider>();
      provider.fetchTaxes();
      provider.fetchTypeTaxes();
      provider.fetchContribuables();
      provider.fetchCommunes();
    });
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddTaxeForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('Gestion des Taxes'),
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading && provider.taxes.isEmpty
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.fetchTaxes(),
              child: ListView.builder(
                padding: EdgeInsets.all(15),
                itemCount: provider.taxes.length,
                itemBuilder: (context, index) {
                  final item = provider.taxes[index];
                  return _buildTaxeCard(item);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppConstants.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaxeCard(Taxe item) {
    final isPaid = item.statut.toLowerCase() == 'payee' || item.statut.toLowerCase() == 'payé';
    final formatter = DateFormat('dd/MM/yyyy');

    return Card(
      margin: EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(15),
        title: Text(
          item.typeTaxeNom ?? 'Taxe #${item.id}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text('Contribuable: ${item.contribuableNom ?? 'Inconnu'}'),
            SizedBox(height: 2),
            Text('Période: ${formatter.format(item.periodeDebut)} - ${formatter.format(item.periodeFin)}'),
            SizedBox(height: 5),
            Text(
              '${item.montant} FCFA',
              style: TextStyle(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item.statut.toUpperCase(),
            style: TextStyle(
              color: isPaid ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class AddTaxeForm extends StatefulWidget {
  @override
  _AddTaxeFormState createState() => _AddTaxeFormState();
}

class _AddTaxeFormState extends State<AddTaxeForm> {
  final _formKey = GlobalKey<FormState>();
  final _montantController = TextEditingController();
  
  int? _selectedContribuable;
  int? _selectedTypeTaxe;
  int? _selectedCommune;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 365));

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

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
                'Émettre une taxe',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
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
                items: provider.communes.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.nom, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCommune = val),
                validator: (val) => val == null ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<int>(
                value: _selectedContribuable,
                decoration: InputDecoration(
                  labelText: 'Contribuable',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                isExpanded: true,
                items: provider.contribuables.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.nom, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) => setState(() => _selectedContribuable = val),
                validator: (val) => val == null ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 15),
              DropdownButtonFormField<int>(
                value: _selectedTypeTaxe,
                decoration: InputDecoration(
                  labelText: 'Type de Taxe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                isExpanded: true,
                items: provider.typeTaxes.map((t) => DropdownMenuItem(
                  value: t.id,
                  child: Text(t.nom, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) {
                  setState(() => _selectedTypeTaxe = val);
                  if (val != null) {
                    final type = provider.typeTaxes.firstWhere((t) => t.id == val);
                    if (type.montantDefaut != null) {
                      _montantController.text = type.montantDefaut.toString();
                    }
                  }
                },
                validator: (val) => val == null ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _montantController,
                decoration: InputDecoration(labelText: 'Montant (FCFA)'),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Champ obligatoire' : null,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: Text('Début'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: Text('Fin'),
                      subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      final taxe = Taxe(
                        communeId: _selectedCommune!,
                        contribuableId: _selectedContribuable!,
                        typeTaxeId: _selectedTypeTaxe!,
                        agentId: auth.user!.id,
                        montant: double.parse(_montantController.text),
                        periodeDebut: _startDate,
                        periodeFin: _endDate,
                        statut: 'impayer',
                      );
                      final success = await provider.createTaxe(taxe, agentId: auth.user?.id);
                      if (success) {
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(provider.error ?? 'Erreur lors de la création')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                  child: provider.isLoading 
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Générer Taxe', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
