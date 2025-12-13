/// Data model for representing player data in Wednesday golf league scoring
/// Extends the basic player data concept with Wednesday-specific fields
class WednesdayPlayerData {
  final String name;
  final double handicap;
  final int? grossScore;
  final int? netScore;
  final String position;
  final String prizeMoney;
  final int? manualGroup;
  final bool isWildCard;

  const WednesdayPlayerData({
    required this.name,
    this.handicap = 0.0,
    this.grossScore,
    this.netScore,
    this.position = '',
    this.prizeMoney = '',
    this.manualGroup,
    this.isWildCard = false,
  });

  @override
  String toString() {
    return 'WednesdayPlayerData(name: $name, handicap: $handicap, gross: $grossScore, net: $netScore, pos: $position, prize: $prizeMoney, group: $manualGroup, wildCard: $isWildCard)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WednesdayPlayerData &&
        other.name == name &&
        other.handicap == handicap &&
        other.grossScore == grossScore &&
        other.netScore == netScore &&
        other.position == position &&
        other.prizeMoney == prizeMoney &&
        other.manualGroup == manualGroup &&
        other.isWildCard == isWildCard;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        handicap.hashCode ^
        grossScore.hashCode ^
        netScore.hashCode ^
        position.hashCode ^
        prizeMoney.hashCode ^
        manualGroup.hashCode ^
        isWildCard.hashCode;
  }

  /// Creates a copy of this WednesdayPlayerData with updated values
  WednesdayPlayerData copyWith({
    String? name,
    double? handicap,
    int? grossScore,
    int? netScore,
    String? position,
    String? prizeMoney,
    int? manualGroup,
    bool? isWildCard,
  }) {
    return WednesdayPlayerData(
      name: name ?? this.name,
      handicap: handicap ?? this.handicap,
      grossScore: grossScore ?? this.grossScore,
      netScore: netScore ?? this.netScore,
      position: position ?? this.position,
      prizeMoney: prizeMoney ?? this.prizeMoney,
      manualGroup: manualGroup ?? this.manualGroup,
      isWildCard: isWildCard ?? this.isWildCard,
    );
  }

  /// Creates a WednesdayPlayerData instance from a map (useful for database operations)
  factory WednesdayPlayerData.fromMap(Map<String, dynamic> map) {
    return WednesdayPlayerData(
      name: map['last'] ?? map['name'] ?? '',
      handicap: (map['handicap'] ?? 0.0).toDouble(),
      grossScore: map['gross_score'] as int?,
      netScore: map['net_score'] as int?,
      position: map['pos'] ?? '',
      prizeMoney: map['prize_money'] ?? '',
      manualGroup: map['manual_group'] as int?,
      isWildCard: map['is_wild_card'] == true,
    );
  }

  /// Converts this WednesdayPlayerData to a map (useful for database operations)
  Map<String, dynamic> toMap() {
    return {
      'last': name,
      'handicap': handicap,
      'gross_score': grossScore,
      'net_score': netScore,
      'pos': position,
      'prize_money': prizeMoney,
      'manual_group': manualGroup,
      'is_wild_card': isWildCard,
    };
  }

  /// Calculates the net score from gross score and handicap
  int? calculateNetScore() {
    if (grossScore == null) return null;
    return grossScore! - handicap.round();
  }

  /// Returns true if this player has a complete gross score (2 digits)
  bool hasCompleteGrossScore() {
    return grossScore != null && grossScore! >= 10;
  }
}
