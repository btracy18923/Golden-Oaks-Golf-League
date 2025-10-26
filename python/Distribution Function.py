# Complete Prize Distribution Table Generator
# Creates a full table for 4-40 players based on observed patterns

def generate_complete_prize_table():
    """Generate complete prize distribution table for 4-40 players"""
    
    # Known data points from your original table
    known_data = {
        15: (75, 19, [9, 6, 4, 0, 0, 0]),
        16: (80, 20, [10, 6, 4, 0, 0, 0]), 
        17: (85, 25, [12, 8, 5, 0, 0, 0]),
        18: (90, 30, [12, 8, 6, 4, 0, 0]),
        19: (95, 35, [13, 9, 7, 4, 2, 0]),
        20: (100, 40, [13, 11, 8, 5, 3, 0]),
        21: (105, 45, [14, 11, 9, 6, 3, 2]),
        22: (110, 46, [15, 11, 9, 6, 3, 2]),
        23: (115, 47, [15, 11, 9, 6, 4, 2]),
        24: (120, 48, [15, 11, 9, 6, 5, 2]),
        25: (125, 49, [15, 12, 9, 6, 5, 2]),
        26: (130, 50, [15, 12, 9, 6, 5, 3]),
        27: (135, 51, [15, 12, 10, 6, 5, 3]),
        28: (140, 52, [15, 13, 10, 6, 5, 3]),
        29: (145, 53, [15, 13, 10, 7, 5, 3]),
        30: (150, 54, [15, 13, 10, 8, 5, 3]),
        31: (155, 55, [15, 13, 10, 8, 6, 3]),
        32: (160, 56, [15, 13, 11, 8, 6, 3])
    }
    
    complete_table = {}
    
    # Generate 4-14 players (inferred from patterns)
    for players in range(4, 15):
        total = players * 5  # Each player antes $5
        if players <= 6:
            # Very small tournaments
            individual = max(3, players)
            
            if players == 4:
                prizes = [2, 1, 1, 0, 0, 0]
            elif players == 5:
                prizes = [3, 1, 1, 0, 0, 0]
            else:  # 6 players
                prizes = [4, 2, 1, 1, 0, 0]
            
            # Adjust first place to match individual total
            diff = individual - sum(prizes)
            prizes[0] += diff
            
        elif players <= 10:
            # Small tournaments
            individual = players + 2
            
            prizes = [
                int(individual * 0.45),  # 1st: 45%
                int(individual * 0.25),  # 2nd: 25%
                int(individual * 0.18),  # 3rd: 18%
                int(individual * 0.12),  # 4th: 12%
                0, 0
            ]
            
            remaining = individual - sum(prizes)
            prizes[0] += remaining
            
        else:  # 11-14 players
            # Medium tournaments
            individual = 9 + (players - 10) * 2
            
            prizes = [
                int(individual * 0.42),  # 1st
                int(individual * 0.24),  # 2nd
                int(individual * 0.18),  # 3rd
                int(individual * 0.11),  # 4th
                int(individual * 0.05),  # 5th
                0
            ]
            
            remaining = individual - sum(prizes)
            prizes[0] += remaining
        
        complete_table[players] = (total, individual, prizes)
    
    # Add known data
    for players, data in known_data.items():
        complete_table[players] = data
    
    # Generate 33-40 players (extrapolated)
    for players in range(33, 41):
        total = players * 5  # Each player antes $5
        
        # Keep individual pool growth modest - increase by $2 per additional player
        individual = 56 + (players - 32) * 2  # Gradual increase
        
        # Prize distribution for larger fields - follow pattern from known data
        # Keep 1st place growing while maintaining total individual pool
        
        # Reduce other places slightly to ensure 1st place can grow
        second_place = 13  # Reduce 2nd place slightly
        third_place = 11   # Reduce 3rd place slightly  
        fourth_place = 9   # Reduce 4th place slightly
        fifth_place = 7    # Reduce 5th place slightly
        sixth_place = 5    # Reduce 6th place slightly
        
        # 1st place gets the remainder to maintain individual total
        other_places_total = second_place + third_place + fourth_place + fifth_place + sixth_place
        first_place = individual - other_places_total
        
        prizes = [first_place, second_place, third_place, fourth_place, fifth_place, sixth_place]
        
        complete_table[players] = (total, individual, prizes)
    
    return complete_table, known_data.keys()

def print_complete_table():
    """Print the complete prize distribution table"""
    table, known_players = generate_complete_prize_table()
    
    print('Complete Prize Distribution Table (4-40 Players)')
    print('=' * 75)
    print('# Players | Total $ | Individual $ | 1st | 2nd | 3rd | 4th | 5th | 6th')
    print('-' * 75)
    
    for players in range(4, 41):
        total, individual, prizes = table[players]
        prize_str = ' | '.join(f'{p:3}' for p in prizes)
        marker = ' *' if players in known_players else ''
        print(f'{players:8} | {total:6} | {individual:11} | {prize_str}{marker}')
    
    print()
    print('* = Original table data provided')
    print('All other entries are inferred/extrapolated based on observed patterns')
    
    return table

if __name__ == "__main__":
    print_complete_table()