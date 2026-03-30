import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/contribuable.dart';
import '../models/taxe.dart';
import '../models/payment.dart';
import '../models/ticket.dart';
import '../models/others.dart';
import '../services/api_service.dart';

import 'package:geolocator/geolocator.dart';

class GeneralProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ------------------- LISTES -------------------
  List<Contribuable> _contribuables = [];
  List<Taxe> _taxes = [];
  List<Payment> _payments = [];
  List<Commune> _communes = [];
  List<Quartier> _quartiers = [];
  List<TypeTaxe> _typeTaxes = [];
  List<Ticket> _tickets = [];


  double _totalPaye = 0;
  int _totalTickets = 0;
  int _totalTaxes = 0;
  int _agentsActifs = 0;
  double _tauxRecouvrement = 0;


  // ------------------- ETATS -------------------
  bool _isLoading = false;
  String? _error;

  // ------------------- GETTERS -------------------
  List<Contribuable> get contribuables => _contribuables;
  List<Taxe> get taxes => _taxes;
  List<Payment> get payments => _payments;
  List<Commune> get communes => _communes;
  List<Quartier> get quartiers => _quartiers;
  List<TypeTaxe> get typeTaxes => _typeTaxes;
  List<Ticket> get tickets => _tickets;

  double get totalPaye => _totalPaye;
  int get totalTickets => _totalTickets;
  int get totalTaxes => _totalTaxes;
  int get agentsActifs => _agentsActifs;

  double get tauxRecouvrement => _tauxRecouvrement;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ------------------- CONTRIBUABLES -------------------
  Future<void> fetchContribuables() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('contribuables');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> contribList = data['data']['data'] ?? [];
        _contribuables =
            contribList.map((item) => Contribuable.fromJson(item)).toList();
      } else {
        _error = data['message'] ?? 'Erreur lors du chargement';
      }
    } catch (e) {
      _error = 'Erreur serveur';
      print('Erreur fetchContribuables: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createContribuable(Contribuable contribuable,
      {int? agentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = contribuable.toJson();
      if (agentId != null) payload['agent_id'] = agentId;

      final response = await _apiService.post('contribuables', payload);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == true) {
        final newContrib = Contribuable.fromJson(data['data']);
        _contribuables.insert(0, newContrib);
        return true;
      } else {
        _error = data['message'] ?? 'Erreur lors de la création';
        return false;
      }
    } catch (e) {
      _error = 'Erreur de connexion au serveur';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------- TAXES -------------------
  Future<void> fetchTaxes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('taxes');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> list = data['data']?['data'] ?? [];
        _taxes = list.map((item) => Taxe.fromJson(item)).toList();
      } else {
        _error = data['message'] ?? "Erreur chargement taxes";
      }
    } catch (e) {
      _error = e.toString();
      print("Erreur fetchTaxes: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTaxe(Taxe taxe, {int? agentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = taxe.toJson();
      if (agentId != null) payload['agent_id'] = agentId;

      final response = await _apiService.post('taxes', payload);
      final data = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['status'] == true) {
        _taxes.insert(0, Taxe.fromJson(data['data']));
        return true;
      } else {
        _error = data['message'] ?? 'Erreur lors de la création de la taxe';
        return false;
      }
    } catch (e) {
      _error = 'Erreur de connexion au serveur';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------- PAYEMENTS -------------------
  Future<void> fetchPayments() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('payements');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> paymentList = data['data']['data'] ?? [];
        _payments =
            paymentList.map((item) => Payment.fromJson(item)).toList();
      } else {
        _error = data['message'] ?? 'Erreur lors du chargement des paiements';
      }
    } catch (e) {
      _error = 'Erreur de connexion au serveur';
      print('Erreur fetchPayments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Payment?> createPayment(Payment payment) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final payload = payment.toJson();

      final response = await _apiService.post('payements', payload);
      final data = jsonDecode(response.body);

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          data['status'] == true) {
        final newPayment = Payment.fromJson(data['data']);
        _payments.insert(0, newPayment);
        return newPayment;
      } else {
        _error = data['message'] ?? "Erreur lors du paiement";
        return null;
      }
    } catch (e) {
      print("Erreur createPayment: $e");
      _error = "Erreur serveur: $e";
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ------------------- COMMUNES -------------------
  Future<void> fetchCommunes() async {
    try {
      final response = await _apiService.get('communes');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final dynamic dataContent = data['data'];

        final List<dynamic> communeList =
            (dataContent is Map && dataContent.containsKey('data'))
                ? dataContent['data']
                : (dataContent is List ? dataContent : []);

        _communes =
            communeList.map((item) => Commune.fromJson(item)).toList();

        notifyListeners();
      }
    } catch (e) {
      print('Erreur fetchCommunes: $e');
    }
  }

  // -------------------RECUPERATION DE  QUARTIERS DANS PAYEMENT-------------------
  Future<void> fetchQuartiers(int communeId) async {
    try {
      final response = await _apiService.get('quartiers/commune/$communeId');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final dynamic dataContent = data['data'];
        final List<dynamic> quartierList =
            dataContent is List ? dataContent : [];

        _quartiers =
            quartierList.map((item) => Quartier.fromJson(item)).toList();

        notifyListeners();
      }
    } catch (e) {
      print('Erreur fetchQuartiers: $e');
    }
  }

  Future<bool> createQuartier(Quartier quartier) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post('quartiers', quartier.toJson());
      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['status'] == true) {
        // Optionnel : recharger les quartiers si on est sur une vue filtrée
        // ou simplement notifier le succès
        return true;
      } else {
        _error = data['message'] ?? "Erreur lors de la création du quartier";
        return false;
      }
    } catch (e) {
      print("Erreur createQuartier: $e");
      _error = "Erreur serveur: $e";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }




  // ------------------- TYPES TAXES -------------------
  Future<void> fetchTypeTaxes() async {
    try {
      final response = await _apiService.get('types-taxes');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> typeList = data['data']['data'] ?? [];
        _typeTaxes =
            typeList.map((item) => TypeTaxe.fromJson(item)).toList();

        notifyListeners();
      } else {
        print("Erreur API types taxes: ${data['message']}");
      }
    } catch (e) {
      print("Erreur fetchTypeTaxes: $e");
    }
  }

  // ------------------- TICKETS -------------------
  Future<void> fetchTickets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('tickets');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> ticketList = data['data']['data'] ?? [];
        _tickets = ticketList.map((e) => Ticket.fromJson(e)).toList();
      } else {
        _error = data['message'] ?? "Erreur lors du chargement des tickets";
      }
    } catch (e) {
      _error = "Erreur serveur: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardStats() async {
  try {
    final response = await _apiService.get('dashboard/stats');
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == true) {
      _totalPaye = double.parse(data['data']['total_paye'].toString());
      _totalTickets = data['data']['total_tickets'];
      _totalTaxes = data['data']['total_taxes'];
      _agentsActifs = data['data']['agents_actifs'];
      _tauxRecouvrement = (data['data']['taux_recouvrement'] as num?)?.toDouble() ?? 0.0;

      notifyListeners();
    }
  } catch (e) {
    print("Erreur fetchDashboardStats: $e");
  }
}


}