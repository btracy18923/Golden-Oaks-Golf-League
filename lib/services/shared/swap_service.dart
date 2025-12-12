import '../UI/enter_scores_UI_service.dart';
import '../../screens/popup_utils.dart';
import 'package:flutter/material.dart';

/// Position class to track positions in the groups grid
class SwapPosition {
  final int groupIndex;
  final int playerIndex;
  
  SwapPosition(this.groupIndex, this.playerIndex);
}

/// Service for handling player swapping functionality
/// Provides common swap logic for enter scores screens
class SwapService {
  
  /// List of selected items for swapping (player names or empty slot keys)
  List<String> selectedForSwap = [];
  
  /// Clears all swap selections
  void clearSelection() {
    selectedForSwap.clear();
  }
  
  /// Handles player selection for swapping
  /// Returns true if state should be updated
  bool handlePlayerSelection(String playerLast) {
    if (selectedForSwap.contains(playerLast)) {
      selectedForSwap.remove(playerLast);
    } else {
      if (selectedForSwap.length < 2) {
        selectedForSwap.add(playerLast);
      } else {
        selectedForSwap.clear();
        selectedForSwap.add(playerLast);
      }
    }
    return true; // Always update state
  }
  
  /// Handles empty slot selection for swapping
  /// Returns true if state should be updated
  bool handleEmptySlotSelection(String slotKey) {
    if (selectedForSwap.contains(slotKey)) {
      selectedForSwap.remove(slotKey);
    } else {
      if (selectedForSwap.length < 2) {
        selectedForSwap.add(slotKey);
      } else {
        selectedForSwap.clear();
        selectedForSwap.add(slotKey);
      }
    }
    return true; // Always update state
  }
  
  /// Checks if a player is currently selected for swapping
  bool isPlayerSelected(String playerLast) {
    return selectedForSwap.contains(playerLast);
  }
  
  /// Checks if an empty slot is currently selected for swapping
  bool isEmptySlotSelected(String slotKey) {
    return selectedForSwap.contains(slotKey);
  }
  
  /// Gets the display name for a selected item
  String getDisplayName(String selectedItem) {
    if (selectedItem.startsWith('empty_')) {
      List<String> parts = selectedItem.split('_');
      String groupNum = parts[1];
      String rowNum = parts[2];
      return 'Empty G${groupNum}R${int.parse(rowNum) + 1}';
    } else {
      return selectedItem;
    }
  }
  
  /// Generates the button text based on current selection state
  String getSwapButtonText() {
    if (selectedForSwap.length == 1) {
      String displayName = getDisplayName(selectedForSwap[0]);
      return 'Selected: $displayName\nClick another Name';
    } else if (selectedForSwap.length == 2) {
      String displayName1 = getDisplayName(selectedForSwap[0]);
      String displayName2 = getDisplayName(selectedForSwap[1]);
      return 'SWAP:\n$displayName1 <-> $displayName2';
    } else {
      return 'Swap Players';
    }
  }
  
  /// Checks if the swap button should be enabled
  bool isSwapButtonEnabled() {
    return selectedForSwap.length == 2;
  }
  
  /// Finds the position of an item in the groups
  SwapPosition? _findItemPosition(String item, List<List<PlayerData>> groups) {
    // Handle empty slots
    if (item.startsWith('empty_')) {
      List<String> parts = item.split('_');
      if (parts.length >= 3) {
        int groupNum = int.tryParse(parts[1]) ?? 0;
        int rowNum = int.tryParse(parts[2]) ?? 0;
        return SwapPosition(groupNum - 1, rowNum); // Convert to 0-based indexing
      }
      return null;
    }
    
    // Handle player names
    for (int groupIndex = 0; groupIndex < groups.length; groupIndex++) {
      for (int playerIndex = 0; playerIndex < groups[groupIndex].length; playerIndex++) {
        var player = groups[groupIndex][playerIndex];
        if (player.name == item) {
          return SwapPosition(groupIndex, playerIndex);
        }
      }
    }
    
    return null;
  }
  
  /// Performs the swap operation
  /// Returns the updated groups or null if swap failed
  List<List<PlayerData>>? performSwap(BuildContext context, List<List<PlayerData>> groups) {
    if (selectedForSwap.length != 2) {
      PopupUtils.showWarning(context, "Invalid Selection", "Please select exactly 2 items to swap.");
      return null;
    }
    
    try {
      String item1 = selectedForSwap[0];
      String item2 = selectedForSwap[1];
      
      // Find positions of both items
      SwapPosition? pos1 = _findItemPosition(item1, groups);
      SwapPosition? pos2 = _findItemPosition(item2, groups);
      
      if (pos1 == null || pos2 == null) {
        PopupUtils.showError(context, "Swap Error", "Could not locate selected items.");
        return null;
      }
      
      // Create a deep copy of groups for the swap
      List<List<PlayerData>> updatedGroups = groups.map((group) {
        return group.map((player) {
          return PlayerData(
            name: player.name,
            skNumber: player.skNumber,
            skats: player.skats,
            diff: player.diff,
            money: player.money,
          );
        }).toList();
      }).toList();
      
      // Ensure groups have enough slots for the positions
      while (updatedGroups.length <= pos1.groupIndex || updatedGroups.length <= pos2.groupIndex) {
        updatedGroups.add([]);
      }
      
      // Ensure groups have enough player slots
      while (updatedGroups[pos1.groupIndex].length <= pos1.playerIndex) {
        updatedGroups[pos1.groupIndex].add(PlayerData(name: '', skNumber: ''));
      }
      while (updatedGroups[pos2.groupIndex].length <= pos2.playerIndex) {
        updatedGroups[pos2.groupIndex].add(PlayerData(name: '', skNumber: ''));
      }
      
      // Perform the swap
      PlayerData temp = updatedGroups[pos1.groupIndex][pos1.playerIndex];
      updatedGroups[pos1.groupIndex][pos1.playerIndex] = updatedGroups[pos2.groupIndex][pos2.playerIndex];
      updatedGroups[pos2.groupIndex][pos2.playerIndex] = temp;
      
      // Clear selection after successful swap
      selectedForSwap.clear();
      
      return updatedGroups;
      
    } catch (e) {
      PopupUtils.showError(context, "Swap Error", "Failed to swap players: $e");
      selectedForSwap.clear();
      return null;
    }
  }
  
  /// Handles the main swap button press
  /// Returns the updated groups if swap was successful, null otherwise
  List<List<PlayerData>>? handleSwapButtonPress(BuildContext context, List<List<PlayerData>> groups) {
    if (selectedForSwap.length == 2) {
      return performSwap(context, groups);
    } else {
      PopupUtils.showWarning(context, "Invalid Selection", "Please select exactly 2 players or empty slots to swap.");
      return null;
    }
  }
  
  /// Gets the number of items currently selected for swapping
  int get selectionCount => selectedForSwap.length;
  
  /// Gets a list of currently selected items
  List<String> get selectedItems => List.unmodifiable(selectedForSwap);
}