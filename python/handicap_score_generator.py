import random

def generate_scores_for_handicap(target_handicap, par=35, course_rating=70, slope=113, num_scores=20):
    """
    Generate golf scores that will produce a specific handicap.
    
    Args:
        target_handicap (float): Desired 9-hole handicap
        par (int): Course par for 9 holes (default 35)
        course_rating (float): 18-hole course rating (default 70)
        slope (int): Course slope rating (default 113)
        num_scores (int): Total number of scores to generate (default 20)
    
    Returns:
        tuple: (all_scores, verification_handicap)
    """
    
    # Step 1: Calculate target differential for the 8 lowest scores
    target_18_hole_handicap = target_handicap * 2
    target_avg_differential = target_18_hole_handicap / 0.96
    
    # Step 2: Generate 8 scores that average to the target differential
    base_9_hole_score = (target_avg_differential + course_rating) / 2
    
    # Create variation around the base score
    lowest_8_scores = []
    total_differential = 0
    
    # Generate 7 scores with some variation
    for i in range(7):
        # Add random variation of ±2 strokes
        variation = random.uniform(-2, 2)
        score = round(base_9_hole_score + variation)
        
        # Ensure score is realistic (par+4 to par+15)
        score = max(par + 4, min(par + 15, score))
        lowest_8_scores.append(score)
        
        # Calculate differential
        score_18 = score * 2
        differential = (score_18 - course_rating) * 113 / slope
        total_differential += differential
    
    # Calculate the 8th score to hit exact target
    needed_differential = (target_avg_differential * 8) - total_differential
    needed_18_hole = (needed_differential * slope / 113) + course_rating
    eighth_score = round(needed_18_hole / 2)
    
    # Ensure 8th score is realistic
    eighth_score = max(par + 4, min(par + 15, eighth_score))
    lowest_8_scores.append(eighth_score)
    
    # Step 3: Generate remaining scores with realistic variance
    if num_scores > 8:
        remaining_scores = []
        
        # Calculate expected average score for this handicap
        expected_avg_score = par + target_handicap
        
        for i in range(num_scores - 8):
            # Generate scores with ±5 stroke variance around expected average
            variance = random.uniform(-5, 5)
            score = round(expected_avg_score + variance)
            
            # Ensure score is realistic and higher than 8th best
            min_score = max(lowest_8_scores) + 1
            score = max(min_score, min(par + 25, score))
            remaining_scores.append(score)
        
        all_scores = lowest_8_scores + remaining_scores
    else:
        all_scores = lowest_8_scores[:num_scores]
    
    # Shuffle scores to make them appear random
    random.shuffle(all_scores)
    
    # Step 4: Verify the handicap calculation
    verification_handicap = calculate_handicap(all_scores, course_rating, slope)
    
    return all_scores, verification_handicap

def calculate_handicap(scores, course_rating=70, slope=113):
    """
    Calculate handicap from a list of 9-hole scores using USGA method.
    
    Args:
        scores (list): List of 9-hole scores
        course_rating (float): 18-hole course rating
        slope (int): Course slope rating
    
    Returns:
        float: 9-hole handicap rounded to 1 decimal place
    """
    if len(scores) < 5:
        return None  # Need at least 5 scores for USGA method
    
    # Calculate differentials
    differentials = []
    for score in scores:
        score_18 = score * 2
        differential = (score_18 - course_rating) * 113 / slope
        differentials.append(differential)
    
    # Sort differentials and select appropriate number
    differentials.sort()
    
    # Determine how many lowest scores to use
    num_scores = len(scores)
    if num_scores <= 6:
        num_to_use = 1
    elif num_scores <= 8:
        num_to_use = 2
    elif num_scores <= 11:
        num_to_use = 3
    elif num_scores <= 14:
        num_to_use = 4
    elif num_scores <= 16:
        num_to_use = 5
    elif num_scores <= 18:
        num_to_use = 6
    elif num_scores == 19:
        num_to_use = 7
    else:  # 20+ scores
        num_to_use = 8
    
    # Calculate average of lowest differentials
    avg_differential = sum(differentials[:num_to_use]) / num_to_use
    
    # Apply 96% factor and convert to 9-hole handicap
    handicap_18 = avg_differential * 0.96
    handicap_9 = handicap_18 / 2
    
    return round(handicap_9, 1)

def generate_example_scores(target_handicap):
    """
    Generate and display example scores for a target handicap.
    """
    print(f"\nGenerating scores for {target_handicap} handicap:")
    print("=" * 50)
    
    # Generate 8 scores (minimum for 20+ score calculation)
    eight_scores, eight_handicap = generate_scores_for_handicap(target_handicap, num_scores=8)
    print(f"\n8 Scores: {sorted(eight_scores)}")
    print(f"Calculated Handicap: {eight_handicap}")
    
    # Generate 20 scores
    twenty_scores, twenty_handicap = generate_scores_for_handicap(target_handicap, num_scores=20)
    print(f"\n20 Scores: {sorted(twenty_scores)}")
    print(f"Calculated Handicap: {twenty_handicap}")
    
    # Show the 8 lowest from the 20 scores
    twenty_sorted = sorted(twenty_scores)
    print(f"8 Lowest from 20: {twenty_sorted[:8]}")

if __name__ == "__main__":
    # Test with different handicaps
    test_handicaps = [5.0, 10.0, 15.0, 20.0]
    
    for handicap in test_handicaps:
        generate_example_scores(handicap)
        print()