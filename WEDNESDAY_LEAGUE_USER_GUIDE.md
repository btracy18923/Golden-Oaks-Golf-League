# Wednesday League User Guide
## Golden Oaks Golf League Application

---

## Table of Contents
1. [Getting Started](#getting-started)
2. [Main Menu](#main-menu)
3. [Wednesday Parent Screen](#wednesday-parent-screen)
4. [Player Selection](#player-selection)
5. [Enter Scores Screen](#enter-scores-screen)
6. [Results Screen](#results-screen)
7. [Player Profiles](#player-profiles)
8. [Player Scores](#player-scores)
9. [Closest Pin](#closest-pin)
10. [Administration](#administration)
11. [Handicap System](#handicap-system)
12. [Tips and Best Practices](#tips-and-best-practices)

---

## Getting Started

### Application Launch
When you launch the Golden Oaks Golf League application, you will see the main menu with two league options:
- **Monday League** (green button)
- **Wednesday League** (orange button)

The application is designed for landscape mode on Android tablets and will automatically lock to landscape orientation.

### Device Compatibility
The application supports:
- **10" tablets** - Primary deployment devices
- **8" tablets** - Secondary deployment option
- **6.5" phones** - Mobile access

---

## Main Menu

### Selecting Wednesday League
1. Tap the **Wednesday League** button (orange)
2. The application will:
   - Set Players Ante to $5.00
   - Set Closest Pin to $1.00
   - Set Mulligan amount to $1.00
3. Navigate to the Wednesday Parent Screen

---

## Wednesday Parent Screen

The Wednesday Parent Screen is your main control center for managing the golf day.

### Key Difference from Monday League
**Wednesday league ALWAYS plays at Golden Oaks Golf Course**
- No golf course selection is required
- The course is fixed and cannot be changed
- This simplifies the setup process

### Screen Layout

#### Top Section - League Settings
The top portion displays and allows you to configure:

1. **Players Ante**
   - Default: $5.00
   - Tap the amount to edit using the custom keypad
   - This is the amount each player pays to enter the league for the day

2. **Closest Pin**
   - Default: $1.00
   - Can be manually edited by tapping the amount
   - This is the per-player amount for closest-to-pin contests

3. **Mulligans**
   - Default: $1.00
   - Tap the amount to edit using the custom keypad
   - This is the amount players pay for mulligan purchases

#### Editing Amounts
- Tap any dollar amount to open the custom keypad
- Enter the new whole dollar amount
- Amounts are displayed as currency (e.g., $5.00)
- Press Enter on the keypad to confirm
- Press Backspace to reset to $0.00

#### Middle Section - Golden Oaks Image
- Displays the Golden Oaks Golf Course logo
- Visual branding for the league

#### Bottom Section - Navigation Buttons

1. **Player Selection** (Orange - Always enabled)
   - Takes you to the player selection screen
   - No prerequisites required (unlike Monday League)
   - This is your next step in the workflow

2. **Player Profiles** (Light Orange)
   - View and manage player information
   - Access player statistics and handicap history
   - Can be accessed at any time

3. **Player Scores** (Light Orange)
   - View historical scores for all players
   - Search and filter player scoring history
   - Can be accessed at any time

#### Top Right - Administration
- Storage icon in the app bar
- Access administrative functions
- Firebase sync controls
- Database management
- Email configuration settings

---

## Player Selection

The Player Selection screen allows you to choose which players are participating in today's league.

### Screen Layout
Players are displayed in a 4-column grid for easy browsing.

### Selecting Players

1. **Browse the Player List**
   - Players from the Wednesday league are shown
   - Names are displayed alphabetically by last name

2. **Select/Deselect Players**
   - Tap a player's card to select them
   - Selected players are highlighted with a gold background
   - Tap again to deselect
   - You can select any number of players (typically 4-40 players)

3. **Player Card Information**
   - Player's last name is displayed
   - Selection is indicated by background color change

### Bottom Navigation Buttons

1. **Enter Scores** (Orange when players are selected)
   - Becomes active when at least one player is selected
   - Proceeds to the Enter Scores screen
   - Player count is shown on the button

2. **Clear All** (Red)
   - Deselects all currently selected players
   - Useful for starting over

3. **Select All** (Blue)
   - Selects all Wednesday league players at once
   - Toggle button - press again to deselect all

---

## Enter Scores Screen

The Enter Scores screen is where you input player scores, organize groups, and calculate winnings. **This is the most complex screen in the application.**

### Wednesday League Scoring System

Wednesday league uses a **dual purse system**:
1. **Group Competition**: Groups compete against each other
2. **Individual Competition**: Individual players compete for personal winnings

### Initial Setup

#### Player Organization
When you first enter this screen:
- Selected players are initially displayed in a single column
- You need to organize them into groups

#### Auto-Fill/Shuffle Feature
1. **Shuffle Groups Button** (Top Right)
   - Tap "Shuffle Groups" to randomly distribute players into groups
   - Players are automatically organized into groups of 4
   - If there's an odd number, some groups may have 3 players
   - Groups are labeled Group 1, Group 2, etc.

2. **Manual Organization** (Adjust Players)
   - You can manually adjust player positions after auto-fill
   - See "Adjust Players" section below

### Screen Layout

#### Top Section - Purse Information
Displays current purse amounts:
- **Players Purse**: Total Players Ante collected (Players Ante × Number of Players)
- **Mulligan Purse**: Total mulligan fees collected
- These amounts update automatically as you enter data

#### Middle Section - Player Groups
- Groups are displayed in a scrollable grid
- Each group shows up to 4 players
- Groups are numbered (Group 1, Group 2, etc.)

#### Player Cards
Each player card shows:
- **Player Name** (Last name)
- **Gross Score Input Field**: Enter the player's gross score
- **Handicap Display**: Shows calculated handicap (auto-calculated from history)
- **Net Score**: Automatically calculated (Gross - Handicap)
- **Mulligans**: Number of mulligans purchased (0-2)
- **Group Winnings**: Earnings from group competition
- **Individual Winnings**: Earnings from individual competition
- **Final Amount**: Total winnings/losses

### Entering Data

#### Gross Scores
1. Tap the Gross input field for a player
2. Custom keypad appears at the bottom
3. Enter the gross score (whole number)
4. Press Enter to confirm
5. Move to the next player

**Gross Score Rules:**
- Whole numbers only (e.g., 85, 92, 78)
- Typically range from 70 to 130 for 18 holes
- This is the actual score the player shot on the course

#### Automatic Handicap Calculation
When you enter a gross score:
- The system automatically looks up the player's handicap
- Handicap is calculated using the **simplified algorithm**:
  - Uses the most recent 6 scores with gross data
  - Drops the 2 highest scores
  - Averages the remaining 4 scores
  - Subtracts 35 to get the handicap
  - Padded with (OHC + 35) if fewer than 6 scores available
- Handicap is displayed on the player card
- **Net Score** is automatically calculated: Gross - Handicap

#### Mulligan Entry
1. Tap the "M" button on a player's card to increment mulligans
2. Cycles through: 0 → 1 → 2 → 0
3. Each mulligan adds to the Mulligan Purse
4. Mulligan count is shown on the button

#### Automatic Calculations
As you enter data, the system calculates:
- **Group Competition**: Compares net scores within each group
  - Lowest net score in the group wins
  - Group purse is distributed to winning groups
- **Individual Competition**: Compares net scores across all players
  - Lowest net scores overall win
  - Individual purse is distributed based on payout tables
- **Final Winnings**: Sum of group + individual + closest pin - mulligans - ante

### Adjust Players Feature

#### Opening Adjust Players Overlay
1. Tap the "Adjust Players" button (top of screen)
2. An overlay appears showing all groups
3. **IMPORTANT**: While overlay is active:
   - Player Selection button is DISABLED
   - Gross score entry is DISABLED
   - You can only adjust player positions

#### Swapping Players
1. **First Selection**: Tap a player card - it highlights in yellow
2. **Second Selection**: Tap another player card
3. **Automatic Swap**: The two players exchange positions
4. Swap is confirmed with a brief message

#### Swap Rules
- Can swap players between any groups
- Can swap players within the same group
- Empty slots can be included in swaps
- Selections clear after each swap

#### Closing Adjust Players Overlay
1. Tap the "Close" button (or "Adjust Players" button again)
2. Overlay disappears
3. Normal score entry is re-enabled
4. Player Selection button becomes available again

### Payout Distribution

The Wednesday league uses **CSV-based payout tables** for both group and individual competitions:

#### Group Payouts
- Groups compete based on total group net scores
- Winning groups split the group purse
- Distribution based on number of groups (loaded from Group_Payouts.csv)

#### Individual Payouts
- Individual players compete based on net scores
- Winners split the individual purse
- Distribution based on number of players (loaded from payout CSV files)

#### Viewing Distribution
- Scroll down to see the payout distribution summary
- Shows both group and individual winners
- Displays payout amounts for each winner

### Bottom Navigation Buttons

1. **Player Selection** (Grey/Disabled during certain conditions)
   - Returns to Player Selection screen
   - **DISABLED when**:
     - Adjust Players overlay is active
     - Gross scores have been entered
   - Prevents accidental navigation that would lose entered data

2. **Adjust Players** (Blue)
   - Opens/closes the player swap overlay
   - Allows reorganizing players between groups

3. **Shuffle Groups** (Purple)
   - Randomly redistributes all players into balanced groups
   - Useful for quick initial organization

4. **Closest Pin** (Orange)
   - Navigates to Closest Pin management screen
   - Record closest-to-pin contest winners
   - See Closest Pin section below

5. **Calculate / View Results** (Green when ready)
   - Becomes active when all gross scores are entered
   - Proceeds to Results Screen
   - Shows final summary and allows saving

---

## Results Screen

The Results Screen displays the final results and allows you to save to the database.

### Screen Layout

#### Top Section - League Information
Displays:
- **Play Date**: Current date
- **Golf Course**: Always "Golden Oaks" for Wednesday league
- **Total Players**: Count of players who participated

#### Purse Summary
Shows the purse totals:
- **Players Purse**: Total collected from Players Ante
- **Mulligan Purse**: Total mulligan fees collected
- **Group Purse**: Portion allocated to group competition
- **Individual Purse**: Portion allocated to individual competition

#### Player Results Table
Scrollable table showing all players with:
- **Player Name** (Last name)
- **Gross Score**: The score entered
- **Handicap**: Calculated handicap
- **Net Score**: Gross - Handicap
- **Mulligans**: Number purchased
- **Group Winnings**: Amount won from group competition
- **Individual Winnings**: Amount won from individual competition
- **Total Winnings**: Final amount (can be positive or negative)

### Saving Results

#### Save to Database Button
1. Review all information carefully
2. Tap "Save to Database" (Green button)
3. Application performs save process:
   - Validates data
   - Checks for duplicate dates (if duplicate prevention is enabled)
   - Saves to local SQLite database (wednesday_scores table)
   - Uploads to Firebase (if enabled)
   - **Calculates and updates player handicaps** for next use
   - Sends email notification (if configured)

#### Duplicate Date Prevention
- **If Enabled** (default): Application prevents saving scores for the same player on the same date
- **If Disabled**: Allows multiple scores per player per day
- Setting controlled in Administration screen

#### Firebase Upload
- **If Enabled** (default): Results automatically sync to Firebase cloud database
- **If Disabled**: Saves only to local database
- Setting controlled in Administration screen

#### Email Notification
- **If Configured**: System automatically sends email with results
- Email includes player scores, handicaps, and winnings
- Configuration done in Administration screen

#### Success
- Green confirmation message appears
- Data is saved, synced, and handicaps updated
- You can navigate away

#### Errors
- Red error message appears if save fails
- Common issues:
  - Duplicate date conflict
  - Network error during Firebase sync
  - Database connection issue
  - Email sending failure (non-critical - save still succeeds)

### Bottom Navigation

1. **Back Button** (Top Left)
   - Returns to Enter Scores screen
   - Allows corrections if needed

2. **Save to Database** (Green)
   - Saves all results and updates handicaps
   - See above for details

3. **Main Menu** (Light Grey)
   - Returns to main league selection
   - Available after successful save

---

## Player Profiles

The Player Profiles screen allows you to view and manage player information.

### Features
- View all Wednesday league players
- Player details including:
  - Name (First and Last)
  - Player number
  - League assignment
  - Current handicap (OHC - Original Handicap)
  - Handicap history and trends
  - Statistics (if available)

### Navigation
- Access from Wednesday Parent Screen
- Available at any time
- Does not affect current game session

---

## Player Scores

The Player Scores screen displays historical scoring data.

### Features
- View all historical scores for Wednesday league players
- Search and filter capabilities
- Score details including:
  - Date played
  - Gross score
  - Calculated handicap (at time of play)
  - Net score
  - Mulligans purchased
  - Group winnings
  - Individual winnings
  - Total winnings/losses

### Use Cases
- Review player performance history
- Verify past scores
- Track handicap progression
- Settle disputes
- Analyze player trends

---

## Closest Pin

The Closest Pin screen manages closest-to-pin contest winners.

### Purpose
Track which players won closest-to-pin contests during the round.

### Entering Closest Pin Winners

1. **Access from Enter Scores Screen**
   - Tap the "Closest Pin" button (orange)

2. **Select Winners**
   - List shows all players from today's game
   - Tap players who won closest pin contests
   - Multiple winners can be selected (typically 3-5 for Golden Oaks)

3. **Automatic Payout Calculation**
   - Closest Pin Purse is divided equally among winners
   - Each winner receives: (Closest Pin Amount × Number of Players) ÷ Number of Winners

4. **Save and Return**
   - Closest pin winnings are added to player totals
   - Return to Enter Scores screen
   - Winnings appear in Final Amount column

---

## Administration

The Administration screen provides system management functions.

### Access
- Tap the storage icon in the top right of Wednesday Parent Screen
- Requires no special authentication

### Key Features

#### 1. Firebase Upload Toggle
**Turn off Firebase Uploads** checkbox
- **Enabled (Unchecked)**: Results automatically sync to Firebase cloud
- **Disabled (Checked)**: Results save only to local database
- **Use Cases for Disabling**:
  - No internet connection
  - Testing scenarios
  - Offline tournament play
- Setting persists across app sessions

#### 2. Duplicate Date Prevention
**Allow Duplicate Dates** checkbox
- **Disabled (Unchecked)**: Prevents saving multiple scores for same player on same date
- **Enabled (Checked)**: Allows multiple scores per player per day
- **Recommended**: Keep disabled to prevent data entry errors
- Setting persists across app sessions

#### 3. Email Configuration
**Send Email After Results** toggle
- Enable/disable automatic email sending
- Configure email settings:
  - Recipient email addresses
  - Subject line format
  - Email template customization
- Uses backend email service for delivery
- Non-blocking: Email failures don't prevent database saves

#### 4. Database Download (If implemented)
- Download player and score data from Firebase
- Sync cloud database to local device
- Useful for:
  - Setting up new tablet
  - Recovering from local database issues
  - Syncing latest cloud data

#### 5. View System Information
- Device details
- Database status
- Firebase connection status
- Email service status

---

## Handicap System

### Wednesday League Handicap Algorithm

The Wednesday league uses a **simplified handicap system** designed for fairness and ease of calculation.

#### How Handicaps are Calculated

1. **Data Source**: Most recent 6 scores with gross data
2. **Padding**: If fewer than 6 scores, pad with (OHC + 35)
   - OHC = Original Handicap Cap (baseline handicap for new players)
3. **Calculation**:
   - Take the 6 scores (real scores + padding if needed)
   - Sort them from lowest to highest
   - **Drop the 2 highest scores**
   - Average the remaining 4 scores
   - Subtract 35 to get the handicap
4. **Rounding**: Result is rounded to 1 decimal place

#### Examples

**Example 1: Player with 6+ scores**
- Recent gross scores: [88, 92, 85, 90, 87, 94]
- Sort: [85, 87, 88, 90, 92, 94]
- Drop 2 highest: [85, 87, 88, 90]
- Average: (85 + 87 + 88 + 90) ÷ 4 = 87.5
- Handicap: 87.5 - 35 = **52.5**

**Example 2: Player with 3 scores (OHC = 15)**
- Recent gross scores: [88, 92, 85]
- Padding value: 15 + 35 = 50
- Padded list: [88, 92, 85, 50, 50, 50]
- Sort: [50, 50, 50, 85, 88, 92]
- Drop 2 highest: [50, 50, 50, 85]
- Average: (50 + 50 + 50 + 85) ÷ 4 = 58.75
- Handicap: 58.75 - 35 = **23.8** (rounded to 1 decimal)

#### Handicap Updates
- Handicaps are **recalculated every time scores are saved**
- New scores are added to player history
- Next game uses the updated handicap
- Historical scores retain the handicap used at time of play

#### Net Score Calculation
- **Net Score = Gross Score - Handicap**
- Net scores determine winners in both group and individual competitions
- Lower net score is better

---

## Tips and Best Practices

### Before League Play

1. **Verify Settings**
   - Check Players Ante amount ($5.00 default)
   - Check Closest Pin amount ($1.00 default)
   - Check Mulligan amount ($1.00 default)
   - Verify Firebase uploads are enabled (if needed)
   - Verify email notifications are configured (if desired)

2. **Review Player List**
   - Ensure all active players are in the database
   - Verify handicaps are current
   - Check for any data issues

3. **Test Device**
   - Ensure tablet is charged
   - Check internet connection (for Firebase sync and email)
   - Verify landscape orientation works

### During Player Selection

1. **Count Players**
   - Note total number selected
   - Ensure all participating players are checked
   - Use Select All for full league days

2. **Double-Check Selections**
   - Review selected players before proceeding
   - Use Clear All if you need to start over

### During Score Entry

1. **Organize Groups First**
   - Use Shuffle Groups for quick random distribution
   - Use Adjust Players for manual fine-tuning
   - Try to match actual golf groups if possible

2. **Enter Gross Scores Carefully**
   - Verify each score as you enter it
   - Gross scores should match scorecards
   - Watch for automatic handicap and net score calculations
   - Double-check net scores make sense

3. **Track Mulligans**
   - Update mulligan counts as you go
   - Maximum 2 per player
   - Mulligans affect final winnings

4. **Monitor Calculations**
   - Watch group winnings populate
   - Watch individual winnings populate
   - Verify final amounts look reasonable

5. **Don't Leave Screen**
   - Player Selection button is disabled after score entry starts
   - Prevents accidental loss of entered data

### Recording Closest Pins

1. **Collect Information During Play**
   - Track closest pin winners during the round
   - Note which holes had contests
   - Confirm winners before entering

2. **Enter Before Calculating Results**
   - Add closest pin winners before viewing results
   - Winnings are included in final totals

### Before Saving Results

1. **Review Results Screen Thoroughly**
   - Verify all gross scores are correct
   - Check handicaps look reasonable
   - Review net scores
   - Verify mulligan counts
   - Check group winnings distribution
   - Check individual winnings distribution
   - Confirm purse amounts add up correctly

2. **Validate Calculations**
   - Total winnings should approximately equal total antes (minus mulligans)
   - Check for any unusually high/low payouts
   - Verify closest pin winnings are distributed

3. **Save Promptly**
   - Save results as soon as they're verified
   - Don't wait - data could be lost if app closes
   - Allow time for Firebase sync to complete

### After Saving

1. **Verify Success**
   - Look for green confirmation message
   - Check that Firebase sync completed (if enabled)
   - Verify email was sent (if configured)

2. **Keep Device On**
   - If Firebase upload is happening, don't close app immediately
   - Allow time for cloud sync to complete

3. **Verify Handicap Updates**
   - Handicaps are automatically recalculated
   - Check Player Profiles to see updated handicaps
   - New handicaps will be used in next game

### Data Management

1. **Regular Backups**
   - Periodically download data from Firebase
   - Keep cloud database as primary backup
   - Test restore procedures

2. **Duplicate Date Prevention**
   - Keep this enabled unless specifically needed
   - Prevents accidental double-entry
   - Protects handicap calculations

3. **Firebase Sync**
   - Keep enabled for automatic cloud backup
   - Only disable when necessary (no internet, testing)
   - Both tablets sync to same cloud database

4. **Email Notifications**
   - Configure email to keep players informed
   - Test email delivery before first use
   - Email failures don't prevent saves

### Troubleshooting

#### Handicap Seems Wrong
- **Check**: Player's recent score history
- **Verify**: At least 6 scores exist (or padding is working correctly)
- **Review**: Gross scores entered were accurate
- **Remember**: Handicap drops 2 highest of last 6 scores

#### Net Scores Don't Match Expected
- **Verify**: Gross score was entered correctly
- **Check**: Handicap calculation is current
- **Formula**: Net = Gross - Handicap
- **Example**: Gross 88, Handicap 15.5, Net = 72.5

#### No Group/Individual Winnings
- **Cause**: Player's net score wasn't in winning positions
- **Check**: Compare net scores with other players in group
- **Verify**: Payout tables loaded correctly (CSV files)

#### SKAT Input Not Working
- **Cause**: Adjust Players overlay is open
- **Solution**: Close the overlay by tapping "Adjust Players" button

#### Player Selection Button Disabled
- **Cause**: Gross scores have been entered, or Adjust Players overlay is open
- **Solution**:
  - Close Adjust Players overlay if open
  - If scores entered, use Back button to return from Results screen

#### Save Failed - Duplicate Date Error
- **Cause**: Player already has score for today
- **Solution**:
  - Check if scores were already saved
  - Enable "Allow Duplicate Dates" in Admin if multiple rounds needed
  - Use different date if testing

#### Firebase Upload Failed
- **Cause**: No internet connection
- **Solution**:
  - Check device internet connection
  - Data is saved locally and will sync later
  - Manually trigger sync when connection restored

#### Email Not Sent
- **Cause**: Email service not configured or network issue
- **Note**: This doesn't prevent save - data is still saved to database
- **Solution**:
  - Check email configuration in Admin
  - Verify internet connection
  - Check email logs in Admin screen

---

## Workflow Summary

### Recommended Workflow

1. **Launch Application** → Select Wednesday League
2. **Wednesday Parent Screen** → Verify/adjust Ante, Closest Pin, Mulligan amounts
3. **Wednesday Parent Screen** → Tap "Player Selection"
4. **Player Selection** → Select all participating players (or use Select All)
5. **Player Selection** → Tap "Enter Scores"
6. **Enter Scores** → Tap "Shuffle Groups" to organize players
7. **Enter Scores** → (Optional) Use "Adjust Players" to fine-tune groups
8. **Enter Scores** → Enter Gross scores for all players
   - Watch handicaps auto-calculate
   - Watch net scores populate
   - Verify calculations look correct
9. **Enter Scores** → Enter Mulligan counts
10. **Enter Scores** → Tap "Closest Pin" to record winners
11. **Closest Pin** → Select closest pin winners, save and return
12. **Enter Scores** → Review group and individual winnings
13. **Enter Scores** → Tap "Calculate / View Results"
14. **Results** → Review all data thoroughly:
    - Verify all gross scores
    - Check handicaps and net scores
    - Verify group and individual winnings
    - Check purse distributions
15. **Results** → Tap "Save to Database"
16. **Results** → Verify success message
17. **Results** → Confirm Firebase sync completed (if enabled)
18. **Results** → Confirm email sent (if configured)
19. **Results** → Tap "Main Menu" to return to start

---

## Key Differences from Monday League

### Simplified Setup
- **No Golf Course Selection**: Wednesday always plays at Golden Oaks
- **Always Ready**: Player Selection button is always enabled (no prerequisites)

### Dual Competition System
- **Group Competition**: Groups compete for group purse
- **Individual Competition**: Individuals compete for individual purse
- **Monday** uses only SKATS scoring (simpler system)

### Handicap System
- **Wednesday**: Uses calculated handicaps based on recent scores
- **Gross and Net Scores**: Entered and tracked separately
- **Monday**: No handicap system

### Scoring Display
- **Wednesday**: Shows Gross, Handicap, Net, Group Winnings, Individual Winnings
- **Monday**: Shows only SKATS scores and winnings

### Email Notifications
- **Wednesday**: Supports automatic email after results saved
- **Monday**: No email feature currently

### Color Scheme
- **Wednesday**: Orange theme
- **Monday**: Green theme

---

## Support and Questions

For technical issues, questions, or feature requests, contact your league administrator or application developer.

---

**Document Version**: 1.0
**Last Updated**: December 31, 2025
**Application**: Golden Oaks Golf League - Wednesday League Module
