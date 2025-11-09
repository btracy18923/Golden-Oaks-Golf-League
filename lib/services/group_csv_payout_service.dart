import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class GroupCsvPayoutService {
  static final GroupCsvPayoutService _instance = GroupCsvPayoutService._internal();
  factory GroupCsvPayoutService() => _instance;
  GroupCsvPayoutService._internal();

  List<List<dynamic>>? _payoutData;

  Future<void> loadPayoutData() async {
    if (_payoutData != null) return; // Already loaded
    
    try {
      final String csvData = await rootBundle.loadString('assets/Group_Payouts.csv');
      _payoutData = const CsvToListConverter().convert(csvData);
    } catch (e) {
      throw Exception('Failed to load group payout data: $e');
    }
  }

  Future<Map<String, double>> getPayoutAmounts(int numPlayers) async {
    if (_payoutData == null) {
      await loadPayoutData();
    }

    // Find the row for the given number of players
    for (int i = 1; i < _payoutData!.length; i++) { // Skip header row
      List<dynamic> row = _payoutData![i];
      if (row.isNotEmpty) {
        int rowPlayers = int.tryParse(row[0].toString()) ?? 0;
        
        if (rowPlayers == numPlayers) {
          return {
            'team_total': _parseAmount(row[1]),
            '1st_team_ind': _parseAmount(row[2]),
            '2nd_team_ind': _parseAmount(row[3]),
            '3rd_team_ind': _parseAmount(row[4]),
            '4th_team_ind': _parseAmount(row[5]),
          };
        }
      }
    }

    // If exact number not found, find the closest higher number
    int closestHigher = -1;
    for (int i = 1; i < _payoutData!.length; i++) {
      List<dynamic> row = _payoutData![i];
      if (row.isNotEmpty && row[0] is int && row[0] > numPlayers) {
        if (closestHigher == -1 || row[0] < closestHigher) {
          closestHigher = row[0];
        }
      }
    }

    if (closestHigher != -1) {
      return getPayoutAmounts(closestHigher);
    }

    // Fallback to default values if no data found
    return {
      'team_total': 0.0,
      '1st_team_ind': 0.0,
      '2nd_team_ind': 0.0,
      '3rd_team_ind': 0.0,
      '4th_team_ind': 0.0,
    };
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    
    String stringValue = value.toString();
    // Remove dollar sign and any other non-numeric characters except decimal point
    stringValue = stringValue.replaceAll(RegExp(r'[^\d.]'), '');
    
    return double.tryParse(stringValue) ?? 0.0;
  }

  Future<List<double>> getPayoutList(int numPlayers) async {
    Map<String, double> payouts = await getPayoutAmounts(numPlayers);
    return [
      payouts['1st_team_ind'] ?? 0.0,
      payouts['2nd_team_ind'] ?? 0.0,
      payouts['3rd_team_ind'] ?? 0.0,
      payouts['4th_team_ind'] ?? 0.0,
    ];
  }
}