import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_helper.dart';
import '../services/ante_manager.dart';
import '../services/percentage_manager.dart';
import '../services/closest_pin_manager.dart';
import '../services/mulligan_manager.dart';
import '../services/csv_payout_service.dart';
import '../services/payout_validation_service.dart';
import '../models/league.dart';
import 'popup_utils.dart';

class ProcessIndividualsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> selectedPlayers;
  final List<List<Map<String, dynamic>?>> groups;
  final String selectedLeague;
  final Map<String, TextEditingController> grossControllers;
  final Map<String, TextEditingController> skatsControllers;

  const ProcessIndividualsScreen({
    Key? key,
    required this.selectedPlayers,
    required this.groups,
    required this.selectedLeague,
    required this.grossControllers,
    required this.skatsControllers,
  }) : super(key: key);

  @override
  _ProcessIndividualsScreenState createState() => _ProcessIndividualsScreenState();
}

class _ProcessIndividualsScreenState extends State<ProcessIndividualsScreen> {
  String? closestPinWinnerName;
  double closestPinWinnings = 0.0;
  bool winnersCalculated = false;
  bool individualsProcessingComplete = false;
  bool isProcessing = false;
  List<Map<String, dynamic>> processedPlayers = [];

  @override
  void initState() {
    super.initState();
    // Start processing automatically when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processIndividuals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Process Individuals - ${widget.selectedLeague.toUpperCase()} League'),
        backgroundColor: Colors.blue[100],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isProcessing) _buildProcessingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingCard() {
    return Expanded(
      child: Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                SizedBox(height: 24),
                Text(
                  'Processing Individuals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Please wait while we calculate individual payouts...',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  List<Map<String, dynamic>> _collectPlayerScores() {
    List<Map<String, dynamic>> playerScores = [];
    Set<String> addedPlayers = {};
    
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null) {
          String playerKey = '${player['last']}_gross';
          String playerIdentifier = '${player['first']}_${player['last']}';
          TextEditingController? controller = widget.grossControllers[playerKey];
          
          if (controller != null && controller.text.isNotEmpty && !addedPlayers.contains(playerIdentifier)) {
            var playerData = Map<String, dynamic>.from(player);
            
            try {
              playerData['gross_score'] = int.parse(controller.text);
              
              if (widget.selectedLeague == 'wednesday') {
                double handicap = playerData['handicap']?.toDouble() ?? 0.0;
                playerData['net_score'] = playerData['gross_score'] - handicap.round();
              } else {
                String skatsKey = '${player['last']}_skats';
                TextEditingController? skatsController = widget.skatsControllers[skatsKey];
                if (skatsController != null && skatsController.text.isNotEmpty) {
                  playerData['skats_score'] = int.parse(skatsController.text);
                }
              }
              
              playerScores.add(playerData);
              addedPlayers.add(playerIdentifier);
            } catch (e) {
              // Skip players with invalid scores
            }
          }
        }
      }
    }
    
    return playerScores;
  }

