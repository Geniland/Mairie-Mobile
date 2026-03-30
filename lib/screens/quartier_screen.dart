import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/general_provider.dart';
import '../models/others.dart';
import '../utils/constants.dart';

class QuartierScreen extends StatefulWidget {
  @override
  _QuartierScreenState createState() => _QuartierScreenState();
}

class _QuartierScreenState extends State<QuartierScreen> {
  int? _selectedCommune;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<GeneralProvider>();
      provider.fetchCommunes();
    });
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddQuartierForm(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text('Gestion des Quartiers', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: AppConstants.secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(15),
            color: Colors.white,
            child: DropdownButtonFormField<int>(
              value: _selectedCommune,
              decoration: InputDecoration(
                labelText: 'Filtrer par Commune',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.location_city, color: AppConstants.primaryColor),
              ),
              items: provider.communes.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text(c.nom),
              )).toList(),
              onChanged: (val) {
                setState(() => _selectedCommune = val);
                if (val != null) {
                  provider.fetchQuartiers(val);
                }
              },
            ),
          ),
          Expanded(
            child: _selectedCommune == null
                ? Center(child: Text('Sélectionnez une commune pour voir les quartiers', style: GoogleFonts.poppins(color: Colors.grey)))
                : provider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : provider.quartiers.isEmpty
                        ? Center(child: Text('Aucun quartier trouvé', style: GoogleFonts.poppins()))
                        : ListView.builder(
                            padding: EdgeInsets.all(15),
                            itemCount: provider.quartiers.length,
                            itemBuilder: (context, index) {
                              final item = provider.quartiers[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text(item.nom, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Lat: ${item.latitude ?? "N/A"}, Long: ${item.longitude ?? "N/A"}'),
                                  leading: CircleAvatar(
                                    backgroundColor: AppConstants.primaryColor.withOpacity(0.1),
                                    child: Icon(Icons.map, color: AppConstants.primaryColor),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppConstants.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class AddQuartierForm extends StatefulWidget {
  @override
  _AddQuartierFormState createState() => _AddQuartierFormState();
}

// class AddQuartierForm extends StatefulWidget {
//   @override
//   _AddQuartierFormState createState() => _AddQuartierFormState();
// }

class _AddQuartierFormState extends State<AddQuartierForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  int? _selectedCommune;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    // <-- IMPORTANT : pré-remplir automatiquement latitude et longitude
    Future.microtask(() => _getCurrentLocation());
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Services de localisation désactivés. Veuillez activer le GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permission de localisation refusée';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Permission de localisation définitivement refusée. Veuillez l\'activer dans les paramètres.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );

      setState(() {
        _latController.text = position.latitude.toString();
        _lngController.text = position.longitude.toString();
      });
    } catch (e) {
      print("Erreur de localisation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GeneralProvider>(context);

    return Padding(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedCommune,
                decoration: InputDecoration(
                  labelText: 'Commune',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: provider.communes
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.nom),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCommune = val),
                validator: (val) =>
                    val == null ? 'Veuillez choisir une commune' : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: 'Nom du Quartier',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Veuillez saisir un nom' : null,
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              TextButton.icon(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.my_location),
                label: Text(
                    _isGettingLocation ? 'Récupération...' : 'Utiliser ma position actuelle'),
              ),
              SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: provider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            final q = Quartier(
                              id: 0,
                              nom: _nomController.text,
                              communeId: _selectedCommune!,
                              latitude:
                                  double.tryParse(_latController.text),
                              longitude:
                                  double.tryParse(_lngController.text),
                            );
                            final success =
                                await provider.createQuartier(q);
                            if (success) {
                              provider.fetchQuartiers(_selectedCommune!);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Quartier ajouté avec succès')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(provider.error ??
                                          'Erreur lors de l\'ajout')));
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: provider.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Enregistrer',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}