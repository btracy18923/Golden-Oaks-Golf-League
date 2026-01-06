# Monday League User Guide
## Golden Oaks Golf League Application

---

## Table of Contents
1. [Getting Started](#getting-started)
2. [Main Menu](#main-menu)
3. [Monday Parent Screen](#monday-parent-screen)
4. [Player Selection](#player-selection)
5. [Enter Scores Screen](#enter-scores-screen)
6. [Results Screen](#results-screen)
7. [Player Profiles](#player-profiles)
8. [Player Scores](#player-scores)
9. [Golf Courses](#golf-courses)
10. [Closest Pin](#closest-pin)
11. [Administration](#administration)
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

### Selecting Monday League
1. Tap the **Monday League** button (green)
2. The application will:
   - Set Players Ante to $5.00
   - Set Closest Pin to $4.00
   - Set Mulligan amount to $2.00
3. Navigate to the Monday Parent Screen

---

## Monday Parent Screen

The Monday Parent Screen is your main control center for managing the golf day.

### Screen Layout

#### Top Section - League Settings
The top portion displays and allows you to configure:

1. **Golf Course Selection**
   - Dropdown menu showing all available golf courses
   - **REQUIRED**: You must select a golf course before proceeding to Player Selection
   - When you select a course, the Closest Pin amount automatically updates based on the number of Par 3 holes

2. **Players Ante**
   - Default: $5.00
   - Tap the amount to edit using the custom keypad
   - This is the amount each player pays to enter the league for the day

3. **Closest Pin**
   - Auto-calculated: Number of Par 3s × $1.00
   - Can be manually edited by tapping the amount
   - This is the total purse for closest-to-pin contests

4. **Mulligans**
   - Default: $2.00
   - Tap the amount to edit using the custom keypad
   - This is the amount players pay for mulligan purchases

#### Editing Amounts
- Tap any dollar amount to open the custom keypad
- Enter the new whole dollar amount
- Amounts are displayed as currency (e.g., $5.00)
- Press Enter on the keypad to confirm
- Press Backspace to reset to $0.00

#### Bottom Section - Navigation Buttons

1. **Player Selection** (Green when enabled)
   - Becomes active only after selecting a golf course
   - Takes you to the player selection screen
   - This is your next step in the workflow

2. **Player Profiles** (Light Green)
   - View and manage player information
   - Access player statistics and history
   - Can be accessed at any time

3. **Player Scores** (Light Green)
   - View historical scores for all players
   - Search and filter player scoring history
   - Can be accessed at any time

4. **Golf Courses** (Light Green)
   - Manage golf course information
   - Add, edit, or view course details
   - View Par 3 hole counts
   - Can be accessed at any time

#### Top Right - Administration
- Storage icon in the app bar
- Access administrative functions
- Firebase sync controls
- Database management

---

## Player Selection

The Player Selection screen allows you to choose which players are participating in today's league.

### Screen Layout
Players are displayed in a 4-column grid for easy browsing.

### Selecting Players

1. **Browse the Player List**
   - Players from the Monday league are shown
   - Names are displayed alphabetically by last name

2. **Select/Deselect Players**
   - Tap a player's card to select them
   - Selected players are highlighted with a light green background
   - Tap again to deselect
   - You can select any number of players (typically 4-40 players)

3. **Player Card Information**
   - Player's last name is displayed
   - Selection is indicated by background color change

### Bottom Navigation Buttons

1. **Enter Scores** (Green when players are selected)
   - Becomes active when at least one player is selected
   - Proceeds to the Enter Scores screen
   - Player count is shown on the button

2. **Clear All** (Red)
   - Deselects all currently selected players
   - Useful for starting over

### Automatic Purse Calculation
- As you select players, the Closest Pin Purse is automatically calculated:
  - Closest Pin Purse = Closest Pin Amount × Number of Selected Players

---

## Enter Scores Screen

The Enter Scores screen is where you input player scores and organize groups.

### Initial Setup

#### Player Organization
When you first enter this screen:
- Selected players are initially displayed in a single column
- You need to organize them into groups

#### Auto-Fill Feature
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
- **Skat Purse**: Total Players Ante collected (Players Ante × Number of Players)
- **Closest Pin Purse**: Total for closest pin contests
- **Mulligan Purse**: Total mulligan fees collected

#### Middle Section - Player Groups
- Groups are displayed in a scrollable grid
- Each group shows up to 4 players
- Groups are numbered (Group 1, Group 2, etc.)

#### Player Cards
Each player card shows:
- **Player Name** (Last name)
- **SKATS Input Field**: Enter the player's SKATS score
- **Mulligans**: Number of mulligans purchased (0-2)
- **Final Amount**: Calculated winnings/losses

### Entering Data

#### SKATS Scores
1. Tap the SKATS input field for a player
2. Custom keypad appears at the bottom
3. Enter the SKATS score (whole number)
4. Press Enter to confirm
5. Move to the next player

**SKATS Score Rules:**
- Whole numbers only
- Typically range from -10 to +10
- Negative scores = player won
- Positive scores = player lost

#### Mulligan Entry
1. Tap the "M" button on a player's card to increment mulligans
2. Cycles through: 0 → 1 → 2 → 0
3. Each mulligan adds to the Mulligan Purse
4. Mulligan count is shown on the button

#### Automatic Calculations
As you enter data:
- Player winnings/losses are calculated in real-time
- Purse amounts are updated automatically
- Final amounts are displayed on each player card

### Adjust Players Feature

#### Opening Adjust Players Overlay
1. Tap the "Adjust Players" button (top of screen)
2. An overlay appears showing all groups
3. **IMPORTANT**: While overlay is active:
   - Player Selection button is DISABLED
   - SKATS score entry is DISABLED
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

### Distribution and Payouts

#### Payout Calculation
The application automatically calculates payouts based on:
- Number of players (4-40 supported)
- SKATS scores (winners and losers)
- Dynamic distribution tables

#### Viewing Distribution
- Scroll down to see the payout distribution summary
- Shows how the Skat Purse is divided among winners

### Bottom Navigation Buttons

1. **Player Selection** (Grey/Disabled during certain conditions)
   - Returns to Player Selection screen
   - **DISABLED when**:
     - Adjust Players overlay is active
     - SKATS scores have been entered
   - Prevents accidental navigation that would lose entered data

2. **Adjust Players** (Blue)
   - Opens/closes the player swap overlay
   - Allows reorganizing players between groups

3. **Shuffle Groups** (Purple)
   - Randomly redistributes all players into balanced groups
   - Tracks shuffle state during session

4. **Closest Pin** (Orange)
   - Navigates to Closest Pin management screen
   - See Closest Pin section below

5. **Calculate / View Results** (Green when ready)
   - Becomes active when all SKATS scores are entered
   - Proceeds to Results Screen
   - Shows summary and allows saving

---

## Results Screen

The Results Screen displays the final results and allows you to save to the database.

### Screen Layout

#### Top Section - League Information
Displays:
- **Selected Golf Course**: The course played
- **Play Date**: Current date
- **Total Players**: Count of players who participated

#### Middle Section - Purse Summary
Shows the three purse totals:
- **Skat Purse**: Total collected from Players Ante
- **Closest Pin Purse**: Total closest pin funds
- **Mulligan Purse**: Total mulligan fees

#### Player Results Table
Scrollable table showing all players with:
- **Player Name** (Last name)
- **SKATS Score**: The score entered
- **Mulligans**: Number purchased
- **Winnings**: Final amount won/lost (positive = won, negative = lost)

### Saving Results

#### Save to Database Button
1. Review all information carefully
2. Tap "Save to Database" (Green button)
3. Application performs 4-step save process:
   - Validates data
   - Checks for duplicate dates (if duplicate prevention is enabled)
   - Saves to local SQLite database
   - Uploads to Firebase (if enabled)

#### Duplicate Date Prevention
- **If Enabled** (default): Application prevents saving scores for the same player on the same date
- **If Disabled**: Allows multiple scores per player per day
- Setting controlled in Administration screen

#### Firebase Upload
- **If Enabled** (default): Results automatically sync to Firebase cloud database
- **If Disabled**: Saves only to local database
- Setting controlled in Administration screen

#### Success
- Green confirmation message appears
- Data is saved and synced
- You can navigate away

#### Errors
- Red error message appears if save fails
- Common issues:
  - Duplicate date conflict
  - Network error during Firebase sync
  - Database connection issue

### Bottom Navigation

1. **Back Button** (Top Left)
   - Returns to Enter Scores screen
   - Allows corrections if needed

2. **Save to Database** (Green)
   - Saves all results
   - See above for details

3. **Main Menu** (Light Grey)
   - Returns to main league selection
   - Available after successful save

---

## Player Profiles

The Player Profiles screen allows you to view and manage player information.

### Features
- View all Monday league players
- Player details including:
  - Name (First and Last)
  - Player number
  - League assignment
  - Statistics (if available)

### Navigation
- Access from Monday Parent Screen
- Available at any time
- Does not affect current game session

---

## Player Scores

The Player Scores screen displays historical scoring data.

### Features
- View all historical scores for Monday league players
- Search and filter capabilities
- Score details including:
  - Date played
  - Golf course
  - SKATS score
  - Mulligans purchased
  - Winnings/losses

### Use Cases
- Review player performance history
- Verify past scores
- Track player trends
- Settle disputes

---

## Golf Courses

The Golf Course screen manages course information.

### Viewing Courses
- List of all golf courses in the system
- Course details displayed:
  - Course name
  - Number of Par 3 holes
  - Additional course information

### Adding a Course
(If implemented in your version)
1. Tap "Add Course" button
2. Enter course name
3. Enter number of Par 3 holes
4. Save course

### Editing a Course
(If implemented in your version)
1. Select a course from the list
2. Tap edit button
3. Modify course information
4. Save changes

### Impact on League Play
- Par 3 count automatically sets Closest Pin purse amount
- Selected course appears in game records

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
   - Multiple winners can be selected (one per Par 3)

3. **Automatic Payout Calculation**
   - Closest Pin Purse is divided equally among winners
   - Each winner receives: Closest Pin Purse ÷ Number of Winners

4. **Save and Return**
   - Closest pin winnings are added to player totals
   - Return to Enter Scores screen

---

## Administration

The Administration screen provides system management functions.

### Access
- Tap the storage icon in the top right of Monday Parent Screen
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

#### 3. Database Download (If implemented)
- Download player and score data from Firebase
- Sync cloud database to local device
- Useful for:
  - Setting up new tablet
  - Recovering from local database issues
  - Syncing latest cloud data

#### 4. View System Information
- Device details
- Database status
- Firebase connection status

---

## Tips and Best Practices

### Before League Play

1. **Verify Golf Course List**
   - Ensure all courses are in the system
   - Check Par 3 counts are accurate

2. **Check Settings**
   - Confirm Players Ante amount ($5.00 default)
   - Confirm Mulligan amount ($2.00 default)
   - Verify Firebase uploads are enabled (if needed)

3. **Test Device**
   - Ensure tablet is charged
   - Check internet connection (for Firebase sync)
   - Verify landscape orientation works

### During Player Selection

1. **Count Players**
   - Note total number selected
   - Ensure all participating players are checked

2. **Double-Check Selections**
   - Review selected players before proceeding
   - Use Clear All if you need to start over

### During Score Entry

1. **Organize Groups First**
   - Use Shuffle Groups for quick random distribution
   - Use Adjust Players for manual fine-tuning
   - Organize groups to match actual golf groups if possible

2. **Enter SKATS Scores Carefully**
   - Verify each score as you enter it
   - Remember: negative = winner, positive = loser
   - Use the custom keypad for accuracy

3. **Track Mulligans**
   - Update mulligan counts as you go
   - Maximum 2 per player

4. **Don't Leave Screen**
   - Player Selection button is disabled after score entry starts
   - Prevents accidental loss of entered data

### Before Saving Results

1. **Review Results Screen**
   - Verify all player scores are correct
   - Check purse amounts make sense
   - Confirm golf course and date are correct

2. **Check for Errors**
   - Ensure no missing SKATS scores
   - Verify mulligan counts
   - Review payout distribution

3. **Save Promptly**
   - Save results as soon as they're verified
   - Don't wait - data could be lost if app closes

### After Saving

1. **Verify Success**
   - Look for green confirmation message
   - Check that Firebase sync completed (if enabled)

2. **Keep Device On**
   - If Firebase upload is happening, don't close app immediately
   - Allow time for cloud sync to complete

### Data Management

1. **Regular Backups**
   - Periodically download data from Firebase
   - Keep cloud database as primary backup

2. **Duplicate Date Prevention**
   - Keep this enabled unless specifically needed
   - Prevents accidental double-entry

3. **Firebase Sync**
   - Keep enabled for automatic cloud backup
   - Only disable when necessary (no internet, testing)

### Troubleshooting

#### Cannot Proceed to Player Selection
- **Solution**: Select a golf course first

#### Player Selection Button Disabled
- **Cause**: SKATS scores have been entered, or Adjust Players overlay is open
- **Solution**:
  - Close Adjust Players overlay if open
  - If scores entered, use Back button to return from Results screen

#### SKATS Input Not Working
- **Cause**: Adjust Players overlay is open
- **Solution**: Close the overlay by tapping "Adjust Players" button

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

---

## Workflow Summary

### Recommended Workflow

1. **Launch Application** → Select Monday League
2. **Monday Parent Screen** → Select Golf Course
3. **Monday Parent Screen** → Verify/adjust Ante, Closest Pin, Mulligan amounts
4. **Monday Parent Screen** → Tap "Player Selection"
5. **Player Selection** → Select all participating players
6. **Player Selection** → Tap "Enter Scores"
7. **Enter Scores** → Tap "Shuffle Groups" to organize players
8. **Enter Scores** → (Optional) Use "Adjust Players" to fine-tune groups
9. **Enter Scores** → Enter SKATS scores for all players
10. **Enter Scores** → Enter Mulligan counts
11. **Enter Scores** → Tap "Closest Pin" to record winners
12. **Closest Pin** → Select closest pin winners, save and return
13. **Enter Scores** → Tap "Calculate / View Results"
14. **Results** → Review all data carefully
15. **Results** → Tap "Save to Database"
16. **Results** → Verify success message
17. **Results** → Tap "Main Menu" to return to start

---

## Support and Questions

For technical issues, questions, or feature requests, contact your league administrator or application developer.

---

**Document Version**: 1.0
**Last Updated**: December 31, 2025
**Application**: Golden Oaks Golf League - Monday League Module