  Future<bool> _processClosestPin(List<Map<String, dynamic>> allPlayers) async {
    if (allPlayers.isEmpty) {
      await PopupUtils.showWarning(context, "No Players", "No players available for closest pin selection!");
      return false;
    }

    while (true) {
      List<String> playerNames = allPlayers.map((player) => '${player['first']} ${player['last']}').toList();
      
      String? selectedPlayer = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text("Select Closest Pin Winner"),
            content: Container(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: playerNames.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(playerNames[index]),
                    onTap: () => Navigator.of(dialogContext).pop(playerNames[index]),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(null),
                child: Text("Cancel"),
              ),
            ],
          );
        },
      );

      if (selectedPlayer == null) {
        return false;
      }

      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text("Confirm Closest Pin Winner"),
            content: Text("Is $selectedPlayer the closest pin winner?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text("No"),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text("Yes"),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        double closestPinAmount = ClosestPinManager().currentClosestPinAmount;
        double totalClosestPinWinnings = closestPinAmount * allPlayers.length;
        
        setState(() {
          closestPinWinnerName = selectedPlayer;
          closestPinWinnings = totalClosestPinWinnings;
        });
        
        await PopupUtils.showSuccess(
          context, 
          "Closest Pin Winner", 
          "$selectedPlayer won the Closest Pin for \$${totalClosestPinWinnings.toStringAsFixed(2)}!"
        );
        
        return true;
      }
    }
  }

  List<Map<String, dynamic>> _collectAllSelectedPlayers() {
    List<Map<String, dynamic>> allPlayers = [];
    Set<String> addedPlayers = {};
    
    for (var group in widget.groups) {
      for (var player in group) {
        if (player != null) {
          String playerIdentifier = '${player['first']}_${player['last']}';
          if (!addedPlayers.contains(playerIdentifier)) {
            allPlayers.add(player);
            addedPlayers.add(playerIdentifier);
          }
        }
      }
    }
    
    return allPlayers;
  }

  void _processIndividuals() async {
    setState(() {
      isProcessing = true;
    });

    try {
      List<Map<String, dynamic>> playerScores = _collectPlayerScores();
      
      if (playerScores.isEmpty) {
        await PopupUtils.showWarning(context, "Process Error", "No player scores available to process!");
        return;
      }
      
      List<Map<String, dynamic>> allPlayers = _collectAllSelectedPlayers();
      
      bool closestPinCompleted = await _processClosestPin(allPlayers);
      
      if (!closestPinCompleted) {
        return;
      }
      
      await _calculateWinnings(playerScores);
      
      setState(() {
        winnersCalculated = true;
        processedPlayers = playerScores;
      });
      
      await _saveResultsToDatabase(playerScores);
      
      // Update the player data with pos and prize_money for the Enter Scores screen
      // Only set pos and prize_money for players who actually win money
      for (var player in playerScores) {
        double winnings = (player['winnings'] ?? 0.0).toDouble();
        int roundedWinnings = winnings.round();
        
        if (roundedWinnings > 0) {
          int place = player['place'] ?? 0;
          bool isTied = player['is_tied'] ?? false;
          
          if (isTied) {
            player['pos'] = 'T${place}';
          } else {
            player['pos'] = place.toString();
          }
          player['prize_money'] = '\$${roundedWinnings}';
        } else {
          player['pos'] = '';
          player['prize_money'] = '';
        }
      }
      
      // Perform payout validation
      PayoutValidationResult? validationResult = await _validatePayouts(playerScores);
      
      setState(() {
        individualsProcessingComplete = true;
      });
      
      // Return to Enter Scores screen with updated data and validation results
      Navigator.pop(context, {
        'individualsProcessingComplete': true,
        'updatedPlayers': playerScores,
        'payoutValidationResult': validationResult,
      });
    } catch (e) {
      setState(() {
        individualsProcessingComplete = false;
      });
      await PopupUtils.showError(context, "Process Error", "Failed to process individuals: $e");
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _calculateWinnings(List<Map<String, dynamic>> playerScores) async {
    // Sort players by score
    if (widget.selectedLeague == 'wednesday') {
      playerScores.sort((a, b) => a['net_score'].compareTo(b['net_score']));
    } else {
      playerScores.sort((a, b) => a['gross_score'].compareTo(b['gross_score']));
    }
    
    // Get payout amounts from CSV
    List<double> payoutList = await CsvPayoutService().getPayoutList(playerScores.length);
    
    // Group players by their scores to identify ties
    List<List<Map<String, dynamic>>> tieGroups = [];
    int currentIndex = 0;
    
    while (currentIndex < playerScores.length) {
      List<Map<String, dynamic>> tiedPlayers = [playerScores[currentIndex]];
      dynamic currentScore = widget.selectedLeague == 'wednesday' 
          ? playerScores[currentIndex]['net_score'] 
          : playerScores[currentIndex]['gross_score'];
      
      // Find all players with the same score
      for (int i = currentIndex + 1; i < playerScores.length; i++) {
        dynamic compareScore = widget.selectedLeague == 'wednesday'
            ? playerScores[i]['net_score']
            : playerScores[i]['gross_score'];
        
        if (compareScore == currentScore) {
          tiedPlayers.add(playerScores[i]);
        } else {
          break;
        }
      }
      
      tieGroups.add(tiedPlayers);
      currentIndex += tiedPlayers.length;
    }
    
    // Assign places and winnings based on tie groups
    int currentPlace = 1;
    
    for (var tieGroup in tieGroups) {
      int groupSize = tieGroup.length;
      
      if (groupSize == 1) {
        // No tie - regular placement
        var player = tieGroup[0];
        player['place'] = currentPlace;
        player['is_tied'] = false;
        
        if (currentPlace <= payoutList.length) {
          player['winnings'] = payoutList[currentPlace - 1];
        } else {
          player['winnings'] = 0.0;
        }
      } else {
        // Tie - calculate shared winnings
        double totalWinnings = 0.0;
        
        // Sum up the winnings for all positions involved in the tie
        for (int i = 0; i < groupSize; i++) {
          int position = currentPlace + i;
          if (position <= payoutList.length) {
            totalWinnings += payoutList[position - 1];
          }
        }
        
        // Divide evenly among tied players
        double sharedWinnings = totalWinnings / groupSize;
        
        // Assign to all tied players
        for (var player in tieGroup) {
          player['place'] = currentPlace;
          player['is_tied'] = true;
          player['tie_count'] = groupSize;
          player['winnings'] = sharedWinnings;
        }
      }
      
      currentPlace += groupSize;
    }
  }



  Future<void> _saveResultsToDatabase(List<Map<String, dynamic>> playerScores) async {
    final dbHelper = DatabaseHelper();
    
    if (closestPinWinnerName != null && closestPinWinnings > 0) {
      for (var player in playerScores) {
        String playerFullName = '${player['first']} ${player['last']}';
        if (playerFullName == closestPinWinnerName) {
          player['close_pin_winnings'] = closestPinWinnings;
          break;
        }
      }
    }
    
    for (var player in playerScores) {
      final db = await dbHelper.database;
      final playerRecords = await db.query(
        'players',
        where: 'first = ? AND last = ? AND league = ?',
        whereArgs: [player['first'], player['last'], widget.selectedLeague],
        limit: 1,
      );
      
      if (playerRecords.isNotEmpty) {
        var playerRecord = playerRecords.first;
        
        double winnings = (player['winnings'] ?? 0.0).toDouble();
        int roundedWinnings = winnings.round();
        
        String positionString = '';
        if (roundedWinnings > 0) {
          int place = player['place'] ?? 0;
          bool isTied = player['is_tied'] ?? false;
          positionString = isTied ? 'T${place}' : place.toString();
        }
        
        Map<String, dynamic> scoreData = {
          'player_id': playerRecord['id'],
          'name': player['last'],
          'date_played': DateTime.now().toIso8601String().split('T')[0],
          'handicap': playerRecord['handicap'] ?? 0.0,
          'gross_score': player['gross_score'],
          'close_pin_winnings': player['close_pin_winnings']?.toDouble() ?? 0.0,
          'pos': positionString,
          'prize_money': roundedWinnings > 0 ? '\$${roundedWinnings}' : '',
        };
        
        if (widget.selectedLeague == 'monday') {
          scoreData['golf_course'] = 'TBD';
          scoreData['skat_number'] = playerRecord['skat_number'] ?? 0;
          scoreData['skats_score'] = player['skats_score'] ?? 0;
          scoreData['skat_winnings'] = roundedWinnings.toDouble();
        } else {
          scoreData['golf_course'] = 'The Hideout';
          scoreData['single_winnings'] = roundedWinnings.toDouble();
          
          double groupWinnings = (player['group_winnings'] ?? 0.0).toDouble();
          int roundedGroupWinnings = groupWinnings.round();
          scoreData['group_winnings'] = roundedGroupWinnings.toDouble();
        }
        
        League league = widget.selectedLeague == 'monday' ? League.monday : League.wednesday;
        await dbHelper.insertScoreLeague(scoreData, league);
      }
    }
  }

  Future<PayoutValidationResult?> _validatePayouts(List<Map<String, dynamic>> playerScores) async {
    try {
      // Get total number of selected players
      int totalSelectedPlayers = widget.groups
          .expand((group) => group)
          .where((player) => player != null && player['is_wild_card'] != true)
          .length;
      
      // Get current mulligan purse amount (we need to pass this from Enter Scores Screen in future)
      double currentMulliganPurse = MulliganManager().currentMulliganAmount * totalSelectedPlayers;
      
      League league = widget.selectedLeague == 'monday' ? League.monday : League.wednesday;
      
      PayoutValidationResult result;
      if (widget.selectedLeague == 'monday') {
        // For Monday league, use the specialized Monday validation
        result = await PayoutValidationService().validateMondayLeaguePayouts(
          players: playerScores,
          totalSelectedPlayers: totalSelectedPlayers,
          currentMulliganPurse: currentMulliganPurse,
        );
      } else {
        // For Wednesday league, use individual validation
        result = await PayoutValidationService().validateIndividualPayouts(
          players: playerScores,
          league: league,
          totalSelectedPlayers: totalSelectedPlayers,
          currentMulliganPurse: currentMulliganPurse,
        );
      }
      
      return result;
    } catch (e) {
      // Payout validation failed in ProcessIndividualsScreen: $e
      return null;
    }
  }
}